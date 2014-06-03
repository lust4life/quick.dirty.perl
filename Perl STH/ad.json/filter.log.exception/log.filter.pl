use 5.16.0;

say qq/\nthis is some test string : hello come on,乐趣 : )\n/;

my $all_txt = ();

my @all_log = qw();
#while(glob "logfile*"){
while(glob "usefull.log"){
open FH,"<$_" or die "can not open $_ : $!";
  push @all_log, <FH>;
}

$all_txt = join "", @all_log;


my $exceptions =  () =  ($all_txt =~ /\d{4}-\d{2}-\d{2}/g);
say "===============> Total Exceptions:$exceptions";

my $count = 0 ;
my $total = 0;

while($count = $all_txt =~ s/(\d{4}-\d{2}-\d{2}.{0,50}未知异常.{0,300}找不到.*?)(\d{4}-\d{2}-\d{2})/$2/sg){
  $total += $count;
};

while($count = $all_txt =~ s/(\d{4}-\d{2}-\d{2}.{0,50}未处理异常.{0,100}Unicode.*?)(\d{4}-\d{2}-\d{2})/$2/sg){
  $total += $count;
}

while($count = $all_txt =~ s/(\d{4}-\d{2}-\d{2}.{0,50}广告推广接口显示异常。\nSystem\.ArgumentNullException: Value cannot be null.*?)(\d{4}-\d{2}-\d{2})/$2/sg){
  $total += $count
}

while($count = $all_txt =~ s/(\d{4}-\d{2}-\d{2}.{0,50}未处理异常.{0,100}Request.Cookies.*?)(\d{4}-\d{2}-\d{2})/$2/sg){
  $total += $count;
}

while($count = $all_txt =~ s/(\d{4}-\d{2}-\d{2}.{0,50}未知异常.{0,400}SyntaxErrorException.*?)(\d{4}-\d{2}-\d{2})/$2/sg){
  $total += $count;
}

while($count = $all_txt =~ s/(\d{4}-\d{2}-\d{2}.{0,50}广告推广接口广告异常.{0,400}NullReferenceException.*?GetTuiGuangAd.*?)(\d{4}-\d{2}-\d{2})/$2/sg){
  $total += $count;
}

while($count = $all_txt =~ s/(\d{4}-\d{2}-\d{2}.{0,50}未处理异常.{0,400}The length of the query string for this request exceeds the configured maxQueryStringLength value.*?)(\d{4}-\d{2}-\d{2})/$2/sg){
  $total += $count;
}

while($count = $all_txt =~ s/(\d{4}-\d{2}-\d{2}.{0,50}未处理异常.{0,400}The file.*?)(\d{4}-\d{2}-\d{2})/$2/sg){
  $total += $count;
}

while($count = $all_txt =~ s/(\d{4}-\d{2}-\d{2}.{0,50}URl 解析出错.*?)(\d{4}-\d{2}-\d{2})/$2/sg){
  $total += $count;
}

while($count = $all_txt =~ s/(\d{4}-\d{2}-\d{2}.{0,50}未知异常.{0,400}Collection was modified; enumeration.*?)(\d{4}-\d{2}-\d{2})/$2/sg){
  $total += $count;
}

while($count = $all_txt =~ s/(\d{4}-\d{2}-\d{2}.{0,50}广告缓存获取增量广告Id异常\nSystem.Data.EntityException: The underlying provider failed on Open.*?)(\d{4}-\d{2}-\d{2})/$2/sg){
  $total += $count;
}

while($count = $all_txt =~ s/(\d{4}-\d{2}-\d{2}.{0,50}未处理异常.{0,100}adpositionservice.*?)(\d{4}-\d{2}-\d{2})/$2/sg){
  $total += $count;
}

open WH,">result.txt" or die "can not create result.txt : $!";
say WH $all_txt;
close WH;

say qq(==============>Usefull Exceptions:), ($exceptions - $total);

