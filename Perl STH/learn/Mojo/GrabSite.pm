package Grab::Site;

use strict;
use warnings;
use diagnostics;

use 5.20.1;

use Carp;
use Data::Printer colored => 1;
use Mojo::UserAgent;
use Encode;
use Path::Tiny;
use DateTime;
use Mojo::JSON qw(encode_json decode_json);
use Timer::Simple;
use Try::Tiny;
use DBI qw(:sql_types);
use utf8;
use experimental 'smartmatch';

use enum qw(BITMASK:PZ_ chuang yigui shafa dianshi bingxiang xiyiji kongtiao reshuiqi kuandai nuanqi meiqi jiaju);
use List::Util qw(any);


sub new{
    my ($class,$info) = @_;

    init($info);

    bless($info,$class);
    return $info;
}

sub init{
    my ($self) = @_;
    $self->{'error_query'} = {};
    $self->{'grab_urls'} = 0;
}

sub check_firewall{
    my ($tx,$site_source) = @_;

    my $url = $tx->req->url->to_string;
    my $is_firewall = ($url =~ m/firewall/);


    return $is_firewall;
}

# 抓取一页数据
sub grab_page{
    my ($self,$delay,$page_index) = @_;
    my $ua = $self->{'ua'};
    my $error_query = $self->{'error_query'};

    my $area_list = $self->{'area_list'};
    my $list_page_url_tpl = $self->{'list_page_url_tpl'};
    my $site_source = $self->{'site_source'};
    my $handy_db = $self->{'db'};

    for my $area (@$area_list) {
        my $page_list_url = sprintf($list_page_url_tpl,$area,$page_index);

        my $end = $delay->begin(0);

        $ua->get($page_list_url => sub{
                     my ($ua, $tx) = @_;
                     my $url = $tx->req->url->to_string;

                     my $is_firewall = check_firewall($tx,$site_source);
                     if ($is_firewall || $tx->res->error) {
                         $error_query->{error_counts}++;
                         my $error_info = $tx->res->error;
                         $error_info->{'exception'} = '反爬虫，访问过快' if $is_firewall;
                         $error_query->{$url} = $error_info;
                     } else {
                         my $list_dom = $tx->res->dom;

                         # 分析 dom
                         my $detail_page_urls_ref = generate_detail_page_urls_ref_func{$site_source}->($list_dom,$site_source);

                         # 去除处理过的 url
                         exclude_urls_in_db($handy_db,$detail_page_urls_ref,$site_source);

                         my $process_count = 1;
                         while (my ($puid,$detail_page_url) = each %$detail_page_urls_ref) {

                             my $delay_time = ($process_count++) * 0.2;
                             my $timer_delay = $delay->begin(0);
                             Mojo::IOLoop->timer( $delay_time => sub{
                                                      $ua->max_redirects(2)->get($detail_page_url =>sub{
                                                                                     my ($ua,$result) = @_;
                                                                                     ++($self->{'grab_urls'});
                                                                                     process_detail_result($result,$puid,$error_query,$handy_db,$site_source);
                                                                                     $timer_delay->();
                                                                                 });
                                                  });
                         }
                     }

                     $end->();
                 });
    }
}

my $generate_detail_page_urls_ref_func = {
                                          '0'=> \&generate_detail_page_urls_ref_58,
                                          '1'=> \&generate_detail_page_urls_ref_ganji,
                                          '2'=> \&generate_detail_page_urls_ref_fang,
                                         };


sub generate_detail_page_urls_ref_ganji{
    my ($page_list_dom)  = @_;

    my %detail_page_urls;
    my $tr_doms = $page_list_dom->find("li[id^=puid-]")->each(sub{
                                                                  my ($dom) = @_;
                                                                  my $puid = $dom->attr('id');
                                                                  $puid =~ s/^puid-(\d+).*$/$1/;
                                                                  my $url = "http://cd.ganji.com/fang1/${puid}x.htm";

                                                                  $detail_page_urls{$puid} = $url;
                                                              });
    my $page_urls_ref = \%detail_page_urls;

    return $page_urls_ref;
}

sub generate_detail_page_urls_ref_58{
    my ($page_list_dom)  = @_;

    my %detail_page_urls;
    my $tr_doms = $page_list_dom->find("div#infolist tr[logr]");

    $tr_doms->each(sub{
                       my ($dom) = @_;
                       my $url = $dom->at('h1>a[href]:nth-child(1)')->attr('href');

                       if (!$url) {
                           return;
                       }

                       # 这里处理一下 url ,获取拼装以后的 url (非需要跳转的推广url)
                       my $puid;
                       if ($url =~ m</(\d+)x\.shtml>) {
                           $puid = $1;
                       } else {
                           # 这类需要跳转的 url 特殊处理
                           my $logr = $dom->attr('logr');
                           $puid = $1 if $logr =~ /_(\d+)_\d_\d/;
                           $url = sprintf('http://cd.58.com/zufang/%s.shtml',$puid . 'x');
                       }

                       $detail_page_urls{$puid} = $url;
                   });



    my $page_urls_ref = \%detail_page_urls;

    return $page_urls_ref;
}


sub generate_detail_page_urls_ref_fang{
    my ($page_list_dom)  = @_;

    my %detail_page_urls;
    my $page_urls_ref = \%detail_page_urls;

    return $page_urls_ref;
}

# 排除已经处理过的 url
sub exclude_urls_in_db{
    my ($handy_db,$page_urls,$site_source) = @_;
    my @puids_from_web = keys %$page_urls;

    my $query_sql = q{
SELECT
  i.puid
FROM
  grab_site_info i
WHERE i.site_source = $site_source i.puid IN ('%s');
};

    $query_sql = sprintf($query_sql,join("','",@puids_from_web));
    my @puids_in_db = @{$handy_db->selectall_arrayref($query_sql)};

    foreach my $row (@puids_in_db) {
        my ($puid) = @$row;
        delete $page_urls->{$puid};
    }
}

# 保存 page info 到数据库
sub save_page_info{
    my ($handy_db,$page_info,$site_source) = @_;

    # 写入数据库
    my $insert_sql = qq{
INSERT INTO `handy`.`grab_site_info` (
  `site_source`,
  `puid`,
  `url`,
  `price`,
  `show_date`,
  `address`,
  `floor`,
  `room_type`,
  `room_space`,
  `house_type`,
  `house_decoration`,
  `region_district`,
  `region_street`,
  `region_xiaoqu`,
  `peizhi_info`
)
VALUES
  ($site_source,?,?,?,?,?,?,?,?,?,?,?,?,?,?);
};

    my @params = @{$page_info}{qw(puid url price show_data address floor room_type room_space house_type house_decoration region_district region_street region_xiaoqu peizhi_info)};
    my $sth = $handy_db->prepare($insert_sql);

    # peizhi int 结构
    $sth->bind_param(14,$params[13],SQL_INTEGER);
    $sth->execute(@params);
}





sub process_detail_result{
    my ($result,$puid,$error_query,$handy_db,$site_source) = @_;
    my $detail_page_dom = $result->res->dom;
    my $url = $result->req->url->to_string;

    my $is_firewall = check_firewall($result,$site_source);
    if ($is_firewall || $result->res->error) {
        ($error_query->{error_counts})++;
        my $error_info = $result->res->error;
        $error_info->{'exception'} = '反爬虫，访问过快' if $is_firewall;
        $error_query->{$url} = $error_info;
        return;
    }

    my $body = decode('utf8',$result->res->body);
    my $page_deleted = 0;   #($body =~ m/你要找的页面不在这个星球上/);
    if ($page_deleted) {
        return;
    }

    try{
        my $page_info = grab_detail_page_func{$site_source}->($detail_page_dom);
        $page_info->{'url'} = $url;
        $page_info->{'puid'} = $puid;

        save_page_info($handy_db,$page_info,1);
    }catch{
        if ($_ !~ m/Duplicate entry/) {
            ($error_query->{error_counts})++;
            my $error_info = $result->res->error;
            $error_info->{'exception'} = $_;
            $error_query->{$url} = $error_info;
        }
    };
}

my $grab_detail_page_func = {
                            '0' => \&grab_detail_page_58,
                            '1' => \&grab_detail_page_ganji,
                            '2' => \&grab_detail_page_fang,
                           };

sub grab_detail_page_58{
    my ($page_dom) = @_;
    my $date_dom = $page_dom->at("li.time");
    my $date = $date_dom->text if $date_dom;
    $date = DateTime->today()->ymd unless $date;
    my $summary = $page_dom->find("ul.suUl>li");

    my $page_info = {show_data=>$date};


    foreach my $row (@$summary) {
        my $title_dom = $row->at("div.su_tit");
        my $title = $title_dom->text if $title_dom;

        given($title){
            when('价格'){
                my $price = $row->at("div.su_con span:nth-child(1)")->text;
                $page_info->{price} = ($price =~ m/\d+/) ? $price : 0;
            }
            when('楼层'){
                my $floor = $row->at("div.su_con")->text;
                $page_info->{floor} = $floor;
            }
            when('地址'){
                my $address = $row->at("div.su_con")->text;
                $page_info->{address} = $address;
            }
            when('概况'){
                my @house_info = split(/\s/,$row->at("div.su_con")->text);
                $page_info->{room_type} = join("-",@house_info[0,1,2]);
                my $room_space = $house_info[3];
                if ($room_space =~ s/(\d+).*/$1/) {
                    $page_info->{room_space} = $room_space;
                } else {
                    $page_info->{room_space} = 0;
                }

                $page_info->{house_type} = $house_info[4];
                $page_info->{house_decoration} = $house_info[5];
            }
            when('区域'){
                my $district = $row->at("div.su_con a:nth-child(1)")->text;
                my $street_dom = $row->at("div.su_con a:nth-child(2)");
                my $street = $street_dom ? $street_dom->text : '';
                my $xiaoqu = $row->at("div.su_con")->text;
                $xiaoqu =~ s/[- ]*//;
                $page_info->{region_district} = $district;
                $page_info->{region_street} = $street;
                my $xiaoqu_dom = $row->at("div.su_con a:nth-child(3)");
                $page_info->{region_xiaoqu} = $xiaoqu_dom ? $xiaoqu_dom->text : $xiaoqu;
            }
        }
    }

    my $peizhi_dom = $page_dom->at("div.peizhi");
    my $peizhi = $1 if $peizhi_dom && (($peizhi_dom->all_text) =~ m/tmp = '(.*)';/);
    my $peizhi_bit_mask = 0;
    if ($peizhi) {
        my @peizhi_info = split(',',$peizhi);
        $peizhi_bit_mask |= PZ_chuang if any {$_ eq '床'} @peizhi_info;
        $peizhi_bit_mask |= PZ_yigui if any {$_ eq '衣柜'} @peizhi_info;
        $peizhi_bit_mask |= PZ_shafa if any {$_ eq '沙发'} @peizhi_info;
        $peizhi_bit_mask |= PZ_dianshi if any {$_ eq '电视'} @peizhi_info;
        $peizhi_bit_mask |= PZ_bingxiang if any {$_ eq '冰箱'} @peizhi_info;
        $peizhi_bit_mask |= PZ_xiyiji if any {$_ eq '洗衣机'} @peizhi_info;
        $peizhi_bit_mask |= PZ_kongtiao if any {$_ eq '空调'} @peizhi_info;
        $peizhi_bit_mask |= PZ_reshuiqi if any {$_ eq '热水器'} @peizhi_info;
        $peizhi_bit_mask |= PZ_kuandai if any {$_ eq '宽带'} @peizhi_info;
        $peizhi_bit_mask |= PZ_nuanqi if any {$_ eq '暖气'} @peizhi_info;
    }
    $page_info->{peizhi_info} = $peizhi_bit_mask;

    return $page_info;
}

sub grab_detail_page_fang{
    return {};
}

sub grab_detail_page_ganji{
    my ($page_dom) = @_;
    my $date_dom = $page_dom->at("ul.title-info-l>li:nth-child(1)>i");
    my $date = $date_dom->text if $date_dom;
    $date = DateTime->today()->ymd unless $date;
    my $summary = $page_dom->find("ul.basic-info-ul>li");

    my $page_info = {show_data=>$date};


    foreach my $row (@$summary) {
        my $title_dom = $row->at("span:nth-child(1)");
        my $title = $title_dom->text if $title_dom;
        $title =~ s/[^\w]//g;

        given($title){
            when('租金'){
                my $price = $row->at("b.basic-info-price")->text;
                $page_info->{price} = ($price =~ m/\d+/) ? $price : 0;
            }
            when('楼层'){
                my $floor = $row->child_nodes->last->content;
                $floor =~ s/\s//g;
                $page_info->{floor} = $floor;
            }
            when(''){
                my $address = $row->at("span.addr-area")->text;
                $page_info->{address} = $address;
            }
            when('户型'){
                my $house_info_str = $row->child_nodes->last->content;
                my @house_info = split(/-/,$house_info_str);
                my $house_type =  $house_info[0];
                $house_type =~ s/\s//g;
                $page_info->{room_type} = $house_type;
                my $room_space = $house_info[2];
                if ($room_space =~ s/\s*(\d+).*/$1/) {
                    $page_info->{room_space} = $room_space;
                } else {
                    $page_info->{room_space} = 0;
                }
            }
            when('概况'){
                my $house_info_str = $row->child_nodes->last->content;
                my @house_info = map { $_ =~ s/\s//g ; $_ } split(/-/,$house_info_str);
                $page_info->{house_type} = $house_info[1];
                $page_info->{house_decoration} = $house_info[2];
            }
            when('小区'){
                my $xiaoqu_dom = $row->at("div>a:nth-child(1)");
                $page_info->{region_xiaoqu} = $xiaoqu_dom ? $xiaoqu_dom->text : '';
            }
            when('位置'){
                my @region = $row->find("a")->map('text')->each;
                my $district = $region[1];
                my $street = $region[2];

                $page_info->{region_district} = $district;
                $page_info->{region_street} = $street;
            }
            when('配置'){
                my $peizhi_dom = $row->at("p");
                my $peizhi = $peizhi_dom->all_text if $peizhi_dom ;
                my $peizhi_bit_mask = 0;

                if ($peizhi) {
                    my @peizhi_info = split('/',$peizhi);

                    $peizhi_bit_mask |= PZ_chuang if any {$_ =~ '床'} @peizhi_info;
                    $peizhi_bit_mask |= PZ_yigui if any {$_ =~ '衣柜'} @peizhi_info;
                    $peizhi_bit_mask |= PZ_shafa if any {$_ =~ '沙发'} @peizhi_info;
                    $peizhi_bit_mask |= PZ_dianshi if any {$_ =~ '电视'} @peizhi_info;
                    $peizhi_bit_mask |= PZ_bingxiang if any {$_ =~ '冰箱'} @peizhi_info;
                    $peizhi_bit_mask |= PZ_xiyiji if any {$_ =~ '洗衣机'} @peizhi_info;
                    $peizhi_bit_mask |= PZ_kongtiao if any {$_ =~ '空调'} @peizhi_info;
                    $peizhi_bit_mask |= PZ_reshuiqi if any {$_ =~ '热水器'} @peizhi_info;
                    $peizhi_bit_mask |= PZ_kuandai if any {$_ =~ '宽带'} @peizhi_info;
                    $peizhi_bit_mask |= PZ_nuanqi if any {$_ =~ '暖气'} @peizhi_info;
                    $peizhi_bit_mask |= PZ_meiqi if any {$_ =~ '煤气'} @peizhi_info;
                    $peizhi_bit_mask |= PZ_jiaju if any {$_ =~ '家具'} @peizhi_info;
                }
                $page_info->{peizhi_info} = $peizhi_bit_mask;
            }
        }
    }

    return $page_info;
}




sub log_grab_info{
    my ($self) = @_;
    my $error_query = $self->{"error_query"};
    my $url_num = $self->{'grab_urls'};
    my $site_source = $self->{'site_source'};
    my $time_used = $self->{'timer'};
    my $handy_db = $self->{'db'};

    my $errors = $error_query->{error_counts} // 0;

    my $grab_info = {
                     'time_used' => $time_used->string,
                     'grab_urls' => $url_num,
                     'errors' => $errors,
                     'site_source' => $site_source,
                    };
    p $grab_info;

    # write info into db
    my $info_sql = q{
INSERT INTO `handy`.`grab_info` (
  `grab_info`,
  `site_info_counts`,
  `errors`
)
VALUES
  (?,?,?) ;
};

    my $grab_info_json = encode_json($grab_info);
    my $error_json = encode_json($error_query);
    my $site_info_counts = ($handy_db->selectrow_array("SELECT COUNT(*) FROM grab_site_info where site_source = $site_source;"));
    $handy_db->do($info_sql,undef,$grab_info_json,$site_info_counts,$error_json);

    # 清空 error_query, grab_urls
    init($self);
}

sub start_timer{
    my ($self) = @_;
    my $time_used = Timer::Simple->new();
    $self->{'timer'} = $time_used;
}

sub reset_timer{
    my ($self) = @_;
    $self->{'timer'}->start;
}


1;


__END__

CREATE TABLE `grab_site_info` (
                               `id` int(11) NOT NULL AUTO_INCREMENT,
                               `puid` varchar(50) NOT NULL,
                               `url` varchar(1000) NOT NULL,
                               `price` decimal(10,2) NOT NULL,
                               `show_date` datetime NOT NULL,
                               `address` varchar(50) DEFAULT NULL,
                               `floor` varchar(50) DEFAULT NULL,
                               `room_type` varchar(50) DEFAULT NULL,
                               `room_space` decimal(10,2) DEFAULT NULL,
                               `house_type` varchar(50) DEFAULT NULL,
                               `house_decoration` varchar(50) DEFAULT NULL,
                               `region_district` varchar(50) DEFAULT NULL,
                               `region_street` varchar(50) DEFAULT NULL,
                               `region_xiaoqu` varchar(50) DEFAULT NULL,
                               `peizhi_info` bit(20) NOT NULL DEFAULT b'0',
                               `created_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
                               PRIMARY KEY (`id`),
                               UNIQUE KEY `idx_puid` (`puid`)
                              ) ENGINE=InnoDB AUTO_INCREMENT=7879 DEFAULT CHARSET=utf8;

CREATE TABLE `export_info` (
                            `id` int(11) NOT NULL AUTO_INCREMENT,
                            `export_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
                            `counts` int(11) NOT NULL,
                            `export_max_id` int(11) NOT NULL,
                            PRIMARY KEY (`id`)
                           ) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8;


CREATE TABLE `grab_info` (
                          `id` int(11) NOT NULL AUTO_INCREMENT,
                          `grab_info` varchar(500) DEFAULT NULL,
                          `site_info_counts` int(11) NOT NULL,
                          `errors` text,
                          `grab_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
                          PRIMARY KEY (`id`)
                         ) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;
