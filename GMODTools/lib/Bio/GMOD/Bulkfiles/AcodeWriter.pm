package Bio::GMOD::Bulkfiles::AcodeWriter;
use strict;

=head1 NAME

  Bio::GMOD::Bulkfiles::AcodeWriter  
  
=head1 SYNOPSIS
  
  use Bio::GMOD::Bulkfiles;       
  
  my $sequtil= Bio::GMOD::Bulkfiles->new(  
    configfile => 'seqdump-r4', 
    );
  my $fwriter= $sequtil->getWriter('acode'); 
  my $result = $fwriter->makeFiles( );
    
=head1 NOTES

  genomic sequence file utilities, part3;
  parts from 
    flybase/work.local/chado_r3_2_26/soft/chado2flat2.pl
  
=head1 AUTHOR

D.G. Gilbert, 2004, gilbertd@indiana.edu

=head1 METHODS

=cut

#-----------------


# debug
#use lib("/bio/biodb/common/perl/lib", "/bio/biodb/common/system-local/perl/lib");

use POSIX;
use FileHandle;
use File::Spec::Functions qw/ catdir catfile /;
use File::Basename;
use Bio::GMOD::Bulkfiles::BulkWriter;       

use base qw(Bio::GMOD::Bulkfiles::BulkWriter);

our $DEBUG = 0;
my $VERSION = "1.1";

#my $configfile= "toacode"; #? BulkFiles/AcodeWriter.xml 
use constant BULK_TYPE => 'acode';
use constant CONFIG_FILE => 'toacode';

use vars qw/  $noIDmap $nameIsId $nameIsSpeciesId $cutdbpattern $indexidtype $gnidpattern $anidpattern /;

sub init 
{
	my $self= shift;
  $self->SUPER::init();
  
  $DEBUG= $self->{debug} if defined $self->{debug};
  ## superclass does these??
  # $self->{bulktype} =  $self->BULK_TYPE; # dont need hash val?
  # $self->{configfile}= $self->CONFIG_FILE unless defined $self->{configfile};
}


=item initData

initialize data from config

=cut

sub initData
{
  my($self)= @_;
  $self->SUPER::initData();
  
#   my $config = $self->{config};
#   my $sconfig= $self->handler()->{config};
#   my $finfo= $self->{fileinfo} || $self->handler()->getFilesetInfo($self->BULK_TYPE);
#   my $outdir= $self->handler()->getReleaseSubdir( $self->getconfig('path') || $self->BULK_TYPE);
#   $self->{outdir} = $outdir;

## see instead super.. promoteconfigs
#   $self->{addids} = $self->getconfig('addids');
#   $self->{dropnotes} = $self->getconfig('dropnotes');
#   $self->{allowanyfeat} = $self->getconfig('allowanyfeat');

  $noIDmap =  $self->getconfig('noidmap');
  unless($noIDmap) {
  $noIDmap= join '|',
  qw(cytowalk 
    misc
    chromosome 
    match motif sim4
    oligo processed 
    protein _peptide
    repeat regulatory_region repeat_region
    transposable_element_pred 
    );
  }
  ##  mRNA CDS  _UTR intron EST cDNA  enhancer
#     _fragment 
#     _junction 
#     _mutation 
#     _site  
#     _variant 
  #   
  $noIDmap =~ s/\s+/|/g;
  $noIDmap .= '|\bregion';
  $nameIsId= $self->getconfig('nameisid')  || '^(BAC)';
  $nameIsSpeciesId= $self->getconfig('nameisorgid')  || '^(gene)$';  # others? rnas?
  $cutdbpattern=  $self->getconfig('idcutdb') || '^(FlyBase|GadFly|GB_protein|GO):';

  $indexidtype= $self->getconfig('indexidtype') || '^(gene|pseudogene|\w+RNA)';
  $gnidpattern= $self->getconfig('gnidpattern') || '[A-Z]{2}gn\d+';
  $anidpattern= $self->getconfig('anidpattern') || '[A-Z]{2}an\d+';
}


#-------------- subs -------------


=item  makeFiles( %args )

  primary method
  arguments: 
    infiles => \@fileset of fff features and dna sequences,   # required

=cut

sub makeFiles
{
	my $self= shift;
  my %args= @_;  

  print STDERR "AcodeWriter::makeFiles\n" if $DEBUG; # debug
  
  # more sensible that writer should ask handler for kind of files it wants
  my $intype= $self->config->{informat} || 'fff'; #? maybe array
  my $fileset = $args{infiles};
  my $chromosomes = $args{chromosomes};
  unless(@$fileset) { 
    $fileset = $self->handler->getFiles($intype, $chromosomes);  
    unless(@$fileset) { 
      warn "AcodeWriter: no input '$intype' files found\n"; 
      return  $self->status(-1);
      }
    }
 
  my $featset= $self->handler->{config}->{featset} || []; #? or default set ?
  my $addids = defined $args{addids} ? $args{addids} : $self->config->{addids};
  
  my $status= 0;
  my $ok= 1;
  for (my $ipart= 0; $ok; $ipart++) {
    $ok= 0;
    my $infile= $self->openInput( $fileset, $ipart, $intype);
    if ($infile && $infile->{inh}) {
      my $inh= $infile->{inh};
      my $chr= $infile->{chr};
      
#       if ($addids) {
#         my $idlist= $self->readIdsFromFFF( $inh, $chr, $self->handler()->{config}); # for featmap ?
#         $self->{idlist}= $idlist;
#         $inh= $self->resetInput($infile); #seek($inh,0,0); ## cant do on STDIN ! cant do on PIPE !
#         }
      
      ## need to know $chr here .. from $fileset infile
      
      my $res= $self->process( $inh, $chr, $featset);
      close($inh); delete $infile->{inh};
      $status += $res;
      $ok= 1;
      }
    }
    
  print STDERR "AcodeWriter::makeFiles: done\n" if $DEBUG; 
  return  $self->status($status);
}


=item openInput( $fileset )

  handle input files
   .. copied to base class
   
=cut

sub openInput
{
	my $self= shift;
  my( $fileset, $ipart, $intype )= @_; # do per-csome/name
  $intype ||= $self->config->{informat} || 'fff'; #? maybe array
  my $atpart= 0;
  print STDERR "openInput: type=$intype part=$ipart \n" if $DEBUG; 
  
  foreach my $fs (@$fileset) {
    my $fp  = $fs->{path};
    my $name= $fs->{name};
    my $type= $fs->{type};
    next unless( $fs->{type} =~ /$intype/); # could it be 'dna/fasta', 'amino/fasta' ?
    unless(-e $fp) { warn "missing infile $fp"; next; }
    $atpart++;
    next unless($atpart > $ipart);
    print STDERR "openInput: name=$name, type=$type, $fp\n" if $DEBUG; 
    
    my ( $org, $chr1, $featn, $rel, $format )= $self->split_filename($fp);
    $fs->{org}= $org;
    $fs->{chr}= $chr1 unless($fs->{chr});
    $fs->{featn}= $featn;
    $fs->{rel}= $rel;
    $fs->{format}= $format;
    
    if ($fp =~ m/\.(gz|Z)$/) { open(INF,"gunzip -c $fp|"); $fs->{pipe}=1; }
    else { open(INF, $fp); }
    my $inh= *INF;
    $fs->{inh}= $inh;
    return $fs;   
    }
  print STDERR "openInput: nothing matches part=$ipart\n" if $DEBUG; 
  return undef;  
}


sub resetInput
{
	my $self= shift;
  my( $infile )= @_;  
  
  my $inh= $infile->{inh};
  my $fp = $infile->{path};
  if ($infile->{pipe} || $fp =~ m/\.(gz|Z)$/) { 
    close($inh) if $inh;
    open(INF,"gunzip -c $fp|"); $inh= *INF;  $infile->{pipe}=1; 
    }
  elsif (!$inh) { open(INF,$fp); $inh= *INF; }
  else { seek($inh,0,0); }
  $infile->{inh}= $inh;
  return $inh;
}


=item process


=cut

sub process
{
	my $self= shift;
  my( $inh, $chr, $featset )=  @_;
  my $ndone= 0;
  my $outh= {};
  my $outdir= $self->outputpath();
  my @features= @$featset;

  my @fffeatures= grep !/^chromosome/, @features;
  my $fn= $self->get_filename ( $self->{org}, $chr, 'all', $self->{rel}, $self->BULK_TYPE);
  $fn= catfile( $outdir, $fn);
  $outh->{all}= new FileHandle(">$fn");
  $self->{outh}= $outh->{all};
  
  $ndone += $self->fromFFFloop( $inh, $outh, $chr, \@fffeatures);

  foreach my $featn (keys %$outh) { 
    my $fh= $outh->{$featn}; 
    close($fh); 
    #? check size and delete if zero ?
    }

  print STDERR "process ndone = $ndone\n" if $DEBUG;
  return $ndone;
}



=item acodeHeader

  my $fah= main->acodeHeader( ID => 'CG123', name => 'MyGene', 
    chr => '2L', loc => '1234..5678', type => 'pseudogene',
    db_xref => 'FlyBase:FBgn0000123', note => 'BOGUS',
    );

  expected keys: type chr/chromosome loc/location ID name db_xref
   
=cut

=item example fff for gene stuff

2L      6338772 gene    Cpr     26C3-26C3       6338772..6346282        CG11567 FlyBase:FB
an0011567;FlyBase:FBgn0015623;GB:CG11567;       gbunit=AE003613;synonym=Cpr;synonym_2nd=CP
R;synonym_2nd=NADPH-cytochrome P450 oxidoreductase;synonym_2nd=NCPR;synonym_2nd=P450;synon
ym_2nd=P450 reductase;synonym_2nd=cpr;

2L      6338772 mRNA    Cpr-RA  -       join(6338772..6339125,6342158..6342349,6342727..63
43069,6344159..6344283,6344344..6344945,6345031..6345679,6345743..6346282)      CG11567-RA
        FlyBase:FBtr0079250;FlyBase:FBgn0015623;Gadfly:CG11567-RA;      synonym=CG11567-RA
;

2L      6342174 CDS     Cpr-PA  -       join(6342174..6342349,6342727..6343069,6344159..63
44283,6344344..6344945,6345031..6345679,6345743..6345884)       CG11567-PA      FlyBase:FB
pp0078880;GB_protein:AAF52367.1;FlyBase:FBgn0015623;Gadfly:CG11567-PA;  synonym=CG11567-PA
;

2L      6338772 five_prime_UTR  Cpr-RA-u5       -       join(6338772..6339125,6342158..634
2173)   CG11567-RA-u5   FlyBase:FBgn0015623;    

2L      6345888 three_prime_UTR Cpr-RA-u3       -       6345888..6346282        CG11567-RA
-u3     FlyBase:FBgn0015623;    

2L      6339126 intron  Cpr-RA-in       -       join(6339126..6342157,6342350..6342726,634
3070..6344158,6344284..6344343,6344946..6345030,6345680..6345742)       -       FlyBase:FB
gn0015623;      


=cut

sub acodeHeader
{
  my($self,%vals)= @_;
  
  
  my $type= delete $vals{type};
  my $arm = delete $vals{chr} || delete $vals{chromosome};
  my $loc = delete $vals{loc} || delete $vals{location};
  #$loc= "$arm:$loc" if ($arm && $loc !~ /:/);
  my $mrna= delete $vals{mrna};
  
  my $ID  = delete $vals{ID} || delete $vals{id} || delete $vals{uniquename};
  my $name= delete  $vals{name};
  my $db_xref= delete $vals{db_xref} || delete $vals{dbxref};
  if ($db_xref) { $db_xref =~ s/\s*;\s*$//; $db_xref =~ s/;/,/g; $db_xref =~ s/,,/,/g;}

  my @ids= map { s/$cutdbpattern//i; $_; } split(/,/, $ID.",".$db_xref);
    
  
  my ($anid)= grep /$anidpattern/, @ids;
  my ($gid) = grep /$gnidpattern/, @ids;
  my $gsym= $name;
  my $cgsym= $ID;
  my $cloc= delete $vals{cytomap};
  my $scaf= delete $vals{gbunit};
  my $syn = delete $vals{synonym_2nd};
  my $isTE=($type =~ /transposable_element/ || $gid =~ /FBti/); # an = TE\d+ ; gn = FBti\d+

  my @re=();
  push(@re,"ID 1 $anid");
  push(@re,"GID 1 $gid");
  push(@re,"GSYM 1 $gsym");
  push(@re,"CGSYM 1 $cgsym");
  push(@re,"ARM 1 $arm");
  push(@re,"CLA 1 $type") if $type;
  push(@re,"CLOC 1 $cloc") if $cloc;
  push(@re,"SCAF 1 $scaf") if $scaf; 

  my @trns= ();
  @trns= @{$mrna} if(ref $mrna); 
  my @aa=(); my @bl=(); my $ntr= 0;
  foreach my $trn (@trns) {
    my($type,$name,$cytomap,$baseloc,$id,$dbxref,$notes,$chr)= @$trn;
    #push(@aa, $name) if ($type eq 'CDS'); # want aa len here !
    push(@bl, $name) if ($type eq 'mRNA');  
    $ntr++ if ($type eq 'mRNA');
    }
  push(@re,"TRREC ".$ntr) if $ntr;  
  push(@re,"AALEN ".scalar(@aa)." ".$aa[0]) if @aa;  
  
  my $re= join("\t",@re);

  my $gadr= "GADR\n{\n";
  $gadr .= "RETE|$re\n";
  $gadr .= "ID|$anid\n";
  $gadr .= "SYM|$cgsym\n";
  
  if ($isTE) {
  $gadr .= "INSR\n{\n";  ## need INSR variant, FBti/TE 
  $gadr .= "SYM|$gsym\n";
  $gadr .= "ID|$gid\n}\n";
  } else {
  $gadr .= "GENSR\n{\n";  ## need INSR variant, FBti/TE 
  $gadr .= "GSYM|$gsym\n";
  $gadr .= "ID|$gid\n}\n";
  }
  
  $gadr.= "CLA|$type\n" if $type;
  $gadr.= "ARM|$arm\n" if $arm;
  $gadr.= "SCAF|$scaf\n" if $scaf;
  $gadr.= "BLOC|$loc\n" if $loc;
  $gadr.= "CLOCC|$cloc\n" if $cloc;
#  $gadr.= "SQLEN|$sqlen\n" if $sqlen;  

  $gadr.= "SYN|".join("\n|",split(/[;,]/,$syn))."\n" if $syn;
  # $gadr.= "GO|$go\n" if $go;
  
  my @id2= map { s/$cutdbpattern//i; $_; } grep !/$gid|$anid/, split(/,/,$db_xref);
  $gadr.= "ID2|".join("\n|",@id2)."\n" if @id2;

#   $gadr.= "CDNA|".join("\n|",split(/$RECSEP/,$h{CDNA}))."\n" if $h{CDNA};
#   $gadr.= "EST|".join("\n|",split(/$RECSEP/,$h{EST}))."\n" if $h{EST};
#   $gadr.= "AFFY|".join("\n|",split(/$RECSEP/,$h{AFFY}))."\n" if $h{AFFY};

#   my $gcm = join("\n|", split(/$RECSEP/,$h{CMT}));
#   $gcm =~ s/^\s*//; 
#   $gcm = wrapLong($gcm);
#   $gadr.= "CMT|$gcm\n" if ($gcm);

#   $gadr.= "DT|$dt\n" if $dt;

		foreach my $trn (@trns) 
		{
      my($type,$nm,$cytomap,$bl,$id,$dbxref,$notes,$chr)= @$trn;
# 			my $nm=  $trn->{CTSYM};  
# 			my $aa=  $trn->{AALEN}; 
# 			my $aan= $trn->{AANAM}; 
# 			my $sl=  $trn->{SQLEN}; 
# 			my $bl=  $trn->{mRNA}; 
# 			my $cds= $trn->{CDS}; 
# 			my $dt=  $trn->{DT}; 
# 			my $cm=  $trn->{PEPCMT}; 
# 			my $subr= $trn->{SUBREC}; 

# 			$sl .= ' (-)' if ($sl && $bl =~ /complement/);
      $bl = $self->wrapLong($bl);
      #$cds= $self->wrapLong($cds); #? store only translation offset?

# 		  $cm= join("\n|",split(/$RECSEP/,$cm));
#       $cm =~ s/^\s*//; $cm = wrapLong($cm);

      # my $type= $trn->{TYPE};
#       if ($type eq 'CLNSR') {
#         # note: CLNSR = flybase.clone.Clone subrecord, not used, mar04
#         $gadr.= "CLNSR\n{\n";
#         $gadr.= "CLA|$ttype\n" if $ttype; # FIXME
#         $gadr.= "NAM|$nm\n" if $nm;
#     		$gadr.= "SYN|".join("\n|",split(/$RECSEP/,$trn->{SYN}))."\n" if $trn->{SYN};
#         $gadr.= "SQLEN|$sl\n" if $sl; # none of these ?
#         $gadr.= "BLOC|$bl\n" if $bl;
#         $gadr.= "CMT|$cm\n" if $cm;
#         $gadr.= "DT|$dt\n" if $dt; #? could get, not
#         $gadr.= "}\n";
#       } elsif
      
      if ($type eq 'mRNA') {
        # note TRREC = flybase.egad.Transcript subrecord
        $gadr.= "TRREC\n{\n";
        $gadr.= "NAM|$nm\n" if $nm;
    		#$gadr.= "SYN|".join("\n|",split(/$RECSEP/,$trn->{SYN}))."\n" if $trn->{SYN};
        #$gadr.= "AANAM|$aan\n" if $aan;
        #$gadr.= "SQLEN|$sl\n" if $sl;
        #$gadr.= "AALEN|$aa\n" if $aa;
        $gadr.= "BLOC|$bl\n" if $bl;
        #$gadr.= "CDS|$cds\n" if $cds;
        #$gadr.= "CMT|$cm\n" if $cm;
        #$gadr.= $subr if $subr;
        #$gadr.= "DT|$dt\n" if $dt;
        $gadr.= "}\n";
        }
      }

  $gadr .= "VERS|". $self->{rel}."\n";
	$gadr .= "}\n\# EOR\n\n";
  
  return $gadr;
}


sub putrec
{
  my  $self= shift;
  my ( $outh, $gmain, $gmsub )= @_;
  my $org= $self->{org} || $self->handler()->{config}->{org};
  
  my($type,$name,$cytomap,$baseloc,$id,$dbxref,$notes,$chr)= @$gmain;

  my @notes= $self->cleanNotes($notes);
  if ($self->{idlist}) { ## && $types_info->{add_id} addids
    $dbxref= $self->addIdsToDbxref( ($id ? $id : $name), $dbxref );
    }

  my $fah= $outh->{all};
  # $type= $retype->{$type}||$type;
  
  my $header= $self->acodeHeader( type => $type, 
      name => $name, chr => $chr, location => $baseloc, 
      ID => $id, db_xref => $dbxref, cytomap => $cytomap,
      $org ? (species => $org) : (),
      mrna => $gmsub,
      @notes  
      );
      
  print $fah $header;
}



sub wrapLong {
  my  $self= shift;
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


sub fromFFFloop
{
  my  $self= shift;
  my ( $fffin, $outh, $chrIn, $featset )= @_;
  my $nout= 0;
  my $sconfig= $self->handler->{config};
  $self->{ffformat}= 0; 
  my %lastfff= ();
  my $org= $self->{org} || $self->handler()->{config}->{org};

  my $allowanyfeat= 1; 
#     (!$featset || $featset =~ /^(any|all)/i) ? 1 
#     : (defined $self->config->{allowanyfeat}) ?  $self->config->{allowanyfeat} 
#       : 0;
  my @gmsub;
  my $gmain;
  my ($gnid,$cgid);
  my %gmodl;
  
  while(<$fffin>) {
    next unless(/^\w/); chomp;
    my $fff= $_;

    my @fvals = $self->handler()->splitFFF($fff, $chrIn);
    $self->{ffformat}= $self->{gotffformat}; # set by splitFFF
    
    my($type,$name,$cytomap,$baseloc,$id,$dbxref,$notes,$chr)= @fvals;

    ## need to collect gene model features together, then make acode
#     my($types_ok,$retype,$usedb,$subrange,$types_info)
#        = $self->get_feature_set( $type, $sconfig, $allowanyfeat);
    #next unless( ($types_ok && $types_ok->{$type}) || ($allowanyfeat && !$didfeat) );
    
    next if ($type =~ /$noIDmap/); ## these should go to evidence ...

    my @ids= map { s/$cutdbpattern//i; $_; } split(/,/, $id.",".$dbxref);
    # my ($gid) = grep /FBgn/, @ids;
    my ($gid) = ($dbxref =~ m/(FBgn\d+)/);
    my ($cid) = ($id =~ m/(C[GR]\d+)/);
    # add FBti/TE support
    
    if ($type =~ /^(mRNA|CDS)/) {  # intron|UTR ???
      ## subfeature for acode  
      ## need to check dbxref IDs for same FBgn as for $gmain !
      ## instead use hash by $gid/gnid 
      if ($cid) { 
        $gmodl{$cid}= [] unless($gmodl{$cid});  
        push( @{$gmodl{$cid}}, \@fvals); 
        }
      next;
      }
    elsif ($type =~ /$indexidtype/) { # ^(gene|pseudogene|tRNA) # main feature
      if ($gmain) {     
        $self->putrec( $outh, $gmain, $gmodl{$cgid}); 
        $nout++; @gmsub=(); $gmain=undef;  delete $gmodl{$cgid};
        }
      $gmain= \@fvals; #push(@gmsub,\@fvals);
      $gnid= $gid;
      $cgid= $cid;
      next;
      }
    else {
      next;
      }
      
    }
    
#   if ($gmain) { 
#     $self->putrec(  $outh, $gmain, \@gmsub); $nout++; @gmsub=(); $gmain=undef;
#     }
  if ($gmain) {     
    $self->putrec( $outh, $gmain, $gmodl{$cgid}); 
    $nout++; @gmsub=(); $gmain=undef;  delete $gmodl{$cgid};
    }

  return $nout;    
}



 ## patch for adding gene IDs to gene model features missing them

sub addIdsToDbxref
{
  my $self = shift;
  my ( $pid,  $dbxref )= @_;
  # my $pid= ($id ? $id : $name);
  $pid =~ s/[_-].*$//; # try for parent id - db prefix: ?
  my $idlist= $self->{idlist}; # from readids ...
  my $idpattern= $self->handler()->{idpattern};
  if ($idlist->{$pid}) { 
    my %dtype=();
    foreach my $x ( $pid, split(/[,;\s]/,$idlist->{$pid})) { 
      if ( $x =~ m/$idpattern/) { ## /(FBgn|FBti|FBan|CG|CR)\d+/
        my $dtype= $1;
        unless( $dtype{$dtype} || ($dbxref && $dbxref =~ m/$x/) ) { 
          $dbxref .= "," if ($dbxref); 
          $dbxref .= $x; 
          } 
        $dtype{$dtype}++;
        }
      }
    }
  return ($dbxref); #??
}

  ##? check notes for synonyms=, other fields?
sub cleanNotes 
{
  my ($self, $notes)= @_;
  my @notes= ();
  if ($notes) {
    my $dropnotes= $self->config->{dropnotes} || 'xxx';
    my %notes=();
    foreach my $n (split(/[;]/,$notes)) {
      if ($n =~ /^(\w+)=(.+)/) { 
        my($k,$v)= ($1,$2);
        if ($dropnotes !~ m/\b$k\b/) { $notes{$k} .= "$v,"; }
        } 
      }
    foreach my $n (sort keys %notes) {
      $notes{$n} =~ s/,$//;
      push(@notes, $n, $notes{$n});
      }
    }
  return @notes;
}




=item @info= get_feature_set($featset, $config, $allowanyfeat)

  given feature type or type-class, return info to screen, remap 
    individual features.  See config <featmap> and associated info.
    
  args:
  featset = single feature or feature set class name (given in configs)
  config  = configuration hash
  allowanyfeat = featset as basic type should be allowed (types_ok)
  
  return ($types_ok,$retype,$usedb,$subrange,$types_info)
  
  types_ok = hash of which basic types are allowed in featset
  retype  = rename basic types to these for output header
  usedb   = pull residues from database rather than chromosome dna (curated bases)
  subrange = expansion range (e.g for gene_expanded2000, etc.)
  types_info = all of featmap information
  
  
=cut

sub get_feature_set
{
  my( $self, $featset, $config, $allowanyfeat)= @_;
  
  #return $self->handler()->get_feature_set($featset,$config,$allowanyfeat);

  my($fromdb,$subrange) = (0,'');
  my @ft=(); 
  my @retype= ();
  my $type_info= {};
  $config = $self->handler->{config} unless($config);
  
  if(!$config->{featmap}->{$featset} && $featset =~ /^(\w+)_extended(\d+)$/) { 
    my ($t,$r)= ($1,$2); $featset= $t; $subrange= "-$r..$r";
    }

  if (defined $config->{featmap}->{$featset}) {
    my $fm= $config->{featmap}->{$featset};
    @ft= split(/[\s,;]/, $fm->{types} || $featset ); #? @{$fm->{types}};
    @retype= split(/[\s,;]/, $fm->{typelabel}) if ($fm->{typelabel});
    $fromdb= $fm->{fromdb} || 0;
    $subrange= $fm->{subrange} || $subrange;
    if ($fm->{method} eq 'between') {
      $fm->{proc}= '&intergeneFromFFF2'; ## FIXME
      }

    $type_info= $fm; # just save all ?
    }
  else {  
  CASE: {
    $featset =~ /^(gene|pseudogene)$/ && do { @ft=($featset); $type_info->{get_id}=1; last CASE; };
    $featset =~ /^(CDS|mRNA)$/ && do { @ft=($featset); last CASE; };
    $featset =~ /^(five_prime_UTR|three_prime_UTR|intron)$/ && do { @ft=($featset); $type_info->{add_id}= 'gene'; last CASE; };
    $featset =~ /^(tRNA|ncRNA|snRNA|snoRNA|rRNA)$/ && do { @ft=($featset); $type_info->{get_id}=1; last CASE; };
    $featset =~ /^(miscRNA)$/ && do { @ft=qw(ncRNA snRNA snoRNA rRNA); last CASE; };
    $featset =~ /^(transposable_element|transposon)$/ && do { @ft=('transposable_element'); last CASE; };
    $featset =~ /^gene_extended(\d+)$/ && do { @ft=('gene'); $subrange="-$1..$1"; @retype=("gene_ex$1");  last CASE; };
    $featset =~ /^(transcript)$/ && do { @ft=('mRNA'); $fromdb=1; @retype=('transcript'); last CASE; };
    $featset =~ /^(CDS_translation|translation)$/ && do { @ft=('CDS'); $fromdb=1; @retype=('translation'); last CASE; };
   
    default: { 
      if ($allowanyfeat) { @ft=($featset); }
      elsif (grep {$featset eq $_} @{$config->{fastafeatok}}) { @ft=($featset); }
      else { return undef; } ## warn "Unknown feature option: $@"; 
      };
    }
    }
    
  $fromdb= 0 if $self->handler()->{ignoredbresidues};
  my %types_ok= map { $_,1; } @ft;
  my %retype  = map { my $f= shift @ft; $f => $_; } @retype;
  return (\%types_ok, \%retype, $fromdb, $subrange, $type_info);
}



1;

__END__

