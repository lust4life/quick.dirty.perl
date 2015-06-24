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


# Mojo::IOLoop::Delay->new->steps(

#                                 # First step (simple timer)
#                                 sub {
#                                     my $delay = shift;
#                                     Mojo::IOLoop->timer(2 => $delay->begin);
#                                     say 'Second step in 2 seconds.';
#                                 },

#                                 # Second step (concurrent timers)
#                                 sub {
#                                     my ($delay, @args) = @_;
#                                     Mojo::IOLoop->timer(1 => $delay->begin);
#                                     Mojo::IOLoop->timer(3 => $delay->begin);
#                                     say 'Third step in 3 seconds.';
#                                 },

#                                 # Third step (the end)
#                                 sub {
#                                     my ($delay, @args) = @_;
#                                     say 'And done after 5 seconds total.';
#                                 }
#                                )->wait;

# exit;


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

    my %detail_page_url_hash;
    $page_list_dom->find("div#infolist tr[logr] h1>a[href]:nth-child(1)")
            ->map(attr=>'href')
            ->each(sub{
                       my ($url) = @_;
                       if (!$url) {
                           return;
                       }

                       if ($url =~ m</(\d+)x\.shtml>) {
                           my $puid = $1;
                           $detail_page_url_hash{$puid} = $url;
                       } else {
                           # 这类需要跳转的 url 特殊处理
                           push @{$detail_page_url_hash{'special-url'}},$url;
                       }
                   });

    return \%detail_page_url_hash;
}


my @page_infos ;
my %error_query;
my $error_num ;
my $url_num ;

my $time_used = Timer::Simple->new();

sub process_detail_result{
    my ($ua,$result) = @_;
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


Mojo::IOLoop->delay(
                    sub{
                        my $delay = shift;
                        for (1..1) {
                            my $page_list_url = sprintf('http://cd.58.com/chuzu/pn%d/',$_);
                            my $end = $delay->begin(0);
                            $ua->get($page_list_url => sub{
                                         my ($ua,$tx) = @_;
                                         $end->($tx->res->dom);
                                     });
                        }
                    },
                    sub{
                        my ($delay,@page_list_doms) = @_;

                        for my $page_list_dom (@page_list_doms) {
                            my $detail_page_url_hash_ref = generate_detail_page_url_hash_ref($page_list_dom);

                            foreach my $puid (keys %$detail_page_url_hash_ref) {
                                my $page_info = {puid => $puid};

                                if ($puid eq 'special-url') {
                                    for my $detail_page_url (@{$detail_page_url_hash_ref->{'special-url'}}) {
                                        #                                        my $end = $delay->begin(0);
                                        ++$url_num;
                                        my $delay_time = $url_num * 0.3;
                                        Mojo::IOLoop->timer( $delay_time => sub{
                                                                 $ua->max_redirects(2)->get($detail_page_url => \&process_detail_result);
                                                             });
                                    }
                                } else {
                                    my $detail_page_url = $detail_page_url_hash_ref->{$puid};
                                    my $end = $delay->begin(0);
                                    ++$url_num;
                                    my $delay_time = $url_num * 0.3;
                                    Mojo::IOLoop->timer($delay_time => sub{
                                                            $ua->max_redirects(2)->get($detail_page_url => \&process_detail_result);
                                                        });
                                }
                            }
                        }
                    }
                   )->wait;

my $page_info_json = encode_json(\@page_infos);
$cwd->path("/result.json")->spew($page_info_json);

say p %error_query;
say "\ndone!\ntime used: $time_used";
say "page_info counts => " . scalar(@page_infos) . "\ntotal urls => $url_num";
