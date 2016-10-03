#!/usr/bin/env perl
use strict;
use warnings;

use DBI;
use Bio::GMOD::Config;
use Bio::GMOD::DB::Config;
use Data::Dumper;
use Getopt::Long;

=head1 NAME

interactions2SIF.pl - Export Chado interaction information in SIF format

=head1 SYNOPSIS

  % interactions2SIF..pl [options] > out.sif

=head1 DESCRIPTION

Reads the feature_relationship table to find interactions.  Outputs those
interactions in Simple Interaction File format (used by Cytoscape).

=head1 COMMAND-LINE OPTIONS

If no arguments are provided, dump_gff3.pl will dump all features
for the default organism in the database.  The command line options
are these:

=over 4

=item * feature_id 

Refines the search to nodes related to this feature_id

=item * cv

Refines the search to edges that have terms that come fromhis 

=back

=head1 AUTHOR

Ben Faga E<lt>faga@cshl.edu<gt>

Copyright (c) 2005

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

my ( $FEATURE_ID, $CV );

GetOptions(
    'feature_id:s' => \$FEATURE_ID,
    'cv:s'         => \$CV,
);

my $gmod_conf =
  $ENV{'GMOD_ROOT'}
  ? Bio::GMOD::Config->new( $ENV{'GMOD_ROOT'} )
  : Bio::GMOD::Config->new();
my $db_conf = Bio::GMOD::DB::Config->new( $gmod_conf, 'default' );

my $dbh = $db_conf->dbh;

my $select_sql = qq[
    select  f1.name as subject_name,
            f1.uniquename as subject_uniquename,
            cvt.name as cvterm,
            f2.name as object_name,
            f2.uniquename as object_uniquename
];
my $from_sql = qq[
    from    feature f1,
            feature f2,
            feature_relationship fr,
            cvterm cvt 
];
my $where_sql = qq[
    where   f1.feature_id = fr.subject_id 
            and f2.feature_id = fr.object_id 
            and cvt.cvterm_id = fr.type_id
];

if ($FEATURE_ID) {
    $where_sql .=
      " and (f1.feature_id = $FEATURE_ID or f2.feature_id = $FEATURE_ID) ";
}
if ($CV) {
    $from_sql   .= ", cv ";
    $where_sql .= " and cvt.cv_id = cv.cv_id and cv.name = '$CV' ";
}

my $sql_str = $select_sql . $from_sql . $where_sql;

my $sth = $dbh->prepare($sql_str);

$sth->execute();

while ( my $hashref = $sth->fetchrow_hashref ) {
    my $s_name       = $$hashref{subject_name};
    my $s_uniquename = $$hashref{subject_uniquename};
    my $o_name       = $$hashref{object_name};
    my $o_uniquename = $$hashref{object_uniquename};
    my $cvterm       = $$hashref{cvterm};

    $s_name = $s_uniquename unless $s_name;
    $o_name = $o_uniquename unless $o_name;

    print join( "\t", ( $s_name, $cvterm, $o_name, ) ), "\n";
}

