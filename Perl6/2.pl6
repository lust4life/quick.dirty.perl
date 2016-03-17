# my @a := 1..Inf;
# my @primes := @a.grep(*.is-prime);
# my @nprimes := @primes.map({ "{++state $n}: $_" });
# .say for @nprimes[^10];

.say for (1..Inf
    ==> grep(*.is-prime)
    ==> map({ "{++state $n}: $_" })
    )[^10];
    
say '-' xx 20;
    
sub postfix:<dameng> (UInt $nth) returns UInt {
    given $nth {
        when 0 { 0 }
        when 1 { 1 }
        default { ($nth-1)dameng + ($nth-2)dameng }
    }
}

say 8dameng;

sub infix:<laugh> ($str,$times) {
    return $str ~ (" D" xx $times);
} 

"simon" laugh 8;

say "-" xx 30;

say ([laugh] "simon", 1, 2, 3);

my @nths = 3, 1, 7, 9;

my @primes = gather for @nths -> $nth 
{
    take start 
    {
        (1 .. *).grep(*.is-prime)[$nth]
    };
};

.say for await @primes;