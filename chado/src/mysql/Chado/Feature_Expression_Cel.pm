package Chado::Feature_Expression_Cel;
use base 'Chado::DBI';
use mixin 'Class::DBI::Join';

Chado::Feature_Expression_Cel->set_up_table('feature_expression_cel');
Chado::Feature_Expression_Cel->hasa(Chado::Feature => 'feature_id');
Chado::Feature_Expression_Cel->hasa(Chado::Expression => 'expression_id');

sub feature    { return shift->feature_id }
sub expression { return shift->expression_id }

1;
