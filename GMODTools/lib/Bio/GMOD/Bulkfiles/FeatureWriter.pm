package Bio::GMOD::Bulkfiles::FeatureWriter;
use strict;

=head1 NAME

  Bio::GMOD::Bulkfiles::FeatureWriter ; was ChadoFeatDump
  
=head1 SYNOPSIS
  
  use Bio::GMOD::Bulkfiles;       
  
  my $sequtil= Bio::GMOD::Bulkfiles->new( # was SeqUtil2
    configfile => 'seqdump-r4', 
    );
    
  my $fwriter= $sequtil->getFeatureWriter(); 
  ## was Bio::GMOD::ChadoFeatDump->new( configfile => 'chadofeatdump', sequtil => $sequtil );
    
  my $result= $fwriter->makeFiles( 
    infiles => [ @$seqfiles, @$chrfeats ], # required
    formats => [ qw(fff gff fasta)] , # optional
    );
    
=head1 NOTES

  genomic sequence file utilities, part3;
  parts from 
    flybase/work.local/chado_r3_2_26/soft/chadosql2flatfeat.pl
  
=head1 AUTHOR

D.G. Gilbert, 2004, gilbertd@indiana.edu

=head1 METHODS

=cut

#-----------------


# debug
#use lib("/bio/biodb/common/perl/lib", "/bio/biodb/common/system-local/perl/lib");

use POSIX;
use FileHandle;
use File::Spec::Functions qw/ catdir catfile /;
use File::Basename;

use Bio::GMOD::Bulkfiles::BulkWriter;       
use base qw(Bio::GMOD::Bulkfiles::BulkWriter);

our $DEBUG = 0;
my $VERSION = "1.1";
use constant BULK_TYPE => 'fff+gff';#??
use constant CONFIG_FILE => 'chadofeatdump';

my $maxout = 0;
my $ntotalout= 0;

my $chromosome= {};  ## read info from chado dump chromosomes.tsv 

my $fff_mergecols=1; # $self->{fff_mergecols} add chr,start cols for merge
my $gff_keepoids= 0; # $self->{gff_keepoids}
my @outformats= (); 
my @defaultformats= qw(fff gff); # cmap ?? fasta - no
my %formatOk= ( fff => 1, gff => 1 ); # only these handled here ?

my @fclone_fields = qw(chr type fulltype name id oid fmin fmax offloc attr writefff writegff);

my $outfile= undef; # "chadofeat"; ## replace w/ get_filename !
my $append=0; # $self->{append} #?? is this used?

my %gffForwards=();
my @gffForwards=();

use constant TOP_SORT => -9999999;
use constant MAX_FORWARD_RANGE => 990000; # at 500000 lost a handful of oidobs refs; maximum base length allowed for collecting forward refs
use constant MIN_FORWARD_RANGE =>  20000; # minimum base length for collecting forward refs

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
  ## $duptype_pattern


sub init 
{
	my $self= shift;
  $self->SUPER::init();
	$self->{outh} = {};

  ## superclass does these??
  $DEBUG= $self->{debug} if defined $self->{debug};
  # $self->{bulktype} =  $self->BULK_TYPE; # dont need hash val?
  # $self->{configfile}= $self->CONFIG_FILE unless defined $self->{configfile};

  $self->setDefaultValues(); #?? use or not? hold-over from pre-config work
}


=item initData

initialize data from config

=cut

sub initData
{
  my($self)= @_;
  $self->SUPER::initData();
  my $config = $self->{config};
  my $sconfig= $self->handler_config;
  
  ## SUPER does now
  #$config->{idpattern}   =  $self->getconfig('idpattern') || '';
  #$config->{intronpatch} =  $self->getconfig('intronpatch') || '';
  #$config->{utrpatch}    =  $self->getconfig('utrpatch')  || '';
  #$config->{gmodel_parts_rename} = $self->getconfig('gmodel_parts_rename') || '';
  #$config->{ignore_missingparent} = $self->getconfig('maptype_ignore_missingparent') || '';
  
  ## should get this from  $sconfig->{fileset}->{gff}->{noforwards}
  my $gffinfo= $self->handler()->getFilesetInfo('gff');
  $gffinfo->{GFF_source} = $sconfig->{GFF_source} if( $sconfig->{GFF_source});
  $self->{gff_config}= $gffinfo;
  $config->{noforwards} = ($gffinfo && defined $gffinfo->{noforwards}) 
    ? $gffinfo->{noforwards}
    : $config->{noforwards_gff};
  
  
  @outformats=  @{ $config->{outformats} || \@defaultformats } ; 

  $fff_mergecols= (defined $config->{fff_mergecols} && $config->{fff_mergecols}) || 1; ## add chr,start cols for merge
  $gff_keepoids = (defined $config->{gff_keepoids} && $config->{gff_keepoids}) || 0;  

  # @csomes= @{ $config->{chromosomes} } if (ref $config->{chromosomes});
  if (ref $config->{chromosome}) {
    $chromosome= $config->{chromosome};
    }
  else {
    $chromosome= $self->handler()->getChromosomeTable();
    $config->{chromosome}= $chromosome;
    }
    
  $rename_child_type= $config->{rename_child_type} if ($config->{rename_child_type});
  $name2type_pattern= $config->{name2type_pattern};
  ## $duptype_pattern  = $config->{duptype_pattern};
    
  %maptype      = %{ $config->{'maptype'} } if ref $config->{'maptype'};
  %maptype_pattern= %{ $config->{'maptype_pattern'} } if ref $config->{'maptype_pattern'};
  %mapname_pattern= %{ $config->{'mapname_pattern'} } if ref $config->{'mapname_pattern'};
  %mapattr_pattern= %{ $config->{'mapattr_pattern'} } if ref $config->{'mapattr_pattern'};
  %maptype_gff  = %{ $config->{'maptype_gff'} } if ref $config->{'maptype_gff'};
  %segmentfeats = %{ $config->{'segmentfeats'} } if ref $config->{'segmentfeats'};
  %simplefeat   = %{ $config->{'simplefeat'} } if ref $config->{'simplefeat'};
  %skipaskid    = %{ $config->{'skipaskid'} } if ref $config->{'skipaskid'};
  %dropfeat_fff = %{ $config->{'dropfeat_fff'} } if ref $config->{'dropfeat_fff'};
  %dropfeat_gff = %{ $config->{'dropfeat_gff'} } if ref $config->{'dropfeat_gff'};
  %dropid       = %{ $config->{'dropid'} } if ref $config->{'dropid'};
  %nameisid     = %{ $config->{'nameisid'} } if ref $config->{'nameisid'};
  %dropname     = %{ $config->{'dropname'} } if ref $config->{'dropname'};
  %mergematch   = %{ $config->{'mergematch'} } if ref $config->{'mergematch'};
  %hasdups      = %{ $config->{'hasdups'} } if ref $config->{'hasdups'};
  %keepstrand   = %{ $config->{'keepstrand'} } if ref $config->{'keepstrand'};
  %oidisid_gff  = %{ $config->{'oidisid_gff'} } if ref $config->{'oidisid_gff'};

  my $gmp= $config->{'GModelParts'} || 'CDS five_prime_UTR three_prime_UTR intron';
  @GModelParts= (ref $gmp) ? @$gmp : split(/[,\s]+/,$gmp);
  #@GModelParts  = qw( CDS five_prime_UTR three_prime_UTR intron );
  #@GModelParts  = @{ $config->{'GModelParts'} } if ref $config->{'GModelParts'};

    ## jan06: replace CDS/CDS_exon with protein/CDS ... per GFFv3 usage
    ## fly chado uses 'protein' for mRNA equivalent feature (start,stop) of cds
    ## and same exons for mRNA and protein
  $gmp= $config->{'GModelParents'} || 'mRNA';
  %GModelParents = map { $_, 1; } ((ref $gmp) ? @$gmp : split(/[,\s]+/,$gmp));
  
  $CDS_spanType= $config->{'CDS_spanType'} || 'CDS'; # change to 'protein' or other ...
  $CDS_exonType= $config->{'CDS_exonType'} || 'CDS_exon';# change back to CDS
  push(@GModelParts,$CDS_spanType) unless(grep(/$CDS_spanType/,@GModelParts));
  
  #? require segmentfeats be simplefeat ?
  map { $simplefeat{$_}=1; } keys %segmentfeats;
  delete $simplefeat{'gene'}; # dont make this mistake
  delete $simplefeat{'mRNA'}; # 
  
  ## merge config from this INTO handler config ?
  ## that is best place to keep common <featmap> and <featset>
  ## ? move this out of here; use separate featmap/featset include file?
  
  my $fset= $config->{featset};
  if (ref $fset && !$sconfig->{featset}) {
    $sconfig->{featset}= $fset;
    }
  my $fmap= $config->{featmap};
  if (ref $fmap) {
    my $smap= $sconfig->{featmap};
    unless(ref $smap) { $sconfig->{featmap}= $smap=  {}; }
    my @keys= keys %$fmap;
    foreach my $k (@keys) { $smap->{$k}= $fmap->{$k} unless defined $smap->{$k}; } 
    }
# $fff_mergecols=1; # add chr,start cols for merge
# $gff_keepoids= 0; #$DEBUG; #?

}


#-------------- subs -------------


=item  makeFiles( %args )

  primary method
  makes  bulk genome sequence files in standard formats.
  input file sets are intermediate chado db dump tables.
  
  arguments: 
  infiles => \@fileset,   # required
  formats => [ 'gff', 'fff' ] # optional

=cut

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
      warn "FeatureWriter: no input '$intype' files found\n"; 
      return $self->status(-1);
      }
    }
 
  my @saveformats= @outformats;
  ## this may be a mistake: config formats are what we need to make(?)
  ## args{formats} are what caller/customer wants as result
  if ($args{formats}) {
    my $formats= $args{formats};
    if(ref $formats) { @outformats= @$formats; } 
    else { @outformats=($formats); } 
    }
  @outformats= grep { $formatOk{$_}; }  @outformats;
  print STDERR "FeatureWriter::makeFiles outformats= @outformats\n" if $DEBUG; 
  
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
      $self->makeall( $chromosomes, "", $fmt) unless ($fmt eq 'fff'); 
      }
    }

  @outformats = @saveformats;
  print STDERR "FeatureWriter::makeFiles: done n=$status\n" if $DEBUG; 
  return  $self->status($status); #?? check files made
}

## just now can do only for gff; leave fff split by chr
sub makeall 
{
	my $self= shift;
  my( $chromosomes, $feature, $format )=  @_;
  return if ($format eq 'fff');
  $feature= ""; 
  $self->{curformat}= $format;
  $self->config->{path}= $format; #???? # setconfig ??
  print STDERR "makeall: $format\n" if $DEBUG; 
  $self->SUPER::makeall($chromosomes, $feature, $format); #?? not seen
  $self->{curformat}= '';  
  $self->config->{path}= ''; #???? # setconfig ??
  
#   my $outdir= $self->outputpath();
#   $chromosomes= $self->handler()->getChromosomes() unless (ref $chromosomes);
# 
#     ## this loop can be common to other writers: makeall( $chromosomes, $feature, $format) ...
#   my $allfn= $self->get_filename ( $self->{org}, 'all', $feature, $self->{rel}, $format);
#   $allfn= catfile( $outdir, $allfn);
#   
#   my @parts=();
#   foreach my $chr (@$chromosomes) {
#     next if ('all' eq $chr);
#     my $fn= $self->get_filename ( $self->{org}, $chr, $feature, $self->{rel}, $format);
#     $fn= catfile( $outdir, $fn);
#     next unless (-e $fn);
#     push(@parts, $fn);
#     }
#     
#   if (@parts) {
#     unlink $allfn if -e $allfn; # dont append existing
#     my $allfh= new FileHandle(">$allfn"); ## DONT open-append
#     foreach my $fn (@parts) {
#       my $fh= new FileHandle("$fn");
#       while (<$fh>) { print $allfh $_; }
#       close($fh); 
#       unlink $fn if (defined $self->config->{perchr} && $self->config->{perchr} == 0);
#       } 
#     close($allfh);
#     }

}
  
  
=item openInput( $fileset, $ipart )

  handle input files
  
=cut

sub openInput
{
	my $self= shift;
  my( $fileset, $ipart )= @_; # do per-csome/name
  my $inh= undef;
  return undef unless(ref $fileset);

  my $intype= $self->config->{informat} || 'feature_table'; #? maybe array
  my $atpart= 0;
  # print STDERR "openInput: type=$intype part=$ipart \n" if $DEBUG; 
  
  foreach my $fs (@$fileset) {
    my $fp= $fs->{path};
    my $name= $fs->{name};
    my $type= $fs->{type};
    next unless($fs->{type} eq $intype); 
    unless(-e $fp) { warn "missing dumpfile $fp"; next; }
    $atpart++;
    next unless($atpart > $ipart);
    print STDERR "openInput[$ipart]: name=$name, type=$type, $fp\n" if $DEBUG; 

    if ($fp =~ m/\.(gz|Z)$/) { open(INF,"gunzip -c $fp|"); }
    else { open(INF,"$fp"); }
    $inh= *INF;
    
    ## want option to ignore file date, use config date ??
    ##my $ftime= $^T - 24*60*60*(-M $fp);
    ## $self->{date}= POSIX::strftime("%d-%B-%Y", localtime( $ftime ));
    
    my ($sfile, undef) = File::Basename::fileparse($fp);
    $self->{sourcefile}= $sfile;
    
    return $inh; # only 1 at a time FIXME ...
    }
  print STDERR "openInput: nothing matches part=$ipart, type=$intype\n" if $DEBUG; 
  return undef;  
}

=item openCloseOutput($outh,$chr,$flags)

  handle output files
  
=cut

sub openCloseOutput
{
	my $self= shift;
  my($outh,$chr,$flags)=  @_;
  
  my $app= defined $self->{append} ? $self->{append} : $append;
  # 0710: no_csomesplit : no perchr files, only makeall
  my $no_csomesplit= $self->handler_config->{no_csomesplit} || 0; # FIXME: 0710
  if( $no_csomesplit ) {
    $app= 1;
    $chr="all"; # or "sum" ??
    }
    
  if ($outh && $flags =~ /open|close/) {
    foreach my $fmt (@outformats) {
      close($outh->{$fmt}) if ($outh->{$fmt});
      }
    }
    
  $outh= {};  
  if ($flags =~ /open/) {
    $chr='undef' unless($chr);
    #?? for unsorted input need to change $append to true after first open?
    foreach my $fmt (@outformats) {
      ## need option to append or create !?
      my $ap=($app) ? ">>" : ">";
      my $fn;
      if ($outfile) { $fn="$outfile-$chr.$fmt"; }
      else { $fn= $self->get_filename( $self->{org}, $chr, '', $self->{rel}, $fmt); }

      ##? check for $self->handler()
      my $subdir= $fmt; ##($fmt eq 'fff') ? 'gnomap' : $fmt; #? fixme 
      my $featdir= $self->handler()->getReleaseSubdir( $subdir);   
      my $fpath = catfile( $featdir, $fn);
      
      my $exists= ($app && -e $fpath) ? 1 : 0;
      print STDERR "# output $fpath (append=$exists)\n" if $DEBUG;
      $outh->{$fmt}= new FileHandle("$ap$fpath");
      $self->writeHeader($outh,$fmt,$chr) unless($exists);
      }
    }
  return $outh;
}


=item remapXXX
  
  processChadoTable handlers to fix various table inputs, according to config mappings
  
=cut

sub remapId
{
	my $self= shift;
  my ($type,$id,$name)= @_;
  my $save= $id;
  if (($nameisid{$type}) && $name) { $id= $name; } ## ? not for gff 
  elsif ($dropid{$type} || $id =~ /^NULL:/ || $id =~ /^:\d+/) { $id= undef; }
  #?? or not# elsif (!$id) { $id= $name; } 
  return ($id,$save);
}


sub remapName
{
	my $self= shift;
  my ($type,$name,$id,$fulltype)= @_;
  my $save= $name;
  
  if ( $dropname{$type} ) { $name= ''; }
  
  ## handle stupid match name = all the match type + ...
  #elsif ($type eq 'transposable_element_pred') { $name =~ s/JOSHTRANSPOSON-//; }
  ## clean unwieldy predictor names: contig...contig...
  elsif ($type =~ /^(gene|mRNA)/ && $name =~ s/Contig[_\d]+//g) { 
    ##if ($name =~ m/^(twinscan|genewise|genscan)/i) { $name= "${id}_${name}"; }
    if ($name =~ m/^(twinscan|genewise|genscan|piecegenie)/i) { $name= "${id}_$1"; }
    }
  elsif (!$name) { $name= $id unless ($id =~ /^NULL:/i || $id =~ /^:\d+/); } 
    ## dmelr4.1 ; must apply below name patches to id (no name)
  
    ## this one could be time sink .. use evaled sub {} ?
  foreach my $mp (sort keys %mapname_pattern) {
    next if ($mp eq 'null'); # dummy?
    my $mtype= $mapname_pattern{$mp}->{type};
    next if ($mtype && $type !~ m/$mtype/);
    if ($mapname_pattern{$mp}->{cuttype}) {
      my @tparts= split(/[_:.-]/, $type);
      push(@tparts, split(/[_:.-]/, $fulltype) ); #??
      foreach my $t (@tparts) { $name =~ s/\W?$t\W?//; }
      next;
      }
    my $from= $mapname_pattern{$mp}->{from}; next unless($from);
    my $to  = $mapname_pattern{$mp}->{to};
    if ($to =~ /\$/) { $name =~ s/$from/eval($to)/e; }
    else { $name =~ s/$from/$to/g; }
    }
  
  return ($name,$save);
}

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

sub remapArm
{
	my $self= shift;
  my ($arm,$fmin,$fmax,$strand)= @_;
  my $save= $arm;
  my $armfile= $arm;

#   my $rf= $armContigs{$arm};
#   if ($rf) {
#     my($armr,$b,$e,$st,$contig)= @$rf;
#     $arm= $armr;
#     if ($st eq '-') { #?? do we need to flip all - min,max relative to arm.e ?
#       $strand= -$strand;
#       ($fmax,$fmin) = ($e - $fmin-1, $e - $fmax-1);
#       }
#     else {
#       $fmin += $b - 1;
#       $fmax += $b - 1;
#       }
#     }
#   $armfile=$arm;
#   
#   ## need to fix dmel synteny.dump to not put gene name => arm for ortho:nnn
#   if ($arm eq $save) {
#     if (lc($org) eq 'dmel' && $arm =~ m/\-/) { # -PA .. others -xxx ?
#       $armfile= 'genes';
#       }
#     elsif ($arm =~ m/^Contig[^_]+_Contig/) {
#       $armfile= 'unordered2';
#       }
#     elsif ($arm =~ m/^Contig\w+/) {
#       $armfile= 'unordered1';
#       }
#     }

  return($arm,$fmin,$fmax,$strand,$armfile,$save)  
}

sub readArmContigs
{
	my $self= shift;
  my ($gffh)= @_;
#   unless($gffh) { warn "cant read arm contigs"; return; }
#   while(<$gffh>){
#     next unless(/^\w/);
#     my($arm,$x0,$type,$b,$e,$x1,$st,$x2,$attr)= split;
#     if($type eq 'segment' || $type eq 'golden_path' ||$type eq 'golden_path_region') { # golden_path_region in sql dump
#       my $contig = ($attr=~m/(Name|dbID)=(\w+)/) ? $2 : '';
#       $armContigs{$contig}= [$arm,$b,$e,$st,$contig];
#       }
#     }
}



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

sub remapType
{
	my $self= shift;
  my ($type,$name)= @_;
  my $save= $type;
  $type =~ s/\s/_/g; # must change?
  
    ## this one could be time sink .. use evaled sub {} ?
  foreach my $mp (keys %maptype_pattern) {
    next if ($mp eq 'null');  
    my $mname= $maptype_pattern{$mp}->{typename};
    next if ($mname && $name !~ m/$mname/);
    my $from= $maptype_pattern{$mp}->{from};
    my $to  = $maptype_pattern{$mp}->{to};
    $type =~ s/$from/$to/;
    }

  my $nutype  = $type;
  # this should be config pattern: ..genscan..
  ##if (defined $name && $name =~ m/[-_](genscan|piecegenie|twinscan|genewise|pred|trnascan)/i) {
  if ($name2type_pattern && defined $name && $name =~ m/$name2type_pattern/i) {
    $nutype .= "_".lc($1);
    }
  $nutype =~ s/[:\.]/_/g; #?
  $type = $maptype{$nutype} || $type;
  
  my $fulltype = $type; #?? here or what.
  $type =~ s/[:\.]/_/g; #?
  
  return ($type,$fulltype,$save);
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

use constant LINEBUF_SIZE => 2000; # for forward refs

sub getline {
	my $self= shift;
  my($fh)=  @_;
  my $n= scalar( @{$self->{linebuf}} );
  while (<$fh>) {
    next unless(/^\w/);
    next if(/^arm\tfmin/); # header from sql out
    chomp;
    push @{$self->{linebuf}}, $_;
    $n++;
    last if ($n >= LINEBUF_SIZE);
    }
  my $fin= shift @{$self->{linebuf}};
  return $fin;
}

sub popline {
	my $self= shift;
  my $fin = shift @{$self->{linebuf}};
  return $fin;
}

sub peekline {
	my $self= shift;
  my($n)=  @_;
  $n= 0 unless($n);
  my $fin= ${$self->{linebuf}}[$n];
  return $fin;
}

sub grepline {
	my $self= shift;
  my($patt)=  @_;
  my $grep= grep /$patt/, @{$self->{linebuf}};
  return $grep;
}


sub hasObForwards {
	my $self= shift;
  my($fobs,$oidobs)=  @_;

  foreach my $fob (@$fobs) {  
    my $oid= $fob->{oid};
    my $paroid= $fob->{paroid}; # may be one of many ! need $oidobs->{parent}
    my $ftype= $fob->{type};
    
    # my $issimple= $simplefeat{$ftype};
    next unless($paroid || $ftype =~ m/^(mRNA|gene)$/); # add CDS ? or do any types w/ paroid?
    
    #my $hasfor= grepline("\b$oid\b"); # mainly looking for attrib: parent_oid\t$oid
    my $hasfor= $self->grepline("parent_oid\t".$oid);  
    my $isfor= 0;

    if ($DEBUG && $hasfor) {
      # my @val= grep /parent_oid\t$oid/, @{$self->{linebuf}};
      print STDERR "hasForward: $ftype, ",$fob->{name},", $oid\n>","\n"; #join("\n>",@val),"\n"; 
      }

    ## ? need reverse: if fob has parent_oid, grep for its object_oid ?
    unless($hasfor) {
    $isfor= ($paroid && $self->grepline("\b$paroid\b"));  
    if ($DEBUG && $isfor) {
      # my @val= grep /\b$paroid\b/, @{$self->{linebuf}};
      print STDERR "isForward: $ftype, ",$fob->{name},", par=$paroid\n>", "\n"; # ,join("\n>",@val),"\n"; 
      }
    }
    
    return 1 if ($hasfor || $isfor);
    }
  return 0;
}


sub newParentOid
{
	my $self= shift;
  my($fob,$attr_type,$attribute,$oidobs)=  @_;

  ## my $paroid= $fob->{paroid};
  ##BAD-exon has many parents## return if($paroid);
  
  # my $type= $fob->{type}; return if ($simplefeat{$type}); ## TEST before call

  my $oid = $fob->{oid};
  
    # do part of this when fob is created:
    # >> add paroid->child and oid->{parent} refs
    # defer any requirement for parent/child ob till putLink()
    
  ##my($attr_type,$attribute)= split "\t",$addattr; 
  if ($attribute && $attr_type eq 'parent_oid' ) {
    my($paroid,$rank)= ($attribute, 0);
    if ($paroid  =~ s/:(.*)$//) {  $rank=$1; } # dont need rank, but must drop from paroid

    $fob->{paroid}= $paroid; ## replace OLD ok ??
    ## push( @{$fob->{attr}}, "rank\t$attribute"); # ? need this for exon, utr - but tied to parent_oid
    
    ## ? got dupl parent_oid for dpse genscan/twinscan genes only ?? screen here? -- gff output only?
    ## >> problem looks like oids are duplicated among gene/mRNA/CDS and the related genscan/genewise/twinscan/... objects
    
    $oidobs->{$paroid}->{child}= [] unless (ref $oidobs->{$paroid}->{child});
    push( @{$oidobs->{$paroid}->{child}}, $fob);   ##? use $rank to position in {child} array ??

    $oidobs->{$oid}->{parent}= [] unless (ref $oidobs->{$oid}->{parent});
    push( @{$oidobs->{$oid}->{parent}}, $paroid);
  }
}

## ???? for sgd gene->cds model; insert gene->mrna->cds/exon
sub add_mRNA
{
	my $self= shift;
  my($geneob,$oidobs)=  @_;
  my $geneoid = $geneob->{oid};
  my $type= $geneob->{type};

  my $make_mrna;
  $make_mrna= $self->config->{feat_model}->{$type}->{make_mrna};
  if ($make_mrna) {
    # my $mrnaob= { %$geneob }; # shallow clone !
    my $mrnaob= $self->cloneBase($geneob); # need locs
    $mrnaob->{type}= 'mRNA'; 
    # need new $oid; insert in $oidobs->{$oid}->{parent}; ..
    $self->newParentOid( $mrnaob, 'parent_oid', $geneoid, $oidobs);  
    ## and move kidobs from geneob to mrnaob ...
    # $mrnaob->{paroid}= $geneoid;  
    # my @kids= @{$oidobs->{$geneoid}->{child}};
    # push( @{$oidobs->{$geneoid}->{child}}, $mrnaob);   
    # push( @{$oidobs->{$oid}->{parent}}, $geneoid);
    }
}


sub updateParentKidLinks
{
	my $self= shift;
  my($fobs,$oidobs)=  @_;
  foreach my $fob (@$fobs) {  
    $self->update1ParentKidLinks($fob,$oidobs);
    }
}

sub update1ParentKidLinks
{
	my $self= shift;
  my($fob,$oidobs)=  @_;
  
  ## my $paroid= $fob->{paroid}; ## FIXME: exons have many parent 
  return unless( $fob->{paroid} );
  
  my $oid = $fob->{oid};
  my $type= $fob->{type};
  my $ignore_missingparent= $self->config->{maptype_ignore_missingparent} || '^xxxx';

  foreach my $paroid ( @{$oidobs->{$oid}->{parent}} ) {
  
  my $parob= $oidobs->{$paroid}->{fob};
  unless($parob) {
    warn "MISSING parent ob $paroid for $type:$oid\n"
      unless ($type =~ /$ignore_missingparent/); # || $id =~ /GA\d/
      # these match parts miss parent often: 'repeat|blast|genscan|sim4'
    next; # return;
    }
      
    ## another fixup for  CDS/protein-of-mRNA feature set
    ## was bad  - simplefeat included gene, pseudogene 
    ## dang; now gene children: 
    # insertion, aberration_junction,regulatory_region,
    # sequence_variant,rescue_fragment, enhancer, etc are missing
    # -> only gone from fff, not gff
    
    ##   <rename_child_type>pseudogene|\w+RNA</rename_child_type>
    
    ## sgdlite has this stuff : 
    ## tRNA contain ncRNA; pseudogene contains CDS (sic!); no mRNA
    
  if ($rename_child_type && $fob->{type} ne 'mRNA' 
        && $fob->{type} =~ m/^($rename_child_type)/) {
    # this is  bad for real gene subfeatures like point_mutation
    my $ptype= $fob->{type};
    
    ## feb05:
    ## this is causing problems for featuretype purists ; should leave 'gene' and subtype \w+RNA
    ## as is ?? but fix software to process right; use fulltype == orig; type = recoding ?
    
    if ($parob && ( $parob->{type} eq 'gene' || $parob->{type} eq $ptype) ) { 
      ##$parob->{fulltype}= $parob->{type}= $ptype; 
      ##$fob->{fulltype}= $fob->{type}= 'mRNA'; 
      $parob->{type}= $ptype; 
      $fob->{type}= 'mRNA'; 
      }
    # warn ">pse2: $arm,$fmin,".$parob->{type}."/".$fob->{type}.",$name,$oid,$l_oid\n" if $DEBUG; 
    }
    

  if ($fob->{type} =~ m/^(mRNA|CDS)$/) {  
   
    ## for genscan/twinscan etc mrna's - retype as parent gene_pred type
    if ($parob->{type} =~ m/^gene([_:.-]\w+)/ ) { 
      $fob->{type} .= $1; 
      if ($parob->{fulltype} =~ m/^gene([_:.-]\w+)/ ) { $fob->{fulltype} .= $1; }
      }
      
    # copy gene id dbxref attr  
    # got gene ids to all mRNA; missing some in CDS; need to do CDS after mRNA
    my $idpattern= $self->config->{idpattern};
    foreach my $pidattr (@{$parob->{attr}}) { 
      next if ($pidattr =~ m/2nd/); #? dbxref_2nd:
      if (!$idpattern || $pidattr =~ m/$idpattern/) { ## (FBgn|FBti)\d+   
        push( @{$fob->{attr}}, $pidattr) unless( grep {$pidattr eq $_} @{$fob->{attr}});  
        last; # add only 1st/primary
        }
      }
    }

  }
  
}

sub handleAttrib
{
	my $self= shift;
  my($addattr, $attr_type, $attribute, $fobadd)=  @_;

  # nasty fix for _Escape ; to_name=Aaa,CGid should probably be two table lines
  if ($attr_type eq 'to_name' && $attribute =~ /,/) {
    my $attr1; ($attr1,$attribute)= split(/,/,$attribute,2);
    push( @$addattr, "$attr_type\t$attr1");
    }

  # chado-gff loader does odd thing like adding unwanted 'DB:' prefix;
  # and dbxref=GFF_source:SGD
#   elsif ($attr_type eq 'dbxref' && $attribute =~ /^DB:\w+:\w+/) {
#     $attribute =~ s/^DB://;
#     }
#   elsif ($attr_type =~ /^dbxref/ && $attribute =~ /^FlyBase Annotation IDs/) {
#     $attribute =~ s/FlyBase Annotation IDs/FBannot/;
#     }
#   elsif ($attr_type eq 'dbxref' && $attribute =~ /^GFF_source:(\S+)/) {
#     if($fobadd) { $fobadd->{gffsource} = $1; } 
#     $attribute='';
#     }

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

#   while(<$fh>) {
#     next unless(/^\w/);
#     next if(/^arm\tfmin/); # header from sql out
#     chomp; 
#     $fin=$_; }
    
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
        
        #? do we need to set a max @fbobs ?
        ## is this where we lose PA/CDS associated with mRNA/gene ? havent got to yet before putFeats?
        
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
        my $clearflag= ($outh->{fff} || !$outh->{gff}) ? 'writefff' : 'writegff';
        my $nclear= $self->clearFinishedObs( $clearflag, \%oidobs, $fmin - MAX_FORWARD_RANGE);
        
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


sub keepfeat_fff
{
	my $self= shift;
  my ($ftype)= @_;
  my $dropfeat= ($dropfeat_fff{$ftype} || $ftype =~ /^match_part/);
  return(!$dropfeat);
}

sub _debugObj
{
  my ($name,$obj)= @_;
  require Data::Dumper;
  my $dd = Data::Dumper->new([$obj]); $dd->Terse(1);
  print STDERR "DEBUG obj: $name=",  $dd->Dump(),"\n";
}

=item  makeFlatFeats($fobs,$oidobs)

  handle gene model, other cases to make simple & compound features
  return  ref to features array
  used for fff and fasta outputs
  
=cut

=item missing prots check

This is list of prot genes lacking proteins - many/most cases where
there are protein and CDS feats in features.tsv and intermediat files,
but missing in fff output
   13472   gene.list
   18716   protgn.list
   13458   protgnuniq.list -- diff from gene.list below

.. feb04, dmelr41 check .. still missing some PA entries in fff, found in gff, featdump

chipmunk% comm -3 genecg41.list prot*list
 ;; these -Px proteins are in featdump, .gff, not .fff
CG10272 -- 3R
CG10324 -- 3R
CG11798 -- 2R
CG12591 -- 3R
CG17998 -- 3R
CG31092 -- 3R
CG3973 -- X
CG4993 -- 2L
CG5789 -- 3R

>> several of these missing prots are in features.tsv as CDS, not in fff output tho !?
dghome2% comm -3 gene.list protgnu.list
CG11989   3L
CG18675   3L
CG32373   3L
CG32406   3L
CG12094   X
CG1692    X
CG31243   3R
CG32600
CG4196
CG4444
CG5490
CG6669
CG7210
CG7369
CG8742
        Gyc76C == CG8742 

for this case CG18675; gff has right data, fff lacks CDS,three_prime_UTR
distance is gene:4157385 to CDS:4157485 = 100 b

chipmunk% gunzip $dr/gff.save/*gz
grep CG18675 ../../gff.chipmunk% grep CG18675 ../../gff.save//*3L*ff

chipmunk% grep CG18675 ../../fff.save//*3L*ff

=cut

sub  makeFlatFeats 
{
	my $self= shift;
  my ($fobs,$oidobs)= @_;
  
## debug missing from fff: insertion_site, regulatory
#   my %GMM= map { $_,1; } qw(enhancer insertion_site aberration_junction 
#     regulatory_region rescue_fragment sequence_variant);
  
  my @cobs=();
  my $gmodel_parts_rename= $self->config->{gmodel_parts_rename};
  foreach my $fob (@$fobs) {  
    my $oid= $fob->{oid};
    my ($iskid,$ispar)= (0,0);
    my $oidob= $oidobs->{$oid};
    my $ftype= $fob->{type};
    my $fulltype= $fob->{fulltype};
    my $id= $fob->{id};
    my $issimple= $simplefeat{$ftype};
     
#     my $GMM= $GMM{$ftype} && $DEBUG;
## missing exons: CG10033 (2L?)
## missing proteins: 3L CG11989 CG18675 CG32373 CG32406

    ##my $GMM= ($DEBUG && $id =~ /CG11989|CG18675|CG32373|CG32406/) ? 1 : 0; # jan05 bug test, mRNA misses last 2 exons
    my $GMM= 0; ##($DEBUG && $id =~ /CG4993|CG11798|CG10272|CG3973/) ? 1 : 0; # feb05 bug test, mRNA misses last 2 exons
    
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
      
    my $keepfeat= ($ispar || $self->keepfeat_fff($ftype));
    if ($keepfeat) {
      
      $issimple= ($issimple || !$ispar || $ftype eq 'gene'); # $ftype !~ m/^(CDS)$/ && 
      #NEED THIS# $issimple = 1 if ($ftype =~ m/^gene$/); #?? otherwise misc. gene parts GMM get flagged as written
      #BUT for complex flybase data; not for sgdlite w/o mrna features
      if ($issimple && $ftype eq 'gene') { $issimple= 0 if($self->config->{gene_is_complex}); }
      
      if ($issimple) { push(@cobs, $fob); } # simple feature
      else {              # has kids, make compound feature
        my $kidobs= $oidob->{child};
        my $cob= $self->makeCompound( $fob, $kidobs, $ftype); 
        push(@cobs, $cob);
        # $self->listkids($cob,$kidobs) if($DEBUG && $ftype =~ m/^(gene|mRNA)$/);  ## was loosing kids to bad $oidobs
        }
      warn ">gmm2 add $ftype $id \n" if $GMM;
      ## _debugObj("gmmisc=$id object",$cobs[-1]) if $GMM;
      }
    
      # UTR here ? ?? insert CDS between UTR's ?
      ## some of intron,UTR have swapped locs = 4650373..4650371
    
=item  debug parent/kid feature objects

      print STDERR "makeFlatFeats $ftype par=$id check kids\n" ;#if $DEBUG;
      # got here, missing protein/CDS kids.
      _debugObj("par=$id objects",$oidob);

makeFlatFeats mRNA par=CG18001-RA check kids
DEBUG obj: par=CG18001-RA objects={
          'parent' => [
                        509313
                      ],
          'fob' => {
                     'writefff' => 1,
                     'chr' => '2h',
                     'attr' => [
                                 'parent_oid    509313'
                               ],
                     'name' => 'CG18001-RA',
                     'id' => 'CG18001-RA',
                     'oid' => 509314,
                     'type' => 'mRNA',
                     'loc' => [
                                '42592  43051   -1'
                              ]
                   },
          'child' => [
                       {
                         'writefff' => 1,
                         'chr' => '2h',
                         'attr' => [
                                     'parent_oid        509314:2'
                                   ],
                         'name' => 'CG18001:2',
                         'id' => 'CG18001:2',
                         'oid' => 509316,
                         'type' => 'exon',
                         'loc' => [
                                    '42592      42914   -1'
                                  ]
                       },
...
}

=cut

    #  
    ## %GModelParents = ( mRNA => 1, otherRnas ?? => );
    ## $CDS_spanType = 'CDS' ; # change to 'protein' or other ...
    ## $CDS_exonType = 'CDS_exon' ; # change to 'CDS'
    ## But for fff, need to rename $CDS_spanType 'protein' to 'CDS' for output fff type
    
    #if ($ispar && $ftype eq 'mRNA')
    if ($ispar && $GModelParents{$ftype})
    {
      foreach my $ftname (@GModelParts) {
        my $utrob= undef; 
        my $cdsob= undef;
        my $exonobs=[];
        my $mrnaexons=[];
        my $kidobs=[];
        
        foreach my $kidob (@{$oidob->{child}}) {  
 
          if ($kidob->{type} eq 'exon') {  
            push(@$mrnaexons, $kidob); # save in case missing CDS_exon
            }
          if ($kidob->{type} eq $CDS_spanType) { $cdsob= $kidob; } # only for utr patch ?
            
          if ($ftname eq $CDS_spanType && $kidob->{type} eq $CDS_spanType) {
            $utrob= $kidob unless($utrob);
            ## urk - need to keep loc:start/stop to adjust CDS_exon end points !
            }
          elsif ($id =~ /CG32491/ && $ftname eq $CDS_spanType && $kidob->{type} eq 'exon') {
            ## patch for mdg4 bug
            push(@$exonobs, $kidob);
            }
          elsif ($ftname eq $CDS_spanType && $kidob->{type} eq $CDS_exonType) {
            push(@$kidobs, $kidob);
            ## missing this for het db ... FIXME 
            # bad CDS_exon for transspliced mdg4 ... sigh ... need to keep also regular exons?
            }
          
          ## ?? want instead: if(kidob->type in (UTR,...)) add to kids
          elsif ($kidob->{type} eq $ftname) {  # these will be UTR's, other things (?)
            $utrob= $kidob unless($utrob); #?? dont do this?
            push(@$kidobs, $kidob); 
            
            ## repair bad names; only if bad !?
            ## FIXME apr05 - intron,UTR fff output needs CG ids (in gff, not fff, due to
            ##   name = gene-symbol, FBgn ID; ... need uniquename
            ## apr05 -  this renaming bad now ? at keep old name,id as 2ndary ?
            if ($gmodel_parts_rename) {
              my $part="";
              if ($ftname eq 'three_prime_UTR') {  $part= "-u3";  }
              elsif ($ftname eq 'five_prime_UTR') {  $part= "-u5";  }
              elsif ($ftname eq 'intron') {  $part= "-in";  }
              if ($part) {
                $utrob->{name}= $fob->{name}.$part;  
                $utrob->{id}= $fob->{id}.$part;
                }
              }
            }
            
          }
        
          
          ## ERROR -  CDS/protein w/o CDS_exon parts - not harvard chado 'reporting' db
          ## fixme ... recreate from cds start/stop + mrna location ?
        if ($utrob && !@$kidobs) {
          if ($ftname eq $CDS_spanType && @$mrnaexons) {
            $kidobs= $self->getCDSexons($utrob, $mrnaexons);
            }
          }
         
        if ($utrob) { 

            ## copy gene model dbxref id into  these features, as per above
          my $idpattern= $self->config->{idpattern};
          foreach my $pidattr (@{$fob->{attr}}) { 
            next if ($pidattr =~ m/2nd/);   #dbxref_2nd:
            if (!$idpattern || $pidattr =~ m/$idpattern/) { 
              push( @{$utrob->{attr}}, $pidattr) unless( grep {$pidattr eq $_} @{$utrob->{attr}});  
              last; # add only 1st/primary ?? also add CG/CR .. ? or is that always there?
              }
            }
            
          if ($ftname =~ /UTR/ && $self->config->{utrpatch}) {
            $self->patchUTRs( $utrob, $cdsob, $mrnaexons, $kidobs);
            }

          ##print STDERR "makeCompound $ftname par=$id, kid=",$utrob->{id},  "\n" if $DEBUG;
          # below # if ($ftname eq 'CDS') { $kidobs= adjustCDSendpoints( $utrob, $kidobs); }
          
          ## jan06: problem here w/ change to protein/cds: all GModelParts end up fff feature
          ## CDS_exon, exon  end up as compound types same as mRNA, CDS/protein
          
          my $cob= $self->makeCompound( $utrob, $kidobs, $ftname); 
          # $self->listkids($cob,$kidobs) if($DEBUG);  ## was loosing kids to bad $oidobs

            # patch bad data -- use getCDSexons above ??
          if ($id =~ /CG32491/ && $ftname eq $CDS_spanType) {  
            my @exlocs=();
            foreach my $kid (@$exonobs) {
              foreach my $loc (@{$kid->{loc}}) { push( @exlocs, $loc);  }
              }
            $cob->{exons}= \@exlocs;
            }
            
          push(@cobs, $cob);
          }
        }
      }
    ## else {  } # $iskid only - dont save
    }
    
  return \@cobs;
}



## jan06: makeFlatFeats -> makeFlatFeatsNew
## change to config->{feat_model}->{$type}: @parts, $parent, $typelabel, $types

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
        my $sub_model= $self->config->{'feat_model'}->{$subtype};
        my $makepartsfrom = $sub_model->{makepartsfrom} || 'exon';
        my $hasspan  = (defined $sub_model->{hasspan}) ? $sub_model->{hasspan} 
                     : ($subtype eq $CDS_spanType); # old version
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
          elsif ($kidparts{$ktype}) {
            push(@$kidobs, $kidob);
            }
          }
          
          ## CDS/protein w/o CDS_exon parts ... recreate from cds start/stop + mrna location 
        if ($subob && !@$kidobs && $hasspan && @$mrnaexons) {
          warn ">gmmC getCDSexons $sub_model $kidparts $subob, ne=",scalar(@$mrnaexons),"\n" if $GMM;
          $kidobs= $self->getCDSexons($subob, $mrnaexons); 
          #($subob,$kidobs)= eval "\$self->$makemethod(\$subob, \$mrnaexons);";
          }
          
         ## for making UTRs, introns: mar06 # makemethod == makeUtr5,makeIntrons,...
        
        elsif( !@$kidobs && @$mrnaexons && $makemethod) {
          $subob= $parob unless($subob); #??
          # warn ">gmmU $makemethod $sub_model $kidparts $subob, ne=",scalar(@$mrnaexons),"\n" if $GMM;
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
            
          if ($subtype =~ /UTR/ && $self->config->{utrpatch}) {
            $self->patchUTRs( $subob, $spanob, $mrnaexons, $kidobs);
            }

          ## jan06: problem here w/ change to protein/cds: all GModelParts end up fff feature
          ## CDS_exon, exon  end up as compound types same as mRNA, CDS/protein
          
          my $cob= $self->makeCompound( $subob, $kidobs, $subtype); 
          # $self->listkids($cob,$kidobs) if($DEBUG);  ## was loosing kids to bad $oidobs
          $cob->{type}= $typelabel;
          warn ">gmmCOB $typelabel $cob np=",scalar(@$kidobs),"\n" if $GMM;
          
          push(@cobs, $cob);
          }
        }
      }
    ## else {  } # $iskid only - dont save
    }
    
  return \@cobs;
}


=item  patchUTRs($utrob,$mrnaexons,$kidobs)

  make sure utr's are in $mrnaexons range
  patch for buggy utr-data
  
=cut

sub patchUTRs
{
	my $self= shift;
  my ($utrob,$cdsob,$mrnaexons,$kidobs)= @_;
  return if ($utrob->{patched} || scalar(@$mrnaexons)==0);
  my($minex,$minex1,$maxex,$maxex1)=(-1,-1,-1,-1);
  foreach my $ex (@$mrnaexons) {
    my ($start,$stop,$st) = split("\t", $ex->{loc}->[0]);
    if ($minex==-1 || $start < $minex) { ($minex,$minex1)= ($start,$stop); }
    if ($maxex==-1 || $stop > $maxex) { ($maxex,$maxex1)= ($stop,$start); }
    }
    
    # got weird utr mid points 2,3 bases below/above CDS start/stop;
    # always use protein start/stop if need change?
  if ($cdsob) {
    my $offsetloc = $cdsob->{loc}->[0] ; # only 1 we hope
    my ($offstart,$offstop,$offstrand) = split("\t",$offsetloc);
    $minex1= $offstart-1 if ($offstart > $minex); # && $offstart <= $minex1
    $maxex1= $offstop+1 if ($offstop < $maxex); #$offstop >= $maxex1 && 
    }
    
    ## kidobs[0] == utrob always ? only 1 kidob ?
  foreach my $kid (@$kidobs) {
    my $c= 0;
    my ($start,$stop,$st) = split("\t", $kid->{loc}->[0]);
    if ($start < $minex) { $c=1; $start= $minex; $stop=  $minex1; } #if ($stop < $start)  
    if ($stop > $maxex)  { $c=1; $stop= $maxex;  $start= $maxex1; } #if ($start > $stop)  
    # print STDERR  "patchUTRs ".($c?'':'NOT ').$kid->{name}." ".$kid->{loc}->[0]." => $start..$stop\n" if $DEBUG;
    if ($c) {
      $kid->{loc}->[0]= join("\t", $start,$stop,$st);
      $utrob->{'writefff'}= $utrob->{'writegff'}= -1 if ($stop==$start);
      }
      # dont write bogus empty UTR
    elsif ($stop==$start) { $utrob->{'writefff'}= $utrob->{'writegff'}= -1; }
    }
  $utrob->{patched}=1;
}

=item makeUtr5,3,makeIntron

  generate UTR's, introns from exons, protein-span features
  added mar06
  call: 
    my $makemethod =  $sub_model->{makemethod}; # makeUtr5,makeIntrons,...
    ($subob,$kidobs)= $self->&{$makemethod}($subob, $mrnaexons);
  where returned $subob is new feature: UTRs or intron(s)
  
=cut

sub makeUtr5 { return shift->makeUtr53(5,@_);  }	
sub makeUtr3 { return shift->makeUtr53(3,@_);  }	
sub makeUtr53
{
	my $self= shift;
  my ($uside, $mrnaob, $mrnaexons)= @_;
  return (undef,[]) unless($uside == 5 || $uside == 3);
  return (undef,[]) unless ($mrnaob && scalar(@$mrnaexons));
  my($cdsob); # get from exon list
  my @kidobs= (); # make from exons

  foreach my $ex (@$mrnaexons) {
    my $ktype= $ex->{type};
    if($ktype eq 'protein') { $cdsob= $ex; }
    }
# warn "makeUtr$uside $cdsob\n" if $DEBUG;
  return (undef,[]) unless ($cdsob);
  
  my $offsetloc = $cdsob->{loc}->[0] ; # only 1 we hope
  my ($offstart,$offstop,$offstrand) = split("\t",$offsetloc);
  ## need to watch strand effect: 5prime for -strand is hi value, not low
  # but genome-locs are always start<stop; 
  my $rev= ($offstrand < 0);
  my $ulow  = (($uside == 5 && !$rev) || ($uside == 3 && $rev));
  my $uhigh = (($uside == 3 && !$rev) || ($uside == 5 && $rev));
  
  foreach my $ex (@$mrnaexons) {
    my $ktype= $ex->{type};
    next unless($ktype eq 'exon');
    my ($start,$stop,$st) = split("\t", $ex->{loc}->[0]);
    # FIXME strand...
    next if($ulow && $start >= $offstart); 
    next if($uhigh && $stop <= $offstop);  
      
    # my $cex= { %$ex };  # shallow clone; ok?
    my $cex= $self->cloneBase($ex); # need locs
    $cex->{'writefff'}= $cex->{'writegff'}= 0;  # -1 ??
    $cex->{type}= ($uside == 5) ? 'five_prime_UTR' : 'three_prime_UTR'; 

    my $c= 0;
    # FIXME strand
    if ($ulow && $stop >= $offstart) { $c=1; $stop = $offstart - 1;  }  
    if ($uhigh && $start <= $offstop) { $c=1; $start= $offstop + 1;  } 
    if ($c) {
      $cex->{loc}->[0]= join("\t", $start,$stop,$st);
      }

    push(@kidobs,$cex);  
    }
# warn "makeUtr$uside kids=",scalar(@kidobs),"\n" if $DEBUG;
  return (undef,[]) unless (@kidobs);

  # my $utrob= { %$mrnaob }; # shallow clone !
  my $utrob= $self->cloneBase($mrnaob); # need locs
  $utrob->{fulltype}= $utrob->{type}= ($uside == 5) ? 'five_prime_UTR' : 'three_prime_UTR'; 
  my $part= ($uside == 5) ? "_utr5" : "_utr3";
  $utrob->{name} .= $part;  
  $utrob->{id}   .= $part;
  $utrob->{'writefff'}= $utrob->{'writegff'}= 0;  
  
#   # need new $oid; insert in $oidobs->{$oid}->{parent}; ..
#   $self->newParentOid( $mrnaob, 'parent_oid', $geneoid, $oidobs);  
   
  $utrob->{patched}=1;
  return($utrob,\@kidobs);
}

sub makeIntrons
{
	my $self= shift;
  my ($mrnaob, $mrnaexons)= @_;
  return () unless ($mrnaob && scalar(@$mrnaexons));

  my @kidobs= (); # make from exons
  my ($lstart,$lstop,$lst)= (0)x3;
  foreach my $ex (@$mrnaexons) {
    my $ktype= $ex->{type};
    next unless($ktype eq 'exon');
    my ($start,$stop,$st) = split("\t", $ex->{loc}->[0]);
    # FIXME strand...
    #? assume ordered exons here ?
    if($lstop>0 && $start > $lstop) { 
      # my $cex= { %$ex };  # shallow clone; ok?
      my $cex= $self->cloneBase($ex); # need locs
      my($istart,$istop,$ist)= ($lstop+1,$start-1,$lst);
      $cex->{loc}->[0]= join("\t", $istart,$istop,$ist);
      $cex->{type}= 'intron'; 
      $cex->{name} .= "_intron";  
      $cex->{id}   .= "_intron";
      push(@kidobs,$cex);  
      }
    ($lstart,$lstop,$lst)= ($start,$stop,$st);
    }
  return () unless (@kidobs);

  # my $intronob= { %$mrnaob }; # shallow clone !
  my $intronob= $self->cloneBase($mrnaob); # need locs
  $intronob->{fulltype}=  $intronob->{type}= 'intron_set'; #  intron collection !
  $intronob->{name} .= "_introns";  
  $intronob->{id}   .= "_introns";
  $intronob->{'writefff'}= $intronob->{'writegff'}= 0; #  intron collection !
  
  return($intronob,\@kidobs);
}


=item  getCDSexons($cdsob,$exonobs,$ftype)

  create compound feature from parent, kids (e.g., mRNA + exons)
  
=cut

sub getCDSexons
{
	my $self= shift;
  my ($cdsob,$exonobs,$ftype)= @_;

  my $offsetloc = $cdsob->{loc}->[0]; # only 1 we hope
  my ($offstart,$offstop,$offstrand) = split("\t",$offsetloc);
  if ($offstart > $offstop) { ($offstart,$offstop)= ($offstop,$offstart); } #? need
  $cdsob->{offloc}= $offsetloc;

  my @cdsobs=();
  foreach my $kid (@$exonobs) {
    my ($start,$stop,$st) = split("\t", $kid->{loc}->[0]);
    if ($stop >= $offstart && $start <= $offstop) { 
      push(@cdsobs, $kid);
      }
    }

  return \@cdsobs;
}


sub listkids { ## DEBUG only
	my $self= shift;
  my ($cob,$kidobs)= @_;

  my $name=$cob->{name};
  my $ftype=$cob->{type};
  my @locs= @ { $cob->{loc} };
  print STDERR "COB $ftype:$name";
  print STDERR " locs=",join(",",@locs);

  print STDERR " kids=";
  foreach my $kid (@$kidobs) {  
    print STDERR  $kid->{type},":",$kid->{name}," ";
    print STDERR join(",", @{$kid->{loc}})," ";
    }
  print STDERR "\n";
}


sub cloneBase ## shallow clone 
{
	my $self= shift;
  my ($fob)= @_;
  
  my $cob= {};  # are these all constant per oid ?
  @{%$cob}{@fclone_fields}= @{%$fob}{@fclone_fields}; #? what is vodoo

#   $cob->{chr} = $fob->{chr};
#   $cob->{type}= $fob->{type};
#   $cob->{fulltype}= $fob->{fulltype};
#   $cob->{name}= $fob->{name};
#   $cob->{id}  = $fob->{id};
#   $cob->{oid} = $fob->{oid};
#  $cob->{'writefff'}= $fob->{'writefff'}; # if ($fob->{'writefff'}<0); # in case flagged in utr checker
#  $cob->{'writegff'}= $fob->{'writegff'}; # if ($fob->{'writegff'}<0); # in case flagged in utr checker

# ## need locs ...
  $cob->{loc} = [];  push( @{$cob->{loc}}, $_) foreach (@{$fob->{loc}});
  $cob->{attr}= [];  push( @{$cob->{attr}}, $_) foreach (@{$fob->{attr}});
  # foreach my $attr (@{$fob->{attr}}) { push( @{$cob->{attr}}, $attr); }
  return $cob;  
}


=item  makeCompound($fob,$kidobs,$ftype)

  create compound feature from parent, kids (e.g., mRNA + exons)
  
=cut

sub makeCompound
{
	my $self= shift;
  my ($fob,$kidobs,$ftype)= @_;
  
  my $cob= $self->cloneBase($fob);
  $fob->{'writefff'}=1; # need here also !? this is messy...
   
#   my $cob= {};  # are these all constant per oid ?
#   $cob->{chr} = $fob->{chr};
#   $cob->{type}= $fob->{type};
#   $cob->{fulltype}= $fob->{fulltype};
#   $cob->{name}= $fob->{name};
#   $cob->{id}  = $fob->{id};
#   $cob->{oid} = $fob->{oid};
#   $cob->{'writefff'}= $fob->{'writefff'} if ($fob->{'writefff'}<0); # in case flagged in utr checker
#   $fob->{'writefff'}=1; # need here also !?
#  
#   #$cob->{attr}= $fob->{attr};
#   $cob->{attr}= [];
#   foreach my $attr (@{$fob->{attr}}) {
#     push( @{$cob->{attr}}, $attr);  
#     }
#     
  ##FIXME - parent loc may need drop for kids locs (mRNA)
  ## bad also to pick all kids - only exon type for mRNA, others?
  ## FIXME - for protein && CDS types which are only child of mRNA, need to merge into
  ## compound feat.
  ## FIXME - for dang transspliced mod(mdg4) - if strands in locs differ -> getLocation
  
  my @locs= ();
  #my @kidlist=(); ## debug only?
  
  ## need to skip kids for 'gene', others ?
  foreach my $kid (@$kidobs) {
  
    ##next if ($fob->{type} eq 'mRNA' && $kid->{type} ne 'exon');
    #if ($DEBUG && $fob->{type} =~ m/^(mRNA|gene)$/) {
    #  push(@kidlist, $kid->{name}, $kid->{type});
    #  }
      
    next if ($fob->{type} =~ m/^(mRNA|gene)$/ && $kid->{type} ne 'exon');  
    if ($ftype eq $CDS_spanType && $kid->{type} eq 'mature_peptide')
    {
      $ftype= $cob->{type}= 'mature_peptide';
    }
    # next if ($fob->{type} eq 'CDS' && $kid->{type} ne 'CDS_exon');
    $kid->{'writefff'}=1; # need here also !?
    foreach my $loc (@{$kid->{loc}}) { push( @locs, $loc);  }
    }

  if ($ftype eq $CDS_spanType) { 
    my $offsetloc = $fob->{loc}->[0]; # only 1 we hope
    $cob->{offloc}= $offsetloc;
    # $ftype= $cob->{type}= 'CDS' if(1); ## FIXME another flag to rename CDS spantype?
    }
  
  unless(@locs) {
    #? never keep main loc if have kid loc?
    foreach my $loc (@{$fob->{loc}}) { push( @locs, $loc);  }
    }
  $cob->{loc}= \@locs;
  # $cob->{kidlist}= \@kidlist if ($DEBUG); ## debug only?
    
  return $cob;
}



=item getLocation($fob,@loc)
  
  get feature genbank/embl/ddbj location string (FTstring)
  including transplice complexity
  
  return ($location, $start, $strand);

## feb05: need to preserve strand==0/undefined for some features which have mixture
## fixed - for dang transspliced mod(mdg4) - if strands in locs differ 
### looks like chado pg reporting instance with CDS_exons is bad for transspliced mod(mdg4)

=cut  

sub getLocation
{
	my $self= shift;
  my($fob,@loc)= @_;
  my $srange='';
  my $bstart= -999;
  my($l_strand,$istrans)=(0,0);

  my ($offstart,$offstop,$offstrand)= (0,0,0);
  ## if $fob is CDS check offset strand, flip compl.
  if (defined $fob->{offloc}) {
    # now: DID NOT adjusted @loc by off start/stop
    ($offstart,$offstop,$offstrand) = split("\t",$fob->{offloc});
    }
    
    ## assume not istrans - only 1 in 15,000 - redo if istrans
  foreach my $loc (@loc) {
    my ($start,$stop,$strand)= split("\t",$loc);
    
    if ($offstop != 0) {
      next if ($stop < $offstart || $start > $offstop);
      $start= $offstart if ($start<$offstart);
      $stop = $offstop if ($stop>$offstop);
      ## $strand= -$strand if ($offstrand < 0); #? is this bad for CDS ??
      }
      
    if ($bstart == -999 || $start<$bstart) { $bstart= $start; }
    $srange .= "$start..$stop,";
    if ($l_strand ne 0 && $strand ne $l_strand) { $istrans= 1; last; }
    $l_strand= $strand;
    }
    
  if ($istrans) {
    $srange='';
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
        if ( $l_strand < 0 && $strand >= 0 ) { #&& $strand >= 0
          print STDERR "transplice ",$fob->{name}," rev ex=$start,$stop,$strand ; off=$offstart,$offstop\n" if $DEBUG;
          $stop = $offstart if ($start < $offstart); #($stop>$offstart); ##
          }
        else {
          # next if ($stop < $offstart || $start > $offstop);
          $start= $offstart if ($start<$offstart);
          $stop = $offstop if ($stop>$offstop);
          }
        }

      $strand= -$strand if ($l_strand < 0);
      if ($strand < 0) { $srange .= "complement($start..$stop),"; }
      else { $srange .= "$start..$stop,"; }
      }
    }
    
  $srange =~ s/,$//;
  if ($l_strand < 0) { $srange= "complement($srange)"; }
  elsif($srange =~ m/,/) { $srange= "join($srange)"; }
  
  return ($srange, $bstart, $l_strand);
}


=item clearFinishedObs($flag,$oidobs)
  
  undef/release objects from %oidobs - 
  otherwise fills up for full chromosome and overruns memory available

  -- ok now, added min base loc to keep in oidobs, delete all before
  runs fast - chr 3L in 10 min. instead of >2hr.
  before this, oidobs was retaining *all* objects per input chr file; 
  and mem swapping to death before end.  Now looks stable around 50 MB mem use.
  AND speeds up greatly; fly chr 3L in 10 min. instead of >2hr.
  
=cut

sub clearFinishedObs
{
	my $self= shift;
  my ( $flag, $oidobs, $beforebase )= @_;
  ##my $flag= 'writefff';
  my $nclear= 0;
  
  if ($self->config->{noforwards}) {
    my @oid; my @parids; my @kids;
    foreach my $oid (keys %{$oidobs}) {
      my $isfree= 1;
      my $parids= $oidobs->{$oid}->{parent}; 
      foreach my $parid (@{$parids}) {
        my $pob = $oidobs->{$parid};
        my $done= ($pob && $pob->{$flag}); #? this is bad?
        if(!$done && $pob && $pob->{fob}) {
          my $ptype= $pob->{fob}->{type} || "";
          if ($simplefeat{$ptype}) { $done=1; }
          }
        unless($done) { $isfree=0; last; }
        }
        
      my $kids= $oidobs->{$oid}->{child};
      foreach my $kidob (@{$kids}) {
        my $done= ($kidob->{$flag});
        unless($done) { $isfree=0; last; }
        }
      
      ## dont free here -- finish iterate then do 
      if ($isfree) {
        push(@oid, @{$parids}) if $parids;
        push(@kids, $kids) if $kids;
        push(@oid, $oid) if $oid;
        }
      }
      
    foreach my $kids (@kids) { undef @{$kids}; $nclear++; }
    foreach my $oid (@oid) { 
      my $ob= delete $oidobs->{$oid};  $nclear++;
      if ($ob) {
        undef @{$ob->{parent}}; 
        undef @{$ob->{child}}; 
        undef %{$ob->{fob}}; 
        undef $ob;
        }
      }
      
      ## this fix looks like it is controlling memory overload
      ## before this, oidobs was retaining *all* objects per input chr file; 
      ## and mem swapping to death before end.  Now looks stable around 50 MB mem use.
      ## AND speeds up greatly over last data dump; < 1hr/chr versus 3hr+
    if ($beforebase>0) {
      while( my($oid,$ob)= each(%{$oidobs}) ) {
        if ($ob->{fob} && $ob->{fob}->{fmax} < $beforebase) {
          undef @{$ob->{parent}}; 
          undef @{$ob->{child}}; 
          undef %{$ob->{fob}}; 
          undef $ob;
          delete $oidobs->{$oid}; $nclear++;
          }
        }
      }
      
    }
    
    # need to use gffForwards check
    # NOTE: not tested; need likely above $beforebase fix to keep from retaining all oidobs
  else {
    foreach my $foid (keys %gffForwards) {
      if ($gffForwards{$foid} == -1) {
        delete $gffForwards{$foid};
        delete $oidobs->{$foid}; #? need to undef/delete $oidobs{n}->parts ?
        $nclear++;
        }
      }
    }
  return $nclear;
}


=item checkForward($flag,$fob,$oidobs)
  
  check for any remaining forwarded (unseen) objects (for gff)
  >> forward checks are problematic w/ new feats; 
  causing gff to sit in mem for full chromosome
  
=cut

sub checkForward
{
	my $self= shift;
  my ($flag,$fob,$oidobs)= @_;
  my $thisforward=0;
  my $anyforward=0;
  my $oid= undef;
  return $anyforward if ($self->config->{noforwards}); 
  
  my $issimple= ($fob && $simplefeat{$fob->{type}} );
## this is wrong - need to check kid ids written (also!?)
## ?? also need to check fob->{loc}/{fmax} to see if we have past that point ??

  if ($fob && $oidobs) { # && !$issimple
    $oid= $fob->{oid};

    # must skip segment, big features, etc. here even if have {parent}

    my $parids= $oidobs->{$oid}->{parent};
    if ($parids && !$issimple) {
    foreach my $parid (@{$parids}) {
      if (defined $gffForwards{$parid} &&  $gffForwards{$parid}<0) { next; }
      my $pob= $oidobs->{$parid};
      my $done= ($pob && $pob->{$flag}); #? this is bad?
      my $ptype= $pob->{fob}->{type};
      if ($pob && $pob->{fob} && ($simplefeat{$ptype})) { $done=1; }
      if (!$done) { $gffForwards{$parid}=1; $thisforward=1; }
      else { $gffForwards{$parid}=-1; }
      }
    }
      
    my $kids= $oidobs->{$oid}->{child};
    if ($kids) {
    foreach my $kidob (@{$kids}) {
      my $kidoid= $kidob->{oid};
      if (defined $gffForwards{$kidoid} && $gffForwards{$kidoid}<0) { next; }
      my $done= ($kidob->{$flag});
      if (!$done) { $gffForwards{$kidoid}=1;  $thisforward=1; }
      else { $gffForwards{$kidoid}=-1; }
      }
    }
  }
  
  ## need $flag check here?
  foreach my $need (values %gffForwards) { if ($need>0) { $anyforward=1; last; } }
  $gffForwards{$oid}=-1 if ($oid); # about to write this $fob
  
  return $anyforward; 
  #return (wantarray) ? ($anyforward,$thisforward) : $anyforward;
}

sub getForwards 
{
	my $self= shift;
  my $anyforward='';
  foreach my $oid (sort keys %gffForwards) { if ($gffForwards{$oid}>0) { $anyforward .="$oid "; } }
  return $anyforward;
}

=item putFeats($outh,$fobs,$oidobs,$flag)
  
  output feature object (fobs) in selected formats (fff,gff,fasta)
  
=cut

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
   
  if ($outh->{fff}) { ## || $outh->{fasta} < moved out
    my $ffh= $outh->{fff};
    # my $fah= $outh->{fasta};
    $self->{curformat}= 'fff';  
    my $cobs= $self->makeFlatFeatsNew($fobs,$oidobs);
    # need to undef @$cobs when done !
    
    my $nout= 0;
    foreach my $fob (@$cobs) {  
      ##$self->writeFFF( $outh->{fff}, $fob, $oidobs);
      my $fffline= $self->getFFF( $fob, $oidobs );
      if($fffline) {
        print $ffh $fffline;
        $nout++;
        }
      undef $fob;
      }
    
    undef $cobs;
    $ffh->flush();
    $ntotalout += $nout;
  }
  
  if ($outh->{gff}) {
    $self->{curformat}= 'gff';  
    my $gffh= $outh->{gff};
    my $noforw= $self->config->{noforwards};
    # print $gffh "# fwd oid=".$self->getForwards()."\n"; # is this a section break?
    my $gffend= 0;
    $l_hasforward= ($noforw) ? 0 : $self->checkForward('writegff');
    foreach my $fob (@$fobs) { 
      $hasforward= ($noforw) ? 0 : $self->checkForward('writegff',$fob,$oidobs);
      if ($hasforward && !$l_hasforward && !$gffend) { $self->writeGFFendfeat($gffh); $gffend++; }
      $l_hasforward= $hasforward; #?
      if ($hasforward) {
        $fob->{'writegff'}=1; # flag we have it for checkForward
        push(@gffForwards, $fob);
        }
      else {
        while (@gffForwards) { $self->writeGFF( $gffh, shift @gffForwards,$oidobs) ;  }
        ## if we drop use of ID=oid, need to resolve all forwards before writeGFF
        $self->writeGFF( $gffh,$fob,$oidobs) ; 
        $gffend=0;
        }
      }
      
    if ($flag =~ /final/) {
      while (@gffForwards) { $self->writeGFF( $gffh,shift @gffForwards,$oidobs) ; }
      }
    $gffh->flush();
    }
    $self->{curformat}= '';  
}


sub writeHeader
{
	my $self= shift;
  my($outh,$fmt,$chr)= @_;
  my $chrlen= defined $chromosome->{$chr} && $chromosome->{$chr}->{length} || 0;

  ## foreach $fmt (@formats) { $self->{$fmt}->writeheader($outh->{$fmt},$chr,$chrlen); }
  $self->writeFFF1header($outh->{$fmt},$chr,$chrlen) if ($fmt eq 'fff');
  $self->writeGFF3header($outh->{$fmt},$chr,$chrlen) if ($fmt eq 'gff');
  
  ## add fasta output - no header ?
}



## SONG/so Revision: 1.45
##     @is_a@oligo ; SO:0000696 ; SOFA:SOFA ; synonym:oligonucleotide
## 'so' is no longer valid
##   old value: @is_a@so ; SO:1000000
## -- options are limited: located_sequence_feature, SO:0000110 ??
## -- in flybase, 'so' seems used for protein blast matches?
## segment not in this    
## alt choices ...
#      @is_a@assembly ; SO:0000353 ; SOFA:SOFA
# **    @is_a@golden_path ; SO:0000688 ; SOFA:SOFA   <<
# **    @is_a@supercontig ; SO:0000148 ; SOFA:SOFA ; synonym:scaffold    <<
#     @is_a@tiling_path ; SO:0000472 ; SOFA:SOFA
#     @is_a@virtual_sequence ; SO:0000499 ; SOFA:SOFA
#     @is_a@chromosome ; SO:0000340
#     @part_of@chromosome_arm ; SO:0000105

## aug04: add new analysis features (HDP,RNAiHDP,fgenesh,)
## these are like exons but parent feature lacks featureloc 
## - need to join together by object_oid/parent_oid and compute parent feature (has name)
## SO type.subtype should be match.program
## SONG: match, match_part match_set nucleotide_match cross_genome_match cDNA_match EST_match

#? use '.' instead of '_' for part type? would that throw gnomap/gbrowse usage? probably

sub setDefaultValues
{
  my($self)= @_;
  
  %maptype = (
    golden_path_region => "scaffold", # "golden_path", ##was "segment", .. is again
    oligonucleotide => "oligo", 
    transposable_element_pred => "transposable_element_pred",
    three_prime_untranslated_region => "three_prime_UTR",
    five_prime_untranslated_region => "five_prime_UTR",
  );
  
  %maptype_pattern = ();
  %mapname_pattern = ();
  %mapattr_pattern = ();
  %maptype_gff = ( 
    tRNA_trnascan => "tRNA:trnascan",
    transposable_element_pred => "transposable_element:predicted",
  );
  
  %segmentfeats = ( # == big feats; no kids 
    chromosome => 1, chromosome_arm => 1, chromosome_band => 1,
    source => 1,
    BAC => 1,
    segment => 1, golden_path => 1, golden_path_region => 1,
      ## segment no longer valid SO; supercontig or golden_path are best
    );
  
  ## some common ones needing simple start/end, not compound
  %simplefeat = (
    ## NOT these: gene => 1, pseudogene => 1, #? but has mRNA-like transcripts
    oligonucleotide => 1,
    point_mutation => 1,
    transcription_start_site => 1,
    repeat_region => 1,
    region => 1, # attached to gene parents .. RpL40-misc_feature-1
  );
  map { $simplefeat{$_}=1; } keys %segmentfeats;
   
  ## drop 'remark' feat from all ?
  %dropfeat_fff = ( ## for the parent/kid test for compound feats
    exon => 1,
    remark => 1,
    CDS_exon => 1, #? better type?
    # these following are not dropped, but compounded under each mRNA
    three_prime_UTR => 1, 
    five_prime_UTR => 1,
    CDS => 1,
    intron => 1,
    );
  
  %dropfeat_gff = ( ## for the parent/kid test for compound feats
    CDS_exon => 1,
    remark => 1,
    );
  
  # these uniquename's from chado are not useful .. same as name always?
  # now only for fff output? keep all ID for gff part resolving
  %dropid = (
    exon => 1,
    transcription_start_site => 1,
    transposable_element_pred => 1,
    intron => 1,
    repeat_region => 1,
    oligonucleotide => 1,
    processed_transcript => 1,
    EST => 1,
    cDNA_clone => 1,
    chromosome_band => 1,
  );
  
  %dropname = (
    mRNA_piecegenie => 1,
    mRNA_genscan => 1,
    tRNA_trnascan => 1,
    transcription_start_site => 1, # if these are like 174396-174397-AE003590.Sept-dummy-promoter
    ## drop 'JOSHTRANSPOSON-' from name of transposable_element_pred 'JOSHTRANSPOSON-copia{}293-pred'
  );
  
      ## need to turn name/id into dbxref attrib
      ## feats: processed_transcript , EST, protein -- instead make compound by same OID !
  %mergematch = (
    ##EST => 1,
    ##processed_transcript => 1,
    ##### protein => 1, # only if not CDS!!!
    );
  %keepstrand=();  
  %hasdups = (
    exon => 1,
    three_prime_UTR => 1,
    five_prime_UTR => 1,
  );
  ##map { $hasdups{$_}=1; } keys %mergematch;
  
  # these are ones where parent feature == gene needs renaming
  $rename_child_type = ""; # old: join('|', 'pseudogene','\w+RNA' );
  
}


#---- FFF output -- separate package ?



sub writeFFF1header
{
	my $self= shift;
  my($fh,$seqid,$start,$stop)= @_;
  
  if ((!defined $stop || $stop == 0)) {
    $stop= $start; $start= 1; # start == length
    }
  my $date = $self->{date};
  my $sourcetitle = $self->{sourcetitle};
  my $sourcefile = $self->{sourcefile};
  my $org= $self->{species} || $self->{org};
  print $fh "# Features for $org from $sourcetitle [$sourcefile, $date]\n";
  print $fh "# gnomap-version 1\n";
  print $fh "# source: ",join("\t", $seqid, "$start..$stop"),"\n";
  ##print $fh "# ",join("\t", qw(Feature gene map range id db_xref notes)),"\n";
  print $fh "# ",join("\t", qw(Feature name cytomap location id db_xref notes)),"\n";
  print $fh "#\n";
   
  if ($stop > $start) {
    if ($fff_mergecols) {
      my $bstart= TOP_SORT; # if ($self->{config}->{topsort}->{$fob->{type}});
      print $fh join("\t", $seqid, $bstart, "source", $org, $seqid, "$start..$stop", $seqid,)."\n";
      }
    else {
      print $fh join("\t", "source", $org, $seqid, "$start..$stop", $seqid,)."\n";
      }
    }
}


sub _fffEscape
{
  my $v= shift;
  # $v =~ tr/ /+/; #? leave in spc ?
  $v =~ s/([\t\n\=&;,])/sprintf("%%%X",ord($1))/ge;  
  return $v;
}


=item getFFF v1

  return tab-delimied feature lines in this format 
  # gnomap-version $gnomapvers
  # Feature	gene 	map 	range 	id	db_xref  	notes
  
  feature == feature type
  gene    == gene name
  map     == cytology map
  range   == GenBank/EMBL/DDBJ location, BioPerl FTstring)
  id      == feature id
  db_xref == database crossrefs (, delimited)
  notes   == miscellany, now key=value; list
  
=cut

sub getFFF 
{
	my $self= shift;
  my($fob,$oidobs)= @_;
  return if ($fob->{'writefff'}); #?? so far ok but for mature_peptide/CDS thing
  $fob->{'writefff'}=1;
  my @loc= @{$fob->{loc}};
  my @attr= @{$fob->{attr}};
  
  my $oid= $fob->{oid};  
  my $featname= $fob->{type};
  my $fulltype= $fob->{fulltype};
  my($id,$s_id)= $self->remapId($featname,$fob->{id},'-'); 
  $id= '-' unless (defined($id) && $id);
  
  (my $ftop= $fulltype) =~ s/[\:\.].*$//;
  if ($ftop && $featname =~ /^$ftop/) { $featname= $fulltype; } #?? want this 
  
  my $sym= $fob->{name} || '-';
  $sym = _fffEscape($sym);
  
  my $map= '-';
  my $dbxref=""; my $dbxref_2nd="";
  my $notes= "";
  my %at=(); 
  foreach (@attr) {
    my ($k,$v)= split "\t";

    ## synonym_2nd=ribosomal protein S3&agr;; << problem; escape
    $v = _fffEscape($v);  # _gffEscape; at least any [\t\n\=&;,]

    if ($k eq "object_oid") {
      # skip
      }
    elsif ($k eq "synonym" && ($v eq $id || $v eq $sym)) { next; }
      
    elsif ($k eq "parent_oid") { ## added apr05
      next if $segmentfeats{$featname}; # dont do parent for these ... ?
      $v =~ s/:.*$//; #$v= $oidmap{$v} || $v;
      $k= 'Parent'; 
      
      my $parob= $oidobs->{$v}->{fob};
      if ($parob && $parob->{id}) {
        $v= $parob->{id};
        #? if ($oidisid_gff{$type}) { $v= $parob->{oid}; } 
        
        if ($v eq $id) { ## FIXME .. ? try to use index in parent->{child} array ?
          my $i= 1;
          my $paroid= $parob->{oid};
          my $kids  = $oidobs->{$paroid}->{child};
          if ($kids) { 
          foreach my $kidob (@{$kids}) {
            last if ($kidob->{oid} eq $oid);
            $i++;
            }
           }
          $id= "$id.$i";
          # $at[0]= "ID="._gffEscape($id);
          }

        $at{$k} .= ',' if $at{$k};
        $at{$k} .= $v;  
        }
      else {
        #next if ($fulltype =~ /match_part|cytology|band|oligo|BAC/ || $id =~ /GA\d/); 
        #print STDERR "GFF: missed Parent ID for i/o/t:",$id,"/",$oid,"/",$fulltype,
        #  " parob=",$parob," k/v=",$k,"/",$v, " \n" if $DEBUG;
        next; # always skip writing bogus Parent= to gff
        }

      }
    elsif ($k eq "cyto_range") { $map= $v; }
    elsif ($k eq "dbxref") { ## and dbxref_2nd; put after dbxref !
      $dbxref .= "$v;"; 
      }
    elsif ($k eq "dbxref_2nd") {  
      $dbxref_2nd .= "$v;"; 
      }
       
    elsif ($k) {
      #$notes .= "$k=$v;" 
      $at{$k} .= ',' if $at{$k};
      $at{$k} .= $v;  
      }
    }

  my @at=();
  foreach my $k (sort keys %at) { push(@at, "$k=$at{$k}"); }
  $notes = join(";",@at);

  $dbxref .= $dbxref_2nd; # aug04: making sure 2nd are last is enough to get 1st ID
  
  my ($srange,$bstart,$strand);
  #my $srange = $fob->{location}; # computed already for transsplice ?
  #my $bstart = $fob->{start}; # computed already for transsplice ?
  #unless($srange && defined $bstart) ...
  ($srange,$bstart,$strand) = $self->getLocation($fob,@loc);
  
  ## feb05: need to preserve strand==0/undefined for some features which have mixture
  if ($strand == 0 && $keepstrand{$featname}) { $notes .= "strand=0;"; }
  
  ## add chr,start to front cols for sort-merge
  if ($fff_mergecols) {
    my $chr= $fob->{chr};
    return join("\t", $chr,$bstart,$featname,$sym,$map,$srange,$id,$dbxref,$notes)."\n";
    }
  else {
    return join("\t", $featname,$sym,$map,$srange,$id,$dbxref,$notes)."\n";
    }
}


sub writeFFF 
{
	my $self= shift;
  my($fh,$fob,$oidobs)= @_;
  my $fffline= $self->getFFF($fob,$oidobs);
  print $fh $fffline if $fffline;
}

#---- GFF output -- separate package ?


=item writeGFF v3

  ##gff-version   3
  ##sequence-region   ctg123 1 1497228      == source in fff
  ctg123 . gene            1000  9000  .  +  .  ID=gene00001;Name=EDEN
  ctg123 . TF_binding_site 1000  1012  .  +  .  ID=tfbs00001;Parent=gene00001
  ctg123 . mRNA            1050  9000  .  +  .  ID=mRNA00001;Parent=gene00001;Name=EDEN.1
  ctg123 . 5_prime_UTR          1050  1200  .  +  .  Parent=mRNA0001
  ctg123 . CDS             1201  1500  .  +  0  Parent=mRNA0001
  ctg123 . CDS             3000  3902  .  +  0  Parent=mRNA0001
  ctg123 . CDS             5000  5500  .  +  0  Parent=mRNA0001
  ctg123 . CDS             7000  7600  .  +  0  Parent=mRNA0001
  ctg123 . 3_prime_UTR          7601  9000  .  +  .  Parent=mRNA0001

=cut

sub writeGFF3header
{
	my $self= shift;
  my($fh,$seqid,$start,$stop)= @_;
  
  if ((!defined $stop || $stop == 0)) {
    $stop= $start; $start= 1;  # start == length
    }
    
  my $date = $self->{date};
  my $sourcetitle = $self->{sourcetitle};
  my $org= $self->{species} || $self->{org};
  print $fh "##gff-version\t3\n";
  print $fh "##sequence-region\t$seqid\t$start\t$stop\n" if($seqid && $stop); #? always or only if missing chromosome?
  print $fh "#organism\t$org\n";
  print $fh "#source\t$sourcetitle\n";
  print $fh "#date\t$date\n";
  print $fh "#\n";
  
  ## DONT write chromosome twice -- check fobs 
  ##sequence-region   ctg123 1 1497228      == source in fff
  ## if ($stop > $start) ...
  print $fh join("\t", $seqid, ".","chromosome", $start, $stop, '.', '.', '.', "ID=$seqid"),"\n" 
    if ($seqid && $stop && $self->config->{gff_addchromosome}); # also "chromosome" needs to be config-type

   
}

sub writeGFFendfeat
{
	my $self= shift;
  my($fh)= @_;
  print $fh "###\n";
}

sub splitGffType
{
	my $self= shift;
  my($gffsource,$type,$fulltype)= @_;
  my($newgffs)=('');
    #? use fulltype instead of type? as 'match:sim4:na_EST_complete_dros'
    # convert mRNA_genscan,mRNA_piecegenie to gffsource,mRNA ?
  if ($maptype_gff{$type}) {
    ##($type,$newgffs)= @{$maptype_gff{$type}};
    ($type,$newgffs)= split(/[\.:]/,$maptype_gff{$type},2);
    }
  elsif ($fulltype =~ m/^([\w\_]+)[\.:]([\w\_\.:]+)$/) {
    ($type,$newgffs)=($1,$2);
    }
  elsif ($type =~ m/^([\w\_]+)[\.:]([\w\_\.:]+)$/) {
    ($type,$newgffs)=($1,$2);
    }
  else { $type= $fulltype; } #?? feb05; want snRNA not mRNA .. leave in fulltype ?
  $gffsource= $newgffs if($newgffs && $newgffs ne '.'); 
  
  return($gffsource,$type);
}

sub _gffEscape
{
  my $v= shift;
  $v =~ tr/ /+/;
  $v =~ s/([\t\n\=&;,])/sprintf("%%%X",ord($1))/ge; # Bio::Tools::GFF _gff3_string escaper
  return $v;
}

=item writeGFF  
   
   write  one feature in gff3
   feature may have sub location parts (multi line)
   
=cut

sub writeGFF
{
	my $self= shift;
  my($fh,$fob,$oidobs)= @_;
  my $type= $fob->{type};
  my $fulltype= $fob->{fulltype};
  return if ($fob->{'writegff'});
  $fob->{'writegff'}=1;
  if ($dropfeat_gff{$type}) { return; }
  my $gffsource= $fob->{gffsource} || $self->{gff_config}->{GFF_source} ||  ".";
  my $oid= $fob->{oid};  
  my $id = $fob->{id}; ## was: $fob->{oid}; -- preserve uniquename ?
  my $chr= $fob->{chr};
  my @loc= @{$fob->{loc}};
  my @attr= @{$fob->{attr}};
  my $at="";
  my @at= ();
  my %at= ();

  
=item  gff IDs

  ## gff3 loader is using ID for uniquename, unless give attr key for uniquename
  ## ? do we want to drop $oid and use id/dbid - is it always uniq in gff file?

  ## feb05; need to test parid != id; problem now w/ some features (match/match_part same id)
  ## feb05 - EST's now have same ID for different location matches; need uniq gff id
  ## sim4:na_dbEST.diff.dmel .. use object_oid ?

=cut
  
  if ($oidisid_gff{$type}) { $id= $oid; } 

  # my($id,$s_id)= $self->remapId($type,$fob->{id}); #?? want for gff also ??
  
  my $ignore_missingparent= $self->config->{maptype_ignore_missingparent} || '^xxxx';
  
  my $v;
  push @at, "ID="._gffEscape($id) if ($id); # use this for gff internal id instead of public id?
    # ^^ if have parent, drop id ?? always or sometimes ?
  push @at, "Name="._gffEscape($v) if (($v= $fob->{name}) && $v ne $id);
  if ($gff_keepoids) {  push @at, "oid=$oid"; }

  foreach (@attr) {
    my ($k,$v)= split "\t";
    if (!$v) { next; }
    elsif ($k eq "object_oid") { next; }
    elsif ($k eq "parent_oid") {
      if ($gff_keepoids) { $at{$k} .= ',' if $at{$k}; $at{$k} .= $v; }
      next if $segmentfeats{$type}; # dont do parent for these ... ?
      
      $v =~ s/:.*$//; #$v= $oidmap{$v} || $v;
      $k= 'Parent'; #push @at, "Parent=$v";
      
      ## now need to convert oid to parent id, given above change to id
      ## BUT this is bad when Parent hasn't been seen yet !
      
=item  BUG

      ## Dec04 -- sometimes miss parent id here; get OID instead in output
      ##  grep CG32584 dmel-X-r4.0.gff 
      ##  mRNA ID=CG32584-RB;Parent=3108188;      
      ##  mRNA ID=CG32584-RA;Parent=CG32584
      ## lots for match_part .. ignore those?

>> not many; 1/2 per csome; 
>> could be due to garbage collect. on oidobs; try MAX_FORWARD_RANGE+++
>>  MAX_FORWARD_RANGE => 990000 seems to have fixed it

=cut

      my $parob= $oidobs->{$v}->{fob};
      if ($parob && $parob->{id}) {
        $v= $parob->{id};
        if ($oidisid_gff{$type}) { $v= $parob->{oid}; } 
        
        if ($v eq $id) { ## FIXME .. ? try to use index in parent->{child} array ?
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
          $at[0]= "ID="._gffEscape($id);
          }
        }
      else {
        unless($fulltype =~ /$ignore_missingparent/) { ## || $id =~ /GA\d/
          # dpse GA genes; odd parent = csome; ignore parent here? FIXME
          print STDERR "GFF: MISSING parent ob for i/o/t:",$id,"/",$oid,"/",$fulltype,
          " parob=",$parob," k/v=",$k,"/",$v, " \n" if $DEBUG;
          }
        next; # always skip writing bogus Parent= to gff
        }
      }
    elsif ($k eq "dbxref" || $k eq "db_xref") { # dbxref_2nd - leave as separate 
      $k= 'Dbxref'; 
      ##$v= "\"$v\"";  # NO quotes - spec says to but BioPerl::GFFv3 reader doesn't strip quotes
      }
    elsif ($k eq "synonym") { # check dupl ID
      next if ($v eq $id || $v eq $fob->{name});
      }
      
    if ($k) {
      $at{$k} .= ',' if $at{$k}; # got duplicate Parent=aaa,aaa in dpse data; why?
      $at{$k} .= _gffEscape($v);  # should be urlencode($v) - at least any [=,;\s]
      }
    }
  
  ($gffsource,$type)= $self->splitGffType($gffsource,$type,$fulltype);
  
  ## drop ID if Parent ; sometimes ?
  my $parent= delete $at{'Parent'};
  if( $parent && $dropid{$type} ) { $at[0]=  "Parent=$parent"; }
  elsif ($parent){ push(@at, "Parent=$parent");  }
  
  foreach my $k (sort keys %at) { push(@at, "$k=$at{$k}"); }
  $at = join(";",@at);
  
    ## need to make uniq ids for dupl oids - any @loc > 1 ?
    ## and need to make parent feature to join.  Use ID=OID.1... OID.n
  if (@loc>1) {
    my ($b,$e,$str)=(-999,0,0);
    foreach my $loc (@loc) {
      my($start,$stop,$strand)= split("\t",$loc);
      if ($b == -999) { ($b,$e) = ($start,$stop); $str= $strand; }
      else { $b= $start if ($b > $start); $e= $stop if ($e < $stop); }
      }
    $str= (!defined $str || $str eq '') ? '.' : ($str < 0) ? '-' : ($str >= 1)? '+' : '.';
    print $fh join("\t", $chr,$gffsource,$type,$b,$e,".",$str,".",$at),"\n";

    ## GFF v3 spec is unclear on what this $gffsource item contains.
    ## gffsource used for genscan, etc. type modifier, also for database sig, e.g. SGD 
    
    $gffsource='part_of' if ($gffsource eq '.'); #? was 'part'
    
    foreach my $i (1..$#loc+1) {
      my($start,$stop,$strand)= split("\t",$loc[$i-1]);
      $strand= (!defined $strand || $strand eq '') ? '.' : ($strand < 0) ? '-' : ($strand >= 1)? '+' : '.';
      $at= "ID=$id.$i;Parent=$id"; #?
      print $fh join("\t", $chr,$gffsource,$type,$start,$stop,".",$strand,".",$at),"\n";
      }
    }
  else {
    my $loc= shift @loc;
    my($start,$stop,$strand)= split("\t",$loc);
    $strand= (!defined $strand || $strand eq '') ? '.' : ($strand < 0) ? '-' : ($strand >= 1)? '+' : '.';
    print $fh join("\t", $chr,$gffsource,$type,$start,$stop,".",$strand,".",$at),"\n";
    }
}






1;

__END__

