package Chado::Eplatform;
use base 'Chado::DBI';

Chado::Eplatform->set_up_table('eplatform');

sub id   { return shift->eplatform_id }

1;
