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

my $executable = basename($0);

my ($SRCDB,$ORIGIN,$ANNOTATIONS);
GetOptions('srcdb:s'       => \$SRCDB,
           'origin:i'      => \$ORIGIN,
           'annotations:s' => \$ANNOTATIONS,
          ) and $ANNOTATIONS or die <<USAGE;
Usage: $0 -annotations <dir> [options]

Convert UCSC Genome Browser-format gene files into GFF3 version files.
Only the gene IDs and their locations come through.  You have to get
the comments and aliases some other way. Currently some info is being added
as additional application-specific gff tags.

Options:

    -srcdb       <string>   Choose a source for the gene, default "UCSC"
    -origin      <integer>  Choose a relative position to number from, default is "1"
    -annotations <dir>      Directory containing UCSC annotation files
    -center      <string>   ???

USAGE

$SRCDB           ||= 'UCSC';
$ORIGIN          ||= 1;
my $KGXREF         = $ANNOTATIONS.'/kgXref.txt';
my $KNOWNGENE      = $ANNOTATIONS.'/knownGene.txt';
my $KNOWNGENEPEP   = $ANNOTATIONS.'/knownGenePep.txt';
my $KNOWNGENEMRNA  = $ANNOTATIONS.'/knownGeneMrna.txt';
my $KNOWNLOCUSLINK = $ANNOTATIONS.'/knownToLocusLink.txt';
my $KNOWNPFAM      = $ANNOTATIONS.'/knownToPfam.txt';
my $KNOWNU133      = $ANNOTATIONS.'/knownToU133.txt';
my $KNOWNU133PLUS  = $ANNOTATIONS.'/knownToU133Plus2.txt';
my $KNOWNU95       = $ANNOTATIONS.'/knownToU95.txt';
my $GENBANK        = $ANNOTATIONS.'/genbank2accessions.txt';
my $LOCACC         = $ANNOTATIONS.'/loc2acc';
my $LOCGO          = $ANNOTATIONS.'/loc2go';
my $LOCUG          = $ANNOTATIONS.'/loc2UG';
my $REFLINK        = $ANNOTATIONS.'/refLink.txt';
my $REFSEQSUMMARY  = $ANNOTATIONS.'/refSeqSummary.txt';
my $CHROMINFO      = $ANNOTATIONS.'/chromInfo.txt';

my %xref;
my %loc2mrna;
my %ref2mrna;

print STDERR "Parsing Genbank...";
parseGenbank(\%xref,$GENBANK);
print STDERR "done!\n";
print STDERR "Parsing Genbank Peptide...";
parseKnownGenePep(\%xref,$KNOWNGENEPEP);
print STDERR "done!\n";
print STDERR "Parsing Known Gene...";
parseKnownGeneMrna(\%xref,$KNOWNGENEMRNA);
print STDERR "done!\n";
print STDERR "Parsing Known Gene Xref...";
parseKgXref(\%xref,$KGXREF);
print STDERR "done!\n";
print STDERR "Parsing LocusLink...";
parseLocAcc(\%xref,$LOCACC); # the best way I've found so far
                                                  # to link Genbank mRNA accession to
                                                  # Genbank protein accession
print STDERR "done!\n";
print STDERR "Parsing LocusLink -> GO...";
parseLocGo(\%xref,$LOCGO);
print STDERR "done!\n";
print STDERR "Parsing LocusLink -> UniGene...";
parseLocUG(\%xref,$LOCUG);
print STDERR "done!\n";
print STDERR "Parsing Known Gene -> Locuslink...";
parseKnownLocusLink(\%xref,$KNOWNLOCUSLINK);
print STDERR "done!\n";
print STDERR "Parsing Known Gene -> Affy...";
parseKnownAffy(\%xref,$KNOWNU133PLUS,$KNOWNU133,$KNOWNU95);
print STDERR "done!\n";
print STDERR "Parsing Known Gene -> PFAM...";
parseKnownPfam(\%xref,$KNOWNPFAM);
print STDERR "done!\n";
print STDERR "Parsing Known Gene -> RefSeq...";
parseRefLink(\%xref,$REFLINK);
print STDERR "done!\n";
print STDERR "Parsing Known Gene -> RefSeq Summary...";
parseRefSeqSummary(\%xref,$REFSEQSUMMARY);
print STDERR "done!\n";

print "##gff-version 3\n";
#if(1){ #for debugging
open(KG,$KNOWNGENE) or die "couldn't open('$KNOWNGENE'): $!";
while (<KG>) {
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
  print join ("\t",$chrom,$SRCDB,'mRNA',$txStart,$txEnd,'.',$strand,'.',"ID=$id;");
  if(defined($xref{$id})) {
    print "Dbxref=";
    my @annotation_sets = grep { $_ =~ /^db:/ && $_ !~ /protein/ } keys %{$xref{$id}};
    my $i = 0;
    foreach my $annotation_set ( @annotation_sets ) {
      next unless $annotation_set;
      $annotation_set =~ s/^db://;

      #yeah, it's a hack.  so fix it.
      my $foo = join(",",
                     map {uri_escape("$annotation_set:$_")}
                     grep { $xref{$id}{'db:'.$annotation_set}{$_} != 0 && $_ != 0 }
                     keys %{$xref{$id}{'db:'.$annotation_set}}
                    );
      print $foo;
      $i++;
      print "," if $foo && $i != scalar(@annotation_sets);
    }
    print ";";

    if(my @aliases = keys %{ $xref{$id}{Alias} }){
      print "Alias=" . join(",", map {uri_escape($_)} @aliases) . ";";
    }

    if(my @notes = keys %{ $xref{$id}{Note} }){
      print "Note=" . join(",", map {uri_escape($_)} @notes) . ";";
    }

    print "\n";

    #and print the protein if there is one
    if( my($prot_id) = keys %{$xref{$id}{'db:RefSeq_protein'}} ){
      @annotation_sets = grep { $_ =~ /^db:/ && $_ =~ /protein/ } keys %{$xref{$id}};
      print join ("\t",'.',$SRCDB,'protein','.','.','.','.','.',"ID=$prot_id;Parent=$id;");
      my $i = 0;
      print "Dbxref=";
      foreach my $annotation_set ( @annotation_sets ) {
        my @a = keys %{ $xref{$id}{$annotation_set} };
        $annotation_set =~ s/db://;
        my $j = 0;
        foreach my $a (@a){
          print uri_escape( "$annotation_set:$a" ) if $a;
          $j++;
          print "," if $a && $j != scalar(@a);
        }
        $i++;
        print "," unless $i == scalar(@annotation_sets);
      }
      print ";\n";
    }
  }

  # now handle the CDS entries -- the tricky part is the need to keep
  # track of phase
  my $phase = 0;
  my @exon_starts = map {$_-$ORIGIN} split ',',$exonStarts;
  my @exon_ends   = map {$_-$ORIGIN} split ',',$exonEnds;

  if($strand eq '+') {
    for(my $i=0;$i<scalar(@exon_starts);$i++) {
      my $exon_start = $exon_starts[$i] + 1;
      my $exon_end   = $exon_ends[$i];
      my ($utr_start,$utr_end,$cds_start,$cds_end);

      if($exon_start < $cdsStart) { # in a 5' UTR
        $utr_start = $exon_start;
      } elsif($exon_start > $cdsEnd) {
        $utr_start = $exon_start;
      } else {
        $cds_start = $exon_start;
      }

      if($exon_end < $cdsStart) {
        $utr_end = $exon_end;
      } elsif($exon_end > $cdsEnd) {
        $utr_end = $exon_end;
      } else {
        $cds_end = $exon_end;
      }

      if($utr_start && !$utr_end) { # half in half out on 5' end
        $utr_end   = $cdsStart - 1;
        $cds_start = $cdsStart;
        $cds_end   = $exon_end;
      }

      if($utr_end && !$utr_start) { # half in half out on 3' end
        $utr_start = $cdsEnd + 1;
        $cds_end   = $cdsEnd;
        $cds_start = $exon_start;
      }

      die "programmer error, utr_start and no utr_end" unless defined $utr_start == defined $utr_end;
      die "programmer error, cds_start and no cds_end" unless defined $cds_start == defined $cds_end;

      if(defined $utr_start && $utr_start <= $utr_end && $utr_start < $cdsStart) {
        print join ("\t",$chrom,$SRCDB,"five_prime_UTR",$utr_start,$utr_end,'.',$strand,'.',"Parent=$id"),"\n"	
      }

      if(defined $cds_start && $cds_start <= $cds_end) {
        print join ("\t",$chrom,$SRCDB,'CDS',$cds_start,$cds_end,'.',$strand,$phase,"Parent=$id"),"\n";
        $phase = (($cds_end-$cds_start+1-$phase)) % 3;
      }

      if(defined $utr_start && $utr_start <= $utr_end && $utr_start > $cdsEnd) {
        print join ("\t",$chrom,$SRCDB,"three_prime_UTR",,$utr_start,$utr_end,'.',$strand,'.',"Parent=$id"),"\n"	
      }
    }
  }

  if($strand eq '-') {
    my @lines;
    for(my $i=@exon_starts-1; $i>=0; $i--) { # count backwards
      my $exon_start = $exon_starts[$i] + 1;
      my $exon_end   = $exon_ends[$i];
      my ($utr_start,$utr_end,$cds_start,$cds_end);

      if($exon_end > $cdsEnd) { # in a 5' UTR
        $utr_end = $exon_end;
      } elsif($exon_end < $cdsStart) {
        $utr_end = $exon_end;
      } else {
        $cds_end = $exon_end;
      }

      if($exon_start > $cdsEnd) {
        $utr_start = $exon_start;
      } elsif($exon_start < $cdsStart) {
        $utr_start = $exon_start;
      } else {
        $cds_start = $exon_start;
      }

      if($utr_start && !$utr_end) { # half in half out on 3' end
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

      if(defined $utr_start && $utr_start <= $utr_end && $utr_start > $cdsEnd) {
        unshift @lines,join ("\t",$chrom,$SRCDB,"five_prime_UTR",,$utr_start,$utr_end,'.',$strand,'.',"Parent=$id"),"\n"	
      }
      if(defined $cds_start && $cds_start <= $cds_end) {
        unshift @lines,join ("\t",$chrom,$SRCDB,'CDS',$cds_start,$cds_end,'.',$strand,$phase,"Parent=$id"),"\n";
        $phase = (($cds_end-$cds_start+1-$phase)) % 3;
      }

      if(defined $utr_start && $utr_start <= $utr_end && $utr_end < $cdsStart) {
        unshift @lines,join ("\t",$chrom,$SRCDB,"three_prime_UTR",$utr_start,$utr_end,'.',$strand,'.',"Parent=$id"),"\n"	
      }

    }
    print @lines;	
  }
}
close(KG) or die "couldn't close('$KNOWNGENE'): $!";
#} for debugging

print "##FASTA\n";

foreach my $kg (keys %xref){
  my $seq_mrna = $xref{$kg}{'sequence:mrna'};
  my $seq_prot = $xref{$kg}{'sequence:protein'};

  if($seq_mrna){
    foreach my $k (keys %{$xref{$kg}{'db:GenBank_mRNA'}}){
      print ">$k\n". wrap('','',$seq_mrna) ."\n";
    }
  }

  if($seq_prot){
    foreach my $k (keys %{$xref{$kg}{'db:GenBank_protein'}}){
      print ">$k\n". wrap('','',$seq_prot) ."\n";
    }
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

sub parseLocAcc {
  my($xref,$filename) = @_;
  open  ANNFILE, $filename or die "Can't open file $filename: $!";
  while(<ANNFILE>) {
    chomp;
    next if /^#/;
	my @line = split /\t/;

    #note: this doesn't work b/c if the second regex doesn't match, $1 is still
    #leftover from the first regex.  a better method is given below.
	#$line[1] =~ /(.*)\.\d/;
	#my $gene = $1;
	#$line[4] =~ /(.*)\.\d/;
	#my $protein = $1;

    my $loc = $line[0];

    my $gene    = $line[1];
    my $protein = $line[4];
    $gene    =~ s/\.\d+$//;
    $protein =~ s/\.\d+$//;

    next if $gene eq 'none';

    push @{ $loc2mrna{$loc} }, $gene;

	$xref->{$gene}{'db:GenBank_protein'}{$protein} = 1 unless($gene eq 'none' || $protein eq '-' || $protein !~ /^[A-Z]{3}\d/ || $protein =~ /_/);
  }
  close ANNFILE;
}

=head2 parseLocGo

 Title   : parseLocGo
 Usage   :
 Function:
 Example :
 Returns :
 Args    :

=cut

sub parseLocGo {
  my($xref,$filename) = @_;
  open  ANNFILE, $filename or die "Can't open file $filename: $!";
  while(<ANNFILE>) {
    chomp;
    next if /^#/;
	my @line = split /\t/;

    if($loc2mrna{$line[0]}){
      foreach my $mrna (@{$loc2mrna{$line[0]}}){
        $xref->{$mrna}{'cvterm:go'}{$line[1]} = 1;
      }
    }
  }
  close ANNFILE;
}

=head2 parseLocUG

 Title   : parseLocUG
 Usage   :
 Function:
 Example :
 Returns :
 Args    :

=cut

sub parseLocUG {
  my($xref,$filename) = @_;
  open  ANNFILE, $filename or die "Can't open file $filename: $!";
  while(<ANNFILE>) {
    chomp;
    next if /^#/;
	my @line = split /\t/;

    if($loc2mrna{$line[0]}){
      foreach my $mrna (@{$loc2mrna{$line[0]}}){
        $xref->{$mrna}{'db:Unigene'}{$line[1]} = 1;
      }
    }
  }
  close ANNFILE;
}

=head2 parseRefLink

 Title   : parseRefLink
 Usage   :
 Function:
 Example :
 Returns :
 Args    :

=cut

sub parseRefLink {
  my($xref,$filename) = @_;
  open  ANNFILE, $filename or die "Can't open file $filename: $!";
  while(<ANNFILE>) {
    chomp;
    next if /^#/;
	my($symbol,$description,$refmrna,$refprotein,undef,undef,$locus,$omim) = split /\t/;
    $description = uri_escape($description);

    if($ref2mrna{$refmrna}){
      foreach my $mrna (@{$ref2mrna{$refmrna}}){
        $xref->{$mrna}{'db:LocusLink'}{$locus} = 1;
        $xref->{$mrna}{'db:OMIM'}{$omim} = 1;
        $xref->{$mrna}{'db:RefSeq_mRNA'}{$refmrna} = 1;
        $xref->{$mrna}{'db:RefSeq_protein'}{$refprotein} = 1;
        $xref->{$mrna}{'Alias'}{$symbol} = 1;
        $xref->{$mrna}{'Note'}{$description} = 1;
      }
    }
  }
  close ANNFILE;
}

=head2 parseRefSeqSummary

 Title   : parseRefSeqSummary
 Usage   :
 Function:
 Example :
 Returns :
 Args    :

=cut

sub parseRefSeqSummary {
  my($xref,$filename) = @_;
  open  ANNFILE, $filename or die "Can't open file $filename: $!";
  while(<ANNFILE>) {
    chomp;
    next if /^#/;
	my($refmrna,$completeness,$description) = split /\t/;
    $description = uri_escape($description);

    if($ref2mrna{$refmrna}){
      foreach my $mrna (@{$ref2mrna{$refmrna}}){
        $xref->{$mrna}{'completeness'}{$completeness} = 1;
        $xref->{$mrna}{'description'}{$description} = 1;
      }
    }
  }
  close ANNFILE;
}

=head2 parseKnownLocusLink

 Title   : parseKnownLocusLink
 Usage   :
 Function:
 Example :
 Returns :
 Args    :

=cut

sub parseKnownLocusLink {
  my($xref,$filename) = @_;
  open  ANNFILE, $filename or die "Can't open file $filename: $!";
  while(<ANNFILE>) {
    chomp;
    next if /^#/;
	my ($accession,$locuslink) = split /\t/;
	$xref->{$accession}{'db:LocusLink'}{$locuslink} = 1;
  }
  close ANNFILE;
}

=head2 parseKnownPfam

 Title   : parseKnownPfam
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub parseKnownPfam {
  my($xref,$filename) = @_;
  open  ANNFILE, $filename or die "Can't open file $filename: $!";
  while(<ANNFILE>) {
    chomp;
    next if /^#/;
	my ($accession,$pfam) = split /\t/;
	$xref->{$accession}{'db:PFAM'}{$pfam} = 1;
  }
  close ANNFILE;
}

=head2 parseKnownAffy

 Title   : parseKnownAffy
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub parseKnownAffy {
  my $xref = shift @_;

  my $i = 0;
  my @chip = qw(U133PLUS U133 U95);
  foreach my $filename (@_){
    open  ANNFILE, $filename or die "Can't open file $filename: $!";
    while(<ANNFILE>) {
      chomp;
      next if /^#/;
      my ($accession,$probeset) = split /\t/;
      $xref->{$accession}{'db:Affymetrix_'.$chip[$i]}{$probeset} = 1;
    }
    close ANNFILE;
    $i++;
  }
}


=head2 parseKnownGeneMrna

 Title   : parseKnownGeneMrna
 Usage   : Links mRNA sequence to mRNA.
 Function:
 Example :
 Returns :
 Args    :

=cut

sub parseKnownGeneMrna {
  my($xref,$filename) = @_;
  open  ANNFILE, $filename or die "Can't open file $filename: $!";
  while(<ANNFILE>) {
    chomp;
    next if /^#/;
	my ($accession,$sequence) = split /\t/;
	$xref->{$accession}{'sequence:mrna'} = $sequence;
  }
  close ANNFILE;
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

sub parseKnownGenePep {
  my($xref,$filename) = @_;
  open  ANNFILE, $filename or die "Can't open file $filename: $!";
  while(<ANNFILE>) {
    chomp;
    next if /^#/;
	my ($accession,$sequence) = split /\t/;

    $xref->{$accession}{'sequence:protein'} = $sequence;
#	$xref->{$protGenbankId}{'sequence:protein'} = $sequence;
  }
  close ANNFILE;
}

=head2 mrna2protein

 Title   : mrna2protein
 Usage   : creates a hash between the mRNA genbank accession
           (used in UCSC DB to key everything) and the proper
           genbank protein accession
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub parseGenbank {
  my($xref,$filename) = @_;
#  my $file = shift;
#  my $annotations = {}; # stores the mRNA genbank id as key, protein genbank id as value
  open ANNFILE, $filename or die "Can't open file $filename: $!";
  while(<ANNFILE>) {
    chomp;
    next if /^#/;
    my ($mrna, $prot) = split /\t/;
    $xref->{$mrna}{'db:GenBank_protein'}{$prot} = 1 if $prot =~ /^[A-Z]{3}\d/ and $prot !~ /_/;
#    $annotations->{$mrna} = $prot;
  }
  close ANNFILE;
#  return($annotations);
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
  my($xref,$filename) = @_;

  open(ANNFILE, $filename) or die "Can't open file $filename: $!";
  while(<ANNFILE>) {
    chomp;
    next if /^#/;
	# first two are the same (genebank) followed by swissprot etc...
    my ($kgID, $mRNA, $spID, $spDisplayID, $geneSymbol, $refseq, $protAcc, $description) = split /\t/;
    my $key = $kgID;
    # escape certain fields
    $key = uri_escape($key);
    $description = uri_escape($description);

    push @{ $ref2mrna{$refseq} }, $kgID;

    #http://www.ncbi.nlm.nih.gov/RefSeq/key.html#accessions
    #http://www.ncbi.nlm.nih.gov/Sitemap/samplerecord.html#AccessionB
    #http://www.ncbi.nlm.nih.gov/Sitemap/samplerecord.html#ProteinIDB

    $xref->{$key}{'db:GenBank_protein'}{$kgID}          = 1 if $kgID and $kgID =~ /^[A-Z]{1,2}\d/ and $kgID !~ /_/;
    $xref->{$key}{'db:GenBank_mRNA'}{$mRNA}             = 1 if $mRNA and $mRNA =~ /^[A-Z]{1,2}\d/ and $mRNA !~ /_/ and $mRNA ne $kgID;
    $xref->{$key}{'db:Swiss'}{$spID}                    = 1 if $spID;
    $xref->{$key}{'db:Swiss'}{$spDisplayID}             = 1 if $spDisplayID and $spDisplayID ne $spID;
    $xref->{$key}{'Alias'}{$geneSymbol}                 = 1 if $geneSymbol;
    $xref->{$key}{'db:RefSeq_mRNA'}{$refseq}            = 1 if $refseq and $refseq =~ /^(NC|NG|NM|NR|NT|NW|XM|XR|NZ)_/;
    $xref->{$key}{'db:RefSeq_protein'}{$protAcc}        = 1 if $protAcc and $protAcc =~ /^(NP|XP|ZP)_/;
    $xref->{$key}{'Note'}{$description}          = 1 if $description;
  }
  close(ANNFILE);
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

  % ucsc_genes2gff.pl -src RefSeq refseq_data.ucsc > refseq.gff

The resulting GFF file can then be loaded into a Bio::DB::GFF database
using the following command:

  % bulk_load_gff.pl -d <databasename> refseq.gff

=head1 SEE ALSO

L<Bio::DB::GFF>, L<bulk_load_gff.pl>, L<load_gff.pl>

=head1 AUTHOR

Allen Day <allenday@ucla.edu>, Lincoln Stein <lstein@cshl.org>.

Copyright (c) 2003 Cold Spring Harbor Laboratory

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.

=cut

