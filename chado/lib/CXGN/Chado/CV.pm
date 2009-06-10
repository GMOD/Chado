=head1 NAME
DEPRECATED . USE Ontology.pm instead
CXGN::Chado::CV 
A class for handling controlled vocabularies

=head1 SYNOPSIS


=head1 AUTHOR

Naama Menda (nm249@cornell.edu)

=cut
use CXGN::DB::Connection;


package CXGN::Chado::CV;
use base qw /CXGN::Chado::Main CXGN::DB::Object / ;

=head2 new

 Usage: my $cv = CXGN::Chado::CV->new($dbh, $cv_id);
 Desc:  A new CV object 
 Ret:  a new CV object
 Args: a database handle, (optional - a database id)
 Side Effects: sets dbh and cv_id
 Example:

=cut


sub new {
    my $class = shift;
    my $dbh= shift;
    my $cv_id = shift; #id of the cv database
   
    my $self= $class->SUPER::new($dbh);

       
    $self->set_cv_id($cv_id);
   
    if ($cv_id) {
	$self->fetch();
    }
    
    return $self;
}


=head2 new_with_name

 Usage: my $rel = CXGN::Chado::CV->new_with_name($dbh, "relationship");
 Desc:         useful for getting a cv objects.
             
 Ret:          a cv object
 Args:         a database handle and a cv name
 Side Effects:
 Example:

=cut

sub new_with_name {
    
    my $class = shift;
    my $dbh = shift;
    my $name = shift;
        
    if (!$name ) { die "[CV.pm] new_with_name: Need name ."; }

    my $query = "SELECT cv_id from cv where name ilike ?";
    my $sth = $dbh->prepare($query);
    $sth->execute($name);
    my ($cv_id) = $sth->fetchrow_array();
    my $self = CXGN::Chado::CV->new($dbh, $cv_id);
    return $self;
}



sub fetch {
    my $self=shift;

    my $cv_query = $self->get_dbh()->prepare("SELECT  name, definition FROM public.cv WHERE cv_id=? ");

         	   
    $cv_query->execute( $self->get_cv_id() );

 
    my ($cv_name, $definition)=$cv_query->fetchrow_array();
    $self->set_cv_name($cv_name);
    $self->set_definition($definition);

}


sub store {
    my $self=shift;
    my $cv_id=$self->get_cv_id();
    if (!$cv_id) {
	my $query = "INSERT INTO cv (name, definition) VALUES (?,?)";
	my $sth=$self->get_dbh->prepare($query);
	$sth->execute($self->get_cv_name(), $self->get_definition() );
	$cv_id =  $self->get_currval("cv_cv_id_seq");
	$self->set_cv_id($cv_id);
    }
    return $cv_id;
}
    
=head2 Class properties

The following class properties have accessors:

  cv_id
  cv_name
  definition

=cut



sub get_cv_id {
  my $self=shift;
  return $self->{cv_id};

}

sub set_cv_id {
  my $self=shift;
  $self->{cv_id}=shift;
}

sub get_cv_name {
  my $self=shift;
  return $self->{cv_name};
}

sub set_cv_name {
  my $self=shift;
  $self->{cv_name}=shift;
}

sub get_definition {
  my $self=shift;
  return $self->{definition};
}

sub set_definition {
  my $self=shift;
  $self->{definition}=shift;
}



###
1;#do not remove
###
