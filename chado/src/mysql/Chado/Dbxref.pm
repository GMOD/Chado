package Chado::Dbxref;
use base 'Chado::DBI';

Chado::Dbxref->set_up_table('dbxref');
sub id { return shift->dbxref_id }

1;
