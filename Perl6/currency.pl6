sub guesses($name) {
    gather loop {
        take prompt "$name, make a guess?";
    }
}

sub alternate(Iterable $a, Iterable $b) {
    my $iter-a = $a.iterator;
    my $iter-b = $b.iterator;
    gather loop {
        take $iter-a.pull-one;
        take $iter-b.pull-one;
    }
}

my $number = (1..10).pick;
say "i've thought a number between 1 and 10, guess it!";

for alternate guesses('player a'), guesses('player b') {
    when $number {
        say "you win!";
        exit;
    }
    when * < $number {
        say "too low";
    }
    when * > $number {
        say "too high";
    }
}
