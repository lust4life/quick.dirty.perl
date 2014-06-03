use 5.16.2;
use Encode;
use Carp;

say "\nhello come on evil guy\n";


# q1:
say "\nthis is question 1:"."=====" x 20 . "\n";
my $iterator_count = 0;
for(my $high_byte_start = 0xB0;$high_byte_start <= 0xF7;$high_byte_start++){
  for(my $low_byte_start = 0xA1;$low_byte_start <= 0xFE;$low_byte_start++){
    # exclude five unuse
    next if($high_byte_start == 0xD7 && $low_byte_start >= 0xFA && $low_byte_start <= 0xFE);
    printf "%c%c",$high_byte_start,$low_byte_start;
    print "\n" unless ++$iterator_count % 100;
  }
}




=q2:but_this_is_for_file

#say substr_gbk_from_file("test.txt",5,9);
#open(RFH,"<test.txt") or die "can not open";
#my $content = <RFH>;
#say $content;
#say substr_gbk($content,2,7);

sub substr_gbk_from_file{
  my($file_name,$start_num,$length) = @_;
  open(RFH, "<","$file_name") or die "can not open file $file_name => $!";
  my ($byte_read_in,@result_str);

  while($start_num-- > 0 && read(RFH,$byte_read_in,1)){
    if(ord($byte_read_in) & 0x80){
      read(RFH,$byte_read_in,1);
    }
  }

  while($length-- > 0 && read(RFH,$byte_read_in,1)){
    push @result_str,$byte_read_in;
    if(ord($byte_read_in) & 0x80){
      read(RFH,$byte_read_in,1);
      push @result_str,$byte_read_in;
    }
  }
  return @result_str;
}
=cut

# q2:
say "\n\nthis is question 2:" . "=====" x 20 . "\n";
say "substr_gbk(\$test_str,3,7)";
my $test_str = "这是我们的GBK字符串";
say $test_str;
say substr_gbk($test_str,3,7);
sub substr_gbk{
  my($content,$start_num,$length) = @_;
  my ($byte_char,$pos,@result_str);
  my $all_count = $length + $start_num;
  while($all_count-- > 0){
    $byte_char = substr($content,$pos++,1);
    push(@result_str,$byte_char) if($length > $all_count);
    if(ord($byte_char) & 0x80){
      $byte_char = substr($content,$pos++,1);
      push(@result_str,$byte_char) if($length > $all_count);
    }
  }
  return join '',@result_str;
}


# q3:
say "\nthis is question 3:" . "=====" x 20 . "\n";
open(RFH,"<test.utf.txt") or die "can not open";
my $content = <RFH>;
my $content_utf = decode("utf8",$content);
say "substr_utf(\$content,2,7)";
say encode("gbk",$content_utf);
say encode("gbk",decode("utf8",substr_utf($content,2,7)));

sub substr_utf{
  my($content,$start_num,$length) = @_;
  my($byte_char,$pos,@result_str);
  my $all_count = $length + $start_num;
  while($all_count-- > 0){
    $byte_char = substr($content,$pos++,1);
    push @result_str,$byte_char if $length > $all_count ;
    my $count = 0;
    given(ord($byte_char)){
      when($_ < 0x80){next;}
      when(($_ >> 5) == 0x6){$count = 1;}
      when(($_ >> 4) == 0xE){$count = 2;}
      when(($_ >> 3) == 0x1E){$count = 3;}
      when(($_ >> 2) == 0x3E){$count = 4;}
      when(($_ >> 1) == 0x7E){$count = 5;}
      default{croak "encoding error: $_ not utf";}
    }
    push @result_str,substr($content,$pos,$count) if $length > $all_count;
    $pos += $count;
  }
  return join '',@result_str;
}

# q4: 伪代码
sub gbk2utf{
  say "通过文件生成对应的hash_map,解析入口编码,\n找到对应的 unicode ,更具unicode 查找对应的 出口编码";
}
say "\nthis is question 4:" . "=====" x 20 . "\n";
gbk2utf();

# q5:
say "\nthis is question 5:" . "=====" x 20 . "\n";
say <DATA>;

say "\nok that is over.\nthx\t:D\n";

__DATA__
#没有明白问题的具体意思,正则能判断出编码?期待答案

sub is_utf8_char_from_reg{
  my($char) = @_;
  return $char =~ /(([\x00-\x7f])|([\x{c080}-\x{dfbf}])|([\x{e080}\x80-\x{efbf}\xbf])|([\x{f080}\x{8080}-\x{f7bf}\x{bfbf}])|([\x{f880}\x{8080}\x80-\x{fbbf}\x{bfbf}\xbf])|([\x{fc80}\x{8080}\x{8080}-\x{fdbf}\x{bfbf}\x{bfbf}]))/;
}

sub is_gbk_char_from_reg{
  my ($char) = @_;
  return $char =~ /([\x81-\xfe]([\x40-\x7e]|[\x80-\xfe]))/;
}




