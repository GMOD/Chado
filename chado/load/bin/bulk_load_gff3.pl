#!/usr/bin/perl
use strict;
use DBI;
use Chado::LoadDBI;
use Bio::Tools::GFF;

# parents come before features
# no dbxref_id allowed
# no residues allowed
# reference sequences already in db!

my %src = ();
my %type = ();
my $pub; # for holding null pub object
my %synonym;
my $gff_source_db;
my %gff_source;
my $source_success = 1; #indicates that GFF_source is in db table
my @tables = (
   "feature",
   "featureloc",
   "feature_relationship",
   "featureprop",
   "feature_cvterm",
   "synonym",
   "feature_synonym",
   "feature_dbxref"
);
my %files = (
   feature              => "feature.tmp",
   featureloc           => "featureloc.tmp",
   feature_relationship => "featurerel.tmp",
   featureprop          => "featureprop.tmp",
   feature_cvterm       => "featurecvterm.tmp",
   synonym              => "synonym.tmp",
   feature_synonym      => "featuresynonym.tmp",
   feature_dbxref       => "featuredbxref.tmp",
);
my %sequences = (
   feature              => "feature_feature_id_seq",
   featureloc           => "featureloc_featureloc_id_seq",
   feature_relationship => "feature_relationship_feature_relationship_id_seq",
   featureprop          => "featureprop_featureprop_id_seq",
   feature_cvterm       => "feature_cvterm_feature_cvterm_id_seq",
   synonym              => "synonym_synonym_id_seq",
   feature_synonym      => "feature_synonym_feature_synonym_id_seq",
   feature_dbxref       => "feature_dbxref_feature_dbxref_id_seq",
);
my %copystring = (
   feature              => "(feature_id,organism_id,name,uniquename,type_id)",
   featureloc           => "(featureloc_id,feature_id,srcfeature_id,fmin,fmax,strand,phase)",
   feature_relationship => "(feature_relationship_id,subject_id,object_id,type_id)",
   featureprop          => "(featureprop_id,feature_id,type_id,value,rank)",
   feature_cvterm       => "(feature_cvterm_id,feature_id,cvterm_id,pub_id)",
   synonym              => "(synonym_id,name,type_id,synonym_sgml)",
   feature_synonym      => "(feature_synonym_id,synonym_id,feature_id,pub_id)",
   feature_dbxref       => "(feature_dbxref_id,feature_id,dbxref_id)",
);


########################
#my $db = DBI->connect('dbi:Pg:dbname=chado_amygdala_02','allenday','');
my $db = DBI->connect('dbi:Pg:dbname=chado','scott','', {AutoCommit => 0});

my $sth = $db->prepare("select nextval('$sequences{feature}')");
$sth->execute;
my($nextfeature) = $sth->fetchrow_array();

$sth = $db->prepare("select nextval('$sequences{featureloc}')");
$sth->execute;
my($nextfeatureloc) = $sth->fetchrow_array();

$sth = $db->prepare("select nextval('$sequences{feature_relationship}')");
$sth->execute;
my($nextfeaturerel) = $sth->fetchrow_array();

$sth = $db->prepare("select nextval('$sequences{featureprop}')");
$sth->execute;
my($nextfeatureprop) = $sth->fetchrow_array();

$sth = $db->prepare("select nextval('$sequences{feature_cvterm}')");
$sth->execute;
my($nextfeaturecvterm) = $sth->fetchrow_array();

$sth = $db->prepare("select nextval('$sequences{synonym}')");
$sth->execute;
my($nextsynonym) = $sth->fetchrow_array();

$sth = $db->prepare("select nextval('$sequences{feature_synonym}')");
$sth->execute;
my($nextfeaturesynonym) = $sth->fetchrow_array();

$sth = $db->prepare("select nextval('$sequences{feature_dbxref}')");
$sth->execute;
my($nextfeaturedbxref) = $sth->fetchrow_array();


$sth = $db->prepare("select cvterm_id from cvterm where name = 'part_of'");
$sth->execute;
my($part_of) = $sth->fetchrow_array();

$sth->finish;
########################

#my($organism) = Chado::Organism->search( common_name => 'human' ); #FIXME
my($organism) = Chado::Organism->search( common_name => 'rice' ); #FIXME--I will

open F   ,  ">$files{feature}";
open FLOC,  ">$files{featureloc}";
open FREL,  ">$files{feature_relationship}";
open FPROP, ">$files{featureprop}";
open FCV,   ">$files{feature_cvterm}";
open SYN,   ">$files{synonym}";
open FS,    ">$files{feature_synonym}";
open FDBX,  ">$files{feature_dbxref}";

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
  my($uniquename) = $feature->has_tag('ID') ? $feature->get_tag_values('ID') : $nextfeature;
  #my $uniquename = $nextfeature;
  $src{$uniquename} = $nextfeature;
  print F join("\t", ($nextfeature, $organism->id, $name, $uniquename, $type)),"\n";

  my $start = $feature->start eq '.' ? '\N' : $feature->start;
  my $end   = $feature->end   eq '.' ? '\N' : $feature->end;
  my $frame = $feature->frame eq '.' ? '\N' : $feature->frame;

  print FLOC join("\t", ($nextfeatureloc, $nextfeature, $src, $start, $end, $feature->strand, $frame)),"\n";

  if ($feature->has_tag('Note') or $feature->has_tag('note')) {
    my @notes;
    push @notes, $feature->get_tag_values('Note') if $feature->has_tag('Note');
    push @notes, $feature->get_tag_values('note') if $feature->has_tag('note');
    my $rank = 0;
    foreach my $note (@notes) {

      ($type{'Note'}) = Chado::Cvterm->search( name => 'note')
          unless $type{'Note'};

      print FPROP join("\t",($nextfeatureprop,$nextfeature,$type{'Note'}->id,$note,$rank)),"\n";

      $rank++;
      $nextfeatureprop++;
    }
  }

  my $source = $feature->source_tag;
  if ( $source_success && $source && $source ne '.') {
    unless ($gff_source_db) {
      ($gff_source_db) = Chado::Db->search({ name => 'GFF_source' });
    }

    if ($gff_source_db) {
      unless ($gff_source{$source}) {
        $gff_source{$source} = Chado::Dbxref->find_or_create( {
            db_id     => $gff_source_db->id,
            accession => $source,
        } );
        $gff_source{$source}->dbi_commit;
      }
      my $dbxref_id = $gff_source{$source}->id;
      print FDBX join("\t",($nextfeaturedbxref,$nextfeature,$dbxref_id)),"\n";
      $nextfeaturedbxref++;
    } else {
      $source_success = 0; #geting GFF_source failed, so don't try anymore
    }
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

my %nextvalue = (
   "feature"              => $nextfeature,
   "featureloc"           => $nextfeatureloc,
   "feature_relationship" => $nextfeaturerel,
   "featureprop"          => $nextfeatureprop,
   "feature_cvterm"       => $nextfeaturecvterm,
   "synonym"              => $nextsynonym,
   "feature_synonym"      => $nextfeaturesynonym,
   "feature_dbxref"       => $nextfeaturedbxref,
);

print F    "\\.\n\n";
print FLOC "\\.\n\n";
print FREL "\\.\n\n";
print FPROP "\\.\n\n";
print FCV "\\.\n\n";
print SYN "\\.\n\n";
print FS "\\.\n\n";
print FDBX "\\.\n\n";

close F;
close FLOC;
close FREL;
close FPROP;
close FCV;
close SYN;
close FS;
close FDBX;


foreach my $table (@tables) {
    copy_from_stdin($db,$table,
                    $copystring{$table},
                    $files{$table},
                    $sequences{$table},
                    $nextvalue{$table});
}

$db->commit;
$db->{AutoCommit}=1;

warn "Optimizing database (this may take a while) ...\n";
print STDERR "  (";
foreach (@tables) {
  print STDERR "$_ "; 
  $db->do("VACUUM ANALYZE $_");
}
print STDERR ") Done.\n";
$db->disconnect;

warn "Deleting temporary files\n";
foreach (@tables) {
  unlink $files{$_};
}

warn "\nWhile this script has made an effort to optimize the database, you\n"
    ."should probably also run VACUUM FULL ANALYZE on the database as well\n";

exit(0);

sub copy_from_stdin {
  my $dbh      = shift;
  my $table    = shift;
  my $fields   = shift;
  my $file     = shift;
  my $sequence = shift;
  my $nextval  = shift;

  warn "Loading data into $table table ...\n";
  my $query = "COPY $table $fields FROM STDIN;";
  my $sth = $dbh->prepare($query);
  $sth->execute();

  open FILE, $file;
  while (<FILE>) {
    $dbh->func($_, 'putline');
  }
  $dbh->func('endcopy');  # no docs on this func--got from google
  close FILE;

  $sth->finish;
  #update the sequence so that later inserts will work 
  $dbh->do("SELECT setval('public.$sequence', $nextval) FROM $table"); 
}
