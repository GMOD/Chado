#!/usr/bin/perl -w

use strict;
use lib 'lib';
use Bio::Tools::GFF;
use Chado::AutoDBI;
use Chado::LoadDBI;
use Term::ProgressBar;
use Getopt::Long;
use constant CACHE_SIZE => 1000;

$| = 1;

=head1 NAME

load_gff3.pl - Load gff3 files into a chado database.

=head1 SYNOPSIS

  % load_gff3.pl --organism Human --srcdb 'DB:refseq' --gfffile refseq.gff

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

  chr1	NCBI	chromosome	1	246127941	.	.	.	ID=chr1

Note that if the '##sequence-region' notation is used, this script will
not be able to determine the type of sequence and therefore will 
assign it the 'region' type which is very general. If that is not what
you want, use the standard GFF line to specify the reference
sequence.

=back

=head1 COMMAND-LINE OPTIONS

The following command line options are required.  Note that they
can be abbreviated to one letter.

  --organism <org name>      Common name of the organism
  --srcdb    <dbname>        The name of the source database
  --gfffile  <filename>      The name of the GFF3 file

=head1 AUTHORS

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
$SRC_DB   ||= 'DB:refseq';
$GFFFILE  ||='test.gff';

#count the file lines.  we need this to track load progress
open(WC,"/usr/bin/wc -l $GFFFILE |");
my $linecount = <WC>; chomp $linecount;
close(WC);
($linecount) = $linecount =~ /^\s+(\d+)\s+.+$/;

my $progress = Term::ProgressBar->new({name => 'Features', count => $linecount,
                                       ETA => 'linear', });
$progress->max_update_rate(1);
my $next_update = 0;


Chado::LoadDBI->init();

my %typemap;

my %feature = ();
my %featureloc_rank = ();
my %srcfeature = ();
my %dbxref = ();
my %tagtype = ();

my $feature_count = 0;

my($chado_organism) = Chado::Organism->search(common_name => $ORGANISM );
my($chado_db)       = Chado::Db->search(name => $SRC_DB);
my($part_of)        = Chado::Cvterm->search(name => 'part_of');
my($nullpub)        = Chado::Pub->search(miniref => 'null');

die "The organism '$ORGANISM' could not be found. Did you spell it correctly?"
     unless $chado_organism;

die "The database '$SRC_DB' could not be found. Did you spell it correctly?"
     unless $chado_db;

die "The cvterm_id for 'part_of' could not be found
That is a pretty serious problem with you database!\n" unless $part_of;

my $gffio = Bio::Tools::GFF->new(-file => $GFFFILE, -gff_version => 3);

#check for a synonym type in cvterm--if it's not there create it
#and a corresponding entry in cv

my ($cv_entry) = Chado::Cv->find_or_create({
                    name       => 'autocreated',
                    definition => 'auto created by load_gff3.pl'
                                             });
my ($synonym_type) = Chado::Cvterm->search(name => 'synonym');
unless ($synonym_type) {
  ($synonym_type) = Chado::Cvterm->find_or_create({
                    name       => 'synonym',
                    cv_id      => $cv_entry->cv_id,
                    definition => 'auto created by load_gff3.pl'
                                                  });
}
die "Unable to create a synonym type in cvterm table."
    unless $synonym_type;

my ($note_type) = Chado::Cvterm->search(name => 'note');
($note_type) = Chado::Cvterm->search(name => 'Note') unless $note_type;
unless ($note_type) {
  ($note_type) = Chado::Cvterm->find_or_create({
                    name       => 'note',
                    cv_id      => $cv_entry->cv_id,
                    definition => 'auto created by load_gff3.pl'
                                                  });
}
die "Unable to create note type in cvterm table."
    unless $note_type;

my ($pub_type) = Chado::Cvterm->search(name => 'gff_file');
unless ($pub_type) {
  ($pub_type) = Chado::Cvterm->find_or_create({
                    name       => 'gff_file',
                    cv_id      => $cv_entry->cv_id,
                    definition => 'auto created by load_gff3.pl'
                                                  });
}
die "Unable to find or create pub type in cvterm table"
    unless $pub_type;

my $mtime = (stat($GFFFILE))[9];
my ($pub) = Chado::Pub->search(title => $GFFFILE." ".$mtime);
if ($pub) {
  print "It appears that you have already loaded this exact file\n";
  print "Do you want to continue [no]? ";
  chomp (my $response = <STDIN>);
  unless ($response =~ /^[Yy]/) {
    print "OK--bye.\n";
    exit 0;
  }
} else {
  $pub = Chado::Pub->find_or_create({
                    title      => $GFFFILE." ".$mtime,
                    miniref    => $GFFFILE." ".$mtime,
                    type_id    => $pub_type->cvterm_id
                                   });
}
die "unable to find or create a pub entry in the pub table"
    unless $pub;

while(my $gff_segment = $gffio->next_segment()) {
  my $segment = Chado::Feature->search({name => $gff_segment->display_id});
  if(!$segment){

    if(!$typemap{'region'}){
      ($typemap{'region'}) = Chado::Cvterm->search( name => 'region' );
    }
    die "Sequence Ontology term \"region\" could not be found in your cvterm table.\nAre you sure the Sequence Ontology was correctly loaded?\n" unless $typemap{'region'};

    my $f = Chado::Feature->create({
	      organism_id => $chado_organism,
	      name        => $gff_segment->display_id,
	      uniquename  => $gff_segment->display_id .'_region',
	      type_id => $typemap{'region'},
	      seqlen => abs($gff_segment->end - $gff_segment->start), #who knows? spec doesn't specify start < end
			          });

    $feature_count++;
    $f->dbi_commit;
  }
}

#cache objects up to CACHE_SIZE, then flush.  this is a way to
#break our large load transaction into multiple cache/flush
#mini-transactions
my @transaction;

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
      exit 1;
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
    name         => $gff_feature->has_tag('ID') ? $gff_feature->get_tag_values('ID')
                                                : ' ',
#    name         => $id,
    uniquename   => $id .'_'. $gff_feature->primary_tag
                        .'_'. $gff_feature->seq_id .':'
                            . $fmin .'..'. $fmax,
    type_id      => $chado_type->cvterm_id,
    seqlen       => $seqlen
                                                    });

  push @transaction, $chado_feature;

  $feature_count++;

  next if $id eq $gff_feature->seq_id; #ie, this is a srcfeature (ie, fref) so only create the feature

  $chado_feature->dbxref_id($dbxref{$id}) if $gff_feature->has_tag('ID'); # is this the right thing to do here?
  $chado_feature->update;

  my $frame = $gff_feature->frame eq '.' ? 0 : $gff_feature->frame;

  my $chado_featureloc = Chado::Featureloc->find_or_create({
      feature_id    => $chado_feature->id,
      fmin          => $fmin,
      fmax          => $fmax,
      strand        => $gff_feature->strand,
      phase         => $frame,
      rank          => $featureloc_rank{$chado_feature->id} || 0,
      srcfeature_id => $srcfeature{$id}->id,
                                      });

  push @transaction, $chado_featureloc;

  $featureloc_rank{$chado_feature->id}++;
  $feature{$id} = $chado_feature if $gff_feature->has_tag('ID');

  if($gff_feature->has_tag('ID')){
    my($chado_synonym1) = Chado::Synonym->find_or_create({
                      name         => $id,
                      synonym_sgml => $id,
                      type_id      => $synonym_type->cvterm_id
                                                   });
    my($chado_synonym2) = Chado::Feature_Synonym->find_or_create ({
                      synonym_id => $chado_synonym1->synonym_id,
                      feature_id => $chado_feature->feature_id,
                      pub_id     => $pub->pub_id
                                            });

    push @transaction, $chado_synonym1;
    push @transaction, $chado_synonym2;

  }

  if($gff_feature->has_tag('Parent')){
    my @parents = $gff_feature->get_tag_values('Parent');
    foreach my $parent (@parents) {
      my $chado_feature_relationship = Chado::Feature_Relationship->find_or_create({
        subject_id => $chado_feature->id,
        object_id => $feature{$parent}->id,
        type_id => $part_of
                                                  });

      push @transaction, $chado_feature_relationship;
    }
  }

  if($gff_feature->has_tag('Alias')) {
    my @aliases = $gff_feature->get_tag_values('Alias');
    foreach my $alias (@aliases) {
      my($chado_synonym1) = Chado::Synonym->find_or_create({
                      name         => $alias,
                      synonym_sgml => $alias,
                      type_id      => $synonym_type->cvterm_id
                                                     });
	  
      my($chado_synonym2) = Chado::Feature_Synonym->find_or_create ({
                      synonym_id => $chado_synonym1->synonym_id,
                      feature_id => $chado_feature->feature_id,
                      pub_id     => $pub->pub_id,
                                              });
      push @transaction, $chado_synonym1;
      push @transaction, $chado_synonym2;
    }
  }

  if($gff_feature->has_tag('Name')) {
    my @names = $gff_feature->get_tag_values('Name');
    foreach my $name (@names) {
      my($chado_synonym1) = Chado::Synonym->find_or_create({
                      name         => $name,
                      synonym_sgml => $name,
                      type_id      => $synonym_type->cvterm_id
                                                   });
      my($chado_synonym2) = Chado::Feature_Synonym->find_or_create ({
                      synonym_id => $chado_synonym1->synonym_id,
                      feature_id => $chado_feature->feature_id,
                      pub_id     => $pub->pub_id,
                                            });
      push @transaction, $chado_synonym1;
      push @transaction, $chado_synonym2;
    }
  }

#  if($gff_feature->has_tag('note') or $gff_feature->has_tag('Note')) {
#    my @notes;
#    push @notes, $gff_feature->get_tag_values('note')
#         if $gff_feature->has_tag('note');
#    push @notes, $gff_feature->get_tag_values('Note')
#         if $gff_feature->has_tag('Note');
#    foreach my $note (@notes) {
#      Chado::Featureprop->find_or_create({
#                      feature_id => $chado_feature->feature_id,
#                      type_id    => $note_type->cvterm_id,
#                      value      => $note
#                                         });
#    }
#  } 

  my @tags = $gff_feature->all_tags;
  foreach my $tag (@tags) {
    next if $tag eq 'ID';
    next if $tag eq 'Parent';
    next if $tag eq 'Alias';
    next if $tag eq 'Name';

    unless (defined $tagtype{$tag}) {
      $tagtype{$tag} = Chado::Cvterm->find_or_create ({
                    name       => $tag,
                    cv_id      => $cv_entry->cv_id,
                    definition => 'auto created by load_gff3.pl'
                                                      });

      push @transaction, $tagtype{$tag};
    }

    my @values = $gff_feature->get_tag_values($tag);
    foreach my $value (@values) {
      my($chado_featureprop) = Chado::Featureprop->find_or_create({
                      feature_id => $chado_feature->feature_id,
                      type_id    => $tagtype{$tag}->cvterm_id,
                      value      => $value
                                         });

      push @transaction, $chado_featureprop;
    }
  }

  if ($feature_count % CACHE_SIZE == 0) {
    $_->dbi_commit foreach @transaction;
  }
    @transaction = ();

    $next_update = $progress->update($feature_count) if($feature_count > $next_update);
#warn $next_update;
#    $progress->update($linecount) if($linecount >= $next_update);
    $progress->update($linecount) if($next_update >= $linecount);

    #old-style progress tracker
    #print STDERR "features loaded $feature_count";
    #print STDERR -t STDOUT && !$ENV{EMACS} ? "\r" : "\n";
#  }
}
$gffio->close();

print "$feature_count features added\n";
