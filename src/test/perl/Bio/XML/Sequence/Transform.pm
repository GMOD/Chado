package Bio::XML::Sequence::Transform;

use XML::NestArray qw(:all);
use base XML::NestArray::NestArrayImpl;
use strict;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = bless [], $class;
    return $self;
}

sub data {
    my $self = shift;
    my $data = shift || [];
    @$self = @$data;
}

sub next_dbxref {
    my $tree = shift;
    my ($last_dbxref) = findSubTree($tree, "last_dbxref");
    if (!$last_dbxref) {
        $last_dbxref = 0;
    }
    $last_dbxref++;
    setSubTreeVal($tree, "last_dbxref", $last_dbxref);
    return "TEMPID:$last_dbxref";
}

sub get_loc {
    my $tree = shift;
    my @features = @_;
    my @frs = findSubTree($tree, "feature_relationship");
    foreach my $feature (@features) {
        my ($dbxref) = findSubTreeVal($feature, "dbxref");
        my @subfeatures = ();
        map { 
            if (findSubTreeVal($_, "objfeature") eq ($dbxref) &&
                findSubTreeVal($_, "type") eq ("Part-Of")) {
                push(@subfeatures,
                     findSubTreeVal($_, "subjfeature"));
            }
          } @frs;
        # get actual features from dbxrefs
        @subfeatures =
          map {
              findSubTreeMatch($tree, "feature", "dbxref", $_);
          } @subfeatures;
        return unless @subfeatures;

        my $minmin;
        my $maxmax;
        my $mainstrand;
        my $mainsrc;
        foreach my $subfeature (@subfeatures) {
            my ($fmin, $fmax, $fstrand, $source_feature) =
              findSubTreeValList($subfeature, qw(fmin fmax fstrand source_feature));
            if (!$source_feature ||
                !defined($fmin) ||
                !defined($fmax) ||
                !defined($fstrand)) {
                get_loc($tree, $subfeature);
                ($fmin, $fmax, $fstrand, $source_feature) =
                  findSubTreeValList($subfeature, qw(fmin fmax fstrand source_feature));
            }
            $minmin = $fmin if !defined($minmin) || $fmin < $minmin;
            $maxmax = $fmax if !defined($maxmax) || $fmax > $maxmax;
            $mainstrand = $fstrand;
            $mainsrc = $source_feature;
        }
        setSubTreeVal($feature, "fmin", $minmin);
        setSubTreeVal($feature, "fmax", $maxmax);
        setSubTreeVal($feature, "fstrand", $mainstrand);
        setSubTreeVal($feature, "source_feature", $mainsrc);
    }
}

sub mk_all {
    my $tree = shift;
    my @features = @_;

    my @frs = findSubTree($tree, "feature_relationship");
    my @nu_tree = ();
    my ($fset) = findSubTree($tree, "fset");
    my ($frset) = findSubTree($tree, "feature_relationship_set");
    foreach my $feature (@features) {
        my ($dbxref) = findSubTreeVal($feature, "dbxref");
        my ($ftype) = findSubTreeVal($feature, "ftype");
        my @subjfeatures = get_subjfeatures($tree, "", $feature);
        map {
            mk_all($tree, $_);
        } @subjfeatures;
        if ($ftype eq "transcript") {
            my @subjfeatures = get_subjfeatures($tree, "Part-Of", $feature);
            my @exons = grep { findSubTreeVal($_, "ftype") eq ("exon") } @subjfeatures;
            my @ss = map { findSubTreeValList($_, "fmin", "fmax") } @exons;
            pop @ss;
            shift @ss;
            my @introns = ();
            while(@ss) {
                my $istart = shift @ss;
                my $iend = shift @ss;
                # todo: strand
                push(@introns,
                     [feature=>[
                                [dbxref=>next_dbxref($tree)],
                                [fmin=>$istart],
                                [fmax=>$iend],
                                [ftype=>"intron"],
                               ]
                     ]);
            }
            map {addChildTree($fset, $_)} @introns;
            map {
                my ($idbxref) = findSubTreeVal($_, "dbxref");
                addChildTree($frset, [feature_relationship=>[
                                                             [subjfeature=>$idbxref],
                                                             [objfeature=>$dbxref],
                                                             [type=>"Part-Of"],
                                                            ]
                                     ])
            } @introns;
        }
    }
}

# requires: exon, CDS
sub implicit_utr_exon_from_transcript {
    my $tree = shift;
    my $transcript = shift;
    my @exons = exonsByTranscript($tree, $transcript);
    # possibly >1 CDS - eg polycistronics
    my @utrs = implicit_utr_from_transcript($tree, $transcript);
    my @utr_exons =
      map {
          implicit_shadow_exon_from_transcript($tree,
                                               $transcript, 
                                               $_)
      } @utrs;
    return @utr_exons;
}

# requires: exon, CDS
sub implicit_shadow_exon_from_transcript {
    my $tree = shift;
    my $transcript = shift;
    my $subtranscript = shift;

    my @exons = exonsByTranscript($tree, $transcript);
    # possibly >1 CDS - eg polycistronics

    my ($tstart, $tend, $tstrand, $ttype) =
      findSubTreeValList($subtranscript,
                         "fmin", "fmax", "fstrand", "ftype");

    # eg utr_exon, cds_exon
    my $ftype = $ttype . "_exon";
    my @subexons = ();
    for (my $i=0; $i<@exons; $i++) {
        my $exon = $exons[$i];
        my ($xstart, $xend, $xstrand) =
          findSubTreeValList($exon, "fmin", "fmax", "fstrand");
        if (($xend - $tstart) * $tstrand < 0) {
            next;
        }
        if (($xstart - $tend) * $tstrand < 0) {
            last;
        }
        if (($xstart - $tstart) * $tstrand < 0) {
            $xstart = $tstart;
        }
        if (($xend - $tend) * $tstrand < 0) {
            $xend = $tend;
        }
        push(@subexons,
             [feature=>[
                        [dbxref=>next_dbxref($tree)],
                        [fmin=>$xstart],
                        [fmax=>$xend],
                        [fstrand=>$tstrand],
                        [ftype=>$ftype],
                       ]
             ]);
    }    
    return @subexons;
}

# requires: CDS
sub implicit_utr_from_transcript {
    my $tree = shift;
    my $transcript = shift;

    # possibly >1 CDS - eg polycistronics
#    my @cdss = sortFeatureByPos(cdsByTranscript($tree, $transcript));
    my @cdss = cdsByTranscript($tree, $transcript);
    if (!@cdss) {
        # no CDS implies no UTR
        return;
    }

    my ($tstrand) = findSubTreeVal($transcript, "fstrand");
    my @posns = 
      map { findSubTreeValList($_, "fmin", "fmax") } @cdss;
    my @utrs = ();
    @posns =
      (
       findSubTreeVal($transcript, "fmin"),
       @posns,
       findSubTreeVal($transcript, "fmax"),
      );
    my $ftype = "utr_5";
    while (@posns) {
        my $s = shift @posns;
        my $e = shift @posns;
        push(@utrs,
             [feature=>[
                        [dbxref=>next_dbxref($tree)],
                        [fmin=>$s],
                        [fmax=>$e],
                        [fstrand=>$tstrand],
                        [ftype=>$ftype],
                       ]
             ]
            )
          unless $s==$e; # leave out zero-length UTR

        # dicistronic can have internal utr
        $ftype = scalar(@posns) > 2 ? "utr_internal" : "utr_3";
    }
    return @utrs;
}

sub dupl {
    my $elt = shift;
    
}

# requires: exon
sub implicit_intron_from_transcript {
    my $tree = shift;
    my $transcript = shift;
    my @exons = exonsByTranscript($tree, $transcript);
    my @introns = ();
    for (my $i=1; $i<@exons; $i++) {
        my $e1 = $exons[$i-1];
        my $e2 = $exons[$i];
        my $istart = findSubTreeVal($e1, "fmax");
        my $iend = findSubTreeVal($e2, "fmin");
        my $intron =
          [feature=>[
                     [dbxref=>next_dbxref($tree)],
                     [fmin=>$istart],
                     [fmax=>$iend],
                     [ftype=>"intron"],
                               ]
          ];
        push(@introns, $intron);
    }
    return @introns;
}

# requires: exon
sub implicit_splice_site_from_transcript {
    my $tree = shift;
    my $transcript = shift;
    my @exons = exonsByTranscript($tree, $transcript);
    my @ss = ();
    my $strand;
    my @posns = 
      map { findSubTreeValList($_, "fmin", "fmax") } @exons;
    pop @posns;
    shift @posns;
    @ss =
      map {
          [feature=>[
                     [dbxref=>next_dbxref($tree)],
                     [fmin=>$_],
                     [fmax=>$_],
                     [fstrand=>$strand],
                     [ftype=>"splice_site"],
                    ]
          ];
      } @posns;
    return @ss;
}

# requires: splice_site
sub implicit_exon_from_transcript {
    my $tree = shift;
    my $transcript = shift;
}

# requires: exon, start_codon
sub implicit_cds_from_transcript {
    my $tree = shift;
    my $transcript = shift;
}

# requires: exon, CDS
sub implicit_start_codon_from_transcript {
    my $tree = shift;
    my $transcript = shift;
}

# ---

sub exonsByTranscript {
    my $tree = shift;
    my $transcript = shift;
    my @subj = get_subjfeatures($tree, "Part-Of", $transcript);
    my @exons = grep {isaExon($tree, $_)} @subj;
    return @exons;
}

sub cdsByTranscript {
    my $tree = shift;
    my $transcript = shift;
    my @subj = get_subjfeatures($tree, "Coded-By", $transcript);
    my @cdss = grep {isaCds($tree, $_)} @subj;
    return @cdss;
}

# --

sub sortFeatureByPos {
    my @fs = @_;
    my @sa = map {[$_->sget_fmin, $_]} @fs;
    @sa = sort {$a->[0] <=> $b->[0]} @sa;
    return map {$_->[1]} @sa;
}

# --

sub isaExon {
    my $tree = shift;
    my $f = shift;
    isaTypeOf($tree, $f, "exon");
}

sub isaCds {
    my $tree = shift;
    my $f = shift;
    isaTypeOf($tree, $f, "cds");
}

sub isaTypeOf {
    my $tree = shift;
    my $f = shift;
    my $check_type = shift;
    my ($ftype) = $f->get_ftype;
    # use SO grap here
    return lc($ftype) eq lc($check_type);
}


# TRANSFORMATIONS
# (1) implicit types - eg UTR from CDS, UTR_exon from exon and CDS
#     [both adding and removing]
#     dicistronic, most_3_prime, inside_intron
# (2) implicit coordinates - eg gene coords from tr coors; tr from exon
# (3) coordinate mapping
#       - between assemblies
#       - between systems (eg SNPs onto proteins)
#       - CDS coords relative to transcript vs relative to genome
# (4) implicit sequence
#    (4.1) feature subsequence
#    (4.2) transcript subsequence (spliced)
#    (4.3) protein sequence
# (5) domain/site specific e.g. Bio::FlyBase::Rules
#    (5.1) dealing with deleted features/genes
#    (5.2) naming rules
#    (5.3) dbxref assigning rules (eg gene/new11111 =>FBgn00001111)
# (6) reports (html?)
# (7) app-specific
#    (7.1) eg nesting graphs as xml trees
# (8) cacheing
#     eg gene counts per att-val eg GO
# (9) more complex - application specific
#     eg autopromoting - synthesising features into other features
# (10) validation - either against xml-schema/dtd OR against
#      a semantically richer model (eg check everything has dbxref)
#
# note: no language lock-in; all transformations are xml/tree transforms
# some could be in xslt, some in java, some in database

# cache transformations in index?

# DEPENDENCIES
# cds_exon < tr, cds, exon
# utr_exon < tr, utr, exon
# xxx_exon < tr, xxx, exon
# utr      < tr, cds                ! 5_utr, 3_utr, internal_utr
# intron   < tr, exon
# splsite  < tr, exon
# promoter < tr, exon
# polyasite< tr, exon

# ?
# most_5_exon < tr, exon
# most_3_exon < tr, exon

sub mk_rules {
    my $tree = shift;
#    my %rules =
#      (
#       intron=>forall( 
#                      \&isaTranscript,
#                      sub {
#                          my $transcript = shift;
#                          exonsForTranscript(
#                                         }
#                     ),
#       utr   =>forall( 
#                      \&isaTranscript,
#                      sub {
#                      }
#                     ),
#      );
}

sub get_subjfeatures {
    my $tree = shift;
    my $rtype = shift;
    my @features = @_;

    my @frs = findSubTree($tree, "feature_relationship");
    my @subfeatures = ();
    foreach my $feature (@features) {
        my ($dbxref) = findSubTreeVal($feature, "dbxref");
        map { 
            if (findSubTreeVal($_, "objfeature") eq ($dbxref) &&
                (!$rtype || findSubTreeVal($_, "type") eq ($rtype))) {
                push(@subfeatures,
                     findSubTreeVal($_, "subjfeature"));
            }
          } @frs;
        # get actual features from dbxrefs
        @subfeatures =
          map {
              findSubTreeMatch($tree, "feature", "dbxref", $_);
          } @subfeatures;
    }
    return @subfeatures;
}

sub tf_gene {
    my $tree = shift;
    my $gene = shift;
    my ($dbxref) = $gene->get_dbxref;
    my @features = findSubTree($tree, "feature");
    @features =
      grep {
          my @gtf = findSubTree($_, "gene_to_feature");
          grep { findSubTreeVal($_, "gene") eq ($dbxref) } @gtf;
      } @features;
    @features = tf_features($tree, @features);
    return 
      [
       gene=>[$gene->children,
              [gene_features=>[
                               @features
                              ]
              ]
             ]
      ];
}

sub tf_features {
    my $tree = shift;
    my @features = @_;

    my @frs = findSubTree($tree, "feature_relationship");
    my @nu_tree = ();
    foreach my $feature (@features) {
        my ($dbxref) = findSubTreeVal($feature, "dbxref");
        my ($ftype) = findSubTreeVal($feature, "ftype");

        my @subfeatures = ();
        my @subelts = ();
        map { 
            if (findSubTreeVal($_, "objfeature") eq ($dbxref)) {
                my ($rtype) = findSubTreeVal($_, "type");
                my ($subjfeature) = 
                  findSubTreeMatch($tree, "feature", "dbxref",
                                   findSubTreeVal($_, "subjfeature"));
                
                my $subtree =
                  ["has-$rtype"=>
                                  [tf_features($tree, $subjfeature)]

                    
                  ];
                push(@subelts, $subtree);
            }
        } @frs;
        push(@nu_tree,
             [$ftype=>[
                       @{$feature->[1]},
                       @subelts,
                      ],
             ]);
    }
    return @nu_tree;
    
}

sub game_feature_to_bf {
    my $feature_h = shift;
    my $game_f = shift;

    my $eltname = $game_f->name;
    my ($id) = findSubTreeVal($game_f, "$eltname-id");
    my ($produces_seq) = findSubTreeVal($game_f, "$eltname-produces_seq");
    my $dbxref = $produces_seq || $id;
    my $feature = Node(feature=>[]);
    if ($feature_h->{$dbxref}) {
        $feature = $feature_h->{$dbxref}
    }
    else {
        $feature_h->{$dbxref} = $feature;
    }
    $feature->set_dbxref($dbxref);
    $feature->set_ftype(findSubTreeVal($game_f, "type"));
    $feature->set_name(findSubTreeVal($game_f, "name"));
    $feature->set_fmin(findSubTreeVal($game_f, "start"));
    $feature->set_fmax(findSubTreeVal($game_f, "end"));
    $feature->set_fstrand($feature->sget_start < $feature->sget_end ? 1 : -1);
    return $feature;
}

sub new_frelset {
    my $frelset = shift;
    sub {
        my $meth = shift;
        
        my ($subj, $obj, $type) = @_;
        my $fr =
          [feature_relationship=>[
                                  [subjfeature=>$subj],
                                  [objfeature=>$obj],
                                  [type=>$type],
                                 ]
          ];
        $frelset->add_feature_relationship($fr);
    }
}

sub from_game {
    my $tree = shift;
    my $game = shift;
    
    my @gseqs = $game->fst("seq");
    my %feature_h = ();
    my @features =
      map {
           my ($id, $name, $res, $desc) =
             findSubTreeValList($_,
                                "seq-id",
                                "name",
                                "residues",
                                "description");
           my @xrefs = findSubTree($_, "dbxref");
           my $f =
             Node(
                   feature=>[
                             [dbxref=>$id],
                             [name=>$name],
                             [residues=>$res],
                            ]
                 );
           $feature_h{$id} = $f;
           $f;
      } @gseqs;
    my @frels = ();
    my @anns = $game->fst("annotation");
    foreach my $ann (@anns) {
        my $nu_ann = game_feature_to_bf(\%feature_h, $ann);
        my @fsets = $ann->fst("feature_set");
        foreach my $fset (@fsets) {
            my $nu_fset = game_feature_to_bf(\%feature_h, $fset);
            push(@frels, [$nu_fset, $nu_ann]);
            my @fspans = $ann->fst("feature_span");
            my @f =
              map {
                  my $nu_fspan = game_feature_to_bf(\%feature_h, $_);
                  if ($nu_fspan->sget_ftype eq "translate offset") {
                      my $orf =
                        Node(
                             feature=>[
                                       [dbxref=>next_dbxref($tree)],
                                       [fmin=>$nu_fspan->sget_fmin],
                                       # NOT CORRECT - need to map
                                       [fmax=>$nu_fset->sget_fmax],
                                       [fstrand=>$nu_fspan->sget_fstrand],
                                       [ftype=>"CDS"],
                                      ]
                            );
                      $feature_h{$orf->sget_dbxref} = $orf;
                      $nu_fspan->set_ftype("translation");
                      $nu_fspan->unset_fmin;
                      $nu_fspan->unset_fmax;
                      $nu_fspan->unset_fstrand;
                      push(@frels, 
                           [$nu_fspan, $orf, "Translated-From"],
                           [$orf, $nu_fset, "Coded-By"]);
                  }
                  else {
                      push(@frels, [$nu_fspan, $nu_fset]);
                      $nu_fspan;
                  }
              } @fspans;
        }
    }
    @frels =
      map {
          my ($sdbxref) = $_->[0]->get_dbxref;
          my ($odbxref) = $_->[1]->get_dbxref;
          my $type = $_->[2] || "Part-Of";
          [feature_relationship=>[
                                  [subjfeature=>$sdbxref],
                                  [objfeature=>$odbxref],
                                  [type=>$type],
                                 ]
          ]
      } @frels;
    $tree->set_frset([@frels]);
    $tree->set_fset([values %feature_h]);
    return $tree;
}

1;

