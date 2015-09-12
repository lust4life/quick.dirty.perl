use v6;

my @names = "foo","bar","moo";
@names = <1 2 yeah>;
say "hello here is : {join('-',@names)} ";
say @names;

for @names -> $name {
	say "my name is => $name";
}