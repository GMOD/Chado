package Chado::Expression_Egroup;
use base 'Chado::DBI';
use mixin 'Class::DBI::Join';

Chado::Expression_Egroup->set_up_table('expression_egroup');
Chado::Expression_Egroup->hasa(Chado::Expression => 'expression_id');
Chado::Expression_Egroup->hasa(Chado::Egroup     => 'egroup_id');

sub expression { return shift->expression_id }
sub egroup     { return shift->egroup_id     }

1;
