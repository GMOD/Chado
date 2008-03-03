package CXGN::Tools::AnnotationConsensus;
=head1 CXGN::Tools::AnnotationConsensus.pm

 Given several annotations, this module implements a phrase-scoring
 algorithm of my own design to find the "consensus" annotation: the
 one which scores the highest based on similar phrases to other 
 annotations.

=head1 AUTHOR

 C. Carpita <ccarpita@gmail.com>

=head1 Methods

=cut

#Clip all annotations to this length, for the sake of efficiency
our $CUTOFF = 300;

=head2 new()
 
 Syn: Create a new consensus-calculator
 Args: (Opt) An anonymous hash of $id=>$annotation
 Ret: Instance of factory

=cut

sub new {
	my $class = shift;
	my $self = bless {}, $class;
	my $annotations = shift;	
	$self->{annotations} = $annotations if(ref $annotations); # $id => $annotation
	$self->{scores} = (); # $id => $score
	
	$self->{tuples} = ();	# $id => $tuples (combinations of phrases)

	$self->{max_tuple_score} = 0;
	$self->{max_tuple} = "";

	return $self;
}

=head2 addAnnotation()

 Syn: Add an annotation to the hash to be processed
 Args: Id, Annotation (content)
 Returns: Nothing

=cut

sub addAnnotation {
	my $self = shift;
	my ($id, $annotation) = @_;
	die "Need ID and annotation" unless($id && $annotation);
	$self->{annotations}->{$id} = $annotation;
}

=head2 calculate()

 Syn: Runs the levenshtein algorithm on each possible pair, sums the total
      edit score for each individual annotation.  Lower # of edits = better,
	  like golf, or 301
 Ret/Args: None

=cut

sub calculate {
	my $self = shift;
	my %scores = ();
	print STDERR "...Calculating\n";

	#Grab all the tuples (combinations of phrases) for each annotation
	while(my ($id, $annot) = each %{$self->{annotations}}){ 
		my @tuples = $self->_get_tuples($annot);	
		my %tuples = ();
		$tuples{$_} = 1 foreach(@tuples);
		$self->{tuples}->{$id} = \%tuples;
	}

	my %tup_copy = ();
 	%tup_copy = %{$self->{tuples}};
	while(my ($id, $tup_hash) = each %{$self->{tuples}}){
		print STDERR "#";
		my $qscore = 0;
  		while(my ($q_id, $q_tup_hash) = each %tup_copy){
  			next if ($q_id eq $id);
 	 			$qscore += $self->_tuple_score($tup_hash, $q_tup_hash);
  		}
		$scores{$id} = $qscore;
	}
	$self->{scores} = \%scores;
	print STDERR "\n";
}

=head2 getConsensus()

 Syn: Get the consensus annotation
 Ret: An array of ($id, $annotation, $score)
 Side: Runs $self->calculate() if no values exist in score hash

=cut

sub getConsensus {
	my $self = shift;
	$self->calculate() unless (values(%{$self->{scores}}));
	my @ids = keys %{$self->{scores}};
	my @sample = keys %{$self->{scores}};
	my $s_id = pop @sample;
	my $max = $self->{scores}->{$s_id};
	my $max_id = $s_id;
	while (my ($id, $score) = each %{$self->{scores}}){
		if ($score > $max) {
			$max_id = $id;
			$max = $score;
		}
	}
	return ($max_id, $self->{annotations}->{$max_id}, $max);
}

=head2 getScores()

 Syn: Gets a hash of $id => $score
 Side: Calculates if no values in score hash

=cut

sub getScores {
	my $self = shift;
	$self->calculate() unless (values(%{$self->{scores}}));
	return $self->{scores};
}

sub getMaxTuple {
	my $self = shift;
	return $self->{max_tuple};
}

#Replaced levenshtein with my own algorithm, should be much faster
sub _get_tuples {
	my $self = shift;
	my $string = shift;
	$string =~ s/\(.*?\)//g;
	$string =~ s/\[.*?\]//g;
	$string =~ s/;|,//g;
	$string = lc($string);  #Case-insensitive tuple-comparison
	my @words = split /\s+/, $string;	

	my @tuples = ();
	push(@tuples, @words);

	my $t = 2;
	while($t <= @words){
		my $i = 0;
		while($i < (@words - $t + 1)){
			my @tuple = ();
			for (my $k = $i; $k < $i + $t; $k++){
				push(@tuple, $words[$k]);
			}
			push(@tuples, join " ", @tuple);
			$i++;
		}
		$t++;
	}
	return @tuples;	
}

sub _tuple_score {
	my $self = shift;
	my ($base_tup, $q_tup) = @_;
	die "Arguments should be hash refs" unless (ref $base_tup && ref $q_tup);
	my $score = 0;
	my %base_tup = %$base_tup;
	my %query_tup = %$q_tup;
	while(my ($k, $v) = each %base_tup){
		next unless $v;
		my $num_spaces = 0;
		$num_spaces++ while($k =~ / /g);
		my $multiplier = ($num_spaces+1)**2;
		if($query_tup{$k}){	
			$score += $multiplier;
			if($multiplier > $self->{max_tuple_score}){
				$self->{max_tuple} = $k;
			}
		}
	}
	return $score;
}



#Not using this anymore, way too slow:
sub _levenshtein {
	my $self = shift;
	my ($s1, $s2) = @_;
	my $m = length $s1;
	my $n = length $s2;

	my %matrix = ();
	my $matrix = \%matrix;

	my ($i, $j);
	for($i = 0; $i<=$m; $i++){
		$matrix->{$i}->{0} = $i;
	}
	for($j = 0; $j<=$n; $j++){
		$matrix->{0}->{$j} = $j;
	}

	for(my $i = 1; $i<=$m; $i++){
		for(my $j = 1; $j<=$n; $j++){
			my $cost;
			if (lc(substr($s1, $i-1, 1)) eq lc(substr($s2, $j-1, 1))){
				$cost = 0;
			}
			else { 
				$cost = 1; 
			}
			$matrix->{$i}->{$j} = __minimum (
				$matrix->{$i-1}->{$j} + 1,
				$matrix->{$i}->{$j-1} + 1,
				$matrix->{$i-1}->{$j-1} + $cost
			);
		}
	}
	return $matrix->{$m}->{$n};
}

sub __minimum {
	my $min = shift;
	foreach(@_){
		$min = $_ if ($_ < $min);
	}
	return $min;
}



1;
