use strict;
use diagnostics;
use warnings;
use 5.20.1;

use Scalar::Util qw(weaken);

sub create_pair{
    my %x;
    my %y;

    $x{yname} = \%y;
    $y{xname} = \%x;

#    weaken($y{xname}); # Solution: weaken one of the circular references

    return;
}

create_pair() for 1..200000;


my $test = <>;
say $test;
