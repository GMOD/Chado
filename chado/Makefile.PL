use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

# questions to ask:
#  - what database server
#  - do you want to create Class::DBI stuff (which will be done now,
#      so that it can be put in lib/Class/DBI)
#




my %O;

#hard code these for the moment for testing
my $DBNAME            = chadx;
my $USER              = scott;
$O{GMOD_HOME}      = $ENV{GMOD_HOME} || '/usr/local/gmod';
$O{PACKAGE_HOME}   = $O{GMOD_HOME}.'/lib/schema';
$O{COREDEF}        = 'modules/idb-full.modules';
$O{EXTDEF}         = 'modules/extension.modules';

open CORE, $O{COREDEF} or die "unable to open $O{COREDEF}: $!\n";
my @sqlfiles;
while (<CORE>) {
  chomp;
  push @sqlfiles, 'modules/'.$_;
}
close CORE;

#what server? (Assume Pg for now)
#my $db = prompt("What database server will you be using?",'PostgreSQL');
#die "Really only PostgreSQL is well supported right now" unless $db =~ /^[Pp]/;

# get available extensions to core and ask if any are to be used.
print "Available extensions to the core schema:\n";
open EXT, $O{EXTDEF} or die "unable to open $O{EXTDEF}: $!\n";
my @extfiles = ( 0 );
my $i = 0;
while (<EXT>) {
  $i++;
  print "[$i] $_";
  chomp;
  push @extfiles, 'modules/'.$_;
}
close EXT;

my $extstr = prompt("What extensions to the core schema do you need (comma delimited)?","0");

if ($extstr) {
  my @extindex = split /,/, $extstr;
  foreach my $index (@extindex) {
    push @sqlfiles, $extfiles[$index];
  }
}

my $sqlout = 'modules/complete.sql';
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
system("./bin/pg2cdbi.pl ./modules/complete.sql > ./lib/Chado/AutoDBI.pm")==0
  or die "bin/pg2cdbi.pl failed";


WriteMakefile(
    'NAME'		=> 'chado',
    'PREREQ_PM'		=> { SQL::Translator => 0.02,
                             #DBI             => 0,
                             #DBD::Pg         => 0
                            }, 
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      ( # retrieve abstract from module
       AUTHOR     => 'A. U. Thor <a.u.thor@a.galaxy.far.far.away>') : ()),
);

print <<HERE
----------------------------------------------------------
possible targets of makefile:
  diagram   - make diagram images of schema
  graphviz  - make graphviz images of schema
  metadata  - ???
  mysql     - convert postgres sql files to mysql sql
  test_load - test database CREATE TABLE statements

HINT: you probably want to run (at least) "make test_load"
----------------------------------------------------------
HERE
;

sub MY::postamble {
  my $uninterp =  q{
song ::
	make obo/OBO_REL/rel.rel_loaded
	make song/SODA.defs.unpacked
	make song/SODA.ontology.unpacked
	make song/SODA.so_loaded

go ::
	make obo/OBO_REL/rel.rel_loaded
	make go/component.go_loaded
	make go/function.go_loaded
	make go/process.go_loaded

websync :: 
	wget -nd -N -r -Pgo http://www.geneontology.org/ontology/component.ontology
	wget -nd -N -r -Pgo http://www.geneontology.org/ontology/function.ontology
	wget -nd -N -r -Pgo http://www.geneontology.org/ontology/process.ontology
	wget -nd -N -r -Pgo http://www.geneontology.org/doc/GO.defs
	wget -nd -N -r -Psong http://heanet.dl.sourceforge.net/sourceforge/song/SODA.defs.gz
	wget -nd -N -r -Psong http://cesnet.dl.sourceforge.net/sourceforge/song/SODA.ontology.gz

mysql :: \
		./modules/complete.mysql

graphviz :: \
                ./modules/companalysis/companalysis.graphviz.png \
                ./modules/cv/cv.graphviz.png \
                ./modules/expression/expression.graphviz.png \
                ./modules/expression/rad.graphviz.png \
                ./modules/general/general.graphviz.png \
                ./modules/genetic/genetic.graphviz.png \
                ./modules/map/map.graphviz.png \
                ./modules/organism/organism.graphviz.png \
                ./modules/pub/pub.graphviz.png \
                ./modules/sequence/sequence.graphviz.png \
                ./modules/www/www.graphviz.png

diagram :: \
                ./modules/companalysis/companalysis.diagram.png \
                ./modules/cv/cv.diagram.png \
                ./modules/expression/expression.diagram.png \
                ./modules/expression/rad.diagram.png \
                ./modules/general/general.diagram.png \
                ./modules/genetic/genetic.diagram.png \
                ./modules/map/map.diagram.png \
                ./modules/organism/organism.diagram.png \
                ./modules/pub/pub.diagram.png \
                ./modules/sequence/sequence.diagram.png \
                ./modules/www/www.diagram.png

%.mysql: %.sql
	./bin/pg2my.pl $< > $@

%.graphviz.png: %.sql
	./bin/pg2graphviz.pl $< > $@

%.diagram.png: %.sql
	./bin/pg2diagram.pl $< > $@

cdbi:
	./bin/pg2cdbi.pl ./modules/complete.sql > ./src/pgsql/Chado/AutoDBI.pm
	./bin/my2cdbi.pl ./modules/complete.mysql > ./src/mysql/Chado/AutoDBI.pm

metadata: ./bin/ddltrans
	cat `find . -name \*.sql -print` > ./dat/chado.ddl
	./bin/ddltrans -s chado -f dtd ./dat/chado.ddl > ./dat/chado.dtd
	./bin/ddltrans -f html ./dat/chado.ddl > ./dat/chado.html
	./bin/ddltrans -f perl ./dat/chado.ddl > ./dat/chado.pl
	./bin/ddltrans -f xml ./dat/chado.ddl > ./dat/chado.xml
  };

  qq{
test_load ::
	\$(SHELL) bin/test_load.sh

%.go_loaded: %.ontology
	./bin/load_ontology.pl $USER $DBNAME $< go/GO.defs
	touch $@

%.so_loaded: %.ontology
	./bin/load_ontology.pl $USER $DBNAME $< song/SODA.defs
	touch $@

$uninterp
  };  
}
