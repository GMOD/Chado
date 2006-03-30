package Bio::GMOD::DB::Adapter;

use strict;
use DBI;
use File::Temp;

#set lots of package-wide variables:
my ($nextfeature,$nextfeatureloc,$nextfeaturerel,$nextfeatureprop,
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
   F              => "feature.tmp",
   FLOC           => "featureloc.tmp",
   FREL           => "feature_relationship.tmp",
   FPROP          => "featureprop.tmp",
   FCV            => "feature_cvterm.tmp",
   SYN            => "synonym.tmp",
   FS             => "feature_synonym.tmp",
   DBX            => "dbxref.tmp",
   FDBX           => "feature_dbxref.tmp",
   AF             => "analysisfeature.tmp",
   SEQ            => "sequence.tmp",
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


sub new {
    my $class = shift;
    my %arg   = @_;

    my $self  = bless {}, ref($class) || $class;

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
    $self->analysis(        $arg{analysis}        );
    $self->organism(        $arg{organism}        );
    $self->dbprofile(       $arg{dbprofile}       );
    $self->noload(          $arg{noload}          );
    $self->skip_vacuum(     $arg{skip_vacuum}     );
    $self->drop_indexes(    $arg{drop_indexes}    );

    my $dbh = DBI->connect(
        "dbi:Pg:dbname=$arg{dbname};port=$arg{dbport};host=$arg{dbhost}",
        $arg{dbuser},
        $arg{dbpass},
        {AutoCommit => $arg{notransact}}
    );
    $self->dbh($dbh); 
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
        for my $key (%files) {
            $self->{file_handles}{$key} 
                = new File::Temp(TEMPLATE => $files{$key});
        }
        return;
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

If none, creates the cache.  Otherwise, it takes a hash.  If the
hash has a key 'type_id', it uses the values in the hash to update
the cache. If it has a key 'uniquename', it returns the feature_id
of the feature corresponding to that uniquename if present, 0 if it is not.

=back

=cut

sub uniquename_cache {
    my ($self, %argv) = @_;

    if ($argv{type_id}) { 
        $self->{uniquename_cache}{$argv{uniquename}}{type_id} 
              = $argv{type_id};
        $self->{uniquename_cache}{$argv{uniquename}}{organism_id} 
              = $argv{organism_id};
        $self->{uniquename_cache}{$argv{uniquename}}{feature_id}
              = $argv{feature_id};
        return;
    }
    elsif ($argv{uniquename}) {
        if ($self->{uniquename_cache}{$argv{uniquename}}) {
            return $self->{uniquename_cache}{$argv{uniquename}}{feature_id};
        }
        else {
            return 0;
        }
    }
    else {
        my $unique_cache = $db->prepare(
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

With a organism common name as an arg, sets the orgainism_id value

=item Returns

value of organism_id (a scalar)

=item Arguments

With a organism common name as an arg, sets the orgainism_id value

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
    ($nextfeature) = $sth->fetchrow_array();

    $sth = $self->dbh->prepare("select nextval('$sequences{featureloc}')");
    $sth->execute;
    ($nextfeatureloc) = $sth->fetchrow_array();

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
    return $self->{'dbh'} = shift if defined(@_);
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
    return $self->{'score_col'} = shift if defined(@_);
    return $self->{'score_col'};
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
    return $self->{'global_analysis'} = shift if defined(@_);
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
    return $self->{'analysis'} = shift if defined(@_);
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

=head2 drop_indexes

=over

=item Usage

  $obj->drop_indexes()        #get existing value
  $obj->drop_indexes($newval) #set new value

=item Function

=item Returns

value of drop_indexes (a scalar)

=item Arguments

new value of drop_indexes (to set)

=back

=cut

sub drop_indexes {
    my $self = shift;
    return $self->{'drop_indexes'} = shift if defined(@_);
    return $self->{'drop_indexes'};
}


