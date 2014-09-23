use 5.20.1;
use strict;
use warnings;
use diagnostics;

use Mojo::UserAgent;
use Data::Printer colored => 1;
use Encode;



my @url_may_be = (
                  'http://www.liveapp.cn/brand/index/','http://www.liveapp.cn/dazzle/index/','http://www.liveapp.cn/school/index/','http://www.lightapp.cn/car/index/','http://www.lightapp.cn/coupon/index/','http://www.lightapp.cn/fun/index/','http://www.lightapp.cn/meeting/index/','http://www.lightapp.cn/realty/index/','http://www.lightapp.cn/show/index/','http://www.lightapp.cn/ticket/index/','http://www.lightapp.cn/brand/index/','http://www.lightapp.cn/conference/index/','http://www.lightapp.cn/job/index/','http://www.lightapp.cn/school/index/','http://www.liveapp.cn/auto/index/','http://www.liveapp.cn/conference/index/','http://www.liveapp.cn/house/index/'

                 );

my @app_ids=(1786,1787,1792,1793,1794,1810,1812,1814,1816,1817,1822,1823,1824,1825,1828,1831,1832,1833,1836,2653,2655,2658,2661,2665,2667,2668,2669,2675,2677,2681,2686,2687,3408,3422,3426,3428,3431,3535,3591,3735,3737,3740,4182,4183,4298,4320,4323);

my $ua = Mojo::UserAgent->new->request_timeout(3);

my %app_result;

foreach my $app_id(@app_ids){
    my $is_success;
    foreach my $domain_url(@url_may_be){
        last if $is_success;

        my $data_url = "$domain_url$app_id";
        my $http_code = $ua->get($data_url)->res->code;
        if($http_code == 200){
            say $data_url;
            push(@{$app_result{'success'}}, $data_url);
            $is_success = 1;
        }
    }
    if(!$is_success){
        push(@{$app_result{'error'}}, $app_id);
    }
}


my $result = p(%app_result,colored=>0);
{
    my @sort_result = sort(@{$app_result{'success'}});
    local $" = "\n";
    $result .= "\n\n\n@sort_result";
}

open(my $out_file,'>:encoding(utf8)','app.result.guess.txt');
say $out_file $result;

say "\ndone!\n";
