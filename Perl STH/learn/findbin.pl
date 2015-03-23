use strict;
use warnings;
use diagnostics;

use 5.20.1;

use FindBin;

say "here is the findbin path:\n$FindBin::Bin\n\nand here is the script:\n$FindBin::Script\n";



use POSIX ":sys_wait_h";
use Time::HiRes qw(sleep);

my $pid = fork();
die "Could not fork\n" if not defined $pid;

if (not $pid) {
    say "In child";
    sleep 1;
    exit 3;
}

say "In parent of $pid";


while (1) {
    my $res = waitpid($pid, WNOHANG);
    say "Res: $res";
    sleep(0.1);

    if ($res == -1) {
        say "Some error occurred ", $? >> 8;
        exit();
    }
    if ($res) {
        say "Child $res ended with ", $? >> 8;
        last;
    }
}

say "about to wait()";
say wait();
say "wait() done";
