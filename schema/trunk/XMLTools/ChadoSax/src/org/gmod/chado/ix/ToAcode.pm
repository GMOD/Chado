
=head1 NAME

org::gmod::chado::ix::ToAcode

=head1 DESCRIPTION

Read Chado XML to acode flatfile

=head1 SYNOPSIS

  perl -I$ix/src -M'org::gmod::chado::ix::ToAcode' -e 'acode;' -- \
    chado7-aug03/AE003430v7.chado.xml > chado7-sep03/AE003430v7-ix.acode

  perl -I$ix/src -M'org::gmod::chado::ix::ToAcode' -e 'acodeindex;' -- \
     chado7-sep03/AE003430v7-ix.acode

  perl -I$ix/src -M'org::gmod::chado::ix::ToAcode' -e 'acode;' -- \
    -out=AE003844_v7.0_0728.acode \
    -feat=AE003844_v7.0_0728.feats \
    -debug -index \
    AE003844_v7.0_0728.chado.xml 

=head2 NOTES

  for feature output (got some dup feats), use on output:
    sort -d +0 -n +1 | uniq |
    and split by col1 = csome to separate features-csome.tsv files
     dropping cols 1,2 
  
  - this now outputs 'gnomap-version-1' feature tables (used by gnomap
  and gbrowse_fb); 
  - add ability to output gff-version-3 and index for use with 
  gbrowse flatfile-db adaptor
     
    ...
    
  just now (sep03) this is memory-piggy, and doesn't release all
  data once dumped.  Best use by invoking program newly for 
  each scaffold.chado.xml, and catting to > output.acode, 
  then do acodeindex
  
  set ix=~/bio/dev/gmod/schema/XMLTools/ChadoSax/
  set ch=~/bio/flybase/chado/chado7-aug03/
  
=head2 CVS info

  set cvsd=':pserver:anonymous@flybase.net:/bio/cvs'
  cvs -d $cvsd login
  cvs -d $cvsd co -d ChadoSax gmod/schema/XMLTools/ChadoSax/

  - also in gmod.org sourceforge CVS, same path
  
=head1 AUTHOR

D.G. Gilbert, Sep 2003, gilbertd@indiana.edu
 
=cut

#-----------------

package org::gmod::chado::ix::ToAcode;

# use lib('/Users/gilbertd/bio/dev/gmod/schema/XMLTools/ChadoSax/src/');
# use lib('/bio/biodb/common/perl/lib/');
# use lib('/bio/biodb/common/system-local/perl/lib/');
# use warnings;

use strict;

use org::gmod::chado::ix::IxFeat;
use org::gmod::chado::ix::IxAttr;
use org::gmod::chado::ix::IxSpan;
use org::gmod::chado::ix::IxReadSax;

use Exporter;
use vars qw/$VERSION $debug @ISA @EXPORT $DATA_VERSION %deflineKeys %fbgn2id /;

@ISA = qw(Exporter);
@EXPORT = qw(&acode &acodeindex);

use Getopt::Long;    
use constant IDXRECSIZE => length(pack("NN", 1, 50000)); # store as unsigned long, unsigned long
use constant FBTI_IDBASE => 50000; ## FIXME - quick fix for TE/FBti id in FBan form

use vars qw/
  @transcript_types $transcript_types
  @non_transcript_types $non_transcript_types
  @ignore_feature_types $ignore_feature_types
  @cmt_props @skip_props
  $AnnoDbName $GeneDbName
  $RECSEP
  /;

=item 

  mar04 - add top level==1 non-transcript feats
      non_transcript (DNA_motif/aberration_junction/ enhancer                         
          insertion_site/ point_mutation/ protein_binding_site/region/                    
          regulatory_region/ repeat_region/rescue_fragment            
                 /sequence_variant )
=cut

BEGIN {
  $debug= 0;
  $VERSION = "0.6"; # mar04
  $DATA_VERSION = "3.2";
  %fbgn2id=();
  $RECSEP='/;'; # ',;'; # ':;'  << digits,: are bad in regex ??
  
  $AnnoDbName= ''; ## 'GadFly:'; # or is it 'FlyBase:' now - what software needs updates
  $GeneDbName= 'FlyBase:';
  
  @transcript_types= qw( \w+RNA protein pseudogene );
  @non_transcript_types = qw(DNA_motif aberration_junction enhancer insertion_site
  point_mutation protein_binding_site region regulatory_region repeat_region
  rescue_fragment sequence_variant
  );
  @ignore_feature_types = qw(exon chromosome_arm);

  $transcript_types= join('|', @transcript_types);
  $non_transcript_types= join('|', @non_transcript_types);
  $ignore_feature_types= join('|', @ignore_feature_types);

  @skip_props= qw( internal_synonym owner element );#protein_id 
  
    ## these fields are added as desired .. don't try to track, stick all in CMT superfield
  @cmt_props= qw(
        sp_comment comment status problem description validation_flag
        anticodon aminoacid dicistronic
        evidence citation
        );
}


=head1 Public METHODS

=item acode()
 
 main method; writes flybase.net acode format data from chado.xml
 usage:
  org::gmod::chado::ix::ToAcode  -e'acode;' --  [options] chado.xml[.gz|.bz2] ...
  creates flybase acode from chado.xml 
  options:
  -outfile = output.acode [or STDOUT]
  -featfile = feature.tsv [or null]
  -index = index output.acode
  -version = 3.2 [$DATA_VERSION]
  -[no]debug     
   
=cut

sub acode {

  my $outfh= *STDOUT;
  my $ftout= undef;
  my $faout= undef; my $fnout= undef;
  my $outf= undef;
  my $ftoutf= undef;
  my $doindex= 0;
  my @skipf=();
  my $fbgn2id= undef;
  
  my $optok= Getopt::Long::GetOptions( 
    'debug!' => \$debug,
    'index!' => \$doindex,
    'outfile=s' => \$outf,
    'featfile=s' => \$ftoutf,
    'fbgn2id=s' => \$fbgn2id,
    'skipfeat=s' => \@skipf,
    'version=s' => \$DATA_VERSION,
    );
    
  unless($optok) {
    die "Usage
  org::gmod::chado::ix::ToAcode  -e'acode;' --  [options] chado.xml[.gz|.bz2] ...
  creates flybase acode from chado.xml 
  options:
  -outfile = output.acode [or STDOUT]
  -featfile = feature.tsv [or null]
  -version = 3.2 [$DATA_VERSION]
  -index = index output.acode
  -fbgn2id = table of FBgn 2ndary id -> primary id to patch in
  -skipfeat = residues  -- optionally drop xml tags during parse
  -[no]debug     
  ";
    }
  
  #added default/opt to pull translation residues as fasta ..
  %fbgn2id=();
  if ($fbgn2id) {
    open(F2ID,"$fbgn2id") or warn "Cant read $fbgn2id";
    my $nid=0;
    while(<F2ID>){
      next unless(/^FB\w+\d+/);
      chomp; 
      my($secondid,$sym,$primeid)= split"\t"; 
      warn "Bad fbgn2id list format:$_"
        if ($nid++ < 5 && $primeid !~ /^FB\w+\d+/);
      next unless($primeid =~ /^FB\w+\d+/);  
      $fbgn2id{$secondid}=$primeid;
      }
    close(F2ID);
    warn "# ToAcode loaded $nid 2ndary ids from $fbgn2id\n" if $debug;
    }
      
  if ($outf) {
    # if (-r $outf) -- what ? append?
    open(OUTF,">>$outf") or die "error writing $outf";
    $outfh= *OUTF;
    }
  if ($ftoutf) {
    # if (-r $ftoutf) -- what ? append?
    open(FEATF,">>$ftoutf") or die "error writing $ftoutf";
    $ftout= *FEATF;
    my $faname= $ftoutf; 
    $faname =~ s/\.\w*$//; 
    my $naname= $faname . ".mrna.fa";
    $faname .=".amino.fa";
    open(AAF,">>$faname") or die "error writing $faname";
    $faout= *AAF;
    open(MRNAF,">>$naname") or die "error writing $naname";
    $fnout= *MRNAF;
    }
      
  my $outhand= new org::gmod::chado::ix::ToAcode(
    outh => $outfh,
    ftout => $ftout,
    faout => $faout,
    fnout => $fnout,
    );  

  my $readsax= new org::gmod::chado::ix::IxReadSax(
    debug => $debug,
    skip => \@skipf,
    handleObj => $outhand, # handle only each finished top-level feature?
    );  

  warn "# ToAcode( @ARGV ).....\n" if $debug;
  $readsax->parse( @ARGV);
  warn "# ToAcode done ............ \n" if $debug;
  
  close($outfh) if ($outf);
  close($ftout) if ($ftout);
  close($faout) if $faout;
  close($fnout) if $fnout;

  if ($doindex && $outf) {
    @ARGV= ($outf);
    acodeindex();
    }  
}



=item acodeindex()
 
 main method; create acode.idx index files for (FBan,FBgn) IDs
 where @ARGV= (input.acode)

=cut

sub acodeindex {
  unless(@ARGV) { die "usage: acodeindex FBan.acode\n"; }
  #? no need for new ToAcode()
  my $file= shift @ARGV;
  unless(-r $file) { die "acodeindex: cannot index $file\n"; }
  indexAcode( $file, "FBan", "FBgn");
}


=head1 Internal METHODS

=item new() and miscellany subs

=cut

sub new {
	my $that= shift;
	my $class= ref($that) || $that;
	my %fields = @_;   
	my $self = \%fields;
	bless $self, $class;
	$self->init();
	return $self;
}

sub init {
	my $self= shift;
	$self->{tag}= 'ToAcode' unless (exists $self->{tag} );
	$self->{outh}= *STDOUT unless (exists $self->{outh} );
	$self->{VERS}= $DATA_VERSION unless (exists $self->{VERS} );
	$self->{ftd}= {};
	$self->{aaresid}= {};
	$self->{mrnaresid}= {};
	$self->{evd}= {};
	$debug= $self->{debug} if $self->{debug};
 }

sub handleVal {  
	my $self = shift;
	my $depth= shift;
 	my $ob   = shift;
 	
  my %kvals= @_; #??
  warn "# Oops! - handleVal($ob) is nullop\n" if $debug;
}

sub cleandate {
  local $_= shift;
  s/ .*//;  s/-//g;
  return $_;
}

sub getDbXref {  
	my $self = shift;
	my $ob = shift; # IxAttr tag=dbxref only
	if ($ob->{tag} eq 'dbxref_id') {
	  $ob= $ob->getid( $ob->{attr} ); # no id, use attr
	  }
# 	elsif ($ob->{tag} eq 'feature_dbxref') {
#     $ob= $ob->getid( $ob->{dbxref_id} ); ## no good
#     # my($dtag,$db)= $ob->id2name('db_id',$dbob->{db_id});
#     }
  my($tag,$dbid,$attr)= ('db_id', $ob->{db_id}, $ob->{attr});
  my($dtag,$db)= $ob->id2name($tag,$dbid);
  my $dbattr= ($db ne $dbid && $attr !~ m/^$db:/) ?  "$db:$attr"  : $attr;
  return ($attr, $db, $dbattr);
}

=item comment($comment)

  process comment from parser (write or ignore)

=cut

sub comment {  
	my $self = shift;
  my $cmt= shift;
  my $outh= $self->{outh};
  print $outh "# $cmt\n";  
}



# sub getMiscFeatureLoc {
# 	my $self = shift;
#  	my ($ft, $type)= @_;
#   my $loc= $ft->getlocation();
#   my $dt= cleandate($ft->{timelastmodified}); 
#   return ($loc, $dt);  
# }

=item handleObj($depth,$object)

  main method; processes $object
  parses main features (mostly 'gene' type), and their subfeatures, attributes, etc.
  has a few FlyBase specific checks - FB id
  some data types may be flybase-specific: 
    chromosome_arm, cyto_range, various comments
  otherwise types are from Sequence Ontology (chado std)
  
  analysis data is inside gene objects as
    prediction_evidence
    alignment_evidence
   with specific feature structure
   
  recursive - calls self handleObj for child objects
  
=cut

sub handleObj {  
	my $self = shift;
	my $depth= shift;
 	my $ob   = shift;
 	
 	my $parsestate= shift; #? skip these
 	return if (defined $parsestate && $parsestate =~ /error/i );
 	  
  my $obname= $ob->name();
  my $obuniqid= $ob->{uniquename} || undef;
  
  my $otag= $ob->{tag};
##  warn "# handleObj $otag = $ob  \n" if ($debug && $depth<1);

  ## otype == gene|mRNA|protein|exon|...
  my($k,$otype)= $ob->id2name('type_id', $ob->get('type_id'));
  my ($dolist, $doatts)= (1,1);
  
    # these change for each depth==0 feature
 	my $ftd= $self->{ftd};
 	my $evd= $self->{evd};
  my $aaresid= $self->{aaresid}; #? keep in $ftd
  my $mrnaresid= $self->{mrnaresid}; #? keep in $ftd
 	my $trn= $ftd->{trn} if $ftd; #? only for $depth>0

  my $nada= 0;
  SWITCH: {

    ($otag =~ /^feature$/ && $depth==0) && do {
      delete $self->{ftd};
      delete $self->{evd};
      $ftd= $self->{ftd}= {}; #?? clear
      
      $aaresid= $self->{aaresid}= {}; #?? clear
      $mrnaresid= $self->{mrnaresid}= {}; #?? clear
      $evd= $self->{evd}= {}; #?? clear
      $trn= $ftd->{trn}= {};
      $self->{cdsloc}= '';
     
      my @srcs= $ob->getlocsources();
      $ftd->{srcid}= shift @srcs; 
      
      # srcid should be chromosome_arm - get src ft name!
      my $sft= $ob->getid( $ftd->{srcid} );
      $ftd->{ARM}= $sft->name() if ($sft);#? always? check sft->id2name{type_id} == chromosome_arm
        
      my $loc= $ob->getlocation( $ftd->{srcid});
      $ftd->{BLOC}= $loc;
      
      $ftd->{ID}= $obuniqid; #mar04 ?? correct
      
      # $ftd->{ANID}= ## dbxref={ FBan0003665, db_name=FlyBase, id=dbxref_58553 } 
      # $ftd->{CGSYM}=  #    dbxref={ CG3665, db_name=Gadfly, id=dbxref_58552 } dbxref_name=CG3665  
      # $ftd->{GID}=  dbxref_name=FBgn0000635 

      $ftd->{GSYM}= $obname;  
      $ftd->{GNLEN}= $ob->{seqlen};
     
      my $dt= cleandate($ob->{timelastmodified}); 
      $ftd->{DT}= $dt if $dt;
      
      my($tag,$type)= ('type_id', $ob->{type_id});
      ($tag,$type)= $ob->id2name($tag,$type);
      $ftd->{TYPE}= $type;
      
      if ($type eq 'transposable_element') {
        #? is this kosher? cgsym = anid = TE19568
        # $ftd->{ANID} =  $ftd->{CGSYM};
        # $ftd->{CGSYM} =   $ftd->{GSYM};
        }

      if ($type eq 'transposable_element_insertion_site') {
        ## can we drop this silly "data object"? -- should be attribute of other object (FBti)
        ## ? probably want to write to .feats table, not to object record
        $dolist= $doatts= 0; # no more recurse ??
        $ftd= $self->{ftd}= {}; #?? clear
        }
        
			last SWITCH; 
			};  

=item    
    # argh! mar04, got 'transposable_element_insertion_site' as new top-level feature
    # was EVD -- that is still there for genes..
EVD 
{
PRG|pinsertion
CLA|transposable_element_insertion_site
DT|20030927
DBX|FlyBase:FBti0007940 , P{EP}CG3308[EP1230]
BLOC|17099533..17099534
}

    # now have this? -- couldn't it be put inside FBti transposable_element record?
    ## maybe not ; maybe no matching FBti record ?
    
GADR
{
RETE|ID 1 FBan0000002   GID 1 FBti0033208       GSYM 1 P{EPgy2}EY03023  CGSYM 1 P{EPgy2}EY03023 CLA 
1 transposable_element_insertion_site   ARM 1 X
ID|FBan0000002
SYM|P{EPgy2}EY03023
GENSR
{
GSYM|P{EPgy2}EY03023
ID|FBti0033208
}

CLA|transposable_element_insertion_site
ARM|X
BLOC|19859379..19859378
DT|20040217
EVD
{
PRG|clonelocator
DB|scaffoldBACs
CLA|clonelocator
}
VERS|3.2.0

}
    
=cut 


   ($otag =~ /^feature$/ && $depth == 3) && do {
   
      if ($otype  =~ /^(mature_peptide|signal_peptide)$/ ) {  
        ## do what with it ?  part of protein - probably has featureloc
        my $val= "$otype=$obname";
        my $loc= $ob->getlocation();
        $val .= ", loc=$loc" if ($loc);
        push( @{$trn->{miscfeats}}, [$otype, $obname, $loc]) if ($loc);
        
        # $trn->{PEPCMT} .= $val .$RECSEP ; #? stick here for now to see
        my $subr= "CLNSR\n{\nCLA|$otype\nNAM|$obname\n";
        $subr .= "BLOC|$loc\n" if $loc;
        $subr .= "}\n";
        $trn->{SUBREC} .= $subr;
        last SWITCH;
        }
        
      ## lots of other depth 3 misc features ?
        
			#? or not ;  
			}; 
			 
      
   ($otag =~ /^feature$/ && $depth == 2) && do {
   
      if ($otype  =~ /^(protein)$/ ) { #&& $depth == 2 ?! need parent.otype == mRNA
        # $otype= 'CDS';
        $trn->{AANAM} = $obname;  
        $trn->{AALEN} = $ob->{seqlen};

        ## look for $ob->{residues}, residuetype => 'cdna' ??
        ## also get mrna residues - diff file?
        if ($ob->{residues}) {
          my $cdsloc= $self->{cdsloc}; #?? safe? put in $ftd?
          $aaresid->{$obname}= [$ob->{seqlen}, $ob->{residues}, $cdsloc];
          }
        }
        
      elsif ($otype  =~ /^(polyA_site)$/ ) {  
        my $val= "$otype=$obname";
        my $loc= $ob->getlocation();
        $val .= ", loc=$loc" if ($loc);
        push( @{$trn->{miscfeats}}, [$otype, $obname, $loc]) if ($loc);

        #$trn->{PEPCMT} .= $val .$RECSEP; #? stick here for now to see
        my $subr= "CLNSR\n{\nCLA|$otype\nNAM|$obname\n";
        $subr .= "BLOC|$loc\n" if $loc;
        $subr .= "}\n";
        $trn->{SUBREC} .= $subr;
        }
        
      elsif ($otype !~ /^(exon|chromosome_arm)$/) {
        warn "MISSED feature=$otype [lev=$depth] ".$obname." \n"; # if $debug;
        }
        
			last SWITCH; 
			};  
    
    
   ($otag =~ /^feature$/ && $depth == 1) && do {  
   
      ## URK - the snRNA/tRNA/xxxRNA types are here, nested below 'type=gene' ! 
      ## are there any other non-RNA types to catch here?
      # my($tag,$type)= ('type_id', $ob->{type_id});
      
      my $ftype= 0;
      if ($otype =~ m/^($transcript_types)$/) { $ftype= 1; }
      elsif ($otype =~ m/^($non_transcript_types)$/) { $ftype= 2; }
        # ^^ this now get put in TRREC{} - should make new GADR subrec for them  .. like EVD ?
      elsif ($otype =~ m/^($ignore_feature_types)$/) { $ftype= -1; }
      else {
        warn "MISSED feature=$otype [lev=$depth] ".$obname." \n";  
        }
        
      if ($ftype > 0) {
      # if ($otype  =~ /^(\w+RNA|protein|pseudogene)$/)  
      
      if ($depth == 1) {
        ## changed here for array of transcript info
        ##was## $ftd->{CTSYM} .= $ob->name() . ";";  
        ##now## $trn->{XXX} .= ... and $ftd->{trns} == array of $trn
        $trn= $ftd->{trn}= {};
        $trn->{CTSYM} = $obname; ## $obuniqid
        $trn->{miscfeats}= [];

        $ftd->{trns}= [] unless(exists $ftd->{trns});
        push( @{$ftd->{trns}}, $trn); #? or hash by $obname ?
        }
        
      my $isgene= ($otype eq 'mRNA');
      my ($locs,$loc,$date)= (undef,undef);
      
      $trn->{SQLEN} = $ob->{seqlen};
      $trn->{DT} = cleandate( $ob->{timelastmodified} );   
      
      if ($ftype > 1) {
        $trn->{TYPE}= $otype;  
        $trn->{mRNA}= $ob->getlocation();
        }
        
      if ($ftype == 1) {
        $ftd->{TYPE}= $otype unless ($isgene); #??
        
        $locs = $ob->getlocationSrc($ftd->{srcid},'exon');
        $loc = $ob->getlocationString($locs);
        $trn->{mRNA} = $loc  if $loc;
        
        if ($ob->{residues}) {
          $mrnaresid->{$obname}= [$ob->{seqlen}, $ob->{residues}, $loc];
          }
        
        $ob->addIntrons($locs);
        my $inloc = $ob->getlocationString($locs,'intron');
        push( @{$trn->{miscfeats}}, ['intron', $obname.'-in', $inloc]) if ($inloc);
          
        $loc=''; # ok for !isgene ?
        my $aaloc = $ob->getlocationSrc($ftd->{srcid},'protein');
        if ($aaloc) {
          $ob->insertlocations($aaloc, $locs); ## do utr math also
          $loc = $ob->getlocationString($aaloc); # if $aaloc;
          
          my $uloc = $ob->getlocationString($aaloc, 'five_prime_UTR');  
          push( @{$trn->{miscfeats}}, ['five_prime_UTR', $obname.'-u5', $uloc]) if ($uloc);
          $uloc = $ob->getlocationString($aaloc, 'three_prime_UTR');  
          push( @{$trn->{miscfeats}}, ['three_prime_UTR', $obname.'-u3', $uloc]) if ($uloc);
          }
        $self->{cdsloc}= $loc;
        $trn->{CDS} = $loc;
        }

      }
        
			last SWITCH; 
			};  
			
			## drop this -- need feature_dbxref w/ is_current flag
#     ($otag =~ /^dbxref_id$/ && $depth==1) && do {
#       # dbxref_id now is 'unused' IxAttr ??
#       last SWITCH if ($ob->get('is_internal') == 1);
#       my($tag,$attr)= $ob->id2name('dbxref_id', $ob->{attr});
# 
#       ## check is_current flag for primary/obsolete ids
#       my $iscur= (defined $ob->{is_current}) ? $ob->{is_current} : -1; # == 0/1/null
#       
#       ## patch here? to replace FBgn 2ndary ids w/ primary 
#       ## - need only hashtable lookup of ~ 10k ids; alternate 'sed -f list' takes a long time
#       if (%fbgn2id && $attr =~ /FBgn/) { $attr= $fbgn2id{$attr} || $attr; }
#       
#         ## FIX for TE000 == FBti000
#          if ($iscur == 0) { $ftd->{ID2} .= $attr .$RECSEP; }
#       elsif ($attr =~ /FBgn|FBti/ ) { $ftd->{GID}= $attr; }#&& $db eq 'FlyBase'
#       elsif ($attr =~ /FBan/ ) { $ftd->{ANID}= $attr; }#&& $db eq 'FlyBase'
#       elsif ($attr =~ /^C[GR]\d/ ) { $ftd->{CGSYM}= $attr; }
#       elsif ($attr =~ /^TE\d/ ) { $ftd->{CGSYM} = $attr; } 
#       #elsif ($attr =~ /^TE\d/ ) { $ftd->{SYN} .= $attr.$RECSEP ; } # drop ? save as SYN or ID2?
#       elsif ($attr =~ /^GO:/) {  }
#       else { 
#         warn "MISSED dbxref_id=$attr,$tag\n"; # if $debug;
#         #MISSED dbxref_id=TE19879,dbxref_name - skip thse
#         }
# 			last SWITCH; 
# 			};  


    ($otag =~ /^feature_dbxref$/ && $depth < 4) && do {
      last SWITCH if ($ob->get('is_internal') == 1);  
      
      my($tag,$attr)= $ob->id2name('dbxref_id', $ob->{dbxref_id});
      # my($attr, $db, $dbattr)= $self->getDbXref($ob); # fixed for feature_dbxref
     
      my $iscur= (defined $ob->{is_current}) ? $ob->{is_current} : -1; # == 0/1/null
      my $notdone= 0;
      if ($attr =~ /\S/) { 
        my $dbob= $ob->getid($ob->{dbxref_id}); 
        my($dtag,$db)= $ob->id2name('db_id',$dbob->{db_id});
        # warn "DEBUG: feature_dbxref=$db:$attr, $dbattr\n" if $debug;
        if ($depth == 1) { 
          if ($iscur == 0) { $ftd->{ID2} .= $attr .$RECSEP; }
          else {
            ## patch here? to replace FBgn 2ndary ids w/ primary 
            ## - need only hashtable lookup of ~ 10k ids; alternate 'sed -f list' takes a long time
            if (%fbgn2id && $attr =~ /FBgn/) { $attr= $fbgn2id{$attr} || $attr; }

               if ($attr =~ /FBgn|FBti/ ) { $ftd->{GID}= $attr; } 
            elsif ($attr =~ /FBan/ ) { $ftd->{ANID}= $attr; } 
            elsif ($attr =~ /^C[GR]\d/ ) { $ftd->{CGSYM}= $attr; }
            elsif ($attr =~ /^TE\d/ ) { $ftd->{CGSYM} = $attr; } 
            elsif ($attr =~ /^(SO|GO):/) {  }
            elsif ($attr =~ /^(X|2L|2R|3L|3R|4)$/) {  }
            else { $notdone=1; }
            }
          }
        elsif ($depth > 1 && $attr !~ /^(SO|GO):/) {
          my $dbattr= ($attr !~ m/^$db:/) ?  "$db:$attr"  : $attr; #$db ne $dbid && 
          my @sym= ( $trn->{SYN}, $trn->{CTSYM}, $trn->{AANAM} );
          unless ( $self->checkForVal($attr,@sym) ) { $trn->{SYN} .= $dbattr .$RECSEP; }
          }
        if ($notdone==1) { 
          warn "MISSED feature_dbxref=$db:$attr\n"; # if $debug;
          }
        }
			last SWITCH; 
      };

			
    ($otag =~ /^dbxref$/ && $depth==1) && do {
      last SWITCH if ($ob->get('is_internal') == 1);
      my($attr, $db, $dbattr)= $self->getDbXref($ob);
      my $iscur= (defined $ob->{is_current}) ? $ob->{is_current} : -1; # == 0/1/null

      ## patch here? to replace FBgn 2ndary ids w/ primary 
      if (%fbgn2id && $attr =~ /FBgn/) { $attr= $fbgn2id{$attr} || $attr; }
      
        ## FIX for TE000 == FBti000
         if ($iscur == 0) { $ftd->{ID2} .= $dbattr .$RECSEP; }
      elsif ($attr =~ /^C[GR]\d/ && $db =~ m/FlyBase|Gadfly/i) { $ftd->{CGSYM} = $attr; }
      elsif ($attr =~ /^TE\d/ && $db =~ m/FlyBase|Gadfly/i) { $ftd->{CGSYM} = $attr; }#or ANID?
      elsif ($attr =~ /^FBan/ && $db =~ m/FlyBase/i) { $ftd->{ANID} = $attr; }
      elsif ($attr =~ /^(FBgn|FBti)/ && $db =~ m/FlyBase/i) { $ftd->{GID}  = $attr; }
      elsif ($attr =~ /^GO/ && $db =~ m/GO/i) {  }
      else {
        warn "MISSED dbxref=$db,$attr,$dbattr\n"; # if $debug;
        #MISSED dbxref=GO,GO:0008017,GO:0008017 ?? from what? -- drop
        #MISSED dbxref=FlyBase,CG9884,FlyBase:CG9884 -- r3.2.0-march replaces Gadfly
        #MISSED dbxref=GB,CG18315,GB:CG18315 ???
        }
        
			last SWITCH; 
			};  

    ($otag =~ /^dbxref$/ && ($depth==2 || $depth==3)) && do {
      last SWITCH if ($ob->get('is_internal') == 1);
      my($attr, $db, $dbattr)= $self->getDbXref($ob);
      # ?? use DBA / PAC fields here instead (== dbxref)
      my @sym= ( $trn->{SYN}, $trn->{CTSYM}, $trn->{AANAM} );
      unless ( $self->checkForVal($attr,@sym) ) { $trn->{SYN} .= $dbattr .$RECSEP; }
			last SWITCH; 
			};  

        ## is this nested 2 or 3 levels ?
    ($otag =~ /^feature_synonym$/ && $depth < 4) && do {
      last SWITCH if ($ob->get('is_internal') == 1); # got some here
      my($tag,$attr)= $ob->id2name('synonym_id', $ob->{synonym_id});
      if ($attr =~ /\S/) { 
        if ($depth == 1) { 
          my @sym= ( $ftd->{SYN}, $ftd->{SYM}, $ftd->{GSYM}, $ftd->{CGSYM} );
          unless ( $self->checkForVal($attr,@sym) ) { $ftd->{SYN} .= $attr .$RECSEP; }

#>> IxReadSax XML parse(r3.2_20xmlgz/AE003789_r3.2.chado.xml.gz) error:
# Quantifier follows nothing in regex; marked by <-- HERE in m/ductin,
# vacuolar H(+ <-- HERE )-ATPase subunit C proteolipid/ at
# ChadoSax/src/org/gmod/chado/ix/ToAcode.pm line 743.

          }
        elsif ($depth > 1) {
          my @sym= ( $trn->{SYN}, $trn->{CTSYM}, $trn->{AANAM} );
          unless ( $self->checkForVal($attr,@sym) ) { $trn->{SYN} .= $attr .$RECSEP; }
          }
        }
			last SWITCH; 
      };
      
      
    ($otag =~ /^featureprop$/ && $depth<3) && do {
      last SWITCH if ($ob->get('is_internal') == 1);

      my $attr= $ob->{attr};
      last SWITCH if ($attr =~ m/internal view|internal comment/); 
      # 'internal view only' is not clean data, have these:
      # (internal view on        ly)
      # (internal viewonly)
      # (internal comment)
      
      my($tag,$db)= $ob->id2name('type_id', $ob->{type_id});
      my $notdone= 0;
      
      # mar04 - drop all ::DATE: text
      $attr =~ s/\s*::DATE:.*//;
       
#       # dec03 - drop '::TS:1035389518000 ' from comments; all featprop?
#       # reporter should reformat dates nicely.
#       # ...blah intron::DATE:2002-10-23 12:11:58::TS:1035389518000; 
#       # CMT|trans spliced::DATE:Wed Jan 22 23:40:09 PST 2003 <<? to short date: 20030122 
#       $attr =~ s/::TS:\d+//;
#       if ($attr =~ s/::DATE:/ DATE:/) {
#         $attr =~ s/\s+\d\d:\d\d:\d\d\s*$//; ## drop hour:min:sec jazz
#         }
        
      $attr =~ s/[\n\r]/ /g;
      if ($db eq 'comment') { $attr =~ s/^Comment:\s+//i; }
        
      #?? use @skip_props and add anything else as CMT or PEPST  or PEPCMT?
      if ($attr !~ /\S/) {}
      elsif ($db eq 'gbunit') {
        $ftd->{SCAF}= $attr;
        }
      elsif (grep(/^$db$/, @skip_props)) {
        $notdone= 0;
        }
      elsif ($depth == 1) {
           if ($db eq 'sp_status') { $ftd->{PEPST} .= "$db=$attr".$RECSEP ; }
        elsif ($db eq 'cyto_range') { $ftd->{CLOCC} .= $attr . $RECSEP ; }
        elsif ($db eq 'symbol' || $db eq 'encoded_symbol') { 
          my @sym= ( $ftd->{SYN}, $ftd->{SYM}, $ftd->{GSYM}, $ftd->{CGSYM} );
          # unless (grep /$attr/, @sym) { $ftd->{SYN} .= $attr .$RECSEP; }
          unless( $self->checkForVal($attr,@sym) ) { $ftd->{SYN} .= $attr .$RECSEP; }
          }
        ##elsif (grep(/^$db$/, @cmt_props))  
        else {
          $ftd->{CMT} .= "$db=$attr".$RECSEP ; $notdone= 0;
          }
        }
        
      else {
        $trn->{PEPCMT} .= "$db=$attr".$RECSEP ; $notdone= 0;
        }
      
        
      warn "MISSED featureprop= $attr,$tag,$db [lev=$depth]\n" if ($notdone); #  && $debug
      ## add these...
      
      ## >> featureprop= true,type_name,dicistronic
      # MISSED featureprop= unusual splice,type_name,validation_flag
      # MISSED featureprop= D.melanogaster FlyBase-curated sequence: Slh.v003,type_name,description

      ##?? featureprop= GCC,type_name,anticodon -- tRNA prop
      ##?? featureprop= Gly,type_name,aminoacid -- tRNA prop

      # MISSED featureprop= diver2,type_name,element
      # MISSED featureprop= CG17410,type_name,encoded_symbol
          # what is encoded_symbol ??

      ##?? featureprop= AAF45927,type_name,protein_id
      ##done## featureprop= all done,type_name,status
      ##done## featureprop= 4B3-4B3,type_name,cyto_range == CLOCC
      ##done## featureprop= true,type_name,problem
      ##done## featureprop= CG32009,type_name,symbol - have elsewhere **? not always??
        ## ^^ save as synonym if not already in symbol set ?
        
      # also got 'sp_status', sp_comment 'cyto_range' ..
      
			last SWITCH; 
			};  
			
    ($otag =~ /^feature_cvterm$/) && do {
      # go term - need GO:id also - need to check db: not always GO ...
      last SWITCH if ($ob->get('is_internal') == 1);
      my $cvft= $ob->get('cvterm_id'); # attr?
      $cvft= $ob->getid($cvft) if ($cvft);
      if ($cvft) {
        my $nm= $cvft->name();
        my @attr= $cvft->getattrs("dbxref"); 
        foreach my $attr (@attr) {  
          my($attr2, $db, $dbattr)= $self->getDbXref($attr);
          if ($db eq 'GO') {
            $ftd->{GO} .= "\n|" if ($ftd->{GO}); 
            $ftd->{GO} .= "$nm ; $dbattr";
            }
          } 
        }
        
#     cvterm = {
#       id=cvterm_1862
#       cv_name=cellular_component
#       name=pyruvate dehydrogenase (lipoamide) phosphatase (sensu Eukarya)
#       dbxref={ GO:0019910, db_name=GO, id=dbxref_1841 } 
#       }

			last SWITCH; 
			};  
			
			
    ($otag =~ /^prediction_evidence$/) && do {
      ## has feature.feature. ... substructure
      last SWITCH if ($ob->get('is_internal') == 1);
     
      my $anid= $ob->get('analysis_id');
      my $anh = $evd->{$anid};
      unless(defined $anh) { 
        $evd->{$anid}= $anh= {};  
        my $anft;
        my $top= $ob->topnode();
        if (ref $top && $top->can('getfeatbyid')) {
          $anft= $top->getfeatbyid( $anid, 'analysis');
          }
        if ($anft) {
          $anh->{PROGRAM}= $anft->{program}; # program=blastx_masked
          $anh->{DATABASE}= $anft->{sourcename} || undef;  # sourcename=aa_SPTR.worm 
        } else {
          my($ntag,$aname)= $ob->id2name('analysis_id',$anid);
          $anh->{PROGRAM}= $aname; 
          }
       # warn "# evd $otag: $anid = $anh->{PROGRAM} \n" if ($debug);
      }
      
      my @fts= $ob->getfeats('feature');
      if (@fts) {
      my $ft= shift @fts; # only 1 ??
      my $loc= $ft->getlocation( $ftd->{srcid});
      my $dt= cleandate($ft->{timelastmodified}); 
      $anh->{mRNA} .= $loc .$RECSEP;  
      $anh->{DT}  = "$dt" if $dt;   

        #type for prediction is same feature level as loc; not for alignment
      my($tag,$type)= $ft->id2name('type_id',$ft->{type_id});
      $anh->{TYPE}= $type if ($type);
      
      @fts= $ft->getfeats('feature'); # find dbx names
      foreach my $dft (@fts) {
        next if ($dft->{id} eq $ftd->{srcid});
        my $dbname= $dft->name();
        $anh->{mRNA_dbx} .= $dbname .$RECSEP;
        ($tag,$type)= $dft->id2name('type_id',$dft->{type_id});
        $anh->{TYPE}= $type if ($type);
        last;
        }
      }
      
      $dolist= $doatts= 0; # no more recurse ??
			last SWITCH; 
			};  


    ($otag =~ /^alignment_evidence$/) && do {
      ## has feature.feature.feature. ... substructure
      last SWITCH if ($ob->get('is_internal') == 1);
       
      my $anid= $ob->get('analysis_id');
      my $anh= $evd->{$anid};
      unless(defined $anh) { 
        $evd->{$anid}= $anh= {};
        $anh->{analysis_id}=  $anid; 
        my $anft;
        my $top= $ob->topnode();
        if (ref $top && $top->can('getfeatbyid')) {
          $anft= $top->getfeatbyid( $anid);
          }
          
        if ($anft) {
          $anh->{PROGRAM}= $anft->{program}; # program=blastx_masked
          $anh->{DATABASE}= $anft->{sourcename} || undef;  # sourcename=aa_SPTR.worm 
        } else {
          my($ntag,$aname)= $ob->id2name('analysis_id',$anid);
          $anh->{PROGRAM}= $aname; 
          }
       # warn "# evd $otag: $anid = $anh->{PROGRAM} \n" if ($debug);
      }
      
      $dolist= $doatts= 0; # no more recurse ??
      last SWITCH
        if ($anh->{PROGRAM} eq 'locator' && $anh->{DATABASE} eq 'cytology');
        
      my @fts= $ob->getfeats('feature');
      if (@fts) {
      my $ft= shift @fts; # only 1? - 1 top level, many subfeature 'match'
      my $loc= $ft->getlocation(  $ftd->{srcid},'match');
      my $dt= cleandate($ft->{timelastmodified}); 
      $anh->{mRNA} .= $loc.$RECSEP; ## FIXME - which ??
      $anh->{DT}  = "$dt" if $dt;   
      
        ## dang need feature.feature kids here . but only 1st of them?
      @fts= $ft->getfeats('feature'); # find dbx names
      @fts= $fts[0]->getfeats('feature') if (@fts); 
      foreach my $dft (@fts) {
        next if ($dft->{id} eq $ftd->{srcid});

        my $dbname= $dft->name();
        my $dbx= $dbname; # default
        
        ## need db:name if have dbxref={ Mm#S1972531, db_name=UG, id=dbxref_50625 } dbxref_name=Mm#S1972531 
        ## may have dbxref_id instead of dbxref  
        my @dfattr= $dft->getattrs("dbxref"); # can be many - try to match dbname
        push(@dfattr, $dft->getattrs("dbxref_id"));  
        if (@dfattr) {
          my $di2= 0;
          foreach my $di (0..$#dfattr) {
            my($attr, $db, $dbattr)= $self->getDbXref( $dfattr[$di] );
            $dbattr =~ s/;//g;
            next unless($dbattr =~ /\S/);
            if ($di2++ == 0 || $dbattr =~ /$dbname/) { $dbx= $dbattr ; }
            #?? save all dbattr
            } 
          $dbx =~ s/;//g;
          if ($dbx !~ m/\S/) { $dbx= $dbname; }
          elsif ($dbx !~ m/$dbname/) { $dbx .= " , $dbname"; }
          }
        $anh->{mRNA_dbx} .= $dbx .$RECSEP; 
        # $anh->{mRNA_dbx2} .= $dbname .';' ; 

        my($tag,$type)= $dft->id2name('type_id',$dft->{type_id});
        $anh->{TYPE}= $type if ($type);
  
          ## EST only if DB|na_EST.all_nr.dros and/or? DB|na_DGC.dros
        if ($type eq 'EST' && $anh->{DATABASE} =~ /\.dros/) { 
          my $v= $dbname; $v =~ s/[:_\.].*//;
          $ftd->{EST} .= $v .$RECSEP unless($ftd->{EST} =~ m/$v$RECSEP/); 
          }
        elsif ($type eq 'cDNA_clone') { 
          my $v= $dbname;  
          $ftd->{CDNA} .= $v .$RECSEP unless($ftd->{CDNA} =~ m/$v$RECSEP/);  
          }
        elsif ($type eq 'oligonucleotide') { 
          my $v= $dbname; $v =~ s/_at_\d+/_at/;
          $ftd->{AFFY} .= $v .$RECSEP unless($ftd->{AFFY} =~ m/$v$RECSEP/); 
          }
        
        last; #? only 1
        }
      }
      
      $dolist= $doatts= 0; # no more recurse ??
			last SWITCH; 
			};  
  
  $nada= 1;
  }

  ## recursion start ......
  ## from IxFeat.pm - move back there...
  ## includes dbxref , featureprop .. ?
  if ( $doatts && defined $ob->{attrlist} ) {
    foreach (@{$ob->{attrlist}}) { 
      # $_->handleObj(1+$depth, $self);  
      $self->handleObj(1+$depth, $_);  
      }
    }

  if ($dolist && defined $ob->{list} ) {
    foreach (@{$ob->{list}}) { 
      # $_->handleObj(1+$depth, $self);  
      $self->handleObj(1+$depth, $_);  
      }
    }
  ## recursion end ......
  
  if ($depth == 0 && $ftd->{ID}) 
  {
    my @elist= values( % $evd );
    $self->{defline}='';   
    my $outh= $self->{outh};
    my $ftout= $self->{ftout};
    $ftd->{VERS}= $self->{VERS}; # data version from where?
    $self->fbanAcode( $outh, $ftd, $ftout,\@elist); ##, $FTOUT, \%ca);
    
    my $chr= $ftd->{ARM};
    my $defline= $self->{defline}; # fbanAcode() makes this
    my $type='protein'; # $ftd->{TYPE} || << not 'gene'
    $outh= $self->{faout};
    my $resid= $aaresid;
    if (scalar %$resid && $outh) {
      foreach my $aa (sort keys %$resid) {
        my $alen= $resid->{$aa}->[0];
        my $ares= $resid->{$aa}->[1];
        my $loc = $resid->{$aa}->[2];
        print $outh ">$aa feature: $type loc=$chr:$loc;$defline;len=$alen\n";
        $ares =~ s/(.{1,50})/$1\n/g; 
        print $outh $ares; 
        }
      }

    $type= $ftd->{TYPE} || 'mRNA'; #<< type of depth==0 is gene...
    $type= 'mRNA' if ($type eq 'gene');
    $outh= $self->{fnout};
    $resid= $mrnaresid;
    if (scalar %$resid && $outh) {
      foreach my $aa (sort keys %$resid) {
        my $alen= $resid->{$aa}->[0];
        my $ares= $resid->{$aa}->[1];
        my $loc = $resid->{$aa}->[2];
        print $outh ">$aa feature: $type loc=$chr:$loc;$defline;len=$alen\n";
        $ares =~ s/(.{1,50})/$1\n/g; 
        print $outh $ares; 
        }
      }

    ## need to delete some $self data here after dump
    # delete $evd->{xxx};
    
    }
    
}

## dang regex parse err... how to get perl not to interpolate?
#>> IxReadSax XML parse(r3.2_20xmlgz/AE003789_r3.2.chado.xml.gz) error:
# Quantifier follows nothing in regex; marked by <-- HERE in m/ductin,
# vacuolar H(+ <-- HERE )-ATPase subunit C proteolipid/ at
# ChadoSax/src/org/gmod/chado/ix/ToAcode.pm line 743.

sub checkForVal {
  my $self= shift;
  #my @sym= ( $ftd->{SYN}, $ftd->{SYM}, $ftd->{GSYM}, $ftd->{CGSYM} );
  ##  unless (grep /$attr/, @sym) { $ftd->{SYN} .= $attr .$RECSEP; }
  my $attr= shift;
  my @sym= @_;
  foreach my $sym (@sym) {
    ##return 1 if ($sym eq $attr);
    return 1 if (index($sym,$attr)>=0);
    }
  return 0;
}

#--------------- acode writer from parsegame4.pl -------------------------------

my @skipkeys= (); # dont really want to skip dbxref, but needs fixing
my %skipkeys= ();
#my %deflineKeys=();

BEGIN {
#   @skipkeys= qw/dbxref CDS mRNA TYPE/;
#   %skipkeys= map { $_ => 1; } @skipkeys;
 %deflineKeys=(
      ID => 'ID=',
      GID => 'gene_id=',
      # ARM => 'chr=', ## do as part of loc=X:100..200
      GSYM => 'gene_sym=',
      CGSYM => 'sym=',
      SCAF => 'scaffold=',
      CLA => 'type=', #??
      );
}

=item sub fbanAcode()

acode writer for fly annotation data
see, eg. ftp://flybase.net/flybase-data/acode/data/FBan*.acode

from  flybase/datagen/parsegame4.pl

=cut

sub fbanAcode {
	my $self = shift;
  my($outh, $ftd, $ftout, $ca)= @_; # array refs of keys, values
  my %h= %$ftd;
 
  #my $fsplit= '\n\|';
  my $fsplit= $RECSEP; # ';';	  
  ##FIXME## use of ';' or '\n\|' field value seps is bad; change logic
  
  # cleanup trailing ;
  foreach my $k (keys %h) { $h{$k} =~ s/$RECSEP$//; } 
	$h{CLOCC} =~ s/$RECSEP\s*$//; # what is this bug - two seps??
	# foreach my $k
	#  (qw/BLOC mRNA CTSYM DT AALEN AANAM CDS SQLEN GO CLOCC PEPST PEPCMT CMT AFFY EST CDNA/) 
	#  { $h{$k} =~ s/$RECSEP$// if $h{$k}; }     
  
  # return unless($h{TYPE} eq 'gene'); ## FIXME for CR ...
  my @id2= ();
  my $type= ($h{TYPE} eq 'gene') ? '' : $h{TYPE};
  my $anid = $h{ANID}; #?? what if null?
  my $uniqid= $h{ID}; # mar04
  
  my $gsym = $h{GSYM}  || $h{CGSYM}; 
  my $cgsym= $h{CGSYM} || $gsym;
  my $sqlen= $h{GNLEN}; ##sqlen($h{BLOC});
  my $gid= $h{GID}; 
  my $arm= $h{ARM};
  my @re= ();
  my $gensr;


=item    
    # argh! mar04, got 'transposable_element_insertion_site' as new top-level feature
    # was EVD
EVD 
{
PRG|pinsertion
CLA|transposable_element_insertion_site
DT|20030927
DBX|FlyBase:FBti0007940 , P{EP}CG3308[EP1230]
BLOC|17099533..17099534
}
=cut 
   
  if ($uniqid) {
    if ($uniqid !~ /FBan\d/) {
      if ($uniqid =~ m/^C[GR]0*(\d+)/) { $uniqid= sprintf("FBan%07d",$1); }
      elsif ($uniqid =~ m/^TE0*(\d+)/) { $uniqid= sprintf("FBan%07d",( FBTI_IDBASE + $1)); }
      }
    if ($uniqid ne $anid) { push(@id2,$anid) if $anid; $anid= $uniqid; }
    }

  if ($type eq 'transposable_element' || $gid =~ /FBti\d/) {
    #? is this kosher? cgsym = anid = TE19568; there should be an FBti value in data...    <accession>FBti0019122</accession>
    ## no - either put TE into separate FBan-te.acode, or revise FBanID num
    if ($gid !~ /FB\w\w\d+/) { $gid = $cgsym; $gid =~ s/TE/FBti/; }  
    if ($anid !~ /FBan\d/) {
       if ($anid =~ m/^TE0*(\d+)/) { $anid= sprintf("FBan%07d",( FBTI_IDBASE + $1)); }
       elsif ($cgsym =~ m/^TE0*(\d+)/) { $anid= sprintf("FBan%07d",( FBTI_IDBASE + $1)); }
       }
    
#     $anid = $cgsym; 
#     if ($cgsym =~ m/TE0*(\d+)/) { ##? is TE/FBti id distinct from FBan id num range? NO
#       $anid = $1;
#       $anid = sprintf("FBan%07d",( FBTI_IDBASE + $anid)); ## this is bad; conflicts with CGnn/FBan
#       }
      
    $cgsym= $gsym;
    $gensr  = "INSR\n{\n"; #?? INSR = TIR subrec ? will this TIRecord cause problems?
    $gensr .= "SYM|$gsym\n"; 
    $gensr .= "ID|$gid\n}\n";
    push(@re,"ID 1 $anid");
    push(@re,"GID 1 $gid") if ($gid);
    push(@re,"GSYM 1 $gsym"); #SYM keep same as FBgn GSYM??
    push(@re,"CGSYM 1 $cgsym") if ($cgsym); # dup of SYM !? leave out
    }
    
    
=item

 mar04 - change this ID decision logic ; <uniquename>CGnnn is now the
 prefered/valid ID, generate FBan from this always, can save (multiple) old
 FBan as 2ndary ID list (ID2)
 
=cut

=item

  mar04; check FBti/FBan overlap ---
grep '^RETE' FBan.acode | \
perl -e'($md,$mt,$mc)=(0,0,0);while(<>){ \
  /ID 1 FBan0*(\d+)/ && do {$d=$1; $nd++; $md=$d if ($d>$md);}; \
  /FBti0*(\d+)/ && do {$t=$1; $nt++; $mt=$t if ($t>$mt);};\
  /CGSYM 1 C[GR]0*(\d+)/ && do {$c=$1; $nc++; $mc=$c if ($c>$mc);};\
  } print "FBan n=$nd; max=$md\nFBti n=$nt; max=$mt\nC[GR] n=$nc; max=$mc\n";'
    
FBan n=15411; max=33214
FBti n=1578; max=20453   << quick fix:  FBan0050000+idnum ? or FBan0100000+idnum
C[GR] n=13833; max=33214

  patch FBti FBan ids with +50000 ---
     
cat FBan.acode |\
perl -p -e'BEGIN{$an=$anold="";} if (/^RETE/ && /FBti0*(\d+)/) { $t=$1; \
 /ID 1 FBan0*(\d+)/ && do { $d=$1; \
  $an=sprintf("FBan%07d",(50000+$d)); s/(FBan\d+)/$an/g; $anold=$1; } } \
 elsif (m,^ID\|$anold,) { s,^ID\|$anold,ID\|$an,; $anold="xxx";}' \
  > fbanr.acode
  
=cut
  
  ## check here if GID = FBti other data class, write proper subrecord?
  elsif ($gid =~ /FB..\d/) {
    if ($anid !~ /FBan\d/) {
       if ($anid =~ m/^C[GR]0*(\d+)/) { $anid= sprintf("FBan%07d",$1); }
       elsif ($cgsym =~ m/^C[GR]0*(\d+)/) { $anid= sprintf("FBan%07d",$1); }
       }
    push(@re,"ID 1 $anid");
    push(@re,"GID 1 $gid");
    push(@re,"GSYM 1 $gsym");
    push(@re,"CGSYM 1 $cgsym");
    $gensr= "GENSR\n{\n";
    $gensr .= "GSYM|$gsym\n";
    $gensr .= "ID|$gid\n}\n";
    }
  else {
    #if ($anid !~ /\d/ && $cgsym =~ m/^C[GR](\d+)/) { $anid=sprintf("FBan%07d",$1); }
    if ($anid !~ /FBan\d/) {
       if ($anid =~ m/^C[GR]0*(\d+)/) { $anid= sprintf("FBan%07d",$1); }
       elsif ($cgsym =~ m/^C[GR]0*(\d+)/) { $anid= sprintf("FBan%07d",$1); }
       }
    push(@re,"ID 1 $anid") if ($anid);
    push(@re,"GSYM 1 $gsym") if ($gsym); #SYM keep same as FBgn GSYM??
    push(@re,"CGSYM 1 $cgsym") if ($cgsym);
    }
  push(@re,"CLA 1 $type") if $type;
  push(@re,"ARM 1 $arm") if $arm;
  push(@re,"CLOC 1 $h{CLOCC}") if $h{CLOCC};

  push(@re,"SCAF 1 $h{SCAF}") if $h{SCAF}; 
  ## re = add BLOC? or use FBid for gbrowse map / cytomap?
  
# $h{GO} -> acode flds now are FNC/ENZ/CEL - use GO field 
# now have goterm == goid ; goterm2 == goid2 ...
# ?? drop single FNC - confusing - add count of FNC ?
		my $go='';
		if( $h{GO} ) {
    	$go= $h{GO}; 
    	$go =~ s/ == / ; /g;
# 			my @headgo= split("\n",$go); 
# 			$headgo[0] =~ s/^([^;\n]+)[;\n].+$/$1/; 
# 			push(@re,"FNC ".scalar(@headgo)." ".$headgo[0]); 
    	}
   
		my $dt='';
		my @dt= split(/$RECSEP/,$h{DT}); #? is there a date field in each ct rec?
		if (@dt) { @dt= sort { $b <=> $a } @dt; $dt= shift @dt; }

    my @trns= ();
    @trns= @{$ftd->{trns}} if(ref $ftd->{trns}); 

# 	## dang - need to filter out CLNSR = trns->{TYPE}
		## push(@re,"TRREC ".scalar(@trns)) if @trns;  
		
		my @aa=(); my @bl=(); my $ntr= 0;
		foreach my $trn (@trns) {
		  foreach my $tk (keys %$trn) { $trn->{$tk} =~ s/$RECSEP$//; }# cleanup trailing ;
		  push(@aa, $trn->{AALEN}) if $trn->{AALEN};
		  push(@bl, $trn->{mRNA}) if $trn->{mRNA};
		  $ntr++ unless($trn->{TYPE});
		  }
		push(@re,"TRREC ".$ntr) if $ntr;  
		push(@re,"AALEN ".scalar(@aa)." ".$aa[0]) if @aa;  
		##drop##push(@re,"SQLEN ".scalar(@sl)." ".$sl[0]) if @sl;  #gene $sqlen ??

		my $defline='';
		foreach my $r (@re) {
		  my($k,$n,$v) = split ' ',$r;
		  if ($deflineKeys{$k}) {
		    $defline .= ';' if $defline;
		    $defline .= $deflineKeys{$k}.$v;
		    }
		  }
		$self->{defline}= $defline; # save for residue fasta
		
		my $re= join("\t",@re);
	  print $outh <<TEOF;
GADR
{
RETE|$re
ID|$anid
SYM|$cgsym
$gensr
TEOF
		print $outh "CLA|$type\n" if $type;
		print $outh "ARM|$arm\n" if $arm;
		print $outh "SCAF|$h{SCAF}\n" if $h{SCAF};
		print $outh "BLOC|$h{BLOC}\n" if $h{BLOC};
		print $outh "CLOCC|$h{CLOCC}\n" if $h{CLOCC};
		print $outh "SQLEN|$sqlen\n" if $sqlen; ##$h{SQLEN};
		print $outh "GO|$go\n" if $go;
		print $outh "SYN|".join("\n|",split(/$RECSEP/,$h{SYN}))."\n" if $h{SYN};
		
		push( @id2, split(/$RECSEP/,$h{ID2})) if $h{ID2};
	  print $outh "ID2|".join("\n|",@id2)."\n" if @id2;

		print $outh "CDNA|".join("\n|",split(/$RECSEP/,$h{CDNA}))."\n" if $h{CDNA};
		print $outh "EST|".join("\n|",split(/$RECSEP/,$h{EST}))."\n" if $h{EST};
		print $outh "AFFY|".join("\n|",split(/$RECSEP/,$h{AFFY}))."\n" if $h{AFFY};

      #?? split these, others on /;/ ??
		print $outh "PEPST|".join("\n|",split(/$RECSEP/,$h{PEPST}))."\n" if $h{PEPST};
		 
    my $gcm = join("\n|", split(/$RECSEP/,$h{CMT}));
	  $gcm =~ s/^\s*//; 
	  $gcm = wrapLong($gcm);
    print $outh "CMT|$gcm\n" if ($gcm);
		#print $outh "CMT|".join("\n|",split(/$RECSEP/,$h{CMT}))."\n" 
		#  if ($h{CMT} && $h{CMT} !~ /internal view/); # forgot that last
		
		print $outh "DT|$dt\n" if $dt;
		
    my $dbx ='';
    $dbx .= $AnnoDbName.$cgsym;
    $dbx .= ' ; ' . $GeneDbName . $anid if ($anid ne $gid);
# 		$dbx =~ s/[;\s]+$//;

    my $gloc= $h{BLOC};
    $gloc= $bl[0] if ($type && $type ne 'gene' && @bl && $bl[0] =~ /\d/);
      
      ## fixme here for tRNA, others w/ exon structure - replace BLOC w/ mRNA $bl[0]
      ## if @trn>1 need many feat lines.
    $self->printFeature($ftout, $arm, $type || 'gene', 
        $gsym, $h{CLOCC}, $gloc, $gid, $dbx) if $ftout;

		foreach my $trn (@trns) 
		{
			my $nm=  $trn->{CTSYM};  
			my $aa=  $trn->{AALEN}; 
			my $aan= $trn->{AANAM}; 
			my $sl=  $trn->{SQLEN}; 
			my $bl=  $trn->{mRNA}; 
			my $cds= $trn->{CDS}; 
			my $dt=  $trn->{DT}; 
			my $cm=  $trn->{PEPCMT}; 
			my $subr= $trn->{SUBREC}; 

      ## need tp split bloc by length -- some are very long
			$sl .= ' (-)' if ($sl && $bl =~ /complement/);
      $bl = wrapLong($bl);
      $cds= wrapLong($cds); #? store only translation offset?

		  $cm= join("\n|",split(/$RECSEP/,$cm));
      $cm =~ s/^\s*//; $cm = wrapLong($cm);

      my $ttype= $trn->{TYPE};
      if ($ttype) {
        # note: CLNSR = flybase.clone.Clone subrecord, not used, mar04
        print $outh "CLNSR\n{\n";
        print $outh "CLA|$ttype\n" if $ttype; # FIXME
        print $outh "NAM|$nm\n" if $nm;
    		print $outh "SYN|".join("\n|",split(/$RECSEP/,$trn->{SYN}))."\n" if $trn->{SYN};
        print $outh "SQLEN|$sl\n" if $sl; # none of these ?
        print $outh "BLOC|$bl\n" if $bl;
        print $outh "CMT|$cm\n" if $cm;
        print $outh "DT|$dt\n" if $dt; #? could get, not
        print $outh "}\n";
      } else {
        # note TRREC = flybase.egad.Transcript subrecord
        print $outh "TRREC\n{\n";
        print $outh "NAM|$nm\n" if $nm;
    		print $outh "SYN|".join("\n|",split(/$RECSEP/,$trn->{SYN}))."\n" if $trn->{SYN};
        print $outh "AANAM|$aan\n" if $aan;
        print $outh "SQLEN|$sl\n" if $sl;
        print $outh "AALEN|$aa\n" if $aa;
        print $outh "BLOC|$bl\n" if $bl;
        print $outh "CDS|$cds\n" if $cds;
        print $outh "CMT|$cm\n" if $cm;
        print $outh $subr if $subr;
        print $outh "DT|$dt\n" if $dt;
        print $outh "}\n";
      }
      
      next if (@bl <= 1 && $type =~ /RNA/);# dont dup features for noncoding RNAs 
        # ^^-- this was bad, tRNA other has exon struct needed in feature table
      next unless($ftout);
      
      my $note;  
      $ttype ||= 'mRNA';
      $dbx  = $AnnoDbName . $cgsym;
      $dbx .= ' ; '. $GeneDbName . $gid if ($gid);
      
      ## need unwrapped $bl, $cds for feats
      $bl=  $trn->{mRNA}; 
      $note= ($gsym && $nm !~ /^$gsym/) ? "gene=".$gsym : '';
      $self->printFeature($ftout, $arm, $ttype, $nm, '', $bl, $AnnoDbName.$nm, $dbx, $note) 
        if ($bl);
        
			$cds= $trn->{CDS}; 
      $note= ($gsym && $aan !~ /^$gsym/) ? "gene=".$gsym : '';
      $self->printFeature($ftout, $arm, 'CDS', $aan, '', $cds, $AnnoDbName.$aan, $dbx, $note) 
        if ($cds);
      
      ## mar04: ADD printFeature : 5,3 UTR; intron_set for each gene
      $note= ''; # ($gsym) ? "gene=".$gsym : '';  
      $nm ||= $cgsym;
      my $nmisc= 1;
      my @morefeats= @{$trn->{miscfeats}};
      foreach my $ftr (@morefeats) {
        my $fnm= $ftr->[1] || $nm.'-'.$nmisc; ++$nmisc;
        $self->printFeature($ftout, $arm, $ftr->[0], $fnm, '',$ftr->[2], '', $dbx, $note);
	      }
	    	    
	  }

	  if (ref($ca) =~ /ARRAY/) { $self->evidAcode( $outh, $ca, $ftout, $arm ); }
#   if ($ca && $ca->{$h{CGSYM}}){ evidAcode( $outh, $ca->{$h{CGSYM}}  ); }
	  
	  my %did= map { $_,1; } 
	    qw/ANID ID ID2 GID GSYM GNLEN ARM CLOC CGSYM SCAF BLOC mRNA CTSYM 
        DT AALEN AANAM CDS SQLEN GO CLOCC PEPST PEPCMT CMT SYN
        AFFY EST CDNA TYPE ENAM srcid residues trns trn aaresid mrnaresid/;
    foreach my $k (sort keys %h) {
      if($k =~ /\w/ && !$did{$k}) { print $outh "$k|$h{$k}\n"; }
      }

# VERS|$vers
	print $outh "\n}\n\# EOR\n\n";
}



sub evidAcode {
	my $self = shift;
	my($outh, $eref, $ftout, $arm)= @_;  
  my @kv= @$eref;  ## array of evd hash
#   ## need to use mRNA_dbx ids matched to BLOC's -- turn into subrec??
  #?? skip feature dump of prg==genscan, type==exon ??
  # exon    NULL:2347151    -       35560..36843 
  
  foreach my $v (@kv) {
    my %h= %$v; ##= (); 
    
    next if ($h{PROGRAM} eq 'locator' && $h{DATABASE} eq 'cytology');
    my $earm= $h{ARM} || $arm;
    my $type= $h{TYPE};
    unless ($type) {
      $type= $h{PROGRAM};#?.':'.$h{DATABASE};
      $type= 'transposable_element' if ($type =~ /JOSHTRANSPOSON/i);
      #^^ this is cause of dupl TE feature table entries? skip for feats() here?
      }
      
    print $outh "EVD\n{\n";
    print $outh "NAM|$h{ENAM}\n" if $h{ENAM};
    print $outh "PRG|$h{PROGRAM}\n" if $h{PROGRAM};
    print $outh "DB|$h{DATABASE}\n" if $h{DATABASE};
    print $outh "CLA|$type\n" if $type;
    print $outh "DT|$h{DT}\n" if $h{DT};
    my @bl= split(/$RECSEP/,$h{mRNA}); # many of these per program/db/type
    my @db= split(/$RECSEP/,$h{mRNA_dbx}); # many of these per program/db/type
    # my @db2= split(/$RECSEP/,$h{mRNA_dbx2}); # many of these per program/db/type
    foreach my $bl (@bl) {
      my $blun= $bl;
      $bl = wrapLong($bl); 
      my $dbx = shift @db;
      print $outh "DBX|$dbx\n" if $dbx;
      print $outh "BLOC|$bl\n" if $bl;
      
      # DBX|FlyBase:FBti0007364 , EP(X)0448
      # DBX|GB:X07656
      my $nm= $dbx; $nm =~ s/^\S+\s*,\s*//;
      $nm =~ s/_at_\d+/_at/ if ($type eq 'oligonucleotide');
      #?? or $id == null for many of these?
      my $id= $dbx; $id =~ s/\s*,.+$//;
      $id= '' if ($id eq $nm); #??
      
      ## noname -- $nm= $h{PROGRAM}.":". $h{DATABASE} unless($nm);
      my $nofeat=0;
      $nofeat= 1 if ($type eq 'transposable_element' && !$nm);
      $nofeat= 1 if ($type eq 'exon');
      
      $self->printFeature($ftout, $earm, $type, $nm, '', $blun, $id, '') 
        if ($bl && $ftout && !$nofeat);
      }
    print $outh "}\n";
    }
}


sub wrapLong {
  # wrap long lines for acode
  # FIXME - check for "\n" already in $rng
  my $rng= shift;
  my $nl = shift || "\n|";
  my $nlen= length($nl);
  my $al;
  
	if (length($rng)>80) {	
		my ($at0, $at, $r2)= (0,0,'');
		while ($at0>=0) {
		  $at= index($rng,$nl,$at0); $al= $at - $at0;
		  if ($at>=0 && $al<=80) { $at += $nlen; $r2 .= substr($rng,$at0,$at-$at0);  $at0= $at;  }
		  else {
		  $at= index($rng,"\n",$at0); $al= $at - $at0;
		  if ($at>=0 && $al<=80) { $r2 .= substr($rng,$at0,$at-$at0) . $nl; $at++; $at0= $at;  }
		  else {
        $at= index($rng,",",$at0+60);
        if ($at<=0) { $at= index($rng,";",$at0+60); }
        if ($at<=0) { $at= index($rng," ",$at0+60); }
        if ($at>0) { $at++; $r2 .= substr($rng,$at0,$at-$at0) . $nl; $at0= $at; }
        else { $r2 .= substr($rng,$at0); $at0= -1; }
        }
       }
		  }
	  $rng= $r2;
		}
  return $rng;
}


=head2  printFeature()

  print feature table entry, in gnomap-version-1 format,
  with addition of leading Chr/Arm and bloc for sorting
  call:
    printFeature($ftout, $h{ARM}, 'gene', $gsym, $h{CLOCC}, $h{BLOC}, $gid, $dbx)  
  output:
    print "$csome\t$bstart\t$feat\t$gsym\t$cloc\t$range\t$id\t$dbxref\n";
  
=cut

sub printFeature {
	my $self = shift;
	my($ftout,$csome,$feat,$gsym,$cloc,$range,$id,$dbxref,$note)= @_; # array refs of keys, values

  # return unless $ftout;
  unless($range && $feat) {
    warn "# feature error: $csome\t$feat\t$gsym\t$range\t$id\n"; # skip bogus features
    return;
    }
  $csome='-' unless($csome);
  $feat= '-' unless($feat);
	$gsym= '-' unless($gsym);
	$cloc= '-' unless($cloc);
  $range='-' unless($range);
	$id= '-' unless($id);
	$dbxref= '-' unless($dbxref);
  ## ignore $note - not used
	# $note= '-' unless($note);

  my $bstart= ($range =~ m/([-]?\d+)/) ? $1 : 0;
  $dbxref =~ s/;*\s*$id// if (index($dbxref,$id)>=0);
  $dbxref .= "\t$note" if ($note);
  # want hash check if this is dupl ... $csome\t$feat\t$gsym\t$range\t$id only?
  print $ftout "$csome\t$bstart\t$feat\t$gsym\t$cloc\t$range\t$id\t$dbxref\n"; #\t$note
}



=head2 	putIndex()

=cut

sub putIndex {
	my($idx,$at,$e2,$idnum)= @_;
	my $size= $e2 - $at;   
	my $record= pack("NN", $at, $size); # should be "NN" for platform independent
	my $idloc = int( $idnum * IDXRECSIZE);
	seek($idx, $idloc, 0);  
	print $idx $record;
}

=head2 	indexAcode($acodefile,$idtag,$id2tag)

=cut

sub indexAcode {
	my($aaf,$idtag,$id2tag)= @_;
	local(*AA,*IDX,*IDX2);
	warn "# indexAcode($aaf,$idtag,$id2tag)\n" if $debug;
	open(AA,$aaf) or die "$aaf";
	open(IDX,">$aaf.idx") or die ">$aaf.idx";
	open(IDX2,">$aaf.$id2tag.idx") or die ">$aaf.$id2tag.idx";
	my ($idnum, $id2num, $at0, $at, $start, $end)= (0,0,0,0,0,0);
	while(<AA>) {
		$at0= $at;
		$at= tell(AA);
		
		if (/^#\s+EOR/) {
			$end= $at0;
			putIndex(*IDX,$start,$end,$idnum) if ($idnum>0);
			putIndex(*IDX2,$start,$end,$id2num) if ($id2num>0);
			$idnum= $id2num= 0;
			$start= $at;
			}
		if (/^ID\|${idtag}0*(\d+)/) {
			$idnum= $1;
			}
		if (/^ID\|${id2tag}0*(\d+)/) {
			$id2num= $1;
			}
		}
	$end= tell(AA);
	putIndex(*IDX,$start,$end,$idnum) if ($idnum>0);
	putIndex(*IDX2,$start,$end,$id2num) if ($id2num>0);
	close(AA); close(IDX);close(IDX2);
	warn "# indexAcode done\n" if $debug;
}


1;

__END__

Match this GAME 2 ACODE output:

GADR
{
RETE|ID 1 FBan0003665	GID 1 FBgn0000635	GSYM 1 Fas2	ARM 1 X	CLOC 1 4B1-4B3	FNC 1 plasma membrane 	TRREC 3	AALEN 3 873	SQLEN 3 3447
ID|FBan0003665
SYM|CG3665
GENSR
{
GSYM|Fas2
ID|FBgn0000635
}

ARM|X
SCAF|AE003430
BLOC|complement(3874988..3946706)
SQLEN|3447
|2891
|2873
GO|plasma membrane ; GO:0005886
|plasma membrane ; GO:0005886
|response to ethanol (sensu Insecta) ; GO:0045473
|learning and/or memory ; GO:0007611
|learning and/or memory ; GO:0007611
|neuronal cell recognition ; GO:0008038
|neuronal cell recognition ; GO:0008038
|homophilic cell adhesion ; GO:0007156
|neuromuscular junction development ; GO:0007528
|neuromuscular junction development ; GO:0007528
|mushroom body development ; GO:0016319
|fasciculation of neuron ; GO:0007413
|fasciculation of neuron ; GO:0007413
CLOCC|4B1-4B3
PEPST|Perfect match to SwissProt real (computational)
DT|20020621

TRREC
{

...
}

EVD
{
NAM|BLASTX Similarity to Other Species
PRG|blastx_masked
DB|aa_SPTR.insect
DT|20030114
DBX|P22648
BLOC|complement(3882379..3882564,3882663..3884150)
...
}

}
# EOR

