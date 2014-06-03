use 5.16.2;
use strict;
use warnings;
use diagnostics;
use Data::Dumper;
#use utf8;
#use encoding "gbk";

die "usage: $0 <filename> \n\n" if $#ARGV < 0;
say qq(let us begin:\n);


my %url_hash = ();

open(SFH,"url.txt") or die "can not open source file $!";
while(<SFH>){
  chomp;
  $url_hash{$_} = 0;
}
close SFH;

#say Dumper(\%url_hash);

#url_hash is ok. now filter from 3 files in the server.
my ($test_count,$ok_count) = (0,0);
while(<>){
  my($url,$count) = split(/,/,$_);
   if(exists $url_hash{$url}){
    $url_hash{$url} += $count;
    $ok_count++;
  }
  $test_count++;
  say $test_count unless $test_count % 100000;
}

say qq(ok_count : $ok_count);
say qq(all_count: $test_count);

#write into file
open(WFH, ">:encoding(UTF-8)", 'result.txt') or die "can not creat sql file ==> $!\n";
while(my($url,$count) = each %url_hash){
  my $str = sprintf("%-100s%-20s",$url,$count);
  say WFH $str;
}
close WFH;
say Dumper(\%url_hash);
say 'end';


