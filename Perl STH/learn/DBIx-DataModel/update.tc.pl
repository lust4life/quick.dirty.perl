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
my $total_sql = q();
foreach(0..9){
    my $biz_table = $biz_table_basic . $_;
    my $query_sql = qq{SELECT b.`id`,b.usage_json FROM $biz_table b WHERE b.usage_json = '{"ExpandOldItemId":null,"ExpandCities":null,"ExpandProvinces":null}';};
    foreach(@{$tc_db->selectall_arrayref($query_sql)}){
        my ($biz_id,$usage_json) = @$_;
        $total_sql .= qq{UPDATE `trading_center`.`$biz_table` b SET b.`usage_json` = NULL WHERE b.`id` = $biz_id;\n};
    }
}
say $total_sql;
