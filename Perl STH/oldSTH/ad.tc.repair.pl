use 5.16.2;
use warnings;
use diagnostics;

use DBI();
use Encode;
use encoding "gbk";
use Data::Dumper;

my $file = __FILE__;
die "usage: $file test/real" if $#ARGV < 0;

my $is_ip_real = shift @ARGV;
my $test_ip = q(10.3.255.21);
my $real_ip = q(192.168.116.20);

my $use_ip = $is_ip_real =~ /^real$/i ? $real_ip : $test_ip;

# online connect
my ( $host, $database, $user, $pw, $port ) = ($use_ip, qq(gcrm), qq(qianjiajun), qq(fd497162d), qq(3320) );

my $dsn = qq(DBI:mysql:database=$database;host=$host;port=$port);
my $dbh = DBI->connect( $dsn, $user, $pw, { mysql_enable_utf8 => 1 } )
  or die qq(unable to connect $host \n);

my $query_cmd = <<query_cmd;
SELECT DISTINCT o.`id`,p.`CityId`,p.`CategoryId`
FROM gcrm.`order` o 
JOIN gcrm.`order_product` op
ON o.`id` = op.`order_id`
JOIN gcrm.`ad_position` p 
ON op.`foreign_id` = p.`PositionId`
WHERE o.`order_type` = 1;
query_cmd

my $sql_template = q(UPDATE tc_order o JOIN tc_order_package p ON o.`id` = p.`order_id` JOIN tc_order_item i ON o.`id` = i.`order_id` SET p.`category_type`=%1$s,i.`category_type` = %1$s,p.`city_id`= %2$s ,i.`city_id` = %2$s WHERE o.`source_order_code` = "%3$s" AND o.`source_type` IN(1,4););

$dbh->do(qq(set names 'utf8'));

my $result = generate_sql_array($dbh,$query_cmd);
generate_update_sql("ad.tc.repair.sql",$result);
say "done";

sub generate_sql_array{
    my ( $dbh, $query_cmd) = @_;

    unless ( $dbh and $query_cmd) {
        die qq(generate_sql ===> argument is invalid);
    }

    my $sth           = $dbh->prepare($query_cmd) or die $dbh->errstr;
    my $result_counts = $sth->execute()           or die $dbh->errstr;
    say qq(\n$query_cmd \n===> find $result_counts rows \n);
    say qq(write into file);
    my $result_ref = [];
    while ( my $array_ref = $sth->fetchrow_arrayref() ) {
      my($order_code,$city_id,$cat) = @$array_ref;
      push @$result_ref, sprintf($sql_template,$cat,$city_id,$order_code);
    }
    $sth->finish();
    return $result_ref;
}

sub generate_update_sql {
  my ($sql_file_name,$sql_array_ref) = @_;
  open( WFH, ">:encoding(UTF-8)", $sql_file_name )
    or die "can not creat sql file ==> $!\n";
  my $while_count = 1;
  foreach(@$sql_array_ref){
    say WFH;
    say $while_count++;
  }
  close WFH;
}
