##--!/usr/bin/perl -w

##################   产品类别 ， 行政区， 标签，二级小类，小类，大类 =》 需要转化为数字



#insert into `gcrm`.`channel_price_config` 
#(`Price`, `SubPrice`, `CategoryId`, `MajorCategoryId`, `MinorCategoryId`, `CategoryType`, 
#`CityId`, `DistrictId`, `Status`, `Position`, 
#`Type`, `Term`, `Count`, 
#`CreatorId`, `CreatorName`, `CreatedTime`, `ModifierId`, `ModifierName`, `ModifiedTime`, 
#`RegionCount`, `LabelCount`, `PositionId`) 
#values('2000.00','0.00','0','0','0','0',
#'225','0','1','0',
#'21','12','0',
#'1001','系统管理员','1307677350','2079','李亚奇','1310754042',
#'0','0','0');


use strict;
use 5.10.0;
use DBI();
use Encode;
use utf8;
binmode(STDOUT, ':encoding(gb2312)');
# use Spreadsheet::XLSX; #对于office 2007 Excel
# use LWP::Simple;
use Spreadsheet::ParseExcel;
use Spreadsheet::ParseExcel::FmtUnicode;   


################## Read the excel 2007 Info #######################
# my $excel = Spreadsheet::XLSX->new('PriceConfigTemplate.xls');
# foreach my $sheet(@{$excel->{Worksheet}}){
	# printf("Sheet: %s\n",$sheet->{Name});
	# $sheet->{MaxRow} ||= $sheet->{MinRow};
	# foreach my $row($sheet->{MinRow} .. $sheet->{MaxRow}){
		# $sheet->{MaxCol} ||= $sheet->{MinCol};
		# foreach my $col($sheet->{MinCol} .. $sheet->{MaxCol}){
			# my $cell = $sheet->{Cells}[$row][$col];
			# if($cell){
				# my $tempvalue = $cell->{Val};  
				#$value = encode("gb2312", decode("utf8", $tempvalue));  
				# printf("(%s , %s) => %s\n",$row,$col,$cell->{Val});
			# }
		# }
	# }
# }

sub trans_xls_to_sql
{
	my $file_name  = $_[0];
	my $parser     = Spreadsheet::ParseExcel->new();  
	my $fmt 	   = Spreadsheet::ParseExcel::FmtUnicode->new(Unicode_Map => 'gb2312'); 
	my $workbook   = $parser->Parse($file_name, $fmt);  
	my $sqlInsert  = qw();
	
	for my $worksheet ( $workbook->worksheets() ) 
	{  
			my ( $row_min, $row_max ) = $worksheet->row_range();  
			my ( $col_min, $col_max ) = $worksheet->col_range();  
			for my $row ( 1 .. $row_max ) 
			{  		
					my @fields=();	
					for my $col ( $col_min .. $col_max ) 
					{  
							my $cell = $worksheet->get_cell( $row, $col ); 
							if(!defined($cell))
							{
								push @fields,undef;
							}		
							else
							{
								my $value = $cell->value;
								$value =~ s/^\s+|\s+$//g ;
								if(length($value) == 0)
								{
									push @fields,undef;
								}
								else
								{
									$value =  Encode::decode("gb2312",$value);
									push @fields,$value;
								}
							}						
					}  		
					my $params = join("','",@fields);
					$params = "'" . $params . "'";
					my ($price,$sub_price,$term,$city_id) = split( /,/ , $params );
					#printf "%s\t%s\t%s\t%s\t\n",$price,$sub_price,$term,$city_id;
					
					$sqlInsert .= "insert into `gcrm`.`channel_price_config`  (`Price`, `SubPrice`, `CategoryId`, `MajorCategoryId`, `MinorCategoryId`, `CategoryType`, `CityId`, `DistrictId`, `Status`, `Position`, `Type`, `Term`, `Count`, `CreatorId`, `CreatorName`, `CreatedTime`, `ModifierId`,`ModifierName`,`ModifiedTime`,`RegionCount`,`LabelCount`,`PositionId`,`IsWaveRed`)values($price,$sub_price,'0','0','0','0',$city_id,'0','1','0','25',$term,'0','3257','曾荣彬','1332412387','4965','佟笛','1332417164','0','0','0','-1');\n";
					
			}  
	}  
	return $sqlInsert;
}

################### General the sql file ############

my $xls_file_name = 'priceconfig.xls';
my $sql_insert_str = trans_xls_to_sql($xls_file_name);


my $sql_file_name = "importData.sql";
unless (-e $sql_file_name)
{
	open(WFH,">:encoding(UTF-8)","$sql_file_name") or die "Can not create $sql_file_name! => $!";
	print WFH $sql_insert_str;
	close WFH;
}
else
{
	die "$sql_file_name is exist!! please check it.\n";
}

say 'All done!! You can check the sql file now ...';




















