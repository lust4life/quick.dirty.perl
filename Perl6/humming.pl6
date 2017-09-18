use v6;

sub powers_of ($radix) { $radix X** [0 ... *] }; say powers_of(2)[^5];

say powers_of(2)[^5];



# https://docs.perl6.org/language/unicode_texas#Other_acceptable_single_codepoints
# https://gist.github.com/briandfoy/619638701f38817387f3e5d22d6dab12

my %hash;

BEGIN {  # Phasers on!
my @table = qw{
        «	U+00AB	<<
        »	U+00BB	>>
        ×	U+00D7	*
        ÷	U+00F7	/
        −	U+2212	-
        ∘	U+2218	o
        ≅	U+2245	=~=
        π	U+03C0	pi
        τ	U+03C4	tau
        𝑒	U+1D452	e
        ∞	U+221E	Inf
        …	U+2026	...
        ‘	U+2018	'
        ’	U+2019	'
        ‚	U+201A	'
        “	U+201C	"
        ”	U+201D	"
        „	U+201E	"
        ｢	U+FF62	Q//
        ｣	U+FF63	Q//
        ⁺	U+207A	+
        ⁻	U+207B	-
        ¯	U+00AF	-
        ⁰	U+2070	**0
        ¹	U+2071	**1
        ²	U+2072	**2
        ³	U+2073	**3
        ⁴	U+2074	**4
        ⁵	U+2075	**5
        ⁶	U+2076	**6
        ⁷	U+2077	**7
        ⁸	U+2078	**8
        ⁹	U+2079	**9
        ∘	U+2218	o
        ∅	U+2205	set()
        ∈	U+2208	(elem)
        ∉	U+2209	!(elem)
        ∋	U+220B	(cont)
        ∌	U+220C	!(cont)
        ⊆	U+2286	(<=)
        ⊈	U+2288	!(<=)
        ⊂	U+2282	(<)
        ⊄	U+2284	!(<)
        ⊇	U+2287	(>=)
        ⊉	U+2289	!(>=)
        ⊃	U+2283	(>)
        ⊅	U+2285	!(>)
        ≼	U+227C	(<+)
        ≽	U+227D	(>+)
        ∪	U+222A	(|)
        ∩	U+2229	(&)
        ∖	U+2216	(-)
        ⊖	U+2296	(^)
        ⊍	U+228D	(.)
        ⊎	U+228E	(+)
        };

while ( @table #`(I could also read from a file) ) {
        # I'd really like a @table.shift(3);
        my ( $unicode, $codepoint, $texas ) = @table.splice( 0, 3 );
        # I don't particularly like the two way hash here.
        %hash{ $unicode, $texas } = %(
                unicode   => $unicode,
                texas     => $texas,
                codepoint => $codepoint
                ) xx *;
        }
}

# I don't really need a multi here, but I'm playing with it anyway.
# multi implies sub, so I could have said "multi sub MAIN"
multi MAIN( Str $s where { %hash{$_}:exists and $_.substr(0, 1).ord > 0xAA } ) {
        say "Running the Unicode version for $s";
        show( %hash{$s} );
        }

multi MAIN( Str $s where { %hash{$_}:exists and $_.substr(0, 1).ord <= 0xAA } ) {
        say "Running the Texas version for $s";
        show( %hash{$s} );
        }

sub show ( %h ) {
        say sprintf "Unicode: %s\nTexas: %s", %h<unicode texas>,
        }
