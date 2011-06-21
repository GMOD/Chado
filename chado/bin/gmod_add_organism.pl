#!/usr/bin/perl -w
use strict;

use Getopt::Long;
use lib '/home/cain/cvs_stuff/schema/chado/lib';
use lib '/home/scott/cvs_stuff/schema/chado/lib';
use Bio::GMOD::Config;
use Bio::GMOD::DB::Config;
use Bio::Chado::Schema;
use ExtUtils::MakeMaker;  #to get prompt

=head1 NAME

$0 - Adds an entry to the organism table 

=head1 SYNOPSIS

  % gmod_add_organism.pl [options] 

=head1 COMMAND-LINE OPTIONS

 --common_name
 --genus
 --species
 --abbreviation
 --comment
 --dbprofile      Specify a gmod.conf profile name (otherwise use default)

=head1 DESCRIPTION

This script will insert an entry into the Chado organism table.  The 
combination genus and species is required to be unique.  If either of
those items are not provided, or if that combination is already in the database,
the script will exit without doing anything.  Technically, those are the only
two things required, but it is strongly suggested that you provide a 
common_name and abbreviation.

=head1 AUTHOR

Scott Cain E<lt>scain@cpan.orgE<gt>

Copyright (c) 2011

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

my ($COMMON_NAME, $GENUS, $SPECIES, $ABBREVIATION, $COMMENT, $DBPROFILE);

GetOptions(
    'common_name=s' => \$COMMON_NAME,
    'genus=s'       => \$GENUS,
    'species=s'     => \$SPECIES,
    'abbreviation=s'=> \$ABBREVIATION,
    'comment=s'     => \$COMMENT, 
    'dbprofile=s'   => \$DBPROFILE,
) or ( system( 'pod2text', $0 ), exit -1 );

#collect information from the user if not provided on command line

if (!$GENUS or !$SPECIES) {
    print "\nBoth genus and species are required; please provide them below\n\n";
}

$COMMON_NAME ||=prompt("Organism's common name?");
$GENUS       ||=prompt("Organism's genus?");
$SPECIES     ||=prompt("Organism's species?");

my $suggest_abbr = substr($GENUS,0,1) . ".$SPECIES";

$ABBREVIATION||=prompt("Organism's abbreviation?", $suggest_abbr );
$COMMENT     =prompt("Comment (can be empty)?") unless defined $COMMENT;
$DBPROFILE   ||='default';

if (!$GENUS or !$SPECIES) {
    print "Both genus and species are required; exiting...\n";
    exit(1);
}


my $gmod_conf = Bio::GMOD::Config->new();
my $db_conf   = Bio::GMOD::DB::Config->new($gmod_conf, $DBPROFILE);

my $schema = Bio::Chado::Schema->connect($db_conf->dsn, 
                                         $db_conf->user,
                                         $db_conf->password ||"",
                                         { AutoCommit=>1 });

my $result = $schema->resultset("Organism::Organism")->find_or_create(
    { common_name   => $COMMON_NAME,
      genus         => $GENUS,
      species       => $SPECIES,
      abbreviation  => $ABBREVIATION,
      comment       => $COMMENT,
    }
);

if ($result->in_storage) {
    print "There was already an organism with that genus and species in the database;\nexiting...\n";
    exit(2);
}

exit(0);
