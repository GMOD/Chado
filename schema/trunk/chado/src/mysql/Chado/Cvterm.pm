package Chado::Cvterm;
use base 'Chado::DBI';

use Chado::Cvrelationship;

Chado::Cvterm->set_up_table('cvterm');

sub id   { return shift->cvterm_id }
sub name { return shift->termname  }


sub parent {
  my $self = shift;
  my $cvr = Chado::Cvrelationship->search(objterm_id => $self->id);
  return Chado::Cvterm->retrieve($cvr->subjterm_id);
}

sub children {
  my $self = shift;
  my $cvr_iter = Chado::Cvrelationship->search(subjterm_id => $self->id);

  my @returns;

  while(my $cvr = $cvr_iter->next){
    push @returns, Chado::Cvterm->retrieve($cvr->objterm_id);
  }

  return @returns;
}

1;
