#!/usr/bin/perl

use Wiki::DBI;
use Modware::Search::Gene;

my $box  = Wiki::Box->retrieve(5);
my @rows = $box->rows();

foreach $row (@rows){
  my $row_data = $row->row_data();
  $row_data =~ s/\n//g;

  my ($gene_name, $description, $synonym_str) = ( $row_data =~ /^(.+?)\|\|(.+?)\|\|(.+)/ );
  my ($gene) = Modware::Search::Gene->Search_by_name( $gene_name );

  $gene->description( trim($description) );
  my @synonyms = split ", ", $synonym_str;

  # Trim whitespace from synonyms
  @synonyms = map { trim($_) } @synonyms;

  $gene->synonyms( \@synonyms );

  $gene->update();

}

# sub to trim whitespace
# should be moved to utility class
sub trim {
   my $string = shift;
   $string =~ s/^\s+//;
   $string =~ s/\s+$//;
   return $string;
}
