#!/usr/bin/perl
use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;

=pod

=head1 SYNOPSYS

  sudo create_postgres_wiki_user.pl [options] -u username -p password

=head1 OPTIONS

  -u username           The user name to be created (required)
  -p password           The password of the created account (required)
  --wiki_only           Do not create a linux or postgres user account
  --sudo                Give the created user account postgres and linux
                            superuser permission

=head1 DESCRIPTION

This script makes it easy to create new users, consolodating the creation of
user accounts for the linux operating system, the postgresql database and
the wiki.  This script will require a user account with sudo permission to 
do anything.

Required arguments are -u username and -p password, which will be used
for all account creation; that is, the account will have the same username
and password for the linux shell, postgres and the wiki.  Optional arguments
are --wiki_only, to skip creation of the shell and postgres accounts, and
--sudo, to give sudo (ie root access) permission to the created shell and
postgres accounts.

=head2 About Passwords

You will need to reenter the password for the linux command 'passwd'.  Also
there will be no password set for the PostgreSQL user account.  If you want
a password for the database, please see the PostgreSQL user manual for
information on setting it.

=head1 AUTHOR

Scott Cain, cain@cshl.edu

=head1 LICENSE

This may be distributed under the same license as Perl itself.

=cut

my ($USER, $PASS, $WIKI_ONLY, $SUDO, $HELP);

GetOptions(
             "u=s"         => \$USER,
             "p=s"         => \$PASS,
             "wiki_only"   => \$WIKI_ONLY,
             "sudo"        => \$SUDO,
             "help"        => \$HELP,
          ) or pod2usage(-verbose => 1, -exitval => 1);
pod2usage(-verbose => 1, -exitval => 1) if $HELP;

unless ($USER) {
    warn "The -u with a user name is required.  Please see `perldoc $0`.\n";
    exit(1);
}

unless ($PASS) {
    warn "The -p with a password is required.  Please see `perldoc $0`.\n";
    exit(1);
}

create_wiki_account();

exit(0) if $WIKI_ONLY;

create_linux_account();

create_postgres_account();

warn "Done\n";
exit(0);

sub create_wiki_account {
    system("php","createWikiUser.php",$USER,$PASS) == 0 or die;
}

sub create_linux_account {
    warn "Creating linux shell account...\n";
    system("/usr/sbin/useradd","-m",$USER) == 0 or die;
    system("passwd",$USER);

    if ($SUDO) {
        warn "Giving shell acount sudo...\n";
        my $allow_string = "$USER\tALL=\\(ALL\\)\tALL";
        system("echo $allow_string >> /etc/sudoers") == 0 or die; 
    }
}

sub create_postgres_account {
    warn "Creating PostgreSQL account...\n";
    my $su = $SUDO ? '-s' : ''; 
    my $createuser = "'createuser $su  $USER'";
    system("su -c $createuser postgres");
}
