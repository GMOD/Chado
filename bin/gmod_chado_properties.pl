#!/usr/bin/env perl 
use strict;
use warnings;

use Getopt::Long;
#use lib '/home/cain/cvs_stuff/schema/chado/lib';
#use lib '/home/scott/cvs_stuff/schema/chado/lib';
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

In older (pre-1.2) versions of Chado, updating the schema version has the 
side effect of creating the chadoprop table and a chado_properties cv.

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
    print "$version\n";
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

    if (looks_like_number($version) and $version > 1.19){
        #first make sure the chado_properties cv is available
        my $cp_query = "SELECT cv_id FROM cv WHERE name = 'chado_properties'";
        my $sth = $dbh->prepare($cp_query);
        $sth->execute();
        my ($cv_id) = $sth->fetchrow_array;

        my $new_chadoprop = 0;
        my $cvterm_id;
        unless ($cv_id) {
            #chado_properties is not available, so create it
            my $cv_insert = "insert into cv (name,definition) values ('chado_properties','Terms that are used in the chadoprop table to describe the state of the database')";
            $dbh->do($cv_insert);

            insert_version_term($dbh);
            $new_chadoprop = 1;
        }

        #check that the version term is available
        my $version_query = "SELECT cvterm_id FROM cvterm WHERE cv_id in (SELECT cv_id FROM cv WHERE name = 'chado_properties') AND name = 'version'";
        $sth = $dbh->prepare($version_query);
        $sth->execute();
        ($cvterm_id) = $sth->fetchrow_array;

        unless ($cvterm_id) {
            insert_version_term($dbh); 

            $sth->execute();
            ($cvterm_id) = $sth->fetchrow_array;
            $new_chadoprop = 1;
        }

        #find out if there's already a version in there
        # and if the chadoprop table exists
        my $table_query = "SELECT 1 FROM pg_tables WHERE tablename = ?";
        $sth = $dbh->prepare($table_query);
        $sth->execute('chadoprop');
        
        if ($sth->fetchrow_array) {
            #chadoprop table exists, so check in it for a value
            my $version_query = "SELECT value FROM chadoprop WHERE type_id in (SELECT cvterm_id FROM cvterm WHERE cv_id in (SELECT cv_id FROM cv WHERE name = 'chado_properties') AND name = 'version')";
            my $isth = $dbh->prepare($version_query); 
            $isth->execute();
            my ($old_version) = $isth->fetchrow_array();

            if (defined($old_version)) {
                #there is a version in there, update it
                my $update_query = "UPDATE chadoprop SET value = $version WHERE type_id = $cvterm_id";
                $dbh->do($update_query);
            }
            else {
                #no version but the table exists, (assume 1.2) and insert new value
                my $set_query = "INSERT INTO chadoprop (type_id, value) VALUES (?,?)";
                $sth = $dbh->prepare($set_query);
                $sth->execute($cvterm_id,$version) or die "database error: $!";
            }

        } 
        else {
            die "The chadoprop table doesn't seem to exist; perhaps there is a problem with Chado?";
        }

    }
    else {
        die "$version doesn't look like a valid version number.";
    }
}

sub insert_version_term {
    my $dbh = shift;

    $dbh->do("insert into dbxref (db_id,accession) values ((select db_id from db where name='null'), 'chado_properties:version')");
    $dbh->do("insert into cvterm (name,definition,cv_id,dbxref_id) values ('version','Chado schema version',(select cv_id from cv where name = 'chado_properties'),(select dbxref_id from dbxref where accession='chado_properties:version'));");

}

sub determine_version {
    my $dbh = shift;

    my $table_query = "SELECT 1 FROM pg_tables WHERE tablename = ?";
    my $sth = $dbh->prepare($table_query);

    #if chadoprop exists, query it
    $sth->execute('chadoprop');
    if ($sth->fetchrow_array) {
        my $version_query = "SELECT value FROM chadoprop WHERE type_id in (SELECT cvterm_id FROM cvterm WHERE cv_id in (SELECT cv_id FROM cv WHERE name = 'chado_properties') AND name = 'version')";

        my $isth = $dbh->prepare($version_query);
        $isth->execute();
        my ($version) = $isth->fetchrow_array();

        return $version if defined($version);

        #if the table exists but doesn't return a version, assume 1.2 (due to bug
        # in that release).
        return 1.2;
    }   

    #if cvprop table exists, then it's 1.11 (or 1.1, same schema)
    $sth->execute('cell_line');
    if ($sth->fetchrow_array) {
        return '1.11';
    }

    #if all_feature_names, then it's 1.0
    my $view_query = "SELECT 1 FROM pg_views WHERE viewname =?";
    $sth = $dbh->prepare($view_query);
    $sth->execute('all_feature_names');
    if ($sth->fetchrow_array) {
        return '1';
    }
 
    #must be something older
    return 'unknown';
}

sub get_all_properties {
    my $dbh = shift;

    my $props_query = "SELECT cvterm.name, cp.value, cp.rank FROM chadoprop cp JOIN cvterm ON (cvterm.cvterm_id = cp.type_id)";
    my $sth = $dbh->prepare($props_query);
    $sth->execute();

    print_table($sth);
    return;
}

sub get_property {
    my $tag = shift;
    my $dbh = shift;

    my $prop_query = "SELECT cvterm.name, cp.value, cp.rank FROM chadoprop cp JOIN cvterm ON (cvterm.cvterm_id = cp.type_id) WHERE cvterm.name = ?";
    my $sth = $dbh->prepare($prop_query);
    $sth->execute($tag);

    print_table($sth);
    return;
}

sub print_table {
    my $sth = shift;

    print "tag\tvalue\trank\n";
    while (my @row = $sth->fetchrow_array) {
        print join("\t", @row)."\n";
    }
    return;
}
