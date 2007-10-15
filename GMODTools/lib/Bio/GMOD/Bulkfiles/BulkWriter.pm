package Bio::GMOD::Bulkfiles::BulkWriter;
use strict;

=head1 NAME

  Bio::GMOD::Bulkfiles::BulkWriter  
  
  >>> use ToFormat/ToFasta/ToGFF/.. instead ?
  
=head1 SYNOPSIS
  
  base class for other Bulkfiles writers

New output formats are added by subclassing the
Bio::GMOD::Bulkfiles::BulkWriter module, which basically
takes tabular inputs from the intermediary SQL output and
does something with it.  
    
Primary methods to subclass: 'makefiles' and 'readInput'
    
    
=head1 AUTHOR

D.G. Gilbert, 2004, gilbertd@indiana.edu

=head1 METHODS

=cut

#-----------------


use POSIX;
use FileHandle;
use File::Spec::Functions qw/ catdir catfile /;
use File::Basename;

our $DEBUG = 0;
sub DEBUG { return $DEBUG; }
#use constant DEBUG => 1;

my $VERSION = "1.1";
#my $configfile= "bulkwriter";
use constant BULK_TYPE => 'other';
use constant CONFIG_FILE => 'bulkwriter';


sub new 
{
	my $that= shift;
	my $class= ref($that) || $that;
	my %fields = @_;   
	my $self = \%fields; # config should be one
	bless $self, $class;
	$self->_init_base();
	return $self;
}


sub DESTROY 
{
  my $self = shift;
}


sub _init_base 
{
	my $self= shift;
	$DEBUG= $self->{debug};
  $self->{bulktype}  = $self->BULK_TYPE; #"other"; # dont need this hash val?
  $self->{configfile}= $self->CONFIG_FILE unless defined $self->{configfile};
	$self->{status}=0; $self->{error}= undef;

  # new common caller arg: fileinfo  is the fileset data
  # <fileset
  #   name="fasta"
  #   path="fasta/[\w\-\_]+.fasta"
  #   title="Fasta sequence of features"
  #   config="toFasta"
  #   handler="FastaWriter"
  #   type="fasta"
  #   date="20040821"
  #   dogzip="1"
  #   etc="..."
  #   />

  unless(ref $self->{handler}) {
    if(ref $self->{sequtil}) { $self->{handler}= $self->{sequtil}; }
    elsif(ref $self->{bulkfiles}) { $self->{handler}= $self->{bulkfiles}; }
    else { die "Should make ->new(handler => Bio::GMOD::Bulkfiles object)"; }
    }
    
  ## add these to %ENV before reading blastfiles.xml so ${vars} get replaced ..
  my $sconfig= $self->handler_config;
  my @keys = qw( species org date title rel relfull relid release_url );
  @ENV{@keys} = @{%$sconfig}{@keys};

	$self->init(); # preconfig inits
	
  $self->readConfig($self->{configfile});
	# == $self->{config}= $self->handler()->callReadConfig($self->{configfile});
  
  $self->initData(); 
}

=item init()

Subclass: initialize at new() object, once only

=cut

sub init 
{
	my $self= shift;
	# for subclasses
}

sub handler { return shift->{handler}; }  
# sub sequtil { return shift->{handler}; }  # old method; drop
# sub bulkfiles { return shift->{handler}; }   # old method; drop

sub config { return shift->{config}; }
sub handler_config { return shift->{handler}->{config}; }


sub outputpath 
{
  my $self = shift;
  unless($self->{outputpath}) {
    my $outputpath= $self->handler()->getReleaseSubdir( $self->getconfig('path') || $self->BULK_TYPE);
    $self->{outputpath} = $outputpath;
    }
  return $self->{outputpath};
}

sub status {
	my $self= shift;
	if(@_) {  
	  ## if status/error already set?
	  $self->{status}= shift; # unless ($self->{status});
	  $self->{error}= join(",",@_) if (@_);
	  }
  my $stat= $self->{status}; # check {error} ??
  $self->handler()->{didmake}{ $self->BULK_TYPE }= $stat;

  if ($stat < 0) { $stat="error ".$stat; }
  elsif ($stat == 1) { $stat='ok'; }
  return $self->BULK_TYPE."=".$stat; #what?
}

=item readConfig($configfile)

read a configuration file - adds to any loaded configs

=cut

sub readConfig
{
	my $self= shift;
	# my ($configfile)= @_;
	
  # ?? dont dupl this elsewhere: BulkWriter.pm subs
	$self->{config}= $self->handler()->callReadConfig(@_);
}


=item initData

Subclass: initialize config & other data after each readConfig 

=cut

sub initData
{
  my($self)= @_;
  my $config = $self->{config};
  my $sconfig= $self->handler_config();
  my $oroot= $sconfig->{rootpath};
  
  $self->{failonerror}= $sconfig->{failonerror}||0 unless defined $self->{failonerror};
  $self->{skiponerror}= $sconfig->{skiponerror}||1 unless defined $self->{skiponerror};
    
    ## use instead $self->getconfig('key')  
  $self->{org}= $sconfig->{org} || $config->{org} || 'noname';
  $self->{rel}= $sconfig->{rel} || $config->{rel} || 'noname';  
  $self->{sourcetitle}= $sconfig->{title} || $config->{title} || 'untitled'; 
  $self->{sourcefile} = $config->{input}  || '';  
  $self->{date}= $sconfig->{date} || $config->{date} || POSIX::strftime("%d-%B-%Y", localtime( $^T ));

  # copy any filesets to handler for those functions
  foreach my $type ( keys %{$config->{fileset}} ) {
    $sconfig->{fileset}->{$type}= $config->{fileset}->{$type}
      unless(defined $sconfig->{fileset}->{$type});
    }

  $self->{fileinfo} = $self->handler()->getFilesetInfo($self->BULK_TYPE)
    unless($self->{fileinfo}); 

  $self->promoteconfigs(); # uses above configs
}


=item promoteconfigs()

  copy fileinfo (1) and main config (2nd) values to self->config
  
=cut

sub promoteconfigs
{
  my $self = shift;
  my @mykeys= @_;
  my $config= $self->{config};
  ## $self->{config}= {}; # dont re-getconfig same

  my %nopromo= map { $_,1; } qw( id doc title about name date );
  unless(@mykeys) {
    @mykeys= grep !$nopromo{$_}, sort keys %{$config};
    }
  
  my $fileinfo = $self->{fileinfo} || {};  
  my $mainconf = $self->handler_config() || {}; 

  # copy any release-specific additions/changes to config from mainconf
  foreach my $key ( @mykeys ) {
    my $sc= $mainconf->{$key};
    $config->{$key}= _mergevars($config->{$key},$sc) if ($sc);
    }
#   foreach my $k (@mykeys) { # only main if not fileinfo
#      $config->{$k}= $mainconf->{$k} 
#        if(defined $mainconf->{$k} && !defined $fileinfo->{$k}); 
#      }

  # use all of fileinfo
  foreach my $k (keys %$fileinfo) { $config->{$k}= $fileinfo->{$k}; } 
  
  $self->{config}= $config;
}

sub _mergevars {
  my($v,$add)= @_;
  if (!$add) { return $v; }
  elsif (!$v) { return $add; }
  elsif (!ref($v) && !ref($add)) { return $add; } # new?
  elsif (ref($v) =~ /HASH/ && ref($add) =~ /HASH/) {
    foreach my $k (keys %$add) { $v->{$k}= $add->{$k}; }
    }
    
=item not this ??  duplicates data ; check for new ? 
  elsif (ref($v) =~ /ARRAY/) {
    if (ref($add) =~ /ARRAY/) { push(@$v, @$add); }
    else { push(@$v, $add); }
    }
=cut

  return $v;
}  

=item getconfig(@keys)

  return config value(s) for key(s); 
  look for key(s) in (1) fileset info; 
    (2) handler.config ?? should this preceed default?
    (3) default package config
  
=cut


sub getconfig {
  my $self = shift;
  my @keys= @_;
  
  ## need option to choose among fileinfo, handler, default
  my $fileinfo = $self->{fileinfo} || {}; # 1st priority or drop???
  my $mainconf = $self->handler_config() || {}; # 2nd priority; e.g. main release config
  my $deconfig = $self->{config} || {}; # 3rd priority; default settings

  if (wantarray) {
    my %vals=();
    foreach my $key (@keys) {
      $vals{$key}= 
          (defined $fileinfo->{$key}) ? $fileinfo->{$key}
        : (defined $mainconf->{$key}) ? $mainconf->{$key}
        : (defined $deconfig->{$key}) ? $deconfig->{$key} 
        : undef;
      }
    return %vals;  
    }
  else {
    my $key= $keys[0];
    return(defined $fileinfo->{$key}) ? $fileinfo->{$key}
        : (defined $mainconf->{$key}) ? $mainconf->{$key}
        : (defined $deconfig->{$key}) ? $deconfig->{$key} 
        : undef;
    }
  return undef;
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
  my $status= 0;
  unless(ref $fileset) { warn "makeFiles: needs infiles => \@filesets "; return; }
  
#   my @seqfiles= $self->openInput( $fileset );
#   my $res= $self->processBlastInput( \@seqfiles);

  if ($self->config->{makeall} && $status > 0) {
    my $chromosomes= "";
    my $feature= "";
    $self->makeall( $chromosomes, $feature, $self->BULK_TYPE); 
    }

  return  $self->status($status); #?? check files made
}

sub makeall 
{
	my $self= shift;
  my( $chromosomes, $feature, $format )=  @_;
  my $outdir= $self->outputpath();
  $chromosomes= $self->handler()->getChromosomes() unless (ref $chromosomes);

    ## this loop can be common to other writers: makeall( $chromosomes, $feature, $format) ...
  my $allfn= $self->get_filename ( $self->{org}, 'all', $feature, $self->{rel}, $format);
  $allfn= catfile( $outdir, $allfn);
  
  my @parts=();
  foreach my $chr (@$chromosomes) {
    next if ('all' eq $chr);
    my $fn= $self->get_filename ( $self->{org}, $chr, $feature, $self->{rel}, $format);
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


=item openInput( $fileset )

  handle input files
  
=cut

=item openInput( $fileset )

  handle input files
  
=cut

sub openInput
{
	my $self= shift;
  my( $fileset, $ipart, $intype )= @_; # do per-csome/name
  
  ## $intype ||= $self->getconfig('informat')  
  $intype= $self->config->{informat} unless ($intype); #? maybe array
  print STDERR "openInput: type=$intype part=$ipart \n" if $DEBUG; 
  
  my $atpart= 0;
  foreach my $fs (@$fileset) {
    my $fp  = $fs->{path};
    my $name= $fs->{name};
    my $type= $fs->{type};
    next unless(!$intype || $fs->{type} =~ /$intype/);  
    unless(-e $fp) { warn "missing infile $fp"; next; }
    $atpart++;
    next unless($atpart > $ipart);
    print STDERR "openInput: name=$name, type=$type, $fp\n" if $DEBUG; 
    
    ## note: fileset maker probably already set these.
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
  print STDERR "openInput: nothing matches part=$ipart\n" if $DEBUG; 
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

# for base class ...

=item makeSymlinks( $fileset, $intype, $toname_patt, $fromdir, $todir )

  make file symlinks;
  input parameters:
    $fileset, $intype, $toname_patt, $fromdir, $todir
  $toname_patt = pattern for todir/name with substitutions
  from fileset-> $name, $type, $chr, $format, $rel, $org
  e.g., toname_patt = 'dna-$chr.raw' 
   or "\$org-\$chr-\$type-\$rel.\$format"
  
=cut

sub makeSymlinks
{
	my $self= shift;
  my( $fileset, $intype, $toname_patt, $fromdir, $todir )= @_; # do per-csome/name
  
  foreach my $fs (@$fileset) {
#     my $fp= $fs->{path};
#     my $name= $fs->{name};
#     my $type= $fs->{type};  
#     my $chr= $fs->{chr};  
    my($fp,$name,$type,$chr,$format,$rel,$org)= 
      ($fs->{path},$fs->{name},$fs->{type},$fs->{chr},
       $fs->{format},$fs->{rel},$fs->{org} );
       # can we do () = $fs->{qw(path name ... org)} ? 
    next unless(!$intype || $fs->{type} =~ /$intype/);  
    ## unless(-e $fp) { warn "missing intype file $fp"; next; }
    my($filename, $dir) = File::Basename::fileparse($fp);
    
    my $toname = $toname_patt; # 'dna-$chr.raw'
    $toname =~ s/\$name/$name/;
    $toname =~ s/\$type/$type/;
    $toname =~ s/\$chr/$chr/;
    $toname =~ s/\$format/$format/;
    $toname =~ s/\$rel/$rel/;
    $toname =~ s/\$org/$org/;
    
    my $relpath= catfile($fromdir, $filename); 
    my $symname= catfile($todir, $toname);
    symlink( $relpath, $symname);
    print STDERR "symlink $toname -> $relpath\n" if $DEBUG; 
    }
 #return error/ok ?
}


=item copyFiles( $fileset, $intype, $toname_patt, $todir )

  copy files;
  input parameters:
    $fileset, $intype, $toname_patt, $todir
  $toname_patt = pattern for todir/name with substitutions
  from fileset-> $name, $type, $chr, $format, $rel, $org
  e.g., toname_patt = 'dna-$chr.raw' 
   or "\$org-\$chr-\$type-\$rel.\$format"
  
=cut

sub copyFiles
{
	my $self= shift;
  my( $fileset, $intype, $toname_patt, $todir )= @_; # do per-csome/name
  
  foreach my $fs (@$fileset) {
    my($fp,$name,$type,$chr,$format,$rel,$org)= 
      ($fs->{path},$fs->{name},$fs->{type},$fs->{chr},
       $fs->{format},$fs->{rel},$fs->{org} );
       # can we do () = $fs->{qw(path name ... org)} ? 
    next unless( !$intype || $fs->{type} =~ m/$intype/);  
    ## unless(-e $fp) { warn "missing intype file $fp"; next; }
    ## my($filename, $dir) = File::Basename::fileparse($fp);
    
    my $toname = $toname_patt || $name;  
    $toname =~ s/\$name/$name/;
    $toname =~ s/\$type/$type/;
    $toname =~ s/\$chr/$chr/;
    $toname =~ s/\$format/$format/;
    $toname =~ s/\$rel/$rel/;
    $toname =~ s/\$org/$org/;
    
    my $frompath= $fp; ##catfile($fromdir, $filename); 
    my $topath  = catfile($todir, $toname);
    system('/bin/cp', '-p', $frompath, $topath);
    print STDERR "copy $frompath to $toname\n" if $DEBUG; 
    }
 #return error/ok ?
}



=item readIdsFromFFF

pre-read ids from fff input for selected features for others to add_id or filter by id
moved to base class for reuse

=cut

sub readIdsFromFFF
{
	my $self= shift;
  my ($fffin,$chr,$config)= @_;
  my $idlist= {};  
  my $types_info= $config->{featmap};
  my $nid=0;
  
  while(<$fffin>) {
    next unless(/^\w/); chomp;
    my ($type,$name,$cytomap,$baseloc,$id,$dbxref,$notes,$chr1)
        = $self->handler()->splitFFF($_, $chr);
    if ($types_info->{$type}->{get_id}) { $idlist->{$id}= $dbxref; $nid++; }
    }
  print STDERR  "read ids n=$nid\n" if $DEBUG;
  return $idlist;
}

=item get_filename

  $fname= get_filename( $org, $chr, $featn, $rel, $format)
  make standard output file name "${org}_${chr}_${featn}_${rel}.${format}"
  
=cut

sub get_filename
{
  return shift->handler()->get_filename( @_);
}

=item split_filename

  ( $org, $chr, $featn, $rel, $format)= split_filename( $fname)
  return parts of standard output file name "${org}_${chr}_${featn}_${rel}.${format}"
  
=cut

sub split_filename
{
  return shift->handler()->split_filename( @_);
}


=item isold($source,$target)

  is source file older than target?
  ## not for symlinks or dirs
  
=cut

sub isold 
{
	my $self= shift;
  my($source,$target) = @_;
  if (! -e $target) { return 1; }
	my $res= 0;
  my $targtime= -M $target; ## -M is file age in days.hrs before now
  if ( -l $source ) {
    # $source= getOriginal($source);
    $res= (-M $source) < $targtime; 
    }
  elsif ( -e $source ) { 
    $res= (-M $source) < $targtime; 
    }
  else { $res= 0; }
  return $res;
}



1;

__END__

