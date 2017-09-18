use v6;

sub MAIN(){
    my $git-br = run :out, <git branch -v>;
    for $git-br.out.lines -> $br-info {
        if ($br-info ~~ /^\s*?(\S+)\s+\w+\s+\[gone\]\s/) {
            my $br-name = ~$0;
            run <git branch -d>, $br-name;
            say "remove branch $br-name";
        }
    }
    say "done.";
}