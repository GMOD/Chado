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
use lib("/bio/biodb/common/perl/lib", "/bio/biodb/common/system-local/perl/lib");

use POSIX;
use FileHandle;
use File::Spec::Functions qw/ catdir catfile /;
use File::Basename;

use vars qw(@ISA);
use Bio::GMOD::Bulkfiles::BulkWriter;       
@ISA= (qw/Bio::GMOD::Bulkfiles::BulkWriter/); ## want interface class

our $DEBUG = 0;
my $VERSION = "1.0";
my $maxout = 0;
my $ntotalout= 0;

## move all these package globals to self object

##my $org='dmel'; # 'fly'; #??
##my $rel="r0";
##my $sourceName="FlyBase Chado DB";
##my $sourceFile="stdin";

my $chromosome= {};  ## read info from chado dump chromosomes.tsv 
my $configfile= "chadofeatdump";

my $fff_mergecols=1; # $self->{fff_mergecols} add chr,start cols for merge
my $gff_keepoids= 0; # $self->{gff_keepoids}
my @outformats= (); 
my @defaultformats= qw(fff gff); # cmap ?? fasta - no
my %formatOk= ( fff => 1, gff => 1 ); # only these handled here ?
my @GModelParts= qw( CDS  five_prime_UTR three_prime_UTR intron );

my $outfile= undef; # "chadofeat"; ## replace w/ get_filename !
my $append=0; # $self->{append}

my %gffForwards=();
my @gffForwards=();

use constant TOP_SORT => -9999999;

## our == global scope; use vars == package scope
use vars qw/ 
  %maptype      
  %maptype_pattern
  %mapname_pattern
  %maptype_gff  
  %segmentfeats 
  %simplefeat   
  %skipaskid    
  %dropfeat_fff 
  %dropfeat_gff 
  %dropid       
  %dropname     
  %mergematch   
  %hasdups  
  $rename_child_type
  $name2type_pattern
  /;


sub init 
{
	my $self= shift;
  $self->SUPER::init();
	# $self->{tag}= 'Bulkfiles::FeatureWriter' unless (exists $self->{tag} );
	$self->{outh} = {};
	$DEBUG= $self->{debug} if defined $self->{debug};

#  $self->{configfile}= $configfile unless defined $self->{configfile};
  # $self->{failonerror}= 0 unless defined $self->{failonerror};
  $self->setDefaultValues(); #?? use or not?

}


=item initData

initialize data from config

=cut

sub initData
{
  my($self)= @_;
  $self->SUPER::initData();
  my $config= $self->{config};
  my $sconfig= $self->handler()->{config};
 
    ## use instead $self->handler()->{config} values here?
#   $self->{org}= $sconfig->{org} || $config->{org} || 'noname';
#   $self->{rel}= $sconfig->{rel} || $config->{rel} || 'noname';  
#   $self->{sourcetitle}= $sconfig->{title} || $config->{title} || 'untitled'; 
#   $self->{sourcefile} = $config->{input}  || '';  
#   $self->{date}= $sconfig->{date} || $config->{date} ||  POSIX::strftime("%d-%B-%Y", localtime( $^T ));

 
  $self->{idpattern} = $sconfig->{idpattern} || $config->{idpattern} || '';

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
    
  $rename_child_type= $config->{rename_child_type};
  $name2type_pattern= $config->{name2type_pattern};
  
  %maptype      = %{ $config->{'maptype'} } if ref $config->{'maptype'};
  %maptype_pattern= %{ $config->{'maptype_pattern'} } if ref $config->{'maptype_pattern'};
  %mapname_pattern= %{ $config->{'mapname_pattern'} } if ref $config->{'mapname_pattern'};
  %maptype_gff  = %{ $config->{'maptype_gff'} } if ref $config->{'maptype_gff'};
  %segmentfeats = %{ $config->{'segmentfeats'} } if ref $config->{'segmentfeats'};
  %simplefeat   = %{ $config->{'simplefeat'} } if ref $config->{'simplefeat'};
  %skipaskid    = %{ $config->{'skipaskid'} } if ref $config->{'skipaskid'};
  %dropfeat_fff = %{ $config->{'dropfeat_fff'} } if ref $config->{'dropfeat_fff'};
  %dropfeat_gff = %{ $config->{'dropfeat_gff'} } if ref $config->{'dropfeat_gff'};
  %dropid       = %{ $config->{'dropid'} } if ref $config->{'dropid'};
  %dropname     = %{ $config->{'dropname'} } if ref $config->{'dropname'};
  %mergematch   = %{ $config->{'mergematch'} } if ref $config->{'mergematch'};
  %hasdups      = %{ $config->{'hasdups'} } if ref $config->{'hasdups'};

  @GModelParts  = qw( CDS five_prime_UTR three_prime_UTR intron );
  @GModelParts  = @{ $config->{'gmodel_parts'} } if ref $config->{'gmodel_parts'};
  
   ## read these also ...
  $config->{maptype}= \%maptype;
  $config->{maptype_pattern}= \%maptype_pattern;
  $config->{mapname_pattern}= \%mapname_pattern;
  $config->{maptype_gff}= \%maptype_gff;
  $config->{segmentfeats}= \%segmentfeats;
  $config->{simplefeat}= \%simplefeat;
  $config->{skipaskid}= \%skipaskid;
  $config->{dropfeat_fff}= \%dropfeat_fff;
  $config->{dropfeat_gff}= \%dropfeat_gff;
  $config->{dropid}= \%dropid;
  $config->{dropname}= \%dropname;
  $config->{mergematch}= \%mergematch;
  $config->{hasdups}= \%hasdups;
  $config->{rename_child_type}= $rename_child_type;

  ## merge config from this INTO handler config ?
  ## that is best place to keep common <featmap> and <featset>
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
  unless(ref $fileset) { 
    my $intype= $self->{config}->{informat} || 'feature_table'; #? maybe array
    $fileset = $self->handler->getFiles($intype, $chromosomes);  
    # warn "FeatureWriter::makeFiles: no infiles => \@filesets given"; return;  
    }
 
  my @saveformats= @outformats;
  if ($args{formats}) {
    my $formats= $args{formats};
    if(ref $formats) { @outformats= @$formats; } 
    else { @outformats=($formats); } 
    }
  @outformats= grep { $formatOk{$_}; }  @outformats;
  print STDERR "FeatureWriter::makeFiles outformats= @outformats\n" if $DEBUG; 
  
  my $ok= 1;
  for (my $ipart= 0; $ok; $ipart++) {
    $ok= 0;
    my $inh= $self->openInput($fileset, $ipart);
    if ($inh) {
      my $res= $self->processChadoTable( $inh);
      close($inh);
      $ok= 1;
      }
    }
    
  @outformats = @saveformats;
  print STDERR "FeatureWriter::makeFiles: done\n" if $DEBUG; 
  return 1; #what?
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

  my $intype= $self->{config}->{informat} || 'feature_table'; #? maybe array
  my $atpart= 0;
  print STDERR "openInput: type=$intype part=$ipart \n" if $DEBUG; 
  
  foreach my $fs (@$fileset) {
    my $fp= $fs->{path};
    my $name= $fs->{name};
    my $type= $fs->{type};
    next unless($fs->{type} eq $intype); 
    unless(-e $fp) { warn "missing dumpfile $fp"; next; }
    $atpart++;
    next unless($atpart > $ipart);
    print STDERR "openInput: name=$name, type=$type, $fp\n" if $DEBUG; 

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
  print STDERR "openInput: nothing matches part=$ipart\n" if $DEBUG; 
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
  if ($dropid{$type} || $id =~ /^NULL:/) { $id= undef; }
  #?? or not# elsif (!$id) { $id= $name; } 
  return ($id,$save);
}


sub remapName
{
	my $self= shift;
  my ($type,$name,$id)= @_;
  my $save= $name;
  if ( $dropname{$type} ) { $name= ''; }
  #elsif ($type eq 'transposable_element_pred') { $name =~ s/JOSHTRANSPOSON-//; }
  ## clean unwieldy predictor names: contig...contig...
  elsif ($type =~ /^(gene|mRNA)/ && $name =~ s/Contig[_\d]+//g) { 
    if ($name =~ m/^(twinscan|genewise|genscan)/i) { $name= "${id}_${name}"; }
    }
  #elsif ($name =~ /dummy/) { $name =~ s/\-dummy\-//; } # from analysis.source default
  elsif (!$name) { $name= $id; } 
  else {
    ## this one could be time sink .. use evaled sub {} ?
    foreach my $mp (sort keys %mapname_pattern) {
      next if ($mp eq 'null'); # dummy?
      my $mtype= $mapname_pattern{$mp}->{type};
      next if ($mtype && $type !~ m/$mtype/);
      if ($mapname_pattern{$mp}->{cuttype}) {
        my @tparts= split(/[_]/, $type);
        foreach my $t (@tparts) { $name =~ s/\W?$t\W?//; }
        next;
        }
      my $from= $mapname_pattern{$mp}->{from}; next unless($from);
      my $to  = $mapname_pattern{$mp}->{to};
      if ($to =~ /\$/) { $name =~ s/$from/eval($to)/e; }
      else { $name =~ s/$from/$to/; }
      }
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
  
  my $nutype  = $type;
  # this should be config pattern: ..genscan..
  ##if (defined $name && $name =~ m/[-_](genscan|piecegenie|twinscan|genewise|pred|trnascan)/i) {
  if ($name2type_pattern && defined $name && $name =~ m/$name2type_pattern/i) {
    $nutype .= "_".lc($1);
    }
  $nutype =~ s/[:\.]/_/g; #?
  $type = $maptype{$nutype} || $type;
  
    ## this one could be time sink .. use evaled sub {} ?
#   foreach my $mp (keys %maptype_pattern) {
#     next if ($mp eq 'null');  
#     my $mname= $maptype_pattern{$mp}->{typename};
#     next if ($mname && $name !~ m/$mname/);
#     my $from= $maptype_pattern{$mp}->{from};
#     my $to  = $maptype_pattern{$mp}->{to};
#     $type =~ s/$from/$to/;
#     }
  
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
 
=cut

sub processChadoTable
{
	my $self= shift;
  my($fh, $outh)=  @_;
  
  $outh= $self->{outh} unless(ref $outh);
  my %origin_one= %{ $self->{config}->{origin_one} || {} };
  
  my $tab= "\t"; # '[\|]'; ##"\t"; < '|' is bad sep cause some names have it !

  my @fobs=();
  my %oidobs=();
  my $fob=undef;
  my @chead=();
  my @l_fobs=();
  my $max_max=0; my $min_max= 0;
  my $armlen=0;
  my $ndone= 0;
  my ($l_arm,$l_fmin,$l_fmax,$l_strand,$l_type,$l_name,$l_id,$l_oid,$l_attr_type,$l_attribute);
  
  ($l_arm,$l_oid,$l_fmin,$max_max)= (0,0,0,1);
  
  while(<$fh>){
    next unless(/^\w/);
    next if(/^arm\tfmin/); # header from sql out
    $ndone++; 
    last if ($maxout>0 && $ndone > $maxout);
    chomp;
    my @c= split("\t"); # $tab
 
    my ($arm,$fmin,$fmax,$strand,$type,$name,$id,$oid,$attr_type,$attribute)= @c;

    ## data fixes
    unless(defined $fmax) { $fmax=0; }
    unless(defined $fmin) { $fmin=0; }
    else { $fmin += 1 unless ($origin_one{$type}); } # dang -1 chado start 
    $strand=0 unless($strand);
    ## this check only for intron,UTR chado-computed locs ??
    if ($fmax < $fmin) { ($fmin,$fmax)= ($fmax,$fmin); $strand= ($strand==0) ? -1 : -$strand; }
    
    my($s_type, $fulltype, $s_arm, $armfile, $s_name, $s_id);
    
#     ($arm,$fmin,$fmax,$strand,$armfile,$s_arm)  
#       = $self->remapArm($arm,$fmin,$fmax,$strand); # for dpse joined contigs 

    ($type,$fulltype,$s_type)= $self->remapType($type,$name); #my $transtype= 
    next if ($type eq 'skip'); # or what? undef?
    
    # ($id,$s_id)= $self->remapId($type,$id,$name); 

    ($name,$s_name)= $self->remapName($type,$name,$id); 

    ##  problem: processed_transcript  .. dbxref  genbank:FBgn0020497|CT32733|FBan0013387 GO:[protein-nucleus export (GO:0
    if ($type eq 'processed_transcript' && $attribute) {
      $attribute= undef if ($attribute !~ /^FlyBase/);
      }
    elsif ($type eq 'chromosome_band' && !$attribute) {
      $attr_type='cyto_range';
      $attribute=$s_name;  $attribute =~ s/band-//;
      }

    my $loc="$fmin\t$fmax\t$strand";

    my @addattr=();
    if ($attribute) {  
      # add dbxref_2nd patch? ; do we want to rename db here - looks like Gadfly from 2ndary/old ids
      $attribute =~ s/Gadfly:/FlyBase:/ if ($attr_type =~ m/^dbxref/);
      push( @addattr, "$attr_type\t$attribute");  
      }
    ##if ($to_species) {  push( @addattr, "species2\t$to_species");  }
    ##if ($an_program) {  push( @addattr, "analysis\t$an_program:$an_source");  }

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
    
    if ($oid eq $l_oid) {
      # same object - cat attributes into one set
      push( @{$fob->{loc}},  $loc) unless(grep /$loc/,@{$fob->{loc}});  
      
      foreach my $at (@addattr) {
        push( @{$fob->{attr}}, $at)
          unless( grep {$at eq $_} @{$fob->{attr}});  
        }
      }
      
    else {
      
      # if ($armfile ne $l_arm)  
      if ($arm ne $l_arm) {
        $self->putFeats($outh,\@fobs,\%oidobs,'final'); 
        @l_fobs=(); @fobs=();  %oidobs=(); %gffForwards=();
        $outh= $self->openCloseOutput($outh, $arm, 'open');
        $max_max=0; $min_max= 0;
        ## start new files / chr - fff, gff, fasta - need file opener/closer
        }
        
      #if ($type eq 'gene') 
      if ($fmin >= $max_max && $fmin > $min_max && scalar(@fobs)>10)  #= reset
        { 
        $self->putFeats($outh,\@fobs,\%oidobs,''); 
        @fobs=(); #@l_fobs= @fobs; 
        
        $min_max= $fmin + 20000; #?? will this help join parts
        ## can we clear out other obs yet: %oidobs=(); %gffForwards=(); ?
        ## if no forwards ?
        }


      my $newob= {};  
      push(@fobs,$newob);
      $oidobs{$oid}->{fob}= $newob;
      $fob= $newob;
      
      $fob->{chr} = $arm;
      $fob->{type}= $type;  
      $fob->{fulltype}= $fulltype;  # colon-delimited complex type 'match:program:source' 
      $fob->{name}= $name;
      $fob->{id}  = $id;
      $fob->{oid} = $oid;
      $fob->{loc} = [];
      $fob->{attr}= [];

      push( @{$fob->{loc}},  $loc);  
      
      foreach my $at (@addattr) {
        push( @{$fob->{attr}}, $at);  
        }
      }
    
    ## make oid crossref here so outputters know feature relations
    if ($attribute && $attr_type eq 'parent_oid' 
      && !$segmentfeats{$type} ## problem for segments, etc and gffForwards 
      && !$skipaskid{$type}  
        ##  mature_peptide attached to protein-CDS - causes 2nd CDS feature 
        ##  really need to turn into compound feature of its own (not CDS) 
      ) {
    
      (my $paroid= $attribute) =~ s/:(.*)$//;
      my $rank= ($1) ? $1 : 0;
      ####push( @{$fob->{attr}}, "rank\t$attribute");  
        # ? need this for exon, utr - but tied to parent_oid
      
      $oidobs{$paroid}->{child}= [] unless (ref $oidobs{$paroid}->{child});
      ##? use $rank to position in {child} array ??
      push( @{$oidobs{$paroid}->{child}}, $fob);

      ## need to either skip parent/child here or in gff forward for these types
      ##    $simplefeats{$type} or $segmentfeats{$type}; # dont do parent for these ... ?

      $oidobs{$oid}->{parent}= [] unless (ref $oidobs{$oid}->{parent});
      push( @{$oidobs{$oid}->{parent}}, $paroid);
 
      ## another fixup for  CDS/protein-of-mRNA feature set

          ## THIS SHOULD MOVE TO config maptype
     ## if ($fob->{type} eq 'protein') { $fob->{type}= 'CDS'; } 
      
      if ($fob->{type} ne 'mRNA' && $fob->{type} =~ m/^($rename_child_type)/) {
        # this is  bad for real gene subfeatures like point_mutation
        my $ptype= $fob->{type};
        my $parob= $oidobs{$paroid}->{fob};
        if ($parob && ( $parob->{type} eq 'gene' || $parob->{type} eq $ptype) ) { 
          $parob->{type}= $ptype; 
          $fob->{type}= 'mRNA'; 
          }
        }

      if ($fob->{type} =~ m/^(mRNA|CDS)$/) {
        my $parob= $oidobs{$paroid}->{fob};
        if ($parob) {
          ## for genscan/twinscan etc mrna's - retype as parent gene_pred type
          if ($parob->{type} =~ m/^gene_(\w+)/ ) { 
            $fob->{type} .= '_'.$1; 
            }
          # copy FBgn dbxref attr - ? do also for CDS
          my $idpattern= $self->{idpattern};
          foreach my $pidattr (@{$parob->{attr}}) { 
            next if ($pidattr =~ m/dbxref_2nd:/); #?
            if (!$idpattern || $pidattr =~ m/$idpattern/) { ## (FBgn|FBti)\d+/  
              push( @{$fob->{attr}}, $pidattr) unless( grep {$pidattr eq $_} @{$fob->{attr}});  
              last; # add only 1st/primary
              }
            }
          }
        }
        
      # repair bad names -- do below
      }
    
    
    ## forward ref checkpoint
    $max_max= $fmax if (!$segmentfeats{$fob->{type}} && $fmax > $max_max);  
    
    ($l_arm,$l_fmin,$l_fmax,$l_strand,$l_type,$l_name,$l_id,$l_oid,$l_attr_type,$l_attribute)= @c;   
    ## only need save these:
    ## ($l_arm,$l_oid,$l_fmin)=($armfile,$oid,$fmin);
    }
  
  # putFeat($outh,$fob); #push(@fobs,$fob) if ($fob);
  $self->putFeats($outh,\@fobs,\%oidobs, 'final'); @l_fobs= (); @fobs=(); %oidobs=();
  
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

sub  makeFlatFeats 
{
	my $self= shift;
  my ($fobs,$oidobs)= @_;
  my %obs= %$oidobs;
  
  my @cobs=();
  foreach my $fob (@$fobs) {  
    my $oid= $fob->{oid};
    my ($iskid,$ispar)= (0,0);
    my $oidob= $obs{$oid};
    my $ftype= $fob->{type};
    my $fulltype= $fob->{fulltype};
    my $id= $fob->{id};
    my $issimple= $simplefeat{$ftype};
     
    if (!$issimple && $oidob) {
      $iskid= (defined $oidob->{parent} && @{$oidob->{parent}} > 0);
      $ispar= (defined $oidob->{child} && @{$oidob->{child}} > 0);
      
      if ($iskid) { # check we have backref to parend obj ??
        my $ok= 0;
        foreach my $poid (@{$oidob->{parent}}) {
          if ($obs{$poid}) { $ok=1; last; }
          }
        $iskid= $ok;
        }
      }
      
    my $keepfeat= ($ispar || $self->keepfeat_fff($ftype));
    if ($keepfeat) {
      $issimple= ($issimple || !$ispar); # $ftype !~ m/^(CDS)$/ && 
      if ($issimple) { push(@cobs, $fob); } # simple feature
      else {
        my $kidobs= $oidob->{child};
        # has kids, make compound feature
        my $cob= $self->makeCompound( $fob, $kidobs, $ftype); 
        push(@cobs, $cob);
        }
      
      }
    
      # UTR here ? ?? insert CDS between UTR's ?
      ## some of intron,UTR have swapped locs = 4650373..4650371
    if ($ispar && $ftype eq 'mRNA') {
    
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
                       {
                         'oid' => 509317,
                         'id' => 'CG18001-PA',
                         'chr' => '2h',
                         'loc' => [
                                    '42705      42914   -1'
                                  ],
                         'type' => 'CDS',   << ok here but no CDS_exons
                         'attr' => [
                                     'parent_oid        509314'
                                   ],
                         'name' => 'CG18001-PA'
                       },
                       {
                         'writefff' => 1,
                         'chr' => '2h',
                         'attr' => [
                                     'parent_oid        509314:1'
                                   ],
                         'name' => 'CG18001:1',
                         'id' => 'CG18001:1',
                         'oid' => 509315,
                         'type' => 'exon',
                         'loc' => [
                                    '42973      43051   -1'
                                  ]
                       }
                     ]
        }

=cut


      foreach my $ftname (@GModelParts) {
        my $utrob= undef;
        my $exonobs=[];
        my $mrnaexons=[];
        my $kidobs=[];
        foreach my $kidob (@{$oidob->{child}}) {  
 
          if ($ftname eq 'CDS' && $kidob->{type} eq 'exon') {
            push(@$mrnaexons, $kidob); # save in case missing CDS_exon
            }
            
          if ($ftname eq 'CDS' && $kidob->{type} eq 'CDS') {
            $utrob= $kidob unless($utrob);
            ## urk - need to keep loc:start/stop to adjust CDS_exon end points !
            }
          elsif ($id =~ /CG32491/ && $ftname eq 'CDS' && $kidob->{type} eq 'exon') {
            ## patch for mdg4 bug
            push(@$exonobs, $kidob);
            }
          elsif ($ftname eq 'CDS' && $kidob->{type} eq 'CDS_exon') {
            push(@$kidobs, $kidob);
            ## missing this for het db ... FIXME 
            # bad CDS_exon for transspliced mdg4 ... sigh ... need to keep also regular exons?
            }

          elsif ($kidob->{type} eq $ftname) { 
            $utrob= $kidob unless($utrob);
            push(@$kidobs, $kidob); 
            
            ## double dang - want to copy gene model dbxref id into  these features, as per above
            my $idpattern= $self->{idpattern};
            foreach my $pidattr (@{$fob->{attr}}) { 
              next if ($pidattr =~ m/dbxref_2nd:/); #?
              if (!$idpattern || $pidattr =~ m/$idpattern/) { ## (FBgn|FBti)\d+/  
                push( @{$utrob->{attr}}, $pidattr) unless( grep {$pidattr eq $_} @{$utrob->{attr}});  
                last; # add only 1st/primary
                }
              }
            
            # repair bad names
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
        
          ## ERROR -  CDS/protein w/o CDS_exon parts - not harvard chado 'reporting' db
          ## fixme ... recreate from cds start/stop + mrna location ?
        if ($utrob && !@$kidobs) {
          if ($ftname eq 'CDS' && @$mrnaexons) {
            $kidobs= $self->getCDSexons($utrob, $mrnaexons);
            }
          }
          
        if ($utrob) { ## @$kidobs < do even if no kidobs ???
          
          ##print STDERR "makeCompound $ftname par=$id, kid=",$utrob->{id},  "\n" if $DEBUG;
          # below # if ($ftname eq 'CDS') { $kidobs= adjustCDSendpoints( $utrob, $kidobs); }
          my $cob= $self->makeCompound( $utrob, $kidobs, $ftname); 
          
            # patch bad data -- use getCDSexons above ??
          if ($id =~ /CG32491/ && $ftname eq 'CDS') {  
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

=item  makeCompound($fob,$kidobs,$ftype)

  create compound feature from parent, kids (e.g., mRNA + exons)
  
=cut

sub makeCompound
{
	my $self= shift;
  my ($fob,$kidobs,$ftype)= @_;
  
  my $cob= {};  # are these all constant per oid ?
  $cob->{chr} = $fob->{chr};
  $cob->{type}= $fob->{type};
  $cob->{fulltype}= $fob->{fulltype};
  $cob->{name}= $fob->{name};
  $cob->{id}  = $fob->{id};
  $cob->{oid} = $fob->{oid};
  $fob->{'writefff'}=1; # need here also !?
 
  #$cob->{attr}= $fob->{attr};
  $cob->{attr}= [];
  foreach my $attr (@{$fob->{attr}}) {
    push( @{$cob->{attr}}, $attr);  
    }
    
  ##FIXME - parent loc may need drop for kids locs (mRNA)
  ## bad also to pick all kids - only exon type for mRNA, others?
  ## FIXME - for protein && CDS types which are only child of mRNA, need to merge into
  ## compound feat.
  ## FIXME - for dang transspliced mod(mdg4) - if strands in locs differ -> getLocation
  
  my @locs= ();
  
  ## need to skip kids for 'gene', others ?
  foreach my $kid (@$kidobs) {
    next if ($fob->{type} eq 'mRNA' && $kid->{type} ne 'exon');
    if ($ftype eq 'CDS' && $kid->{type} eq 'mature_peptide')
    {
      $ftype= $cob->{type}= 'mature_peptide';
    }
    # next if ($fob->{type} eq 'CDS' && $kid->{type} ne 'CDS_exon');
    $kid->{'writefff'}=1; # need here also !?
    foreach my $loc (@{$kid->{loc}}) { push( @locs, $loc);  }
    }

  if ($ftype eq 'CDS') { 
    my $offsetloc = $fob->{loc}->[0]; # only 1 we hope
    $cob->{offloc}= $offsetloc;
    }
  
  unless(@locs) {
    #? never keep main loc if have kid loc?
    foreach my $loc (@{$fob->{loc}}) { push( @locs, $loc);  }
    }
  $cob->{loc}= \@locs;
    
  return $cob;
}



=item getLocation($fob,@loc)
  
  get feature genbank/embl/ddbj location string (FTstring)
  including transplice messes
  
  return ($location, $start);

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
  
  return ($srange, $bstart);
}


=item checkForward($flag,$fob,$oidobs)
  
  check for any remaining forwarded (unseen) objects (for gff)
  
=cut

sub checkForward
{
	my $self= shift;
  my ($flag,$fob,$oidobs)= @_;
  my $thisforward=0;
  my $oid= undef;
  
  my $issimple= ($fob && $segmentfeats{$fob->{type}});
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
      if ($pob && $pob->{fob} && $segmentfeats{$pob->{fob}->{type}}) { $done=1; }
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
  my $anyforward=0;
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
  
  if ($DEBUG>1 || $DEBUG && $flag =~ /final/) {
    print STDERR "putFeats n=$n, total=".($n+$ntotalout)
    .", oid1=".(($n>0)?$fobs->[0]->{oid}:0)."\n";
    }
  elsif ($DEBUG) {
    print STDERR ".";
    }
    
    
=item  

  ?? add interface to output formats: -- looks fairly complex - simple is nice

  my $cobs= undef;
  foreach $fmt (@formats) {  
    $fmtproc= $self->{$fmt};
    ## need to do fff before fasta, then save fffline for fasta header
    next if ($fmtproc->didwrite());
    
    if ($fmtproc->needsCompoundFeatures()) {
      $cobs= $self->makeFlatFeats($fobs,$oidobs) unless $cobs;
      foreach my $fob (@$cobs) {
        my $outline= $fmtproc->write( $self,  $fob, $oidobs, $flag);
        foreach my $fmtproc2 ($fmtproc->chainto()) {
          $fmtproc2->chainwrite( $self, $outline, $fob, $oidobs, $flag);
          }
        }
      }
    else {
      ## handle gff forward here or in fmtproc ??
      foreach my $fob (@$fobs) {
        my $outline= $fmtproc->write( $self,  $fob, $oidobs, $flag);
        foreach my $fmtproc2 ($fmtproc->chainto()) {
          $fmtproc2->chainwrite( $self,  $outline, $fob, $oidobs, $flag);
          }
        }
      }
      
    foreach my $fmtproc2 ($fmtproc->chainto()) { $fmtproc2->didwrite(1); }
  }
  
  
=cut

  if ($outh->{fff} || $outh->{fasta}) {
    my $ffh= $outh->{fff};
    my $fah= $outh->{fasta};
  
    my $cobs= $self->makeFlatFeats($fobs,$oidobs);
    my $nout= 0;
    foreach my $fob (@$cobs) {  
      my $fffline= $self->getFFF( $fob );
      next unless($fffline);
      print $ffh $fffline if $ffh;
      ##$self->writeFFF( $outh->{fff}, $fob);
      $nout++;

#         #?? separate this from makeFeatures > makeFasta ?
#       if ( $fah ) {
#         ## !URK! need a large set of fasta file handles, one for each featureset type
#         ## need to reverse lookup featset from this $fob->{type}
#         ## OR could split fasta files by featuretype after this 
#         my $featname= $fob->{type};
#         my $featset= $featname; ## cheater .. FIXME
#         my $chr= $fob->{chr};
#         my $fasta= $self->handler()->fastaFromFFF( $fffline, $chr, $featset);
#         print $fah $fasta if $fasta;
#         }
      }
      
    $ntotalout += $nout;
#     if ($outh->{fff}) {
#       my $fh= $outh->{fff};
#       print $fh "#\n" if ($nout>3);  # is this a section break?
#       }
  }
  
  if ($outh->{gff}) {
    my $gffh= $outh->{gff};
    # print $gffh "# fwd oid=".$self->getForwards()."\n"; # is this a section break?
    my $gffend= 0;
    $l_hasforward= $self->checkForward('writegff');
    foreach my $fob (@$fobs) { 
      $hasforward= $self->checkForward('writegff',$fob,$oidobs);
      if ($hasforward && !$l_hasforward && !$gffend) { $self->writeGFFendfeat($gffh); $gffend++; }
      $l_hasforward= $hasforward; #?
      if ($hasforward) {
        $fob->{'writegff'}=1; # flag we have it for checkForward
        push(@gffForwards, $fob);
        }
      else {
        while (@gffForwards) { $self->writeGFF( $gffh,shift @gffForwards,$oidobs) ;  }
        ## if we drop use of ID=oid, need to resolve all forwards before writeGFF
        $self->writeGFF( $gffh,$fob,$oidobs) ; 
        $gffend=0;
        }
      }
      
    if ($flag =~ /final/) {
      while (@gffForwards) { $self->writeGFF( $gffh,shift @gffForwards,$oidobs) ; }
      }
    }
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
    golden_path_region => "golden_path", ##was "segment",
    oligonucleotide => "oligo", 
    mRNA_genscan => "mRNA_genscan",
    mRNA_piecegenie => "mRNA_piecegenie",
    mRNA_trnascan => "tRNA_trnascan",
    #?? so => "located_sequence_feature", ## leave in for now; no replacement for so ; SO:1000000
    match_fgenesh => "match_fgenesh",
    match_RNAiHDP => "match_RNAiHDP",
    match_HDP => "match_HDP",
  
    transposable_element_pred => "transposable_element_pred",
    three_prime_untranslated_region => "three_prime_UTR",
    five_prime_untranslated_region => "five_prime_UTR",
    CDS => "CDS_exon",
    # protein => "CDS", # only if mRNA is parent !!
  );
  
  %maptype_pattern = ();
  %mapname_pattern = ();
  ## change to hash of hash : { fulltype => { gfftype => val, gffsource => val } }
  %maptype_gff = (
    mRNA_genscan => ["mRNA","genscan"],
    mRNA_piecegenie => ["mRNA","piecegenie"],
    tRNA_trnascan => ["tRNA","trnascan"],
  
    match_fgenesh => ["match","fgenesh"],
    match_RNAiHDP => ["match","RNAiHDP"],
    match_HDP => ["match","HDP"],
    match_part_fgenesh => ["match_part","fgenesh"],
    match_part_RNAiHDP => ["match_part","RNAiHDP"],
    match_part_HDP => ["match_part","HDP"],
  # for species, duplicate w/ "gene", "subtype"
  
    transposable_element_pred => 
      ["transposable_element","predicted"],
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
    gene => 1,
    pseudogene => 1, #? but has mRNA-like transcripts
    oligonucleotide => 1,
    point_mutation => 1,
    transcription_start_site => 1,
    repeat_region => 1,
    region => 1, # attached to gene parents .. RpL40-misc_feature-1
    mature_peptide => 1, #! attached to protein/CDS 
    ##so => 1,
    ##processed_transcript => 1, < are compound
    ##EST => 1, < some are compound !
  );
  map { $simplefeat{$_}=1; } keys %segmentfeats;
  
  # use to fix messup with mature_peptide attached to protein/cds - causes generation of 2nd CDS?
  %skipaskid = (
    point_mutation => 1,
    transcription_start_site => 1,
    repeat_region => 1,
    region => 1, # attached to gene parents .. RpL40-misc_feature-1
  ##  mature_peptide => 1, #! attached to protein/CDS -- fixed as own compound type
  );
  
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
    # all match_part_ ..
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
    ##three_prime_UTR => 1,  #?  keep, for fasta ?
    ##five_prime_UTR => 1,   #?   keep, for fasta ?
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
    
  %hasdups = (
    exon => 1,
    three_prime_UTR => 1,
    five_prime_UTR => 1,
    intron => 1,
  );
  ##map { $hasdups{$_}=1; } keys %mergematch;
  
  # these are ones where parent feature == gene needs renaming
  $rename_child_type = join('|', 'pseudogene','\w+RNA' );
  
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
  my $org= $self->{org};
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
  my($fob)= @_;
  return if ($fob->{'writefff'}); #?? so far ok but for mature_peptide/CDS thing
  $fob->{'writefff'}=1;
  my @loc= @{$fob->{loc}};
  my @attr= @{$fob->{attr}};
  
  my $featname= $fob->{type};
  my $fulltype= $fob->{fulltype};
  my($id,$s_id)= $self->remapId($featname,$fob->{id},'-'); 
  $id= '-' unless (defined($id) && $id);
  
  (my $ftop= $fulltype) =~ s/[\:\.].*$//;
  if ($ftop && $featname =~ /^$ftop/) { $featname= $fulltype; } #?? want this 
  
  my $sym= $fob->{name} || '-';
  my $map= '-';
  my $dbxref=""; my $dbxref_2nd="";
  my $notes= "";
  foreach (@attr) {
    my ($k,$v)= split "\t";
    if ($k eq "parent_oid" || $k eq "object_oid") {
      ##$v =~ s/:.*$//; #$v= $oidmap{$v} || $v;
      ##$at .= "Parent=$v;" 
      }
    elsif ($k eq "cyto_range") { $map= $v; }
    elsif ($k eq "dbxref") { ## and dbxref_2nd; put after dbxref !
      $dbxref .= "$v;"; 
      }
    elsif ($k eq "dbxref_2nd") {  
      $dbxref_2nd .= "$v;"; 
      }
    else {
      $notes .= "$k=$v;" 
      }
    }

  $dbxref .= $dbxref_2nd; # aug04: making sure 2nd are last is enough to get 1st ID
  
  my ($srange,$bstart);
  #my $srange = $fob->{location}; # computed already for transsplice ?
  #my $bstart = $fob->{start}; # computed already for transsplice ?
  #unless($srange && defined $bstart) { ...
  ($srange,$bstart) = $self->getLocation($fob,@loc);
  
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
  my($fh,$fob)= @_;
  my $fffline= $self->getFFF($fob);
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
  my $org= $self->{org};
  print $fh "##gff-version\t3\n";
  print $fh "##sequence-region\t$seqid\t$start\t$stop\n";
  print $fh "#organism\t$org\n";
  print $fh "#source\t$sourcetitle\n";
  print $fh "#date\t$date\n";
  print $fh "#\n";
  ##sequence-region   ctg123 1 1497228      == source in fff
  ## if ($stop > $start) ...
  print $fh join("\t", $seqid, ".","chromosome", $start, $stop, '.', '.', '.', "ID=$seqid"),"\n";
   
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
  
    #? use fulltype instead of type? as 'match:sim4:na_EST_complete_dros'
    # convert mRNA_genscan,mRNA_piecegenie to gffsource,mRNA ?
  if ($maptype_gff{$type}) {
    ($type,$gffsource)= @{$maptype_gff{$type}};
    }
  elsif ($fulltype =~ m/^([\w\_]+)[\.:]([\w\_\.:]+)$/) {
    ($type,$gffsource)=($1,$2);
    }
  elsif ($type =~ m/^([\w\_]+)[\.:]([\w\_\.:]+)$/) {
    ($type,$gffsource)=($1,$2);
    }
  return($gffsource,$type);
}

sub _gffEscape
{
  my $v= shift;
  $v =~ tr/ /+/;
  $v =~ s/([\t\n\=;,])/sprintf("%%%X",ord($1))/ge; # Bio::Tools::GFF _gff3_string escaper
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
  my $v;
  my $type= $fob->{type};
  my $fulltype= $fob->{fulltype};
  $fob->{'writegff'}=1;
  if ($dropfeat_gff{$type}) { return; }
  my $gffsource=".";
  my $oid= $fob->{oid};  
  my $id = $fob->{id}; ## was: $fob->{oid}; -- preserve uniquename ?
  my $chr= $fob->{chr};
  my @loc= @{$fob->{loc}};
  my @attr= @{$fob->{attr}};
  my $at="";
  my @at=();
  
  ## gff3 loader is using ID for uniquename, unless give attr key for uniquename
  ## ? do we want to drop $oid and use id/dbid - is it always uniq in gff file?
  ## below Parent from {id} is not working; need all forward refs resolved here
  
  push @at, "ID="._gffEscape($id) if ($id); # use this for gff internal id instead of public id?
  push @at, "Name="._gffEscape($v) if (($v= $fob->{name}) && $v ne $id);
  if ($gff_keepoids) {  push @at, "oid=$oid"; }

  my %at= ();
  foreach (@attr) {
    my ($k,$v)= split "\t";
    if (!$v) { next; }
    elsif ($k eq "object_oid") {}
    elsif ($k eq "parent_oid") {
      if ($gff_keepoids) { $at{$k} .= ',' if $at{$k}; $at{$k} .= $v; }
      next if $segmentfeats{$type}; # dont do parent for these ... ?
      
      $v =~ s/:.*$//; #$v= $oidmap{$v} || $v;
      $k= 'Parent'; #push @at, "Parent=$v";
      
      ## now need to convert oid to parent id, given above change to id
      ## BUT this is bad when Parent hasn't been seen yet !
      my $parob= $oidobs->{$v}->{fob};
      $v= $parob->{id} if ($parob && $parob->{id});
      }
    elsif ($k eq "dbxref") { # dbxref_2nd - leave as separate 
      $k= 'Dbxref'; 
      ##$v= "\"$v\"";  # NO quotes - spec says to but BioPerl::GFFv3 reader doesn't strip quotes
      }
      
    $at{$k} .= ',' if $at{$k};
    $at{$k} .= _gffEscape($v);  # should be urlencode($v) - at least any [=,;\s]
    }
    
  foreach my $k (sort keys %at) { push(@at, "$k=$at{$k}"); }
  $at = join(";",@at);
  
  ($gffsource,$type)= $self->splitGffType($gffsource,$type,$fulltype);
  
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
    ## gffsource used for genscan, etc. type modifier 
    
    $gffsource='part_of' if ($gffsource eq '.'); #? was 'part'
    
    foreach my $i (1..$#loc+1) {
      my($start,$stop,$strand)= split("\t",$loc[$i-1]);
      $strand= (!defined $strand || $strand eq '') ? '.' : ($strand < 0) ? '-' : ($strand >= 1)? '+' : '.';
      $at= "ID=$id.$i;Parent=$id";
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

