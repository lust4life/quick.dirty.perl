use 5.18.2;
use strict;
use warnings;
use diagnostics;
use DBI;
use Smart::Comments;
use Data::Printer colored => 1;
use Carp;
use GJDataSource;

=sample4cwd
use Cwd;
my $origin_cwd = cwd;
chdir "c:/Program Files/MySQL/MySQL Server 5.5/bin";
END{
  chdir $origin_cwd;
  say "\nend\n";
}
=cut

my $ds = GJ::DataSource->new(0);
my $tc_db =
  DBI->connect( $ds->tc, GJ::DataSource::User, GJ::DataSource::Pwd,
    { mysql_enable_utf8 => 1, 'RaiseError' => 1 } )
  or die qq(unable to connect $GJ::DataSource::tc \n);

$tc_db->do("set group_concat_max_len = 1024*1024;");

my $generate_sql = q();
my $biz_table_basic = 'biz_balance_user_';
foreach(0..9){
  my $biz_table = $biz_table_basic . $_;
  my $query_sql = qq{SELECT CONCAT(
  "UPDATE `trading_center`.`$biz_table` b SET b.`amount` = 6 ,b.`amount_left` = 6 WHERE b.`order_id` IN(",
  s.ids, ") AND b.`product_code` = 'pd_post_minor_num' ;
UPDATE `trading_center`.`$biz_table` b SET b.`amount` = 8 ,b.`amount_left` = 8 WHERE b.`order_id` IN( ",
  s.ids, ") AND b.`product_code` = 'pd_manual_refresh' ;
"
) 
FROM
(SELECT 
  GROUP_CONCAT(DISTINCT b.`order_id`) AS ids 
FROM
  `$biz_table` b 
WHERE b.`category_type` = 9 
  AND b.`product_code` = 'pd_post_minor_num'
  AND b.`amount` = 3
  AND b.`status` = 1 
  AND b.`end_at` > UNIX_TIMESTAMP()) s ;
};

  $generate_sql .= $tc_db->selectrow_array($query_sql) // q();

=nouse
  $query_sql = qq{SELECT CONCAT("insert into `trading_center`.`$biz_table` (`order_id`,`order_item_id`,`user_id`,`balance_id`,`amount`,`amount_left`,`begin_at`,`end_at`,`status`,`created_at`,`duration_modified_at`,`product_code`,`city_id`,`category_type`,`extension`,`old_key`,`old_deposit_id`,`refund_at`,`package_id`,`package_type`,`log_id`,`source_type`,`usage_json`) values('",b.`order_id`,"','",b.`order_item_id`,"','",b.`user_id`,"','",b.`balance_id`,"','",500,"','",500,"','",b.`begin_at`,"','",b.`end_at`,"','",b.`status`,"','",b.`created_at`,"','",b.`duration_modified_at`,"','",'pd_refresh_point',"','",b.`city_id`,"','",b.`category_type`,"','",b.`extension`,"','",b.`old_key`,"','",b.`old_deposit_id`,"','",b.`refund_at`,"','",b.`package_id`,"','",b.`package_type`,"','",b.`log_id`,"','",b.`source_type`,"',",IFNULL(b.`usage_json`,'NULL'),");")
FROM (
SELECT * FROM `$biz_table` b WHERE b.`category_type` = 9 AND b.`product_code` = 'pd_post_minor_num' and b.`amount` = 3 AND b.`status` = 1 AND b.`end_at` > UNIX_TIMESTAMP()
) b;
};

  foreach my $row_ref (@{$tc_db->selectall_arrayref($query_sql)}){
     $generate_sql .= $$row_ref[0] . qq(\r);
  }
=cut

  $generate_sql .= qq(\r\n);
}

say $generate_sql;
