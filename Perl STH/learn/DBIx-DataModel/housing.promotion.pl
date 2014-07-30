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
use URI::Escape;

my $json = JSON->new->allow_nonref;

# 获取所有的房产用户信息, 过滤出在精品在生效中的,并且获取用户 email
my $all_customer_sql = q{SELECT
c.`CompanyName` AS 'company_name',
c.`FullName` AS 'customer_name',
ca.`UserId` AS 'user_id',
ca.`SaleName` AS 'sale_name',
ca.`ServiceName` AS 'service_name'
 FROM gcrm.`customer` c
JOIN gcrm.`customer_account` ca
ON c.`CustomerId` = ca.`CustomerId`
WHERE
c.`CompanyId` IN (
28904,90839,66236,194033,1941,168236,13902,175932,820,1131,3100,214271,72875,16500,3339,2948,18279,148561,1900,954,2377,1191,176246,19234,119083,2910,22105,15718,24119,10760,858,786,23355,3726,23073,114889,181612,1531,72656,93239,2489,908,220157,1520,2487,11158,21084,21938
)
AND c.`Status` = 0 AND ca.`Status` = 1
};

my $user_in_use_sql_tpl = q{SELECT
 distinct b.`user_id`
FROM
  `biz_balance_user_%s` b
WHERE b.`product_code` = 'pd_post_num'
  AND b.`category_type` = 7
  AND b.`status` = 1
  AND b.`begin_at` <= 1406736000
  AND b.`end_at` >= 1406736000
  AND b.`user_id` IN (%s) ;
};

my $ds = GJ::DataSource->new(1);

my $tc_db = DBI->connect( $ds->tc,
                          GJ::DataSource::User,
                          GJ::DataSource::Pwd,
                          {
                           mysql_enable_utf8 => 1,
                           'RaiseError' => 1
                          }
                        ) or die qq(unable to connect $GJ::DataSource::tc\n);

my $tg_db = DBI->connect( $ds->tg,
                          GJ::DataSource::User,
                          GJ::DataSource::Pwd,
                          {
                           mysql_enable_utf8 => 1,
                           'RaiseError' => 1
                          }
                        ) or die qq(unable to connect $GJ::DataSource::tc\n);

my $customer_info_hash_ref = $tg_db->selectall_hashref($all_customer_sql,'user_id');

my %user_id_group = ();
map group_user_id($_),  keys %$customer_info_hash_ref;
sub group_user_id{
    push @{$user_id_group{$_%10}},$_;
}

my @all_user_id_in_use = ();
while(my($table_index,$user_ids_ref) = each %user_id_group){
    if($user_ids_ref && (scalar(@$user_ids_ref) > 0)){
        my $user_in_use_sql = sprintf($user_in_use_sql_tpl,$table_index,join(',',@$user_ids_ref));
        my $all_user_id_in_use_ref = $tc_db->selectall_arrayref($user_in_use_sql);
        push(@all_user_id_in_use, map {@$_} @$all_user_id_in_use_ref);
    }
}

use Mojo::UserAgent;
use Encode;
my $ua = Mojo::UserAgent->new;
binmode(STDOUT, ':encoding(gbk)');


my $sso_url = "sso.corp.ganji.com/Account/LogOn";
my $tx = $ua->post(
    $sso_url,
    => { DNT => 1 } => json => {
        UserName => 'qianjiajun',
        Password => 'suyang5`',
        Domain   => '@ganji.com',
    }
);

my $all_customer_info_export = q();
foreach my $row(@{$customer_info_hash_ref}{@all_user_id_in_use}){
    my $user_id = $$row{user_id};
    my $get_user_id_url = "gcrm.corp.ganji.com/HousingTask/getganjiuser?userid=$user_id";
    my $user_info = decode('utf8',$ua->post($get_user_id_url)->res->body);
    if($user_info =~ /Email:(.*?)\s.*Name:(.*?)\s/){
        @$row{'user_email','user_name'} = ($1,$2);
        $all_customer_info_export .= sprintf("%s\t%s\t%s\t%s\t%s\t%s\t%s\n",@$row{qw(company_name customer_name sale_name service_name user_id user_email user_name)});
    }
    else{
        carp 'requrest is faild :' . $user_id;
    }
}

say $all_customer_info_export;
