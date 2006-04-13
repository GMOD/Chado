package Bio::GMOD::DB::Adapter;

use strict;
use Carp;
use DBI;
use File::Temp;
use Data::Dumper;
use URI::Escape;

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

    $self->{const}{source_success} = 1; #flag to indicate GFF_source is in db table
    $self->initialize_ontology();
    $self->prepare_queries();
    $self->initialize_sequences();

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
                = new File::Temp(TEMPLATE => $key.'XXXX');
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

If none, creates the cache.  Otherwise, it takes a hash.  
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
        if ($argv{type_id}){  #valididate type & org too
            if ($self->{uniquename_cache}{$argv{uniquename}}{type_id}
               && $self->{uniquename_cache}{$argv{uniquename}}{organism_id}) {
                return $self->{uniquename_cache}{$argv{uniquename}}{feature_id};
            }
        }
        elsif ($self->{uniquename_cache}{$argv{uniquename}}) {
            return $self->{uniquename_cache}{$argv{uniquename}}{feature_id};
        }
        else {
            return 0;
        }
    }
    elsif ($argv{type_id}) { 
        $self->{uniquename_cache}{$argv{uniquename}}{type_id} 
              = $argv{type_id};
        $self->{uniquename_cache}{$argv{uniquename}}{organism_id} 
              = $argv{organism_id};
        $self->{uniquename_cache}{$argv{uniquename}}{feature_id}
              = $argv{feature_id};
        return;
    }
    else {
        my $unique_cache = $self->dbh->prepare(
             "select feature_id,uniquename,type_id,organism_id from feature");
        $unique_cache->execute();

        while (my $un_hash = $unique_cache->fetchrow_hashref() ) {
            my $name = $$un_hash{'uniquename'};
            $self->{uniquename_cache}{$name}{'feature_id'}
                      = $$un_hash{'feature_id'};
            $self->{uniquename_cache}{$name}{'type_id'}  
                      = $$un_hash{'type_id'};
            $self->{uniquename_cache}{$name}{'organism_id'}
                      = $$un_hash{'organism_id'};
        }
        $unique_cache->finish();
        return;
    }
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
       "select cvterm_id from cvterm where name = 'part_of'");
    $sth->execute;
    ($part_of) = $sth->fetchrow_array();

    $sth = $self->dbh->prepare(
      "select cvterm_id from cvterm where name = 'derives_from'");$sth->execute;
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
    return $self->{'dbname'} = shift if defined(@_);
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
    return $self->{'dbport'} = shift if defined(@_);
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
    return $self->{'dbhost'} = shift if defined(@_);
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
    return $self->{'dbuser'} = shift if defined(@_);
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
    return $self->{'dbpass'} = shift if defined(@_);
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
    return $self->{'notransact'} = shift if defined(@_);
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
    return $self->{'nosequence'} = shift if defined(@_);
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
    return $self->{'inserts'} = shift if defined(@_);
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
    return $self->{'organism'} = shift if defined(@_); 
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
    return $self->{'dbprofile'} = shift if defined(@_);
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
    return $self->{'noload'} = shift if defined(@_);
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
    return $self->{'skip_vacuum'} = shift if defined(@_);
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
    return $self->{'drop_indexes_flag'} = shift if defined(@_);
    return $self->{'drop_indexes_flag'};
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
  my ($nextfeature,$organism,$name,$uniquename,$type,$seqlen) = @_;

  my $fh = $self->file_handles('F');
  if ($self->inserts()) {
    my $q_name        = $self->dbh->quote($name);
    my $q_uniquename  = $self->dbh->quote($uniquename);
    my $q_seqlen      = $seqlen eq '\N' ? 'NULL' : $seqlen;
    my $q_analysis    = $self->analysis ? "'true'" : "'false'";
    print $fh "INSERT INTO feature $copystring{'feature'} VALUES ($nextfeature,$organism,$q_name,$q_uniquename,$type,$q_analysis,$q_seqlen);\n";
  }
  else {
    print $fh join("\t", ($self->nextfeature, $organism, $name, $uniquename, $type, $self->analysis,$seqlen)),"\n";
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

  confess;

  my $sth
    = $self->dbh->prepare("SELECT analysis_id,name,program FROM analysis");
  printf STDERR "%10s %25s %10s\n\n",
    ('analysis_id','name','program');

  $sth->execute;
  while (my $array_ref = $sth->fetchrow_arrayref) {
    printf STDERR "%10s %25s %10s\n", @$array_ref;
  }

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

      $self->synonyms($target_id,$self->cache('feature',$uniquename));

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

      my $score = $feature->score->value ? $feature->score->value : '\N';
      $score    = '.' eq $score          ? '\N'                   : $score;

      my $featuretype = $feature->type->name;

      my $type = $self->cache('type',$featuretype);

      my $ankey = $self->global_analysis ?
                  $self->analysis_group :
                  $tsource .'_'. $featuretype;

      unless($self->cache('analysis',$ankey)) {
        $self->{queries}{search_analysis}->execute($ankey);
        my ($ana) = $self->{queries}{search_analysis}->fetchrow_array;
        dump_ana_contents($ankey) unless $ana;
        $self->cache('analysis',$ankey,$ana);
      }
      dump_ana_contents($ankey) unless $self->cache('analysis',$ankey);

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

    $self->print_f($self->nextfeature, $self->organism_id(), $name, $target_id.'_'.$self->nextfeature, $type, '\N');
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
      if(my $temp_id = $self->cache('dbxref',"$database|$accession|$version")){
        if($self->constraint( name  => 'feature_dbxref_c1',
                              terms => [ $self->cache('feature',$uniquename) ,
                                         $temp_id] ) ) {
          $self->print_fdbx($nextfeaturedbxref,$self->cache('feature',$uniquename),$temp_id);
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
          my ($existing_dbxref) = $self->{queries}{search_long_dbxref}->fetchrow_array;
          if ($existing_dbxref) {
            if($self->constraint( name => 'feature_dbxref_c1',
                                  terms=> [ $self->cache('feature',$uniquename),
                                            $existing_dbxref ] ) ) {
              $self->print_fdbx($nextfeaturedbxref,$self->cache('feature',$uniquename),$existing_dbxref);
              $nextfeaturedbxref++;
            }
            $self->cache('dbxref',"$database|$accession|$version",$existing_dbxref);
          } else {
            if($self->constraint( name => 'feature_dbxref_c1',
                                  terms=> [ $self->cache('feature',$uniquename),
                                            $nextdbxref ] ) ){
              $self->print_fdbx($nextfeaturedbxref,$self->cache('feature',$uniquename),$nextdbxref);
              $nextfeaturedbxref++;
            }
            $self->print_dbx($nextdbxref,$self->cache('db',$database),$accession,$version,$desc);
            $self->cache('dbxref',"$database|$accession|$version",$nextdbxref);
            $nextdbxref++;
          }
      }
    }
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
        my $sth = $self->dbh->prepare("SELECT cv_id FROM cv WHERE name='autocreated'");
        $sth->execute;
        ($self->{const}{auto_cv_id}) = $sth->fetchrow_array;
      }

      unless ( $self->cache('type',$tag) ) {
        $self->{queries}{search_cvterm_id}->execute($tag, $self->{const}{auto_cv_id});
        my ($tag_cvterm) = $self->{queries}{search_cvterm_id}->fetchrow_array;
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
        $self->print_frop($nextfeatureprop,$self->cache('feature',$uniquename),$self->cache('type','Gap') ,uri_unescape($note),$rank);
        $rank++;
        $nextfeatureprop++;
      }
    }
}


sub handle_parent {
    my $self = shift;
    my ($feature) = @_;

    my $pname  = undef;
    ($pname)   = ($feature->annotation->get_Annotations('Parent'))[0]->value;
    my $parent = $self->cache('parent',$pname);
    die "no parent ".$pname unless $parent;

    $self->print_frel($nextfeaturerel,$self->nextfeature,$parent,$part_of);

    $nextfeaturerel++;
}

sub handle_derives_from {
    my $self = shift;
    my ($feature) = @_;

    my $pname  = undef;
    ($pname)   = ($feature->annotation->get_Annotations('Derives_from'))[0]->value;
    my $parent = $self->cache('parent',$pname);
    die "no parent ".$pname unless $parent;

    $self->print_frel($nextfeaturerel,$self->nextfeature,$parent,$derives_from);
    $nextfeaturerel++;
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
      $self->cache('parent',$feature->seq_id->value,$temp_f_id);

      unless ($temp_f_id) {
        $self->{queries}{count_name}->execute($feature->seq_id->value);
        my ($n_rows) = $self->{queries}{count_name}->fetchrow_array;
        if (1 < $n_rows) {
          die "more that one source for ".$feature->seq_id->value;
        } elsif ( 1==$n_rows) {
          $self->{queries}{search_name}->execute($feature->seq_id->value);
          my ($tmp_source) = $self->{queries}{search_name}->fetchrow_array;
          $self->cache('parent',$feature->seq_id->value,$tmp_source);
        } else {
          confess "Unable to find srcfeature "
               .$feature->seq_id->value
               ." in the database\n";
        }
      }
      $src = $self->cache('parent',$feature->seq_id->value);
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
    if ( defined (($feature->annotation->get_Annotations('ID'))[0])
         && $feature->seq_id->value
            eq ($feature->annotation->get_Annotations('ID'))[0] ) {
        #this is a srcfeature (ie, a reference sequence)
      $src = $self->nextfeature;
      $self->cache('parent',$feature->seq_id->value,$src);
      $seqlen = $feature->end - $feature->start +1;
    } else { # normal case
      $src = $self->cache('parent',$feature->seq_id->value);
      $seqlen = '\N';
    }

    return ($src,$seqlen);
}


1;
