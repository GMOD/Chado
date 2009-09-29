=head1 NAME

CXGN::Debug - a utility class for handling debug messages

=head1 DESCRIPTION

Use CXGN::Debug for inserting debugging messages in your code. Example:

  use CXGN::Debug;

  #normal usage
  my $d = CXGN::Debug->new();
  $d->d("blablalba");


  # use for only a portion of your code
  $d->set_debug( 1 );
  # do something
  $d->set_debug( 0 );

The debug messages are printed to STDERR in a terminal context, and to
the Apache error log in a mod_perl context.

For CXGN objects, you could inherit from CXGN::Debug.  Be sure to call
__PACKAGE__->SUPER::new() in any constructors that you write, though.

=head1 SWITCHING OFF AND ON

When a Debug object is created, it sets itself to be either on or off
(that is, printing or non-printing) based on:

     the debug => option to its constructor, if passed
  or if that is not passed, the CXGN_DEBUG environment variable
  or if that is not present, the 'debug' setting in the (merged) vhost conf
  or if that is not present, off.

=head1 AUTHORS

Lukas Mueller and Robert Buels

=cut

use strict;

package CXGN::Debug;

use CXGN::VHost;

=head2 new()

 Usage:        $d = CXGN::Debug->new();
 Desc:         the constructor
 Args:         a hash with parameters, currently:
                debug
               calling CXGN::Debug->new( debug=>1) will
               override the VHost configuration
 Side Effects:
 Example:

=cut

sub new {
    my $class = shift;
    my %opts = @_;
    my $self = bless {}, $class;

    my $conf_debug = CXGN::VHost->new->get_conf("debug");

    my $initial_debug_setting =
              defined $opts{debug}     ? $opts{debug}
            : defined $ENV{CXGN_DEBUG} ? $ENV{CXGN_DEBUG}
            : defined $conf_debug      ? $conf_debug
            :                            0;

    $self->set_debug( $initial_debug_setting );

    return $self;
}

=head2 accessors get_debug(), set_debug()

 Usage:        $d->set_debug(1);
 Desc:         accessors for the debug property.
               a true value turns debugging on, i.e., debug
               messages will be printed to either STDERR or
               the Apache error log (if running in mod_perl).
 Property:
 Side Effects:
 Example:

=cut

sub get_debug {
  my $self = shift;
  return $self->{debug};
}

sub set_debug {
  my $self = shift;
  $self->{debug} = shift;
}

=head2 debug()  or  d()

 Usage:  $d->d("The value of foo is $foo\n");
 Desc:   A debug message. Note that you have to provide the
         newline.
 Ret:    nothing meaningful
 Args:   message to print
 Side Effects: prints message to STDERR.  if running under
               mod_perl, uses log()->debug() method to print
               the message to the log
 Example:
     $d->d('well here we are');

=cut

sub debug {

    my $self = shift;
    my $message = shift;

    if ($self->get_debug()) {

        $message .= "\n" unless $message =~ /\n$/;
        warn "$message";

        if ($ENV{MOD_PERL}) {
            require Apache2::RequestUtil
                or die "must have Apache2::RequestUtil installed to use CXGN::Debug under mod_perl";
            my $r= Apache2::Request->new();
            $r->log()->debug($message);
        }

    }
}

sub d {
    my $self = shift;
    $self->debug(@_);
}


###
1;#do not remove
###

