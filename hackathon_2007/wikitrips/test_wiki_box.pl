#!/usr/bin/perl
#
#
use WikiBox;


$box = WikiBox->retrieve( 3 );
use Data::Dumper;
print Dumper($box);
