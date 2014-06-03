use 5.10.0;
use strict;
use warnings;
use Encode;
use utf8;
#use encoding "gbk";
binmode(STDOUT,":encoding(gbk)");
say "wo 我们";
my $hello = 'love you so much , you are awesome';
say length($hello), "\t", "'$hello'";


$hello = "编码是个问题啊";
say length($hello), "\t", $hello;

my $str = "abcd";
my $str2 = "我们";

foreach ($str, $str2)
{
        if (utf8::is_utf8($_))
        {
	  say length;
	  say ;
	  print "Yes\n";
	}
        else
        {
	  say length;
	  say ;
	  print "No\n";
        }
}



