
=head1 NAME

org::gmod::chado::ix::ToAcode

=head1 DESCRIPTION

Read Chado XML to acode flatfile

=head1 SYNOPSIS

  perl -I$ix/src -M'org::gmod::chado::ix::ToAcode' -e 'acode;' -- \
    chado7-aug03/AE003430v7.chado.xml > chado7-sep03/AE003430v7-ix.acode

  perl -I$ix/src -M'org::gmod::chado::ix::ToAcode' -e 'acodeindex;' -- \
     chado7-sep03/AE003430v7-ix.acode

=head2 NOTES

  just now (sep03) this is memory-piggy, and doesn't release all
  data once dumped.  Best use by invoking program newly for 
  each scaffold.chado.xml, and catting to > output.acode, 
  then do acodeindex
  
  
=head2 CVS info

  set cvsd=':pserver:anonymous@sf.net:???'
  set cvsd=':pserver:anonymous@flybase.net:/bio/cvs'
  cvs -d $cvsd login
  cvs -d $cvsd co -d ChadoSax gmod/schema/XMLTools/ChadoSax/

=head1 AUTHOR

D.G. Gilbert, Sep 2003, gilbertd@indiana.edu

=cut

#-----------------

package org::gmod::chado::ix::ToAcode;

use strict;

use org::gmod::chado::ix::IxFeat;
use org::gmod::chado::ix::IxAttr;
use org::gmod::chado::ix::IxSpan;
use org::gmod::chado::ix::IxReadSax;

use Exporter;
use vars qw/$VERSION $debug @ISA @EXPORT $DATA_VERSION/;
@ISA = qw(Exporter);
@EXPORT = qw(&acode &acodeindex);

$debug= 0;
$VERSION = "0.1";
$DATA_VERSION = "3.1";

BEGIN {
  # some of these are useful - later

}

=head1 METHODS

=item acode(inputChado.xml)
 
 main method; writes flybase.net acode format data from chado.xml

=cut

sub acode {

  ## add Getopts ?
  my ($de)= grep(/debug/,@main::ARGV);
  if ($de) { $debug= ($de =~ /nodebug/) ? 0 : 1 ; }
  
  my $outfh= *STDOUT;
  ## need option for -out=outfile
  ## need option to do acodindex also
  
  my $outhand= new org::gmod::chado::ix::ToAcode(
    outh => $outfh
    );  

  my $xmlreader= new org::gmod::chado::ix::IxReadSax(
    debug => $debug,
    handleObj => $outhand, # handle only each finished top-level feature?
    );  
  warn "# ToAcode @main::ARGV .....\n" if $debug;

  $xmlreader->parse(@main::ARGV);

  warn "# ToAcode done ............ \n" if $debug;
  
#   my $topnode= $xmlreader->topnode();
#   # $topnode->printObj(0);
#   my @fts= $topnode->getfeats('feature');
#   foreach my $ft (@fts) {
#     warn "# handleObj $ft ......\n" if $debug;
#     $ft->handleObj( 0, $outhand);
#     }
#  warn "# ToAcode done ............ \n" if $debug;
  
}

=item acodeindex(input.acode)
 
 main method; create acode.idx index files for (FBan,FBgn) IDs

=cut

sub acodeindex {
  unless(@main::ARGV) { die "usage: acodeindex FBan-data.acode\n"; }
  #? no need for new ToAcode()
  my $file= shift @main::ARGV;
  unless(-r $file) { die "acodeindex: cannot index $file\n"; }
  indexAcode( $file, "FBan", "FBgn");
}



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
	  $ob= $ob->getid($ob->{attr}); # no id, use attr
	  }
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

=item handleObj($depth,$object)

  main method; processes $object

=cut

sub handleObj {  
	my $self = shift;
	my $depth= shift;
 	my $ob   = shift;
 	  
  my $outh= $self->{outh};
 	my $ftd= $self->{ftd};
 	my $evd= $self->{evd};

  my $otag= $ob->{tag};
  warn "# handleObj $otag = $ob  \n" if ($debug && $depth<1);
  
  ## otype == gene|mRNA|protein|exon|...
  my($k,$otype)= $ob->id2name('type_id', $ob->get('type_id'));
  my ($dolist, $doatts)= (1,1);
  
  my $nada= 0;
  SWITCH: {

    ($otag =~ /^feature$/ && $depth==0) && do {
      delete $self->{ftd};
      delete $self->{evd};
      $ftd= $self->{ftd}= {}; #?? clear
      $evd= $self->{evd}= {}; #?? clear
      
      my @srcs= $ob->getlocsources();
      $ftd->{srcid}= shift @srcs; 
      
      # srcid should be chromosome_arm - get src ft name!
      my $sft= $ob->getid( $ftd->{srcid} );
      $ftd->{ARM}= $sft->name() if ($sft);#? always? check sft->id2name{type_id} == chromosome_arm
        
      my $loc= $ob->getlocation( $ftd->{srcid});
      $ftd->{BLOC}= $loc;
      
      # $ftd->{ANID}= ## dbxref={ FBan0003665, db_name=FlyBase, id=dbxref_58553 } 
      # $ftd->{CGSYM}=  #    dbxref={ CG3665, db_name=Gadfly, id=dbxref_58552 } dbxref_name=CG3665  
      # $ftd->{GID}=  dbxref_name=FBgn0000635 

      $ftd->{GSYM}= $ob->name();  
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

      
			last SWITCH; 
			};  

   ($otag =~ /^feature$/ && $depth > 0 && $depth < 3) && do {
      
      ## change logic here/for ftd{} to store all of subfeature fields together
      
      if ($otype  =~ /^(mRNA|protein)$/) {
      ## protein is nested in mRNA
      my $loc;
      
      if ($otype  =~ /^(protein)$/ && $depth == 2) { #?! need parent.otype == mRNA
        # $otype= 'CDS';
        $ftd->{AANAM} .= $ob->name() . ";";  
        $ftd->{AALEN} .= $ob->{seqlen} . ";";
        
        ## need something like this to get full CDS location:
        ## my $mrnalocs= $ob->getparent()->{locs}; ## getlocationSrc( $ftd->{srcid},'exon');
        ## my $floc= $ob->getlocationMath( $ftd->{srcid}, 'add' => $mrnalocs);
        
          ## CDS needs to add loc to its mRNA loc
        ## $loc= $ob->getlocation(  $ftd->{srcid} ); 
        ## $ftd->{CDS} .= $loc . ";";
        }
        
      elsif ($otype =~ /^(mRNA)$/) { # $depth == 1
        $ftd->{CTSYM} .= $ob->name() . ";";  
        $ftd->{SQLEN} .= $ob->{seqlen} . ";";
        # $loc= $ob->getlocation(  $ftd->{srcid},'exon'); ## bad for mRNA - need to add exon subfeat locs

        my $locs = $ob->getlocationSrc($ftd->{srcid},'exon');
        $loc = $ob->getlocationString($locs);
        $ftd->{mRNA} .= $loc . ";";

         # $ob->{locs}= $locs; #????
        $loc='';
        my $aaloc = $ob->getlocationSrc($ftd->{srcid},'protein');
        if ($aaloc) {
          $aaloc = $ob->insertlocations($aaloc, $locs);
          $loc = $ob->getlocationString($aaloc) if $aaloc;
          }
        $ftd->{CDS} .= $loc . ";";
        }

      }
      
			last SWITCH; 
			};  
			
			
    ($otag =~ /^dbxref_id$/ && $depth==1) && do {
      # dbxref_id now is 'unused' IxAttr
      my($tag,$attr)= ('dbxref_id', $ob->{attr}); #??
      ($tag,$attr)= $ob->id2name($tag,$attr);
      #?? my($attr, $db, $dbattr)= $self->getDbXref($ob);

        ## FIX for TE000 == FBti000
      $ftd->{GID}= $attr if ($attr =~ /FBgn/ );#&& $db eq 'FlyBase'
      $ftd->{ANID}= $attr if ($attr =~ /FBan/ );#&& $db eq 'FlyBase'
      $ftd->{CGSYM}= $attr if ($attr =~ /^C[GR]\d/ ); 
      warn "dbxref_id= $attr,$tag\n" if $debug;
      
			last SWITCH; 
			};  
			
    ($otag =~ /^dbxref$/ && $depth==1) && do {
      # my($tag,$db,$attr)= ('db_id', $ob->{db_id}, $ob->{attr});
      # ($tag,$db)= $ob->id2name($tag,$db);
      my($attr, $db, $dbattr)= $self->getDbXref($ob);
      
        ## FIX for TE000 == FBti000
      $ftd->{CGSYM}= $attr if ($attr && $db =~ m'Gadfly'i);
      $ftd->{ANID} = $attr if ($attr =~ /FBan/ && $db =~ m'FlyBase'i);
      $ftd->{GID}  = $attr if ($attr =~ /FBgn/ && $db =~ m'FlyBase'i);
      warn "dbxref= $db,$attr,$dbattr\n" if $debug;
      
			last SWITCH; 
			};  

    ($otag =~ /^featureprop$/ && $depth<3) && do {
      my($tag,$db,$attr)= ('type_id', $ob->{type_id}, $ob->{attr});
      ($tag,$db)= $ob->id2name($tag,$db);
      $ftd->{SCAF}= $attr if ($db eq 'gbunit');
      
      if ($depth == 1) {
      $ftd->{PEPST} .= $attr.";" if ($db eq 'sp_status');
      $ftd->{CMT} .= $attr.";" if ($db eq 'sp_comment');
      $ftd->{CMT} .= $attr.";" if ($db eq 'comment');
      $ftd->{CLOCC} .= $attr.";" if ($db eq 'cyto_range');
      }
      else {
      $ftd->{PEPCMT} .= $attr.";" if ($db eq 'sp_status');
      $ftd->{PEPCMT} .= $attr.";" if ($db eq 'sp_comment');
      $ftd->{PEPCMT} .= $attr.";" if ($db eq 'comment');
      }
      
      ## add these...
      ## featureprop= AAF45927,type_name,protein_id
      ## featureprop= all done,type_name,status
      ##?? featureprop= 4B3-4B3,type_name,cyto_range == CLOCC
      ## featureprop= true,type_name,problem
      ##?? featureprop= CG32009,type_name,symbol - have elsewhere
     
      warn "featureprop= $attr,$tag,$db\n" if $debug;
      # also got 'sp_status', sp_comment 'cyto_range' ..
      
			last SWITCH; 
			};  
			
    ($otag =~ /^feature_cvterm$/) && do {
      # go term - need GO:id also...
      my $cvft= $ob->get('cvterm_id'); # attr?
      $cvft= $ob->getattr('cvterm_id') unless($cvft); #?? which?
      $cvft= $ob->getid($cvft) if ($cvft);
      if ($cvft) {
        my $nm= $cvft->name();
        my $goid='';
        my @attr= $cvft->getattrs("dbxref"); 
        if (@attr) {
          $goid= $attr[0]->getattr(); 
          } 
        $ftd->{GO} .= "\n|" if ($ftd->{GO}); #fixme?
        $ftd->{GO} .= "$nm ; $goid";
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
        warn "# evd $otag: $anid = $anh->{PROGRAM} \n" if ($debug);
      }
      
      my @fts= $ob->getfeats('feature');
      if (@fts) {
      my $ft= shift @fts; # only 1 ??
      my $loc= $ft->getlocation( $ftd->{srcid});
      my $dt= cleandate($ft->{timelastmodified}); 
      $anh->{mRNA} .= $loc .';';  
      $anh->{DT}  = "$dt" if $dt;   
      
      @fts= $ft->getfeats('feature'); # find dbx names
      foreach my $dft (@fts) {
        next if ($dft->{id} eq $ftd->{srcid});
        my $dbname= $dft->name();
        $anh->{mRNA_dbx} .= $dbname .';'
          ;# unless($anh->{mRNA_dbx} =~ m/$dbname;/);
        my($tag,$type)= $ob->id2name('type_id',$dft->{type_id});
        $anh->{TYPE}= $type if ($type);
        last;
        }
      }
      
      $dolist= $doatts= 0; # no more recurse ??
			last SWITCH; 
			};  


    ($otag =~ /^alignment_evidence$/) && do {
      ## has feature.feature.feature. ... substructure
       
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
        warn "# evd $otag: $anid = $anh->{PROGRAM} \n" if ($debug);
      }
      
      $dolist= $doatts= 0; # no more recurse ??
      last SWITCH
        if ($anh->{PROGRAM} eq 'locator' && $anh->{DATABASE} eq 'cytology');
        
      my @fts= $ob->getfeats('feature');
      if (@fts) {
      my $ft= shift @fts; # only 1? - 1 top level, many subfeature 'match'
      my $loc= $ft->getlocation(  $ftd->{srcid},'match');
      my $dt= cleandate($ft->{timelastmodified}); 
      $anh->{mRNA} .= "$loc;"; ## FIXME - which ??
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
        $anh->{mRNA_dbx} .= $dbx .';' ; 
        # $anh->{mRNA_dbx2} .= $dbname .';' ; 


        my($tag,$type)= $dft->id2name('type_id',$dft->{type_id});
        $anh->{TYPE}= $type if ($type);
  
          ## EST only if DB|na_EST.all_nr.dros and/or? DB|na_DGC.dros
        if ($type eq 'EST' && $anh->{DATABASE} =~ /\.dros/) { 
          my $v= $dbname; $v =~ s/[:_\.].*//;
          $ftd->{EST} .= $v .';' unless($ftd->{EST} =~ m/$v;/); 
          }
        elsif ($type eq 'cDNA_clone') { 
          my $v= $dbname;  
          $ftd->{CDNA} .= $v .';' unless($ftd->{CDNA} =~ m/$v;/);  
          }
        elsif ($type eq 'oligonucleotide') { 
          my $v= $dbname; $v =~ s/_at_\d+/_at/;
          $ftd->{AFFY} .= $v .';' unless($ftd->{AFFY} =~ m/$v;/); 
          }
        
        last; #? only 1
        }
      }
      
      $dolist= $doatts= 0; # no more recurse ??
			last SWITCH; 
			};  
  
  $nada= 1;
  }

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
  
  if ($depth == 0 && scalar(%$ftd)>1) {
    my %ca= ();      
    my @elist= values( % $evd );
       
    $ftd->{VERS}= $self->{VERS}; # data version from where?
    fbanAcode( $outh, $ftd, undef,\@elist); ##, $FTOUT, \%ca);
    
    ## need to delete some $self data here after dump
    # delete $evd->{xxx};
    
    }
    
}




#--------------- acode writer from parsegame4.pl -------------------------------

my @skipkeys= (); # dont really want to skip dbxref, but needs fixing
my %skipkeys= ();
BEGIN {
#   @skipkeys= qw/dbxref CDS mRNA TYPE/;
#   %skipkeys= map { $_ => 1; } @skipkeys;
}

=item sub fbanAcode()

from  flybase/datagen/parsegame4.pl

=cut

sub fbanAcode {
    my($outh, $href, $ftout, $ca)= @_; # array refs of keys, values
    my %h= %$href;
   
    #my $fsplit= '\n\|';
    my $fsplit= ';';	  
	  ##FIXME## use of ';' or '\n\|' field value seps is bad; change logic
	  
		##FIXME## featureTable($ftout,\%h,'\n\|') if ($ftout) ; # splitpat problems here !

		# return unless($h{TYPE} eq 'gene'); ## FIXME for CR ...
    my $type= ($h{TYPE} eq 'gene') ? '' : $h{TYPE};
		my $gensr;
		my $anid = $h{ANID}  || 'null'; #?? what if null?
 	  my $gsym = $h{GSYM}  || $h{CGSYM}; 
		my $cgsym= $h{CGSYM} || $gsym;
    my $sqlen= $h{GNLEN}; ##sqlen($h{BLOC});

    if ($type eq 'transposable_element') {
      #? is this kosher? cgsym = anid = TE19568
      $anid = $cgsym;
      $cgsym= $gsym;
      my $tid= $anid; $tid =~ s/TE/FBti/;
			$gensr= "INSR\n{\n"; #?? INSR = TIR subrec ? will this TIRecord cause problems?
			$gensr .= "SYM|$gsym\n";
			$gensr .= "ID|$tid\n}\n";
      }
		
		my @re= ("ID 1 $anid"); 
		## check here if GID = FBti other data class, write proper subrecord?
		if ($h{GID} =~ /FB..\d/) {
			push(@re,"GID 1 $h{GID}");
			push(@re,"GSYM 1 $gsym");
			$gensr= "GENSR\n{\n";
			$gensr .= "GSYM|$gsym\n";
			$gensr .= "ID|$h{GID}\n}\n";
			}
		push(@re,"CLA 1 $type") if $type;
		push(@re,"ARM 1 $h{ARM}") if $h{ARM};
		push(@re,"CLOC 1 $h{CLOCC}") if $h{CLOCC}; 

# $h{GO} -> acode flds now are FNC/ENZ/CEL - use GO field 
# now have goterm == goid ; goterm2 == goid2 ...
		my $go;
		if( $h{GO} ) {
    	$go= $h{GO}; 
    	#(my $topgo= $go) =~ s/\s*(==|;|\n).+$//m; push(@re,'FNC 1 '.$topgo);
    	$go =~ s/ == / ; /g;
			my @headgo= split("\n",$go); $headgo[0] =~ s/^([^;\n]+)[;\n].+$/$1/; 
			push(@re,'FNC 1 '.$headgo[0]); 
    	}
    	
		my @trn= split(/$fsplit/,$h{CTSYM});
		my @aan= split(/$fsplit/,$h{AANAM});
		my @aa= split(/$fsplit/,$h{AALEN});
		my @sl= split(/$fsplit/,$h{SQLEN});
		my @cm= split(/$fsplit/,$h{PEPCMT});
		my @bl= split(/$fsplit/,$h{mRNA});
		my @cds= split(/$fsplit/,$h{CDS});
		my @dt= split(/$fsplit/,$h{DT}); #? is there a date field in each ct rec?
		push(@re,"TRREC ".scalar(@trn)) if @trn;  
		push(@re,"AALEN ".scalar(@aa)." ".$aa[0]) if @aa;  
		push(@re,"SQLEN ".scalar(@sl)." ".$sl[0]) if @sl;  #gene $sqlen ??
		
		my $dt='';
		if (@dt) { my @sd= sort { $b <=> $a } @dt; $dt= shift @sd; }

    # FIXME add: AFFY EST CDNA fields
		
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
		print $outh "ARM|$h{ARM}\n" if $h{ARM};
		print $outh "SCAF|$h{SCAF}\n" if $h{SCAF};
		print $outh "BLOC|$h{BLOC}\n" if $h{BLOC};
		print $outh "SQLEN|$sqlen\n" if $sqlen; ##$h{SQLEN};
		print $outh "GO|$go\n" if $go;
		
		print $outh "CDNA|".join("\n|",split(/;/,$h{CDNA}))."\n" if $h{CDNA};
		print $outh "EST|".join("\n|",split(/;/,$h{EST}))."\n" if $h{EST};
		print $outh "AFFY|".join("\n|",split(/;/,$h{AFFY}))."\n" if $h{AFFY};

		print $outh "CLOCC|$h{CLOCC}\n" if $h{CLOCC};
		print $outh "PEPST|$h{PEPST}\n" if $h{PEPST};
		print $outh "CMT|$h{CMT}\n" if ($h{CMT} && $h{CMT} !~ /internal view/); # forgot that last
		print $outh "DT|$dt\n" if $dt;
		
		foreach my $i (0..$#trn) {
			my $nm= $trn[$i]; 
			my $aa= $aa[$i]; my $aan= $aan[$i];
			my $sl= $sl[$i]; 
			my $bl= $bl[$i]; 
			my $cds= $cds[$i]; 
			my $dt= $dt[$i];
			my $cm= $cm[$i]; $cm =~ s/^\s*//;
      ## need tp split bloc by length -- some are very long
      # $bl= undef; #?
			$sl .= ' (-)' if ($sl && $bl =~ /complement/);
      $bl = wrapLong($bl);
      $cds = wrapLong($cds); #? store only translation offset?
      $cm = wrapLong($cm);

## want TRREC. CMT other evidence fields
			print $outh "TRREC\n{\n";
		  print $outh "NAM|$nm\n" if $nm;
		  print $outh "AANAM|$aan\n" if $aa;
		  print $outh "SQLEN|$sl\n" if $sl;
		  print $outh "AALEN|$aa\n" if $aa;
		  print $outh "BLOC|$bl\n" if $bl;
		  print $outh "CDS|$cds\n" if $cds;
		  print $outh "CMT|$cm\n" if $cm;
		  print $outh "DT|$dt\n" if $dt;

      #?? make AAREC subrec for protein ??

		  print $outh "}\n";
			}

	  if (ref($ca) =~ /ARRAY/) { evidAcode( $outh, $ca ); }
#   if ($ca && $ca->{$h{CGSYM}}){ evidAcode( $outh, $ca->{$h{CGSYM}}  ); }
	  
	  my %did= map { $_,1; } 
	    qw/ANID GID GSYM GNLEN ARM CLOC CGSYM SCAF BLOC mRNA CTSYM 
        DT AALEN AANAM CDS SQLEN GO CLOCC PEPST PEPCMT CMT 
        AFFY EST CDNA srcid TYPE ENAM/;
    foreach my $k (sort keys %h) {
      if($k =~ /\w/ && !$did{$k}) { print $outh "$k|$h{$k}\n"; }
      }

# VERS|$vers
	print $outh "\n}\n\# EOR\n\n";
}


sub evidAcode {
	my($outh, $eref)= @_;  
  my @kv= @$eref;  ## array of evd hash
#   ## need to use mRNA_dbx ids matched to BLOC's -- turn into subrec??
  
  foreach my $v (@kv) {
    my %h= %$v; ##= (); 
    
    next if ($h{PROGRAM} eq 'locator' && $h{DATABASE} eq 'cytology');

    print $outh "EVD\n{\n";
    print $outh "NAM|$h{ENAM}\n" if $h{ENAM};
    print $outh "PRG|$h{PROGRAM}\n" if $h{PROGRAM};
    print $outh "DB|$h{DATABASE}\n" if $h{DATABASE};
    print $outh "CLA|$h{TYPE}\n" if $h{TYPE};
    print $outh "DT|$h{DT}\n" if $h{DT};
    my @bl= split(/;/,$h{mRNA}); # many of these per program/db/type
    my @db= split(/;/,$h{mRNA_dbx}); # many of these per program/db/type
    # my @db2= split(/;/,$h{mRNA_dbx2}); # many of these per program/db/type
    foreach my $bl (@bl) {
      $bl = wrapLong($bl); 
      my $dbx = shift @db;
#       if (@db2) {
#         my $dbx2= shift @db2;
#         if(!$dbx) { $dbx= $dbx2; }
#         elsif ($dbx !~ m/$dbx2/) { $dbx .= " ; $dbx2 "; }
#         }
      print $outh "DBX|$dbx\n" if $dbx;
      print $outh "BLOC|$bl\n" if $bl;
      }
    print $outh "}\n";
    }
}


sub wrapLong {
  # wrap long lines for acode
  my $rng= shift;
  my $nl = shift || "\n|";
  
	if (length($rng)>80) {	
		my ($at0, $at, $r2)= (0,0,'');
		while ($at0>=0) {
		  $at= index($rng,",",$at0+60);
		  if ($at<=0) { $at= index($rng,";",$at0+60); }
		  if ($at>0) { $at++; $r2 .= substr($rng,$at0,$at-$at0) . $nl; $at0= $at; }
		  else { $r2 .= substr($rng,$at0); $at0= -1; }
		  }
	  $rng= $r2;
		}
  return $rng;
}

use vars qw( $idxrecsize );
BEGIN {
$idxrecsize = length(pack("LL", 1, 50000)); # store as unsigned long, unsigned long
}
  
sub putIndex {
	my($idx,$at,$e2,$idnum)= @_;
	my $size= $e2 - $at;   
	my $record= pack("LL", $at, $size); # should be "NN" for platform independent
	my $idloc = $idnum * $idxrecsize;
	seek($idx, $idloc, 0);  
	print $idx $record;
}

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

