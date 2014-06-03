use 5.16.2;
use warnings;
use diagnostics;
use Time::HiRes qw(gettimeofday);
use URI::Escape;

sub get_microsec_now {
    my ( $sec, $microsec ) = gettimeofday;
    return $sec + $microsec / 1000000;
}

say qq/\nthis is some test string : hello come on : )\n/;

my $start_microsec = get_microsec_now();
my $url_pattern = qr/&q=(.*?)&/;
my %query_hash = ();
my $count = 0;

for(glob "u_ex13052809.log"){
  open FH,"<$_" or die "can not open file $_ : $!";
  while(<FH>){
    #chomp;
    if($_ =~ $url_pattern){
      my $query_param = uri_escape($1);
      $query_hash{$query_param} = undef;
      $count++;
      say $count unless $count % 1000 ;
      last if $count >=100;
    }
  }
}

my $end_microsec = &get_microsec_now();
my $time_used    = ( $end_microsec - $start_microsec );
say qq(\n\n================>);
printf( "time used  : %.4f s\n", $time_used );
say qq();
say $count;
say qq();


#say "\nDumper\n";
#use YAML;
#say Dump(%query_hash);
use Data::Dumper;
say Dumper(keys %query_hash);


# write into file

__END__

$start_microsec = &get_microsec_now();

open WH, "query_param_result.txt" or die "can not create file: $!";
foreach(keys %query_hash){
  say WH;
}

$end_microsec = &get_microsec_now();
$time_used    = ( $end_microsec - $start_microsec );
say qq(\n\n================>);
printf( "write file time used  : %.4f s\n", $time_used );
say qq(\nEnd\n);



