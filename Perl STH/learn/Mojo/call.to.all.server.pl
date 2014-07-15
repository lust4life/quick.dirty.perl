use 5.18.2;
use strict;
use warnings;
use diagnostics;
use Mojo::UserAgent;
use Data::Printer colored => 1;

my $request_url = qq(http://resource.apollo.corp.ganji.com/Domain/GeneralJqGrid/re_jqdata/q/2/nd/1401795134991/_search/true/rows/50/page/1/sidx/id/sord/desc/filters/{"groupOp":"AND","rules":[{"field":"ip","op":"bw","data":"192.168.113.161"},{"field":"port","op":"bw","data":"5555"}]}/);

my $ua = Mojo::UserAgent->new;
$ua         = $ua->request_timeout(1);
my $tx = $ua->get($request_url)->res;

my %server_infos_hash = ();
my $server_infos = $tx->json('/rows') || ();
#p $server_infos;
foreach my $server_info(@$server_infos){
  my $url_port =  $server_info->{'cell'}[12] . ':' . $server_info->{'cell'}[13];
#  my $request_url = $url_port . '/adcache/rebuildcache?donotevil=1401811201';
  my $request_url = $url_port . '/StoreService/Contract/RefreshCommodity.json';

  my $request_result = undef;
  if($ua->get($request_url)->res->body =~ m/1010151000096/){
	$request_result = $&;
  }
  
  $server_infos_hash{$url_port} = {
                                   'request_url' => $request_url,
                                   'request_result' => $request_result
                                  };
}

p %server_infos_hash;

say "\ndone!\n";
