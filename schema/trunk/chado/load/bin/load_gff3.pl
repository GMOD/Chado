#!/usr/bin/perl
#copyright stuff: Allen Day, 2003
# license stuff: Perl Artistic License


use strict;
use Bio::Tools::GFF;
use Chado::AutoDBI;
use Chado::LoadDBI;
use Getopt::Long;

#
# Items probably need to be passed in:
#       filename of GFF file (or stdin)
#       name of source db for dbxref (could use filename as default)
#       name of the organism
#       could provide a flag to skip mitocondrial, although I don't know how to implement generally
#

my ($ORGANISM, $SRC_DB, $GFFFILE);

GetOptions('organism:s'       => \$ORGANISM,
           'srcdb:s'          => \$SRC_DB,
           'gfffile:s'        => \$GFFFILE
          ) ; 

$ORGANISM ||='Human';
$SRC_DB   ||= 'refseq';
$SRC_DB   ="DB:$SRC_DB";
$GFFFILE  ||='test.gff';

Chado::LoadDBI->init();

my %typemap;

my %feature = ();
my %srcfeature = ();
my %dbxref = ();

my $line_count = 0;

my($chado_organism) = Chado::Organism->search(common_name => $ORGANISM );
my($chado_db)       = Chado::Db->search(name => $SRC_DB);
my($part_of)        = Chado::Cvterm->search(name => 'part_of');

die "The organism '$ORGANISM' could not be found. Did you spell it right?"
     unless $chado_organism;

die "The database '$SRC_DB' could not be found. Did you spell it correctly?"
     unless $chado_db;

die "The cvterm_id for 'part_of' could not be found
That is a pretty serious problem with you database!\n" unless $part_of;

my $gffio = Bio::Tools::GFF->new(-file => $GFFFILE, -gff_version => 3);

while(my $gff_feature = $gffio->next_feature()) {

  #skip mitochondrial genes?

  my($id) = $gff_feature->has_tag('ID') ? $gff_feature->get_tag_values('ID')
                                        : $gff_feature->get_tag_values('Parent');

  if ($gff_feature->has_tag('ID') && !($id eq $gff_feature->seq_id) ){
#print $id,"\n";
#print STDERR $id,"\n";
    ($srcfeature{$id}) = Chado::Feature->search(name => $gff_feature->seq_id);

    unless ($srcfeature{$id}) {
      warn "\n" . "*" x 72 ."\n";
      warn "Unable to find a source feature id for the reference sequence in this line:\n";
      warn $gff_feature->gff_string . "\n\n";
      warn "That is, ".$gff_feature->seq_id." should either have a entry in the \n";
      warn "feature table or early in this GFF file and it doesn't.\n\n";
      warn "*" x 72 ."\n";
      die;
    }

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

#warn $id .'_'. $gff_feature->primary_tag .'_'. $gff_feature->seq_id .':'. $gff_feature->start .'..'. $gff_feature->end;
#warn "*".$gff_feature->has_tag('ID')." ". $dbxref{$id}->id;
#warn "organism:$chado_organism";

  my($chado_feature) = Chado::Feature->find_or_create({
    organism_id => $chado_organism,
    name => $id,
    uniquename => $id .'_'. $gff_feature->primary_tag
                      .'_'. $gff_feature->seq_id .':'
                          . $gff_feature->start .'..'. $gff_feature->end,
    type_id => $chado_type->cvterm_id,
#    dbxref_id => $gff_feature->has_tag('ID') ? $dbxref{$id} : undef,
                                                    });

  $line_count++;

  next if $id eq $gff_feature->seq_id; #ie, this is a srcfeature (ie, fref) so only create the feature

  $chado_feature->dbxref_id($dbxref{$id}) if $gff_feature->has_tag('ID');
  $chado_feature->update;

#warn $chado_feature->name;

  my $frame = $gff_feature->frame eq '.' ? 0 : $gff_feature->frame;

  Chado::Featureloc->find_or_create({
      feature_id    => $chado_feature->id,
      fmin          => $gff_feature->start,
      fmax          => $gff_feature->end,
      strand        => $gff_feature->strand,
      phase         => $frame,
      srcfeature_id => $srcfeature{$id}->id,
                                      });

  $feature{$id} = $chado_feature if $gff_feature->has_tag('ID');

  if($gff_feature->has_tag('ID')){
    my($id)     = $gff_feature->get_tag_values('ID');

  }
  if($gff_feature->has_tag('Parent')){
    my($parent) = $gff_feature->get_tag_values('Parent');

#warn $chado_feature->uniquename ." part of ". $gff_feature{$parent}->uniquename; 
    Chado::Feature_Relationship->find_or_create({
      subject_id => $chado_feature,
      object_id => $feature{$parent},
      type_id => $part_of,
                                              });
  }
}
$gffio->close();

print "$line_count features added\n";
