=head1 NAME

CXGN::Chado::Pubauthor 
display and store authors of a publication

=head1 SYNOPSIS

=head1 AUTHOR

Naama

=cut
use CXGN::DB::Connection;
use CXGN::Chado::Publication;


package CXGN::Chado::Pubauthor;
use strict;
use warnings;

use base qw / CXGN::Chado::Publication /;



=head2 new

 Usage: my $author = CXGN::Chado::Pubauthor->new($dbh, $pubauthor_id);
 Desc:
 Ret:    
 Args: $dbh, $pubauthor_id
 Side Effects:
 Example:

=cut


sub new {
    my $class = shift;
    my $dbh= shift;
    my $id= shift; # the pub_id of the publication 
   
    
    my $args = {};  
    my $self = bless $args, $class;
    $self=$class->SUPER::new($dbh);  
  
    $self->set_pubauthor_id($id);
   
    if ($id) {
	$self->fetch($id);
    }
    
    return $self;
}


sub fetch {
    my $self=shift;

    my $pubauthor_query = $self->get_dbh()->prepare(
		        "SELECT  pub_id, rank, editor, surname, givennames, suffix 
                          FROM public.pubauthor
                          WHERE pubauthor_id=? "
						    );
   
    my $pubauthor_id=$self->get_pubauthor_id();
    $pubauthor_query->execute( $pubauthor_id);

     
    my ($pub_id, $rank, $editor, $surname, $givennames, $suffix)=
     $pubauthor_query->fetchrow_array();
    
    $self->set_pub_id($pub_id);
    $self->set_rank($rank);
    $self->set_editor($editor);
    $self->set_surname($surname);
    $self->set_givennames($givennames);
    $self->set_suffix($suffix);
}


=head2 store

 Usage: $self->store()
 Desc: store an author of a publication in chado pubauthor table
 Ret:  a database pubauthor_id 
 Args: none
 Side Effects:
 Example:

=cut

sub store {
    my $self = shift;
    
    if ($self->get_pubauthor_id()) {
	#not updating authors..
    }else { 
	my $pub_id= $self->get_dbh->last_insert_id('pub', 'public');
	$self->set_pub_id($pub_id);
	#store new author
 	my $pubauthor_sth= $self->get_dbh()->prepare(
		    "INSERT INTO pubauthor (pub_id, rank, editor, surname, givennames, suffix)                                  VALUES (?,?,?,?,?,?)");
	
	$pubauthor_sth->execute($self->get_pub_id, $self->get_rank, $self->get_editor, $self->get_surname, $self->get_givennames, $self->get_suffix() );
	####
	my $pubauthor_id= $self->get_dbh->last_insert_id('pubauthor', 'public');
	$self->set_pubauthor_id($pubauthor_id);
	return $pubauthor_id;
	
    }
}


=head2 get_pubauthor_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_pubauthor_id {
  my $self=shift;
  return $self->{pubauthor_id};

}

=head2 set_pubauthor_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_pubauthor_id {
  my $self=shift;
  $self->{pubauthor_id}=shift;
}

=head2 get_rank

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_rank {
  my $self=shift;
  return $self->{rank};

}

=head2 set_rank

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_rank {
  my $self=shift;
  $self->{rank}=shift;
}

=head2 get_editor

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_editor {
  my $self=shift;
  return $self->{editor};

}

=head2 set_editor

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_editor {
  my $self=shift;
  $self->{editor}=shift;
}

=head2 get_surname

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_surname {
  my $self=shift;
  return $self->{surname};

}

=head2 set_surname

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_surname {
  my $self=shift;
  $self->{surname}=shift;
}

=head2 get_givennames

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_givennames {
  my $self=shift;
  return $self->{givennames};

}

=head2 set_givennames

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_givennames {
  my $self=shift;
  $self->{givennames}=shift;
}

=head2 get_suffix

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_suffix {
  my $self=shift;
  return $self->{suffix};

}

=head2 set_suffix

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_suffix {
  my $self=shift;
  $self->{suffix}=shift;
}



return 1;
