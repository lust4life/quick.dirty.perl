use 5.16.0;

my $word_to_search = $ARGV[0];
my $show_line_match = $ARGV[1];
say qq(the \$word_to_search we match is $word_to_search);

if($word_to_search){
  for(glob "*.less"){
    my $file = $_;
    open(FH, "<$file") or die "can not open $_ :$!";
    my $has_show_file;
    while(<FH>){
      if(/$word_to_search/){
	say $file unless $has_show_file;
	$has_show_file = 1;
	if($show_line_match){
#	  say __LINE__;
	  say qq($.===>  $_);
	}
	else{
	  last;
	}
      }
    }
    close FH;
  }
}

__DATA__

radius
