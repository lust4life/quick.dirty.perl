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
$ua    = $ua->connect_timeout(2)->request_timeout(3);

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
                                  area_list => [qw(wuhou qingyang jinniu jinjiang chenghua gaoxing gaoxingxiqu)],
                                  #area_list => [qw(wuhou)],
                                  list_page_url_tpl => q(http://cd.ganji.com/fang1/%s/m1o%d/),
                                  page_total => 2,
                                 });

my $grab_58 =  Grab::Site->new({
                                db => $handy_db,
                                site_source => f58,
                                ua => $ua,
                                area_list => [qw(wuhou jinjiang chenghua jinniu qingyangqu cdgaoxin gaoxinxiqu)],
                                list_page_url_tpl => q(http://cd.58.com/%s/zufang/pn%d/),
                                page_total => 2,
                               });

my $grab_fang =  Grab::Site->new({
                                  db => $handy_db,
                                  site_source => fang,
                                  ua => $ua,
                                  area_list => [qw(a0132 a0129 a0131 a0133 a0130 a0136 a01156)],
                                  list_page_url_tpl => q(http://zu.cd.fang.com/house-%s/h31-i3%d-n31/),
                                  page_total => 2,
                                 });


say "ready go!";

#$grab_ganji->start();
#$grab_58->start();
#$grab_fang->start();
use enum qw(BITMASK:PZ_ chuang yigui shafa dianshi bingxiang xiyiji kongtiao reshuiqi kuandai nuanqi meiqi jiaju);

my $dom = $ua->get('http://zu.cd.fang.com/chuzu/3_164390361_1.htm')->res->dom;
#my $dom = $ua->get('http://www.xiami.com')->res->dom;

grab_detail_page_fang($dom);


sub grab_detail_page_fang{
    my ($page_dom) = @_;

    my $date_dom = $page_dom->at("div.houseInfo dl.title p[class]");
    my $date = $date_dom->text if $date_dom;
    $date =~ s<.*?(\d{4}/\d{1,2}/\d{1,2}) .*><$1>g;
    $date = DateTime->today()->ymd unless $date;


    my $page_info = {show_data=>$date,peizhi_info=>0,price=>0};

    my $summary = $page_dom->find("div.info ul>li");

    foreach my $row (@$summary) {
        my $row_text = decode('gb2312', $row->all_text);

        my ($title,$content) = ();
        if($row_text =~ m/(.+)：(.*)/g){
            $title = $1;
            $content = $2;

            $title =~ s/[\s]//g;
        }else{
            next;
        }

        given($title){
            when(/元/){
                my $price = $title =~ m/(\d+)元/g ? $1 : 0;
                $page_info->{price} = $price;
            }
            when('小区'){
                my @region = $row->find("a")->map('text')->each;
                my $district = $region[-2];
                my $street = $region[-1];

                $page_info->{region_district} = $district;
                $page_info->{region_street} = $street;
            }
            when('/(家具家电)|(配套设施)/'){
                my $peizhi_bit_mask = 0;

                if ($content) {
                    my @peizhi_info = split(',',$content);

                    $peizhi_bit_mask |= PZ_chuang if any {$_ =~ '床'} @peizhi_info;
                    $peizhi_bit_mask |= PZ_kuandai if any {$_ =~ '宽带'} @peizhi_info;
                    $peizhi_bit_mask |= PZ_dianshi if any {$_ =~ '电视'} @peizhi_info;
                    $peizhi_bit_mask |= PZ_bingxiang if any {$_ =~ '冰箱'} @peizhi_info;
                    $peizhi_bit_mask |= PZ_xiyiji if any {$_ =~ '洗衣机'} @peizhi_info;
                    $peizhi_bit_mask |= PZ_kongtiao if any {$_ =~ '空调'} @peizhi_info;
                    $peizhi_bit_mask |= PZ_reshuiqi if any {$_ =~ '热水器'} @peizhi_info;
                    $peizhi_bit_mask |= PZ_nuanqi if any {$_ =~ '暖气'} @peizhi_info;
                    $peizhi_bit_mask |= PZ_yigui if any {$_ =~ '衣柜'} @peizhi_info;
                    $peizhi_bit_mask |= PZ_shafa if any {$_ =~ '沙发'} @peizhi_info;
                    $peizhi_bit_mask |= PZ_meiqi if any {$_ =~ '煤气'} @peizhi_info;
                    $peizhi_bit_mask |= PZ_jiaju if any {$_ =~ '家具'} @peizhi_info;
                }
                $page_info->{peizhi_info} = $peizhi_bit_mask;
            }
        }
    }
    my $huxing = $page_dom->find("ul.Huxing li");
    for my $row(@$huxing){
        my $title = decode('gb2312', $row->at("p.type")->text);
        my $content = $row->at('p.info')->text;
        given($title){
            when('楼层'){
                $page_info->{floor} = $content;
            }
            when(''){

            }
        };



    }

    $page_info->{address} = $address;
    $page_info->{room_type} = $house_type;
    $page_info->{house_type} = $house_info[1];
    $page_info->{house_decoration} = $house_info[2];
    $page_info->{region_xiaoqu} = $xiaoqu_dom ? $xiaoqu_dom->text : '';
                      my $room_space = $house_info[2];
                if ($room_space =~ s/\s*(\d+).*/$1/) {
                    $page_info->{room_space} = $room_space;
                } else {
                    $page_info->{room_space} = 0;
                }


    return $page_info;
}

#Mojo::IOLoop->start unless Mojo::IOLoop->is_running;


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
