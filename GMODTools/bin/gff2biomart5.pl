#!/usr/bin/perl

=head1 NAME

  gff2biomart.pl -- create tables for BioMart from genome GFF annotations

=head1 SYNOPSIS

./gff2biomart.pl --species=scer --version=sgdlite_2005_08_23 --output tabscer/ \
 --fasta $scer/fasta/*-all-chromosome-*.fasta  \
 $scer/gff/scer-chr*.gff

  # add some extra tables here for more filters
./gff2biomart3.pl -dataset=11 -species=dper -version=br051028 -output tabdper \
 -table=cross_genome_match_dmelchr,match_tblastn_modDM \
 -fasta $dper/dper*.fa.gz $dper/gff/dper*scaffold*gff $dper/gff/dper*gff.gz

Example data sets from this tool are at:
http://insects.eugenes.org/BioMart/martview

=head1 Loading the results

Usage is for MySQL database and BioMart.org (0.3 version tested)
Please have installed and tested BioMart before trying
to use these data with it.

  # EXAMPLE LOADING INSTRUCTIONS ; use with care to existing databases  
  # LOAD tables TO MySQL: 
  
  mysqladmin create biomart
  cat tabdper//*.sql | mysql biomart 
  mysqlimport biomart `pwd`/tabdper//*.txt
  
  # LOAD xml to MySQL biomart.meta_configuration: 
  # BEST USE martj/bin/marteditor.sh to load tabdper//*.xml   
  # OR try this BUT NOT IF YOU HAVE EXISTING biomart
  # cat tabdper//meta.sql_example | mysql biomart 
  
  # NOTE: biomart is included in *.xml
  # Change datasetID's in xml, meta.sql if needed


=head1 ABOUT gff2biomart

gff2biomart creates

1. chromosome region__main tables for biomart
   with chr broken into nKb bins/regions (1kb default size?)

2. per-featuretype xfeature__dm link tables
    store feature attributes (id,dbxref,match stats,..)
    modify table __main add column feature_bool to indicate
    where features lie.

3.  create $species__chromosome__dm    
  with dna residues for fasta output from biomart
  
use in biomart:
  filter (include,exclude) features that exist in regions
  including joint filters (has homology in x
     but not homology in y,z; has gene/predict_gene/..)
  output: attributes = feature info, fasta of features
    in selected regions
Note: this means changing biomart's filter==attribute
paradigm; new perl module? 


=head1 VERSION NOTES

*** FIXME: gff2featdm dropped featuretype__dm, but want for some ??
e.g. dper__cross_genome_match_dmelchr__dm for dmelchr names
    dper__match_tblastn_modDM__dm for dmel Gene names; use instead __features__dm ?
**** add config for this;
****

Have gone thru several table variants to get biomart to
find both features and regions with feature matches (bool).
Version 3b works (finally) with proper xml; but drop extra per-feat
_dm tables.  Problems still at region-sequence output (where?)

See scer_mart3b_main.xml

Need this script to write proper xml config for biomart (martedit naive won't do).

Version 4 similar but added extra feat-region key
links, not working right.  Move however the combined feat info
from that to 3b.



=head1 NOTES

Needs lots of config choices for general use, esp. creating
UI parts.  Add as module to GMODTools Bulkfiles with various
config parts.  Add default biomart XML templates.

** ?? for biomart cross-table linking need the _dm tables to have
valid region_id_key entries for all such regions even if no/null values
otherwise attribute outputs do sql join that filters output to only thos
with region matches.

** need separate sequence Perl module to get feature_seq entries (as per Gbrowse)
** need new/revised GFF perl module - current needs Ensembl db fields.

** ??? add GO/OrthoMCL info based on prot. matches 

Used now with biomart martj/bin/marteditor to create
biomart metadata xml for interface after creating mart database.
Found martbuilder not useful enough at present for auto-deciphering
a genome database structure (e.g. chado db).

Mar06 (version 6): change sql to ?? sometimes want nulls, sometimes not
   NOT NULL default '' (or default 0 for int)
   
   
=head1 History
 
Needed genome seq. selector tool for sequence-regions,
rather than gene-centric, for new genomes, any seqregion
interests.  E.g. find all regions with homologs to mosquito but
not to Dmel fruitfly; find regions with SNAP gene predictions but
not Genscan/genewise/... or not homology to known genes (i.e. possible
new genes).

BioMart has useful userinterfaces for such but large time cost getting
data from anything else into its desired structure.

from seqblocks prelim. work at insects.eugenes.org, d.gilbert, aug 2005

cat *.gff | sort -k1,1 -k4,4n -k5,5rn | perl -n seqblockbin > seqblock.gfft
cat seqblock.gfft | sort -k2,2 -k1,1n | perl -n seqblockxml > seqblock.xml

=head1 AUTHOR
  
  Don Gilbert, gilbertd@indiana.edu, 2005/2006.
  
=head1 METHODS

=cut

use strict;
use Getopt::Long;
use FileHandle;
use POSIX;


use constant DEBUG => 1; # 
use constant DROSPEGE => 1;   # insects.eugenes.org rewriting code

use constant REGIONTAB => 1;  # always on now
use constant GFFTAB => 1;     # always on now
use constant SHORT_EXTRATAB => 0; # for $ftkey__dm : all fields or not?

my  $PROGRAM=$0; $PROGRAM =~ s,\S+/,,g,;
my  $BSIZE=5000; # blocksize, is 1Kb better default?
my  $DNACHUNKSIZE= 100000;  # dna chunks? NOTE: THIS NEEDS TO BE IN biomart.genome.xml
my  $MAX_FEATURE_RANGE = 1500000; # skip blocking things bigger than this ?


my @skipattr=qw();
my @chrtype=qw(chromosome chromosome_arm golden_path scaffold); #... more/choice
my @skiptype=qw(chromosome_band BAC match_part);  
my @skipattr=qw(qloc query version atID atsource loc noname species);
my @skipsource=qw( assembly:path );

my @tabletype=qw();  # THESE ARE 'type_source' syntax; FIXME;
                     # feat types to make _dm accessory table for

my %ftinfo=(); ## == main table info
my ($outpath,$version,$fasta);
my $species  =  $ENV{species} || 'noname';  # FIXME; full name
my $label    =  $ENV{label} || ""; #

my $RegionKey   = "Region"; # cant clash with valid feature type?
my $RegionIDKey = "region_id_key"; # in sql
my $StrucKey    = 'features'; #? NOW NOT _main, but _dm
my $StrucIDKey  = "feature_id_key"; # in sql
my $SequenceKey = 'genomic_sequence';  #? not main table, dm ? change to $tablehead_genomic_sequence__xxx__main ??
my $XmlKey      = "BioMart";
my $goldenpathType= 'chromosome'; 
my %goldenpathInfo= ();

my %MainKeys=( $RegionKey=>1, $StrucKey=>1, $SequenceKey => -1, $XmlKey => -1);
my @AllFtKeys=();

my @GFF3ATTR= qw(ID Name Parent Dbxref Target Note); # match structuresql order
my %GFF3ATTR= map{$_,1} @GFF3ATTR;
my @infiles;
my $databasename;
my $datasetid= 1;

my $optok= GetOptions(
  'blocksize=n'   => \$BSIZE,
  'dbname=s'     => \$databasename,
  'datasetid=n' => \$datasetid,
  'fasta=s'     => \$fasta,
  'input=s'     => \@infiles,
  'label=s'     => \$label,
  'output=s'    => \$outpath,
  'skipattr=s'  => \@skipattr,
  'skiptype=s'  => \@skiptype,
  'species=s'   => \$species,
  'tabletype=s'  => \@tabletype,
  'version=s'   => \$version,
  );
sub usage { return
"$PROGRAM: creates biomart table data from genome gff data
 usage:
  -input=gff[.gz] ... feature data including chromosomes: 
    @chrtype 
  -output=$outpath  .. put output tables in this folder
  -fasta=$fasta .. chromosome fasta file[.gz]
  -species=$species .. species prefix for tables
  -label=$label .. label for tables
  -dbname=biomart .. database name
  -datasetid=$datasetid .. datasest ID for biomart
  -version=$version .. version of data
  -blocksize=$BSIZE .. region size
  -tabletype=@tabletype .. list of feature types to make accessory _dm tables
  -skiptype=@skiptype .. list of feature types to skip
  -skipattr=@skipattr .. list of attributes to skip
  "; }
#  -format=main,features   data for main is chromosome.gff
#    'format=s'  => \$outformat,
  
push(@infiles,@ARGV); 
die usage() unless($optok && (@infiles || $fasta)); 

my %chrtype = map{ $_,1; } @chrtype;
my %skiptype= map{ $_,1; } map{ split /[,\s]+/; } @skiptype,@chrtype;
my %skipattr= map{ $_,1; } map{ split /[,\s]+/; } @skipattr;
my %skipsource= map{ $_,1; } map{ split /[,\s]+/; } @skipsource;
@tabletype= map{ split /[,\s]+/; } @tabletype;
my %tabletype= map{ $_,1; } @tabletype;

my $org= $species;
if ($org =~ /^(\w)[^_\s]*[_\s]+(\w{1,3})/) {
 $org= lc("$1$2"); # Gspp 4 letter abbrev.
 }
elsif (length($org)>10 && $org =~ /^(\w{1,4})/) {
 $org= lc("$1"); # Gspp 4 letter abbrev.
 }

my $tablehead= $org; $tablehead.= "_".$label if($label);
$version ||= $org."_1";
$databasename ||= "biomart";  ## FIXME
my $DATE=  POSIX::strftime("%F %T", localtime( $^T ));


#?? $outpath must be directory if exists ??
if($outpath) {
  $outpath .= "/" unless($outpath =~ m,/$,); # fixme
  mkdir($outpath) or die "bad output folder: $outpath" 
    unless(-d $outpath);
}


my $regionoid = 1;
my @regions=();
my %regionhash=();

if($fasta) {
  seqsql();
  seqtab( openin($fasta) );
}

if(@infiles) {
  foreach my $in (@infiles) { gff2featprescan( openin($in)); }
  
  regionsql();
  structuresql();
  featsql();
  
  foreach my $in (@infiles) { gff2featdm( openin($in)); }
  
  regiontab();  
  
  xml_config();
  meta_table_sql(); # ??
}

my $outh = new FileHandle(">${outpath}${tablehead}_loading.info"); 
my $info =  loadinfo();
print $outh $info; 
print $info;


#------------------------------------------------------------
sub loadinfo {
  return "
# EXAMPLE LOADING INSTRUCTIONS ; use with care to existing databases  
# LOAD tables TO MySQL: 

mysqladmin create $databasename
cat ${outpath}/*.sql | mysql $databasename 
mysqlimport $databasename `pwd`/${outpath}/*.txt

# LOAD xml to MySQL $databasename.meta_configuration: 
# BEST USE martj/bin/marteditor.sh to load ${outpath}/*.xml   

# OR try this BUT NOT IF YOU HAVE EXISTING $databasename
# cat ${outpath}${tablehead}_meta.sql_example | mysql $databasename 

# NOTE: dbname=$databasename is included in $SequenceKey.xml
# Change datasetID's in xml, meta.sql if needed
";
}

sub meta_table_sql {

  warn "meta_table_sql \n";
  my $maindataset= $tablehead; #?? 
  my $mainid    = $datasetid; # fixme
  my $dnatable=  $ftinfo{$SequenceKey}->{tabname}; ## need xml dataset name here  not tabname
  (my $dnadataset= $dnatable) =~ s/__(main|dm)$//g;
  my $dnaid    = $datasetid+1; # fixme
  my $mainname= $species; ## $maindataset; # species name; FiXME
  
  my $outsql = new FileHandle(">${outpath}${tablehead}_meta.sql_example"); 
  
  # $ftkey= $SequenceKey."_".$XmlKey;
  my $fullpath=$outpath; 
  unless($fullpath=~m,^/,) {$fullpath=`pwd`;chomp($fullpath);$fullpath.="/$outpath";} ## FiXME: use filetools
  
  my $maintab= $ftinfo{$XmlKey}->{tabname};
  my $dnatab = $ftinfo{$SequenceKey."_".$XmlKey}->{tabname};
 
  
print $outsql <<"EOF";

-- BioMart meta data tables
-- USE martj/bin/marteditor to create ; update

CREATE TABLE meta_interface (
  datasetID int(11) default NULL,
  interface varchar(100) default NULL,
  UNIQUE KEY datasetID (datasetID,interface)
);
INSERT INTO meta_interface values('$mainid','default'),('$dnaid','default');

CREATE TABLE meta_user (
  datasetID int(11) default NULL,
  martUser varchar(100) default NULL,
  UNIQUE KEY datasetID (datasetID,martUser)
);
INSERT INTO meta_user values('$mainid','default'),('$dnaid','default');

CREATE TABLE meta_table_info (
  table_name varchar(100) NOT NULL default '',
  column_name varchar(100) NOT NULL default '',
  column_count int(11) default NULL,
  KEY table_name (table_name),
  KEY table_name_2 (table_name,column_name)
);

-- this is the dataset table; needs XML loaded which is tricky without martj

CREATE TABLE meta_configuration (
  internalName varchar(100) default NULL,
  displayName varchar(100) default NULL,
  dataset varchar(100) default NULL,
  description varchar(200) default NULL,
  xml longblob,
  compressed_xml longblob,
  MessageDigest blob,
  type varchar(20) default NULL,
  visible int(1) unsigned default NULL,
  version varchar(25) default NULL,
  datasetID int(11) NOT NULL default '0',
  modified timestamp NOT NULL default CURRENT_TIMESTAMP
);

INSERT INTO meta_configuration (internalName,displayName,dataset,type,visible,version,datasetID,modified) values ('default','$mainname','$maindataset','TableSet','1','$version', $mainid, '$DATE');
INSERT INTO meta_configuration (internalName,displayName,dataset,type,visible,version,datasetID,modified) values ('default','$mainname DNA','$dnadataset','GenomicSequence','0','$version', $dnaid, '$DATE');

-- -- standard biomart also wants compressed_xml, but i haven't gotten that to work w/o corruption
-- CREATE TABLE tmpxml (xml longblob);
-- LOAD DATA INFILE '$fullpath$maintab.xml' INTO TABLE tmpxml LINES TERMINATED BY '~';
-- UPDATE meta_configuration set xml = (select xml from tmpxml) where datasetID = $mainid;
-- TRUNCATE table tmpxml;
-- LOAD DATA INFILE '$fullpath$dnatab.xml' INTO TABLE tmpxml LINES TERMINATED BY '~';
-- UPDATE meta_configuration set xml = (select xml from tmpxml) where datasetID = $dnaid;
-- DROP TABLE tmpxml;

-- GRANT select on $databasename.* to my_mart_user; -- FIX

EOF

}

sub featkey { 
  my($t, $s)= @_;
  my $ftkey= $t."_".$s; $ftkey =~ s/[.:;,\-]+/_/g;
  return (wantarray) ? ($ftkey, nickname($t,$s)) : $ftkey;
} 

sub nickname { 
  my($t, $s)= @_;
  my $nick= $s; 
  if($nick =~ m/^(\w+):(.+)$/) {
    $nick= substr($1,0,1).$2; #??
    }
  $nick =~ s/[:;,_-]+//g; ## fixme ; need configs
  return $nick;
}

sub openin {
  my @infiles= @_;
  my $infiles = join(" ", map{ split /[,\s]+/; } @infiles );
  (my $inshort= $infiles) =~ s,/\S+/,,g,;
  # warn "openin $inshort\n";
  my $inh;
  if($infiles =~ /\.gz/){
  open(IN, "gunzip -c $infiles  |") or warn "Error:openin gunzip -c $infiles\n"; 
  $inh= *IN;
  } else {
  open(IN, "cat $infiles |") or warn "Error:openin cat $infiles\n"; 
  $inh= *IN;
  }
  return ($inh,$inshort);
}



=item SQL writers

=cut

sub attrsql
{
  my($outh,$ftkey,$atkeys,$prefix)= @_;
  $prefix.="_" if($prefix && $prefix !~ m/_$/); #$prefix ||= "at_";
  foreach my $ak (@$atkeys) {
    print $outh "   ${prefix}${ak} "; ## change this 'at_' prefix; ends up in biomart views
    if($ftinfo{$ftkey}->{istext}->{$ak}) {
      print $outh "text default null"; #? use text instead?
    } elsif($ftinfo{$ftkey}->{ischar}->{$ak}) {
      print $outh "varchar(128) default null"; #? use text instead?
    } elsif($ftinfo{$ftkey}->{isreal}->{$ak}) {
      print $outh "double (32,5) default null";
    } else {
      print $outh "int(10) default null";
    }
    print $outh ",\n";
  }
}

sub structuresql
{
  # if(GFFTAB) 
  my $ftkey= $StrucKey;
  return unless(ref $ftinfo{$ftkey});
  my $outh= $ftinfo{$ftkey}->{outsql};
  my $tabname= $ftinfo{$ftkey}->{tabname} || "${tablehead}__${ftkey}__main"; # no longer __main
  
  ## match this field.txt
  # $oid,$c,$s,$t,$b,$e,$p,$o,$r,$a << gff order fields
  ## ** add GFFv3 ID,Name,Parent,Target,Notes,Dbxref parsed from attribs ..
  @GFF3ATTR= qw(ID Name Parent Dbxref Target Note); # match structuresql order
  %GFF3ATTR= map{$_,1} @GFF3ATTR;
  warn "structuresql $tabname\n";
  print $outh "
  -- written by: $PROGRAM
  -- date: $DATE 
  drop table if exists $tabname;
  create table $tabname (
    region_id_key   int(10) not null,
    feature_id_key   int(10)  not null,
    chr_name    varchar(32) not null,
    source      varchar(64) not null default '', 
    biotype     varchar(32) not null default '',
    type_source varchar(128) not null default '', 
    chr_start   int(10)  not null default 0,
    chr_end     int(10)  not null default 0,
    score       double(32,5)  not null default 0, 
    chr_strand  int(2)  not null default 0,
    chr_phase   int(2)  not null default 0,
    ID          varchar(128) not null default '',
    Name        varchar(128) not null default '',
    Parent      varchar(128) not null default '',
    Dbxref      text  not null default '',
    Target      text  not null default '',
    Note        text  not null default '',
    attributes  text  not null default '',
    ";
  print $outh "     key (region_id_key), \n"; #??
  print $outh "     key (feature_id_key) );\n"; #??
}


sub featsql
{
  ### NOT OFF for v.3b : user selected types for extra tables
  return unless(@tabletype);
  foreach my $ftkey (@AllFtKeys) { ## sort keys %ftinfo
    next unless(grep/^$ftkey/,@tabletype); ## ignore Source; only leading type?
    
    next  if ($MainKeys{$ftkey}); ##($ftkey eq $RegionKey);
    my $outh= $ftinfo{$ftkey}->{outsql};
    my $atkeys= $ftinfo{$ftkey}->{attrkeys};
    my $nickname= $ftinfo{$ftkey}->{nickname};
    my $tabname= $ftinfo{$ftkey}->{tabname} || "${tablehead}__${ftkey}__dm";
    
    ## match this field.txt order
    ##     print $outh join("\t", $oid, $c,$b,$e,$o,$t,$s);
    
    warn "featsql $tabname\n"; ##${tablehead}__${ftkey}__dm\n";
    #? short or long here?
if(SHORT_EXTRATAB) { ## (GFFTAB)  
    print $outh "
    drop table if exists $tabname;
    create table $tabname (
      region_id_key   int(10) not null ,
      feature_id_key  int(10)  not null,
      ";
  } else {
    print $outh "
    drop table if exists $tabname;
    create table $tabname (
      region_id_key   int(10)  not null,
      feature_id_key  int(10)  not null,
      chr_name    varchar(32) not null,
      chr_start   int(10) not null,
      chr_end     int(10) not null,
      chr_strand  int(2) not null  default 0,
      biotype     varchar(32) not null default '',
      source      varchar(64) not null default '', 
      ";
}
  
  ## see xml_extra_filters : use these fields as filters ??
    attrsql($outh,$ftkey,$atkeys,$nickname);
    print $outh "   key (region_id_key), \n"; #??
    print $outh "   key (feature_id_key) );\n"; #??
    }
}


sub regionsql
{
  my $ftkey= $RegionKey;
  return unless(ref $ftinfo{$ftkey});
  
  my $outh= $ftinfo{$ftkey}->{outsql};
  my $tabname= $ftinfo{$ftkey}->{tabname} || "${tablehead}__region__main";
  
  ## match this field.txt
  ## print $outh join("\t",$oid,"$c.$ib",$ib,$se,$c,$len);

  
  ## FIXME:
  ## region_name > region_id       varchar(64),
  ## drop chr_size
  warn "regionsql $tabname\n";
  print $outh "
  -- written by: $PROGRAM
  -- date: $DATE 
  drop table if exists $tabname;
  create table $tabname (
    region_id_key   int(10)  not null,
    region_name     varchar(64)  not null,
    region_start    int(10) not null,
    region_end      int(10) not null,
    chr_name        varchar(40)  not null,
    chr_size        int(10)  not null, 
    ";
  
  #my $atkeys= $ftinfo{$ftkey}->{attrkeys};  
  #skip for region# attrsql($outh,$ftkey,$atkeys);
    
    ## add feature_bool here ?
  print $outh "\n";
  foreach my $ftkey (@AllFtKeys) { ## sort keys %ftinfo
    ## next  if($MainKeys{$ftkey}); #($ftkey eq $RegionKey);
    my $sqlfield= "${ftkey}_bool";
    $ftinfo{$ftkey}->{regionfield}= $sqlfield;
    print $outh "   $sqlfield int(1) default null,\n"
    }
  print $outh "     key (region_id_key) );\n"; #??
}


sub seqsql
{
  my $ftkey= $SequenceKey;
  ## this should be instead
  ## my $tabname= lc("${tablehead}_genomic_sequence__sequence__main"); # ??
  my $tabname= lc("${tablehead}__${ftkey}__dm");  
  my $outh   = new FileHandle(">$outpath$tabname.txt");
  my $outsql = new FileHandle(">${outpath}$tabname.sql"); #$ftinfo{$ftkey}->{outsql};

  my $tabinfo= {
    tabname  => $tabname,
    nickname => $ftkey,
    outh   => $outh,
    outsql => $outsql,
    count => 0,
    oid => 1,
    attrs => {},
    isreal => {},
    isint => {},
    ischar => {},
    istext => {},
    locs => [],
    };
  $ftinfo{$ftkey}= $tabinfo;

  warn "seqsql $tabname\n";
  print $outsql "
  -- written by: $PROGRAM
  -- date: $DATE 
  drop table if exists $tabname;
  create table $tabname (
    region_id_key   int(10)  not null,
    name          varchar(128) not null default '',
    version       varchar(64) not null default '',
    biotype       varchar(255) not null default '',
    description   text not null default '',
    chr_size      int(10) not null, 
    md5checksum   character(32) not null default '',
    chr_start     int(10) not null,
    chunk_size    int(10) not null, 
    residues      longblob  not null default ''
    );";
  # timelastmodified   timestamp
  #print $outsql "     key (region_id_key) );\n"; #??
}



=item Table data subs

=cut

sub writetab
{
  my( $outh, @vals)= @_;
  foreach (@vals) { $_='\N' unless(defined $_); }
  print $outh join("\t",@vals);
}

sub writedna
{
  my( $outh, $oid, $id, $vers, $type, $desc, $md5, $dna)= @_;
  my $len= length($dna);
  # print $outh join("\t",$oid,$id,$vers,$type,$desc,$md5,1,$len,$dna),"\n";
  for (my $start=0; $start < $len;  ) {
    my $csize= $DNACHUNKSIZE;
    if($start+$csize > $len) { $csize= $len - $start; }
    writetab( $outh, $oid,$id,$vers,$type,$desc,$len,$md5, ($start+1), $csize);
    print $outh "\t", substr($dna,$start,$csize),"\n";
    $start += $csize;
    }
}


sub seqtab
{
  my($inh, $iname)= @_;
  warn "seqtab $iname\n";
  my $ftkey= $SequenceKey;
  
  # my $tabname= lc("${tablehead}__${ftkey}__dm");  
  # my $outh = new FileHandle(">${outpath}$tabname.txt"); #$ftinfo{$ftkey}->{outh};
  my $tabname= $ftinfo{$ftkey}->{tabname};
  my $outh   = $ftinfo{$ftkey}->{outh};
  
  my $oid = 1; # what ?? this is 'region_id_key' ?? 
  my $type= $goldenpathType || "chromosome"; # need input info
  my $start= 1; # biomart likes 1-origin
  
  my($id,$dna,$desc,$md5)=('','','','');
  while(<$inh>){
    chomp;
    if(/^>(\S+)\s*(.*)/) {
      my($newid,$newdesc)=($1,$2);
      if($id) {
        writedna( $outh, $oid, $id, $version, $type, $desc, $md5, $dna);
        # my $len= length($dna);
        # print $outh join("\t",$oid,$id,$version,$type,$desc,$md5,$start,$len,$dna),"\n";
        }
      $id= $newid; $desc= $newdesc; $dna='';
      if($desc =~ s/MD5=(\w+)[;]?//i){ $md5=$1; } else { $md5='\N'; }
      $desc =~ s/CRC64=\w+[;]?//; $desc =~ s/size=\w+[;]?//; # hack fix
      }
    elsif(/^\w/){
      $dna.= $_; #? check junk?
      }
    }
  if($id){
    writedna( $outh, $oid, $id, $version, $type, $desc, $md5, $dna);
    # my $len= length($dna);
    # print $outh join("\t",$oid,$id,$version,$type,$desc,$md5,$start,$len,$dna),"\n";
    }
  close($inh); close($outh);
}



sub attrhash 
{
  my @at= map { split (/;\s*/,$_) } @_;
  my %at= ();
  foreach (@at) {
    my($k,$v)=split(/=/,$_,2); 
    next unless(defined $v && $v ne '.' && $v ne '');
    if($k eq 'db_xref'){ $k='Dbxref'; }
    ## fixme for lowcase of GFF3 'name', 'id', 'db_xref', 'note'
    elsif($k =~ m/^[a-z]/ && $GFF3ATTR{ucfirst($k)}) { $k= ucfirst($k); }
    if(defined $at{$k}){ $at{$k} .=",".$v; } else { $at{$k} = $v ; }
    }
  attrib4drospege(\%at) if(DROSPEGE);
  return %at;
}

sub attrib4drospege
{
  my $at= shift;
  ## drop  Protein '-PA' tag from Name, ID like fields, otherwise ID search is messy
  ## biomart could use regexp/wildcard searches.
  $at->{ID}   =~ s/\-[RP]\w$// if($at->{ID});
  $at->{Name} =~ s/\-[RP]\w$// if($at->{Name});
  # also Dbxref ?
}

sub gffcols
{
  # my ($c,$s,$t,$b,$e,$p,$o,$r,$a)
  my @v= split "\t",$_[0],9; #gff cols
  foreach (@v) { $_=undef if($_ eq '.'); }
  unless($v[6]=~/\d/) { $v[6]= ($v[6] eq '+') ? 1 : ($v[6] eq '-') ? -1 : 0; }
  return @v;
}



## need 1-origin not 0-origin for blocks !!
sub calcregion { 
  if (wantarray) {
    my($b,$e)= @_;
    my @rg=();
    for (my $i= 1 + $BSIZE * int($b/$BSIZE) ; $i < $e; $i += $BSIZE) { push(@rg,$i); }
    return @rg;
  } else {
    return 1 + $BSIZE * int($_[0]/$BSIZE); 
  }
}

sub overlaps {
  my($sb,$se,$tb,$te)= @_;
  return ($tb <= $se && $te >= $sb);
}


sub newtab 
{
  my($ftkey,$nickname)= @_;

  my $ismain= ($MainKeys{$ftkey});
  my $suf= ($ftkey eq $StrucKey) ? "dm"
    : ($ismain) ? "main" : "dm"; ##($ftkey eq $RegionKey) 
  my $tabname= lc("${tablehead}__${ftkey}__${suf}");

  ## v4/3b drop some/all ftkey_dm tabs /
  my $makeout= ($ismain) || $tabletype{$ftkey};
  my $outh   = ($makeout) ? new FileHandle(">$outpath$tabname.txt") : undef;
  my $outsql = ($makeout) ? new FileHandle(">$outpath$tabname.sql") : undef;

  my $tabinfo= {
    tabname  => $tabname,
    nickname => $nickname,
    outh   => $outh,
    outsql => $outsql,
    count => 0,
    oid => 1,
    attrs => {},
    isreal => {},
    isint => {},
    ischar => {},
    istext => {},
    locs => [],
    };
  return $tabinfo;
}


=item GFF to Table data

=cut

=item gff2featprescan

  need to know about features before writing; read thru gff twice
  
=cut

sub gff2featprescan
{
  my($inh, $iname)= @_;
  warn "gff2featprescan $iname\n";
  
  # my %ftinfo=(); ## use global
  unless($ftinfo{$StrucKey}) {
    $ftinfo{$StrucKey}= newtab($StrucKey,$StrucKey);
    }

  while(<$inh>){
    next if(/^#/);
    chomp;
    my ($c,$s,$t,$b,$e,$p,$o,$r,$a)= gffcols($_); #split "\t",$_,9; #gff cols
    
    my $ftkey= featkey($t,$s);
    if($e && $chrtype{$t}) {
      $ftkey= $RegionKey; ## ??
      my $len= $e - $b + 1;
      $goldenpathType= $t; # could be many.
      $goldenpathInfo{$c}= { name => $c, type=>$t, source => $s, start=>$b, end=>$e, size=>$len };
      }
    elsif(!$e || $skiptype{$t} || $skipsource{$s}) {
      next; #?? should these be saved ??
      }

    ## $featureInfo{$ftkey}= { type=>$t, source => $s, } ## use ftinfo
    
    ## write new table for each "$t.$s" group
    unless($ftinfo{$ftkey}) {
      my $nickname= nickname($t,$s);
      $ftinfo{$ftkey}= newtab($ftkey,$nickname);
      $ftinfo{$ftkey}->{type}= $t; #?
      $ftinfo{$ftkey}->{source}= $s; #?
      }
    
    if($ftkey eq $RegionKey) {
      ##if(REGIONTAB)     
      # what? need to make region table now for crossrefs in _dm ?
      my $len= $e - $b + 1;
      my $links=""; # place holder; #5
      my @rblocks= calcregion($b,$e); 
      foreach my $ib (@rblocks) {
        my $ie= $ib + $BSIZE - 1; $ie= $e if ($ie>$e);
        # push(@regions, [$regionoid,$c,$ib,$ie,$len,$links]);
        my $regionkey= "$c.$ib";
        push(@regions, $regionkey); # keep input order
        $regionhash{$regionkey} = [$regionoid,$c,$ib,$ie,$len,$links]; # instead of @regions
        $regionoid++;
        }
    }
    
    $ftinfo{$ftkey}->{count}++;
    my %at= attrhash($a, ((defined $p)?"score=$p":"")); 
    foreach my $ak (sort keys %at) { 
      next if $skipattr{$ak};
      my $av= $at{$ak}; 
      next unless(defined $av && $av ne '.');
      $ftinfo{$ftkey}->{attrs}->{$ak}++; 
        if ($av =~ m/^[-+]?\d+$/) { $ftinfo{$ftkey}->{isint}->{$ak}++; }
      elsif($av =~ m/^[-+]?\d[\d\.e\-]+$/i) { $ftinfo{$ftkey}->{isreal}->{$ak}++; }
      elsif(length($av) > 128) { $ftinfo{$ftkey}->{istext}->{$ak}++; }
      elsif($av =~ m/\D/) { $ftinfo{$ftkey}->{ischar}->{$ak}++; }
      }
    }

  @AllFtKeys= grep { !$MainKeys{$_} } (sort keys %ftinfo);
    
  foreach my $ftkey (@AllFtKeys) { 
    my @at = sort keys %{ $ftinfo{$ftkey}->{attrs} };
    $ftinfo{$ftkey}->{attrkeys} = \@at;
    }
  close($inh); 
  ## return \%ftinfo;
}

=item regiontab

  write main table of region information
  
=cut

sub regiontab
{
  warn "regiontab\n";
  my $ftkey= $RegionKey;
  my $outh = $ftinfo{$ftkey}->{outh};
  ## use input order# my @regions= sort keys %regionhash; # sort not numeric
  foreach my $r (@regions) {
#   push(@regions, [$regionoid,$c,$ib,$ie,$len,$links]);
    my $rv= $regionhash{$r}; 
    my($regionoid,$c,$ib,$ie,$len,$links)= @$rv;
    writetab( $outh, $regionoid,"$c.$ib",$ib,$ie,$c,$len);

    ## ?? add all the _bool values here ? need region list in prescan then
    foreach my $ftkey (@AllFtKeys) { ## sort keys %ftinfo
      ## next  if($MainKeys{$ftkey}); #($ftkey eq $RegionKey);
      my $hits= ($links =~ m/\b$ftkey\b/) ? '1' : '\N'; ## urk value of NULL not 0 is off;
      print $outh "\t$hits"; 
      }
    print $outh "\n";
  }
}

=item gff2featdm

  write common feature table (gff) and maybe per-feature subtables;
  collect feature->region map info.
  
=cut

sub gff2featdm
{
  my($inh, $iname)= @_;
  warn "gff2featdm $iname\n";
    
  while(<$inh>){
    next if(/^#/);
    chomp;
    my ($c,$s,$t,$b,$e,$p,$o,$r,$a)= gffcols($_); 
    
    my $ftkey= featkey($t,$s);
    if( $e && $chrtype{$t}) {
      $ftkey= $RegionKey; 
      }
    
    elsif(!$e || $skiptype{$t} || $skipsource{$s}) {
      next; #?? should these be saved ??
      }

    # rows per attrib
    my %at= attrhash($a, ((defined $p)?"score=$p":"")); 
    my $featoid = 0;
    
    if(1) { # (GFFTAB)  
  # print struct main table of all features
    $featoid  = $ftinfo{$StrucKey}->{oid}++; #?? use this one for feat oid
    my $outh  = $ftinfo{$StrucKey}->{outh};

    my $rblock= calcregion($b,$e); # first only
    my $regionkey= "$c.$rblock";
    my $rvals= $regionhash{$regionkey};  
    my $regionoid= $rvals->[0] || '\N'; ## shouldnt be dupl.
    
    ## split out these gff3 tags from $a: ID,Name,Dbxref,Note,Parent,Target
    ## fixme for locase of GFF3 'name', 'id', 'db_xref', 'note'
    my %at2= attrhash($a); 
    my @atlist= map{ (defined $at2{$_}) ? delete $at2{$_} : '\N'; } @GFF3ATTR;
    my $amore = join(";", map { "$_=$at2{$_}" }(sort keys %at2));

    ## can we add 1 regionoid here that feature matches? will it help?
    writetab( $outh, $regionoid, $featoid, 
      $c,$s,$t,$ftkey,$b,$e,$p,$o,$r,@atlist,$amore); # same as gff order 
      ## BUT added $ftkey = type_source for feature filtering 
    print $outh "\n";
    }
    
  # -- collect region info and maybe write ftkey tab
  # print region dm tables for each feat type

    if($ftkey eq $RegionKey) {

    } else {  
      next  if($MainKeys{$ftkey});
      next if($e - $b > $MAX_FEATURE_RANGE); #? skip godawfullong ones/some errors?

      my $outh = $ftinfo{$ftkey}->{outh};
      my $atkeys= $ftinfo{$ftkey}->{attrkeys};

      my @hitblocks= calcregion($b,$e);
      foreach my $rblock (@hitblocks) { ## loop over feat row adding each regionoid
        my $regionkey= "$c.$rblock";
        my $rvals= $regionhash{$regionkey};  
        my $regionoid= $rvals->[0] || '\N'; ## shouldnt be dupl.
        $rvals->[5] .= $ftkey.",";
        
    # FIXME: dropped featuretype__dm, but want for some ??
    # e.g. dper__cross_genome_match_dmelchr__dm for dmelchr names
    
        next unless($tabletype{$ftkey}); 

  ## drop this extra table data? only need 3 tabs: region, feature, dna
if(SHORT_EXTRATAB) {
        writetab( $outh, $regionoid, $featoid);  
} else {
        writetab( $outh, $regionoid, $featoid, $c,$b,$e,$o,$t,$s);  
}        
        foreach my $ak (@$atkeys) {
          my $av= $at{$ak}; $av= '\N' unless(defined $av); 
          print $outh "\t$av";
          }
        print $outh "\n";
        } 
    }
  }
  close($inh); 
}




=item Biomart XML configs

=cut

sub xml_config
{
  my $xmlkey= $XmlKey;
  my $tabname= lc("${tablehead}__${xmlkey}");
  my $outh   = new FileHandle(">$outpath$tabname.xml");
  
  my $tabinfo= {
    tabname  => $tabname,
    nickname => $xmlkey,
    outh   => $outh,
    # outsql => $outsql,
    count => 0,
    oid => 1,
    attrs => {},
    isreal => {},
    isint => {},
    ischar => {},
    istext => {},
    locs => [],
    };
  $ftinfo{$xmlkey}= $tabinfo;

  warn "xml_config $tabname\n";
  xml_header($xmlkey);
  xml_filter_page($xmlkey);
  xml_attr_pages($xmlkey);
  xml_footer($xmlkey);

  #-- write dna dataset.xml
  $xmlkey= $SequenceKey."_".$XmlKey;
  $tabname= lc("${tablehead}__${xmlkey}");
  $outh   = new FileHandle(">$outpath$tabname.xml");
  $tabinfo= {
    tabname  => $tabname,
    nickname => $xmlkey,
    outh   => $outh,
    # outsql => $outsql,
    count => 0,
    oid => 1,
    attrs => {},
    isreal => {},
    isint => {},
    ischar => {},
    istext => {},
    locs => [],
    };

  $ftinfo{$xmlkey}= $tabinfo;
  warn "xml_config $tabname\n";
  xml_seqconfig($xmlkey);
}


sub xml_header
{
  my($xmlkey)= @_;
  my $outh = $ftinfo{$xmlkey}->{outh};
  my $tabname=  $ftinfo{$RegionKey}->{tabname};
  my $dataset= $tablehead; #?? 
  my $did    = $datasetid; # fixme
  
print $outh <<"EOF";
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE DatasetConfig>
<DatasetConfig 
  dataset="$dataset" 
  datasetID="$did" 
  displayName="$species" 
  version="$version"
  type="TableSet"  
  visible="1"
  interfaces="default" internalName="default" martUsers="default" modified="$DATE" 
  >
<!--  
written by: $PROGRAM
date: $DATE
-->
  
<MainTable>$tabname</MainTable>
<Key>region_id_key</Key>  

<Exportable attributes="rg_chr_name,rg_region_start,rg_region_end" 
  default="1" internalName="raw_sequence" linkName="raw_sequence" linkVersion="$version" 
  name="raw_sequence" orderBy="rg_chr_name" />
<Exportable attributes="rg_chr_name,rg_region_start,rg_region_end,ft_chr_strand" 
  default="0" internalName="oriented_raw_sequence" linkName="oriented_raw_sequence" linkVersion="$version" 
  name="oriented_raw_sequence" orderBy="rg_chr_name" />

<Exportable attributes="ft_id_key,ft_chr_name,ft_chr_start,ft_chr_end,ft_chr_strand" 
  internalName="gene_exon_intron" linkName="gene_exon_intron" linkVersion="$version" 
  name="gene_exon_intron"  orderBy="ft_id_key" default="1" />
<Exportable attributes="ft_id_key,ft_chr_name,ft_chr_start,ft_chr_end,ft_chr_strand" 
  internalName="gene_flank" linkName="gene_flank" linkVersion="$version" 
  name="gene_flank" orderBy="ft_id_key" default="0" />

EOF

}

sub xml_footer
{
  my($xmlkey)= @_;
  my $outh = $ftinfo{$xmlkey}->{outh};
  print $outh <<"EOF";

</DatasetConfig>
EOF
}

sub xml_filter_page
{
  my($xmlkey)= @_;
  my $outh = $ftinfo{$xmlkey}->{outh};
  print $outh <<"EOF";
<FilterPage displayName="FILTERS" internalName="filterpg">
EOF
  xml_feature_filter($xmlkey);
  xml_region_range_filter($xmlkey);
  xlm_region_contains_filter($xmlkey);
  xml_extra_filters($xmlkey) if(@tabletype);
  
  print $outh <<"EOF";
</FilterPage>

EOF
}

sub xml_extra_filters
{
  my($xmlkey)= @_;
  my $outh = $ftinfo{$xmlkey}->{outh};
  
print $outh <<"EOF";

<FilterGroup displayName="EXTRA FILTERS:" internalName="exfilterg">
<FilterCollection displayName="Extra Features" internalName="exfeatures_col">
EOF

  foreach my $tabkey (@tabletype) {
    my $tabname=  $ftinfo{$tabkey}->{tabname};
    my $atkeys = $ftinfo{$tabkey}->{attrkeys};
    my $prefix= $ftinfo{$tabkey}->{nickname};
    $prefix.="_" if($prefix && $prefix !~ m/_$/);  
    foreach my $ak (@$atkeys) {
      my $atfld="${prefix}${ak}"; 
     (my $fname= ucfirst($atfld)) =~ s/_/ /g;
print $outh <<"EOF";
<FilterDescription displayName="$fname" field="$atfld" 
 internalName="${tabname}_${atfld}" key="region_id_key" tableConstraint="$tabname"
 legal_qualifiers="=" qualifier="="  type="text" />
EOF
      }
    }

print $outh <<"EOF";
</FilterCollection>
</FilterGroup>
EOF

}

sub xml_feature_filter
{
  my($xmlkey)= @_;
  my $outh = $ftinfo{$xmlkey}->{outh};
  my $tabname=  $ftinfo{$StrucKey}->{tabname};
print $outh <<"EOF";

<FilterGroup displayName="FILTER by FEATURE:" internalName="ftfilterg">
<FilterCollection displayName="Feature Type(s)" internalName="Features_col">
<FilterDescription displayName="Feature type" field="type_source" 
 internalName="biotype_multi_list" key="region_id_key" tableConstraint="$tabname"
 legal_qualifiers="=,in" qualifier="="  type="list">
EOF

  foreach my $ftkey (@AllFtKeys) { ## sort keys %ftinfo
    #my $type  = $ftinfo{$ftkey}->{type};
    #my $source= $ftinfo{$ftkey}->{source} || ".";
    #my $fname= "$type:$source";
    (my $fname= ucfirst($ftkey)) =~ s/_/ /g;
    print $outh <<"EOF";
  <Option displayName="$fname" internalName="$ftkey"  value="$ftkey" />
EOF
  }

print $outh <<"EOF";
</FilterDescription>
</FilterCollection>
</FilterGroup>
EOF

}

sub kbsizeof {
  my($n)= shift;
  if($n>=1000000) { $n= int($n/1000000)."M"; }
  elsif($n>=1000) { $n= int($n/1000)."K"; }
  return $n;
}

sub xml_region_range_filter
{
  my($xmlkey)= @_;
  my $outh = $ftinfo{$xmlkey}->{outh};

print $outh <<"EOF";

<FilterGroup displayName="FILTER GENOME REGION:" internalName="grfilters">
<FilterCollection displayName="Chromosome" internalName="rgchrcol">
<FilterDescription displayName="Chromosome" field="chr_name" 
 internalName="rgchr_multi_list" key="region_id_key" 
 legal_qualifiers="=,in" qualifier="=" 
 tableConstraint="main" type="list">
EOF

  my @chrs= (sort keys %goldenpathInfo);
  my $toomany= (@chrs > 50);
  if ($toomany) { # got a genome-in-progress ... pick only biggest
    my @topchr= sort{ $goldenpathInfo{$b}->{size} <=> $goldenpathInfo{$a}->{size} }  
       @chrs;
    @chrs= splice(@topchr,0,50);
    }
  foreach my $chr (@chrs) {  
    my $cname= $chr; 
    $cname .=" ".kbsizeof( $goldenpathInfo{$chr}->{size} ) if($toomany);
    # ($cname= ucfirst($cname)) =~ s/_/ /g;
print $outh <<"EOF";
    <Option displayName="$cname" internalName="$chr" value="$chr" />
EOF
  }
  
print $outh <<"EOF";
</FilterDescription>
<FilterDescription displayName="Region Start &gt;=" field="region_start" internalName="region_start" key="region_id_key" 
  legal_qualifiers="&gt;=" qualifier="&gt;="  tableConstraint="main" type="text" />
<FilterDescription displayName="Region End &lt;=" field="region_end" internalName="region_end" key="region_id_key" 
  legal_qualifiers="&lt;=" qualifier="&lt;=" tableConstraint="main" type="text" />

<FilterDescription displayName="Chrom. Size &gt;=" field="chr_size" internalName="hi_chr_size" key="region_id_key" 
  legal_qualifiers="&gt;=" qualifier="&gt;="  tableConstraint="main" type="text" />
<FilterDescription displayName="Chrom. Size &lt;=" field="chr_size" internalName="low_chr_size" key="region_id_key" 
  legal_qualifiers="&lt;=" qualifier="&lt;=" tableConstraint="main" type="text" />
</FilterCollection>
</FilterGroup>
EOF

}

sub xlm_region_contains_filter
{
  my($xmlkey)= @_;
  my $outh = $ftinfo{$xmlkey}->{outh};

print $outh <<"EOF";

<FilterGroup  displayName="FILTER REGIONS WITH FEATURES: (include,exclude)" internalName="rgfeatflt">
<FilterCollection displayName="Feature LIST" internalName="id_list">
<FilterDescription  internalName="id_multilist_filters" type="boolean_list">
EOF
  foreach my $ftkey (@AllFtKeys) { ## sort keys %ftinfo
    my $fld= $ftinfo{$ftkey}->{regionfield};
    next unless($fld);
    (my $fname= ucfirst($fld)) =~ s/_/ /g;
    if($fname =~ s/ bool$//) { $fname="Has $fname";}
print $outh <<"EOF";
    <Option displayName="$fname" field="$fld" internalName="f_$fld" isSelectable="true" key="region_id_key" 
    legal_qualifiers="only,excluded" qualifier="only" tableConstraint="main" type="boolean" />
EOF
    }
print $outh <<"EOF";
</FilterDescription>
</FilterCollection>
</FilterGroup>
EOF

# and another one, diff iname
print $outh <<"EOF";

<FilterGroup  displayName="FILTER REGIONS WITH FEATURES:  (include,exclude)" internalName="rgfeatflt">
<FilterCollection displayName="Feature LIST" internalName="id2_list">
<FilterDescription  internalName="id2_multilist_filters" type="boolean_list">
EOF
  foreach my $ftkey (@AllFtKeys) { ## sort keys %ftinfo
    my $fld= $ftinfo{$ftkey}->{regionfield};
    next unless($fld);
    (my $fname= ucfirst($fld)) =~ s/_/ /g;
    if($fname =~ s/ bool$//) { $fname="Has $fname";}
    
print $outh <<"EOF";
    <Option displayName="$fname" field="$fld" internalName="f2_$fld" isSelectable="true" key="region_id_key" 
    legal_qualifiers="only,excluded" qualifier="only" tableConstraint="main" type="boolean" />
EOF
    }
print $outh <<"EOF";
</FilterDescription>
</FilterCollection>
</FilterGroup>
EOF

}

sub xml_attr_pages
{
  my($xmlkey)= @_;
  xml_featattr_page($xmlkey);
  xml_featseq_page($xmlkey);
  xml_regionattr_page($xmlkey);
  xml_regionseq_page($xmlkey);
}


sub xml_featattr_page
{
  my($xmlkey)= @_;
  my $outh = $ftinfo{$xmlkey}->{outh};
  my $tabname=  $ftinfo{$StrucKey}->{tabname};
print $outh <<"EOF";

<AttributePage displayName="FEATURE TABLE" internalName="ftattr_page" outFormats="html,txt,csv,tsv,xls">
<AttributeGroup displayName="FEATURE TABLE" internalName="ftattr_grp">
<!-- not quite gff; biomart gff printer is unusable w/o rewrite  -->
<AttributeCollection displayName="Common Features" internalName="Features_ac">
<AttributeDescription default="true" displayName="Chromosome" field="chr_name" internalName="at_chr_name" key="region_id_key" tableConstraint="$tabname" maxLength="32" />
<AttributeDescription default="true" displayName="Source" field="source" internalName="at_source" key="region_id_key" tableConstraint="$tabname" maxLength="128" />
<AttributeDescription default="true" displayName="Biotype" field="biotype" internalName="at_biotype" key="region_id_key" tableConstraint="$tabname" maxLength="128" />
<AttributeDescription default="true" displayName="Start" field="chr_start" internalName="at_chr_start" key="region_id_key" tableConstraint="$tabname" maxLength="10" />
<AttributeDescription default="true" displayName="End" field="chr_end" internalName="at_chr_end" key="region_id_key" tableConstraint="$tabname" maxLength="10" />
<AttributeDescription default="true" displayName="Strand" field="chr_strand" internalName="at_chr_strand" key="region_id_key" tableConstraint="$tabname" maxLength="2" />
<AttributeDescription default="true" displayName="Score" field="score" internalName="at_score" key="region_id_key" tableConstraint="$tabname" maxLength="10" />
<AttributeDescription default="true" displayName="ID" field="id" internalName="at_id" key="region_id_key" tableConstraint="$tabname" maxLength="128" />
<AttributeDescription default="true" displayName="Name" field="Name" internalName="at_Name" key="region_id_key" tableConstraint="$tabname" maxLength="128" />
<AttributeDescription default="true" displayName="Dbxref" field="Dbxref" internalName="at_Dbxref" key="region_id_key" tableConstraint="$tabname" maxLength="128" />
<AttributeDescription default="true" displayName="Note" field="Note" internalName="at_Note" key="region_id_key" tableConstraint="$tabname" maxLength="128" />
<AttributeDescription default="true" displayName="Other Attributes" field="attributes" internalName="at_attributes" key="region_id_key" tableConstraint="$tabname" maxLength="128" />
<!-- Parent; Target; -->
</AttributeCollection>
</AttributeGroup>
</AttributePage>
EOF
}


sub xml_featseq_page
{
  my($xmlkey)= @_;
  my $outh = $ftinfo{$xmlkey}->{outh};
  my $tabname=  $ftinfo{$StrucKey}->{tabname};
  my $dnadataset=  $ftinfo{$SequenceKey}->{tabname}; ## need xml dataset name here  not tabname
  $dnadataset =~ s/__(main|dm)$//g;
  
print $outh <<"EOF";

<AttributePage displayName="FEATURE SEQUENCE" internalName="fsq_pg" outFormats="fasta">
<AttributeGroup displayName="FEATURE SEQUENCE" internalName="fsq_grp">

<AttributeCollection default="true"  displayName="Feature Sequence" internalName="seq_scope_type" maxSelect="1">
<AttributeDescription displayName="Feature span"  internalName="$dnadataset.gene_exon_intron" key="region_id_key" tableConstraint="$tabname" />
<AttributeDescription displayName="Feature flank" internalName="$dnadataset.gene_flank" key="region_id_key" tableConstraint="$tabname"  />
</AttributeCollection>

<AttributeCollection displayName="Upstream flank" internalName="upstream" maxSelect="0">
<AttributeDescription default="100" displayName="Upstream flank1" internalName="$dnadataset.filter.upstream_flank" />
</AttributeCollection>
<AttributeCollection displayName="Downstream flank" internalName="downstream" maxSelect="0">
<AttributeDescription default="100"  displayName="Downstream flank1" internalName="$dnadataset.filter.downstream_flank" />
</AttributeCollection>

<AttributeCollection displayName="Header Information" internalName="ft_header_info" maxSelect="0">
<AttributeDescription default="true" displayName="Chromosome" field="chr_name" internalName="ft_chr_name" key="region_id_key" tableConstraint="$tabname" maxLength="10" />
<AttributeDescription default="true" displayName="Start" field="chr_start" internalName="ft_chr_start" key="region_id_key" tableConstraint="$tabname" maxLength="10" />
<AttributeDescription default="true" displayName="End" field="chr_end" internalName="ft_chr_end" key="region_id_key" tableConstraint="$tabname" maxLength="10" />
<AttributeDescription default="true" displayName="Strand" field="chr_strand" internalName="ft_chr_strand" key="region_id_key" tableConstraint="$tabname" maxLength="2" />
  <!-- this is needed for link to seq by feature id ? -->
<AttributeDescription hideDisplay="true" default="true" displayName="Ft_ID (required)" 
  field="feature_id_key" internalName="ft_id_key" key="region_id_key" tableConstraint="$tabname" maxLength="10" /> 
<AttributeDescription default="true" displayName="Biotype" field="biotype" internalName="ft_biotype" key="region_id_key" tableConstraint="$tabname" maxLength="128" />
<AttributeDescription default="true" displayName="Source" field="source" internalName="ft_source" key="region_id_key" tableConstraint="$tabname" maxLength="128" />
<AttributeDescription default="true" displayName="ID" field="id" internalName="ft_id" key="region_id_key" maxLength="128" tableConstraint="$tabname" />
<AttributeDescription default="true" displayName="Name" field="Name" internalName="ft_Name" key="region_id_key" maxLength="128" tableConstraint="$tabname" />
<AttributeDescription default="true" displayName="Dbxref" field="Dbxref" internalName="ft_Dbxref" key="region_id_key" maxLength="128" tableConstraint="$tabname" />
<AttributeDescription displayName="Score" field="score" internalName="ft_score" key="region_id_key" tableConstraint="$tabname" maxLength="32" />
<AttributeDescription displayName="Note" field="Note" internalName="ft_Note" key="region_id_key" maxLength="128" tableConstraint="$tabname" />
<AttributeDescription displayName="Other Attributes" field="attributes" internalName="ft_attributes" key="region_id_key" tableConstraint="$tabname" maxLength="128" />
</AttributeCollection>
</AttributeGroup>
</AttributePage>

EOF
}

sub xml_regionattr_page
{
  my($xmlkey)= @_;
  my $outh = $ftinfo{$xmlkey}->{outh};
  # my $tabname=  $ftinfo{$StrucKey}->{tabname};
print $outh <<"EOF";

<AttributePage displayName="REGION TABLE" internalName="rgattr_page" outFormats="html,txt,csv,tsv,xls">
<AttributeGroup displayName="REGION TABLE" internalName="rgattr_grp">

<AttributeCollection displayName="Region location" internalName="Region">
<AttributeDescription displayName="Region ID" field="region_name" internalName="region_name" key="region_id_key" maxLength="64" tableConstraint="main" />
<AttributeDescription default="true" displayName="Region chr" field="chr_name" internalName="rg_chr_name" key="region_id_key" maxLength="40" tableConstraint="main" />
<AttributeDescription default="true" displayName="Region start" field="region_start" internalName="region_start1" key="region_id_key" maxLength="10" tableConstraint="main" />
<AttributeDescription default="true" displayName="Region end" field="region_end" internalName="region_end1" key="region_id_key" maxLength="10" tableConstraint="main" />
</AttributeCollection>

<AttributeCollection displayName="Region contains" internalName="Regioncont">
EOF

  foreach my $ftkey (@AllFtKeys) { ## sort keys %ftinfo
    my $fld= $ftinfo{$ftkey}->{regionfield};
    next unless($fld);
    (my $fname= ucfirst($fld)) =~ s/_/ /g;
    if($fname =~ s/ bool$//) { $fname="Has $fname";}
print $outh <<"EOF";
  <AttributeDescription default="true" displayName="$fname" field="$fld" internalName="a_$fld" 
    key="region_id_key" maxLength="1" tableConstraint="main" />
EOF
    }

print $outh <<"EOF";
</AttributeCollection>
</AttributeGroup>
</AttributePage>

EOF
}

sub xml_regionseq_page
{
  my($xmlkey)= @_;
  my $outh = $ftinfo{$xmlkey}->{outh};
  my $dnadataset=  $ftinfo{$SequenceKey}->{tabname}; ## need xml dataset name here  not tabname
  $dnadataset =~ s/__(main|dm)$//g;
print $outh <<"EOF";
<AttributePage displayName="REGION SEQUENCE" internalName="sequences" outFormats="fasta">
<AttributeGroup displayName="REGION SEQUENCE" internalName="sequence">

<!-- having problems with this selector -->
<AttributeCollection  displayName="REGION Sequence" internalName="seq_scope_type" maxSelect="1">
<AttributeDescription displayName="Region sequence" internalName="$dnadataset.raw_sequence" key="region_id_key"  tableConstraint="main" />
<!-- AttributeDescription  displayName="Oriented sequence"  internalName="$dnadataset.oriented_raw_sequence" key="region_id_key"  tableConstraint="main" / -->
</AttributeCollection>

<AttributeCollection displayName="Header Information" internalName="rg_header_info" maxSelect="0">
<AttributeDescription default="true" displayName="Scaffold" field="chr_name" internalName="rg_chr_name" key="region_id_key" maxLength="128" tableConstraint="main" />
<AttributeDescription default="true" displayName="Start" field="region_start" internalName="rg_region_start" key="region_id_key" maxLength="128" tableConstraint="main" />
<AttributeDescription default="true" displayName="End" field="region_end" internalName="rg_region_end" key="region_id_key" maxLength="128" tableConstraint="main" />
</AttributeCollection>

</AttributeGroup>
</AttributePage>
EOF
}

sub xml_seqconfig
{
  my($xmlkey)= @_;
  my $outh = $ftinfo{$xmlkey}->{outh};
  # my $databasename= $tablehead . "_" .$version;  ## FIXME - global
  my $dnatable=  $ftinfo{$SequenceKey}->{tabname}; ## need xml dataset name here  not tabname
  (my $dnadataset= $dnatable) =~ s/__(main|dm)$//g;
  my $did    = $datasetid + 1; # fixme
  
print $outh <<"EOF";
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE DatasetConfig>
<DatasetConfig 
  dataset="$dnadataset" 
  datasetID="$did" 
  displayName="$species genomic DNA" 
  version="$version"
  type="GenomicSequence"  
  optional_parameters="$databasename.$dnatable,name,chr_start,residues,$DNACHUNKSIZE" 
  visible="0"
  interfaces="default" internalName="default" martUsers="default" modified="$DATE" 
  >
<!--  
written by: $PROGRAM 
date: $DATE
-->

<!-- note filter keys are tied to software: GenomicSequence.pm + dnaextractor -->
<Importable filters="pkey,chr,start,end,strand" internalName="gene_flank" 
  linkName="gene_flank" linkVersion="$version" name="gene_flank" orderBy="pkey" />
<Importable filters="pkey,chr,start,end,strand" internalName="gene_exon_intron" 
  linkName="gene_exon_intron" linkVersion="$version" name="gene_exon_intron" orderBy="pkey" />

<Importable filters="chr,start,end,strand" internalName="oriented_raw_sequence" 
  linkName="oriented_raw_sequence" linkVersion="$version" name="oriented_raw_sequence" />
<Importable filters="chr,start,end" internalName="raw_sequence" linkName="raw_sequence" 
  linkVersion="$version" name="raw_sequence" />

<!-- // no good for prots; need exon-rank; phase?; type??, codon,seq_edits are options -->
<!--
<Importable filters="pkey,chr,start,end,strand" internalName="gene_exon" 
  linkName="gene_exon" linkVersion="$version" name="gene_exon" orderBy="pkey" />
<Importable filters="pkey,chr,start,end,strand" 
  internalName="peptide" linkName="peptide" linkVersion="$version" name="peptide" orderBy="pkey" />
<Importable filters="pkey,chr,start,end,strand" internalName="coding" 
  linkName="coding" linkVersion="$version" name="coding" orderBy="pkey" />
-->

<FilterPage displayName="FILTERS FOR LINKS" internalName="link_filters">
<FilterGroup description="Filters for Links" internalName="link_filters">
<FilterCollection internalName="link_filters">
<FilterDescription internalName="phase" type="list" />
<FilterDescription internalName="codon_table_id" type="list" />
<FilterDescription internalName="pos" type="list" />
<FilterDescription internalName="allele" type="list" />
<FilterDescription internalName="pkey" type="list" />
<FilterDescription internalName="chr" type="list" />
<FilterDescription internalName="start" type="list" />
<FilterDescription internalName="end" type="list" />
<FilterDescription internalName="strand" type="list" />
<FilterDescription internalName="rank" type="list" />
<FilterDescription internalName="seq_edits" type="list" />
<FilterDescription internalName="type" type="list" />
<FilterDescription displayName="Upstream flank" internalName="upstream_flank" legal_qualifiers="=" qualifier="=" type="list" />
<FilterDescription displayName="Downstream flank" internalName="downstream_flank" legal_qualifiers="=" qualifier="=" type="list" />
</FilterCollection>
</FilterGroup>
</FilterPage>

<AttributePage displayName="ATTRIBUTES FOR LINKS" internalName="link_attributes">
<AttributeGroup description="Attributes for Links" internalName="link_attributes">
<AttributeCollection internalName="link_attributes">
<AttributeDescription internalName="codon_table_id" />

<AttributeDescription datasetLink="raw_sequence" internalName="raw_sequence" />
<AttributeDescription datasetLink="oriented_raw_sequence" internalName="oriented_raw_sequence" />
<AttributeDescription datasetLink="gene_exon_intron" displayName="Unspliced (Gene)" internalName="gene_exon_intron" />
<AttributeDescription datasetLink="gene_exon" displayName="Exon sequences (Gene)" internalName="gene_exon" />
<AttributeDescription datasetLink="gene_flank" displayName="Flank (Gene)" internalName="gene_flank" />
<AttributeDescription displayName="upstream_flank" internalName="upstream_flank" />
<AttributeDescription displayName="downstream_flank" internalName="downstream_flank" />
<AttributeDescription datasetLink="coding" displayName="Coding sequence" internalName="coding" />
<AttributeDescription datasetLink="coding_gene_flank" displayName="Flank-coding region (Gene)" internalName="coding_gene_flank" />
<AttributeDescription datasetLink="peptide" displayName="Peptide" internalName="peptide" />

<AttributeDescription displayName="pkey" internalName="pkey" />
<AttributeDescription displayName="chr" internalName="chr" />
<AttributeDescription displayName="start" internalName="start" />
<AttributeDescription displayName="end" internalName="end" />
<AttributeDescription displayName="strand" internalName="strand" />
<AttributeDescription displayName="rank" internalName="rank" />
<AttributeDescription internalName="seq_edits" />
<AttributeDescription internalName="type" />
</AttributeCollection>
</AttributeGroup>
</AttributePage>

</DatasetConfig>
EOF

}




1; # turn into perl module
##=================================

