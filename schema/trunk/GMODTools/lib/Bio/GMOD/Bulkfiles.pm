package Bio::GMOD::Bulkfiles;
use strict;

=head1 NAME

  Bio::GMOD::Bulkfiles -- produce bulk sequence and feature files
    from Chado genome database for public distribution .
  
=head1 ABOUT Bulkfiles

  This generates Fasta, GFF, DNA and other bulk genome annotation files at
    ftp://flybase.net/genomes/Drosophila_melanogaster/current/ ..
    (and other species soon)
  It is tested with flybase chado dbs, and with SGDLite chado db

  Bulkfiles is mostly self-contained, but uses a few
  BioPerl parts plus XML::Simple for configuration files.  All of
  the organism/database-specific logic should be in these configuration
  files (see GMODTools/conf/)
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
  
  
=head1 REQUIREMENTS and INSTALLATION

  Uses a few GMOD, BioPerl, other Perl5 modules, including
    Bio::GMOD::Config.pm (and included Config2.pm)
    XML::Simple

  Program looks for conf/ folder with  .xml files.
  You likely only need to edit fbbulk-r4.xml equivalent.
  
=head1 USAGE

  # see bin/bulkfiles.pl 
  use Bio::GMOD::Bulkfiles;    
  
  my $sequtil= Bio::GMOD::Bulkfiles->new( 
    configfile => 'sgdbulk1',   # data-release config file
    debug => 1, showconfig => 0, );
  
  my $feattables = $sequtil->dumpFeatures(); 
  my $chrfeats   = $sequtil->sortNSplitByChromosome( $feattables) ; 
  my $seqfiles   = $sequtil->dumpChromosomeBases();  
  
  my $featwriter= $sequtil->getFeatureWriter();
  my $result= $featwriter->makeFiles( 
    infiles => [ @$seqfiles, @$chrfeats ], # required
    formats => [qw(fff gff fasta)] , # optional
    );
    
    
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
    datadir="data2/fban"   -- subfolder for data releases
    >

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

    -- to be documented, config. for output files
  <dnafiles ... />
  <featfiles ... />
  <fastafiles ... />

    -- feature sets to make fasta bulk files 
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
 
 TO BE DOCUMENTED: 

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
  cvs -d $cvsd co gmod/schema/GMODTools
  
=head1 SEE ALSO

  GMOD::Chado::SeqUtils  -- older sequence in/out/check methods for Chado DB

=head1 AUTHOR

D.G. Gilbert, 2004, gilbertd@indiana.edu

=head1 METHODS

=cut

#-----------------



# debug
use lib("/bio/biodb/common/perl/lib", "/bio/biodb/common/system-local/perl/lib");

use POSIX;
use FileHandle;
use File::Basename;
use File::Spec::Functions qw/ catdir catfile /;
use File::Path; ## mkpath
use FindBin qw( $RealBin); #? eval

use DBI; 

use Bio::Location::Simple;

## use Bio::GMOD::Config2; -- see below require
use Bio::GMOD::Bulkfiles::FeatureWriter; ## was ChadoFeatDump;
use Bio::GMOD::Bulkfiles::MyLargePrimarySeq;
use Bio::GMOD::Bulkfiles::MySplitLocation;


our $DEBUG = 0;
my $VERSION = "1.0";

## should be $self instead of package global?
use vars qw/  @featset @allfeats /;

my $defaultconfigfile="sequtil";  
my %dnaseqs=(); #? package global - read only BioseqFile
 

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
  # $self->SUPER::DESTROY();
}

sub init 
{
	my $self= shift;
	# $self->{tag}= 'Bulkfiles' unless (exists $self->{tag} );
	$self->{outh}= *STDOUT unless ( exists $self->{outh} );
	$DEBUG= $self->{debug} if defined $self->{debug};

  $self->{failonerror}= 0 unless defined $self->{failonerror};
  $self->{skiponerror}= 1 unless defined $self->{skiponerror};
  $self->{ignoredbresidues}= 0 unless defined $self->{ignoredbresidues};
  $self->{addids}= 0 unless defined $self->{addids};
  $self->{date}= POSIX::strftime("%d-%B-%Y", localtime( $^T ));
  
  $self->{configfile}= $defaultconfigfile unless defined $self->{configfile};
  if (defined $self->{config}) {
    $self->initData();  
  } else {
    $self->readConfig($self->{configfile});
  }
}

=item readConfig($configfile)

read a configuration file - adds to any loaded configs

=cut

sub readConfig
{
	my $self= shift;
	my ($configfile)= @_;
  eval {  
    unless(ref $self->{config2}) { 
      require Bio::GMOD::Config2; 
      $self->{config2}= Bio::GMOD::Config2->new(); 
      }
     
#     $self->{config}= $self->{config2}->readConfig( $configfile, { Variables => \%ENV } );  
    $self->{config}= $self->{config2}->readConfDir( 
      undef, ##$config2->{confdir}, 
      $configfile, #confpatt
      undef # confhash
      );  
      
     print STDERR $self->{config2}->showConfig( $self->{config}, { debug => $DEBUG }) 
      if ($self->{showconfig}); ##if $DEBUG;
      
    }; warn "Config2 err: $@" if ($@);
  
  $self->initData(); 
}


sub getconfig {
	my $self= shift;
  my $cf= $self->{config2}; # if missing ??
  # if ($cf && @_) { my %vals= $cf->get(@_); return %vals; } #?? or single val
  if ($cf && @_) { return $cf->get(@_); } 
}


=item $fname= get_filename($org, $chr, $featn, $rel, $format)
  
  make standard output file name "${org}_${chr}_${featn}_${rel}.${format}"
  
=cut

sub get_filename
{
	my $self= shift;
  my( $org, $chr, $featn, $rel, $format)= @_;
  unless ( $org ) { $org="noname"; }
  if ( $chr ) { $chr="_${chr}"; } else { $chr=''; }
  if ( $featn ) { $featn="_${featn}"; } else { $featn=''; }
  if ( $rel ) { $rel="_${rel}"; } else { $rel=''; }
  unless ( $format ) { $format="txt"; }
  my $filename="${org}${chr}${featn}${rel}.${format}";
  return $filename;
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


=item raw2Fasta( %args )

  ---  MOVE TO Bulkfiles::ToFasta 
args: 
  chr => 'X' # required
  fastafile => $file # opt
  start => 1  #opt
  end => 100000 # opt
  type => 'chromosome' # opt
  defline => 'fasta defline' # opt
  
print fasta from dna-$chr.raw files, given $chr,$start,$end

=cut

sub raw2Fasta 
{
  #my ($self, $chr, $fastafile, $start, $end, $defline)= @_;  
  my $self= shift;
  my %args= @_;  
  my $chr= $args{chr};
  my $fastafile= $args{fastafile};
  my $start= $args{start};
  my $end= $args{end};
  my $defline= $args{defline};
  my $type=  $args{type} || 'chromosome';
  
  my $dnafile= $self->dnafile($chr);  
  unless($fastafile) {
    ($fastafile = $dnafile.".fasta") =~ s/\.raw//;  
    }
  if (-e $fastafile) { warn "raw2Fasta: wont overwrite $fastafile"; return $fastafile; }
  my $outh= new FileHandle(">$fastafile"); ## $self->{outh};
  my $org= $self->{config}->{org};
  my $rel= $self->{config}->{rel};
  my $fullchr= 0;
  $start= 1 unless(defined $start && $start>=1);
  
  if (-f $dnafile) {
    my $fh= new FileHandle($dnafile);
    unless(defined $end) {
      $fh->seek(0,2);
      $end= $fh->tell();
      $fh->seek(0,0);
      $fullchr= ($start <= 1);
      }
    unless ($end>=$start) { $end= $start; } # what ?
    my $id= ($fullchr) ? $chr : "$chr:$start..$end";
    
    $defline= $self->fastaHeader( 
      ID => $id, ##"$chr:$start..$end",
      type => $type,
      chr => $chr, 
      location => "$start..$end", 
      $org ? (species => $org) : (),
      $rel ? (release => $rel) : (),
      ) unless $defline;

    print $outh ">$defline\n";

    $fh->seek($start-1,0);
    my $len= ($end-$start+1);  
    my ($buf,$sz)=('',50); 
    for (my $i=0; $i<$len; $i+=50) {
      if ($sz+$i>=$len) { $sz= $len-$i; }
      $fh->read($buf,$sz);
      print $outh $buf,"\n";
      }
    close($fh);
    }
    
  else {
    unless ($end>=$start) { $end= $start; } # what ?
    $defline= $self->fastaHeader( 
      ID => "$chr:$start..$end",
      type => $type,
      chr => $chr, 
      location => "$start..$end", 
      $org ? (species => $org) : (),
      $rel ? (release => $rel) : (),
      ) unless $defline;
    print $outh ">$defline\n";
    }
  print $outh "\n";
  print STDERR "raw2Fasta $fastafile, $defline\n" if $DEBUG;
  
  return $fastafile;
}



=item dumpChromosomeBases

  $sequtil->dumpChromosomeBases( \@chromosomes or $config->chromosomes)
  foreach chr @chromosomes
    write dnafile() getBasesFromDb($chrID)
    $sequtil->raw2Fasta() if $config->{dofasta}; -- write from db to files
   
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
  
  foreach my $chr (@$chromosomes) {
    my $dnafile= $self->dnafile($chr);  
    print STDERR "dumpChromosomeBases $dnafile\n" if $DEBUG;
    if (-e $dnafile) { 
      warn "dumpChromosomeBases: wont overwrite $dnafile"; 
      #next;  #? do fasta
      }
    else {
      my $id= $csomeset->{$chr}->{id} || $chr;
      my $bases= $self->getBasesFromDb($id); 
      if ($bases) { 
        open(DNA,">$dnafile"); print DNA $bases;  close(DNA); 
        print STDERR " dumped length=",length($bases),"\n" if $DEBUG;
        push(@files, { path => $dnafile, type => 'dna/raw', name => $chr, });
        }
      else { warn "dumpChromosomeBases: no bases for $dnafile\n"; }
      }
    
    if (-e $dnafile && $self->{config}->{dnafiles}->{dofasta}) { 
      my $ctype= $csomeset->{$chr}->{type};
      my $fafile= $self->raw2Fasta( chr => $chr, type => $ctype); 
      push(@files, { path => $fafile, type => 'dna/fasta', name => $chr, });
      }
    }
}

=item getChromosomeFiles()

return fileset of dna/raw chromosomes 

=cut

sub getChromosomeFiles
{
  my ($self, $chromosomes)= @_;
  $chromosomes= $self->getChromosomes() unless (ref $chromosomes);
  my @files=();
  
  foreach my $chr (@$chromosomes) {
    my $dnafile= $self->dnafile($chr);  
    if (-e $dnafile) {
      push(@files, { path => $dnafile, type => 'dna/raw',  name => $chr, });
      }
    }
  
  return \@files;
}

=item sortNSplitByChromosome($fileset)

 sort chado feature dump fileset  by arm, location
 and split into chromosome file set

=cut

sub sortNSplitByChromosome
{
  my ($self, $fileset)= @_;

  $fileset= $self->getDumpFiles() unless(ref $fileset);
  # return undef unless(ref $fileset);
  my $fdump= $self->{config}->{featdump};
  my $sorter=`which sort`; chomp($sorter); ## '/bin/sort'; '/usr/bin/sort';
  my $outpath= $self->getReleaseSubdir( $fdump->{'path'} || "tmp") ;
  my $outname= $fdump->{splitname} || "chadofeat";
  my $sumfile= catfile( $self->getReleaseDir(), $outname."-summary.txt");
  $outname= catfile( $outpath, $outname);

  my $intype= $fdump->{type};
  
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
    unless(-e $fp) { warn "missing dumpfile $fp"; next; }
    if ($uptodate && _isold($fp, $testout)) { $uptodate= 0 ; }
    $scmd .= "$fp ";
    }
    
  if($uptodate) {
    my @files=();
    foreach my $chr (@$chromosomes) {
      my $fn= "$outname-$chr.tsv";
      push(@files, { path => $fn, type => 'feature/table', name => $chr,  });
      }
    return \@files;
    }
    
  ## WATCH OUT - TAB here in '	' -- does $t="\t" work?
  unless($scmd) { warn "sortNSplitByChromosome: no dumpfiles at $outpath"; return undef; }
  $scmd = "cat ". $scmd ." | $sorter -t'	' -k 1,1 -k 2,2n |"; # uniq | ??
  print STDERR "sortNSplitByChromosome:\n $scmd\n" if $DEBUG;
  print STDERR "  to csomeSplit($outname)\n" if $DEBUG;
  open(FS,$scmd) || die $scmd;
  my $files= $self->csomeSplit(*FS, $outname, $sumfile);
  close(FS);
  return $files;
}

sub csomeSplit 
{
  my($self, $inh, $outname, $sumfile)= @_;
  $outname ||= "chadofeats";
  my @files=();
  my $fh= undef;
  my %h=();
  my %csomefeats= ();
  
  while(<$inh>) { 
    next unless(/^\w/); 
    my ($c, $b, $e, $s, $t, $r)= split "\t",$_,6; 
    unless($h{$c}) {
      my $fn= "$outname-$c.tsv";
      $fh= $h{$c}= new FileHandle(">$fn");
      push(@files, { path => $fn, name => $c, 
        type => 'feature/table', # should be   $fs->{type} == feature_table
        });
 		  # my $header= feattabheader($org, $c, join('',@srclist));
		  # print $fh $header;   
		  }
		 
    $fh= $h{$c};  
    print $fh $_; ## "$t\t$r";  
    $csomefeats{$c}{$t}++; $csomefeats{all}{$t}++; 
    }
    
  foreach my $c (keys %h) { $fh= $h{$c}; close($fh) if $fh; }

  if ( $sumfile ) {
    $fh= new FileHandle(">$sumfile");
    my $title = $self->{config}->{title};
    my $date = $self->{config}->{date};
    my $org  = $self->{config}->{species} || $self->{config}->{org};
    print $fh "# Summary of features for $org from $title [$date]\n";
    my @fl= grep { 'all' ne $_ } sort keys %csomefeats;
    foreach my $c ('all', @fl) {
      print $fh (($c eq 'all') ? "\n# ALL chromosomes\n" : "\n# Chromosome $c\n");
      foreach my $t (sort keys %{$csomefeats{$c}}) {
        print  $fh "$t\t$csomefeats{$c}{$t}\n";
        }
      print $fh "#","="x50,"\n";
      }  
    close($fh);
    push(@files, { path => $sumfile, type => 'feature/summary',  name => 'summary', });
    }
  
  return \@files;  
}

=item getSeqSql($sqlconf)

 read in config file with feature dump sql scripts

=cut

sub getSeqSql
{
  my ($self, $sqlconf)= @_;
  $sqlconf = 'chadofeatsql' unless($sqlconf);
  my $seqsql = $self->{$sqlconf} || '';
  unless($seqsql) {
    my $config2= $self->{config2}; #?? Config2 object, not hash
    $seqsql= $config2->readConfig( $sqlconf, {}, {} );
    #  readConfig($file, $opts, $confhash) << need to pass $confhash param so
    #    doesnt overwrite $self->config values !

    print STDERR $config2->showConfig($seqsql, { debug => $DEBUG })
       if ($self->{showconfig}); ##if $DEBUG;      
    $self->{$sqlconf}= $seqsql;
    }
  return $seqsql;
}

sub updateSqlViews
{
  my ($self, $seqsql, $sqltag)= @_;
  return if $self->{didsqlviews};
  $self->{didsqlviews}= 1;

  unless($seqsql) {
    my $fdump  = $self->{config}->{featdump};
    $seqsql  = $self->getSeqSql($fdump->{config});
    }
  $sqltag  ||=  "feature_sql";
  my $sqltype =  'view';  # other types? procedures ?
 
  my $dbh= $self->dbiConnect();
  my @targets= sort keys %{$seqsql->{$sqltag}}; 
  foreach my $sname (@targets) 
  {
    my $fs= $seqsql->{$sqltag}->{$sname};
    my $type= $fs->{type};
    my $sql = $fs->{sql};
    unless($sql && ( $type =~ m/\b$sqltype\b/) ) { next; } 
    print STDERR "do sql  $sname $type\n" if $DEBUG; 
    my $result = $dbh->do($sql) or warn "unable to do  $sql";  
  } 
}

=item getFeatureWriter()

 return handler to write bulk files, with this primary method
  $featwriter->makeFiles( 
    infiles => [ @$seqfiles, @$chrfeats ], # required
    formats => [ qw(fff gff fasta) ] , # optional
    );
    
=cut

sub getFeatureWriter
{
  my ($self, $xxx)= @_;
  my $fconfig= $self->{config}->{featfiles}->{config} || 'chadofeatconv';
  my $featwriter= Bio::GMOD::Bulkfiles::FeatureWriter->new( ##ChadoFeatDump
    configfile => $fconfig,   
    sequtil => $self, 
    debug => $DEBUG, showconfig => $self->{showconfig},
    );
  return $featwriter;
}

=item getDumpFiles($targets)

 return list of feature dump files

=cut

sub getDumpFiles 
{
  my ($self,$targets)= @_;
  my $fdump= $self->{config}->{featdump};
  my @files=();
  
  my $seqsql = $self->getSeqSql($fdump->{config});
    
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
      push(@files, { 
        path => $outf,
        type => $type,
        name => $sname,
        file => $outn,
        });
      }
  }
  
  return \@files;
}


=item getChromosomeTable

  locate and read feature dump of chromosomes (or equivalent parts)

  2L  1  22217931  0 chromosome_arm  2L  2L      1  species Drosophila_melanogaster
  2R  1  20302755  0 chromosome_arm  2R  2R      2  species Drosophila_melanogaster
  3L  1  23352213  0 chromosome_arm  3L  3L      4  species Drosophila_melanogaster
  3R  1  27890790  0 chromosome_arm  3R  3R      3  species Drosophila_melanogaster
  4   1  1237870   0 chromosome_arm  4   4       5  species Drosophila_melanogaster
  U   1  11561901  0 chromosome_arm  U   U       7  species Drosophila_melanogaster
  X   1  21780003  0 chromosome_arm  X   X       6  species Drosophila_melanogaster

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
  my $fileset= $self->getDumpFiles(['chromosomes']);
  my $path= (ref $fileset) ? $fileset->[0]->{path} : undef;
  if ($path && open(CF,$path)) {
  while(<CF>) {
    next unless(/^\w/);
    next if(/^arm\tfmin/); # header from sql out -- should be 'chromosome' or 'chr' instead of 'arm'
    chomp;
    my ($arm,$fmin,$fmax,$strand,$type,$name,$id,$oid,$attr_type,$attribute)
      = split("\t"); ##@c;
    next unless($id); #?
    ## sgdlite uses messy chr ID -- use name instead here ? better: $arm is best of both
    
    $chromosome->{$arm}= {
      name => $name || $id,
      id => $id,
      type => $type,
      start => $fmin,
      length => ($fmax - $fmin),
      strand => $strand,
      oid => $oid,
      };
    }
  close(CF);
  }
  
  $config->{chromosome}= $chromosome;
  unless(ref $config->{chromosomes}) {
    my @csomes= sort keys %$chromosome;
    $config->{chromosomes}= \@csomes;
    }
  return $chromosome;
}

sub getChromosomes
{
	my $self= shift;
  my $config= $self->{config};
  unless(ref $config->{chromosomes}) {
    my $chromosome= $self->getChromosomeTable();
    my @csomes= sort keys %$chromosome;
    $config->{chromosomes}= \@csomes;
    }
  return $config->{chromosomes};
}

sub dumpFeatures 
{
  my ($self, $sqlconf)= @_;
  my $fdump= $self->{config}->{featdump};
  my @files=();
  
  $sqlconf = $fdump->{config} unless($sqlconf);
  my $seqsql = $self->getSeqSql($sqlconf);
  
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
      print STDERR "postprocess $shell $spath $outf\n" if $DEBUG;
      open(SH,">$spath"); print SH $fixme->{content}; close(SH);
      my $sresult= `$shell $spath $outf`; #?? what of perl params 
      # how do i pipe table into script ?? and out again to replace old
      # this works:  perl -i.old rdump $r/tmp/featdump/analysis.tsv
      }
      
    push(@files,  {
      path => $outf,
      type => $type,
      name => $sname,
      file => $outn,
      });
  }
  return \@files;
  
}


=item fastaHeader
  ---  MOVE TO Bulkfiles::ToFasta 

  my $fah= main->fastaHeader( ID => 'CG123', name => 'MyGene', 
    chr => '2L', loc => '1234..5678', type => 'pseudogene',
    db_xref => 'FlyBase:FBgn0000123', note => 'BOGUS',
    );

  expected keys: type chr/chromosome loc/location ID name db_xref
   
=cut

sub fastaHeader
{
  my($self,%vals)= @_;
  
  my $type= delete $vals{type};
  my $chr= delete $vals{chr} || delete $vals{chromosome};
  my $loc= delete $vals{loc} || delete $vals{location};
  $loc= "$chr:$loc" if ($chr && $loc !~ /:/);
  
  my $ID  = delete $vals{ID} || delete $vals{id} || delete $vals{uniquename};
  my $name= delete  $vals{name};
  my $db_xref= delete $vals{db_xref} || delete $vals{dbxref};
  if ($db_xref) { $db_xref =~ s/\s*;\s*$//; $db_xref =~ s/;/,/g; $db_xref =~ s/,,/,/g;}

  my %primvals=();
  @primvals{qw(type loc ID name db_xref)}= ($type,$loc,$ID,$name,$db_xref);

  my @d=();
  foreach my $k (qw(type loc ID name db_xref), keys %vals) {
    my $v= $primvals{$k} || $vals{$k};
    push(@d, "$k=$v") if ($v);
    }
    
  my $desc= join("; ", @d);
  my $fid= ($ID) ? $ID : $name;
  unless($fid) { $fid= "${type}_${loc}"; $fid =~ tr/a-zA-Z0-9/_/cs; }
  return "$fid $desc";
}




=item $fa= $sequtil->fastaFromFFF( $fffeature,$chr,$featset)

  ---  MOVE TO Bulkfiles::ToFasta 
  return fasta for one input feature line
   $fffeature = flat-file-feature input line
   chr = chromosome
   featset = key for feature type or type-set
 
=cut

sub fastaFromFFF
{
  my($self,$fffeature,$chr,$featset)= @_;
  
  ## revise this param set for more options - expand +/- ends, array of featset types, chr, ...
  ## gene_extended(\d+)
  
  my $config= $self->{config};
  my $dropnotes= $config->{fastafiles}->{dropnotes} || 'xxx';
  
  my $ffformat= 0; my $nout= 0;
  my $bstart; 
  my @csomes= @{ $self->getChromosomes() || [] };
  my($types_ok,$retype,$usedb,$subrange,$types_info)
        = $self->get_feature_set($featset,$config);
  return "" unless( ref $types_ok );
  $usedb= 0 if $self->{ignoredbresidues};
  ##my $outh= $self->{outh};
  
  my($type,$name,$cytomap,$baseloc,$id,$dbxref,$notes);
  chomp($fffeature);
  my @v= split "\t", $fffeature;
    
  foreach (@v) { $_='' if $_ eq '-'; }
  if ($ffformat == 0) {
    if (grep({$v[0] eq $_} @csomes) && $v[1] =~ /^\d+$/) { $ffformat= 2; }
    ##if ($v[1] =~ /^\d+$/ && grep({$v[2] eq $_} @allfeats)) { $ffformat= 2; }
    elsif ( grep({$v[0] eq $_} @allfeats) ) { $ffformat= 1; } ## FIXME 
    else { warn "skipped; not FFF format? @v";  return "";  }
    }
  if ($ffformat == 1) { ($type,$name,$cytomap,$baseloc,$id,$dbxref,$notes)= @v; }
  elsif ($ffformat == 2) { ($chr,$bstart,$type,$name,$cytomap,$baseloc,$id,$dbxref,$notes)= @v; }
   
  return "" unless( $types_ok->{$type} );
  
  ##? patch for adding gene IDs to gene model features missing them
  if ($self->{addids} && $types_info->{$type} && $types_info->{$type}->{add_id}) {
    my $pid= ($id ? $id : $name);
    $pid =~ s/[_-].*$//; # try for parent id - db prefix: ?
    my $idlist= $self->{idlist}; # from readids ...
    my $idpattern= $self->{idpattern};
    if ($idlist->{$pid}) { 
      my %dtype=();
      foreach my $x ( $pid, split(/[,;\s]/,$idlist->{$pid})) { 
        if ( $x =~ m/$idpattern/) { ## /(FBgn|FBti|FBan|CG|CR)\d+/
          my $dtype= $1;
          unless( $dtype{$dtype} || ($dbxref && $dbxref =~ m/$x/) ) { 
            $dbxref .= "," if ($dbxref); 
            $dbxref .= $x; 
            } 
          $dtype{$dtype}++;
          }
        }
      }

    # my $ptype  = $types_info->{$type}->{add_id};
    # my @pdbxref= @{$idlist->{$ptype}};
    # foreach my $x (@pdbxref) { $dbxref .= ",$x" unless($dbxref =~ m/$x/); }
    }
  
  ##? check notes for synonyms=, other fields?
  my @notes= ();
  if ($notes) {
    my %notes=();
    foreach my $n (split(/[;]/,$notes)) {
      if ($n =~ /^(\w+)=(.+)/) { 
        my($k,$v)= ($1,$2);
        if ($dropnotes !~ m/\b$k\b/) { $notes{$k} .= "$v,"; }
        } 
      }
    foreach my $n (sort keys %notes) {
      $notes{$n} =~ s/,$//;
      push(@notes, $n, $notes{$n});
      }
    }
  
  my $header= $self->fastaHeader( type => $retype->{$type}||$type, 
      name => $name, chr => $chr, location => $baseloc, 
      ID => $id, db_xref => $dbxref, 
      # cytomap => $cytomap, 
      @notes ##notes => $notes
      );
  
  my $bases= $self->getBases($usedb,$type,$chr,$baseloc,$id,$name,$subrange);
  if ($bases) {
    $nout++;
    my $slen= length($bases);
    $bases =~ s/(.{1,50})/$1\n/g;
    return ">$header; len=$slen\n".$bases; 
    }
  else {
    warn "ERROR: missing bases for $header\n";
    if ($self->{failonerror}) {  
      warn "FAILING: $featset \n";
      return -1;
      }
    return ">$header; ERROR missing data\n"; #? write to file or not
    }
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
      ? $config->{release}->{$relid}->{db} :'';
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

=item $n= getFeaturesFromDb( $outh, $sql, @sqlparam)

=cut

sub getFeaturesFromDb 
{
  my ($self, $outh, $sql, @sqlparam)= @_;
  my $dbh= $self->dbiConnect();

  my $sth = $dbh->prepare($sql) or warn "unable to prepare select $sql";  
  if (@sqlparam) { $sth->execute(@sqlparam) or warn("failed to get sql"); }
  else { $sth->execute() or warn("failed to get sql"); }
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
  my $sth = $dbh->prepare($sql)
    or warn "unable to prepare select feature_id";
  $sth->execute($uniquename) or warn("failed to get feature_id"); 
  my $hashref = $sth->fetchrow_hashref;
  my $feature_id = $$hashref{'feature_id'};
  my $bases= $$hashref{'residues'};
  $sth->finish();
  warn "getBasesFromDb $uniquename -> $feature_id ;  n bases=",length($bases),"\n" 
    if (!$bases || $DEBUG > 1);
  return $bases;
}


sub maxrange {
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
  
  warn "dna-file: $name, bases=",length($bases),"\n" if $DEBUG > 1;
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

=item $fname= get_filename($org, $chr, $featn, $rel, $format)

=cut

sub get_feature_set
{
  my($self,$type,$config)= @_;
  my($fromdb,$subrange) = (0,'');
  my @ft=(); my @retype= ();
  my %type_info= ();
  $type_info{$type}= {};
  
  if (defined $config->{featmap}->{$type}) {
    my $fm= $config->{featmap}->{$type};
    @ft= split(/[\s,;]/, $fm->{types} || $type ); #? @{$fm->{types}};
    @retype= split(/[\s,;]/, $fm->{typelabel}) if ($fm->{typelabel});
    $fromdb= $fm->{fromdb} || 0;
    $subrange= $fm->{subrange} || '';
    $type_info{$type}= $fm; # just save all ?
    #$type_info{$type}->{get_id}= $fm->{get_id} || 0;
    #$type_info{$type}->{add_id}= $fm->{add_id} || '';
    }
  else {  
  CASE: {
    $type =~ /^(gene|pseudogene)$/ && do { @ft=($type); $type_info{$type}->{get_id}=1; last CASE; };
    $type =~ /^(CDS|mRNA)$/ && do { @ft=($type); last CASE; };
    $type =~ /^(five_prime_UTR|three_prime_UTR|intron)$/ && do { @ft=($type); $type_info{$type}->{add_id}= 'gene'; last CASE; };
    $type =~ /^(tRNA|ncRNA|snRNA|snoRNA|rRNA)$/ && do { @ft=($type); $type_info{$type}->{get_id}=1; last CASE; };
    $type =~ /^(miscRNA)$/ && do { @ft=qw(ncRNA snRNA snoRNA rRNA); last CASE; };
    $type =~ /^(transposable_element|transposon)$/ && do { @ft=('transposable_element'); last CASE; };
   
    $type =~ /^gene_extended(\d+)$/ && do { @ft=('gene'); $subrange="-$1..$1"; @retype=("gene_ex$1");  last CASE; };

    $type =~ /^(transcript)$/ && do { @ft=('mRNA'); $fromdb=1; @retype=('transcript'); last CASE; };
    $type =~ /^(CDS_translation|translation)$/ && do { @ft=('CDS'); $fromdb=1; @retype=('translation'); last CASE; };
   
    $type =~ /^(annotation|noncoding-gene)$/ && do { 
      ##if ($domake == 1) { warn "Feature only for comparison: $@"; }
      last CASE; };
    
    default: { 
      if ($config->{fastafiles}->{allowanyfeat}) { @ft=($type); }
      elsif (grep {$type eq $_} @{$config->{fastafeatok}}) { @ft=($type); }
      else { return undef; } ## warn "Unknown feature option: $@"; 
      };
    }
    }
    
  my %types_ok= map { $_,1; } @ft;
  my %retype  = map { my $f= shift @ft; $f => $_; } @retype;
  return (\%types_ok, \%retype, $fromdb, $subrange, \%type_info);
}

sub getReleaseDir {
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
 

sub getReleaseSubdir {
  my($self, $subdir)= @_;
  my $config= $self->{config};
  unless(-d $subdir) {
    my ($filename,$ext);
    if ($subdir !~ m,/$, && $subdir =~ m,/, && $subdir =~ m,\.,) {
      ($filename, $subdir, $ext) = File::Basename::fileparse($subdir, '\.[^\.]+');
      }
    my $reldir= $self->getReleaseDir();
    $subdir= catdir($reldir,$subdir) unless(-d $subdir);
    mkpath($subdir,$DEBUG) unless(-d $subdir); ## mkdir
    }
  return $subdir;
}


sub initData {
  my($self, $config, $oroot)= @_;
  
  # check $self for params
  unless(ref $config) { $config= $self->{config} || {};  }
  $self->{config}= $config;

  unless(defined $oroot && -d $oroot) {
    if (defined $config->{ROOT}) { $oroot= $config->{ROOT}; }
    elsif ($ENV{ARGOS_SERVICE_ROOT}) { $oroot= $ENV{ARGOS_SERVICE_ROOT}; }
    elsif ($ENV{ARGOS_ROOT} && $config->{SERVICE}) { $oroot= $ENV{ARGOS_ROOT}.'/'.$config->{SERVICE}; }
    elsif ($ENV{GMOD_ROOT}) { $oroot= $ENV{GMOD_ROOT}; }
    unless(-d $oroot) {
      my $root = "$FindBin::RealBin/../"; 
      if ( -e "$root/common/") { $oroot= $root; }
      }
    }
  $self->{rootpath} = $oroot;
  
  ## rewrite this to use $config->{vals} ...
  my $datadir= $config->{datadir} || "data2/fban"; # flybase - need better config
  $datadir= "$oroot/$datadir" unless(-d $datadir);
  if (!-d $datadir && -d $oroot) { mkpath($datadir,$DEBUG); }
  $config->{datadir} = $datadir;
  
  $self->{idpattern}= $config->{idpattern} || '(FBgn|FBti)\d+';
  
  my $dnadir= $self->getReleaseSubdir( $config->{dnafiles}->{path} || 'dna/');
  $self->{dnadir} = $config->{dnadir} = $dnadir;
  
  my $featdir= $self->getReleaseSubdir( $config->{featfiles}->{path} || 'gnomap/');
  $self->{featdir} = $config->{featdir} = $featdir;

  # see getChromosomeTable: $chromosome= $config->{chromosome} if (ref $config->{chromosome});

    ## FIXME -- tests w/ this allfeats can be bad ... 
  @allfeats= (ref $config->{allfeats}) ? @{$config->{allfeats}}
    : qw(
    BAC CDS DNA_motif EST RNA_motif aberration_junction cDNA_clone enhancer five_prime_UTR
    gene insertion_site intron mRNA mRNA_genscan mRNA_piecegenie mature_peptide ncRNA
    oligo   oligonucleotide point_mutation polyA_site processed_transcript protein protein_binding_site
    pseudogene rRNA region regulatory_region repeat_region rescue_fragment segment golden_path sequence_variant signal_peptide snRNA snoRNA
    so source tRNA tRNA_trnascan three_prime_UTR transcription_start_site
    transposable_element transposable_element_insertion transposable_element_insertion_site transposable_element_pred
    cyto_insertion cytobreakpoint_inv cytobreakpoint_other cytobreakpoint_ttp cytodeleted_segment cytoduplicated_segment cytogene
    );
  #$config->{allfeats}= \@allfeats;

      # add all featset?
  @featset= (ref $config->{featset}) ? @{$config->{featset}}
    : qw(gene mRNA CDS transcript translation 
      tRNA miscRNA transposon pseudogene gene_extended2000 
      five_prime_UTR three_prime_UTR intron 
      );
  $config->{featset}= \@featset;
  
  my @fastafeatok=();
  push(@fastafeatok, @featset); # ?? not @allfeats
  my $fm= $config->{featmap};
  foreach my $fk (keys %$fm) {
    push(@fastafeatok, $fk);
    if (defined $fm->{$fk}->{types}) {
      my @ft= split(/[\s,;]/, $fm->{$fk}->{types} ); 
      push(@fastafeatok, @ft);
      }
    }
  $config->{fastafeatok}= \@fastafeatok;
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


