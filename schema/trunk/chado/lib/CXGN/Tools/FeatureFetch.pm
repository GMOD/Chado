package CXGN::Tools::FeatureFetch;
use strict;

use XML::Twig;

use CXGN::Chado::Feature;

use CXGN::Tools::Entrez;



=head1 CXGN::Tools::FeatureFetch

get data from the NucleotideCore site and parse the necessary fields to fill a feature object
 
 
=head2


=head1 Author

Tim Jacobs

=cut
 
=head2 new

 Usage: my $feature_fetch = CXGN::Tools::FeatureFetch->new($feature_obj);
 Desc:
 Ret:    
 Args: $feature_object 
 Side Effects:
 Example:

=cut  

our $feature_object=undef;

sub new {
    my $class = shift;
    $feature_object= shift;
 
    
    my $args = {};  
    my $self = bless $args, $class;
    
      
    $self->set_feature_object($feature_object);  
             
    my $GBaccession= $feature_object->get_name();
    
    if ($GBaccession) {
	$self->fetch($GBaccession);
    }
    
    return $self;
}

=head2 fetch

 Usage: CXGN::Tools::featureFetch->fetch($genBank_accession);
 Desc:
 Ret:    
 Args: $genBank_accession
 Side Effects:
 Example:

=cut  

sub fetch {
    my $self=shift;
    my $GBaccession=shift; #GenBank accessions are stored in feature.name!

    #clear feature objects pubmeds so that we don't add the same one multiple times
    #$feature_object->set_pubmed_ids(undef);

    
    my $feature_xml = `wget "eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=$GBaccession&rettype=xml&retmode=text"  -O -  `;
   #	'Textseq-id/Textseq-id_accession'   => \&name,
    eval{ 
	my $twig=XML::Twig->new(
			    twig_roots   => 
				{
				    
				    'Textseq-id/Textseq-id_version'     => \&version,
				    'Seq-data_iupacna/IUPACna'          => \&residues,
				    'Seq-inst/Seq-inst_length'          => \&seqlen,
				    'Seqdesc/Seqdesc_title'             => \&description,
				    'Org-ref/Org-ref_taxname'           => \&organism_name,
				    'Org-ref_db/Dbtag/Dbtag_tag/Object-id/Object-id_id'           => \&organism_taxon_id,
				    'PubMedId'                          => \&pubmed_id,
				    'Textseq-id/Textseq-id_version'     =>\&version,
				    'Seq-id/Seq-id_gi'                  =>\&accession,  # accession refers to genBnk GI number
				    'MolInfo/MolInfo_biomol'            =>\&molecule_type,
				},
				twig_handlers =>
			    {
				# AbstractText     => \&abstract,
				#''                =>\&molecule_type, # see if the molecule type can be parsed and matched to a cvterm from the SO...
			    },
				
				pretty_print => 'indented',  # output will be nicely formatted
				); 
	
	$twig->parse($feature_xml );
	#my @names = $self->get_feature_object->get_names();
	#my $primary_name = $names[0];
	my $uniquename=  $self->get_feature_object->get_name() . "." . $self->get_feature_object->get_version();
	$feature_object->set_uniquename($uniquename);    
	my @gi_accessions = $self->get_feature_object->get_accessions();
	my $primary_gi = $gi_accessions[0];
	$feature_object->set_accession($primary_gi);
	
	my $db_name= 'DB:GenBank_GI';
	$feature_object->set_dbname($db_name);

    }; 
    if($@) {
	my $message= "NCBI server seems to be down. Please try again later.\n";
	return $message;
    }else { return undef ; }
}

sub get_feature_object {
  my $self=shift;
  return $self->{feature_object};

}

sub set_feature_object {
    my $self=shift;
    $self->{feature_object}=shift;
}

=head2 get_organism_name

 Usage:
 Desc: Retrieve the scientific organism name
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_organism_name {
    my $self=shift;
    return $self->{organism_name};
}

=head2 organism_name

 Usage:
 Desc: Store the scientific organism name in the feature object. This is used only for cleaner error messages.
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub organism_name {
    my ($twig, $elt) = @_;
    $feature_object->set_organism_name($elt->text);
    $twig->purge();
}

=head2 get_organism_taxon_id

 Usage:
 Desc: Retrieve the organisms genbank-given taxon_id
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_organism_taxon_id {
    my $self=shift;
    return $self->{organism_taxon_id};
}

=head2 organism_taxon_id

 Usage:
 Desc: Store the genbank taxon_id in the feature object
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub organism_taxon_id {
    my ($twig, $elt) = @_;
    $feature_object->set_organism_taxon_id($elt->text);
    $twig->purge();
}

sub get_name {
    my $self=shift;
    return $self->{name};
}

sub name {
    my ($twig, $elt)= @_;
    
    my $name_data=  $elt->text;
    
    $feature_object->add_name($name_data) ;
    print STDERR "name (genbank accession) $name_data\n";
    $twig->purge;
}

sub get_accession {
    my $self=shift;
    return $self->{accession};
}

sub accession {
    my ($twig, $elt)= @_;
    
    my $accession_data=  $elt->text;
    
    $feature_object->add_accession($accession_data) ;
    print STDERR "accession (genbank gi) $accession_data\n";
    $twig->purge;
}




sub pubmed_id {
    my ($twig, $elt)= @_;
    my $pubmed_id = $elt->text;
    
    my @pubmed_ids = $feature_object->get_pubmed_ids();
    
    my @already_exists = grep(/$pubmed_id/, @pubmed_ids);

    if(!@already_exists){
	$feature_object->add_pubmed_id($pubmed_id);
	print STDERR "***Adding pubmed_id to array: $pubmed_id \n";
    }
    $twig->purge;
}

sub get_version {
    my $self=shift;
    return $self->{version};
}

sub version {
    my ($twig, $elt)= @_;
    $feature_object->set_version($elt->text);
    $twig->purge;
}

sub get_residues {
    my $self=shift;
    return $self->{residues};
}

sub residues {
    my ($twig, $elt)= @_;
    $feature_object->set_residues($elt->text);
    $twig->purge;
}

sub get_seqlen {
    my $self=shift;
    return $self->{seqlen}
}

sub seqlen {
    my ($twig, $elt)= @_;
    $feature_object->set_seqlen($elt->text);
    $twig->purge;
}

=head2 description

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub description {
    my ($twig, $elt)= @_;
    $feature_object->set_description($elt->text);
    $twig->purge;
}

sub get_description {
    my $self = shift;
    return $self->{description};
}

sub get_molecule_type {
    my $self=shift;
    return $self->{molecule_type}
}

sub molecule_type {
    my ($twig, $elt)= @_;
    $feature_object->set_molecule_type($elt->text);
    $twig->purge;
}

#### DO NOT REMOVE
return 1;
####
