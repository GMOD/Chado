package Chado::DBI;
use base 'Class::DBI::mysql';
Chado::DBI->set_db(
				   'Main',
				   'dbi:mysql:chado_wax;host=sumo',
				   'nobody',
				   ''
				  );

1;
