package CXGN::Tools::List;
use strict;
use Carp;

use List::Util qw/first/;

use POSIX;

=head1 NAME

CXGN::Tools::List - small (sort of) useful functions for working with
lists that aren't in L<List::Util>.

=head1 SYNOPSIS

  use CXGN::Tools::List qw/ every_other_elem
			    any
			    all
			    none
			    notall
			    true
			    false
                            max
                            min
                            flatten
                            collate
                            str_in
                            distinct
                            balanced_split
                            evens
                            odds
                            index_where
                            list_join
			  /;

  every_other_elem(1,0,1,0,0,1); #(1,1,0)
  any(0,1,0,0); #returns true
  all(0,1,0,0); #returns false
  all(1,1,1,1); #returns true
  none(0,1,0,0); #false
  none(0,0,0,0); #true
  notall(0,1,0,0); #true
  notall(1,1,1,1); #false
  true(0,1,1,0,0); #2
  true(1,1,1,1,0,0); #4
  false(0,1,1,0,0); #3
  false(1,1,1,1,0,0); #2

  my @list = flatten(['a','b'],'c',['d',['e','f']],{g => 'h'});
  #@list is now qw/a b c d e f g h/;

  my %hash = collate(\@list1,\@list2);

  if(str_in($name,qw/Linus Larry Eric/)) {
    print "i've heard of $name\n";
  }

  my @d = distinct qw/Linus Larry Eric Larry Linus Eric/;
  #@d is now qw/Linus Larry Eric/


  evens('foo','bar','baz','quux') # 'foo','baz'
  odds('foo','bar','baz','quux')  # 'bar','quux'

  index_where {$_ eq 'monkeys'} qw/foo bar baz quux/       # -1
  index_where {$_ eq 'monkeys'} qw/monkeys bonobos/        # 0
  index_where {$_ eq 'monkeys'} qw/bonobos chimps monkeys/ # 2

=cut

use base qw/Exporter/;

BEGIN {
  our @EXPORT_OK = qw/ every_other_elem
		       any  all none notall true false
		       max min flatten
		       collate
		       str_in
                       distinct
		       balanced_split
		       evens odds
		       index_where
		       list_join
		     /;
}
our @EXPORT_OK;

sub every_other_elem(@) {
  my $last = 0;
  map {$last = !$last; $last ? ($_) : ()} @_;
}

######## useful list tests ###########
# One argument is true
sub any { $_ && return 1 for @_; 0 }

# All arguments are true
sub all { $_ || return 0 for @_; 1 }

# All arguments are false
sub none { $_ && return 0 for @_; 1 }

# One argument is false
sub notall { $_ || return 1 for @_; 0 }

# How many elements are true
sub true { scalar grep { $_ } @_ }

# How many elements are false
sub false { scalar grep { !$_ } @_ }

=head2 max

  Usage: my $max = max(@mylist);
  Desc : find the maximum numerical value in a list.  Reimplemented here because
         List::Util::max does not work on OS X 10.3
  Ret  : maximum value in the list, or undef if there is none
  Args : list of numerical values
  Side Effects: none

=cut

sub max {
  my $max;
  $max = (defined($max) and $max >= $_) ? $max : $_ foreach @_;
  return $max
}

=head2 min

  Usage: my $min = min(@mylist);
  Desc : find the minimum numerical value in a list.  Reimplemented here because
         List::Util::min does not work on OS X 10.3.
  Ret  : minimum value in the list, or undef if there is none
  Args : list of numerical values
  Side Effects: none

=cut

sub min {
  my $min;
  $min = (defined($min) and $min <= $_) ? $min : $_ foreach @_;
  return $min;
}


=head2 flatten

  Usage: my @list = flatten(['a','b'],'c',['d',['e','f']],{g => 'h'});
         #@list is now qw/a b c d e f g h/;
  Desc : given a list of scalars, array refs, and/or hash refs,
         flatten them all into a list
  Ret  : a list
  Args : a list of stuff
  Side Effects: none

=cut

sub flatten(@) {
  map {
    if(ref eq 'ARRAY') {
      flatten(@$_);
    }
    elsif(ref eq 'HASH') {
      flatten(%$_);
    }
    else {
      $_
    }
  } @_;
}

=head2 collate

  Usage: my %hash = collate(\@list1,\@list2);
  Desc : collate two lists into a hash, with one as keys and the
         other as values
  Ret  : a hash-style list with the elements of the first array
         as the keys and the elements of the second array as the
         values
  Args : two arrayrefs
  Side Effects: if the two arrayrefs have different lengths,
                ignores extra elements

=cut

sub collate($$) {
  my ($list1,$list2) = @_;

  ref($list1) eq 'ARRAY' && ref($list2) eq 'ARRAY'
    or croak 'invalid arguments to collate().  give two arrayrefs';
  unless(@$list1 == @$list2) {
    if(@$list1 > @$list2) {
      $list1 = [@$list1[0..(@$list2-1)]];
    }
    elsif(@$list1 < @$list2) {
      $list2 = [@$list2[0..(@$list1-1)]];
    }
  }

  my %hash;
  @hash{@$list1} = @$list2;
  return %hash;
}


=head2 str_in

  Usage: print "it's valid" if str_in($thingy,qw/foo bar baz/);
  Desc : return 1 if the first argument is string equal to at least one of the
         subsequent arguments
  Ret  : 1 or 0
  Args : string to search for, array of strings to search in
  Side Effects: none

  I kept writing this over and over in validation code and got sick of it.

=cut

sub str_in {
  my $needle = shift;
  return defined(first {$needle eq $_} @_) ? 1 : 0;
}


=head2 distinct

  Usage: my @things = distinct(@other_things);
  Desc : remove duplicates in a list of strings, similar to SQL's DISTINCT
  Ret  : list of non-duplicated strings
  Args : list of strings
  Side Effects: none

=cut

sub distinct {
  my %seen;
  return grep {
    my $r = !$seen{$_};
    $seen{$_} = 1;
    $r
  } @_;
}


=head2 balanced_split

  Usage: my @lists = balanced_split($num_pieces,@list);
  Desc : split the given list in to the given number of pieces,
         with the lengths of the pieces differing by at most
         1 element.  If the number of requested pieces is less
         than the number of elements in the input, returns a
         1-element array for each element in the input
  Args : number of pieces to split into, list to split
  Ret  : a list of arrayrefs, as ([piece 1],[piece 2], ...)
  Side Effects: croaks if num_pieces is not at least 1
  Example:

=cut

sub balanced_split($@) {
  my ($num_pieces,@input) = @_;

  croak "balanced_split number of pieces must be a positive integer, not '$num_pieces'"
    unless $num_pieces > 0 && $num_pieces =~ /^\d+$/;

  return map {[$_]} @input
    if $num_pieces >= @input;

  my $base_jobsize = POSIX::floor(@input/$num_pieces);
  my @piece_sizes = ($base_jobsize+0)x$num_pieces;
  my $remainder = @input - @piece_sizes*$piece_sizes[0];
  $_++ foreach @piece_sizes[0..($remainder-1)];

  return map {
    [splice @input,0,$_]
  } @piece_sizes;
}

=head2 odds

  Usage: my @e = odds  'foo', 'bar', 'baz', 'bloo', 'blorg';
         #returns 'bar','bloo'
  Desc : given a list, return the elements at odd-indexed positions
  Args : a list
  Ret  : a list

=cut

sub odds {
  my $c;
  return grep {! ((++$c) % 2)  } @_;
}


=head2 evens

  Usage: my @o = evens 'foo', 'bar', 'baz', 'bloo', 'blorg'
         # returns 'foo','baz','blorg'
  Desc : given a list, return the elements at even-index positions
  Args : a list
  Ret  : a list

=cut

sub evens {
  my @ret;
  my $c;
  return grep { (++$c) % 2 } @_;
}

=head2 index_where

  Usage: my $i = index_where {$_ eq $foo} @list
  Desc : return the array index of the first element in the
         given list where the given block evaluates to true,
         or -1 if it was never true
  Args : BLOCK  list
  Ret  : array index, or -1 if not found
  Side Effects: none
  Example:

   my $foo_location = index_where {$_ eq $foo} @list;
   if($foo == -1) {
     print "foo was not found";
   } else {
     print "foo was at index $foo_location";
   }

=cut

sub index_where(&@) {
  my $code = shift;
  my $c = 0;
  return $c-1 if first {$c++; &{$code}()} @_;
  return -1;
}


=head2 list_join

  Usage: my @list = list_join \@glue, @otherlist;
  Desc : joins the elements of the list together using the given glue
  Args : arrayref of glue elements (can contain multiple),
         list of elements to join
  Ret  : list of elements, each glued together with the given glue
  Side Effects: none
  Example:

     list_join ['a','b'], 1..4;
     #returns 1,'a','b',2,'a','b',3,'a','b',4

     list_join [['c','d']], 1..4'
     #returns 1,['c','d'],2,['c','d'],3,['c','d'],4

=cut

sub list_join($@) {
  my $glue = shift;
  my $end  = pop;
  return (map {$_,@$glue} @_),$end;
}

=head1 SEE ALSO

L<List::Util>

=head1 AUTHORS

Robert Buels

=cut

###
1;#do not remove
###
