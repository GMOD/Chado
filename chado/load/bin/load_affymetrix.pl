#!/usr/bin/perl

use strict;
use lib 'lib';
use Chado::LoadDBI;
use Chado::AutoDBI;
use XML::Simple;
use Data::Dumper;

my $filename = shift;

die "USAGE: $0 <filename>" unless $filename;

open(my $fh,"zcat $filename |") or die "couldn't open file $filename : $!";

Chado::LoadDBI->init();

my %DATABASE = ();
my $database_sequence = 0;

my $nullcv      = Chado::Cv->find_or_create({ name => 'null' });
my $nullcontact = Chado::Contact->find_or_create({ description => 'null' });
my $nulldb      = Chado::Db->find_or_create({ contact_id => $nullcontact->id, name => 'null' });
my $nulldbxref  = Chado::Dbxref->find_or_create({ db_id => $nulldb->id, accession => 'null' });
my $nullcvterm  = Chado::Cvterm->find_or_create({ dbxref_id => $nulldbxref->id, name => 'null', cv_id => $nullcv->id });
my $nullpub     = Chado::Pub->find_or_create({ miniref => '', title => 'Affy MAGE-ML', type_id => $nullcvterm->id });
my $term_affysynonym = Chado::Cvterm->find_or_create({ dbxref_id => $nulldbxref->id, name => 'Affymetrix synonym', cv_id => $nullcv->id });

my($organism) = Chado::Organism->find_or_create({
												abbreviation => 'H.sapiens',
												genus        => 'Homo',
#												taxgroup     => '9606', #NCBI TaxonomyID
												species      => 'sapiens',
												common_name  => 'Human'
											   });

my($cv) = Chado::Cv->find_or_create({
									 name => 'Affymetrix Feature Properties'
									});


#fastforward to and capture Database_assnlist
my $xml = skipto($fh,'<Database_assnlist>','</Database_assnlist>');
processDatabase_assnlist($xml);

#my $die = 3;
while(1){
  $xml = skipto($fh,'BioSequence ','</BioSequence>');
  processBioSequence($xml);
#  last unless --$die;
}

exit 1;


sub processDatabase_assnlist {
  my $xml = shift;
  my $xmld = XMLin($xml);

  foreach my $database (@{$xmld->{Database}}){
	next if $DATABASE{$database->{identifier}} = Chado::Db->search(name => $database->{identifier});
	my $db_obj = Chado::Db->create({
									name  => $database->{identifier},
									url   => $database->{URI},
									contact_id => $nullcontact->id,
								   });
	$DATABASE{$database->{identifier}} = $db_obj;
  }
}

sub processBioSequence {
  my $xml = shift;
  my $xmld = XMLin($xml);
#  print Dumper($xmld);

  my $identifier = $xmld->{identifier};
  my($dbname,$name) = $identifier =~ /^(.+:)(.+)$/;
warn $identifier;
  my($db) = Chado::Db->find_or_create({name => $dbname, contact_id => $nullcontact->id});
  $db->commit if $db->is_changed;

  my($dbxref) = Chado::Dbxref->find_or_create({db_id => $db->id, accession => $name});

  my $feature = Chado::Feature->find_or_create({
												dbxref_id => $dbxref->id,
												organism_id => $organism->id,
												name => $name,
												uniquename => $identifier,
												seqlen => length($xmld->{sequence}),
												#this is BS, prereq SOFA load
												type_id => $nullcvterm->id,
											   });
  $feature->residues($xmld->{sequence});
  $feature->update;

  if($xmld->{name}){
	my $synonym = Chado::Synonym->find_or_create({
												  name => substr($xmld->{name},0,255),
												  synonym_sgml => '',
												  type_id => $term_affysynonym->id,
												 });

	my $fsynonym = Chado::Feature_Synonym->find_or_create({
														   feature_id => $feature->id,
														   synonym_id => $synonym->id,
														   pub_id     => $nullpub->id,
														  });
  }

  foreach my $namevaluetype (keys %{$xmld->{PropertySets_assnlist}->{NameValueType}}){
	my $nvt = $xmld->{PropertySets_assnlist}->{NameValueType}->{$namevaluetype};
#warn Dumper($nvt);
	my $term = $namevaluetype;
	if($term =~ /^GO:(\d+)/){
	  my $num = sprintf("%07d",$1);
	  $term = "GO:$num";
	}

	my($cvterm) = Chado::Cvterm->find_or_create({
												 name => $term,
												 cv_id => $cv->id,
												});
	
 	my $featureprop = Chado::Featureprop->find_or_create({
														  feature_id => $feature->id,
														  type_id => $cvterm->id,
														  value => $nvt->{value},
														 });
  }



#------------------------------



  foreach my $dbentry (@{$xmld->{SequenceDatabases_assnlist}->{DatabaseEntry}}){
#warn Dumper($dbentry);
	my $accession = $dbentry->{accession};

#warn $feature->id;
#warn $dbxref->id;

#	my($fd) = Chado::Feature_Dbxref->search(feature_id => $feature->id, dbxref_id => $dbxref->id);
#
#	if(!$fd){
#	  $fd = Chado::Feature_Dbxref->create({
#										   feature_id => $feature->id,
#										   dbxref_id  => $dbxref->id,
#										  });
#	}

	my($fd) = Chado::Feature_Dbxref->find_or_create({
													 feature_id => $feature->id,
													 dbxref_id  => $dbxref->id,
													});

	
	foreach my $dbref (keys %{$dbentry->{Database_assnref}}){
	  my $identifier = $dbentry->{Database_assnref}->{$dbref}->{identifier};

	  my($db) = Chado::Db->search(name => $identifier);
	  if(!$db){
		$db = Chado::Db->find_or_create({
										 name => $identifier,
										 contact_id => $nullcontact->id
										});
	  }

	  my($dbxref) = Chado::Dbxref->find_or_create(db_id => $db->id, accession => $accession);

	  my($fd) = Chado::Feature_Dbxref->find_or_create({
													   feature_id => $feature->id,
													   dbxref_id  => $dbxref->id,
													  });

	  foreach my $namevaluetype (keys %{$dbentry->{PropertySets_assnlist}->{NameValueType}}){
		my $nvt = $dbentry->{PropertySets_assnlist}->{NameValueType}->{$namevaluetype};

		my $term = $namevaluetype;
		if($term =~ /^GO:(\d+)/){
		  my $num = sprintf("%07d",$1);
		  $term = "GO:$num";
		}

		my $value = ref($nvt) eq 'HASH' ? $nvt->{value} : $nvt;
#warn "$term\t$value";
		if($term eq 'name'){
		  $term   = $dbentry->{PropertySets_assnlist}->{NameValueType}->{name};
		  $value  = $dbentry->{PropertySets_assnlist}->{NameValueType}->{value};

		  $value .= $dbentry->{PropertySets_assnlist}->{NameValueType}->{type} ? '|' .
			        $dbentry->{PropertySets_assnlist}->{NameValueType}->{type} : '';
		}

		my  $cvterm = Chado::Cvterm->find_or_create({
													 name => $term,
													 cv_id => $cv->id,
													});

		my $dbxrefprop = Chado::Dbxrefprop->find_or_create({
															dbxref_id => $dbxref->id,
															type_id => $cvterm->id,
															value => $value,
														   });
	  }
	}
  }

#exit;

  foreach my $ontology (keys %{$xmld->{OntologyEntries_assnlist}}){
#	warn dumper $ontology;
	my @terms = ref($xmld->{OntologyEntries_assnlist}->{$ontology}) eq 'ARRAY'
	  ? @{$xmld->{OntologyEntries_assnlist}->{$ontology}}
	  : ($xmld->{OntologyEntries_assnlist}->{$ontology});

	foreach my $term (@terms){
	  my($cv) = Chado::Cv->find_or_create(name => _cv_remap($term->{category}));

	  if($term->{value} =~ /^GO:(\d+)/){
		my $num = sprintf("%07d",$1);
		$term->{value} = "GO:$num";
	  }

	  my($cvterm) = Chado::Cvterm->search(name => $term->{value}, cv_id => $cv->id);
	  if(!$cvterm){
		$cvterm = Chado::Cvterm->find_or_create({
												 name => $term->{value},
												 cv_id => $cv->id,
												 definition => $term->{description},
												});
	  }

		my $featurecvterm = Chado::Feature_Cvterm->find_or_create({
														 feature_id => $feature->id,
														 cvterm_id => $cvterm->id,
														 pub_id => $nullpub->id,
														});
	}
  }

#print Dumper $xmld;

}

sub skipto {
  my($fh,$beg,$end) = @_;

  my $xml;

  while(my $line = <$fh>){
	next unless $line =~ /$beg/;
	$xml = $line;
	last;
  }

  while(my $line = <$fh>){
	$xml .= $line;
	last if $line =~ /$end/;
  }

  return $xml;
}

sub _cv_remap {
  my $cvname = shift;
  my %map = (
		   'GO:Cellular_Component' => 'Gene Ontology',
		   'GO:Molecular_Function' => 'Gene Ontology',
		   'GO:Biological_Process' => 'Gene Ontology',
			);

  return $map{$cvname} || $cvname;
}
