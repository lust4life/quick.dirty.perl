package UOKO::Schema;

use base qw/DBIx::Class::Schema/;

__PACKAGE__->load_namespaces();

package UOKO::Schema::Result::GrabInfo;
use base qw/DBIx::Class::Core/;

__PACKAGE__->table('grab-info-table');
