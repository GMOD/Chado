use ExtUtils::MakeMaker;
# vim: set ft=perl ts=2 expandtab:

# $Id: Makefile.PL,v 1.57 2004-03-26 18:34:35 scottcain Exp $

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
);

my %env2arg = (
  CHADO_DB_NAME     => 'DBNAME',
  CHADO_DB_USERNAME => 'DBUSER',
  CHADO_DB_PASSWORD => 'DBPASS',
  CHADO_DB_HOST     => 'DBHOST',
  CHADO_DB_PORT     => 'DBPORT',
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

END

#
# Establish some globals.
#
my $PERL         =  $Config{'startperl'};
$PERL            =~ s/^\s*#!\s*//;
my $working_dir  = cwd;
my $lib_dir      = catdir $working_dir, 'lib';
my $chado_dir    = catdir $lib_dir, 'Chado';
my $build_config = catfile $working_dir, 'build.conf';
my $load_config  = catfile $working_dir, 'load', 'etc', 'load.conf';

my $all_args = join( '|', qw[ RECONFIGURE DEFAULTS ], keys %args );
my %env_required = map {$_=>1} qw(GMOD_ROOT CHADO_DB_NAME CHADO_DB_USERNAME); #CHADO_DB_PASSWORD is valid if undefined
my $all_envs = join( '|', keys %env_required );

my %O;
$O{GMOD_ROOT}    = $ENV{GMOD_ROOT} || catdir qw[usr local gmod];
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
@ARGV    = (); # empty out @ARGV so MakeMaker doesn't get 
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
  $SQLFILES, $EXTERNAL_DDL, $LOCAL_TMP );

$O{'SIMPLE'} = prompt(
   "Use the simple install (uses default database schema)", 'Y'
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
}
elsif ( $opts{'DEFAULTS'} ) {
  $DBDRIVER = $args{'DBDRIVER'}{'default'};
  $DBNAME   = $args{'DBNAME'}{'default'};
  $DBUSER   = $args{'DBUSER'}{'default'};
  $DBPASS   = $args{'DBPASS'}{'default'};
  $DBHOST   = $args{'DBHOST'}{'default'};
  $DBPORT   = $args{'DBPORT'}{'default'};
  $LOCAL_TMP= $args{'LOCAL_TMP'}{'default'};
}
elsif ( %opts ) {
  $DBDRIVER = $opts{'DBDRIVER'} || '';
  $DBNAME   = $opts{'DBNAME'}   || '';
  $DBUSER   = $opts{'DBUSER'}   || '';
  $DBPASS   = $opts{'DBPASS'}   || '';
  $DBHOST   = $opts{'DBHOST'}   || '';
  $DBPORT   = $opts{'DBPORT'}   || '';
  $LOCAL_TMP= $opts{'LOCAL_TMP'}|| '';
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
}

#
# Now figure out which schema modules to include.
# or just go with the default
#

my @sqlfiles;
my $external;
my @funcfiles;
my $rebuild_complete = 0;
if ($O{'SIMPLE'} =~ /^[Yy]/) {
  system('cp', 
         "$working_dir/modules/default_schema.sql", 
         "$working_dir/modules/complete.sql");
} else{

  open CORE, $O{COREDEF} or die "Unable to read file '$O{COREDEF}': $!\n";
  while (<CORE>) {
    next if /^\s*#/; # allow comment lines
    chomp;
    my $file = $working_dir . '/modules/' . $_;
    if (-M "$working_dir/modules/complete.sql" > -M $file) {
      $rebuild_complete++;
    }
    push @sqlfiles, $file;
  }
  close CORE;

#
# Ask about available extensions to core.
#
  print "\nAvailable extensions to the core schema:\n";
  open EXT, $O{EXTDEF} or die "Unable to read file '$O{EXTDEF}': $!\n";
  my @extfiles = ( 0 );
  my $i = 0;
  while (<EXT>) {
    next if /^\s*#/; # allow comment lines
    $i++;
    print "[$i] $_";
    chomp;
    my $file = "$working_dir/modules/".$_;
    if (-M "$working_dir/modules/complete.sql" > -M $file) {
      $rebuild_complete++;
    }
    push @extfiles, $file;
  }
  close EXT;

  print "\nWhat extensions to the core schema would you like?\n",
    "(Note that selecting any of these will force the\n",
    "rebuilding of Class::DBI classes.)\n";
  my $extstr = prompt("(Comma-delimited)?","0");

  if ($extstr) {
    $rebuild_complete++; 
    my @extindex = split /,/, $extstr;
    foreach my $index (@extindex) {
      next unless defined $extfiles[$index];
      push @sqlfiles, $extfiles[$index];
    }
  }

  $external = prompt("Enter the full path of an external DDL file", 'none');
  unless ($external eq 'none') {
    if (-e $external) {
      push @sqlfiles, $external; 
    } else {
      die "The file $external couldn't be found.  Quitting...\n";
    }
  }

  print "\nAvailable function extensions to the core schema:\n";
  open EXT, $O{FUNCDEF} or die "Unable to read file '$O{FUNCDEF}': $!\n";
  @funcfiles = ( );
  my $i = 0;
  while (<EXT>) {
    next if /^\s*#/; # allow comment lines
    $i++;
    print "[$i] $_";
    chomp;
    my $file = "$working_dir/modules/".$_;
    push @funcfiles, $file;
  }
  close EXT;
                                                                                    
  print "\nWhat function extensions to the core schema would you like?\n";
  my $funcstr = prompt("(Comma-delimited)?","0");

} #closes the "nonsimple" unless option

#
# Show the user the options (esp. if using RECONFIGURE or DEFAULTS).
#
print join("\n", 
  '', 
  'Building with the following database options:',
  "  DBDRIVER=$DBDRIVER",
  "  DBNAME=$DBNAME",
  "  DBUSER=$DBUSER",
  "  DBPASS=$DBPASS",
  "  DBHOST=$DBHOST",
  "  DBPORT=$DBPORT",
  "  LOCAL_TMP=$LOCAL_TMP",
  '',
  $O{'SIMPLE'}!~ /^[Yy]/ ? 'And the following core modules and extensions:' : ''  , 
  $O{'SIMPLE'}!~ /^[Yy]/ ? ( map { "  $_" } @sqlfiles ) : '', 
  ''
);

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

my $complete_sql;
if ($O{'SIMPLE'} =~ /^[Yy]/) {
    system(  $PERL, 'bin/AutoDBI.PL');
    system( "$PERL load/Build.PL load_conf=$load_config; ./Build" );
}
else {

  $complete_sql = "$working_dir/modules/complete.sql";
  if ($rebuild_complete || !-e $complete_sql ) {
    open OUT, ">$complete_sql" or die "Couldn't write file '$complete_sql': $!\n";
    foreach my $file (@sqlfiles) {
      open IN, $file or die "Couldn't read file '$file': $!\n";
      while (<IN>) {
        print OUT;
      }
      close IN;
    }
    close OUT;

    print "Creating Class::DBI classes in '$chado_dir'\n",
      "(This could take a while) ...\n"; 

    system(
      "$working_dir/bin/pg2cdbi.pl '$DBNAME' '$DBUSER' '$DBPASS' " .
      "$working_dir/modules/complete.sql > $working_dir/lib/Chado/AutoDBI.pm"
    ) == 0 or die "bin/pg2cdbi.pl failed, is SQL::Translator installed?\n";

    system( "$PERL load/Build.PL load_conf=$load_config; ./Build" );
  }

  if (@funcfiles > 0) {
    open OUT, ">>$complete_sql" or die "Couldn't write file '$complete_sql': $!\n";
    foreach my $file (@funcfiles) {
      open IN, $file or die "Couldn't read file '$file': $!\n";
      while (<IN>) {
        print OUT;
      }
      close IN;
    }
    close OUT;
  }
} # close "not simple" else to make AutoDBI.pm

WriteMakefile(
    'NAME'		            => 'chado',
    'VERSION'             => 0.002,
    'PREREQ_PM'		        => { 
      #'SQL::Translator'   => 0.05,
      'Class::DBI'        => 0.94,
      'Class::DBI::Pager' => 0,
      'Class::DBI::Pg'    => 0.02,
      'Module::Build'     => 0.20,
      'Template'          => 2.10,
      'Term::ProgressBar' => 2.06, #fluff, but make sure you check load/bin/*
                                  #if this prereq is removed
      'DBI'               => 0,
      'DBD::Pg'           => 0,
      'XML::Simple'       => 2.09,
      'Log::Log4perl'     => 0.39,
    }, 
    'PL_FILES'            => {
          'load/bin/genbank2gff3.PLS'    => 'load/bin/gmod_genbank2gff3.pl',
#          'load/bin/load_affymetrix.PLS' => 'load/bin/gmod_load_affymetrix.pl',
#          'load/bin/load_affyxls.PLS'    => 'load/bin/gmod_load_affyxls.pl',
          'load/bin/load_gff3.PLS'       => 'load/bin/gmod_load_gff3.pl',
          'load/bin/load_ontology.PLS'   => 'load/bin/gmod_load_ontology.pl',
    },
    EXE_FILES             => [
           'load/bin/gmod_genbank2gff3.pl',
           #'load/bin/gmod_load_affymetrix.pl',
           #'load/bin/gmod_load_affyxls.pl',
           'load/bin/gmod_load_gff3.pl',
           'load/bin/gmod_load_ontology.pl'
    ],
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      ( # retrieve abstract from module
       AUTHOR     => 'Scott Cain <cain@cshl.org>') : ()
    ),
    clean                 => {
      FILES               => 
        '$(DISTVNAME).tar$(SUFFIX) load/etc/load.conf build.conf ' .
        '_build Build lib/Chado/AutoDBI.pm lib/Chado/LoadDBI.pm'  
    },
);

print <<HERE

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
Makefile written.  Now you should do the following, in order:

  1. make             (creates necessary build files)
  2. make load_schema (loads SQL schema into database)
                       NOTE: this will destroy any existing database
                         with the same name as the one you are creating
  3. make prepdb      (loads basic data)
  4. make ontologies  (loads data for various ontologies)

Optional Targets:

  make radviews    (creates views for gene expression data.  this is
                    necessary if you chose expression/rad.sql above)
  make images      (generates images of the schema in several formats)
  make rm_locks    (removes ontology lock files, allowing installation
                    of ontologies on successive builds of the database
                    without removing the ontology files altogether)

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

HERE
;

sub MY::clean {
  package MY;
  my $inherited = shift->SUPER::clean(@_);
  $inherited =~ s/clean_subdirs/clean_subdirs rm_locks/;
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

sub MY::postamble {
  qq{

cvtermpath ::
	$working_dir/bin/make_cvtermpath.sh

images :: graphviz graphviz_svg diagram

graphviz :: \
	make $working_dir/modules/companalysis/companalysis.graphviz.png \
	make $working_dir/modules/cv/cv.graphviz.png \
	make $working_dir/modules/expression/expression.graphviz.png \
	make $working_dir/modules/expression/rad.graphviz.png \
	make $working_dir/modules/general/general.graphviz.png \
	make $working_dir/modules/genetic/genetic.graphviz.png \
	make $working_dir/modules/map/map.graphviz.png \
	make $working_dir/modules/organism/organism.graphviz.png \
	make $working_dir/modules/pub/pub.graphviz.png \
	make $working_dir/modules/sequence/sequence.graphviz.png \
	make $working_dir/modules/pathway/pathway.graphviz.png \
	make $working_dir/modules/www/www.graphviz.png \
	make $working_dir/modules/complete.graphviz.png

graphviz_svg :: \
	make $working_dir/modules/companalysis/companalysis.graphviz.svg \
	make $working_dir/modules/cv/cv.graphviz.svg \
	make $working_dir/modules/expression/expression.graphviz.svg \
	make $working_dir/modules/expression/rad.graphviz.svg \
	make $working_dir/modules/general/general.graphviz.svg \
	make $working_dir/modules/genetic/genetic.graphviz.svg \
	make $working_dir/modules/map/map.graphviz.svg \
	make $working_dir/modules/organism/organism.graphviz.svg \
	make $working_dir/modules/pub/pub.graphviz.svg \
	make $working_dir/modules/sequence/sequence.graphviz.svg \
	make $working_dir/modules/pathway/pathway.graphviz.svg \
	make $working_dir/modules/www/www.graphviz.svg \
	make $working_dir/modules/complete.graphviz.svg

diagram :: \
	make $working_dir/modules/companalysis/companalysis.diagram.png \
	make $working_dir/modules/cv/cv.diagram.png \
	make $working_dir/modules/expression/expression.diagram.png \
	make $working_dir/modules/expression/rad.diagram.png \
	make $working_dir/modules/general/general.diagram.png \
	make $working_dir/modules/genetic/genetic.diagram.png \
	make $working_dir/modules/map/map.diagram.png \
	make $working_dir/modules/organism/organism.diagram.png \
	make $working_dir/modules/pub/pub.diagram.png \
	make $working_dir/modules/sequence/sequence.diagram.png \
	make $working_dir/modules/pathway/pathway.diagram.png \
	make $working_dir/modules/www/www.diagram.png \
	make $working_dir/modules/complete.diagram.png

%.graphviz.png: %.sql
	$working_dir/bin/pg2graphviz.pl \$< > \$@

%.graphviz.svg: %.sql
	$working_dir/bin/pg2graphviz_svg.pl \$< > \$@

%.diagram.png: %.sql
	$working_dir/bin/pg2diagram.pl \$< > \$@

metadata: $working_dir/bin/ddltrans
	cat \`find . -name \\*.sql -print\` > $working_dir/dat/chado.ddl
	$working_dir/bin/ddltrans -s chado -f dtd $working_dir/dat/chado.ddl > $working_dir/dat/chado.dtd
	$working_dir/bin/ddltrans -f html $working_dir/dat/chado.ddl > $working_dir/dat/chado.html
	$working_dir/bin/ddltrans -f perl $working_dir/dat/chado.ddl > $working_dir/dat/chado.pl
	$working_dir/bin/ddltrans -f xml $working_dir/dat/chado.ddl > $working_dir/dat/chado.xml

load_schema ::
	\$(SHELL) $working_dir/bin/test_load.sh $DBNAME

prepdb ::
	./Build prepdb

ontologies ::
	./Build ontologies

radviews ::
	./Build radviews

rm_locks ::
	`find $LOCAL_TMP -name "*_chado" -exec rm -f '{}' ';'`

  };  
}
