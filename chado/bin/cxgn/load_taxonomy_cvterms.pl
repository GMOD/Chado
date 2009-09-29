#!/usr/bin/perl
use strict;
use CXGN::DB::Connection;
use CXGN::DB::InsertDBH;

use Bio::Chado::Schema;

use Getopt::Std;


our ($opt_H, $opt_D, $opt_v,  $opt_t);

getopts('H:vtD:');

my $dbhost = $opt_H;
my $dbname = $opt_D;

my $dbh;

if (!$dbhost && !$dbname) { 
    $dbh= CXGN::DB::Connection->new();
}else {
    
    $dbh = CXGN::DB::InsertDBH->new( { dbhost => $dbhost,
				       dbname => $dbname,
				     } );
}
my $schema= Bio::Chado::Schema->connect(  sub { $dbh->get_actual_dbh() },
    );


eval {
    
    my $db = $schema->resultset("General::Db")->find_or_create( 
	{
	    name =>'species_taxonomy',
	});
    
    my $db_id = $db->get_column('db_id');
    
    my $cv= $schema->resultset("Cv::Cv")->find_or_create(
	{
	    name => 'taxonomy',
	});
    my $cv_id = $cv->get_column('cv_id');
    
    
    while ( my $tax =  <DATA> )  {
	chomp $tax;
	my $dbxref= $schema->resultset("General::Dbxref")->find_or_create(
	    {
		db_id     => $db_id,
		accession => "taxonomy:$tax",
	    }); 
	my $dbxref_id = $dbxref->get_column('dbxref_id');

	my $cvterm = $schema->resultset("Cv::Cvterm")->find_or_create(
	    {
		cv_id => $cv_id,
		name  => $tax,
		dbxref_id => $dbxref_id,

	    });
	my $cvterm_id= $cvterm->get_column('cvterm_id');
	print STDERR "Stored cvterm for $tax ($cvterm_id)\n";
    }
};   

if($@) {
    print $@;
    print"Failed; rolling back.\n";
    $dbh->rollback();
}else{ 
    print"Succeeded.\n";
    if (!$opt_t) {
	print STDERR "committing ! \n";
        $dbh->commit();
    }else{
	print STDERR "Rolling back! \n";
        $dbh->rollback();
    }
}

__DATA__
superkingdom
subkingdom
kingdom
superphylum
phylum
subphylum
superclass
class
subclass
infraclass
cohort
subcohort
superorder
order
suborder
infraorder
parvorder
superfamily
family
subfamily
tribe
subtribe
genus
subgenus
species group
species subgroup
species
subspecies
varietas
forma
