use strict;
package CXGN::Tools::Class;
use Carp;

BEGIN {
  our @EXPORT_OK = qw/parricide super_autoload/;
}
use base qw/Exporter/;
our @EXPORT_OK;

=head1 NAME

CXGN::Tools::Class - a bundle of little code snippets that make writing
   robust object-oriented code a little easier

=head1 DEPRECATED

This module is deprecated.  Do not use in new code.  Build new code with Moose instead, and sidestep the multiple-inheritance DESTROY problem that parricide() was meant to solve.

=cut


# =head1 DESCRIPTION

# none yet

# =head1 SYNOPSIS

# none yet

# =head1 FUNCTIONS

# All of the below functions are EXPORT_OK.

# =head2 parricide

#   Desc: Call DESTROY on all the classes in a list, making sure
#         not to do any one of them twice (originally from Conway
#         p. 176, modified significantly to not try to store state
#         in the destroyed object)
#   Args: (Object, @ISA of that object)
#   Ret : A list of all classes whose destructors get called by recursing
#         up the class inheritance graph.
#   Side Effects: Calls the DESTROY of all of the classes listed in ISA 
#                 (and so recursively on all their superclasses, etc.)
#                 with the given object as the first argument.
#   Example:

#     #in my witchy little class with multiple parent classes...
#     sub DESTROY {
#       # <any cleanups specific to your class>
#       return parricide ($self, our @ISA);
#     }


#   If all of your classes use this little jimmy, the destructors get
#   automagically chained together, which is usually a good thing.

#   Note: you *must* make sure that the return value from parricide gets
#   returned by your destructor, so that parricide can know which
#   superclasses it has destroyed.  Really, this is important.

# =cut

#my $indentation = 0;
sub parricide {
#  $indentation += 2;
  $| = 1;
  my ($object,@isa) = @_;

#   print "isa: " . ref($object) . ": ";
#   print join ", ", @isa;
#   print "\n";

  # What's going on here is that if your object is of class C, where
  # class C is a subclass of A and B, *and* A is a subclass of B, we
  # must ensure that we call A's destructor before B's (if we call B's
  # destructor first, and then A's destructor call's B's again, all 
  # sorts of badness may occur.  So we'll topologically sort the @isa
  # array into @toposort (sort things such that if one class is a 
  # descendant class of another in @isa, the subclass occurs first 
  # in the sorting).
  my @toposort = ();
  while (@isa) {                            # until @isa is empty,
    foreach my $class (@isa) {              # take a class in @isa
      my $degree = 0;                       # assume it's not anybody's superclass
      foreach my $otherclass (@isa) {       # for each otherclass in @isa
	unless ($class eq $otherclass) {    #
	  if ($otherclass->isa($class)) {   # if class is an ancestor of otherclass
	    $degree=1;                      # then class is not a leaf of the class graph.
	  }
	}
      }
      if ($degree == 0) {                   # if the class is a leaf (no subclasses)
	push @toposort, $class;             # push it onto the sorted array
	@isa = grep { !/$class/ } @isa;     # and remove it from @isa.
      }
    }
  }

#  warn ' 'x$indentation,"toposort: " . (join(", ", @toposort)). "\n";

  # Here's where we call destructors.  Each time we call a destructor,
  # we get back a list of all the ancestor classes whose destructors
  # get called when destroying any of the object's parents.  We need
  # to hold onto the names of classes that have already been killed, to
  # avoid calling their destructors more than once.
  my @already_dead = ();
  foreach my $parent (@toposort) {
#    warn ' 'x$indentation,"parent: " . $parent . "\n";
    my $destructor = $parent->can('DESTROY');
#    warn ' 'x$indentation, "already_dead 1: ".(join(" ", @already_dead))."\n";
    if ($destructor) {
      unless (grep {$parent eq $_} @already_dead) {
#	warn ' 'x$indentation,"calling DESTROY on $parent\n";
	my @killed = $object->$destructor();
	push @already_dead, ($parent,@killed);
      }
    }
#    warn ' 'x$indentation, "already_dead 2: ".(join(" ", @already_dead))."\n";
  }

#  warn ' 'x$indentation, "all done\n";

  # Finally, we return the class of our object.
#  $indentation -= 2;
  return @already_dead;
}


=head2 super_autoload

  Desc: check whether this object's superclass has an AUTOLOAD, and if so,
        call it as the given method name, with the rest of the given
        arguments, and return the result.  Otherwise, croak with a
        'method not found'.  This function is useful when you're writing
        an AUTOLOAD method, but your superclass also has an AUTOLOAD method,
        and you want to pass control to that AUTOLOAD method if your AUTOLOAD
        doesn't know how to handle the request.

        If the method name you pass is qualified with a package name
        (e.g. 'MySuperPackage::methodname'), this will call the method on
        that particular class.  Otherwise, it will call 'SUPER::methodname'.
  Args: the current object, the requested method name, array of arguments
  Ret : the results of the superclass function call
  Side Effects: calls
  Example:

    sub AUTOLOAD {
      my $this = shift;
      my $methodname = (split /::/,$AUTOLOAD)[-1];
      if($methodname =~ /get_/) {
	return 'something';
      } else {
	return supercall($this,$methodname,@_);
      }
    }

=cut

sub super_autoload {
  no strict 'refs';

  my $this = shift;
  my $method = shift;

  my ($package) = $method =~ /(.+)::[^:]+$/;
  $package ||= 'SUPER';
  my $fullmethod = "${package}::${method}";

  if($package->can($method) || $package->can('AUTOLOAD') ) {
    return $this->$fullmethod(@_);
  } else {
    croak "Method '$method' not found";
  }
}


# =head1 AUTHOR

# Robert Buels and Marty Kreuter

# =cut

###
1;#
###
