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
use Carp;
use base qw(Exporter);
use vars qw($AUTOLOAD);

@EXPORT_OK = qw(set_location_from_component set_loc);
%EXPORT_TAGS = (all=> [@EXPORT_OK]);

use strict;

=head1 FUNCTIONS

=cut

#only relationship of part_of (may need to use more defined part_of, later)
sub set_location_from_component {
    my $node = shift;
    if ($node->isa('SOI::Visitor')) {
        $node = shift;
    }
    my @children = grep{$_->relationship_type eq 'part_of' || $_->relationship_type eq 'partof'}@{$node->nodes || []};
    my $q_sec;
    if (@children) {
        @children = sort{$a->fmin <=> $b->fmin}@children;
        $node->fmin($children[0]->fmin);
        $node->strand($children[0]->strand);
        $q_sec = $children[0]->secondary_loc;
        @children = sort{$a->fmax <=> $b->fmax}@children;
        $node->fmax($children[-1]->fmax);
        $node->src_seq($children[0]->src_seq);
    }
    if ($q_sec) {
        my $sec = ref($node)->new({src_seq=>$q_sec->src_seq,strand=>$q_sec->strand});
        my @secs = map{$_->secondary_loc}@{$_->nodes || []};
        @secs = sort{$a->fmin <=> $b->fmin}@secs;
        $sec->fmin($secs[0]->fmin);
        @secs = sort{$a->fmax <=> $b->fmax}@secs;
        $sec->fmax($secs[-1]->fmax);
        my $node_sec = $node->secondary_node;
        $node->add_secondary_node($sec) unless ($node_sec && $node_sec->src_seq eq $sec->src_seq && $node_sec->fmin == $sec->fmin);
    }
    return $node;
}
*set_loc = \&set_location_from_component;


1;
