#!/usr/bin/perl
use strict;
use DBI;
use Chado::LoadDBI;
use Bio::Tools::GFF;

# parents come before features
# no dbxref_id allowed
# no residues allowed

#still need to touch for barest of functionality (for me):
#  featureprop for Notes -- done,not tested
#  feature_synonym and synonym for Alias and Name -- done, not tested
#  feature_cvterm for Ontology_term -- done, not tested

my %src = ();
my %type = ();
my $pub; # for holding null pub object
my %synonym;

########################
#my $db = DBI->connect('dbi:Pg:dbname=chado_amygdala_02','allenday','');
my $db = DBI->connect('dbi:Pg:dbname=chado','cain','');

my $sth = $db->prepare("select nextval('feature_feature_id_seq')");
$sth->execute;
my($nextfeature) = $sth->fetchrow_array();

$sth = $db->prepare("select nextval('featureloc_featureloc_id_seq')");
$sth->execute;
my($nextfeatureloc) = $sth->fetchrow_array();

$sth = $db->prepare("select nextval('feature_relationship_feature_relationship_id_seq')");
$sth->execute;
my($nextfeaturerel) = $sth->fetchrow_array();

$sth = $db->prepare("select nextval('featureprop_featureprop_id_seq')");
$sth->execute;
my($nextfeatureprop) = $sth->fetchrow_array();

$sth = $db->prepare("select nextval('feature_cvterm_feature_cvterm_id_seq')");
$sth->execute;
my($nextfeaturecvterm) = $sth->fetchrow_array();

$sth = $db->prepare("select nextval('synonym_synonym_id_seq')");
$sth->execute;
my($nextsynonym) = $sth->fetchrow_array();

$sth = $db->prepare("select nextval('feature_synonym_feature_synonym_id_seq')");
$sth->execute;
my($nextfeaturesynonym) = $sth->fetchrow_array();

$sth = $db->prepare("select cvterm_id from cvterm where name = 'part_of'");
$sth->execute;
my($part_of) = $sth->fetchrow_array();
########################

#my($organism) = Chado::Organism->search( common_name => 'human' ); #FIXME
my($organism) = Chado::Organism->search( common_name => 'rice' ); #FIXME--I will


open F   ,  ">feature.tmp";
open FLOC,  ">featureloc.tmp";
open FREL,  ">featurerel.tmp";
open FPROP, ">featureprop.tmp";
open FCV,   ">featurecvterm.tmp";
open SYN,   ">synonym.tmp";
open FS,    ">featuresynonym.tmp";

print F    "BEGIN;\n";
print F    "COPY feature (feature_id,organism_id,name,uniquename,type_id) FROM STDIN;\n";

print FLOC "BEGIN;\n";
print FLOC "COPY featureloc (featureloc_id,feature_id,srcfeature_id,fmin,fmax,strand,phase) FROM STDIN;\n";

print FREL "BEGIN;\n";
print FREL "COPY feature_relationship (feature_relationship_id,subject_id,object_id,type_id) FROM STDIN;\n";

print FPROP "BEGIN;\n";
print FPROP "COPY featureprop (featureprop_id,feature_id,type_id,value,rank) FROM STDIN;\n";

print FCV "BEGIN;\n";
print FCV "COPY feature_cvterm (feature_cvterm_id,feature_id,cvterm_id,pub_id) FROM STDIN;\n";

print SYN "BEGIN;\n";
print SYN "COPY synonym (synonym_id,name,type_id,synonym_sgml) FROM STDIN;\n";

print FS "BEGIN;\n";
print FS "COPY feature_synonym (feature_synonym_id,synonym_id,feature_id,pub_id) FROM STDIN;\n";

my $gffio = Bio::Tools::GFF->new(-fh => \*STDIN, -gff_version => 3);

while(my $feature = $gffio->next_feature()){
  my $type = $type{$feature->primary_tag};
  if(!$type){
    ($type) = Chado::Cvterm->search( name => $feature->primary_tag );
    $type{$feature->primary_tag} = $type->id;
  }
  die "no cvterm for ".$feature->primary_tag unless $type;

  my $src = $src{$feature->seq_id};
  if(!$src){
    if($feature->seq_id eq '.'){
      $src = '\N';
    } else {
      ($src) = Chado::Feature->search( uniquename => $feature->seq_id )
            || Chado::Feature->search( name => $feature->seq_id );
      if ($src->isa('Class::DBI::Iterator')) {
        my @sources;
        while (my $tmp = $src->next) {
          push @sources, $tmp;
        }
        die "more that one source for ".$feature->seq_id if (@sources>1);
        $src{$feature->seq_id} = $sources[0]->id;
      } else {
        $src{$feature->seq_id} = $src->id;
      }
      $src = $src{$feature->seq_id};
    }
  }
  die "no feature for ".$feature->seq_id unless $src;

  if($feature->has_tag('Parent')){
    my $pname = undef;
    my($pname) = $feature->get_tag_values('Parent');
    my $parent = $src{$pname};
    if(!$parent){
      ($parent) = Chado::Feature->search( uniquename => $pname )
        || Chado::Feature->search( name => $pname );
      $src{$pname} = $parent->id;
    }
    die "no parent ".$pname unless $parent;

    print FREL join("\t", ($nextfeaturerel,$nextfeature,$parent,$part_of)),"\n";
    $nextfeaturerel++;
  }

  my($name) = $feature->has_tag('Name') ? $feature->get_tag_values('Name') : '\N';
  #my($uniquename) = $feature->has_tag('ID') ? $feature->get_tag_values('ID') : $nextfeature;
  my $uniquename = $nextfeature;
  $src{$name} = $nextfeature;
  print F join("\t", ($nextfeature, $organism->id, $name, $uniquename, $type)),"\n";

  my $start = $feature->start eq '.' ? '\N' : $feature->start;
  my $end   = $feature->end   eq '.' ? '\N' : $feature->end;
  my $frame = $feature->frame eq '.' ? '\N' : $feature->frame;

  print FLOC join("\t", ($nextfeatureloc, $nextfeature, $src, $start, $end, $feature->strand, $frame)),"\n";

  my @notes = $feature->has_tag('Note') ? $feature->get_tag_values('Note') : [];
  foreach my $note (@notes) {
    my $rank = 0;

    ($type{'Note'}) = Chado::Cvterm->search( name => 'note') unless $type{'Note'};

    print FPROP join("\t",($nextfeatureprop,$nextfeature,$type{'Note'}->id,$note,$rank)),"\n";

    $rank++;
    $nextfeatureprop++;
  }

  my @cvterms = $feature->has_tag('Ontology_term') 
                ? $feature->get_tag_values('Ontology_term')
                : ();
  foreach my $term (@cvterms) {
    unless ($type{$term}) {
      my ($dbxref) = Chado::Dbxref->search( accession => $term );
      warn "couldn't find $term in dbxref\n" and next unless $dbxref;
      ($type{$term}) = Chado::Cvterm->search( dbxref_id => $dbxref->id );
      warn "couldn't find $term's cvterm_id in cvterm table\n" 
        and next unless $type{$term}; 
    }
    unless ($pub) {
      ($pub) = Chado::Pub->search( miniref => 'null' );
      $pub = $pub->id; #no need to keep whole object when all we want is the id
    }

    print FCV join("\t",($nextfeaturecvterm,$nextfeature,$type{$term}->id,$pub)),"\n";;
    $nextfeaturecvterm++;
  }

  my @aliases;
  if ($feature->has_tag('Alias')) {
    @aliases =   $feature->get_tag_values('Alias');
  }
  if ($name ne '\N') {
    push @aliases, $name;
  }

  #need to unique-ify the list
  my %count;
  my @ualiases = grep {++$count{$_} < 2} @aliases;

  foreach my $alias (@ualiases) {
    unless ($synonym{$alias}) {
      unless ($type{'synonym'}) {
        ($type{'synonym'}) = Chado::Cvterm->search( name => 'synonym' );
        warn "unable to find synonym type in cvterm table" 
            and next unless $type{'synonym'};
      }

      print SYN join("\t", ($nextsynonym,$alias,$type{'synonym'}->id,$alias)),"\n";

      unless ($pub) {
        ($pub) = Chado::Pub->search( miniref => 'null' );
        $pub = $pub->id; #no need to keep whole object when all we want is the id
      }

      print FS join("\t", ($nextfeaturesynonym,$nextsynonym,$nextfeature,$pub)),"\n";

#        warn "alias:$alias,name:$name\n";

      $nextfeaturesynonym++;
      $synonym{$alias} = $nextsynonym;
      $nextsynonym++;

    } else {
      print FS join("\t", ($nextfeaturesynonym,$synonym{$alias},$nextfeature,$pub)),"\n";

#        warn "in seenit, alias:$alias, name:$name\n";

      $nextfeaturesynonym++;
    }
  }

  $nextfeature++;
  $nextfeatureloc++;
}

print F    "\\.\n";
print F    "COMMIT;\n";
print FLOC "\\.\n";
print FLOC "COMMIT;\n";
print FREL "\\.\n";
print FREL "COMMIT;\n";
print FPROP "\\.\n";
print FPROP "COMMIT;\n";
print FCV "\\.\n";
print FCV "COMMIT;\n";
print SYN "\\.\n";
print SYN "COMMIT;\n";
print FS "\\.\n";
print FS "COMMIT;\n";

close F;
close FLOC;
close FREL;
close FPROP;
close FCV;
close SYN;
close FS;
