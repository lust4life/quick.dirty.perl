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
use Carp;
use Encode;
use Data::Dumper;
use GJDataSource;
require 'Schema.pl';

my $file = __FILE__;
say
"hello , let us make hand dirty ;)\n\nusage: $file test/real\nDefault is test.\n";

#my $env_str = $#ARGV < 0 ? 'test' : shift @ARGV;
#say "ENV ===> $env_str\n\n";
#my $is_real = $env_str eq 'real';
my $ds = GJ::DataSource->new(0);

my $tg_db =
  DBI->connect( $ds->tg, GJ::DataSource::User, GJ::DataSource::Pwd,
    { mysql_enable_utf8 => 1, 'RaiseError' => 1 } )
  or die qq(unable to connect $GJ::DataSource::tg \n);

my $tc_db =
  DBI->connect( $ds->tc, GJ::DataSource::User, GJ::DataSource::Pwd,
    { mysql_enable_utf8 => 1, 'RaiseError' => 1 } )
  or die qq(unable to connect $GJ::DataSource::tc \n);

my $order_id = $#ARGV < 0 ? '0' : shift @ARGV;
if($order_id < 1){
  say "\n请输入需要修改的订单id\n";
  exit;
}

say "\n需要修改的订单id===> $order_id\n";

my $sql_tc_order = qq{
SELECT 
  t.`id`,t.`user_id`
FROM
  tc_order t 
WHERE t.`source_order_code` = $order_id
  AND t.`source_type` IN (1, 4) 
LIMIT 1 ;
};

my ( $tc_order_id, $user_id ) = $tc_db->selectrow_array($sql_tc_order);
if ( $tc_order_id < 1 || $user_id < 1 ) {
    say "找不到需要修改的订单,请确认输入正确的订单id : $order_id";
    exit;
}

my $table_index = $user_id % 10;

say "确认要修改库存信息为过期吗? n :取消. y:昨天过期. 2014-01-16代表具体时间.";
show_data_modified( $table_index, $tc_order_id );

my $tz         = DateTime::TimeZone::Local->TimeZone();
my $dt         = DateTime->today()->subtract( seconds => 1 );
my $expir_time = $dt->epoch() - $tz->offset_for_datetime($dt);

my $next_action = <STDIN>;
chomp($next_action);

if ( $next_action eq "y" ) {
    update_data( $table_index, $tc_order_id, $expir_time );
    show_data_modified( $table_index, $tc_order_id );
}

if ( $next_action =~ /^\d{4}\W\d{1,2}\W\d{1,2}( \d{1,2}\W\d{1,2}\W\d{1,2})?/ ) {
    $expir_time = "UNIX_TIMESTAMP('$next_action')";
    update_data( $table_index, $tc_order_id, $expir_time );
    show_data_modified( $table_index, $tc_order_id );
}

$tg_db->disconnect;
$tc_db->disconnect;

sub update_data {
    my ( $table_id, $tc_order_id, $expir_time ) = @_;
    if ( $table_id < 0 || $table_id > 9 || $tc_order_id < 1 ) {
        say "error user_id.";
    }
    else {
        my $sql_update = qq{
UPDATE 
  `biz_balance_user_$table_id` b 
SET
  b.`end_at` = $expir_time
WHERE b.`order_id` = $tc_order_id;
};
        $tc_db->do($sql_update);
    }
    say "\n已经修改,请查看:\n";
}

sub show_data_modified {
    my ( $table_id, $tc_order_id ) = @_;
    if ( $table_id < 0 || $table_id > 9 || $tc_order_id < 1 ) {
        say "error user_id.";
    }
    else {
        my $sql_balance = qq{
SELECT 
  FROM_UNIXTIME(b.`begin_at`) as time_begin ,
  FROM_UNIXTIME(b.`end_at`) as time_end ,
  b.`product_code`
FROM
  `biz_balance_user_$table_id` b 
WHERE b.`order_id` = $tc_order_id ;
};
        my $rows_ref = $tc_db->selectall_arrayref($sql_balance);
        print "\n";
        say '|' . '-' x 60 . '|';
        printf( "|%-20s%-20s%-20s|\n", "产品", "开始时间", "结束时间" );
        foreach my $row_ref (@$rows_ref) {
            printf( "|%-20s%-20s%-20s|\n",
                $$row_ref[2], $$row_ref[0], $$row_ref[1] );
        }
        say '|' . '-' x 60 . "|\n";
    }
}

say "\nbye-bye. :)\n";
exit;
