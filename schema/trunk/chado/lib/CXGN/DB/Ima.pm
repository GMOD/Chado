package CXGN::DB::Ima;

=head1 NAME

CXGN::Ima::DBI - subclass of Ima::DBI, customizing it for use with the
CXGN DB infrastructure

=head1 SYNOPSIS

  ## this is a complete working script, notice you don't
  ## have to create any database connections

  package mything;
  use base qw/ Ima::DBI /;

  __PACKAGE__->set_sql( get_all_foos => <<EOSQL );
  select name from foo
  EOSQL

  my $sth = __PACKAGE__->sql_get_all_foos;
  $sth->execute;
  my $foo_names = $sth->fetchall_arrayref;

=head1 DESCRIPTION

This is a customized subclass of Ima::DBI, an off-the-shelf,
well-tested connection sharing solution used by the popular
object-relational mapping package Class::DBI.

The reasons to use this package is that ALL SUBCLASSES OF THIS
PACKAGE SHARE THE SAME 'cxgn' DATABASE HANDLE.

The changes are:
  - the DB handles it manages are now CXGN::DB::Connections,
    not regular DBI connections
  - the DB name in set_sql now defaults to 'cxgn', whereas in
    vanilla Ima::DBI, it had no default

=head1 BASE CLASS(ES)

L<Ima::DBI>

=head1 AUTHOR(S)

Robert Buels

=cut

use strict;
use base qw/ Ima::DBI /;
use CXGN::DB::Connection;

sub set_db {
  my $class = shift;
  my $db_name = shift or $class->_croak("Need a db name");
  $db_name =~ s/\s/_/g;

  $class->_remember_handle($db_name);
  no strict 'refs';
  *{ $class . "::db_$db_name" } =
    $class->_make_cxgn_db_closure(@_);

  return 1;
}

sub _make_cxgn_db_closure {
  my ($class, @connection) = @_;
  my $dbh;
  return sub {
    unless ($dbh && $dbh->FETCH('Active') && $dbh->ping) {
      $dbh = CXGN::DB::Connection->new(@connection);
    }
    return $dbh;
  };
}

#add a 'cxgn' default
sub set_sql {
  my $class = shift;
  $_[2] ||= 'cxgn';
  $class->SUPER::set_sql(@_);
}

#make a db_Main with default connection args
__PACKAGE__->set_db( 'cxgn' );
