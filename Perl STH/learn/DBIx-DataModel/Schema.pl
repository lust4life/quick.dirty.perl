use 5.16.3;
use strict;
use warnings;
use diagnostics;
use DBIx::DataModel;

DBIx::DataModel->Schema('gcrm');
gcrm->Table(qw/huoji ad_shiwanhuoji_ext AdId/);
