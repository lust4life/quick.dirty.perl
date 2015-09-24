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
use DBI qw(:sql_types);
use utf8;
use experimental 'smartmatch';

use enum qw(f58 ganji fang);
use List::Util qw(any);

use GrabSite;

say "ready go!";


my $pid_58 = fork();
if ($pid_58) {

    my $grab_58 =  GrabSite->new({
                                    site_source => f58,
                                    city => 'cd',
                                   });

    $grab_58->detection_is_remove_from_site();

    $grab_58 =  GrabSite->new({
                                    site_source => f58,
                                    city => 'hz',
                                   });

    $grab_58->detection_is_remove_from_site();

    $grab_58 =  GrabSite->new({
                                    site_source => f58,
                                    city => 'wh',
                                   });

    $grab_58->detection_is_remove_from_site();


} else {

    my $pid_fang = fork();
    if ($pid_fang) {

        my $grab_fang =  GrabSite->new({
                                          site_source => fang,
                                          city => 'cd',
                                         });


        $grab_fang->detection_is_remove_from_site();

    } else {

        my $grab_ganji = GrabSite->new({
                                          site_source => ganji,
                                          city => 'cd',
                                         });

        $grab_ganji->detection_is_remove_from_site();
    }
}

say "done";
