=head1 NAME

CXGN::Chado::Organism - a class for accessing and inserting new organisms (the chado organism table, in public schema) into the database.

=head1 SYNOPSIS


=head1 DESCRIPTION

=head1 AUTHORS

 Naama Menda <nm249@cornell.edu>

=cut

use strict;
use warnings;

package CXGN::Chado::Organism;

use base qw /CXGN::Chado::Dbxref/;

=head2 new

 Usage:        my $feature = CXGN::Chado::Organism->new($dbh, $organism_id);
 Desc:
 Ret:    
 Args:         $dbh, $organism_id (the primary key of the organism table)
 Side Effects:
 Example:

=cut

sub new {
    my $class = shift;
    my $dbh= shift;
    my $id= shift;  
  
    my $args = {};  
    my $self = bless $args, $class;

    $self->set_dbh($dbh);
    $self->set_organism_id($id);
   
    if ($id) {
	$self->fetch();
    }
    
    return $self;
}


=head2 new_with_common_name

  Usage:        my $organism = CXGN::Chado::Organism->new_with_common_name($dbh, $common_name);
 Desc:          returns an organism object for the common name $common_name.
                note that some common names have several database entries. In that
                case, it returns the object for the first one listed.
 Ret:
 Args:
 Side Effects: accesses the database.
 Example:

=cut

sub new_with_common_name {
    my $class = shift;
    my $dbh = shift;
    my $common_name = shift;
    my $query = "SELECT organism_id FROM public.organism WHERE common_name ilike ?";
    my $sth = $dbh->prepare($query);
    $sth->execute($common_name);
    my ($organism_id) = $sth->fetchrow_array();
    my $self = CXGN::Chado::Organism->new($dbh, $organism_id);
    return $self;
	
}


=head2 fetch

 Usage:  $self->fetch();
 Desc:         populates the CXGN::Chado::Organism object from 
               the database.
 Ret:          nothing
 Args:         none
 Side Effects: accesses the database.
 Example:

=cut

sub fetch {
    my $self=shift;
    my $query = "SELECT abbreviation, genus, species, common_name, comment, genbank_taxon_id 
                 FROM public.organism WHERE organism_id=?";
    my $sth=$self->get_dbh()->prepare($query);
    $sth->execute($self->get_organism_id() );
       
    my ($abbreviation, $genus, $species, $common_name, $comment, $genbank_taxon_id)= $sth->fetchrow_array();
    
    $self->set_abbreviation($abbreviation);
    $self->set_genus($genus);
    $self->set_species($species);
    $self->set_common_name($common_name);
    $self->set_comment($comment);
    $self->set_genbank_taxon_id($genbank_taxon_id);
}

=head2 store

  Usage: $self->store();
 Desc:   stores an organism in public.organism table
 Ret:    $organism_id
 Args:   none
 Side Effects: none
 Example:

=cut

sub store {
    my $self=shift;
    my $organism_id = $self->get_organism_id();
    my $abbreviation = $self->get_abbreviation();
    my $genus= ucfirst( $self->get_genus() );
    my $species= $self->get_species();
    my $common_name= $self->get_common_name();
    my $comment= $self->get_comment();
    my $genbank_taxon_id= $self->get_genbank_taxon_id();
   
    if ($organism_id) {
	my $query = "UPDATE public.organism SET
                abbreviation=? ,genus=?, species=?, common_name=?, comment=?, genbank_taxon_id=?
                WHERE organism_id=?";
	my $sth= $self->get_dbh()->prepare($query);
	
	$sth->execute($abbreviation, $genus, $species, $common_name, $comment, $genbank_taxon_id, $organism_id);
	
    }else {
	my $query = "INSERT INTO public.organism 
                (abbreviation, genus, species, common_name, comment, genbank_taxon_id) 
                VALUES (?,?,?,?,?,?)";
	my $sth= $self->get_dbh()->prepare($query);
	$sth->execute($abbreviation, $genus, $species, $common_name, $comment, $genbank_taxon_id);
	$organism_id= $self->get_dbh()->last_insert_id('organism', 'public');
	$self->set_organism_id($organism_id);
    }
    return $organism_id;
}

=head2 delete

 Usage: $organism->delete()
 Desc:  hard delete of an organism from the database 
 Ret:   undef if succedded , $message if failed
 Args:  none
 Side Effects: checks if the organism has associated features with it.
  TODO: once we migrate to one public.organism table this check should be extended!!
 Example:

=cut

sub delete {
    my $self=shift;
    my $message=undef;
    my $organism = $self->get_abbreviation() ." (". $self->get_common_name() . ")";
    my $check = "SELECT COUNT(*) FROM public.feature WHERE organism_id=?";
    my $check_sth=$self->get_dbh()->prepare($check);
    $check_sth->execute($self->get_organism_id() );
    my $count= $check_sth->fetchrow_array();
    if ($count) { $message = "Cannot delete!! Found $count features associated with $organism"; }
    else {
	my $query = "DELETE FROM public.organism WHERE organism_id=?";
	my $sth=$self->get_dbh()->prepare($query);
	$sth->execute($self->get_organism_id() );
    }  
    return $message;
}


=head2 get_organism_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_organism_id {
  my $self=shift;
  return $self->{organism_id};

}

=head2 set_organism_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_organism_id {
  my $self=shift;
  $self->{organism_id}=shift;
}



=head2 accessors get_abbreviation, set_abbreviation

 Usage:        $o->set_abbreviation("S.lycopersicum");
 Desc:         sets the abbreviation for the organism
               
 Side Effects:
 Example:


=cut

sub get_abbreviation {
  my $self=shift;
  return $self->{abbreviation} || uc(substr($self->get_genus() ,0,1)) .".".$self->get_species();

}


sub set_abbreviation {
  my $self=shift;
  $self->{abbreviation}=shift;
}

=head2 accessors get_genus, set_genus

 Usage:        $o->set_genus("Solanum");
 Desc:         sets the genus of the organism
               
 Side Effects:
 Example:

=cut

sub get_genus {
  my $self=shift;
  return $self->{genus};

}

sub set_genus {
  my $self=shift;
  $self->{genus}=shift;
}

=head2 accessors get_species, set_species

 Usage:        $o->set_species("lycopersicum");
 Desc:         sets the species name of the organism
               
 Side Effects:
 Example:

=cut

sub get_species {
  my $self=shift;
  return $self->{species};

}


sub set_species {
  my $self=shift;
  $self->{species}=shift;
}


=head2 accessors get_common_name, set_common_name
 Usage:        $o->set_common_name("tomato");
 Desc:         sets the common name of the organism
               
 Side Effects:
 Example:

=cut
sub get_common_name {
  my $self=shift;
  return $self->{common_name};

}


sub set_common_name {
  my $self=shift;
  $self->{common_name}=shift;
}

=head2 accessors get_commnet, set_comment

 Usage:        $o->set_comment("this refers only to the cultivated tomato species");
 Desc:         sets the comment field in the organism table
               
 Side Effects:
 Example:

=cut
sub get_comment {
  my $self=shift;
  return $self->{comment};

}


sub set_comment {
  my $self=shift;
  $self->{comment}=shift;
}

=head2 accessors get_genbank_taxon_id, set_genbank_taxon_id

 Usage:        $o->set_genbank_taxon_id("4081");
 Desc:         sets the genbank taxon id of the organism.
               this ID has to be the correct taxon id from genbank, otherwise 
               uploading features of this organism (add_feaure.pl) will not work!
 Side Effects:
 Example:

=cut
sub get_genbank_taxon_id {
  my $self=shift;
  return $self->{genbank_taxon_id};

}


sub set_genbank_taxon_id {
  my $self=shift;
  $self->{genbank_taxon_id}=shift;
}

=head2 get_organism_by_species

 Usage: my $organism= CXGN::Chado::Organism::get_organism_by_species($species, $dbh)
 Desc:  finds an organism for a given species name
 Ret: an organism object (or undef if no organism is found)
 Args: species name and a dbh
 Side Effects:
 Example:

=cut

sub get_organism_by_species {
    my $species=shift;
    my $dbh=shift;
    my $query="SELECT organism_id FROM public.organism WHERE species=?";
    my $sth=$dbh->prepare($query);
    $sth->execute($species);
    my $organism_id= $sth->fetchrow_array();
    if ($organism_id) {
	my $organism= CXGN::Chado::Organism->new($dbh,$organism_id);
	$organism->set_organism_id($organism_id);
	return $organism;
    }else { return undef ; }
}



#### DO NOT REMOVE
return 1;
####
