#!/usr/bin/perl

use Bio::GMOD::Bulkfiles;    

my $dumpchrbases= 1;
my $dumpfeats= 1;
my $makeout= 1;

my $config= shift @ARGV || 'sgdbulk1';
  ## 'sgdbulk1' or 'fbbulk-r4', # 'fbbulk-r3h', # 'fbbulk-dpse1'
  
my ($feattables,$seqfiles,$chrfeats);

my $sequtil= Bio::GMOD::Bulkfiles->new( 
  configfile => $config, 
  debug => 1, showconfig => 0,
  );

if ($dumpfeats) { 
  $feattables = $sequtil->dumpFeatures(); 
  $chrfeats= $sequtil->sortNSplitByChromosome( $feattables) ; 
  }
if ($dumpchrbases) { $seqfiles = $sequtil->dumpChromosomeBases(); }

# this part takes processing time - split among computers by chromosomes ?
if ( $makeout ) {

  my $featwriter= $sequtil->getFeatureWriter();
    
  $seqfiles= $sequtil->getChromosomeFiles() unless($seqfiles);
  $chrfeats= $sequtil->sortNSplitByChromosome( $feattables) unless($chrfeats); 

  ## need to fix fasta featureset production 
  my $result= $featwriter->makeFiles( 
    infiles => [ @$seqfiles, @$chrfeats ], # required
    formats => [qw(fff gff fasta)] , # optional
    );
    
}

