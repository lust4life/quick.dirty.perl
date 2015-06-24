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


#my $page = path('C:\Users\jiajun\Desktop\test.html');
#my $mojo_dom = Mojo::DOM->new($page->slurp_utf8);

my $cwd = Path::Tiny->cwd;
my $ua = Mojo::UserAgent->new;
$ua    = $ua->connect_timeout(1)->request_timeout(2);

$ua->on(start => sub {
            my ($ua, $tx) = @_;
            $tx->req->headers->user_agent('Mozilla/5.0 (Windows NT 6.3; Win64; x64; rv:40.0) Gecko/20100101 Firefox/40.0');
        });

sub grap_detail_page{
    my ($page_dom) = @_;

    my $title = $page_dom->at("div.bigtitle")->all_text;
    my $date = $page_dom->at("li.time")->text || DateTime->today()->ymd;
    my $summary = $page_dom->find("ul.suUl>li");
    my $price = $summary->[0]->all_text;
    my $root_type = $summary->[1]->all_text;
    my $floor = $summary->[2]->all_text;
    my $rent_info = $summary->[3]->all_text;
    my $region = $summary->[4]->all_text;
    my $address = $summary->[5]->all_text;
    my $peizhi_dom = $page_dom->at("div.peizhi");
    my $peizhi = $1 if $peizhi_dom && (($peizhi_dom->all_text) =~ m/tmp = '(.*)';/);

    my $page_info = {
                     title => $title,
                     date => $date,
                     price =>$price,
                     root_type =>$root_type,
                     floor =>$floor,
                     rent_info =>$rent_info,
                     region =>$region,
                     address =>$address,
                     peizhi =>$peizhi ,
                    };
    return $page_info;
}

sub generate_detail_page_url_hash_ref{
    my ($page_list_dom)  = @_;
    #    my $page_list_dom = Mojo::DOM->new(path('c:/users/jiajun/desktop/test1.html')->slurp_utf8);
    my $detail_url_nums;
    my %detail_page_url_hash;
    $page_list_dom->find("div#infolist tr[logr] h1>a[href]:nth-child(1)")
            ->map(attr=>'href')
            ->each(sub{
                       my ($url) = @_;
                       if (!$url) {
                           return;
                       }

                       ++$detail_url_nums;

                       if ($url =~ m</(\d+)x\.shtml>) {
                           my $puid = $1;
                           $detail_page_url_hash{$puid} = $url;
                       } else {
                           # 这类需要跳转的 url 特殊处理
                           push @{$detail_page_url_hash{'special-url'}},$url;
                       }
                   });
    say "has details urls => $detail_url_nums";
    return \%detail_page_url_hash;
}

my @page_infos ;
my %error_query;
my $error_num ;
my $url_num ;

my $time_used = Timer::Simple->new();

Mojo::IOLoop->delay(
                    sub{
                        my $delay = shift;
                        for (1..1) {
                            my $page_list_url = sprintf('http://cd.58.com/chuzu/pn%d/',$_);
                            $ua->get($page_list_url => $delay->begin);
                        }
                    },
                    sub{
                        my ($delay,@page_list_results) = @_;
                        my @page_list_doms = map {$_->res->dom} @page_list_results;

                        for my $page_list_dom (@page_list_doms) {
                            my $detail_page_url_hash_ref = generate_detail_page_url_hash_ref($page_list_dom);

                            foreach my $puid (keys %$detail_page_url_hash_ref) {
                                my $page_info = {puid => $puid};

                                if ($puid eq 'special-url') {
                                    for my $detail_page_url (@{$detail_page_url_hash_ref->{'special-url'}}) {
                                        ++$url_num;
                                        my $delay_time = $url_num * 0.5;
                                        Mojo::IOLoop->timer( $delay_time => $delay->pass($detail_page_url));
                                    }
                                } else {
                                    my $detail_page_url = $detail_page_url_hash_ref->{$puid};
                                    ++$url_num;
                                    my $delay_time = $url_num * 0.5;
                                    Mojo::IOLoop->timer($delay_time => $delay->pass($detail_page_url));
                                }
                            }
                        }
                    },
                    sub{
                        my ($delay,@detail_page_urls) = @_;
                        say $time_used;
                        exit;
                        for my $detail_page_url(@detail_page_urls){
                            $ua->max_redirects(2)->get($detail_page_url => $delay->begin);
                        }
                    },
                    sub{
                        my ($delay,@detail_results) = @_;
                        for my $result (@detail_results) {
                            my $detail_page_dom = $result->res->dom;
                            my $url = $result->req->url->to_string;
                            try{
                                my $page_info = grap_detail_page($detail_page_dom);
                                $page_info->{'url'} = $url;
                                push @page_infos,$page_info;
                            }catch{
                                $error_query{error_counts} = ++$error_num;
                                my $error_info = $result->res->error;
                                $error_info->{'exception'} = $_;
                                $error_query{$url} = $error_info;

                                #                                say p $result->res; exit;
                                #                carp "error happened: $url  $_ :";
                            };
                        }
                    }
                   )->wait;

my $page_info_json = encode_json(\@page_infos);
$cwd->path("/result.json")->spew($page_info_json);

say p %error_query;
say "\ndone!time used: $time_used";
say "page_info counts => " . scalar(@page_infos) . "\ntotal urls => $url_num";
