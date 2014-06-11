use 5.18.2;
use strict;
use warnings;
use diagnostics;
use DBI;
use Smart::Comments;
use Data::Printer colored => 1;
use Carp;
use GJDataSource;
use JSON;

my $ds = GJ::DataSource->new(1);
my $tc_db = DBI->connect( $ds->tc,
                          GJ::DataSource::User,
                          GJ::DataSource::Pwd,
                          {
                           mysql_enable_utf8 => 1,
                           'RaiseError' => 1
                          }
                        ) or die qq(unable to connect $GJ::DataSource::tc\n);

my $json = JSON->new->allow_nonref;
my $biz_table_basic = 'biz_balance_user_';
my $total_sql ;
while(<DATA>){
    my $usageModle = {ExpandCities=>undef,ExpandOldItemId=>undef,ExpandProvinces=>undef};
    my ($order_id,$province,$user_id) = split(/\s/);
    my $biz_table = $biz_table_basic . ($user_id % 10);
    my $query_sql = qq{SELECT b.`city_id`,b.`usage_json`,b.`id`,b.`product_code` FROM $biz_table b WHERE b.`user_id` = $user_id AND b.`order_id` = $order_id;};
    foreach(@{$tc_db->selectall_arrayref($query_sql)}){
        my ($city_id,$usage_json,$id,$product_code) = @$_;
        if($product_code ne 'pd_sms' && $product_code ne 'pd_manual_refresh'){
            $usageModle->{ExpandProvinces} = [int($province)];
            $usage_json = $json->encode( $usageModle );
            $total_sql .= qq{UPDATE `trading_center`.`$biz_table` b SET b.`usage_json` = '$usage_json',b.`city_id` = -1 WHERE b.`id` = $id;\n};
        }
    }
}
say $total_sql;

__DATA__
7234677	13	325496605
7243703	5	325504567
7248359	13	325492987
7274511	7	324669859
7275357	7	324744931
