package Chado::Cvpath;
use base 'Chado::DBI';

use Chado::Cvrelationship;
use Class::DBI::Pager;

Chado::Cvpath->set_up_table('cvpath');

sub id   { return shift->cvpath_id }

1;
