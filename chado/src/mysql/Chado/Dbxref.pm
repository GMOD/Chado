package Chado::Dbxref;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Dbxref->set_up_table('dbxref');
Chado::Dbxref->hasa(Chado::Db => 'db_id');

sub id { return shift->dbxref_id }
sub name { return shift->accession }
sub db { return shift->db_id }

1;
