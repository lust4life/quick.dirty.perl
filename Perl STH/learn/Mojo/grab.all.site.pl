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

my $ua = Mojo::UserAgent->new;
$ua    = $ua->connect_timeout(1)->request_timeout(3);

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
                                  area_list => [qw(wuhou)],##my $area_list = qw(wuhou qingyang jinniu jinjiang chenghua gaoxing gaoxingxiqu);
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


__END__

/*
SQLyog Trial v12.01 (64 bit)
MySQL - 5.6.21 : Database - handy
*********************************************************************
*/


/*!40101 SET NAMES utf8 */;

/*!40101 SET SQL_MODE=''*/;

/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
CREATE DATABASE /*!32312 IF NOT EXISTS*/`handy` /*!40100 DEFAULT CHARACTER SET utf8 */;

USE `handy`;

/*Table structure for table `export_info` */

DROP TABLE IF EXISTS `export_info`;

CREATE TABLE `export_info` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `export_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `counts` int(11) NOT NULL,
  `export_max_id` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8;

/*Table structure for table `grab_info` */

DROP TABLE IF EXISTS `grab_info`;

CREATE TABLE `grab_info` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `grab_info` varchar(500) DEFAULT NULL,
  `site_info_counts` int(11) NOT NULL,
  `errors` text,
  `grab_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=191 DEFAULT CHARSET=utf8;

/*Table structure for table `grab_site_info` */

DROP TABLE IF EXISTS `grab_site_info`;

CREATE TABLE `grab_site_info` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `site_source` int(11) NOT NULL COMMENT '58:0,gj:1,fang:2',
  `puid` varchar(50) NOT NULL,
  `url` varchar(1000) NOT NULL,
  `price` decimal(10,2) NOT NULL,
  `show_date` datetime NOT NULL,
  `address` varchar(50) DEFAULT NULL,
  `floor` varchar(50) DEFAULT NULL,
  `room_type` varchar(50) DEFAULT NULL,
  `room_space` decimal(10,2) DEFAULT NULL,
  `house_type` varchar(50) DEFAULT NULL,
  `house_decoration` varchar(50) DEFAULT NULL,
  `region_district` varchar(50) DEFAULT NULL,
  `region_street` varchar(50) DEFAULT NULL,
  `region_xiaoqu` varchar(50) DEFAULT NULL,
  `peizhi_info` bit(20) NOT NULL DEFAULT b'0' COMMENT 'use enum qw(BITMASK:PZ_ chuang yigui shafa dianshi bingxiang xiyiji kongtiao reshuiqi kuandai nuanqi);',
  `created_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_puid` (`site_source`,`puid`),
  KEY `idx_site_source` (`site_source`),
  KEY `idx_show_date` (`show_date`)
) ENGINE=InnoDB AUTO_INCREMENT=195912 DEFAULT CHARSET=utf8;

/*Table structure for table `test` */

DROP TABLE IF EXISTS `test`;

CREATE TABLE `test` (
  `name` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
