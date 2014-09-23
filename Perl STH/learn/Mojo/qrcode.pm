package QRCode;

use 5.20.1;
use warnings;
use diagnostics;


my $zbar_cmd = q(D:\ZBar\bin\zbarimg.exe --raw);

sub decode_qr{
    my ($file_name) = @_;
    my $qr_link = qx($zbar_cmd $file_name);
    chomp($qr_link);
    return $qr_link;
}

1;
