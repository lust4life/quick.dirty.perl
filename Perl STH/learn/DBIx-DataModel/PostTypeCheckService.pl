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

#my $sth = $dbh->prepare("select * from gcrm.ad_shiwanhuoji_ext limit 1");
#$sth->execute();
#my $row = $sth->fetchrow_hashref();
#print Dumper($row);
#c-x r t insert into something in a rectangle

#say DateTime->now(time_zone=>'local');
#say time;
#say $time{'yyyy/mm/dd hh:mm:ss'};

#gcrm->dbh($dbh);
#my @select_columns = qw/puid userid postdb posttable postid/;
#my $all_huoji = gcrm->table('huoji')->select(
#                                             -columns => [-DISTINCT => @select_columns],
#                                             -where => {
#                                                        adid =>{"<" => 3},
#                                                       }
#                                            );
#
my $sql_huoji = q{
SELECT DISTINCT
  puid,
  userid,
  postdb AS db,
  posttable AS tb,
  postid AS id,
  p.`Status` = 2 
  AND p.`EndTime` > UNIX_TIMESTAMP() AS isonline
FROM
  gcrm.`ad_shiwanhuoji_ext` s 
  JOIN gcrm.`ad_position` p 
    ON s.`AdId` = p.`AdId`
  Where s.`puid` > 0
    ;
};

my $sth = $tg_db->prepare($sql_huoji);
$sth->execute;

#my $huoji_group = $sth->fetchall_hashref([qw/db tb/]);
#p $huoji_group;

my %huoji_group_by_db;
my %huoji_puid;
while ( my $row = $sth->fetchrow_hashref() ) {   ### huoji |=== | % done

    #  p $row;
    my $db_str = $row->{db} . ',' . $row->{tb};
    my $huoji_in_hash =
      first { $_->{puid} == $row->{puid} } @{ $huoji_group_by_db{$db_str} };
    if ($huoji_in_hash) {
        $huoji_in_hash->{isonline} =
          $huoji_in_hash->{isonline} || $row->{isonline};
        $huoji_puid{ $row->{puid} } = $huoji_in_hash;
    }
    else {
        push( @{ $huoji_group_by_db{$db_str} }, $row );
        $huoji_puid{ $row->{puid} } = $row;
    }
}

my @posts;
while ( my ( $key, $rows ) = each %huoji_group_by_db ) { ### post |=== | % done
    my ( $db, $tb ) = split ",", $key;
    my $post_ids = join( ",", map { $_->{id} } @$rows );
    my $all_post_in_one_table = qq{
 select id,puid,post_type,ad_types,
 ad_status,listing_status, '$db' as db,
 '$tb' as tb,user_id
 from $db.$tb
 where id in ($post_ids);
};

    my $posts_tb = $ms_db->selectall_hashref( $all_post_in_one_table, 'puid' );
    push @posts, values %$posts_tb;
}

$tg_db->disconnect;
$ms_db->disconnect;

my %broken_data;
my @update_sql;
foreach my $post (@posts) {  ### broken |=== | % done
    my ( $pt, $as, $at, $ls, $puid ) = (
        $post->{post_type},      $post->{ad_status}, $post->{ad_types},
        $post->{listing_status}, $post->{puid}


    );
    my $is_online = $huoji_puid{$puid}->{isonline} // 0;

    # 十万火急 post_type, ad_types && ad_status 需要对应
    my $is_normal;
    if ($is_online) {
      $is_normal =
             $pt == 2
          && ($ls == 51)
          && ( ( $at & 32 ) == 32 )
          && ( ( $as & 32 ) == 32 );
      $is_normal = $is_normal || $ls == 1;
    }
    else {
        $is_normal =
             $pt != 2
          && $ls != 51
          && ( ( $at & 32 ) != 32 )
          && ( ( $as & 32 ) != 32 );
        unless($is_normal){
          my $pt_str = $pt == 2 ? ", post_type = 0 ": "";
          my $ls_str = $ls == 51 ? ", listing_status = 5 " :"";
          my $as_new = $as < 0 ? 0 : $as & (~32);
          my $at_new = $at < 0 ? 0 : $at & (~32);
          my $repari_sql = qq/update $post->{db}.$post->{tb} set ad_status = $as_new , ad_types = $at_new  $pt_str $ls_str where id = $post->{id} ;/;
          push @update_sql, $repari_sql;
        }
    }
    $post->{is_online} = $is_online;
    push( @{$broken_data{$is_online}}, $post ) unless $is_normal;
}


#p %broken_data;

my $broken_data = p(%broken_data,colored=>0);
open WFH,'>:encoding(gbk)', "broken.data" or croak "open failed.";
say WFH $broken_data;
close WFH;

open WFH,'>:encoding(gbk)', "update.sql" or croak "open failed.";
foreach my $line(@update_sql){
  say WFH $line;
}
close WFH;


my @show_data = (@{$broken_data{0}}[1..3],@{$broken_data{1}}[1..3]);
#p @show_data;

say "\n\nend";
