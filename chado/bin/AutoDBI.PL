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
########DBI########
package Chado::DBI;

# Created by SQL::Translator::Producer::TTSchema
# Template used: dbi.tt2

use strict;
use Data::Dumper;
no warnings 'redefine';
use base qw(Class::DBI::Pg);

# This is how you normally connect with Class DBI's connection pooling but
# its very fragile for me on FC2.  I'm replacing it with the db_Main method below
#Chado::DBI->set_db('Main', 'dbi:Pg:dbname=$OPTIONS{'DBNAME'};host=$OPTIONS{'DBHOST'};port=$OPTIONS{'DBPORT'}', '$OPTIONS{'DBUSER'}', '$OPTIONS{'DBPASS'}');

my \$db_options = { __PACKAGE__->_default_attributes };
__PACKAGE__->_remember_handle('Main'); # so dbi_commit works
\$db_options->{AutoCommit} = 0;

sub db_Main {
  my \$dbh;
  \$dbh = DBI->connect_cached( 'dbi:Pg:dbname=$OPTIONS{'DBNAME'};host=$OPTIONS{'DBHOST'};port=$OPTIONS{'DBPORT'}', '$OPTIONS{'DBUSER'}', '$OPTIONS{'DBPASS'}', \$db_options );
  # clear the connection cache if can't ping
  if (\$dbh->ping() < 1) {
    my \$CachedKids_hashref = \$dbh->{Driver}->{CachedKids};
    \%\$CachedKids_hashref = () if \$CachedKids_hashref;
    \$dbh = DBI->connect_cached( 'dbi:Pg:dbname=$OPTIONS{'DBNAME'};host=$OPTIONS{'DBHOST'};port=$OPTIONS{'DBPORT'}', '$OPTIONS{'DBUSER'}', '$OPTIONS{'DBPASS'}', \$db_options );
    warn("Database handle reset!: ".\$dbh." ping: ".\$dbh->ping());
  }
  return(\$dbh);
}
!GROK!THIS!

print OUT <<'!NO!SUBS!';

sub search_ilike { shift->_do_search(ILIKE => @_ ) }
sub search_lower {
   my $c = shift;
   my %q = @_;
   my %t;
   foreach my $k (keys %q){
     $t{"lower($k)"} = lc($q{$k});
   }
   $c->_do_search(LIKE => %t);
}


# debug method
sub dump {
  my $self = shift;
  my %arg  = %{shift @_};
  $arg{'indent'} ||= 1;
  $arg{'depth'} ||= 3;
  $Data::Dumper::Maxdepth = $arg{'depth'} if defined $arg{'depth'};
  $Data::Dumper::Indent = $arg{'indent'} if defined $arg{'indent'};
  return(Dumper($arg{'object'}));
}

#
#
# NOT PART OF THE API, but useful function which returns a single row
#  and throws an error if more than one is returned
#
# Added as a utility function for modware
#
sub get_single_row {
   my ($proto, @args) = @_;
   my $class = ref $proto || $proto;

   my @rows  = $class->search( @args );

   my $count = @rows;
   die "only one row expected, @rows returned" if @rows > 1;

   return $rows[0];
}


1;


########Chado::Expression_Pub########

package Chado::Expression_Pub;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Expression_Pub->set_up_table('expression_pub');

#
# Primary key accessors
#

sub id { shift->expression_pub_id }
sub expression_pub { shift->expression_pub_id }
 



#
# Has A
#
 
Chado::Expression_Pub->has_a(expression_id => 'Chado::Expression');
    
sub Chado::Expression_Pub::expression { return shift->expression_id }
      
 
Chado::Expression_Pub->has_a(pub_id => 'Chado::Pub');
    
sub Chado::Expression_Pub::pub { return shift->pub_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Assay########

package Chado::Assay;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Assay->set_up_table('assay');

#
# Primary key accessors
#

sub id { shift->assay_id }
sub assay { shift->assay_id }
 



#
# Has A
#
 
Chado::Assay->has_a(arraydesign_id => 'Chado::Arraydesign');
    
sub Chado::Assay::arraydesign { return shift->arraydesign_id }
      
 
Chado::Assay->has_a(protocol_id => 'Chado::Protocol');
    
sub Chado::Assay::protocol { return shift->protocol_id }
      
 
Chado::Assay->has_a(operator_id => 'Chado::Contact');
    
sub Chado::Assay::contact { return shift->operator_id }
      
 
Chado::Assay->has_a(dbxref_id => 'Chado::Dbxref');
    
sub Chado::Assay::dbxref { return shift->dbxref_id }
      
  
  
  
  
  
  
   

#
# Has Many
#
     
Chado::Assay->has_many('study_assay_assay_id', 'Chado::Study_Assay' => 'assay_id');
   
Chado::Assay->has_many('acquisition_assay_id', 'Chado::Acquisition' => 'assay_id');
  
    
sub acquisitions { return shift->acquisition_assay_id }
      
Chado::Assay->has_many('assay_biomaterial_assay_id', 'Chado::Assay_Biomaterial' => 'assay_id');
  
    
sub assay_biomaterials { return shift->assay_biomaterial_assay_id }
      
Chado::Assay->has_many('studyfactorvalue_assay_id', 'Chado::Studyfactorvalue' => 'assay_id');
  
    
sub studyfactorvalues { return shift->studyfactorvalue_assay_id }
      
Chado::Assay->has_many('assay_project_assay_id', 'Chado::Assay_Project' => 'assay_id');
   
Chado::Assay->has_many('assayprop_assay_id', 'Chado::Assayprop' => 'assay_id');
  
    
sub assayprops { return shift->assayprop_assay_id }
      
Chado::Assay->has_many('control_assay_id', 'Chado::Control' => 'assay_id');
  
    
sub controls { return shift->control_assay_id }
     



#
# Has Compound Many (many to many relationships in all their flavors)
#
 
  
sub assay_project_assays { return shift->assay_project_assay_id }

   
 
  
  
sub study_assay_assays { return shift->study_assay_assay_id }
 
# one to many to one
 
  
# one2one #
sub projects { my $self = shift; return map $_->project_id, $self->assay_project_assay_id }

  

sub studys { my $self = shift; return map $_->study_id, $self->study_assay_assay_id }

# one to many to many
 
  
  
#many to many to one
 
  
  
#many to many to many


  
   

1;

########Chado::Db########

package Chado::Db;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Db->set_up_table('db');

#
# Primary key accessors
#

sub id { shift->db_id }
sub db { shift->db_id }
 



#
# Has A
#
   

#
# Has Many
#
 
Chado::Db->has_many('dbxref_db_id', 'Chado::Dbxref' => 'db_id');
  
    
sub dbxrefs { return shift->dbxref_db_id }
     


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Study_Assay########

package Chado::Study_Assay;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Study_Assay->set_up_table('study_assay');

#
# Primary key accessors
#

sub id { shift->study_assay_id }
sub study_assay { shift->study_assay_id }
 



#
# Has A
#
 
Chado::Study_Assay->has_a(study_id => 'Chado::Study');
    
sub Chado::Study_Assay::study { return shift->study_id }
      
 
Chado::Study_Assay->has_a(assay_id => 'Chado::Assay');
    
sub Chado::Study_Assay::assay { return shift->assay_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Feature_Dbxref########

package Chado::Feature_Dbxref;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Feature_Dbxref->set_up_table('feature_dbxref');

#
# Primary key accessors
#

sub id { shift->feature_dbxref_id }
sub feature_dbxref { shift->feature_dbxref_id }
 



#
# Has A
#
 
Chado::Feature_Dbxref->has_a(feature_id => 'Chado::Feature');
    
sub Chado::Feature_Dbxref::feature { return shift->feature_id }
      
 
Chado::Feature_Dbxref->has_a(dbxref_id => 'Chado::Dbxref');
    
sub Chado::Feature_Dbxref::dbxref { return shift->dbxref_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Studyfactor########

package Chado::Studyfactor;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Studyfactor->set_up_table('studyfactor');

#
# Primary key accessors
#

sub id { shift->studyfactor_id }
sub studyfactor { shift->studyfactor_id }
 



#
# Has A
#
 
Chado::Studyfactor->has_a(studydesign_id => 'Chado::Studydesign');
    
sub Chado::Studyfactor::studydesign { return shift->studydesign_id }
      
 
Chado::Studyfactor->has_a(type_id => 'Chado::Cvterm');
    
sub Chado::Studyfactor::cvterm { return shift->type_id }
      
   

#
# Has Many
#
   
Chado::Studyfactor->has_many('studyfactorvalue_studyfactor_id', 'Chado::Studyfactorvalue' => 'studyfactor_id');
  
    
sub studyfactorvalues { return shift->studyfactorvalue_studyfactor_id }
     


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Quantification########

package Chado::Quantification;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Quantification->set_up_table('quantification');

#
# Primary key accessors
#

sub id { shift->quantification_id }
sub quantification { shift->quantification_id }
 



#
# Has A
#
 
Chado::Quantification->has_a(acquisition_id => 'Chado::Acquisition');
    
sub Chado::Quantification::acquisition { return shift->acquisition_id }
      
 
Chado::Quantification->has_a(operator_id => 'Chado::Contact');
    
sub Chado::Quantification::contact { return shift->operator_id }
      
 
Chado::Quantification->has_a(protocol_id => 'Chado::Protocol');
    
sub Chado::Quantification::protocol { return shift->protocol_id }
      
 
Chado::Quantification->has_a(analysis_id => 'Chado::Analysis');
    
sub Chado::Quantification::analysis { return shift->analysis_id }
      
  
  
  
   

#
# Has Many
#
     
Chado::Quantification->has_many('quantification_relationship_subject_id', 'Chado::Quantification_Relationship' => 'subject_id');
   
Chado::Quantification->has_many('quantification_relationship_object_id', 'Chado::Quantification_Relationship' => 'object_id');
   
Chado::Quantification->has_many('elementresult_quantification_id', 'Chado::Elementresult' => 'quantification_id');
  
    
sub elementresults { return shift->elementresult_quantification_id }
      
Chado::Quantification->has_many('quantificationprop_quantification_id', 'Chado::Quantificationprop' => 'quantification_id');
  
    
sub quantificationprops { return shift->quantificationprop_quantification_id }
     



#
# Has Compound Many (many to many relationships in all their flavors)
#
 
  
sub quantification_relationship_subjects { return shift->quantification_relationship_subject_id }

  
  
sub quantification_relationship_objects { return shift->quantification_relationship_object_id }
 
# one to many to one
 
  
# one to many to many
 
  
#many to many to one
 
  
# many2one #
  
  
sub quantification_relationship_subject_types { my $self = shift; return map $_->type_id, $self->quantification_relationship_subject_id }
    
  
sub quantification_relationship_object_types { my $self = shift; return map $_->type_id, $self->quantification_relationship_object_id }
    
   
#many to many to many


   

1;

########Chado::Mageml########

package Chado::Mageml;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Mageml->set_up_table('mageml');

#
# Primary key accessors
#

sub id { shift->mageml_id }
sub mageml { shift->mageml_id }
 



#
# Has A
#
   

#
# Has Many
#
 
Chado::Mageml->has_many('magedocumentation_mageml_id', 'Chado::Magedocumentation' => 'mageml_id');
  
    
sub magedocumentations { return shift->magedocumentation_mageml_id }
     


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Organism_Dbxref########

package Chado::Organism_Dbxref;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Organism_Dbxref->set_up_table('organism_dbxref');

#
# Primary key accessors
#

sub id { shift->organism_dbxref_id }
sub organism_dbxref { shift->organism_dbxref_id }
 



#
# Has A
#
 
Chado::Organism_Dbxref->has_a(organism_id => 'Chado::Organism');
    
sub Chado::Organism_Dbxref::organism { return shift->organism_id }
      
 
Chado::Organism_Dbxref->has_a(dbxref_id => 'Chado::Dbxref');
    
sub Chado::Organism_Dbxref::dbxref { return shift->dbxref_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Feature_Expression########

package Chado::Feature_Expression;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Feature_Expression->set_up_table('feature_expression');

#
# Primary key accessors
#

sub id { shift->feature_expression_id }
sub feature_expression { shift->feature_expression_id }
 



#
# Has A
#
 
Chado::Feature_Expression->has_a(expression_id => 'Chado::Expression');
    
sub Chado::Feature_Expression::expression { return shift->expression_id }
      
 
Chado::Feature_Expression->has_a(feature_id => 'Chado::Feature');
    
sub Chado::Feature_Expression::feature { return shift->feature_id }
      
 
Chado::Feature_Expression->has_a(pub_id => 'Chado::Pub');
    
sub Chado::Feature_Expression::pub { return shift->pub_id }
      
   

#
# Has Many
#
    
Chado::Feature_Expression->has_many('feature_expressionprop_feature_expression_id', 'Chado::Feature_Expressionprop' => 'feature_expression_id');
  
    
sub feature_expressionprops { return shift->feature_expressionprop_feature_expression_id }
     


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Feature_Cvterm########

package Chado::Feature_Cvterm;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Feature_Cvterm->set_up_table('feature_cvterm');

#
# Primary key accessors
#

sub id { shift->feature_cvterm_id }
sub feature_cvterm { shift->feature_cvterm_id }
 



#
# Has A
#
 
Chado::Feature_Cvterm->has_a(feature_id => 'Chado::Feature');
    
sub Chado::Feature_Cvterm::feature { return shift->feature_id }
      
 
Chado::Feature_Cvterm->has_a(cvterm_id => 'Chado::Cvterm');
    
sub Chado::Feature_Cvterm::cvterm { return shift->cvterm_id }
      
 
Chado::Feature_Cvterm->has_a(pub_id => 'Chado::Pub');
    
sub Chado::Feature_Cvterm::pub { return shift->pub_id }
      
  
  
   

#
# Has Many
#
    
Chado::Feature_Cvterm->has_many('feature_cvterm_dbxref_feature_cvterm_id', 'Chado::Feature_Cvterm_Dbxref' => 'feature_cvterm_id');
   
Chado::Feature_Cvterm->has_many('feature_cvtermprop_feature_cvterm_id', 'Chado::Feature_Cvtermprop' => 'feature_cvterm_id');
  
    
sub feature_cvtermprops { return shift->feature_cvtermprop_feature_cvterm_id }
      
Chado::Feature_Cvterm->has_many('feature_cvterm_pub_feature_cvterm_id', 'Chado::Feature_Cvterm_Pub' => 'feature_cvterm_id');
  



#
# Has Compound Many (many to many relationships in all their flavors)
#
 
  
sub feature_cvterm_dbxref_feature_cvterms { return shift->feature_cvterm_dbxref_feature_cvterm_id }

   
 
  
sub feature_cvterm_pub_feature_cvterms { return shift->feature_cvterm_pub_feature_cvterm_id }

   
# one to many to one
 
  
# one2one #
sub dbxrefs { my $self = shift; return map $_->dbxref_id, $self->feature_cvterm_dbxref_feature_cvterm_id }

  

sub pubs { my $self = shift; return map $_->pub_id, $self->feature_cvterm_pub_feature_cvterm_id }

# one to many to many
 
  
  
#many to many to one
 
  
  
#many to many to many


  
   

1;

########Chado::Arraydesign########

package Chado::Arraydesign;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Arraydesign->set_up_table('arraydesign');

#
# Primary key accessors
#

sub id { shift->arraydesign_id }
sub arraydesign { shift->arraydesign_id }
 



#
# Has A
#
  
 
Chado::Arraydesign->has_a(manufacturer_id => 'Chado::Contact');
    
sub Chado::Arraydesign::contact { return shift->manufacturer_id }
      
 
Chado::Arraydesign->has_a(platformtype_id => 'Chado::Cvterm');
    
sub platformtype { return shift->platformtype_id }
      
 
Chado::Arraydesign->has_a(substratetype_id => 'Chado::Cvterm');
    
sub substratetype { return shift->substratetype_id }
      
 
Chado::Arraydesign->has_a(protocol_id => 'Chado::Protocol');
    
sub Chado::Arraydesign::protocol { return shift->protocol_id }
      
 
Chado::Arraydesign->has_a(dbxref_id => 'Chado::Dbxref');
    
sub Chado::Arraydesign::dbxref { return shift->dbxref_id }
      
  
  
   

#
# Has Many
#
 
Chado::Arraydesign->has_many('assay_arraydesign_id', 'Chado::Assay' => 'arraydesign_id');
  
    
sub assays { return shift->assay_arraydesign_id }
           
Chado::Arraydesign->has_many('arraydesign_element_arraydesign_id', 'Chado::Arraydesign_Element' => 'arraydesign_id');
   
Chado::Arraydesign->has_many('element_arraydesign_id', 'Chado::Element' => 'arraydesign_id');
  
sub element_arraydesigns { return shift->element_arraydesign_id }
#sub --element--arraydesign_id-- {}
   
Chado::Arraydesign->has_many('arraydesignprop_arraydesign_id', 'Chado::Arraydesignprop' => 'arraydesign_id');
  
    
sub arraydesignprops { return shift->arraydesignprop_arraydesign_id }
     



#
# Has Compound Many (many to many relationships in all their flavors)
#
 
  
sub arraydesign_element_arraydesigns { return shift->arraydesign_element_arraydesign_id }

   
 
  
sub element_arraydesigns { return shift->element_arraydesign_id }

   
 
  
sub element_arraydesigns { return shift->element_arraydesign_id }

   
 
  
  
sub element_arraydesigns { return shift->element_arraydesign_id }
 
# one to many to one
 
  
# one2one #
sub elements { my $self = shift; return map $_->element_id, $self->arraydesign_element_arraydesign_id }

  

sub dbxrefs { my $self = shift; return map $_->dbxref_id, $self->element_arraydesign_id }

  

sub cvterms { my $self = shift; return map $_->type_id, $self->element_arraydesign_id }

  

sub features { my $self = shift; return map $_->feature_id, $self->element_arraydesign_id }

# one to many to many
 
  
  
  
  
#many to many to one
 
  
  
  
  
#many to many to many


  
  
  
   

1;

########Chado::Phylonodeprop########

package Chado::Phylonodeprop;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Phylonodeprop->set_up_table('phylonodeprop');

#
# Primary key accessors
#

sub id { shift->phylonodeprop_id }
sub phylonodeprop { shift->phylonodeprop_id }
 



#
# Has A
#
 
Chado::Phylonodeprop->has_a(phylonode_id => 'Chado::Phylonode');
    
sub Chado::Phylonodeprop::phylonode { return shift->phylonode_id }
      
 
Chado::Phylonodeprop->has_a(type_id => 'Chado::Cvterm');
    
sub Chado::Phylonodeprop::cvterm { return shift->type_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Study########

package Chado::Study;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Study->set_up_table('study');

#
# Primary key accessors
#

sub id { shift->study_id }
sub study { shift->study_id }
 



#
# Has A
#
  
 
Chado::Study->has_a(contact_id => 'Chado::Contact');
    
sub Chado::Study::contact { return shift->contact_id }
      
 
Chado::Study->has_a(pub_id => 'Chado::Pub');
    
sub Chado::Study::pub { return shift->pub_id }
      
 
Chado::Study->has_a(dbxref_id => 'Chado::Dbxref');
    
sub Chado::Study::dbxref { return shift->dbxref_id }
      
   

#
# Has Many
#
 
Chado::Study->has_many('study_assay_study_id', 'Chado::Study_Assay' => 'study_id');
      
Chado::Study->has_many('studydesign_study_id', 'Chado::Studydesign' => 'study_id');
  
    
sub studydesigns { return shift->studydesign_study_id }
     



#
# Has Compound Many (many to many relationships in all their flavors)
#
 
  
sub study_assay_studys { return shift->study_assay_study_id }

   
# one to many to one
 
  
# one2one #
sub assays { my $self = shift; return map $_->assay_id, $self->study_assay_study_id }

# one to many to many
 
  
#many to many to one
 
  
#many to many to many


   

1;

########Chado::Stock_Cvterm########

package Chado::Stock_Cvterm;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Stock_Cvterm->set_up_table('stock_cvterm');

#
# Primary key accessors
#

sub id { shift->stock_cvterm_id }
sub stock_cvterm { shift->stock_cvterm_id }
 



#
# Has A
#
 
Chado::Stock_Cvterm->has_a(stock_id => 'Chado::Stock');
    
sub Chado::Stock_Cvterm::stock { return shift->stock_id }
      
 
Chado::Stock_Cvterm->has_a(cvterm_id => 'Chado::Cvterm');
    
sub Chado::Stock_Cvterm::cvterm { return shift->cvterm_id }
      
 
Chado::Stock_Cvterm->has_a(pub_id => 'Chado::Pub');
    
sub Chado::Stock_Cvterm::pub { return shift->pub_id }
       

#
# Has Many
#
   


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Arraydesign_Element########

package Chado::Arraydesign_Element;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Arraydesign_Element->set_up_table('arraydesign_element');

#
# Primary key accessors
#

sub id { shift->arraydesign_element_id }
sub arraydesign_element { shift->arraydesign_element_id }
 



#
# Has A
#
 
Chado::Arraydesign_Element->has_a(arraydesign_id => 'Chado::Arraydesign');
    
sub Chado::Arraydesign_Element::arraydesign { return shift->arraydesign_id }
      
 
Chado::Arraydesign_Element->has_a(element_id => 'Chado::Element');
    
sub Chado::Arraydesign_Element::element { return shift->element_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Biomaterial_Relationship########

package Chado::Biomaterial_Relationship;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Biomaterial_Relationship->set_up_table('biomaterial_relationship');

#
# Primary key accessors
#

sub id { shift->biomaterial_relationship_id }
sub biomaterial_relationship { shift->biomaterial_relationship_id }
 



#
# Has A
#
 
Chado::Biomaterial_Relationship->has_a(subject_id => 'Chado::Biomaterial');
    
sub subject { return shift->subject_id }
      
 
Chado::Biomaterial_Relationship->has_a(type_id => 'Chado::Cvterm');
    
sub Chado::Biomaterial_Relationship::cvterm { return shift->type_id }
      
 
Chado::Biomaterial_Relationship->has_a(object_id => 'Chado::Biomaterial');
    
sub object { return shift->object_id }
       

#
# Has Many
#
   


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Expression_Image########

package Chado::Expression_Image;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Expression_Image->set_up_table('expression_image');

#
# Primary key accessors
#

sub id { shift->expression_image_id }
sub expression_image { shift->expression_image_id }
 



#
# Has A
#
 
Chado::Expression_Image->has_a(expression_id => 'Chado::Expression');
    
sub Chado::Expression_Image::expression { return shift->expression_id }
      
 
Chado::Expression_Image->has_a(eimage_id => 'Chado::Eimage');
    
sub Chado::Expression_Image::eimage { return shift->eimage_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Stockprop_Pub########

package Chado::Stockprop_Pub;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Stockprop_Pub->set_up_table('stockprop_pub');

#
# Primary key accessors
#

sub id { shift->stockprop_pub_id }
sub stockprop_pub { shift->stockprop_pub_id }
 



#
# Has A
#
 
Chado::Stockprop_Pub->has_a(stockprop_id => 'Chado::Stockprop');
    
sub Chado::Stockprop_Pub::stockprop { return shift->stockprop_id }
      
 
Chado::Stockprop_Pub->has_a(pub_id => 'Chado::Pub');
    
sub Chado::Stockprop_Pub::pub { return shift->pub_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Cvtermprop########

package Chado::Cvtermprop;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Cvtermprop->set_up_table('cvtermprop');

#
# Primary key accessors
#

sub id { shift->cvtermprop_id }
sub cvtermprop { shift->cvtermprop_id }
 



#
# Has A
#
 
Chado::Cvtermprop->has_a(cvterm_id => 'Chado::Cvterm');
    
sub cvterm { return shift->cvterm_id }
      
 
Chado::Cvtermprop->has_a(type_id => 'Chado::Cvterm');
    
sub type { return shift->type_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Feature_Phenotype########

package Chado::Feature_Phenotype;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Feature_Phenotype->set_up_table('feature_phenotype');

#
# Primary key accessors
#

sub id { shift->feature_phenotype_id }
sub feature_phenotype { shift->feature_phenotype_id }
 



#
# Has A
#
 
Chado::Feature_Phenotype->has_a(feature_id => 'Chado::Feature');
    
sub Chado::Feature_Phenotype::feature { return shift->feature_id }
      
 
Chado::Feature_Phenotype->has_a(phenotype_id => 'Chado::Phenotype');
    
sub Chado::Feature_Phenotype::phenotype { return shift->phenotype_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Quantification_Relationship########

package Chado::Quantification_Relationship;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Quantification_Relationship->set_up_table('quantification_relationship');

#
# Primary key accessors
#

sub id { shift->quantification_relationship_id }
sub quantification_relationship { shift->quantification_relationship_id }
 



#
# Has A
#
 
Chado::Quantification_Relationship->has_a(subject_id => 'Chado::Quantification');
    
sub subject { return shift->subject_id }
      
 
Chado::Quantification_Relationship->has_a(type_id => 'Chado::Cvterm');
    
sub Chado::Quantification_Relationship::cvterm { return shift->type_id }
      
 
Chado::Quantification_Relationship->has_a(object_id => 'Chado::Quantification');
    
sub object { return shift->object_id }
       

#
# Has Many
#
   


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Element########

package Chado::Element;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Element->set_up_table('element');

#
# Primary key accessors
#

sub id { shift->element_id }
sub element { shift->element_id }
 



#
# Has A
#
  
 
Chado::Element->has_a(feature_id => 'Chado::Feature');
    
sub Chado::Element::feature { return shift->feature_id }
      
 
Chado::Element->has_a(arraydesign_id => 'Chado::Arraydesign');
    
sub Chado::Element::arraydesign { return shift->arraydesign_id }
      
 
Chado::Element->has_a(type_id => 'Chado::Cvterm');
    
sub Chado::Element::cvterm { return shift->type_id }
      
 
Chado::Element->has_a(dbxref_id => 'Chado::Dbxref');
    
sub Chado::Element::dbxref { return shift->dbxref_id }
      
  
  
   

#
# Has Many
#
 
Chado::Element->has_many('arraydesign_element_element_id', 'Chado::Arraydesign_Element' => 'element_id');
       
Chado::Element->has_many('elementresult_element_id', 'Chado::Elementresult' => 'element_id');
  
    
sub elementresults { return shift->elementresult_element_id }
      
Chado::Element->has_many('element_relationship_subject_id', 'Chado::Element_Relationship' => 'subject_id');
  
    
sub element_relationship_subject_ids { my $self = shift; return $self->element_relationship_subject_id(@_) }
      
Chado::Element->has_many('element_relationship_object_id', 'Chado::Element_Relationship' => 'object_id');
  
    
sub element_relationship_object_ids { my $self = shift; return $self->element_relationship_object_id(@_) }
     



#
# Has Compound Many (many to many relationships in all their flavors)
#
 
  
  
sub arraydesign_element_elements { return shift->arraydesign_element_element_id }
 
# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Analysis########

package Chado::Analysis;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Analysis->set_up_table('analysis');

#
# Primary key accessors
#

sub id { shift->analysis_id }
sub analysis { shift->analysis_id }
 



#
# Has A
#
  
  
   

#
# Has Many
#
 
Chado::Analysis->has_many('quantification_analysis_id', 'Chado::Quantification' => 'analysis_id');
  
    
sub quantifications { return shift->quantification_analysis_id }
      
Chado::Analysis->has_many('analysisfeature_analysis_id', 'Chado::Analysisfeature' => 'analysis_id');
  
    
sub analysisfeatures { return shift->analysisfeature_analysis_id }
      
Chado::Analysis->has_many('analysisprop_analysis_id', 'Chado::Analysisprop' => 'analysis_id');
  
    
sub analysisprops { return shift->analysisprop_analysis_id }
     


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Eimage########

package Chado::Eimage;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Eimage->set_up_table('eimage');

#
# Primary key accessors
#

sub id { shift->eimage_id }
sub eimage { shift->eimage_id }
 



#
# Has A
#
   

#
# Has Many
#
 
Chado::Eimage->has_many('expression_image_eimage_id', 'Chado::Expression_Image' => 'eimage_id');
  



#
# Has Compound Many (many to many relationships in all their flavors)
#
 
  
  
sub expression_image_eimages { return shift->expression_image_eimage_id }
 
# one to many to one
 
  
# one2one #
sub expressions { my $self = shift; return map $_->expression_id, $self->expression_image_eimage_id }

# one to many to many
 
  
#many to many to one
 
  
#many to many to many


   

1;

########Chado::Arraydesignprop########

package Chado::Arraydesignprop;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Arraydesignprop->set_up_table('arraydesignprop');

#
# Primary key accessors
#

sub id { shift->arraydesignprop_id }
sub arraydesignprop { shift->arraydesignprop_id }
 



#
# Has A
#
 
Chado::Arraydesignprop->has_a(arraydesign_id => 'Chado::Arraydesign');
    
sub Chado::Arraydesignprop::arraydesign { return shift->arraydesign_id }
      
 
Chado::Arraydesignprop->has_a(type_id => 'Chado::Cvterm');
    
sub Chado::Arraydesignprop::cvterm { return shift->type_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Synonym########

package Chado::Synonym;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Synonym->set_up_table('synonym');

#
# Primary key accessors
#

sub id { shift->synonym_id }
sub synonym { shift->synonym_id }
 



#
# Has A
#
 
Chado::Synonym->has_a(type_id => 'Chado::Cvterm');
    
sub Chado::Synonym::cvterm { return shift->type_id }
      
   

#
# Has Many
#
  
Chado::Synonym->has_many('feature_synonym_synonym_id', 'Chado::Feature_Synonym' => 'synonym_id');
  
    
sub feature_synonyms { return shift->feature_synonym_synonym_id }
     


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Cvtermpath########

package Chado::Cvtermpath;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Cvtermpath->set_up_table('cvtermpath');

#
# Primary key accessors
#

sub id { shift->cvtermpath_id }
sub cvtermpath { shift->cvtermpath_id }
 



#
# Has A
#
 
Chado::Cvtermpath->has_a(type_id => 'Chado::Cvterm');
    
sub type { return shift->type_id }
      
 
Chado::Cvtermpath->has_a(subject_id => 'Chado::Cvterm');
    
sub subject { return shift->subject_id }
      
 
Chado::Cvtermpath->has_a(object_id => 'Chado::Cvterm');
    
sub object { return shift->object_id }
      
 
Chado::Cvtermpath->has_a(cv_id => 'Chado::Cv');
    
sub Chado::Cvtermpath::cv { return shift->cv_id }
       

#
# Has Many
#
    


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Biomaterial_Treatment########

package Chado::Biomaterial_Treatment;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Biomaterial_Treatment->set_up_table('biomaterial_treatment');

#
# Primary key accessors
#

sub id { shift->biomaterial_treatment_id }
sub biomaterial_treatment { shift->biomaterial_treatment_id }
 



#
# Has A
#
 
Chado::Biomaterial_Treatment->has_a(biomaterial_id => 'Chado::Biomaterial');
    
sub Chado::Biomaterial_Treatment::biomaterial { return shift->biomaterial_id }
      
 
Chado::Biomaterial_Treatment->has_a(treatment_id => 'Chado::Treatment');
    
sub Chado::Biomaterial_Treatment::treatment { return shift->treatment_id }
      
 
Chado::Biomaterial_Treatment->has_a(unittype_id => 'Chado::Cvterm');
    
sub Chado::Biomaterial_Treatment::cvterm { return shift->unittype_id }
       

#
# Has Many
#
   


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Expressionprop########

package Chado::Expressionprop;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Expressionprop->set_up_table('expressionprop');

#
# Primary key accessors
#

sub id { shift->expressionprop_id }
sub expressionprop { shift->expressionprop_id }
 



#
# Has A
#
 
Chado::Expressionprop->has_a(expression_id => 'Chado::Expression');
    
sub Chado::Expressionprop::expression { return shift->expression_id }
      
 
Chado::Expressionprop->has_a(type_id => 'Chado::Cvterm');
    
sub Chado::Expressionprop::cvterm { return shift->type_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Cvterm_Relationship########

package Chado::Cvterm_Relationship;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Cvterm_Relationship->set_up_table('cvterm_relationship');

#
# Primary key accessors
#

sub id { shift->cvterm_relationship_id }
sub cvterm_relationship { shift->cvterm_relationship_id }
 



#
# Has A
#
 
Chado::Cvterm_Relationship->has_a(type_id => 'Chado::Cvterm');
    
sub type { return shift->type_id }
      
 
Chado::Cvterm_Relationship->has_a(subject_id => 'Chado::Cvterm');
    
sub subject { return shift->subject_id }
      
 
Chado::Cvterm_Relationship->has_a(object_id => 'Chado::Cvterm');
    
sub object { return shift->object_id }
       

#
# Has Many
#
   


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Phylonode_Pub########

package Chado::Phylonode_Pub;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Phylonode_Pub->set_up_table('phylonode_pub');

#
# Primary key accessors
#

sub id { shift->phylonode_pub_id }
sub phylonode_pub { shift->phylonode_pub_id }
 



#
# Has A
#
 
Chado::Phylonode_Pub->has_a(phylonode_id => 'Chado::Phylonode');
    
sub Chado::Phylonode_Pub::phylonode { return shift->phylonode_id }
      
 
Chado::Phylonode_Pub->has_a(pub_id => 'Chado::Pub');
    
sub Chado::Phylonode_Pub::pub { return shift->pub_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Acquisitionprop########

package Chado::Acquisitionprop;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Acquisitionprop->set_up_table('acquisitionprop');

#
# Primary key accessors
#

sub id { shift->acquisitionprop_id }
sub acquisitionprop { shift->acquisitionprop_id }
 



#
# Has A
#
 
Chado::Acquisitionprop->has_a(acquisition_id => 'Chado::Acquisition');
    
sub Chado::Acquisitionprop::acquisition { return shift->acquisition_id }
      
 
Chado::Acquisitionprop->has_a(type_id => 'Chado::Cvterm');
    
sub Chado::Acquisitionprop::cvterm { return shift->type_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Phylonode_Organism########

package Chado::Phylonode_Organism;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Phylonode_Organism->set_up_table('phylonode_organism');

#
# Primary key accessors
#

sub id { shift->phylonode_organism_id }
sub phylonode_organism { shift->phylonode_organism_id }
 



#
# Has A
#
 
Chado::Phylonode_Organism->has_a(phylonode_id => 'Chado::Phylonode');
    
sub Chado::Phylonode_Organism::phylonode { return shift->phylonode_id }
      
 
Chado::Phylonode_Organism->has_a(organism_id => 'Chado::Organism');
    
sub Chado::Phylonode_Organism::organism { return shift->organism_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Studydesignprop########

package Chado::Studydesignprop;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Studydesignprop->set_up_table('studydesignprop');

#
# Primary key accessors
#

sub id { shift->studydesignprop_id }
sub studydesignprop { shift->studydesignprop_id }
 



#
# Has A
#
 
Chado::Studydesignprop->has_a(studydesign_id => 'Chado::Studydesign');
    
sub Chado::Studydesignprop::studydesign { return shift->studydesign_id }
      
 
Chado::Studydesignprop->has_a(type_id => 'Chado::Cvterm');
    
sub Chado::Studydesignprop::cvterm { return shift->type_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Acquisition########

package Chado::Acquisition;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Acquisition->set_up_table('acquisition');

#
# Primary key accessors
#

sub id { shift->acquisition_id }
sub acquisition { shift->acquisition_id }
 



#
# Has A
#
  
  
 
Chado::Acquisition->has_a(assay_id => 'Chado::Assay');
    
sub Chado::Acquisition::assay { return shift->assay_id }
      
 
Chado::Acquisition->has_a(protocol_id => 'Chado::Protocol');
    
sub Chado::Acquisition::protocol { return shift->protocol_id }
      
 
Chado::Acquisition->has_a(channel_id => 'Chado::Channel');
    
sub Chado::Acquisition::channel { return shift->channel_id }
      
  
   

#
# Has Many
#
 
Chado::Acquisition->has_many('quantification_acquisition_id', 'Chado::Quantification' => 'acquisition_id');
  
    
sub quantifications { return shift->quantification_acquisition_id }
      
Chado::Acquisition->has_many('acquisitionprop_acquisition_id', 'Chado::Acquisitionprop' => 'acquisition_id');
  
    
sub acquisitionprops { return shift->acquisitionprop_acquisition_id }
         
Chado::Acquisition->has_many('acquisition_relationship_subject_id', 'Chado::Acquisition_Relationship' => 'subject_id');
  
    
sub acquisition_relationship_subject_ids { my $self = shift; return $self->acquisition_relationship_subject_id(@_) }
      
Chado::Acquisition->has_many('acquisition_relationship_object_id', 'Chado::Acquisition_Relationship' => 'object_id');
  
    
sub acquisition_relationship_object_ids { my $self = shift; return $self->acquisition_relationship_object_id(@_) }
     


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Assay_Biomaterial########

package Chado::Assay_Biomaterial;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Assay_Biomaterial->set_up_table('assay_biomaterial');

#
# Primary key accessors
#

sub id { shift->assay_biomaterial_id }
sub assay_biomaterial { shift->assay_biomaterial_id }
 



#
# Has A
#
 
Chado::Assay_Biomaterial->has_a(assay_id => 'Chado::Assay');
    
sub Chado::Assay_Biomaterial::assay { return shift->assay_id }
      
 
Chado::Assay_Biomaterial->has_a(biomaterial_id => 'Chado::Biomaterial');
    
sub Chado::Assay_Biomaterial::biomaterial { return shift->biomaterial_id }
      
 
Chado::Assay_Biomaterial->has_a(channel_id => 'Chado::Channel');
    
sub Chado::Assay_Biomaterial::channel { return shift->channel_id }
       

#
# Has Many
#
   


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Biomaterial_Dbxref########

package Chado::Biomaterial_Dbxref;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Biomaterial_Dbxref->set_up_table('biomaterial_dbxref');

#
# Primary key accessors
#

sub id { shift->biomaterial_dbxref_id }
sub biomaterial_dbxref { shift->biomaterial_dbxref_id }
 



#
# Has A
#
 
Chado::Biomaterial_Dbxref->has_a(biomaterial_id => 'Chado::Biomaterial');
    
sub Chado::Biomaterial_Dbxref::biomaterial { return shift->biomaterial_id }
      
 
Chado::Biomaterial_Dbxref->has_a(dbxref_id => 'Chado::Dbxref');
    
sub Chado::Biomaterial_Dbxref::dbxref { return shift->dbxref_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Channel########

package Chado::Channel;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Channel->set_up_table('channel');

#
# Primary key accessors
#

sub id { shift->channel_id }
sub channel { shift->channel_id }
 



#
# Has A
#
  
   

#
# Has Many
#
 
Chado::Channel->has_many('acquisition_channel_id', 'Chado::Acquisition' => 'channel_id');
  
    
sub acquisitions { return shift->acquisition_channel_id }
      
Chado::Channel->has_many('assay_biomaterial_channel_id', 'Chado::Assay_Biomaterial' => 'channel_id');
  
    
sub assay_biomaterials { return shift->assay_biomaterial_channel_id }
     


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Genotype########

package Chado::Genotype;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Genotype->set_up_table('genotype');

#
# Primary key accessors
#

sub id { shift->genotype_id }
sub genotype { shift->genotype_id }
 



#
# Has A
#
  
  
  
  
  
   

#
# Has Many
#
 
Chado::Genotype->has_many('phenotype_comparison_genotype1_id', 'Chado::Phenotype_Comparison' => 'genotype1_id');
   
Chado::Genotype->has_many('phenotype_comparison_genotype2_id', 'Chado::Phenotype_Comparison' => 'genotype2_id');
   
Chado::Genotype->has_many('stock_genotype_genotype_id', 'Chado::Stock_Genotype' => 'genotype_id');
   
Chado::Genotype->has_many('feature_genotype_genotype_id', 'Chado::Feature_Genotype' => 'genotype_id');
  
    
sub feature_genotypes { return shift->feature_genotype_genotype_id }
      
Chado::Genotype->has_many('phenstatement_genotype_id', 'Chado::Phenstatement' => 'genotype_id');
   
Chado::Genotype->has_many('phendesc_genotype_id', 'Chado::Phendesc' => 'genotype_id');
  
    
sub phendescs { return shift->phendesc_genotype_id }
     



#
# Has Compound Many (many to many relationships in all their flavors)
#
 
  
sub phenstatement_genotypes { return shift->phenstatement_genotype_id }

   
 
  
sub phenstatement_genotypes { return shift->phenstatement_genotype_id }

   
 
  
sub phenstatement_genotypes { return shift->phenstatement_genotype_id }

   
 
  
sub phenstatement_genotypes { return shift->phenstatement_genotype_id }

   
 
  
  
sub stock_genotype_genotypes { return shift->stock_genotype_genotype_id }
 
 
  
sub phenotype_comparison_genotype1s { return shift->phenotype_comparison_genotype1_id }

  
  
sub phenotype_comparison_genotype2s { return shift->phenotype_comparison_genotype2_id }

   
 
  
sub phenotype_comparison_genotype1s { return shift->phenotype_comparison_genotype1_id }

  
sub phenotype_comparison_genotype2s { return shift->phenotype_comparison_genotype2_id }

   
 
  
sub phenotype_comparison_genotype1s { return shift->phenotype_comparison_genotype1_id }

  
sub phenotype_comparison_genotype2s { return shift->phenotype_comparison_genotype2_id }

  
   
 
  
sub phenotype_comparison_genotype1s { return shift->phenotype_comparison_genotype1_id }

  
sub phenotype_comparison_genotype2s { return shift->phenotype_comparison_genotype2_id }

   
# one to many to one
 
  
# one2one #
sub environments { my $self = shift; return map $_->environment_id, $self->phenstatement_genotype_id }

  

sub cvterms { my $self = shift; return map $_->type_id, $self->phenstatement_genotype_id }

  

sub phenotypes { my $self = shift; return map $_->phenotype_id, $self->phenstatement_genotype_id }

  

sub pubs { my $self = shift; return map $_->pub_id, $self->phenstatement_genotype_id }

  

sub stocks { my $self = shift; return map $_->stock_id, $self->stock_genotype_genotype_id }

  
  
  
  
# one to many to many
 
  
  
  
  
  
  
  
  
  
#many to many to one
 
  
  
  
  
  
  
  
# many2one #
  
  
sub phenotype_comparison_genotype1_types { my $self = shift; return map $_->type_id, $self->phenotype_comparison_genotype1_id }
    
  
sub phenotype_comparison_genotype2_types { my $self = shift; return map $_->type_id, $self->phenotype_comparison_genotype2_id }
    
   
  
  

  
  
sub phenotype_comparison_genotype1_pubs { my $self = shift; return map $_->pub_id, $self->phenotype_comparison_genotype1_id }
    
  
sub phenotype_comparison_genotype2_pubs { my $self = shift; return map $_->pub_id, $self->phenotype_comparison_genotype2_id }
    
   
#many to many to many


  
  
  
  
  
  
# many2many #
  
  
    
    
sub phenotype_comparison_genotype1_environment1s { my $self = shift; return map $_->phenotype_comparison_environment1s, $self->phenotype_comparison_genotype1s }
      
    
sub phenotype_comparison_genotype1_environment2s { my $self = shift; return map $_->phenotype_comparison_environment2s, $self->phenotype_comparison_genotype1s }
      
    
    
  
    
    
sub phenotype_comparison_genotype2_environment1s { my $self = shift; return map $_->phenotype_comparison_environment1s, $self->phenotype_comparison_genotype2s }
      
    
sub phenotype_comparison_genotype2_environment2s { my $self = shift; return map $_->phenotype_comparison_environment2s, $self->phenotype_comparison_genotype2s }
      
    
    
   
  
  

  
  
    
    
sub phenotype_comparison_genotype1_phenotype1s { my $self = shift; return map $_->phenotype_comparison_phenotype1s, $self->phenotype_comparison_genotype1s }
      
    
sub phenotype_comparison_genotype1_phenotype2s { my $self = shift; return map $_->phenotype_comparison_phenotype2s, $self->phenotype_comparison_genotype1s }
      
    
    
  
    
    
sub phenotype_comparison_genotype2_phenotype1s { my $self = shift; return map $_->phenotype_comparison_phenotype1s, $self->phenotype_comparison_genotype2s }
      
    
sub phenotype_comparison_genotype2_phenotype2s { my $self = shift; return map $_->phenotype_comparison_phenotype2s, $self->phenotype_comparison_genotype2s }
      
    
    
   
   

1;

########Chado::Studyfactorvalue########

package Chado::Studyfactorvalue;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Studyfactorvalue->set_up_table('studyfactorvalue');

#
# Primary key accessors
#

sub id { shift->studyfactorvalue_id }
sub studyfactorvalue { shift->studyfactorvalue_id }
 



#
# Has A
#
 
Chado::Studyfactorvalue->has_a(studyfactor_id => 'Chado::Studyfactor');
    
sub Chado::Studyfactorvalue::studyfactor { return shift->studyfactor_id }
      
 
Chado::Studyfactorvalue->has_a(assay_id => 'Chado::Assay');
    
sub Chado::Studyfactorvalue::assay { return shift->assay_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Phylotree_Pub########

package Chado::Phylotree_Pub;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Phylotree_Pub->set_up_table('phylotree_pub');

#
# Primary key accessors
#

sub id { shift->phylotree_pub_id }
sub phylotree_pub { shift->phylotree_pub_id }
 



#
# Has A
#
 
Chado::Phylotree_Pub->has_a(phylotree_id => 'Chado::Phylotree');
    
sub Chado::Phylotree_Pub::phylotree { return shift->phylotree_id }
      
 
Chado::Phylotree_Pub->has_a(pub_id => 'Chado::Pub');
    
sub Chado::Phylotree_Pub::pub { return shift->pub_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Dbxref########

package Chado::Dbxref;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Dbxref->set_up_table('dbxref');

#
# Primary key accessors
#

sub id { shift->dbxref_id }
sub dbxref { shift->dbxref_id }
 



#
# Has A
#
  
  
  
  
  
  
  
 
Chado::Dbxref->has_a(db_id => 'Chado::Db');
    
sub Chado::Dbxref::db { return shift->db_id }
      
  
  
  
  
  
  
  
  
  
  
  
   

#
# Has Many
#
 
Chado::Dbxref->has_many('assay_dbxref_id', 'Chado::Assay' => 'dbxref_id');
  
    
sub assays { return shift->assay_dbxref_id }
      
Chado::Dbxref->has_many('feature_dbxref_dbxref_id', 'Chado::Feature_Dbxref' => 'dbxref_id');
  
    
sub feature_dbxrefs { return shift->feature_dbxref_dbxref_id }
      
Chado::Dbxref->has_many('organism_dbxref_dbxref_id', 'Chado::Organism_Dbxref' => 'dbxref_id');
   
Chado::Dbxref->has_many('arraydesign_dbxref_id', 'Chado::Arraydesign' => 'dbxref_id');
  
sub arraydesign_dbxrefs { return shift->arraydesign_dbxref_id }
#sub --arraydesign--dbxref_id-- {}
   
Chado::Dbxref->has_many('study_dbxref_id', 'Chado::Study' => 'dbxref_id');
  
    
sub studys { return shift->study_dbxref_id }
      
Chado::Dbxref->has_many('element_dbxref_id', 'Chado::Element' => 'dbxref_id');
   
Chado::Dbxref->has_many('biomaterial_dbxref_dbxref_id', 'Chado::Biomaterial_Dbxref' => 'dbxref_id');
    
Chado::Dbxref->has_many('dbxrefprop_dbxref_id', 'Chado::Dbxrefprop' => 'dbxref_id');
  
    
sub dbxrefprops { return shift->dbxrefprop_dbxref_id }
      
Chado::Dbxref->has_many('feature_cvterm_dbxref_dbxref_id', 'Chado::Feature_Cvterm_Dbxref' => 'dbxref_id');
   
Chado::Dbxref->has_many('protocol_dbxref_id', 'Chado::Protocol' => 'dbxref_id');
  
    
sub protocols { return shift->protocol_dbxref_id }
      
Chado::Dbxref->has_many('feature_dbxref_id', 'Chado::Feature' => 'dbxref_id');
  
sub feature_dbxrefs { return shift->feature_dbxref_id }
#sub --feature--dbxref_id-- {}
   
Chado::Dbxref->has_many('stock_dbxref_dbxref_id', 'Chado::Stock_Dbxref' => 'dbxref_id');
  
    
sub stock_dbxrefs { return shift->stock_dbxref_dbxref_id }
      
Chado::Dbxref->has_many('cvterm_dbxref_dbxref_id', 'Chado::Cvterm_Dbxref' => 'dbxref_id');
  
    
sub cvterm_dbxrefs { return shift->cvterm_dbxref_dbxref_id }
      
Chado::Dbxref->has_many('stock_dbxref_id', 'Chado::Stock' => 'dbxref_id');
  
    
sub stocks { return shift->stock_dbxref_id }
      
Chado::Dbxref->has_many('phylonode_dbxref_dbxref_id', 'Chado::Phylonode_Dbxref' => 'dbxref_id');
   
Chado::Dbxref->has_many('cvterm_dbxref_id', 'Chado::Cvterm' => 'dbxref_id');
  
sub cvterm_dbxrefs { return shift->cvterm_dbxref_id }
#sub --cvterm--dbxref_id-- {}
   
Chado::Dbxref->has_many('biomaterial_dbxref_id', 'Chado::Biomaterial' => 'dbxref_id');
  
sub biomaterial_dbxrefs { return shift->biomaterial_dbxref_id }
#sub --biomaterial--dbxref_id-- {}
   
Chado::Dbxref->has_many('pub_dbxref_dbxref_id', 'Chado::Pub_Dbxref' => 'dbxref_id');
  
    
sub pub_dbxrefs { return shift->pub_dbxref_dbxref_id }
      
Chado::Dbxref->has_many('phylotree_dbxref_id', 'Chado::Phylotree' => 'dbxref_id');
  
    
sub phylotrees { return shift->phylotree_dbxref_id }
     



#
# Has Compound Many (many to many relationships in all their flavors)
#
 
  
  
sub element_dbxrefs { return shift->element_dbxref_id }
 
 
  
  
sub element_dbxrefs { return shift->element_dbxref_id }
 
 
  
  
sub element_dbxrefs { return shift->element_dbxref_id }
 
 
  
  
sub phylonode_dbxref_dbxrefs { return shift->phylonode_dbxref_dbxref_id }
 
 
  
  
sub feature_cvterm_dbxref_dbxrefs { return shift->feature_cvterm_dbxref_dbxref_id }
 
 
  
  
sub organism_dbxref_dbxrefs { return shift->organism_dbxref_dbxref_id }
 
 
  
  
sub biomaterial_dbxref_dbxrefs { return shift->biomaterial_dbxref_dbxref_id }
 
# one to many to one
 
  
# one2one #
sub cvterms { my $self = shift; return map $_->type_id, $self->element_dbxref_id }

  

sub arraydesigns { my $self = shift; return map $_->arraydesign_id, $self->element_dbxref_id }

  

sub features { my $self = shift; return map $_->feature_id, $self->element_dbxref_id }

  

sub phylonodes { my $self = shift; return map $_->phylonode_id, $self->phylonode_dbxref_dbxref_id }

  

sub feature_cvterms { my $self = shift; return map $_->feature_cvterm_id, $self->feature_cvterm_dbxref_dbxref_id }

  

sub organisms { my $self = shift; return map $_->organism_id, $self->organism_dbxref_dbxref_id }

  

sub biomaterials { my $self = shift; return map $_->biomaterial_id, $self->biomaterial_dbxref_dbxref_id }

# one to many to many
 
  
  
  
  
  
  
  
#many to many to one
 
  
  
  
  
  
  
  
#many to many to many


  
  
  
  
  
  
   

1;

########Chado::Assay_Project########

package Chado::Assay_Project;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Assay_Project->set_up_table('assay_project');

#
# Primary key accessors
#

sub id { shift->assay_project_id }
sub assay_project { shift->assay_project_id }
 



#
# Has A
#
 
Chado::Assay_Project->has_a(assay_id => 'Chado::Assay');
    
sub Chado::Assay_Project::assay { return shift->assay_id }
      
 
Chado::Assay_Project->has_a(project_id => 'Chado::Project');
    
sub Chado::Assay_Project::project { return shift->project_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Assayprop########

package Chado::Assayprop;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Assayprop->set_up_table('assayprop');

#
# Primary key accessors
#

sub id { shift->assayprop_id }
sub assayprop { shift->assayprop_id }
 



#
# Has A
#
 
Chado::Assayprop->has_a(assay_id => 'Chado::Assay');
    
sub Chado::Assayprop::assay { return shift->assay_id }
      
 
Chado::Assayprop->has_a(type_id => 'Chado::Cvterm');
    
sub Chado::Assayprop::cvterm { return shift->type_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Environment_Cvterm########

package Chado::Environment_Cvterm;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Environment_Cvterm->set_up_table('environment_cvterm');

#
# Primary key accessors
#

sub id { shift->environment_cvterm_id }
sub environment_cvterm { shift->environment_cvterm_id }
 



#
# Has A
#
 
Chado::Environment_Cvterm->has_a(environment_id => 'Chado::Environment');
    
sub Chado::Environment_Cvterm::environment { return shift->environment_id }
      
 
Chado::Environment_Cvterm->has_a(cvterm_id => 'Chado::Cvterm');
    
sub Chado::Environment_Cvterm::cvterm { return shift->cvterm_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Contact_Relationship########

package Chado::Contact_Relationship;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Contact_Relationship->set_up_table('contact_relationship');

#
# Primary key accessors
#

sub id { shift->contact_relationship_id }
sub contact_relationship { shift->contact_relationship_id }
 



#
# Has A
#
 
Chado::Contact_Relationship->has_a(type_id => 'Chado::Cvterm');
    
sub Chado::Contact_Relationship::cvterm { return shift->type_id }
      
 
Chado::Contact_Relationship->has_a(subject_id => 'Chado::Contact');
    
sub subject { return shift->subject_id }
      
 
Chado::Contact_Relationship->has_a(object_id => 'Chado::Contact');
    
sub object { return shift->object_id }
       

#
# Has Many
#
   


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Tableinfo########

package Chado::Tableinfo;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Tableinfo->set_up_table('tableinfo');

#
# Primary key accessors
#

sub id { shift->tableinfo_id }
sub tableinfo { shift->tableinfo_id }
 



#
# Has A
#
  
   

#
# Has Many
#
 
Chado::Tableinfo->has_many('magedocumentation_tableinfo_id', 'Chado::Magedocumentation' => 'tableinfo_id');
  
    
sub magedocumentations { return shift->magedocumentation_tableinfo_id }
      
Chado::Tableinfo->has_many('control_tableinfo_id', 'Chado::Control' => 'tableinfo_id');
  
    
sub controls { return shift->control_tableinfo_id }
     


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Pubauthor########

package Chado::Pubauthor;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Pubauthor->set_up_table('pubauthor');

#
# Primary key accessors
#

sub id { shift->pubauthor_id }
sub pubauthor { shift->pubauthor_id }
 



#
# Has A
#
 
Chado::Pubauthor->has_a(pub_id => 'Chado::Pub');
    
sub Chado::Pubauthor::pub { return shift->pub_id }
       

#
# Has Many
#
 


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Pub########

package Chado::Pub;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Pub->set_up_table('pub');

#
# Primary key accessors
#

sub id { shift->pub_id }
sub pub { shift->pub_id }
 



#
# Has A
#
  
  
  
  
  
  
  
  
  
 
Chado::Pub->has_a(type_id => 'Chado::Cvterm');
    
sub Chado::Pub::cvterm { return shift->type_id }
      
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
   

#
# Has Many
#
 
Chado::Pub->has_many('expression_pub_pub_id', 'Chado::Expression_Pub' => 'pub_id');
   
Chado::Pub->has_many('feature_expression_pub_id', 'Chado::Feature_Expression' => 'pub_id');
   
Chado::Pub->has_many('feature_cvterm_pub_id', 'Chado::Feature_Cvterm' => 'pub_id');
  
sub feature_cvterm_pubs { return shift->feature_cvterm_pub_id }
#sub --feature_cvterm--pub_id-- {}
   
Chado::Pub->has_many('study_pub_id', 'Chado::Study' => 'pub_id');
  
    
sub studys { return shift->study_pub_id }
      
Chado::Pub->has_many('stock_cvterm_pub_id', 'Chado::Stock_Cvterm' => 'pub_id');
   
Chado::Pub->has_many('stockprop_pub_pub_id', 'Chado::Stockprop_Pub' => 'pub_id');
   
Chado::Pub->has_many('phylonode_pub_pub_id', 'Chado::Phylonode_Pub' => 'pub_id');
   
Chado::Pub->has_many('phylotree_pub_pub_id', 'Chado::Phylotree_Pub' => 'pub_id');
   
Chado::Pub->has_many('pubauthor_pub_id', 'Chado::Pubauthor' => 'pub_id');
  
    
sub pubauthors { return shift->pubauthor_pub_id }
       
Chado::Pub->has_many('feature_pub_pub_id', 'Chado::Feature_Pub' => 'pub_id');
   
Chado::Pub->has_many('phenotype_comparison_pub_id', 'Chado::Phenotype_Comparison' => 'pub_id');
   
Chado::Pub->has_many('protocol_pub_id', 'Chado::Protocol' => 'pub_id');
  
    
sub protocols { return shift->protocol_pub_id }
      
Chado::Pub->has_many('featureloc_pub_pub_id', 'Chado::Featureloc_Pub' => 'pub_id');
   
Chado::Pub->has_many('stock_relationship_pub_pub_id', 'Chado::Stock_Relationship_Pub' => 'pub_id');
   
Chado::Pub->has_many('feature_relationship_pub_pub_id', 'Chado::Feature_Relationship_Pub' => 'pub_id');
   
Chado::Pub->has_many('pubprop_pub_id', 'Chado::Pubprop' => 'pub_id');
  
    
sub pubprops { return shift->pubprop_pub_id }
      
Chado::Pub->has_many('feature_cvterm_pub_pub_id', 'Chado::Feature_Cvterm_Pub' => 'pub_id');
   
Chado::Pub->has_many('stock_pub_pub_id', 'Chado::Stock_Pub' => 'pub_id');
   
Chado::Pub->has_many('feature_synonym_pub_id', 'Chado::Feature_Synonym' => 'pub_id');
  
    
sub feature_synonyms { return shift->feature_synonym_pub_id }
      
Chado::Pub->has_many('featuremap_pub_pub_id', 'Chado::Featuremap_Pub' => 'pub_id');
   
Chado::Pub->has_many('feature_relationshipprop_pub_pub_id', 'Chado::Feature_Relationshipprop_Pub' => 'pub_id');
   
Chado::Pub->has_many('phenstatement_pub_id', 'Chado::Phenstatement' => 'pub_id');
   
Chado::Pub->has_many('pub_dbxref_pub_id', 'Chado::Pub_Dbxref' => 'pub_id');
  
    
sub pub_dbxrefs { return shift->pub_dbxref_pub_id }
      
Chado::Pub->has_many('phendesc_pub_id', 'Chado::Phendesc' => 'pub_id');
  
    
sub phendescs { return shift->phendesc_pub_id }
      
Chado::Pub->has_many('featureprop_pub_pub_id', 'Chado::Featureprop_Pub' => 'pub_id');
   
Chado::Pub->has_many('pub_relationship_subject_id', 'Chado::Pub_Relationship' => 'subject_id');
   
Chado::Pub->has_many('pub_relationship_object_id', 'Chado::Pub_Relationship' => 'object_id');
  



#
# Has Compound Many (many to many relationships in all their flavors)
#
 
  
  
sub feature_pub_pubs { return shift->feature_pub_pub_id }
 
 
  
  
sub featuremap_pub_pubs { return shift->featuremap_pub_pub_id }
 
 
  
  
sub phenstatement_pubs { return shift->phenstatement_pub_id }
 
 
  
  
sub phenstatement_pubs { return shift->phenstatement_pub_id }
 
 
  
  
sub phenstatement_pubs { return shift->phenstatement_pub_id }
 
 
  
  
sub phenstatement_pubs { return shift->phenstatement_pub_id }
 
 
  
  
sub stock_cvterm_pubs { return shift->stock_cvterm_pub_id }
 
 
  
  
sub stock_cvterm_pubs { return shift->stock_cvterm_pub_id }
 
 
  
  
sub stockprop_pub_pubs { return shift->stockprop_pub_pub_id }
 
 
  
  
sub stock_pub_pubs { return shift->stock_pub_pub_id }
 
 
  
  
sub stock_relationship_pub_pubs { return shift->stock_relationship_pub_pub_id }
 
 
  
  
sub phylonode_pub_pubs { return shift->phylonode_pub_pub_id }
 
 
  
  
sub phylotree_pub_pubs { return shift->phylotree_pub_pub_id }
 
 
  
  
sub featureprop_pub_pubs { return shift->featureprop_pub_pub_id }
 
 
  
sub pub_relationship_subjects { return shift->pub_relationship_subject_id }

  
sub pub_relationship_objects { return shift->pub_relationship_object_id }

   
 
  
  
sub featureloc_pub_pubs { return shift->featureloc_pub_pub_id }
 
 
  
  
sub feature_cvterm_pub_pubs { return shift->feature_cvterm_pub_pub_id }
 
 
  
  
sub expression_pub_pubs { return shift->expression_pub_pub_id }
 
 
  
  
sub feature_expression_pubs { return shift->feature_expression_pub_id }
 
 
  
  
sub feature_expression_pubs { return shift->feature_expression_pub_id }
 
 
  
  
sub feature_relationship_pub_pubs { return shift->feature_relationship_pub_pub_id }
 
 
  
  
  
sub phenotype_comparison_pubs { return shift->phenotype_comparison_pub_id }
 
 
  
  
sub phenotype_comparison_pubs { return shift->phenotype_comparison_pub_id }
 
 
  
  
  
sub phenotype_comparison_pubs { return shift->phenotype_comparison_pub_id }
 
 
  
  
  
sub phenotype_comparison_pubs { return shift->phenotype_comparison_pub_id }
 
 
  
  
sub feature_relationshipprop_pub_pubs { return shift->feature_relationshipprop_pub_pub_id }
 
# one to many to one
 
  
# one2one #
sub features { my $self = shift; return map $_->feature_id, $self->feature_pub_pub_id }

  

sub featuremaps { my $self = shift; return map $_->featuremap_id, $self->featuremap_pub_pub_id }

  

sub environments { my $self = shift; return map $_->environment_id, $self->phenstatement_pub_id }

  

sub cvterms { my $self = shift; return map $_->type_id, $self->phenstatement_pub_id }

  

sub phenotypes { my $self = shift; return map $_->phenotype_id, $self->phenstatement_pub_id }

  

sub genotypes { my $self = shift; return map $_->genotype_id, $self->phenstatement_pub_id }

  

sub cvterms { my $self = shift; return map $_->cvterm_id, $self->stock_cvterm_pub_id }

  

sub stocks { my $self = shift; return map $_->stock_id, $self->stock_cvterm_pub_id }

  

sub stockprops { my $self = shift; return map $_->stockprop_id, $self->stockprop_pub_pub_id }

  

sub stocks { my $self = shift; return map $_->stock_id, $self->stock_pub_pub_id }

  

sub stock_relationships { my $self = shift; return map $_->stock_relationship_id, $self->stock_relationship_pub_pub_id }

  

sub phylonodes { my $self = shift; return map $_->phylonode_id, $self->phylonode_pub_pub_id }

  

sub phylotrees { my $self = shift; return map $_->phylotree_id, $self->phylotree_pub_pub_id }

  

sub featureprops { my $self = shift; return map $_->featureprop_id, $self->featureprop_pub_pub_id }

  
  

sub featurelocs { my $self = shift; return map $_->featureloc_id, $self->featureloc_pub_pub_id }

  

sub feature_cvterms { my $self = shift; return map $_->feature_cvterm_id, $self->feature_cvterm_pub_pub_id }

  

sub expressions { my $self = shift; return map $_->expression_id, $self->expression_pub_pub_id }

  

sub expressions { my $self = shift; return map $_->expression_id, $self->feature_expression_pub_id }

  

sub features { my $self = shift; return map $_->feature_id, $self->feature_expression_pub_id }

  

sub feature_relationships { my $self = shift; return map $_->feature_relationship_id, $self->feature_relationship_pub_pub_id }

  
  

sub cvterms { my $self = shift; return map $_->type_id, $self->phenotype_comparison_pub_id }

  
  
  

sub feature_relationshipprops { my $self = shift; return map $_->feature_relationshipprop_id, $self->feature_relationshipprop_pub_pub_id }

# one to many to many
 
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
# one2many #
  
  
  
    
sub phenotype_comparison_environment1s { my $self = shift; return map $_->environment1_id, $self->phenotype_comparison_pub_id }
    
  
     
  
  

  
  
  
    
sub phenotype_comparison_phenotype1s { my $self = shift; return map $_->phenotype1_id, $self->phenotype_comparison_pub_id }
    
  
     
  

  
  
  
    
sub phenotype_comparison_genotype1s { my $self = shift; return map $_->genotype1_id, $self->phenotype_comparison_pub_id }
    
  
     
  
#many to many to one
 
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
# many2one #
  
  
sub pub_relationship_subject_types { my $self = shift; return map $_->type_id, $self->pub_relationship_subject_id }
    
  
sub pub_relationship_object_types { my $self = shift; return map $_->type_id, $self->pub_relationship_object_id }
    
   
  
  
  
  
  
  
  
  
  
  
  
#many to many to many


  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
   

1;

########Chado::Organism########

package Chado::Organism;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Organism->set_up_table('organism');

#
# Primary key accessors
#

sub id { shift->organism_id }
sub organism { shift->organism_id }
 



#
# Has A
#
  

#
# Has Many
#
 
Chado::Organism->has_many('organism_dbxref_organism_id', 'Chado::Organism_Dbxref' => 'organism_id');
   
Chado::Organism->has_many('phylonode_organism_organism_id', 'Chado::Phylonode_Organism' => 'organism_id');
   
Chado::Organism->has_many('organismprop_organism_id', 'Chado::Organismprop' => 'organism_id');
  
    
sub organismprops { return shift->organismprop_organism_id }
         
Chado::Organism->has_many('feature_organism_id', 'Chado::Feature' => 'organism_id');
  
    
sub features { return shift->feature_organism_id }
      
Chado::Organism->has_many('stock_organism_id', 'Chado::Stock' => 'organism_id');
  
    
sub stocks { return shift->stock_organism_id }
            
Chado::Organism->has_many('biomaterial_taxon_id', 'Chado::Biomaterial' => 'taxon_id');
  
    
sub biomaterials { return shift->biomaterial_taxon_id }


#
# Has Compound Many (many to many relationships in all their flavors)
#
 
sub organism_dbxref_organisms { return shift->organism_dbxref_organism_id }
  
sub phylonode_organism_organisms { return shift->phylonode_organism_organism_id }
 
# one to many to one
 
  
  
# one2one #
sub dbxrefs { my $self = shift; return map $_->dbxref_id, $self->organism_dbxref_organism_id }

  

sub phylonodes { my $self = shift; return map $_->phylonode_id, $self->phylonode_organism_organism_id }

# one to many to many
 
  
  
  
#many to many to one
 
  
# many2one #
  
    
#many to many to many 

1;

########Chado::Organismprop########

package Chado::Organismprop;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Organismprop->set_up_table('organismprop');

#
# Primary key accessors
#

sub id { shift->organismprop_id }
sub organismprop { shift->organismprop_id }
 



#
# Has A
#
 
Chado::Organismprop->has_a(organism_id => 'Chado::Organism');
    
sub Chado::Organismprop::organism { return shift->organism_id }
      
 
Chado::Organismprop->has_a(type_id => 'Chado::Cvterm');
    
sub Chado::Organismprop::cvterm { return shift->type_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Featurerange########

package Chado::Featurerange;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Featurerange->set_up_table('featurerange');

#
# Primary key accessors
#

sub id { shift->featurerange_id }
sub featurerange { shift->featurerange_id }
 



#
# Has A
#
 
Chado::Featurerange->has_a(featuremap_id => 'Chado::Featuremap');
    
sub Chado::Featurerange::featuremap { return shift->featuremap_id }
      
 
Chado::Featurerange->has_a(feature_id => 'Chado::Feature');
    
sub feature { return shift->feature_id }
      
 
Chado::Featurerange->has_a(leftstartf_id => 'Chado::Feature');
    
sub leftstartf { return shift->leftstartf_id }
      
 
Chado::Featurerange->has_a(leftendf_id => 'Chado::Feature');
    
sub leftendf { return shift->leftendf_id }
      
 
Chado::Featurerange->has_a(rightstartf_id => 'Chado::Feature');
    
sub rightstartf { return shift->rightstartf_id }
      
 
Chado::Featurerange->has_a(rightendf_id => 'Chado::Feature');
    
sub rightendf { return shift->rightendf_id }
       

#
# Has Many
#
      


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Dbxrefprop########

package Chado::Dbxrefprop;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Dbxrefprop->set_up_table('dbxrefprop');

#
# Primary key accessors
#

sub id { shift->dbxrefprop_id }
sub dbxrefprop { shift->dbxrefprop_id }
 



#
# Has A
#
 
Chado::Dbxrefprop->has_a(dbxref_id => 'Chado::Dbxref');
    
sub Chado::Dbxrefprop::dbxref { return shift->dbxref_id }
      
 
Chado::Dbxrefprop->has_a(type_id => 'Chado::Cvterm');
    
sub Chado::Dbxrefprop::cvterm { return shift->type_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Featureloc########

package Chado::Featureloc;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Featureloc->set_up_table('featureloc');

#
# Primary key accessors
#

sub id { shift->featureloc_id }
sub featureloc { shift->featureloc_id }
 



#
# Has A
#
 
Chado::Featureloc->has_a(feature_id => 'Chado::Feature');
    
sub feature { return shift->feature_id }
      
 
Chado::Featureloc->has_a(srcfeature_id => 'Chado::Feature');
    
sub srcfeature { return shift->srcfeature_id }
      
   

#
# Has Many
#
   
Chado::Featureloc->has_many('featureloc_pub_featureloc_id', 'Chado::Featureloc_Pub' => 'featureloc_id');
  



#
# Has Compound Many (many to many relationships in all their flavors)
#
 
  
sub featureloc_pub_featurelocs { return shift->featureloc_pub_featureloc_id }

   
# one to many to one
 
  
# one2one #
sub pubs { my $self = shift; return map $_->pub_id, $self->featureloc_pub_featureloc_id }

# one to many to many
 
  
#many to many to one
 
  
#many to many to many


   

1;

########Chado::Analysisfeature########

package Chado::Analysisfeature;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Analysisfeature->set_up_table('analysisfeature');

#
# Primary key accessors
#

sub id { shift->analysisfeature_id }
sub analysisfeature { shift->analysisfeature_id }
 



#
# Has A
#
 
Chado::Analysisfeature->has_a(feature_id => 'Chado::Feature');
    
sub Chado::Analysisfeature::feature { return shift->feature_id }
      
 
Chado::Analysisfeature->has_a(analysis_id => 'Chado::Analysis');
    
sub Chado::Analysisfeature::analysis { return shift->analysis_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Feature_Cvterm_Dbxref########

package Chado::Feature_Cvterm_Dbxref;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Feature_Cvterm_Dbxref->set_up_table('feature_cvterm_dbxref');

#
# Primary key accessors
#

sub id { shift->feature_cvterm_dbxref_id }
sub feature_cvterm_dbxref { shift->feature_cvterm_dbxref_id }
 



#
# Has A
#
 
Chado::Feature_Cvterm_Dbxref->has_a(feature_cvterm_id => 'Chado::Feature_Cvterm');
    
sub Chado::Feature_Cvterm_Dbxref::feature_cvterm { return shift->feature_cvterm_id }
      
 
Chado::Feature_Cvterm_Dbxref->has_a(dbxref_id => 'Chado::Dbxref');
    
sub Chado::Feature_Cvterm_Dbxref::dbxref { return shift->dbxref_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Feature_Pub########

package Chado::Feature_Pub;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Feature_Pub->set_up_table('feature_pub');

#
# Primary key accessors
#

sub id { shift->feature_pub_id }
sub feature_pub { shift->feature_pub_id }
 



#
# Has A
#
 
Chado::Feature_Pub->has_a(feature_id => 'Chado::Feature');
    
sub Chado::Feature_Pub::feature { return shift->feature_id }
      
 
Chado::Feature_Pub->has_a(pub_id => 'Chado::Pub');
    
sub Chado::Feature_Pub::pub { return shift->pub_id }
      
   

#
# Has Many
#
   
Chado::Feature_Pub->has_many('feature_pubprop_feature_pub_id', 'Chado::Feature_Pubprop' => 'feature_pub_id');
  
    
sub feature_pubprops { return shift->feature_pubprop_feature_pub_id }
     


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Feature_Relationship########

package Chado::Feature_Relationship;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Feature_Relationship->set_up_table('feature_relationship');

#
# Primary key accessors
#

sub id { shift->feature_relationship_id }
sub feature_relationship { shift->feature_relationship_id }
 



#
# Has A
#
 
Chado::Feature_Relationship->has_a(subject_id => 'Chado::Feature');
    
sub subject { return shift->subject_id }
      
 
Chado::Feature_Relationship->has_a(object_id => 'Chado::Feature');
    
sub object { return shift->object_id }
      
 
Chado::Feature_Relationship->has_a(type_id => 'Chado::Cvterm');
    
sub Chado::Feature_Relationship::cvterm { return shift->type_id }
      
  
   

#
# Has Many
#
    
Chado::Feature_Relationship->has_many('feature_relationship_pub_feature_relationship_id', 'Chado::Feature_Relationship_Pub' => 'feature_relationship_id');
   
Chado::Feature_Relationship->has_many('feature_relationshipprop_feature_relationship_id', 'Chado::Feature_Relationshipprop' => 'feature_relationship_id');
  
    
sub feature_relationshipprops { return shift->feature_relationshipprop_feature_relationship_id }
     



#
# Has Compound Many (many to many relationships in all their flavors)
#
 
  
sub feature_relationship_pub_feature_relationships { return shift->feature_relationship_pub_feature_relationship_id }

   
# one to many to one
 
  
# one2one #
sub pubs { my $self = shift; return map $_->pub_id, $self->feature_relationship_pub_feature_relationship_id }

# one to many to many
 
  
#many to many to one
 
  
#many to many to many


   

1;

########Chado::Acquisition_Relationship########

package Chado::Acquisition_Relationship;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Acquisition_Relationship->set_up_table('acquisition_relationship');

#
# Primary key accessors
#

sub id { shift->acquisition_relationship_id }
sub acquisition_relationship { shift->acquisition_relationship_id }
 



#
# Has A
#
 
Chado::Acquisition_Relationship->has_a(subject_id => 'Chado::Acquisition');
    
sub subject { return shift->subject_id }
      
 
Chado::Acquisition_Relationship->has_a(type_id => 'Chado::Cvterm');
    
sub Chado::Acquisition_Relationship::cvterm { return shift->type_id }
      
 
Chado::Acquisition_Relationship->has_a(object_id => 'Chado::Acquisition');
    
sub object { return shift->object_id }
       

#
# Has Many
#
   


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Featurepos########

package Chado::Featurepos;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Featurepos->set_up_table('featurepos');

#
# Primary key accessors
#

sub id { shift->featurepos_id }
sub featurepos { shift->featurepos_id }
 



#
# Has A
#
 
Chado::Featurepos->has_a(featuremap_id => 'Chado::Featuremap');
    
sub Chado::Featurepos::featuremap { return shift->featuremap_id }
      
 
Chado::Featurepos->has_a(feature_id => 'Chado::Feature');
    
sub feature { return shift->feature_id }
      
 
Chado::Featurepos->has_a(map_feature_id => 'Chado::Feature');
    
sub map_feature { return shift->map_feature_id }
       

#
# Has Many
#
   


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;


########Chado::Phenotype_Comparison########

package Chado::Phenotype_Comparison;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Phenotype_Comparison->set_up_table('phenotype_comparison');

#
# Primary key accessors
#

sub id { shift->phenotype_comparison_id }
sub phenotype_comparison { shift->phenotype_comparison_id }
 



#
# Has A
#
 
Chado::Phenotype_Comparison->has_a(genotype1_id => 'Chado::Genotype');
    
sub genotype1 { return shift->genotype1_id }
      
 
Chado::Phenotype_Comparison->has_a(environment1_id => 'Chado::Environment');
    
sub environment1 { return shift->environment1_id }
      
 
Chado::Phenotype_Comparison->has_a(genotype2_id => 'Chado::Genotype');
    
sub genotype2 { return shift->genotype2_id }
      
 
Chado::Phenotype_Comparison->has_a(environment2_id => 'Chado::Environment');
    
sub environment2 { return shift->environment2_id }
      
 
Chado::Phenotype_Comparison->has_a(phenotype1_id => 'Chado::Phenotype');
    
sub phenotype1 { return shift->phenotype1_id }
      
 
Chado::Phenotype_Comparison->has_a(phenotype2_id => 'Chado::Phenotype');
    
sub phenotype2 { return shift->phenotype2_id }
      
 
Chado::Phenotype_Comparison->has_a(type_id => 'Chado::Cvterm');
    
sub Chado::Phenotype_Comparison::cvterm { return shift->type_id }
      
 
Chado::Phenotype_Comparison->has_a(pub_id => 'Chado::Pub');
    
sub Chado::Phenotype_Comparison::pub { return shift->pub_id }
       

#
# Has Many
#
        


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Feature_Cvtermprop########

package Chado::Feature_Cvtermprop;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Feature_Cvtermprop->set_up_table('feature_cvtermprop');

#
# Primary key accessors
#

sub id { shift->feature_cvtermprop_id }
sub feature_cvtermprop { shift->feature_cvtermprop_id }
 



#
# Has A
#
 
Chado::Feature_Cvtermprop->has_a(feature_cvterm_id => 'Chado::Feature_Cvterm');
    
sub Chado::Feature_Cvtermprop::feature_cvterm { return shift->feature_cvterm_id }
      
 
Chado::Feature_Cvtermprop->has_a(type_id => 'Chado::Cvterm');
    
sub Chado::Feature_Cvtermprop::cvterm { return shift->type_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Protocol########

package Chado::Protocol;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Protocol->set_up_table('protocol');

#
# Primary key accessors
#

sub id { shift->protocol_id }
sub protocol { shift->protocol_id }
 



#
# Has A
#
  
  
  
  
 
Chado::Protocol->has_a(type_id => 'Chado::Cvterm');
    
sub Chado::Protocol::cvterm { return shift->type_id }
      
 
Chado::Protocol->has_a(pub_id => 'Chado::Pub');
    
sub Chado::Protocol::pub { return shift->pub_id }
      
 
Chado::Protocol->has_a(dbxref_id => 'Chado::Dbxref');
    
sub Chado::Protocol::dbxref { return shift->dbxref_id }
      
  
   

#
# Has Many
#
 
Chado::Protocol->has_many('assay_protocol_id', 'Chado::Assay' => 'protocol_id');
  
    
sub assays { return shift->assay_protocol_id }
      
Chado::Protocol->has_many('quantification_protocol_id', 'Chado::Quantification' => 'protocol_id');
  
    
sub quantifications { return shift->quantification_protocol_id }
      
Chado::Protocol->has_many('arraydesign_protocol_id', 'Chado::Arraydesign' => 'protocol_id');
  
    
sub arraydesigns { return shift->arraydesign_protocol_id }
      
Chado::Protocol->has_many('acquisition_protocol_id', 'Chado::Acquisition' => 'protocol_id');
  
    
sub acquisitions { return shift->acquisition_protocol_id }
         
Chado::Protocol->has_many('treatment_protocol_id', 'Chado::Treatment' => 'protocol_id');
  
    
sub treatments { return shift->treatment_protocol_id }
      
Chado::Protocol->has_many('protocolparam_protocol_id', 'Chado::Protocolparam' => 'protocol_id');
  
    
sub protocolparams { return shift->protocolparam_protocol_id }
     


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Featureloc_Pub########

package Chado::Featureloc_Pub;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Featureloc_Pub->set_up_table('featureloc_pub');

#
# Primary key accessors
#

sub id { shift->featureloc_pub_id }
sub featureloc_pub { shift->featureloc_pub_id }
 



#
# Has A
#
 
Chado::Featureloc_Pub->has_a(featureloc_id => 'Chado::Featureloc');
    
sub Chado::Featureloc_Pub::featureloc { return shift->featureloc_id }
      
 
Chado::Featureloc_Pub->has_a(pub_id => 'Chado::Pub');
    
sub Chado::Featureloc_Pub::pub { return shift->pub_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Elementresult_Relationship########

package Chado::Elementresult_Relationship;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Elementresult_Relationship->set_up_table('elementresult_relationship');

#
# Primary key accessors
#

sub id { shift->elementresult_relationship_id }
sub elementresult_relationship { shift->elementresult_relationship_id }
 



#
# Has A
#
 
Chado::Elementresult_Relationship->has_a(subject_id => 'Chado::Elementresult');
    
sub subject { return shift->subject_id }
      
 
Chado::Elementresult_Relationship->has_a(type_id => 'Chado::Cvterm');
    
sub Chado::Elementresult_Relationship::cvterm { return shift->type_id }
      
 
Chado::Elementresult_Relationship->has_a(object_id => 'Chado::Elementresult');
    
sub object { return shift->object_id }
       

#
# Has Many
#
   


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Cvtermsynonym########

package Chado::Cvtermsynonym;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Cvtermsynonym->set_up_table('cvtermsynonym');

#
# Primary key accessors
#

sub id { shift->cvtermsynonym_id }
sub cvtermsynonym { shift->cvtermsynonym_id }
 



#
# Has A
#
 
Chado::Cvtermsynonym->has_a(cvterm_id => 'Chado::Cvterm');
    
sub cvterm { return shift->cvterm_id }
      
 
Chado::Cvtermsynonym->has_a(type_id => 'Chado::Cvterm');
    
sub type { return shift->type_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Phylonode########

package Chado::Phylonode;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Phylonode->set_up_table('phylonode');

#
# Primary key accessors
#

sub id { shift->phylonode_id }
sub phylonode { shift->phylonode_id }
 



#
# Has A
#
  
  
  
 
Chado::Phylonode->has_a(phylotree_id => 'Chado::Phylotree');
    
sub Chado::Phylonode::phylotree { return shift->phylotree_id }
      
 
Chado::Phylonode->has_a(parent_phylonode_id => 'Chado::Phylonode');
    
sub Chado::Phylonode::phylonode { return shift->parent_phylonode_id }
      
  
 
Chado::Phylonode->has_a(type_id => 'Chado::Cvterm');
    
sub Chado::Phylonode::cvterm { return shift->type_id }
      
 
Chado::Phylonode->has_a(feature_id => 'Chado::Feature');
    
sub Chado::Phylonode::feature { return shift->feature_id }
      
  
  
   

#
# Has Many
#
 
Chado::Phylonode->has_many('phylonodeprop_phylonode_id', 'Chado::Phylonodeprop' => 'phylonode_id');
  
    
sub phylonodeprops { return shift->phylonodeprop_phylonode_id }
      
Chado::Phylonode->has_many('phylonode_pub_phylonode_id', 'Chado::Phylonode_Pub' => 'phylonode_id');
   
Chado::Phylonode->has_many('phylonode_organism_phylonode_id', 'Chado::Phylonode_Organism' => 'phylonode_id');
     
Chado::Phylonode->has_many('phylonode_parent_phylonode_id', 'Chado::Phylonode' => 'parent_phylonode_id');
  
    
sub phylonode_parent_phylonode_ids { my $self = shift; return $self->phylonode_parent_phylonode_id(@_) }
        
Chado::Phylonode->has_many('phylonode_dbxref_phylonode_id', 'Chado::Phylonode_Dbxref' => 'phylonode_id');
   
Chado::Phylonode->has_many('phylonode_relationship_subject_id', 'Chado::Phylonode_Relationship' => 'subject_id');
  
    
sub phylonode_relationship_subject_ids { my $self = shift; return $self->phylonode_relationship_subject_id(@_) }
      
Chado::Phylonode->has_many('phylonode_relationship_object_id', 'Chado::Phylonode_Relationship' => 'object_id');
  
    
sub phylonode_relationship_object_ids { my $self = shift; return $self->phylonode_relationship_object_id(@_) }
     



#
# Has Compound Many (many to many relationships in all their flavors)
#
 
  
sub phylonode_dbxref_phylonodes { return shift->phylonode_dbxref_phylonode_id }

   
 
  
sub phylonode_pub_phylonodes { return shift->phylonode_pub_phylonode_id }

   
 
  
sub phylonode_organism_phylonodes { return shift->phylonode_organism_phylonode_id }

   
# one to many to one
 
  
# one2one #
sub dbxrefs { my $self = shift; return map $_->dbxref_id, $self->phylonode_dbxref_phylonode_id }

  

sub pubs { my $self = shift; return map $_->pub_id, $self->phylonode_pub_phylonode_id }

  

sub organisms { my $self = shift; return map $_->organism_id, $self->phylonode_organism_phylonode_id }

# one to many to many
 
  
  
  
#many to many to one
 
  
  
  
#many to many to many


  
  
   

1;

########Chado::Stock_Relationship########

package Chado::Stock_Relationship;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Stock_Relationship->set_up_table('stock_relationship');

#
# Primary key accessors
#

sub id { shift->stock_relationship_id }
sub stock_relationship { shift->stock_relationship_id }
 



#
# Has A
#
 
Chado::Stock_Relationship->has_a(subject_id => 'Chado::Stock');
    
sub subject { return shift->subject_id }
      
 
Chado::Stock_Relationship->has_a(object_id => 'Chado::Stock');
    
sub object { return shift->object_id }
      
 
Chado::Stock_Relationship->has_a(type_id => 'Chado::Cvterm');
    
sub Chado::Stock_Relationship::cvterm { return shift->type_id }
      
   

#
# Has Many
#
    
Chado::Stock_Relationship->has_many('stock_relationship_pub_stock_relationship_id', 'Chado::Stock_Relationship_Pub' => 'stock_relationship_id');
  



#
# Has Compound Many (many to many relationships in all their flavors)
#
 
  
sub stock_relationship_pub_stock_relationships { return shift->stock_relationship_pub_stock_relationship_id }

   
# one to many to one
 
  
# one2one #
sub pubs { my $self = shift; return map $_->pub_id, $self->stock_relationship_pub_stock_relationship_id }

# one to many to many
 
  
#many to many to one
 
  
#many to many to many


   

1;

########Chado::Feature########

package Chado::Feature;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Feature->set_up_table('feature');

#
# Primary key accessors
#

sub id { shift->feature_id }
sub feature { shift->feature_id }
 



#
# Has A
#
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
 
Chado::Feature->has_a(dbxref_id => 'Chado::Dbxref');
    
sub Chado::Feature::dbxref { return shift->dbxref_id }
      
 
Chado::Feature->has_a(organism_id => 'Chado::Organism');
    
sub Chado::Feature::organism { return shift->organism_id }
      
 
Chado::Feature->has_a(type_id => 'Chado::Cvterm');
    
sub Chado::Feature::cvterm { return shift->type_id }
      
  
  
  
   

#
# Has Many
#
 
Chado::Feature->has_many('feature_dbxref_feature_id', 'Chado::Feature_Dbxref' => 'feature_id');
  
    
sub feature_dbxrefs { return shift->feature_dbxref_feature_id }
      
Chado::Feature->has_many('feature_expression_feature_id', 'Chado::Feature_Expression' => 'feature_id');
   
Chado::Feature->has_many('feature_cvterm_feature_id', 'Chado::Feature_Cvterm' => 'feature_id');
  
    
sub feature_cvterms { return shift->feature_cvterm_feature_id }
      
Chado::Feature->has_many('feature_phenotype_feature_id', 'Chado::Feature_Phenotype' => 'feature_id');
   
Chado::Feature->has_many('element_feature_id', 'Chado::Element' => 'feature_id');
   
Chado::Feature->has_many('featurerange_feature_id', 'Chado::Featurerange' => 'feature_id');
  
    
sub featurerange_feature_ids { my $self = shift; return $self->featurerange_feature_id(@_) }
      
Chado::Feature->has_many('featurerange_leftstartf_id', 'Chado::Featurerange' => 'leftstartf_id');
  
    
sub featurerange_leftstartf_ids { my $self = shift; return $self->featurerange_leftstartf_id(@_) }
      
Chado::Feature->has_many('featurerange_leftendf_id', 'Chado::Featurerange' => 'leftendf_id');
  
    
sub featurerange_leftendf_ids { my $self = shift; return $self->featurerange_leftendf_id(@_) }
      
Chado::Feature->has_many('featurerange_rightstartf_id', 'Chado::Featurerange' => 'rightstartf_id');
  
    
sub featurerange_rightstartf_ids { my $self = shift; return $self->featurerange_rightstartf_id(@_) }
      
Chado::Feature->has_many('featurerange_rightendf_id', 'Chado::Featurerange' => 'rightendf_id');
  
    
sub featurerange_rightendf_ids { my $self = shift; return $self->featurerange_rightendf_id(@_) }
      
Chado::Feature->has_many('featureloc_feature_id', 'Chado::Featureloc' => 'feature_id');
  
    
sub featureloc_feature_ids { my $self = shift; return $self->featureloc_feature_id(@_) }
      
Chado::Feature->has_many('featureloc_srcfeature_id', 'Chado::Featureloc' => 'srcfeature_id');
  
    
sub featureloc_srcfeature_ids { my $self = shift; return $self->featureloc_srcfeature_id(@_) }
      
Chado::Feature->has_many('analysisfeature_feature_id', 'Chado::Analysisfeature' => 'feature_id');
  
    
sub analysisfeatures { return shift->analysisfeature_feature_id }
      
Chado::Feature->has_many('feature_pub_feature_id', 'Chado::Feature_Pub' => 'feature_id');
   
Chado::Feature->has_many('feature_relationship_subject_id', 'Chado::Feature_Relationship' => 'subject_id');
  
    
sub feature_relationship_subject_ids { my $self = shift; return $self->feature_relationship_subject_id(@_) }
      
Chado::Feature->has_many('feature_relationship_object_id', 'Chado::Feature_Relationship' => 'object_id');
  
    
sub feature_relationship_object_ids { my $self = shift; return $self->feature_relationship_object_id(@_) }
      
Chado::Feature->has_many('featurepos_feature_id', 'Chado::Featurepos' => 'feature_id');
  
    
sub featurepos_feature_ids { my $self = shift; return $self->featurepos_feature_id(@_) }
      
Chado::Feature->has_many('featurepos_map_feature_id', 'Chado::Featurepos' => 'map_feature_id');
  
    
sub featurepos_map_feature_ids { my $self = shift; return $self->featurepos_map_feature_id(@_) }
      
Chado::Feature->has_many('phylonode_feature_id', 'Chado::Phylonode' => 'feature_id');
  
    
sub phylonodes { return shift->phylonode_feature_id }
         
Chado::Feature->has_many('featureprop_feature_id', 'Chado::Featureprop' => 'feature_id');
  
    
sub featureprops { return shift->featureprop_feature_id }
      
Chado::Feature->has_many('feature_synonym_feature_id', 'Chado::Feature_Synonym' => 'feature_id');
  
    
sub feature_synonyms { return shift->feature_synonym_feature_id }
      
Chado::Feature->has_many('feature_genotype_feature_id', 'Chado::Feature_Genotype' => 'feature_id');
  
    
sub feature_genotype_feature_ids { my $self = shift; return $self->feature_genotype_feature_id(@_) }
      
Chado::Feature->has_many('feature_genotype_chromosome_id', 'Chado::Feature_Genotype' => 'chromosome_id');
  
    
sub feature_genotype_chromosome_ids { my $self = shift; return $self->feature_genotype_chromosome_id(@_) }
     



#
# Has Compound Many (many to many relationships in all their flavors)
#
 
  
sub feature_pub_features { return shift->feature_pub_feature_id }

   
 
  
sub element_features { return shift->element_feature_id }

   
 
  
sub element_features { return shift->element_feature_id }

   
 
  
sub element_features { return shift->element_feature_id }

   
 
  
sub feature_expression_features { return shift->feature_expression_feature_id }

   
 
  
  
sub feature_expression_features { return shift->feature_expression_feature_id }
 
 
  
sub feature_phenotype_features { return shift->feature_phenotype_feature_id }

   
# one to many to one
 
  
# one2one #
sub pubs { my $self = shift; return map $_->pub_id, $self->feature_pub_feature_id }

  

sub dbxrefs { my $self = shift; return map $_->dbxref_id, $self->element_feature_id }

  

sub cvterms { my $self = shift; return map $_->type_id, $self->element_feature_id }

  

sub arraydesigns { my $self = shift; return map $_->arraydesign_id, $self->element_feature_id }

  

sub pubs { my $self = shift; return map $_->pub_id, $self->feature_expression_feature_id }

  

sub expressions { my $self = shift; return map $_->expression_id, $self->feature_expression_feature_id }

  

sub phenotypes { my $self = shift; return map $_->phenotype_id, $self->feature_phenotype_feature_id }

# one to many to many
 
  
  
  
  
  
  
  
#many to many to one
 
  
  
  
  
  
  
  
#many to many to many


  
  
  
  
  
  
   

1;

########Chado::Feature_Pubprop########

package Chado::Feature_Pubprop;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Feature_Pubprop->set_up_table('feature_pubprop');

#
# Primary key accessors
#

sub id { shift->feature_pubprop_id }
sub feature_pubprop { shift->feature_pubprop_id }
 



#
# Has A
#
 
Chado::Feature_Pubprop->has_a(feature_pub_id => 'Chado::Feature_Pub');
    
sub Chado::Feature_Pubprop::feature_pub { return shift->feature_pub_id }
      
 
Chado::Feature_Pubprop->has_a(type_id => 'Chado::Cvterm');
    
sub Chado::Feature_Pubprop::cvterm { return shift->type_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Stockcollection########

package Chado::Stockcollection;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Stockcollection->set_up_table('stockcollection');

#
# Primary key accessors
#

sub id { shift->stockcollection_id }
sub stockcollection { shift->stockcollection_id }
 



#
# Has A
#
 
Chado::Stockcollection->has_a(type_id => 'Chado::Cvterm');
    
sub Chado::Stockcollection::cvterm { return shift->type_id }
      
 
Chado::Stockcollection->has_a(contact_id => 'Chado::Contact');
    
sub Chado::Stockcollection::contact { return shift->contact_id }
      
  
   

#
# Has Many
#
   
Chado::Stockcollection->has_many('stockcollection_stock_stockcollection_id', 'Chado::Stockcollection_Stock' => 'stockcollection_id');
   
Chado::Stockcollection->has_many('stockcollectionprop_stockcollection_id', 'Chado::Stockcollectionprop' => 'stockcollection_id');
  
    
sub stockcollectionprops { return shift->stockcollectionprop_stockcollection_id }
     



#
# Has Compound Many (many to many relationships in all their flavors)
#
 
  
sub stockcollection_stock_stockcollections { return shift->stockcollection_stock_stockcollection_id }

   
# one to many to one
 
  
# one2one #
sub stocks { my $self = shift; return map $_->stock_id, $self->stockcollection_stock_stockcollection_id }

# one to many to many
 
  
#many to many to one
 
  
#many to many to many


   

1;

########Chado::Biomaterialprop########

package Chado::Biomaterialprop;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Biomaterialprop->set_up_table('biomaterialprop');

#
# Primary key accessors
#

sub id { shift->biomaterialprop_id }
sub biomaterialprop { shift->biomaterialprop_id }
 



#
# Has A
#
 
Chado::Biomaterialprop->has_a(biomaterial_id => 'Chado::Biomaterial');
    
sub Chado::Biomaterialprop::biomaterial { return shift->biomaterial_id }
      
 
Chado::Biomaterialprop->has_a(type_id => 'Chado::Cvterm');
    
sub Chado::Biomaterialprop::cvterm { return shift->type_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Elementresult########

package Chado::Elementresult;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Elementresult->set_up_table('elementresult');

#
# Primary key accessors
#

sub id { shift->elementresult_id }
sub elementresult { shift->elementresult_id }
 



#
# Has A
#
  
  
 
Chado::Elementresult->has_a(element_id => 'Chado::Element');
    
sub Chado::Elementresult::element { return shift->element_id }
      
 
Chado::Elementresult->has_a(quantification_id => 'Chado::Quantification');
    
sub Chado::Elementresult::quantification { return shift->quantification_id }
       

#
# Has Many
#
 
Chado::Elementresult->has_many('elementresult_relationship_subject_id', 'Chado::Elementresult_Relationship' => 'subject_id');
  
    
sub elementresult_relationship_subject_ids { my $self = shift; return $self->elementresult_relationship_subject_id(@_) }
      
Chado::Elementresult->has_many('elementresult_relationship_object_id', 'Chado::Elementresult_Relationship' => 'object_id');
  
    
sub elementresult_relationship_object_ids { my $self = shift; return $self->elementresult_relationship_object_id(@_) }
       


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Expression########

package Chado::Expression;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Expression->set_up_table('expression');

#
# Primary key accessors
#

sub id { shift->expression_id }
sub expression { shift->expression_id }
 



#
# Has A
#
  
  
  
  
   

#
# Has Many
#
 
Chado::Expression->has_many('expression_pub_expression_id', 'Chado::Expression_Pub' => 'expression_id');
   
Chado::Expression->has_many('feature_expression_expression_id', 'Chado::Feature_Expression' => 'expression_id');
   
Chado::Expression->has_many('expression_image_expression_id', 'Chado::Expression_Image' => 'expression_id');
   
Chado::Expression->has_many('expressionprop_expression_id', 'Chado::Expressionprop' => 'expression_id');
  
    
sub expressionprops { return shift->expressionprop_expression_id }
      
Chado::Expression->has_many('expression_cvterm_expression_id', 'Chado::Expression_Cvterm' => 'expression_id');
  
    
sub expression_cvterms { return shift->expression_cvterm_expression_id }
     



#
# Has Compound Many (many to many relationships in all their flavors)
#
 
  
sub expression_pub_expressions { return shift->expression_pub_expression_id }

   
 
  
sub feature_expression_expressions { return shift->feature_expression_expression_id }

   
 
  
sub feature_expression_expressions { return shift->feature_expression_expression_id }

   
 
  
sub expression_image_expressions { return shift->expression_image_expression_id }

   
# one to many to one
 
  
# one2one #
sub pubs { my $self = shift; return map $_->pub_id, $self->expression_pub_expression_id }

  

sub pubs { my $self = shift; return map $_->pub_id, $self->feature_expression_expression_id }

  

sub features { my $self = shift; return map $_->feature_id, $self->feature_expression_expression_id }

  

sub eimages { my $self = shift; return map $_->eimage_id, $self->expression_image_expression_id }

# one to many to many
 
  
  
  
  
#many to many to one
 
  
  
  
  
#many to many to many


  
  
  
   

1;

########Chado::Magedocumentation########

package Chado::Magedocumentation;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Magedocumentation->set_up_table('magedocumentation');

#
# Primary key accessors
#

sub id { shift->magedocumentation_id }
sub magedocumentation { shift->magedocumentation_id }
 



#
# Has A
#
 
Chado::Magedocumentation->has_a(mageml_id => 'Chado::Mageml');
    
sub Chado::Magedocumentation::mageml { return shift->mageml_id }
      
 
Chado::Magedocumentation->has_a(tableinfo_id => 'Chado::Tableinfo');
    
sub Chado::Magedocumentation::tableinfo { return shift->tableinfo_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Stock_Relationship_Pub########

package Chado::Stock_Relationship_Pub;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Stock_Relationship_Pub->set_up_table('stock_relationship_pub');

#
# Primary key accessors
#

sub id { shift->stock_relationship_pub_id }
sub stock_relationship_pub { shift->stock_relationship_pub_id }
 



#
# Has A
#
 
Chado::Stock_Relationship_Pub->has_a(stock_relationship_id => 'Chado::Stock_Relationship');
    
sub Chado::Stock_Relationship_Pub::stock_relationship { return shift->stock_relationship_id }
      
 
Chado::Stock_Relationship_Pub->has_a(pub_id => 'Chado::Pub');
    
sub Chado::Stock_Relationship_Pub::pub { return shift->pub_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Feature_Relationship_Pub########

package Chado::Feature_Relationship_Pub;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Feature_Relationship_Pub->set_up_table('feature_relationship_pub');

#
# Primary key accessors
#

sub id { shift->feature_relationship_pub_id }
sub feature_relationship_pub { shift->feature_relationship_pub_id }
 



#
# Has A
#
 
Chado::Feature_Relationship_Pub->has_a(feature_relationship_id => 'Chado::Feature_Relationship');
    
sub Chado::Feature_Relationship_Pub::feature_relationship { return shift->feature_relationship_id }
      
 
Chado::Feature_Relationship_Pub->has_a(pub_id => 'Chado::Pub');
    
sub Chado::Feature_Relationship_Pub::pub { return shift->pub_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Analysisprop########

package Chado::Analysisprop;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Analysisprop->set_up_table('analysisprop');

#
# Primary key accessors
#

sub id { shift->analysisprop_id }
sub analysisprop { shift->analysisprop_id }
 



#
# Has A
#
 
Chado::Analysisprop->has_a(analysis_id => 'Chado::Analysis');
    
sub Chado::Analysisprop::analysis { return shift->analysis_id }
      
 
Chado::Analysisprop->has_a(type_id => 'Chado::Cvterm');
    
sub Chado::Analysisprop::cvterm { return shift->type_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Stock_Dbxref########

package Chado::Stock_Dbxref;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Stock_Dbxref->set_up_table('stock_dbxref');

#
# Primary key accessors
#

sub id { shift->stock_dbxref_id }
sub stock_dbxref { shift->stock_dbxref_id }
 



#
# Has A
#
 
Chado::Stock_Dbxref->has_a(stock_id => 'Chado::Stock');
    
sub Chado::Stock_Dbxref::stock { return shift->stock_id }
      
 
Chado::Stock_Dbxref->has_a(dbxref_id => 'Chado::Dbxref');
    
sub Chado::Stock_Dbxref::dbxref { return shift->dbxref_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Cvterm_Dbxref########

package Chado::Cvterm_Dbxref;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Cvterm_Dbxref->set_up_table('cvterm_dbxref');

#
# Primary key accessors
#

sub id { shift->cvterm_dbxref_id }
sub cvterm_dbxref { shift->cvterm_dbxref_id }
 



#
# Has A
#
 
Chado::Cvterm_Dbxref->has_a(cvterm_id => 'Chado::Cvterm');
    
sub Chado::Cvterm_Dbxref::cvterm { return shift->cvterm_id }
      
 
Chado::Cvterm_Dbxref->has_a(dbxref_id => 'Chado::Dbxref');
    
sub Chado::Cvterm_Dbxref::dbxref { return shift->dbxref_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Feature_Relationshipprop########

package Chado::Feature_Relationshipprop;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Feature_Relationshipprop->set_up_table('feature_relationshipprop');

#
# Primary key accessors
#

sub id { shift->feature_relationshipprop_id }
sub feature_relationshipprop { shift->feature_relationshipprop_id }
 



#
# Has A
#
 
Chado::Feature_Relationshipprop->has_a(feature_relationship_id => 'Chado::Feature_Relationship');
    
sub Chado::Feature_Relationshipprop::feature_relationship { return shift->feature_relationship_id }
      
 
Chado::Feature_Relationshipprop->has_a(type_id => 'Chado::Cvterm');
    
sub Chado::Feature_Relationshipprop::cvterm { return shift->type_id }
      
   

#
# Has Many
#
   
Chado::Feature_Relationshipprop->has_many('feature_relationshipprop_pub_feature_relationshipprop_id', 'Chado::Feature_Relationshipprop_Pub' => 'feature_relationshipprop_id');
  



#
# Has Compound Many (many to many relationships in all their flavors)
#
 
  
sub feature_relationshipprop_pub_feature_relationshipprops { return shift->feature_relationshipprop_pub_feature_relationshipprop_id }

   
# one to many to one
 
  
# one2one #
sub pubs { my $self = shift; return map $_->pub_id, $self->feature_relationshipprop_pub_feature_relationshipprop_id }

# one to many to many
 
  
#many to many to one
 
  
#many to many to many


   

1;

########Chado::Stockcollection_Stock########

package Chado::Stockcollection_Stock;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Stockcollection_Stock->set_up_table('stockcollection_stock');

#
# Primary key accessors
#

sub id { shift->stockcollection_stock_id }
sub stockcollection_stock { shift->stockcollection_stock_id }
 



#
# Has A
#
 
Chado::Stockcollection_Stock->has_a(stockcollection_id => 'Chado::Stockcollection');
    
sub Chado::Stockcollection_Stock::stockcollection { return shift->stockcollection_id }
      
 
Chado::Stockcollection_Stock->has_a(stock_id => 'Chado::Stock');
    
sub Chado::Stockcollection_Stock::stock { return shift->stock_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Stockcollectionprop########

package Chado::Stockcollectionprop;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Stockcollectionprop->set_up_table('stockcollectionprop');

#
# Primary key accessors
#

sub id { shift->stockcollectionprop_id }
sub stockcollectionprop { shift->stockcollectionprop_id }
 



#
# Has A
#
 
Chado::Stockcollectionprop->has_a(stockcollection_id => 'Chado::Stockcollection');
    
sub Chado::Stockcollectionprop::stockcollection { return shift->stockcollection_id }
      
 
Chado::Stockcollectionprop->has_a(type_id => 'Chado::Cvterm');
    
sub Chado::Stockcollectionprop::cvterm { return shift->type_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Element_Relationship########

package Chado::Element_Relationship;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Element_Relationship->set_up_table('element_relationship');

#
# Primary key accessors
#

sub id { shift->element_relationship_id }
sub element_relationship { shift->element_relationship_id }
 



#
# Has A
#
 
Chado::Element_Relationship->has_a(subject_id => 'Chado::Element');
    
sub subject { return shift->subject_id }
      
 
Chado::Element_Relationship->has_a(type_id => 'Chado::Cvterm');
    
sub Chado::Element_Relationship::cvterm { return shift->type_id }
      
 
Chado::Element_Relationship->has_a(object_id => 'Chado::Element');
    
sub object { return shift->object_id }
       

#
# Has Many
#
   


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Stock########

package Chado::Stock;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Stock->set_up_table('stock');

#
# Primary key accessors
#

sub id { shift->stock_id }
sub stock { shift->stock_id }
 



#
# Has A
#
  
  
  
  
  
 
Chado::Stock->has_a(dbxref_id => 'Chado::Dbxref');
    
sub Chado::Stock::dbxref { return shift->dbxref_id }
      
 
Chado::Stock->has_a(organism_id => 'Chado::Organism');
    
sub Chado::Stock::organism { return shift->organism_id }
      
 
Chado::Stock->has_a(type_id => 'Chado::Cvterm');
    
sub Chado::Stock::cvterm { return shift->type_id }
      
  
  
   

#
# Has Many
#
 
Chado::Stock->has_many('stock_cvterm_stock_id', 'Chado::Stock_Cvterm' => 'stock_id');
   
Chado::Stock->has_many('stock_relationship_subject_id', 'Chado::Stock_Relationship' => 'subject_id');
  
    
sub stock_relationship_subject_ids { my $self = shift; return $self->stock_relationship_subject_id(@_) }
      
Chado::Stock->has_many('stock_relationship_object_id', 'Chado::Stock_Relationship' => 'object_id');
  
    
sub stock_relationship_object_ids { my $self = shift; return $self->stock_relationship_object_id(@_) }
      
Chado::Stock->has_many('stock_dbxref_stock_id', 'Chado::Stock_Dbxref' => 'stock_id');
  
    
sub stock_dbxrefs { return shift->stock_dbxref_stock_id }
      
Chado::Stock->has_many('stockcollection_stock_stock_id', 'Chado::Stockcollection_Stock' => 'stock_id');
      
Chado::Stock->has_many('stock_pub_stock_id', 'Chado::Stock_Pub' => 'stock_id');
   
Chado::Stock->has_many('stock_genotype_stock_id', 'Chado::Stock_Genotype' => 'stock_id');
   
Chado::Stock->has_many('stockprop_stock_id', 'Chado::Stockprop' => 'stock_id');
  
    
sub stockprops { return shift->stockprop_stock_id }
     



#
# Has Compound Many (many to many relationships in all their flavors)
#
 
  
sub stock_cvterm_stocks { return shift->stock_cvterm_stock_id }

   
 
  
sub stock_cvterm_stocks { return shift->stock_cvterm_stock_id }

   
 
  
sub stock_pub_stocks { return shift->stock_pub_stock_id }

   
 
  
  
sub stockcollection_stock_stocks { return shift->stockcollection_stock_stock_id }
 
 
  
sub stock_genotype_stocks { return shift->stock_genotype_stock_id }

   
# one to many to one
 
  
# one2one #
sub cvterms { my $self = shift; return map $_->cvterm_id, $self->stock_cvterm_stock_id }

  

sub pubs { my $self = shift; return map $_->pub_id, $self->stock_cvterm_stock_id }

  

sub pubs { my $self = shift; return map $_->pub_id, $self->stock_pub_stock_id }

  

sub stockcollections { my $self = shift; return map $_->stockcollection_id, $self->stockcollection_stock_stock_id }

  

sub genotypes { my $self = shift; return map $_->genotype_id, $self->stock_genotype_stock_id }

# one to many to many
 
  
  
  
  
  
#many to many to one
 
  
  
  
  
  
#many to many to many


  
  
  
  
   

1;

########Chado::Featuremap########

package Chado::Featuremap;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Featuremap->set_up_table('featuremap');

#
# Primary key accessors
#

sub id { shift->featuremap_id }
sub featuremap { shift->featuremap_id }
 



#
# Has A
#
  
  
 
Chado::Featuremap->has_a(unittype_id => 'Chado::Cvterm');
    
sub Chado::Featuremap::cvterm { return shift->unittype_id }
      
   

#
# Has Many
#
 
Chado::Featuremap->has_many('featurerange_featuremap_id', 'Chado::Featurerange' => 'featuremap_id');
  
    
sub featureranges { return shift->featurerange_featuremap_id }
      
Chado::Featuremap->has_many('featurepos_featuremap_id', 'Chado::Featurepos' => 'featuremap_id');
  
    
sub featureposs { return shift->featurepos_featuremap_id }
       
Chado::Featuremap->has_many('featuremap_pub_featuremap_id', 'Chado::Featuremap_Pub' => 'featuremap_id');
  



#
# Has Compound Many (many to many relationships in all their flavors)
#
 
  
sub featuremap_pub_featuremaps { return shift->featuremap_pub_featuremap_id }

   
# one to many to one
 
  
# one2one #
sub pubs { my $self = shift; return map $_->pub_id, $self->featuremap_pub_featuremap_id }

# one to many to many
 
  
#many to many to one
 
  
#many to many to many


   

1;

########Chado::Treatment########

package Chado::Treatment;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Treatment->set_up_table('treatment');

#
# Primary key accessors
#

sub id { shift->treatment_id }
sub treatment { shift->treatment_id }
 



#
# Has A
#
  
 
Chado::Treatment->has_a(biomaterial_id => 'Chado::Biomaterial');
    
sub Chado::Treatment::biomaterial { return shift->biomaterial_id }
      
 
Chado::Treatment->has_a(type_id => 'Chado::Cvterm');
    
sub Chado::Treatment::cvterm { return shift->type_id }
      
 
Chado::Treatment->has_a(protocol_id => 'Chado::Protocol');
    
sub Chado::Treatment::protocol { return shift->protocol_id }
       

#
# Has Many
#
 
Chado::Treatment->has_many('biomaterial_treatment_treatment_id', 'Chado::Biomaterial_Treatment' => 'treatment_id');
  
    
sub biomaterial_treatments { return shift->biomaterial_treatment_treatment_id }
        


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Pubprop########

package Chado::Pubprop;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Pubprop->set_up_table('pubprop');

#
# Primary key accessors
#

sub id { shift->pubprop_id }
sub pubprop { shift->pubprop_id }
 



#
# Has A
#
 
Chado::Pubprop->has_a(pub_id => 'Chado::Pub');
    
sub Chado::Pubprop::pub { return shift->pub_id }
      
 
Chado::Pubprop->has_a(type_id => 'Chado::Cvterm');
    
sub Chado::Pubprop::cvterm { return shift->type_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Phylonode_Dbxref########

package Chado::Phylonode_Dbxref;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Phylonode_Dbxref->set_up_table('phylonode_dbxref');

#
# Primary key accessors
#

sub id { shift->phylonode_dbxref_id }
sub phylonode_dbxref { shift->phylonode_dbxref_id }
 



#
# Has A
#
 
Chado::Phylonode_Dbxref->has_a(phylonode_id => 'Chado::Phylonode');
    
sub Chado::Phylonode_Dbxref::phylonode { return shift->phylonode_id }
      
 
Chado::Phylonode_Dbxref->has_a(dbxref_id => 'Chado::Dbxref');
    
sub Chado::Phylonode_Dbxref::dbxref { return shift->dbxref_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Quantificationprop########

package Chado::Quantificationprop;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Quantificationprop->set_up_table('quantificationprop');

#
# Primary key accessors
#

sub id { shift->quantificationprop_id }
sub quantificationprop { shift->quantificationprop_id }
 



#
# Has A
#
 
Chado::Quantificationprop->has_a(quantification_id => 'Chado::Quantification');
    
sub Chado::Quantificationprop::quantification { return shift->quantification_id }
      
 
Chado::Quantificationprop->has_a(type_id => 'Chado::Cvterm');
    
sub Chado::Quantificationprop::cvterm { return shift->type_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Expression_Cvterm########

package Chado::Expression_Cvterm;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Expression_Cvterm->set_up_table('expression_cvterm');

#
# Primary key accessors
#

sub id { shift->expression_cvterm_id }
sub expression_cvterm { shift->expression_cvterm_id }
 



#
# Has A
#
 
Chado::Expression_Cvterm->has_a(expression_id => 'Chado::Expression');
    
sub Chado::Expression_Cvterm::expression { return shift->expression_id }
      
 
Chado::Expression_Cvterm->has_a(cvterm_id => 'Chado::Cvterm');
    
sub cvterm { return shift->cvterm_id }
      
 
Chado::Expression_Cvterm->has_a(cvterm_type_id => 'Chado::Cvterm');
    
sub cvterm_type { return shift->cvterm_type_id }
      
   

#
# Has Many
#
    
Chado::Expression_Cvterm->has_many('expression_cvtermprop_expression_cvterm_id', 'Chado::Expression_Cvtermprop' => 'expression_cvterm_id');
  
    
sub expression_cvtermprops { return shift->expression_cvtermprop_expression_cvterm_id }
     


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Cv########

package Chado::Cv;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Cv->set_up_table('cv');

#
# Primary key accessors
#

sub id { shift->cv_id }
sub cv { shift->cv_id }
 



#
# Has A
#
  
   

#
# Has Many
#
 
Chado::Cv->has_many('cvtermpath_cv_id', 'Chado::Cvtermpath' => 'cv_id');
  
    
sub cvtermpaths { return shift->cvtermpath_cv_id }
      
Chado::Cv->has_many('cvterm_cv_id', 'Chado::Cvterm' => 'cv_id');
  
    
sub cvterms { return shift->cvterm_cv_id }
     


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Feature_Cvterm_Pub########

package Chado::Feature_Cvterm_Pub;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Feature_Cvterm_Pub->set_up_table('feature_cvterm_pub');

#
# Primary key accessors
#

sub id { shift->feature_cvterm_pub_id }
sub feature_cvterm_pub { shift->feature_cvterm_pub_id }
 



#
# Has A
#
 
Chado::Feature_Cvterm_Pub->has_a(feature_cvterm_id => 'Chado::Feature_Cvterm');
    
sub Chado::Feature_Cvterm_Pub::feature_cvterm { return shift->feature_cvterm_id }
      
 
Chado::Feature_Cvterm_Pub->has_a(pub_id => 'Chado::Pub');
    
sub Chado::Feature_Cvterm_Pub::pub { return shift->pub_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Project########

package Chado::Project;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Project->set_up_table('project');

#
# Primary key accessors
#

sub id { shift->project_id }
sub project { shift->project_id }
 



#
# Has A
#
   

#
# Has Many
#
 
Chado::Project->has_many('assay_project_project_id', 'Chado::Assay_Project' => 'project_id');
  



#
# Has Compound Many (many to many relationships in all their flavors)
#
 
  
  
sub assay_project_projects { return shift->assay_project_project_id }
 
# one to many to one
 
  
# one2one #
sub assays { my $self = shift; return map $_->assay_id, $self->assay_project_project_id }

# one to many to many
 
  
#many to many to one
 
  
#many to many to many


   

1;

########Chado::Contact########

package Chado::Contact;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Contact->set_up_table('contact');

#
# Primary key accessors
#

sub id { shift->contact_id }
sub contact { shift->contact_id }
 



#
# Has A
#
  
  
  
  
  
  
  
 
Chado::Contact->has_a(type_id => 'Chado::Cvterm');
    
sub Chado::Contact::cvterm { return shift->type_id }
      
   

#
# Has Many
#
 
Chado::Contact->has_many('assay_operator_id', 'Chado::Assay' => 'operator_id');
  
    
sub assays { return shift->assay_operator_id }
      
Chado::Contact->has_many('quantification_operator_id', 'Chado::Quantification' => 'operator_id');
  
    
sub quantifications { return shift->quantification_operator_id }
      
Chado::Contact->has_many('arraydesign_manufacturer_id', 'Chado::Arraydesign' => 'manufacturer_id');
  
    
sub arraydesigns { return shift->arraydesign_manufacturer_id }
      
Chado::Contact->has_many('study_contact_id', 'Chado::Study' => 'contact_id');
  
    
sub studys { return shift->study_contact_id }
      
Chado::Contact->has_many('contact_relationship_subject_id', 'Chado::Contact_Relationship' => 'subject_id');
   
Chado::Contact->has_many('contact_relationship_object_id', 'Chado::Contact_Relationship' => 'object_id');
   
Chado::Contact->has_many('stockcollection_contact_id', 'Chado::Stockcollection' => 'contact_id');
  
    
sub stockcollections { return shift->stockcollection_contact_id }
       
Chado::Contact->has_many('biomaterial_biosourceprovider_id', 'Chado::Biomaterial' => 'biosourceprovider_id');
  
    
sub biomaterials { return shift->biomaterial_biosourceprovider_id }
     



#
# Has Compound Many (many to many relationships in all their flavors)
#
 
  
  
sub contact_relationship_subjects { return shift->contact_relationship_subject_id }

  
sub contact_relationship_objects { return shift->contact_relationship_object_id }
 
# one to many to one
 
  
# one to many to many
 
  
#many to many to one
 
  
# many2one #
  
  
sub contact_relationship_subject_types { my $self = shift; return map $_->type_id, $self->contact_relationship_subject_id }
    
  
sub contact_relationship_object_types { my $self = shift; return map $_->type_id, $self->contact_relationship_object_id }
    
   
#many to many to many


   

1;

########Chado::Featureprop########

package Chado::Featureprop;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Featureprop->set_up_table('featureprop');

#
# Primary key accessors
#

sub id { shift->featureprop_id }
sub featureprop { shift->featureprop_id }
 



#
# Has A
#
 
Chado::Featureprop->has_a(feature_id => 'Chado::Feature');
    
sub Chado::Featureprop::feature { return shift->feature_id }
      
 
Chado::Featureprop->has_a(type_id => 'Chado::Cvterm');
    
sub Chado::Featureprop::cvterm { return shift->type_id }
      
   

#
# Has Many
#
   
Chado::Featureprop->has_many('featureprop_pub_featureprop_id', 'Chado::Featureprop_Pub' => 'featureprop_id');
  



#
# Has Compound Many (many to many relationships in all their flavors)
#
 
  
sub featureprop_pub_featureprops { return shift->featureprop_pub_featureprop_id }

   
# one to many to one
 
  
# one2one #
sub pubs { my $self = shift; return map $_->pub_id, $self->featureprop_pub_featureprop_id }

# one to many to many
 
  
#many to many to one
 
  
#many to many to many


   

1;

########Chado::Phylonode_Relationship########

package Chado::Phylonode_Relationship;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Phylonode_Relationship->set_up_table('phylonode_relationship');

#
# Primary key accessors
#

sub id { shift->phylonode_relationship_id }
sub phylonode_relationship { shift->phylonode_relationship_id }
 



#
# Has A
#
 
Chado::Phylonode_Relationship->has_a(subject_id => 'Chado::Phylonode');
    
sub subject { return shift->subject_id }
      
 
Chado::Phylonode_Relationship->has_a(object_id => 'Chado::Phylonode');
    
sub object { return shift->object_id }
      
 
Chado::Phylonode_Relationship->has_a(type_id => 'Chado::Cvterm');
    
sub Chado::Phylonode_Relationship::cvterm { return shift->type_id }
       

#
# Has Many
#
   


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Stock_Pub########

package Chado::Stock_Pub;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Stock_Pub->set_up_table('stock_pub');

#
# Primary key accessors
#

sub id { shift->stock_pub_id }
sub stock_pub { shift->stock_pub_id }
 



#
# Has A
#
 
Chado::Stock_Pub->has_a(stock_id => 'Chado::Stock');
    
sub Chado::Stock_Pub::stock { return shift->stock_id }
      
 
Chado::Stock_Pub->has_a(pub_id => 'Chado::Pub');
    
sub Chado::Stock_Pub::pub { return shift->pub_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Stock_Genotype########

package Chado::Stock_Genotype;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Stock_Genotype->set_up_table('stock_genotype');

#
# Primary key accessors
#

sub id { shift->stock_genotype_id }
sub stock_genotype { shift->stock_genotype_id }
 



#
# Has A
#
 
Chado::Stock_Genotype->has_a(stock_id => 'Chado::Stock');
    
sub Chado::Stock_Genotype::stock { return shift->stock_id }
      
 
Chado::Stock_Genotype->has_a(genotype_id => 'Chado::Genotype');
    
sub Chado::Stock_Genotype::genotype { return shift->genotype_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Protocolparam########

package Chado::Protocolparam;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Protocolparam->set_up_table('protocolparam');

#
# Primary key accessors
#

sub id { shift->protocolparam_id }
sub protocolparam { shift->protocolparam_id }
 



#
# Has A
#
 
Chado::Protocolparam->has_a(protocol_id => 'Chado::Protocol');
    
sub Chado::Protocolparam::protocol { return shift->protocol_id }
      
 
Chado::Protocolparam->has_a(datatype_id => 'Chado::Cvterm');
    
sub datatype { return shift->datatype_id }
      
 
Chado::Protocolparam->has_a(unittype_id => 'Chado::Cvterm');
    
sub unittype { return shift->unittype_id }
       

#
# Has Many
#
   


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Feature_Synonym########

package Chado::Feature_Synonym;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Feature_Synonym->set_up_table('feature_synonym');

#
# Primary key accessors
#

sub id { shift->feature_synonym_id }
sub feature_synonym { shift->feature_synonym_id }
 



#
# Has A
#
 
Chado::Feature_Synonym->has_a(synonym_id => 'Chado::Synonym');
    
sub Chado::Feature_Synonym::synonym { return shift->synonym_id }
      
 
Chado::Feature_Synonym->has_a(feature_id => 'Chado::Feature');
    
sub Chado::Feature_Synonym::feature { return shift->feature_id }
      
 
Chado::Feature_Synonym->has_a(pub_id => 'Chado::Pub');
    
sub Chado::Feature_Synonym::pub { return shift->pub_id }
       

#
# Has Many
#
   


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Control########

package Chado::Control;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Control->set_up_table('control');

#
# Primary key accessors
#

sub id { shift->control_id }
sub control { shift->control_id }
 



#
# Has A
#
 
Chado::Control->has_a(type_id => 'Chado::Cvterm');
    
sub Chado::Control::cvterm { return shift->type_id }
      
 
Chado::Control->has_a(assay_id => 'Chado::Assay');
    
sub Chado::Control::assay { return shift->assay_id }
      
 
Chado::Control->has_a(tableinfo_id => 'Chado::Tableinfo');
    
sub Chado::Control::tableinfo { return shift->tableinfo_id }
       

#
# Has Many
#
   


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;


########Chado::Phenotype_Cvterm########

package Chado::Phenotype_Cvterm;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Phenotype_Cvterm->set_up_table('phenotype_cvterm');

#
# Primary key accessors
#

sub id { shift->phenotype_cvterm_id }
sub phenotype_cvterm { shift->phenotype_cvterm_id }


#
# Has A
#
 
Chado::Phenotype_Cvterm->has_a(phenotype_id => 'Chado::Phenotype');
    
sub Chado::Phenotype_Cvterm::phenotype { return shift->phenotype_id }
      
 
Chado::Phenotype_Cvterm->has_a(cvterm_id => 'Chado::Cvterm');
    
sub Chado::Phenotype_Cvterm::cvterm { return shift->cvterm_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Stockprop########

package Chado::Stockprop;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Stockprop->set_up_table('stockprop');

#
# Primary key accessors
#

sub id { shift->stockprop_id }
sub stockprop { shift->stockprop_id }
 



#
# Has A
#
  
 
Chado::Stockprop->has_a(stock_id => 'Chado::Stock');
    
sub Chado::Stockprop::stock { return shift->stock_id }
      
 
Chado::Stockprop->has_a(type_id => 'Chado::Cvterm');
    
sub Chado::Stockprop::cvterm { return shift->type_id }
       

#
# Has Many
#
 
Chado::Stockprop->has_many('stockprop_pub_stockprop_id', 'Chado::Stockprop_Pub' => 'stockprop_id');
    



#
# Has Compound Many (many to many relationships in all their flavors)
#
 
  
sub stockprop_pub_stockprops { return shift->stockprop_pub_stockprop_id }

   
# one to many to one
 
  
# one2one #
sub pubs { my $self = shift; return map $_->pub_id, $self->stockprop_pub_stockprop_id }

# one to many to many
 
  
#many to many to one
 
  
#many to many to many


   

1;

########Chado::Feature_Genotype########

package Chado::Feature_Genotype;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Feature_Genotype->set_up_table('feature_genotype');

#
# Primary key accessors
#

sub id { shift->feature_genotype_id }
sub feature_genotype { shift->feature_genotype_id }
 



#
# Has A
#
 
Chado::Feature_Genotype->has_a(feature_id => 'Chado::Feature');
    
sub feature { return shift->feature_id }
      
 
Chado::Feature_Genotype->has_a(genotype_id => 'Chado::Genotype');
    
sub Chado::Feature_Genotype::genotype { return shift->genotype_id }
      
 
Chado::Feature_Genotype->has_a(chromosome_id => 'Chado::Feature');
    
sub chromosome { return shift->chromosome_id }
      
 
Chado::Feature_Genotype->has_a(cvterm_id => 'Chado::Cvterm');
    
sub Chado::Feature_Genotype::cvterm { return shift->cvterm_id }
       

#
# Has Many
#
    


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Featuremap_Pub########

package Chado::Featuremap_Pub;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Featuremap_Pub->set_up_table('featuremap_pub');

#
# Primary key accessors
#

sub id { shift->featuremap_pub_id }
sub featuremap_pub { shift->featuremap_pub_id }
 



#
# Has A
#
 
Chado::Featuremap_Pub->has_a(featuremap_id => 'Chado::Featuremap');
    
sub Chado::Featuremap_Pub::featuremap { return shift->featuremap_id }
      
 
Chado::Featuremap_Pub->has_a(pub_id => 'Chado::Pub');
    
sub Chado::Featuremap_Pub::pub { return shift->pub_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Cvterm########

package Chado::Cvterm;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Cvterm->set_up_table('cvterm');

#
# Primary key accessors
#

sub id { shift->cvterm_id }
sub cvterm { shift->cvterm_id }
 



#
# Has A
#
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
 
Chado::Cvterm->has_a(cv_id => 'Chado::Cv');
    
sub Chado::Cvterm::cv { return shift->cv_id }
      
 
Chado::Cvterm->has_a(dbxref_id => 'Chado::Dbxref');
    
sub Chado::Cvterm::dbxref { return shift->dbxref_id }
      
  
  
  
  
  
  
  
  
  
   

#
# Has Many
#
 
Chado::Cvterm->has_many('studyfactor_type_id', 'Chado::Studyfactor' => 'type_id');
  
    
sub studyfactors { return shift->studyfactor_type_id }
      
Chado::Cvterm->has_many('feature_cvterm_cvterm_id', 'Chado::Feature_Cvterm' => 'cvterm_id');
  
    
sub feature_cvterms { return shift->feature_cvterm_cvterm_id }
      
Chado::Cvterm->has_many('arraydesign_platformtype_id', 'Chado::Arraydesign' => 'platformtype_id');
  
sub arraydesign_platformtypes { return shift->arraydesign_platformtype_id }
#sub --arraydesign--platformtype_id-- {}
   
Chado::Cvterm->has_many('arraydesign_substratetype_id', 'Chado::Arraydesign' => 'substratetype_id');
  
sub arraydesign_substratetypes { return shift->arraydesign_substratetype_id }
#sub --arraydesign--substratetype_id-- {}
   
Chado::Cvterm->has_many('phylonodeprop_type_id', 'Chado::Phylonodeprop' => 'type_id');
  
    
sub phylonodeprops { return shift->phylonodeprop_type_id }
      
Chado::Cvterm->has_many('stock_cvterm_cvterm_id', 'Chado::Stock_Cvterm' => 'cvterm_id');
   
Chado::Cvterm->has_many('biomaterial_relationship_type_id', 'Chado::Biomaterial_Relationship' => 'type_id');
   
Chado::Cvterm->has_many('cvtermprop_cvterm_id', 'Chado::Cvtermprop' => 'cvterm_id');
  
    
sub cvtermprop_cvterm_ids { my $self = shift; return $self->cvtermprop_cvterm_id(@_) }
      
Chado::Cvterm->has_many('cvtermprop_type_id', 'Chado::Cvtermprop' => 'type_id');
  
    
sub cvtermprop_type_ids { my $self = shift; return $self->cvtermprop_type_id(@_) }
      
Chado::Cvterm->has_many('quantification_relationship_type_id', 'Chado::Quantification_Relationship' => 'type_id');
   
Chado::Cvterm->has_many('element_type_id', 'Chado::Element' => 'type_id');
   
Chado::Cvterm->has_many('arraydesignprop_type_id', 'Chado::Arraydesignprop' => 'type_id');
  
    
sub arraydesignprops { return shift->arraydesignprop_type_id }
      
Chado::Cvterm->has_many('synonym_type_id', 'Chado::Synonym' => 'type_id');
  
    
sub synonyms { return shift->synonym_type_id }
      
Chado::Cvterm->has_many('cvtermpath_type_id', 'Chado::Cvtermpath' => 'type_id');
  
    
sub cvtermpath_type_ids { my $self = shift; return $self->cvtermpath_type_id(@_) }
      
Chado::Cvterm->has_many('cvtermpath_subject_id', 'Chado::Cvtermpath' => 'subject_id');
  
    
sub cvtermpath_subject_ids { my $self = shift; return $self->cvtermpath_subject_id(@_) }
      
Chado::Cvterm->has_many('cvtermpath_object_id', 'Chado::Cvtermpath' => 'object_id');
  
    
sub cvtermpath_object_ids { my $self = shift; return $self->cvtermpath_object_id(@_) }
      
Chado::Cvterm->has_many('biomaterial_treatment_unittype_id', 'Chado::Biomaterial_Treatment' => 'unittype_id');
  
    
sub biomaterial_treatments { return shift->biomaterial_treatment_unittype_id }
      
Chado::Cvterm->has_many('expressionprop_type_id', 'Chado::Expressionprop' => 'type_id');
  
    
sub expressionprops { return shift->expressionprop_type_id }
      
Chado::Cvterm->has_many('cvterm_relationship_type_id', 'Chado::Cvterm_Relationship' => 'type_id');
   
Chado::Cvterm->has_many('cvterm_relationship_subject_id', 'Chado::Cvterm_Relationship' => 'subject_id');
   
Chado::Cvterm->has_many('cvterm_relationship_object_id', 'Chado::Cvterm_Relationship' => 'object_id');
   
Chado::Cvterm->has_many('acquisitionprop_type_id', 'Chado::Acquisitionprop' => 'type_id');
  
    
sub acquisitionprops { return shift->acquisitionprop_type_id }
      
Chado::Cvterm->has_many('studydesignprop_type_id', 'Chado::Studydesignprop' => 'type_id');
  
    
sub studydesignprops { return shift->studydesignprop_type_id }
      
Chado::Cvterm->has_many('assayprop_type_id', 'Chado::Assayprop' => 'type_id');
  
    
sub assayprops { return shift->assayprop_type_id }
      
Chado::Cvterm->has_many('environment_cvterm_cvterm_id', 'Chado::Environment_Cvterm' => 'cvterm_id');
   
Chado::Cvterm->has_many('contact_relationship_type_id', 'Chado::Contact_Relationship' => 'type_id');
   
Chado::Cvterm->has_many('pub_type_id', 'Chado::Pub' => 'type_id');
  
sub pub_types { return shift->pub_type_id }
#sub --pub--type_id-- {}
   
Chado::Cvterm->has_many('organismprop_type_id', 'Chado::Organismprop' => 'type_id');
  
    
sub organismprops { return shift->organismprop_type_id }
      
Chado::Cvterm->has_many('dbxrefprop_type_id', 'Chado::Dbxrefprop' => 'type_id');
  
    
sub dbxrefprops { return shift->dbxrefprop_type_id }
      
Chado::Cvterm->has_many('feature_relationship_type_id', 'Chado::Feature_Relationship' => 'type_id');
  
    
sub feature_relationships { return shift->feature_relationship_type_id }
      
Chado::Cvterm->has_many('acquisition_relationship_type_id', 'Chado::Acquisition_Relationship' => 'type_id');
  
    
sub acquisition_relationships { return shift->acquisition_relationship_type_id }
         
Chado::Cvterm->has_many('phenotype_comparison_type_id', 'Chado::Phenotype_Comparison' => 'type_id');
   
Chado::Cvterm->has_many('feature_cvtermprop_type_id', 'Chado::Feature_Cvtermprop' => 'type_id');
  
    
sub feature_cvtermprops { return shift->feature_cvtermprop_type_id }
      
Chado::Cvterm->has_many('protocol_type_id', 'Chado::Protocol' => 'type_id');
  
    
sub protocols { return shift->protocol_type_id }
      
Chado::Cvterm->has_many('elementresult_relationship_type_id', 'Chado::Elementresult_Relationship' => 'type_id');
  
    
sub elementresult_relationships { return shift->elementresult_relationship_type_id }
      
Chado::Cvterm->has_many('cvtermsynonym_cvterm_id', 'Chado::Cvtermsynonym' => 'cvterm_id');
  
    
sub cvtermsynonym_cvterm_ids { my $self = shift; return $self->cvtermsynonym_cvterm_id(@_) }
      
Chado::Cvterm->has_many('cvtermsynonym_type_id', 'Chado::Cvtermsynonym' => 'type_id');
  
    
sub cvtermsynonym_type_ids { my $self = shift; return $self->cvtermsynonym_type_id(@_) }
      
Chado::Cvterm->has_many('phylonode_type_id', 'Chado::Phylonode' => 'type_id');
  
    
sub phylonodes { return shift->phylonode_type_id }
      
Chado::Cvterm->has_many('stock_relationship_type_id', 'Chado::Stock_Relationship' => 'type_id');
  
    
sub stock_relationships { return shift->stock_relationship_type_id }
      
Chado::Cvterm->has_many('feature_type_id', 'Chado::Feature' => 'type_id');
  
sub feature_types { return shift->feature_type_id }
#sub --feature--type_id-- {}
   
Chado::Cvterm->has_many('feature_pubprop_type_id', 'Chado::Feature_Pubprop' => 'type_id');
  
    
sub feature_pubprops { return shift->feature_pubprop_type_id }
      
Chado::Cvterm->has_many('stockcollection_type_id', 'Chado::Stockcollection' => 'type_id');
  
    
sub stockcollections { return shift->stockcollection_type_id }
      
Chado::Cvterm->has_many('biomaterialprop_type_id', 'Chado::Biomaterialprop' => 'type_id');
  
    
sub biomaterialprops { return shift->biomaterialprop_type_id }
      
Chado::Cvterm->has_many('analysisprop_type_id', 'Chado::Analysisprop' => 'type_id');
  
    
sub analysisprops { return shift->analysisprop_type_id }
      
Chado::Cvterm->has_many('cvterm_dbxref_cvterm_id', 'Chado::Cvterm_Dbxref' => 'cvterm_id');
  
    
sub cvterm_dbxrefs { return shift->cvterm_dbxref_cvterm_id }
      
Chado::Cvterm->has_many('feature_relationshipprop_type_id', 'Chado::Feature_Relationshipprop' => 'type_id');
  
    
sub feature_relationshipprops { return shift->feature_relationshipprop_type_id }
      
Chado::Cvterm->has_many('stockcollectionprop_type_id', 'Chado::Stockcollectionprop' => 'type_id');
  
    
sub stockcollectionprops { return shift->stockcollectionprop_type_id }
      
Chado::Cvterm->has_many('element_relationship_type_id', 'Chado::Element_Relationship' => 'type_id');
  
    
sub element_relationships { return shift->element_relationship_type_id }
      
Chado::Cvterm->has_many('stock_type_id', 'Chado::Stock' => 'type_id');
  
sub stock_types { return shift->stock_type_id }
#sub --stock--type_id-- {}
   
Chado::Cvterm->has_many('featuremap_unittype_id', 'Chado::Featuremap' => 'unittype_id');
  
    
sub featuremaps { return shift->featuremap_unittype_id }
      
Chado::Cvterm->has_many('treatment_type_id', 'Chado::Treatment' => 'type_id');
  
    
sub treatments { return shift->treatment_type_id }
      
Chado::Cvterm->has_many('pubprop_type_id', 'Chado::Pubprop' => 'type_id');
  
    
sub pubprops { return shift->pubprop_type_id }
      
Chado::Cvterm->has_many('quantificationprop_type_id', 'Chado::Quantificationprop' => 'type_id');
  
    
sub quantificationprops { return shift->quantificationprop_type_id }
      
Chado::Cvterm->has_many('expression_cvterm_cvterm_id', 'Chado::Expression_Cvterm' => 'cvterm_id');
  
    
sub expression_cvterm_cvterm_ids { my $self = shift; return $self->expression_cvterm_cvterm_id(@_) }
      
Chado::Cvterm->has_many('expression_cvterm_cvterm_type_id', 'Chado::Expression_Cvterm' => 'cvterm_type_id');
  
    
sub expression_cvterm_cvterm_type_ids { my $self = shift; return $self->expression_cvterm_cvterm_type_id(@_) }
      
Chado::Cvterm->has_many('contact_type_id', 'Chado::Contact' => 'type_id');
  
sub contact_types { return shift->contact_type_id }
#sub --contact--type_id-- {}
   
Chado::Cvterm->has_many('featureprop_type_id', 'Chado::Featureprop' => 'type_id');
  
    
sub featureprops { return shift->featureprop_type_id }
      
Chado::Cvterm->has_many('phylonode_relationship_type_id', 'Chado::Phylonode_Relationship' => 'type_id');
  
    
sub phylonode_relationships { return shift->phylonode_relationship_type_id }
      
Chado::Cvterm->has_many('protocolparam_datatype_id', 'Chado::Protocolparam' => 'datatype_id');
  
    
sub protocolparam_datatype_ids { my $self = shift; return $self->protocolparam_datatype_id(@_) }
      
Chado::Cvterm->has_many('protocolparam_unittype_id', 'Chado::Protocolparam' => 'unittype_id');
  
    
sub protocolparam_unittype_ids { my $self = shift; return $self->protocolparam_unittype_id(@_) }
      
Chado::Cvterm->has_many('control_type_id', 'Chado::Control' => 'type_id');
  
    
sub controls { return shift->control_type_id }
            
Chado::Cvterm->has_many('phenotype_cvterm_cvterm_id', 'Chado::Phenotype_Cvterm' => 'cvterm_id');
   
Chado::Cvterm->has_many('stockprop_type_id', 'Chado::Stockprop' => 'type_id');
  
    
sub stockprops { return shift->stockprop_type_id }
      
Chado::Cvterm->has_many('feature_genotype_cvterm_id', 'Chado::Feature_Genotype' => 'cvterm_id');
  
    
sub feature_genotypes { return shift->feature_genotype_cvterm_id }
        
Chado::Cvterm->has_many('phenstatement_type_id', 'Chado::Phenstatement' => 'type_id');
   
Chado::Cvterm->has_many('expression_cvtermprop_type_id', 'Chado::Expression_Cvtermprop' => 'type_id');
  
    
sub expression_cvtermprops { return shift->expression_cvtermprop_type_id }
      
Chado::Cvterm->has_many('phenotype_observable_id', 'Chado::Phenotype' => 'observable_id');
  
sub phenotype_observables { return shift->phenotype_observable_id }
#sub --phenotype--observable_id-- {}
   
Chado::Cvterm->has_many('phenotype_attr_id', 'Chado::Phenotype' => 'attr_id');
  
sub phenotype_attrs { return shift->phenotype_attr_id }
#sub --phenotype--attr_id-- {}
   
Chado::Cvterm->has_many('phenotype_cvalue_id', 'Chado::Phenotype' => 'cvalue_id');
  
sub phenotype_cvalues { return shift->phenotype_cvalue_id }
#sub --phenotype--cvalue_id-- {}
   
Chado::Cvterm->has_many('phenotype_assay_id', 'Chado::Phenotype' => 'assay_id');
  
sub phenotype_assays { return shift->phenotype_assay_id }
#sub --phenotype--assay_id-- {}
   
Chado::Cvterm->has_many('phendesc_type_id', 'Chado::Phendesc' => 'type_id');
  
    
sub phendescs { return shift->phendesc_type_id }
      
Chado::Cvterm->has_many('phylotree_type_id', 'Chado::Phylotree' => 'type_id');
  
    
sub phylotrees { return shift->phylotree_type_id }
      
Chado::Cvterm->has_many('feature_expressionprop_type_id', 'Chado::Feature_Expressionprop' => 'type_id');
  
    
sub feature_expressionprops { return shift->feature_expressionprop_type_id }
      
Chado::Cvterm->has_many('pub_relationship_type_id', 'Chado::Pub_Relationship' => 'type_id');
  



#
# Has Compound Many (many to many relationships in all their flavors)
#
 
  
  
sub phenstatement_types { return shift->phenstatement_type_id }
 
 
  
  
sub phenstatement_types { return shift->phenstatement_type_id }
 
 
  
  
sub phenstatement_types { return shift->phenstatement_type_id }
 
 
  
sub phenstatement_types { return shift->phenstatement_type_id }

   
 
  
  
sub biomaterial_relationship_types { return shift->biomaterial_relationship_type_id }

   
 
  
sub stock_cvterm_cvterms { return shift->stock_cvterm_cvterm_id }

   
 
  
  
sub stock_cvterm_cvterms { return shift->stock_cvterm_cvterm_id }
 
 
  
sub element_types { return shift->element_type_id }

   
 
  
  
sub element_types { return shift->element_type_id }
 
 
  
  
sub element_types { return shift->element_type_id }
 
 
sub contact_relationship_types { return shift->contact_relationship_type_id }
  
sub quantification_relationship_types { return shift->quantification_relationship_type_id }

   
 
  
sub cvterm_relationship_types { return shift->cvterm_relationship_type_id }

  
sub cvterm_relationship_subjects { return shift->cvterm_relationship_subject_id }

  
sub cvterm_relationship_objects { return shift->cvterm_relationship_object_id }
 
 
  
  
  
sub pub_relationship_types { return shift->pub_relationship_type_id }
 
 
  
  
sub environment_cvterm_cvterms { return shift->environment_cvterm_cvterm_id }
 
 
  
  
sub phenotype_cvterm_cvterms { return shift->phenotype_cvterm_cvterm_id }
 
 
  
  
  
sub phenotype_comparison_types { return shift->phenotype_comparison_type_id }
 
 
  
  
  
sub phenotype_comparison_types { return shift->phenotype_comparison_type_id }
 
 
  
  
  
sub phenotype_comparison_types { return shift->phenotype_comparison_type_id }
 
 
  
sub phenotype_comparison_types { return shift->phenotype_comparison_type_id }

   
# one to many to one
 
  
# one2one #
sub environments { my $self = shift; return map $_->environment_id, $self->phenstatement_type_id }

  

sub phenotypes { my $self = shift; return map $_->phenotype_id, $self->phenstatement_type_id }

  

sub genotypes { my $self = shift; return map $_->genotype_id, $self->phenstatement_type_id }

  

sub pubs { my $self = shift; return map $_->pub_id, $self->phenstatement_type_id }

  
  

sub pubs { my $self = shift; return map $_->pub_id, $self->stock_cvterm_cvterm_id }

  

sub stocks { my $self = shift; return map $_->stock_id, $self->stock_cvterm_cvterm_id }

  

sub dbxrefs { my $self = shift; return map $_->dbxref_id, $self->element_type_id }

  

sub arraydesigns { my $self = shift; return map $_->arraydesign_id, $self->element_type_id }

  

sub features { my $self = shift; return map $_->feature_id, $self->element_type_id }

  
  
  
  
  

sub environments { my $self = shift; return map $_->environment_id, $self->environment_cvterm_cvterm_id }

  

sub phenotypes { my $self = shift; return map $_->phenotype_id, $self->phenotype_cvterm_cvterm_id }

  
  
  
  

sub pubs { my $self = shift; return map $_->pub_id, $self->phenotype_comparison_type_id }

# one to many to many
 
  
  
  
  
  
# one2many #
  
  
  
    
sub biomaterial_relationship_subjects { my $self = shift; return map $_->subject_id, $self->biomaterial_relationship_type_id }
    
  
     
  
  
  
  
  
  

  
  
  
    
  
  
    
sub contact_relationship_subjects { my $self = shift; return map $_->subject_id, $self->contact_relationship_type_id }
    
  
     
  

  
  
  
    
sub quantification_relationship_subjects { my $self = shift; return map $_->subject_id, $self->quantification_relationship_type_id }
    
  
     
  

  
  
  
    
sub pub_relationship_subjects { my $self = shift; return map $_->subject_id, $self->pub_relationship_type_id }
    
  
     
  
  
  

  
  
  
    
sub phenotype_comparison_environment1s { my $self = shift; return map $_->environment1_id, $self->phenotype_comparison_type_id }
    
  
     
  

  
  
  
    
sub phenotype_comparison_phenotype1s { my $self = shift; return map $_->phenotype1_id, $self->phenotype_comparison_type_id }
    
  
     
  

  
  
  
    
sub phenotype_comparison_genotype1s { my $self = shift; return map $_->genotype1_id, $self->phenotype_comparison_type_id }
    
  
     
  
#many to many to one
 
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
#many to many to many


  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
   

1;

########Chado::Feature_Relationshipprop_Pub########

package Chado::Feature_Relationshipprop_Pub;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Feature_Relationshipprop_Pub->set_up_table('feature_relationshipprop_pub');

#
# Primary key accessors
#

sub id { shift->feature_relationshipprop_pub_id }
sub feature_relationshipprop_pub { shift->feature_relationshipprop_pub_id }
 



#
# Has A
#
 
Chado::Feature_Relationshipprop_Pub->has_a(feature_relationshipprop_id => 'Chado::Feature_Relationshipprop');
    
sub Chado::Feature_Relationshipprop_Pub::feature_relationshipprop { return shift->feature_relationshipprop_id }
      
 
Chado::Feature_Relationshipprop_Pub->has_a(pub_id => 'Chado::Pub');
    
sub Chado::Feature_Relationshipprop_Pub::pub { return shift->pub_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Biomaterial########

package Chado::Biomaterial;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Biomaterial->set_up_table('biomaterial');

#
# Primary key accessors
#

sub id { shift->biomaterial_id }
sub biomaterial { shift->biomaterial_id }
 



#
# Has A
#
  
  
  
  
  
  
  
 
Chado::Biomaterial->has_a(taxon_id => 'Chado::Organism');
    
sub Chado::Biomaterial::organism { return shift->taxon_id }
      
 
Chado::Biomaterial->has_a(biosourceprovider_id => 'Chado::Contact');
    
sub Chado::Biomaterial::contact { return shift->biosourceprovider_id }
      
 
Chado::Biomaterial->has_a(dbxref_id => 'Chado::Dbxref');
    
sub Chado::Biomaterial::dbxref { return shift->dbxref_id }
       

#
# Has Many
#
 
Chado::Biomaterial->has_many('biomaterial_relationship_subject_id', 'Chado::Biomaterial_Relationship' => 'subject_id');
   
Chado::Biomaterial->has_many('biomaterial_relationship_object_id', 'Chado::Biomaterial_Relationship' => 'object_id');
   
Chado::Biomaterial->has_many('biomaterial_treatment_biomaterial_id', 'Chado::Biomaterial_Treatment' => 'biomaterial_id');
  
    
sub biomaterial_treatments { return shift->biomaterial_treatment_biomaterial_id }
      
Chado::Biomaterial->has_many('assay_biomaterial_biomaterial_id', 'Chado::Assay_Biomaterial' => 'biomaterial_id');
  
    
sub assay_biomaterials { return shift->assay_biomaterial_biomaterial_id }
      
Chado::Biomaterial->has_many('biomaterial_dbxref_biomaterial_id', 'Chado::Biomaterial_Dbxref' => 'biomaterial_id');
   
Chado::Biomaterial->has_many('biomaterialprop_biomaterial_id', 'Chado::Biomaterialprop' => 'biomaterial_id');
  
    
sub biomaterialprops { return shift->biomaterialprop_biomaterial_id }
      
Chado::Biomaterial->has_many('treatment_biomaterial_id', 'Chado::Treatment' => 'biomaterial_id');
  
    
sub treatments { return shift->treatment_biomaterial_id }
        



#
# Has Compound Many (many to many relationships in all their flavors)
#
 
  
sub biomaterial_relationship_subjects { return shift->biomaterial_relationship_subject_id }

  
  
sub biomaterial_relationship_objects { return shift->biomaterial_relationship_object_id }
 
 
  
sub biomaterial_dbxref_biomaterials { return shift->biomaterial_dbxref_biomaterial_id }

   
# one to many to one
 
  
  
# one2one #
sub dbxrefs { my $self = shift; return map $_->dbxref_id, $self->biomaterial_dbxref_biomaterial_id }

# one to many to many
 
  
  
#many to many to one
 
  
# many2one #
  
  
sub biomaterial_relationship_subject_types { my $self = shift; return map $_->type_id, $self->biomaterial_relationship_subject_id }
    
  
sub biomaterial_relationship_object_types { my $self = shift; return map $_->type_id, $self->biomaterial_relationship_object_id }
    
   
  
#many to many to many


  
   

1;

########Chado::Environment########

package Chado::Environment;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Environment->set_up_table('environment');

#
# Primary key accessors
#

sub id { shift->environment_id }
sub environment { shift->environment_id }
 



#
# Has A
#
  
  
  
  
   

#
# Has Many
#
 
Chado::Environment->has_many('environment_cvterm_environment_id', 'Chado::Environment_Cvterm' => 'environment_id');
   
Chado::Environment->has_many('phenotype_comparison_environment1_id', 'Chado::Phenotype_Comparison' => 'environment1_id');
   
Chado::Environment->has_many('phenotype_comparison_environment2_id', 'Chado::Phenotype_Comparison' => 'environment2_id');
   
Chado::Environment->has_many('phenstatement_environment_id', 'Chado::Phenstatement' => 'environment_id');
   
Chado::Environment->has_many('phendesc_environment_id', 'Chado::Phendesc' => 'environment_id');
  
    
sub phendescs { return shift->phendesc_environment_id }
     



#
# Has Compound Many (many to many relationships in all their flavors)
#
 
  
sub phenstatement_environments { return shift->phenstatement_environment_id }

   
 
  
sub phenstatement_environments { return shift->phenstatement_environment_id }

   
 
  
  
sub phenstatement_environments { return shift->phenstatement_environment_id }
 
 
  
sub phenstatement_environments { return shift->phenstatement_environment_id }

   
 
  
sub environment_cvterm_environments { return shift->environment_cvterm_environment_id }

   
 
  
sub phenotype_comparison_environment1s { return shift->phenotype_comparison_environment1_id }

  
sub phenotype_comparison_environment2s { return shift->phenotype_comparison_environment2_id }

   
 
  
sub phenotype_comparison_environment1s { return shift->phenotype_comparison_environment1_id }

  
sub phenotype_comparison_environment2s { return shift->phenotype_comparison_environment2_id }

  
   
 
  
  
sub phenotype_comparison_environment1s { return shift->phenotype_comparison_environment1_id }

  
  
sub phenotype_comparison_environment2s { return shift->phenotype_comparison_environment2_id }
 
 
  
sub phenotype_comparison_environment1s { return shift->phenotype_comparison_environment1_id }

  
sub phenotype_comparison_environment2s { return shift->phenotype_comparison_environment2_id }

   
# one to many to one
 
  
# one2one #
sub cvterms { my $self = shift; return map $_->type_id, $self->phenstatement_environment_id }

  

sub phenotypes { my $self = shift; return map $_->phenotype_id, $self->phenstatement_environment_id }

  

sub genotypes { my $self = shift; return map $_->genotype_id, $self->phenstatement_environment_id }

  

sub pubs { my $self = shift; return map $_->pub_id, $self->phenstatement_environment_id }

  

sub cvterms { my $self = shift; return map $_->cvterm_id, $self->environment_cvterm_environment_id }

  
  
  
  
# one to many to many
 
  
  
  
  
  
  
  
  
  
#many to many to one
 
  
  
  
  
  
  
# many2one #
  
  
sub phenotype_comparison_environment1_types { my $self = shift; return map $_->type_id, $self->phenotype_comparison_environment1_id }
    
  
sub phenotype_comparison_environment2_types { my $self = shift; return map $_->type_id, $self->phenotype_comparison_environment2_id }
    
   
  
  
  

  
  
sub phenotype_comparison_environment1_pubs { my $self = shift; return map $_->pub_id, $self->phenotype_comparison_environment1_id }
    
  
sub phenotype_comparison_environment2_pubs { my $self = shift; return map $_->pub_id, $self->phenotype_comparison_environment2_id }
    
   
#many to many to many


  
  
  
  
  
  
  
# many2many #
  
  
    
    
sub phenotype_comparison_environment1_phenotype1s { my $self = shift; return map $_->phenotype_comparison_phenotype1s, $self->phenotype_comparison_environment1s }
      
    
sub phenotype_comparison_environment1_phenotype2s { my $self = shift; return map $_->phenotype_comparison_phenotype2s, $self->phenotype_comparison_environment1s }
      
    
    
  
    
    
sub phenotype_comparison_environment2_phenotype1s { my $self = shift; return map $_->phenotype_comparison_phenotype1s, $self->phenotype_comparison_environment2s }
      
    
sub phenotype_comparison_environment2_phenotype2s { my $self = shift; return map $_->phenotype_comparison_phenotype2s, $self->phenotype_comparison_environment2s }
      
    
    
   
  

  
  
    
    
sub phenotype_comparison_environment1_genotype1s { my $self = shift; return map $_->phenotype_comparison_genotype1s, $self->phenotype_comparison_environment1s }
      
    
sub phenotype_comparison_environment1_genotype2s { my $self = shift; return map $_->phenotype_comparison_genotype2s, $self->phenotype_comparison_environment1s }
      
    
    
  
    
    
sub phenotype_comparison_environment2_genotype1s { my $self = shift; return map $_->phenotype_comparison_genotype1s, $self->phenotype_comparison_environment2s }
      
    
sub phenotype_comparison_environment2_genotype2s { my $self = shift; return map $_->phenotype_comparison_genotype2s, $self->phenotype_comparison_environment2s }
      
    
    
   
   

1;

########Chado::Phenstatement########

package Chado::Phenstatement;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Phenstatement->set_up_table('phenstatement');

#
# Primary key accessors
#

sub id { shift->phenstatement_id }
sub phenstatement { shift->phenstatement_id }
 



#
# Has A
#
 
Chado::Phenstatement->has_a(genotype_id => 'Chado::Genotype');
    
sub Chado::Phenstatement::genotype { return shift->genotype_id }
      
 
Chado::Phenstatement->has_a(environment_id => 'Chado::Environment');
    
sub Chado::Phenstatement::environment { return shift->environment_id }
      
 
Chado::Phenstatement->has_a(phenotype_id => 'Chado::Phenotype');
    
sub Chado::Phenstatement::phenotype { return shift->phenotype_id }
      
 
Chado::Phenstatement->has_a(type_id => 'Chado::Cvterm');
    
sub Chado::Phenstatement::cvterm { return shift->type_id }
      
 
Chado::Phenstatement->has_a(pub_id => 'Chado::Pub');
    
sub Chado::Phenstatement::pub { return shift->pub_id }
       

#
# Has Many
#
     


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Studydesign########

package Chado::Studydesign;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Studydesign->set_up_table('studydesign');

#
# Primary key accessors
#

sub id { shift->studydesign_id }
sub studydesign { shift->studydesign_id }
 



#
# Has A
#
  
  
 
Chado::Studydesign->has_a(study_id => 'Chado::Study');
    
sub Chado::Studydesign::study { return shift->study_id }
       

#
# Has Many
#
 
Chado::Studydesign->has_many('studyfactor_studydesign_id', 'Chado::Studyfactor' => 'studydesign_id');
  
    
sub studyfactors { return shift->studyfactor_studydesign_id }
      
Chado::Studydesign->has_many('studydesignprop_studydesign_id', 'Chado::Studydesignprop' => 'studydesign_id');
  
    
sub studydesignprops { return shift->studydesignprop_studydesign_id }
      


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Pub_Dbxref########

package Chado::Pub_Dbxref;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Pub_Dbxref->set_up_table('pub_dbxref');

#
# Primary key accessors
#

sub id { shift->pub_dbxref_id }
sub pub_dbxref { shift->pub_dbxref_id }
 



#
# Has A
#
 
Chado::Pub_Dbxref->has_a(pub_id => 'Chado::Pub');
    
sub Chado::Pub_Dbxref::pub { return shift->pub_id }
      
 
Chado::Pub_Dbxref->has_a(dbxref_id => 'Chado::Dbxref');
    
sub Chado::Pub_Dbxref::dbxref { return shift->dbxref_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Expression_Cvtermprop########

package Chado::Expression_Cvtermprop;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Expression_Cvtermprop->set_up_table('expression_cvtermprop');

#
# Primary key accessors
#

sub id { shift->expression_cvtermprop_id }
sub expression_cvtermprop { shift->expression_cvtermprop_id }
 



#
# Has A
#
 
Chado::Expression_Cvtermprop->has_a(expression_cvterm_id => 'Chado::Expression_Cvterm');
    
sub Chado::Expression_Cvtermprop::expression_cvterm { return shift->expression_cvterm_id }
      
 
Chado::Expression_Cvtermprop->has_a(type_id => 'Chado::Cvterm');
    
sub Chado::Expression_Cvtermprop::cvterm { return shift->type_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Phenotype########

package Chado::Phenotype;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Phenotype->set_up_table('phenotype');

#
# Primary key accessors
#

sub id { shift->phenotype_id }
sub phenotype { shift->phenotype_id }
 



#
# Has A
#
  
  
  
  
  
 
Chado::Phenotype->has_a(observable_id => 'Chado::Cvterm');
    
sub observable { return shift->observable_id }
      
 
Chado::Phenotype->has_a(attr_id => 'Chado::Cvterm');
    
sub attr { return shift->attr_id }
      
 
Chado::Phenotype->has_a(cvalue_id => 'Chado::Cvterm');
    
sub cvalue { return shift->cvalue_id }
      
 
Chado::Phenotype->has_a(assay_id => 'Chado::Cvterm');
    
sub assay { return shift->assay_id }
       

#
# Has Many
#
 
Chado::Phenotype->has_many('feature_phenotype_phenotype_id', 'Chado::Feature_Phenotype' => 'phenotype_id');
   
Chado::Phenotype->has_many('phenotype_comparison_phenotype1_id', 'Chado::Phenotype_Comparison' => 'phenotype1_id');
   
Chado::Phenotype->has_many('phenotype_comparison_phenotype2_id', 'Chado::Phenotype_Comparison' => 'phenotype2_id');
   
Chado::Phenotype->has_many('phenotype_cvterm_phenotype_id', 'Chado::Phenotype_Cvterm' => 'phenotype_id');
   
Chado::Phenotype->has_many('phenstatement_phenotype_id', 'Chado::Phenstatement' => 'phenotype_id');
      



#
# Has Compound Many (many to many relationships in all their flavors)
#
 
  
  
sub phenstatement_phenotypes { return shift->phenstatement_phenotype_id }
 
 
  
sub phenstatement_phenotypes { return shift->phenstatement_phenotype_id }

   
 
  
  
sub phenstatement_phenotypes { return shift->phenstatement_phenotype_id }
 
 
  
sub phenstatement_phenotypes { return shift->phenstatement_phenotype_id }

   
 
  
sub phenotype_cvterm_phenotypes { return shift->phenotype_cvterm_phenotype_id }

   
 
  
  
sub feature_phenotype_phenotypes { return shift->feature_phenotype_phenotype_id }
 
 
  
  
  
sub phenotype_comparison_phenotype1s { return shift->phenotype_comparison_phenotype1_id }

  
sub phenotype_comparison_phenotype2s { return shift->phenotype_comparison_phenotype2_id }
 
 
  
sub phenotype_comparison_phenotype1s { return shift->phenotype_comparison_phenotype1_id }

  
sub phenotype_comparison_phenotype2s { return shift->phenotype_comparison_phenotype2_id }

   
 
  
  
  
sub phenotype_comparison_phenotype1s { return shift->phenotype_comparison_phenotype1_id }

  
sub phenotype_comparison_phenotype2s { return shift->phenotype_comparison_phenotype2_id }
 
 
  
sub phenotype_comparison_phenotype1s { return shift->phenotype_comparison_phenotype1_id }

  
sub phenotype_comparison_phenotype2s { return shift->phenotype_comparison_phenotype2_id }

   
# one to many to one
 
  
# one2one #
sub environments { my $self = shift; return map $_->environment_id, $self->phenstatement_phenotype_id }

  

sub cvterms { my $self = shift; return map $_->type_id, $self->phenstatement_phenotype_id }

  

sub genotypes { my $self = shift; return map $_->genotype_id, $self->phenstatement_phenotype_id }

  

sub pubs { my $self = shift; return map $_->pub_id, $self->phenstatement_phenotype_id }

  

sub cvterms { my $self = shift; return map $_->cvterm_id, $self->phenotype_cvterm_phenotype_id }

  

sub features { my $self = shift; return map $_->feature_id, $self->feature_phenotype_phenotype_id }

  
  
  
  
# one to many to many
 
  
  
  
  
  
  
  
  
  
  
#many to many to one
 
  
  
  
  
  
  
  
  
# many2one #
  
  
sub phenotype_comparison_phenotype1_types { my $self = shift; return map $_->type_id, $self->phenotype_comparison_phenotype1_id }
    
  
sub phenotype_comparison_phenotype2_types { my $self = shift; return map $_->type_id, $self->phenotype_comparison_phenotype2_id }
    
   
  
  

  
  
sub phenotype_comparison_phenotype1_pubs { my $self = shift; return map $_->pub_id, $self->phenotype_comparison_phenotype1_id }
    
  
sub phenotype_comparison_phenotype2_pubs { my $self = shift; return map $_->pub_id, $self->phenotype_comparison_phenotype2_id }
    
   
#many to many to many


  
  
  
  
  
  
  
# many2many #
  
  
    
    
sub phenotype_comparison_phenotype1_environment1s { my $self = shift; return map $_->phenotype_comparison_environment1s, $self->phenotype_comparison_phenotype1s }
      
    
sub phenotype_comparison_phenotype1_environment2s { my $self = shift; return map $_->phenotype_comparison_environment2s, $self->phenotype_comparison_phenotype1s }
      
    
    
  
    
    
sub phenotype_comparison_phenotype2_environment1s { my $self = shift; return map $_->phenotype_comparison_environment1s, $self->phenotype_comparison_phenotype2s }
      
    
sub phenotype_comparison_phenotype2_environment2s { my $self = shift; return map $_->phenotype_comparison_environment2s, $self->phenotype_comparison_phenotype2s }
      
    
    
   
  
  

  
  
    
    
sub phenotype_comparison_phenotype1_genotype1s { my $self = shift; return map $_->phenotype_comparison_genotype1s, $self->phenotype_comparison_phenotype1s }
      
    
sub phenotype_comparison_phenotype1_genotype2s { my $self = shift; return map $_->phenotype_comparison_genotype2s, $self->phenotype_comparison_phenotype1s }
      
    
    
  
    
    
sub phenotype_comparison_phenotype2_genotype1s { my $self = shift; return map $_->phenotype_comparison_genotype1s, $self->phenotype_comparison_phenotype2s }
      
    
sub phenotype_comparison_phenotype2_genotype2s { my $self = shift; return map $_->phenotype_comparison_genotype2s, $self->phenotype_comparison_phenotype2s }
      
    
    
   
   

1;

########Chado::Phendesc########

package Chado::Phendesc;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Phendesc->set_up_table('phendesc');

#
# Primary key accessors
#

sub id { shift->phendesc_id }
sub phendesc { shift->phendesc_id }
 



#
# Has A
#
 
Chado::Phendesc->has_a(genotype_id => 'Chado::Genotype');
    
sub Chado::Phendesc::genotype { return shift->genotype_id }
      
 
Chado::Phendesc->has_a(environment_id => 'Chado::Environment');
    
sub Chado::Phendesc::environment { return shift->environment_id }
      
 
Chado::Phendesc->has_a(type_id => 'Chado::Cvterm');
    
sub Chado::Phendesc::cvterm { return shift->type_id }
      
 
Chado::Phendesc->has_a(pub_id => 'Chado::Pub');
    
sub Chado::Phendesc::pub { return shift->pub_id }
       

#
# Has Many
#
    


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Featureprop_Pub########

package Chado::Featureprop_Pub;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Featureprop_Pub->set_up_table('featureprop_pub');

#
# Primary key accessors
#

sub id { shift->featureprop_pub_id }
sub featureprop_pub { shift->featureprop_pub_id }
 



#
# Has A
#
 
Chado::Featureprop_Pub->has_a(featureprop_id => 'Chado::Featureprop');
    
sub Chado::Featureprop_Pub::featureprop { return shift->featureprop_id }
      
 
Chado::Featureprop_Pub->has_a(pub_id => 'Chado::Pub');
    
sub Chado::Featureprop_Pub::pub { return shift->pub_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Phylotree########

package Chado::Phylotree;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Phylotree->set_up_table('phylotree');

#
# Primary key accessors
#

sub id { shift->phylotree_id }
sub phylotree { shift->phylotree_id }
 



#
# Has A
#
  
  
 
Chado::Phylotree->has_a(dbxref_id => 'Chado::Dbxref');
    
sub Chado::Phylotree::dbxref { return shift->dbxref_id }
      
 
Chado::Phylotree->has_a(type_id => 'Chado::Cvterm');
    
sub Chado::Phylotree::cvterm { return shift->type_id }
       

#
# Has Many
#
 
Chado::Phylotree->has_many('phylotree_pub_phylotree_id', 'Chado::Phylotree_Pub' => 'phylotree_id');
   
Chado::Phylotree->has_many('phylonode_phylotree_id', 'Chado::Phylonode' => 'phylotree_id');
  
    
sub phylonodes { return shift->phylonode_phylotree_id }
       



#
# Has Compound Many (many to many relationships in all their flavors)
#
 
  
sub phylotree_pub_phylotrees { return shift->phylotree_pub_phylotree_id }

   
# one to many to one
 
  
# one2one #
sub pubs { my $self = shift; return map $_->pub_id, $self->phylotree_pub_phylotree_id }

# one to many to many
 
  
#many to many to one
 
  
#many to many to many


   

1;

########Chado::Feature_Expressionprop########

package Chado::Feature_Expressionprop;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Feature_Expressionprop->set_up_table('feature_expressionprop');

#
# Primary key accessors
#

sub id { shift->feature_expressionprop_id }
sub feature_expressionprop { shift->feature_expressionprop_id }
 



#
# Has A
#
 
Chado::Feature_Expressionprop->has_a(feature_expression_id => 'Chado::Feature_Expression');
    
sub Chado::Feature_Expressionprop::feature_expression { return shift->feature_expression_id }
      
 
Chado::Feature_Expressionprop->has_a(type_id => 'Chado::Cvterm');
    
sub Chado::Feature_Expressionprop::cvterm { return shift->type_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Chado::Pub_Relationship########

package Chado::Pub_Relationship;
use base 'Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Chado::Pub_Relationship->set_up_table('pub_relationship');

#
# Primary key accessors
#

sub id { shift->pub_relationship_id }
sub pub_relationship { shift->pub_relationship_id }
 



#
# Has A
#
 
Chado::Pub_Relationship->has_a(subject_id => 'Chado::Pub');
    
sub subject { return shift->subject_id }
      
 
Chado::Pub_Relationship->has_a(object_id => 'Chado::Pub');
    
sub object { return shift->object_id }
      
 
Chado::Pub_Relationship->has_a(type_id => 'Chado::Cvterm');
    
sub Chado::Pub_Relationship::cvterm { return shift->type_id }
       

#
# Has Many
#
   


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
