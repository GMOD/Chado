package Chado::Feature;
use base 'Chado::DBI';

Chado::Feature->set_up_table('feature');

Chado::Feature->has_many('expression_dchipxls', 'Chado::Feature_Expression_Dchipxls' => 'feature_id');

sub id { return shift->feature_id }

1;
