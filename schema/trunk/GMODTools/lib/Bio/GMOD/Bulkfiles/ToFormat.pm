package Bio::GMOD::Bulkfiles::ToFormat;
use strict;

=head1 NAME

  Bio::GMOD::Bulkfiles::ToFormat -- interface class 
  
=cut

# debug
use lib("/bio/biodb/common/perl/lib", "/bio/biodb/common/system-local/perl/lib");

our $DEBUG = 0;
my $VERSION = "1.0";

sub new 
{
	my $that= shift;
	my $class= ref($that) || $that;
	my %fields = @_;   
	my $self = \%fields; # handler, outh should be there
	bless $self, $class;
	$self->init();
	return $self;
}

sub init {
	my $self= shift;
  unless(ref $self->{handler}) { 
    warn "need handler => param"; $self->{handler}= {}; 
    }
  unless(ref $self->{outh}) { 
    warn "need output handle"; $self->{outh}= *STDOUT; 
    }
	$DEBUG= $self->{debug} if defined $self->{debug};
}

sub DESTROY 
{
  my $self = shift;
  ## $self->closeit(); close($self->{outh}); #??
  ## $self->SUPER::DESTROY();
}

=item get_filename( $org, $chr, $featn, $rel, $format)

  make standard output file name "${org}_${chr}_${featn}_${rel}.${format}"
  
=cut

sub get_filename
{
	my $self= shift;
  my( $org, $chr, $featn, $rel, $format)= @_;
  if ( $featn ) { $featn="_${featn}"; } else { $featn=''; }
  if ( $chr ) { $chr="_${chr}"; } else { $chr=''; }
  if ( $rel ) { $rel="_${rel}"; } else { $rel=''; }
  if (! $format ) { $format="undef"; }
  #?? leave to later# elsif ($format eq 'fff') { $format= 'tsv'; } # preserve old naming ??
  my $filename="${org}${chr}${featn}${rel}.${format}";
  return $filename;
}


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
