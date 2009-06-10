package CXGN::Class::Exporter;
use strict;
no strict 'refs';

# VERBOSE: Developer Variable, default quiet
# 0: non-verbose, no developer messages
# 1: print messages on DBH exchange
# 2: print messages on any import() call
# Usage:
# BEGIN {
# 	require CXGN::Class::Exporter;
# 	$CXGN::Class::Exporter::VERBOSE = 2;
# }
our $VERBOSE = 1;

BEGIN {
	#Uses the default exporter, want to allow subclasses to use
	#our importer for DBH-exchange capability
	our @EXPORT_OK = qw/
		import
		looks_like_DBH
		looks_like_dbh
	/;
}
our @EXPORT_OK;

sub dprint {
	#We can have this do nothing to kill the dprint messages
	#Need to make sure DBH exchanging actually works
	return unless $VERBOSE;	
	my $msg = shift;
	chomp $msg;
	print STDERR "# " . $msg . "\n";
}

=head1 NAME

 CXGN::Class::Exporter

=head1 DESCRIPTION

 Use this as a base class to get a standard CXGN import() function on your class,
 which does a few cool things:
 1) Implements its own light-weight EXPORT/EXPORT_OK routine
 2) Can take one hash ref as a set of class routines to execute, with scalar/ref argument.
 	If sub doesn't exist, will just set package scalar in the importing module
 3) Handles exchange of global database handles between modules

 Example:
 use CXGN::DB::Connection qw/export this and that/ { verbose => 0 }
 #equivalent to CXGN::DB::Connection->verbose(0);

=head1 USAGE

 package Foo;
 use base qw/CXGN::Class::Exporter/;

 BEGIN {
 	our @EXPORT_OK = qw/works like Exporter/;
	our @EXPORT = qw/ditto/;
 }
 our @EXPORT_OK;
 our @EXPORT;
 
 our $EXCHANGE_DBH = 1; #pushes or pulls global $DBH to anything that uses this module
 #our $IMPORT_DBH = 1; would only pull a $DBH from the using script/module
 #our $EXPORT_DBH = 1; would only push a $DBH to the using script/module
 
 sub baz {
    my $arg = shift;
	$Foo::Bar = $arg;
 }
 sub works { }
 sub ditto { }
 sub like { }
 sub Exporter { }

 1;

 package main;

 use Foo qw/works/, { baz => 1 };

 print "YaHoo!" if defined(&works) && defined(&ditto);


=head1 IMPORT_DBH

 Setting the package variable IMPORT_DBH to 'true' within a class will
 attempt DBH-importing.  This means that if $DBH is defined within the
 calling script/class, then it will be grabbed and set as a the DBH
 package variable within the importer.

 This is part of an effort to minimize connections to the database.
 The idea is that all classes that need database access should use
 global database handles, which can be grabbed from other classes.

 If fresh handles are needed, they could always be created at-will.


=head1 AUTHOR

 C. Carpita

=cut

sub import {
	my $class = shift;
	my @args = @_;
	my $pkg = caller(0);
	dprint "$class importer called by $pkg with args: " . join(", ", @args) . "\n" if $VERBOSE > 1;
	my @expok = grep { !ref && /^[\$\@\%\*&]?\w+$/ } @args;
	CXGN::Class::Exporter->export($class, $pkg, @expok);
	
	my @refs = grep { ref eq "HASH" } @args;
	if (@refs > 1) {
		die "Error: $pkg sent multiple hash ref import-arguments to $class\n";
	}
	if(@refs){
		my $args = $refs[0];
		while(my($k,$v) = each %$args){
			if(defined(&{$class."::".$k})){
				$class->$k($v);
			}
			else {
				${$class."::$k"} = $v;
			}
		}
	}
	CXGN::Class::Exporter->resolve_DBH_exchange($class, $pkg);	
}

sub export {
	my $this = shift;
	my ($source, $target, @ok) = @_;
	foreach my $export (@{$source.'::EXPORT'}){
		$this->export_variable($source, $target, $export);	
	}
	my %export_ok = ();
	$export_ok{$_} = 1 foreach(@{$source.'::EXPORT_OK'});
	foreach my $ok (@ok){
		die "Package $source does not list '$ok' within EXPORT_OK\n" unless $export_ok{$ok};
		$this->export_variable($source, $target, $ok);
	}
}

sub export_variable {
	my $this = shift;
	my ($source, $target, $var) = @_;
	my ($type) = $var =~ /^([\$\@\%&\*])/;
	if(defined($type)){
		$var =~ s/\Q$type\E//;
		${$target.'::'.$var} = ${$source.'::'.$var} if $type eq '$';
		@{$target.'::'.$var} = @{$source.'::'.$var} if $type eq '@';
		%{$target.'::'.$var} = %{$source.'::'.$var} if $type eq '%';
		*{$target.'::'.$var} = *{$source.'::'.$var} if $type eq '*';
		*{$target.'::'.$var} = \&{$source.'::'.$var} if $type eq '&';
	}
	else {
		warn "Method \&${source}::$var() does not exist\n" unless defined(&{"${source}::$var"});
		*{$target.'::'.$var} = \&{$source.'::'.$var};
	}
}

sub resolve_DBH_exchange {
	my $this = shift;
	my $class = shift;
	my $pkg = shift;
	
	my $lldbh = sub { $this->looks_like_DBH(@_) };
	no warnings 'once';
	if( ${$class."::IMPORT_DBH"}  && $lldbh->(${$pkg."::DBH"}) && !$lldbh->(${$class."::DBH"}) ){
		dprint "$class is pulling its DBH from $pkg\n";
		$this->send_DBH($pkg, $class);	#Pull the DBH from $pkg
	}

	elsif ( ${$class."::EXPORT_DBH"} 
		&& $lldbh->(${$class."::DBH"})
		&& !$lldbh->(${$pkg."::DBH"})
	) {
		dprint "$class is pushing its DBH to $pkg\n";
		$this->send_DBH($class, $pkg); #push DBH to $pkg
	}
	elsif (${$class."::EXCHANGE_DBH"} && ${$pkg."::EXCHANGE_DBH"}){
		if(
			$lldbh->(${$class."::DBH"})
			&& !$lldbh->(${$pkg."::DBH"})
		){
			dprint "$class exchanging (push) its DBH with $pkg\n";
			$this->send_DBH($class, $pkg);
		}
		elsif(
			$lldbh->(${$pkg."::DBH"})
			&& !$lldbh->(${$class."::DBH"})
		){
			dprint "$class exchanging (pull) its DBH with $pkg\n";
			$this->send_DBH($pkg, $class);
		}
	}
}

sub send_DBH {
	my $this = shift;
	my $source = shift;
	my $dest = shift;
	my $DBH = ${$source."::DBH"};
	return unless defined $DBH;
	return unless $this->looks_like_DBH($DBH);
	if(defined(&{$dest."::DBH"})){
		DBH $dest $DBH;
	}
	else {
		${$dest."::DBH"} = $DBH;
	}
}

sub looks_like_DBH {
	my $this = shift;
	my ($DBH) = @_;
	$DBH = $this if (ref($this) && !$DBH); #used :: (or exported) form of sub
	return 0 unless defined($DBH);
	return 0 unless ref($DBH);
	my $debug = '';
	eval {
		$DBH->can("anything");
	};
	return 0 if $@;
	foreach(qw/disconnect prepare commit quote do selectall_hashref ping tables/){
		return 0 unless defined &{ref($DBH).'::'.$_};
	}
	return 1;
}

*looks_like_dbh = \&looks_like_DBH;

1;
