
=head1 NAME

 load_ncbi_taxonomy.pl
    
=head1 DESCRIPTION

 Usage: perl load_ncbi_taxonomy.pl -H [dbhost] -D [dbname] [-vt] -i file

populate a chado database with organism information (see the organism module and phylogeny module)

=head2 Prerequisites

=over 3

=item 1. Load taxonomy cvterms 

see load_taxonomy_cvterms.pl

=item 2. Download NCBI taxonomy files 

ftp://ftp.ncbi.nih.gov/pub/taxonomy/

Save these 2 files in the same dir. of this script 
 names.dmp
 nodes.dmp

=item 3. Download a taxon_id list from NCBI

Optional. This filter file will include the taxons you would like to store in your tree (see option -i).
Without this file the entire NCBI taxonomy will be stored in your database! 

=back 


=head2 parameters

=over 7

=item -H

hostname for database

=item -D

database name

=item -i 

input file [optional]

List taxonomy ids to be stored. The rest of the taxons in the name and node files will be excluded.
http://www.ncbi.nlm.nih.gov/sites/entrez?db=Taxonomy 
and search by taxid (e.g. txis4070[Subtree] )  

=item p [optional]

phylotree name 

name you phylotree. Default = 'NCBI taxonomy tree' 

=item -v

verbose output
 
=item -t

trial mode. Do not perform any store operations at all.


=item -g

GMOD database profile name (can provide host and DB name) Default: 'default'

=back


The script stores ncbi taxonomy in chado organism and phylogeny modules
This script works with SGN's public schema (chado compatible) and accesse the following tables:

=over 7

=item db (DB:NCBI_taxonomy)
 
=item dbxref (genbank taxon ids will be stored in the accession field)

=item organism

=item organism_dbxref

=item phylotree 

=item phylonode

=item phylonode_organism



=back


For storing phylonodes a new phylotree will be stored with the name 'NCBI taxonomy tree'.
Each organism will get a phylonode id and will be stored in a tmp table, since each phylonode (except for the root) has a parent_phylonode_id, which is an internal foreign key. 
Next each phylonode will get a left and right indexes, which are calculated by walking down the entire tree structure (see article by Aaron Mackey: http://www.oreillynet.com/pub/a/network/2002/11/27/bioconf.html?page=2).
Only after each phylonode will have calculated indexes, the phylonode table will be populated from the tmp table.


=head1 AUTHOR

Adapted from GMOD load_taxonomy.pl:
#$Id: load_taxonomy.pl,v 1.1 2006/04/17 05:22:22 allenday Exp $
#download from ftp://ftp.ncbi.nih.gov/pub/taxonomy/

by
Naama Menda <nm249@cornell.edu>

=head1 VERISON AND DATE

Version 2.0, October 2009.

=head1 TODO



=cut


#! /usr/bin/perl

use strict;


use Bio::GMOD::Config;
use Bio::GMOD::DB::Config;

use Bio::Chado::Schema;

use Getopt::Std;

our ($opt_H, $opt_D, $opt_v, $opt_t, $opt_i, $opt_p, $opt_g);

getopts('H:D:i:p:g:tv');

my $dbhost = $opt_H;
my $dbname = $opt_D;
my $infile = $opt_i;
my $phylotree_name= $opt_p || 'NCBI taxonomy tree';
my $DBPROFILE = $opt_g ;

print "H= $opt_H, D= $opt_D, v=$opt_v, t=$opt_t, i=$opt_i  \n";

my ($dbh, $schema);

if ($opt_g) {
    my $DBPROFILE = $opt_g;
    $DBPROFILE ||= 'default';
    my $gmod_conf = Bio::GMOD::Config->new() ;
    my $db_conf = Bio::GMOD::DB::Config->new( $gmod_conf, $DBPROFILE ) ;
    
    $dbhost ||= $db_conf->host();
    $dbname ||= $db_conf->name();
    
    if (!$dbhost && !$dbname) { die "Need -D dbname and -H hostname arguments.\n"; }
    my $dsn = "dbi:".$db_conf->driver.":dbname=$dbname";
    $dsn .= ";host=$dbhost";
    $dsn .= ";port=".$db_conf->port if $db_conf->port;
    $schema= Bio::Chado::Schema->connect( $dsn, $db_conf->user(), $db_conf->password(), { AutoCommit=>0 });
    $dbh=$schema->storage->dbh();

}else { 
    require CXGN::DB::InsertDBH;
    $dbh = CXGN::DB::InsertDBH->new( { dbhost=>$dbhost,
				       dbname=>$dbname,
				       dbschema=>'public',
				     } );
    $schema= Bio::Chado::Schema->connect( sub { $dbh->get_actual_dbh() } );   
}
if (!$schema || !$dbh) { die "No schema or dbh is avaiable! \n"; }

my $sth;
my %okay_level = map { chomp; $_=>1 } grep { $_ !~ /^#/ } <DATA>;
my %node = ();
my %seen = ();
my %seq  = (
    db       => 'db_db_id_seq',
    organism => 'organism_organism_id_seq',
    dbxref   => 'dbxref_dbxref_id_seq',
    organism_dbxref => 'organism_dbxref_organism_dbxref_id_seq',
    phylotree=> 'phylotree_phylotree_id_seq',
    phylonode=> 'phylonode_phylonode_id_seq',
    phylonode_organism => 'phylonode_organism_phylonode_organism_id_seq',
    );



#Create and retrieve NCBI Tax database

my $db_name= 'DB:NCBI_taxonomy';

my $db= $schema->resultset("General::Db")->find_or_create(
    { name => $db_name } ); 

$db->url('ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?mode=Info&id=');
$db->urlprefix('http://');
$db->update();
my $db_id = $db->get_column('db_id');

########

#Fetch last database ids of relevant tables for resetting in case of rollback
my %maxval=();
foreach my $key( keys %seq) {
    my $id_column= $key . "_id";
    my $table =  $key;
    my $query = "SELECT max($id_column) FROM $table";
    $sth=$dbh->prepare($query);
    $sth->execute();
    my ($next) = $sth->fetchrow_array();
    #print STDERR "max $key is $next!\n";
    $maxval{$key}= $next;
}

#store a new phylotree for NCBI taxonomy

my  $tree_accession= 'taxonomy'; 

my $tree_dbxref = $schema->resultset("General::Dbxref")->find_or_create(
    { accession => $tree_accession,
      db_id => $db_id,
    } );

my $tree_dbxref_id = $tree_dbxref->get_column('dbxref_id');


my $phylotree = $schema->resultset('Phylogeny::Phylotree')->find_or_create(
    { dbxref_id => $tree_dbxref_id,
      name => $phylotree_name,
    }
    );

my $phylotree_id = $phylotree->phylotree_id();
print STDERR "Created a new phylotee with id $phylotree_id\n\n\n";

#remove all existing phylonodes for this tree and reset the database sequence

$schema->resultset('Phylogeny::Phylonode')->search(
    { phylotree_id => $phylotree_id })->delete();

$maxval{phylonode} = set_maxval( 'phylonode' );
$maxval{phylonode_organism} = set_maxval( 'phylonode_organism' ); 


my %tax_file=() ; # hash for soring taxonomy ids from -i 
if ($infile) {
    open (INFILE, "<$infile") || die "Can't open infile $infile!!\n\n";  #
    while (my $t_id = <INFILE>) {
	chomp $t_id;
	$tax_file{$t_id} = $t_id;
    }
}
my $error = "load_taxonomy.err";
open (ERR, ">$error") || die "Can't open error file for writing ($error)!\n";

#######################
##########################
#read in the taxonomy tree
open( NODE, "nodes.dmp" );
while ( my $line = <NODE> ) {
    my ( $id, $parent, $level ) = split /\s+\|\s+/, $line;
    
    next unless $okay_level{ $level };
    if ($infile) { next() unless exists $tax_file{$id} ; }  # skip nodes not in tax_file 
    $node{ $id }{ 'parent_taxid' } = $parent;
    $node{ $id }{ 'self_taxid'   } = $id;
    $node{ $id }{ 'level'        } = $level;
}

close( NODE );

open( NAME, "names.dmp" );
while ( my $line = <NAME> ) {
    #next unless $line =~ /scientific name/;
    my ( $id, $name ) = split /\s+\|\s+/, $line;
    next unless $node{ $id }; #skip nodes  
    if ( $line =~ /scientific name/) {
	$node{ $id }{ 'name' } = $name;
	$node{ $id }{ 'name' } .= " Taxonomy:$id" if $seen{ $name }++;
    } elsif  ( $line =~ /common name/) { #  genbank common names 
	push(@{ $node{ $id }{ 'common_name' } } , $name);
	push(@{ $node{$id}{ 'synonyms' } }, $name);
	
    } elsif ( $line =~ /synonym/ ) {
	push @{ $node{$id}{ 'synonyms' } }, $name;
    }
}

close( NAME );

foreach my $id ( keys %node ) {
    if ( $node{ $id }{ 'level' } eq 'species' ) {
	$node{ $id }{ 'genus' }   = $node{ $node{ $id }{ 'parent_taxid' } }{ 'name' };
	$node{ $id }{ 'species' } = $node{ $id }{ 'name' };
    }
    else {
	$node{ $id }{ 'genus'   } = $node{ $id }{ 'level' };
	$node{ $id }{ 'species' } = $node{ $id }{ 'name' };
    }
}



##########################
#use temp table for generating the phylonode_ids 

$dbh->do("CREATE TEMP TABLE tmp_phylonode (
 phylonode_id integer NOT NULL PRIMARY KEY,  
 phylotree_id integer ,
 organism_id integer,
 parent_phylonode_id integer,
 left_idx integer,
 right_idx integer,
 type_id integer)"
    );


############################################
my $next_phylonode_id= $maxval{'phylonode'} +1  ;
my %phylonode=();
my $node_count=0;

eval {
    my $root_id;
    my $organism_id = $maxval{'organism'};
  NODE: foreach my $id ( keys %node ) {
      ######
      #Store the genbank taxon_id in dbxref and in organism_dbxref
      #
      my $genbank_taxon_accession= $node{ $id }{ 'self_taxid' };
      if (!$genbank_taxon_accession) { 
	  print ERR "SKIPPING: No record found for genbank taxon id $id! Check your infile !\n";
	  next NODE;
      }
      my $dbxref = $schema->resultset("General::Dbxref")->find_or_create(
	  { accession => $genbank_taxon_accession,
	    db_id => $db_id,
	  });
      my $dbxref_id = $dbxref->get_column('dbxref_id');
      
      my $abbreviation;
      if ($node{ $id }{level} eq 'species' ) {
	    
	  if ( $node{ $id }{ 'species' } =~ m/(.*)\s(.*)/ ) {
	      my $gen=$1;
	      my $sp=$2;
	      $abbreviation= uc( substr( $gen ,0, 1 ) ) . "." .  $sp;
	  }
      }
      my $common_name;
      my $c= @{ $node{$id}{'common_name'} } if (defined @{ $node{$id}{'common_name'}}); 
      $common_name =    join("," , @{ $node{ $id }{ 'common_name' } }) if $c;
      
      my $genus = $node{ $id }{ 'genus' } ;
      my $species = $node{ $id }{ 'species' } ;
      my ($organism, $update, $insert);
      
      #this is just for checking if the organism is already stored in the database
      #
      #if ($species =~ m/(.*)\s(.*)/) { 
      #    $species = $2;
      #    $genus = $1;
      #}
      $organism = $schema->resultset('Organism::Organism')->search(
	  {
	      genus   => { 'ilike'=> $genus },
	      species => {'ilike' => $species }
	  })->single();
      if (!$organism) {  #create a new empty row object 
	  $organism = $schema->resultset('Organism::Organism')->new({});
	  $insert=1;
      } else { $update = 1; }
      
      $organism->set_column(genus => $node{ $id }{ 'genus' } );
      $organism->set_column(species => $node{ $id }{ 'species' } );
      $organism->set_column(abbreviation => $abbreviation );
      $organism->set_column(common_name => $common_name );
      
      if ($update) {
	  $organism->update();
	  print STDERR "*Updating organism " . $organism->get_column('organism_id') . " (species=" . $organism->species . ")\n"; 
	  print ERR "*Updating organism " . $organism->get_column('organism_id') . " (species=" . $organism->species . ")\n"; 
      }
      if ($insert) {
	  $organism->insert();
	    print STDERR "New organism " . $organism->get_column('organism_id') . " (species=" . $organism->species . ")\n"; 
	  print ERR "New organism " . $organism->get_column('organism_id') . " (species=" . $organism->species . ")\n"; 
      }
      	my $organism_id= $organism->get_column('organism_id');
      
      ###########################################
      #store the organism synonyms 
      foreach (@{$node{ $id }{synonyms} } ) {
	  $organism->create_organismprops( { synonym => $_ }, { autocreate => 1} , );
	  print STDERR $node{ $id }{name} . " LEVEL=( " . $node{ $id }{level} . ") Synonym is $_ \n" ; 
      } 
      ####################################################################
      
      my $organism_dbxref = $schema->resultset('Organism::OrganismDbxref')->find_or_create( 
	  {
	      organism_id => $organism_id,
	      dbxref_id   => $dbxref_id,
	  },
	  );
      
      #get the cvterm_id of the taxonomy level
      my $level= $node{ $id }{level};
      my ($level_cvterm) = $schema->resultset("Cv::Cvterm")->find( 
	  {
	      name  => $level,
	      cv_id => $schema->resultset("Cv::Cv")->find( { name => 'taxonomy' } )->get_column('cv_id'),
	  },
	  );
      
      my $level_id = $level_cvterm->get_column("cvterm_id") if $level_cvterm ;
      
      if (!$level_cvterm) {
	  print STDERR "No cvterm found for type $level! Check your cvterm table for loaded taxonomy (cv name should be 'taxonomy') \n\n";
	  print ERR "No cvterm found for type $level! Check your cvterm table for loaded taxonomy (cv name should be 'taxonomy') \n\n";
	  
      }
      #store a new phylonode_id + phylonode_organism. This is necessary for storing later the parent_phylonode_id
      # and eventuay the left_idx and right_idx.
      
      $phylonode{ $id }{ 'phylonode_id' } = $next_phylonode_id++;
      $phylonode{ $id }{ 'organism_id' } = $organism_id;
      $phylonode{ $id }{ 'parent_taxid' } = $node{ $id }{ 'parent_taxid' };
      $phylonode{ $id }{ 'type_id' } = $level_id ; 
      
  }
    
    
#now that all the organisms are stored, we can sore the relationships (=phylonodes) 
    my %stored=();
    my %test=();
    foreach my $id (keys %phylonode ) {
	
	my $phylonode_id = $phylonode{ $id }{ 'phylonode_id' };
	my $organism_id = $phylonode{ $id }{ 'organism_id' } ;
	my $parent_phylonode_id = $phylonode{ $phylonode{ $id }{ 'parent_taxid' } }{ 'phylonode_id' } || 'NULL';
	$root_id = $phylonode_id if $parent_phylonode_id eq 'NULL';
	if ($parent_phylonode_id eq 'NULL') { print STDERR "organism $organism_id does not have a parent! (phylonode_id = $phylonode_id)\n"; }
	my $type_id = $phylonode{ $id }{'type_id'} || 'NULL';
	push @{$test{$parent_phylonode_id} } , $phylonode_id ;  
	my $insert="INSERT INTO tmp_phylonode (phylotree_id, phylonode_id, parent_phylonode_id, organism_id, type_id) 
             VALUES ($phylotree_id,$phylonode_id, $parent_phylonode_id, $organism_id, $type_id)";
	
	$node_count++;
	$dbh->do($insert);
    }
    
    #now walk through the tmp table and update the indexes
    
    our $ctr = 1;
    print STDERR "the root_id is $root_id\n";
    
    walktree($root_id);
    
    print STDERR "Updating the phylonode and phylonode_organism tables\n\n";
    my @updates=(
	"INSERT INTO phylonode (phylonode_id, phylotree_id, parent_phylonode_id, left_idx, right_idx, type_id) SELECT phylonode_id, phylotree_id, parent_phylonode_id, left_idx, right_idx, type_id  FROM tmp_phylonode",
	"INSERT INTO phylonode_organism (phylonode_id, organism_id) SELECT phylonode_id, organism_id FROM tmp_phylonode"
	);
    
    
    foreach (@updates) { $dbh->do( $_ );  }
    
    sub walktree {
	my $id = shift;
	
	my $children = $dbh->prepare("SELECT phylonode_id
                              FROM tmp_phylonode
                              WHERE parent_phylonode_id = ?");
	my $setleft  = $dbh->prepare("UPDATE tmp_phylonode
                              SET left_idx = ?
                              WHERE phylonode_id = ?");
	my $setright = $dbh->prepare("UPDATE tmp_phylonode
                              SET right_idx = ?
                              WHERE phylonode_id = ?");
	
	print STDERR "\nwalking the tree for $id...\n";
	$setleft->execute($ctr++, $id);
	print STDERR "Setting left index= $ctr for parent $id\n\n";
	$children->execute($id);
	
	while(my ($id) = $children->fetchrow_array() ) {
	    print STDERR "Found child_id $id \n ";
	    walktree($id);
	}
	$setright->execute($ctr++, $id);
	print STDERR "Setting right index= $ctr for id $id\n\n";
    }
    
};

if ($@ || $opt_t) { 
    $dbh->rollback();
    
    print STDERR "Rolling back! \n $@\n Resetting database sequences...\n";
    print ERR "Rolling back! \n $@\n Resetting database sequences...\n";
    
    #reset sequences
    foreach my $key ( keys %seq ) { 
	my $value= $seq{$key};
	my $maxvalue= $maxval{$key} || 0;
	#print STDERR "$key: $value, $maxvalue \n";
	if ($maxvalue) { $dbh->do("SELECT setval ('$value', $maxvalue, true)") ;  }
	else {  $dbh->do("SELECT setval ('$value', 1, false)");  }
    }
}else {    
    print STDERR "Commiting!! \n";
    print STDERR "Inserted $node_count phylonodes. \n";
    print ERR "Inserted $node_count phylonodes. \n";
    
    $dbh->commit(); 
}


sub set_maxval {
    my $key=shift;
    my $id_column= $key . "_id";
    my $table =  $key;
    my $query = "SELECT max($id_column) FROM $table";
    $sth=$dbh->prepare($query);
    $sth->execute();
    my ($next) = $sth->fetchrow_array();
    #print STDERR "max $key is $next!\n";
    return $next;
}


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
subspecies
varietas
forma
