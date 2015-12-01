use v6;

my @names = "foo","bar","moo";
@names = <1 2 yeah>;
say "hello here is : {join('-',@names)} ";
say @names;

for @names -> $name {
    say "my name is => $name";
}

my @lines = "array.pl6".IO.lines;

.say for keys(@lines ∩ ("use v6;", 'say @names;'));

multi test(Int $num?){
    with $num {
        say "i am a int with => " ~ $num;
    };
    without $num {
        say "i am not a int with => Any";        
    }
}

multi bad-say($num="fuck"){
    say "just a test !  => " ~ $num;
}

test(0);
test;
test(123);
bad-say "<<<<====";
bad-say;


class man{
    has $.name;
    has $.age is rw;
    has $!sex;
    
    method showAge{
        say $!sex;
    }
}

my $a-man = man.new(name =>"Huge man!",age => 18, sex=> -1);
say $a-man;
$a-man.age = 81;
say $a-man.name;
$a-man.showAge;

say $a-man.WHAT;
say $a-man.^attributes;
say $a-man.^methods;
say $a-man.^parents;

try {
    
    my Str $str;
    # $str = 123;
    
    CATCH {
        say "error!!!";
    }
}

say "!" if 'a==1@.com' ~~ /'f'/;
say "\c[WHITE SMILING FACE]";

my %hs = :age(18),:name('jiajun'),:sex("sexy"),;
say %hs;
say %hs<age>;
say %hs{'name'};

sub change($num){
    $num+1;
    say "$num in change";
    return $num;
}

my $testNum = 123;
change($testNum);
say "$testNum out of change";

my $result = False ?? "i am true" !! "i am false" ;
say $result;

if change($testNum) -> $res {
    say "here is the res => $res";
}

say "wow" if $testNum ~~ &change;


sub foo(@array [$fst, $snd]) {
  say "My first is $fst, my second is $snd ! All in all, I'm @array[].";
  # (^ remember the `[]` to interpolate the array)
}
my @tail = 1,2;
foo(@tail); #=> My first is 2, my second is 3 ! All in all, I'm 2 3

sub test-res{
    for ^5 {
        $_;
    }
}

say "test-res :" ~ test-res;

role aRole {
  has $!counter = 0;
  method print {
    say $.val;
  }
}

class a does aRole {
    has $.val = 123;
}

a.new().print;

use JSON::Tiny;
say from-json('{"a":[1,2,3,4,{"b":789}]}').perl; 


for ^5 -> $a {
  sub foo {
    state $val = rand; # This will be a different value for every value of `$a`
  }
  for ^5 -> $b {
    say foo; # This will print the same value 5 times, but only 5.
             # Next iteration will re-run `rand`.
  }
}