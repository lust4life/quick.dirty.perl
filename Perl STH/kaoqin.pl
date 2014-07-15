use 5.18.1;
use strict;
use warnings;
use diagnostics;
use Data::Printer colored => 1;


my($come_total,$go_total,$days);
while(<DATA>){
  $_ =~ s/(?<come_hour>\d+):(?<come_min>\d+),(?<go_hour>\d+):(?<go_min>\d+)/$+{come_hour}*60+$+{come_min}."\t".($+{go_hour}*60+$+{go_min})/e;
  my($come,$go) = split(/\t/,$_);
  if($come && $go){
    $come_total += $come;
    $go_total += $go;
    $days++;
  }
}



my $come_avg = int($come_total/$days);
my $go_avg = int($go_total/$days);
my $kaoqin_rate = ($go_avg - $come_avg) / 540;
my($come_hour,$come_min,$go_hour,$go_min);
$come_hour = int($come_avg/60);
$come_min = $come_avg%60;
$go_hour = int($go_avg/60);
$go_min = $go_avg%60;
printf("\t%s\t%s\t%s\t%s\n",'�ϰ��','�°��','����','������');
printf("\t%02s:%02s\t%02s:%02s\t%s\t%f\n",$come_hour,$come_min,$go_hour,$go_min,$days,$kaoqin_rate);
say "end";


__DATA__
10:07,21:09
09:45,19:13
09:50,22:22
10:16,21:23
11:07,21:14
10:02,18:58
10:06,19:48
09:08,21:15
09:15,20:03
09:44,21:13
09:47,21:43
10:16,21:23
09:37,21:50
09:55,21:13
10:07,22:04
08:27,19:14
10:32,20:18
10:20,20:30
09:56,23:08
10:14,19:09
09:44,19:45
10:42,21:14
10:10,19:48
10:21,19:48
10:06,21:50
09:58,21:00
10:54,22:48
10:11,21:21
08:57,21:09
09:51,22:35
08:05,21:12
08:34,13:01
08:11,21:00
11:10,14:50
09:34,22:54
09:41,22:03
09:54,22:13
10:30,22:54
11:14,21:21
10:50,22:18
10:00,22:01
10:21,21:56
08:36,22:33
08:11,19:36
10:36,21:40
09:45,22:53
09:23,21:55
10:48,22:51
08:20,22:28
08:31,19:55
08:33,22:00
08:29,21:43
10:40,19:02
10:39,21:43
10:28,22:27
08:26,22:33

08:38,21:32
10:26,22:08
10:55,20:33
10:07,21:37
10:27,21:18
08:30,21:39
08:27,22:14
08:25,21:41
08:38,21:29
08:43,21:57
08:33,21:44
10:20,23:12
09:48,21:41
10:10,20:51


10:36,20:23
09:54,22:19
12:50,19:26
10:30,22:43
08:32,21:51
10:45,21:49
08:39,22:15
08:41,20:40
08:43,22:52
08:48,19:59
11:34,18:23
10:15,18:55
08:18,21:50
10:26,21:31
10:52,22:43
10:39,22:20
10:25,21:40
10:17,21:55

11:19,22:25
10:00,18:51
09:26,22:24
10:59,21:10
10:28,22:15
10:58,22:44
10:18,22:27
10:16,23:14
10:46,22:20
10:41,21:25
12:00,21:28
10:49,22:12

10:28,21:33
10:45,21:33
10:39,21:41
10:57,21:32
10:27,21:04
10:50,22:54
10:49,22:17
10:31,23:13
13:26,19:17
11:03,18:39
09:39,21:33
10:32,22:28
10:06,22:23
10:05,18:20
10:25,22:12
10:49,22:24
11:26,20:56
10:13,22:05
10:50,23:21
09:52,21:33
10:23,19:36
10:55,21:45
10:47,22:19
10:33,20:44
11:25,22:38
10:21,23:25

10:32,21:55
10:32,20:09
10:44,21:16
10:32,21:18

09:40,21:31
08:37,23:02
10:14,22:12
10:49,19:27
10:02,21:35
10:23,22:11
10:53,17:12
10:40,22:06
10:19,20:21