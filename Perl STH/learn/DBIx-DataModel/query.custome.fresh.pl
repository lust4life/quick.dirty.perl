use 5.16.3;
use strict;
use warnings;
use diagnostics;
use DBI;
use YAML;
use DateTime;
use Time::Format;
use Smart::Comments;
use Data::Printer colored => 1;
use List::AllUtils qw(:all);
use Carp;
use Encode;
use Data::Dumper;
#use utf8;
use encoding "gbk";
use GJDataSource;
require 'Schema.pl';
binmode(STDERR, ':encoding(gbk)');
#binmode(STDOUT, ':encoding(gbk)');

my $file = __FILE__;
say
"hello , let us make hand dirty ;)\n\nusage: $file test/real.Default is test.\n";

my $env_str = $#ARGV < 0 ? 'test' : shift @ARGV;
say "ENV ===> $env_str\n\n";
my $is_real = $env_str eq 'real';
my $ds = GJ::DataSource->new($is_real);

# online connect
my $tg_db =
  DBI->connect( $ds->tg, GJ::DataSource::User, GJ::DataSource::Pwd,
    { mysql_enable_utf8 => 1, 'RaiseError' => 1 } )
  or die qq(unable to connect $GJ::DataSource::tg \n);

my $ms_db =
  DBI->connect( $ds->ms, GJ::DataSource::User, GJ::DataSource::Pwd,
    { mysql_enable_utf8 => 1, 'RaiseError' => 1 } )
  or die qq(unable to connect $GJ::DataSource::ms \n);

my $mana_db =
  DBI->connect( $ds->mana, GJ::DataSource::User, GJ::DataSource::Pwd,
    { mysql_enable_utf8 => 1, 'RaiseError' => 1 } )
  or die qq(unable to connect $GJ::DataSource::mana \n);



my $customer_in_db_sql = q{
SELECT DISTINCT c.`FullName` FROM gcrm.`customer` c 
WHERE c.`CityId` = 12
;
};

#my $all_customer_in_db_hashref = $tg_db->selectall_hashref($customer_in_db_sql,'FullName');

my $all_category_in_db_hashref = $mana_db->selectall_hashref('SELECT j.`category_name`,j.`script_index` FROM category_major j WHERE j.`parent_id` = 2;','script_index');

my $sql_normal_company = q{
SELECT 
  p.`company_id`,
  p.`company_name`,
  p.`puid`,
  p.`title` ,
    p.`major_category`
FROM
  beijing.`wanted_post` p 
WHERE p.`listing_status` = 5 
  AND p.`post_type` = 0 
  AND p.`ad_types` = 0 
  AND p.`agent` = 0 
  AND p.`company_name` LIKE '%北京%公司%' 
  AND p.`post_at` >= UNIX_TIMESTAMP(ADDDATE(CURRENT_DATE(), - 1)) 
  AND p.`major_category` > - 1 
GROUP BY p.`company_id` 
ORDER BY p.`post_at` DESC
LIMIT 3000 ;
};



my $sth = $ms_db->prepare($sql_normal_company);
$sth->execute;
my %company_we_need = ();
while(my $row = $sth->fetchrow_hashref()){
  my ($full_name,$puid,$title,$mac_index) = ($row->{company_name},$row->{puid},$row->{title},$row->{major_category});

  my $sql_not_in_customer = qq{SELECT c.`CustomerId` FROM gcrm.`customer` c WHERE c.`FullName` = '$full_name' AND  c.`CityId` = 12  LIMIT 1;};
  my $customer_count =  $tg_db->selectrow_array($sql_not_in_customer) // 0;
  unless($customer_count > 0){
#  unless(exists $all_customer_in_db_hashref->{$full_name}){
    # not in customer
    my $sql_not_in_opportunity = qq{
SELECT 
  count(*)
FROM
  gcrm.opportunity p
WHERE p.`Status` not in (7)
  AND p.`CityId` = 12
  AND p.`SaleGroup` = 2
  AND p.`FullName` = '$full_name'
;
};
    my $opportunity_count = $tg_db->selectrow_array($sql_not_in_opportunity);
    if($opportunity_count == 0){
      # not in opportunity
      push  @{$company_we_need{$all_category_in_db_hashref->{$mac_index}->{category_name}}}, {'puid'=>$puid,'公司名称'=>$full_name,'帖子标题'=>$title};
    }
  }
}
$ms_db->disconnect;
$tg_db->disconnect;

my $customer_data = p(%company_we_need,colored=>0);
open WFH,'>:encoding(utf8)', "customer.data" or croak "open failed.";
say WFH $customer_data;
close WFH;

say p %company_we_need;
