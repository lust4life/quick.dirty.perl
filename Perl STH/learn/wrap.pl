use strict;
use warnings;
use diagnostics;

use 5.20.1;

die "Usage: perl $0 text num" if $#ARGV > 1;

my($text, $max) = @ARGV;

$max = 70 if not $max;
$text = '' if not defined $text;

use Text::Wrap;

{
    local $Text::Wrap::columns = $max;
    say wrap('','',$text);
}



__END__

say qq(\n--------done by Text::Wrap---------\n);

while ($text) {
    if (length $text <= $max) {
        say $text;
        last;
    }
    my $prefix = substr $text, 0, $max;
    my $loc = rindex $prefix, ' ';

    if ($loc == -1) {
        die "We found a word which is longer than $max\n";
    }
    my $str = substr $text, 0, $loc, '';
    say $str;
    substr $text, 0, 1, '';
}
