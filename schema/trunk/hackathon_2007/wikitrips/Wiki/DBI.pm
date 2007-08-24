package Wiki::DBI;

use base 'Class::DBI::mysql';
__PACKAGE__->set_db('Main', 'dbi:mysql:wikibox_db', 'root' );


package Wiki::Box;
use base 'Wiki::DBI';
__PACKAGE__->set_up_table("box");
