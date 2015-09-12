use 5.20.1;
use strict;
use warnings;
use diagnostics;

use Path::Tiny;
use DateTime;

my $log = path('corn.log');

my $msg = "hello\t =>\t" . DateTime->now ."\n";
say $msg;

$log->append($msg);
