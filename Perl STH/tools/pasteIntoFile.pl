use strict;
use warnings;
use diagnostics;

use 5.20.1;

use Win32::Clipboard;
use autodie;

my $clip = Win32::Clipboard();

if($clip->IsBitmap()){
    my $bitmap = $clip->GetBitmap();
    if($bitmap){
        print "please choose file name to save:";
        my $fileName = <>;
        chomp($fileName);
        open(my $fh, ">",$fileName);
        binmode $fh;
        print $fh $bitmap;
        close $fh;
    }else{
        say "no map in clipboard";
    }
}
