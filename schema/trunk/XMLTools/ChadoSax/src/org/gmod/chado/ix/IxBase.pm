
=head1 NAME

org::gmod::chado::ix::IxBase

=head1 DESCRIPTION

Basic feature/attribute.

=cut

package org::gmod::chado::ix::IxBase;

use strict;


sub isBaseob() { return 1; }

sub new {
	my $that= shift;
	my $class= ref($that) || $that;
	my %fields = @_;   
	my $self = \%fields;
	bless $self, $class;
	$self->init();
	return $self;
}

sub init {
	my $self= shift;
	$self->{tag}= 'IxBase' unless (exists $self->{tag} );
}

sub set {
	my $self= shift;
	my $key= shift;
	my $val= shift;
	$self->{$key}= $val;
}

sub get {
	my $self= shift;
	my $key= shift;
	return $self->{$key};
}

sub name {
	my $self= shift;
	foreach (qw/name uniquename cvname program accession dbname/) {
	  return $self->{$_} if ($self->{$_});
	  }
	my $a= $self->{attr};
	if ($a) {
	  while ((ref $a) && $a->can('name')) { $a= $a->name(); }
	  if ($a && !(ref $a)) { return $a; }
	  }
	return $self->{id}; #always ?
}

sub id2name {
	my $self= shift;
	my ($k,$v)= @_;
  if ($k =~ /_id$/) {
   my $ft= $self->{handler}->{idhash}{$v};
   if ($ft) {
      my $idval= $ft->name() || '';
      if ($idval) { 
        $v= $idval; #? or $v= "$v=$idval";
        $k =~ s/_id$/_name/;
        }
      }
    }
  return ($k,$v);
}

sub printObj { ## was toString
	my $self= shift;
	my $depth= shift;
	my $sb='';

  my $tab= "  " x $depth;
  print $tab.$self->{tag}." = {\n";
  $depth++;
  $tab= "  " x $depth;
  print $tab."id=".$self->{id}."\n" if $self->{id};
  
  ## print "# Keys\n";
  foreach my $k (sort keys %$self) {
    next if ($k =~ /^(id|tag|handler)$/);
    my $v= $self->{$k};

    # check type_id|.. here and change $k if need be ?
    # if ($k =~ /^(type_id|pkey_id)$/)  
    ($k,$v)= $self->id2name($k,$v);

    print $tab."$k";
    next unless($v =~ /\S/);
    print "=";
    if (ref $v && $v->can('printObj')) {
      print  $v->printObj($depth);
      }
    elsif (ref $v =~ /ARRAY/) { ## list, attrlist
      print "[";
      foreach my $a ( @$v ) {
        if (ref $a && $a->can('printObj')) {
          print $a->printObj($depth);
          }
        else { print $a; }
        print ",";
        }
      print "]\n";
      }
    elsif (ref $v =~ /HASH/) { ## list, attrlist
      print "[";
      foreach my $a (sort keys %$v ) {
        if (ref $a && $a->can('printObj')) {
          print  $a->printObj($depth);
          }
        else { print $a; }
        print ",";
        }
      print "]\n";
      }
    else { print $v; }
    print "\n";
    }

  return $sb;
}


1;
