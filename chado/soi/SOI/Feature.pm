
package SOI::Feature;

=head1 NAME

SOI::Feature

=head1 SYNOPSIS

=head1 USAGE

my $feature = SOI::Feature->new($hashref)

=cut

=head1 FEEDBACK

Email sshu@fruitfly.org

=cut

=head1 GENERAL DESCRIPTION

For building feature tree, each SOI::Feature object has 0..m child SOI::Feature objects

=cut

=head2 chado feature table column method

all chado feature table column names can be called, e.g. $feature->uniquename

=cut

=head2 non-chado feature table column method

id, src/src_seq(=srcfeature.uniquename), nbeg, nend, start, end, symbol(=name), type(=SO type name), hash

=cut

=head2 coordinate system

remapped to interbase 0 system (nbeg, nend) and base 1 system(start, end) from fmin, fmax and strand

=cut

=head2 multivalued attr/method

properties, dbxrefs, and ontologies, all are a list of hash refs, nodes for child features

=cut

=head2 subject seq

  adapter by default get subject seq residues and all subject seq data are in $sec_loc->{seq},
  which will have subject seq length as $sec_loc->{seq}->{seqlen}, if database has it.
  secondary_location will have rank, right now FlyBase use loc rank 1 to indicate span is subject

=cut

=head2 computating method

transform, stitch_child_segments, see doc below for each method

=cut

=head2 GAME xml for apollo

the following structure is expected

   chromosome_arm
      contig
      genes
         their children ...
      analyses
         result features
            their children
  and all features have to be mapped to contig using transform method and contig feature is made
  from overlapping segments (golden_path_region) for the specified range

=cut

=head2 XML formats

chaos, soi, GAME. soi is nested structure, start/end tag are SO type,
it is between chaos and GAME

=cut


use Exporter;

use strict;
use Carp;
use SOI::Outputter qw(chaos_xml soi_xml game_xml gff3);
use base qw(Exporter);
use vars qw($AUTOLOAD);

=head1 FUNCTIONS

=cut

sub new {
    my $proto = shift; my $class = ref($proto) || $proto;;
    my $self = {};
    bless $self, $class;

    $self->{hash} = {};
    $self->hash(@_);
    return $self;
}

sub hash {
    my $self = shift;
    if (@_) {
        my $h = shift;
        confess("must be a hash ref") unless (ref($h) eq 'HASH');
        $self->{hash} = $h;
        #do some compu: convert db fmin/fmax to nbeg/nend (directional interbase 0 system)
        $self->nbeg($h);
        $self->nend($h);
    }
    return $self->{hash};
}
sub id {
    shift->hash->{feature_id};
}
sub type {
    my $self = shift;
    $self->hash->{type} = shift if (@_);
    return $self->hash->{type};
}
sub name {
    my $self = shift;
    $self->hash->{name} = shift if (@_);
    return $self->hash->{name};
}
*symbol =\&name;

sub uniquename {
	my $self = shift;
	$self->hash->{uniquename} = shift if (@_);
	return $self->hash->{uniquename} || $self->name;
}

sub src_seq {
    my $self = shift;
    if (@_) {
        $self->hash->{src_seq} = shift;
    }
    return $self->hash->{src_seq};
}
*src = \&src_seq;

sub nbeg {
    my $self = shift;
    if (@_) {
        my $h = shift;
        my $nbeg;
        if (ref($h)) {
            my $strand = $h->{strand} || 0;
            $nbeg = ($strand > 0) ? $h->{fmin} : $h->{fmax};
        } else {
            $nbeg = $h;
        }
        $self->hash->{nbeg} = $nbeg;
    }
    return $self->hash->{nbeg};
}
sub nend {
    my $self = shift;
    if (@_) {
        my $h = shift;
        my $nend;
        if (ref($h)) {
            my $strand = $h->{strand} || 0;
            $nend = ($strand > 0) ? $h->{fmax} : $h->{fmin}
        } else {
            $nend = $h;
        }
        $self->hash->{nend} = $nend;
    }
    return $self->hash->{nend};
}
#it is genomic length (readonly), not seqlen
sub length {
    my $self = shift;
    $self->{length} = shift if (@_);
    unless ($self->{length}) {
        if (defined($self->fmin) && defined($self->fmax)) {
            $self->{length} = $self->fmax - $self->fmin;
        }
        elsif (defined($self->nbeg) && defined($self->nend)) {
            my ($s, $e) = ($self->nbeg, $self->nend);
            if ($self->strand < 0) {
                ($s,$e) = ($e, $s);
            }
            $self->{length} = $e - $s;
        }
    }
    return $self->{length};
}

sub strand {
    my $self = shift;
    $self->hash->{strand} = shift if (@_);
    return $self->hash->{strand};
}
sub start {
    my $self = shift;
    $self->hash->{start} = shift if (@_); #support game parsing
    unless (defined($self->hash->{start})) {
        my $strand = $self->strand;
        $self->hash->{start} =
          ($strand > 0) ? $self->nbeg + 1 : $self->nbeg;
    }
    return $self->hash->{start};
}
sub end {
    my $self = shift;
    $self->hash->{end} = shift if (@_); #support game parsing
    unless (defined($self->hash->{end})) {
        my $strand = $self->strand || ($self->nend - $self->nbeg);
        my $end = ($strand > 0) ? $self->nend : $self->nend + 1;
        $self->hash->{end} = $end;
    }
    return $self->hash->{end};
}
sub nodes {
    my $self = shift;
    if (@_) {
        my $nodes = shift;
        unless (ref($nodes) eq 'ARRAY') {
            $nodes = [$nodes];
        }
        $self->{nodes} = $nodes;
    }
    return $self->{nodes};
}
sub add_node {
    my $self = shift;

    if (@_) {
        push @{$self->{nodes}}, shift;
    }
}
sub synonyms {
    my $self = shift;
    if (@_) {
        my $syn = shift;
        $syn = [$syn] unless (ref($syn) eq 'ARRAY');
        $self->{synonyms} = $syn;
    }
    return $self->{synonyms};
}
sub add_synonym {
    my $self = shift;
    if (@_) {
        push @{$self->{synonyms}}, shift;
    }
}
sub dbxrefs {
    my $self = shift;
    if (@_) {
        my $dbx = shift;
        $dbx = [$dbx] unless (ref($dbx) eq 'ARRAY');
        $self->{dbxrefs} = $dbx;
    }
    return $self->{dbxrefs};
}
sub add_dbxref {
    my $self = shift;
    if (@_) {
        push @{$self->{dbxrefs}}, shift;
    }
}
sub get_property {
    my $self = shift;
    my $k = shift;
    my @val;
    map{
        if ($k eq $_->{type}) {
            push @val, $_->{value};
        }
    }@{$self->properties || []};
    return @val;
}
sub properties {
    my $self = shift;
    if (@_) {
        my $p = shift;
        $p = [$p] unless (ref($p) eq 'ARRAY');
        $self->{properties} = $p;
    }
    return $self->{properties};
}
sub add_property {
    my $self = shift;
    if (@_) {
        my $h = shift;
        unless (ref($h) eq 'HASH') {
            my $k = $h;
            $h = {type=>$k, value=>shift};
        }
        push @{$self->{properties}}, $h;
    }
}
sub ontologies {
    my $self = shift;
    if (@_) {
        my $ont = shift;
        $ont = [$ont] unless (ref($ont) eq 'ARRAY');
        $self->{ontologies} = $ont;
    }
    return $self->{ontologies};
}
sub add_ontology {
    my $self = shift;
    if (@_) {
        push @{$self->{ontologies}}, shift;
    }
}
sub comments {
    my $self = shift;
    if (@_) {
        my $comments = shift;
        $comments = [$comments] unless (ref($comments) eq 'ARRAY');
        $self->{comments} = $comments;
    }
    return $self->{comments};
}
sub add_comment {
    my $self = shift;
    if (@_) {
        push @{$self->{comments}}, shift;
    }
}
#it has a seq that is hashref to a chado feature (name,residues,etc, plus SO-type,genus, species)
sub secondary_locations {
    my $self = shift;
    if (@_) {
        my $loc = shift;
        $loc = [$loc] unless (ref($loc) eq 'ARRAY');
        $self->{secondary_nodes} = [map{ref($self)->new($_)}@$loc];
    }
    return [map{$_->hash}@{$self->secondary_nodes || []}];
}
sub add_secondary_location {
    my $self = shift;
    if (@_) {
        push @{$self->{secondary_nodes}}, ref($self)->new(shift);
    }
}
#same as secondary_location but obj, as matter of fact, location stores internally as typeless SOI::Feature without property/dbxref/ontology
sub secondary_nodes {
    my $self = shift;
    if (@_) {
        my $nodes = shift;
        $nodes = [$nodes] unless (ref($nodes) eq 'ARRAY');
        $self->{secondary_nodes} = $nodes;
    }
    return $self->{secondary_nodes};
}
sub add_secondary_node {
    my $self = shift;
    if (@_) {
        my $node = shift;
        push @{$self->{secondary_nodes}}, $node;
    }
}
sub secondary_node {
    my $nodes = shift->secondary_nodes;
    return $nodes->[0] if (@{$nodes || []});
}
*secondary_loc =\&secondary_node;

=head2 set_depth

  Usage  - $feature->set_depth(0)
  Return - none
  Args   - depth val

  Description  - set depth and its children depth, change depth will change tree structure.
  mainly for finding intersection (see SOI::IntersectGraph)

=cut

sub set_depth {
    my $self = shift;
    my $d = shift;
    $self->depth($d);
    map{$_->set_depth($self->depth+1)}@{$self->nodes || []};
}

=head2 transform

  Usage  - $feature->transform($new_contig)
  Return - none
  Args   - new contig(SOI::Feature)

  Description  - map $feature and its children to $new_contig

  Prerequisite - both feature and new_contig are located on the same src_seq

=cut

sub transform {
    my $self = shift;
    my $new_f = shift;
    map{$_->transform($new_f)}@{$self->nodes || []};
    $self->_transform($new_f);
}
sub _transform {
    my $self = shift;
    my $new_contig = shift || confess("must pass in Feature as arg");

    if ($self->src_seq &&
        $new_contig->name &&
        $self->src_seq eq $new_contig->name) {
        #already transformed
        return;
    }

    if (!$new_contig->src_seq ||
        !$self->src_seq ||
        $new_contig->src_seq ne $self->src_seq) {
        #cant transform
        return;
    }

    #don't transform if this feature don't have coord,
    return unless (defined($self->nbeg));

    my $delta = $new_contig->fmin;

    $self->hash->{src_seq} = $new_contig->uniquename;
    $self->hash->{srcfeature_id} = $self->src_seq;
    $self->hash->{fmin} = $self->fmin - $delta;
    $self->hash->{fmax} = $self->fmax - $delta;
    #make sure other coords will change as well
    delete $self->hash->{start};
    delete $self->hash->{end};
    $self->hash($self->hash);
}

=head2 stitch_child_segments

  Usage   - my $contig = $arm->stich_child_segments($fmin, $fmax, $options)
  Returns - SOI::Feature object, and original segments (array ref)
  Args    - arm (SOI::Feature) with overlapping segments (golden_path_region) that cover $fmin and $fmax
            fmin, fmax: the range of new contig
            optional options: {name=>'temp:blabla'}, {source_origin_feature_type=>'blabla'}
            the latter default to chromosome_arm

  Description - stitch all sequence from overlapping segments and cut to the range (fmin, fmax)

  Prerequisite - all segments on plus strand and overlap with neighbors

=cut

sub stitch_child_segments {
    my $self = shift;
    my @coords = (shift, shift);
    my $opts = shift || {};

    my ($nbeg, $nend) = @coords;

    my @nodes = sort{$a->nbeg <=> $b->nbeg}@{$self->nodes || []};
    return unless (@nodes);
    my ($seg_b,$seg_e) = ($nodes[0]->nbeg,$nodes[-1]->nend);
    unless (defined $nbeg && defined $nend) {
        ($nbeg, $nend) = ($seg_b,$seg_e);
    }
    my $most_top_type = $opts->{source_origin_feature_type} || 'chromosome_arm';
    confess("ASSERTION ERROR: cutted segment, top level must be $most_top_type and range must be within range of children\n".
            "and requested ($nbeg, $nend) is NOT within ($seg_b, $seg_e)")
      unless ($nbeg >= $seg_b && $nend <= $seg_e && $self->type eq $most_top_type);

    my $residues = "";
    my $last_e = 0;
    for (my $i = 0; $i < scalar(@nodes) - 1; $i++) {
        my $n = $nodes[$i];
        $residues .= substr($n->residues, 0, $n->seqlen - ($n->nend - $nodes[$i+1]->nbeg))
    }
    $residues .= $nodes[-1]->residues;

#tested: stitching worked correctly
#    my ($arml, $armsl, $armasl) = ($self->seqlen, length($residues),length($self->residues));
#    my $same = ($residues eq $self->residues);
#    printf STDERR "seqlen=%d stitched_reslen=%d actual reslen=%d seq same? %d\n",$arml,$armsl,$armasl, $same;

    my $offset = ($nbeg-$seg_b);
    $residues = substr($residues,$offset,($nend - $nbeg));
    my $tmp = $opts->{name} || sprintf("%s:%d-%d",$nodes[0]->src_seq,$nbeg,$nend);
    my $new = SOI::Feature->new;
    my $nh =
      {feature_id=>$tmp,
       name=>$tmp,
       uniquename=>$tmp,
       fmin=>$nbeg,
       fmax=>$nbeg + CORE::length($residues),
       seqlen=>CORE::length($residues),
       strand=>1,
       is_analysis=>0,
       src_seq=>$nodes[0]->src_seq,
       srcfeature_id=>$nodes[0]->hash->{srcfeature_id},
       residues=>$residues,
       type=>'contig'
      };
    $new->hash($nh);
    $self->nodes([$new]);
#    $new->dbxrefs([]);$new->properties([]);
    return ($new, [@nodes]);
}
sub _rsetup_coord {
    my $self = shift;
    $self->_setup_coord;
    map{$_->_rsetup_coord}@{$self->nodes || []};
}
sub _setup_coord {
    my $self = shift;

    if ($self->hash->{start} && $self->hash->{end}) {
        my ($s, $e) = ($self->start, $self->end);
        $self->hash->{strand} = $s < $e ? 1 : -1;
        ($s, $e) = ($e, $s) if ($self->strand < 0);
        $self->fmin($s-1);
        $self->fmax($e);
    }
    unless (defined $self->nbeg && defined $self->nend) {
        my $h = $self->hash;
        $self->nbeg($h);
        $self->nend($h);
    }
    if (defined $self->nbeg && defined $self->nend) {
        $self->start;
        $self->end;
    }
    foreach my $loc (@{$self->secondary_nodes || []}) {
        $loc->_setup_coord;
    }
}
sub to_chaos_xml {
    my $self = shift;

    return if ($self->hash->{is_analysis} && !@{$self->nodes || []});
    #detect cycle;
    my @c_ids = grep{$_->id}@{$self->nodes || []};
    confess(sprintf("cycle detected; parent=%s", $self->hash->{name})) if (grep {$self->id eq $_}@c_ids);
    return chaos_xml($self, @_);

}
sub to_soi_xml {
    my $self = shift;

    #detect cycle;
    my @c_ids = grep{$_->id}@{$self->nodes || []};
    confess(sprintf("cycle detected; parent=%s", $self->hash->{name})) if (grep {$self->id eq $_}@c_ids);
    $self->_setup_coord;
    return soi_xml($self, @_);

}
sub to_game_xml {
    my $self = shift;

    #detect cycle;
    my @c_ids = grep{$_->id}@{$self->nodes || []};
    confess(sprintf("cycle detected; parent=%s", $self->hash->{name})) if (grep {$self->id eq $_}@c_ids);
    return game_xml($self, @_);
}
sub to_gff {
    my $self = shift;

    #detect cycle;
    my @c_ids = grep{$_->id}@{$self->nodes || []};
    confess(sprintf("cycle detected; parent=%s", $self->hash->{name})) if (grep {$self->id eq $_}@c_ids);
    return gff3($self, @_);
}
*to_gff3 =\&to_gff;
*to_GFF3 =\&to_gff;

sub _min_attr {
    my $self = shift;
    unless ($self->{_min_attr}) {
        my %att_h;
        map{$att_h{$_}=1}keys %{$self->hash};
        #some of them alread have method that is ok since it is for autoload method (see below)
        map{$att_h{$_}=1}qw(type relationship_type depth name uniquename feature_id genus species residues seqlen md5checksum srcfeature_id src_seq fmin fmax strand residue_info phase is_fmin_partial is_fmax_partial rank locgroup organism program database);
        #add game fields (seqtype: temp holder for sequence type as seq is feature type in GAME parsing)
        map{$att_h{$_}=1}qw(produces_seq focus seq author date timestamp version description score seqtype);
        $self->{_min_attr} = [keys %att_h];
    }
    return $self->{_min_attr};
}

sub DESTROY {}
sub AUTOLOAD {
    no strict "refs";
    my ($self, $newval) = @_;

    my $field = $AUTOLOAD;
    $field =~ s/.*://;   # strip fully-qualified portion
    if (grep {$field eq $_}@{$self->_min_attr || []}) {
        #use autoload to install a method(with closure)
        #so next time it is called, the method is called instead of autoload for speed
        *{$field} = sub {
            my $self = shift;
            @_ ? $self->hash->{$field} = shift : $self->hash->{$field};
        };
        &$field(@_);
    } else {
        confess("Does not support $field");
   }
}
#sub AUTOLOAD {
#    my $self = shift;

#    my $name = $AUTOLOAD;
#    $name =~ s/.*://;   # strip fully-qualified portion
#    if ($name eq "DESTROY") {
#        return;
#    }
#    if (grep {$name eq $_}@{$self->_min_attr || []}) {
#        $self->hash->{$name} = shift if (@_);
#        return $self->hash->{$name};
#    } else {
#        warn("Does not support $name") if ($ENV{DEBUG} || $self->hash->{DEBUGMODE});
#   }
#}

1;
