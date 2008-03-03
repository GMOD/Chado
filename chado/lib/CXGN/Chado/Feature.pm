=head1 NAME

CXGN::Chado::Feature - a class for accessing and inserting new sequences ("features" according to the chado schema) into the database.

=head1 SYNOPSIS

my $feature=CXGN::Chado::Feature->new($dbh, $feature_id)
my $f_name=$feature->get_name();
$f->set_name("new name for feature");
#update:
$f->store();


=head1 DESCRIPTION

The feature object deals with the Chado feature table and takes care of associated information, such as Dbxrefs.

The feature table has the following definition in the database:

 feature_id       | integer                     | not null default nextval('feature_feature_id_seq'::regclass)
 dbxref_id        | integer                     | 
 organism_id      | integer                     | not null
 name             | character varying(255)      | 
 uniquename       | text                        | not null
 residues         | text                        | 
 seqlen           | integer                     | 
 md5checksum      | character(32)               | 
 type_id          | integer                     | not null
 is_analysis      | boolean                     | not null default false
 is_obsolete      | boolean                     | not null default false
 timeaccessioned  | timestamp without time zone | not null default ('now'::text)::timestamp(6) with time zone
 timelastmodified | timestamp without time zone | not null default ('now'::text)::timestamp(6) with time zone

The featureloc table is defined as follows:

    Column      |   Type   |                             Modifiers                              
-----------------+----------+--------------------------------------------------------------------
 featureloc_id   | integer  | not null default nextval('featureloc_featureloc_id_seq'::regclass)
 feature_id      | integer  | not null
 srcfeature_id   | integer  | 
 fmin            | integer  | 
 is_fmin_partial | boolean  | not null default false
 fmax            | integer  | 
 is_fmax_partial | boolean  | not null default false
 strand          | smallint | 
 phase           | integer  | 
 residue_info    | text     | 
 locgroup        | integer  | not null default 0
 rank            | integer  | not null default 0
 
=head1 AUTHORS

 Tim Jacobs
 Naama Menda <nm249@cornell.edu>
 Lukas Mueller <lam87@cornell.edu>

=head1 METHODS

This class implements the following methods. Note that CXGN::Chado::Feature inherits from L<CXGN::Chado::Dbxref>, and thus inherits the useful functions set_name, set_description, etc from that class.

=cut

use strict;
use warnings;

package CXGN::Chado::Feature;

use base qw /CXGN::Chado::Dbxref/;

=head2 new

 Usage:        my $feature = CXGN::Chado::Feature->new($dbh, $feature_id);
 Desc:         a new feature object
 Ret:          a feature object
 Args:         $dbh, $feature_id (the primary key of the feature table)
 Side Effects:  sets dbh and feature_id (if given)
 Example:

=cut

sub new {
    my $class = shift;
    my $dbh= shift;
    my $id= shift; # the feature_id of the feature 
  
    my $args = {};  
    my $self = bless $args, $class;

    $self->set_dbh($dbh);
    $self->set_feature_id($id);
   
    if ($id) {
	$self->fetch();
	if (!$self->get_feature_id()) { return undef; }
    }

    return $self;
}

=head2 new_with_id

 Usage:        my @f = CXGN::Chado::Feature->new($dbh, $name);
 Desc:         returns all the features with the name $name
 Ret:          a list of CXGN::Chado::Feature objects
 Args:         a database handle and a feature name
 Side Effects: accesses the database.
 Example:

=cut

sub new_with_name {
    my $class = shift;
    my $dbh = shift;
    my $name = shift;
    my $query = "SELECT feature_id FROM feature WHERE name=?";
    my $sth = $dbh->prepare($query);
    $sth->execute($name);
    my @features = ();
    while (my ($feature_id) = $sth->fetchrow_array()) { 
	push @features, CXGN::Chado::Feature->new($dbh, $feature_id);
    }
    return @features;
    
}

=head2 new_with_accession

 Usage:        CXGN::Chado::Feature->new_with_accession($dbh, $accesion)
 Desc:         override this function of the superclass to ensure
               the entire feature object gets loaded.
 Ret:          a feature object
 Args:         a database handle and an accession
 Side Effects: none
 Example:

=cut

sub new_with_accession {
    my $class =shift;
    my $dbh = shift;
    my $accession = shift;

    my $query = "SELECT feature_id FROM feature join dbxref using(dbxref_id) WHERE accession ilike ?";
    my $sth = $dbh->prepare($query);
    $sth->execute($accession);
    my ($feature_id) = $sth->fetchrow_array();
    my $self = $class->new($dbh, $feature_id);
    return $self;

}



=head2 fetch

 Usage:        my $f->fetch()
 Desc:         populates the CXGN::Chado::Feature object from 
               the database.
 Ret:          nothing
 Args:         none
 Side Effects: accesses the database.

=cut

sub fetch {
    my $self=shift;

    my $feature_query = $self->get_dbh()->prepare(
			"SELECT feature_id, feature.name, uniquename, residues, seqlen, feature.dbxref_id, dbxref.accession, dbxref.description, cvterm.name, dbxref.version
                          FROM public.feature
                          LEFT JOIN public.feature_dbxref USING (feature_id) 
                          JOIN public.dbxref ON dbxref.dbxref_id = feature.dbxref_id
                          JOIN public.cvterm ON cvterm.cvterm_id= feature.type_id
                          WHERE feature_id=? "
						  );
    my $feature_id=$self->get_feature_id();
    $feature_query->execute($feature_id);

     
    my ($id, $name, $uniquename, $residues, $seqlen, $dbxref_id, $accession, $description, $molecule_type, $version)=
     $feature_query->fetchrow_array();
    $self->set_feature_id($id);
    $self->set_name($name);
    $self->set_uniquename($uniquename);
    $self->set_residues($residues);
    $self->set_seqlen($seqlen);
    $self->set_dbxref_id($dbxref_id);
    $self->set_accession($accession);
    $self->set_description($description);
    $self->set_molecule_type($molecule_type);
    $self->set_version($version);
}

=head2 store

 Usage:        $feature_object->store()
 Desc:         store a sequence (feature) object in chado feature module 
               call this function after setting the accession and the db_name!
               
 Ret:          database feature ID
 Args:         none
 Side Effects: stores the gi number (in the accessions column) in dbxref 
               (if it is not there already), the dbxref_id in the 
               linking table feature_dbxref (with the new feature_id)

=cut

sub store {
    
    my $self = shift;
   
    my $dbh = $self->get_dbh();

    my $dbxref_id=$self->get_dbxref_id(); 
    my $feature_id= $self->get_feature_id();
    
    if (!$dbxref_id) {
	#check if there is a dbxref id for the current accession:
	$dbxref_id= $self->get_dbxref_id_by_accession($self->get_accession, $self->get_db_name());
	$self->set_dbxref_id($dbxref_id);
    }
    
    eval{
	
        #If accession is not in dbxref do an insert (for Genbank DB:GenBank_GI is the database name)
	if (!$dbxref_id) {
	    my $dbxref= CXGN::Chado::Dbxref->new($dbh, $dbxref_id);	    
	    #The GI is used as the accession in the dbxref table. The accessions are stored in feature.name
	    $dbxref->set_db_name($self->get_db_name());
	    $dbxref->set_accession($self->get_accession());
	    $dbxref->set_description($self->get_description());
	    $dbxref->set_version($self->get_version());
	    
	    $dbxref_id=$dbxref->store();
	    $self->set_dbxref_id($dbxref_id);
	} else { 	#print STDERR "^^^ dbxref ID $dbxref_id already exists...\n"; 
	}
	
	####
	
	if (!$feature_id) {
	    #store new feature
	    my $query= "INSERT INTO feature (dbxref_id, organism_id, name, uniquename, residues, seqlen, type_id) VALUES (?,(SELECT organism_id FROM public.organism WHERE genbank_taxon_id = ?),?,?,?,?, (SELECT cvterm_id FROM cvterm WHERE name = ?))";
	    my $sth=$dbh->prepare($query);
	    $sth->execute($dbxref_id, $self->get_organism_taxon_id(), $self->get_name, $self->get_uniquename, $self->get_residues, $self->get_seqlen(), $self->get_molecule_type());
	    ####
	    $feature_id = $dbh->last_insert_id('feature', 'public');
	    $self->set_feature_id($feature_id);
	    
	    #this statement is for inserting into the feature_dbxref table 
	    my $feature_dbxref_query= "INSERT INTO feature_dbxref (feature_id, dbxref_id) VALUES (?, ?)";
	    my $feature_dbxref_sth=$dbh->prepare($feature_dbxref_query);
	    $feature_dbxref_sth->execute($feature_id, $dbxref_id);
	    #print STDERR "*** Inserting new feature feature_id=$feature_id dbxref ID= $dbxref_id\n";
	   

	    ####
	} else {
	    my $query= "UPDATE public.feature SET SET dbxref_id = ?, uniquename=?  where feature_id=?";
	    my $sth=$dbh->prepare($query);
	    
	    #do we really want to update features??
	    #$sth->execute($self->get_dbxref_id(), $self->get_uniquename(), $self->get_feature_id() );
	}

    };

    
    if($@) {
	die "Storing feature: An error occurred: $@";
    } 
    return $feature_id;


}#store
    

=head2 Class properties

The following class properties have accessors (get_feature_id, set_feature_id...): 

    feature_id
    db_name    sets/gets the name of the database that describes
               that feature. The database has to be listed in
               the public.db table.
    
    name      the name of the feature

    uniquename
    residues
    seqlen

    organism_taxon_id
    organism_name
    organism_id
=cut

    
sub get_db_name {
    my $self=shift;
    return $self->{db_name};
}

sub set_db_name {
    my $self=shift;
    $self->{db_name}=shift;
}

sub get_organism_taxon_id {
  my $self=shift;
  return $self->{organism_taxon_id};
}

sub set_organism_taxon_id {
  my $self=shift;
  $self->{organism_taxon_id}=shift;
}

sub get_organism_name {
  my $self=shift;
  return $self->{organism_name};

}

sub set_organism_name {
  my $self=shift;
  $self->{organism_name}=shift;
}

sub get_organism_id {
    my $self=shift;
    return $self->{organism_id};
}

sub set_organism_id {
    my $self=shift;
    $self->{organism_id}=shift;
}

sub get_name {
    my $self=shift;
    return $self->{name};
}

sub set_name {
    my $self=shift;
    $self->{name}=shift;
}


sub get_uniquename {
    my $self=shift;
    return $self->{uniquename};
}

sub set_uniquename {
    my $self=shift;
    $self->{uniquename}=shift;
}

sub get_residues {
    my $self=shift;
    return $self->{residues};
}

sub set_residues {
    my $self=shift;
    $self->{residues}=shift;
}

=head2 function add_pubmed_id

 Usage: $self->add_pubmed_id($pubmed_id)
 Desc:  add a pubmed reference annotation to a feature
 Ret:   nothing
 Args:  pubmed id
 Side Effects: none
 Example:

=cut

sub add_pubmed_id {
    my $self=shift;
    my $pubmed_id = shift;
    push @{ $self->{pubmed_ids} }, $pubmed_id;
}

=head2 get_pubmed_ids

 Usage: $self->get_pubmed_ids
 Desc:  an accessor for associated pubmed ids
 Ret:  an array of pubmed ids, or undef if none exist
 Args:  none
 Side Effects: none
 Example:

=cut

sub get_pubmed_ids {
    my $self=shift;
    if($self->{pubmed_ids}){
	return @{$self->{pubmed_ids}};
    }
    return undef;
}

=head2 set_pubmed_ids

 Usage:        $f->set_pubmed_ids($id1, $id2, $id3);
 Desc:         adds the list to the list of pubmed ids.
 Side Effects:
 Example:

=cut

sub set_pubmed_ids {
    my $self=shift;
    @{$self->{pubmed_ids}} = @_;
}

=head2 add_name

 Usage:        THIS FUNCTION DOES NOT SEEM TO BE USED.
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub add_name {
    my $self=shift;
    my $GBaccession = shift; 
    push @{ $self->{names} }, $GBaccession;
}

=head2 add_accession

Usage:  $f->add_accession
Desc:   add an accession (typically from genbank) to this feature   
Ret:    nothing
Args:   an accession
Side Effects: none
Example:

=cut

sub add_accession {
    my $self=shift;
    my $gi_accession = shift; 
    push @{ $self->{accessions} }, $gi_accession;
}

=head2 get_accessions

Usage:  $f->get_accessions
Desc:   get the accessions associated with this feature (typically from genbank)  
Ret:    an array of accessions or undef if none exist
Args:   none
Side Effects: none
Example:

=cut

sub get_accessions {
    my $self=shift;
    if($self->{accessions}){
	return @{$self->{accessions}};
    }
    return undef;
}


sub get_seqlen {
    my $self=shift;
    if (exists($self->{seqlen}) && defined($self->{seqlen})) { 
	return $self->{seqlen};
    }
    else { 
	return length($self->get_residues()); 
    }
}

sub set_seqlen {
    my $self=shift;
    $self->{seqlen}=shift;
}


=head2 accessors get_molecule_type, set_molecule_type

 Usage:        $f->set_molecule_type("mRNA")
 Property:     a molecule type, as specified by the 
               sequence ontology feature annotation controlled
               vocabulary. See www.sequenceontology.org.
 Side Effects:
 Example:

=cut

sub get_molecule_type {
  my $self=shift;
  return $self->{molecule_type};

}

sub set_molecule_type {
  my $self=shift;
  $self->{molecule_type}=shift;
}


sub get_feature_id {
  my $self=shift;
  return $self->{feature_id};
}

sub set_feature_id {
  my $self=shift;
  $self->{feature_id}=shift;
}

=head2 get_feature_by_uniquename

 Usage:        $self->get_feature_by_uniquename($name, $dbh)
 Desc:         check if a feature is already stored in the database
               the check is performed by using the 'uniquename' 
               field which has the format : 'accession:version'
 Ret:          $feature_id: a database id
 Args: none
 Side Effects:
 Example: 

=cut

sub get_feature_by_uniquename {
    my $self=shift;
    my $uniquename=shift;
   
   # print STDERR "uniquename: $uniquename\n";
    
    my $query = "SELECT feature_id FROM public.feature WHERE uniquename=? " ;
    my $sth = $self->get_dbh->prepare($query);
    #print STDERR "uniquename: $uniquename\n";
    
    $sth->execute($uniquename);
    my $feature_id = $sth->fetchrow_array();
   # print STDERR "uniquename: $uniquename, feature_id: $feature_id\n";
    if ($feature_id) {    return $feature_id; }
    else {return undef ; }
}

=head2 function feature_exists

 Usage:        if ($f->feature_exists()) { #do something
 Desc:         checks if the feature defined by $f
               already exists in the database. The check
               is done on the accession property.
 Ret:          the ID of the feature if it exists.
 Args:
 Side Effects:
 Example:

=cut

sub feature_exists {
    my $self = shift;
    my $query = "SELECT feature_id
                  FROM public.feature
                 
                  WHERE  feature.name ilike ?" ;
    my $sth = $self->get_dbh()->prepare($query);
    my $check= $self->get_accession();
    #print STDERR  "**Feature.pm found accession: $check!?\n ";

    if (!$check) { 
	$check= $self->get_name(); 
	#print STDERR  "**Feature.pm found name: $check!";
    }
    
    $sth->execute($check );
    my $feature_id = $sth->fetchrow_array();
    #$self->set_feature_id($feature_id);
    
    return $feature_id;
}

=head2 get_dbxref_id_by_accession

 Usage:
 Desc:          Overloading the same method in Dbxref due to a change 
                in function names from publications: 'get_name()' 
                is needed by the chado schema to be the accessions. 
                Therefore a seperate 'get_db_name' function is needed.
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_dbxref_id_by_accession {
    my $self = shift;
    my $query = "SELECT dbxref_id
                  FROM public.dbxref
                  JOIN db USING (db_id)
                  WHERE accession=? AND db.name= ?" ;
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_accession(), $self->get_db_name() );
    my $dbxref_id = $sth->fetchrow_array();

    return $dbxref_id;
}

=head2 get_feature_name_by_gi

 Usage:        $self->CXGN::Chado::Feature::get_feature_name_by_gi($gi_number)
 Desc:         find the name (should be genBank accession number) of some genBank GI number
 Ret:          genBank accession number
 Args:         $gi_number
 Side Effects:
 Example: 

=cut

sub get_feature_name_by_gi {
    my $self = shift;
    my $gi_accession=shift;
    my $query = "SELECT feature.name
                  FROM public.feature
                  JOIN public.dbxref USING (dbxref_id)
                  WHERE accession=? " ;
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($gi_accession );
    my $name = $sth->fetchrow_array();

    return $name;
}

=head2 associated_loci

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub associated_loci {
    my $self=shift;
    my $query = $self->get_dbh()->prepare("SELECT locus_id FROM phenome.locus_dbxref
                                          
                                           JOIN public.feature USING (dbxref_id)
                                           LEFT JOIN public.feature_dbxref USING (dbxref_id)
                                           WHERE feature.name= ?");
    $query->execute($self->get_name());
    my @loci;
    while (my $locus_id= $query->fetchrow_array()) {
	my $locus = CXGN::Phenome::Locus->new($self->get_dbh(), $locus_id);
	push @loci, $locus;
    }
    return @loci;
}

=head2 add_feature_location

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub add_feature_location {
    my $self = shift;
    my $parent_feature_name = shift;
    my $start = shift;
    my $end = shift;
    
    my $parent_q = "SELECT ";

}

=head2 add_secondary_dbxref

 Usage:        $f->add_dbxref($dbxref_id)
 Desc:         associates the dbxref with id $dbxref_id
               with this feature.
 Side Effects: $dbxref_id must exist in the database. 
               dbxref entries can be easily generated using
               CXGN::Chado::Dbxref. Inserts a row into the
               feature_dbxref table.
 Example:

=cut

sub add_secondary_dbxref {
    my $self = shift;
    my $dbxref_id = shift;
    my $query = "INSERT INTO feature_dbxref (dbxref_id, feature_id) VALUES (?, ?)";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($dbxref_id, $self->get_feature_id());
    
}

=head2 get_secondary_dbxrefs

 Usage:        my @dbxrefs = $f->get_dbxrefs();
 Desc:         returns the secondary dbxrefs associated
               with this feature (from the feature_dbxref
               table).
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_secondary_dbxrefs {
    my $self = shift;
    my $query = "SELECT dbxref_id FROM feature_dbxref WHERE feature_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_feature_id());
    my @dbxrefs = ();
    while (my ($dbxref_id) = $sth->fetchrow_array()) { 
	push @dbxrefs, CXGN::Chado::Dbxref->new($self->get_dbh(), $dbxref_id);
    }
    return @dbxrefs;
}

=head2 function add_feature_relationship

 Usage:        $f->add_feature_relationship($another_feature_id, $relationship_type);
 Desc:         adds a feature relationship of type $relationship_type
               [string] as defined by the relatioship ontology (currently
               defined relationship terms are: is_a, part_of, member_of, etc.
               if the feature_id or the relationship type does not 
               exist, the function dies.
 Args:         $feature_id [int], $relationship_type [string]
 Side Effects: accesses and modifies the database
 Example:

=cut

sub add_feature_relationship {
    my $self = shift;
    my $other_feature_id = shift;
    my $relationship_type = shift;
    my $value = shift;

    # get the cvterm_id of the relationship type
    my $rtq = "SELECT cvterm.cvterm_id FROM cvterm WHERE name=? and is_relationshiptype=1";
    my $rth = $self->get_dbh()->prepare($rtq);
    $rth->execute($relationship_type);
    
    my ($rt_id) = $rth->fetchrow_array();
    if (!$rt_id) { 
	die "The relationship type $relationship_type does not exist in the database.";
    }

    

    my $f = CXGN::Chado::Feature->new($self->get_dbh(), $other_feature_id);
    if (!$f->get_feature_id()) { 
	die "Feature with id $other_feature_id does not exist in the database";
    }
    
    my $query = "INSERT INTO feature_relationship (type_id, subject_id, object_id, value) VALUES (?, ?, ?, ?)";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($rt_id, $self->get_feature_id(), $other_feature_id, $value);
    

}

=head2 get_subject_feature_relationships

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_subject_feature_relationships {
    my $self = shift;
    my $query = "SELECT object_id, type_id FROM feature_relationship WHERE subject_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_feature_id());
    my @features = ();
    while (my ($object_id) = $sth->fetchrow_array()) {
	push @features, CXGN::Chado::Feature->new($self->get_dbh(), $object_id);
    }
    return @features;
} 

=head2 get_object_feature_relationships

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_object_feature_relationships {
    my $self = shift;
    my $query = "SELECT subject_id, type_id FROM feature_relationship WHERE object_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_feature_id());
    my @features = ();
    while (my ($subject_id) = $sth->fetchrow_array()) {
	push @features, CXGN::Chado::Feature->new($self->get_dbh(), $subject_id);
    }
    return @features;
}

=head2 associate_cvterm

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub associate_cvterm {
    my $self = shift;
    my $cvterm = shift;
    my $pub = shift;
    my $is_not = shift;

    $self->associate_cvterm_id($cvterm->get_cvterm_id(), $pub->get_pub_id(), $is_not);

}

=head2 associate_cvterm_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub associate_cvterm_id {
    my $self = shift;
    my $cvterm_id = shift;
    my $pub_id = shift;
    my $is_not = shift;

    my $query = "INSERT INTO feature_cvterm (feature_id, cvterm_id, pub_id, is_not) VALUES (?, ?, ?, ?)";
    my $sth =  $self->get_dbh()->prepare($query);
    
    $sth->execute($self->get_feature_id(), $cvterm_id, $pub_id, $is_not);
    
    
}

=head2 get_associated_cvterms

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_associated_cvterms {
    my $self = shift;
    my @cvterm_ids = $self->get_associated_cvterm_ids();
    my @cvterms = ();
    foreach my $t_id (@cvterm_ids) { 
	push @cvterms, $t_id;
    }
    return @cvterms;
}



=head2 get_associated_cvterm_ids

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_associated_cvterm_ids {
    my $self = shift;
    my $query = "SELECT cvterm_id FROM feature_cvterm WHERE feature_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_feature_id());
    my @cvterm_ids = ();
    while (my ($cv_term) = $sth->fetchrow_array()) { 
	push @cvterm_ids, $cv_term;
    }
    return @cvterm_ids;
}




#### DO NOT REMOVE
return 1;
####
