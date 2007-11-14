package Bio::GMOD::DB::Tools::ETA;
$|=1;  #does this help?

=head1 Bio::GMOD::DB::Tools::ETA

 A nice little package for displaying the ETA for a process in a terminal


=head1 USAGE

 my $eta = Bio::GMOD::DB::Tools::ETA->new();
 $eta->interval(1.2) #only allow updates 1.2 seconds after the last update
 my $i=0;
 $eta->begin(); #sets start time
 $eta->target(3000); #total # of iterations expected
 while($row = ...){
	#doing stuff
	#whoop-de-do
	$i++;
	$eta->update_and_print($i);
 }

 #Prints something like:  
 #ETA: 01:33:34

 Don't print any newlines if you want the ETA to be displayed in-place!

=cut


sub new {
	my $class = shift;
	my $self = bless {}, $class;
	$self->{increment} = 1;
	$self->{begin} = time();
	$self->{last_update} = time();
	$self->{current} = 0;
	$self->{interval} = 0;
	return $self;
}

sub begin {
	my $self = shift;
	$self->{begin} = time();
}

sub target {
	my $self = shift;
	my $target = shift;
	$self->{target} = $target if $target;
	return $self->{target};
}

sub interval {
	my $self = shift;
	my $interval = shift;
	$self->{interval} = $interval if $interval;
	return $self->{interval};
}

sub update {
	my $self = shift;
	my $current = shift;
	if($self->{interval} > 0){
		$diff = time() - $self->{last_update};
		return if $diff < $self->{interval};
	}
	$self->{current} = $current;
	$self->{elapsed} = time() - $self->{begin};
	$self->{elapsed} ||= 1; #round up to 1 second, at least
	$self->{remaining} = $self->{target} - $self->{current};
	$self->{rate} = ($self->{current})/$self->{elapsed};
	$self->{eta} = $self->{remaining}/$self->{rate};
	$self->{last_update} = time();
}

sub update_and_print {
	my $self = shift;
	if($self->{interval} > 0) {
		$diff = time() - $self->{last_update};
		return if $diff < $self->{interval};
	}
	$self->update( shift );
	$self->print();
}

sub print {
	my $self = shift;
	print ( " " x 80 . "\r" x 200 );
	print "ETA: " . $self->format_secs($self->{eta});		
}

sub format_secs {
	my $self = shift;
	my $sec = int( shift );
	my $hour = 0;
	my $min = 0;
	if($sec > 60){
		$min = int($sec / 60);
		$sec = $sec - $min*60;
		if($min > 60){
			$hour = int($min / 60);
			$min = $min - $hour*60;
		}
	}
	foreach($sec, $hour, $min){
		next unless $_<10;
		$_ = "0" . $_;
	}
	return "$hour:$min:$sec";
}

1;
