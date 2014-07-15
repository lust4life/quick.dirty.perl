package GJ::DataSource;

use strict;
use warnings;
use diagnostics;
use feature ":5.16";
use parent qw/Exporter/;

#our @EXPORT = qw/User Pwd $db/;
our $VERSION = 1.0;

use constant {
  User => 'qianjiajun',
    Pwd  => 'fd497162d',
      TestIP => '10.3.255.21',
        RealIP => '192.168.116.20',
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

1;