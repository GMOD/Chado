
=head1 NAME

org::gmod::chado::ix::IxSpan

=head1 DESCRIPTION

Describe generic feature location.
See also org.gmod.chado.ix.IxSpan.java

=head1 AUTHOR

D.G. Gilbert, May 2003, software@bio.indiana.edu

=cut

package org::gmod::chado::ix::IxSpan;

use strict;
use org::gmod::chado::ix::IxAttr;
use vars qw/  @ISA /;
@ISA = qw( org::gmod::chado::ix::IxAttr );  


sub isSpan() { return 1; }

# sub new {
# 	my $that= shift;
# 	my $class= ref($that) || $that;
# 	my %fields = @_;   
# 	my $self = \%fields;
# 	bless $self, $class;
# 	$self->init();
# 	return $self;
# }

sub init {
	my $self= shift;
  $self->{tag}= 'IxSpan' unless (exists $self->{tag} );
}

sub reversed { 
  my $self= shift; 
  if (defined $self->{strand}) { return ($self->{strand}<0);  }
  else { return ($self->{nbeg} > $self->{nend}); }
  }
sub isForward { my $self= shift; return !$self->reversed(); }

##  jun03 - fmin,fmax replace nbeg,nend ; fmin always < fmax ? and use 'strand'
##  chado uses odd 'interbase' begin value == -1 of starting base
##  presumably to save cost of -1 in calculating length = fmax - fmin  

sub start {my $self= shift; return (defined $self->{fmin}) ? $self->{fmin} + 1 : $self->{nbeg}; }
sub stop { my $self= shift; return (defined $self->{fmax}) ? $self->{fmax} : $self->{nend}; }

sub length {
	my $self= shift;
	if (defined $self->{fmax}) {
	  return $self->{fmax} - $self->{fmin};
	  }
  elsif ($self->{nbeg} > $self->{nend}) { 
    return $self->{nbeg} - $self->{nend} + 1; 
    }  
  else {
    return $self->{nend} - $self->{nbeg} + 1; 
    }
}


sub toString {
	my $self= shift;
  return $self->start() ."..". $self->stop();
  # return $self->{nbeg} ."..". $self->{nend};
}

  
1;
