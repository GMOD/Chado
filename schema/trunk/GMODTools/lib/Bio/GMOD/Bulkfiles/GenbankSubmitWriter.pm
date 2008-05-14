package Bio::GMOD::Bulkfiles::GenbankSubmitWriter;

use strict;

use constant FIXME => 1;

=head1 NAME

  Bio::GMOD::Bulkfiles::GenbankSubmitWriter  
  
=head1 SYNOPSIS
  
  use Bio::GMOD::Bulkfiles;       
  
  my $bulkfiles= Bio::GMOD::Bulkfiles->new( 
    configfile => 'mymodconfig', 
    );
    
  my $result= $bulkfiles->makeFiles( 
    formats => [ qw(genbanktbl)] , 
    );
    
=head1 NOTES

  subclassed from FeatureWriter (gff+fff), which deserves rewrite
  
=head1 TEST CASES
  
  perl -Ilib  bin/bulkfiles.pl -config sgdtest -format=genbanktbl -debug -make

  # get AnoGam chrX and load to chado db
  curl -OR ftp://bio-mirror.net/biomirror/ncbigenomes/Anopheles_gambiae/CHR_X/NC_004818.gbk.gz

  set dbname=anogam_x
  $pg/bin/createdb -T chado_01_template $dbname
  
  # fix Genbank FT to SO type map
  vi  lib/Bio/SeqFeature/Tools/TypeMapper.pm : add pseudogenic tRNA
 
  # load Anopheles gambia chromosome X to chado
  gunzip -c NC_004818.gbk.gz |\
   perl bin/bp_genbank2gff3.pl -noCDS -in stdin -out stdout |\
   perl bin/gmod_bulk_load_gff3.pl -dbname $dbname -organism fromdata 
  
  # create GMOD Bulkfiles conf/anogam.xml from template.xml : dbname, etc. edits
  
  # create Bulkfiles outputs for anogam_x
  perl -Ilib bin/bulkfiles.pl -config=anogam -debug -make >& log.anogam1 &
  # and now genbank table
  perl -Ilib bin/bulkfiles.pl -config=anogam -format=genbanktbl -debug -make  

  
=head1 AUTHOR

D.G. Gilbert, 2008, gilbertd@indiana.edu

=head1 METHODS

=cut

#-----------------


# debug
#use lib( "/bio/argos/common/perl/lib", "/bio/argos/common/system-local/perl/lib");
#use lib( "/bio/argos/gmod/gmtmp/lib");

use POSIX;
use FileHandle;
use File::Spec::Functions qw/ catdir catfile /;
use File::Basename;

use Bio::GMOD::Bulkfiles::BulkWriter;       
use base qw(Bio::GMOD::Bulkfiles::FeatureWriter);
#was use base qw(Bio::GMOD::Bulkfiles::BulkWriter);

our $DEBUG = 1;
my $VERSION = "1.2";
use constant BULK_TYPE   => 'genbanktbl';#??
use constant CONFIG_FILE => 'genbanksubmit'; #?? or other

use constant TOP_SORT => -9999999;
use constant MAX_FORWARD_RANGE => 990000; # at 500000 lost a handful of oidobs refs; maximum base length allowed for collecting forward refs
use constant MIN_FORWARD_RANGE =>  20000; # minimum base length for collecting forward refs

#........... super vars; move some out
our $maxout;
our $ntotalout;

our $chromosome;  ## read info from chado dump chromosomes.tsv 

our $fff_mergecols;  
our $gff_keepoids;  
our @outformats; 
our @defaultformats;
our %formatOk;  
our @fclone_fields;

our $outfile;
our $append;

our %gffForwards;
our @gffForwards;
our %maptype_gb;

## our == global scope; use vars == package scope
use vars qw/ 
  %maptype      
  %maptype_pattern
  %mapname_pattern
  %mapattr_pattern
  %maptype_gff  
  %segmentfeats 
  %simplefeat   
  %skipaskid    
  %dropfeat_fff 
  %dropfeat_gff  %oidisid_gff
  %dropid  %nameisid     
  %dropname     
  %mergematch   
  %hasdups  
  %keepstrand
  $rename_child_type
  $name2type_pattern
  @GModelParts
  %GModelParents
  $CDS_spanType
  $CDS_exonType
  /;

#............... super vars .................


sub init 
{
	my $self= shift;
  $self->SUPER::init();
	$self->{outh} = {};
  $DEBUG= $self->{debug} if defined $self->{debug};
  $self->setDefaultValues(); #?? use or not? hold-over from pre-config work

}


=item initData

initialize data from config

=cut

our $tbl2asn;

sub initData
{
  my($self)= @_;
  my $config = $self->{config};
  my $sconfig= $self->handler_config;

  @defaultformats= ( BULK_TYPE() ); #'genbanktbl' 
  %formatOk= ( 
    BULK_TYPE() => 1,
  ); # only these handled here ?

  @outformats=  @{ $config->{outformats} || \@defaultformats } ; 
  $config->{outformats}= \@outformats; #?? need this before super init; fixme
  %maptype_gb  = %{ $config->{'maptype_gb'} } if ref $config->{'maptype_gb'};
  
  $self->SUPER::initData();


  my $blasthome= $config->{blasthome} ; # try $ENV{BLAST_HOME} or other??  
  $tbl2asn= $config->{tbl2asn} || "$blasthome/tbl2asn";
  unless(-e $tbl2asn) { 
    warn "Missing tbl2asn: $tbl2asn"; 
    $self->status(-1,"missing tbl2asn"); 
    }
    
  my $tbl2asnopts= $config->{tbl2asnopts} || '-V v ';   
  $config->{tbl2asnopts}= $tbl2asnopts;

}


#-------------- subs -------------

sub tbl2asn 
{
	my $self= shift;
	my( $seqlist, $subdir, $blastname)= @_;
	warn "tbl2asn( $blastname )\n" if $DEBUG;
	my $opts= $self->getconfig('tbl2asnopts');  

# this works: $nb/tbl2asn -t template.sbt -V vb -p ./  
# with inputs:
# drosmelgb-all-drosmelgb4.tbl
# drosmelgb-all-drosmelgb4.fsa == ../fasta/drosmelgb-all-chromosome-drosmelgb4.fasta
# drosmelgb-all-drosmelgb4.pep == ../fasta/drosmelgb-all-translation-drosmelgb4.fasta
# template.sbt

  warn("#$blastname:  $tbl2asn $opts \n") if $DEBUG;
	my $olddir= $ENV{'PWD'};  #?? not safe?
  chdir($subdir);  
  
#   foreach (@$seqlist) {
#     $_ = catfile($olddir,$_) unless($_ =~ m,^/,);
#     }
#   my $seqlib = join(" ",@$seqlist);
#   my $cat= ($seqlib =~ /\.(gz|Z)/) ? 'gunzip -c' : 'cat';
    
  my $ok= system("$tbl2asn $opts ");
  
  ##opendir(D,"."); my @f= grep(/stdin/,readdir(D)); closedir(D);
  ##foreach my $f (@f) { (my $t= $f) =~ s/stdin/$blastname/; rename($f,$t); }

  chdir($olddir);
}


=item  makeFiles( %args )

  primary method
  makes  bulk genome sequence files in standard formats.
  input file sets are intermediate chado db dump tables.
  
  arguments: 
  infiles => \@fileset,   # required
  formats => [ 'gff', 'fff' ] # optional

=cut

# subclass: this one could be inherited
sub makeFiles
{
	my $self= shift;
  my %args= @_;  
  my $fileset = $args{infiles};
  my $chromosomes = $args{chromosomes};
  my $intype= $self->config->{informat} || 'feature_table'; #? maybe array

  # 0710: no_csomesplit : no perchr files, only makeall
  my $no_csomesplit= $self->handler_config->{no_csomesplit} || 0; # FIXME: 0710
  my $makeall= !$no_csomesplit && !$args{noall} && ($self->config->{makeall} || $self->{gff_config}->{makeall});

  $self->{append}=1 if($no_csomesplit); #?????? TEST ME

  unless(@$fileset) { 
    $fileset = $self->handler->getFiles($intype, $chromosomes);  
    unless(@$fileset) { 
      warn "GenbankSubmitWriter: no input '$intype' files found\n"; 
      return $self->status(-1);
      }
    }
 
  my @saveformats= @outformats;
  if ($args{formats}) {
    my $formats= $args{formats};
    @outformats= (ref $formats) ? @$formats : ($formats);
    }
  @outformats= grep { $formatOk{$_} > 0 }  @outformats;
  
  ## messy; but see  $args{filesetinfo} $args{name}
  if($args{name} && $args{filesetinfo}) {
    $self->{fileset}{ $args{name} }= $args{filesetinfo};
  }
  foreach my $fmt (@outformats) {
    my $outset = $self->handler->getFilesetInfo( $fmt ); # genbanktbl
    $self->{fileset}{$fmt}= $outset if($outset);
    }
  
  print STDERR "GenbankSubmitWriter::makeFiles outformats= @outformats\n" if $DEBUG; 

  
  my $status= 0;
  my $ok= 1;
  for (my $ipart= 0; $ok; $ipart++) {
    $ok= 0;
    my $inh= $self->openInput($fileset, $ipart);
    if ($inh) {
      my $res= $self->processChadoTable( $inh);
      close($inh);
      $status += $res;
      $ok= 1;
      }
    }
    
  if ($makeall && $status > 0) {
    foreach my $fmt (@outformats) { 
      $self->makeall( $chromosomes, "", $fmt); 
      }
    }


  ## need also symlink fasta/chrom.fa and fasta/translate.fa to genbanksubmit/.fsa,.pep
  
  $self->handler->writeDocs( $self->config->{doc} );   # submit template.sbt


  @outformats = @saveformats;
  print STDERR "GenbankSubmitWriter::makeFiles: done n=$status\n" if $DEBUG; 
  return  $self->status($status); #?? check files made
}



## just now can do only for gff; leave fff split by chr
# sub makeall 
# {
# 	my $self= shift;
#   my( $chromosomes, $feature, $format )=  @_;
#   return if ($format eq 'fff');
#   $feature= ""; 
#   $self->{curformat}= $format;
#   $self->config->{path}= $format; #???? # setconfig ??
#   print STDERR "makeall: $format\n" if $DEBUG; 
#   $self->SUPER::makeall($chromosomes, $feature, $format); #?? not seen
#   $self->{curformat}= '';  
#   $self->config->{path}= ''; #???? # setconfig ??
# }
  
  
=item openInput( $fileset, $ipart )

  handle input files
  
=cut

# sub openInput
# {
# 	my $self= shift;
#   my( $fileset, $ipart )= @_; # do per-csome/name
#   my $inh= undef;
#   return undef unless(ref $fileset);
# 
#   my $intype= $self->config->{informat} || 'feature_table'; #? maybe array
#   my $atpart= 0;
#   # print STDERR "openInput: type=$intype part=$ipart \n" if $DEBUG; 
#   
#   foreach my $fs (@$fileset) {
#     my $fp= $fs->{path};
#     my $name= $fs->{name};
#     my $type= $fs->{type};
#     next unless($fs->{type} eq $intype); 
#     unless(-e $fp) { warn "missing dumpfile $fp"; next; }
#     $atpart++;
#     next unless($atpart > $ipart);
#     print STDERR "openInput[$ipart]: name=$name, type=$type, $fp\n" if $DEBUG; 
# 
#     if ($fp =~ m/\.(gz|Z)$/) { open(INF,"gunzip -c $fp|"); }
#     else { open(INF,"$fp"); }
#     $inh= *INF;
#     
#     my ($sfile, undef) = File::Basename::fileparse($fp);
#     $self->{sourcefile}= $sfile;
#     
#     return $inh; # only 1 at a time FIXME ...
#     }
#   print STDERR "openInput: nothing matches part=$ipart, type=$intype\n" if $DEBUG; 
#   return undef;  
# }

=item openCloseOutput($outh,$chr,$flags)

  handle output files
  
=cut

# sub openCloseOutput
# {
# 	my $self= shift;
#   my($outh,$chr,$flags)=  @_;
#   my $chrfile= $chr;
#   my $app= defined $self->{append} ? $self->{append} : $append;
#   # 0710: no_csomesplit : no perchr files, only makeall
#   my $no_csomesplit= $self->handler_config->{no_csomesplit} || 0; # FIXME: 0710
#   if( $no_csomesplit ) {
#     $app= 1;
#     $chrfile="all"; # or "sum" ??
#     }
#     
#   if ($outh && $flags =~ /open|close/) {
#     foreach my $fmt (@outformats) {
#       close($outh->{$fmt}) if ($outh->{$fmt});
#       }
#     }
#     
#   $outh= {};  
#   if ($flags =~ /open/) {
#     $chrfile='undef' unless($chrfile);
#     #?? for unsorted input need to change $append to true after first open?
#     foreach my $fmt (@outformats) {
#       ## need option to append or create !?
#       my $ap=($app) ? ">>" : ">";
#       my $fn;
#       if ($outfile) { $fn="$outfile-$chrfile.$fmt"; }
#       else { $fn= $self->get_filename( $self->{org}, $chrfile, '', $self->{rel}, $fmt); }
# 
#       ##? check for $self->handler()
#       my $subdir= $fmt; ##($fmt eq 'fff') ? 'gnomap' : $fmt; #? fixme 
#       my $featdir= $self->handler()->getReleaseSubdir( $subdir);   
#       my $fpath = catfile( $featdir, $fn);
#       
#       my $exists= ($app && -e $fpath) ? 1 : 0;
#       print STDERR "# output $fpath (append=$exists)\n" if $DEBUG;
#       $outh->{$fmt}= new FileHandle("$ap$fpath");
#       $self->writeHeader($outh,$fmt,$chr,$exists); ## unless($exists);
#       }
#     }
#   return $outh;
# }


=item remapXXX
  
  processChadoTable handlers to fix various table inputs, according to config mappings
  
=cut

# sub remapId
# {
# 	my $self= shift;
#   my ($type,$id,$name)= @_;
#   my $save= $id;
#   if (($nameisid{$type}) && $name) { $id= $name; } ## ? not for gff 
#   elsif ($dropid{$type} || $id =~ /^NULL:/ || $id =~ /^:\d+/) { $id= undef; }
#   #?? or not# elsif (!$id) { $id= $name; } 
#   return ($id,$save);
# }


# sub remapName
# {
# 	my $self= shift;
#   my ($type,$name,$id,$fulltype)= @_;
#   my $save= $name;
#   
#   if ( $dropname{$type} ) { $name= ''; }
#   
#   ## handle stupid match name = all the match type + ...
#   ## clean unwieldy predictor names: contig...contig...
#   elsif ($type =~ /^(gene|mRNA)/ && $name =~ s/Contig[_\d]+//g) { 
#     ##if ($name =~ m/^(twinscan|genewise|genscan)/i) { $name= "${id}_${name}"; }
#     if ($name =~ m/^(twinscan|genewise|genscan|piecegenie)/i) { $name= "${id}_$1"; }
#     }
#   elsif (!$name) { $name= $id unless ($id =~ /^NULL:/i || $id =~ /^:\d+/); } 
#     ## dmelr4.1 ; must apply below name patches to id (no name)
#   
#     ## this one could be time sink .. use evaled sub {} ?
#   foreach my $mp (sort keys %mapname_pattern) {
#     next if ($mp eq 'null'); # dummy?
#     my $mtype= $mapname_pattern{$mp}->{type};
#     next if ($mtype && $type !~ m/$mtype/);
#     if ($mapname_pattern{$mp}->{cuttype}) {
#       my @tparts= split(/[_:.-]/, $type);
#       push(@tparts, split(/[_:.-]/, $fulltype) ); #??
#       foreach my $t (@tparts) { $name =~ s/\W?$t\W?//; }
#       next;
#       }
#     my $from= $mapname_pattern{$mp}->{from}; next unless($from);
#     my $to  = $mapname_pattern{$mp}->{to};
#     if ($to =~ /\$/) { $name =~ s/$from/eval($to)/e; }
#     else { $name =~ s/$from/$to/g; }
#     }
#   
#   return ($name,$save);
# }

=item remapArm

  2       3       segment Contig3266_Contig6542   -       complement(3..1555441)  Contig3266_Contig654
  2               
  2       1555569 segment Contig143_Contig447     -       complement(1555569..2614209)    Contig143_Contig447         
   
  -- unordered contigs -- singles (? no feats) and doubles - put into common out files?
  -- if so, need to offset start/end to fit into unorderd 'chromosome'
  Contig1090      1       contig  -       -       1..211  Contig1090      GB:AADE01008166;        
  Contig2258_Contig2260   1       contig  -       -       1..3082 Contig2258      GB:AADE01005006;
  
  # Double Dang - need to use segment offset/strand to map segment features

=cut

# sub remapArm
# {
# 	my $self= shift;
#   my ($arm,$fmin,$fmax,$strand)= @_;
#   my $save= $arm;
#   my $armfile= $arm;
# 
# #   my $rf= $armContigs{$arm};
# #   if ($rf) {
# #     my($armr,$b,$e,$st,$contig)= @$rf;
# #     $arm= $armr;
# #     if ($st eq '-') { #?? do we need to flip all - min,max relative to arm.e ?
# #       $strand= -$strand;
# #       ($fmax,$fmin) = ($e - $fmin-1, $e - $fmax-1);
# #       }
# #     else {
# #       $fmin += $b - 1;
# #       $fmax += $b - 1;
# #       }
# #     }
# #   $armfile=$arm;
# #   
# #   ## need to fix dmel synteny.dump to not put gene name => arm for ortho:nnn
# #   if ($arm eq $save) {
# #     if (lc($org) eq 'dmel' && $arm =~ m/\-/) { # -PA .. others -xxx ?
# #       $armfile= 'genes';
# #       }
# #     elsif ($arm =~ m/^Contig[^_]+_Contig/) {
# #       $armfile= 'unordered2';
# #       }
# #     elsif ($arm =~ m/^Contig\w+/) {
# #       $armfile= 'unordered1';
# #       }
# #     }
# 
#   return($arm,$fmin,$fmax,$strand,$armfile,$save)  
# }



=item remapType 


Types from name ... only when needed
  Dpse uses gene  name_(genscan|genewise|twinscan) ...
  Dmel uses mRNA  name-(genscan|piecegenie) ...
    ?? anything with '-dummy-' in name is computed type?
    for Dpse which has gene ..., need to reType mRNA kids also

  mRNA    13903,12560-AE003590.Sept-dummy-piecegenie
  mRNA    15793,12560-AE003590.Sept-dummy-genscan
  transposable_element Name=JOSHTRANSPOSON-jockey{}277-pred
  transposable_element DBID=TE19092;Name=jockey{}277;cyto_range=21A3-21A3;Dbxref="FlyBase:FBti0019092";Dbxref="Gadfly:TE19092";gbunit=AE003590


Handle more complex types

change this to allow complex type:subtype:.. for analysis, other features
with pseudo-type like 'match:program:source'
want final gff-type/source 'match',fgenesh{_source} or fgenesh:source
want final fff-type  match_fgenesh{_source} or match:fgenesh{_source} ?
check how both gbrowse_fb and gnomap read/handle types

gnomap/annomap -- underscores generally used but '.' also 
  ## remap FBan.acode PRG:DB choices
  blastx_masked_aa_SPTR.worm=blastx_otherspp
  blastx_masked_aa_SP.hyp.dros=blastx_dros
  sim4_na_EST.all_nr.dros=EST
  genscan_dummy=genscan

=cut

#s subclass: use remapType for SeqOnto -> Genbank FT map?

sub remapType
{
	my $self= shift;
  my ($type,$name)= @_;

  return $self->SUPER::remapType(@_);
  #... or ....

#   my $save= $type;
#   $type =~ s/\s/_/g; # must change?
#   
#     ## this one could be time sink .. use evaled sub {} ?
#   foreach my $mp (keys %maptype_pattern) {
#     next if ($mp eq 'null');  
#     my $mname= $maptype_pattern{$mp}->{typename};
#     next if ($mname && $name !~ m/$mname/);
#     my $from= $maptype_pattern{$mp}->{from};
#     my $to  = $maptype_pattern{$mp}->{to};
#     $type =~ s/$from/$to/;
#     }
# 
#   my $nutype  = $type;
#   # this should be config pattern: ..genscan..
#   ##if (defined $name && $name =~ m/[-_](genscan|piecegenie|twinscan|genewise|pred|trnascan)/i) {
#   if ($name2type_pattern && defined $name && $name =~ m/$name2type_pattern/i) {
#     $nutype .= "_".lc($1);
#     }
#   $nutype =~ s/[:\.]/_/g; #?
#   $type = $maptype{$nutype} || $type;
#   
#   my $fulltype = $type; #?? here or what.
#   $type =~ s/[:\.]/_/g; #?
#   
#   return ($type,$fulltype,$save);

}


=item processChadoTable

 Read input feature table, write bulk output formats FFF and GFF 
 (other formats are derived from these)
 This step takes longest, e.g. ~ 20 hr on single cpu for D. melangaster.
 Split by chromosome data among processors to speed up.
 
 Joins table lines/feature; builds compound features; checks feature names/types, etc.
 
 Input chado feature table dump format (see sql)
 arm     fmin    fmax    strand  type         name       id        oid      attr_type     attribute
 2L      0       305900  1       golden_path  AE003590   AE003590  1273141  various_key   value

 Outputs: FFF (also used for fasta, gnomap), GFF
 
 FIXME: something here gets very memory piggy, slow, with input feature tables
  full of match: analysis types (messy names, types, etc.)
  -- no feats written to fff in many hours !? - due to holding BAC and cytoband features
  -- try dropping gffForwards; maybe better (gff written) but still memuse balloons
  -- added clearFinishedObs() - no apparent help; dont see what else is holding objects here
   -- ok now, added min base loc to keep in oidobs, delete all before
       runs fast - chr 3L in 10 min. instead of >2hr.
  
=cut



sub handleAttrib
{
	my $self= shift;
  my($addattr, $attr_type, $attribute, $fobadd)=  @_;

  # nasty fix for _Escape ; to_name=Aaa,CGid should probably be two table lines
  if ($attr_type eq 'to_name' && $attribute =~ /,/) {
    my $attr1; ($attr1,$attribute)= split(/,/,$attribute,2);
    push( @$addattr, "$attr_type\t$attr1");
    }

  foreach my $mp (sort keys %mapattr_pattern) {
    next if ($mp eq 'null'); # dummy 
    my $mtype= $mapattr_pattern{$mp}->{type};
    next if ($mtype && $attr_type !~ m/$mtype/);
    my $from= $mapattr_pattern{$mp}->{from}; next unless($from);
    my $to  = $mapattr_pattern{$mp}->{to};
    if ($to =~ /\$/) { $attribute =~ s/$from/eval($to)/e; }
    else { $attribute =~ s/$from/$to/g; }
    }

  if ($attr_type eq 'dbxref' && $attribute =~ /^GFF_source:(\S+)/) {
    if($fobadd) { $fobadd->{gffsource} = $1; } 
    $attribute='';
    }
    
  push( @$addattr, "$attr_type\t$attribute") if $attribute;  
}


#s subclass: this main sub needs revisions

sub processChadoTable
{
	my $self= shift;
  my($fh, $outh)=  @_;
   
  $outh= $self->{outh} unless(ref $outh);
  my %origin_one= %{ $self->config->{origin_one} || {} };
  my $utrpatch= $self->config->{utrpatch} ; 
  my $intronpatch= $self->config->{intronpatch} ; 
    # patch for intron type; oct04: fmin - no+1,fmax, add+1
  my $nozombiechromosomes= $self->config->{nozombiechromosomes};
    # dpse chado duplicate 0-length chromosome entries
    
  my $tab= "\t"; # '[\|]'; ##"\t"; < '|' is bad sep cause some names have it !

  my @fobs=();
  my %oidobs=(); # this hash will grow big; can we delete before next chr ?
  my $fob= undef;
  my $max_max=0; my $min_max= 0;
  my $armlen=0;
  my $ndone= 0;
  my ($l_arm,$l_oid,$l_fmin,$l_fmax,$l_type)= (0,0,0);
  my ($arm,$fmin,$fmax,$strand,$type,$name,$id,$oid,$attr_type,$attribute) ;
  my($s_type, $fulltype, $s_arm, $armfile, $s_name, $s_id);
  my ($fin,$fhpeek);
  my %addfob=();
  
  #? use line buffer @fhpeek to grep for missing forward refs ? eg. PA for mRNA ?
  $self->{linebuf}= [];

  while( $fin= $self->getline($fh) ) {
    $_= $fin;
    $ndone++; 
    my @addattr=();

    ## loop here over <$fh> while $oid == $l_oid  
    ## only part changing is $attr_type/$attribute
    my $sameoid= 0;
    do { 
    ($arm,$fmin,$fmax,$strand,$type,$name,$id,$oid,$attr_type,$attribute) 
      = split("\t",$fin);  

    $self->handleAttrib(\@addattr,$attr_type,$attribute,\%addfob) if ($attribute);

    ## inner read loop problem? need to process parent_oid attrib only once below  
    my $nextin= $self->peekline(0) || "";
    my $joid=  index($nextin,"$id\t$oid\t");
    $sameoid= ($joid>0);
    if ($sameoid) {
      my $ioid= index($fin,"$id\t$oid\t");
      $sameoid= ($ioid==$joid && substr($nextin,0,$ioid) eq substr($fin,0,$ioid) );
      if ($sameoid) { $fin= $self->popline(); }
      }

    } while ($sameoid);
    
    #my $tss= ($DEBUG && $type eq 'transcription_start_site');
    #warn ">tss1: $arm,$fmin,$type,$name,$oid,$l_oid\n" if $tss; 

    ## data fixes
    ## dpse chado has chromosomes of fmin=1; fmax = NULL ! no length; drop these (dupl)
    if ($nozombiechromosomes && $segmentfeats{$type} && $fmax <= $fmin) {
      ($l_oid,$l_fmin)= (-1,$fmin);
      next;
      } 
    
    if( !defined $fmax ) { $fmax=0; }
    if( !defined $fmin ) { $fmin=0; }
    elsif ($intronpatch && $type eq 'intron') { $fmax += 1; }
    elsif ($utrpatch && $type =~ /_prime_untranslated_region|_prime_UTR/) { 
      $fmin= $fmax if ($fmax == $fmin-1); 
      }
    elsif( ! ($origin_one{$type} || $fmin == $fmax) ) { $fmin += 1; } # dang -1 chado start
    if( !defined $strand )  { $strand=0; }
    
    # feb05: the zero-base insertion sites ( fmin==fmax ) should not have fmin+1 adjustment
    # 2L      131986  131986  1       1       transposable_element_insertion_site

    ## this check only for intron,UTR chado-computed locs ??
    ## also looks like computed UTR's can be off by 1 out of gene bounds, if UTR == 0
    ## CG2657 = 2L:21918..23888 ;  exon1 = 22983..23888 ; exon2 = 21918..22687
    ## dmel_chado says -u3 = 21918..21917<too low
    ##  -u5 = too high>23889..23888 ; -intron = no+1>22688..22982  
    if ($fmax < $fmin) { 
      ($fmin,$fmax)= ($fmax,$fmin); 
      $strand= ($strand==0) ? -1 : -$strand; 
      }
    
#     ($arm,$fmin,$fmax,$strand,$armfile,$s_arm)  
#       = $self->remapArm($arm,$fmin,$fmax,$strand); # for dpse joined contigs 

    ($type,$fulltype,$s_type)= $self->remapType($type,$name); 
    
    if (!$type && $DEBUG && !/NULL|repeatmask/) { print STDERR "missing type: $_\n";  } ##<< repeatmasker kid objs
    if ($type eq 'skip' || !$type) { # or what? undef? got some bad feats w/ no type??
       ## dont keep old oid: ($l_arm,$l_oid,$l_fmin)= ($arm,$oid,$fmin);
       ##dont save arm for skip !? if changed here, cant miss below openout..
      ($l_oid,$l_fmin)= (-1,$fmin);
	    next;
	    }
    
    # ($id,$s_id)= $self->remapId($type,$id,$name); 

    ($name,$s_name)= $self->remapName($type,$name,$id,$fulltype); 
    
    ## dmelr4.1 patch; cant do this for all dropid - gff needs real ids for exons for instance
    #if (($dropid{$type} || $nameisid{$type}) && $name) { $id= $name; } ## 
    ## do this in remapId ..
    ## if (($nameisid{$type}) && $name) { $id= $name; } ## ? not for gff 

    my $loc="$fmin\t$fmax\t$strand";
    
      # dmelr4.1 - need add band attrib even if attrib == parent_oid
    if ($type eq 'chromosome_band') { ##  && !$attribute
      my $battr_type = 'cyto_range';
      my $battribute = $s_name;  
      $battribute =~ s/(cyto|band|\-)//g;
      push( @addattr, "$battr_type\t$battribute");  
      $name =~ s/\-cyto//;
      }

      
## find quicker way to screen out many match_ dup things ; same simple loc, no id...
## # hasdups -- need to check id == l_id, name = l_name ..
##     match_blastn_na_dbEST_dpse="1"
##     match_sim4_na_dbEST_same_dmel="1"

    ## ? do something like this also for EST, protein which differ only by dbxref id
    ## i.e. feature is location w/ several items matching
    ## need to turn name/id into dbxref attrib
    ## feats: processed_transcript , EST, protein
    
    ## some chado exons, introns are dupl of same data... diff uniquename for no useful reason
    ## also check for $oidobs{$oid}->{fob};
    if ($oid ne $l_oid && ! $simplefeat{$type} 
        && exists $oidobs{$oid}->{fob}) {
      my $ok=0;
      foreach my $dob (@fobs) {
        if ($dob->{oid} eq $oid) { $ok=1; last; }
        }
      if ($ok) {
        $fob= $oidobs{$oid}->{fob};
        $oid= $l_oid= $fob->{oid};
        }
      else {
      ## FIXME - bad if fob not in @fobs 
      ## .. e.g. repeat region - many locs over arm, few oid's
      ## most of these we dont want to join - too far apart; need max_max setting below to keep small ranges together?
        # print STDERR "missed join to last $type,$name,$oid\n" if $DEBUG;
        }
      }
    
    if ($oid ne $l_oid && $hasdups{$type}) {
      foreach my $dob (@fobs) {
        next unless($dob->{type} eq $type);
        my $dloc= $dob->{loc}->[0];
        my($dmin,$dmax,$dstrand)= split("\t",$dloc);
        if ( $dmin eq $fmin 
          && $dmax eq $fmax 
          && $dstrand eq $strand
          ) {
            $fob= $dob;
            $oid= $l_oid= $fob->{oid};
            last;
            }
        }
      }
      #warn ">tss2d: new $arm,$fmin,$oid,$l_oid\n" if $tss;

   ## all TSS has same oid now !????  -- odd bug $l_oid == $oid
    if ( $oid eq $l_oid ) {
      # same object - cat attributes into one set
      push( @{$fob->{loc}},  $loc) unless(grep /$loc/,@{$fob->{loc}});  
      #warn ">tss2S: new $arm,$fmin,$oid,$l_oid\n" if $tss;
      foreach my $fk (keys %addfob) { $fob->{$fk}= $addfob{$fk}; } %addfob=();
      }
      
    else {
      
      ## new feature object here ..
      
      if ($arm ne $l_arm) {
        $self->putFeats($outh,\@fobs,\%oidobs,'final'); 
        undef @fobs;  @fobs=();
        undef %oidobs; %oidobs=();
        undef %gffForwards; %gffForwards=();
        $max_max=0; $min_max= 0;

        $outh= $self->openCloseOutput($outh, $arm, 'open');
        }
                
      my $flushok= ($fmin >= $max_max && $fmin > $min_max && scalar(@fobs)>5);
      if ($flushok) {
        if ($self->hasObForwards(\@fobs, \%oidobs)) {
          $flushok = 0;
          $min_max= $fmin + 2000; ##smaller step so we dont miss chance to flush
          }
        warn "hasObForwards no=$flushok at $fmin $type:$name $oid\n" if ($DEBUG>1);
        }
        
      if ($flushok) { 
        ##warn "flushobs at $fmin $type:$name $oid\n" if $DEBUG;
        my ($nstart, $nleft, $nobs)=(0,0,0);
        if ($DEBUG>1) { $nobs= scalar(@fobs); }
        
        $self->putFeats( $outh, \@fobs, \%oidobs, ''); 
        undef @fobs; @fobs=();  
        $min_max= $fmin + MIN_FORWARD_RANGE; #?? will this help join parts
        
        ## %oidobs will grow big; 
        ## can we clear out other obs yet: %oidobs=(); %gffForwards=();  if no forwards ?
        if ($DEBUG>1) { while( each %oidobs ){ $nstart++; }}
        
        my $clearflag= 'writefff';
        my $nclear= 0;
        $nclear= $self->clearFinishedObs( $clearflag, \%oidobs, $fmin - MAX_FORWARD_RANGE);
        if ($DEBUG>1) {
          while( each %oidobs ){ $nleft++; } 
          print STDERR " printed n=$nobs; oidobs: pre-clear=$nstart, cleared=$nclear, left=$nleft\n";
          print STDERR " fmin=$fmin, fmax=$fmax, l_fmin=$l_fmin, min_max=$min_max, max_max=$max_max\n";
          }
        }

      my $newob= {};  
      push(@fobs,$newob);
      $fob= $newob;
      foreach my $fk (keys %addfob) { $fob->{$fk}= $addfob{$fk}; } %addfob=();
      
        #?? dont add here if it is simple feature; wait till know if it is parent or kid?
        # this is bad for 'gene' NOT? simple feat
      unless( $simplefeat{$type} ) { 
        $oidobs{$oid}->{fob}= $newob; 
        }

      # my @fclone_fields = qw(chr type fulltype name id oid fmin fmax offloc attr writefff writegff);
      $fob->{chr} = $arm;
      $fob->{type}= $type;  
      $fob->{fulltype}= $fulltype;  # colon-delimited complex type 'match:program:source' 
      $fob->{name}= $name;
      $fob->{id}  = $id;
      $fob->{oid} = $oid;
      $fob->{fmin}= $fmin;
      $fob->{fmax}= $fmax;
      $fob->{loc} = [];
      $fob->{attr}= [];

      ##warn ">tss2x: new $arm,$fmin,$oid\n" if $tss;

      push( @{$fob->{loc}},  $loc);  
      ##moved below## foreach my $at (@addattr) { push( @{$fob->{attr}}, $at); }
      }
    
    ## make oid crossref here so outputters know feature relations
    ## change this (see above $samoid read loop)
    ## FIXME 05: this sub should be run only after forward parent_oid is found;
    ## or change input to sort given model gene > mRNA > CDS (ignoring seq start)
    foreach my $at (@addattr) {
      my $paroid='';
      if ($at =~ /parent_oid\t(.+)/) { $paroid=$1; } 
      push( @{$fob->{attr}}, $at)
        ; # unless( grep {$at eq $_} @{$fob->{attr}});  #? do we have any dupls?

       ## REMEMBER SOME (exons) HAVE MULTIPLE parent_oid attributes 
      if ($paroid && !$simplefeat{$type}) { 
        $self->newParentOid($fob, 'parent_oid', $paroid, \%oidobs);  
        }
      }
      
    # $self->newParentKidLink($fob, \%oidobs); # uses @{$fob->{attr}} parent_oid

    ## MOVED parent_oid attrib TO putFeats: $self->update1ParentKidLinks($fob, \%oidobs);
    
    ## forward ref checkpoint .. maybe skip more than segmentfeats here ? what is big?
    if ($fmax > $max_max && !$segmentfeats{$fob->{type}}) {
      $max_max= $fmax; 
      my $supermax= $min_max - MIN_FORWARD_RANGE + MAX_FORWARD_RANGE;   
      $max_max= $supermax if ($max_max > $supermax); # is it < or > ? was > (set to SMALLER)
      }
    
    ## only need save these:
    ($l_arm,$l_oid,$l_fmin,$l_fmax,$l_type)= ($arm,$oid,$fmin,$fmax,$type);
    }
  
  $self->putFeats($outh,\@fobs,\%oidobs, 'final'); 
  @fobs=(); %oidobs=();
  
  $outh= $self->openCloseOutput($outh,'','close');
  print STDERR "\nprocessChadoTable ndone = $ndone\n" if $DEBUG;
  return $ndone;
}



## jan06: makeFlatFeats -> makeFlatFeatsNew
## change to config->{feat_model}->{$type}: @parts, $parent, $typelabel, $types

#s subclass this needs work
sub  makeFlatFeatsNew 
{
	my $self= shift;
  my ($fobs,$oidobs)= @_;
  
  my @cobs=(); # these compound features get added to output
  foreach my $fob (@$fobs) {  
    my $oid= $fob->{oid};
    my ($iskid,$ispar)= (0,0);
    my $oidob= $oidobs->{$oid};
    my $ftype= $fob->{type};
    #my $fulltype= $fob->{fulltype};
    my $id= $fob->{id};
    my $issimple= $simplefeat{$ftype};
    my $feat_model= $self->config->{'feat_model'}->{$ftype};
      ## get issimple from feat_model
      
    my $GMM=0; # ($DEBUG && $id =~ /CG17245|CG32013|CG2125|CG3973/) ? 1 : 0; # feb05 bug test, mRNA misses last 2 exons
    
    if (!$issimple && $oidob) {
      $iskid= (defined $oidob->{parent} && @{$oidob->{parent}} > 0);
      $ispar= (defined $oidob->{child} && @{$oidob->{child}} > 0);
      if ($iskid) { # check we have backref to parend obj ??
        my $ok= 0;
        foreach my $poid (@{$oidob->{parent}}) {
          if ($oidobs->{$poid}) { $ok=1; last; }
          }
        $iskid= $ok;
        }
      }
    warn ">gmm1 $ftype $id ispar=$ispar iskid=$iskid\n" if $GMM;


    ## handle feat_model changes to $fob; not just submodels: typelabel, attr
    if($feat_model) {
      my $typelabel=  $feat_model->{typelabel};
      $fob->{fulltype}= $fob->{type}= $typelabel if($typelabel); #?? need fulltype

      #0805: add sub_model->attr functions
      if(ref $feat_model->{attr}) {
        my $subattr= $feat_model->{attr};

        my @subattr = (ref( $subattr) =~ /ARRAY/) ? @$subattr : ($subattr);
        foreach my $sattr (@subattr) {
          my $akey = $sattr->{id} or next;
          my $aval = $sattr->{content} ||" ";
          $aval= $ftype if($aval eq "type");
          push( @{$fob->{attr}}, "$akey\t$aval");  
        }
      }
    }
    
    
    my $keepfeat= ($ispar || $self->keepfeat_fff($ftype));
    if ($keepfeat) {
      if(!$ispar) { $issimple=1; } 
      elsif($feat_model && defined($feat_model->{simple})) { $issimple= $feat_model->{simple}; }
      elsif($ftype eq 'gene' && !$self->config->{gene_is_complex}) { $issimple=1; }
      
      #NEED THIS# $issimple = 1 if ($ftype =~ m/^gene$/); #?? otherwise misc. gene parts GMM get flagged as written
      #BUT for complex flybase data; not for sgdlite w/o mrna features
      
      if ($issimple) { push(@cobs, $fob); } # simple feature
      else {              # has kids, make compound feature >> (m,t,s)RNA here
        my $kidobs= $oidob->{child};
        my $cob= $self->makeCompound( $fob, $kidobs, $ftype); 
        push(@cobs, $cob);
        # $self->listkids($cob,$kidobs) if($DEBUG && $ftype =~ m/^(gene|mRNA)$/);  ## was loosing kids to bad $oidobs
        }
      warn ">gmm2 add $ftype $id \n" if $GMM;
      }
    
    ## %GModelParents = ( mRNA => 1, otherRnas ?? => );
    ## $CDS_spanType = 'CDS' ; # change to 'protein' or other ...
    ## $CDS_exonType = 'CDS_exon' ; # change to 'CDS'
    ## But for fff, need to rename $CDS_spanType 'protein' to 'CDS' for output fff type
    ## ?? this is only for 3-level models (gene/mRNA/protein) where
    ## submodel parts are contained in mainmodel kid list (protein-CDS in mRNA)
    
    if ($ispar && $feat_model && $feat_model->{submodels})
    {
      my $parob= $fob;
      my $submodels = $feat_model->{submodels};
      my @submodels = (ref $submodels) ? @$submodels : split(/[,\s]+/,$submodels);
       
      foreach my $subtype (@submodels) {
        my $sub_model= $self->config->{'feat_model'}->{$subtype}; # make sure exists ?
        my $makepartsfrom = $sub_model->{makepartsfrom} || 'exon';
        my $hasspan  = (defined $sub_model->{hasspan}) ? $sub_model->{hasspan} 
                     : ($subtype eq $CDS_spanType); # old version

        my $subtypelist= $sub_model->{types} | ""; # fixme types= list ..
          
        my $typelabel=  $sub_model->{typelabel} || $subtype;
        # my $parent=  $sub_model->{parent};
        my $kidparts = $sub_model->{parts} || 'exon'; #? no default

        my @kidparts = (ref $kidparts) ? @$kidparts : split(/[,\s]+/,$kidparts);
        my %kidparts = map { $_,1; } @kidparts;
        my $makemethod =  $sub_model->{makemethod}; 
      
        my $subob= undef; 
        my $spanob= undef;
        my $mrnaexons=[];
        my $kidobs=[];
        
        foreach my $kidob (@{$oidob->{child}}) {  
          my $ktype= $kidob->{type};
          if ($ktype =~ /^$makepartsfrom$/) {  
            push(@$mrnaexons, $kidob); # save in case missing CDS_exon
            }
          if ( $ktype eq $CDS_spanType ) { $spanob= $kidob; }  # only for utr patch !
          if ( $ktype eq $subtype ) {
            $subob= $kidob unless($subob);
            }
          elsif ( $subtypelist =~ m/$ktype/ ) {
            $subtype= $ktype; #??
            $subob= $kidob unless($subob);
            }
          elsif ($kidparts{$ktype}) {
            push(@$kidobs, $kidob);
            }
          }
          
          ## CDS/protein w/o CDS_exon parts ... recreate from cds start/stop + mrna location 
        if ($subob && !@$kidobs && $hasspan && @$mrnaexons) {
          warn ">gmmC getCDSexons $sub_model $kidparts $subob, ne=",scalar(@$mrnaexons),"\n" if $GMM;
  
          # this doesnt adjust exons for CDS span: see getLocation; reuse here 
          $kidobs= $self->getCDSexons($subob, $mrnaexons); 
          }
          
         ## for making UTRs, introns: mar06 # makemethod == makeUtr5,makeIntrons,...
        elsif( !@$kidobs && @$mrnaexons && $makemethod) {
          $subob= $parob unless($subob); #??
          ($subob,$kidobs)= eval "\$self->$makemethod(\$subob, \$mrnaexons);";
          if($@ && $DEBUG){ warn "$makemethod err: $@"; } #? die if ($self->{failonerror}) ?
          warn ">gmmU $makemethod $sub_model np=",scalar(@$kidobs),"\n" if $GMM;
          }
         
        if ($subob) { 
            ## copy gene model dbxref id into  these features, as per above
          my $idpattern= $self->config->{idpattern};
          foreach my $pidattr (@{$fob->{attr}}) { 
            next if ($pidattr =~ m/2nd/);   #dbxref_2nd:
            if (!$idpattern || $pidattr =~ m/$idpattern/) { 
              push( @{$subob->{attr}}, $pidattr) unless( grep {$pidattr eq $_} @{$subob->{attr}});  
              last; # add only 1st/primary 
              }
            }
  
          #0805: add sub_model->attr functions
          if(ref $sub_model->{attr}) {
            my $subattr= $sub_model->{attr};

            my @subattr = (ref( $subattr) =~ /ARRAY/) ? @$subattr : ($subattr);
            foreach my $sattr (@subattr) {
              my $akey = $sattr->{id} or next;
              my $aval = $sattr->{content} || " ";
              $aval= $subtype if($aval eq "type");
              push( @{$subob->{attr}}, "$akey\t$aval");  
            }
          }
          

          if ($subtype =~ /UTR/ && $self->config->{utrpatch}) {
            $self->patchUTRs( $subob, $spanob, $mrnaexons, $kidobs);
            }

          ## jan06: problem here w/ change to protein/cds: all GModelParts end up fff feature
          ## CDS_exon, exon  end up as compound types same as mRNA, CDS/protein
          
          my $cob= $self->makeCompound( $subob, $kidobs, $subtype); 
          $cob->{fulltype}= $cob->{type}= $typelabel;
          warn ">gmmCOB $typelabel $cob np=",scalar(@$kidobs),"\n" if $GMM;
          
          push(@cobs, $cob);
          }
        }
      }
    ## else {  } # $iskid only - dont save
    }
    
  return \@cobs;
}



=item  getCDSexons($cdsob,$exonobs,$ftype)

  create compound feature from parent, kids (e.g., mRNA + exons)
  
=cut

# sub getCDSexons
# {
# 	my $self= shift;
#   my ($cdsob,$exonobs,$ftype)= @_;
# 
#   my $offsetloc = $cdsob->{loc}->[0]; # only 1 we hope
#   my ($offstart,$offstop,$offstrand) = split("\t",$offsetloc);
#   if ($offstart > $offstop) { ($offstart,$offstop)= ($offstop,$offstart); } #? need
#   $cdsob->{offloc}= $offsetloc;
# 
#   my @cdsobs=();
#   foreach my $kid (@$exonobs) {
#     my ($start,$stop,$st) = split("\t", $kid->{loc}->[0]);
#     if ($stop >= $offstart && $start <= $offstop) { 
#       push(@cdsobs, $kid);
#       }
#     }
# 
#   return \@cdsobs;
# }



=item  makeCompound($fob,$kidobs,$ftype)

  create compound feature from parent, kids (e.g., mRNA + exons)
  
=cut

sub makeCompound
{
	my $self= shift;
  my ($fob,$kidobs,$ftype)= @_;
  
  my $cob= $self->cloneBase($fob);
  $fob->{'writefff'}=1; # need here also !? this is messy...
   
  ## FIXME - for dang transspliced mod(mdg4) - if strands in locs differ -> getLocation
  
  my @locs= ();
  my $hasspan= ($self->config->{'feat_model'}->{$ftype}->{hasspan}) or ($ftype eq $CDS_spanType);
  
  ## need to skip kids for 'gene', others ?
  foreach my $kid (@$kidobs) {
    next if ($fob->{type} =~ m/^(mRNA|gene)$/ && $kid->{type} ne 'exon');  
    if ($hasspan && $kid->{type} eq 'mature_peptide')
    {
      $ftype= $cob->{type}= 'mature_peptide';
    }
    $kid->{'writefff'}=1; # need here also !?
    foreach my $loc (@{$kid->{loc}}) { push( @locs, $loc);  }
    }

  unless(@locs) {
    foreach my $loc (@{$fob->{loc}}) { push( @locs, $loc);  }
    }

  if ($hasspan) { #  && !defined $cob->{offloc}
    my $offsetloc = $fob->{loc}->[0]; # only 1 we hope
    $cob->{offloc}= $offsetloc;
    }
 
    # FIXME: do getLocation adjustment for CDS_span > CDS_exons here?
  if (defined $cob->{offloc}) {
    @locs= $self->offsetLocation($cob, @locs);
  }
  
  $cob->{loc}= \@locs;    
  return $cob;
}



=item offsetLocation($fob,@loc)
  
  derived from getLocation
  get feature genbank/embl/ddbj location string (FTstring)
  including transplice complexity
  return ($location, $start, $strand);

 feb05: need to preserve strand==0/undefined for some features which have mixture
 fixed - for dang transspliced mod(mdg4) - if strands in locs differ 
 looks like chado pg reporting instance with CDS_exons is bad for transspliced mod(mdg4)

 08may: change behavior for GenbankSubmit to offsetLocation: 
    dont return Genbank style string location, but
    adjust @loc to CDS_exons by CDS span offset;
 See also getCDSexons and makeCompound
 
=cut  

sub offsetLocation # was getLocation
{
	my $self= shift;
  my($fob,@loc)= @_;
  my $srange='';
  my $bstart= -999;
  my($l_strand,$istrans)=(0,0);
  my @newloc=();
  
  my ($offstart,$offstop,$offstrand)= (0,0,0);
  if (defined $fob->{offloc}) {
    ($offstart,$offstop,$offstrand) = split("\t",$fob->{offloc});
    }
    
    ## assume not istrans - only 1 in 15,000 - redo if istrans
  foreach my $loc (@loc) {
    my ($start,$stop,$strand)= split("\t",$loc);
    
    if ($offstop != 0) {
      next if ($stop < $offstart || $start > $offstop);
      $start= $offstart if ($start<$offstart);
      $stop = $offstop if ($stop>$offstop);
      }
      
    if ($bstart == -999 || $start<$bstart) { $bstart= $start; }
    # $srange .= "$start..$stop,";
    push( @newloc, "$start\t$stop\t$strand");
    
    if ($l_strand ne 0 && $strand ne $l_strand) { $istrans= 1; last; }
    $l_strand= $strand;
  }

  if ($istrans) {
    @newloc=(); $srange='';
   
    $l_strand= 0; 
    $l_strand= $offstrand if ($offstrand < 0);

    ## hack patch for bad cds exons for transpliced mdg4
    if (defined $fob->{exons}) {
      my $exonlocs= $fob->{exons};
      @loc= @$exonlocs if (@$exonlocs);
      print STDERR "transplice ",$fob->{name}," replaced cds_exons with mrna exons\n" if $DEBUG;
      }
      
    foreach my $loc (@loc) {
      my ($start,$stop,$strand)= split("\t",$loc);
      
      if ($offstop != 0) {
        next if ($stop < $offstart || $start > $offstop);
        ## revcomp tricks here
        if ( $l_strand < 0 && $strand >= 0 ) { 
          print STDERR "transplice ",$fob->{name}," rev ex=$start,$stop,$strand ; off=$offstart,$offstop\n" if $DEBUG;
          $stop = $offstart if ($start < $offstart);  
          }
        else {
          $start= $offstart if ($start<$offstart);
          $stop = $offstop if ($stop>$offstop);
          }
        }

      $strand= -$strand if ($l_strand < 0);
      # if ($strand < 0) { $srange .= "complement($start..$stop),"; }
      # else { $srange .= "$start..$stop,"; }
      push( @newloc, "$start\t$stop\t$strand");
      }
    }
  
  return @newloc;
  # $srange =~ s/,$//;
  # if ($l_strand < 0) { $srange= "complement($srange)"; }
  # elsif($srange =~ m/,/) { $srange= "join($srange)"; }
  # return ($srange, $bstart, $l_strand);
  
}






=item putFeats($outh,$fobs,$oidobs,$flag)
  
  output feature object (fobs) in selected formats (fff,gff,fasta)
  
=cut

#s subclass this needs work
sub putFeats
{
	my $self= shift;
  my ($outh,$fobs,$oidobs,$flag)= @_;
  return unless($fobs && @$fobs > 0);
  my($hasforward,$l_hasforward)=(0,0);
  
  my $n= scalar(@$fobs);
  
  if ($DEBUG && $flag =~ /final/) { # $DEBUG>1 || 
    print STDERR "putFeats n=$n, total=".($n+$ntotalout)
    .", oid1=".(($n>0)?$fobs->[0]->{oid}:0)."\n";
    }
  elsif ($DEBUG) {
    print STDERR ".";
    }
    
  $self->updateParentKidLinks($fobs, $oidobs); #05feb: logic change ; was in processChadoTable


#s subclass convert here for genbanktab output    
  if ($outh->{genbanktbl}) {  
    my $ffh= $outh->{genbanktbl};
    $self->{curformat}=  $self->{bulktype}; #  'genbanktbl';  
    
    #? need this for genbank ? probably yes, otherwise get exons as features
    my $cobs= $self->makeFlatFeatsNew($fobs,$oidobs);
    
    my $nout= 0;
    foreach my $fob (@$cobs) {  # ?? $fobs or $cobs
      $self->writeGenbankTbl( $ffh,$fob,$oidobs) ;  $nout++;
      undef $fob;
      }
    
    undef $cobs;
    $ffh->flush();
    $ntotalout += $nout;
  }

  $self->{curformat}= '';  
}


#s subclass this needs work
sub writeHeader
{
	my $self= shift;
  my($outh,$fmt,$chr,$appending)= @_;
  my $chrlen= defined $chromosome->{$chr} && $chromosome->{$chr}->{length} || 0;

  ## foreach $fmt (@formats) { $self->{$fmt}->writeheader($outh->{$fmt},$chr,$chrlen); }
#   $self->writeFFF1header($outh->{$fmt},$chr,$chrlen) if ($fmt eq 'fff' && !$appending);
#   $self->writeGFF3header($outh->{$fmt},$chr,$chrlen) if ($fmt eq 'gff' && !$appending);
  
  $self->writeGenbankHeader($outh->{$fmt},$chr,$chrlen); # if ($fmt eq 'genbanktab');
  ## add fasta output - no header ?
}


#s subclass this needs work
sub setDefaultValues
{
  my($self)= @_;

  $self->SUPER::setDefaultValues();
  
}

#---- GenbankTbl output -- separate package ?

sub writeGenbankHeader
{
	my $self= shift;
  my($fh,$seqid,$start,$stop)= @_;

  my $tblname="";
  my $date = $self->{date};
  my $sourcetitle = $self->{sourcetitle};
  my $org= $self->{species} || $self->{org};
  
  $tblname= $sourcetitle." ".$date; $tblname =~ s/\s+/_/g;

  print $fh ">Features\t$seqid\t$tblname\n"; 
 # gbtbl: first line is >Features SeqID table_name == chromosome SeqID, same as fasta
 
}


  ## see also SUPER::remapType ; handleAttrib ***; remapId ; remapName ; 
use constant ATTR_LISTCHAR => "\t";

sub handleAttribOut 
{
	my $self= shift;
  my($attr_array, $attr_key, $attribute, $feattype)=  @_;
  my $savekey= $attr_key;
  
  # special handling?
  # for types gene, mRNA, CDS:  Name => Gene; (gene)ID => locus_tag
  #  mRNA ID => transcript_id ; protein ID => protein_id

  # Map all ID tags depending on feature type
  # gene Name,ID => /gene= and /locus_tag=
  # mRNA Name,ID => /product= and /transcript_id= (but keep Parent /gene= and /locus_tag=
  # CDS Name,ID => /product= and /protein_id= (but keep (Grand)Parent /gene= and /locus_tag=
  # ncRNA ID,Name like mRNA ?
  #  transposon ID => /transposon=
  #  other  
  
  # Note => note
  # type polypeptide/protein => CDS type
  
  # FIXME here: also have fromGenbank attributes of these same tr/pr_id
  # keep both? rename other to old_ ? ID here is chado uniquename, should be valid
  # Also, GBSubmit wants original tr/pr_id for updates, in their special format (see docs)

  my $ftkey= "mapattr_key_".$feattype;
  my $fthash= $self->config->{$ftkey};
  
  my $newkey; 
  if(ref $fthash) { # FIXME allow [mrt*]RNA match
    ##warn "$ftkey keys=",keys(%$fthash),"\n"; # content,id,key
    $newkey= $fthash->{$attr_key};
    }
    
  if(!$newkey && exists $self->config->{mapattr_key}->{$attr_key}) {
    $newkey = $self->config->{mapattr_key}->{$attr_key}->{content}; 
    }
  $attr_key= $newkey if($newkey);
  return if ($newkey eq "skip");

  $attribute =~ s/_/ /g if($attr_key eq "organism"); # was species

  ## see also above handleAttrib
    
    # some/all value lists should be split to separate lines;
    # but some notes have ',': see below change to '\t' ?
  my @avals= split( ATTR_LISTCHAR, $attribute);
  foreach my $aval (@avals) {  
    push( @$attr_array, "$attr_key\t$aval");
  }

}

sub splitGbType
{
	my $self= shift;
  my($gffsource,$type,$fulltype)= @_;
  my($newgffs)=('');
  
  # FIXME: ${golden_path} becomes 'source' type. in code or in config?
  my $golden_path= $self->config->{golden_path} || $ENV{'golden_path'};
  
  if($golden_path =~ m/$type/) {
    $type= "source";
    }
    #? use fulltype instead of type? as 'match:sim4:na_EST_complete_dros'
    # convert mRNA_genscan,mRNA_piecegenie to gffsource,mRNA ?
  elsif ($maptype_gb{$type}) {
    ($type,$newgffs)= split(/[\.:]/,$maptype_gb{$type},2);
    }
  elsif ($fulltype =~ m/^([\w\_]+)[\.:]([\w\_\.:]+)$/) {
    ($type,$newgffs)=($1,$2);
    }
  elsif ($type =~ m/^([\w\_]+)[\.:]([\w\_\.:]+)$/) {
    ($type,$newgffs)=($1,$2);
    }
  else { $type= $fulltype if($fulltype); } #?? feb05; want snRNA not mRNA .. leave in fulltype ?
  $gffsource= $newgffs if($newgffs && $newgffs ne '.'); 
  
  return($gffsource,$type);
}

sub _gffEscape
{
  my $v= shift;
### not for genbank
#   $v =~ tr/ /+/;
#   $v =~ s/([\t\n\=&;,])/sprintf("%%%X",ord($1))/ge; # Bio::Tools::GFF _gff3_string escaper
  return $v;
}


=item writeGenbankTbl  
   
   write  one feature in Genbank submit table format
   feature may have sub location parts (multi line)
   
=cut

sub writeGenbankTbl  # from writeGFF
{
	my $self= shift;
  my($fh,$fob,$oidobs)= @_;
  my $type= $fob->{type};
  my $fulltype= $fob->{fulltype};
  return if ($fob->{'writefff'});
  $fob->{'writefff'}=1;
  if ($dropfeat_gff{$type}) { return; } #?? 
  
  my $ignore_missingparent= $self->config->{maptype_ignore_missingparent} || '^xxxx';
  my $gffsource= $fob->{gffsource} || $self->{gff_config}->{GFF_source} ||  ".";
  my $oid= $fob->{oid};  
  my $id = $fob->{id};  
  my $chr= $fob->{chr};
  my @loc= @{$fob->{loc}};
  my @attr= @{$fob->{attr}};
  my $at="";
  my @at= ();
  my %at= ();

  my $v;
  $at{"ID"}= _gffEscape($id) if ($id);
  $at{"Name"}= _gffEscape($v) if (($v= $fob->{name})); # keep dupl for GBsub  ! && $v ne $id
    
  foreach (@attr) {
    my ($k,$v)= split "\t";
    ## NO; keep empty vals# if (!$v) { next; }
    if ($k eq "object_oid") { next; }
    elsif ($k eq "parent_oid") {
      ## for each gene model part; should add locus_tag == gene ID
      
#       if ($gff_keepoids) { $at{$k} .= ATTR_LISTCHAR if $at{$k}; $at{$k} .= $v; }
      next if $segmentfeats{$type}; # dont do parent for these ... ?
      
      $v =~ s/:.*$//;  
      $k= 'Parent'; 

      my $parob= $oidobs->{$v}->{fob};
      if ($parob && $parob->{id}) {
        $v= $parob->{id};
        if ($oidisid_gff{$type}) { $v= $parob->{oid}; } 

        # FIXME: GBsub wants gene name,id in CDS; not mRNA parent
        my $vname= $parob->{name};  # special case
        $at{'ParentName'} = _gffEscape($vname) if($vname);  

        if($type =~ /protein|CDS/) { # FIXME
          my $paroid= $parob->{oid};
          my($gparoid)= @{ $oidobs->{$paroid}->{parent} };
          my $gparob= $oidobs->{ $gparoid }->{fob};
          my $gparid= $gparob->{id};
          $at{'GrandParent'} = _gffEscape($gparid);  
          my $vname= $gparob->{name};  # special case
          $at{'GrandParentName'} = _gffEscape($vname) if($vname);  
        }
        
        if ($v eq $id) {  
          my $i= 1;
          my $paroid= $parob->{oid};
          my $kids = $oidobs->{$paroid}->{child};
          if ($kids) { 
          foreach my $kidob (@{$kids}) {
            last if ($kidob->{oid} eq $oid);
            $i++;
            }
           }
          $id= "$id.$i";
          $at{"ID"} = _gffEscape($id);
          }
        }
      else {
        unless($fulltype =~ /$ignore_missingparent/) { 
          print STDERR "GB: MISSING parent ob for i/o/t:",$id,"/",$oid,"/",$fulltype,
          " parob=",$parob," k/v=",$k,"/",$v, " \n" if $DEBUG;
          }
        next; # always skip writing bogus Parent= to gff
        }

      }
      
    elsif ($k =~ /^dbxref|db_xref/i ) 
      { 
      $k= 'db_xref'; 
      next if ($v =~ /^GI:/); # drop NCBI GI: from submit db_xref
      }
      
    elsif ($k eq "synonym") { # check dupl ID
      next if ($v eq $id || $v eq $fob->{name});
      }
      
    if ($k) {
      $at{$k} .= ATTR_LISTCHAR if $at{$k}; # got duplicate Parent=aaa,aaa in dpse data; why?
      $at{$k} .= _gffEscape($v);  # should be urlencode($v) - at least any [=,;\s]
      }
    }

  ## drop ID if Parent ; sometimes ?
# unless(0) { 
#   my $parent= delete $at{'Parent'};
#   if( $parent && $dropid{$type} ) { $at[0]=  "Parent\t$parent"; }
#   elsif ($parent){ push(@at, "Parent\t$parent");  }
# }  

  ## this should set attrib 'ncRNA_class	snoRNA' for (snoRNA, scRNA, snRNA, miRNA, ncRNA, rRNA) > ncRNA
  ($gffsource,$type)= $self->splitGbType($gffsource,$type,$fulltype);

  foreach my $k (sort keys %at) { 
    $self->handleAttribOut(\@at, $k, $at{$k}, $type);
    # push(@at, "$k\t$at{$k}"); 
  }
  
  # Genbank Tbl format here:  loc \t loc \t FT-type \n \t ftfield \t ftval ...
  # FIXME: revcomp needs $#loc .. 0
  my(undef,undef,$gstrand)= split("\t",$loc[0]);
  my @iter= ( 0 .. $#loc );
  @iter= reverse @iter if ($gstrand < 0);
  my $first=1;
  
  foreach my $i ( @iter ) { 
    my($start,$stop,$strand)= split("\t",$loc[$i]);
    ($start,$stop) = ($stop,$start) if ($strand < 0);
    my @v= ($first) ? ($start,$stop,$type) : ($start,$stop);
    print $fh join("\t",@v),"\n"; $first=0;
  }
  foreach my $at (@at) {
    my ($k,$v)= split "\t",$at,2;
    print $fh join("\t","",$k,$v),"\n";
  }
  print $fh "\n";

}




1;

__END__

