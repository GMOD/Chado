#!/usr/bin/perl

my ( $gene_name_input, $template ) = @ARGV;

die "please pass gene_name and template_name as arguments\n" if ( !$gene_name_input || !$template);

use Modware::Search::Gene;

my ($gene) = Modware::Search::Gene->Search_by_name( $gene_name_input );

my $gene_name   = $gene->name();
my $description = $gene->description();
my @synonyms    = @{$gene->synonyms()};
my $syn_string  = join ", ", @synonyms;
print $gene_name."\t".$template."\t".$gene_name.'||'.$description.'||'.$syn_string."\n";
