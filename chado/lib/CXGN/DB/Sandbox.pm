=head1 NAME

 CXGN::DB::Sandbox

=head1 WHY?

 I want something simple for standalone scripts that may make weird calls 
 and lock or mess up the database.  I don't want to change my environmental
 variables every time, so I think it's easier to just call this, and it
 helps set the "tone" of the particular script.  All this does is provide
 standard arguments to CXGN::DB::Connection for a Sandbox connection, 
 public schema.  You can provide further arguments, or replace the standard
 ones that I've made, the same as you do with the standard Connection module.

=head1 AUTHOR

 Christopher Carpita <csc32@cornell.edu>

=cut

package CXGN::DB::Sandbox;
use strict;
use base qw/CXGN::DB::Connection/;
sub new {
	my $class = shift;
	my $custom_args = shift;
	my $db_args = { 
		dbname => "sandbox",
		dbhost => "scopolamine",
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

