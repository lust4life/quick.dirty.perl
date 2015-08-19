use 5.20.1;
use strict;
use warnings;
use diagnostics;

use Mojo::UserAgent;
use Data::Printer colored => 1;
use Encode;

use DateTime;

say "hello\t =>\t" . DateTime->now;
