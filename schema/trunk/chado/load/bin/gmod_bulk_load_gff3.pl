#!/usr/bin/perl
use strict;
#use lib '~/bioperl-live';
use DBI;
use Chado::LoadDBI;
#use Bio::Tools::GFF;
use Bio::FeatureIO;
use Getopt::Long;
use Data::Dumper;

# parents come before features
# no residues allowed
# reference sequences already in db!

=head1 NAME

gmod_bulk_load.pl - Bulk loads gff3 files into a chado database.

=head1 SYNOPSIS

  % cat <gff-file> | gmod_bulk_load.pl [options]

=head1 COMMAND-LINE OPTIONS

 --gfffile     The file containing GFF3 (optional, can read from stdin)
 --organism    The organism for the data
 --dbname      Database name
 --dbuser      Database user name
 --dbpass      Database password
 --dbhost      Database host
 --dbport      Database port
 --analysis    The GFF data is from computational analysis
 --noload      Create bulk load files, but don't actually load them.

Note that all of the arguments that begin 'db' can be provided by default
by Bio::GMOD::Config, which was installed when 'make install' was run.

=head1 DESCRIPTION

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

=item GFF3

The GFF in the datafile must be version 3 due to its tighter control of
the specification and use of controlled vocabulary.  Accordingly, the names
of feature types must be exactly those in the Sequence Ontology, not the
synonyms and not the accession numbers (SO accession numbers may be
supported in future versions of this script).  There are several caveates
about the GFF3 that will work with this bulk loader:

=over

=item Reference sequences

This loader requires that the reference sequence features be already
loaded into the database (for instance, by using gmod_load_gff3.pl).
Future versions of this bulk loader will not have this restriction.

=item Parents/children order

Parents must come before children in the GFF file.

=item Several GFF tags (both reserved and custom) not supported

These include:

=over

=item Gap

=item Any custom (ie, lowercase-first) tag

=back

=item No sequences

This loader does not load DNA sequences, though chromosome sequences
can be loaded with gmod_load_gff3 when the reference sequence features
are loaded.

=back

=back

=head1 AUTHORS

Allen Day E<lt>allenday@ucla.eduE<gt>, Scott Cain E<lt>cain@cshl.orgE<gt>

Copyright (c) 2004

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

my ($ORGANISM, $GFFFILE, $DBNAME, $DBUSER, $DBPASS, $DBHOST, $DBPORT, $ANALYSIS, $NOLOAD);

if (eval {require Bio::GMOD::Config;
          Bio::GMOD::Config->import();
          require Bio::GMOD::DB::Config;
          Bio::GMOD::DB::Config->import();
          1;  } ) {
    my $gmod_conf = $ENV{'GMOD_ROOT'} ?
                    Bio::GMOD::Config->new($ENV{'GMOD_ROOT'}) :
                    Bio::GMOD::Config->new();
    my $db_conf = Bio::GMOD::DB::Config->new($gmod_conf,'default');
    $DBNAME = $db_conf->name();
    $DBUSER = $db_conf->user();
    $DBPASS = $db_conf->password();
    $DBHOST = $db_conf->host();
    $DBPORT = $db_conf->port();
    $ORGANISM=$db_conf->organism();
}

GetOptions(
    'organism:s' => \$ORGANISM,
    'gfffile:s'  => \$GFFFILE,
    'dbname:s'   => \$DBNAME,
    'dbuser:s'   => \$DBUSER,
    'dbpass:s'   => \$DBPASS,
    'dbhost:s'   => \$DBHOST,
    'dbport:s'   => \$DBPORT,
    'analysis'   => \$ANALYSIS,
    'noload'     => \$NOLOAD,
) or ( system( 'pod2text', $0 ), exit -1 );;

$ORGANISM ||='human';
$GFFFILE  ||='stdin';  #nobody better name their file 'stdin'
$DBNAME   ||='chado';
$DBPASS   ||='';
$DBHOST   ||='localhost';
$DBPORT   ||='5432';
$ANALYSIS ||=0;

my %cache = (
             analysis => {},
             db       => {}, #db.db_id cache
             dbxref   => {},
             feature  => {},
             parent   => {}, #featureloc.srcfeature_id ; parent feature
             source   => {}, #dbxref.dbxref_id ; gff_source
             synonym  => {},
             type     => {}, #cvterm.cvterm_id cache
            );

my %t_unique_count;
my $pub; # for holding null pub object
my $gff_source_db;
my $source_success = 1; #indicates that GFF_source is in db table
my @tables = (
   "feature",#
   "featureloc",#
   "feature_relationship",#
   "featureprop",#
   "feature_cvterm",#
   "synonym",#?
   "feature_synonym",#
   "dbxref",#
   "feature_dbxref",#
   "analysisfeature",
);
my %files = (
   feature              => "feature.tmp",
   featureloc           => "featureloc.tmp",
   feature_relationship => "feature_relationship.tmp",
   featureprop          => "featureprop.tmp",
   feature_cvterm       => "feature_cvterm.tmp",
   synonym              => "synonym.tmp",
   feature_synonym      => "feature_synonym.tmp",
   dbxref               => "dbxref.tmp",
   feature_dbxref       => "feature_dbxref.tmp",
   analysisfeature      => "analysisfeature.tmp",
);
my %sequences = (
   feature              => "feature_feature_id_seq",
   featureloc           => "featureloc_featureloc_id_seq",
   feature_relationship => "feature_relationship_feature_relationship_id_seq",
   featureprop          => "featureprop_featureprop_id_seq",
   feature_cvterm       => "feature_cvterm_feature_cvterm_id_seq",
   synonym              => "synonym_synonym_id_seq",
   feature_synonym      => "feature_synonym_feature_synonym_id_seq",
   dbxref               => "dbxref_dbxref_id_seq",
   feature_dbxref       => "feature_dbxref_feature_dbxref_id_seq",
   analysisfeature      => "analysisfeature_analysisfeature_id_seq"
);
my %copystring = (
   feature              => "(feature_id,organism_id,name,uniquename,type_id,is_analysis)",
   featureloc           => "(featureloc_id,feature_id,srcfeature_id,fmin,fmax,strand,phase,rank)",
   feature_relationship => "(feature_relationship_id,subject_id,object_id,type_id)",
   featureprop          => "(featureprop_id,feature_id,type_id,value,rank)",
   feature_cvterm       => "(feature_cvterm_id,feature_id,cvterm_id,pub_id)",
   synonym              => "(synonym_id,name,type_id,synonym_sgml)",
   feature_synonym      => "(feature_synonym_id,synonym_id,feature_id,pub_id)",
   dbxref               => "(dbxref_id,db_id,accession,version,description)",
   feature_dbxref       => "(feature_dbxref_id,feature_id,dbxref_id)",
   analysisfeature      => "(analysisfeature_id,feature_id,analysis_id,significance)",
);


########################
my $db = DBI->connect("dbi:Pg:dbname=$DBNAME;port=$DBPORT;host=$DBHOST",
                       $DBUSER,$DBPASS, {AutoCommit => 0});

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

$sth = $db->prepare("select nextval('$sequences{dbxref}')");
$sth->execute;
my($nextdbxref) = $sth->fetchrow_array();

$sth = $db->prepare("select nextval('$sequences{analysisfeature}')");
$sth->execute;
my($nextanalysisfeature) = $sth->fetchrow_array();

$sth = $db->prepare("select cvterm_id from cvterm where name = 'part_of'");
$sth->execute;
my($part_of) = $sth->fetchrow_array();

$sth = $db->prepare("select cv_id from cv where name = 'Sequence Ontology Feature Annotation'");
$sth->execute;
my($sofa_id) =  $sth->fetchrow_array();

#backup plan for old chado instances
if(!defined($sofa_id)){
  $sth = $db->prepare("select cv_id from cv where name = 'Sequence Ontology'");
  $sth->execute;
  ($sofa_id) =  $sth->fetchrow_array();
}

#######################################################
# Load cache with existing synonym, dbxref, and
# analysis records.  prevents failure of load if they
# already existed.
#

my %label = (
             #add more tables here.  key is tablename,
             #value is label to lookup by.
             analysis => 'name',
             synonym  => 'name',
             dbxref   => 'accession',
            );

my $iterator;

foreach my $table (keys %label){
  print STDERR "caching $table... ";
  my $class = 'Chado::'.ucfirst($table);
  $iterator = $class->retrieve_all();
  my $label = $label{$table};
  while(my $obj = $iterator->next()){
    $cache{$table}{$obj->$label} = $obj;
  }
  print STDERR "done!\n";
}

#
# End load cache.
#######################################################



$sth->finish;
########################

my($organism) = Chado::Organism->search( common_name => "$ORGANISM" );

$organism or die "organism not found in the database";

open F   ,  ">$files{feature}";
open FLOC,  ">$files{featureloc}";
open FREL,  ">$files{feature_relationship}";
open FPROP, ">$files{featureprop}";
open FCV,   ">$files{feature_cvterm}";
open SYN,   ">$files{synonym}";
open FS,    ">$files{feature_synonym}";
open FDBX,  ">$files{feature_dbxref}";
open DBX,   ">$files{dbxref}";
open AF,    ">$files{analysisfeature}";

my $gffio = Bio::FeatureIO->new(-fh => \*STDIN , -format => 'gff');

while(my $feature = $gffio->next_feature()){
  my $featuretype = $feature->type->name;

  my $type = $cache{type}{$featuretype};
  if(!$type){
    ($type) = Chado::Cvterm->search( name => $featuretype, cv_id => $sofa_id );
    $cache{type}{$featuretype} = $type->id;
  }
  die "no cvterm for ".$featuretype unless $type;

  my $src = $cache{parent}{$feature->seq_id->value};

  if(!$src){
    if($feature->seq_id->value eq '.'){
      $src = '\N';
    } else {
      ($src) = Chado::Feature->search( uniquename => $feature->seq_id->value )
            || Chado::Feature->search( name => $feature->seq_id->value );
      die "Unable to find srcfeature ",$feature->seq_id->value," in the database\n" 
            unless $src;
      if ($src->isa('Class::DBI::Iterator')) {
        my @sources;
        while (my $tmp = $src->next) {
          push @sources, $tmp;
        }
        die "more that one source for ".$feature->seq_id->value if (@sources>1);
        $cache{parent}{$feature->seq_id->value} = $sources[0]->id;
      } else {
        $cache{parent}{$feature->seq_id->value} = $src->id;
      }
      $src = $cache{parent}{$feature->seq_id->value};
    }
  }
  die "no feature for ".$feature->seq_id->value unless $src;

  if($feature->annotation->get_Annotations('Parent')){
    my $pname = undef;
    my($pname) = ($feature->annotation->get_Annotations('Parent'))[0]->value;
    my $parent = $cache{parent}{$pname};
    if(!$parent){
      ($parent) = Chado::Feature->search( uniquename => $pname )
        || Chado::Feature->search( name => $pname );
      $cache{parent}{$pname} = $parent->id;
    }
    die "no parent ".$pname unless $parent;

    print FREL join("\t", ($nextfeaturerel,$nextfeature,$parent,$part_of)),"\n";
    $nextfeaturerel++;
  }

  my $source = $feature->source->value;
  my $is_FgenesH = 1 if $source eq 'FgenesH_Monocot';
  my $is_analysis = $is_FgenesH ? 1 : 0;

  my($uniquename) = ($feature->annotation->get_Annotations('ID'))[0] || $nextfeature;
  $uniquename = $uniquename->value if ref($uniquename);
  my($name) = ($feature->annotation->get_Annotations('Name'))[0] || "$featuretype-$uniquename";
  $name = $name->value if ref($name);

  #my $uniquename = $nextfeature;
  $cache{parent}{$uniquename} = $nextfeature;
  print F join("\t", ($nextfeature, $organism->id, $name, $uniquename, $type, $ANALYSIS)),"\n";

  if ($ANALYSIS 
      && $featuretype =~ /match/  
      && !$feature->annotation->get_Annotations('Target')) {
    $cache{feature}{($feature->annotation->get_Annotations('ID'))[0]->value} = $nextfeature;
  }


#need to convert from base to interbase coords
  my $start = $feature->start eq '.' ? '\N' : ($feature->start - 1);
  my $end   = $feature->end   eq '.' ? '\N' : $feature->end;
  my $phase = ($feature->phase->value eq '.' or $feature->phase->value eq '') ? '\N' : $feature->phase->value;

  print FLOC join("\t", ($nextfeatureloc, $nextfeature, $src, $start, $end, $feature->strand, $phase,'0')),"\n";

  if ($feature->annotation->get_Annotations('Note')) {
    my @notes = map {$_->value} $feature->annotation->get_Annotations('Note');
    my $rank = 0;
    foreach my $note (@notes) {

      ($cache{type}{'Note'}) = Chado::Cvterm->search( name => 'Note')
          unless $cache{type}{'Note'};

      print FPROP join("\t",($nextfeatureprop,$nextfeature,$cache{type}{'Note'}->id,$note,$rank)),"\n";

      $rank++;
      $nextfeatureprop++;
    }
  }

  if ( $source_success && $source && $source ne '.') {
    unless ($gff_source_db) {
      ($gff_source_db) = Chado::Db->search({ name => 'GFF_source' });
    }

    if ($gff_source_db) {
      unless ($cache{dbxref}{$source}) {
#        $cache{dbxref}{$source} = Chado::Dbxref->find_or_create( {
#            db_id     => $gff_source_db->id,
#            accession => $source,
#        } );

        $cache{dbxref}{$source} = $nextdbxref;
        print DBX join("\t",($nextdbxref,$gff_source_db->id,$source,1,'\N')),"\n";
        $nextdbxref++; 

#        $cache{dbxref}{$source}->dbi_commit;
      }
      my $dbxref_id = $cache{dbxref}{$source};
      print FDBX join("\t",($nextfeaturedbxref,$nextfeature,$dbxref_id)),"\n";
      $nextfeaturedbxref++;
    } else {
      $source_success = 0; #geting GFF_source failed, so don't try anymore
    }
  }

  if ($feature->annotation->get_Annotations('Ontology_term')) {
    my @cvterms = map {$_->identifier} $feature->annotation->get_Annotations('Ontology_term');
    my %count;
    my @ucvterms = grep {++$count{$_} < 2} @cvterms;
    foreach my $term (@ucvterms) {
      next unless $term;
      unless ($cache{type}{$term}) {
        my ($dbxref) = Chado::Dbxref->search( accession => $term );
        warn "couldn't find $term in dbxref\n" and next unless $dbxref;
        ($cache{type}{$term}) = Chado::Cvterm->search( dbxref_id => $dbxref->id );
        warn "couldn't find $term's cvterm_id in cvterm table\n" 
          and next unless $cache{type}{$term}; 
      }
      unless ($pub) {
        ($pub) = Chado::Pub->search( miniref => 'null' );
        $pub = $pub->id; #no need to keep whole object when all we want is the id
      }

      print FCV join("\t",($nextfeaturecvterm,$nextfeature,$cache{type}{$term}->id,$pub)),"\n";
      $nextfeaturecvterm++;
    }
  }

  if ($feature->annotation->get_Annotations('Dbxref')) {
    my @dbxrefs = $feature->annotation->get_Annotations('Dbxref');
    foreach my $dbxref (@dbxrefs) {
      my $database  = $dbxref->database;
      my $accession = $dbxref->primary_id;
      my $version;
      if ($accession =~ /\S+\.(\d+)$/) {
        $version    = $1;
      } else {
        $version    = 1; 
      }
      my $desc      = '\N'; #FeatureIO::gff doesn't support descriptions yet

      #enforcing the unique index on dbxref table
      if($cache{dbxref}{"$database|$accession|$version"}){
          print FDBX join("\t",($nextfeaturedbxref,$nextfeature,$nextdbxref)),"\n";
          $nextfeaturedbxref++;
      } else {
          $cache{dbxref}{"$database|$accession|$version"} = 1;

          unless ($cache{db}{$database}) {
              my($db_id) = Chado::Db->search( name => "DB:$database" );
              warn "couldn't find database 'DB:$database' in db table"
                 and next unless $db_id;
              $cache{db}{$database} = $db_id;
          }

          print FDBX join("\t",($nextfeaturedbxref,$nextfeature,$nextdbxref)),"\n";
          $nextfeaturedbxref++;
          print DBX join("\t",($nextdbxref,$cache{db}{$database},$accession,$version,$desc)),"\n";
          $nextdbxref++;
      }
    }
  }

  my @aliases;
  if ($feature->annotation->get_Annotations('Alias')) {
    @aliases = map {$_->value} $feature->annotation->get_Annotations('Alias');
  }
  if ($name ne '\N') {
    push @aliases, $name;
  }

  #need to unique-ify the list
  my %count;
  my @ualiases = grep {++$count{$_} < 2} @aliases;

  foreach my $alias (@ualiases) {
    synonyms($alias);
  }

  if ($ANALYSIS && !$feature->annotation->get_Annotations('Target')) {
    my $source = $feature->source->value;
    my $score = $feature->score->value ? $feature->score->value : '\N';
    $score    = '.' eq $score   ? '\N'            : $score;

    my $featuretype = $feature->type->name;

    my $ankey = $is_FgenesH ?
                'FgenesH_Monocot' :
                $source .'_'. $featuretype;

    unless ($cache{analysis}{$ankey}) {
      my ($ana) = Chado::Analysis->search( name => $ankey );
      die "couldn't find $ankey in analysis table\n" unless $ana;
      $cache{analysis}{$ankey} = $ana->id;
      die unless $cache{analysis}{$ankey};
    }

    print AF join("\t", ($nextanalysisfeature,$nextfeature,$cache{analysis}{$ankey},$score)), "\n";
    $nextanalysisfeature++;
  }

  $nextfeatureloc++;
  #now deal with creating another feature for targets

  if (!$ANALYSIS && $feature->annotation->get_Annotations('Target')) {
    die "Features in this GFF file have Target tags, but you did not indicate\n"
    ."--analysis on the command line";
  }
  elsif ($feature->annotation->get_Annotations('Target')) {
    # get the targets, which are Bio::Annotation::SimpleValue, which in
    # turn are Bio::Location::Simple
    my @targets = $feature->annotation->get_Annotations('Target');
    my $rank = 1;
    foreach my $target (@targets) {
      my $target_id = $target->target_id;
      my $tstart    = $target->start -1; #convert to interbase
      my $tend      = $target->end;
      my $tstrand   = $target->strand ? $target->value->strand : '\N';
      my $tsource   = $feature->source->value;

      synonyms($target_id);

      #warn join("\t", (($feature->annotation->get_Annotations('Parent'))[0]->value,$target_id,$tstart,$tend )) if $feature->annotation->get_Annotations('Parent');

      if ($feature->annotation->get_Annotations('Parent') 
         && $cache{feature}{($feature->annotation->get_Annotations('Parent'))[0]->value}) { 
        print FLOC join("\t", (
             $nextfeatureloc, 
             $nextfeature,
             $cache{feature}{($feature->annotation->get_Annotations('Parent'))[0]->value},
             $tstart, $tend, $tstrand, '\N',$rank)),"\n";
      } else { #this Target needs a feature too
        $nextfeature++;
        $name ||= "$featuretype-$uniquename";
        print F join("\t", ($nextfeature, $organism->id, $name, $target_id.'_'.$nextfeature, $type, $ANALYSIS)),"\n";
        print FLOC join("\t", (
              $nextfeatureloc,
              $nextfeature-1,
              $nextfeature,
              $tstart, $tend, $tstrand, '\N',$rank)),"\n";
      }

      my $score = $feature->score->value ? $feature->score->value : '\N';
      $score    = '.' eq $score   ? '\N'            : $score;

      my $featuretype = $feature->type->name;

      my $type = $cache{type}{$featuretype};
 #     if(!$type){
 #       ($type) = Chado::Cvterm->search( name => $featuretype, cv_id => $sofa_id );
 #       $cache{type}{$featuretype} = $type->id;
 #     }
 #     die "no cvterm for ".$featuretype unless $type;

      my $ankey = $tsource .'_'. $featuretype;

      unless($cache{analysis}{$ankey}) {
        my ($ana) = Chado::Analysis->search( name => $ankey );
        if(!$ana){
          ($ana) = Chado::Analysis->create({
                                            name           => $ankey,
                                            program        => "autocreated by $0",
                                            programversion => "autocreated by $0",
                                           });
          $ana->dbi_commit();
          warn "created analysis for '$ankey'";
        }
        $cache{analysis}{$ankey} = $ana->id;
      }
      die unless $cache{analysis}{$ankey};

      print AF join("\t", ($nextanalysisfeature,$nextfeature,$cache{analysis}{$ankey},$score)), "\n"; 
      $nextanalysisfeature++;

 #     my $target_unique = "target_$target_id";
 #     $t_unique_count{$target_unique}++;
 #     $target_unique .= "_part_$t_unique_count{$target_unique}";
 #     print F join("\t", ($nextfeature, $organism->id, $target_id, $target_unique, $type, $ANALYSIS)),"\n";

      $nextfeatureloc++;
      $rank++;
    }
  }
  $nextfeature++;
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
   "dbxref"               => $nextdbxref,
   "analysisfeature"      => $nextanalysisfeature,
);

print F    "\\.\n\n";
print FLOC "\\.\n\n";
print FREL "\\.\n\n";
print FPROP "\\.\n\n";
print FCV "\\.\n\n";
print SYN "\\.\n\n";
print FS "\\.\n\n";
print FDBX "\\.\n\n";
print DBX "\\.\n\n";
print AF "\\.\n\n";

close F;
close FLOC;
close FREL;
close FPROP;
close FCV;
close SYN;
close FS;
close FDBX;
close DBX;
close AF;

if(!$NOLOAD){
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

}

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

sub synonyms  {
    my $alias = shift;
    unless ($cache{synonym}{$alias}) {
      unless ($cache{type}{'synonym'}) {
        ($cache{type}{'synonym'}) = Chado::Cvterm->search( name => 'synonym' );
        warn "unable to find synonym type in cvterm table"
            and next unless $cache{type}{'synonym'};
      }

      print SYN join("\t", ($nextsynonym,$alias,$cache{type}{'synonym'}->id,$alias)),"\n";

      unless ($pub) {
        ($pub) = Chado::Pub->search( miniref => 'null' );
        $pub = $pub->id; #no need to keep whole object when all we want is the id
      }

      print FS join("\t", ($nextfeaturesynonym,$nextsynonym,$nextfeature,$pub)),"\n";

#        warn "alias:$alias,name:$name\n";

      $nextfeaturesynonym++;
      $cache{synonym}{$alias} = $nextsynonym;
      $nextsynonym++;

    } else {
      print FS join("\t", ($nextfeaturesynonym,$cache{synonym}{$alias},$nextfeature,$pub)),"\n";

#        warn "in seenit, alias:$alias, name:$name\n";

      $nextfeaturesynonym++;
    }
}
