#!/usr/bin/env perl

=pod

=head1 NAME

gmod_make_cvtermpath.pl

=head1 USAGE 

 perl gmod_make_cvtermpath.pl -H [dbhost] -D [dbname]  [-vt] -c cvname
 perl gmod_make_cvtermpath.pl -g [GMODConf_profile] -c cvname

=head2 Parameters

=over 5


=item -c

Name of ontology (cv.name) to compute the transitive closure on. (Required)

=item -v

Verbose output

=item -t

Trial mode. Do not perform any store operations at all. (Not implemented)

=item -o 

outfile for writing errors and verbose messages (optional)

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

Version 1.2, Feb. 2011.

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
use Try::Tiny;

our ($opt_H, $opt_D, $opt_v, $opt_t,  $opt_g, $opt_p, $opt_d, $opt_u, $opt_c, $opt_o);

getopts('H:D:c:p:g:p:d:u:o:tv');


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
if (!$cvname) { die "Need to provide -c cv.name ! \n" ; }

my $dsn = "dbi:$driver:dbname=$dbname";
$dsn .= ";host=$dbhost";
$dsn .= ";port=$port";

my $schema= Bio::Chado::Schema->connect($dsn, $user, $pass||'');

my $db=$schema->storage->dbh();

if (!$schema || !$db) { die "No schema or dbh is avaiable! \n"; }

print STDOUT "Connected to database $dbname on host $dbhost.\n" if $verbose;
##########


if ($opt_o) { open (OUT, ">$opt_o") ||die "can't open error file $opt_o for writting.\n" ; }



my %type;
my %subject;
my %object;
my %black;
my %root;
our %leaf;
my %sot;

my $sth_type = $db->prepare("select cvterm_id from cvterm where is_relationshiptype = ?");
$sth_type->execute(1);
while(my $type_id = $sth_type->fetchrow){
  $type{$type_id}++;
}

my %cvterm;
my $sth_cvterm = $db->prepare("select cvterm_id from cvterm WHERE is_relationshiptype = 0");
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

  #hash of subject-object-type. Stores all the relationships defined in cvterm_relationship table.
  $sot{$cvterm_relationship->{subject_id}}{$cvterm_relationship->{object_id}}{$cvterm_relationship->{type_id}}++;
}

#populate hash of roots (terms without parents (objects)) and hash of leaves (terms without child terms (subjects)) 
foreach my $cvterm (keys %cvterm){
  $root{$cvterm}++ if(!$subject{$cvterm} and  $object{$cvterm});
  $leaf{$cvterm}++ if( $subject{$cvterm} and !$object{$cvterm});
}

my %leafbak = %leaf;
%sot = ();

# this is a hash for storing the already-processed leaves for a given type term.
our %seen ;


while(keys %leaf){
    foreach my $l (keys %leaf){
	foreach my $type (keys %type){
	    #add the leaf-type term to the seen list.
	    $seen{$l}{$type}++;
	    #sending the leaf as an arrayref to the recurse fuction. Distance starts with 1
	    recurse([$l],$type,1);
	}
	delete $leaf{$l};
	message("DELETED leaf $l ! number of leaves is now : " .(scalar(keys(%leaf))) . "\n" ) ;
    }
    message("DONE recursing leaves \n");
}
message("DONE FIRST LEAF RECURSIION! About to create the transitive path.\n");

%leaf = %leafbak;
%seen = ();


while(keys %leaf){
    foreach my $le (sort keys %leaf){
	$seen{$le}{0}++;
	#calling recurse with leaf $le
	recurse([$le],0,1);
	#deleting the leaf from the list
	delete $leaf{$le};
       message("Deleted leaf $le!  after deleting number of leaves is : " .(scalar(keys(%leaf))) . "\n");
    }
    message("FINISHED RECURSING for the transitive path (type = IS_A) \n");
}


sub recurse {
  my($subjects,$type,$dist) = @_;

  # start with the last subject
  my $subject = $subjects->[-1];
  #get the parents for the subject with this type (defaults to IS_A)
  my @objects = objects($subject,$type);

  #if there are no parents for this path, exit the loop (and the next leaf will be sent here again)
  if(!@objects){
      $leaf{$subject}++ ;
      return;
  }
  my $path;

  # foreach parent construct a path with each child
  foreach my $object (@objects){
      my $coderef = sub {
          my $tdist = $dist;
          # loop through the child terms
          foreach my $s (@$subjects){
              #next if the path was seen (subject-object-type-distance)
              next if $sot{$s}{$object}{$type}{$tdist};
              if (exists($sot{$s}{$object}) && exists($sot{$object}{$s})) { 
                  die " YOU HAVE A CYCLE IN YOUR ONTOLOGY for $s, $object ($type, $tdist)    C8-( \n" ;
              }
              $sot{$s}{$object}{$type}{$tdist}++;
              print $tdist,"\t"x$dist,"\t",$s,"\t" , $object,"\t" ,$type||'transitive',"\n";

              # if type is defined , create a path using it (see the first looping through %leaf keys) 
              if($type){
                  $path = $schema->resultset("Cv::Cvtermpath")->find_or_create( 
                      {
                          subject_id => $s,
                          object_id  => $object,
                          type_id    => $type,
                          cv_id      => $cv_id,
                          pathdistance => $tdist
                      }, { key => 'cvtermpath_c1' } , );
                  message( "Inserting ($s,$object,$type,$cv_id , $tdist) into cvtermpath...path_id = " . $path->cvtermpath_id(). "\n" );
                  my $ttdist = -1 * $tdist;

                  $path = $schema->resultset("Cv::Cvtermpath")->find_or_create( 
                      {
                          subject_id => $object,
                          object_id  => $subject,
                          type_id    => $type,
                          cv_id      => $cv_id,
                          pathdistance => $ttdist
                      }, { key => 'cvtermpath_c1' } , );
                  message( "Inserting ($object,$subject,$type,$cv_id , $ttdist) into cvtermpath...path_id = " . $path->cvtermpath_id() . "\n" );
              } else {  # if type exists (see second looping through %leaf keys) create a path using the is_a type
                  message("No type defined! Using default IS_A relationship\n");
                  my $is_a = $schema->resultset("Cv::Cvterm")->search({ name => 'is_a' })->first();

                  $path = $schema->resultset("Cv::Cvtermpath")->find_or_create( 
                      {
                          subject_id => $s,
                          object_id  => $object,
                          type_id    => $is_a->cvterm_id(),
                          cv_id      => $cv_id,
                          pathdistance => $tdist
                      }, { key => 'cvtermpath_c1' } , );
                  message("Inserting ($s,$object, $type, " . $is_a->cv_id() . "  , $tdist) into cvtermpath...path_id = " . $path->cvtermpath_id() . "\n" );

                  $path = $schema->resultset("Cv::Cvtermpath")->find_or_create( 
                      {
                          subject_id => $object,
                          object_id  => $subject,
                          type_id    => $is_a->cvterm_id(),
                          cv_id      => $cv_id,
                          pathdistance => -$tdist
                      }, { key => 'cvtermpath_c1' } , );
                  message( "Inserting ($object,$subject, " . $is_a->cvterm_id() . " ,$cv_id , -$tdist) into cvtermpath... path_id = " . $path->cvtermpath_id() . "\n" );
              }
              $tdist--;
          }
          $tdist = $dist;
          # recurse with arrayref of subjects and the object, increment the pathdistance
          recurse([@$subjects,$object],$type,$dist+1);
      };
      try {
          $schema->txn_do($coderef);
      } catch {
          die "An error occured. Rolling back! " . $_ . "\n\n";
      };
  } #object
} #recurse

#-------------------

sub objects {
  my($subject,$type) = @_;
  my @cvterm_rel;
  if($type){

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
  if($type){

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


sub message {
    my $message = shift;
    my $default=shift;
    if ($opt_v || $default) {  print STDOUT "$message"; }
    print OUT "$message" if $opt_o;
}
