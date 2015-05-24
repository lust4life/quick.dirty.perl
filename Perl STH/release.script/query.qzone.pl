use strict;
use warnings;
use diagnostics;

use 5.20.1;

use Carp;
use Data::Printer colored=>1;
use Mojo::UserAgent;
use Mojo::JSON qw(encode_json decode_json);
use Path::Tiny;
use DateTime;
use Encode;
use utf8;
use Timer::Simple;

binmode(STDOUT,":encoding(gbk)");

my $site_root_dir = path('e:/git/lust4life/src/org/life/');

my $ua = Mojo::UserAgent->new;

my $g_tk = q(793542699);


my $query_url_fomat = q(http://taotao.qq.com/cgi-bin/emotion_cgi_msglist_v6?pos=%d&num=%d&code_version=1&format=json&g_tk=%s);

my %file_name_hash;


sub process_msg{

    my $data = shift;
    my $tid = $data->{'tid'};

    # get msg with no truncate
    my $query_msg_detail_url =sprintf(q(http://taotao.qq.com/cgi-bin/emotion_cgi_msgdetail_v6?g_tk=%s&tid=%s&uin=276805281&not_trunc_con=1&code_version=1&format=fs),$g_tk,$tid);

    my $data_from_server = $ua->get($query_msg_detail_url)->res->body;
    my $msg = $data->{'content'};

    if ($data_from_server =~ m/frameElement\.callback\((.*})\);/si) {
        $msg = decode_json($1)->{'content'};
    }

    my $msg_info = {
                    'tid' => $tid,
                    'msg' => $msg,
                    'create_time'=> $data->{'created_time'},
                   };

    my @pic = map {
        my $pic_info = $_;
        my $img ={
                  'big' => $pic_info->{'url2'},
                  'small' => $pic_info->{'url3'},
                 };
        $img;
    } @{$data->{'pic'}};

    $msg_info->{'pics'} = \@pic;
    return $msg_info;
}

# 读取相应org模板文件，进行解析，然后写入信息
sub generate_org_file{
    my $msg = $_;
    my $create_time = DateTime->from_epoch( epoch => $msg->{'create_time'} );
    my $file_name = $create_time->strftime("%Y-%m-%d");
    if(exists $file_name_hash{$file_name}){
        $file_name_hash{$file_name}++;
        $file_name = sprintf("%s-%d",$file_name,$file_name_hash{$file_name});
    }
    my $title = $file_name;
    my $create_date = $create_time->strftime("<%Y-%m-%d %a>");

    my $pics = $msg->{'pics'};


    my $org_content = <<'end_org';
#+TITLE: %s
#+DATE: %s
#+AUTHOR: $+j
#+EMAIL: lust4life.jun@gmail.com
#+OPTIONS: ':nil *:t -:t ::t <:t H:3 \n:nil ^:t arch:headline
#+OPTIONS: author:t c:nil creator:comment d:(not "LOGBOOK") date:t
#+OPTIONS: e:t email:nil f:t inline:t num:t p:nil pri:nil stat:t
#+OPTIONS: tags:t tasks:t tex:t timestamp:t toc:t todo:t |:t
#+CREATOR: Emacs 24.4.1 (Org mode 8.2.10)
#+DESCRIPTION:
#+EXCLUDE_TAGS: noexport
#+KEYWORDS:
#+LANGUAGE: zh
#+SELECT_TAGS: export

%s

%s
end_org

    my $words = $msg->{'msg'};
    $words =~ s/\n/\n\n/;

    my $pic_html = '';
    for my $pic(@$pics){
        $pic_html .= sprintf(q(<li><a href="%s"><img src="%s"></a></li>),$pic->{'big'},$pic->{'small'});
    }

    if($pic_html){
        my $container = q(#+BEGIN_HTML
  <ul class="clearing-thumbs small-block-grid-3" data-clearing>
%s
  </ul>
#+END_HTML);

        $pic_html = sprintf($container,$pic_html);
    }

    $org_content = sprintf($org_content,$title,$create_date,$words,$pic_html);

    $site_root_dir->path($file_name . '.org')->touch->spew_utf8($org_content);
}

my $time_used = Timer::Simple->new();

Mojo::IOLoop->delay(
                    sub{
                        my ($delay) = shift;
                        my $page_num = 40;
                        for my $page(0..15){
                            my $start_index = $page * $page_num;
                            my $query_url = sprintf($query_url_fomat,$start_index,$page_num,$g_tk);
                            $ua->cookie_jar->add(
                                                 Mojo::Cookie::Response->new(
                                                                             name   => 'skey',
                                                                             value  => '@DGwKszHQ3',
                                                                             domain => '.qq.com',
                                                                             path   => '/'
                                                                            )
                                                );
                            $ua->cookie_jar->add(
                                                 Mojo::Cookie::Response->new(
                                                                             name   => 'uin',
                                                                             value  => 'o0276805281',
                                                                             domain => '.qq.com',
                                                                             path   => '/'
                                                                            )
                                                );
                            $ua->get($query_url => $delay->begin);
                        }
                    },
                    sub{
                        my ($delay, @data_from_server) = @_;
                        my @msg_infos = map {
                            my $tx = $_;
                            my $msg_list = $tx->res->json('/msglist/');
                            map {process_msg($_)} @{$msg_list};
                        } @data_from_server;

                        # 将 msg_infos 处理成 org file 进行保存
                        map {generate_org_file($_)} @msg_infos;
                        say "\n\ndone!\n";
                    }
                   )->wait;

say "all took: $time_used";
