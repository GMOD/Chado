package Chado::Eplatform;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Eplatform->set_up_table('eplatform');

sub id   { return shift->eplatform_id }

1;
