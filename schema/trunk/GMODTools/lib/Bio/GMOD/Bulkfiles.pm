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

sub getFeatureWriter
sub getBlastWriter
sub getFastaWriter
sub getGnomapWriter

sub splitFFF
sub intergeneFromFFF2

=cut

=head1 METHODS

=cut

#-----------------



# debug
##use lib("/bio/biodb/common/perl/lib", "/bio/biodb/common/system-local/perl/lib");

use POSIX;
use FileHandle;
use File::Basename;
use File::Spec::Functions qw/ catdir catfile /;
use File::Path; ## mkpath
use FindBin qw( $RealBin); #? eval

use DBI; 

use Bio::Location::Simple;

# could use perl tricks here w/ ISA/can/base class to use any new type writer
use Bio::GMOD::Bulkfiles::FeatureWriter; ## was ChadoFeatDump;
use Bio::GMOD::Bulkfiles::BlastWriter;  
use Bio::GMOD::Bulkfiles::FastaWriter;  
use Bio::GMOD::Bulkfiles::GnomapWriter;  
## OR use the Bio::GMOD::Bulkfiles::ToFormat; versions

use Bio::GMOD::Bulkfiles::MyLargePrimarySeq;
use Bio::GMOD::Bulkfiles::MySplitLocation;


our $DEBUG = 0;
my $VERSION = "1.0";

## should be $self instead of package global?
use vars qw/  @featset @allfeats %mapchr_pattern $fndel /;

my $defaultconfigfile="bulkfiles"; # was 'sequtil'  
my %dnaseqs=(); #? package global - read only BioseqFile
my @defaultformats= qw(fff gff fasta blast gnomap); 
 

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
  $self->{date}= POSIX::strftime("%d-%B-%Y", localtime( $^T ));
  $self->{config}={} unless defined $self->{config};
  $self->{configfile}= $defaultconfigfile unless defined $self->{configfile};

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
	my ($configfile)= @_;
  eval {  
    unless(ref $self->{config2}) { 
      my @showtags= ($self->{verbose}) ? qw(name title about) : qw(name title);
      
      require Bio::GMOD::Config2; 
      $self->{config2}= Bio::GMOD::Config2->new( {
        #order? #searchpath => [ 'conf', 'conf/bulkfiles', 'bulkfiles',  ],
        searchpath => [ 'conf/bulkfiles', 'bulkfiles', 'conf',   ],
        debug => $DEBUG,
        read_includes => 1, # process include = 'conf.file'
        showtags => \@showtags, # another debug/verbose option - print these if found
        #gmod_root => $ROOT,
        } ); 
      }
     
    $self->{config}= $self->{config2}->readConfig( $configfile); 
    ## add processing of include="include.conf" keys ?
    
    print STDERR $self->{config2}->showConfig( $self->{config}, { debug => $DEBUG }) 
      if ($self->{showconfig}); ##if $DEBUG;
    }; 
  if ($@) { 
    my $cf= $self->{config2}->{filename}; 
    warn "Config2: file=$cf; err: $@"; 
    die if $self->{failonerror};
    }
  
  $self->initData(); 
}

sub rereadConfig
{
	my $self= shift;
  print STDERR "rereadConfig\n" if $DEBUG;
  #update $docs= $self->{config}->{doc} unless ref $docs;
	
  ## add these to %ENV before reading  so ${vars} get replaced ..
  my $sconfig= $self->{config};
  my @keys = qw( species org date title rel relfull relid release_url );
  @ENV{@keys} = @{%$sconfig}{@keys};
  my $newconfig= {};
  
  eval {  
    ##$self->readConfig($self->{configfile});
    $newconfig= $self->{config2}->readConfig( $self->{configfile}, 
      { Variables => \%ENV },
      $newconfig, # $self->{config}, << this is bad; old not overwritten 
      ); 
    
    #fixme: want to update any/all replace vals from newconfig
    # can we replace {config} - but see initData() changes.
    $self->{config}->{doc} = $newconfig->{doc} if $newconfig->{doc};
    }; 
  if ($@) { 
    my $cf= $self->{config2}->{filename}; 
    warn "Config2: file=$cf; err: $@"; 
    ##die if $self->{failonerror};
    }
  print STDERR "new.doc.content=",$newconfig->{doc}->{content},"\n" if $DEBUG;
}

sub config 
{ return shift->{config}; }

sub getconfig 
{
	my $self= shift;
  my $cf= $self->{config2}; # if missing ??
  # if ($cf && @_) { my %vals= $cf->get(@_); return %vals; } #?? or single val
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
	my ($fname)= @_;
	
  my( $org, $chr, $featn, $rel, $format, $path, $featORrel, $gz, $xtra);
  if ($fname =~ s/(\.gz)$//) { $gz=$1; }
  ($fname, $path, $format) = File::Basename::fileparse($fname, '\.[^\.]+');
  $format .= $gz if $gz; #??
  
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
  #? search for it .. if ($self->{config}->{dnafiles}->{path});

  if ($chrOrFile) {
    my $dnafile="";
    if (-e $chrOrFile) { $dnafile= $chrOrFile; }
    else { 
      my $org= $self->{config}->{org};
      my $rel= $self->{config}->{rel};
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
  my $save= $arm;
#  my $armfile= $arm;
  ##my $csomeset= $self->getChromosomeTable(); ## pass value

  if ($csomeset->{'_part2chr'}->{$arm}) {
    $arm= $csomeset->{'_part2chr'}->{$arm};
    }
  else {
  foreach my $mp (sort keys %mapchr_pattern) {
    next if ($mp eq 'null'); # dummy?
    my $from= $mapchr_pattern{$mp}->{from}; next unless($from);
    my $to  = $mapchr_pattern{$mp}->{to};
    $arm =~ s/$from/$to/g;
    # if ($to =~ /\$/) { $name =~ s/$from/eval($to)/e; }
    }
  }

  ## need to trap $arm not in $csomeset -- errors like Contig_Contig below
  ## which either need to be remapped or otherwise handled.
  ## <mapchr_pattern name="3contig"  from="^Contig\w+" to="ctg1"/>
  
  if (!$csomeset->{$arm}) {
  
    }
    
  elsif ($csomeset->{$arm} && ref($csomeset->{$arm}->{parts})) {
    my $parts= $csomeset->{$arm}->{parts};
  MATCHPART:
    foreach my $p (@$parts) {
      my $nm = $p->{name}; #? or name
      if ($nm eq $save) { #?? is this ok
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
    
  return($arm,$fmin,$fmax,$strand,$save); 
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
  
=cut

sub dumpChromosomeBases 
{
  my ($self, $chromosomes)= @_;
  #? or chromosome->{}
  my @files=();
  my $csomeset= $self->getChromosomeTable();
  $chromosomes= $self->getChromosomes() unless (ref $chromosomes);
  
  ##? change naming of dnafile() to same as other files?
  ## using get_filename
  my $saveorg= $self->{config}->{org};
  
  foreach my $chr (@$chromosomes) {
    next if $chr eq 'all';
    my $spp= $csomeset->{$chr}->{species};  ## FIX $dnafile name for this !
    my $org= $self->speciesAbbrev($spp);
    ## next if($org && $org ne $self->{config}->{org});
    ## skip if $spp ne $self->{config}->{species} ? or Rename ; but need spp abbrev
    $self->{config}->{org}= $org if $org;
    my $dnafile= $self->dnafile($chr);  #? add $org option
    $self->{config}->{org}= $saveorg;
    
    print STDERR "dumpChromosomeBases $dnafile\n" if $DEBUG;
    if (-e $dnafile) { 
      warn "dumpChromosomeBases: wont overwrite $dnafile"; 
      }

      ##  for making Unknown 'bag' chromosomes from parts
    elsif (ref($csomeset->{$chr}->{parts})) {
      my $parts= $csomeset->{$chr}->{parts};
      my $len= 0; my $np= 0;
      open(DNA,">$dnafile"); 
      foreach my $p (@$parts) {
        my $id= $p->{id};
        my $bases= ($id) ? $self->getBasesFromDb($id) : ''; 
        print DNA $bases if ($bases); 
        $len += length($bases); $np++;
        }
      close(DNA); 
      print STDERR " dumped $chr parts=$np, total_length=",$len,"\n" if $DEBUG;
      push(@files, { path => $dnafile, type => 'dna/raw', name => $chr, chr => $chr, });
      }
      
    else {
      my $id= $csomeset->{$chr}->{id} || $chr;
      my $bases= $self->getBasesFromDb($id); 
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
}


=item getChromosomeFiles()

return fileset of dna/raw chromosomes 
## rename this getChromosomeDnaFiles ?

=cut

sub getChromosomeFiles
{
  my ($self, $chromosomes)= @_;
  $chromosomes= $self->getChromosomes() unless (ref $chromosomes);
  my @files=();
  
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
  my ($self,$targets)= @_;
  my $fdump= $self->{config}->{featdump};
  my @files=();
  
  my $seqsql = $self->getSeqSql($fdump->{config},$fdump->{ENV});
    
  my $outpath= $self->getReleaseSubdir( $fdump->{'path'} || catdir( $self->{config}->{TMP}, "featdump") );
  $fdump->{'path'}= $outpath; # save for reuse

  my $sqltag  =  $fdump->{tag} || "feature_sql";
  my $sqltype =  $fdump->{type};
  unless($targets) { $targets =  $fdump->{target}; } # should be array ?
  unless($targets) { my @tg= sort keys %{$seqsql->{$sqltag}}; $targets= \@tg; }
  unless(ref $targets) { $targets= [ $targets ]; }
  
  foreach my $sname (@$targets) 
  {
    my $fs= $seqsql->{$sqltag}->{$sname};
    unless($fs) {  next; }
    my $type= $fs->{type};
    my $sql = $fs->{sql};
    my $outn= $fs->{output} || $sname.".tsv";
    unless($sql && (!$sqltype || $type =~ m/\b$sqltype\b/)) { next; } #??

    my $outf= catfile($outpath,$outn);
    
    if (-e $outf) {
      push(@files, { path => $outf, type => $type, name => $sname, file => $outn, });
      }
  }
  
  return \@files;
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
    if (-e $fastafile) {
      push(@files, 
        { path => $fastafile, type => 'chromosome/fasta',  name => $chr,  chr => $chr});
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
  my $fdump= $self->{config}->{featdump};
  my $outpath= $self->getReleaseSubdir( $fdump->{'path'} || "tmp/") ;
  my $outname= catfile( $outpath, $fdump->{splitname} || "chadofeat");

  $chromosomes= $self->getChromosomes() unless (ref $chromosomes); 

  ##my $spp= $csomeset->{$chr}->{species};  ## FIX $dnafile name for this !
  my $spp= $self->{config}->{species} || $self->{config}->{org};
  my $orgabbr= $self->speciesAbbrev($spp);
  #?? $orgabbr == '3'
  print STDERR "# feature_table org=$orgabbr species=$spp path=$outpath \n" if $DEBUG;
  
  foreach my $chr (@$chromosomes) {
    next if $chr eq 'all';
    my $fn;
    #^^ FIXME for species file name: chadofeat-dmel2L.tsv .. chadofeat-dpseXR_group9.tsv
    # ? add spp to getChromosomes() ?
    $fn= "$outname-$orgabbr$chr.tsv";
    $fn= "$outname-$chr.tsv" unless( -e $fn);
    
    push(@files, { path => $fn, type => 'feature_table', name => $chr, org => $orgabbr  });
    }
  print STDERR "# feature_table files=",join(",",map{ basename($_->{path})}@files),"\n" if $DEBUG;
  return \@files;
}  



sub getFilesetInfo
{
  my ($self, $type)= @_;

    ## regularize/change configs so new format can be added w/o special tag names ?
  my $fset= $self->{config}->{fileset}->{$type};
  return $fset if (ref $fset);
  
  my @oldset= qw( featdump dnafiles featfiles fastafiles blastfiles gnomapfiles gbrowsefiles );
  foreach my $ms (@oldset) {
    my $fset= $self->{config}->{$ms};
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
  
    if (opendir(D, $dir)) {
      my $filepattern= '\w';
      # ($filepattern, undef) = File::Basename::fileparse($path) if ($path !~ m,/$,);
      # >> err fileparse(): need a valid pathname
      if ($path !~ m,/$,){  
        my $e= rindex($path,'/'); 
        $filepattern= ($e<0) ? $path : substr($path,$e+1); 
        }
      
      foreach my $fa (grep(/^$filepattern/,readdir(D))) { 
        my ( $org, $chr, $featn, $rel, $format)= $self->split_filename($fa);
        next unless( grep {$chr eq $_} @$chromosomes );  
        $featn ||= 'feature';
        push(@files, 
          { path => "$dir/$fa", type => "$featn/$type", name => $fa, 
            chr => $chr, format => $format, rel => $rel, org => $org });
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
        system("gzip -f ".$fs->{path}) if (-e $fs->{path});
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
  my $sortfeaturescmd= "$sorter -t'	' -k 1,1 -k 2,2n"; #? add -k 3,3rn ; nope end not there

  $fileset= $self->getDumpFiles() unless(ref $fileset);
  # return undef unless(ref $fileset);
  my $fdump  = $self->{config}->{featdump};
  my $outpath= $self->getReleaseSubdir( $fdump->{'path'} || "tmp/") ;
  my $outname= catfile( $outpath, $fdump->{splitname} || "chadofeat");
  my $intype = $fdump->{type};

  my $tfset  = $self->getFilesetInfo('tables');
  my $tabdir = $self->getReleaseSubdir( $tfset->{path} || 'tables/');
  my $sumfile= catfile( $tabdir, "feature_table-summary.txt");
  
  ## check first existance of outname files, and age 
  ## if newer than input fileset, leave as is, return file names ?
  my $chromosomes= $self->getChromosomes(); ## $self->{config}->{chromosomes};
  my $chr= $$chromosomes[0];
  my $testout= "$outname-$chr.tsv";
  my $uptodate= (-e $testout) ? 1 : 0;
  
  my $scmd="";
  foreach my $fs (@$fileset) {
    my $fp= $fs->{path};
    next unless($fs->{type} eq $intype); #??
    unless(-e $fp) { warn "missing dumpfile $fp"; next; } # die if $self->{failonerror};
    if ($uptodate && _isold($fp, $testout)) { $uptodate= 0 ; }
    $scmd .= "$fp ";
    }
    
  if($uptodate) {
    my @files=();
    foreach my $chr (@$chromosomes) {
      my $fn= "$outname-$chr.tsv";
      push(@files, { path => $fn, type => 'feature_table', name => $chr, chr => $chr,  });
      }
    return \@files;
    }
    
  
  unless($scmd) { warn "sortNSplitByChromosome: no dumpfiles at $outpath"; return undef; }
  # die if $self->{failonerror};

  $scmd = "cat $scmd | $sortfeaturescmd |";  
  print STDERR "sortNSplitByChromosome:\n $scmd\n" if $DEBUG;
  print STDERR "  to csomeSplit($outname)\n" if $DEBUG;
  open(FS,$scmd) || die $scmd;
  my $files= $self->csomeSplit(*FS, $outname, $sumfile);
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

=cut

sub csomeSplit 
{
  my($self, $inh, $outname, $sumfile)= @_;
  $outname ||= "chadofeats";
  my @files=();
  my $fh= undef;
  my %fhs=();
  my %csomefeats= ();
  my $lastoid='';
  my $csomeset = $self->getChromosomeTable(); ## pass value
  my $organisms= $self->{config}->{organism};
  my %fhsorts=();
  
  while(<$inh>) { 
    next unless(/^\w/); 
    chomp();
    my ($arm,$fmin,$fmax,$strand,$orgid,$type,$name,$id,$oid,$attr_type,$attribute)
      = split("\t"); 
    my $oldarm;
    my $oldfmax= $fmax;
    
    my $orgabbr= $organisms->{$orgid}->{abbreviation} || 'null';
    ($arm,$fmin,$fmax,$strand,$oldarm)= $self->remapArm($arm,$fmin,$fmax,$strand,$csomeset); # for Unknown.. and other fragments ? need to do before sorter call
    ##  -- BUG: remapArm U isnt sorted; need to check after 1st create files
    
    if ($attr_type eq 'to_species') {
      my $toorg= $self->speciesAbbrev($attribute);
      ## my $toorg= $organisms->{$attribute}->{abbreviation};
      $attribute= $toorg if $toorg;
      }
      
    my $dosort= ($arm ne $oldarm || $fmax ne $oldfmax);
    my $fhname= $orgabbr.$arm; ## dmel2R, 
    unless($fhs{$fhname}) {
      my $fn= "$outname-$fhname.tsv";
      $fh= $fhs{$fhname}= new FileHandle(">$fn");
      push(@files, { path => $fn, name => $arm,  chr => $arm, org => $orgabbr, 
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
    my $title = $self->{config}->{title};
    my $date = $self->{config}->{date};
    my $org  = $self->{config}->{species} || $self->{config}->{org};
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
  my $result='';

  print STDERR "makeFiles\n" if $DEBUG; # debug

  #unless($already_done_doc) ... dont do this each call!
  $self->rereadConfig(); # replace doc ${values}
  $self->writeDocs(); #? unless already wrote ?
    
  my @outformats=(); # check config
  if ($args{formats}) {
    my $formats= $args{formats};
    if(ref $formats) { @outformats= @$formats; } 
    else { @outformats=($formats); } 
    print STDERR "makeFiles: outformats= @outformats\n" if $DEBUG; 
    }
  else {
    @outformats=  @{ $self->config->{outformats} || \@defaultformats } ; 
    }
    
  my $chromosomes= undef;
  if (ref $args{chromosomes}) { $chromosomes= $args{chromosomes};  }
  elsif (ref $args{chr}) { $chromosomes= $args{chr};  }
  unless (ref $chromosomes && @$chromosomes > 0) {
    $chromosomes= [ 'all', @{$self->getChromosomes()} ];
    }
  elsif ($chromosomes->[0] eq 'all') {
    $chromosomes= [ 'all', @{$self->getChromosomes()} ];
    }
    
    # trick- getFeatureWriter loads common config for featmap/featset needed by others
  my $featwriter= $self->getWriter('fff');
  
    ## this one takes a while; split chromosomes among processors
  if (grep /fff|gff/, @outformats) {
    my $chrfeats = $self->getFiles('feature_table', $chromosomes);
    if ($DEBUG) { print STDERR "read feature tables= ",join(" ",map {$_->{name}} @$chrfeats),"\n"; }  
    $result .= $featwriter->makeFiles( %args, 
               infiles => $chrfeats, chromosomes => $chromosomes );   
    }
    
  my $featfiles = $self->getFiles('fff', $chromosomes);
  my $dnafiles  = $self->getFiles('dna', $chromosomes);
  
  if ($DEBUG) {
    my @cn= @$chromosomes; print STDERR "make chromosomes= @cn\n";
    my @fn= map {$_->{name}} @$featfiles; print STDERR "with featfiles= @fn\n";
    my @dn= map {$_->{name}} @$dnafiles; print STDERR "with dnafiles= @dn\n";
    }
  
  if (grep /fasta/, @outformats) {
    ## ! check/warn here if $featfiles or $dnafiles are missing
    my $writer= $self->getWriter('fasta');
    $result .= $writer->makeFiles(%args, 
      infiles =>  $featfiles, chromosomes => $chromosomes);
    }
    
  if (grep /blast/, @outformats) {
    ## ! check/warn here if $fafiles are missing
    my $fafiles = $self->getFiles( 'fasta', $chromosomes);
    my $writer  = $self->getWriter('blast'); # this works; eval new writer
    $result .= $writer->makeFiles( %args, 
      infiles =>  $fafiles, chromosomes => $chromosomes );  
    }
    
  if (grep /gnomap/, @outformats) {
    ## ! check/warn here if $featfiles or $dnafiles are missing
    my $writer= $self->getWriter('gnomap');
    $result .= $writer->makeFiles(%args, 
      infiles => [ @$featfiles, @$dnafiles ], chromosomes => $chromosomes); # needs $featfiles
    }
  
  my @moreformats= grep !/(fff|gff|dna|fasta|blast|gnomap)/,@outformats;
  foreach my $fmt (@moreformats) {
    my $writer= $self->getWriter($fmt);
    unless ($writer) { warn "no writer for $fmt\n"; }
    else { $result .= $writer->makeFiles( %args, 
            infiles => [ @$featfiles, @$dnafiles ], chromosomes => $chromosomes); 
      }
    }
    
  $self->gzipFiles( \@outformats, $chromosomes );
  
  return $result; #what?
}



=item writeDocs( $docs or $self->{config}->{doc})

  print docs from config file
  .. move this into own BulkWriter subclass ?
  
=cut

sub writeDocs
{
  my ($self, $docs)= @_;
  my $ndoc= 0;
  $docs= $self->{config}->{doc} unless ref $docs;
  if (ref $docs) {
    # check for 1 or many (name keys, darn xmlsimple)
    if ($docs->{name} && $docs->{content}) {
      my %dd= ( $docs->{name} => $docs );
      $docs= \%dd;
      }
    foreach my $dname (keys %$docs) {
      my $data = $docs->{$dname}->{content} || '';
      my $dpath= $docs->{$dname}->{path} || $dname;
      my $fn=  catfile( $self->getReleaseDir(), $dpath);
      print STDERR "write doc $dname $fn\n" if $DEBUG;
      
      ## check eval embedded ${vars} ? or xml reader does ?
      
      open(DOC,">$fn"); print DOC $data; close(DOC); 
      $ndoc++;
      }
    }
  print STDERR "writeDocs n=$ndoc\n" if $DEBUG; # debug
  return $ndoc;
}


#==================
=item
  
  Replace these getXxxWriter with below generic getWriter()
  
=cut

=item getFeatureWriter()

 return handler to write bulk files, with this primary method
  $featwriter->makeFiles( 
    infiles => [ @$seqfiles, @$chrfeats ], # required
    formats => [ qw(fff gff fasta) ] , # optional
    );
    
=cut

sub getFeatureWriter
{
  my ($self)= @_;

  my $fileinfo= $self->{config}->{fileset}->{fff}; # FIXME
  ##$fileinfo= $self->{config}->{featfiles} unless($fileinfo);
  my $writer= Bio::GMOD::Bulkfiles::FeatureWriter->new( 
    configfile => $fileinfo->{config}, fileinfo => $fileinfo,
    handler => $self, 
    debug => $DEBUG, showconfig => $self->{showconfig},
    );
    
  ## MOVED THIS TO FeatureWriter.new so will always happen after it reads its config
  #?? merge config from feature writer chadofeatconf with this config ?
  ## that is best place to keep common <featmap> and <featset>
#   my $fset= $writer->{config}->{featset};
#   if (ref $fset && !$self->{config}->{featset}) {
#     $self->{config}->{featset}= $fset;
#     }
#   my $fmap= $writer->{config}->{featmap};
#   if (ref $fmap) {
#     my $smap= $self->{config}->{featmap};
#     unless(ref $smap) {
#       $self->{config}->{featmap}= $smap=  {};
#       }
#     my @keys= keys %$fmap;
#     foreach my $k (@keys) { $smap->{$k}= $fmap->{$k} unless defined $smap->{$k}; } 
#     }
  
  return $writer;
}


=item getBlastWriter()

  return handler to write blast index files, with this primary method

  $blastwriter->makeFiles( 
    infiles => [ @$fastafiles ], # required
    );

#  my $blastwriter= $self->getBlastWriter();
#  $result= $blastwriter->makeFiles(%args);
    
=cut

sub getBlastWriter
{
  my ($self)= @_;
  
  my $fileinfo= $self->{config}->{fileset}->{blast};  
  ##$fileinfo= $self->{config}->{blastfiles} unless($fileinfo); 
  my $writer= Bio::GMOD::Bulkfiles::BlastWriter->new( 
    configfile => $fileinfo->{config}, fileinfo => $fileinfo,
    handler => $self, 
    debug => $DEBUG, showconfig => $self->{showconfig},
    );
  return $writer;
}


=item getFastaWriter()

  return handler to write fasta feature set sequence files, with this primary method

  $fawriter->makeFiles( 
    infiles => [ @$fastafiles ], # required? or optional
    );

=cut

sub getFastaWriter
{
  my ($self)= @_;
  my $fileinfo= $self->{config}->{fileset}->{fasta}; # FIXME
  ##$fileinfo= $self->{config}->{fastafiles} unless($fileinfo); 
  my $writer= Bio::GMOD::Bulkfiles::FastaWriter->new( 
    configfile => $fileinfo->{config}, fileinfo => $fileinfo,
    handler => $self, 
    debug => $DEBUG, showconfig => $self->{showconfig},
    );
  return $writer;
}


=item getGnomapWriter()

  return handler to write gnomap feature files, with this primary method

  $fawriter->makeFiles( 
    infiles => [ @$fastafiles ], # required? or optional
    );

=cut

sub getGnomapWriter
{
  my ($self)= @_;
  my $fileinfo= $self->{config}->{fileset}->{gnomap}; # FIXME
  ##$fileinfo= $self->{config}->{gnomapfiles} unless($fileinfo); 
  my $writer= Bio::GMOD::Bulkfiles::GnomapWriter->new( 
    configfile => $fileinfo->{config}, fileinfo => $fileinfo,
    handler => $self, 
    debug => $DEBUG, showconfig => $self->{showconfig},
    );
  return $writer;
}



sub getWriter
{
  my ($self, $type)= @_;

  my $finfo= $self->getFilesetInfo($type);
  if (ref $finfo && $finfo->{handler}) {
    my $pkg= $finfo->{handler};
    unless($pkg =~ /\:\:/) { $pkg= "Bio::GMOD::Bulkfiles::".$pkg; }  
    my $eval=
     "use $pkg;
      $pkg->new( configfile => \$finfo->{config}, fileinfo => \$finfo, 
        handler => \$self, debug => \$DEBUG,  showconfig => \$self->{showconfig},
        );";
    ##print STDERR "getWriter: eval $eval\n" if $DEBUG;
    my $writer= eval $eval; 
    if ($@) { ($self->{failonerror}) ? die $@ : warn $@;  }

    return $writer if ref $writer; 
    }
 
  print STDERR "getWriter('$type'): eval failed; fallback to getXxxWriter\n" if $DEBUG;
  ## old way
  CASE: {
    $type eq 'fasta'  && return $self->getFastaWriter(); 
    $type eq 'blast'  && return $self->getBlastWriter(); 
    $type eq 'fff'    && return $self->getFeatureWriter(); 
    $type eq 'gff'    && return $self->getFeatureWriter(); 
    $type eq 'gnomap' && return $self->getGnomapWriter(); 
    } 

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
  my $config= $self->{config};
  if (defined $config->{chromosome}) { return $config->{chromosome}; }
  
  my $chromosome= {};
  my $chrparts  = {}; # for dpse map Unknown ultra_scaffold/golden_path_fragment to U
  my $part2chr  = {}; # map golden_path_region name to chr-arm name
  my $chrpartpattern= $config->{chrpart_pattern};
  my %orgset    = ();
  
  my $fileset= $self->getDumpFiles(['chromosomes']);
  my $path= (ref $fileset) ? $fileset->[0]->{path} : undef;
  if ($path && open(CF,$path)) {
  while(<CF>) {
    next unless(/^\w/);
    next if(/^arm\tfmin/); # header from sql out -- should be 'chromosome' or 'chr' instead of 'arm'
    chomp;
    
    my ($arm,$fmin,$fmax,$strand,$orgid,$type,$name,$id,$oid,$attr_type,$attribute)
      = split("\t");  
    next unless($id); #?
    ## sgdlite uses messy chr ID -- use name instead here ? better: $arm is best of both

    ## use $strand == rank here -- assume input file is ordered by that.
    
    ## need ($arm,$golden_path,...)= mapChr($arm)
    ## ? need some compound chr{arm} with multiple ids for Unknown bag?
    
    my $species= ($attr_type eq 'species') ? $attribute : $config->{species};
    $species =~ s/ /_/g;
    my $org= $self->speciesAbbrev($species) || 'null';
    
    my $chrvals= {
      arm => $arm,
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
      organism_id => $orgid, abbreviation => lc($org), 
      genus => $genus, species => $spp,
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
  
  $chromosome->{'_part2chr'}= $part2chr;
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

  ##add db id to <organism id="dpse" species="Drosophila_pseudoobscura"/>
  $self->{config}->{organism}={}  unless(ref $self->{config}->{organism});
  my $organisms= $self->{config}->{organism};
  foreach my $orgid (keys %orgset) {
    my $org= $orgset{$orgid}->{abbreviation};
    $organisms->{$org}={} unless(ref $organisms->{$org});
    $organisms->{$org}->{organism_id}= $orgid; # need this from db
    $organisms->{$org}->{abbreviation}= $org; 
    $organisms->{$org}->{species}= $orgset{$orgid}->{fullspecies};
    $organisms->{$orgid}= $organisms->{$org}; # copy for orgid lookup
    }
    
  $config->{chromosome}= $chromosome;
  $self->getChromosomes();
#   unless(ref $config->{chromosomes}) {
#     my @csomes= sort keys %$chromosome;
#     $config->{chromosomes}= \@csomes;
#     }
  return $chromosome;
}


sub getChromosomes
{
	my $self= shift;
  my $config= $self->{config};
  unless(ref $config->{chromosomes}) {
    my $chromosome= $self->getChromosomeTable();
    my @csomes= grep !/^_/, sort keys %$chromosome;
    $config->{chromosomes}= \@csomes;
    }
  return $config->{chromosomes};
}


sub speciesAbbrev
{
	my $self= shift;
	my ($spp)= @_;
	$spp =~ s/ /_/g;
  my $organisms= $self->{config}->{organism};
  if (ref $organisms) {
    foreach my $org (reverse sort keys %{$organisms}) {
      if ($spp eq $org || $spp eq $organisms->{$org}->{species}
        || $spp eq $organisms->{$org}->{organism_id}
        ) {
        if ($org =~ /\d+/) { # watchout for org == orgid here
          my $abbr= $organisms->{$org}->{abbreviation};
          return $abbr if $abbr;
          }
        else { return $org; }
        }
      }
    }
  if ($spp =~ /^(\w)[^_]*_(\w{1,3})/) {
    return "$1$2"; # Gspp 4 letter abbrev.
    }
  return $spp; #?
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
  
  if ($chr eq $chr2 && $stop1 < $start2) { 
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



sub getDnaSeq 
{
  my ($self, $chr)= @_;
  my $seq= $dnaseqs{$chr};
  unless($seq) {
    my $dnafile= $self->dnafile($chr); #"$dnadir/dna-$chr.raw";
    $seq= Bio::GMOD::Bulkfiles::MyLargePrimarySeq->new( -file => $dnafile);
    $dnaseqs{$chr}= $seq;
    print STDERR "open dnafile $dnafile, length=",$seq->length(),"\n" if $DEBUG;
    }
  return $seq;
}

sub getBases
{
  my($self, $usedb,$type,$chr,$baseloc,$id,$name,$subrange)= @_;
  my $bases= undef;
  if($usedb && $id) { 
    $bases= $self->getBasesFromDb($id); 
    return $bases if($bases || $self->{failonerror} || $self->{skiponerror}); 
    }
  unless ($bases) { 
    $bases= $self->getBasesFromFiles($type,$chr,$baseloc,$name,$subrange);   
    }
  return $bases;
}


# but see  Bio/GMOD/DB/Config.pm
sub dbiDSN
{
  my ($self, $dsn)= @_;
  my $config= $self->{config};
  my ($dbuser,$dbpass)=("","");
  if ($dsn && $dsn =~ /^dbi:/) { $self->{dsn}= $dsn; }
  ## if ($self->{dsn}) { $dsn= $self->{dsn}; }
  if ($config->{db}) { 
    my $dbname= $config->{db}->{name};
    my $relid= $config->{relid};
    my $reldb= ($relid && defined $config->{release}->{$relid}) 
      ? $config->{release}->{$relid}->{dbname} :'';
    $dbname= $reldb if ($reldb);
    unless($dbname) {
      die "missing dbname";
      }
    $dsn  = "dbi:" . $config->{db}->{driver} || "Pg";
    $dsn .= ":dbname=" .$dbname;
    $dsn .= ";host=" .$config->{db}->{host} if $config->{db}->{host};
    $dsn .= ";port=" .$config->{db}->{port} if $config->{db}->{port};
    #?? $self->{dsn}= $dsn;

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
  $sqlenv= \%ENV unless (ref $sqlenv);

  print STDERR "sqlenv: ",join("\n ", map{ $_."=".$sqlenv->{$_}} keys %$sqlenv ),"\n"
    if ($DEBUG>1);     

  my $seqsql = $self->{$sqlconf} || '';
  unless($seqsql) {
    my $config2= $self->{config2}; #?? Config2 object, not hash
    $seqsql= $config2->readConfig( $sqlconf, {Variables => $sqlenv}, {} ); 
            ## readConfig( $file, \%opts, \%toconf) << add some main opts->{Variables} ?
    print STDERR $config2->showConfig($seqsql, { debug => $DEBUG })
       if ($self->{showconfig} && $DEBUG>1);      
    $self->{$sqlconf}= $seqsql;
    }
  return $seqsql;
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
    my $fdump  = $self->{config}->{featdump};
    $seqsql  = $self->getSeqSql($fdump->{config},$fdump->{ENV});
    }
  $sqltag  ||=  "feature_sql";
  my $sqltype = 'view';  # other types? procedures ?
 
  my $dbh= $self->dbiConnect();
  my @targets= sort keys %{$seqsql->{$sqltag}}; 
  foreach my $sname (@targets) 
  {
    my $fs= $seqsql->{$sqltag}->{$sname};
    my $type= $fs->{type};
    my $sql = $fs->{sql};
    unless($sql && ( $type =~ m/\b$sqltype\b/) ) { next; } 
    print STDERR "do sql $sname $type\n" if $DEBUG; 
    my $result = $dbh->do($sql) or warn "unable to do sql $sname $type";  
  } 
}

=item dumpFeatures
  
    dumpFeatures() - extract feature_table s from chado db using
      feature sql config info
    -- add other config items for sql dumps - organism_table; lists; ..
    -- use fileset instead of featdump
    
=cut

sub dumpFeatures 
{
  my ($self, $sqlconf)= @_;
  my $fdump= $self->{config}->{featdump};
  my @files=();
  
  $sqlconf = $fdump->{config} unless($sqlconf);
  my $seqsql = $self->getSeqSql($sqlconf,$fdump->{ENV});
  
  $self->updateSqlViews($seqsql, $fdump->{tag});
 
  my $outpath= $self->getReleaseSubdir( $fdump->{'path'} || catdir( $self->{config}->{TMP}, "featdump") );
  $fdump->{'path'}= $outpath; # save for reuse

  my $sqltag  =  $fdump->{tag} || "feature_sql";
  my $sqltype =  $fdump->{type};
  my $targets =  $fdump->{target}; # should be array ?
  unless($targets) { my @tg= sort keys %{$seqsql->{$sqltag}}; $targets= \@tg; }
  unless(ref $targets) { $targets= [ $targets ]; }
  
  foreach my $sname (@$targets) 
  {
    my $fs= $seqsql->{$sqltag}->{$sname};
    unless($fs) { warn "no sql dump target $sname in $sqlconf"; next; }
    my $type= $fs->{type};
    my $sql = $fs->{sql};
    my $outn= $fs->{output} || $sname.".tsv";
    unless($sql && (!$sqltype || $type =~ m/\b$sqltype\b/)) { next; } #??

    my $outf= catfile($outpath,$outn);
    my $outh= new FileHandle(">$outf");
    print STDERR "sql dump $sname $type $outf\n" if $DEBUG; # debug
    my $nout= $self->getFeaturesFromDb( $outh, $sql);# @sqlparam ?
    print STDERR "sql dump $sname n rows=$nout\n" if $DEBUG;  
    close($outh);
    
    my $fixme = $fs->{script}; # may be array/hash of scripts ?
    if ($fixme && $fixme->{type} eq 'postprocess') {
      my $shell=  $fixme->{shell} || $fixme->{language};  
      my $spath=  catfile( $self->{config}->{TMP}, $fixme->{name});
      my $fixinput= $outf;
      # if ($fixme->{input}) {
      # $fixinput= catfile($self->getReleaseDir(),$fixme->{input});
      # }
      
      print STDERR "postprocess $shell $spath $fixinput\n" if $DEBUG;
      open(SH,">$spath"); print SH $fixme->{content}; close(SH);
      my $sresult= `$shell $spath $fixinput`; #?? what of perl params 
      # how do i pipe table into script ?? and out again to replace old
      # this works:  perl -i.old rdump $r/tmp/featdump/analysis.tsv
      }
      
    push(@files, { path => $outf, type => $type, name => $sname, file => $outn, });
  }
  return \@files;
}


=item getFeaturesFromDb
  
  $n= getFeaturesFromDb( $outh, $sql, @sqlparam)

=cut

sub getFeaturesFromDb 
{
  my ($self, $outh, $sql, @sqlparam)= @_;
  my $dbh= $self->dbiConnect();

  my $err="";
  my $sth = $dbh->prepare($sql) or $err= "unable to prepare select $sql";  
  if (@sqlparam) { $sth->execute(@sqlparam) or $err= "failed to get sql" ; }
  else { $sth->execute() or $err= "failed to get sql"; }
  if ($err) { ($self->{failonerror}) ? die $err : warn $err;  }
 
# sql dump analysis feature_table /bio/biodb/flybase/data2/fban/sgdlite_20040519/tmp/featdump/ana
# lysis.tsv
# DBD::Pg::st execute failed: ERROR:  No such attribute armft.name at /bio/biodb/common/perl/lib/
# Bio/GMOD/Bulkfiles.pm line 1013.
   
   ## analysis sql gets lots of: Use of uninitialized value in join  
  local $^W=0; # kill warnings of undef values
  my $n= 0;
  while (my @row = $sth->fetchrow_array) { 
    print $outh join("\t",@row),"\n"; $n++;
    }
  $sth->finish;
  
  return $n;
}

=item $bases= getBasesFromDb( $uniquename)

=cut

sub getBasesFromDb 
{
  my ($self, $uniquename)= @_;
  my $dbh= $self->dbiConnect();
  my $sql= $self->{config}->{dnadump}->{sql}
      || "select feature_id, residues from feature where uniquename = ?";
  my $err="";    
  my $sth = $dbh->prepare($sql) or $err="unable to prepare select feature_id";
  $sth->execute($uniquename) or $err="failed to get feature_id"; 
  if ($err) { ($self->{failonerror}) ? die $err : warn $err;  }

  my $hashref = $sth->fetchrow_hashref;
  my $feature_id = $$hashref{'feature_id'};
  my $bases= $$hashref{'residues'};
  $sth->finish();
  print STDERR "getBasesFromDb $uniquename -> $feature_id ;  n bases=",length($bases),"\n" 
    if (!$bases || $DEBUG > 1);
  return $bases;
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
    # $source= getOriginal($source);
    $res= (-M $source) < $targtime; 
    }
  elsif ( -f $source ) { 
    $res= (-M $source) < $targtime; 
    }
  else { $res= 0; }
  return $res;
}



sub getReleaseDir 
{
  my($self)= @_;
  my $config = $self->{config};
  my $releasedir= $config->{releasedir};
  return $releasedir if ($releasedir && -d $releasedir);

  my $datadir= $config->{datadir}; # must exist
  my $subdir = $config->{relfull} || $config->{rel} || "release";
  $releasedir= catdir($datadir, $subdir);
  $config->{releasedir} = $releasedir;
  if(! -d $datadir) { warn " missing data dir $datadir";  }
  elsif(!-d $releasedir) { mkpath($releasedir,$DEBUG); }
  return $releasedir;
}


# flybase bulk seq/feature release folders:
 

sub getReleaseSubdir 
{
  my($self, $subdir, $flags)= @_;
  my $config= $self->{config};
  $flags ||= "";
  unless(-d $subdir) {
    my ($filename,$ext);
    if ($subdir !~ m,/$, && $subdir =~ m,/, && $subdir =~ m,\.,) {
      ($filename, $subdir, $ext) = File::Basename::fileparse($subdir, '\.[^\.]+');
      }
    my $reldir= $self->getReleaseDir();
    $subdir= catdir($reldir,$subdir) unless(-d $subdir);
    mkpath($subdir,$DEBUG) unless(-d $subdir || $flags =~ /nocreate|nomake/); ## mkdir
    }
  return $subdir;
}


sub initData 
{
  my($self, $config, $oroot)= @_;
  
  # check $self for params
  unless(ref $config) { $config= $self->{config} || {};  }
  $self->{config}= $config;

  if (ref $config->{ENV}) {
    foreach my $key (%{$config->{ENV}}) {
      $ENV{$key}= $config->{ENV}->{$key};
      }
    }

  unless(defined $oroot && -d $oroot) {
    if (defined $config->{ROOT}) { $oroot= $config->{ROOT}; }
    elsif ($ENV{ARGOS_SERVICE_ROOT}) { $oroot= $ENV{ARGOS_SERVICE_ROOT}; }
    elsif ($ENV{ARGOS_ROOT} && $config->{SERVICE}) { $oroot= $ENV{ARGOS_ROOT}.'/'.$config->{SERVICE}; }
    elsif ($ENV{GMOD_ROOT}) { $oroot= $ENV{GMOD_ROOT}; }
    unless(defined $oroot && -d $oroot) {
      my $bin = "$FindBin::RealBin"; 
      if ( -e "$bin/../common/") { $oroot= "$bin/../"; }
      else { $oroot= "./"; }  
      $oroot=`cd "$oroot" && pwd`; chomp($oroot);
      }
    }
  print STDERR "Using rootpath=$oroot\n" if $DEBUG;
  $self->{rootpath} = $config->{rootpath} =  $oroot; # gmod_root ??

  my $tmpdir= $config->{TMP} || "$oroot/tmp";
  if (!-d $tmpdir) { mkpath($tmpdir,$DEBUG); }
  $config->{TMP} = $tmpdir;
  
  ## rewrite this to use $config->{vals} ...
  my $datadir= $config->{datadir} || "genomes"; # flybase - need better config
  $datadir= "$oroot/$datadir" unless(-d $datadir);
  if (!-d $datadir && -d $oroot) { mkpath($datadir,$DEBUG); }
  $config->{datadir} = $datadir;

#  ## promote all <release id=relid> to top of config ..
#   <release id="3" 
#     rel="r3.2.1" 
#     relfull="dmel_r3.2.1_07212004"
#     dbname="chado_r3_2_27" 
#     date="20040804" 
#     release_url="/annot/release3.2.1.html"
#     />
  my $relid= $config->{relid};
  if($relid && ref $config->{release}->{$relid}) {
    my %relh= %{$config->{release}->{$relid}};
    foreach my $k (keys %relh) {
      ## need release date !
      $config->{$k}= $relh{$k} ;
        #??NO?# unless($config->{$k});
      }
    }
  if ($relid && !$config->{rel}) { 
    $config->{rel}= $relid; # used much, relid ~= rel
    }
  
  $self->{idpattern}= $config->{idpattern} || '(FBgn|FBti)\d+';
  
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
  #$config->{allfeats}= \@allfeats;

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
  my @keys = qw( species org date title rel relfull relid release_url );
  @ENV{@keys} = @{%$config}{@keys};

}



#-----------

=head1 

package Bio::GMOD::Bulkfiles::MySplitLocation
  
  -- moved to sep. file
  patch for Bio::Location::Split  
  
=cut

=head1 

package Bio::GMOD::Bulkfiles::MyLargePrimarySeq

  -- moved to sep. file
  patch to use Bio::Seq::LargePrimarySeq to read
  feature locations from dna.raw files.
   
  my $dnaseq= Bio::GMOD::Bulkfiles::MyLargePrimarySeq->new( -file => $dnafile);
  
  $loc= new Bio::Location::something(...);
  $bases= $dnaseq->subseq($loc);   
  
=cut

#-------

1;


