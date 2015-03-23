use v6;

my $x = 10;
my $y = 0;

my $result = $x / $y;

{
    say $result;
    CATCH{
        default{
            say "exception is $_" if $_;
        }
    }
}

say "all done!";
