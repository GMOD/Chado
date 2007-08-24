#!/usr/bin/perl
#

use Modware::Search::Gene;

my ($gene) = Modware::Search::Gene->Search_by_name( 'sadA');

my $gene_name   = $gene->name();
my $description = $gene->description();
my @synonyms    = @{$gene->synonyms()};
my $syn_string  = join ", ", @synonyms;

print $gene_name."\t".$gene_name.'||'.$description.'||'.$syn_string."\n";
;
