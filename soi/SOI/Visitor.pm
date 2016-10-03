package SOI::Visitor;

=head1 NAME

SOI::Visitor

=head1 SYNOPSIS

provide rare functions of SOI::Feature, which might include validation methods
and set derived attribtues (more to come)

to keep SOI::Feature lightweight, all these functions should be imported and used in client (script)

=head1 FEEDBACK

Email sshu@fruitfly.org

=cut

use Exporter;

use SOI::Feature;
use SOI::IntersectGraph;
use Carp;
use base qw(Exporter);
use vars qw($AUTOLOAD);

@EXPORT_OK = qw(set_location_from_component set_loc);
%EXPORT_TAGS = (all=> [@EXPORT_OK]);

use strict;


#only relationship of part_of (may need to use more defined part_of, later)
sub set_location_from_component {
    my $node = shift;
    if ($node->isa('SOI::Visitor')) {
        $node = shift;
    }
    return $node if (defined($node->fmax) && defined($node->strand)); #already set
    map{&set_loc($_)}@{$node->nodes || []};
    my @children = grep{$_->relationship_type && ($_->relationship_type  eq 'part_of' || $_->relationship_type eq 'partof')}@{$node->nodes || []};
    return $node unless (@children);

    my $q_sec;
    @children = sort{$a->fmin <=> $b->fmin}@children;
    $node->fmin($children[0]->fmin);
    $node->strand($children[0]->strand);
    $q_sec = $children[0]->secondary_loc;
    @children = sort{$a->fmax <=> $b->fmax}@children;
    $node->fmax($children[-1]->fmax);
    $node->src_seq($children[0]->src_seq);

    if ($q_sec) {
        my $sec = ref($node)->new({src_seq=>$q_sec->src_seq,strand=>$q_sec->strand});
        my @secs = map{$_->secondary_node}@{$node->nodes || []};
        @secs = sort{$a->fmin <=> $b->fmin}@secs;
        $sec->fmin($secs[0]->fmin);
        $sec->strand($secs[0]->strand);
        @secs = sort{$a->fmax <=> $b->fmax}@secs;
        $sec->fmax($secs[-1]->fmax);
        my $node_sec = $node->secondary_node;
        $sec->_setup_coord;
        $node->add_secondary_node($sec) unless ($node_sec && $node_sec->src_seq eq $sec->src_seq && $node_sec->fmin == $sec->fmin);
    }
    return $node;
}
*set_loc = \&set_location_from_component;

sub delete_property {
    my $node = shift;
    if ($node->isa('SOI::Visitor')) {
        $node = shift;
    }
    my $key = shift || return;

    my $props = $node->properties;
    my @remains = grep{$_->{type} ne $key}@{$props || []};
    $node->properties(\@remains);
}

#must be mini-view feature
sub remove_strand {
    my $node = shift;
    if ($node->isa('SOI::Visitor')) {
        $node = shift;
    }
    my $gone = shift || confess("must pass in strand that is to be removed");
    my ($contig,@features);
    map{if ($_->type eq 'contig') {$contig = $_} else {push @features, $_}}@{$node->nodes || []};
    my (@ans,@fs);
    map{if ($_->type eq 'companalysis') {push @ans, $_} else {push @fs, $_}}@features;
    my (@keep_ans, @keep_fs);
    foreach my $an (@ans) {
        my @rsets;
        map{
            SOI::Visitor->set_loc($_);
            push @rsets, $_ if ($_->strand != $gone);
        }@{$an->nodes || []};
        if (@rsets) {
            $an->nodes([@rsets]);
            push @keep_ans, $an;
        }
    }
    @keep_fs = grep{$_->strand != $gone}@fs;
    $node->nodes([$contig,@keep_ans,@keep_fs]);
    return $node;
}

sub make_CDS_feature {
    my $mRNA = shift;

    if ($mRNA->isa('SOI::Visitor')) {
        $mRNA = shift;
    }

    my ($protein) = grep{$_->type eq 'protein' or $_->type eq 'poly_peptide'}@{$mRNA->nodes || []};
    my @exons = sort{$a->fmin <=> $b->fmin}grep{$_->type eq 'exon'}@{$mRNA->nodes || []};
    my $ig = SOI::IntersectGraph->new;

    my ($startc_fmin, $stopc_fmin) = ($protein->fmin, $protein->fmax);
    if ($protein->strand < 0) {
        ($startc_fmin, $stopc_fmin) = ($protein->fmax-3, $protein->fmin-3);
    }
    my $start_codon = SOI::Feature->new({name=>$mRNA->name."_start_codon",type=>'codon',src_seq=>$mRNA->src,fmin=>$startc_fmin,fmax=>$startc_fmin+3, strand=>$protein->strand});
    $ig->find_intersects([@exons],[$start_codon], {query_type=>'exon',subject_type=>'codon',same_strand=>1});
    my $cds1exon = $ig->query_overlaps->[0];
    my $cds_b = $start_codon->fmin  - $cds1exon->fmin;
    if ($start_codon->strand < 0) {
        $cds_b = $cds1exon->fmax - $start_codon->fmax;
    }
    map{$cds_b += $_->length}@{&front_of($cds1exon, [@exons]) || []};

    my $stop_codon = SOI::Feature->new({name=>$mRNA->name."_start_codon",type=>'codon',src=>$mRNA->src,fmin=>$stopc_fmin,fmax=>$stopc_fmin+3, strand=>$protein->strand});
    $ig->find_intersects([@exons],[$stop_codon], {query_type=>'exon',subject_type=>'codon',same_strand=>1});
    my $cdslastexon = $ig->query_overlaps->[0];
    my $cds_e = $mRNA->seqlen - ($cdslastexon->fmax - $stop_codon->fmax);
    if ($stop_codon->strand < 0) {
        $cds_e = $mRNA->seqlen - ($stop_codon->fmin - $cdslastexon->fmin);
    }
    map{$cds_e -= $_->length}@{&behind_of($cdslastexon, [@exons]) || []};
    printf STDERR "mRNA len: %d cds: $cds_b-$cds_e\n", $mRNA->seqlen if ($ENV{DEBUG});
    my $res = substr($mRNA->residues, $cds_b, $cds_e - $cds_b);
    return SOI::Feature->new
      ({type=>'CDS',name=>$mRNA->name."_CDS",
        src_seq=>$protein->src,
        fmin=>$startc_fmin,fmax=>$stopc_fmin+3,strand=>$protein->strand,
        residues=>$res,
        seqlen=>length($res)}
      );
}

sub front_of {
    my $it = shift;
    if ($it->strand > 0) {
        return &_smaller_than($it, @_);
    } else {
        return &_bigger_than($it, @_);
    }
}
sub _smaller_than {
    my $it = shift;
    my $all = shift;
    return [grep{$_->fmax < $it->fmin && $_->type eq $it->type}@{$all || []}];
}
sub behind_of {
    my $it = shift;
    if ($it->strand > 0) {
        return &_bigger_than($it, @_);
    } else {
        return &_smaller_than($it, @_);
    }
}
sub _bigger_than {
    my $it = shift;
    my $all = shift;
    return [grep{$_->fmin > $it->fmax && $_->type eq $it->type}@{$all || []}];
}


1;
