
=head1 NAME

 load_taxonomy_cvterms.pl
    
=head1 DESCRIPTION

 Usage: perl load_taxonomy_cvterms.pl -H [dbhost] -D [dbname] [-t] -g gmod_dbprofile

populate a chado database with NCBI taxon terms 


=head2 parameters

=over 4

=item -H

hostname for database

=item -D

database name

 
=item -t

trial mode. Do not perform any store operations at all.


=item -g

GMOD database profile name (can provide host and DB name) Default: 'default'


=back

=cut

#!/usr/bin/perl
use strict;

use Bio::GMOD::Config;
use Bio::GMOD::DB::Config;

use Bio::Chado::Schema;

use Getopt::Std;


our ($opt_H, $opt_D, $opt_g,  $opt_t);

getopts('H:g:tD:');

my $dbhost = $opt_H;
my $dbname = $opt_D;

my ($dbh, $schema);

if ($opt_g) {
    my $DBPROFILE = $opt_g;
    $DBPROFILE ||= 'default';
    my $gmod_conf = Bio::GMOD::Config->new() ;
    my $db_conf = Bio::GMOD::DB::Config->new( $gmod_conf, $DBPROFILE ) ;
    
    $dbhost ||= $db_conf->host();
    $dbname ||= $db_conf->name();
    my $dbdriver=$db_conf->driver();
    my $dbport = $db_conf->port();
    if (!$dbhost && !$dbname) { die "Need -D dbname and -H hostname arguments.\n"; }
    
    my $dsn = "dbi:$dbdriver:dbname=$dbname";
    $dsn .= ";host=$dbhost";
    $dsn .= ";port=$dbport" if $dbport;
    
    $schema= Bio::Chado::Schema->connect( $dsn, $db_conf->user(), $db_conf->password(), { AutoCommit=>0 } );
    
    $dbh=$schema->storage->dbh();
    
}else { 
    require CXGN::DB::InsertDBH;
    $dbh = CXGN::DB::InsertDBH->new( { dbhost=>$dbhost,
				       dbname=>$dbname,
				       dbschema=>'public',
				     } );
    $schema= Bio::Chado::Schema->connect( sub { $dbh->get_actual_dbh() } );   
}
if (!$schema || !$dbh) { die "No schema or dbh is avaiable! \n"; }


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
no rank
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
