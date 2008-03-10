
=head1 NAME

CXGN::Chado::Relationship - a class to deal with relationships between ontology terms.

=head1 DESCRIPTION

This class implements the interface defined in L<Bio::Ontology::RelationshipI>.

=head1 AUTHOR

Lukas Mueller <lam87@cornell.edu>

=head1 FUNCTIONS

This class implements the following functions:

=cut

use strict;

package CXGN::Chado::Relationship;

use CXGN::DB::Object;
use Bio::Ontology::RelationshipI;

use base qw | CXGN::DB::Object Bio::Ontology::RelationshipI |;

=head2 new

 Usage:        my $rel = CXGN::Chado::Relationship->new($dbh, $id)
 Desc:         creates a new relationship object
 Args:         a database handle and an id. If the id is omitted, 
               an empty object is created.
 Side Effects: accesses the database if an id is provided.
 Example:

=cut

sub new {
    my $class = shift;
    my $dbh = shift;
    my $id = shift;
    my $self = $class->SUPER::new($dbh);
    $self->identifier($id);
    $self->fetch();
    return $self;
}

=head2 identifier

 Usage:
 Desc:         setter/getter for unique id property.
               this maps to the cvterm_relationship_id in the
               database.
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub identifier {
    my $self = shift;
    my $id = shift;
    $self->{relationship_id} = $id if defined($id);
    return $self->{relationship_id};
}

=head2 subject_term

 Usage:        $rel->subject_term($subject_term)
 Desc:         setter/getter for subject term property
 Property:     A CXGN::Chado::Cvterm object
 Side Effects:
 Example:

=cut

sub subject_term {
    my $self = shift;
    my $term = shift;
    $self->{subject_term} = $term if defined($term);
    return $self->{subject_term};
}

=head2 object_term

 Usage:        my $object_term = $r->object_term()
 Desc:         setter/getter for the object_term property.
 Property:     the object of this relationship, a CXGN::Chado::Cvterm
               object.
 Side Effects:
 Example:

=cut

sub object_term {
    my $self = shift;
    my $term = shift;
    $self->{object_term} = $term if defined($term);
    return $self->{object_term};
}

=head2 predicate_term

 Usage:        my $predicate_term = $r->predicate_term();
 Desc:         setter/getter for the predicate term. This is just
               a fancy name for the relationship type.
 Property:     a predicate term object [CXGN::Chado::Cvterm]
 Side Effects: 
 Example:

=cut

sub predicate_term {
    my $self = shift;
    my $term = shift;
    $self->{predicate_term}=$term if defined($term);
    return $self->{predicate_term};
}

=head2 ontology

 Usage:        [not yet correctly implemented]
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub ontology {
    my $self = shift;
    my $ontology = shift;
    $self->{ontology} = $ontology if defined($ontology);
}

=head2 fetch

 Usage:        $r -> fetch();
 Desc:         fetches the relationship data from the database
 Ret:          nothing
 Args:         none, but requires identifier() to be set
 Side Effects: populates the object from the database
 Example:

=cut

sub fetch {
    my $self = shift;
    my $query = "SELECT subject_id, object_id, type_id FROM cvterm_relationship WHERE cvterm_relationship_id = ? ";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->identifier());
    my ($subject_id, $object_id, $predicate_id) = $sth->fetchrow_array();
    $self->subject_term(CXGN::Chado::Cvterm->new($self->get_dbh(), $subject_id));
    $self->object_term(CXGN::Chado::Cvterm->new($self->get_dbh(), $object_id));
    $self->predicate_term(CXGN::Chado::Cvterm->new($self->get_dbh(), $predicate_id));
		      
}



=head2 store

 Usage:        my $id = $r->store()
 Desc:         stores the object in the database. An insert 
               operation is performed if identifier() is not 
               defined, otherwise and update of that row is 
               performed.
 Ret:          the id of the database row
 Args:         none
 Side Effects: accesses and modifies the database.
 Example:

=cut

sub store {
    my $self = shift;
    if (!$self->identifier) {
	my $identifier = $self->exists();
	$self->identifier($identifier);
    }
    if ($self->identifier()) {
	print STDERR "Relationship.pm: identifier exists!\n";
	print STDERR "Updating relationship ".$self->identifier().".\n";
	my $query = "UPDATE cvterm_relationship SET 
                       subject_id = ?,
                       object_id = ?,
                       type_id = ?
                     WHERE cvterm_relationship_id=?";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute($self->subject_term()->get_cvterm_id(), $self->object_term()->get_cvterm_id(), $self->predicate_term()->get_cvterm_id());

	$self->subject_term()->store();
	$self->object_term()->store();
	$self->predicate_term()->store();

	return $self->identifier();
    }
    else { 
	print STDERR "Inserting new relationship...\n";
	my $query = "INSERT INTO cvterm_relationship (subject_id, object_id, type_id ) VALUES (?, ?, ?)";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute($self->subject_term()->get_cvterm_id(),
		      $self->object_term()->get_cvterm_id(),
		      $self->predicate_term()->get_cvterm_id()
		      );
	my $id = $self->get_currval("cvterm_relationship_cvterm_relationship_id_seq");
	$self->identifier($id);

	#print STDERR "New id = $id\n";

	return $self->identifier();
    }
    
}

=head2 exists

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub exists {
    my $self = shift;
    my $query = "SELECT cvterm_relationship_id FROM cvterm_relationship WHERE object_id =? AND subject_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->object_term->get_cvterm_id(), $self->subject_term()->get_cvterm_id());
    my ($id) = $sth->fetchrow_array();
    return $id;
}



=head2 delete

 Usage:        $r->delete();
 Desc:         hard deletes the relationship from the database.
               Can only be called if the relationship was stored,
               otherwise the method dies with a database error.
               Deleted relationships cannot be re-vived.
               Be careful with this one.
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub delete {
    my $self = shift;
    my $query = "DELETE FROM cvterm_relationship WHERE cvterm_relationship_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->identifier());
    $self = undef;
}




return 1;
