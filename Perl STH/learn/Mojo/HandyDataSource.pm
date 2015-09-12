package Handy::DataSource;

use strict;
use warnings;
use diagnostics;
use feature ":5.16";
use parent qw/Exporter/;

#our @EXPORT = qw/User Pwd $db/;
our $VERSION = 1.0;

use constant {
  User => 'lust',
    Pwd  => 'lust',
      TestIP => 'localhost',
        RealIP => '172.16.1.193',
  };

sub new{
  my $class = shift;
  my $is_real_env= $_[0];
  my $use_ip = $is_real_env ? RealIP : TestIP;
  my $self = {
              is_real_env => $is_real_env,
              tg          => qq(DBI:mysql:database=gcrm;host=$use_ip;port=3320),
              ms          => qq(DBI:mysql:database=beijing;host=$use_ip;port=3310),
              tc          => qq(DBI:mysql:database=trading_center;host=$use_ip;port=3321),
              mana          => qq(DBI:mysql:database=management;host=$use_ip;port=3311),
              handy          => qq(DBI:mysql:database=handy;host=$use_ip;port=3306),
             };
  bless($self,$class);
  return $self;
}

sub env{
  my $self = shift;
  return $self->{is_real_env};
}

sub tg{
  return $_[0]->{tg};
}

sub ms{
  return $_[0]->{ms};
}

sub mana {
  return $_[0]->{mana};
}

sub tc {
  return $_[0]->{tc};
}

sub handy {
  return $_[0]->{handy};
}

1;
