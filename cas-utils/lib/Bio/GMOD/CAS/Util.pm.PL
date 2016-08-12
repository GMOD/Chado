#!perl

use strict;
use CASBuilder;
use Cwd;
use File::Basename qw(&basename &dirname);
use File::Spec::Functions;

my $builder   = CASBuilder->current;
my $conf_dir  = $builder->notes('CONF');
my $conf_file = catfile( $conf_dir, 'cas.conf');

my $origdir = cwd;
chdir dirname($0);
my $file;
($file = basename($0)) =~ s/\.PL$//;

open OUT, ">$file" or die "Cannot write file '$file': $!\n";
print "Extracting $file (with variable substitutions)\n";
print OUT<<'NOGROK';
package Bio::GMOD::CAS::Util;
use Config::General;

sub new {
  my ($class, @args) = @_;

#This is configured at install time; don't change the path to this file
#without also actually moving the file 
NOGROK

print OUT "  my \$cas_conf_file = '$conf_file';
";

print OUT << 'END';
  my $conf = Config::General->new($cas_conf_file);
  my %config = $conf->getall;

  my $self = bless {}, $class;

  $self->{'config'} = \%config;

  return $self;
}

sub AUTOLOAD {
  $self = shift;
  use vars qw($AUTOLOAD);
  my $tag = $AUTOLOAD;
  $tag    =~ s/.*:://;
  return $self->{'config'}->{$tag};
}

1;

=pod

=head1 AUTHOR

Scott Cain, cain.cshl@gmail.com

=head1 COPYRIGHT

2008, All rights reserved

=cut

END

close OUT;
