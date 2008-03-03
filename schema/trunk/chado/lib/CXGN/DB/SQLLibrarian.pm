use strict;

package SQLLibrarian;

=head1 NAME

SQLLibrarian -- manage libraries of SQL queries

=head1 SYNOPSIS

  # Assume some file named "CXGN/Some/Dir/MyLib.sqllib" in cwd
  # with contents like this:
  # Format:
  # query_name (modules, that, can, use, query) sql_query;
  fooq (MyClass, MyOtherClass, myprog.pl) SELECT * FROM my_table;
  barq (MyOtherClass)                     SELECT some_column FROM my_table;
  #EOF

  # Make a new librarian.
  my $librarian = SQLLibrarian->new;
  # Make the librarian aware of an SQL library.
  # The library name looks like a Perl module name,
  # though the file extension must be "sqllib".
  $librarian->load("CXGN::Some::Dir::MyLib");

  # Make some instances, to use with the librarian.
  my $inst  =  MyClass->new;
  # Suppose MySubClass is a subclass of MyClass.
  my $subi  = MySubClass->new;
  # Suppose MyOtherClass is not a sublcass of MyClass.
  my $oinst = MyOtherClass->new;

  # Instances of MyClass can use query fooq
  print $librarian->lookup("fooq", $inst) . "\n";
  # Instances of subclasses of MyClass can use query fooq.
  print $librarian->lookup("fooq", $subi) . "\n";
  # Instances of MyOtherClass can use barq
  print $librarian->lookup("barq", $oinst) . "\n";
  # But this will die.
  print $librarian->lookup("barq", $inst) . "\n";

=cut

=head1 DESCRIPTION

This module implements a very simple mechanism for factoring static
SQL queries out of Perl code while keeping SQL source text that can be
used directly in an SQL monitor, and also providing some Perl-specific
means of controlling which modules in a program have access to which
named SQL queries.

This module introduces a notion of a "query library", which associates
each query with (1) a name, (2) a list of Perl classes (packages)
whose instances may employ the named query.  A program that wishes to
use queries named in a library must create an SQLLibrarian instance to
manage a collection of query libraries.  The librarian instance is
instructed to "load" various libraries, at which time it checks that
no query names in loaded libraries conflict (this check also ensures
that all library files are openable, and that their contents parse
properly).  Thereafter the librarian can dole out queries when passed
(1) a query's name (2) an instance of a class whose class is a member
of the list of classes that may employ the query.

At present, query libraries are implemented as plain text files, with
a very simple format: first a query name, which has Perl identifier
syntax (\w character class); then a list of class names, separated by
commas, enclosed in parentheses; then a query string, which may span
several lines, and must terminate with a semicolon.  For example, the
following line

  fooq (MyClass, MyOtherClass, myprog.pl) SELECT * FROM my_table;

defines a query named "fooq", which may be employed by instances of
class "MyClass" and "MyOtherClass", whose query text is a simple
SQL query.

The query library namespace is essentially the Perl module namespace
at present: see the documentation of the load() method.

=cut

our $extension = "sqllib";

=head1 METHODS

=head2 new

 Usage: my $librarian = SQLLibrarian->new;
 Desc:  Create a new SQLLibrarian instance.
 Ret:   A gorilla.
 Args:  None.
 Side Effects: Makes a new instance.
 Example: See SYNOPSIS

=head2 load

 Usage: $librarian->load("some-library", "another-library" ...);
 Desc:  Adds libraries to the librarian's search list for looking
        up queries.  die()s in case any two queries in the union
        of all loaded libraries have the same name, or if any library
        is not readable, or if parsing any record in any library
        file fails.
 Ret:   Nothing
 Args:  A list of strings.  Library names look like Perl module names,
        and library files must end with the extension ".sqllib".
 Side Effects: Modifies the instance's subsequent query search behavior.
 Example: See the SYNOPSIS.
=cut

=head2 lookup

 Usage: $librarian->lookup("query_name", $some_instance)
        $librarian->lookup("query_name") # uses $0 for lookup
 Desc: Ask the librarian to look up a query by name for an instance,
        or for $0 (the name of the program).  The query named
        "query_name" for which instances of the class of
        $some_instance or the named program are allowed to use the 
        query.  If no such query is found, the program will die().
 Ret:   A DBI query string.
 Args:  A query name, and an optional instance of a class.
 Side Effects: Opens and closes a lot of directories.
               May open and close a lot of files.
 Example: See the SYNOPSIS.
 Note: It is almost certainly an extremely bad idea to alter the
       contents of any of the loaded query libraries between a load()
       and a lookup().  At present, if a library has loaded, the
       lookup will only die in case the instance is not permitted to
       employ the query.

=cut

sub new {
  my ($class) = @_;
  my $self = {};
  bless ($self, $class);
  return ($self);
}

# Just a little utility.  Pushes something only if it isn't
# already in the list.  Needs to be prototyped, to work like
# push.
sub pushnew (\@@) {
  my $array = shift;
  foreach my $arg (@_) {
    unless (grep { $_ eq $arg } @$array) {
      push @$array, $arg;
    }
  }
}

# Accumulate a string until a line ends in a semicolon that isn't
# in a comment.  Not for users.
sub read_record {
  my ($fh) = @_;
  my $ret = "";
  while (my $ln = <$fh>) {
    if ($ln) {
      # Get rid of comments.
      $ln =~ s/#.*$//;
      # Append whatever's left to $ret.
      $ret .= $ln;
      # If $ret now ends with a semicolon (and maybe whitespace),
      # quit the loop.
      if ($ret =~ m/;\s*/) {
	last;
      }
    } else {
      last;
    }
  }
  # Finally, trim leading (and so possibly all) whitespace out.
  $ret =~ s/\s*//;
  if ($ret) {
    return ($ret);
  } else {
    return (undef);
  }
}

# Given a (mildly tidied) string as returned by read_record,
# parse the string into 3 things: a name, a list of classes 
# (Perl package names), and an query string suitable for DBI's
# prepare method.
#XXX FIXME: it's possible for a line to end in an SQL string with a
#semicolon as the last character.  Perhaps ditch the regex monkeying
#and write a real parser. #'
sub parse_record {
  my ($record) = @_;
  unless (defined($record)) {
    return (undef);
  }
  my ($name, $classstr, $query) =
    ($record =~ m|(\w+)\s*\(\s*((?:[\w:.]+,\s*)*[\w:.]+)\s*\)\s*(.*);|s);
  unless ($name && $classstr && $query) {
    die ("parse error in parse_record with record: >>>$record<<<\n");
  }
  my @classes = split /[[:space:],]+/, $classstr;
  return ([$name, \@classes, $query]);
}

# Given a string that designates a library (at present, this
# can be either a file basename or a full pathname), return
# a full pathname if the instance can find such a file.
sub find_library {
  my ($self, $lib) = @_;
  my $fn = $lib;
  $fn =~ s|::|/|g;
  foreach my $dir (@INC) {
    my $fn = "$dir/$fn.$extension";
    if (-f $fn) {
      return ($fn);
    }
  }
  die ("can't find library file for name $lib");
}

sub make_library_iterator_sub {
  my ($self) = @_;
  my $idx = 0;
  return (sub { return ($self->{libs}->[$idx++]); });
}
sub make_query_iterator_sub {
  my ($self) = @_;
  return (sub { return (parse_record (read_record ($self->{fh}))); });
}

sub open_lib {
  my ($self, $fn) = @_;
  open (my $fh, $fn) or die ("couldn't open SQL library file $fn: $!");
  $self->{fh} = $fh;
}

sub close_lib {
  my ($self) = @_;
  close ($self->{fh}) or die ("couldn't close SQL library file $self->{fn}: $!");
  $self->{fh} = undef;
}

sub probe_file {
  my ($fn) = @_;
  open (my $fh, $fn) or die ("couldn't open file $fn: $!");
  close ($fh) or die ("couldn't close file handle $fh: $!");
}

sub load {
  my ($self) = @_;
  shift;
  foreach my $lib (@_) {
    pushnew @{$self->{libs}}, $lib;
  }
  my @query_names;
  my $libiter = make_library_iterator_sub ($self);
  while (my $lib = $libiter->()) {
    my $fn = $self->find_library($lib);
    probe_file ($fn);
    my $queryiter = make_query_iterator_sub ($self);
    while (my $record = $queryiter->()) {
      my ($name) = @$record;
      if (grep { $_ eq $name } @query_names) {
	die ("query name $name appears more than once in ".(join ", ", @{$self->libs}));
      } else {
	push @query_names, $name
      }
    }
  }

}

sub lookup {
  my ($self, $query_name, $requester) = @_;
  my $ret;
  unless (defined ($requester)) {
    $requester = $0;
  }
  my $libiter = make_library_iterator_sub($self);
  while (my $lib = $libiter->()) {
    my $fn = $self->find_library ($lib);
    $self->open_lib ($fn);
    eval {
      my $queryiter = make_query_iterator_sub ($self);
      while (my $record = $queryiter->()) {
	my ($name, $classes, $query) = @$record;
	if ($name eq $query_name) {
	  # If the requester is an instance and its class is in @$classes
	  if (((ref ($requester)) && (grep { $requester->isa($_) } @$classes)) ||
	      # if the requester is a string, treat it as a program name, see if its
	      # basename is in @$classes
	      (grep { $fn = $requester; $fn =~ s/^.*\///; if ($fn =~ m|\.pl$|) { $fn eq $_ } } @$classes) ||
	      # or if classes is empty
		(@$classes == 0)) {
	    $ret = $query;
	    last;
	  }
	}
      }
    };
    $self->close_lib;
    if ($@) {
      die ("error operating on library $lib, file $fn: $@\n");
    }
    if ($ret) {
      last;
    }
  }
  if ($ret) {
    return ($ret);
  } else {
    die ("can't find query named $query_name for requester " . ref($requester));
  }
}

1;
