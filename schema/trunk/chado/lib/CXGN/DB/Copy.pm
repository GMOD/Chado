# A module that adds a copy() function to CXGN::DB::Connection.

# The implementation here tries to take maximal advantage of the symmetries
# between copying to/from the database, both structurally and syntactically.
# To that end we wrap filehandles in a trivial class so we can have
# getline/putline methods on that class's instances, and we wrap pg_getline
# in a tiny method with a cleaner interface than DBD::Pg's pg_getline.

use strict;

# Note: this file adds a method to CXGN::DB::Connection.
use CXGN::DB::Connection;
package CXGN::DB::Connection;

sub copy {
  my $dbh = shift;
  my @args = CXGN::DB::Copy::helpers::process_args (@_);

  # @args now contains
  # ($direction, $csv, $table, $file, $delimiter, $null, $quote, $escape, $munge),
  # but we only need to deal with $direction and $file in this subroutine.
  my ($direction, $file, $delimiter, $munge) = @args[0,3,4,8];

  # Manufacture the command to put the backend into COPY mode.
  my $copycmd = CXGN::DB::Copy::helpers::copy_command ($dbh, @args);

  # We want to support copying to/from either named files or
  # already-open filehandles.  So if $file is a reference to
  # a glob, use it, and otherwise try opening it (and see
  # below for CXGN::DB::Copy::copy_filehandle).
  my $fh;
  if (ref ($file) eq "GLOB") {
    $fh = CXGN::DB::Copy::copy_filehandle->wrap_filehandle($file);
  } elsif (ref ($file) eq "") {
    my $fileh;
    if ($direction eq "in") {
      open ($fileh, "<$file") or die ("copy() couldn't open $file for reading: $!");
    } else {
      open ($fileh, ">$file") or die ("copy() couldn't open $file for writing: $!");
    }
    $fh = CXGN::DB::Copy::copy_filehandle->wrap_filehandle($fileh);
  } else {
    die ("copy doesn't know what to do with $file.");
  }

  # At this point all we need to do is to line up source/sink
  # methods.
  my ($source, $getline, $sink, $putline);
  if ($direction eq "in") {
    $source = $fh;
    $getline = "fh_getline";
    $sink = $dbh;
    $putline = "pg_putline";
  } else {
    $source = $dbh;
    $getline = "non_idiotic_pg_getline";
    $sink = $fh;
    $putline = "fh_putline";
  }

  # And here's the actual work.
#  print STDERR "!!".$copycmd."\n";
  $dbh->do ($copycmd); # Put the backend into COPY mode.
  my $line_count = 0;
  while (my $line = $source->$getline) { # As long as there's data from the source,
    if ($munge) {                        # maybe munge it,
      chomp ($line);
      my @a = split ($delimiter, $line);
      $line = join ($delimiter, $munge->(@a));
      if ($line) {
	$line = $line . "\n";
      }
    }
    if ($line) {                         # (the munger may return undef, meaning 'skip this one')
      $sink->$putline ($line);	         # and sink it.
      $line_count++;
    }
  }
  if ($direction eq "in") { # COPY ... TO requires an explicit close operation.
    $dbh->pg_endcopy;
  }
  return ($line_count);
}
# That's it for the copy operation.  The logic above is simplified by
# creating a symmetry between the interface to getting and putting
# lines from and to data sources.

# pg_getline has the documented interface of fgets (it takes a buffer
# and a size, and mutates the buffer), but doesn't seem to *stop*
# writing into the string after the specified number of characters.
# Awful.  Probably it's diddling unallocated memory or somesuch;
# consequently it's advisable to make the variable $sz below be at
# least as large as any line you're liable to receive from the
# database. In any case, if it should happen that pg_getline ever does
# honor its second argument, this routine ought to do the memory
# management properly.
sub non_idiotic_pg_getline {
  my ($dbh) = @_;
  my $sz = 4096;     # Totally arbitrary size.
  my $ret = "";
  while (1) {
    my $buf = " " x $sz;
    my $r;
    $r = $dbh->pg_getline ($buf, $sz);
    if ($r eq "") {
      last;
    }
    $ret .= $buf;
    if ($ret =~ m|$/$|) {
      last;
    }
  }
  if ($ret eq "") {
    return (undef);
  } else {
    return $ret;
  }

#  my $buf = " " x $sz;
#  my $r = $dbh->pg_getline ($buf, $sz);
#  if ($r eq "") {
#    return undef;
#  } else {
#    return $buf;
#  }

}

# As Perl's ordinary <> operator and print functions are not
# syntactically available as methods of anything, we introduce a tiny
# wrapper that makes getting a line and writing a line a method of a
# wrapped filehandle object.
#
# DO NOT USE OUTSIDE THIS FILE.  It's not very sturdy, but only meant
# for this one purpose.
package CXGN::DB::Copy::copy_filehandle;

# Constructor.
sub wrap_filehandle {
  my ($class, $fh) = @_;
  my $self = {};
  $self->{fh} = $fh;
  bless ($self, $class);
  return ($self);
}
sub fh_putline {
  my ($self, $line) = @_;
  my $fh = $self->{fh};
  print $fh $line;
}
sub fh_getline {
  my ($self) = @_;
  my $fh = $self->{fh};
  my $ln = <$fh>;
  return ($ln);
}

package CXGN::DB::Copy::helpers;

# Construct 
sub copy_command {
  my $dbh = shift;
  my ($direction, $csv, $table, undef, $delimiter, $null, $quote, $escape) = @_;

  my ($stream, $fmt, @copyargs);
  if ($direction eq "in") {
    $stream = "FROM STDIN";
  } else {
    $stream = "TO STDOUT";
  }
  if ($csv) {
    $fmt = "COPY %s %s DELIMITER AS %s NULL AS %s CSV QUOTE AS %s ESCAPE AS %s",
    @copyargs = ($delimiter, $null, $quote, $escape);
  } else {
    $fmt = "COPY %s %s WITH DELIMITER AS %s NULL AS %s",
    @copyargs = ($delimiter, $null);
  }
  my $command = sprintf $fmt, $table, $stream, map {$dbh->quote($_)} @copyargs;
  return ($command);
}

sub process_args {
  my %args = @_;
  # Source/sink must be either (fromtable AND tofile) OR (fromfile AND totable).
  unless ((exists ($args{fromtable}) && exists ($args{tofile})) ||
	  (exists ($args{fromfile}) && exists ($args{totable}))) {
    die ("copy must have (fromtable and tofile) or (fromfile and totable).");
  }

  my $direction;
  if (exists ($args{fromtable})) {
    $direction = "out";
  } else {
    $direction = "in";
  }
  my $csv;
  if ((exists ($args{quote}))|| exists ($args{escape})) {
    $csv = 1;
  }

  # Fill in canonical defaults for everything.
  unless (exists ($args{delimiter})) {
    $args{delimiter} = $csv ? "," : "\t";
  }
  unless (exists ($args{null})) {
    $args{null} = $csv ? "" : "\\N";
  }
  unless (exists ($args{quote})) {
    $args{quote} = "\""; #"
  }
  unless (exists ($args{escape})) {
    $args{escape} = "\\";
  }
  # Strictly, munging is not incompatible with CSV encoding,
  # but it's a pain to decode CSV (and there are variations in
  # how CSV is done, too).  So we'll just say that munging
  # is not allowed for CSV encodings.
  if ($csv && exists ($args{munge})) {
    die ("can't use a munge in CSV mode.  Sorry.");
  }
  unless (exists ($args{munge})) {
    $args{munge} = undef;
  }

  # This is a bit messy because I was having trouble with
  # hash slices.  Preserve the order of the return arguments,
  # or else change the other methods in this class.
  my @ret = ($direction, $csv);
  if ($direction eq "in") {
    push @ret, @args{"totable", "fromfile"};
  } else {
    push @ret, @args{"fromtable", "tofile"};
  }
  push @ret, @args{"delimiter", "null", "quote", "escape", "munge"};
  return (@ret);
}

1;


=head1 NAME

  CXGN::DB::Copy -- a wrapper for the COPY operation in PostgreSQL.

=cut

=head1 SYNOPSIS

  # CXGN::DB::Copy adds 1 notable method to the CXGN::DB::Connection
  # class. Use both CXGN::DB::Connection and CXGN::DB::Copy to get the
  # fancy copy method.
  use CXGN::DB::Connection;
  use CXGN::DB::Copy;

  # Copy from a table to a file, with default options for everything
  # else (i.e., delimiter will be tab, null will be
  # backslash-capital-n).  Tablename and filename must be strings.
  my $dbh = CXGN::DB::Connection->new();
  $dbh->copy(fromtable => "$tablename", tofile => "$filename");

  # Copy from /etc/passwd to a table (assumes a suitable table
  # structure):
  $dbh->copy (totable => "passwd",
	      fromfile    => "/etc/passwd",
	      delimiter => ":",
	      null => "");

  # Copy into a table from a file, upcasing the second field of each
  # line.  The munge function must return an array.
  my $munge = 
  $dbh->copy (totable => "sometable", fromfile => "somefile",
              munge => sub { return (shift, uc(shift), @_); });


=cut

=head1 DESCRIPTION

DBD::Pg offers a low-level interface to using the COPY operation in
the Postgres backend, but it's comparatively tedious to use.  This
module adds a method called copy() to CXGN::DB::Connection that has
approximately the same compact expression as psql's \copy builtin,
which is somewhat tidier than the explicit loops involved using the
DBD::Pg interface.

=head1 METHODS

=head2 copy

  Description: copies data to or from a database table from or to a
               file or filehandle, respectively.
  Arguments: similar to those taken by the Postgres backend's COPY
             command, viz:

             totable => name of a table
             fromfile => name of a file, or a filehandle

             fromtable => name of a table
             tofile => name of a file, or a filehandle

             delimiter => a string of length 1 that will delimit
                          fields in the file (default "\t")
             null => a textual representation for NULL (default "\\N")
             quote => a string of length 1 for quoting fields
                      containing whitespace in the file.
             escape => a string of length 1 for escaping quotes in
                       fields in the file

             munge => a subroutine.  See below.
   Returns: nothing
   Side effects: either populates a database table with stuff from a
                 file, or fills a file with stuff from a database table.
   Limitations: has whatever limits the Pg backend's COPY command
                does, e.g., you can't COPY to or from a view.
                Also has whatever bugs DBD::Pg has: in particular,
                DBD::Pg's pg_getline routine is likely subject to
                serious buffer overflow problems, which this module
                tries to avoid by assuming that no printed representation
                of a row in a table will be bigger than 4KiB.
   Unimplemented: COPY lets you select a subset of columns in the
                  database table, and to specify to always quote some
                  columns when doing CSV copies.  It'd be a SMOP to
                  add these, however.
   Notes:    Either totable and fromfile must be supplied, or tofile
             and fromtable must be supplied, and not both.

             The quote and escape arguments are used only with CSV
             formatted files.  I (Marty) haven't really stress-tested
             the CSV side of COPY too much, so you should perhaps
             expect some bugs there.

             The order of arguments is not significant.

             For certain simple filters and transforms between
             database and file, a subroutine may be supplied as the
             munge argument to the copy method.  The subroutine will
             receive the broken-up fields from the database or file as
             separate arguments, and should return a list (which will
             be joined using the copy operation's delimiter string and
             then passed on to the database or file) or undef (which
             will not be inserted into the table or written to the
             file).  For example, to copy a tabular file with
             identifiers prefixed by "SGN-U" into a table, stripping
             off the "SGN-U", you might say something like this:

             $dbh->copy(fromfile=>"file.tab", totable=>"sometable",
                        munge=>sub{ my $id=shift; $id =~s /^SGN-U/;
                                    return ($id, @_); } );

             There are a couple of caveats to using such a munge
             function: first, you can't supply a munge argument if the
             file is to be encoded/decoded in CSV format.  Second, the
             line of text from the file or database will be split
             using the delimiter character, and so it's important to
             ensure that the delimiter character doesn't appear in the
             fields in the database (you might want to supply a
             control character such as ^_ (C-_) for the delimiter to
             avoid this possibility).  Finally, while you can, in
             principle, do arbitrarily complex transformations with
             the munge function, probably you shouldn't.

=cut
