package CXGN::Tools::RestrictionEnzyme;
use strict;
use CXGN::DB::Connection;

=head1 NAME

 CXGN::Tools::RestrictionEnzyme

=head1 SYNOPSIS

 Abstract representation for pulling information about restriction enzymes
 from SGN database.  Will work in concert with CXGN::Tools::Sequence
 to find restriction sites. 

=head1 AUTHOR

 C. Carpita <ccarpita@gmail.com>

=cut

#GLOBAL CLASS VARIABLES
our $DBH;

#Prepared statement references:
our ($ALL_ENZ_NAME_Q);
our ($VALID_ENZ_NAME_Q, $ENZ_SEQ_Q);

our %VALID_NAMES;

=head1 CLASS METHODS

=cut

sub setDBH {
	my $class = shift;
	my $dbh = shift;
	die "Must call this function on the class and send a DBH argument\n" unless ref($dbh);
	$DBH = $dbh;		
	$class->prepare();
}

sub prepare {
	my $class = shift;
	if($DBH->can("add_search_path")){
		$DBH->add_search_path("sgn");
	}
	else {
		$DBH->do("set search_path=sgn");
	}

	$ALL_ENZ_NAME_Q = $DBH->prepare("
			SELECT DISTINCT enzyme_name 
			FROM enzymes 
			WHERE enzyme_id 
			IN ( 
				SELECT DISTINCT enzyme_id 
				FROM enzyme_restriction_sites 
				WHERE restriction_site IS NOT NULL 
			) 
			ORDER BY enzyme_name
			");

	$VALID_ENZ_NAME_Q = $DBH->prepare("
			SELECT enzyme_name 
			FROM enzymes 
			WHERE enzyme_id 
				IN ( 
					SELECT DISTINCT enzyme_id 
					FROM enzyme_restriction_sites 
					WHERE restriction_site IS NOT NULL 
				)
			AND enzyme_name = ?
			ORDER BY enzyme_name
			");

	$ENZ_SEQ_Q = $DBH->prepare("
		SELECT restriction_site
		FROM enzyme_restriction_sites
		WHERE enzyme_id = 
			(	SELECT enzyme_id
				FROM enzymes
				WHERE enzyme_name = ?
			)
		AND restriction_site IS NOT NULL
	");
}

sub preload_valid_names {
	my $class = shift;
	$ALL_ENZ_NAME_Q->execute();
	while(my $row = $ALL_ENZ_NAME_Q->fetchrow_hashref){
		my $enzyme_name = $row->{enzyme_name};
		$VALID_NAMES{$enzyme_name} = 1;	
	}
}

sub createDBH {
	my $class = shift;
	print STDERR "$class is creating SGN database handle...\n";
	my $dbh = CXGN::DB::Connection->new("sgn");
	$class->setDBH($dbh);
}

=head2 all_enzymes
 
 Ex: my @enzymes = CXGN::Tools::Enzyme::all_enzymes();

 Returns an array of all enzyme objects, created from
 the enzyme tables in the database.

=cut

sub all_enzymes {
	my $class = shift;
	$class->createDBH() unless ref($DBH);
	$class->preload_valid_names() unless keys(%VALID_NAMES);
	my @enzymes = ();
	foreach my $name (keys %VALID_NAMES){
		my $enzyme = $class->new($name);
		push(@enzymes, $enzyme);
	}
	return @enzymes;
}


=head1 CONSTRUCTOR

 Usage: my $enzyme = CXGN::Tools::Enzyme->new("hindIII");
 Auto-fetches the matching sequences from the database,
 dies if the name is not valid.  Use eval{} tags to avoid
 death.

=cut

sub new {
	my $class = shift;
	my $self = bless {}, $class;
	
	my $name = shift;

	#You can provide a different DBH to use instead of the
	#class global, which we use to prepare queries efficiently
	my $dbh = shift;

	die "No enzyme name provided\n" unless $name;
	$self->name($name);

	if(ref($dbh)){
		$self->setDBH($dbh);
	}
	else {
		$class->createDBH() unless ref($DBH);
	}

	$self->{match_seqs} = [];
	$self->check_name_valid();
	$self->fetch_match_seqs();

	return $self;
}

=head1 INSTANCE METHODS

=cut

sub name {
	my $self = shift;
	my $name = shift;
	return $self->{name} unless $name;
	$self->{name} = $name;
}

sub check_name_valid {
	my $self = shift;
	my $name = $self->name();	
	__PACKAGE__->preload_valid_names() unless defined %VALID_NAMES;
	die "Name of enzyme ($name) not valid, or no restriction site identified\n" unless $VALID_NAMES{$name};
}

sub fetch_match_seqs {
	my $self = shift;
	$ENZ_SEQ_Q->execute($self->name());
	while(my ($seq) = $ENZ_SEQ_Q->fetchrow_array){
		push(@{$self->{match_seqs}}, $seq);
	}
}
