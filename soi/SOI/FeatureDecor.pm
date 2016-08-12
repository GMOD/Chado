package SOI::FeatureDecor;

=head1 NAME

SOI::FeatureDecor

=head1 SYNOPSIS

=head1 USAGE

=cut

use Exporter;

use SOI::Feature;
use SOI::Visitor;
use Bio::SeqFeatureI;
use Bio::Graphics;
use Carp;
use base qw(Exporter SOI::Feature Bio::SeqFeatureI);
use vars qw($AUTOLOAD);

#@EXPORT_OK = qw();
%EXPORT_TAGS = (all=> [@EXPORT_OK]);

use strict;

=head1 FUNCTIONS

=cut


sub new {
    my $proto = shift; my $class = ref($proto) || $proto;;
    my $self = {};
    bless $self, $class;

    $self->feature(@_);
    return $self;
}

sub feature {
    my $self = shift;
    my $f = shift;
    if ($f) {
        confess("must be SOI::Feature") unless ($f->isa("SOI::Feature"));
        map{
            map{
                SOI::Visitor->set_loc($_);
                $_->_setup_coord;
            }@{$_->nodes || []};
        }grep{$_->type eq 'companalysis'}@{$f->nodes || []};
        #$f->_setup_coord;
        $self->_morph($f);
        $self->{_feature} = $f;
    }
    return $self->{_feature};
}
sub _morph {
    my $self = shift;
    my $f = shift;
    my $class = ref($self);
    bless($f, $class);
    $self->_morph2($f);
    map{$self->_morph($_)}@{$f->nodes || []};
    return $f;
}
sub _morph2 {
    my $self = shift;
    my $f = shift;
    my $class = ref($self);
    map{
        my $sec = $_;
        my $sseq = $sec->sseq;
        if ($sseq && $sseq->isa("SOI::Feature")) {
            bless($sseq, $class);
        }
        bless($sec, $class);
    }@{$f->secondary_nodes || []};
}

sub make_panel {
    my $self = shift;
    my $options = shift;

    my $feature = $self->feature;
    confess("no feature set and nothing to make from") unless ($feature);

    my ($contig) = grep{$_->type =~ /contig/}@{$feature->nodes || []};
    unless ($contig) {#not mini-view arm feature
        $contig = SOI::Feature->new
          ({name=>'fake',src_seq=>$feature->src_seq,fmin=>$feature->fmin,fmax=>$feature->fmax,strand=>1});
        $self->_morph($contig);
        $feature->transform($contig);
    }
    my $line = SOI::Feature->new({src=>$contig->src_seq,fmin=>0,fmax=>$contig->length,strand=>1});
    $self->_morph($line);

    my $len = $line->length;

    my %keyed_h = ();
    my $panel =
      Bio::Graphics::Panel->new
          (
           -offset => $options->{offset} || 0,
           -length=>$len,
           -width  => $options->{width} || 1000,
           -pad_left  => $options->{pad_left} || 50,
           -pad_right  => $options->{pad_right} || 50,
           -key_style  => $options->{key_style},
          );

    my @all_trs = ();
    foreach my $gene (grep{$_->type eq 'gene'}@{$feature->nodes || []}) {
        my @trs = @{$gene->nodes || []}; #all immediate children of gene
        push(@all_trs, @trs);
    }

    my @tes = ();
    @all_trs = 
      grep {
          if ($_->type eq 'transposable_element') {
              push(@tes, $_);
              0;
          }
          else {
              1;
          }
      } @all_trs;

    unless (@all_trs) {#not mini-view feature?
        push @all_trs, grep{$_}@{$feature->nodes || []};
    }

    my @analyses = grep{$_->type eq 'companalysis'}@{$feature->nodes || []};


    ####################################### TO DO #####################################
    #   analysis glyph type and color need more work, better default and optionally set
    #   and group analysis by type?
    ###################################################################################

    my %an_color = ();
    my @color_names = ();
    map {
        push @color_names, $_
          if $_ ne 'yellow' && $_ ne 'steelblue'
            && $_ ne 'white' && $_ ne 'darkred'
              && $_ ne 'honeydew' && $_ ne 'red'
          }$panel->color_names;
    $an_color{'clonelocator:scaffoldBACs'} = 'honeydew';
    $an_color{'clonelocator:BACs'} = 'honeydew';
    $an_color{'tilingpath BAC'} = 'magenta'; # 'pink'; #'honeydew';
    $an_color{'P Insertion'} = 'darkturquoise'; # 'turquoise'; #'red';
    $an_color{'cDNA'} = 'mediumseagreen'; #'green';
    $an_color{'Your BLAST hit'} = 'darkred';
    $an_color{'Repeat'} = 'purple';

    my $track = 0;
    my $middle_track;
    foreach my $strand (+1, -1) {
        my $meth = "unshift_track";
        if ($strand == 1) {
            $meth = "unshift_track";
        }
        $meth = "add_track";
        if ($strand == -1) {
            # Add the scale in the middle using the "arrow" glyph
            $panel->$meth(arrow => [$line],
                          -bump => 0,
                          -tick=>1);#1->major tick, 2->major + minor ticks

            $middle_track = $track;
            $track++;
        }
        # draw analyses
        my $an_height = $options->{analysis_height} || 12;
        foreach my $analysis (@analyses) {
            my $ap = $analysis->program . ":" . $analysis->sourcename;
            my %uniquetypes =
              map {s/_/ /g;$_=>1}($analysis->get_property("type"));
            #$ap = join(" ",grep {$_} keys %uniquetypes) || $ap;

            my $an_type = $ap;
            my $color = $an_color{$an_type};

            ## hard-coded color designations for evidence

            # blast
            if (lc($analysis->program) =~ /blastx/) {
                $color = 'darkorange';
            }
            if (lc($analysis->program) =~ /sptr/) {
                $color = 'darkorange';
            }

            # cDNA, DGC
            if (lc($analysis->sourcename) =~ /na_dgc/) {
                $color = 'mediumseagreen';
            }
            if (lc($analysis->sourcename) =~ /na_cdna/) {
                $color = 'green';
            }
            if (lc($analysis->sourcename) =~ /na_users/) {
                $color = 'green';
            }
            if (lc($analysis->database) =~ /na_gb/) {
                $color = 'green';
            }

            # tiling BACs
            if (lc($analysis->sourcename) =~ /bac/) {
                $color = 'lightslategray';
            }
            if (lc($analysis->sourcename) =~ /clone/) {
                $color = 'lightslategray';
            }
            if (lc($analysis->sourcename) =~ /all_nr/) {
                $color = 'black';
            }

            # P elements
            if (lc($analysis->sourcename) =~ /na_pe.dros/) {
                $color = 'darkturquoise';
            }

            # ESTs
            if (lc($analysis->database) =~ /est/) {
                $color = 'mediumaquamarine';
            }

            # gene prediction
            if (lc($analysis->program) =~ /genscan/) {
                $color = 'lightskyblue';
            }
            if (lc($analysis->program) =~ /genie/) {
                $color = 'lightskyblue';
            }
            if (lc($analysis->program) =~ /trnascan/) {
                $color = 'lightskyblue';
            }

            # affy oligo
            if (lc($analysis->database) =~ /na_affy_oligo.dros/) {
                $color = 'crimson';
            }

            if ($options->{colormap}) {
                my $cmap = $options->{colormap};
                my $c = $cmap->{$analysis->program .':'. $analysis->sourcename};
                if (!$c) {
                    $c = $cmap->{$analysis->sourcename};
                }
                if (!$c) {
                    $c = $cmap->{$analysis->program};
                }
                if ($c) {
                    $color = $c;
                }
            }

            my @rsets = @{$analysis->nodes || []};
            my ($bump, $labelling) = (0, 0);
            if (defined($options->{bump_analyses})) {
                $bump = $options->{bump_analyses};
            }
            $labelling = ($an_type =~ /scaffold bac/i) ? 0
              : ($options->{label_analyses} || 0);
            if ($analysis->program eq "assembly" ||
                $analysis->program eq "gulliver") {
                $bump = 1;
                $labelling = 
                  defined($options->{label_assembly}) ? 
                    $options->{label_assembly} : 1;
            }
            my @todraw = grep {$_->strand == $strand} @rsets;

            my $max = $options->{max_results_per_tier};
            if (defined($max) && 
                @rsets > $max) {
                $bump = 0;
                $an_type .= " (too many results - tier collapsed)";
            }
            if (@todraw) {
                $panel->$meth([@todraw]
                              =>$self->glyph_type($analysis),
                              -bgcolor =>  $color,
                              -fillcolor=> $color,
                              -fgcolor   =>  'black',
                              -bump      => $bump,
                              -key => ($keyed_h{$an_type} ? '' : $an_type),
                              -height    => $an_height,
                              -label     => $labelling
                             );
                $keyed_h{$an_type}++;
                $track++;
            }
        }
        # draw genes: actually transcript
        my $gene_height = $options->{gene_height} || 10;
        my @trs = grep {$_->strand == $strand} @all_trs;
        if (@trs) {
            $panel->$meth([@trs]
                          =>'transcript',
                          -fillcolor => 'blue',
                          -bgcolor   => 'blue',
                          -fgcolor   =>  'black',
                          -bump      =>  1,
                          -key =>  ($keyed_h{annotation} ? '' : 'annotation'),
                          -mark_cds => 1,
                          -height    => $gene_height,
                          -label     => $options->{label_annotations} || 1,
                         );
            $keyed_h{annotation}++;
            $track++;
        }
        if (@tes) {
            $panel->$meth([grep {$_->strand == $strand} @tes] 
                          =>'transcript',
                          -fillcolor => 'red',
                          -bgcolor   => 'red',
                          -fgcolor   =>  'black',
                          -bump      =>  1,
                          -key => ($keyed_h{te} ? '' : 'transposable element'),
                          -mark_cds => 1,
                          -height    => $gene_height,
                          -label     => $options->{label_annotations} || 1,
                         );
            $keyed_h{te}++;
            $track++;
        }
        # draw overlapping segments
        my @segs = grep{$_->type eq 'golden_path_scaffold'}@{$feature->nodes || []};
        if (@segs) {
            $panel->$meth([grep {$_->strand == $strand} @segs]=>'arrow',
                          -fillcolor => 'yellow',
                          -bgcolor => 'yellow',
                          -fgcolor =>   'black',
                          -bump =>      1,
                          -key =>       ($keyed_h{segment} ? '' : 'segment'),
                          -height =>    10,
                          -label =>     defined($options->{label_segments}) ? $options->{label_segments} : 1,
                         );
            $keyed_h{segment}++;
            $track++;
        }
    }
    # Panel object has no concept of being seperated into
    # 2 strands; lets do a vertical reverse on the negative strand
    my @rev = splice(@{$panel->{tracks}}, $middle_track+1);
    push(@{$panel->{tracks}}, reverse @rev);

    # imagemap
    my $map = "";
    my @boxes = $panel->boxes;
    foreach my $box (@boxes) {
        my $f = shift @$box;
        my $coords = join(" ", @$box);
        my $alt_text = scalar(@{$f->secondary_locations || []}) ? $f->secondary_loc->src : $f->name;
        $alt_text =~ s/[\"\']//g;
        my $href = $f->{url} || "#";
	
        $map .= 
          qq[<area shape="rect"
	     coords="$coords" 
	     href=$href
	     onmouseover='window.status = "$alt_text"; return true;'
	     onmouseexit='window.status = ""; return true;'>
	    ];
    }
    $panel->{maptext} = $map;

    return $panel;
}

sub glyph_type {
    my $self = shift;
    my $an = shift;
    if (grep{lc($an->program) =~ /$_/i}('blastn', 'pinsertion') and
        !$an->sourcename) {
        return 'pinsertion';
    } elsif (lc($an->program) eq 'blastn' &&
             lc($an->sourcename) eq 'na_pe.dros') {
        return 'pinsertion';
    } elsif (lc($an->program) eq "clonelocator") {
        return 'arrow';
    } elsif ($an->sourcename =~ /(dgc|cdna|est)/i) {
        return "bdgp_ests";
    } else {
        return 'segments';
    }
}


#conform to Bio::FeatureI or Gadfly API for drawing
sub seq_id {return shift->src}
sub display_name {
    my $self = shift;
    return $self->name || $self->uniquename;
}
#only for drawing, mixed type and one of them span whole parent range?
sub sub_SeqFeature {
    return grep{$_->type !~ 'protein' && $_->type !~ 'polypeptide'
                  && $_->type !~ /cds/i && $_->type !~ /intron/i
              }@{shift->nodes || []};
}
sub homol_sf {
    my $self = shift;
    if (@{$self->secondary_nodes || []}) {
        #check rank?
        my $homol = $self->secondary_nodes->[0];
        $homol->src_seq(SOI::Feature->new({name=>$homol->src_seq}));
        return $homol;
    }
}
sub start_codon {
    my $self = shift;

    my ($sc) = grep{$_->type eq 'start_codon'}@{$self->nodes || []};
    unless ($sc) {
        my ($p)= grep{$_->type =~ /protein/i or $_->type =~ /polypeptdie/}@{$self->nodes || []};
        return unless ($p);
        #no junction in start/stop codon?
        my $fmin = ($p->strand > 0)?$p->fmin:$p->fmax;
        $sc = SOI::Feature->new({src_seq=>$p->src_seq,fmin=>$fmin,fmax=>$fmin+3,strand=>$p->strand});
    }
    $sc->_setup_coord;
    $self->_morph($sc);
    return $sc;
}
sub stop_codon {
    my $self = shift;

    my ($sc) = grep{$_->type eq 'stop_codon'}@{$self->nodes || []};
    unless ($sc) {
        my ($p)= grep{$_->type =~ /protein/i or $_->type =~ /polypeptdie/}@{$self->nodes || []};
        return unless ($p);
        #no junction in start/stop codon? and protein feature end at stop codon start?
        my $fmin = ($p->strand > 0)?$p->fmax:$p->fmin;
        $sc = SOI::Feature->new({src_seq=>$p->src_seq,fmin=>$fmin,fmax=>$fmin+3,strand=>$p->strand});
    }
    $sc->_setup_coord;
    $self->_morph($sc);
    return $sc;
}
sub stop {shift->end}

1;
