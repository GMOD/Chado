


=head1 NAME

CXGN::DB::Object - a parent class for all objects needing a database handle accessor
 
=head1 DESCRIPTION

This class is not intended to be used by itself, but rather it should be sub-classed. 

For example, a class using CXGN::DB::Object should declare:

 package CXGN::SomeObject;
 
 sub new { 
   my $class = shift;
   my $dbh = shift;
   return $self = $class->SUPER::new($dbh);
 }

Note that it is assumed that these database objects are always fed with a $dbh from somewhere outside the class, which allows better control on the number of open database connections. These $dbh should preferably be created with CXGN::DB::Connection, which respects server configurations and accesses the correct database according to configuration settings.


=head1 AUTHOR(S)

Lukas Mueller (lam87@cornell.edu)

=head1 FUNCTIONS

This class implements the following functions:

=cut

use strict;

package CXGN::DB::Object;

use Carp;

=head2 function new

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub new {
    my $class = shift;
    my $dbh = shift;
    
    if ($dbh) { 
	if (!$dbh->isa("CXGN::DB::Connection")) { 
	    die "I need a database handle, folks! Byebye!\n";
	}
    }
    else { 
	print STDERR "WARNING! Usually dbh parameter required.\n";
    }
    my $self = bless {}, $class;
    $self->set_dbh($dbh);
    return $self;
}

=head2 accessors set_dbh, get_dbh

  Property:	
  Setter Args:	
  Getter Args:	
  Getter Ret:	
  Side Effects:	
  Description:	

=cut

sub get_dbh { 
    my $self=shift;
    return $self->{dbh};
}

sub set_dbh { 
    my $self=shift;
    $self->{dbh}=shift;
}

=head2 function get_currval

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_currval {
    my $self = shift;
    my $serial_name = shift;
    my $sth = $self->get_dbh()->prepare("SELECT CURRVAL(?)");
    $sth->execute($serial_name);
    my ($currval) = $sth->fetchrow_array();
    return $currval;
}



return 1;
