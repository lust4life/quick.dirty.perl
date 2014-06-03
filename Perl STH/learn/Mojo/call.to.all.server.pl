use 5.18.2;
use strict;
use warnings;
use diagnostics;
use Mojo::UserAgent;
use Data::Printer colored => 1;

my $request_url = qq(http://resource.apollo.corp.ganji.com/Domain/GeneralJqGrid/re_jqdata/q/2/nd/1401795134991/_search/true/rows/50/page/1/sidx/id/sord/desc/filters/{"groupOp":"AND","rules":[{"field":"ip","op":"bw","data":"192.168.115.157"},{"field":"port","op":"bw","data":"10086"}]}/);

my $ua = Mojo::UserAgent->new;
$ua         = $ua->request_timeout(1);
my $tx = $ua->get($request_url)->res;

my %server_infos_hash = ();
my $server_infos = $tx->json('/rows') || ();
#p $server_infos;
foreach my $server_info(@$server_infos){
  my $url_port =  $server_info->{'cell'}[12] . ':' . $server_info->{'cell'}[13];
  my $request_url = $url_port . '6/adcache/rebuildcache?donotevil=1401811201';
  my $request_result = $ua->get($request_url)->res->body;
  $server_infos_hash{$url_port} = {
                                   'request_url' => $request_url,
                                   'request_result' => $request_result
                                  };
}

p %server_infos_hash;

say "\ndone!\n";
