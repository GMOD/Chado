
=head1 NAME

CXGN::Chado::Organism - a class to create and manipulate Chado organism objects.

Version:1.0

=head1 DESCRIPTION


=head1 AUTHOR

Naama Menda <nm249@cornell.edu>

=cut 



use strict;
use warnings;

package CXGN::Chado::Organism ; # 


use Carp;

use base qw / CXGN::DB::Object / ;

=head2 new

  Usage: my $organism = CXGN::Chado::Organism->new($schema, $organism_id);
  Desc:
  Ret: a CXGN::Chado::Organism object
  Args: a $schema a schema object, preferentially created using:
        Bio::Chado::Schema->connect( sub{ CXGN::DB::Connection->new()->get_actual_dbh()}, %other_parameters);
        $organism_id, if $organism_id is omitted, an empty metadata object is created.
  Side_Effects: accesses the database, check if exists the database columns that this object use. die if the id is not an integer.
 
=cut

sub new {
    my $class = shift;
    my $schema = shift;
    my $id = shift;

    ### First, bless the class to create the object and set the schema into the object.
    my $self = $class->SUPER::new($schema);
   
    ##Setting sbh for using some legacy functions from the old Organism object 
    my $dbh= $schema->storage->dbh();
    $self->set_dbh($dbh);
    
    #Check if $id is an integer 
    my $organism;
    if (defined $id) {
	unless ($id =~ m/^\d+$/) {  ## The id can be only an integer
	    my $error_message = "\nDATA TYPE ERROR: The organism_id ($id) for CXGN::Chado::Organism->new() IS NOT AN INTEGER.\n\n";
	    croak($error_message);
	}
	
	$organism = $self->get_resultset('Organism::Organism')->find({ organism_id => $id }); 
	
	unless (defined $organism) {
	    my $error_message2 = "\nDATABASE COHERENCE ERROR: The organism_id ($id) for CXGN::Chado::Organism->new(\$schema, \$id) ";
            $error_message2 .= "DOES NOT EXIST IN THE DATABASE.\n";
	    $error_message2 .= "If you need enforce it, you can create an empty object (my \$org = CXGN::Chado::Organism->new(\$schema)";
            $error_message2 .= " and set the variable (\$org->set_organism_id(\$id);)";
	    warn($error_message2);
	    return undef;
	}
    } else {
	$self->debug("Creating a new empty Organism object! " . $self->get_resultset('Organism::Organism'));
	$organism = $self->get_resultset('Organism::Organism')->new({});   ### Create an empty resultset object; 
    }
    ###It's important to set the object row for using the accesor in other class functions
    $self->set_object_row($organism);
    
    return $self;
}
    

    
=head2 store

 Usage: $self->store
 Desc:  store a new organism 
 Ret:   a database id 
 Args:  none
 Side Effects: checks if the organism exists in the database, and if does, will attempt to update
 Example:

=cut

sub store {
    my $self=shift;
    my $id= $self->get_organism_id();
    my $schema=$self->get_schema();
    #no organism id . Check first if genus + species exists in te database
    if (!$id) { 
	my $exists= $self->exists_in_database();
	if (!$exists) {
	    
	    my $new_row = $self->get_object_row();
	    $new_row->insert();
	   
	    $id=$new_row->organism_id();
	    
	    $self->set_organism_id($id);
	    $self->d(  "Inserted a new organism  " . $self->get_organism_id() ." database_id = $id\n");
	}else { 
	    $self->set_organism_id($exists);
	    my $existing_organism=$self->get_resultset('Organism::Organism')->find($exists);
	    #don't update here if organism already exist. User should call from the code exist_in_database
	    #and instantiate a new organism object with the database organism_id
	    #updating here is not a good idea, since it might not be what the user intended to do
            #and it can mess up the database.
	    
	    $self->debug("Organism " . $self->get_species() . " " . $self->get_genus() .  " exists in database!");
	    
	} 
    }else { # id exists
	$self->d( "Updating existing organism_id $id\n");
	$self->get_object_row()->update();
    }
    return $self->get_organism_id()
}


=head2 exists_in_database
    
 Usage: $self->exists_in_database()
 Desc:  check if the genus + species exists in the organism table
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub exists_in_database {
    my $self=shift;
    my $genus= $self->get_genus() ; 
    my $species = $self->get_species();
    my $o = $self->get_resultset('Organism::Organism')->search({
	genus  => { 'ilike' => $genus },
	species    => { 'ilike'  => $species  }
    })->single(); #  ->single() for retrieving a single row (there sould be only one genus-species entry) 
    if ($o) { return $o->organism_id(); }
    
    # search if the genus+species where set together in the species field
    if ($species =~ m/(.*)\s(.*)/) {
	$o = $self->get_resultset('Organism::Organism')->search(
	    {
		genus   => { 'ilike'=> $1 },
		species => {'ilike' => $2 }
	    })->single();
	if ($o) { return $o->organism_id(); }
    }
    return undef;
}


=head2 get_dbxrefs

 Usage: $self->get_dbxrefs()
 Desc:  create a list of all dbxref objects associated with the organism
        via the organism_dbxref table
 Ret:   a list of CXGN::Chado::Dbxref objects
 Args:  none
 Side Effects: none
 Example:

=cut

sub get_dbxrefs {
    my $self=shift;
    my @organism_dbxrefs= $self->get_schema()->resultset('Organism::OrganismDbxref')->search( {organism_id => $self->get_organism_id() } );
    
    my @dbxrefs=();
    foreach my $od (@organism_dbxrefs) {
	my $dbxref_id= $od->dbxref_id(); 
	push @dbxrefs, $self->get_resultset("General::Dbxref")->search( { dbxref_id => $dbxref_id } );
    }
    return  @dbxrefs;
}


=head2 add_dbxref

 Usage: $self->add_dbxref($dbxref)
 Desc:  store a new organism_dbxref
 Ret:   database id 
 Args:  dbxref object 
 Side Effects: accesses the database
 Example:

=cut

sub add_dbxref {
    my $self=shift;
    my $dbxref=shift;

    my $schema=$self->get_schema;
    my $organism_id= $self->get_organism_id();
    my $dbxref_id = $dbxref->get_dbxref_id();
    my $organism_dbxref = $schema->resultset('Organism::OrganismDbxref')->find_or_create( 
	{
	    organism_id => $organism_id,
	    dbxref_id   => $dbxref_id,
	},
	);
    my $id = $organism_dbxref->get_column('dbxref_id');
    return $id;
}


=head2 add_synonym

 Usage: $self->add_synonym($synonym)
 Desc:  Store a new synonym for this organism
 Ret:   an organismprop object
 Args:  a synonym (text) 
 Side Effects: stores a new organismprop with a type_id of 'synonym'
 Example:

=cut

sub add_synonym {
    my $self=shift;
    my $synonym=shift;
    
    my $cvterm= $self->get_resultset("Cv::Cvterm")->search( {name => 'synonym' } )->single();;
    my $type_id;
    if ($cvterm) { 
	$type_id= $cvterm->get_column('cvterm_id');
	my $rank=1;
	my @organismprops= $self->get_schema()->resultset("Organism::Organismprop")->search(
	    {
		organism_id=>$self->get_organism_id(),
		type_id =>$type_id
	    });
	if (@organismprops) { 
	    my @sorted_ranks = reverse sort { $a <=> $b }  ( map($_->get_column('rank'), @organismprops) ) ;
	    my $max_rank = $sorted_ranks[0];
	    $rank = $max_rank+1;
	}
	my ($organismprop)= $self->get_schema()->resultset("Organism::Organismprop")->search( 
	    {
		organism_id => $self->get_organism_id(),
		type_id => $type_id,
		value   => $synonym,
	    });
	if (!$organismprop) {
	    $organismprop= $self->get_schema()->resultset("Organism::Organismprop")->create( 
		{
		    organism_id => $self->get_organism_id(),
		    type_id => $type_id,
		    value   => $synonym,
		    rank  => $rank,
		});
	    return $organismprop;
	}
    }
    $self->d("add_synonym ERROR: 'synonym' is not a cvterm! Please update your cvterm table. a cvterm with name='synonym' is required  for storing organismprop for synonyms\n");
    return undef;
}


=head2 get_synonyms

 Usage: my @synonyms= $self->get_synonyms()
 Desc:  find the synonyms for this organism
 Ret:   a list 
 Args:  none 
 Side Effects: get the organismprops for type_id of cvterm.name = synonym
 Example:

=cut

sub get_synonyms {
    my $self=shift;
    my @props= $self->get_resultset("Organism::Organismprop")->search( 
	{ organism_id => $self->get_organism_id(),
	  type_id  => $self->get_resultset("Cv::Cvterm")->search( { name => 'synonym'} )->first()->get_column('cvterm_id') 
	});
    my @synonyms;
    foreach my $prop (@props) { 
	push @synonyms, $prop->get_column('value');
    }
    return @synonyms;
}



=head2 get_ploidy

 Usage: my $ploidy= $self->get_ploidy()
 Desc:  find the ploidy value for this organism
 Ret:   a scalar
 Args:  none 
 Side Effects: get the organismprops for type_id of cvterm.name = ploidy
 Example:

=cut

sub get_ploidy {
    my $self=shift;

    my $name = "ploidy";
    my $value = $self->get_organismprop($name);
    return $value;
}


=head2 get_chromosome_number

 Usage: my $chr= $self->get_chromosome_number()
 Desc:  find the chromosome number  value for this organism
 Ret:   a scalar
 Args:  none 
 Side Effects: get the organismprops for type_id of cvterm.name = chromosome_number_variation
 Example:

=cut

sub get_chromosome_number {
    my $self=shift;
    my $name = "chromosome_number_variation";
    my $value = $self->get_organismprop($name);
    return $value;
}

=head2 get_genome_size

 Usage: my $genome_size= $self->get_genome_size()
 Desc:  find the genome size value for this organism
 Ret:   a scalar
 Args:  none 
 Side Effects: get the organismprops for type_id of cvterm.name = 'genome size'
 Example:

=cut

sub get_genome_size {
    my $self=shift;
    my $name = "genome size";
    my $value = $self->get_organismprop($name);
    return $value;
}


=head2 get_est_attribution

 Usage: my $att= $self->get_est_attribution()
 Desc:  find the est attribution for this organism
 Ret:   a scalar
 Args:  none 
 Side Effects: get the organismprops for type_id of cvterm.name = 'est attribution'
 Example:

=cut

sub get_est_attribution {
    my $self=shift;
    my $name= "est attribution";
    my $value= $self->get_organismprop($name);
    return $value;
}
 
=head2 get_organismprop

 Usage: $self->get_organismprop($value)
 Desc:  find the value of the organismprop for value $value
 Ret:   a string or undef
 Args:  $value (a cvterm name) 
 Side Effects:
 Example:

=cut

sub get_organismprop {
    my $self=shift;
    my $name = shift;
    
    my ($prop)= $self->get_resultset("Organism::Organismprop")->search( 
	{ organism_id => $self->get_organism_id(),
	  type_id  => $self->get_resultset("Cv::Cvterm")->search( { name => $name } )->first()->get_column('cvterm_id') 
	});
    if ($prop) {
	my $value= $prop->get_column('value');
	return $value;
    }
    return undef;
}

=head2 get_parent

 Usage: $self->get_parent()
 Desc:  get the parent organism of this object
 Ret:   Chado::Organism object or undef if organism has no parent (i.e. is the root in the tree)
 Args:  none 
 Side Effects: accesses the phylonode table
 Example:

=cut

sub get_parent {
    my $self=shift;
    my $organism_id = $self->get_organism_id();
    
    my ($phylonode)= $self->get_resultset("Phylogeny::PhylonodeOrganism")->search(
	{ organism_id =>$self->get_organism_id() })->search_related('phylonode');
    
    if ($phylonode) {
	my $parent_phylonode_id= $phylonode->get_column('parent_phylonode_id');
	
	my ($parent_phylonode)= $self->get_resultset("Phylogeny::Phylonode")->search(
	    { phylonode_id=> $parent_phylonode_id } );
	if ($parent_phylonode) {
	    my ($phylonode_organism)= $self->get_resultset("Phylogeny::PhylonodeOrganism")->search(
		{ phylonode_id => $parent_phylonode->get_column('phylonode_id') } );
	    
	    my $parent_organism= CXGN::Chado::Organism->new($self->get_schema(), $phylonode_organism->organism_id );
	    
	    return $parent_organism;
	}
    }
    return undef;
}

=head2 get_taxon

 Usage: $sef->get_taxon()
 Desc:  get the taxon for this organism 
 Ret:   a taxon name
 Args:  none
 Side Effects: looks in the phylonode table
 Example:

=cut

sub get_taxon {
    my $self = shift;
    my ($phylonode) = $self->get_resultset("Phylogeny::PhylonodeOrganism")->search(
	{ organism_id=>$self->get_organism_id() } )->search_related("phylonode");
    if ($phylonode) {
	my $type_id = $phylonode->get_column('type_id');
	
	my ($cvterm) = $self->get_resultset("Cv::Cvterm")->find( { cvterm_id=>$type_id });
	if ($cvterm) {
	    my $taxon = $cvterm->get_column('name');
	    return $taxon;
	}
    }
    return undef;
    
}




#############################################

=head2 accessors get_species, set_species

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_species {
    my $self = shift;
    return $self->get_object_row()->get_column('species');    
}

sub set_species {
    my $self = shift;
    my $species=shift || croak " No argument passed to set_species!!!";
    $self->get_object_row()->set_column(species => $species ) ;
    
}

=head2 accessors get_genus, set_genus

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_genus {
    my $self = shift;
    return $self->get_object_row()->get_column("genus"); 
}

sub set_genus {
    my $self = shift;
    $self->get_object_row()->set_column(genus => shift);
}

=head2 accessors get_abbreviation, set_abbreviation

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_abbreviation {
    my $self = shift;
    return $self->get_object_row()->get_column("abbreviation"); 
}

sub set_abbreviation {
    my $self = shift;
    $self->get_object_row()->set_column(abbreviation => shift);
}

=head2 accessors get_common_name, set_common_name

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_common_name {
    my $self = shift;
    return $self->get_object_row()->get_column("common_name"); 
}

sub set_common_name {
    my $self = shift;
    $self->get_object_row()->set_column(common_name => shift);
}


=head2 accessors get_comment, set_comment

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_comment {
    my $self = shift;
    return $self->get_object_row()->get_column("comment"); 
}

sub set_comment {
    my $self = shift;
    $self->get_object_row()->set_column(comment => shift);
}




=head2 accessors get_organism_id, set_organism_id

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_organism_id {
    my $self = shift;
    return $self->get_object_row()->get_column('organism_id'); 
}

sub set_organism_id {
    my $self = shift;
    my $organism_id=shift || croak "No argument passed to organism_id";
    #check if integer
    #check if id is in the database 
    $self->get_object_row()->set_column(organism_id=>$organism_id);
}


sub get_object_row {
    my $self = shift;
    return $self->{object_row}; 
}

sub set_object_row {
  my $self = shift;
  $self->{object_row} = shift;
}

=head2 get_resultset

 Usage: $self->get_resultset(ModuleName::TableName)
 Desc:  Get a ResultSet object for source_name 
 Ret:   a ResultSet object
 Args:  a source name
 Side Effects: none
 Example:

=cut

sub get_resultset {
    my $self=shift;
    my $source = shift;
    return $self->get_schema()->resultset("$source");
}



###################Functions adapted from the old the organism object

=head2 new_with_taxon_id

 Usage:  my $organism = CXGN::Chado::Organism->new_with_taxon_id($dbh, $gb_taxon_id)
 Desc:   create a new organism object using genbank taxon_id instead of organism_id 
 Ret:    a new organism object
 Args:   
 Side Effects: creates a new Bio::Chado::Schema object
 Example: 

=cut

sub new_with_taxon_id {
    my $class = shift;
    my $schema = shift;
    
    #this is for old-stype objects having only a dbh (See CXGN::Chado::Feature)
    if ( $schema->isa("CXGN::DB::Connection")) { # it's a DBI object
	my $dbh=$schema;
	use Bio::Chado::Schema;
	$schema= Bio::Chado::Schema->connect(  sub { $dbh->get_actual_dbh() },
					  { on_connect_do => ['SET search_path TO public'],
					  },);
    }
    
    my $taxon_id = shift;
    
    my ($organism)= $schema->resultset("General::Db")->search(
	{  name      =>  'DB:NCBI_taxonomy' } ->
	search_related('dbxrefs', { accession =>  $taxon_id } )->
	search_related('organism_dbxrefs')->
	search_related('organisms')
	);
    my $self=CXGN::Chado::Organism->new($schema, $organism->get_column('organism_id') );
    
    return $self;
}



=head2 get_genbank_taxon_id

 Usage:  $self->get_genbank_taxon_id
 Desc:   get the genbank taxon id of this organism
 Ret:    a string
 Args:   
 Side Effects: none
 Example: 

=cut

sub get_genbank_taxon_id {
    my $self = shift;
    my $schema= $self->get_schema();
    my ($db) = $schema->resultset("General::Db")->search( { name =>  'DB:NCBI_taxonomy' } );
    my $db_id = $db->get_column('db_id');
    
    my ($dbxref)= $schema->resultset("Organism::OrganismDbxref")->search(
	{  organism_id => $self->get_organism_id() })->
	search_related('dbxref', {db_id => $db_id } ) ;
    my $accession = $dbxref->get_column('accession');
    return $accession;
}



=head2 new_with_common_name

 Usage:  my $organism = CXGN::Chado::Organism->new_with_common_name($dbh, $common_name)
 Desc:   create a new organism object using common_name instead of organism_id 
 Ret:    a new organism object
 Args:   
 Side Effects: none
 Example: 

=cut


###Need to figure out what to do with common names 
sub new_with_common_name {
    my $self = shift;
    my $dbh = shift;
    my $common_name = shift;
    my $schema;
    
    my @organisms;
    
    #this returns all the organisms in the common name group
    my $query =  "SELECT organism_id FROM public.organism
                  JOIN organismgroup_member USING(organism_id)
                  JOIN organismgroup USING(organismgroup_id) 
                  WHERE name ILIKE ? AND type =?";
    my $sth= $dbh->prepare($query);
    $sth->execute($common_name, 'common name');
    
    use Bio::Chado::Schema;
    $schema= Bio::Chado::Schema->connect(  sub { $dbh->get_actual_dbh() },
					   { on_connect_do => ['SET search_path TO public'],
					   },);
    while (my ($organism_id) = $sth->fetchrow_array() ) {
	
	my $organism= CXGN::Chado::Organism->new($schema, $organism_id);
	push @organisms, $organism;
	
    }
    
    #return @organisms;
    
    #or maybe :
    
    #my @organism= $self->get_resultset('Organism::Organism')->find(
#	{ common_name => $common_name, 
#	});
    if (scalar(@organisms) > 1 ) { warn "new_with_common_name found more than one organism row for common_name $common_name!!"; }
    return $organisms[0];
}


=head2 get_intergroup_species_name DEPRECATED see get_group_common_name
    
 Usage: 
 Ret:   
 Args:   
 Side Effects: 
 Example: 

=cut

sub get_intergroup_species_name {
    
    my $self = shift;
    warn "DEPRECATED. Replaced by get_group_common_name";
    return $self->get_group_common_name();
}



=head2 get_group_common_name

 Usage: my $group_common_name= $self->get_group_common_name()
 Desc:  The unigenes, loci and phenome are grouped by interspecific group class.
        e.g. for all tomato species we have the same number of unigene, loci or phenotypes accessions. 
        This function  get this common_name for this organism 
 Ret:   A string
 Args:   
 Side Effects: none
 Example: my $species_intergroup= $organism->get_group_common_name()

=cut

sub get_group_common_name {

    my $self = shift;
    my $query = "SELECT
           	organismgroup.name
		FROM organismgroup
		JOIN organismgroup_member USING (organismgroup_id)
	        WHERE organism_id=? AND type = ?";
    
    my $sth=$self->get_dbh()->prepare($query);
    $sth->execute($self->get_organism_id() , 'common name');

    my ($common_name) = $sth->fetchrow_array();
       
    return $common_name;

}


#############
#The following methods need database changes of the organism and common_name FK
#############


=head2 get_map_data

 Usage:  my $map_data = $self->get_map_data ();
 Desc:   Get the map link for an organism. The organism could be one of the parents.
 Ret:    array of [ map short_name , map_id ], [], ...
 Args:   
 Side Effects: none
 Example: my ($short_name, $map_id = $organism->get_map_data();

=cut

sub get_map_data {

    my $self = shift;
    
    my $query = "SELECT DISTINCT
		 	sgn.map.short_name, 
			sgn.map.map_id 
		  FROM sgn.map 
   		  INNER JOIN sgn.accession ON (parent_1=accession_id or parent_2=accession_id or ancestor=accession_id) 
		  INNER JOIN public.organism on  (public.organism.organism_id = sgn.accession.chado_organism_id)
		  WHERE public.organism.organism_id = ?";

    my $sth=$self->get_dbh()->prepare($query);
    $sth->execute($self->get_organism_id() );
    my @map_data=();
  
    while (my ($short_name, $map_id) = $sth -> fetchrow_array()) {
	push @map_data, [$short_name, $map_id];
    }
    return @map_data;
}


#####################

=head2 get_loci_count

 Usage: my $loci_count = $self->get_loci_count();
 Desc:  Get the loci data for an organism  .
 Ret:   An integer.
 Args:   
 Side Effects: none
 Example: my $loci_count = $organism->get_loci_count();

=cut

sub get_loci_count {

    my $self = shift;

    my $query = "SELECT COUNT
			(phenome.locus.locus_id) 
                 FROM phenome.locus
                 JOIN sgn.common_name using (common_name_id)
                 JOIN public.organismgroup  on (common_name.common_name = public.organismgroup.name )
                 JOIN public.organismgroup_member USING (organismgroup_id)
                 JOIN public.organism USING (organism_id)
                 WHERE locus.obsolete = 'f' AND public.organism.organism_id=?";
    
    my $sth=$self->get_dbh()->prepare($query);
    $sth->execute($self->get_organism_id() );

    my ($locus_count) = $sth->fetchrow_array() ;
    return $locus_count;
}

=head2 get_library_list

 Usage: my $library_count = $self->get_library_list();
 Desc:  Get the libraries names. 
 Ret:  a list of library_shortnames
 Args:   
 Side Effects: none
 Example: my $lib = $organism->get_library_list();

=cut

sub get_library_list {
   
    my $self=shift;

    my $query = "SELECT library_shortname
                 FROM sgn.library
		 JOIN public.organism on (organism.organism_id = library.chado_organism_id)
		 WHERE public.organism.organism_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_organism_id() );

    my @libraries = ();
    while ( my ($library_shortname)=$sth->fetchrow_array() ) {
	push @libraries,  $library_shortname;
    }
    return @libraries;
}

=head2 get_est_count 

 Usage: my $est_count = $organism->get_est_count();
 Desc:  Get the EST count for an organism. This number is only for the ESTs where status=0 and flags=0. 
 Ret:   An integer.
 Args:   
 Side Effects: THIS FUNCTION IS VERY SLOW. Currently not called from the organism page.
 Example: my $est_n = $organism->get_ests_count();

=cut

sub get_est_count {

    my $self = shift;

    my $query = "SELECT COUNT(
			sgn.est.est_id)
		 FROM sgn.est
		 JOIN sgn.seqread USING (read_id)
		 JOIN sgn.clone USING (clone_id)
		 JOIN sgn.library USING (library_id)
		 JOIN public.organism ON (organism.organism_id = library.chado_organism_id)
		                  WHERE sgn.est.status = 0 and sgn.est.flags = 0 and public.organism.organism_id=?"; 

    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_organism_id() );
    my ($est_n) = $sth->fetchrow_array() ;
    return $est_n;
}

=head2 get_phenotype_count

 Usage: my $phenotypes =$self->get_phenotype_count();
 Desc:  Get the phenotypes count for an organism.
 Ret:   An integer or undef
 Args:   
 Side Effects: none
 Example: 

=cut

sub get_phenotype_count {

   my $self = shift;

   my $query=" SELECT COUNT (phenome.individual.individual_id) 
                 FROM phenome.individual
                 JOIN sgn.common_name using (common_name_id)
                 JOIN public.organismgroup  on (common_name.common_name = public.organismgroup.name )
                 JOIN public.organismgroup_member USING (organismgroup_id)
                 JOIN public.organism USING (organism_id)
                 WHERE individual.obsolete = 'f' AND public.organism.organism_id=?";
    
   my $sth=$self->get_dbh()->prepare($query);
   $sth->execute($self->get_organism_id() );
   
   my $phenotypes =0;
   while (my ($pheno_count) = $sth->fetchrow_array()) {
       $phenotypes += $pheno_count; 
   }
   
   return $phenotypes;
}


##########################

=head2 get_organism_by_species

 Usage: CXGN::Chado::Oganism::get_organism_by_species($species, $schema)
 Desc:  
 Ret:   Organism object or undef
 Args: species name and a schema object
 Side Effects:
 Example:

=cut


sub get_organism_by_species {
    my $species=shift;
    my $schema= shift;
    my $organism=$schema->resultset("Organism::Organism")->find(
	{ species => $species }
	)->first(); #should be just one species... 
    
    return $organism || undef ;
}


=head2 get_organism_by_tax

 Usage: $self->get_organism_by_tax($taxon)
 Desc:  Find the organism row for the higher level taxon of the current organism.
 Ret:   Organism object or undef
 Args:  taxon order (e.g. order, family , tribe, etc.)
 Side Effects:
 Example:

=cut


sub get_organism_by_tax {
    my $self=shift;
    my $taxon=shift;
    my ($cvterm) = $self->get_resultset("Cv::Cvterm")->find( { name => $taxon } );
    if ($cvterm) {
	my $type_id = $cvterm->get_column('cvterm_id');
	
	my ($self_phylonode)= $self->get_resultset("Phylogeny::PhylonodeOrganism")->search(
	    { organism_id => $self->get_organism_id() } )->search_related('phylonode');
	if ($self_phylonode) {
	    my $left_idx= $self_phylonode->get_column('left_idx');
	    my $right_idx=$self_phylonode->get_column('right_idx');
	    my ($phylonode)=$self->get_resultset("Phylogeny::Phylonode")->search_literal(
		('left_idx < ? AND right_idx > ? AND type_id = ?' , ($left_idx, $right_idx, $type_id) ));
	    
	    if ($phylonode) { 
		my ($organism)= $self->get_resultset("Phylogeny::PhylonodeOrganism")->search(
		    { phylonode_id => $phylonode->get_column('phylonode_id') } )->search_related('organism');
		
		return $organism || undef ;
	    }
	}else { warn("NO PHYLONODE stored for organism " . $self->get_abbreviation() . "\n");  }
    }else {  warn("NO CVTERM FOUND for term '$taxon'!! Check your database\n"); }
    return undef;
}




###########
return 1;##
###########
