package Bio::GMOD::Bulkfiles::ToFormat;
use strict;

=head1 NAME

  Bio::GMOD::Bulkfiles::ToFormat -- base class for other Bulkfiles writers
  
=cut

# debug
use lib("/bio/biodb/common/perl/lib", "/bio/biodb/common/system-local/perl/lib");

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
	my $self = \%fields; # handler, outh should be there
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
  ## $self->{configfile}= $configfile unless defined $self->{configfile};

  unless(ref $self->{handler}) {
    if(ref $self->{bulkfiles}) { $self->{handler}= $self->{bulkfiles}; }
    else { die "Should make ->new(handler => Bio::GMOD::Bulkfiles object)"; }
    }
  unless(ref $self->{outh}) { 
    warn "need outh => output-handle"; $self->{outh}= *STDOUT; 
    }
    
	$self->init(); # preconfig inits
  $self->readConfig($self->{configfile});
}


=item init()

Subclass: initialize at new() object, once only

=cut

sub init 
{
	my $self= shift;
	
  $self->{configfile}= $configfile unless defined $self->{configfile};
	# for subclasses
}

sub config { return shift->{config}; }

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
      $self->{config2}= Bio::GMOD::Config2->new( {
        #gmod_root => $ROOT,
        #confdir => 'conf', ## << change to conf/bulkfiles ?
        #confpatt => '(gmod|[\w_\-]+db)\.conf$',
        } ); 
      }
     
    $self->{config}= $self->{config2}->readConfig( $configfile); 
    print STDERR $self->{config2}->showConfig( $self->{config}, { debug => $DEBUG }) 
      if ($self->{showconfig});  
  }; warn "Config2 err: $@" if ($@);
  
  $self->initData(); 
}


=item initData

Subclass: initialize config & other data after each readConfig 

=cut

sub initData
{
  my($self)= @_;
  my $config = $self->{config};
  my $sconfig= $self->{sequtil}->{config};
  my $oroot= $sconfig->{rootpath};
 
    ## use instead $self->{sequtil}->{config} values here?
  $self->{org}= $sconfig->{org} || $config->{org} || 'noname';
  $self->{rel}= $sconfig->{rel} || $config->{rel} || 'noname';  
  $self->{sourcetitle}= $sconfig->{title} || $config->{title} || 'untitled'; 
  $self->{sourcefile} = $config->{input}  || '';  
  $self->{date}= $sconfig->{date} || $config->{date} ||  POSIX::strftime("%d-%B-%Y", localtime( $^T ));
}


=item get_filename

  $fname= get_filename( $org, $chr, $featn, $rel, $format)
  make standard output file name "${org}_${chr}_${featn}_${rel}.${format}"
  
=cut

sub get_filename
{
  return shift->{sequtil}->get_filename( @_);
}

=item split_filename

  ( $org, $chr, $featn, $rel, $format)= split_filename( $fname)
  return parts of standard output file name "${org}_${chr}_${featn}_${rel}.${format}"
  
=cut

sub split_filename
{
  return shift->{sequtil}->split_filename( @_);
}


=item isold($source,$target)

  is source file older than target?
  
=cut

sub isold 
{
	my $self= shift;
  my($source,$target) = @_;
  ## not for symlinks or dirs
	my $res= 0;
  my $targtime= -M $target; ## -M is file age in days.hrs before now
  if (! -f $target) {
    return 1;
    }
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


#------- writing methods -----------


sub writeheader 
{
	my $self= shift;
  my($seqid,$start,$stop)= @_;
  my $fh= $self->{outh};

  my $date = $self->{handler}->{date};
  my $sourcetitle = $self->{handler}->{sourcetitle};
  my $sourcefile = $self->{handler}->{sourcefile};
  my $org= $self->{handler}->{org};
  print $fh "# Features for $org from $sourcetitle [$sourcefile, $date]\n";
  print $fh "# source: ",join("\t", $seqid, "$start..$stop"),"\n";
  print $fh "#\n";
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



#-------------
1;
