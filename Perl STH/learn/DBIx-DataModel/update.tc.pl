use 5.18.2;
use strict;
use warnings;
use diagnostics;
use DBI;
use Smart::Comments;
use Data::Printer colored => 1;
use Carp;
use GJDataSource;
use JSON -support_by_pp;

my $ds = GJ::DataSource->new(1);
my $tc_db = DBI->connect( $ds->tc,
                          GJ::DataSource::User,
                          GJ::DataSource::Pwd,
                          {
                           mysql_enable_utf8 => 1,
                           'RaiseError' => 1
                          }
                        ) or die qq(unable to connect $GJ::DataSource::tc\n);

my $tg_db = DBI->connect( $ds->tg,
                          GJ::DataSource::User,
                          GJ::DataSource::Pwd,
                          {
                           mysql_enable_utf8 => 1,
                           'RaiseError' => 1
                          }
                        ) or die qq(unable to connect $GJ::DataSource::tc\n);

my $json = JSON->new->allow_nonref->allow_barekey;

my $city_code_to_city_id_json = q({1100:1,1101:2,1109:3,1102:4,1103:5,1104:6,1105:7,1106:8,1107:9,1108:10,1110:11,0:12,100:13,200:14,300:15,400:16,401:17,403:18,404:19,405:20,406:21,409:22,408:23,402:24,407:25,600:26,601:27,602:28,603:29,604:30,605:31,606:32,607:33,608:34,609:35,700:36,701:37,702:38,703:39,704:40,705:41,706:42,707:43,708:44,500:45,501:46,502:47,503:48,504:49,507:50,505:51,509:52,508:53,506:54,800:55,801:56,802:57,803:58,804:59,805:60,806:61,807:62,808:63,809:64,900:65,902:66,901:67,903:68,904:69,905:70,906:71,907:72,908:73,909:74,1000:75,1001:76,1002:77,1003:78,1004:79,1005:80,1006:81,1007:82,1008:83,1300:84,1301:85,1302:86,1303:87,1304:88,1305:89,1306:90,1307:91,1308:92,1400:93,1401:94,1402:95,1403:96,1404:97,1405:98,1406:99,1407:100,1408:101,1409:102,1200:103,1201:104,1202:105,1203:106,1204:107,1205:108,1206:109,1208:110,1207:111,1209:112,1500:113,1501:114,1503:115,1504:116,1505:117,1506:118,1507:119,1502:120,1508:121,1509:122,1600:123,1601:124,1602:125,1603:126,1604:127,1605:128,1606:129,1607:130,1608:131,1609:132,1702:133,1701:134,1703:135,1704:136,1705:137,1706:138,1707:139,1708:140,1709:141,1700:142,1800:143,1801:144,1900:145,1901:146,1902:147,1903:148,1904:149,1905:150,1906:151,1907:152,1908:153,1909:154,2000:155,2001:156,2002:157,2003:158,2004:159,2005:160,2006:161,2007:162,2008:163,2009:164,2100:165,2200:166,2201:167,2202:168,2203:169,2204:170,2205:171,2206:172,2207:173,2208:174,2209:175,2300:176,2301:177,2302:178,2303:179,2304:180,2305:181,2306:182,2307:183,2308:184,2309:185,2400:186,2401:187,2402:188,2403:189,2404:190,2405:191,2406:192,2407:193,2500:194,2501:195,2502:196,2503:197,2504:198,2505:199,2506:200,2507:201,2508:202,2509:203,2600:204,2601:205,2602:206,2603:207,2604:208,2605:209,2606:210,2607:211,2608:212,2609:213,2700:214,2701:215,2702:216,2703:217,2704:218,2705:219,2706:220,2708:221,2710:222,2709:223,2707:224,2800:225,2801:226,2802:227,2803:228,2804:229,2810:230,2811:231,2812:232,2813:233,2805:234,2806:235,2807:236,2808:237,2809:238,2814:239,2815:240,2900:241,2901:242,2902:243,2903:244,2904:245,2905:246,2906:247,2910:248,2909:249,2911:250,2912:251,2907:252,2913:253,2914:254,2908:255,3000:256,3001:257,3002:258,3003:259,3004:260,3005:261,3006:262,410:263,411:264,412:265,413:266,414:267,415:268,416:269,417:270,418:271,419:272,420:273,510:274,511:275,512:276,513:277,514:278,515:279,516:280,517:281,518:282,519:283,520:284,610:285,810:286,811:287,812:288,813:289,910:290,911:291,912:292,1210:293,1211:294,1212:295,1213:296,1214:297,1215:298,1216:299,1217:300,1410:301,1411:302,1412:303,1510:304,1511:305,1512:306,1513:307,1514:308,1515:309,1610:310,1611:311,1612:312,1613:313,1614:314,1615:315,1616:316,1710:317,1711:318,1712:319,1713:320,1910:321,1911:322,2010:323,2211:324,2212:325,2213:326,2510:327,2511:328,2512:329,2513:330,2514:331,2515:332,2516:333,2610:334,2611:335,2612:336,2613:337,1516:338,2101:339,2102:340,2103:341,2104:342,2210:343,3200:344,3300:345,1802:353,2915:373,2916:374,2917:375,2918:376,1803:377,1804:378});

my $city_dic = $json->decode($city_code_to_city_id_json);

my $biz_table_basic = 'biz_balance_user_';
my $total_sql = q();

foreach(0..9){
    my $biz_table = $biz_table_basic . $_;
    my $query_sql = qq{SELECT
  b.`id`,b.`user_id`
FROM
  `$biz_table` b
WHERE b.`product_code` = 'pd_house_bidding'
  AND b.`city_id` = 0 ;
};
    my @biz_ids =  @{$tc_db->selectall_arrayref($query_sql)};
    foreach(@biz_ids){
        my ($id,$user_id) = @$_;
        my ($city_code) = $tg_db->selectrow_array("SELECT c.`CityId` FROM gcrm.`customer_account` c WHERE c.`UserId` = $user_id;");
        my $city_id = $city_dic->{$city_code};
        $total_sql .= qq{UPDATE `trading_center`.`$biz_table` b SET b.`city_id` = $city_id WHERE b.`id` = $id AND b.`user_id` = $user_id;\n};
    }
}

say $total_sql;