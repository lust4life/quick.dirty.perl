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
use Time::HiRes;
use URI::Escape;
use enum qw(f58 ganji fang);
use enum
  qw(BITMASK:PZ_ chuang yigui shafa dianshi bingxiang xiyiji kongtiao reshuiqi kuandai nuanqi meiqi jiaju);
use List::Util qw(any);

use HandyDataSource;

my $generate_detail_page_urls_ref_func = {
    '0' => \&generate_detail_page_urls_ref_58,
    '1' => \&generate_detail_page_urls_ref_ganji,
    '2' => \&generate_detail_page_urls_ref_fang,
};

my $grab_detail_page_func = {
    '0' => \&grab_detail_page_58,
    '1' => \&grab_detail_page_ganji,
    '2' => \&grab_detail_page_fang,
};
my $rent_type_hash = {
    '整套' => 0,
    '主卧' => 1,
    '次卧' => 2,
    '隔断' => 3,
};

my $proxy_urls;

my $ua;

sub init_mojo{
    $ua = Mojo::UserAgent->new;
    $ua = $ua->connect_timeout(1)->request_timeout(3)->max_redirects(2);
}

sub new {
    my ( $class, $info ) = @_;

    init_error_info($info);
    init_mojo();
    $proxy_urls = $info->{proxy_urls};
    if($proxy_urls){
        my $url_num = scalar(@$proxy_urls);
        p $url_num;
        my $rand = int(rand($url_num));
        $ua->proxy->http($proxy_urls->[$rand]);
    }

    my $ds = Handy::DataSource->new(1);

    my $handy_db = DBI->connect(
        $ds->handy,

        #'lust','lust',
        'uoko-dev',
        'dev-uoko',
        {
            'mysql_enable_utf8' => 1,
            'RaiseError'        => 1,
            'PrintError'        => 0
        }
    ) or die qq(unable to connect $Handy::DataSource::handy\n);

    $info->{'db'}       = $handy_db;
    $info->{'page_num'} = 1;
    $info->{'city'}     = $info->{'city'};

    bless( $info, $class );
    return $info;
}

sub init_error_info {
    my ($self) = @_;
    $self->{'error_query'} = {};
    $self->{'grab_urls'}   = 0;
}

sub check_req_error {
    my ($self,$tx,$no_change_proxy) = @_;

    my $error_info = $tx->res->error;

    my $url = $tx->req->url->to_string;
    my $is_firewall = 0;

    if(!$error_info){

        $is_firewall = ( $url =~ m/firewall/ ) || ( $url =~ m/confirm/ );

        if($is_firewall){
            $error_info->{'exception'} = '反爬虫，访问过快';
        }
    }

    if ( !$no_change_proxy && $error_info ) {

        if($is_firewall){
            $url = uri_unescape($url);
            $url =~ s!.*?=(http://.*)!$1!g;
        }

        my $proxy_set_ok = $self->change_proxy($url);

        if (!$proxy_set_ok) {
            $error_info->{'exception'} = '爬虫代理切换失败';
        } else {
            undef $error_info;
        }
    }

    return $error_info;
}

sub change_proxy{
    my ($self,$test_url) = @_;

    my $proxy_set_ok = 0;

    if(!$proxy_urls){
        return $proxy_set_ok;
    }


    for my $proxy_url(@$proxy_urls){
        $ua->proxy->http($proxy_url);

        my $tx =$ua->get($test_url);

        my $error_info = $self->check_req_error($tx,1);
        if(!$error_info){
            $proxy_set_ok = 1;
            say "$test_url => firewall --------- $proxy_url";
            last;
        }
    }

    if(!$proxy_set_ok){
        init_mojo();
    }

    return $proxy_set_ok;
}


# 抓取一页数据
sub grab_page {
    my ( $self, $delay ) = @_;

    my $page_index   = $self->{'page_num'};
    my $area_list    = $self->{'area_list'};
    my $url_tpl_hash = $self->{'url_tpl_hash'};
    my $site_source  = $self->{'site_source'};
    my $error_query  = $self->{'error_query'};

    $delay->steps(
        sub {
            my ($task) = @_;
            my $area_index;
            for my $area (@$area_list) {
                for my $list_page_url_tpl ( keys %$url_tpl_hash ) {

                    my $page_list_url = sprintf( $list_page_url_tpl, $area, $page_index );
                    my $detail_url_tpl = $url_tpl_hash->{$list_page_url_tpl};

                    my $end = $task->begin(0);

                    my $delay_time = ( $area_index++ * 1 );

                    Mojo::IOLoop->timer(
                        $delay_time => sub {
                            $ua->get(
                                $page_list_url => sub {
                                    my ( $ua, $tx ) = @_;
                                    my $url = $tx->req->url->to_string;

                                    my $error_info = $self->check_req_error($tx);
                                    if ($error_info) {
                                        $error_query->{error_counts}++;
                                        $error_query->{$url} = $error_info;
                                        $end->();
                                    }
                                    else {
                                        my $list_dom = $tx->res->dom;

                                        # 分析 dom
                                        my $detail_page_urls_ref =
                                          $generate_detail_page_urls_ref_func
                                          ->{$site_source}
                                          ->( $list_dom, $detail_url_tpl );

                                        # 去除处理过的 url
                                        $self->exclude_urls_in_db($detail_page_urls_ref);

                                        $end->($detail_page_urls_ref);
                                    }
                                }
                            );

                        }
                    );
                }
            }
        },
        sub {
            my ( $delay, @detail_page_urls_refs ) = @_;

            my $process_count = 1;

            for my $detail_page_urls_ref (@detail_page_urls_refs) {

                while ( my ( $puid, $detail_page_url ) = each %$detail_page_urls_ref )
                {
                    my $factor = 0.5;
                    if ( $site_source == ganji ) {
                        $factor = 1;
                    }
                    my $delay_time  = ( $process_count++ ) * $factor;
                    my $timer_delay = $delay->begin(0);

                    Mojo::IOLoop->timer(
                        $delay_time => sub {
                            $ua->get(
                                $detail_page_url => sub {
                                    my ( $ua, $result ) = @_;
                                    ++( $self->{'grab_urls'} );
                                    $self->process_detail_result($result,$puid);
                                    $timer_delay->();
                                }
                            );
                        }
                    );
                }
            }
        }
    );
}

sub generate_detail_page_urls_ref_ganji {
    my ( $page_list_dom, $detail_url_tpl ) = @_;

    my %detail_page_urls;
    my $tr_doms = $page_list_dom->find("li[id^=puid-]")->each(
        sub {
            my ($dom) = @_;
            my $puid = $dom->attr('id');
            $puid =~ s/^puid-(\d+).*$/$1/;

            my $url = sprintf( $detail_url_tpl, $puid . 'x.htm' );

            $detail_page_urls{$puid} = $url;
        }
    );
    my $page_urls_ref = \%detail_page_urls;

    return $page_urls_ref;
}

sub generate_detail_page_urls_ref_fang {
    my ( $page_list_dom, $detail_url_tpl ) = @_;

    my %detail_page_urls;
    my $tr_doms = $page_list_dom->find("dl[id^=rentid_]>dd>p.title>a")->each(
        sub {
            my ($dom) = @_;
            my $href = $dom->attr('href');
            my $puid = $1 if $href =~ m/\d_(\d+)_\d\.htm/;
            if ($puid) {
                my $url = sprintf( $detail_url_tpl, $href );
                $detail_page_urls{$puid} = $url;
            }
        }
    );
    my $page_urls_ref = \%detail_page_urls;

    return $page_urls_ref;
}

sub generate_detail_page_urls_ref_58 {
    my ( $page_list_dom, $detail_url_tpl ) = @_;

    my %detail_page_urls;
    my $tr_doms = $page_list_dom->find("div#infolist tr[logr]");

    $tr_doms->each(
        sub {
            my ($dom) = @_;
            my $url = $dom->at('h1>a[href]:nth-child(1)')->attr('href');

            if ( !$url ) {
                return;
            }

# 这里处理一下 url ,获取拼装以后的 url (非需要跳转的推广url)
            my $puid;
            if ( $url =~ m</(\d+)x\.shtml> ) {
                $puid = $1;
            }
            else {
                # 这类需要跳转的 url 特殊处理
                my $logr = $dom->attr('logr');
                $puid = $1 if $logr =~ /_(\d+)_\d_\d/;
                $url = sprintf( $detail_url_tpl, $puid . 'x' );
            }

            $detail_page_urls{$puid} = $url;
        }
    );

    my $page_urls_ref = \%detail_page_urls;

    return $page_urls_ref;
}

# 排除已经处理过的 url
sub exclude_urls_in_db {
    my ( $self, $page_urls ) = @_;

    my ($city,$handy_db,$site_source) = @$self{'city','db','site_source'};


    my $table_name     = 'grab_site_info_' . $city;
    my @puids_from_web = keys %$page_urls;

    my $query_sql = qq{
SELECT
  i.puid
FROM
  $table_name i
WHERE i.site_source = $site_source and i.puid IN ('%s');
};

    $query_sql = sprintf( $query_sql, join( "','", @puids_from_web ) );
    my @puids_in_db = @{ $handy_db->selectall_arrayref($query_sql) };

    foreach my $row (@puids_in_db) {
        my ($puid) = @$row;
        delete $page_urls->{$puid};
    }
}

# 保存 page info 到数据库
sub save_page_info {
    my ( $self, $page_info ) = @_;
    my ($city,$handy_db,$site_source) = @$self{'city','db','site_source'};

    my $table_name = 'grab_site_info_' . $city;

    # 写入数据库
    my $insert_sql = qq{
INSERT INTO `handy`.`$table_name` (
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
  `peizhi_info`,
  `rent_type`,
  `contact_link`
)
VALUES
  ($site_source,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?);
};

    my @params =
      @{$page_info}{
        qw(puid url price show_data address floor room_type room_space house_type house_decoration region_district region_street region_xiaoqu peizhi_info rent_type contact_link)
      };
    my $sth = $handy_db->prepare($insert_sql);

    # peizhi int 结构
    $sth->bind_param( 14, $params[13], SQL_INTEGER );
    $sth->execute(@params);
}

sub process_detail_result {
    my ( $self, $result, $puid ) = @_;

    my ($error_query,$site_source) = @$self{'error_query','site_source'};

    my $detail_page_dom = $result->res->dom;
    my $url             = $result->req->url->to_string;

    my $error_info = $self->check_req_error($result);
    if ($error_info) {
        $error_query->{error_counts}++;
        $error_query->{$url} = $error_info;
        return;
    }

    my $page_deleted = $self->check_page_remove( $result->res );
    if ($page_deleted) {
        return;
    }

    try {
        my $page_info = $grab_detail_page_func->{$site_source}->($detail_page_dom);
        $page_info->{'url'}  = $url;
        $page_info->{'puid'} = $puid;

        $self->save_page_info($page_info);
    }
    catch {
        if ( $_ !~ m/Duplicate entry/ ) {
            ( $error_query->{error_counts} )++;
            $error_info->{'exception'} = $_;
            $error_query->{$url} = $error_info;
        }
    };
}

sub grab_detail_page_fang {
    my ($page_dom) = @_;

    my $date_dom = $page_dom->at("div.houseInfo dl.title p[class]");
    my $date = $date_dom->text if $date_dom;
    $date = decode( "gb2312", $date );

    $date =~ s<.*?(\d{4}[/-]\d{1,2}[/-]\d{1,2}) .*><$1>g;
    $date = DateTime->today()->ymd unless $date;

    my $page_info = { show_data => $date, peizhi_info => 0, price => 0, rent_type => 0, };

    my $summary = $page_dom->find("div.info ul>li");

    foreach my $row (@$summary) {
        my $row_text = decode( 'gb2312', $row->all_text );

        my ( $title, $content ) = ();
        if ( $row_text =~ m/(.+)：?(.*)/g ) {
            $title   = $1;
            $content = $2;

            $title =~ s/[\s]//g;
        }
        else {
            $title = $row_text;
        }

        given ($title) {
            when (/元/) {
                my $price = $title =~ m/(\d+).*元/g ? $1 : 0;
                $page_info->{price} = $price;
            }
            when ('小区') {
                my @region   = $row->find("a")->map('text')->each;
                my $district = $region[-2];
                my $street   = $region[-1];
                $district = decode( 'gb2312', $district );
                $street   = decode( 'gb2312', $street );
                $page_info->{region_district} = $district;
                $page_info->{region_street}   = $street;
            }
            when (/(家具家电)|(配套设施)/) {
                my $peizhi_bit_mask = 0;

                if ($content) {
                    my @peizhi_info = split( ',', $content );

                    $peizhi_bit_mask |= PZ_chuang
                      if any { $_ =~ '床' } @peizhi_info;
                    $peizhi_bit_mask |= PZ_kuandai
                      if any { $_ =~ '宽带' } @peizhi_info;
                    $peizhi_bit_mask |= PZ_dianshi
                      if any { $_ =~ '电视' } @peizhi_info;
                    $peizhi_bit_mask |= PZ_bingxiang
                      if any { $_ =~ '冰箱' } @peizhi_info;
                    $peizhi_bit_mask |= PZ_xiyiji
                      if any { $_ =~ '洗衣机' } @peizhi_info;
                    $peizhi_bit_mask |= PZ_kongtiao
                      if any { $_ =~ '空调' } @peizhi_info;
                    $peizhi_bit_mask |= PZ_reshuiqi
                      if any { $_ =~ '热水器' } @peizhi_info;
                    $peizhi_bit_mask |= PZ_nuanqi
                      if any { $_ =~ '暖气' } @peizhi_info;
                    $peizhi_bit_mask |= PZ_yigui
                      if any { $_ =~ '衣柜' } @peizhi_info;
                    $peizhi_bit_mask |= PZ_shafa
                      if any { $_ =~ '沙发' } @peizhi_info;
                    $peizhi_bit_mask |= PZ_meiqi
                      if any { $_ =~ '煤气' } @peizhi_info;
                    $peizhi_bit_mask |= PZ_jiaju
                      if any { $_ =~ '家具' } @peizhi_info;
                }
                $page_info->{peizhi_info} = $peizhi_bit_mask;
            }
        }
    }
    my $huxing = $page_dom->find("ul.Huxing li");
    for my $row (@$huxing) {
        my $title = decode( 'gb2312', $row->at("p.type")->text );
        $title =~ s/[\s：]//g;
        my $content = $row->at('p.info')->text;
        $content = decode( 'gb2312', $content );

        given ($title) {
            when ('楼层') {
                $page_info->{floor} = $content;
            }
            when ('地址') {
                $page_info->{address} = $content;
            }
            when ('户型') {
                $page_info->{room_type} = $content;
            }
            when ('物业类型') {
                $page_info->{house_type} = $content;
            }
            when ('装修') {
                $page_info->{house_decoration} = $content;
            }
            when ('小区') {
                $page_info->{region_xiaoqu} = $content;
            }
            when ('面积') {
                my $room_space = $content;
                if ( $room_space =~ s/\s*(\d+).*/$1/ ) {
                    $page_info->{room_space} = $room_space;
                }
                else {
                    $page_info->{room_space} = 0;
                }
            }
        }
    }

    return $page_info;
}

sub grab_detail_page_58 {
    my ($page_dom) = @_;
    my $date_dom = $page_dom->at("li.time");
    my $date = $date_dom->text if $date_dom;
    $date = DateTime->today()->ymd unless $date;
    my $summary = $page_dom->find("ul.suUl>li");

    my $page_info = { show_data => $date, peizhi_info => 0, price => 0, rent_type => 0, };

    foreach my $row (@$summary) {
        my $title_dom = $row->at("div.su_tit");
        my $title = $title_dom->text if $title_dom;

        given ($title) {
            when ('价格') {
                my $price = $row->at("div.su_con span:nth-child(1)")->text;
                $page_info->{price} = ( $price =~ m/\d+/ ) ? $price : 0;
            }
            when ('楼层') {
                my $floor = $row->at("div.su_con")->text;
                $page_info->{floor} = $floor;
            }
            when ('地址') {
                my $address = $row->at("div.su_con")->text;
                $page_info->{address} = $address;
            }
            when ('概况') {
                my @house_info = split( /\s/, $row->at("div.su_con")->text );
                $page_info->{room_type} = join( "-", @house_info[ 0, 1, 2 ] );
                my $room_space = $house_info[3] // 0;
                if ( $room_space =~ s/(\d+).*/$1/ ) {
                    $page_info->{room_space} = $room_space;
                }
                else {
                    $page_info->{room_space} = 0;
                }

                $page_info->{house_type}       = $house_info[4];
                $page_info->{house_decoration} = $house_info[5];
            }
            when ('区域') {
                my $district   = $row->at("div.su_con a:nth-child(1)")->text;
                my $street_dom = $row->at("div.su_con a:nth-child(2)");
                my $street     = $street_dom ? $street_dom->text : '';
                my $xiaoqu     = $row->at("div.su_con")->text;
                $xiaoqu =~ s/[- ]*//;
                $page_info->{region_district} = $district;
                $page_info->{region_street}   = $street;
                my $xiaoqu_dom = $row->at("div.su_con a:nth-child(3)");
                $page_info->{region_xiaoqu} =
                  $xiaoqu_dom ? $xiaoqu_dom->text : $xiaoqu;
            }
            when ('出租') {
                my @house_info = split( /\s/, $row->at("div.su_con")->text );

                $page_info->{rent_type} = $rent_type_hash->{ $house_info[0] }
                  // 0;

                my $room_space = $house_info[1] // 0;
                if ( $room_space =~ s/(\d+).*/$1/ ) {
                    $page_info->{room_space} = $room_space;
                }
                else {
                    $page_info->{room_space} = 0;
                }

                $page_info->{house_type} = $house_info[3];
            }
            when ('整体') {
                my @house_info = split( /\s/, $row->at("div.su_con")->text );
                $page_info->{room_type} = join( "-", @house_info[ 0, 1, 2 ] );
                $page_info->{house_decoration} = $house_info[3];
            }
            when ('联系'){
                my $contact_dom = $row->at('span>a');

                $page_info->{contact_link} = $contact_dom->attr('href');
            }
        }
    }

    my $peizhi_dom = $page_dom->at("div.peizhi");
    my $peizhi     = $1
      if $peizhi_dom && ( ( $peizhi_dom->all_text ) =~ m/tmp = '(.*)';/ );
    my $peizhi_bit_mask = 0;
    if ($peizhi) {
        my @peizhi_info = split( ',', $peizhi );
        $peizhi_bit_mask |= PZ_chuang    if any { $_ eq '床' } @peizhi_info;
        $peizhi_bit_mask |= PZ_yigui     if any { $_ eq '衣柜' } @peizhi_info;
        $peizhi_bit_mask |= PZ_shafa     if any { $_ eq '沙发' } @peizhi_info;
        $peizhi_bit_mask |= PZ_dianshi   if any { $_ eq '电视' } @peizhi_info;
        $peizhi_bit_mask |= PZ_bingxiang if any { $_ eq '冰箱' } @peizhi_info;
        $peizhi_bit_mask |= PZ_xiyiji if any { $_ eq '洗衣机' } @peizhi_info;
        $peizhi_bit_mask |= PZ_kongtiao if any { $_ eq '空调' } @peizhi_info;
        $peizhi_bit_mask |= PZ_reshuiqi
          if any { $_ eq '热水器' } @peizhi_info;
        $peizhi_bit_mask |= PZ_kuandai if any { $_ eq '宽带' } @peizhi_info;
        $peizhi_bit_mask |= PZ_nuanqi  if any { $_ eq '暖气' } @peizhi_info;
    }
    $page_info->{peizhi_info} = $peizhi_bit_mask;

    return $page_info;
}

sub grab_detail_page_ganji {
    my ($page_dom) = @_;
    my $date_dom = $page_dom->at("ul.title-info-l>li:nth-child(1)>i");
    my $date = $date_dom->text if $date_dom;
    $date =~ s/(\d{2}-\d{2}) .*/2015-$1/g;
    $date = DateTime->today()->ymd unless $date;
    my $summary = $page_dom->find("ul.basic-info-ul>li");

    my $page_info = { show_data => $date, peizhi_info => 0, price => 0, rent_type => 0, };

    foreach my $row (@$summary) {
        my $title_dom = $row->at("span:nth-child(1)");
        my $title = $title_dom->text if $title_dom;
        $title =~ s/[^\w]//g;

        given ($title) {
            when ('租金') {
                my $price = $row->at("b.basic-info-price")->text;
                $page_info->{price} = ( $price =~ m/\d+/ ) ? $price : 0;
            }
            when ('楼层') {
                my $floor = $row->child_nodes->last->content;
                $floor =~ s/\s//g;
                $page_info->{floor} = $floor;
            }
            when ('') {
                my $address = $row->at("span.addr-area")->attr('title');
                $page_info->{address} = $address;
            }
            when ('户型') {
                my $house_info_str = $row->child_nodes->last->content;
                my @house_info     = split( /-/, $house_info_str );
                my $house_type     = $house_info[0];
                $house_type =~ s/\s//g;
                $page_info->{room_type} = $house_type;
                my $room_space = $house_info[2];
                if ( $room_space =~ s/\s*(\d+).*/$1/ ) {
                    $page_info->{room_space} = $room_space;
                }
                else {
                    $page_info->{room_space} = 0;
                }
            }
            when ('概况') {
                my $house_info_str = $row->child_nodes->last->content;
                my @house_info =
                  map { $_ =~ s/\s//g; $_ } split( /-/, $house_info_str );
                $page_info->{house_type}       = $house_info[1];
                $page_info->{house_decoration} = $house_info[2];
            }
            when ('小区') {
                my $xiaoqu_dom = $row->at("div>a:nth-child(1)");
                $page_info->{region_xiaoqu} =
                  $xiaoqu_dom ? $xiaoqu_dom->text : '';
            }
            when ('位置') {
                my @region   = $row->find("a")->map('text')->each;
                my $district = $region[1];
                my $street   = $region[2];

                $page_info->{region_district} = $district;
                $page_info->{region_street}   = $street;
            }
            when ('配置') {
                my $peizhi_dom      = $row->at("p");
                my $peizhi          = $peizhi_dom->all_text if $peizhi_dom;
                my $peizhi_bit_mask = 0;

                if ($peizhi) {
                    my @peizhi_info = split( '/', $peizhi );

                    $peizhi_bit_mask |= PZ_chuang
                      if any { $_ =~ '床' } @peizhi_info;
                    $peizhi_bit_mask |= PZ_yigui
                      if any { $_ =~ '衣柜' } @peizhi_info;
                    $peizhi_bit_mask |= PZ_shafa
                      if any { $_ =~ '沙发' } @peizhi_info;
                    $peizhi_bit_mask |= PZ_dianshi
                      if any { $_ =~ '电视' } @peizhi_info;
                    $peizhi_bit_mask |= PZ_bingxiang
                      if any { $_ =~ '冰箱' } @peizhi_info;
                    $peizhi_bit_mask |= PZ_xiyiji
                      if any { $_ =~ '洗衣机' } @peizhi_info;
                    $peizhi_bit_mask |= PZ_kongtiao
                      if any { $_ =~ '空调' } @peizhi_info;
                    $peizhi_bit_mask |= PZ_reshuiqi
                      if any { $_ =~ '热水器' } @peizhi_info;
                    $peizhi_bit_mask |= PZ_kuandai
                      if any { $_ =~ '宽带' } @peizhi_info;
                    $peizhi_bit_mask |= PZ_nuanqi
                      if any { $_ =~ '暖气' } @peizhi_info;
                    $peizhi_bit_mask |= PZ_meiqi
                      if any { $_ =~ '煤气' } @peizhi_info;
                    $peizhi_bit_mask |= PZ_jiaju
                      if any { $_ =~ '家具' } @peizhi_info;
                }
                $page_info->{peizhi_info} = $peizhi_bit_mask;
            }
        }
    }

    return $page_info;
}

sub log_grab_info {
    my ($self)      = @_;
    my $error_query = $self->{"error_query"};
    my $url_num     = $self->{'grab_urls'};
    my $site_source = $self->{'site_source'};
    my $time_used   = $self->{'timer'};
    my $handy_db    = $self->{'db'};
    my $page        = $self->{'page_num'};
    my $city        = $self->{'city'};
    my $table_name  = 'grab_site_info_' . $city;

    my $errors = $error_query->{error_counts} // 0;

    my $grab_info = {
        'time_used'   => $time_used->string,
        'grab_urls'   => $url_num,
        'errors'      => $errors,
        'site_source' => $site_source,
        'page'        => $page,
        'city'        => $city,
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

    my $grab_info_json   = encode_json($grab_info);
    my $error_json       = encode_json($error_query);
    my $site_info_counts = (
        $handy_db->selectrow_array(
            "SELECT COUNT(*) FROM $table_name where site_source = $site_source;"
        )
    );
    $handy_db->do( $info_sql, undef, $grab_info_json, $site_info_counts,
        $error_json );

    # 清空 error_query, grab_urls
    init_error_info($self);
}

sub detection_is_remove_from_site {
    my ($self) = @_;

    $self->start_timer();
    my $site_source = $self->{'site_source'};
    my $handy_db    = $self->{'db'};
    my $time        = $self->{'timer'};

    my $city       = $self->{'city'};
    my $table_name = 'grab_site_info_' . $city;

    my $url_sql = qq{
SELECT
  b.`id`,
  b.`url`
FROM
  $table_name b
WHERE b.`site_source` = $site_source
  AND b.remove_from_site = 0
  AND b.`check_remove_time` < DATE_ADD(CURRENT_DATE(),INTERVAL -1 DAY)
  order by id desc
;
};

    my $urls_need_to_check =
      $handy_db->selectall_arrayref( $url_sql, { Slice => {} } );
    my $total = @$urls_need_to_check;
    my $index = 0;

    for my $url_ref (@$urls_need_to_check) {
        $index++;

        if ( $index % 5 == 0 ) {
            Time::HiRes::sleep (0.4);
        }

        my $uuid = $url_ref->{'id'};
        my $url  = $url_ref->{'url'};

        my $tx = $ua->get($url);
        my $error_info = $self->check_req_error( $tx );
        if ($error_info) {
            next;
        }

        my $is_removed = $self->check_page_remove( $tx->res );

        $handy_db->do("UPDATE $table_name b SET b.remove_from_site = ? ,b.`check_remove_time` = CURRENT_DATE() WHERE b.`id` = ?",undef, $is_removed, $uuid);
    }

    say "detection_is_remove_from_site $site_source => $total . done: $time";
    $self->reset_timer();
}

sub check_page_remove {
    my ($self,$res) = @_;
    my $is_removed = 0;

    my $ganji_title = $res->dom->at('title') || '';
    if ( $ganji_title =~ m/您访问的网页不存在/g ) {
        $is_removed = 1;
    }

    my $site_fang_none_dom = $res->dom->at('div.searchnone-txt');
    if ($site_fang_none_dom) {
        my $txt = $site_fang_none_dom->all_text;
        $txt = decode( 'gb2312', $txt );
        if ( $txt =~ m/该房源不存在/g ) {
            $is_removed = 1;
        }
    }

    my $site_58_body = $res->body;
    $site_58_body = decode( 'utf8', $site_58_body );
    if ( $site_58_body =~ m/你要找的页面不在这个星球上/g ) {
        $is_removed = 1;
    }
    return $is_removed;

}

sub get_proxy_urls{
    my ($self,$total) = @_;
    my $ua = init_mojo();

    my $url_hash =();
    my @test_urls = ('http://cd.58.com/zufang/','http://hz.58.com/hezu/','http://cd.ganji.com/fang1/m1/','http://zu.cd.fang.com/house/n31/');

    for (1..$total) {
        my $page = $_;
        my $delay_time = $page;

        Mojo::IOLoop->timer($delay_time => sub{
                                my ($delay) = @_;
                                my $res = $ua->get("http://www.proxy-ip.cn/other/1/$page")->res;
                                my $dom = $res->dom;
                                $dom->find('table.proxy_table tr')->each(sub{
                                                                             my ($tr) = @_;
                                                                             my $tds = $tr->find('td')->map('text')->to_array;
                                                                             my ($ip,$port,$location,$type) = @$tds[0,1,2,4];

                                                                             if ($location =~ m/中国/g && $type =~ m/高匿/g) {
                                                                                 my $url = qq(http://$ip:$port);
                                                                                 my $url_is_ok = 1;
                                                                                 for my $test_url (@test_urls) {
                                                                                     my $error = $ua->get($test_url)->res->error;
                                                                                     if ($error) {
                                                                                         p $error;
                                                                                         $url_is_ok = 0;
                                                                                     }
                                                                                 }

                                                                                 if ($url_is_ok) {
                                                                                     $url_hash->{$url} = 1;
                                                                                 }
                                                                             }
                                                                         });
                            });
    }

    Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

    return [keys %$url_hash];
}



sub start_timer {
    my ($self) = @_;
    my $time_used = Timer::Simple->new();
    $self->{'timer'} = $time_used;
}

sub reset_timer {
    my ($self) = @_;
    $self->{'timer'}->start;
}

sub start {
    my ($self) = @_;

    my $page_total  = $self->{'page_total'};
    my $site_source = $self->{'site_source'};

    my $delay = Mojo::IOLoop->delay();
    $self->start_timer();
    $self->grab_page($delay);

    $delay->on(
        finish => sub {
            my $task      = shift;
            my $page_num  = $self->{'page_num'};
            my $timer     = $self->{'timer'};
            my $grab_urls = $self->{'grab_urls'};
            my $city      = $self->{'city'};

            say "---------------- done grab $city site=> $site_source, page=> $page_num, time=> $timer, urls=> $grab_urls";

            my $is_last_page = $page_num == $page_total;

            if ($is_last_page) {
                $self->log_grab_info();
                $self->reset_timer();

                $self->{page_num} = 1;
            }
            else {
                $self->{page_num}++;
            }

            if(DateTime->now->hour == 23){
                exit;
            }

            # 如果 grab_urls 为 0 代表当页没有新的数据或者是爬虫抓取太快. 暂停一会儿.
            my $next_time = $grab_urls ? 1 : 60;

            Mojo::IOLoop->timer(
                $next_time => sub {
                    $self->grab_page($task);
                }
            );
        }
    );

    return $delay;
}



1;
