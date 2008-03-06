#!/usr/bin/perl
use strict;
use CXGN::DB::Connection;
# and Term::ReadKey, included below


=head1 NAME

  CXGN::DB::InsertDBH - prompts user for password, then invokes CXGN::DB::Connection

=head1 SYNOPSIS

Really, it's just like CXGN::DB::Connection, except it'll override 
any password you give it.

  use CXGN::DB::InsertDBH;
  my $dbh = CXGN::DB::InsertDBH::connect({
  					dbname => 'sandbox',
  					dbhost => 'scopolamine',
  					dbschema => 'public', 
  					dbargs => {AutoCommit => 0, 
  						   RaiseError => 1}});

=head1 DESCRIPTION

Prompts the user for a username and password; and then, asks
DB::Connection for a $dbh. You should use this so you don't have to
encode a password anywhere.

=head2 Methods

=over 12

=item connect()

Provide the same arguments you would give to CXGN::DB::Connection. 
However, providing dbuser or dbpass is useless, since those will 
be overwritten. 

=item commit_prompt($prompt_message, $yes_regexp, $no_regexp, $stern_message)

Print $prompt_message to STDOUT, then read one line of response from the
user.  If the line matches $yes_regexp, try to commit; if it matches $no_regexp,
try to rollback; if it matches neither print $stern_message.  Do this until
either commit or rollback is performed.

=back

=head1 LICENSE

Same license as all the rest of CXGN. Questions? Contact sgn-feedback@sgn.cornell.edu

=head1 AUTHOR

Beth, mostly, I think.

=head1 BUGS

who, me?

=head1 SEE ALSO

CXGN::DB::Connection

=cut





package CXGN::DB::InsertDBH;


open (my $TTY, '>', '/dev/tty') or die "what the heck - no TTY??\n";


sub connect {
  # connects with CXGN::DB::Connection, prompting you for
  # a username and password.
  my ($dbargs) = @_;

  if ($$dbargs{'dbprofile'}) {
    if (eval {require Bio::GMOD::Config;
          Bio::GMOD::Config->import();
          require Bio::GMOD::DB::Config;
          Bio::GMOD::DB::Config->import();
          1;  } ) {
      my $gmod_conf = $ENV{'GMOD_ROOT'} || "/var/lib/gmod" ?
                  Bio::GMOD::Config->new($ENV{'GMOD_ROOT'} || "/var/lib/gmod") :
                  Bio::GMOD::Config->new();

      my $db_conf = Bio::GMOD::DB::Config->new($gmod_conf,
                                               $$dbargs{'dbprofile'});
      my $dbh = $db_conf->dbh;
      if ($dbh) {
        return $dbh;
      } 
      else {
        die "You provided the dbprofile option, but I couldn't use it to connect\n";
      }
    }
    else {
      die "You provided the dbprofile option, but I couldn't load Bio::GMOD::Config\n";
    }
  }

  ######################################################
  # we will prompt the user for a username and password.
#  my $un = $ENV{"USER"};
  my $un = "postgres";
  print $TTY "Halt! Who goes there? (default \"$un\"): ";

  use Term::ReadKey;
  ReadMode 'normal';
  my $ln = ReadLine(0);
  chomp $ln;
  if ($ln) {
    $un = $ln;
  }
  $dbargs->{dbuser} = $un;

  print $TTY 'Password for write access: ';

  use Term::ReadKey;
  ReadMode 'noecho';
  $dbargs->{dbpass} = ReadLine(0);
  ReadMode 'normal';
  chomp $dbargs->{dbpass};
  print $TTY "\n"; #newline to let the user know the password was entered
  # done with username/password


  ###############################################
  # make some default parameters for ease of use, and for safety's sake
  #
  # the default behavior will be to modify the sandbox database, which is always harmless.
  # you must explicitly specify when you want your script to run on the real database.
  # this is another layer of protection, in addition to the devel/production distinction
  # and in addition to transactions. 
  unless(defined($dbargs->{dbname}))
  {
      $dbargs->{dbname}='sandbox';
  }
  # make darn sure autocommit defaults to off. this is redundant but redundant safety is good.
  unless(defined($dbargs->{dbargs}->{AutoCommit}))
  {
      $dbargs->{dbargs}->{AutoCommit}=0;
  }
  # make darn sure raiseerror defaults to on. this is redundant but redundant safety is good.
  unless(defined($dbargs->{dbargs}->{RaiseError}))
  {
      $dbargs->{dbargs}->{RaiseError}=1;
  }
  ###############################################  
  return
    CXGN::DB::Connection->new($dbargs); # returns a dbh
}

sub new {
	my $class = shift;
	return &connect(@_);
}


sub commit_prompt {
  my ($dbh, $prompt_message, $yes_regexp, $no_regexp, $stern_message) = @_;
  unless ($prompt_message) {
    $prompt_message = "Commit?\n(yes|no, default no)> ";
    $yes_regexp = "^y(es)\$"; #"
    $no_regexp = "^n(o)\$"; #"
    $stern_message = "Please enter \"yes\" or \"no\"";
  }
  if (-t *STDIN) {
    print $prompt_message;
    while (<STDIN>) {
      if ($_ =~ m|$yes_regexp|i) {
	print "Committing...";
	$dbh->commit;
	print "okay.\n";
	last;
      } elsif ($_ =~ m|$no_regexp|i) {
	print "Rolling back...";
	$dbh->rollback;
	print "done.\n";
	last;
      } else {
	print "$stern_message\n";
      }
    }
  } else {
    die ("commit_prompt called when STDIN isn't a tty.  That shouldn't happen.\n");
  }
}

###
1 #
###


