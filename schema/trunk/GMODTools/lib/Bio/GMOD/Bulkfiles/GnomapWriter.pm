package Bio::GMOD::Bulkfiles::GnomapWriter;
use strict;

=head1 NAME

  Bio::GMOD::Bulkfiles::GnomapWriter  
  
=head1 SYNOPSIS
  
  use Bio::GMOD::Bulkfiles;       
  
  my $sequtil= Bio::GMOD::Bulkfiles->new(  
    configfile => 'seqdump-r4', 
    );
  my $fwriter= $sequtil->getGnomapWriter(); 
  my $result = $fwriter->makeFiles( );
    
=head1 NOTES

  This is FlyBase-specific for now ; handles fly cytology map features
  and gnomap feature indexing
  
  genomic sequence file utilities, part3;
  parts from 
    flybase/work.local/chado_r3_2_26/soft/mergeflyfeats4.pl
  
=head1 AUTHOR

D.G. Gilbert, 2004, gilbertd@indiana.edu

=head1 METHODS

=cut

#-----------------


# debug
# use lib("/bio/biodb/common/perl/lib", "/bio/biodb/common/system-local/perl/lib");

use POSIX;
use FileHandle;
use File::Spec::Functions qw/ catdir catfile /;
use File::Basename;

use Bio::GMOD::Bulkfiles::BulkWriter;       
use vars qw(@ISA);
@ISA= (qw/Bio::GMOD::Bulkfiles::BulkWriter/); ## want interface class

use constant RECSIZE => length(pack("NN", 1, 50000));

our $DEBUG = 0;
my $VERSION = "1.0";
my $configfile= "tognomap"; #? BulkFiles/GnomapWriter.xml 
my $kMissingValue= -99999999;
my $kMaxValue= 999999999;
my $kMinValue= $kMissingValue+1;

use vars qw/ %flycsomebands $noIDmap $nameIsId $nameIsSpeciesId $cutdbpattern $indexidtype $indexidpattern /;

sub init 
{
	my $self= shift;
  $self->SUPER::init();
	$DEBUG= $self->{debug} if defined $self->{debug};
  $self->{configfile}= $configfile unless defined $self->{configfile};
}



=item initData

initialize data from config

=cut

sub initData
{
  my($self)= @_;
  $self->SUPER::initData();
  
  my $config = $self->{config};
  my $sconfig= $self->handler()->{config};
#  my $org= $self->{org} || $self->handler()->{config}->{org};

  ##  gnomapfiles
  my $finfo= $self->{fileinfo} || $self->handler()->getFilesetInfo('gnomap');
  my $dnainfo= $self->handler()->getFilesetInfo('dna');

  $self->{indexonly} = $finfo->{indexonly};

#   $noIDmap = $finfo->{noIDmap} 
#     || $config->{noIDmap} 
#     || 'cytowalk|protein|mRNA|CDS|EST|cDNA|oligo|processed|repeat|sim4';
  $noIDmap =  $finfo->{noIDmap} || $config->{noIDmap};
  unless($noIDmap) {
  $noIDmap= join '|',
  qw(cytowalk 
    _fragment 
    _junction 
    _mutation 
    _UTR 
    _variant 
    misc
    chromosome 
    enhancer  
    EST cDNA 
    intron 
    match motif sim4
    mRNA CDS 
    oligo processed 
    protein _peptide
    repeat
    regulatory_region repeat_region
    transposable_element_pred 
    );
  }
  $noIDmap =~ s/\s+/|/g; 
  $noIDmap .= '|\bregion';
  $noIDmap =~ s/\|\|/|/g;
  
  $nameIsId= $finfo->{nameisid} || $config->{nameisid} || '^(BAC)';
  $nameIsSpeciesId= $finfo->{nameisorgid} || $config->{nameisorgid} || '^(gene)$';  # others? rnas?
  $cutdbpattern=  $finfo->{idcutdb} || $config->{idcutdb} || '^(FlyBase|GadFly|GB_protein|GO):';

  $indexidtype= $finfo->{indexidtype} 
    || $config->{indexidtype} 
    || '^(gene|pseudogene|\w+RNA)';
  $indexidpattern= $finfo->{indexidpattern} 
    || $config->{indexidpattern} 
    || '[A-Z]{2}gn\d+';
    
  %flycsomebands = (
    'X'  => [ '1A1','20F4'],
    '2L' => ['21A1','40F7'],
    '2R' => ['41A1','60F5'],
    '3L' => ['61A1','80F9'],
    '3R' => ['81F1','100F5'],
    '4'  => ['101A1','102F8'],
    );
 
  
  my $gnomapdir= $self->handler()->getReleaseSubdir( $finfo->{path} || 'gnomap/');
  $self->{gnomapdir} = $config->{gnomapdir}= $gnomapdir;

  my $reldir= $self->handler()->getReleaseDir();
  
  my $dnareldir= $self->handler()->getReleaseSubdir( $dnainfo->{path} || 'dna/');
  $dnareldir =~ s,^$reldir,,;
  $dnareldir = "../$dnareldir";
  $self->{dnareldir}= $dnareldir;

  my $tfset  = $self->handler()->getFilesetInfo('tables');
  my $tabdir = $self->handler()->getReleaseSubdir( $tfset->{path} || 'tables/');
  $self->{summaryfile}= catfile( $tabdir, "feature_map-summary.txt"); 

  my @copytypes=();  
  foreach my $type ( keys %{$config->{fileset}} ) {
    my $fs= $config->{fileset}->{$type};
    push(@copytypes, $type) if ($fs->{copy});
    }
  $self->{copytypes}= \@copytypes;
  
  ## dont create subdir - use only if exists .. 
  ## change to $config->{fileset}->{cytofeat} // <fileset name=cytofeat ??
#   my $cytomapdir= $self->handler()->getReleaseSubdir( 
#       $config->{cytofeat}->{path} || 'cytomap/', 'nocreate');
#   $self->{cytomapdir} = $cytomapdir;

    ## this is replaced by fileset.cytomap split by chr
    ## need sep. package for flybase cytology map methods (various users)
  my $sorsa= $config->{sorsa}->{path};
  if ($sorsa) {
    $sorsa= catfile( $self->handler()->getReleaseDir(),  $sorsa);
    $self->{sorsatable} =  $sorsa;
    }
}


#-------------- subs -------------

=item notes

for simple, non-dmel-flybase case of no cytofeats to add, 
need only here create gnomap/ folder files w/ indexed fff (stripped of leading
  chr, bstart columns


flybase cytofeatures look like (fff format)

2L	1	cytogene	anon-21Aa	21A	-30856..353	FBgn0015861
2L	1	cytogene	l(2)21Bb	21A1-21B4	-30856..213625	FBgn0001885

X	22039275	cytoduplicated_segment	Ts(1Lt;YSt)E15+Ts(YLt;3Lt)W27	20F-h29;91A-100F5	22039275..22098704	FBab0025172
X	5216754	cytoduplicated_segment	Dp(1;2;1)AT	5A-7A;36D1-37D2	5216754..6912751	FBab0003372

=cut

=item  makeFiles( %args )

  primary method
  makes  blast indices.
  input file sets are intermediate chado db dump tables.
  
  arguments: 
  infiles => \@fileset,   # required

=cut

sub makeFiles
{
	my $self= shift;
  my %args= @_;  

  print STDERR "makeFiles\n" if $DEBUG; # debug
  my $fileset = $args{infiles};
  my $chromosomes = $args{chromosomes};
  unless(ref $fileset) { 
    my $intype= $self->{config}->{informat} || ['fff','dna']; #? maybe array
    $fileset = $self->handler->getFiles($intype, $chromosomes);  
    # warn "makeFiles: no infiles => \@filesets given"; return;  
    }
  unless(ref $fileset) { 
    warn "GnomapWriter: no input 'fff' feature or dna files found\n"; 
    return;  
    }

  ## infiles => [ @$featfiles, @$dnafiles ]
 
  ## $self->readflysorsa(); #? here or wait

  if ($self->{indexonly}) {
    warn "Indexing only features in $self->{gnomapdir}\n" if $DEBUG;
    $self->indexfeatdir($self->{gnomapdir});
    return 1;
    }

## ---------- get cytology set ----------
  # == cytomap/ folder
  # need to get seq id list and purge cytogene/.. w/ same id
	##	  my ($nr, $nk)= cytosort( $fset_h, $dir.$hf, $csome, *FO);

  my $addcyto= 0;
  ##if (-d $self->{cytomapdir}) {
    #  $config->{cytofeat}->{path} OR fileset->cytofeat/cytomap
  my $cytoset= $self->handler->getFiles('cytofeat', $chromosomes);  
  if ($cytoset) { $fileset= [ @$fileset, @$cytoset ]; $addcyto=1; }
    
    #? add to $fileset
    # require cytomapdir to have tables in fffformat==2, split by chr
    #  then merge steps are 
    #  1. readids (seqset) (see fastawriter)
    #  2. filter cytomap fff by seq ids
    #  3. cat seq,cyto fff | sort | write to gnomapdir
    # $addcyto= 1;
  ##}

## ---------- get sequence set ----------
  # == fff/ folder

    # 1. symlink dnafiles to gnomap/dna-$chr.raw 
    # 2. copy fff/release-$chr.fff to gnomap/features-$chr.tsv , stripping lead 2 cols

  # $self->addDnaSymlinks($fileset);
  $self->makeSymlinks( $fileset, 'dna/raw', "dna-\$chr.raw", $self->{dnareldir}, $self->{gnomapdir});
 
  if (@{$self->{copytypes}}) {
    my $fset= $self->handler->getFiles( $self->{copytypes}, $chromosomes);  
    $self->copyFiles( $fset, '', '',  $self->{gnomapdir});
    }
  
  if($addcyto) {
    $self->mergeFeats($fileset);
  } else {
    $self->copyFFF2Gnomap($fileset);
  }
  
  $self->printSummary( $self->{summaryfile}, $self->{featnames});
  
  $self->indexfeatdir($self->{gnomapdir})  
    ; #if ($doindex);

  my @featnames= ();
  if ($self->{featnames}->{all}) { @featnames= sort keys %{$self->{featnames}->{all}}; }
  $self->makeGbrowseConf(\@featnames); # should pass array of feature names !

  print STDERR "GnomapWriter::makeFiles: done\n" if $DEBUG; 

  return 1; #what?
}


sub mergeFeats
{
	my $self= shift;
  my( $fileset )= @_; # do per-csome/name
  my $ok= 1;
  my $filterids= 1; #?? config
  my $gnomapdir= $self->{gnomapdir};
  my $sorter=`which sort`; chomp($sorter); ## '/bin/sort'; '/usr/bin/sort';
  print STDERR "mergeFeats\n" if $DEBUG; 
  
  for (my $ipart= 0; $ok; $ipart++) {
    $ok= 0;
    my $infile= $self->openInput( $fileset, $ipart, 'fff');
    if ($infile && $infile->{inh}) {
      my $chr= $infile->{chr};
      
      if ($filterids) {
        my $inh= $infile->{inh};
        my $idlist= $self->readIdsFromFFF( $inh, $chr, $self->handler()->{config}); # for featmap ?
        $self->{idlist}= $idlist;
        ##$inh= $self->resetInput($infile);  
        }
      

    # require cytomapdir to have tables in fffformat==2, split by chr
    #  then merge steps are 
    #  1. readids (seqset) (see fastawriter)
    #  2. filter cytomap fff by seq ids
    #  3. cat seq,cyto fff | sort | write to gnomapdir
        
          ## this not good - need to make sure same $chr as $infile
      my $inmerge;
      my $mergepipe;

      foreach my $fs (@$fileset) {
        my $fp  = $fs->{path};
        next unless($fs->{type} =~ /cytofeat/); ## cytomap > type => "$featn/$type",
        next unless($fs->{chr} eq $chr);  
        $inmerge = $fs;
        last;
        }
        
      if ($inmerge) { 
        close($infile->{inh}) if ($infile->{inh});
        
        # if .gz ??
        my $catset= $infile->{path} ." ".$inmerge->{path};
        if ($catset =~ /\.gz/) { $catset= "gunzip -c ".$catset; }
        else { $catset= "cat ".$catset; }
        $catset .= " | $sorter -t'	' -k 1,1 -k 2,2n |"; #NOTE TAB in '	'
        open(MERGE,$catset);
        $mergepipe= *MERGE;
        }
      else {
        # just cat infile
        $mergepipe=  $self->resetInput($infile);
        }
        
      my $outname= catfile($gnomapdir,"features-$chr.tsv");
      my $outh= new FileHandle(">$outname");
      
      print STDERR "merge $outname from $infile->{path}, $inmerge->{path}\n" if $DEBUG; 
      my $res= $self->merge2gnomap( $mergepipe, $outh, $chr);

      close($outh);
      close($mergepipe);
      $ok= 1;
      }
    }
    
 ## $self->printSummary( $self->{summaryfile}, $self->{featnames});
}


sub merge2gnomap
{
	my $self= shift;
  my( $inh, $outh, $chr )= @_; # do per-csome/name
  # my $csomefeats= $self->{featnames};

  my $ffformat = 0; #? test always; probably is 2
  while(<$inh>){
    if (/^\w/ && /\t/) {  
      my @v= split(/\t/); #split "\t", $_;
      if ( $ffformat == 2 || @v > 7 || ($v[0] =~ /^\w/ && $v[1] =~ /^[\d-]+$/)) { 
        $ffformat= 2;
        splice(@v,0,2); 
        }
      print $outh join("\t",@v);
      my $fname= $v[0];
      $self->{featnames}->{all}->{$fname}++; # save for gbrowse...
      $self->{featnames}->{$chr}->{$fname}++; # save for gbrowse...
      }
    else { print $outh $_; }
    }
  ##$self->printSummary( $self->{summaryfile}, $self->{featnames});
}

# sub addDnaSymlinks
# {
# 	my $self= shift;
#   my( $fileset )= @_; # do per-csome/name
#   my $intype =   'dna/raw';  
#   my $gnomapdir= $self->{gnomapdir};
#   my $dnareldir= $self->{dnareldir};
# 
#   $self->makeSymlinks($fileset, $intype, "dna-\$chr.raw", $dnareldir, $gnomapdir);
#   
# #   foreach my $fs (@$fileset) {
# #     my $fp= $fs->{path};
# #     my $name= $fs->{name};
# #     my $type= $fs->{type};  
# #     my $chr= $fs->{chr};  
# #     next unless( $fs->{type} eq $intype);  
# #     ## unless(-e $fp) { warn "missing intype file $fp"; next; }
# #     my($filename, $dir) = File::Basename::fileparse($fp);
# #     
# #     my $relpath= catfile($dnareldir, $filename); #?
# #     my $symname= catfile($gnomapdir,"dna-$chr.raw");
# #     symlink( $relpath, $symname);
# #     print STDERR "symlink dna-$chr.raw -> $relpath\n" if $DEBUG; 
# #     }
# 
# }


sub copyFFF2Gnomap
{
	my $self= shift;
  my( $fileset )= @_; # do per-csome/name
  my $intype =   'fff';  
  my $gnomapdir= $self->{gnomapdir};
  # my %csomefeats=();
  $self->{featnames}= {};
  print STDERR "copyFFF2Gnomap\n" if $DEBUG; 

  foreach my $fs (@$fileset) {
    my $fp= $fs->{path};
    my $name= $fs->{name};
    my $type= $fs->{type};  
    my $chr= $fs->{chr};  
    next unless( $fs->{type} =~ /$intype/);  
    unless(-e $fp) { warn "missing $intype file $fp"; next; }
    
    my $featname= catfile($gnomapdir,"features-$chr.tsv");
    print STDERR "copy $featname from $fp\n" if $DEBUG; 

      #?? include here opt to merge cyto feats - w/ sort
    if ($fp =~ m/\.(gz|Z)$/) { open(FF,"gunzip -c $fp|"); }
    else { open(FF,"$fp"); }

    my $ffformat = 0; #? test always; probably is 2
    open(OUT,">$featname");
    while(<FF>){
      if (/^\w/ && /\t/) {  
        my @v= split(/\t/); # split /\t/, $_;
        if ( $ffformat == 2 || @v > 7 || ($v[0] =~ /^\w/ && $v[1] =~ /^[\d-]+$/)) { 
          $ffformat= 2;
          splice(@v,0,2); 
          }
        print OUT join("\t",@v);
        my $fname= $v[0];
        $self->{featnames}->{all}->{$fname}++; # save for summary && gbrowse...
        $self->{featnames}->{$chr}->{$fname}++;  
        }
      else { print OUT $_; }
      }
    close(FF); close(OUT);
    }

##  $self->printSummary( $self->{summaryfile}, $self->{featnames});
}


sub printSummary 
{
	my $self= shift;
  my( $sumfile, $csomefeats )= @_; 
  if ( $sumfile && $csomefeats ) {
    my $fh= new FileHandle(">$sumfile");
    my $title = $self->{config}->{title};
    my $date  = $self->{config}->{date};
    ##my $org   = $self->{config}->{species} || $self->{config}->{org};
    my $org= $self->{org} || $self->handler()->{config}->{org};
    print $fh "# Genome feature summary of $org from $title [$date]\n";
    my @fl= grep { 'all' ne $_ } sort keys %$csomefeats;
    foreach my $arm ('all', @fl) {
      print $fh (($arm eq 'all') ? "\n# ALL chromosomes\n" : "\n# Chromosome $arm\n");
      foreach my $t (sort keys %{$csomefeats->{$arm}}) {
        my $v= $csomefeats->{$arm}{$t};
        print  $fh "$t\t$v\n";
        }
      print $fh "#","="x50,"\n";
      }  
    close($fh);
    }
}

sub makeGbrowseConf
{
	my $self= shift;
	my($featnames)= @_;
	
	warn "makeGbrowseConf\n" if $DEBUG;

  ## need active feature set from ? feature-summary.txt or fff/ files
  
	my $config={}; # stuff with $self->handler->config && others
	$config= $self->handler->{config};
  ##my $gbrowseconf= $config->{gbrowsefiles}->{config};
  ##my $gbrowseconf= $self->{gbrowseconf};
  my $gbset= $self->handler->getFilesetInfo('gbrowse');
  my $gbrowseconf= $gbset->{config};
  
  # add vars to config
  # description = ${species} ${relfull} ${date} OR ${title} ??
  # datapath    = ${gnomapdir}
  $config->{gnomapdir}= $self->{gnomapdir};
  
  my ($loc, $ex)= ('','');
  my $chromosomes= $self->handler->getChromosomes(); 
  foreach my $chr (@$chromosomes) {
     $loc= "$chr:1..100000" unless($loc);
     $ex .= "$chr: ";
     }
  $config->{ default_location } = $loc;
  $config->{ examples } = $ex;
  
  my $config2= $self->handler->{config2}; 
  my $gbconf= $config2->readConfig( $gbrowseconf, 
    { Variables => $config, debug => $DEBUG,  }, {} );
  print STDERR $config2->showConfig( $gbconf, { debug => $DEBUG })
    if ($self->{showconfig});       
	
  my $doc  = $gbconf->{doc}->{gbrowse};
  my $fdefs= $gbconf->{fdef};
  my $content= $doc->{header}->{content} || '';

  my @featnames=();
  @featnames= @$featnames if (ref $featnames);
  @featnames= sort keys %$fdefs unless(@featnames);
  
  foreach my $fname (@featnames) {
    my $fd = $fdefs->{$fname};
    unless( $fd ) {
      # next; # check all hash {feature} strings for match...
      $fd = $fdefs->{GENERIC};
      my $gct= $fd->{content};
      $gct =~ s/GENERIC/$fname/sg;
      $fd= { name => $fname, content => $gct };
      }
    next if ($fd->{done});
    my $morefeats= $fd->{feature};
    my $ct= $fd->{content};
    $content .=  $ct."\n";
    $fd->{done}=1;
    }
    
  $content .= $doc->{footer}->{content} || '';
  $doc->{content}= $content;
  $doc->{path}= $gbset->{path}; #$config->{gbrowsefiles}->{path}; #??
  $self->handler()->writeDocs( { gbrowseconf => $doc });
}


# =item openInput( $fileset )
# 
#   handle input files
#   
# =cut
# 
# sub openInput
# {
# 	my $self= shift;
#   my( $fileset )= @_; # do per-csome/name
#   my @files= ();
#   my $inh= undef;
#   return undef unless(ref $fileset);
# 
#   my $intype = $self->{config}->{informat} || 'fff'; #? maybe array
#   my $featset= $self->{config}->{featset} || [];
#     
#   print STDERR "openInput: type=$intype \n" if $DEBUG; 
#   
#   foreach my $fs (@$fileset) {
#     my $fp= $fs->{path};
#     my $name= $fs->{name};
#     my $type= $fs->{type}; # want also/instead featset type here ? gene,mrna,cds,...
#     next unless( $fs->{type} =~ /$intype/); # could it be 'dna/fasta', 'amino/fasta' ?
#     unless(-e $fp) { warn "missing intype file $fp"; next; }
# 
#     push(@files, $fp);
#     }
#     
#   return @files;  
# }



=item processToOutput


=cut

sub processToOutput
{
	my $self= shift;
  my( $rseqfiles )=  @_;
  

}



#============== 
# mostly from  flybase/work.local/chado_r3_2_26/soft/mergeflyfeats4.pl
#==============


## --- read table of genome:cytology mapping  -----
# my $sorsaf="${sorsapath}sorsa.txt";
# if (defined $mconf->{sorsa}->{path}) {
#   $sorsaf= join("",getFiles( $mconf->{sorsa}->{path} ));
# }

# sub getFiles {
# 	my $self= shift;
#   my($path)= @_;
#   my $file;
#   if ($path =~ s,([^/]+)$,,) { $file= $1;  }
#   else { $file= $path; $path="./"; }
#   opendir(D,$path);
#   my @file= grep(/$file/,readdir(D));
#   closedir(D);
#   return $path,@file;
# }


sub readflysorsa 
{
	my $self= shift;
	my ($sorsa)= @_;
  my %cytobases= %{$self->{cytobases}} || ();
	return if (scalar(%cytobases));

	local(*F,*O);
	my ($n);
  my @sorsalist= ();
	$sorsa= $self->{sorsatable} unless(-e $sorsa);
	unless (open(F,$sorsa)) { 
	  warn "Can't read $sorsa" ; 
	  $cytobases{1}= [ 0, 0 ]; # don't come here back again
  	$self->{cytobases}= \%cytobases;
	  return; 
	  }
	warn "reading $sorsa\n" if $DEBUG;
	while (<F>) {
		next unless(/^\d/); 	chomp();
		my($cyto,$bb,$be)= split(); ### /\t/ ##  (' ') was, now \t separated!
		$cytobases{$cyto}= [ $bb, $be ];
		push( @sorsalist, $cyto);  # sorted !
		}
	close(F);
	$self->{cytobases}= \%cytobases;
	$self->{sorsalist}= \@sorsalist;
}



=item

replace static sorsa.txt with chromosome_band features from chado db

-- gff table
2L      .       chromosome_band -30855  353     .       +       .       ID=1273798;Name=ba
nd-21A1;cyto_range=21A1
2L      .       chromosome_band -30855  108823  .       +       .       ID=1273801;Name=ba
nd-21A;cyto_range=21A
2L      .       chromosome_band -30855  1318131 .       +       .       ID=1242194;Name=ba
nd-21;cyto_range=21
2L      .       chromosome_band 354     32349   .       +       .       ID=1273804;Name=ba

-- use .fff file instead ?
2L      -30855  chromosome_band band-21A1       21A1    -30855..353     -
2L      -30855  chromosome_band band-21A        21A     -30855..108823  -
2L      -30855  chromosome_band band-21 21      -30855..1318131 -

=cut 

sub readChadoCytomap 
{
	my $self= shift;
  my( $fset_h, $file, $outh)= @_;
  local(*F);
  return "Can't read $file" unless (open(F,$file));
	warn "Reading chromosome_band  $file \n" if $DEBUG;
	unless($file =~ m/\.gff$/) { warn "Wrong format - want .gff"; return; }

  my %cytobases= %{$self->{cytobases}} || ();
  my @sorsalist= ();

  ##my @keepset= ($fset_h->{keep}) ? @ {$fset_h->{keep}} : ();
  ##my @dropset= ($fset_h->{drop}) ? @ {$fset_h->{drop}} : ();
	while (<F>) {
		next unless(/^(\w+)\s+(\S+)\s+chromosome_band/);
		my @gff= split;
    #next unless (grep {$gff[2] eq $_} @keepset);
		if ($gff[-1] =~ m/cyto_range=(\S+)/) {
		  my ($cyto,$bb,$be)= ($1, $gff[3], $gff[4]); 
		  next unless($cyto =~ m/^\d+[A-F]\d/); # need to drop 1,1A for 1A1 
		  $bb--; # dang interbase -1 doesn't apply to chromosome_band - why not? 
		  $cytobases{$cyto}= [ $bb, $be ];
		  push( @sorsalist, $cyto);  # sorted
		  print $outh "$cyto\t$bb\t$be\n" if ($outh); # ! not sorted right here - need chr order
		  }
		}
	close(F);
	$self->{cytobases}= \%cytobases;
	$self->{sorsalist}= \@sorsalist;
}


sub getCytobases {
	my $self= shift;
	my ($cmap)= @_;
  my %cytobases= %{$self->{cytobases}} || ();
	my ($start1,$stop1)= ($kMissingValue,$kMissingValue);
  ($start1,$stop1)= @ {$cytobases{$cmap}} if $cytobases{$cmap};
  return ($start1,$stop1);
}

sub getCytolocFromSeqloc {
	my $self= shift;
	my ($arm, $bstart, $bend)= @_; # $chr
	my ($cstart, $cend);
	my @sorsalist= @ { $self->{sorsalist} };
	my $ca= $flycsomebands{$arm}->[0];
	my $ina= 0;
	foreach my $cb (@sorsalist) {
		if ($cb eq $ca) { $ina= 1; }
		if ($ina) {
			my ($bb, $be)= $self->getCytobases($cb); # @ {$cytobases{$cb}};
			if ($bstart >= $bb && $bstart <= $be) {
				$cstart= $cb;
				}
			if ($bend >= $bb && $bend <= $be) {
				$cend= $cb;
				last;
				}
			}
		}
	if ($cstart && !$cend) { $cend= $cstart; }
	elsif ($cend && !$cstart) { $cstart= $cend; }
	if (wantarray) { return ($cstart, $cend); }
	else { return ($cstart eq $cend) ? $cstart : "$cstart--$cend"; }
}

sub maxrange {
	my $self= shift;
	my( $range)= @_;
	my ($pre, $suf,$start,$stop, $b, $u);
	$start= $kMissingValue; $stop= $start;
	
	$range =~ s/^([^\d<>-]*)//; $pre= $1;
	$range =~ s/(\D*)$//;  $suf= $1;
	if ($range =~ m/^([<>]*)([\d-]+)/) { $u= $1; $start= $2; $start-- if ($u eq '<'); }
	if ($range =~ m/([<>]*)([\d-]+)$/) { $u= $1; $stop= $2; $stop++ if ($u eq '>'); }
	return ($start,$stop);
}

sub getCytorange {
	my $self= shift;
	my($ca,$cx)= @_;
	$ca =~ s/^\s*//; $ca =~ s/[\s+-]*$//;
	return () unless ($ca =~ /^\d/); #? don't have conversion info for hXXX
	my $offs= 0;
	## need patch for 1Lt; 1Rt; 1Cen? h, ...
	if ($ca !~ /[A-G]/) { 
		if ($cx) { $cx =~ s/\d*$//; $ca= $cx . $ca; } 
		else { $ca .= 'A1'; $offs= -1; } 
		}
	elsif ($ca !~ /\d$/) { $ca .= '1'; $offs= -1; }
	my ($start1,$stop1)= $self->getCytobases($ca); #@ {$cytobases{$ca}};   
	return ($start1,$stop1,$ca); # +$offs
}

# sub getMap2Bases { return flyCytomap2Bases(@_); }


 ##  ignore ranges outside of csome arm
 ## same as sub flyCytomap2Bases()
sub getMap2Bases { 
	my $self= shift;
	my ($map, $arm)= @_;
	my($stop,$start)= ($kMissingValue,$kMissingValue);

  $self->readflysorsa(); #? here or wait

	my $carm= $flycsomebands{$arm}->[0]; # $cytoarms{$arm};
	my $darm= ($carm =~ m/^(\d+)/) ? $1 : 0;
	my ($armb, $x)= $self->getCytobases($carm); #@ {$cytobases{$carm}};
	my $carme= $flycsomebands{$arm}->[1];  
	my $darme= ($carme =~ m/^(\d+)/) ? $1 : 0;
	my ($y, $arme)= $self->getCytobases($carme); #@ {$cytobases{$carme}};
	
	$map =~ s/\s+//g; 
	foreach my $mp (split(/;/, $map)) {
		next if ($mp eq '*');
		next if ($mp =~ /^h/); # cant handle these yet
		my($ca, $cb)= split(/-/, $mp);
		my $da= ($ca =~ m/^(\d+)/) ? $1 : 0;
		next if ($da < $darm || $da > $darme);
		
		my($start1,$stop1,$bstart,$bstop);
		($start1,$stop1,$ca)= $self->getCytorange($ca);
		next unless(defined $start1);
		# next unless($stop1 >= $armb && $start1 <= $arme);
		if ($cb) {
			($bstart,$bstop,$cb)= $self->$self->getCytorange($cb,$ca);
			$stop1= $bstop if ($bstop);
			}
		##? skip/ignore if both $ca,$cb are outside of $arm ?
		next if ($stop1 < $armb || $start1 > $arme);
		$start= $start1 if ($start==$kMissingValue && $start1 >= $armb && $start1 <= $arme);
		$stop = $stop1  if ($stop1 >= $armb && $stop1 <= $arme);
		}
	
	# $start= $armb if ($start==$kMissingValue && $stop != $kMissingValue);
	$stop = $start if ($stop==$kMissingValue); ## was = $arme 
	  ##?? need band range here, for e.g. '41' => 41A1-41F29
	# DEBUG - getting missing when should get real range !??
	return (wantarray) ? ($start, $stop) : "$start..$stop";
}

## indexing parts from genomefeat.pl - fixed for changed sorsa.txt, other flyfeat parts


##
## index features*.tsv by ID field for lookup by id
## 

sub indexfeatdir 
{
	my $self= shift;
	my $dir= shift;
	local(*D); opendir(D, $dir) || warn "can't open $dir";
	my @files= grep( /^features-\w+\.tsv$/, readdir(D));
	closedir(D);
	
	local(*IMAP,*IMAPX);
	open(IMAP,">$dir/idmap.tsv");
	open(IMAPX,">$dir/idmap.tsv.idx");
	my %idfh=();
	foreach my $file (sort @files) {
		my $sfile= catfile($dir, $file);
		my $csome= ($file =~ /^features-(\w+)/) ? $1 : 'UNK';
    my $infh= new FileHandle($sfile);
    unless($infh) {
      warn "Can't read $sfile";
      $self->{failonerror} ? die : next;
      }
		## warn "indexing chr-$csome, $sfile\n" if $DEBUG;
		$infh->seek(0,0);
		print $self->indexFeatures( $sfile, $infh, 'index',  $csome);  
		$infh->seek(0,0);
		print $self->indexIds( $sfile,  $infh, 'idindex', $csome, *IMAP, *IMAPX);  
		$infh->seek(0,0);
		print $self->makeAllIdmaps( $sfile,  $infh, $dir, $csome, \%idfh);  
		}
	close(IMAP); close(IMAPX);
	foreach my $idfh (values %idfh) { $idfh->close(); }
}
 
sub makeAllIdmaps 
{
	my $self= shift;
  my( $file, $fin, $dir, $csome, $idfh)= @_;
  my ($nd)=(0); my %didid=();
  my $indexidpattern='^[A-Za-z]{2,}';  
  my $indexdbpattern='^[A-Za-z]{2,}';  # FIXME - config
  #die "Can't read $file" unless (open(FIN,$file));
  # my $org   = ucfirst( $self->{config}->{org} || 'Any');
  my $org= $self->{org} || $self->handler()->{config}->{org};
  $org=  'Any' unless($org);
  # fixme for ortholog to_name in $notes
  my($nte,$ste,$ite);

	# warn "makeAllIdmaps: noIdmap.classes='$noIDmap' \n" if $DEBUG;

  while(<$fin>) {
    my ($class,$sym,$map,$range,$idv,$dbx,$notes)= split(/\t/);
    $nte++ if ($class =~/transposable_element/); #DEBUG
    next unless( $range && $range ne '-' );
    next if ($class =~ /$noIDmap/i); ## ?? drop or keep
    
    my @ids= (split(/[,;\s]/,$idv),split(/[,;\s]/,$dbx));  
    if ($class =~ /$nameIsId/) { # fixme for fff output - put in ID field
      $sym =~ s/\-hit$//; # bad BAC names
      unshift(@ids,$sym);
      }
    elsif ($class =~ /$nameIsSpeciesId/) {  
      $sym = "$org\\$sym" unless($sym =~ m,\\,);  
      unshift(@ids,$sym);
      }
    elsif ($notes && $notes =~ /to_name=([^;,\s]+)/ ) {  
      ## added to_name=name, id << keep id?
      my $tosym = $1; $tosym =~ s/\-\w\w$//; # drop prot suffix
      my $toorg = ($notes =~ /to_species=([^;,\s]+)/) ? $1 : $org;
      unshift(@ids,ucfirst($toorg).'\\'.$tosym);
      }
      
      # feb05: getting lots of useless idmap-xxx.tsv for things like
      # polyA_site with symbol name as id/name 
      # gbb-polyA_site-1, Delta88{}su(s)[28] , 
      
    my $needid=1;
    IDINDEX:
    while ($needid && (my $tid = shift @ids)) {
      next if ($tid eq '-');
      
      $ite++ if ($tid =~/FBti/); #DEBUG
      my $db='';
      if ($tid =~ s/$cutdbpattern//i) { $db= $1; } 
      next unless ($db =~ /$indexdbpattern/ || $tid =~ /$indexidpattern/);
      
      my($start, $stop)= $self->maxrange($range);  
      my $idkey="$tid.$csome.$start";
      next if ($didid{$idkey});

      $ste++ if ($tid =~/FBti/); #DEBUG
      my $idf= 'idmap-all.tsv';
      if ( $tid =~ m/^([A-Za-z]+)/ ) { $idf= "idmap-$1.tsv"; }
      my $fh= $idfh->{$idf};
      unless($fh) { 		
        my $sfile= catfile($dir, $idf);
        $fh= new FileHandle(">$sfile"); $idfh->{$idf}= $fh; 
        }
      if ($fh) {
        print $fh "$tid\t$csome\t$start\t$stop\n"; $nd++;
        $didid{$idkey}++;
        }  
      }
  }
	warn "TE count: nte=$nte idte=$ite saved=$ste\n" if $DEBUG;
  #close(FIN);
  return "makeAllIdmaps n=$nd\n";
}


sub indexIds 
{
	my $self= shift;
  my($file, $fin, $kind, $csome, $idmapf, $idmapx)= @_;
  local(*FIN,*FIDX);
  my ( $n, $nl)= (0,0);
  $kind= 'idindex' unless($kind);

  my $idx= $file . ".idx";
  # die "Can't read $file" unless (open(FIN,$file));
  die "Can't write $idx" unless (open(FIDX,">$idx"));
	# my $recsize = length(pack("NN", 1, 500));  ## a constant -- 2 long integers
	my %didid= ();

	my ($at,$ate)= (0,0);
	while (<$fin>) {
		$at = $ate;
	  $ate= tell($fin);
    if (/^\w/) {
    	$nl++;
    	chomp();
      my ($class,$sym,$map,$range,$idv,$dbx)= split(/\t/);
      ## dang, for cytogene need to make $range from $map
      next if ($class =~ /$noIDmap/); ## ?? drop or keep
      next unless($class =~ /$indexidtype/);
      
			  ## aug04 -- ID field has changed to CG, others - use dbx to get FBgn ID
			  ## look at both fields for 1st valid numeric (FBgn) ID
      my @ids= (split(/[,;\s]/,$idv),split(/[,;\s]/,$dbx)); # dbx should be ',' now
      my $needid=1;
      IDINDEX:
      while ($needid && (my $tid = shift @ids)) {
        ## next unless($class =~ /gene|RNA/ || $tid =~ /gn\d+/); 
        ## FIXME - need another index method to mix FBgn/FBan/FBxx
			  next unless ($tid =~ /$indexidpattern/);
			  
      my $db=''; #default?
      if ($tid =~ s/([^:]+)://) {
        $db= $1; ## skip not-our-id ids
      	## $tid= '' unless ($db =~ m/FlyBase|MEOW|euGenes/i);
      	## ? do we need to check db, if matches $indexidpattern ?
      	}
      	
      ##if ($tid =~ m/[A-Za-z]*0*(\d+)/) ## need config patt here
      ##if ($tid =~ m/[A-Z]{2}gn0*(\d+)/) 
      if ($tid =~ m/0*(\d+)/) 
      {    
        #? $needid=0; -- keep going thru all dbx 2ndary FBgn IDS ????
      	my $idnum= int($1);
      	if (!$didid{$tid} && $idnum < 200000) { # be sure is good idnum 
					$didid{$tid}++; 
					my $size= $ate - $at;
				  my $record= pack("NN", $at, $size);
				  my $idloc = $idnum * RECSIZE;
				  seek(FIDX, $idloc, 0);
				  ## check if already did id == e.g., several feats have same ID, pick 1st? always
				  print FIDX $record;
				  $n++;
				  
				  # ?? also write to single $org id-map.tsv ? and do .idx for it?
          if ($class =~ /cyto/ && $map && $range eq '-') {
            $range=  $self->getMap2Bases( $map, $csome);
            }

					if ($idmapf && $range && $range ne '-') {
						my($start, $stop)= $self->maxrange($range);
						my $idat= tell($idmapf);
						print $idmapf "$tid\t$csome\t$start..$stop\n";
						my $ide= tell($idmapf); 
					  $size= $ide - $idat;
					 	$record= pack("NN", $idat, $size);
  				  ##my $idloc = $idnum * RECSIZE;
						seek($idmapx, $idloc, 0);
						print $idmapx $record;
					  }  
				  }
				## last IDINDEX;
			  }
			  }
		  }
		##$at = $ate;
		}
	close(FIDX); 
	# close(FIN);
  return "indexIds $file = $n / $nl\n";
}


##
## index features*.tsv by base range
## 

sub indexFeatures {
	my $self= shift;
  my($file, $fin, $kind, $csome)= @_;
  local(*FIN,*FIDX);
  my $n= 0;
  $kind= 'index' unless($kind);
  ##return if ($kind ne 'index');

  my $idx= $file . ".ranges";
  # die "Can't read $file" unless (open(FIN,$file));
  die "Can't write $idx" unless (open(FIDX,">$idx"));
  print FIDX "# $idx\n";
  print FIDX "# base range -> file index, and source, scaffold ranges\n";
  print FIDX "# tab-separated-values of: \n";
  print FIDX "# base-start | file-index OR class-name | file-index | location\n";

  my $bindex= 0; ##? off by one? was 0;
  my $nextstep= -666;
  my $stepsize= 100000;
  my @csomerange= (0,0);
  while (<$fin>) {
    # my $blength= length($_);
    if (/^\w/) {
      chomp();
      my ($class,$sym,$map,$range,$ids,$dbx)= split(/\t/);
      my ($start,$stop)= ($kMissingValue, $kMissingValue);

      if (defined $range && $range =~ /\d/) {
       	($start, $stop)= $self->maxrange($range);
       	}
      elsif ($map =~ /\d/) { # !$range || $range eq '-'
     		($start, $stop)=  $self->getMap2Bases( $map, $csome) ; # if ($org =~ /fly/);
       	}

      if ($start!=$kMissingValue && $stop!=$kMissingValue) {
        if ($class eq 'source') {
                @csomerange= ($start, $stop);
                $stepsize= int( ($stop - $start) / 100 );
                }
        if ($class eq 'source') { # || $class eq 'segment' ## segment not scaffold
                print FIDX "$class\t$bindex\t$range\n";
                }
        elsif ($nextstep == -666 || $start >= $nextstep) {
                $nextstep= $start if ($nextstep == -666);
                $nextstep= 0 unless($nextstep); ## dang perl
                print FIDX "$nextstep\t$bindex\n";
                $nextstep += $stepsize;
                }
        $n++;
        }
      }
    # $bindex += $blength;
    $bindex= tell($fin); ##? off by one ??
    }
  print FIDX "$csomerange[1]\t$bindex\n";

  #close(FIN); 
  close(FIDX);
  return "indexFeatures $file = $n\n";
}





1;

__END__

