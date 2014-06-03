use 5.16.0;
use strict;
use warnings;


say "let us try & make hands dirty!";


my $foo = "\tbar";
&say_foo;

{
  my $foo = "\t{bar}";
  &say_foo;
  say $foo;
}

&say_foo;

sub say_foo{
  say $foo;
}


while(<ARGV>){
  say if(/middle/..eof);
}
