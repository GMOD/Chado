#!/usr/bin/perl

=head1 NAME

  bulkfiles.pl --  command-line program to Bio::GMOD::Bulkfiles
  
=head1 SYNOPSIS

  perl bulkfiles.pl --help  for command details
  
  This generates bulk genome annotation files from a Chado genome
  database, including Fasta, GFF, DNA, Blast indices, as found at 
    ftp://flybase.net/genomes/Drosophila_melanogaster/ ..
    (and other species soon)
  
  Most all of the database and data-release information, including
  what features to extract, how to make files, is in xml configuration
  files (see GMODTools/conf/bulkfiles/)
  See perldoc Bio::GMOD::Bulkfiles for more information.
  
=head1 Quick Start

  # get soft
  cvs -d :pserver:anonymous@cvs.sourceforge.net:/cvsroot/gmod co -d GMODTools schema/GMODTools 

  # load a genome chado db to Postgres
  wget http://http://sgdlite.princeton.edu/download/sgdlite/2004_05_19_sgdlite.sql.gz
  createdb sgdlite_20040519
  (zcat *sgdlite.sql.gz | psql -d sgdlite_20040519 -f - ) >& log.load 

  env GMOD_ROOT=$PWD/GMODTools perl ./bin/bulkfiles.pl -help
  env GMOD_ROOT=$PWD/GMODTools perl ./bin/bulkfiles.pl \
    -conf sgdbulk1 -dna -feat -make -debug

=head1 AUTHOR

  D.G. Gilbert, 2004, gilbertd@indiana.edu

=cut

use Bio::GMOD::Bulkfiles;    
use Getopt::Long;    

my ($dnadump,$featdump,$makeout,$failonerror,$debug,$showconfig)
  = (0) x 10;
  
my $config= undef;  ## 'sgdbulk1' or 'fbbulk-r4', # 'fbbulk-r3h', # 'fbbulk-dpse1'
my @formats= ();
my @defformats= qw(fff gff fasta blast gnomap);
my @chr=();

my $ok= Getopt::Long::GetOptions( 
'config=s' => \$config,
'formats=s' => \@formats,  
'chromosome=s' => \@chr,
'dnadump!' => \$dnadump,
'featdump!' => \$featdump,
'failonerror!' => \$failonerror,
'makeout!' => \$makeout,
'debug!' => \$debug,
'showconfig!' => \$showconfig,
);

die <<"USAGE" unless ($ok && $config);
Generate genome bulk files from Chado database.
Usage: $0 [ -conf fbbulk-r4 -chr X -format fff -make -nodna -nofeatdump ]
  -config=bulkfile-config 
    A Bio::GMOD::Bulkfiles config file pointing to genome data files,
    e.g., sgdbulk1, conf/bulkfiles/fbbulk-r4
  -format=fff    
    repeat for multiple; [defaults: @defformats]
  -chromosome=2L   
    repeat for multiple: -chr=2 -chr=3 -chr=X   
    All chromosomes are processed unless specified.
  -dnadump  
    extract chromosome dna from database [default $dnadump]
  -featdump  
    extract features from database [default $featdump]
  -failonerror  
    die if error is encountered (otherwise read log to see it)
  -make  
    make output bulk files [default $makeout]
  -showconfig
    prints the parsed configuration file(s); pay attention
      to ROOT= for location of output (set by \$GMOD_ROOT)
  -debug  
    turn on debug output for progress info [$debug]
    
NOTES: 
 -dnadump and -featdump are prerequisites, but you need run only once 
   ( ~1 hr for all drosophila m. genome )
 -format 'fff' is required for making fasta, blast, gnomap formats
   making fff and gff are the time consuming steps and may be split
   by chromosome across processors ( ~3 hr / chr for drosophila)
USAGE

  
@formats= @defformats unless(@formats);
my ($feattables,$dnafiles,$chrfeats,$fafiles);

my $sequtil= Bio::GMOD::Bulkfiles->new( configfile => $config, 
  debug => $debug, showconfig => $showconfig,
  failonerror => $failonerror,
  );

if ($featdump) { 
  $feattables = $sequtil->dumpFeatures(); 
  $chrfeats= $sequtil->sortNSplitByChromosome( $feattables) ; 
  }
if ($dnadump) { $dnafiles = $sequtil->dumpChromosomeBases(); }

# this part takes processing time - split among computers by chromosomes ?
if ( $makeout ) {
  my $result= $sequtil->makeFiles(  
    formats => \@formats, chromosomes => \@chr );
    
  print STDERR "done make. result=",$result,"\n" if $result;  
}


