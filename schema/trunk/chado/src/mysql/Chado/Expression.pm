package Chado::Expression;
use base 'Chado::DBI';

Chado::Expression->set_up_table('expression');
Chado::Expression->has_many('expression_egroup', 'Chado::Expression_Egroup' => 'expression_id');

sub id { return shift->expression_id }

1;
