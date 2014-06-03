use 5.16.2;
use warnings;
use diagnostics;

die "usage:",__FILE__," url_host limit_count" if $#ARGV < 1;
my ($ip_host,$limit) = @ARGV;

my $url_pattern = qr/ \/adrender.aspx (callback.*? )/;
my %url_hash;
my $count = 0;

use Time::HiRes qw(gettimeofday);
my $start_microsec = &get_microsec_now();

for(glob "*.log"){
  open FH,"<$_" or die "can not open $_ :$!";
  while(<FH>){
    if($_ =~ $url_pattern){
      my $url = qq($ip_host:10087/tuiguangservice.aspx?$1);
      $url_hash{$url} = undef;
      say $count unless $count++ % 10000;
    }
  }
}

my $end_microsec = &get_microsec_now();
my $time_used    = ( $end_microsec - $start_microsec );

say qq(\n\n================>);
printf( "search time used  : %.4f s\n", $time_used );
say qq();
say $count;
say qq();


#say "\nDumper\n";
#use YAML;
#say Dump(%adType_url_hash);
#use Data::Dumper;
#say Dumper(%adType_url_hash);


# write into file

$start_microsec = &get_microsec_now();

open WH, ">result.txt" or die "can not create file result.txt :$!";
my $for_index = 0;
foreach(keys %url_hash){
  if($for_index++ < $limit){
    say WH;
  }else{
    last;
  }
}
#say WH join("\n", keys %url_hash);

$end_microsec = &get_microsec_now();
$time_used    = ( $end_microsec - $start_microsec );

say qq(\n\n================>);
printf( "write file time used  : %.4f s\n", $time_used );
say qq(\nEnd\n);

sub get_microsec_now {
    my ( $sec, $microsec ) = gettimeofday;
    return $sec + $microsec / 1000000;
}
