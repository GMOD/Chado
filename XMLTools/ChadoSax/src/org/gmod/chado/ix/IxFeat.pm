
=head1 NAME

org::gmod::chado::ix::IxFeat

=head1 DESCRIPTION

Describe generic feature.
See also org.gmod.chado.ix.IxFeat.java

  org::gmod::chado::ix::IxFeat; - 'feature' record contains
       (a) hash of single value fields (tag==class,id,name,..)
       (b) list of child sub-features
       (c) list of attributes (IxAttr)
       (d) list of feature locations (IxSpan)

inherits from org::gmod::chado::ix::IxBase

note: want to use method names consistent w/ Java standard?
  getBob instead of getbob 

=head1 AUTHOR

D.G. Gilbert, May 2003, gilbertd@indiana.edu

=cut

package org::gmod::chado::ix::IxFeat;

use strict;
use org::gmod::chado::ix::IxBase;
use vars qw/  @ISA /;
@ISA = qw( org::gmod::chado::ix::IxBase );  


sub isGenFeat() { return 1; }

sub init {
	my $self= shift;
	$self->{tag}= 'IxFeat' unless (exists $self->{tag} );
	# @{$self->{list}}= ();
}


=head1 METHODS

=head2 add
  
  add(IxFeat) - add child sub-feature record to list
  
=cut
  
sub add {
	my $self= shift;
	my $val= shift;
  push(@{$self->{list}}, $val);
}

=head2 getfeats([classTypes])
  
  return list of child sub-feature  
  classTypes - optional list of feature types to return
  
=cut

sub getfeats {
	my $self= shift;
	my @cl= @_;
  my @fts= @{$self->{list}};
  if (@cl) {
    my %tags=  map { $_,1; } @cl;
    my @ft2= ();
    foreach my $ft (@fts) {
      push(@ft2, $ft) if ( $tags{ $ft->{tag} });
      }
    return @ft2;
    }
  return @fts;
}

=head2 getfeattypes
  
  getfeattypes() - return list of child sub-feature field types
  note: want an iterator class to handle multiple methods per feature ?
  
=cut

sub getfeattypes {
	my $self= shift;
  return undef unless(defined $self->{list});
  my @fts= @{$self->{list}};
  my @cl= ();
  foreach my $ft (@fts) {
    push(@cl, $ft->{tag});
    }
  return @cl;
}

=head2 addattr

  addattr(IxAttr) - add IxAttr to list

=cut
  
sub addattr {
	my $self= shift;
	my $val= shift;
  push(@{$self->{attrlist}}, $val); ## attrlist
}

=head2 getattrs()

  get IxAttr list

=cut
  
sub getattrs {
	my $self= shift;
  return undef unless(defined $self->{attrlist});
  my @attr= @{$self->{attrlist}};
  return @attr;
}


=head2 addloc(IxSpan)

  add IxSpan(nbeg,nend,src)

=cut
  
sub addloc {
	my $self= shift;
	my $val= shift;
  push(@{$self->{loclist}}, $val); ## loclist
}

=head2 getlocs()

  return hash by source id of ordered Spans

=cut
  
sub getlocs {
	my $self= shift;
  return undef unless(defined $self->{loclist});
  my %sp=();
  my @list= @{$self->{loclist}};
  
  foreach (@list) { 
    my $src= $_->get('src');
    push( @{$sp{$src}}, $_->toString());
    }
  foreach my $src (keys %sp) {
    my @sp= sort { $a <=> $b } @{$sp{$src}}; #? ok
    my @ps= ();
    my $lp;
    foreach (@sp) {
      if ($_ ne $lp) { push(@ps,$_); $lp=$_; }
      ##if (eq) { $_= undef; }# else { push(@ps,$_); }
      ##else { $lp= $_; }
      }
    @{$sp{$src}}= @ps;
    }
  # $self->{locs}= \%sp;
  return %sp;
}



=head2 printObj()

Basic display method - mostly tuned to printing readable, asn1-like  structure
this may well change. For this sample print out (IxFeat::printObj()),
the definition IDs embedded in fields are replaced by def. names.

=cut

sub printObj { ## was toString
	my $self= shift;
	my $depth= shift;
	my $sb='';

  my $tab= "  " x $depth;
  print $tab.$self->{tag}." = {\n";
  $depth++;
  $tab= "  " x $depth;
  print $tab."id=".$self->{id}."\n" if $self->{id};
  
  ## print "# Keys\n";
  foreach my $k (sort keys %$self) {
    next if ($k =~ /^(id|tag|list|attrlist|loclist|handler)$/);
    next if ($k eq 'uniquename' && $self->{name});
    my $v= $self->{$k};
    # check type_id|.. here and change $k if need be ?
    ($k,$v)= $self->id2name($k,$v);

    print $tab."$k";
    next unless($v =~ /\S/);
    print "=";
    if (ref $v && $v->can('printObj')) {
      $v->printObj($depth);
      }
     # currently dont have array or hash in main fields
    elsif (ref $v =~ /ARRAY/) { ## list, attrlist
      print "[";
      foreach my $a ( @$v ) {
        if (ref $a && $a->can('printObj')) {
          $a->printObj($depth);
          }
        else { print $a; }
        print ",";
        }
      print "]\n";
      }
    elsif (ref $v =~ /HASH/) {  
      print "[";
      foreach my $a (sort keys %$v ) {
        if (ref $a && $a->can('printObj')) {
          $a->printObj($depth);
          }
        else { print $a; }
        print ",";
        }
      print "]\n";
      }
    else { print $v; }
    print "\n";
    }
    
    ## need to order spans; check on source_id to see if all are same?
  if ( defined $self->{loclist} ) {
    my %sp= $self->getlocs();
#     foreach (@{$self->{loclist}}) { 
#       my $src= $_->get('src');
#       push( @{$sp{$src}}, $_->toString());
#       }
    foreach my $src (sort keys %sp) {
#       my @sp= sort { $a <=> $b } @{$sp{$src}}; #? ok
      my @sp= @{$sp{$src}};
      print $tab."loc.$src=".join(",",@sp)."\n" if (@sp);
      }
    }
  
  if ( defined $self->{attrlist} ) {
    my $nd= 0; my $ln= 0;
    $self->{handler}->{linelen}=0;
    foreach (@{$self->{attrlist}}) { 
      if (0 == $nd++) { print $tab; }
      elsif ($ln>80 || $self->{handler}->{linelen}>80) { 
        print "\n$tab"; $ln= 0; $self->{handler}->{linelen}=0; 
        }
      $ln += $_->printObj($depth);  
      }
    print "\n" if $nd>0; # $self->{handler}->{linelen}>0;
    }
  
  if ( defined $self->{list} ) {
    foreach (@{$self->{list}}) { 
      $_->printObj($depth);  
      }
    }
  print "$tab}\n";

  return $sb;
}


=head1 SAMPLE printObj
  
  chado = {
  unused_analysis_id=177
  unused_analysisfeature=177
  -- top level list of definitions (mostly cvterms)
  cv = {
    id=cv_1
    cvname=SO
    }
  cvterm = {
    id=cvterm_4
    cv_name=SO
    name=mRNA
    }
  organism = {
    id=organism_1
    genus=Drosophila species=melanogaster taxgroup=drosophilid 
    }
  analysis = {
    id=analysis_24
    program=blastx_masked
    programversion=1.0
    sourcename=aa_SPTR.rodent 
    }
    
    -- this is a primary (top-level) gene annotation record
    -- all following subrecords are nested inside this feature
  feature = {
    id=feature_110661
    name=Fas2
    type_name=synonym
    -- ^ primary record keys from obj->{keyname}
        note obj->{type_id} is converted on output to type_name from top cvterm list
    -- there is no field which indicates this is a gene annotation structure !?
        
    loc.feature_6=3946706..3874987
    -- ^ from obj->getlocs()
    
    subjfeature_name=CG3665-RC subjfeature_name=CG3665-RB dbxref_name=FlyBase:FBgn0000635 
    dbxref_id=dbxref={ Gadfly:CG3665, id=dbxref_58074 }  
    dbxref_id=dbxref={ flybase:FBan0003665, id=dbxref_58075 }  
    featureprop={ AE003430, id=featureprop_26868, pkey_name=gbunit, pub_name=pub_1 } featureprop={ 'Perfect match to SwissProt real (computational)', id=featureprop_26866, pkey_name=sp_status, pub_name=pub_1 } 
    featureprop={ 4B1-4B3, id=featureprop_26867, pkey_name=cyto_range, pub_name=pub_1 } 
    cvterm_name='learning and/or memory' cvterm_name='homophilic cell adhesion' 
    is_internal=0 
    -- ^ attribute list from obj->getattrs()
    
    -- start 1st transcript record
    feature = {
      id=feature_110662
      name=CG3665-RA
      type_name=synonym
      loc.feature_6=3946706..3874987
      dbxref_id=dbxref={ Gadfly:CG3665-RA, id=dbxref_58076 }  
      seqlen=71719 dbxref_name=Gadfly:CG3665-RA featureprop={ AAF45925, id=featureprop_26869, pkey_name=protein_id } 
      featureprop={ 'Perfect match to REAL SP with corresponding FBgn', id=featureprop_26870, pkey_name=sp_comment } 
      featureprop={ campbell, id=featureprop_26871, pkey_name=owner } is_internal=0 

      -- first exon1 subrecord for transcript
      feature = {
        id=feature_110671
        name=CG3665:9
        type_name=exon
        loc.feature_6=3876113..3876026
        dbxref_id=dbxref={ Gadfly:CG3665:9, id=dbxref_58085 }  
        seqlen=87 dbxref_name=Gadfly:CG3665:9 
        
        -- this is where chado xml nesting is confusing; this
        -- feature_6 is the global X chromosome record that many records refer to
        -- but is nested 3 levels into structure
        -- should move to top or main feat level for human readability
        feature = {
          id=feature_6
          uniquename=X
          }
        }
        
      -- second exon2 record more confusion 
      -- additional transcripts now are nested inside transcript1/exon2
      -- should be promoted to same level
      feature = {
        id=feature_110664
        name=CG3665:2
        type_name=exon
        loc.feature_6=3944102..3943806
        dbxref_id=dbxref={ Gadfly:CG3665:2, id=dbxref_58078 }  
        seqlen=296 dbxref_name=Gadfly:CG3665:2 
        -- transcript2 defined
        feature = {
          id=feature_110674
          uniquename=CG3665-RB
          }
        -- transcript3 defined
        feature = {
          id=feature_110677
          uniquename=CG3665-RC
          }
        }
        
      -- this sample exon is nested in transcript1 and is referenced
      -- by tr2 and tr3, so belongs to all
      feature = {
        id=feature_110666
        name=CG3665:4
        type_name=exon
        loc.feature_6=3890167..3890003
        dbxref_id=dbxref={ Gadfly:CG3665:4, id=dbxref_58080 }  
        seqlen=164 dbxref_name=Gadfly:CG3665:4 objfeature_name=CG3665-RB 
        objfeature_name=CG3665-RC 
        }
        
     }
    -- end transcript records
    
    -- a feature evidence record - analysis and locations of matches
    feature_evidence = {
      id=feature_evidence_110661:115629
      feature = {
        id=feature_115629
        rawscore=183
        type_name=alignment_hsp
        uniquename=NULL:87474
        loc.feature_28828=301..518
        loc.feature_6=3884117..3883415
        -- ^ locations of source and object/target matches
        -- loc.feature_id is syntax now 
        seqlen=701 analysis_name=blastx_masked
        -- this subfeature probably should be promoted to part of parent record
        feature = {
          id=feature_28828
          name=P20241
          type_name=protein
          loc.=0..27,17..436,24..68,26..517,41..164,47..216,53..133,55..436,56..336,57..217,68..1006,78..423,155..631,193..335,237..447,249..472,251..417,264..563,271..333,275..512,281..428,300..517,301..518,302..518,302..444,312..508,327..515,327..518,329..487,332..430,334..619,334..436,336..430,338..563,338..428,342..705,382..621,392..517,394..480,396..952,403..518,417..548,427..508,427..507,428..695,428..643,431..518,444..596,444..537,444..596,444..530,445..522,445..1100,448..616,454..1004,458..1106,477..877,479..713,501..660,508..651,514..807,524..804,527..799,551..1100,552..809,552..660,552..809,554..1100,555..799,557..1110,571..1100,574..1096,576..854,578..807,614..960,712..1114,731..1004,779..1069,783..1120,915..1006,915..1122,915..1006,1006..1067,1056..1188,1188..1223,1222..1302
          seqlen=1302 dbxref_name=SMART:SM00060 dbxref_id=dbxref={ EMBL:X76243, id=dbxref_49862 }  
          dbxref_name=PRINTS:PR00014 dbxref_name=SMART:SM00408 dbxref_id=dbxref={ PDB:1CFB, id=dbxref_49858 }  
          dbxref_id=dbxref={ EMBL:M28231, id=dbxref_49869 }  
          dbxref_name=InterPro:IPR003006 dbxref_name=InterPro:IPR001777 dbxref_name=SMART:SM00410 
          dbxref_id=dbxref={ FlyBase:FBgn0002968, id=dbxref_49861 }  
          dbxref_name=InterPro:IPR003598 dbxref_id=dbxref={ SPTR:P20241;, id=dbxref_49864 }  

          dbxref_name=Pfam:PF00047 dbxref_name=Pfam:PF00041 dbxref_name=InterPro:IPR003600 
          featureprop={ 'Neuroglian precursor.', id=featureprop_6948, pkey_name=description, pub_name=pub_1 } 
          }
        feature = {
          id=feature_115628
          uniquename=NULL:87473
          }
        }
      }

    feature_evidence = {
      id=feature_evidence_110661:113321
      feature = {
        id=feature_113321
        rawscore=381.49
        type_name=exon
        uniquename=NULL:85821
        loc.feature_6=3877474..3877184
        seqlen=289 analysis_name=piecegenie objfeature_name=NULL:85820 
        }
      }
    }
  }
  
=cut

1;
