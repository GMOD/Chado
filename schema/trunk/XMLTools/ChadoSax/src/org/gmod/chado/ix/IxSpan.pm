
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

sub reversed { my $self= shift; return ($self->{nbeg} > $self->{nend}); }
sub isForward { my $self= shift; return !$self->reversed(); }

sub length {
	my $self= shift;
  if ($self->{nbeg} > $self->{nend}) { 
    return $self->{nbeg} - $self->{nend} + 1; 
    }  
  else {
    return $self->{nend} - $self->{nbeg} + 1; 
    }
}


sub toString {
	my $self= shift;
  return $self->{nbeg} ."..". $self->{nend};
}

  
1;
