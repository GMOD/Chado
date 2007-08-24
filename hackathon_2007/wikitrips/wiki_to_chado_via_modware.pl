#!/usr/bin/perl
#
use Wiki::DBI;
use Modware::Search::Gene;


my $box  = Wiki::Box->retrieve(3);

my @rows = $box->rows();

foreach $row (@rows){
   print $row->row_data();

}

