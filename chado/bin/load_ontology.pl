#!/usr/bin/perl

use strict;

use DBI;
use Data::Dumper;
use Chado::AutoDBI;
use Bio::OntologyIO;
use Bio::Ontology::TermFactory;

#######################################
# COPYRIGHT
#######################################
#
# This software is free.  You can use it under the terms of the 
# Perl Artistic License.
#
# Allen Day <allenday@ucla.edu>
# October 2, 2003

#######################################
# INITIALIZATION
#######################################

#perl pgload_so2.pl user dbname SODA.ontology SODA.defs
my ($user, $dbname, $ontology_file, $ontology_deffile) = @ARGV;

#allow non-existant defsfile for this one
die "USAGE: $0 <username> <dbname> <dagedit file> (defs file)" unless $user and $dbname and $ontology_file;

Chado::DBI->set_db('Main',
		   "dbi:Pg:dbname=$dbname",
		   "$user",
		   "",
#		   {AutoCommit => 1}
		  ) or die "set_db failed";

warn "ontology_file:$ontology_file\n";

#######################################
# SET UP GLOBAL VARS
#######################################
my $ontology_file2 = $ontology_file;
$ontology_file2 =~ s!.+/(.+)!$1!;

#infer the name of the ontology based on the file name.  this may be unreliable.

my $ontname = $ontology_file2 =~ /^EMAP/            ? "Mouse Embryo Anatomy Ontology" :
              $ontology_file2 =~ /^MA/              ? "Mouse Adult Anatomy Ontology" :
              $ontology_file2 =~ /^mouse_pathology/ ? "Mouse Pathology Ontology (Pathbase)" :
              $ontology_file2 =~ /^rel/             ? "Relationship Ontology" :
              $ontology_file2 =~ /^component/       ? "Gene Ontology" :
              $ontology_file2 =~ /^function/        ? "Gene Ontology" :
              $ontology_file2 =~ /^process/         ? "Gene Ontology" :
              $ontology_file2 =~ /^cell_type/       ? "eVOC Cell Type Ontology" :
              $ontology_file2 =~ /^cell/            ? "Cell Ontology" :
              $ontology_file2 =~ /^pathology/       ? "eVOC Pathology Ontology" :
              $ontology_file2 =~ /^SODA/            ? "Sequence Ontology" :
              undef;

die "no ontology name defined for $ontology_file2!" unless defined($ontname);

#we see all of these, apparently it's not standardized yet.  map relationship
#types to stable Relationship Ontology IDs

my %predmap = ( 'isa'           => 'OBO_REL:0002',
		'is_a'          => 'OBO_REL:0002',
		'is a'          => 'OBO_REL:0002',
		'partof'        => 'OBO_REL:0003',
		'part_of'       => 'OBO_REL:0003',
		'part of'       => 'OBO_REL:0003',
		'developsfrom'  => 'OBO_REL:0004',
		'develops_from' => 'OBO_REL:0004',
		'develops from' => 'OBO_REL:0004',
		'REL:0005'      => 'OBO_REL:0005',
		'rel:0005'      => 'OBO_REL:0005',
		'REL:0001'      => 'OBO_REL:0001',
		'rel:0001'      => 'OBO_REL:0001',
	      );

#create some default entries to satisfy chado FK requirements of ontology on contact and db tables

warn "getting info from Class::DBI\n";

my($nullcontact) = Chado::Contact->find_or_create({ name => 'null', description => 'null' });

warn "getting db\n";

my($db) = Chado::Db->find_or_create({name => $ontname, contact_id => $nullcontact->id});

warn "getting cv_db\n";

my($cv_db) = Chado::Cv->find_or_create({name => $ontname});

warn "Creating Ontology objects...\n";

my $termfact = Bio::Ontology::TermFactory->new();
my $relfact = Bio::Ontology::RelationshipFactory->new();

#decide what format we need.  simple indented file or DAG-Edit ?
my $format = $ontname =~ 'eVOC' ? 'simplehierarchy' : 'so';

warn "starting parser...\n";
my $parser = Bio::OntologyIO->new(
			  -term_factory => $termfact,
			  -format => $format,
			  -indent_string => ',',
			  -ontology_name => $ontname,
			  -defs_file => $ontology_deffile,
			  -files => $ontology_file
				 );

my %allterms;
my %predicateterms;
my %allrels;

#parse the ontologies
while (my $ont = $parser->next_ontology()) {

  warn "parsing ontology...\n";
  $ont->relationship_factory($relfact);
  warn "...terms...\n";
  load_ontologyterms($ont);
  warn "...relationships...\n";
  load_ontologyrels($ont);

}
##############
# SUBROUTINES
##############

sub load_ontologyterms{
  my $ontref = shift;

  warn "in loading term\n";

  my @predicates = $ontref->get_predicate_terms();
  my @roots = $ontref->get_root_terms();

  #load edge terms
  foreach my $predicate (@predicates) {
	print STDERR "this is a predicate: ", lc($predicate->identifier) , "\n";

	#we can't use find_or_create here because the name may already be assigned another cv_id...

	my($predicate_db) = Chado::Cvterm->search(name =>predmap($predicate->name));
	if(!$predicate_db){
		$predicate_db = Chado::Cvterm->create({
		  name =>predmap($predicate->name),
		  cv_id => $cv_db->id,
		 });
	}
	
	$predicateterms{predmap($predicate->name)} = $predicate_db->id;
	$predicate_db->definition($predicate->name) unless defined($predicate_db->definition);
	$predicate_db->update;

	load_synonyms($predicate,$predicate_db);
	load_dblinks($predicate,$predicate_db);
  }

  #load root terms
  foreach my $root (@roots) {
	my $root_db = Chado::Cvterm->find_or_create ({
		  name => predmap($root->identifier),
		  cv_id => $cv_db->id
		 });
	$root_db->definition($root->name) unless defined($root_db->definition);
	$root_db->update;

	$allterms{$root->name} = $root_db->id;

	load_synonyms($root,$root_db);
	load_dblinks($root,$root_db);

	#and recurse down the dag
	load_ontologytermsR($ontref, $root, "\t");
  }
}

#usage: load_ontologytermsR($ontref, $root)
sub load_ontologytermsR {
  my $ontref = shift;
  my $parent = shift;
  my $tab = shift;

  my @children = $ontref->get_child_terms($parent);
  foreach my $child (@children) {
	if (!(exists $allterms{$child->name})) {
	print "$tab", $child->name , "\n";
	  my $child_db = Chado::Cvterm->find_or_create({
		name => predmap($child->identifier),
		cv_id => $cv_db->id,
	   });

	  $child_db->definition($child->name) unless defined($child_db->definition);
	  $child_db->update;

	  $allterms{$child->name} = $child_db->id;

	  load_synonyms($child,$child_db);
	  load_dblinks($child,$child_db);

	  load_ontologytermsR($ontref, $child, $tab . "\t");
	}
  }
}

sub load_ontologyrels {
  my $ontref = shift;

  my @relationships = $ontref->get_relationships();

  foreach my $relationship (@relationships) {

	my $skip = 0;

	my $obj = $relationship->object_term();
	my $subj = $relationship->subject_term();
	my $pred = $relationship->predicate_term();

	my $pred_id = $predicateterms{predmap($pred->name)};
	my $subj_id = $allterms{$subj->name};
	my $obj_id  = $allterms{$obj->name};


	if(!defined $pred_id){
		warn "pred! ".$pred->name;
		$skip++;
	}

	if (!(exists $allrels{$obj->name . $subj->name . $pred->name})) {

	  $allrels{$obj->name . $subj->name . $pred->name} = $relationship;

	  warn "subj! ".$subj->name and $skip++ unless defined $subj_id;
	  warn "obj!  ".$obj->name  and $skip++ unless defined $obj_id;

	  next if $skip;

	  Chado::Cvterm_Relationship->find_or_create ({
										  subject_id => $subj_id,
										  object_id => $obj_id,
										  type_id => $pred_id,
										 });
	}								
  }
}

sub predmap {
  my $term = shift;
  return $predmap{lc($term)} ? $predmap{lc($term)} : $term;
}

sub load_dblinks {
  my $term = shift;
  my $term_db = shift;

  my @term_links = $term->get_dblinks();
  foreach my $term_link (@term_links) {
	my $dbxref_db = Chado::Dbxref->find_or_create ({
													accession => $term_link,
													db_id => $db->id,
													version => 0
												   });

	Chado::Cvterm_Dbxref->find_or_create ({
										   cvterm_id => $term_db->id,
										   dbxref_id => $dbxref_db->id
										  });
  }
}

sub load_synonyms {
  my $term = shift;
  my $term_db = shift;

  my @term_syns = $term->get_synonyms();
  foreach my $term_syn (@term_syns) {

#	Chado::Cvtermsynonym->find_or_create ({
#						cvterm_id => $term_db->id,
#						synonym => $term_syn,
#					     });
	Chado::Cvtermsynonym->find_or_create ({
						cvterm_id => $term_db->id,
						synonym => $term_syn,
					     });
  }
}

__END__

=head1 NAME

load_ontology.pl - load DAG-Edit or simple indented hierarchy ontology files into a Chado database.

=head1 SYNOPSIS

#with a definitions file...
/usr/bin/perl load_ontology.pl $USER database_name SODA.ontology SODA.defs

#...and without
/usr/bin/perl load_ontology.pl $USER database_name cell.ontology

=head1 DESCRIPTION

this script relies on three external modules:

=item Bio::OntologyIO (available from Bioperl)

=back

=item Chado::AutoDBI  (generated from chado/complete.sql using chado/bin/pg2cdbi.pl)

=back

=item SQL::Translator required to generate Chado::AutoDBI

=back

=head1 KNOWN BUGS

may not load data into the fields you'd like.  we need to establish a SOP as to what data goes where
in Chado from a DAG-Edit file.

=head1 AUTHOR

Allen Day E<lt>allenday@ucla.eduE<gt>

Copyright 2002-2003
