package Bio::GMOD::Bulkfiles::ToFFF;
use strict;

=head1 NAME

  Bio::GMOD::Bulkfiles::ToFFF 
  
=cut


# debug
use lib("/bio/biodb/common/perl/lib", "/bio/biodb/common/system-local/perl/lib");

our $DEBUG = 0;
use vars qw/@ISA/;
BEGIN {
@ISA = qw/ Bio::GMOD::Bulkfiles::ToFormat /;
}

use constant TOP_SORT => -9999999;

sub init {
	my $self= shift;
	$self->SUPER::init();
  $self->{handler}->{fff_mergecols}=1 unless defined $self->{handler}->{fff_mergecols};
}


sub writeheader ##writeFFF1header
{
	my $self= shift;
  my($seqid,$start,$stop)= @_;
  my $fh= $self->{outh};
  
  if ((!defined $stop || $stop == 0)) {
    $stop= $start; $start= 1; # start == length
    }
  my $date = $self->{handler}->{date};
  my $sourcetitle = $self->{handler}->{sourcetitle};
  my $sourcefile = $self->{handler}->{sourcefile};
  my $org= $self->{handler}->{org};
  print $fh "# Features for $org from $sourcetitle [$sourcefile, $date]\n";
  print $fh "# gnomap-version 1\n";
  print $fh "# source: ",join("\t", $seqid, "$start..$stop"),"\n";
  print $fh "# ",join("\t", qw(Feature gene map range id db_xref notes)),"\n";
  print $fh "#\n";
   
  if ($stop > $start) {
    if ( $self->{handler}->{fff_mergecols} ) {
      my $bstart= TOP_SORT; # if ($self->{handler}->{topsort}->{$fob->{type}});
      print $fh join("\t", $seqid, $bstart, "source", $org, $seqid, "$start..$stop")."\n";
      }
    else {
      print $fh join("\t", "source", $org, $seqid, "$start..$stop")."\n";
      }
    }
}


=item getFFF v1

  return tab-delimied feature lines in this format 
  # gnomap-version $gnomapvers
  # Feature	gene 	map 	range 	id	db_xref  	notes
  
  feature == feature type
  gene    == gene name
  map     == cytology map
  range   == GenBank/EMBL/DDBJ location, BioPerl FTstring)
  id      == feature id
  db_xref == database crossrefs (, delimited)
  notes   == miscellany, now key=value; list
  
=cut

sub get ##getFFF 
{
	my $self= shift;
  my($fob)= @_;
  return if ($fob->{'writefff'}); #?? so far ok but for mature_peptide/CDS thing
  $fob->{'writefff'}=1;
  my @loc= @{$fob->{loc}};
  my @attr= @{$fob->{attr}};
  
  my $featname= $fob->{type};
  my($id,$s_id)= $self->{handler}->remapId($featname,$fob->{id},'-');  # FIXME
  $id= '-' unless (defined($id) && $id);
  
  my $sym= $fob->{name} || '-';
  my $map= '-';
  my $dbxref=""; my $dbxref_2nd="";
  my $notes= "";
  foreach (@attr) {
    my ($k,$v)= split "\t";
    if ($k eq "parent_oid" || $k eq "object_oid") {
      ##$v =~ s/:.*$//; #$v= $oidmap{$v} || $v;
      ##$at .= "Parent=$v;" 
      }
    elsif ($k eq "cyto_range") { $map= $v; }
    elsif ($k eq "dbxref") { ## and dbxref_2nd; put after dbxref !
      $dbxref .= "$v;"; 
      }
    elsif ($k eq "dbxref_2nd") {  
      $dbxref_2nd .= "$v;"; 
      }
    else {
      $notes .= "$k=$v;" 
      }
    }

  $dbxref .= $dbxref_2nd; # aug04: making sure 2nd are last is enough to get 1st ID
  
  my ($srange,$bstart);
  #my $srange = $fob->{location}; # computed already for transsplice ?
  #my $bstart = $fob->{start}; # computed already for transsplice ?
  #unless($srange && defined $bstart) { ...
  ($srange,$bstart) = $self->{handler}->getLocation($fob,@loc); #FIXME
  
  ## add chr,start to front cols for sort-merge
  my $line;
  if ($self->{handler}->{fff_mergecols}) {
    my $chr= $fob->{chr};
    $line= join("\t", $chr,$bstart,$featname,$sym,$map,$srange,$id,$dbxref,$notes)."\n";
    }
  else {
    $line= join("\t", $featname,$sym,$map,$srange,$id,$dbxref,$notes)."\n";
    }
  return $line;
}


sub writeendobj ## writeGFFendfeat
{
	my $self= shift;
  #my $fh= $self->{outh};
  #print $fh "###\n";
}


sub writeobj ##writeFFF 
{
	my $self= shift;
  my( $fob)= @_;
  my $fh= $self->{outh};
  my $line= $self->get($fob);
  print $fh $line if $line;
}


#---------------------

1;
