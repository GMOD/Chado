
=head1 NAME

gmod_bulk_load_pubmed.pl

=head1 DESCRIPTION

 Usage: perl gmod_bulk_load_pubmed.pl -H [dbhost] -D [dbname]  [-vt] -i file


parameters

=over 6

=item -H

hostname for database 

=item -D

database name 

=item -i 

input file [required]

=item -v

verbose output
 
=item -t

trial mode. Do not perform any store operations at all.

=item -g

GMOD database profile name (can provide host and DB name) Default: 'default'

=back

=head2 If not using a GMOD database profile (option -g) then you must provide the following parameters

=over 3

=item -u

user name 

=item -d 

database driver name (i.e. 'Pg' for postgres)

=item -p 

password for youe user to connect to the database


=back

The script stores pubmed entries in the database.
Existing ones are ignored. 
Input file should contain a list of pubmed ids. Then a new Publication object (Bio::Chado::Schema::Pub::Pub) with accession= PMID,
the publication specs are fetched from Entrez (using eUtils) which sets the different fields in the Publication object. When the publication is stored, a new dbxref is stored first (see Chado General module)   

=head2 This script works with Chado schema and accesse the following tables:

=over 5

=item pub

=item pubauthor

=item pubprop

=item dbxref

=item pub_dbxref


=back


=head1 AUTHOR

Naama Menda <nm249@cornell.edu>

=head1 VERSION AND DATE

Version 1.1, April 2010.

=cut


#! /usr/bin/env perl
use strict;
use warnings;


use Bio::GMOD::Config;
use Bio::GMOD::DB::Config;

use Bio::Chado::Schema;
use XML::Twig;
use LWP::Simple qw/ get /;

use Getopt::Std;

our ($opt_H, $opt_D, $opt_v, $opt_t, $opt_i,  $opt_g, $opt_p, $opt_d, $opt_u);

getopts('H:D:i:p:g:p:d:u:tv');

our $publication;


my $dbhost = $opt_H;
my $dbname = $opt_D;
my $infile = $opt_i;
my $pass = $opt_p;
my $driver = $opt_d;
my $user = $opt_u;

my $DBPROFILE = $opt_g ;

print "H= $opt_H, D= $opt_D, u=$opt_u, d=$opt_d, v=$opt_v, t=$opt_t, i=$opt_i  \n";

my $port;
my ($dbh, $schema);

if ($opt_g) {
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
#if (!$pass) { die "Need -p password, or provide one in -g gmod_conf\n"; }

my $dsn = "dbi:$driver:dbname=$dbname";
$dsn .= ";host=$dbhost";
$dsn .= ";port=$port";

$schema= Bio::Chado::Schema->connect($dsn, $user, $pass||'', { AutoCommit=>0 });

$dbh=$schema->storage->dbh();

if (!$schema || !$dbh) { die "No schema or dbh is avaiable! \n"; }

print STDOUT "Connected to database $dbname on host $dbhost.\n";
#####################################################################################################

my $sth;

my %seq  = (
    db         => 'db_db_id_seq',
    dbxref     => 'dbxref_dbxref_id_seq',
    pub        => 'pub_pub_id_seq',
    pub_dbxref => 'pub_dbxref_pub_dbxref_id_seq',
    pubauthor  => 'pubauthor_pubauthor_id_seq',
    pubprop    => 'pubprop_pubprop_id_seq',
    cv         => 'cv_cv_id_seq',
    cvterm     => 'cvterm_cvterm_id_seq',
    );

open (INFILE, "<$infile") || die "can't open file $infile";   #
open (ERR, ">$infile.err") || die "Can't open the error ($infile.err) file for writing.\n";
my $exists_count=0;
my $pubmed_count=0;

my %maxval=();

eval {
    
    #Fetch last database ids of relevant tables for resetting in case of rollback
  
    foreach my $key( keys %seq) {
	my $id_column= $key . "_id";
	my $table =  $key;
	my $query = "SELECT max($id_column) FROM $table";
	$sth=$dbh->prepare($query);
	$sth->execute();
	my ($next) = $sth->fetchrow_array();
	$maxval{$key}= $next;
    }

    #db name for pubmed ids
    my $db= $schema->resultset("General::Db")->find_or_create(
	{ name => 'PMID' } ); 
    my $db_id = $db->get_column('db_id');

    #cvterm_name for 'journal' . Currently this software does not support other types. All PubMed publications are stored with this default 'journal' type_id
    my $journal_cvterm = $schema->resultset('Cv::Cvterm')->create_with(
	{name=>'journal', cv=>'publication'});
    
    while (my $line = <INFILE>) {
	
	$publication = undef;
	
	chomp $line;
	my $pmid;
	if ( $line=~ m/(\[PMID: )(\d+)(.*)/ ) { 
	    $pmid= $2; 
	}else { $pmid=$line;}
	if (!$pmid) { next(); }
	
	#add a dbxref
	my $dbxref = $schema->resultset("General::Dbxref")->find_or_create(
	    { accession => $pmid,
	      db_id => $db_id,
	    });
	
	##
	# new Bio::Chado::Schema::Pub::Pub object
	my $pub_dbxref = $dbxref->find_related ('pub_dbxrefs', {}, { key=> 'pub_dbxref_c1' }, );
	$publication= $pub_dbxref->find_related('pub', {}, { key=> 'pub_c1'}, ) if $pub_dbxref;
	
	if(!($publication)) { #publication does not exist in our database
	    $pubmed_count++;
	    $publication = $schema->resultset('Pub::Pub')->new( {} ) ; 
	    
	    my $message= fetch_pubmed($pmid);
	    
	    if ($message) { message($message,1); }
	    print STDOUT "storing new publication. pubmed id = $pmid\n";
	    ####
	    #extract the abstract and uniquename assigned in Pubmed.pm
	    my $abstract = $publication->uniquename();
	    print STDOUT "The abstract is $abstract \n\n\n";
	    my (@authors) = split /-----/ , $publication->title();
	    my $title = shift(@authors);
	    print STDOUT "The title is $title\n\n";
	    $publication->title($title) ;
	    
	    
            #remove the abstract from the uniquename field
	    $publication->set_column(uniquename => $pmid . ":" . $title ) ;
	    $publication->type_id( $journal_cvterm->cvterm_id() );
	    
	    #store the publication in the pub table
	    $publication->insert();
	    
	    #store a pubprop for the abstract
	    #
	    my $pubprop = create_pubprops($publication, { 'abstract'=>$abstract }, { autocreate => 1 } );
	    
	    ## Add pub_dbxref
	    $publication->find_or_create_related('pub_dbxrefs' ,
						 { dbxref_id   => $dbxref->dbxref_id } );
	    ##
	    
	    ##Add the authors
	    my $rank =1;
	    foreach (@authors) {
		my ($surname, $givennames)= split  /\|/, $_;
		print STDOUT "Author: Surname=$surname, givennames = $givennames \n";
		
		$surname =~ s/^\s+|\s+$//g;
		$givennames =~ s/^\s+|\s+$//g;
		$publication->find_or_create_related( 'pubauthors' ,
						      {
							  surname => $surname,
							  givennames => $givennames,
							  rank => $rank++,
						      }
		    );
	    }
	    
	    #publication exists, do nothing
	}else  {  
	    $exists_count++;
	    print STDOUT "Publication $pmid is already stored in the database. Skipping..\n";
	}
    }
};


if($@) {
    print $@;
    print"Failed; rolling back.\n";
   
    foreach my $key ( keys %seq ) { 
	my $value= $seq{$key};
	my $maxvalue= $maxval{$key} || 0;
	if ($maxvalue) { $dbh->do("SELECT setval ('$value', $maxvalue, true)") ;  }
	else {  $dbh->do("SELECT setval ('$value', 1, false)");  }
    }
    $dbh->rollback();
}else{ 
    print"Succeeded.\n";
    print "Inserted $pubmed_count new publications!\n";
    print "$exists_count publication already exist in the database\n";
    
    if($opt_t) {
        print STDOUT "Rolling back!\n";
	foreach my $key ( keys %seq ) { 
	    my $value= $seq{$key};
	    my $maxvalue= $maxval{$key} || 0;
	    
	    if ($maxvalue) { $dbh->do("SELECT setval ('$value', $maxvalue, true)") ;  }
	    else {  $dbh->do("SELECT setval ('$value', 1, false)");  }
	}
	$dbh->rollback();
    }else {
        print STDOUT "Committing...\n";
        $dbh->commit();
    }
}

close ERR;
close INFILE;


sub message {
    my $message=shift;
    my $err=shift;
    if ($opt_v) {
	print STDOUT $message. "\n";
    }
    print ERR "$message \n" if $err;
}



sub sanitize {
    my $string = shift;
    $string =~ s/^\s+//; #remove leading spaces
    $string =~ s/\s+$//; #remove trailing spaces
    return $string;
}


sub create_pubprops {
    my ($self, $props, $opts) = @_;
    
    # process opts
    $opts ||= {};
    $opts->{cv_name} = 'publication'
	unless defined $opts->{cv_name};
    
    return Bio::Chado::Schema::Util->create_properties
	( properties => $props,
	  options    => $opts,
	  row        => $self,
	  prop_relation_name => 'pubprops',
	);
}

sub reset_sequences {
    my %seq=@_;
    my %maxval=@_;
    #reset sequences
    foreach my $key ( keys %seq ) { 
	my $value= $seq{$key};
	my $maxvalue= $maxval{$key} || 0;
	#print STDERR "$key: $value, $maxvalue \n";
	if ($maxvalue) { $dbh->do("SELECT setval ('$value', $maxvalue, true)") ;  }
	else {  $dbh->do("SELECT setval ('$value', 1, false)");  }
    }
}


sub fetch_pubmed {
    
    my $accession=shift;
    my $pub_xml = get("http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&id=$accession&rettype=xml&retmode=text");
    
    eval {
	my $twig=XML::Twig->new(
	    twig_roots   => 
	    {
		'Article/ArticleTitle'    => \&title,
		'JournalIssue/Volume'     => \&volume,
		'JournalIssue/Issue'      => \&issue,
		'DateCompleted/Year'      => \&pyear,
		'PubDate/Year'            => \&pyear,
		'Pagination/MedlinePgn'   => \&pages,
		'Journal/Title'           => \&journal_name,
		#'PublicationTypeList/PublicationType'  => \&pub_type,
		'Abstract/AbstractText'   => \&abstract,
		Author       => \&author, 
	    },
	    twig_handlers =>
	    { },
	    pretty_print => 'indented',  # output will be nicely formatted
	    ); 
	
	$twig->parse($pub_xml ); # build it
	
    };
    if($@) {
	my $message= "Error in transaction or NCBI server seems to be down. Please check your input for accession $accession or try again later.\n $@";
	return $message;
    }else { return undef ; }
    
}

##########################################
#Functions for parsing the XML
##########################################

sub title {
    
    my ($twig, $elt)= @_;
    $publication->title($elt->text) ;
    $twig->purge;
}



sub volume {
    my ($twig, $elt)= @_;
    $publication->volume($elt->text) ;
    $twig->purge;
}


sub issue {
    my ($twig, $elt)= @_;
    $publication->issue($elt->text) ;

    $twig->purge;
}


sub pyear {
    my ($twig, $elt)= @_;
    my $pyear = $elt->text;
    $publication->pyear($pyear);

    $twig->purge;
}


sub pages {
    my ($twig, $elt)= @_;
    $publication->pages($elt->text) ;

    $twig->purge;
}



sub journal_name {
    my ($twig, $elt)= @_;
    $publication->series_name($elt->text) ;

    $twig->purge;
}

sub abstract {
    my ($twig, $elt)= @_;
    $publication->uniquename($elt->text) ;

    $twig->purge
}

sub author {
    my ($twig, $elt)= @_;
    
    my $lastname=$elt->children_text('LastName');
    my $initials=$elt->children_text('Initials');  
    #sometimes the firstname has no initials but full first name 'ForName'..
  
    if (!$initials) {  $initials=$elt->children_text('ForeName') || $elt->children_text('FirstName') ; }
    
    
    my $author_data=  $lastname ."|" . $initials ; 
    
    #append the authors to the 'title' field. 
    #Then extract the list and store in pubprop
    $publication->title($publication->title() . "-----" . $author_data) ;
    
    $twig->purge
}
