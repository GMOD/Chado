package Chado::Feature_Expression;
use base 'Chado::DBI';
use mixin 'Class::DBI::Join';
use Class::DBI::Pager;

Chado::Feature_Expression->set_up_table('feature_expression');
Chado::Feature_Expression->hasa(Chado::Feature => 'feature_id');
Chado::Feature_Expression->hasa(Chado::Expression => 'expression_id');

sub feature    { return shift->feature_id }
sub expression { return shift->expression_id }

1;
