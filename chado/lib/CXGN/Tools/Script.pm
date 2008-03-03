package CXGN::Tools::Script;
use strict;
use warnings;
use English;
use Carp;
use FindBin;

=head1 NAME

CXGN::Tools::Script - useful little functions for writing command-line
scripts

=head1 SYNOPSIS

coming soon

=head1 DESCRIPTION

coming soon

=head1 FUNCTIONS

All functions below are EXPORT_OK.

=cut

use base qw/Exporter/;

BEGIN {
  our @EXPORT_OK = qw(
		      out_fh
                      in_fh
		      lock_script
		      unlock_script
		      dprint
		      debugging
		     );
}
our @EXPORT_OK;


=head2 out_fh

  Usage: my $out_fh = out_fh($opt{o});
  Desc : get an output filehandle.
  Ret  : \*STDOUT if passed '-', '', or undef,
         or if given a filehandle, attempts to open it
         like ">$filename", dies on failure
  Args : optional filename to open
  Side Effects: might open a file for writing

=cut

sub out_fh {
  my ($filename) = @_;

  if(!$filename || $filename eq '-') {
    return \*STDOUT;
  } else {
    open my $f,">$filename"
      or croak "Cannot open '$filename' for writing: $!";
    return $f;
  }
}


=head2 in_fh

  Usage: my $in_fh = in_fh($opt{o});
  Desc : get an input filehandle.
  Ret  : \*STDIN if passed '-', '', or undef,
         or if given a filehandle, attempts to open it,
         dies on failure
  Args : optional filename to open
  Side Effects: might open a file for reading

=cut

sub in_fh {
  my ($filename) = @_;

  if(!$filename || $filename eq '-') {
    return \*STDIN;
  } else {
    open my $f,$filename
      or croak "Cannot open '$filename' for reading: $!";
    return $f;
  }
}


our $lockfile_name = File::Spec->catfile( File::Spec->tmpdir,
					  "$FindBin::Script.pid");

=head2 lock_script

  Usage: lock_script();
  Desc : attempt to acquire a system-wide lock, unique to whatever
         script you're running this from.  Use this and its companion
         unlock_script() when you have a script that needs to only
         have one instance running on a given host at one time.
  Args : none
  Ret  : 1 if successful at aquiring lock, 0 if not successful
  Side Effects: creates a lockfile in the temp directory specified by
                File::Spec->tmpdir
  Example:

     use CXGN::Tools::Script qw/lock_script unlock_script/;
     lock_script() or die "only run one instance";

     #do some stuff

     unlock_script();

=cut

sub lock_script {
  my $lock_fh;

  #check for a lockfile
  if( -f $lockfile_name ) {
    #if found, check if that PID is still running
    open( $lock_fh, $lockfile_name )
      or die "Could not read lock file '$lockfile_name'";
    my $pid = <$lock_fh>;
    chomp $pid;

    -d '/proc' or confess "The way we do lockfiles depends on there being a /proc dir.  sorry.";

    if( -d "/proc/$pid" ) {
      warn "Script still running with pid $pid.\n";
      return 0;
    } else {
      unlink $lockfile_name
	or croak "Could not unlink stale lock file '$lockfile_name': $!";
    }
  }

  open( $lock_fh, ">$lockfile_name" )
    or croak "Could not open '$lockfile_name' for writing";
  print $lock_fh "$PROCESS_ID\n";
  close $lock_fh;
  return 1;
}

# try to delete the script lockfile when the program ends
END {
  unlink $lockfile_name if -f $lockfile_name;
}


=head2 unlock_script

  Usage: unlock_script();
  Desc : release the system-wide lock on this script
  Args : none
  Ret  : nothing meaningful
  Side Effects:
  Example:

=cut

sub unlock_script {
  #delete our lockfile
  unlink( $lockfile_name )
    or ( -f $lockfile_name
	 and warn "Could not delete lockfile '$lockfile_name': $!"
       );
  return 1;
}


BEGIN {  #figure out a name for this script's debugging environment variable
  our $debugenv_name = $FindBin::Script;
  $debugenv_name =~ s/\.pl$//;
  $debugenv_name =~ s/[^a-zA-Z\d]//g;
  $debugenv_name = uc($debugenv_name).'DEBUG';
}
use constant DEBUG => ($ENV{our $debugenv_name} ? 1 : 0);

=head2 dprint

  Usage: dprint "foo! foofoofoo!\n";
  Desc : if this script's debugging environment variable is set, print
         the message to STDERR.  The name of the script's debugging
         environment variable is constructed from the script's name,
         plus DEBUG.  For example, the script do_some_weird_stuff.pl
         would have a debugging environment variable named
         DOSOMEWEIRDSTUFFDEBUG
  Args : same args as print()
  Ret  : same as print()
  Side Effects: might print things to STDERR
  Example:

    rob@toblerone:~$ DOSOMEWEIRDSTUFFDEBUG=1 ./do_some_weird_stuff.pl
    foo!  foofoofoo!
    rob@toblerone:~$ ./do_some_weird_stuff.pl
    rob@toblerone:~$

=cut

sub dprint(@) { if(DEBUG) { local $|=1; print STDERR @_; } }

=head2 debugging

  Usage: do_something() if debugging;
  Desc : same as dprint, except just returns 1 if the debug env is
         set, undef if not
  Args : none
  Ret  : 1 if debugging, 0 otherwise
  Side Effects: none

=cut

sub debugging {
  DEBUG ? 1 : 0;
}

=head1 AUTHOR(S)

Robert Buels

=cut

###
1;#do not remove
###
