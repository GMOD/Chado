package CXGN::Tools::Organism;
use strict;
use warnings;

=head1 NAME

Functions for accessing ogranism names and their identifiers

=head1 SYNOPSIS


=head1 DESCRIPTION
 

=cut


=head2 get_all_organisms

 Usage:        my ($names_ref, $ids_ref) = CXGN::Tools::Organism::get_all_organisms($dbh);
 Desc:         This is a static function. Retrieves distinct organism names and IDs from phenome.locus
 Ret:          Returns two arrayrefs. One array contains all the
               organism names, and the other all the organism ids
               with corresponding array indices.
 Args:         a database handle
 Side Effects:
 Example:

=cut

sub get_all_organisms {
    my $dbh = shift;
    #this query should be changed to work with chado's organism table after sgn.common_name is replaced with it.
    my $query = "SELECT common_name, common_name_id 
                   FROM sgn.common_name ORDER BY upper(common_name) desc";
    my $sth = $dbh->prepare($query);
    $sth->execute();
    my @names = ();
    my @ids = ();
    while (my($common_name, $common_name_id) = $sth->fetchrow_array()) { 
	push @names, $common_name;
	push @ids, $common_name_id;
    }
    return (\@names, \@ids);
}


=head2 get_existing_organisms

 Usage:        my ($names_ref, $ids_ref) = CXGN::Tools::Organism::get_existing_organisms($dbh);
 Desc:         This is a static function. Selects the distinct organism names and their IDs from phenome.locus.
               Useful fro populating a unique drop-down menu with only the organism names that exist in the table.
 Ret:          Returns two arrayrefs. One array contains all the
               organism names, and the other all the organism ids
               with corresponding array indices.
 Args:         a database handle
 Side Effects:
 Example:

=cut

sub get_existing_organisms {
    my $dbh= shift;
    my $query = "SELECT distinct(common_name), common_name_id FROM phenome.locus 
                 JOIN sgn.common_name using(common_name_id) 
                 WHERE obsolete = 'f'";
    my $sth = $dbh->prepare($query);
    $sth->execute();
    my @names = ();
    my @ids = ();
    while (my($common_name, $common_name_id) = $sth->fetchrow_array()) { 
	push @names, $common_name;
	push @ids, $common_name_id;
    }
    return (\@names, \@ids);
}

=head2 get_all_populations

 Usage:        my ($names_ref, $ids_ref) = CXGN::Tools::Organism::get_all_populations($dbh);
 Desc:         This is a static function. Retrieves distinct population names and IDs from phenome.population
 Ret:          Returns two arrayrefs. One array contains all the
               population names, and the other all the population ids
               with corresponding array indices.
 Args:         a database handle
 Side Effects:
 Example:

=cut

sub get_all_populations {
    my $dbh = shift;
   
    my $query = "SELECT name, population_id 
                   FROM phenome.population";
    my $sth = $dbh->prepare($query);
    $sth->execute();
    my @names = ();
    my @ids = ();
    while (my($name, $population_id) = $sth->fetchrow_array()) { 
	push @names, $name;
	push @ids, $population_id;
    }
    return (\@names, \@ids);
}


return 1;
