package Chado::DBI;
use base 'Class::DBI::mysql';
Chado::DBI->set_db(
				   'Main',
				   'd:s:n;host=hostname',
				   'username',
				   'password'
				  );

1;
