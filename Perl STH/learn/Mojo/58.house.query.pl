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
$ua    = $ua->connect_timeout(1)->request_timeout(1);

my $time_used = Timer::Simple->new();

my $detail_page_urls = generate_detail_page_urls('http://cd.58.com/chuzu/pn1/');

my @page_infos ;
my %error_query;
foreach my $puid(keys %$detail_page_urls){
    my $page_info = {puid => $puid};

    if ($puid eq 'special-url') {
        my @special_url_page_infos = map {
            my $url = $_;
            my $time = Timer::Simple->new();
            my $detail_page_dom =$ua->max_redirects(2)->get($url)->res->dom;
            say "request: $time";
            try{
                $page_info = grap_detail_page($detail_page_dom,$puid);
            }catch{
                $error_query{$url} = $_;
#                carp "error happened: $url  $_ :";
            };

        }  @{$detail_page_urls->{'special-url'}};

        push @page_infos,@special_url_page_infos;
    } else {
        my $detail_page_url = $detail_page_urls->{$puid};
        my $time = Timer::Simple->new();
        my $detail_page_dom = $ua->get($detail_page_url)->res->dom;
        say "request: $time";

        try{
            $page_info = grap_detail_page($detail_page_dom,$puid);
        }catch{
#            carp "error happened: $detail_page_url  $_";
            $error_query{$detail_page_url} = $_;
        };
        push @page_infos,$page_info;
    }
}

my $page_info_json = encode_json(\@page_infos);
$cwd->path("/result.json")->spew($page_info_json);

say "\ndone!time used: $time_used";
say p %error_query;

sub grap_detail_page{
    my ($page_dom,$puid) = @_;
    carp "$puid page_dom is null" if !$page_dom;

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
                     puid => $puid,
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

sub generate_detail_page_urls{
    my ($page_url)  = @_;
    my $page_list_dom = $ua->get($page_url)->res->dom;
    #    my $page_list_dom = Mojo::DOM->new(path('c:/users/jiajun/desktop/test1.html')->slurp_utf8);

    my %detail_page_urls;
    $page_list_dom->find("div#infolist tr[logr] h1>a[href]:nth-child(1)")
            ->map(attr=>'href')
            ->each(sub{
                       my ($url) = @_;
                       if (!$url) {
                           return;
                       }

                       if ($url =~ m</(\d+)x\.shtml>) {
                           my $puid = $1;
                           $detail_page_urls{$puid} = $url;
                       } else {
                           # 这类需要跳转的 url 特殊处理
                           push @{$detail_page_urls{'special-url'}},$url;
                       }
                   });

    return \%detail_page_urls;
}
