use 5.16.3;
use strict;
use warnings;
use diagnostics;

use Mojo::UserAgent;
use Data::Printer colored => 1;
use Encode;

binmode( STDERR, ':encoding(gbk)' );
binmode( STDOUT, ':encoding(gbk)' );

my ( $uname, $env_str ) = @ARGV;
$env_str = $env_str || 'test';
my $is_real = ( $env_str eq 'real' );
say "ENV ===>" . ( $is_real ? 'real' : 'test' ) . "\n\n";

my $sso_url =
  $is_real
  ? "sso.corp.ganji.com/Account/LogOn"
  : "sso.test.corp.ganji.com/Account/LogOn";
my $crm_url = $is_real ? "gcrm.corp.ganji.com" : "gcrm.test.corp.ganji.com";

my $ua = Mojo::UserAgent->new;

my $get_user_id_url =
  $crm_url . "/HousingTask/ExsitGanjiUser?userNameOrEmail=" . $uname;
my $tx = $ua->post(
    $sso_url,
    => { DNT => 1 } => json => {
        UserName => 'qianjiajun',
        Password => $is_real ? 'suyang2`' : 'suyang',
        Domain   => '@ganji.com',
    }
);

say 'start get_user_id';
$tx = $ua->build_tx( GET => $get_user_id_url );

my $content = decode( 'utf8', $ua->start($tx)->res->body );

my $user_id;
if ( $content =~ /^(\d*) / ) {
    $user_id = $1;
    if ( $user_id > 0 ) {
        say 'user_id => ' . $user_id . "\n\n";
        my $tc_info_url =
          $crm_url . '/TradingCenter/DepositList?userid=' . $user_id;
        my $open_chrome_cmd = "start chrome $tc_info_url";
        system($open_chrome_cmd);
        exit;
    }
}

say 'no user';

say "end!";
