use strict;
use CASBuilder;
use GuessDirectories;
use File::Spec::Functions;
use Cwd;
use Bio::GMOD::Config;

eval { require Module::Build };
if ( $@ =~ /Can't locate/ ) {
    print qq[Please install "Module::Build" before continuing.\n];
    exit(0);
}

my $build = CASBuilder->new(
    module_name => 'cas-utils',
    license     => 'perl',
    dist_version_from => 'lib/Bio/GMOD/CAS/Util.pm',
    dist_abstract => 'A set of cgi scripts and config utilites for making the Apollo webstart/Chado roundtrip easier',
    dist_author => 'Scott Cain',
    requires    => {
                     'Bio::GMOD::DB::Config' => 0,
                     'CGI'                   => 0,
                     'Time::HiRes'           => 0,
                     'Config::General'       => 0,
                   }
);


#need to get htdocs, gmod_root (can get from Bio::GMOD::DB::Config
my @OPTION_LIST = qw[
  GMOD_ROOT
  CGIBIN
  CONF
  WEB_DOCUMENT_ROOT
  HTDOCS
  UPLOAD_DIR
  AUTOLOAD
  APOLLO_PATH
  VENDOR
  APOLLO_DESC
  PROJECT_HOME
  WEB_PATH
  HEADLESS_APOLLO
];

my @ARGS =  ( qw[ PREFIX ], @OPTION_LIST );
my %ARGS = (
    GMOD_ROOT => {
        desc    => 'Location that GMOD files are installed',
        default => catdir( '/', 'usr', 'local', 'gmod' ),
    },
    UPLOAD_DIR => {
        desc    => 'Location for uploaded XML files',
        default => catdir( 'apollo' ),
    },
    PREFIX => {
        desc    => 'A directory prefix for web-related install arguments',
        default => catdir( '/', 'usr', 'local', 'apache' ),
    },
    CONF => {
        desc    => 'Location for the cas.conf configuration file',
        default => '',
    },
    CGIBIN => {
        desc    => 'Location for CGI executables',
        default => 'cgi-bin',
    },
    WEB_DOCUMENT_ROOT => {
        desc    => 'Location of web document root',
        default => catdir('htdocs'),
    },
    HTDOCS => {
        desc    => 'Location of XML files generated for download',
        default => catdir('apollo', 'tmp'),
    },
    AUTOLOAD => {
        desc    => 'Should uploaded XML files be automatically loaded?',
        default => 0,
    },
    APOLLO_PATH => {
        desc    => 'The path to the installed version of Apollo',
        default => '/usr/bin/apollo',
    },
    VENDOR => {
        desc    => 'The description of your organization',
        default => 'Our org',
    },
    APOLLO_DESC => {
        desc    => 'Description for Apollo webstart',
        default => 'Our Apollo Webstart',
    },
    PROJECT_HOME => {
        desc    => 'The projects home page (eg, http://www.wormbase.org/)',
        default => 'http://localhost/',
    },
    WEB_PATH => {
        desc    => 'The path part of the uRL that is where the downloadable xml files will go',
        default => 'apollo/tmp',
    },
    HEADLESS_APOLLO => {
        desc    => 'The path to the Apollo binary that has been modified to run "headless"',
        default => '/usr/bin/apollo.headless',
    },
);

my $OPTIONS = join( '|', @ARGS );
my %OPTIONS;

my $USAGE = join(
    "\n",
    'To customize install locations, provide one or more of the options ',
    '',
    join(
        "\n",
        map {
            sprintf(
                "%18s: %-s\n\t\t(default: %s%s)\n",
                $_,
                $ARGS{$_}{'desc'},
                $_ eq 'PREFIX' ? ''
                : ( $_ eq 'GMOD_ROOT' ) ? ''
                : ( $_ eq 'VENDOR'    ) ? ''
                : ( $_ eq 'APOLLO_DESC')? ''
                : ( $_ eq 'PROJECT_HOME')?''
                : ( $_ eq 'HEADLESS_APOLLO')?''
                : ( $_ eq 'WEB_PATH')   ? ''
                : ( $_ eq 'AUTOLOAD' ) ? ''
                : ( $_ eq 'APOLLO_PATH' ) ? ''
                : ( $_ eq 'HTDOCS' ) ? '$PREFIX + $WEB_DOCUMENT_ROOT + '
                : ( $_ eq 'CONF' )   ? '$GMOD_ROOT + conf/'
                : ( $_ eq 'UPLOAD_DIR' ) ? '$GMOD_ROOT + tmp/'
                : '$PREFIX + ',
                $ARGS{$_}{'default'}
              )
          } @ARGS
    ),
    "e.g., 'perl Build.PL PREFIX=/usr/local/apache'",
    '',
    ''
);

# Process command-line args.
# #
my @argv = @ARGV;
foreach (@argv) {
    print STDERR "$OPTIONS \n$_\n";
    if (/^--?h(elp)?/i) {
        print $USAGE;
        exit(0);
    }
    elsif (/($OPTIONS)=(.+)/og) {
        $OPTIONS{$1} = $2;
    }
    else {
        warn "Ignoring unknown option '$_'\n";
        push @ARGV, $_;
    }
}

#
# See if previous config options exist.
#
my $install_conf = catfile( cwd(), 'cas_install.conf' );
my $using_install_conf = 0;
if ( !%OPTIONS ) {
    if ( -e $install_conf ) {
        my $yes = Module::Build->y_n(
            "It looks like you have installed cas before.\n"
              . "Should I use the settings in '"
              . $install_conf . "'?",
            'y'
        );

        if ($yes) {
            print "Using previous settings from '$install_conf.'\n";
            open F, $install_conf or die "Can't read '$install_conf: $!\n";
            while (<F>) {
                chomp;
                next if /^#/;
                next unless /^($OPTIONS)=(.+)/o;
                $OPTIONS{$1} = $2;
            }
            close F;
            $using_install_conf = 1;
        }
    }
    else {
        print "No arguments to Build.PL.  Using defaults.\n",
          "Execute 'perl Build.PL --help' for help.\n";
    }
}

unless ($using_install_conf) {

    # Make sure we have usable options.
    my $prefix = $OPTIONS{'PREFIX'};

    if ($prefix) {
        $OPTIONS{'WEB_DOCUMENT_ROOT'} ||=
             catdir( $prefix, $ARGS{'WEB_DOCUMENT_ROOT'}{'default'} );
        $OPTIONS{'CGIBIN'} ||= catdir( $prefix, $ARGS{'CGIBIN'}{'default'} );
    }

    $OPTIONS{'GMOD_ROOT'} ||= $ENV{GMOD_ROOT} || GuessDirectories->gmod_root
        || ask_about_dir ("\nCannot guess the correct GMOD_ROOT directory.\n"
            . "Please specify the GMOD_ROOT directory or hit enter to quit.\n");
    my $gmod_conf = Bio::GMOD::Config->new($OPTIONS{'GMOD_ROOT'});
    

    $OPTIONS{'CONF'} ||= catdir($gmod_conf->confdir, $ARGS{'CONF'}{'default'} )
        || GuessDirectories->conf()
        || ask_about_dir( "\nCannot guess the correct CONF directory.\n"
            . "Please specify the CONF directory or hit enter to quit.\n" );
    $OPTIONS{'CGIBIN'} ||= GuessDirectories->cgibin()
        || ask_about_dir( "\nCannot guess the correct CGIBIN directory.\n"
            . "If using Ubuntu, you may need to create "
            . "the /usr/lib/cgi-bin/ directory.\n"
            . "Please enter the CGIBIN directory or hit enter to quit.\n" );
    $OPTIONS{'WEB_DOCUMENT_ROOT'} ||= GuessDirectories->web_document_root()
        || ask_about_dir(
              "\nCannot guess the correct WEB_DOCUMENT_ROOT directory.\n"
            . "Please specify the WEB_DOCUMENT_ROOT directory or hit enter to quit.\n"
        );
    $OPTIONS{'AUTOLOAD'} ||= $build->prompt(
              "\nShould the CAS automatically load XML files that have been uploaded?\n" 
            . "Enter 1 for yes, 0 for no",
              $ARGS{'AUTOLOAD'}{'default'}
        );
    $OPTIONS{'APOLLO_PATH'} ||= $build->prompt(
              "\nPlease specify the path to the installed version of Apollo.\n",
              $ARGS{'APOLLO_PATH'}{'default'}
        );
    $OPTIONS{'HEADLESS_APOLLO'} ||= $OPTIONS{'APOLLO_PATH'} . ".headless";

    $OPTIONS{'VENDOR'} ||= $build->prompt(
              "\nPlease specify the name of your organization",
              $ARGS{'VENDOR'}{'default'}

        );
    $OPTIONS{'APOLLO_DESC'} ||= $build->prompt(
              "\nPlease specify the description line for Apollo Webstart",
              $ARGS{'APOLLO_DESC'}{'default'}
        );
    $OPTIONS{'PROJECT_HOME'} ||= $build->prompt(
              "\nPlease give your project's homepage",
              $ARGS{'PROJECT_HOME'}{'default'}
        );


    $OPTIONS{'HTDOCS'} ||=
      catdir( $OPTIONS{'WEB_DOCUMENT_ROOT'}, $ARGS{'HTDOCS'}{'default'} );
    $OPTIONS{'WEB_PATH'} ||= $ARGS{'HTDOCS'}{'default'};
    $OPTIONS{'UPLOAD_DIR'} ||= 
      catdir( $gmod_conf->tmpdir, $ARGS{'UPLOAD_DIR'}{'default'});

    print "The following install options have been inferred:\n",
      join( "\n",
        '', ( map { sprintf( "%18s: %-s", $_, $OPTIONS{$_} ) } @OPTION_LIST ),
        '', '' ),
      ;

    # Let the user define them if they need to.
    my $use_values = Module::Build->y_n( "Use these values?", 'y' );
    if ( !$use_values ) {
        foreach
            my $opt ( 'CONF', 'CGIBIN', 'WEB_DOCUMENT_ROOT', 'UPLOAD_DIR' )
        {
            $OPTIONS{$opt} = Module::Build->prompt(
                "$opt: "
                    . $ARGS{$opt}->{'desc'} . "\n"
                    . "What should the value of $opt be?\n",
                $OPTIONS{$opt},
            );
        }
    }
}

print "The following options will be used to install CAS:\n",
  join( "\n",
    '', ( map { sprintf( "%18s: %-s", $_, $OPTIONS{$_} ) } @OPTION_LIST ),
    '', '' ),
  ;

# Write out our current config options.
open F, ">$install_conf" or warn "Can't write '$install_conf': $!\n";
print F "$_=$OPTIONS{$_}\n" for @OPTION_LIST;
close F;

$build->notes( $_, $OPTIONS{$_} ) for @OPTION_LIST;

$build->create_build_script;

print "Now run './Build' and './Build install'\n";


sub ask_about_dir {
    my $prompt = shift;
    while (1) {
        my $answer = Module::Build->prompt( $prompt . "\n", 'quit', );
        exit(0) if ( $answer =~ /^q$/i or $answer =~ /^quit$/i );
        return $answer if ( -d $answer );
        print "\n$answer is not a directory.\n";
    }
}

