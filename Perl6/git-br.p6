use v6;

sub MAIN(Bool :$remove){
    run <git fetch -p>;
    my $git-br = run :out, <git branch -v>;
    my @removed-brs;
    for $git-br.out.lines -> $br-info {
        if ($br-info ~~ /^\s*?(\S+)\s+\w+\s+\[gone\]\s/) {
            my $br-name = ~$0;
            run <git branch -d>, $br-name if $remove;
            @removed-brs.push: $br-name;
        }
    }
    say "branches need remove: @removed-brs[]";
    say "done." if $remove;
}