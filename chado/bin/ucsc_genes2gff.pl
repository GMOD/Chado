#!/usr/bin/perl

# convert UCSC gene files into GFF3 data

use strict;
use File::Basename 'basename';
use Getopt::Long;
use URI::Escape;
use Text::Wrap;
use Bio::SeqIO;
use Bio::SeqFeature::Generic;
use Data::Dumper;

my $executable = basename($0);

my ($SRC,$ORIGIN,$KNOWNGENEPEP,$KNOWNGENEMRNA,$KNOWNLOCUSLINK,$GENBANK,$KGXREF,$LOCACC,$CENTER);
GetOptions('src:s'    => \$SRC,
	   'origin:i' => \$ORIGIN,
	   'kgXref:s' => \$KGXREF,
	   'knownGenePep:s' => \$KNOWNGENEPEP,
	   'knownGeneMrna:s' => \$KNOWNGENEMRNA,
	   'knownLocusLink:s' => \$KNOWNLOCUSLINK,
	   'genbank:s' => \$GENBANK,
	   'loc2acc:s' => \$LOCACC,
	   'center:s' => \$CENTER,
	   ) or die <<USAGE;
Usage: cat knownGene.txt | $0 [options]

Convert UCSC Genome Browser-format gene files into GFF3 version files.
Only the gene IDs and their locations come through.  You have to get
the comments and aliases some other way. Currently some info is being added
as additional application-specific gff tags.

Options:

    -src         <string>   Choose a source for the gene, default "UCSC"
    -origin      <integer>  Choose a relative position to number from, default is "1"
    -annotations <file>     Annotations file
    -center      <string>   ???

USAGE

$SRC    ||= 'UCSC';
$ORIGIN ||= 1;
$KGXREF ||='kgXref.txt';
$KNOWNGENEPEP ||= 'knownGenePep.txt';
$KNOWNGENEMRNA ||= 'knownGeneMrna.txt';
$KNOWNLOCUSLINK ||= 'knownToLocusLink.txt';
$GENBANK ||= 'genbank2accessions.txt';
$LOCACC ||= 'loc2acc';
$CENTER ||= 'unigene';

my $mrna2protein = parseGenbank($GENBANK);
my $kgxref = parseKgXref($KGXREF);
my $loc2acc = parseLocAcc($LOCACC); # the best way I've found so far to link Genbank mRNA accession to Genbank protein accession
my $knowngenepep = parseKnownGenePep($KNOWNGENEPEP);
my $knowngenemrna = parseKnownGeneMrna($KNOWNGENEMRNA);
my $knownlocuslink = parseKnownLocusLink($KNOWNLOCUSLINK);
# need to pull in the omim and other annotations too

print "##gff-version 3\n";

while (<>) {
  chomp;
  next if /^\#/;;
  my ($id,$chrom,$strand,$txStart,$txEnd,$cdsStart,$cdsEnd,$exons,$exonStarts,$exonEnds) = split /\t/;
  my ($utr5_start,$utr5_end,$utr3_start,$utr3_end);

  # adjust for Jim's 0-based coordinates
  $txStart++;
  $cdsStart++;

  $txStart  -= $ORIGIN;
  $txEnd    -= $ORIGIN;
  $cdsStart -= $ORIGIN;
  $cdsEnd   -= $ORIGIN;

  # print the transcript
  print join ("\t",$chrom,$SRC,'mRNA',$txStart,$txEnd,'.',$strand,'.',"ID=$id");
  #print 
  if(defined($kgxref->{$id})){
      foreach my $annotation_set (keys %{$kgxref->{$id}}){
         print ";";
		 print "$annotation_set=", join (",", keys %{$kgxref->{$id}->{$annotation_set}});
		 
	  #foreach my $annotation_key (keys %{$annotation->{$id}->{$annotation_set}}){
	  #    print "$annotation_key=", join (",", $annotation->{$id}->{$annotation_set}->{$annotation_key});
	  #}
      }
	  if(defined $knownlocuslink->{$id}) { print ";locuslink=", $knownlocuslink->{id}; }
	  print "\n";
#	  # now write out stuff for protein
	  my @protGenBank = keys (%{$kgxref->{$id}->{protein}});
	  my $protGenBank = $protGenBank[0];
	  if(defined ($protGenBank)) { print join ("\t",'.', $SRC,'protein','.','.','.','.',"ID=$protGenBank;Parent=$id"), "\n"; }
  }
 # print "\n";
  #print join ("\t","dbxref=".$annotations->{$id}),"\n";
  #print Dumper($annotations->{$id});
  # now handle the CDS entries -- the tricky part is the need to keep
  # track of phase
  my $phase = 0;
  my @exon_starts = map {$_-$ORIGIN} split ',',$exonStarts;
  my @exon_ends   = map {$_-$ORIGIN} split ',',$exonEnds;

  if ($strand eq '+') {
    for (my $i=0;$i<@exon_starts;$i++) {
      my $exon_start = $exon_starts[$i] + 1;
      my $exon_end   = $exon_ends[$i];
      my ($utr_start,$utr_end,$cds_start,$cds_end);

      if ($exon_start < $cdsStart) { # in a 5' UTR
	$utr_start = $exon_start;
      } elsif ($exon_start > $cdsEnd) {
	$utr_start = $exon_start;
      } else {
	$cds_start = $exon_start;
      }

      if ($exon_end < $cdsStart) {
	$utr_end = $exon_end;
      } elsif ($exon_end > $cdsEnd) {
	$utr_end = $exon_end;
      } else {
	$cds_end = $exon_end;
      }

      if ($utr_start && !$utr_end) { # half in half out on 5' end
	$utr_end   = $cdsStart - 1;
	$cds_start = $cdsStart;
	$cds_end   = $exon_end;
      }

      if ($utr_end && !$utr_start) { # half in half out on 3' end
	$utr_start = $cdsEnd + 1;
	$cds_end   = $cdsEnd;
	$cds_start = $exon_start;
      }

      die "programmer error, utr_start and no utr_end" unless defined $utr_start == defined $utr_end;
      die "programmer error, cds_start and no cds_end" unless defined $cds_start == defined $cds_end;

      if (defined $utr_start && $utr_start <= $utr_end && $utr_start < $cdsStart) {
#	print join ("\t",$chrom,$SRC,"5'-UTR",$utr_start,$utr_end,'.',$strand,'.',"Parent=$id"),"\n"	
	print join ("\t",$chrom,$SRC,"five_prime_UTR",$utr_start,$utr_end,'.',$strand,'.',"Parent=$id"),"\n"	
      }

      if (defined $cds_start && $cds_start <= $cds_end) {
	print join ("\t",$chrom,$SRC,'CDS',$cds_start,$cds_end,'.',$strand,$phase,"Parent=$id"),"\n";
	$phase = (($cds_end-$cds_start+1-$phase)) % 3;
      }

      if (defined $utr_start && $utr_start <= $utr_end && $utr_start > $cdsEnd) {
#	print join ("\t",$chrom,$SRC,"3'-UTR",,$utr_start,$utr_end,'.',$strand,'.',"Parent=$id"),"\n"	
	print join ("\t",$chrom,$SRC,"three_prime_UTR",,$utr_start,$utr_end,'.',$strand,'.',"Parent=$id"),"\n"	
      }
    }
  }

  if ($strand eq '-') {
    my @lines;
    for (my $i=@exon_starts-1; $i>=0; $i--) { # count backwards
      my $exon_start = $exon_starts[$i] + 1;
      my $exon_end   = $exon_ends[$i];
      my ($utr_start,$utr_end,$cds_start,$cds_end);

      if ($exon_end > $cdsEnd) { # in a 5' UTR
	$utr_end = $exon_end;
      } elsif ($exon_end < $cdsStart) {
	$utr_end = $exon_end;
      } else {
	$cds_end = $exon_end;
      }

      if ($exon_start > $cdsEnd) {
	$utr_start = $exon_start;
      } elsif ($exon_start < $cdsStart) {
	$utr_start = $exon_start;
      } else {
	$cds_start = $exon_start;
      }

      if ($utr_start && !$utr_end) { # half in half out on 3' end
	$utr_end   = $cdsStart - 1;
	$cds_start = $cdsStart;
	$cds_end   = $exon_end;
      }

      if ($utr_end && !$utr_start) { # half in half out on 5' end
	$utr_start = $cdsEnd + 1;
	$cds_end   = $cdsEnd;
	$cds_start = $exon_start;
      }

      die "programmer error, utr_start and no utr_end" unless defined $utr_start == defined $utr_end;
      die "programmer error, cds_start and no cds_end" unless defined $cds_start == defined $cds_end;

      if (defined $utr_start && $utr_start <= $utr_end && $utr_start > $cdsEnd) {
#	unshift @lines,join ("\t",$chrom,$SRC,"5'-UTR",,$utr_start,$utr_end,'.',$strand,'.',"Parent=$id"),"\n"	
	unshift @lines,join ("\t",$chrom,$SRC,"five_prime_UTR",,$utr_start,$utr_end,'.',$strand,'.',"Parent=$id"),"\n"	
      }
      if (defined $cds_start && $cds_start <= $cds_end) {
	unshift @lines,join ("\t",$chrom,$SRC,'CDS',$cds_start,$cds_end,'.',$strand,$phase,"Parent=$id"),"\n";
	$phase = (($cds_end-$cds_start+1-$phase)) % 3;
      }

      if (defined $utr_start && $utr_start <= $utr_end && $utr_end < $cdsStart) {
#	unshift @lines,join ("\t",$chrom,$SRC,"3'-UTR",$utr_start,$utr_end,'.',$strand,'.',"Parent=$id"),"\n"	
	unshift @lines,join ("\t",$chrom,$SRC,"three_prime_UTR",$utr_start,$utr_end,'.',$strand,'.',"Parent=$id"),"\n"	
      }

    }
    print @lines;	
  }
}

# for protein/mrna printing
  if (defined($kgxref) && (defined($knowngenepep) || defined($knowngenemrna))) {
  print "##FASTA\n";
  # now print all my lovely protein sequence
  foreach my $protein (keys %{$knowngenepep}) {
	print ">".$protein."\n";
	$Text::Wrap::columns = 79;
	print wrap('', '', $knowngenepep->{$protein});
	print "\n";
  }
  # now all the mRNA sequence
  foreach my $mrna (keys %{$knowngenemrna}) {
	print ">".$mrna."\n";
	$Text::Wrap::columns = 79;
	print wrap('', '', $knowngenemrna->{$mrna});
	print "\n";
  }
}

=head2 parseLocAcc

 Title   : parseLocAcc
 Usage   :
 Function:
 Example :
 Returns :
 Args    :

=cut

sub parseLocAcc{
  my $filename = shift;
  my $annotations = {};
  open  ANNFILE, $filename or die "Can't open file $filename\n";
  while(<ANNFILE>) {
    chomp;
    next if /^\#/;;
	my @line = split /\t/;
	$line[1] =~ /(.*)\.\d/;
	my $gene = $1;
	$line[4] =~ /(.*)\.\d/;
	my $protein = $1;
	if($protein ne '-') { $annotations->{$gene} = $protein; }
  }
  close ANNFILE;
  return ($annotations);
}


=head2 parseKnownLocusLink

 Title   : parseKnownLocusLink
 Usage   :
 Function:
 Example :
 Returns :
 Args    :

=cut

sub parseKnownLocusLink{
  my $filename = shift;
  my $annotations = {};
  open  ANNFILE, $filename or die "Can't open file $filename\n";
  while(<ANNFILE>) {
    chomp;
    next if /^\#/;;
	my ($accession,$locuslink) = split /\t/;
	$annotations->{$accession} = $locuslink;
  }
  close ANNFILE;
  return ($annotations);
}


=head2 parseKnownGeneMrna

 Title   : parseKnownGeneMrna
 Usage   : Links mRNA sequence to mRNA.
 Function:
 Example :
 Returns :
 Args    :

=cut

sub parseKnownGeneMrna{
  my $filename = shift;
  my $annotations = {};
  open  ANNFILE, $filename or die "Can't open file $filename\n";
  while(<ANNFILE>) {
    chomp;
    next if /^\#/;;
	my ($accession,$sequence) = split /\t/;
	$annotations->{$accession} = $sequence;
  }
  close ANNFILE;
  return ($annotations);
}

=head2 parseKnownGenePep

 Title   : parseKnownGenePep
 Usage   : This method depends on parseLocAcc being run first so mRNA accessions can
           be mapped to protein accessions.
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub parseKnownGenePep{
  my $filename = shift;
  my $annotations = {};
  open  ANNFILE, $filename or die "Can't open file $filename\n";
  while(<ANNFILE>) {
    chomp;
    next if /^\#/;;
	my ($accession,$sequence) = split /\t/;
	#my @protAcc = keys %{$kgxref->{$accession}->{protAcc}};
	#print @protAcc[0]."\n";
	#$annotations->{@protAcc[0]} = $sequence;
	my $protGenbankId = $mrna2protein->{$accession};
	$annotations->{$protGenbankId} = $sequence;
  }
  close ANNFILE;
  return ($annotations);
}

=head2 mrna2protein

 Title   : mrna2protein
 Usage   : creates a hash between the mRNA genbank accession (used in UCSC DB to key everything) and the proper genbank protein accession
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub parseGenbank{
   my $file = shift;
   my $annotations = {}; # stores the mRNA genbank id as key, protein genbank id as value
   open ANNFILE, $file or die "Can't open file $file\n";
   while(<ANNFILE>) {
	 chomp;
	 next if /^\#/;;
	 my ($mrna, $prot) = split /\t/;
	 $annotations->{$mrna} = $prot;
   }
   close ANNFILE;
   return($annotations);
}



=head2 parseKgXref
 Title   : parseKgXref
 Usage   :
 Function:
 Example :
 Returns :
 Args    :
=cut
sub parseKgXref {
  my $filename = shift;
  my $annotations = {};
  open ANNFILE, $filename or die "Can't open file $filename\n";
  while(<ANNFILE>) {
    chomp;
    next if /^\#/;;
	# first two are the same (genebank) followed by swissprot etc...
    my ($kgID, $mRNA, $spID, $spDisplayID, $geneSymbol, $refseq, $protAcc, $description) = split /\t/;
    my $key = "";
    if($CENTER =~ /unigene/i) { $key = $kgID; }
    else { $key = $refseq; }
    # escape certain fields
    $key = uri_escape($key);
    $description = uri_escape($description);

    $annotations->{$key}->{kgID}->{$kgID} = 1                if $kgID;
    $annotations->{$key}->{mRNA}->{$mRNA} = 1                if $mRNA;
    $annotations->{$key}->{spID}->{$spID} = 1                if $spID;
    $annotations->{$key}->{spDisplayID}->{$spDisplayID} = 1  if $spDisplayID;
    $annotations->{$key}->{geneSymbol}->{$geneSymbol} = 1    if $geneSymbol;
    $annotations->{$key}->{refseq}->{$refseq} = 1            if $refseq;
    $annotations->{$key}->{protAcc}->{$protAcc} = 1          if $protAcc;
    $annotations->{$key}->{description}->{$description} = 1  if $description;
	my $protAccession = $mrna2protein->{$mRNA}; # pulls out the protein genbank accession
	$annotations->{$key}->{protein}->{$protAccession} = 1    if $protAccession;
  }
  close ANNFILE;
  return($annotations);
}


__END__

=head1 NAME

ucsc_genes2gff.pl - Convert UCSC Genome Browser-format gene files into GFF files suitable for loading into gbrowse

=head1 SYNOPSIS

  % ucsc_genes2gff.pl [options] ucsc_file1 ucsc_file2...

Options:

    -src    <string>   Choose a source for the gene, default "UCSC"
    -origin <integer>  Choose a relative position to number from, default is "1"

=head1 DESCRIPTION

This script massages the gene files available from the "tables" link
of the UCSC genome browser (genome.ucsc.edu) into a form suitable for
loading of gbrowse.  Warning: it only works with the gene tables.
Other tables, such as EST alignments, contours and repeats, have their
own formats which will require other scripts to parse.

To use this script, get one or more UCSC tables, either from the
"Tables" link on the browser, or from the UCSC Genome Browser FTP
site.  Give the table file as the argument to this script.  You may
want to provide an alternative "source" field.  Otherwise this script
defaults to "UCSC".

  % pucsc_genes2gff.pl -src RefSeq refseq_data.ucsc > refseq.gff

The resulting GFF file can then be loaded into a Bio::DB::GFF database
using the following command:

  % bulk_load_gff.pl -d <databasename> refseq.gff

=head1 SEE ALSO

L<Bio::DB::GFF>, L<bulk_load_gff.pl>, L<load_gff.pl>

=head1 AUTHOR

Lincoln Stein <lstein@cshl.org>.

Copyright (c) 2003 Cold Spring Harbor Laboratory

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.

=cut

