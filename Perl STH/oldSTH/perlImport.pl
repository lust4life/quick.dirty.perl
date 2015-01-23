

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
#use Spreadsheet::XLSX; #对于office 2007 Excel
#use LWP::Simple;
use Spreadsheet::ParseExcel;
use Spreadsheet::ParseExcel::FmtUnicode;   

sub CacheInfo 
{
	my $host = "xxxx";
	my $database = "xxxx";
	my $user = "xxxx";
	my $pw = "xxxx";
	my $port = "xxxx";
	my $dsn = "DBI:mysql:database=$database;host=$host;port=$port"; #Data Source Name
	my $dbh = DBI->connect($dsn,$user,$pw,{mysql_enable_utf8 => 1})
				or die "unable to connect !!" ; # database handle
	# $dbh->do("SET character_set_client = 'gb2312'");
	# $dbh->do("SET character_set_connection = 'gb2312'");
	# $dbh->do("SET character_set_results= 'gb2312'");
	#$dbh->do("SET names 'gb2312'");  # 设置字符集，保证和mysql交流字符编码正确
	
	my %city_hash = &cache_city($dbh);
	my (%category ,%category_major,%category_minor,%tag);
	eval
	{
		(%category ,%category_major,%category_minor,%tag)= &cache_category($dbh);
	};
	if ($@)
	{
		die "cache_category failed => $@";
	}	
	$dbh->disconnect();
	return (%city_hash,%category,%category_major,%category_minor,%tag);
	
       
}


# category , major_category , minor_category , tag
sub cache_category
{
	my ($dbh) = @_;
	my $array_ref;
	################# Cache the category info into category_hash ####################
	my $category_query = ' SELECT DISTINCT c.`category_id`,c.`category_name` FROM management.`category` c ;';
	my $sth = $dbh->prepare($category_query);  #statement handle
	$sth->execute();

	my %category_hash ;
	while($array_ref = $sth->fetchrow_arrayref())
	{
		my ($category_id,$category_name) = ($array_ref->[0],$array_ref->[1]);
		$category_hash{$category_name} = $category_id;
	}
	$sth->finish();
	
	################# Cache the major_category info into major_category_hash ####################
	my $major_category_query = ' SELECT DISTINCT c.`category_id`,c.`category_name` FROM management.`category_major` c ;';
	$sth = $dbh->prepare($major_category_query); # statement handle
	$sth->execute();
	
	my %major_category_hash;
	while($array_ref = $sth->fetchrow_arrayref())
	{
		my ($category_id,$category_name) = ($array_ref->[0],$array_ref->[1]);
		$major_category_hash{$category_name} = $category_id;
	}
	$sth->finish();
	
	
	################# Cache the minor_category info into minor_category_hash ####################
	my $minor_category_query = "SELECT DISTINCT c.`category_id`,c.`category_name` FROM management.`category_minor` c ;";
	$sth = $dbh->prepare($minor_category_query);
	$sth->execute();
	
	my %minor_category_hash;
	while($array_ref = $sth->fetchrow_arrayref())
	{
		my ($category_id,$category_name) = ($array_ref->[0],$array_ref->[1]);
		$minor_category_hash{$category_name} = $category_id;
	}
	$sth->finish();
	
	
	################# Cache the tag info into tag_hash ####################
	my $tag_query = ' SELECT DISTINCT  t.`tag_id`,t.`tag_name` FROM management.`tag` t;';
	$sth = $dbh->prepare($tag_query);
	$sth->execute();
	
	my %tag_hash;
	while($array_ref = $sth->fetchrow_arrayref())
	{
		my ($tag_id,$tag_name) = ($array_ref->[0],$array_ref->[1]);
		$tag_hash{$tag_name} = $tag_id;
	}
	$sth->finish();
	
	return (%category_hash,%major_category_hash,%minor_category_hash,%tag_hash);
}



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

	# my %cache_info_hash 		= &CacheInfo();
	# my %cityHash   				= $cache_info_hash{'city'};
	# my %category_hash   		= $cache_info_hash{'category'};
	# my %category_major_hash  	= $cache_info_hash{'category_major'};
	# my %category_minor_hash  	= $cache_info_hash{'category_minor'};
	# my %tag_hash 		   	 	= $cache_info_hash{'tag'};

	my (%cityHash, %category_hash,%category_major_hash,%category_minor_hash,%tag_hash) = &CacheInfo();
	say %category_major_hash;

	my $parser     = Spreadsheet::ParseExcel->new();  
	my $fmt 	   = Spreadsheet::ParseExcel::FmtUnicode->new(Unicode_Map => 'gb2312'); 
	my $workbook   = $parser->Parse($file_name, $fmt);  
	my $sqlInsert  = qq();
	my @infoFields = ('1001','系统管理员','1307677350','2079','李亚奇','1310754042');	
	
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
					my $minor_category_name_original = $fields[4];
					for (0 .. $#fields) 
					{
						if (!defined($fields[$_]))
						{
							$fields[$_] = "0";
						}
						given($_)
						{
							when(2) # category
							{
								my $category_id = $category_hash{$fields[$_]};
								if(!defined($category_id))
								{
									my $category_name = Encode::encode("gb2312",$fields[$_]);
									die "can not find category : $category_name !\n"
								}
								else
								{
									$fields[$_] = $category_id;
								}
							}
							when(3) # major category
							{
								my $category_major_id = $category_major_hash{$fields[$_]};
								if(!defined($category_major_id))
								{
									my $category_major_name = Encode::encode("gb2312",$fields[$_]);
									die "can not find Major_Category : $category_major_name !\n"
								}
								else
								{
									$fields[$_] = $category_major_id;
								}
							}
							when(4) # minor category or tag
							{
								my $category_minor_id = $category_minor_hash{$fields[$_]};
								if(!defined($category_minor_id))
								{
									my $tag_id = $tag_hash{$fields[$_]};
									if(!defined($tag_id))
									{
										my $category_name = Encode::encode("gb2312",$fields[$_]);
										die "can not find minor_category_name or tag_name : $category_name !\n"
									}
									else
									{
										$fields[$_] = $tag_id;
									}
								}
								else
								{
									$fields[$_] = $category_minor_id;
								}
							}
							when(5) # city
							{
								my $cityId = $cityHash{$fields[$_]};
								if(!defined($cityId))
								{
									my $cityName = Encode::encode("gb2312",$fields[$_]);
									die "can not find city : $cityName !\n"
								}
								else
								{
									$fields[$_] = $cityId;
								}
							}
							#default{}
						}
						# if($_ == 6)#city field is 6 => cityDic
						# {
							# my $cityId = $cityHash{$fields[$_]};
							# if(!defined($cityId))
							# {
								# my $cityName = Encode::encode("gb2312",$fields[$_]);
								# die "can not find city $cityName !\n"
							# }
							# else
							# {
								# $fields[$_] = $cityHash{$fields[$_]};
							# }
						# }
					}
					
					my $category_minor_id = $category_minor_hash{$minor_category_name_original};
					if(defined($category_minor_id))
					{
						splice(@fields,5,0,'1'); # category_type 代表是二级还是标签	
					}
					else
					{
						splice(@fields,5,0,'0'); # category_type 代表是二级还是标签	
					}
					
					splice(@fields,7,0,'0'); # district 行政区（暂时没有用）	
					splice(@fields,13,0,@infoFields);				
					my $params = join("','",@fields);
					$params = "'" . $params;
					$params .= "'";
					
					$sqlInsert .= "insert into `gcrm`.`channel_price_config`(`Price`,`SubPrice`, `CategoryId`,`MajorCategoryId`, `MinorCategoryId`, `CategoryType`,`CityId`,`DistrictId`, `Status`, `Position`,`Type`, `Term`,`Count`,`CreatorId`, `CreatorName`, `CreatedTime`, `ModifierId`,`ModifierName`, `ModifiedTime`,`RegionCount`, `LabelCount`,`PositionId`)values($params);\n";
			}  
	}  
	return $sqlInsert;
}

################### General the sql file ############

my $xls_file_name = 'PriceConfigTemplate.xls';
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




















