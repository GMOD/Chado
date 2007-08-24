#!/usr/bin/perl
use strict;
my ( $gene_name_input, $page_template, $table_template ) = @ARGV;

die "please pass gene_name, page_template, table_template as arguments\n" if ( !$gene_name_input || !$page_template || !$table_template );

use Modware::Search::Gene;

my ($gene) = Modware::Search::Gene->Search_by_name( $gene_name_input );

my $gene_name   = $gene->name();
my $description = $gene->description();
my @synonyms    = @{$gene->synonyms()};
my $syn_string  = join ", ", @synonyms;
print $gene_name."\t".$page_template."\t".$table_template."\t".$gene_name.'||'.$description.'||'.$syn_string."\n";
