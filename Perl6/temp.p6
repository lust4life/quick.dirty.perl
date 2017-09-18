use v6;
use experimental :collation;


my @list = <a ö ä Ä o ø>;
say @list;
say @list.sort;
say @list.collate;