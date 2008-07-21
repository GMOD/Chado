package Bio::GMOD::CAS::Util;
use Config::General;

my $VERSION = 0.1;

#configured at install

sub new {
  my ($class, @args) = @_;

  my $cas_conf_file = '/usr/local/gmod/conf/cas.conf';
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

