package SOI::Outputter;

=head1 NAME

SOI::Outputter

=head1 SYNOPSIS

=head1 USAGE

=cut

use Exporter;

use SOI::Feature;
use XML::Writer;
use IO;
use Carp;
use base qw(Exporter);
use vars qw($AUTOLOAD);

@EXPORT_OK = qw(chaos_xml soi_xml game_xml gff3);
%EXPORT_TAGS = (all=> [@EXPORT_OK]);

use strict;

=head1 FUNCTIONS

=cut


sub _out_params {
    return qw(relationship_type uniquename name symbol organism src_seq start end residues);
}
sub _analysis_params {
    return qw(description program programversion algorithm sourcename sourceversion sourceuri timeexecuted);
}
sub _chaos_hidden_params {
    return qw(analysis_id parent_id featureloc_id analysisfeature_id organism_id dbxref_id type_id nbeg nend start end fmin fmax depth timelastmodified timeaccessioned relationship_type locgroup);
}
#if not in the list, field value to property in gff3
sub _gff_hidden_prop_params {
   my @a1 = &_chaos_hidden_params;
   my @a2 = &_out_params;
   my %uniq;
   map{$uniq{$_}=1}(@a1, @a2, qw(srcfeature_id species genus is_analysis type strand rank phase feature_id seqlen orderrank md5checksum is_fmin_partial is_fmax_partial));
   return keys %uniq;
}
sub _soi_hidden_params {
    return (grep{$_ ne 'fmin' && $_ ne 'fmax' && $_ ne 'relationship_type'}(_chaos_hidden_params),
            qw(feature_id srcfeature_id type md5checksum));
}

sub chaos_xml {
    my $node = shift;
    my $output = shift;

    my $opath = $output;
    unless ($opath) {
        $opath ||= ">-"; #default to STDOUT
    }
    $output = new IO::File(">$opath") unless (ref($output));
    my $w = new XML::Writer(OUTPUT => $output, DATA_MODE => 1, DATA_INDENT => 2);
    if ($node->hash->{program}) {
        my $pt = 'property';
        my $t = "companalysis";
        $w->startTag($t);
        map{$w->dataElement($_,$node->hash->{$_}) if ($node->hash->{$_})}(_analysis_params);
        my @fp_params = qw(type value rank);
        map{
            $w->startTag($pt);
            my $h = $_;
            map{
                $w->dataElement($_, $h->{$_}) if (defined($h->{$_}));
            }@fp_params;
            $w->endTag($pt);
        }@{$node->properties || []};
        map{_chaos_xml($_, $output, $w)}@{$node->nodes || []};
        $w->endTag($t);
    } else {
        _chaos_xml($node, $output);
    }
}
sub _chaos_xml {
    my $node = shift;
    my $output = shift;
    my $w = shift;

    $w = new XML::Writer(OUTPUT => $output, DATA_MODE => 1, DATA_INDENT => 2) unless ($w);

    my $h = $node->hash;

    my ($ft, $flt, $fpt, $fxt, $frt, $fot) =
      ('feature', 'featureloc', 'featureprop', 'feature_dbxref', 'feature_relationship', 'feature_cvterm');

    my @loc_params =
      qw(srcfeature_id src_seq nbeg nend strand phase residue_info locgroup );

    $w->startTag($ft);
    foreach my $k (sort{$a cmp $b}keys %{$h || {}}) {
        next if (grep{$k eq $_}(_chaos_hidden_params, _analysis_params, @loc_params));
        my ($t,$v) = ($k,$h->{$k});
        $t = 'rank' if ($t eq 'orderrank');
        $w->dataElement($t, $v) if (defined $v);
    } keys %{$h || {}};

    if (scalar(@{$node->dbxrefs || []})) {
        $w->startTag($fxt);
        map{
            $w->dataElement('dbxrefstr',sprintf("%s:%s",$_->{dbname},$_->{accession}));
        }@{$node->dbxrefs || []};
        $w->endTag($fxt);
    }

    my @fp_params = qw(type value rank);
    map{
        $w->startTag($fpt);
        my $h = $_;
        map{
            $w->dataElement($_, $h->{$_});
        }@fp_params;
        $w->endTag($fpt);
    }@{$node->properties || []};

    $w->startTag($flt);
    $w->dataElement("srcfeature_id",$node->hash->{srcfeature_id});
    $w->dataElement('nbeg',$node->nbeg);
    $w->dataElement('nend',$node->nend);
    $w->dataElement('rank',$node->hash->{rank});
    $w->dataElement('locgroup',$node->hash->{locgroup});
    $w->dataElement('phase',$node->hash->{phase}) if (defined($node->hash->{phase}));
    $w->endTag($flt);
    foreach my $h (@{$node->secondary_locations || []}) {
        $w->startTag($flt);
        $w->dataElement("srcfeature_id",$h->{srcfeature_id});
        my ($nbeg, $nend) = ($h->{fmin},$h->{fmax});
        if ($h->{strand} < 0) {($nbeg,$nend) = ($nend,$nbeg)};
        $w->dataElement('nbeg',$nbeg);
        $w->dataElement('nend',$nend);
        $w->dataElement('strand',$h->{strand});
        $w->dataElement('rank',$h->{rank});
        $w->dataElement('locgroup',$h->{locgroup});
        $w->dataElement('phase',$h->{phase}) if (defined($h->{phase}));
        $w->endTag($flt);
    }

    if (scalar(@{$node->ontologies || []})) {
        $w->startTag($fot);
        map{
            $w->startTag('cvterm');
            $w->dataElement('name',$_->{name});
            $w->dataElement('dbxrefstr',sprintf("%s",$_->{accession}));
            $w->dataElement('cv', $_->{cv});
            $w->endTag('cvterm');
        }@{$node->ontologies || []};
        $w->endTag($fot);
    }

    $w->endTag($ft);

    #recreate writer to write relationship outside feature
    $w = new XML::Writer(OUTPUT => $output, DATA_MODE => 1, DATA_INDENT => 2);
    if ($node->hash->{parent_id}) {
        $w->startTag($frt);
        $w->dataElement('subject_id',$node->id);
        $w->dataElement('object_id', $node->hash->{parent_id});
        $w->dataElement('type',$node->hash->{relationship_type});
        $w->endTag($frt);
    }

    map{_chaos_xml($_, $output)}@{$node->nodes || []};
}
sub soi_xml {
    my $node = shift;
    my $output = shift;
    my $w = shift;

    my $opath = $output;
    unless ($opath) {
        $opath ||= ">-"; #default to STDOUT
    }
    $output = new IO::File(">$opath") unless (ref($output));
    undef $opath;
    my $h = $node->hash;
    $w = new XML::Writer(OUTPUT => $output, DATA_MODE => 1, DATA_INDENT => 2) unless ($w);

    $node->_setup_coord;
    $w->startTag($node->type);
    foreach my $k (sort{$a cmp $b}keys %{$h || {}}) {
        next if (grep{$k eq $_}(_soi_hidden_params));
        my ($t,$v) = ($k,$h->{$k});
        $t = 'rank' if ($t eq 'orderrank');
        if ($t eq 'residues' and $v) {
            $v =~ s/(.{50})/$1\n/g;
            chomp $v;
            $v .= "\n";
            $w->startTag('seq');
            my $md5 = 'md5checksum';
            $w->dataElement($md5,$h->{$md5}) if ($h->{$md5});
            $w->dataElement($t, $v) if (defined($v));
            $w->endTag('seq');
        } else {
            $w->dataElement($t, $v) if (defined($v));
        }
    }
    foreach my $h (@{$node->secondary_locations || []}) {
        $w->startTag("secondary_location");
        $w->dataElement("src_seq",$h->{src_seq});
        $w->dataElement('fmin',$h->{fmin});
        $w->dataElement('fmax',$h->{fmax});
        $w->dataElement('strand',$h->{strand});
        $w->dataElement('rank',$h->{rank}) if (defined($h->{rank}));
        $w->dataElement('locgroup',$h->{locgroup}) if (defined($h->{locgroup}));
        $w->dataElement('phase',$h->{phase}) if (defined($h->{phase}));
#subject seq data is hidden in soi and chaos?!!
#        my $subj_seq = $h->{seq};
#        if ($subj_seq) {
#            foreach my $k (qw(seqlen)) {
#                my $t = "src_seq_$k";
#                my $v = $subj_seq->{$k};
#                $w->dataElement($t, $v) if (defined($v));
#            }
#        }
        $w->endTag("secondary_location");
    }

    my ($dbxt, $pt, $cvt) = qw(dbxref property cvterm);
    map{
        $w->startTag($dbxt);
        $w->dataElement($_->{dbname}, $_->{accession});
        $w->endTag($dbxt);
    }@{$node->dbxrefs || []};
    map{
        $w->startTag($pt);
        $w->dataElement($_->{type}, $_->{value});
        $w->endTag($pt);
    }@{$node->properties || []};
    map{
        $w->startTag($cvt);
        $w->startTag($_->{cv});
        $w->dataElement('name',$_->{name});
        $w->dataElement('dbxrefstr',$_->{accession});
        $w->endTag($_->{cv});
        $w->endTag($cvt);
    }@{$node->ontologies || []};
    map{
        $w->startTag('comment');
        my $h = $_;
        map{$w->dataElement($_,$h->{$_})}keys %{$h};
        $w->endTag('comment');
    }@{$node->comments || []};
    map{soi_xml($_, $output, $w)}@{$node->nodes || []};
    $w->endTag($node->type);
}

sub game_xml {
    my $node = shift;
    my $output = shift;
    my $w = shift;

    my $opath = $output;
    unless ($opath) {
        $opath ||= ">-"; #default to STDOUT
    }
    $output = new IO::File(">$opath") unless (ref($output));
    undef $opath;
    my $h = $node->hash;
    $w = new XML::Writer(OUTPUT => $output, DATA_MODE => 1, DATA_INDENT => 2) unless ($w);

    $w->startTag('game', version=>'1.2');
    my ($g_node, @an_nodes, @o_nodes);
    foreach my $c (@{$node->nodes || []}) {
        if ($c->hash->{type} eq 'contig') {
            $g_node = $c;
        }
        elsif ($c->hash->{type} eq 'companalysis' || $c->hash->{program}) {
            push @an_nodes, $c;
        } else {
            push @o_nodes, $c;
        }
    }
    my %sec_seq_h;
    foreach my $an (@an_nodes) {
        foreach my $rset (@{$an->nodes || []}) {
            foreach my $span (@{$rset->nodes || []}) {
                foreach my $loc (@{$span->secondary_nodes || []}) {
                    my $seq_h = $loc->seq ? $loc->seq->hash : "";
                    $sec_seq_h{$seq_h->{feature_id} || $seq_h->{name}} = $seq_h if ($seq_h);
                }
            }
        }
    }
    _genomic_seq_game_xml($g_node, $w, $node->name);
    _subject_seq_game_xml([values %sec_seq_h], $w);
    map{_game_xml($_, $w)}(@o_nodes);
    map{_an_game_xml($_, $w)}(@an_nodes);
    $w->endTag('game');
}

sub _genomic_seq_game_xml {
    my $node = shift || return;
    my $w = shift; #XML writer
    my $arm = shift;

    $node->_setup_coord;
    $w->startTag('seq', id=>$node->uniquename, length=>$node->seqlen || $node->length, focus=>'true');
    $w->dataElement('name', $node->name);
    my $residues = $node->hash->{residues} || "";
    $residues =~ s/(.{50})/$1\n/g;
    chomp $residues;
    $residues = "\n$residues\n";
    $w->dataElement('residues', $residues);
    $w->endTag('seq');
    $w->startTag('map_position',type=>'tile',seq=>$node->name);
    $w->dataElement('arm', $arm);
    $w->startTag('span');
    map{my $m=$_;$w->dataElement($m,$node->$m)}qw(start end);
    $w->endTag('span');
    $w->endTag('map_position');
}
sub _subject_seq_game_xml {
    my $seqs = shift || return;
    my $w = shift; #XML writer

    foreach my $seq_h (@{$seqs || []}) {
        $w->startTag('seq', id=>$seq_h->{uniquename}, length=>$seq_h->{seqlen});
        $w->dataElement('name', $seq_h->{name});
        my $residues = $seq_h->{residues} || "";
        $residues =~ s/(.{50})/$1\n/g;
        chomp $residues;
        $residues = "\n$residues\n";
        $w->dataElement('residues', $residues);
        $w->endTag('seq');
    }
}
sub _game_xml {
    my $node = shift || return;
    my $w = shift;

    my @SO_game_fset = qw(mRNA pseudogene tRNA snRNA snoRNA rRNA ncRNA transcript);
    my @non_gene = qw(transposable_element remark); #only has top level

    my @so_polypep = qw(protein polypeptide);
    my %game_type_map =
      ('gene' => 'annotation',
       'transposable_element' => 'annotation',
       'remark' => 'annotation',
       'exon' => 'feature_span',
       protein => 'feature_span',
       polypeptide => 'feature_span',
      );

    $node->_setup_coord;
    my $h = $node->hash;

    #ok, treat transcript's protein node specially (output it in tr level)
    return if (grep{$node->type eq $_}@so_polypep);

    my $game_t = $game_type_map{$node->type}
      || ((grep{$_ eq $node->type}@SO_game_fset) ? 'feature_set' : $node->type);
    if ($game_t =~ /_set/) {
        $w->startTag($game_t, id=>$node->uniquename, produces_seq=>$node->uniquename);
    }
    else {
        $w->startTag($game_t, id=>$node->uniquename);
    }

    my $prot_node;
    #hard coded protein-producing feature!!!
    if (grep{$node->type eq $_}qw(mRNA transcript)) {
        foreach my $n (@{$node->nodes || []}) {
            if (grep{$n->type eq $_}@so_polypep) {
                $prot_node = $n;
                last;
            }
        }
    }
    #main attr
    $w->dataElement('name',$node->name);
    $w->dataElement('uniquename',$node->uniquename) if ($node->name && $game_t eq 'annotation');
    my $v = $node->type;$v='transcript' if ($v eq 'mRNA');
    if ($game_t eq 'annotation') {
        $v = $node->nodes->[0]->type if (@{$node->nodes || []});
        $v = $node->type if (grep{$v eq $_}qw(mRNA transcript));
    }
    $w->dataElement('type',$v);

    if ($game_t eq 'annotation') {
        $w->startTag('gene', association=>'IS');
        $w->dataElement('name', $node->name);
        $w->endTag('gene');
        unless (scalar(@{$node->nodes || []})) {
            #manufacture tr
            my $h;
            map{$h->{$_} = $node->hash->{$_}}keys %{$node->hash};
            $h->{parent_id} = $node->id;
            $h->{feature_id} = $node->id.":1";
            $h->{depth} = $node->depth + 1;
            $h->{type} = 'transcript';
            my $n = SOI::Feature->new($h);
            $node->add_node($n);
        }
    }
    if ($game_t =~ /_set/) {
        unless (@{$node->nodes || []}) {
            #manufacture span
            my $h;
            map{$h->{$_} = $node->hash->{$_}}keys %{$node->hash};
            $h->{parent_id} = $node->id;
            $h->{feature_id} = $node->id.":2";
            $h->{depth} = $node->depth + 1;
            $h->{type} = 'exon';
            my $n = SOI::Feature->new($h);
            $node->add_node($n);
        }
    }
    #primary loc, apollo can handle seq_relationship in annotation/feature_set but won't draw feature without span
    if ($game_t =~ /_span/) {
        $w->startTag('seq_relationship', type=>'query',seq=>$node->src_seq);
        $w->startTag('span');
        map{my $m=$_;$w->dataElement($m,$node->$m)}qw(start end);
        $w->endTag('span');
        $w->endTag('seq_relationship');
    }
    #only analysis result has secondary loc??
    foreach my $h (@{$node->secondary_locations || []}) {
        $w->startTag('seq_relationship', type=>'subject',seq=>$h->{src_seq});
        $w->startTag('span');
        map{my $m=$_;$w->dataElement($m,$h->{$m})}qw(start end);
        $w->endTag('span');
        $w->endTag('seq_relationship');
    }

    my ($dbxt, $pt, $cvt) = qw(dbxref property aspect);
    map{
        $w->startTag($pt);
        $w->dataElement('type',$_->{type});
        $w->dataElement('valule', $_->{value});
        $w->endTag($pt);
    }@{$node->properties || []};
    map{
        $w->startTag($dbxt);
        $w->dataElement('xref_db',$_->{dbname});
        $w->dataElement('db_xref_id',$_->{accession});
        $w->endTag($dbxt);
    }@{$node->dbxrefs || []};
    map{
        $w->startTag('comment');
        my $h = $_;
        map{$w->dataElement($_,$h->{$_})}keys %{$h};
        $w->endTag('comment');
    }@{$node->comments || []};

    map{
        my $h = $_;
        $w->startTag($cvt);
        $w->startTag('dbxref');
        $w->dataElement('xref_db',$h->{dbname});
        $w->dataElement('db_xref_id',$h->{accession});
        $w->endTag('dbxref');
        if ($h->{cv} && $h->{name}) {
            $w->dataElement($h->{cv}, $h->{name});#coming from db
        } else { #coming from game xml
            my @others = grep{$_ ne 'dbname' && $_ ne 'accession'}keys %{$h || {}};
            map{
                $w->dataElement($_, $h->{$_});
            }@others;
        }
        $w->endTag($cvt);
    }@{$node->ontologies || []};

    if ($prot_node) {
        my $g_t = 'feature_span';
        my $id = $prot_node->feature_id || sprintf("%s:tmp%d",$prot_node->uniquename,time);
        $w->startTag($g_t, id=>$id,produces_seq=>$prot_node->uniquename);
        $w->dataElement('type','translate offset');
        $w->startTag('seq_relationship', type=>'query',seq=>$prot_node->src_seq);
        $w->startTag('span');
        my $b = $prot_node->start;
        my $e = $b + 2;
        if ($prot_node->strand < 0) {
            $e = $b - 2;
        }
        $w->dataElement('start', $b);
        $w->dataElement('end', $e);
        $w->endTag('span');
        $w->endTag('seq_relationship');
        $w->endTag($g_t);
    }
    #out child before seq (work only for tr
    map{_game_xml($_, $w)}@{$node->nodes || []};

    #sequence
    my @seq_nodes;
    push @seq_nodes, $node if ($node->hash->{residues});
    push @seq_nodes, $prot_node if ($prot_node);
    foreach my $n (@seq_nodes) {
        my $t = 'residues';
        my $v = $n->hash->{residues};
        my $type = (grep{$n->type eq $_}@so_polypep) ? "aa" : "cdna";
        $v =~ s/(.{50})/$1\n/g;
        chomp $v;
        $v = "\n$v\n";
        my $md5 = 'md5checksum';
        $w->startTag('seq',id=>$n->uniquename,length=>$n->seqlen,type=>$type,md5checksum=>$n->$md5);
        $w->dataElement($t, $v);
        $w->endTag('seq');
    }
    #hmm so protein(polypeptide) can not out nest xml for children (see translate offset above)
    #already treat it specially, should not come down this far if protein node
    $w->endTag($game_t);
}
sub _an_game_xml {
    my $node = shift || return;
    my $w = shift;

    my @SO_game_fset = qw(match mRNA transposable_element);

    my %game_type_map =
      ('match_part' => 'result_span',
       'exon' => 'result_span',
      );

    $node->_setup_coord;
    my $h = $node->hash;


    my $game_t;
    if ($h->{type} eq 'companalysis' || $h->{program}) {
        $game_t = 'computational_analysis';
    } else {
        $game_t = $game_type_map{$node->type} || ((grep{$_ eq $node->type}@SO_game_fset) ? 'result_set' : "unknown_set");
    }
    if ($game_t =~ /_analysis/) {
        $w->startTag($game_t);
        $w->dataElement('program', $h->{program});
        $w->dataElement('database', $h->{sourcename}) if ($h->{sourcename});
    }
    elsif ($game_t =~ /_set/) {
        $w->startTag($game_t, id=>$node->uniquename);
        $w->dataElement('name',$node->name || $node->uniquename);
        unless (@{$node->nodes || []}) {
            #manufacture span
            my $h;
            map{$h->{$_} = $node->hash->{$_}}keys %{$node->hash};
            $h->{parent_id} = $node->id;
            $h->{depth} = $node->depth + 1;
            $h->{type} = 'match_part';
            my $n = SOI::Feature->new($h);
            $node->add_node($n);
        }
    }
    else {
        $w->startTag($game_t, id=>$node->uniquename);
    }


    #primary loc
    if ($game_t =~ /_span/) {
        foreach my $k (sort{$a cmp $b}keys %{$h || {}}) {
            next if (grep{$k eq $_}(_soi_hidden_params, qw(rank orderrank is_analysis strand fmin fmax is_fmin_partial is_fmax_partial src_seq seqlen start end residue_info relationship_type)));
            my ($t,$v) = ($k,$h->{$k});
            $t = 'rank' if ($t eq 'orderrank');
            $t = 'score' if ($t eq 'rawscore');
            $t = 'name' if ($t eq 'uniquename' && !$h->{name});
            $w->dataElement($t, $v) if (defined($v));
        }
        $w->startTag('seq_relationship', type=>'query',seq=>$node->src_seq);
        $w->startTag('span');
        map{my $m=$_;$w->dataElement($m,$node->$m)}qw(start end);
        $w->dataElement('alignment', $node->residue_info) if ($node->residue_info);
        $w->endTag('span');
        $w->endTag('seq_relationship');
    }
    #only analysis result has secondary loc??
    foreach my $h (@{$node->secondary_locations || []}) {
        $w->startTag('seq_relationship', type=>'subject',seq=>$h->{src_seq});
        $w->startTag('span');
        map{my $m=$_;$w->dataElement($m,$h->{$m})}qw(start end);
        $w->dataElement('alignment', $h->{residue_info}) if ($h->{residue_info});
        $w->endTag('span');
        $w->endTag('seq_relationship');
    }

    my ($dbxt, $pt, $cvt) = qw(dbxref property cvterm);
    $pt = 'output' if ($game_t =~ /_span/);
    map{
        $w->startTag($pt);
        $w->dataElement('type',$_->{type});
        $w->dataElement('value', $_->{value});
        $w->endTag($pt);
    }@{$node->properties || []};
    map{_an_game_xml($_, $w)}@{$node->nodes || []};

    $w->endTag($game_t);
}

sub gff3 {
    my $top = shift;
    my $fh = shift;
    my $opts = shift || {};

    my $opath = $fh;
    unless ($opath) {
        $opath ||= ">-"; #default to STDOUT
    }
    $fh = new IO::File(">$opath");

    require SOI::Visitor;
    SOI::Visitor->set_loc($top);
    &_gff3($top,$fh, $opts);
    printf $fh "###EOF\n" if ($opts->{EOF});
    $fh->close;
}

sub _gff3 {
    my $node = shift || return;
    my $fh = shift;
    my $opts = shift || {};
    my $parent_id = shift;

    my $fasta_out= $opts->{fasta};
    my $terminator_depth = $opts->{terminator_depth};

    #use node type as parent ID is a hack here!!!
    my $id = $node->uniquename || $node->id || $node->type;
    my @magic9 = ();
    push @magic9, sprintf("ID=%s", $id);
    push @magic9, sprintf("Name=%s", $node->name) if ($node->name);
    push @magic9, sprintf("Parent=%s", $parent_id) if ($parent_id);

    my $secs = $node->secondary_nodes;
    push @magic9, sprintf("Target=%s",join(",",map{sprintf("%s+%d+%d",$_->src_seq,$_->start,$_->end)}@{$secs || []})) if (@{$secs || []});

    #WARNING: property value HAS NOT BEEN URL escaped for the following characters: ",=;" and whitespace
    my $props = $node->properties;
    my $h = $node->hash;
    foreach my $k (keys %{$h || {}}) {
        unless (grep{$k eq $_}&_gff_hidden_prop_params) {
            push @{$props}, {type=>$k,value=>$h->{$k}} if (defined($h->{$k}));
        }
    }
    my ($s, $e) = ($node->fmin, $node->fmax);
    unless (defined($s) && $e) {
        if ($node->seqlen && !$node->src_seq) {
            push @{$props}, {type=>'seqlen',value=>$node->seqlen};
        }
    }
    $s++ if (defined($s));

    push @magic9, join(";", map{$_->{type}."=".$_->{value}}@{$props || []}) if (@{$props || []});
    my $dbxrefs = $node->dbxrefs;
    push @magic9, sprintf("Dbxref=%s",join(",",map{$_->{dbname}.":".$_->{accession}}@{$dbxrefs || []})) if (@{$dbxrefs || []});
    my $syns = $node->synonyms;
    push @magic9, sprintf("Alias=%s",join(",",map{$_->{type}."=".$_->{value}}@{$syns || []})) if (@{$syns || []});
    my $onts = $node->ontologies;
    push @magic9, sprintf("Ontology_term=%s",join(",",map{$_->{dbname}.":".$_->{accession}}@{$onts || []})) if (@{$onts || []});
    print $fh sprintf("%s\n",join("\t", ($node->src_seq || ".", ".", $node->type, $s || ".", $e || ".", ".", $node->strand || ".", ".", join(";",@magic9))));
    #no homology (secondary_node) seq fasta??
    if ($fasta_out) {
        my ($descr, $res) = (undef, $node->residues);
        ($descr) = $node->get_property('description');
        if ($descr || $res) {
            print $fh "##FASTA\n";
            printf $fh sprintf(">%s\n",$descr || $id);
            if ($res) {
                $res =~ s/(.{80})/$1\n/g;
                chomp $res;
                print $fh "$res\n";
            }
            printf $fh "###\n";
        }
    }
    map{_gff3($_, $fh, $opts, $id)}@{$node->nodes || []};
    #terminator could be the end of FASTA or the end of a feature (complex feature)
    printf $fh "###\n" if ($terminator_depth && $terminator_depth == ($node->depth || -1)); #depth 0 is root
}

1;
