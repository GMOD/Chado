
=head1 NAME

load_cvterms.pl

=head1 DESCRIPTION

Usage: perl load_cvterms.pl -H dbhost -D dbname [-vDnFo] file

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

Version 0.12, February 2007.

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

if ($opt_o) { open (OUT, ">$opt_o") ||die "can't open error file $file for writting.\n" ; }


my $dbh = CXGN::DB::InsertDBH->new( { dbhost=>$dbhost,
				      dbname=>$dbname,  
                                      dbprofile=>$DBPROFILE,
				   } );


print STDERR "Connected to database $dbname on host $dbhost.\n";
print OUT "Connected to database $dbname on host $dbhost.\n" if $opt_o;


print STDERR "Parsing the ontology $file...\n";
my $parser="";
$parser = Bio::OntologyIO->new( -file => $file, -format=>$opt_F );

#my $new_ont;
my @onts = ();
while( my $ont = $parser->next_ontology() ) {
    push @onts, $ont;
}
#$new_ont = $onts[-1];

foreach my $new_ont(@onts) {
    my $new_ont_name=$new_ont->name();
    print STDERR "....found namespace  '$new_ont_name' \n"; 
    
    if ($opt_n && ( $opt_n ne $new_ont_name) ) { print STDERR "$opt_n: skipping to next ontology..\n"; next (); } 
    
    my $cv = CXGN::Chado::Ontology->new_with_name($dbh, $new_ont->name()); # also get a CXGN::Chado::Ontology object for the cv_id (see later).
    print STDERR "cv_id = ".($cv->get_cv_id())."\n";
    
    my $db_ont;
    
    
    print STDERR "Updating an ontology in the database...\n";
    $db_ont = CXGN::Chado::Ontology->new_with_name($dbh, $new_ont->name());
    my $ontology_name=$db_ont->name();
    print STDERR "Ontology name: ".($db_ont->name())."\n";
    print OUT "Ontology name: ".($db_ont->name())."\n" if $opt_o;

    
    my %file_relationships = (); # relationships currently defined in the file
    my %db_relationships = ();
    
    eval { 
	print STDERR "Getting all the terms of the new ontology...\n";
	my (@all_file_terms) = $new_ont->get_all_terms();
	my (@all_file_predicate_terms) = $new_ont->get_predicate_terms();
	print STDERR "***found ".(scalar(@all_file_predicate_terms))." predicate terms!.\n";
	
	print STDERR "Retrieved ".(scalar(@all_file_terms))." terms.\n";
	print OUT "Retrieved ".(scalar(@all_file_terms))." terms.\n" if $opt_o;
	
	#look at all predecate terms (Typedefs)
	my @all_db_predicate_terms = $db_ont->get_predicate_terms();
	foreach my $t(@all_file_predicate_terms) {           #look at predicate terms in file
	    if (!grep (/^$t$/, @all_db_predicate_terms ) ) { #didn't find predicate term in this cv in the database
		my $p_term= CXGN::Chado::Cvterm::get_cvterm_by_name($dbh, $t->name());
		if ( ($p_term->get_cv_id()) ) {    #maybe it's stored with another cv_id?
		    print STDERR "predicate term '" .$t->name() . "' already exists with cv_id " . $p_term->get_cv_id() . "\n";
		    print OUT "predicate term already exists with cv_id " . $p_term->get_cv_id() . "\n" if $opt_o;
		}else { 
		    my $cv = CXGN::Chado::CV->new_with_name($dbh, $new_ont_name);
		    my $cv_id= $cv->get_cv_id();
		    if (!$cv_id) { 
			$cv->set_cv_name("relationship");
			$cv_id= $cv->store();
		    }
		    if (($cv->get_cv_name()) eq 'relationship' ) { $p_term->set_db_name('OBO_REL'); }
		    else { $p_term->set_db_name($opt_d); }
 
		    $p_term->name($t->name() );
		    $p_term->identifier($t->identifier()) || $p_term->identifier($t->name() );
		    $p_term->definition( $t->definition() );
		    my $ontology= $t->ontology()->name();
		    $p_term->set_obsolete($t->is_obsolete() );
		    $p_term->set_is_relationshiptype(1);
		    $p_term->set_cv_id($cv_id);
		    $p_term->store();
		    print STDERR "Stored new relationshiptype '" .  $t->name() . "'\n";
		    print OUT "Stored new relationshiptype '" .  $t->name() . "'\n" if $opt_o;
		}
	    }
	}

	print STDERR "Getting all the terms of the current ontology...\n";
	
	my @all_db_terms = $db_ont->get_all_terms();

	print STDERR "Indexing terms and relationships...\n";
	my %file_index = ();  # index of term objects in the db with accession as key
	my %db_index = ();
	
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
	
	
	foreach my $k (keys(%file_index)) { 
	    #print STDERR "Checking $k...\n";
	    if (!exists($db_index{$k})) { 
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
		print STDERR "Term not in file: $k\n";
		print OUT "Term not in file: $k\n" if $opt_o;
		my $name = $db_index{$k}->name(); #get the name in the database 
		
		unless( $name =~ m/obsolete.*$opt_d:$k/ ) {
		    my $ob_name = $name . " (obsolete " . $opt_d . ":" . $k . ")" ;  #add the 'obsolete' suffix 
		    $db_index{$k}->name($ob_name );
		    print STDERR "**modified name for $opt_d:$k - '$ob_name' \n " ; 
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
	foreach my $k (keys(%file_index)) {
	    $count++;
	    if (!exists($novel_terms{$k})) { 
		#update the term if run with -u option.
		
		if ($opt_u) {
		    $u_count++;
		    $db_index{$k}->name($file_index{$k}->name());
		    $db_index{$k}->definition($file_index{$k}->definition());
		    $db_index{$k}->comment($file_index{$k}->comment());
		    $db_index{$k}->set_obsolete($file_index{$k}->is_obsolete());
		    message( "updating information for term $k...\n");
		    print OUT "*updating information for term " . $k  . "*\n" if $opt_o;
		    my $name = $db_index{$k}->name();
		    #changing the name of obsolete terms to "$name (obsolete $db:$accession)"
		    #to avoid violating the cvterm unique constaint (name, cv_id, is_obsolete)
		    if ($db_index{$k}->get_obsolete() ) { 
			unless( $name =~ m/obsolete.*$opt_d:$k/ ) {
			    my $ob_name = $name . " (obsolete " . $opt_d . ":" . $k . ")" ;  
			    $db_index{$k}->name($ob_name );
			    print STDERR "**modified name for $opt_d:$k - '$ob_name' \n " ; 
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
			print OUT "...adding synonym  '$s'  to the database...\n" if $opt_o;
			
			$db_index{$k}->add_synonym($s);
		    }
		    
		    foreach my $s ($db_index{$k}->get_synonyms()) { 
			if (!exists($file_synonyms{uc($s)}) ) { 
			    print STDERR "Note: deleting synonym '$s' from cvterm ". $db_index{$k}->get_cvterm_name(). "...\n";
			    print OUT "Note: deleting synonym '$s' from cvterm ". $db_index{$k}->get_cvterm_name(). "...\n" if $opt_o;
			    $db_index{$k}->delete_synonym($s);
			}
		    }
		    #deal with secondary ids (alt_id field).
		    # Stored in cvterm_dbxref with the field 'is_for_definition' = 0
		    my %file_secondary_ids = ();
		    foreach my $i ($file_index{$k}->get_secondary_ids()) { 
			$file_secondary_ids{uc($i)}=1;
			message("adding secondary id $i to the database...\n");
			print OUT "adding secondary id $i to the database...\n" if $opt_o;
			
			$db_index{$k}->add_secondary_dbxref($i);
			
		    }
		    foreach my $i ($db_index{$k}->get_secondary_dbxrefs()) {
			if (!exists($file_secondary_ids{uc($i)})) { 
			    print STDERR "Note: deleting secondary id $i from cvterm_dbxref...\n";
			    print OUT "Note: deleting secondary id $i from cvterm_dbxref...\n" if $opt_o;
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
			print OUT "adding definition dbxref $db:$id to cvterm_dbxref\n" if $opt_o;
			
			$db_index{$k}->add_def_dbxref($db, $id); 
		    }
		    my @def_dbxrefs = $db_index{$k}->get_def_dbxref();
		    foreach my $r (@def_dbxrefs) {
			if ($r->get_dbxref_id()) {
			    my $db= $r->get_db_name();
			    my $acc=$r->get_accession();
			    my $def_dbxref=$db . ":" . $acc;
			    if (!exists($file_def_dbxrefs{uc($def_dbxref)})) { 
				print STDERR "Note: deleting definition dbxref '$def_dbxref' from cvterm_dbxref...\n";
				print OUT "Note: deleting definition dbxref '$def_dbxref' from cvterm_dbxref...\n" if $opt_o;
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
	    $new_term->set_db_name($opt_d);
	    $new_term->set_cv_id($cv->get_cv_id());
	    $new_term->set_obsolete($novel_terms{$k}->is_obsolete());
	    
	    #changing the name of obsolete terms to "$name (obsolete $db:$accession)"
	    #to avoid violating the cvterm unique constaint (name, cv_id, is_obsolete)
	    if ($novel_terms{$k}->is_obsolete() ) {
		unless( $name =~ m/obsolete.*$opt_d:$k/ ) {
		    my $ob_name = $name . " (obsolete " . $opt_d . ":" . $k . ")" ;  
		    $novel_terms{$k}->name($ob_name );
		    print STDERR "**modified name for $opt_d:$k - '$ob_name' \n " ; 
		}
	    }
	    if ($opt_v) { print STDERR "Storing term $k...\n"; }
	    print OUT "Storing term $k...\n" if $opt_o;
	    
	    if (!$opt_t) { 
		if ($count % 100==0)  { print STDERR "."; }
		$new_term->store();
		$new_term->comment($novel_terms{$k}->comment()); #store comment in cvterm_prop
		
		foreach my $s ($novel_terms{$k}->get_synonyms()) { #store synonyms in cvtermsynonym
		    $s=~ s/\s+$//; 
		    $s =~ s/\\//g;
		    message("...adding synonym  '$s'  to the database...\n");
		    print OUT "...adding synonym  '$s'  to the database...\n" if $opt_o;
		    $new_term->add_synonym($s);  #need to add a type_id to each synonym!
		}
		
		foreach my $i ($novel_terms{$k}->get_secondary_ids()) { #store secondary ids in cvterm_dbxref
		    message("adding secondary dbxref '$i' to cvterm_dbxref\n");
		    print OUT "adding secondary dbxref '$i' to cvterm_dbxref\n" if $opt_o;
		    
		    $new_term->add_secondary_dbxref($i);
		}
		foreach my $r ($novel_terms{$k}->get_dblinks() ) { #store definition's dbxrefs in cvterm_dbxref
		    #my $id= $r->primary_id();
		    #my $db= $r->database();
		    my ($db, $id) = split /:/, $r;
		    my $def_dbxref= $db . ":" . $id;
		    #$file_def_dbxrefs{uc($def_dbxref)}=1;
		    message("adding definition dbxref $db:$id to cvterm_dbxref\n");
		    print OUT "adding definition dbxref $db:$id to cvterm_dbxref\n" if $opt_o;
		    
		    $new_term->add_def_dbxref($db, $id);
		}
	    }
	}   
	
	
	print STDERR "Updated $u_count existing terms, inserted $n_count new terms!\n";
	print OUT "Updated $u_count existing terms, inserted $n_count new terms!\n";

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
		message("Looking at relationship in file: $key\n");
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
		print STDERR "Deleted relationship: $k... \n";
		print OUT "Deleted relationship: $k... \n" if $opt_o;

		$db_relationships{$k}->delete();
		print STDERR "gone.\n";
	    }
	}
	
	
	
	
	print STDERR "\n";
#print STDERR scalar(@novel_terms). " novel terms (of ".(scalar(keys(%db_terms))).") were found and stored. \n";
	
	my $r_count = 0;
	foreach my $r (keys(%file_relationships)) { 
	    $r_count++;
	    if (!exists($db_relationships{$r})) {
		if ($opt_v) { print STDERR "Novel relationship: $r\n"; }
		elsif ($r_count % 100 == 0) { print STDERR "."; } 
		print OUT "Novel relationship: $r\n" if $opt_o;
		
		push @novel_relationships, $r;
		
		# create a new relationship object
		my $new_rel = CXGN::Chado::Relationship->new($dbh);
		
		# convert the Bio::Ontology::OBOTerm objects to CXGN::Chado::Cvterm objects
		my $subject_term = CXGN::Chado::Cvterm->new_with_term_name($dbh, $file_relationships{$r}->subject_term()->name(), $cv->get_cv_id());
		$new_rel->subject_term($subject_term);
		
		my $object_term = CXGN::Chado::Cvterm->new_with_term_name($dbh, $file_relationships{$r}->object_term()->name(), $cv->get_cv_id());
		$new_rel->object_term($object_term);
		
		my $predicate_term_name = $file_relationships{$r}->predicate_term()->name();
		my $cv_id= CXGN::Chado::CV->new_with_name($dbh, "relationship")->get_cv_id();
		if (!$cv_id) { $cv_id= CXGN::Chado::CV->new_with_name($dbh, $db_ont->name)->get_cv_id(); }
		
		my $predicate_term = CXGN::Chado::Cvterm->new_with_term_name($dbh, $predicate_term_name, $cv_id);
		if (!$predicate_term->get_cvterm_id()) { 
		    die "The predicate term $predicate_term_name does not exist in the database\n"; 
		}
		$new_rel->predicate_term($predicate_term);
		if ($opt_v) { print STDERR "Storing relationship $r. type cv_id=$cv_id\n"; }
		if (!$opt_t) { 
		    $new_rel->store();
		}
	    }   
	}
	print STDERR $ontology_name." : ". scalar(@novel_relationships)." novel relationships among ".(scalar(keys(%file_relationships)))." were found and stored.\n";
	print OUT $ontology_name ." : " . scalar(@novel_relationships)." novel relationships among ".(scalar(keys(%file_relationships)))." were found and stored.\n" if $opt_o;
    };
    
    if ($@ || ($opt_t)) { 
	print STDERR "Either running as trial mode (-t) or AN ERROR OCCURRED: $@\n"; 
	print OUT "Either running as trial mode (-t) or AN ERROR OCCURRED: $@\n" if $opt_o; 
	
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
    if ($opt_v) { 
	print STDERR "$message";
    }
}

sub numeric_id { 
    my $id = shift;
    $id =~ s/.*\:(\d+)$/$1/g;
    return $id;
}
