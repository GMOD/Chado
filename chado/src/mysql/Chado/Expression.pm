package Chado::Expression;
use base 'Chado::DBI';

Chado::Expression->set_up_table('expression');
sub id { return shift->expression_id }

1;
