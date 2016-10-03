#!/usr/bin/env perl

# convert UCSC gene files into GFF3 data

use strict;
use File::Basename 'basename';
use Getopt::Long;
use URI::Escape;
use Text::Wrap;
$Text::Wrap::columns = 79;
use Bio::SeqIO;
use Bio::SeqFeature::Generic;
use Data::Dumper;

while(<>){
  chomp;
  my($bin,$chrom,$start,$end,$name,$source,$type) = split /\t/;

  my $gfftype = $type eq 'SNP' ? 'SNP' :
                $type eq 'INDEL' ? 'indel' :
                $type eq 'SEGMENTAL' ? 'simple_sequence_length_polymorphism' :
                $type eq 'unknown' ? 'sequence_variant' :
                die "don't know how to represent variant type $type";

  print join("\t", ($chrom, $source, $gfftype, $start + 1, $end, '.', '.', '.', "ID=$name")), "\n";
}
