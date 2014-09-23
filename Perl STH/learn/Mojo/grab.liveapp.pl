use 5.20.1;
use strict;
use warnings;
use diagnostics;

use Mojo::UserAgent;
use Data::Printer colored => 1;
use Encode;
use MIME::Base64;

use QRCode;

my $ua = Mojo::UserAgent->new->request_timeout(3);

my $domain = q(http://www.liveapp.cn);
my $data_url_tmp = qq($domain/auto/index/%s);




my %app_result;

foreach(<DATA>){
    chomp;
    my $qr_url = $_;
    if($qr_url =~ /\/5\/(?<app_id>\d+)\//xms){
        my $app_id = $+{app_id};
        my $data_url = sprintf($data_url_tmp,$app_id);
        my $http_code = $ua->get($data_url)->res->code;
        if($http_code == 200){
            push(@{$app_result{'success'}}, $data_url);
        }else{
            # call zbar to decode qrcode
            my $qr_code_url = "$domain$qr_url";
            my $qr_img_file_path = "qrcode/$app_id.png";
            if(not -e $qr_img_file_path){
                $ua->get($qr_code_url)->res->content->asset->move_to($qr_img_file_path);
            }else{
                say "skip download qr code img";
            }
            $data_url = QRCode::decode_qr($qr_img_file_path);
            $data_url =~ s/\?.*\Z//xms;
            push(@{$app_result{'success'}}, $data_url || $app_id);
        }
    }else{
        $app_result{'qr_code_not_match'}{$qr_url} = undef;
    }
}


my $result = p(%app_result,colored=>0);
{
    my @sort_result = sort(@{$app_result{'success'}});
    local $" = "\n";
    $result .= "\n\n\n@sort_result";
}

open(my $out_file,'>:encoding(utf8)','app.result.txt');
say $out_file $result;

say "\ndone!\n";

__DATA__
/userfiles/qrcode/5/5056/0.png
/userfiles/qrcode/5/2686/store.png
/userfiles/qrcode/5/4326/0.png
/userfiles/qrcode/5/3741/store.png
/userfiles/qrcode/5/4189/store.png
/userfiles/qrcode/5/1827/store.png
/userfiles/qrcode/5/4085/0.png
/userfiles/qrcode/5/3735/store.png
/userfiles/qrcode/5/4325/store.png
/userfiles/qrcode/5/2684/store.png
/userfiles/qrcode/5/5071/0.png
/userfiles/qrcode/5/4101/store.png
/userfiles/qrcode/5/4323/store.png
/userfiles/qrcode/5/4324/store.png
/userfiles/qrcode/5/1794/store.png
/userfiles/qrcode/5/3742/store.png
/userfiles/qrcode/5/3414/store.png
/userfiles/qrcode/5/2655/store.png
/userfiles/qrcode/5/1812/store.png
/userfiles/qrcode/5/2668/store.png
/userfiles/qrcode/5/5083/0.png
/userfiles/qrcode/5/3416/store.png
/userfiles/qrcode/5/4797/0.png
/userfiles/qrcode/5/2661/store.png
/userfiles/qrcode/5/1788/store.png
/userfiles/qrcode/5/2677/store.png
/userfiles/qrcode/5/3431/store.png
/userfiles/qrcode/5/2670/store.png
/userfiles/qrcode/5/4186/store.png
/userfiles/qrcode/5/1822/store.png
/userfiles/qrcode/5/5222/0.png
/userfiles/qrcode/5/3738/store.png
/userfiles/qrcode/5/2676/store.png
/userfiles/qrcode/5/4243/store.png
/userfiles/qrcode/5/1840/store.png
/userfiles/qrcode/5/1835/store.png
/userfiles/qrcode/5/4488/store.png
/userfiles/qrcode/5/4536/0.png
/userfiles/qrcode/5/4182/store.png
/userfiles/qrcode/5/2685/store.png
/userfiles/qrcode/5/1786/store.png
/userfiles/qrcode/5/5148/0.png
/userfiles/qrcode/5/2669/store.png
/userfiles/qrcode/5/4489/store.png
/userfiles/qrcode/5/1787/store.png
/userfiles/qrcode/5/4565/0.png
/userfiles/qrcode/5/3415/store.png
/userfiles/qrcode/5/2675/store.png
/userfiles/qrcode/5/3417/store.png
/userfiles/qrcode/5/2665/store.png
/userfiles/qrcode/5/5073/0.png
/userfiles/qrcode/5/1833/store.png
/userfiles/qrcode/5/1792/store.png
/userfiles/qrcode/5/3424/store.png
/userfiles/qrcode/5/2682/store.png
/userfiles/qrcode/5/3421/store.png
/userfiles/qrcode/5/1816/store.png
/userfiles/qrcode/5/1825/store.png
/userfiles/qrcode/5/2683/store.png
/userfiles/qrcode/5/1809/store.png
/userfiles/qrcode/5/4322/store.png
/userfiles/qrcode/5/5180/0.png
/userfiles/qrcode/5/2660/store.png
/userfiles/qrcode/5/5455/0.png
/userfiles/qrcode/5/3411/store.png
/userfiles/qrcode/5/1828/store.png
/userfiles/qrcode/5/4181/store.png
/userfiles/qrcode/5/3425/store.png
/userfiles/qrcode/5/3423/store.png
/userfiles/qrcode/5/2678/store.png
/userfiles/qrcode/5/5154/0.png
/userfiles/qrcode/5/1820/store.png
/userfiles/qrcode/5/2664/store.png
/userfiles/qrcode/5/1830/store.png
/userfiles/qrcode/5/4414/0.png
/userfiles/qrcode/5/4188/store.png
/userfiles/qrcode/5/1819/store.png
/userfiles/qrcode/5/3432/store.png
/userfiles/qrcode/5/1832/store.png
/userfiles/qrcode/5/4298/store.png
/userfiles/qrcode/5/1831/store.png
/userfiles/qrcode/5/3426/store.png
/userfiles/qrcode/5/1797/store.png
/userfiles/qrcode/5/3419/store.png
/userfiles/qrcode/5/1802/store.png
/userfiles/qrcode/5/1810/store.png
/userfiles/qrcode/5/1799/store.png
/userfiles/qrcode/5/2689/store.png
/userfiles/qrcode/5/1814/store.png
/userfiles/qrcode/5/3740/store.png
/userfiles/qrcode/5/5195/0.png
/userfiles/qrcode/5/3428/store.png
/userfiles/qrcode/5/1795/store.png
/userfiles/qrcode/5/4321/store.png
/userfiles/qrcode/5/5272/0.png
/userfiles/qrcode/5/4242/store.png
/userfiles/qrcode/5/4487/store.png
/userfiles/qrcode/5/2653/store.png
/userfiles/qrcode/5/3739/store.png
/userfiles/qrcode/5/1824/store.png
/userfiles/qrcode/5/1793/store.png
/userfiles/qrcode/5/2688/store.png
/userfiles/qrcode/5/5207/0.png
/userfiles/qrcode/5/1789/store.png
/userfiles/qrcode/5/1808/store.png
/userfiles/qrcode/5/4183/store.png
/userfiles/qrcode/5/4328/store.png
/userfiles/qrcode/5/4190/store.png
/userfiles/qrcode/5/5410/0.png
/userfiles/qrcode/5/2690/store.png
/userfiles/qrcode/5/3407/store.png
/userfiles/qrcode/5/3420/store.png
/userfiles/qrcode/5/2673/store.png
/userfiles/qrcode/5/2658/store.png
/userfiles/qrcode/5/2666/store.png
/userfiles/qrcode/5/3591/store.png
/userfiles/qrcode/5/2674/store.png
/userfiles/qrcode/5/4564/0.png
/userfiles/qrcode/5/5262/0.png
/userfiles/qrcode/5/5259/0.png
/userfiles/qrcode/5/3427/store.png
/userfiles/qrcode/5/2663/store.png
/userfiles/qrcode/5/3410/store.png
/userfiles/qrcode/5/2654/store.png
/userfiles/qrcode/5/3422/store.png
/userfiles/qrcode/5/1817/store.png
/userfiles/qrcode/5/1837/store.png
/userfiles/qrcode/5/1811/store.png
/userfiles/qrcode/5/2662/store.png
/userfiles/qrcode/5/1790/store.png
/userfiles/qrcode/5/4327/0.png
/userfiles/qrcode/5/4349/0.png
/userfiles/qrcode/5/1805/store.png
/userfiles/qrcode/5/5260/0.png
/userfiles/qrcode/5/2672/store.png
/userfiles/qrcode/5/2681/store.png
/userfiles/qrcode/5/1829/store.png
/userfiles/qrcode/5/4100/0.png
/userfiles/qrcode/5/5153/0.png
/userfiles/qrcode/5/1823/store.png
/userfiles/qrcode/5/2687/store.png
/userfiles/qrcode/5/1796/store.png
/userfiles/qrcode/5/5177/0.png
/userfiles/qrcode/5/4320/store.png
/userfiles/qrcode/5/4562/0.png
/userfiles/qrcode/5/1836/store.png
/userfiles/qrcode/5/2680/store.png
/userfiles/qrcode/5/3429/store.png
/userfiles/qrcode/5/1800/store.png
/userfiles/qrcode/5/3409/store.png
/userfiles/qrcode/5/3592/store.png
/userfiles/qrcode/5/1806/store.png
/userfiles/qrcode/5/4241/store.png
/userfiles/qrcode/5/3737/store.png
/userfiles/qrcode/5/2667/store.png
/userfiles/qrcode/5/5261/0.png
/userfiles/qrcode/5/3408/store.png
/userfiles/qrcode/5/1821/store.png
/userfiles/qrcode/5/3535/store.png
