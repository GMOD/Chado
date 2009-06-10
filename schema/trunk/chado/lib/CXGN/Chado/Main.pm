
=head1 NAME

CXGN::Chado::Main 
package for the main methods used by Chado objects (CV, Db.. )  

=head1 SYNOPSIS

=head1 AUTHOR

Naama Menda (nm249@cornell.edu)

=cut 

package CXGN::Chado::Main;

use base qw / CXGN::DB::Object / ;

=head2 new

 Usage: CXGN::Chado::Main->new($dbh) 
 Desc:  a new Chado::Main class
 Ret:   $self 
 Args: database handle
 Side Effects: sets dbh
 Example:

=cut

sub new {
    my $class=shift;
    my $dbh= shift; 
   
    my $args = {};  
    my $self = $class->SUPER::new($dbh); #bless $args, $class;

   $self->set_dbh($dbh);
  
    return $self;
}

=head2 Class properties
    
The following class properties have accessors : 
    
    get_dbh/set_dbh


=cut


sub get_dbh {
  my $self=shift;
  return $self->{dbh};
}

sub set_dbh {
  my $self=shift;
  $self->{dbh}=shift;
}


###
1;# do not remove
###
