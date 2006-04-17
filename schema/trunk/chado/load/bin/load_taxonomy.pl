#!/usr/bin/perl
#$Id: load_taxonomy.pl,v 1.1 2006-04-17 05:22:22 allenday Exp $
#download from ftp://ftp.ncbi.nih.gov/pub/taxonomy/
use strict;
use DBI;

my %okay_level = map { chomp; $_=>1 } grep { $_ !~ /^#/ } <DATA>;
my %node = ();
my %seen = ();
my %seq  = (
  organism => 'organism_organism_id_seq',
  dbxref   => 'dbxref_dbxref_id_seq',
);
my %field = (
  organism              => 'organism_id, genus, species',
  organism_relationship => 'subject_id, object_id, type_id',
  organism_dbxref       => 'organism_id, dbxref_id',
  dbxref                => 'dbxref_id, db_id, accession',
);

my $dbh = DBI->connect("dbi:Pg:dbname=chado-celsius;host=torso.genomics.ctrl.ucla.edu");
my $sth;

#Create and retrieve NCBI Tax database
$sth = $dbh->do("INSERT INTO db (name,url,urlprefix) VALUES ('Taxonomy','http://ncbi.nlm.nih.gov/Taxonomy/','http://ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?mode=Info&id=')");
$sth = $dbh->prepare("SELECT db_id FROM db WHERE name = 'Taxonomy'");
$sth->execute();
my( $db_id ) = $sth->fetchrow_array();

$sth = $dbh->prepare("SELECT cvterm_id FROM cvterm WHERE name = 'is_a' AND cv_id = (SELECT cv_id FROM cv WHERE name = 'relationship')");
$sth->execute();
my( $isa_id ) = $sth->fetchrow_array();

$sth = $dbh->prepare("SELECT nextval('$seq{organism}')");
$sth->execute();
my( $next_organism ) = $sth->fetchrow_array();
$sth = $dbh->prepare("SELECT nextval('$seq{dbxref}')");
$sth->execute;
my( $next_dbxref ) = $sth->fetchrow_array();

##########################
#read in the taxonomy tree
open( NODE, "nodes.dmp" );
while ( my $line = <NODE> ) {
  my ( $id, $parent, $level ) = split /\t\|\t/, $line;
  next unless $okay_level{ $level };
  $node{ $id }{ 'parent_taxid' } = $parent;
  $node{ $id }{ 'self_taxid'   } = $id;
  $node{ $id }{ 'level'        } = $level;
  $node{ $id }{ 'organism_id'  } = $next_organism++;
}
close( NODE );

open( NAME, "names.dmp" );
while ( my $line = <NAME> ) {
  next unless $line =~ /scientific name/;
  my ( $id, $name ) = split /\t\|\t/, $line;
  next unless $node{ $id };
  $node{ $id }{ 'common_name' } = $name;
  $node{ $id }{ 'common_name' } .= " Taxonomy:$id" if $seen{ $name }++;
}
close( NAME );

foreach my $id ( keys %node ) {
  if ( $node{ $id }{ 'level' } eq 'species' ) {
    $node{ $id }{ 'genus' }   = $node{ $node{ $id }{ 'parent_taxid' } }{ 'common_name' };
    $node{ $id }{ 'species' } = $node{ $id }{ 'common_name' };
  }
  else {
    $node{ $id }{ 'genus'   } = $node{ $id }{ 'level' };
    $node{ $id }{ 'species' } = $node{ $id }{ 'common_name' };
  }
}


##########################
#write the data files
$dbh->begin_work();

open( O, ">organism.dat");
open( D, ">dbxref.dat");
open( OD, ">organism_dbxref.dat");
open( OR, ">organism_relationship.dat");

foreach my $id ( keys %node ) {
  print O sprintf(
    "%s\t%s\t%s\n",
    $node{ $id }{ 'organism_id' },
    $node{ $id }{ 'genus'       },
    $node{ $id }{ 'species'     },
  );

  if ( defined $node{ $node{ $id }{ 'parent_taxid' } }{ 'organism_id' } ) {
    print OR sprintf(
      "%s\t%s\t%s\n",
      $node{ $id }{ 'organism_id' },
      $node{ $node{ $id }{ 'parent_taxid' } }{ 'organism_id' },
      $isa_id,
    );
  }

  print D sprintf(
    "%s\t%s\t%s\n",
    $next_dbxref,
    $db_id,
    $node{ $id }{ 'self_taxid' },
  );

  print OD sprintf(
    "%s\t%s\n",
    $node{ $id }{ 'organism_id' },
    $next_dbxref,
  );

  $next_dbxref++;
}

close( O );
close( D );
close( OD );
close( OR );

#exit;

foreach my $table ( qw( dbxref organism organism_dbxref organism_relationship ) ) {
  my $fields = $field{ $table };
  warn "Loading data into $table table ...\n";
  my $query = "COPY $table ( $fields ) FROM STDIN;";
  my $sth = $dbh->prepare( $query );
  $sth->execute();

  open FILE, "$table.dat";
  while ( <FILE> ) {
    $dbh->func( $_, 'putline' );
  }
  $dbh->func('endcopy');  # no docs on this func--got from google
  close FILE;
  $sth->finish();
}


#update the sequence so that later inserts will work 
$sth->finish();
$dbh->do("SELECT setval('public.$seq{organism}', $next_organism)"); 
$dbh->do("SELECT setval('public.$seq{dbxref}', $next_dbxref)"); 
#$dbh->rollback();
$dbh->commit();
$dbh->disconnect();

#http://www.eyesopen.com/docs/cplusprog_1_2/node220.html
__DATA__
no rank
superkingdom
subkingdom
kingdom
superphylum
phylum
subphylum
superclass
class
subclass
infraclass
cohort
subcohort
superorder
order
suborder
infraorder
parvorder
superfamily
family
subfamily
tribe
subtribe
genus
subgenus
species group
species subgroup
species
#subspecies
#varietas
#forma
