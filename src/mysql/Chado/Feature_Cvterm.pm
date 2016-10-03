package Chado::Feature_Cvterm;
use base 'Chado::DBI';
use mixin 'Class::DBI::Join';
use Class::DBI::Pager;

Chado::Feature_Cvterm->set_up_table('feature_cvterm');
Chado::Feature_Cvterm->hasa(Chado::Feature => 'feature_id');
Chado::Feature_Cvterm->hasa(Chado::Cvterm     => 'cvterm_id');

sub id { return shift->feature_cvterm_id }
sub feature { return shift->feature_id }
sub cvterm     { return shift->cvterm_id     }

1;
