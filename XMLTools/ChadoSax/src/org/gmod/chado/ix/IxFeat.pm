
=head1 NAME

org::gmod::chado::ix::IxFeat

=head1 DESCRIPTION

Describe generic feature.
See also org.gmod.chado.ix.IxFeat.java

  org::gmod::chado::ix::IxFeat; - 'feature' record contains
       (a) hash of single value fields (tag==class,id,name,..)
       (b) list of child sub-features (IxFeat; tagged; should have id)
       (c) list of attributes (IxAttr; tagged; may have id)
       (d) list of feature locations (IxSpan; no id)

inherits from org::gmod::chado::ix::IxBase

update dec2003; mar2004 
 - fixed finally transsplice problem 
 (exons and prot start/stop w/ diff orientations); 
 - added intron, 5/3 utr parts

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
	# $self->SUPER::init();
	$self->{tag}= 'IxFeat' unless (exists $self->{tag} );
  $self->{list}= [];
  $self->{attrlist}= [];
	$self->{loclist}= [];
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

=head2 addattr

  addattr(IxAttr) - add IxAttr to list

=cut
  
sub addattr {
	my $self= shift;
	my $val= shift;
  push(@{$self->{attrlist}}, $val); ## attrlist
}

=head2 getfeats([classTypes])
  
  return list of IxFeat sub-features  
  classTypes - optional list of feature types to return
  
=cut

sub getfeats {
	my $self= shift;
	return $self->getFeatsOrAttrs($self->{list},@_);
}

=head2 getattrs([classTypes])

  get IxAttr list
  classTypes - optional list of feature types to return

=cut
  

sub getattrs {
	my $self= shift;
	return $self->getFeatsOrAttrs($self->{attrlist},@_);
}

sub getFeatsOrAttrs {
	my $self= shift;
	my $atftlist= shift;
	my @cl= @_;
  my @fts= @{$atftlist};
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

=head2 getfeatbyid
  
  getfeatbyid() - return child feature with given id
  see also IxBase::getid(id) using handler->{idhash}
  
=cut

sub getfeatbyid {
	my $self= shift;
	my $id= shift;
  my @fts= @{$self->{list}};
  foreach my $ft (@fts) {
    return $ft if ( $ft->{id} eq $id );
    }
  return undef;
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



=head2 addloc(IxSpan)

  add IxSpan(nbeg,nend,src)

=item NOTE
  
  move location handling to new IxBase/IxAttr subclass ? not IxSpan
  
=cut
  
sub addloc {
	my $self= shift;
	my $val= shift;
  push(@{$self->{loclist}}, $val); ## loclist
}

# =head2 getlocs()
# 
#   return hash by source id of ordered Spans
#   drop for getlocations() ?
#   
# =cut
#   
# sub getlocs {
# 	my $self= shift;
# 	
#   my %sp=();
#   my @list= @{$self->{loclist}};
#   return undef unless(  @list);
#   
#   foreach (@list) { 
#     my $src= $_->get('src');
#     push( @{$sp{$src}}, $_->toString());
#     }
#   foreach my $src (keys %sp) {
#       # this sort is actually bad for transspliced, other non-linear orderings
#     my @sp= sort { $a <=> $b } @{$sp{$src}}; #? ok
#     my @ps= ();
#     my $lp;
#     foreach (@sp) {
#       if ($_ ne $lp) { push(@ps,$_); $lp=$_; }
#       }
#     @{$sp{$src}}= @ps;
#     }
#   # $self->{locs}= \%sp;
#   return %sp;
# }
# 

#?? here? need  to deal with mRNA/CDS subfeature - exon joining...
## if which == sublocs:type_name=>exon get compound location from exon feature sublocs
## ditto for analysis feature, type_name => match, ..

=head2 getlocations( [$sublocs] )

  replacement for getlocs()
  
  $sublocs - use subfeatures of this feature type_id/name (optional)
    e.g. %srclocs= $mrna_feature->getlocations('exon')
    returns join of exon spans
    
  return hash by source id of 
    srclocs{src}->{locs} = @array of IxSpan()->toString() == 10..20
    srclocs{src}->{rev}  = true if reversed 
    srclocs{src}->{loc}  = join of locs
    srclocs{src}->{i}    = source index (0..n-1)
    
  should be part of IxLoc subclass?

=cut

sub getlocations {
	my $self= shift;
	my $sublocs= shift || undef;
  
  #return undef unless(  @{$self->{loclist}});
  my @list= @{$self->{loclist}};
	
	if ($sublocs =~ /\S/) {
	  @list= ();
	  my @subft= $self->getfeats("feature"); #? locs only in this type
	  foreach my $sf (@subft) {
	    my ($t,$nm)= $sf->id2name('type_id',$sf->{type_id});
	    push(@list, @{$sf->{loclist}}) if($nm eq $sublocs);
	    }
	  }
	
  return undef unless(@list);
  my %sp=();
  my @srcs= ();
  my %revs= ();
   ## if we kept the Span objects in {locs} wouldn't need messy revs computes
   ## but this is all for 1 dang fly transspliced gene
     
  foreach (@list) { 
    my $src= $_->get('src');
    push( @srcs, $src) unless(exists $sp{$src}); # for sort order
    my $rev= $_->reversed();
    $sp{$src}->{rev} = $rev; # this is where trans splice needs patch
    push( @{$revs{$src}}, $rev);
    push( @{$sp{$src}->{locs}}, $_->toString());
    }
    
  for my $i (0..$#srcs) {
    my $src= $srcs[$i];
    my @revs= @{$revs{$src}};
    my @locs= @{$sp{$src}->{locs}};
    
    my $istrans= 0;
    if (@revs > 1) {
      my $lastr= $revs[0];
      foreach my $rev (@revs[1..$#revs]) {
        if ($rev != $lastr) { $istrans=1; last; }
        $lastr= $rev;
        }
      }

    my @ps= (); my @rs=();
    my @js= sort { $locs[$a] <=> $locs[$b] } (0..$#locs);  
    my $lp='';
    foreach my $j (@js) {
      next if ($locs[$j] eq $lp); #? dont need this
      push(@ps, $locs[$j]);  $lp= $locs[$j];
      push(@rs, $revs[$j]) if ($istrans);
      }
    @locs= @ps; 
    @revs= @rs if ($istrans);
      
    $sp{$src}->{locs} = \@locs;
    $sp{$src}->{i}= $i;
    $sp{$src}->{transspliced}= $istrans;
    if ($istrans) { $sp{$src}->{revs}= \@revs; $sp{$src}->{rev}= 0; }
    }
  return %sp;
}



## FIXME ##
=head2 getlocation( [$which] [$sublocs] )
  
  returns string of location == complement(10..20,30..40)
  params:
  $which = which source, may be source name or index, default is 0/1st
  $sublocs = subfeature type_name, if present, uses these
    e.g. $locstring= $mrna->getlocation( $src_id, 'exon')
  should be part of IxLoc subclass?
  
=cut 

sub getlocation {
	my $self = shift;
	# my $which= shift || 0;
	# my $sublocs= shift || undef;
  # my %sp= $self->getlocations($sublocs);
  my $spi= $self->getlocationSrc(@_);# ($which, $sublocs);
  return $self->getlocationString($spi);
}

sub getlocationSrc {
	my $self = shift;
	my $which= shift || 0;
	my $sublocs= shift || undef;
  my %sp= $self->getlocations($sublocs);
  return undef unless(%sp);
  
  my ($src, $spi);
  my @srcs= keys %sp;  
  if ($which =~ /\D/) { #name
    ($src)= grep(/^$which$/, @srcs);   
    $spi= $sp{$src} if ($src); # $loc= $sp{$src}->{loc} || undef;
    }
  else {
    foreach $src (@srcs) {
      if ($sp{$src}->{i} == $which) {
        $spi= $sp{$src}; last;
        }
      # $loc= $sp{$src}->{loc};    
      # return $loc if ($sp{$src}->{i} == $which);
      }
    }
  return $spi;
}
  
sub getlocationString {
	my $self = shift;
	my ($spi, $lockey)= @_;
  $lockey ||= 'locs';
	return undef unless(defined $spi && defined $spi->{$lockey});
  my $loc='';
  my @ps= @{$spi->{$lockey}};
  if ($spi->{transspliced}) {
    my @r= @{$spi->{revs}};
    foreach my $i (0..$#ps) {
      $loc .= ',' if ($loc);
      if ($r[$i]) { $loc.= 'complement('.$ps[$i].')'; }
      else { $loc.= $ps[$i]; }
      }
    # $loc= 'join('.$loc.')';
    if ($spi->{rev} && $loc) { $loc= 'complement('.$loc.')'; }
    elsif ($loc =~ /,/) { $loc= 'join('.$loc.')'; }
    }
  else {
    $loc= join(",",@ps);
    if ($spi->{rev} && $loc) { $loc= 'complement('.$loc.')'; }
    elsif ($loc =~ /,/) { $loc= 'join('.$loc.')'; }
    }
  return $loc;
}


=head2 trans spliced locs -- FIXME

## FIXME = messy; move to IxLoc

FIXME: for trans splicing
 for fly mod(mdg4) - trans-spliced; 
 need to handle odd mix of transcript parts to CDS
 
mRNA join(complement(17193974..17194085),
   complement(17193505..17193762),
   complement(17193288..17193427),
   complement(17191746..17192598),17182690..17183024)
   /gene="mod(mdg4)"
   /locus_tag="CG32491"
   /product="CG32491-RY"
   /note="trans splicing"
   /transcript_id=" NM_176523.1 "
   /db_xref="FLYBASE: FBgn0002781 "
   
CDS join(complement(17193505..17193718),
   complement(17193288..17193427),
   complement(17191746..17192598),17182690..17182985)
   /gene="mod(mdg4)"
   /locus_tag="CG32491"
   /codon_start=1
   /exception="trans splicing"
   /protein_id=" NP_788700.1 "
   /db_xref="FLYBASE: FBgn0002781 "

-- mar 2004 output from chado.xml r3.2.0 --
3R      17182690        mRNA    mod(mdg4)-RY    -      
join(17182690..17183024,complement(17191746..17192598),complement(
17193288..17193427),complement(17193505..17193762),complement(17193974..
17194085))  mod(mdg4)-RY    CG32491 ; FlyBase:FBgn0002781  
gene=mod(mdg4)

3R      17182690        CDS     mod(mdg4)-PY    -      
complement(complement(17182690..17182983),17191746..17192598,17193288..
17193427,17193505..17193718)        mod(mdg4)-PY    CG32491 ;
FlyBase:FBgn0002781      gene=mod(mdg4)


=cut

sub insertlocations {
	my $self  = shift;
	my $loca  = shift; # amino start .. end
	my $locb  = shift; # mrna  a..b,c..d,e..f
	return undef unless(ref $loca);
  my @a= @{$loca->{locs}}; # should be 1 only; if more ??
  my @r= @{$locb->{locs}};
  
  # patch here..
  my @revs=(); my $isrev= 0;
  my $istrans= $locb->{transspliced};
  if ($istrans) { 
    $loca->{transspliced}= $istrans;
    @revs= @{$locb->{revs}}; 
    $isrev= ($loca->{rev} != $locb->{rev});
    if ($isrev) { foreach (@revs) { $_ = ! $_; } }
    # $loca->{revs}= \@revs; # URK, need to screen/split prot & utr revs..
    }
 
  ##  if ($istrans) -- need to flip exons here and apply $loca->b,e right way
  ## but what is right way ? $rb..$b instead of $b..$re ? / $e..$re not $rb..$e
   
  my @al= ();  my @arev=();
  my @head=(); my @tail= (); ## 5/3 prime ends
  my $a= shift @a;
  my ($b,$e)= split(/\.\./,$a);
  ## need patch here for non-linear ordered parts
  # foreach my $r (@r)  
  foreach my $i (0..$#r) {
    my $r= $r[$i];
    my $rev= ($istrans) ? $revs[$i] : 0;
    
    my ($rb,$re)= split(/\.\./,$r);
    if ($re < $b) { push(@head, $r); next; }
    elsif ($rb > $e) { push(@tail, $r); next; }  
    elsif ($rb<=$b && $re>=$b) {
      if ($re>=$e) { push(@al,"$b..$e"); push(@arev,$rev); } # last
      elsif ($istrans && $isrev && $rev) { 
        ## is this right? only need transspliced patch for compl( compl(protexon1:b..e<),...)
        ## here protexon1:e becomes start of prot, not protexon1:b
        push(@al,"$rb..$b");  push(@arev,$rev);
        push(@head, ($b+1)."..$re")  if ($b<$re);  
        } 
      else { 
        push(@al,"$b..$re");  push(@arev,$rev);
        push(@head, "$rb..".($b-1)) if ($rb<$b);  
        }
      }
    elsif ($rb<=$e && $re>=$e) {
      push(@al,"$rb..$e"); push(@arev,$rev);
      push(@tail, ($e+1)."..$re") if ($re>$e);
      #was# last;
      }
    else { push(@al,$r); push(@arev,$rev); }
    }
  unless(@al) { push(@al,"$b..$e"); }
  $loca->{locs}= \@al; 
  $loca->{revs}= \@arev if ($istrans);
  $loca->{five_prime_UTR}= \@head; 
  $loca->{three_prime_UTR}= \@tail; 
  return $loca;
}

=item addIntrons

  turn location subrange inside out = introns from exons
  
=cut

sub addIntrons { 
	my $self = shift;
	my $loca  = shift; # mrna  a..b,c..d,e..f
 	return undef unless(ref $loca);
  my @r= @{$loca->{locs}};
  my @al= ();  
  my $a= shift @r;
  my ($bb,$be)= split(/\.\./,$a);
  foreach my $r (@r) {
    my ($rb,$re)= split(/\.\./,$r);
    $be++; $rb--; # move out of seq bases
    push(@al,"$be..$rb");
    $be= $re;
    }
  $loca->{intron}= \@al; 
  return $loca;
}


sub getlocsources {
	my $self= shift;
  return undef unless(defined $self->{loclist});
  my @srcs;
  my @list= @{$self->{loclist}};
  foreach (@list) { 
    my $src= $_->get('src');
    push( @srcs, $src);
    }
  return @srcs; #?? sort/ these are ugly feature_### names
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
    #? uniquename is most valid name ?
    # next if ($k eq 'uniquename' && $self->{name});
    my $v= $self->{$k};
    # check type_id|.. here and change $k if need be ?
    ($k,$v)= $self->id2name($k,$v);

    print $tab."$k";
    if($v =~ /\S/) {
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
    }
    print "\n";
    }
    
    ## need to order spans; check on source_id to see if all are same?
  if ( defined $self->{loclist} ) {
    my %sp= $self->getlocations();
    foreach my $src (sort keys %sp) {
      ##my $loc= $sp{$src}->{loc}; # ${$sp{$src}}{loc};
      my $loc= $self->getlocationString( $sp{$src} ); 
      print $tab."loc.$src=".$loc."\n" if ($loc);
      }
#     my %sp= $self->getlocs();
#     foreach my $src (sort keys %sp) {
#       my @sp= @{$sp{$src}};
#       print $tab."loc.$src=".join(",",@sp)."\n" if (@sp);
#       }
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
