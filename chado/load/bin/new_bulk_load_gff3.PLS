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
use Bio::FeatureIO;
use Getopt::Long;
#use Data::Dumper;
use URI::Escape;
use lib '/Users/cain/cvs_stuff/schema/chado/lib';
use Bio::GMOD::DB::Adapter;

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
) or ( system( 'pod2text', $0 ), exit -1 );


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

die "You must supply an organism" unless $ORGANISM;

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


my %argv;
  $argv{organism}     = $ORGANISM;
  $argv{gfffile}      = $GFFFILE;
  $argv{dbprofile}    = $DBPROFILE;
  $argv{dbname}       = $DBNAME;
  $argv{dbuser}       = $DBUSER;
  $argv{dbpass}       = $DBPASS;
  $argv{dbhost}       = $DBHOST;
  $argv{dbport}       = $DBPORT;
  $argv{analysis}     = $ANALYSIS;
  $argv{noload}       = $NOLOAD;
  $argv{validate}     = $VALIDATE;
  $argv{notransact}   = $NOTRANSACT;
  $argv{nosequence}   = $NOSEQUENCE;
  $argv{score_col}    = $SCORE_COL;
  $argv{ontology}     = $ONTOLOGY;
  $argv{skip_vacuum}  = $SKIP_VACUUM;
  $argv{drop_indexes} = $DROP_INDEX;
  $argv{inserts}      = $INSERTS;
  $argv{global_analysis}=$GLOBAL_ANALYSIS;
  $argv{analysis_group}=$ANALYSIS_GROUP;

#allow a feature_id to be referenced by multiple featureloc.feature_id's
my %locgroup = ();

########################

my $chado = Bio::GMOD::DB::Adapter->new(%argv);

#if we need custom ontology mapping, cache them here
if ($ONTOLOGY) {
  my @pairs = split /\,/, $ONTOLOGY;
  foreach (@pairs) {
    my ($tag, $value) = split/\=/;
    $chado->cache('ontology',$tag, $value);
  }
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



########################

#######################################################
#prepare a bunch of sql queries to be used in the loop:
#

$chado->organism_id($ORGANISM) or die "$ORGANISM organism not found in the database";

$chado->file_handles();

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
$chado->uniquename_cache();
warn "done\n";

warn "Preparing data for inserting into the $DBNAME database\n";
warn "(This may take a while ...)\n";

while(my $feature = $gffio->next_feature()){

  my $nextfeature    = $chado->nextfeature();
  my $nextfeatureloc = $chado->nextfeatureloc();

  my $featuretype = $feature->type->name;

  my $type           = $chado->get_type($featuretype);
  my ($src, $seqlen) = $chado->get_src_seqlen($feature);

  if(!$src){
    $src = $chado->src_second_chance($feature);
  }
  die "no feature for ".$feature->seq_id->value unless $src;

  if($feature->annotation->get_Annotations('Parent')){
    $chado->handle_parent($feature);
  }

  if($feature->annotation->get_Annotations('Derives_from')){
    $chado->handle_derives_from($feature);
  }

  my $source      = $feature->source->value;

  my($uniquename) = ($feature->annotation->get_Annotations('ID'))[0]
                   || "auto".$nextfeature;
  $uniquename     = $uniquename->value if ref($uniquename);

  $uniquename     = $chado->uniquename_validation( $uniquename,
                                       $type,
                                       $chado->organism_id,
                                       $nextfeature);

  my($name)       = ($feature->annotation->get_Annotations('Name'))[0]
                   ||($feature->annotation->get_Annotations('ID'))[0]
                   || "$featuretype-$uniquename";
  $name           = $name->value if ref($name);

  #my $uniquename = $nextfeature;
  unless ($chado->cache('parent',$uniquename) ) {
      $chado->cache('parent',$uniquename,$nextfeature);
  }
  if($chado->cache('feature',$uniquename)){
    #seen this feature before
    $locgroup{$uniquename}++;
  }
  else {
    $chado->print_f($nextfeature,$chado->organism_id,$name,$uniquename,$type,$ANALYSIS,$seqlen);

    $chado->cache('feature',$uniquename,$nextfeature);
    $chado->cache('parent',$uniquename,$nextfeature);
    $locgroup{$uniquename}       = 0;
  }

  #FIXME potential $chado->nextfeature bug
  if ($ANALYSIS 
      && $featuretype =~ /match/  
      && !$feature->annotation->get_Annotations('Target')) {
    $chado->cache('feature',($feature->annotation->get_Annotations('ID'))[0]->value,$nextfeature);
  }


#don't write a featureloc entry for srcfeatures
  unless ($src eq '\N' or $src == $nextfeature) {
#need to convert from base to interbase coords
    my $start = $feature->start eq '.' ? '\N' : ($feature->start - 1);
    my $end   = $feature->end   eq '.' ? '\N' : defined($feature->end) ? $feature->end : '\N';
    my $phase = ($feature->phase->value eq '.' or $feature->phase->value eq '') ? '\N' : $feature->phase->value;

    $chado->print_floc($nextfeatureloc, $chado->cache('feature',$uniquename), $src, $start, $end, $feature->strand, $phase,'0',$locgroup{$uniquename});
  }

  if ($feature->annotation->get_Annotations('Gap')) {
    $chado->handle_gap($feature,$uniquename);
  }


  if ($feature->annotation->get_Annotations('Note')) {
    $chado->handle_note($feature,$uniquename);
  }

#try to put unreserved tags in featureprop
#this requires that the terms exist in cvterm (and therefore that they
#have a dbxref)
  my @unreserved_tags = grep {/^[a-z]/} $feature->annotation->get_all_annotation_keys();
  if ( @unreserved_tags > 0 ) {
    $chado->handle_unreserved_tags($feature,$uniquename,@unreserved_tags);
  }

  if ( $chado->{const}{source_success} && $source && $source ne '.') {
    $chado->handle_source($feature,$uniquename,$source);
  }

  if ($feature->annotation->get_Annotations('Ontology_term')) {
    $chado->handle_ontology_term($feature,$uniquename);
  }

  if ($feature->annotation->get_Annotations('Dbxref')) {
    $chado->handle_dbxref($feature,$uniquename);
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
    $chado->synonyms($alias,$chado->cache('feature',$uniquename));
  }

  if ($ANALYSIS && !$feature->annotation->get_Annotations('Target')) {
    $chado->handle_nontarget_analysis($feature,$uniquename);
  }

  $chado->nextfeatureloc('++');
  #now deal with creating another feature for targets

  if (!$ANALYSIS && $feature->annotation->get_Annotations('Target')) {
    die "Features in this GFF file have Target tags, but you did not indicate\n"
    ."--analysis on the command line";
  }
  elsif ($feature->annotation->get_Annotations('Target')) {
      $chado->handle_target($feature, $uniquename,$name,$featuretype,$type);
  }
  $chado->nextfeature('++');
}

$chado->end_files();

#$search_uniquename->finish;
#$validate_uniquename->finish;

#deal with sequence 
unless ($NOSEQUENCE) {
  while (my $seq = $gffio->next_seq) {
    my $string = $seq->seq();
    my $name   = $seq->display_id();
    $chado->print_seq($name,$string);
  }
}

$chado->load_data() unless $NOLOAD;

exit(0);

!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
chdir $origdir;


