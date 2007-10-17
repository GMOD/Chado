#!/usr/bin/perl

=head1 NAME

  bulkfiles.pl -- command-line program for Bio::GMOD::Bulkfiles
  
=head1 SYNOPSIS

  This program generates bulk genome annotation files from a Chado genome
  database, including Fasta, GFF, DNA, Blast indices.
  
  # get bulkfiles software
  cvs -d :pserver:anonymous@cvs.sourceforge.net:/cvsroot/gmod \
    co -d GMODTools schema/GMODTools 
  -- OR --
  curl  -O http://eugenes.org/gmod/GMODTools/GMODTools-1.0.zip 
   unzip GMODTools*zip

  # load a genome chado db to Postgres database
  curl -O http://sgdlite.princeton.edu/download/sgdlite/sgdlite.sql.gz
  createdb sgdlite
  (gunzip -c sgdlite.sql.gz | psql -d sgdlite -f - ) >& log.load 

  # extract bulk files from database
  cd GMODTools 
  perl -Ilib bin/bulkfiles.pl -conf sgdbulk -make 

=head1 DETAILED USAGE

  Generate genome bulk files from Chado database.
  Usage: bulkfiles.pl [ -conf sgdbulk -chr chrIII -format fasta -make  ]
  
    -config=bulkfile-config 
      A configuration xml-simple file pointing to genome data files,
      e.g., sgdbulk  or  conf/bulkfiles/sgdbulk.xml
      
      See conf/bulkfiles/bulkfiles-template.xml  to create a new database
      release 
      
    -format=gff,fasta    
      repeat for multiple formats [defaults: @defformats]
      
    -chromosome=2L   
      repeat for multiple chromosomes: -chr=2 -chr=3 -chr=X   
      All chromosomes are processed by default.
      
    -dnadump  
      extract chromosome dna from database [default $dnadump]
      
    -featdump  
      extract features from database [default $featdump]
      intermediate step option:
        -[no]splitfeat = split by chromosome [default with -featdump] )
        
    -failonerror  
      die if error is encountered (otherwise read log to see it)
      
    -make  
      make output bulk files [default $makeout]
      
    -showconfig
      prints the parsed configuration file(s); pay attention
        to ROOT= for location of output (set by \$GMOD_ROOT)
        
    -help
      more info
    -debug  
      turn on debug output for progress info [$debug]
  
=head1 REQUIREMENTS

Mimimal additional software is required. It is assumed you
have installed a Chado database (as in synopsis).  This
sofware requires perl DBI for database access, and XML::Simple
for configurations, and a few bits of BioPerl,
all part of GMOD database installation.

=head1 CONFIGURATION

The operation of this program is controlled by several
configuration files (in simple xml format), including database location, 
feature construction and data-release information.  
The defaults for these are in GMODTools/conf/bulkfiles/.  These can be
tuned for specific data sets, releases.  You can override these
with a conf/ folder containing updated versions, and use the
primary -conf=my-bulkfile.xml to point to alternate configurations.

The concept of data-release set is important here.  If you use
a Chado database release  for which there is a configuration
set, you should get the same outputs as provided by the originators.
With a new database, or new release, you may need to go thru rounds
of tuning the configurations, and possibly software, to specifics
of the data-release.  As genome databases mature, they can get more
complex.  E.g. a new FlyBase D.pseudoobscura release added complexity
to the 'chromosome/superscaffold' structure, necessitating editing
of this basic aspect data configurations and outputs.

Configurations include the SQL statements used for extracting
table files, as the primary functions of these need to be tuned
for specific Chado data sets (conf/bulkfiles/chadofeatsql.xml).  
There are additional configurations for each type of output bulkfile
in 'filesets.xml' with options for those operations.  Operations for
converting and renaming features (e.g. change non-SO names to Sequence Ontology
compliant names for GFF, regular expressions for converting unweildy
database names, values to publicly usable content) are in
'chadofeatconv.xml', along with 'featuresets.xml'.   Each bulkfile
module can have a module.xml for further instructions.

=head1 NOTES

Much of the operation of this program has been dictated by practical
needs to create usable public data releases from FlyBase Chado databases
starting in year 2004.  There remain aspects of the package internal
software that warrants improvement and extention to additional cases.
If there were such a thing as a 'perfect' genome database, much of this
tool would not be needed, as it basically dumps tables and adds some
reformatting for standard output file formats.  But along the way it
also has necessarily added options to correct what is in the database to
meet criteria for public data consumption.

-dnadump and -featdump are prerequisites, but you need run only once.
These create intermediate output files used in make steps.  
featdump = extract feature table files, first in feature-groups
then join and split by chromosome/scaffold.
dnadump = extract chromosome/scaffold raw dna files.

The first stage of -featdump will extract a table
of chromosomes or your ${golden_path} feature.
If this fails to work right, the other steps will fail.
With a new genome dataset, test this first.  Read the
{release_path}/tmp/featdump/chromosomes.tsv to see if correct.
Hand-edit if need be; this file will be used as provided.
Format of the tmp/featdump/tables.tsv is tab-separated columns:

  ($arm,$fmin,$fmax,$strand,$orgid,$type,$name,$id,$oid,$attr_type,$attribute)
  chrI    1       230208  0       10      chromosome      chrI    chrI    212     species Saccharomyces_cerevisiae
  chrII   1       813178  0       10      chromosome      chrII   chrII   507     species Saccharomyces_cerevisiae
  

-format 'fff' is an intermediate flat-feature-format, required for making 
fasta and additional formats.  FFF and GFF are produced together
by one module reading the intermediate feature tables.
Making FFF and GFF are the time consuming steps and may be split
by chromosome across processors.  Processing time may be hours for
complex databases.

New output formats are added by subclassing the
Bio::GMOD::Bulkfiles::BulkWriter module, which basically
takes tabular inputs from the intermediary SQL output and
does something with it.  

=head1 AUTHOR

  D.G. Gilbert, 2004, gilbertd@indiana.edu

=cut

BEGIN{
 unless($ENV{GMOD_ROOT}){
   require Bio::GMOD::Config2; 
   my $root= Bio::GMOD::Config2->new()->gmod_root();
   warn "* Setting GMOD_ROOT=$root\n";
   $ENV{GMOD_ROOT}=$root;
   }
}

use Bio::GMOD::Bulkfiles;    
use Getopt::Long;    

my ($dnadump,$featdump,$makeout,$failonerror,$debug,$verbose,$showconfig)
  = (0) x 10;
my $splitfeat=-1;  
my $no_csomesplit=0;
my $automake=1;  # make this easier for general user
my $config= undef;   
my @formats= ();

#? let release.xml formats replace this? yes! but want for display?
## want $sequtil->config->{outformats} but dont want to call before help
my @defformats= (); #was# qw(overview fff gff fasta tables blast ); 

my @chr=();
my $help=0;

my $ok= Getopt::Long::GetOptions( 
'config=s' => \$config,
'formats=s' => \@formats,  
'chromosome=s' => \@chr,
'automake!' => \$automake,
'dnadump!' => \$dnadump,
'featdump!' => \$featdump, 
'splitfeat!' => \$splitfeat,  
'failonerror!' => \$failonerror,
'makeout!' => \$makeout,
'debug!' => \$debug,
'verbose!' => \$verbose,
'help!' => \$help,
'bugger=s' => \$debug, # more debug levels
'showconfig!' => \$showconfig,
);

my $usage=<<"USAGE";
Generate genome bulk files from Chado database.
Usage: $0  -conf sgdbulk -make [ -format gff,fasta ... ]
Options:
  -help            : show helpful documents
  -config=bulkfile-config    
    Configuration file for genome data release  [required, no default]
  -format=gff,fasta,blast,tables,overview,go_association
    output formats [default from your config.xml or site_defaults.xml ]
  -chromosome=2L      
    chromosome(s) to work with: -chr=3,4,5 [default: all chromosomes]
  -[no]make        : make output bulk files [default $makeout]
  -[no]failonerror : die if error is encountered (otherwise read log to see it)
  -[no]verbose     : turn on verbose output info [$verbose]
  -[no]debug       : turn on debug output for progress info [$debug]

MORE INFO:
  perldoc $0
  perldoc Bio::GMOD::Bulkfiles

USAGE

=item more usage

  -[no]automake  
    auto-make required preliminary data [default $automake]
  -[no]dnadump  
    extract chromosome dna from database [intermediate step; default $dnadump]
  -[no]featdump  
    extract features from database [intermediate step; default $featdump]
     -splitfeat = collate primary table files, sortin and splitting  by chromosome 
     -nosplitfeat = do not create any intermediate per-chromosome/scaffold files
  -[no]showconfig
    print the parsed configuration file(s); pay attention
      to ROOT= for location of output (set by \$GMOD_ROOT)
  
=cut

# 0710 update: change nosplitfeat to mean same as new no_csomesplit flag
#  meaning no per golden_path files (e.g. for genomes with 1000s - 100,000s of scaffolds)
if($splitfeat == 0) { $no_csomesplit=1; }
elsif ($splitfeat == -1) { $splitfeat= $featdump; }

@chr = split(/[,;:\s]/,join(',',@chr));
@formats = split(/[,;:\s]/,join(',',@formats));
@formats= @defformats unless(@formats);

if($help) {
  warn $usage;
  $config= "bulkfiles_template";#? unless($config);
  $verbose=1;
  $makeout= $automake= 0;
  $dnadump= $featdump= $splitfeat=0;
  @formats=();
}

warn "** Please specify -config=config-name\n" unless($config);
die $usage unless ($ok && $config);

my $result= 'none';

my $sequtil= Bio::GMOD::Bulkfiles->new( configfile => $config, 
  debug => $debug, showconfig => $showconfig,
  failonerror => $failonerror,
  verbose => $verbose,
  automake => $automake,
  no_csomesplit => $no_csomesplit,
  );

# automake will do these now if need be.
$sequtil->dumpFeatures() if ($featdump); 
$sequtil->sortNSplitByChromosome() if ($splitfeat); 
$sequtil->dumpChromosomeBases() if ($dnadump);

$result= $sequtil->makeFiles( formats => \@formats, chromosomes => \@chr ) 
  if ( $makeout );
    
print STDERR "Bulkfiles done. result=",$result,"\n";   



