use strict;
use warnings;
use diagnostics;

use 5.20.1;

use Term::ReadPassword::Win32 qw(read_password);

my $pwd = read_password("Password:");
say $pwd;
