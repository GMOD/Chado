#!/usr/bin/perl -w

use strict;
use Bio::Tools::GFF;
use Chado::AutoDBI;
use Chado::LoadDBI;
use Getopt::Long;

=head1 NAME

load_gff3.pl - Load gff3 files into a chado database.

=head1 SYNOPSIS

  % load_gff3.pl --organism Human --srcdb refseq --gfffile refseq.gff

=head1 DESCRIPTION

See the notes; there is plenty there.

=head2 NOTES

=over

=item What this script doesn't do yet

It does very limited parsing of the group column (column 9).  Notes are not parsed.
Nor are similarity/match/target data parsed.  Sequence is not handled yet either,
though it shouldn't be to hard to add.

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

  insert into db (name, contact_id) values ('refseq',1);

Substituting for the name of your database.  A more complete insert
command may be appropriate in your case, but this should work in a pinch.

=item GFF3

The GFF in the datafile must be version 3 due to its tighter control of
the specification and use of controlled vocabulary.  Accordingly, the names
of feature types must be exactly those in the Sequence Ontology, not the
synonyms and not the accession numbers.  Also, in order for the load
to be successful, the reference sequences (eg, chromosomes or contigs)
must be defined in the GFF file before any features on them are listed.
This can be done either by the reference-sequence meta data specification,
which would be lines that look like this:

  ##sequence-region chr1 1 246127941  ----except that this isn't supported
  yet--can I get Bio::Tools::GFF to give me this info?

or with a standard GFF line:

  chr1	NCBI	chromosome	1	246127941	.	.	.	ID=chr1

=back

=head1 COMMAND-LINE OPTIONS

The following command line options are required.  Note that they
can be abbreviated to one letter.

  --organism <org name>      Common name of the organism
  --srcdb    <dbname>        The name of the source database
  --gfffile  <filename>      The name of the GFF3 file

=head1 AUTHOR

Allen Day E<lt>allenday@ucla.eduE<gt>, Scott Cain E<lt>cain@cshl.orgE<gt>

Copyright (c) 2003

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  

=cut

my ($ORGANISM, $SRC_DB, $GFFFILE);

GetOptions('organism:s'       => \$ORGANISM,
           'srcdb:s'          => \$SRC_DB,
           'gfffile:s'        => \$GFFFILE
          ) or (system('pod2text',$0), exit -1); 

$ORGANISM ||='Human';
$SRC_DB   ||= 'refseq';
$SRC_DB   ="DB:$SRC_DB";
$GFFFILE  ||='test.gff';

Chado::LoadDBI->init();

my %typemap;

my %feature = ();
my %srcfeature = ();
my %dbxref = ();

my $feature_count = 0;

my($chado_organism) = Chado::Organism->search(common_name => $ORGANISM );
my($chado_db)       = Chado::Db->search(name => $SRC_DB);
my($part_of)        = Chado::Cvterm->search(name => 'part_of');

die "The organism '$ORGANISM' could not be found. Did you spell it correctly?"
     unless $chado_organism;

die "The database '$SRC_DB' could not be found. Did you spell it correctly?"
     unless $chado_db;

die "The cvterm_id for 'part_of' could not be found
That is a pretty serious problem with you database!\n" unless $part_of;

my $gffio = Bio::Tools::GFF->new(-file => $GFFFILE, -gff_version => 3);

#check for a synonym type in cvterm--if it's not there create it
#and a corresponding entry in cv

my ($synonym_type) = Chado::Cvterm->search(name => 'synonym');
unless ($synonym_type) {
  my ($cv_entry) = Chado::Cv->find_or_create({
                    name       => 'autocreated',
                    definition => 'auto created by load_gff3.pl'
                                             }); 
  ($synonym_type) = Chado::Cvterm->find_or_create({
                    name       => 'synonym',
                    cv_id      => $cv_entry->cv_id,
                    definition => 'auto created by load_gff3.pl'
                                                  });
}
die "Unable to create a synonym type in cvterm table."
    unless $synonym_type;

my ($note_type) = Chado::Cvterm->search(name => 'note');
my ($note_type  = Chado::Cvterm->search(name => 'Note') unless $note_type;
unless ($note_type) {
  my ($cv_entry) = Chado::Cv->find_or_create({
                    name       => 'autocreated',
                    definition => 'auto created by load_gff3.pl'
                                             });
  ($note_type) = Chado::Cvterm->find_or_create({
                    name       => 'note',
                    cv_id      => $cv_entry->cv_id,
                    definition => 'auto created by load_gff3.pl'
                                                  });
}
die "Unable to create note type in cvterm table."
    unless $note_type;

while(my $gff_feature = $gffio->next_feature()) {

  #skip mitochondrial genes?

  my($id) = $gff_feature->has_tag('ID')? $gff_feature->get_tag_values('ID')
                                       : $gff_feature->get_tag_values('Parent');

  if ($gff_feature->has_tag('ID') && !($id eq $gff_feature->seq_id) ){
    ($srcfeature{$id}) = Chado::Feature->search(name => $gff_feature->seq_id);

    unless ($srcfeature{$id}) {
      warn "\n" . "*" x 72 ."\n";
      warn "Unable to find a source feature id for the reference sequence in this line:\n";
      warn $gff_feature->gff_string . "\n\n";
      warn "That is, ".$gff_feature->seq_id." should either have a entry in the \n";
      warn "feature table or earlier in this GFF file and it doesn't.\n\n";
      warn "*" x 72 ."\n";
      die;
    }


#is this general, or what should really be done here?
    if(!$dbxref{$id}){
      my($chado_dbxref) = Chado::Dbxref->find_or_create({
        db_id => $chado_db->id,
        accession => $id,
                                                       });
      $dbxref{$id} = $chado_dbxref;
    }
  }


  my ($chado_type);
  if ($typemap{$gff_feature->primary_tag}) {
    ($chado_type) = $typemap{$gff_feature->primary_tag};
  } else {
    ($typemap{$gff_feature->primary_tag}) = Chado::Cvterm->search( name => $gff_feature->primary_tag );
    ($chado_type) = $typemap{$gff_feature->primary_tag}; 
  }

  die $gff_feature->primary_tag . " could not be found in your cvterm table.\nEither the Sequence Ontology was incorrectly loaded,\nor this file doesn't contain GFF3" unless $chado_type;


  ## GFF features are base-oriented, so we must add 1 to the diff
  ## between the end base and the start base, to get the number of
  ## intervening bases between the start and end intervals
  my $seqlen = ($gff_feature->end - $gff_feature->start) + 1;

  ## we must convert between base-oriented coordinates (GFF3) and
  ## interbase coordinates (chado)
  ##
  ## interbase counts *between* bases (starting from 0)
  ## GFF3 (and blast, bioperl, etc) count the actual bases (origin 1)
  ##
  ## 
  ## 0 1 2 3 4 5 6 7 8 : INTERBASE
  ##  A T G C G T A T
  ##  1 2 3 4 5 6 7 8  : BIOPERL/GFF
  ##
  ## from the above we can see that we need to add/subtract 1 from fmin
  ## we don't touch fmax
  my $fmin = $gff_feature->start -1;    # GFF -> InterBase
  my $fmax = $gff_feature->end;

  my($chado_feature) = Chado::Feature->find_or_create({
    organism_id  => $chado_organism,
    name         => $id,
    uniquename   => $id .'_'. $gff_feature->primary_tag
                        .'_'. $gff_feature->seq_id .':'
                            . $fmin .'..'. $fmax,
    type_id      => $chado_type->cvterm_id,
    seqlen       => $seqlen
                                                    });

  $feature_count++ if $gff_feature->has_tag('ID');

  next if $id eq $gff_feature->seq_id; #ie, this is a srcfeature (ie, fref) so only create the feature

  $chado_feature->dbxref_id($dbxref{$id}) if $gff_feature->has_tag('ID'); # is this the right thing to do here?
  $chado_feature->update;

  my $frame = $gff_feature->frame eq '.' ? 0 : $gff_feature->frame;

  Chado::Featureloc->find_or_create({
      feature_id    => $chado_feature->id,
      fmin          => $fmin,
      fmax          => $fmax,
      strand        => $gff_feature->strand,
      phase         => $frame,
      srcfeature_id => $srcfeature{$id}->id,
                                      });

  $feature{$id} = $chado_feature if $gff_feature->has_tag('ID');

  if($gff_feature->has_tag('ID')){
    my ($synonym) = Chado::Synonym->find_or_create({
                      name    => $id,
                      type_id => $synonym_type->cvterm_id
                                                   });
                                                                                                                                  
    Chado::Feature_synonym->find_or_create ({
                      synonym_id => $synonym->synonym_id,
                      feature_id => $chado_feature->feature_id,
                      pub_id     => 1 ##what should go here?
                                            });
  }

  if($gff_feature->has_tag('Parent')){
    my($parent) = $gff_feature->get_tag_values('Parent');

    Chado::Feature_Relationship->find_or_create({
      subject_id => $chado_feature->id,
      object_id => $feature{$parent}->id,
      type_id => $part_of
                                              });

  }

  if($gff_feature->has_tag('Alias')) {
    my ($synonym) = Chado::Synonym->find_or_create({
                      name    => $gff_feature->get_tag_values('Alias'),
                      type_id => $synonym_type->cvterm_id
                                                   });
                                                                                
                                                                                
    Chado::Feature_synonym->find_or_create ({
                      synonym_id => $synonym->synonym_id,
                      feature_id => $chado_feature->feature_id,
                      pub_id     => 1 ##what should go here?
                                            });
 
  }

  if($gff_feature->has_tag('Name')) {
    my ($synonym) = Chado::Synonym->find_or_create({
                      name    => $gff_feature->get_tag_values('Name'),
                      type_id => $synonym_type->cvterm_id
                                                   });
                                                                                
                                                                                
    Chado::Feature_synonym->find_or_create ({
                      synonym_id => $synonym->synonym_id,
                      feature_id => $chado_feature->feature_id,
                      pub_id     => 1 ##what should go here?
                                            });
  }

  if($gff_feature->has_tag('note')) {
    Chado::Featureprop->find_or_create({
                      feature_id => $chado_feature->feature_id,
                      type_id    => $note_type->cvterm_id,
                      value      => $gff_feature->get_tag_values('note');
                                       });
  } 

}
$gffio->close();

print "$feature_count features added\n";
