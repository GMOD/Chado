#!/bin/sh
#argh--path dependancy need to be fixed

echo "Relationship Ontology"
./bin/make_cvtermpath.pl $USER $DBNAME 'Relationship Ontology'         | psql -q $DBNAME

echo "Sequence Ontology"
./bin/make_cvtermpath.pl $USER $DBNAME 'Sequence Ontology'             | psql -q $DBNAME

echo "Gene Ontology"
./bin/make_cvtermpath.pl $USER $DBNAME 'Gene Ontology'                 | psql -q $DBNAME

echo "Mouse Embryo Anatomy Ontology"
./bin/make_cvtermpath.pl $USER $DBNAME 'Mouse Embryo Anatomy Ontology' | psql -q $DBNAME

echo "Mouse Adult Anatomy Ontology"
./bin/make_cvtermpath.pl $USER $DBNAME 'Mouse Adult Anatomy Ontology'  | psql -q $DBNAME

echo "Cell Ontology"
./bin/make_cvtermpath.pl $USER $DBNAME 'Cell Ontology'                 | psql -q $DBNAME

echo "eVOC Pathology Ontology"
./bin/make_cvtermpath.pl $USER $DBNAME 'eVOC Pathology Ontology'       | psql -q $DBNAME

true;




#echo "eVOC Cell Type Ontology"
#./bin/make_cvtermpath.pl $USER $DBNAME 'eVOC Cell Type Ontology'       | psql -q $DBNAME

