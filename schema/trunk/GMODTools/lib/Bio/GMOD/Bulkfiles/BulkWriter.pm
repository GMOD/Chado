package Bio::GMOD::Bulkfiles::BulkWriter;
use strict;

=head1 NAME

  Bio::GMOD::Bulkfiles::BulkWriter  
  
  >>> use ToFormat/ToFasta/ToGFF/.. instead ?
  
=head1 SYNOPSIS
  
  base class for other Bulkfiles writers
    
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
my $VERSION = "1.0";
my $configfile= "bulkwriter";


sub new 
{
	my $that= shift;
	my $class= ref($that) || $that;
	my %fields = @_;   
	my $self = \%fields; # config should be one
	bless $self, $class;
	$self->init_base();
	return $self;
}


sub DESTROY 
{
  my $self = shift;
}

sub init_base 
{
	my $self= shift;
	$DEBUG= $self->{debug} if defined $self->{debug};
  $self->{configfile}= $configfile unless defined $self->{configfile};
  $self->{failonerror}= 0 unless defined $self->{failonerror};
  $self->{skiponerror}= 1 unless defined $self->{skiponerror};
  
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
    ##$self->{bulkfiles}= $self->{sequtil}= $self->{handler}; # dang namechange .. or 'bulkfiles' .. which ?
    }
    
  ## add these to %ENV before reading blastfiles.xml so ${vars} get replaced ..
  my $sconfig= $self->handler()->{config};
  my @keys = qw( species org date title rel relfull relid release_url );
  @ENV{@keys} = @{%$sconfig}{@keys};

	$self->init(); # preconfig inits
  $self->readConfig($self->{configfile});
}

=item init()

Subclass: initialize at new() object, once only

=cut

sub init 
{
	my $self= shift;
	# for subclasses
	
	$DEBUG= $self->{debug} if defined $self->{debug};
  # $self->{configfile}= $configfile unless defined $self->{configfile};
}

sub config { return shift->{config}; }

sub handler { return shift->{handler}; } #$self->{bulkfiles}= $self->{sequtil}= $self->{handler}
sub sequtil { return shift->{handler}; }  
sub bulkfiles { return shift->{handler}; }  

=item readConfig($configfile)

read a configuration file - adds to any loaded configs

=cut

sub readConfig
{
	my $self= shift;
	my ($configfile)= @_;
  eval {  
    ## >> no good unless(ref $self->{config2}) { $self->{config2}= $self->{sequtil}->{config2}; }
    unless(ref $self->{config2}) { 
      require Bio::GMOD::Config2; 
      my @showtags= ($self->{verbose}) ? qw(name title about) : qw(name title);
      $self->{config2}= Bio::GMOD::Config2->new( {
        searchpath => [ 'conf/bulkfiles', 'bulkfiles', 'conf' ],
        showtags => \@showtags, # another debug/verbose option - print these if found
        read_includes => 1, # process include = 'conf.file'
        #gmod_root => $ROOT,
        #confdir => 'conf', ## << change to conf/bulkfiles ?
        #confpatt => '(gmod|[\w_\-]+db)\.conf$',
        } ); 
      }
     
    $self->{config}= $self->{config2}->readConfig( $configfile); 
    print STDERR $self->{config2}->showConfig( $self->{config}, { debug => $DEBUG }) 
      if ($self->{showconfig});  
  }; 
  if ($@) { 
    my $cf= $self->{config2}->{filename}; 
    warn "Config2: file=$cf; err: $@"; 
    die if $self->{failonerror};
    }
  
  $self->initData(); 
}


=item initData

Subclass: initialize config & other data after each readConfig 

=cut

sub initData
{
  my($self)= @_;
  my $config = $self->{config};
  my $sconfig= $self->handler()->{config};
  my $oroot= $sconfig->{rootpath};
 
    ## use instead $self->handler()->{config} values here?
  $self->{org}= $sconfig->{org} || $config->{org} || 'noname';
  $self->{rel}= $sconfig->{rel} || $config->{rel} || 'noname';  
  $self->{sourcetitle}= $sconfig->{title} || $config->{title} || 'untitled'; 
  $self->{sourcefile} = $config->{input}  || '';  
  $self->{date}= $sconfig->{date} || $config->{date} ||  POSIX::strftime("%d-%B-%Y", localtime( $^T ));
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
  unless(ref $fileset) { warn "makeFiles: no infiles => \@filesets given"; return; }
 
#   my @seqfiles= $self->openInput( $fileset );
#   my $res= $self->processBlastInput( \@seqfiles);

  return 1; #what?
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
  $intype= $self->{config}->{informat} unless ($intype); #? maybe array
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

