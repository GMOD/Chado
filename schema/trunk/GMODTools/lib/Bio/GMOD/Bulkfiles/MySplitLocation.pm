package Bio::GMOD::Bulkfiles::MySplitLocation;
use strict;

=head1 Bio::GMOD::Bulkfiles::MySplitLocation

  patch for Bio::Location::Split 
  
=cut

use vars qw(@ISA);
  ## REV COMP NOT WORKING!  LargeSeq looks ok ... Bio::Location::Split is bad for strand !

use Bio::Root::Root;
use Bio::Location::SplitLocationI;
use Bio::Location::Atomic;
use Bio::Location::Split;

BEGIN{
@ISA = qw(Bio::Location::Split);
}

sub new {
    my ($class, @args) = @_;
    ## Atomic doing strange things which throws## my $self = $class->SUPER::new(@args);
    my $self = {};

    bless $self,$class;
    $self->{'_sublocations'} = [];
    $self->splittype('JOIN');
    return $self;
}

=item strand

Bio::Location::Split  IS DOING WRONG THING HERE 
it should do same as Simple/Atomic location, and
PrimarySeq handler then properly reverses, etc. all of location

  Title   : strand
  Usage   : $strand = $loc->strand();
  Function: get/set the strand of this range
  Returns : the strandidness (-1, 0, +1)
  Args    : optionaly allows the strand to be set
          : using $loc->strand($strand)

=cut

sub strand {
  my $self = shift;

  if ( @_ ) {
       my $value = shift;
       if ( defined($value) ) {
	   if ( $value eq '+' ) { $value = 1; }
	   elsif ( $value eq '-' ) { $value = -1; }
	   elsif ( $value eq '.' ) { $value = 0; }
	   elsif ( $value != -1 && $value != 1 && $value != 0 ) {
	       $self->throw("$value is not a valid strand info");
	   }
           $self->{'_strand'} = $value;
       }
  }
  # do not pretend the strand has been set if in fact it wasn't
  return $self->{'_strand'};
}

## this is also bad in split - forgot strand

sub to_FTstring {
  my ($self) = @_;
  my @strs;
  foreach my $loc ( $self->sub_Location() ) {	
    my $str = $loc->to_FTstring();
    if( (! $loc->is_remote) &&
        defined($self->seq_id) && defined($loc->seq_id) &&
        ($loc->seq_id ne $self->seq_id) ) {
        $str = sprintf("%s:%s", $loc->seq_id, $str);
    } 
  push @strs, $str;
  }    
  my $spt= lc $self->splittype;
  if( defined $self->strand && $self->strand == -1 ) {
    $spt = "complement";
    }
  my $str = sprintf("%s(%s)",$spt, join(",", @strs));
  return $str;
}


1;
