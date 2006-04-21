package Bio::GMOD::DB::Adaptor::FeatureIterator;

=pod

=head1 NAME

Bio::GMOD::DB::Adaptor::FeatureIterator

=head1 SYNOPSYS

  my $iterator = Bio::GMOD::DB::Adaptor::FeatureIterator->new(\@features);

  while (my $feat = $iterator->next_feature() ) {
      #do stuff with the feature
  }

=head1 DESCRIPTION

This is a very simple feature iterator with only two methods: new and
next_feature.  To use it, you pass in a reference to an array of
Bio::SeqFeatureI compliant feature objects, and subsequent invocations
of next_feature on the iterator object will give back one feature
object until there are no feature objects, when it will return nothing.

=head1 AUTHOR

=head1 AUTHOR - Scott Cain

Email cain@cshl.org

=cut

sub new {
  my $package  = shift;
  my $features = shift;
  return bless $features,$package;
}

sub next_feature {
  my $self = shift;
  return unless @$self;
    my $next_feature = shift @$self;
  return $next_feature;
}

1;

