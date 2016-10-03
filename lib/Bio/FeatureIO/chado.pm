package Bio::FeatureIO::chado;

use strict;
use base qw(Bio::FeatureIO);

use Bio::SeqIO;
use Bio::Chado::LoadDBI;
use Data::Dumper;

sub _initialize {
  my($self,%arg) = @_;
  $self->SUPER::_initialize(%arg);

  $self->feature_count(0);
  $self->organism($arg{-organism} || 'Human');
  $self->cachesize($arg{-cachesize} || 1000);
}

sub next_feature {
  shift->throw('this class only writes to database');
}

sub write_feature {
  my($self,$feature) = shift;

}

=head2 cache

 Title   : cache
 Usage   : $obj->cache($newval)
 Function: cache an object for commit to db.  when number of
           items in cache exceeds cachesize(), objects are flushed
 Example : 
 Returns : value of cache (a scalar)
 Args    : on set, new value (a scalar or undef, optional)


=cut

sub cache{
  my $self = shift;
  my $val = shift;

  push @{ $self->{'cache'} }, $val if ref($val);

  if(scalar @{ $self->{'cache'} } > $self->cachesize){
    $_->dbi_commit foreach @{ $self->{'cache'} };
    @{ $self->{'cache'} } = ();
  }
}

=head2 cachesize

 Title   : cachesize
 Usage   : $obj->cachesize($newval)
 Function: number of features to cache before flushing to db
 Example : 
 Returns : value of cachesize (a scalar)
 Args    : on set, new value (a scalar or undef, optional)


=cut

sub cachesize{
    my $self = shift;

    return $self->{'cachesize'} = shift if @_;
    return $self->{'cachesize'};
}


=head2 organism

 Title   : organism
 Usage   : $obj->organism($newval)
 Function: organism of features being loaded
 Example : 
 Returns : value of organism (a scalar)
 Args    : on set, new value (a scalar or undef, optional)


=cut

sub organism{
    my $self = shift;

    return $self->{'organism'} = shift if @_;
    return $self->{'organism'};
}

1;
