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


BEGIN{push(@INC,"e:/git/quick.dirty.perl/Perl STH/learn/DBIx-DataModel/");push(@INC,'e:/git/quick.dirty.perl/Perl STH/learn/Mojo/')};
use HandyDataSource;
use GrabSite;


say "ready go!";

my $pid_58 = fork();
if ($pid_58) {

    my $grab_58 =  Grab::Site->new({
                                    site_source => f58,
                                   });

    $grab_58->detection_is_remove_from_site();

} else {

    my $pid_fang = fork();
    if ($pid_fang) {

        my $grab_fang =  Grab::Site->new({
                                          site_source => fang,
                                         });

        $grab_fang->detection_is_remove_from_site();

    } else {

        my $grab_ganji = Grab::Site->new({
                                          site_source => ganji,
                                         });



        $grab_ganji->detection_is_remove_from_site();
    }
}

say "done";
