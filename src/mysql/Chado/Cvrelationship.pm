package Chado::Cvrelationship;
use base 'Chado::DBI';

use Chado::Cvrelationship;
use Class::DBI::Pager;

Chado::Cvrelationship->set_up_table('cvrelationship');

sub id       { return shift->cvrelationship_id }

1;
