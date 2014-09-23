use 5.20.1;
use strict;
use warnings;
use diagnostics;

use Mojo::UserAgent;
use Data::Printer colored => 1;
use Encode;


my $ua = Mojo::UserAgent->new->request_timeout(1);


my $data_url_tmp = q(http://www.liveapp.cn/store?ajax=1&p=%s);
my $page;

my %total_qr;

foreach(1..14){
    $page = $_;
    my $data_url = sprintf($data_url_tmp,$page++);
    my $json_result = $ua->get($data_url)->res->json('/data/data');

    undef @total_qr{ map {$_->{qrcode}} @$json_result };
}

{
    local $" = "\n";
    my @qr_codes = keys %total_qr;
    print "@qr_codes";
}
