say "take 2 + 3**2 = {2 + 3 ** 2} \t" x 2;


my $num = <1 39 59 17 23 46>.pick;
if 10 < $num < 20 {
    say "$num is between 10 and 20";
}else{
    say "$num";
}

given $num {
    when (1) {
        say 1;
    }
    when $num < 50 {
        say "$num < 50";
        proceed;
    }
    when 20 < $num < 40 {
        say "20 < $num < 40";
    }
    default {
        say "default";   
    }
}

if 12 == 1|12|21 {
    say "junctions";
}