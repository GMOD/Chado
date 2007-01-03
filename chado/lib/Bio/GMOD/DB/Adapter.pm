package Bio::GMOD::DB::Adapter;

use strict;
use Carp;
use DBI;
use File::Temp;
use Data::Dumper;
use URI::Escape;
use Bio::SeqFeature::Generic;
use Bio::GMOD::DB::Adapter::FeatureIterator;
use FreezeThaw qw( freeze thaw safeFreeze );

#set lots of package-wide variables:
my ($nextfeaturerel,$nextfeatureprop,
    $nextfeaturecvterm,$nextsynonym,$nextfeaturesynonym,
    $nextfeaturedbxref,$nextdbxref,$nextanalysisfeature,
    $part_of,$derives_from,$sofa_id);

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
   feature              => "(feature_id,organism_id,name,uniquename,type_id,is_analysis,seqlen,dbxref_id)",
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

my %files = (
   feature              => 'F', 
   featureloc           => 'FLOC',
   feature_relationship => 'FREL',
   featureprop          => 'FPROP',
   feature_cvterm       => 'FCV',
   synonym              => 'SYN',
   feature_synonym      => 'FS',
   dbxref               => 'DBX',
   feature_dbxref       => 'FDBX',
   analysisfeature      => 'AF',
   sequence             => 'SEQ',
);

# @tables array sets the order for which things will be inserted into
# the database
my @tables = (
   "feature",
   "featureloc",
   "feature_relationship",
   "featureprop",
   "feature_cvterm",
   "synonym",
   "feature_synonym",
   "dbxref",
   "feature_dbxref",
   "analysisfeature",
);


use constant SEARCH_NAME =>
               "SELECT feature_id FROM feature WHERE name=?";
use constant COUNT_NAME =>
               "SELECT COUNT(*) FROM feature WHERE name=?";
use constant SEARCH_CVTERM_ID =>
               "SELECT cvterm_id FROM cvterm WHERE name=? AND cv_id=?";
use constant SEARCH_SOURCE_DBXREF =>
               "SELECT dbxref_id FROM dbxref WHERE accession=? AND db_id=?";
use constant SEARCH_DBXREF => 
               "SELECT dbxref_id FROM dbxref WHERE accession=? AND db_id in 
                    (SELECT db_id FROM db WHERE name like ? OR name like ?)";
use constant SEARCH_CVTERM_ID_W_DBXREF =>
               "SELECT cvterm_id FROM cvterm WHERE dbxref_id=?";
use constant SEARCH_DB =>
               "SELECT db_id FROM db WHERE name =?";
use constant SEARCH_LONG_DBXREF => 
               "SELECT dbxref_id FROM dbxref WHERE accession =?
                                                  AND version =?
                                                  AND db_id =?";
use constant SEARCH_ANALYSIS =>
               "SELECT analysis_id FROM analysis WHERE name=?";
use constant SEARCH_SYNONYM =>
               "SELECT synonym_id FROM synonym WHERE name=? AND type_id=?";

use constant CREATE_CACHE_TABLE =>
               "CREATE TABLE tmp_gff_load_cache (
                    feature_id int,
                    uniquename varchar(1000),
                    type_id int,
                    organism_id int
                )";
use constant DROP_CACHE_TABLE =>
               "DROP TABLE tmp_gff_load_cache";
use constant VERIFY_TMP_TABLE =>
               "SELECT count(*) FROM pg_class WHERE relname=? and relkind='r'";
use constant POPULATE_CACHE_TABLE =>
               "INSERT INTO tmp_gff_load_cache
                SELECT feature_id,uniquename,type_id,organism_id FROM feature";
use constant CREATE_CACHE_TABLE_INDEX1 =>
               "CREATE INDEX tmp_gff_load_cache_idx1 
                    ON tmp_gff_load_cache (feature_id)";
use constant CREATE_CACHE_TABLE_INDEX2 =>
               "CREATE INDEX tmp_gff_load_cache_idx2 
                    ON tmp_gff_load_cache (uniquename)";
use constant CREATE_CACHE_TABLE_INDEX3 =>
               "CREATE INDEX tmp_gff_load_cache_idx3
                    ON tmp_gff_load_cache (uniquename,type_id,organism_id)";
use constant VALIDATE_TYPE_ID =>
               "SELECT feature_id FROM tmp_gff_load_cache
                    WHERE type_id = ? AND
                          organism_id = ? AND
                          uniquename = ?";
use constant VALIDATE_UNIQUENAME =>
               "SELECT feature_id FROM tmp_gff_load_cache WHERE uniquename=?";
use constant INSERT_CACHE_TYPE_ID =>
               "INSERT INTO tmp_gff_load_cache 
                  (feature_id,uniquename,type_id,organism_id) VALUES (?,?,?,?)";
use constant INSERT_CACHE_UNIQUENAME =>
               "INSERT INTO tmp_gff_load_cache (feature_id,uniquename)
                  VALUES (?,?)";

use constant INSERT_GFF_SORT_TMP =>
               "INSERT INTO gff_sort_tmp (refseq,id,parent,gffline)
                  VALUES (?,?,?,?)";


my $ALLOWED_UNIQUENAME_CACHE_KEYS =
               "feature_id|type_id|organism_id|uniquename|validate";
my $ALLOWED_CACHE_KEYS =
               "analysis|db|dbxref|feature|parent|source|synonym|type|ontology|const";


sub new {
    my $class = shift;
    my %arg   = @_;

    my $self  = bless {}, ref($class) || $class;


    my $dbname = $arg{dbname};
    my $dbport = $arg{dbport};
    my $dbhost = $arg{dbhost};
    my $dbuser = $arg{dbuser};
    my $dbpass = $arg{dbpass};
    my $notrans= $arg{notransact};
    my $skipinit=$arg{skipinit};

    my $dbh = DBI->connect(
        "dbi:Pg:dbname=$dbname;port=$dbport;host=$dbhost",
        $dbuser,
        $dbpass,
        {AutoCommit => $notrans,
         TraceLevel => 0}
    ) or die;

    $self->dbh($dbh);

    $self->dbname(          $arg{dbname}          );
    $self->dbport(          $arg{dbport}          ); 
    $self->dbhost(          $arg{dbhost}          );
    $self->dbuser(          $arg{dbuser}          );
    $self->dbpass(          $arg{dbpass}          );
    $self->notransact(      $arg{notransact}      );
    $self->nosequence(      $arg{nosequence}      );
    $self->inserts(         $arg{inserts}         );
    $self->score_col(       $arg{score_col}       );
    $self->global_analysis( $arg{global_analysis} );
    $self->analysis_group(  $arg{analysis_group}  );
    $self->analysis(        $arg{analysis}        );
    $self->organism(        $arg{organism}        );
    $self->dbprofile(       $arg{dbprofile}       );
    $self->noload(          $arg{noload}          );
    $self->skip_vacuum(     $arg{skip_vacuum}     );
    $self->drop_indexes_flag($arg{drop_indexes_flag});
    $self->noexon(          $arg{noexon}          );
    $self->nouniquecache(   $arg{nouniquecache}   );
    $self->recreate_cache(  $arg{recreate_cache}  );
    $self->save_tmpfiles(   $arg{save_tmpfiles}   );
    $self->no_target_syn(   $arg{no_target_syn}  );
    $self->unique_target(   $arg{unique_target}  );
    $self->dbxref(          $arg{dbxref}         );
    $self->fp_cv(           $arg{fp_cv}          );

    $self->{const}{source_success} = 1; #flag to indicate GFF_source is in db table

    $self->prepare_queries();
    unless ($skipinit) {
        $self->initialize_ontology();
        $self->initialize_sequences();
        $self->initialize_uniquename_cache();
    }

    $self->cds_db_exists(0);

    return $self;
}

=head2 prepare_queries

=over

=item Usage

  $obj->prepare_queries()

=item Function

Does dbi prepare on several cached queries

=item Returns

void

=item Arguments

none

=back

=cut

sub prepare_queries {
    my $self = shift;
    my $dbh  = $self->dbh();
    
  $self->{'queries'}{'search_name'}              
                                  = $dbh->prepare(SEARCH_NAME);
  $self->{'queries'}{'count_name'}               
                                  = $dbh->prepare(COUNT_NAME);
  $self->{'queries'}{'search_cvterm_id'}         
                                  = $dbh->prepare(SEARCH_CVTERM_ID);
  $self->{'queries'}{'search_source_dbxref'}     
                                  = $dbh->prepare(SEARCH_SOURCE_DBXREF);
  $self->{'queries'}{'search_dbxref'}
                                  = $dbh->prepare(SEARCH_DBXREF);
  $self->{'queries'}{'search_cvterm_id_w_dbxref'}
                                  = $dbh->prepare(SEARCH_CVTERM_ID_W_DBXREF);
  $self->{'queries'}{'search_db'}
                                  = $dbh->prepare(SEARCH_DB);
  $self->{'queries'}{'search_long_dbxref'}
                                  = $dbh->prepare(SEARCH_LONG_DBXREF);
  $self->{'queries'}{'search_analysis'}
                                  = $dbh->prepare(SEARCH_ANALYSIS);
  $self->{'queries'}{'search_synonym'}
                                  = $dbh->prepare(SEARCH_SYNONYM);
  $self->{'queries'}{'validate_type_id'}
                                  = $dbh->prepare(VALIDATE_TYPE_ID);
  $self->{'queries'}{'validate_uniquename'}
                                  = $dbh->prepare(VALIDATE_UNIQUENAME);
  $self->{'queries'}{'insert_cache_type_id'}
                                  = $dbh->prepare(INSERT_CACHE_TYPE_ID);
  $self->{'queries'}{'insert_cache_uniquename'}
                                  = $dbh->prepare(INSERT_CACHE_UNIQUENAME);

  $self->{'queries'}{'insert_gff_sort_tmp'}
                                  = $dbh->prepare(INSERT_GFF_SORT_TMP);
  return;
}

=head2 constraint

=over

=item Usage

  $obj->constraint()

=item Function

Manages database constraints

=item Returns

Updates cache and returns true if the constraint has not be violoated,
otherwise returns false.

=item Arguments

A hash with keys:

  name		constraint name
  terms		a anonymous array with column values

The array contains the column values in the 'right' order:

  feature_synonym_c1:  [feature_id, synonym_id]
  feature_dbxref_c1:   [feature_id, dbxref_id]
  feature_cvterm_c1:   [feature_id, cvterm_id]
  featureprop_c1:      [feature_id, cvterm_id, rank]

=back

=cut

sub constraint {
    my ($self, %argv) = @_;

    my $constraint = $argv{name};
    my @terms      = @{ $argv{terms} };

    if ($constraint eq 'feature_synonym_c1' ||
        $constraint eq 'feature_dbxref_c1'  ||
        $constraint eq 'feature_cvterm_c1') {
        die "wrong number of constraint terms" if (@terms != 2);
        if ($self->{$constraint}{$terms[0]}{$terms[1]}) {
            return 0; #this combo is already in the constraint
        }
        else {
            $self->{$constraint}{$terms[0]}{$terms[1]}++;
            return 1;
        }
    }
    elsif ($constraint eq 'featureprop_c1') {
        die "wrong number of constraint terms" if (@terms != 3);
        if ($self->{$constraint}{$terms[0]}{$terms[1]}{$terms[2]}) {
            return 0; #this combo is already in the constraint
        }
        else {
            $self->{$constraint}{$terms[0]}{$terms[1]}{$terms[2]}++;
            return 1;
        }
    }
    else {
        die "I don't know how to deal with the constraint $constraint: typo?";
    }
}


=head2 cache

=over

=item Usage

  $obj->cache()

=item Function

Handles generic data cache hash of hashes from bulk_load_gff3

=item Returns

The cached value

=item Arguments

The name of one of several top level cache keys:

             analysis
             db              #db.db_id cache
             dbxref
             feature
             parent          #featureloc.srcfeature_id ; parent feature
             source          #dbxref.dbxref_id ; gff_source
             synonym
             type            #cvterm.cvterm_id cache
             ontology

and a tag and optional value that gets stored in the cache.
If no value is passed, it is returned, otherwise void is returned.


=back

=cut

sub cache {
    my ($self, $top_level, $key, $value) = @_;

    if ($top_level !~ /($ALLOWED_CACHE_KEYS)/) {
        confess "I don't know what to do with the key '$top_level'".
            " in the cache method; it's probably because of a typo";
    }

    return $self->{cache}{$top_level}{$key} unless $value;

    return $self->{cache}{$top_level}{$key} = $value; 
}

=head2 nextfeature

=over

=item Usage

  $obj->nextfeature()        #get existing value
  $obj->nextfeature($newval) #set new value

=item Function

=item Returns

value of nextfeature (a scalar)

=item Arguments

new value of nextfeature (to set)

=back

=cut

sub nextfeature {
    my $self = shift;

    my $arg = shift if defined(@_);
    if (defined($arg) && $arg eq '++') {
        return $self->{'nextfeature'}++;
    }
    elsif (defined($arg)) {
        return $self->{'nextfeature'} = $arg;
    }
    return $self->{'nextfeature'};
}

=head2 nextfeatureloc

=over

=item Usage

  $obj->nextfeatureloc()        #get existing value
  $obj->nextfeatureloc($newval) #set new value

=item Function

=item Returns

value of nextfeatureloc (a scalar)

=item Arguments

new value of nextfeatureloc (to set)

=back

=cut

sub nextfeatureloc {
    my $self = shift;

    my $arg = shift if defined(@_);
    if (defined($arg) && $arg eq '++') {
        return $self->{nextfeatureloc}++;
    }
    elsif (defined($arg)) {
        return $self->{nextfeatureloc} = $arg;
    }
    return $self->{nextfeatureloc};
}

=head2 nextfeaturerel

=over

=item Usage

  $obj->nextfeaturerel()        #get existing value
  $obj->nextfeaturerel($newval) #set new value

=item Function

=item Returns

value of nextfeaturerel (a scalar)

=item Arguments

new value of nextfeaturerel (to set)

=back

=cut

sub nextfeaturerel {
    my $self = shift;
    return $nextfeaturerel = shift if defined(@_);
    return $nextfeaturerel;
}

=head2 nextfeatureprop

=over

=item Usage

  $obj->nextfeatureprop()        #get existing value
  $obj->nextfeatureprop($newval) #set new value

=item Function

=item Returns

value of nextfeatureprop (a scalar)

=item Arguments

new value of nextfeatureprop (to set)

=back

=cut

sub nextfeatureprop {
    my $self = shift;
    return $nextfeatureprop = shift if defined(@_);
    return $nextfeatureprop;
}

=head2 nextfeaturecvterm

=over

=item Usage

  $obj->nextfeaturecvterm()        #get existing value
  $obj->nextfeaturecvterm($newval) #set new value

=item Function

=item Returns

value of nextfeaturecvterm (a scalar)

=item Arguments

new value of nextfeaturecvterm (to set)

=back

=cut

sub nextfeaturecvterm {
    my $self = shift;
    return $nextfeaturecvterm = shift if defined(@_);
    return $nextfeaturecvterm;
}

=head2 nextsynonym

=over

=item Usage

  $obj->nextsynonym()        #get existing value
  $obj->nextsynonym($newval) #set new value

=item Function

=item Returns

value of nextsynonym (a scalar)

=item Arguments

new value of nextsynonym (to set)

=back

=cut

sub nextsynonym {
    my $self = shift;
    return $nextsynonym = shift if defined(@_);
    return $nextsynonym;
}

=head2 nextfeaturesynonym

=over

=item Usage

  $obj->nextfeaturesynonym()        #get existing value
  $obj->nextfeaturesynonym($newval) #set new value

=item Function

=item Returns

value of nextfeaturesynonym (a scalar)

=item Arguments

new value of nextfeaturesynonym (to set)

=back

=cut

sub nextfeaturesynonym {
    my $self = shift;
    return $nextfeaturesynonym = shift if defined(@_);
    return $nextfeaturesynonym;
}

=head2 nextfeaturedbxref

=over

=item Usage

  $obj->nextfeaturedbxref()        #get existing value
  $obj->nextfeaturedbxref($newval) #set new value

=item Function

=item Returns

value of nextfeaturedbxref (a scalar)

=item Arguments

new value of nextfeaturedbxref (to set)

=back

=cut

sub nextfeaturedbxref {
    my $self = shift;
    return $nextfeaturedbxref = shift if defined(@_);
    return $nextfeaturedbxref;
}

=head2 nextdbxref

=over

=item Usage

  $obj->nextdbxref()        #get existing value
  $obj->nextdbxref($newval) #set new value

=item Function

=item Returns

value of nextdbxref (a scalar)

=item Arguments

new value of nextdbxref (to set)

=back

=cut

sub nextdbxref {
    my $self = shift;
    return $nextdbxref = shift if defined(@_);
    return $nextdbxref;
}

=head2 nextanalysisfeature

=over

=item Usage

  $obj->nextanalysisfeature()        #get existing value
  $obj->nextanalysisfeature($newval) #set new value

=item Function

=item Returns

value of nextanalysisfeature (a scalar)

=item Arguments

new value of nextanalysisfeature (to set)

=back

=cut

sub nextanalysisfeature {
    my $self = shift;
    return $nextanalysisfeature = shift if defined(@_);
    return $nextanalysisfeature;
}



=head2 file_handles

=over

=item Usage

  $obj->file_handles()

=item Function

Creates and keeps track of file handles for temp files

=item Returns

On create, void.  With an arguement, returns the requested file handle

=item Arguments

If the 'short hand' name of a file handle is given, returns the requested
file handle.  The short hand file names are:

  F       feature
  FLOC    featureloc
  FREL    feature_relationship
  FPROP   featureprop
  FCV     feature_cvterm
  SYN     synonym
  FS      feature_synonym
  FDBX    feature_dbxref
  DBX     dbxref
  AF      analysisfeature
  SEQ     sequence

=back

=cut


sub file_handles {
    my ($self, $argv) = @_;

    if ($argv && $argv ne 'close') {
        return $self->{file_handles}{$argv};
    }
    else {
        for my $key (keys %files) {
            $self->{file_handles}{$files{$key}} 
                = new File::Temp(
                                 TEMPLATE => $key.'XXXX',
                                 UNLINK   => $self->save_tmpfiles() ? 0 : 1,  
                                );
        }
        return;
    }
}

=head2 end_files

=over

=item Usage

  $obj->end_files()

=item Function

Appends proper bulk load terminators

=item Returns

void

=item Arguments

none

=back

=cut

sub end_files {
    my $self = shift;

    unless ($self->inserts) {
        foreach my $file (@tables) {
            my $fh = $self->file_handles($files{$file});
            print $fh "\\.\n\n";
        }
    }
}


=head2 uniquename_cache

=over

=item Usage

  $obj->uniquename_cache()

=item Function

Maintains a cache of feature.uniquenames present in the database

=item Returns

See Arguements.

=item Arguments

uniquename_cache takes a hash.  
If it has a key 'validate', it returns the feature_id
of the feature corresponding to that uniquename if present, 0 if it is not.
Otherwise, it uses the values in the hash to update the uniquename_cache

Allowed hash keys:

  feature_id
  type_id
  organism_id
  uniquename
  validate

=back

=cut

sub uniquename_cache {
    my ($self, %argv) = @_;

    my @bogus_keys = grep {!/($ALLOWED_UNIQUENAME_CACHE_KEYS)/} keys %argv;

    if (@bogus_keys) {
        for (@bogus_keys) {
            warn "I don't know what to do with the key ".$_.
           " in the uniquename_cache method; it's probably because of a typo\n";
        }
        confess;
    }

    if ($argv{validate}) {
        if (defined $argv{type_id}){  #valididate type & org too
            $self->{'queries'}{'validate_type_id'}->execute(
                $argv{type_id},
                $argv{organism_id},
                $argv{uniquename},         
            );

            my ($feature_id) 
                 = $self->{'queries'}{'validate_type_id'}->fetchrow_array; 

            return $feature_id;
        }
        else { #just validate the uniquename

            $self->{'queries'}{'validate_uniquename'}->execute($argv{uniquename});

            my ($feature_id) 
                = $self->{'queries'}{'validate_uniquename'}->fetchrow_array;

            return $feature_id;
        }
    }
    elsif ($argv{type_id}) { 

        $self->{'queries'}{'insert_cache_type_id'}->execute(
            $argv{feature_id},
            $argv{uniquename},
            $argv{type_id},
            $argv{organism_id}        
        );
        $self->dbh->commit;
        return;
    }
}

=head2 fp_cv

=over

=item Usage

  $obj->fp_cv()        #get existing value
  $obj->fp_cv($newval) #set new value

=item Function

Gets/sets the name of the feature property cv

=item Returns

value of fp_cv (a scalar)

=item Arguments

new value of fp_cv (to set)

=back

=cut

sub fp_cv {
    my $self = shift;
    my $fp_cv = shift if defined(@_);
    return $self->{'fp_cv'} = $fp_cv if defined($fp_cv);
    return $self->{'fp_cv'};
}


=head2 recreate_cache

=over

=item Usage

  $obj->recreate_cache()        #get existing value
  $obj->recreate_cache($newval) #set new value

=item Function

=item Returns

value of recreate_cache (a scalar)

=item Arguments

new value of recreate_cache (to set)

=back

=cut

sub recreate_cache {
    my $self = shift;
    my $recreate_cache = shift if defined(@_);

    return $self->{'recreate_cache'} = $recreate_cache if defined($recreate_cache);
    return $self->{'recreate_cache'};
}

=head2 organism_id

=over

=item Usage

  $obj->organism_id()        #get existing value
  $obj->organism_id($newval) #set new value

=item Function

With a organism common name as an arg, sets the organism_id value

=item Returns

value of organism_id (a scalar)

=item Arguments

With a organism common name as an arg, sets the organism_id value

=back

=cut

sub organism_id {
    my $self = shift;
    my $organism_name = shift;

    return $self->{'organism_id'} unless $organism_name;

    my $sth = $self->dbh->prepare(
           "SELECT organism_id FROM organism WHERE common_name = ?");
    $sth->execute($organism_name);
    ($self->{'organism_id'}) = $sth->fetchrow_array; 

    return $self->{'organism_id'};
}

=head2 initialize_uniquename_cache

=over

=item Usage

  $obj->initialize_uniquename_cache()

=item Function

Creates the uniquename cache tables in the database

=item Returns

void

=item Arguments

none

=back

=cut

sub initialize_uniquename_cache {
    my $self = shift;

    #determine if the table already exists
    my $dbh = $self->dbh;
    my $sth = $dbh->prepare(VERIFY_TMP_TABLE);
    $sth->execute('tmp_gff_load_cache');

    my ($table_exists) = $sth->fetchrow_array;

    if (!$table_exists || $self->recreate_cache() ) {
        print STDERR "(Re)creating the uniquename cache in the database... ";
        $dbh->do(DROP_CACHE_TABLE) if ($self->recreate_cache() and $table_exists);

        print STDERR "\nCreating table...\n";
        $dbh->do(CREATE_CACHE_TABLE);

        print STDERR "Populating table...\n";
        $dbh->do(POPULATE_CACHE_TABLE);

        print STDERR "Creating indexes...";
        $dbh->do(CREATE_CACHE_TABLE_INDEX1);
        $dbh->do(CREATE_CACHE_TABLE_INDEX2);
        $dbh->do(CREATE_CACHE_TABLE_INDEX3);

        $dbh->commit;
        print STDERR "Done.\n";
    }
    return;
}


=head2 initialize_ontology

=over

=item Usage

  $obj->initialize_ontology()

=item Function

Initializes part_of, derives_from and SO cv_id

=item Returns

void

=item Arguments

none

=back

=cut

sub initialize_ontology {
    my $self = shift;

    my $sth = $self->dbh->prepare(
       "select cvterm_id from cvterm where name = 'part_of' and cv_id in (
         SELECT cv_id FROM cv WHERE name='relationship'
        )");
    $sth->execute;
    ($part_of) = $sth->fetchrow_array();

    $sth = $self->dbh->prepare(
      "select cvterm_id from cvterm where name = 'derives_from' and cv_id in (
         SELECT cv_id FROM cv WHERE name='relationship' 
       )");
    $sth->execute;
    ($derives_from) = $sth->fetchrow_array();

    $sth = $self->dbh->prepare("select cv_id from cv where name = 'sequence'");
    $sth->execute;
    ($sofa_id) =  $sth->fetchrow_array();

#backup plan for old chado instances
    if(!defined($sofa_id)){
        $sth = $self->dbh->prepare(
         "select cv_id from cv where name =
             'Sequence Ontology Feature Annotation' or name='sofa.ontology'");
        $sth->execute;
        ($sofa_id) =  $sth->fetchrow_array();
    }

#backup plan for really old chado instances
    if(!defined($sofa_id)){
        $sth = $self->dbh->prepare(
            "select cv_id from cv where name = 'Sequence Ontology'");
        $sth->execute;
        ($sofa_id) =  $sth->fetchrow_array();
    }

    return;
}


=head2 initialize_sequences

=over

=item Usage

  $obj->initialize_sequences()

=item Function

Initializes sequence counter variables

=item Returns

void

=item Arguments

none

=back

=cut

sub initialize_sequences {
    my $self = shift;

    my $sth = $self->dbh->prepare("select nextval('$sequences{feature}')");
    $sth->execute;
    my ($nextfeature) = $sth->fetchrow_array();
    $self->nextfeature($nextfeature);

    $sth = $self->dbh->prepare("select nextval('$sequences{featureloc}')");
    $sth->execute;
    my ($nextfeatureloc) = $sth->fetchrow_array();
    $self->nextfeatureloc($nextfeatureloc);

    $sth = $self->dbh->prepare("select nextval('$sequences{feature_relationship}')");
    $sth->execute;
    ($nextfeaturerel) = $sth->fetchrow_array();

    $sth = $self->dbh->prepare("select nextval('$sequences{featureprop}')");
    $sth->execute;
    ($nextfeatureprop) = $sth->fetchrow_array();

    $sth = $self->dbh->prepare("select nextval('$sequences{feature_cvterm}')");
    $sth->execute;
    ($nextfeaturecvterm) = $sth->fetchrow_array();

    $sth = $self->dbh->prepare("select nextval('$sequences{synonym}')");
    $sth->execute;
    ($nextsynonym) = $sth->fetchrow_array();

    $sth = $self->dbh->prepare("select nextval('$sequences{feature_synonym}')");
    $sth->execute;
    ($nextfeaturesynonym) = $sth->fetchrow_array();

    $sth = $self->dbh->prepare("select nextval('$sequences{feature_dbxref}')");
    $sth->execute;
    ($nextfeaturedbxref) = $sth->fetchrow_array();

    $sth = $self->dbh->prepare("select nextval('$sequences{dbxref}')");
    $sth->execute;
    ($nextdbxref) = $sth->fetchrow_array();

    $sth = $self->dbh->prepare("select nextval('$sequences{analysisfeature}')");
    $sth->execute;
    ($nextanalysisfeature) = $sth->fetchrow_array();

    return;
}


=head2 dbh

=over

=item Usage

  $obj->dbh()        #get existing value
  $obj->dbh($newval) #set new value

=item Function

=item Returns

value of dbh (a scalar)

=item Arguments

new value of dbh (to set)

=back

=cut

sub dbh {
    my $self = shift;

    my $dbh = shift if defined(@_);
    return $self->{'dbh'} = $dbh if defined($dbh);
    return $self->{'dbh'};
}


=head2 nouniquecache

=over

=item Usage

  $obj->nouniquecache()        #get existing value
  $obj->nouniquecache($newval) #set new value

=item Function

=item Returns

value of nouniquecache (a scalar)

=item Arguments

new value of nouniquecache (to set)

=back

=cut

sub nouniquecache {
    my $self = shift;

    my $nouniquecache = shift if defined(@_);
    return $self->{'nouniquecache'} = $nouniquecache if defined($nouniquecache);
    return $self->{'nouniquecache'};
}


=head2 noexon

=over

=item Usage

  $obj->noexon()        #get existing value
  $obj->noexon($newval) #set new value

=item Function

=item Returns

value of noexon (a scalar)

=item Arguments

new value of noexon (to set)

=back

=cut

sub noexon {
    my $self = shift;

    my $noexon = shift if defined(@_);
    return $self->{'noexon'} = $noexon if defined($noexon);
    return $self->{'noexon'};
}


=head2 dbname

=over

=item Usage

  $obj->dbname()        #get existing value
  $obj->dbname($newval) #set new value

=item Function

=item Returns

value of dbname (a scalar)

=item Arguments

new value of dbname (to set)

=back

=cut

sub dbname {
    my $self = shift;

    my $dbname = shift if defined(@_);
    return $self->{'dbname'} = $dbname if defined($dbname);
    return $self->{'dbname'};
}

=head2 dbport

=over

=item Usage

  $obj->dbport()        #get existing value
  $obj->dbport($newval) #set new value

=item Function

=item Returns

value of dbport (a scalar)

=item Arguments

new value of dbport (to set)

=back

=cut

sub dbport {
    my $self = shift;

    my $dbport = shift;
    return $self->{'dbport'} = $dbport if defined($dbport);
    return $self->{'dbport'};
}

=head2 dbhost

=over

=item Usage

  $obj->dbhost()        #get existing value
  $obj->dbhost($newval) #set new value

=item Function

=item Returns

value of dbhost (a scalar)

=item Arguments

new value of dbhost (to set)

=back

=cut

sub dbhost {
    my $self = shift;

    my $dbhost = shift;
    return $self->{'dbhost'} = $dbhost if defined($dbhost);
    return $self->{'dbhost'};
}

=head2 dbuser

=over

=item Usage

  $obj->dbuser()        #get existing value
  $obj->dbuser($newval) #set new value

=item Function

=item Returns

value of dbuser (a scalar)

=item Arguments

new value of dbuser (to set)

=back

=cut

sub dbuser {
    my $self = shift;

    my $dbuser = shift;
    return $self->{'dbuser'} = $dbuser if defined($dbuser);
    return $self->{'dbuser'};
}

=head2 dbpass

=over

=item Usage

  $obj->dbpass()        #get existing value
  $obj->dbpass($newval) #set new value

=item Function

=item Returns

value of dbpass (a scalar)

=item Arguments

new value of dbpass (to set)

=back

=cut

sub dbpass {
    my $self = shift;

    my $dbpass = shift;
    return $self->{'dbpass'} = $dbpass if defined($dbpass);
    return $self->{'dbpass'};
}

=head2 notransact

=over

=item Usage

  $obj->notransact()        #get existing value
  $obj->notransact($newval) #set new value

=item Function

=item Returns

value of notransact (a scalar)

=item Arguments

new value of notransact (to set)

=back

=cut

sub notransact {
    my $self = shift;

    my $notransact = shift;
    return $self->{'notransact'} = $notransact if defined($notransact);
    return $self->{'notransact'};
}

=head2 nosequence

=over

=item Usage

  $obj->nosequence()        #get existing value
  $obj->nosequence($newval) #set new value

=item Function

=item Returns

value of nosequence (a scalar)

=item Arguments

new value of nosequence (to set)

=back

=cut

sub nosequence {
    my $self = shift;

    my $nosequence = shift;
    return $self->{'nosequence'} = $nosequence if defined($nosequence);
    return $self->{'nosequence'};
}

=head2 inserts

=over

=item Usage

  $obj->inserts()        #get existing value
  $obj->inserts($newval) #set new value

=item Function

=item Returns

value of inserts (a scalar)

=item Arguments

new value of inserts (to set)

=back

=cut

sub inserts {
    my $self = shift;

    my $inserts = shift if defined(@_);
    return $self->{'inserts'} = $inserts if defined($inserts);
    return $self->{'inserts'};
}

=head2 score_col

=over

=item Usage

  $obj->score_col()        #get existing value
  $obj->score_col($newval) #set new value

=item Function

=item Returns

value of score_col (a scalar)

=item Arguments

new value of score_col (to set)

=back

=cut

sub score_col {
    my $self = shift;
    my $col  = shift if defined(@_);
    return $self->{'score_col'} = $col if defined($col);
    return $self->{'score_col'};
}

=head2 analysis_group

=over

=item Usage

  $obj->analysis_group()        #get existing value
  $obj->analysis_group($newval) #set new value

=item Function

=item Returns

value of analysis_group (a scalar)

=item Arguments

new value of analysis_group (to set)

=back

=cut

sub analysis_group {
    my $self = shift;
    my $anal = shift if defined(@_);
    return $self->{'analysis_group'} = $anal if defined($anal);
    return $self->{'analysis_group'};
}

=head2 global_analysis

=over

=item Usage

  $obj->global_analysis()        #get existing value
  $obj->global_analysis($newval) #set new value

=item Function

=item Returns

value of global_analysis (a scalar)

=item Arguments

new value of global_analysis (to set)

=back

=cut

sub global_analysis {
    my $self = shift;
    my $anal = shift if defined(@_);
    return $self->{'global_analysis'} = $anal if defined($anal);
    return $self->{'global_analysis'};
}

=head2 analysis

=over

=item Usage

  $obj->analysis()        #get existing value
  $obj->analysis($newval) #set new value

=item Function

=item Returns

value of analysis (a scalar)

=item Arguments

new value of analysis (to set)

=back

=cut

sub analysis {
    my $self = shift;
    my $analysis = shift if defined(@_);
    return $self->{'analysis'} = $analysis if defined($analysis);
    return $self->{'analysis'};
}

=head2 organism

=over

=item Usage

  $obj->organism()        #get existing value
  $obj->organism($newval) #set new value

=item Function

=item Returns

value of organism (a scalar)

=item Arguments

new value of organism (to set)

=back

=cut

sub organism {
    my $self = shift;

    my $organism = shift;
    return $self->{'organism'} = $organism if defined($organism); 
    return $self->{'organism'};
}

=head2 dbprofile

=over

=item Usage

  $obj->dbprofile()        #get existing value
  $obj->dbprofile($newval) #set new value

=item Function

=item Returns

value of dbprofile (a scalar)

=item Arguments

new value of dbprofile (to set)

=back

=cut

sub dbprofile {
    my $self = shift;

    my $dbprofile = shift;
    return $self->{'dbprofile'} = $dbprofile if defined($dbprofile);
    return $self->{'dbprofile'};
}

=head2 noload

=over

=item Usage

  $obj->noload()        #get existing value
  $obj->noload($newval) #set new value

=item Function

=item Returns

value of noload (a scalar)

=item Arguments

new value of noload (to set)

=back

=cut

sub noload {
    my $self = shift;

    my $noload = shift;
    return $self->{'noload'} = $noload if defined($noload);
    return $self->{'noload'};
}

=head2 skip_vacuum

=over

=item Usage

  $obj->skip_vacuum()        #get existing value
  $obj->skip_vacuum($newval) #set new value

=item Function

=item Returns

value of skip_vacuum (a scalar)

=item Arguments

new value of skip_vacuum (to set)

=back

=cut

sub skip_vacuum {
    my $self = shift;

    my $skip_vacuum = shift;
    return $self->{'skip_vacuum'} = $skip_vacuum if defined($skip_vacuum);
    return $self->{'skip_vacuum'};
}

=head2 drop_indexes_flag

=over

=item Usage

  $obj->drop_indexes_flag()        #get existing value
  $obj->drop_indexes_flag($newval) #set new value

=item Function

=item Returns

value of drop_indexes_flag (a scalar)

=item Arguments

new value of drop_indexes_flag (to set)

=back

=cut

sub drop_indexes_flag {
    my $self = shift;

    my $drop_indexes_flag = shift;
    return $self->{'drop_indexes_flag'} = $drop_indexes_flag if defined($drop_indexes_flag);
    return $self->{'drop_indexes_flag'};
}

=head2 save_tmpfiles

=over

=item Usage

  $obj->save_tmpfiles()        #get existing value
  $obj->save_tmpfiles($newval) #set new value

=item Function

=item Returns

value of save_tmpfiles (a scalar)

=item Arguments

new value of save_tmpfiles (to set)

=back

=cut

sub save_tmpfiles {
    my $self = shift;
    my $save_tmpfiles = shift if defined(@_);
    return $self->{'save_tmpfiles'} = $save_tmpfiles if defined($save_tmpfiles);    return $self->{'save_tmpfiles'};
}

=head2 no_target_syn

=over

=item Usage

  $obj->no_target_syn()        #get existing value
  $obj->no_target_syn($newval) #set new value

=item Function

=item Returns

value of no_target_syn() (a scalar)

=item Arguments

new value of no_target_syn (to set)

=back

=cut

sub no_target_syn {

    my $self = shift;
    my $no_target_syn = shift if defined(@_);
    return $self->{'no_target_syn'} = $no_target_syn if defined($no_target_syn);
    return $self->{'no_target_syn'};
}

=head2 unique_target

=over

=item Usage

  $obj->unique_target()        #get existing value
  $obj->unique_target($newval) #set new value

=item Function

=item Returns

value of unique_target() (a scalar)

=item Arguments

new value of unique_target (to set)

=back

=cut

sub unique_target {

    my $self = shift;
    my $unique_target = shift if defined(@_);
    return $self->{'unique_target'} = $unique_target if defined($unique_target);
    return $self->{'unique_target'};
}

=head2 dbxref

=over

=item Usage

  $obj->dbxref()        #get existing value
  $obj->dbxref($newval) #set new value

=item Function

=item Returns

value of dbxref (a scalar)

=item Arguments

new value of dbxref (to set)

=back

=cut

sub dbxref {
    my $self = shift;
    my $dbxref = shift if defined(@_);
    return $self->{'dbxref'} = $dbxref if defined($dbxref);
    return $self->{'dbxref'};
}

=head2 primary_dbxref

=over

=item Usage

  $obj->primary_dbxref()        #get existing value
  $obj->primary_dbxref($newval) #set new value

=item Function

=item Returns

value of primary_dbxref (a scalar)

=item Arguments

new value of primary_dbxref (to set)

=back

=cut

sub primary_dbxref {
    my $self = shift;
    my $primary_dbxref = shift if defined(@_);
    return $self->{'primary_dbxref'} = $primary_dbxref if defined($primary_dbxref);
    return $self->{'primary_dbxref'};
}


#####################################################################
#
# Subs moved directly from gmod_bulk_load_gff3.pl
#
#
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

sub print_seq {
  my $self = shift;
  my ($name,$string) = @_;

  my $fh = $self->file_handles('SEQ');
  print $fh "UPDATE feature set residues='$string' WHERE uniquename='$name';\n";
  print $fh "UPDATE feature set seqlen=length(residues) WHERE uniquename='$name';\n";

  return;
}

sub print_af {
  my $self = shift;
  my ($af_id,$f_id,$a_id,$score) = @_;

  my $fh = $self->file_handles('AF');
  if ($self->inserts()) {
    $score       =~ s/\\N/NULL/g;
    my @scores   = split "\t", $score;
    my @q_scores = map { $self->dbh->quote($_) if $_ ne 'NULL'  } @scores;
    my $q_score  = join(',', @q_scores);
    print $fh "INSERT INTO analysisfeature $copystring{'analysisfeature'} VALUES ($af_id,$f_id,$a_id,$q_score);\n";
  }
  else {
    print $fh join("\t", ($af_id,$f_id,$a_id,$score)), "\n";
  }
}

sub print_dbx {
  my $self = shift;
  my ($dbx_id,$db_id,$acc,$vers,$desc) = @_;

  my $fh = $self->file_handles('DBX');
  if ($self->inserts()) {
    my $q_acc  = $self->dbh->quote($acc);
    my $q_vers = $self->dbh->quote($vers);
    my $q_desc = $desc eq '\N' ? 'NULL' : $self->dbh->quote($desc);
    print $fh "INSERT INTO dbxref $copystring{'dbxref'} VALUES ($dbx_id,$db_id,$q_acc,$q_vers,$q_desc);\n";
  }
  else {
    print $fh join("\t",($dbx_id,$db_id,$acc,$vers,$desc)),"\n";
  }
}

sub print_fs {
  my $self = shift;
  my ($fs_id,$s_id,$f_id,$p_id) = @_;

  my $fh = $self->file_handles('FS');
  if ($self->inserts()) {
    print $fh "INSERT INTO feature_synonym $copystring{'feature_synonym'} VALUES ($fs_id,$s_id,$f_id,$p_id);\n";
  }
  else {
    print $fh join("\t", ($fs_id,$s_id,$f_id,$p_id)),"\n";
  }
}

sub print_fdbx {
  my $self = shift;
  my ($fd_id,$f_id,$dx_id) = @_;

  my $fh = $self->file_handles('FDBX');
  if ($self->inserts()) {
    print $fh "INSERT INTO feature_dbxref $copystring{'feature_dbxref'} VALUES ($fd_id,$f_id,$dx_id);\n";
  }
  else {
    print $fh join("\t",($fd_id,$f_id,$dx_id)),"\n";
  }
}

sub print_fcv {
  my $self = shift;
  my ($fcv_id,$f_id,$cvterm_id,$p_id) = @_;

  my $fh = $self->file_handles('FCV');
  if ($self->inserts()) {
    print $fh "INSERT INTO feature_cvterm $copystring{'feature_cvterm'} VALUES ($fcv_id,$f_id,$cvterm_id,$p_id);\n";
  }
  else {
    print $fh join("\t",($fcv_id,$f_id,$cvterm_id,$p_id)),"\n";
  }
}

sub print_syn {
  my $self = shift;
  my ($s_id,$syn,$type_id) = @_;

  my $fh = $self->file_handles('SYN');
  if ($self->inserts()) {
    my $q_syn = $self->dbh->quote($syn);
    print $fh "INSERT INTO synonym $copystring{'synonym'} VALUES ($s_id,$q_syn,$type_id,$q_syn);\n";
  }
  else {
    print $fh join("\t", ($s_id,$syn,$type_id,$syn)),"\n";
  }
}

sub print_floc {
  my $self = shift;
  my ($featureloc_id,$feature_id,$src_id,$start,$end,$strand,$phase,$rank,$locgroup) = @_;

  my $fh = $self->file_handles('FLOC');
  if ($self->inserts()) {
    my $q_strand= $strand eq '\N'? 'NULL' : $strand;
    my $q_phase = $phase eq '\N' ? 'NULL' : $phase;
    print $fh "INSERT INTO featureloc $copystring{'featureloc'} VALUES ($featureloc_id,$feature_id,$src_id,$start,$end,$q_strand,$q_phase,$rank,$locgroup);\n";
  }
  else {
    print $fh join("\t", ($featureloc_id, $feature_id, $src_id, $start, $end, $strand, $phase,$rank,$locgroup)),"\n";
  }
}

sub print_fprop {
  my $self = shift;
  my ($fp_id,$f_id,$cvterm_id,$value,$rank) = @_;

  my $fh = $self->file_handles('FPROP');
  if ($self->inserts()) {
    my $q_value = $self->dbh->quote($value);
    print $fh "INSERT INTO featureprop $copystring{'featureprop'} VALUES ($fp_id,$f_id,$cvterm_id,$q_value,$rank);\n";
  }
  else {
    print $fh join("\t",($fp_id,$f_id,$cvterm_id,$value,$rank)),"\n";
  }
}

sub print_frel {
  my $self = shift;
  my ($nextfeaturerel,$nextfeature,$parent,$part_of) = @_;

  my $fh = $self->file_handles('FREL');
  if ($self->inserts()) {
    print $fh "INSERT INTO feature_relationship $copystring{'feature_relationship'} VALUES ($nextfeaturerel,$nextfeature,$parent,$part_of);\n";
  }
  else {
    print $fh join("\t", ($nextfeaturerel,$nextfeature,$parent,$part_of)),"\n";
  }
}

sub print_f {
  my $self = shift;
  my ($nextfeature,$organism,$name,$uniquename,$type,$seqlen,$dbxref) = @_;

  my $fh = $self->file_handles('F');
  if ($self->inserts()) {
    my $q_name        = $self->dbh->quote($name);
    my $q_uniquename  = $self->dbh->quote($uniquename);
    my $q_seqlen      = $seqlen eq '\N' ? 'NULL' : $seqlen;
    my $q_analysis    = $self->analysis ? "'true'" : "'false'";
    $dbxref      ||= 'NULL';
    print $fh "INSERT INTO feature $copystring{'feature'} VALUES ($nextfeature,$organism,$q_name,$q_uniquename,$type,$q_analysis,$q_seqlen,$dbxref);\n";
  }
  else {
    $dbxref      ||= '\N';
    print $fh join("\t", ($self->nextfeature, $organism, $name, $uniquename, $type, $self->analysis,$seqlen,$dbxref)),"\n";
  }
}

sub create_indexes {
  my $self = shift;
  my $dbh = $self->dbh();
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

sub drop_indexes {
  my $self = shift;
  my $dbh = $self->dbh();
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


sub uniquename_validation {
  my $self = shift;
  my ($uniquename, $type, $organism, $nextfeature) = @_;

  if (
       $self->uniquename_cache(   validate    => 1, 
                                  type_id     => $type,
                                  organism_id => $organism,
                                  uniquename  => $uniquename )
      ) { #if this returns non-zero, it is already in the cache and not valid

      $uniquename = "$uniquename-$nextfeature";
      return $self->uniquename_validation($uniquename, $type, $organism, $nextfeature);

  }
  else { #this uniquename is valid; cache it and return

      $self->uniquename_cache(
                                type_id   => $type,
                                organism_id => $organism,
                                feature_id  => $nextfeature,
                                uniquename  => $uniquename, 
                             );

      return $uniquename;
  }
}

sub dump_ana_contents {
  my $self = shift;
  my $anakey = shift;
  print STDERR "\n\nCouldn't find $anakey in analysis table\n";
  print STDERR "The current contents of the analysis table is:\n\n";

  #confess;

  my $sth
    = $self->dbh->prepare("SELECT analysis_id,name,program FROM analysis");
  printf STDERR "%10s %25s %10s\n\n",
    ('analysis_id','name','program');

  $sth->execute;
  while (my $array_ref = $sth->fetchrow_arrayref) {
    printf STDERR "%10s %25s %10s\n", @$array_ref;
  }

  print STDERR "\n\nCouldn't find $anakey in analysis table\n";

  print STDERR "\nPlease see \`perldoc gmod_bulk_load_gff3.pl\` for more information\n\n";
  exit 1;
}


sub synonyms  {
    my $self = shift;
    my $alias = shift;
    my $feature_id = shift;

    unless ($self->cache('synonym',$alias)) {
      unless ($self->cache('type','synonym')) {
        my $sth
          = $self->dbh->prepare("SELECT cvterm_id FROM cvterm WHERE name='synonym'");
        $sth->execute;
        my ($syn_type) = $sth->fetchrow_array;

#        warn "synonym type: $syn_type\n\n\n\n\n\n";

        $self->cache('type','synonym',$syn_type); 
        warn "unable to find synonym type in cvterm table"
            and next unless $syn_type;
      }

#      warn Dumper($self);
#      warn "\n\n\n\n".$self->cache('type','synonym')."\n\n\n\n";

      #check for pre-existing synonyms with this name
      $self->{queries}{search_synonym}->execute($alias,$self->cache('type','synonym'));
      my ($synonym) = $self->{queries}{search_synonym}->fetchrow_array;

      if ($synonym) {
        unless ($self->{const}{pub}) {
          my $sth=$self->dbh->prepare("SELECT pub_id FROM pub WHERE miniref = 'null'");
          $sth->execute;
          ($self->{const}{pub}) = $sth->fetchrow_array;
        }

        if ( $self->constraint( name => 'feature_synonym_c1',
                                terms=> [ $feature_id , $synonym ] ) ) {
          $self->print_fs($nextfeaturesynonym,$synonym,$feature_id,$self->{const}{pub});

          $nextfeaturesynonym++;
          $self->cache('synonym',$alias,$synonym);
        }

      } else {
        $self->print_syn($nextsynonym,$alias,$self->cache('type','synonym'));

        unless ($self->{const}{pub}) {
          my $sth=$self->dbh->prepare("SELECT pub_id FROM pub WHERE miniref = 'null'");
            $sth->execute;
            my @row_array = $sth->fetchrow_array;
            $self->{const}{pub} = $row_array[0];
        }

        if( $self->constraint( name  => 'feature_synonym_c1',
                               terms => [ $feature_id , $nextsynonym ] ) ) {
          $self->print_fs($nextfeaturesynonym,$nextsynonym,$feature_id,$self->{const}{pub});
          $nextfeaturesynonym++;
          $self->cache('synonym',$alias,$nextsynonym);
          $nextsynonym++;
        }
      }

    } else {
      if ( $self->constraint( name => 'feature_synonym_c1',
                              terms=>  [ $feature_id ,
                                         $self->cache('synonym',$alias) ] ) ) {
        $self->print_fs($nextfeaturesynonym,$self->cache('synonym',$alias),$feature_id,$self->{const}{pub});
        $nextfeaturesynonym++;
      }
    }
}


sub load_data {
  my $self = shift;

  if ($self->drop_indexes_flag()) {
    warn "Dropping indexes...\n";
    $self->drop_indexes();
  }

  my %nextvalue = (
   "feature"              => $self->nextfeature,
   "featureloc"           => $self->nextfeatureloc,
   "feature_relationship" => $nextfeaturerel,
   "featureprop"          => $nextfeatureprop,
   "feature_cvterm"       => $nextfeaturecvterm,
   "synonym"              => $nextsynonym,
   "feature_synonym"      => $nextfeaturesynonym,
   "feature_dbxref"       => $nextfeaturedbxref,
   "dbxref"               => $nextdbxref,
   "analysisfeature"      => $nextanalysisfeature,
  );


  foreach my $table (@tables) {
    $self->file_handles($files{$table})->autoflush;
    if (-s $self->file_handles($files{$table})->filename <= 4) {
        warn "Skipping $table table since the load file is empty...\n";
        next;
    }
    $self->copy_from_stdin($table,
                    $copystring{$table},
                    $files{$table},      #file_handle name
                    $sequences{$table},
                    $nextvalue{$table});
  }

  ($self->dbh->commit() 
      || die "commit failed: ".$self->dbh->errstr()) unless $self->notransact;
  $self->dbh->{AutoCommit}=1;

  #load sequence
  unless ($self->nosequence) {
    $self->load_sequence();
  }

  if ($self->drop_indexes_flag()) {
    warn "Recreating indexes...\n";
    $self->create_indexes();
  }

  unless ($self->skip_vacuum) {
    warn "Optimizing database (this may take a while) ...\n";
    print STDERR "  (";
    foreach (@tables) {
      print STDERR "$_ ";
      $self->dbh->do("VACUUM ANALYZE $_");
    }
  }

  print STDERR ") Done.\n";

  warn "\nWhile this script has made an effort to optimize the database, you\n"
    ."should probably also run VACUUM FULL ANALYZE on the database as well\n";

}


sub copy_from_stdin {
  my $self = shift;
  my $table    = shift;
  my $fields   = shift;
  my $file     = shift;
  my $sequence = shift;
  my $nextval  = shift;

  my $dbh      = $self->dbh();

  warn "Loading data into $table table ...\n";

  my $fh = $self->file_handles($file);
  seek($fh,0,0);

  if ($self->inserts()) {
    # note that if a password is required, the user will have to enter it
    system("psql -q -f " . $fh->filename . " " .
                   "-h " . $self->dbhost() . " " .
                   "-p " . $self->dbport() . " " .
                   "-U " . $self->dbuser() . " " .
                   "-d " . $self->dbname()   )
      && die "FAILED: loading $file failed (error:$!); I can't go on\n";
  }
  else {

    my $query = "COPY $table $fields FROM STDIN;";
    #warn "\t".$query;
    $dbh->do($query) or die "Error when executing: $query: $!\n";

    while (<$fh>) {
      if ( ! ($dbh->pg_putline($_)) ) {
        #error, disconecting
        $dbh->pg_endcopy;
        $dbh->rollback;
        $dbh->disconnect;
        die "error while copying data's of file $file, line $.\n";
      } #putline returns 1 if succesful
    }
    $dbh->pg_endcopy or die "calling endcopy for $table failed: $!\n";

  }
  #update the sequence so that later inserts will work
  $dbh->do("SELECT setval('$sequence', $nextval) FROM $table");
}

sub load_sequence {
    my $self = shift;
    my $dbh  = $self->dbh();
    warn "Loading sequences (if any) ...\n";
    my $fh = $self->file_handles('SEQ');
    seek($fh,0,0);
    while (<$fh>) {
        chomp;
        $dbh->do($_);
    }
}

sub handle_target {
    my $self = shift;
    my ($feature, $uniquename,$name,$featuretype,$type) = @_;

    my @targets = $feature->annotation->get_Annotations('Target');
    my $rank = 1;
    foreach my $target (@targets) {
      my $target_id = $target->target_id;
      my $tstart    = $target->start -1; #convert to interbase
      my $tend      = $target->end;
      my $tstrand   = $target->strand ? $target->strand : '\N';
      my $tsource   = $feature->source->value;

      $self->synonyms($target_id,$self->cache('feature',$uniquename)) if (!$self->no_target_syn);

      my $created_target_feature = 0;

      #check for an existing feature with the Target's uniquename
      if ( $self->uniquename_cache(validate=>1,uniquename=>$target_id) ) {
          $self->print_floc(
                            $self->nextfeatureloc,
                            $self->nextfeature,
                            $self->uniquename_cache(validate=>1,uniquename=>$target_id),
                            $tstart, $tend, $tstrand, '\N',$rank,'0'
            );
      }
      else {
          $self->create_target_feature($name,$featuretype,$uniquename,$target_id,$type,$tstart,$tend,$tstrand,$rank);
          
          $created_target_feature = 1;
      }

      my $score = defined($feature->score->value) ? $feature->score->value : '\N';
      $score    = '.' eq $score                   ? '\N'                   : $score;

      my $featuretype = $feature->type->name;

      my $type = $self->cache('type',$featuretype);

      my $ankey = $self->global_analysis ?
                  $self->analysis_group :
                  $tsource .'_'. $featuretype;

      unless($self->cache('analysis',$ankey)) {
        $self->{queries}{search_analysis}->execute($ankey);
        my ($ana) = $self->{queries}{search_analysis}->fetchrow_array;
        $self->dump_ana_contents($ankey) unless $ana;
        $self->cache('analysis',$ankey,$ana);
      }
      $self->dump_ana_contents($ankey) unless $self->cache('analysis',$ankey);

      my $score_string;
      if      ($self->score_col =~ /^[Ss]/) {
        $score_string = "$score\t\\N\t\\N\t\\N";
      } elsif ($self->score_col =~ /^[Rr]/) {
        $score_string = "\\N\t$score\t\\N\t\\N";
      } elsif ($self->score_col =~ /^[Nn]/) {
        $score_string = "\\N\t\\N\t$score\t\\N";
      } elsif ($self->score_col =~ /^[Ii]/) {
        $score_string = "\\N\t\\N\t\\N\t$score";
      }

      $self->print_af($nextanalysisfeature,
                      $self->nextfeature-$created_target_feature, #takes care of Allen's nextfeature bug--FINALLY!
                      $self->cache('analysis',$ankey),
                      $score_string);
      $nextanalysisfeature++;
      $self->nextfeatureloc('++');
      $rank++;
    }
}

sub create_target_feature {
    my $self = shift;
    my ($name,$featuretype,$uniquename,$target_id,$type,$tstart,$tend,$tstrand,$rank) = @_;

    $self->nextfeature('++');
    $name ||= "$featuretype-$uniquename";

    #$self->print_f($self->nextfeature, $self->organism_id(), $name, $target_id.'_'.$self->nextfeature, $type, '\N','\N');


    my $tuniquename = $target_id.'_'.$self->nextfeature;     # isn't this double call to nextfeature problematic? 
                                                             #It will unecessrally accelerate the growth of feature_id, and possibly lead to problem with very large and old databases.
    if ($self->unique_target){
      $tuniquename = $target_id;
      $name = $target_id;
    }
    $self->print_f($self->nextfeature, $self->organism_id(), $name,$tuniquename , $type, '\N','\N');
 

    $self->print_floc(
           $self->nextfeatureloc,
           ($self->nextfeature)-1,
           $self->nextfeature,
           $tstart,
           $tend,
           $tstrand,
           '\N',
           $rank,
           '0'
          );
    $self->uniquename_cache(
                            feature_id   => $self->nextfeature,
                            type_id      => $type,
                            organism_id  => $self->organism_id(),
                            uniquename   => $target_id
                           );
    return;
}

sub handle_nontarget_analysis {
    my $self = shift;
    my ($feature,$uniquename) = @_;
    my $source = $feature->source->value;
    my $score = $feature->score->value ? $feature->score->value : '\N';
    $score    = '.' eq $score   ? '\N'            : $score;

    my $featuretype = $feature->type->name;

    my $ankey = $self->global_analysis ?
                $self->analysis_group :
                $source .'_'. $featuretype;

    unless ($self->cache('analysis',$ankey)) {
      $self->{queries}{search_analysis}->execute($ankey);
      my ($ana) = $self->{queries}{search_analysis}->fetchrow_array;
      $self->dump_ana_contents($ankey) unless $ana;
      $self->cache('analysis',$ankey,$ana);
    }
    $self->dump_ana_contents($ankey) unless $self->cache('analysis',$ankey);

    my $score_string;
    if      ($self->score_col =~ /^[Ss]/) {
        $score_string = "$score\t\\N\t\\N\t\\N";
      } elsif ($self->score_col =~ /^[Rr]/) {
        $score_string = "\\N\t$score\t\\N\t\\N";
      } elsif ($self->score_col =~ /^[Nn]/) {
        $score_string = "\\N\t\\N\t$score\t\\N";
      } elsif ($self->score_col =~ /^[Ii]/) {
        $score_string = "\\N\t\\N\t\\N\t$score";
    }

    $self->print_af($nextanalysisfeature,$self->cache('feature',$uniquename),$self->cache('analysis',$ankey),$score_string);
    $nextanalysisfeature++;
}


sub handle_dbxref {
    my $self = shift;
    my ($feature,$uniquename) = @_;

    my @dbxrefs = $feature->annotation->get_Annotations('Dbxref');
    my ($dbxref_id,$primary_dbxref_id,$primary_pattern);
    if (defined $self->dbxref and $self->dbxref ne '1') {
        $primary_pattern = $self->dbxref;
    }
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
      if(my $dbxref_id=$self->cache('dbxref',"$database|$accession|$version")){
        if ($primary_pattern and $database =~/$primary_pattern/) {
            $primary_dbxref_id ||= $dbxref_id;
        }
        elsif ($self->dbxref eq '1') {
            $primary_dbxref_id ||= $dbxref_id;
        }
        if($self->constraint( name  => 'feature_dbxref_c1',
                              terms => [ $self->cache('feature',$uniquename) ,
                                         $dbxref_id] ) ) {
          $self->print_fdbx($nextfeaturedbxref,
                            $self->cache('feature',$uniquename),
                            $dbxref_id);
          $nextfeaturedbxref++;
        }
      } else {
          unless ($self->cache('db',$database)) {
              $self->{queries}{search_db}->execute("DB:$database");
              my($db_id) = $self->{queries}{search_db}->fetchrow_array;
              warn "couldn't find database 'DB:$database' in db table"
                 and next unless $db_id;
              $self->cache('db',$database,$db_id);
          }

          #check for an existing dbxref--this could slow things down a lot!
          $self->{queries}{search_long_dbxref}->execute($accession,
                                       $version,$self->cache('db',$database));
          ($dbxref_id) = $self->{queries}{search_long_dbxref}->fetchrow_array;
          if ($dbxref_id) {
            if($self->constraint( name => 'feature_dbxref_c1',
                                  terms=> [ $self->cache('feature',$uniquename),
                                            $dbxref_id ] ) ) {
              $self->print_fdbx($nextfeaturedbxref,
                                $self->cache('feature',$uniquename),
                                $dbxref_id);
              $nextfeaturedbxref++;
            }
            $self->cache('dbxref',"$database|$accession|$version",$dbxref_id);
          } else {
            $dbxref_id = $nextdbxref;
            if($self->constraint( name => 'feature_dbxref_c1',
                                  terms=> [ $self->cache('feature',$uniquename),
                                            $dbxref_id ] ) ){
              $self->print_fdbx($nextfeaturedbxref,
                                $self->cache('feature',$uniquename),
                                $dbxref_id);
              $nextfeaturedbxref++;
            }
            $self->print_dbx($dbxref_id,
                             $self->cache('db',$database),
                             $accession,
                             $version,
                             $desc);
            $self->cache('dbxref',"$database|$accession|$version",$dbxref_id);
            $nextdbxref++;
          }
          if (defined $primary_pattern and defined $database and $database =~/$primary_pattern/) {
              $primary_dbxref_id ||= $dbxref_id;
          }
          elsif (defined $self->dbxref and $self->dbxref eq '1') {
              $primary_dbxref_id ||= $dbxref_id;
          }
      }
    }
    $self->primary_dbxref($primary_dbxref_id) 
            if ($primary_dbxref_id && $self->dbxref);
}


sub handle_ontology_term {
    my $self = shift;
    my ($feature,$uniquename) = @_;

    my @cvterms = map {$_->identifier} $feature->annotation->get_Annotations('Ontology_term');
    my %count;
    my @ucvterms = grep {++$count{$_} < 2} @cvterms;
    foreach my $term (@ucvterms) {
      next unless $term;
      unless ($self->cache('type',$term)) {
        my($d,$a) = $term =~ /^(.+?):(.+?)$/;

        my $db_name;
        if ($d eq 'GO') {
          $self->{queries}{search_dbxref}->execute($a,'%Gene Ontology%'   ,'GO');
        } elsif ($d eq 'SO') {
          $self->{queries}{search_dbxref}->execute($a,'Sequence Ontology' ,'SO');
        } elsif ($self->cache('ontology',$d)) {
          $self->{queries}{search_dbxref}->execute($a,$self->cache('ontology',$d), $d );
        }

        my ($dbxref) = $self->{queries}{search_dbxref}->fetchrow_array;
        warn "couldn't find $term in dbxref for db:".
              $self->cache('ontology',$d)." ($d)\n" 
            and next unless $dbxref;

        $self->{queries}{search_cvterm_id_w_dbxref}->execute($dbxref);
        my ($temp_cvterm) = $self->{queries}{search_cvterm_id_w_dbxref}->fetchrow_array;
        $self->cache('type',$term, $temp_cvterm);
        warn "couldn't find $term 's cvterm_id in cvterm table\n"
          and next unless $temp_cvterm;
      }
      unless ($self->{const}{pub}) {
        my $sth = $self->dbh->prepare("SELECT pub_id FROM pub WHERE miniref = 'null'");
        $sth->execute;
        ($self->{const}{pub}) = $sth->fetchrow_array;
      }

      if($self->constraint( name  => 'feature_cvterm_c1',
                            terms => [ $self->cache('feature',$uniquename), 
                                       $self->cache('type',$term) ] ) ){
        $self->print_fcv($nextfeaturecvterm,$self->cache('feature',$uniquename),$self->cache('type',$term),$self->{const}{pub});
        $nextfeaturecvterm++;
      }
    }
}


sub handle_source {
    my $self = shift;
    my ($feature,$uniquename,$source) = @_;

    unless ($self->{const}{gff_source_db}) {
      my $sth = $self->dbh->prepare("SELECT db_id FROM db WHERE name='GFF_source'");
      $sth->execute;
      ($self->{const}{gff_source_db}) = $sth->fetchrow_array;
    }

    if ($self->{const}{gff_source_db}) {
      unless ($self->cache('dbxref',$source)) {
        #first, check if this source is already in the database

        $self->{queries}{search_source_dbxref}->execute($source, $self->{const}{gff_source_db});
        my ($chado_source) = $self->{queries}{search_source_dbxref}->fetchrow_array;

        if ($chado_source) {
          $self->cache('dbxref',$source,$chado_source);
        } else {
          $self->cache('dbxref',$source,$nextdbxref);
          $self->print_dbx($nextdbxref,$self->{const}{gff_source_db},$source,1,'\N');
          $nextdbxref++;
        }
      }
      my $dbxref_id = $self->cache('dbxref',$source);
      if($self->constraint( name => 'feature_dbxref_c1',
                            terms=> [ $self->cache('feature',$uniquename),
                                      $dbxref_id ] ) ){
        $self->print_fdbx($nextfeaturedbxref,$self->cache('feature',$uniquename),$dbxref_id);
        $nextfeaturedbxref++;
      }
    } else {
      $self->{const}{source_success} = 0; #geting GFF_source failed, so don't try anymore
    }
}


sub handle_unreserved_tags {
    my $self = shift;
    my ($feature,$uniquename,@unreserved_tags) = @_;

    foreach my $tag (@unreserved_tags) {
      next if $tag eq 'source';
      next if $tag eq 'phase';
      next if $tag eq 'seq_id';
      next if $tag eq 'type';
      next if $tag eq 'score';
      next if $tag eq 'dbxref';

      unless ($self->{const}{auto_cv_id}){
        my $sth = $self->dbh->prepare("SELECT cv_id FROM cv WHERE name='autocreated' or name='". $self->fp_cv  ."'");
        $sth->execute;
        ($self->{const}{auto_cv_id}) = $sth->fetchrow_array;
      }

      if (!$self->{const}{tried_fp_cv} and !$self->{const}{fp_cv_id}) {
        my $sth = $self->dbh->prepare("SELECT cv_id FROM cv WHERE name='". $self->fp_cv  ."'");
        $sth->execute;
        ($self->{const}{fp_cv_id}) = $sth->fetchrow_array;
        $self->{const}{tried_fp_cv} = 1;
      }

      unless ( $self->cache('type',$tag) ) {
        #check fp cv first, then autocreated
        $self->{queries}{search_cvterm_id}->execute(
                                 $tag, 
                                 $self->{const}{fp_cv_id})
                              if $self->{const}{fp_cv_id};
        my ($tag_cvterm) = $self->{queries}{search_cvterm_id}->fetchrow_array;

        unless ($tag_cvterm) {
            $self->{queries}{search_cvterm_id}->execute(
                                 $tag, 
                                 $self->{const}{auto_cv_id});
            ($tag_cvterm) = $self->{queries}{search_cvterm_id}->fetchrow_array;
        }

        if ($tag_cvterm) { #good, the term is already there
          $self->cache('type',$tag,$tag_cvterm);
        } else { #bad! the term is not there for now we die with a helpful message
          dbxref_error_message($tag) && die;
        }
      }
      #moving on, add this to the featureprop table
      my @values = map {$_->value} $feature->annotation->get_Annotations($tag);
      my $rank=0;
      foreach my $value (@values) {
        $self->print_fprop($nextfeatureprop,$self->cache('feature',$uniquename),$self->cache('type',$tag),$value,$rank);
        $rank++;
        $nextfeatureprop++;
      }
    }
}


sub handle_note {
    my $self = shift;
    my ($feature,$uniquename) = @_;

    my @notes = map {$_->value} $feature->annotation->get_Annotations('Note');
    my $rank = 0;
    foreach my $note (@notes) {
      unless ($self->cache('type','Note')) {
          my $sth =
              $self->dbh->prepare(
                           "SELECT cvterm_id FROM cvterm WHERE name='Note'
                            AND cv_id in
                              (SELECT cv_id FROM cv WHERE name='null' OR
                                                          name='local')");
          $sth->execute();
          my ($note_type) = $sth->fetchrow_array;
          $self->cache('type','Note',$note_type);
      }

      if ( $self->constraint( name => 'featureprop_c1',
                              terms=> [ $self->cache('feature',$uniquename),
                                        $self->cache('type','Note'), 
                                        $rank ] ) ) {
        $self->print_fprop($nextfeatureprop,$self->cache('feature',$uniquename),$self->cache('type','Note'),uri_unescape($note),$rank);
        $rank++;
        $nextfeatureprop++;
      }
    }
}


sub handle_gap {
    my $self = shift;
    my ($feature,$uniquename) = @_;

    my @notes = map {$_->value} $feature->annotation->get_Annotations('Gap');
    my $rank = 0;
    foreach my $note (@notes) {
      unless ($self->cache('type','Gap')) {
          my $sth =
              $self->dbh->prepare(
                     "SELECT cvterm_id FROM cvterm WHERE name='Gap'
                            AND cv_id in
                              (SELECT cv_id FROM cv WHERE name='null' OR
                                                          name='local')");
          $sth->execute();
          my ($gap_type) = $sth->fetchrow_array; 
          $self->cache('type','Gap',$gap_type);
      }

      if ( $self->constraint( name => 'featureprop_c1',
                              terms=> [ $self->cache('feature',$uniquename),
                                        $self->cache('type','Gap'),
                                        $rank ] ) ) {
        $self->print_fprop($nextfeatureprop,$self->cache('feature',$uniquename),$self->cache('type','Gap') ,uri_unescape($note),$rank);
        $rank++;
        $nextfeatureprop++;
      }
    }
}

=head2 handle_CDS

=over

=item Usage

  $obj->handle_CDS($feature_obj)

=item Function

This function stores CDS and UTR features in a temporary database
table for processing after the entire GFF3 file has be seen.

=item Returns

Nothing

=item Arguments

A Bio::FeatureIO CDS or UTR object

=back

=cut

sub handle_CDS {
    my $self = shift;
    my $feat = shift;
    my $dbh  = $self->dbh;

#    warn Dumper($feat);

    my $feat_id     = ($feat->annotation->get_Annotations('ID'))[0]->value
               if ($feat && ($feat->annotation->get_Annotations('ID'))[0]);
    my @feat_parents= map {$_->value} 
               $feat->annotation->get_Annotations('Parent')
               if ($feat && ($feat->annotation->get_Annotations('Parent'))[0]);

    #assume that an exon can have at most one grandparent (gene, operon)
    my $parent_id = $self->cache('feature',$feat_parents[0]) if $feat_parents[0];

    unless ($parent_id) {
        warn "\n\nThere is a ".$feat->type->name." feature with no parent.  I think that is wrong!\n\n";
    }

    my $feat_grandparent = $self->cache('parent',$parent_id);

    unless ($self->cds_db_exists()) {
        $self->create_cds_db;
    }

    my $fmin = $feat->start;              #check that this is interbase
    my $fmax = $feat->end;
    my $object = safeFreeze $feat;

    my $feat_type   = $feat->type->name;
    my $seq_id = $feat->seq_id;

    my $insert = qq/
        INSERT INTO tmp_cds_handler (gff_id,seq_id,type,fmin,fmax,object) 
        VALUES (?,?,?,?,?,?)
    /;
    my $sth = $dbh->prepare($insert);
    $sth->execute($feat_id,$seq_id,$feat_type,$fmin,$fmax,$object);

    #get the value of the row just inserted
    $sth = $dbh->prepare("SELECT currval('tmp_cds_handler_cds_row_id_seq')");
    $sth->execute;
    my ($cds_row_id) = $sth->fetchrow_array;

    $sth = $dbh->prepare("INSERT INTO tmp_cds_handler_relationship (cds_row_id,parent_id,grandparent_id) VALUES (?,?,?)");
    for my $parent (@feat_parents) {
        $sth->execute($cds_row_id,$parent,$feat_grandparent);        
    }

    return;
}


=head2 process_CDS

=over

=item Usage

  my $feature_iterator = $obj->process_CDS()

=item Function

Retrieves CDS and UTR objects from a temporary database table and
does necessary conversion to exon and polypeptide features and
returns a feature iterator to let the bulk loader process them

=item Returns

A Bio::GMOD::Adaptor::FeatureIterator object

=item Arguments

None.

=back

=cut

sub process_CDS {
    my $self = shift;
    my $dbh  = $self->dbh;

    #get one of the features from the database(!)

#    print Dumper($self);
#    die;

    my $min_feat_query = "SELECT min(fmax) FROM tmp_cds_handler";
    my $sth = $dbh->prepare($min_feat_query);
    $sth->execute;
    my ($min_feat) = $sth->fetchrow_array;

    my $cds_utr_query = qq/
SELECT distinct cds.gff_id,cds.object,cds.type,cds.fmin,cds.fmax, rel.grandparent_id
FROM tmp_cds_handler cds, tmp_cds_handler_relationship rel
WHERE rel.cds_row_id = cds.cds_row_id
  AND rel.grandparent_id IN
        (SELECT grandparent_id FROM tmp_cds_handler_relationship
          WHERE cds_row_id IN
           (SELECT cds_row_id FROM tmp_cds_handler WHERE fmax = ?))
ORDER BY cds.fmin,cds.gff_id
                /;
    $sth = $dbh->prepare($cds_utr_query);
    $sth->execute($min_feat);

    my %polypeptide;
    my @feature_list;
    my $grandparent;
#do stuff, create a list of features
    while (my $feat_row = $sth->fetchrow_hashref) {
        $grandparent  = $$feat_row{ grandparent_id };
        my ($feat_obj)= thaw $$feat_row{ object };
        my $type      = $$feat_row{ type };
        my $fmin      = $$feat_row{ fmin };
        my $fmax      = $$feat_row{ fmax };
        my @parents   = $feat_obj->annotation->get_Annotations('Parent');

        for my $parent_id (@parents) {
          if ($type =~ /CDS/) {
            #check for a polypeptide with for this parent
            if ($polypeptide{ $parent_id }) {
            #add to it if it exists

                if ( $polypeptide{ $parent_id }->start > $fmin ) {
                    $polypeptide{ $parent_id }->start($fmin);
                }
                if ( $polypeptide{ $parent_id }->end   < $fmax ) {
                    $polypeptide{ $parent_id }->end($fmax);
                }
            }
            else {
            #create it if it doesn't
                my $polyp = Bio::SeqFeature::Annotated->new();
                $polyp->start(  $fmin  );
                $polyp->end(    $fmax  );
                $polyp->strand( $feat_obj->strand );
                $polyp->name(   $parent_id.' polypeptide');

                my $polyp_ac = Bio::Annotation::Collection->new();
                $polyp_ac->add_Annotation(
                    'Note',Bio::Annotation::SimpleValue->new(
                     'polypeptide feature inferred from GFF3 CDS feature'));
                $polyp_ac->add_Annotation(
                    'Derives_from',Bio::Annotation::SimpleValue->new(
                      $parent_id));
                $polyp_ac->add_Annotation(
                    'type',Bio::Annotation::OntologyTerm->new(
                      -term => Bio::Ontology::Term->new(-name=>'polypeptide')));
                $polyp_ac->add_Annotation(
                    'seq_id',Bio::Annotation::SimpleValue->new(
                      $feat_obj->seq_id->value));
                $polyp_ac->add_Annotation(
                    'phase',Bio::Annotation::SimpleValue->new('.'));
                $polyp->annotation($polyp_ac);

                $polypeptide{ $parent_id } = $polyp;
            }
          }
        }

        #create an exon feature (or add to an existing one)
        my $merged_exon = 0;
        for my $exon ( @feature_list ) {
            next unless ($exon->type->name eq 'exon');
            if ($exon->start == $fmax - 1 ) {
        #this feature imideately precedes an existing exon, glue them together

                $exon->start($fmin);

                $exon = $self->_merge_annotations($exon, $feat_obj);
                $merged_exon = 1;
            }

            if ($exon->end == $fmin -1 ) {
        #this feature come right after an existing exon, glue them together
                $exon->end($fmax);

                $exon = $self->_merge_annotations($exon, $feat_obj);
                $merged_exon = 1;
            }
        }

#        if ($merged_exon) {
#            print Dumper($_) for @feature_list;
#        }

        unless ($merged_exon) {
        #convert the existing feature to an exon
            my $ac = $feat_obj->annotation();

            $ac->remove_Annotations('type');
            $ac->add_Annotation('type',Bio::Annotation::OntologyTerm->new(
                             -term => Bio::Ontology::Term->new(-name=>'exon')));
            $ac->add_Annotation('Note',Bio::Annotation::SimpleValue->new(
                             'Exon inferred from GFF3 ' .
                             $feat_obj->type->name .
                             ' feature line'));

            $feat_obj->annotation($ac);

            push @feature_list, $feat_obj;
        }
    }
    #add the polypeptides to the list
    if ($self->noexon) {
        #only return the polpeptides if noexon is set
        @feature_list = values %polypeptide;
    }
    else {
        push @feature_list, values %polypeptide;
    }

#delete the features from the temp tables:

    my $delete_query = qq/DELETE FROM tmp_cds_handler WHERE cds_row_id IN
  (SELECT cds_row_id FROM tmp_cds_handler_relationship WHERE grandparent_id =?)
   /;
    $sth = $dbh->prepare($delete_query);
    $sth->execute($grandparent);
    $dbh->commit;

#return an iterator
    if (@feature_list > 0) {
        return Bio::GMOD::DB::Adapter::FeatureIterator->new(\@feature_list);
    }
    else {
        return 0;
    }
}

=head2 _merge_annotations

=over

=item Usage

  $obj->_merge_annotations()

=item Function

Take two adjecent feature objects and merge their annotations

=item Returns

The merged feature object (which will be an exon feature)

=item Arguments

Two feature objects, with the existing exon first

=back

=cut

sub _merge_annotations {
    my ($self, $exon, $obj2) = @_;

    my $exon_ac = $exon->annotation;
    my $obj2_ac = $obj2->annotation;

    for my $key ( $obj2_ac->get_all_annotation_keys() ) {
        my @values = $obj2_ac->get_Annotations($key);
        if ($key eq 'type') {
            $exon_ac->add_Annotation('Note',Bio::Annotation::SimpleValue->new(
                'exon feature the result of two merged features in GFF3, one '.
                'of which was a '.$obj2->type->name.' feature')); 
        }
        elsif ( $key eq 'source'
             or $key eq 'Parent'
             or $key eq 'seq_id'
             or $key eq 'phase'
             or $key eq 'score' ) {
            next;
        }
        else {
            for my $value ( @values ) {
                $exon_ac->add_Annotation($key,$value); 
            }
        }
    }
    $exon->annotation($exon_ac);

    return $exon;
}


=pod

    my $iterator;
  #so its time to process the most recent set of features and return an iterator
    if (($feat_id && $self->{cdscache}{id} && $feat_id ne $self->{cdscache}{id})
         or
       ($feat_parent && $self->{cdscache}{parent} && $feat_parent ne $self->{cdscache}{parent})
         or
       (!$self->{cdscache}{id} && !$self->{cdscache}{parent}) ) {

        #this is a new cds feature so package up the old one to give back
        if ($self->noexon) {
            $iterator = Bio::GMOD::DB::Adapter::FeatureIterator->new(
                $self->{cdscache}{polypeptide_obj} 
            );
        }
        elsif ($self->{cdscache}{polypeptide_obj}) {
            push @{ $self->{cdscache}{feature_array} }, 
                $self->{cdscache}{polypeptide_obj};

            $iterator = Bio::GMOD::DB::Adapter::FeatureIterator->new(
                \@{ $self->{cdscache}{feature_array} }
            );
        }

        #now empty the caches and set parent/id
        $self->{cdscache}{feature_array}   = ();
        $self->{cdscache}{polypeptide_obj} = '';
        $self->{cdscache}{id}              = $feat_id;
        $self->{cdscache}{parent}          = $feat_parent;
    }

    #get the current AnnotationCollection and change
    # that is, convert CDS features to exon features
    if ($feat && !$self->noexon) {

        #check for existing created exons that but up against this feature
        my $start = $feat->start;
        my $stop  = $feat->end;

        my $appended_feature_flag = 0;
        for my $cached_feat ( @{ $self->{cdscache}{feature_array} } ) {
            if ($stop + 1 == $cached_feat->start) {
                my $cached_ac = $cached_feat->annotation();
                my $ac        = $feat->annotation();

                $ac->remove_Annotations('type');
                $ac->add_Annotation('Note',Bio::Annotation::SimpleValue->new(
                             'Exon added to from an adjacent feature in GFF3'));
                
                my @annot_list = $ac->get_Annotations;
                for my $annot (@annot_list) {
                    $cached_ac->add_Annotation($annot);
                } 

                $cached_feat->start($start);
                $appended_feature_flag = 1;
            }
            elsif ( $start == $cached_feat->end + 1 ) {
                my $cached_ac = $cached_feat->annotation();
                my $ac        = $feat->annotation();

                $ac->remove_Annotations('type');
                $ac->add_Annotation('Note',Bio::Annotation::SimpleValue->new(
                             'Exon added to from an adjacent feature in GFF3'));
                my @annot_list = $ac->get_Annotations;
                for my $annot (@annot_list) {
                    $cached_ac->add_Annotation($annot);
                }

                $cached_feat->end($stop);
                $appended_feature_flag = 1;
            } 
        }

        unless ( $appended_feature_flag ) {
            my $ac = $feat->annotation();

            $ac->remove_Annotations('type'); 
            $ac->add_Annotation('type',Bio::Annotation::OntologyTerm->new(
                             -term => Bio::Ontology::Term->new(-name=>'exon')));
            $ac->add_Annotation('Note',Bio::Annotation::SimpleValue->new(
                             'Exon inferred from GFF3 ' .
                             $feat->type->name .
                             ' feature line'));

            $feat->annotation($ac); 
        }
    }

    if ($feat && !$self->{cdscache}{polypeptide_obj}) {
    #polypeptide doesn't exist yet, so create it
        my $polyp = Bio::SeqFeature::Annotated->new();
        $polyp->start(    $feat->start  );
        $polyp->end(      $feat->end    );
        $polyp->strand(   $feat->strand );
        $polyp->name(     $feat_parent.' polypeptide');

        my $polyp_ac = Bio::Annotation::Collection->new();
        $polyp_ac->add_Annotation('Note',Bio::Annotation::SimpleValue->new(
                      'polypeptide feature inferred from GFF3 CDS feature'));
        $polyp_ac->add_Annotation('Derives_from',Bio::Annotation::SimpleValue->new(
                      $feat_parent));
        $polyp_ac->add_Annotation('type',Bio::Annotation::OntologyTerm->new(
                      -term => Bio::Ontology::Term->new(-name=>'polypeptide')));
        $polyp_ac->add_Annotation('seq_id',Bio::Annotation::SimpleValue->new(
                      $feat->seq_id->value));
        $polyp->annotation($polyp_ac);

        $self->{cdscache}{polypeptide_obj} = $polyp;
    }
    #check for bounds change on the existing polypeptide
    elsif ( $feat 
              && $self->{cdscache}{polypeptide_obj}->start > $feat->start
              && $feat->type->name =~ /CDS/ ) {
        $self->{cdscache}{polypeptide_obj}->start($feat->start);
    }
    elsif ( $feat 
              && $self->{cdscache}{polypeptide_obj}->end < $feat->end
              && $feat->type->name =~ /CDS/ ) {
        $self->{cdscache}{polypeptide_obj}->end($feat->end);
    }

    push @{ $self->{cdscache}{feature_array} }, $feat if $feat;

    return $iterator;
}
=cut

sub handle_parent {
    my $self = shift;
    my ($feature) = @_;

    for my $p_anot ( $feature->annotation->get_Annotations('Parent') ) {
        my $pname  = $p_anot->value;
        my $parent = $self->cache('feature',$pname);
        die "\nno parent $pname;\nyou probably need to rerun the loader with the --recreate_cache option\n\n" unless $parent;

        $self->cache('parent',$self->nextfeature,$parent);

        $self->print_frel($nextfeaturerel,$self->nextfeature,$parent,$part_of);

        $nextfeaturerel++;
    }
}

sub handle_derives_from {
    my $self = shift;
    my ($feature) = @_;

    for my $p_anot ( $feature->annotation->get_Annotations('Derives_from') ) {
        my $pname  = $p_anot->value;
        my $parent = $self->cache('feature',$pname);
        die "no parent ".$pname unless $parent;

        $self->cache('parent',$self->nextfeature,$parent);

        $self->print_frel($nextfeaturerel,$self->nextfeature,$parent,$derives_from);
        $nextfeaturerel++;
    }
}


sub src_second_chance {
    my $self = shift;
    my ($feature) = @_;

    my $src;
    if($feature->seq_id->value eq '.'){
      $src = '\N';
    } else {

      my ($temp_f_id)= $self->uniquename_cache(
                                        validate => 1,
                                        uniquename => $feature->seq_id->value
                                              );
      $self->cache('feature',$feature->seq_id->value,$temp_f_id);

      unless ($temp_f_id) {
        $self->{queries}{count_name}->execute($feature->seq_id->value);
        my ($n_rows) = $self->{queries}{count_name}->fetchrow_array;
        if (1 < $n_rows) {
          die "more that one source for ".$feature->seq_id->value;
        } elsif ( 1==$n_rows) {
          $self->{queries}{search_name}->execute($feature->seq_id->value);
          my ($tmp_source) = $self->{queries}{search_name}->fetchrow_array;
          $self->cache('feature',$feature->seq_id->value,$tmp_source);
        } else {
          confess "Unable to find srcfeature "
               .$feature->seq_id->value
               ." in the database.\nPerhaps you need to rerun your data load with the '--recreate_cache' option.";
        }
      }
      $src = $self->cache('feature',$feature->seq_id->value);
    }

    return $src;
}

sub get_type {
    my $self = shift;
    my ($featuretype) = @_;

    return $self->cache('type',$featuretype) 
        if defined $self->cache('type',$featuretype);

    $self->{queries}{search_cvterm_id}->execute($featuretype, $sofa_id);
    my ($tmp_type) = $self->{queries}{search_cvterm_id}->fetchrow_array;
    $self->cache('type',$featuretype,$tmp_type);

    return $tmp_type if defined $tmp_type;

    die "no cvterm for ".$featuretype;
}

sub get_src_seqlen {
    my $self = shift;
    my ($feature) = @_;

    my ($src,$seqlen);
    if ( defined(($feature->annotation->get_Annotations('ID'))[0])
         && $feature->seq_id->value
            eq ($feature->annotation->get_Annotations('ID'))[0]->value ) {
        #this is a srcfeature (ie, a reference sequence)
      $src = $self->nextfeature;
      $seqlen = $feature->end - $feature->start +1;
    } else { # normal case

      $src = $self->cache('feature',$feature->seq_id);
      $seqlen = '\N';
    }

    return ($src,$seqlen);
}

sub flush_caches {
    my $self = shift;

    $self->{cache}            = '';
    $self->{uniquename_cache} = '';

    return;
}


#########################################################################
#
#  Methods that are to be used with the GFF3 preprocessor.  It makes
#  use of the chado database to make a temp table that it uses to sort
#  content of the GFF file
#
sub sorter_create_table  {
    my $self = shift;
    my $dbh  = $self->dbh;
  
    #determine if the table already exists
    my $sth = $dbh->prepare("SELECT count(*) FROM pg_tables WHERE tablename='gff_sort_tmp'");
    $sth->execute;
    my ($table_exists) = $sth->fetchrow_array;
    return if $table_exists;

 
    $dbh->do("CREATE TABLE gff_sort_tmp (
    refseq   varchar(4000),
    id       varchar(4000),
    parent   varchar(4000),
    gffline  varchar(4000),
    row_id   serial not null,
    primary key(row_id)
    ) "); 

    $dbh->do("CREATE INDEX gff_sort_tmp_idx1 ON gff_sort_tmp (refseq)");
    $dbh->do("CREATE INDEX gff_sort_tmp_idx2 ON gff_sort_tmp (id)");
    $dbh->do("CREATE INDEX gff_sort_tmp_idx3 ON gff_sort_tmp (parent)");

    return;
}

sub sorter_vacuum_table {
    my $self = shift;
    my $dbh  = $self->dbh;

    $dbh->do("vacuum gff_sort_tmp");
    return;
}

sub sorter_delete_from_table {
    my $self = shift;
    my $dbh  = $self->dbh;

    $dbh->do("DELETE FROM gff_sort_tmp");
    return;
}

sub sorter_insert_line {
    my $self = shift;
    my ($refseq, $id, $parent, $line) = @_;
    $self->{'queries'}{'insert_gff_sort_tmp'}->execute(
                                               $refseq, $id, $parent, $line);
    return;
}

sub sorter_get_refseqs {
    my $self = shift;
    my $dbh  = $self->dbh;

    my $sth  = $dbh->prepare("SELECT distinct gffline FROM gff_sort_tmp WHERE refseq = id") or die;
    $sth->execute or die;

    my $result = $sth->fetchall_arrayref or die;

    my @to_return = map { $$_[0] } @$result; 
   
    return @to_return; 
}

sub sorter_get_no_parents {
    my $self = shift;
    my $dbh  = $self->dbh;

    my $sth  = $dbh->prepare("SELECT distinct gffline FROM gff_sort_tmp WHERE id is null and parent is null") or die; 
    $sth->execute or die;
    
    my $result = $sth->fetchall_arrayref or die;

    my @to_return = map { $$_[0] } @$result;

    $sth  = $dbh->prepare("SELECT distinct gffline,id FROM gff_sort_tmp WHERE parent is null and refseq != id order by id") or die;
    $sth->execute or die;

    $result = $sth->fetchall_arrayref or die;

    push @to_return, map { $$_[0] } @$result;

    return @to_return;
}

sub sorter_get_second_tier {
    my $self = shift;
    my $dbh  = $self->dbh;

#ARGH! need to deal with multiple parents!

    my $sth  = $dbh->prepare("SELECT distinct gffline,id,parent FROM gff_sort_tmp WHERE parent in (SELECT id FROM gff_sort_tmp WHERE parent is null) order by parent,id") or die;
    $sth->execute or die;

    my $result = $sth->fetchall_arrayref or die;

    my @to_return = map { $$_[0] } @$result;

    return @to_return;
}

sub sorter_get_third_tier {
    my $self = shift;
    my $dbh  = $self->dbh;

#ARGH! need to deal with multiple parents!

    my $sth  = $dbh->prepare("SELECT distinct gffline,id,parent FROM gff_sort_tmp WHERE parent in (SELECT id FROM gff_sort_tmp WHERE parent in (SELECT id FROM gff_sort_tmp WHERE parent is null)) order by parent,id") or die;
    $sth->execute or die;

    my $result = $sth->fetchall_arrayref or die;

    my @to_return = map { $$_[0] } @$result;

    return @to_return;
}

=head2 cds_db_exists

=over

=item Usage

  $obj->cds_db_exists()        #get existing value
  $obj->cds_db_exists($newval) #set new value

=item Function

Flag for determining if the cds temp database exists

=item Returns

value of cds_db_exists (a scalar)

=item Arguments

new value of cds_db_exists (to set)

=back

=cut

sub cds_db_exists {
    my $self = shift;
    my $cds_db_exists = shift if defined(@_);
    return $self->{'cds_db_exists'} = $cds_db_exists if defined($cds_db_exists);
    return $self->{'cds_db_exists'};
}

=head2 create_cds_db

=over

=item Usage

  $obj->create_cds_db()

=item Function

Create the temp database table for dealing with CDS and UTR features

=item Returns

Nothing

=item Arguments

None

=back

=cut

sub create_cds_db {
    my $self = shift;
    my $dbh = $self->dbh;

    #determine if the table exists and drop if it does

    my $exists_query = "SELECT tablename FROM pg_tables WHERE tablename = 'tmp_cds_handler'";  
    my $sth = $dbh->prepare($exists_query);
    $sth->execute();
    my ($exists) = $sth->fetchrow_array; 

    if ($exists) {
        warn "Dropping cds temp tables...\n";
        $dbh->do("DROP INDEX tmp_cds_handler_seq_id");
        $dbh->do("DROP INDEX tmp_cds_handler_fmax");
        $dbh->do("DROP INDEX tmp_cds_handler_relationship_grandparent");
        $dbh->do("DROP TABLE tmp_cds_handler_relationship");
        $dbh->do("DROP TABLE tmp_cds_handler");
        $dbh->commit();
    }
 
    #create the table

    warn "Creating cds temp tables...\n";
    my $table_create = qq/
        CREATE TABLE tmp_cds_handler (
            cds_row_id   serial not null,
            seq_id       varchar(1024),
            gff_id       varchar(1024),
            type         varchar(1024) not null,
            fmin         int not null,
            fmax         int not null,
            object       text not null,
            primary key(cds_row_id)
        )
    /;

    $dbh->do($table_create);
    $dbh->do("CREATE INDEX tmp_cds_handler_seq_id ON tmp_cds_handler (seq_id)");
    $dbh->do("CREATE INDEX tmp_cds_handler_fmax ON tmp_cds_handler (fmax)");
    $dbh->commit;

    $table_create = qq/
        CREATE TABLE tmp_cds_handler_relationship (
            rel_row_id   serial not null,
            cds_row_id   int,
            foreign key (cds_row_id) references tmp_cds_handler (cds_row_id) on delete cascade,
            parent_id    varchar(1024),
            grandparent_id varchar(1024),
            primary key(rel_row_id)
        )
    /;

    $dbh->do($table_create);
    $dbh->do("CREATE INDEX tmp_cds_handler_relationship_grandparent ON tmp_cds_handler_relationship(grandparent_id)");
    $dbh->commit;

    $self->cds_db_exists(1);
    return;
}


1;
