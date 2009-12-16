package Bio::GMOD::DB::Adapter;

use strict;
use Carp qw/cluck confess/;
use DBI;
use File::Temp qw/ tempdir /;
use Data::Dumper;
use URI::Escape;
use Sys::Hostname;
use Bio::SeqFeature::Generic;
use Bio::GMOD::DB::Adapter::FeatureIterator;

use base 'Bio::Root::Root';

## dgg## use FreezeThaw qw( freeze thaw safeFreeze ); ## see below; Data::Dumper is better

#set lots of package-wide variables: # dgg; drop these for $self->{nextoid}{$table}  
my ( $part_of,$derives_from,$sofa_id);
  # $nextfeaturerel,
  # $nextfeatureprop,
  #  $nextfeaturecvterm,
  # $nextsynonym,
  # $nextfeaturesynonym,
  #  $nextfeaturedbxref,
  #  $nextdbxref,
  # $nextanalysisfeature,
   

#------------ START Table Entries ------------------------------
#  any new table to populate needs entries here (and a print_tablename)

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
   "cvterm", ## dgg
   "db", ## dgg
   "cv", ## dgg
   "analysis", #dgg
   "organism", #dgg
);

my %use_public_tables = (
   db                   => "public.db",
   cv                   => "public.cv",
   cvterm               => "public.cvterm",
   organism             => "public.organism",
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
   analysisfeature      => "analysisfeature_analysisfeature_id_seq",
   cvterm               => "cvterm_cvterm_id_seq", # dgg
   db                   => "db_db_id_seq", # dgg
   cv                   => "cv_cv_id_seq", # dgg
   analysis             => "analysis_analysis_id_seq", # dgg
   organism             => "organism_organism_id_seq", # dgg
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
   cvterm               => "(cvterm_id,cv_id,name,dbxref_id,definition)", # is_obsolete, is_relationshiptype ## dgg
   db                   => "(db_id,name,description)", # ,urlprefix,url ## dgg
   cv                   => "(cv_id,name,definition)",  ## dgg
   analysis             => "(analysis_id,name,program,programversion,sourcename)",  ## dgg
   organism             => "(organism_id,genus,species,common_name,abbreviation)",  ## dgg
);

#------------ END Table Entries ------------------------------

## dgg; see sub file_handles
my %files = map { $_ => 'FH'.$_; } @tables,'sequence','delete'; # SEQ special case in feature table 
# (
#    feature              => 'F', 
#    featureloc           => 'FLOC',
#    feature_relationship => 'FREL',
#    featureprop          => 'FPROP',
#    feature_cvterm       => 'FCV',
#    synonym              => 'SYN',
#    feature_synonym      => 'FS',
#    dbxref               => 'DBX',
#    feature_dbxref       => 'FDBX',
#    analysisfeature      => 'AF',
#    sequence             => 'SEQ',
#    cvterm               => 'CVTERM', # dgg
#    db               => 'DB', # dgg
#    cv               => 'CV', # dgg
# );


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
## dgg patch see note below
# use constant SEARCH_ANALYSIS =>
#                "SELECT analysis_id FROM analysis WHERE name=?";
use constant SEARCH_ANALYSIS =>
               "SELECT analysis_id FROM analysis 
                WHERE (name = ?) OR (program=? and (sourcename=? OR sourcename is NULL))";
use constant SEARCH_SYNONYM =>
               "SELECT synonym_id FROM synonym WHERE name=? AND type_id=?";

use constant CREATE_CACHE_TABLE =>
               "CREATE TABLE public.tmp_gff_load_cache (
                    feature_id int,
                    uniquename varchar(1000),
                    type_id int,
                    organism_id int
                )";
use constant DROP_CACHE_TABLE =>
               "DROP TABLE public.tmp_gff_load_cache";
use constant VERIFY_TMP_TABLE =>
               "SELECT count(*) FROM pg_class WHERE relname=? and relkind='r'";
use constant POPULATE_CACHE_TABLE =>
               "INSERT INTO public.tmp_gff_load_cache
                SELECT feature_id,uniquename,type_id,organism_id FROM feature";
use constant CREATE_CACHE_TABLE_INDEX1 =>
               "CREATE INDEX tmp_gff_load_cache_idx1 
                    ON public.tmp_gff_load_cache (feature_id)";
use constant CREATE_CACHE_TABLE_INDEX2 =>
               "CREATE INDEX tmp_gff_load_cache_idx2 
                    ON public.tmp_gff_load_cache (uniquename)";
use constant CREATE_CACHE_TABLE_INDEX3 =>
               "CREATE INDEX tmp_gff_load_cache_idx3
                    ON public.tmp_gff_load_cache (uniquename,type_id,organism_id)";
use constant VALIDATE_TYPE_ID =>
               "SELECT feature_id FROM public.tmp_gff_load_cache
                    WHERE type_id = ? AND
                          organism_id = ? AND
                          uniquename = ?";
use constant VALIDATE_ORGANISM_ID =>
               "SELECT feature_id FROM public.tmp_gff_load_cache
                    WHERE organism_id = ? AND
                          uniquename = ?";
use constant VALIDATE_UNIQUENAME =>
               "SELECT feature_id FROM public.tmp_gff_load_cache WHERE uniquename=?";
use constant INSERT_CACHE_TYPE_ID =>
               "INSERT INTO public.tmp_gff_load_cache 
                  (feature_id,uniquename,type_id,organism_id) VALUES (?,?,?,?)";
use constant INSERT_CACHE_UNIQUENAME =>
               "INSERT INTO public.tmp_gff_load_cache (feature_id,uniquename)
                  VALUES (?,?)";

use constant INSERT_GFF_SORT_TMP =>
               "INSERT INTO gff_sort_tmp (refseq,id,parent,gffline)
                  VALUES (?,?,?,?)";

use constant CREATE_META_TABLE =>
               "CREATE TABLE gff_meta (
                     name        varchar(100),
                     hostname    varchar(100),
                     starttime   timestamp not null default now() 
                )";
use constant SELECT_FROM_META =>
               "SELECT name,hostname,starttime FROM gff_meta";
use constant INSERT_INTO_META =>
               "INSERT INTO gff_meta (name,hostname) VALUES (?,?)";
use constant DELETE_FROM_META =>
               "DELETE FROM gff_meta WHERE name = ? AND hostname = ?";
use constant TMP_TABLE_CLEANUP =>
               "DELETE FROM tmp_gff_load_cache WHERE feature_id >= ?";

my $ALLOWED_UNIQUENAME_CACHE_KEYS =
               "feature_id|type_id|organism_id|uniquename|validate";
my $ALLOWED_CACHE_KEYS =
               "analysis|db|dbxref|feature|parent|source|synonym|type|ontology|property|const|srcfeature";


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

    my $private_schema = $arg{private_schema};

    my $dbh = DBI->connect(
        "dbi:Pg:dbname=$dbname;port=$dbport;host=$dbhost",
        $dbuser,
        $dbpass,
        {AutoCommit => $notrans,
         TraceLevel => 0}
    ) or $self->throw("couldn't connect to the database");

    if ($private_schema) {
        $dbh->do("SET search_path=$private_schema,public,pg_catalog");
    }

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
    $self->is_analysis(     $arg{is_analysis}     );
    $self->organism(        $arg{organism}        );
    $self->dbprofile(       $arg{dbprofile}       );
    $self->noload(          $arg{noload}          );
    $self->skip_vacuum(     $arg{skip_vacuum}     );
    $self->drop_indexes_flag($arg{drop_indexes_flag});
    $self->noexon(          $arg{noexon}          );
    $self->nouniquecache(   $arg{nouniquecache}   );
    $self->recreate_cache(  $arg{recreate_cache}  );
    $self->save_tmpfiles(   $arg{save_tmpfiles}   );
    $self->random_tmp_dir(  $arg{random_tmp_dir}  );
    $self->no_target_syn(   $arg{no_target_syn}   );
    $self->unique_target(   $arg{unique_target}   );
    $self->dbxref(          $arg{dbxref}          );
    $self->fp_cv(           $arg{fp_cv} || 'autocreated' );
    $self->{'addpropertycv'}= $arg{addpropertycv}; # dgg
    $self->private_schema(  $arg{private_schema}  );
    $self->use_public_cv(   $arg{use_public_cv}   );
    
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
  $self->{'queries'}{'validate_organism_id'}
                                  = $dbh->prepare(VALIDATE_ORGANISM_ID);
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
        $self->throw( "wrong number of constraint terms") if (@terms != 2);
        if ($self->{$constraint}{$terms[0]}{$terms[1]}) {
            return 0; #this combo is already in the constraint
        }
        else {
            $self->{$constraint}{$terms[0]}{$terms[1]}++;
            return 1;
        }
    }
    elsif ($constraint eq 'featureprop_c1') {
        $self->throw("wrong number of constraint terms") if (@terms != 3);
        if ($self->{$constraint}{$terms[0]}{$terms[1]}{$terms[2]}) {
            return 0; #this combo is already in the constraint
        }
        else {
            $self->{$constraint}{$terms[0]}{$terms[1]}{$terms[2]}++;
            return 1;
        }
    }
    else {
        $self->throw("I don't know how to deal with the constraint $constraint: typo?");
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
             srcfeature      #feature_id is a srcfeature

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

    return $self->{cache}{$top_level}{$key} unless defined($value);

    return $self->{cache}{$top_level}{$key} = $value; 
}

=head2 nextoid

=over

=item Usage

  $obj->nextoid($table)        #get existing value
  $obj->nextoid($table,$newval) #set new value

=item Function

=item Returns

value of next table id (a scalar)

=item Arguments

new value of next table id (to set)

=back

=cut

sub nextoid {  
  my $self = shift;
  my $table= shift;
  my $arg  = shift if defined(@_);
  if (defined($arg) && $arg eq '++') {
      return $self->{'nextoid'}{$table}++;
  }
  elsif (defined($arg)) {
      return $self->{'nextoid'}{$table} = $arg;
  }
  return $self->{'nextoid'}{$table} if ($table);
  # return nextvalueHash(); #??
}

sub nextvalueHash {  
  my $self= shift;
  my %nextval=();
  for my $t (@tables) {
    $nextval{$t} = $self->{'nextoid'}{$t};
    }
  return %nextval;
}
#   return (
#    "feature"              => $self->nextfeature,
#    "featureloc"           => $self->nextfeatureloc,
#    "feature_relationship" => $nextfeaturerel,
#    "featureprop"          => $nextfeatureprop,
#    "feature_cvterm"       => $nextfeaturecvterm,
#    "synonym"              => $nextsynonym,
#    "feature_synonym"      => $nextfeaturesynonym,
#    "feature_dbxref"       => $nextfeaturedbxref,
#    "dbxref"               => $nextdbxref,
#    "analysisfeature"      => $nextanalysisfeature,
#    "cvterm"               => $nextcvterm, #dgg
#    "db"               => $nextdbname, #dgg
#    "cv"               => $nextcvname, #dgg
#    );


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

## dgg; keep - this is public; 
sub nextfeature {
    my $self = shift;

    my $fid = $self->nextoid('feature',@_);
    if (!$self->first_feature_id() ) {
        $self->first_feature_id( $fid );
    }

    return $fid;
#     my $arg = shift if defined(@_);
#     if (defined($arg) && $arg eq '++') {
#         return $self->{'nextfeature'}++;
#     }
#     elsif (defined($arg)) {
#         return $self->{'nextfeature'} = $arg;
#     }
#     return $self->{'nextfeature'};
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

## dgg; keep - this is public; 
sub nextfeatureloc {
    my $self = shift;
    return $self->nextoid('featureloc',@_);
# 
#     my $arg = shift if defined(@_);
#     if (defined($arg) && $arg eq '++') {
#         return $self->{nextfeatureloc}++;
#     }
#     elsif (defined($arg)) {
#         return $self->{nextfeatureloc} = $arg;
#     }
#     return $self->{nextfeatureloc};
}

# =head2 nextfeaturerel
# 
# =over
# 
# =item Usage
# 
#   $obj->nextfeaturerel()        #get existing value
#   $obj->nextfeaturerel($newval) #set new value
# 
# =item Function
# 
# =item Returns
# 
# value of nextfeaturerel (a scalar)
# 
# =item Arguments
# 
# new value of nextfeaturerel (to set)
# 
# =back
# 
# =cut
# 
# sub nextfeaturerel {
#     my $self = shift;
#     return $self->nextoid('feature_relationship',@_);
# #     return $nextfeaturerel = shift if defined(@_);
# #     return $nextfeaturerel;
# }

# =head2 nextfeatureprop
# 
# =over
# 
# =item Usage
# 
#   $obj->nextfeatureprop()        #get existing value
#   $obj->nextfeatureprop($newval) #set new value
# 
# =item Function
# 
# =item Returns
# 
# value of nextfeatureprop (a scalar)
# 
# =item Arguments
# 
# new value of nextfeatureprop (to set)
# 
# =back
# 
# =cut
# 
# sub nextfeatureprop {
#     my $self = shift;
#     return $self->nextoid('featureprop',@_);
# #     return $nextfeatureprop = shift if defined(@_);
# #     return $nextfeatureprop;
# }

# =head2 nextfeaturecvterm
# 
# =over
# 
# =item Usage
# 
#   $obj->nextfeaturecvterm()        #get existing value
#   $obj->nextfeaturecvterm($newval) #set new value
# 
# =item Function
# 
# =item Returns
# 
# value of nextfeaturecvterm (a scalar)
# 
# =item Arguments
# 
# new value of nextfeaturecvterm (to set)
# 
# =back
# 
# =cut
# 
# sub nextfeaturecvterm {
#     my $self = shift;
#     return $self->nextoid('feature_cvterm',@_);
# #     return $nextfeaturecvterm = shift if defined(@_);
# #     return $nextfeaturecvterm;
# }

# =head2 nextsynonym
# 
# =over
# 
# =item Usage
# 
#   $obj->nextsynonym()        #get existing value
#   $obj->nextsynonym($newval) #set new value
# 
# =item Function
# 
# =item Returns
# 
# value of nextsynonym (a scalar)
# 
# =item Arguments
# 
# new value of nextsynonym (to set)
# 
# =back
# 
# =cut
# 
# sub nextsynonym {
#     my $self = shift;
#     return $self->nextoid('synonym',@_);
# #     return $nextsynonym = shift if defined(@_);
# #     return $nextsynonym;
# }

# =head2 nextfeaturesynonym
# 
# =over
# 
# =item Usage
# 
#   $obj->nextfeaturesynonym()        #get existing value
#   $obj->nextfeaturesynonym($newval) #set new value
# 
# =item Function
# 
# =item Returns
# 
# value of nextfeaturesynonym (a scalar)
# 
# =item Arguments
# 
# new value of nextfeaturesynonym (to set)
# 
# =back
# 
# =cut
# 
# sub nextfeaturesynonym {
#     my $self = shift;
#     return $self->nextoid('feature_synonym',@_);
# #     return $nextfeaturesynonym = shift if defined(@_);
# #     return $nextfeaturesynonym;
# }

# =head2 nextfeaturedbxref
# 
# =over
# 
# =item Usage
# 
#   $obj->nextfeaturedbxref()        #get existing value
#   $obj->nextfeaturedbxref($newval) #set new value
# 
# =item Function
# 
# =item Returns
# 
# value of nextfeaturedbxref (a scalar)
# 
# =item Arguments
# 
# new value of nextfeaturedbxref (to set)
# 
# =back
# 
# =cut
# 
# sub nextfeaturedbxref {
#     my $self = shift;
#     return $self->nextoid('feature_dbxref',@_);
# #     return $nextfeaturedbxref = shift if defined(@_);
# #     return $nextfeaturedbxref;
# }

# =head2 nextdbxref
# 
# =over
# 
# =item Usage
# 
#   $obj->nextdbxref()        #get existing value
#   $obj->nextdbxref($newval) #set new value
# 
# =item Function
# 
# =item Returns
# 
# value of nextdbxref (a scalar)
# 
# =item Arguments
# 
# new value of nextdbxref (to set)
# 
# =back
# 
# =cut
# 
# sub nextdbxref {
#     my $self = shift;
#     return $self->nextoid('dbxref',@_);
# #     return $nextdbxref = shift if defined(@_);
# #     return $nextdbxref;
# }

# =head2 nextanalysisfeature
# 
# =over
# 
# =item Usage
# 
#   $obj->nextanalysisfeature()        #get existing value
#   $obj->nextanalysisfeature($newval) #set new value
# 
# =item Function
# 
# =item Returns
# 
# value of nextanalysisfeature (a scalar)
# 
# =item Arguments
# 
# new value of nextanalysisfeature (to set)
# 
# =back
# 
# =cut
# 
# sub nextanalysisfeature {
#     my $self = shift;
#     return $self->nextoid('analysisfeature',@_);
# #     return $nextanalysisfeature = shift if defined(@_);
# #     return $nextanalysisfeature;
# }



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

** dgg; revised this so FH = 'FH'.$tablename
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
        my $fhhame= ($argv =~ /^FH/) ? $argv : 'FH'.$argv; #dgg
        return $self->{file_handles}{$fhhame};
    }
    else {
        my $file_path = "./";
        if ($self->random_tmp_dir ) {
            $file_path = tempdir( CLEANUP => $self->save_tmpfiles() ? 0 : 1 );
        }
        for my $key (keys %files) {
            $self->{file_handles}{$files{$key}} 
                = new File::Temp(
                                 TEMPLATE => "chado-$key-XXXX", #dgg; was $keyXXXX
                                 SUFFIX   => '.dat',
                                 UNLINK   => $self->save_tmpfiles() ? 0 : 1, 
                                 DIR      => $file_path,
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
        elsif (defined $argv{organism_id}) { #validate uniquename and organism
            $self->{'queries'}{'validate_organism_id'}->execute(
                $argv{organism_id},
                $argv{uniquename},
            ); 

            my ($feature_id)
                 = $self->{'queries'}{'validate_organism_id'}->fetchrow_array;
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

    ## dgg; handle also 'Saccharomyces cerevisiae'
    ## dgg; now may have new organism on each gff line (e.g. uniprot data)
    ## start using $self->cache('organism',...);
    
    my ($genus,$species)= split(" ",$organism_name,2);
    my ($sth,$orgid);
    
    if($species && $genus =~ /^[A-Z]/) {
      $sth = $self->dbh->prepare("SELECT organism_id FROM organism WHERE genus = ? AND species = ?");
      $sth->execute($genus,$species);
    } else { # 2nd way
      $sth = $self->dbh->prepare("SELECT organism_id FROM organism WHERE common_name = ? OR abbreviation = ?");
      $sth->execute($organism_name, $organism_name);

      if ($sth->rows > 1) {
          die "\n\nMore than one organism with the common name $organism_name,\ntry using the abbreviation or the genus and species in quotes instead\n\n";
      }
    }
    ($orgid) = $sth->fetchrow_array; 

    unless($orgid) { # try other way
      if($species && $genus =~ /^[A-Z]/) {
        $sth = $self->dbh->prepare("SELECT organism_id FROM organism WHERE common_name = ? OR abbreviation = ?");
        $sth->execute($organism_name, $organism_name);
      } elsif($species) { # 2nd way
        $sth = $self->dbh->prepare("SELECT organism_id FROM organism WHERE genus = ? AND species = ?");
        $sth->execute($genus,$species);
      }
      ($orgid) = $sth->fetchrow_array; 
    }
    
    # auto-add here
    if(!$orgid && $self->{'addpropertycv'} && $species && $genus =~ /^[A-Z]/) {
      # create analysis entry
      $orgid= $self->nextoid('organism');
      $self->print_organism( $orgid, $genus, $species);
      $self->nextoid('organism','++'); 
      ## $self->cache('organism',$organism_name,$orgid);
    }
    
    $self->{'organism_id'}= $orgid;
    
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

        print STDERR "Creating indexes...\n";
        $dbh->do(CREATE_CACHE_TABLE_INDEX1);
        $dbh->do(CREATE_CACHE_TABLE_INDEX2);
        $dbh->do(CREATE_CACHE_TABLE_INDEX3);

        $dbh->commit;

        print STDERR "Adjusting the primary key sequences (if necessary)...";
        $self->update_sequences();
        print STDERR "Done.\n";
    }
    return;
}

=head2 place_lock

=over

=item Usage

  $obj->place_lock()

=item Function

To place a row in the gff_meta table (creating that table if necessary) 
that will prevent other users/processes from doing GFF bulk loads while
the current process is running.

=item Returns

Nothing

=item Arguments

None

=back

=cut

sub place_lock {
    my ($self, %argv) = @_;

    #first determine if the meta table exists
    my $dbh = $self->dbh;
    my $sth = $dbh->prepare(VERIFY_TMP_TABLE);
    $sth->execute('gff_meta');

    my ($table_exists) = $sth->fetchrow_array;

    if (!$table_exists) {
       print STDERR "Creating gff_meta table...\n";
       $dbh->do(CREATE_META_TABLE); 
    } 

    #check for existing lock
    my $select_query = $dbh->prepare(SELECT_FROM_META);
    $select_query->execute();

    while (my @result = $select_query->fetchrow_array) {
        my ($name,$host,$time) = @result;
        my ($progname,$pid)  = split /\-/, $name;

        if ($progname eq 'gmod_bulk_load_gff3.pl') {
            print STDERR "\n\n\nWARNING: There is another gmod_bulk_load_gff3.pl process\n";
            print STDERR "running on $host, with a process id of $pid\n";
            print STDERR "which started at $time\n";
            print STDERR "\nIf that process is no longer running, you can remove the lock by providing\n";
            print STDERR "the --remove_lock flag when running gmod_bulk_load_gff3.pl\n\n";
            print STDERR "Note that if the last bulk load process crashed, you may also need the\n";
            print STDERR "--recreate_cache option as well\n\n";

            exit(-2);
        }
    }

    my $pid = $$;
    my $name = "gmod_bulk_load_gff3.pl-$pid";
    my $hostname = hostname;

    my $insert_query = $dbh->prepare(INSERT_INTO_META);
    $insert_query->execute($name,$hostname);

    return;
}

=head2 remove_lock

=over

=item Usage

  $obj->remove_lock()

=item Function

To remove the row in the gff_meta table that prevents other gmod_bulk_load_gff3.pl processes from running while the current process is running.

=item Returns

Nothing

=item Arguments

None

=back

=cut

sub remove_lock {
    my ($self, %argv) = @_;

    my $dbh = $self->dbh;
    my $select_query = $dbh->prepare(SELECT_FROM_META) or warn "select prepare failed";
    $select_query->execute() or warn "select from meta failed";

    my $delete_query = $dbh->prepare(DELETE_FROM_META) or warn "delete prepare failed";

    while (my @result = $select_query->fetchrow_array) {
        my ($name,$host,$time) = @result;

        if ($name =~ /gmod_bulk_load_gff3/) {
            $delete_query->execute($name,$host) or warn "removing the lock failed!";
            $dbh->commit unless $self->dbh->{AutoCommit};
        }
    }

    return;
}

=head2 cleanup_tmp_table

=over

=item Usage

  $obj->cleanup_tmp_table()

=item Function

Called when there is an abnormal exit from a loading program.  It deletes
entries in the tmp_gff_load_cache table that have feature_ids that were used
during the current session.

=item Returns

Nothing

=item Arguments

None (it needs the first feature_id, but that is stored in the object).

=back

=cut

sub cleanup_tmp_table {
    my $self = shift;

    my $dbh = $self->dbh;
    my $first_feature = $self->first_feature_id();
    return unless $first_feature;

    my $delete_query = $dbh->prepare(TMP_TABLE_CLEANUP);


    warn "Attempting to clean up the loader temp table (so that --recreate_cache\nwon't be needed)...\n";
    $delete_query->execute($first_feature); 

    return;
}

=head2 first_feature_id

=over

=item Usage

  $obj->first_feature_id()        #get existing value
  $obj->first_feature_id($newval) #set new value

=item Function

=item Returns

value of first_feature_id (a scalar), that is, the feature_id of the first
feature parsed in the current session.

=item Arguments

new value of first_feature_id (to set)

=back

=cut

sub first_feature_id {
    my $self = shift;
    my $first_feature_id = shift if defined(@_);
    return $self->{'first_feature_id'} = $first_feature_id if defined($first_feature_id);
    return $self->{'first_feature_id'};
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

    foreach my $table (@tables) {
      my $sth = $self->dbh->prepare("select nextval('$sequences{$table}')");
      $sth->execute;
      my ($nextoid) = $sth->fetchrow_array();
      $self->nextoid($table, $nextoid);
    }
    return;
}


=head2 update_sequences

=over

=item Usage

  $obj->update_sequences()

=item Function

Checks the maximum value of the primary key of the sequence's table
and modifies the nextval of the sequence if they are out of sync.
It then (re)initializes the sequence cache.

=item Returns

Nothing

=item Arguments

None

=back

=cut

sub update_sequences {
    my $self = shift;

    foreach my $table (@tables) {

      my $id_name      = $table."_id";
      my $max_id_query = "SELECT max($id_name) FROM $table";
      my $sth          = $self->dbh->prepare($max_id_query);
      $sth->execute;
      my ($max_id)     = $sth->fetchrow_array();
      
      my $curval_query = "SELECT nextval('$sequences{$table}')";
      $sth             = $self->dbh->prepare($curval_query);
      $sth->execute;
      my ($curval)     = $sth->fetchrow_array();      

      if ($max_id > $curval) {
          my $setval_query = "SELECT setval('$sequences{$table}',$max_id)";
          $sth             = $self->dbh->prepare($setval_query);
          $sth->execute;
      }

    }

    $self->initialize_sequences();
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

=head2 is_analysis

=over

=item Usage

  $obj->is_analysis()        #get existing value
  $obj->is_analysis($newval) #set new value

  dgg: renamed to flag field name to avoid confusion with analysis table
  
=item Function

=item Returns

value of is_analysis (a scalar)

=item Arguments

new value of is_analysis (to set)

=back

=cut

sub is_analysis {
    my $self = shift;
    my $is_analysis = shift if defined(@_);
    return $self->{'is_analysis'} = $is_analysis if defined($is_analysis);
    return $self->{'is_analysis'};
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

=head2 random_tmp_dir

=over

=item Usage

  $obj->random_tmp_dir()        #get existing value
  $obj->random_tmp_dir($newval) #set new value

=item Function

=item Returns

value of random_tmp_dir (a scalar)

=item Arguments

new value of random_tmp_dir (to set)

=back

=cut

sub random_tmp_dir {
    my $self = shift;
    my $random_tmp_dir = shift if defined(@_);
    return $self->{'random_tmp_dir'} = $random_tmp_dir if defined($random_tmp_dir);
    return $self->{'random_tmp_dir'};
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

=head2 private_schema

=over

=item Usage

  $obj->private_schema()        #get existing value
  $obj->private_schema($newval) #set new value

=item Function

Sets the value of private_schema, the name of the private schema to
insert data into.  If not set, the public schema will be used.

=item Returns

value of private_schema (a scalar)

=item Arguments

new value of private_schema (to set)

=back

=cut

sub private_schema {
    my $self = shift;
    my $private_schema = shift if defined(@_);
    return $self->{'private_schema'} = $private_schema if defined($private_schema);
    return $self->{'private_schema'};
}


=head2 use_public_cv

=over

=item Usage

  $obj->use_public_cv()        #get existing value
  $obj->use_public_cv($newval) #set new value

=item Function

When private_schema is set, this flag tells the loader to insert new
cv and cvterm data into the public schema instead of the private one.

=item Returns

value of use_public_cv (a scalar)

=item Arguments

new value of use_public_cv (to set)

=back

=cut

sub use_public_cv {
    my $self = shift;
    my $use_public_cv = shift if defined(@_);
    return $self->{'use_public_cv'} = $use_public_cv if defined($use_public_cv);
    return $self->{'use_public_cv'};
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
already in the cvterm and dbxref tables so that its value can be inserted
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

sub print_delete {
  my $self = shift;
  my $feature_id = shift;

  my $table = $self->private_schema 
            ? $self->private_schema . "._feature"
            : "feature";

  my $fh = $self->file_handles('delete');
  print $fh "DELETE FROM $table WHERE feature_id = $feature_id;\n";
  return;
}

sub print_seq {
  my $self = shift;
  my ($name,$string) = @_;
  my $dbh = $self->dbh;

  my $organism_id = $self->organism_id;

  my $uniquename = $self->modified_uniquename(orig_id=>$name, organism_id => $organism_id)
                 ? $self->modified_uniquename(orig_id=>$name, organism_id => $organism_id)
                 : $name;

  my $fid_query = "SELECT feature_id FROM tmp_gff_load_cache WHERE uniquename = ? AND organism_id = ? AND feature_id >= ?";
  my $sth = $dbh->prepare($fid_query);
  $sth->execute($uniquename,$organism_id,$self->first_feature_id); 
  
  if ($sth->rows == 0) {
    warn "No feature found for $uniquename, org_id:$organism_id when trying to add sequence";
    return;
  }
  elsif ($sth->rows > 1) {
    warn "More than one feature found for $uniquename, org_id:$organism_id when trying to add sequence";
    return;
  }
  my ($feature_id) = $sth->fetchrow_array;

  my $fh = $self->file_handles('sequence');
  print $fh "UPDATE feature set residues='$string' WHERE feature_id=$feature_id;\n";
  print $fh "UPDATE feature set seqlen=length(residues) WHERE feature_id=$feature_id;\n";

  return;
}

sub print_fasta {
  my $self = shift;
  my ($uniquename,$string) = @_;
  my $dbh = $self->dbh;
  my $organism_id = $self->organism_id;

  #assume that the fasta ID matches the uniquename (ie, no munging when it went into the database)
  my $fid_query = "SELECT feature_id FROM feature WHERE uniquename = ? AND organism_id = ?";
  my $sth = $dbh->prepare($fid_query);
  $sth->execute($uniquename,$organism_id);

  if ($sth->rows == 0) {
    warn <<END;
No features where found with a unqiuename of $uniquename
and an organism_id of $organism_id.  Are you sure you have the uniquename
right?  It might have been changed when loaded into the database to ensure
uniqueness.  Skipping this sequence...

END
    return;
  } 
  elsif ($sth->rows > 1) {
    warn "More than one feature found for $uniquename, org_id:$organism_id when trying to add sequence, skipping...\n\n";
    return;
  }

  my ($feature_id) = $sth->fetchrow_array;

  my $fh = $self->file_handles('sequence');
  print $fh "UPDATE feature set residues='$string' WHERE feature_id=$feature_id;\n";
  print $fh "UPDATE feature set seqlen=length(residues) WHERE feature_id=$feature_id;\n";

  return;
}

sub print_af {
  my $self = shift;
  my ($af_id,$f_id,$a_id,$score) = @_;

  my $fh = $self->file_handles('analysisfeature');
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

  my $fh = $self->file_handles('dbxref');
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


sub print_analysis {  # dgg
  my $self = shift;
  my ($an_id,$name,$program,$source) = @_;
  
  unless($name) { $name = ($source) ? "$program.$source" : $program; }   
  $source ||= '\N';
  my $progvers= 'null'; # not NULL, but no idea here? dup program? or 'null' ?
  my $fh = $self->file_handles('analysis');
  if ($self->inserts()) {
    my $q_name     = $self->dbh->quote($name);
    my $q_program  = $self->dbh->quote($program);
    my $q_progvers = $self->dbh->quote($progvers);
    my $q_source   = $source eq '\N' ? 'NULL' : $self->dbh->quote($source);
    print $fh "INSERT INTO analysis $copystring{'analysis'} VALUES ($an_id,$q_name,$q_program,$q_progvers,$q_source);\n";
  } else {
    print $fh join("\t",($an_id,$name,$program,$progvers,$source) ),"\n";
  }
}

sub print_organism {  # dgg
  my $self = shift;
  my ($orgid,$genus,$species,$common) = @_;
 
  my $table = $self->use_public_cv ? 'public.organism' : 'organism';
  
  $common ||= '\N';
  my $abbrev= substr($genus,0,1).'.'.$species;
  my $fh = $self->file_handles('organism');
  if ($self->inserts()) {
    my $q_genus    = $self->dbh->quote($genus);
    my $q_species  = $self->dbh->quote($species);
    my $q_abbrev   = $self->dbh->quote($abbrev);
    my $q_common   = $common eq '\N' ? 'NULL' : $self->dbh->quote($common);
    print $fh "INSERT INTO $table $copystring{'organism'} VALUES ($orgid,$q_genus,$q_species,$q_common,$q_abbrev);\n";
  } else {
    print $fh join("\t",($orgid,$genus,$species,$common,$abbrev) ),"\n";
  }
}


sub print_cvterm {  # dgg
  my $self = shift;
  my ($cvterm_id,$cv_id,$name,$dbxref_id,$definition) = @_;
 
  my $table = $self->use_public_cv ? 'public.cvterm' : 'cvterm';
 
  $definition ||= '\N';
  my $fh = $self->file_handles('cvterm');
  if ($self->inserts()) {
    my $q_acc  = $self->dbh->quote($name);
    my $q_desc = $definition eq '\N' ? 'NULL' : $self->dbh->quote($definition);
    print $fh "INSERT INTO $table $copystring{'cvterm'} VALUES ($cvterm_id,$cv_id,$q_acc,$dbxref_id,$q_desc);\n";
  } else {
    print $fh join("\t",($cvterm_id,$cv_id,$name,$dbxref_id,$definition)),"\n";
  }
}


sub print_cv {  # dgg
  my $self = shift;
  my ($cv_id,$name,$definition) = @_;
 
  my $table = $self->use_public_cv ? 'public.cv' : 'cv';
 
  $definition ||= '\N';
  my $fh = $self->file_handles('cv');
  if ($self->inserts()) {
    my $q_acc  = $self->dbh->quote($name);
    my $q_desc = $definition eq '\N' ? 'NULL' : $self->dbh->quote($definition);
    print $fh "INSERT INTO $table $copystring{'cv'} VALUES ($cv_id,$q_acc,$q_desc);\n";
  } else {
    print $fh join("\t",($cv_id,$name,$definition)),"\n";
  }
}

sub print_dbname {  # dgg
  my $self = shift;
  my ($db_id,$name,$description) = @_;
 
  my $table = $self->use_public_cv ? 'public.db' : 'db';
 
  $description ||= '\N';
  my $fh = $self->file_handles('db');
  if ($self->inserts()) {
    my $q_acc  = $self->dbh->quote($name);
    my $q_desc = $description eq '\N' ? 'NULL' : $self->dbh->quote($description);
    print $fh "INSERT INTO $table $copystring{'db'} VALUES ($db_id,$q_acc,$q_desc);\n";
  } else {
    print $fh join("\t",($db_id,$name,$description)),"\n";
  }
}

sub print_fs {
  my $self = shift;
  my ($fs_id,$s_id,$f_id,$p_id) = @_;

  my $fh = $self->file_handles('feature_synonym');
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

  my $fh = $self->file_handles('feature_dbxref');
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

  my $fh = $self->file_handles('feature_cvterm');
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

  my $fh = $self->file_handles('synonym');
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

  my $fh = $self->file_handles('featureloc');
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

  my $fh = $self->file_handles('featureprop');
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

  my $fh = $self->file_handles('feature_relationship');
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

  my $fh = $self->file_handles('feature');
  if ($self->inserts()) {
    my $q_name        = $self->dbh->quote($name);
    my $q_uniquename  = $self->dbh->quote($uniquename);
    my $q_seqlen      = $seqlen eq '\N' ? 'NULL' : $seqlen;
    my $q_analysis    = $self->is_analysis ? "'true'" : "'false'";
    $dbxref      ||= 'NULL';
    print $fh "INSERT INTO feature $copystring{'feature'} VALUES ($nextfeature,$organism,$q_name,$q_uniquename,$type,$q_analysis,$q_seqlen,$dbxref);\n";
  }
  else {
    $dbxref      ||= '\N';
    print $fh join("\t", ($self->nextfeature, $organism, $name, $uniquename, $type, $self->is_analysis,$seqlen,$dbxref)),"\n";
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

=head2 modified_uniquename

=over

=item Usage

  $obj->modified_uniquename(orig_id     => $id, 
                            modified_id => $new_id, 
                            organism_id => $organism_id)

=item Function

Keeps track of uniquenames that had to be modifed from their original
GFF3 ID so relationships in the GFF3 can be properly represented in Chado.

=item Returns

When called with all three pairs of args, nothing.  When called with one of
orig_id or modified_id args, return the value of the other arg.  For example,
when called with "orig_id => $id", the method would return $new_id.

=item Arguments

Two possible hash pairs: orig_id for the ID that was present in the GFF file
and modified_id for the uniquename that will be in Chado.  Additionally,
the organism_id hash pair must be supplied.

=back

=cut

sub modified_uniquename {
    my ($self, %argv) = @_;

    if (!defined $argv{'organism_id'}) {
        confess "organism_id must be supplied to the modified_uniquename method";
    }

    if (defined $argv{'orig_id'} && defined $argv{'modified_id'}) { #set

        #cluck "organism_id is: ",$argv{'organism_id'};

        $self->{'modified_uniquename'}->
                    {$argv{'organism_id'}}->
                         {'orig2mod'}->
                              {$argv{'orig_id'}} = $argv{'modified_id'};
        $self->{'modified_uniquename'}->
                    {$argv{'organism_id'}}->
                         {'mod2orig'}->
                              {$argv{'modified_id'}} = $argv{'orig_id'};
        return;
    }
    elsif (defined $argv{'orig_id'}) {
        return $self->{'modified_uniquename'}->{$argv{'organism_id'}}->{'orig2mod'}->{$argv{'orig_id'}}; 
    }
    elsif (defined $argv{'modified_id'}) {
        return $self->{'modified_uniquename'}->{$argv{'organism_id'}}->{'mod2orig'}->{$argv{'modified_id'}};
    }
    else {
        cluck"this shouldn't happen in modified_uniquename";
        return;
    }
}


sub dump_ana_contents {
  my $self = shift;
  my $anakey = shift;
  print STDERR "\n\nCouldn't find $anakey in analysis table\n";
  print STDERR "The current contents of the analysis table is:\n\n";

  #confess;

  my $sth
    = $self->dbh->prepare("SELECT analysis_id,name,program,sourcename FROM analysis");
  printf STDERR "%10s %25s %10s %10s\n\n",
    ('analysis_id','name','program','sourcename');

  $sth->execute;
  while (my $array_ref = $sth->fetchrow_arrayref) {
    printf STDERR "%10s %25s %10s %10s\n", @$array_ref;
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
        my $cv_table     = $self->use_public_cv ? "public.cv" : "cv";
        my $cvterm_table = $self->use_public_cv ? "public.cvterm" : "cvterm";
        my $sth
          = $self->dbh->prepare("SELECT cvterm_id FROM $cvterm_table WHERE 
              (name='synonym' and cv_id in 
                 (SELECT cv_id FROM $cv_table WHERE name='null' OR name='local')) OR
              (name='exact' and cv_id in 
                 (SELECT cv_id FROM $cv_table WHERE name='synonym_type') )
              ORDER BY name");
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
          $self->print_fs($self->nextoid('feature_synonym'),$synonym,$feature_id,$self->{const}{pub});

          $self->nextoid('feature_synonym','++'); #$nextfeaturesynonym++;
          $self->cache('synonym',$alias,$synonym);
        }

      } else {
        $self->print_syn($self->nextoid('synonym'),$alias,$self->cache('type','synonym'));

        unless ($self->{const}{pub}) {
          my $sth=$self->dbh->prepare("SELECT pub_id FROM pub WHERE miniref = 'null'");
            $sth->execute;
            my @row_array = $sth->fetchrow_array;
            $self->{const}{pub} = $row_array[0];
        }

        if( $self->constraint( name  => 'feature_synonym_c1',
                               terms => [ $feature_id , $self->nextoid('synonym') ] ) ) {
          $self->print_fs($self->nextoid('feature_synonym'),$self->nextoid('synonym'),$feature_id,$self->{const}{pub});
          $self->nextoid('feature_synonym','++'); #$nextfeaturesynonym++;
          $self->cache('synonym',$alias,$self->nextoid('synonym'));
          $self->nextoid('synonym','++'); #$nextsynonym++;
        }
      }

    } else {
      if ( $self->constraint( name => 'feature_synonym_c1',
                              terms=>  [ $feature_id ,
                                         $self->cache('synonym',$alias) ] ) ) {
        $self->print_fs($self->nextoid('feature_synonym'),$self->cache('synonym',$alias),$feature_id,$self->{const}{pub});
        $self->nextoid('feature_synonym','++'); #$nextfeaturesynonym++;
      }
    }
}


sub load_data {
  my $self = shift;

  if ($self->drop_indexes_flag()) {
    warn "Dropping indexes...\n";
    $self->drop_indexes();
  }

  my %nextvalue = $self->nextvalueHash();
#   (
#    "feature"              => $self->nextfeature,
#    "featureloc"           => $self->nextfeatureloc,
#    "feature_relationship" => $nextfeaturerel,
#    "featureprop"          => $nextfeatureprop,
#    "feature_cvterm"       => $nextfeaturecvterm,
#    "synonym"              => $nextsynonym,
#    "feature_synonym"      => $nextfeaturesynonym,
#    "feature_dbxref"       => $nextfeaturedbxref,
#    "dbxref"               => $nextdbxref,
#    "analysisfeature"      => $nextanalysisfeature,
#    "cvterm"               => $nextcvterm, #dgg
#    "db"               => $nextdbname, #dgg
#    "cv"               => $nextcvname, #dgg
#   );

  $self->file_handles('delete')->autoflush;
  if (-s $self->file_handles('delete')->filename > 0) {
      warn "Processing deletes ...\n";
      $self->load_deletes();
  }

  foreach my $table (@tables) {
    
    $self->file_handles($files{$table})->autoflush;
    if (-s $self->file_handles($files{$table})->filename <= 4) {
        warn "Skipping $table table since the load file is empty...\n";
        next;
    }

    my $l_table = $self->use_public_cv ? $use_public_tables{$table} : $table;

    $self->copy_from_stdin($l_table,
                    $copystring{$table},
                    $files{$table},      #file_handle name
                    $sequences{$table},
                    $nextvalue{$table});
  }

  ($self->dbh->commit() 
      || die "commit failed: ".$self->dbh->errstr()) unless $self->notransact;
  $self->dbh->{AutoCommit}=1;

  $self->load_reftype_property(); # dgg

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
    print STDERR "  ";
    foreach (@tables) {
      print STDERR "$_ ";
      $self->dbh->do("VACUUM ANALYZE $_");
    }
  }

  print STDERR "\nDone.\n";

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
      && $self->throw("FAILED: loading $file failed (error:$!); I can't go on");
  }
  else {

    my $query = "COPY $table $fields FROM STDIN;";
    #warn "\t".$query;
    $dbh->do($query) or $self->throw("Error when executing: $query: $!");

    while (<$fh>) {
      if ( ! ($dbh->pg_putline($_)) ) {
        #error, disconecting
        $dbh->pg_endcopy;
        $dbh->rollback;
        $dbh->disconnect;
        $self->throw("error while copying data's of file $file, line $.");
      } #putline returns 1 if succesful
    }
    $dbh->pg_endcopy or $self->throw("calling endcopy for $table failed: $!");

  }
  #update the sequence so that later inserts will work
  $dbh->do("SELECT setval('$sequence', $nextval) FROM $table")
    or $self->throw("Error when executing:  setval('$sequence', $nextval) FROM $table: $!"); 
}

sub load_sequence {
    my $self = shift;
    my $dbh  = $self->dbh();
    warn "Loading sequences (if any) ...\n";
    my $fh = $self->file_handles('sequence'); # 'SEQ'
    seek($fh,0,0);
    while (<$fh>) {
        chomp;
        $dbh->do($_);
    }
}

sub load_deletes {
    my $self = shift;
    my $dbh  = $self->dbh();
    my $fh = $self->file_handles('delete');
    seek($fh,0,0);
    while (<$fh>) {
        chomp;
        $dbh->do($_);
    }
}

=item add this to chado db for gbrowse reference class:

 insert into cvtermprop (cvterm_id,type_id,value) 
   values(ref_cvtermid,ref_cvtermid,'MapReferenceType');
  where ref_cvtermid = cvterm_id for reference type (e.g. chromosome,region,contig,...)
  my $query = "select cvterm_id from cvtermprop where value = ?";

  $value= Bio::DB::Das::Chado->MAP_REFERENCE_TYPE();
  
=cut

sub reftype_property {
    my $self = shift;
    my $reftype_property = shift;
    my $reftype_cvtermid = shift;
    # warn "Adding reftype_property=$reftype_property,$reftype_cvtermid\n"  if($reftype_property);
    $self->{'reftype_property'}= $reftype_property if($reftype_property);
    $self->{'reftype_cvtermid'}= $reftype_cvtermid if($reftype_cvtermid);
    return $self->{'reftype_property'};
}


sub load_reftype_property {
    my $self = shift;

    my $reftype = $self->reftype_property();  return unless($reftype);  
    warn "Adding cvtermprop=MapReferenceType for '$reftype' ...\n";
    my $ref_cvtermid = $self->{'reftype_cvtermid'};
    $ref_cvtermid = $self->get_type($reftype) unless($ref_cvtermid);  
    return unless($ref_cvtermid);
    my $maprefkey=""; 
    ##?? eval { "$maprefkey= Bio::DB::Das::Chado::MAP_REFERENCE_TYPE;" }; warn @$ if($@);
    $maprefkey ||= 'MapReferenceType';
    
    my $dbh = $self->dbh();
    my $sth = $dbh->prepare("SELECT value FROM cvtermprop where cvterm_id = ? and type_id = ?");
    $sth->execute($ref_cvtermid,$ref_cvtermid);
    my $data = $sth->fetchrow_hashref(); 
    return if $$data{'value'}; #??
    
    #? check we haven't already added this ...
    warn "Adding cvtermprop=$maprefkey to $reftype ...\n";
    $sth = $dbh->prepare("INSERT INTO cvtermprop (cvterm_id,type_id,value) VALUES (?,?,?)");
    $sth->execute($ref_cvtermid,$ref_cvtermid,$maprefkey) 
      or warn "Error when executing: INSERT INTO cvtermprop: $!\n";
}




sub handle_target {
    my $self = shift;
    my ($feature, $uniquename,$name,$featuretype,$type) = @_;

    my $organism_id = $self->organism_id;
    my @targets = $feature->annotation->get_Annotations('Target');
    my $rank = 1;
    foreach my $target (@targets) {
      my $target_id = $target->target_id;
      my $tstart    = $target->start -1; #convert to interbase
      my $tend      = $target->end;
      my $tstrand   = $target->strand ? $target->strand : '\N';
      my $tsource   = ref($feature->source) 
                        ? $feature->source->value : $feature->source;

      $self->synonyms($target_id,$self->cache('feature',$uniquename)) if (!$self->no_target_syn);

      my $created_target_feature = 0;

      #check for an existing feature with the Target's uniquename
      my $real_target_id = $self->modified_uniquename(orig_id => $target_id, organism_id => $organism_id) ?
                           $self->modified_uniquename(orig_id => $target_id, organism_id => $organism_id)
                         : $target_id;
      if ( $self->uniquename_cache(validate=>1,uniquename=>$real_target_id) ) {
          $self->print_floc(
                            $self->nextfeatureloc,
                            $self->nextfeature,
                            $self->uniquename_cache(validate=>1,uniquename=>$real_target_id),
                            $tstart, $tend, $tstrand, '\N',$rank,'0'
            );
      }
      else {
          $self->create_target_feature($name,$featuretype,$uniquename,$real_target_id,$type,$tstart,$tend,$tstrand,$rank);
          
          $created_target_feature = 1;
      }

      #print Dumper($feature);
      my $score = defined($feature->score) ? $feature->score : '\N';
      $score    = '.' eq $score                   ? '\N'                   : $score;

      my $featuretype = $feature->type->name;

      my $type = $self->cache('type',$featuretype);

#       my $ankey = $self->global_analysis ?
#                   $self->analysis_group :
#                   $tsource .'_'. $featuretype;
# 
#       unless($self->cache('analysis',$ankey)) {
#         $self->{queries}{search_analysis}->execute($ankey);
#         my ($ana) = $self->{queries}{search_analysis}->fetchrow_array;
#         $self->dump_ana_contents($ankey) unless $ana;
#         $self->cache('analysis',$ankey,$ana);
#       }

      my $ankey = $self->find_analysis($tsource,$featuretype); ## dgg patch, see note below
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

      $self->print_af($self->nextoid('analysisfeature'),
                      $self->nextfeature-$created_target_feature, #takes care of Allen's nextfeature bug--FINALLY!
                      $self->cache('analysis',$ankey),
                      $score_string);
      $self->nextoid('analysisfeature','++'); #$nextanalysisfeature++;
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



=item  analysis  comment

 d.gilbert, 07mar: data sourcename is important also for analysis use,
 see the table index: (program, programversion, sourcename)
 The 'name' field is not a unique value; see schema comments:
 Note only program and programversion are NOT NULL fields.
 
-- TABLE: analysis
-- name: can be NULL
--   a way of grouping analyses. this should be a handy
--   short identifier that can help people find an analysis they
--   want. for instance "tRNAscan", "cDNA", "FlyPep", "SwissProt"
--   it should not be assumed to be unique. for instance, there may
--   be lots of seperate analyses done against a cDNA database.
--
-- program: not NULL   (and programversion is NOT NULL...)
--   e.g. blastx, blastp, sim4, genscan
--
-- sourcename: can be NULL
--   e.g. cDNA, SwissProt

when analysis_group is not given, here are options for
finding from GFF source.  Using GFF.method is problematic
as any analysis can produce several method/type values (gene,CDS,exon; match, match_part, ...)

  1.  gff.source == an.program[:.-]an.sourcename -- this is flybase example an. usage
    e.g.   gff: chr4, BLASTx.insectEST, est_match, ...
                chrX, tBLASTn.yeastProtein, protein_match, ...
           chado.an:  program=tBLASTN, sourcename=yeastgenes
           
  2.  gff.source == an.program
            gff:  chr2, genscan, gene, ...
                  chr2, genscan, CDS, ...
        chado.an: program=genscan  programversion=2.0  or genscan 2.0, sourcename=NULL
  
Proposed changes: 
  ... original ...
   use constant SEARCH_ANALYSIS =>
               "SELECT analysis_id FROM analysis WHERE name=?";
    my $ankey = $self->global_analysis ?
                $self->analysis_group :
                $source .'_'. $featuretype; ## problem

    unless ($self->cache('analysis',$ankey)) {
      $self->{queries}{search_analysis}->execute($ankey);
      
  ... new , with option to auto-add analysis names to database

   use constant SEARCH_ANALYSIS =>
               "SELECT analysis_id FROM analysis 
                WHERE (name = ?) OR (program=? AND (sourcename=? OR sourcename is NULL))";

    my $ankey = $self->global_analysis ? $self->analysis_group : $source; 
    my ($anprog,$ansource)= split(/[:\.]/,$ankey,2);
    unless ($self->cache('analysis',$ankey)) {
      $self->{queries}{search_analysis}->execute($ankey,$anprog,$ansource);

=cut

sub find_analysis {
    my $self = shift;
    my ($source,$featuretype) = @_;

    my $ankey = $self->global_analysis ? $self->analysis_group : $source; 
    unless ($self->cache('analysis',$ankey)) {
      my ($anprog,$ansource)= split(/[:\.]/,$ankey,2); 
        # what is best split pattern? '_' is useful as name part
        ## GBrowse.conf problem using 'feature = type:prog:source'; 
        ## this affects also gff.source > ch.dbxref
        ## use/expect convention of 'program.dbsource' in gff.source line?
        
      $self->{queries}{search_analysis}->execute($ankey,$anprog,$ansource);
      my ($an_id) = $self->{queries}{search_analysis}->fetchrow_array;

      if($an_id) {
        $self->cache('analysis',$ankey,$an_id);
        
      } elsif ($self->{'addpropertycv'}) {   
        # create analysis entry
        $an_id= $self->nextoid('analysis');
        $self->print_analysis( $an_id, $ankey, $anprog, $ansource);
        $self->nextoid('analysis','++'); 
        $self->cache('analysis',$ankey,$an_id);
      }
    }
    return $ankey;
}


sub handle_nontarget_analysis {
    my $self = shift;
    my ($feature,$uniquename) = @_;
    my $source = ref($feature->source) 
                  ? $feature->source->value : $feature->source;
    my $score = $feature->score ? $feature->score : '\N';
    $score    = '.' eq $score   ? '\N'            : $score;

    my $featuretype = $feature->type->name;

#     my $ankey = $self->global_analysis ?
#                 $self->analysis_group :
#                 $source .'_'. $featuretype;
# 
#     unless ($self->cache('analysis',$ankey)) {
#       $self->{queries}{search_analysis}->execute($ankey);
#       my ($ana) = $self->{queries}{search_analysis}->fetchrow_array;
#       $self->dump_ana_contents($ankey) unless $ana;
#       $self->cache('analysis',$ankey,$ana);
#     }

    my $ankey = $self->find_analysis($source,$featuretype); ## dgg patch, see note 
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

    $self->print_af($self->nextoid('analysisfeature'),$self->cache('feature',$uniquename),$self->cache('analysis',$ankey),$score_string);
    $self->nextoid('analysisfeature','++'); #$nextanalysisfeature++;
}


sub handle_dbxref {
    my $self = shift;
    my ($feature,$uniquename) = @_;

    my @dbxrefs = $feature->annotation->get_Annotations('Dbxref');
    push @dbxrefs, $feature->annotation->get_Annotations('dbxref');
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
          $self->print_fdbx($self->nextoid('feature_dbxref'),
                            $self->cache('feature',$uniquename),
                            $dbxref_id);
          $self->nextoid('feature_dbxref','++'); #$nextfeaturedbxref++;
        }
      } else {
          unless ($self->cache('db',$database)) {
              $self->{queries}{search_db}->execute("$database");
              my($db_id) = $self->{queries}{search_db}->fetchrow_array;
              unless($db_id) { 
                ## dgg: this 'DB:' prefix on db names in chado is not desired
                $self->{queries}{search_db}->execute("DB:$database");
                ($db_id) = $self->{queries}{search_db}->fetchrow_array;
                }
              if(!$db_id && $self->{'addpropertycv'}) { # dgg: use same flag for add db names
                $db_id= $self->nextoid('db');# $nextdbname++;
                $self->print_dbname($db_id,$database,"autocreated:$database");
                $self->nextoid('db','++');
                }
              warn "couldn't find database '$database' in db table"
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
              $self->print_fdbx($self->nextoid('feature_dbxref'),  
                                $self->cache('feature',$uniquename),
                                $dbxref_id);
              $self->nextoid('feature_dbxref','++'); #$nextfeaturedbxref++;
            }
            $self->cache('dbxref',"$database|$accession|$version",$dbxref_id);
          } else {
            $dbxref_id = $self->nextoid('dbxref'); # $nextdbxref;
            if($self->constraint( name => 'feature_dbxref_c1',
                                  terms=> [ $self->cache('feature',$uniquename),
                                            $dbxref_id ] ) ){
              $self->print_fdbx($self->nextoid('feature_dbxref'),
                                $self->cache('feature',$uniquename),
                                $dbxref_id);
              $self->nextoid('feature_dbxref','++'); #$nextfeaturedbxref++;
            }
            $self->print_dbx($dbxref_id,
                             $self->cache('db',$database),
                             $accession,
                             $version,
                             $desc);
            $self->cache('dbxref',"$database|$accession|$version",$dbxref_id);
            $self->nextoid('dbxref','++'); ##$nextdbxref++;
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
      unless ($self->cache('type',$term)) { ## shouldnt this be cache('ontology',$term) ?? dgg
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
        $self->print_fcv($self->nextoid('feature_cvterm'),$self->cache('feature',$uniquename),$self->cache('type',$term),$self->{const}{pub});
        $self->nextoid('feature_cvterm','++'); # $nextfeaturecvterm++;
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
          $self->cache('dbxref',$source,$self->nextoid('dbxref'));
          $self->print_dbx($self->nextoid('dbxref'),$self->{const}{gff_source_db},$source,1,'\N');
          $self->nextoid('dbxref','++'); #$nextdbxref++;
        }
      }
      my $dbxref_id = $self->cache('dbxref',$source);
      if($self->constraint( name => 'feature_dbxref_c1',
                            terms=> [ $self->cache('feature',$uniquename),
                                      $dbxref_id ] ) ){
        $self->print_fdbx($self->nextoid('feature_dbxref'),$self->cache('feature',$uniquename),$dbxref_id);
        $self->nextoid('feature_dbxref','++'); # $nextfeaturedbxref++;
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

      unless ($self->{const}{fp_cv_id} || $self->{const}{tried_fp_cv}){
      
        $self->fp_cv("autocreated") unless($self->fp_cv());
      
        my $sth = $self->dbh->prepare("SELECT cv_id FROM cv WHERE name='". $self->fp_cv()  ."'");
          # dgg: dropped  'autocreated' due to SO/auto conflicts for things like 'gene', 'chromosome'
          #      where SO and autocreated cvs are used primarily for type names in Bio/DB/Das/Chado
        $sth->execute;
        ($self->{const}{fp_cv_id}) = $sth->fetchrow_array;
        if(!$self->{const}{fp_cv_id} && $self->{'addpropertycv'}) {
          # create cv entry
          $self->{const}{fp_cv_id}= $self->nextoid('cv');
          $self->print_cv( $self->{const}{fp_cv_id}, $self->fp_cv());
          $self->nextoid('cv','++'); 
        }
        
        $self->{const}{tried_fp_cv} = 1;
      }

#       if (!$self->{const}{tried_fp_cv} and !$self->{const}{fp_cv_id}) {
#         my $sth = $self->dbh->prepare("SELECT cv_id FROM cv WHERE name='". $self->fp_cv  ."'");
#         $sth->execute;
#         ($self->{const}{fp_cv_id}) = $sth->fetchrow_array;
#         $self->{const}{tried_fp_cv} = 1;
#       }

      ## problems here with auto-added properties that clash with SO/other cvterms; cache-type?
      my $property_cvterm_id = $self->cache('property',$tag);
      # $property_cvterm_id = $self->cache('type',$tag) unless($property_cvterm_id); ## dgg; drop this?
      unless ( $property_cvterm_id ) {
        #check fp cv first; ## dgg drop this due to conflicts with SO type:  autocreated
        ## my ($tag_cvterm); # ==  $property_cvterm_id
        if ($self->{const}{fp_cv_id}) {
          $self->{queries}{search_cvterm_id}->execute( 
                                $tag, 
                                $self->{const}{fp_cv_id}) ;
         ($property_cvterm_id) = $self->{queries}{search_cvterm_id}->fetchrow_array;
         }

        if ($property_cvterm_id) { #good, the term is already there
          $self->cache('property',$tag,$property_cvterm_id); 
        } else { #bad! the term is not there for now we die with a helpful message

## dgg patch
          if($self->{'addpropertycv'} && $self->{const}{fp_cv_id}) {
            $property_cvterm_id= $self->nextoid('cvterm'); # $nextcvterm++;
            my $dbxid= $self->nextoid('dbxref'); #$nextdbxref++;
            my $cvid = $self->{const}{fp_cv_id};
            my $dbxacc= "autocreated:$tag";

            ## bad to use  gff_source_db id; use 'null' db
            unless ($self->{const}{null_db}) {
              my $sth = $self->dbh->prepare("SELECT db_id FROM db WHERE name='null'");
              $sth->execute;
              ($self->{const}{null_db}) = $sth->fetchrow_array;
            }
        
            $self->print_dbx($dbxid,$self->{const}{null_db},$dbxacc,1,'\N');
            $self->nextoid('dbxref','++'); 
            $self->cache('dbxref',$dbxacc,$dbxid);
            $self->print_cvterm($property_cvterm_id, $cvid, $tag, $dbxid);
            $self->nextoid('cvterm','++'); 
            $self->cache('property',$tag,$property_cvterm_id);  
          
          } else {
          dbxref_error_message($tag) && die;
          }
        }
      }
      #moving on, add this to the featureprop table
      my @values = map {$_->value} $feature->annotation->get_Annotations($tag);
      my $rank=0;
      foreach my $value (@values) {
        if ( $self->constraint( name => 'featureprop_c1',
                              terms=> [ $self->cache('feature',$uniquename),
                                        $self->cache('property',$tag), 
                                        $rank ] ) ) {
        $self->print_fprop($self->nextoid('featureprop'),$self->cache('feature',$uniquename),$property_cvterm_id,$value,$rank);
        $rank++;
        $self->nextoid('featureprop','++'); # $nextfeatureprop++;
        }
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
                                                    name='local' OR
                                                    name='feature_property')");
          $sth->execute();
          my ($note_type) = $sth->fetchrow_array;
          if ($note_type) {
              $self->cache('type','Note',$note_type);
          }
          else {
              $self->throw("I couldn't find the 'Note' cvterm in the database;\nDid you load the feature property controlled vocabulary?");
          }
      }

      if ( $self->constraint( name => 'featureprop_c1',
                              terms=> [ $self->cache('feature',$uniquename),
                                        $self->cache('type','Note'), 
                                        $rank ] ) ) {
        $self->print_fprop($self->nextoid('featureprop'),$self->cache('feature',$uniquename),$self->cache('type','Note'),uri_unescape($note),$rank);
        $rank++;
        $self->nextoid('featureprop','++'); #$nextfeatureprop++;
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
                                                    name='local' OR
                                                    name='feature_property')");
          $sth->execute();
          my ($gap_type) = $sth->fetchrow_array; 
          $self->cache('type','Gap',$gap_type);
      }

      if ( $self->constraint( name => 'featureprop_c1',
                              terms=> [ $self->cache('feature',$uniquename),
                                        $self->cache('type','Gap'),
                                        $rank ] ) ) {
        $self->print_fprop($self->nextoid('featureprop'),$self->cache('feature',$uniquename),$self->cache('type','Gap') ,uri_unescape($note),$rank);
        $rank++;
        $self->nextoid('featureprop','++'); #$nextfeatureprop++;
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
If the feature's parents do not correspond to the central dogma
(that is, gene -> transcript -> cds), then the method will return
false and the CDS or UTR feature will be inserted as is into
the database.

=item Returns

False if the feature doesn't belong to a central dogma gene, 
otherwise nothing.

=item Arguments

A Bio::FeatureIO CDS or UTR object

=back

=cut

sub handle_CDS {
    my $self = shift;
    my $feat = shift;
    my $dbh  = $self->dbh;

    my $organism_id = $self->organism_id;

#    warn Dumper($feat);

    my $feat_id     = ($feat->annotation->get_Annotations('ID'))[0]->value
               if ($feat && defined(($feat->annotation->get_Annotations('ID'))[0]));
    my @feat_parents= map {$_->value} 
               $feat->annotation->get_Annotations('Parent')
               if ($feat && defined(($feat->annotation->get_Annotations('Parent'))[0]));

    #assume that an exon can have at most one grandparent (gene, operon)
    my $first_parent = $feat_parents[0];
    my $f_parent_uniquename 
            = $self->modified_uniquename(orig_id=>$first_parent, organism_id => $organism_id)
            ? $self->modified_uniquename(orig_id=>$first_parent, organism_id => $organism_id)
            : $first_parent;
    my $parent_id = $self->cache('feature',$f_parent_uniquename) if $f_parent_uniquename;

    unless ($parent_id) {
        warn "\n\nThere is a ".$feat->type->name
        ." feature with no parent (ID:$feat_id)  I think that is wrong!\n\n";
    }

    my $feat_grandparent = $self->cache('parent',$parent_id);

    return 0 unless $feat_grandparent;

    unless ($self->cds_db_exists()) {
        $self->create_cds_db;
    }

    my $fmin = $feat->start;              #check that this is interbase
    my $fmax = $feat->end;
    # my $object = safeFreeze $feat;  ## original; dgg;  was bad for argos perl lib; had real old FreezeThaw
    ## dgg this works, and doesnt need a new 3rd party perl module: 
    my $dumper = Data::Dumper->new ([[$feat]]);
    $dumper->Indent(0)->Terse(1)->Purity(1);
    my $object = $dumper->Dump;
    
    my $feat_type   = $feat->type->name; 
    ##$feat_type= $feat_type->value if(ref $feat_type);
    my $seq_id = $feat->seq_id;  ## this is a ref->value !!

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

    return 1;
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

#    $self->dbh->commit && die;
    return unless $self->cds_db_exists;

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

## dgg: Data::Dumper works and is easier on user (Data::Dumper part of sys perl lib) ##          
        ##my ($feat_obj)= thaw $$feat_row{ object }; # original
        my $objs = eval $$feat_row{ object }; if($@) { warn @$; }
        my $feat_obj = $$objs[0];

        my $type      = $$feat_row{ type };
        my $fmin      = $$feat_row{ fmin };
        my $fmax      = $$feat_row{ fmax };
        my @parents   = map {$_->value}
                              $feat_obj->annotation->get_Annotations('Parent');

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

                my $srcval= Bio::Annotation::SimpleValue->new(
                     ref($feat_obj->source) 
                         ? $feat_obj->source->value : $feat_obj->source);
                         
                $polyp->source( $srcval );

                my $polyp_ac = Bio::Annotation::Collection->new();
                $polyp_ac->add_Annotation( 'source', $srcval);

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
                      $feat_obj->seq_id));
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
                      $feat->seq_id));
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

    my $organism_id = $self->organism_id;

    for my $p_anot ( $feature->annotation->get_Annotations('Parent') ) {
        my $orig_pname  = $p_anot->value;
        my $pname = $self->modified_uniquename(orig_id => $orig_pname, organism_id => $organism_id)
                    ? $self->modified_uniquename(orig_id => $orig_pname, organism_id => $organism_id)
                    : $orig_pname;
        my $parent = $self->cache('feature',$pname);
        confess "\nno parent $orig_pname ($pname);\nyou probably need to rerun the loader with the --recreate_cache option\n\n" unless $parent;

        $self->cache('parent',$self->nextfeature,$parent);

        $self->print_frel($self->nextoid('feature_relationship'),$self->nextfeature,$parent,$part_of);

        $self->nextoid('feature_relationship','++'); # $nextfeaturerel++;
    }
}

sub handle_derives_from {
    my $self = shift;
    my ($feature) = @_;

    my $organism_id = $self->organism_id;

    for my $p_anot ( $feature->annotation->get_Annotations('Derives_from') ) {
        my $orig_pname  = $p_anot->value;
        my $pname = $self->modified_uniquename(orig_id => $orig_pname, organism_id => $organism_id)
                    ? $self->modified_uniquename(orig_id => $orig_pname, organism_id => $organism_id)
                    : $orig_pname; 
        my $parent = $self->cache('feature',$pname);
        confess "no parent ".$orig_pname unless $parent;

        $self->cache('parent',$self->nextfeature,$parent);

        $self->print_frel($self->nextoid('feature_relationship'),$self->nextfeature,$parent,$derives_from);
        $self->nextoid('feature_relationship','++'); #$nextfeaturerel++;
    }
}

sub handle_crud {
    my $self = shift;
    my $feature = shift;
    my $force_delete = shift;

    my ($op) = $feature->annotation->get_Annotations('CRUD');
    $op = $op->value if defined($op);
    if ($force_delete) {
        $op = 'delete-all';
    }

    my ($name) = $feature->annotation->get_Annotations('Name');

    if (!defined($name)) {
        #try to get the name from the ID
        ($name) = $feature->annotation->get_Annotations('ID');
        if (!defined($name)) {
        #if it doesn't have a name, don't do anything
        return 1;
        }
    }

    $name = $name->value if ref($name);
    my $type   = ref($feature->type) ? $feature->type->name : $feature->type;
    
    if ($op =~ /delete/) {
        #determine if a single feature corresponds to what is in the gff line
        #it is considered to be the same if the type, name (or synonym)
        #and organism are the same

        #this sql should be moved to the prepared sql hash after debugging is done
        my $sql = "SELECT feature_id FROM feature
                   WHERE name = ? and type_id = ? and organism_id = ?";
        my $delete_query_handle = $self->dbh->prepare($sql);
        $delete_query_handle->execute($name,
                                      $self->get_type($type),
                                      $self->organism_id);
        my $feature_id_arrayref = $delete_query_handle->fetchall_arrayref;

        my $feature_id;
        if (scalar @{$feature_id_arrayref} > 1 and $op ne 'delete-all') {
            $self->throw("I can't figure out which feature to delete that corresponds to a feature with a name of $name, a type of $type and organism of ".$self->organism.".  More than one feature match these criteria");
        }
        elsif (scalar @{$feature_id_arrayref} > 1) {
            warn "Deleting all features with name $name, type $type and organism ".$self->organism."\n";
            for my $id_row (@{$feature_id_arrayref}) {
                my $feature_id = $$id_row[0];
                $self->print_delete($$id_row[0]) if $feature_id;
            }
            return 1;
        }
        elsif (scalar @{$feature_id_arrayref} == 0) {
            warn "Couldn't fined a matching feature with name $name, type $type and organism ".$self->organism."\n";
            return 1;
#            warn("Searching for a feature with the name $name to delete yielded nothing; checking synonyms...");
#            $sql = "SELECT f.feature_id 
#                    FROM feature f, feature_synonym fs, synonym s
#                    WHERE s.name = ? and 
#                          s.synonym_id = fs.synonym_id and
#                          fs.feature_id = f.feature_id and
#                          f.type_id = ? and f.organism_id = ?"; 
#            my $delete_by_syn_query_handle = $self->dbh->prepare($sql);
#            $delete_by_syn_query_handle->execute($name,
#                                                 $self->get_type($type),
#                                                 $self->organism_id);
#            $feature_id_arrayref = $delete_by_syn_query_handle->fetchall_arrayref;
#            if (scalar @{$feature_id_arrayref} > 1) {
#                $self->throw("I couldn't figure out which feature to delete when searching by synonym $name; I found more than one matching feature");
#            } 
#            elsif (scalar @{$feature_id_arrayref} == 0) {
#                $self->throw("I couldn't find a matching feature using either feature.name or synonym.name of $name and a type of $type and organism of ".$self->organism.".  I can't go on... Bye.");
#            }
#            else { 
#                ($feature_id) = $$feature_id_arrayref[0];
#            }
        }
        else {
            $feature_id = $$feature_id_arrayref[0][0];
        }
        $self->print_delete($feature_id);
        return 1;
    }
    elsif ($op eq 'replace' or $op eq 'update') {
        $self->throw("The CRUD operation $op is not supported yet");
    }
    elsif ($op eq 'create') {
        return 0;  #nothing to do--create is the default
    }
    else {
        $self->throw("I don't know what to do for the CRUD operation $op");
    } 
}

sub src_second_chance {
    my $self = shift;
    my ($feature) = @_;

    my $organism_id = $self->organism_id;

    my $src;
    if($feature->seq_id eq '.'){
      $src = '\N';
    } else {

      #check to see if the uniquename had to be changed
      my $src_uniquename = 
             $self->modified_uniquename(orig_id => $feature->seq_id, organism_id => $organism_id) ?
             $self->modified_uniquename(orig_id => $feature->seq_id, organism_id => $organism_id)
           : $feature->seq_id;

      my ($temp_f_id)= $self->uniquename_cache(
                                        validate => 1,
                                        uniquename => $src_uniquename
                                              );
      $self->cache('feature',$src_uniquename,$temp_f_id);

      unless ($temp_f_id) {
        $self->{queries}{count_name}->execute($src_uniquename);
        my ($n_rows) = $self->{queries}{count_name}->fetchrow_array;
        if (1 < $n_rows) {
          $self->throw( "more that one source for ".$src_uniquename );
        } elsif ( 1==$n_rows) {
          $self->{queries}{search_name}->execute($src_uniquename);
          my ($tmp_source) = $self->{queries}{search_name}->fetchrow_array;
          $self->cache('feature',$src_uniquename,$tmp_source);
        } else {
          confess "Unable to find srcfeature "
               .$feature->seq_id
               ." in the database.\nPerhaps you need to rerun your data load with the '--recreate_cache' option.";
        }
      }
      $src = $self->cache('feature',$src_uniquename);
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

    $self->throw( "no cvterm for ".$featuretype );
}

sub get_src_seqlen {
    my $self = shift;
    my ($feature) = @_;

    my $organism_id = $self->organism_id;

    my ($src,$seqlen);
    if ( defined(($feature->annotation->get_Annotations('ID'))[0])
         && $feature->seq_id
            eq ($feature->annotation->get_Annotations('ID'))[0]->value ) {
        #this is a srcfeature (ie, a reference sequence)
      $src = $self->nextfeature;
      $seqlen = $feature->end - $feature->start +1;

      $self->cache('feature',$feature->seq_id,$src);
      $self->cache('srcfeature',$src,1);

    } else { # normal case
      my $src_uniquename 
                = $self->modified_uniquename(orig_id=>$feature->seq_id, organism_id => $organism_id) 
                ? $self->modified_uniquename(orig_id=>$feature->seq_id, organism_id => $organism_id)
                : $feature->seq_id;
      $src = $self->uniquename_cache(
                                        validate    => 1,
                                        organism_id => $organism_id,
                                        uniquename  => $src_uniquename
                                    );
#      $src = $self->cache('feature',$feature->seq_id);
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

    my $sth  = $dbh->prepare("SELECT distinct gffline FROM gff_sort_tmp WHERE refseq = id") or $self->throw();
    $sth->execute or $self->throw();

    my $result = $sth->fetchall_arrayref or $self->throw();

    my @to_return = map { $$_[0] } @$result; 
   
    return @to_return; 
}

sub sorter_get_no_parents {
    my $self = shift;
    my $dbh  = $self->dbh;

    my $sth  = $dbh->prepare("SELECT distinct gffline FROM gff_sort_tmp WHERE id is null and parent is null") or $self->throw(); 
    $sth->execute or $self->throw();
    
    my $result = $sth->fetchall_arrayref or $self->throw();

    my @to_return = map { $$_[0] } @$result;

    $sth  = $dbh->prepare("SELECT distinct gffline,id FROM gff_sort_tmp WHERE parent is null and refseq != id order by id") or $self->throw();
    $sth->execute or $self->throw();

    $result = $sth->fetchall_arrayref or $self->throw();

    push @to_return, map { $$_[0] } @$result;

    my %seen = ();
    my @uniq;
    for my $item (@to_return) {
        push(@uniq, $item) unless $seen{$item}++;
    }

    return @uniq;
}

sub sorter_get_second_tier {
    my $self = shift;
    my $dbh  = $self->dbh;

#ARGH! need to deal with multiple parents!

    my $sth  = $dbh->prepare("SELECT distinct gffline,parent,id FROM gff_sort_tmp WHERE parent in (SELECT id FROM gff_sort_tmp WHERE parent is null) order by parent,id") or $self->throw();
    $sth->execute or $self->throw();

    my $result = $sth->fetchall_arrayref or $self->throw();

    my %seen;
    my @to_return = grep { ! $seen{$_}++ }  
          map { $$_[0] } @$result;

    %seen = ();
    my @uniq;
    for my $item (@to_return) {
        push(@uniq, $item) unless $seen{$item}++;
    }

    return @uniq;
}

sub sorter_get_third_tier {
    my $self = shift;
    my $dbh  = $self->dbh;

#ARGH! need to deal with multiple parents!

    my $sth  = $dbh->prepare("SELECT distinct gffline,parent,id FROM gff_sort_tmp WHERE parent in (SELECT id FROM gff_sort_tmp WHERE parent in (SELECT id FROM gff_sort_tmp WHERE parent is null)) order by parent,id ") or $self->throw();
    $sth->execute or $self->throw();

    my $result = $sth->fetchall_arrayref or $self->throw();

    my %seen;
    my @to_return = grep { ! $seen{$_}++ } 
          map { $$_[0] } @$result;

    %seen = ();
    my @uniq;
    for my $item (@to_return) {
        push(@uniq, $item) unless $seen{$item}++;
    }

    return @uniq;
}

sub sorter_get_fourth_tier {
    my $self = shift;
    my $dbh  = $self->dbh;

#ARGH! need to deal with multiple parents!

    my $sth  = $dbh->prepare("SELECT distinct gffline,parent,id FROM gff_sort_tmp WHERE parent in (SELECT id FROM gff_sort_tmp WHERE parent in (SELECT id FROM gff_sort_tmp WHERE parent in (SELECT id FROM gff_sort_tmp WHERE parent is null))) order by parent,id ") or $self->throw();
    $sth->execute or $self->throw();

    my $result = $sth->fetchall_arrayref or $self->throw();

    my %seen;
    my @to_return = grep { ! $seen{$_}++ }
          map { $$_[0] } @$result;

    %seen = ();
    my @uniq;
    for my $item (@to_return) {
        push(@uniq, $item) unless $seen{$item}++;
    }

    return @uniq;
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
