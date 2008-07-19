package Bio::GMOD::GenericGenePage::Chado;
use strict;
use warnings;
use English;
use Carp;

use Bio::GMOD::Config;
use Bio::GMOD::DB::Config;

use base qw/ Bio::GMOD::GenericGenePage /;

=head1 NAME

Bio::GMOD::GenericGenePage::Chado - 

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
         my $genepage = Bio::GMOD::GenericGenePage::Chado->new( feature_id => $id);
  Desc : create a new gene page object; overridden from abstract class.
  Args : -id => $feature_id
  Ret  : a new gene page object
  Side Effects: Sets feature_id attribute, creates db connection

=cut

sub new {
  my ($class,%args) = @_;
  my $self = bless {}, ref($class) || $class;

#create db connection from GMOD db objects
  my $gmod_conf = Bio::GMOD::Config->new();
  my $db_conf   = Bio::GMOD::DB::Config->new($gmod_conf);
  my $dbh       = $db_conf->dbh;
  $self->dbh($dbh);
  warn "No database connection; what do I do?" unless $dbh;

  my $feature_id  = $args{'-id'};
  #$self->feature_id( $args{'-id'} ) if (defined($args{'id'}));
  $self->feature_id( $feature_id ) if defined($feature_id);
  warn "No feature_id set; what do I do?" unless $self->feature_id;

  return $self;
}

=head2 dbh

  Usage: my $dbh = $obj->dbh();
  Desc: Sets/Gets Chado database handle
  Args: DBI database handle to set, none to get

=cut

sub dbh {
    my $self = shift;
    my $dbh = shift;

    return $self->{'dbh'} = $dbh if defined $dbh;
    return $self->{'dbh'};
}


=head2 feature_id

  Usage: my $feature_id = $obj->feature_id();
  Desc: Sets/Gets feature_id
  Args: Integer to set, none to get

=cut

sub feature_id {
    my $self = shift;
    my $feature_id = shift if defined(@_);

    return $self->{'feature_id'} = $feature_id if defined $feature_id;
    return $self->{'feature_id'};    
}

=head2 

=head1 CHADO SPECIFIC METHODS

Methods below were overridden from the GenericGenePage abstract implementation.

=head2 name

  Usage: my $name = $genepage->name();
  Desc : get the string name of this gene
  Args : none
  Ret  : string gene name, e.g. 'Pax6'
  Side Effects: none

=cut

sub name {
  my ($self) = @_;

  my $query = "SELECT name FROM feature WHERE feature_id = ?";
  my $sth   = $self->dbh->prepare($query);
  $sth->execute($self->feature_id);

  my ($name) = $sth->fetchrow_array();
  warn "No name found for the given feature_id" unless $name;
  return $name;
}

=head2 synonyms

  Usage: my @syn = $genepage->synonyms();
  Desc : get a list of synonyms for this gene
  Args : none

  Ret : list of strings, with the canonical/official/approved gene
        name first.
        e.g. ( '1500038E17Rik',
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

#this query could include checking s.type_id and fs.is_current when relevent
  my $query = "SELECT s.name FROM feature_synonym fs, synonym s WHERE fs.feature_id = ? and s.synonym_id = fs.synonym_id";
  my $sth   = $self->dbh->prepare($query);
  $sth->execute($self->feature_id);

  my @syns;
  while (my $data = $sth->fetchrow_arrayref) {
      push @syns, $$data[0];
  }

  return @syns;
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
  warn 'map_locations() method is abstract, must be implemented in a subclass;';
  return {  map_name => '',
            chromosome => '',
            marker     => '',
            position   => '',
            units      => '',
         };

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

  my $query = "SELECT cvterm.name,db.name as dbname,dbxref.accession "
             ."FROM feature_cvterm fc "
             ." JOIN cvterm using (cvterm_id) "
             ." JOIN dbxref using (dbxref_id) "
             ." JOIN db using (db_id) "
             ."WHERE fc.feature_id = ?";
  my $sth = $self->dbh->prepare($query);
  $sth->execute($self->feature_id); 

  my %term;
  while (my $data = $sth->fetchrow_hashref) {
      $term{ "$$data{dbname}:$$data{accession}" } 
          = $$data{name};
  }

  return %term;
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

  my $query = "SELECT db.name,dbxref.accession "
             ."FROM feature_dbxref fd "
             ." JOIN dbxref using (dbxref_id) "
             ." JOIN db using (db_id) "
             ."WHERE fd.feature_id = ?";
  my $sth = $self->dbh->prepare($query);
  $sth->execute($self->feature_id);

  my @dbxrefs;
  while (my $data = $sth->fetchrow_hashref) {
      push @dbxrefs, "$$data{name}:$$data{accession}";
  }

  return @dbxrefs;
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

  my $query = "SELECT db.name,dbxref.accession "
             ."FROM feature_pub fp "
             ." JOIN pub using (pub_id) "
             ." JOIN pub_dbxref using (pub_id) "
             ." JOIN dbxref using (dbxref_id) "
             ." JOIN db using (db_id) "
             ."WHERE fp.feature_id = ?";
  my $sth = $self->dbh->prepare($query);
  $sth->execute($self->feature_id);

  my @pubs;
    while (my $data = $sth->fetchrow_hashref) {
      push @pubs, "$$data{name}:$$data{accession}";
  }

  return @pubs;
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

  my $query = "SELECT cv.name, fp.value "
             ."FROM featureprop fp "
             ." JOIN cvterm cv on (fp.type_id = cv.cvterm_id) "
             ."WHERE cv.name IN ('Note','description') "
             ."  AND fp.feature_id = ? "
             ."  AND cv.cv_id IN "
             ."    (SELECT cv_id FROM cv WHERE name='feature_property') "
             ."ORDER BY name";
  my $sth = $self->dbh->prepare($query);
  $sth->execute($self->feature_id);

  my ($desc) = $sth->fetchrow_array;
  return $desc;
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

  ###CHANGE ME  if you aren't a yeast database
  my %organism = (
      ncbi_taxon_id => 4932,
      binomial      => "Saccharomyces cerevisiae",
      common        => "yeast",
  );

  return \%organism;
}


=head1 AUTHOR(S)

Robert Buels

=cut


###
1;#do not remove
###
