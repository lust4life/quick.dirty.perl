use strict;
use 5.10.0;
use DBI();
use Encode;

use encoding "gbk";

#use utf8;

#binmode(STDOUT, ':encoding(gb2312)');

my @cols = (
             'A:A',  'B:B',  'C:C',  'D:D',  'E:E',  'F:F',  'G:G',  'H:H',
             'I:I',  'J:J',  'K:K',  'L:L',  'M:M',  'N:N',  'O:O',  'P:P',
             'Q:Q',  'R:R',  'S:S',  'T:T',  'U:U',  'V:V',  'W:W',  'X:X',
             'Y:Y',  'Z:Z',  'AA:A', 'BB:B', 'CC:C', 'DD:D', 'EE:E', 'FF:F',
             'GG:G', 'HH:H', 'II:I', 'JJ:J', 'KK:K', 'LL:L', 'MM:M', 'NN:N',
             'OO:O', 'PP:P', 'QQ:Q', 'RR:R', 'SS:S', 'TT:T', 'UU:U', 'VV:V',
             'WW:W', 'XX:X', 'YY:Y', 'ZZ:Z'
);

use Spreadsheet::ParseExcel;
use Spreadsheet::ParseExcel::FmtUnicode;
use Spreadsheet::WriteExcel;

my $lets_begin = qq(准备开始:==========>);
say qq();
say $lets_begin;
say qq();

# test connect
# my ( $host, $database, $user, $pw, $port ) = ( qq(192.168.112.10), qq(gcrm), qq(qianjiajun), qq(fd497162d), qq(3320) );

# online connect
my ( $host, $database, $user, $pw, $port ) = ( qq(192.168.116.20), qq(gcrm), qq(qianjiajun), qq(fd497162d), qq(3320) );

my $dsn = qq(DBI:mysql:database=$database;host=$host;port=$port);
my $dbh = DBI->connect( $dsn, $user, $pw, { mysql_enable_utf8 => 1 } )
  or die qq(unable to connect $host \n);
my $query_cmd_agent = <<query_cmd;
SELECT  a.agentid AS 代理商ID,a.agentname AS 代理商,
    IF(ag.id IS NULL,'一级','二级') AS 类别,
    a.isservicecenter AS 是否营销服务中心,
    a.agentstatus AS 是否停用,
    a.cityid AS 城市,
    a.companyaddress AS 公司地址
FROM gcrm.`channel_agent` a
LEFT JOIN gcrm.`channel_agent_generation_sale_permissions` ag
ON a.`AgentId` = ag.`AgentId`
query_cmd

my $file_name = qq(agentExport.xls);
$dbh->do(qq(set names 'utf8'));

use Time::HiRes qw(gettimeofday);
my $start_microsec = &get_microsec_now();

#&export_to_excel( $dbh, $query_cmd_agent, $file_name );
#$dbh->disconnect();

my $end_microsec = &get_microsec_now();
my $time_used    = ( $end_microsec - $start_microsec ) / 1000000;
say qq(\n\n================>);
printf( "time used  : %.4f s\n", $time_used );
say qq();

$start_microsec = &get_microsec_now();

&generate_update_sql( $file_name, "import_sql.txt" );

$end_microsec = &get_microsec_now();
$time_used    = ( $end_microsec - $start_microsec ) / 1000000;
say qq(\n\n================>);
printf( "time generate sql file used  : %.4f s\n", $time_used );
say qq();

sub cache_info {
    my $host     = qq(192.168.64.4);
    my $database = qq(gcrm);
    my $user     = qq(dbdev);
    my $pw       = qq(ganjidev);
    my $port     = qq(3306);
    my $dsn =
      qq(DBI:mysql:database=$database;host=$host;port=$port);  #data source name
    my $dbh = DBI->connect( $dsn, $user, $pw, { mysql_enable_utf8 => 1 } )
      or die qq(unable to connect $host \n);                   #data base handle
    my $city_cache_ref = undef;
    eval { $city_cache_ref = &cache_city_ref($dbh); };
    if ($@) { die "cache_city faild => $@"; }
    $dbh->disconnect();
    return ( 'city_cache' => $city_cache_ref, );
}

# cityInfo
sub cache_city_ref {
    my $dbh = shift;
    my $city_query =
'SELECT c.`city_id`,c.`city_name`,c.`short_name` FROM management.`city` c ORDER BY c.`city_id`;';
    my $sth = $dbh->prepare($city_query);    #statement handle
    $sth->execute();

    ################# Cache the city info into CityHash ####################
    my %cityHash;
    while ( my $aryRef = $sth->fetchrow_arrayref() ) {
        my ( $cityId, $cityName, $shortName ) =
          ( $aryRef->[0], $aryRef->[1], $aryRef->[2] );
        $cityHash{$cityId} = $cityName;
    }
    $sth->finish();
    \%cityHash;
}

# export sql result to excel
sub export_to_excel {
    my ( $dbh, $query_cmd, $file_name ) = @_;
    my %cache_info = &cache_info();    # some cache info

    unless ( $dbh and $query_cmd and $file_name ) {
        die qq(export_to_excel ===> argument is invalid);
    }

    my $sth           = $dbh->prepare($query_cmd) or die $dbh->errstr;
    my $result_counts = $sth->execute()           or die $dbh->errstr;
    say qq($query_cmd \n===> find $result_counts rows);
    say qq();
    say qq(write into excel);
    my $workbook  = Spreadsheet::WriteExcel->new($file_name);
    my $worksheet = $workbook->add_worksheet();

    #将结果写入表格
    my @column_names = @{ $sth->{'NAME'} };       # 数据库查询的列名
    my $format       = $workbook->add_format();
    $format->set_bold();
    $format->set_color('red');
    $format->set_align('center');
    $format->set_size(16);
    for ( my $i = 0 ; $i <= $#column_names ; $i++ ) {

        #列信息
        my $col_name = Encode::decode( "utf8", $column_names[$i] );
        $worksheet->set_column( $cols[$i], length($col_name) + 30 );
        $worksheet->write( 0, $i, $col_name, $format );
    }

    #冻结表首行
    $worksheet->freeze_panes( 1, 0 );

    my $row_nums = 0;
    while ( my $ary_ref = $sth->fetchrow_arrayref() ) {
        $row_nums++;

        for ( my $i = 0 ; $i <= $#column_names ; $i++ ) {
            my $data = $ary_ref->[$i];

            # write into excel
            given ($i) {
                when (5) {    # 5 mean city column
                    my $city_id = $data;
                    $data = %{ $cache_info{"city_cache"} }->{$city_id};
                    if ( !defined($data) ) {
                        die
qq(\nexport failed :\n\tcityId ==> $city_id can't find city_name\n\n);
                    }
                }

=comment
	      when(/[]/){
		$data = $data == 0 ? qq(否) : qq(是);
	      }
=cut

            }
            if ( $i =~ /[16]/ ) {
                $worksheet->write_string( $row_nums, $i, $data );
            }
            else {
                $worksheet->write( $row_nums, $i, $data );
            }
        }
    }
    $sth->finish();
    say qq(finish write);
}

sub get_microsec_now {
    my ( $sec, $microsec ) = gettimeofday;
    return $sec + $microsec;
}

sub get_agent_ids_with_flag {

    # 读入 excel 将 is_service_center 为 1 的更新在 channel_agent 表中。
    # 生成 update sql 文本。

    my $file_name = $_[0];
    my $parser    = Spreadsheet::ParseExcel->new();
    my $fmt =
      Spreadsheet::ParseExcel::FmtUnicode->new( Unicode_Map => 'gb2312' );
    my $workbook = $parser->Parse( $file_name, $fmt );

    for my $worksheet ( $workbook->worksheets() ) {
        my ( $row_min,       $row_max )       = $worksheet->row_range();
        my ( $col_min,       $col_max )       = $worksheet->col_range();
        my ( @agent_ids_iss, @agent_ids_nos ) = ( (), () );
        for my $row ( 1 .. $row_max ) {
            my @need_cells_per_row = ();
            push @need_cells_per_row,
              (
                $worksheet->get_cell( $row, 0 ),
                $worksheet->get_cell( $row, 2 ),
                $worksheet->get_cell( $row, 3 )
              );

            my @need_values_per_row = ();
            for ( my $i = 0 ; $i <= $#need_cells_per_row ; $i++ ) {
                my $cell = $need_cells_per_row[$i];
                if ( !defined($cell) ) {
                    die "there is no cell\n";
                }
                else {
                    my $cel_value = $cell->value;
                    push @need_values_per_row,
                      Encode::decode( 'gb2312', $cel_value );
                }
            }

            # a row values
            if ( $need_values_per_row[1] == "一级" ) {
                my ( $agent_id, $is_service ) =
                  ( $need_values_per_row[0], $need_values_per_row[2] );
                if ( $is_service == 1 ) {
                    push @agent_ids_iss, $agent_id;
                }
                elsif ( $is_service == 0 ) {
                    push @agent_ids_nos, $agent_id;
                }
            }

        }

        # get all the is or not agent_ids
        return (
                 'agent_id_iss' => \@agent_ids_iss,
                 'agent_id_nos' => \@agent_ids_nos
        );
    }
}

sub generate_update_sql {
    my ( $excel_file_name, $sql_file_name ) = @_;
    my %agent_ids_hash = &get_agent_ids_with_flag($excel_file_name);
    my $id_iss_string  = join( ",", @{ $agent_ids_hash{'agent_id_iss'} } );
    my $id_nos_string  = join( ",", @{ $agent_ids_hash{'agent_id_nos'} } );
    my $sql_update =
qq(UPDATE gcrm.`channel_agent` a SET a.`IsServiceCenter` = 1 WHERE a.`AgentId` IN ($id_iss_string); \n UPDATE gcrm.`channel_agent` a SET a.`IsServiceCenter` = 0 WHERE a.`AgentId` IN ($id_nos_string););

    unless ( -e $sql_file_name ) {
        open( WFH, ">:encoding(UTF-8)", $sql_file_name )
          or die "can not creat sql file ==> $!\n";
        print WFH $sql_update;
        close WFH;
    }
    else {
        die "$sql_file_name is exist. please check it.\n";
    }
}
