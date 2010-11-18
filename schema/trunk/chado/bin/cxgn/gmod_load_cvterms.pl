#!/usr/bin/env perl

=head1 NAME

load_cvterms.pl

=head1 SYNOPSIS

Usage: perl load_cvterms.pl -H dbhost -D dbname [-vdntuFo] file

parameters

=over 8

=item -g

GMOD database profile name (can provide host, DB name, password, username, and driver) Default: 'default'

=item -s

database name for linking (must be in db table, e.g. GO ) 

=item -n

controlled vocabulary name (e.g 'biological_process').
optional. If not given, terms of all namespaces related with database name will be handled.

=item -F

File format. Can be obo or go_flat and others supported by
L<Bio::OntologyIO>. Default: obo

=item -u 

update all the terms. Without -u, the terms in the database won't be updated to the contents of the file, in terms of definitions, etc. New terms will still be added.

=item -v

verbose output

=item -o 

outfile for writing errors and verbose messages (optional)

=item -t

trial mode. Don't perform any store operations at all.
(trial mode cannot test inserting associated data for new terms)

=back


The following options are required if not using GMOD profile


=over 5

=item -H

hostname for database [required if -p isn't used]

=item -D

database name [required if -p isn't used]

=item -p 

password (if you need to provide a password to connect to your db)

=item -r 

username (if you need to provide a username to connect to your database) 


=item -d

driver name (e.g. 'Pg' for postgres). Driver name can be provided in gmod_config

=back


The script parses the ontology in the file and the corresponding ontology in the database, if present. It compares which terms are new in the file compared to the database and inserts them, and compares all the relationships that are new and inserts them. It removes the relationships that were not specified in the file from the database. It never removes a term entry from the database. 

This script works with Chado schema (see gmod.org) and accesse the following tables:

=over 9

=item db 

=item dbxref

=item cv

=item cvterm

=item cvterm_relationship

=item cvtermsynonym

=item cvterm_dbxref

=item cvtermprop

=back



Terms that are in the database but not in the file are set to is_obsolete=1.
All the terms that are present in the database are updated (if using -u option) to reflect the term definitions that are in the file.
New terms that are in the file but not in the database are stored.
The following data are associated with each term insert/update:

=over 7

=item Term name

=item Term definition

=item Relationships with other terms

=item Synonyms

=item Secondary ids

=item Definition dbxrefs

=item Comments

=back 



=head1 AUTHOR

Lukas Mueller <lam87@cornell.edu>

Naama Menda <nm249@cornell.edu>


=head1 VERSION AND DATE

Version 0.15, September 2010.

=cut


use strict;

use Getopt::Std;
use Pod::Usage;

use Bio::OntologyIO;
use Bio::Ontology::OntologyI;

use Bio::GMOD::Config;
use Bio::GMOD::DB::Config;

use Bio::Chado::Schema;

our ($opt_d, $opt_h, $opt_H, $opt_F, $opt_n, $opt_D, $opt_v, $opt_t, 
     $opt_u, $opt_o, $opt_p, $opt_r, $opt_g, $opt_s);

getopts('F:d:H:o:n:vD:tp:us:r:g:')
    or pod2usage();

my $dbhost = $opt_H;
my $dbname = $opt_D;
my $pass = $opt_p;
my $driver = $opt_d;
my $user = $opt_r;
my $verbose = $opt_v;

my $DBPROFILE = $opt_g ;

print "H= $opt_H, D= $opt_D, u=$opt_u, d=$opt_d, v=$opt_v, t=$opt_t   \n" if $verbose;

my $port = '5432';

if (!$opt_s)  { die  " Need -s db.name argument! \n " ; } # the database name that Dbxrefs should refer to

if (!($opt_H and $opt_D) ) {
    $DBPROFILE ||= 'default';
    my $gmod_conf = Bio::GMOD::Config->new() ;
    my $db_conf = Bio::GMOD::DB::Config->new( $gmod_conf, $DBPROFILE ) ;
    
    $dbhost ||= $db_conf->host();
    $dbname ||= $db_conf->name();
    $driver ||= $db_conf->driver();
    

    $port= $db_conf->port() || '5432';
    
    $user= $db_conf->user();
    $pass= $db_conf->password();
}

if (!$dbhost && !$dbname) { die "Need -D dbname and -H hostname arguments.\n"; }
if (!$driver) { die "Need -d (dsn) driver, or provide one in -g gmod_conf\n"; }
if (!$user) { die "Need -u user_name, or provide one in -g gmod_conf\n"; }


my $dsn = "dbi:$driver:dbname=$dbname";
$dsn .= ";host=$dbhost";
$dsn .= ";port=$port";

my $schema= Bio::Chado::Schema->connect($dsn, $user, $pass||'', { AutoCommit=>0 });

my $dbh=$schema->storage->dbh();

if (!$schema || !$dbh) { die "No schema or dbh is avaiable! \n"; }

#######################3

      
my $error = 0; # keep track of input errors (in command line switches).

if (!$opt_F) { $opt_F="obo"; }

if ($opt_t) { 
    print STDERR "Trial mode - rolling back all changes at the end.\n";
}
if ($opt_u) { print STDERR "This script will UPDATE cvterms stored in your database from the input file! \n"; }
else { print STDERR "WARNING: If your databse is already population with cvterms, not running in UPDATE mode (option -u) may cause database conflicts, such as violating unique constraints!\n"; }

print STDERR "Default for -s: $opt_s (specifies the database names for Dbxref objects)\n";

print STDERR "Default for -F: File format set to $opt_F\n";

my $file = shift;

if (!$file) { 
    print STDERR "A file is required as a command line argument.\n";
    $error=1;
}


die "Some required command lines parameters not set. Aborting.\n" if $error;

if ($opt_o) { open (OUT, ">$opt_o") ||die "can't open error file $opt_o for writting.\n" ; }


message( "Connected to database $dbname on host $dbhost.\n", 1);


print STDERR "Parsing the ontology $file...\n";
my $parser="";
$parser = Bio::OntologyIO->new( -file => $file, -format=>$opt_F );

#my $new_ont;
my @onts = ();
while( my $ont = $parser->next_ontology() ) {
    push @onts, $ont;
}


foreach my $new_ont(@onts) {
    my $new_ont_name=$new_ont->name();
    message("....found namespace  '$new_ont_name' \n", 1); 
    
    if ($opt_n && ( $opt_n ne $new_ont_name) ) { 
	message ("$opt_n: skipping to next ontology..\n",1);
	next (); 
    } 
    my $rel_cv;
    #check if relationship ontology is already loaded:
    if ($new_ont_name ne 'relationship') {
	$rel_cv= $schema->resultset("Cv::Cv")->find_or_create( { name => 'relationship' } , { key => 'cv_c1' }, );
	my @rel= $schema->resultset("Cv::Cvterm")->search(
	    { cv_id => $rel_cv->get_column('cv_id'),
	      is_relationshiptype => 1,
	    });
	
	if (!@rel) {
	    warn "Relationship ontology must be loaded first!!\n" ;
	    exit(0);
	}
    }
    ####add Typedef parsing to obo.pm!###
    ####store a new cv if the ontology namespace does not exist
    my $cv= $schema->resultset('Cv::Cv')->find_or_create( { name => $new_ont_name } , { key => 'cv_c1' }, );
    
    print STDERR "cv_id = ".($cv->get_column('cv_id') )."\n";
    
    print STDERR "Updating an ontology in the database...\n";
        my $db_ont = $cv;
    
    my $ontology_name=$db_ont->get_column('name');
    message("Ontology name: ".($db_ont->name())."\n", 1);
    
    my %file_relationships = (); # relationships currently defined in the file
    my %db_relationships = ();
    
    eval { 
	my $db = $schema->resultset("General::Db")->find_or_create( 
	    { name => $opt_s }, { key => 'db_c1' }, );
	
	print STDERR "Getting all the terms of the new ontology...\n";
	my (@all_file_terms) = $new_ont->get_all_terms();
	my (@all_file_predicate_terms) = $new_ont->get_predicate_terms();
	###my (@all_file_typedefs) = $new_ont->get_all_typedefs();
	message( "***found ".(scalar(@all_file_predicate_terms))." predicate terms!.\n", 1);
	message( "Retrieved ".(scalar(@all_file_terms))." terms.\n", 1);
        
	#look at all predecate terms (Typedefs)
	my @all_db_predicate_terms= $db_ont->search_related('cvterms' , { is_relationshiptype => 1} );  
	foreach my $t(@all_file_predicate_terms) {           #look at predicate terms in file
	    my ($p_term) = $schema->resultset('Cv::Cvterm')->search( 
		{ name => $t->name(),
		  is_relationshiptype => 1,
		});
	    #maybe it's stored with another cv_id?
	    if ($p_term) {
		message("predicate term '" .$t->name() . "' already exists with cv_id " . $p_term->get_column('cv_id') . "\n", 1);
	    }else { #need to store the predicate term under $cv  
	
		#this stores the relationship types under 'relationship' cv namespace
		#terms defined as '[Typedef]' in the obo file should actually be stored as relationshiptype
		#but with the current ontology cv namespace .
		#To do this we need to add to the obo parser (Bio::OntologyIO::obo.pm)
		#a 'get_typedefs' funciton
		my $accession = $t->identifier() || $t->name();
		my $p_term_db = $schema->resultset("General::Db")->find_or_create( { name => $opt_s }, { key => 'db_c1' }, );
		my $p_term_dbxref = $schema->resultset("General::Dbxref")->find_or_create( 
		    {   db_id     => $p_term_db->get_column('db_id'),
			accession => $accession,
			version   => $t->version() || '',
		    },
		    { key => 'dbxref_c1' } ,
		    );
		my $p_term = $schema->resultset("Cv::Cvterm")->find_or_create( 
		    { cv_id  => $cv->get_column('cv_id'),
		      name   => $t->name(),
		      dbxref_id => $p_term_dbxref->get_column('dbxref_id'),
		      definition => $t->definition(),
		      is_obsolete=> $t->is_obsolete(),
		      is_relationshiptype => 1,
		    },
		    { key => 'cvterm_c1' },
		    );
		
		message("Stored new relationshiptype '" .  $t->name() . "'\n",1);
	    }
	}
	print STDERR "Getting all the terms of the current ontology...\n";
	
	#a list of Bio::Chado::Schema::Cvterm objects
	my @all_db_terms = $schema->resultset("Cv::Cvterm")->search( 
	    { cv_id => $db_ont->get_column('cv_id'),
	      is_relationshiptype => 0,
	    })->all();
	print STDERR "Indexing terms and relationships...\n";
	my %file_index = ();  # index of term objects in the db with accession as key
	my %db_index = (); # this hash will be populated with accession => cvterm_object
	my $db_namespace ;
	foreach my $t (@all_file_terms) { 
	    my ($prefix, $id) = split (/\:/, $t->identifier()); #=~ s/\w+\:(.*)/$1/g;
	    $db_namespace = $prefix if !$db_namespace;
	    
	    $file_index{$id} = $t  if ($db_namespace eq $prefix) ;
	    message("Found term in file :  $prefix:$id\n", 1);
	}
	
	my $c_count = 0;  # count of db terms    
	foreach my $t (@all_db_terms) { 
	    $c_count++;
	    my ($id )= $t->search_related('dbxref')->first()->get_column('accession');
	    $db_index{$id} = $t;
	    message("Found term in DB: $id\n", 1);
	}
	
	my %novel_terms = ();
	my @removed_terms = ();
	my @novel_relationships = ();
	my @removed_relationships = ();
	
	
	print STDERR "Determining which terms are new...\n";
	#exit();
	
	FILE_INDEX: foreach my $k (keys(%file_index)) { 
	    if (!exists($db_index{$k})) { 
		if (!$file_index{$k}->name() ) { next FILE_INDEX; } #skip if term in file has no name. 
		#This happens in InterPro file - which is translated from xml to obo.
		
		if ($opt_v) { print STDERR "Novel term: $k ".($file_index{$k}->name())."\n"; }
		else { print STDERR "."; }
		print OUT "Novel term: $k ".($file_index{$k}->name())."\n" if $opt_o;
		
		$novel_terms{$k}=$file_index{$k};
	    }
	}
	
	print STDERR "Determine which terms are not in the file anymore...\n 
                      These terms will be set to obsolete in the database\n";
	
	foreach my $k (keys(%db_index)) { 
	    if (!exists($file_index{$k})) { 
		
		my $name = $db_index{$k}->name(); #get the name in the database 
		message( "Term not in file: $name \n",1);
		unless( $name =~ m/obsolete.*$opt_s:/ ) {
		    my $ob_name = $name . " (obsolete " . $opt_s . ":" . $name . ")" ;  #add the 'obsolete' suffix 
		    $db_index{$k}->set_column(name => $ob_name );
		    message( "**modified name for $opt_s:$name - '$ob_name' \n " , 1); 
		}
		
		$db_index{$k}->set_column(is_obsolete => 1 );
		$db_index{$k}->update();
				
		print STDERR " obsoleted term  $name!.\n";
		push @removed_terms, $db_index{$k};
	    }
	}
	
	print STDERR "Inserting and updating terms...\n";

	my $count = 0;
	my $u_count=0;
	UPDATE: foreach my $k (keys(%file_index)) {
	    $count++;
	    if (!exists($novel_terms{$k})) { 
		#update the term if run with -u option.
		
		if ($opt_u) {
		    $u_count++;
		    message( "updating information for term $k...\n");
		    if (!$file_index{$k} || !$db_index{$k} ) { message ("SKIPPING term $k! No value found\n", 1); next UPDATE; } 
		    $db_index{$k}->set_column(name => $file_index{$k}->name()  );
		    $db_index{$k}->set_column( definition => $file_index{$k}->definition() );
		    $db_index{$k}->set_column(is_obsolete => $file_index{$k}->is_obsolete() );
		    
		    my $name = $db_index{$k}->name();
		    #changing the name of obsolete terms to "$name (obsolete $db:$accession)"
		    #to avoid violating the cvterm unique constaint (name, cv_id, is_obsolete)
		    if ($db_index{$k}->is_obsolete() ) { 
			unless( $name =~ m/obsolete.*$opt_s:$k/ ) {
			    my $ob_name = $name . " (obsolete " . $opt_s . ":" . $k . ")" ;  
			    $db_index{$k}->set_column( name=>$ob_name );
			    print STDERR "**modified name for $opt_s:$k - '$ob_name' version: " . $file_index{$k}->version() . " \n " ; 
			}
		    }
		    $db_index{$k}->update();
		    
		    #update dbxref version 
		    if ( $file_index{$k}->version() ) {
			my ($dbxref)=$db_index{$k}->search_related('dbxref');
			$dbxref->set_column(version => $file_index{$k}->version() );
			$dbxref->update();
		    }
		    #add comment as a cvtermprop
		    my ($comment_cvterm) = $schema->resultset("Cv::Cvterm")->search( { name => 'comment'} ); 
		    if ($file_index{$k}->comment() ) {
			my $cvtermprop= $schema->resultset("Cv::Cvtermprop")->find_or_create(
			    { cvterm_id => $db_index{$k}->get_column('cvterm_id'),
			      type_id   => $comment_cvterm->get_column('cvterm_id'),
			      value     => $file_index{$k}->comment(),
			    },
			    );
		    }
		    ###############################
		    # deal with synonyms here... 
		    my %file_synonyms = ();
		    foreach my $s ($file_index{$k}->get_synonyms()) { 
			$s=~ s/\s+$//; 
			$s =~ s/\\//g;
			$file_synonyms{uc($s)}=1;
			
			message("...adding synonym  '$s'  to the database...\n");
			$db_index{$k}->add_synonym($s);
		    }
		    
		    foreach my $s ($db_index{$k}->search_related('cvtermsynonyms')) {
			my $s_name= $s->get_column('synonym');
			if (!exists($file_synonyms{uc($s_name)}) ) { 
			    message( "Note: deleting synonym ' " . $s->synonym() . "' from cvterm ". $db_index{$k}->get_column('name') . "...\n",1);
			    $db_index{$k}->delete_synonym($s);
			}
		    }
		    #deal with secondary ids (alt_id field).
		    # Stored in cvterm_dbxref with the field 'is_for_definition' = 0
		    
		    #delete all cvterm dbxrefs before loading the new ones from the file
		    my @secondary_dbxrefs= $db_index{$k}->search_related('cvterm_dbxrefs');
		    foreach (@secondary_dbxrefs) { $_->delete(); }
		    
		    my %file_secondary_ids = ();
		    foreach my $i ($file_index{$k}->get_secondary_ids()) { 
			$file_secondary_ids{uc($i)}=1;
			message("adding secondary id $i to the database...\n");
			
			$db_index{$k}->add_secondary_dbxref($i);
			
		    }
		    #########
                    # Definition dbxrefs. get_dblinks gets the dbxref in the definition tag
		    # and all xref_analog tags. This will store in the database cvterm_dbxrefs with 
		    #the fiels 'is_for_definition' = 1 
		    
		    my %file_def_dbxrefs=();
		    #store definition's dbxrefs in cvterm_dbxref
		    foreach my $dblink ($file_index{$k}->get_dbxrefs() ) { 
			my $def_dbxref = $dblink->database() . ':' .  $dblink->primary_id();
			$file_def_dbxrefs{uc($def_dbxref)}=1;
			message("adding definition dbxref $def_dbxref to cvterm_dbxref\n");
			$db_index{$k}->add_secondary_dbxref($def_dbxref, 1); 
		    }
		}
	    }
	} #finished updating existing terms..
	#now insert the new ones:
	my $n_count=0;
	foreach my $k (keys(%novel_terms)) {
	    $n_count++;
	    my $name = $novel_terms{$k}->name();
	    my $version = $novel_terms{$k}->version();
	    
	    my $accession = numeric_id($novel_terms{$k}->identifier());
	    message("Inserting novel term '$name'  (accession = '$accession', version = '$version'\n");
	    #write a special case for interpro domains 
	    #those have accession IPR000xxxx
	    #
	    #There's a potential issue with updating cvterms which have been moved  to another cv namespace. 
	    #In such cases, a dbxref is found, but we cannot store a new cvterm with the same dbxref_id (see cvterm_c2). 
	    # A new dbxref will be created to overcome this problem 
	    my $new_term_dbxref = $schema->resultset("General::Dbxref")->find( 
		{   db_id     => $db->get_column('db_id'),
		    accession => $accession,
		    version   => $version || '',
		},
		{ key => 'dbxref_c1' } ,
		);
	    if ($new_term_dbxref) { $version = $version+1 ; }
	    
	    $new_term_dbxref =  $schema->resultset("General::Dbxref")->create( 
		{   db_id     => $db->get_column('db_id'),
		    accession => $accession,
		    version   => $version || '',
		},
		{ key => 'dbxref_c1' } ,
		);
	    
	    if ($novel_terms{$k}->is_obsolete() == 1 ) {
		unless( $name =~ m/obsolete.*$opt_s:$k/i ) {
		    my $ob_name = $name . " (obsolete " . $opt_s . ":" . $k . ")" ;  
		    $name = $ob_name ;
		    print STDERR "**modified name for $opt_s:$k - '$ob_name' \n " ; 
		}
	    }
	    if (!$opt_t) {
		my $new_term= $schema->resultset("Cv::Cvterm")->create(
		    { cv_id  =>$cv->cv_id(),
		      name   => $name,
		      definition => $novel_terms{$k}->definition(),
		      dbxref_id  => $new_term_dbxref-> dbxref_id(),
		      is_obsolete=> $novel_terms{$k}->is_obsolete(),
		    }
		    );
		
		#changing the name of obsolete terms to "$name (obsolete $db:$accession)"
		#to avoid violating the cvterm unique constaint (name, cv_id, is_obsolete)
		
		message("Storing term $k...name = " . $novel_terms{$k}->name() . "\n"); 
		
		if ($count % 100==0)  { print STDERR "."; }
		my $comment = $novel_terms{$k}->comment();
		$new_term->create_cvtermprops( { comment => $comment } , { autocreate => 1 } ) if $comment;  
		
                #store synonyms in cvtermsynonym
		foreach my $s ($novel_terms{$k}->get_synonyms() ) { 
		    $s=~ s/\s+$//; 
		    $s =~ s/\\//g;
		    message("...adding synonym  '$s'  to the database...\n");
		    $new_term->add_synonym($s);  #need to add a type_id to each synonym!
		}
		
		foreach my $i ($novel_terms{$k}->get_secondary_ids()) { #store secondary ids in cvterm_dbxref
		    message("adding secondary dbxref '$i' to cvterm_dbxref\n");
		    		    
		    $new_term->add_secondary_dbxref($i);
		}
		foreach my $r ($novel_terms{$k}->get_dbxrefs() ) { #store definition's dbxrefs in cvterm_dbxref
		    my $def_dbxref= $r->database() . ':' . $r->primary_id();
		    message("adding definition dbxref $def_dbxref to cvterm_dbxref\n");
		    $new_term->add_secondary_dbxref($def_dbxref, 1);
		}
	    }
	}

	##################################
	message ("Updated $u_count existing terms, inserted $n_count new terms!\n",1);
	
	print STDERR "Parsing out the relationships...\n";
	print STDERR "Looking at relationships in file.\n";
	
	my $t_count = 0;   # count of terms in the file
	foreach my $t (@all_file_terms) { 
	    $t_count++;
	    my $id = numeric_id($t->identifier());
	    my @all_relationships = $new_ont->get_relationships($t);
	    message("Retrieved accession: $id\n");
	    foreach my $r (@all_relationships) { 
		my $s = $r->subject_term();
		my $o = $r->object_term();
		my ($s_db_name, undef) = split (/\:/ , $s->identifier);
		my ($o_db_name, undef) = split (/\:/, $o->identifier);
		if ($s_db_name ne $o_db_name) { 
		    print "*********************************************subject $s_db_name != object $o_db_name. Skipping!!\n";
		    next();
		}
		my $key = numeric_id($s->identifier())."-".numeric_id($o->identifier());
		message("Looking at relationship in file: $key\n" );
		if ($t_count % 100==0) { message("."); }
		$file_relationships{$key} = $r; # create the hash entry for this relationship	
	    }
	}
	print STDERR "\nLooking at relationships in database.\n";
	
	# indexing the database relationships
	foreach my $k (keys %db_index) {     
	    ###foreach my $r ($db_ont->get_relationships($db_index{$k})) { 
	    foreach my $r ($db_index{$k}->search_related('cvterm_relationship_subjects') ) { 
		if ($r) {
		    my ($s) = $r->search_related('subject');
		    my ($o) = $r->search_related('object'); 
		    #terms might have moved to a different cv namespace 
		    if ($s->cv_id() eq $o->cv_id() ) { 
			my $key = numeric_id($s->search_related('dbxref')->first()->accession)."-".numeric_id($o->search_related('dbxref')->first()->accession);
			message("Looking at relationship in db: $key\n");
			$db_relationships{$key}=$r;
		    }
		}
	    }
	}
	print STDERR "Relationships not in the file...\n";
	
	foreach my $k (keys(%db_relationships)) { 
	    if (! (exists($file_relationships{$k}) && defined($file_relationships{$k})) ) { 
		push @removed_relationships, $k;
		message("Deleted relationship: $k... \n",1);
	
		$db_relationships{$k}->delete();
		print STDERR "gone.\n";
	    }
	}
	
	print STDERR "\n";
	
	#####################################
	my $r_count = 0;
	RELATIONSHIP: foreach my $r (keys(%file_relationships)) { 
	    $r_count++;
	    if (!exists($db_relationships{$r})) {
		if ($opt_v) { print STDERR "Novel relationship: $r\n"; }
		elsif ($r_count % 100 == 0) { print STDERR "."; } 
		print OUT "Novel relationship: $r\n" if $opt_o;
		
		####
		#convert the Bio::Ontology::OBOTerm objects to Bio::Chado::Schema::Cv::Cvterm objects
		my $subject_accession = $file_relationships{$r}->subject_term()->identifier();
	
		my ($s_db, $s_acc) = split ':', $subject_accession;
		my ($subject_dbxref)= $schema->resultset("General::Dbxref")->find( 
		    { accession => $s_acc,
		      db_id     => $db->db_id(),
		    } );
		if (!$subject_dbxref ) { 
		    message("dbxref does not exist for subject term '$s_acc'.Skipping..\n" ,1); 
		    next RELATIONSHIP; 
		}
		my ($subject_term)= $schema->resultset('Cv::Cvterm')->find(
		    { cv_id => $cv->cv_id(),
		      dbxref_id => $subject_dbxref->dbxref_id(),
		    });
		
		
		if (!$subject_term ) { 
		    message("cvterm does not exist for subject term '$subject_accession'.Skipping..\n" ,1); 
		    next RELATIONSHIP; 
		}
		
		my $object_accession = $file_relationships{$r}->object_term()->identifier();
		my ($o_db, $o_acc) = split ':', $object_accession;
		my ($object_dbxref)= $schema->resultset("General::Dbxref")->find( 
		    { accession => $o_acc,
		      db_id     => $db->db_id(),
		    } );
					
		if (!$object_dbxref ) {
		    message("dbxref does not exist for object term $o_acc . SKIPPING!\n",1); 
		    next RELATIONSHIP;
		}
		my ($object_term)= $schema->resultset('Cv::Cvterm')->find(
		    { cv_id => $cv->cv_id(),
		      dbxref_id => $object_dbxref->dbxref_id(),
		    });
				
		if (!$object_term ) {
		    message("cvterm does not exist for object term $object_accession . SKIPPING!\n",1); 
		    next RELATIONSHIP;
		}
		
		############################################
		push @novel_relationships, $r;
		my $predicate_term_name = $file_relationships{$r}->predicate_term()->name();
		
		my $predicate_term;
		my ($rel_db)= $schema->resultset('General::Db')->search( { name => 'OBO_REL' } );
		($predicate_term) = $schema->resultset('General::Dbxref')->search(
		    { accession => { 'ilike' , "$predicate_term_name" }, 
		      db_id     => $rel_db->db_id(), 
		    })->search_related('cvterm') if $rel_db;
		if (!$predicate_term) {
		    ($predicate_term) = $schema->resultset('Cv::Cvterm')->search( 
			{ name => { 'ilike' , $predicate_term_name } ,
			  cv_id=> $cv->cv_id(),
			}
			);
		    
		    if (!$predicate_term) { 
			die "The predicate term $predicate_term_name does not exist in the database\n";  
		    }
		}
		if (!$opt_t) { 
		    message("Storing relationship $r. type cv_id=" . $predicate_term->cv_id() ."\n" ,1); 
		    my $new_rel = $schema->resultset('Cv::CvtermRelationship')->create(
			{ subject_id => $subject_term->cvterm_id(),
			  object_id  => $object_term->cvterm_id(),
			  type_id    => $predicate_term->cvterm_id(),
			}
			);
		}
	    }   
	}
	message($ontology_name." : ". scalar(@novel_relationships)." novel relationships among ".(scalar(keys(%file_relationships)))." were found and stored.\n", 1);
	
    };
    
    if ($@ || ($opt_t)) { 
	message( "Either running as trial mode (-t) or AN ERROR OCCURRED: $@\n",1); 
	$dbh->rollback();
	exit(0);
    }
    else {  
	message("Committing! \n If you are using cvtermpath you should now run gmod_make_cvtermoath.pl . See the perldoc for more info. \n\n", 1);
	
	$dbh->commit(); 
    }
}

print STDERR "Done.\n";



sub recursive_children { 
    my $ont = shift;
    my $node = shift;
    
    my @children = $ont -> get_child_terms($node);
    
    foreach my $child (@children) { 
	print STDERR "CHILD: ".($child->name())."\n";
	recursive_children($ont, $child);
    }
}


sub message { 
    my $message = shift;
    my $default=shift;
    if ($opt_v || $default) {  print STDOUT "$message"; }
    print OUT "$message" if $opt_o;
}

sub numeric_id { 
    my $id = shift;
    $id =~ s/.*\:(.*)$/$1/g;
    return $id;
}
