package Chado::Feature_Expression_Dchipxls;
use base 'Chado::DBI';
use mixin 'Class::DBI::Join';

Chado::Feature_Expression_Dchipxls->set_up_table('feature_expression_dchipxls');
Chado::Feature_Expression_Dchipxls->hasa(Chado::Feature => 'feature_id');
Chado::Feature_Expression_Dchipxls->hasa(Chado::Expression => 'expression_id');

sub feature    { return shift->feature_id }
sub expression { return shift->expression_id }

1;
