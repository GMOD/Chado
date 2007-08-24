#!/usr/bin/perl

use Modware::Search::Gene;

#my ($gene) = Modware::Search::Gene->Search_by_name( 'sadA');
my @genes = Modware::Search::Gene->Search_by_name( 's*');

map { printgene2wikistr($_); } @genes;

sub printgene2wikistr {
  my($gene)=@_;
my $gene_name   = $gene->name();
my $description = $gene->description();
my @synonyms    = @{$gene->synonyms()};
my $syn_string  = join ", ", @synonyms;

print $gene_name.'||'.$description.'||'.$syn_string."\n";
;
}

