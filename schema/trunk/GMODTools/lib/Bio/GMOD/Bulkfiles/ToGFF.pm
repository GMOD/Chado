package Bio::GMOD::Bulkfiles::ToGFF;
use strict;

=head1 NAME

  Bio::GMOD::Bulkfiles::ToGFF 
  
=cut

our $DEBUG = 0;
use vars qw/@ISA/;
BEGIN {
@ISA = qw/ Bio::GMOD::Bulkfiles::ToFormat /;
}


sub init {
	my $self= shift;
	$self->SUPER::init();
}



=item writeGFF v3

  ##gff-version   3
  ##sequence-region   ctg123 1 1497228      == source in fff
  ctg123 . gene            1000  9000  .  +  .  ID=gene00001;Name=EDEN
  ctg123 . TF_binding_site 1000  1012  .  +  .  ID=tfbs00001;Parent=gene00001
  ctg123 . mRNA            1050  9000  .  +  .  ID=mRNA00001;Parent=gene00001;Name=EDEN.1
  ctg123 . 5_prime_UTR          1050  1200  .  +  .  Parent=mRNA0001
  ctg123 . CDS             1201  1500  .  +  0  Parent=mRNA0001
  ctg123 . CDS             3000  3902  .  +  0  Parent=mRNA0001
  ctg123 . CDS             5000  5500  .  +  0  Parent=mRNA0001
  ctg123 . CDS             7000  7600  .  +  0  Parent=mRNA0001
  ctg123 . 3_prime_UTR          7601  9000  .  +  .  Parent=mRNA0001

=cut

sub writeheader ## writeGFF3header
{
	my $self= shift;
  my($seqid,$start,$stop)= @_;
  my $fh= $self->{outh};
  
  if ((!defined $stop || $stop == 0)) {
    $stop= $start; $start= 1;  # start == length
    }
    
  my $date = $self->{handler}->{date};
  my $sourcetitle = $self->{handler}->{sourcetitle};
  my $org= $self->{handler}->{org};
  print $fh "##gff-version\t3\n";
  print $fh "##sequence-region\t$seqid\t$start\t$stop\n";
  print $fh "#organism\t$org\n";
  print $fh "#source\t$sourcetitle\n";
  print $fh "#date\t$date\n";
  print $fh "#\n";
  ##sequence-region   ctg123 1 1497228      == source in fff
  ## if ($stop > $start) ...
  print $fh join("\t", $seqid, ".","chromosome", $start, $stop, '.', '.', '.', "ID=$seqid"),"\n";
   
}

sub splitGffType
{
	my $self= shift;
  my($gffsource,$type)= @_;
  my $maptype_gff= $self->{handler}->{config}->{maptype_gff};
  
    # convert mRNA_genscan,mRNA_piecegenie to gffsource,mRNA ?
  if ($$maptype_gff{$type}) {
    ($type,$gffsource)= @{$$maptype_gff{$type}};
    }
  elsif ($type =~ m/^([\w\_]+)[\.:]([\w\_]+)$/) {
    ($type,$gffsource)=($1,$2);
    }
  return($gffsource,$type);
}

sub _gffEscape
{
  my $v= shift;
  $v =~ tr/ /+/;
  $v =~ s/([\t\n\=;,])/sprintf("%%%X",ord($1))/ge; # Bio::Tools::GFF _gff3_string escaper
  return $v;
}

sub writeendobj ## writeGFFendfeat
{
	my $self= shift;
  my $fh= $self->{outh};
  print $fh "###\n";
}


=item writeobj // writeGFF  
   
   write  one feature in gff3
   feature may have sub location parts (multi line)
   
=cut

sub writeobj
{
	my $self= shift;
  my($fob,$oidobs)= @_;
  my $fh= $self->{outh};
  my $v;
  my $type= $fob->{type};
  $fob->{'writegff'}=1;
  
  my $dropfeat_gff= $self->{handler}->{config}->{dropfeat_gff};
  if ($$dropfeat_gff{$type}) { return; }
  my $segmentfeats= $self->{handler}->{config}->{segmentfeats};

  my $gffsource=".";
  my $oid= $fob->{oid};  
  my $id = $fob->{id}; ## was: $fob->{oid}; -- preserve uniquename ?
  my $chr= $fob->{chr};
  my @loc= @{$fob->{loc}};
  my @attr= @{$fob->{attr}};
  my $at="";
  my @at=();
  
  ## gff3 loader is using ID for uniquename, unless give attr key for uniquename
  ## ? do we want to drop $oid and use id/dbid - is it always uniq in gff file?
  ## below Parent from {id} is not working; need all forward refs resolved here
  
  push @at, "ID="._gffEscape($id) if ($id); # use this for gff internal id instead of public id?
  push @at, "Name="._gffEscape($v) if (($v= $fob->{name}) && $v ne $id);
  if ($self->{handler}->{keepoids}) {  push @at, "oid=$oid"; }

  my %at= ();
  foreach (@attr) {
    my ($k,$v)= split "\t";
    if (!$v) { next; }
    elsif ($k eq "object_oid") {}
    elsif ($k eq "parent_oid") {
      if ($self->{handler}->{keepoids}) { $at{$k} .= ',' if $at{$k}; $at{$k} .= $v; }
      next if $$segmentfeats{$type}; # dont do parent for these ... ?
      
      $v =~ s/:.*$//; #$v= $oidmap{$v} || $v;
      $k= 'Parent'; #push @at, "Parent=$v";
      
      ## now need to convert oid to parent id, given above change to id
      ## BUT this is bad when Parent hasn't been seen yet !
      my $parob= $oidobs->{$v}->{fob};
      $v= $parob->{id} if ($parob && $parob->{id});
      }
    elsif ($k eq "dbxref") { # dbxref_2nd - leave as separate 
      $k= 'Dbxref'; 
      ##$v= "\"$v\"";  # NO quotes - spec says to but BioPerl::GFFv3 reader doesn't strip quotes
      }
      
    $at{$k} .= ',' if $at{$k};
    $at{$k} .= _gffEscape($v);  # should be urlencode($v) - at least any [=,;\s]
    }
    
  foreach my $k (sort keys %at) { push(@at, "$k=$at{$k}"); }
  $at = join(";",@at);
  
  ($gffsource,$type)= $self->splitGffType($gffsource,$type);
  
    ## need to make uniq ids for dupl oids - any @loc > 1 ?
    ## and need to make parent feature to join.  Use ID=OID.1... OID.n
  if (@loc>1) {
    my ($b,$e,$str)=(-999,0,0);
    foreach my $loc (@loc) {
      my($start,$stop,$strand)= split("\t",$loc);
      if ($b == -999) { ($b,$e) = ($start,$stop); $str= $strand; }
      else { $b= $start if ($b > $start); $e= $stop if ($e < $stop); }
      }
    $str= (!defined $str || $str eq '') ? '.' : ($str < 0) ? '-' : ($str >= 1)? '+' : '.';
    print $fh join("\t", $chr,$gffsource,$type,$b,$e,".",$str,".",$at),"\n";

    ## GFF v3 spec is unclear on what this $gffsource item contains.
    ## gffsource used for genscan, etc. type modifier 
    
    $gffsource='part_of' if ($gffsource eq '.'); #? was 'part'
    
    foreach my $i (1..$#loc+1) {
      my($start,$stop,$strand)= split("\t",$loc[$i-1]);
      $strand= (!defined $strand || $strand eq '') ? '.' : ($strand < 0) ? '-' : ($strand >= 1)? '+' : '.';
      $at= "ID=$id.$i;Parent=$id";
      print $fh join("\t", $chr,$gffsource,$type,$start,$stop,".",$strand,".",$at),"\n";
      }
    }
  else {
    my $loc= shift @loc;
    my($start,$stop,$strand)= split("\t",$loc);
    $strand= (!defined $strand || $strand eq '') ? '.' : ($strand < 0) ? '-' : ($strand >= 1)? '+' : '.';
    print $fh join("\t", $chr,$gffsource,$type,$start,$stop,".",$strand,".",$at),"\n";
    }
}

#-------------

1;

