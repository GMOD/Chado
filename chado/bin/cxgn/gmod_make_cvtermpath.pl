#!/usr/bin/perl

=pod

=head1 NAME

gmod_make_cvtermpath.pl

=head1 USAGE 

 perl gmod_make_cvtermpath.pl -H [dbhost] -D [dbname]  [-vt] -c cvname
 perl gmod_make_cvtermpath.pl -g [GMODConf_profile] -c cvname

=head2 Parameters

=over 4


=item -c 

Name of ontology (cv.name) to compute the transitive closure on. (Required)

=item -v

Verbose output
 
=item -t

Trial mode. Do not perform any store operations at all. (Not implemented)

=item -g

GMOD database profile name (can provide host and DB name) Default: 'default'

=back

=head2 If not using a GMOD database profile (option -g) then you must provide the following parameters

=over 5

=item -D 

Database name 

=item -H 

Hostname


=item -d 

Database driver name (e.g. 'Pg' for postgres)

=item -u

[Optional- if default user is not used]
Database user name 

=item -p 

[Optional- if you need a password to connect to your database] 
Password for your user to connect to the database



=back

=head1 DESCRIPTION

This script calculates the transitive closure on the ontology terms in the cvterm
table.  As this is a computationaly intensive operation, doing so on a large
cv like the Gene Ontology can take several hours.  For more information on what
a transative closure is, please see:

  http://www.geneontology.org/GO.database.shtml#graphs

=head1 AUTHOR

Naama Menda <nm249@cornell.edu>

=head1 VERSION AND DATE

Version 1.1, April 2010.

=cut


use strict;

use DBI;
use Bio::OntologyIO;
use Bio::Ontology::TermFactory;

use Bio::Chado::Schema;
##########
use Bio::GMOD::Config;
use Bio::GMOD::DB::Config;
use Getopt::Std;

our ($opt_H, $opt_D, $opt_v, $opt_t,  $opt_g, $opt_p, $opt_d, $opt_u, $opt_c);

getopts('H:D:c:p:g:p:d:u:tv');


my $dbhost = $opt_H;
my $dbname = $opt_D;
my $pass = $opt_p;
my $driver = $opt_d;
my $user = $opt_u;
my $cvname = $opt_c;
my $verbose = $opt_v;

my $DBPROFILE = $opt_g ;

print "H= $opt_H, D= $opt_D, u=$opt_u, d=$opt_d, v=$opt_v, t=$opt_t , cvname = $opt_c  \n" if $verbose;

my $port = '5432';

if (!($opt_H and $opt_D) ) {
    my $DBPROFILE = $opt_g;
    $DBPROFILE ||= 'default';
    my $gmod_conf = Bio::GMOD::Config->new() ;
    my $db_conf = Bio::GMOD::DB::Config->new( $gmod_conf, $DBPROFILE ) ;
    
    $dbhost ||= $db_conf->host();
    $dbname ||= $db_conf->name();
    $driver = $db_conf->driver();
    

    $port= $db_conf->port();
    
    $user= $db_conf->user();
    $pass= $db_conf->password();
}

if (!$dbhost && !$dbname) { die "Need -D dbname and -H hostname arguments.\n"; }
if (!$driver) { die "Need -d (dsn) driver, or provide one in -g gmod_conf\n"; }
if (!$user) { die "Need -u user_name, or provide one in -g gmod_conf\n"; }

#we can allow blank passwords
#if (!$pass) { die "Need -p password, or provide one in -g gmod_conf\n"; }
if (!$cvname) { die "Need to provide -c cv.name ! \n" ; } 

my $dsn = "dbi:$driver:dbname=$dbname";
$dsn .= ";host=$dbhost";
$dsn .= ";port=$port";

my $schema= Bio::Chado::Schema->connect($dsn, $user, $pass||'', { AutoCommit=>0 });

my $db=$schema->storage->dbh();

if (!$schema || !$db) { die "No schema or dbh is avaiable! \n"; }

print STDOUT "Connected to database $dbname on host $dbhost.\n" if $verbose;
##########


#die "USAGE: $0 <dbhost> <dbname> <cvname>" unless $dbhost and $dbname and $cvname;


my %type;
my %subject;
my %object;
my %black;
my(%root,%leaf);
my %sot;

my $sth_type = $db->prepare("select cvterm_id from cvterm where cv_id = (select cv_id from cv where name ilike 'Relationship')");
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
warn "select cv_id from cv where name = '$cvname'" if $verbose;
my $sth_cv = $db->prepare("select cv_id from cv where name = '$cvname'");
$sth_cv->execute;
while(my $cv = $sth_cv->fetchrow_hashref){
  $cv_id = $cv->{cv_id};
}

die "no cv_id for '$cvname'" unless defined $cv_id;

##############

#delete existing cvtermpath rows
$schema->resultset("Cv::Cvtermpath")->search({cv_id => $cv_id} )->delete();
#######

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
  my $path;
  foreach my $object (@objects){
	my $tdist = $dist;
	foreach my $s (@$subjects){
	  next if $sot{$s}{$object}{$type}{$tdist};
	  $sot{$s}{$object}{$type}{$tdist}++;
	 
#	  print $tdist,"\t"x$dist,"\t",$s,"\t",$object,"\t",$type||'transitive',"\n";
	  if(defined $type){
	      
	      $path = $schema->resultset("Cv::Cvtermpath")->find_or_create( 
		  {
		      subject_id => $s,
		      object_id  => $object,
		      type_id    => $type,
		      cv_id      => $cv_id,
		      pathdistance => $tdist
		  }, { key => 'cvtermpath_c1' } , );
	      print STDOUT "Inserting ($s,$object,$type,$cv_id , $tdist) into cvtermpath...path_id = " . $path->cvtermpath_id(). "\n" if $verbose;
	      my $ttdist = -1 * $tdist;
	      
	      $path = $schema->resultset("Cv::Cvtermpath")->find_or_create( 
		  {
		      subject_id => $object,
		      object_id  => $subject,
		      type_id    => $type,
		      cv_id      => $cv_id,
		      pathdistance => $ttdist
		  }, { key => 'cvtermpath_c1' } , );
	      print STDOUT "Inserting ($object,$subject,$type,$cv_id , $ttdist) into cvtermpath...path_id = " . $path->cvtermpath_id() . "\n" if $verbose;
	  } else {

	      my $is_a = $schema->resultset("Cv::Cvterm")->search({ name => 'is_a' })->first();
	       
	      $path = $schema->resultset("Cv::Cvtermpath")->find_or_create( 
		  {
		      subject_id => $s,
		      object_id  => $object,
		      type_id    => $is_a->cvterm_id(),
		      cv_id      => $cv_id,
		      pathdistance => $tdist
		  }, { key => 'cvtermpath_c1' } , );
	      print STDOUT "Inserting ($s,$object, $type, " . $is_a->cv_id() . "  , $tdist) into cvtermpath...path_id = " . $path->cvtermpath_id() . "\n" if $verbose;
          
	      $path = $schema->resultset("Cv::Cvtermpath")->find_or_create( 
		  {
		      subject_id => $object,
		      object_id  => $subject,
		      type_id    => $is_a->cvterm_id(),
		      cv_id      => $cv_id,
		      pathdistance => -$tdist
		  }, { key => 'cvtermpath_c1' } , );
	      print STDOUT "Inserting ($object,$subject, " . $is_a->cvterm_id() . " ,$cv_id , -$tdist) into cvtermpath... path_id = " . $path->cvtermpath_id() . "\n" if $verbose;   
	  }
	  $tdist--;
	}
	$tdist = $dist;
	recurse([@$subjects,$object],$type,$dist+1);
	$db->commit();
  }
  
}

#-------------------


sub objects {
  my($subject,$type) = @_;
  #warn $subject;
  my @cvterm_rel;
  if(defined($type)){
            
      @cvterm_rel = $schema->resultset("Cv::CvtermRelationship")->search(
	  { subject_id  => $subject,
	    type_id     => $type ,
	  }
	  );
      
  } else {
      
      @cvterm_rel = $schema->resultset("Cv::CvtermRelationship")->search(
	  { subject_id  => $subject }
	  );
  }
  my @objects = map ($_->object_id, @cvterm_rel)   ;
  return @objects;
}


sub subjects {
  my($object,$type) = @_;
  my @cvterm_rel;
  if(defined($type)){
	
      @cvterm_rel = $schema->resultset("Cv::CvtermRelationship")->search(
	  { object_id  => $object,
	    type_id     => $type ,
	  }
	  );
      
  } else {
      
      @cvterm_rel = $schema->resultset("Cv::CvtermRelationship")->search(
	  { object_id  => $object }
	  );
  }
  my @subjects = map ($_->subject_id, @cvterm_rel)   ;
  
  return @subjects;
}
