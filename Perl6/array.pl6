use v6;

my @names = "foo","bar","moo";
@names = <1 2 yeah>;
say "hello here is : {join('-',@names)} ";
say @names;

for @names -> $name {
    say "my name is => $name";
}

my @lines = "array.pl".IO.lines;

.say for keys(@lines ∩ ("use v6;", 'say @names;'));

# here is the comment

say #`(here is mutiline comments
hello !!!
) "embedded comments";



=begin comment
This is a multi line comment.
Comment 1
Comment 2
=end comment

say "multi line";
