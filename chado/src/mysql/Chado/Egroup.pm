package Chado::Egroup;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Egroup->set_up_table( 'egroup' );
Chado::Egroup->has_many('expressions', 'Chado::Expression_Egroup' => 'egroup_id');

sub id { return shift->egroup_id }

1;
