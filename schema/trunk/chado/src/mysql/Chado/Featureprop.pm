package Chado::Featureprop;
use base 'Chado::DBI';

Chado::Featureprop->set_up_table('featureprop');
Chado::Featureprop->hasa(Chado::Feature => 'feature_id');

sub id         { return shift->featureprop_id }
sub name       { return shift->pval }
sub feature    { return shift->feature_id }

1;
