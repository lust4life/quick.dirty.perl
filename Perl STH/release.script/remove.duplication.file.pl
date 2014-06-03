use 5.16.2;

say "hello\n";
die "usage: $0 <filename> \n\n" if $#ARGV < 0;
my %file_dic;

while(<>){
  chomp;
  s/.*V4\///;
  next if /(\.csproj$)|([(packages),(web)]\.config$)|(.*\/[^.]*$)|(\.sln$)/ ;
  unless(exists $file_dic{$_}){
    $file_dic{$_} = undef;
  }
}

open (WFH,">online.result.txt") or die "can not open online.result.txt =>$!";
my @file_paths = join("\n",sort keys %file_dic);
say @file_paths;
print WFH @file_paths;
close WFH;
say "\nall done!";
