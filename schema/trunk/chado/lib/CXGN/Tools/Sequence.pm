package CXGN::Tools::Sequence;
use strict;

=head2 new()

 Creates a new sequence object, which has a type, id, and sequence,
 sent as an argument hash 
 CXGN::Tools::Sequence->new({ id=>..., seq=>..., type=>... })
 
 Additionally, you may provide options for CDS translation to peptide:
   strict_cds: If positive, don't allow mid-sequence stop codons or incomplete CDS's
   allow_incomplete: CDS can be a fragment, not start w/ M, have a non-codon tail (ignored)
   ignore_stop: Stop codons in the middle of the sequence are skipped over
 
 If you are using strict mode, the translation will call die() whenever problems arise

=cut

sub new {
	my $class = shift;
	my $self = bless {}, $class;
	my $args = shift;
	$self->_default($args);	
	return $self;
}

sub _default {
	my $self = shift;
	my $args = shift;

	$self->{strict_cds} = 0;
	$self->{ignore_stop} = 1;
	$self->{allow_incomplete} = 1;
	my $random = int(rand(100000000));
	$self->{id} = "Unknown-$random";
	$self->{seq} = "";
	$self->{type} = "nt";

	if(ref($args) eq "HASH"){	
		foreach(qw/   	type       id          seq   
						strict_cds ignore_stop allow_incomplete /
			){
			$self->{$_} = $args->{$_} if(exists $args->{$_});
		}
	}
	else {
		$self->{seq} = $args;
	}
	
	if($self->{strict_cds}){
		$self->{ignore_stop} = 0;
		$self->{allow_incomplete} = 0;
	}

}

=head2 translate_cds()

  Type must be set to "cds", otherwise returns with nothing.
  Takes the sequence and translates it into a polypeptide, returning
  the peptide sequence when finished and setting the hash key 
  $self->{translated_protein_seq}

=cut

sub translate_cds {
	my $self = shift;
	unless($self->{type} eq "cds") {
		print STDERR "Type not set to 'cds', early return";
		return;
	}
	my $seq = $self->{seq};
	my $cds_seq = $seq;
	my $protein_seq = "";
	my $i = 0;
	while($i < length($cds_seq)){
		my $codon = substr($cds_seq, $i, 3);
		my $aa = "";
		$aa = $self->_translate_codon($codon, $i);	
 		if(!$self->{allow_incomplete} && $i==0 && $aa ne "M"){
 			die "Polypeptide does not start with a Methionine, for the sequence identified by " . $self->{id} . "\n";
 		}
		if($aa eq "*"){
			$i+=3;
			$protein_seq .= "X" if $self->{ignore_stop}; #assuming that cds is wrong
			$protein_seq .= "*" if !$self->{ignore_stop};
			last unless $self->{ignore_stop};
		}
		else {
			$protein_seq .= $aa;
			$i+=3;
		}
	}
 	unless ($self->{ignore_stop} || $i >= length($cds_seq)){
 		my $stop_codon = substr($cds_seq, $i, 3);
 		my $next_codon = substr($cds_seq, $i+3, 3);
 		die "Early termination of CDS for the sequence identified by " . $self->{id} . "\n$stop_codon-$next_codon... position $i short of " . length($cds_seq);
 	}

	$self->{translated_protein_seq} = $protein_seq;
	return $protein_seq;
}

sub _translate_codon {
	#Ridiculous and Unnecessary? Maybe, but I wanted to do it,
	#and Bio::Tools::CodonTable requires overhead
	my $self = shift;
	my $codon = uc ( shift );
	my $pos = 1 + ( shift );
	$codon =~ tr/U/T/;
	if(length($codon)<3){
		die "Not a complete codon" unless $self->{allow_incomplete};
		return "X"; #consider revising
	}
	if(length($codon)>3){
		die "Codon more than 3 base pairs long.  Fix this bug!\n";
	}
	return "-" if $codon =~ /^(-|\.){3}$/;

	die "Invalid codon: $codon at position $pos (". $self->{id} . ")" 
		unless $codon =~ /^(A|T|G|C|N|R|Y|S|W|K|M|B|D|H|V|X)+$/;
	
	return "*" if $codon =~ /(TA((G|A)|R))|(TGA)/; #STOP codon
	return "M" if $codon =~ /ATG/;
	return "I" if $codon =~ /AT((T|C|A)|H|Y|M|W)/;
	return "L" if $codon =~ /(CT.)|(TT((A|G)|R))/;
	return "V" if $codon =~ /GT./;
	return "F" if $codon =~ /TT((T|C)|Y)/;
	return "C" if $codon =~ /TG((T|C)|Y)/;
	return "A" if $codon =~ /GC./;
	return "G" if $codon =~ /GG./;
	return "P" if $codon =~ /CC./;
	return "T" if $codon =~ /AC./;
	return "S" if $codon =~ /(TC.)|(AG((T|C)|Y))/;
	return "Y" if $codon =~ /TA((T|C)|Y)/;
	return "W" if $codon =~ /TGG/;
	return "Q" if $codon =~ /CA((A|G)|R)/;
	return "N" if $codon =~ /AA((T|C)|Y)/;
	return "H" if $codon =~ /CA((T|C)|Y)/;
	return "E" if $codon =~ /GA((A|G)|R)/;
	return "D" if $codon =~ /GA((T|C)|Y)/;
	return "K" if $codon =~ /AA((A|G)|R)/;
	return "R" if $codon =~ /(CG.)|(AG((A|G)|R))/;
	
	return "X"; #unknown
}

=head3 cds_insert_gaps
 
 Type must be 'cds', use this function if you have an
 un-gapped cds and would like to gap-it, given a gapped
 protein sequence returned by the alignment program.

 Arguments: A gapped *protein* sequence
 Returns: Nothing
 Side Effects: Gaps up the current CDS.  Also, I recommend
 	setting 'cds_nocheck' in the constructor, as this will
	run MUCH more quickly if you already know that the
	protein sequence and CDS are properly translated.

=cut

sub cds_insert_gaps {
	my $self = shift;
	unless($self->{type} eq "cds"){
		print STDERR "Type not set to 'cds', early return\n";
		return;
	}
	my $gapped_prot_seq = shift;

	my $ungap_prot = $gapped_prot_seq;
	$ungap_prot =~ s/\W//g;
	unless(length($self->{seq}) <= (3*length($ungap_prot)+3)) {
		my $message = "Error: Protein length (" . length($ungap_prot) . 
						") must be less than or equal to 1/3 of CDS length ( " . 
						length($self->{seq}) . 
						" minus stop codon) for gapping to work.  Early return.\n";
		print STDERR $message;
		return;
	}

	my $revprot = reverse $gapped_prot_seq;
	my $cds_gapped = "";
	my $cds_pos = 0;
	while(my $aa = chop($revprot)){
		if($aa eq '-'){
			$cds_gapped .= "---";
		}
		else {
			my $codon = substr($self->{seq}, $cds_pos, 3);
			die "Protein seq does not match CDS at position $cds_pos (" . $self->{id} . ")\n" unless ($self->{cds_nocheck} || $aa == ($self->_translate_codon($codon)) );
			$cds_gapped .= $codon;
			$cds_pos+=3;
		}
	}
	$self->{seq} = $cds_gapped;
	return $cds_gapped;
}

=head2 use_liberal_cds()

 Mid-sequence stop codons ignored, replaced w/ 'X'
 Incomplete CDS is allowed, assuming frame starts on
 first character.

=cut

sub use_liberal_cds {
	my $self = shift;
	$self->{strict_cds} = 0;
	$self->{ignore_stop} = 1;
	$self->{allow_incomplete} = 1;
}

=head2 use_strict_cds

 CDS must be complete (length divisible by three),
 starting with a methionine.
 STOP codons mid-sequence will cause death.

=cut

sub use_strict_cds {
	my $self = shift;
	$self->{strict_cds} = 1;
	$self->{ignore_stop} = 0;
	$self->{allow_incomplete} = 0;
}


1;
