#!perl
use Config;
use File::Basename qw(&basename &dirname);
use File::Spec;
use FindBin '$Bin';
use Cwd;
  
my %OPTIONS;
if (open F,"$Bin/../build.conf") {
  while (<F>) {
    next if /^\#/;
    chomp;
    $OPTIONS{$1} = $2 if /^(\w+)\s*=\s*(.+)/;
  }
  close F;
}

$file   = basename($0, '.PL','.PLS');
$file   = "$Bin/../lib/Chado/$file.pm";

open OUT,">$file" or die "Can't create $file: $!";
        
print "Extracting $file (with variable substitutions)\n";
               
my $startperl = $Config{startperl} ne '#!perl'
  ? $Config{startperl}
  : "#!$Config{perlpath}";
                       
print OUT <<"!GROK!THIS!";
package Chado::DBI;

# Created by SQL::Translator::Producer::Turnkey
# Template used: classdbi

use strict;
no warnings 'redefine';
use base qw(Class::DBI::Pg);
Chado::DBI->set_db('Main', 'dbi:Pg:dbname=$OPTIONS{'DBNAME'};host=$OPTIONS{'DBHOST'};port=$OPTIONS{'DBPORT'}', '$OPTIONS{'DBUSER'}', '$OPTIONS{'DBPASS'}');

#sub search_ilike { shift->_do_search(ILIKE => \@_ ) }

!GROK!THIS!

print OUT <<'!NO!SUBS!';
# -------------------------------------------------------------------
package Chado::Tableinfo;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Tableinfo->set_up_table('tableinfo');


Chado::Tableinfo->has_many(
    'magedocumentation_tableinfo_id', 'Chado::Magedocumentation' => 'tableinfo_id'
);

Chado::Tableinfo->has_many(
    'control_tableinfo_id', 'Chado::Control' => 'tableinfo_id'
);

# -------------------------------------------------------------------
package Chado::Db;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Db->set_up_table('db');


Chado::Db->has_many(
    'dbxref_db_id', 'Chado::Dbxref' => 'db_id'
);

# -------------------------------------------------------------------
package Chado::Dbxref;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Dbxref->set_up_table('dbxref');


Chado::Dbxref->has_a(
    db_id => 'Chado::Db'
);

sub Chado::Dbxref::db {
    return shift->db_id
}

Chado::Dbxref->has_many(
    'protocol_dbxref_id', 'Chado::Protocol' => 'dbxref_id'
);

Chado::Dbxref->has_many(
    'assay_dbxref_id', 'Chado::Assay' => 'dbxref_id'
);

Chado::Dbxref->has_many(
    'feature_dbxref_dbxref_id', 'Chado::Feature_Dbxref' => 'dbxref_id'
);

Chado::Dbxref->has_many(
    'biomaterial_dbxref_dbxref_id', 'Chado::Biomaterial_Dbxref' => 'dbxref_id'
);

sub features { my $self = shift; return map $_->feature_id, $self->element_dbxref_id }

Chado::Dbxref->has_many(
    'feature_dbxref_id', 'Chado::Feature' => 'dbxref_id'
);

Chado::Dbxref->has_many(
    'organism_dbxref_dbxref_id', 'Chado::Organism_Dbxref' => 'dbxref_id'
);

sub feature_cvterms { my $self = shift; return map $_->feature_cvterm_id, $self->feature_cvterm_dbxref_dbxref_id }

sub arraydesigns { my $self = shift; return map $_->arraydesign_id, $self->element_dbxref_id }

Chado::Dbxref->has_many(
    'arraydesign_dbxref_id', 'Chado::Arraydesign' => 'dbxref_id'
);

Chado::Dbxref->has_many(
    'study_dbxref_id', 'Chado::Study' => 'dbxref_id'
);

sub pubs { my $self = shift; return map $_->pub_id, $self->pub_dbxref_dbxref_id }

sub organisms { my $self = shift; return map $_->organism_id, $self->organism_dbxref_dbxref_id }

Chado::Dbxref->has_many(
    'dbxrefprop_dbxref_id', 'Chado::Dbxrefprop' => 'dbxref_id'
);

Chado::Dbxref->has_many(
    'cvterm_dbxref_dbxref_id', 'Chado::Cvterm_Dbxref' => 'dbxref_id'
);

Chado::Dbxref->has_many(
    'feature_cvterm_dbxref_dbxref_id', 'Chado::Feature_Cvterm_Dbxref' => 'dbxref_id'
);

Chado::Dbxref->has_many(
    'element_dbxref_id', 'Chado::Element' => 'dbxref_id'
);

sub cvterms { my $self = shift; return map $_->cvterm_id, $self->element_dbxref_id }

Chado::Dbxref->has_many(
    'cvterm_dbxref_id', 'Chado::Cvterm' => 'dbxref_id'
);

sub biomaterials { my $self = shift; return map $_->biomaterial_id, $self->biomaterial_dbxref_dbxref_id }

Chado::Dbxref->has_many(
    'biomaterial_dbxref_id', 'Chado::Biomaterial' => 'dbxref_id'
);

Chado::Dbxref->has_many(
    'pub_dbxref_dbxref_id', 'Chado::Pub_Dbxref' => 'dbxref_id'
);

# -------------------------------------------------------------------
package Chado::Project;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Project->set_up_table('project');


Chado::Project->has_many(
    'assay_project_project_id', 'Chado::Assay_Project' => 'project_id'
);

sub assays { my $self = shift; return map $_->assay_id, $self->assay_project_project_id }

# -------------------------------------------------------------------
package Chado::Cv;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Cv->set_up_table('cv');


Chado::Cv->has_many(
    'cvtermpath_cv_id', 'Chado::Cvtermpath' => 'cv_id'
);

Chado::Cv->has_many(
    'cvterm_cv_id', 'Chado::Cvterm' => 'cv_id'
);

# -------------------------------------------------------------------
package Chado::Cvterm;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Cvterm->set_up_table('cvterm');


Chado::Cvterm->has_a(
    cv_id => 'Chado::Cv'
);

sub Chado::Cvterm::cv {
    return shift->cv_id
}

Chado::Cvterm->has_a(
    dbxref_id => 'Chado::Dbxref'
);

sub Chado::Cvterm::dbxref {
    return shift->dbxref_id
}

Chado::Cvterm->has_many(
    'protocol_type_id', 'Chado::Protocol' => 'type_id'
);

Chado::Cvterm->has_many(
    'elementresult_relationship_type_id', 'Chado::Elementresult_Relationship' => 'type_id'
);

Chado::Cvterm->has_many(
    'studyfactor_type_id', 'Chado::Studyfactor' => 'type_id'
);

Chado::Cvterm->has_many(
    'cvtermsynonym_cvterm_id', 'Chado::Cvtermsynonym' => 'cvterm_id'
);

Chado::Cvterm->has_many(
    'cvtermsynonym_type_id', 'Chado::Cvtermsynonym' => 'type_id'
);

sub quantification_relationships { my $self = shift; return $self->quantification_relationship_type_id(@_) }

sub features { my $self = shift; return map $_->feature_id, $self->element_type_id }

Chado::Cvterm->has_many(
    'feature_type_id', 'Chado::Feature' => 'type_id'
);

Chado::Cvterm->has_many(
    'biomaterialprop_type_id', 'Chado::Biomaterialprop' => 'type_id'
);

Chado::Cvterm->has_many(
    'feature_cvterm_cvterm_id', 'Chado::Feature_Cvterm' => 'cvterm_id'
);

sub arraydesigns { my $self = shift; return map $_->arraydesign_id, $self->element_type_id }

Chado::Cvterm->has_many(
    'arraydesign_platformtype_id', 'Chado::Arraydesign' => 'platformtype_id'
);

Chado::Cvterm->has_many(
    'arraydesign_substratetype_id', 'Chado::Arraydesign' => 'substratetype_id'
);

Chado::Cvterm->has_many(
    'library_cvterm_cvterm_id', 'Chado::Library_Cvterm' => 'cvterm_id'
);

Chado::Cvterm->has_many(
    'biomaterial_relationship_type_id', 'Chado::Biomaterial_Relationship' => 'type_id'
);

Chado::Cvterm->has_many(
    'analysisprop_type_id', 'Chado::Analysisprop' => 'type_id'
);

Chado::Cvterm->has_many(
    'cvterm_dbxref_cvterm_id', 'Chado::Cvterm_Dbxref' => 'cvterm_id'
);

Chado::Cvterm->has_many(
    'feature_relationshipprop_type_id', 'Chado::Feature_Relationshipprop' => 'type_id'
);

Chado::Cvterm->has_many(
    'cvtermprop_cvterm_id', 'Chado::Cvtermprop' => 'cvterm_id'
);

Chado::Cvterm->has_many(
    'cvtermprop_type_id', 'Chado::Cvtermprop' => 'type_id'
);

Chado::Cvterm->has_many(
    'element_relationship_type_id', 'Chado::Element_Relationship' => 'type_id'
);

Chado::Cvterm->has_many(
    'quantification_relationship_type_id', 'Chado::Quantification_Relationship' => 'type_id'
);

Chado::Cvterm->has_many(
    'element_type_id', 'Chado::Element' => 'type_id'
);

Chado::Cvterm->has_many(
    'featuremap_unittype_id', 'Chado::Featuremap' => 'unittype_id'
);

Chado::Cvterm->has_many(
    'treatment_type_id', 'Chado::Treatment' => 'type_id'
);

Chado::Cvterm->has_many(
    'arraydesignprop_type_id', 'Chado::Arraydesignprop' => 'type_id'
);

Chado::Cvterm->has_many(
    'synonym_type_id', 'Chado::Synonym' => 'type_id'
);

Chado::Cvterm->has_many(
    'pubprop_type_id', 'Chado::Pubprop' => 'type_id'
);

Chado::Cvterm->has_many(
    'cvtermpath_type_id', 'Chado::Cvtermpath' => 'type_id'
);

Chado::Cvterm->has_many(
    'cvtermpath_subject_id', 'Chado::Cvtermpath' => 'subject_id'
);

Chado::Cvterm->has_many(
    'cvtermpath_object_id', 'Chado::Cvtermpath' => 'object_id'
);

Chado::Cvterm->has_many(
    'quantificationprop_type_id', 'Chado::Quantificationprop' => 'type_id'
);

Chado::Cvterm->has_many(
    'libraryprop_type_id', 'Chado::Libraryprop' => 'type_id'
);

Chado::Cvterm->has_many(
    'biomaterial_treatment_unittype_id', 'Chado::Biomaterial_Treatment' => 'unittype_id'
);

Chado::Cvterm->has_many(
    'expression_cvterm_cvterm_id', 'Chado::Expression_Cvterm' => 'cvterm_id'
);

Chado::Cvterm->has_many(
    'cvterm_relationship_type_id', 'Chado::Cvterm_Relationship' => 'type_id'
);

Chado::Cvterm->has_many(
    'cvterm_relationship_subject_id', 'Chado::Cvterm_Relationship' => 'subject_id'
);

Chado::Cvterm->has_many(
    'cvterm_relationship_object_id', 'Chado::Cvterm_Relationship' => 'object_id'
);

Chado::Cvterm->has_many(
    'acquisitionprop_type_id', 'Chado::Acquisitionprop' => 'type_id'
);

Chado::Cvterm->has_many(
    'studydesignprop_type_id', 'Chado::Studydesignprop' => 'type_id'
);

sub contact_relationships { my $self = shift; return $self->contact_relationship_type_id(@_) }

Chado::Cvterm->has_many(
    'contact_type_id', 'Chado::Contact' => 'type_id'
);

sub librarys { my $self = shift; return map $_->library_id, $self->library_cvterm_cvterm_id }

Chado::Cvterm->has_many(
    'library_type_id', 'Chado::Library' => 'type_id'
);

sub phenotype_comparisons { my $self = shift; return $self->phenotype_comparison_type_id(@_) }

Chado::Cvterm->has_many(
    'featureprop_type_id', 'Chado::Featureprop' => 'type_id'
);

sub dbxrefs { my $self = shift; return map $_->dbxref_id, $self->element_type_id }

Chado::Cvterm->has_many(
    'assayprop_type_id', 'Chado::Assayprop' => 'type_id'
);

Chado::Cvterm->has_many(
    'environment_cvterm_cvterm_id', 'Chado::Environment_Cvterm' => 'cvterm_id'
);

Chado::Cvterm->has_many(
    'contact_relationship_type_id', 'Chado::Contact_Relationship' => 'type_id'
);

Chado::Cvterm->has_many(
    'protocolparam_datatype_id', 'Chado::Protocolparam' => 'datatype_id'
);

Chado::Cvterm->has_many(
    'protocolparam_unittype_id', 'Chado::Protocolparam' => 'unittype_id'
);

sub pubs { my $self = shift; return map $_->pub_id, $self->library_cvterm_cvterm_id }

Chado::Cvterm->has_many(
    'pub_type_id', 'Chado::Pub' => 'type_id'
);

Chado::Cvterm->has_many(
    'control_type_id', 'Chado::Control' => 'type_id'
);

Chado::Cvterm->has_many(
    'organismprop_type_id', 'Chado::Organismprop' => 'type_id'
);

Chado::Cvterm->has_many(
    'dbxrefprop_type_id', 'Chado::Dbxrefprop' => 'type_id'
);

Chado::Cvterm->has_many(
    'phenotype_cvterm_cvterm_id', 'Chado::Phenotype_Cvterm' => 'cvterm_id'
);

Chado::Cvterm->has_many(
    'feature_genotype_cvterm_id', 'Chado::Feature_Genotype' => 'cvterm_id'
);

sub cvterm_relationship_type_ids { my $self = shift; return $self->cvterm_relationship_type_id(@_) }

sub cvterm_relationship_subject_ids { my $self = shift; return $self->cvterm_relationship_subject_id(@_) }

sub cvterm_relationship_object_ids { my $self = shift; return $self->cvterm_relationship_object_id(@_) }

Chado::Cvterm->has_many(
    'feature_relationship_type_id', 'Chado::Feature_Relationship' => 'type_id'
);

Chado::Cvterm->has_many(
    'acquisition_relationship_type_id', 'Chado::Acquisition_Relationship' => 'type_id'
);

sub biomaterial_relationships { my $self = shift; return $self->biomaterial_relationship_type_id(@_) }

sub phenotype_comparisons { my $self = shift; return $self->phenotype_comparison_type_id(@_) }

Chado::Cvterm->has_many(
    'phenstatement_type_id', 'Chado::Phenstatement' => 'type_id'
);

sub phenotype_comparisons { my $self = shift; return $self->phenotype_comparison_type_id(@_) }

Chado::Cvterm->has_many(
    'phenotype_observable_id', 'Chado::Phenotype' => 'observable_id'
);

Chado::Cvterm->has_many(
    'phenotype_attr_id', 'Chado::Phenotype' => 'attr_id'
);

Chado::Cvterm->has_many(
    'phenotype_cvalue_id', 'Chado::Phenotype' => 'cvalue_id'
);

Chado::Cvterm->has_many(
    'phenotype_assay_id', 'Chado::Phenotype' => 'assay_id'
);

Chado::Cvterm->has_many(
    'pub_relationship_type_id', 'Chado::Pub_Relationship' => 'type_id'
);

Chado::Cvterm->has_many(
    'feature_cvtermprop_type_id', 'Chado::Feature_Cvtermprop' => 'type_id'
);

Chado::Cvterm->has_many(
    'phenotype_comparison_type_id', 'Chado::Phenotype_Comparison' => 'type_id'
);

# -------------------------------------------------------------------
package Chado::Cvterm_Relationship;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Cvterm_Relationship->set_up_table('cvterm_relationship');


Chado::Cvterm_Relationship->has_a(
    type_id => 'Chado::Cvterm'
);

sub Chado::Cvterm_Relationship::type {
    return shift->type_id
}

Chado::Cvterm_Relationship->has_a(
    subject_id => 'Chado::Cvterm'
);

sub Chado::Cvterm_Relationship::subject {
    return shift->subject_id
}

Chado::Cvterm_Relationship->has_a(
    object_id => 'Chado::Cvterm'
);

sub Chado::Cvterm_Relationship::object {
    return shift->object_id
}

# -------------------------------------------------------------------
package Chado::Cvtermpath;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Cvtermpath->set_up_table('cvtermpath');


Chado::Cvtermpath->has_a(
    type_id => 'Chado::Cvterm'
);

sub Chado::Cvtermpath::type {
    return shift->type_id
}

Chado::Cvtermpath->has_a(
    subject_id => 'Chado::Cvterm'
);

sub Chado::Cvtermpath::subject {
    return shift->subject_id
}

Chado::Cvtermpath->has_a(
    object_id => 'Chado::Cvterm'
);

sub Chado::Cvtermpath::object {
    return shift->object_id
}

Chado::Cvtermpath->has_a(
    cv_id => 'Chado::Cv'
);

sub Chado::Cvtermpath::cv {
    return shift->cv_id
}

# -------------------------------------------------------------------
package Chado::Cvtermsynonym;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Cvtermsynonym->set_up_table('cvtermsynonym');


Chado::Cvtermsynonym->has_a(
    cvterm_id => 'Chado::Cvterm'
);

sub Chado::Cvtermsynonym::cvterm {
    return shift->cvterm_id
}

Chado::Cvtermsynonym->has_a(
    type_id => 'Chado::Cvterm'
);

sub Chado::Cvtermsynonym::type {
    return shift->type_id
}

# -------------------------------------------------------------------
package Chado::Cvterm_Dbxref;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Cvterm_Dbxref->set_up_table('cvterm_dbxref');


Chado::Cvterm_Dbxref->has_a(
    cvterm_id => 'Chado::Cvterm'
);

sub Chado::Cvterm_Dbxref::cvterm {
    return shift->cvterm_id
}

Chado::Cvterm_Dbxref->has_a(
    dbxref_id => 'Chado::Dbxref'
);

sub Chado::Cvterm_Dbxref::dbxref {
    return shift->dbxref_id
}

# -------------------------------------------------------------------
package Chado::Cvtermprop;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Cvtermprop->set_up_table('cvtermprop');


Chado::Cvtermprop->has_a(
    cvterm_id => 'Chado::Cvterm'
);

sub Chado::Cvtermprop::cvterm {
    return shift->cvterm_id
}

Chado::Cvtermprop->has_a(
    type_id => 'Chado::Cvterm'
);

sub Chado::Cvtermprop::type {
    return shift->type_id
}

# -------------------------------------------------------------------
package Chado::Dbxrefprop;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Dbxrefprop->set_up_table('dbxrefprop');


Chado::Dbxrefprop->has_a(
    dbxref_id => 'Chado::Dbxref'
);

sub Chado::Dbxrefprop::dbxref {
    return shift->dbxref_id
}

Chado::Dbxrefprop->has_a(
    type_id => 'Chado::Cvterm'
);

sub Chado::Dbxrefprop::type {
    return shift->type_id
}

# -------------------------------------------------------------------
package Chado::Organism;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Organism->set_up_table('organism');


Chado::Organism->has_many(
    'biomaterial_taxon_id', 'Chado::Biomaterial' => 'taxon_id'
);

Chado::Organism->has_many(
    'feature_organism_id', 'Chado::Feature' => 'organism_id'
);

Chado::Organism->has_many(
    'organism_dbxref_organism_id', 'Chado::Organism_Dbxref' => 'organism_id'
);

Chado::Organism->has_many(
    'library_organism_id', 'Chado::Library' => 'organism_id'
);

Chado::Organism->has_many(
    'organismprop_organism_id', 'Chado::Organismprop' => 'organism_id'
);

sub dbxrefs { my $self = shift; return map $_->dbxref_id, $self->organism_dbxref_organism_id }

# -------------------------------------------------------------------
package Chado::Organism_Dbxref;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Organism_Dbxref->set_up_table('organism_dbxref');


Chado::Organism_Dbxref->has_a(
    organism_id => 'Chado::Organism'
);

sub Chado::Organism_Dbxref::organism {
    return shift->organism_id
}

Chado::Organism_Dbxref->has_a(
    dbxref_id => 'Chado::Dbxref'
);

sub Chado::Organism_Dbxref::dbxref {
    return shift->dbxref_id
}

# -------------------------------------------------------------------
package Chado::Organismprop;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Organismprop->set_up_table('organismprop');


Chado::Organismprop->has_a(
    organism_id => 'Chado::Organism'
);

sub Chado::Organismprop::organism {
    return shift->organism_id
}

Chado::Organismprop->has_a(
    type_id => 'Chado::Cvterm'
);

sub Chado::Organismprop::type {
    return shift->type_id
}

# -------------------------------------------------------------------
package Chado::Pub;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Pub->set_up_table('pub');


Chado::Pub->has_a(
    type_id => 'Chado::Cvterm'
);

sub Chado::Pub::type {
    return shift->type_id
}

Chado::Pub->has_many(
    'protocol_pub_id', 'Chado::Protocol' => 'pub_id'
);

Chado::Pub->has_many(
    'expression_pub_pub_id', 'Chado::Expression_Pub' => 'pub_id'
);

sub features { my $self = shift; return map $_->feature_id, $self->feature_pub_pub_id }

Chado::Pub->has_many(
    'library_pub_pub_id', 'Chado::Library_Pub' => 'pub_id'
);

sub feature_cvterms { my $self = shift; return map $_->feature_cvterm_id, $self->feature_cvterm_pub_pub_id }

Chado::Pub->has_many(
    'feature_cvterm_pub_id', 'Chado::Feature_Cvterm' => 'pub_id'
);

sub expressions { my $self = shift; return map $_->expression_id, $self->expression_pub_pub_id }

Chado::Pub->has_many(
    'library_cvterm_pub_id', 'Chado::Library_Cvterm' => 'pub_id'
);

Chado::Pub->has_many(
    'study_pub_id', 'Chado::Study' => 'pub_id'
);

Chado::Pub->has_many(
    'feature_relationship_pub_pub_id', 'Chado::Feature_Relationship_Pub' => 'pub_id'
);

sub feature_relationshipprops { my $self = shift; return map $_->feature_relationshipprop_id, $self->feature_relationshipprop_pub_pub_id }

sub featuremaps { my $self = shift; return map $_->featuremap_id, $self->featuremap_pub_pub_id }

Chado::Pub->has_many(
    'pubprop_pub_id', 'Chado::Pubprop' => 'pub_id'
);

Chado::Pub->has_many(
    'feature_cvterm_pub_pub_id', 'Chado::Feature_Cvterm_Pub' => 'pub_id'
);

sub librarys { my $self = shift; return map $_->library_id, $self->library_cvterm_pub_id }

sub phenotype_comparisons { my $self = shift; return $self->phenotype_comparison_pub_id(@_) }

sub featureprops { my $self = shift; return map $_->featureprop_id, $self->featureprop_pub_pub_id }

sub dbxrefs { my $self = shift; return map $_->dbxref_id, $self->pub_dbxref_pub_id }

Chado::Pub->has_many(
    'pubauthor_pub_id', 'Chado::Pubauthor' => 'pub_id'
);

sub pub_relationship_subject_ids { my $self = shift; return $self->pub_relationship_subject_id(@_) }

sub pub_relationship_object_ids { my $self = shift; return $self->pub_relationship_object_id(@_) }

Chado::Pub->has_many(
    'feature_synonym_pub_id', 'Chado::Feature_Synonym' => 'pub_id'
);

Chado::Pub->has_many(
    'feature_pub_pub_id', 'Chado::Feature_Pub' => 'pub_id'
);

Chado::Pub->has_many(
    'featuremap_pub_pub_id', 'Chado::Featuremap_Pub' => 'pub_id'
);

sub cvterms { my $self = shift; return map $_->cvterm_id, $self->library_cvterm_pub_id }

sub feature_relationships { my $self = shift; return map $_->feature_relationship_id, $self->feature_relationship_pub_pub_id }

Chado::Pub->has_many(
    'feature_relationshipprop_pub_pub_id', 'Chado::Feature_Relationshipprop_Pub' => 'pub_id'
);

sub phenotype_comparisons { my $self = shift; return $self->phenotype_comparison_pub_id(@_) }

Chado::Pub->has_many(
    'phenstatement_pub_id', 'Chado::Phenstatement' => 'pub_id'
);

Chado::Pub->has_many(
    'pub_dbxref_pub_id', 'Chado::Pub_Dbxref' => 'pub_id'
);

sub phenotype_comparisons { my $self = shift; return $self->phenotype_comparison_pub_id(@_) }

Chado::Pub->has_many(
    'phendesc_pub_id', 'Chado::Phendesc' => 'pub_id'
);

Chado::Pub->has_many(
    'featureprop_pub_pub_id', 'Chado::Featureprop_Pub' => 'pub_id'
);

Chado::Pub->has_many(
    'library_synonym_pub_id', 'Chado::Library_Synonym' => 'pub_id'
);

Chado::Pub->has_many(
    'pub_relationship_subject_id', 'Chado::Pub_Relationship' => 'subject_id'
);

Chado::Pub->has_many(
    'pub_relationship_object_id', 'Chado::Pub_Relationship' => 'object_id'
);

Chado::Pub->has_many(
    'phenotype_comparison_pub_id', 'Chado::Phenotype_Comparison' => 'pub_id'
);

# -------------------------------------------------------------------
package Chado::Pub_Relationship;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Pub_Relationship->set_up_table('pub_relationship');


Chado::Pub_Relationship->has_a(
    subject_id => 'Chado::Pub'
);

sub Chado::Pub_Relationship::subject {
    return shift->subject_id
}

Chado::Pub_Relationship->has_a(
    object_id => 'Chado::Pub'
);

sub Chado::Pub_Relationship::object {
    return shift->object_id
}

Chado::Pub_Relationship->has_a(
    type_id => 'Chado::Cvterm'
);

sub Chado::Pub_Relationship::type {
    return shift->type_id
}

# -------------------------------------------------------------------
package Chado::Pub_Dbxref;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Pub_Dbxref->set_up_table('pub_dbxref');


Chado::Pub_Dbxref->has_a(
    pub_id => 'Chado::Pub'
);

sub Chado::Pub_Dbxref::pub {
    return shift->pub_id
}

Chado::Pub_Dbxref->has_a(
    dbxref_id => 'Chado::Dbxref'
);

sub Chado::Pub_Dbxref::dbxref {
    return shift->dbxref_id
}

# -------------------------------------------------------------------
package Chado::Pubauthor;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Pubauthor->set_up_table('pubauthor');


Chado::Pubauthor->has_a(
    pub_id => 'Chado::Pub'
);

sub Chado::Pubauthor::pub {
    return shift->pub_id
}

# -------------------------------------------------------------------
package Chado::Pubprop;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Pubprop->set_up_table('pubprop');


Chado::Pubprop->has_a(
    pub_id => 'Chado::Pub'
);

sub Chado::Pubprop::pub {
    return shift->pub_id
}

Chado::Pubprop->has_a(
    type_id => 'Chado::Cvterm'
);

sub Chado::Pubprop::type {
    return shift->type_id
}

# -------------------------------------------------------------------
package Chado::Feature;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Feature->set_up_table('feature');


Chado::Feature->has_a(
    dbxref_id => 'Chado::Dbxref'
);

sub Chado::Feature::dbxref {
    return shift->dbxref_id
}

Chado::Feature->has_a(
    organism_id => 'Chado::Organism'
);

sub Chado::Feature::organism {
    return shift->organism_id
}

Chado::Feature->has_a(
    type_id => 'Chado::Cvterm'
);

sub Chado::Feature::type {
    return shift->type_id
}

Chado::Feature->has_many(
    'feature_dbxref_feature_id', 'Chado::Feature_Dbxref' => 'feature_id'
);

sub librarys { my $self = shift; return map $_->library_id, $self->library_feature_feature_id }

Chado::Feature->has_many(
    'featureprop_feature_id', 'Chado::Featureprop' => 'feature_id'
);

sub dbxrefs { my $self = shift; return map $_->dbxref_id, $self->element_feature_id }

Chado::Feature->has_many(
    'feature_expression_feature_id', 'Chado::Feature_Expression' => 'feature_id'
);

Chado::Feature->has_many(
    'feature_cvterm_feature_id', 'Chado::Feature_Cvterm' => 'feature_id'
);

sub expressions { my $self = shift; return map $_->expression_id, $self->feature_expression_feature_id }

sub arraydesigns { my $self = shift; return map $_->arraydesign_id, $self->element_feature_id }

Chado::Feature->has_many(
    'feature_synonym_feature_id', 'Chado::Feature_Synonym' => 'feature_id'
);

sub pubs { my $self = shift; return map $_->pub_id, $self->feature_pub_feature_id }

Chado::Feature->has_many(
    'library_feature_feature_id', 'Chado::Library_Feature' => 'feature_id'
);

Chado::Feature->has_many(
    'featurerange_feature_id', 'Chado::Featurerange' => 'feature_id'
);

Chado::Feature->has_many(
    'featurerange_leftstartf_id', 'Chado::Featurerange' => 'leftstartf_id'
);

Chado::Feature->has_many(
    'featurerange_leftendf_id', 'Chado::Featurerange' => 'leftendf_id'
);

Chado::Feature->has_many(
    'featurerange_rightstartf_id', 'Chado::Featurerange' => 'rightstartf_id'
);

Chado::Feature->has_many(
    'featurerange_rightendf_id', 'Chado::Featurerange' => 'rightendf_id'
);

Chado::Feature->has_many(
    'featureloc_feature_id', 'Chado::Featureloc' => 'feature_id'
);

Chado::Feature->has_many(
    'featureloc_srcfeature_id', 'Chado::Featureloc' => 'srcfeature_id'
);

Chado::Feature->has_many(
    'analysisfeature_feature_id', 'Chado::Analysisfeature' => 'feature_id'
);

Chado::Feature->has_many(
    'feature_pub_feature_id', 'Chado::Feature_Pub' => 'feature_id'
);

Chado::Feature->has_many(
    'feature_phenotype_feature_id', 'Chado::Feature_Phenotype' => 'feature_id'
);

Chado::Feature->has_many(
    'feature_genotype_feature_id', 'Chado::Feature_Genotype' => 'feature_id'
);

Chado::Feature->has_many(
    'feature_genotype_chromosome_id', 'Chado::Feature_Genotype' => 'chromosome_id'
);

Chado::Feature->has_many(
    'element_feature_id', 'Chado::Element' => 'feature_id'
);

sub cvterms { my $self = shift; return map $_->cvterm_id, $self->element_feature_id }

Chado::Feature->has_many(
    'feature_relationship_subject_id', 'Chado::Feature_Relationship' => 'subject_id'
);

Chado::Feature->has_many(
    'feature_relationship_object_id', 'Chado::Feature_Relationship' => 'object_id'
);

Chado::Feature->has_many(
    'featurepos_feature_id', 'Chado::Featurepos' => 'feature_id'
);

Chado::Feature->has_many(
    'featurepos_map_feature_id', 'Chado::Featurepos' => 'map_feature_id'
);

sub phenotypes { my $self = shift; return map $_->phenotype_id, $self->feature_phenotype_feature_id }

# -------------------------------------------------------------------
package Chado::Featureloc;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Featureloc->set_up_table('featureloc');


Chado::Featureloc->has_a(
    feature_id => 'Chado::Feature'
);

sub Chado::Featureloc::feature {
    return shift->feature_id
}

Chado::Featureloc->has_a(
    srcfeature_id => 'Chado::Feature'
);

sub Chado::Featureloc::srcfeature {
    return shift->srcfeature_id
}

# -------------------------------------------------------------------
package Chado::Feature_Pub;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Feature_Pub->set_up_table('feature_pub');


Chado::Feature_Pub->has_a(
    feature_id => 'Chado::Feature'
);

sub Chado::Feature_Pub::feature {
    return shift->feature_id
}

Chado::Feature_Pub->has_a(
    pub_id => 'Chado::Pub'
);

sub Chado::Feature_Pub::pub {
    return shift->pub_id
}

# -------------------------------------------------------------------
package Chado::Featureprop;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Featureprop->set_up_table('featureprop');


Chado::Featureprop->has_a(
    feature_id => 'Chado::Feature'
);

sub Chado::Featureprop::feature {
    return shift->feature_id
}

Chado::Featureprop->has_a(
    type_id => 'Chado::Cvterm'
);

sub Chado::Featureprop::type {
    return shift->type_id
}

Chado::Featureprop->has_many(
    'featureprop_pub_featureprop_id', 'Chado::Featureprop_Pub' => 'featureprop_id'
);

sub pubs { my $self = shift; return map $_->pub_id, $self->featureprop_pub_featureprop_id }

# -------------------------------------------------------------------
package Chado::Featureprop_Pub;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Featureprop_Pub->set_up_table('featureprop_pub');


Chado::Featureprop_Pub->has_a(
    featureprop_id => 'Chado::Featureprop'
);

sub Chado::Featureprop_Pub::featureprop {
    return shift->featureprop_id
}

Chado::Featureprop_Pub->has_a(
    pub_id => 'Chado::Pub'
);

sub Chado::Featureprop_Pub::pub {
    return shift->pub_id
}

# -------------------------------------------------------------------
package Chado::Feature_Dbxref;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Feature_Dbxref->set_up_table('feature_dbxref');


Chado::Feature_Dbxref->has_a(
    feature_id => 'Chado::Feature'
);

sub Chado::Feature_Dbxref::feature {
    return shift->feature_id
}

Chado::Feature_Dbxref->has_a(
    dbxref_id => 'Chado::Dbxref'
);

sub Chado::Feature_Dbxref::dbxref {
    return shift->dbxref_id
}

# -------------------------------------------------------------------
package Chado::Feature_Relationship;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Feature_Relationship->set_up_table('feature_relationship');


Chado::Feature_Relationship->has_a(
    subject_id => 'Chado::Feature'
);

sub Chado::Feature_Relationship::subject {
    return shift->subject_id
}

Chado::Feature_Relationship->has_a(
    object_id => 'Chado::Feature'
);

sub Chado::Feature_Relationship::object {
    return shift->object_id
}

Chado::Feature_Relationship->has_a(
    type_id => 'Chado::Cvterm'
);

sub Chado::Feature_Relationship::type {
    return shift->type_id
}

Chado::Feature_Relationship->has_many(
    'feature_relationshipprop_feature_relationship_id', 'Chado::Feature_Relationshipprop' => 'feature_relationship_id'
);

sub pubs { my $self = shift; return map $_->pub_id, $self->feature_relationship_pub_feature_relationship_id }

Chado::Feature_Relationship->has_many(
    'feature_relationship_pub_feature_relationship_id', 'Chado::Feature_Relationship_Pub' => 'feature_relationship_id'
);

# -------------------------------------------------------------------
package Chado::Feature_Relationship_Pub;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Feature_Relationship_Pub->set_up_table('feature_relationship_pub');


Chado::Feature_Relationship_Pub->has_a(
    feature_relationship_id => 'Chado::Feature_Relationship'
);

sub Chado::Feature_Relationship_Pub::feature_relationship {
    return shift->feature_relationship_id
}

Chado::Feature_Relationship_Pub->has_a(
    pub_id => 'Chado::Pub'
);

sub Chado::Feature_Relationship_Pub::pub {
    return shift->pub_id
}

# -------------------------------------------------------------------
package Chado::Feature_Relationshipprop;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Feature_Relationshipprop->set_up_table('feature_relationshipprop');


Chado::Feature_Relationshipprop->has_a(
    feature_relationship_id => 'Chado::Feature_Relationship'
);

sub Chado::Feature_Relationshipprop::feature_relationship {
    return shift->feature_relationship_id
}

Chado::Feature_Relationshipprop->has_a(
    type_id => 'Chado::Cvterm'
);

sub Chado::Feature_Relationshipprop::type {
    return shift->type_id
}

sub pubs { my $self = shift; return map $_->pub_id, $self->feature_relationshipprop_pub_feature_relationshipprop_id }

Chado::Feature_Relationshipprop->has_many(
    'feature_relationshipprop_pub_feature_relationshipprop_id', 'Chado::Feature_Relationshipprop_Pub' => 'feature_relationshipprop_id'
);

# -------------------------------------------------------------------
package Chado::Feature_Relationshipprop_Pub;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Feature_Relationshipprop_Pub->set_up_table('feature_relationshipprop_pub');


Chado::Feature_Relationshipprop_Pub->has_a(
    feature_relationshipprop_id => 'Chado::Feature_Relationshipprop'
);

sub Chado::Feature_Relationshipprop_Pub::feature_relationshipprop {
    return shift->feature_relationshipprop_id
}

Chado::Feature_Relationshipprop_Pub->has_a(
    pub_id => 'Chado::Pub'
);

sub Chado::Feature_Relationshipprop_Pub::pub {
    return shift->pub_id
}

# -------------------------------------------------------------------
package Chado::Feature_Cvterm;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Feature_Cvterm->set_up_table('feature_cvterm');


Chado::Feature_Cvterm->has_a(
    feature_id => 'Chado::Feature'
);

sub Chado::Feature_Cvterm::feature {
    return shift->feature_id
}

Chado::Feature_Cvterm->has_a(
    cvterm_id => 'Chado::Cvterm'
);

sub Chado::Feature_Cvterm::cvterm {
    return shift->cvterm_id
}

Chado::Feature_Cvterm->has_a(
    pub_id => 'Chado::Pub'
);

sub Chado::Feature_Cvterm::pub {
    return shift->pub_id
}

Chado::Feature_Cvterm->has_many(
    'feature_cvterm_pub_feature_cvterm_id', 'Chado::Feature_Cvterm_Pub' => 'feature_cvterm_id'
);

Chado::Feature_Cvterm->has_many(
    'feature_cvterm_dbxref_feature_cvterm_id', 'Chado::Feature_Cvterm_Dbxref' => 'feature_cvterm_id'
);

sub pubs { my $self = shift; return map $_->pub_id, $self->feature_cvterm_pub_feature_cvterm_id }

Chado::Feature_Cvterm->has_many(
    'feature_cvtermprop_feature_cvterm_id', 'Chado::Feature_Cvtermprop' => 'feature_cvterm_id'
);

sub dbxrefs { my $self = shift; return map $_->dbxref_id, $self->feature_cvterm_dbxref_feature_cvterm_id }

# -------------------------------------------------------------------
package Chado::Feature_Cvtermprop;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Feature_Cvtermprop->set_up_table('feature_cvtermprop');


Chado::Feature_Cvtermprop->has_a(
    feature_cvterm_id => 'Chado::Feature_Cvterm'
);

sub Chado::Feature_Cvtermprop::feature_cvterm {
    return shift->feature_cvterm_id
}

Chado::Feature_Cvtermprop->has_a(
    type_id => 'Chado::Cvterm'
);

sub Chado::Feature_Cvtermprop::type {
    return shift->type_id
}

# -------------------------------------------------------------------
package Chado::Feature_Cvterm_Dbxref;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Feature_Cvterm_Dbxref->set_up_table('feature_cvterm_dbxref');


Chado::Feature_Cvterm_Dbxref->has_a(
    feature_cvterm_id => 'Chado::Feature_Cvterm'
);

sub Chado::Feature_Cvterm_Dbxref::feature_cvterm {
    return shift->feature_cvterm_id
}

Chado::Feature_Cvterm_Dbxref->has_a(
    dbxref_id => 'Chado::Dbxref'
);

sub Chado::Feature_Cvterm_Dbxref::dbxref {
    return shift->dbxref_id
}

# -------------------------------------------------------------------
package Chado::Feature_Cvterm_Pub;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Feature_Cvterm_Pub->set_up_table('feature_cvterm_pub');


Chado::Feature_Cvterm_Pub->has_a(
    feature_cvterm_id => 'Chado::Feature_Cvterm'
);

sub Chado::Feature_Cvterm_Pub::feature_cvterm {
    return shift->feature_cvterm_id
}

Chado::Feature_Cvterm_Pub->has_a(
    pub_id => 'Chado::Pub'
);

sub Chado::Feature_Cvterm_Pub::pub {
    return shift->pub_id
}

# -------------------------------------------------------------------
package Chado::Synonym;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Synonym->set_up_table('synonym');


Chado::Synonym->has_a(
    type_id => 'Chado::Cvterm'
);

sub Chado::Synonym::type {
    return shift->type_id
}

Chado::Synonym->has_many(
    'library_synonym_synonym_id', 'Chado::Library_Synonym' => 'synonym_id'
);

Chado::Synonym->has_many(
    'feature_synonym_synonym_id', 'Chado::Feature_Synonym' => 'synonym_id'
);

# -------------------------------------------------------------------
package Chado::Feature_Synonym;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Feature_Synonym->set_up_table('feature_synonym');


Chado::Feature_Synonym->has_a(
    synonym_id => 'Chado::Synonym'
);

sub Chado::Feature_Synonym::synonym {
    return shift->synonym_id
}

Chado::Feature_Synonym->has_a(
    feature_id => 'Chado::Feature'
);

sub Chado::Feature_Synonym::feature {
    return shift->feature_id
}

Chado::Feature_Synonym->has_a(
    pub_id => 'Chado::Pub'
);

sub Chado::Feature_Synonym::pub {
    return shift->pub_id
}

# -------------------------------------------------------------------
package Chado::Genotype;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Genotype->set_up_table('genotype');


Chado::Genotype->has_many(
    'phenstatement_genotype_id', 'Chado::Phenstatement' => 'genotype_id'
);

sub phenotype_comparison_genotype1_ids { my $self = shift; return $self->phenotype_comparison_genotype1_id(@_) }

sub phenotype_comparison_genotype2_ids { my $self = shift; return $self->phenotype_comparison_genotype2_id(@_) }

Chado::Genotype->has_many(
    'phendesc_genotype_id', 'Chado::Phendesc' => 'genotype_id'
);

sub phenotype_comparison_genotype1_ids { my $self = shift; return $self->phenotype_comparison_genotype1_id(@_) }

sub phenotype_comparison_genotype2_ids { my $self = shift; return $self->phenotype_comparison_genotype2_id(@_) }

sub phenotype_comparison_genotype1_ids { my $self = shift; return $self->phenotype_comparison_genotype1_id(@_) }

sub phenotype_comparison_genotype2_ids { my $self = shift; return $self->phenotype_comparison_genotype2_id(@_) }

Chado::Genotype->has_many(
    'feature_genotype_genotype_id', 'Chado::Feature_Genotype' => 'genotype_id'
);

Chado::Genotype->has_many(
    'phenotype_comparison_genotype1_id', 'Chado::Phenotype_Comparison' => 'genotype1_id'
);

Chado::Genotype->has_many(
    'phenotype_comparison_genotype2_id', 'Chado::Phenotype_Comparison' => 'genotype2_id'
);

# -------------------------------------------------------------------
package Chado::Feature_Genotype;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Feature_Genotype->set_up_table('feature_genotype');


Chado::Feature_Genotype->has_a(
    feature_id => 'Chado::Feature'
);

sub Chado::Feature_Genotype::feature {
    return shift->feature_id
}

Chado::Feature_Genotype->has_a(
    genotype_id => 'Chado::Genotype'
);

sub Chado::Feature_Genotype::genotype {
    return shift->genotype_id
}

Chado::Feature_Genotype->has_a(
    chromosome_id => 'Chado::Feature'
);

sub Chado::Feature_Genotype::chromosome {
    return shift->chromosome_id
}

Chado::Feature_Genotype->has_a(
    cvterm_id => 'Chado::Cvterm'
);

sub Chado::Feature_Genotype::cvterm {
    return shift->cvterm_id
}

# -------------------------------------------------------------------
package Chado::Environment;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Environment->set_up_table('environment');


Chado::Environment->has_many(
    'phenstatement_environment_id', 'Chado::Phenstatement' => 'environment_id'
);

sub phenotype_comparison_environment1_ids { my $self = shift; return $self->phenotype_comparison_environment1_id(@_) }

sub phenotype_comparison_environment2_ids { my $self = shift; return $self->phenotype_comparison_environment2_id(@_) }

Chado::Environment->has_many(
    'environment_cvterm_environment_id', 'Chado::Environment_Cvterm' => 'environment_id'
);

Chado::Environment->has_many(
    'phendesc_environment_id', 'Chado::Phendesc' => 'environment_id'
);

sub phenotype_comparison_environment1_ids { my $self = shift; return $self->phenotype_comparison_environment1_id(@_) }

sub phenotype_comparison_environment2_ids { my $self = shift; return $self->phenotype_comparison_environment2_id(@_) }

sub phenotype_comparison_environment1_ids { my $self = shift; return $self->phenotype_comparison_environment1_id(@_) }

sub phenotype_comparison_environment2_ids { my $self = shift; return $self->phenotype_comparison_environment2_id(@_) }

Chado::Environment->has_many(
    'phenotype_comparison_environment1_id', 'Chado::Phenotype_Comparison' => 'environment1_id'
);

Chado::Environment->has_many(
    'phenotype_comparison_environment2_id', 'Chado::Phenotype_Comparison' => 'environment2_id'
);

# -------------------------------------------------------------------
package Chado::Environment_Cvterm;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Environment_Cvterm->set_up_table('environment_cvterm');


Chado::Environment_Cvterm->has_a(
    environment_id => 'Chado::Environment'
);

sub Chado::Environment_Cvterm::environment {
    return shift->environment_id
}

Chado::Environment_Cvterm->has_a(
    cvterm_id => 'Chado::Cvterm'
);

sub Chado::Environment_Cvterm::cvterm {
    return shift->cvterm_id
}

# -------------------------------------------------------------------
package Chado::Phenotype;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Phenotype->set_up_table('phenotype');


Chado::Phenotype->has_a(
    observable_id => 'Chado::Cvterm'
);

sub Chado::Phenotype::observable {
    return shift->observable_id
}

Chado::Phenotype->has_a(
    attr_id => 'Chado::Cvterm'
);

sub Chado::Phenotype::attr {
    return shift->attr_id
}

Chado::Phenotype->has_a(
    cvalue_id => 'Chado::Cvterm'
);

sub Chado::Phenotype::cvalue {
    return shift->cvalue_id
}

Chado::Phenotype->has_a(
    assay_id => 'Chado::Cvterm'
);

sub Chado::Phenotype::assay {
    return shift->assay_id
}

Chado::Phenotype->has_many(
    'phenstatement_phenotype_id', 'Chado::Phenstatement' => 'phenotype_id'
);

sub phenotype_comparison_phenotype1_ids { my $self = shift; return $self->phenotype_comparison_phenotype1_id(@_) }

sub phenotype_comparison_phenotype2_ids { my $self = shift; return $self->phenotype_comparison_phenotype2_id(@_) }

sub features { my $self = shift; return map $_->feature_id, $self->feature_phenotype_phenotype_id }

Chado::Phenotype->has_many(
    'phenotype_cvterm_phenotype_id', 'Chado::Phenotype_Cvterm' => 'phenotype_id'
);

sub phenotype_comparison_phenotype1_ids { my $self = shift; return $self->phenotype_comparison_phenotype1_id(@_) }

sub phenotype_comparison_phenotype2_ids { my $self = shift; return $self->phenotype_comparison_phenotype2_id(@_) }

Chado::Phenotype->has_many(
    'feature_phenotype_phenotype_id', 'Chado::Feature_Phenotype' => 'phenotype_id'
);

sub phenotype_comparison_phenotype1_ids { my $self = shift; return $self->phenotype_comparison_phenotype1_id(@_) }

sub phenotype_comparison_phenotype2_ids { my $self = shift; return $self->phenotype_comparison_phenotype2_id(@_) }

Chado::Phenotype->has_many(
    'phenotype_comparison_phenotype1_id', 'Chado::Phenotype_Comparison' => 'phenotype1_id'
);

Chado::Phenotype->has_many(
    'phenotype_comparison_phenotype2_id', 'Chado::Phenotype_Comparison' => 'phenotype2_id'
);

# -------------------------------------------------------------------
package Chado::Phenotype_Cvterm;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Phenotype_Cvterm->set_up_table('phenotype_cvterm');


Chado::Phenotype_Cvterm->has_a(
    phenotype_id => 'Chado::Phenotype'
);

sub Chado::Phenotype_Cvterm::phenotype {
    return shift->phenotype_id
}

Chado::Phenotype_Cvterm->has_a(
    cvterm_id => 'Chado::Cvterm'
);

sub Chado::Phenotype_Cvterm::cvterm {
    return shift->cvterm_id
}

# -------------------------------------------------------------------
package Chado::Phenstatement;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Phenstatement->set_up_table('phenstatement');


Chado::Phenstatement->has_a(
    genotype_id => 'Chado::Genotype'
);

sub Chado::Phenstatement::genotype {
    return shift->genotype_id
}

Chado::Phenstatement->has_a(
    environment_id => 'Chado::Environment'
);

sub Chado::Phenstatement::environment {
    return shift->environment_id
}

Chado::Phenstatement->has_a(
    phenotype_id => 'Chado::Phenotype'
);

sub Chado::Phenstatement::phenotype {
    return shift->phenotype_id
}

Chado::Phenstatement->has_a(
    type_id => 'Chado::Cvterm'
);

sub Chado::Phenstatement::type {
    return shift->type_id
}

Chado::Phenstatement->has_a(
    pub_id => 'Chado::Pub'
);

sub Chado::Phenstatement::pub {
    return shift->pub_id
}

# -------------------------------------------------------------------
package Chado::Feature_Phenotype;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Feature_Phenotype->set_up_table('feature_phenotype');


Chado::Feature_Phenotype->has_a(
    feature_id => 'Chado::Feature'
);

sub Chado::Feature_Phenotype::feature {
    return shift->feature_id
}

Chado::Feature_Phenotype->has_a(
    phenotype_id => 'Chado::Phenotype'
);

sub Chado::Feature_Phenotype::phenotype {
    return shift->phenotype_id
}

# -------------------------------------------------------------------
package Chado::Phendesc;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Phendesc->set_up_table('phendesc');


Chado::Phendesc->has_a(
    genotype_id => 'Chado::Genotype'
);

sub Chado::Phendesc::genotype {
    return shift->genotype_id
}

Chado::Phendesc->has_a(
    environment_id => 'Chado::Environment'
);

sub Chado::Phendesc::environment {
    return shift->environment_id
}

Chado::Phendesc->has_a(
    pub_id => 'Chado::Pub'
);

sub Chado::Phendesc::pub {
    return shift->pub_id
}

# -------------------------------------------------------------------
package Chado::Phenotype_Comparison;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Phenotype_Comparison->set_up_table('phenotype_comparison');


Chado::Phenotype_Comparison->has_a(
    genotype1_id => 'Chado::Genotype'
);

sub Chado::Phenotype_Comparison::genotype1 {
    return shift->genotype1_id
}

Chado::Phenotype_Comparison->has_a(
    environment1_id => 'Chado::Environment'
);

sub Chado::Phenotype_Comparison::environment1 {
    return shift->environment1_id
}

Chado::Phenotype_Comparison->has_a(
    genotype2_id => 'Chado::Genotype'
);

sub Chado::Phenotype_Comparison::genotype2 {
    return shift->genotype2_id
}

Chado::Phenotype_Comparison->has_a(
    environment2_id => 'Chado::Environment'
);

sub Chado::Phenotype_Comparison::environment2 {
    return shift->environment2_id
}

Chado::Phenotype_Comparison->has_a(
    phenotype1_id => 'Chado::Phenotype'
);

sub Chado::Phenotype_Comparison::phenotype1 {
    return shift->phenotype1_id
}

Chado::Phenotype_Comparison->has_a(
    phenotype2_id => 'Chado::Phenotype'
);

sub Chado::Phenotype_Comparison::phenotype2 {
    return shift->phenotype2_id
}

Chado::Phenotype_Comparison->has_a(
    type_id => 'Chado::Cvterm'
);

sub Chado::Phenotype_Comparison::type {
    return shift->type_id
}

Chado::Phenotype_Comparison->has_a(
    pub_id => 'Chado::Pub'
);

sub Chado::Phenotype_Comparison::pub {
    return shift->pub_id
}

# -------------------------------------------------------------------
package Chado::Analysis;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Analysis->set_up_table('analysis');


Chado::Analysis->has_many(
    'analysisfeature_analysis_id', 'Chado::Analysisfeature' => 'analysis_id'
);

Chado::Analysis->has_many(
    'quantification_analysis_id', 'Chado::Quantification' => 'analysis_id'
);

Chado::Analysis->has_many(
    'analysisprop_analysis_id', 'Chado::Analysisprop' => 'analysis_id'
);

# -------------------------------------------------------------------
package Chado::Analysisprop;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Analysisprop->set_up_table('analysisprop');


Chado::Analysisprop->has_a(
    analysis_id => 'Chado::Analysis'
);

sub Chado::Analysisprop::analysis {
    return shift->analysis_id
}

Chado::Analysisprop->has_a(
    type_id => 'Chado::Cvterm'
);

sub Chado::Analysisprop::type {
    return shift->type_id
}

# -------------------------------------------------------------------
package Chado::Analysisfeature;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Analysisfeature->set_up_table('analysisfeature');


Chado::Analysisfeature->has_a(
    feature_id => 'Chado::Feature'
);

sub Chado::Analysisfeature::feature {
    return shift->feature_id
}

Chado::Analysisfeature->has_a(
    analysis_id => 'Chado::Analysis'
);

sub Chado::Analysisfeature::analysis {
    return shift->analysis_id
}

# -------------------------------------------------------------------
package Chado::Expression;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Expression->set_up_table('expression');


Chado::Expression->has_many(
    'expression_pub_expression_id', 'Chado::Expression_Pub' => 'expression_id'
);

sub features { my $self = shift; return map $_->feature_id, $self->feature_expression_expression_id }

sub eimages { my $self = shift; return map $_->eimage_id, $self->expression_image_expression_id }

Chado::Expression->has_many(
    'feature_expression_expression_id', 'Chado::Feature_Expression' => 'expression_id'
);

sub pubs { my $self = shift; return map $_->pub_id, $self->expression_pub_expression_id }

Chado::Expression->has_many(
    'expression_image_expression_id', 'Chado::Expression_Image' => 'expression_id'
);

Chado::Expression->has_many(
    'expression_cvterm_expression_id', 'Chado::Expression_Cvterm' => 'expression_id'
);

# -------------------------------------------------------------------
package Chado::Feature_Expression;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Feature_Expression->set_up_table('feature_expression');


Chado::Feature_Expression->has_a(
    expression_id => 'Chado::Expression'
);

sub Chado::Feature_Expression::expression {
    return shift->expression_id
}

Chado::Feature_Expression->has_a(
    feature_id => 'Chado::Feature'
);

sub Chado::Feature_Expression::feature {
    return shift->feature_id
}

# -------------------------------------------------------------------
package Chado::Expression_Cvterm;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Expression_Cvterm->set_up_table('expression_cvterm');


Chado::Expression_Cvterm->has_a(
    expression_id => 'Chado::Expression'
);

sub Chado::Expression_Cvterm::expression {
    return shift->expression_id
}

Chado::Expression_Cvterm->has_a(
    cvterm_id => 'Chado::Cvterm'
);

sub Chado::Expression_Cvterm::cvterm {
    return shift->cvterm_id
}

# -------------------------------------------------------------------
package Chado::Expression_Pub;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Expression_Pub->set_up_table('expression_pub');


Chado::Expression_Pub->has_a(
    expression_id => 'Chado::Expression'
);

sub Chado::Expression_Pub::expression {
    return shift->expression_id
}

Chado::Expression_Pub->has_a(
    pub_id => 'Chado::Pub'
);

sub Chado::Expression_Pub::pub {
    return shift->pub_id
}

# -------------------------------------------------------------------
package Chado::Eimage;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Eimage->set_up_table('eimage');


sub expressions { my $self = shift; return map $_->expression_id, $self->expression_image_eimage_id }

Chado::Eimage->has_many(
    'expression_image_eimage_id', 'Chado::Expression_Image' => 'eimage_id'
);

# -------------------------------------------------------------------
package Chado::Expression_Image;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Expression_Image->set_up_table('expression_image');


Chado::Expression_Image->has_a(
    expression_id => 'Chado::Expression'
);

sub Chado::Expression_Image::expression {
    return shift->expression_id
}

Chado::Expression_Image->has_a(
    eimage_id => 'Chado::Eimage'
);

sub Chado::Expression_Image::eimage {
    return shift->eimage_id
}

# -------------------------------------------------------------------
package Chado::Featuremap;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Featuremap->set_up_table('featuremap');


Chado::Featuremap->has_a(
    unittype_id => 'Chado::Cvterm'
);

sub Chado::Featuremap::unittype {
    return shift->unittype_id
}

Chado::Featuremap->has_many(
    'featurerange_featuremap_id', 'Chado::Featurerange' => 'featuremap_id'
);

Chado::Featuremap->has_many(
    'featurepos_featuremap_id', 'Chado::Featurepos' => 'featuremap_id'
);

Chado::Featuremap->has_many(
    'featuremap_pub_featuremap_id', 'Chado::Featuremap_Pub' => 'featuremap_id'
);

sub pubs { my $self = shift; return map $_->pub_id, $self->featuremap_pub_featuremap_id }

# -------------------------------------------------------------------
package Chado::Featurerange;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Featurerange->set_up_table('featurerange');


Chado::Featurerange->has_a(
    featuremap_id => 'Chado::Featuremap'
);

sub Chado::Featurerange::featuremap {
    return shift->featuremap_id
}

Chado::Featurerange->has_a(
    feature_id => 'Chado::Feature'
);

sub Chado::Featurerange::feature {
    return shift->feature_id
}

Chado::Featurerange->has_a(
    leftstartf_id => 'Chado::Feature'
);

sub Chado::Featurerange::leftstartf {
    return shift->leftstartf_id
}

Chado::Featurerange->has_a(
    leftendf_id => 'Chado::Feature'
);

sub Chado::Featurerange::leftendf {
    return shift->leftendf_id
}

Chado::Featurerange->has_a(
    rightstartf_id => 'Chado::Feature'
);

sub Chado::Featurerange::rightstartf {
    return shift->rightstartf_id
}

Chado::Featurerange->has_a(
    rightendf_id => 'Chado::Feature'
);

sub Chado::Featurerange::rightendf {
    return shift->rightendf_id
}

# -------------------------------------------------------------------
package Chado::Featurepos;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Featurepos->set_up_table('featurepos');


Chado::Featurepos->has_a(
    featuremap_id => 'Chado::Featuremap'
);

sub Chado::Featurepos::featuremap {
    return shift->featuremap_id
}

Chado::Featurepos->has_a(
    feature_id => 'Chado::Feature'
);

sub Chado::Featurepos::feature {
    return shift->feature_id
}

Chado::Featurepos->has_a(
    map_feature_id => 'Chado::Feature'
);

sub Chado::Featurepos::map_feature {
    return shift->map_feature_id
}

# -------------------------------------------------------------------
package Chado::Featuremap_Pub;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Featuremap_Pub->set_up_table('featuremap_pub');


Chado::Featuremap_Pub->has_a(
    featuremap_id => 'Chado::Featuremap'
);

sub Chado::Featuremap_Pub::featuremap {
    return shift->featuremap_id
}

Chado::Featuremap_Pub->has_a(
    pub_id => 'Chado::Pub'
);

sub Chado::Featuremap_Pub::pub {
    return shift->pub_id
}

# -------------------------------------------------------------------
package Chado::Library;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Library->set_up_table('library');


Chado::Library->has_a(
    organism_id => 'Chado::Organism'
);

sub Chado::Library::organism {
    return shift->organism_id
}

Chado::Library->has_a(
    type_id => 'Chado::Cvterm'
);

sub Chado::Library::type {
    return shift->type_id
}

Chado::Library->has_many(
    'library_feature_library_id', 'Chado::Library_Feature' => 'library_id'
);

sub cvterms { my $self = shift; return map $_->cvterm_id, $self->library_cvterm_library_id }

sub features { my $self = shift; return map $_->feature_id, $self->library_feature_library_id }

Chado::Library->has_many(
    'library_pub_library_id', 'Chado::Library_Pub' => 'library_id'
);

Chado::Library->has_many(
    'libraryprop_library_id', 'Chado::Libraryprop' => 'library_id'
);

Chado::Library->has_many(
    'library_cvterm_library_id', 'Chado::Library_Cvterm' => 'library_id'
);

sub pubs { my $self = shift; return map $_->pub_id, $self->library_cvterm_library_id }

Chado::Library->has_many(
    'library_synonym_library_id', 'Chado::Library_Synonym' => 'library_id'
);

# -------------------------------------------------------------------
package Chado::Library_Synonym;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Library_Synonym->set_up_table('library_synonym');


Chado::Library_Synonym->has_a(
    synonym_id => 'Chado::Synonym'
);

sub Chado::Library_Synonym::synonym {
    return shift->synonym_id
}

Chado::Library_Synonym->has_a(
    library_id => 'Chado::Library'
);

sub Chado::Library_Synonym::library {
    return shift->library_id
}

Chado::Library_Synonym->has_a(
    pub_id => 'Chado::Pub'
);

sub Chado::Library_Synonym::pub {
    return shift->pub_id
}

# -------------------------------------------------------------------
package Chado::Library_Pub;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Library_Pub->set_up_table('library_pub');


Chado::Library_Pub->has_a(
    library_id => 'Chado::Library'
);

sub Chado::Library_Pub::library {
    return shift->library_id
}

Chado::Library_Pub->has_a(
    pub_id => 'Chado::Pub'
);

sub Chado::Library_Pub::pub {
    return shift->pub_id
}

# -------------------------------------------------------------------
package Chado::Libraryprop;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Libraryprop->set_up_table('libraryprop');


Chado::Libraryprop->has_a(
    library_id => 'Chado::Library'
);

sub Chado::Libraryprop::library {
    return shift->library_id
}

Chado::Libraryprop->has_a(
    type_id => 'Chado::Cvterm'
);

sub Chado::Libraryprop::type {
    return shift->type_id
}

# -------------------------------------------------------------------
package Chado::Library_Cvterm;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Library_Cvterm->set_up_table('library_cvterm');


Chado::Library_Cvterm->has_a(
    library_id => 'Chado::Library'
);

sub Chado::Library_Cvterm::library {
    return shift->library_id
}

Chado::Library_Cvterm->has_a(
    cvterm_id => 'Chado::Cvterm'
);

sub Chado::Library_Cvterm::cvterm {
    return shift->cvterm_id
}

Chado::Library_Cvterm->has_a(
    pub_id => 'Chado::Pub'
);

sub Chado::Library_Cvterm::pub {
    return shift->pub_id
}

# -------------------------------------------------------------------
package Chado::Library_Feature;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Library_Feature->set_up_table('library_feature');


Chado::Library_Feature->has_a(
    library_id => 'Chado::Library'
);

sub Chado::Library_Feature::library {
    return shift->library_id
}

Chado::Library_Feature->has_a(
    feature_id => 'Chado::Feature'
);

sub Chado::Library_Feature::feature {
    return shift->feature_id
}

# -------------------------------------------------------------------
package Chado::Contact;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Contact->set_up_table('contact');


Chado::Contact->has_a(
    type_id => 'Chado::Cvterm'
);

sub Chado::Contact::type {
    return shift->type_id
}

Chado::Contact->has_many(
    'biomaterial_biosourceprovider_id', 'Chado::Biomaterial' => 'biosourceprovider_id'
);

Chado::Contact->has_many(
    'assay_operator_id', 'Chado::Assay' => 'operator_id'
);

Chado::Contact->has_many(
    'contact_relationship_subject_id', 'Chado::Contact_Relationship' => 'subject_id'
);

Chado::Contact->has_many(
    'contact_relationship_object_id', 'Chado::Contact_Relationship' => 'object_id'
);

Chado::Contact->has_many(
    'arraydesign_manufacturer_id', 'Chado::Arraydesign' => 'manufacturer_id'
);

sub contact_relationship_subject_ids { my $self = shift; return $self->contact_relationship_subject_id(@_) }

sub contact_relationship_object_ids { my $self = shift; return $self->contact_relationship_object_id(@_) }

Chado::Contact->has_many(
    'study_contact_id', 'Chado::Study' => 'contact_id'
);

Chado::Contact->has_many(
    'quantification_operator_id', 'Chado::Quantification' => 'operator_id'
);

# -------------------------------------------------------------------
package Chado::Contact_Relationship;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Contact_Relationship->set_up_table('contact_relationship');


Chado::Contact_Relationship->has_a(
    type_id => 'Chado::Cvterm'
);

sub Chado::Contact_Relationship::type {
    return shift->type_id
}

Chado::Contact_Relationship->has_a(
    subject_id => 'Chado::Contact'
);

sub Chado::Contact_Relationship::subject {
    return shift->subject_id
}

Chado::Contact_Relationship->has_a(
    object_id => 'Chado::Contact'
);

sub Chado::Contact_Relationship::object {
    return shift->object_id
}

# -------------------------------------------------------------------
package Chado::Mageml;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Mageml->set_up_table('mageml');


Chado::Mageml->has_many(
    'magedocumentation_mageml_id', 'Chado::Magedocumentation' => 'mageml_id'
);

# -------------------------------------------------------------------
package Chado::Magedocumentation;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Magedocumentation->set_up_table('magedocumentation');


Chado::Magedocumentation->has_a(
    mageml_id => 'Chado::Mageml'
);

sub Chado::Magedocumentation::mageml {
    return shift->mageml_id
}

Chado::Magedocumentation->has_a(
    tableinfo_id => 'Chado::Tableinfo'
);

sub Chado::Magedocumentation::tableinfo {
    return shift->tableinfo_id
}

# -------------------------------------------------------------------
package Chado::Protocol;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Protocol->set_up_table('protocol');


Chado::Protocol->has_a(
    type_id => 'Chado::Cvterm'
);

sub Chado::Protocol::type {
    return shift->type_id
}

Chado::Protocol->has_a(
    pub_id => 'Chado::Pub'
);

sub Chado::Protocol::pub {
    return shift->pub_id
}

Chado::Protocol->has_a(
    dbxref_id => 'Chado::Dbxref'
);

sub Chado::Protocol::dbxref {
    return shift->dbxref_id
}

Chado::Protocol->has_many(
    'treatment_protocol_id', 'Chado::Treatment' => 'protocol_id'
);

Chado::Protocol->has_many(
    'assay_protocol_id', 'Chado::Assay' => 'protocol_id'
);

Chado::Protocol->has_many(
    'acquisition_protocol_id', 'Chado::Acquisition' => 'protocol_id'
);

Chado::Protocol->has_many(
    'arraydesign_protocol_id', 'Chado::Arraydesign' => 'protocol_id'
);

Chado::Protocol->has_many(
    'protocolparam_protocol_id', 'Chado::Protocolparam' => 'protocol_id'
);

Chado::Protocol->has_many(
    'quantification_protocol_id', 'Chado::Quantification' => 'protocol_id'
);

# -------------------------------------------------------------------
package Chado::Protocolparam;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Protocolparam->set_up_table('protocolparam');


Chado::Protocolparam->has_a(
    protocol_id => 'Chado::Protocol'
);

sub Chado::Protocolparam::protocol {
    return shift->protocol_id
}

Chado::Protocolparam->has_a(
    datatype_id => 'Chado::Cvterm'
);

sub Chado::Protocolparam::datatype {
    return shift->datatype_id
}

Chado::Protocolparam->has_a(
    unittype_id => 'Chado::Cvterm'
);

sub Chado::Protocolparam::unittype {
    return shift->unittype_id
}

# -------------------------------------------------------------------
package Chado::Channel;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Channel->set_up_table('channel');


Chado::Channel->has_many(
    'acquisition_channel_id', 'Chado::Acquisition' => 'channel_id'
);

Chado::Channel->has_many(
    'assay_biomaterial_channel_id', 'Chado::Assay_Biomaterial' => 'channel_id'
);

# -------------------------------------------------------------------
package Chado::Arraydesign;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Arraydesign->set_up_table('arraydesign');


Chado::Arraydesign->has_a(
    manufacturer_id => 'Chado::Contact'
);

sub Chado::Arraydesign::manufacturer {
    return shift->manufacturer_id
}

Chado::Arraydesign->has_a(
    platformtype_id => 'Chado::Cvterm'
);

sub Chado::Arraydesign::platformtype {
    return shift->platformtype_id
}

Chado::Arraydesign->has_a(
    substratetype_id => 'Chado::Cvterm'
);

sub Chado::Arraydesign::substratetype {
    return shift->substratetype_id
}

Chado::Arraydesign->has_a(
    protocol_id => 'Chado::Protocol'
);

sub Chado::Arraydesign::protocol {
    return shift->protocol_id
}

Chado::Arraydesign->has_a(
    dbxref_id => 'Chado::Dbxref'
);

sub Chado::Arraydesign::dbxref {
    return shift->dbxref_id
}

sub features { my $self = shift; return map $_->feature_id, $self->element_arraydesign_id }

Chado::Arraydesign->has_many(
    'arraydesignprop_arraydesign_id', 'Chado::Arraydesignprop' => 'arraydesign_id'
);

Chado::Arraydesign->has_many(
    'assay_arraydesign_id', 'Chado::Assay' => 'arraydesign_id'
);

Chado::Arraydesign->has_many(
    'element_arraydesign_id', 'Chado::Element' => 'arraydesign_id'
);

sub cvterms { my $self = shift; return map $_->cvterm_id, $self->element_arraydesign_id }

sub dbxrefs { my $self = shift; return map $_->dbxref_id, $self->element_arraydesign_id }

# -------------------------------------------------------------------
package Chado::Arraydesignprop;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Arraydesignprop->set_up_table('arraydesignprop');


Chado::Arraydesignprop->has_a(
    arraydesign_id => 'Chado::Arraydesign'
);

sub Chado::Arraydesignprop::arraydesign {
    return shift->arraydesign_id
}

Chado::Arraydesignprop->has_a(
    type_id => 'Chado::Cvterm'
);

sub Chado::Arraydesignprop::type {
    return shift->type_id
}

# -------------------------------------------------------------------
package Chado::Assay;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Assay->set_up_table('assay');


Chado::Assay->has_a(
    arraydesign_id => 'Chado::Arraydesign'
);

sub Chado::Assay::arraydesign {
    return shift->arraydesign_id
}

Chado::Assay->has_a(
    protocol_id => 'Chado::Protocol'
);

sub Chado::Assay::protocol {
    return shift->protocol_id
}

Chado::Assay->has_a(
    operator_id => 'Chado::Contact'
);

sub Chado::Assay::operator {
    return shift->operator_id
}

Chado::Assay->has_a(
    dbxref_id => 'Chado::Dbxref'
);

sub Chado::Assay::dbxref {
    return shift->dbxref_id
}

Chado::Assay->has_many(
    'study_assay_assay_id', 'Chado::Study_Assay' => 'assay_id'
);

sub projects { my $self = shift; return map $_->project_id, $self->assay_project_assay_id }

Chado::Assay->has_many(
    'acquisition_assay_id', 'Chado::Acquisition' => 'assay_id'
);

Chado::Assay->has_many(
    'assay_biomaterial_assay_id', 'Chado::Assay_Biomaterial' => 'assay_id'
);

Chado::Assay->has_many(
    'studyfactorvalue_assay_id', 'Chado::Studyfactorvalue' => 'assay_id'
);

Chado::Assay->has_many(
    'assay_project_assay_id', 'Chado::Assay_Project' => 'assay_id'
);

Chado::Assay->has_many(
    'assayprop_assay_id', 'Chado::Assayprop' => 'assay_id'
);

sub studys { my $self = shift; return map $_->study_id, $self->study_assay_assay_id }

Chado::Assay->has_many(
    'control_assay_id', 'Chado::Control' => 'assay_id'
);

# -------------------------------------------------------------------
package Chado::Assayprop;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Assayprop->set_up_table('assayprop');


Chado::Assayprop->has_a(
    assay_id => 'Chado::Assay'
);

sub Chado::Assayprop::assay {
    return shift->assay_id
}

Chado::Assayprop->has_a(
    type_id => 'Chado::Cvterm'
);

sub Chado::Assayprop::type {
    return shift->type_id
}

# -------------------------------------------------------------------
package Chado::Assay_Project;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Assay_Project->set_up_table('assay_project');


Chado::Assay_Project->has_a(
    assay_id => 'Chado::Assay'
);

sub Chado::Assay_Project::assay {
    return shift->assay_id
}

Chado::Assay_Project->has_a(
    project_id => 'Chado::Project'
);

sub Chado::Assay_Project::project {
    return shift->project_id
}

# -------------------------------------------------------------------
package Chado::Biomaterial;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Biomaterial->set_up_table('biomaterial');


Chado::Biomaterial->has_a(
    taxon_id => 'Chado::Organism'
);

sub Chado::Biomaterial::taxon {
    return shift->taxon_id
}

Chado::Biomaterial->has_a(
    biosourceprovider_id => 'Chado::Contact'
);

sub Chado::Biomaterial::biosourceprovider {
    return shift->biosourceprovider_id
}

Chado::Biomaterial->has_a(
    dbxref_id => 'Chado::Dbxref'
);

sub Chado::Biomaterial::dbxref {
    return shift->dbxref_id
}

sub biomaterial_relationship_subject_ids { my $self = shift; return $self->biomaterial_relationship_subject_id(@_) }

sub biomaterial_relationship_object_ids { my $self = shift; return $self->biomaterial_relationship_object_id(@_) }

Chado::Biomaterial->has_many(
    'treatment_biomaterial_id', 'Chado::Treatment' => 'biomaterial_id'
);

Chado::Biomaterial->has_many(
    'biomaterialprop_biomaterial_id', 'Chado::Biomaterialprop' => 'biomaterial_id'
);

Chado::Biomaterial->has_many(
    'assay_biomaterial_biomaterial_id', 'Chado::Assay_Biomaterial' => 'biomaterial_id'
);

Chado::Biomaterial->has_many(
    'biomaterial_dbxref_biomaterial_id', 'Chado::Biomaterial_Dbxref' => 'biomaterial_id'
);

Chado::Biomaterial->has_many(
    'biomaterial_treatment_biomaterial_id', 'Chado::Biomaterial_Treatment' => 'biomaterial_id'
);

Chado::Biomaterial->has_many(
    'biomaterial_relationship_subject_id', 'Chado::Biomaterial_Relationship' => 'subject_id'
);

Chado::Biomaterial->has_many(
    'biomaterial_relationship_object_id', 'Chado::Biomaterial_Relationship' => 'object_id'
);

sub dbxrefs { my $self = shift; return map $_->dbxref_id, $self->biomaterial_dbxref_biomaterial_id }

# -------------------------------------------------------------------
package Chado::Biomaterial_Relationship;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Biomaterial_Relationship->set_up_table('biomaterial_relationship');


Chado::Biomaterial_Relationship->has_a(
    subject_id => 'Chado::Biomaterial'
);

sub Chado::Biomaterial_Relationship::subject {
    return shift->subject_id
}

Chado::Biomaterial_Relationship->has_a(
    type_id => 'Chado::Cvterm'
);

sub Chado::Biomaterial_Relationship::type {
    return shift->type_id
}

Chado::Biomaterial_Relationship->has_a(
    object_id => 'Chado::Biomaterial'
);

sub Chado::Biomaterial_Relationship::object {
    return shift->object_id
}

# -------------------------------------------------------------------
package Chado::Biomaterialprop;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Biomaterialprop->set_up_table('biomaterialprop');


Chado::Biomaterialprop->has_a(
    biomaterial_id => 'Chado::Biomaterial'
);

sub Chado::Biomaterialprop::biomaterial {
    return shift->biomaterial_id
}

Chado::Biomaterialprop->has_a(
    type_id => 'Chado::Cvterm'
);

sub Chado::Biomaterialprop::type {
    return shift->type_id
}

# -------------------------------------------------------------------
package Chado::Biomaterial_Dbxref;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Biomaterial_Dbxref->set_up_table('biomaterial_dbxref');


Chado::Biomaterial_Dbxref->has_a(
    biomaterial_id => 'Chado::Biomaterial'
);

sub Chado::Biomaterial_Dbxref::biomaterial {
    return shift->biomaterial_id
}

Chado::Biomaterial_Dbxref->has_a(
    dbxref_id => 'Chado::Dbxref'
);

sub Chado::Biomaterial_Dbxref::dbxref {
    return shift->dbxref_id
}

# -------------------------------------------------------------------
package Chado::Treatment;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Treatment->set_up_table('treatment');


Chado::Treatment->has_a(
    biomaterial_id => 'Chado::Biomaterial'
);

sub Chado::Treatment::biomaterial {
    return shift->biomaterial_id
}

Chado::Treatment->has_a(
    type_id => 'Chado::Cvterm'
);

sub Chado::Treatment::type {
    return shift->type_id
}

Chado::Treatment->has_a(
    protocol_id => 'Chado::Protocol'
);

sub Chado::Treatment::protocol {
    return shift->protocol_id
}

Chado::Treatment->has_many(
    'biomaterial_treatment_treatment_id', 'Chado::Biomaterial_Treatment' => 'treatment_id'
);

# -------------------------------------------------------------------
package Chado::Biomaterial_Treatment;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Biomaterial_Treatment->set_up_table('biomaterial_treatment');


Chado::Biomaterial_Treatment->has_a(
    biomaterial_id => 'Chado::Biomaterial'
);

sub Chado::Biomaterial_Treatment::biomaterial {
    return shift->biomaterial_id
}

Chado::Biomaterial_Treatment->has_a(
    treatment_id => 'Chado::Treatment'
);

sub Chado::Biomaterial_Treatment::treatment {
    return shift->treatment_id
}

Chado::Biomaterial_Treatment->has_a(
    unittype_id => 'Chado::Cvterm'
);

sub Chado::Biomaterial_Treatment::unittype {
    return shift->unittype_id
}

# -------------------------------------------------------------------
package Chado::Assay_Biomaterial;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Assay_Biomaterial->set_up_table('assay_biomaterial');


Chado::Assay_Biomaterial->has_a(
    assay_id => 'Chado::Assay'
);

sub Chado::Assay_Biomaterial::assay {
    return shift->assay_id
}

Chado::Assay_Biomaterial->has_a(
    biomaterial_id => 'Chado::Biomaterial'
);

sub Chado::Assay_Biomaterial::biomaterial {
    return shift->biomaterial_id
}

Chado::Assay_Biomaterial->has_a(
    channel_id => 'Chado::Channel'
);

sub Chado::Assay_Biomaterial::channel {
    return shift->channel_id
}

# -------------------------------------------------------------------
package Chado::Acquisition;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Acquisition->set_up_table('acquisition');


Chado::Acquisition->has_a(
    assay_id => 'Chado::Assay'
);

sub Chado::Acquisition::assay {
    return shift->assay_id
}

Chado::Acquisition->has_a(
    protocol_id => 'Chado::Protocol'
);

sub Chado::Acquisition::protocol {
    return shift->protocol_id
}

Chado::Acquisition->has_a(
    channel_id => 'Chado::Channel'
);

sub Chado::Acquisition::channel {
    return shift->channel_id
}

Chado::Acquisition->has_many(
    'acquisition_relationship_subject_id', 'Chado::Acquisition_Relationship' => 'subject_id'
);

Chado::Acquisition->has_many(
    'acquisition_relationship_object_id', 'Chado::Acquisition_Relationship' => 'object_id'
);

Chado::Acquisition->has_many(
    'acquisitionprop_acquisition_id', 'Chado::Acquisitionprop' => 'acquisition_id'
);

Chado::Acquisition->has_many(
    'quantification_acquisition_id', 'Chado::Quantification' => 'acquisition_id'
);

# -------------------------------------------------------------------
package Chado::Acquisitionprop;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Acquisitionprop->set_up_table('acquisitionprop');


Chado::Acquisitionprop->has_a(
    acquisition_id => 'Chado::Acquisition'
);

sub Chado::Acquisitionprop::acquisition {
    return shift->acquisition_id
}

Chado::Acquisitionprop->has_a(
    type_id => 'Chado::Cvterm'
);

sub Chado::Acquisitionprop::type {
    return shift->type_id
}

# -------------------------------------------------------------------
package Chado::Acquisition_Relationship;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Acquisition_Relationship->set_up_table('acquisition_relationship');


Chado::Acquisition_Relationship->has_a(
    subject_id => 'Chado::Acquisition'
);

sub Chado::Acquisition_Relationship::subject {
    return shift->subject_id
}

Chado::Acquisition_Relationship->has_a(
    type_id => 'Chado::Cvterm'
);

sub Chado::Acquisition_Relationship::type {
    return shift->type_id
}

Chado::Acquisition_Relationship->has_a(
    object_id => 'Chado::Acquisition'
);

sub Chado::Acquisition_Relationship::object {
    return shift->object_id
}

# -------------------------------------------------------------------
package Chado::Quantification;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Quantification->set_up_table('quantification');


Chado::Quantification->has_a(
    acquisition_id => 'Chado::Acquisition'
);

sub Chado::Quantification::acquisition {
    return shift->acquisition_id
}

Chado::Quantification->has_a(
    operator_id => 'Chado::Contact'
);

sub Chado::Quantification::operator {
    return shift->operator_id
}

Chado::Quantification->has_a(
    protocol_id => 'Chado::Protocol'
);

sub Chado::Quantification::protocol {
    return shift->protocol_id
}

Chado::Quantification->has_a(
    analysis_id => 'Chado::Analysis'
);

sub Chado::Quantification::analysis {
    return shift->analysis_id
}

Chado::Quantification->has_many(
    'elementresult_quantification_id', 'Chado::Elementresult' => 'quantification_id'
);

Chado::Quantification->has_many(
    'quantificationprop_quantification_id', 'Chado::Quantificationprop' => 'quantification_id'
);

Chado::Quantification->has_many(
    'quantification_relationship_subject_id', 'Chado::Quantification_Relationship' => 'subject_id'
);

Chado::Quantification->has_many(
    'quantification_relationship_object_id', 'Chado::Quantification_Relationship' => 'object_id'
);

sub quantification_relationship_subject_ids { my $self = shift; return $self->quantification_relationship_subject_id(@_) }

sub quantification_relationship_object_ids { my $self = shift; return $self->quantification_relationship_object_id(@_) }

# -------------------------------------------------------------------
package Chado::Quantificationprop;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Quantificationprop->set_up_table('quantificationprop');


Chado::Quantificationprop->has_a(
    quantification_id => 'Chado::Quantification'
);

sub Chado::Quantificationprop::quantification {
    return shift->quantification_id
}

Chado::Quantificationprop->has_a(
    type_id => 'Chado::Cvterm'
);

sub Chado::Quantificationprop::type {
    return shift->type_id
}

# -------------------------------------------------------------------
package Chado::Quantification_Relationship;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Quantification_Relationship->set_up_table('quantification_relationship');


Chado::Quantification_Relationship->has_a(
    subject_id => 'Chado::Quantification'
);

sub Chado::Quantification_Relationship::subject {
    return shift->subject_id
}

Chado::Quantification_Relationship->has_a(
    type_id => 'Chado::Cvterm'
);

sub Chado::Quantification_Relationship::type {
    return shift->type_id
}

Chado::Quantification_Relationship->has_a(
    object_id => 'Chado::Quantification'
);

sub Chado::Quantification_Relationship::object {
    return shift->object_id
}

# -------------------------------------------------------------------
package Chado::Control;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Control->set_up_table('control');


Chado::Control->has_a(
    type_id => 'Chado::Cvterm'
);

sub Chado::Control::type {
    return shift->type_id
}

Chado::Control->has_a(
    assay_id => 'Chado::Assay'
);

sub Chado::Control::assay {
    return shift->assay_id
}

Chado::Control->has_a(
    tableinfo_id => 'Chado::Tableinfo'
);

sub Chado::Control::tableinfo {
    return shift->tableinfo_id
}

# -------------------------------------------------------------------
package Chado::Element;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Element->set_up_table('element');


Chado::Element->has_a(
    feature_id => 'Chado::Feature'
);

sub Chado::Element::feature {
    return shift->feature_id
}

Chado::Element->has_a(
    arraydesign_id => 'Chado::Arraydesign'
);

sub Chado::Element::arraydesign {
    return shift->arraydesign_id
}

Chado::Element->has_a(
    type_id => 'Chado::Cvterm'
);

sub Chado::Element::type {
    return shift->type_id
}

Chado::Element->has_a(
    dbxref_id => 'Chado::Dbxref'
);

sub Chado::Element::dbxref {
    return shift->dbxref_id
}

Chado::Element->has_many(
    'elementresult_element_id', 'Chado::Elementresult' => 'element_id'
);

Chado::Element->has_many(
    'element_relationship_subject_id', 'Chado::Element_Relationship' => 'subject_id'
);

Chado::Element->has_many(
    'element_relationship_object_id', 'Chado::Element_Relationship' => 'object_id'
);

# -------------------------------------------------------------------
package Chado::Elementresult;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Elementresult->set_up_table('elementresult');


Chado::Elementresult->has_a(
    element_id => 'Chado::Element'
);

sub Chado::Elementresult::element {
    return shift->element_id
}

Chado::Elementresult->has_a(
    quantification_id => 'Chado::Quantification'
);

sub Chado::Elementresult::quantification {
    return shift->quantification_id
}

Chado::Elementresult->has_many(
    'elementresult_relationship_subject_id', 'Chado::Elementresult_Relationship' => 'subject_id'
);

Chado::Elementresult->has_many(
    'elementresult_relationship_object_id', 'Chado::Elementresult_Relationship' => 'object_id'
);

# -------------------------------------------------------------------
package Chado::Element_Relationship;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Element_Relationship->set_up_table('element_relationship');


Chado::Element_Relationship->has_a(
    subject_id => 'Chado::Element'
);

sub Chado::Element_Relationship::subject {
    return shift->subject_id
}

Chado::Element_Relationship->has_a(
    type_id => 'Chado::Cvterm'
);

sub Chado::Element_Relationship::type {
    return shift->type_id
}

Chado::Element_Relationship->has_a(
    object_id => 'Chado::Element'
);

sub Chado::Element_Relationship::object {
    return shift->object_id
}

# -------------------------------------------------------------------
package Chado::Elementresult_Relationship;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Elementresult_Relationship->set_up_table('elementresult_relationship');


Chado::Elementresult_Relationship->has_a(
    subject_id => 'Chado::Elementresult'
);

sub Chado::Elementresult_Relationship::subject {
    return shift->subject_id
}

Chado::Elementresult_Relationship->has_a(
    type_id => 'Chado::Cvterm'
);

sub Chado::Elementresult_Relationship::type {
    return shift->type_id
}

Chado::Elementresult_Relationship->has_a(
    object_id => 'Chado::Elementresult'
);

sub Chado::Elementresult_Relationship::object {
    return shift->object_id
}

# -------------------------------------------------------------------
package Chado::Study;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Study->set_up_table('study');


Chado::Study->has_a(
    contact_id => 'Chado::Contact'
);

sub Chado::Study::contact {
    return shift->contact_id
}

Chado::Study->has_a(
    pub_id => 'Chado::Pub'
);

sub Chado::Study::pub {
    return shift->pub_id
}

Chado::Study->has_a(
    dbxref_id => 'Chado::Dbxref'
);

sub Chado::Study::dbxref {
    return shift->dbxref_id
}

Chado::Study->has_many(
    'studydesign_study_id', 'Chado::Studydesign' => 'study_id'
);

sub assays { my $self = shift; return map $_->assay_id, $self->study_assay_study_id }

Chado::Study->has_many(
    'study_assay_study_id', 'Chado::Study_Assay' => 'study_id'
);

# -------------------------------------------------------------------
package Chado::Study_Assay;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Study_Assay->set_up_table('study_assay');


Chado::Study_Assay->has_a(
    study_id => 'Chado::Study'
);

sub Chado::Study_Assay::study {
    return shift->study_id
}

Chado::Study_Assay->has_a(
    assay_id => 'Chado::Assay'
);

sub Chado::Study_Assay::assay {
    return shift->assay_id
}

# -------------------------------------------------------------------
package Chado::Studydesign;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Studydesign->set_up_table('studydesign');


Chado::Studydesign->has_a(
    study_id => 'Chado::Study'
);

sub Chado::Studydesign::study {
    return shift->study_id
}

Chado::Studydesign->has_many(
    'studydesignprop_studydesign_id', 'Chado::Studydesignprop' => 'studydesign_id'
);

Chado::Studydesign->has_many(
    'studyfactor_studydesign_id', 'Chado::Studyfactor' => 'studydesign_id'
);

# -------------------------------------------------------------------
package Chado::Studydesignprop;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Studydesignprop->set_up_table('studydesignprop');


Chado::Studydesignprop->has_a(
    studydesign_id => 'Chado::Studydesign'
);

sub Chado::Studydesignprop::studydesign {
    return shift->studydesign_id
}

Chado::Studydesignprop->has_a(
    type_id => 'Chado::Cvterm'
);

sub Chado::Studydesignprop::type {
    return shift->type_id
}

# -------------------------------------------------------------------
package Chado::Studyfactor;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Studyfactor->set_up_table('studyfactor');


Chado::Studyfactor->has_a(
    studydesign_id => 'Chado::Studydesign'
);

sub Chado::Studyfactor::studydesign {
    return shift->studydesign_id
}

Chado::Studyfactor->has_a(
    type_id => 'Chado::Cvterm'
);

sub Chado::Studyfactor::type {
    return shift->type_id
}

Chado::Studyfactor->has_many(
    'studyfactorvalue_studyfactor_id', 'Chado::Studyfactorvalue' => 'studyfactor_id'
);

# -------------------------------------------------------------------
package Chado::Studyfactorvalue;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::Studyfactorvalue->set_up_table('studyfactorvalue');


Chado::Studyfactorvalue->has_a(
    studyfactor_id => 'Chado::Studyfactor'
);

sub Chado::Studyfactorvalue::studyfactor {
    return shift->studyfactor_id
}

Chado::Studyfactorvalue->has_a(
    assay_id => 'Chado::Assay'
);

sub Chado::Studyfactorvalue::assay {
    return shift->assay_id
}

1;
!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
