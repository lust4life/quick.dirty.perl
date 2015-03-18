use strict;
use warnings;
use diagnostics;
use 5.20.1;

use Path::Iterator::Rule;

die "Usage: $0 DIRs" if not @ARGV;

my $rule = Path::Iterator::Rule->new;

for my $file ( $rule->all( @ARGV ) ) {
    say $file;
}

say qq(\ndone!\n);
