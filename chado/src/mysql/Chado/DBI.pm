package Chado::DBI;

my $USER ||= 'nobody';
my $PASS ||= '';

use base 'Class::DBI::mysql';

Chado::DBI->set_db(
			'Main',
			'dbi:mysql:chado_wax;host=sumo',
			$USER,
			$PASS,
		  );

sub _set_db {

  warn $USER;
  warn $PASS;

  Chado::DBI->set_db(
			'Main',
			'dbi:mysql:chado_wax;host=sumo',
			$USER,
			$PASS,
		    );
}

sub user {
warn "user()";
  my $pack = shift;
  $USER = shift if @_;
  _set_db();
  return $USER;
}

sub pass {
warn "pass()";
  my $pack = shift;
  $PASS = shift if @_;
  _set_db();
  return $PASS;
}

1;
