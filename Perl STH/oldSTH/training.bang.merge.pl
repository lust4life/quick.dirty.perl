use 5.16.2;

say "hello\n";
die "usage: $0 <bang_info.file> <user_info.file> \n\n" if $#ARGV < 1;
my %bang_info_hash = ();
my %user_info_hash = ();
my ($bang_info_file,$user_info_file) = @ARGV;

open(BangInfoFH,$bang_info_file) or die "can not open $bang_info_file , $!";
while(my $line = <BangInfoFH>){
  my @bang_info_row = split(/,/,$line);
  $bang_info_hash{$bang_info_row[0]}=\@bang_info_row;
}

say "\nbang_info_hash is done \n";

open (BangUserFH,$user_info_file) or die "can not open $user_info_file , $!";
while(my $line = <BangUserFH>){
  my @bang_user_row = split(/,/,$line);
  my $user_id = $bang_user_row[0];
  my $bang_info_row_ref = $bang_info_hash{$user_id};
  chomp($bang_user_row[2]);
  push(@bang_user_row,splice(@$bang_info_row_ref,1));
  $user_info_hash{$bang_user_row[0]} = \@bang_user_row;
}

say "\nuser_info_hash is done \n";

open("WF",">bang.result.csv") or die "can not open bang.result.csv to write, $!";
my $all_str = qq();
foreach my $user_info_row(values %user_info_hash){
  my $temp_row_str = join(",",@$user_info_row);
#  say $temp_row_str;
  $all_str .= $temp_row_str;
}

print WF $all_str;

say "\nall done\n";
