use 5.16.2;
use strict;
use warnings;
use diagnostics;

use LWP;
use Encode;
#use Encode::HanExtra;

say "\n" . '-' x 10 . ' well ' x 3 . '-' x 10 . "\n";

my $response = LWP::UserAgent->new()->post(
    'http://192.168.72.254/portal/logon.cgi',
    [
        PtUser   => '',
        PtPwd    => '',
        Domain   => '',
        PtButton => ''
    ]
);
my $result = decode( 'utf8', $response->content() );
say encode( 'gbk', $result ) if $result =~ s/[^\x{4e00}-\x{9fa5}]/ /g;
















