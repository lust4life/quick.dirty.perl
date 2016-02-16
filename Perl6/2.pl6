# my @a := 1..Inf;
# my @primes := @a.grep(*.is-prime);
# my @nprimes := @primes.map({ "{++state $n}: $_" });
# .say for @nprimes[^10];

.say for (1..Info
    ==> grep(*.is-prime)
    ==> map({ "{++state $n}: $_" })
    )[^10];