#!perl -w

use Config;
use File::Basename qw(&basename &dirname);
use FindBin '$Bin';
use Cwd;

$origdir = cwd;
chdir dirname($0);
$file = basename($0, '.PL','.PLS');
$file = "gmod_$file.pl";

my %OPTIONS;
if (open F,"$Bin/../../build.conf") {
  while (<F>) {
    next if /^\#/;
    chomp;
    $OPTIONS{$1} = $2 if /^(\w+)\s*=\s*(.+)/;
  }
  close F;
}

open OUT,">$file" or die "Can't create $file: $!";
print OUT "$Config{startperl} -w\n";

if ($OPTIONS{LIB}) {
  print OUT "use lib '$OPTIONS{LIB}';\n";
}
if ($OPTIONS{PREFIX}) {
  print OUT "use lib '$OPTIONS{PREFIX}/lib';\n";
}

print OUT <<'!NO!SUBS!';
use strict;
use DBI;
use Bio::FeatureIO;
use Getopt::Long;
#use Data::Dumper;
use URI::Escape;

# parents come before features
# no residues allowed
# reference sequences already in db!

=head1 NAME

$0 - Bulk loads gff3 files into a chado database.

=head1 SYNOPSIS

  % $0 [options]
  % cat <gff-file> | $0 [options]

=head1 COMMAND-LINE OPTIONS

 --gfffile         The file containing GFF3 (optional, can read 
                     from stdin)
 --organism        The organism for the data
 --dbprofile       Database config profile name
 --dbname          Database name
 --dbuser          Database user name
 --dbpass          Database password
 --dbhost          Database host
 --dbport          Database port
 --analysis        The GFF data is from computational analysis
 --noload          Create bulk load files, but don't actually load them.
 --nosequence      Don't load sequence even if it is in the file
 --notransact      Don't use a single transaction to load the database
 --drop_indexes    Drop indexes of affected tables before starting load
                     and recreate after load is finished; generally
                     does not help performance.
 --validate        Validate SOFA terms before attempting insert (can
                     cause script startup to be slow, off by default)
 --ontology        Give directions for handling misc Ontology_terms
 --skip_vacuum     Skip vacuuming the tables after the inserts
 --inserts         Print INSERT statements instead of COPY FROM STDIN

Note that all of the arguments that begin 'db' as well as organism can
be provided by default by Bio::GMOD::Config, which was installed when
'make install' was run.  Also note the the option dbprofile and all other
db* options are mutually exclusive--if you supply dbprofile, do not
supply any other db* options, as they will not be used.

=head1 DESCRIPTION

The GFF in the datafile must be version 3 due to its tighter control of
the specification and use of controlled vocabulary.  Accordingly, the names
of feature types must be exactly those in the Sequence Ontology Feature
Annotation (SOFA), not the synonyms and not the accession numbers (SO
accession numbers may be supported in future versions of this script).

Note that the ##sequence-region directive is not supported as a way of
declaring a reference sequence for a GFF3 file.  The ##sequence-region
directive is not expressive enough to define what type of thing the
sequence is (ie, is it a chromosome, a contig, an arm, etc?).  If
your GFF file uses a ##sequence-region directive in this way, you
must convert it to a full GFF3 line.  For example, if you have 
this line:

  ##sequence-region chrI 1 9999999

Then is should be converted to a GFF3 line like this:

  chrI	.	chromosome	1	9999999	.	.	.	ID=chrI

=head2 How GFF3 is stored in chado

Here is summary of how GFF3 data is stored in chado:

=over

=item Column 1 (reference sequence)

The reference sequence for the feature becomes the srcfeature_id
of the feature in the featureloc table for that feature.  That featureloc 
generally assigned a rank of zero if there are other locations associated
with this feature (for instance, for a match feature), the other locations
will be assigned featureloc.rank values greater than zero.

=item Column 2 (source)

The source is stored as a dbxref.  The chado instance must of an entry
in the db table named 'GFF_source'.  The script will then create a dbxref
entry for the feature's source and associate it to the feature via
the feature_dbxref table.

=item Column 3 (type)

The cvterm.cvterm_id of the SOFA type is stored in feature.type_id.

=item Column 4 (start)

The value of start minus 1 is stored in featureloc.fmin (one is subtracted
because chado uses interbase coordinates, whereas GFF uses base coordinates).

=item Column 5 (end)

The value of end is stored in featureloc.fmax.

=item Column 6 (score)

The score is stored in one of the score columns in the analysisfeature 
table.  The default is analysisfeature.significance.  See the
section below on analysis results for more information.

=item Column 7 (strand)

The strand is stored in featureloc.strand.

=item Column 8 (phase)

The phase is stored in featureloc.phase.  Note that there is currently
a problem with the chado schema for the case of single exons having 
different phases in different transcripts.  If your data has just such
a case, complain to gmod-schema@lists.sourceforge.net to find ways
to address this problem.

=item Column 9 (group)

Here is where the magic happens.

=over

=item Assigning feature.name, feature.uniquename

The values of feature.name and feature.uniquename are assigned 
according to these simple rules:

=over 

=item If there is an ID tag, that is used as feature.uniquename

otherwise, it is assigned a uniquename that is equal to
'auto' concatenated with the feature_id.

(Note that this is a potential problem as there is no check
to make sure that it is appropriately unique.)

=item If there is a Name tag, it's value is set to feature.name;

otherwise it is null.

Note that these rules are much more simple than that those that
Bio::DB::GFF uses, and may need to be revisited.

=back

=item Assigning feature_relationship entries

All Parent tagged features are assigned feature_relationship
entries of 'part_of' to their parent features.  Derived_from
tags are assigned 'derived_from' relationships.  Note that
parent features must appear in the file before any features
use a Parent or Derived_from tags referring to that feature.

=item Alias tags

Alias values are stored in the synonym table, under
both synonym.name and synonym.synonym_sgml, and are
linked to the feature via the feature_synonym table.

=item Dbxref tags

Dbxref values must be of the form 'db_name:accession', where 
db_name must have an entry in the db table, with a value of 
db.name equal to 'DB:db_name'; several database names were preinstalled
with the database when 'make prepdb' was run.  Execute 'SELECT name
FROM db' to find out what databases are already availble.  New dbxref
entries are created in the dbxref table, and dbxrefs are linked to
features via the feature_dbxref table.

=item Gap tags

Currently is mostly ignored--the value is stored as a featureprop,
but otherwise is not used yet.

=item Note tags

The values are stored as featureprop entries for the feature.

=item Any custom (ie, lowercase-first) tags

Custom tags are supported, provided they already have an entry in the
cvterm table. Their values are stored in the featureprop table with
a type predefined the database administrator.  For example, if you
have a custom tab, 'orf_classification', you need an entry in the
dbxref and cvterm tables something like this:

  INSERT INTO dbxref (db_id,accession)
    VALIES ( (SELECT db_id FROM db WHERE name='null'),
             'autocreated:orf_classification');
  INSERT INTO cvterm (name,dbxref_id,cv_id)
    VALUES ('orf_classification',
             (SELECT cv_id FROM cv WHERE name='local'),
             (SELECT dbxref_id FROM dbxref WHERE accession='autocreated:orf_classification'));

=item Ontology_term

When the Ontology_term tags are used, items from the Gene Ontology
and Sequence Ontology will be processed automatically when the standard
DB:accession format is used (e.g. GO:0001234).  To use other ontology
terms, you must specify that mapping of the DB indentifiers in the GFF
file and the name of the ontologies in the cv table as a comma separated
tag=value pairs.  For example, to use plant and cell ontology terms,
you would supply on the command line:

  --ontology 'PO=plant ontology,CL=cell ontology'

where 'plant ontology' and 'cell ontology' are the names in the cv table
exactly as they appear.

=item Target tags

Proper processing of Target tags requires that there be two source features
already available in the database, the 'primary' source feature (the
chromosome or contig) and the 'subject' from the similarity analysis,
like an EST, cDNA or syntenic chromosome.  If the subject feature is not
present, the loader will attempt to create a placeholder feature object
in its place.  If you have a fasta file the contains the subject, you can
use the perl script, L<gmod_fasta2gff3.pl>, that comes with this distribution
to make a GFF3 file suitable for loading into chado before loading your
analysis results.

=back

=back

=head2 NOTES

=over

=item ##sequence-region

This script does not use sequence-region directives for anything.
If it represents a feature that needs to be inserted into the database,
it should be represented with a full GFF line.  This includes the
reference sequence for the features if it is not already in the database,
like a chromosome.  For example, this:

  ##sequence-region chr1 1	213456789

should change to this:

  chr1	UCSC	chromosome	1	213456789	.	.	.	ID=chr1

=item Transactions

This application will, by default, try to load all of the data at
once as a single transcation.  This is safer from the database's
point of view, since if anything bad happens during the load, the 
transaction will be rolled back and the database will be untouched.  
The problem occurs if there are many (say, greater than a 2-300,000)
rows in the GFF file.  When that is the case, doing the load as 
a single transcation can result in the machine running out of memory
and killing processes.  If --notranscat is provided on the commandline,
each table will be loaded as a separate transaction.

=item SQL INSERTs versus COPY FROM

This bulk loader was originally designed to use the PostgreSQL
COPY FROM syntax for bulk loading of data.  However, as mentioned
in the 'Transactions' section, memory issues can sometimes interfere
with such bulk loads.  In another effort to circumvent this issue,
the bulk loader has been modified to optionally create INSERT statements
instead of the COPY FROM statements.  INSERT statements will load
much more slowly than COPY FROM statements, but as they load and
commit individually, they are more more likely to complete successfully.
As an indication of the speed differences involved, loading 
yeast GFF3 annotations (about 16K rows), it takes about 5 times
longer using INSERTs versus COPY on my laptop.

=item Sequence

By default, if there is sequence in the GFF file, it will be loaded
into the residues column in the feature table row that corresponds
to that feature.  By supplying the --nosequence option, the sequence
will be skipped.  You might want to do this if you have very large
sequences, which can be difficult to load.  In this context, "very large"
means more than 200MB.

Also note that for sequences to load properly, the GFF file must have
the ##FASTA directive (it is required for proper parsing by Bio::FeatureIO),
and the ID of the feature must be exactly the same as the name of the
sequence following the > in the fasta section.

=item The ORGANISM table

This script assumes that the organism table is populated with information
about your organism.  If you are unsure if that is the case, you can
execute this command from the psql command-line:

  select * from organism;

If you do not see your organism listed, execute this command to insert it:

  insert into organism (abbreviation, genus, species, common_name)
                values ('H.sapiens', 'Homo','sapiens','Human');

substituting in the appropriate values for your organism.

=item Parents/children order

Parents must come before children in the GFF file.

=item Analysis

If you are loading analysis results (ie, blat results, gene predictions), 
you should specify the -a flag.  If no arguments are supplied with the
-a, then the loader will assume that the results belong to an analysis
set with a name that is the concatenation of the source (column 2) and
the method (column 3) with an underscore in between.  Otherwise, the
argument provided with -a will be taken as the name of the analysis
set.  Either way, the analysis set must already be in the analysis
table.  The easist way to do this is to insert it directly in the
psql shell:

  INSERT INTO analysis (name, program, programversion)
               VALUES  ('genscan 2005-2-28','genscan','5.4');

There are other columns in the analysis table that are optional; see
the schema documentation and '\d analysis' in psql for more information.

Chado has four possible columns for storing the score in the GFF score 
column; please use whichever is most appropriate and identifiy it 
with --score_col flag (significance is the default). Note that the name
of the column can be shortened to one letter.  If you have more than
one score associated with each feature, you can put the other scores in
the ninth column as a tag=value pair, like 'identity=99', and the
bulk loader will put it in the featureprop table (provided there
is a cvterm for identity; see the section above concerning custom
tags).  Available options are:

=over

=item significance (default)

=item identity

=item normscore

=item rawscore

=back

A planned addtion to the functionality of handling analysis results
is to allow "mixed" GFF files, where some lines are analysis results
and some are not.  Additionally, one will be able to supply lists
of types (optionally with sources) and their associated entry in the
analysis table.  The format will probably be tag value pairs:

  --analysis match:Rice_est=rice_est_blast, \
             match:Maize_cDNA=maize_cdna_blast, \
             mRNA=genscan_prediction,exon=genscan_prediction

=back

=head1 AUTHORS

Allen Day E<lt>allenday@ucla.eduE<gt>, Scott Cain E<lt>cain@cshl.orgE<gt>

Copyright (c) 2004

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

my ($ORGANISM, $GFFFILE,$DBPROFILE, $DBNAME, $DBUSER, $DBPASS,$DBHOST, $DBPORT, 
    $ANALYSIS, $ANALYSIS_GROUP, $GLOBAL_ANALYSIS, $NOLOAD, $VALIDATE, $INSERTS,
    $NOTRANSACT, $NOSEQUENCE, $SCORE_COL, $ONTOLOGY, $SKIP_VACUUM,$DROP_INDEX);

GetOptions(
    'organism=s' => \$ORGANISM,
    'gfffile=s'  => \$GFFFILE,
    'dbprofile=s'=> \$DBPROFILE,
    'dbname=s'   => \$DBNAME,
    'dbuser=s'   => \$DBUSER,
    'dbpass=s'   => \$DBPASS,
    'dbhost=s'   => \$DBHOST,
    'dbport=s'   => \$DBPORT,
    'analysis:s' => \$ANALYSIS, # = means it is required, : means optional
    'noload'     => \$NOLOAD,
    'validate'   => \$VALIDATE,
    'notransact' => \$NOTRANSACT,
    'nosequence' => \$NOSEQUENCE,
    'score_col=s'=> \$SCORE_COL,
    'ontology=s' => \$ONTOLOGY,
    'skip_vacuum'=> \$SKIP_VACUUM,
    'drop_indexes'=>\$DROP_INDEX,
    'inserts'    => \$INSERTS,
) or ( system( 'pod2text', $0 ), exit -1 );;


unless ($DBNAME) {
    if (eval {require Bio::GMOD::Config;
          Bio::GMOD::Config->import();
          require Bio::GMOD::DB::Config;
          Bio::GMOD::DB::Config->import();
          1;  } ) {
        my $gmod_conf = $ENV{'GMOD_ROOT'} || "/var/lib/gmod" ?
                  Bio::GMOD::Config->new($ENV{'GMOD_ROOT'} || "/var/lib/gmod") :
                  Bio::GMOD::Config->new();

        my $profile = $DBPROFILE || 'default';
        my $db_conf = Bio::GMOD::DB::Config->new($gmod_conf,$profile);
        $DBNAME    = $db_conf->name();
        $DBUSER    = $db_conf->user();
        $DBPASS    = $db_conf->password();
        $DBHOST    = $db_conf->host();
        $DBPORT    = $db_conf->port();
        $ORGANISM ||= $db_conf->organism();
    }
}

$ORGANISM ||='human';
$GFFFILE  ||='stdin';  #nobody better name their file 'stdin'
#$DBNAME   ||='chado';
$DBPASS   ||='';
$DBHOST   ||='localhost';
$DBPORT   ||='5432';
$VALIDATE ||=0;
$NOTRANSACT ||=0;
$NOSEQUENCE ||=0;
$INSERTS    ||=0;
$SCORE_COL  ||='significance';

die "You must supply a database name" unless $DBNAME;

$GLOBAL_ANALYSIS=0;
if ((defined $ANALYSIS) and ($ANALYSIS eq '')) { 
  $ANALYSIS = 1; #ie, it was specified on the command line with no arg
} elsif ($ANALYSIS) {
  $GLOBAL_ANALYSIS = 1;
  $ANALYSIS_GROUP = $ANALYSIS; # analysis group specified on the command line
  $ANALYSIS = 1;
} else {
  $ANALYSIS = 0;
}

my %uniquename_cache;
my %cache = (
             analysis => {},
             db       => {}, #db.db_id cache
             dbxref   => {},
             feature  => {},
             parent   => {}, #featureloc.srcfeature_id ; parent feature
             source   => {}, #dbxref.dbxref_id ; gff_source
             synonym  => {},
             type     => {}, #cvterm.cvterm_id cache
             ontology => {},
            );

#if we need custom ontology mapping, cache them here
if ($ONTOLOGY) {
  my @pairs = split /\,/, $ONTOLOGY;
  foreach (@pairs) {
    my ($tag, $value) = split/\=/;
    $cache{ontology}{$tag} = $value;
  } 
}


#let's track unique constraints
my %constraint = ();
#feature_cvterm_c1 => {}, #{feature_id}{cvterm_id}
#feature_dbxref_c1 => {}, #{feature_id}{dbxref_id}
#featureprop_c1     => {}, #{feature_id}{type_id}{rank}
#feature_synonym_c1 => {}, #{feature_id}{synonym_id}

#allow a feature_id to be referenced by multiple featureloc.feature_id's
my %locgroup = ();


#my %t_unique_count;
my $pub; # for holding null pub object
my $gff_source_db;
my $auto_cv_id;
my $source_success = 1; #indicates that GFF_source is in db table
my @tables = (
   "feature",#
   "featureloc",#
   "feature_relationship",#
   "featureprop",#
   "feature_cvterm",#
   "synonym",#
   "feature_synonym",#
   "dbxref",#
   "feature_dbxref",#
   "analysisfeature",
);
my %files = (
   feature              => "/tmp/feature.tmp",
   featureloc           => "/tmp/featureloc.tmp",
   feature_relationship => "/tmp/feature_relationship.tmp",
   featureprop          => "/tmp/featureprop.tmp",
   feature_cvterm       => "/tmp/feature_cvterm.tmp",
   synonym              => "/tmp/synonym.tmp",
   feature_synonym      => "/tmp/feature_synonym.tmp",
   dbxref               => "/tmp/dbxref.tmp",
   feature_dbxref       => "/tmp/feature_dbxref.tmp",
   analysisfeature      => "/tmp/analysisfeature.tmp",
   sequence             => "/tmp/sequence.tmp",
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
   feature              => "(feature_id,organism_id,name,uniquename,type_id,is_analysis,seqlen)",
   featureloc           => "(featureloc_id,feature_id,srcfeature_id,fmin,fmax,strand,phase,rank,locgroup)",
   feature_relationship => "(feature_relationship_id,subject_id,object_id,type_id)",
   featureprop          => "(featureprop_id,feature_id,type_id,value,rank)",
   feature_cvterm       => "(feature_cvterm_id,feature_id,cvterm_id,pub_id)",
   synonym              => "(synonym_id,name,type_id,synonym_sgml)",
   feature_synonym      => "(feature_synonym_id,synonym_id,feature_id,pub_id)",
   dbxref               => "(dbxref_id,db_id,accession,version,description)",
   feature_dbxref       => "(feature_dbxref_id,feature_id,dbxref_id)",
   analysisfeature      => "(analysisfeature_id,feature_id,analysis_id,significance,rawscore,normscore,identity)",
);


########################
my $db = DBI->connect("dbi:Pg:dbname=$DBNAME;port=$DBPORT;host=$DBHOST",
                       $DBUSER,$DBPASS, {AutoCommit => $NOTRANSACT});

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

$sth = $db->prepare("select cvterm_id from cvterm where name = 'derives_from'");
$sth->execute;
my($derives_from) = $sth->fetchrow_array();

$sth = $db->prepare("select cv_id from cv where name = 'sequence'");
$sth->execute;
my($sofa_id) =  $sth->fetchrow_array();

#backup plan for old chado instances
if(!defined($sofa_id)){
  $sth = $db->prepare("select cv_id from cv where name = 'Sequence Ontology Feature Annotation' or name='sofa.ontology'");
  $sth->execute;
  ($sofa_id) =  $sth->fetchrow_array();
}

#backup plan for really old chado instances
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
#
# I don't want to do this due to overhead issues
#my %label = (
#             #add more tables here.  key is tablename,
#             #value is label to lookup by.
#             analysis => 'name',
#             synonym  => 'name',
#             dbxref   => 'accession',
#            );
#
#my $iterator;
#
#foreach my $table (keys %label){
#  print STDERR "caching $table... ";
#  my $class = 'Chado::'.ucfirst($table);
#  $iterator = $class->retrieve_all();
#  my $label = $label{$table};
#  while(my $obj = $iterator->next()){
#    $cache{$table}{$obj->$label} = $obj;
#  }
#  print STDERR "done!\n";
#}
#
#
# End load cache.
#######################################################



$sth->finish;
########################

#######################################################
#prepare a bunch of sql queries to be used in the loop:
#
#my $search_uniquename 
#   = $db->prepare("SELECT feature_id FROM feature WHERE uniquename=?");
#my $validate_uniquename
#  = $db->prepare("SELECT count(*) FROM feature where uniquename=?
#                                                  and type_id = ?
#                                                  and organism_id = ?");
my $search_name
   = $db->prepare("SELECT feature_id FROM feature WHERE name=?");
my $count_name
   = $db->prepare("SELECT COUNT(*) FROM feature WHERE name=?");
my $search_cvterm_id
   = $db->prepare("SELECT cvterm_id FROM cvterm WHERE name=? AND cv_id=?");
my $search_source_dbxref
   = $db->prepare("SELECT dbxref_id FROM dbxref WHERE accession=? AND db_id=?");
my $search_dbxref
   = $db->prepare("SELECT dbxref_id FROM dbxref WHERE accession=? AND db_id in (SELECT db_id FROM db WHERE name like ? OR name like ?)");
my $search_cvterm_id_w_dbxref
   = $db->prepare("SELECT cvterm_id FROM cvterm WHERE dbxref_id=?");
my $search_db
   = $db->prepare("SELECT db_id FROM db WHERE name =?");
my $search_long_dbxref
   = $db->prepare("SELECT dbxref_id FROM dbxref WHERE accession =? 
                                                  AND version =?
                                                  AND db_id =?");
my $search_analysis
   = $db->prepare("SELECT analysis_id FROM analysis WHERE name=?");
my $search_synonym
   = $db->prepare("SELECT synonym_id FROM synonym WHERE name=? 
                                                    AND type_id=?");

$sth = $db->prepare("SELECT organism_id FROM organism WHERE common_name = ?");
$sth->execute($ORGANISM);
my @row_array = $sth->fetchrow_array;
my $organism = $row_array[0];
undef $sth;
undef @row_array;

$organism or die "$ORGANISM organism not found in the database";

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

my $gffio;
if ($GFFFILE eq 'stdin') {
    $gffio = Bio::FeatureIO->new(-fh   => \*STDIN , 
                                 -format => 'gff', 
                                 -validate_terms => $VALIDATE);
} else {
    $gffio = Bio::FeatureIO->new(-file => $GFFFILE, 
                                 -format => 'gff', 
                                 -validate_terms => $VALIDATE);
}

print STDERR "Creating a uniquename cache...";
my $unique_cache = $db->prepare(
     "select feature_id,uniquename,type_id,organism_id from feature");
$unique_cache->execute();

while (my $un_hash = $unique_cache->fetchrow_hashref() ) {
    my $tmp_name = $$un_hash{'uniquename'};
    $uniquename_cache{$tmp_name}{'feature_id'} = $$un_hash{'feature_id'};
    $uniquename_cache{$tmp_name}{'type_id'}    = $$un_hash{'type_id'};
    $uniquename_cache{$tmp_name}{'organism_id'}= $$un_hash{'organism_id'};
}
$unique_cache->finish();
warn "done\n";

warn "Preparing data for inserting into the $DBNAME database\n";
warn "(This may take a while ...)\n";

while(my $feature = $gffio->next_feature()){
  my $featuretype = $feature->type->name;

  my $type           = get_type($featuretype);
  my ($src, $seqlen) = get_src_seqlen($feature);

  if(!$src){
    $src = src_second_chance($feature);
  }
  die "no feature for ".$feature->seq_id->value unless $src;

  if($feature->annotation->get_Annotations('Parent')){
    handle_parent($feature);
  }

  if($feature->annotation->get_Annotations('Derives_from')){
    handle_derives_from($feature);
  }

  my $source      = $feature->source->value;

  my($uniquename) = ($feature->annotation->get_Annotations('ID'))[0]
                   || "auto$nextfeature";
  $uniquename     = $uniquename->value if ref($uniquename);

  $uniquename     = uniquename_validation( $uniquename,
                                       $type,
                                       $organism,
                                       $nextfeature);

  my($name)       = ($feature->annotation->get_Annotations('Name'))[0]
                   ||($feature->annotation->get_Annotations('ID'))[0]
                   || "$featuretype-$uniquename";
  $name           = $name->value if ref($name);

  #my $uniquename = $nextfeature;
  $cache{parent}{$uniquename} ||= $nextfeature;
  if($cache{feature}{$uniquename}){
    #seen this feature before
    $locgroup{$uniquename}++;
  }
  else {
    print_f($nextfeature,$organism,$name,$uniquename,$type,$ANALYSIS,$seqlen);

    $cache{feature}{$uniquename} = $nextfeature;
    $cache{parent}{$uniquename}  = $nextfeature;
    $locgroup{$uniquename}       = 0;
  }

  #FIXME potential $nextfeature bug
  if ($ANALYSIS 
      && $featuretype =~ /match/  
      && !$feature->annotation->get_Annotations('Target')) {
    $cache{feature}{($feature->annotation->get_Annotations('ID'))[0]->value} = $nextfeature;
  }


#don't write a featureloc entry for srcfeatures
  unless ($src eq '\N' or $src == $nextfeature) {
#need to convert from base to interbase coords
    my $start = $feature->start eq '.' ? '\N' : ($feature->start - 1);
    my $end   = $feature->end   eq '.' ? '\N' : defined($feature->end) ? $feature->end : '\N';
    my $phase = ($feature->phase->value eq '.' or $feature->phase->value eq '') ? '\N' : $feature->phase->value;

    print_floc($nextfeatureloc, $cache{feature}{$uniquename}, $src, $start, $end, $feature->strand, $phase,'0',$locgroup{$uniquename});
  }

  if ($feature->annotation->get_Annotations('Gap')) {
    handle_gap($feature,$uniquename);
  }


  if ($feature->annotation->get_Annotations('Note')) {
    handle_note($feature,$uniquename);
  }

#try to put unreserved tags in featureprop
#this requires that the terms exist in cvterm (and therefore that they
#have a dbxref)
  my @unreserved_tags = grep {/^[a-z]/} $feature->annotation->get_all_annotation_keys();
  if ( @unreserved_tags > 0 ) {
    handle_unreserved_tags($feature,$uniquename,@unreserved_tags);
  }

  if ( $source_success && $source && $source ne '.') {
    handle_source($feature,$uniquename,$source);
  }

  if ($feature->annotation->get_Annotations('Ontology_term')) {
    handle_ontology_term($feature,$uniquename);
  }

  if ($feature->annotation->get_Annotations('Dbxref')) {
    handle_dbxref($feature,$uniquename);
  }

  my @aliases;
  if ($feature->annotation->get_Annotations('Alias')) {
    @aliases = map {$_->value} $feature->annotation->get_Annotations('Alias');
  }
  if ($name ne '\N') {
    push @aliases, $name;
  }
  push @aliases, $uniquename;

  #need to unique-ify the list
  my %count;
  my @ualiases = grep {++$count{$_} < 2} @aliases;

  foreach my $alias (@ualiases) {
    synonyms($alias,$cache{feature}{$uniquename});
  }

  if ($ANALYSIS && !$feature->annotation->get_Annotations('Target')) {
    handle_nontarget_analysis($feature,$uniquename);
  }

  $nextfeatureloc++;
  #now deal with creating another feature for targets

  if (!$ANALYSIS && $feature->annotation->get_Annotations('Target')) {
    die "Features in this GFF file have Target tags, but you did not indicate\n"
    ."--analysis on the command line";
  }
  elsif ($feature->annotation->get_Annotations('Target')) {
      handle_target($feature, $uniquename,$name,$featuretype,$type);
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

print F     "\\.\n\n" unless $INSERTS;
print FLOC  "\\.\n\n" unless $INSERTS;
print FREL  "\\.\n\n" unless $INSERTS;
print FPROP "\\.\n\n" unless $INSERTS;
print FCV   "\\.\n\n" unless $INSERTS;
print SYN   "\\.\n\n" unless $INSERTS;
print FS    "\\.\n\n" unless $INSERTS;
print FDBX  "\\.\n\n" unless $INSERTS;
print DBX   "\\.\n\n" unless $INSERTS;
print AF    "\\.\n\n" unless $INSERTS;

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

#$search_uniquename->finish;
#$validate_uniquename->finish;
$search_name->finish;
$count_name->finish;
$search_cvterm_id->finish;
$search_source_dbxref->finish;
$search_dbxref->finish;
$search_cvterm_id_w_dbxref->finish;
$search_db->finish;
$search_long_dbxref->finish;
$search_analysis->finish;
$search_synonym->finish;

#deal with sequence 
unless ($NOSEQUENCE) {
  open SEQ, ">$files{sequence}" or die;
  while (my $seq = $gffio->next_seq) {
    my $string = $seq->seq();
    my $name   = $seq->display_id();
    print SEQ "UPDATE feature set residues='$string' WHERE uniquename='$name';\n";
    print SEQ "UPDATE feature set seqlen=length(residues) WHERE uniquename='$name';\n";
  }
  close SEQ;
}

if(!$NOLOAD){
  if ($DROP_INDEX) {
    warn "Dropping indexes...\n";
    drop_indexes($db) if $DROP_INDEX;
  }

  foreach my $table (@tables) {
    copy_from_stdin($db,$table,
                    $copystring{$table},
                    $files{$table},
                    $sequences{$table},
                    $nextvalue{$table});
  }

  ($db->commit || die "commit failed: ".$db->errstr()) unless $NOTRANSACT;
  $db->{AutoCommit}=1;

  #load sequence
  unless ($NOSEQUENCE) {
    warn "Loading sequences (if any) ...\n";
    open SEQ, $files{sequence} or die;
    while (<SEQ>) {
      chomp;
      $db->do($_);
    }
    close SEQ;
  }

  if ($DROP_INDEX) {
    warn "Recreating indexes...\n";
    create_indexes($db) if $DROP_INDEX;
  }

  unless ($SKIP_VACUUM) {
    warn "Optimizing database (this may take a while) ...\n";
    print STDERR "  (";
    foreach (@tables) {
      print STDERR "$_ "; 
      $db->do("VACUUM ANALYZE $_");
    }
  }

  print STDERR ") Done.\n";
  $db->disconnect;

  warn "Deleting temporary files\n";
  foreach (keys %files) {
    unlink $files{$_};
  }

  warn "\nWhile this script has made an effort to optimize the database, you\n"
    ."should probably also run VACUUM FULL ANALYZE on the database as well\n";

}

exit(0);

sub get_type {
    my ($featuretype) = @_;

    return $cache{type}{$featuretype} if defined $cache{type}{$featuretype};

    $search_cvterm_id->execute($featuretype, $sofa_id);
    ($cache{type}{$featuretype}) = $search_cvterm_id->fetchrow_array;

    return $cache{type}{$featuretype} if defined $cache{type}{$featuretype};

    die "no cvterm for ".$featuretype;
}

sub get_src_seqlen {
    my ($feature) = @_;

    my ($src,$seqlen);
    if ( defined (($feature->annotation->get_Annotations('ID'))[0])
         && $feature->seq_id->value
          eq ($feature->annotation->get_Annotations('ID'))[0]) {
        #this is a srcfeature (ie, a reference sequence)
      $src = $nextfeature;
      $cache{parent}{$feature->seq_id->value} = $src;
      $seqlen = $feature->end - $feature->start +1;
    } else { # normal case
      $src = $cache{parent}{$feature->seq_id->value};
      $seqlen = '\N';
    }

    return ($src,$seqlen);
}

sub src_second_chance {
    my ($feature) = @_;

    my $src;
    if($feature->seq_id->value eq '.'){
      $src = '\N';
    } else {

      ($cache{parent}{$feature->seq_id->value})
            = $uniquename_cache{$feature->seq_id->value}{'feature_id'};

      unless ($cache{parent}{$feature->seq_id->value}) {
        $count_name->execute($feature->seq_id->value);
        my ($n_rows) = $count_name->fetchrow_array;
        if (1 < $n_rows) {
          die "more that one source for ".$feature->seq_id->value;
        } elsif ( 1==$n_rows) {
          $search_name->execute($feature->seq_id->value);
          ($cache{parent}{$feature->seq_id->value})
              = $search_name->fetchrow_array;
        } else {
          die "Unable to find srcfeature "
               .$feature->seq_id->value
               ." in the database\n";
        }
      }
      $src = $cache{parent}{$feature->seq_id->value};
    }

    return $src;
}

sub handle_derives_from {
    my ($feature) = @_;

    my $pname  = undef;
    ($pname)   = ($feature->annotation->get_Annotations('Derives_from'))[0]->value;
    my $parent = $cache{parent}{$pname};
    die "no parent ".$pname unless $parent;

    print_frel($nextfeaturerel,$nextfeature,$parent,$derives_from);
    $nextfeaturerel++;
}

sub handle_parent {
    my ($feature) = @_;

    my $pname  = undef;
    ($pname)   = ($feature->annotation->get_Annotations('Parent'))[0]->value;
    my $parent = $cache{parent}{$pname};
    die "no parent ".$pname unless $parent;

    print_frel($nextfeaturerel,$nextfeature,$parent,$part_of);

    $nextfeaturerel++;
}

sub handle_gap {
    my ($feature,$uniquename) = @_;

    my @notes = map {$_->value} $feature->annotation->get_Annotations('Gap');
    my $rank = 0;
    foreach my $note (@notes) {
      unless ($cache{type}{'Gap'}) {
          my $sth =
              $db->prepare("SELECT cvterm_id FROM cvterm WHERE name='Gap'
                            AND cv_id in
                              (SELECT cv_id FROM cv WHERE name='null' OR
                                                          name='local')");
          $sth->execute();
          ($cache{type}{'Gap'}) = $sth->fetchrow_array;
      }

      if ( !$constraint{featureprop_c1}{ $cache{feature}{$uniquename} }{ $cache{type}{'Gap'}}{ $rank } ) {
        $constraint{featureprop_c1}{ $cache{feature}{$uniquename} }{ $cache{type}{'Gap'}}{ $rank }++;
        print_frop($nextfeatureprop,$cache{feature}{$uniquename},$cache{type}{'Gap'},uri_unescape($note),$rank);
        $rank++;
        $nextfeatureprop++;
      }
    }
}

sub handle_note {
    my ($feature,$uniquename) = @_;

    my @notes = map {$_->value} $feature->annotation->get_Annotations('Note');
    my $rank = 0;
    foreach my $note (@notes) {
      unless ($cache{type}{'Note'}) {
          my $sth =
              $db->prepare("SELECT cvterm_id FROM cvterm WHERE name='Note'
                            AND cv_id in
                              (SELECT cv_id FROM cv WHERE name='null' OR
                                                          name='local')");
          $sth->execute();
          ($cache{type}{'Note'}) = $sth->fetchrow_array;
      }

      if ( !$constraint{featureprop_c1}{ $cache{feature}{$uniquename} }{ $cache{type}{'Note'}}{ $rank } ) {
        $constraint{featureprop_c1}{ $cache{feature}{$uniquename} }{ $cache{type}{'Note'}}{ $rank }++;
        print_fprop($nextfeatureprop,$cache{feature}{$uniquename},$cache{type}{'Note'},uri_unescape($note),$rank);
        $rank++;
        $nextfeatureprop++;
      }
    }
}

sub handle_unreserved_tags {
    my ($feature,$uniquename,@unreserved_tags) = @_;

    foreach my $tag (@unreserved_tags) {
      next if $tag eq 'source';
      next if $tag eq 'phase';
      next if $tag eq 'seq_id';
      next if $tag eq 'type';
      next if $tag eq 'score';
      next if $tag eq 'dbxref';

      unless ($auto_cv_id){
        my $sth = $db->prepare("SELECT cv_id FROM cv WHERE name='autocreated'");
        $sth->execute;
        ($auto_cv_id) = $sth->fetchrow_array;
      }

      unless ( $cache{type}{$tag} ) {
        $search_cvterm_id->execute($tag, $auto_cv_id);
        my ($tag_cvterm) = $search_cvterm_id->fetchrow_array;
        if ($tag_cvterm) { #good, the term is already there
          $cache{type}{$tag} = $tag_cvterm;
        } else { #bad! the term is not there for now we die with a helpful message
          dbxref_error_message($tag) && die;
        }
      }

      #moving on, add this to the featureprop table
      my @values = map {$_->value} $feature->annotation->get_Annotations($tag);
      my $rank=0;
      foreach my $value (@values) {
        print_fprop($nextfeatureprop,$cache{feature}{$uniquename},$cache{type}{$tag},$value,$rank);
        $rank++;
        $nextfeatureprop++;
      }
    }
}

sub handle_source {
    my ($feature,$uniquename,$source) = @_;

    unless ($gff_source_db) {
      my $sth = $db->prepare("SELECT db_id FROM db WHERE name='GFF_source'");
      $sth->execute;
      ($gff_source_db) = $sth->fetchrow_array;
    }

    if ($gff_source_db) {
      unless ($cache{dbxref}{$source}) {
        #first, check if this source is already in the database

        $search_source_dbxref->execute($source, $gff_source_db);
        my ($chado_source) = $search_source_dbxref->fetchrow_array;

        if ($chado_source) {
          $cache{dbxref}{$source} = $chado_source;
        } else {
          $cache{dbxref}{$source} = $nextdbxref;
          print_dbx($nextdbxref,$gff_source_db,$source,1,'\N');
          $nextdbxref++;
        }
      }
      my $dbxref_id = $cache{dbxref}{$source};
      if(!$constraint{feature_dbxref_c1}{ $cache{feature}{$uniquename} }{$dbxref_id}){
        $constraint{feature_dbxref_c1}{ $cache{feature}{$uniquename} }{$dbxref_id}++;
        print_fdbx($nextfeaturedbxref,$cache{feature}{$uniquename},$dbxref_id);
        $nextfeaturedbxref++;
      }
    } else {
      $source_success = 0; #geting GFF_source failed, so don't try anymore
    }
}

sub handle_ontology_term {
    my ($feature,$uniquename) = @_;

    my @cvterms = map {$_->identifier} $feature->annotation->get_Annotations('Ontology_term');
    my %count;
    my @ucvterms = grep {++$count{$_} < 2} @cvterms;
    foreach my $term (@ucvterms) {
      next unless $term;
      unless ($cache{type}{$term}) {
        my($d,$a) = $term =~ /^(.+?):(.+?)$/;

        my $db_name;
        if ($d eq 'GO') {
          $search_dbxref->execute($a,'%Gene Ontology%'   ,'GO');
        } elsif ($d eq 'SO') {
          $search_dbxref->execute($a,'Sequence Ontology' ,'SO');
        } elsif ($cache{ontology}{$d}) {
          $search_dbxref->execute($a,$cache{ontology}{$d}, $d );
        }

        my ($dbxref) = $search_dbxref->fetchrow_array;
        warn "couldn't find $term in dbxref for db:$cache{ontology}{$d} ($d)\n" and next unless $dbxref;

        $search_cvterm_id_w_dbxref->execute($dbxref);
        ($cache{type}{$term}) = $search_cvterm_id_w_dbxref->fetchrow_array;
        warn "couldn't find $term 's cvterm_id in cvterm table\n"
          and next unless $cache{type}{$term};
      }
      unless ($pub) {
        my $sth = $db->prepare("SELECT pub_id FROM pub WHERE miniref = 'null'");
        $sth->execute;
        ($pub) = $sth->fetchrow_array;
      }

      if(!$constraint{feature_cvterm_c1}{ $cache{feature}{$uniquename} }{ $cache{type}{$term} }){
        $constraint{feature_cvterm_c1}{ $cache{feature}{$uniquename} }{ $cache{type}{$term} }++;
        print_fcv($nextfeaturecvterm,$cache{feature}{$uniquename},$cache{type}{$term},$pub);
        $nextfeaturecvterm++;
      }
    }
}

sub handle_dbxref {
    my ($feature,$uniquename) = @_;

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
      if(my $temp_id = $cache{dbxref}{"$database|$accession|$version"}){
        if(!$constraint{feature_dbxref_c1}{ $cache{feature}{$uniquename} }{$temp_id}){
          $constraint{feature_dbxref_c1}{ $cache{feature}{$uniquename} }{$temp_id}++;
          print_fdbx($nextfeaturedbxref,$cache{feature}{$uniquename},$temp_id);
          $nextfeaturedbxref++;
        }
      } else {
          unless ($cache{db}{$database}) {
              $search_db->execute("DB:$database");
              my($db_id) = $search_db->fetchrow_array;
              warn "couldn't find database 'DB:$database' in db table"
                 and next unless $db_id;
              $cache{db}{$database} = $db_id;
          }

          #check for an existing dbxref--this could slow things down a lot!
          $search_long_dbxref->execute($accession,
                                       $version,$cache{db}{$database});
          my ($existing_dbxref) = $search_long_dbxref->fetchrow_array;
          if ($existing_dbxref) {
            if(!$constraint{feature_dbxref_c1}{ $cache{feature}{$uniquename} }{$existing_dbxref}){
              $constraint{feature_dbxref_c1}{ $cache{feature}{$uniquename} }{$existing_dbxref}++;
              print_fdbx($nextfeaturedbxref,$cache{feature}{$uniquename},$existing_dbxref);
              $nextfeaturedbxref++;
            }
            $cache{dbxref}{"$database|$accession|$version"} = $existing_dbxref;
          } else {
            if(!$constraint{feature_dbxref_c1}{ $cache{feature}{$uniquename} }{$nextdbxref}){
              $constraint{feature_dbxref_c1}{ $cache{feature}{$uniquename} }{$nextdbxref}++;
              print_fdbx($nextfeaturedbxref,$cache{feature}{$uniquename},$nextdbxref);
              $nextfeaturedbxref++;
            }
            print_dbx($nextdbxref,$cache{db}{$database},$accession,$version,$desc);
            $cache{dbxref}{"$database|$accession|$version"} = $nextdbxref;
            $nextdbxref++;
          }
      }
    }
}

sub handle_nontarget_analysis {
    my ($feature,$uniquename) = @_;
    my $source = $feature->source->value;
    my $score = $feature->score->value ? $feature->score->value : '\N';
    $score    = '.' eq $score   ? '\N'            : $score;

    my $featuretype = $feature->type->name;

    my $ankey = $GLOBAL_ANALYSIS ?
                $ANALYSIS_GROUP :
                $source .'_'. $featuretype;

    unless ($cache{analysis}{$ankey}) {
      $search_analysis->execute($ankey);
      my ($ana) = $search_analysis->fetchrow_array;
      dump_ana_contents($ankey) unless $ana;
      $cache{analysis}{$ankey} = $ana;
    }
    dump_ana_contents($ankey) unless $cache{analysis}{$ankey};

    my $score_string;
    if      ($SCORE_COL =~ /^[Ss]/) {
        $score_string = "$score\t\\N\t\\N\t\\N";
      } elsif ($SCORE_COL =~ /^[Rr]/) {
        $score_string = "\\N\t$score\t\\N\t\\N";
      } elsif ($SCORE_COL =~ /^[Nn]/) {
        $score_string = "\\N\t\\N\t$score\t\\N";
      } elsif ($SCORE_COL =~ /^[Ii]/) {
        $score_string = "\\N\t\\N\t\\N\t$score";
    }

    print_af($nextanalysisfeature,$cache{feature}{$uniquename},$cache{analysis}{$ankey},$score_string);
    $nextanalysisfeature++;
}

sub handle_target {
    my ($feature, $uniquename,$name,$featuretype,$type) = @_;

    my @targets = $feature->annotation->get_Annotations('Target');
    my $rank = 1;
    foreach my $target (@targets) {
      my $target_id = $target->target_id;
      my $tstart    = $target->start -1; #convert to interbase
      my $tend      = $target->end;
      my $tstrand   = $target->strand ? $target->strand : '\N';
      my $tsource   = $feature->source->value;

      synonyms($target_id,$cache{feature}{$uniquename});

      #warn join("\t", (($feature->annotation->get_Annotations('Parent'))[0]->value,$target_id,$tstart,$tend )) if $feature->annotation->get_Annotations('Parent');

      if ($feature->annotation->get_Annotations('Parent')
         && $cache{feature}{($feature->annotation->get_Annotations('Parent'))[0]->value}) {

        #check for an existing feature with the Target's uniquename
        if ( $uniquename_cache{$target_id} ) {
            print_floc(
                $nextfeatureloc,
                $nextfeature,
                $uniquename_cache{$target_id}{'feature_id'},
                $tstart, $tend, $tstrand, '\N',$rank,'0'
            );
        }
        else { 
            my $gffline = $feature->write_feature();
            die << "END_DIE"
I don't think this should happen; there is a Target with a Parent, but
no feature maps as the Target Parent for this feature:
$gffline
END_DIE
;
        }
      } else { #this Target needs a feature too

        #first, check for an existing feature with the Target's unqiuename
        if ( $uniquename_cache{$target_id} ) {
          print_floc(
              $nextfeatureloc,
              $nextfeature,
              $uniquename_cache{$target_id}{'feature_id'},
              $tstart, $tend, $tstrand, '\N',$rank,'0'
          );
        }
        else { #need to create a 'dummy' feature for the Target
          $nextfeature++;
          $name ||= "$featuretype-$uniquename";

          print_f($nextfeature, $organism, $name, $target_id.'_'.$nextfeature, $type, $ANALYSIS,'\N');
          print_floc(
                $nextfeatureloc,
                $nextfeature-1,
                $nextfeature,
                $tstart,
                $tend,
                $tstrand,
                '\N',
                $rank,
                '0'
                );
          $uniquename_cache{$target_id}{'feature_id'}   = $nextfeature;
          $uniquename_cache{$target_id}{'type_id'}      = $type;
          $uniquename_cache{$target_id}{'orgainism_id'} = $organism;
        }
      }

      my $score = $feature->score->value ? $feature->score->value : '\N';
      $score    = '.' eq $score          ? '\N'                   : $score;

      my $featuretype = $feature->type->name;

      my $type = $cache{type}{$featuretype};
 #     if(!$type){
 #       ($type) = Chado::Cvterm->search( name => $featuretype, cv_id => $sofa_id );
 #       $cache{type}{$featuretype} = $type;
 #     }
 #     die "no cvterm for ".$featuretype unless $type;

      my $ankey = $GLOBAL_ANALYSIS ?
                  $ANALYSIS_GROUP :
                  $tsource .'_'. $featuretype;

      unless($cache{analysis}{$ankey}) {
        $search_analysis->execute($ankey);
        my ($ana) = $search_analysis->fetchrow_array;
        dump_ana_contents($ankey) unless $ana;
        $cache{analysis}{$ankey} = $ana;
      }
      dump_ana_contents($ankey) unless $cache{analysis}{$ankey};

      dump_ana_contents($ankey) unless $cache{analysis}{$ankey};

      my $score_string;
      if      ($SCORE_COL =~ /^[Ss]/) {
        $score_string = "$score\t\\N\t\\N\t\\N";
      } elsif ($SCORE_COL =~ /^[Rr]/) {
        $score_string = "\\N\t$score\t\\N\t\\N";
      } elsif ($SCORE_COL =~ /^[Nn]/) {
        $score_string = "\\N\t\\N\t$score\t\\N";
      } elsif ($SCORE_COL =~ /^[Ii]/) {
        $score_string = "\\N\t\\N\t\\N\t$score";
      }

      print_af($nextanalysisfeature,$nextfeature,$cache{analysis}{$ankey},$score_string);
      $nextanalysisfeature++;
      $nextfeatureloc++;
      $rank++;
    }
}


sub copy_from_stdin {
  my $dbh      = shift;
  my $table    = shift;
  my $fields   = shift;
  my $file     = shift;
  my $sequence = shift;
  my $nextval  = shift;

  warn "Loading data into $table table ...\n";

  if ($INSERTS) {
    # note that if a password is required, the user will have to enter it
    system("psql -q -f $file -h $DBHOST -p $DBPORT -U $DBUSER -d $DBNAME ") 
      && die "FAILED: loading $file failed (error:$!); I can't go on\n";
  }
  else {

    my $query = "COPY $table $fields FROM STDIN;";
    #warn "\t".$query;
    $dbh->do($query) or die "Error when executing: $query: $!\n";

    open FILE, $file;
    while (<FILE>) {
      if ( ! ($dbh->pg_putline($_)) ) {
        #error, disconecting
        $dbh->pg_endcopy;
        $dbh->rollback;
        $dbh->disconnect;
        die "error while copying data's of file $file, line $.\n";
      } #putline returns 1 if succesful
    }
    $dbh->pg_endcopy or die "calling endcopy for $table failed: $!\n"; 
    close FILE;

  }

  #update the sequence so that later inserts will work 
  $dbh->do("SELECT setval('public.$sequence', $nextval) FROM $table"); 
}

sub synonyms  {
    my $alias = shift;
    my $feature_id = shift;
    unless ($cache{synonym}{$alias}) {
      unless ($cache{type}{'synonym'}) {
        my $sth 
          = $db->prepare("SELECT cvterm_id FROM cvterm WHERE name='synonym'");
        $sth->execute;
        ($cache{type}{'synonym'}) = $sth->fetchrow_array;
        warn "unable to find synonym type in cvterm table"
            and next unless $cache{type}{'synonym'};
      }

      #check for pre-existing synonyms with this name
      $search_synonym->execute($alias,$cache{type}{'synonym'});
      my ($synonym) = $search_synonym->fetchrow_array;

      if ($synonym) {
        unless ($pub) {
          my $sth = $db->prepare("SELECT pub_id FROM pub WHERE miniref = 'null'");
          $sth->execute;
          ($pub) = $sth->fetchrow_array;
        }


        if ( !$constraint{feature_synonym_c1}{ $feature_id }{ $synonym } ) {
          $constraint{feature_synonym_c1}{ $feature_id }{ $synonym }++;
          print_fs($nextfeaturesynonym,$synonym,$feature_id,$pub);

          $nextfeaturesynonym++;
          $cache{synonym}{$alias} = $synonym;
        }

      } else {
        print_syn($nextsynonym,$alias,$cache{type}{'synonym'},$alias);

        unless ($pub) {
            my $sth = $db->prepare("SELECT pub_id FROM pub WHERE miniref = 'null'");
            $sth->execute;
            my @row_array = $sth->fetchrow_array;
            $pub = $row_array[0];
        }

        if( !$constraint{feature_synonym_c1}{ $feature_id }{ $nextsynonym } ) { 
          $constraint{feature_synonym_c1}{ $feature_id }{ $nextsynonym }++;

          print_fs($nextfeaturesynonym,$nextsynonym,$feature_id,$pub);
          $nextfeaturesynonym++;
          $cache{synonym}{$alias} = $nextsynonym;
          $nextsynonym++;
        }
      }

    } else {
      if ( !$constraint{feature_synonym_c1}{ $feature_id }{ $cache{synonym}{$alias} } ) {
        $constraint{feature_synonym_c1}{ $feature_id }{ $cache{synonym}{$alias} }++;

        print_fs($nextfeaturesynonym,$cache{synonym}{$alias},$feature_id,$pub);
        $nextfeaturesynonym++;
      }
    }
}

sub dump_ana_contents {
  my $anakey = shift;
  print STDERR "\n\nCouldn't find $anakey in analysis table\n";
  print STDERR "The current contents of the analysis table is:\n\n";

  my $sth 
    = $db->prepare("SELECT analysis_id,name,program FROM analysis");
  printf STDERR "%10s %25s %10s\n\n", 
    ('analysis_id','name','program');

  $sth->execute;
  while (my $array_ref = $sth->fetchrow_arrayref) {
    printf STDERR "%10s %25s %10s\n", @$array_ref;
  }

  print STDERR "\nPlease see \`perldoc gmod_bulk_load_gff3.pl\` for more information\n\n";
  exit 1;
}

sub uniquename_validation {
  my ($uniquename, $type, $organism, $nextfeature) = @_;

  if (defined($uniquename_cache{$uniquename}{'type_id'})         and
      defined($uniquename_cache{$uniquename}{'organism_id'})     and
      $uniquename_cache{$uniquename}{'type_id'}     == $type     and
      $uniquename_cache{$uniquename}{'organism_id'} == $organism) {

      $uniquename = "$uniquename-$nextfeature";
      return uniquename_validation($uniquename, $type, $organism, $nextfeature);

  }
  else { #this uniquename is valid; cache it and return

      $uniquename_cache{$uniquename}{'type_id'}     = $type;
      $uniquename_cache{$uniquename}{'organism_id'} = $organism;
      $uniquename_cache{$uniquename}{'feature_id'}  = $nextfeature;

      return $uniquename;
  }

#  $validate_uniquename->execute($uniquename, $type, $organism);
#  my @count = $validate_uniquename->fetchrow_array;
#  return $uniquename if ($count[0] == 0);
#  $uniquename = "$uniquename-$nextfeature";
#  return uniquename_validation($uniquename, $type, $organism, $nextfeature);
}

sub drop_indexes {
  my $dbh = shift;

  $dbh->do("ALTER TABLE feature DROP CONSTRAINT feature_c1") or die "$!";
  $dbh->do("DROP INDEX feature_name_ind1") or die "$!";
  $dbh->do("DROP INDEX feature_idx1") or die "$!";
  $dbh->do("DROP INDEX feature_idx2") or die "$!";
  $dbh->do("DROP INDEX feature_idx3") or die "$!";
  $dbh->do("DROP INDEX feature_idx4") or die "$!";
  $dbh->do("DROP INDEX feature_idx5") or die "$!";

  $dbh->do("ALTER TABLE featureloc DROP CONSTRAINT featureloc_c1") or die "$!";
  $dbh->do("DROP INDEX featureloc_idx1") or die "$!";
  $dbh->do("DROP INDEX featureloc_idx2") or die "$!";
  $dbh->do("DROP INDEX featureloc_idx3") or die "$!";

  $dbh->do("ALTER TABLE feature_dbxref DROP CONSTRAINT feature_dbxref_c1") or die "$!";
  $dbh->do("DROP INDEX feature_dbxref_idx1") or die "$!";
  $dbh->do("DROP INDEX feature_dbxref_idx2") or die "$!";

  $dbh->do("ALTER TABLE feature_relationship DROP CONSTRAINT feature_relationship_c1") or die "$!";
  $dbh->do("DROP INDEX feature_relationship_idx1") or die "$!";
  $dbh->do("DROP INDEX feature_relationship_idx2") or die "$!";
  $dbh->do("DROP INDEX feature_relationship_idx3") or die "$!";

  $dbh->do("ALTER TABLE feature_cvterm DROP CONSTRAINT feature_cvterm_c1") or die "$!";
  $dbh->do("DROP INDEX feature_cvterm_idx1") or die "$!";
  $dbh->do("DROP INDEX feature_cvterm_idx2") or die "$!";
  $dbh->do("DROP INDEX feature_cvterm_idx3") or die "$!";

  $dbh->do("ALTER TABLE synonym DROP CONSTRAINT synonym_c1") or die "$!";
  $dbh->do("DROP INDEX synonym_idx1") or die "$!";
  $dbh->do("DROP INDEX synonym_idx2") or die "$!";

  $dbh->do("ALTER TABLE feature_synonym DROP CONSTRAINT feature_synonym_c1") or die "$!";
  $dbh->do("DROP INDEX feature_synonym_idx1") or die "$!";
  $dbh->do("DROP INDEX feature_synonym_idx2") or die "$!";
  $dbh->do("DROP INDEX feature_synonym_idx3") or die "$!";

  $dbh->do("ALTER TABLE analysisfeature DROP CONSTRAINT analysisfeature_c1") or die "$!";
  $dbh->do("DROP INDEX analysisfeature_idx1") or die "$!";
  $dbh->do("DROP INDEX analysisfeature_idx2") or die "$!";
}

sub create_indexes {
  my $dbh = shift;
  $dbh->do("ALTER TABLE feature ADD CONSTRAINT feature_c1 unique (organism_id,uniquename,type_id)");
  $dbh->do("CREATE INDEX feature_name_ind1  ON feature (name)");
  $dbh->do("CREATE INDEX feature_idx1  ON feature (dbxref_id)");
  $dbh->do("CREATE INDEX feature_idx2  ON feature (organism_id)");
  $dbh->do("CREATE INDEX feature_idx3  ON feature (type_id)");
  $dbh->do("CREATE INDEX feature_idx4  ON feature (uniquename)");
  $dbh->do("CREATE INDEX feature_idx5  ON feature (lower(name))");

  $dbh->do("ALTER TABLE featureloc ADD CONSTRAINT featureloc_c1 unique (feature_id,locgroup,rank)");
  $dbh->do("CREATE INDEX featureloc_idx1  ON featureloc (feature_id)");
  $dbh->do("CREATE INDEX featureloc_idx2  ON featureloc (srcfeature_id)");
  $dbh->do("CREATE INDEX featureloc_idx3  ON featureloc (srcfeature_id,fmin,fmax)");

  $dbh->do("ALTER TABLE feature_dbxref ADD CONSTRAINT feature_dbxref_c1 unique (feature_id,dbxref_id)");
  $dbh->do("CREATE INDEX feature_dbxref_idx1  ON feature_dbxref (feature_id)");
  $dbh->do("CREATE INDEX feature_dbxref_idx2  ON feature_dbxref (dbxref_id)");

  $dbh->do("ALTER TABLE feature_relationship ADD CONSTRAINT feature_relationship_c1 unique (subject_id,object_id,type_id,rank)");
  $dbh->do("CREATE INDEX feature_relationship_idx1  ON feature_relationship (subject_id)");
  $dbh->do("CREATE INDEX feature_relationship_idx2  ON feature_relationship (object_id)");
  $dbh->do("CREATE INDEX feature_relationship_idx3  ON feature_relationship (type_id)");

  $dbh->do("ALTER TABLE feature_cvterm ADD CONSTRAINT feature_cvterm_c1 unique (feature_id,cvterm_id,pub_id)");
  $dbh->do("CREATE INDEX feature_cvterm_idx1  ON feature_cvterm (feature_id)");
  $dbh->do("CREATE INDEX feature_cvterm_idx2  ON feature_cvterm (cvterm_id)");
  $dbh->do("CREATE INDEX feature_cvterm_idx3  ON feature_cvterm (pub_id)");

  $dbh->do("ALTER TABLE synonym ADD CONSTRAINT synonym_c1 unique (name,type_id)");
  $dbh->do("CREATE INDEX synonym_idx1  ON synonym (type_id)");
  $dbh->do("CREATE INDEX synonym_idx2  ON synonym ((lower(synonym_sgml)))");

  $dbh->do("ALTER TABLE feature_synonym ADD CONSTRAINT feature_synonym_c1 unique (synonym_id,feature_id,pub_id)");
  $dbh->do("CREATE INDEX feature_synonym_idx1  ON feature_synonym (synonym_id)");
  $dbh->do("CREATE INDEX feature_synonym_idx2  ON feature_synonym (feature_id)");
  $dbh->do("CREATE INDEX feature_synonym_idx3  ON feature_synonym (pub_id)");

  $dbh->do("ALTER TABLE analysisfeature ADD CONSTRAINT analysisfeature_c1 unique (feature_id,analysis_id)");
  $dbh->do("CREATE INDEX analysisfeature_idx1 ON analysisfeature (feature_id)");
  $dbh->do("CREATE INDEX analysisfeature_idx2 ON analysisfeature (analysis_id)");
}

sub print_frel {
  my ($nextfeaturerel,$nextfeature,$parent,$part_of) = @_;
  if ($INSERTS) {
    print FREL "INSERT INTO feature_relationship $copystring{'feature_relationship'} VALUES ($nextfeaturerel,$nextfeature,$parent,$part_of);\n";
  }
  else {
    print FREL join("\t", ($nextfeaturerel,$nextfeature,$parent,$part_of)),"\n";
  }
}

sub print_f {
  my ($nextfeature,$organism,$name,$uniquename,$type,$ANALYSIS,$seqlen) = @_;
  if ($INSERTS) {
    my $q_name        = $db->quote($name);
    my $q_uniquename  = $db->quote($uniquename);
    my $q_seqlen      = $seqlen eq '\N' ? 'NULL' : $seqlen;
    my $q_analysis    = $ANALYSIS ? "'true'" : "'false'";
    print F "INSERT INTO feature $copystring{'feature'} VALUES ($nextfeature,$organism,$q_name,$q_uniquename,$type,$q_analysis,$q_seqlen);\n";
  }
  else {
    print F join("\t", ($nextfeature, $organism, $name, $uniquename, $type, $ANALYSIS),$seqlen),"\n";
  }
}

sub print_floc {
  my ($featureloc_id,$feature_id,$src_id,$start,$end,$strand,$phase,$rank,$locgroup) = @_;

  if ($INSERTS) {
    my $q_strand= $strand eq '\N'? 'NULL' : $strand;
    my $q_phase = $phase eq '\N' ? 'NULL' : $phase;
    print FLOC "INSERT INTO featureloc $copystring{'featureloc'} VALUES ($featureloc_id,$feature_id,$src_id,$start,$end,$q_strand,$q_phase,$rank,$locgroup);\n";
  }
  else {
    print FLOC join("\t", ($featureloc_id, $feature_id, $src_id, $start, $end, $strand, $phase,$rank,$locgroup)),"\n";
  }
}

sub print_fprop {
  my ($fp_id,$f_id,$cvterm_id,$value,$rank) = @_;

  if ($INSERTS) {
    my $q_value = $db->quote($value);
    print FPROP "INSERT INTO featureprop $copystring{'featureprop'} VALUES ($fp_id,$f_id,$cvterm_id,$q_value,$rank);\n";
  }
  else {
    print FPROP join("\t",($fp_id,$f_id,$cvterm_id,$value,$rank)),"\n";
  }
}

sub print_fcv {
  my ($fcv_id,$f_id,$cvterm_id,$p_id) = @_;

  if ($INSERTS) {
    print FCV "INSERT INTO feature_cvterm $copystring{'feature_cvterm'} VALUES ($fcv_id,$f_id,$cvterm_id,$p_id);\n";
  }
  else {
    print FCV join("\t",($fcv_id,$f_id,$cvterm_id,$p_id)),"\n";
  }
}

sub print_syn {
  my ($s_id,$syn,$type_id) = @_;

  if ($INSERTS) {
    my $q_syn = $db->quote($syn);
    print SYN "INSERT INTO synonym $copystring{'synonym'} VALUES ($s_id,$q_syn,$type_id,$q_syn);\n";
  }
  else {
    print SYN join("\t", ($s_id,$syn,$type_id,$syn)),"\n";
  }
}

sub print_fs {
  my ($fs_id,$s_id,$f_id,$p_id) = @_;

  if ($INSERTS) {
    print FS "INSERT INTO feature_synonym $copystring{'feature_synonym'} VALUES ($fs_id,$s_id,$f_id,$p_id);\n";
  }
  else {
    print FS join("\t", ($fs_id,$s_id,$f_id,$p_id)),"\n";
  }
}

sub print_fdbx {
  my ($fd_id,$f_id,$dx_id) = @_;

  if ($INSERTS) {
    print FDBX "INSERT INTO feature_dbxref $copystring{'feature_dbxref'} VALUES ($fd_id,$f_id,$dx_id);\n";
  }
  else {
    print FDBX join("\t",($fd_id,$f_id,$dx_id)),"\n";
  }
}

sub print_dbx {
  my ($dbx_id,$db_id,$acc,$vers,$desc) = @_;

  if ($INSERTS) {
    my $q_acc  = $db->quote($acc);
    my $q_vers = $db->quote($vers);
    my $q_desc = $desc eq '\N' ? 'NULL' : $db->quote($desc);
    print DBX "INSERT INTO dbxref $copystring{'dbxref'} VALUES ($dbx_id,$db_id,$q_acc,$q_vers,$q_desc);\n";
  }
  else {
    print DBX join("\t",($dbx_id,$db_id,$acc,$vers,$desc)),"\n";
  }
}

sub print_af {
  my ($af_id,$f_id,$a_id,$score) = @_;

  if ($INSERTS) {
    $score       =~ s/\\N/NULL/g;
    my @scores   = split "\t", $score;
    my @q_scores = map { $db->quote($_) if $_ ne 'NULL'  } @scores;
    my $q_score  = join(',', @q_scores);
    print AF "INSERT INTO analysisfeature $copystring{'analysisfeature'} VALUES ($af_id,$f_id,$a_id,$q_score);\n";
  }
  else {
    print AF join("\t", ($af_id,$f_id,$a_id,$score)), "\n";
  }
}

sub dbxref_error_message {
  my $tag = shift;
  warn <<END
Your GFF3 file uses a tag called '$tag', but this term is not
already in the cvterm table so that it's value can be inserted
into the featureprop table.  The easiest way to rectify this is
to execute the following SQL commands in the psql shell:

  INSERT INTO dbxref (db_id,accession)
    VALUES ((select db_id from db where name='null'),'autocreated:$tag');
  INSERT INTO cvterm (cv_id,name,dbxref_id)
    VALUES ((select cv_id from cv where name='autocreated'), '$tag',
            (select dbxref_id from dbxref where accession='autocreated:$tag'));

and then rerun this loader.  Your other option is to
write a special handler for this tag so that it will
go where you want it in the database.

END
; 
}

!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
chdir $origdir;


