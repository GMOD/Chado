package SOI::GFF3Parser;

=head1 NAME

SOI::GFF3Parser

=head1 SYNOPSIS

perlSAX handler to parse soi xml

=head1 USAGE

=begin

my $parser = SOI::GFF3Parser->new([qw(property_type_map2method)]);
$parser->parse($yourGFF3File);
my $feature = $parser->feature; #get SOI::Feature obj (feature tree) from soi xml

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

    my $file = shift;
    $self->file($file);
    my $types = shift;
    if ($types) {
        $types = [$types] unless (ref($types) eq 'ARRAY');
        $self->{method_types} = $types;
    }
    return $self;
}
sub method_types {
    my $self = shift;
    if (@_) {
        my $types = shift;
        $types = [$types] unless (ref($types) eq 'ARRAY');
        $self->{method_types} = $types;
    }
    return $self->{method_types};
}
sub file {
    my $self = shift;
    my $file = shift;
    if ($file) {
        my $fh = FileHandle->new("<$file") || confess("Failed to open file $file: $!");
        $self->fh($fh);
        $self->{file} = $file;
        undef $self->{top_features};
        undef $self->{feature_h};
    }
    return $self->{file};
}
sub fh {
    my $self = shift;
    $self->{fh} = shift if (@_);
    return $self->{fh};
}
sub parse {
    my $self = shift;
    my $f = shift;
    $self->file($f) if ($f);

    my $tops = $self->fetch_object(); #no object id, return top objects
    map{$_->set_depth(0)}@{$tops || []};
#    return $tops;
}
#hard to implement get_next_object?
sub fetch_object {
    my $self = shift;
    my $oid = shift;
    my $fh = $self->fh;
    return $self->_parse($fh, $oid);
}
sub _last_meta {
    my $self = shift;
    $self->{last_meta} = shift if (@_);
    return $self->{last_meta} || "";
}
sub _parse {
    my $self = shift;
    my $fh = shift;
    my $oid = shift;

    #my (%seq_h, %feat_h, @tops);
    my @predefined = qw(ID Name Alias Parent Target Gap Note Dbxref Ontology_term);
    while (my $line = <$fh>) {
        chomp $line;
        next unless ($line);
        if ($line =~ /^\#\#/) {
            my $last_meta = $self->_last_meta || "";
            $self->_last_meta($line);
            if ($line =~ /^\#{3}$/) {
                if ($last_meta =~ /^\#\#FASTA/) {
                    #end of fasta seq
                }
                elsif ($oid) {
                    last; #end of feature for the oid requested (### better be at right level)
                }
            }
            #rest meta NOT IMPLEMENTED

            next;
        }
        if ($self->_last_meta =~ /^\#\#FASTA/) {
            #get residue
            next;
        }
        #only able to handle tab-delimited file for now
        my @a = split/\t/, $line;
        map{undef $_ if ($_ eq '.')}@a;
        my $col9 = pop @a;
        my ($src_seq,$source,$type,$start,$end,$score,$strand,$phase) = @a;
        my (%magic_h, @props);
        map {
            my ($tag, $val) = split/\=/, $_;
            if (grep{$tag eq $_}@predefined) {
                my @v = (split/[,+]/, $val);
                $magic_h{$tag} = \@v;
            } else {
                push @props, {type=>$tag,value=>$val};
            }
        }(split/\;\s*/, $col9);
        my ($id) = @{$magic_h{ID} || []};
        confess("A feature must have ID and type") unless ($id && $type);
        my ($name) = @{$magic_h{Name} || []};
        my $parent = $magic_h{Parent};
        my $target = $magic_h{Target};
        my ($gap) = @{$magic_h{Ga} || []};
        push @props, {type=>'cigar',values=>$gap} if ($gap);
        my ($note) = @{$magic_h{Note} || []};
        push @props, {type=>'note', value=>$note} if ($note);

        my $feature = SOI::Feature->new({uniquename=>$id,name=>$name,type=>$type});
        confess("Feature ID: $id is duplicated") if (exists $self->{feature_h}->{$id});
        $self->{feature_h}->{$id} = $feature;
        if ($parent) {
            map {
                my $p = $self->{feature_h}->{$_};
                #parent must appear first!!!
                $p->add_node($feature);
            }@{$parent || []};
        } else {
            push @{$self->{top_features}}, $feature;
        }
        if ($start && $end) {
            confess("Locatable feature must have src and coord including strand: $line") unless ($src_seq && $strand);
            my ($fmin, $fmax) = ($start - 1, $end);
            $feature->src_seq($src_seq);
            $feature->fmin($fmin);
            $feature->fmax($fmax);
            $feature->strand($strand);
        }
        if ($target) {
            my $sstrand = $target->[3] || 1;
            $feature->add_secondary_node(SOI::Feature->new({src_seq=>$target->[0], fmin=>$target->[1]-1, fmax=>$target->[2], strand=>$sstrand}));
        }
        &_set_synonyms($feature, $magic_h{Alias});
        &_set_dbxrefs($feature, $magic_h{Dbxref});
        &_set_ontology_terms($feature, $magic_h{Ontology_term});
        $self->setup_properties($feature, \@props);
    }
    if ($oid) {
        return $self->{feature_h}->{$oid};
    }
    return $self->{top_features};
}
sub _set_synonyms {
    my $feature = shift;
    my $syns = shift || return;
    ##??
}
sub _set_dbxrefs {
    my $feature = shift;
    my $dbxrefs = shift || return;
    my @a;
    map{my ($db, $acc) = (split/\:/);push @a, {dbname=>$db,accession=>$acc}}@$dbxrefs;
    $feature->dbxrefs(\@a);
}
sub _set_ontology_terms {
    my $feature = shift;
    my $terms = shift || return;
    my @a;
    map{my ($db, $acc) = (split/\:/);push @a, {dbname=>$db,accession=>$acc}}@$terms;
    $feature->ontologies(\@a);
}
sub setup_properties {
    my $self = shift;
    my $feature = shift;
    my $props = shift;
    my (@a, @m);
    foreach my $p (@{$props || []}) {
        if (grep{$p->{type} eq $_}@{$self->{method_types} || []}) {
            push @m, $p;
        } else {
            push @a, $p;
        }
    }
    $feature->properties(\@a) if (@a);
    foreach my $m (@m) {
        $feature->hash->{$m->{type}} = $m->{value};
    }
}


=head2 feature

 usage:  my $feature = $self->feature;

 returns: top node feature

=cut

sub feature {
    my $self = shift;
    return unless (@{$self->{top_features} || []});
    return $self->{top_features}->[0];
}
sub features {
    my $self = shift;
    return $self->{top_features};
}

1;
