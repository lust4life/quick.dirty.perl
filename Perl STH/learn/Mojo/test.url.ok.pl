use 5.20.1;
use strict;
use warnings;
use diagnostics;

use Mojo::UserAgent;
use Data::Printer colored => 1;
use Encode;

my $ua = Mojo::UserAgent->new->request_timeout(3);
my %url_test_hash;
while(<DATA>){
    chomp;
    my $url = $_;
    my $res = $ua->get($url)->res;
    push @{$url_test_hash{$res->code}},$url;
}

p %url_test_hash;

my $result = p(%url_test_hash,colored=>0);
{
    my @sort_result = sort(@{$url_test_hash{'200'}});
    local $" = "\n";
    $result .= "\n\n\n@sort_result";
}


open(my $out_file,'>:encoding(utf8)','url.test.txt');
say $out_file $result;

say "\ndone!\n";


__DATA__
http://www.lightapp.cn/car/index/1786
http://www.lightapp.cn/car/index/1787
http://www.lightapp.cn/car/index/1792
http://www.lightapp.cn/car/index/1793
http://www.lightapp.cn/car/index/1794
http://www.lightapp.cn/car/index/1810
http://www.lightapp.cn/car/index/1812
http://www.lightapp.cn/car/index/1814
http://www.lightapp.cn/car/index/1816
http://www.lightapp.cn/car/index/1817
http://www.lightapp.cn/car/index/1822
http://www.lightapp.cn/car/index/1823
http://www.lightapp.cn/car/index/1824
http://www.lightapp.cn/car/index/1825
http://www.lightapp.cn/car/index/1828
http://www.lightapp.cn/car/index/1831
http://www.lightapp.cn/car/index/1833
http://www.lightapp.cn/car/index/1836
http://www.lightapp.cn/car/index/2653
http://www.lightapp.cn/car/index/2655
http://www.lightapp.cn/car/index/2658
http://www.lightapp.cn/car/index/2661
http://www.lightapp.cn/car/index/2665
http://www.lightapp.cn/car/index/2667
http://www.lightapp.cn/car/index/2668
http://www.lightapp.cn/car/index/2669
http://www.lightapp.cn/car/index/2675
http://www.lightapp.cn/car/index/2677
http://www.lightapp.cn/car/index/2681
http://www.lightapp.cn/car/index/2686
http://www.lightapp.cn/car/index/2687
http://www.lightapp.cn/car/index/3408
http://www.lightapp.cn/car/index/3426
http://www.lightapp.cn/car/index/3428
http://www.lightapp.cn/car/index/3431
http://www.lightapp.cn/car/index/3535
http://www.lightapp.cn/car/index/3591
http://www.lightapp.cn/car/index/3735
http://www.lightapp.cn/car/index/3737
http://www.lightapp.cn/car/index/4298
http://www.lightapp.cn/car/index/4320
http://www.lightapp.cn/car/index/4323
http://www.lightapp.cn/fun/index/1832
http://www.liveapp.cn/brand/index/3422
http://www.liveapp.cn/brand/index/3740
http://www.liveapp.cn/brand/index/4182
http://www.liveapp.cn/brand/index/4183
http://www.liveapp.cn/brand/index/4181
http://www.liveapp.cn/brand/index/4564
http://www.liveapp.cn/brand/index/5073
http://www.liveapp.cn/dazzle/index/5153
http://www.liveapp.cn/school/index/5071
http://www.lightapp.cn/car/index/1830
http://www.lightapp.cn/car/index/1835
http://www.lightapp.cn/coupon/index/1795
http://www.lightapp.cn/coupon/index/1796
http://www.lightapp.cn/coupon/index/1800
http://www.lightapp.cn/fun/index/1789
http://www.lightapp.cn/fun/index/1827
http://www.lightapp.cn/meeting/index/1820
http://www.lightapp.cn/meeting/index/1829
http://www.lightapp.cn/meeting/index/1840
http://www.lightapp.cn/realty/index/1788
http://www.lightapp.cn/realty/index/1819
http://www.lightapp.cn/realty/index/1837
http://www.lightapp.cn/show/index/1799
http://www.lightapp.cn/show/index/1805
http://www.lightapp.cn/show/index/1806
http://www.lightapp.cn/show/index/1811
http://www.lightapp.cn/ticket/index/1808
http://www.lightapp.cn/ticket/index/1821
http://www.lightapp.cn/brand/index/4100
http://www.lightapp.cn/brand/index/4101
http://www.lightapp.cn/brand/index/4186
http://www.lightapp.cn/brand/index/4349
http://www.lightapp.cn/brand/index/4536
http://www.lightapp.cn/car/index/2654
http://www.lightapp.cn/car/index/2660
http://www.lightapp.cn/car/index/2663
http://www.lightapp.cn/car/index/2664
http://www.lightapp.cn/car/index/2670
http://www.lightapp.cn/car/index/2672
http://www.lightapp.cn/car/index/2682
http://www.lightapp.cn/car/index/2683
http://www.lightapp.cn/car/index/2690
http://www.lightapp.cn/car/index/3409
http://www.lightapp.cn/car/index/3416
http://www.lightapp.cn/car/index/3421
http://www.lightapp.cn/car/index/3423
http://www.lightapp.cn/car/index/3427
http://www.lightapp.cn/car/index/4188
http://www.lightapp.cn/car/index/4242
http://www.lightapp.cn/car/index/4328
http://www.lightapp.cn/car/index/4488
http://www.lightapp.cn/conference/index/5195
http://www.lightapp.cn/conference/index/5260
http://www.lightapp.cn/job/index/3420
http://www.lightapp.cn/job/index/3738
http://www.lightapp.cn/meeting/index/2685
http://www.lightapp.cn/meeting/index/2689
http://www.lightapp.cn/meeting/index/3414
http://www.lightapp.cn/meeting/index/3415
http://www.lightapp.cn/meeting/index/3425
http://www.lightapp.cn/meeting/index/3592
http://www.lightapp.cn/meeting/index/4189
http://www.lightapp.cn/realty/index/2662
http://www.lightapp.cn/realty/index/2666
http://www.lightapp.cn/realty/index/2673
http://www.lightapp.cn/realty/index/2674
http://www.lightapp.cn/realty/index/2680
http://www.lightapp.cn/realty/index/2684
http://www.lightapp.cn/realty/index/2688
http://www.lightapp.cn/realty/index/3419
http://www.lightapp.cn/realty/index/3424
http://www.lightapp.cn/realty/index/3429
http://www.lightapp.cn/realty/index/3432
http://www.lightapp.cn/realty/index/4487
http://www.lightapp.cn/school/index/4321
http://www.liveapp.cn/auto/index/1790
http://www.liveapp.cn/auto/index/1797
http://www.liveapp.cn/auto/index/1802
http://www.liveapp.cn/auto/index/1809
http://www.liveapp.cn/auto/index/2676
http://www.liveapp.cn/auto/index/2678
http://www.liveapp.cn/auto/index/3407
http://www.liveapp.cn/auto/index/3410
http://www.liveapp.cn/auto/index/3411
http://www.liveapp.cn/auto/index/3417
http://www.liveapp.cn/auto/index/3739
http://www.liveapp.cn/auto/index/3741
http://www.liveapp.cn/auto/index/3742
http://www.liveapp.cn/auto/index/4085
http://www.liveapp.cn/auto/index/4190
http://www.liveapp.cn/auto/index/4241
http://www.liveapp.cn/auto/index/4243
http://www.liveapp.cn/auto/index/4322
http://www.liveapp.cn/auto/index/4324
http://www.liveapp.cn/auto/index/4325
http://www.liveapp.cn/auto/index/4326
http://www.liveapp.cn/auto/index/4327
http://www.liveapp.cn/auto/index/4414
http://www.liveapp.cn/auto/index/4489
http://www.liveapp.cn/auto/index/4562
http://www.liveapp.cn/auto/index/4565
http://www.liveapp.cn/auto/index/4797
http://www.liveapp.cn/auto/index/5083
http://www.liveapp.cn/auto/index/5148
http://www.liveapp.cn/auto/index/5177
http://www.liveapp.cn/auto/index/5180
http://www.liveapp.cn/brand/index/5207
http://www.liveapp.cn/conference/index/5154
http://www.liveapp.cn/conference/index/5259
http://www.liveapp.cn/conference/index/5261
http://www.liveapp.cn/dazzle/index/5222
http://www.liveapp.cn/dazzle/index/5455
http://www.liveapp.cn/house/index/5056
http://www.liveapp.cn/school/index/5262
http://www.liveapp.cn/school/index/5272
http://www.liveapp.cn/school/index/5410
