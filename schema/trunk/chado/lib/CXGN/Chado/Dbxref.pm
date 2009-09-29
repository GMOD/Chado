=head1 NAME

CXGN::Chado::Dbxref 
A class for handling dbxref terms

implements an object for the Chado 'dbxref' database table:

    Column    |          Type          |                           Modifiers
 -------------+------------------------+---------------------------------------------------------------
  dbxref_id   | integer                | not null default nextval('public.dbxref_dbxref_id_seq'::text)
  db_id       | integer                | not null
  accession   | character varying(255) | not null
  version     | character varying(255) | not null default ''::character varying
  description | text                   |

=head1 SYNOPSIS

for existing dbxrefs:

my $dbxref=CXGN::Chado::Dbxref->new($dbh, $dbxref_id); 
my $accession=$dbxref->get_accession();

for new dbxrefs:

my $dbxref=CXGN::Chado::Dbxref->new($dbh); 
$dbxref->set_db_name($db_name)
$dbxref->set_accession($accession);
my $dbxref_id=$dbxref->store();

=head1 AUTHOR

Naama Menda (nm249@cornell.edu)

=cut

use strict;

package CXGN::Chado::Dbxref;

use CXGN::Chado::Cvterm;
use CXGN::Chado::Publication;
use CXGN::Chado::Feature;
use CXGN::Chado::Db;

use base qw / CXGN::DB::Object /;


=head2 new

 Usage: my $dbxref = CXGN::Chado::Dbxref->new($dbh, $dbxref_id)
 Desc:  A new dbxref object  
 Ret:   a dbxref object
 Args: database handle and a dbxref_id (optional)
 Side Effects: none
 Example:

=cut

sub new {
    my $class = shift;
    my $dbh = shift;
    my $id = shift;
    my $self= $class->SUPER::new($dbh);

    if ($id) { 
	$self->set_dbxref_id($id);
	$self->fetch();
    }
    return $self;
}

=head2 new_with_accession

 Usage: my $dbxref = CXGN::Chado::Dbxref->new_with_accession($dbh, $accession, $db_id)
 Desc:  A new dbxref object  
 Ret:   a dbxref object
 Args: database handle, an accession, and a db_id
 Side Effects: none
 Example:

=cut

sub new_with_accession {
    my $class = shift;
    my $dbh = shift;
    my $accession = shift;
    my $db_id = shift;
    if (!($accession || $db_id)) { 
	die "Dbxref: new_with_accession: Need accession and db_id.\n";
    }
    my $query = "SELECT dbxref_id FROM dbxref where accession = ? and db_id=?";
    my $sth = $dbh->prepare($query);
    $sth->execute($accession, $db_id);
    my ($dbxref_id )=  $sth->fetchrow_array();
    my $self = $class->new($dbh, $dbxref_id);
    return $self;
}


sub fetch {
    my $self = shift;
    my $query = "SELECT db_id, db.name, urlprefix, url, accession, version, dbxref.description, 
                  cvterm_id, cvterm.name, cvterm.cv_id, cv.name
                  FROM public.db
                  JOIN public.dbxref USING(db_id)
                  LEFT OUTER JOIN cvterm ON (cvterm.dbxref_id=dbxref.dbxref_id)
                  LEFT JOIN cv ON (cv.cv_id=cvterm.cv_id)
                  WHERE dbxref.dbxref_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_dbxref_id());
    my ($db_id, $db_name, $urlprefix, $url, $accession, $version, $description, $cvterm_id, $cvterm_name, $cv_id, $cv_name) = $sth->fetchrow_array();

    $self->set_db_id($db_id);
    $self->set_db_name($db_name);
    $self->set_urlprefix($urlprefix);
    $self->set_url($url);
    $self->set_accession($accession);
    $self->set_version($version);
    $self->set_description($description);
    $self->set_cvterm_id($cvterm_id);
    $self->set_cvterm_name($cvterm_name);
    $self->set_cv_id($cv_id);
    $self->set_cv_name($cv_name);
}


=head2 store

 Usage: $self->store()
 Desc:  store a new dbxref
 Ret:   dbxref_id
 Args:  a valid db name, accession, version (optional), description (optional)  
 Side Effects: stores a new db if dows not exist in database
 Example:

=cut

sub store {
    my $self= shift;
    my $dbxref_id= $self->get_dbxref_id() ;
    if (!$dbxref_id) { #do an insert 
	if (!$self->db_exists() ) { # insert a new db 
	    $self->d( "***Dbxref.pm: storing a new db '".$self->get_db_name() ."'.\n");
	    my $db=CXGN::Chado::Db->new($self->get_dbh() );
	    $db->set_db_name($self->get_db_name() );
	    $db->store;
	    $self->set_db_id($db->get_db_id() );
	}else { 
	    my $q= "SELECT db_id FROM db WHERE db.name = ?";
	    my $s=$self->get_dbh()->prepare($q);
	    $s->execute($self->get_db_name() ) ;
	    my ($db_id)= $s->fetchrow_array();
	    $self->set_db_id($db_id);
	}
	my $existing_id= $self->exists_in_database();
	if (!$existing_id) {
	    #insert the new dbxref 
	    my $query = "INSERT INTO public.dbxref (db_id, accession, description, version) VALUES(?,?,?,?)";
	    my $sth= $self->get_dbh()->prepare($query);
	    if (!$self->get_version()) { $self->set_version(""); } #version field is not null
	    $sth->execute($self->get_db_id, $self->get_accession, $self->get_description, $self->get_version());
	    $dbxref_id=  $self->get_dbh()->last_insert_id("dbxref", "public");
	    $self->set_dbxref_id($dbxref_id);
	} else { $self->set_dbxref_id($existing_id); }
    }else {	 # do an update
	my $query = "UPDATE public.dbxref SET description=?, version=? WHERE dbxref_id=?";
	my $sth= $self->get_dbh()->prepare($query);
	$sth->execute($self->get_description(), $self->get_version(), $dbxref_id);
    }
    return $dbxref_id; 
}

=head2 exists_in_database

 Usage: $self->exists_in_database() 
 Desc:   check if the dbxref exists with the db_id, accession, and version
         prior to updating 
 Ret:    dbxref_id or undef if no dbxref exists
 Args:   non 
 Side Effects: none
 Example:

=cut

sub exists_in_database {
    my $self=shift;
    my $query="SELECT dbxref_id FROM public.dbxref WHERE db_id=? AND  accession=?";
    my $sth=$self->get_dbh()->prepare($query);
    $sth->execute($self->get_db_id(), $self->get_accession());
    my ($existing_id) = $sth->fetchrow_array();
    return $existing_id;
}


=head2 Class properties
The following class properties have accessors (get_dbxref_id, set_dbxref_id...):  

    dbxref_id
    db_id
    db_name
    urlprefix
    url
    accession
    version
    description
    cvterm_id
    cvterm_name
    cv_id
    cv_name

=cut

sub get_dbxref_id {
  my $self=shift;
  return $self->{dbxref_id};
}

sub set_dbxref_id {
  my $self=shift;
  $self->{dbxref_id}=shift;
}


sub get_db_id {
  my $self=shift;
  return $self->{db_id};
}


sub set_db_id {
  my $self=shift;
  $self->{db_id}=shift;
}


sub get_db_name {
  my $self=shift;
  return $self->{db_name};
}


sub set_db_name {
  my $self=shift;
  $self->{db_name}=shift;
}

sub get_urlprefix {
  my $self=shift;
  return $self->{urlprefix};
}


sub set_urlprefix {
  my $self=shift;
  $self->{urlprefix}=shift;
}


sub get_url {
  my $self=shift;
  return $self->{url};
}

sub set_url {
  my $self=shift;
  $self->{url}=shift;
}

sub get_accession {
  my $self=shift;
  return $self->{accession};
}


sub set_accession {
  my $self=shift;
  $self->{accession}=shift;
}

sub get_version {
  my $self=shift;
  return $self->{version};
}


sub set_version {
  my $self=shift;
  $self->{version}=shift;
}


sub get_description {
  my $self=shift;
  return $self->{description};
}

sub set_description {
  my $self=shift;
  $self->{description}=shift;
}


sub get_cvterm_id {
  my $self=shift;
  return $self->{cvterm_id};

}

sub set_cvterm_id {
  my $self=shift;
  $self->{cvterm_id}=shift;
}

sub get_cvterm_name {
  my $self=shift;
  return $self->{cvterm_name};
}


sub set_cvterm_name {
  my $self=shift;
  $self->{cvterm_name}=shift;
}

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

=head2 get_full_accession

 Usage: $self->get_full_accession()
 Desc:  Usse this accessor to find the full accession of your cvterm
        instead of concatenating db_name and accession (e.g. GO:0001234)
 Ret:   db_name:accession
 Args:   none
 Side Effects: none
 Example:

=cut

sub get_full_accession {
    my $self=shift;
    return $self->get_db_name() . ":" . $self->get_accession();
}


=head2 get_cvterm

 Usage:        my $cvterm = $self->get_cvterm()
 Desc:         get the cvterm object of a dbxref
 Ret:          cvterm object, or undef if there is no cvterm associated with the dbxref
 Args:         none 
 Side Effects: none
 Example:

=cut

sub get_cvterm {
    my $self=shift;
    my $cvterm_query = $self->get_dbh()->prepare("SELECT cvterm_id FROM cvterm WHERE dbxref_id= ?");
    my $cvterm2_query = $self->get_dbh()->prepare("SELECT distinct(cvterm_id) FROM cvterm_dbxref WHERE dbxref_id=?");

    #my $dbxref_id= $self->get_dbxref_id();
    my $dbxref_id= shift || $self->get_dbxref_id();
    $cvterm_query->execute($dbxref_id);
    my ($cvterm_id) = $cvterm_query->fetchrow_array();
    if (!$cvterm_id) {
	$cvterm2_query->execute($dbxref_id);
	my ($cvterm_id) = $cvterm2_query->fetchrow_array();
    }
    my $cvterm_obj= CXGN::Chado::Cvterm->new($self->get_dbh(), $cvterm_id);
    return ($cvterm_obj);
    
}




=head2 get_all_dbxref_types

 Usage: my (@names, @ids) = $self->get_all_dbxref_types()
 Desc:  selects all the db names and ids from chado db table
 Ret:   2 arrays: one with db names and second with db ids
 Args:
 Side Effects:
 Example:

=cut

sub get_all_dbxref_types {
    my $dbh = shift;
    my $query = "SELECT name, db_id FROM db";
    my $sth = $dbh->prepare($query);
    $sth->execute();
    my @namespace_names = ();
    my @namespace_ids = ();
    while (my ($name, $id) = $sth->fetchrow_array()) { 
	push @namespace_names, $name;
	push @namespace_ids , $id;
    }
    return (\@namespace_names, \@namespace_ids);
}
=head2 get_dbxref_id_by_accession

 Usage: CXGN::Chado::Dbxref::get_dbxref_id_by_accession($dbh,$accession, $db_name)
 Desc:  find the database id of an accession and a db_name
 Ret:   dbxref_id
 Args:  accession and a database db_name (from db table)
 Side Effects: none
 Example:

=cut
   

sub get_dbxref_id_by_accession {
    my $dbh=shift;
    my $accession = shift;
    my $db_name=shift;

    my $query = "SELECT dbxref_id
                  FROM public.dbxref
                  JOIN db USING (db_id)
                  WHERE accession=? AND db.name = ?" ;
    my $sth = $dbh->prepare($query);
    $sth->execute($accession, $db_name );
    my ($dbxref_id) = $sth->fetchrow_array();

    return $dbxref_id;
}
=head2 get_dbxref_id_by_accession

 Usage: CXGN::Chado::Dbxref::get_dbxref_id_by_db_id($dbh,$accession, $db_id)
 Desc:  find the database id of an accession and a db_id
 Ret:   dbxref_id
 Args:  accession and a database db_id (from db table)
 Side Effects: none
 Example:

=cut
   

sub get_dbxref_id_by_db_id {
    my $dbh=shift;
    my $accession = shift;
    my $db_id=shift;

    my $query = "SELECT dbxref_id
                  FROM dbxref
                  WHERE accession=? AND db_id = ?" ;
    my $sth = $dbh->prepare($query);
    $sth->execute($accession, $db_id );
    my ($dbxref_id) = $sth->fetchrow_array();

    return $dbxref_id;
}


=head2 get_publication

 Usage: $self->get-publication()
 Desc:  find the publication associated with the dbxref
 Ret: a publication object
 Args: none
 Side Effects:
 Example:

=cut

sub get_publication {
    my $self = shift;
    my $query = "SELECT pub_id
                  FROM public.pub
                  JOIN public.pub_dbxref USING (pub_id)
                  WHERE dbxref_id=? " ;
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_dbxref_id() );
    my ($pub_id) = $sth->fetchrow_array();
    my $pub_obj= CXGN::Chado::Publication->new($self->get_dbh(), $pub_id);
    
}

=head2 get_feature

 Usage: $dbxref->get_feature()
  Desc: get the feature object of this dbxref
 Ret:  a feature object. An empty object if no feature exists for the dbxref
 Args: none
 Side Effects:
 Example:

=cut

sub get_feature {
    my $self = shift;
    my $query = "SELECT feature_id
                  FROM public.feature
                  LEFT JOIN public.feature_dbxref USING (feature_id)
                  WHERE public.feature.dbxref_id=? ";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_dbxref_id());
    my ($feature_id) = $sth->fetchrow_array();
    my $feature_object = CXGN::Chado::Feature->new($self->get_dbh(), $feature_id);
    return $feature_object;
}

=head2 db_exists

 Usage: $dbxref->db_exists()
 Desc:  find if db_name exists in db table. Case insensitive.
 Ret:   1 if exists , undef if does not
 Args:  none
 Side Effects:  none
 Example:

=cut

sub db_exists {
    my $self=shift;
    my $query= "SELECT db_id FROM public.db WHERE name = ?";
    my $sth=$self->get_dbh()->prepare($query);
    $sth->execute($self->get_db_name());
    my ($db_id) = $sth->fetchrow_array();
    if ($db_id) { return 1; }
    else { return undef ; }
}

=head2 get_cvterm_dbxrefs

 Usage: $self->get_cvterm_dbxrefs
 Desc:  find the dbxrefs associated with a cvterm 
 Ret:   list of dbxref objects
 Args:   none
 Side Effects: none
 Example:

=cut

sub get_cvterm_dbxrefs {
    my $self=shift;
    my $query = "SELECT dbxref_id FROM cvterm_dbxref
                 WHERE cvterm_id=?";
    my $sth=$self->get_dbh()->prepare($query);
    $sth->execute($self->get_cvterm_id());
    
    my @dbxrefs;
    while (my ($id) = $sth->fetchrow_array() ){
	my $d=CXGN::Chado::Dbxref->new($self->get_dbh(),$id); 
	push @dbxrefs, $d;
    }
    return @dbxrefs ;
}



return 1;
