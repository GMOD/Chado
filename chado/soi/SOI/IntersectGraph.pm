package SOI::IntersectGraph;

=head1 NAME

  SOI::IntersectGraph

=head1 DESCRIPTION

stores/finds the intersection graph between two sets of features.

the algorithm (smaller/bigger (which is a Set) implies the number of elements):

foreach I in smaller(Set1, Set2):

   foreach J in Set(J.range ov w I.range in bigger(Set1, Set2)):

      if ov(I, J):

         add to ov list

it has O(N x k) instead of O(N^2).

set i: smaller set, set j: bigger set.

Both sets are sorted on fmin. J is from a set of item in set j and J index
is between smallest index of set j whose range ov with the previous item
of set i and that of set j whose range ov with current item of set i.

for this to work efficiently, location intersection comparing node parent
must have fmin and fmax and src_seq. because chado [early FlyBase version]
did not have resultset located, you may have to manufacture its location:
src_seq, fmin, and fmax from its spans/match_part (see Visitor module)

soi tree has undeterministic depth and mixed types at one level, to find intersections, feature type
must be specified (see property below). If no depth specified, top node (depth 0) is assumed.

furthermore, 2 sets depth has the same sematics(same level has similar types of features):
transcript vs transcript(resultset), NOT transcript vs exon(span/match_part), NOR translation vs exon
although this is no enforced. API user should be clear on what is compared to when passing in 2 sets
and options (hashref) as property (see below) to find intersection

=cut

=head2  property

=over

property can be set before call find_intersects or passed in as hashref (3rd arg) when call find_intersects

=item query_type

(required) feature type at the depth specified of query side (first arg in find_intersects)

=item subject_type

(required) feature type at the depth specified of subject side (2nd arg in find_intersects)

NOTE: theoretically, mixed types at the same depth could work by passing in array ref of types

=item depth

feature depth for intersecting determination, without specifying depth, it will zigzag
to go to right level (controlled by query_type, subject_type) to do comparison.

=item query_depth, subject_depth

feature depth for comparison can be different, but comparing feature at the same depth
is much faster as it does not need to zigzag instead of diving into both graphs at the same time

=item overlap

min percentage overlaping (span length) to be intersecting

=item overlap_length

min overlap length to be intersecting per span

=item attach_ov_coords

add ov_fmin, ov_fmax as feature properties to subject feature

=item same_strand

on the same strand to be intersecting

=item threshold

min percentage overlaping (seq length) to be intersecting

=item lt_threshold

max percentage overlapping (seq length) to be intersecting, this is for getting
set of not threshold

WARNING: when specify threshold or lt_threshold, both sets of features have to be flatten
ones like transcript or resultset (match). In other words, children of feature must be
component_part_of, eg for gene, it may over-count overlaps since a gene may have >1
overlapping transcripts.

=item query_compare

default to primary location, only valid option is secondary_location

=item subject_compare

default to primary location, only valid option is secondary_location

=back

=head1 CREDITS

Interface is similar to Gadfly IntersectionGraph.pm (Chris Mungall), but implementation is different

=cut

=head1 FEEDBACK

Email sshu@fruitfly.org

=cut

use strict;
use Carp;
use Exporter;
use SOI::Feature;
use base qw(Exporter);
#use vars qw($AUTOLOAD);

=head1 FUNCTIONS

=cut

sub new {
    my $proto = shift; my $class = ref($proto) || $proto;;
    my $self = {};
    bless $self, $class;

    $self->_initialize;
    return $self;
}

# automatically called by new()
sub _initialize {
    my $self = shift;
    $self->{arcs} = [];
    $self->{lookup} = {};
    $self->{properties} = {};
}

=head2 properties

  Usage   -
  Returns - hashref
  Args    - hashref

=cut

sub properties {
    my $self = shift;
    $self->{_properties} = shift if @_;
    return $self->{_properties};
}

sub property_key_list {
    qw(boundary check depth query_depth subject_depth query_type subject_type both_type query_compare subject_compare
       overlap overlap_length attach_ov_coords has_overlaps same_strand
       profile n_comparisons threshold lt_threshold);
}

sub allowed_property {
    my $self = shift;
    my $p = shift;
    return 1 if grep {$p eq $_} $self->property_key_list;
}

=head2 set_property

  Usage   - $sf->set_property("wibble", "on");
  Returns -
  Args    - property key, property scalar

=cut

sub set_property {
    my $self = shift;
    my $p = shift;
    my $v = shift;
    if (!$self->allowed_property($p)) {
        confess("$p not a valid property");
    }
    if (!$self->properties) {
        $self->properties({});
    }
    $self->properties->{$p} = $v;
    $v;
}

=head2 get_property

  Usage   -
  Returns -
  Args    -

=cut

sub get_property {
    my $self = shift;
    my $p = shift;
    if (!$self->allowed_property($p)) {
        confess("$p not a valid property");
    }
    if (!$self->properties) {
        $self->properties({});
    }
    $self->properties->{$p};
}


=head2 has_intersects

  Usage   -
  Returns - boolean
  Args    - SOI::Feature listref, SOI::Feature listref


=cut

sub has_intersects {
    my $self = shift;
    $self->set_property("check", 1);
    $self->set_property("has_overlaps", 0);
    $self->find_intersects(@_);
    $self->set_property("check", 0);
    return $self->get_property("has_overlaps");
}
*has_intersections =\&has_intersects;

sub _qsec2sf_h {
    my $self = shift;
    my $sec = shift || confess('must pass in secondary loc');
    if (@_) {
        my $sf = shift;
        $self->{_qsec2sf_h}->{$sec} = $sf;
    }
    return $self->{_qsec2sf_h}->{$sec};
}
sub _ssec2sf_h {
    my $self = shift;
    my $sec = shift || confess('must pass in secondary loc');
    if (@_) {
        my $sf = shift;
        $self->{_ssec2sf_h}->{$sec} = $sf;
    }
    return $self->{_ssec2sf_h}->{$sec};
}

=head2 find_intersects

  Usage   -
  Returns -
  Args    - arrayref of features, arrayref of features, option (hashref)

=cut

sub find_intersects {
    my $self = shift;
    my $sfs1 = shift;
    my $sfs2 = shift;
    my $opts = shift;

    my %old = ();
    if ($opts) {
        my $p = $self->properties || {};
        %old = %$p;
        $self->properties({});
        map {
            if ($_ eq 'both_type') {
                $self->set_property('query_type', $opts->{$_});
                $self->set_property('subject_type', $opts->{$_});
            } else {
                $self->set_property($_, $opts->{$_});
            }
        } keys %$opts;
    }
    unless ($self->get_property('query_type') && $self->get_property('subject_type')) {
        confess("must pass in query_type and subject_type in options hash");
    }
    my %sfh1 = ();
    my %sfh2 = ();

    foreach (@$sfs1) {
        my $c = $_;
        if ($self->get_property('query_compare')|| "" eq 'secondary_location') {
            $c = $_->secondary_loc;
            $self->_qsec2sf_h($c, $_);
        }
        next unless ($c->src_seq);
        $sfh1{$c->src_seq} = [] unless $sfh1{$c->src_seq};
        push(@{$sfh1{$c->src_seq}}, $c);
    }
    foreach (@$sfs2) {
        my $c = $_;
        if ($self->get_property('subject_compare')|| "" eq 'secondary_location') {
            $c = $_->secondary_loc;
            $self->_ssec2sf_h($c, $_);
        }
        next unless ($c->src_seq);
        $sfh2{$c->src_seq} = [] unless $sfh2{$c->src_seq};
        push(@{$sfh2{$c->src_seq}}, $c);
    }

    $self->clear_overlaps;

    my $rv;
    # remember, there will be no intersections if
    # they dont share same seq!
    foreach my $k (keys %sfh1) {
        if ($sfh2{$k}) {
            $rv = $self->find_intersects_on_same_seq($sfh1{$k}, $sfh2{$k})
        }
    }
    # unset temp properties
    if ($opts) {
        map {$self->set_property($_, $old{$_})} keys %$opts;
    }
    $self->overlap_list;
}


sub find_intersects_on_same_seq {
    my $self = shift;
    my $sfs1 = shift;
    my $sfs2 = shift;

    return [] unless (@{$sfs1 || []} && @{$sfs2 || []});

    #use the flag to indicate I (smaller set) is first set of the args or not
    my $sets_order_flipped = 0;
    my ($small, $big) = ($sfs1, $sfs2);
    if (@{$sfs1} > @{$sfs2}) {
        ($small, $big) = ($sfs2, $sfs1);
        $sets_order_flipped = 1;
    }
    $small = [sort{$a->fmin <=> $b->fmin}@$small];
    $big = [sort{$a->fmin <=> $b->fmin}@$big];

    my @ovs = ();

    my $nc = 0;

    my $k = 0;
    for (my $i = 0; $i < scalar(@{$small}); $i++) {
        my $sf1 = $small->[$i];
        #trace(sprintf("\nexamined one round: %s:%d-%d",$sf1->type." ".($sf1->secondary_loc?$sf1->secondary_loc->src_seq:$sf1->name),$sf1->fmin,$sf1->fmax));
        my $pointer_moved;
        for (my $j = $k; $j < scalar(@{$big}); $j++) {
            my $sf2 = $big->[$j];
            if ($sf2->fmax < $sf1->fmin) {
                #sf2 left of sf1: sf2 moves right
                next;
            }
            elsif ($sf1->fmin <= $sf2->fmax && $sf1->fmax >= $sf2->fmin) {
                unless ($pointer_moved) {
                    $k = $j;
                    $pointer_moved = 1;
                }
            } else {
                #sf2 right of sf1: no possible ov
                last;
            }

            #keep $sf1 straight by using alias because we have to swap sf in some cases!
            my ($c1, $c2) = ($sf1, $sf2);
            if ($sets_order_flipped) {
                ($c1, $c2) = ($sf2, $sf1);
            }
            if ($self->get_property('query_compare')|| "" eq 'secondary_location') {
                $c1 = $self->_qsec2sf_h($c1);
            }
            if ($self->get_property('subject_compare')|| "" eq 'secondary_location') {
                $c2 = $self->_ssec2sf_h($c2);
            }
            my $is_overlap = $self->_icheck($c1, $c2);
            $nc++;
            if ($is_overlap) {
                if ($self->get_property("check")) {
                    # user doesn't care about list of
                    # overlaps, use ig to find if overlap (has_overlaps)?
                    $self->set_property("has_overlaps", 1);
                    return;
                }
                trace(sprintf("%s:%d-%d %s ov %s:%d-%d %s",$sf1->src_seq,$sf1->fmin,$sf1->fmax,$c1->name || "", $sf2->src_seq,$sf2->fmin,$sf2->fmax, $c2->name || ""));
                push(@ovs, [$c1, $c2, $is_overlap]);
            } else {
                trace(sprintf("%s:%d-%d %s(d=%d) not ov %s:%d-%d %s(d=%d)",$sf1->src_seq,$sf1->fmin,$sf1->fmax,$c1->type,$c1->depth,$sf2->src_seq,$sf2->fmin,$sf2->fmax, $c2->type, $c2->depth));
            }
        }
    }

    if ($self->get_property("profile")) {
        $self->set_property("n_comparisons", $nc);
    }
    foreach my $ov (@ovs) {
        $self->add_overlap($ov);
    }
    printf STDERR "EXAMINED ALL\n" if ($ENV{DEBUG});
    trace('n overlaps = ', scalar(@ovs));
    $self->overlap_list;
}



sub _icheck {
    my $self = shift;
    my $sf1 = shift; #must be from set of user's first arg
    my $sf2 = shift;

    local *sf_ov = sub {
        my $f1 = shift;
        my $f2 = shift;
        my $ov_lap = $self->overlaps($f1, $f2);
        my $is_overlap = $ov_lap->[0];
        my $overlap = $self->get_property('overlap');#span overlap percentage
        my $ov_len = $self->get_property('overlap_length');
        if ($overlap) {
            if ($is_overlap/($f2->length || 1) < $overlap) {
                $is_overlap = 0;
            }
        }
        elsif ($ov_len) {
            if ($is_overlap < $ov_len) {
                $is_overlap = 0;
            }
        }
        if ($is_overlap && $self->get_property('attach_ov_coords')) {
            my $ov_fmin_term = $self->get_property('subject_compare') eq 'secondary_location' ?
              'ov_sec_loc_fmin' : 'ov_fmin';
            my $ov_fmax_term = $self->get_property('subject_compare') eq 'secondary_location' ?
              'ov_sec_loc_fmax' : 'ov_fmax';
            $f2->add_property($ov_fmin_term, $ov_lap->[1]);
            $f2->add_property($ov_fmax_term, $ov_lap->[2]);
        }
        return $is_overlap;
    };

    local *further_down = sub {
        my $leaf1 = shift;
        my $leaf2 = shift;
        my $f2 = shift; #parent of $leaf2

        return unless (scalar(@{$leaf1 || []}) && scalar(@{$leaf2 || []}));
        # do a recursive check on next level nodes
        my $inner_ov = ref($self)->new;
        $inner_ov->properties({%{$self->properties}});
        my $inovs =
          $inner_ov->find_intersects_on_same_seq($leaf1,
                                                 $leaf2);
        # this assumes that both sf sets are flattened
        # eg it will work for transcripts (result set or match), but not genes
        #well, for genes, you may over-count overlaps as a gene may have >1 overlapping tr
        my $is_overlap = 0; #both flag and ov length (ov length is added up for next level node of $sf1, $sf2)
        foreach my $inov (@{$inovs || []}) {
            #arc (third item) is ov length
            $is_overlap += $inov->[2];
        }
        my $thresh = $self->get_property("threshold");
        my $ltthresh = $self->get_property("lt_threshold");
        if ($thresh || $ltthresh) {
            my $seq_len = 0;
            my $types = $self->get_property('subject_type');
            $types = [$types] unless (ref($types) eq 'ARRAY');
            my @parts;
            map{my $p = $_; push @parts, $p if (grep{$p->type eq $_}@$types)}@{$leaf2};
            map{$seq_len += $_->length}@parts;

            if ($ltthresh && $is_overlap / $seq_len >= $ltthresh) {
                print STDERR "NOT GETTING >= $ltthresh\n";
                $is_overlap = 0; #filter out
            } else {
                if ($is_overlap / $seq_len < $thresh) {
                    $is_overlap = 0;
                }
            }
        }
        return $is_overlap;
    };

    #both sf are on the same src
    my $strand_test_passed = 1;
    if ($self->get_property("same_strand")) {
        $strand_test_passed = 0 unless ($sf1->strand == $sf2->strand);
    }
    if ($sf1->uniquename eq $sf2->uniquename || ($strand_test_passed)) {
        my $overlap;
        my $depth = $self->get_property('depth');
        my ($qd, $sd) = ($self->get_property('query_depth'),$self->get_property('subject_depth'));
        #same depth of said types (a type can appear at diff level of the tree)
        if (defined($depth)) {
            if ($sf1->depth == $depth && $sf2->depth == $depth) {
                $overlap = sf_ov($sf1,$sf2);
            }
            else {
                # do a recursive check on next level nodes
                my $leaf1 = $sf1->nodes;
                my $leaf2 = $sf2->nodes;
                $overlap = further_down($leaf1,$leaf2,$sf2);
            }
        }
        #said depth of said types
        elsif (defined($qd) || defined($sd)) {
            confess("must specify both query and subject depth when a depth is specified")
              unless (defined($qd) && defined($sd));
            if ($sf1->depth == $qd && $sf2->depth == $sd) {
                $overlap = sf_ov($sf1,$sf2);
            }
            elsif ($sf1->depth == $qd) {
                my $leaf2 = $sf2->nodes;
                $overlap = further_down([$sf1],$leaf2,$sf2);
            }
            elsif ($sf2->depth == $sd) {
                my $leaf1 = $sf1->nodes;
                $overlap = further_down($leaf1,[$sf2],$sf2);
            }
            else {
                # do a recursive check on next level nodes
                my $leaf1 = $sf1->nodes;
                my $leaf2 = $sf2->nodes;
                $overlap = further_down($leaf1,$leaf2,$sf2);
            }
        }
        #any depth of said types, the type must be unique in the tree
        #in other words, the type SHOUD NOT be at diff depth or you WILL get wrong answer
        else {
            my ($qtype, $stype) = ($self->get_property('query_type'),$self->get_property('subject_type'));
            $qtype = [$qtype] unless (ref($qtype) eq 'ARRAY');
            $stype = [$stype] unless (ref($stype) eq 'ARRAY');
            if (grep{$sf1->type eq $_}@$qtype and grep{$sf2->type eq $_}@$stype) {
                $overlap = sf_ov($sf1,$sf2);
            }
            elsif (grep{$sf1->type eq $_}@$qtype) {
                my $leaf2 = $sf2->nodes;
                $overlap = further_down([$sf1],$leaf2,$sf2);
            }
            elsif (grep{$sf2->type eq $_}@$stype) {
                my $leaf1 = $sf1->nodes;
                $overlap = further_down($leaf1,[$sf2],$sf2);
            }
            else {
                my $leaf1 = $sf1->nodes;
                my $leaf2 = $sf2->nodes;
                $overlap = further_down($leaf1,$leaf2,$sf2);
            }
        }
        return $overlap;
    }
}

#prerequisite: first arg is from query/user's first arg
#return array ref: ov length, ov_fmin, ov_fmax
sub overlaps {
    my $self = shift;
    my $sf1 = shift;
    my $sf2 = shift;

    my ($qtype, $stype) = ($self->get_property('query_type'),$self->get_property('subject_type'));
    $qtype = [$qtype] unless (ref($qtype) eq 'ARRAY');
    $stype = [$stype] unless (ref($stype) eq 'ARRAY');
    return unless (grep{$sf1->type eq $_}@$qtype and grep{$sf2->type eq $_}@$stype); #not right feature type

    if ($self->get_property('query_compare')|| "" eq 'secondary_location') {
        $sf1 = $sf1->secondary_loc;
    }
    if ($self->get_property('subject_compare')|| "" eq 'secondary_location') {
        $sf2 = $sf2->secondary_loc;
    }
    my ($ov, $fmin, $fmax);
    if ($sf1->fmin > $sf2->fmin) {
        ($sf2, $sf1) = ($sf1, $sf2);
    }
    elsif ($sf2->length > $sf1->length && $sf1->fmin == $sf2->fmin) {
        ($sf2, $sf1) = ($sf1, $sf2);
    }
    #$sf1 is smaller fmin (and longer if same fmin)
    if ($sf1->fmin <= $sf2->fmin && $sf1->fmax >= $sf2->fmax) {
        if ($sf1->length > $sf2->length) {
            ($fmin, $fmax) = ($sf2->fmin, $sf2->fmax);
        } else {
            ($fmin, $fmax) = ($sf1->fmin, $sf1->fmax);
        }
    }
    elsif ($sf1->fmax > $sf2->fmin && $sf1->fmax <= $sf2->fmax) {
        ($fmin, $fmax) = ($sf2->fmin, $sf1->fmax);
    }
    else {
        ;
    }
    if (defined($fmin) && defined($fmax)) {
        return [$fmax-$fmin, $fmin, $fmax];
    } else {
        return [0,0,0]
    }
}

# an arc is stored as an arrayref
# [0] - feature1
# [1] - feature2
# [2] - distance (optional)
sub add_overlap {
    my $self = shift; my $ov = shift;
    $ov->[0]->isa("SOI::Feature") || confess;
    $ov->[1]->isa("SOI::Feature") || confess;
    push(@{$self->{arcs}}, $ov);
    my $lookup = $self->{lookup};
    $lookup->{$ov->[0]->uniquename} = [] unless  $lookup->{$ov->[0]->uniquename};
    $lookup->{$ov->[1]->uniquename} = [] unless  $lookup->{$ov->[1]->uniquename};
    push(@{$lookup->{$ov->[0]->uniquename}}, $ov);
    push(@{$lookup->{$ov->[1]->uniquename}}, $ov);# unless ($ov->[0]->uniquename eq $ov->[1]->uniquename);
    1;
}


=head2 overlap_list

  Usage   -
  Returns -
  Args    -

=cut

sub overlap_list {
    my $self = shift;
    if (@_) {
        $self->clear_overlaps;
        map {$self->add_overlap($_) } @{shift || []}
    }
    $self->{arcs};
}

=head2 query_overlaps

  Usage   -
  Returns -
  Args    -

returns list of SOI::Feature objects which came from the
first set (query features) which overlap with some of 2nd set

=cut

sub query_overlaps {
    my $self = shift;
    my $p = shift;
    my $arcs = $self->overlap_list;
    my %u_h;
	map {my $o = $_->[0]; $u_h{$o} = $o } @$arcs;
	return [values %u_h];
}

=head2 subject_overlaps

  Usage   -
  Returns -
  Args    -

returns list of SOI::Feature objects which came from the
second set (subject features) which overlap with some of first set

=cut

sub subject_overlaps {
    my $self = shift;
    my $arcs = $self->overlap_list;
    my %u_h;
	map { my $o = $_->[1]; $u_h{$o} = $o } @$arcs;
	return [values %u_h];
}

=head2 overlap_count

  Usage   -
  Returns -
  Args    -

=cut

sub overlap_count {
    my $self = shift;
    scalar(@{$self->overlap_list});
}

=head2 clear_overlaps

  Usage   -
  Returns -
  Args    -

=cut

sub clear_overlaps {
    my $self = shift;
    $self->{lookup} = {};
    $self->{arcs} = [];
}


=head2 get_ilist

  Usage   -
  Returns -
  Args    - SOI::Feature

returns all intersecting Features

=cut

sub get_ilist {
    my $self = shift;
    my $sf = shift;
    my $ovs = $self->{lookup}->{$sf->uniquename} || [];
    my @ilist =
      map {
          $_->[0]->uniquename eq $sf->uniquename ? $_->[1] : $_->[0]
      } @$ovs;
    return \@ilist;
}


=head2 get_distlist

  Usage   -
  Returns -
  Args    - SOI::Feature

returns intersecting Features and their distance, as pairs

eg

  [sfA, distA],
  [sfB, distC],
  [sfC, distC],

=cut

sub get_distlist {
    my $self = shift;
    my $sf = shift;
    my $ovs = $self->{lookup}->{$sf->uniquename} || [];
    my @ilist =
      map {
          $_->[0]->uniquename eq $sf->uniquename ? [$_->[1], $_->[2]] : [$_->[0], $_->[2]]
      } @$ovs;
    return \@ilist;
}


our $debug;
sub debug {
    my $self = shift;
    $debug = shift;
}

sub trace {
    print STDERR join(" ", @_),"\n" if ($debug || $ENV{DEBUG});
}


1;
