package CXGN::Tools::Parse;
use strict;

=head1 CXGN::Tools::Parse

 Interface-like base class for CXGN parsers.  
 
 Two different methods are encouraged:
 1) Give a filename to new(), and a filehandle is created, 
    and you can parse one entry at a time w/ next().
 2) Send raw data to new(), and automatically parses everything
    at once with parse_all(), pushing each entry, as a hash ref, 
	to @{$self->{entries}}

=head1 Author

 C. Carpita <csc32@cornell.edu>

=head1 Methods

=cut

=head2 new()

 Args: (opt) raw output data
 Ret: Parser object
 Side: Calls parse() automatically if argument provided

=cut

sub new {
	my $class = shift;
	my $self = bless {}, $class;
	my $data_or_file = shift;
	if(-f $data_or_file){
		$self->{file} = $data_or_file;
		my $fh;
		open($fh, $self->{file}) or die "Can't open file for reading: " . $self->{file} . "\n";
		$self->{fh} = $fh;
	}
	else{
		$self->{data} = $data_or_file;
		$self->{data_to_parse} = $data_or_file;
		$self->parse_all_data();
	}
	return $self;
}

sub parse_all {
	my $self = shift;
	while(my $entry = $self->next()){
		push(@{$self->{entries}}, $entry);
		$self->{entry_by_id}->{$entry->{id}} = $entry;
	}
}	

sub get_entry_by_id {
	my $self = shift;
	my $id = shift;
	return $self->{entry_by_id}->{$id};
}

sub get_all_entries {
	my $self = shift;
	return @{$self->{entries}};
}

sub next {
	my $self = shift;

	#Do stuff with this:
	#my $data = $self->{data_to_parse};
	# grab entry, set hash, then...
	# $self->{data_to_parse} = $data_with_stuff_chopped_off
	# then return hashref
	#
	#or this, if filehandle exists:
	#
	#my $fh = $self->{fh};	
	# do filehandle reads, grab entry, set hash
	# return hashref
	#

	die "Override this function in a subclass";	

}


sub DESTROY {
	my $self = shift;
	$self->{fh}->close() if $self->{fh};
}

1;
