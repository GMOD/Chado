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
package Chado::DBI::Chado::Tableinfo;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Tableinfo->set_up_table('tableinfo');


Chado::DBI::Chado::Tableinfo->has_many(
    'magedocumentation_tableinfo_id', 'Chado::DBI::Chado::Magedocumentation' => 'tableinfo_id'
);

Chado::DBI::Chado::Tableinfo->has_many(
    'control_tableinfo_id', 'Chado::DBI::Chado::Control' => 'tableinfo_id'
);

# -------------------------------------------------------------------
package Chado::DBI::Chado::Db;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Db->set_up_table('db');


Chado::DBI::Chado::Db->has_many(
    'dbxref_db_id', 'Chado::DBI::Chado::Dbxref' => 'db_id'
);

# -------------------------------------------------------------------
package Chado::DBI::Chado::Dbxref;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Dbxref->set_up_table('dbxref');


Chado::DBI::Chado::Dbxref->has_a(
    db_id => 'Chado::DBI::Chado::Db'
);

sub Chado::DBI::Chado::Dbxref::db {
    return shift->db_id
}

Chado::DBI::Chado::Dbxref->has_many(
    'protocol_dbxref_id', 'Chado::DBI::Chado::Protocol' => 'dbxref_id'
);

Chado::DBI::Chado::Dbxref->has_many(
    'assay_dbxref_id', 'Chado::DBI::Chado::Assay' => 'dbxref_id'
);

Chado::DBI::Chado::Dbxref->has_many(
    'feature_dbxref_dbxref_id', 'Chado::DBI::Chado::Feature_Dbxref' => 'dbxref_id'
);

Chado::DBI::Chado::Dbxref->has_many(
    'biomaterial_dbxref_dbxref_id', 'Chado::DBI::Chado::Biomaterial_Dbxref' => 'dbxref_id'
);

sub phylonodes { my $self = shift; return map $_->phylonode_id, $self->phylonode_dbxref_dbxref_id }

sub features { my $self = shift; return map $_->feature_id, $self->element_dbxref_id }

Chado::DBI::Chado::Dbxref->has_many(
    'feature_dbxref_id', 'Chado::DBI::Chado::Feature' => 'dbxref_id'
);

Chado::DBI::Chado::Dbxref->has_many(
    'organism_dbxref_dbxref_id', 'Chado::DBI::Chado::Organism_Dbxref' => 'dbxref_id'
);

sub feature_cvterms { my $self = shift; return map $_->feature_cvterm_id, $self->feature_cvterm_dbxref_dbxref_id }

sub arraydesigns { my $self = shift; return map $_->arraydesign_id, $self->element_dbxref_id }

Chado::DBI::Chado::Dbxref->has_many(
    'arraydesign_dbxref_id', 'Chado::DBI::Chado::Arraydesign' => 'dbxref_id'
);

Chado::DBI::Chado::Dbxref->has_many(
    'study_dbxref_id', 'Chado::DBI::Chado::Study' => 'dbxref_id'
);

sub organisms { my $self = shift; return map $_->organism_id, $self->organism_dbxref_dbxref_id }

Chado::DBI::Chado::Dbxref->has_many(
    'dbxrefprop_dbxref_id', 'Chado::DBI::Chado::Dbxrefprop' => 'dbxref_id'
);

Chado::DBI::Chado::Dbxref->has_many(
    'cvterm_dbxref_dbxref_id', 'Chado::DBI::Chado::Cvterm_Dbxref' => 'dbxref_id'
);

Chado::DBI::Chado::Dbxref->has_many(
    'feature_cvterm_dbxref_dbxref_id', 'Chado::DBI::Chado::Feature_Cvterm_Dbxref' => 'dbxref_id'
);

Chado::DBI::Chado::Dbxref->has_many(
    'element_dbxref_id', 'Chado::DBI::Chado::Element' => 'dbxref_id'
);

sub cvterms { my $self = shift; return map $_->cvterm_id, $self->element_dbxref_id }

Chado::DBI::Chado::Dbxref->has_many(
    'cvterm_dbxref_id', 'Chado::DBI::Chado::Cvterm' => 'dbxref_id'
);

sub biomaterials { my $self = shift; return map $_->biomaterial_id, $self->biomaterial_dbxref_dbxref_id }

Chado::DBI::Chado::Dbxref->has_many(
    'biomaterial_dbxref_id', 'Chado::DBI::Chado::Biomaterial' => 'dbxref_id'
);

Chado::DBI::Chado::Dbxref->has_many(
    'pub_dbxref_dbxref_id', 'Chado::DBI::Chado::Pub_Dbxref' => 'dbxref_id'
);

Chado::DBI::Chado::Dbxref->has_many(
    'phylonode_dbxref_dbxref_id', 'Chado::DBI::Chado::Phylonode_Dbxref' => 'dbxref_id'
);

Chado::DBI::Chado::Dbxref->has_many(
    'phylotree_dbxref_id', 'Chado::DBI::Chado::Phylotree' => 'dbxref_id'
);

# -------------------------------------------------------------------
package Chado::DBI::Chado::Project;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Project->set_up_table('project');


Chado::DBI::Chado::Project->has_many(
    'assay_project_project_id', 'Chado::DBI::Chado::Assay_Project' => 'project_id'
);

sub assays { my $self = shift; return map $_->assay_id, $self->assay_project_project_id }

# -------------------------------------------------------------------
package Chado::DBI::Chado::Cv;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Cv->set_up_table('cv');


Chado::DBI::Chado::Cv->has_many(
    'cvtermpath_cv_id', 'Chado::DBI::Chado::Cvtermpath' => 'cv_id'
);

Chado::DBI::Chado::Cv->has_many(
    'cvterm_cv_id', 'Chado::DBI::Chado::Cvterm' => 'cv_id'
);

# -------------------------------------------------------------------
package Chado::DBI::Chado::Cvterm;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Cvterm->set_up_table('cvterm');


Chado::DBI::Chado::Cvterm->has_a(
    cv_id => 'Chado::DBI::Chado::Cv'
);

sub Chado::DBI::Chado::Cvterm::cv {
    return shift->cv_id
}

Chado::DBI::Chado::Cvterm->has_a(
    dbxref_id => 'Chado::DBI::Chado::Dbxref'
);

sub Chado::DBI::Chado::Cvterm::dbxref {
    return shift->dbxref_id
}

Chado::DBI::Chado::Cvterm->has_many(
    'protocol_type_id', 'Chado::DBI::Chado::Protocol' => 'type_id'
);

Chado::DBI::Chado::Cvterm->has_many(
    'elementresult_relationship_type_id', 'Chado::DBI::Chado::Elementresult_Relationship' => 'type_id'
);

Chado::DBI::Chado::Cvterm->has_many(
    'studyfactor_type_id', 'Chado::DBI::Chado::Studyfactor' => 'type_id'
);

Chado::DBI::Chado::Cvterm->has_many(
    'phylonode_type_id', 'Chado::DBI::Chado::Phylonode' => 'type_id'
);

Chado::DBI::Chado::Cvterm->has_many(
    'cvtermsynonym_cvterm_id', 'Chado::DBI::Chado::Cvtermsynonym' => 'cvterm_id'
);

Chado::DBI::Chado::Cvterm->has_many(
    'cvtermsynonym_type_id', 'Chado::DBI::Chado::Cvtermsynonym' => 'type_id'
);

sub quantification_relationships { my $self = shift; return $self->quantification_relationship_type_id(@_) }

sub features { my $self = shift; return map $_->feature_id, $self->element_type_id }

Chado::DBI::Chado::Cvterm->has_many(
    'feature_type_id', 'Chado::DBI::Chado::Feature' => 'type_id'
);

Chado::DBI::Chado::Cvterm->has_many(
    'biomaterialprop_type_id', 'Chado::DBI::Chado::Biomaterialprop' => 'type_id'
);

Chado::DBI::Chado::Cvterm->has_many(
    'feature_cvterm_cvterm_id', 'Chado::DBI::Chado::Feature_Cvterm' => 'cvterm_id'
);

Chado::DBI::Chado::Cvterm->has_many(
    'phylonodeprop_type_id', 'Chado::DBI::Chado::Phylonodeprop' => 'type_id'
);

sub arraydesigns { my $self = shift; return map $_->arraydesign_id, $self->element_type_id }

Chado::DBI::Chado::Cvterm->has_many(
    'arraydesign_platformtype_id', 'Chado::DBI::Chado::Arraydesign' => 'platformtype_id'
);

Chado::DBI::Chado::Cvterm->has_many(
    'arraydesign_substratetype_id', 'Chado::DBI::Chado::Arraydesign' => 'substratetype_id'
);

Chado::DBI::Chado::Cvterm->has_many(
    'biomaterial_relationship_type_id', 'Chado::DBI::Chado::Biomaterial_Relationship' => 'type_id'
);

Chado::DBI::Chado::Cvterm->has_many(
    'analysisprop_type_id', 'Chado::DBI::Chado::Analysisprop' => 'type_id'
);

Chado::DBI::Chado::Cvterm->has_many(
    'cvterm_dbxref_cvterm_id', 'Chado::DBI::Chado::Cvterm_Dbxref' => 'cvterm_id'
);

Chado::DBI::Chado::Cvterm->has_many(
    'feature_relationshipprop_type_id', 'Chado::DBI::Chado::Feature_Relationshipprop' => 'type_id'
);

Chado::DBI::Chado::Cvterm->has_many(
    'cvtermprop_cvterm_id', 'Chado::DBI::Chado::Cvtermprop' => 'cvterm_id'
);

Chado::DBI::Chado::Cvterm->has_many(
    'cvtermprop_type_id', 'Chado::DBI::Chado::Cvtermprop' => 'type_id'
);

Chado::DBI::Chado::Cvterm->has_many(
    'element_relationship_type_id', 'Chado::DBI::Chado::Element_Relationship' => 'type_id'
);

Chado::DBI::Chado::Cvterm->has_many(
    'quantification_relationship_type_id', 'Chado::DBI::Chado::Quantification_Relationship' => 'type_id'
);

Chado::DBI::Chado::Cvterm->has_many(
    'element_type_id', 'Chado::DBI::Chado::Element' => 'type_id'
);

Chado::DBI::Chado::Cvterm->has_many(
    'featuremap_unittype_id', 'Chado::DBI::Chado::Featuremap' => 'unittype_id'
);

Chado::DBI::Chado::Cvterm->has_many(
    'treatment_type_id', 'Chado::DBI::Chado::Treatment' => 'type_id'
);

Chado::DBI::Chado::Cvterm->has_many(
    'arraydesignprop_type_id', 'Chado::DBI::Chado::Arraydesignprop' => 'type_id'
);

Chado::DBI::Chado::Cvterm->has_many(
    'synonym_type_id', 'Chado::DBI::Chado::Synonym' => 'type_id'
);

Chado::DBI::Chado::Cvterm->has_many(
    'pubprop_type_id', 'Chado::DBI::Chado::Pubprop' => 'type_id'
);

Chado::DBI::Chado::Cvterm->has_many(
    'cvtermpath_type_id', 'Chado::DBI::Chado::Cvtermpath' => 'type_id'
);

Chado::DBI::Chado::Cvterm->has_many(
    'cvtermpath_subject_id', 'Chado::DBI::Chado::Cvtermpath' => 'subject_id'
);

Chado::DBI::Chado::Cvterm->has_many(
    'cvtermpath_object_id', 'Chado::DBI::Chado::Cvtermpath' => 'object_id'
);

Chado::DBI::Chado::Cvterm->has_many(
    'quantificationprop_type_id', 'Chado::DBI::Chado::Quantificationprop' => 'type_id'
);

Chado::DBI::Chado::Cvterm->has_many(
    'biomaterial_treatment_unittype_id', 'Chado::DBI::Chado::Biomaterial_Treatment' => 'unittype_id'
);

Chado::DBI::Chado::Cvterm->has_many(
    'expression_cvterm_cvterm_id', 'Chado::DBI::Chado::Expression_Cvterm' => 'cvterm_id'
);

Chado::DBI::Chado::Cvterm->has_many(
    'cvterm_relationship_type_id', 'Chado::DBI::Chado::Cvterm_Relationship' => 'type_id'
);

Chado::DBI::Chado::Cvterm->has_many(
    'cvterm_relationship_subject_id', 'Chado::DBI::Chado::Cvterm_Relationship' => 'subject_id'
);

Chado::DBI::Chado::Cvterm->has_many(
    'cvterm_relationship_object_id', 'Chado::DBI::Chado::Cvterm_Relationship' => 'object_id'
);

Chado::DBI::Chado::Cvterm->has_many(
    'acquisitionprop_type_id', 'Chado::DBI::Chado::Acquisitionprop' => 'type_id'
);

Chado::DBI::Chado::Cvterm->has_many(
    'studydesignprop_type_id', 'Chado::DBI::Chado::Studydesignprop' => 'type_id'
);

sub contact_relationships { my $self = shift; return $self->contact_relationship_type_id(@_) }

Chado::DBI::Chado::Cvterm->has_many(
    'contact_type_id', 'Chado::DBI::Chado::Contact' => 'type_id'
);

sub phenotype_comparisons { my $self = shift; return $self->phenotype_comparison_type_id(@_) }

Chado::DBI::Chado::Cvterm->has_many(
    'featureprop_type_id', 'Chado::DBI::Chado::Featureprop' => 'type_id'
);

Chado::DBI::Chado::Cvterm->has_many(
    'phylonode_relationship_type_id', 'Chado::DBI::Chado::Phylonode_Relationship' => 'type_id'
);

sub dbxrefs { my $self = shift; return map $_->dbxref_id, $self->element_type_id }

Chado::DBI::Chado::Cvterm->has_many(
    'assayprop_type_id', 'Chado::DBI::Chado::Assayprop' => 'type_id'
);

Chado::DBI::Chado::Cvterm->has_many(
    'environment_cvterm_cvterm_id', 'Chado::DBI::Chado::Environment_Cvterm' => 'cvterm_id'
);

Chado::DBI::Chado::Cvterm->has_many(
    'contact_relationship_type_id', 'Chado::DBI::Chado::Contact_Relationship' => 'type_id'
);

Chado::DBI::Chado::Cvterm->has_many(
    'protocolparam_datatype_id', 'Chado::DBI::Chado::Protocolparam' => 'datatype_id'
);

Chado::DBI::Chado::Cvterm->has_many(
    'protocolparam_unittype_id', 'Chado::DBI::Chado::Protocolparam' => 'unittype_id'
);

sub pubs { my $self = shift; return map $_->pub_id, $self->phenotype_comparison_type_id }

Chado::DBI::Chado::Cvterm->has_many(
    'pub_type_id', 'Chado::DBI::Chado::Pub' => 'type_id'
);

Chado::DBI::Chado::Cvterm->has_many(
    'control_type_id', 'Chado::DBI::Chado::Control' => 'type_id'
);

Chado::DBI::Chado::Cvterm->has_many(
    'organismprop_type_id', 'Chado::DBI::Chado::Organismprop' => 'type_id'
);

Chado::DBI::Chado::Cvterm->has_many(
    'dbxrefprop_type_id', 'Chado::DBI::Chado::Dbxrefprop' => 'type_id'
);

Chado::DBI::Chado::Cvterm->has_many(
    'phenotype_cvterm_cvterm_id', 'Chado::DBI::Chado::Phenotype_Cvterm' => 'cvterm_id'
);

Chado::DBI::Chado::Cvterm->has_many(
    'feature_genotype_cvterm_id', 'Chado::DBI::Chado::Feature_Genotype' => 'cvterm_id'
);

sub cvterm_relationship_type_ids { my $self = shift; return $self->cvterm_relationship_type_id(@_) }

sub cvterm_relationship_subject_ids { my $self = shift; return $self->cvterm_relationship_subject_id(@_) }

sub cvterm_relationship_object_ids { my $self = shift; return $self->cvterm_relationship_object_id(@_) }

Chado::DBI::Chado::Cvterm->has_many(
    'feature_relationship_type_id', 'Chado::DBI::Chado::Feature_Relationship' => 'type_id'
);

Chado::DBI::Chado::Cvterm->has_many(
    'acquisition_relationship_type_id', 'Chado::DBI::Chado::Acquisition_Relationship' => 'type_id'
);

sub phenotype_comparisons { my $self = shift; return $self->phenotype_comparison_type_id(@_) }

sub biomaterial_relationships { my $self = shift; return $self->biomaterial_relationship_type_id(@_) }

Chado::DBI::Chado::Cvterm->has_many(
    'phenstatement_type_id', 'Chado::DBI::Chado::Phenstatement' => 'type_id'
);

sub phenotype_comparisons { my $self = shift; return $self->phenotype_comparison_type_id(@_) }

Chado::DBI::Chado::Cvterm->has_many(
    'phenotype_observable_id', 'Chado::DBI::Chado::Phenotype' => 'observable_id'
);

Chado::DBI::Chado::Cvterm->has_many(
    'phenotype_attr_id', 'Chado::DBI::Chado::Phenotype' => 'attr_id'
);

Chado::DBI::Chado::Cvterm->has_many(
    'phenotype_cvalue_id', 'Chado::DBI::Chado::Phenotype' => 'cvalue_id'
);

Chado::DBI::Chado::Cvterm->has_many(
    'phenotype_assay_id', 'Chado::DBI::Chado::Phenotype' => 'assay_id'
);

Chado::DBI::Chado::Cvterm->has_many(
    'phylotree_type_id', 'Chado::DBI::Chado::Phylotree' => 'type_id'
);

Chado::DBI::Chado::Cvterm->has_many(
    'pub_relationship_type_id', 'Chado::DBI::Chado::Pub_Relationship' => 'type_id'
);

Chado::DBI::Chado::Cvterm->has_many(
    'feature_cvtermprop_type_id', 'Chado::DBI::Chado::Feature_Cvtermprop' => 'type_id'
);

Chado::DBI::Chado::Cvterm->has_many(
    'phenotype_comparison_type_id', 'Chado::DBI::Chado::Phenotype_Comparison' => 'type_id'
);

# -------------------------------------------------------------------
package Chado::DBI::Chado::Cvterm_Relationship;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Cvterm_Relationship->set_up_table('cvterm_relationship');


Chado::DBI::Chado::Cvterm_Relationship->has_a(
    type_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Cvterm_Relationship::type {
    return shift->type_id
}

Chado::DBI::Chado::Cvterm_Relationship->has_a(
    subject_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Cvterm_Relationship::subject {
    return shift->subject_id
}

Chado::DBI::Chado::Cvterm_Relationship->has_a(
    object_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Cvterm_Relationship::object {
    return shift->object_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Cvtermpath;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Cvtermpath->set_up_table('cvtermpath');


Chado::DBI::Chado::Cvtermpath->has_a(
    type_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Cvtermpath::type {
    return shift->type_id
}

Chado::DBI::Chado::Cvtermpath->has_a(
    subject_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Cvtermpath::subject {
    return shift->subject_id
}

Chado::DBI::Chado::Cvtermpath->has_a(
    object_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Cvtermpath::object {
    return shift->object_id
}

Chado::DBI::Chado::Cvtermpath->has_a(
    cv_id => 'Chado::DBI::Chado::Cv'
);

sub Chado::DBI::Chado::Cvtermpath::cv {
    return shift->cv_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Cvtermsynonym;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Cvtermsynonym->set_up_table('cvtermsynonym');


Chado::DBI::Chado::Cvtermsynonym->has_a(
    cvterm_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Cvtermsynonym::cvterm {
    return shift->cvterm_id
}

Chado::DBI::Chado::Cvtermsynonym->has_a(
    type_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Cvtermsynonym::type {
    return shift->type_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Cvterm_Dbxref;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Cvterm_Dbxref->set_up_table('cvterm_dbxref');


Chado::DBI::Chado::Cvterm_Dbxref->has_a(
    cvterm_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Cvterm_Dbxref::cvterm {
    return shift->cvterm_id
}

Chado::DBI::Chado::Cvterm_Dbxref->has_a(
    dbxref_id => 'Chado::DBI::Chado::Dbxref'
);

sub Chado::DBI::Chado::Cvterm_Dbxref::dbxref {
    return shift->dbxref_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Cvtermprop;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Cvtermprop->set_up_table('cvtermprop');


Chado::DBI::Chado::Cvtermprop->has_a(
    cvterm_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Cvtermprop::cvterm {
    return shift->cvterm_id
}

Chado::DBI::Chado::Cvtermprop->has_a(
    type_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Cvtermprop::type {
    return shift->type_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Dbxrefprop;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Dbxrefprop->set_up_table('dbxrefprop');


Chado::DBI::Chado::Dbxrefprop->has_a(
    dbxref_id => 'Chado::DBI::Chado::Dbxref'
);

sub Chado::DBI::Chado::Dbxrefprop::dbxref {
    return shift->dbxref_id
}

Chado::DBI::Chado::Dbxrefprop->has_a(
    type_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Dbxrefprop::type {
    return shift->type_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Organism;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Organism->set_up_table('organism');


Chado::DBI::Chado::Organism->has_many(
    'biomaterial_taxon_id', 'Chado::DBI::Chado::Biomaterial' => 'taxon_id'
);

Chado::DBI::Chado::Organism->has_many(
    'feature_organism_id', 'Chado::DBI::Chado::Feature' => 'organism_id'
);

Chado::DBI::Chado::Organism->has_many(
    'organism_dbxref_organism_id', 'Chado::DBI::Chado::Organism_Dbxref' => 'organism_id'
);

Chado::DBI::Chado::Organism->has_many(
    'phylonode_organism_organism_id', 'Chado::DBI::Chado::Phylonode_Organism' => 'organism_id'
);

sub phylonodes { my $self = shift; return map $_->phylonode_id, $self->phylonode_organism_organism_id }

Chado::DBI::Chado::Organism->has_many(
    'organismprop_organism_id', 'Chado::DBI::Chado::Organismprop' => 'organism_id'
);

sub dbxrefs { my $self = shift; return map $_->dbxref_id, $self->organism_dbxref_organism_id }

# -------------------------------------------------------------------
package Chado::DBI::Chado::Organism_Dbxref;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Organism_Dbxref->set_up_table('organism_dbxref');


Chado::DBI::Chado::Organism_Dbxref->has_a(
    organism_id => 'Chado::DBI::Chado::Organism'
);

sub Chado::DBI::Chado::Organism_Dbxref::organism {
    return shift->organism_id
}

Chado::DBI::Chado::Organism_Dbxref->has_a(
    dbxref_id => 'Chado::DBI::Chado::Dbxref'
);

sub Chado::DBI::Chado::Organism_Dbxref::dbxref {
    return shift->dbxref_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Organismprop;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Organismprop->set_up_table('organismprop');


Chado::DBI::Chado::Organismprop->has_a(
    organism_id => 'Chado::DBI::Chado::Organism'
);

sub Chado::DBI::Chado::Organismprop::organism {
    return shift->organism_id
}

Chado::DBI::Chado::Organismprop->has_a(
    type_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Organismprop::type {
    return shift->type_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Pub;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Pub->set_up_table('pub');


Chado::DBI::Chado::Pub->has_a(
    type_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Pub::type {
    return shift->type_id
}

Chado::DBI::Chado::Pub->has_many(
    'protocol_pub_id', 'Chado::DBI::Chado::Protocol' => 'pub_id'
);

Chado::DBI::Chado::Pub->has_many(
    'expression_pub_pub_id', 'Chado::DBI::Chado::Expression_Pub' => 'pub_id'
);

Chado::DBI::Chado::Pub->has_many(
    'featureloc_pub_pub_id', 'Chado::DBI::Chado::Featureloc_Pub' => 'pub_id'
);

sub phylonodes { my $self = shift; return map $_->phylonode_id, $self->phylonode_pub_pub_id }

sub features { my $self = shift; return map $_->feature_id, $self->feature_pub_pub_id }

sub feature_cvterms { my $self = shift; return map $_->feature_cvterm_id, $self->feature_cvterm_pub_pub_id }

Chado::DBI::Chado::Pub->has_many(
    'feature_cvterm_pub_id', 'Chado::DBI::Chado::Feature_Cvterm' => 'pub_id'
);

sub expressions { my $self = shift; return map $_->expression_id, $self->expression_pub_pub_id }

Chado::DBI::Chado::Pub->has_many(
    'study_pub_id', 'Chado::DBI::Chado::Study' => 'pub_id'
);

Chado::DBI::Chado::Pub->has_many(
    'feature_relationship_pub_pub_id', 'Chado::DBI::Chado::Feature_Relationship_Pub' => 'pub_id'
);

sub feature_relationshipprops { my $self = shift; return map $_->feature_relationshipprop_id, $self->feature_relationshipprop_pub_pub_id }

sub featuremaps { my $self = shift; return map $_->featuremap_id, $self->featuremap_pub_pub_id }

Chado::DBI::Chado::Pub->has_many(
    'pubprop_pub_id', 'Chado::DBI::Chado::Pubprop' => 'pub_id'
);

Chado::DBI::Chado::Pub->has_many(
    'feature_cvterm_pub_pub_id', 'Chado::DBI::Chado::Feature_Cvterm_Pub' => 'pub_id'
);

Chado::DBI::Chado::Pub->has_many(
    'phylonode_pub_pub_id', 'Chado::DBI::Chado::Phylonode_Pub' => 'pub_id'
);

sub phenotype_comparisons { my $self = shift; return $self->phenotype_comparison_pub_id(@_) }

sub featureprops { my $self = shift; return map $_->featureprop_id, $self->featureprop_pub_pub_id }

Chado::DBI::Chado::Pub->has_many(
    'phylotree_pub_pub_id', 'Chado::DBI::Chado::Phylotree_Pub' => 'pub_id'
);

Chado::DBI::Chado::Pub->has_many(
    'pubauthor_pub_id', 'Chado::DBI::Chado::Pubauthor' => 'pub_id'
);

sub pub_relationship_subject_ids { my $self = shift; return $self->pub_relationship_subject_id(@_) }

sub pub_relationship_object_ids { my $self = shift; return $self->pub_relationship_object_id(@_) }

Chado::DBI::Chado::Pub->has_many(
    'feature_synonym_pub_id', 'Chado::DBI::Chado::Feature_Synonym' => 'pub_id'
);

sub featurelocs { my $self = shift; return map $_->featureloc_id, $self->featureloc_pub_pub_id }

Chado::DBI::Chado::Pub->has_many(
    'feature_pub_pub_id', 'Chado::DBI::Chado::Feature_Pub' => 'pub_id'
);

Chado::DBI::Chado::Pub->has_many(
    'featuremap_pub_pub_id', 'Chado::DBI::Chado::Featuremap_Pub' => 'pub_id'
);

sub cvterms { my $self = shift; return map $_->cvterm_id, $self->phenotype_comparison_pub_id }

sub feature_relationships { my $self = shift; return map $_->feature_relationship_id, $self->feature_relationship_pub_pub_id }

Chado::DBI::Chado::Pub->has_many(
    'feature_relationshipprop_pub_pub_id', 'Chado::DBI::Chado::Feature_Relationshipprop_Pub' => 'pub_id'
);

sub phenotype_comparisons { my $self = shift; return $self->phenotype_comparison_pub_id(@_) }

Chado::DBI::Chado::Pub->has_many(
    'phenstatement_pub_id', 'Chado::DBI::Chado::Phenstatement' => 'pub_id'
);

Chado::DBI::Chado::Pub->has_many(
    'pub_dbxref_pub_id', 'Chado::DBI::Chado::Pub_Dbxref' => 'pub_id'
);

sub phenotype_comparisons { my $self = shift; return $self->phenotype_comparison_pub_id(@_) }

Chado::DBI::Chado::Pub->has_many(
    'phendesc_pub_id', 'Chado::DBI::Chado::Phendesc' => 'pub_id'
);

Chado::DBI::Chado::Pub->has_many(
    'featureprop_pub_pub_id', 'Chado::DBI::Chado::Featureprop_Pub' => 'pub_id'
);

sub phylotrees { my $self = shift; return map $_->phylotree_id, $self->phylotree_pub_pub_id }

Chado::DBI::Chado::Pub->has_many(
    'pub_relationship_subject_id', 'Chado::DBI::Chado::Pub_Relationship' => 'subject_id'
);

Chado::DBI::Chado::Pub->has_many(
    'pub_relationship_object_id', 'Chado::DBI::Chado::Pub_Relationship' => 'object_id'
);

Chado::DBI::Chado::Pub->has_many(
    'phenotype_comparison_pub_id', 'Chado::DBI::Chado::Phenotype_Comparison' => 'pub_id'
);

# -------------------------------------------------------------------
package Chado::DBI::Chado::Pub_Relationship;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Pub_Relationship->set_up_table('pub_relationship');


Chado::DBI::Chado::Pub_Relationship->has_a(
    subject_id => 'Chado::DBI::Chado::Pub'
);

sub Chado::DBI::Chado::Pub_Relationship::subject {
    return shift->subject_id
}

Chado::DBI::Chado::Pub_Relationship->has_a(
    object_id => 'Chado::DBI::Chado::Pub'
);

sub Chado::DBI::Chado::Pub_Relationship::object {
    return shift->object_id
}

Chado::DBI::Chado::Pub_Relationship->has_a(
    type_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Pub_Relationship::type {
    return shift->type_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Pub_Dbxref;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Pub_Dbxref->set_up_table('pub_dbxref');


Chado::DBI::Chado::Pub_Dbxref->has_a(
    pub_id => 'Chado::DBI::Chado::Pub'
);

sub Chado::DBI::Chado::Pub_Dbxref::pub {
    return shift->pub_id
}

Chado::DBI::Chado::Pub_Dbxref->has_a(
    dbxref_id => 'Chado::DBI::Chado::Dbxref'
);

sub Chado::DBI::Chado::Pub_Dbxref::dbxref {
    return shift->dbxref_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Pubauthor;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Pubauthor->set_up_table('pubauthor');


Chado::DBI::Chado::Pubauthor->has_a(
    pub_id => 'Chado::DBI::Chado::Pub'
);

sub Chado::DBI::Chado::Pubauthor::pub {
    return shift->pub_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Pubprop;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Pubprop->set_up_table('pubprop');


Chado::DBI::Chado::Pubprop->has_a(
    pub_id => 'Chado::DBI::Chado::Pub'
);

sub Chado::DBI::Chado::Pubprop::pub {
    return shift->pub_id
}

Chado::DBI::Chado::Pubprop->has_a(
    type_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Pubprop::type {
    return shift->type_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Feature;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Feature->set_up_table('feature');


Chado::DBI::Chado::Feature->has_a(
    dbxref_id => 'Chado::DBI::Chado::Dbxref'
);

sub Chado::DBI::Chado::Feature::dbxref {
    return shift->dbxref_id
}

Chado::DBI::Chado::Feature->has_a(
    organism_id => 'Chado::DBI::Chado::Organism'
);

sub Chado::DBI::Chado::Feature::organism {
    return shift->organism_id
}

Chado::DBI::Chado::Feature->has_a(
    type_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Feature::type {
    return shift->type_id
}

Chado::DBI::Chado::Feature->has_many(
    'feature_dbxref_feature_id', 'Chado::DBI::Chado::Feature_Dbxref' => 'feature_id'
);

Chado::DBI::Chado::Feature->has_many(
    'phylonode_feature_id', 'Chado::DBI::Chado::Phylonode' => 'feature_id'
);

Chado::DBI::Chado::Feature->has_many(
    'featureprop_feature_id', 'Chado::DBI::Chado::Featureprop' => 'feature_id'
);

sub dbxrefs { my $self = shift; return map $_->dbxref_id, $self->element_feature_id }

Chado::DBI::Chado::Feature->has_many(
    'feature_expression_feature_id', 'Chado::DBI::Chado::Feature_Expression' => 'feature_id'
);

Chado::DBI::Chado::Feature->has_many(
    'feature_cvterm_feature_id', 'Chado::DBI::Chado::Feature_Cvterm' => 'feature_id'
);

sub expressions { my $self = shift; return map $_->expression_id, $self->feature_expression_feature_id }

sub arraydesigns { my $self = shift; return map $_->arraydesign_id, $self->element_feature_id }

Chado::DBI::Chado::Feature->has_many(
    'feature_synonym_feature_id', 'Chado::DBI::Chado::Feature_Synonym' => 'feature_id'
);

sub pubs { my $self = shift; return map $_->pub_id, $self->feature_pub_feature_id }

Chado::DBI::Chado::Feature->has_many(
    'featurerange_feature_id', 'Chado::DBI::Chado::Featurerange' => 'feature_id'
);

Chado::DBI::Chado::Feature->has_many(
    'featurerange_leftstartf_id', 'Chado::DBI::Chado::Featurerange' => 'leftstartf_id'
);

Chado::DBI::Chado::Feature->has_many(
    'featurerange_leftendf_id', 'Chado::DBI::Chado::Featurerange' => 'leftendf_id'
);

Chado::DBI::Chado::Feature->has_many(
    'featurerange_rightstartf_id', 'Chado::DBI::Chado::Featurerange' => 'rightstartf_id'
);

Chado::DBI::Chado::Feature->has_many(
    'featurerange_rightendf_id', 'Chado::DBI::Chado::Featurerange' => 'rightendf_id'
);

Chado::DBI::Chado::Feature->has_many(
    'featureloc_feature_id', 'Chado::DBI::Chado::Featureloc' => 'feature_id'
);

Chado::DBI::Chado::Feature->has_many(
    'featureloc_srcfeature_id', 'Chado::DBI::Chado::Featureloc' => 'srcfeature_id'
);

Chado::DBI::Chado::Feature->has_many(
    'feature_pub_feature_id', 'Chado::DBI::Chado::Feature_Pub' => 'feature_id'
);

Chado::DBI::Chado::Feature->has_many(
    'analysisfeature_feature_id', 'Chado::DBI::Chado::Analysisfeature' => 'feature_id'
);

Chado::DBI::Chado::Feature->has_many(
    'feature_phenotype_feature_id', 'Chado::DBI::Chado::Feature_Phenotype' => 'feature_id'
);

Chado::DBI::Chado::Feature->has_many(
    'feature_genotype_feature_id', 'Chado::DBI::Chado::Feature_Genotype' => 'feature_id'
);

Chado::DBI::Chado::Feature->has_many(
    'feature_genotype_chromosome_id', 'Chado::DBI::Chado::Feature_Genotype' => 'chromosome_id'
);

Chado::DBI::Chado::Feature->has_many(
    'element_feature_id', 'Chado::DBI::Chado::Element' => 'feature_id'
);

sub cvterms { my $self = shift; return map $_->cvterm_id, $self->element_feature_id }

Chado::DBI::Chado::Feature->has_many(
    'feature_relationship_subject_id', 'Chado::DBI::Chado::Feature_Relationship' => 'subject_id'
);

Chado::DBI::Chado::Feature->has_many(
    'feature_relationship_object_id', 'Chado::DBI::Chado::Feature_Relationship' => 'object_id'
);

Chado::DBI::Chado::Feature->has_many(
    'featurepos_feature_id', 'Chado::DBI::Chado::Featurepos' => 'feature_id'
);

Chado::DBI::Chado::Feature->has_many(
    'featurepos_map_feature_id', 'Chado::DBI::Chado::Featurepos' => 'map_feature_id'
);

sub phenotypes { my $self = shift; return map $_->phenotype_id, $self->feature_phenotype_feature_id }

# -------------------------------------------------------------------
package Chado::DBI::Chado::Featureloc;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Featureloc->set_up_table('featureloc');


Chado::DBI::Chado::Featureloc->has_a(
    feature_id => 'Chado::DBI::Chado::Feature'
);

sub Chado::DBI::Chado::Featureloc::feature {
    return shift->feature_id
}

Chado::DBI::Chado::Featureloc->has_a(
    srcfeature_id => 'Chado::DBI::Chado::Feature'
);

sub Chado::DBI::Chado::Featureloc::srcfeature {
    return shift->srcfeature_id
}

Chado::DBI::Chado::Featureloc->has_many(
    'featureloc_pub_featureloc_id', 'Chado::DBI::Chado::Featureloc_Pub' => 'featureloc_id'
);

sub pubs { my $self = shift; return map $_->pub_id, $self->featureloc_pub_featureloc_id }

# -------------------------------------------------------------------
package Chado::DBI::Chado::Featureloc_Pub;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Featureloc_Pub->set_up_table('featureloc_pub');


Chado::DBI::Chado::Featureloc_Pub->has_a(
    featureloc_id => 'Chado::DBI::Chado::Featureloc'
);

sub Chado::DBI::Chado::Featureloc_Pub::featureloc {
    return shift->featureloc_id
}

Chado::DBI::Chado::Featureloc_Pub->has_a(
    pub_id => 'Chado::DBI::Chado::Pub'
);

sub Chado::DBI::Chado::Featureloc_Pub::pub {
    return shift->pub_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Feature_Pub;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Feature_Pub->set_up_table('feature_pub');


Chado::DBI::Chado::Feature_Pub->has_a(
    feature_id => 'Chado::DBI::Chado::Feature'
);

sub Chado::DBI::Chado::Feature_Pub::feature {
    return shift->feature_id
}

Chado::DBI::Chado::Feature_Pub->has_a(
    pub_id => 'Chado::DBI::Chado::Pub'
);

sub Chado::DBI::Chado::Feature_Pub::pub {
    return shift->pub_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Featureprop;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Featureprop->set_up_table('featureprop');


Chado::DBI::Chado::Featureprop->has_a(
    feature_id => 'Chado::DBI::Chado::Feature'
);

sub Chado::DBI::Chado::Featureprop::feature {
    return shift->feature_id
}

Chado::DBI::Chado::Featureprop->has_a(
    type_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Featureprop::type {
    return shift->type_id
}

Chado::DBI::Chado::Featureprop->has_many(
    'featureprop_pub_featureprop_id', 'Chado::DBI::Chado::Featureprop_Pub' => 'featureprop_id'
);

sub pubs { my $self = shift; return map $_->pub_id, $self->featureprop_pub_featureprop_id }

# -------------------------------------------------------------------
package Chado::DBI::Chado::Featureprop_Pub;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Featureprop_Pub->set_up_table('featureprop_pub');


Chado::DBI::Chado::Featureprop_Pub->has_a(
    featureprop_id => 'Chado::DBI::Chado::Featureprop'
);

sub Chado::DBI::Chado::Featureprop_Pub::featureprop {
    return shift->featureprop_id
}

Chado::DBI::Chado::Featureprop_Pub->has_a(
    pub_id => 'Chado::DBI::Chado::Pub'
);

sub Chado::DBI::Chado::Featureprop_Pub::pub {
    return shift->pub_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Feature_Dbxref;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Feature_Dbxref->set_up_table('feature_dbxref');


Chado::DBI::Chado::Feature_Dbxref->has_a(
    feature_id => 'Chado::DBI::Chado::Feature'
);

sub Chado::DBI::Chado::Feature_Dbxref::feature {
    return shift->feature_id
}

Chado::DBI::Chado::Feature_Dbxref->has_a(
    dbxref_id => 'Chado::DBI::Chado::Dbxref'
);

sub Chado::DBI::Chado::Feature_Dbxref::dbxref {
    return shift->dbxref_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Feature_Relationship;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Feature_Relationship->set_up_table('feature_relationship');


Chado::DBI::Chado::Feature_Relationship->has_a(
    subject_id => 'Chado::DBI::Chado::Feature'
);

sub Chado::DBI::Chado::Feature_Relationship::subject {
    return shift->subject_id
}

Chado::DBI::Chado::Feature_Relationship->has_a(
    object_id => 'Chado::DBI::Chado::Feature'
);

sub Chado::DBI::Chado::Feature_Relationship::object {
    return shift->object_id
}

Chado::DBI::Chado::Feature_Relationship->has_a(
    type_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Feature_Relationship::type {
    return shift->type_id
}

Chado::DBI::Chado::Feature_Relationship->has_many(
    'feature_relationshipprop_feature_relationship_id', 'Chado::DBI::Chado::Feature_Relationshipprop' => 'feature_relationship_id'
);

sub pubs { my $self = shift; return map $_->pub_id, $self->feature_relationship_pub_feature_relationship_id }

Chado::DBI::Chado::Feature_Relationship->has_many(
    'feature_relationship_pub_feature_relationship_id', 'Chado::DBI::Chado::Feature_Relationship_Pub' => 'feature_relationship_id'
);

# -------------------------------------------------------------------
package Chado::DBI::Chado::Feature_Relationship_Pub;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Feature_Relationship_Pub->set_up_table('feature_relationship_pub');


Chado::DBI::Chado::Feature_Relationship_Pub->has_a(
    feature_relationship_id => 'Chado::DBI::Chado::Feature_Relationship'
);

sub Chado::DBI::Chado::Feature_Relationship_Pub::feature_relationship {
    return shift->feature_relationship_id
}

Chado::DBI::Chado::Feature_Relationship_Pub->has_a(
    pub_id => 'Chado::DBI::Chado::Pub'
);

sub Chado::DBI::Chado::Feature_Relationship_Pub::pub {
    return shift->pub_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Feature_Relationshipprop;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Feature_Relationshipprop->set_up_table('feature_relationshipprop');


Chado::DBI::Chado::Feature_Relationshipprop->has_a(
    feature_relationship_id => 'Chado::DBI::Chado::Feature_Relationship'
);

sub Chado::DBI::Chado::Feature_Relationshipprop::feature_relationship {
    return shift->feature_relationship_id
}

Chado::DBI::Chado::Feature_Relationshipprop->has_a(
    type_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Feature_Relationshipprop::type {
    return shift->type_id
}

sub pubs { my $self = shift; return map $_->pub_id, $self->feature_relationshipprop_pub_feature_relationshipprop_id }

Chado::DBI::Chado::Feature_Relationshipprop->has_many(
    'feature_relationshipprop_pub_feature_relationshipprop_id', 'Chado::DBI::Chado::Feature_Relationshipprop_Pub' => 'feature_relationshipprop_id'
);

# -------------------------------------------------------------------
package Chado::DBI::Chado::Feature_Relationshipprop_Pub;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Feature_Relationshipprop_Pub->set_up_table('feature_relationshipprop_pub');


Chado::DBI::Chado::Feature_Relationshipprop_Pub->has_a(
    feature_relationshipprop_id => 'Chado::DBI::Chado::Feature_Relationshipprop'
);

sub Chado::DBI::Chado::Feature_Relationshipprop_Pub::feature_relationshipprop {
    return shift->feature_relationshipprop_id
}

Chado::DBI::Chado::Feature_Relationshipprop_Pub->has_a(
    pub_id => 'Chado::DBI::Chado::Pub'
);

sub Chado::DBI::Chado::Feature_Relationshipprop_Pub::pub {
    return shift->pub_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Feature_Cvterm;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Feature_Cvterm->set_up_table('feature_cvterm');


Chado::DBI::Chado::Feature_Cvterm->has_a(
    feature_id => 'Chado::DBI::Chado::Feature'
);

sub Chado::DBI::Chado::Feature_Cvterm::feature {
    return shift->feature_id
}

Chado::DBI::Chado::Feature_Cvterm->has_a(
    cvterm_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Feature_Cvterm::cvterm {
    return shift->cvterm_id
}

Chado::DBI::Chado::Feature_Cvterm->has_a(
    pub_id => 'Chado::DBI::Chado::Pub'
);

sub Chado::DBI::Chado::Feature_Cvterm::pub {
    return shift->pub_id
}

Chado::DBI::Chado::Feature_Cvterm->has_many(
    'feature_cvterm_pub_feature_cvterm_id', 'Chado::DBI::Chado::Feature_Cvterm_Pub' => 'feature_cvterm_id'
);

Chado::DBI::Chado::Feature_Cvterm->has_many(
    'feature_cvterm_dbxref_feature_cvterm_id', 'Chado::DBI::Chado::Feature_Cvterm_Dbxref' => 'feature_cvterm_id'
);

sub pubs { my $self = shift; return map $_->pub_id, $self->feature_cvterm_pub_feature_cvterm_id }

Chado::DBI::Chado::Feature_Cvterm->has_many(
    'feature_cvtermprop_feature_cvterm_id', 'Chado::DBI::Chado::Feature_Cvtermprop' => 'feature_cvterm_id'
);

sub dbxrefs { my $self = shift; return map $_->dbxref_id, $self->feature_cvterm_dbxref_feature_cvterm_id }

# -------------------------------------------------------------------
package Chado::DBI::Chado::Feature_Cvtermprop;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Feature_Cvtermprop->set_up_table('feature_cvtermprop');


Chado::DBI::Chado::Feature_Cvtermprop->has_a(
    feature_cvterm_id => 'Chado::DBI::Chado::Feature_Cvterm'
);

sub Chado::DBI::Chado::Feature_Cvtermprop::feature_cvterm {
    return shift->feature_cvterm_id
}

Chado::DBI::Chado::Feature_Cvtermprop->has_a(
    type_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Feature_Cvtermprop::type {
    return shift->type_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Feature_Cvterm_Dbxref;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Feature_Cvterm_Dbxref->set_up_table('feature_cvterm_dbxref');


Chado::DBI::Chado::Feature_Cvterm_Dbxref->has_a(
    feature_cvterm_id => 'Chado::DBI::Chado::Feature_Cvterm'
);

sub Chado::DBI::Chado::Feature_Cvterm_Dbxref::feature_cvterm {
    return shift->feature_cvterm_id
}

Chado::DBI::Chado::Feature_Cvterm_Dbxref->has_a(
    dbxref_id => 'Chado::DBI::Chado::Dbxref'
);

sub Chado::DBI::Chado::Feature_Cvterm_Dbxref::dbxref {
    return shift->dbxref_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Feature_Cvterm_Pub;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Feature_Cvterm_Pub->set_up_table('feature_cvterm_pub');


Chado::DBI::Chado::Feature_Cvterm_Pub->has_a(
    feature_cvterm_id => 'Chado::DBI::Chado::Feature_Cvterm'
);

sub Chado::DBI::Chado::Feature_Cvterm_Pub::feature_cvterm {
    return shift->feature_cvterm_id
}

Chado::DBI::Chado::Feature_Cvterm_Pub->has_a(
    pub_id => 'Chado::DBI::Chado::Pub'
);

sub Chado::DBI::Chado::Feature_Cvterm_Pub::pub {
    return shift->pub_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Synonym;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Synonym->set_up_table('synonym');


Chado::DBI::Chado::Synonym->has_a(
    type_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Synonym::type {
    return shift->type_id
}

Chado::DBI::Chado::Synonym->has_many(
    'feature_synonym_synonym_id', 'Chado::DBI::Chado::Feature_Synonym' => 'synonym_id'
);

# -------------------------------------------------------------------
package Chado::DBI::Chado::Feature_Synonym;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Feature_Synonym->set_up_table('feature_synonym');


Chado::DBI::Chado::Feature_Synonym->has_a(
    synonym_id => 'Chado::DBI::Chado::Synonym'
);

sub Chado::DBI::Chado::Feature_Synonym::synonym {
    return shift->synonym_id
}

Chado::DBI::Chado::Feature_Synonym->has_a(
    feature_id => 'Chado::DBI::Chado::Feature'
);

sub Chado::DBI::Chado::Feature_Synonym::feature {
    return shift->feature_id
}

Chado::DBI::Chado::Feature_Synonym->has_a(
    pub_id => 'Chado::DBI::Chado::Pub'
);

sub Chado::DBI::Chado::Feature_Synonym::pub {
    return shift->pub_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Gencode;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Gencode->set_up_table('gencode');


Chado::DBI::Chado::Gencode->has_many(
    'gencode_startcodon_gencode_id', 'Chado::DBI::Chado::Gencode_Startcodon' => 'gencode_id'
);

Chado::DBI::Chado::Gencode->has_many(
    'gencode_codon_aa_gencode_id', 'Chado::DBI::Chado::Gencode_Codon_Aa' => 'gencode_id'
);

# -------------------------------------------------------------------
package Chado::DBI::Chado::Gencode_Codon_Aa;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Gencode_Codon_Aa->set_up_table('gencode_codon_aa');


Chado::DBI::Chado::Gencode_Codon_Aa->has_a(
    gencode_id => 'Chado::DBI::Chado::Gencode'
);

sub Chado::DBI::Chado::Gencode_Codon_Aa::gencode {
    return shift->gencode_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Gencode_Startcodon;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Gencode_Startcodon->set_up_table('gencode_startcodon');


Chado::DBI::Chado::Gencode_Startcodon->has_a(
    gencode_id => 'Chado::DBI::Chado::Gencode'
);

sub Chado::DBI::Chado::Gencode_Startcodon::gencode {
    return shift->gencode_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Analysis;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Analysis->set_up_table('analysis');


Chado::DBI::Chado::Analysis->has_many(
    'analysisfeature_analysis_id', 'Chado::DBI::Chado::Analysisfeature' => 'analysis_id'
);

Chado::DBI::Chado::Analysis->has_many(
    'quantification_analysis_id', 'Chado::DBI::Chado::Quantification' => 'analysis_id'
);

Chado::DBI::Chado::Analysis->has_many(
    'analysisprop_analysis_id', 'Chado::DBI::Chado::Analysisprop' => 'analysis_id'
);

# -------------------------------------------------------------------
package Chado::DBI::Chado::Analysisprop;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Analysisprop->set_up_table('analysisprop');


Chado::DBI::Chado::Analysisprop->has_a(
    analysis_id => 'Chado::DBI::Chado::Analysis'
);

sub Chado::DBI::Chado::Analysisprop::analysis {
    return shift->analysis_id
}

Chado::DBI::Chado::Analysisprop->has_a(
    type_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Analysisprop::type {
    return shift->type_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Analysisfeature;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Analysisfeature->set_up_table('analysisfeature');


Chado::DBI::Chado::Analysisfeature->has_a(
    feature_id => 'Chado::DBI::Chado::Feature'
);

sub Chado::DBI::Chado::Analysisfeature::feature {
    return shift->feature_id
}

Chado::DBI::Chado::Analysisfeature->has_a(
    analysis_id => 'Chado::DBI::Chado::Analysis'
);

sub Chado::DBI::Chado::Analysisfeature::analysis {
    return shift->analysis_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Genotype;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Genotype->set_up_table('genotype');


Chado::DBI::Chado::Genotype->has_many(
    'phenstatement_genotype_id', 'Chado::DBI::Chado::Phenstatement' => 'genotype_id'
);

sub phenotype_comparison_genotype1_ids { my $self = shift; return $self->phenotype_comparison_genotype1_id(@_) }

sub phenotype_comparison_genotype2_ids { my $self = shift; return $self->phenotype_comparison_genotype2_id(@_) }

Chado::DBI::Chado::Genotype->has_many(
    'phendesc_genotype_id', 'Chado::DBI::Chado::Phendesc' => 'genotype_id'
);

sub phenotype_comparison_genotype1_ids { my $self = shift; return $self->phenotype_comparison_genotype1_id(@_) }

sub phenotype_comparison_genotype2_ids { my $self = shift; return $self->phenotype_comparison_genotype2_id(@_) }

sub phenotype_comparison_genotype1_ids { my $self = shift; return $self->phenotype_comparison_genotype1_id(@_) }

sub phenotype_comparison_genotype2_ids { my $self = shift; return $self->phenotype_comparison_genotype2_id(@_) }

Chado::DBI::Chado::Genotype->has_many(
    'feature_genotype_genotype_id', 'Chado::DBI::Chado::Feature_Genotype' => 'genotype_id'
);

Chado::DBI::Chado::Genotype->has_many(
    'phenotype_comparison_genotype1_id', 'Chado::DBI::Chado::Phenotype_Comparison' => 'genotype1_id'
);

Chado::DBI::Chado::Genotype->has_many(
    'phenotype_comparison_genotype2_id', 'Chado::DBI::Chado::Phenotype_Comparison' => 'genotype2_id'
);

# -------------------------------------------------------------------
package Chado::DBI::Chado::Feature_Genotype;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Feature_Genotype->set_up_table('feature_genotype');


Chado::DBI::Chado::Feature_Genotype->has_a(
    feature_id => 'Chado::DBI::Chado::Feature'
);

sub Chado::DBI::Chado::Feature_Genotype::feature {
    return shift->feature_id
}

Chado::DBI::Chado::Feature_Genotype->has_a(
    genotype_id => 'Chado::DBI::Chado::Genotype'
);

sub Chado::DBI::Chado::Feature_Genotype::genotype {
    return shift->genotype_id
}

Chado::DBI::Chado::Feature_Genotype->has_a(
    chromosome_id => 'Chado::DBI::Chado::Feature'
);

sub Chado::DBI::Chado::Feature_Genotype::chromosome {
    return shift->chromosome_id
}

Chado::DBI::Chado::Feature_Genotype->has_a(
    cvterm_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Feature_Genotype::cvterm {
    return shift->cvterm_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Environment;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Environment->set_up_table('environment');


Chado::DBI::Chado::Environment->has_many(
    'phenstatement_environment_id', 'Chado::DBI::Chado::Phenstatement' => 'environment_id'
);

sub phenotype_comparison_environment1_ids { my $self = shift; return $self->phenotype_comparison_environment1_id(@_) }

sub phenotype_comparison_environment2_ids { my $self = shift; return $self->phenotype_comparison_environment2_id(@_) }

Chado::DBI::Chado::Environment->has_many(
    'environment_cvterm_environment_id', 'Chado::DBI::Chado::Environment_Cvterm' => 'environment_id'
);

Chado::DBI::Chado::Environment->has_many(
    'phendesc_environment_id', 'Chado::DBI::Chado::Phendesc' => 'environment_id'
);

sub phenotype_comparison_environment1_ids { my $self = shift; return $self->phenotype_comparison_environment1_id(@_) }

sub phenotype_comparison_environment2_ids { my $self = shift; return $self->phenotype_comparison_environment2_id(@_) }

sub phenotype_comparison_environment1_ids { my $self = shift; return $self->phenotype_comparison_environment1_id(@_) }

sub phenotype_comparison_environment2_ids { my $self = shift; return $self->phenotype_comparison_environment2_id(@_) }

Chado::DBI::Chado::Environment->has_many(
    'phenotype_comparison_environment1_id', 'Chado::DBI::Chado::Phenotype_Comparison' => 'environment1_id'
);

Chado::DBI::Chado::Environment->has_many(
    'phenotype_comparison_environment2_id', 'Chado::DBI::Chado::Phenotype_Comparison' => 'environment2_id'
);

# -------------------------------------------------------------------
package Chado::DBI::Chado::Environment_Cvterm;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Environment_Cvterm->set_up_table('environment_cvterm');


Chado::DBI::Chado::Environment_Cvterm->has_a(
    environment_id => 'Chado::DBI::Chado::Environment'
);

sub Chado::DBI::Chado::Environment_Cvterm::environment {
    return shift->environment_id
}

Chado::DBI::Chado::Environment_Cvterm->has_a(
    cvterm_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Environment_Cvterm::cvterm {
    return shift->cvterm_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Phenotype;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Phenotype->set_up_table('phenotype');


Chado::DBI::Chado::Phenotype->has_a(
    observable_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Phenotype::observable {
    return shift->observable_id
}

Chado::DBI::Chado::Phenotype->has_a(
    attr_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Phenotype::attr {
    return shift->attr_id
}

Chado::DBI::Chado::Phenotype->has_a(
    cvalue_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Phenotype::cvalue {
    return shift->cvalue_id
}

Chado::DBI::Chado::Phenotype->has_a(
    assay_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Phenotype::assay {
    return shift->assay_id
}

Chado::DBI::Chado::Phenotype->has_many(
    'phenstatement_phenotype_id', 'Chado::DBI::Chado::Phenstatement' => 'phenotype_id'
);

sub phenotype_comparison_phenotype1_ids { my $self = shift; return $self->phenotype_comparison_phenotype1_id(@_) }

sub phenotype_comparison_phenotype2_ids { my $self = shift; return $self->phenotype_comparison_phenotype2_id(@_) }

sub features { my $self = shift; return map $_->feature_id, $self->feature_phenotype_phenotype_id }

Chado::DBI::Chado::Phenotype->has_many(
    'phenotype_cvterm_phenotype_id', 'Chado::DBI::Chado::Phenotype_Cvterm' => 'phenotype_id'
);

sub phenotype_comparison_phenotype1_ids { my $self = shift; return $self->phenotype_comparison_phenotype1_id(@_) }

sub phenotype_comparison_phenotype2_ids { my $self = shift; return $self->phenotype_comparison_phenotype2_id(@_) }

Chado::DBI::Chado::Phenotype->has_many(
    'feature_phenotype_phenotype_id', 'Chado::DBI::Chado::Feature_Phenotype' => 'phenotype_id'
);

sub phenotype_comparison_phenotype1_ids { my $self = shift; return $self->phenotype_comparison_phenotype1_id(@_) }

sub phenotype_comparison_phenotype2_ids { my $self = shift; return $self->phenotype_comparison_phenotype2_id(@_) }

Chado::DBI::Chado::Phenotype->has_many(
    'phenotype_comparison_phenotype1_id', 'Chado::DBI::Chado::Phenotype_Comparison' => 'phenotype1_id'
);

Chado::DBI::Chado::Phenotype->has_many(
    'phenotype_comparison_phenotype2_id', 'Chado::DBI::Chado::Phenotype_Comparison' => 'phenotype2_id'
);

# -------------------------------------------------------------------
package Chado::DBI::Chado::Phenotype_Cvterm;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Phenotype_Cvterm->set_up_table('phenotype_cvterm');


Chado::DBI::Chado::Phenotype_Cvterm->has_a(
    phenotype_id => 'Chado::DBI::Chado::Phenotype'
);

sub Chado::DBI::Chado::Phenotype_Cvterm::phenotype {
    return shift->phenotype_id
}

Chado::DBI::Chado::Phenotype_Cvterm->has_a(
    cvterm_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Phenotype_Cvterm::cvterm {
    return shift->cvterm_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Phenstatement;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Phenstatement->set_up_table('phenstatement');


Chado::DBI::Chado::Phenstatement->has_a(
    genotype_id => 'Chado::DBI::Chado::Genotype'
);

sub Chado::DBI::Chado::Phenstatement::genotype {
    return shift->genotype_id
}

Chado::DBI::Chado::Phenstatement->has_a(
    environment_id => 'Chado::DBI::Chado::Environment'
);

sub Chado::DBI::Chado::Phenstatement::environment {
    return shift->environment_id
}

Chado::DBI::Chado::Phenstatement->has_a(
    phenotype_id => 'Chado::DBI::Chado::Phenotype'
);

sub Chado::DBI::Chado::Phenstatement::phenotype {
    return shift->phenotype_id
}

Chado::DBI::Chado::Phenstatement->has_a(
    type_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Phenstatement::type {
    return shift->type_id
}

Chado::DBI::Chado::Phenstatement->has_a(
    pub_id => 'Chado::DBI::Chado::Pub'
);

sub Chado::DBI::Chado::Phenstatement::pub {
    return shift->pub_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Feature_Phenotype;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Feature_Phenotype->set_up_table('feature_phenotype');


Chado::DBI::Chado::Feature_Phenotype->has_a(
    feature_id => 'Chado::DBI::Chado::Feature'
);

sub Chado::DBI::Chado::Feature_Phenotype::feature {
    return shift->feature_id
}

Chado::DBI::Chado::Feature_Phenotype->has_a(
    phenotype_id => 'Chado::DBI::Chado::Phenotype'
);

sub Chado::DBI::Chado::Feature_Phenotype::phenotype {
    return shift->phenotype_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Phendesc;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Phendesc->set_up_table('phendesc');


Chado::DBI::Chado::Phendesc->has_a(
    genotype_id => 'Chado::DBI::Chado::Genotype'
);

sub Chado::DBI::Chado::Phendesc::genotype {
    return shift->genotype_id
}

Chado::DBI::Chado::Phendesc->has_a(
    environment_id => 'Chado::DBI::Chado::Environment'
);

sub Chado::DBI::Chado::Phendesc::environment {
    return shift->environment_id
}

Chado::DBI::Chado::Phendesc->has_a(
    pub_id => 'Chado::DBI::Chado::Pub'
);

sub Chado::DBI::Chado::Phendesc::pub {
    return shift->pub_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Phenotype_Comparison;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Phenotype_Comparison->set_up_table('phenotype_comparison');


Chado::DBI::Chado::Phenotype_Comparison->has_a(
    genotype1_id => 'Chado::DBI::Chado::Genotype'
);

sub Chado::DBI::Chado::Phenotype_Comparison::genotype1 {
    return shift->genotype1_id
}

Chado::DBI::Chado::Phenotype_Comparison->has_a(
    environment1_id => 'Chado::DBI::Chado::Environment'
);

sub Chado::DBI::Chado::Phenotype_Comparison::environment1 {
    return shift->environment1_id
}

Chado::DBI::Chado::Phenotype_Comparison->has_a(
    genotype2_id => 'Chado::DBI::Chado::Genotype'
);

sub Chado::DBI::Chado::Phenotype_Comparison::genotype2 {
    return shift->genotype2_id
}

Chado::DBI::Chado::Phenotype_Comparison->has_a(
    environment2_id => 'Chado::DBI::Chado::Environment'
);

sub Chado::DBI::Chado::Phenotype_Comparison::environment2 {
    return shift->environment2_id
}

Chado::DBI::Chado::Phenotype_Comparison->has_a(
    phenotype1_id => 'Chado::DBI::Chado::Phenotype'
);

sub Chado::DBI::Chado::Phenotype_Comparison::phenotype1 {
    return shift->phenotype1_id
}

Chado::DBI::Chado::Phenotype_Comparison->has_a(
    phenotype2_id => 'Chado::DBI::Chado::Phenotype'
);

sub Chado::DBI::Chado::Phenotype_Comparison::phenotype2 {
    return shift->phenotype2_id
}

Chado::DBI::Chado::Phenotype_Comparison->has_a(
    type_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Phenotype_Comparison::type {
    return shift->type_id
}

Chado::DBI::Chado::Phenotype_Comparison->has_a(
    pub_id => 'Chado::DBI::Chado::Pub'
);

sub Chado::DBI::Chado::Phenotype_Comparison::pub {
    return shift->pub_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Featuremap;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Featuremap->set_up_table('featuremap');


Chado::DBI::Chado::Featuremap->has_a(
    unittype_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Featuremap::unittype {
    return shift->unittype_id
}

Chado::DBI::Chado::Featuremap->has_many(
    'featurerange_featuremap_id', 'Chado::DBI::Chado::Featurerange' => 'featuremap_id'
);

Chado::DBI::Chado::Featuremap->has_many(
    'featurepos_featuremap_id', 'Chado::DBI::Chado::Featurepos' => 'featuremap_id'
);

Chado::DBI::Chado::Featuremap->has_many(
    'featuremap_pub_featuremap_id', 'Chado::DBI::Chado::Featuremap_Pub' => 'featuremap_id'
);

sub pubs { my $self = shift; return map $_->pub_id, $self->featuremap_pub_featuremap_id }

# -------------------------------------------------------------------
package Chado::DBI::Chado::Featurerange;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Featurerange->set_up_table('featurerange');


Chado::DBI::Chado::Featurerange->has_a(
    featuremap_id => 'Chado::DBI::Chado::Featuremap'
);

sub Chado::DBI::Chado::Featurerange::featuremap {
    return shift->featuremap_id
}

Chado::DBI::Chado::Featurerange->has_a(
    feature_id => 'Chado::DBI::Chado::Feature'
);

sub Chado::DBI::Chado::Featurerange::feature {
    return shift->feature_id
}

Chado::DBI::Chado::Featurerange->has_a(
    leftstartf_id => 'Chado::DBI::Chado::Feature'
);

sub Chado::DBI::Chado::Featurerange::leftstartf {
    return shift->leftstartf_id
}

Chado::DBI::Chado::Featurerange->has_a(
    leftendf_id => 'Chado::DBI::Chado::Feature'
);

sub Chado::DBI::Chado::Featurerange::leftendf {
    return shift->leftendf_id
}

Chado::DBI::Chado::Featurerange->has_a(
    rightstartf_id => 'Chado::DBI::Chado::Feature'
);

sub Chado::DBI::Chado::Featurerange::rightstartf {
    return shift->rightstartf_id
}

Chado::DBI::Chado::Featurerange->has_a(
    rightendf_id => 'Chado::DBI::Chado::Feature'
);

sub Chado::DBI::Chado::Featurerange::rightendf {
    return shift->rightendf_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Featurepos;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Featurepos->set_up_table('featurepos');


Chado::DBI::Chado::Featurepos->has_a(
    featuremap_id => 'Chado::DBI::Chado::Featuremap'
);

sub Chado::DBI::Chado::Featurepos::featuremap {
    return shift->featuremap_id
}

Chado::DBI::Chado::Featurepos->has_a(
    feature_id => 'Chado::DBI::Chado::Feature'
);

sub Chado::DBI::Chado::Featurepos::feature {
    return shift->feature_id
}

Chado::DBI::Chado::Featurepos->has_a(
    map_feature_id => 'Chado::DBI::Chado::Feature'
);

sub Chado::DBI::Chado::Featurepos::map_feature {
    return shift->map_feature_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Featuremap_Pub;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Featuremap_Pub->set_up_table('featuremap_pub');


Chado::DBI::Chado::Featuremap_Pub->has_a(
    featuremap_id => 'Chado::DBI::Chado::Featuremap'
);

sub Chado::DBI::Chado::Featuremap_Pub::featuremap {
    return shift->featuremap_id
}

Chado::DBI::Chado::Featuremap_Pub->has_a(
    pub_id => 'Chado::DBI::Chado::Pub'
);

sub Chado::DBI::Chado::Featuremap_Pub::pub {
    return shift->pub_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Phylotree;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Phylotree->set_up_table('phylotree');


Chado::DBI::Chado::Phylotree->has_a(
    dbxref_id => 'Chado::DBI::Chado::Dbxref'
);

sub Chado::DBI::Chado::Phylotree::dbxref {
    return shift->dbxref_id
}

Chado::DBI::Chado::Phylotree->has_a(
    type_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Phylotree::type {
    return shift->type_id
}

Chado::DBI::Chado::Phylotree->has_many(
    'phylonode_phylotree_id', 'Chado::DBI::Chado::Phylonode' => 'phylotree_id'
);

sub pubs { my $self = shift; return map $_->pub_id, $self->phylotree_pub_phylotree_id }

Chado::DBI::Chado::Phylotree->has_many(
    'phylotree_pub_phylotree_id', 'Chado::DBI::Chado::Phylotree_Pub' => 'phylotree_id'
);

# -------------------------------------------------------------------
package Chado::DBI::Chado::Phylotree_Pub;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Phylotree_Pub->set_up_table('phylotree_pub');


Chado::DBI::Chado::Phylotree_Pub->has_a(
    phylotree_id => 'Chado::DBI::Chado::Phylotree'
);

sub Chado::DBI::Chado::Phylotree_Pub::phylotree {
    return shift->phylotree_id
}

Chado::DBI::Chado::Phylotree_Pub->has_a(
    pub_id => 'Chado::DBI::Chado::Pub'
);

sub Chado::DBI::Chado::Phylotree_Pub::pub {
    return shift->pub_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Phylonode;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Phylonode->set_up_table('phylonode');


Chado::DBI::Chado::Phylonode->has_a(
    phylotree_id => 'Chado::DBI::Chado::Phylotree'
);

sub Chado::DBI::Chado::Phylonode::phylotree {
    return shift->phylotree_id
}

Chado::DBI::Chado::Phylonode->has_a(
    parent_phylonode_id => 'Chado::DBI::Chado::Phylonode'
);

sub Chado::DBI::Chado::Phylonode::parent_phylonode {
    return shift->parent_phylonode_id
}

Chado::DBI::Chado::Phylonode->has_a(
    type_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Phylonode::type {
    return shift->type_id
}

Chado::DBI::Chado::Phylonode->has_a(
    feature_id => 'Chado::DBI::Chado::Feature'
);

sub Chado::DBI::Chado::Phylonode::feature {
    return shift->feature_id
}

Chado::DBI::Chado::Phylonode->has_many(
    'phylonode_pub_phylonode_id', 'Chado::DBI::Chado::Phylonode_Pub' => 'phylonode_id'
);

Chado::DBI::Chado::Phylonode->has_many(
    'phylonode_organism_phylonode_id', 'Chado::DBI::Chado::Phylonode_Organism' => 'phylonode_id'
);

Chado::DBI::Chado::Phylonode->has_many(
    'phylonode_parent_phylonode_id', 'Chado::DBI::Chado::Phylonode' => 'parent_phylonode_id'
);

Chado::DBI::Chado::Phylonode->has_many(
    'phylonode_relationship_subject_id', 'Chado::DBI::Chado::Phylonode_Relationship' => 'subject_id'
);

Chado::DBI::Chado::Phylonode->has_many(
    'phylonode_relationship_object_id', 'Chado::DBI::Chado::Phylonode_Relationship' => 'object_id'
);

sub dbxrefs { my $self = shift; return map $_->dbxref_id, $self->phylonode_dbxref_phylonode_id }

Chado::DBI::Chado::Phylonode->has_many(
    'phylonode_dbxref_phylonode_id', 'Chado::DBI::Chado::Phylonode_Dbxref' => 'phylonode_id'
);

Chado::DBI::Chado::Phylonode->has_many(
    'phylonodeprop_phylonode_id', 'Chado::DBI::Chado::Phylonodeprop' => 'phylonode_id'
);

sub organisms { my $self = shift; return map $_->organism_id, $self->phylonode_organism_phylonode_id }

sub pubs { my $self = shift; return map $_->pub_id, $self->phylonode_pub_phylonode_id }

# -------------------------------------------------------------------
package Chado::DBI::Chado::Phylonode_Dbxref;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Phylonode_Dbxref->set_up_table('phylonode_dbxref');


Chado::DBI::Chado::Phylonode_Dbxref->has_a(
    phylonode_id => 'Chado::DBI::Chado::Phylonode'
);

sub Chado::DBI::Chado::Phylonode_Dbxref::phylonode {
    return shift->phylonode_id
}

Chado::DBI::Chado::Phylonode_Dbxref->has_a(
    dbxref_id => 'Chado::DBI::Chado::Dbxref'
);

sub Chado::DBI::Chado::Phylonode_Dbxref::dbxref {
    return shift->dbxref_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Phylonode_Pub;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Phylonode_Pub->set_up_table('phylonode_pub');


Chado::DBI::Chado::Phylonode_Pub->has_a(
    phylonode_id => 'Chado::DBI::Chado::Phylonode'
);

sub Chado::DBI::Chado::Phylonode_Pub::phylonode {
    return shift->phylonode_id
}

Chado::DBI::Chado::Phylonode_Pub->has_a(
    pub_id => 'Chado::DBI::Chado::Pub'
);

sub Chado::DBI::Chado::Phylonode_Pub::pub {
    return shift->pub_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Phylonode_Organism;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Phylonode_Organism->set_up_table('phylonode_organism');


Chado::DBI::Chado::Phylonode_Organism->has_a(
    phylonode_id => 'Chado::DBI::Chado::Phylonode'
);

sub Chado::DBI::Chado::Phylonode_Organism::phylonode {
    return shift->phylonode_id
}

Chado::DBI::Chado::Phylonode_Organism->has_a(
    organism_id => 'Chado::DBI::Chado::Organism'
);

sub Chado::DBI::Chado::Phylonode_Organism::organism {
    return shift->organism_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Phylonodeprop;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Phylonodeprop->set_up_table('phylonodeprop');


Chado::DBI::Chado::Phylonodeprop->has_a(
    phylonode_id => 'Chado::DBI::Chado::Phylonode'
);

sub Chado::DBI::Chado::Phylonodeprop::phylonode {
    return shift->phylonode_id
}

Chado::DBI::Chado::Phylonodeprop->has_a(
    type_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Phylonodeprop::type {
    return shift->type_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Phylonode_Relationship;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Phylonode_Relationship->set_up_table('phylonode_relationship');


Chado::DBI::Chado::Phylonode_Relationship->has_a(
    subject_id => 'Chado::DBI::Chado::Phylonode'
);

sub Chado::DBI::Chado::Phylonode_Relationship::subject {
    return shift->subject_id
}

Chado::DBI::Chado::Phylonode_Relationship->has_a(
    object_id => 'Chado::DBI::Chado::Phylonode'
);

sub Chado::DBI::Chado::Phylonode_Relationship::object {
    return shift->object_id
}

Chado::DBI::Chado::Phylonode_Relationship->has_a(
    type_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Phylonode_Relationship::type {
    return shift->type_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Contact;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Contact->set_up_table('contact');


Chado::DBI::Chado::Contact->has_a(
    type_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Contact::type {
    return shift->type_id
}

Chado::DBI::Chado::Contact->has_many(
    'biomaterial_biosourceprovider_id', 'Chado::DBI::Chado::Biomaterial' => 'biosourceprovider_id'
);

Chado::DBI::Chado::Contact->has_many(
    'assay_operator_id', 'Chado::DBI::Chado::Assay' => 'operator_id'
);

Chado::DBI::Chado::Contact->has_many(
    'contact_relationship_subject_id', 'Chado::DBI::Chado::Contact_Relationship' => 'subject_id'
);

Chado::DBI::Chado::Contact->has_many(
    'contact_relationship_object_id', 'Chado::DBI::Chado::Contact_Relationship' => 'object_id'
);

Chado::DBI::Chado::Contact->has_many(
    'arraydesign_manufacturer_id', 'Chado::DBI::Chado::Arraydesign' => 'manufacturer_id'
);

sub contact_relationship_subject_ids { my $self = shift; return $self->contact_relationship_subject_id(@_) }

sub contact_relationship_object_ids { my $self = shift; return $self->contact_relationship_object_id(@_) }

Chado::DBI::Chado::Contact->has_many(
    'study_contact_id', 'Chado::DBI::Chado::Study' => 'contact_id'
);

Chado::DBI::Chado::Contact->has_many(
    'quantification_operator_id', 'Chado::DBI::Chado::Quantification' => 'operator_id'
);

# -------------------------------------------------------------------
package Chado::DBI::Chado::Contact_Relationship;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Contact_Relationship->set_up_table('contact_relationship');


Chado::DBI::Chado::Contact_Relationship->has_a(
    type_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Contact_Relationship::type {
    return shift->type_id
}

Chado::DBI::Chado::Contact_Relationship->has_a(
    subject_id => 'Chado::DBI::Chado::Contact'
);

sub Chado::DBI::Chado::Contact_Relationship::subject {
    return shift->subject_id
}

Chado::DBI::Chado::Contact_Relationship->has_a(
    object_id => 'Chado::DBI::Chado::Contact'
);

sub Chado::DBI::Chado::Contact_Relationship::object {
    return shift->object_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Expression;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Expression->set_up_table('expression');


Chado::DBI::Chado::Expression->has_many(
    'expression_pub_expression_id', 'Chado::DBI::Chado::Expression_Pub' => 'expression_id'
);

sub features { my $self = shift; return map $_->feature_id, $self->feature_expression_expression_id }

sub eimages { my $self = shift; return map $_->eimage_id, $self->expression_image_expression_id }

Chado::DBI::Chado::Expression->has_many(
    'feature_expression_expression_id', 'Chado::DBI::Chado::Feature_Expression' => 'expression_id'
);

sub pubs { my $self = shift; return map $_->pub_id, $self->expression_pub_expression_id }

Chado::DBI::Chado::Expression->has_many(
    'expression_image_expression_id', 'Chado::DBI::Chado::Expression_Image' => 'expression_id'
);

Chado::DBI::Chado::Expression->has_many(
    'expression_cvterm_expression_id', 'Chado::DBI::Chado::Expression_Cvterm' => 'expression_id'
);

# -------------------------------------------------------------------
package Chado::DBI::Chado::Feature_Expression;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Feature_Expression->set_up_table('feature_expression');


Chado::DBI::Chado::Feature_Expression->has_a(
    expression_id => 'Chado::DBI::Chado::Expression'
);

sub Chado::DBI::Chado::Feature_Expression::expression {
    return shift->expression_id
}

Chado::DBI::Chado::Feature_Expression->has_a(
    feature_id => 'Chado::DBI::Chado::Feature'
);

sub Chado::DBI::Chado::Feature_Expression::feature {
    return shift->feature_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Expression_Cvterm;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Expression_Cvterm->set_up_table('expression_cvterm');


Chado::DBI::Chado::Expression_Cvterm->has_a(
    expression_id => 'Chado::DBI::Chado::Expression'
);

sub Chado::DBI::Chado::Expression_Cvterm::expression {
    return shift->expression_id
}

Chado::DBI::Chado::Expression_Cvterm->has_a(
    cvterm_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Expression_Cvterm::cvterm {
    return shift->cvterm_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Expression_Pub;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Expression_Pub->set_up_table('expression_pub');


Chado::DBI::Chado::Expression_Pub->has_a(
    expression_id => 'Chado::DBI::Chado::Expression'
);

sub Chado::DBI::Chado::Expression_Pub::expression {
    return shift->expression_id
}

Chado::DBI::Chado::Expression_Pub->has_a(
    pub_id => 'Chado::DBI::Chado::Pub'
);

sub Chado::DBI::Chado::Expression_Pub::pub {
    return shift->pub_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Eimage;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Eimage->set_up_table('eimage');


sub expressions { my $self = shift; return map $_->expression_id, $self->expression_image_eimage_id }

Chado::DBI::Chado::Eimage->has_many(
    'expression_image_eimage_id', 'Chado::DBI::Chado::Expression_Image' => 'eimage_id'
);

# -------------------------------------------------------------------
package Chado::DBI::Chado::Expression_Image;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Expression_Image->set_up_table('expression_image');


Chado::DBI::Chado::Expression_Image->has_a(
    expression_id => 'Chado::DBI::Chado::Expression'
);

sub Chado::DBI::Chado::Expression_Image::expression {
    return shift->expression_id
}

Chado::DBI::Chado::Expression_Image->has_a(
    eimage_id => 'Chado::DBI::Chado::Eimage'
);

sub Chado::DBI::Chado::Expression_Image::eimage {
    return shift->eimage_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Mageml;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Mageml->set_up_table('mageml');


Chado::DBI::Chado::Mageml->has_many(
    'magedocumentation_mageml_id', 'Chado::DBI::Chado::Magedocumentation' => 'mageml_id'
);

# -------------------------------------------------------------------
package Chado::DBI::Chado::Magedocumentation;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Magedocumentation->set_up_table('magedocumentation');


Chado::DBI::Chado::Magedocumentation->has_a(
    mageml_id => 'Chado::DBI::Chado::Mageml'
);

sub Chado::DBI::Chado::Magedocumentation::mageml {
    return shift->mageml_id
}

Chado::DBI::Chado::Magedocumentation->has_a(
    tableinfo_id => 'Chado::DBI::Chado::Tableinfo'
);

sub Chado::DBI::Chado::Magedocumentation::tableinfo {
    return shift->tableinfo_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Protocol;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Protocol->set_up_table('protocol');


Chado::DBI::Chado::Protocol->has_a(
    type_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Protocol::type {
    return shift->type_id
}

Chado::DBI::Chado::Protocol->has_a(
    pub_id => 'Chado::DBI::Chado::Pub'
);

sub Chado::DBI::Chado::Protocol::pub {
    return shift->pub_id
}

Chado::DBI::Chado::Protocol->has_a(
    dbxref_id => 'Chado::DBI::Chado::Dbxref'
);

sub Chado::DBI::Chado::Protocol::dbxref {
    return shift->dbxref_id
}

Chado::DBI::Chado::Protocol->has_many(
    'treatment_protocol_id', 'Chado::DBI::Chado::Treatment' => 'protocol_id'
);

Chado::DBI::Chado::Protocol->has_many(
    'assay_protocol_id', 'Chado::DBI::Chado::Assay' => 'protocol_id'
);

Chado::DBI::Chado::Protocol->has_many(
    'acquisition_protocol_id', 'Chado::DBI::Chado::Acquisition' => 'protocol_id'
);

Chado::DBI::Chado::Protocol->has_many(
    'arraydesign_protocol_id', 'Chado::DBI::Chado::Arraydesign' => 'protocol_id'
);

Chado::DBI::Chado::Protocol->has_many(
    'protocolparam_protocol_id', 'Chado::DBI::Chado::Protocolparam' => 'protocol_id'
);

Chado::DBI::Chado::Protocol->has_many(
    'quantification_protocol_id', 'Chado::DBI::Chado::Quantification' => 'protocol_id'
);

# -------------------------------------------------------------------
package Chado::DBI::Chado::Protocolparam;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Protocolparam->set_up_table('protocolparam');


Chado::DBI::Chado::Protocolparam->has_a(
    protocol_id => 'Chado::DBI::Chado::Protocol'
);

sub Chado::DBI::Chado::Protocolparam::protocol {
    return shift->protocol_id
}

Chado::DBI::Chado::Protocolparam->has_a(
    datatype_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Protocolparam::datatype {
    return shift->datatype_id
}

Chado::DBI::Chado::Protocolparam->has_a(
    unittype_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Protocolparam::unittype {
    return shift->unittype_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Channel;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Channel->set_up_table('channel');


Chado::DBI::Chado::Channel->has_many(
    'acquisition_channel_id', 'Chado::DBI::Chado::Acquisition' => 'channel_id'
);

Chado::DBI::Chado::Channel->has_many(
    'assay_biomaterial_channel_id', 'Chado::DBI::Chado::Assay_Biomaterial' => 'channel_id'
);

# -------------------------------------------------------------------
package Chado::DBI::Chado::Arraydesign;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Arraydesign->set_up_table('arraydesign');


Chado::DBI::Chado::Arraydesign->has_a(
    manufacturer_id => 'Chado::DBI::Chado::Contact'
);

sub Chado::DBI::Chado::Arraydesign::manufacturer {
    return shift->manufacturer_id
}

Chado::DBI::Chado::Arraydesign->has_a(
    platformtype_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Arraydesign::platformtype {
    return shift->platformtype_id
}

Chado::DBI::Chado::Arraydesign->has_a(
    substratetype_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Arraydesign::substratetype {
    return shift->substratetype_id
}

Chado::DBI::Chado::Arraydesign->has_a(
    protocol_id => 'Chado::DBI::Chado::Protocol'
);

sub Chado::DBI::Chado::Arraydesign::protocol {
    return shift->protocol_id
}

Chado::DBI::Chado::Arraydesign->has_a(
    dbxref_id => 'Chado::DBI::Chado::Dbxref'
);

sub Chado::DBI::Chado::Arraydesign::dbxref {
    return shift->dbxref_id
}

sub features { my $self = shift; return map $_->feature_id, $self->element_arraydesign_id }

Chado::DBI::Chado::Arraydesign->has_many(
    'arraydesignprop_arraydesign_id', 'Chado::DBI::Chado::Arraydesignprop' => 'arraydesign_id'
);

Chado::DBI::Chado::Arraydesign->has_many(
    'assay_arraydesign_id', 'Chado::DBI::Chado::Assay' => 'arraydesign_id'
);

Chado::DBI::Chado::Arraydesign->has_many(
    'element_arraydesign_id', 'Chado::DBI::Chado::Element' => 'arraydesign_id'
);

sub cvterms { my $self = shift; return map $_->cvterm_id, $self->element_arraydesign_id }

sub dbxrefs { my $self = shift; return map $_->dbxref_id, $self->element_arraydesign_id }

# -------------------------------------------------------------------
package Chado::DBI::Chado::Arraydesignprop;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Arraydesignprop->set_up_table('arraydesignprop');


Chado::DBI::Chado::Arraydesignprop->has_a(
    arraydesign_id => 'Chado::DBI::Chado::Arraydesign'
);

sub Chado::DBI::Chado::Arraydesignprop::arraydesign {
    return shift->arraydesign_id
}

Chado::DBI::Chado::Arraydesignprop->has_a(
    type_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Arraydesignprop::type {
    return shift->type_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Assay;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Assay->set_up_table('assay');


Chado::DBI::Chado::Assay->has_a(
    arraydesign_id => 'Chado::DBI::Chado::Arraydesign'
);

sub Chado::DBI::Chado::Assay::arraydesign {
    return shift->arraydesign_id
}

Chado::DBI::Chado::Assay->has_a(
    protocol_id => 'Chado::DBI::Chado::Protocol'
);

sub Chado::DBI::Chado::Assay::protocol {
    return shift->protocol_id
}

Chado::DBI::Chado::Assay->has_a(
    operator_id => 'Chado::DBI::Chado::Contact'
);

sub Chado::DBI::Chado::Assay::operator {
    return shift->operator_id
}

Chado::DBI::Chado::Assay->has_a(
    dbxref_id => 'Chado::DBI::Chado::Dbxref'
);

sub Chado::DBI::Chado::Assay::dbxref {
    return shift->dbxref_id
}

Chado::DBI::Chado::Assay->has_many(
    'study_assay_assay_id', 'Chado::DBI::Chado::Study_Assay' => 'assay_id'
);

sub projects { my $self = shift; return map $_->project_id, $self->assay_project_assay_id }

Chado::DBI::Chado::Assay->has_many(
    'acquisition_assay_id', 'Chado::DBI::Chado::Acquisition' => 'assay_id'
);

Chado::DBI::Chado::Assay->has_many(
    'assay_biomaterial_assay_id', 'Chado::DBI::Chado::Assay_Biomaterial' => 'assay_id'
);

Chado::DBI::Chado::Assay->has_many(
    'studyfactorvalue_assay_id', 'Chado::DBI::Chado::Studyfactorvalue' => 'assay_id'
);

Chado::DBI::Chado::Assay->has_many(
    'assay_project_assay_id', 'Chado::DBI::Chado::Assay_Project' => 'assay_id'
);

Chado::DBI::Chado::Assay->has_many(
    'assayprop_assay_id', 'Chado::DBI::Chado::Assayprop' => 'assay_id'
);

sub studys { my $self = shift; return map $_->study_id, $self->study_assay_assay_id }

Chado::DBI::Chado::Assay->has_many(
    'control_assay_id', 'Chado::DBI::Chado::Control' => 'assay_id'
);

# -------------------------------------------------------------------
package Chado::DBI::Chado::Assayprop;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Assayprop->set_up_table('assayprop');


Chado::DBI::Chado::Assayprop->has_a(
    assay_id => 'Chado::DBI::Chado::Assay'
);

sub Chado::DBI::Chado::Assayprop::assay {
    return shift->assay_id
}

Chado::DBI::Chado::Assayprop->has_a(
    type_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Assayprop::type {
    return shift->type_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Assay_Project;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Assay_Project->set_up_table('assay_project');


Chado::DBI::Chado::Assay_Project->has_a(
    assay_id => 'Chado::DBI::Chado::Assay'
);

sub Chado::DBI::Chado::Assay_Project::assay {
    return shift->assay_id
}

Chado::DBI::Chado::Assay_Project->has_a(
    project_id => 'Chado::DBI::Chado::Project'
);

sub Chado::DBI::Chado::Assay_Project::project {
    return shift->project_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Biomaterial;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Biomaterial->set_up_table('biomaterial');


Chado::DBI::Chado::Biomaterial->has_a(
    taxon_id => 'Chado::DBI::Chado::Organism'
);

sub Chado::DBI::Chado::Biomaterial::taxon {
    return shift->taxon_id
}

Chado::DBI::Chado::Biomaterial->has_a(
    biosourceprovider_id => 'Chado::DBI::Chado::Contact'
);

sub Chado::DBI::Chado::Biomaterial::biosourceprovider {
    return shift->biosourceprovider_id
}

Chado::DBI::Chado::Biomaterial->has_a(
    dbxref_id => 'Chado::DBI::Chado::Dbxref'
);

sub Chado::DBI::Chado::Biomaterial::dbxref {
    return shift->dbxref_id
}

sub biomaterial_relationship_subject_ids { my $self = shift; return $self->biomaterial_relationship_subject_id(@_) }

sub biomaterial_relationship_object_ids { my $self = shift; return $self->biomaterial_relationship_object_id(@_) }

Chado::DBI::Chado::Biomaterial->has_many(
    'treatment_biomaterial_id', 'Chado::DBI::Chado::Treatment' => 'biomaterial_id'
);

Chado::DBI::Chado::Biomaterial->has_many(
    'biomaterialprop_biomaterial_id', 'Chado::DBI::Chado::Biomaterialprop' => 'biomaterial_id'
);

Chado::DBI::Chado::Biomaterial->has_many(
    'assay_biomaterial_biomaterial_id', 'Chado::DBI::Chado::Assay_Biomaterial' => 'biomaterial_id'
);

Chado::DBI::Chado::Biomaterial->has_many(
    'biomaterial_dbxref_biomaterial_id', 'Chado::DBI::Chado::Biomaterial_Dbxref' => 'biomaterial_id'
);

Chado::DBI::Chado::Biomaterial->has_many(
    'biomaterial_treatment_biomaterial_id', 'Chado::DBI::Chado::Biomaterial_Treatment' => 'biomaterial_id'
);

Chado::DBI::Chado::Biomaterial->has_many(
    'biomaterial_relationship_subject_id', 'Chado::DBI::Chado::Biomaterial_Relationship' => 'subject_id'
);

Chado::DBI::Chado::Biomaterial->has_many(
    'biomaterial_relationship_object_id', 'Chado::DBI::Chado::Biomaterial_Relationship' => 'object_id'
);

sub dbxrefs { my $self = shift; return map $_->dbxref_id, $self->biomaterial_dbxref_biomaterial_id }

# -------------------------------------------------------------------
package Chado::DBI::Chado::Biomaterial_Relationship;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Biomaterial_Relationship->set_up_table('biomaterial_relationship');


Chado::DBI::Chado::Biomaterial_Relationship->has_a(
    subject_id => 'Chado::DBI::Chado::Biomaterial'
);

sub Chado::DBI::Chado::Biomaterial_Relationship::subject {
    return shift->subject_id
}

Chado::DBI::Chado::Biomaterial_Relationship->has_a(
    type_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Biomaterial_Relationship::type {
    return shift->type_id
}

Chado::DBI::Chado::Biomaterial_Relationship->has_a(
    object_id => 'Chado::DBI::Chado::Biomaterial'
);

sub Chado::DBI::Chado::Biomaterial_Relationship::object {
    return shift->object_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Biomaterialprop;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Biomaterialprop->set_up_table('biomaterialprop');


Chado::DBI::Chado::Biomaterialprop->has_a(
    biomaterial_id => 'Chado::DBI::Chado::Biomaterial'
);

sub Chado::DBI::Chado::Biomaterialprop::biomaterial {
    return shift->biomaterial_id
}

Chado::DBI::Chado::Biomaterialprop->has_a(
    type_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Biomaterialprop::type {
    return shift->type_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Biomaterial_Dbxref;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Biomaterial_Dbxref->set_up_table('biomaterial_dbxref');


Chado::DBI::Chado::Biomaterial_Dbxref->has_a(
    biomaterial_id => 'Chado::DBI::Chado::Biomaterial'
);

sub Chado::DBI::Chado::Biomaterial_Dbxref::biomaterial {
    return shift->biomaterial_id
}

Chado::DBI::Chado::Biomaterial_Dbxref->has_a(
    dbxref_id => 'Chado::DBI::Chado::Dbxref'
);

sub Chado::DBI::Chado::Biomaterial_Dbxref::dbxref {
    return shift->dbxref_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Treatment;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Treatment->set_up_table('treatment');


Chado::DBI::Chado::Treatment->has_a(
    biomaterial_id => 'Chado::DBI::Chado::Biomaterial'
);

sub Chado::DBI::Chado::Treatment::biomaterial {
    return shift->biomaterial_id
}

Chado::DBI::Chado::Treatment->has_a(
    type_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Treatment::type {
    return shift->type_id
}

Chado::DBI::Chado::Treatment->has_a(
    protocol_id => 'Chado::DBI::Chado::Protocol'
);

sub Chado::DBI::Chado::Treatment::protocol {
    return shift->protocol_id
}

Chado::DBI::Chado::Treatment->has_many(
    'biomaterial_treatment_treatment_id', 'Chado::DBI::Chado::Biomaterial_Treatment' => 'treatment_id'
);

# -------------------------------------------------------------------
package Chado::DBI::Chado::Biomaterial_Treatment;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Biomaterial_Treatment->set_up_table('biomaterial_treatment');


Chado::DBI::Chado::Biomaterial_Treatment->has_a(
    biomaterial_id => 'Chado::DBI::Chado::Biomaterial'
);

sub Chado::DBI::Chado::Biomaterial_Treatment::biomaterial {
    return shift->biomaterial_id
}

Chado::DBI::Chado::Biomaterial_Treatment->has_a(
    treatment_id => 'Chado::DBI::Chado::Treatment'
);

sub Chado::DBI::Chado::Biomaterial_Treatment::treatment {
    return shift->treatment_id
}

Chado::DBI::Chado::Biomaterial_Treatment->has_a(
    unittype_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Biomaterial_Treatment::unittype {
    return shift->unittype_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Assay_Biomaterial;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Assay_Biomaterial->set_up_table('assay_biomaterial');


Chado::DBI::Chado::Assay_Biomaterial->has_a(
    assay_id => 'Chado::DBI::Chado::Assay'
);

sub Chado::DBI::Chado::Assay_Biomaterial::assay {
    return shift->assay_id
}

Chado::DBI::Chado::Assay_Biomaterial->has_a(
    biomaterial_id => 'Chado::DBI::Chado::Biomaterial'
);

sub Chado::DBI::Chado::Assay_Biomaterial::biomaterial {
    return shift->biomaterial_id
}

Chado::DBI::Chado::Assay_Biomaterial->has_a(
    channel_id => 'Chado::DBI::Chado::Channel'
);

sub Chado::DBI::Chado::Assay_Biomaterial::channel {
    return shift->channel_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Acquisition;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Acquisition->set_up_table('acquisition');


Chado::DBI::Chado::Acquisition->has_a(
    assay_id => 'Chado::DBI::Chado::Assay'
);

sub Chado::DBI::Chado::Acquisition::assay {
    return shift->assay_id
}

Chado::DBI::Chado::Acquisition->has_a(
    protocol_id => 'Chado::DBI::Chado::Protocol'
);

sub Chado::DBI::Chado::Acquisition::protocol {
    return shift->protocol_id
}

Chado::DBI::Chado::Acquisition->has_a(
    channel_id => 'Chado::DBI::Chado::Channel'
);

sub Chado::DBI::Chado::Acquisition::channel {
    return shift->channel_id
}

Chado::DBI::Chado::Acquisition->has_many(
    'acquisition_relationship_subject_id', 'Chado::DBI::Chado::Acquisition_Relationship' => 'subject_id'
);

Chado::DBI::Chado::Acquisition->has_many(
    'acquisition_relationship_object_id', 'Chado::DBI::Chado::Acquisition_Relationship' => 'object_id'
);

Chado::DBI::Chado::Acquisition->has_many(
    'acquisitionprop_acquisition_id', 'Chado::DBI::Chado::Acquisitionprop' => 'acquisition_id'
);

Chado::DBI::Chado::Acquisition->has_many(
    'quantification_acquisition_id', 'Chado::DBI::Chado::Quantification' => 'acquisition_id'
);

# -------------------------------------------------------------------
package Chado::DBI::Chado::Acquisitionprop;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Acquisitionprop->set_up_table('acquisitionprop');


Chado::DBI::Chado::Acquisitionprop->has_a(
    acquisition_id => 'Chado::DBI::Chado::Acquisition'
);

sub Chado::DBI::Chado::Acquisitionprop::acquisition {
    return shift->acquisition_id
}

Chado::DBI::Chado::Acquisitionprop->has_a(
    type_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Acquisitionprop::type {
    return shift->type_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Acquisition_Relationship;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Acquisition_Relationship->set_up_table('acquisition_relationship');


Chado::DBI::Chado::Acquisition_Relationship->has_a(
    subject_id => 'Chado::DBI::Chado::Acquisition'
);

sub Chado::DBI::Chado::Acquisition_Relationship::subject {
    return shift->subject_id
}

Chado::DBI::Chado::Acquisition_Relationship->has_a(
    type_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Acquisition_Relationship::type {
    return shift->type_id
}

Chado::DBI::Chado::Acquisition_Relationship->has_a(
    object_id => 'Chado::DBI::Chado::Acquisition'
);

sub Chado::DBI::Chado::Acquisition_Relationship::object {
    return shift->object_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Quantification;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Quantification->set_up_table('quantification');


Chado::DBI::Chado::Quantification->has_a(
    acquisition_id => 'Chado::DBI::Chado::Acquisition'
);

sub Chado::DBI::Chado::Quantification::acquisition {
    return shift->acquisition_id
}

Chado::DBI::Chado::Quantification->has_a(
    operator_id => 'Chado::DBI::Chado::Contact'
);

sub Chado::DBI::Chado::Quantification::operator {
    return shift->operator_id
}

Chado::DBI::Chado::Quantification->has_a(
    protocol_id => 'Chado::DBI::Chado::Protocol'
);

sub Chado::DBI::Chado::Quantification::protocol {
    return shift->protocol_id
}

Chado::DBI::Chado::Quantification->has_a(
    analysis_id => 'Chado::DBI::Chado::Analysis'
);

sub Chado::DBI::Chado::Quantification::analysis {
    return shift->analysis_id
}

Chado::DBI::Chado::Quantification->has_many(
    'elementresult_quantification_id', 'Chado::DBI::Chado::Elementresult' => 'quantification_id'
);

Chado::DBI::Chado::Quantification->has_many(
    'quantificationprop_quantification_id', 'Chado::DBI::Chado::Quantificationprop' => 'quantification_id'
);

Chado::DBI::Chado::Quantification->has_many(
    'quantification_relationship_subject_id', 'Chado::DBI::Chado::Quantification_Relationship' => 'subject_id'
);

Chado::DBI::Chado::Quantification->has_many(
    'quantification_relationship_object_id', 'Chado::DBI::Chado::Quantification_Relationship' => 'object_id'
);

sub quantification_relationship_subject_ids { my $self = shift; return $self->quantification_relationship_subject_id(@_) }

sub quantification_relationship_object_ids { my $self = shift; return $self->quantification_relationship_object_id(@_) }

# -------------------------------------------------------------------
package Chado::DBI::Chado::Quantificationprop;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Quantificationprop->set_up_table('quantificationprop');


Chado::DBI::Chado::Quantificationprop->has_a(
    quantification_id => 'Chado::DBI::Chado::Quantification'
);

sub Chado::DBI::Chado::Quantificationprop::quantification {
    return shift->quantification_id
}

Chado::DBI::Chado::Quantificationprop->has_a(
    type_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Quantificationprop::type {
    return shift->type_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Quantification_Relationship;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Quantification_Relationship->set_up_table('quantification_relationship');


Chado::DBI::Chado::Quantification_Relationship->has_a(
    subject_id => 'Chado::DBI::Chado::Quantification'
);

sub Chado::DBI::Chado::Quantification_Relationship::subject {
    return shift->subject_id
}

Chado::DBI::Chado::Quantification_Relationship->has_a(
    type_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Quantification_Relationship::type {
    return shift->type_id
}

Chado::DBI::Chado::Quantification_Relationship->has_a(
    object_id => 'Chado::DBI::Chado::Quantification'
);

sub Chado::DBI::Chado::Quantification_Relationship::object {
    return shift->object_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Control;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Control->set_up_table('control');


Chado::DBI::Chado::Control->has_a(
    type_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Control::type {
    return shift->type_id
}

Chado::DBI::Chado::Control->has_a(
    assay_id => 'Chado::DBI::Chado::Assay'
);

sub Chado::DBI::Chado::Control::assay {
    return shift->assay_id
}

Chado::DBI::Chado::Control->has_a(
    tableinfo_id => 'Chado::DBI::Chado::Tableinfo'
);

sub Chado::DBI::Chado::Control::tableinfo {
    return shift->tableinfo_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Element;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Element->set_up_table('element');


Chado::DBI::Chado::Element->has_a(
    feature_id => 'Chado::DBI::Chado::Feature'
);

sub Chado::DBI::Chado::Element::feature {
    return shift->feature_id
}

Chado::DBI::Chado::Element->has_a(
    arraydesign_id => 'Chado::DBI::Chado::Arraydesign'
);

sub Chado::DBI::Chado::Element::arraydesign {
    return shift->arraydesign_id
}

Chado::DBI::Chado::Element->has_a(
    type_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Element::type {
    return shift->type_id
}

Chado::DBI::Chado::Element->has_a(
    dbxref_id => 'Chado::DBI::Chado::Dbxref'
);

sub Chado::DBI::Chado::Element::dbxref {
    return shift->dbxref_id
}

Chado::DBI::Chado::Element->has_many(
    'elementresult_element_id', 'Chado::DBI::Chado::Elementresult' => 'element_id'
);

Chado::DBI::Chado::Element->has_many(
    'element_relationship_subject_id', 'Chado::DBI::Chado::Element_Relationship' => 'subject_id'
);

Chado::DBI::Chado::Element->has_many(
    'element_relationship_object_id', 'Chado::DBI::Chado::Element_Relationship' => 'object_id'
);

# -------------------------------------------------------------------
package Chado::DBI::Chado::Elementresult;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Elementresult->set_up_table('elementresult');


Chado::DBI::Chado::Elementresult->has_a(
    element_id => 'Chado::DBI::Chado::Element'
);

sub Chado::DBI::Chado::Elementresult::element {
    return shift->element_id
}

Chado::DBI::Chado::Elementresult->has_a(
    quantification_id => 'Chado::DBI::Chado::Quantification'
);

sub Chado::DBI::Chado::Elementresult::quantification {
    return shift->quantification_id
}

Chado::DBI::Chado::Elementresult->has_many(
    'elementresult_relationship_subject_id', 'Chado::DBI::Chado::Elementresult_Relationship' => 'subject_id'
);

Chado::DBI::Chado::Elementresult->has_many(
    'elementresult_relationship_object_id', 'Chado::DBI::Chado::Elementresult_Relationship' => 'object_id'
);

# -------------------------------------------------------------------
package Chado::DBI::Chado::Element_Relationship;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Element_Relationship->set_up_table('element_relationship');


Chado::DBI::Chado::Element_Relationship->has_a(
    subject_id => 'Chado::DBI::Chado::Element'
);

sub Chado::DBI::Chado::Element_Relationship::subject {
    return shift->subject_id
}

Chado::DBI::Chado::Element_Relationship->has_a(
    type_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Element_Relationship::type {
    return shift->type_id
}

Chado::DBI::Chado::Element_Relationship->has_a(
    object_id => 'Chado::DBI::Chado::Element'
);

sub Chado::DBI::Chado::Element_Relationship::object {
    return shift->object_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Elementresult_Relationship;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Elementresult_Relationship->set_up_table('elementresult_relationship');


Chado::DBI::Chado::Elementresult_Relationship->has_a(
    subject_id => 'Chado::DBI::Chado::Elementresult'
);

sub Chado::DBI::Chado::Elementresult_Relationship::subject {
    return shift->subject_id
}

Chado::DBI::Chado::Elementresult_Relationship->has_a(
    type_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Elementresult_Relationship::type {
    return shift->type_id
}

Chado::DBI::Chado::Elementresult_Relationship->has_a(
    object_id => 'Chado::DBI::Chado::Elementresult'
);

sub Chado::DBI::Chado::Elementresult_Relationship::object {
    return shift->object_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Study;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Study->set_up_table('study');


Chado::DBI::Chado::Study->has_a(
    contact_id => 'Chado::DBI::Chado::Contact'
);

sub Chado::DBI::Chado::Study::contact {
    return shift->contact_id
}

Chado::DBI::Chado::Study->has_a(
    pub_id => 'Chado::DBI::Chado::Pub'
);

sub Chado::DBI::Chado::Study::pub {
    return shift->pub_id
}

Chado::DBI::Chado::Study->has_a(
    dbxref_id => 'Chado::DBI::Chado::Dbxref'
);

sub Chado::DBI::Chado::Study::dbxref {
    return shift->dbxref_id
}

Chado::DBI::Chado::Study->has_many(
    'studydesign_study_id', 'Chado::DBI::Chado::Studydesign' => 'study_id'
);

sub assays { my $self = shift; return map $_->assay_id, $self->study_assay_study_id }

Chado::DBI::Chado::Study->has_many(
    'study_assay_study_id', 'Chado::DBI::Chado::Study_Assay' => 'study_id'
);

# -------------------------------------------------------------------
package Chado::DBI::Chado::Study_Assay;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Study_Assay->set_up_table('study_assay');


Chado::DBI::Chado::Study_Assay->has_a(
    study_id => 'Chado::DBI::Chado::Study'
);

sub Chado::DBI::Chado::Study_Assay::study {
    return shift->study_id
}

Chado::DBI::Chado::Study_Assay->has_a(
    assay_id => 'Chado::DBI::Chado::Assay'
);

sub Chado::DBI::Chado::Study_Assay::assay {
    return shift->assay_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Studydesign;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Studydesign->set_up_table('studydesign');


Chado::DBI::Chado::Studydesign->has_a(
    study_id => 'Chado::DBI::Chado::Study'
);

sub Chado::DBI::Chado::Studydesign::study {
    return shift->study_id
}

Chado::DBI::Chado::Studydesign->has_many(
    'studydesignprop_studydesign_id', 'Chado::DBI::Chado::Studydesignprop' => 'studydesign_id'
);

Chado::DBI::Chado::Studydesign->has_many(
    'studyfactor_studydesign_id', 'Chado::DBI::Chado::Studyfactor' => 'studydesign_id'
);

# -------------------------------------------------------------------
package Chado::DBI::Chado::Studydesignprop;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Studydesignprop->set_up_table('studydesignprop');


Chado::DBI::Chado::Studydesignprop->has_a(
    studydesign_id => 'Chado::DBI::Chado::Studydesign'
);

sub Chado::DBI::Chado::Studydesignprop::studydesign {
    return shift->studydesign_id
}

Chado::DBI::Chado::Studydesignprop->has_a(
    type_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Studydesignprop::type {
    return shift->type_id
}

# -------------------------------------------------------------------
package Chado::DBI::Chado::Studyfactor;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Studyfactor->set_up_table('studyfactor');


Chado::DBI::Chado::Studyfactor->has_a(
    studydesign_id => 'Chado::DBI::Chado::Studydesign'
);

sub Chado::DBI::Chado::Studyfactor::studydesign {
    return shift->studydesign_id
}

Chado::DBI::Chado::Studyfactor->has_a(
    type_id => 'Chado::DBI::Chado::Cvterm'
);

sub Chado::DBI::Chado::Studyfactor::type {
    return shift->type_id
}

Chado::DBI::Chado::Studyfactor->has_many(
    'studyfactorvalue_studyfactor_id', 'Chado::DBI::Chado::Studyfactorvalue' => 'studyfactor_id'
);

# -------------------------------------------------------------------
package Chado::DBI::Chado::Studyfactorvalue;
use base 'Chado::DBI';
use Class::DBI::Pager;

Chado::DBI::Chado::Studyfactorvalue->set_up_table('studyfactorvalue');


Chado::DBI::Chado::Studyfactorvalue->has_a(
    studyfactor_id => 'Chado::DBI::Chado::Studyfactor'
);

sub Chado::DBI::Chado::Studyfactorvalue::studyfactor {
    return shift->studyfactor_id
}

Chado::DBI::Chado::Studyfactorvalue->has_a(
    assay_id => 'Chado::DBI::Chado::Assay'
);

sub Chado::DBI::Chado::Studyfactorvalue::assay {
    return shift->assay_id
}

1;
!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
