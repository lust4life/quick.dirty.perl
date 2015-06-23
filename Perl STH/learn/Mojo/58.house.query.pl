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

my $page = path('C:\Users\jiajun\Desktop\test.html');

my $mojo_dom = Mojo::DOM->new($page->slurp_utf8);



my $ua = Mojo::UserAgent->new;

my $detail_page_urls = generate_detail_page_urls('http://cd.58.com/chuzu/pn1/');
my @page_infos = map {
    my $puid = $_;
    my $detail_page_url = $detail_page_urls->{$puid};
    my $detail_page_dom = $ua->get($detail_page_url)->res->dom;
    my $page_info = grap_detail_page($detail_page_dom,$puid);
    $page_info;
} keys %$detail_page_urls;


my $page_info_json = encode_json(@page_infos);
path("c:/users/jiajun/desktop/result.txt")->spew_utf8($page_info_json);
say "\ndone!";


sub grap_detail_page{
    my ($page_dom,$puid) = @_;

    $page_dom = $page_dom->at("div#main");

    my $title = $page_dom->at("div.bigtitle")->all_text;
    my $date = $page_dom->at("li.time")->text || DateTime->today()->ymd;
    my $summary = $page_dom->find("ul.suUl>li");
    my $price = $summary->[0]->all_text;
    my $root_type = $summary->[1]->all_text;
    my $floor = $summary->[2]->all_text;
    my $rent_info = $summary->[3]->all_text;
    my $region = $summary->[4]->all_text;
    my $address = $summary->[5]->all_text;
    my $peizhi = $1 if ($page_dom->at("div.peizhi")->all_text) =~ m/tmp = '(.*)';/;

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
    $page_list_dom->find("div#infolist tr[logr]")
            ->map(attr=>'logr')
            ->each(sub{
                       my ($e,$num) = @_;
                       if ($e =~ m/(\d+)_\d_\d/){
                           my $puid = $1;
                           my $url = 'http://cd.58.com/hezu/' . $1 . 'x.shtml';
                           $detail_page_urls{$puid} = $url;
                       }
                   });

    return \%detail_page_urls;
}
