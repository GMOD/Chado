use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

# questions to ask:
#  - what database server
#  - do you want to create Class::DBI stuff (which will be done now,
#      so that it can be put in lib/Class/DBI)
#

use Cwd;

my $working_dir = cwd;
#$working_dir .= '/';

unless( -d "$working_dir/lib" ) { mkdir "$working_dir/lib" }
unless( -d "$working_dir/lib/Chado" ) { mkdir "$working_dir/lib/Chado" }

my %O;

#hard code these for the moment for testing
my $DBNAME         = "";
my $DBUSER         = "";
my $DBPASS         = "";
$O{GMOD_HOME}      = $ENV{GMOD_HOME} || '/usr/local/gmod';
$O{PACKAGE_HOME}   = $O{GMOD_HOME}.'/lib/schema';
$O{COREDEF}        = "$working_dir/modules/idb-full.modules";
$O{EXTDEF}         = "$working_dir/modules/extension.modules";

my $rebuild_complete = 0;
open CORE, $O{COREDEF} or die "unable to open $O{COREDEF}: $!\n";
my @sqlfiles;
while (<CORE>) {
  chomp;
  my $file = $working_dir . '/modules/' . $_;
  if (-M "$working_dir/modules/complete.sql" > -M $file) {
    $rebuild_complete++;
  }
  push @sqlfiles, $file;
}
close CORE;

#what server? (Assume Pg for now)
my $db = prompt("What database server will you be using?",'PostgreSQL');
die "Really only PostgreSQL is well supported right now" unless $db =~ /^[Pp]/;
$DBNAME = prompt("Database name?", 'chado');
$DBUSER = prompt("What is your username?", $ENV{USER});
$DBPASS = prompt("What is your password?", '');

# get available extensions to core and ask if any are to be used.
print "\nAvailable extensions to the core schema:\n";
open EXT, $O{EXTDEF} or die "unable to open $O{EXTDEF}: $!\n";
my @extfiles = ( 0 );
my $i = 0;
while (<EXT>) {
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

print "\nWhat extensions to the core schema do you need (Note that selecting any\n";
print "of these will force the rebuilding of Class::DBI classes.)\n";
my $extstr = prompt("(Comma delimited)?","0");

if ($extstr) {
  $rebuild_complete++; 
  my @extindex = split /,/, $extstr;
  foreach my $index (@extindex) {
    push @sqlfiles, $extfiles[$index];
  }
}

if ($rebuild_complete) {
  my $sqlout = "$working_dir/modules/complete.sql";
  open OUT, ">$sqlout" or die "couldn't open $sqlout: $!\n";
  foreach my $file (@sqlfiles) {
    open IN, $file or die "couldn't open $file: $!\n";
    while (<IN>) {
      print OUT;
    }
    close IN;
  }
  close OUT;

  warn "Creating Class::DBI classes in lib/ (this could take a while) ...\n";
  system("$working_dir/bin/pg2cdbi.pl '$DBNAME' '$DBUSER' '$DBPASS' $working_dir/modules/complete.sql > $working_dir/lib/Chado/AutoDBI.pm")==0
    or die "bin/pg2cdbi.pl failed, is SQL::Translator installed?\n";
}

WriteMakefile(
    'NAME'		=> 'chado',
    'PREREQ_PM'		=> { SQL::Translator   => 0.03,
                             Class::DBI        => 0.94,
                             Class::DBI::Pager => 0,
                             Class::DBI::Pg    => 0.02,
                             Module::Build     => 0.20,
                             Template          => 2.10,
                             DBI               => 0,
                             DBD::Pg           => 0,
                             XML::Simple       => 2.09,
                            }, 
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      ( # retrieve abstract from module
       AUTHOR     => 'Scott Cain <cain@cshl.org>') : ()),
);

print <<HERE

--------------------------------------------------------------
possible targets of makefile:
  images    - generate images of the schema in several formats
  metadata  - ???
  mysql     - convert postgres sql files to mysql sql files
  test_load - test database CREATE TABLE statements

HINT: you probably want to run (at least) "make test_load"
--------------------------------------------------------------
HERE
;

sub MY::install {
  package MY;
  my $inherited = shift->SUPER::install(@_);
  $inherited =~ s/doc_install/doc_install song go cvtermpath/;
  $inherited;
}

sub MY::c_o {
  return ".SUFFIXES : .gz .loaded .ontology .go_loaded .so_loaded .unpacked";
}


sub MY::postamble {
  qq{
.gz.unpacked:
	cp \$< \$<.tmp
	gunzip -f \$<
	mv \$<.tmp \$<
	touch \$@

cvtermpath ::
	$working_dir/bin/make_cvtermpath.sh

song ::
	make $working_dir/song/SODA.defs.unpacked
	make $working_dir/song/SODA.ontology.unpacked
	make $working_dir/song/SODA.so_loaded

go ::
	make $working_dir/go/component.go_loaded
	make $working_dir/go/function.go_loaded
	make $working_dir/go/process.go_loaded

websync :: 
	wget -nd -N -r -P$working_dir/go http://www.geneontology.org/ontology/component.ontology
	wget -nd -N -r -P$working_dir/go http://www.geneontology.org/ontology/function.ontology
	wget -nd -N -r -P$working_dir/go http://www.geneontology.org/ontology/process.ontology
	wget -nd -N -r -P$working_dir/go http://www.geneontology.org/doc/GO.defs
	wget -nd -N -r -P$working_dir/song http://heanet.dl.sourceforge.net/sourceforge/song/SODA.defs.gz
	wget -nd -N -r -P$working_dir/song http://cesnet.dl.sourceforge.net/sourceforge/song/SODA.ontology.gz

mysql :: \
		$working_dir/modules/complete.mysql

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

%.mysql: %.sql
	$working_dir/bin/pg2my.pl \$< > \$@

%.graphviz.png: %.sql
	$working_dir/bin/pg2graphviz.pl \$< > \$@

%.graphviz.svg: %.sql
	$working_dir/bin/pg2graphviz_svg.pl \$< > \$@

%.diagram.png: %.sql
	$working_dir/bin/pg2diagram.pl \$< > \$@

cdbi:
	$working_dir/bin/pg2cdbi.pl $working_dir/modules/complete.sql > $working_dir/src/pgsql/Chado/AutoDBI.pm
	$working_dir/bin/my2cdbi.pl $working_dir/modules/complete.mysql > $working_dir/src/mysql/Chado/AutoDBI.pm

metadata: $working_dir/bin/ddltrans
	cat \`find . -name \\*.sql -print\` > $working_dir/dat/chado.ddl
	$working_dir/bin/ddltrans -s chado -f dtd $working_dir/dat/chado.ddl > $working_dir/dat/chado.dtd
	$working_dir/bin/ddltrans -f html $working_dir/dat/chado.ddl > $working_dir/dat/chado.html
	$working_dir/bin/ddltrans -f perl $working_dir/dat/chado.ddl > $working_dir/dat/chado.pl
	$working_dir/bin/ddltrans -f xml $working_dir/dat/chado.ddl > $working_dir/dat/chado.xml

test_load ::
	\$(SHELL) $working_dir/bin/test_load.sh $DBNAME

%.go_loaded: %.ontology
	$working_dir/bin/load_ontology.pl $USER $DBNAME \$< $working_dir/go/GO.defs
	touch \$@

%.so_loaded: %.ontology
	$working_dir/bin/load_ontology.pl $USER $DBNAME \$< $working_dir/song/SODA.defs
	touch \$@
  };  
}
