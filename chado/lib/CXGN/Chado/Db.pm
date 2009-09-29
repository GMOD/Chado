=head1 NAME

CXGN::Chado::Db - a class to handle Db terms.

implements an object for the Chado 'db' database table:

  Column    |          Type          |                       Modifiers
  db_id       | integer                | not null default nextval('public.db_db_id_seq'::text)
  name        | character varying(255) | not null
  description | character varying(255) |
  urlprefix   | character varying(255) |
  url         | character varying(255) |


=head1 SYNOPSIS

my $db=CXGN::Chado::Db->new($dbh, $db_id);
my $db_name= $db->get_db_name();

#do an update:
$db->set_description("new description for SGN db");
$db->store();

 
#OR store a new db :
my $db=CXGN::Chado::Db->new($dbh);
$db->set_db_name($db_name);
$db->set_urlprefix($prefix);
$db->set_url($url);
my $db_id=$db->store();
 

=head1 AUTHOR

 Naama Menda <nm249@cornell.edu>
 Lukas Mueller <lam87@cornell.edu> (added implementation of Bio::Ontology::TermI)

=cut
use strict;

package CXGN::Chado::Db;

use base qw / CXGN::DB::Object /;


=head2 new

 Usage: CXGN::Chado::Db->new($dbh, $id)
 Desc:  a new Db object
 Ret:   Db object
 Args:  a database handle, a database db_id (optional)
 Side Effects: none
 Example:

=cut

sub new {
    my $class = shift;
    my $dbh = shift;
    my $id = shift;
    my $self= $class->SUPER::new($dbh);

    if ($id) { 
	$self->set_db_id($id);
	$self->fetch();
    }
    return $self;
}

=head2 new_with_name

 Usage:        my $db = CXGN::Chado::Db->new_with_name($dbh, "GO");
 Desc:         an alternate constructor that takes a db name as parameter
               db name is case insensitive, but if more than one is found 
               only one db_id is returned + a warning.
 Side Effects: accesses the database.
 Example:

=cut

sub new_with_name {
    my $class = shift;
    my $dbh = shift;
    my $name = shift;

    my $query = "SELECT db_id FROM db WHERE name ilike ?";
    my $sth = $dbh->prepare($query);
    $sth->execute($name);
    my @ids=();
    while (my ($id) = $sth->fetchrow_array()) {
	push @ids, $id;	
    }
    if (scalar(@ids) > 1 ) { warn "Db.pm: new with name found more than one db with iname $name! Please check your databse."; }
    my $db_id= $ids[0] || undef; #return only the 1st id
    my $self = CXGN::Chado::Db->new($dbh, $db_id);
    return $self;
}




sub fetch {
    my $self = shift;
    my $query = "SELECT name, description, urlprefix, url
                   FROM db 
                  WHERE db_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_db_id());
    my ($name, $description, $urlprefix, $url) = 
	$sth->fetchrow_array();
    
    $self->set_db_name($name);
    $self->set_description($description);
    $self->set_urlprefix($urlprefix);
    $self->set_url($url);
}

=head2 store

 Usage: $db->store()
 Desc:   store a new db in the database (update if db_id exists) 
 Ret:   a database id (db_id)
 Args:  none 
 Side Effects: accesses the database
 Example:  

=cut


sub store {
    my $self= shift;
    my $db_id= $self->get_db_id();
    if (!$db_id) {
	
	my $query = "INSERT INTO public.db (name, description, urlprefix,url) VALUES(?,?,?,?)";
	my $sth= $self->get_dbh()->prepare($query);
	print STDERR "Db.pm: storing * " . $self->get_db_name() . "\n\n";
	$sth->execute($self->get_db_name, $self->get_description, $self->get_urlprefix, $self->get_url());
	$db_id=  $self->get_dbh()->last_insert_id("db", "public");
	$self->set_db_id($db_id);
    }else {	
	my $query = "UPDATE public.db SET description=?, urlprefix=? , url=? WHERE db_id=?";
	my $sth= $self->get_dbh()->prepare($query);
	$sth->execute($self->get_description(), $self->get_urlprefix(),$self->get_url(), $db_id);
    }
    return $db_id; 
}

=head2 Class properties
    
The following class properties have accessors (get_db_id, set_db_id...): 
    
    db_id
    db_name
    description
    urlprefix
    url

=cut


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


sub get_description {
  my $self=shift;
  return $self->{description};
}

sub set_description {
  my $self=shift;
  $self->{description}=shift;
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



return 1;
