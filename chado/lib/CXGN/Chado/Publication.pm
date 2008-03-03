
=head1 NAME

Functions for accessing and inserting new publications into the database

=head1 SYNOPSIS


=head1 DESCRIPTION
 

=cut
use strict;
use warnings;

#use CXGN::Chado::Pubauthor;

package CXGN::Chado::Publication;

use base qw /CXGN::Chado::Dbxref/;

=head2 new

 Usage: my $pub = CXGN::Chado::Publication->new($dbh, $pub_id);
 Desc:
 Ret:    
 Args: $dbh, $pub_id
 Side Effects:
 Example:

=cut


sub new {
    my $class = shift;
    my $dbh= shift;
    my $id= shift; # the pub_id of the publication 
   
    
    my $args = {};  
    my $self = bless $args, $class;

    $self->set_dbh($dbh);
    $self->set_pub_id($id);
   
    if ($id) {
	$self->fetch($id);
    }
    
    return $self;
}

=head2 fetch

 Usage:
 Desc:
 Ret:    
 Args: none
 Side Effects:
 Example:

=cut

sub fetch {
    my $self=shift;

    my $pub_query = $self->get_dbh()->prepare(
		        "SELECT  title, volume, series_name, issue, pyear, pages, uniquename, cvterm.name, pub_dbxref.dbxref_id, abstract
                          FROM public.pub
                          JOIN public.cvterm ON (public.pub.type_id=public.cvterm.cvterm_id)
                          JOIN public.pub_dbxref USING (pub_id) 
                          JOIN public.pubabstract USING (pub_id)
                          JOIN public.pubauthor USING (pub_id)
                          WHERE pub_id=? "
					      );
   
    my $pub_id=$self->get_pub_id();
    $pub_query->execute( $pub_id);

     
    my ($title, $volume, $series_name, $issue, $pyear, $pages, $uniquename, $cvterm_name, $dbxref_id, $abstract)=
     $pub_query->fetchrow_array();
    
    $self->set_title($title);
    $self->set_volume($volume);
    $self->set_series_name($series_name);
    $self->set_issue($issue);
    $self->set_pyear($pyear);
    $self->set_pages($pages);
    $self->set_uniquename($uniquename);
    $self->set_cvterm_name($cvterm_name);
    $self->set_dbxref_id($dbxref_id);
    $self->set_abstract($abstract);
  
    
}


=head2 store

 Usage:  $pub_object->store()
 Desc:   store a publication object in chado pub module 
 Ret:    database publication ID
 Args:   none
 Side Effects: stores the accession id in dbxref (if it is not there already),
               the dbxref_id in the linking table pub_dbxref (with the new pub_id)
               and the text abstract in pubabstract (this table is not part of the chado schema)
                
 Example:

=cut

sub store {
    my $self = shift;
    
    #If accession is not in dbxref- do an insert (for pubmed db.name is PMID)
    my $db_name= 'PMID';
    $self->set_db_name($db_name);
    
    my $dbxref_id= CXGN::Chado::Dbxref::get_dbxref_id_by_accession($self->get_dbh(), $self->get_accession(), $self->get_db_name());
    if (!$dbxref_id) {
	my $dbxref_sth= $self->get_dbh->prepare("INSERT INTO public.dbxref (db_id, accession) VALUES ((SELECT db_id FROM db WHERE name = ?), ?)"); 
	
	$dbxref_sth->execute($db_name, $self->get_accession());
	$dbxref_id= $self->get_dbh()->last_insert_id("dbxref", "public");
	$self->set_dbxref_id($dbxref_id);
	print STDERR "*** Inserting new dbxref $dbxref_id for pubmed accession ...\n";

    } else { 	print STDERR "^^^ dbxref ID $dbxref_id already exists...\n"; }
    
    ####
    
    if ($self->get_pub_id()) {
	#can publications be altered? check pubmed for update option..
    }else { 
	
	my $existing_pub_id= $self->get_pub_by_uniquename();
	if (!$existing_pub_id) {
	
	    #store new publication
	    my $pub_sth= $self->get_dbh()->prepare(
		    "INSERT INTO pub (title, volume, series_name, issue, pyear, pages, uniquename, type_id)                      VALUES (?,?,?,?,?,?,?, (SELECT cvterm_id FROM cvterm WHERE name = ?))");
	    $pub_sth->execute($self->get_title, $self->get_volume, $self->get_series_name, $self->get_issue, $self->get_pyear, $self->get_pages(), $self->get_uniquename(), 'journal');
	    ####
	   
	    #this statement is for inserting into pub_dbxref table 
	    my $pub_dbxref_sth= $self->get_dbh()-> prepare("INSERT INTO pub_dbxref (pub_id, dbxref_id) VALUES (?, ?)");
	    $pub_dbxref_sth->execute($self->get_dbh()->last_insert_id('pub', 'public'), $dbxref_id);
	    print STDERR "*** Inserting new publication dbxref ID= $dbxref_id\n";
	    
	    
	    ####
	    
	    #insert the abstract of the publication
	    my $abstract_sth= $self->get_dbh()->prepare("INSERT INTO pubabstract (pub_id, abstract) VALUES (?,?)");
	    $abstract_sth->execute($self->get_dbh->last_insert_id('pub', 'public'), $self->get_abstract());
	  	    
	    
	    my $pub_id= $self->get_dbh->last_insert_id('pub', 'public');
	    $self->set_pub_id($pub_id);
	    
	    #$self->get_authors() ;
	    my $rank=1;
	    foreach my $author ( @{$self->{authors}} )   {
		$rank++;
		my $author_obj= CXGN::Chado::Pubauthor->new($self->get_dbh());
		my ($surname, $givennames)= split  ' ', $author; 
		$author_obj->set_rank($rank);
		$author_obj->set_surname($surname);
		$author_obj->set_givennames($givennames);
		$author_obj->store();
	    }
	    
	    return $pub_id;
	}
    }
}




sub get_pubauthors_ids {
  my $self=shift;
  my $pub_id = shift;
  my @pubauthors_ids;
  my $pubauthor_id;

  my $q = "SELECT pubauthor_id FROM public.pubauthor WHERE pubauthor.pub_id=?";
  my $sth = $self->get_dbh->prepare($q);
  $sth->execute($pub_id);
  
  while ($pubauthor_id = $sth->fetchrow_array()) {
      push @pubauthors_ids, $pubauthor_id;
  }

  return @pubauthors_ids;

}

=head2 get_dbh

 Usage:  $self->get_dbh
 Desc:
 Ret: a database handle
 Args: 
 Side Effects:
 Example:

=cut

sub get_dbh {
  my $self=shift;
  return $self->{dbh};

}

=head2 set_dbh

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_dbh {
  my $self=shift;
  $self->{dbh}=shift;
}

=head2 get_pub_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_pub_id {
  my $self=shift;
  return $self->{pub_id};

}

=head2 set_pub_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_pub_id {
  my $self=shift;
  $self->{pub_id}=shift;
}



=head2 get_title

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_title {
  my $self=shift;
  return $self->{title};

}

=head2 set_title

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_title {
  my $self=shift;
  $self->{title}=shift;
}

=head2 get_volume

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_volume {
  my $self=shift;
  return $self->{volume};

}

=head2 set_volume

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_volume {
  my $self=shift;
  $self->{volume}=shift;
}

=head2 get_series_name

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_series_name {
  my $self=shift;
  return $self->{series_name};

}

=head2 set_series_name

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_series_name {
  my $self=shift;
  $self->{series_name}=shift;
}

=head2 get_issue

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_issue {
  my $self=shift;
  return $self->{issue};

}

=head2 set_issue

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_issue {
  my $self=shift;
  $self->{issue}=shift;
}

=head2 get_pyear

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_pyear {
  my $self=shift;
  return $self->{pyear};

}

=head2 set_pyear

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_pyear {
  my $self=shift;
  $self->{pyear}=shift;
}

=head2 get_pages

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_pages {
  my $self=shift;
  return $self->{pages};

}

=head2 set_pages

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_pages {
  my $self=shift;
  $self->{pages}=shift;
}

=head2 get_uniquename

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_uniquename {
  my $self=shift;
  return $self->{uniquename};

}

=head2 set_uniquename

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_uniquename {
  my $self=shift;
  $self->{uniquename}=shift;
}

=head2 get_cvterm_name

 Usage: $self->get_cvterm_name()
 Desc:  a getter for the publication type (book or journal- stored in chado cvterm table) 
 Ret:   
 Args:  none
 Side Effects:
 Example:

=cut

sub get_cvterm_name {
  my $self=shift;
  return $self->{cvterm_name};

}

=head2 set_cvterm_name

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_cvterm_name {
  my $self=shift;
  $self->{cvterm_name}=shift;
}

=head2 get_accession

 Usage:  $self->get_accession()
 Desc:   a getter for the database accession (pubmed) of the publication
 Ret:
 Args:  none
 Side Effects:
 Example:

=cut

sub get_accession {
  my $self=shift;
  return $self->{accession};

}

=head2 set_accession

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_accession {
  my $self=shift;
  $self->{accession}=shift;
}

=head2 get_abstract

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut


sub get_abstract {
  my $self=shift;
  return $self->{abstract};

}

=head2 set_abstract

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_abstract {
  my $self=shift;
  $self->{abstract}=shift;
}


=head2 get_dbxref_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_dbxref_id {
  my $self=shift;
  return $self->{dbxref_id};

}

=head2 set_dbxref_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_dbxref_id {
  my $self=shift;
  $self->{dbxref_id}=shift;
}


=head2 add_author

 Usage: $self->add_author($author_data)
 Desc:  a method for storing authors in an array. 
        Each author should have the following data: 
        the rank of the author (an integer) -  'last name' - 'first_name, initials'
 Ret:  
 Args: $author_data:  a scalar  variable with the author rank, last name, first name
 Side Effects:
 Example:

=cut

sub add_author {
    my $self=shift;
    my $author = shift; 
    push @{ $self->{authors} }, $author;

}

=head2 get_authors

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_authors {
  my $self=shift;
  if($self->{authors}){
      return @{$self->{authors}};
  }
  return undef;
}
=head2 get_pub_by_uniquename
 Usage:  $self->get_pub_by_uniquename()
 Desc:  check if a publication is already stored in the database
        the check is performed by using the 'uniquename' field which has the format : 'accession#: title'
 Ret:   $pub_id: a database id
 Args: none
 Side Effects:
 Example: 

=cut

sub get_pub_by_uniquename {
    my $self = shift;
    my $query = "SELECT pub_id
                  FROM public.pub
                  WHERE uniquename=? " ;
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_uniquename );
    my $pub_id = $sth->fetchrow_array();

    return $pub_id;
}


=head2 publication_exists
 Usage:  $self->publication_exists($dbxref_accession)
 Desc:  check if a publication is already stored in the database 
        the check is performed by using a pubmed accession
 Ret:   $pub_id: a database id
 Args: pubmed accession number (PMID)
 Side Effects:
 Example: 

=cut

sub publication_exists {
    my $self = shift;
    my $query = "SELECT pub_id
                  FROM public.pub
                  JOIN pub_dbxref USING (pub_id)
                  JOIN public.dbxref USING (dbxref_id)
                  WHERE dbxref.accession=? " ;
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_accession );
    my $pub_id = $sth->fetchrow_array();

    return $pub_id;
}


=head2 is_associated_publication

 Usage:
 Desc: Check to see if the publication corresponding to the given pub_id is associated with the object of the given type in our database
 Ret: 0 if the publication is not already associated with this object in our databases, 1 if it is.
 Args: The publication_id of the 
 Side Effects:
 Example:

=cut

sub is_associated_publication {
    my $self = shift;
    my $type = shift;
    my $type_id = shift;

    my $dbxref_id= $self->get_dbxref_id();
       
    my ($locus, $allele);
    if ($type eq 'locus') {
	$locus= CXGN::Phenome::Locus->new($self->get_dbh(), $type_id);
    }
    elsif ($type eq 'allele'){
	$allele=CXGN::Phenome::Allele->new($self->get_dbh(), $type_id);
    }

    ##dbxref object...
    my $dbxref= CXGN::Chado::Dbxref->new($self->get_dbh(), $dbxref_id);
    my ($associated_publication, $obsolete);
    if ($type eq 'locus') {
	$associated_publication= $locus->get_locus_dbxref($dbxref)->get_locus_dbxref_id();
	$obsolete = $locus->get_locus_dbxref($dbxref)->get_obsolete();
    }elsif ($type eq 'allele' ) {
	$associated_publication= $allele->get_allele_dbxref($dbxref)->get_allele_dbxref_id();
	$obsolete = $allele->get_allele_dbxref($dbxref)->get_obsolete();  
    }
    if  ($associated_publication && $obsolete eq 'f') {
	return 1;		   
	
    }else{  ##the publication is not associated with the object
	return 0; 
    }    
}

=head2 get_pub_by_accession

  Usage: my $pub=CXGN::Chado::Publication->get_pub_by_accession($accession);
 Desc:  get a publication object with an accession
 Ret: a publication object
 Args: publication accession (pubmed ID)
 Side Effects:
 Example:

=cut

sub get_pub_by_accession {
    my $self=shift;
    my $dbh=shift;
    my $accession=shift;
    my $query = "SELECT pub_id
                  FROM public.pub
                  JOIN pub_dbxref USING (pub_id)
                  JOIN public.dbxref USING (dbxref_id)
                  WHERE dbxref.accession=? " ;
    my $sth = $dbh->prepare($query);
    $sth->execute($accession );
    my $pub_id = $sth->fetchrow_array();
    if ($pub_id) { 
	my $publication= CXGN::Chado::Publication->new($dbh, $pub_id);
	return $publication;
    }
    else { return undef; }
}


=head2 get_loci

 Usage: $publication->get_loci()
 Desc: find all the associated loci with the publication
 Ret: an array of locus objects
 Args: none
 Side Effects:
 Example:

=cut

sub get_loci {
    my $self=shift;
    my $query = $self->get_dbh()->prepare("SELECT locus_id FROM phenome.locus_dbxref
                                          
                                           JOIN public.pub_dbxref USING (dbxref_id)
                                           JOIN pub using (pub_id)
                                           WHERE pub.pub_id= ? AND phenome.locus_dbxref.obsolete='f'");
    $query->execute($self->get_pub_id());
    my @loci;
    while (my $locus_id= $query->fetchrow_array()) {
	my $locus = CXGN::Phenome::Locus->new($self->get_dbh(), $locus_id);
	push @loci, $locus;
    }
    return @loci;
}

=head2 get_curator_ref

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_curator_ref {

    my $dbh=shift;
    my $query = "SELECT dbxref_id FROM public.dbxref JOIN cvterm USING (dbxref_id) JOIN pub on (type_id= cvterm_id)
                 WHERE title = ?";
    my $sth= $dbh->prepare($query);
    $sth->execute('curator');
    my $dbxref_id= $sth->fetchrow_array();
    return $dbxref_id;
}



return 1;
