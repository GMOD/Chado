
=head1 CXGN::Tools::Param

 Export OK functions to build URL and Form parameter strings

=head1 Author

C. Carpita <csc32@cornell.edu>

=cut


package CXGN::Tools::Param; 
use strict;

use base qw/Exporter/;

BEGIN {
	our @EXPORT_OK = qw/ hash2param hash2hiddenpost /

}

=head2 hash2param()

 Given a hash reference, build an argument string

 Args: A common hash ref with parameters, and optional
       second hash ref with modified parameters
 Ret: URL param string, starting w/ "&arg1=val1..."
 Ex:  my $argstring = hash2param($std_arghashref, { hide => 1, arg2 => "scooter", formica => "kitsch" });
      print $argstring;  # prints '&otherargs=stuff...&hide=1&arg2=scooter&formica=kitsch'

 Useful when you maintain settings in a hash and need to modify
 different arguments and build several different URL's with GET
 params

=cut

sub hash2param {
	my $hashref = shift;
	my $modifyref = shift;
	return unless ref($hashref) eq "HASH";
	
	my $string = "";

	my %hash = %$hashref;
	while(my($k, $v) = each %$modifyref){
		next unless $k;
		$hash{$k} = $v;
	}

	while(my($k, $v) = each %hash){
		next unless $k && defined $v;
		$string .= "&$k=$v";
	}
	return $string;
}

=head2 hash2hiddenpost()

 Works like hash2param, except it returns several lines of <input type="hidden ..>
 tags instead of a URL string.  Takes a third argument, an array reference of
 fields to exclude, since another form element may be providing the argument.

=cut

sub hash2hiddenpost {
	my $hashref = shift;
	my $modifyref = shift;
	my $exclude_array = shift;
	return unless ref($hashref) eq "HASH";

	my %hash = %$hashref;
	if(ref($modifyref) eq "HASH"){
		while(my($k, $v) = each %$modifyref){
			next unless $k;
			$hash{$k} = $v;
		}
	}
	if(ref($exclude_array) eq "ARRAY"){
		delete $hash{$_} foreach(@$exclude_array);
	}
			
	my $string = "";
	while(my($k, $v) = each %hash){
		next unless $k;
		$string .= "\n<input type=\"hidden\" name=\"$k\" value=\"$v\" />";
	}
	return $string;	
}

1;

