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
Chado::DBI->set_db('Main', 'dbi:Pg:dbname=$OPTIONS{'DBNAME'}', '$OPTIONS{'DBUSER'}', '$OPTIONS{'DBPASS'}');

sub search_ilike { shift->_do_search(ILIKE => @_ ) }

!GROK!THIS!

print OUT <<'!NO!SUBS!';
# --------------------------------------------
package Chado::Acquisition;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Acquisition->set_up_table('acquisition');
#
# Primary key accessors
#
sub id { shift->acquisition_id }sub acquisition { shift->acquisition_id }

#
# Has A
#
Chado::Acquisition->has_a(assay_id => 'Chado::Assay');
sub assay { return shift->assay_id }Chado::Acquisition->has_a(protocol_id => 'Chado::Protocol');
sub protocol { return shift->protocol_id }Chado::Acquisition->has_a(channel_id => 'Chado::Channel');
sub channel { return shift->channel_id }

#
# Has Many
#
Chado::Acquisition->has_many('acquisitionprop_acquisition_id', 'Chado::Acquisitionprop' => 'acquisition_id');
sub acquisitionprops { return shift->acquisitionprop_acquisition_id }
Chado::Acquisition->has_many('quantification_acquisition_id', 'Chado::Quantification' => 'acquisition_id');
sub quantifications { return shift->quantification_acquisition_id }
Chado::Acquisition->has_many('acquisition_relationship_subject_id', 'Chado::Acquisition_Relationship' => 'subject_id');
Chado::Acquisition->has_many('acquisition_relationship_object_id', 'Chado::Acquisition_Relationship' => 'object_id');


#
# Has Compound Many
#
sub acquisition_relationship_subjects { return shift->acquisition_relationship_subject_id }
sub acquisition_relationship_objects { return shift->acquisition_relationship_object_id }


########## many2one ##########
#Chado::Acquisition::acquisition_id -> Chado::Acquisition_Relationship::subject_id ... Chado::Acquisition_Relationship::type_id <- Chado::Cvterm::cvterm_id
sub acquisition_relationship_subject_types { my $self = shift; return map $_->type_id, $self->acquisition_relationship_subject_id }
#Chado::Acquisition::acquisition_id -> Chado::Acquisition_Relationship::object_id ... Chado::Acquisition_Relationship::type_id <- Chado::Cvterm::cvterm_id
sub acquisition_relationship_object_types { my $self = shift; return map $_->type_id, $self->acquisition_relationship_object_id }


# --------------------------------------------

package Chado::Acquisition_Relationship;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Acquisition_Relationship->set_up_table('acquisition_relationship');
#
# Primary key accessors
#
sub id { shift->acquisition_relationship_id }sub acquisition_relationship { shift->acquisition_relationship_id }

#
# Has A
#
Chado::Acquisition_Relationship->has_a(subject_id => 'Chado::Acquisition');
sub subject { return shift->subject_id }Chado::Acquisition_Relationship->has_a(type_id => 'Chado::Cvterm');
sub cvterm { return shift->type_id }Chado::Acquisition_Relationship->has_a(object_id => 'Chado::Acquisition');
sub object { return shift->object_id }

#
# Has Many
#







# --------------------------------------------

package Chado::Acquisitionprop;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Acquisitionprop->set_up_table('acquisitionprop');
#
# Primary key accessors
#
sub id { shift->acquisitionprop_id }sub acquisitionprop { shift->acquisitionprop_id }

#
# Has A
#
Chado::Acquisitionprop->has_a(acquisition_id => 'Chado::Acquisition');
sub acquisition { return shift->acquisition_id }Chado::Acquisitionprop->has_a(type_id => 'Chado::Cvterm');
sub cvterm { return shift->type_id }

#
# Has Many
#







# --------------------------------------------

package Chado::Analysis;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Analysis->set_up_table('analysis');
#
# Primary key accessors
#
sub id { shift->analysis_id }sub analysis { shift->analysis_id }

#
# Has A
#


#
# Has Many
#
Chado::Analysis->has_many('quantification_analysis_id', 'Chado::Quantification' => 'analysis_id');
sub quantifications { return shift->quantification_analysis_id }
Chado::Analysis->has_many('analysisprop_analysis_id', 'Chado::Analysisprop' => 'analysis_id');
sub analysisprops { return shift->analysisprop_analysis_id }
Chado::Analysis->has_many('analysisfeature_analysis_id', 'Chado::Analysisfeature' => 'analysis_id');
sub analysisfeatures { return shift->analysisfeature_analysis_id }







# --------------------------------------------

package Chado::Analysisfeature;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Analysisfeature->set_up_table('analysisfeature');
#
# Primary key accessors
#
sub id { shift->analysisfeature_id }sub analysisfeature { shift->analysisfeature_id }

#
# Has A
#
Chado::Analysisfeature->has_a(feature_id => 'Chado::Feature');
sub feature { return shift->feature_id }Chado::Analysisfeature->has_a(analysis_id => 'Chado::Analysis');
sub analysis { return shift->analysis_id }

#
# Has Many
#







# --------------------------------------------

package Chado::Analysisprop;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Analysisprop->set_up_table('analysisprop');
#
# Primary key accessors
#
sub id { shift->analysisprop_id }sub analysisprop { shift->analysisprop_id }

#
# Has A
#
Chado::Analysisprop->has_a(analysis_id => 'Chado::Analysis');
sub analysis { return shift->analysis_id }Chado::Analysisprop->has_a(type_id => 'Chado::Cvterm');
sub cvterm { return shift->type_id }

#
# Has Many
#







# --------------------------------------------

package Chado::Arraydesign;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Arraydesign->set_up_table('arraydesign');
#
# Primary key accessors
#
sub id { shift->arraydesign_id }sub arraydesign { shift->arraydesign_id }

#
# Has A
#
Chado::Arraydesign->has_a(manufacturer_id => 'Chado::Contact');
sub contact { return shift->manufacturer_id }Chado::Arraydesign->has_a(platformtype_id => 'Chado::Cvterm');
sub platformtype { return shift->platformtype_id }Chado::Arraydesign->has_a(substratetype_id => 'Chado::Cvterm');
sub substratetype { return shift->substratetype_id }Chado::Arraydesign->has_a(protocol_id => 'Chado::Protocol');
sub protocol { return shift->protocol_id }Chado::Arraydesign->has_a(dbxref_id => 'Chado::Dbxref');
sub dbxref { return shift->dbxref_id }

#
# Has Many
#
Chado::Arraydesign->has_many('element_arraydesign_id', 'Chado::Element' => 'arraydesign_id');
sub elements { return shift->element_arraydesign_id }
Chado::Arraydesign->has_many('assay_arraydesign_id', 'Chado::Assay' => 'arraydesign_id');
sub assays { return shift->assay_arraydesign_id }
Chado::Arraydesign->has_many('arrayprop_arraydesign_id', 'Chado::Arrayprop' => 'arraydesign_id');
sub arrayprops { return shift->arrayprop_arraydesign_id }







# --------------------------------------------

package Chado::Arrayprop;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Arrayprop->set_up_table('arrayprop');
#
# Primary key accessors
#
sub id { shift->arrayprop_id }sub arrayprop { shift->arrayprop_id }

#
# Has A
#
Chado::Arrayprop->has_a(arraydesign_id => 'Chado::Arraydesign');
sub arraydesign { return shift->arraydesign_id }Chado::Arrayprop->has_a(type_id => 'Chado::Cvterm');
sub cvterm { return shift->type_id }

#
# Has Many
#







# --------------------------------------------

package Chado::Assay;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Assay->set_up_table('assay');
#
# Primary key accessors
#
sub id { shift->assay_id }sub assay { shift->assay_id }

#
# Has A
#
Chado::Assay->has_a(arraydesign_id => 'Chado::Arraydesign');
sub arraydesign { return shift->arraydesign_id }Chado::Assay->has_a(protocol_id => 'Chado::Protocol');
sub protocol { return shift->protocol_id }Chado::Assay->has_a(operator_id => 'Chado::Contact');
sub contact { return shift->operator_id }Chado::Assay->has_a(dbxref_id => 'Chado::Dbxref');
sub dbxref { return shift->dbxref_id }

#
# Has Many
#
Chado::Assay->has_many('studyfactorvalue_assay_id', 'Chado::Studyfactorvalue' => 'assay_id');
sub studyfactorvalues { return shift->studyfactorvalue_assay_id }
Chado::Assay->has_many('control_assay_id', 'Chado::Control' => 'assay_id');
sub controls { return shift->control_assay_id }
Chado::Assay->has_many('study_assay_assay_id', 'Chado::Study_Assay' => 'assay_id');
Chado::Assay->has_many('assay_project_assay_id', 'Chado::Assay_Project' => 'assay_id');
Chado::Assay->has_many('assayprop_assay_id', 'Chado::Assayprop' => 'assay_id');
sub assayprops { return shift->assayprop_assay_id }
Chado::Assay->has_many('assay_biomaterial_assay_id', 'Chado::Assay_Biomaterial' => 'assay_id');
Chado::Assay->has_many('acquisition_assay_id', 'Chado::Acquisition' => 'assay_id');
sub acquisitions { return shift->acquisition_assay_id }


#
# Has Compound Many
#
sub assay_project_assays { return shift->assay_project_assay_id }
sub study_assay_assays { return shift->study_assay_assay_id }
sub assay_biomaterial_assays { return shift->assay_biomaterial_assay_id }
sub assay_biomaterial_assays { return shift->assay_biomaterial_assay_id }
########## one2one ###########
sub projects { my $self = shift; return map $_->project_id, $self->assay_project_assay_id }
sub studys { my $self = shift; return map $_->study_id, $self->study_assay_assay_id }
sub biomaterials { my $self = shift; return map $_->biomaterial_id, $self->assay_biomaterial_assay_id }
sub channels { my $self = shift; return map $_->channel_id, $self->assay_biomaterial_assay_id }




# --------------------------------------------

package Chado::Assay_Biomaterial;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Assay_Biomaterial->set_up_table('assay_biomaterial');
#
# Primary key accessors
#
sub id { shift->assay_biomaterial_id }sub assay_biomaterial { shift->assay_biomaterial_id }

#
# Has A
#
Chado::Assay_Biomaterial->has_a(assay_id => 'Chado::Assay');
sub assay { return shift->assay_id }Chado::Assay_Biomaterial->has_a(biomaterial_id => 'Chado::Biomaterial');
sub biomaterial { return shift->biomaterial_id }Chado::Assay_Biomaterial->has_a(channel_id => 'Chado::Channel');
sub channel { return shift->channel_id }

#
# Has Many
#







# --------------------------------------------

package Chado::Assay_Project;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Assay_Project->set_up_table('assay_project');
#
# Primary key accessors
#
sub id { shift->assay_project_id }sub assay_project { shift->assay_project_id }

#
# Has A
#
Chado::Assay_Project->has_a(assay_id => 'Chado::Assay');
sub assay { return shift->assay_id }Chado::Assay_Project->has_a(project_id => 'Chado::Project');
sub project { return shift->project_id }

#
# Has Many
#







# --------------------------------------------

package Chado::Assayprop;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Assayprop->set_up_table('assayprop');
#
# Primary key accessors
#
sub id { shift->assayprop_id }sub assayprop { shift->assayprop_id }

#
# Has A
#
Chado::Assayprop->has_a(assay_id => 'Chado::Assay');
sub assay { return shift->assay_id }Chado::Assayprop->has_a(type_id => 'Chado::Cvterm');
sub cvterm { return shift->type_id }

#
# Has Many
#







# --------------------------------------------

package Chado::Author;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Author->set_up_table('author');
#
# Primary key accessors
#
sub id { shift->author_id }sub author { shift->author_id }

#
# Has A
#
Chado::Author->has_a(contact_id => 'Chado::Contact');
sub contact { return shift->contact_id }

#
# Has Many
#
Chado::Author->has_many('pub_author_author_id', 'Chado::Pub_Author' => 'author_id');
sub pub_authors { return shift->pub_author_author_id }







# --------------------------------------------

package Chado::Biomaterial;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Biomaterial->set_up_table('biomaterial');
#
# Primary key accessors
#
sub id { shift->biomaterial_id }sub biomaterial { shift->biomaterial_id }

#
# Has A
#
Chado::Biomaterial->has_a(taxon_id => 'Chado::Organism');
sub organism { return shift->taxon_id }Chado::Biomaterial->has_a(biosourceprovider_id => 'Chado::Contact');
sub contact { return shift->biosourceprovider_id }Chado::Biomaterial->has_a(dbxref_id => 'Chado::Dbxref');
sub dbxref { return shift->dbxref_id }

#
# Has Many
#
Chado::Biomaterial->has_many('biomaterial_treatment_biomaterial_id', 'Chado::Biomaterial_Treatment' => 'biomaterial_id');
sub biomaterial_treatments { return shift->biomaterial_treatment_biomaterial_id }
Chado::Biomaterial->has_many('assay_biomaterial_biomaterial_id', 'Chado::Assay_Biomaterial' => 'biomaterial_id');
Chado::Biomaterial->has_many('biomaterialprop_biomaterial_id', 'Chado::Biomaterialprop' => 'biomaterial_id');
sub biomaterialprops { return shift->biomaterialprop_biomaterial_id }
Chado::Biomaterial->has_many('treatment_biomaterial_id', 'Chado::Treatment' => 'biomaterial_id');
sub treatments { return shift->treatment_biomaterial_id }
Chado::Biomaterial->has_many('biomaterial_relationship_subject_id', 'Chado::Biomaterial_Relationship' => 'subject_id');
Chado::Biomaterial->has_many('biomaterial_relationship_object_id', 'Chado::Biomaterial_Relationship' => 'object_id');


#
# Has Compound Many
#
sub biomaterial_relationship_subjects { return shift->biomaterial_relationship_subject_id }
sub biomaterial_relationship_objects { return shift->biomaterial_relationship_object_id }
sub assay_biomaterial_biomaterials { return shift->assay_biomaterial_biomaterial_id }
sub assay_biomaterial_biomaterials { return shift->assay_biomaterial_biomaterial_id }
########## one2one ###########
sub assays { my $self = shift; return map $_->assay_id, $self->assay_biomaterial_biomaterial_id }
sub channels { my $self = shift; return map $_->channel_id, $self->assay_biomaterial_biomaterial_id }

########## many2one ##########
#Chado::Biomaterial::biomaterial_id -> Chado::Biomaterial_Relationship::subject_id ... Chado::Biomaterial_Relationship::type_id <- Chado::Cvterm::cvterm_id
sub biomaterial_relationship_subject_types { my $self = shift; return map $_->type_id, $self->biomaterial_relationship_subject_id }
#Chado::Biomaterial::biomaterial_id -> Chado::Biomaterial_Relationship::object_id ... Chado::Biomaterial_Relationship::type_id <- Chado::Cvterm::cvterm_id
sub biomaterial_relationship_object_types { my $self = shift; return map $_->type_id, $self->biomaterial_relationship_object_id }


# --------------------------------------------

package Chado::Biomaterial_Relationship;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Biomaterial_Relationship->set_up_table('biomaterial_relationship');
#
# Primary key accessors
#
sub id { shift->biomaterial_relationship_id }sub biomaterial_relationship { shift->biomaterial_relationship_id }

#
# Has A
#
Chado::Biomaterial_Relationship->has_a(subject_id => 'Chado::Biomaterial');
sub subject { return shift->subject_id }Chado::Biomaterial_Relationship->has_a(type_id => 'Chado::Cvterm');
sub cvterm { return shift->type_id }Chado::Biomaterial_Relationship->has_a(object_id => 'Chado::Biomaterial');
sub object { return shift->object_id }

#
# Has Many
#







# --------------------------------------------

package Chado::Biomaterial_Treatment;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Biomaterial_Treatment->set_up_table('biomaterial_treatment');
#
# Primary key accessors
#
sub id { shift->biomaterial_treatment_id }sub biomaterial_treatment { shift->biomaterial_treatment_id }

#
# Has A
#
Chado::Biomaterial_Treatment->has_a(biomaterial_id => 'Chado::Biomaterial');
sub biomaterial { return shift->biomaterial_id }Chado::Biomaterial_Treatment->has_a(treatment_id => 'Chado::Treatment');
sub treatment { return shift->treatment_id }Chado::Biomaterial_Treatment->has_a(unittype_id => 'Chado::Cvterm');
sub cvterm { return shift->unittype_id }

#
# Has Many
#







# --------------------------------------------

package Chado::Biomaterialprop;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Biomaterialprop->set_up_table('biomaterialprop');
#
# Primary key accessors
#
sub id { shift->biomaterialprop_id }sub biomaterialprop { shift->biomaterialprop_id }

#
# Has A
#
Chado::Biomaterialprop->has_a(biomaterial_id => 'Chado::Biomaterial');
sub biomaterial { return shift->biomaterial_id }Chado::Biomaterialprop->has_a(type_id => 'Chado::Cvterm');
sub cvterm { return shift->type_id }

#
# Has Many
#







# --------------------------------------------

package Chado::Channel;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Channel->set_up_table('channel');
#
# Primary key accessors
#
sub id { shift->channel_id }sub channel { shift->channel_id }

#
# Has A
#


#
# Has Many
#
Chado::Channel->has_many('assay_biomaterial_channel_id', 'Chado::Assay_Biomaterial' => 'channel_id');
Chado::Channel->has_many('acquisition_channel_id', 'Chado::Acquisition' => 'channel_id');
sub acquisitions { return shift->acquisition_channel_id }


#
# Has Compound Many
#
sub assay_biomaterial_channels { return shift->assay_biomaterial_channel_id }
sub assay_biomaterial_channels { return shift->assay_biomaterial_channel_id }
########## one2one ###########
sub biomaterials { my $self = shift; return map $_->biomaterial_id, $self->assay_biomaterial_channel_id }
sub assays { my $self = shift; return map $_->assay_id, $self->assay_biomaterial_channel_id }




# --------------------------------------------

package Chado::Contact;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Contact->set_up_table('contact');
#
# Primary key accessors
#
sub id { shift->contact_id }sub contact { shift->contact_id }

#
# Has A
#


#
# Has Many
#
Chado::Contact->has_many('study_contact_id', 'Chado::Study' => 'contact_id');
sub studys { return shift->study_contact_id }
Chado::Contact->has_many('arraydesign_manufacturer_id', 'Chado::Arraydesign' => 'manufacturer_id');
sub arraydesigns { return shift->arraydesign_manufacturer_id }
Chado::Contact->has_many('db_contact_id', 'Chado::Db' => 'contact_id');
sub dbs { return shift->db_contact_id }
Chado::Contact->has_many('quantification_operator_id', 'Chado::Quantification' => 'operator_id');
sub quantifications { return shift->quantification_operator_id }
Chado::Contact->has_many('assay_operator_id', 'Chado::Assay' => 'operator_id');
sub assays { return shift->assay_operator_id }
Chado::Contact->has_many('biomaterial_biosourceprovider_id', 'Chado::Biomaterial' => 'biosourceprovider_id');
sub biomaterials { return shift->biomaterial_biosourceprovider_id }
Chado::Contact->has_many('author_contact_id', 'Chado::Author' => 'contact_id');
sub authors { return shift->author_contact_id }







# --------------------------------------------

package Chado::Control;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Control->set_up_table('control');
#
# Primary key accessors
#
sub id { shift->control_id }sub control { shift->control_id }

#
# Has A
#
Chado::Control->has_a(type_id => 'Chado::Cvterm');
sub cvterm { return shift->type_id }Chado::Control->has_a(assay_id => 'Chado::Assay');
sub assay { return shift->assay_id }Chado::Control->has_a(tableinfo_id => 'Chado::Tableinfo');
sub tableinfo { return shift->tableinfo_id }

#
# Has Many
#







# --------------------------------------------

package Chado::Cv;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Cv->set_up_table('cv');
#
# Primary key accessors
#
sub id { shift->cv_id }sub cv { shift->cv_id }

#
# Has A
#


#
# Has Many
#
Chado::Cv->has_many('cvterm_cv_id', 'Chado::Cvterm' => 'cv_id');
sub cvterms { return shift->cvterm_cv_id }
Chado::Cv->has_many('cvtermpath_cv_id', 'Chado::Cvtermpath' => 'cv_id');
sub cvtermpaths { return shift->cvtermpath_cv_id }







# --------------------------------------------

package Chado::Cvterm;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Cvterm->set_up_table('cvterm');
#
# Primary key accessors
#
sub id { shift->cvterm_id }sub cvterm { shift->cvterm_id }

#
# Has A
#
Chado::Cvterm->has_a(cv_id => 'Chado::Cv');
sub cv { return shift->cv_id }Chado::Cvterm->has_a(dbxref_id => 'Chado::Dbxref');
sub dbxref { return shift->dbxref_id }

#
# Has Many
#
Chado::Cvterm->has_many('gcontextprop_type_id', 'Chado::Gcontextprop' => 'type_id');
sub gcontextprops { return shift->gcontextprop_type_id }
Chado::Cvterm->has_many('cvtermsynonym_cvterm_id', 'Chado::Cvtermsynonym' => 'cvterm_id');
sub cvtermsynonyms { return shift->cvtermsynonym_cvterm_id }
Chado::Cvterm->has_many('cvterm_dbxref_cvterm_id', 'Chado::Cvterm_Dbxref' => 'cvterm_id');
Chado::Cvterm->has_many('acquisitionprop_type_id', 'Chado::Acquisitionprop' => 'type_id');
sub acquisitionprops { return shift->acquisitionprop_type_id }
Chado::Cvterm->has_many('arraydesign_platformtype_id', 'Chado::Arraydesign' => 'platformtype_id');
sub arraydesign_platformtypes { return shift->arraydesign_platformtype_id }
Chado::Cvterm->has_many('arraydesign_substratetype_id', 'Chado::Arraydesign' => 'substratetype_id');
sub arraydesign_substratetypes { return shift->arraydesign_substratetype_id }
Chado::Cvterm->has_many('control_type_id', 'Chado::Control' => 'type_id');
sub controls { return shift->control_type_id }
Chado::Cvterm->has_many('element_type_id', 'Chado::Element' => 'type_id');
sub elements { return shift->element_type_id }
Chado::Cvterm->has_many('protocol_type_id', 'Chado::Protocol' => 'type_id');
sub protocols { return shift->protocol_type_id }
Chado::Cvterm->has_many('analysisprop_type_id', 'Chado::Analysisprop' => 'type_id');
sub analysisprops { return shift->analysisprop_type_id }
Chado::Cvterm->has_many('cvtermpath_type_id', 'Chado::Cvtermpath' => 'type_id');
sub cvtermpath_types { return shift->cvtermpath_type_id }
Chado::Cvterm->has_many('cvtermpath_subject_id', 'Chado::Cvtermpath' => 'subject_id');
sub cvtermpath_subjects { return shift->cvtermpath_subject_id }
Chado::Cvterm->has_many('cvtermpath_object_id', 'Chado::Cvtermpath' => 'object_id');
sub cvtermpath_objects { return shift->cvtermpath_object_id }
Chado::Cvterm->has_many('organismprop_type_id', 'Chado::Organismprop' => 'type_id');
sub organismprops { return shift->organismprop_type_id }
Chado::Cvterm->has_many('elementresult_relationship_type_id', 'Chado::Elementresult_Relationship' => 'type_id');
sub elementresult_relationships { return shift->elementresult_relationship_type_id }
Chado::Cvterm->has_many('dbxrefprop_type_id', 'Chado::Dbxrefprop' => 'type_id');
sub dbxrefprops { return shift->dbxrefprop_type_id }
Chado::Cvterm->has_many('feature_relationship_type_id', 'Chado::Feature_Relationship' => 'type_id');
sub feature_relationships { return shift->feature_relationship_type_id }
Chado::Cvterm->has_many('phenstatement_cvterm_cvterm_id', 'Chado::Phenstatement_Cvterm' => 'cvterm_id');
Chado::Cvterm->has_many('feature_cvterm_cvterm_id', 'Chado::Feature_Cvterm' => 'cvterm_id');
Chado::Cvterm->has_many('studyfactor_type_id', 'Chado::Studyfactor' => 'type_id');
sub studyfactors { return shift->studyfactor_type_id }
Chado::Cvterm->has_many('phenstatement_prop_type_id', 'Chado::Phenstatement_Prop' => 'type_id');
sub phenstatement_props { return shift->phenstatement_prop_type_id }
Chado::Cvterm->has_many('biomaterial_treatment_unittype_id', 'Chado::Biomaterial_Treatment' => 'unittype_id');
sub biomaterial_treatments { return shift->biomaterial_treatment_unittype_id }
Chado::Cvterm->has_many('phenstatement_observable_id', 'Chado::Phenstatement' => 'observable_id');
sub phenstatement_observables { return shift->phenstatement_observable_id }
Chado::Cvterm->has_many('phenstatement_attr_id', 'Chado::Phenstatement' => 'attr_id');
sub phenstatement_attrs { return shift->phenstatement_attr_id }
Chado::Cvterm->has_many('phenstatement_cvalue_id', 'Chado::Phenstatement' => 'cvalue_id');
sub phenstatement_cvalues { return shift->phenstatement_cvalue_id }
Chado::Cvterm->has_many('phenstatement_assay_id', 'Chado::Phenstatement' => 'assay_id');
sub phenstatement_assays { return shift->phenstatement_assay_id }
Chado::Cvterm->has_many('feature_type_id', 'Chado::Feature' => 'type_id');
sub feature_types { return shift->feature_type_id }
Chado::Cvterm->has_many('studydesignprop_type_id', 'Chado::Studydesignprop' => 'type_id');
sub studydesignprops { return shift->studydesignprop_type_id }
Chado::Cvterm->has_many('assayprop_type_id', 'Chado::Assayprop' => 'type_id');
sub assayprops { return shift->assayprop_type_id }
Chado::Cvterm->has_many('feature_gcontext_cvterm_id', 'Chado::Feature_Gcontext' => 'cvterm_id');
sub feature_gcontexts { return shift->feature_gcontext_cvterm_id }
Chado::Cvterm->has_many('acquisition_relationship_type_id', 'Chado::Acquisition_Relationship' => 'type_id');
Chado::Cvterm->has_many('gcontext_relationship_type_id', 'Chado::Gcontext_Relationship' => 'type_id');
Chado::Cvterm->has_many('arrayprop_type_id', 'Chado::Arrayprop' => 'type_id');
sub arrayprops { return shift->arrayprop_type_id }
Chado::Cvterm->has_many('cvterm_relationship_type_id', 'Chado::Cvterm_Relationship' => 'type_id');
Chado::Cvterm->has_many('cvterm_relationship_subject_id', 'Chado::Cvterm_Relationship' => 'subject_id');
Chado::Cvterm->has_many('cvterm_relationship_object_id', 'Chado::Cvterm_Relationship' => 'object_id');
Chado::Cvterm->has_many('quantificationprop_type_id', 'Chado::Quantificationprop' => 'type_id');
sub quantificationprops { return shift->quantificationprop_type_id }
Chado::Cvterm->has_many('pub_type_id', 'Chado::Pub' => 'type_id');
sub pub_types { return shift->pub_type_id }
Chado::Cvterm->has_many('phenstatement_relationship_type_id', 'Chado::Phenstatement_Relationship' => 'type_id');
Chado::Cvterm->has_many('phenstatement_relationship_comment_id', 'Chado::Phenstatement_Relationship' => 'comment_id');
Chado::Cvterm->has_many('pubprop_type_id', 'Chado::Pubprop' => 'type_id');
sub pubprops { return shift->pubprop_type_id }
Chado::Cvterm->has_many('biomaterialprop_type_id', 'Chado::Biomaterialprop' => 'type_id');
sub biomaterialprops { return shift->biomaterialprop_type_id }
Chado::Cvterm->has_many('synonym_type_id', 'Chado::Synonym' => 'type_id');
sub synonyms { return shift->synonym_type_id }
Chado::Cvterm->has_many('featureprop_type_id', 'Chado::Featureprop' => 'type_id');
sub featureprops { return shift->featureprop_type_id }
Chado::Cvterm->has_many('treatment_type_id', 'Chado::Treatment' => 'type_id');
sub treatments { return shift->treatment_type_id }
Chado::Cvterm->has_many('quantification_relationship_type_id', 'Chado::Quantification_Relationship' => 'type_id');
Chado::Cvterm->has_many('protocolparam_datatype_id', 'Chado::Protocolparam' => 'datatype_id');
sub protocolparam_datatypes { return shift->protocolparam_datatype_id }
Chado::Cvterm->has_many('protocolparam_unittype_id', 'Chado::Protocolparam' => 'unittype_id');
sub protocolparam_unittypes { return shift->protocolparam_unittype_id }
Chado::Cvterm->has_many('biomaterial_relationship_type_id', 'Chado::Biomaterial_Relationship' => 'type_id');
Chado::Cvterm->has_many('pub_relationship_type_id', 'Chado::Pub_Relationship' => 'type_id');


#
# Has Compound Many
#
sub quantification_relationship_types { return shift->quantification_relationship_type_id }
sub cvterm_dbxref_cvterms { return shift->cvterm_dbxref_cvterm_id }
sub pub_relationship_types { return shift->pub_relationship_type_id }
sub feature_cvterm_cvterms { return shift->feature_cvterm_cvterm_id }
sub feature_cvterm_cvterms { return shift->feature_cvterm_cvterm_id }
sub biomaterial_relationship_types { return shift->biomaterial_relationship_type_id }
sub gcontext_relationship_types { return shift->gcontext_relationship_type_id }
sub cvterm_relationship_types { return shift->cvterm_relationship_type_id }
sub cvterm_relationship_subjects { return shift->cvterm_relationship_subject_id }
sub cvterm_relationship_objects { return shift->cvterm_relationship_object_id }
sub phenstatement_cvterm_cvterms { return shift->phenstatement_cvterm_cvterm_id }
sub acquisition_relationship_types { return shift->acquisition_relationship_type_id }
sub phenstatement_relationship_types { return shift->phenstatement_relationship_type_id }
sub phenstatement_relationship_comments { return shift->phenstatement_relationship_comment_id }
########## one2one ###########
sub dbxrefs { my $self = shift; return map $_->dbxref_id, $self->cvterm_dbxref_cvterm_id }
sub pubs { my $self = shift; return map $_->pub_id, $self->feature_cvterm_cvterm_id }
sub features { my $self = shift; return map $_->feature_id, $self->feature_cvterm_cvterm_id }
sub phenstatements { my $self = shift; return map $_->phenstatement_id, $self->phenstatement_cvterm_cvterm_id }
########## one2many ##########
#Chado::Cvterm::cvterm_id -> Chado::Quantification_Relationship::type_id ... Chado::Quantification_Relationship::subject_id <- Chado::Quantification::quantification_id
sub quantification_relationship_subjects { my $self = shift; return map $_->subject_id, $self->quantification_relationship_type_id }
#Chado::Cvterm::cvterm_id -> Chado::Pub_Relationship::type_id ... Chado::Pub_Relationship::subject_id <- Chado::Pub::pub_id
sub pub_relationship_subjects { my $self = shift; return map $_->subject_id, $self->pub_relationship_type_id }
#Chado::Cvterm::cvterm_id -> Chado::Biomaterial_Relationship::type_id ... Chado::Biomaterial_Relationship::subject_id <- Chado::Biomaterial::biomaterial_id
sub biomaterial_relationship_subjects { my $self = shift; return map $_->subject_id, $self->biomaterial_relationship_type_id }
#Chado::Cvterm::cvterm_id -> Chado::Gcontext_Relationship::type_id ... Chado::Gcontext_Relationship::subjectgc_id <- Chado::Gcontext::gcontext_id
sub gcontext_relationship_subjectgcs { my $self = shift; return map $_->subjectgc_id, $self->gcontext_relationship_type_id }
#Chado::Cvterm::cvterm_id -> Chado::Acquisition_Relationship::type_id ... Chado::Acquisition_Relationship::subject_id <- Chado::Acquisition::acquisition_id
sub acquisition_relationship_subjects { my $self = shift; return map $_->subject_id, $self->acquisition_relationship_type_id }

########## many2many #########
#Chado::Cvterm::cvterm_id -> Chado::Phenstatement_Relationship::type_id ... Chado::Phenstatement_Relationship::subject_id <- Chado::Phenstatement::phenstatement_id
sub phenstatement_relationship_type_subjects { my $self = shift; return map $_->phenstatement_relationship_subjects, $self->phenstatement_relationship_types }
#Chado::Cvterm::cvterm_id -> Chado::Phenstatement_Relationship::type_id ... Chado::Phenstatement_Relationship::object_id <- Chado::Phenstatement::phenstatement_id
sub phenstatement_relationship_type_objects { my $self = shift; return map $_->phenstatement_relationship_objects, $self->phenstatement_relationship_types }
#Chado::Cvterm::cvterm_id -> Chado::Phenstatement_Relationship::comment_id ... Chado::Phenstatement_Relationship::subject_id <- Chado::Phenstatement::phenstatement_id
sub phenstatement_relationship_comment_subjects { my $self = shift; return map $_->phenstatement_relationship_subjects, $self->phenstatement_relationship_comments }
#Chado::Cvterm::cvterm_id -> Chado::Phenstatement_Relationship::comment_id ... Chado::Phenstatement_Relationship::object_id <- Chado::Phenstatement::phenstatement_id
sub phenstatement_relationship_comment_objects { my $self = shift; return map $_->phenstatement_relationship_objects, $self->phenstatement_relationship_comments }

# --------------------------------------------

package Chado::Cvterm_Dbxref;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Cvterm_Dbxref->set_up_table('cvterm_dbxref');
#
# Primary key accessors
#
sub id { shift->cvterm_dbxref_id }sub cvterm_dbxref { shift->cvterm_dbxref_id }

#
# Has A
#
Chado::Cvterm_Dbxref->has_a(cvterm_id => 'Chado::Cvterm');
sub cvterm { return shift->cvterm_id }Chado::Cvterm_Dbxref->has_a(dbxref_id => 'Chado::Dbxref');
sub dbxref { return shift->dbxref_id }

#
# Has Many
#







# --------------------------------------------

package Chado::Cvterm_Relationship;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Cvterm_Relationship->set_up_table('cvterm_relationship');
#
# Primary key accessors
#
sub id { shift->cvterm_relationship_id }sub cvterm_relationship { shift->cvterm_relationship_id }

#
# Has A
#
Chado::Cvterm_Relationship->has_a(type_id => 'Chado::Cvterm');
sub type { return shift->type_id }Chado::Cvterm_Relationship->has_a(subject_id => 'Chado::Cvterm');
sub subject { return shift->subject_id }Chado::Cvterm_Relationship->has_a(object_id => 'Chado::Cvterm');
sub object { return shift->object_id }

#
# Has Many
#







# --------------------------------------------

package Chado::Cvtermpath;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Cvtermpath->set_up_table('cvtermpath');
#
# Primary key accessors
#
sub id { shift->cvtermpath_id }sub cvtermpath { shift->cvtermpath_id }

#
# Has A
#
Chado::Cvtermpath->has_a(type_id => 'Chado::Cvterm');
sub type { return shift->type_id }Chado::Cvtermpath->has_a(subject_id => 'Chado::Cvterm');
sub subject { return shift->subject_id }Chado::Cvtermpath->has_a(object_id => 'Chado::Cvterm');
sub object { return shift->object_id }Chado::Cvtermpath->has_a(cv_id => 'Chado::Cv');
sub cv { return shift->cv_id }

#
# Has Many
#







# --------------------------------------------

package Chado::Cvtermsynonym;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Cvtermsynonym->set_up_table('cvtermsynonym');
#
# Primary key accessors
#
sub id { shift->cvtermsynonym_id }sub cvtermsynonym { shift->cvtermsynonym_id }

#
# Has A
#
Chado::Cvtermsynonym->has_a(cvterm_id => 'Chado::Cvterm');
sub cvterm { return shift->cvterm_id }

#
# Has Many
#







# --------------------------------------------

package Chado::Db;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Db->set_up_table('db');
#
# Primary key accessors
#
sub id { shift->db_id }sub db { shift->db_id }

#
# Has A
#
Chado::Db->has_a(contact_id => 'Chado::Contact');
sub contact { return shift->contact_id }

#
# Has Many
#
Chado::Db->has_many('dbxref_db_id', 'Chado::Dbxref' => 'db_id');
sub dbxrefs { return shift->dbxref_db_id }







# --------------------------------------------

package Chado::Dbxref;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Dbxref->set_up_table('dbxref');
#
# Primary key accessors
#
sub id { shift->dbxref_id }sub dbxref { shift->dbxref_id }

#
# Has A
#
Chado::Dbxref->has_a(db_id => 'Chado::Db');
sub db { return shift->db_id }

#
# Has Many
#
Chado::Dbxref->has_many('study_dbxref_id', 'Chado::Study' => 'dbxref_id');
sub studys { return shift->study_dbxref_id }
Chado::Dbxref->has_many('cvterm_dbxref_dbxref_id', 'Chado::Cvterm_Dbxref' => 'dbxref_id');
Chado::Dbxref->has_many('arraydesign_dbxref_id', 'Chado::Arraydesign' => 'dbxref_id');
sub arraydesigns { return shift->arraydesign_dbxref_id }
Chado::Dbxref->has_many('element_dbxref_id', 'Chado::Element' => 'dbxref_id');
sub elements { return shift->element_dbxref_id }
Chado::Dbxref->has_many('protocol_dbxref_id', 'Chado::Protocol' => 'dbxref_id');
sub protocols { return shift->protocol_dbxref_id }
Chado::Dbxref->has_many('cvterm_dbxref_id', 'Chado::Cvterm' => 'dbxref_id');
sub cvterm_dbxrefs { return shift->cvterm_dbxref_id }
Chado::Dbxref->has_many('feature_dbxref_dbxref_id', 'Chado::Feature_Dbxref' => 'dbxref_id');
sub feature_dbxrefs { return shift->feature_dbxref_dbxref_id }
Chado::Dbxref->has_many('dbxrefprop_dbxref_id', 'Chado::Dbxrefprop' => 'dbxref_id');
sub dbxrefprops { return shift->dbxrefprop_dbxref_id }
Chado::Dbxref->has_many('phenstatement_dbxref_id', 'Chado::Phenstatement' => 'dbxref_id');
sub phenstatements { return shift->phenstatement_dbxref_id }
Chado::Dbxref->has_many('feature_dbxref_id', 'Chado::Feature' => 'dbxref_id');
sub features { return shift->feature_dbxref_id }
Chado::Dbxref->has_many('pub_dbxref_dbxref_id', 'Chado::Pub_Dbxref' => 'dbxref_id');
Chado::Dbxref->has_many('assay_dbxref_id', 'Chado::Assay' => 'dbxref_id');
sub assays { return shift->assay_dbxref_id }
Chado::Dbxref->has_many('biomaterial_dbxref_id', 'Chado::Biomaterial' => 'dbxref_id');
sub biomaterials { return shift->biomaterial_dbxref_id }
Chado::Dbxref->has_many('organism_dbxref_dbxref_id', 'Chado::Organism_Dbxref' => 'dbxref_id');


#
# Has Compound Many
#
sub cvterm_dbxref_dbxrefs { return shift->cvterm_dbxref_dbxref_id }
sub organism_dbxref_dbxrefs { return shift->organism_dbxref_dbxref_id }
sub pub_dbxref_dbxrefs { return shift->pub_dbxref_dbxref_id }
########## one2one ###########
sub cvterms { my $self = shift; return map $_->cvterm_id, $self->cvterm_dbxref_dbxref_id }
sub organisms { my $self = shift; return map $_->organism_id, $self->organism_dbxref_dbxref_id }
sub pubs { my $self = shift; return map $_->pub_id, $self->pub_dbxref_dbxref_id }




# --------------------------------------------

package Chado::Dbxrefprop;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Dbxrefprop->set_up_table('dbxrefprop');
#
# Primary key accessors
#
sub id { shift->dbxrefprop_id }sub dbxrefprop { shift->dbxrefprop_id }

#
# Has A
#
Chado::Dbxrefprop->has_a(dbxref_id => 'Chado::Dbxref');
sub dbxref { return shift->dbxref_id }Chado::Dbxrefprop->has_a(type_id => 'Chado::Cvterm');
sub cvterm { return shift->type_id }

#
# Has Many
#







# --------------------------------------------

package Chado::Element;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Element->set_up_table('element');
#
# Primary key accessors
#
sub id { shift->element_id }sub element { shift->element_id }

#
# Has A
#
Chado::Element->has_a(feature_id => 'Chado::Feature');
sub feature { return shift->feature_id }Chado::Element->has_a(arraydesign_id => 'Chado::Arraydesign');
sub arraydesign { return shift->arraydesign_id }Chado::Element->has_a(type_id => 'Chado::Cvterm');
sub cvterm { return shift->type_id }Chado::Element->has_a(dbxref_id => 'Chado::Dbxref');
sub dbxref { return shift->dbxref_id }

#
# Has Many
#
Chado::Element->has_many('elementresult_element_id', 'Chado::Elementresult' => 'element_id');
sub elementresults { return shift->elementresult_element_id }







# --------------------------------------------

package Chado::Elementresult;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Elementresult->set_up_table('elementresult');
#
# Primary key accessors
#
sub id { shift->elementresult_id }sub elementresult { shift->elementresult_id }

#
# Has A
#
Chado::Elementresult->has_a(element_id => 'Chado::Element');
sub element { return shift->element_id }Chado::Elementresult->has_a(quantification_id => 'Chado::Quantification');
sub quantification { return shift->quantification_id }

#
# Has Many
#
Chado::Elementresult->has_many('elementresult_relationship_subject_id', 'Chado::Elementresult_Relationship' => 'subject_id');
sub elementresult_relationship_subjects { return shift->elementresult_relationship_subject_id }
Chado::Elementresult->has_many('elementresult_relationship_object_id', 'Chado::Elementresult_Relationship' => 'object_id');
sub elementresult_relationship_objects { return shift->elementresult_relationship_object_id }







# --------------------------------------------

package Chado::Elementresult_Relationship;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Elementresult_Relationship->set_up_table('elementresult_relationship');
#
# Primary key accessors
#
sub id { shift->elementresult_relationship_id }sub elementresult_relationship { shift->elementresult_relationship_id }

#
# Has A
#
Chado::Elementresult_Relationship->has_a(subject_id => 'Chado::Elementresult');
sub subject { return shift->subject_id }Chado::Elementresult_Relationship->has_a(type_id => 'Chado::Cvterm');
sub cvterm { return shift->type_id }Chado::Elementresult_Relationship->has_a(object_id => 'Chado::Elementresult');
sub object { return shift->object_id }

#
# Has Many
#







# --------------------------------------------

package Chado::Feature;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Feature->set_up_table('feature');
#
# Primary key accessors
#
sub id { shift->feature_id }sub feature { shift->feature_id }

#
# Has A
#
Chado::Feature->has_a(dbxref_id => 'Chado::Dbxref');
sub dbxref { return shift->dbxref_id }Chado::Feature->has_a(organism_id => 'Chado::Organism');
sub organism { return shift->organism_id }Chado::Feature->has_a(type_id => 'Chado::Cvterm');
sub cvterm { return shift->type_id }

#
# Has Many
#
Chado::Feature->has_many('featurerange_feature_id', 'Chado::Featurerange' => 'feature_id');
sub featurerange_features { return shift->featurerange_feature_id }
Chado::Feature->has_many('featurerange_leftstartf_id', 'Chado::Featurerange' => 'leftstartf_id');
sub featurerange_leftstartfs { return shift->featurerange_leftstartf_id }
Chado::Feature->has_many('featurerange_leftendf_id', 'Chado::Featurerange' => 'leftendf_id');
sub featurerange_leftendfs { return shift->featurerange_leftendf_id }
Chado::Feature->has_many('featurerange_rightstartf_id', 'Chado::Featurerange' => 'rightstartf_id');
sub featurerange_rightstartfs { return shift->featurerange_rightstartf_id }
Chado::Feature->has_many('featurerange_rightendf_id', 'Chado::Featurerange' => 'rightendf_id');
sub featurerange_rightendfs { return shift->featurerange_rightendf_id }
Chado::Feature->has_many('feature_synonym_feature_id', 'Chado::Feature_Synonym' => 'feature_id');
sub feature_synonyms { return shift->feature_synonym_feature_id }
Chado::Feature->has_many('element_feature_id', 'Chado::Element' => 'feature_id');
sub elements { return shift->element_feature_id }
Chado::Feature->has_many('feature_dbxref_feature_id', 'Chado::Feature_Dbxref' => 'feature_id');
sub feature_dbxrefs { return shift->feature_dbxref_feature_id }
Chado::Feature->has_many('feature_relationship_subject_id', 'Chado::Feature_Relationship' => 'subject_id');
sub feature_relationship_subjects { return shift->feature_relationship_subject_id }
Chado::Feature->has_many('feature_relationship_object_id', 'Chado::Feature_Relationship' => 'object_id');
sub feature_relationship_objects { return shift->feature_relationship_object_id }
Chado::Feature->has_many('feature_cvterm_feature_id', 'Chado::Feature_Cvterm' => 'feature_id');
Chado::Feature->has_many('analysisfeature_feature_id', 'Chado::Analysisfeature' => 'feature_id');
sub analysisfeatures { return shift->analysisfeature_feature_id }
Chado::Feature->has_many('feature_gcontext_feature_id', 'Chado::Feature_Gcontext' => 'feature_id');
sub feature_gcontext_features { return shift->feature_gcontext_feature_id }
Chado::Feature->has_many('feature_gcontext_chromosome_id', 'Chado::Feature_Gcontext' => 'chromosome_id');
sub feature_gcontext_chromosomes { return shift->feature_gcontext_chromosome_id }
Chado::Feature->has_many('featurepos_feature_id', 'Chado::Featurepos' => 'feature_id');
sub featurepos_features { return shift->featurepos_feature_id }
Chado::Feature->has_many('featurepos_map_feature_id', 'Chado::Featurepos' => 'map_feature_id');
sub featurepos_map_features { return shift->featurepos_map_feature_id }
Chado::Feature->has_many('featureprop_feature_id', 'Chado::Featureprop' => 'feature_id');
sub featureprops { return shift->featureprop_feature_id }
Chado::Feature->has_many('featureloc_feature_id', 'Chado::Featureloc' => 'feature_id');
sub featureloc_features { return shift->featureloc_feature_id }
Chado::Feature->has_many('featureloc_srcfeature_id', 'Chado::Featureloc' => 'srcfeature_id');
sub featureloc_srcfeatures { return shift->featureloc_srcfeature_id }
Chado::Feature->has_many('feature_pub_feature_id', 'Chado::Feature_Pub' => 'feature_id');


#
# Has Compound Many
#
sub feature_cvterm_features { return shift->feature_cvterm_feature_id }
sub feature_cvterm_features { return shift->feature_cvterm_feature_id }
sub feature_pub_features { return shift->feature_pub_feature_id }
########## one2one ###########
sub pubs { my $self = shift; return map $_->pub_id, $self->feature_cvterm_feature_id }
sub cvterms { my $self = shift; return map $_->cvterm_id, $self->feature_cvterm_feature_id }
sub pubs { my $self = shift; return map $_->pub_id, $self->feature_pub_feature_id }




# --------------------------------------------

package Chado::Feature_Cvterm;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Feature_Cvterm->set_up_table('feature_cvterm');
#
# Primary key accessors
#
sub id { shift->feature_cvterm_id }sub feature_cvterm { shift->feature_cvterm_id }

#
# Has A
#
Chado::Feature_Cvterm->has_a(feature_id => 'Chado::Feature');
sub feature { return shift->feature_id }Chado::Feature_Cvterm->has_a(cvterm_id => 'Chado::Cvterm');
sub cvterm { return shift->cvterm_id }Chado::Feature_Cvterm->has_a(pub_id => 'Chado::Pub');
sub pub { return shift->pub_id }

#
# Has Many
#







# --------------------------------------------

package Chado::Feature_Dbxref;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Feature_Dbxref->set_up_table('feature_dbxref');
#
# Primary key accessors
#
sub id { shift->feature_dbxref_id }sub feature_dbxref { shift->feature_dbxref_id }

#
# Has A
#
Chado::Feature_Dbxref->has_a(feature_id => 'Chado::Feature');
sub feature { return shift->feature_id }Chado::Feature_Dbxref->has_a(dbxref_id => 'Chado::Dbxref');
sub dbxref { return shift->dbxref_id }

#
# Has Many
#







# --------------------------------------------

package Chado::Feature_Gcontext;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Feature_Gcontext->set_up_table('feature_gcontext');
#
# Primary key accessors
#
sub id { shift->feature_gcontext_id }sub feature_gcontext { shift->feature_gcontext_id }

#
# Has A
#
Chado::Feature_Gcontext->has_a(feature_id => 'Chado::Feature');
sub feature { return shift->feature_id }Chado::Feature_Gcontext->has_a(gcontext_id => 'Chado::Gcontext');
sub gcontext { return shift->gcontext_id }Chado::Feature_Gcontext->has_a(chromosome_id => 'Chado::Feature');
sub chromosome { return shift->chromosome_id }Chado::Feature_Gcontext->has_a(cvterm_id => 'Chado::Cvterm');
sub cvterm { return shift->cvterm_id }

#
# Has Many
#







# --------------------------------------------

package Chado::Feature_Pub;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Feature_Pub->set_up_table('feature_pub');
#
# Primary key accessors
#
sub id { shift->feature_pub_id }sub feature_pub { shift->feature_pub_id }

#
# Has A
#
Chado::Feature_Pub->has_a(feature_id => 'Chado::Feature');
sub feature { return shift->feature_id }Chado::Feature_Pub->has_a(pub_id => 'Chado::Pub');
sub pub { return shift->pub_id }

#
# Has Many
#







# --------------------------------------------

package Chado::Feature_Relationship;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Feature_Relationship->set_up_table('feature_relationship');
#
# Primary key accessors
#
sub id { shift->feature_relationship_id }sub feature_relationship { shift->feature_relationship_id }

#
# Has A
#
Chado::Feature_Relationship->has_a(subject_id => 'Chado::Feature');
sub subject { return shift->subject_id }Chado::Feature_Relationship->has_a(object_id => 'Chado::Feature');
sub object { return shift->object_id }Chado::Feature_Relationship->has_a(type_id => 'Chado::Cvterm');
sub cvterm { return shift->type_id }

#
# Has Many
#







# --------------------------------------------

package Chado::Feature_Synonym;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Feature_Synonym->set_up_table('feature_synonym');
#
# Primary key accessors
#
sub id { shift->feature_synonym_id }sub feature_synonym { shift->feature_synonym_id }

#
# Has A
#
Chado::Feature_Synonym->has_a(synonym_id => 'Chado::Synonym');
sub synonym { return shift->synonym_id }Chado::Feature_Synonym->has_a(feature_id => 'Chado::Feature');
sub feature { return shift->feature_id }Chado::Feature_Synonym->has_a(pub_id => 'Chado::Pub');
sub pub { return shift->pub_id }

#
# Has Many
#







# --------------------------------------------

package Chado::Featureloc;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Featureloc->set_up_table('featureloc');
#
# Primary key accessors
#
sub id { shift->featureloc_id }sub featureloc { shift->featureloc_id }

#
# Has A
#
Chado::Featureloc->has_a(feature_id => 'Chado::Feature');
sub feature { return shift->feature_id }Chado::Featureloc->has_a(srcfeature_id => 'Chado::Feature');
sub srcfeature { return shift->srcfeature_id }

#
# Has Many
#







# --------------------------------------------

package Chado::Featuremap;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Featuremap->set_up_table('featuremap');
#
# Primary key accessors
#
sub id { shift->featuremap_id }sub featuremap { shift->featuremap_id }

#
# Has A
#


#
# Has Many
#
Chado::Featuremap->has_many('featurerange_featuremap_id', 'Chado::Featurerange' => 'featuremap_id');
sub featureranges { return shift->featurerange_featuremap_id }
Chado::Featuremap->has_many('featuremap_pub_featuremap_id', 'Chado::Featuremap_Pub' => 'featuremap_id');
Chado::Featuremap->has_many('featurepos_featuremap_id', 'Chado::Featurepos' => 'featuremap_id');
sub featureposs { return shift->featurepos_featuremap_id }


#
# Has Compound Many
#
sub featuremap_pub_featuremaps { return shift->featuremap_pub_featuremap_id }
########## one2one ###########
sub pubs { my $self = shift; return map $_->pub_id, $self->featuremap_pub_featuremap_id }




# --------------------------------------------

package Chado::Featuremap_Pub;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Featuremap_Pub->set_up_table('featuremap_pub');
#
# Primary key accessors
#
sub id { shift->featuremap_pub_id }sub featuremap_pub { shift->featuremap_pub_id }

#
# Has A
#
Chado::Featuremap_Pub->has_a(featuremap_id => 'Chado::Featuremap');
sub featuremap { return shift->featuremap_id }Chado::Featuremap_Pub->has_a(pub_id => 'Chado::Pub');
sub pub { return shift->pub_id }

#
# Has Many
#







# --------------------------------------------

package Chado::Featurepos;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Featurepos->set_up_table('featurepos');
#
# Primary key accessors
#
sub id { shift->featurepos_id }sub featurepos { shift->featurepos_id }

#
# Has A
#
Chado::Featurepos->has_a(featuremap_id => 'Chado::Featuremap');
sub featuremap { return shift->featuremap_id }Chado::Featurepos->has_a(feature_id => 'Chado::Feature');
sub feature { return shift->feature_id }Chado::Featurepos->has_a(map_feature_id => 'Chado::Feature');
sub map_feature { return shift->map_feature_id }

#
# Has Many
#







# --------------------------------------------

package Chado::Featureprop;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Featureprop->set_up_table('featureprop');
#
# Primary key accessors
#
sub id { shift->featureprop_id }sub featureprop { shift->featureprop_id }

#
# Has A
#
Chado::Featureprop->has_a(feature_id => 'Chado::Feature');
sub feature { return shift->feature_id }Chado::Featureprop->has_a(type_id => 'Chado::Cvterm');
sub cvterm { return shift->type_id }

#
# Has Many
#
Chado::Featureprop->has_many('featureprop_pub_featureprop_id', 'Chado::Featureprop_Pub' => 'featureprop_id');


#
# Has Compound Many
#
sub featureprop_pub_featureprops { return shift->featureprop_pub_featureprop_id }
########## one2one ###########
sub pubs { my $self = shift; return map $_->pub_id, $self->featureprop_pub_featureprop_id }




# --------------------------------------------

package Chado::Featureprop_Pub;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Featureprop_Pub->set_up_table('featureprop_pub');
#
# Primary key accessors
#
sub id { shift->featureprop_pub_id }sub featureprop_pub { shift->featureprop_pub_id }

#
# Has A
#
Chado::Featureprop_Pub->has_a(featureprop_id => 'Chado::Featureprop');
sub featureprop { return shift->featureprop_id }Chado::Featureprop_Pub->has_a(pub_id => 'Chado::Pub');
sub pub { return shift->pub_id }

#
# Has Many
#







# --------------------------------------------

package Chado::Featurerange;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Featurerange->set_up_table('featurerange');
#
# Primary key accessors
#
sub id { shift->featurerange_id }sub featurerange { shift->featurerange_id }

#
# Has A
#
Chado::Featurerange->has_a(featuremap_id => 'Chado::Featuremap');
sub featuremap { return shift->featuremap_id }Chado::Featurerange->has_a(feature_id => 'Chado::Feature');
sub feature { return shift->feature_id }Chado::Featurerange->has_a(leftstartf_id => 'Chado::Feature');
sub leftstartf { return shift->leftstartf_id }Chado::Featurerange->has_a(leftendf_id => 'Chado::Feature');
sub leftendf { return shift->leftendf_id }Chado::Featurerange->has_a(rightstartf_id => 'Chado::Feature');
sub rightstartf { return shift->rightstartf_id }Chado::Featurerange->has_a(rightendf_id => 'Chado::Feature');
sub rightendf { return shift->rightendf_id }

#
# Has Many
#







# --------------------------------------------

package Chado::Gcontext;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Gcontext->set_up_table('gcontext');
#
# Primary key accessors
#
sub id { shift->gcontext_id }sub gcontext { shift->gcontext_id }

#
# Has A
#
Chado::Gcontext->has_a(pub_id => 'Chado::Pub');
sub pub { return shift->pub_id }

#
# Has Many
#
Chado::Gcontext->has_many('gcontextprop_gcontext_id', 'Chado::Gcontextprop' => 'gcontext_id');
sub gcontextprops { return shift->gcontextprop_gcontext_id }
Chado::Gcontext->has_many('phendesc_gcontext_id', 'Chado::Phendesc' => 'gcontext_id');
sub phendescs { return shift->phendesc_gcontext_id }
Chado::Gcontext->has_many('phenstatement_gcontext_id', 'Chado::Phenstatement' => 'gcontext_id');
sub phenstatements { return shift->phenstatement_gcontext_id }
Chado::Gcontext->has_many('feature_gcontext_gcontext_id', 'Chado::Feature_Gcontext' => 'gcontext_id');
sub feature_gcontexts { return shift->feature_gcontext_gcontext_id }
Chado::Gcontext->has_many('gcontext_relationship_subjectgc_id', 'Chado::Gcontext_Relationship' => 'subjectgc_id');
Chado::Gcontext->has_many('gcontext_relationship_objectgc_id', 'Chado::Gcontext_Relationship' => 'objectgc_id');


#
# Has Compound Many
#
sub gcontext_relationship_subjectgcs { return shift->gcontext_relationship_subjectgc_id }
sub gcontext_relationship_objectgcs { return shift->gcontext_relationship_objectgc_id }


########## many2one ##########
#Chado::Gcontext::gcontext_id -> Chado::Gcontext_Relationship::subjectgc_id ... Chado::Gcontext_Relationship::type_id <- Chado::Cvterm::cvterm_id
sub gcontext_relationship_subjectgc_types { my $self = shift; return map $_->type_id, $self->gcontext_relationship_subjectgc_id }
#Chado::Gcontext::gcontext_id -> Chado::Gcontext_Relationship::objectgc_id ... Chado::Gcontext_Relationship::type_id <- Chado::Cvterm::cvterm_id
sub gcontext_relationship_objectgc_types { my $self = shift; return map $_->type_id, $self->gcontext_relationship_objectgc_id }


# --------------------------------------------

package Chado::Gcontext_Relationship;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Gcontext_Relationship->set_up_table('gcontext_relationship');
#
# Primary key accessors
#
sub id { shift->gcontext_relationship_id }sub gcontext_relationship { shift->gcontext_relationship_id }

#
# Has A
#
Chado::Gcontext_Relationship->has_a(subjectgc_id => 'Chado::Gcontext');
sub subjectgc { return shift->subjectgc_id }Chado::Gcontext_Relationship->has_a(objectgc_id => 'Chado::Gcontext');
sub objectgc { return shift->objectgc_id }Chado::Gcontext_Relationship->has_a(type_id => 'Chado::Cvterm');
sub cvterm { return shift->type_id }

#
# Has Many
#







# --------------------------------------------

package Chado::Gcontextprop;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Gcontextprop->set_up_table('gcontextprop');
#
# Primary key accessors
#
sub id { shift->gcontextprop_id }sub gcontextprop { shift->gcontextprop_id }

#
# Has A
#
Chado::Gcontextprop->has_a(gcontext_id => 'Chado::Gcontext');
sub gcontext { return shift->gcontext_id }Chado::Gcontextprop->has_a(type_id => 'Chado::Cvterm');
sub cvterm { return shift->type_id }

#
# Has Many
#







# --------------------------------------------

package Chado::Magedocumentation;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Magedocumentation->set_up_table('magedocumentation');
#
# Primary key accessors
#
sub id { shift->magedocumentation_id }sub magedocumentation { shift->magedocumentation_id }

#
# Has A
#
Chado::Magedocumentation->has_a(mageml_id => 'Chado::Mageml');
sub mageml { return shift->mageml_id }Chado::Magedocumentation->has_a(tableinfo_id => 'Chado::Tableinfo');
sub tableinfo { return shift->tableinfo_id }

#
# Has Many
#







# --------------------------------------------

package Chado::Mageml;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Mageml->set_up_table('mageml');
#
# Primary key accessors
#
sub id { shift->mageml_id }sub mageml { shift->mageml_id }

#
# Has A
#


#
# Has Many
#
Chado::Mageml->has_many('magedocumentation_mageml_id', 'Chado::Magedocumentation' => 'mageml_id');
sub magedocumentations { return shift->magedocumentation_mageml_id }







# --------------------------------------------

package Chado::Organism;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Organism->set_up_table('organism');
#
# Primary key accessors
#
sub id { shift->organism_id }sub organism { shift->organism_id }

#
# Has A
#


#
# Has Many
#
Chado::Organism->has_many('organismprop_organism_id', 'Chado::Organismprop' => 'organism_id');
sub organismprops { return shift->organismprop_organism_id }
Chado::Organism->has_many('feature_organism_id', 'Chado::Feature' => 'organism_id');
sub features { return shift->feature_organism_id }
Chado::Organism->has_many('biomaterial_taxon_id', 'Chado::Biomaterial' => 'taxon_id');
sub biomaterials { return shift->biomaterial_taxon_id }
Chado::Organism->has_many('organism_dbxref_organism_id', 'Chado::Organism_Dbxref' => 'organism_id');


#
# Has Compound Many
#
sub organism_dbxref_organisms { return shift->organism_dbxref_organism_id }
########## one2one ###########
sub dbxrefs { my $self = shift; return map $_->dbxref_id, $self->organism_dbxref_organism_id }




# --------------------------------------------

package Chado::Organism_Dbxref;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Organism_Dbxref->set_up_table('organism_dbxref');
#
# Primary key accessors
#
sub id { shift->organism_dbxref_id }sub organism_dbxref { shift->organism_dbxref_id }

#
# Has A
#
Chado::Organism_Dbxref->has_a(organism_id => 'Chado::Organism');
sub organism { return shift->organism_id }Chado::Organism_Dbxref->has_a(dbxref_id => 'Chado::Dbxref');
sub dbxref { return shift->dbxref_id }

#
# Has Many
#







# --------------------------------------------

package Chado::Organismprop;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Organismprop->set_up_table('organismprop');
#
# Primary key accessors
#
sub id { shift->organismprop_id }sub organismprop { shift->organismprop_id }

#
# Has A
#
Chado::Organismprop->has_a(organism_id => 'Chado::Organism');
sub organism { return shift->organism_id }Chado::Organismprop->has_a(type_id => 'Chado::Cvterm');
sub cvterm { return shift->type_id }

#
# Has Many
#







# --------------------------------------------

package Chado::Phendesc;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Phendesc->set_up_table('phendesc');
#
# Primary key accessors
#
sub id { shift->phendesc_id }sub phendesc { shift->phendesc_id }

#
# Has A
#
Chado::Phendesc->has_a(gcontext_id => 'Chado::Gcontext');
sub gcontext { return shift->gcontext_id }

#
# Has Many
#







# --------------------------------------------

package Chado::Phenstatement;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Phenstatement->set_up_table('phenstatement');
#
# Primary key accessors
#
sub id { shift->phenstatement_id }sub phenstatement { shift->phenstatement_id }

#
# Has A
#
Chado::Phenstatement->has_a(gcontext_id => 'Chado::Gcontext');
sub gcontext { return shift->gcontext_id }Chado::Phenstatement->has_a(dbxref_id => 'Chado::Dbxref');
sub dbxref { return shift->dbxref_id }Chado::Phenstatement->has_a(observable_id => 'Chado::Cvterm');
sub observable { return shift->observable_id }Chado::Phenstatement->has_a(attr_id => 'Chado::Cvterm');
sub attr { return shift->attr_id }Chado::Phenstatement->has_a(cvalue_id => 'Chado::Cvterm');
sub cvalue { return shift->cvalue_id }Chado::Phenstatement->has_a(assay_id => 'Chado::Cvterm');
sub assay { return shift->assay_id }

#
# Has Many
#
Chado::Phenstatement->has_many('phenstatement_cvterm_phenstatement_id', 'Chado::Phenstatement_Cvterm' => 'phenstatement_id');
Chado::Phenstatement->has_many('phenstatement_prop_phenstatement_id', 'Chado::Phenstatement_Prop' => 'phenstatement_id');
sub phenstatement_props { return shift->phenstatement_prop_phenstatement_id }
Chado::Phenstatement->has_many('phenstatement_relationship_subject_id', 'Chado::Phenstatement_Relationship' => 'subject_id');
Chado::Phenstatement->has_many('phenstatement_relationship_object_id', 'Chado::Phenstatement_Relationship' => 'object_id');


#
# Has Compound Many
#
sub phenstatement_cvterm_phenstatements { return shift->phenstatement_cvterm_phenstatement_id }
sub phenstatement_relationship_subjects { return shift->phenstatement_relationship_subject_id }
sub phenstatement_relationship_objects { return shift->phenstatement_relationship_object_id }
########## one2one ###########
sub cvterms { my $self = shift; return map $_->cvterm_id, $self->phenstatement_cvterm_phenstatement_id }


########## many2many #########
#Chado::Phenstatement::phenstatement_id -> Chado::Phenstatement_Relationship::subject_id ... Chado::Phenstatement_Relationship::type_id <- Chado::Cvterm::cvterm_id
sub phenstatement_relationship_subject_types { my $self = shift; return map $_->phenstatement_relationship_types, $self->phenstatement_relationship_subjects }
#Chado::Phenstatement::phenstatement_id -> Chado::Phenstatement_Relationship::subject_id ... Chado::Phenstatement_Relationship::comment_id <- Chado::Cvterm::cvterm_id
sub phenstatement_relationship_subject_comments { my $self = shift; return map $_->phenstatement_relationship_comments, $self->phenstatement_relationship_subjects }
#Chado::Phenstatement::phenstatement_id -> Chado::Phenstatement_Relationship::object_id ... Chado::Phenstatement_Relationship::type_id <- Chado::Cvterm::cvterm_id
sub phenstatement_relationship_object_types { my $self = shift; return map $_->phenstatement_relationship_types, $self->phenstatement_relationship_objects }
#Chado::Phenstatement::phenstatement_id -> Chado::Phenstatement_Relationship::object_id ... Chado::Phenstatement_Relationship::comment_id <- Chado::Cvterm::cvterm_id
sub phenstatement_relationship_object_comments { my $self = shift; return map $_->phenstatement_relationship_comments, $self->phenstatement_relationship_objects }

# --------------------------------------------

package Chado::Phenstatement_Cvterm;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Phenstatement_Cvterm->set_up_table('phenstatement_cvterm');
#
# Primary key accessors
#
sub id { shift->phenstatement_cvterm_id }sub phenstatement_cvterm { shift->phenstatement_cvterm_id }

#
# Has A
#
Chado::Phenstatement_Cvterm->has_a(phenstatement_id => 'Chado::Phenstatement');
sub phenstatement { return shift->phenstatement_id }Chado::Phenstatement_Cvterm->has_a(cvterm_id => 'Chado::Cvterm');
sub cvterm { return shift->cvterm_id }

#
# Has Many
#







# --------------------------------------------

package Chado::Phenstatement_Prop;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Phenstatement_Prop->set_up_table('phenstatement_prop');
#
# Primary key accessors
#
sub id { shift->phenstatement_prop_id }sub phenstatement_prop { shift->phenstatement_prop_id }

#
# Has A
#
Chado::Phenstatement_Prop->has_a(phenstatement_id => 'Chado::Phenstatement');
sub phenstatement { return shift->phenstatement_id }Chado::Phenstatement_Prop->has_a(type_id => 'Chado::Cvterm');
sub cvterm { return shift->type_id }

#
# Has Many
#







# --------------------------------------------

package Chado::Phenstatement_Relationship;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Phenstatement_Relationship->set_up_table('phenstatement_relationship');
#
# Primary key accessors
#
sub id { shift->phenstatement_relationship_id }sub phenstatement_relationship { shift->phenstatement_relationship_id }

#
# Has A
#
Chado::Phenstatement_Relationship->has_a(subject_id => 'Chado::Phenstatement');
sub subject { return shift->subject_id }Chado::Phenstatement_Relationship->has_a(object_id => 'Chado::Phenstatement');
sub object { return shift->object_id }Chado::Phenstatement_Relationship->has_a(type_id => 'Chado::Cvterm');
sub type { return shift->type_id }Chado::Phenstatement_Relationship->has_a(comment_id => 'Chado::Cvterm');
sub comment { return shift->comment_id }

#
# Has Many
#







# --------------------------------------------

package Chado::Project;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Project->set_up_table('project');
#
# Primary key accessors
#
sub id { shift->project_id }sub project { shift->project_id }

#
# Has A
#


#
# Has Many
#
Chado::Project->has_many('assay_project_project_id', 'Chado::Assay_Project' => 'project_id');


#
# Has Compound Many
#
sub assay_project_projects { return shift->assay_project_project_id }
########## one2one ###########
sub assays { my $self = shift; return map $_->assay_id, $self->assay_project_project_id }




# --------------------------------------------

package Chado::Protocol;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Protocol->set_up_table('protocol');
#
# Primary key accessors
#
sub id { shift->protocol_id }sub protocol { shift->protocol_id }

#
# Has A
#
Chado::Protocol->has_a(type_id => 'Chado::Cvterm');
sub cvterm { return shift->type_id }Chado::Protocol->has_a(pub_id => 'Chado::Pub');
sub pub { return shift->pub_id }Chado::Protocol->has_a(dbxref_id => 'Chado::Dbxref');
sub dbxref { return shift->dbxref_id }

#
# Has Many
#
Chado::Protocol->has_many('arraydesign_protocol_id', 'Chado::Arraydesign' => 'protocol_id');
sub arraydesigns { return shift->arraydesign_protocol_id }
Chado::Protocol->has_many('quantification_protocol_id', 'Chado::Quantification' => 'protocol_id');
sub quantifications { return shift->quantification_protocol_id }
Chado::Protocol->has_many('assay_protocol_id', 'Chado::Assay' => 'protocol_id');
sub assays { return shift->assay_protocol_id }
Chado::Protocol->has_many('treatment_protocol_id', 'Chado::Treatment' => 'protocol_id');
sub treatments { return shift->treatment_protocol_id }
Chado::Protocol->has_many('protocolparam_protocol_id', 'Chado::Protocolparam' => 'protocol_id');
sub protocolparams { return shift->protocolparam_protocol_id }
Chado::Protocol->has_many('acquisition_protocol_id', 'Chado::Acquisition' => 'protocol_id');
sub acquisitions { return shift->acquisition_protocol_id }







# --------------------------------------------

package Chado::Protocolparam;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Protocolparam->set_up_table('protocolparam');
#
# Primary key accessors
#
sub id { shift->protocolparam_id }sub protocolparam { shift->protocolparam_id }

#
# Has A
#
Chado::Protocolparam->has_a(protocol_id => 'Chado::Protocol');
sub protocol { return shift->protocol_id }Chado::Protocolparam->has_a(datatype_id => 'Chado::Cvterm');
sub datatype { return shift->datatype_id }Chado::Protocolparam->has_a(unittype_id => 'Chado::Cvterm');
sub unittype { return shift->unittype_id }

#
# Has Many
#







# --------------------------------------------

package Chado::Pub;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Pub->set_up_table('pub');
#
# Primary key accessors
#
sub id { shift->pub_id }sub pub { shift->pub_id }

#
# Has A
#
Chado::Pub->has_a(type_id => 'Chado::Cvterm');
sub cvterm { return shift->type_id }

#
# Has Many
#
Chado::Pub->has_many('study_pub_id', 'Chado::Study' => 'pub_id');
sub studys { return shift->study_pub_id }
Chado::Pub->has_many('feature_synonym_pub_id', 'Chado::Feature_Synonym' => 'pub_id');
sub feature_synonyms { return shift->feature_synonym_pub_id }
Chado::Pub->has_many('protocol_pub_id', 'Chado::Protocol' => 'pub_id');
sub protocols { return shift->protocol_pub_id }
Chado::Pub->has_many('pub_author_pub_id', 'Chado::Pub_Author' => 'pub_id');
sub pub_authors { return shift->pub_author_pub_id }
Chado::Pub->has_many('feature_cvterm_pub_id', 'Chado::Feature_Cvterm' => 'pub_id');
Chado::Pub->has_many('featureprop_pub_pub_id', 'Chado::Featureprop_Pub' => 'pub_id');
Chado::Pub->has_many('pub_dbxref_pub_id', 'Chado::Pub_Dbxref' => 'pub_id');
Chado::Pub->has_many('featuremap_pub_pub_id', 'Chado::Featuremap_Pub' => 'pub_id');
Chado::Pub->has_many('pubprop_pub_id', 'Chado::Pubprop' => 'pub_id');
sub pubprops { return shift->pubprop_pub_id }
Chado::Pub->has_many('feature_pub_pub_id', 'Chado::Feature_Pub' => 'pub_id');
Chado::Pub->has_many('gcontext_pub_id', 'Chado::Gcontext' => 'pub_id');
sub gcontexts { return shift->gcontext_pub_id }
Chado::Pub->has_many('pub_relationship_subject_id', 'Chado::Pub_Relationship' => 'subject_id');
Chado::Pub->has_many('pub_relationship_object_id', 'Chado::Pub_Relationship' => 'object_id');


#
# Has Compound Many
#
sub pub_relationship_subjects { return shift->pub_relationship_subject_id }
sub pub_relationship_objects { return shift->pub_relationship_object_id }
sub feature_cvterm_pubs { return shift->feature_cvterm_pub_id }
sub feature_cvterm_pubs { return shift->feature_cvterm_pub_id }
sub featuremap_pub_pubs { return shift->featuremap_pub_pub_id }
sub feature_pub_pubs { return shift->feature_pub_pub_id }
sub featureprop_pub_pubs { return shift->featureprop_pub_pub_id }
sub pub_dbxref_pubs { return shift->pub_dbxref_pub_id }
########## one2one ###########
sub features { my $self = shift; return map $_->feature_id, $self->feature_cvterm_pub_id }
sub cvterms { my $self = shift; return map $_->cvterm_id, $self->feature_cvterm_pub_id }
sub featuremaps { my $self = shift; return map $_->featuremap_id, $self->featuremap_pub_pub_id }
sub features { my $self = shift; return map $_->feature_id, $self->feature_pub_pub_id }
sub featureprops { my $self = shift; return map $_->featureprop_id, $self->featureprop_pub_pub_id }
sub dbxrefs { my $self = shift; return map $_->dbxref_id, $self->pub_dbxref_pub_id }

########## many2one ##########
#Chado::Pub::pub_id -> Chado::Pub_Relationship::subject_id ... Chado::Pub_Relationship::type_id <- Chado::Cvterm::cvterm_id
sub pub_relationship_subject_types { my $self = shift; return map $_->type_id, $self->pub_relationship_subject_id }
#Chado::Pub::pub_id -> Chado::Pub_Relationship::object_id ... Chado::Pub_Relationship::type_id <- Chado::Cvterm::cvterm_id
sub pub_relationship_object_types { my $self = shift; return map $_->type_id, $self->pub_relationship_object_id }


# --------------------------------------------

package Chado::Pub_Author;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Pub_Author->set_up_table('pub_author');
#
# Primary key accessors
#
sub id { shift->pub_author_id }sub pub_author { shift->pub_author_id }

#
# Has A
#
Chado::Pub_Author->has_a(author_id => 'Chado::Author');
sub author { return shift->author_id }Chado::Pub_Author->has_a(pub_id => 'Chado::Pub');
sub pub { return shift->pub_id }

#
# Has Many
#







# --------------------------------------------

package Chado::Pub_Dbxref;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Pub_Dbxref->set_up_table('pub_dbxref');
#
# Primary key accessors
#
sub id { shift->pub_dbxref_id }sub pub_dbxref { shift->pub_dbxref_id }

#
# Has A
#
Chado::Pub_Dbxref->has_a(pub_id => 'Chado::Pub');
sub pub { return shift->pub_id }Chado::Pub_Dbxref->has_a(dbxref_id => 'Chado::Dbxref');
sub dbxref { return shift->dbxref_id }

#
# Has Many
#







# --------------------------------------------

package Chado::Pub_Relationship;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Pub_Relationship->set_up_table('pub_relationship');
#
# Primary key accessors
#
sub id { shift->pub_relationship_id }sub pub_relationship { shift->pub_relationship_id }

#
# Has A
#
Chado::Pub_Relationship->has_a(subject_id => 'Chado::Pub');
sub subject { return shift->subject_id }Chado::Pub_Relationship->has_a(object_id => 'Chado::Pub');
sub object { return shift->object_id }Chado::Pub_Relationship->has_a(type_id => 'Chado::Cvterm');
sub cvterm { return shift->type_id }

#
# Has Many
#







# --------------------------------------------

package Chado::Pubprop;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Pubprop->set_up_table('pubprop');
#
# Primary key accessors
#
sub id { shift->pubprop_id }sub pubprop { shift->pubprop_id }

#
# Has A
#
Chado::Pubprop->has_a(pub_id => 'Chado::Pub');
sub pub { return shift->pub_id }Chado::Pubprop->has_a(type_id => 'Chado::Cvterm');
sub cvterm { return shift->type_id }

#
# Has Many
#







# --------------------------------------------

package Chado::Quantification;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Quantification->set_up_table('quantification');
#
# Primary key accessors
#
sub id { shift->quantification_id }sub quantification { shift->quantification_id }

#
# Has A
#
Chado::Quantification->has_a(acquisition_id => 'Chado::Acquisition');
sub acquisition { return shift->acquisition_id }Chado::Quantification->has_a(operator_id => 'Chado::Contact');
sub contact { return shift->operator_id }Chado::Quantification->has_a(protocol_id => 'Chado::Protocol');
sub protocol { return shift->protocol_id }Chado::Quantification->has_a(analysis_id => 'Chado::Analysis');
sub analysis { return shift->analysis_id }

#
# Has Many
#
Chado::Quantification->has_many('elementresult_quantification_id', 'Chado::Elementresult' => 'quantification_id');
sub elementresults { return shift->elementresult_quantification_id }
Chado::Quantification->has_many('quantificationprop_quantification_id', 'Chado::Quantificationprop' => 'quantification_id');
sub quantificationprops { return shift->quantificationprop_quantification_id }
Chado::Quantification->has_many('quantification_relationship_subject_id', 'Chado::Quantification_Relationship' => 'subject_id');
Chado::Quantification->has_many('quantification_relationship_object_id', 'Chado::Quantification_Relationship' => 'object_id');


#
# Has Compound Many
#
sub quantification_relationship_subjects { return shift->quantification_relationship_subject_id }
sub quantification_relationship_objects { return shift->quantification_relationship_object_id }


########## many2one ##########
#Chado::Quantification::quantification_id -> Chado::Quantification_Relationship::subject_id ... Chado::Quantification_Relationship::type_id <- Chado::Cvterm::cvterm_id
sub quantification_relationship_subject_types { my $self = shift; return map $_->type_id, $self->quantification_relationship_subject_id }
#Chado::Quantification::quantification_id -> Chado::Quantification_Relationship::object_id ... Chado::Quantification_Relationship::type_id <- Chado::Cvterm::cvterm_id
sub quantification_relationship_object_types { my $self = shift; return map $_->type_id, $self->quantification_relationship_object_id }


# --------------------------------------------

package Chado::Quantification_Relationship;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Quantification_Relationship->set_up_table('quantification_relationship');
#
# Primary key accessors
#
sub id { shift->quantification_relationship_id }sub quantification_relationship { shift->quantification_relationship_id }

#
# Has A
#
Chado::Quantification_Relationship->has_a(subject_id => 'Chado::Quantification');
sub subject { return shift->subject_id }Chado::Quantification_Relationship->has_a(type_id => 'Chado::Cvterm');
sub cvterm { return shift->type_id }Chado::Quantification_Relationship->has_a(object_id => 'Chado::Quantification');
sub object { return shift->object_id }

#
# Has Many
#







# --------------------------------------------

package Chado::Quantificationprop;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Quantificationprop->set_up_table('quantificationprop');
#
# Primary key accessors
#
sub id { shift->quantificationprop_id }sub quantificationprop { shift->quantificationprop_id }

#
# Has A
#
Chado::Quantificationprop->has_a(quantification_id => 'Chado::Quantification');
sub quantification { return shift->quantification_id }Chado::Quantificationprop->has_a(type_id => 'Chado::Cvterm');
sub cvterm { return shift->type_id }

#
# Has Many
#







# --------------------------------------------

package Chado::Study;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Study->set_up_table('study');
#
# Primary key accessors
#
sub id { shift->study_id }sub study { shift->study_id }

#
# Has A
#
Chado::Study->has_a(contact_id => 'Chado::Contact');
sub contact { return shift->contact_id }Chado::Study->has_a(pub_id => 'Chado::Pub');
sub pub { return shift->pub_id }Chado::Study->has_a(dbxref_id => 'Chado::Dbxref');
sub dbxref { return shift->dbxref_id }

#
# Has Many
#
Chado::Study->has_many('study_assay_study_id', 'Chado::Study_Assay' => 'study_id');
Chado::Study->has_many('studydesign_study_id', 'Chado::Studydesign' => 'study_id');
sub studydesigns { return shift->studydesign_study_id }


#
# Has Compound Many
#
sub study_assay_studys { return shift->study_assay_study_id }
########## one2one ###########
sub assays { my $self = shift; return map $_->assay_id, $self->study_assay_study_id }




# --------------------------------------------

package Chado::Study_Assay;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Study_Assay->set_up_table('study_assay');
#
# Primary key accessors
#
sub id { shift->study_assay_id }sub study_assay { shift->study_assay_id }

#
# Has A
#
Chado::Study_Assay->has_a(study_id => 'Chado::Study');
sub study { return shift->study_id }Chado::Study_Assay->has_a(assay_id => 'Chado::Assay');
sub assay { return shift->assay_id }

#
# Has Many
#







# --------------------------------------------

package Chado::Studydesign;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Studydesign->set_up_table('studydesign');
#
# Primary key accessors
#
sub id { shift->studydesign_id }sub studydesign { shift->studydesign_id }

#
# Has A
#
Chado::Studydesign->has_a(study_id => 'Chado::Study');
sub study { return shift->study_id }

#
# Has Many
#
Chado::Studydesign->has_many('studyfactor_studydesign_id', 'Chado::Studyfactor' => 'studydesign_id');
sub studyfactors { return shift->studyfactor_studydesign_id }
Chado::Studydesign->has_many('studydesignprop_studydesign_id', 'Chado::Studydesignprop' => 'studydesign_id');
sub studydesignprops { return shift->studydesignprop_studydesign_id }







# --------------------------------------------

package Chado::Studydesignprop;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Studydesignprop->set_up_table('studydesignprop');
#
# Primary key accessors
#
sub id { shift->studydesignprop_id }sub studydesignprop { shift->studydesignprop_id }

#
# Has A
#
Chado::Studydesignprop->has_a(studydesign_id => 'Chado::Studydesign');
sub studydesign { return shift->studydesign_id }Chado::Studydesignprop->has_a(type_id => 'Chado::Cvterm');
sub cvterm { return shift->type_id }

#
# Has Many
#







# --------------------------------------------

package Chado::Studyfactor;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Studyfactor->set_up_table('studyfactor');
#
# Primary key accessors
#
sub id { shift->studyfactor_id }sub studyfactor { shift->studyfactor_id }

#
# Has A
#
Chado::Studyfactor->has_a(studydesign_id => 'Chado::Studydesign');
sub studydesign { return shift->studydesign_id }Chado::Studyfactor->has_a(type_id => 'Chado::Cvterm');
sub cvterm { return shift->type_id }

#
# Has Many
#
Chado::Studyfactor->has_many('studyfactorvalue_studyfactor_id', 'Chado::Studyfactorvalue' => 'studyfactor_id');
sub studyfactorvalues { return shift->studyfactorvalue_studyfactor_id }







# --------------------------------------------

package Chado::Studyfactorvalue;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Studyfactorvalue->set_up_table('studyfactorvalue');
#
# Primary key accessors
#
sub id { shift->studyfactorvalue_id }sub studyfactorvalue { shift->studyfactorvalue_id }

#
# Has A
#
Chado::Studyfactorvalue->has_a(studyfactor_id => 'Chado::Studyfactor');
sub studyfactor { return shift->studyfactor_id }Chado::Studyfactorvalue->has_a(assay_id => 'Chado::Assay');
sub assay { return shift->assay_id }

#
# Has Many
#







# --------------------------------------------

package Chado::Synonym;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Synonym->set_up_table('synonym');
#
# Primary key accessors
#
sub id { shift->synonym_id }sub synonym { shift->synonym_id }

#
# Has A
#
Chado::Synonym->has_a(type_id => 'Chado::Cvterm');
sub cvterm { return shift->type_id }

#
# Has Many
#
Chado::Synonym->has_many('feature_synonym_synonym_id', 'Chado::Feature_Synonym' => 'synonym_id');
sub feature_synonyms { return shift->feature_synonym_synonym_id }







# --------------------------------------------

package Chado::Tableinfo;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Tableinfo->set_up_table('tableinfo');
#
# Primary key accessors
#
sub id { shift->tableinfo_id }sub tableinfo { shift->tableinfo_id }

#
# Has A
#


#
# Has Many
#
Chado::Tableinfo->has_many('control_tableinfo_id', 'Chado::Control' => 'tableinfo_id');
sub controls { return shift->control_tableinfo_id }
Chado::Tableinfo->has_many('magedocumentation_tableinfo_id', 'Chado::Magedocumentation' => 'tableinfo_id');
sub magedocumentations { return shift->magedocumentation_tableinfo_id }







# --------------------------------------------

package Chado::Treatment;
use base 'Chado::DBI';
use Class::DBI::Pager;
Chado::Treatment->set_up_table('treatment');
#
# Primary key accessors
#
sub id { shift->treatment_id }sub treatment { shift->treatment_id }

#
# Has A
#
Chado::Treatment->has_a(biomaterial_id => 'Chado::Biomaterial');
sub biomaterial { return shift->biomaterial_id }Chado::Treatment->has_a(type_id => 'Chado::Cvterm');
sub cvterm { return shift->type_id }Chado::Treatment->has_a(protocol_id => 'Chado::Protocol');
sub protocol { return shift->protocol_id }

#
# Has Many
#
Chado::Treatment->has_many('biomaterial_treatment_treatment_id', 'Chado::Biomaterial_Treatment' => 'treatment_id');
sub biomaterial_treatments { return shift->biomaterial_treatment_treatment_id }

1;

!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';

