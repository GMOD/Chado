package WikiBox;

use base 'Class::DBI::mysql';
__PACKAGE__->set_db('Main', 'dbi:mysql:wikibox_db', 'root' );
__PACKAGE__->set_up_table("box");
