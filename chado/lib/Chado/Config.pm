package Chado::Config;

=head1 NAME

Chado::Config

=head1 SYNOPSIS

  my $config  = Chado::Config->new;
  my $db_name = $config->{'database'}{'db_name'};

=head1 DESCRIPTION

This module is a simple interface to the Chado installation 
configuration information.

=head1 METHODS

=cut

use strict;
use Carp;
use FindBin '$Bin';
use File::Spec::Functions;
use XML::Simple;

use constant DEFAULT_FILENAME => catfile( $Bin, 'load', 'etc', 'load.conf' );

# ---------------------------------------------------------
=pod

=head2 new

Instantiates a new object.  Takes an optional (but preferred) 
argument of the configuration file's path.  The filename should be 
indicated as a key/value pair, but, if only one argument is passed
in, it is assumed to be the filename.

  my $conf = Chado::Config->new;
  my $conf = Chado::Config->new( <filename> );
  my $conf = Chado::Config->new( filename => <filename> );

=cut

sub new {
    my $class = shift;
    my $args  = defined $_[0] && UNIVERSAL::isa( $_[0], 'HASH' ) ? shift
                : scalar @_ == 1 ? { filename => shift }
                : { @_ };
    my $self  = bless {}, $class;

    if ( $args->{'filename'} ) {
        $self->filename( $args->{'filename'} ); 
    }

    return $self;
}

# ---------------------------------------------------------
=pod

=head2 filename

Gets/sets the location of the configuration file.

  my $file = $conf->filename( <filename> );

=cut

sub filename {
    my ( $self, $arg ) = @_;

    if ( ! defined $self->{'filename'} && ! $arg ) {
        $arg = DEFAULT_FILENAME if -e DEFAULT_FILENAME;
    } 

    if ( $arg ) {
        if ( -e $arg && -r _ ) {
            $self->{'filename'} = $arg; 
        }
        else {
            croak("The file '$arg' does not exist or is not readable");
        }
    }

    return $self->{'filename'};
}

# ---------------------------------------------------------
=pod

=head2 config 

Returns the configuration information as parsed by XML::Simple.

  my $options = $conf->config;

=cut

sub config {
    my $self = shift;
    unless ( defined $self->{'config'} ) {
        my $file = $self->filename;
        $self->{'config'} = XMLin(  
            $file,
#            ForceArray => [ qw( template token path file) ],
#            KeyAttr    => [ qw( token name file) ],
            ContentKey => '-value',
        );
    }
    return $self->{'config'};
}

# ---------------------------------------------------------
=pod

=head1 SEE ALSO

XML::Simple.

=head1 AUTHOR

Ken Y. Clark E<lt>kclark@cshl.orgE<gt>.

=cut

1;
