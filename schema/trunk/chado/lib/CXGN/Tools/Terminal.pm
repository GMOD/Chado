package CXGN::Tools::Terminal;

use strict;

=head1 CXGN::Tools::Terminal

 Little utilities for terminal-based scripts

=cut

use base qw/Exporter/;

BEGIN {
	our @EXPORT_OK = qw/ get_userpass 
						 progress 
						 confirm 
						 /
}


sub get_userpass {
	print "\nEnter username: ";
	my $username = <STDIN>;
	chomp $username;
	print "Enter password: ";
	system "stty -echo";
	my $password = <STDIN>;
	system "stty echo";
	print "\n";
	chomp $password;
	return ($username, $password);
}


sub progress {
	my ($count, $max) = @_;
	return unless($count && $max);  #count=0 returns immediately, count = 1 starts it off
	if($count==1){ print "\nProgress:||"}
	my $step_size = int($max / 8) - 1;
	if($count==$step_size) { print "===12%"; }
	elsif($count==2*$step_size) { print "===25%";}
	elsif($count==3*$step_size) { print "===37%";}
	elsif($count==4*$step_size) { print "===50%";}
	elsif($count==5*$step_size) { print "===62%";}
	elsif($count==6*$step_size) { print "===75%";}
	elsif($count==7*$step_size) { print "===88%";}
	elsif($count==8*$step_size) { print "===100%\n";}

}

sub confirm {
	my $message = shift;
	$message =~ s/\s+$//;
	$message .= "," unless $message =~ /\.$/;
	print $message;
	print " Continue? [y/n]: ";
	my $r = <STDIN>;
	return 1 unless $r =~ /^n/i;
	return 0;
}



1;

