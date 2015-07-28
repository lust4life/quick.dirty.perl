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

use enum qw(ganji f58 fang);
use List::Util qw(any);


BEGIN{push(@INC,"e:/git/quick.dirty.perl/Perl STH/learn/DBIx-DataModel/")};
use HandyDataSource;

my $ua = Mojo::UserAgent->new;
$ua    = $ua->connect_timeout(1)->request_timeout(1);

$ua->on(start => sub {
            my ($ua, $tx) = @_;
            $tx->req->headers->user_agent('Mozilla/5.0 (Windows NT 6.3; Win64; x64; rv:40.0) Gecko/20100101 Firefox/40.0');
        });

my $ds = Handy::DataSource->new(1);

my $handy_db = DBI->connect( $ds->handy,
                             #'lust','lust',
                             'uoko-dev','dev-uoko',
                             {
                              'mysql_enable_utf8' => 1,
                              'RaiseError' => 1,
                              'PrintError' => 0
                             }
                           ) or die qq(unable to connect $Handy::DataSource::handy\n);




my $ganji = Grab::Site->new({
                             db => $handy_db,
                             site_source => ganji,
                             ua => $ua,
                            });
my $f58 =  Grab::Site->new({
                            db => $handy_db,
                            site_source => f58,
                            ua => $ua,
                           });

my $fang =  Grab::Site->new({
                             db => $handy_db,
                             site_source => fang,
                             ua => $ua,
                            });

for $page(1..2){

    $ganji->grab()

}

$ganji->grab();
$f58->grab();
$fang->grab();

Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
