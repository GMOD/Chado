package Bio::GMOD::Load;
use strict;
use Chado::AutoDBI;
use Chado::LoadDBI;
use Bio::GMOD::Util;
use Class::DBI::ConceptSearch;
use Bio::GMOD::Config;
use Bio::Root::Root;
use Bio::GMOD::Util;

=head2 new

=over

=item Usage

  $obj->new()

=item Function

=item Returns

=item Arguments

=back

=cut

sub new {
    my $proto = shift;
    my $self  = bless {}, ref($proto) || $proto;

    my $conf = Bio::GMOD::Config->new();
    my $cs_config_file = $conf->get_tag_value('CONCEPT_SEARCH_CONFIG');
    my $cs_config;

    open CONF, $cs_config 
        or $self->throw("unable to open ConceptSearch config file: $!");
    while (<CONF>) {
        $cs_config .= $_;
    }
    close CONF;

    my $cs = Class::DBI::ConceptSearch->new(xml => $config);

    $self->concept_search($cs);

    return $self;
}

=head2 concept_search

=over

=item Usage

  $obj->concept_search()        #get existing value
  $obj->concept_search($newval) #set new value

=item Function

=item Returns

value of concept_search (a scalar)

=item Arguments

new value of concept_search (to set)

=back

=cut

sub concept_search {
    my $self = shift;
    return $self->{'concept_search'} = shift if defined(@_);
    return $self->{'concept_search'};
}



=head2 search

=over

=item Usage

  $obj->search()

=item Function

=item Returns

=item Arguments

hash of search terms

=back

=cut

sub search {
    my ($self, %argv) = @_;

    return unless %argv;

    my @object = $self->concept_search()->search( %argv );

    return @object;
}

=head2 find_or_create

=over

=item Usage

  $obj->find_or_create()

=item Function

=item Returns

=item Arguments

=back

=cut

sub find_or_create {
    my ($self, %argv) = @_;


}

=head2 cache_feature

=over

=item Usage

  $obj->cache_feature()

=item Function

=item Returns

=item Arguments

=back

=cut

sub cache_feature {
    my ($self, %argv) = @_;


}

=head2 cv

=over

=item Usage

  $obj->cv()

=item Function

=item Returns

=item Arguments

=back

=cut

sub cv {
    my $self = shift;
    return $self->{'cv'} if $self->{'cv'};

    $self->{'cv'} = Chado::Cv->find_or_create(
        {
            name       => 'autocreated',
            definition => 'auto created by load_gff3.pl'
        }
    );

    return $self->{'cv'};
}

=head2 so

=over

=item Usage

  $obj->so()

=item Function

=item Returns

=item Arguments

=back

=cut

sub so {
    my $self = shift;
    return $self->{'so'} if $self->{'so'};

    $self->{'so'} = Chado::Cv->search( { name => 'Sequence Ontology' } );
    die "Unable to find Sequence Ontology in cv table; that is a pretty big problem" 
        unless $self->{'so'};
    return $self->{'so'};
}


sub cache_cvterm {
    my $self = shift;
    my $name = shift;
    my $soid = shift;
                                                                                                              
    ( $cvterm{$name} ) = Chado::Cvterm->search( {
                                                  name => $name,
                                                  cv_id=> $soid } )
                      || Chado::Cvterm->search( {
                                                  name => ucfirst($name),
                                                  cv_id=> $soid } );
                                                                                                              
    $cvterm{$name} = $cvterm{$name}->next()
      if defined( $cvterm{$name} )
      and $cvterm{$name}->isa('Class::DBI::Iterator');
                                                                                                              
    if ( !$cvterm{$name} && !$soid  ) {
        ( $cvterm{$name} ) = Chado::Cvterm->find_or_create(
            {
                name       => $name,
                cv_id      => $self->cv()->id,
                definition => 'autocreated by gmod_load_gff3.pl',
            }
        );
    }
    die "unable to create a '$name' entry in the cvterm table"
      if (!$cvterm{$name} && !$soid );
    die "$name could not be found in your cvterm table.\n"
       ."Either the Sequence Ontology was incorrectly loaded,\n"
       ."or this file doesn't contain GFF3"
       if (!$cvterm{$name} && $soid);
}

=head2 srcfeature

=over

=item Usage

  $obj->srcfeature()        #get existing value
  $obj->srcfeature($newval) #set new value

=item Function

=item Returns

value of srcfeature (a scalar)

=item Arguments

new value of srcfeature (to set)

=back

=cut

sub srcfeature {
    my $self = shift;
    return unless defined $_[0];
    return ${$self->{'srcfeature'}}->$_[0] = $_[1] if defined($_[1]);
    return ${$self->{'srcfeature'}}->$_[0];
}

=head2 featureloc_locgroup

=over

=item Usage

  $obj->featureloc_locgroup()        #get existing value
  $obj->featureloc_locgroup($newval) #set new value

=item Function

=item Returns

value of featureloc_locgroup (a scalar)

=item Arguments

new value of featureloc_locgroup (to set)

=back

=cut

sub featureloc_locgroup {
    my $self = shift;
    return unless defined $_[0];
    return ${$self->{'featureloc_locgroup'}}->$_[0] = $_[1] if defined($_[1]);
    return ${$self->{'featureloc_locgroup'}}->$_[0];
}

=head2 feature

=over

=item Usage

  $obj->feature()        #get existing value
  $obj->feature($newval) #set new value

=item Function

=item Returns

value of feature (a scalar)

=item Arguments

new value of feature (to set)

=back

=cut

sub feature {
    my $self = shift;
    return unless defined $_[0];
    return ${$self->{'feature'}}->$_[0] = $_[1] if defined($_[1]);
    return ${$self->{'feature'}}->$_[0];
}

=head2 gff_source

=over

=item Usage

  $obj->gff_source()        #get existing value
  $obj->gff_source($newval) #set new value

=item Function

=item Returns

value of gff_source (a scalar)

=item Arguments

new value of gff_source (to set)

=back

=cut

sub gff_source {
    my $self = shift;
    return unless defined $_[0];
    return ${$self->{'gff_source'}}->$_[0] = $_[1] if defined($_[1]);
    return ${$self->{'gff_source'}}->$_[0];
}

=head2 dbxref

=over

=item Usage

  $obj->dbxref()        #get existing value
  $obj->dbxref($newval) #set new value

=item Function

=item Returns

value of dbxref (a scalar)

=item Arguments

new value of dbxref (to set)

=back

=cut

sub dbxref {
    my $self = shift;
    return unless defined $_[0];
    return ${$self->{'dbxref'}}->$_[0] = $_[1] if defined($_[1]);
    return ${$self->{'dbxref'}}->$_[0];
}


=head2 gff_source_db

=over

=item Usage

  $obj->gff_source_db()        #get existing value
  $obj->gff_source_db($newval) #set new value

=item Function

=item Returns

value of gff_source_db (a scalar)

=item Arguments

new value of gff_source_db (to set)

=back

=cut

sub gff_source_db {
    my $self = shift;
    return $self->{'gff_source_db'} = shift if defined(@_);
    return $self->{'gff_source_db'};
}

