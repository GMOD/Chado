package Bio::GMOD::Bulkfiles;
use strict;

=head1 NAME

  Bio::GMOD::Bulkfiles -- produce bulk sequence and feature files
    from Chado genome database for public distribution .
  
=head1 ABOUT Bulkfiles

  This generates Fasta, GFF, DNA and other bulk genome annotation files at
    ftp://flybase.net/genomes/Drosophila_melanogaster/current/ ..
    (and other species)
  It works with several FlyBase chado dbs, and with SGDLite chado db

  Bulkfiles is mostly self-contained, but uses a few
  BioPerl parts plus XML::Simple for configuration files.  All of
  the organism/database-specific logic should be in these configuration
  files (see GMODTools/conf/bulkfiles/)
    fbbulk-r4.xml, sgdbulk1.xml .. -- organism/database/release specific options
    chadofeatsql.xml  --  chado db sql calls to dump features
    chadofeatconv.xml --  feature conversion options

  
=head1 INPUTS

  Chado genome databases available (aug 2004) are
  ftp://flybase.net/genomes/Drosophila_melanogaster/current/pgsql/chado_r3_2_26_s.gz
  http://sgdlite.princeton.edu/download/sgdlite/2004_05_19_sgdlite.sql.gz

  Given a postgres db installation, load dump file with
     createdb sgdlite_20040519
     (zcat 2004_05_19_sgdlite.sql.gz | psql -d sgdlite_20040519 -f - ) >& log.load &

=head1 OUTPUTS
  
  DNA files (full chromosomes) in raw and fasta formats
  GFF (v3) feature files
  FFF (v1) feature files (used in FlyBase, each complex feature one line
     using GenBank/EMBL locations)
  Fasta sequence for each selected feature set,
     with headers from feature files
  BLAST Index files (NCBI)
  Chado database overview tables. 
  A standard genome webpage for access to bulk data.
  
  
=head1 REQUIREMENTS and INSTALLATION

  Uses a few GMOD, BioPerl, other Perl5 modules, including
    Bio::GMOD::Config.pm (and included Config2.pm)
    XML::Simple

  Program looks for conf/ folder with  .xml files.
  You likely only need to edit fbbulk-r4.xml equivalent.
  
=head1 USAGE

  # see bin/bulkfiles.pl 
  use Bio::GMOD::Bulkfiles;    

  my $bulkfiles= Bio::GMOD::Bulkfiles->new( 
    configfile => 'fbbulk-r4',   # data-release config file, required param
    debug => 1, showconfig => 0,
    failonerror => 1,
    );
  
  $bulkfiles->dumpFeatures(); # extract feature tables from chado sql db
  $bulkfiles->sortNSplitByChromosome(); # collate and separate by chromosome
  $bulkfiles->dumpChromosomeBases();    # extract chromosome dna files
  
     # produce various output format bulk files from above
  my $result= $bulkfiles->makeFiles(
        formats => [qw(fff gff fasta blast gnomap)], 
        chromosomes => [qw(all)] );
      
  print STDERR "Bulkfiles done. result=",$result,"\n";   
    
    
=head1 WHY Bulkfiles? 

  (rather than using other middleware layers to chado db - chadoxml,
   chadodbi, bioperl, ...)
   
  The general logic is
  
    1. dump all chado db features using simple (and quick) sql,
       to common intermediate table files, and chromosome dna to raw files.
       The feature info is simple: type, location, name/id, and a few
       attributes (db_xrefs,..)
       
    2. postprocess these table files to create the various public use
       formats (the time-consuming and configurable part), organized
       into per-chromosome files.
    
  Here are some reasons we take this approach:
  
    a. using simple sql to dump all db features to intermediate table
       allows easy checks that all features get to bulk files
       
    b. simple sql dump is fast (30 - 60 min for full fly genome), 
       reliable in getting all mapped features by keeping logic simple
       
    c. process table output in stages - better debugging of steps in
        process, and can split processing among computers
       c1. the stages are loosely coupled - one can go back, tweek
        configurations and get a new output w/o redoing the complete
        extraction process.
        
    d. convert one common feature table + dna to several output formats
       in one step, or repeatedly as needed.
    
    e. combine features from several chado dbs (flybase now has 3 chado dbs
       for d.mel genome features), and add other sources like
       flybase cytology features.
       
    f. need fairly complex and data specific configurations - moving
      that to config files keeps code reusable.

    g. each genome chado database has different policy and choices with
      respect to feature, vocabulary and other data.  A highly configurable
      tool, with data extraction and correction methods that are separate
      and tunable is needed to adapt to such variation in genome databases.
      

=head1 CONFIGURATION

  These are essential parts to change for a specific
  database release.  See e.g., conf/sgdbulk1.xml.
  
  <opt
    name="sgdbulk1" -- any name
    rel="sgdr1"     -- data release short name
    relfull="sgdlite_20040519"  -- data release long name/folder name
    relid="1"       -- local release id
    date="20040519" -- release date
    ROOT="${ARGOS_ROOT}/flybase/"   -- path to root database folder
             where '${ARGOS_ROOT}' is any ENVIRON variable or fixed path
             (could be ${GMOD_ROOT})
             
    TMP="${ARGOS_ROOT}/flybase/tmp"  -- locate temp folder
    datadir="genomes/Saccharomyces_cerevisiae"   -- subfolder for data releases
    >
    
  -- include config files allow many of these options
     can be packaged separately for reuse among main release configs.
     E.g. conf/bulkfiles/fbreleases.xml contains release name, date, databse access
     and identified by relid value
     
  <title>SGD Chado DB Lite r1</title>  -- your release title

    -- various releases and their chado db name
  <release id="1" value="sgdr1"  db="sgdlite_20040519" date="20040519"/>
  <release id="0" value="sgdr0"  db="sgdlite" date="20040000"/>

    -- database connection information (release.db overrides this db.name)
  <db
    driver="Pg"
    name="sgdlite_20040519"
    host="localhost"
    port="7302"
    user="flybase"
    password=""
    />

    -- organism info
  <org>scer</org>
  <species>Saccharomyces cerevisiae</species>
  
    -- configure chado feature sql dump information
  <featdump
    path="tmp/featdump/\w+.tsv" -- where to put temp dump files
    config="chadofeatsql"   -- config file with sql
    tag="feature_sql"       -- sql elements in file
    type="feature_table"    -- element type
    splitname="chadofeat"   
    >
    <target>chromosomes</target>  -- which sql elements to use
    <target>features</target>
    <target>matches</target> 
    <target>analysis</target> 
  </featdump>

    -- configure chado dna/residue sql dump information
  <dnadump
    path="dna/dna-\w+.raw"
    sql="select feature_id, residues from feature where uniquename = ?"
    />

    -- config. for output files; see conf/bulkfiles/filesets.xml
  <fileset name="fff" path="fff/.+\.fff" ... />
  <fileset name="gff" path="gff/.+\.gff" .../>
  <fileset
    name="fasta"           -- name of output format type
    path="fasta/.+\.fasta" -- subdirectory with files
    title="Genome feature sequence fasta" 
    input="fff"            -- input data selector
    config="tofasta"       -- xml configurations for handler
    handler="FastaWriter"  -- perl module that creates output
    dropnotes="synonym_2nd,synonym" -- other module options here ..
    makeall="1"
    perchr="1"
    dogzip="0"
    />
  <fileset name="blast" path="blast/.+\.*" input="fasta".../>    
  
  
    -- feature sets to make fasta bulk files 
    -- see conf/bulkfiles/featuresets.xml
  <featset>gene</featset>
  <featset>mRNA</featset>
  
    -- more fasta dump information
  <featmap
    name="translation"
    types="CDS"
    typelabel="protein"
    fromdb="1"
    />

  </opt>
 
MORE CONFIG FILES: 

    chadofeatsql.xml  --  chado db sql calls to dump features
       sql for various feature classes, including
       chromosomes, gene model, matches, analysis,
       synteny, with some helper sql views and postprocessing 
       scripts.
        
    chadofeatconv.xml --  feature conversion options
        this is mostly about how to process specific features
        (all SO terms).  Tied into Bulkfiles::FeatureWriter code.
   
   
=head1 NOTES

  genomic sequence file utilities, part2;
  parts converted from 
    flybase/work.local/chado_r3_2_26/soft/chado2flat2.pl
    flybase/work.local/chado_r3_2_26/soft/chadosql2flatfeat.pl

  Find source here 
  set cvsd=':pserver:anonymous@cvs.sourceforge.net:/cvsroot/gmod'
  cvs -d $cvsd login
  cvs -d $cvsd co schema/GMODTools

  Backup CVS: set cvsd=':pserver:anonymous@eugenes.org:/bio/cvs'
  cvs -d $cvsd co -d GMODTools gmod/schema/GMODTools
  
=head1 QUICK TEST (Postgres active):

  # get soft
  cvs -d $cvsd co -d GMODTools schema/GMODTools 
  
  # load a genome chado db to Postgres
  wget http://http://sgdlite.princeton.edu/download/sgdlite/2004_05_19_sgdlite.sql.gz
  createdb sgdlite_20040519
  (zcat *sgdlite.sql.gz | psql -d sgdlite_20040519 -f - ) >& log.load 
  
  # set GMOD_ROOT  to here and run default config 
  cd GMODTools
  env GMOD_ROOT=$PWD perl -I./lib/ bin/bulkfiles.pl sgdbulk1
  
=head1 no_csomesplit update 

  this change is needed to handle partially assembled genomes (the common
  first draft) with many scaffolds (10,000s of < 1MB  to  100,000s of
    < 100Kb segments)

  The old state assumes a handful of full or nearly full chromosomes implicitly
  by producing 1 file/golden_path segment, at least as temporary working
  files. This is a problem for any file system, where > 1,000 files/folder
  is problematic and > 100,000 can be serious.  THis isnt needful design,
  just how the program grew (for drosophila genome data with 5 golden_path
  segments).

  First try: use "sum" as special chromosome name, "all" is already used
    specially for final output of  public files with all csomes in one file.
    
  Main changes are to these subs here:
    See filesets.xml configuration with flags no_csomesplit, perchr and makeall

   Features:
    sortNSplitByChromosome : produce temporary per-csome feature files (tmp/chadofeat-org-csome)

    getFeatTableFiles : collect temp per-csome feat. files for further processing
      -- this hands data to downstream BulkWriter packages for final file (GFF,..)
        creation. Then the filesets perchr and makeall flags control final file set.

    >> need to revise downstream packs (FeatureWriter, ...) to  not split into
       per-csome files (done before 'makeall' option)
    
    Dna:
    -- possibly revise here to use chado sql calls instead of temp dna files?
    dumpChromosomeBases: create dna string files from chado feature.residues
      see ##  for making Unknown 'bag' chromosomes from parts
          ## $csomeset->{$chr}->{parts}

    getBasesFromFiles: return data from dna string files
     Note use of Bio::GMOD::Bulkfiles::MyLargePrimarySeq for dna files.
    
    >> first try using only chadodb get residues
    failed to create chromosome.fasta (no dna/ files). other fasta looked ok.
    See FastaWriter:processFasta : has special raw2Fasta for csomes.,

    
  
=head1 SEE ALSO

  GMOD::Chado::SeqUtils  -- older sequence in/out/check methods for Chado DB

=head1 AUTHOR

D.G. Gilbert, 2004, gilbertd@indiana.edu

=head1 package methods

# -- initialize
sub new 
sub closeit
sub DESTROY 
sub init 
sub initData 

sub readConfig
sub config 
sub getconfig 

# -- extract data from chado db - move to new package ?
sub dnafile 
sub dumpChromosomeBases 
sub dumpFeatures 
sub sortNSplitByChromosome
sub csomeSplit 

sub getDnaSeq 
sub getBases
sub getFeaturesFromDb 
sub getBasesFromDb 
sub getBasesFromFiles

sub dbiDSN
sub dbiConnect
sub getSeqSql
sub updateSqlViews

sub getChromosomeTable
sub getChromosomes

# -- file/folder management

sub getReleaseDir 
sub getReleaseSubdir 

sub getDumpFiles 
sub getChromosomeFiles
sub getFastaFiles
sub getFeatFiles
sub getFeatTableFiles

sub get_filename
sub split_filename
sub maxrange 
sub _isold  

# -- write files

sub makeFiles
sub writeDocs
sub getWriter('type')

sub splitFFF
sub intergeneFromFFF2

=cut

=head1 METHODS

=cut

#-----------------



#debug# 
use lib("/bio/argos/common/perl/lib", "/bio/argos/common/system-local/perl/lib");
use lib("/Users/gilbertd/bio/dev/gmod/schema/GMODTools/lib/");

use POSIX;
use FileHandle;
use File::Basename;
use File::Spec::Functions qw/ catdir catfile /;
use File::Path; ## mkpath
use File::Temp qw/ tempfile tempdir /;
use FindBin qw( $RealBin); #? eval

use DBI; 

use Bio::Location::Simple;
use Bio::PrimarySeq; # see MyLargePrimarySeq use

use Bio::GMOD::Bulkfiles::BulkWriter;
# see getWriter() - base class BulkWriter, loads any other subclasses

use Bio::GMOD::Bulkfiles::MyLargePrimarySeq;
use Bio::GMOD::Bulkfiles::MySplitLocation;
# see below require Bio::GMOD::Config2; dont use

our $DEBUG = 0;
my $VERSION = "1.1"; # no_csomesplit update

use vars qw/ @ENV_KEYS @featset @allfeats %mapchr_pattern $fndel /;

# special config keys to put in ENV for Config2 reader
# 0710: add more: ENV_default set : golden_path seq_ontology
# too many rel.variables: relid , release_id == rel ??
BEGIN{@ENV_KEYS=  qw( species org date title datadir 
    rel relfull relid release_url release_id release_date 
    ftp_url golden_path seq_ontology );}

my $defaultconfigfile="bulkfiles"; # was 'sequtil'  
my %dnaseqs=(); #? package global - read only BioseqFile
my @defaultformats= qw(overview fff gff fasta tables blast ); # gnomap
 

sub new 
{
	my $that= shift;
	my $class= ref($that) || $that;
	my %fields = @_;   
	my $self = \%fields; # config should be one
	bless $self, $class;
	$self->init();
	return $self;
}

sub closeit
{
  my ($self)= @_;
  my $dbh= delete $self->{dbh};
  if ($dbh) { $dbh->disconnect();  }
}

sub DESTROY 
{
  my $self = shift;
  $self->closeit();
}

sub init 
{
	my $self= shift;
	# $self->{tag}= 'Bulkfiles' unless (exists $self->{tag} );
	## $self->{outh}= *STDOUT unless ( exists $self->{outh} ); ## DROP THIS ??
	
	$DEBUG= $self->{debug} if defined $self->{debug};

  $self->{failonerror}= 0 unless defined $self->{failonerror};
  $self->{skiponerror}= 1 unless defined $self->{skiponerror};
  $self->{ignoredbresidues}= 0 unless defined $self->{ignoredbresidues};
  $self->{addids}= 0 unless defined $self->{addids};
  $self->{date}= POSIX::strftime("%F %T", localtime( $^T ));
  $self->{config}={} unless defined $self->{config};
  $self->{configfile}= $defaultconfigfile unless defined $self->{configfile};
  $self->{verbose}=0 unless defined $self->{verbose};
  # no_csomesplit is now a call option, but respect only if >0, replacing config value
  
  $self->readConfig($self->{configfile});
  # calls initData()
}


=item readConfig($configfile)

  read a configuration file - adds to any loaded configs
  -- changed location to conf/bulkfiles/ -- read all of these (no)
  but need to locate subdir 
 
=cut

sub readConfig
{
	my $self= shift;
	$self->{config}= $self->callReadConfig(@_);
  $self->initData(); 
}

# dont dupl this elsewhere e.g. BulkWriter.pm subs
sub callReadConfig
{
	my $self= shift;
	my ($configfile)= @_;
  my $returnConfig= {};
  my $replacevariables= $DEBUG; #?? make default, then drop rereadConfig
  
  eval {  
    my $config2= $self->{config2}; # Config2 object, not hash
    unless(ref $config2) { 
      require Bio::GMOD::Config2; 
      $self->{config2}= $config2= Bio::GMOD::Config2->new( {
        searchpath => [ 'GMODTools/conf/bulkfiles', 'conf/bulkfiles', 'conf', ],
        debug => $DEBUG,
        read_includes => 1, # process include = 'conf.file'
        } ); 
      }

    my @showtags= ($self->{verbose}) ? qw(name title date about) : qw(title date);
    $config2->setargs( showtags => \@showtags );

    # $self->{config}= 
    $returnConfig= $config2->readConfig( $configfile, {}, {}); ## need empty hashrefs!

    ## added processing of include="include.conf"  
    unless ($config2->readConfigOk()) {
      warn "** Error with configuration files\n";
      die if($self->{failonerror} || $self->{automake});
      }

    if($replacevariables) { # 0710 update      
      my @keys= @ENV_KEYS;
      # also inspect config for simple keys
      foreach my $k (keys %$returnConfig) {
        my $v= $$returnConfig{$k};
        push(@keys, $k) unless(ref($v));
        }
      foreach my $k (@keys) { 
        my $v= $$returnConfig{$k};
        $ENV{$k}= $v if(defined $v and not defined $ENV{$k}); 
        } 
      print STDERR "readConfig:pass2 for variables=@keys\n" if $DEBUG;

      # readConfig replace=>1 is bad, replaces 1st/primary values with backup values :(
      # new updateVariables will touch only ${variable} set
      # recurses thru all of config  hash to find '${variable}' matching %ENV keys
      
      $returnConfig= $self->{config2}->updateVariables( 
        $returnConfig,  { Variables => \%ENV, replace =>1 },
        ); 
    
      }
    
    print STDERR $config2->showConfig( $returnConfig, { debug => $DEBUG }) 
      if ($self->{showconfig});  
    }; 
    
  if ($@) { 
    my $cf= $self->{config2}->{filename}; 
    warn "Config2: file=$cf; err: $@"; 
    die if ($self->{failonerror} || $self->{automake});
    }
    
  return $returnConfig;  
}


sub rereadConfig
{
	my $self= shift;
  print STDERR "rereadConfig\n" if $DEBUG;
	
  my $config= $self->config;
  foreach my $k (@ENV_KEYS) { defined $$config{$k} and $ENV{$k}= $$config{$k}; }

  my $newconfig= {};
  eval {  
  
    ## need to replace ${variables} with config values
    ## so need to change $self->{config} hash, not newconfig
    ## still need rereadConfig after  above updateVariables, as init() changes config
    ## but could use a 2nd updateVariables here instead ??

    $self->{config2}->updateVariables( $config,  
                { Variables => \%ENV, replace =>1 },  ); 

#     $newconfig= $self->{config2}->readConfig( $self->{configfile}, 
#                 { Variables => \%ENV }, $newconfig, ); 
#     $self->config->{doc} = $newconfig->{doc} if $newconfig->{doc};

    }; 
  if ($@) { 
    my $cf= $self->{config2}->{filename}; 
    warn "Config2: file=$cf; err: $@"; 
    }
  # print STDERR "new.doc.content=",$newconfig->{doc}->{content},"\n" if $DEBUG;
}

sub updateConfigVars
{
	my $self= shift;
  my $config= $self->config;
  foreach my $k (@ENV_KEYS) { defined $$config{$k} and $ENV{$k}= $$config{$k}; }
  eval { $self->{config2}->updateVariables( $config, { Variables => \%ENV, replace =>1 },  ); }; 
  if ($@) {  warn "Config2: file=",$self->{config2}->{filename},"; err: $@";  }
}


sub config  { return shift->{config}; }

sub getconfig 
{
	my $self= shift;
  my $cf= $self->{config2}; 
  if ($cf && @_) { return $cf->get(@_); } 
}


=item get_filename
  
  $fname= get_filename($org, $chr, $featn, $rel, $format)
  make standard output file name "${org}_${chr}_${featn}_${rel}.${format}"
  See split_filename; need to parse above out of file name, but
    chr, featn, rel can have '_'.  Use '-' instead and disallow in parts?
    Use '.'?
    
=cut

sub get_filename
{
	my $self= shift;
  my( $org, $chr, $featn, $rel, $format)= @_;
  unless ( $org ) { $org="noname"; }
  if ( $chr ) { $chr="$fndel${chr}"; } else { $chr=''; }
  if ( $featn ) { $featn="$fndel${featn}"; } else { $featn=''; }
  if ( $rel ) { $rel="$fndel${rel}"; } else { $rel=''; }
  unless ( $format ) { $format="txt"; }
  my $filename="${org}${chr}${featn}${rel}.${format}";
  return $filename;
}

=item split_filename

  ( $org, $chr, $featn, $rel, $format)= split_filename($filename)
  parse standard output file name "${org}-${chr}-${featn}-${rel}.${format}"
  
  THIS IS problematic - both featn and rel can have _, need other split method
  now chr can have _: dpse_4_group2_transposable_element_rel_2_1..
  BAD NEWS: dpse 4_group5; XR_group3; ... underscore wont do it  

  $fndel=".";
  dpse.4_group2.transposable_element.rel_2.1.fasta
  $fndel="-";
  dpse-4_group2-transposable_element-rel_2.1.fasta
  $fndel="=";
  dpse=4_group2=transposable_element=rel_2.1.fasta
  $fndel="--";
  dpse--4_group2--transposable_element--rel_2.1.fasta
  $fndel="#";
  dpse#4_group2#transposable_element#rel_2.1.fasta

=cut

sub split_filename
{
	my $self= shift;
	my ($fname,$no_orgchr)= @_;
	
  my( $org, $chr, $featn, $rel, $format, $path, $featORrel, $gz, $xtra);
  if ($fname =~ s/(\.gz)$//) { $gz=$1; }
  ($fname, $path, $format) = File::Basename::fileparse($fname, '\.[^\.]+');
  $format .= $gz if $gz; #??
  
  if($no_orgchr) {
    # only fname, format valid ...
    ($org,$chr,$featn,$rel)= ('')x4;
    $featn= $fname; #???
    $chr="all";
  } else {
  #my $nu= ($fname =~ tr/$fndel/$fndel/);## bad
  my @v= split(/$fndel/, $fname, 4); #! rel can have _; !! chr can have _; feat might have _
  my $nu= scalar(@v); 
  
  if (@v == 4) { ($org,$chr,$featn,$rel)= @v; $nu++ if (index($rel,$fndel)>=0); }
  elsif (@v == 3) { 
    ($org,$chr,$featORrel)= @v; # might also be $feat,$chr,$xxx
    if ($featORrel =~ /\d/) { $rel= $featORrel; $featn=''; } 
    else { $featn= $featORrel; $rel=''; }
    }
  elsif (@v == 2) { ($org,$chr)= @v; $featn= $rel='';} ## might also be ($featn,$chr)
  
  if ($nu > 4 || $nu<3) {
    warn "split_filename : ambiguous parts $org,$chr,$featn,$rel from '$fname'\n";
    }
    
  }
  
  return ( $org, $chr, $featn, $rel, $format);
}


=item dnafile($chr)

 locate file of raw chromosome dna bases
 ?? change naming of dnafile() to same as others  using get_filename
   now: dna-chrIX.fasta,raw
   to : scer_chrIII_dna_sgdr1.fasta,raw
   
=cut

sub dnafile 
{
  my ($self, $chrOrFile)= @_;
  #? search for it .. if ($self->config->{dnafiles}->{path});

  if ($chrOrFile) {
    my $dnafile="";
    if (-e $chrOrFile) { $dnafile= $chrOrFile; }
    else { 
      my $org= $self->config->{org};
      my $rel= $self->config->{rel};
      my $fn= $self->get_filename($org,$chrOrFile,'dna',$rel,'raw');
      # my $fn= "dna-$chrOrFile.raw";
      $dnafile = catfile( $self->{dnadir}, $fn);
      }
    $self->{dnafile}= $dnafile;
    }
  return $self->{dnafile};
}


=item remapArm

-- unordered contigs -- singles (? no feats) and doubles - put into common out files?
-- if so, need to offset start/end to fit into unorderd 'chromosome'
See also FeatureWriter remapName, remapArm ...

=cut

sub remapArm
{
  my ($self,$arm,$fmin,$fmax,$strand,$csomeset)= @_;
  my $savearm= $arm;
  $csomeset= {} unless($csomeset);
  
  if ($csomeset->{'_part2chr'}->{$arm}) {
    $arm= $csomeset->{'_part2chr'}->{$arm};
    }
  else {
  foreach my $mp (sort keys %mapchr_pattern) {
    next if ($mp eq 'null'); # dummy?
    my $from= $mapchr_pattern{$mp}->{from}; next unless($from);
    my $to  = $mapchr_pattern{$mp}->{to};
    #$arm =~ s/$from/$to/g;
    if ($to =~ /\$/) { $arm =~ s/$from/eval($to)/e; }
    else { $arm =~ s/$from/$to/g; }
    }
  }

  ## drop arm if $arm is mapped to ""
  
  ## need to trap $arm not in $csomeset -- errors like Contig_Contig below
  ## which either need to be remapped or otherwise handled.
  ## <mapchr_pattern name="3contig"  from="^Contig\w+" to="ctg1"/>
  
  if (!$csomeset->{$arm}) {
  
    }
    
  elsif ($csomeset->{$arm} && ref($csomeset->{$arm}->{parts})) {
    my $parts= $csomeset->{$arm}->{parts};
  MATCHPART:
    foreach my $p (@$parts) {
      my $nm = $p->{name}; #? or id ?
      if ($nm eq $savearm) { #?? is this ok
        my $b = $p->{start};
        my $e = $p->{length} + $b;
        my $st= $p->{strand};
  
        if ($st < 0) { #($st eq '-')?? do we need to flip all - min,max relative to arm.e ?
          $strand= -$strand;
          ($fmax,$fmin) = ($e - $fmin-1, $e - $fmax-1);
          }
        else {
          $fmin += $b - 1;
          $fmax += $b - 1;
          }
        last MATCHPART;
        }
      }
    }
    
  return($arm,$fmin,$fmax,$strand,$savearm); 
}

=item dumpChromosomeBases

  $sequtil->dumpChromosomeBases( \@chromosomes or $config->chromosomes)
  foreach chr @chromosomes
    write dnafile() getBasesFromDb($chrID)
    >> moved out >>$sequtil->raw2Fasta() if $config->{dofasta}; -- write from db to files
   
  oct04 -- add option to create 'chr-U' from bag of Unknown_* golden_path entries
  in getChromosomeTable.
  ** See FeatureWriter remapArm and precursor work w/ Dpse; need to create
  ordered Uknown chr, joining contigs end-to-end.
  
  oct07 -- need no_csomesplit / no dna files option (for 100,000s of scaffolds cases)
  
=cut

sub dumpChromosomeBases 
{
  my ($self, $chromosomes)= @_;
  #? or chromosome->{}
  my @files=();
  my $csomeset= $self->getChromosomeTable();
  $chromosomes= $self->getChromosomes() unless (ref $chromosomes);
  
  my $no_csomesplit= $self->config->{no_csomesplit} || 0; # FIXME: 0710
  
  #? $chromosomes=["sum"] if($no_csomesplit); # 2007oct; not "all", other special csome name !
  # ^^ can we use one dna.raw file with simple csome byte index instead of many files?
  #    or chado db feature.residues fetch as csome 'file'
  if($no_csomesplit) {
    my $chr="sum"; #? "sum" or "all"
    my $dnafile= $self->dnafile($chr);  #? add $org option
    return [ { path => $dnafile, type => 'dna/raw', name => $chr, chr => $chr, } ];
    }
    
  ##? change naming of dnafile() to same as other files?
  ## using get_filename
  my $saveorg= $self->config->{org};
  
  foreach my $chr (@$chromosomes) {
    next if $chr eq 'all';
    my $spp= $csomeset->{$chr}->{species};  ## FIX $dnafile name for this !
    my $org= $self->speciesAbbrev($spp);
    ## next if($org && $org ne $self->config->{org});
    ## skip if $spp ne $self->config->{species} ? or Rename ; but need spp abbrev
    $self->config->{org}= $org if $org;
    my $dnafile= $self->dnafile($chr);  #? add $org option
    $self->config->{org}= $saveorg;
    
    print STDERR "dumpChromosomeBases $dnafile\n" if $DEBUG;
    if (-e $dnafile) { 
      warn "dumpChromosomeBases: wont overwrite $dnafile"; 
      # die if failonerror ?? optionally clean/rewrite ?
      }

      ##  for making Unknown 'bag' chromosomes from parts
    elsif (ref($csomeset->{$chr}->{parts})) {
      my $parts= $csomeset->{$chr}->{parts};
      my $len= 0; my $np= 0;
      open(DNA,">$dnafile"); 
      foreach my $p (@$parts) {
        my $id= $p->{id};
        my $bases= ($id) ? $self->getBasesFromDb($id,1) : ''; 
        print DNA $bases if ($bases); 
        $len += length($bases); $np++;
        }
      close(DNA); 
      print STDERR " dumped $chr parts=$np, total_length=",$len,"\n" if $DEBUG;
      push(@files, { path => $dnafile, type => 'dna/raw', name => $chr, chr => $chr, });
      }
      
    else {
      my $id= $csomeset->{$chr}->{id} || $chr;
      my $bases= $self->getBasesFromDb($id,1); 
      if ($bases) { 
        open(DNA,">$dnafile"); print DNA $bases;  close(DNA); 
        print STDERR " dumped length=",length($bases),"\n" if $DEBUG;
        push(@files, { path => $dnafile, type => 'dna/raw', name => $chr, chr => $chr, });
        }
      else { 
        warn "dumpChromosomeBases: no bases for $dnafile\n"; 
        die if $self->{failonerror};
        }
      }
      
    }
  return \@files;
}


=item getChromosomeFiles()

return fileset of dna/raw chromosomes 

=cut

sub getChromosomeFiles
{
  my ($self, $chromosomes)= @_;
  $chromosomes= $self->getChromosomes() unless (ref $chromosomes);
  my @files=();
  
  ## FIXME: no_csomesplit
  my $no_csomesplit= $self->config->{no_csomesplit} || 0; # FIXME: 0710
  
  foreach my $chr (@$chromosomes) {
    next if $chr eq 'all';
    my $dnafile= $self->dnafile($chr);  
    if (-e $dnafile) {
      push(@files, { path => $dnafile, type => 'dna/raw',  name => $chr, chr => $chr });
      }
    }
  
  return \@files;
}


=item getDumpFiles($targets)

 return list of feature dump files

=cut

sub getDumpFiles 
{
  my ($self, $targets, $fdump)= @_;

  $fdump= $self->config->{featdump} unless($fdump);
  my @files=();
  my @missing=();
  
  my $seqsql = $self->getSeqSql($fdump->{config},$fdump->{ENV});
    
  my $outpath= $self->getReleaseSubdir( $fdump->{'path'} || catdir( $self->config->{TMP}, "featdump") );
  $fdump->{'path'}= $outpath; # save for reuse

  my $sqltag  =  $fdump->{tag} || "feature_sql";
  my $sqltype =  $fdump->{type};
  unless($targets) { $targets =  $fdump->{target}; } # should be array ?
  unless($targets) { my @tg= sort keys %{$seqsql->{$sqltag}}; $targets= \@tg; }
  unless(ref $targets) { $targets= [ $targets ]; }
  
  foreach my $tgname (@$targets) 
  {
    my $fs= $seqsql->{$sqltag}->{$tgname};
    unless($fs) {  next; }
    my $type= $fs->{type};
    my $sql = $fs->{sql};
    my $outn= $fs->{output} || $tgname.".tsv";
    unless($sql && (!$sqltype || $type =~ m/\b$sqltype\b/)) {
      warn "getDumpFiles skip: $tgname/$type<>$sqltype\n";
      next; } #??

    my $outf= catfile($outpath,$outn);
    if(! -e $outf && -e "$outf.gz") { $outf .=".gz";}
    # changed keys:  name =>  to target => ; file => to name => 
    if (-e $outf) {
      push(@files, { path => $outf, type => $type, target => $tgname, name => $outn, });
      }
    else {
      push(@missing, { path => $outf, type => $type, target => $tgname, name => $outn, });
      }
  }
  
  return (wantarray) ? (\@files,\@missing) : \@files;
}



=item getFastaFiles()

return fileset of available features/fasta

=cut

sub getFastaFiles
{
  my ($self, $chromosomes)= @_;
  my @files=();
  
  $chromosomes= $self->getChromosomes() unless (ref $chromosomes);
  
  #? drop this; moved fasta out of dnadir ..
  foreach my $chr (@$chromosomes) {
    my $dnafile= $self->dnafile($chr);  
    (my $fastafile = $dnafile.".fasta") =~ s/\.raw//;  
    if(! -e $fastafile && -e "$fastafile.gz") { $fastafile .=".gz";}
    if (-e $fastafile) {
      push(@files, { path => $fastafile, type => 'chromosome/fasta',  name => $chr,  chr => $chr});
      }
    }

  my $fset= $self->getFilesetInfo('fasta');
  my $fadir= $self->getReleaseSubdir( $fset->{path} || 'fasta/');
  if (opendir(D, $fadir)) {
    foreach my $fa (grep(/^\w/,readdir(D))) { 
      my ( $org, $chr, $featn, $rel, $format)= $self->split_filename($fa);
      $featn = 'feature' unless($featn);
      next unless( grep {$chr eq $_} @$chromosomes ); #?
      push(@files, 
        { path => "$fadir/$fa", type => "$featn/fasta",  name => $fa, chr => $chr });
      }
    closedir(D);
    }
  return \@files;
}


sub getFeatFiles
{
  my ($self, $chromosomes)= @_;
  my @files=();

  my $fset= $self->getFilesetInfo('fff');
  my $featdir= $self->getReleaseSubdir( $fset->{path} || 'fff/');
  $chromosomes= $self->getChromosomes() unless (ref $chromosomes);

  if (opendir(D, $featdir)) {
    foreach my $fa (grep(/^\w/,readdir(D))) { 
      my ( $org, $chr, $featn, $rel, $format)= $self->split_filename($fa);
      next unless( grep {$chr eq $_} @$chromosomes );  
      $featn ||= 'feature';
      push(@files, 
        { path => "$featdir/$fa", type => "$featn/fff", name => $fa, chr => $chr });
      }
    closedir(D);
    }
  return \@files;
}


sub getFeatTableFiles
{
  my ($self, $chromosomes)= @_;
  my @files=();
  my $fdump= $self->config->{featdump};
  my $outpath= $self->getReleaseSubdir( $fdump->{'path'} || "tmp/") ;
  my $outname= catfile( $outpath, $fdump->{splitname} || "chadofeat");
  
  my $no_csomesplit= $self->config->{no_csomesplit} || 0; # FIXME: 0710

  $chromosomes= $self->getChromosomes() unless (ref $chromosomes); 

  ##my $spp= $csomeset->{$chr}->{species};  ## FIX $dnafile name for this !
  my $spp= $self->config->{species} || $self->config->{org};
  my $orgabbr= $self->speciesAbbrev($spp, "org4");
  print STDERR "# feature_table org=$orgabbr species=$spp path=$outpath \n" if $DEBUG;
  
  $chromosomes=["sum"] if($no_csomesplit); # 2007oct; not "all", other special csome name !
  
  foreach my $chr (@$chromosomes) {
    next if $chr eq 'all';
    my $fn;
    #^^ FIXME for species file name: chadofeat-dmel2L.tsv .. chadofeat-dpseXR_group9.tsv
    # ? add spp to getChromosomes() ?
    $fn= "$outname-$orgabbr$chr.tsv";
    if(! -e $fn && -e "$fn.gz") { $fn .=".gz"; }
    #$fn= "$outname-$chr.tsv" unless( -e $fn);
    
    push(@files, { path => $fn, type => 'feature_table', name => $chr, org => $orgabbr  });
    }
  print STDERR "# feature_table files=",join(",",map{ basename($_->{path})}@files),"\n" if $DEBUG;
  return \@files;
}  



sub getFilesetInfo
{
  my ($self, $type)= @_;

    ## regularize configs so new format can be added w/o special tag names  
  my $fset;
  $fset= $self->config->{fileset_override}->{$type};
  return $fset if (ref $fset);
  $fset= $self->config->{fileset}->{$type};
  return $fset if (ref $fset);
  
  my @oldset= qw( featdump dnafiles featfiles fastafiles blastfiles gnomapfiles gbrowsefiles );
  foreach my $ms (@oldset) {
    my $fset= $self->config->{$ms};
    if (ref $fset && $fset->{type} eq $type) { return $fset; }
    }
  return {};
}


sub getFilesByType
{
  my ($self, $type, $chromosomes)= @_;
  my @files=();
  $chromosomes= $self->getChromosomes() unless (ref $chromosomes);

  ## $type maybe [] arrayref
  my @types= (ref $type) ? @$type : ( $type ) ;
  foreach $type (@types) {
    my $fset= $self->getFilesetInfo($type);
    next unless $fset;
    
    my $path= $fset->{path} || $type;
    my $dir = $self->getReleaseSubdir( $path, 'nocreate' );
    my $no_orgchr= (defined $fset->{no_orgchr}) ? $fset->{no_orgchr} : 0;
  
    if (opendir(D, $dir)) {
      my $filepattern= '\w';
      # ($filepattern, undef) = File::Basename::fileparse($path) if ($path !~ m,/$,);
      # >> err fileparse(): need a valid pathname
      if ($path !~ m,/$,){  
        my $e= rindex($path,'/'); 
        $filepattern= ($e<0) ? $path : substr($path,$e+1); 
        }
      
      foreach my $fa (grep(/^$filepattern/,readdir(D))) { 
        my ( $org, $chr, $featn, $rel, $format);
        ( $org, $chr, $featn, $rel, $format)=$self->split_filename($fa,$no_orgchr);
        next unless( $no_orgchr || grep {$chr eq $_} @$chromosomes );  
        
        $featn ||= 'feature';
        push( @files, 
          { path => "$dir/$fa", type => "$featn/$type", 
            name => $fa, format => $format, 
            chr => $chr, rel => $rel, org => $org,
            no_orgchr => $no_orgchr,
           });
        }
      closedir(D);
      }
    }
    
  return \@files;
}

sub getFiles
{
  my ($self, $type, $chromosomes)= @_;
  my @filesets=();
  ## $type maybe [] arrayref
  my @types= (ref $type) ? @$type : ( $type ) ;
  foreach $type (@types) {
    my $fileset;
    ## old way
    CASE: {
      $type eq 'feature_table' && do { $fileset= $self->getFeatTableFiles($chromosomes); last CASE };
      $type eq 'dna'    && do { $fileset= $self->getChromosomeFiles($chromosomes); last CASE };
      #$type eq 'fff'    && do { $fileset= $self->getFeatFiles($chromosomes);  last CASE };
      #$type eq 'fasta'  && do { $fileset= $self->getFastaFiles($chromosomes); last CASE };

      # new way: 
      $fileset= $self->getFilesByType($type, $chromosomes);
      } 
  
    push(@filesets, @$fileset) if $fileset;
    } 
  
  return \@filesets;
}


sub gzipFiles
{
  my ($self, $formats, $chromosomes)= @_;
  my @formats= ref $formats ? @$formats : qw( fff gff fasta dna gnomap blast) ;
  foreach my $type (@formats) {
    my $finfo= $self->getFilesetInfo($type);
    if (ref $finfo && $finfo->{dogzip}) {
      my $fileset= $self->getFiles($type, $chromosomes);
      print STDERR "gzipping $finfo->{path}\n" if $DEBUG;
      foreach my $fs (@$fileset) {
        system("gzip -f ".$fs->{path}) if (-e $fs->{path} && $fs->{path} !~ /\.gz$/);
        }
      }
    }
}



#=============================================



=item sortNSplitByChromosome($fileset)

 sort chado feature dump fileset  by arm, location
 and split into chromosome file set

=cut

sub sortNSplitByChromosome
{
  my ($self, $fileset)= @_;

  my $sorter=`which sort`; chomp($sorter); ## '/bin/sort'; '/usr/bin/sort';
  ## WATCH OUT - TAB here in '	' ; does shell understand '^I' instead ?
  #DEBUG off#my $sortfeaturescmd= "$sorter -t'	' -k 1,1 -k 2,2n"; #? add -k 3,3rn ; nope end not there
  my $sortfeaturescmd= "$sorter -t'	' -k 1,1 -k 2,2n -k 3,3rn"; 

  $fileset= $self->getDumpFiles() unless(ref $fileset);
  # return undef unless(ref $fileset);
  my $fdump  = $self->config->{featdump};
  my $outpath= $self->getReleaseSubdir( $fdump->{'path'} || "tmp/") ;
  my $outname= catfile( $outpath, $fdump->{splitname} || "chadofeat");
  my $intype = $fdump->{type};

  my $no_csomesplit= $self->config->{no_csomesplit} || 0; # FIXME: 0710

  my $tfset  = $self->getFilesetInfo('tables');
  my $tabdir = $self->getReleaseSubdir( $tfset->{path} || 'tables/');
  my $sumfile= catfile( $tabdir, "feature_table-summary.txt");
  
  ## check first existance of outname files, and age 
  ## if newer than input fileset, leave as is, return file names ?
  my $chromosomes= $self->getChromosomes(); ## $self->config->{chromosomes};
  my $chr= $$chromosomes[0];

  ##FIXME:    my $testout= $outname-$orgabbr.$chr; ## dmel2R, 
  my $orgabbr= $self->config->{org} || $self->speciesAbbrev("","org4"); 

  my $testout= "$outname-$orgabbr$chr.tsv";
  if(! -e $testout && -e "$testout.gz") { $testout .=".gz"; }
  my $uptodate= (-e $testout) ? 1 : 0;
  
  my $scmd="";
  foreach my $fs (@$fileset) {
    my $fp= $fs->{path};
    next unless($fs->{type} eq $intype); #??
    ## if(! -e $fp && -e "$fp.gz") { $fp .=".gz"; } ## fileset will already have .gz if so
    unless(-e $fp) { warn "missing dumpfile $fp"; next; } # die if $self->{failonerror};
    if ($uptodate && _isold($fp, $testout)) { $uptodate= 0 ; }
    $scmd .= "$fp ";
    }
    
  if($uptodate) {
    my @files=();
    foreach my $chr (@$chromosomes) {
      my $fn= "$outname-$orgabbr$chr.tsv"; ## dmel2R, 
      push(@files, { path => $fn, type => 'feature_table', name => $chr, chr => $chr,  });
      }
    return \@files;
    }
  
  unless($scmd) { warn "sortNSplitByChromosome: no dumpfiles at $outpath"; return undef; }
  # die if $self->{failonerror};

  if($scmd =~ /\.gz /){ $scmd= "gunzip -c $scmd"; } else { $scmd= "cat $scmd"; }
  $scmd = "$scmd | $sortfeaturescmd |";  
  print STDERR "sortNSplitByChromosome:\n $scmd\n" if $DEBUG;
  print STDERR "  to csomeSplit($outname)\n" if $DEBUG;
  open(FS,$scmd) || die $scmd;
  my $files= $self->csomeSplit(*FS, $outname, $sumfile, $no_csomesplit);
  close(FS);
  
    ## with remapArm, need to resort each output file
  foreach my $finfo (@$files) { 
    next unless ($finfo->{dosort});
    my $path= $finfo->{path}; 
    my $cmd="cat $path | $sortfeaturescmd > $path.new";
    if (system($cmd) == 0) { rename("$path.new",$path); $finfo->{dosort}= 0; }
    else { my $err= $? >> 8; warn "resort $path failed: $err"; }
    }

  return $files;
}


=item csomeSplit($inh, $outname, $sumfile)

 split sorted input feature_table files into per-chromosome (and now per-organism)
 feature fileset

  2007Oct: add this flag ENV_default: output_by_golden_path=1 instead use: csome_split=1
    to separate output by chromosome/scaffold/..., otherwise lump output by feature types,
    for all csomes.
    -- how much work to implement this? as all downstream outputs are csome-split now.
    
    
=cut

sub csomeSplit 
{
  my($self, $inh, $outname, $sumfile, $no_csomesplit)= @_;
  $outname ||= "chadofeats";
  my @files=();
  my $fh= undef;
  my %fhs=();
  my %csomefeats= ();
  my $lastoid='';
  my $csomeset = $self->getChromosomeTable(); ## pass value
  my $organisms= $self->config->{organism};
  my %fhsorts=();
  
  while(<$inh>) { 
    next unless(/^\w/); 
    chomp();
    my ($arm,$fmin,$fmax,$strand,$orgid,$type,$name,$id,$oid,$attr_type,$attribute)
      = split("\t"); 
    my $oldarm;
    my $oldfmax= $fmax;
    
    # bug 0710: getting 's.cerevisiae' instead of 'scer'; from chado db ??
    my $orgabbr= 
      $organisms->{$orgid}->{org4} ||
      $organisms->{$orgid}->{abbreviation};
    $orgabbr = "org$orgid" unless($orgabbr); #?? skip null orgabbr : not wanted ?
    
    ($arm,$fmin,$fmax,$strand,$oldarm)= $self->remapArm($arm,$fmin,$fmax,$strand,$csomeset); # for Unknown.. and other fragments ? need to do before sorter call
    ## -- BUG: remapArm U isnt sorted; need to check after 1st create files
    ## -- BUG2: renameArm needs to be called other places, change ChromosomeTable
    next unless($arm && $arm ne 'skip'); #?
    
    if ($attr_type eq 'to_species') {
      my $toorg= $self->speciesAbbrev($attribute); ## , "org4"
      ## my $toorg= $organisms->{$attribute}->{abbreviation};
      $attribute= $toorg if $toorg;
      }
      
    my $dosort= ($arm ne $oldarm || $fmax ne $oldfmax);
    
    my $armfile= ($no_csomesplit) ? "sum" : $arm;
    my $fhname= $orgabbr.$armfile; ## dmel2R, 
    
    unless($fhs{$fhname}) {
      my $fn= "$outname-$fhname.tsv";
      $fh= $fhs{$fhname}= new FileHandle(">$fn");
      die "Failed to create csome feature file '$fn'" unless($fh);
      push(@files, { path => $fn, name => $armfile,  chr => $arm, org => $orgabbr, 
        type => 'feature_table', # should be   $fs->{type} == feature_table
        dosort => $dosort,
        });
		  }
		$fhsorts{$fhname} += $dosort;
		
    $fh= $fhs{$fhname};  
    ## drop $orgid from this output set
    print $fh join("\t",$arm,$fmin,$fmax,$strand,$type,$name,$id,$oid,$attr_type,$attribute)
      ,"\n";
    
    unless($oid eq $lastoid) {
      $csomefeats{$fhname}{$type}++; $csomefeats{all}{$type}++; 
      }
    $lastoid= $oid;
    }
    
  foreach my $fhname (keys %fhs) { $fh= $fhs{$fhname}; close($fh) if $fh; }
  foreach my $f (@files) {
    my $fhname= $f->{org} . $f->{chr};
    $f->{dosort}= 1 if ($fhsorts{$fhname});
    }
    
  ## these counts are bad; include dup rows/feature (e.g 4x gene count)
  ## need to use distinct oid .
  if ( $sumfile ) {
    $fh= new FileHandle(">$sumfile");
    my $title = $self->config->{title};
    my $date = $self->config->{date};
    my $org  = $self->config->{species} || $self->config->{org};
    #^^ use $orgid !??
    print $fh "# Database feature summary for $org from $title [$date]\n";
    my @fl= grep { 'all' ne $_ } sort keys %csomefeats;
    foreach my $arm ('all', @fl) {
      print $fh (($arm eq 'all') ? "\n# ALL chromosomes\n" : "\n# Chromosome $arm\n");
      foreach my $t (sort keys %{$csomefeats{$arm}}) {
        print  $fh "$t\t$csomefeats{$arm}{$t}\n";
        }
      print $fh "#","="x50,"\n";
      }  
    close($fh);
    push(@files, { path => $sumfile, type => 'feature/summary',  name => 'summary', });
    }
  
  return \@files;  
}


sub preMake
{
	my $self= shift;
  my ($what)= @_;  
	my $ok= 0;
	my ($dumpfiles,$chrfeats,$dnafiles);
	# parts from bulkfiles.pl not run by default; save user some hassle here
  if ($what =~ /feature_table/ && !$self->{didmake}{feature_table}) { 
    warn "Automaking feature_table files\n"; 
    $dumpfiles= $self->dumpFeatures(); 
    $chrfeats= $self->sortNSplitByChromosome(); 
    $self->{didmake}{feature_table}=1;
    $ok= 1 if(@$chrfeats);
    }
    
  if ($what =~ /dna/ && !$self->{didmake}{dna}) {
    warn "Automaking dna files\n"; 
    $dnafiles= $self->dumpChromosomeBases();
    $self->{didmake}{dna}=1;
    $ok= 1 if(@$dnafiles);
    }
    
  return $ok;
}


sub missingData
{
	my $self= shift;
  my ($fileset, $maketype, $what)= @_; 
  
  if( @$fileset && $self->{automake} ) {
    my @didmake= keys %{$self->{didmake}};
    my $current= grep /$maketype/, @didmake;
    unless($current) {
      (my $msg = $what) =~ s/;.*$//;
      warn "Using pre-existing $msg\n";
      warn "Use '/bin/rm -rf ",$self->getReleaseDir(),"' for clean make\n" 
        if($what =~ /chromosomes/);
      }
    }  
    
  unless(@$fileset){ warn "Missing ",$what,"\n"; die if $self->{failonerror}; }
}

=item  makeFiles( %args )

  primary method; 
    mostly it calls FeatureWriter() package to handle
    also prints any config->doc entries

  arguments: 
  infiles => \@fileset,   # required
  formats => [ 'gff', 'fasta', 'fff', 'blast' ] # optional


=cut


sub makeFiles
{
	my $self= shift;
  my %args= @_;  
  my @results=();

  print STDERR "makeFiles\n" if $DEBUG; # debug

  $self->rereadConfig(); # == updateConfigVars; replace doc ${values}
  
  $self->writeDocs( $self->config->{doc} ); #? unless already wrote ? move this to Writer module
 
  my $automake= $args{automake} || $self->{automake} ;
  
  my @outformats=(); # check config
  if ($args{formats}) {
    my $formats= $args{formats};
    @outformats= (ref $formats) ? @$formats : ($formats);
    }
  else {
    @outformats=  @{ $self->config->{outformats} || \@defaultformats } ; 
    }
  my %outformats= map{ $_,1; } @outformats;
  print STDERR "makeFiles: outformats= @outformats\n" if $DEBUG; 
  
  if (delete $outformats{'overview'}) {
    my $overviewset  = $self->getFilesetInfo('overview');
    if($overviewset) {
      ## check for already done overview files ..
      my ($ovfiles,$ovmissing)= $self->getDumpFiles(['overview'], $overviewset);
      ## FIXME: bug in above x config? 'overview' files are tagged 'summary' in chadofeatsql ??
      if(1 or scalar(@$ovmissing)) { 
        $ovfiles =  $self->dumpFeatures($overviewset, undef, "colnames");  
        }
  
      my $ovlist= join(" ",map {$_->{name}} @$ovfiles);
      push @results, "overviews:$ovlist";
      warn "** Please review overview tables for validity **\noverviews:$ovlist\n" if($automake||$DEBUG); # && return ??
      $self->getOrganismTable() if($ovlist =~ /organism/);
      }
    }
    
  ## 0710: insert here optional validateVariables: seq_ontology, golden_path at least
  ## valid=0 default flag handles this for newuser: $self->config->{newuser}
  $self->validateVariables() unless( $self->config->{valid} );
    
    ## getChromosomes needs chromosomes.tsv .. essential it exist here
  my $fileset= $self->getDumpFiles(['chromosomes']);
  if($automake && ! @$fileset) {
    $self->preMake('feature_table'); # returns $ok
    $fileset= $self->getDumpFiles(['chromosomes']);
    }
  $self->missingData( $fileset, 'feature_table', "chromosomes.tsv table file; make with -featdump");
    
  my $chromosomes= undef;
  if (ref $args{chromosomes}) { $chromosomes= $args{chromosomes}; $args{noall}=1; }
  elsif (ref $args{chr}) { $chromosomes= $args{chr};  $args{noall}=1; }
    ## dont do 'all' if subset !

  unless (ref $chromosomes && @$chromosomes > 0 && $chromosomes->[0] ne 'all') {
    $chromosomes= [ 'all', @{$self->getChromosomes()} ];
    $args{noall}=0;
    }
  
    # FIXME trick - getFeatureWriter loads common config for featmap/featset needed by others
  my $featwriter= $self->getWriter('fff');
  
    ## this one takes a while; split chromosomes among processors
  if ($outformats{'fff'} || $outformats{'gff'}) { ## grep /fff|gff/, @outformats) 
    delete $outformats{'fff'}; delete $outformats{'gff'};
    my $chrfeats = $self->getFiles('feature_table', $chromosomes);
    if ($automake && !@$chrfeats) {
      $self->preMake('feature_table'); # returns $ok
      $chrfeats = $self->getFiles('feature_table', $chromosomes);
      }
    if ($DEBUG) { print STDERR "read feature tables= ",join(" ",map {$_->{name}} @$chrfeats),"\n"; }  
    $self->missingData( $chrfeats, 'feature_table', "feature_table files; make with -featdump");
    push @results, $featwriter->makeFiles( %args, 
               infiles => $chrfeats, chromosomes => $chromosomes );   
    }
    
  my $featfiles = $self->getFiles('fff', $chromosomes);
  my $dnafiles  = $self->getFiles('dna', $chromosomes);
  if ($automake && !@$dnafiles && $outformats{'fasta'}) {
    $self->preMake('dna');
    $dnafiles  = $self->getFiles('dna', $chromosomes);
    }
  if ($automake && !@$featfiles && ($outformats{'fasta'} || $outformats{'gnomap'})) { #(grep /fasta|gnomap/, @outformats))
    $self->preMake('fff'); # not active?
    $dnafiles  = $self->getFiles('fff', $chromosomes);
    }
    
  if ($DEBUG) {
    my @cn= @$chromosomes; print STDERR "make chromosomes= @cn\n";
    my @fn= map {$_->{name}} @$featfiles; print STDERR "with featfiles= @fn\n";
    my @dn= map {$_->{name}} @$dnafiles; print STDERR "with dnafiles= @dn\n";
    }
  
  if (delete $outformats{'fasta'}) {
    $self->missingData( $featfiles, "fff", "fff files; make with -format fff");
    $self->missingData( $dnafiles, "dna", "dna files; make with -dnadump");
    my $writer= $self->getWriter('fasta');
    push @results, $writer->makeFiles(%args, 
      infiles =>  $featfiles, chromosomes => $chromosomes);
    }
    
  if (delete $outformats{'blast'}) {
    my $fafiles = $self->getFiles( 'fasta', $chromosomes);
    $self->missingData( $fafiles,  'fasta', "fasta files; make with -format fasta");
    my $writer  = $self->getWriter('blast'); # this works; eval new writer
    push @results, $writer->makeFiles( %args, 
      infiles =>  $fafiles, chromosomes => $chromosomes );  
    }
    
  if (delete $outformats{'gnomap'}) {
    $self->missingData( $featfiles, "fff","fff files; make with -format fff");
    my $writer= $self->getWriter('gnomap');
    push @results, $writer->makeFiles(%args, 
      infiles => [ @$featfiles, @$dnafiles ], chromosomes => $chromosomes); # needs $featfiles
    }
  
  # my @moreformats= grep !/(fff|gff|dna|fasta|blast|gnomap)/,@outformats;
  my @moreformats= grep { $outformats{$_} } @outformats; # preserve call-order
  foreach my $fmt (@moreformats) {
    my $writer= $self->getWriter($fmt);
    if (!$writer) { warn "no writer for $fmt\n"; }
    else { push @results, $writer->makeFiles( %args, 
            infiles => [ @$featfiles, @$dnafiles ], chromosomes => $chromosomes); 
      }
    }
    
  $self->gzipFiles( \@outformats, $chromosomes );
  
  my $lok= $self->makeCurrentLink() 
    if (@results && $self->config->{make_current});

  #? put most of above in eval{} block so we return error info if failed ??

  push(@results,"\nBulkfiles are located at ".$self->getReleaseDir())
    if(@results);
  return join(", ",@results); #what?
}






=item writeDocs( $docs or $self->config->{doc})

  print docs from config file
  .. move this into own BulkWriter subclass ?
 
  need some fix to writeDocs for doc->path at top level or not-releasedir
  
=cut

sub writeDocs
{
  my ($self, $docs)= @_;
  my $ndoc= 0;
  if (ref $docs) {
    # check for 1 or many (name keys, darn xmlsimple); is tag 'name'  or 'id' ?
    my $reldir = $self->getReleaseDir();
    my $datadir= $self->config->{datadir}; # must exist
    my $species= $self->speciesFull();
    if ($docs->{content}) {
      my %dd= ();
      if ($docs->{name}) { %dd= ( $docs->{name} => $docs ); }
      elsif ($docs->{id}) { %dd= ( $docs->{id} => $docs ); }
      else { %dd= ( 'untitled' => $docs ); }
      $docs= \%dd;
      }
    foreach my $dname (sort keys %$docs) {
      next if ($docs->{$dname}->{hidden}); ##  == 1
      my $data = $docs->{$dname}->{content} || '';
      my $dpath= $docs->{$dname}->{path} || $dname;
      
      $dpath =~ s/\${datadir}/$datadir/; 
      $dpath =~ s/\${species}/$species/; 
      my $norel=($dpath =~ m/$datadir/ || $dpath =~ m,^/,);
      my $fn= ($norel) ? $dpath : catfile( $reldir, $dpath);
      
      print STDERR "write doc $dname $fn\n" if $DEBUG;
      if( open(DOC,">$fn") ) { print DOC $data; close(DOC); $ndoc++; }
      else { warn "ERROR: cant write $fn\n"; }
      }
    }
  print STDERR "writeDocs n=$ndoc\n" if $DEBUG; # debug
  return $ndoc;
}



=item getWriter
  
  Replaced getXxxWriter with generic getWriter('type')
  
=cut


sub getWriter
{
  my ($self, $type)= @_;

  my $finfo= $self->getFilesetInfo($type);
  if (ref $finfo && $finfo->{handler}) {
    my $configfile= $finfo->{config};
    my $pkg= $finfo->{handler};
    if($pkg eq "Bulkfiles") { return $self; } #?? can we do this; needs BulkWriter methods
    
    unless($pkg =~ /\:\:/) { $pkg= "Bio::GMOD::Bulkfiles::".$pkg; }  
    my $eval=
     "use $pkg;
      $pkg->new( configfile => \$configfile, fileinfo => \$finfo, 
        handler => \$self, debug => \$DEBUG,  showconfig => \$self->{showconfig},
        );";
    ##print STDERR "getWriter: eval $eval\n" if $DEBUG;
    my $writer= eval $eval; 
    if ($@) { warn $@; die if($self->{failonerror}); }
    return $writer if ref $writer; 
    }
 
#   print STDERR "getWriter('$type'): eval failed\n" if $DEBUG;
#   ## old way
#   CASE: {
#     $type eq 'fasta'  && return $self->getFastaWriter(); 
#     $type eq 'blast'  && return $self->getBlastWriter(); 
#     $type eq 'fff'    && return $self->getFeatureWriter(); 
#     $type eq 'gff'    && return $self->getFeatureWriter(); 
#     $type eq 'gnomap' && return $self->getGnomapWriter(); 
#     } 
  warn "no writer module for $type\n"; 
}


#===================================================



=item getChromosomeTable

  locate and read feature dump of chromosomes (or equivalent parts)

  2L  1  22217931  0 chromosome_arm  2L  2L      1  species Drosophila_melanogaster
  2R  1  20302755  0 chromosome_arm  2R  2R      2  species Drosophila_melanogaster
  3L  1  23352213  0 chromosome_arm  3L  3L      4  species Drosophila_melanogaster
  3R  1  27890790  0 chromosome_arm  3R  3R      3  species Drosophila_melanogaster
  4   1  1237870   0 chromosome_arm  4   4       5  species Drosophila_melanogaster
  U   1  11561901  0 chromosome_arm  U   U       7  species Drosophila_melanogaster
  X   1  21780003  0 chromosome_arm  X   X       6  species Drosophila_melanogaster

  oct04 -- add option to create 'chr-U' from bag of Unknown_* golden_path entries
  in getChromosomeTable.  Have some 2000+ Unknown_group and Unknown_singleton
  golden_path/ultra_scaffold  entries in Dpse r2.1.

  need also map contig -> contig_contig -> ultra_scaffold 

Contig1083_Contig6433   0       11665   1       3       contig          Contig1083      3209332      parent_oid      3208389:1
Unknown_group3  0       15476   1       3       golden_path_region      Contig1083_Contig6433 Contig1083_Contig6433   3208389 parent_oid      3798908:1
  
  return hash {
          '3R' => {
                    'length' => 27890789,
                    'start' => 1,
                    'oid' => 3,
                    'strand' => '0',
                    'type' => 'chromosome_arm',
                    'name' => '3R'
                  },
          4 => {
                 'length' => 1237869,
                 'start' => 1,
                 'oid' => 5,
                 'strand' => '0',
                 'type' => 'chromosome_arm',
                 'name' => 4
               },
        }
        
=cut

sub getChromosomeTable
{
	my $self= shift;
  my $config= $self->config;
  if (defined $config->{chromosome}) { return $config->{chromosome}; }
  
  my $chromosome= {};
  my $chrparts  = {}; # for dpse map Unknown ultra_scaffold/golden_path_fragment to U
  my $part2chr  = {}; # map golden_path_region name to chr-arm name
  my $chrpartpattern= $config->{chrpart_pattern};
  my %orgset    = ();
  my $nozombiechromosomes= $config->{nozombiechromosomes};
    # dpse chado duplicate 0-length chromosome entries

## need remapArm() here, but csomeset is result of this method ...
## BUT featdump tables are not remapped until csomeSplit(); cant use remapped names til after that
    
    #? allow only one species per make run ?
  my $myspp= $config->{species};  $myspp =~ s/ /_/g;
  my $myorg= $config->{org} || $self->speciesAbbrev($myspp); 
  
  my $fileset= $self->getDumpFiles(['chromosomes']);
  my $path= (ref $fileset) ? $fileset->[0]->{path} : undef;
  if ($path && open(CF,$path)) {
  while(<CF>) {
    next unless(/^\w/);
    next if(/^arm\tfmin/); # header from sql out -- should be 'chromosome' or 'chr' instead of 'arm'
    chomp;
    
    my $oldarm;
    my ($arm,$fmin,$fmax,$strand,$orgid,$type,$name,$id,$oid,$attr_type,$attribute)
      = split("\t");  
    next unless($id); #?
    ## sgdlite uses messy chr ID -- use name instead here ? better: $arm is best of both
    ## fb-dpse has zero-length chromosomes, and duplicates (some zero some not)
    ## ? skip zero len csomes ? for output at least
    
    ## use $strand == rank here -- assume input file is ordered by that.
    
    ## need ($arm,$golden_path,...)= mapChr($arm)
    ## ? need some compound chr{arm} with multiple ids for Unknown bag?
    ($arm,$fmin,$fmax,$strand,$oldarm)= $self->remapArm($arm,$fmin,$fmax,$strand,undef); 
    next unless($arm && $arm ne 'skip'); #?
    
    my $species= ($attr_type eq 'species') ? $attribute : $config->{species};
    $species =~ s/ /_/g;
    my $org= $self->speciesAbbrev($species);
    $org= $self->speciesAbbrev($orgid) unless($org);
    $org= "null" unless($org); 
    next unless($myorg eq $org || $myspp eq $species); #?? dec05; for dpse+dmel db
    next if ($nozombiechromosomes && $fmax <= $fmin);
    my $org4= $self->speciesAbbrev($orgid, "org4");
    
    my $chrvals= {
      arm => $arm,
      oldarm => $oldarm, # rarely differs from arm ...
      name => $name || $id,
      id => $id,
      type => $type,
      start => $fmin,
      length => ($fmax - $fmin + 1),
      strand => $strand,
      oid => $oid,
      species => $species,
      orgid => $orgid, ## NEED THIS, now all feature_table have organism_id
      org => $org,
      };
    
    my($genus,$spp)= split(/_/,$species,2);
    $orgset{$orgid}= { 
      organism_id => $orgid, 
      abbreviation => lc($org), 
      org4 => $org4,
      genus => $genus, 
      species => $spp,
      fullspecies => $species,
      };
      
    if ($chrpartpattern && $type =~ /$chrpartpattern/) { #== golden_path_fragment|golden_path_region, other?
      unless($chrparts->{$arm}) { $chrparts->{$arm}= []; }
      push(@{$chrparts->{$arm}}, $chrvals);
      $part2chr->{$id}= $arm;
      }
    else {
      #? check type =~ <chr_pattern>^(chromosome_arm|golden_path|ultra_scaffold)$</chr_pattern>
      $chromosome->{$arm}= $chrvals;
      }
    }
  close(CF);
  }
  
  $chromosome->{'_part2chr'}= $part2chr if( %$part2chr );
  foreach my $arm (keys %$chrparts) {
    unless($chromosome->{$arm}) {  ## make pseudochr from parts?
      $chromosome->{$arm}= { 
        arm => $arm, name => $arm, id => $arm, 
        type => 'golden_path', # fixme
        start => 1, 
        length => 0, # fixme
        strand => 0, oid => 0, species => '', org => '', # fixme
        }; 
      } 
    $chromosome->{$arm}->{parts}= $chrparts->{$arm}; 
  }

  my $organisms = $self->getOrganismTable(\%orgset);
    
  $config->{chromosome}= $chromosome;
  $self->getChromosomes();
  warn "N chromosomes=",scalar(keys %{$chromosome}),"\n" if $DEBUG;
  return $chromosome;
}


sub getOrganismTable
{
	my $self= shift;
	my($orgset)= @_;
  
 ## add read from overview tables/organisms-overview.txt
 ## flds: qw(Organism_id Abbreviation Genus Species Common_name N_features Comment)
  unless($self->{did_organism}) {
    my $overviewset = $self->getFilesetInfo('overview');
    my $tabdir = $self->getReleaseSubdir( $overviewset->{path} || 'tables/');
    my $tabfile= catfile( $tabdir, "organisms-overview.txt");
    my @colheads;
    if( open(DOC,$tabfile) ) { 
      $orgset= {} unless(ref $orgset);
      $self->{did_organism}++;
      while(<DOC>){
        chomp; my @col= split "\t";
        if(/^Organism_id/i){ @colheads= @col; }
        elsif(/^\d/ && scalar(@col) > 3) {
          foreach (@col) { $_='' if($_ eq "\\N"); }
          my($orgid,$abbreviation,$genus,$species,$common,@xtra)= @col;
          my $fullspecies= $genus."_".$species;
          unless($abbreviation) { $abbreviation= $self->speciesAbbrev($fullspecies); }
          my $org4= $self->species4letter($fullspecies);

          $orgset->{$orgid}= { 
            organism_id => $orgid, 
            org4 => $org4,
            abbreviation => lc($abbreviation), 
            genus => $genus, 
            species => $species,
            fullspecies => $fullspecies,
            from_db => 1,
            };
          }
      }
      close(DOC);  
    }
  }


  my $organisms= $self->config->{organism};
  $organisms= {} unless(ref $organisms);
  my $norgs=0;
  if(ref $orgset) {
  foreach my $orgid (keys %$orgset) {
    my $orgref= $orgset->{$orgid};
    $organisms->{$orgid}={} unless(ref $organisms->{$orgid});
    next if( $organisms->{$orgid}->{from_db} && ! $orgref->{from_db});

    $organisms->{$orgid}->{organism_id}= $orgid;  
    my $fullspecies= $orgref->{fullspecies} || $orgref->{genus}."_".$orgref->{species}; 
    $organisms->{$orgid}->{fullspecies}= $fullspecies;
    $organisms->{$orgid}->{species}= $fullspecies; #?? need this same as fullspecies??
    $organisms->{$orgid}->{from_db}= $orgref->{from_db} || 0;
    $organisms->{$orgid}->{org4}= $self->species4letter($fullspecies); 
    
    my $abbrev= $orgref->{abbreviation} || $self->speciesAbbrev( $fullspecies );
    $organisms->{$orgid}->{abbreviation}= $abbrev; 
    
    $organisms->{$abbrev}= $organisms->{$orgid}; # copy for orgid lookup
    $norgs++;
    }
  warn "Organisms n_entries=$norgs\n" if $DEBUG;
  } 
  $self->config->{organism}= $organisms;
  return $organisms;
}


sub getChromosomes
{
	my $self= shift;
  my $config= $self->config;
  unless(ref $config->{chromosomes}) {
    my $chromosome= $self->getChromosomeTable();
    my @csomes= grep !/^_/, sort keys %$chromosome;
    $config->{chromosomes}= \@csomes;
    }
  return $config->{chromosomes};
}


# this needs to be a configuration choice (how many genus,species letters)
# and combine with chado table abbreviation, locase or not, ... have too many
# abbreviations now, used in file names.  Need simpler common abbrev.

sub species4letter
{
	my $self= shift;
	my ($spp)= @_;
  $spp ||= $self->config->{species} || $self->config->{org};
	$spp =~ s/ /_/g;
	
	my $spattern= $self->config->{species_short_pattern}
	      || '^(\w)[^_]*_(\w{1,3})';
	  
	my( $ga, $sa) = $spp =~ /$spattern/;
	return lc($ga.$sa) if($ga and $sa); #? should lc() be a _pattern option?
  return lc( substr($spp,0,4) ); #??
}

sub speciesAbbrev
{
	my $self= shift;
	my ($spp, $org4letter)= @_;
  $spp = $spp || $self->config->{species} || $self->config->{org} || "";
	$spp =~ s/ /_/g;
  my $organisms= $self->config->{organism};
  if (ref $organisms) {

  local $^W=0; # kill warnings of undef orgset values
    foreach my $org (reverse sort keys %{$organisms}) {
      my $orgset= $organisms->{$org};
      if ($spp eq $org 
        || $spp eq $orgset->{fullspecies}
        || $spp eq $orgset->{species}
        || $spp eq $orgset->{organism_id}
        ) {
        
        if($org4letter) {
          my $org4= $orgset->{org4} || $self->species4letter($spp);
          return $org4;
          }
        elsif ($org =~ /\d+/) { # watchout for org == orgid here
          my $abbr= $orgset->{abbreviation};
          return $abbr if $abbr;
          }
        else { return $org; }
        }
      }
    }
  return $self->species4letter($spp);
}


sub speciesFull
{
	my $self= shift;
	my ($org)= @_;
	my $species= '';
	
	unless($org) {
    $species= $self->config->{species};
    $species =~ s/ /_/g;
    return $species if($species =~ m/_/);
    }
  $org= $org || $species || $self->config->{org};
  $org= $self->speciesAbbrev($org);
  my $organisms= $self->config->{organism};
  $species= $organisms->{$org}->{species} if ($organisms->{$org}->{species});
  $self->config->{species}= $species if ($species =~ m/_/);
  
  return $species;
}

=item splitFFF

  split flat feature format line to fields
   ($type,$name,$cytomap,$baseloc,$id,$dbxref,$notes,$chr)
    = splitFFF($fffeature, $chr)

=cut

sub splitFFF
{
  my( $self, $fffeature, $chr)= @_;
  my($type,$name,$cytomap,$baseloc,$id,$dbxref,$notes,$bstart);
  chomp($fffeature);
  my @v= split "\t", $fffeature;
  foreach (@v) { $_='' if $_ eq '-'; }
  
  my $ffformat = $self->{ffformat} || 0; #? test always
  unless( $ffformat > 0 ) {
    if ( @v > 7 || ($v[0] =~ /^\w/ && $v[1] =~ /^\d+$/)) { $ffformat= 2; }  
    else { $ffformat= 1; }  
    }
  if ($ffformat == 1) { ($type,$name,$cytomap,$baseloc,$id,$dbxref,$notes)= @v; }
  elsif ($ffformat == 2) { ($chr,$bstart,$type,$name,$cytomap,$baseloc,$id,$dbxref,$notes)= @v; }
  $self->{gotffformat}= $ffformat;
  
  return ($type,$name,$cytomap,$baseloc,$id,$dbxref,$notes,$chr);
}


=item $interfff= intergeneFromFFF2($chr,$fff1,$fff2)

  return fff line for region between two features
  (any feature types ok, intergenic regions most interesting)

=cut

sub intergeneFromFFF2
{
  my ($self, $chr, $fff1, $fff2)= @_;
  my $newfff='';
  my ($type,$name1,$cytomap,$baseloc1,$id1,$dbxref,$notes);
  my ($chr2,$name2,$baseloc2,$id2);
  my $intergenetype='intergene'; # FIXME 
  
  ($type,$name1,$cytomap,$baseloc1,$id1,$dbxref,$notes,$chr)
      = $self->splitFFF( $fff1, $chr);
  my($start1,$stop1,$strand1)= $self->maxrange($baseloc1);
  
  ($type,$name2,$cytomap,$baseloc2,$id2,$dbxref,$notes, $chr2)
      = $self->splitFFF( $fff2, $chr);
  my($start2,$stop2,$strand2)= $self->maxrange($baseloc2);
  
  if ($chr eq $chr2 && ($stop1 + 2) < $start2) { 
    my $iname= "$name1/$name2";
    my $iid= "$id1/$id2";
    my $interloc= ($stop1+1)."..".($start2-1);
    if ($self->{gotffformat} == 2) {
      $newfff= join("\t", $chr, $stop1, $intergenetype, $iname,'-', $interloc, $iid,$dbxref,$notes);
    } else {
      $newfff= join("\t", $intergenetype, $iname,'-', $interloc, $iid,$dbxref,$notes);
    }
    }
  return $newfff;
}

## no_csomesplit: replace dna/ files w/ chado db calls for all?? see dumpChromosomeBases
sub getDnaSeqFromDb
{
  my($self,$chr)= @_;
  my $csomeset= $self->getChromosomeTable();  
  my $id= $csomeset->{$chr}->{id} || $chr;
  my $bases= $self->getBasesFromDb($id,1); 
  unless ($bases) { 
    warn "getDnaSeqFromDb: no bases for segment:$chr\n"; 
    die if $self->{failonerror};  
    }
  return $bases;
}


sub getDnaSeq 
{
  my ($self, $chr)= @_;
  my $seq= $dnaseqs{$chr};
  unless($seq) {
    
    my $no_csomesplit= $self->config->{no_csomesplit} || 0; # 2007oct: old default, change for many small scaffolds
    if($no_csomesplit) {
      my $dna= $self->getDnaSeqFromDb($chr);
      $seq= Bio::PrimarySeq->new( -id=>$chr, -seq => $dna);
      print STDERR "getDnaSeqFromDb $chr, length=",$seq->length(),"\n" if $DEBUG;
      
    } else {
      my $dnafile= $self->dnafile($chr); #"$dnadir/dna-$chr.raw";
      $seq= Bio::GMOD::Bulkfiles::MyLargePrimarySeq->new( -id=>$chr, -file => $dnafile);
      print STDERR "open dnafile $dnafile, length=",$seq->length(),"\n" if $DEBUG;
      }
    $dnaseqs{$chr}= $seq;
    }
  return $seq;
}

sub getBases
{
  my($self, $usedb,$type,$chr,$baseloc,$id,$name,$subrange,$makeaa)= @_;
  my $bases= undef;
  if($usedb && $id) { 
    $bases= $self->getBasesFromDb($id); 
    return $bases if($bases || $self->{failonerror} || $self->{skiponerror}); 
    }
  unless ($bases) { 
    $bases= $self->getBasesFromFiles($type,$chr,$baseloc,$name,$subrange);   
    if($makeaa) { $bases= $self->dna2protein($bases); }
    }
  return $bases;
}


# but see  Bio/GMOD/DB/Config.pm
sub dbiDSN
{
  my ($self, $dsn)= @_;
  my $config= $self->config;
  my ($dbuser,$dbpass)=("","");
  if ($dsn && $dsn =~ /^dbi:/) { $self->{dsn}= $dsn; }
  if (ref $config->{db}) { 
    my $dbname= $config->{db}->{name};
    my $relid= $config->{relid}; #? or now use promoted {release_dbname}
    my $reldb= ($relid && defined $config->{release}->{$relid}) 
      ? $config->{release}->{$relid}->{dbname} :'';
    $dbname= $reldb if ($reldb);
    unless($dbname) { warn "missing dbname"; die if $self->{failonerror}; }
    
    ## ? handle   dbi:mysql:database=dmel_r41_20050207;host=localhost;port=3306;mysql_socket=/tmp/fbmysql.sock
    if($config->{db}->{dsn}){
      $dsn  =  $config->{db}->{dsn};
    } else {
    $dsn  = "dbi:" . $config->{db}->{driver} || "Pg";
    $dsn .= ":dbname=" .$dbname;
    $dsn .= ";host=" .$config->{db}->{host} if $config->{db}->{host};
    $dsn .= ";port=" .$config->{db}->{port} if $config->{db}->{port};
    #?? $self->{dsn}= $dsn;
    }
    
    $dbuser= $config->{db}->{user} if $config->{db}->{user};
    $dbpass= $config->{db}->{password} if $config->{db}->{password};
    }
  ## if ($self->{dsn}) { $dsn= $self->{dsn}; }
  return (wantarray) ? ($dsn,$dbuser,$dbpass) : $dsn;
}

sub dbiConnect
{
  my ($self)= @_;
  my $dbh= $self->{dbh};
  unless($dbh) { 
    my $tdsn= $self->dbiDSN();
    print STDERR "DBI->connect( $tdsn )\n" if $DEBUG;
    $dbh = DBI->connect( $self->dbiDSN() )
      or die("unable to open db( $tdsn )"); # throw ?
    $self->{dbh}= $dbh;
    }
  return $dbh;
}


=item getSeqSql($sqlconf)

 read in config file with feature dump sql scripts

=cut

sub getSeqSql
{
  my ($self, $sqlconf, $sqlenv)= @_;
  $sqlconf = 'chadofeatsql' unless($sqlconf);
  $sqlenv= $self->config unless (ref $sqlenv);

  print STDERR "sqlenv: ",join("\n ", map{ $_."=".$sqlenv->{$_}} keys %$sqlenv ),"\n"
    if ($DEBUG>1);     

  my $config2= $self->{config2}; #?? Config2 object, not hash
  my $seqsql = $self->{$sqlconf} || '';
  unless($seqsql) {
    $seqsql= $config2->readConfig( $sqlconf, {Variables => $sqlenv}, {} ); 
    print STDERR $config2->showConfig($seqsql, { debug => $DEBUG })
       if ($self->{showconfig} && $DEBUG>1);      
    }
    
  my $sqxml= $config2->showConfig( $seqsql, { debug => 0 });  
    # has undefined Variables -- try to define
  if ( $sqxml =~ m/\$\{/ && ref($seqsql->{ENV_default}) ) {
    my %env= %{$seqsql->{ENV_default}};
    foreach my $k (keys %env) { $env{$k}= $sqlenv->{$k} if($sqlenv->{$k}); }
    $seqsql= $config2->readConfig( $sqlconf, {Variables => \%env}, {} ); 
    
#     if ($DEBUG) {
#       my @undefs=  $sqxml =~ m/\$\{([^}]+)\}/g;
#       print STDERR "Added default vars\n"; 
#       foreach my $un (@undefs) { print STDERR "$un => ",$seqsql->{ENV_default}{$un},"\n"; }
#       }
    }

  $self->{$sqlconf}= $seqsql;
  return $seqsql;
}

=item validateVariables

  validate config values for seq_ontology, golden_path, species??
  to exist in database
  
=cut

sub validateVariables
{
  my ($self)= @_;
  return if $self->{didvalidatevars};
  $self->{didvalidatevars}= 1;
  warn "Validating...\n" if($DEBUG||$self->{automake});
  my $note="";
  my $doinspect= ($DEBUG or $self->{verbose} or $self->config->{newuser}) ? 1 : 0;
      ## ? newuser, verbose, DEBUG, ...
  
  my $fdump   = $self->config->{featdump};
  my $seqsql  = $self->getSeqSql($fdump->{config},$fdump->{ENV});
  my $sqltag  = $fdump->{tag} || "feature_sql";
  my $sqltype = 'validate';  # other types? 
  my @sqlparam=();
  
  ## tag names here are now seq_ontology_check, golden_path_check

  my $dbh= $self->dbiConnect();
  my @targets= sort keys %{$seqsql->{$sqltag}}; 
  foreach my $tgname (@targets)  {
    my $fs  = $seqsql->{$sqltag}->{$tgname};
    my $type= $fs->{type};
    my $sql = $fs->{sql};
    next unless($sql && ( $type =~ m/\b$sqltype\b/) );
    
    $note.= "$tgname = ";
    print STDERR "$type:$tgname\n" if $DEBUG; # sql=$sql 
    
    # local $^W=0; # kill warnings of undef values
    my $nrow= 0;
    my $err="";
    my $sth = $dbh->prepare($sql) or $err= "Failed to prepare $sql";  
    unless($err) { $sth->execute() or $err= "Failed to execute sql";  }
    unless($err) { while (my @row = $sth->fetchrow_array) {  $nrow++; } }
    $sth->finish(); 
      
    my $sql_inspect = $fs->{sql_inspect}; # optionally show this inspect even if no err
    if($err or $nrow == 0) {
      $err .= "*** Failed validation check for $tgname\n";
      $err .= $fs->{warning}."\n" if($fs->{warning});
      $err .= "$tgname sql=$sql\n";
      warn $err; $err= "Invalid $tgname\n";
      $doinspect= 1;
      }
        
    if($doinspect and $sql_inspect) {
      warn "\nInspecting database for $tgname values...\n";
      print STDERR ("-") x 60, "\n";
      my $result= $self->getFeaturesFromDb( *STDERR, $sql_inspect, undef, "colnames"); 
      print STDERR ("-") x 60, "\n";
    }
      
    if ($err) {
      warn $err; die if($self->{failonerror}); #?? ||$self->{automake}
      $note.="Invalid ";
      }
    else { $note.="Ok "; }
    }
    
  warn "Variable checks: $note\n" if($DEBUG||$self->{automake});
}


=item  updateSqlViews

 add views to db used by sql feature calls.
 this may fail if one lacks update permissions; assume
 user knows about such
 
=cut

sub updateSqlViews
{
  my ($self, $seqsql, $sqltag)= @_;
  return if $self->{didsqlviews};
  $self->{didsqlviews}= 1;

  unless($seqsql) {
    my $fdump  = $self->config->{featdump};
    $seqsql  = $self->getSeqSql($fdump->{config},$fdump->{ENV});
    }
  $sqltag  ||=  "feature_sql";
  my $sqltype = 'view';  # other types? procedures ?
 
  my $dbh= $self->dbiConnect();
  my @targets= sort keys %{$seqsql->{$sqltag}}; 
  foreach my $tgname (@targets) 
  {
    my $fs= $seqsql->{$sqltag}->{$tgname};
    my $type= $fs->{type};
    my $sql = $fs->{sql};
    unless($sql && ( $type =~ m/\b$sqltype\b/) ) { next; } 
    print STDERR "do sql $tgname $type\n" if $DEBUG; 
    my $result = $dbh->do($sql) or warn "unable to do sql $tgname $type";  
  } 
}

=item dumpFeatures
  
    dumpFeatures($fdump, $sqlconf) - extract feature_table s from chado db using
      feature sql config info
    -- add other config items for sql dumps - organism_table; lists; ..
    -- use fileset instead of featdump
    
=cut

sub dumpFeatures 
{
  my ($self, $fdump, $sqlconf, $dumpflags)= @_;
  my @files=();
  $dumpflags ||=""; ## add colnames for overview.txt
  
  $fdump   = $self->config->{featdump}  unless($fdump);
  $sqlconf = $fdump->{config} unless($sqlconf);
  my $seqsql = $self->getSeqSql($sqlconf,$fdump->{ENV});
  
  $self->updateSqlViews($seqsql, $fdump->{tag});
 
  my $outpath= $self->getReleaseSubdir( $fdump->{'path'} || catdir( $self->config->{TMP}, "featdump") );
  $fdump->{'path'}= $outpath; # save for reuse

  my $sqltag  =  $fdump->{tag} || "feature_sql";
  my $sqltype =  $fdump->{type};
  my $targets =  $fdump->{target}; # should be array ?
  unless($targets) { my @tg= sort keys %{$seqsql->{$sqltag}}; $targets= \@tg; }
  unless(ref $targets) { $targets= [ $targets ]; }
  
  foreach my $tgname (@$targets) 
  {
    my $fs= $seqsql->{$sqltag}->{$tgname};
    unless($fs) { warn "no sql dump target $tgname in $sqlconf"; next; }
    my $type= $fs->{type};
    my $sql = $fs->{sql};
    my $outn= $fs->{output} || $tgname.".tsv";
    unless($sql && (!$sqltype || $type =~ m/\b$sqltype\b/)) { 
      warn "dumpFeatures skip: $tgname/$type<>$sqltype\n";
      next; } #??

    my $outf= catfile($outpath,$outn);
    my $outh= new FileHandle(">$outf");
    print STDERR "sql dump $tgname $type $outf\n" if $DEBUG; 
    my $nout= $self->getFeaturesFromDb( $outh, $sql, undef, $dumpflags);# \@sqlparam ?
    print STDERR "sql dump $tgname n rows=$nout\n" if $DEBUG;  
    close($outh);
    
    my $fixme = $fs->{script}; # may be array/hash of scripts ?
    if ($fixme && $fixme->{type} eq 'postprocess') {
      my $shell=  $fixme->{shell} || $fixme->{language};  
      my $spath=  catfile( $self->config->{TMP}, $fixme->{name});
      my $fixinput= $outf;
      
      print STDERR "postprocess $shell $spath $fixinput\n" if $DEBUG;
      open(SH,">$spath"); print SH $fixme->{content}; close(SH);
      my $sresult= `$shell $spath $fixinput`; #?? what of perl params 
      # how do i pipe table into script ?? and out again to replace old
      # this works:  perl -i.old rdump $r/tmp/featdump/analysis.tsv
      }
      
      ## changed keys: name=> target; file=> name
    push(@files, { path => $outf, type => $type, target => $tgname, name => $outn, });
  }
  return \@files;
}


=item getFeaturesFromDb
  
  $nrows = self->getFeaturesFromDb( $outh, $sql, \@sqlparam, $flags)
  $table = self->getFeaturesFromDb( undef, $sql, \@sqlparam, $flags)

=cut

sub getFeaturesFromDb 
{
  my ($self, $outh, $sql, $sqlparam, $flags)= @_;
  my $err="";
  my $dbh = $self->dbiConnect();
  my $sth = $dbh->prepare($sql) or $err= "failed to prepare $sql";  
  if (ref $sqlparam) { $sth->execute(@$sqlparam) or $err= "failed to execute sql" ; }
  else { $sth->execute() or $err= "failed to execute sql"; }
  if ($err) { warn $err; die if($self->{failonerror}); return -1; }
 
  ## analysis sql gets lots of: Use of uninitialized value in join  
  local $^W=0; # kill warnings of undef values
  my $result= 0;
  if($outh) {  
    print $outh join("\t",@{$sth->{NAME}})."\n" if($flags=~/colname/i);
    while (my @row = $sth->fetchrow_array) { 
      print $outh join("\t",@row),"\n"; $result++;
      }
  } else {  
    $result = join("\t",@{$sth->{NAME}})."\n" if($flags=~/colname/i); # is this ok?
    while (my @row = $sth->fetchrow_array) { 
      $result .= join("\t",@row)."\n";  
      }
  }
  $sth->finish();
  return $result;
}

=item $bases= getBasesFromDb( $uniquename)

=cut

sub getBasesFromDb 
{
  my ($self, $uniquename, $iscsome)= @_;
  my $dbh= $self->dbiConnect();
  my $sql="";
  $sql= $self->config->{dnadump}->{sql_csome} if ($iscsome);
  $sql ||= $self->config->{dnadump}->{sql};
  $sql ||= "select feature_id, residues, md5checksum, seqlen, name from feature where uniquename = ?";
  my $err="";    
  my $sth = $dbh->prepare($sql) or $err="unable to prepare feature_id";
  unless($err) { $sth->execute($uniquename) or $err="failed to execute feature_id"; }
  if ($err) { warn $err; die if ($self->{failonerror}); return undef;  }

  ## check for >1 row! e.g. flybase dpse has 2+ csome entries, 1 w/o bases, for same ID
  my($hashref,$feature_id,$bases)=(undef,undef,"");
  while (my $nextrow = $sth->fetchrow_hashref) {
    $hashref = $nextrow;
    $feature_id = $$hashref{'feature_id'};
    $bases= $$hashref{'residues'} || "";
    last if $bases;
    }    
  $self->{gotbases}= $hashref; ## return md5checksum, seqlen fields ;stick all other fields into self
  $sth->finish();
  print STDERR "getBasesFromDb $uniquename -> $feature_id ;  n bases=",length($bases),"\n" 
    if (!$bases || $DEBUG > 1);
  return $bases;
}

sub getLastBasesFeature
{
  my ($self)= @_;
  return $self->{gotbases};
}

sub maxrange 
{
  my ($self, $range)= @_;
	my ($pre, $suf,$start,$stop, $b, $u);
	$start= -9; $stop= $start;

	$range =~ s/^([^\d<>-]*)//; $pre= $1;
	$range =~ s/(\D*)$//;  $suf= $1;

  my $strand= ($pre =~ /^complement/) ? -1 : 1;
	if ($range =~ m/^([<>]*)([\d\-]+)/) { $u= $1; $start= $2; $start-- if ($u eq '<'); }
	if ($range =~ m/([<>]*)([\d\-]+)$/) { $u= $1; $stop= $2; $stop++ if ($u eq '>'); }
	return ($start,$stop,$strand);
}


sub dna2protein
{
  my($self, $dna)= @_;
  my $aa= undef;
  eval {
    require Bio::Tools::CodonTable;
    my $codonTable   = Bio::Tools::CodonTable->new();
    $aa = $codonTable->translate($dna);
    }; 
    
  if ($@) { 
    warn "dna2protein: err: $@"; 
    die if ($self->{failonerror} || $self->{automake});
    }
  return $aa;
}



sub getBasesFromFiles
{
  my($self, $type,$chr,$baseloc,$name,$subrange)= @_;
  my $bases= undef;
  my $gotloc= $baseloc;
  
  my $dnaseq= $self->getDnaSeq($chr);  
  if ($dnaseq) {
    my ($start,$stop,$strand)= $self->maxrange($baseloc);
    my ($subrb,$subre,$rs)=(0,0,0);
    if ($subrange) { 
      # need some more logic in $subrange to get just upstream or downstream sections
      # readseq's: start +/- offset1, stop +/- offset2; eg. (start-2000,start); (stop,stop+2000); (start-2000,stop); (start,stop+2000)
      
      my $maxseq= $dnaseq->length();
      ($subrb,$subre,$rs)= $self->maxrange($subrange); 
      if ($subrb) { $start += $subrb ; $start=1 if $start<=0; } # need dnaseq min/max !
      if ($subre) { $stop  += $subre ; $stop=$maxseq if $stop> $maxseq; } # need dnaseq min/max !
      }
      
    my $range= $baseloc;
    $range =~ s/^[\w]*\(?//;  ##s/^([^\d<>-]*)//;  
    $range =~ s/\)?\s*$//;  
    my @locs= split(/,/,$range);
    if (@locs>1) {
      my $sloc = Bio::GMOD::Bulkfiles::MySplitLocation->new(); ## bad strand() >> new Bio::Location::Split();
      my $topstrand= $strand; 
      $sloc->strand($topstrand); #?? bad ?
      ##if ($subrb) { unshift(@locs,"$subrb..$start"); } ## FIXME 
      ##if ($subre) { push(@locs,"$stop..$subre"); }
      # if ($topstrand < 0) { @locs = reverse @locs; } #?? right?
      foreach my $loc (@locs) {
        ($start,$stop,$strand)= $self->maxrange($loc);
        # $strand= -$strand if ($topstrand < 0);
        $sloc->add_sub_Location( new Bio::Location::Simple( 
          -start => $start, -end => $stop, -strand => $strand, ));
        }
      $gotloc= $sloc->to_FTstring();
      ## warn "feat=$name, got featloc=",$gotloc,"\n" if $DEBUG;
      $bases= $dnaseq->subseq($sloc);    
      }
    else {
      ## given warnings do we need to swap start,stop for -strand ??
      my $sloc= new Bio::Location::Simple( 
        -start => $start, -end => $stop, -strand => $strand, );
      $gotloc= $sloc->to_FTstring();
      $bases= $dnaseq->subseq($sloc);   
      }
     
    }
  
  print STDERR "dna-file: $name, bases=",length($bases),"\n" if $DEBUG > 1;
  if (!$subrange && ($gotloc ne $baseloc)) {
    my $ok= 0;
    ## check  for silly 123..123 => 123 change 
    while ($baseloc =~ m/(\d+)\.\.(\d+)/g) {
      my($a,$b)= ($1,$2); 
      if ($a eq $b) { $ok=1; last; }
      }
    warn "dna-file: WARNING $name, loc-out=$gotloc ne loc-in=$baseloc\n" 
      unless $ok;
    }
  return $bases;
}



sub _isold {
  my($source,$target) = @_;
  ## not for symlinks or dirs
	my $res= 0;
  my $targtime= -M $target; ## -M is file age in days.hrs before now
  if (! -f $target) { return 1; }
  elsif ( -l $source ) {
    # $source= _getLinkOriginal($source);
    $res= (-M $source) < $targtime; 
    }
  elsif ( -f $source ) { 
    $res= (-M $source) < $targtime; 
    }
  else { $res= 0; }
  return $res;
}

sub _getLinkOriginal {
  my($source) = @_;
	my $rsource= readlink($source);
	return $source unless ($rsource);
	if ($rsource =~ m/^\.\./) {
		my $at= rindex( $source,'/');
		$rsource= substr($source,0,$at) . '/' . $rsource;
		}
	return $rsource;
}

##  option to symlink ReleaseDir to 'current' for genomeweb path
sub makeCurrentLink 
{
  my ($self)= @_;
  my $sok= 0;

  my $reldir = $self->getReleaseDir();
  my $subdir = $self->config->{relfull} || $self->config->{rel} || "release";
  my $curdir = $reldir;
  unless($curdir =~ s,$subdir$,current,) {
    $sok= -1; return $sok; # what?
    }
  
  if( -l $curdir) {
    my $lsource = _getLinkOriginal($curdir);
    if ($lsource =~ m/$subdir$/) { $sok= 1; }
    else { 
      warn "unlink old $curdir -> $lsource\n" if $DEBUG; 
      unlink($curdir); $sok= 1; # unlink err?
      }
    }
  elsif( -d $curdir) {
    warn "'$curdir' is directory, not symlink\n";
    $sok= -1;  
    }
  unless(-e $curdir) {  
    (my $topdir= $curdir) =~ s,current$,,;
  	my $olddir= $ENV{'PWD'};  #?? not safe?
    $sok = chdir($topdir); # NOTE: relative link; subdir has no path
    $sok = symlink($subdir,'current') if $sok; 
    chdir($olddir);
    }
  warn "Changed 'current' release symlink to $reldir; ok=$sok\n";
  return $sok;
}

sub makePath
{
  my($self, $dir, $errmsg, $failonerr)= @_;
  return 0 unless($dir); # ok or not?
  return 1 if(-d $dir);
  eval { mkpath($dir,$DEBUG); }; # 0777 permission
  if ($@) { 
    $failonerr= ($self->{failonerror}||$self->{automake})  unless(defined $failonerr);
    warn "ERROR: Couldn't create path $dir: $@\n$errmsg\n"; 
    die if ($failonerr);
    return 0;   
    }
  else { return 1; }
}

sub getReleaseDir 
{
  my($self)= @_;
  my $config = $self->config;
  my $releasedir= $config->{releasedir};
  return $releasedir if ($releasedir && -d $releasedir);

  ## optiona/default: add full species to path, if not there ...
  my $datadir= $config->{datadir}; # must exist
  my $species= $self->speciesFull();
  my $org=  $self->config->{org};
  my $subdir = $config->{relfull} || $config->{rel} || "release";
  
  $datadir= catdir($datadir, $species) unless($datadir =~ m/$species|$org/);
  $releasedir= catdir($datadir, $subdir);
  
  $config->{releasedir} = $releasedir;
  if( ! -d $datadir) { warn " missing data dir $datadir\n";  }
  else { $self->makePath($releasedir, "Release path $subdir needed"); }
  return $releasedir;
}


sub getReleaseSubdir 
{
  my($self, $subdir, $flags)= @_;
  my $config= $self->config;
  $flags ||= "";
  unless(-d $subdir) {
    my ($filename,$ext);
    if ($subdir !~ m,/$, && $subdir =~ m,/, && $subdir =~ m,\.,) {
      ($filename, $subdir, $ext) = File::Basename::fileparse($subdir, '\.[^\.]+');
      }
    my $reldir= $self->getReleaseDir();
    $subdir= catdir($reldir,$subdir) unless(-d $subdir);
    $self->makePath($subdir,  "Release subdir $subdir needed") 
      unless(-d $subdir || $flags =~ /nocreate|nomake/); ## mkpath
    }
  return $subdir;
}


#  ## promote all <release id=relid> to top of config ..
#   <release id="3" dbname="chado_r3_2_27" date="20040804" ... />
sub promoteRelease
{
  my($self, $config)= @_;
  
  my $relid= $config->{relid} ||  $self->{date};
  unless($relid) { $relid= $config->{relid}= $self->{date}; }
  unless( ref $config->{release}->{$relid} ) {
    $config->{release}->{$relid}= {
      date => $self->{date},
      };
  }
  
  if($relid && ref $config->{release}->{$relid}) 
  {
    my %relh= %{$config->{release}->{$relid}};
    foreach my $k (keys %relh) {
      $config->{'release_'.$k}= $config->{$k}= $relh{$k} ;
      # double-store: too many 'date' keys in conf files; use '${release_key}' by preference
      }
  }
  
  unless($config->{rel}) {  # used much, relid ~= rel
    my $org= $config->{org} || "rel";
    $config->{rel}= $org.$relid; 
    }
  $config->{'release_id'}= $config->{rel} unless($config->{'release_id'}); ## alias of config variables ??
  $self->updateConfigVars(); # install ${release_} variables
}


sub initData 
{
  my($self, $config, $oroot)= @_;
  
  # check $self for params
  unless(ref $config) { $config= $self->config || {};  }
  $self->{config}= $config;
  $self->{verbose}= $self->{verbose} || $config->{verbose};
  ## added $self->config->{newuser} ; turn on verbose, valid checks with this
  $config->{no_csomesplit}= $self->{no_csomesplit} if($self->{no_csomesplit});
  
  if (ref $config->{ENV}) {
    foreach my $key (%{$config->{ENV}}) {
      $ENV{$key}= $config->{ENV}->{$key} unless($ENV{$key});
      }
    }

  $self->promoteRelease($config);

  unless(defined $oroot && -d $oroot) {
    if (defined $config->{ROOT}) { $oroot= $config->{ROOT}; }
    elsif ($ENV{ARGOS_SERVICE_ROOT}) { $oroot= $ENV{ARGOS_SERVICE_ROOT}; }
    elsif ($ENV{ARGOS_ROOT} && $config->{SERVICE}) { $oroot= $ENV{ARGOS_ROOT}.'/'.$config->{SERVICE}; }
    elsif ($ENV{GMOD_ROOT}) { $oroot= $ENV{GMOD_ROOT}; }
    
    unless(defined $oroot && -d $oroot) {
      my $bin = "$FindBin::RealBin"; 
      if ( -e "$bin/../common/") { $oroot= "$bin/../"; }
      elsif ( -e "$bin/../conf/") { $oroot= "$bin/../"; }
      # ^^ this is putting data into GMODTools/ folder - ok? no?
      else { $oroot= "./"; }  
      $oroot=`cd "$oroot" && pwd`; chomp($oroot);
      }
    }
  print STDERR "Using rootpath=$oroot\n" if $DEBUG; # is this bad?
  $self->{rootpath} = $config->{rootpath} =  $oroot; # gmod_root ??

  my $datadir= $config->{datadir} || "genomes";  
  $datadir= "$oroot/$datadir" unless(-d $datadir);
  if (!-d $datadir && -d $oroot) { 
    $self->makePath($datadir,
      "** Need writeable data dir=$datadir\nChange configuration datadir\n", 1);  #mkpath($datadir,$DEBUG);
    }
  $config->{datadir} = $datadir;
  
  my $tmpdir= $config->{TMP} || $self->getReleaseSubdir( "tmp/"); # will make dirs inside datadir
  unless( $tmpdir && $self->makePath($tmpdir,"** Need writeable TMP folder\nTrying other..\n",0) )
  {
    $tmpdir = File::Temp::tempdir( "gmodXXXX", TMPDIR => 1, CLEANUP => 1 );  
    $self->makePath($tmpdir,
    "** Need writeable TMP=$tmpdir\nChange configuration TMP\n", 1);
    warn "Using TMP=$tmpdir\n";
  }
  $config->{TMP} = $tmpdir;
  
  $self->{idpattern}= $config->{idpattern} || '[A-Za-z]+\d+';
  
  $fndel= $config->{filepart_delimiter} || '-';
  
  my $fset= $self->getFilesetInfo('dna');
  my $dnadir= $self->getReleaseSubdir( $fset->{path} || 'dna/');
  $self->{dnadir}  = $dnadir;
  
  # see getChromosomeTable: $chromosome= $config->{chromosome} if (ref $config->{chromosome});
  $self->{addids}= $config->{addids} if defined $config->{addids} ;
  $self->{ignoredbresidues}= $config->{ignoredbresidues} 
    if defined $config->{ignoredbresidues} ;

    ## FIXME -- tests w/ this allfeats can be bad ... 
  @allfeats= (ref $config->{allfeats}) ? @{$config->{allfeats}}
    : qw(
    BAC CDS DNA_motif EST RNA_motif aberration_junction cDNA_clone enhancer five_prime_UTR
    gene insertion_site intron mRNA mRNA_genscan mRNA_piecegenie mature_peptide ncRNA
    oligo   oligonucleotide point_mutation polyA_site processed_transcript protein protein_binding_site
    pseudogene rRNA region regulatory_region repeat_region rescue_fragment 
    segment golden_path_fragment scaffold golden_path sequence_variant signal_peptide snRNA snoRNA
    so source tRNA tRNA_trnascan three_prime_UTR transcription_start_site
    transposable_element transposable_element_insertion transposable_element_insertion_site transposable_element_pred
    );

  %mapchr_pattern= %{ $config->{'mapchr_pattern'} } if ref $config->{'mapchr_pattern'};
  
     # add all featset?
  if (ref $config->{featset}) { @featset= @{$config->{featset}}; }
  elsif ($config->{featset})  { @featset=  ($config->{featset}); } # singleton
  else { @featset=  qw(gene mRNA CDS transcript translation 
      tRNA miscRNA transposon pseudogene gene_extended2000 
      five_prime_UTR three_prime_UTR intron 
      );
     }
  $config->{featset}= \@featset;
  
  my @fastafeatok=();
  push(@fastafeatok, @featset); # ?? not @allfeats

  if (ref $config->{featmap}) {
    my $fm= $config->{featmap};
    foreach my $fk (keys %$fm) {
      push(@fastafeatok, $fk);
      if (ref $fm->{$fk} && defined $fm->{$fk}->{types}) {
        my @ft= split(/[\s,;]/, $fm->{$fk}->{types} ); 
        push(@fastafeatok, @ft);
        }
      }
    }
    
  $config->{fastafeatok}= \@fastafeatok;

  ## add these to %ENV before more configs so they get replaced ..
  foreach my $k (@ENV_KEYS) { defined $$config{$k} and $ENV{$k}= $$config{$k}; }

}



#-----------

=head1 

package Bio::GMOD::Bulkfiles::MySplitLocation
  
  patch for Bio::Location::Split  
  -- moved to sep. file
  
=head1 

package Bio::GMOD::Bulkfiles::MyLargePrimarySeq

  -- moved to sep. file
  patch to use Bio::Seq::LargePrimarySeq to read
  feature locations from dna.raw files.
   
  my $dnaseq= Bio::GMOD::Bulkfiles::MyLargePrimarySeq->new( -file => $dnafile);
  $loc= new Bio::Location::something(...);
  $bases= $dnaseq->subseq($loc);   
  
=cut


1;


