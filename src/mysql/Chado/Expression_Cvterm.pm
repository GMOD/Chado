package Chado::Expression_Cvterm;
use base 'Chado::DBI';
use mixin 'Class::DBI::Join';
use Class::DBI::Pager;

Chado::Expression_Cvterm->set_up_table('expression_cvterm');
Chado::Expression_Cvterm->hasa(Chado::Expression => 'expression_id');
Chado::Expression_Cvterm->hasa(Chado::Cvterm     => 'cvterm_id');

sub id { return shift->expression_cvterm_id }
sub expression { return shift->expression_id }
sub cvterm     { return shift->cvterm_id     }

1;
