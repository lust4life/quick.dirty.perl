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


BEGIN{push(@INC,"e:/git/quick.dirty.perl/Perl STH/learn/DBIx-DataModel/");push(@INC,'e:/git/quick.dirty.perl/Perl STH/learn/Mojo/')};
use HandyDataSource;
use GrabSite;

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


my ($page_ganji, $page_58, $page_fang) = (1,1,1);


my $grab_ganji = Grab::Site->new({
                                  db => $handy_db,
                                  site_source => ganji,
                                  ua => $ua,
                                  area_list => [qw(wohou)],##my $area_list = qw(wuhou qingyang jinniu jinjiang chenghua gaoxing gaoxingxiqu);
                                  list_page_url_tpl => q(http://cd.ganji.com/fang1/%s/m1o%d/),
                                 });

my $grab_58 =  Grab::Site->new({
                                  db => $handy_db,
                                  site_source => ganji,
                                  ua => $ua,
                                  area_list => [qw(wuhou jinjiang chenghua jinniu qingyangqu cdgaoxin gaoxinxiqu)],
                                  list_page_url_tpl => q(http://cd.58.com/%s/zufang/pn%d/),
                               });

my $grab_fang =  Grab::Site->new({
                                  db => $handy_db,
                                  site_source => ganji,
                                  ua => $ua,
                                  area_list => [qw(wohou)],
                                  list_page_url_tpl => q(http://cd.ganji.com/fang1/%s/m1o%d/),
                                 });



my $delay_ganji = Mojo::IOLoop->delay(sub{
                                          my $delay = shift;
                                          $grab_ganji->start_timer();
                                          $grab_ganji->grab_page($delay,$page_ganji);
                                      });
$delay_ganji->on(finish=>sub{
                     my $delay = shift;

                     if($page_ganji == 3){
                         # 如果这是最后一页的抓取,代表全站抓取已经完成, 记录抓取信息

                         $grab_ganji->log_grab_info();

                         $grab_ganji->reset_timer();

                         $page_ganji = 1;
                     }else{
                         $page_ganji++;
                     }

                     # 然后最后递归调用抓取
                     $grab_ganji->grab_page($delay,$page_ganji);
                 });


# my $delay_58 = Mojo::IOLoop->delay(sub{
#                                        my $delay = shift;
#                                        $grab_58->grab_page($delay,$page_58);
#                                    });
# $delay_58->on(finish=>sub{
#                   # 如果这是最后一页的抓取,代表全站抓取已经完成, 记录抓取信息

#                   # 然后最后递归调用抓取

#               });

# my $delay_fang = Mojo::IOLoop->delay(sub{
#                                          my $delay = shift;
#                                          $grab_fang->grab_page($delay,$page_fang);
#                                      });
# $delay_fang->on(finish=>sub{
#                     # 如果这是最后一页的抓取,代表全站抓取已经完成, 记录抓取信息

#                     # 然后最后递归调用抓取

#                 });


Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
