package CXGN::Tools::Gene;
use strict;
no strict 'refs';
use base qw/CXGN::Class::DBI/;
use CXGN::DB::Connection;
use CXGN::Tools::Identifiers qw/identifier_namespace/;

=head1 NAME

 CXGN::Tools::Gene

=head1 SYNOPSIS

 Fetch properties of a given unigene or arabidopsis gene,
 such as annotation, sequence, or signalp data.  If you
 want it to do more, please add functions!  I wanted
 a unified object that could grab information about any
 gene in our database, so this is just a start.

 WARNING: This module throws an error if the identifier
 is not recognized.  In web scripts, construction of a
 Gene should be wrapped in eval{}

=head1 USAGE

 my $gene = CXGN::Tools::Gene->new("AT1G01010.1");
 $gene->fetch;
 if($gene->isSignalPositive){
 	print $gene->{id} . " is likely to be secreted";
 }

 #(mostly) works based on database column names from fetch:
 my $nn_score = $gene->getProperty("nn_score");

 #custom getters:
 my $cds = $gene->getSequence("cds");
 my $annotation = $gene->getAnnotation();
 #write more!

=cut

#If a calling script/package has DBH defined as a package variable, attach it to this class
our $EXCHANGE_DBH = 1; 
#All the database queries are in this INIT block

BEGIN {
	__PACKAGE__->required_search_paths(qw/public sgn/);

	my %queries = ( 

	#Arabidopsis Queries
	
	ara_check => 

		"SELECT agi FROM public.ara_properties WHERE agi=?",

	ara_annot => 
		
		"SELECT * FROM ara_properties JOIN ara_annotation USING(agi) WHERE agi=?",

	ara_sigp =>
		
		"SELECT * FROM ara_signalp WHERE agi=?",
	
	ara_seq =>
		
		"SELECT * FROM ara_sequence WHERE agi=?",

	ara_domain =>
		
		"SELECT dom_desc, dom_start, dom_end, 
				interpro_id AS dom_interpro_id, 
				interpro_dom AS dom_full_desc 
		FROM ara_domain 
		WHERE agi=?",
	
	ara_ncbi_check => 
		
		"	
		SELECT agi 
		FROM ara_annotation 
		WHERE 	
			gb_prot_id=?
			OR gb_mrna_id=? 
			",

	ara_protein_length => 

		"SELECT LENGTH(protein) AS protein_length FROM ara_sequence WHERE agi=?",

	ara_go =>

		"	
		SELECT type, go_id, evidence, content, pmid 
		FROM ara_go
		WHERE 
			gene=?
		",
	
	#Unigene Queries

	
	uni_domain =>

		"SELECT cds_id AS dom_cds_id,
				domain_accession, 
				match_begin AS dom_start, 
				match_end AS dom_end, 
				interpro_id AS dom_interpro_id, 
				description AS dom_desc 
		FROM domain_match
		LEFT JOIN domain USING (domain_id)
		WHERE 
			unigene_id=?
		",

	uni_check =>

		"SELECT unigene_id FROM unigene WHERE unigene_id=?",	

	uni_seq =>
	
		"	
		SELECT seq_edits, protein_seq 
		FROM cds 
		WHERE unigene_id=?
		",

	uni_sigp =>
	
		"	
		SELECT * FROM signalp 
		WHERE 
			cds_id=
				(
					SELECT cds_id 
					FROM cds 
					WHERE 	
						unigene_id=? 
						AND method='estscan'
				)
		",
	
	uniq_manual_annot =>

		"	
		SELECT 
			sgn_people.sp_person.first_name || ' ' || sgn_people.sp_person.last_name AS annot_contributor,
			manual_annotations.date_entered AS annot_date_entered,
			manual_annotations.last_modified AS annot_last_modified,
			manual_annotations.annotation_text AS annot_content,
			clone.clone_name AS annot_clone_name
		FROM unigene
		LEFT JOIN unigene_member USING (unigene_id)
		LEFT JOIN est USING (est_id) 
		LEFT JOIN seqread USING (read_id)
		LEFT JOIN clone USING (clone_id)
		LEFT JOIN manual_annotations ON (clone.clone_id = manual_annotations.annotation_target_id)
		LEFT JOIN sgn_people.sp_person ON (manual_annotations.author_id = sgn_people.sp_person.sp_person_id)
		LEFT JOIN annotation_target_type ON (manual_annotations.annotation_target_type_id = annotation_target_type.annotation_target_type_id)
		WHERE 
			unigene.unigene_id=? 
			AND annotation_target_type.type_name='clone'
		",
	
	uni_blast_annot =>
	
		"
		SELECT evalue AS blast_annot_evalue, score AS blast_annot_score, 
			identity_percentage AS blast_annot_identity_percentage, 
			defline AS blast_annot_content
		FROM blast_hits
		LEFT JOIN blast_defline USING (defline_id)
		WHERE blast_annotation_id=
		(	
			SELECT  blast_annotation_id
			FROM blast_annotations
			LEFT JOIN blast_targets USING (blast_target_id)
			WHERE apply_id=? and apply_type=15 LIMIT 1
		)
		ORDER BY score DESC
		",

	uni_general =>
		
		"SELECT 
			unigene.cluster_no,
			unigene.contig_no,
			unigene.nr_members,
			unigene.database_name,
			unigene.sequence_name,
			unigene_build.build_nr,
			unigene_build.build_date,
			unigene_build.status,
			unigene_build.comment AS build_comment,
			groups.comment AS species
		FROM unigene 
		LEFT JOIN unigene_build USING (unigene_build_id)
		LEFT JOIN groups ON (organism_group_id=group_id)
		WHERE 
			unigene_id=?
		",

	uni_consensi =>
		
		"	SELECT seq
			FROM unigene
			LEFT JOIN unigene_consensi USING (consensi_id)
			WHERE unigene_id=?
		",


	uni_singleton =>
		
		"	SELECT COALESCE(substring(seq FROM (hqi_start)::int+1 FOR (hqi_length)::int ),seq)
			FROM unigene
			LEFT JOIN unigene_member USING (unigene_id)
			LEFT JOIN est USING (est_id)
			LEFT JOIN qc_report USING (est_id)
			WHERE 
				unigene.unigene_id=?
		",

	uni_protein_length =>

		"	
		SELECT LENGTH(protein_seq) AS protein_length 
		FROM cds 
		WHERE 	
			unigene_id=? 
			AND preferred='t'
		",


	);

	
	while(my ($name, $query) = each %queries){
		__PACKAGE__->set_sql($name, $query);
	}
}	


#.................................
#..... Instance Functions ........

=head3 new()

 Instantiate a new Gene object.  As of now, the gene must
 exist as an arabidopsis or unigene identifier in the database.
 Argument: Identifier
 Returns: Gene object

 Support will be added for "empty" objects if sequence processing
 is added.  Also, I think store() methods aren't a good idea.

=cut

sub new {
	my $class = shift;
	my $identifier = uc ( shift );
	my $dbh = shift;
	
	if($dbh) { __PACKAGE__->DBH($dbh) }
	
	my $self = bless {}, $class;

	my $namespace = identifier_namespace($identifier);
	if($namespace =~ /sgn_u/i){
		$self->{type} = "uni";
		$identifier =~ s/SGN-U//i;
		$self->{id} = $identifier;
	}
	elsif($namespace =~ /tair_gene_model/i){
		$self->{type} = "ara";
		$self->{id} = $identifier;
	}
	elsif($namespace =~ /tair_locus/i){
		print STDERR "Tair Locus passed ($identifier), using first gene model $identifier.1\n";
		$self->{type} = "ara";
		$self->{id} = $identifier . '.1';
	}
	elsif($namespace =~ /genbank_accession/i){
		$self->_resolve_ncbi($identifier);
		die "NCBI identifier [$identifier] does not map to TAIR gene model" unless $self->{id};
	}
	else {	
		die "You must send a SGN-Unigene or TAIR Gene model (AT1G01010.1) identifier as the first argument to this class [$identifier]";
	}
	$self->_check_existence;
	
	return $self;
}

sub _check_existence {
	my $self = shift;
	my $sth = $self->get_sql($self->{type} . "_check");
	$sth->execute($self->{id});
	my (@row) = $sth->fetchrow_array();
	unless(@row){
		die 
		"Gene with type '$self->{type}' and id '$self->{id}' not found in database\n";
	}
}

sub _resolve_ncbi {
	my $self = shift;
	my $id = shift;
	unless($id){
		$id = $self->{id};
	}
	return unless $id;
	return unless identifier_namespace($id) =~ /genbank_accession/i;


	my $sth = $self->get_sql("ara_ncbi_check");
	$sth->execute($id, $id);

	my $row = $sth->fetchrow_hashref;
	if($row->{agi}){
		$self->{type} = "ara";
		$self->{id} = $row->{agi};
		return $self->{id};
	}
	return;
}


=head3 fetch()

 Argument: Query hash key  [ See _set_query_hashes() ]
 Returns: Nothing
 Side Effect: Populate object with selected information from database

=cut


sub fetch {
	my $self = shift;	
	my $query_key = lc ( shift );
	my $option = shift;
	if(!$query_key) { $query_key = "annot" }
	my %query_hash;
	
	my $sth = $self->get_sql($self->{type}."_".$query_key);

	$sth->execute($self->{id});
	
	#extra junk for getting unigene cdna sequence
	if($query_key eq "seq" && $self->{type} eq "uni"){
		while(my $row = $sth->fetchrow_hashref){
			unless ($self->property('protein_seq') && $row->{preferred} ne 't'){
				$self->property("seq_edits", $row->{seq_edits});
				$self->property("protein_seq", $row->{protein_seq});
			}
		}
		$self->fetch("general");
		my $qt;
		($self->getProperty("nr_members")>1)?($qt="consensi"):($qt="singleton");
		my $sth = $self->get_sql("uni_".$qt);

		$sth->execute($self->{id});
		$self->property("cdna", $sth->fetchrow_array());
		return; #have all we need now
	}

	my $row = $sth->fetchrow_hashref;
	while( my ($key, $value) = each %$row ) {
		$self->property($key, $value);
	}
	

}

=head3 fetch_all

 Fetch all information from database pertaining to gene.
 Convenient, but inefficient for mass process.

=cut

sub fetch_all {
	my $self = shift;
	$self->fetch();
	$self->fetch_sigp();
	$self->fetch_seq();
	$self->fetch_dom();
	if($self->{type} eq "uni"){
		my @uni_specific = qw/ blast_annot general consensi singleton /;
		$self->fetch($_) foreach @uni_specific;
	}
}

sub fetch_sigp {
	my $self = shift;
	$self->fetch("sigp");
}

sub fetch_seq {
	my $self = shift;
	$self->fetch("seq");
}

sub fetch_dom {
	#Several rows, non-standard fetch:
	my $self = shift;
#	return unless $self->{type} eq "ara"; works for unigene now?
	my $sth = $self->get_sql($self->{type}."_domain");
	$sth->execute($self->{id});
	$self->{domains} = [];
	if($self->{type} eq "ara"){	
		while(my $row = $sth->fetchrow_hashref){
			push(@{$self->{domains}}, $row);
		}
	}
	else {
		#Only get rows for one of the cds_id's, in case multiple cds_id's
		#exist for a particular unigene_id:
		my $row = $sth->fetchrow_hashref;
		return unless $row;
		my $cds_id = $row->{dom_cds_id};
		#fix interpro id's
		
		my $ipr = $row->{dom_interpro_id};
		if($ipr =~ /^\d+$/){
			$ipr = "IPR" . sprintf("%06s", $ipr);
			$row->{dom_interpro_id} = $ipr;
		}
		push(@{$self->{domains}}, $row);
		while(my $row = $sth->fetchrow_hashref){
			push(@{$self->{domains}}, $row) if ($row->{dom_cds_id} eq $cds_id);
		}
	}
}

sub fetch_go {
	my $self = shift;
	return unless $self->{type} eq "ara";  #Arabidopsis only, for now
	my $sth = $self->get_sql("ara_go");
	$sth->execute($self->{id});
	
	my $gref = {};
	$gref->{$_} = [] foreach(qw/comp func proc/);

	while(my $row = $sth->fetchrow_hashref) {
		my $prop = {};		
		$prop->{$_} = $row->{$_} foreach(qw/go_id evidence content pmid/);
		push @{$gref->{$row->{type}}}, $prop;
	}
	$self->{go} = $gref;
}


sub getGO { get_go(@_) }

sub get_go {
	my $self = shift;
	$self->fetch_go unless($self->{go});
	return $self->{go};
}

sub property {
	my $self = shift;
	my ($k,$v) = @_;
	return undef unless $k;
	$self->{db_keys}->{$k} = $v if defined $v;
	return $self->{db_keys}->{$k};
}

=head3 get_property($key)

 Return a property of the gene, based on the column name in the database
 under which the information can be found.  There are some exceptions
 to this rule, such as with the cdna sequence in Unigenes, and for aliased
 query returns. See the _prepare_global_queries() section for key aliases.

 Arguments: key name
 Returns: value

=cut

sub getProperty {
	my $self = shift;
	my $key = shift;
	return $self->{db_keys}->{$key};
}


=head3 getProperties

 Just like getProperty, except it takes and returns an array

=cut

sub getProperties {
	my $self = shift;
	return map { $self->property($_) } @_;
}

sub getSpecies {
	my $self = shift;
	unless($self->_check_key("species")){
		$self->property("species", "Arabidopsis T.") if $self->{type} eq "ara";
		$self->fetch("general") if $self->{type} eq "uni";
	}
	return $self->property("species");
}

=head3 getSequence

 Arguments: 'genomic', 'cdna', 'cds', or 'protein'
 Returns: A sequence
 Issues: No 'genomic' support for Unigenes

=cut

sub getSequence {
	my $self = shift;
	my $seq_type = shift;
	die "Only supported seq_types for sequences: protein, cds, cdna, genomic"
		unless $seq_type =~ /(protein)|(cds)|(cdna)|(genomic)/;

	$self->fetch("seq") unless $self->_check_key($seq_type);
	if($self->{type} eq "uni"){
		return $self->property("seq_edits") if $seq_type eq "cds";
		return $self->property("protein_seq") if $seq_type eq "protein";
		return $self->property("cdna") if $seq_type eq "cdna";
		
		#Ok, so you can't get a REAL genomic sequence
		warn "No 'genomic' sequence supported for Unigenes yet" if $seq_type eq "genomic";
		return undef;
	}
	if($self->{type} eq "ara"){
		return $self->property($seq_type);
	}
}

sub getAnnotation {
	my $self = shift;
	if ($self->{type} eq "ara") {
		$self->fetch("annot") unless $self->_check_key("tair_annotation");
		return $self->property("tair_annotation");
	}
	if ($self->{type} eq "uni") {
		$self->fetch("blast_annot") unless $self->_check_key("blast_annot_content");
		$self->fetch("annot") unless $self->_check_key("annot_content");
		my $manual = $self->property("annot_content");
		my $blast = $self->property("blast_annot_content");
		return $manual if $manual;
		if($blast){
			#Trim off the fluff.  If you need it, use fetch("blast_annot")
			# and getProperty("blast_annot_content");
			my ($agi, $ncbi_id);
			if($blast =~ /^\s*AT[1-5MC]G/i){
				($agi) = $blast =~ /(AT[1-5MC]G\d{5}\.\d+)/i;
			
				$blast =~ s/.*?\|.*?\|\s*//;
				$blast =~ s/\s*\|.*//;
				$blast = "[BLAST: $agi] $blast" if $agi;
			}
			elsif($blast =~ /^\s*gi\s*\|/i){
				($ncbi_id) = $blast =~ /\s*gi\s*\|\s*\d+\s*\|\s*\w+\s*\|\s*(\S+)\s*\|/i;
				$blast =~ s/.*?\|.*?\|.*?\|.*?\|//;
				$blast = "[BLAST: $ncbi_id] $blast" if $ncbi_id;
			}
			$blast = "[BLAST] $blast" unless($ncbi_id || $agi);
		}
		return $blast if $blast;

		print STDERR "No annotation available for " . $self->{id};
		return;
	}	
}

=head3 getDomains

 Returns an array of hash references, one for each domain:
 dom_desc => "NAME111"
 dom_full_desc => "Actual description" 
 dom_start => start aa position
 dom_end => end aa position
 dom_interpro_id => intropro accession # for domain

=cut

sub getDomains {
	my $self = shift;
	$self->fetch_dom unless (ref $self->{domains} && @{$self->{domains}});
	return @{$self->{domains}};
}

=head3 SignalP Getters

 getSignalScore() - neural network score
 getCleavagePosition() - AA # to the right of cleavage point
 isSignalPositive() - 1 if predicted secretion, 0 if not
 getSignalPeptide() - returns signal peptide sequence if positive, null string otherwise
 getCleavedSequence() - returns protein sequence without signal peptide if signal positive,
                        otherwise returns a null string

=cut

sub getSignalScore {
	my $self = shift;
	$self->fetch_sigp unless $self->_check_key("nn_score");	
	return $self->property("nn_score");
}

sub getSignalPeptide {
	my $self = shift;
	$self->fetch_sigp unless $self->_check_key("nn_ypos");
	my $protseq = $self->get_sequence("protein");
	if($self->is_signal_positive){
		my $cp = $self->get_cleavage_position();
		return substr($protseq, 0, $cp-1);
	}
	else {
		return '';
	}
}

sub getCleavedSequence {
	my $self = shift;
	$self->fetch_sigp unless $self->_check_key("nn_ypos");
	my $protseq = $self->get_sequence("protein");
	if($self->is_signal_positive){
		my $cp = $self->get_cleavage_position();
		return substr($protseq, $cp-1);
	}
	else {
		return '';
	}
}

sub getCleavagePosition {
	my $self = shift;
	$self->fetch_sigp unless $self->_check_key("nn_ypos");
	return $self->property("nn_ypos");
}

sub isSignalPositive {
	my $self = shift;
	$self->fetch_sigp unless $self->_check_key("nn_d");
	my $dec = $self->property("nn_d");
	if($dec eq 'Y'){
		return 1;
	}
	elsif($dec eq 'N'){
		return 0;
	}
	else {
		#There is a serious problem with signalp formats that needs to be fixed immediately:
		warn "\nSignalProblem: NN decision score ($dec) not recognized for " . $self->{id} . ", returning false\n";
		return 0;
	}
}

#Temporary sub aliases, get rid of that camel case!  What was I thinking?
*get_property = \&getProperty;
*get_properties = \&getProperties;
*get_species = \&getSpecies;
*get_sequence = \&getSequence;
*get_annotation = \&getAnnotation;
*get_domains = \&getDomains;
*get_signal_score = \&getSignalScore;
*get_signal_peptide = \&getSignalPeptide;
*get_cleaved_sequence = \&getCleavedSequence;
*get_cleavage_position = \&getCleavagePosition;
*is_signal_positive = \&isSignalPositive;

sub _check_key {
	my $self = shift;
	my $key = shift;
	unless(exists $self->{db_keys}->{$key}){
		return 0;
	}
	return 1;
}


1;
