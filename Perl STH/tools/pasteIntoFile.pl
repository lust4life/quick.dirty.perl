use strict;
use warnings;
use diagnostics;

use 5.20.1;

use Win32::Clipboard;
use autodie;
use Imager;
use Getopt::Long;

my $fileName;
(GetOptions('file|f=s' => \$fileName) && $fileName) or die "Usage: $0 --file|-f Name";

my $clip = Win32::Clipboard();
if($clip->IsBitmap()){
    my $bitmap = $clip->GetBitmap();
    if($bitmap){
        my $img = Imager->new;
        $img->read(data=> $bitmap) or die $img->errstr;
        $img->write(file=>"$fileName") or die $img->errstr;
        say "done!";
    }else{
        say "no map in clipboard";
    }
}
