package SOI::IntersectGraph;

=head1 NAME

  SOI::IntersectGraph

=head1 DESCRIPTION

stores/finds the intersection graph between two sets of features.

the algorithm (smaller/bigger (which is a Set): num of elements):

foreach I in smaller(Set1, Set2):

   foreach J in Set(J.fmin between I.fmin and I.fmax in bigger(Set1, Set2)):

      if ov(I, J):

         add to ov list

for this to work efficiently, location intersection comparing node's parent
must have fmin and fmax and src_seq. because chado [early FlyBase version]
did not have resultset loc'ed, you may have to manufacture its location:
src_seq, fmin, and fmax from its spans/match_part (see Visitor module)

soi tree has undeterministic depth and mixed types at one level, to find intersections, feature type
must be specified (see property below). If no depth specified, top node (depth 0) is assumed.

furthermore, 2 sets depth has the same sematics(same level has similar types of features):
transcript vs transcript(resultset), NOT transcript vs exon(span/match_part), NOR translation vs exon
although this is no enforced. API user should be clear on what is compared to when pass in 2 sets
and options (hashref) as property (see below) to find intersection

=cut

=head2  property

=over

property can be set before call find_intersects or passed in as hashref (3rd arg) when call find_intersects

=item query_type

(required) feature type at the depth specified of query side (first arg in find_intersects)

=item subject_type

(required) feature type at the depth specified of subject side (2nd arg in find_intersects

=item depth

feature depth for intersecting determination, default to 0

=item overlap

min percentage overlaping (span length) to be intersecting

=item overlap_length

min overlap length to be intersecting

=item attach_ov_coords

add ov_fmin, ov_fmax as feature properties to subject feature

=item same_strand

on the same strand to be intersecting

=item threshold

min percentage overlaping (seq length) to be intersecting

=item lt_threshold

max percentage overlapping (seq length) to be intersecting

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
    qw(boundary check depth query_type subject_type query_compare subject_compare
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
        map {$self->set_property($_, $opts->{$_})} keys %$opts;
    }
    unless ($self->get_property('query_type') && $self->get_property('subject_type')) {
        confess("must pass in query_type and subject_type");
    }
    my %sfh1 = ();
    my %sfh2 = ();

    foreach (@$sfs1) {
        my $c = $_;
        if ($self->get_property('query_compare') eq 'secondary_location') {
            $c = $_->secondary_loc;
            $self->_qsec2sf_h($c, $_);
        }
        next unless ($c->src_seq);
        $sfh1{$c->src_seq} = [] unless $sfh1{$c->src_seq};
        push(@{$sfh1{$c->src_seq}}, $c);
    }
    foreach (@$sfs2) {
        my $c = $_;
        if ($self->get_property('subject_compare') eq 'secondary_location') {
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

    #since indexing bigger set, use the flag to indicate I (smaller set) is first set of the args or not
    my $sets_order_flipped = 0;
    my ($small, $big) = ($sfs1, $sfs2);
    if (@{$sfs1} > @{$sfs2}) {
        ($small, $big) = ($sfs2, $sfs1);
        $sets_order_flipped = 1;
    }
    # INDEX of low coords
    $small = [sort{$a->fmin <=> $b->fmin}@$small];
    $big = [sort{$a->fmin <=> $b->fmin}@$big];
    my %big_index_h; #key is fmin and value is big set index (lowest index of those same fmins)
    my %big_index_h2; #key is fmin and value is big set index (highest index of those same fmins)
    for (my $i = 0; $i < scalar(@$big); $i++) {
        my $f = $big->[$i];
        confess("feature must have fmin and fmax to find intersection") unless (defined($f->fmin) && defined($f->fmax));
        unless (exists $big_index_h{$f->fmin}) {
            $big_index_h{$f->fmin} = $i;
        }
        $big_index_h2{$f->fmin} = $i;
    }
    my @big_coords = ();
    map{push @big_coords, [$_->fmin, $_->fmax]}@$big; #@big_coords is sorted in fmin as well

    my @ovs = ();

    my $nc = 0;

    # declare subroutine as local,
    # as we don't want lexical closure
    # over the above variables
    local *icheck = sub {
        my $sf1 = shift; #must be from set of user's first arg
        my $sf2 = shift;
        my $strand_test_passed = 1;
        if ($self->get_property("same_strand")) {
            $strand_test_passed = 0 unless ($sf1->strand == $sf2->strand);
        }
        if ($sf1->uniquename eq $sf2->uniquename || ($strand_test_passed)) {
            my $is_overlap;
            my $depth = $self->get_property('depth') || 0;
            unless ($sf1->depth == $depth && $sf2->depth == $depth) {
                # do a recursive check on next level nodes
                my $inner_ov = ref($self)->new;
                $inner_ov->properties({%{$self->properties}});
                #get next level feature
                my $leaf1 = $sf1->nodes;
                my $leaf2 = $sf2->nodes;
                my $inovs =
                  $inner_ov->find_intersects_on_same_seq($leaf1,
                                                         $leaf2);
                # this assumes that both sf sets are flattened
                # eg it will work for transcripts, but not genes (may not the way you think)
                #well, for genes, you get ov of tr (tr depth = your depth) which may have introns
                $is_overlap = 0; #effectively add up ov only for secondary level to leaf (desired depth)
                foreach my $inov (@{$inovs || []}) {
                    #arc third item is ov length
                    $is_overlap += $inov->[2];
                }
                my $thresh = $self->get_property("threshold");
                my $ltthresh = $self->get_property("lt_threshold");
                #threshold only apply to compu results
                if ($thresh || $ltthresh) {
                    if (@{$sf2->secondary_locations || []}) {
                        #how to check mixed seq?
                        #what level are we checking? (composite type feature length is not really seq length!!)
                        #get homol seq length if we could
                        my $homol_seq_len = $sf2->secondary_locations->[0]->{fmax} - $sf2->secondary_location->[0]->{fmin};
                        if ($sf2->secondary_location->[0]->{seq}->{seqlen}) {
                            $homol_seq_len = $sf2->secondary_location->[0]->{seq}->{seqlen};
                        }
                        if ($ltthresh && $is_overlap / $homol_seq_len >= $ltthresh) {
                            print STDERR "NOT GETTING >= $ltthresh\n";
                            $is_overlap = 0; #filter out
                        } else {
                            if ($is_overlap / $sf2->length < $thresh) {
                                $is_overlap = 0;
                            }
                        }
                    }
                }
            } else {
                 my $ov_lap = $self->overlaps($sf1, $sf2);
                 $is_overlap = $ov_lap->[0];
                 my $overlap = $self->get_property('overlap');#span overlap percentage
                 my $ov_len = $self->get_property('overlap_length');
                 if ($overlap) {
                     if ($is_overlap/($sf2->length || 1) < $overlap) {
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
                     $sf2->add_property($ov_fmin_term, $ov_lap->[1]);
                     $sf2->add_property($ov_fmax_term, $ov_lap->[2]);
                 }
            }
            return $is_overlap;
        }
    };

    for (my $i = 0; $i < scalar(@{$small}); $i++) {
        my $sf = $small->[$i];
        #trace(sprintf("\nexamined one round: %s:%d-%d",$sf->type." ".($sf->secondary_loc?$sf->secondary_loc->src_seq:$sf->name),$sf->fmin,$sf->fmax));
        my @fmins = ();
        foreach my $big (@big_coords) {
            if ($sf->fmin <= $big->[1] && $sf->fmax >= $big->[0]) {
                push @fmins, $big->[0];
            }
        }
        next unless (@fmins);
        #@fmins is sorted as @big_coords is sorted
        my ($init, $term) = ($big_index_h{$fmins[0]},$big_index_h2{$fmins[-1]});
        for (my $j = $init; $j <= $term; $j++) {
            my ($sf1, $sf2) = ($sf, $big->[$j]);
            if ($sets_order_flipped) {
                ($sf1, $sf2) = ($sf2, $sf1);
            }
            my ($c1, $c2) = ($sf1, $sf2);
            if ($self->get_property('query_compare') eq 'secondary_location') {
                $c1 = $self->_qsec2sf_h($c1);
            }
            if ($self->get_property('subject_compare') eq 'secondary_location') {
                $c2 = $self->_ssec2sf_h($c2);
            }
            my $is_overlap = icheck($c1, $c2);
            $nc++;
            if ($is_overlap) {
                if ($self->get_property("check")) {
                    # user doesn't care about list of
                    # overlaps;
                    $self->set_property("has_overlaps", 1);
                    return;
                }
                #trace(sprintf("%s:%d-%d overlap %s:%d-%d",$sf1->name,$sf1->fmin,$sf1->fmax,$sf2->name,$sf2->fmin,$sf2->fmax));
                push(@ovs, [$c1, $c2, $is_overlap]);
            } else {
                #trace(sprintf("%d-%d %s(d=%d) not ov %d-%d %s(d=%d)",$sf1->fmin,$sf1->fmax,$sf1->type." ".$sf1->name,$sf1->depth,$sf2->fmin,$sf2->fmax, $sf2->type." ".($sf2->secondary_loc?$sf2->secondary_loc->src_seq:$sf2->name), $sf2->depth));
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
#prerequisite: first arg is from query/user's first arg
#return array ref: ov length, ov_fmin, ov_fmax
sub overlaps {
    my $self = shift;
    my $sf1 = shift;
    my $sf2 = shift;
    confess("To check overlaps, both feature must be on the same level") unless ($sf1->depth == $sf2->depth);
    return unless ($sf1->type eq $self->get_property('query_type')
                   && $sf2->type eq $self->get_property('subject_type')); #not right type, no overlap

    if ($self->get_property('query_compare') eq 'secondary_location') {
        $sf1 = $sf1->secondary_loc;
    }
    if ($self->get_property('subject_compare') eq 'secondary_location') {
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

#=head2 get_distance

#  Usage   -
#  Returns -
#  Args    - SOI::Feature, SOI::Feature

#=cut

#sub get_distance {
#    my $self = shift;
#    my $sf1 = shift;
#    my $sf2 = shift;
#    my $ovs = $self->{lookup}->{$sf1->uniquename} || [];
    
#}

1;
