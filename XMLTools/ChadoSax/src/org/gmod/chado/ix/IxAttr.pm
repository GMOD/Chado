
=head1 NAME

org::gmod::chado::ix::IxAttr

=head1 DESCRIPTION

Describe generic attribute.
See also org.gmod.chado.ix.IxAttr.java

=head1 AUTHOR

D.G. Gilbert, May 2003, gilbertd@indiana.edu

=cut

package org::gmod::chado::ix::IxAttr;

use strict;
use org::gmod::chado::ix::IxBase;
use vars qw/  @ISA /;
@ISA = qw( org::gmod::chado::ix::IxBase );  

sub isAttrib() { return 1; }

sub init {
	my $self= shift;
  $self->{tag}= 'IxAttr' unless (exists $self->{tag} );
}

sub setattr {
	my $self= shift;
	# my $key= shift;
	my $val= shift;
	$self->{attr}= $val;
}

sub getattr {
	my $self= shift;
	# my $key= shift;
	return $self->{attr};
}

sub cleanval {
	my $self= shift;
  local $_= shift;
  return $_ if (ref $_);
  my $m= tr/[({/[({/;
  my $n= tr/])}/])}/;
  if ($m != $n) {
    s,[\[\]\(\)\{\}],.,g; #? may not need, but unbalanced for some [](){} symbols
    }
  if (/\s/) { return "'$_'"; }
  else { return $_; }
}

sub printObj {  
	my $self= shift;
	my $depth= shift;

  my $tab= "  " x $depth;
	my $sb='';  
  my $ln= 10; my $lb='';
  my @keys= sort keys %$self;
  my $dobrak= scalar(@keys)>3;
  
  my $tag= $self->{tag};
  my $attr= $self->{attr};
  ($tag,$attr)= $self->id2name($tag,$attr);
  
  print $tag."="; $ln += length($tag); 
  print "{ " if $dobrak;

  my $sn= 1; 
  if (ref $attr && $attr->can('printObj')) {
    $ln += $attr->printObj($depth);
    }
  else {  
    $attr= $self->cleanval($attr);
    print $attr; $ln += length($attr); 
    }
    
  foreach my $k (@keys) {
    next if ($k =~ /^(tag|attr|handler|parnode)$/);
    my $v= $self->{$k};
    ($k,$v)= $self->id2name($k,$v); 
    $v= $self->cleanval($v);
    $lb= '';
    print ", " if ($sn++);
    $lb .= "$k="; # unless($k eq 'attr');
    # if ($k eq 'pval') { $v= $self->cleanval($v); }
    
    if (ref $v && $v->can('printObj')) {
      $ln += $v->printObj($depth);   
      }
    elsif (ref $v =~ /ARRAY/) { ## list, attrlist
      $lb .= "[";
      foreach my $a ( @$v ) {
        if (ref $a && $a->can('printObj')) {
          $ln += $a->printObj($depth);    
          }
        else { $lb.= $a; }
        $lb.= ", ";
        }
      $lb.= "]\n$tab";
      }
    # elsif ($v =~ /\s/) { $lb.= "'$v'"; }
    else { $lb.= $v; }
    print $lb;
    $ln += length($lb);
    }
  if ($dobrak) { print " } ";} else { print " "; }
  $self->{handler}->{linelen} += $ln; #?
  return $ln;
}
  
1;