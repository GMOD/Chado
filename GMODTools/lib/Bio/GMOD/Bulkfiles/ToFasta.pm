package Bio::GMOD::Bulkfiles::ToFasta;
use strict;

=head1 NAME

  Bio::GMOD::Bulkfiles::ToFasta 
  
=cut

# debug
use lib("/bio/biodb/common/perl/lib", "/bio/biodb/common/system-local/perl/lib");

use vars qw/@ISA/;
use Bio::GMOD::Bulkfiles::ToFormat;   
our $DEBUG = 0;
my $configfile= "tofasta"; #? BulkFiles/tofasta.xml 

BEGIN { @ISA = qw/ Bio::GMOD::Bulkfiles::ToFormat /; }

sub init {
	my $self= shift;
	$self->SUPER::init();

  # $self->{failonerror}= 0 unless defined $self->{failonerror};
}

=item initData

initialize data from config

=cut

sub initData
{
  my($self)= @_;
  $self->SUPER::initData();
  my $config = $self->{config};
  my $sconfig= $self->{handler}->{config};
  my $oroot= $sconfig->{rootpath};
 
    ## use instead $self->{handler}->{config} values here?
#   $self->{org}= $sconfig->{org} || $config->{org} || 'noname';
#   $self->{rel}= $sconfig->{rel} || $config->{rel} || 'noname';  
#   $self->{sourcetitle}= $sconfig->{title} || $config->{title} || 'untitled'; 
#   $self->{sourcefile} = $config->{input}  || '';  
#   $self->{date}= $sconfig->{date} || $config->{date} ||  POSIX::strftime("%d-%B-%Y", localtime( $^T ));
  
  my $fastadir= $self->{handler}->getReleaseSubdir( $sconfig->{fastafiles}->{path} || 'fasta/');
  $self->{fastadir} = $config->{fastadir}= $fastadir;
  
}


#-------------- subs -------------


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
  unless(ref $fileset) { 
    
    # $fileset= $self->{sequtil}->getFastaFiles();
    
    warn "makeFiles: no infiles => \@filesets given"; return; 
    }
 
  my @ffffiles= $self->openInput( $fileset );
  my $res= $self->processFasta( \@ffffiles);
  
  print STDERR "FastaWriter::makeFiles: done\n" if $DEBUG; 

  return 1; #what?
}

=item openInput( $fileset )

  handle input files
  
=cut

sub openInput
{
	my $self= shift;
  my( $fileset )= @_; # do per-csome/name
  my @files= ();
  my $inh= undef;
  return undef unless(ref $fileset);

  my $intype = $self->{config}->{informat} || 'fff'; #? maybe array
  my $featset= $self->{config}->{featset} || [];
  if (@$featset) { 
  
    }
    
  print STDERR "openInput: type=$intype \n" if $DEBUG; 
  
  foreach my $fs (@$fileset) {
    my $fp= $fs->{path};
    my $name= $fs->{name};
    my $type= $fs->{type}; # want also/instead featset type here ? gene,mrna,cds,...
    next unless( $fs->{type} =~ /$intype/); # could it be 'dna/fasta', 'amino/fasta' ?
    unless(-e $fp) { warn "missing intype file $fp"; next; }

    push(@files, $fp);
    }
    
  return @files;  
}



=item processFasta


=cut

sub processFasta
{
	my $self= shift;
  my( $rseqfiles )=  @_;
  
#   my $blastdir= $self->{blastdir};
#   my ($doformat, $doconfig)= (1,1);
#   my $ndone= 0;
#   
#   # format only if changed...
#   $self->updateformat(  $blastdir, $rseqfiles) if ($doformat);
#   
#   my @blastfiles=();
#   opendir(D, $blastdir);
#   @blastfiles= grep(/^\w/,readdir(D));
#   closedir(D);
#   
#   if ($doconfig) {
#     $self->update_blastrc( $blastdir, \@blastfiles);
#     $self->update_dbselect( $blastdir, \@blastfiles);
#     $self->update_dbhtml( $blastdir, \@blastfiles);
#     }
# 
#   $ndone= scalar( @blastfiles);
#   print STDERR "processBlastInput ndone = $ndone\n" if $DEBUG;
#   return $ndone;

}




sub writeheader 
{
	my $self= shift;
  my($seqid,$start,$stop)= @_;
#   my $fh= $self->{outh};
#   my $date = $self->{handler}->{date};
#   my $sourcetitle = $self->{handler}->{sourcetitle};
#   my $sourcefile = $self->{handler}->{sourcefile};
#   my $org= $self->{handler}->{org};
#   print $fh "# Features for $org from $sourcetitle [$sourcefile, $date]\n";
#   print $fh "# source: ",join("\t", $seqid, "$start..$stop"),"\n";
#   print $fh "#\n";
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



=item raw2Fasta( %args )

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
  
  my $dnafile= $self->{handler}->dnafile($chr);  
  unless($fastafile) {
    ($fastafile = $dnafile.".fasta") =~ s/\.raw//;  
    }
  if (-e $fastafile) { warn "raw2Fasta: wont overwrite $fastafile"; return $fastafile; }
  my $outh= new FileHandle(">$fastafile"); ## $self->{outh};
  my $org= $self->{handler}->{config}->{org};
  my $rel= $self->{handler}->{config}->{rel};
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


=item $fa= $handler->fastaFromFFF( $fffeature,$chr,$featset)

return fasta for one flat-file-feature input line

 chr = chromosome
 featset = key for feature type or type-set
 
=cut

sub fastaFromFFF
{
  my($self,$fffeature,$chr,$featset)= @_;
  
  ## revise this param set for more options - expand +/- ends, array of featset types, chr, ...
  ## gene_extended(\d+)
  
  my $config= $self->{handler}->{config};
  my $dropnotes= $config->{fastafiles}->{dropnotes} || 'xxx';
  
  my $ffformat= 0; my $nout= 0;
  my $bstart; 
  my @csomes= @{ $self->{handler}->getChromosomes() || [] };
  my($types_ok,$retype,$usedb,$subrange,$types_info)
        = $self->{handler}->get_feature_set($featset,$config);
  return "" unless( ref $types_ok );
  $usedb= 0 if $self->{handler}->{ignoredbresidues};
  ##my $outh= $self->{outh};
  
  my($type,$name,$cytomap,$baseloc,$id,$dbxref,$notes);
  chomp($fffeature);
  my @v= split "\t", $fffeature;
    
  foreach (@v) { $_='' if $_ eq '-'; }
  if ($ffformat == 0) {
    if (grep({$v[0] eq $_} @csomes) && $v[1] =~ /^\d+$/) { $ffformat= 2; }
    else { $ffformat= 1; } ## assume caller is sensible
    ##if ($v[1] =~ /^\d+$/ && grep({$v[2] eq $_} @allfeats)) { $ffformat= 2; }
    #elsif ( grep({$v[0] eq $_} @allfeats) ) { $ffformat= 1; } ## FIXME 
    #else { warn "skipped; not FFF format? @v";  return "";  }
    }
  if ($ffformat == 1) { ($type,$name,$cytomap,$baseloc,$id,$dbxref,$notes)= @v; }
  elsif ($ffformat == 2) { ($chr,$bstart,$type,$name,$cytomap,$baseloc,$id,$dbxref,$notes)= @v; }
   
  return "" unless( $types_ok->{$type} );
  
  ##? patch for adding gene IDs to gene model features missing them
  if ($self->{handler}->{addids} && $types_info->{$type} && $types_info->{$type}->{add_id}) {
    my $pid= ($id ? $id : $name);
    $pid =~ s/[_-].*$//; # try for parent id - db prefix: ?
    my $idlist= $self->{handler}->{idlist}; # from readids ...
    my $idpattern= $self->{handler}->{idpattern};
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
  
  my $bases= $self->{handler}->getBases(
    $usedb,$type,$chr,$baseloc,$id,$name,$subrange);
  if ($bases) {
    $nout++;
    my $slen= length($bases);
    $bases =~ s/(.{1,50})/$1\n/g;
    return ">$header; len=$slen\n".$bases; 
    }
  else {
    warn "ERROR: missing bases for $header\n";
    if ($self->{handler}->{failonerror}) {  
      warn "FAILING: $featset \n";
      return -1;
      }
    return ">$header; ERROR missing data\n"; #? write to file or not
    }
}



#------

1;
