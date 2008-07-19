package Bio::GMOD::GenericGenePage;
use strict;
use warnings;
use English;
use Carp;

=head1 NAME

Bio::GMOD::GenericGenePage - generic GMOD gene page base class,
designed for maximum ease of implementation for subclasses and minimal
external dependencies

=head1 SYNOPSIS

my $page = Bio::GMOD::GenericGenePage->new( $gene_identifier );
my $xml = $page->render_xml();
my $html = $page->render_html();

#and then you can print the xml or html in your page

=head1 DESCRIPTION

=head1 BASE CLASS(ES)

none

=head1 SUBCLASSES

none yet

=head1 PROVIDED METHODS

=head2 new

  Usage: my $genepage = MyGenePage->new( -id => $gene_identifier );
  Desc : create a new gene page object.  should be overridden
  Args : not specified
  Ret  : a new gene page object
  Side Effects: none as implemented here, but subclass
                implementations may have side effects
  Example:

=cut

sub new {
  my ($class,%args) = @_;
  return bless {}, $class;
}

sub _counter {
  my $self = shift;
  $self->{'counter'}++;
  return $self->{'counter'};
}

=head2 render_xml

  Usage: my $xml = $page->render_xml();
  Desc : render the XML for this generic gene page
  Args : none
  Ret  : string of xml
  Side Effects: none

=cut

sub render_xml {
  my ($self) = @_;

  my $name = $self->name;

  my @syn = $self->synonyms;
  shift @syn;
  my $synonyms = join "\n", map {
    qq|  <name type="synonym">$_</name>|
  } @syn;

  my $dbreferences   = $self->_xml_render_colon_separated_dbrefs( 2, $self->dbxrefs);
  my $organism       = $self->_xml_render_organism();
  my $ontology_terms = $self->_xml_render_ontology_terms( 4, $self->ontology_terms);
  my $literature     = $self->_xml_render_colon_separated_dbrefs( 4, $self->literature_references);

  my $maplocations = join "\n", map {
    qq|    <mapLocation map="$_->{map_name}" chromosome="$_->{chromosome}" position="$_->{position}" units="$_->{units}" />|
  } $self->map_locations;

  return <<EOXML;
<gene>
  <name type="primary">$name</name>

$synonyms

$dbreferences

$organism

  <mapLocations>
$maplocations
  </mapLocations>

  <ontology>
$ontology_terms
  </ontology>

  <literature>
$literature
  </literature>

</gene>
EOXML
}

sub _xml_render_organism {
  my $self = shift;
  my $counter = $self->_counter;
  my $org = $self->organism;
  my $organism = <<END;
  <organism>
    <name type="common">$org->{common}</name>
    <name type="scientific">$org->{binomial}</name>
    <dbReference type="NCBI Taxonomy" key="$counter" id="$org->{ncbi_taxon_id}" />
  </organism>
END
  return $organism;
}

sub _xml_render_colon_separated_dbrefs {
  my ($self,$spaces,@refs) = @_;
  my $refstring = '';
  for my $ref (@refs) {
    my $counter = $self->_counter;
    my ($type,$id) = split /:/,$ref,2;
    $refstring .= (' 'x$spaces).qq|<dbReference type="$type" key="$counter" id="$id" />\n|
  }
  return $refstring;
}

sub _xml_render_ontology_terms {
  my ($self,$spaces,%term) = @_;
 
  my $xml_string = ''; 
  for my $key (keys %term) {
      my ($type,$id) = split /:/,$key;
      my $value = $term{$key};
      my $counter = $self->_counter;
      $type = "Go" if ($type eq "GO");
      $xml_string .= (' 'x$spaces).qq|<dbReference type="$type" key="$counter" id="$key">\n|; 
      $xml_string .= (' 'x($spaces+2)).qq|<property value="$value" type="term"/>\n|;
      $xml_string .= (' 'x$spaces).qq|</dbReference>\n|;
  }
  return $xml_string;
}

=head2 render_html

  Usage: my $html = $page->render_html();
  Desc : render HTML for this generic gene page.  you may want to
         override this method for your implementation
  Args : none
  Ret  : string of html
  Side Effects: none

=cut

sub render_html {
  my ($self) = @_;

  return <<EOHTML;

EOHTML
}

#helper method that calls all those functions
sub _info {
  my ($self) = @_;

  return
    { name => $self->name,
      syn  => [$self->synonyms],
      loc  => [$self->map_locations],
      ont  => [$self->ontology_terms],
      dbx  => [$self->dbxrefs],
      lit  => [$self->lit_refs],
      summary => $self->summary_text,
      species => $self->species,
    };
}


=head1 ABSTRACT METHODS

Methods below should be overridden by each GenericGenePage implementation.

=head2 name

  Usage: my $name = $genepage->name();
  Desc : get the string name of this gene
  Args : none
  Ret  : string gene name, e.g. 'Pax6'
  Side Effects: none

=cut

sub name {
  my ($self) = @_;
  die 'name() method is abstract, must be implemented in a subclass;'
}

=head2 synonyms

  Usage: my @syn = $genepage->synonyms();
  Desc : get a list of synonyms for this gene
  Args : none

  Ret : list of strings, with the canonical/official/approved gene
        name first.
        e.g. ( 'Pax6',
               '1500038E17Rik',
                'AEY11',
                'Dey',
                "Dickie's small eye",
                'Gsfaey11',
                'Pax-6',
             )
  Side Effects: none

=cut

sub synonyms {
  my ($self) = @_;
  die 'synonyms() method is abstract, must be implemented in a subclass;'
}

=head2 map_locations

  Usage: my @locs = $genepage->map_locations()
  Desc : get a list of known map locations for this gene
  Args : none
  Ret  : list of map locations, each a hashref as:
         {  map_name => string map name,
            chromosome => string chromosome name,
            marker     => (optional) associated marker name,
            position   => numerical position on the map,
            units      => map units, either 'cm', for centimorgans,
                          or 'b', for bases
         }
  Side Effects: none

=cut

sub map_locations {
  my ($self) = @_;
  die 'map_locations() method is abstract, must be implemented in a subclass;'
}


=head2 ontology_terms

  Usage: my @terms = $genepage->ontology_terms();
  Desc : get a list of ontology terms
  Args : none
  Ret  : hash-style list as:
           termname => human-readable description,
  Side Effects: none
  Example:

     my %terms = $genepage->ontology_terms()

     # and %terms is now
     (  GO:0016711 => 'F:flavonoid 3'-monooxygenase activity',
        ...
     )

=cut

sub ontology_terms {
  my ($self) = @_;
  die 'go_terms() method is abstract, must be implemented in a subclass'
}

=head2 dbxrefs

  Usage: my @dbxrefs = $genepage->dbxrefs();
  Desc : get a list of database cross-references for info related to this gene
  Args : none
  Ret  : list of strings, like type:id e.g. ('PFAM:00012')
  Side Effects: none

=cut

sub dbxrefs {
  my ($self) = @_;
  die 'dbxrefs() method is abstract, must be implemented in a subclass'
}

=head2 literature_references

  Usage: my @refs = $genepage->lit_refs();
  Desc : get a list of literature references for this gene
  Args : none
  Ret  : list of literature reference identifers, as type:id,
         like ('PMID:0023423',...)
  Side Effects: none

=cut

sub literature_references {
  my ($self) = @_;
  die 'lit_refs() method is abstract, must be implemented in a subclass'
}


=head2 summary_text

  Usage: my $summary = $page->summary_text();
  Desc : get a text string of plain-English summary text for this gene
  Args : none
  Ret  : string of summary text
  Side Effects: none

=cut

sub summary_text {
  my ($self) = @_;
  die 'summary_text() method is abstract, must be implemented in a subclass'
}

=head2 organism

  Usage: my $species_info = $genepage->organism
  Desc : get a handful of species-related information
  Args : none
  Ret  : hashref as:
         { ncbi_taxon_id => ncbi taxon id, (e.g. 3702),
           binomial      => e.g. 'Arabidopsis thaliana',
           common        => e.g. 'Mouse-ear cress',
         }
  Side Effects: none

=cut

sub organism {
  my ($self) = @_;
  die 'organism() method is abstract, must be implemented in a subclass';
}


=head1 AUTHOR(S)

Robert Buels

=cut


###
1;#do not remove
###
