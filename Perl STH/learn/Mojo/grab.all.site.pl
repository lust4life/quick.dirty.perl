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

my ( $page_ganji, $page_58, $page_fang ) = ( 1, 1, 1 );
my $proxy_urls = Grab::Site->get_proxy_urls();

my $pid_58 = fork();
if ($pid_58) {

    my $pid_58_hang = fork();
    if ($pid_58_hang) {
        my $grab_58_hang = Grab::Site->new(
                                           {
                                            site_source => f58,
                                            city        => 'hz',
                                            area_list =>
                                            [qw(xihuqu gongshu jianggan xiacheng hzshangcheng binjiang)],
                                            url_tpl_hash => {
                                                             q(http://hz.58.com/%s/zufang/pn%d/) =>
                                                             q(http://hz.58.com/zufang/%s.shtml),
                                                             q(http://hz.58.com/%s/hezu/pn%d/) =>
                                                             q(http://hz.58.com/hezu/%s.shtml),
                                                            },
                                            page_total => 70,
                                            proxy_urls => $proxy_urls,
                                           }
                                          );

        $grab_58_hang->start();
    } else {
        my $grab_58 = Grab::Site->new(
                                      {
                                       site_source => f58,
                                       city        => 'cd',
                                       area_list   => [
                                                       qw(wuhou jinjiang chenghua jinniu qingyangqu cdgaoxin gaoxinxiqu)
                                                      ],
                                       url_tpl_hash => {
                                                        q(http://cd.58.com/%s/zufang/pn%d/) =>
                                                        q(http://cd.58.com/zufang/%s.shtml),
                                                        q(http://cd.58.com/%s/hezu/pn%d/) =>
                                                        q(http://hz.58.com/hezu/%s.shtml),
                                                       },
                                       page_total => 70,
                                       proxy_urls => $proxy_urls,
                                      }
                                     );

        $grab_58->start();
    }

} else {
    my $pid_fang = fork();
    if ($pid_fang) {

        my $grab_fang = Grab::Site->new(
                                        {
                                         site_source => fang,
                                         city        => 'cd',
                                         area_list   => [qw(a0132 a0129 a0131 a0133 a0130 a0136 a01156)],
                                         url_tpl_hash => {
                                                          q(http://zu.cd.fang.com/house-%s/h31-i3%d-n31/) =>
                                                          q(http://zu.cd.fang.com/%s),
                                                         },
                                         page_total => 100,
                                         proxy_urls => $proxy_urls,
                                        }
                                       );

        $grab_fang->start();
    } else {

        my $grab_ganji = Grab::Site->new(
                                         {
                                          site_source => ganji,
                                          city        => 'cd',
                                          area_list   => [
                                                          qw(wuhou qingyang jinniu jinjiang chenghua gaoxing gaoxingxiqu)
                                                         ],
                                          url_tpl_hash => {
                                                           q(http://cd.ganji.com/fang1/%s/m1o%d/) =>
                                                           q(http://cd.ganji.com/fang1/%s),
                                                          },
                                          page_total => 150,
                                          proxy_urls => $proxy_urls,
                                         }
                                        );

        $grab_ganji->start();

    }
}

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
