package CXGN::Tools::Run;
use strict;
use warnings;
use English;
use Carp;
use POSIX qw( :sys_wait_h);
use Time::HiRes qw/time/;

use File::Path;
use File::Temp qw( tempfile );
use File::Basename;
use File::Spec;
use Cwd;
use UNIVERSAL qw/isa/;

use File::NFSLock qw/uncache/;

use CXGN::VHost;
use CXGN::Tools::File qw/file_contents/;
use CXGN::Tools::List qw/any/;

use CXGN::Tools::Run::Run3;

use base qw/Class::Data::Inheritable/;

use constant DEBUG => $ENV{CXGNTOOLSRUNDEBUG} ? 1 : 0;
BEGIN {
  if(DEBUG) {
    use Data::Dumper;
  }
}
#debug print function
sub dbp(@) {
  #get rid of first arg if it's one of these objects
  return 1 unless DEBUG;
  shift if( ref($_[0]) && ref($_[0]) =~ /::/ and $_[0]->isa(__PACKAGE__));
  print STDERR '# dbg '.__PACKAGE__.': ',@_;
  print STDERR "\n" unless $_[-1] =~ /\n$/;
  return 1;
}
sub dprinta(@) {
  if(DEBUG) {
    local $Data::Dumper::Indent = 0;
    print STDERR join(' ',map {ref($_) ? Dumper($_) : $_} @_)."\n";
  }
  @_
}


=head1 NAME

CXGN::Tools::Run - run an external command, either synchronously
or asynchronously (in the background).

=head1 SYNOPSIS

  ############ SYNCHRONOUS MODE #############

  #just run the program, collecting its stderr and stdout outputs

  my $run = CXGN::Tools::Run->run( 'fooprogram',
                                   -i => 'myfile.seq',
                                   -d => '/my/blast/databases/nr',
                                   -e => '1e-10',
                                 );

  print "fooprogram printed '", $run->out, "' on stdout";
  print "and it printed '", $run->err, "' on stderr";

  ############ ASYNCHRONOUS MODE ############

  #run the program in the background while your script does other
  #things, or even exits

  my $sleeper = CXGN::Tools::Run->run_async('sleep',600);
  $sleeper->is_async
    or die "But I ran this as asynchronous!";
  $sleeper->alive
    or die "Hey, it's not running!\n";

  $sleeper->wait;    #waits for the process to finish

  $sleeper->die;     #kills the process
  $sleeper->cleanup; #don't forget to clean it up, deletes tempfiles


  ############ RUNNING ON THE CLUSTER #########

  #run the job, with a temp_base directory of /data/shared/tmp
  my $cjob = CXGN::Tools::Run->run_cluster('sleep',600, {temp_base => '/data/shared/tmp'});

  print "the Torque job id for that thing is ",$cjob->job_id,"\n";

  #alive, wait, die, and all the rest work the same as for async
  $cjob->cleanup; #don't forget to clean it up, deletes tempfiles


=head1 DESCRIPTION

This class is a handy way to run an external program, either in the
foreground, in the background, or as a cluster job, connecting files
or filehandles to its STDIN, STDOUT, and STDERR.  Furthermore, the
objects of this class can be saved and restored with Storable, letting
you migrate backgrounded jobs between different instances of the
controlling program, such as when you're doing a web or SOAP interface
to a long-running computation.

One important different between using this module to run things and
using system() is that interrupt or kill signals are propagated to
child processes, so if you hit ctrl-C on your perl program, any
programs *IT* is running will also receive the SIGTERM.

If you want to see debugging output from this module, set an
environment variable CXGNTOOLSRUNDEBUG to something true, like "1", or
"you know a biologist is lying when they tell you something is
_always_ true".

=head1 METHODS

=cut

#make some private accessors

use Class::MethodMaker
  [ scalar => [
	       'in_file',          #holds filename or filehandle used to provide stdin
	       'out_file',         #holds filename or filehandle used to capture stdout
	       'err_file',         #holds filename or filehandle used to capture stderr
	       '_temp_base',       #holds the object-specific temp_base, if set
               '_existing_temp',   #holds whether we're using someone else's tempdir
               '_told_to_die',     #holds whether this job has been told to die
	       '_working_dir',     #holds name of the process's working directory
  	       '_die_on_destroy',  #set to true if we should kill our subprocess
                                   #when this object is destroyed
	       '_pid',             #holds the pid of our background process, if any
	       '_jobid',           #holds the jobid of our cluster process, if any
	       '_jobdest',         #holds the server/queue destination
                                   #where we submitted a cluster job
	       '_error_string',    #holds our die error, if any
	       '_command',         #holds the command string that was executed
	       '_host',            #hostname where the command ran
	       '_start_time',      #holds the time() from when we started the job
	       '_end_time',        #holds the approximate time from when the job finished
	       '_exit_status',     #holds the exit status ($?) from our job
               {-default => 1},
	       '_raise_error',     #holds whether we throw errors or just store
                                   #them in _error. defaults to
	       '_procs_per_node',  #holds the number of processors to use for cluster
	                           #and other parallel calls
	       '_nodes',           #holds a torque-compliant nodelist, default of '1'
	                           #not used for regular and _async runs
	      ],
  ];

#keep a vhost object around for reading configuration variables
our $vhost = CXGN::VHost->new;

=head2 run

  Usage: my $slept = CXGN::Tools::Run->run('sleep',3);
         #would sleep 3 seconds, then return the object
  Desc : run the program and wait for it to finish
  Ret  : a new CXGN::Tools::Run object
  Args : executable to run (absolute or relative path, will also search $ENV{PATH}),
         argument,
         argument,
         ...,
         { in_file        => filename or filehandle to put on job's STDIN,
           out_file       => filename or filehandle to capture job's STDOUT,
           err_file       => filename or filehandle to capture job's STDERR,
           working_dir    => path of working directory to run the program,
           temp_base      => path under which to put this job's temp dir
                             defaults to the whatever the class accessor temp_base()
                             is set to,
           existing_temp  => use this existing temp dir for storing your out, err,
                             and die files.  will not automatically delete it
                             at the end of the script
           raise_error    => true if it should die on error, false otherwise.
                             default true
         }
  Side Effects: runs the program, waiting for it to finish

=cut

sub run {
  my ($class,@args) = @_;
  my $self = bless {},$class;

  $self->_common_prerun(\@args);

  #now start the process and die informatively if it errors
  $self->_start_time(time);

  my $curdir = cwd();
  eval {
    chdir $self->working_dir or die "Could not change directory into '".$self->working_dir."': $!";
    my $cmd = @args > 1 ? \@args : $args[0];
    run3 $cmd, $self->in_file, $self->out_file, $self->err_file, $self->tempdir;
    chdir $curdir or die "Could not cd back to parent working directory '$curdir': $!";
  }; if( $EVAL_ERROR ) {
    $self->_error_string($EVAL_ERROR);
    if($self->_raise_error) {
      #write die messages to a file for later retrieval by interested
      #parties, chiefly the parent process if this is a cluster job
      $self->_write_die($EVAL_ERROR);
      croak $self->_format_error_message($EVAL_ERROR);
    }
  }
  $self->_end_time(time);
  $self->_exit_status($?); #save the exit status of what we ran
  return $self;
}

=head2 run_async

  Usage: my $sleeper = CXGN::Tools::Run->run_async('sleep',3);
  Desc : run an external command in the background
  Ret  : a new L<CXGN::Tools::Run> object, which is a handle
         for your running process
  Args : executable to run (absolute or relative path, will also search $ENV{PATH}),
         argument,
         argument,
         ...,
         { die_on_destroy => 1, #default is 0, does not matter for a synchronous run.
           in_file        => filename or filehandle,
           out_file       => filename or filehandle,
           err_file       => filename or filehandle,
           working_dir    => path of working dir to run this program
           temp_base      => path under which to but this job's temp dir,
                             defaults to the whatever the class accessor temp_base()
                             is set to,
           existing_temp  => use this existing temp dir for storing your out, err,
                             and die files.  will not automatically delete it
                             at the end of the script
           raise_error    => true if it should die on error, false otherwise.
                             default true
         }
  Side Effects: runs the given command in the background, dies if the program
                terminated abnormally

  If you set die_on_destroy in the options hash, the backgrounded program
  will be killed whenever this object goes out of scope.

=cut

sub run_async {
  my ($class,@args) = @_;
  my $self = bless {},$class;

  $self->_common_prerun(\@args);

  #make sure we have a temp directory made already before we fork
  #calling tempdir() makes this directory and returns its name.
  #dbp is debug print, which only prints if $ENV{CXGNTOOLSRUNDEBUG} is set
  $self->dbp('starting background process with tempdir ',$self->tempdir);

  #make a subroutine that wraps the run3() call in order to save any
  #error messages into a file named 'died' in the process's temp dir.
  my $pid = fork;
#  $SIG{CHLD} = \&REAPER;
#  $SIG{CHLD} = 'IGNORE';
  unless($pid) {
    #CODE FOR THE BACKGROUND PROCESS THAT RUNS THIS JOB
    my $curdir = cwd();
    eval {
#       #handle setting reader/writer on IO::Pipe objects if any were passed in
      $self->in_file->reader  if isa($self->in_file,'IO::Pipe');
      $self->out_file->writer if isa($self->out_file,'IO::Pipe');
      $self->err_file->writer if isa($self->out_file,'IO::Pipe');

      chdir $self->working_dir
	or die "Could not cd to new working directory '".$self->working_dir."': $!";
#      setpgrp; #run this perl and its exec'd child as their own process group
      my $cmd = @args > 1 ? \@args : $args[0];
      run3($cmd, $self->in_file, $self->out_file, $self->err_file, $self->tempdir );
      chdir $curdir or die "Could not cd back to parent working dir '$curdir': $!";

    }; if( $EVAL_ERROR ) {
      #write die messages to a file for later retrieval by parent process
      $self->_write_die($EVAL_ERROR);
    }
    #explicitly close all our filehandles, cause the hard exit doesn't do it
    foreach ($self->in_file,$self->out_file,$self->err_file) {
      if(isa($_,'IO::Handle')) {
#	warn "closing $_\n";
	close $_;
      }
    }
    POSIX::_exit(0); #call a HARD exit to avoid running any weird END blocks
                     #or DESTROYs from our parent thread
  }
  #CODE FOR THE PARENT
  $self->_pid($pid);

  $self->_die_if_error;              #check if it's died
  return $self;
}

=head2 run_cluster

  Usage: my $sleeper = CXGN::Tools::Run->run_cluster('sleep',30);
  Desc : run a command on a cluster using the 'qsub' command
  Ret  : a new L<CXGN::Tools::Run> object, which is a handle
         for your running cluster job
  Args : executable to run (absolute or relative path, will also search $ENV{PATH}),
         argument,
         argument,
         ...,
         { die_on_destroy => 1, #default is 0
           in_file        => do not use, not yet supported for cluster jobs
           out_file       => filename, defaults to a new one created internally,
           err_file       => filename, defaults to a new one created internally,
           working_dir    => path of working dir to run this program
           temp_base      => path under which to put this job's temp dir
                             defaults to the whatever the class accessor temp_base()
                             is set to,
           existing_temp  => use this existing temp dir for storing your out, err,
                             and die files.  will not automatically delete it
                             at the end of the script
           raise_error    => true if it should die on error, false otherwise.
                             default true,
           nodes          => torque-compatible node list to use for running this job.  default is '1',
           procs_per_node => number of processes this job will use on each node.  default 1,
           queue          => torque-compatible job queue specification string, e.g. 'batch@solanine',
                             if running in a web environment, defaults to the value of the
                             'web_cluster_queue' conf key, otherwise, defaults to blank, which will
                             use the default queue that the 'qsub' command is configured to use.
         }
  Side Effects: runs the given command in the background, dies if the program
                terminated abnormally

  If you set die_on_destroy in the options hash, the job will be killed with `qdel`
  if this object goes out of scope.

=cut

sub run_cluster {
  my ($class,@args) = @_;

  my $self = bless {},$class;

  $self->_common_prerun(\@args);

  #check that qsub is actually in the path
  `which qsub` or croak "qsub command not in path, cannot submit jobs to the cluster.  Maybe you need to install the torque package?";

  #check that our out_file, err_file, and in_file are accessible from the cluster nodes
  sub cluster_accessible {
    my $path = shift;
#    warn "relpath $path\n";
    $path = File::Spec->rel2abs($path);
#    warn "abspath $path\n";
    return 1 if $path =~ m!(/net/solanine)?(/data/(shared|prod|trunk)|/home)!;
    return 0;
  }

  #Convert filehandle references.
  print "\nFilehandle input now supported, but in testing..." if grep { ref $_ } ($self->out_file, $self->err_file);
  $self->out_file($self->out_file()->filename) if ref($self->out_file);
  $self->err_file($self->err_file()->filename) if ref($self->err_file);

  my $tempdir = $self->tempdir;
  foreach my $file ($self->out_file,$self->err_file) {
    croak "tempdir ".$self->tempdir." is not on /data/shared or /data/prod, but needs to be for cluster jobs.  Do you need to set a different temp_base?\n"
      unless cluster_accessible($tempdir);

    unless(cluster_accessible($file)) {
      if(index($file,$tempdir) != -1) {
		croak "tempdir ".$self->tempdir." is not on /data/shared or /data/prod, but needs to be for cluster jobs.  Do you need to set a different temp_base?\n";
      } else {
		croak "'$file' must be in a subdirectory of /data/shared or /data/prod in order to be accessible to all cluster nodes";
      }
    }
  }
  
  #check that our working directory, if set, is accessible from the cluster nodes
  if($self->_working_dir_isset) {
    cluster_accessible($self->_working_dir)
      or croak "working directory '".$self->_working_dir."' is not a subdirectory of /data/shared or /data/prod, but should be in order to be accessible to the cluster nodes";
  }

  ###submit the job with qsub in the form of a bash script that contains a perl script
  #we do this so we can use CXGN::Tools::Run to write
  my $working_dir = $self->_working_dir_isset ? "working_dir => '".$self->_working_dir."'," : '';
  my $cmd_string = join(', ', map { my $s=$_;
				    $s=~s/'/\\'/g; #< quote for inserting into a single-quoted string
				    "'$s'"
				  } @args
		       ); #< xlate the comment string into perl array syntax
  $cmd_string = <<EOSCRIPT; #< we'll send a little shell script that runs a perl script
#!/bin/bash
#this is a shell script
cat <<EOF | perl
  #and this is a perl script
  use CXGN::Tools::Run;
  CXGN::Tools::Run->run($cmd_string,
                        { out_file => \\*STDOUT,
                          err_file => \\*STDERR,
                          existing_temp => '$tempdir',
                          $working_dir
                        });
EOF
EOSCRIPT
  dbp "running cmd_string:\n$cmd_string\n";

  $self->dbp("cluster running command '$cmd_string'");
  my $jobid; #< string to hold the job ID of this job submission
  my $ppn = $self->_procs_per_node;
  my $nodes = $self->_nodes;

  #note that you can use a reference to a string as a filehandle, which is done here:
  my $qsub = CXGN::Tools::Run->run(
				   dprinta( "qsub",
					    '-V',
					    -r => 'n', #< not rerunnable, cause we'll notice it died
					    -o => $self->out_file,
					    -e => $self->err_file,
					    -N => basename($self->tempdir),
					    ( $self->_working_dir_isset ? (-d => $self->working_dir)
					                                : ()
					    ),
					    ( $self->_jobdest_isset ? (-q => $self->_jobdest)
                                                                    : ()
					    ),
					    -l => "nodes=".$self->_nodes.":ppn=".$self->_procs_per_node,
					    { in_file  => \$cmd_string,
					      out_file => \$jobid,
					    }
					  )
				  );
  our $last_qstat_time = undef; #< force a qstat update

  #check that we got a sane job id
  chomp $jobid;
  $jobid =~ /^\d+(\.\w+)+$/
    or die "I don't understand what qsub printed on stdout: '$jobid'";

  $self->_jobid($jobid); #< remember our job id

  $self->_die_if_error;

  return $self;
}



#process the options hash and set the correct parameters in our object
#use for input and output
sub _common_prerun {
  my ($self,$args) = @_;
  my %options = ref($args->[-1]) ? %{pop @$args} : ();

  my @allowed_options = qw(
			   in_file
			   out_file
			   err_file
			   working_dir
			   temp_base
			   existing_temp
			   raise_error
			   die_on_destroy
			   procs_per_node
			   nodes
			   queue
			  );
  foreach my $optname (keys %options) {
    grep {$optname eq $_} @allowed_options
      or croak "'$optname' is not a valid option for run_*() methods\n";
  }

  #store our command string for later use in error messages and such
  $self->_command("'".join(' ',@$args)."'");

  #given a filehandle or filename, absolutify it if it is a filename
  sub abs_if_filename($) {
    my $name = shift;
    ref($name) ? $name : File::Spec->rel2abs($name);
  }

  #set out temp_base, if given
  $self->_temp_base( $options{temp_base} ) if defined $options{temp_base};

  #if an existing temp dir has been passed, verify that it exists, and
  #use it
  if(defined $options{existing_temp}) {
    $self->{tempdir} = $options{existing_temp};
    -d $self->{tempdir} or croak "existing_temp '$options{existing_temp}' does not exist";
    -w $self->{tempdir} or croak "existing_temp '$options{existing_temp}' is not writable";
    $self->_existing_temp(1);
  }

  #figure out where to put the files for the stdin and stderr
  #outputs of the program.  Make sure to use absolute file names
  #in case the working dir gets changed
  $self->out_file( abs_if_filename( $options{out_file}
				    || File::Spec->catfile($self->tempdir, 'out')
				  )
		 );
  $self->err_file( abs_if_filename( $options{err_file}
				    || File::Spec->catfile($self->tempdir, 'err')
				  )
		 );
  $self->in_file( abs_if_filename $options{in_file} );

  $self->working_dir( $options{working_dir} );

  dbp "Got dirs and files ",map {"'$_' "} $self->out_file, $self->err_file, $self->in_file, $self->working_dir;

  $self->_die_on_destroy(1) if $options{die_on_destroy};
  $self->_raise_error(0) if defined($options{raise_error}) && !$options{raise_error};

  $self->_procs_per_node($options{procs_per_node}) if defined $options{procs_per_node};
  $self->_nodes($options{nodes}) if defined $options{nodes};
  if(!defined $options{queue} && $ENV{MOD_PERL}) {
    $options{queue} = $vhost->get_conf('web_cluster_queue');
  }
  $self->_jobdest($options{queue}) if defined $options{queue};
}

=head2 tempdir

  Usage: my $dir = $job->tempdir;
  Desc : get this object's temporary directory
  Ret  : the name of a unique temp directory used for
         storing the output of this job
  Args : none
  Side Effects: creates a temp directory if one has not yet
                been created

=cut

#object accessor that returns a path to an exclusive
#temp dir for that object.  Does not actually
#create a temp directory until called.
sub tempdir {
  my ($self) = @_;
  #return our current temp dir if we have one
  return $self->{tempdir} if $self->{tempdir};

  #otherwise make a new temp dir
  #figure out the right place to make our temp dir
  my ($executable) = $self->_command =~ /^'([^'\s]+)/;
  $executable ||= '';
  if($executable) {
    $executable = basename($executable);
    $executable .= '-';
  }
  my $newtemp = File::Temp::tempdir("cxgn-tools-run-${executable}XXXXXXXX",
				    DIR     => $self->_temp_base() || __PACKAGE__->temp_base(),
				    CLEANUP => 0, #don't delete our kids' tempfiles
				   );
  -d $newtemp and -w $newtemp
    or die __PACKAGE__.": Could not make temp dir in ".__PACKAGE__->temp_base().": $!";

  $self->{tempdir} = $newtemp;
  dbp "Made new temp dir $newtemp\n";

  return $self->{tempdir};
}


=head2 temp_base

  Usage: CXGN::Tools::Run->temp_base('/data/local/temp');
  Desc : class method to get/set the base directory where these objects
         put their tempfiles.  This defaults to the value of the
         CXGN::VHost variable 'tempfiles_subdir', if set,
         otherwise, this is set to File::Spec->tmpdir (which is usually '/tmp')
  Ret  : directory name of place to put temp files
  Args : (optional) name of new place to put temp files

=cut


# return the base path where CXGN::Tools::Run classes
# should stick their temp dirs, indexes, whatever
__PACKAGE__->mk_classdata( temp_base => File::Spec->tmpdir );

#returns the name of the file to use for recording the die message from background jobs
sub _diefile_name {
  my $self = shift;
  return File::Spec->catfile( $self->tempdir, 'died');
}

#write a properly formatted error message to our diefile
sub _write_die {
  my ($self,$error) = @_;
  open my $diefile, ">".$self->_diefile_name
    or die "Could not open file ".$self->_diefile_name.": $error: $!";
  print $diefile $self->_format_error_message($error);
  return 1;
}

#croak()s if our subprocess terminated abnormally
sub _die_if_error {
  my $self = shift;
  if(($self->is_async || $self->is_cluster)
     && $self->_diefile_exists) {
    my $error_string = $self->_file_contents( $self->_diefile_name );
    #kill our child process's whole group if it's still running for some reason
    kill SIGKILL => -($self->pid) if $self->is_async;
    $self->_error_string($error_string);
    if($self->_raise_error && !($self->_told_to_die && $error_string =~ /Got signal SIG(QUIT|TERM)/)) {
      croak($error_string || 'subprocess died, but returned no error string');
    }
  }
}

sub _diefile_exists {
  my ($self) = @_;
  unless($self->is_cluster) {
    return -e $self->_diefile_name;
  } else {
    #have to do the opendir dance instead of caching, because NFS caches the stats
    opendir my $tempdir, $self->tempdir;
    while(my $f = readdir $tempdir) {
      dbp "is '$f' my diefile?\n";
      return 1 if $f eq 'died';
    }
    return 0;
  }
}

sub _file_contents {
  my ($self,$file) = @_;
  uncache($file) if $self->is_cluster;
  return file_contents($file);
}

#takes an error text string, adds some informative context to it,
#then returns the new string
sub _format_error_message {
  my $self = shift;
  my $error = shift || 'unknown error';
  $error =~ s/[\.,\s]*$//; #chop off any ending punctuation or whitespace
  my $of = $self->out_file;
  my $ef = $self->err_file;
  my @out_tail = do {
    unless(ref $of) {
      "last few lines of stdout:\n",`tail -20 $of`
    } else {
      ()
    }
  };
  my @err_tail = do {
    unless(ref $ef) {
      "last few lines of stderr:\n",`tail -20 $ef`
    } else {
      ()
    }
  };
  return join '', map {chomp; __PACKAGE__.": $_\n"} ( "command failed: ".$self->_command,
						      $error,
						      @out_tail,
						      @err_tail,
						    );
}


=head2 out_file

  Usage: my $file = $run->out_file;
  Desc : get the filename or filehandle that received the
         the stdout of the thing you just ran
  Ret  : a filename, or a filehandle if you passed in a filehandle
         with the out_file option to run()
  Args : none

=cut

#
#out_file() is generated by Class::MethodMaker above
#

=head2 out

  Usage: print "the program said: ".$run->out."\n";
  Desc : get the STDOUT output from the program as a string
         Be careful, this is in a tempfile originally, and if it's
         got a lot of stuff in it you'll blow your memory.
         Consider using out_file() instead.
  Ret  : string containing the output of the program, or undef
         if you set our out_file to a filehandle
  Args : none

=cut

sub out {
  my ($self) = @_;
  unless(ref($self->out_file)) {
    $self->dbp("Outfile is ",$self->out_file,"\n");
    return $self->_file_contents($self->out_file);
  }
  return undef;
}


=head2 err_file

  Usage: my $err_filename = $run->err_file
  Desc : get the filename or filehandle that received
         the STDERR output
  Ret  : a filename, or a filehandle if you passed in a filehandle
         with the err_file option to run()
  Args : none

=cut

#
#err_file() is generated by Class::MethodMaker above
#

=head2 err

  Usage: print "the program errored with ".$run->err."\n";
  Desc : get the STDERR output from the program as a string
         Be careful, this is in a tempfile originally, and if it's
         too big you'll run out of memory.
         Consider using err_file() instead.
  Ret  : string containing the program's STDERR output, or undef
         if you set your err_file to a filehandle
  Args : none

=cut

sub err {
  my ($self) = @_;
  unless(ref($self->err_file)) {
    return $self->_file_contents( $self->err_file );
  }
  return undef;
}

=head2 error_string

  Usage: my $err = $runner->error_string;
  Desc : get the string contents of the error
         we last die()ed with, if any.
         You would mostly want to check this
         if you did a run() with raise_error
         set to false
  Ret  : undef if there has been no error,
         or a string if there has been.
  Args : none
  Side Effects: none

=cut

sub error_string {
  shift->_error_string;
}

=head2 in_file

  Usage: my $infile_name = $run->in_file;
  Desc : get the filename or filehandle used for the process's stdin
  Ret  : whatever you passed in the in_file option to run(), if anything.
         So that would be either a filename or a filehandle.
  Args : none

=cut

#
#in_file() is defined by Class::MethodMaker above
#

=head2 working_dir

  Usage: my $dir = $run->working_dir
  Desc : get/set the full pathname (string) of the process's working dir.
         Defaults to the parent process's working directory.
  Ret  : the current or new value of the working directory
  Args : (optional) new path for the working directory of this process
  Side Effects: gets/sets the working directory where the process is/will be
                running
  Note: attempting to set the working directory on a process that is currently
        running will throw an error

=cut

sub working_dir {
  my ($self,$newdir) = @_;

  if($newdir) {
    -d $newdir or croak "'$newdir' is not a directory";
    $self->alive and croak "cannot set the working dir on a running process";
    $self->_working_dir($newdir);
  }

  $self->_working_dir(File::Spec->curdir) unless $self->_working_dir;
  return $self->_working_dir;
}

=head2 is_async

  Usage: print "It was asynchronous" if $runner->is_async;
  Desc : tell whether this run was asynchronous (backgrounded)
  Ret  : 1 if the run was asynchronous, 0 if not
  Args : none

=cut

sub is_async {
  my ($self) = @_;
  return $self->_pid_isset ? 1 : 0;
}

=head2 is_cluster

  Usage: print "It's a cluster job" if $runner->is_cluster;
  Desc : tell whether this run was done with a job submitted to the cluster
  Ret  : 1 if it's a cluster job, 0 if not
  Args : none

=cut

sub is_cluster {
  my ($self) = @_;
  return $self->_jobid_isset ? 1 : 0;
}

=head2 alive

  Usage: print "It's still there" if $runner->alive;
  Desc : check whether our background process is still alive
  Ret  : false if it's not still running or was synchronous,
         true if it's async or cluster and is still running.
         Additionally, if it's a cluster job, the true value
         returned will be either 'running' or 'queued'.
  Args : none
  Side Effects: dies if our background process terminated abnormally

=cut

sub alive {
  my ($self) = @_;
  $self->_die_if_error; #if our child died, we should die too
  if( $self->is_async) {
    #use a kill with signal zero to see if that pid is still running
    $self->_reap;
    if( kill 0 => $self->pid ) {
      system("pstree -p | egrep '$$|".$self->pid."'") if DEBUG;
      dbp 'background job '.$self->pid." is alive.\n";
      return 1;
    } else {
      system("pstree -p | egrep '$$|".$self->pid."'") if DEBUG;
      dbp 'background job ',$self->pid," is dead.\n";
      return;
    }
  } elsif( $self->is_cluster ) {
    #use qstat to see if the job is still alive
    return 'ending' if $self->_qstat('job_state') eq 'e';
    return 'running' if $self->_qstat('job_state') eq 'r';
    return 'queued' if $self->_qstat('job_state') eq 'q';
  }
  $self->_die_if_error; #if our child died, we should die too
  return;
}

#keep a cached copy of the qstat results, updated at most every X
#seconds, to avoid pestering the server too much

use constant MIN_QSTAT_WAIT => 1;
sub _qstat {
  my ($self,$field) = @_;

  our $jobstate;
  our $last_qstat_time;

  #return our cached job state if it has been updated recently
  unless( defined($last_qstat_time) && (time()-$last_qstat_time) <= MIN_QSTAT_WAIT ) {
  #otherwise, update it and return it
    $jobstate = {};
    my $servername = $self->job_id;
    $servername =~ s/^\d+\.//; #remove the numbers from the beginning of the job id to get its server name
#    warn "using server name $servername\n";
    open my $qstat, "qstat -f \@$servername |";
    my $current_jobid;
    while (my $qs = <$qstat>) {
      #      dbp "got qstat record:\n$qs";
      if ($qs =~ /\s*Job\s+Id\s*:\s*(\S+)/i) {
	$current_jobid = $1;
      } elsif ( my ($key,$val) = $qs =~ /(\S+)\s*[:=]\s*(\S+)/ ) {
	next if $key =~ /[=:]/;
	$jobstate->{$current_jobid}->{lc($key)} = lc $val;
      }
    }
    $last_qstat_time = time();
#      use Data::Dumper;
#      warn "qstat hash is now: ".Dumper($jobstate);
  }
#   else {
#     warn "skip qstat (".time().", $last_qstat_time)\n";
#   }

  if($jobstate->{$self->_jobid}) {
    return $jobstate->{$self->_jobid}->{$field};
  }
  return '';
}

=head2 wait

  Usage: my $status = $job->wait;
  Desc : this subroutine blocks until our job finishes
         of course, if the job was run synchronously,
         this will return immediately
  Ret  : the exit status ($?) of the job
  Args : none

=cut

sub wait {
  my ($self) = @_;
  $self->_die_if_error;
  if($self->is_async && $self->alive) { #< for backgrounded jobs
    $self->_reap(1); #blocking wait
  } elsif($self->is_cluster && $self->alive) {#< for cluster jobs
    #spin wait for the cluster job to finish
    do { sleep 2; $self->_die_if_error; } while $self->alive;
  }
  die 'sanity check failed, process is still alive' if $self->alive;
  $self->_die_if_error;
  return $self->exit_status;
}

=head2 die

  Usage: die "Could not kill job!" unless $runner->die;
  Desc : Reliably try to kill the process, if it is being run
         in the background.  The following signals are sent to
         the process at one second intervals until the process dies:
         HUP, QUIT, INT, KILL.
  Ret  : 1 if the process no longer exists once die has completed, 0 otherwise.
         Will always return 1 if this process was not run in the background.
  Args : none
  Side Effects: tries really hard to kill our background process

=cut

sub die {
  my ($self) = @_;
  $self->_told_to_die(1);
  if($self->is_async) {
    $self->_reap; #reap if necessary
    my @signal_sequence = qw/SIGQUIT SIGINT SIGTERM SIGKILL/;
    foreach my $signal (@signal_sequence) {
      if(kill $signal => $self->pid) {
	dbp "DIE(".$self->pid.") OK with signal $signal";
      } else {
	dbp "DIE(".$self->pid.") failed with signal $signal";
      }
      sleep 1;
      $self->_reap; #reap if necessary
      last unless $self->alive;
    }
    $self->_reap; #reap if necessary
    return $self->alive ? 0 : 1;
  } elsif( $self->is_cluster ) {
    dbp "trying first run qdel ",$self->_jobid,"\n";

    my $qdel = CXGN::Tools::Run->run( qdel => $self->_jobid );
    if($self->alive) {
      sleep 3;  #wait a bit longer
      if($self->alive) {  #try the del again
	dbp "trying again qdel ",$self->_jobid,"\n";
	$qdel = CXGN::Tools::Run->run( qdel => $self->_jobid );
	sleep 7; #wait again for it to take effect
	if($self->alive) {
	  die("Unable to kill cluster job ".$self->_jobid."\n",
	      $qdel->out,"\n",
	      $qdel->err,"\n",
	     );
	}
      }
    }
  }
  return 1;
}

=head2 pid

  Usage: my $pid = $runner->pid
  Ret  : the PID of our background process, or
         undef if this command was not run asynchronously
  Args : none
  Side Effects: none

=cut

sub pid { #just a read-only wrapper for _pid setter/getter
  shift->_pid;
}

=head2 job_id

  Usage: my $jobid = $runner->job_id;
  Ret  : the job ID of our cluster job if this was a cluster job, undef otherwise
  Args : none
  Side Effects: none

=cut

sub job_id {
  shift->_jobid;
}


=head2 host

  Usage: my $host = $runner->host
  Desc : get the hostname of the host that ran or is running this job
  Ret  : hostname, or undef if the job has not been run (yet)
  Args : none

=cut

sub host {
  my $self = shift;
  return $self->_host if $self->_host_isset;
  CORE::die 'should have a hostname by now' unless $self->is_async || $self->is_cluster;
  $self->_read_status_file;
  return $self->_host;

}

=head2 start_time

  Usage: my $start = $runner->start_time;
  Desc : get the number returned by time() for when this process
         was started
  Ret  : result of time() for just before the process was started
  Args : none

=cut

sub start_time {
  my $self = shift;
  return $self->_start_time if $self->_start_time_isset;
  CORE::die 'should have a start time by now' unless $self->is_async || $self->is_cluster;
  $self->_read_status_file;
  return $self->_start_time;
}

=head2 end_time

  Usage: my $elapsed = $runner->end_time - $runner->start_time;
  Desc : get the number returned by time() for when this process was
         first noticed to have stopped.
  Ret  : time()-type number
  Args : none

  This end time is approximate, since I haven't yet figured out a way
  to get an asynchronous notification when a process finishes that isn't
  necessarily a child of this process.  So as a kludge, pretty much every
  method you call on this object checks whether the process has finished and
  sets the end time if it has.

=cut

sub end_time {
  my $self = shift;
  if($self->is_async) {
    $self->_reap;
    return undef if $self->alive;
    $self->_read_status_file;
  }
  return $self->_end_time;
}
sub _read_status_file {
  my $self = shift;

  return unless $self->is_async || $self->is_cluster; #this only applies to async and cluster jobs
  return if $self->_end_time_isset;

  my $statname = File::Spec->catfile( $self->tempdir, 'status');
  uncache($statname) if $self->is_cluster;
  dbp "attempting to open status file $statname\n";
  open my $statfile, $statname
    or return;
  my ($host,$start,$end,$ret);
  while(<$statfile>) {
    dbp $_;
    if( /^start:(\d+)/ ) {
      $start = $1;
    } elsif( /^end:(\d+)/) {
      $end = $1;
    } elsif( /^ret:(\d+)/) {
      $ret = $1;
    } elsif( /^host:(\S+)/) {
      $host = $1;
    } else {
      dbp "no match: $_";
    }
  }
  $self->_start_time($start);
  $self->_host($host);
  $self->_end_time($end) if defined $end;
  $self->_exit_status($ret) if defined $ret;
}

=head2 exit_status

  Usage: my $status = $runner->exit_status
  Desc : get the exit status of the thing that just ran
  Ret  : undef if the thing hasn't finished yet, otherwise,
         returns the exit status ($?) of the program.
         For how to handle this value, see perlvar.
  Args : none

=cut

sub exit_status {
  my $self = shift;
  return $self->_exit_status if $self->_exit_status_isset;
  $self->_read_status_file;
  return $self->_exit_status;
}

=head2 cleanup

  Usage: $runner->cleanup;
  Desc : delete temp storage associated with this object, if any
  Ret  : 1 on success, dies on failure
  Args : none
  Side Effects: deletes any temporary files or directories associated
                with this object


  Cleanup is done automatically for run() jobs, but not run_async()
  or run_cluster() jobs.

=cut

sub cleanup {
  my ($self) = @_;
  $self->_reap if $self->is_async;
  if( $self->{tempdir} && -d $self->{tempdir} ) {
    rmtree($self->{tempdir}, DEBUG ? 1 : 0);
  }
}

=head2 do_not_cleanup

  Usage: $runner->do_not_cleanup;
  Desc : get/set flag that disables automatic cleaning up of this
         object's tempfiles when it goes out of scope
  Args : true to set, false to unset
  Ret  : current value of flag

=cut

sub do_not_cleanup {
  my ($self,$v) = @_;
  if(defined $v) {
    $self->{do_not_cleanup} = $v;
  }
  $self->{do_not_cleanup} = 0 unless defined $self->{do_not_cleanup};
  return $self->{do_not_cleanup};
}

=head2 property()

 Used to set key => values in the $self->{properties} namespace,
 for attaching custom properties to jobs

 Args: Key, Value (optional, to set key value)
 Ret: Value of Key
 Example: $job->property("file_written", 1);
          do_something() if $job->property("file_written");

=cut

sub property {
	my $self = shift;
	my $key = shift;
	return unless defined $key;
	my $value = shift;
	if(defined $value){
		$self->{properties}->{$key} = $value;
	}
	return $self->{properties}->{$key};
}

sub DESTROY {
  my $self = shift;
  $self->die if( $self->_die_on_destroy );
  $self->_reap if $self->is_async;
  if( $self->is_cluster ) {
    uncache($self->out_file) unless ref $self->out_file;
    uncache($self->err_file) unless ref $self->out_file;
  }
  $self->cleanup unless $self->_existing_temp || $self->is_async || $self->is_cluster || $self->do_not_cleanup || DEBUG;
}

sub _reap {
  my $self = shift;
  my $hang = shift() ? 0 : WNOHANG;
  if (my $res = waitpid($self->pid, $hang) > 0) {
    # We reaped a truly running process
    $self->_exit_status($?);
    dbp "reaped ".$self->pid;
  } else {
    dbp "reaper: waitpid(".$self->pid.",$hang) returned $res";
  }
}

=head1 SEE ALSO

L<IPC::Run> - the big kahuna

L<IPC::Run3> - this module uses CXGN::Tools::Run::Run3, which is
               basically a copy of this module in which the signal
               handling has been tweaked.

L<Proc::Background> - this module sort of copies this

L<Proc::Simple> - this module takes a lot of code from this

L<Expect> - great for interacting with your subprocess


This module blends ideas from the two CPAN modules L<Proc::Simple> and
L<IPC::Run3>, though it does not directly use either of them.  Rather,
processes are run with L<CXGN::Tools::Run::Run3>, the code of which
has been forked from IPC::Run3 version 0.030.  The backgrounding is
all handled in this module, in a way that was inspired by the way
L<Proc::Simple> does things.  The interface exported by this module is
very similar to L<Proc::Background>, though the implementation is
different.

=head1 AUTHOR

Robert Buels

=cut

###
1;#do not remove
###

