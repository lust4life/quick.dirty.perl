use 5.18.1;
use Encode;

my $total_diff = q();
my $count;
while(<>){
  $result = decode("utf8",$_);
  $result = encode("gbk",$result);
#  say $result;
  $total_diff .= $result;
}

say $total_diff;

#open(WRF,">hanghang.diff") or die "can not write.";
#say WRF $total_diff;
#say "done";
