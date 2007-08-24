#!/usr/bin/perl
#
use Modware::Search::Gene;
use strict;
open (FILE, "<sada.out.modified");

while (<FILE>){

  my ($gene_name, $new_name, $description, $synonym_str) = ( /^([^\t]+)\t(.+?)\|\|(.+?)\|\|(.+)/ );


  my ($gene) = Modware::Search::Gene->Search_by_name( $gene_name );

  $gene->description( $description );
  $gene->name( $new_name );
  my @synonyms = split ", ", $synonym_str;

  $gene->synonyms( \@synonyms );

  $gene->update();
}

