#!/usr/bin/perl -w
use strict;

use Getopt::Long;
use lib '/home/cain/cvs_stuff/schema/chado/lib';
use lib '/home/scott/cvs_stuff/schema/chado/lib';
use Bio::GMOD::Config;
use Bio::GMOD::DB::Config;
use ExtUtils::MakeMaker;  #to get prompt
use Scalar::Util qw(looks_like_number);

=head1 NAME

$0 - reads or modifies the chadoprop table

=head1 SYNOPSIS

  % gmod_chado_properties.pl [options] 

=head1 COMMAND-LINE OPTIONS

 --version        Without an argument, returns the schema version
 --force          Provided with the version option to update the schema version
 --property       Get the value of a specific property ("all" to get all)
 --dbprofile      Specify a gmod.conf profile name (otherwise use default)

=head1 DESCRIPTION

The main use of this script is to get or set the schema version for use during
schema updates.  It can also get any named property (based on the cvterm in
the chadoprop table), or a list of all properties in the chadoprop table.

=head1 AUTHOR

Scott Cain E<lt>scain@cpan.orgE<gt>

Copyright (c) 2011

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

my ($VERSION, $FORCE, $PROPERTY, $DBPROFILE, );

GetOptions(
    'version:s'     => \$VERSION,
    'force'         => \$FORCE,
    'property=s'    => \$PROPERTY,
    'dbprofile=s'   => \$DBPROFILE,
) or ( system( 'pod2text', $0 ), exit -1 );

$DBPROFILE ||= 'default';

my $gmod_conf = Bio::GMOD::Config->new();
my $db_conf   = Bio::GMOD::DB::Config->new($gmod_conf, $DBPROFILE);
my $dbh       = $db_conf->dbh();

if ($FORCE and $VERSION >0) {
    set_version($VERSION, $dbh);
}
elsif (defined $VERSION) {
    my $version = determine_version($dbh);
}
elsif ($PROPERTY eq 'all') {
    my %prop = get_all_properties($dbh);
}
elsif ($PROPERTY) {
    my $prop = get_property($PROPERTY, $dbh);
}


exit(0);

sub set_version {
    my $version = shift;
    my $dbh     = shift;

    unless (looks_like_number($version) and $version > 1.19){
        my $set_query = "INSERT INTO chadoprop (type_id, value) VALUES ((SELECT cvterm_id FROM cvterm WHERE cv_id in (SELECT cv_id FROM cv WHERE name = 'chado_properties') AND name = 'version'),?)";
        my $sth = $dbh->prepare($set_query);
        $sth->execute($version) or die "database error: $!";
    }
    else {
        die "$version doesn't look like a valid version number.";
    }
}

sub determine_version {
    my $dbh = shift;

    #if chadoprop exists, query it

    #if cvprop table exists, then it's 1.11 (or 1.1, same schema)

    #if all_feature_names, then it's 1.0
}

sub get_all_properties {
    my $dbh = shift;
}

sub get_property {
    my $tag = shift;
    my $dbh = shift;
}
