
=head1 NAME

load_cvterms.pl

=head1 DESCRIPTION

Usage: perl load_cvterms.pl -H dbhost -D dbname [-vdntuFo] file

parameters

=over 9

=item -H

hostname for database [required if -p isn't used]

=item -D

database name [required if -p isn't used]

=item -p

GMOD database profile name (can provide host and DB name) Default: 'default'

=item -v

verbose output

=item -d

database name for linking (must be in db table) Default: GO

=item -n

controlled vocabulary name (e.g 'biological_process').
optional. If not given, terms of all namespaces related with database name will be handled.

=item -F

File format. Can be obo or go_flat and others supported by
L<Bio::OntologyIO>. Default: obo

=item -u 

update all the terms. Without -u, the terms in the database won't be updated to the contents of the file, in terms of definitions, etc. New terms will still be added.

=item -o 

outfile for writing errors and verbose messages (optional)

=item -t

trial mode. Don't perform any store operations at all.
(trial mode cannot test inserting associated data for new terms)

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

Version 0.12, February 2008.

=cut


use strict;

use Getopt::Std;
use Bio::OntologyIO;
use Bio::Ontology::OntologyI;
use CXGN::DB::InsertDBH;
use CXGN::Chado::Db;
use CXGN::Chado::Dbxref;
use CXGN::Chado::CV;
use CXGN::Chado::Cvterm;
use CXGN::Chado::Ontology;
use CXGN::Chado::Relationship;
use Bio::GMOD::Config;
use Bio::GMOD::DB::Config;

our ($opt_d, $opt_h, $opt_H, $opt_F, $opt_n, $opt_D, $opt_v, $opt_t, 
     $opt_u, $opt_o, $opt_p);

getopts('F:d:H:o:n:vD:tup:');

my $dbhost = $opt_H;
my $dbname = $opt_D;

my $DBPROFILE = $opt_p;
$DBPROFILE ||= 'default';
my $gmod_conf = Bio::GMOD::Config->new();
my $db_conf = Bio::GMOD::DB::Config->new( $gmod_conf, $DBPROFILE );

$dbhost ||= $db_conf->host();
$dbname ||= $db_conf->name();

if (!$dbhost && !$dbname) { die "Need -D dbname and -H hostname arguments.\n"; }

my $error = 0; # keep track of input errors (in command line switches).
if (!$opt_D and !$dbname) { 
    print STDERR "Option -D required. Must be a valid database name.\n";
    $error=1;
}

if (!$opt_F) { $opt_F="obo"; }

if ($opt_t) { 
    print STDERR "Trial mode - rolling back all changes at the end.\n";
}

if (!$opt_d) { $opt_d="GO"; } # the database name that Dbxrefs should refer to
print STDERR "Default for -d: $opt_d (specifies the database names for Dbxref objects)\n";

print STDERR "Default for -F: File format set to $opt_F\n";

my $file = shift;

if (!$file) { 
    print STDERR "A file is required as a command line argument.\n";
    $error=1;
}


die "Some required command lines parameters not set. Aborting.\n" if $error;

if ($opt_o) { open (OUT, ">$opt_o") ||die "can't open error file $opt_o for writting.\n" ; }


my $dbh = CXGN::DB::InsertDBH->new( { dbhost=>$dbhost,
				      dbname=>$dbname,  
                                      #dbprofile=>$DBPROFILE,
				   } );


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
    #check if relationship ontology is already loaded:
    if ($new_ont_name ne 'relationship') {
	my $rel_cv= CXGN::Chado::Ontology->new_with_name($dbh, 'relationship');
	my @rel=$rel_cv->get_predicate_terms();
	if (!@rel) {
	    warn "Relationship ontology must be loaded first!!\n" ;
	    exit(0);
	}
    }
    #add Typedef parsing to obo.pm!

    my $cv = CXGN::Chado::Ontology->new_with_name($dbh, $new_ont->name()); # also get a CXGN::Chado::Ontology object for the cv_id (see later).
    #store a new cv if the ontology namespace does not exist
    if (!$cv->get_cv_id() ) { 
	$cv->name($new_ont_name);
	$cv->store();
    }
    print STDERR "cv_id = ".($cv->get_cv_id())."\n";
    
    my $db_ont;
    
    
    print STDERR "Updating an ontology in the database...\n";
    $db_ont = CXGN::Chado::Ontology->new_with_name($dbh, $new_ont->name());
    my $ontology_name=$db_ont->name();
    message("Ontology name: ".($db_ont->name())."\n", 1);
    
    my %file_relationships = (); # relationships currently defined in the file
    my %db_relationships = ();
    
    eval { 
	print STDERR "Getting all the terms of the new ontology...\n";
	my (@all_file_terms) = $new_ont->get_all_terms();
	my (@all_file_predicate_terms) = $new_ont->get_predicate_terms();
	#my (@all_file_typedefs) = $new_ont->get_all_typedefs();
	message( "***found ".(scalar(@all_file_predicate_terms))." predicate terms!.\n", 1);
	
	message( "Retrieved ".(scalar(@all_file_terms))." terms.\n", 1);
        
	#look at all predecate terms (Typedefs)
	my @all_db_predicate_terms = $db_ont->get_predicate_terms();
	foreach my $t(@all_file_predicate_terms) {           #look at predicate terms in file
	    #if (!grep (/^$t$/, @all_db_predicate_terms ) ) { #didn't find predicate term in this cv in the database
	    my $p_term= CXGN::Chado::Cvterm::get_cvterm_by_name($dbh, $t->name(), '1');
	    my $is_rel= $p_term->get_is_relationshiptype(); 
	    if ( ($p_term->get_cv_id() && $p_term->get_is_relationshiptype()eq '1' ) ) {    #maybe it's stored with another cv_id?
		message("predicate term '" .$t->name() . "' already exists with cv_id " . $p_term->get_cv_id() . "\n", 1);
	    }else { 
		my $cv = CXGN::Chado::CV->new_with_name($dbh, $new_ont_name);
		my $cv_id= $cv->get_cv_id();
		#message("*!for ontology '$new_ont_name' the cv_id is $cv_id \n");
		if (!$cv_id) { 
		    $cv->set_cv_name("relationship");
		    message("*!No cv found for $new_ont_name. Using 'relationship' namespace instead\n ");
		    $cv_id= $cv->store();
		}
		#this stores the relationship types under 'relationship' cv namespace
		#terms defined as '[Typedef]' in the obo file should actually be stored as relationshiptype
		#but with the current ontology cv namespace .
		#To do this we need to add to the obo parser (Bio::OntologyIO::obo.pm)
		#a 'get_typedefs' funciton
		
		if (($cv->get_cv_name()) eq 'relationship' ) { $p_term->set_db_name('OBO_REL'); } 
		else { $p_term->set_db_name($opt_d); }
		
		$p_term->name($t->name() );
		$p_term->identifier($t->identifier()) || $p_term->identifier($t->name() );
		$p_term->definition( $t->definition() );
		$p_term->version( $t->version() );
		my $ontology= $t->ontology()->name();
		$p_term->set_obsolete($t->is_obsolete() );
		$p_term->set_is_relationshiptype('1');
		$p_term->set_cv_id($cv_id);
		$p_term->store();
		message("Stored new relationshiptype '" .  $t->name() . "'\n",1);
	    }
	    # }
	}
	
	print STDERR "Getting all the terms of the current ontology...\n";
	
	my @all_db_terms = $db_ont->get_all_terms(); # a list of cvterm objects
		
	print STDERR "Indexing terms and relationships...\n";
	my %file_index = ();  # index of term objects in the db with accession as key
	my %db_index = (); # this hash will be populated with accession => cvterm_object
	
	foreach my $t (@all_file_terms) { 
	    my $id = $t->identifier();
	    $id=~ s/\w+\:(.*)/$1/g;
	    $file_index{$id} = $t;
	}
	
	my $c_count = 0;  # count of db terms    
	foreach my $t (@all_db_terms) { 
	    $c_count++;
	    my $id = $t->identifier();
	    $id=~ s/\w+\:(.*)/$1/g;
	    $db_index{$id} = $t;
	}
	
	
	my %novel_terms = ();
	my @removed_terms = ();
	my @novel_relationships = ();
	my @removed_relationships = ();
	
	
	print STDERR "Determining which terms are new...\n";
	#exit();
	
	FILE_INDEX: foreach my $k (keys(%file_index)) { 
	    #print STDERR "Checking $k...\n";
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
		message( "Term not in file: $k\n",1);
	
		my $name = $db_index{$k}->name(); #get the name in the database 
		
		unless( $name =~ m/obsolete.*$opt_d:$k/ ) {
		    my $ob_name = $name . " (obsolete " . $opt_d . ":" . $k . ")" ;  #add the 'obsolete' suffix 
		    $db_index{$k}->name($ob_name );
		    message( "**modified name for $opt_d:$k - '$ob_name' \n " , 1); 
		}
		$db_index{$k}->set_obsolete("1");
		$db_index{$k}->store();
		
		print STDERR " obsoleted term $k!.\n";
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
		    $db_index{$k}->name($file_index{$k}->name());
		    $db_index{$k}->definition($file_index{$k}->definition());
		    $db_index{$k}->comment($file_index{$k}->comment());
		    $db_index{$k}->set_obsolete($file_index{$k}->is_obsolete());
		    $db_index{$k}->version($file_index{$k}->version());
		    my $name = $db_index{$k}->name();
		    #changing the name of obsolete terms to "$name (obsolete $db:$accession)"
		    #to avoid violating the cvterm unique constaint (name, cv_id, is_obsolete)
		    if ($db_index{$k}->get_obsolete() ) { 
			unless( $name =~ m/obsolete.*$opt_d:$k/ ) {
			    my $ob_name = $name . " (obsolete " . $opt_d . ":" . $k . ")" ;  
			    $db_index{$k}->name($ob_name );
			    print STDERR "**modified name for $opt_d:$k - '$ob_name' version: " . $db_index{$k}->version()." \n " ; 
			}
		    }
		    $db_index{$k}->store();
		    
		    # deal with synonyms here... 
		    my %file_synonyms = ();
		    foreach my $s ($file_index{$k}->get_synonyms()) { 
			$s=~ s/\s+$//; 
			$s =~ s/\\//g;
			$file_synonyms{uc($s)}=1;
			
			message("...adding synonym  '$s'  to the database...\n");
					
			$db_index{$k}->add_synonym($s);
		    }
		    
		    foreach my $s ($db_index{$k}->get_synonyms()) { 
			if (!exists($file_synonyms{uc($s)}) ) { 
			    message( "Note: deleting synonym '$s' from cvterm ". $db_index{$k}->get_cvterm_name(). "...\n",1);
			    $db_index{$k}->delete_synonym($s);
			}
		    }
		    #deal with secondary ids (alt_id field).
		    # Stored in cvterm_dbxref with the field 'is_for_definition' = 0
		    my %file_secondary_ids = ();
		    foreach my $i ($file_index{$k}->get_secondary_ids()) { 
			$file_secondary_ids{uc($i)}=1;
			message("adding secondary id $i to the database...\n");
						
			$db_index{$k}->add_secondary_dbxref($i);
			
		    }
		    foreach my $i ($db_index{$k}->get_secondary_dbxrefs()) {
			if (!exists($file_secondary_ids{uc($i)})) { 
			    message( "Note: deleting secondary id $i from cvterm_dbxref...\n",1);
			    $db_index{$k}->delete_secondary_dbxref($i);
			}
		    }
		    # Definition dbxrefs. get_dblinks gets the dbxref in the definition tag
		    # and all xref_analog tags. This will store in the database cvterm_dbxrefs with 
		    #the fiels 'is_for_definition' = 1 
		    my %file_def_dbxrefs=();
		    foreach my $r ($file_index{$k}->get_dblinks() ) { #store definition's dbxrefs in cvterm_dbxref
			#my $id= $r->primary_id();
			#my $db= $r->database();
			my ($db, $id) = split /:/, $r;
			my $def_dbxref= $db . ":" . $id;
			$file_def_dbxrefs{uc($def_dbxref)}=1;
			message("adding definition dbxref $db:$id to cvterm_dbxref\n");
						
			$db_index{$k}->add_def_dbxref($db, $id); 
		    }
		    my @def_dbxrefs = $db_index{$k}->get_def_dbxref();
		    foreach my $r (@def_dbxrefs) {
			if ($r->get_dbxref_id()) {
			    my $db= $r->get_db_name();
			    my $acc=$r->get_accession();
			    my $def_dbxref=$db . ":" . $acc;
			    if (!exists($file_def_dbxrefs{uc($def_dbxref)})) { 
				message( "Note: deleting definition dbxref '$def_dbxref' from cvterm_dbxref...\n",1);
				$db_index{$k}->delete_def_dbxref($r);
			    }
			}
		    }
		}
	    }
	} #finished updating existing terms..
	#now insert the new ones:
	my $n_count=0;
	foreach my $k (keys(%novel_terms)) {
	    $n_count++;
	    my $new_term = CXGN::Chado::Cvterm->new($dbh);
	    my $name = $novel_terms{$k}->name();
	    $new_term->name($name);
	    $new_term->identifier(numeric_id($novel_terms{$k}->identifier()));
	    $new_term->definition($novel_terms{$k}->definition());
	    $new_term->version($novel_terms{$k}->version());
	    $new_term->set_db_name($opt_d);
	    $new_term->set_cv_id($cv->get_cv_id());
	    $new_term->set_obsolete($novel_terms{$k}->is_obsolete());
	    
	    #changing the name of obsolete terms to "$name (obsolete $db:$accession)"
	    #to avoid violating the cvterm unique constaint (name, cv_id, is_obsolete)
	    if ($novel_terms{$k}->is_obsolete() ) {
		unless( $name =~ m/obsolete.*$opt_d:$k/i ) {
		    my $ob_name = $name . " (obsolete " . $opt_d . ":" . $k . ")" ;  
		    $novel_terms{$k}->name($ob_name );
		    $new_term->name($ob_name);
		    print STDERR "**modified name for $opt_d:$k - '$ob_name' \n " ; 
		}
	    }
	    message("Storing term $k...name = " . $novel_terms{$k}->name() . "\n"); 
	    
	    if (!$opt_t) { 
		if ($count % 100==0)  { print STDERR "."; }
		$new_term->store();
		$new_term->comment($novel_terms{$k}->comment()); #store comment in cvterm_prop
		
		foreach my $s ($novel_terms{$k}->get_synonyms()) { #store synonyms in cvtermsynonym
		    $s=~ s/\s+$//; 
		    $s =~ s/\\//g;
		    message("...adding synonym  '$s'  to the database...\n");
		    $new_term->add_synonym($s);  #need to add a type_id to each synonym!
		}
		
		foreach my $i ($novel_terms{$k}->get_secondary_ids()) { #store secondary ids in cvterm_dbxref
		    message("adding secondary dbxref '$i' to cvterm_dbxref\n");
		    		    
		    $new_term->add_secondary_dbxref($i);
		}
		foreach my $r ($novel_terms{$k}->get_dblinks() ) { #store definition's dbxrefs in cvterm_dbxref
		    #my $id= $r->primary_id();
		    #my $db= $r->database();
		    my ($db, $id) = split /:/, $r;
		    my $def_dbxref= $db . ":" . $id;
		    #$file_def_dbxrefs{uc($def_dbxref)}=1;
		    message("adding definition dbxref $db:$id to cvterm_dbxref\n");
		    		    
		    $new_term->add_def_dbxref($db, $id);
		}
	    }
	}   
	
	
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
		my $key = numeric_id($s->identifier())."-".numeric_id($o->identifier());
		message("Looking at relationship in file: $key\n" );
		if ($t_count % 100==0) { message("."); }
		$file_relationships{$key} = $r; # create the hash entry for this relationship	
	    }
	}
	print STDERR "\n";
	print STDERR "Looking at relationships in database.\n";

	# indexing the database relationships
	foreach my $k (keys %db_index) {     
	    foreach my $r ($db_ont->get_relationships($db_index{$k})) { 
		my $s = $r->subject_term();
		my $o = $r->object_term();
		
		my $key = numeric_id($s->identifier())."-".numeric_id($o->identifier());
		message("Looking at relationship in db: $key\n");
		$db_relationships{$key}=$r;
	    }
	}
	
			
	print STDERR "Relationships not in the file...\n";
	
	foreach my $k (keys(%db_relationships)) { 
	    if (!(exists($file_relationships{$k}) && defined($file_relationships{$k}))) { 
		push @removed_relationships, $k;
		message("Deleted relationship: $k... \n",1);
	
		$db_relationships{$k}->delete();
		print STDERR "gone.\n";
	    }
	}
	
	print STDERR "\n";
	#message(scalar(@novel_terms). " novel terms (of ".(scalar(keys(%db_terms))).") were found and stored. \n", 1);
	
	my $r_count = 0;
	RELATIONSHIP: foreach my $r (keys(%file_relationships)) { 
	    $r_count++;
	    if (!exists($db_relationships{$r})) {
		if ($opt_v) { print STDERR "Novel relationship: $r\n"; }
		elsif ($r_count % 100 == 0) { print STDERR "."; } 
		print OUT "Novel relationship: $r\n" if $opt_o;
		
		# create a new relationship object
		my $new_rel = CXGN::Chado::Relationship->new($dbh);
		
		# convert the Bio::Ontology::OBOTerm objects to CXGN::Chado::Cvterm objects
		my $subject_term = CXGN::Chado::Cvterm->new_with_accession($dbh, $file_relationships{$r}->subject_term()->identifier());
		if (!$subject_term->get_cvterm_id() ) { message("cvterm does not exist for subject term " . $file_relationships{$r}->subject_term()->identifier() . " Skipping...\n" ,1); next RELATIONSHIP; }
		$new_rel->subject_term($subject_term);
		print STDERR "subject term: " . $file_relationships{$r}->subject_term()->identifier()."\n";
		
		my $object_term = CXGN::Chado::Cvterm->new_with_accession($dbh, $file_relationships{$r}->object_term()->identifier);
		if (!$object_term->get_cvterm_id() ) { message("cvterm does not exist for object term " . $file_relationships{$r}->object_term()->identifier() ,1); next RELATIONSHIP;}
		$new_rel->object_term($object_term);
		
		push @novel_relationships, $r;
		my $predicate_term_name = $file_relationships{$r}->predicate_term()->name();
		my $rel_cv_id= CXGN::Chado::Ontology->new_with_name($dbh, "relationship")->identifier();
		my $cv_id= $db_ont->identifier();
		
		my $predicate_term = CXGN::Chado::Cvterm->new_with_accession($dbh, "OBO_REL:$predicate_term_name");
		if (!$predicate_term->get_cvterm_id()) {
		    $predicate_term=CXGN::Chado::Cvterm->new_with_term_name($dbh, $predicate_term_name, $cv_id);
		    if (!$predicate_term->get_cvterm_id()) { 
			die "The predicate term $predicate_term_name does not exist in the database\n";  
		    }
		}
		$new_rel->predicate_term($predicate_term);
		if (!$opt_t) { 
		    message("Storing relationship $r. type cv_id=" . $predicate_term->get_cv_id() ."\n" ,1); 
		    $new_rel->store();
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
    if ($opt_v || $default) {  print STDERR "$message"; }
    print OUT "$message" if $opt_o;
}

sub numeric_id { 
    my $id = shift;
    $id =~ s/.*\:(.*)$/$1/g;
    return $id;
}
