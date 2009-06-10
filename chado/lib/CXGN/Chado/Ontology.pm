

=head1 NAME

CXGN::Chado::Ontology - a class that implements the Bio::Ontology::OntologyI interface for the ontologies stored in the SGN database

=head1 DESCRIPTION

This class implements the interface given in L<Bio::Ontology::OntologyI>. Refer to its documentation for most of the functions given below. 

In addition, this class adds some utility functions and accessors that are more in-line with SGN usage.

=head1 AUTHOR

Lukas Mueller <lam87@cornell.edu>

=head1 DATE

December 2007

=cut

use strict;

package CXGN::Chado::Ontology;

use Bio::Ontology::OntologyI;
use CXGN::DB::Object;

use base qw | CXGN::DB::Object |;
#use base qw | Bio::Ontology::OntologyI CXGN::DB::Object |;


=head2 new

 Usage:        my $ont = CXGN::Chado::Ontology->new($dbh, $id)
 Desc:         Constructor for an ontology object
 Args:         a $dbh handle and an ontology id.
 Side Effects: accesses the database if an $id is provided.
 Example:

=cut

sub new {
    my $class = shift;
    my $dbh = shift;
    my $id = shift;
    my $self = $class->SUPER::new($dbh);
    if ($id) { 
	$self->identifier($id);
	$self->fetch();
    }
    
    return $self;
}

=head2 new_with_name

 Usage:        my $ont = CXGN::Chado::Ontology->new($dbh, $name)
 Desc:         alternate constructor that generates an ontology
               object from its name $name.
 Args:         a database handle and a name.
 Side Effects: accesses the database
 Example:

=cut

sub new_with_name {
    my $class = shift;
    my $dbh = shift;
    my $name = shift;
    my $query = "SELECT cv.cv_id FROM cv WHERE name ilike ?";
    my $sth = $dbh->prepare($query);
    $sth->execute($name);
    my ($id) = $sth->fetchrow_array();
    my $self = CXGN::Chado::Ontology->new($dbh, $id);
    return $self;
}

=head2 fetch

 Usage:        $ont->fetch()
 Desc:         fetches the object contents from the database.
 Side Effects: accesses the database.
 Example:

=cut

sub fetch {
    my $self = shift;
    my $query = "SELECT cv_id, name, definition FROM cv WHERE cv_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_cv_id());
    my ($cv_id, $name, $definition) = $sth->fetchrow_array();
    $self->identifier($cv_id);
    $self->name($name);
    $self->definition($definition);

}

=head2 store

 Usage:        my $id = $ont->store()
 Desc:         stores the object contents to the database.
               if the object already has an id, an update is 
               performed, otherwise an insert is performed.
 Ret:          the id of the primary key is returned.
 Args:         none
 Side Effects: accesses the database. May set the ontology_id
               property if the row did not exist in the database.
 Example:

=cut

    
sub store {
    my $self = shift;
    if ($self->identifier()) { 
	my $query = "UPDATE cv set name=?, definition=? WHERE cv_id=?";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute($self->name(),$self->definition(),  $self->identifier());	
	return $self->identifier();

    }
    else { 
	my $query = "INSERT INTO cv (name, definition) VALUES (?, ?)"; 
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute($self->name(), $self->definition());
	my $id = $self->get_currval("cv_cv_id_seq");
	$self->identifier($id);
	return $id;
    }

}

=head2 accessors get_cv_id, set_cv_id

 Usage:        $ont->get_cv_id()
 Desc:         the primary key of the ontology object.
               the setter should not be used mindlessly.
 Side Effects:
 Example:

=cut

sub get_cv_id {
  my $self = shift;
  return $self->{cv_id}; 
}

sub set_cv_id {
  my $self = shift;
  $self->{cv_id} = shift;
}


=head2 name

 Usage:        my $name = $ont->name()
 Desc:         getter/setter of the ontology name.
 Ret:
 Args:
 Note:         this function is specified in the 
               L<Bio::Ontology::OntologyI> interface
 Example:

=cut

sub name {
    my $self = shift;
    my $name = shift;
    $self->{name}=$name if $name;
    return $self->{name};
}

=head2 identifier

 Usage:        my $id = $ont->identifier()
 Desc:         getter/setter of the ontology id.
               this is a synonym for get_cv_id.
 Ret:
 Args:
 Note:         this function is specified in the 
               L<Bio::Ontology::OntologyI> interface
 Example:

=cut

sub identifier {
    my $self = shift;
    my $identifier = shift;
    $self->set_cv_id($identifier) if defined($identifier);
    return $self->get_cv_id();
}

=head2 definition

 Usage:        my $def = $ont->definition()
 Desc:         getter/setter of the definition property
 Property:     [string]
 Note:         this function is specified in the 
               L<Bio::Ontology::OntologyI> interface
 Example:

=cut

sub definition {
    my $self = shift;
    my $definition = shift;
    $self->{definition}=$definition if defined($definition);
    return $self->{definition};
}






=head2 get_root_terms

 Usage:        my @terms = $ont->get_root_terms()
 Desc:
 Ret:
 Args:
 Side Effects:
 Note:         this function is specified in the 
               L<Bio::Ontology::OntologyI> interface
 Example:

=cut

sub get_root_terms {
    my $self = shift;
    my $query = "SELECT cvterm_id FROM cvterm JOIN cvterm_relationship ON (cvterm_id=object_id) WHERE object_id IS NULL AND cv_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_cv_id());
    my @terms = ();
    while (my ($cvterm_id) = $sth->fetchrow_array()) { 
	push @terms, CXGN::Chado::Cvterm->new($self->get_dbh(), $cvterm_id);
    }
    return @terms;
}

=head2 get_leaf_terms

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Note:         this function is specified in the 
               L<Bio::Ontology::OntologyI> interface
 Example:

=cut

sub get_leaf_terms {
    my $self = shift;
    my $query = "SELECT cvterm_id FROM cvterm JOIN cvterm_relationship ON (cvterm_id=subject_id) WHERE subject_id IS NULL AND cv_id=?";
my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_cv_id());
    my @terms = ();
    while (my ($cvterm_id) = $sth->fetchrow_array()) { 
	push @terms, CXGN::Chado::Cvterm->new($self->get_dbh(), $cvterm_id);
    }
    return @terms;
    
}

=head2 get_all_terms

 Usage:     $self->get_all_terms()
 Desc:            
 Ret:       a list of Cvterm objects
 Args:      none
 Side Effects:
 Note:         this function is specified in the 
               L<Bio::Ontology::OntologyI> interface
 Example:

=cut

sub get_all_terms {
    my $self = shift;
    my $query = "SELECT cvterm_id FROM cvterm  WHERE  cv_id=? AND is_relationshiptype=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->identifier(), 0);
    my @terms = ();
    while (my ($cvterm_id) = $sth->fetchrow_array()) { 
	push @terms, CXGN::Chado::Cvterm->new($self->get_dbh(), $cvterm_id);
    }
    return @terms;
}


=head2 get_predicate_terms

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Note:         this function is specified in the 
               L<Bio::Ontology::OntologyI> interface
 Example:

=cut

sub get_predicate_terms {
    my $self = shift;
    my $query = "SELECT cvterm_id FROM cvterm  WHERE  cv_id=? AND is_relationshiptype=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->identifier(), 1);
    my @terms = ();
    while (my ($cvterm_id) = $sth->fetchrow_array()) { 
	push @terms, CXGN::Chado::Cvterm->new($self->get_dbh(), $cvterm_id);
    }
    return @terms;
}


=head2 get_ancestor_terms

 Usage:        [NOT YET IMPLEMENTED]
 Desc:
 Ret:
 Args:
 Side Effects:
 Note:         this function is specified in the 
               L<Bio::Ontology::OntologyI> interface
 Example:

=cut

sub get_ancestor_terms {

}

=head2 get_parent_terms

 Usage:        my @parents = $ont->get_parent_terms($term, $rel_type)
 Desc:
 Ret:
 Args:         a CXGN::Chado::Cvterm object, and a 
               CXGN::Chado::Cvterm specifying the relation-
               ship type.
 Side Effects:
 Note:         this function is specified in the 
               L<Bio::Ontology::OntologyI> interface
 Example:

=cut

sub get_parent_terms {
    my $self = shift;
    my $term = shift;
    my @rel_types = @_;

    my @rel_type_ids = ();
    my $rel_type_clause = "";
    if (@rel_types) { 
	my @rel_type_ids = map { $->identifier() } @rel_types;
	$rel_type_clause = " AND ( ".(join ", ", @rel_type_ids).") ";
    }
    

    my $parents_sth = $self->get_dbh()->prepare("SELECT cvterm_relationship.object_id, cvterm_relationship.type_id, cvterm.name FROM cvterm_relationship join cvterm ON cvterm.cvterm_id=cvterm_relationship.object_id left join cvtermsynonym on cvtermsynonym.synonym=cvterm.name WHERE cvterm_relationship.subject_id= ? and cvtermsynonym.synonym is null and cvterm.is_obsolete = 0 $rel_type_clause order by cvterm.name asc");
    $parents_sth->execute($self->identifier());
    my @parents = ();
    while (my ($parent_term_id, $type_id) = $parents_sth->fetchrow_array()) { 
	my $parent_term = CXGN::Chado::Cvterm->new($self->get_dbh(), $parent_term_id);
	push @parents, $parent_term;
    }
    return (@parents);
    
}

=head2 get_child_terms

 Usage:        @children = $ontology->get_child_terms($term, @term_rels)
 Ret:          returns a list of terms that are direct descendants of 
               term $term.
 Args:         a Bio::Ontolog::TermI object describing the term
               a list of BIo::Ontology::TermI relationship type terms
 Side Effects: accesses the database
 Example:

=cut

sub get_child_terms {
    my $self=shift;
    my $term = shift;
    my @rel_types = @_;
    
    my @rel_type_ids = ();
    my $rel_type_clause = "";
    if (@rel_types) { 
	my @rel_type_ids = map { $->identifier() } @rel_types;
	$rel_type_clause = " AND ( ".(join ", ", @rel_type_ids).") ";
    }

    my $children_sth = $self->get_dbh()->prepare("SELECT cvterm_relationship.subject_id, cvterm_relationship.type_id, cvterm.name FROM cvterm_relationship join cvterm ON cvterm.cvterm_id=cvterm_relationship.subject_id left join cvtermsynonym on cvtermsynonym.synonym=cvterm.name WHERE cvterm_relationship.object_id= ? and cvtermsynonym.synonym is null and cvterm.is_obsolete = 0 $rel_type_clause order by cvterm.name asc");
    $children_sth->execute($term->identifier());
    my @children = ();
    while (my ($child_term_id, $type_id) = $children_sth->fetchrow_array()) { 
	print STDERR "retrieved child $child_term_id, $type_id\n";
	my $child_term = CXGN::Chado::Cvterm->new($self->get_dbh(), $child_term_id);
	#my $relationship_term = CXGN::Chado::Cvterm->new($self->get_dbh(), $type_id);
	
	push @children,  $child_term;
    }
    return (@children);

}

=head2 get_descendant_terms

 Usage:        [NOT YET IMPLEMENTED]
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_descendant_terms {
    
}

=head2 add_relationship

 Usage:
 Desc:         [NOT YET IMPLEMENTED]
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub add_relationship {
    
}

=head2 get_relationships

 Usage:        @terms = $ont->get_relationships($term)
 Desc:         gets all the relationships of term $term
 Ret:          a list of CXGN::Chado::Relationship objects
 Args:         a CXGN::Chado::Cvterm object.
 Side Effects: accesses the database.
 
 Example:

=cut

sub get_relationships {
    my $self = shift;
    my $term = shift;
    my $query = "SELECT cvterm_relationship_id FROM public.cvterm_relationship WHERE subject_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($term->get_cvterm_id());
    my @relationships = ();
    while (my($id)=$sth->fetchrow_array()) { 
	push @relationships, CXGN::Chado::Relationship->new($self->get_dbh(), $id);
    }
    return @relationships;
}


=head2 add_term

 Usage:        
 Desc:         [NOT YET IMPLEMENTED]
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub add_term {

}

=head2 find_terms

 Usage:
 Desc:         [NOT YET IMPLEMENTED]
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub find_terms {
    my $self = shift;
}



return 1;
