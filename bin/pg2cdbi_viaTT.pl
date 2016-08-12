#!/usr/bin/env perl
# vim: set ft=perl ts=2 expandtab:

use strict;
use SQL::Translator;
use lib './bin';
use Skip_tables qw( @skip_tables );

unless ( scalar @ARGV > 3 ) {
  die "USAGE: $0 <dbname> <username> <password> <sql file> [<sql files>]\n";
}

my $db_name     = shift @ARGV;
my $db_username = shift @ARGV;
my $db_password = shift @ARGV;
my $dsn         = "dbi:Pg:dbname=$db_name";
my $translator  = SQL::Translator->new(
  from          => 'PostgreSQL',
  to            => 'TTSchema',
  filename      => \@ARGV,
  producer_args => {
    tt_vars => {
      db_user     => $db_username,
      db_pass     => $db_password,
      db_dsn      => $dsn,
      baseclass   => 'Bio::Chado::DBI',
      format_fk   => \&generate_file_y,
      format_node => \&format_table_name,
      format_refers => \&format_refers,
    },
    ttfile    => "./bin/dbi.tt2",
  },
  filters       => [
                   sub {
                     my $schema = shift;
                     foreach (@skip_tables) {
                       $schema->drop_table($_);
                     }  
                   },
  ],
);


my $output = $translator->translate or die $translator->error;
print $output;

#stolen from turnkey_generate script
sub generate_file_y {
  my $table_name = shift;
  my $field_name = shift;
  $field_name =~ s/_id$//;
  return $field_name;
}

sub format_table_name {
  my $table_name = shift;
  my $first_char = substr($table_name,0,1);
  substr($table_name,0,1,uc($first_char));
  $table_name =~ s/_(\w)/'_'.uc($1)/eg;
  return $table_name;
}

sub format_refers {
  my $table_name = shift;
  my $field_name = shift;
  return "--$table_name--$field_name--";
}
