#!/usr/bin/perl
use strict;
use warnings;

my ( $gene_name_input, $page_template, $table_template ) = @ARGV;

die "please pass gene_name, page_template, table_template as arguments\n" if ( !$gene_name_input || !$page_template || !$table_template );

use Modware::Search::Gene;

my $genes = Modware::Search::Gene->Search_by_name( $gene_name_input );

while ( my $gene = $genes->next ) {
    my $gene_name   = $gene->name();
    my $description = $gene->description() || '';
    my @synonyms    = @{$gene->synonyms()};
    my $syn_string  = join ", ", @synonyms || '';
    my $row_data    = join ("||", $gene_name, $description, $syn_string);
    print join("\t",$gene_name,$page_template,$table_template,$row_data),"\n";
}
