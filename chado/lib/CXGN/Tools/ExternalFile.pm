# ExternalFile.pm: routines for managing collections of files stored 
# external to the database.
# Time-stamp: <2005-08-05 11:31:58 kreuter>

package ExternalFile;
use strict;
use CXGN::DB::Connection;
use File::Copy;
use Carp;

# Global lexical things, all of which must be defined before doing
# anything useful with this package.
our $checksum_function = undef;
our $file_table = undef;
our $file_table_file_id_column = undef;
our $file_table_file_name_column = undef;
our $file_table_file_mime_column = undef;
our $file_table_file_cksum_column = undef;
our $database_handle = undef;
our $storage_system_root_directory = undef;
our $storage_system_directory_width = undef;
our $errstr = undef;

# Internal debugging routine
sub _debug_hang {
  my ($msg, $hangtime) = @_;
  unless ($hangtime) {
    $hangtime = $ENV["HANG_FOR"];
  }
  if ($msg) {
    print stderr $msg . "\n";
  }
  sleep ($hangtime);
  return (1);
}
sub internal_error {
  my ($msg) = @_;
  $errstr = "Internal error: $msg.";
  return (undef);
}
sub exceptional_condition {
  my ($msg) = @_;
  $errstr = "Exceptional condition: $msg.";
  return (undef);
}

## Things that have side-effects.
# This should probably load data from someplace.
sub _init {
  if ($checksum_function) {
    return;
  }
  $checksum_function = \&_md5sum_file;

  $file_table = "sgn.external_file";
  $database_handle = CXGN::DB::Connection->new()->dbh();
  $file_table_file_id_column = "external_file_id";
  $file_table_file_name_column = "external_file_name";
  $file_table_file_mime_column = "external_file_mime";
  $file_table_file_cksum_column = "external_file_cksum";
  $storage_system_root_directory = "/tmp/";
  $storage_system_directory_width = 5;
}
# This takes system command and a second argument, and returns the
# second argument if the system command exited with status 0.  This
# way, we effectively invert the sense of system(), and also let
# functions that would simply end by calling system() return something
# informational to their callers.
sub _system {
  my ($cmd, $ret) = @_;
  unless (system ($cmd)) {
    return $ret;
  }
  return (undef);
}
sub _ensure_directory_exists {
  my ($directory) = @_;
  return _system ("mkdir -p $directory", $directory);
}
# The next two are inverses.
sub _store {
  my ($checksum, $filename) = @_;
  my $destination = _find_cksum_file ($checksum);

  my $dirpart = $destination;
  $dirpart =~ s|/[^/]+$||;
  unless (_ensure_directory_exists ($dirpart)) {
    return (undef);
  }
  # Try linking first, then copy, then fail.
  if (link ($filename, $destination)) {
    return $destination;
  } elsif (copy ($filename, $destination)) {
    return $destination;
  } else {
    return (undef);
  }
}
sub _restore {
  my ($filename, $checksum) = @_;
  my $source = _find_cksum_file ($checksum);
  # Try linking first, then copy, then fail.
  if (link ($source, $filename)) {
    return $source;
  } elsif (copy ($source, $filename)) {
    return $source;
  } else {
    return (undef);
  }
}
sub _unlink {
  my ($discriminator, $datum) = @_;
  my $cksum;

  if ($discriminator eq "c") {
    $cksum = $datum;
  } elsif ($discriminator eq "i") {
    $cksum = _cksum_for_id ($datum);
  } else {
    # bug in caller
    internal_error ("unknown discriminator $discriminator passed to _unlink");
  }
  my $file = _find_cksum_file ($cksum);
  _system ("rm $file", $file);
}
# Furnish takes 3 arguments: a discriminator, a datum, and a directory name, and
# modifies the file system so that a file comes to exist in the named directory whose
# contents are those of the file corresponding to a datum whose type is the discriminator.
sub _furnish {
  my ($discriminator, $datum, $directory) = @_;
  unless ($checksum_function) {
    _init();
  }
  my $cksum = undef;
  my $target = undef;

  if ($discriminator eq "c") {
    $cksum = $datum;
  } elsif ($discriminator eq "i") {
    $cksum = _cksum_for_id ($datum);
  } else {
    # bug in caller
    internal_error ("unknown discriminator $discriminator passed to _furnish");
  }
  $target = filename_for_checksum ($cksum);

  if ($target) {
    if (_restore ("$directory/$target", $cksum)) {
      return "$directory/$target";
    } else {
      exceptional_condition ("failed to restore file $directory/$target for checksum $cksum");
    }
  } else {
    internal_error ("can't determine internal file name for checksum $cksum");
  }
}
sub _unintern {
  my ($discriminator, $datum, $directory) = @_;
  my $restored = _furnish (@_);
  if ($restored) {
    if (_delete ($discriminator, $datum)) {
      if (_unlink ($discriminator, $datum)) {
	return ($restored);
      } else {
	exceptional_condition ("failed to unlink file corresponding to $datum");
      }
    } else {
      exceptional_condition ("failed to delete database record corresponding to $datum");
    }
  } else {
    exceptional_condition ("failed to restore file corresponding to $datum");
  }
}
sub _serve {
  my ($discriminator, $datum) = @_;
  my $cksum = undef;
  if ($discriminator eq "i") {
    $cksum = _lookup ("c", $discriminator, $datum);
  } elsif ($discriminator eq "c") {
    $cksum = $datum;
  } else {
    internal_error ("unknown discriminator $discriminator passed to _serve");
  }
  my $path = _find_cksum_file ($cksum);

  # Okay, these two should be one query, not two.  So sue me.
  my $filename = _lookup ("f", $discriminator, $datum);
  my $mime = _lookup ("m", $discriminator, $datum);

  print "Content-Location: $filename\n";
  print "Content-Type: $mime\n";
  open (my $file, $path) or exceptional_condition ("failed to open file $path");
  while(read($file,$_,4096)) {
    print;
  }
  close ($file);
}
## Database operations
sub _insert {
  # Note: it's impossible to have a cksum unless _init has already
  # been called.
  my ($basename, $mime, $cksum) = @_;
  my $query = "INSERT INTO $file_table
               ($file_table_file_name_column,
                $file_table_file_mime_column,
                $file_table_file_cksum_column)
                VALUES
                ('$basename', '$mime', '$cksum');";
  if ($database_handle->do ($query)) {
    return (1);
  } else {
    exceptional_condition ("failed to insert database record for $basename");
  }
}

sub _delete {
  my ($discriminator, $datum) = @_;
  my $column = undef;

  my $query = undef;
  if ($discriminator eq "i") {
    $column = $file_table_file_id_column;
    $query = "DELETE FROM $file_table
              WHERE $column = $datum;";
  } elsif ($discriminator eq "c") {
    $column = $file_table_file_cksum_column;
    $query = "DELETE FROM $file_table
              WHERE $column = '$datum';";
  } else {
    # bug in caller
    internal_error ("unknown discriminator $discriminator passed to _delete");
  }
  if ($database_handle->do ($query)) {
    return (1);
  } else {
    exceptional_condition ("failed to delete database record for $datum");
  }
}

# Internal library functions without side-effects.
sub _find_cksum_file {
  my ($checksum) = @_;
  my $basename _lookup ("f", "c", $checksum);
  return "$storage_system_root_directory/$checksum-$basename";
}
sub _md5sum_file {
  my ($filename) = @_;
  my @foo = split " ", `md5sum $filename`;
  return $foo[0];
}
sub _find_file_mime_type {
  my ($filename) = @_;
  $_ = `file -i $filename`;
  chomp;
  $_ =~ s/.*:\s*//;
  $_ =~ s/;.*$//;
  return $_;
}
sub _lookup {
  my ($return_discriminator, $search_discriminator, $datum) = @_;
  my $return_column = undef;
  my $search_column = undef;

  if ($return_discriminator eq "f") {
    $return_column = $file_table_file_name_column;
  } elsif ($return_discriminator eq "i") {
    $return_column = $file_table_file_id_column;
  } elsif ($return_discriminator eq "c") {
    $return_column = $file_table_file_cksum_column;
  } elsif ($return_discriminator eq "m") {
    $return_column = $file_table_file_mime_column;
  } else {
    # bug in caller
    internal_error ("unknown return discriminator $return_discriminator passed to _lookup");
  }

  my $query = undef;
  if ($search_discriminator eq "i") {
    $search_column = $file_table_file_id_column;
    $query = "SELECT $return_column
              FROM $file_table
              WHERE $search_column = $datum;";
  } elsif ($search_discriminator eq "c") {
    $search_column = $file_table_file_cksum_column;
    $query = "SELECT $return_column
              FROM $file_table
              WHERE $search_column = '$datum';";
  } else {
    # bug in caller
    internal_error ("unknown search discriminator $search_discriminator passed to _lookup");
  }
  my ($ret) = $database_handle->selectrow_array ($query);
  return ($ret);
}
# Public interface
sub checksum_file {
  my ($filename) = @_;
  _init();
  return $checksum_function->($filename);
}
sub filename_for_checksum {
  _init();
  _lookup ("f", "c", @_);
}
sub filename_for_id {
  _init();
  _lookup ("f", "i", @_);
}
sub id_for_cksum {
  _init();
  _lookup ("i", "c", @_);
}
sub cksum_for_id {
  _init();
  _lookup ("c", "i", @_);
}

sub intern_file {
  _init();
  my ($filename) = @_;

  my $cksum = checksum_file ($filename);
  my $mime = _find_file_mime_type ($filename);
  $_ = `basename $filename`;
  chomp;
  my $basename = $_;
  # Begin db transaction here
  my $stored = _insert ($basename, $mime, $cksum);
  if ($stored) {
    if (_store ($cksum, $filename)) {
      # Commit db transaction here.
      return ($cksum);
    } else {
      print ("Failed to store file $filename in file storage.");
      # Rollback db transaction here.
      return (undef);
    }
  } else {
    print ("Failed to store file name $basename in database.");
    return (undef);
  }
}

sub furnish_file_by_checksum {
  _init();
  return _furnish ("c", @_);
}
sub furnish_file_by_id {
  _init();
  return _furnish ("i", @_);
}
sub unintern_file_by_id {
  _init();
  my ($id, $directory) = @_;
  return _unintern ("i", $id, $directory);
}
sub unintern_file_by_checksum {
  _init();
  my ($checksum, $directory) = @_;
  return _unintern ("c", $checksum, $directory);
}
sub serve_file_by_id {
  _init();
  my ($id) = @_;
  _serve ("i", $id);
}
sub serve_file_by_checksum {
  _init();
  my ($cksum) = @_;
  _serve ("c", $cksum);
}

=head1 NAME

ExternalFile - Manage files external to the database

=head1 SYNOPSIS

  # Add an existing file to ExternalFile's management.
  ExternalFile::intern_file('filename');
  
  # Retrieve a file by a checksum $cksum in directory $dir:
  my $filename = ExternalFile::furnish_file_by_checksum($cksum, $dir);
  
  # Retrieve a file by database serial number $id in directory $dir:
  my $filename = ExternalFile::furnish_file_by_id($id, $dir);
  
  # Retrieve a file by a checksum $cksum in directory $dir, and remove
  # it from ExternalFile's management:
  my $filename = ExternalFile::unintern_file_by_checksum($cksum, $dir);
  
  # Retrieve a file by a database serial number in directory $dir, and 
  # remove it from ExternalFile's management:
  my $filename = ExternalFile::unintern_file_by_id($id, $dir);
  
  # Lookup the file name associated with checksum:
  my $filename = ExternalFile::filename_for_checksum ($cksum);
  
  # Lookup the file name associated with database serial number:
  my $filename = ExternalFile::filename_for_id ($id);
  
  # Lookup the database serial number associated with a checksum:
  my $id = ExternalFile::id_for_checksum ($cksum);
  
  # Lookup the checksum associated with a database serial number:
  my $cksum = ExternalFile::checksum_for_id ($id);

=head1 DESCRIPTION

The idea here is to store files whose contents aren't related to
anything else in the database in a consistent way in the file system,
and keep the file metadata we care about (file name, cryptographic
hash, possibly MIME type) in a database table.  This way, programs that
need to serve or store these data files (images, spreadsheets, etc.)
can rely on a consistent, collision-free namespace (actually, two
namespaces: either the cryptographic checksums or the serial number in
the db table), and not need to deal with the details of file system
storage.  This also lets us separate the file system layout of the
external files from programs that use such files, and also verify that
the contents of files stored in the file system are what they're
supposed to be (at least asynchronously, e.g., by a cron job).

=head2 Functions

=over 12

=item intern_file($filename)

Takes the name of an existing file, adds a record to the external files
table if the file has not already been interned, and stores the file's
contents for future use.

Returns the file's checksum on success.  All modes of failure should
raise an exception (a die); internal programming errors in this module
should also raise an exception (a Carp::croak), but this function also
returns undef in case it fails without croaking or dying.

Note that this doesn't delete the original copy of the file.

=back

=over 12

=item furnish_file_by_cksum($cksum, $dir)

Modifies the file system so that a file comes to exist in directory $dir
whose contents match the cryptographic checksum $cksum and whose
basename is the basename under which the file was initially interned.
Returns the name of the file in the directory.

Notes: for increased performance, this function will try to provide this
file by means of a hard link; if this is impossible, it will create a
new copy of the file.  Also, users should *not* modify the furnished
file.  If you want to modify the file, use unintern_file_by_cksum, then
modify the file, then intern_file it again.

=back

=over 12

=item furnish_file_by_id($id, $dir)

Modifies the file system so that a file comes to exist in directory $dir
whose contents match the cryptographic checksum associated with serial
number $id in the external files table in the database, and whose
basename is the basename under which the file was initially interned.
Returns the name of the file in the directory.

Notes: for increased performance, this function will try to provide this
file by means of a hard link; if this is impossible, it will create a
new copy of the file.  Also, users should *not* modify the furnished
file.  If you want to modify the file, use unintern_file_by_id, then
modify the file, then intern_file it again.

=back

=over 12

=item unintern_file_by_checksum($cksum, $dir)

Modifies the file system so that a file comes to exist in directory $dir
whose contents match the cryptographic checksum $cksum and whose
basename is the basename under which the file was initially interned,
*and* removes the file from ExternalFile's management (i.e., by removing
the database record for the file, and removing the file from
ExternalFile's file system storage space).

Returns the name of the file in the directory.

Use this function if you intend to modify or replace a named file's
contents.

=back

=over 12

=item unintern_file_by_id($id, $dir);

Modifies the file system so that a file comes to exist in directory $dir
whose contents match the cryptographic checksum associated with serial
number $id in the external files table in the database, and whose
basename is the basename under which the file was initially interned,
*and* removes the file from ExternalFile's management (i.e., by removing
the database record for the file, and removing the file from
ExternalFile's file system storage space).

Returns the name of the file in the directory.

=back

=over 12

=item filename_for_checksum ($cksum);

Returns the basename associated with the cryptographic checksum $cksum
in external file database table.

=back

=over 12

=item filename_for_id ($id);

Returns the basename associated with the database table key $id in
external file database table.

=back

=over 12

=item id_for_checksum ($cksum);

Returns the database table key corresponding to cryptographic checksum
$cksum.

=back

=over 12

=item checksum_for_id ($id);

Returns the cryptographic checksum corresponding to database table key
$id.

=back

=head1 BUGS

Impedance mismatch.  Some things that ought to be done with database
transactions aren't.  See the source for details.


=head1 AUTHOR

The idea to identify file contents (or sometimes the contents of
sub-file blocks) with their cryptographic hashes comes up all over the
place (e.g., Linus Torvalds's git source code control system uses it);
it's at least as old as Plan 9's `fossil' storage engine (circa 1998).

=cut

1;

# CREATE TABLE sgn.external_file (
#   external_file_id BIGINT NOT NULL AUTO_INCREMENT,
#   external_file_name VARCHAR (255),
#   external_file_mime VARCHAR (64),
#   external_file_cksum VARCHAR (32), -- big enough for md5, not for sha1
#   PRIMARY KEY (external_file_id),
#   UNIQUE (external_file_cksum)
# );
