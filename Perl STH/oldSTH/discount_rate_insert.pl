use strict;
use 5.10.0;
use Encode;
use utf8;
binmode(STDOUT, ':encoding(gb2312)');


my $file_name = 'channel_discount_rate120323.txt'; 

open(FILE,$file_name) or die "can not open $file_name.=> $!";
#my $discount_rate_ids = ();
my $discount_rate_sql = ();
my $suit_count = 0;
while(<FILE>)
{
	$_ = decode("utf8",$_);
	#if(/(\d+)\t485\t\w+/)
	#if(/^(\d+)\t485\t.+1$/)
	if(/^\d+\t485\t(\w+)\t(\d+)\t(\w+)\t(\d+)\t(\w+)\t(\d+.\d+).+1$/)
	{
		$suit_count++;		
		$discount_rate_sql .= "insert into gcrm.`channel_discount_rate` (`agent_id`, `agent_name`, `city_id`, `city_name`, `product_type`, `product_type_name`, `discount_rate`, `creator_by`, `creator_by_name`, `created_time`, `modifier_by`, `modifier_by_name`, `modified_time`, `product_line_id`) values('485','$1','$2','$3','$4','$5','$6','3844','曹芳','1329356248','3844','曹芳','1329356248','1');\n";
		
	}
}
close FILE;

say $suit_count;
#say $discount_rate_sql;

my $file_to_write = 'discount_rate_insert.sql';
#&write_sql($file_to_write,$discount_rate_sql);


$file_name = 'channel_discount_rate_sub120312.txt';
open(FILE,$file_name) or die "can not open $file_name. => $!";
my $insert_sql = ();
$suit_count = 0 ;
while(<FILE>)
{
	$_ = Encode::decode("utf8",$_);
	if(/\d+\t(6119|6120|6121|6122|6123|6124)\t(\d+)\t(\w+)\t(0.\d+)/)
	{
		say $_;
		$suit_count++;
		my($discount_rate_id,$category_id,$category_name,$real_discount_rate)=($1,$2,$3,$4);
		$insert_sql .= "insert into `channel_discount_rate_sub` (`discount_rate_id`, `category_id`, `category_name`, `real_discount_rate`) values('$discount_rate_id','$category_id','$category_name','$real_discount_rate');\n";
	}
}
say $suit_count;
close FILE;
say $insert_sql;

$file_to_write = 'discount_rate_sub_insert.sql';
&write_sql($file_to_write,$insert_sql);
 

sub write_sql
{
my ($sql_file_name,$insert_sql) = @_;
unless(-e $sql_file_name)
{
	open(WFH,">$sql_file_name") or die "can not create $sql_file_name! => $!";
	print WFH Encode::encode("gb2312",$insert_sql);
	close WFH;
}
else	
{
	die "$sql_file_name is exist!! please check it .\n";
}
}

