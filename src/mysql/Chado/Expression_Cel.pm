package Chado::Expression_Cel;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Expression_Cel->set_up_table('expression_cel');
Chado::Expression_Cel->hasa(Chado::Expression => 'expression_id');
sub id { return shift->expression_id }

1;
