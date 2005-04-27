# $Id: Root.pm,v 1.4 2005-04-27 19:32:45 cmungall Exp $
#
#

=head1 NAME

  Bio::Chaos::Root     - root utility class for chaos objects

=head1 SYNOPSIS

  package Bio::Chaos::SomeClass;
  use base qw(Bio::Chaos::Root);
  1;

=cut

=head1 DESCRIPTION

Root class for chaos objects

this class inherits from L<Bio::Root::Root>, so you get all that juicy stuff too

=head2 INHERITANCE

=over

=item Bio::Root::Root

=back

=cut

package Bio::Chaos::Root;

use Exporter;
use Bio::Root::Root;
@ISA = qw(Bio::Root::Root Exporter); # TODO -- make independent

use strict;

# Constructor

=head2 load_module

 Title   : load_module
 Usage   :
 Function:
 Example : $self->load_module("Bio::Tools::Blah");
 Returns : 
 Args    :


=cut

sub load_module {

    my $self = shift;
    my $classname = shift;
    my $mod = $classname;
    $mod =~ s/::/\//g;

    if ($main::{"_<$mod.pm"}) {
    }
    else {
        require "$mod.pm";
        if ($@) {
            print $@;
        }
    }
}

sub verbose {
    my $self = shift;
    $self->{_verbose} = shift if @_;
    return $self->{_verbose};
}


sub freak {
    my $self = shift;
    my $msg = shift;
    my @stags = @_;
    foreach my $stag (@stags) {
	eval {
	    print STDERR $stag->sxpr;
	};
	if ($@) {
	    print STDERR "[$stag]\n";
	}
    }
    $self->throw($msg);
}

sub dd {
    my $self = shift;
    my $obj = shift;
    require "Data/Dumper.pm";
    return Dumper($obj);
}
*dump = \&dd;

1;
