#!/usr/bin/env perl

# assumes empty password--that should be fixed

use strict;

use DBI;
use Bio::OntologyIO;
use Bio::Ontology::TermFactory;

my ($user, $dbname, $cvname) = @ARGV;
die "USAGE: $0 <username> <dbname> <cvname>" unless $user and $dbname and $cvname;

my $db = DBI->connect("dbi:Pg:dbname=$dbname",$user,'');
my $sth_objects     = $db->prepare("select object_id from cvterm_relationship where subject_id = ? and type_id = ?");
my $sth_subjects    = $db->prepare("select subject_id from cvterm_relationship where object_id = ? and type_id = ?");
my $sth_allobjects  = $db->prepare("select object_id from cvterm_relationship where subject_id = ?");
my $sth_allsubjects = $db->prepare("select subject_id from cvterm_relationship where object_id = ?");

my %type;
my %subject;
my %object;
my %black;
my(%root,%leaf);
my %sot;

my $sth_type = $db->prepare("select cvterm_id from cvterm where cv_id = (select cv_id from cv where name = 'Relationship Ontology')");
$sth_type->execute;
while(my $type_id = $sth_type->fetchrow){
  $type{$type_id}++;
}

my %cvterm;
my $sth_cvterm = $db->prepare("select cvterm_id from cvterm");
$sth_cvterm->execute;
while(my $cvterm_id = $sth_cvterm->fetchrow_array){
  $cvterm{$cvterm_id}++;
}



my $cv_id;
warn "select cv_id from cv where name = '$cvname'";
my $sth_cv = $db->prepare("select cv_id from cv where name = '$cvname'");
$sth_cv->execute;
while(my $cv = $sth_cv->fetchrow_hashref){
  $cv_id = $cv->{cv_id};
}

die "no cv_id for '$cvname'" unless defined $cv_id;

#my $sth_cvterm_relationship = $db->prepare("select subject_id,type_id,object_id from cvterm_relationship");

my $sth_cvterm_relationship = $db->prepare("select subject_id,type_id,object_id from cvterm_relationship,cvterm where cvterm_relationship.subject_id = cvterm.cvterm_id and cvterm.cv_id = $cv_id");
$sth_cvterm_relationship->execute;
while(my $cvterm_relationship = $sth_cvterm_relationship->fetchrow_hashref){
  $subject{$cvterm_relationship->{subject_id}}++;
  $object{$cvterm_relationship->{object_id}}++;
  $sot{$cvterm_relationship->{subject_id}}{$cvterm_relationship->{object_id}}{$cvterm_relationship->{type_id}}++;
}

foreach my $cvterm (keys %cvterm){
  $root{$cvterm}++ if(!$subject{$cvterm} and  $object{$cvterm});
  $leaf{$cvterm}++ if( $subject{$cvterm} and !$object{$cvterm});
}

my %leafbak = %leaf;
%sot = ();

while(keys %leaf){
  foreach my $leaf (keys %leaf){
	foreach my $type (keys %type){
	  recurse([$leaf],$type,1);
	}
	delete $leaf{$leaf};
  }

  #  print "**************************************\n";
}

%leaf = %leafbak;

while(keys %leaf){
  foreach my $leaf (keys %leaf){
	recurse([$leaf],undef,1);
	delete $leaf{$leaf};
  }

  #  print "**************************************\n";
}


sub recurse {
  my($subjects,$type,$dist) = @_;

  my $subject = $subjects->[-1];
#  print $subject,"\n";

  my @objects = objects($subject,$type);
  if(!@objects){
	$leaf{$subject}++;
	return;
  }

  foreach my $object (@objects){
	my $tdist = $dist;
	foreach my $s (@$subjects){
	  next if $sot{$s}{$object}{$type}{$tdist};
	  $sot{$s}{$object}{$type}{$tdist}++;

#	  print $tdist,"\t"x$dist,"\t",$s,"\t",$object,"\t",$type||'transitive',"\n";
	  if(defined $type){
		print "insert into cvtermpath (subject_id,object_id,type_id,cv_id,pathdistance) values
                                      ($s,$object,$type,$cv_id,$tdist);\n";
		my $ttdist = -1 * $tdist;
		print "insert into cvtermpath (subject_id,object_id,type_id,cv_id,pathdistance) values
                                      ($object,$subject,$type,$cv_id,$ttdist);\n";
	  } else {
		print "insert into cvtermpath (subject_id,object_id,type_id,cv_id,pathdistance) values
                                      ($s,$object,(select cvterm_id from cvterm where name = 'OBO_REL:0001'),$cv_id,$tdist);\n";
		print "insert into cvtermpath (subject_id,object_id,type_id,cv_id,pathdistance) values
                                      ($object,$subject,(select cvterm_id from cvterm where name = 'OBO_REL:0001'),$cv_id,-$tdist);\n";
	  }
	  $tdist--;
	}
	$tdist = $dist;
	recurse([@$subjects,$object],$type,$dist+1);
  }

}

#-------------------


sub objects {
  my($subject,$type) = @_;
#warn $subject;
  my @objects;
  if(defined($type)){
	$sth_objects->execute($subject,$type);
	while(my $object = $sth_objects->fetchrow_array){
	  push @objects, $object;
	}
  } else {
	$sth_allobjects->execute($subject);
	while(my $object = $sth_allobjects->fetchrow_array){
	  push @objects, $object;
	}
  }

  return @objects;
}

sub subjects {
  my($object,$type) = @_;
  my @subjects;
  if(defined($type)){
	$sth_subjects->execute($object,$type);
	while(my $subject = $sth_subjects->fetchrow_array){
	  push @subjects, $subject;
	}
  } else {
	$sth_allsubjects->execute($object);
	while(my $subject = $sth_allsubjects->fetchrow_array){
	  push @subjects, $subject;
	}
  }

  return @subjects;
}
