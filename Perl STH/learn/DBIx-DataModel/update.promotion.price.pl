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

my $commodities_sql = q{SELECT
  c.`id`,
  c.`uni_set_id`,
  sp.`sales_promotion_code` as promotion_code,
  c.`id` AS unique_key,
  c.`code` AS commodity_code,
  c.`public_price` AS price,
  c.`price_factor_json` AS factor_json
FROM
  gcrm.`uni_commodity` c
  JOIN gcrm.`uni_commodity_set` s
    ON c.`uni_set_id` = s.`id`
  JOIN gcrm.`uni_commodity_status` cs
    ON c.`id` = cs.`commodity_id`
  JOIN gcrm.`sales_promotion` sp
    ON s.`item_foreign_key` = sp.`id`
WHERE s.`item_type` = 1
  AND cs.`status` = 2
  AND s.`c_time` < UNIX_TIMESTAMP('2014-06-06')
  AND s.`c_name` NOT IN (
    '测试代理商001',
    '测试代理006',
    '花瑞邦',
    '乔丹',
    '祝鹤源',
    '张超',
    '苟洁'
  )
ORDER BY c.id DESC ;};

my $promotion_info_sql = q{SELECT
  p.`code` as promotion_code,
  cn.`commodity_code`,
  c.`is_optional`,
  c.`type`
FROM
  `promotion_activity` p
  JOIN `promotion_activity_commodity` c
    ON p.`id` = c.`activity_id`
  JOIN `commodity_new` cn
    ON c.`commodity_id` = cn.`id` ;
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

$tc_db->do('use `commodity_base`;');
my $promotion_info_hash = $tc_db->selectall_hashref($promotion_info_sql,[qw(promotion_code commodity_code)]);

my $sth =$tg_db->prepare_cached($commodities_sql);
$sth->execute();
my %commodity_set_hash =();
while(my $commodity = $sth->fetchrow_hashref){
    $commodity->{factors} = $json->decode($commodity->{factor_json});
    my $promotion_code = $commodity->{promotion_code};
    my $promotion = $promotion_info_hash->{$promotion_code}->{$commodity->{commodity_code}};
    if($promotion){
        $commodity->{type} = $promotion->{type};
        $commodity->{is_optional} = $promotion->{is_optional};
    }
    push @{$commodity_set_hash{$commodity->{uni_set_id} . ' ' . $promotion_code}} , $commodity;
}

use Mojo::UserAgent;
use Encode;
my $ua = Mojo::UserAgent->new;

my $update_price_sql = q();
while(my($set_key,$commodity_list) = each %commodity_set_hash){
    my($set_id,$promotion_code) = split(/\s/,$set_key);
    my %data_list = (
                     'activity_code' => $promotion_code,
                     'commodity_list' => $commodity_list
                    );
    my $data_list_str = $json->encode(\%data_list);
    my $api_url = qq(http://crmapi.dns.ganji.com:7101/CommodityBaseApi/PromotionActivity/VerifyPromotionActivity.cbi);
    my $promotion_result = $ua->post($api_url=>form=>{
                                                  source => '6566567b50be0ac7b85076ae76acbaa1',
                                                  data_list => $data_list_str
                                                 })->res->json();

    # generate update price sql
    if($promotion_result->{succeed} == 1){
        foreach(@{$promotion_result->{data}}){
            my ($update_price,$update_id) = @$_{(qw(public_price uniquely_key))};
            $update_price_sql .= qq(UPDATE gcrm.`uni_commodity` c SET c.`promotion_public_price` = $update_price WHERE c.`id` = $update_id ;\n);
        }
    }else{
     #   carp 'requrest is faild :' . $data_list_str;
    }
}

say $update_price_sql;
