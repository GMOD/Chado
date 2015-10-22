#!/usr/bin/env perl
use strict;
use warnings;

use Getopt::Long;
#use lib '/home/cain/cvs_stuff/schema/chado/lib';
#use lib '/home/scott/cvs_stuff/schema/chado/lib';
use Bio::GMOD::Config;
use Bio::GMOD::DB::Config;
use ExtUtils::MakeMaker;  #to get prompt
use Cwd;

=head1 NAME

$0 - updates the schema of a Chado database if necessary

=head1 SYNOPSIS

  % gmod_update_chado.pl [options] 

=head1 COMMAND-LINE OPTIONS

  --force          Update the schema without prompt
  --dbprofile      Which database profile to use for updating

=head1 DESCRIPTION

=head1 AUTHOR

Scott Cain E<lt>scain@cpan.orgE<gt>

Copyright (c) 2011

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

my ($FORCE, $DBPROFILE, );

GetOptions(
    'force'         => \$FORCE,
    'dbprofile=s'   => \$DBPROFILE,
) or ( system( 'pod2text', $0 ), exit -1 );

$DBPROFILE ||= 'default';

my $gmod_conf = Bio::GMOD::Config->new();
my $version   = $gmod_conf->version();
my $gmod_root = $gmod_conf->gmod_root();
my $db_conf   = Bio::GMOD::DB::Config->new($gmod_conf, $DBPROFILE);
my $dbh       = $db_conf->dbh();

my $current_version = `gmod_chado_properties.pl --version --dbprof $DBPROFILE`;
chomp $current_version;

if ($current_version >= $version) {
    print "This instance of the Chado schema does not need updating.\n";
    exit(0);
}

if (!defined $FORCE) {
    print <<END

The schema needs updating; this will add columns and/or tables, and should
not delete any data, but we still advise you to back up your database
before continuing.  

END
;
    my $YN = prompt ("Continue with update?", "y");
    if ($YN =~ /^n/i) {
        print  "OK, exiting...\n";
        exit(0);
    }
}

#build path to get updates from
my $path = "$gmod_root/src/chado/schemas/$current_version-$version/diff.sql";
my $cwd  = getcwd;

my $dbuser = $db_conf->user;
my $dbport = $db_conf->port;
my $dbhost = $db_conf->host;
my $dbname = $db_conf->name;
my $schema = $db_conf->schema;

system("cp $path $cwd");
unless ($schema eq 'public') {
    system("perl -pi -e 's/public/$schema/g' diff.sql");
}

my $syscommand = "cat diff.sql | psql -U $dbuser -p $dbport -h $dbhost $dbname";
system($syscommand) == 0 or die "failed updating database";

#now update the schema version in the chadoprop table
system("gmod_chado_properties.pl --version $version --force --dbprof $DBPROFILE");

print "Updating $dbname complete.\n";

exit(0);

