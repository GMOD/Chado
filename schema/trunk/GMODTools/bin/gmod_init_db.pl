#!/usr/bin/perl

=head1 NAME

gmod_init_db.pl

=head1 SYNOPSIS

  A simple script to create the Chado database and tables
  based on test_load.pl.   d.gilbert added:
    parts to load in initialize.sql, 
    add new organisms, 
    add user choice of ontologies, which must exist in GMOD_ROOT/data/ontologies/

  Assumes that Chado::LoadDBI is available for ontologies

=head1 EXAMPLES

  bin/gmod_init_db.pl -dbname daphnia \
     -org='waterflea,Daphnia pulex' \
     -org='waterflea,Daphnia magna' \
     -org='waterflea,Daphnia pulicaria' \
     -ontology=obo_rel,song
     
    -- create database daphnia  & loads modules/complete.sql
    -- load install/initialize.sql (other folder?)
    -- add three new organisms
    -- loads all ontologies in subfolders of data/ontologies/ 
         (e.g., go, obo_rel, song)
  

  dghome2% bin/gmod_init_db.pl -dbname=daphnia -org='waterflea,Daphnia pulex' -ont=all 

  Argos::Config using ARGOS_SERVICE=GMOD at /bio/biodb/common/perl/lib/Argos/Config.pm line 55.
  A database called 'daphnia' already exists.
  OK to drop database 'daphnia'? [Y/n] 
  Dropping database 'daphnia'
  DROP DATABASE
  Creating new database called 'daphnia'
  CREATE DATABASE
  Creating tables
  psql:modules/complete.sql:1424: ERROR:  Type "gffatts" does not exist
  psql:modules/complete.sql:1510: ERROR:  language "plpgsql" does not exist
  Database 'daphnia' created

  Loading initial sql: install/initialize.sql
  ERROR:  Relation "array" does not exist
  ERROR:  Relation "array" does not exist
  ERROR:  Relation "array" does not exist
  ERROR:  Relation "array" does not exist

  insert into organism (abbreviation, genus, species, common_name) values('D.pulex','Daphnia','pulex','waterflea');
  INSERT 11965340 1

  Loading ontology: data/ontologies/go/component.ontology
  Loading ontology: data/ontologies/go/function.ontology
  Loading ontology: data/ontologies/go/process.ontology
  Loading ontology: data/ontologies/obo_rel/rel.ontology
  Loading ontology: data/ontologies/song/so.ontology

  Database 'daphnia' initialized.


=head1 init with location

  Will optionally store PostgresDB indices in project-specific location,
  given --location or ENV{DAPHNIA_PGDATA} (e.g. argos_service keys)
  
  dghome2% bin/gmod_init_db.pl -ont=obo_rel,song -org='waterflea,Daphnia pulex'

  Argos::Config using ARGOS_SERVICE=daphnia
  A database called 'daphnia' already exists.
  OK to drop database 'daphnia'? [Y/n] 
  Dropping database 'daphnia'
  DROP DATABASE
  Creating new database called 'daphnia'
  making database directory at /bio/biodb/daphnia/indices/pgsql
  The location will be initialized with username "gilbertd".
  This user will own all the files and must also own the server process.
  
  Creating directory /bio/biodb/daphnia/indices/pgsql
  Creating directory /bio/biodb/daphnia/indices/pgsql/base
  
  initlocation is complete.
  You can now create a database using
    CREATE DATABASE <name> WITH LOCATION = 'daphnia_LOCATION'
  in SQL, or
    createdb -D 'daphnia_LOCATION' <name>
  from the shell.
  
  ERROR:  Postmaster environment variable 'daphnia_LOCATION' not set
  createdb: database creation failed
  Cannot create database: 256 at bin/gmod_init_db.pl line 156, <STDIN> line 1.

=head1 SEE ALSO

  gmod_load_newseq.pl -- add miscellaneous organism sequences, cDNA, EST, 
     microsatellites, etc. not located on genome.  Optionally 
     generate PublicID for these.
     
  gmod_dump_seq.pl -- output sequences selected by organism, publication (input file),
     seq type.
     
  gmod_list_db.pl  -- show feature statistics for chado db: # per organism, per seq type,
    per publication/infile, and checksum test for sequence duplications.

=cut

use strict;

use Argos::Config;   # loads config to ENV; or eval { "require Argos::Config;" };
# use GMOD::Config; # simpler alternate, checks only conf/gmod.conf for ENV settings

use Getopt::Long;

## these may change; assume this is run from gmod/ folder

my $groot = $ENV{GMOD_ROOT} || '.';

my $initsql = "$groot/install/initialize.sql"; # load/ ?
my $completesql= "$groot/modules/complete.sql";
my $ontdir = "$groot/data/ontologies/"; 
my $loadont= "$groot/bin/gmod_load_ontology.pl";

my @ontology= (); # default to go, so, other ?
my @organism= ();
my $dbname = $ENV{CHADO_DB_NAME} || '';
my $locationKey= 'CHADO_PGDATA';
my $location= $ENV{$locationKey} || '';
my $template='';

our $DEBUG = 0 unless defined $DEBUG;

## argos config stuff: Argos::Config using ARGOS_SERVICE=GMOD
if ($ENV{'ARGOS_SERVICE'}) {
  $dbname= $ENV{'ARGOS_SERVICE'}; ## lc(); # leave case alone, here and in Argos::Config
  ## get this stuff from Argos::Config methods !
  my $root;  
  my $servkey = uc($dbname);
  $servkey =~ tr/A-Za-z0-9/_/c;
  $root = $ENV{$servkey."_ROOT"} || "$ENV{ARGOS_ROOT}/$dbname";
  # setenv FB_PGDATA /bio/biodb/flybase/indices/pgsql
  $locationKey= $servkey."_PGDATA";
  if ($ENV{$locationKey}) {
    $location=$ENV{$locationKey};
  } else {
    $location= "$root/indices/pgsql" ;
    ## this can be problem as restart of PG may not have ENV $locationKey path
    }
  }

my $ok= GetOptions(
  'dbname:s' => \$dbname, # required
  'location:s' => \$location,  
  'ontology:s' => \@ontology, 
  'organism:s' => \@organism,   
  'initsql:s' => \$initsql,
  'template:s' => \$template,  
  'debug!' => \$DEBUG,
  );

unless ($dbname && $ok) {
  die <<"HERE";
Usage:
  -dbname = $dbname      [required, database name to create]
  -location = $location      [optional, database storage location]
  -template = $template      [optional, database template]
  -ontology = go,song,.. [optional, or 'all', in folders in $ontdir]
  -initsql = $initsql    [optional, initializing sql]
  -organism = fruitfly,Drosophila melanogaster 
        [ optional: 'common,genus species', repeat -org=xxx as needed ]
HERE
  }
#  -organism = 'fruitfly' [optional; common name to add]

foreach (@ontology) {
  my @on= split /[,; ]/, $_;
  if (@on>1) { $_=''; push(@ontology,@on); }
  }
    
my $makedb= 1;
my %dbs;

my @list = `psql -l`;
if($?) {
  die "command 'psql -l' failed: @list\n Did you initialize Postgres and put psql on path?";
  }
  
my $ok = 0;
for my $line ( @list ) {
    ;
    if ( $line =~ m/^\s*Name\s*|\s*Owner\s*/ ) {
        $ok = 1;
        next;
    }
    elsif ( $ok ) {
        if ( $line =~ m/^\s*(\S+)\s*\|\s*\w+\s*/ ) {
            $dbs{ $1 } = 1;
        }
    }
}

if ( $dbs{ $dbname } ) {
    print "A database called '$dbname' already exists.\n";
    print "Do you want to DROP database '$dbname'? [yes/NO] ";
    chomp( my $answer = <STDIN> );
    if ( $answer =~ m/^[Yy]/ ) {
        print "Dropping database '$dbname'\n";
        system( "dropdb $dbname" ) == 0 or die "Cannot drop database: $?";
    }
    else {
        print "Will not drop database '$dbname'.  Skipping on to other data.\n";
        $makedb= 0; #exit(0);
    }
}

$ENV{'CHADO_DB_NAME'}= $dbname;  # for autoinit of LoadDBI in ontologies
$ENV{'DEBUG'}= $DEBUG;   
   # assume rest of chado_db info is in conf/gmod.conf

if ($makedb) {
  print "Creating new database called '$dbname'\n";
  if ($template) {
    if ($dbs{$template}) { 
      print "From template $template\n";
      $template= "--template=$template"; 
      }
    else { 
      print "Template database '$template' doesn't exist; skipping\n"; 
      $template=''; 
      }
    }
  
  my $loc='';
  if ($location) {
    unless($ENV{$locationKey} eq $location) {
      warn " Postgres location $locationKey is not set in environ.\n"
          ." Restarting Postgres server will need this:"
          ."   setenv $locationKey '$location'\n";
      $ENV{$locationKey}= $location; # this is what postgres wants
      }
    $loc= "--location $locationKey";
    unless (-d $location) {
      print "making database directory at $location\n";
      system("initlocation $locationKey") == 0 or die "Cannot initlocation $location: $?";

      ## need this for $ENV{$locationKey} - will need in run_postgres env also !
      ## $PGDATA=$ENV{'PGDATA'} << really should be set in ENV for pg restarts
      system("pg_ctl restart") == 0 or die "Restarting postgres failed: $?";
      }
    }
  
  system( "createdb $template $loc $dbname " ) == 0 or die "Cannot create database: $?";
#  createdb -D, --location=PATH       alternative place to store the database
#  ^^ use with argos dbs, loc = $root/$service/indices/pgsql/
  
  print "Creating tables\n";
  system( 
     "psql -f $completesql $dbname 2>&1 | egrep 'ERROR\|FATAL\|No such file or directory'"
  ) == 0 or die "Problem creating tables: $?";
  
  print "Database '$dbname' created\n";
}


if (-f $initsql) {
  print "Loading initial sql: $initsql\n";
  system(
    "psql -f $initsql $dbname 2>&1 | egrep 'ERROR\|FATAL\|No such file or directory'"
      ) == 0 or warn "Problem loading $initsql: $?";
  }

foreach my $organism (@organism) {
  #'H.sapiens', 'Homo','sapiens','human';
  if ($organism =~ m/([\w\s]+)\s*[,;\|]\s*(\w+)\s+(\w+)/) {
    my($com,$gen,$spp)=($1,$2,$3);
    my $sql="insert into organism (abbreviation, genus, species, common_name)";
    my $abbr= substr($gen,0,1).'.'.$spp;
    $sql .= " values('$abbr','$gen','$spp','$com');";
    $com= lc($com);
    print $sql,"\n";
    system( "psql -d $dbname -c \"$sql\"") == 0 or warn "Problem adding organism $organism: $?";
    }
  else {
    warn "Organism should be 'common_name,Genus species'; not $organism";
    }
}

if (grep /^all$/,@ontology) {
  if (opendir(D,$ontdir)) {
    @ontology= grep(/\w+/,readdir(D));
    closedir(D);
    }
}
foreach my $on (@ontology) { # go, song, ... allow 'all' for all folders in $ontdir
  my $ontd= $ontdir.$on;
  if (opendir(D,$ontd)) {
    my @onf= grep(/\.(ontology|def)/,readdir(D)); # need to match .def .defs .definition ...
    closedir(D);
    my ($def)= grep(/\.def/, @onf); #? just one per dir ?
    @onf= grep(/\.(ontology)$/, @onf);
    foreach my $onf (@onf) {
      print "Loading ontology: $ontd/$onf\n";
      system( "$loadont $ontd/$onf $ontd/$def" ) == 0 
        or warn "Problem loading ontology $ontd/$onf: $?";
      }
    }
}
  
print "Database '$dbname' initialized.\n";
exit(0);
