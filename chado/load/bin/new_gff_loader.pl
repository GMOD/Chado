#!/usr/bin/perl -w
use strict;
use Bio::Tools::GFF;
use Bio::SeqIO;
use Getopt::Long;
use File::Temp qw(tempfile);
use lib '../../lib';
use Bio::GMOD::Load::GFF;

use constant DEBUG => 0;

my ( $ORGANISM, $SRC_DB, $GFFFILE, $CACHE_SIZE, $FORCE_LOAD );

GetOptions(
    'organism:s' => \$ORGANISM,
    'srcdb:s'    => \$SRC_DB,
    'gfffile:s'  => \$GFFFILE,
    'cache:s'    => \$CACHE_SIZE,
    'force'      => \$FORCE_LOAD,
  )
  or ( system( 'pod2text', $0 ), exit -1 );

$ORGANISM   ||= 'Human';
$SRC_DB     ||= 'DB:refseq';
$CACHE_SIZE ||= 1000;

die "\nYou must specify a GFF file\n" unless $GFFFILE;
die "$GFFFILE does not exist" unless ( -e $GFFFILE );

#create load object

my %load_args = (
                  gfffile   => $GFFFILE,
                  organism  => $ORGANISM,
                  src_db    => $SRC_DB,
                  cache_size=> $CACHE_SIZE,
                  pid       => $$
                );
$load_args{'force'} = $FORCE_LOAD if $FORCE_LOAD;

my $load = Bio::GMOD::Load::GFF->new(%load_args);

my $mtime = ( stat($GFFFILE) )[9];
$load->pub( $GFFFILE . " " . $mtime );


#deal with Term::ProgressBar set up

#iterate through GFF file (using Bio::Tools::GFF)
  #includes doing commits every CACHE passes
  #updating progressbar



my $gffio = Bio::Tools::GFF->new( -file => $load->tmpgff(), -gff_version => 3 );

my $feature_count += $load->load_segments($gffio);


my %feature;
while ( my $gff_feature = $gffio->next_feature() ) {

    my ($id) =
        $gff_feature->has_tag('ID')
      ? $gff_feature->get_tag_values('ID')
      : '';

    my ($parent) =
        $gff_feature->has_tag('Parent')
      ? $gff_feature->get_tag_values('Parent')
      : '';

    if ( ($id ne $gff_feature->seq_id) && ($gff_feature->seq_id ne '.') ) {
        $load->srcfeature($gff_feature->seq_id,
                          $load->search( name => $gff_feature->seq_id ) )
            unless $load->srcfeature($gff_feature->seq_id);

        unless ( $load->srcfeature($gff_feature->seq_id) ) {
            warn "\n" . "*" x 72 . "\n";
            warn "Unable to find a source feature id for the reference sequence in this line:\n";
            warn $gff_feature->gff_string . "\n\n";
            warn "That is, "
              . $gff_feature->seq_id
              . " should either have a entry in the \n";
            warn
              "feature table or earlier in this GFF file and it doesn't.\n\n";
            warn "*" x 72 . "\n";
            exit 1;
        }

        if ( !$load->dbxref($id) ) {
            my ($chado_dbxref) = $load->find_or_create(
                    table     => 'dbxref',
                    db_id     => $load->chado_db()->id,
                    accession => $id,
            );
            $load->dbxref($id, $chado_dbxref);
        }
    }

    $load->cache_cvterm( $gff_feature->primary_tag, $load->so()->id );
    my $chado_type = cache_cvterm( $gff_feature->primary_tag );
    
    my $chado_feature = $load->load_feature_locations($gff_feature,
                                                      $chado_type,
                                                      $id);

    $feature_count++;

    $feature{$id} = $chado_feature if $gff_feature->has_tag('ID');

    my @tags = $gff_feature->all_tags;
    foreach my $tag (@tags) {
        if ( $tag eq 'ID' ) {
            #this currently doesn't do anything.  ID is used elsewhere though
        }
        elsif ( $tag eq 'Parent' ) {
            $load->load_Parent_tag( $gff_feature, $chado_feature );
        }
        elsif ( $tag eq 'Alias' ) {
            $load->load_Alias_tag( $gff_feature, $chado_feature );
        }
        elsif ( $tag eq 'Name' ) {
            $load->load_Name_tag( $gff_feature, $chado_feature );
        }
        elsif ( $tag eq 'Target' ) {
            $load->load_Target_tag( $gff_feature, $chado_feature );
        }
        elsif ( $tag eq 'Note' ) {
            $load->load_Note_tag( $gff_feature, $chado_feature );
        }
        elsif ( $tag eq 'Ontology_term' || $tag =~ /^cvterm/) {
            $load->load_Ontology_term( $gff_feature, $chado_feature, $tag );
        }
        elsif ( $tag =~ /^[A-Z]/ ) {
            die "$0 doesn't handle '$tag' tags yet.  are you sure it's allowed by the GFF3 spec?";
        }
        elsif ( $tag =~ /^[a-z]/ ) {
            $load->load_custom_tags( $gff_feature, $chado_feature, $tag );
        }
    }

    if ( $feature_count % $CACHE_SIZE == 0 ) {
        $load->transaction(); #commit and flush the queue
    }
}

$load->transaction();
$gffio->close();

print "\n$feature_count features added\n";

my $seqs_loaded = $load->load_sequences();
print "\n$seqs_loaded sequences added\n";
print "Done\n";
exit 0;


=head1 NAME

gmod_load_gff3.pl - Load gff3 files into a chado database.

=head1 SYNOPSIS

  % gmod_load_gff3.pl --organism Human --srcdb 'DB:refseq' --gfffile refseq.gff

=head1 COMMAND-LINE OPTIONS

The following command line options are available.  Note that they
can be abbreviated to one letter.

  --cache      (optional, defaults to 1000)         The number of features to cache before
                                                    committing to the database
  --force      (optional, defaults to false)        Force the file to load, even if it has already
                                                    been loaded before
  --gfffile    (required)                           The name of the GFF3 file
  --organism   (optional, defaults to 'Human')      Common name of the organism
  --srcdb      (optional, defaults to 'DB:refseq')  The name of the source database

=head1 DESCRIPTION

The gmod_load_gff3.pl script takes genomic annotations in the GFF3 format
and loads them into several tables in chado.  (see
L<http://song.sourceforge.net/gff3.shtml> for a description of the format).
There are two types of data tags in GFF3: those that are part of the
specification, and those that aren't.  There is a short list of those that
are part of the spec (ie, reserved)  They include ID, Parent, Name, Alias,
Target, and Gap.  Tags that are part of the spec are first letter capitalized
and all other tags are all lower case.  All tags that are part of the spec
are handled as special cases during the insert, as well as some non-spec
tags.  These include 'description', tags beginning with 'db:' or 'DB:',
and tags beginning with 'cvterm:'.  All other tags are inserted into the
same table (featureprop).  If that is not the desired behavior for a given
tag, you may look at modifying the load_custom_tags subroutine.  If you
have a modification that you feel might be particularly useful, please
email your suggestion to the authors.

(Note that this behavior might better be module-ized, so that we could
provide an empty 'custom tag processing' module, that if installed, would
provide addtional processing of custom tags.  Add it to the todo list.)

=head2 NOTES

=over

=item The ORGANISM table

This script assumes that the organism table is populated with information
about your organism.  If you are unsure if that is the case, you can
execute this command from the psql command-line:

  select * from organism;

If you do not see your organism listed, execute this command to insert it:

  insert into organism (abbreviation, genus, species, common_name)
                values ('H.sapiens', 'Homo','sapiens','Human');

substituting in the appropriate values for your organism.

=item The DB table

This script assumes that the db table is populated with a row describing
the database that is the source of these annotations.  If you are unsure,
execute this command:

  select * from db;

If you do not see your database listed, execute this command:

  insert into db (name, contact_id) values ('DB:refseq',1);

Substituting for the name of your database.  A more complete insert
command may be appropriate in your case, but this should work in a pinch.

=item GFF3

The GFF in the datafile must be version 3 due to its tighter control of
the specification and use of controlled vocabulary.  Accordingly, the names
of feature types must be exactly those in the Sequence Ontology, not the
synonyms and not the accession numbers (SO accession numbers may be
supported in future versions of this script).  Also, in order for the load
to be successful, the reference sequences (eg, chromosomes or contigs)
must be defined in the GFF file before any features on them are listed.
This can be done either by the reference-sequence meta data specification,
which would be lines that look like this:

  ##sequence-region chr1 1 246127941

or with a standard GFF line:

  chr1  NCBI    chromosome      1       246127941       .       .       .       ID=chr1

Do not use both.  Note that if the '##sequence-region' notation is used,
this script will not be able to determine the type of sequence and therefore
will assign it the 'region' type which is very general. If that is not what
you want, use the standard GFF line to specify the reference
sequence.

=back

=head1 AUTHORS

Allen Day E<lt>allenday@ucla.eduE<gt>, Scott Cain E<lt>cain@cshl.orgE<gt>

Copyright (c) 2003-2004

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

