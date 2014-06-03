use strict;
use warnings;
use feature qw(say);


say q(begin);

sub binary{
  my ($n) = @_;
  return $n if $n == 1 || $n == 0;
  my $k = int($n/2);
  my $b = $n % 2;
  my $E = binary($k);
  return $E . $b;
}

say q(binary);
say binary(32);
say binary(31);
say binary(33);

say qq(\nfactorial);

sub factorial{
  my ($n) = @_;
  return 1 if $n == 0;
  return factorial($n-1) * $n;
}

say factorial(4);
say factorial(5);
say factorial(6);
say factorial(0);
say factorial(1);
#say factorial(-4);


say qq(\nhanoi);
# hanoi(n,start,end,extra)
# 解决含有N个盘子的汉诺塔问题，其中最大的盘子为#N。
# 要将整个塔从'start'移动到'end'，使用'extra'
# 作为存放盘子的临时空间

sub hanoi{
  my ($n,$start,$end,$extra,$move_disk) = @_;
  if ($n == 1){
    $move_disk->(1,$start,$end);
  }
  else{
    hanoi($n-1,$start,$extra,$end,$move_disk);
    $move_disk->($n,$start,$end);
    hanoi($n-1,$extra,$end,$start,$move_disk);
  }
}

sub print_instruction{
  my($disk,$start,$end) = @_;
  say qq(move disk #$disk from $start to $end);
}

hanoi(1,'a','c','b',\&print_instruction);
say q();
hanoi(2,'a','c','b',\&print_instruction);
say q();
hanoi(3,'a','c','b',\&print_instruction);
