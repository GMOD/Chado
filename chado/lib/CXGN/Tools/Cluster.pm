package CXGN::Tools::Cluster;
use strict;
use constant DEBUG => $ENV{CLUSTER_DEBUG};
use POSIX qw/ ceil /;

use Time::HiRes qw/usleep/;

=head1 NAME

CXGN::Tools::Cluster

=head1 SYNOPSIS

 Base class for cluster programs, such as ModelPAUP, SignalP, and more!

=head1 USAGE
 
 my $proc = CXGN::Tools::Cluster::(Program)->new({ 
            in => $input_filepath,
			out => $output_filepath,
			host => "solanine",
			job_wait => 10 });
 $proc->submit(); 
 $proc->spin();
 #Done!

=cut

BEGIN {
	print STDERR "\nDEBUG MODE\n" if DEBUG;
}

=head2 new()
 
 Args: Argument hash reference, with
          in => (optional) input file, if you are splitting one file.  
		        If you don't use this, you should send an input file
                as an argument to the submit() subroutine
          out => output result file
		  host => cluster host name, defaults to "solanine"
		  job_wait => refresh time for calling qstat while spinning

 Ret: A cluster object

=cut

sub new {
	my $class = shift;
	my $self = bless {}, $class;
	my $args = shift;
	
	$self->cluster_host($args->{cluster_host});
	$self->job_wait($args->{job_wait});
	$self->tmp_base($args->{tmp_base});
	$self->infile($args->{in});
	$self->outfile($args->{out});

	$self->cluster_host("solanine") unless $self->cluster_host();
	$self->run_locally($args->{run_locally});
	$self->tmp_base(".") if($self->run_locally() && !$args->{tmp_base});
	$self->tmp_base("/data/shared/tmp") unless $self->tmp_base();
	$self->job_wait(10) unless $self->job_wait();

	return $self;
}

=head2 submit()

	This function should either 
	1) Use the infile, split it up, and submit all jobs, set cluster_outs() and jobs()
	2) Take one input file, submit one job, push cluster-outfile and job onto the
	   cluster_outs() and jobs() arrays.

=cut

sub submit {
	die "Override this function in a subclass"
}

=head2 chill()

 Prevent submission to qsub from happening too quickly.  Call $self->chill()
 before submitting a job in subclasses

=cut

sub chill {
	my $self = shift;
	my $msec = shift;
	$msec ||= 250_000;	
	usleep($msec); #4 per second, at most
}

=head2 alive()

 Returns 1 if jobs are still running, 0 if all jobs are done (or no jobs exist)

=cut

sub alive {
	my $self = shift;
	my $job_array = $self->jobs();
	my $running = 0;
	foreach(@$job_array){
		$running = 1 if $_->alive();
	}
	return $running;
}

=head2 spin()

 Keeps checking <-> sleeping until all the jobs are
 no longer alive.
 
 Args: (optional) wait time in seconds between qstat calls, 
                  uses $self->job_wait() otherwise
 Ret: Nothing

=cut

sub spin {
	my $self = shift;
	my $wait_time = shift;
	$wait_time ||= $self->job_wait();
	print STDERR "\nAll jobs submitted, now we wait...";
	while($self->alive()){
		sleep($wait_time);
		print STDERR "." if DEBUG;
	}
}

=head2 job_sizes()
 
 A handy little utility to get chunks of roughly equal size
 Args: Total Size, Minimum # of Pieces, Maximum Piece Size
 Ret:  An array of integers, each one a piece size for a chunk

=cut

sub job_sizes {
	my $self = shift;
	my ($total_size, $min_pieces, $max_piece_size) = @_;
	
	my @sizes = ();
	my $first_size = ceil($total_size / $min_pieces);
	
	my $piece_size = $max_piece_size + 1;
	if($first_size <= $max_piece_size){
		$piece_size = $first_size;
	}
	else{
		$piece_size = $max_piece_size;	
		my $num_pieces = ceil($total_size / $piece_size);
		until($num_pieces >= $min_pieces){
			$piece_size = int($piece_size * 0.5);	
			$num_pieces = ceil($total_size / $piece_size);
		}
	}
	my $sum = 0;
	my $remaining = 0;
	until($sum >= $total_size){
		my $remaining = $total_size - $sum;
		if($remaining <= $piece_size){
			push(@sizes, $remaining);
			last;
		}
		else {
			$sum += $piece_size;
			push(@sizes, $piece_size);
		}
	}
	return @sizes;
}

=head2 concat()
 
 Concatenates all of the cluster_outs() into outfile() 

=cut

sub concat {
	my $self = shift;
	my $outfiles = $self->cluster_outs();
	open(WF, ">" . $self->outfile())
		or die "\nCan't open final write file: $!";
	print STDERR "\nConcatenating cluster outputs to final file";
	foreach(@$outfiles){
		open(RF, $_);
		print WF $_ while(<RF>);
		close(RF);
		print STDERR ".";
	}
	close(WF);
}

=head2 push_job() and push_cluster_out()

 *Push a job onto the jobs() array ref
 *Push an output file on the cluster_outs() array ref

=cut

sub push_job {
	my $self = shift;
	my $job = shift;
	return unless $job;
	my $jobarray = $self->jobs();
	push(@$jobarray, $job);
	$self->jobs($jobarray); #I don't need to do this, do I?
}

sub push_cluster_out {
	my $self = shift;
	my $cluster_out = shift;
	return unless $cluster_out;
	my $array = $self->cluster_outs();
	push(@$array, $cluster_out);
	$self->cluster_outs($array); #I don't need to do this, do I?
}

=head2 Getter/Setters

 jobs() - an array reference of the jobs returned by CXGN::Tools::Run
 outfile() - the final output file of the process, usually concatenated
             from the cluster outputs
 infile() - the original input file for the process
 cluster_outs() - array reference to cluster output files, as you choose
                  them to be.  Standard concat() function takes these
                  and glues them together into the outfile()
 temp_dir() - the temporary directory where all the cluster outputs and
              cluster process information is stored. Usually a subdirectory
			  of /data/shared/tmp, but whatever you want it to be
 tmp_base() - base directory for temporary files, use this to build temp_dir(),
              defaults to "/data/shared/tmp"
 cluster_host() - the name of the cluster server, defaults to "solanine"
 job_wait  - seconds to wait before checking qstat again, defaults to 10 
 run_locally - flag to run process locally instead of on cluster (say whaaat?)
               this can be implemented in subclasses however you like 


=cut

sub jobs {
	my $self = shift;
	my $jobs = shift;
	if($jobs && ref($jobs) eq "ARRAY"){
		$self->{jobs} = $jobs;
	}
	return $self->{jobs};
}

sub outfile {
	my $self = shift;
	my $outfile = shift;
	if($outfile) { 
		$self->{outfile} = $outfile;
	}
	return $self->{outfile};
}

sub stdout {
	my $self = shift;
	my $stdout = shift;
	if($stdout) { 
		$self->{stdout} = $stdout;
	}
	return $self->{stdout};
}

sub stderr {
	my $self = shift;
	my $stderr = shift;
	if($stderr) { 
		$self->{stderr} = $stderr;
	}
	return $self->{stderr};
}

sub infile {
	my $self = shift;
	my $infile = shift;
	if($infile) { 
		$self->{infile} = $infile;
	}
	return $self->{infile};
}

sub cluster_outs {
	my $self = shift;
	my $cluster_outs = shift;
	if($cluster_outs && ref($cluster_outs) eq "ARRAY"){
		$self->{cluster_outs} = $cluster_outs;
	}
	return $self->{cluster_outs};
}

sub temp_dir {
	my $self = shift;
	my $temp_dir = shift;
	if($temp_dir){
		$self->{temp_dir} = $temp_dir;
	}
	return $self->{temp_dir};
}

sub cluster_host {
	my $self = shift;
	my $cluster_host = shift;
	$self->{cluster_host} = $cluster_host if $cluster_host;
	return $self->{cluster_host};
}

sub job_wait {
	my $self = shift;
	my $job_wait = shift;
	$self->{job_wait} = $job_wait if $job_wait;
	return $self->{job_wait};
}

sub tmp_base {
	my $self = shift;
	my $tmp_base = shift;
	$self->{tmp_base} = $tmp_base if $tmp_base;
	return $self->{tmp_base};
}

sub run_locally {
	my $self = shift;
	my $flag = shift;
	return $self->{run_locally} unless defined $flag;
	$self->{run_locally} = $flag;
}

1;
