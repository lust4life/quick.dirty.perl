use v6;

class War{
    has $!start-year;
    has $!end-year;

    method fought-in($year){
        $year >= $!start-year && $year <= $!end-year
    }
};
