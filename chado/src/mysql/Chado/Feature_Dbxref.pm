package Chado::Feature_Dbxref;
use base 'Chado::DBI';
use mixin 'Class::DBI::Join';

Chado::Feature_Dbxref->set_up_table('feature_dbxref');
Chado::Feature_Dbxref->hasa(Chado::Feature => 'feature_id');
Chado::Feature_Dbxref->hasa(Chado::Dbxref  => 'dbxref_id');

sub id { return shift->feature_dbxref }

sub feature { return shift->feature_id }
sub dbxref  { return shift->dbxref_id  }

1;
