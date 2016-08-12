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
  to            => 'ClassDBI',
  filename      => \@ARGV,
  producer_args => {
    db_user     => $db_username,
    db_pass     => $db_password,
    dsn         => $dsn,
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

$translator->format_package_name(\&x);
$translator->format_pk_name(sub {return 'id';});
$translator->format_fk_name(\&y);

my $output = $translator->translate or die $translator->error;

print $output;

sub x { 
  my ($name, $primary_key) = @_;
  my $package_name;
  my @temp = split(/_/,$name);

  for(my $i = 0; $i < scalar(@temp); $i++) {
    my $new_name = ucfirst($temp[$i]);
    if($i == 0) {
      $package_name .= $new_name;
    } else {
      $package_name .= "_" .$new_name;
    }
  }

  $package_name = 'Bio::Chado::CDBI::' . $package_name;

  return $package_name;
}

sub y {
  my $table_name = shift;
  my $field_name = shift;
  $field_name =~ s/_id$//;
  return $field_name;
}
