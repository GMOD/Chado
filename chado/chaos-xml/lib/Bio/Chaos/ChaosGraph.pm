# $Id: ChaosGraph.pm,v 1.3 2004-10-18 20:49:35 cmungall Exp $
#
#

=head1 NAME

  Bio::Chaos::ChaosGraph     - object for representing a chaos-xml dataset

=head1 SYNOPSIS

  use Bio::Chaos::ChaosGraph;
  my $chaos = Bio::Chaos::ChaosGraph->new($chaos_stag);
  
  my $fl = $chaos->top_features;
  foreach my $f (@$fl) {
    next unless $f->get_type eq 'gene';
    $island_feature = $chaos->make_island($f, 5000, 5000);

    print $island_feature->xml;
  }

=head1 DESCRIPTION

=cut

package Bio::Chaos::ChaosGraph;

use Exporter;
use Data::Stag qw(:all);
use Bio::Chaos::Root;
@ISA = qw(Bio::Chaos::Root Exporter);

use FileHandle;
use strict;
use Graph;

# Constructor


=head2 new

  Usage   - my $chaos = Bio::Chaos::ChaosGraph->new($chaos_stag)
  Returns - Bio::Chaos::ChaosGraph

creates a new Chaos::ChaosGraph object

=cut

sub new {
    my $proto = shift; my $class = ref($proto) || $proto;;
    my $self = bless {}, $class;
    my ($stag) =
      $self->_rearrange([qw(stag)], @_);
    $self->graph(Graph->new);
    $self->locgraph(Graph->new);
    $self->feature_idx({});
    $self->init_from_stag($stag) if $stag;
    return $self;
}

sub init_from_stag {
    my $self = shift;
    my $stag = shift;
    if (!$stag) {
	$self->freak;
    }
    foreach my $feature ($stag->get_feature) {
#	print "====\nADDING FEATURE:\n";
#	print $feature->sxpr;
	$self->add_feature($feature);
    }
    foreach my $fr ($stag->get_feature_relationship) {
#	print "====\nADDING REL:\n";
#	print $fr->sxpr;
	$self->add_feature_relationship($fr);
    }
}

sub init_from_file {
    my $self = shift;
    my $file = shift;
    my $fmt = shift || 'genbank';
    $self->chaos_flavour("genbank_unflattened");
    $self->load_module("Bio::SeqIO");
    my $unflattener = $self->unflattener;
    my $type_mapper = $self->type_mapper;
    my $seqio =
      Bio::SeqIO->new(-file=> $file,
                      -format => $fmt);
    while (my $seq = $seqio->next_seq()) {
	$unflattener->unflatten_seq(-seq=>$seq,
				    -use_magic=>1);
	$type_mapper->map_types_to_SO(-seq=>$seq);
	my $outio = Bio::SeqIO->new( -format => 'chaos');
	$outio->write_seq($seq);
	my $stag = $outio->handler->stag;
	$self->init_from_stag($stag);
    }
    $self->name_all_features;
    return;
}

# --- turns object into stag document ---
sub stag {
    my $self = shift;
    my $W = Data::Stag->makehandler;
    $self->fire_events($W);
    return $W->stag;
}

sub chaos_flavour {
    my $self = shift;
    $self->{_chaos_flavour} = shift if @_;
    return $self->{_chaos_flavour} || 'chaos';
}

sub metadata {
    my $self = shift;
    $self->{_metadata} = shift if @_;
    return $self->{_metadata};
}


sub fire_events {
    my $self = shift;
    my $W = shift;

    my $t = time;
    my $ppt = localtime($t);
    my $prog = $0;
    chomp $prog;

    my @meta = $self->metadata ? ($self->metadata) : ();
    $W->start_event('chaos');
    $W->event(chaos_metadata=>[
			       [chaos_version=>1],
			       [chaos_flavour=>$self->chaos_flavour],
			       @meta,
			       
			       [feature_unique_key=>'feature_id'],
			       [equiv_chado_release=>'chado_1_01'],
			       
			       [export_unixtime=>$t],
			       [export_localtime=>$ppt],
			       [export_host=>$ENV{HOST}],
			       [export_user=>$ENV{USER}],
			       [export_perl5lib=>$ENV{PERL5LIB}],
			       [export_program=>$prog],
			      ]
	     );
    my $g = $self->graph;

    # unordered; features followed by frs
    my $done_idx = {};
    my @ufeats = @{$self->unlocalised_features};
    $self->fire_feature_event($W, $_, $done_idx) foreach @ufeats;
    
#    my $fidx = $self->feature_idx;
#    foreach my $f (values %$fidx) {
#	$W->event('feature', $f->data);
#    }
#    foreach my $fid (keys %$fidx) {
#	my @es = $g->in_edges($fid);
#	while (my @e = splice(@es, 0, 2)) {
#	    $self->freak("bad edge [@e] for $fid") unless $e[0] && $e[1];
#	    my $type = $g->get_attribute('type', @e);
#	    $W->event(feature_relationship=>[
#					     [subject_id=>$e[1]],
#					     [object_id=>$e[0]],
#					     [type=>$type],
#					    ]
#		     );
#	}
#    }
    
    $W->end_event('chaos');
}

sub fire_feature_event {
    my $self = shift;
    my $W = shift           || $self->freak("no writer");
    my $f = shift           || $self->freak("no feature"); 
    my $done_idx = shift    || $self->freak("no index of done features");
    my $fid = $f->get_feature_id;
    return if $done_idx->{$fid};

    my $g = $self->graph;
    my @es = $g->in_edges($fid); # object FRs
    my @frs = ();
    while (my @e = splice(@es, 0, 2)) {
	$self->freak("bad edge [@e] for $fid") unless $e[0] && $e[1];
	my $type = $g->get_attribute('type', @e);

        my $object_id = $e[0];
        my $subject_id = $e[1];
        if (!$self->feature_idx->{$object_id}) {
            #$self->freak("cannot find object_id:$object_id in feature_idx for $fid / $subject_id");
            $f->add_featureprop([[type=>'comment'],[value=>"this feature has a parent in another subgraph; there will be a trailing object_id=$object_id"]]);
            # this is the case for AceView worm models and
            # dicistronic genes where exons are shared across genes
        }
        else {
            # objects must be written before subjects
            $self->fire_feature_event($W,
                                      $self->feature_idx->{$object_id},
                                      $done_idx);
        }
	# no point carrying on, redundant tree traversal
	return if $done_idx->{$fid};
	push(@frs,
	     [feature_relationship=>[
				     [subject_id=>$subject_id],
				     [object_id=>$object_id],
				     [type=>$type],
				    ]]);
    }
    return if $done_idx->{$fid};

    $W->event(feature=>$f->data);
    $W->event(@$_) foreach @frs;
    $done_idx->{$fid} = 1;
    my @nextfs = 
      (@{$self->get_features_on($f)},
       @{$self->get_features_contained_by($f)});
#    print "$fid has the following: @nextfs\n";
    $self->fire_feature_event($W, $_, $done_idx) foreach @nextfs;
    return;
}


sub init_mldbm {
    my $self = shift;
    require "MLDBM.pm";
    import("MLDBM", qw(DB_File Storable));
    return;
}

sub next_idn {
    my $self = shift;
    $self->{_next_idn} = shift if @_;
    return $self->{_next_idn};
}


sub generate_new_feature_id {
    my $self = shift;
    my $prefix = shift || 'feature';
    my $feature_id;
    my $idn = $self->{_next_idn} || 0;
    my $fidx = $self->feature_idx;
    while (!$feature_id) {
	$idn++;
	unless ($fidx->{"$prefix-$idn"}) {
	    $feature_id = "$prefix-$idn";
	}
    }
    $self->{_next_idn} = $idn;
    return $feature_id;
}

sub unflattener {
    my $self = shift;
    $self->{_unflattener} = shift if @_;
    if (!$self->{_unflattener} ) {
	$self->load_module("Bio::SeqFeature::Tools::Unflattener");
	$self->{_unflattener} =
	  Bio::SeqFeature::Tools::Unflattener->new;
    }
    return $self->{_unflattener};
}

sub type_mapper {
    my $self = shift;
    $self->{_type_mapper} = shift if @_;
    if (!$self->{_type_mapper} ) {
	$self->load_module("Bio::SeqFeature::Tools::TypeMapper");
	$self->{_type_mapper} =
	  Bio::SeqFeature::Tools::TypeMapper->new;
    }
    return $self->{_type_mapper};
}


sub feature_idx {
    my $self = shift;
    $self->{_feature_idx} = shift if @_;
    return $self->{_feature_idx};
}

sub get_feature {
    my $self = shift;
    my $fid = shift;
    return $self->{_feature_idx}->{$fid};
}

# relationship graph
# equiv to chaos/chado feature_relationship graph
sub graph {
    my $self = shift;
    $self->{_graph} = shift if @_;
    return $self->{_graph};
}

# location graph
# equiv to chaos/chado featureloc graph
# (locations can be arbitrarily nested in graphs)
sub locgraph {
    my $self = shift;
    $self->{_locgraph} = shift if @_;
    return $self->{_locgraph};
}

sub add_feature {
    my $self = shift;
    my $feature = shift;
    my $fid = $feature->get_feature_id;

    $self->graph->add_vertex($fid);
    $self->feature_idx->{$fid} = $feature;
    my @flocs = $feature->get_featureloc;
    foreach my $floc (@flocs) {
	$self->add_featureloc($feature, $floc);
    }
    return 1;
}

sub add_featureloc {
    my $self = shift;
    my $feature = shift;
    my $floc = shift;
    my $lg = $self->locgraph;
    my $fid = $feature->get_feature_id;

    my $src_fid = $floc->get_srcfeature_id;
    my @e = ($src_fid, $fid);
    $lg->add_edge(@e);
    foreach ($floc->kids) {
	next unless $_->isterminal;
	next if $_->name eq 'srcfeature_id';
	next; #TODO
	$lg->set_attribute($_->name,
			   @e,
			   $_->data);
    }
}

sub replace_featureloc {
    my $self = shift;
    my $feature = shift;
    my $old_floc = shift;
    my $new_floc = shift;

    my $lg = $self->locgraph;

    my $fid = $feature->get_feature_id;

    my $old_src_fid = $old_floc->get_srcfeature_id;
    my $new_src_fid = $new_floc->get_srcfeature_id;

    my @old_e = ($old_src_fid, $fid);
    my @e = ($new_src_fid, $fid);

    $lg->delete_edge(@old_e);
    $lg->add_edge(@e);
    foreach ($new_floc->kids) {
        next unless $_->isterminal;
        next if $_->name eq 'srcfeature_id';
        $lg->set_attribute($_->name,
                           @e,
                           $_->data);
    }
    $feature->set_featureloc($new_floc->data);
    return;
}

sub add_feature_relationship {
    my $self = shift;
    my $fr = shift;
    my $g = $self->graph;
    my %frh = $fr->pairs;
    my @edge = ($frh{object_id},
		 $frh{subject_id});

    if (!$edge[0] || !$edge[1]) {
	$self->freak("bad feature_rel", $fr);
    }
    $g->add_edge(@edge);
    $g->set_attribute("type",
		      @edge,
		      $frh{type} || '');
    $g->set_attribute("rank",
		      @edge,
		      $frh{rank} || '0');
    if (1) {
	# TEST 
	my @oe = $g->out_edges($frh{object_id});
	$self->freak("uhoh @oe", $fr) if !$oe[0] || !$oe[1];
	my @e = $g->in_edges($frh{subject_id});
	$self->freak("uhoh @e", $fr) if !$e[0] || !$e[1];
    }

    return 1;
}

# features at the root of the feature graph
sub top_features {
    my $self = shift;
    my $g = $self->graph;
    my $fidx = $self->feature_idx;
    my @fl = ();
    while (my($fid, $f) = each %$fidx) {
	if (!$g->in_edges($fid)) {
	    push(@fl, $f);
	}
    }
    return \@fl;
}

sub leaf_features {
    my $self = shift;
    my $g = $self->graph;
    my $fidx = $self->feature_idx;
    my @fl = ();
    while (my($fid, $f) = each %$fidx) {
	if (!$g->out_edges($fid)) {
	    push(@fl, $f);
	}
    }
    return \@fl;
}

# features at top of location graph
sub unlocalised_features {
    my $self = shift;
    my $lg = $self->locgraph;
    my $fidx = $self->feature_idx;
    my @fl = ();
    while (my($fid, $f) = each %$fidx) {
	if (!$lg->in_edges($fid)) {
	    push(@fl, $f);
	}
    }
    return \@fl;
}

# features at top of location AND containment graph
sub top_unlocalised_features {
    my $self = shift;
    my $g = $self->graph;
    my $lg = $self->locgraph;
    my $fidx = $self->feature_idx;
    my @fl = ();
    while (my($fid, $f) = each %$fidx) {
	if (!scalar($g->in_edges($fid)) &&
	    !scalar($lg->in_edges($fid))) {
	    push(@fl, $f);
	}
    }
    return \@fl;
}

sub create_subgraph_around {
    my $self = shift;
    my $f = shift;
    my $C = $self->new;
    my $it = Iterator->new($self->locgraph, undef, 'in');
    
}

sub get_features_on {
    my $self = shift;
    my $srcf = shift;

    my $srcfid = ref($srcf) ? $srcf->get_feature_id : $srcf;
    my $lg = $self->locgraph;

    my @e = $lg->out_edges($srcfid);
    my @located_fids = ();
    while (@e) {
	shift @e;
	push(@located_fids, shift @e);
    }
    my $fidx = $self->feature_idx;
    return [map {$fidx->{$_}} @located_fids];
}

sub get_features_contained_by {
    my $self = shift;
    my $f = shift;

    my $g = $self->graph;

    my @e = $g->out_edges($f->get_feature_id);
    my @contained_fids = ();
    while (@e) {
	shift @e;
	push(@contained_fids, shift @e);
    }
    my $fidx = $self->feature_idx;
    return [map {$fidx->{$_}} @contained_fids];
}

sub get_features_containing {
    my $self = shift;
    my $f = shift;

    my $g = $self->graph;

    my @e = $g->in_edges($f->get_feature_id);
    my @container_fids = ();
    while (@e) {
	push(@container_fids, shift @e);
	shift @e;
    }
    my $fidx = $self->feature_idx;
    return [map {$fidx->{$_}} @container_fids];
}

sub feature_relationships_for_subject {
    my $self = shift;
    my $f = shift;

    my $g = $self->graph;

    my @e = $g->in_edges(ref($f) ? $f->get_feature_id : $f);
    my @frs = ();
    while (@e) {
	if (!$e[0] || !$e[1]) {
	    $self->freak("bad edge: [@e]", $f);
	}
	my $type = $g->get_attribute('type', @e);
	push(@frs, 
	     Data::Stag->new(feature_relationship=>[
						    [subject_id=>$e[1]],
						    [object_id=>$e[0]],
						    [type=>$type],
						   ]));
	shift @e;
	shift @e;
    }
    return [@frs];
}

sub all_features {
    my $self = shift;
}

sub get_related_features {
}

sub get_all_contained_features {
    my $self = shift;
    my $top = shift || $self->freak("requires parameter: top [feature]");
    my $topfid = $top->get_feature_id;
    my $fidx = $self->feature_idx;

    my $iterator = $self->feature_iterator($topfid);
    my @cfids = ();
    while (my $fid = $iterator->next_vertex) {
	push(@cfids, $fid) unless $fid eq $topfid;
    }
    return [map {$fidx->{$_}} @cfids];
}

sub get_floc {
    my $self = shift;
    my $f = shift;

    my @flocs = $f->get_featureloc;
    if (@flocs > 1) {
	@flocs = grep {!$_->get_rank && !$_->get_locgroup} @flocs;
	if (@flocs > 1) {
	    $self->freak("invalid flocs", @flocs);
	}
    }
    return shift @flocs;
}

sub make_gene_islands {
    my $self = shift;
    my @args = @_;
    my $fs = $self->top_features;
    my @islands = ();
    foreach my $f (@$fs) {
	my $type = $f->get_type;
	$self->freak("no type", $f) unless $type;
	next unless $f->get_type eq 'gene';
	my $island = $self->make_island($f, @args);
	push(@islands, $island);
    }
    return \@islands;
}

# generates an island contig around a feature $f and transforms the
# coordinates to the contig
sub make_island {
    my $self = shift;
    my $f = shift;

    my ($left, $right) = @_;
    if (!$left) {
	$left = 0;
    }
    if (!$right) {
	$right = $left;
    }
    my $floc = $self->get_floc($f);
    if (!$floc) {
	$self->freak("No featureloc", $f);
    }
    my $src_fid = $floc->get_srcfeature_id;
    my $srcf = $self->get_feature($src_fid);
    my $strand = $floc->get_strand;

    my $nbeg = $floc->get_nbeg - $left * $strand;
    my $nend = $floc->get_nend + $right * $strand;
#    my $island_id = $self->generate_new_feature_id('contig');
    my $island_id = "contig:$src_fid:$nbeg:$nend";
#    print "from: $src_fid\n";
    my $island_name = 'contig-'.$f->get_name.'-'.$left.'-'.$right;
    my $island_uniquename = 'contig-'.$f->get_uniquename.'-'.$left.'-'.$right;
    if ($self->verbose) {
        logtime();
        printf STDERR "Making island $island_name\n";
    }
    my $island =
      $self->new_feature(
			 feature_id=>$island_id,
			 name=>$island_name,
			 uniquename=>$island_uniquename,
			 type=>'contig',
			 featureloc=>[
				      nbeg=>$nbeg,
				      nend=>$nend,
                                      strand=>$strand,
				      srcfeature_id=>$src_fid,
				     ],
			);
    $self->derive_residues($island);
    $self->add_feature($island);
    $self->loctransform($f,
			$island);
    my $children = $self->get_all_contained_features($f);
    # replicate feature and add to subhraph
    # (we wish to replicate because a feature can be
    #  shared between graphs and we want to do loctransforms
    #  on the features on a per-subgraph basis)
    $children = [map {$_->duplicate} @$children];

    foreach my $child (@$children) {
	$self->loctransform($child, $island);
    }
    my $C = $self->new; # create a new subgraph
    my @feats = ($srcf, $island, $f, @$children);
    foreach my $subf (@feats) {
	$C->add_feature($subf);
	my $frs = $self->feature_relationships_for_subject($subf);
	$C->add_feature_relationship($_) foreach @$frs;
    }
    return $C;
}

sub derive_residues {
    my $self = shift;
    my $feature = shift;
    my $res;
    if ($self->is_spliced($feature)) {
        $self->freak('not yet');
    }
    else {
        my @flocs = $feature->get_featureloc;
	if (!@flocs) {
	    $self->freak("feature is not located, can't derive residues",
			 $feature);
	}
        @flocs = grep {!$_->get_rank} @flocs;
        $self->freak unless @flocs;
        my @resl =
          map {
	      my $src_fid = $_->get_srcfeature_id;
              my $srcf = $self->get_feature($src_fid);
	      if (!$srcf) {
		  $self->freak("no source feature for $src_fid in feature",
			       $feature);
	      }
              my $srcres = $srcf->get_residues;
	      if (!$srcres) {
		  $self->freak("feature $src_fid has no residues", $srcf);
	      }
              $self->cutseq($srcres, $_->get_nbeg, $_->get_nend);
          } @flocs;
        $res = shift @resl;
        if (@resl) {
            foreach (@resl) {
                if ($_ ne $res) {
                    $self->freak("$_ ne $res");
                }
            }
        }
        
    }
    $self->freak("cannot derive residues", $feature) unless defined $res;
    $feature->set_residues($res);
    return 1;
}

sub cutseq {
    my $self = shift;
    my $res = shift;
    my $nbeg = shift;
    my $nend = shift;
    if ($nbeg <= $nend) {
        return substr($res, $nbeg, $nend-$nbeg);
    }
    else {
        my $cut = substr($res, $nend, $nbeg-$nend);
        $cut = $self->revcomp($cut);
        return $cut;
    }
}

sub revcomp {
    my $self = shift;
    my $res = shift;
    $res =~ tr/acgtrymkswhbvdnxACGTRYMKSWHBVDNX/tgcayrkmswdvbhnxTGCAYRKMSWDVBHNX/;
    return scalar(CORE::reverse($res));
}

sub loctransform {
    my $self = shift;
    my $sfeature = shift;                    # source  (eg gene)
    my $tfeature = shift;                    # target  (eg contig)

    # get source and target feature locations;
    # any feature can have >1 flocs (differentiated by rank, group)
    # (usually there will be just 1 each)
    my @sflocs = $sfeature->get_featureloc;
    my @tflocs = $tfeature->get_featureloc;

    # the source and target locations we use to actually transform
    my $sfloc;
    my $tfloc;
    my $ssrc_fid;
    my $tsrc_fid;

    my $already_transformed;
    # ASSERTION:
    # forall (@sflocs, @tflocs)
    #     there exists exactly one pair ($sfloc, $tfloc)
    #     such that $sfloc and $tfloc share the same srcfeature_id
    #
    # this pair is the source and target flocs that will be used in
    # the location transform
    foreach my $sflocI (@sflocs) {
        my $ssrc_fidI = $sflocI->get_srcfeature_id;
        if ($ssrc_fidI eq $tfeature->get_feature_id) {
            $already_transformed = 1;
            last;
        }
        foreach my $tflocI (@tflocs) {
            my $tsrc_fidI = $tflocI->get_srcfeature_id;
            # intersection
            if ($ssrc_fidI eq $tsrc_fidI) {
                if ($sfloc || $tfloc) {
                    $self->freak("CONFLICT: >1 pair [$ssrc_fid, $tsrc_fid]",
                                 $sfloc, $tfloc);
                }
                $sfloc = $sflocI;
                $tfloc = $tflocI;
                $ssrc_fid = $ssrc_fidI;
                $tsrc_fid = $tsrc_fidI;
            }
        }
    }

    if ($already_transformed) {
        # nothing to be done
        return;
    }

    # ASSERTION (see above) - at least 1 pair
    if (!($sfloc || $tfloc)) {
        $self->freak("NO LOC PAIR FOUND",
                     @sflocs, @tflocs,$sfeature,$tfeature);
    }


    # s: source
    # t: target

    my $snbeg = $sfloc->get_nbeg;
    my $snend = $sfloc->get_nend;
    my $srank = $sfloc->get_rank;
    my $sstrand = $sfloc->get_strand;
    my $tnbeg = $tfloc->get_nbeg;
    my $tnend = $tfloc->get_nend;
    my $tstrand = $tfloc->get_strand;

    my $tfid = $tfeature->get_feature_id;
    if (!$tfid) {
	$self->freak("NO FEATURE_ID", $tfeature);
    }

    $snbeg = ($snbeg - $tnbeg) * $tstrand;
    $snend = ($snend - $tnbeg) * $tstrand;

    my $nu_sfloc =
      $self->new_featureloc(srcfeature_id=>$tfid,
                            nbeg=>$snbeg,
                            nend=>$snend,
                            strand=>$sstrand,
                            rank=>$srank,
                           );
    $self->replace_featureloc($sfeature, $sfloc, $nu_sfloc);
    return;
}

sub history_log {

}

sub new_feature {
    my $self = shift;
    return
      Data::Stag->unflatten(feature=>[@_]);
}

sub new_featureloc {
    my $self = shift;
    return
      Data::Stag->unflatten(featureloc=>[@_]);
}

our %SPLICEDF =
  (mRNA=>1);
sub is_spliced {
    my $self = shift;
    my $feature = shift;
    my $type = $feature->get_type;
    return $SPLICEDF{$type} || 0;
}

sub iterate {
    my $self = shift;
    my $G = shift;
    my $v = shift;
    my $func = shift;
    my $iterator = $self->iterator($G, $v);
    while (my $v = $iterator->next_vertex) {
	$func->($v);
    }
}

sub iterator {
    my $self = shift;
    return Iterator->new(@_);
}

sub feature_iterator {
    my $self = shift;
    return Iterator->new($self->graph, @_);
}

sub get_features_by_type {
    my $self = shift;
    my $type = shift;
    my $fidx = $self->feature_idx;
    my @fs = grep {$_->get_type eq $type} values %$fidx;
    return [@fs];
}

sub get_features {
    my $self = shift;
    my $fidx = $self->feature_idx;
    return [values %$fidx];
}

sub validate {
    my $self = shift;
    my $W = shift;
    my $G = $self->graph;
    my $fidx = $self->feature_idx;
    my @vs = $G->vertices;
    $W->start_event('chaos_validation');
    my @missing_fids = ();
    my @errs = ();
    foreach my $v (@vs) {
	if (exists $fidx->{$v}) {
	}
	else {
	    $W->event(missing_feature=>$v);
	    push(@missing_fids, $v);
	}
    }
    if (@missing_fids) {
	push(@errs, "Missing feature_ids: @missing_fids");
    }
    my $features = $self->get_features;
    foreach my $f (@$features) {
	my $name = $f->get_name;
	my $res = $f->get_residues;
	my @flocs = $f->get_featureloc;
	if ($res && scalar(@flocs)) {
	    my $implicit_res = $self->derive_residues($f);
	    if ($res ne $implicit_res) {
		$W->event(residues_conflict=>$name);
		push(@errs, "residues $name");
	    }
	}
    }
    $W->end_event('chaos_validation');
    return @errs;
}

sub name_all_features {
    my $self = shift;
    my $basename = shift;

    my %global_id_by_type = ();   # for unnamed top features

    my $topfs = $self->top_features;
    foreach my $topf (@$topfs) {
	my $childfs = $self->get_all_contained_features($topf);
	
	my $tname = $topf->get_name;
	if (!$tname) {
	    my $type = $topf->get_type;
	    $global_id_by_type{$type} = 0 unless $global_id_by_type{$type};
	    my $id = ++$global_id_by_type{$type};
	    $tname = "$type$id";
	    if ($basename) {
		$tname = "$basename-$tname";
	    }
	    $topf->set_name($tname);
#	    $topf->set_uniquename($tname);
	}
	my %id_by_type = ();      # unique within a topfeature
    
	foreach my $cf (@$childfs) {
	    my $type = $cf->get_type;
	    $id_by_type{$type} = 0 unless $id_by_type{$type};
	    my $id = ++$id_by_type{$type};
	    my $name = "$tname-$type-$id";
	    $cf->set_name($name);
	    $cf->set_uniquename($name);
	}
    }
    return;
}

sub asciitree {
    my $self = shift;
    my $containers = $self->unlocalised_features;
    my $fidx = $self->feature_idx;
    foreach my $f (@$containers) {
	$self->asciifeature($f, 0);
    }
}

sub asciifeature {
    my $self = shift;
    my $f = shift;
    my $indent = shift || 0;

    my @flocs = $f->get_featureloc;
    printf("%s%s %s \"%s\" %s\n",
	   ' '  x $indent,
	   $f->get_type,
	   $f->get_feature_id,
	   $self->get_feature_shortlabel($f->get_feature_id),
	   join(";",
		map {
		    sprintf("%s->%s on %s",
			    $_->get_nbeg, $_->get_nend,
			    $self->get_feature_shortlabel($_->get_srcfeature_id))
		} @flocs),
	  );
    my $cfeats = $self->get_features_contained_by($f);
    foreach my $subf (@$cfeats) {
	$self->asciifeature($subf, $indent+1);
    }
    my $lfeats = $self->get_features_on($f);
    foreach my $subf (@$lfeats) {
	my $parents = $self->get_features_containing($subf);
	next if @$parents;
	printf("%s[anchors]\n",
	       ' ' x ($indent+1));
	$self->asciifeature($subf, $indent+2);
    }
}

sub get_feature_shortlabel {
    my $self = shift;
    my $fid = shift;
    my $fidx = $self->feature_idx;
    my $f = $fidx->{$fid};
    return '?' unless $f;
    my $name = $f->get_name;
    return $name if $name;
    return $fid;
}

sub debug {
    my $self= shift;
    my $fmt = shift;
    printf STDERR ($fmt, @_);
    print STDERR "\n";
}

sub logtime {
    my $t = time;
    my $lt = localtime $t;
    printf "$t $lt : ";
}


1;

package Iterator;

sub new {
    my $self = shift;
    my $G = shift;    # graph or array of graphs
    my $v = shift;
    my $dir = shift || 'out';
    unless (ref($G) eq 'ARRAY') {
	$G = [$G];
    }
    if (!$v) {
	($v) = map {$_->vertices} @$G;
    }
    my $depth = 0;
    my @nodes = ();
    
    my $closure = sub {
	my $meth = shift;
	if ($meth eq 'next_vertex') {
	    my @e;
	    my @all_child_nodes = ();
	    foreach my $g (@$G) {
		if ($dir eq 'in') {
		    @e = $g->in_edges($v);
		}
		else {
		    @e = $g->out_edges($v);
		}
		my @child_nodes = ();
		while (@e) {
		    my @pair = @e[0,1];
		    my $rank = $g->get_attribute('rank', @pair);
		    die unless defined $rank;
		    #		print "@pair rank=$rank\n";
		    push(@child_nodes, [$depth+1, shift @e, shift @e, $rank]);
		}
		@child_nodes = sort { $a->[3] <=> $b->[3] } @child_nodes;
		push(@all_child_nodes, @child_nodes);
	    }
	    push(@nodes, @all_child_nodes);
	    my $nextnode = shift @nodes;
	    if (!$nextnode) {
		$depth = -1;
		return;
	    }
	    $depth = $nextnode->[0];
	    $v = $nextnode->[2];
	    return $v;
	}
	elsif ($meth eq 'depth') {
	    return $depth;
	}
	else {
	    $self->freak("cannot call method \"$meth\" on an iterator");
	}
    };
    bless $closure, 'Iterator';
    return $closure;
}

sub next_vertex { &{shift @_}('next_vertex')}
sub depth { &{shift @_}('depth')}


1;

