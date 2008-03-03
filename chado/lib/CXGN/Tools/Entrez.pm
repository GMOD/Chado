=head1 NAME

 CXGN::Tools::Entrez

=head1 SYNOPSIS

 A module using eFetch to access information about NCBI identifiers

=head1 USAGE

 #Terminal Script, useful for testing:
 use CXGN::Tools::Entrez;
 my $eutil = CXGN::Tools::Entrez->new();
 $eutil->run_terminal();


 # Fetch stuff within a script!
 use CXGN::Tools::Entrez;
 #....script....
 my $eutil = CXGN::Tools::Entrez->new({
                query => "zanzibar",
                db => "pubmed",
				format => "abstract",
				fetch_size => 1 });

 $eutil->init();
 my $first_abstract = $eutil->next();

 OR

 my $eutil = CXGN::Tools::Entrez->new();
 my $seq = $eutil->get_sequence("NP_188752", "Protein");


=head1 Author

 C. Carpita <ccarpita@gmail.com>

=cut

package CXGN::Tools::Entrez;

use Class::MethodMaker 
	[
		scalar =>  [qw/ db query format ret_mode 
						esearch result 
						fetch_start fetch_size fetch_max count 
						query_key web_env 
						url_base 
						xml_root/]
	];

use LWP::Simple;

use constant DEBUG => $ENV{ENTREZ_DEBUG};

BEGIN {
	print STDERR "\nDEBUG MODE\n" if DEBUG;
}

#Class Methods
sub new {
	my $class = shift;
	my $self = bless {}, $class;
	my $args =  shift;
	if($args && (ref($args) ne "HASH")){
		die "\nArguments must be sent as a hash reference:  ...->new( { db => 'Pubmed', ... } )\n";
	}
	$self->url_base("http://www.ncbi.nlm.nih.gov/entrez/eutils");
	$self->fetch_start(0);
	$self->fetch_size(10);
	$self->fetch_max(100);
	$self->ret_mode("text");

	#Default (usually JSON string) 
	#This should be set in subclass or by user
	$self->format(""); 	

	while(my($k, $v) = each %$args){
		unless (__PACKAGE__->can($k)){ 
			die "\nSetting '$k' not recognized\n";
		}
		$self->$k($v);
	}
	$self->{queried} = 0;	
	return $self;
}

#Instance Methods
sub init {
	my $self = shift;
	
	$self->esearch($self->url_base() . "/esearch.fcgi?" . 
					"db=" . $self->db() . 
					"&retmax=" . $self->fetch_max() .
					"&usehistory=y" .
					"&term=" . $self->query());

	print "\nEsearch: " . $self->esearch() if DEBUG;
	my $result = LWP::Simple::get($self->esearch);
	
	my ($count, $query_key, $web_env) = $result =~
		/<Count>(\d+)<\/Count>.*<QueryKey>(\d+)<\/QueryKey>.*<WebEnv>(\S+)<\/WebEnv>/s;		

	print STDERR "\nQuery result size: $count" if DEBUG;
	print STDERR "\n$result\n\n" if DEBUG;
	$self->count($count);
	$self->query_key($query_key);
	$self->web_env($web_env);
	$self->{queried} = 1;
}

sub next {
	my $self = shift;
	my $fetch_size = shift;
	$fetch_size ||= $self->fetch_size();
	
	my $fetch_start = shift;
	my $no_increment = 0;
	(defined $fetch_start)?($no_increment = 1):($fetch_start = $self->fetch_start());

	if($fetch_start >= $self->count()){
		print STDERR "\nProvided fetch start exceeds result size";
		return;
	}

	my $efetch = $self->url_base() . "/efetch.fcgi?" .
					"rettype=" . $self->format() .
					"&retmode=text" .
					"&retstart=" . $fetch_start .
					"&retmax=" . $fetch_size .
					"&db=" . $self->db() .
					"&query_key=" . $self->query_key() .
					"&WebEnv=" . $self->web_env();

	my $result = LWP::Simple::get($efetch);
	print STDERR "\nNo result from fetch" unless($result);

	#Increment internal counter unless starting point was specified
	$self->fetch_start($self->fetch_start() + $fetch_size) unless $no_increment;

	return $result;
}

sub fetch {
	my $self = shift;
	my $query = shift;
	return unless $query;
	$self->query($query);
	$self->init();
	
	my $fetch_size = shift;
	$fetch_size ||= $self->fetch_max();

	return $self->next($fetch_size);
}

sub get_sequence {
	my $self = shift;
	my $id = shift;
	my $db = shift;	
	$db ||= $self->db();
	die "\nDatabase (2nd arg) not specified" unless $db;
	if($db && !($db =~ /(protein)|(nucleotide)/i)){
		die "\nSecond argument (database) must be 'protein' or 'nucleotide'";
	}
	$self->db($db);
	$self->format("fasta");
	my $result = $self->fetch($id, 1);
	$result =~ s/>.*?\n//s;
	return $result;
}

sub run_terminal {
	my $self = shift;
	$self->ask_for_input();
	print "\nRunning query...\n";
	$self->init();
	$self->terminal_fetch();
}

sub ask_for_input {
	my $self = shift;
	$self->db(ask_user("Database", "Protein"));
	$self->query(ask_user("Query",    "Cytochrome P450"));
	$self->format(ask_user("Format",   "Fasta"));
}

sub terminal_fetch {
	my $self = shift;
	while(my $result = $self->next()){
		print $result;
		my $first = $self->fetch_start() - $self->fetch_size() + 1;
		my $last = $first + $self->fetch_size() - 1;
		$last = $self->count() if $last > $self->count();
		print "\nResults $first - $last out of " . $self->count() . "\n";
		my $press_msg = "Press <return> to fetch next " . $self->fetch_size() . " results...";
		print "\n" . ("=" x (length($press_msg))) . "\n";
		print "$press_msg\n";
	 	<STDIN>;
		print "\nFetching...\n";
	}
}

#Utility Methods
sub ask_user {
  print "$_[0] [$_[1]]: ";
  my $rc = <>;
  chomp $rc;
  if($rc eq "") { $rc = $_[1]; }
  return $rc;
}


1;
