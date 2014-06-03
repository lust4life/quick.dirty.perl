use strict;
use warnings;
use feature qw(say);

say qq/\nthis is some test string : hello come on,乐趣 : )\n/;

my $all_txt = ();
while(glob "logfile*"){
  open FH,"<$_" or die "can not open $_ : $!";
  my @all_log = <FH>;
  my  $temp_txt = join "",@all_log;
  chomp($temp_txt);
  $temp_txt .= "\n";
  $all_txt .= $temp_txt;
}

say "===============>";
my $exceptions =  () =  ($all_txt =~ /\d{4}-\d{2}-\d{2}/g);
say $exceptions;

my $count = 0 ;
my $total = 0;

while($count = $all_txt =~ s/(\d{4}-\d{2}-\d{2}.{0,50}未知异常.{0,300}找不到.*?)(\d{4}-\d{2}-\d{2})/$2/sg){
  $total += $count;
};

while($count = $all_txt =~ s/(\d{4}-\d{2}-\d{2}.{0,50}未处理异常.{0,100}Unicode.*?)(\d{4}-\d{2}-\d{2})/$2/sg){
  $total += $count;
}

open WH,">result.txt" or die "can not create result.txt : $!";
say WH $all_txt;
close WH;

say qq(====> $total);
