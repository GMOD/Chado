package Bio::GMOD::Bulkfiles::FastaWriter;
use strict;

=head1 NAME

  Bio::GMOD::Bulkfiles::FastaWriter  
  
=head1 SYNOPSIS
  
  use Bio::GMOD::Bulkfiles;       
  
  my $sequtil= Bio::GMOD::Bulkfiles->new(  
    configfile => 'seqdump-r4', 
    );
  my $fwriter= $sequtil->getFastaWriter(); 
  my $result = $fwriter->makeFiles( );
    
=head1 NOTES

  genomic sequence file utilities, part3;
  parts from 
    flybase/work.local/chado_r3_2_26/soft/chado2flat2.pl
  
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
# use Bio::GMOD::Bulkfiles::SWISS_CRC64; # see below require

use base qw(Bio::GMOD::Bulkfiles::BulkWriter);
#use vars qw(@ISA); @ISA= (qw/Bio::GMOD::Bulkfiles::BulkWriter/);  

our $DEBUG = 0;
my $VERSION = "1.1";
#my $configfile= "fastawriter"; #? BulkFiles/FastaWriter.xml 

#?? how do constants overload in perl object inheritance ??
# perldoc constant:  Subclasses may .. override those in their base class.
# BUT? need to do $obj->CONSTANT not CONSTANT ???
use constant BULK_TYPE => 'fasta';
use constant CONFIG_FILE => 'fastawriter';

sub init 
{
	my $self= shift;
  $self->SUPER::init();
  
  $DEBUG= $self->{debug} if defined $self->{debug};
  ## super does
#   $self->{bulktype}= BULK_TYPE;
#   $self->{configfile}= CONFIG_FILE unless defined $self->{configfile};
}


=item initData

initialize data from config

=cut

sub initData
{
  my($self)= @_;
  $self->SUPER::initData();
 
  ##  fastafiles -- use $self->{config} instead / also with finfo ??
  # my $outdir= $self->handler()->getReleaseSubdir( $self->getconfig('path') || $self->BULK_TYPE);
  # $self->{outdir} = $outdir;

  ## $self->promoteconfigs(); << now in base class
#  ##? test: see fastawriter.xml for valid keys
#   my @mykeys= sort keys %{$self->{config}}; 
#   my %cvals= $self->getconfig(@mykeys); # debug
#   @{%$self}{@mykeys}= @{%cvals}{@mykeys}; 
#   if($DEBUG){
#     print STDERR "### initData: getconfig(@mykeys)= \n";
#     foreach my $key (@mykeys) {
#       print STDERR "$key => ",$self->{$key}," <",$cvals{$key},"\n";
#       }
#     }

## now done by promoteconfigs()
#  # my $finfo= $self->{fileinfo} || $self->handler()->getFilesetInfo($self->BULK_TYPE);# 
#   $self->{addids} = $finfo->{addids};
#   $self->{dropnotes} = $finfo->{dropnotes};
#   $self->{allowanyfeat} = $finfo->{allowanyfeat};
#   $self->{makeall} = $finfo->{makeall};
#   $self->{dogzip} = $finfo->{dogzip};
#   $self->{perchr} = $finfo->{perchr};
#   $self->{addmd5sum} = $finfo->{addmd5sum};
#   $self->{addcrc64} = $finfo->{addcrc64};

}


#-------------- subs -------------


=item  makeFiles( %args )

  primary method
  arguments: 
    infiles => \@fileset of fff features and dna sequences,   # required

=cut

sub makeFiles
{
	my $self= shift;
  my %args= @_;  

  print STDERR "FastaWriter::makeFiles\n" if $DEBUG; # debug
  
  # more sensible that writer should ask handler for kind of files it wants
  my $fileset = $args{infiles};
  my $chromosomes = $args{chromosomes};
  unless(@$fileset) { 
    my $intype= $self->{config}->{informat} || 'fff'; #? maybe array
    $fileset = $self->handler->getFiles($intype, $chromosomes);  
    unless(@$fileset) { 
      warn "FastaWriter: no input '$intype' files found\n"; 
      return $self->status(-1);
      }
    }
 
  my $featset= $self->handler->{config}->{featset} || []; #? or default set ?
  my $addids = defined $args{addids} ? $args{addids} : $self->getconfig('addids');
  
  my %chrset=();
  my $status= 0;
  my $ok= 1;
  for (my $ipart= 0; $ok; $ipart++) {
    $ok= 0;
    my $infile= $self->openInput( $fileset, $ipart);
    if ($infile && $infile->{inh}) {
      my $inh= $infile->{inh};
      my $chr= $infile->{chr};
      $chrset{$chr}++;
      
      if ($addids) {
        my $idlist= $self->readIdsFromFFF( $inh, $chr, $self->handler()->{config}); # for featmap ?
        $self->{idlist}= $idlist;
        $inh= $self->resetInput($infile); #seek($inh,0,0); ## cant do on STDIN ! cant do on PIPE !
        }
      
      ## need to know $chr here .. from $fileset infile
      
      my $res= $self->processFasta( $inh, $chr, $featset);
      close($inh); delete $infile->{inh};
      $status += $res;
      $ok= 1;
      }
    }
    
   #? use found $chromosomes= [sort keys %chrset] ; want to keep original sort order
  $self->makeall( $chromosomes, $featset) 
   if (!$args{noall} && $self->config->{makeall} && $status > 0) ;
  
  print STDERR "FastaWriter::makeFiles: done n=$status\n" if $DEBUG; 
  return $self->status($status);
}

sub makeall 
{
	my $self= shift;
  my( $chromosomes, $featset )=  @_;
  my $outdir= $self->outputpath();
  my @features= @$featset;
  $chromosomes= $self->handler()->getChromosomes() unless (ref $chromosomes);

  foreach my $featn (@features) {
  
    ## this loop can be common to other writers: makeall( $chromosomes, $feature, $format) ...
    # $self->SUPER::makeall($chromosomes, $featn, $self->BULK_TYPE);
    
    my $allfn= $self->get_filename ( $self->{org}, 'all', $featn, $self->{rel}, $self->BULK_TYPE);
    $allfn= catfile( $outdir, $allfn);
    
    my @parts=();
    foreach my $chr (@$chromosomes) {
      next if ('all' eq $chr);
      my $fn= $self->get_filename ( $self->{org}, $chr, $featn, $self->{rel}, $self->BULK_TYPE);
      $fn= catfile( $outdir, $fn);
      next unless (-e $fn);
      push(@parts, $fn);
      }
      
    if (@parts) {
      unlink $allfn if -e $allfn; # dont append existing
      my $allfh= new FileHandle(">$allfn"); ## DONT open-append
      foreach my $fn (@parts) {
        my $fh= new FileHandle("$fn");
        while (<$fh>) { print $allfh $_; }
        close($fh); 
        unlink $fn if (defined $self->config->{perchr} && $self->config->{perchr} == 0);
        } 
      close($allfh);
      }
    }
}
  

=item openInput( $fileset )

  handle input files
   .. copied to base class
   
=cut

sub openInput
{
	my $self= shift;
  my( $fileset, $ipart )= @_; # do per-csome/name
  my $intype= $self->config->{informat} || 'fff'; #? maybe array
  my $atpart= 0;
  # print STDERR "openInput: type=$intype part=$ipart \n" if $DEBUG; 
  
  foreach my $fs (@$fileset) {
    my $fp  = $fs->{path};
    my $name= $fs->{name};
    my $type= $fs->{type};
    next unless( $fs->{type} =~ /$intype/); # could it be 'dna/fasta', 'amino/fasta' ?
    unless(-e $fp) { warn "missing infile $fp"; next; }
    $atpart++;
    next unless($atpart > $ipart);
    print STDERR "openInput[$ipart]: name=$name, type=$type, $fp\n" if $DEBUG; 
    
    my ( $org, $chr1, $featn, $rel, $format )= $self->split_filename($fp);
    $fs->{org}= $org;
    $fs->{chr}= $chr1 unless($fs->{chr});
    $fs->{featn}= $featn;
    $fs->{rel}= $rel;
    $fs->{format}= $format;
    
    if ($fp =~ m/\.(gz|Z)$/) { open(INF,"gunzip -c $fp|"); $fs->{pipe}=1; }
    else { open(INF, $fp); }
    my $inh= *INF;
    $fs->{inh}= $inh;
    return $fs;   
    }
  print STDERR "openInput: nothing matches part=$ipart, type=$intype\n" if $DEBUG; 
  return undef;  
}


sub resetInput
{
	my $self= shift;
  my( $infile )= @_;  
  
  my $inh= $infile->{inh};
  my $fp = $infile->{path};
  if ($infile->{pipe} || $fp =~ m/\.(gz|Z)$/) { 
    close($inh) if $inh;
    open(INF,"gunzip -c $fp|"); $inh= *INF;  $infile->{pipe}=1; 
    }
  elsif (!$inh) { open(INF,$fp); $inh= *INF; }
  else { seek($inh,0,0); }
  $infile->{inh}= $inh;
  return $inh;
}


=item processFasta


=cut

sub processFasta
{
	my $self= shift;
  my( $inh, $chr, $featset )=  @_;
  my $ndone= 0;
  my $outh= {};
  my $outdir= $self->outputpath();
  my @features= @$featset;

  my @dbfeatures= ();
  $self->{diddbfa}= {} unless($self->{diddbfa});
  my $featmap = $self->handler->config->{featmap}; # NOT local config ; for main config's featmap
  
    # special case for feat == chromosome/dna -> raw2Fasta 
    # add something like this, but dump direct from db, for EST, reagent seqs w/o csome loc
  my @fffeatures= @features;
  if (my ($featn)= grep /^chromosome/, @features) {
    my $fn= $self->get_filename ( $self->{org}, $chr, 'chromosome', $self->{rel}, $self->BULK_TYPE);
    $fn= catfile($outdir, $fn);
    $self->raw2Fasta( chr => $chr, fastafile => $fn); $ndone++;
    @fffeatures= grep !/^chromosome/, @features;
    }

  foreach my $featn (@fffeatures) {
    my $fn= $self->get_filename ( $self->{org}, $chr, $featn, $self->{rel}, $self->BULK_TYPE);
    $fn= catfile( $outdir, $fn);
    $outh->{$featn}= new FileHandle(">$fn");
    
    ## check featmap for db vs fff features !?
    my $fm= $featmap->{$featn};
    if($fm && $fm->{onlydb}) {
      push(@dbfeatures, $featn) unless($self->{diddbfa}->{$featn});
      $self->{diddbfa}->{$featn}++;
      @fffeatures= grep !/^$featn/, @fffeatures;
      }
    }
    
  $ndone += $self->fastaFromFFFloop( $inh, $outh, $chr, \@fffeatures) if (@fffeatures);
  
  ## dang do this only once; this method called inside chromosome loop;
  $ndone += $self->fastaFromDb( $outh, \@dbfeatures) if (@dbfeatures);

  foreach my $featn (keys %$outh) { 
    my $fh= $outh->{$featn}; 
    close($fh); 
    #? check size and delete if zero or leave for check ?
    }

  #print STDERR "process ndone = $ndone\n" if $DEBUG;
  return $ndone;
}


# =item readIdsFromFFF
# 
# pre-read ids from fff input for selected features for others to add_id or filter by id
# moved to base class for reuse
# 
# =cut
# 
# sub readIdsFromFFF
# {
# 	my $self= shift;
#   my ($fffin,$chr,$config)= @_;
#   my $idlist= {};  
#   my $types_info= $config->{featmap};
#   my $nid=0;
#   
#   while(<$fffin>) {
#     next unless(/^\w/); chomp;
#     my ($type,$name,$cytomap,$baseloc,$id,$dbxref,$notes,$chr1)
#         = $self->handler()->splitFFF($_, $chr);
#     if ($types_info->{$type}->{get_id}) { $idlist->{$id}= $dbxref; $nid++; }
#     }
#   print STDERR  "read ids n=$nid\n" if $DEBUG;
#   return $idlist;
# }



sub writeheader 
{
	my $self= shift;
  my($seqid,$start,$stop)= @_;
}


sub get 
{
	my $self= shift;
  my($fob)= @_;

  return undef;
}


sub writeendobj  
{
	my $self= shift;
  #my $fh= $self->{outh};
  #print $fh "###\n";
}


sub writeobj 
{
	my $self= shift;
  my( $fob )= @_;
  my $fh= $self->{outh};
  my $line= $self->get($fob);
  print $fh $line if $line;
}


=item fastaHeader

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
  my $name= delete $vals{name};
  my $db_xref= delete $vals{db_xref} || delete $vals{dbxref};
  if ($db_xref) { $db_xref =~ s/\s*;\s*$//; $db_xref =~ s/;/,/g; $db_xref =~ s/,,/,/g;}

  my %primvals=();
  @primvals{qw(type loc ID name db_xref)}= ($type,$loc,$ID,$name,$db_xref);
  
  my @d=();
  foreach my $hk (qw(type loc ID name db_xref), sort keys %vals) {
    my $v= $primvals{$hk} || $vals{$hk};
    next unless($v);
    my $key= $hk;
    if($self->config->{recodekey}->{$hk}) {
      $key= $self->config->{recodekey}->{$hk}->{content}; 
      }
    push(@d, "$key=$v");  
    }
    
  my $desc= join("; ", @d);
  my $fid= ($ID) ? $ID : $name;
  unless($fid) { $fid= "${type}_${loc}"; $fid =~ tr/a-zA-Z0-9/_/cs; }
  return "$fid $desc";
}



sub fastaFromFFFloop
{
  my  $self= shift;
  my ( $fffin, $outh, $chrIn, $featset )= @_;
  my ( $lastchr );
  my $nout= 0;
  my $sconfig= $self->handler->{config};
  $self->{ffformat}= 0; 
  my %lastfff= ();
  my $org= $self->{org}; # || $self->handler()->{config}->{org};
  my $rel= $self->{rel}; # || $self->handler()->{config}->{rel};

  my $allowanyfeat= 
    (!$featset || $featset =~ /^(any|all)/i) ? 1 
    : (defined $self->config->{allowanyfeat}) ? $self->config->{allowanyfeat} 
      : 0;
      
  while(<$fffin>) {
    next unless(/^\w/); chomp;
    my $fff= $_;
    
    ## my $faline= $self->fastaFromFFF( $_, $chrIn, $featset);
    ## print $fah $faline if $faline;
    
    #? loop here over @$featset ???
    # one input line can produce > 1 output fasta, e.g. gene & gene_extended, & intergene? 
    ## add option to handle intergene type feature sets -> subrange?

    my @fvals = $self->handler()->splitFFF($fff, $chrIn);
    $self->{ffformat}= $self->{gotffformat}; # set by splitFFF
    
    my($type,$name,$cytomap,$baseloc,$id,$dbxref,$notes,$chr)= @fvals;
    my @notes= $self->cleanNotes($notes);
    my @features= (ref $featset) ? @$featset : ($type);
    my $didfeat= 0;
    
    foreach my $featn (@features) {
        
        ## this loop is tricky - print each input fff only once UNLESS special
        ## case of showing in other types_ok
        
      ($type,$name,$cytomap,$baseloc,$id,$dbxref,$notes,$chr)= @fvals;
      my @fnotes= @notes;
      
      my($types_ok,$retype,$usedb,$subrange,$types_info)
          = $self->get_feature_set( $featn, $sconfig, $allowanyfeat);
      next unless( ($types_ok && $types_ok->{$type}) || ($allowanyfeat && !$didfeat) );

      $self->{use_dbmd5}= $usedb; #? want sep. flag in featmap.xml ? 

      if ($types_info->{method} eq 'between') {
        my $lastf= $lastfff{$type};
        $lastfff{$type}= $fff; # problems below.. save now
        if($lastchr eq $chr && $lastf) {
          ## arg - $lastfff only for same type as this fff !
          my $ffftween= $self->handler()->intergeneFromFFF2( $chr, $lastf, $fff);
          print STDERR "intergene: $ffftween\n" if $DEBUG > 1;
          next unless($ffftween);
          ($type,$name,$cytomap,$baseloc,$id,$dbxref,$notes,$chr)
             = $self->handler()->splitFFF( $ffftween, $chr);
          }
        else { next; }
        $self->{use_dbmd5}= 0;
        }

      if ($self->{idlist} && $types_info->{add_id}) { ## addids
        $dbxref= $self->addIdsToDbxref( ($id ? $id : $name), $dbxref );
        }
      
      my $fah= $outh->{$featn};
      unless($fah) { next; } #??
      
      my ($start,$stop,$strand)= $self->handler()->maxrange($baseloc);
      my $shortloc= ($stop<0) ? $baseloc : ($strand<0) ? "complement($start..$stop)" : "$start..$stop"; 
      # option for full/short loc in header?

      print STDERR "getBases id=$id type=$type chr=$chr loc=$baseloc\n" if $DEBUG>2;
      
      my $bases= $self->handler()->getBases( 
                 $usedb, $type, $chr, $baseloc, $id, $name, $subrange,
                 $types_info->{dotranslate});
      
      ## add optional md5checksum, SwissProt CRC64 calcs; 
      ##  check if last getBases returned md5checksum 
      my @crcs= $self->getCRCs( $id, \$bases, \@fnotes);
      
      my $header= $self->fastaHeader( type => $retype->{$type}||$type, 
          name => $name, chr => $chr, location => $shortloc, 
          ID => $id, db_xref => $dbxref, 
          $org ? (species => $org) : (),
          $rel ? (release => $rel) : (),
          @fnotes, @crcs,  
          );
      
      if ($bases) {
        my $slen= length($bases);
        $bases =~ s/(.{1,50})/$1\n/g;
        print $fah ">$header; len=$slen\n",$bases; 
        $nout++;
        }
      else {
        warn "ERROR: missing bases for $header\n";
        if ($self->handler()->{failonerror}) {  
          warn "FAILING: $chrIn $featset \n"; return undef;
          }
        # write at least one dummy base so user soft wont screw up
        print $fah ">$header; ERROR missing data\nN\n" if($self->config->{writeemptyrecords}); #? write to file or not
        }
        
      $didfeat++;
      }
      
    ($lastchr)=($chr);
    # $lastfff{$type}= $fff; #? problem
    }
    
  return $nout;    
}

sub getCRCs {
  my($self, $id, $basesref, $notesref)= @_;
  ## add optional md5checksum, SwissProt CRC64 calcs; 
  ##  check if last getBases returned md5checksum 
  my @retcrcs=();
  
  my($addmd5sum,$addcrc64)= ($self->config->{addmd5sum},$self->config->{addcrc64});
  my $use_dbmd5= $self->{use_dbmd5};
  if ($addmd5sum) {
    my $md5='';
    my $baseft= ($use_dbmd5) ? $self->handler()->getLastBasesFeature() : undef; 
    if ($baseft && ref($baseft) =~ /HASH/ && $$baseft{'uniquename'} eq $id) {
      $md5= $$baseft{'md5checksum'};
      }
    if ($md5) {
      # maybe calc and compare if want to verify ?
    } else {
    require Digest::MD5;
    my $md5sum= Digest::MD5->new;
    if($md5sum) {
      $md5sum->add($$basesref);
      $md5= $md5sum->hexdigest();
      }
    }
# warn "CRC id=$id md5=$md5\n" if $DEBUG > 1;
      push(@retcrcs, "MD5",$md5) if ($md5);
    }
    
  if ($addcrc64) {  
    require Bio::GMOD::Bulkfiles::SWISS_CRC64;
    my $crc64sum= SWISS_CRC64->new;
    if($crc64sum) {
      $crc64sum->add($$basesref);
      my $crc= $crc64sum->hexsum();
      push(@retcrcs, "CRC64",$crc) if ($crc);
      }
    }
  return @retcrcs;
}

=item fastaFromFFF

  $fa= $handler->fastaFromFFF( $fffeature,$chr,$featset)

  return fasta for one input feature line
   $fffeature = flat-file-feature input line
   chr = chromosome
   featset = key for feature type or type-set
 
  The flat-file-feature input line looks like
  
  @v= split "\t", $fffeature;
     if ($ffformat == 1) { ($type,$name,$cytomap,$baseloc,$id,$dbxref,$notes)= @v; }
  elsif ($ffformat == 2) { ($chr,$bstart,$type,$name,$cytomap,$baseloc,$id,$dbxref,$notes)= @v; }
   # format 2 just has leading chromosome, start-position fields for sorting
  where baseloc == Genbank/EMBL/DDBJ location string == BioPerl FTstring
 
=cut

sub fastaFromFFF
{
  my($self, $fffeature, $chrIn, $featset)= @_;
  
  my $allowanyfeat= 
    (!$featset || $featset =~ /^(any|all)/i) ? 1 
    : (defined $self->config->{allowanyfeat}) ?  $self->config->{allowanyfeat} 
      : 0;
  
  # print STDERR "fastaFromFFF: 1\n" if $DEBUG>1;
  my $org= $self->{org}; # || $self->handler()->{config}->{org};
  my $rel= $self->{rel}; # || $self->handler()->{config}->{rel};
  
  my($types_ok,$retype,$usedb,$subrange,$types_info)
        = $self->get_feature_set( $featset, undef, $allowanyfeat);

  return "" unless( ref $types_ok );
  
  my ($type,$name,$cytomap,$baseloc,$id,$dbxref,$notes,$chr)
        = $self->handler()->splitFFF($fffeature, $chrIn);

  return "" unless( $allowanyfeat || $types_ok->{$type} );
  # print STDERR "fastaFromFFF: 2\n" if $DEBUG>1;

  $self->{use_dbmd5}= $usedb; #? want sep. flag in featmap.xml ? 
  if ($self->{idlist} && $types_info->{add_id}) {
    $dbxref= $self->addIdsToDbxref( ($id ? $id : $name), $dbxref );
    }
  my @notes= $self->cleanNotes($notes);
  my ($start,$stop,$strand)= $self->handler()->maxrange($baseloc);
  my $shortloc= ($stop<0) ? $baseloc : ($strand<0) ? "complement($start..$stop)" : "$start..$stop"; 
  # option for full/short loc in header?
  
  my $bases= $self->handler()->getBases( 
             $usedb, $type, $chr, $baseloc, $id, $name, $subrange,
             $types_info->{dotranslate});

  ## add optional md5checksum, SwissProt CRC64 calcs; 
  my @crcs= $self->getCRCs( $id, \$bases, \@notes);

  my $header= $self->fastaHeader( type => $retype->{$type}||$type, 
      name => $name, chr => $chr, location => $shortloc, 
      ID => $id, db_xref => $dbxref, 
      $org ? (species => $org) : (),
      $rel ? (release => $rel) : (),
      @notes, @crcs,  
      );
  
  if ($bases) {
    my $slen= length($bases);
    $bases =~ s/(.{1,50})/$1\n/g;
    return ">$header; len=$slen\n".$bases; 
    }
  else {
    warn "ERROR: missing bases for $header\n";
    if ($self->handler()->{failonerror}) {  
      warn "FAILING: $featset \n"; return undef;
      }
        # write at least one dummy base so user soft wont screw up
    return ">$header; ERROR missing data\nN\n" if($self->config->{writeemptyrecords}); #? write to file or not
    }
}

=item fastaFromDb

For sequences not part of golden_path; not in genome feature table files
E.g. reagent sequences (EST, cDNA, misc ..)
See <featmap fromdb=1 onlydb=1 ?? >

=cut

sub fastaFromDb
{
  my($self, $outh, $featset)= @_;
  my @features= (ref $featset) ? @$featset : ($featset);

  my $org= $self->{org};  
  my $rel= $self->{rel};  
  my($species,$genus) = ($self->handler->speciesFull($org),'');
  ($genus,$species)= split(/[_ ]/,$species,2);  
  my $dbh= $self->handler->dbiConnect();
  my $nout= 0;
  
  foreach my $featn (@features) {
    print STDERR "fastaFromDb featn=$featn ?\n" if $DEBUG;
    
    my $allowanyfeat= 1;  # ????
#       (!$featn || $featn =~ /^(any|all)/i) ? 1 
#       : (defined $self->config->{allowanyfeat}) ?  $self->config->{allowanyfeat} 
#         : 0;
    
    my($types_ok,$retype,$usedb,$subrange,$types_info)
          = $self->get_feature_set( $featn, undef, $allowanyfeat);
    next unless($DEBUG || ref $types_ok );

    my $onlydb= $types_info->{onlydb} || 0;  ## is this right featmap flag ??
    next unless($DEBUG || $onlydb); #??    
    $usedb= 1;
    
    my ($chr,$cytomap)= (undef,undef);
    my ($baseloc)= (undef); # no location or dummy ??
    my $outhandle= $outh->{$featn};
    next unless($DEBUG || $outhandle); #??

    my $err="";    
    my $sql="";
    my $ftypes= "'" . join("','", sort keys %$types_ok) ."'" ;

    ### FIXME ... look in chadofeatsql ...
    ## $sql = $self->config->{feature2fastasql}; 
    $sql = " 
select f.feature_id, t.name as type, f.residues, f.md5checksum, f.seqlen, f.name, f.uniquename
from feature f, organism o, cvterm t
where t.name in ($ftypes) and t.cvterm_id = f.type_id
and o.genus = '$genus' and o.species = '$species' and o.organism_id = f.organism_id
      " unless($sql);
    print STDERR "fastaFromDb sql=$sql\n" if ($DEBUG );

    my $sth = $dbh->prepare($sql) or $err="unable to prepare feature_id";
    #$sth->execute($ftypes,$genus,$species) or $err="failed to execute feature_id"; 
    $sth->execute() or $err="failed to execute feature_id"; 
    if ($err) { ($self->{failonerror}) ? die $err : warn $err; return undef;  }
  
    while (my $nextrow = $sth->fetchrow_hashref) {
      my $type= $$nextrow{'type'};   
      my $name= $$nextrow{'name'};
      my $id  = $$nextrow{'uniquename'};
      my $feature_id = $$nextrow{'feature_id'};
      my $bases= $$nextrow{'residues'};
      my $seqlen= length($bases); ## $$nextrow{'seqlen'};

      # my ($start,$stop,$strand)= (1,$seqlen,0);
      # my $shortloc= "$start..$stop"; 

      my @notes= (); #what: featureprop, featuresynonym; others? $self->cleanNotes($notes);

      my $dbxref= ''; ##FIXME: $$nextrow{'dbxref'};
      if ($self->{idlist} && $types_info->{add_id}) {
        $dbxref= $self->addIdsToDbxref( ($id ? $id : $name), $dbxref );
        }
  
      my @crcs= ();
      ## $self->{use_dbmd5}= $usedb;  
      ## $self->getCRCs( $id, \$bases, \@notes);
      if ($self->config->{addmd5sum}) {
        my $md5= $$nextrow{'md5checksum'};
        push(@crcs, "MD5",$md5) if ($md5);
        }
        
      my $header= $self->fastaHeader( 
          type => $retype->{$type}||$type, 
          name => $name, ID => $id, db_xref => $dbxref, 
          # location => $shortloc, # chr => $chr, 
          $org ? (species => $org) : (),
          $rel ? (release => $rel) : (),
          @notes, @crcs,  
          );
          
      print STDERR "fastaFromDb[$nout]=$header\n" if ($DEBUG && $nout<4);
  
      if ($bases) {
        $bases =~ s/(.{1,50})/$1\n/g;
        print $outhandle ">$header; len=$seqlen\n".$bases; 
        }
      else {
        warn "ERROR: missing bases for $header\n";
        if ($self->handler()->{failonerror}) {  
          warn "FAILING: $featset \n"; return -1;
          }
        # write at least one dummy base so user soft wont screw up
        print $outhandle ">$header; ERROR missing data\nN\n" 
          if($self->config->{writeemptyrecords}); #? write to file or not
        }
      $nout++;
      }  # db row
    $sth->finish();
      
  }
  return $nout;
}


 ## patch for adding gene IDs to gene model features missing them

sub addIdsToDbxref
{
  my $self = shift;
  my ( $pid,  $dbxref )= @_;
  # my $pid= ($id ? $id : $name);
  $pid =~ s/[_-].*$//; # try for parent id - db prefix: ?
  my $idlist= $self->{idlist}; # from readids ...
  my $idpattern= $self->handler()->{idpattern};
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
  return ($dbxref); #??
}

  ##? check notes for synonyms=, other fields?
sub cleanNotes 
{
  my ($self, $notes)= @_;
  my @notes= ();
  if ($notes) {
    my $dropnotes= $self->config->{dropnotes} || 'xxx';
    my %notes=();
    foreach my $n (split(/[;]/,$notes)) {
      if ($n =~ /^(\w+)=(.+)/) { 
        my($k,$v)= ($1,$2); $v=~s/\s+$//;
        if ($v && $dropnotes !~ m/\b$k\b/) { $notes{$k} .= "$v,"; }
        } 
      }
    foreach my $n (sort keys %notes) {
      $notes{$n} =~ s/,$//;
      push(@notes, $n, $notes{$n}) if($notes{$n});
      }
    }
  return @notes;
}



=item raw2Fasta( %args )

args: 
  fastafile => $file # opt
  append => 1 # opt, append existing file
  chr => 'X' # required
  start => 1  #opt
  end => 100000 # opt
  type => 'chromosome' # opt
  defline => 'fasta defline' # opt
  
print fasta from dna-$chr.raw files, given $chr and optional $start,$end

=cut


sub raw2Fasta 
{
  my $self= shift;
  my %args= @_;  
  my $chr= $args{chr};
  my $fastafile= $args{fastafile};
  my $start= $args{start};
  my $end= $args{end};
  my $defline= $args{defline};
  my $type=  $args{type} || 'chromosome';
  my $append= $args{append};
  
  my $dnafile= $self->handler()->dnafile($chr);  
  unless($fastafile) {
    ($fastafile = $dnafile.".fasta") =~ s/\.raw//;  
    }
  if (!$append && -e $fastafile) { 
    warn "raw2Fasta: wont overwrite $fastafile"; return $fastafile; 
    }
  my $ap= ($append) ? ">>" : ">";
  my $outh= new FileHandle("$ap$fastafile");  
  my $org= $self->handler()->{config}->{org};
  my $rel= $self->handler()->{config}->{rel};
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
    
    #?? add: $self->getCRCs( $id, \$bases, \@notes);
    ## but need to read dna 1st; revise crc to do add-lines
    
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
  close $outh;
  print STDERR "raw2Fasta $fastafile, $defline\n" if $DEBUG;
  return $fastafile;
}



=item @info= get_feature_set($featset, $config, $allowanyfeat)

  given feature type or type-class, return info to screen, remap 
    individual features.  See config <featmap> and associated info.
    
  args:
  featset = single feature or feature set class name (given in configs)
  config  = configuration hash
  allowanyfeat = featset as basic type should be allowed (types_ok)
  
  return ($types_ok,$retype,$usedb,$subrange,$types_info)
  
  types_ok = hash of which basic types are allowed in featset
  retype  = rename basic types to these for output header
  usedb   = pull residues from database rather than chromosome dna (curated bases)
  subrange = expansion range (e.g for gene_expanded2000, etc.)
  types_info = all of featmap information
  
  
=cut

sub get_feature_set
{
  my( $self, $featset, $config, $allowanyfeat)= @_;
  
  #return $self->handler()->get_feature_set($featset,$config,$allowanyfeat);

  my($fromdb,$subrange) = (0,'');
  my @ft=(); 
  my @retype= ();
  my $type_info= {};
  $config = $self->handler->{config} unless($config);
  
  if(!$config->{featmap}->{$featset} && $featset =~ /^(\w+)_extended(\d+)$/) { 
    my ($t,$r)= ($1,$2); $featset= $t; $subrange= "-$r..$r";
    }

  if (defined $config->{featmap}->{$featset}) {
    my $fm= $config->{featmap}->{$featset};
    @ft= split(/[\s,;]/, $fm->{types} || $featset ); #? @{$fm->{types}};
    @retype= split(/[\s,;]/, $fm->{typelabel}) if ($fm->{typelabel});
    $fromdb= $fm->{fromdb} || 0;
    $subrange= $fm->{subrange} || $subrange;
    if ($fm->{method} eq 'between') {
      $fm->{proc}= '&intergeneFromFFF2'; ## FIXME
      }

    $type_info= $fm; # just save all ?
    }
  else {  
  CASE: {
    $featset =~ /^(gene|pseudogene)$/ && do { @ft=($featset); $type_info->{get_id}=1; last CASE; };
    $featset =~ /^(CDS|mRNA)$/ && do { @ft=($featset); last CASE; };
    $featset =~ /^(five_prime_UTR|three_prime_UTR|intron)$/ && do { @ft=($featset); $type_info->{add_id}= 'gene'; last CASE; };
    $featset =~ /^(tRNA|ncRNA|snRNA|snoRNA|rRNA)$/ && do { @ft=($featset); $type_info->{get_id}=1; last CASE; };
    $featset =~ /^(miscRNA)$/ && do { @ft=qw(ncRNA snRNA snoRNA rRNA); last CASE; };
    $featset =~ /^(transposable_element|transposon)$/ && do { @ft=('transposable_element'); last CASE; };
    $featset =~ /^gene_extended(\d+)$/ && do { @ft=('gene'); $subrange="-$1..$1"; @retype=("gene_ex$1");  last CASE; };
    $featset =~ /^(transcript)$/ && do { @ft=('mRNA'); $fromdb=1; @retype=('transcript'); last CASE; };
    $featset =~ /^(CDS_translation|translation)$/ && do { @ft=('CDS'); $fromdb=1; @retype=('translation'); last CASE; };
   
    default: { 
      if ($allowanyfeat) { @ft=($featset); }
      elsif (grep {$featset eq $_} @{$config->{fastafeatok}}) { @ft=($featset); }
      else { return undef; } ## warn "Unknown feature option: $@"; 
      };
    }
    }
    
  $fromdb= 0 if $self->handler()->{ignoredbresidues};
  my %types_ok= map { $_,1; } @ft;
  my %retype  = map { my $f= shift @ft; $f => $_; } @retype;
  return (\%types_ok, \%retype, $fromdb, $subrange, $type_info);
}



1;

__END__

