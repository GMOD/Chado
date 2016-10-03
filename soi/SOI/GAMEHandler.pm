package SOI::GAMEHandler;

=head1 NAME

SOI::GAMEHandler

=head1 SYNOPSIS

perlSAX handler to parse GAME xml

(WARNING: very alpha software!)

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

use strict;
use SOI::Feature;
use FileHandle;
use Carp;

=head1 FUNCTIONS

=cut

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;

    #element tag becomes feature type, but overwritten by its type attr if any
    my $types = shift || [qw(game map_position seq annotation feature_set feature_span result_set result_span computational_analysis)];

    #alias: synonym and output is also property, aspect is ontology
    my $mv_types = shift || [qw(property output dbxref ontology aspect comment)];
    my $single2prop = shift || [qw(synonym)];
    $types = [$types] unless (ref($types) eq 'ARRAY');
    $mv_types = [$mv_types] unless (ref($mv_types) eq 'ARRAY');
    $single2prop = [$single2prop] unless (ref($single2prop) eq 'ARRAY');
    $self->{feature_types} = $types;
    $self->{multi_types} = $mv_types;
    $self->{single_types} = $single2prop;
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
    my $feature = $self->_curr_feature;
    my $attrs = $element->{Attributes};
    if (grep{$name eq $_}@{$self->{feature_types} || []}) {
        $feature = SOI::Feature->new({type=>$element->{Name}});
        map{
            my $m = $self->_field($_);
            $m = 'seqtype' if ($feature->type eq 'seq' && $_ eq 'type');
            $m = 'seqlen' if ($feature->type eq 'seq' && $_ eq 'length');
            $feature->$m($attrs->{$_});
        }keys %{$attrs || {}};

        $feature->depth(scalar(@{$self->{feature_stack} || []}));
        push @{$self->{feature_stack}}, $feature;
        push @{$self->{level_stack}}, "feature";
    }
    elsif (grep{$name eq $_}@{$self->{multi_types} || []}) {
        push @{$self->{level_stack}}, $name;
        $self->start_multi($element);
        map{
            $self->{hash}->{$_} = $attrs->{$_};
        }keys %{$attrs || {}}
    }
    elsif (grep{$name eq $_}@{$self->{single_types} || []}) {
        push @{$self->{level_stack}}, $name;
        $self->start_single($element);
    }
    elsif (grep{$name eq $_}qw(seq_relationship span)) {
        #special handling
        if ($name eq 'span') { #simply contain start/end

        } else {
            my $type = $attrs->{type};
            $feature = SOI::Feature->new();
            push @{$self->{feature_stack}}, $feature;
            push @{$self->{level_stack}}, "feature";
            $feature->src_seq($attrs->{seq});
            $feature->hash->{seq_relationship} = $type;
        }
    }
    elsif (grep{$name eq $_}qw(gene)) {

    }
    else {
        undef $self->{cur_e_char};
        if (keys %{$attrs || {}}) {
            my $level = $self->{level_stack}->[-1];
            if ($level eq 'feature') {
                my $f = $self->_curr_feature;
                map{
                    my $m = $self->_field($_);
                    $f->$m($attrs->{$_});
                }keys %{$attrs || {}}
            }
            elsif (grep{$level eq $_}@{$self->{multi_types} || []}) {
                map{
                    $self->{hash}->{$_} = $attrs->{$_};
                }keys %{$attrs || {}}
            }
        }
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
    my $feature = $self->_curr_feature;

    my $level = $self->{level_stack}->[-1];
    if (grep{$name eq $_}@{$self->{feature_types} || []}) {
        pop @{$self->{level_stack}};
        unless (@{$self->{feature_stack}} == 1) {
            my $child = pop @{$self->{feature_stack}};
            my $parent = $self->_curr_feature;
            if ($child->type eq 'seq') {
                $self->{seq_hash}->{$child->uniquename || $child->name} = $child;
            } else {
                $parent->add_node($child);
            }
        }
    }
    elsif (grep{$name eq $_}@{$self->{multi_types} || []}) {
        pop @{$self->{level_stack}};
        my $el_name = "end_multi";
        $self->$el_name($element);
    }
    elsif (grep{$name eq $_}@{$self->{single_types} || []}) {
        pop @{$self->{level_stack}};
        $self->end_single($element);
    }
    elsif (grep{$name eq $_}qw(seq_relationship span)) {
        #special handling
        if ($name eq 'span') { #simply contain start/end

        } else {
            pop @{$self->{level_stack}};
            $feature = pop @{$self->{feature_stack}};
            my $main_f = $self->_curr_feature;
            if ($feature->hash->{seq_relationship} eq 'subject') {
                $main_f->add_secondary_node($feature);
                delete $feature->hash->{seq_relationship};
            } else { #query
                #$feature->_setup_coord;
                map{
                    my $m = $_;
                    $main_f->$m($feature->$m)
                }keys %{$feature->hash};
                delete $main_f->hash->{seq_relationship};
            }
        }
    }
    elsif (grep{$name eq $_}qw(gene)) {

    }
    else {
        my $e_val = $self->{cur_e_char};
        if ($e_val) {
            $e_val =~ s/^\s*//g;
            $e_val =~ s/\s*$//g;
        }
        if ($level eq 'feature') {
            my $m = $self->_field($name);
            $feature->$m($e_val);
        }
        else {
            $self->{hash}->{$name} = $e_val;
        }
    }
    return 1;
}

#multi to auxillary: property dbxref ontology comment
sub start_multi {
    my ($self, $element) = @_;
    $self->{hash} = {};
}

sub end_multi {
    my ($self, $element) = @_;

    my $name = $element->{Name};
    $name =~ tr/A-Z/a-z/;
    my $feature = $self->_curr_feature;
    #alias tags!!!
    if ($name eq 'aspect') {
        $name = 'ontology';
    }
    elsif ($name eq 'output') {
        $name = 'property';
    }
    my $method = "add_$name";
    confess("unsupported auxillary: $name") unless ($feature->can($method));
    my $hs = $self->{hash};
    #turn array of hash into one hash
    my $h;
    map{
        my $k = $self->_field($_);
        $h->{$k}=$hs->{$_};
    }keys %{$hs || {}};
    $feature->$method($h);
}
#single to property (tag=type, val=val)
sub start_single {
    my ($self, $element) = @_;
    undef $self->{cur_e_char};
    #$self->{hash} = {};
}
sub end_single {
    my ($self, $element) = @_;
    my $name = $element->{Name};
    my $e_val = $self->{cur_e_char} || "";
    $e_val =~ s/^\s*//g;
    $e_val =~ s/\s*$//g;
    $self->_curr_feature->add_property({type=>$name, value=>$e_val});
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

 returns: top node feature/apollo mini view feature

=cut


sub feature {
    my $self = shift;
    return unless (@{$self->{feature_stack} || []});
    my $feature = $self->_curr_feature;
    $feature->type('chromosome_arm');
    delete $feature->hash->{version};
    my (@all, $contig);

    foreach my $sf (@{$feature->nodes || []}) {
        if ($sf->type eq 'tile') {
            $sf->type('contig');
            $contig = $sf;
        }
        elsif ($sf->type eq 'gene') {
            $sf->_rsetup_coord;
            #do we have translation/polypeptide?
            foreach my $tr (@{$sf->nodes || []}) {
                my $seq = $self->{seq_hash}->{$tr->produces_seq};
                delete $tr->hash->{produces_seq};
                if ($seq) {
                    my $res = $seq->residues;
                    $res =~ s/\n//g;
                    $res =~ s/\s+//g;
                    $tr->residues($res);
                    $tr->seqlen($seq->seqlen);
                    $tr->md5checksum($seq->md5checksum);
                }
                my @prots = grep{$_->type eq 'translate offset'}@{$tr->nodes || []}; #only one
                foreach my $p (@prots) {
                    my $seq = $self->{seq_hash}->{$p->produces_seq};
                    $p->uniquename($p->produces_seq);
                    $p->type('protein');
                    delete $p->hash->{produces_seq};
                    if ($seq) {
                        my $res = $seq->residues;
                        my $res = $seq->residues;
                        $res =~ s/\n//g;
                        $res =~ s/\s+//g;
                        $p->residues($res);
                        $p->seqlen($seq->seqlen);
                        $p->md5checksum($seq->md5checksum);
                    }
                    #$p->to_soi_xml;
                }
            }
            push @all, $sf;
            #$sf->to_soi_xml;
        }
        elsif ($sf->type eq 'computational_analysis') {
            $sf->_rsetup_coord;
            foreach my $rset (@{$sf->nodes || []}) {
                foreach my $span (@{$rset->nodes || []}) {
                    my $seq = $span->secondary_node?$self->{seq_hash}->{$span->secondary_node->src_seq}:"";
                    if ($seq) {
                        my $res = $seq->residues;
                        $res =~ s/\n//g;
                        $res =~ s/\s+//g;
                        $seq->residues($res);
                        $span->secondary_node->sseq($seq);
                    }
                }
            }
            push @all, $sf;
            #$sf->to_soi_xml;
        }
    }
    unless ($contig) {
        #fishing for contig (arm dump)
        my ($arm) = grep{$_->hash->{focus} eq 'true'}values %{$self->{seq_hash} || {}};
        if ($arm) {
            $contig = SOI::Feature->new({type=>'contig'});
            $contig->name($arm->name);
            $contig->src_seq($arm->name);
            $contig->seqlen($arm->seqlen);
            map{$contig->$_($arm->$_)}qw(length version md5checksum);
        }
    }
    my $seq = $self->{seq_hash}->{$contig->hash->{seq}};
    if ($seq) {
        my $res = $seq->residues;
        $res =~ s/\n//g;
        $res =~ s/\s+//g;
        $contig->residues($res);
        $contig->name($seq->name);
        $contig->length($seq->length);
    }
    $feature->name($contig->src_seq);
    delete $contig->hash->{seq};

    $feature->nodes([$contig, @all]);
    return $feature;
}

sub _curr_feature {
    my $self = shift;
    return unless (@{$self->{feature_stack} || []});
    return $self->{feature_stack}->[-1];
}

#field transform
sub _field {
    my ($self, $field) = @_;
    my %map_h =
      (id        => 'uniquename',
       arm       => 'src_seq',
       alignment => 'residue_info',
       xref_db   => 'dbname',
       db_xref_id => 'accession',
      );
    return $map_h{$field} || $field;
}

1;
