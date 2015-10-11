use strict;
use warnings;
use diagnostics;

use 5.20.1;

use Carp;
use Data::Printer colored => 1;
use Mojo::UserAgent;
use Mojo::JSON qw(encode_json decode_json);
use Path::Tiny;
use DateTime;
use Encode;
use utf8;
use Timer::Simple;

binmode( STDOUT, ":encoding(gbk)" );

my $site_root_dir = path('e:/git/blog.site.src/src/org/life/');

my $ua = Mojo::UserAgent->new;
$ua->cookie_jar->add(
                     Mojo::Cookie::Response->new(
                                                 name   => 'uin',
                                                 value  => 'o0276805281',
                                                 domain => '.qq.com',
                                                 path   => '/'
                                                )
                    );

            $ua->cookie_jar->add(
                Mojo::Cookie::Response->new(
                    name   => 'skey',
                    value  => '@OZavJxqqr', # 每次修改
                    domain => '.qq.com',
                    path   => '/'
                )
            );

my $g_tk = q(2104389563);  # 每次修改

my $query_url_fomat =
        q(http://taotao.qq.com/cgi-bin/emotion_cgi_msglist_v6?pos=%d&num=%d&code_version=1&format=json&g_tk=%s);

my %file_name_hash;

sub process_msg {

    my $data = shift;
    my $tid  = $data->{'tid'};

    # get msg with no truncate
    my $query_msg_detail_url = sprintf(
                                       q(http://taotao.qq.com/cgi-bin/emotion_cgi_msgdetail_v6?g_tk=%s&tid=%s&uin=276805281&not_trunc_con=1&code_version=1&format=fs),
                                       $g_tk, $tid );

    my $data_from_server = $ua->get($query_msg_detail_url)->res->body;
    my $msg              = $data->{'content'};

    if ( $data_from_server =~ m/frameElement\.callback\((.*})\);/si ) {
        $msg = decode_json($1)->{'content'};
    }

    my $msg_info = {
                    'tid'         => $tid,
                    'msg'         => $msg,
                    'create_time' => $data->{'created_time'},
                   };

    my @pic = map {
        my $pic_info = $_;
        my $img      = {
                        'big'   => $pic_info->{'url2'},
                        'small' => $pic_info->{'url3'},
                       };
        $img;
    } @{ $data->{'pic'} };

    # 替换图片地址为本地图片

    $msg_info->{'pics'} = \@pic;

    return $msg_info;
}

# 读取相应org模板文件，进行解析，然后写入信息
sub generate_org_file {
    my $msg         = $_;
    my $create_time = DateTime->from_epoch( epoch => $msg->{'create_time'} );
    my $file_name   = $create_time->strftime("%Y-%m-%d");
    if ( exists $file_name_hash{$file_name} ) {
        $file_name_hash{$file_name}++;
        $file_name =
                sprintf( "%s-%d", $file_name, $file_name_hash{$file_name} );
    }

    # 如果 file_name 存在，跳过
    my $file_path_obj = $site_root_dir->path( $file_name . '.org' );
    exit if $file_path_obj->exists;

    my $title       = $file_name;
    my $create_date = $create_time->strftime("<%Y-%m-%d %a>");

    my $pics = $msg->{'pics'};

    my $org_content = <<'end_org';
#+OPTIONS: ':nil *:t -:t ::t <:t H:3 \n:nil ^:t arch:headline
#+OPTIONS: author:t c:nil creator:nil d:(not "LOGBOOK") date:t e:t
#+OPTIONS: email:nil f:t inline:t num:nil p:nil pri:nil prop:nil
#+OPTIONS: stat:t tags:t tasks:t tex:t timestamp:t title:t toc:t
#+OPTIONS: todo:t |:t
#+TITLE: %s
#+DATE: %s
#+AUTHOR: $+j
#+EMAIL: lust4life.jun@gmail.com
#+LANGUAGE: zh
#+SELECT_TAGS: export
#+EXCLUDE_TAGS: noexport
#+CREATOR: Emacs 24.5.1 (Org mode 8.3.1)

%s

%s

end_org

    my $words = $msg->{'msg'};
    $words =~ s/\n/\n\n/;

    my $pic_html  = '';
    my $pic_count = 0;
    for my $pic (@$pics) {
        $pic_count++;
        my $big_pic_name =
                sprintf( "life-img/%s-%s.big.jpg", $file_name, $pic_count );
        my $small_pic_name =
                sprintf( "life-img/%s-%s.small.jpg", $file_name, $pic_count );
        $ua->get( $pic->{'big'} )
                ->res->content->asset->move_to("E:/git/lust4life/life/$big_pic_name");
        $ua->get( $pic->{'small'} )
                ->res->content->asset->move_to(
                                               "E:/git/lust4life/life/$small_pic_name");
        $pic_html .= sprintf( q(<li><a href="%s"><img src="%s"></a></li>),
                              $big_pic_name, $small_pic_name );
    }

    if ($pic_html) {
        my $container = q(#+BEGIN_HTML
  <ul class="clearing-thumbs small-block-grid-3" data-clearing>
%s
  </ul>
#+END_HTML);

        $pic_html = sprintf( $container, $pic_html );
    }

    $org_content =
            sprintf( $org_content, $title, $create_date, $words, $pic_html );

    $file_path_obj->touch->spew_utf8($org_content);
}

my $time_used = Timer::Simple->new();

Mojo::IOLoop->delay(
                    sub {
                        my ($delay) = shift;
                        my $page_num = 40;
                        for my $page ( 0 .. 15 ) {
                            my $start_index = $page * $page_num;
                            my $query_url =
                                    sprintf( $query_url_fomat, $start_index, $page_num, $g_tk );
                            say $query_url;
                            $ua->get( $query_url => $delay->begin );
                        }
                    },
                    sub {
                        my ( $delay, @data_from_server ) = @_;

                        my @msg_infos = map {
                            my $tx       = $_;
                            my $msg_list = $tx->res->json('/msglist/');
                            say "no msg data from server" unless $msg_list;
                            map { process_msg($_) } @{$msg_list};
                        } @data_from_server;

                        # 将 msg_infos 处理成 org file 进行保存
                        map { generate_org_file($_) } @msg_infos;
                        say "\n\ndone!\n";
                    }
                   )->wait;

say "all took: $time_used";
