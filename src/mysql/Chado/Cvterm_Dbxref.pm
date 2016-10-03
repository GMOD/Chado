package Chado::Cvterm_Dbxref;
use base 'Chado::DBI';
use mixin 'Class::DBI::Join';
use Class::DBI::Pager;

Chado::Cvterm_Dbxref->set_up_table('cvterm_dbxref');
Chado::Cvterm_Dbxref->hasa(Chado::Cvterm => 'cvterm_id');
Chado::Cvterm_Dbxref->hasa(Chado::Dbxref  => 'dbxref_id');

sub id { return shift->cvterm_dbxref_id }

sub cvterm { return shift->cvterm_id }
sub dbxref  { return shift->dbxref_id  }

1;
