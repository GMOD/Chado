use ExtUtils::MakeMaker;
# vim: set ft=perl ts=2 expandtab:
# $Id: Makefile.PL,v 1.133 2009-09-01 15:01:14 scottcain Exp $

$| = 1;
use constant INSTRUCTIONS => <<HERE

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
Makefile written.  Now you should do the following, in order:
  1. make              (creates necessary build files)
  2. sudo make install (creates \$GMOD_ROOT and subdirectories)
-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*WARNING-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
         STEP 3 WILL DELETE ANY DATA IN A DATABASE WITH THE 
            DATABASE NAME YOU PROVIDED!
-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*WARNING-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
  3. make load_schema (loads SQL schema into database)
  4. make prepdb      (loads basic data)
  5. make ontologies  (loads data for various ontologies)

Optional Targets:
  make rm_locks     (removes ontology lock files, allowing installation
                     of ontologies on successive builds of the database
                     without removing the ontology files altogether)
  make clean        (remove build related files and ontology tmp dir)
  make instructions (at any moment display these instructions)

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
HERE
;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

# questions to ask:
#  - what database server
#  - do you want to create Class::DBI stuff (which will be done now,
#      so that it can be put in lib/Class/DBI)
#

use strict;
use re 'taint';
use Config;
use Cwd;
use File::Copy;
use File::Spec::Functions qw[ catfile catdir ];
use Template;
use Module::Build;

my $VERSION = 1.2;

my %args    =  (
  DBDRIVER  => {
    default => 'PostgreSQL'
  },
  DBNAME    => {
    default => $ENV{'CHADO_DB_NAME'}
  },
  DBUSER    => {
    default => $ENV{'CHADO_DB_USERNAME'} || $ENV{'USER'}
  },
  DBPASS    => {
    default => $ENV{'CHADO_DB_PASSWORD'}
  },
  DBHOST    => {
    default => $ENV{'CHADO_DB_HOST'} || $ENV{'HOST'} ||
               scalar gethostent || 'localhost'
  },
  DBPORT    => {
    default => $ENV{'CHADO_DB_PORT'} || 5432
  },
  LOCAL_TMP => {
    default => './tmp'
  },
  DBORGANISM  => {
    default => ''
  },
  APOLLO    => {
    default => 'n'
  },
  DEFAULT   => {
    default => 'y'
  },
);

my %env2arg = (
  CHADO_DB_NAME      => 'DBNAME',
  CHADO_DB_USERNAME  => 'DBUSER',
  CHADO_DB_PASSWORD  => 'DBPASS',
  CHADO_DB_HOST      => 'DBHOST',
  CHADO_DB_PORT      => 'DBPORT',
  PREFIX             => 'PREFIX',
  INSTALLSITEMAN1DIR => 'INSTALLSITEMAN1DIR',
  INSTALLSITEMAN3DIR => 'INSTALLSITEMAN3DIR',
);

my $usage = <<"END";

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
                      CHADO INSTALLATION HELP
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

The arguments to this script should be set in your environment per
the instructions in the Chado INSTALL document.

To customize installation options, provide one or more of the options
(default values in parentheses):

DBDRIVER The RDBMS vendor ($args{'DBDRIVER'}{'default'})
DBNAME   The name of the Chado database ($args{'DBNAME'}{'default'})
DBUSER   The username to use when connecting to the database ($args{'DBUSER'}{'default'})
DBPASS   The password for connecting ($args{'DBPASS'}{'default'})
DBHOST   The machine name where the database is running ($args{'DBHOST'}{'default'})
DBPORT   The port on which the database is listening ($args{'DBPORT'}{'default'})

e.g., perl Makefile.PL DBDRIVER=PostgreSQL DBNAME=chado [...]

In addition to the "global" variables above, you can also specify LOCAL_TMP, 
which indicates where ontology files will be stored.  The default is
'./tmp'.

Optionally, if the file "build.conf" can be found from a previous run
of the Makefile.PL, you will be prompted to confirm the values saved 
in this file.  

If you wish to use the previous values without being prompted, then
provide the argument "RECONFIGURE=1."  

If you wish to disregard any values in "load.conf" and be prompted for
new arguments, provide the argument "RECONFIGURE=0."  

If you wish to use the defaults without being prompted, provide the 
argument "DEFAULTS=1."

You can also use PREFIX and LIB to install perl modules in nonstandard
locations as you would with a typical package install.  ALTHOUGH THERE
IS CURRENTLY A PROBLEM THAT DYNAMICALLY GENERATED SCRIPTS MAY NOT
GET REGENERATED ON SUBSEQUENT RUNNINGS OF perl Makefile.PL WITH
DIFFERENT VALUES OF LIB AND PREFIX.

END

#
# Establish some globals.
#
my $PERL         =  $Config{'startperl'};
$PERL            =~ s/^\s*#!\s*//;
my $working_dir  = cwd;
my $lib_dir      = catdir $working_dir, 'lib';
my $chado_dir    = catdir $lib_dir, 'Bio/Chado';
my $build_config = catfile $working_dir, 'build.conf';
my $load_config  = catfile $working_dir, 'load', 'etc', 'load.conf';

my $all_args = join( '|', qw[LIB RECONFIGURE DEFAULTS PREFIX INSTALLSITEMAN1DIR INSTALLSITEMAN3DIR INSTALL_BASE], keys %args );
my %env_required = map {$_=>1} qw(GMOD_ROOT CHADO_DB_NAME CHADO_DB_USERNAME); #CHADO_DB_PASSWORD is valid if undefined
my $all_envs = join( '|', keys %env_required );

my %O;
$O{GMOD_ROOT}    = $ENV{GMOD_ROOT} || catdir ( '', 'usr', 'local', 'gmod', );
$O{PACKAGE_HOME} = catfile $O{GMOD_ROOT}, 'lib', 'schema';
$O{COREDEF}      = catfile $working_dir, 'modules', 'idb-full.modules';
$O{EXTDEF}       = catfile $working_dir, 'modules', 'extension.modules';
$O{FUNCDEF}      = catfile $working_dir, 'modules', 'function.modules';

mkdir $lib_dir   unless -d $lib_dir;
mkdir $chado_dir unless -d $chado_dir;

#
# If the config file is there, parse it.
#
my %conf = ();
if ( -e $build_config && -r _ ) {
  open CONF, "<$build_config" or die "Can't read file '$build_config': $!\n";
  while ( <CONF> ) {
    chomp;
    next if /^\#/;
    if ( /^($all_args)=(.+)$/o ) {
      $conf{ $1 } = $2;
    }
  }
  close CONF;
}

#
# Parse arguments.
#
my %opts;
my @argv = @ARGV;
foreach ( @argv ) {
  if ( /^--?h(elp)?$/i ) {
    die $usage;
  }
  elsif ( /^($all_args)=(.+)$/ ) {
    $opts{ $1 } = $2;
  }
  elsif ( /^($all_envs)=(.+)$/ ) {
    $args{ $env2arg{$1} }{ default } = $2;
  }
}
@ARGV = ();
push @ARGV, "PREFIX=$opts{PREFIX}" if $opts{PREFIX};
push @ARGV, "INSTALL_BASE=$opts{INSTALL_BASE}" if $opts{INSTALL_BASE};
$O{'GMOD_ROOT'} = $opts{PREFIX} if $opts{PREFIX};
push @ARGV, "INSTALLSITEMAN1DIR=$opts{INSTALLSITEMAN1DIR}" if $opts{INSTALLSITEMAN1DIR};
push @ARGV, "INSTALLSITEMAN3DIR=$opts{INSTALLSITEMAN3DIR}" if $opts{INSTALLSITEMAN3DIR};
push @ARGV, "LIB=$opts{LIB}" if $opts{LIB};

#
# Check to see if the enviroment is there, mostly to make sure
# other apps can get what they need.
#
my @env_missing = ();
for my $key (keys %env_required) {
  push @env_missing, $key unless defined $ENV{ $key } or defined $args{$env2arg{$key}}{default} or defined $conf{$env2arg{$key}};
}
if ( @env_missing ) {
  die join("\n",
    '*' x 72,
    'The following enviroment variables not detected:',
    ( map { "  $_"} @env_missing ),
    'Please read the INSTALL document and set required environment variables.',
    '*' x 72,
    ''
  );
} 

my %VALID_DBS = (
  Pg => 'PostgreSQL',
  #Oracle => 'Oracle',
);
my %db_lookup = reverse %VALID_DBS;

#
# Now figure out where the values are coming from -- build.conf, 
# command-line, or prompt().
#
my ( $DBDRIVER, $DBNAME, $DBUSER, $DBPASS, $DBHOST, $DBPORT,
  $SQLFILES, $EXTERNAL_DDL, $LOCAL_TMP, $DBORGANISM, $APOLLO, $DEFAULT);

$O{'SIMPLE'} = prompt(
   "Use the simple install (uses default database schema, which contains\nall of the modules and extensions to the schema and all of the non-trigger functions.\nThis is probably what you want)", 'Y'
  );

if ( ! @argv && %conf ) {
  my $answer = prompt(
    "Previous configuration detected.\nUse values in '$build_config'?", 'Y'
  );

  $opts{'RECONFIGURE'} = $answer =~ /^[Yy]/ ? 1 : 0;
}

if ( $opts{'RECONFIGURE'} && %conf ) {
  $DBDRIVER = $VALID_DBS{ $conf{'DBDRIVER'} } || '';
  $DBNAME   = $conf{'DBNAME'}   || '';
  $DBUSER   = $conf{'DBUSER'}   || '';
  $DBPASS   = $conf{'DBPASS'}   || '';
  $DBHOST   = $conf{'DBHOST'}   || '';
  $DBPORT   = $conf{'DBPORT'}   || '';
  $LOCAL_TMP= $conf{'LOCAL_TMP'}|| '';
  $DBORGANISM=$conf{'DBORGANISM'}|| '';
  $APOLLO   = $conf{'APOLLP'}   || '';
  $DEFAULT  = $conf{'DEFAULT'}  || '';
}
elsif ( $opts{'DEFAULTS'} ) {
  $DBDRIVER = $args{'DBDRIVER'}{'default'};
  $DBNAME   = $args{'DBNAME'}{'default'};
  $DBUSER   = $args{'DBUSER'}{'default'};
  $DBPASS   = $args{'DBPASS'}{'default'};
  $DBHOST   = $args{'DBHOST'}{'default'};
  $DBPORT   = $args{'DBPORT'}{'default'};
  $LOCAL_TMP= $args{'LOCAL_TMP'}{'default'};
  $DBORGANISM=$args{'DBORGANISM'}{'default'};
  $APOLLO   = $args{'APOLLO'}{'default'};
  $DEFAULT  = $args{'DEFAULT'}{'default'};
}
elsif ( %opts ) {
  $DBDRIVER = $opts{'DBDRIVER'} || '';
  $DBNAME   = $opts{'DBNAME'}   || '';
  $DBUSER   = $opts{'DBUSER'}   || '';
  $DBPASS   = $opts{'DBPASS'}   || '';
  $DBHOST   = $opts{'DBHOST'}   || '';
  $DBPORT   = $opts{'DBPORT'}   || '';
  $LOCAL_TMP= $opts{'LOCAL_TMP'}|| '';
  $DBORGANISM=$opts{'DBORGANISM'}|| '';
  $APOLLO   = $opts{'APOLLO'}   || '';
  $DEFAULT  = $opts{'DEFAULT'}  || '';
}

if ( !$opts{'DEFAULTS'} && !$opts{'RECONFIGURE'} ) {
  #
  # Make sure everything has a value and looks kosher.
  #
  $DBDRIVER ||= prompt(
    'What database server will you be using?', 
    $VALID_DBS{ $conf{'DBDRIVER'} }
    ? $VALID_DBS{ $conf{'DBDRIVER'} }
    : $args{'DBDRIVER'}{'default'}
  );
  
  unless ( exists $db_lookup{ $DBDRIVER } ) {
    print join("\n",
      "Sorry, '$DBDRIVER' isn't valid. Please choose from the following:",
      ( map { "  $_" } sort values %VALID_DBS ),
      ''
    );
    exit;
  }
  
  $DBNAME ||= prompt( 'What is the Chado database name?', 
    $conf{'DBNAME'} || $args{'DBNAME'}{'default'}
  );
  
  $DBUSER ||= prompt( 'What is the database username?', 
    $conf{'DBUSER'} || $args{'DBUSER'}{'default'}
  );
  
  $DBPASS ||= prompt( "What is the password for '$DBUSER'?", 
    $conf{'DBPASS'} || $args{'DBPASS'}{'default'}
  );
  
  $DBHOST ||= prompt( 'What is the database host?', 
    $conf{'DBHOST'} || $args{'DBHOST'}{'default'}
  );
  
  $DBPORT ||= prompt( 'What is your database port?', 
    $conf{'DBPORT'} || $args{'DBPORT'}{'default'}
  );

  $LOCAL_TMP ||= prompt( 'Where shall downloaded ontologies go?',
    $conf{'LOCAL_TMP'} || $args{'LOCAL_TMP'}{'default'}
  );

  $DBORGANISM||=prompt('What is the default organism (common name, or "none")?',
    $conf{'DBORGANISM'} || $args{'DBORGANISM'}{'default'}
  );

  $DEFAULT ||=prompt('Do you want to make this the default chado instance?',
    $conf{'DEFAULT'} || $args{'DEFAULT'}{'default'}
  );

#  $APOLLO||=prompt('Create files to use Apollo with chado?'),
#    $conf{'APOLLO'} || $args{'APOLLO'}{'default'}
}

$DBORGANISM = '' if $DBORGANISM =~ /none/i;
#
# Now figure out which schema modules to include.
# or just go with the default
#

my @sqlfiles;
my $external;
my @funcfiles;
my $rebuild_complete = 0;
copy( 
     "$working_dir/modules/default_schema.sql", 
     "$working_dir/modules/complete.sql");
copy(
     "$working_dir/modules/default_nofuncs.sql",
     "$working_dir/modules/nofuncs.sql");

my $ant = 1;
if (-e "$working_dir/../GMODTools") {
    print "\nCopying GMODTools from its directory using its ant build.xml ...\n";

    chdir "$working_dir/../GMODTools";

    system("ant", "gmodrel", "-Dgmod.dir=$working_dir") == 0 or
        (warn "\n\n****************\nMoving tools from GMODTools directory faild; do you have ant installed?\n****************\n\n" && $ant = 0);
    print "Done with GMODTools\n";

    chdir $working_dir;
}

#
# Show the user the options (esp. if using RECONFIGURE or DEFAULTS).
#
print join("\n", 
  '', 
  'Building with the following database options:',
  "  GMOD_ROOT=$O{'GMOD_ROOT'}",
  "  DBDRIVER=$DBDRIVER",
  "  DBNAME=$DBNAME",
  "  DBUSER=$DBUSER",
  "  DBPASS=$DBPASS",
  "  DBHOST=$DBHOST",
  "  DBPORT=$DBPORT",
  "  LOCAL_TMP=$LOCAL_TMP",
  "  DBORGANISM=$DBORGANISM",
  "  DEFAULT=$DEFAULT",
  "  VERSION=$VERSION",
),"\n\n";

#
# Save build options.
#
if ( open CONF, ">$build_config" ) {
  $conf{'DBDRIVER'} = $db_lookup{ $DBDRIVER };
  $conf{'DBNAME'}   = $DBNAME;
  $conf{'DBUSER'}   = $DBUSER;
  $conf{'DBPASS'}   = $DBPASS;
  $conf{'DBHOST'}   = $DBHOST;
  $conf{'DBPORT'}   = $DBPORT;
  $conf{'LOCAL_TMP'}= $LOCAL_TMP;
  $conf{'DBORGANISM'}=$DBORGANISM;
  $conf{'PREFIX'}   = $opts{'PREFIX'};
  $conf{'LIB'}      = $opts{'LIB'};
  $conf{'DEFAULT'}  = $DEFAULT;
  $conf{'VERSION'}  = $VERSION;

  print CONF map { "$_=$conf{ $_ }\n" } keys %conf;
  close CONF or die "Can't write file '$build_config': $!\n";
}

#
# Write out new "load.conf" (backup if exists).
#
copy( $load_config, $load_config . '.old' ) if -e $load_config;
my $config_template = catfile( $working_dir, 'load', 'tt2', 'load.conf.tt2' );
if ( -e $config_template ) {
  my $t = Template->new( ABSOLUTE => 1 );
  $t->process( 
    $config_template, 
    {
      db_driver    => $db_lookup{ $DBDRIVER },
      db_name      => $DBNAME,
      db_username  => $DBUSER,
      db_password  => $DBPASS,
      db_host      => $DBHOST,
      db_port      => $DBPORT,
      db_organism  => $DBORGANISM, 
      local_tmp    => $LOCAL_TMP,
      working_dir  => $working_dir,
      external_ddl => $external,
      sql_files    => \@sqlfiles,
    }, 
    $load_config 
  ) or die $t->error;
}
else {
  warn "Template '$config_template' doesn't exist\n";
}

#create load/log/ if it doesn't exist already
if (! (-e 'load/logs') ) {
    mkdir ('load/logs', 0777) or die "unable to mkdir load/logs: $!\n";
}

my $complete_sql;
if ($O{'SIMPLE'} =~ /^[Yy]/) {
    system(  $PERL, 'bin/AutoDBI.PL') == 0
        or die "unable to run bin/AutoDBI.PL: $!\n";
}
else {

    print STDERR <<AUTODBI;

-------------------------WARNING------------------------------------
I'm assuming you modified modules/default_schema.sql and
modules/default_nofuncs.sql or want to rebuild AutoDBI.pm for some
other reason.  If that is not the case, please read INSTALL.Custom
for more information or, if you do not think this is what you want to
do, rerun `perl Makefile.PL` and answer 'y' to the question about
doing a simple install.

AUTODBI
;

    print "Creating Class::DBI classes in '$chado_dir'\n",
      "(This could take a while) ...\n"; 

    system(
      "$working_dir/bin/pg2cdbi_viaTT.pl '$DBNAME' '$DBUSER' '$DBPASS' " .
      "$working_dir/modules/nofuncs.sql > $working_dir/lib/Bio/Chado/AutoDBI.pm"
    ) == 0 or die "bin/pg2cdbi_viaTT.pl failed, is SQL::Translator installed?\n";
}

system( "$PERL load/Build.PL load_conf=$load_config; ./Build" ) == 0
    or die "unable to create Build from load/Build.PL: $!\n";

my @exe_files = (
           #'load/bin/gmod_load_affymetrix.pl',
           #'load/bin/gmod_load_affyxls.pl',
           #'load/bin/gmod_load_gff3.pl',
           'load/bin/gmod_bulk_load_gff3.pl',
           #'bin/gmod_dump_gff3.pl',
           'bin/gmod_apollo_triggers.pl',
           'bin/gmod_fasta2gff3.pl',
           'bin/gmod_sort_gff3.pl',
           'bin/gmod_materialized_view_tool.pl',
           'bin/gmod_extract_dbxref_from_gff.pl',
           'bin/gmod_gff3_preprocessor.pl',
           'bin/gmod_make_gff_from_dbxref.pl',
           'bin/gmod_load_cvterms.pl',
           'bin/gmod_bulk_load_pubmed.pl',
           'bin/gmod_make_cvtermpath.pl',
           'bin/gmod_add_organism.pl',
#           'bin/gmod_bulkfiles.pl',
#           'bin/gmod_gff2biomart5.pl',
);

if ($ant and -e "$working_dir/../GMODTools") {
    push @exe_files, 'bin/gmod_bulkfiles.pl', 'bin/gmod_gff2biomart5.pl';
}

WriteMakefile(
#      'INSTALLSITELIB' => '$(INSTALLSITEARCH)',
    'NAME'		            => 'chado',
#    'NAME'                => 'gmod',
    'VERSION'             => $VERSION,
    'PREREQ_PM'		        => { 
      #'SQL::Translator'   => 0.05,
      #'Class::DBI'        => 0.94,
      #'Class::DBI::Pager' => 0,
      #'Class::DBI::Pg'    => 0.02,
      'Module::Build'     => 0.20,
      'Template'          => 2.10,
      #'Term::ProgressBar' => 2.06, #fluff, but make sure you check load/bin/*
                                  #if this prereq is removed
      'DBI'               => 0,
      'DBD::Pg'           => 1.49,
      'XML::Simple'       => 2.09,
      'XML::Twig'         => 0,
      'Bio::Chado::Schema'=> 0,
      'DBIx::DBStag'      => 0.11,
      'GO::Parser'        => 0,
      'Module::Load'      => 0.16,
      'Bio::Root::Version'=> 1.006001,
      'LWP::Simple'       => 0,
      'IPC::Cmd'          => 0,
    }, 
    'PL_FILES'            => {
#          'load/bin/load_affymetrix.PLS' => 'load/bin/gmod_load_affymetrix.pl',
#          'load/bin/load_affyxls.PLS'    => 'load/bin/gmod_load_affyxls.pl',
#          'load/bin/load_gff3.PLS'       => 'load/bin/gmod_load_gff3.pl',
          'load/bin/bulk_load_gff3.PLS'       => 'load/bin/gmod_bulk_load_gff3.pl',
          'install_util/conf_install.PLS'    => 'install_util/conf_install.pl',
          'install_util/src_install.PLS'     => 'install_util/src_install.pl',
    },
    EXE_FILES             => \@exe_files,
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      ( # retrieve abstract from module
       AUTHOR     => 'Scott Cain <cain@cshl.edu>') : ()
    ),
    clean                 => {
      FILES               => 
        '$(DISTVNAME).tar$(SUFFIX) load/etc/load.conf build.conf ' .
        '_build Build lib/Bio/Chado/AutoDBI.pm '.$LOCAL_TMP  
    },
);

print INSTRUCTIONS;

#sub MY::clean {
#  package MY;
#  my $inherited = shift->SUPER::clean(@_);
#  $inherited =~ s/clean_subdirs/clean_subdirs rm_locks/;
#  $inherited;
#}

sub MY::install {
  package MY;
  my $inherited = shift->SUPER::install(@_);
  $inherited =~ s/doc_install/doc_install conf_install src_install/;
  $inherited;
}


#sub MY::install {
#  package MY;
#  my $inherited = shift->SUPER::install(@_);
#  $inherited =~ s/doc_install/doc_install song go cvtermpath/;
#  $inherited;
#}

sub MY::c_o {
  return ".SUFFIXES : .gz ";
}

# TODO: this should be rewritten to use the metadata xml
sub MY::postamble {
  my $root = "GMOD_ROOT=$O{GMOD_ROOT}";
  qq{
conf_install ::
	\$(PERL) \"$working_dir/install_util/conf_install.pl\" '$root'

src_install ::
	\$(PERL) \"$working_dir/install_util/src_install.pl\" '$root'

#cvtermpath ::
#	$working_dir/bin/make_cvtermpath.sh

images :: graphviz graphviz_svg diagram

instructions ::
	\@cat Makefile.PL | head -33 | tail -24

graphviz :: \
	make $working_dir/modules/companalysis/companalysis.graphviz.png \
	make $working_dir/modules/contact/contact.graphviz.png \
	make $working_dir/modules/cv/cv.graphviz.png \
	make $working_dir/modules/expression/expression.graphviz.png \
	make $working_dir/modules/general/general.graphviz.png \
	make $working_dir/modules/genetic/genetic.graphviz.png \
	make $working_dir/modules/phenotype/phenotype.graphviz.png \
	make $working_dir/modules/library/library.graphviz.png \
	make $working_dir/modules/cell_line/cell_line.graphviz.png \
	make $working_dir/modules/mage/mage.graphviz.png \
	make $working_dir/modules/map/map.graphviz.png \
	make $working_dir/modules/organism/organism.graphviz.png \
	make $working_dir/modules/phenotype/phenotype.graphviz.png \
	make $working_dir/modules/phylogeny/phylogeny.graphviz.png \
	make $working_dir/modules/pub/pub.graphviz.png \
	make $working_dir/modules/sequence/sequence.graphviz.png \
	make $working_dir/modules/www/www.graphviz.png \
	make $working_dir/modules/stock/stock.graphviz.png \
	make $working_dir/modules/project/project.graphviz.png \
	make $working_dir/modules/natural_diversity/natural_diversity.graphviz.png \
	make $working_dir/modules/nofuncs.graphviz.png

graphviz_svg :: \
	make $working_dir/modules/companalysis/companalysis.graphviz.svg \
	make $working_dir/modules/contact/contact.graphviz.svg \
	make $working_dir/modules/cv/cv.graphviz.svg \
	make $working_dir/modules/expression/expression.graphviz.svg \
	make $working_dir/modules/general/general.graphviz.svg \
	make $working_dir/modules/genetic/genetic.graphviz.svg \
	make $working_dir/modules/library/library.graphviz.svg \
	make $working_dir/modules/cell_line/cell_line.graphviz.svg \
	make $working_dir/modules/mage/mage.graphviz.svg \
	make $working_dir/modules/map/map.graphviz.svg \
	make $working_dir/modules/organism/organism.graphviz.svg \
	make $working_dir/modules/phenotype/phenotype.graphviz.svg \
	make $working_dir/modules/phylogeny/phylogeny.graphviz.svg \
	make $working_dir/modules/pub/pub.graphviz.svg \
	make $working_dir/modules/sequence/sequence.graphviz.svg \
	make $working_dir/modules/www/www.graphviz.svg \
	make $working_dir/modules/stock/stock.graphviz.svg \
	make $working_dir/modules/project/project.graphviz.svg \
	make $working_dir/modules/natural_diversity/natural_diversity.graphviz.svg \
	make $working_dir/modules/nofuncs.graphviz.svg

diagram :: \
	make $working_dir/modules/companalysis/companalysis.diagram.png \
	make $working_dir/modules/contact/contact.diagram.png \
	make $working_dir/modules/cv/cv.diagram.png \
	make $working_dir/modules/expression/expression.diagram.png \
	make $working_dir/modules/general/general.diagram.png \
	make $working_dir/modules/genetic/genetic.diagram.png \
	make $working_dir/modules/library/library.diagram.png \
	make $working_dir/modules/cell_line/cell_line.diagram.png \
	make $working_dir/modules/mage/mage.diagram.png \
	make $working_dir/modules/map/map.diagram.png \
	make $working_dir/modules/organism/organism.diagram.png \
	make $working_dir/modules/phenotype/phenotype.diagram.png \
	make $working_dir/modules/phylogeny/phylogeny.diagram.png \
	make $working_dir/modules/pub/pub.diagram.png \
	make $working_dir/modules/sequence/sequence.diagram.png \
	make $working_dir/modules/www/www.diagram.png \
	make $working_dir/modules/stock/stock.diagram.png \
	make $working_dir/modules/project/project.diagram.png \
	make $working_dir/modules/natural_diversity/natural_diversity.diagram.png \
	make $working_dir/modules/nofuncs.diagram.png


html :: \
	make $working_dir/modules/companalysis/companalysis.html \
	make $working_dir/modules/contact/contact.html \
	make $working_dir/modules/cv/cv.html \
	make $working_dir/modules/expression/expression.html \
	make $working_dir/modules/general/general.html \
	make $working_dir/modules/genetic/genetic.html \
	make $working_dir/modules/phenotype/phenotype.html \
	make $working_dir/modules/library/library.html \
	make $working_dir/modules/cell_line/cell_line.html \
	make $working_dir/modules/mage/mage.html \
	make $working_dir/modules/map/map.html \
	make $working_dir/modules/organism/organism.html \
	make $working_dir/modules/phenotype/phenotype.html \
	make $working_dir/modules/phylogeny/phylogeny.html \
	make $working_dir/modules/pub/pub.html \
	make $working_dir/modules/sequence/sequence.html \
	make $working_dir/modules/www/www.html \
	make $working_dir/modules/stock/stock.html \
	make $working_dir/modules/project/project.html \
	make $working_dir/modules/natural_diversity/natural_diversity.html \
	make $working_dir/modules/nofuncs.html

tex :: \
	make $working_dir/modules/companalysis/companalysis.tex \
	make $working_dir/modules/contact/contact.tex \
	make $working_dir/modules/cv/cv.tex \
	make $working_dir/modules/expression/expression.tex \
	make $working_dir/modules/general/general.tex \
	make $working_dir/modules/genetic/genetic.tex \
	make $working_dir/modules/phenotype/phenotype.tex \
	make $working_dir/modules/library/library.tex \
	make $working_dir/modules/cell_line/cell_line.tex \
	make $working_dir/modules/mage/mage.tex \
	make $working_dir/modules/map/map.tex \
	make $working_dir/modules/organism/organism.tex \
	make $working_dir/modules/phenotype/phenotype.tex \
	make $working_dir/modules/phylogeny/phylogeny.tex \
	make $working_dir/modules/pub/pub.tex \
	make $working_dir/modules/sequence/sequence.tex \
	make $working_dir/modules/www/www.tex \
	make $working_dir/modules/stock/stock.tex \
	make $working_dir/modules/project/project.tex \
	make $working_dir/modules/natural_diversity/natural_diversity.tex \
	make $working_dir/modules/nofuncs.tex

%.html: %.sql
	$working_dir/bin/pg2html.pl \$< > \$@

%.tex: %.sql
	sqlt --from PostgreSQL \$< --to Latex > \$@

%.graphviz.png: %.sql
	sqlt-graph -o \$@ --color --db PostgreSQL -l neato --skip-tables-like "^gencode"  \$<

%.graphviz.svg: %.sql
	sqlt-graph -o \$@ --color --db PostgreSQL -l neato --skip-tables-like "^gencode" -t svg \$<

%.diagram.png: %.sql
	$working_dir/bin/pg2diagram.pl \$< > \$@

metadata: $working_dir/bin/ddltrans
	cat \`find . -name \\*.sql -print\` > $working_dir/dat/chado.ddl
	$working_dir/bin/ddltrans -s chado -f dtd $working_dir/dat/chado.ddl > $working_dir/dat/chado.dtd
	$working_dir/bin/ddltrans -f html $working_dir/dat/chado.ddl > $working_dir/dat/chado.html
	$working_dir/bin/ddltrans -f perl $working_dir/dat/chado.ddl > $working_dir/dat/chado.pl
	$working_dir/bin/ddltrans -f xml $working_dir/dat/chado.ddl > $working_dir/dat/chado.xml

load_schema ::
	\$(SHELL) $working_dir/bin/test_load.sh $DBHOST $DBPORT $DBUSER $DBNAME

prepdb ::
	./Build prepdb

ontologies ::
	./Build ontologies

rm_locks ::
	`find $LOCAL_TMP -name "*$DBNAME" -exec rm -f '{}' ';'`

  };  
}
