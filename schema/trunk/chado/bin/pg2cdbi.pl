#!/usr/bin/perl
use strict;
use SQL::Translator;
use SQL::Translator::Producer::ClassDBI;

my @files = @ARGV;

my $translator     = SQL::Translator->new();

my $config = { from       => "PostgreSQL", 
	       to         => "ClassDBI",
	       filename   => \@files,
	     };

$translator->format_package_name(\&x);
$translator->format_pk_name(sub {return 'id';});
$translator->format_fk_name(\&y);

my $output = $translator->translate($config) or die $translator->error;

print $output;


sub x { 
my ($name, $primary_key) = @_;

my $package_name;

my @temp = split(/_/,$name);

for(my $i = 0; $i < scalar(@temp); $i++) {
  my $new_name = ucfirst($temp[$i]);

  if($i == 0) {
	$package_name .= $new_name;
  }else {
	$package_name .= "_" .$new_name;
  }

}


$package_name = 'Chado::' . $package_name;

return $package_name;

}

sub y {
  my $table_name = shift;
  my $field_name = shift;
  $field_name =~ s/_id$//;
  return $field_name;
#  return $table_name;
}

