package SOI::SOIHandler;

=head1 NAME

SOI::SOIHandler

=head1 SYNOPSIS

perlSAX handler to parse soi xml

=head1 USAGE

=begin

my $handler = SOI::SOIHandler->new([qw(your feature type list here)]);
my $parser = XML::Parser::PerlSAX->new(Handler=>$handler);
$parser->parse(Source => { SystemId =>$soixml_file});
my $feature = $handler->feature; #get SOI::Feature obj (feature tree) from soi xml

=end

=cut

=head1 FEEDBACK

Email sshu@fruitfly.org

=cut

use SOI::Feature;
use FileHandle;
use Carp;

=head1 FUNCTIONS

=cut

sub new {
    my $class = shift;
    my $self = {};

#    my $outfile = shift || ">-";
#    $self->{fh} = new FileHandle ">$outfile";
    bless $self, $class;
    #for now one arg (non-optional)
    my $types = shift || confess("must pass in feature types (arrayref)");
    $types = [$types] unless (ref($types) eq 'ARRAY');
    $self->{feature_types} = $types;
    return $self;
}

=head2 start_element

Called directly by SAX Parser.
Do NOT call this directly.

Adds element name string to stack.

=cut

sub start_element {
    my ($self, $element) = @_;

    my $name = $element->{Name};
    my $feature = $self->feature;
    my $method = "add_$name";
    if (grep{$name eq $_}@{$self->{feature_types} || []}) {
        my $feature = SOI::Feature->new({type=>$element->{Name}});
        $feature->depth(scalar(@{$self->{feature_stack} || []}));
        push @{$self->{feature_stack}}, $feature;
        push @{$self->{level_stack}}, "feature";
    }
#    elsif (grep{$name eq $_}qw(property dbxref ontology secondary_location)) {
    elsif ($feature && $feature->can($method)) {
        push @{$self->{level_stack}}, $name;
        $self->start_auxillary($element);
    }
    else {
        undef $self->{cur_e_char};
    }

    return 1;
}

=head2 end_element

Called directly by SAX Parser.
Do NOT call this directly.

Removes element name string from stack.

=cut


sub end_element {
    my ($self, $element) = @_;

    my $name = $element->{Name};
    my $feature = $self->feature;
    my $method = "add_$name";
    my $level = $self->{level_stack}->[-1];
    if (grep{$name eq $_}@{$self->{feature_types} || []}) {
        pop @{$self->{level_stack}};
        unless (@{$self->{feature_stack}} == 1) {
            my $subf = pop @{$self->{feature_stack}};
            my $curf = $self->feature;
            $curf->add_node($subf);
        }
    }
#    elsif (grep{$name eq $_}qw(property dbxref ontology secondary_location)) {
    elsif ($feature && $feature->can($method)) {
        pop @{$self->{level_stack}};
        my $el_name = "end_auxillary";
        $self->$el_name($element);
    }
    else {
        my $e_val = $self->{cur_e_char};
        if ($e_val) {
            $e_val =~ s/^\s*//g;
            $e_val =~ s/\s*$//g;
        }
        if ($level eq 'feature') {
            $feature->hash->{$name} = $e_val;
        }
        else {
            if ($level eq 'secondary_location') {
                $self->{hash}->{$name} = $e_val;
            } else {
                $self->{hash} = {type=>$name, value=>$e_val};
            }
        }
    }
    return 1;
}

sub start_auxillary {
    my ($self, $element) = @_;
    $self->{hash} = {};
}

sub end_auxillary {
    my ($self, $element) = @_;

    my $name = $element->{Name};
    $name =~ tr/A-Z/a-z/;
    my $feature = $self->feature;
    my $method = "add_$name";
    confess("unsupported auxillary: $name") unless ($feature->can($method));
    my $h = $self->{hash};
    if ($name eq 'secondary_location') {
        my $locf = SOI::Feature->new($h);
        $feature->add_secondary_node($locf);
    } else {
        $feature->$method($h);
    }
}

sub start_document {
    my $self = shift;
    undef $self->{feature_stack};
    undef $self->{level_stack};
}

=head2 end_element

Called directly by SAX Parser.
Do NOT call this directly.

The last method called by the
Sax Parser.  This returns the
data in $self->data.

=cut


sub end_document {
  my $self = shift;

#  if ($self->{fh}) {
#      $self->{fh}->close;
#  }
#  return $self->{data};
}

=head2 characters

Called directly by SAX Parser.
Do NOT call this directly.

Calls method with the name of the
current element with text as the 
first argument.

=cut

sub characters {
  my ($self, $characters) = @_;

  my $data = $characters->{Data};
  return $self->{cur_e_char} .= $data;
}


=head2 feature

 usage:  my $feature = $self->feature;

 returns: top node feature

=cut

sub feature {
    my $self = shift;
    return unless (@{$self->{feature_stack} || []});
    return $self->{feature_stack}->[-1];
}


1;
