package Wiki::DBI;

use base 'Class::DBI::mysql';
__PACKAGE__->set_db('Main', 'dbi:mysql:wikibox_db', 'root' );


package Wiki::Box;
use base 'Wiki::DBI';
__PACKAGE__->set_up_table("box");
Wiki::Box->has_many( rows =>Wiki::Row=>'box_id');

package Wiki::Row;
use base 'Wiki::DBI';
__PACKAGE__->set_up_table("row");
Wiki::Box->has_many( row_metadata =>Wiki::RowMetadata=>'row_id');

package Wiki::RowMetadata;
use base 'Wiki::DBI';
__PACKAGE__->set_up_table("row_metadata");
