use 5.18.2;
use strict;
use warnings;
use diagnostics;
use DBI;
use GJDataSource;

my $ds = GJ::DataSource->new(1);
my $tc_db = DBI->connect( $ds->tg,
                          GJ::DataSource::User,
                          GJ::DataSource::Pwd,
                          {
                           mysql_enable_utf8 => 1,
                           'RaiseError' => 1
                          }
                        ) or die qq(unable to connect $GJ::DataSource::tc\n);

while(<DATA>){
    my $need_excute_sql = $_;
    if($need_excute_sql){
        $tc_db->do($need_excute_sql);
    }
}

say "done!";

__DATA__
update `gcrm`.`uni_temporary_mis_info` set `foreign_userId` = '336531255' where `id` = '1';
update `gcrm`.`uni_temporary_mis_info` set `foreign_userId` = '249399986' where `id` = '1';
update `gcrm`.`uni_temporary_mis_info` set `foreign_userId` = '338703836' where `id` = '1';
update `gcrm`.`uni_temporary_mis_info` set `foreign_userId` = '275930025' where `id` = '1';
update `gcrm`.`uni_temporary_mis_info` set `foreign_userId` = '217413240' where `id` = '2';
