use 5.16.0;

say "hello all \n";

my $test_str = "abc   ABC 123_����  ��� ��õ���ĺú�.";

say $test_str;
$test_str =~ tr/��/��/s;
say $test_str;


say "\n\n";

#END

BEGIN{
  my $current_file = __FILE__;
  open RFH,"<$current_file" or die "can not open " . __FILE__ ." ==> $!";
  say "\n". "-" x 100 . "\n";
  while(<RFH>){
    if(/^#END/){
      last;
    }
    printf("\t%s\n",$_) unless /^$/;
  }
  say "-" x 100;
  say "\n" x 2;
}

