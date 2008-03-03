=head1 NAME

 CXGN::DB::Production

=head1 WHY?

 Same idea as CXGN::DB::Sandbox, except you might want to run a script
 explicitly on the production database.

=head1 AUTHOR

 Christopher Carpita <csc32@cornell.edu>

=cut

package CXGN::DB::Production;
use strict;
use base qw/CXGN::DB::Connection/;

sub new {
	my $class = shift;
	my $custom_args = shift;
	my $db_args = { 
		dbname => "cxgn",
		dbhost => "hyoscine",
		dbschema => "public",
		dbbranch => "production",
		dbargs => { RaiseError=>0, AutoCommit=>1, PrintError=>0 }
	};
	while(my($key, $value) = each %$custom_args){
		$db_args->{$key} = $value;
	}
	my $self = $class->SUPER::new($db_args);
	return $self;
}
		
1;


