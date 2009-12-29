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
$file   = "$Bin/../lib/Bio/Chado/$file.pm";

open OUT,">$file" or die "Can't create $file: $!";
        
print "Extracting $file (with variable substitutions)\n";
               
my $startperl = $Config{startperl} ne '#!perl'
  ? $Config{startperl}
  : "#!$Config{perlpath}";
                       
print OUT <<'!NO!SUBS!';
########DBI########
package Bio::Chado::DBI;

# Created by SQL::Translator::Producer::TTSchema
# Template used: dbi.tt2

use strict;
use Data::Dumper;
use Bio::GMOD::Config;
use Bio::GMOD::DB::Config;
no warnings 'redefine';
use base qw(Class::DBI::Pg);

# This is how you normally connect with Class DBI's connection pooling but
# its very fragile for me on FC2.  I'm replacing it with the db_Main method below
#Bio::Chado::DBI->set_db('Main', 'dbi:Pg:dbname=chado', 'cain', '');

my $db_options = { __PACKAGE__->_default_attributes };
__PACKAGE__->_remember_handle('Main'); # so dbi_commit works
$db_options->{AutoCommit} = 0;

sub db_Main {
  my $DBPROFILE ||= 'default';   #might want to allow passing this in somehow
  my $gmod_conf = Bio::GMOD::Config->new();
  my $db_conf = Bio::GMOD::DB::Config->new( $gmod_conf, $DBPROFILE );

  my $dbname = $db_conf->name;
  my $dbhost = $db_conf->host;
  my $dbport = $db_conf->port;
  my $dbuser = $db_conf->user;
  my $dbpass = $db_conf->password;
 
  my $dbh;
  $dbh = DBI->connect_cached( 
      "dbi:Pg:dbname=$dbname;host=$dbhost;port=$dbport", 
      $dbuser, 
      $dbpass, 
      $db_options );
  # clear the connection cache if can't ping
  if ($dbh->ping() < 1) {
    my $CachedKids_hashref = $dbh->{Driver}->{CachedKids};
    %$CachedKids_hashref = () if $CachedKids_hashref;
    $dbh = DBI->connect_cached(
       "dbi:Pg:dbname=$dbname;host=$dbhost;port=$dbport",
       $dbuser, 
       $dbpass, 
       $db_options );
       warn("Database handle reset!: ".$dbh." ping: ".$dbh->ping());
  }
  return($dbh);
}

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


########Bio::Chado::CDBI::Study_Assay########

package Bio::Chado::CDBI::Study_Assay;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Study_Assay->set_up_table('study_assay');

#
# Primary key accessors
#

sub id { shift->study_assay_id }
sub study_assay { shift->study_assay_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Study_Assay->has_a(study_id => 'Bio::Chado::CDBI::Study');
    
sub Bio::Chado::CDBI::Study_Assay::study { return shift->study_id }
      
 
Bio::Chado::CDBI::Study_Assay->has_a(assay_id => 'Bio::Chado::CDBI::Assay');
    
sub Bio::Chado::CDBI::Study_Assay::assay { return shift->assay_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Feature_Dbxref########

package Bio::Chado::CDBI::Feature_Dbxref;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Feature_Dbxref->set_up_table('feature_dbxref');

#
# Primary key accessors
#

sub id { shift->feature_dbxref_id }
sub feature_dbxref { shift->feature_dbxref_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Feature_Dbxref->has_a(feature_id => 'Bio::Chado::CDBI::Feature');
    
sub Bio::Chado::CDBI::Feature_Dbxref::feature { return shift->feature_id }
      
 
Bio::Chado::CDBI::Feature_Dbxref->has_a(dbxref_id => 'Bio::Chado::CDBI::Dbxref');
    
sub Bio::Chado::CDBI::Feature_Dbxref::dbxref { return shift->dbxref_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Quantification########

package Bio::Chado::CDBI::Quantification;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Quantification->set_up_table('quantification');

#
# Primary key accessors
#

sub id { shift->quantification_id }
sub quantification { shift->quantification_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Quantification->has_a(acquisition_id => 'Bio::Chado::CDBI::Acquisition');
    
sub Bio::Chado::CDBI::Quantification::acquisition { return shift->acquisition_id }
      
 
Bio::Chado::CDBI::Quantification->has_a(operator_id => 'Bio::Chado::CDBI::Contact');
    
sub Bio::Chado::CDBI::Quantification::contact { return shift->operator_id }
      
 
Bio::Chado::CDBI::Quantification->has_a(protocol_id => 'Bio::Chado::CDBI::Protocol');
    
sub Bio::Chado::CDBI::Quantification::protocol { return shift->protocol_id }
      
 
Bio::Chado::CDBI::Quantification->has_a(analysis_id => 'Bio::Chado::CDBI::Analysis');
    
sub Bio::Chado::CDBI::Quantification::analysis { return shift->analysis_id }
      
  
  
  
   

#
# Has Many
#
     
Bio::Chado::CDBI::Quantification->has_many('quantification_relationship_subject_id', 'Bio::Chado::CDBI::Quantification_Relationship' => 'subject_id');
   
Bio::Chado::CDBI::Quantification->has_many('quantification_relationship_object_id', 'Bio::Chado::CDBI::Quantification_Relationship' => 'object_id');
   
Bio::Chado::CDBI::Quantification->has_many('elementresult_quantification_id', 'Bio::Chado::CDBI::Elementresult' => 'quantification_id');
  
    
sub elementresults { return shift->elementresult_quantification_id }
      
Bio::Chado::CDBI::Quantification->has_many('quantificationprop_quantification_id', 'Bio::Chado::CDBI::Quantificationprop' => 'quantification_id');
  
    
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

########Bio::Chado::CDBI::Mageml########

package Bio::Chado::CDBI::Mageml;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Mageml->set_up_table('mageml');

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
 
Bio::Chado::CDBI::Mageml->has_many('magedocumentation_mageml_id', 'Bio::Chado::CDBI::Magedocumentation' => 'mageml_id');
  
    
sub magedocumentations { return shift->magedocumentation_mageml_id }
     


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Feature_Expression########

package Bio::Chado::CDBI::Feature_Expression;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Feature_Expression->set_up_table('feature_expression');

#
# Primary key accessors
#

sub id { shift->feature_expression_id }
sub feature_expression { shift->feature_expression_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Feature_Expression->has_a(expression_id => 'Bio::Chado::CDBI::Expression');
    
sub Bio::Chado::CDBI::Feature_Expression::expression { return shift->expression_id }
      
 
Bio::Chado::CDBI::Feature_Expression->has_a(feature_id => 'Bio::Chado::CDBI::Feature');
    
sub Bio::Chado::CDBI::Feature_Expression::feature { return shift->feature_id }
      
 
Bio::Chado::CDBI::Feature_Expression->has_a(pub_id => 'Bio::Chado::CDBI::Pub');
    
sub Bio::Chado::CDBI::Feature_Expression::pub { return shift->pub_id }
      
   

#
# Has Many
#
    
Bio::Chado::CDBI::Feature_Expression->has_many('feature_expressionprop_feature_expression_id', 'Bio::Chado::CDBI::Feature_Expressionprop' => 'feature_expression_id');
  
    
sub feature_expressionprops { return shift->feature_expressionprop_feature_expression_id }
     


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Feature_Cvterm########

package Bio::Chado::CDBI::Feature_Cvterm;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Feature_Cvterm->set_up_table('feature_cvterm');

#
# Primary key accessors
#

sub id { shift->feature_cvterm_id }
sub feature_cvterm { shift->feature_cvterm_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Feature_Cvterm->has_a(feature_id => 'Bio::Chado::CDBI::Feature');
    
sub Bio::Chado::CDBI::Feature_Cvterm::feature { return shift->feature_id }
      
 
Bio::Chado::CDBI::Feature_Cvterm->has_a(cvterm_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Feature_Cvterm::cvterm { return shift->cvterm_id }
      
 
Bio::Chado::CDBI::Feature_Cvterm->has_a(pub_id => 'Bio::Chado::CDBI::Pub');
    
sub Bio::Chado::CDBI::Feature_Cvterm::pub { return shift->pub_id }
      
  
  
   

#
# Has Many
#
    
Bio::Chado::CDBI::Feature_Cvterm->has_many('feature_cvterm_dbxref_feature_cvterm_id', 'Bio::Chado::CDBI::Feature_Cvterm_Dbxref' => 'feature_cvterm_id');
   
Bio::Chado::CDBI::Feature_Cvterm->has_many('feature_cvtermprop_feature_cvterm_id', 'Bio::Chado::CDBI::Feature_Cvtermprop' => 'feature_cvterm_id');
  
    
sub feature_cvtermprops { return shift->feature_cvtermprop_feature_cvterm_id }
      
Bio::Chado::CDBI::Feature_Cvterm->has_many('feature_cvterm_pub_feature_cvterm_id', 'Bio::Chado::CDBI::Feature_Cvterm_Pub' => 'feature_cvterm_id');
  



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

########Bio::Chado::CDBI::Arraydesign########

package Bio::Chado::CDBI::Arraydesign;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Arraydesign->set_up_table('arraydesign');

#
# Primary key accessors
#

sub id { shift->arraydesign_id }
sub arraydesign { shift->arraydesign_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Arraydesign->has_a(manufacturer_id => 'Bio::Chado::CDBI::Contact');
    
sub Bio::Chado::CDBI::Arraydesign::contact { return shift->manufacturer_id }
      
 
Bio::Chado::CDBI::Arraydesign->has_a(platformtype_id => 'Bio::Chado::CDBI::Cvterm');
    
sub platformtype { return shift->platformtype_id }
      
 
Bio::Chado::CDBI::Arraydesign->has_a(substratetype_id => 'Bio::Chado::CDBI::Cvterm');
    
sub substratetype { return shift->substratetype_id }
      
 
Bio::Chado::CDBI::Arraydesign->has_a(protocol_id => 'Bio::Chado::CDBI::Protocol');
    
sub Bio::Chado::CDBI::Arraydesign::protocol { return shift->protocol_id }
      
 
Bio::Chado::CDBI::Arraydesign->has_a(dbxref_id => 'Bio::Chado::CDBI::Dbxref');
    
sub Bio::Chado::CDBI::Arraydesign::dbxref { return shift->dbxref_id }
      
  
  
   

#
# Has Many
#
      
Bio::Chado::CDBI::Arraydesign->has_many('assay_arraydesign_id', 'Bio::Chado::CDBI::Assay' => 'arraydesign_id');
  
    
sub assays { return shift->assay_arraydesign_id }
      
Bio::Chado::CDBI::Arraydesign->has_many('element_arraydesign_id', 'Bio::Chado::CDBI::Element' => 'arraydesign_id');
   
Bio::Chado::CDBI::Arraydesign->has_many('arraydesignprop_arraydesign_id', 'Bio::Chado::CDBI::Arraydesignprop' => 'arraydesign_id');
  
    
sub arraydesignprops { return shift->arraydesignprop_arraydesign_id }
     



#
# Has Compound Many (many to many relationships in all their flavors)
#
 
  
sub element_arraydesigns { return shift->element_arraydesign_id }

   
 
  
  
sub element_arraydesigns { return shift->element_arraydesign_id }
 
 
  
sub element_arraydesigns { return shift->element_arraydesign_id }

   
# one to many to one
 
  
# one2one #
sub cvterms { my $self = shift; return map $_->type_id, $self->element_arraydesign_id }

  

sub features { my $self = shift; return map $_->feature_id, $self->element_arraydesign_id }

  

sub dbxrefs { my $self = shift; return map $_->dbxref_id, $self->element_arraydesign_id }

# one to many to many
 
  
  
  
#many to many to one
 
  
  
  
#many to many to many


  
  
   

1;

########Bio::Chado::CDBI::Cell_Line_Dbxref########

package Bio::Chado::CDBI::Cell_Line_Dbxref;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Cell_Line_Dbxref->set_up_table('cell_line_dbxref');

#
# Primary key accessors
#

sub id { shift->cell_line_dbxref_id }
sub cell_line_dbxref { shift->cell_line_dbxref_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Cell_Line_Dbxref->has_a(cell_line_id => 'Bio::Chado::CDBI::Cell_Line');
    
sub Bio::Chado::CDBI::Cell_Line_Dbxref::cell_line { return shift->cell_line_id }
      
 
Bio::Chado::CDBI::Cell_Line_Dbxref->has_a(dbxref_id => 'Bio::Chado::CDBI::Dbxref');
    
sub Bio::Chado::CDBI::Cell_Line_Dbxref::dbxref { return shift->dbxref_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Biomaterial_Relationship########

package Bio::Chado::CDBI::Biomaterial_Relationship;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Biomaterial_Relationship->set_up_table('biomaterial_relationship');

#
# Primary key accessors
#

sub id { shift->biomaterial_relationship_id }
sub biomaterial_relationship { shift->biomaterial_relationship_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Biomaterial_Relationship->has_a(subject_id => 'Bio::Chado::CDBI::Biomaterial');
    
sub subject { return shift->subject_id }
      
 
Bio::Chado::CDBI::Biomaterial_Relationship->has_a(type_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Biomaterial_Relationship::cvterm { return shift->type_id }
      
 
Bio::Chado::CDBI::Biomaterial_Relationship->has_a(object_id => 'Bio::Chado::CDBI::Biomaterial');
    
sub object { return shift->object_id }
       

#
# Has Many
#
   


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Cell_Line_Feature########

package Bio::Chado::CDBI::Cell_Line_Feature;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Cell_Line_Feature->set_up_table('cell_line_feature');

#
# Primary key accessors
#

sub id { shift->cell_line_feature_id }
sub cell_line_feature { shift->cell_line_feature_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Cell_Line_Feature->has_a(cell_line_id => 'Bio::Chado::CDBI::Cell_Line');
    
sub Bio::Chado::CDBI::Cell_Line_Feature::cell_line { return shift->cell_line_id }
      
 
Bio::Chado::CDBI::Cell_Line_Feature->has_a(feature_id => 'Bio::Chado::CDBI::Feature');
    
sub Bio::Chado::CDBI::Cell_Line_Feature::feature { return shift->feature_id }
      
 
Bio::Chado::CDBI::Cell_Line_Feature->has_a(pub_id => 'Bio::Chado::CDBI::Pub');
    
sub Bio::Chado::CDBI::Cell_Line_Feature::pub { return shift->pub_id }
       

#
# Has Many
#
   


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Feature_Phenotype########

package Bio::Chado::CDBI::Feature_Phenotype;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Feature_Phenotype->set_up_table('feature_phenotype');

#
# Primary key accessors
#

sub id { shift->feature_phenotype_id }
sub feature_phenotype { shift->feature_phenotype_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Feature_Phenotype->has_a(feature_id => 'Bio::Chado::CDBI::Feature');
    
sub Bio::Chado::CDBI::Feature_Phenotype::feature { return shift->feature_id }
      
 
Bio::Chado::CDBI::Feature_Phenotype->has_a(phenotype_id => 'Bio::Chado::CDBI::Phenotype');
    
sub Bio::Chado::CDBI::Feature_Phenotype::phenotype { return shift->phenotype_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Cell_Line_Relationship########

package Bio::Chado::CDBI::Cell_Line_Relationship;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Cell_Line_Relationship->set_up_table('cell_line_relationship');

#
# Primary key accessors
#

sub id { shift->cell_line_relationship_id }
sub cell_line_relationship { shift->cell_line_relationship_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Cell_Line_Relationship->has_a(subject_id => 'Bio::Chado::CDBI::Cell_Line');
    
sub subject { return shift->subject_id }
      
 
Bio::Chado::CDBI::Cell_Line_Relationship->has_a(object_id => 'Bio::Chado::CDBI::Cell_Line');
    
sub object { return shift->object_id }
      
 
Bio::Chado::CDBI::Cell_Line_Relationship->has_a(type_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Cell_Line_Relationship::cvterm { return shift->type_id }
       

#
# Has Many
#
   


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Quantification_Relationship########

package Bio::Chado::CDBI::Quantification_Relationship;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Quantification_Relationship->set_up_table('quantification_relationship');

#
# Primary key accessors
#

sub id { shift->quantification_relationship_id }
sub quantification_relationship { shift->quantification_relationship_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Quantification_Relationship->has_a(subject_id => 'Bio::Chado::CDBI::Quantification');
    
sub subject { return shift->subject_id }
      
 
Bio::Chado::CDBI::Quantification_Relationship->has_a(type_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Quantification_Relationship::cvterm { return shift->type_id }
      
 
Bio::Chado::CDBI::Quantification_Relationship->has_a(object_id => 'Bio::Chado::CDBI::Quantification');
    
sub object { return shift->object_id }
       

#
# Has Many
#
   


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Cell_Line_Synonym########

package Bio::Chado::CDBI::Cell_Line_Synonym;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Cell_Line_Synonym->set_up_table('cell_line_synonym');

#
# Primary key accessors
#

sub id { shift->cell_line_synonym_id }
sub cell_line_synonym { shift->cell_line_synonym_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Cell_Line_Synonym->has_a(cell_line_id => 'Bio::Chado::CDBI::Cell_Line');
    
sub Bio::Chado::CDBI::Cell_Line_Synonym::cell_line { return shift->cell_line_id }
      
 
Bio::Chado::CDBI::Cell_Line_Synonym->has_a(synonym_id => 'Bio::Chado::CDBI::Synonym');
    
sub Bio::Chado::CDBI::Cell_Line_Synonym::synonym { return shift->synonym_id }
      
 
Bio::Chado::CDBI::Cell_Line_Synonym->has_a(pub_id => 'Bio::Chado::CDBI::Pub');
    
sub Bio::Chado::CDBI::Cell_Line_Synonym::pub { return shift->pub_id }
       

#
# Has Many
#
   


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Analysis########

package Bio::Chado::CDBI::Analysis;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Analysis->set_up_table('analysis');

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
 
Bio::Chado::CDBI::Analysis->has_many('quantification_analysis_id', 'Bio::Chado::CDBI::Quantification' => 'analysis_id');
  
    
sub quantifications { return shift->quantification_analysis_id }
      
Bio::Chado::CDBI::Analysis->has_many('analysisfeature_analysis_id', 'Bio::Chado::CDBI::Analysisfeature' => 'analysis_id');
  
    
sub analysisfeatures { return shift->analysisfeature_analysis_id }
      
Bio::Chado::CDBI::Analysis->has_many('analysisprop_analysis_id', 'Bio::Chado::CDBI::Analysisprop' => 'analysis_id');
  
    
sub analysisprops { return shift->analysisprop_analysis_id }
      
Bio::Chado::CDBI::Analysis->has_many('phylotree_analysis_id', 'Bio::Chado::CDBI::Phylotree' => 'analysis_id');
  
    
sub phylotrees { return shift->phylotree_analysis_id }
     


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Eimage########

package Bio::Chado::CDBI::Eimage;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Eimage->set_up_table('eimage');

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
 
Bio::Chado::CDBI::Eimage->has_many('expression_image_eimage_id', 'Bio::Chado::CDBI::Expression_Image' => 'eimage_id');
  



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

########Bio::Chado::CDBI::Phenotype_Comparison_Cvterm########

package Bio::Chado::CDBI::Phenotype_Comparison_Cvterm;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Phenotype_Comparison_Cvterm->set_up_table('phenotype_comparison_cvterm');

#
# Primary key accessors
#

sub id { shift->phenotype_comparison_cvterm_id }
sub phenotype_comparison_cvterm { shift->phenotype_comparison_cvterm_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Phenotype_Comparison_Cvterm->has_a(phenotype_comparison_id => 'Bio::Chado::CDBI::Phenotype_Comparison');
    
sub Bio::Chado::CDBI::Phenotype_Comparison_Cvterm::phenotype_comparison { return shift->phenotype_comparison_id }
      
 
Bio::Chado::CDBI::Phenotype_Comparison_Cvterm->has_a(cvterm_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Phenotype_Comparison_Cvterm::cvterm { return shift->cvterm_id }
      
 
Bio::Chado::CDBI::Phenotype_Comparison_Cvterm->has_a(pub_id => 'Bio::Chado::CDBI::Pub');
    
sub Bio::Chado::CDBI::Phenotype_Comparison_Cvterm::pub { return shift->pub_id }
       

#
# Has Many
#
   


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Synonym########

package Bio::Chado::CDBI::Synonym;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Synonym->set_up_table('synonym');

#
# Primary key accessors
#

sub id { shift->synonym_id }
sub synonym { shift->synonym_id }
 



#
# Has A
#
  
 
Bio::Chado::CDBI::Synonym->has_a(type_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Synonym::cvterm { return shift->type_id }
      
  
   

#
# Has Many
#
 
Bio::Chado::CDBI::Synonym->has_many('cell_line_synonym_synonym_id', 'Bio::Chado::CDBI::Cell_Line_Synonym' => 'synonym_id');
  
    
sub cell_line_synonyms { return shift->cell_line_synonym_synonym_id }
       
Bio::Chado::CDBI::Synonym->has_many('library_synonym_synonym_id', 'Bio::Chado::CDBI::Library_Synonym' => 'synonym_id');
  
    
sub library_synonyms { return shift->library_synonym_synonym_id }
      
Bio::Chado::CDBI::Synonym->has_many('feature_synonym_synonym_id', 'Bio::Chado::CDBI::Feature_Synonym' => 'synonym_id');
  
    
sub feature_synonyms { return shift->feature_synonym_synonym_id }
     


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Cvtermpath########

package Bio::Chado::CDBI::Cvtermpath;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Cvtermpath->set_up_table('cvtermpath');

#
# Primary key accessors
#

sub id { shift->cvtermpath_id }
sub cvtermpath { shift->cvtermpath_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Cvtermpath->has_a(type_id => 'Bio::Chado::CDBI::Cvterm');
    
sub type { return shift->type_id }
      
 
Bio::Chado::CDBI::Cvtermpath->has_a(subject_id => 'Bio::Chado::CDBI::Cvterm');
    
sub subject { return shift->subject_id }
      
 
Bio::Chado::CDBI::Cvtermpath->has_a(object_id => 'Bio::Chado::CDBI::Cvterm');
    
sub object { return shift->object_id }
      
 
Bio::Chado::CDBI::Cvtermpath->has_a(cv_id => 'Bio::Chado::CDBI::Cv');
    
sub Bio::Chado::CDBI::Cvtermpath::cv { return shift->cv_id }
       

#
# Has Many
#
    


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Cvterm_Relationship########

package Bio::Chado::CDBI::Cvterm_Relationship;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Cvterm_Relationship->set_up_table('cvterm_relationship');

#
# Primary key accessors
#

sub id { shift->cvterm_relationship_id }
sub cvterm_relationship { shift->cvterm_relationship_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Cvterm_Relationship->has_a(type_id => 'Bio::Chado::CDBI::Cvterm');
    
sub type { return shift->type_id }
      
 
Bio::Chado::CDBI::Cvterm_Relationship->has_a(subject_id => 'Bio::Chado::CDBI::Cvterm');
    
sub subject { return shift->subject_id }
      
 
Bio::Chado::CDBI::Cvterm_Relationship->has_a(object_id => 'Bio::Chado::CDBI::Cvterm');
    
sub object { return shift->object_id }
       

#
# Has Many
#
   


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Phylonode_Pub########

package Bio::Chado::CDBI::Phylonode_Pub;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Phylonode_Pub->set_up_table('phylonode_pub');

#
# Primary key accessors
#

sub id { shift->phylonode_pub_id }
sub phylonode_pub { shift->phylonode_pub_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Phylonode_Pub->has_a(phylonode_id => 'Bio::Chado::CDBI::Phylonode');
    
sub Bio::Chado::CDBI::Phylonode_Pub::phylonode { return shift->phylonode_id }
      
 
Bio::Chado::CDBI::Phylonode_Pub->has_a(pub_id => 'Bio::Chado::CDBI::Pub');
    
sub Bio::Chado::CDBI::Phylonode_Pub::pub { return shift->pub_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Phylonode_Organism########

package Bio::Chado::CDBI::Phylonode_Organism;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Phylonode_Organism->set_up_table('phylonode_organism');

#
# Primary key accessors
#

sub id { shift->phylonode_organism_id }
sub phylonode_organism { shift->phylonode_organism_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Phylonode_Organism->has_a(phylonode_id => 'Bio::Chado::CDBI::Phylonode');
    
sub Bio::Chado::CDBI::Phylonode_Organism::phylonode { return shift->phylonode_id }
      
 
Bio::Chado::CDBI::Phylonode_Organism->has_a(organism_id => 'Bio::Chado::CDBI::Organism');
    
sub Bio::Chado::CDBI::Phylonode_Organism::organism { return shift->organism_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Biomaterial_Dbxref########

package Bio::Chado::CDBI::Biomaterial_Dbxref;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Biomaterial_Dbxref->set_up_table('biomaterial_dbxref');

#
# Primary key accessors
#

sub id { shift->biomaterial_dbxref_id }
sub biomaterial_dbxref { shift->biomaterial_dbxref_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Biomaterial_Dbxref->has_a(biomaterial_id => 'Bio::Chado::CDBI::Biomaterial');
    
sub Bio::Chado::CDBI::Biomaterial_Dbxref::biomaterial { return shift->biomaterial_id }
      
 
Bio::Chado::CDBI::Biomaterial_Dbxref->has_a(dbxref_id => 'Bio::Chado::CDBI::Dbxref');
    
sub Bio::Chado::CDBI::Biomaterial_Dbxref::dbxref { return shift->dbxref_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Genotype########

package Bio::Chado::CDBI::Genotype;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Genotype->set_up_table('genotype');

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
 
Bio::Chado::CDBI::Genotype->has_many('stock_genotype_genotype_id', 'Bio::Chado::CDBI::Stock_Genotype' => 'genotype_id');
   
Bio::Chado::CDBI::Genotype->has_many('phendesc_genotype_id', 'Bio::Chado::CDBI::Phendesc' => 'genotype_id');
  
    
sub phendescs { return shift->phendesc_genotype_id }
      
Bio::Chado::CDBI::Genotype->has_many('phenotype_comparison_genotype1_id', 'Bio::Chado::CDBI::Phenotype_Comparison' => 'genotype1_id');
   
Bio::Chado::CDBI::Genotype->has_many('phenotype_comparison_genotype2_id', 'Bio::Chado::CDBI::Phenotype_Comparison' => 'genotype2_id');
   
Bio::Chado::CDBI::Genotype->has_many('feature_genotype_genotype_id', 'Bio::Chado::CDBI::Feature_Genotype' => 'genotype_id');
  
    
sub feature_genotypes { return shift->feature_genotype_genotype_id }
      
Bio::Chado::CDBI::Genotype->has_many('phenstatement_genotype_id', 'Bio::Chado::CDBI::Phenstatement' => 'genotype_id');
  



#
# Has Compound Many (many to many relationships in all their flavors)
#
 
  
  
sub stock_genotype_genotypes { return shift->stock_genotype_genotype_id }
 
 
  
sub phenotype_comparison_genotype1s { return shift->phenotype_comparison_genotype1_id }

  
sub phenotype_comparison_genotype2s { return shift->phenotype_comparison_genotype2_id }

   
 
  
sub phenotype_comparison_genotype1s { return shift->phenotype_comparison_genotype1_id }

  
  
sub phenotype_comparison_genotype2s { return shift->phenotype_comparison_genotype2_id }

   
 
  
sub phenotype_comparison_genotype1s { return shift->phenotype_comparison_genotype1_id }

  
sub phenotype_comparison_genotype2s { return shift->phenotype_comparison_genotype2_id }

   
 
  
sub phenotype_comparison_genotype1s { return shift->phenotype_comparison_genotype1_id }

  
sub phenotype_comparison_genotype2s { return shift->phenotype_comparison_genotype2_id }

  
   
 
  
sub phenstatement_genotypes { return shift->phenstatement_genotype_id }

   
 
  
sub phenstatement_genotypes { return shift->phenstatement_genotype_id }

   
 
  
sub phenstatement_genotypes { return shift->phenstatement_genotype_id }

   
 
  
sub phenstatement_genotypes { return shift->phenstatement_genotype_id }

   
# one to many to one
 
  
# one2one #
sub stocks { my $self = shift; return map $_->stock_id, $self->stock_genotype_genotype_id }

  
  
  
  
  

sub cvterms { my $self = shift; return map $_->type_id, $self->phenstatement_genotype_id }

  

sub environments { my $self = shift; return map $_->environment_id, $self->phenstatement_genotype_id }

  

sub pubs { my $self = shift; return map $_->pub_id, $self->phenstatement_genotype_id }

  

sub phenotypes { my $self = shift; return map $_->phenotype_id, $self->phenstatement_genotype_id }

# one to many to many
 
  
  
  
  
  
  
  
  
  
#many to many to one
 
  
  
# many2one #
  
  
sub phenotype_comparison_genotype1_organisms { my $self = shift; return map $_->organism_id, $self->phenotype_comparison_genotype1_id }
    
  
sub phenotype_comparison_genotype2_organisms { my $self = shift; return map $_->organism_id, $self->phenotype_comparison_genotype2_id }
    
   
  
  

  
  
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

########Bio::Chado::CDBI::Phylotree_Pub########

package Bio::Chado::CDBI::Phylotree_Pub;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Phylotree_Pub->set_up_table('phylotree_pub');

#
# Primary key accessors
#

sub id { shift->phylotree_pub_id }
sub phylotree_pub { shift->phylotree_pub_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Phylotree_Pub->has_a(phylotree_id => 'Bio::Chado::CDBI::Phylotree');
    
sub Bio::Chado::CDBI::Phylotree_Pub::phylotree { return shift->phylotree_id }
      
 
Bio::Chado::CDBI::Phylotree_Pub->has_a(pub_id => 'Bio::Chado::CDBI::Pub');
    
sub Bio::Chado::CDBI::Phylotree_Pub::pub { return shift->pub_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Dbxref########

package Bio::Chado::CDBI::Dbxref;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Dbxref->set_up_table('dbxref');

#
# Primary key accessors
#

sub id { shift->dbxref_id }
sub dbxref { shift->dbxref_id }
 



#
# Has A
#
  
  
  
  
 
Bio::Chado::CDBI::Dbxref->has_a(db_id => 'Bio::Chado::CDBI::Db');
    
sub Bio::Chado::CDBI::Dbxref::db { return shift->db_id }
      
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
   

#
# Has Many
#
 
Bio::Chado::CDBI::Dbxref->has_many('feature_dbxref_dbxref_id', 'Bio::Chado::CDBI::Feature_Dbxref' => 'dbxref_id');
  
    
sub feature_dbxrefs { return shift->feature_dbxref_dbxref_id }
      
Bio::Chado::CDBI::Dbxref->has_many('arraydesign_dbxref_id', 'Bio::Chado::CDBI::Arraydesign' => 'dbxref_id');
  
sub arraydesign_dbxrefs { return shift->arraydesign_dbxref_id }
#sub --arraydesign--dbxref_id-- {}
   
Bio::Chado::CDBI::Dbxref->has_many('cell_line_dbxref_dbxref_id', 'Bio::Chado::CDBI::Cell_Line_Dbxref' => 'dbxref_id');
  
    
sub cell_line_dbxrefs { return shift->cell_line_dbxref_dbxref_id }
      
Bio::Chado::CDBI::Dbxref->has_many('biomaterial_dbxref_dbxref_id', 'Bio::Chado::CDBI::Biomaterial_Dbxref' => 'dbxref_id');
    
Bio::Chado::CDBI::Dbxref->has_many('dbxrefprop_dbxref_id', 'Bio::Chado::CDBI::Dbxrefprop' => 'dbxref_id');
  
    
sub dbxrefprops { return shift->dbxrefprop_dbxref_id }
      
Bio::Chado::CDBI::Dbxref->has_many('feature_cvterm_dbxref_dbxref_id', 'Bio::Chado::CDBI::Feature_Cvterm_Dbxref' => 'dbxref_id');
   
Bio::Chado::CDBI::Dbxref->has_many('protocol_dbxref_id', 'Bio::Chado::CDBI::Protocol' => 'dbxref_id');
  
    
sub protocols { return shift->protocol_dbxref_id }
      
Bio::Chado::CDBI::Dbxref->has_many('feature_dbxref_id', 'Bio::Chado::CDBI::Feature' => 'dbxref_id');
  
sub feature_dbxrefs { return shift->feature_dbxref_id }
#sub --feature--dbxref_id-- {}
   
Bio::Chado::CDBI::Dbxref->has_many('stock_dbxref_dbxref_id', 'Bio::Chado::CDBI::Stock_Dbxref' => 'dbxref_id');
  
    
sub stock_dbxrefs { return shift->stock_dbxref_dbxref_id }
      
Bio::Chado::CDBI::Dbxref->has_many('cvterm_dbxref_dbxref_id', 'Bio::Chado::CDBI::Cvterm_Dbxref' => 'dbxref_id');
  
    
sub cvterm_dbxrefs { return shift->cvterm_dbxref_dbxref_id }
      
Bio::Chado::CDBI::Dbxref->has_many('stock_dbxref_id', 'Bio::Chado::CDBI::Stock' => 'dbxref_id');
  
    
sub stocks { return shift->stock_dbxref_id }
      
Bio::Chado::CDBI::Dbxref->has_many('biomaterial_dbxref_id', 'Bio::Chado::CDBI::Biomaterial' => 'dbxref_id');
  
sub biomaterial_dbxrefs { return shift->biomaterial_dbxref_id }
#sub --biomaterial--dbxref_id-- {}
   
Bio::Chado::CDBI::Dbxref->has_many('pub_dbxref_dbxref_id', 'Bio::Chado::CDBI::Pub_Dbxref' => 'dbxref_id');
  
    
sub pub_dbxrefs { return shift->pub_dbxref_dbxref_id }
      
Bio::Chado::CDBI::Dbxref->has_many('assay_dbxref_id', 'Bio::Chado::CDBI::Assay' => 'dbxref_id');
  
    
sub assays { return shift->assay_dbxref_id }
      
Bio::Chado::CDBI::Dbxref->has_many('organism_dbxref_dbxref_id', 'Bio::Chado::CDBI::Organism_Dbxref' => 'dbxref_id');
   
Bio::Chado::CDBI::Dbxref->has_many('study_dbxref_id', 'Bio::Chado::CDBI::Study' => 'dbxref_id');
  
    
sub studys { return shift->study_dbxref_id }
      
Bio::Chado::CDBI::Dbxref->has_many('element_dbxref_id', 'Bio::Chado::CDBI::Element' => 'dbxref_id');
   
Bio::Chado::CDBI::Dbxref->has_many('library_dbxref_dbxref_id', 'Bio::Chado::CDBI::Library_Dbxref' => 'dbxref_id');
  
    
sub library_dbxrefs { return shift->library_dbxref_dbxref_id }
      
Bio::Chado::CDBI::Dbxref->has_many('phylonode_dbxref_dbxref_id', 'Bio::Chado::CDBI::Phylonode_Dbxref' => 'dbxref_id');
   
Bio::Chado::CDBI::Dbxref->has_many('cvterm_dbxref_id', 'Bio::Chado::CDBI::Cvterm' => 'dbxref_id');
  
sub cvterm_dbxrefs { return shift->cvterm_dbxref_id }
#sub --cvterm--dbxref_id-- {}
   
Bio::Chado::CDBI::Dbxref->has_many('phylotree_dbxref_id', 'Bio::Chado::CDBI::Phylotree' => 'dbxref_id');
  
    
sub phylotrees { return shift->phylotree_dbxref_id }
     



#
# Has Compound Many (many to many relationships in all their flavors)
#
 
  
  
sub element_dbxrefs { return shift->element_dbxref_id }
 
 
  
  
sub element_dbxrefs { return shift->element_dbxref_id }
 
 
  
  
sub element_dbxrefs { return shift->element_dbxref_id }
 
 
  
  
sub feature_cvterm_dbxref_dbxrefs { return shift->feature_cvterm_dbxref_dbxref_id }
 
 
  
  
sub organism_dbxref_dbxrefs { return shift->organism_dbxref_dbxref_id }
 
 
  
  
sub biomaterial_dbxref_dbxrefs { return shift->biomaterial_dbxref_dbxref_id }
 
 
  
  
sub phylonode_dbxref_dbxrefs { return shift->phylonode_dbxref_dbxref_id }
 
# one to many to one
 
  
# one2one #
sub cvterms { my $self = shift; return map $_->type_id, $self->element_dbxref_id }

  

sub features { my $self = shift; return map $_->feature_id, $self->element_dbxref_id }

  

sub arraydesigns { my $self = shift; return map $_->arraydesign_id, $self->element_dbxref_id }

  

sub feature_cvterms { my $self = shift; return map $_->feature_cvterm_id, $self->feature_cvterm_dbxref_dbxref_id }

  

sub organisms { my $self = shift; return map $_->organism_id, $self->organism_dbxref_dbxref_id }

  

sub biomaterials { my $self = shift; return map $_->biomaterial_id, $self->biomaterial_dbxref_dbxref_id }

  

sub phylonodes { my $self = shift; return map $_->phylonode_id, $self->phylonode_dbxref_dbxref_id }

# one to many to many
 
  
  
  
  
  
  
  
#many to many to one
 
  
  
  
  
  
  
  
#many to many to many


  
  
  
  
  
  
   

1;

########Bio::Chado::CDBI::Assayprop########

package Bio::Chado::CDBI::Assayprop;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Assayprop->set_up_table('assayprop');

#
# Primary key accessors
#

sub id { shift->assayprop_id }
sub assayprop { shift->assayprop_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Assayprop->has_a(assay_id => 'Bio::Chado::CDBI::Assay');
    
sub Bio::Chado::CDBI::Assayprop::assay { return shift->assay_id }
      
 
Bio::Chado::CDBI::Assayprop->has_a(type_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Assayprop::cvterm { return shift->type_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Contact_Relationship########

package Bio::Chado::CDBI::Contact_Relationship;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Contact_Relationship->set_up_table('contact_relationship');

#
# Primary key accessors
#

sub id { shift->contact_relationship_id }
sub contact_relationship { shift->contact_relationship_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Contact_Relationship->has_a(type_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Contact_Relationship::cvterm { return shift->type_id }
      
 
Bio::Chado::CDBI::Contact_Relationship->has_a(subject_id => 'Bio::Chado::CDBI::Contact');
    
sub subject { return shift->subject_id }
      
 
Bio::Chado::CDBI::Contact_Relationship->has_a(object_id => 'Bio::Chado::CDBI::Contact');
    
sub object { return shift->object_id }
       

#
# Has Many
#
   


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Tableinfo########

package Bio::Chado::CDBI::Tableinfo;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Tableinfo->set_up_table('tableinfo');

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
 
Bio::Chado::CDBI::Tableinfo->has_many('control_tableinfo_id', 'Bio::Chado::CDBI::Control' => 'tableinfo_id');
  
    
sub controls { return shift->control_tableinfo_id }
      
Bio::Chado::CDBI::Tableinfo->has_many('magedocumentation_tableinfo_id', 'Bio::Chado::CDBI::Magedocumentation' => 'tableinfo_id');
  
    
sub magedocumentations { return shift->magedocumentation_tableinfo_id }
     


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Pub########

package Bio::Chado::CDBI::Pub;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Pub->set_up_table('pub');

#
# Primary key accessors
#

sub id { shift->pub_id }
sub pub { shift->pub_id }
 



#
# Has A
#
  
  
  
  
  
  
  
 
Bio::Chado::CDBI::Pub->has_a(type_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Pub::cvterm { return shift->type_id }
      
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
   

#
# Has Many
#
 
Bio::Chado::CDBI::Pub->has_many('feature_expression_pub_id', 'Bio::Chado::CDBI::Feature_Expression' => 'pub_id');
   
Bio::Chado::CDBI::Pub->has_many('feature_cvterm_pub_id', 'Bio::Chado::CDBI::Feature_Cvterm' => 'pub_id');
  
sub feature_cvterm_pubs { return shift->feature_cvterm_pub_id }
#sub --feature_cvterm--pub_id-- {}
   
Bio::Chado::CDBI::Pub->has_many('cell_line_feature_pub_id', 'Bio::Chado::CDBI::Cell_Line_Feature' => 'pub_id');
   
Bio::Chado::CDBI::Pub->has_many('cell_line_synonym_pub_id', 'Bio::Chado::CDBI::Cell_Line_Synonym' => 'pub_id');
  
    
sub cell_line_synonyms { return shift->cell_line_synonym_pub_id }
      
Bio::Chado::CDBI::Pub->has_many('phenotype_comparison_cvterm_pub_id', 'Bio::Chado::CDBI::Phenotype_Comparison_Cvterm' => 'pub_id');
  
    
sub phenotype_comparison_cvterms { return shift->phenotype_comparison_cvterm_pub_id }
      
Bio::Chado::CDBI::Pub->has_many('phylonode_pub_pub_id', 'Bio::Chado::CDBI::Phylonode_Pub' => 'pub_id');
   
Bio::Chado::CDBI::Pub->has_many('phylotree_pub_pub_id', 'Bio::Chado::CDBI::Phylotree_Pub' => 'pub_id');
    
Bio::Chado::CDBI::Pub->has_many('libraryprop_pub_pub_id', 'Bio::Chado::CDBI::Libraryprop_Pub' => 'pub_id');
   
Bio::Chado::CDBI::Pub->has_many('feature_pub_pub_id', 'Bio::Chado::CDBI::Feature_Pub' => 'pub_id');
   
Bio::Chado::CDBI::Pub->has_many('protocol_pub_id', 'Bio::Chado::CDBI::Protocol' => 'pub_id');
  
    
sub protocols { return shift->protocol_pub_id }
      
Bio::Chado::CDBI::Pub->has_many('featureloc_pub_pub_id', 'Bio::Chado::CDBI::Featureloc_Pub' => 'pub_id');
   
Bio::Chado::CDBI::Pub->has_many('library_pub_pub_id', 'Bio::Chado::CDBI::Library_Pub' => 'pub_id');
   
Bio::Chado::CDBI::Pub->has_many('cell_line_library_pub_id', 'Bio::Chado::CDBI::Cell_Line_Library' => 'pub_id');
   
Bio::Chado::CDBI::Pub->has_many('stock_pub_pub_id', 'Bio::Chado::CDBI::Stock_Pub' => 'pub_id');
   
Bio::Chado::CDBI::Pub->has_many('feature_relationshipprop_pub_pub_id', 'Bio::Chado::CDBI::Feature_Relationshipprop_Pub' => 'pub_id');
   
Bio::Chado::CDBI::Pub->has_many('pub_dbxref_pub_id', 'Bio::Chado::CDBI::Pub_Dbxref' => 'pub_id');
  
    
sub pub_dbxrefs { return shift->pub_dbxref_pub_id }
      
Bio::Chado::CDBI::Pub->has_many('phendesc_pub_id', 'Bio::Chado::CDBI::Phendesc' => 'pub_id');
  
    
sub phendescs { return shift->phendesc_pub_id }
      
Bio::Chado::CDBI::Pub->has_many('featureprop_pub_pub_id', 'Bio::Chado::CDBI::Featureprop_Pub' => 'pub_id');
   
Bio::Chado::CDBI::Pub->has_many('library_synonym_pub_id', 'Bio::Chado::CDBI::Library_Synonym' => 'pub_id');
  
    
sub library_synonyms { return shift->library_synonym_pub_id }
      
Bio::Chado::CDBI::Pub->has_many('pub_relationship_subject_id', 'Bio::Chado::CDBI::Pub_Relationship' => 'subject_id');
   
Bio::Chado::CDBI::Pub->has_many('pub_relationship_object_id', 'Bio::Chado::CDBI::Pub_Relationship' => 'object_id');
   
Bio::Chado::CDBI::Pub->has_many('expression_pub_pub_id', 'Bio::Chado::CDBI::Expression_Pub' => 'pub_id');
   
Bio::Chado::CDBI::Pub->has_many('study_pub_id', 'Bio::Chado::CDBI::Study' => 'pub_id');
  
    
sub studys { return shift->study_pub_id }
      
Bio::Chado::CDBI::Pub->has_many('stock_cvterm_pub_id', 'Bio::Chado::CDBI::Stock_Cvterm' => 'pub_id');
   
Bio::Chado::CDBI::Pub->has_many('cell_line_cvterm_pub_id', 'Bio::Chado::CDBI::Cell_Line_Cvterm' => 'pub_id');
  
    
sub cell_line_cvterms { return shift->cell_line_cvterm_pub_id }
      
Bio::Chado::CDBI::Pub->has_many('stockprop_pub_pub_id', 'Bio::Chado::CDBI::Stockprop_Pub' => 'pub_id');
   
Bio::Chado::CDBI::Pub->has_many('pubauthor_pub_id', 'Bio::Chado::CDBI::Pubauthor' => 'pub_id');
  
    
sub pubauthors { return shift->pubauthor_pub_id }
      
Bio::Chado::CDBI::Pub->has_many('phenotype_comparison_pub_id', 'Bio::Chado::CDBI::Phenotype_Comparison' => 'pub_id');
   
Bio::Chado::CDBI::Pub->has_many('cell_lineprop_pub_pub_id', 'Bio::Chado::CDBI::Cell_Lineprop_Pub' => 'pub_id');
   
Bio::Chado::CDBI::Pub->has_many('library_cvterm_pub_id', 'Bio::Chado::CDBI::Library_Cvterm' => 'pub_id');
   
Bio::Chado::CDBI::Pub->has_many('stock_relationship_pub_pub_id', 'Bio::Chado::CDBI::Stock_Relationship_Pub' => 'pub_id');
   
Bio::Chado::CDBI::Pub->has_many('feature_relationship_pub_pub_id', 'Bio::Chado::CDBI::Feature_Relationship_Pub' => 'pub_id');
   
Bio::Chado::CDBI::Pub->has_many('pubprop_pub_id', 'Bio::Chado::CDBI::Pubprop' => 'pub_id');
  
    
sub pubprops { return shift->pubprop_pub_id }
      
Bio::Chado::CDBI::Pub->has_many('feature_cvterm_pub_pub_id', 'Bio::Chado::CDBI::Feature_Cvterm_Pub' => 'pub_id');
   
Bio::Chado::CDBI::Pub->has_many('feature_synonym_pub_id', 'Bio::Chado::CDBI::Feature_Synonym' => 'pub_id');
  
    
sub feature_synonyms { return shift->feature_synonym_pub_id }
      
Bio::Chado::CDBI::Pub->has_many('cell_line_pub_pub_id', 'Bio::Chado::CDBI::Cell_Line_Pub' => 'pub_id');
   
Bio::Chado::CDBI::Pub->has_many('featuremap_pub_pub_id', 'Bio::Chado::CDBI::Featuremap_Pub' => 'pub_id');
   
Bio::Chado::CDBI::Pub->has_many('phenstatement_pub_id', 'Bio::Chado::CDBI::Phenstatement' => 'pub_id');
  



#
# Has Compound Many (many to many relationships in all their flavors)
#
 
  
  
sub libraryprop_pub_pubs { return shift->libraryprop_pub_pub_id }
 
 
  
  
sub library_cvterm_pubs { return shift->library_cvterm_pub_id }
 
 
  
  
sub library_cvterm_pubs { return shift->library_cvterm_pub_id }
 
 
  
sub phenotype_comparison_pubs { return shift->phenotype_comparison_pub_id }

   
 
  
  
  
sub phenotype_comparison_pubs { return shift->phenotype_comparison_pub_id }
 
 
  
  
  
sub phenotype_comparison_pubs { return shift->phenotype_comparison_pub_id }
 
 
  
  
  
sub phenotype_comparison_pubs { return shift->phenotype_comparison_pub_id }
 
 
  
  
sub featuremap_pub_pubs { return shift->featuremap_pub_pub_id }
 
 
  
sub pub_relationship_subjects { return shift->pub_relationship_subject_id }

  
sub pub_relationship_objects { return shift->pub_relationship_object_id }

   
 
  
  
sub phylotree_pub_pubs { return shift->phylotree_pub_pub_id }
 
 
  
  
sub stockprop_pub_pubs { return shift->stockprop_pub_pub_id }
 
 
  
  
sub cell_lineprop_pub_pubs { return shift->cell_lineprop_pub_pub_id }
 
 
  
  
sub cell_line_feature_pubs { return shift->cell_line_feature_pub_id }
 
 
  
  
sub cell_line_feature_pubs { return shift->cell_line_feature_pub_id }
 
 
  
  
sub feature_relationshipprop_pub_pubs { return shift->feature_relationshipprop_pub_pub_id }
 
 
  
  
sub stock_cvterm_pubs { return shift->stock_cvterm_pub_id }
 
 
  
  
sub stock_cvterm_pubs { return shift->stock_cvterm_pub_id }
 
 
  
  
sub feature_cvterm_pub_pubs { return shift->feature_cvterm_pub_pub_id }
 
 
  
  
sub stock_pub_pubs { return shift->stock_pub_pub_id }
 
 
  
  
sub feature_relationship_pub_pubs { return shift->feature_relationship_pub_pub_id }
 
 
  
  
sub featureprop_pub_pubs { return shift->featureprop_pub_pub_id }
 
 
  
  
sub phylonode_pub_pubs { return shift->phylonode_pub_pub_id }
 
 
  
  
sub stock_relationship_pub_pubs { return shift->stock_relationship_pub_pub_id }
 
 
  
  
sub library_pub_pubs { return shift->library_pub_pub_id }
 
 
  
  
sub feature_pub_pubs { return shift->feature_pub_pub_id }
 
 
  
  
sub featureloc_pub_pubs { return shift->featureloc_pub_pub_id }
 
 
  
  
sub phenstatement_pubs { return shift->phenstatement_pub_id }
 
 
  
  
sub phenstatement_pubs { return shift->phenstatement_pub_id }
 
 
  
  
sub phenstatement_pubs { return shift->phenstatement_pub_id }
 
 
  
  
sub phenstatement_pubs { return shift->phenstatement_pub_id }
 
 
  
  
sub cell_line_library_pubs { return shift->cell_line_library_pub_id }
 
 
  
  
sub cell_line_library_pubs { return shift->cell_line_library_pub_id }
 
 
  
  
sub cell_line_pub_pubs { return shift->cell_line_pub_pub_id }
 
 
  
  
sub feature_expression_pubs { return shift->feature_expression_pub_id }
 
 
  
  
sub feature_expression_pubs { return shift->feature_expression_pub_id }
 
 
  
  
sub expression_pub_pubs { return shift->expression_pub_pub_id }
 
# one to many to one
 
  
# one2one #
sub libraryprops { my $self = shift; return map $_->libraryprop_id, $self->libraryprop_pub_pub_id }

  

sub cvterms { my $self = shift; return map $_->cvterm_id, $self->library_cvterm_pub_id }

  

sub librarys { my $self = shift; return map $_->library_id, $self->library_cvterm_pub_id }

  

sub organisms { my $self = shift; return map $_->organism_id, $self->phenotype_comparison_pub_id }

  
  
  
  

sub featuremaps { my $self = shift; return map $_->featuremap_id, $self->featuremap_pub_pub_id }

  
  

sub phylotrees { my $self = shift; return map $_->phylotree_id, $self->phylotree_pub_pub_id }

  

sub stockprops { my $self = shift; return map $_->stockprop_id, $self->stockprop_pub_pub_id }

  

sub cell_lineprops { my $self = shift; return map $_->cell_lineprop_id, $self->cell_lineprop_pub_pub_id }

  

sub cell_lines { my $self = shift; return map $_->cell_line_id, $self->cell_line_feature_pub_id }

  

sub features { my $self = shift; return map $_->feature_id, $self->cell_line_feature_pub_id }

  

sub feature_relationshipprops { my $self = shift; return map $_->feature_relationshipprop_id, $self->feature_relationshipprop_pub_pub_id }

  

sub cvterms { my $self = shift; return map $_->cvterm_id, $self->stock_cvterm_pub_id }

  

sub stocks { my $self = shift; return map $_->stock_id, $self->stock_cvterm_pub_id }

  

sub feature_cvterms { my $self = shift; return map $_->feature_cvterm_id, $self->feature_cvterm_pub_pub_id }

  

sub stocks { my $self = shift; return map $_->stock_id, $self->stock_pub_pub_id }

  

sub feature_relationships { my $self = shift; return map $_->feature_relationship_id, $self->feature_relationship_pub_pub_id }

  

sub featureprops { my $self = shift; return map $_->featureprop_id, $self->featureprop_pub_pub_id }

  

sub phylonodes { my $self = shift; return map $_->phylonode_id, $self->phylonode_pub_pub_id }

  

sub stock_relationships { my $self = shift; return map $_->stock_relationship_id, $self->stock_relationship_pub_pub_id }

  

sub librarys { my $self = shift; return map $_->library_id, $self->library_pub_pub_id }

  

sub features { my $self = shift; return map $_->feature_id, $self->feature_pub_pub_id }

  

sub featurelocs { my $self = shift; return map $_->featureloc_id, $self->featureloc_pub_pub_id }

  

sub cvterms { my $self = shift; return map $_->type_id, $self->phenstatement_pub_id }

  

sub genotypes { my $self = shift; return map $_->genotype_id, $self->phenstatement_pub_id }

  

sub environments { my $self = shift; return map $_->environment_id, $self->phenstatement_pub_id }

  

sub phenotypes { my $self = shift; return map $_->phenotype_id, $self->phenstatement_pub_id }

  

sub librarys { my $self = shift; return map $_->library_id, $self->cell_line_library_pub_id }

  

sub cell_lines { my $self = shift; return map $_->cell_line_id, $self->cell_line_library_pub_id }

  

sub cell_lines { my $self = shift; return map $_->cell_line_id, $self->cell_line_pub_pub_id }

  

sub expressions { my $self = shift; return map $_->expression_id, $self->feature_expression_pub_id }

  

sub features { my $self = shift; return map $_->feature_id, $self->feature_expression_pub_id }

  

sub expressions { my $self = shift; return map $_->expression_id, $self->expression_pub_pub_id }

# one to many to many
 
  
  
  
  
  
# one2many #
  
  
  
    
sub phenotype_comparison_genotype1s { my $self = shift; return map $_->genotype1_id, $self->phenotype_comparison_pub_id }
    
  
     
  

  
  
  
    
sub phenotype_comparison_environment1s { my $self = shift; return map $_->environment1_id, $self->phenotype_comparison_pub_id }
    
  
     
  

  
  
  
    
sub phenotype_comparison_phenotype1s { my $self = shift; return map $_->phenotype1_id, $self->phenotype_comparison_pub_id }
    
  
     
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
#many to many to one
 
  
  
  
  
  
  
  
  
  
# many2one #
  
  
sub pub_relationship_subject_types { my $self = shift; return map $_->type_id, $self->pub_relationship_subject_id }
    
  
sub pub_relationship_object_types { my $self = shift; return map $_->type_id, $self->pub_relationship_object_id }
    
   
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
#many to many to many


  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
   

1;

########Bio::Chado::CDBI::Organismprop########

package Bio::Chado::CDBI::Organismprop;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Organismprop->set_up_table('organismprop');

#
# Primary key accessors
#

sub id { shift->organismprop_id }
sub organismprop { shift->organismprop_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Organismprop->has_a(organism_id => 'Bio::Chado::CDBI::Organism');
    
sub Bio::Chado::CDBI::Organismprop::organism { return shift->organism_id }
      
 
Bio::Chado::CDBI::Organismprop->has_a(type_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Organismprop::cvterm { return shift->type_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Libraryprop_Pub########

package Bio::Chado::CDBI::Libraryprop_Pub;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Libraryprop_Pub->set_up_table('libraryprop_pub');

#
# Primary key accessors
#

sub id { shift->libraryprop_pub_id }
sub libraryprop_pub { shift->libraryprop_pub_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Libraryprop_Pub->has_a(libraryprop_id => 'Bio::Chado::CDBI::Libraryprop');
    
sub Bio::Chado::CDBI::Libraryprop_Pub::libraryprop { return shift->libraryprop_id }
      
 
Bio::Chado::CDBI::Libraryprop_Pub->has_a(pub_id => 'Bio::Chado::CDBI::Pub');
    
sub Bio::Chado::CDBI::Libraryprop_Pub::pub { return shift->pub_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Dbxrefprop########

package Bio::Chado::CDBI::Dbxrefprop;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Dbxrefprop->set_up_table('dbxrefprop');

#
# Primary key accessors
#

sub id { shift->dbxrefprop_id }
sub dbxrefprop { shift->dbxrefprop_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Dbxrefprop->has_a(dbxref_id => 'Bio::Chado::CDBI::Dbxref');
    
sub Bio::Chado::CDBI::Dbxrefprop::dbxref { return shift->dbxref_id }
      
 
Bio::Chado::CDBI::Dbxrefprop->has_a(type_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Dbxrefprop::cvterm { return shift->type_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Featureloc########

package Bio::Chado::CDBI::Featureloc;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Featureloc->set_up_table('featureloc');

#
# Primary key accessors
#

sub id { shift->featureloc_id }
sub featureloc { shift->featureloc_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Featureloc->has_a(feature_id => 'Bio::Chado::CDBI::Feature');
    
sub feature { return shift->feature_id }
      
 
Bio::Chado::CDBI::Featureloc->has_a(srcfeature_id => 'Bio::Chado::CDBI::Feature');
    
sub srcfeature { return shift->srcfeature_id }
      
   

#
# Has Many
#
   
Bio::Chado::CDBI::Featureloc->has_many('featureloc_pub_featureloc_id', 'Bio::Chado::CDBI::Featureloc_Pub' => 'featureloc_id');
  



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

########Bio::Chado::CDBI::Analysisfeature########

package Bio::Chado::CDBI::Analysisfeature;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Analysisfeature->set_up_table('analysisfeature');

#
# Primary key accessors
#

sub id { shift->analysisfeature_id }
sub analysisfeature { shift->analysisfeature_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Analysisfeature->has_a(feature_id => 'Bio::Chado::CDBI::Feature');
    
sub Bio::Chado::CDBI::Analysisfeature::feature { return shift->feature_id }
      
 
Bio::Chado::CDBI::Analysisfeature->has_a(analysis_id => 'Bio::Chado::CDBI::Analysis');
    
sub Bio::Chado::CDBI::Analysisfeature::analysis { return shift->analysis_id }
      
   

#
# Has Many
#
   
Bio::Chado::CDBI::Analysisfeature->has_many('analysisfeatureprop_analysisfeature_id', 'Bio::Chado::CDBI::Analysisfeatureprop' => 'analysisfeature_id');
  
    
sub analysisfeatureprops { return shift->analysisfeatureprop_analysisfeature_id }
     


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Feature_Cvterm_Dbxref########

package Bio::Chado::CDBI::Feature_Cvterm_Dbxref;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Feature_Cvterm_Dbxref->set_up_table('feature_cvterm_dbxref');

#
# Primary key accessors
#

sub id { shift->feature_cvterm_dbxref_id }
sub feature_cvterm_dbxref { shift->feature_cvterm_dbxref_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Feature_Cvterm_Dbxref->has_a(feature_cvterm_id => 'Bio::Chado::CDBI::Feature_Cvterm');
    
sub Bio::Chado::CDBI::Feature_Cvterm_Dbxref::feature_cvterm { return shift->feature_cvterm_id }
      
 
Bio::Chado::CDBI::Feature_Cvterm_Dbxref->has_a(dbxref_id => 'Bio::Chado::CDBI::Dbxref');
    
sub Bio::Chado::CDBI::Feature_Cvterm_Dbxref::dbxref { return shift->dbxref_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Feature_Pub########

package Bio::Chado::CDBI::Feature_Pub;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Feature_Pub->set_up_table('feature_pub');

#
# Primary key accessors
#

sub id { shift->feature_pub_id }
sub feature_pub { shift->feature_pub_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Feature_Pub->has_a(feature_id => 'Bio::Chado::CDBI::Feature');
    
sub Bio::Chado::CDBI::Feature_Pub::feature { return shift->feature_id }
      
 
Bio::Chado::CDBI::Feature_Pub->has_a(pub_id => 'Bio::Chado::CDBI::Pub');
    
sub Bio::Chado::CDBI::Feature_Pub::pub { return shift->pub_id }
      
   

#
# Has Many
#
   
Bio::Chado::CDBI::Feature_Pub->has_many('feature_pubprop_feature_pub_id', 'Bio::Chado::CDBI::Feature_Pubprop' => 'feature_pub_id');
  
    
sub feature_pubprops { return shift->feature_pubprop_feature_pub_id }
     


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Feature_Relationship########

package Bio::Chado::CDBI::Feature_Relationship;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Feature_Relationship->set_up_table('feature_relationship');

#
# Primary key accessors
#

sub id { shift->feature_relationship_id }
sub feature_relationship { shift->feature_relationship_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Feature_Relationship->has_a(subject_id => 'Bio::Chado::CDBI::Feature');
    
sub subject { return shift->subject_id }
      
 
Bio::Chado::CDBI::Feature_Relationship->has_a(object_id => 'Bio::Chado::CDBI::Feature');
    
sub object { return shift->object_id }
      
 
Bio::Chado::CDBI::Feature_Relationship->has_a(type_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Feature_Relationship::cvterm { return shift->type_id }
      
  
   

#
# Has Many
#
    
Bio::Chado::CDBI::Feature_Relationship->has_many('feature_relationshipprop_feature_relationship_id', 'Bio::Chado::CDBI::Feature_Relationshipprop' => 'feature_relationship_id');
  
    
sub feature_relationshipprops { return shift->feature_relationshipprop_feature_relationship_id }
      
Bio::Chado::CDBI::Feature_Relationship->has_many('feature_relationship_pub_feature_relationship_id', 'Bio::Chado::CDBI::Feature_Relationship_Pub' => 'feature_relationship_id');
  



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

########Bio::Chado::CDBI::Acquisition_Relationship########

package Bio::Chado::CDBI::Acquisition_Relationship;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Acquisition_Relationship->set_up_table('acquisition_relationship');

#
# Primary key accessors
#

sub id { shift->acquisition_relationship_id }
sub acquisition_relationship { shift->acquisition_relationship_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Acquisition_Relationship->has_a(subject_id => 'Bio::Chado::CDBI::Acquisition');
    
sub subject { return shift->subject_id }
      
 
Bio::Chado::CDBI::Acquisition_Relationship->has_a(type_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Acquisition_Relationship::cvterm { return shift->type_id }
      
 
Bio::Chado::CDBI::Acquisition_Relationship->has_a(object_id => 'Bio::Chado::CDBI::Acquisition');
    
sub object { return shift->object_id }
       

#
# Has Many
#
   


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Feature_Cvtermprop########

package Bio::Chado::CDBI::Feature_Cvtermprop;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Feature_Cvtermprop->set_up_table('feature_cvtermprop');

#
# Primary key accessors
#

sub id { shift->feature_cvtermprop_id }
sub feature_cvtermprop { shift->feature_cvtermprop_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Feature_Cvtermprop->has_a(feature_cvterm_id => 'Bio::Chado::CDBI::Feature_Cvterm');
    
sub Bio::Chado::CDBI::Feature_Cvtermprop::feature_cvterm { return shift->feature_cvterm_id }
      
 
Bio::Chado::CDBI::Feature_Cvtermprop->has_a(type_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Feature_Cvtermprop::cvterm { return shift->type_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Protocol########

package Bio::Chado::CDBI::Protocol;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Protocol->set_up_table('protocol');

#
# Primary key accessors
#

sub id { shift->protocol_id }
sub protocol { shift->protocol_id }
 



#
# Has A
#
  
  
 
Bio::Chado::CDBI::Protocol->has_a(type_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Protocol::cvterm { return shift->type_id }
      
 
Bio::Chado::CDBI::Protocol->has_a(pub_id => 'Bio::Chado::CDBI::Pub');
    
sub Bio::Chado::CDBI::Protocol::pub { return shift->pub_id }
      
 
Bio::Chado::CDBI::Protocol->has_a(dbxref_id => 'Bio::Chado::CDBI::Dbxref');
    
sub Bio::Chado::CDBI::Protocol::dbxref { return shift->dbxref_id }
      
  
  
  
   

#
# Has Many
#
 
Bio::Chado::CDBI::Protocol->has_many('quantification_protocol_id', 'Bio::Chado::CDBI::Quantification' => 'protocol_id');
  
    
sub quantifications { return shift->quantification_protocol_id }
      
Bio::Chado::CDBI::Protocol->has_many('arraydesign_protocol_id', 'Bio::Chado::CDBI::Arraydesign' => 'protocol_id');
  
    
sub arraydesigns { return shift->arraydesign_protocol_id }
         
Bio::Chado::CDBI::Protocol->has_many('protocolparam_protocol_id', 'Bio::Chado::CDBI::Protocolparam' => 'protocol_id');
  
    
sub protocolparams { return shift->protocolparam_protocol_id }
      
Bio::Chado::CDBI::Protocol->has_many('assay_protocol_id', 'Bio::Chado::CDBI::Assay' => 'protocol_id');
  
    
sub assays { return shift->assay_protocol_id }
      
Bio::Chado::CDBI::Protocol->has_many('acquisition_protocol_id', 'Bio::Chado::CDBI::Acquisition' => 'protocol_id');
  
    
sub acquisitions { return shift->acquisition_protocol_id }
      
Bio::Chado::CDBI::Protocol->has_many('treatment_protocol_id', 'Bio::Chado::CDBI::Treatment' => 'protocol_id');
  
    
sub treatments { return shift->treatment_protocol_id }
     


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Featureloc_Pub########

package Bio::Chado::CDBI::Featureloc_Pub;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Featureloc_Pub->set_up_table('featureloc_pub');

#
# Primary key accessors
#

sub id { shift->featureloc_pub_id }
sub featureloc_pub { shift->featureloc_pub_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Featureloc_Pub->has_a(featureloc_id => 'Bio::Chado::CDBI::Featureloc');
    
sub Bio::Chado::CDBI::Featureloc_Pub::featureloc { return shift->featureloc_id }
      
 
Bio::Chado::CDBI::Featureloc_Pub->has_a(pub_id => 'Bio::Chado::CDBI::Pub');
    
sub Bio::Chado::CDBI::Featureloc_Pub::pub { return shift->pub_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Feature########

package Bio::Chado::CDBI::Feature;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Feature->set_up_table('feature');

#
# Primary key accessors
#

sub id { shift->feature_id }
sub feature { shift->feature_id }
 



#
# Has A
#
  
  
  
  
  
  
  
  
  
  
  
 
Bio::Chado::CDBI::Feature->has_a(dbxref_id => 'Bio::Chado::CDBI::Dbxref');
    
sub Bio::Chado::CDBI::Feature::dbxref { return shift->dbxref_id }
      
 
Bio::Chado::CDBI::Feature->has_a(organism_id => 'Bio::Chado::CDBI::Organism');
    
sub Bio::Chado::CDBI::Feature::organism { return shift->organism_id }
      
 
Bio::Chado::CDBI::Feature->has_a(type_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Feature::cvterm { return shift->type_id }
      
  
  
  
  
  
  
  
  
  
  
  
  
  
  
   

#
# Has Many
#
 
Bio::Chado::CDBI::Feature->has_many('feature_dbxref_feature_id', 'Bio::Chado::CDBI::Feature_Dbxref' => 'feature_id');
  
    
sub feature_dbxrefs { return shift->feature_dbxref_feature_id }
      
Bio::Chado::CDBI::Feature->has_many('feature_expression_feature_id', 'Bio::Chado::CDBI::Feature_Expression' => 'feature_id');
   
Bio::Chado::CDBI::Feature->has_many('feature_cvterm_feature_id', 'Bio::Chado::CDBI::Feature_Cvterm' => 'feature_id');
  
    
sub feature_cvterms { return shift->feature_cvterm_feature_id }
      
Bio::Chado::CDBI::Feature->has_many('cell_line_feature_feature_id', 'Bio::Chado::CDBI::Cell_Line_Feature' => 'feature_id');
   
Bio::Chado::CDBI::Feature->has_many('feature_phenotype_feature_id', 'Bio::Chado::CDBI::Feature_Phenotype' => 'feature_id');
   
Bio::Chado::CDBI::Feature->has_many('featureloc_feature_id', 'Bio::Chado::CDBI::Featureloc' => 'feature_id');
  
    
sub featureloc_feature_ids { my $self = shift; return $self->featureloc_feature_id(@_) }
      
Bio::Chado::CDBI::Feature->has_many('featureloc_srcfeature_id', 'Bio::Chado::CDBI::Featureloc' => 'srcfeature_id');
  
    
sub featureloc_srcfeature_ids { my $self = shift; return $self->featureloc_srcfeature_id(@_) }
      
Bio::Chado::CDBI::Feature->has_many('analysisfeature_feature_id', 'Bio::Chado::CDBI::Analysisfeature' => 'feature_id');
  
    
sub analysisfeatures { return shift->analysisfeature_feature_id }
      
Bio::Chado::CDBI::Feature->has_many('feature_pub_feature_id', 'Bio::Chado::CDBI::Feature_Pub' => 'feature_id');
   
Bio::Chado::CDBI::Feature->has_many('feature_relationship_subject_id', 'Bio::Chado::CDBI::Feature_Relationship' => 'subject_id');
  
    
sub feature_relationship_subject_ids { my $self = shift; return $self->feature_relationship_subject_id(@_) }
      
Bio::Chado::CDBI::Feature->has_many('feature_relationship_object_id', 'Bio::Chado::CDBI::Feature_Relationship' => 'object_id');
  
    
sub feature_relationship_object_ids { my $self = shift; return $self->feature_relationship_object_id(@_) }
         
Bio::Chado::CDBI::Feature->has_many('library_feature_feature_id', 'Bio::Chado::CDBI::Library_Feature' => 'feature_id');
   
Bio::Chado::CDBI::Feature->has_many('studyprop_feature_feature_id', 'Bio::Chado::CDBI::Studyprop_Feature' => 'feature_id');
   
Bio::Chado::CDBI::Feature->has_many('featureprop_feature_id', 'Bio::Chado::CDBI::Featureprop' => 'feature_id');
  
    
sub featureprops { return shift->featureprop_feature_id }
      
Bio::Chado::CDBI::Feature->has_many('element_feature_id', 'Bio::Chado::CDBI::Element' => 'feature_id');
   
Bio::Chado::CDBI::Feature->has_many('featurerange_feature_id', 'Bio::Chado::CDBI::Featurerange' => 'feature_id');
  
    
sub featurerange_feature_ids { my $self = shift; return $self->featurerange_feature_id(@_) }
      
Bio::Chado::CDBI::Feature->has_many('featurerange_leftstartf_id', 'Bio::Chado::CDBI::Featurerange' => 'leftstartf_id');
  
    
sub featurerange_leftstartf_ids { my $self = shift; return $self->featurerange_leftstartf_id(@_) }
      
Bio::Chado::CDBI::Feature->has_many('featurerange_leftendf_id', 'Bio::Chado::CDBI::Featurerange' => 'leftendf_id');
  
    
sub featurerange_leftendf_ids { my $self = shift; return $self->featurerange_leftendf_id(@_) }
      
Bio::Chado::CDBI::Feature->has_many('featurerange_rightstartf_id', 'Bio::Chado::CDBI::Featurerange' => 'rightstartf_id');
  
    
sub featurerange_rightstartf_ids { my $self = shift; return $self->featurerange_rightstartf_id(@_) }
      
Bio::Chado::CDBI::Feature->has_many('featurerange_rightendf_id', 'Bio::Chado::CDBI::Featurerange' => 'rightendf_id');
  
    
sub featurerange_rightendf_ids { my $self = shift; return $self->featurerange_rightendf_id(@_) }
      
Bio::Chado::CDBI::Feature->has_many('featurepos_feature_id', 'Bio::Chado::CDBI::Featurepos' => 'feature_id');
  
    
sub featurepos_feature_ids { my $self = shift; return $self->featurepos_feature_id(@_) }
      
Bio::Chado::CDBI::Feature->has_many('featurepos_map_feature_id', 'Bio::Chado::CDBI::Featurepos' => 'map_feature_id');
  
    
sub featurepos_map_feature_ids { my $self = shift; return $self->featurepos_map_feature_id(@_) }
      
Bio::Chado::CDBI::Feature->has_many('phylonode_feature_id', 'Bio::Chado::CDBI::Phylonode' => 'feature_id');
  
    
sub phylonodes { return shift->phylonode_feature_id }
      
Bio::Chado::CDBI::Feature->has_many('feature_synonym_feature_id', 'Bio::Chado::CDBI::Feature_Synonym' => 'feature_id');
  
    
sub feature_synonyms { return shift->feature_synonym_feature_id }
      
Bio::Chado::CDBI::Feature->has_many('feature_genotype_feature_id', 'Bio::Chado::CDBI::Feature_Genotype' => 'feature_id');
  
    
sub feature_genotype_feature_ids { my $self = shift; return $self->feature_genotype_feature_id(@_) }
      
Bio::Chado::CDBI::Feature->has_many('feature_genotype_chromosome_id', 'Bio::Chado::CDBI::Feature_Genotype' => 'chromosome_id');
  
    
sub feature_genotype_chromosome_ids { my $self = shift; return $self->feature_genotype_chromosome_id(@_) }
     



#
# Has Compound Many (many to many relationships in all their flavors)
#
 
  
sub element_features { return shift->element_feature_id }

   
 
  
sub element_features { return shift->element_feature_id }

   
 
  
sub element_features { return shift->element_feature_id }

   
 
  
sub feature_phenotype_features { return shift->feature_phenotype_feature_id }

   
 
  
  
sub studyprop_feature_features { return shift->studyprop_feature_feature_id }
 
 
  
sub studyprop_feature_features { return shift->studyprop_feature_feature_id }

   
 
  
  
sub library_feature_features { return shift->library_feature_feature_id }
 
 
  
sub cell_line_feature_features { return shift->cell_line_feature_feature_id }

   
 
  
  
sub cell_line_feature_features { return shift->cell_line_feature_feature_id }
 
 
  
sub feature_pub_features { return shift->feature_pub_feature_id }

   
 
  
sub feature_expression_features { return shift->feature_expression_feature_id }

   
 
  
  
sub feature_expression_features { return shift->feature_expression_feature_id }
 
# one to many to one
 
  
# one2one #
sub cvterms { my $self = shift; return map $_->type_id, $self->element_feature_id }

  

sub dbxrefs { my $self = shift; return map $_->dbxref_id, $self->element_feature_id }

  

sub arraydesigns { my $self = shift; return map $_->arraydesign_id, $self->element_feature_id }

  

sub phenotypes { my $self = shift; return map $_->phenotype_id, $self->feature_phenotype_feature_id }

  

sub studyprops { my $self = shift; return map $_->studyprop_id, $self->studyprop_feature_feature_id }

  

sub cvterms { my $self = shift; return map $_->type_id, $self->studyprop_feature_feature_id }

  

sub librarys { my $self = shift; return map $_->library_id, $self->library_feature_feature_id }

  

sub pubs { my $self = shift; return map $_->pub_id, $self->cell_line_feature_feature_id }

  

sub cell_lines { my $self = shift; return map $_->cell_line_id, $self->cell_line_feature_feature_id }

  

sub pubs { my $self = shift; return map $_->pub_id, $self->feature_pub_feature_id }

  

sub pubs { my $self = shift; return map $_->pub_id, $self->feature_expression_feature_id }

  

sub expressions { my $self = shift; return map $_->expression_id, $self->feature_expression_feature_id }

# one to many to many
 
  
  
  
  
  
  
  
  
  
  
  
  
#many to many to one
 
  
  
  
  
  
  
  
  
  
  
  
  
#many to many to many


  
  
  
  
  
  
  
  
  
  
  
   

1;

########Bio::Chado::CDBI::Feature_Pubprop########

package Bio::Chado::CDBI::Feature_Pubprop;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Feature_Pubprop->set_up_table('feature_pubprop');

#
# Primary key accessors
#

sub id { shift->feature_pubprop_id }
sub feature_pubprop { shift->feature_pubprop_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Feature_Pubprop->has_a(feature_pub_id => 'Bio::Chado::CDBI::Feature_Pub');
    
sub Bio::Chado::CDBI::Feature_Pubprop::feature_pub { return shift->feature_pub_id }
      
 
Bio::Chado::CDBI::Feature_Pubprop->has_a(type_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Feature_Pubprop::cvterm { return shift->type_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Library_Pub########

package Bio::Chado::CDBI::Library_Pub;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Library_Pub->set_up_table('library_pub');

#
# Primary key accessors
#

sub id { shift->library_pub_id }
sub library_pub { shift->library_pub_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Library_Pub->has_a(library_id => 'Bio::Chado::CDBI::Library');
    
sub Bio::Chado::CDBI::Library_Pub::library { return shift->library_id }
      
 
Bio::Chado::CDBI::Library_Pub->has_a(pub_id => 'Bio::Chado::CDBI::Pub');
    
sub Bio::Chado::CDBI::Library_Pub::pub { return shift->pub_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Biomaterialprop########

package Bio::Chado::CDBI::Biomaterialprop;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Biomaterialprop->set_up_table('biomaterialprop');

#
# Primary key accessors
#

sub id { shift->biomaterialprop_id }
sub biomaterialprop { shift->biomaterialprop_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Biomaterialprop->has_a(biomaterial_id => 'Bio::Chado::CDBI::Biomaterial');
    
sub Bio::Chado::CDBI::Biomaterialprop::biomaterial { return shift->biomaterial_id }
      
 
Bio::Chado::CDBI::Biomaterialprop->has_a(type_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Biomaterialprop::cvterm { return shift->type_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Elementresult########

package Bio::Chado::CDBI::Elementresult;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Elementresult->set_up_table('elementresult');

#
# Primary key accessors
#

sub id { shift->elementresult_id }
sub elementresult { shift->elementresult_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Elementresult->has_a(element_id => 'Bio::Chado::CDBI::Element');
    
sub Bio::Chado::CDBI::Elementresult::element { return shift->element_id }
      
 
Bio::Chado::CDBI::Elementresult->has_a(quantification_id => 'Bio::Chado::CDBI::Quantification');
    
sub Bio::Chado::CDBI::Elementresult::quantification { return shift->quantification_id }
      
  
   

#
# Has Many
#
   
Bio::Chado::CDBI::Elementresult->has_many('elementresult_relationship_subject_id', 'Bio::Chado::CDBI::Elementresult_Relationship' => 'subject_id');
  
    
sub elementresult_relationship_subject_ids { my $self = shift; return $self->elementresult_relationship_subject_id(@_) }
      
Bio::Chado::CDBI::Elementresult->has_many('elementresult_relationship_object_id', 'Bio::Chado::CDBI::Elementresult_Relationship' => 'object_id');
  
    
sub elementresult_relationship_object_ids { my $self = shift; return $self->elementresult_relationship_object_id(@_) }
     


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Cell_Line########

package Bio::Chado::CDBI::Cell_Line;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Cell_Line->set_up_table('cell_line');

#
# Primary key accessors
#

sub id { shift->cell_line_id }
sub cell_line { shift->cell_line_id }
 



#
# Has A
#
  
  
  
  
  
 
Bio::Chado::CDBI::Cell_Line->has_a(organism_id => 'Bio::Chado::CDBI::Organism');
    
sub Bio::Chado::CDBI::Cell_Line::organism { return shift->organism_id }
      
  
  
  
   

#
# Has Many
#
 
Bio::Chado::CDBI::Cell_Line->has_many('cell_line_dbxref_cell_line_id', 'Bio::Chado::CDBI::Cell_Line_Dbxref' => 'cell_line_id');
  
    
sub cell_line_dbxrefs { return shift->cell_line_dbxref_cell_line_id }
      
Bio::Chado::CDBI::Cell_Line->has_many('cell_line_feature_cell_line_id', 'Bio::Chado::CDBI::Cell_Line_Feature' => 'cell_line_id');
   
Bio::Chado::CDBI::Cell_Line->has_many('cell_line_relationship_subject_id', 'Bio::Chado::CDBI::Cell_Line_Relationship' => 'subject_id');
   
Bio::Chado::CDBI::Cell_Line->has_many('cell_line_relationship_object_id', 'Bio::Chado::CDBI::Cell_Line_Relationship' => 'object_id');
   
Bio::Chado::CDBI::Cell_Line->has_many('cell_line_synonym_cell_line_id', 'Bio::Chado::CDBI::Cell_Line_Synonym' => 'cell_line_id');
  
    
sub cell_line_synonyms { return shift->cell_line_synonym_cell_line_id }
       
Bio::Chado::CDBI::Cell_Line->has_many('cell_line_library_cell_line_id', 'Bio::Chado::CDBI::Cell_Line_Library' => 'cell_line_id');
   
Bio::Chado::CDBI::Cell_Line->has_many('cell_line_cvterm_cell_line_id', 'Bio::Chado::CDBI::Cell_Line_Cvterm' => 'cell_line_id');
  
    
sub cell_line_cvterms { return shift->cell_line_cvterm_cell_line_id }
      
Bio::Chado::CDBI::Cell_Line->has_many('cell_lineprop_cell_line_id', 'Bio::Chado::CDBI::Cell_Lineprop' => 'cell_line_id');
  
    
sub cell_lineprops { return shift->cell_lineprop_cell_line_id }
      
Bio::Chado::CDBI::Cell_Line->has_many('cell_line_pub_cell_line_id', 'Bio::Chado::CDBI::Cell_Line_Pub' => 'cell_line_id');
  



#
# Has Compound Many (many to many relationships in all their flavors)
#
 
  
sub cell_line_relationship_subjects { return shift->cell_line_relationship_subject_id }

  
sub cell_line_relationship_objects { return shift->cell_line_relationship_object_id }

   
 
  
sub cell_line_feature_cell_lines { return shift->cell_line_feature_cell_line_id }

   
 
  
sub cell_line_feature_cell_lines { return shift->cell_line_feature_cell_line_id }

   
 
  
sub cell_line_library_cell_lines { return shift->cell_line_library_cell_line_id }

   
 
  
sub cell_line_library_cell_lines { return shift->cell_line_library_cell_line_id }

   
 
  
sub cell_line_pub_cell_lines { return shift->cell_line_pub_cell_line_id }

   
# one to many to one
 
  
  
# one2one #
sub pubs { my $self = shift; return map $_->pub_id, $self->cell_line_feature_cell_line_id }

  

sub features { my $self = shift; return map $_->feature_id, $self->cell_line_feature_cell_line_id }

  

sub librarys { my $self = shift; return map $_->library_id, $self->cell_line_library_cell_line_id }

  

sub pubs { my $self = shift; return map $_->pub_id, $self->cell_line_library_cell_line_id }

  

sub pubs { my $self = shift; return map $_->pub_id, $self->cell_line_pub_cell_line_id }

# one to many to many
 
  
  
  
  
  
  
#many to many to one
 
  
# many2one #
  
  
sub cell_line_relationship_subject_types { my $self = shift; return map $_->type_id, $self->cell_line_relationship_subject_id }
    
  
sub cell_line_relationship_object_types { my $self = shift; return map $_->type_id, $self->cell_line_relationship_object_id }
    
   
  
  
  
  
  
#many to many to many


  
  
  
  
  
   

1;

########Bio::Chado::CDBI::Library_Feature########

package Bio::Chado::CDBI::Library_Feature;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Library_Feature->set_up_table('library_feature');

#
# Primary key accessors
#

sub id { shift->library_feature_id }
sub library_feature { shift->library_feature_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Library_Feature->has_a(library_id => 'Bio::Chado::CDBI::Library');
    
sub Bio::Chado::CDBI::Library_Feature::library { return shift->library_id }
      
 
Bio::Chado::CDBI::Library_Feature->has_a(feature_id => 'Bio::Chado::CDBI::Feature');
    
sub Bio::Chado::CDBI::Library_Feature::feature { return shift->feature_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Stock_Dbxref########

package Bio::Chado::CDBI::Stock_Dbxref;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Stock_Dbxref->set_up_table('stock_dbxref');

#
# Primary key accessors
#

sub id { shift->stock_dbxref_id }
sub stock_dbxref { shift->stock_dbxref_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Stock_Dbxref->has_a(stock_id => 'Bio::Chado::CDBI::Stock');
    
sub Bio::Chado::CDBI::Stock_Dbxref::stock { return shift->stock_id }
      
 
Bio::Chado::CDBI::Stock_Dbxref->has_a(dbxref_id => 'Bio::Chado::CDBI::Dbxref');
    
sub Bio::Chado::CDBI::Stock_Dbxref::dbxref { return shift->dbxref_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Cvterm_Dbxref########

package Bio::Chado::CDBI::Cvterm_Dbxref;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Cvterm_Dbxref->set_up_table('cvterm_dbxref');

#
# Primary key accessors
#

sub id { shift->cvterm_dbxref_id }
sub cvterm_dbxref { shift->cvterm_dbxref_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Cvterm_Dbxref->has_a(cvterm_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Cvterm_Dbxref::cvterm { return shift->cvterm_id }
      
 
Bio::Chado::CDBI::Cvterm_Dbxref->has_a(dbxref_id => 'Bio::Chado::CDBI::Dbxref');
    
sub Bio::Chado::CDBI::Cvterm_Dbxref::dbxref { return shift->dbxref_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Feature_Relationshipprop########

package Bio::Chado::CDBI::Feature_Relationshipprop;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Feature_Relationshipprop->set_up_table('feature_relationshipprop');

#
# Primary key accessors
#

sub id { shift->feature_relationshipprop_id }
sub feature_relationshipprop { shift->feature_relationshipprop_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Feature_Relationshipprop->has_a(feature_relationship_id => 'Bio::Chado::CDBI::Feature_Relationship');
    
sub Bio::Chado::CDBI::Feature_Relationshipprop::feature_relationship { return shift->feature_relationship_id }
      
 
Bio::Chado::CDBI::Feature_Relationshipprop->has_a(type_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Feature_Relationshipprop::cvterm { return shift->type_id }
      
   

#
# Has Many
#
   
Bio::Chado::CDBI::Feature_Relationshipprop->has_many('feature_relationshipprop_pub_feature_relationshipprop_id', 'Bio::Chado::CDBI::Feature_Relationshipprop_Pub' => 'feature_relationshipprop_id');
  



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

########Bio::Chado::CDBI::Stockcollectionprop########

package Bio::Chado::CDBI::Stockcollectionprop;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Stockcollectionprop->set_up_table('stockcollectionprop');

#
# Primary key accessors
#

sub id { shift->stockcollectionprop_id }
sub stockcollectionprop { shift->stockcollectionprop_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Stockcollectionprop->has_a(stockcollection_id => 'Bio::Chado::CDBI::Stockcollection');
    
sub Bio::Chado::CDBI::Stockcollectionprop::stockcollection { return shift->stockcollection_id }
      
 
Bio::Chado::CDBI::Stockcollectionprop->has_a(type_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Stockcollectionprop::cvterm { return shift->type_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Element_Relationship########

package Bio::Chado::CDBI::Element_Relationship;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Element_Relationship->set_up_table('element_relationship');

#
# Primary key accessors
#

sub id { shift->element_relationship_id }
sub element_relationship { shift->element_relationship_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Element_Relationship->has_a(subject_id => 'Bio::Chado::CDBI::Element');
    
sub subject { return shift->subject_id }
      
 
Bio::Chado::CDBI::Element_Relationship->has_a(type_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Element_Relationship::cvterm { return shift->type_id }
      
 
Bio::Chado::CDBI::Element_Relationship->has_a(object_id => 'Bio::Chado::CDBI::Element');
    
sub object { return shift->object_id }
       

#
# Has Many
#
   


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Stock########

package Bio::Chado::CDBI::Stock;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Stock->set_up_table('stock');

#
# Primary key accessors
#

sub id { shift->stock_id }
sub stock { shift->stock_id }
 



#
# Has A
#
  
 
Bio::Chado::CDBI::Stock->has_a(dbxref_id => 'Bio::Chado::CDBI::Dbxref');
    
sub Bio::Chado::CDBI::Stock::dbxref { return shift->dbxref_id }
      
 
Bio::Chado::CDBI::Stock->has_a(organism_id => 'Bio::Chado::CDBI::Organism');
    
sub Bio::Chado::CDBI::Stock::organism { return shift->organism_id }
      
 
Bio::Chado::CDBI::Stock->has_a(type_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Stock::cvterm { return shift->type_id }
      
  
  
  
  
  
  
   

#
# Has Many
#
 
Bio::Chado::CDBI::Stock->has_many('stock_dbxref_stock_id', 'Bio::Chado::CDBI::Stock_Dbxref' => 'stock_id');
  
    
sub stock_dbxrefs { return shift->stock_dbxref_stock_id }
         
Bio::Chado::CDBI::Stock->has_many('stock_pub_stock_id', 'Bio::Chado::CDBI::Stock_Pub' => 'stock_id');
   
Bio::Chado::CDBI::Stock->has_many('stock_genotype_stock_id', 'Bio::Chado::CDBI::Stock_Genotype' => 'stock_id');
   
Bio::Chado::CDBI::Stock->has_many('stock_cvterm_stock_id', 'Bio::Chado::CDBI::Stock_Cvterm' => 'stock_id');
   
Bio::Chado::CDBI::Stock->has_many('stock_relationship_subject_id', 'Bio::Chado::CDBI::Stock_Relationship' => 'subject_id');
  
    
sub stock_relationship_subject_ids { my $self = shift; return $self->stock_relationship_subject_id(@_) }
      
Bio::Chado::CDBI::Stock->has_many('stock_relationship_object_id', 'Bio::Chado::CDBI::Stock_Relationship' => 'object_id');
  
    
sub stock_relationship_object_ids { my $self = shift; return $self->stock_relationship_object_id(@_) }
      
Bio::Chado::CDBI::Stock->has_many('stockcollection_stock_stock_id', 'Bio::Chado::CDBI::Stockcollection_Stock' => 'stock_id');
   
Bio::Chado::CDBI::Stock->has_many('stockprop_stock_id', 'Bio::Chado::CDBI::Stockprop' => 'stock_id');
  
    
sub stockprops { return shift->stockprop_stock_id }
     



#
# Has Compound Many (many to many relationships in all their flavors)
#
 
  
sub stock_genotype_stocks { return shift->stock_genotype_stock_id }

   
 
  
sub stock_cvterm_stocks { return shift->stock_cvterm_stock_id }

   
 
  
sub stock_cvterm_stocks { return shift->stock_cvterm_stock_id }

   
 
  
  
sub stockcollection_stock_stocks { return shift->stockcollection_stock_stock_id }
 
 
  
sub stock_pub_stocks { return shift->stock_pub_stock_id }

   
# one to many to one
 
  
# one2one #
sub genotypes { my $self = shift; return map $_->genotype_id, $self->stock_genotype_stock_id }

  

sub cvterms { my $self = shift; return map $_->cvterm_id, $self->stock_cvterm_stock_id }

  

sub pubs { my $self = shift; return map $_->pub_id, $self->stock_cvterm_stock_id }

  

sub stockcollections { my $self = shift; return map $_->stockcollection_id, $self->stockcollection_stock_stock_id }

  

sub pubs { my $self = shift; return map $_->pub_id, $self->stock_pub_stock_id }

# one to many to many
 
  
  
  
  
  
#many to many to one
 
  
  
  
  
  
#many to many to many


  
  
  
  
   

1;

########Bio::Chado::CDBI::Featuremap########

package Bio::Chado::CDBI::Featuremap;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Featuremap->set_up_table('featuremap');

#
# Primary key accessors
#

sub id { shift->featuremap_id }
sub featuremap { shift->featuremap_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Featuremap->has_a(unittype_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Featuremap::cvterm { return shift->unittype_id }
      
  
  
   

#
# Has Many
#
  
Bio::Chado::CDBI::Featuremap->has_many('featurerange_featuremap_id', 'Bio::Chado::CDBI::Featurerange' => 'featuremap_id');
  
    
sub featureranges { return shift->featurerange_featuremap_id }
      
Bio::Chado::CDBI::Featuremap->has_many('featurepos_featuremap_id', 'Bio::Chado::CDBI::Featurepos' => 'featuremap_id');
  
    
sub featureposs { return shift->featurepos_featuremap_id }
      
Bio::Chado::CDBI::Featuremap->has_many('featuremap_pub_featuremap_id', 'Bio::Chado::CDBI::Featuremap_Pub' => 'featuremap_id');
  



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

########Bio::Chado::CDBI::Studyprop_Feature########

package Bio::Chado::CDBI::Studyprop_Feature;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Studyprop_Feature->set_up_table('studyprop_feature');

#
# Primary key accessors
#

sub id { shift->studyprop_feature_id }
sub studyprop_feature { shift->studyprop_feature_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Studyprop_Feature->has_a(studyprop_id => 'Bio::Chado::CDBI::Studyprop');
    
sub Bio::Chado::CDBI::Studyprop_Feature::studyprop { return shift->studyprop_id }
      
 
Bio::Chado::CDBI::Studyprop_Feature->has_a(feature_id => 'Bio::Chado::CDBI::Feature');
    
sub Bio::Chado::CDBI::Studyprop_Feature::feature { return shift->feature_id }
      
 
Bio::Chado::CDBI::Studyprop_Feature->has_a(type_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Studyprop_Feature::cvterm { return shift->type_id }
       

#
# Has Many
#
   


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Libraryprop########

package Bio::Chado::CDBI::Libraryprop;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Libraryprop->set_up_table('libraryprop');

#
# Primary key accessors
#

sub id { shift->libraryprop_id }
sub libraryprop { shift->libraryprop_id }
 



#
# Has A
#
  
 
Bio::Chado::CDBI::Libraryprop->has_a(library_id => 'Bio::Chado::CDBI::Library');
    
sub Bio::Chado::CDBI::Libraryprop::library { return shift->library_id }
      
 
Bio::Chado::CDBI::Libraryprop->has_a(type_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Libraryprop::cvterm { return shift->type_id }
       

#
# Has Many
#
 
Bio::Chado::CDBI::Libraryprop->has_many('libraryprop_pub_libraryprop_id', 'Bio::Chado::CDBI::Libraryprop_Pub' => 'libraryprop_id');
    



#
# Has Compound Many (many to many relationships in all their flavors)
#
 
  
sub libraryprop_pub_libraryprops { return shift->libraryprop_pub_libraryprop_id }

   
# one to many to one
 
  
# one2one #
sub pubs { my $self = shift; return map $_->pub_id, $self->libraryprop_pub_libraryprop_id }

# one to many to many
 
  
#many to many to one
 
  
#many to many to many


   

1;

########Bio::Chado::CDBI::Analysisfeatureprop########

package Bio::Chado::CDBI::Analysisfeatureprop;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Analysisfeatureprop->set_up_table('analysisfeatureprop');

#
# Primary key accessors
#

sub id { shift->analysisfeatureprop_id }
sub analysisfeatureprop { shift->analysisfeatureprop_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Analysisfeatureprop->has_a(analysisfeature_id => 'Bio::Chado::CDBI::Analysisfeature');
    
sub Bio::Chado::CDBI::Analysisfeatureprop::analysisfeature { return shift->analysisfeature_id }
      
 
Bio::Chado::CDBI::Analysisfeatureprop->has_a(type_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Analysisfeatureprop::cvterm { return shift->type_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Project########

package Bio::Chado::CDBI::Project;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Project->set_up_table('project');

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
 
Bio::Chado::CDBI::Project->has_many('assay_project_project_id', 'Bio::Chado::CDBI::Assay_Project' => 'project_id');
  



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

########Bio::Chado::CDBI::Featureprop########

package Bio::Chado::CDBI::Featureprop;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Featureprop->set_up_table('featureprop');

#
# Primary key accessors
#

sub id { shift->featureprop_id }
sub featureprop { shift->featureprop_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Featureprop->has_a(feature_id => 'Bio::Chado::CDBI::Feature');
    
sub Bio::Chado::CDBI::Featureprop::feature { return shift->feature_id }
      
 
Bio::Chado::CDBI::Featureprop->has_a(type_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Featureprop::cvterm { return shift->type_id }
      
   

#
# Has Many
#
   
Bio::Chado::CDBI::Featureprop->has_many('featureprop_pub_featureprop_id', 'Bio::Chado::CDBI::Featureprop_Pub' => 'featureprop_id');
  



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

########Bio::Chado::CDBI::Cell_Line_Library########

package Bio::Chado::CDBI::Cell_Line_Library;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Cell_Line_Library->set_up_table('cell_line_library');

#
# Primary key accessors
#

sub id { shift->cell_line_library_id }
sub cell_line_library { shift->cell_line_library_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Cell_Line_Library->has_a(cell_line_id => 'Bio::Chado::CDBI::Cell_Line');
    
sub Bio::Chado::CDBI::Cell_Line_Library::cell_line { return shift->cell_line_id }
      
 
Bio::Chado::CDBI::Cell_Line_Library->has_a(library_id => 'Bio::Chado::CDBI::Library');
    
sub Bio::Chado::CDBI::Cell_Line_Library::library { return shift->library_id }
      
 
Bio::Chado::CDBI::Cell_Line_Library->has_a(pub_id => 'Bio::Chado::CDBI::Pub');
    
sub Bio::Chado::CDBI::Cell_Line_Library::pub { return shift->pub_id }
       

#
# Has Many
#
   


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Phylonode_Relationship########

package Bio::Chado::CDBI::Phylonode_Relationship;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Phylonode_Relationship->set_up_table('phylonode_relationship');

#
# Primary key accessors
#

sub id { shift->phylonode_relationship_id }
sub phylonode_relationship { shift->phylonode_relationship_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Phylonode_Relationship->has_a(subject_id => 'Bio::Chado::CDBI::Phylonode');
    
sub subject { return shift->subject_id }
      
 
Bio::Chado::CDBI::Phylonode_Relationship->has_a(object_id => 'Bio::Chado::CDBI::Phylonode');
    
sub object { return shift->object_id }
      
 
Bio::Chado::CDBI::Phylonode_Relationship->has_a(type_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Phylonode_Relationship::cvterm { return shift->type_id }
      
 
Bio::Chado::CDBI::Phylonode_Relationship->has_a(phylotree_id => 'Bio::Chado::CDBI::Phylotree');
    
sub Bio::Chado::CDBI::Phylonode_Relationship::phylotree { return shift->phylotree_id }
       

#
# Has Many
#
    


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Stock_Pub########

package Bio::Chado::CDBI::Stock_Pub;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Stock_Pub->set_up_table('stock_pub');

#
# Primary key accessors
#

sub id { shift->stock_pub_id }
sub stock_pub { shift->stock_pub_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Stock_Pub->has_a(stock_id => 'Bio::Chado::CDBI::Stock');
    
sub Bio::Chado::CDBI::Stock_Pub::stock { return shift->stock_id }
      
 
Bio::Chado::CDBI::Stock_Pub->has_a(pub_id => 'Bio::Chado::CDBI::Pub');
    
sub Bio::Chado::CDBI::Stock_Pub::pub { return shift->pub_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Stock_Genotype########

package Bio::Chado::CDBI::Stock_Genotype;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Stock_Genotype->set_up_table('stock_genotype');

#
# Primary key accessors
#

sub id { shift->stock_genotype_id }
sub stock_genotype { shift->stock_genotype_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Stock_Genotype->has_a(stock_id => 'Bio::Chado::CDBI::Stock');
    
sub Bio::Chado::CDBI::Stock_Genotype::stock { return shift->stock_id }
      
 
Bio::Chado::CDBI::Stock_Genotype->has_a(genotype_id => 'Bio::Chado::CDBI::Genotype');
    
sub Bio::Chado::CDBI::Stock_Genotype::genotype { return shift->genotype_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Protocolparam########

package Bio::Chado::CDBI::Protocolparam;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Protocolparam->set_up_table('protocolparam');

#
# Primary key accessors
#

sub id { shift->protocolparam_id }
sub protocolparam { shift->protocolparam_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Protocolparam->has_a(protocol_id => 'Bio::Chado::CDBI::Protocol');
    
sub Bio::Chado::CDBI::Protocolparam::protocol { return shift->protocol_id }
      
 
Bio::Chado::CDBI::Protocolparam->has_a(datatype_id => 'Bio::Chado::CDBI::Cvterm');
    
sub datatype { return shift->datatype_id }
      
 
Bio::Chado::CDBI::Protocolparam->has_a(unittype_id => 'Bio::Chado::CDBI::Cvterm');
    
sub unittype { return shift->unittype_id }
       

#
# Has Many
#
   


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Control########

package Bio::Chado::CDBI::Control;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Control->set_up_table('control');

#
# Primary key accessors
#

sub id { shift->control_id }
sub control { shift->control_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Control->has_a(type_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Control::cvterm { return shift->type_id }
      
 
Bio::Chado::CDBI::Control->has_a(assay_id => 'Bio::Chado::CDBI::Assay');
    
sub Bio::Chado::CDBI::Control::assay { return shift->assay_id }
      
 
Bio::Chado::CDBI::Control->has_a(tableinfo_id => 'Bio::Chado::CDBI::Tableinfo');
    
sub Bio::Chado::CDBI::Control::tableinfo { return shift->tableinfo_id }
       

#
# Has Many
#
   


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Feature_Relationshipprop_Pub########

package Bio::Chado::CDBI::Feature_Relationshipprop_Pub;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Feature_Relationshipprop_Pub->set_up_table('feature_relationshipprop_pub');

#
# Primary key accessors
#

sub id { shift->feature_relationshipprop_pub_id }
sub feature_relationshipprop_pub { shift->feature_relationshipprop_pub_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Feature_Relationshipprop_Pub->has_a(feature_relationshipprop_id => 'Bio::Chado::CDBI::Feature_Relationshipprop');
    
sub Bio::Chado::CDBI::Feature_Relationshipprop_Pub::feature_relationshipprop { return shift->feature_relationshipprop_id }
      
 
Bio::Chado::CDBI::Feature_Relationshipprop_Pub->has_a(pub_id => 'Bio::Chado::CDBI::Pub');
    
sub Bio::Chado::CDBI::Feature_Relationshipprop_Pub::pub { return shift->pub_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Biomaterial########

package Bio::Chado::CDBI::Biomaterial;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Biomaterial->set_up_table('biomaterial');

#
# Primary key accessors
#

sub id { shift->biomaterial_id }
sub biomaterial { shift->biomaterial_id }
 



#
# Has A
#
  
  
  
  
 
Bio::Chado::CDBI::Biomaterial->has_a(taxon_id => 'Bio::Chado::CDBI::Organism');
    
sub Bio::Chado::CDBI::Biomaterial::organism { return shift->taxon_id }
      
 
Bio::Chado::CDBI::Biomaterial->has_a(biosourceprovider_id => 'Bio::Chado::CDBI::Contact');
    
sub Bio::Chado::CDBI::Biomaterial::contact { return shift->biosourceprovider_id }
      
 
Bio::Chado::CDBI::Biomaterial->has_a(dbxref_id => 'Bio::Chado::CDBI::Dbxref');
    
sub Bio::Chado::CDBI::Biomaterial::dbxref { return shift->dbxref_id }
      
  
  
   

#
# Has Many
#
 
Bio::Chado::CDBI::Biomaterial->has_many('biomaterial_relationship_subject_id', 'Bio::Chado::CDBI::Biomaterial_Relationship' => 'subject_id');
   
Bio::Chado::CDBI::Biomaterial->has_many('biomaterial_relationship_object_id', 'Bio::Chado::CDBI::Biomaterial_Relationship' => 'object_id');
   
Bio::Chado::CDBI::Biomaterial->has_many('biomaterial_dbxref_biomaterial_id', 'Bio::Chado::CDBI::Biomaterial_Dbxref' => 'biomaterial_id');
   
Bio::Chado::CDBI::Biomaterial->has_many('biomaterialprop_biomaterial_id', 'Bio::Chado::CDBI::Biomaterialprop' => 'biomaterial_id');
  
    
sub biomaterialprops { return shift->biomaterialprop_biomaterial_id }
         
Bio::Chado::CDBI::Biomaterial->has_many('biomaterial_treatment_biomaterial_id', 'Bio::Chado::CDBI::Biomaterial_Treatment' => 'biomaterial_id');
  
    
sub biomaterial_treatments { return shift->biomaterial_treatment_biomaterial_id }
      
Bio::Chado::CDBI::Biomaterial->has_many('assay_biomaterial_biomaterial_id', 'Bio::Chado::CDBI::Assay_Biomaterial' => 'biomaterial_id');
  
    
sub assay_biomaterials { return shift->assay_biomaterial_biomaterial_id }
      
Bio::Chado::CDBI::Biomaterial->has_many('treatment_biomaterial_id', 'Bio::Chado::CDBI::Treatment' => 'biomaterial_id');
  
    
sub treatments { return shift->treatment_biomaterial_id }
     



#
# Has Compound Many (many to many relationships in all their flavors)
#
 
  
sub biomaterial_dbxref_biomaterials { return shift->biomaterial_dbxref_biomaterial_id }

   
 
  
sub biomaterial_relationship_subjects { return shift->biomaterial_relationship_subject_id }

  
  
sub biomaterial_relationship_objects { return shift->biomaterial_relationship_object_id }
 
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

########Bio::Chado::CDBI::Pub_Dbxref########

package Bio::Chado::CDBI::Pub_Dbxref;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Pub_Dbxref->set_up_table('pub_dbxref');

#
# Primary key accessors
#

sub id { shift->pub_dbxref_id }
sub pub_dbxref { shift->pub_dbxref_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Pub_Dbxref->has_a(pub_id => 'Bio::Chado::CDBI::Pub');
    
sub Bio::Chado::CDBI::Pub_Dbxref::pub { return shift->pub_id }
      
 
Bio::Chado::CDBI::Pub_Dbxref->has_a(dbxref_id => 'Bio::Chado::CDBI::Dbxref');
    
sub Bio::Chado::CDBI::Pub_Dbxref::dbxref { return shift->dbxref_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Phendesc########

package Bio::Chado::CDBI::Phendesc;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Phendesc->set_up_table('phendesc');

#
# Primary key accessors
#

sub id { shift->phendesc_id }
sub phendesc { shift->phendesc_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Phendesc->has_a(genotype_id => 'Bio::Chado::CDBI::Genotype');
    
sub Bio::Chado::CDBI::Phendesc::genotype { return shift->genotype_id }
      
 
Bio::Chado::CDBI::Phendesc->has_a(environment_id => 'Bio::Chado::CDBI::Environment');
    
sub Bio::Chado::CDBI::Phendesc::environment { return shift->environment_id }
      
 
Bio::Chado::CDBI::Phendesc->has_a(type_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Phendesc::cvterm { return shift->type_id }
      
 
Bio::Chado::CDBI::Phendesc->has_a(pub_id => 'Bio::Chado::CDBI::Pub');
    
sub Bio::Chado::CDBI::Phendesc::pub { return shift->pub_id }
       

#
# Has Many
#
    


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Featureprop_Pub########

package Bio::Chado::CDBI::Featureprop_Pub;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Featureprop_Pub->set_up_table('featureprop_pub');

#
# Primary key accessors
#

sub id { shift->featureprop_pub_id }
sub featureprop_pub { shift->featureprop_pub_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Featureprop_Pub->has_a(featureprop_id => 'Bio::Chado::CDBI::Featureprop');
    
sub Bio::Chado::CDBI::Featureprop_Pub::featureprop { return shift->featureprop_id }
      
 
Bio::Chado::CDBI::Featureprop_Pub->has_a(pub_id => 'Bio::Chado::CDBI::Pub');
    
sub Bio::Chado::CDBI::Featureprop_Pub::pub { return shift->pub_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Library_Synonym########

package Bio::Chado::CDBI::Library_Synonym;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Library_Synonym->set_up_table('library_synonym');

#
# Primary key accessors
#

sub id { shift->library_synonym_id }
sub library_synonym { shift->library_synonym_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Library_Synonym->has_a(synonym_id => 'Bio::Chado::CDBI::Synonym');
    
sub Bio::Chado::CDBI::Library_Synonym::synonym { return shift->synonym_id }
      
 
Bio::Chado::CDBI::Library_Synonym->has_a(library_id => 'Bio::Chado::CDBI::Library');
    
sub Bio::Chado::CDBI::Library_Synonym::library { return shift->library_id }
      
 
Bio::Chado::CDBI::Library_Synonym->has_a(pub_id => 'Bio::Chado::CDBI::Pub');
    
sub Bio::Chado::CDBI::Library_Synonym::pub { return shift->pub_id }
       

#
# Has Many
#
   


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Feature_Expressionprop########

package Bio::Chado::CDBI::Feature_Expressionprop;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Feature_Expressionprop->set_up_table('feature_expressionprop');

#
# Primary key accessors
#

sub id { shift->feature_expressionprop_id }
sub feature_expressionprop { shift->feature_expressionprop_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Feature_Expressionprop->has_a(feature_expression_id => 'Bio::Chado::CDBI::Feature_Expression');
    
sub Bio::Chado::CDBI::Feature_Expressionprop::feature_expression { return shift->feature_expression_id }
      
 
Bio::Chado::CDBI::Feature_Expressionprop->has_a(type_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Feature_Expressionprop::cvterm { return shift->type_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Pub_Relationship########

package Bio::Chado::CDBI::Pub_Relationship;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Pub_Relationship->set_up_table('pub_relationship');

#
# Primary key accessors
#

sub id { shift->pub_relationship_id }
sub pub_relationship { shift->pub_relationship_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Pub_Relationship->has_a(subject_id => 'Bio::Chado::CDBI::Pub');
    
sub subject { return shift->subject_id }
      
 
Bio::Chado::CDBI::Pub_Relationship->has_a(object_id => 'Bio::Chado::CDBI::Pub');
    
sub object { return shift->object_id }
      
 
Bio::Chado::CDBI::Pub_Relationship->has_a(type_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Pub_Relationship::cvterm { return shift->type_id }
       

#
# Has Many
#
   


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Expression_Pub########

package Bio::Chado::CDBI::Expression_Pub;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Expression_Pub->set_up_table('expression_pub');

#
# Primary key accessors
#

sub id { shift->expression_pub_id }
sub expression_pub { shift->expression_pub_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Expression_Pub->has_a(expression_id => 'Bio::Chado::CDBI::Expression');
    
sub Bio::Chado::CDBI::Expression_Pub::expression { return shift->expression_id }
      
 
Bio::Chado::CDBI::Expression_Pub->has_a(pub_id => 'Bio::Chado::CDBI::Pub');
    
sub Bio::Chado::CDBI::Expression_Pub::pub { return shift->pub_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Db########

package Bio::Chado::CDBI::Db;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Db->set_up_table('db');

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
 
Bio::Chado::CDBI::Db->has_many('dbxref_db_id', 'Bio::Chado::CDBI::Dbxref' => 'db_id');
  
    
sub dbxrefs { return shift->dbxref_db_id }
     


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Assay########

package Bio::Chado::CDBI::Assay;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Assay->set_up_table('assay');

#
# Primary key accessors
#

sub id { shift->assay_id }
sub assay { shift->assay_id }
 



#
# Has A
#
  
  
  
 
Bio::Chado::CDBI::Assay->has_a(arraydesign_id => 'Bio::Chado::CDBI::Arraydesign');
    
sub Bio::Chado::CDBI::Assay::arraydesign { return shift->arraydesign_id }
      
 
Bio::Chado::CDBI::Assay->has_a(protocol_id => 'Bio::Chado::CDBI::Protocol');
    
sub Bio::Chado::CDBI::Assay::protocol { return shift->protocol_id }
      
 
Bio::Chado::CDBI::Assay->has_a(operator_id => 'Bio::Chado::CDBI::Contact');
    
sub Bio::Chado::CDBI::Assay::contact { return shift->operator_id }
      
 
Bio::Chado::CDBI::Assay->has_a(dbxref_id => 'Bio::Chado::CDBI::Dbxref');
    
sub Bio::Chado::CDBI::Assay::dbxref { return shift->dbxref_id }
      
  
  
  
   

#
# Has Many
#
 
Bio::Chado::CDBI::Assay->has_many('study_assay_assay_id', 'Bio::Chado::CDBI::Study_Assay' => 'assay_id');
   
Bio::Chado::CDBI::Assay->has_many('assayprop_assay_id', 'Bio::Chado::CDBI::Assayprop' => 'assay_id');
  
    
sub assayprops { return shift->assayprop_assay_id }
      
Bio::Chado::CDBI::Assay->has_many('control_assay_id', 'Bio::Chado::CDBI::Control' => 'assay_id');
  
    
sub controls { return shift->control_assay_id }
          
Bio::Chado::CDBI::Assay->has_many('assay_biomaterial_assay_id', 'Bio::Chado::CDBI::Assay_Biomaterial' => 'assay_id');
  
    
sub assay_biomaterials { return shift->assay_biomaterial_assay_id }
      
Bio::Chado::CDBI::Assay->has_many('acquisition_assay_id', 'Bio::Chado::CDBI::Acquisition' => 'assay_id');
  
    
sub acquisitions { return shift->acquisition_assay_id }
      
Bio::Chado::CDBI::Assay->has_many('studyfactorvalue_assay_id', 'Bio::Chado::CDBI::Studyfactorvalue' => 'assay_id');
  
    
sub studyfactorvalues { return shift->studyfactorvalue_assay_id }
      
Bio::Chado::CDBI::Assay->has_many('assay_project_assay_id', 'Bio::Chado::CDBI::Assay_Project' => 'assay_id');
  



#
# Has Compound Many (many to many relationships in all their flavors)
#
 
  
  
sub study_assay_assays { return shift->study_assay_assay_id }
 
 
  
sub assay_project_assays { return shift->assay_project_assay_id }

   
# one to many to one
 
  
# one2one #
sub studys { my $self = shift; return map $_->study_id, $self->study_assay_assay_id }

  

sub projects { my $self = shift; return map $_->project_id, $self->assay_project_assay_id }

# one to many to many
 
  
  
#many to many to one
 
  
  
#many to many to many


  
   

1;

########Bio::Chado::CDBI::Studyfactor########

package Bio::Chado::CDBI::Studyfactor;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Studyfactor->set_up_table('studyfactor');

#
# Primary key accessors
#

sub id { shift->studyfactor_id }
sub studyfactor { shift->studyfactor_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Studyfactor->has_a(studydesign_id => 'Bio::Chado::CDBI::Studydesign');
    
sub Bio::Chado::CDBI::Studyfactor::studydesign { return shift->studydesign_id }
      
 
Bio::Chado::CDBI::Studyfactor->has_a(type_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Studyfactor::cvterm { return shift->type_id }
      
   

#
# Has Many
#
   
Bio::Chado::CDBI::Studyfactor->has_many('studyfactorvalue_studyfactor_id', 'Bio::Chado::CDBI::Studyfactorvalue' => 'studyfactor_id');
  
    
sub studyfactorvalues { return shift->studyfactorvalue_studyfactor_id }
     


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Organism_Dbxref########

package Bio::Chado::CDBI::Organism_Dbxref;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Organism_Dbxref->set_up_table('organism_dbxref');

#
# Primary key accessors
#

sub id { shift->organism_dbxref_id }
sub organism_dbxref { shift->organism_dbxref_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Organism_Dbxref->has_a(organism_id => 'Bio::Chado::CDBI::Organism');
    
sub Bio::Chado::CDBI::Organism_Dbxref::organism { return shift->organism_id }
      
 
Bio::Chado::CDBI::Organism_Dbxref->has_a(dbxref_id => 'Bio::Chado::CDBI::Dbxref');
    
sub Bio::Chado::CDBI::Organism_Dbxref::dbxref { return shift->dbxref_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Phylonodeprop########

package Bio::Chado::CDBI::Phylonodeprop;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Phylonodeprop->set_up_table('phylonodeprop');

#
# Primary key accessors
#

sub id { shift->phylonodeprop_id }
sub phylonodeprop { shift->phylonodeprop_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Phylonodeprop->has_a(phylonode_id => 'Bio::Chado::CDBI::Phylonode');
    
sub Bio::Chado::CDBI::Phylonodeprop::phylonode { return shift->phylonode_id }
      
 
Bio::Chado::CDBI::Phylonodeprop->has_a(type_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Phylonodeprop::cvterm { return shift->type_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Study########

package Bio::Chado::CDBI::Study;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Study->set_up_table('study');

#
# Primary key accessors
#

sub id { shift->study_id }
sub study { shift->study_id }
 



#
# Has A
#
  
 
Bio::Chado::CDBI::Study->has_a(contact_id => 'Bio::Chado::CDBI::Contact');
    
sub Bio::Chado::CDBI::Study::contact { return shift->contact_id }
      
 
Bio::Chado::CDBI::Study->has_a(pub_id => 'Bio::Chado::CDBI::Pub');
    
sub Bio::Chado::CDBI::Study::pub { return shift->pub_id }
      
 
Bio::Chado::CDBI::Study->has_a(dbxref_id => 'Bio::Chado::CDBI::Dbxref');
    
sub Bio::Chado::CDBI::Study::dbxref { return shift->dbxref_id }
      
  
   

#
# Has Many
#
 
Bio::Chado::CDBI::Study->has_many('study_assay_study_id', 'Bio::Chado::CDBI::Study_Assay' => 'study_id');
      
Bio::Chado::CDBI::Study->has_many('studyprop_study_id', 'Bio::Chado::CDBI::Studyprop' => 'study_id');
  
    
sub studyprops { return shift->studyprop_study_id }
      
Bio::Chado::CDBI::Study->has_many('studydesign_study_id', 'Bio::Chado::CDBI::Studydesign' => 'study_id');
  
    
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

########Bio::Chado::CDBI::Expression_Image########

package Bio::Chado::CDBI::Expression_Image;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Expression_Image->set_up_table('expression_image');

#
# Primary key accessors
#

sub id { shift->expression_image_id }
sub expression_image { shift->expression_image_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Expression_Image->has_a(expression_id => 'Bio::Chado::CDBI::Expression');
    
sub Bio::Chado::CDBI::Expression_Image::expression { return shift->expression_id }
      
 
Bio::Chado::CDBI::Expression_Image->has_a(eimage_id => 'Bio::Chado::CDBI::Eimage');
    
sub Bio::Chado::CDBI::Expression_Image::eimage { return shift->eimage_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Stock_Cvterm########

package Bio::Chado::CDBI::Stock_Cvterm;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Stock_Cvterm->set_up_table('stock_cvterm');

#
# Primary key accessors
#

sub id { shift->stock_cvterm_id }
sub stock_cvterm { shift->stock_cvterm_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Stock_Cvterm->has_a(stock_id => 'Bio::Chado::CDBI::Stock');
    
sub Bio::Chado::CDBI::Stock_Cvterm::stock { return shift->stock_id }
      
 
Bio::Chado::CDBI::Stock_Cvterm->has_a(cvterm_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Stock_Cvterm::cvterm { return shift->cvterm_id }
      
 
Bio::Chado::CDBI::Stock_Cvterm->has_a(pub_id => 'Bio::Chado::CDBI::Pub');
    
sub Bio::Chado::CDBI::Stock_Cvterm::pub { return shift->pub_id }
       

#
# Has Many
#
   


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Cell_Line_Cvterm########

package Bio::Chado::CDBI::Cell_Line_Cvterm;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Cell_Line_Cvterm->set_up_table('cell_line_cvterm');

#
# Primary key accessors
#

sub id { shift->cell_line_cvterm_id }
sub cell_line_cvterm { shift->cell_line_cvterm_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Cell_Line_Cvterm->has_a(cell_line_id => 'Bio::Chado::CDBI::Cell_Line');
    
sub Bio::Chado::CDBI::Cell_Line_Cvterm::cell_line { return shift->cell_line_id }
      
 
Bio::Chado::CDBI::Cell_Line_Cvterm->has_a(cvterm_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Cell_Line_Cvterm::cvterm { return shift->cvterm_id }
      
 
Bio::Chado::CDBI::Cell_Line_Cvterm->has_a(pub_id => 'Bio::Chado::CDBI::Pub');
    
sub Bio::Chado::CDBI::Cell_Line_Cvterm::pub { return shift->pub_id }
      
   

#
# Has Many
#
    
Bio::Chado::CDBI::Cell_Line_Cvterm->has_many('cell_line_cvtermprop_cell_line_cvterm_id', 'Bio::Chado::CDBI::Cell_Line_Cvtermprop' => 'cell_line_cvterm_id');
  
    
sub cell_line_cvtermprops { return shift->cell_line_cvtermprop_cell_line_cvterm_id }
     


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Stockprop_Pub########

package Bio::Chado::CDBI::Stockprop_Pub;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Stockprop_Pub->set_up_table('stockprop_pub');

#
# Primary key accessors
#

sub id { shift->stockprop_pub_id }
sub stockprop_pub { shift->stockprop_pub_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Stockprop_Pub->has_a(stockprop_id => 'Bio::Chado::CDBI::Stockprop');
    
sub Bio::Chado::CDBI::Stockprop_Pub::stockprop { return shift->stockprop_id }
      
 
Bio::Chado::CDBI::Stockprop_Pub->has_a(pub_id => 'Bio::Chado::CDBI::Pub');
    
sub Bio::Chado::CDBI::Stockprop_Pub::pub { return shift->pub_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Cvtermprop########

package Bio::Chado::CDBI::Cvtermprop;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Cvtermprop->set_up_table('cvtermprop');

#
# Primary key accessors
#

sub id { shift->cvtermprop_id }
sub cvtermprop { shift->cvtermprop_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Cvtermprop->has_a(cvterm_id => 'Bio::Chado::CDBI::Cvterm');
    
sub cvterm { return shift->cvterm_id }
      
 
Bio::Chado::CDBI::Cvtermprop->has_a(type_id => 'Bio::Chado::CDBI::Cvterm');
    
sub type { return shift->type_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Element########

package Bio::Chado::CDBI::Element;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Element->set_up_table('element');

#
# Primary key accessors
#

sub id { shift->element_id }
sub element { shift->element_id }
 



#
# Has A
#
  
  
  
 
Bio::Chado::CDBI::Element->has_a(feature_id => 'Bio::Chado::CDBI::Feature');
    
sub Bio::Chado::CDBI::Element::feature { return shift->feature_id }
      
 
Bio::Chado::CDBI::Element->has_a(arraydesign_id => 'Bio::Chado::CDBI::Arraydesign');
    
sub Bio::Chado::CDBI::Element::arraydesign { return shift->arraydesign_id }
      
 
Bio::Chado::CDBI::Element->has_a(type_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Element::cvterm { return shift->type_id }
      
 
Bio::Chado::CDBI::Element->has_a(dbxref_id => 'Bio::Chado::CDBI::Dbxref');
    
sub Bio::Chado::CDBI::Element::dbxref { return shift->dbxref_id }
       

#
# Has Many
#
 
Bio::Chado::CDBI::Element->has_many('elementresult_element_id', 'Bio::Chado::CDBI::Elementresult' => 'element_id');
  
    
sub elementresults { return shift->elementresult_element_id }
      
Bio::Chado::CDBI::Element->has_many('element_relationship_subject_id', 'Bio::Chado::CDBI::Element_Relationship' => 'subject_id');
  
    
sub element_relationship_subject_ids { my $self = shift; return $self->element_relationship_subject_id(@_) }
      
Bio::Chado::CDBI::Element->has_many('element_relationship_object_id', 'Bio::Chado::CDBI::Element_Relationship' => 'object_id');
  
    
sub element_relationship_object_ids { my $self = shift; return $self->element_relationship_object_id(@_) }
         


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Arraydesignprop########

package Bio::Chado::CDBI::Arraydesignprop;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Arraydesignprop->set_up_table('arraydesignprop');

#
# Primary key accessors
#

sub id { shift->arraydesignprop_id }
sub arraydesignprop { shift->arraydesignprop_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Arraydesignprop->has_a(arraydesign_id => 'Bio::Chado::CDBI::Arraydesign');
    
sub Bio::Chado::CDBI::Arraydesignprop::arraydesign { return shift->arraydesign_id }
      
 
Bio::Chado::CDBI::Arraydesignprop->has_a(type_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Arraydesignprop::cvterm { return shift->type_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Biomaterial_Treatment########

package Bio::Chado::CDBI::Biomaterial_Treatment;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Biomaterial_Treatment->set_up_table('biomaterial_treatment');

#
# Primary key accessors
#

sub id { shift->biomaterial_treatment_id }
sub biomaterial_treatment { shift->biomaterial_treatment_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Biomaterial_Treatment->has_a(biomaterial_id => 'Bio::Chado::CDBI::Biomaterial');
    
sub Bio::Chado::CDBI::Biomaterial_Treatment::biomaterial { return shift->biomaterial_id }
      
 
Bio::Chado::CDBI::Biomaterial_Treatment->has_a(treatment_id => 'Bio::Chado::CDBI::Treatment');
    
sub Bio::Chado::CDBI::Biomaterial_Treatment::treatment { return shift->treatment_id }
      
 
Bio::Chado::CDBI::Biomaterial_Treatment->has_a(unittype_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Biomaterial_Treatment::cvterm { return shift->unittype_id }
       

#
# Has Many
#
   


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Expressionprop########

package Bio::Chado::CDBI::Expressionprop;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Expressionprop->set_up_table('expressionprop');

#
# Primary key accessors
#

sub id { shift->expressionprop_id }
sub expressionprop { shift->expressionprop_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Expressionprop->has_a(expression_id => 'Bio::Chado::CDBI::Expression');
    
sub Bio::Chado::CDBI::Expressionprop::expression { return shift->expression_id }
      
 
Bio::Chado::CDBI::Expressionprop->has_a(type_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Expressionprop::cvterm { return shift->type_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Acquisitionprop########

package Bio::Chado::CDBI::Acquisitionprop;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Acquisitionprop->set_up_table('acquisitionprop');

#
# Primary key accessors
#

sub id { shift->acquisitionprop_id }
sub acquisitionprop { shift->acquisitionprop_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Acquisitionprop->has_a(acquisition_id => 'Bio::Chado::CDBI::Acquisition');
    
sub Bio::Chado::CDBI::Acquisitionprop::acquisition { return shift->acquisition_id }
      
 
Bio::Chado::CDBI::Acquisitionprop->has_a(type_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Acquisitionprop::cvterm { return shift->type_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Assay_Biomaterial########

package Bio::Chado::CDBI::Assay_Biomaterial;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Assay_Biomaterial->set_up_table('assay_biomaterial');

#
# Primary key accessors
#

sub id { shift->assay_biomaterial_id }
sub assay_biomaterial { shift->assay_biomaterial_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Assay_Biomaterial->has_a(assay_id => 'Bio::Chado::CDBI::Assay');
    
sub Bio::Chado::CDBI::Assay_Biomaterial::assay { return shift->assay_id }
      
 
Bio::Chado::CDBI::Assay_Biomaterial->has_a(biomaterial_id => 'Bio::Chado::CDBI::Biomaterial');
    
sub Bio::Chado::CDBI::Assay_Biomaterial::biomaterial { return shift->biomaterial_id }
      
 
Bio::Chado::CDBI::Assay_Biomaterial->has_a(channel_id => 'Bio::Chado::CDBI::Channel');
    
sub Bio::Chado::CDBI::Assay_Biomaterial::channel { return shift->channel_id }
       

#
# Has Many
#
   


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Acquisition########

package Bio::Chado::CDBI::Acquisition;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Acquisition->set_up_table('acquisition');

#
# Primary key accessors
#

sub id { shift->acquisition_id }
sub acquisition { shift->acquisition_id }
 



#
# Has A
#
  
  
  
  
 
Bio::Chado::CDBI::Acquisition->has_a(assay_id => 'Bio::Chado::CDBI::Assay');
    
sub Bio::Chado::CDBI::Acquisition::assay { return shift->assay_id }
      
 
Bio::Chado::CDBI::Acquisition->has_a(protocol_id => 'Bio::Chado::CDBI::Protocol');
    
sub Bio::Chado::CDBI::Acquisition::protocol { return shift->protocol_id }
      
 
Bio::Chado::CDBI::Acquisition->has_a(channel_id => 'Bio::Chado::CDBI::Channel');
    
sub Bio::Chado::CDBI::Acquisition::channel { return shift->channel_id }
       

#
# Has Many
#
 
Bio::Chado::CDBI::Acquisition->has_many('quantification_acquisition_id', 'Bio::Chado::CDBI::Quantification' => 'acquisition_id');
  
    
sub quantifications { return shift->quantification_acquisition_id }
      
Bio::Chado::CDBI::Acquisition->has_many('acquisition_relationship_subject_id', 'Bio::Chado::CDBI::Acquisition_Relationship' => 'subject_id');
  
    
sub acquisition_relationship_subject_ids { my $self = shift; return $self->acquisition_relationship_subject_id(@_) }
      
Bio::Chado::CDBI::Acquisition->has_many('acquisition_relationship_object_id', 'Bio::Chado::CDBI::Acquisition_Relationship' => 'object_id');
  
    
sub acquisition_relationship_object_ids { my $self = shift; return $self->acquisition_relationship_object_id(@_) }
      
Bio::Chado::CDBI::Acquisition->has_many('acquisitionprop_acquisition_id', 'Bio::Chado::CDBI::Acquisitionprop' => 'acquisition_id');
  
    
sub acquisitionprops { return shift->acquisitionprop_acquisition_id }
        


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Studydesignprop########

package Bio::Chado::CDBI::Studydesignprop;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Studydesignprop->set_up_table('studydesignprop');

#
# Primary key accessors
#

sub id { shift->studydesignprop_id }
sub studydesignprop { shift->studydesignprop_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Studydesignprop->has_a(studydesign_id => 'Bio::Chado::CDBI::Studydesign');
    
sub Bio::Chado::CDBI::Studydesignprop::studydesign { return shift->studydesign_id }
      
 
Bio::Chado::CDBI::Studydesignprop->has_a(type_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Studydesignprop::cvterm { return shift->type_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Channel########

package Bio::Chado::CDBI::Channel;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Channel->set_up_table('channel');

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
 
Bio::Chado::CDBI::Channel->has_many('assay_biomaterial_channel_id', 'Bio::Chado::CDBI::Assay_Biomaterial' => 'channel_id');
  
    
sub assay_biomaterials { return shift->assay_biomaterial_channel_id }
      
Bio::Chado::CDBI::Channel->has_many('acquisition_channel_id', 'Bio::Chado::CDBI::Acquisition' => 'channel_id');
  
    
sub acquisitions { return shift->acquisition_channel_id }
     


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Studyfactorvalue########

package Bio::Chado::CDBI::Studyfactorvalue;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Studyfactorvalue->set_up_table('studyfactorvalue');

#
# Primary key accessors
#

sub id { shift->studyfactorvalue_id }
sub studyfactorvalue { shift->studyfactorvalue_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Studyfactorvalue->has_a(studyfactor_id => 'Bio::Chado::CDBI::Studyfactor');
    
sub Bio::Chado::CDBI::Studyfactorvalue::studyfactor { return shift->studyfactor_id }
      
 
Bio::Chado::CDBI::Studyfactorvalue->has_a(assay_id => 'Bio::Chado::CDBI::Assay');
    
sub Bio::Chado::CDBI::Studyfactorvalue::assay { return shift->assay_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Assay_Project########

package Bio::Chado::CDBI::Assay_Project;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Assay_Project->set_up_table('assay_project');

#
# Primary key accessors
#

sub id { shift->assay_project_id }
sub assay_project { shift->assay_project_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Assay_Project->has_a(assay_id => 'Bio::Chado::CDBI::Assay');
    
sub Bio::Chado::CDBI::Assay_Project::assay { return shift->assay_id }
      
 
Bio::Chado::CDBI::Assay_Project->has_a(project_id => 'Bio::Chado::CDBI::Project');
    
sub Bio::Chado::CDBI::Assay_Project::project { return shift->project_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Environment_Cvterm########

package Bio::Chado::CDBI::Environment_Cvterm;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Environment_Cvterm->set_up_table('environment_cvterm');

#
# Primary key accessors
#

sub id { shift->environment_cvterm_id }
sub environment_cvterm { shift->environment_cvterm_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Environment_Cvterm->has_a(environment_id => 'Bio::Chado::CDBI::Environment');
    
sub Bio::Chado::CDBI::Environment_Cvterm::environment { return shift->environment_id }
      
 
Bio::Chado::CDBI::Environment_Cvterm->has_a(cvterm_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Environment_Cvterm::cvterm { return shift->cvterm_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Pubauthor########

package Bio::Chado::CDBI::Pubauthor;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Pubauthor->set_up_table('pubauthor');

#
# Primary key accessors
#

sub id { shift->pubauthor_id }
sub pubauthor { shift->pubauthor_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Pubauthor->has_a(pub_id => 'Bio::Chado::CDBI::Pub');
    
sub Bio::Chado::CDBI::Pubauthor::pub { return shift->pub_id }
       

#
# Has Many
#
 


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Organism########

package Bio::Chado::CDBI::Organism;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Organism->set_up_table('organism');

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
 
Bio::Chado::CDBI::Organism->has_many('phylonode_organism_organism_id', 'Bio::Chado::CDBI::Phylonode_Organism' => 'organism_id');
   
Bio::Chado::CDBI::Organism->has_many('organismprop_organism_id', 'Bio::Chado::CDBI::Organismprop' => 'organism_id');
  
    
sub organismprops { return shift->organismprop_organism_id }
      
Bio::Chado::CDBI::Organism->has_many('feature_organism_id', 'Bio::Chado::CDBI::Feature' => 'organism_id');
  
    
sub features { return shift->feature_organism_id }
      
Bio::Chado::CDBI::Organism->has_many('cell_line_organism_id', 'Bio::Chado::CDBI::Cell_Line' => 'organism_id');
  
    
sub cell_lines { return shift->cell_line_organism_id }
      
Bio::Chado::CDBI::Organism->has_many('stock_organism_id', 'Bio::Chado::CDBI::Stock' => 'organism_id');
  
    
sub stocks { return shift->stock_organism_id }
      
Bio::Chado::CDBI::Organism->has_many('biomaterial_taxon_id', 'Bio::Chado::CDBI::Biomaterial' => 'taxon_id');
  
    
sub biomaterials { return shift->biomaterial_taxon_id }
      
Bio::Chado::CDBI::Organism->has_many('organism_dbxref_organism_id', 'Bio::Chado::CDBI::Organism_Dbxref' => 'organism_id');
   
Bio::Chado::CDBI::Organism->has_many('phenotype_comparison_organism_id', 'Bio::Chado::CDBI::Phenotype_Comparison' => 'organism_id');
   
Bio::Chado::CDBI::Organism->has_many('library_organism_id', 'Bio::Chado::CDBI::Library' => 'organism_id');
  
    
sub librarys { return shift->library_organism_id }
     



#
# Has Compound Many (many to many relationships in all their flavors)
#
 
  
  
  
sub phenotype_comparison_organisms { return shift->phenotype_comparison_organism_id }
 
 
  
  
  
sub phenotype_comparison_organisms { return shift->phenotype_comparison_organism_id }
 
 
  
  
sub phenotype_comparison_organisms { return shift->phenotype_comparison_organism_id }
 
 
  
  
  
sub phenotype_comparison_organisms { return shift->phenotype_comparison_organism_id }
 
 
  
sub organism_dbxref_organisms { return shift->organism_dbxref_organism_id }

   
 
  
  
sub phylonode_organism_organisms { return shift->phylonode_organism_organism_id }
 
# one to many to one
 
  
  
  
# one2one #
sub pubs { my $self = shift; return map $_->pub_id, $self->phenotype_comparison_organism_id }

  
  

sub dbxrefs { my $self = shift; return map $_->dbxref_id, $self->organism_dbxref_organism_id }

  

sub phylonodes { my $self = shift; return map $_->phylonode_id, $self->phylonode_organism_organism_id }

# one to many to many
 
  
# one2many #
  
  
  
    
sub phenotype_comparison_genotype1s { my $self = shift; return map $_->genotype1_id, $self->phenotype_comparison_organism_id }
    
  
     
  

  
  
  
    
sub phenotype_comparison_environment1s { my $self = shift; return map $_->environment1_id, $self->phenotype_comparison_organism_id }
    
  
     
  
  

  
  
  
    
sub phenotype_comparison_phenotype1s { my $self = shift; return map $_->phenotype1_id, $self->phenotype_comparison_organism_id }
    
  
     
  
  
#many to many to one
 
  
  
  
  
  
  
#many to many to many


  
  
  
  
  
   

1;

########Bio::Chado::CDBI::Featurerange########

package Bio::Chado::CDBI::Featurerange;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Featurerange->set_up_table('featurerange');

#
# Primary key accessors
#

sub id { shift->featurerange_id }
sub featurerange { shift->featurerange_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Featurerange->has_a(featuremap_id => 'Bio::Chado::CDBI::Featuremap');
    
sub Bio::Chado::CDBI::Featurerange::featuremap { return shift->featuremap_id }
      
 
Bio::Chado::CDBI::Featurerange->has_a(feature_id => 'Bio::Chado::CDBI::Feature');
    
sub feature { return shift->feature_id }
      
 
Bio::Chado::CDBI::Featurerange->has_a(leftstartf_id => 'Bio::Chado::CDBI::Feature');
    
sub leftstartf { return shift->leftstartf_id }
      
 
Bio::Chado::CDBI::Featurerange->has_a(leftendf_id => 'Bio::Chado::CDBI::Feature');
    
sub leftendf { return shift->leftendf_id }
      
 
Bio::Chado::CDBI::Featurerange->has_a(rightstartf_id => 'Bio::Chado::CDBI::Feature');
    
sub rightstartf { return shift->rightstartf_id }
      
 
Bio::Chado::CDBI::Featurerange->has_a(rightendf_id => 'Bio::Chado::CDBI::Feature');
    
sub rightendf { return shift->rightendf_id }
       

#
# Has Many
#
      


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Cell_Line_Cvtermprop########

package Bio::Chado::CDBI::Cell_Line_Cvtermprop;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Cell_Line_Cvtermprop->set_up_table('cell_line_cvtermprop');

#
# Primary key accessors
#

sub id { shift->cell_line_cvtermprop_id }
sub cell_line_cvtermprop { shift->cell_line_cvtermprop_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Cell_Line_Cvtermprop->has_a(cell_line_cvterm_id => 'Bio::Chado::CDBI::Cell_Line_Cvterm');
    
sub Bio::Chado::CDBI::Cell_Line_Cvtermprop::cell_line_cvterm { return shift->cell_line_cvterm_id }
      
 
Bio::Chado::CDBI::Cell_Line_Cvtermprop->has_a(type_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Cell_Line_Cvtermprop::cvterm { return shift->type_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Featurepos########

package Bio::Chado::CDBI::Featurepos;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Featurepos->set_up_table('featurepos');

#
# Primary key accessors
#

sub id { shift->featurepos_id }
sub featurepos { shift->featurepos_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Featurepos->has_a(featuremap_id => 'Bio::Chado::CDBI::Featuremap');
    
sub Bio::Chado::CDBI::Featurepos::featuremap { return shift->featuremap_id }
      
 
Bio::Chado::CDBI::Featurepos->has_a(feature_id => 'Bio::Chado::CDBI::Feature');
    
sub feature { return shift->feature_id }
      
 
Bio::Chado::CDBI::Featurepos->has_a(map_feature_id => 'Bio::Chado::CDBI::Feature');
    
sub map_feature { return shift->map_feature_id }
       

#
# Has Many
#
   


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Phenotype_Comparison########

package Bio::Chado::CDBI::Phenotype_Comparison;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Phenotype_Comparison->set_up_table('phenotype_comparison');

#
# Primary key accessors
#

sub id { shift->phenotype_comparison_id }
sub phenotype_comparison { shift->phenotype_comparison_id }
 



#
# Has A
#
  
 
Bio::Chado::CDBI::Phenotype_Comparison->has_a(genotype1_id => 'Bio::Chado::CDBI::Genotype');
    
sub genotype1 { return shift->genotype1_id }
      
 
Bio::Chado::CDBI::Phenotype_Comparison->has_a(environment1_id => 'Bio::Chado::CDBI::Environment');
    
sub environment1 { return shift->environment1_id }
      
 
Bio::Chado::CDBI::Phenotype_Comparison->has_a(genotype2_id => 'Bio::Chado::CDBI::Genotype');
    
sub genotype2 { return shift->genotype2_id }
      
 
Bio::Chado::CDBI::Phenotype_Comparison->has_a(environment2_id => 'Bio::Chado::CDBI::Environment');
    
sub environment2 { return shift->environment2_id }
      
 
Bio::Chado::CDBI::Phenotype_Comparison->has_a(phenotype1_id => 'Bio::Chado::CDBI::Phenotype');
    
sub phenotype1 { return shift->phenotype1_id }
      
 
Bio::Chado::CDBI::Phenotype_Comparison->has_a(phenotype2_id => 'Bio::Chado::CDBI::Phenotype');
    
sub phenotype2 { return shift->phenotype2_id }
      
 
Bio::Chado::CDBI::Phenotype_Comparison->has_a(pub_id => 'Bio::Chado::CDBI::Pub');
    
sub Bio::Chado::CDBI::Phenotype_Comparison::pub { return shift->pub_id }
      
 
Bio::Chado::CDBI::Phenotype_Comparison->has_a(organism_id => 'Bio::Chado::CDBI::Organism');
    
sub Bio::Chado::CDBI::Phenotype_Comparison::organism { return shift->organism_id }
       

#
# Has Many
#
 
Bio::Chado::CDBI::Phenotype_Comparison->has_many('phenotype_comparison_cvterm_phenotype_comparison_id', 'Bio::Chado::CDBI::Phenotype_Comparison_Cvterm' => 'phenotype_comparison_id');
  
    
sub phenotype_comparison_cvterms { return shift->phenotype_comparison_cvterm_phenotype_comparison_id }
             


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Studyprop########

package Bio::Chado::CDBI::Studyprop;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Studyprop->set_up_table('studyprop');

#
# Primary key accessors
#

sub id { shift->studyprop_id }
sub studyprop { shift->studyprop_id }
 



#
# Has A
#
  
 
Bio::Chado::CDBI::Studyprop->has_a(study_id => 'Bio::Chado::CDBI::Study');
    
sub Bio::Chado::CDBI::Studyprop::study { return shift->study_id }
      
 
Bio::Chado::CDBI::Studyprop->has_a(type_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Studyprop::cvterm { return shift->type_id }
       

#
# Has Many
#
 
Bio::Chado::CDBI::Studyprop->has_many('studyprop_feature_studyprop_id', 'Bio::Chado::CDBI::Studyprop_Feature' => 'studyprop_id');
    



#
# Has Compound Many (many to many relationships in all their flavors)
#
 
  
sub studyprop_feature_studyprops { return shift->studyprop_feature_studyprop_id }

   
 
  
sub studyprop_feature_studyprops { return shift->studyprop_feature_studyprop_id }

   
# one to many to one
 
  
# one2one #
sub cvterms { my $self = shift; return map $_->type_id, $self->studyprop_feature_studyprop_id }

  

sub features { my $self = shift; return map $_->feature_id, $self->studyprop_feature_studyprop_id }

# one to many to many
 
  
  
#many to many to one
 
  
  
#many to many to many


  
   

1;

########Bio::Chado::CDBI::Elementresult_Relationship########

package Bio::Chado::CDBI::Elementresult_Relationship;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Elementresult_Relationship->set_up_table('elementresult_relationship');

#
# Primary key accessors
#

sub id { shift->elementresult_relationship_id }
sub elementresult_relationship { shift->elementresult_relationship_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Elementresult_Relationship->has_a(subject_id => 'Bio::Chado::CDBI::Elementresult');
    
sub subject { return shift->subject_id }
      
 
Bio::Chado::CDBI::Elementresult_Relationship->has_a(type_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Elementresult_Relationship::cvterm { return shift->type_id }
      
 
Bio::Chado::CDBI::Elementresult_Relationship->has_a(object_id => 'Bio::Chado::CDBI::Elementresult');
    
sub object { return shift->object_id }
       

#
# Has Many
#
   


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Phylonode########

package Bio::Chado::CDBI::Phylonode;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Phylonode->set_up_table('phylonode');

#
# Primary key accessors
#

sub id { shift->phylonode_id }
sub phylonode { shift->phylonode_id }
 



#
# Has A
#
  
  
  
  
  
 
Bio::Chado::CDBI::Phylonode->has_a(phylotree_id => 'Bio::Chado::CDBI::Phylotree');
    
sub Bio::Chado::CDBI::Phylonode::phylotree { return shift->phylotree_id }
      
 
Bio::Chado::CDBI::Phylonode->has_a(parent_phylonode_id => 'Bio::Chado::CDBI::Phylonode');
    
sub Bio::Chado::CDBI::Phylonode::phylonode { return shift->parent_phylonode_id }
      
  
 
Bio::Chado::CDBI::Phylonode->has_a(type_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Phylonode::cvterm { return shift->type_id }
      
 
Bio::Chado::CDBI::Phylonode->has_a(feature_id => 'Bio::Chado::CDBI::Feature');
    
sub Bio::Chado::CDBI::Phylonode::feature { return shift->feature_id }
      
   

#
# Has Many
#
 
Bio::Chado::CDBI::Phylonode->has_many('phylonode_pub_phylonode_id', 'Bio::Chado::CDBI::Phylonode_Pub' => 'phylonode_id');
   
Bio::Chado::CDBI::Phylonode->has_many('phylonode_organism_phylonode_id', 'Bio::Chado::CDBI::Phylonode_Organism' => 'phylonode_id');
   
Bio::Chado::CDBI::Phylonode->has_many('phylonode_relationship_subject_id', 'Bio::Chado::CDBI::Phylonode_Relationship' => 'subject_id');
  
    
sub phylonode_relationship_subject_ids { my $self = shift; return $self->phylonode_relationship_subject_id(@_) }
      
Bio::Chado::CDBI::Phylonode->has_many('phylonode_relationship_object_id', 'Bio::Chado::CDBI::Phylonode_Relationship' => 'object_id');
  
    
sub phylonode_relationship_object_ids { my $self = shift; return $self->phylonode_relationship_object_id(@_) }
      
Bio::Chado::CDBI::Phylonode->has_many('phylonodeprop_phylonode_id', 'Bio::Chado::CDBI::Phylonodeprop' => 'phylonode_id');
  
    
sub phylonodeprops { return shift->phylonodeprop_phylonode_id }
        
Bio::Chado::CDBI::Phylonode->has_many('phylonode_parent_phylonode_id', 'Bio::Chado::CDBI::Phylonode' => 'parent_phylonode_id');
  
    
sub phylonode_parent_phylonode_ids { my $self = shift; return $self->phylonode_parent_phylonode_id(@_) }
        
Bio::Chado::CDBI::Phylonode->has_many('phylonode_dbxref_phylonode_id', 'Bio::Chado::CDBI::Phylonode_Dbxref' => 'phylonode_id');
  



#
# Has Compound Many (many to many relationships in all their flavors)
#
 
  
sub phylonode_pub_phylonodes { return shift->phylonode_pub_phylonode_id }

   
 
  
sub phylonode_dbxref_phylonodes { return shift->phylonode_dbxref_phylonode_id }

   
 
  
sub phylonode_organism_phylonodes { return shift->phylonode_organism_phylonode_id }

   
# one to many to one
 
  
# one2one #
sub pubs { my $self = shift; return map $_->pub_id, $self->phylonode_pub_phylonode_id }

  

sub dbxrefs { my $self = shift; return map $_->dbxref_id, $self->phylonode_dbxref_phylonode_id }

  

sub organisms { my $self = shift; return map $_->organism_id, $self->phylonode_organism_phylonode_id }

# one to many to many
 
  
  
  
#many to many to one
 
  
  
  
#many to many to many


  
  
   

1;

########Bio::Chado::CDBI::Cvtermsynonym########

package Bio::Chado::CDBI::Cvtermsynonym;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Cvtermsynonym->set_up_table('cvtermsynonym');

#
# Primary key accessors
#

sub id { shift->cvtermsynonym_id }
sub cvtermsynonym { shift->cvtermsynonym_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Cvtermsynonym->has_a(cvterm_id => 'Bio::Chado::CDBI::Cvterm');
    
sub cvterm { return shift->cvterm_id }
      
 
Bio::Chado::CDBI::Cvtermsynonym->has_a(type_id => 'Bio::Chado::CDBI::Cvterm');
    
sub type { return shift->type_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Cell_Lineprop_Pub########

package Bio::Chado::CDBI::Cell_Lineprop_Pub;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Cell_Lineprop_Pub->set_up_table('cell_lineprop_pub');

#
# Primary key accessors
#

sub id { shift->cell_lineprop_pub_id }
sub cell_lineprop_pub { shift->cell_lineprop_pub_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Cell_Lineprop_Pub->has_a(cell_lineprop_id => 'Bio::Chado::CDBI::Cell_Lineprop');
    
sub Bio::Chado::CDBI::Cell_Lineprop_Pub::cell_lineprop { return shift->cell_lineprop_id }
      
 
Bio::Chado::CDBI::Cell_Lineprop_Pub->has_a(pub_id => 'Bio::Chado::CDBI::Pub');
    
sub Bio::Chado::CDBI::Cell_Lineprop_Pub::pub { return shift->pub_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Cell_Lineprop########

package Bio::Chado::CDBI::Cell_Lineprop;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Cell_Lineprop->set_up_table('cell_lineprop');

#
# Primary key accessors
#

sub id { shift->cell_lineprop_id }
sub cell_lineprop { shift->cell_lineprop_id }
 



#
# Has A
#
  
 
Bio::Chado::CDBI::Cell_Lineprop->has_a(cell_line_id => 'Bio::Chado::CDBI::Cell_Line');
    
sub Bio::Chado::CDBI::Cell_Lineprop::cell_line { return shift->cell_line_id }
      
 
Bio::Chado::CDBI::Cell_Lineprop->has_a(type_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Cell_Lineprop::cvterm { return shift->type_id }
       

#
# Has Many
#
 
Bio::Chado::CDBI::Cell_Lineprop->has_many('cell_lineprop_pub_cell_lineprop_id', 'Bio::Chado::CDBI::Cell_Lineprop_Pub' => 'cell_lineprop_id');
    



#
# Has Compound Many (many to many relationships in all their flavors)
#
 
  
sub cell_lineprop_pub_cell_lineprops { return shift->cell_lineprop_pub_cell_lineprop_id }

   
# one to many to one
 
  
# one2one #
sub pubs { my $self = shift; return map $_->pub_id, $self->cell_lineprop_pub_cell_lineprop_id }

# one to many to many
 
  
#many to many to one
 
  
#many to many to many


   

1;

########Bio::Chado::CDBI::Stock_Relationship########

package Bio::Chado::CDBI::Stock_Relationship;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Stock_Relationship->set_up_table('stock_relationship');

#
# Primary key accessors
#

sub id { shift->stock_relationship_id }
sub stock_relationship { shift->stock_relationship_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Stock_Relationship->has_a(subject_id => 'Bio::Chado::CDBI::Stock');
    
sub subject { return shift->subject_id }
      
 
Bio::Chado::CDBI::Stock_Relationship->has_a(object_id => 'Bio::Chado::CDBI::Stock');
    
sub object { return shift->object_id }
      
 
Bio::Chado::CDBI::Stock_Relationship->has_a(type_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Stock_Relationship::cvterm { return shift->type_id }
      
   

#
# Has Many
#
    
Bio::Chado::CDBI::Stock_Relationship->has_many('stock_relationship_pub_stock_relationship_id', 'Bio::Chado::CDBI::Stock_Relationship_Pub' => 'stock_relationship_id');
  



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

########Bio::Chado::CDBI::Stockcollection########

package Bio::Chado::CDBI::Stockcollection;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Stockcollection->set_up_table('stockcollection');

#
# Primary key accessors
#

sub id { shift->stockcollection_id }
sub stockcollection { shift->stockcollection_id }
 



#
# Has A
#
  
 
Bio::Chado::CDBI::Stockcollection->has_a(type_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Stockcollection::cvterm { return shift->type_id }
      
 
Bio::Chado::CDBI::Stockcollection->has_a(contact_id => 'Bio::Chado::CDBI::Contact');
    
sub Bio::Chado::CDBI::Stockcollection::contact { return shift->contact_id }
      
   

#
# Has Many
#
 
Bio::Chado::CDBI::Stockcollection->has_many('stockcollectionprop_stockcollection_id', 'Bio::Chado::CDBI::Stockcollectionprop' => 'stockcollection_id');
  
    
sub stockcollectionprops { return shift->stockcollectionprop_stockcollection_id }
        
Bio::Chado::CDBI::Stockcollection->has_many('stockcollection_stock_stockcollection_id', 'Bio::Chado::CDBI::Stockcollection_Stock' => 'stockcollection_id');
  



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

########Bio::Chado::CDBI::Expression########

package Bio::Chado::CDBI::Expression;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Expression->set_up_table('expression');

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
 
Bio::Chado::CDBI::Expression->has_many('feature_expression_expression_id', 'Bio::Chado::CDBI::Feature_Expression' => 'expression_id');
   
Bio::Chado::CDBI::Expression->has_many('expression_pub_expression_id', 'Bio::Chado::CDBI::Expression_Pub' => 'expression_id');
   
Bio::Chado::CDBI::Expression->has_many('expression_image_expression_id', 'Bio::Chado::CDBI::Expression_Image' => 'expression_id');
   
Bio::Chado::CDBI::Expression->has_many('expressionprop_expression_id', 'Bio::Chado::CDBI::Expressionprop' => 'expression_id');
  
    
sub expressionprops { return shift->expressionprop_expression_id }
      
Bio::Chado::CDBI::Expression->has_many('expression_cvterm_expression_id', 'Bio::Chado::CDBI::Expression_Cvterm' => 'expression_id');
  
    
sub expression_cvterms { return shift->expression_cvterm_expression_id }
     



#
# Has Compound Many (many to many relationships in all their flavors)
#
 
  
sub feature_expression_expressions { return shift->feature_expression_expression_id }

   
 
  
sub feature_expression_expressions { return shift->feature_expression_expression_id }

   
 
  
sub expression_pub_expressions { return shift->expression_pub_expression_id }

   
 
  
sub expression_image_expressions { return shift->expression_image_expression_id }

   
# one to many to one
 
  
# one2one #
sub pubs { my $self = shift; return map $_->pub_id, $self->feature_expression_expression_id }

  

sub features { my $self = shift; return map $_->feature_id, $self->feature_expression_expression_id }

  

sub pubs { my $self = shift; return map $_->pub_id, $self->expression_pub_expression_id }

  

sub eimages { my $self = shift; return map $_->eimage_id, $self->expression_image_expression_id }

# one to many to many
 
  
  
  
  
#many to many to one
 
  
  
  
  
#many to many to many


  
  
  
   

1;

########Bio::Chado::CDBI::Magedocumentation########

package Bio::Chado::CDBI::Magedocumentation;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Magedocumentation->set_up_table('magedocumentation');

#
# Primary key accessors
#

sub id { shift->magedocumentation_id }
sub magedocumentation { shift->magedocumentation_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Magedocumentation->has_a(mageml_id => 'Bio::Chado::CDBI::Mageml');
    
sub Bio::Chado::CDBI::Magedocumentation::mageml { return shift->mageml_id }
      
 
Bio::Chado::CDBI::Magedocumentation->has_a(tableinfo_id => 'Bio::Chado::CDBI::Tableinfo');
    
sub Bio::Chado::CDBI::Magedocumentation::tableinfo { return shift->tableinfo_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Library_Cvterm########

package Bio::Chado::CDBI::Library_Cvterm;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Library_Cvterm->set_up_table('library_cvterm');

#
# Primary key accessors
#

sub id { shift->library_cvterm_id }
sub library_cvterm { shift->library_cvterm_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Library_Cvterm->has_a(library_id => 'Bio::Chado::CDBI::Library');
    
sub Bio::Chado::CDBI::Library_Cvterm::library { return shift->library_id }
      
 
Bio::Chado::CDBI::Library_Cvterm->has_a(cvterm_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Library_Cvterm::cvterm { return shift->cvterm_id }
      
 
Bio::Chado::CDBI::Library_Cvterm->has_a(pub_id => 'Bio::Chado::CDBI::Pub');
    
sub Bio::Chado::CDBI::Library_Cvterm::pub { return shift->pub_id }
       

#
# Has Many
#
   


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Stock_Relationship_Pub########

package Bio::Chado::CDBI::Stock_Relationship_Pub;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Stock_Relationship_Pub->set_up_table('stock_relationship_pub');

#
# Primary key accessors
#

sub id { shift->stock_relationship_pub_id }
sub stock_relationship_pub { shift->stock_relationship_pub_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Stock_Relationship_Pub->has_a(stock_relationship_id => 'Bio::Chado::CDBI::Stock_Relationship');
    
sub Bio::Chado::CDBI::Stock_Relationship_Pub::stock_relationship { return shift->stock_relationship_id }
      
 
Bio::Chado::CDBI::Stock_Relationship_Pub->has_a(pub_id => 'Bio::Chado::CDBI::Pub');
    
sub Bio::Chado::CDBI::Stock_Relationship_Pub::pub { return shift->pub_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Library_Dbxref########

package Bio::Chado::CDBI::Library_Dbxref;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Library_Dbxref->set_up_table('library_dbxref');

#
# Primary key accessors
#

sub id { shift->library_dbxref_id }
sub library_dbxref { shift->library_dbxref_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Library_Dbxref->has_a(library_id => 'Bio::Chado::CDBI::Library');
    
sub Bio::Chado::CDBI::Library_Dbxref::library { return shift->library_id }
      
 
Bio::Chado::CDBI::Library_Dbxref->has_a(dbxref_id => 'Bio::Chado::CDBI::Dbxref');
    
sub Bio::Chado::CDBI::Library_Dbxref::dbxref { return shift->dbxref_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Analysisprop########

package Bio::Chado::CDBI::Analysisprop;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Analysisprop->set_up_table('analysisprop');

#
# Primary key accessors
#

sub id { shift->analysisprop_id }
sub analysisprop { shift->analysisprop_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Analysisprop->has_a(analysis_id => 'Bio::Chado::CDBI::Analysis');
    
sub Bio::Chado::CDBI::Analysisprop::analysis { return shift->analysis_id }
      
 
Bio::Chado::CDBI::Analysisprop->has_a(type_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Analysisprop::cvterm { return shift->type_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Feature_Relationship_Pub########

package Bio::Chado::CDBI::Feature_Relationship_Pub;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Feature_Relationship_Pub->set_up_table('feature_relationship_pub');

#
# Primary key accessors
#

sub id { shift->feature_relationship_pub_id }
sub feature_relationship_pub { shift->feature_relationship_pub_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Feature_Relationship_Pub->has_a(feature_relationship_id => 'Bio::Chado::CDBI::Feature_Relationship');
    
sub Bio::Chado::CDBI::Feature_Relationship_Pub::feature_relationship { return shift->feature_relationship_id }
      
 
Bio::Chado::CDBI::Feature_Relationship_Pub->has_a(pub_id => 'Bio::Chado::CDBI::Pub');
    
sub Bio::Chado::CDBI::Feature_Relationship_Pub::pub { return shift->pub_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Stockcollection_Stock########

package Bio::Chado::CDBI::Stockcollection_Stock;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Stockcollection_Stock->set_up_table('stockcollection_stock');

#
# Primary key accessors
#

sub id { shift->stockcollection_stock_id }
sub stockcollection_stock { shift->stockcollection_stock_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Stockcollection_Stock->has_a(stockcollection_id => 'Bio::Chado::CDBI::Stockcollection');
    
sub Bio::Chado::CDBI::Stockcollection_Stock::stockcollection { return shift->stockcollection_id }
      
 
Bio::Chado::CDBI::Stockcollection_Stock->has_a(stock_id => 'Bio::Chado::CDBI::Stock');
    
sub Bio::Chado::CDBI::Stockcollection_Stock::stock { return shift->stock_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Treatment########

package Bio::Chado::CDBI::Treatment;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Treatment->set_up_table('treatment');

#
# Primary key accessors
#

sub id { shift->treatment_id }
sub treatment { shift->treatment_id }
 



#
# Has A
#
  
 
Bio::Chado::CDBI::Treatment->has_a(biomaterial_id => 'Bio::Chado::CDBI::Biomaterial');
    
sub Bio::Chado::CDBI::Treatment::biomaterial { return shift->biomaterial_id }
      
 
Bio::Chado::CDBI::Treatment->has_a(type_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Treatment::cvterm { return shift->type_id }
      
 
Bio::Chado::CDBI::Treatment->has_a(protocol_id => 'Bio::Chado::CDBI::Protocol');
    
sub Bio::Chado::CDBI::Treatment::protocol { return shift->protocol_id }
       

#
# Has Many
#
 
Bio::Chado::CDBI::Treatment->has_many('biomaterial_treatment_treatment_id', 'Bio::Chado::CDBI::Biomaterial_Treatment' => 'treatment_id');
  
    
sub biomaterial_treatments { return shift->biomaterial_treatment_treatment_id }
        


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Pubprop########

package Bio::Chado::CDBI::Pubprop;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Pubprop->set_up_table('pubprop');

#
# Primary key accessors
#

sub id { shift->pubprop_id }
sub pubprop { shift->pubprop_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Pubprop->has_a(pub_id => 'Bio::Chado::CDBI::Pub');
    
sub Bio::Chado::CDBI::Pubprop::pub { return shift->pub_id }
      
 
Bio::Chado::CDBI::Pubprop->has_a(type_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Pubprop::cvterm { return shift->type_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Phylonode_Dbxref########

package Bio::Chado::CDBI::Phylonode_Dbxref;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Phylonode_Dbxref->set_up_table('phylonode_dbxref');

#
# Primary key accessors
#

sub id { shift->phylonode_dbxref_id }
sub phylonode_dbxref { shift->phylonode_dbxref_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Phylonode_Dbxref->has_a(phylonode_id => 'Bio::Chado::CDBI::Phylonode');
    
sub Bio::Chado::CDBI::Phylonode_Dbxref::phylonode { return shift->phylonode_id }
      
 
Bio::Chado::CDBI::Phylonode_Dbxref->has_a(dbxref_id => 'Bio::Chado::CDBI::Dbxref');
    
sub Bio::Chado::CDBI::Phylonode_Dbxref::dbxref { return shift->dbxref_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Quantificationprop########

package Bio::Chado::CDBI::Quantificationprop;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Quantificationprop->set_up_table('quantificationprop');

#
# Primary key accessors
#

sub id { shift->quantificationprop_id }
sub quantificationprop { shift->quantificationprop_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Quantificationprop->has_a(quantification_id => 'Bio::Chado::CDBI::Quantification');
    
sub Bio::Chado::CDBI::Quantificationprop::quantification { return shift->quantification_id }
      
 
Bio::Chado::CDBI::Quantificationprop->has_a(type_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Quantificationprop::cvterm { return shift->type_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Expression_Cvterm########

package Bio::Chado::CDBI::Expression_Cvterm;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Expression_Cvterm->set_up_table('expression_cvterm');

#
# Primary key accessors
#

sub id { shift->expression_cvterm_id }
sub expression_cvterm { shift->expression_cvterm_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Expression_Cvterm->has_a(expression_id => 'Bio::Chado::CDBI::Expression');
    
sub Bio::Chado::CDBI::Expression_Cvterm::expression { return shift->expression_id }
      
 
Bio::Chado::CDBI::Expression_Cvterm->has_a(cvterm_id => 'Bio::Chado::CDBI::Cvterm');
    
sub cvterm { return shift->cvterm_id }
      
 
Bio::Chado::CDBI::Expression_Cvterm->has_a(cvterm_type_id => 'Bio::Chado::CDBI::Cvterm');
    
sub cvterm_type { return shift->cvterm_type_id }
      
   

#
# Has Many
#
    
Bio::Chado::CDBI::Expression_Cvterm->has_many('expression_cvtermprop_expression_cvterm_id', 'Bio::Chado::CDBI::Expression_Cvtermprop' => 'expression_cvterm_id');
  
    
sub expression_cvtermprops { return shift->expression_cvtermprop_expression_cvterm_id }
     


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Cv########

package Bio::Chado::CDBI::Cv;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Cv->set_up_table('cv');

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
 
Bio::Chado::CDBI::Cv->has_many('cvtermpath_cv_id', 'Bio::Chado::CDBI::Cvtermpath' => 'cv_id');
  
    
sub cvtermpaths { return shift->cvtermpath_cv_id }
      
Bio::Chado::CDBI::Cv->has_many('cvterm_cv_id', 'Bio::Chado::CDBI::Cvterm' => 'cv_id');
  
    
sub cvterms { return shift->cvterm_cv_id }
     


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Feature_Cvterm_Pub########

package Bio::Chado::CDBI::Feature_Cvterm_Pub;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Feature_Cvterm_Pub->set_up_table('feature_cvterm_pub');

#
# Primary key accessors
#

sub id { shift->feature_cvterm_pub_id }
sub feature_cvterm_pub { shift->feature_cvterm_pub_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Feature_Cvterm_Pub->has_a(feature_cvterm_id => 'Bio::Chado::CDBI::Feature_Cvterm');
    
sub Bio::Chado::CDBI::Feature_Cvterm_Pub::feature_cvterm { return shift->feature_cvterm_id }
      
 
Bio::Chado::CDBI::Feature_Cvterm_Pub->has_a(pub_id => 'Bio::Chado::CDBI::Pub');
    
sub Bio::Chado::CDBI::Feature_Cvterm_Pub::pub { return shift->pub_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Contact########

package Bio::Chado::CDBI::Contact;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Contact->set_up_table('contact');

#
# Primary key accessors
#

sub id { shift->contact_id }
sub contact { shift->contact_id }
 



#
# Has A
#
  
  
  
  
  
  
  
  
 
Bio::Chado::CDBI::Contact->has_a(type_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Contact::cvterm { return shift->type_id }
       

#
# Has Many
#
 
Bio::Chado::CDBI::Contact->has_many('quantification_operator_id', 'Bio::Chado::CDBI::Quantification' => 'operator_id');
  
    
sub quantifications { return shift->quantification_operator_id }
      
Bio::Chado::CDBI::Contact->has_many('arraydesign_manufacturer_id', 'Bio::Chado::CDBI::Arraydesign' => 'manufacturer_id');
  
    
sub arraydesigns { return shift->arraydesign_manufacturer_id }
      
Bio::Chado::CDBI::Contact->has_many('contact_relationship_subject_id', 'Bio::Chado::CDBI::Contact_Relationship' => 'subject_id');
   
Bio::Chado::CDBI::Contact->has_many('contact_relationship_object_id', 'Bio::Chado::CDBI::Contact_Relationship' => 'object_id');
   
Bio::Chado::CDBI::Contact->has_many('biomaterial_biosourceprovider_id', 'Bio::Chado::CDBI::Biomaterial' => 'biosourceprovider_id');
  
    
sub biomaterials { return shift->biomaterial_biosourceprovider_id }
      
Bio::Chado::CDBI::Contact->has_many('assay_operator_id', 'Bio::Chado::CDBI::Assay' => 'operator_id');
  
    
sub assays { return shift->assay_operator_id }
      
Bio::Chado::CDBI::Contact->has_many('study_contact_id', 'Bio::Chado::CDBI::Study' => 'contact_id');
  
    
sub studys { return shift->study_contact_id }
      
Bio::Chado::CDBI::Contact->has_many('stockcollection_contact_id', 'Bio::Chado::CDBI::Stockcollection' => 'contact_id');
  
    
sub stockcollections { return shift->stockcollection_contact_id }
      



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

########Bio::Chado::CDBI::Library########

package Bio::Chado::CDBI::Library;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Library->set_up_table('library');

#
# Primary key accessors
#

sub id { shift->library_id }
sub library { shift->library_id }
 



#
# Has A
#
  
  
  
  
  
  
  
 
Bio::Chado::CDBI::Library->has_a(organism_id => 'Bio::Chado::CDBI::Organism');
    
sub Bio::Chado::CDBI::Library::organism { return shift->organism_id }
      
 
Bio::Chado::CDBI::Library->has_a(type_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Library::cvterm { return shift->type_id }
       

#
# Has Many
#
 
Bio::Chado::CDBI::Library->has_many('library_pub_library_id', 'Bio::Chado::CDBI::Library_Pub' => 'library_id');
   
Bio::Chado::CDBI::Library->has_many('library_feature_library_id', 'Bio::Chado::CDBI::Library_Feature' => 'library_id');
   
Bio::Chado::CDBI::Library->has_many('libraryprop_library_id', 'Bio::Chado::CDBI::Libraryprop' => 'library_id');
  
    
sub libraryprops { return shift->libraryprop_library_id }
      
Bio::Chado::CDBI::Library->has_many('cell_line_library_library_id', 'Bio::Chado::CDBI::Cell_Line_Library' => 'library_id');
   
Bio::Chado::CDBI::Library->has_many('library_synonym_library_id', 'Bio::Chado::CDBI::Library_Synonym' => 'library_id');
  
    
sub library_synonyms { return shift->library_synonym_library_id }
      
Bio::Chado::CDBI::Library->has_many('library_cvterm_library_id', 'Bio::Chado::CDBI::Library_Cvterm' => 'library_id');
   
Bio::Chado::CDBI::Library->has_many('library_dbxref_library_id', 'Bio::Chado::CDBI::Library_Dbxref' => 'library_id');
  
    
sub library_dbxrefs { return shift->library_dbxref_library_id }
       



#
# Has Compound Many (many to many relationships in all their flavors)
#
 
  
sub library_cvterm_librarys { return shift->library_cvterm_library_id }

   
 
  
sub library_cvterm_librarys { return shift->library_cvterm_library_id }

   
 
  
sub library_feature_librarys { return shift->library_feature_library_id }

   
 
  
sub library_pub_librarys { return shift->library_pub_library_id }

   
 
  
sub cell_line_library_librarys { return shift->cell_line_library_library_id }

   
 
  
  
sub cell_line_library_librarys { return shift->cell_line_library_library_id }
 
# one to many to one
 
  
# one2one #
sub cvterms { my $self = shift; return map $_->cvterm_id, $self->library_cvterm_library_id }

  

sub pubs { my $self = shift; return map $_->pub_id, $self->library_cvterm_library_id }

  

sub features { my $self = shift; return map $_->feature_id, $self->library_feature_library_id }

  

sub pubs { my $self = shift; return map $_->pub_id, $self->library_pub_library_id }

  

sub pubs { my $self = shift; return map $_->pub_id, $self->cell_line_library_library_id }

  

sub cell_lines { my $self = shift; return map $_->cell_line_id, $self->cell_line_library_library_id }

# one to many to many
 
  
  
  
  
  
  
#many to many to one
 
  
  
  
  
  
  
#many to many to many


  
  
  
  
  
   

1;

########Bio::Chado::CDBI::Feature_Synonym########

package Bio::Chado::CDBI::Feature_Synonym;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Feature_Synonym->set_up_table('feature_synonym');

#
# Primary key accessors
#

sub id { shift->feature_synonym_id }
sub feature_synonym { shift->feature_synonym_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Feature_Synonym->has_a(synonym_id => 'Bio::Chado::CDBI::Synonym');
    
sub Bio::Chado::CDBI::Feature_Synonym::synonym { return shift->synonym_id }
      
 
Bio::Chado::CDBI::Feature_Synonym->has_a(feature_id => 'Bio::Chado::CDBI::Feature');
    
sub Bio::Chado::CDBI::Feature_Synonym::feature { return shift->feature_id }
      
 
Bio::Chado::CDBI::Feature_Synonym->has_a(pub_id => 'Bio::Chado::CDBI::Pub');
    
sub Bio::Chado::CDBI::Feature_Synonym::pub { return shift->pub_id }
       

#
# Has Many
#
   


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Phenotype_Cvterm########

package Bio::Chado::CDBI::Phenotype_Cvterm;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Phenotype_Cvterm->set_up_table('phenotype_cvterm');

#
# Primary key accessors
#

sub id { shift->phenotype_cvterm_id }
sub phenotype_cvterm { shift->phenotype_cvterm_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Phenotype_Cvterm->has_a(phenotype_id => 'Bio::Chado::CDBI::Phenotype');
    
sub Bio::Chado::CDBI::Phenotype_Cvterm::phenotype { return shift->phenotype_id }
      
 
Bio::Chado::CDBI::Phenotype_Cvterm->has_a(cvterm_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Phenotype_Cvterm::cvterm { return shift->cvterm_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Cell_Line_Pub########

package Bio::Chado::CDBI::Cell_Line_Pub;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Cell_Line_Pub->set_up_table('cell_line_pub');

#
# Primary key accessors
#

sub id { shift->cell_line_pub_id }
sub cell_line_pub { shift->cell_line_pub_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Cell_Line_Pub->has_a(cell_line_id => 'Bio::Chado::CDBI::Cell_Line');
    
sub Bio::Chado::CDBI::Cell_Line_Pub::cell_line { return shift->cell_line_id }
      
 
Bio::Chado::CDBI::Cell_Line_Pub->has_a(pub_id => 'Bio::Chado::CDBI::Pub');
    
sub Bio::Chado::CDBI::Cell_Line_Pub::pub { return shift->pub_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Featuremap_Pub########

package Bio::Chado::CDBI::Featuremap_Pub;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Featuremap_Pub->set_up_table('featuremap_pub');

#
# Primary key accessors
#

sub id { shift->featuremap_pub_id }
sub featuremap_pub { shift->featuremap_pub_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Featuremap_Pub->has_a(featuremap_id => 'Bio::Chado::CDBI::Featuremap');
    
sub Bio::Chado::CDBI::Featuremap_Pub::featuremap { return shift->featuremap_id }
      
 
Bio::Chado::CDBI::Featuremap_Pub->has_a(pub_id => 'Bio::Chado::CDBI::Pub');
    
sub Bio::Chado::CDBI::Featuremap_Pub::pub { return shift->pub_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Feature_Genotype########

package Bio::Chado::CDBI::Feature_Genotype;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Feature_Genotype->set_up_table('feature_genotype');

#
# Primary key accessors
#

sub id { shift->feature_genotype_id }
sub feature_genotype { shift->feature_genotype_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Feature_Genotype->has_a(feature_id => 'Bio::Chado::CDBI::Feature');
    
sub feature { return shift->feature_id }
      
 
Bio::Chado::CDBI::Feature_Genotype->has_a(genotype_id => 'Bio::Chado::CDBI::Genotype');
    
sub Bio::Chado::CDBI::Feature_Genotype::genotype { return shift->genotype_id }
      
 
Bio::Chado::CDBI::Feature_Genotype->has_a(chromosome_id => 'Bio::Chado::CDBI::Feature');
    
sub chromosome { return shift->chromosome_id }
      
 
Bio::Chado::CDBI::Feature_Genotype->has_a(cvterm_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Feature_Genotype::cvterm { return shift->cvterm_id }
       

#
# Has Many
#
    


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Stockprop########

package Bio::Chado::CDBI::Stockprop;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Stockprop->set_up_table('stockprop');

#
# Primary key accessors
#

sub id { shift->stockprop_id }
sub stockprop { shift->stockprop_id }
 



#
# Has A
#
  
 
Bio::Chado::CDBI::Stockprop->has_a(stock_id => 'Bio::Chado::CDBI::Stock');
    
sub Bio::Chado::CDBI::Stockprop::stock { return shift->stock_id }
      
 
Bio::Chado::CDBI::Stockprop->has_a(type_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Stockprop::cvterm { return shift->type_id }
       

#
# Has Many
#
 
Bio::Chado::CDBI::Stockprop->has_many('stockprop_pub_stockprop_id', 'Bio::Chado::CDBI::Stockprop_Pub' => 'stockprop_id');
    



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

########Bio::Chado::CDBI::Cvterm########

package Bio::Chado::CDBI::Cvterm;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Cvterm->set_up_table('cvterm');

#
# Primary key accessors
#

sub id { shift->cvterm_id }
sub cvterm { shift->cvterm_id }
 



#
# Has A
#
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
 
Bio::Chado::CDBI::Cvterm->has_a(cv_id => 'Bio::Chado::CDBI::Cv');
    
sub Bio::Chado::CDBI::Cvterm::cv { return shift->cv_id }
      
 
Bio::Chado::CDBI::Cvterm->has_a(dbxref_id => 'Bio::Chado::CDBI::Dbxref');
    
sub Bio::Chado::CDBI::Cvterm::dbxref { return shift->dbxref_id }
      
  
  
  
  
  
  
   

#
# Has Many
#
 
Bio::Chado::CDBI::Cvterm->has_many('feature_cvterm_cvterm_id', 'Bio::Chado::CDBI::Feature_Cvterm' => 'cvterm_id');
  
    
sub feature_cvterms { return shift->feature_cvterm_cvterm_id }
      
Bio::Chado::CDBI::Cvterm->has_many('arraydesign_platformtype_id', 'Bio::Chado::CDBI::Arraydesign' => 'platformtype_id');
  
sub arraydesign_platformtypes { return shift->arraydesign_platformtype_id }
#sub --arraydesign--platformtype_id-- {}
   
Bio::Chado::CDBI::Cvterm->has_many('arraydesign_substratetype_id', 'Bio::Chado::CDBI::Arraydesign' => 'substratetype_id');
  
sub arraydesign_substratetypes { return shift->arraydesign_substratetype_id }
#sub --arraydesign--substratetype_id-- {}
   
Bio::Chado::CDBI::Cvterm->has_many('biomaterial_relationship_type_id', 'Bio::Chado::CDBI::Biomaterial_Relationship' => 'type_id');
   
Bio::Chado::CDBI::Cvterm->has_many('cell_line_relationship_type_id', 'Bio::Chado::CDBI::Cell_Line_Relationship' => 'type_id');
   
Bio::Chado::CDBI::Cvterm->has_many('quantification_relationship_type_id', 'Bio::Chado::CDBI::Quantification_Relationship' => 'type_id');
   
Bio::Chado::CDBI::Cvterm->has_many('phenotype_comparison_cvterm_cvterm_id', 'Bio::Chado::CDBI::Phenotype_Comparison_Cvterm' => 'cvterm_id');
  
    
sub phenotype_comparison_cvterms { return shift->phenotype_comparison_cvterm_cvterm_id }
      
Bio::Chado::CDBI::Cvterm->has_many('synonym_type_id', 'Bio::Chado::CDBI::Synonym' => 'type_id');
  
    
sub synonyms { return shift->synonym_type_id }
      
Bio::Chado::CDBI::Cvterm->has_many('cvtermpath_type_id', 'Bio::Chado::CDBI::Cvtermpath' => 'type_id');
  
    
sub cvtermpath_type_ids { my $self = shift; return $self->cvtermpath_type_id(@_) }
      
Bio::Chado::CDBI::Cvterm->has_many('cvtermpath_subject_id', 'Bio::Chado::CDBI::Cvtermpath' => 'subject_id');
  
    
sub cvtermpath_subject_ids { my $self = shift; return $self->cvtermpath_subject_id(@_) }
      
Bio::Chado::CDBI::Cvterm->has_many('cvtermpath_object_id', 'Bio::Chado::CDBI::Cvtermpath' => 'object_id');
  
    
sub cvtermpath_object_ids { my $self = shift; return $self->cvtermpath_object_id(@_) }
      
Bio::Chado::CDBI::Cvterm->has_many('cvterm_relationship_type_id', 'Bio::Chado::CDBI::Cvterm_Relationship' => 'type_id');
   
Bio::Chado::CDBI::Cvterm->has_many('cvterm_relationship_subject_id', 'Bio::Chado::CDBI::Cvterm_Relationship' => 'subject_id');
   
Bio::Chado::CDBI::Cvterm->has_many('cvterm_relationship_object_id', 'Bio::Chado::CDBI::Cvterm_Relationship' => 'object_id');
   
Bio::Chado::CDBI::Cvterm->has_many('assayprop_type_id', 'Bio::Chado::CDBI::Assayprop' => 'type_id');
  
    
sub assayprops { return shift->assayprop_type_id }
      
Bio::Chado::CDBI::Cvterm->has_many('contact_relationship_type_id', 'Bio::Chado::CDBI::Contact_Relationship' => 'type_id');
   
Bio::Chado::CDBI::Cvterm->has_many('pub_type_id', 'Bio::Chado::CDBI::Pub' => 'type_id');
  
sub pub_types { return shift->pub_type_id }
#sub --pub--type_id-- {}
   
Bio::Chado::CDBI::Cvterm->has_many('organismprop_type_id', 'Bio::Chado::CDBI::Organismprop' => 'type_id');
  
    
sub organismprops { return shift->organismprop_type_id }
      
Bio::Chado::CDBI::Cvterm->has_many('dbxrefprop_type_id', 'Bio::Chado::CDBI::Dbxrefprop' => 'type_id');
  
    
sub dbxrefprops { return shift->dbxrefprop_type_id }
      
Bio::Chado::CDBI::Cvterm->has_many('feature_relationship_type_id', 'Bio::Chado::CDBI::Feature_Relationship' => 'type_id');
  
    
sub feature_relationships { return shift->feature_relationship_type_id }
      
Bio::Chado::CDBI::Cvterm->has_many('acquisition_relationship_type_id', 'Bio::Chado::CDBI::Acquisition_Relationship' => 'type_id');
  
    
sub acquisition_relationships { return shift->acquisition_relationship_type_id }
      
Bio::Chado::CDBI::Cvterm->has_many('feature_cvtermprop_type_id', 'Bio::Chado::CDBI::Feature_Cvtermprop' => 'type_id');
  
    
sub feature_cvtermprops { return shift->feature_cvtermprop_type_id }
      
Bio::Chado::CDBI::Cvterm->has_many('protocol_type_id', 'Bio::Chado::CDBI::Protocol' => 'type_id');
  
    
sub protocols { return shift->protocol_type_id }
      
Bio::Chado::CDBI::Cvterm->has_many('feature_type_id', 'Bio::Chado::CDBI::Feature' => 'type_id');
  
sub feature_types { return shift->feature_type_id }
#sub --feature--type_id-- {}
   
Bio::Chado::CDBI::Cvterm->has_many('feature_pubprop_type_id', 'Bio::Chado::CDBI::Feature_Pubprop' => 'type_id');
  
    
sub feature_pubprops { return shift->feature_pubprop_type_id }
      
Bio::Chado::CDBI::Cvterm->has_many('biomaterialprop_type_id', 'Bio::Chado::CDBI::Biomaterialprop' => 'type_id');
  
    
sub biomaterialprops { return shift->biomaterialprop_type_id }
      
Bio::Chado::CDBI::Cvterm->has_many('cvterm_dbxref_cvterm_id', 'Bio::Chado::CDBI::Cvterm_Dbxref' => 'cvterm_id');
  
    
sub cvterm_dbxrefs { return shift->cvterm_dbxref_cvterm_id }
      
Bio::Chado::CDBI::Cvterm->has_many('feature_relationshipprop_type_id', 'Bio::Chado::CDBI::Feature_Relationshipprop' => 'type_id');
  
    
sub feature_relationshipprops { return shift->feature_relationshipprop_type_id }
      
Bio::Chado::CDBI::Cvterm->has_many('stockcollectionprop_type_id', 'Bio::Chado::CDBI::Stockcollectionprop' => 'type_id');
  
    
sub stockcollectionprops { return shift->stockcollectionprop_type_id }
      
Bio::Chado::CDBI::Cvterm->has_many('element_relationship_type_id', 'Bio::Chado::CDBI::Element_Relationship' => 'type_id');
  
    
sub element_relationships { return shift->element_relationship_type_id }
      
Bio::Chado::CDBI::Cvterm->has_many('stock_type_id', 'Bio::Chado::CDBI::Stock' => 'type_id');
  
sub stock_types { return shift->stock_type_id }
#sub --stock--type_id-- {}
   
Bio::Chado::CDBI::Cvterm->has_many('featuremap_unittype_id', 'Bio::Chado::CDBI::Featuremap' => 'unittype_id');
  
    
sub featuremaps { return shift->featuremap_unittype_id }
      
Bio::Chado::CDBI::Cvterm->has_many('studyprop_feature_type_id', 'Bio::Chado::CDBI::Studyprop_Feature' => 'type_id');
   
Bio::Chado::CDBI::Cvterm->has_many('libraryprop_type_id', 'Bio::Chado::CDBI::Libraryprop' => 'type_id');
  
    
sub libraryprops { return shift->libraryprop_type_id }
      
Bio::Chado::CDBI::Cvterm->has_many('analysisfeatureprop_type_id', 'Bio::Chado::CDBI::Analysisfeatureprop' => 'type_id');
  
    
sub analysisfeatureprops { return shift->analysisfeatureprop_type_id }
      
Bio::Chado::CDBI::Cvterm->has_many('featureprop_type_id', 'Bio::Chado::CDBI::Featureprop' => 'type_id');
  
    
sub featureprops { return shift->featureprop_type_id }
      
Bio::Chado::CDBI::Cvterm->has_many('phylonode_relationship_type_id', 'Bio::Chado::CDBI::Phylonode_Relationship' => 'type_id');
  
    
sub phylonode_relationships { return shift->phylonode_relationship_type_id }
      
Bio::Chado::CDBI::Cvterm->has_many('protocolparam_datatype_id', 'Bio::Chado::CDBI::Protocolparam' => 'datatype_id');
  
    
sub protocolparam_datatype_ids { my $self = shift; return $self->protocolparam_datatype_id(@_) }
      
Bio::Chado::CDBI::Cvterm->has_many('protocolparam_unittype_id', 'Bio::Chado::CDBI::Protocolparam' => 'unittype_id');
  
    
sub protocolparam_unittype_ids { my $self = shift; return $self->protocolparam_unittype_id(@_) }
      
Bio::Chado::CDBI::Cvterm->has_many('control_type_id', 'Bio::Chado::CDBI::Control' => 'type_id');
  
    
sub controls { return shift->control_type_id }
      
Bio::Chado::CDBI::Cvterm->has_many('phendesc_type_id', 'Bio::Chado::CDBI::Phendesc' => 'type_id');
  
    
sub phendescs { return shift->phendesc_type_id }
      
Bio::Chado::CDBI::Cvterm->has_many('feature_expressionprop_type_id', 'Bio::Chado::CDBI::Feature_Expressionprop' => 'type_id');
  
    
sub feature_expressionprops { return shift->feature_expressionprop_type_id }
      
Bio::Chado::CDBI::Cvterm->has_many('pub_relationship_type_id', 'Bio::Chado::CDBI::Pub_Relationship' => 'type_id');
   
Bio::Chado::CDBI::Cvterm->has_many('studyfactor_type_id', 'Bio::Chado::CDBI::Studyfactor' => 'type_id');
  
    
sub studyfactors { return shift->studyfactor_type_id }
      
Bio::Chado::CDBI::Cvterm->has_many('phylonodeprop_type_id', 'Bio::Chado::CDBI::Phylonodeprop' => 'type_id');
  
    
sub phylonodeprops { return shift->phylonodeprop_type_id }
      
Bio::Chado::CDBI::Cvterm->has_many('stock_cvterm_cvterm_id', 'Bio::Chado::CDBI::Stock_Cvterm' => 'cvterm_id');
   
Bio::Chado::CDBI::Cvterm->has_many('cell_line_cvterm_cvterm_id', 'Bio::Chado::CDBI::Cell_Line_Cvterm' => 'cvterm_id');
  
    
sub cell_line_cvterms { return shift->cell_line_cvterm_cvterm_id }
      
Bio::Chado::CDBI::Cvterm->has_many('cvtermprop_cvterm_id', 'Bio::Chado::CDBI::Cvtermprop' => 'cvterm_id');
  
    
sub cvtermprop_cvterm_ids { my $self = shift; return $self->cvtermprop_cvterm_id(@_) }
      
Bio::Chado::CDBI::Cvterm->has_many('cvtermprop_type_id', 'Bio::Chado::CDBI::Cvtermprop' => 'type_id');
  
    
sub cvtermprop_type_ids { my $self = shift; return $self->cvtermprop_type_id(@_) }
      
Bio::Chado::CDBI::Cvterm->has_many('element_type_id', 'Bio::Chado::CDBI::Element' => 'type_id');
   
Bio::Chado::CDBI::Cvterm->has_many('arraydesignprop_type_id', 'Bio::Chado::CDBI::Arraydesignprop' => 'type_id');
  
    
sub arraydesignprops { return shift->arraydesignprop_type_id }
      
Bio::Chado::CDBI::Cvterm->has_many('biomaterial_treatment_unittype_id', 'Bio::Chado::CDBI::Biomaterial_Treatment' => 'unittype_id');
  
    
sub biomaterial_treatments { return shift->biomaterial_treatment_unittype_id }
      
Bio::Chado::CDBI::Cvterm->has_many('expressionprop_type_id', 'Bio::Chado::CDBI::Expressionprop' => 'type_id');
  
    
sub expressionprops { return shift->expressionprop_type_id }
      
Bio::Chado::CDBI::Cvterm->has_many('acquisitionprop_type_id', 'Bio::Chado::CDBI::Acquisitionprop' => 'type_id');
  
    
sub acquisitionprops { return shift->acquisitionprop_type_id }
      
Bio::Chado::CDBI::Cvterm->has_many('studydesignprop_type_id', 'Bio::Chado::CDBI::Studydesignprop' => 'type_id');
  
    
sub studydesignprops { return shift->studydesignprop_type_id }
      
Bio::Chado::CDBI::Cvterm->has_many('environment_cvterm_cvterm_id', 'Bio::Chado::CDBI::Environment_Cvterm' => 'cvterm_id');
   
Bio::Chado::CDBI::Cvterm->has_many('cell_line_cvtermprop_type_id', 'Bio::Chado::CDBI::Cell_Line_Cvtermprop' => 'type_id');
  
    
sub cell_line_cvtermprops { return shift->cell_line_cvtermprop_type_id }
      
Bio::Chado::CDBI::Cvterm->has_many('studyprop_type_id', 'Bio::Chado::CDBI::Studyprop' => 'type_id');
  
sub studyprop_types { return shift->studyprop_type_id }
#sub --studyprop--type_id-- {}
   
Bio::Chado::CDBI::Cvterm->has_many('elementresult_relationship_type_id', 'Bio::Chado::CDBI::Elementresult_Relationship' => 'type_id');
  
    
sub elementresult_relationships { return shift->elementresult_relationship_type_id }
      
Bio::Chado::CDBI::Cvterm->has_many('phylonode_type_id', 'Bio::Chado::CDBI::Phylonode' => 'type_id');
  
    
sub phylonodes { return shift->phylonode_type_id }
      
Bio::Chado::CDBI::Cvterm->has_many('cvtermsynonym_cvterm_id', 'Bio::Chado::CDBI::Cvtermsynonym' => 'cvterm_id');
  
    
sub cvtermsynonym_cvterm_ids { my $self = shift; return $self->cvtermsynonym_cvterm_id(@_) }
      
Bio::Chado::CDBI::Cvterm->has_many('cvtermsynonym_type_id', 'Bio::Chado::CDBI::Cvtermsynonym' => 'type_id');
  
    
sub cvtermsynonym_type_ids { my $self = shift; return $self->cvtermsynonym_type_id(@_) }
      
Bio::Chado::CDBI::Cvterm->has_many('cell_lineprop_type_id', 'Bio::Chado::CDBI::Cell_Lineprop' => 'type_id');
  
    
sub cell_lineprops { return shift->cell_lineprop_type_id }
      
Bio::Chado::CDBI::Cvterm->has_many('stock_relationship_type_id', 'Bio::Chado::CDBI::Stock_Relationship' => 'type_id');
  
    
sub stock_relationships { return shift->stock_relationship_type_id }
      
Bio::Chado::CDBI::Cvterm->has_many('stockcollection_type_id', 'Bio::Chado::CDBI::Stockcollection' => 'type_id');
  
    
sub stockcollections { return shift->stockcollection_type_id }
      
Bio::Chado::CDBI::Cvterm->has_many('library_cvterm_cvterm_id', 'Bio::Chado::CDBI::Library_Cvterm' => 'cvterm_id');
   
Bio::Chado::CDBI::Cvterm->has_many('analysisprop_type_id', 'Bio::Chado::CDBI::Analysisprop' => 'type_id');
  
    
sub analysisprops { return shift->analysisprop_type_id }
      
Bio::Chado::CDBI::Cvterm->has_many('treatment_type_id', 'Bio::Chado::CDBI::Treatment' => 'type_id');
  
    
sub treatments { return shift->treatment_type_id }
      
Bio::Chado::CDBI::Cvterm->has_many('pubprop_type_id', 'Bio::Chado::CDBI::Pubprop' => 'type_id');
  
    
sub pubprops { return shift->pubprop_type_id }
      
Bio::Chado::CDBI::Cvterm->has_many('quantificationprop_type_id', 'Bio::Chado::CDBI::Quantificationprop' => 'type_id');
  
    
sub quantificationprops { return shift->quantificationprop_type_id }
      
Bio::Chado::CDBI::Cvterm->has_many('expression_cvterm_cvterm_id', 'Bio::Chado::CDBI::Expression_Cvterm' => 'cvterm_id');
  
    
sub expression_cvterm_cvterm_ids { my $self = shift; return $self->expression_cvterm_cvterm_id(@_) }
      
Bio::Chado::CDBI::Cvterm->has_many('expression_cvterm_cvterm_type_id', 'Bio::Chado::CDBI::Expression_Cvterm' => 'cvterm_type_id');
  
    
sub expression_cvterm_cvterm_type_ids { my $self = shift; return $self->expression_cvterm_cvterm_type_id(@_) }
      
Bio::Chado::CDBI::Cvterm->has_many('contact_type_id', 'Bio::Chado::CDBI::Contact' => 'type_id');
  
    
sub contacts { return shift->contact_type_id }
      
Bio::Chado::CDBI::Cvterm->has_many('library_type_id', 'Bio::Chado::CDBI::Library' => 'type_id');
  
sub library_types { return shift->library_type_id }
#sub --library--type_id-- {}
   
Bio::Chado::CDBI::Cvterm->has_many('phenotype_cvterm_cvterm_id', 'Bio::Chado::CDBI::Phenotype_Cvterm' => 'cvterm_id');
  
    
sub phenotype_cvterms { return shift->phenotype_cvterm_cvterm_id }
      
Bio::Chado::CDBI::Cvterm->has_many('feature_genotype_cvterm_id', 'Bio::Chado::CDBI::Feature_Genotype' => 'cvterm_id');
  
    
sub feature_genotypes { return shift->feature_genotype_cvterm_id }
      
Bio::Chado::CDBI::Cvterm->has_many('stockprop_type_id', 'Bio::Chado::CDBI::Stockprop' => 'type_id');
  
    
sub stockprops { return shift->stockprop_type_id }
        
Bio::Chado::CDBI::Cvterm->has_many('phenstatement_type_id', 'Bio::Chado::CDBI::Phenstatement' => 'type_id');
   
Bio::Chado::CDBI::Cvterm->has_many('expression_cvtermprop_type_id', 'Bio::Chado::CDBI::Expression_Cvtermprop' => 'type_id');
  
    
sub expression_cvtermprops { return shift->expression_cvtermprop_type_id }
      
Bio::Chado::CDBI::Cvterm->has_many('phenotype_observable_id', 'Bio::Chado::CDBI::Phenotype' => 'observable_id');
  
sub phenotype_observables { return shift->phenotype_observable_id }
#sub --phenotype--observable_id-- {}
   
Bio::Chado::CDBI::Cvterm->has_many('phenotype_attr_id', 'Bio::Chado::CDBI::Phenotype' => 'attr_id');
  
sub phenotype_attrs { return shift->phenotype_attr_id }
#sub --phenotype--attr_id-- {}
   
Bio::Chado::CDBI::Cvterm->has_many('phenotype_cvalue_id', 'Bio::Chado::CDBI::Phenotype' => 'cvalue_id');
  
sub phenotype_cvalues { return shift->phenotype_cvalue_id }
#sub --phenotype--cvalue_id-- {}
   
Bio::Chado::CDBI::Cvterm->has_many('phenotype_assay_id', 'Bio::Chado::CDBI::Phenotype' => 'assay_id');
  
sub phenotype_assays { return shift->phenotype_assay_id }
#sub --phenotype--assay_id-- {}
   
Bio::Chado::CDBI::Cvterm->has_many('phylotree_type_id', 'Bio::Chado::CDBI::Phylotree' => 'type_id');
  
    
sub phylotrees { return shift->phylotree_type_id }
     



#
# Has Compound Many (many to many relationships in all their flavors)
#
 
  
  
sub library_cvterm_cvterms { return shift->library_cvterm_cvterm_id }
 
 
  
sub library_cvterm_cvterms { return shift->library_cvterm_cvterm_id }

   
 
  
  
sub element_types { return shift->element_type_id }
 
 
  
sub element_types { return shift->element_type_id }

   
 
  
  
sub element_types { return shift->element_type_id }
 
 
  
  
sub studyprop_feature_types { return shift->studyprop_feature_type_id }
 
 
  
  
sub studyprop_feature_types { return shift->studyprop_feature_type_id }
 
 
  
  
  
sub pub_relationship_types { return shift->pub_relationship_type_id }
 
 
  
  
  
sub cell_line_relationship_types { return shift->cell_line_relationship_type_id }
 
 
  
  
sub environment_cvterm_cvterms { return shift->environment_cvterm_cvterm_id }
 
 
  
sub contact_relationship_types { return shift->contact_relationship_type_id }

  
   
 
  
  
sub quantification_relationship_types { return shift->quantification_relationship_type_id }

   
 
  
sub stock_cvterm_cvterms { return shift->stock_cvterm_cvterm_id }

   
 
  
  
sub stock_cvterm_cvterms { return shift->stock_cvterm_cvterm_id }
 
 
  
  
sub biomaterial_relationship_types { return shift->biomaterial_relationship_type_id }

   
 
  
sub cvterm_relationship_types { return shift->cvterm_relationship_type_id }

  
sub cvterm_relationship_subjects { return shift->cvterm_relationship_subject_id }

  
sub cvterm_relationship_objects { return shift->cvterm_relationship_object_id }
 
 
  
  
sub phenstatement_types { return shift->phenstatement_type_id }
 
 
  
  
sub phenstatement_types { return shift->phenstatement_type_id }
 
 
  
sub phenstatement_types { return shift->phenstatement_type_id }

   
 
  
  
sub phenstatement_types { return shift->phenstatement_type_id }
 
# one to many to one
 
  
# one2one #
sub librarys { my $self = shift; return map $_->library_id, $self->library_cvterm_cvterm_id }

  

sub pubs { my $self = shift; return map $_->pub_id, $self->library_cvterm_cvterm_id }

  

sub features { my $self = shift; return map $_->feature_id, $self->element_type_id }

  

sub dbxrefs { my $self = shift; return map $_->dbxref_id, $self->element_type_id }

  

sub arraydesigns { my $self = shift; return map $_->arraydesign_id, $self->element_type_id }

  

sub studyprops { my $self = shift; return map $_->studyprop_id, $self->studyprop_feature_type_id }

  

sub features { my $self = shift; return map $_->feature_id, $self->studyprop_feature_type_id }

  
  
  

sub environments { my $self = shift; return map $_->environment_id, $self->environment_cvterm_cvterm_id }

  
  
  

sub pubs { my $self = shift; return map $_->pub_id, $self->stock_cvterm_cvterm_id }

  

sub stocks { my $self = shift; return map $_->stock_id, $self->stock_cvterm_cvterm_id }

  
  

sub genotypes { my $self = shift; return map $_->genotype_id, $self->phenstatement_type_id }

  

sub environments { my $self = shift; return map $_->environment_id, $self->phenstatement_type_id }

  

sub pubs { my $self = shift; return map $_->pub_id, $self->phenstatement_type_id }

  

sub phenotypes { my $self = shift; return map $_->phenotype_id, $self->phenstatement_type_id }

# one to many to many
 
  
  
  
  
  
  
  
  
# one2many #
  
  
  
    
sub pub_relationship_subjects { my $self = shift; return map $_->subject_id, $self->pub_relationship_type_id }
    
  
     
  

  
  
  
    
sub cell_line_relationship_subjects { my $self = shift; return map $_->subject_id, $self->cell_line_relationship_type_id }
    
  
     
  
  

  
  
  
    
sub contact_relationship_subjects { my $self = shift; return map $_->subject_id, $self->contact_relationship_type_id }
    
  
     
  

  
  
  
    
sub quantification_relationship_subjects { my $self = shift; return map $_->subject_id, $self->quantification_relationship_type_id }
    
  
     
  
  
  

  
  
  
    
sub biomaterial_relationship_subjects { my $self = shift; return map $_->subject_id, $self->biomaterial_relationship_type_id }
    
  
     
  
  
  
  
#many to many to one
 
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
#many to many to many


  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
   

1;

########Bio::Chado::CDBI::Phenstatement########

package Bio::Chado::CDBI::Phenstatement;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Phenstatement->set_up_table('phenstatement');

#
# Primary key accessors
#

sub id { shift->phenstatement_id }
sub phenstatement { shift->phenstatement_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Phenstatement->has_a(genotype_id => 'Bio::Chado::CDBI::Genotype');
    
sub Bio::Chado::CDBI::Phenstatement::genotype { return shift->genotype_id }
      
 
Bio::Chado::CDBI::Phenstatement->has_a(environment_id => 'Bio::Chado::CDBI::Environment');
    
sub Bio::Chado::CDBI::Phenstatement::environment { return shift->environment_id }
      
 
Bio::Chado::CDBI::Phenstatement->has_a(phenotype_id => 'Bio::Chado::CDBI::Phenotype');
    
sub Bio::Chado::CDBI::Phenstatement::phenotype { return shift->phenotype_id }
      
 
Bio::Chado::CDBI::Phenstatement->has_a(type_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Phenstatement::cvterm { return shift->type_id }
      
 
Bio::Chado::CDBI::Phenstatement->has_a(pub_id => 'Bio::Chado::CDBI::Pub');
    
sub Bio::Chado::CDBI::Phenstatement::pub { return shift->pub_id }
       

#
# Has Many
#
     


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Environment########

package Bio::Chado::CDBI::Environment;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Environment->set_up_table('environment');

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
 
Bio::Chado::CDBI::Environment->has_many('phendesc_environment_id', 'Bio::Chado::CDBI::Phendesc' => 'environment_id');
  
    
sub phendescs { return shift->phendesc_environment_id }
      
Bio::Chado::CDBI::Environment->has_many('environment_cvterm_environment_id', 'Bio::Chado::CDBI::Environment_Cvterm' => 'environment_id');
   
Bio::Chado::CDBI::Environment->has_many('phenotype_comparison_environment1_id', 'Bio::Chado::CDBI::Phenotype_Comparison' => 'environment1_id');
   
Bio::Chado::CDBI::Environment->has_many('phenotype_comparison_environment2_id', 'Bio::Chado::CDBI::Phenotype_Comparison' => 'environment2_id');
   
Bio::Chado::CDBI::Environment->has_many('phenstatement_environment_id', 'Bio::Chado::CDBI::Phenstatement' => 'environment_id');
  



#
# Has Compound Many (many to many relationships in all their flavors)
#
 
  
sub phenotype_comparison_environment1s { return shift->phenotype_comparison_environment1_id }

  
sub phenotype_comparison_environment2s { return shift->phenotype_comparison_environment2_id }

   
 
  
  
sub phenotype_comparison_environment1s { return shift->phenotype_comparison_environment1_id }

  
  
sub phenotype_comparison_environment2s { return shift->phenotype_comparison_environment2_id }
 
 
  
sub phenotype_comparison_environment1s { return shift->phenotype_comparison_environment1_id }

  
sub phenotype_comparison_environment2s { return shift->phenotype_comparison_environment2_id }

   
 
  
sub phenotype_comparison_environment1s { return shift->phenotype_comparison_environment1_id }

  
sub phenotype_comparison_environment2s { return shift->phenotype_comparison_environment2_id }

  
   
 
  
sub environment_cvterm_environments { return shift->environment_cvterm_environment_id }

   
 
  
sub phenstatement_environments { return shift->phenstatement_environment_id }

   
 
  
  
sub phenstatement_environments { return shift->phenstatement_environment_id }
 
 
  
sub phenstatement_environments { return shift->phenstatement_environment_id }

   
 
  
sub phenstatement_environments { return shift->phenstatement_environment_id }

   
# one to many to one
 
  
  
  
  
  
# one2one #
sub cvterms { my $self = shift; return map $_->cvterm_id, $self->environment_cvterm_environment_id }

  

sub cvterms { my $self = shift; return map $_->type_id, $self->phenstatement_environment_id }

  

sub genotypes { my $self = shift; return map $_->genotype_id, $self->phenstatement_environment_id }

  

sub pubs { my $self = shift; return map $_->pub_id, $self->phenstatement_environment_id }

  

sub phenotypes { my $self = shift; return map $_->phenotype_id, $self->phenstatement_environment_id }

# one to many to many
 
  
  
  
  
  
  
  
  
  
#many to many to one
 
  
# many2one #
  
  
sub phenotype_comparison_environment1_organisms { my $self = shift; return map $_->organism_id, $self->phenotype_comparison_environment1_id }
    
  
sub phenotype_comparison_environment2_organisms { my $self = shift; return map $_->organism_id, $self->phenotype_comparison_environment2_id }
    
   
  
  

  
  
sub phenotype_comparison_environment1_pubs { my $self = shift; return map $_->pub_id, $self->phenotype_comparison_environment1_id }
    
  
sub phenotype_comparison_environment2_pubs { my $self = shift; return map $_->pub_id, $self->phenotype_comparison_environment2_id }
    
   
  
  
  
  
  
  
#many to many to many


  
  
# many2many #
  
  
    
    
sub phenotype_comparison_environment1_genotype1s { my $self = shift; return map $_->phenotype_comparison_genotype1s, $self->phenotype_comparison_environment1s }
      
    
sub phenotype_comparison_environment1_genotype2s { my $self = shift; return map $_->phenotype_comparison_genotype2s, $self->phenotype_comparison_environment1s }
      
    
    
  
    
    
sub phenotype_comparison_environment2_genotype1s { my $self = shift; return map $_->phenotype_comparison_genotype1s, $self->phenotype_comparison_environment2s }
      
    
sub phenotype_comparison_environment2_genotype2s { my $self = shift; return map $_->phenotype_comparison_genotype2s, $self->phenotype_comparison_environment2s }
      
    
    
   
  
  

  
  
    
    
sub phenotype_comparison_environment1_phenotype1s { my $self = shift; return map $_->phenotype_comparison_phenotype1s, $self->phenotype_comparison_environment1s }
      
    
sub phenotype_comparison_environment1_phenotype2s { my $self = shift; return map $_->phenotype_comparison_phenotype2s, $self->phenotype_comparison_environment1s }
      
    
    
  
    
    
sub phenotype_comparison_environment2_phenotype1s { my $self = shift; return map $_->phenotype_comparison_phenotype1s, $self->phenotype_comparison_environment2s }
      
    
sub phenotype_comparison_environment2_phenotype2s { my $self = shift; return map $_->phenotype_comparison_phenotype2s, $self->phenotype_comparison_environment2s }
      
    
    
   
  
  
  
  
   

1;

########Bio::Chado::CDBI::Studydesign########

package Bio::Chado::CDBI::Studydesign;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Studydesign->set_up_table('studydesign');

#
# Primary key accessors
#

sub id { shift->studydesign_id }
sub studydesign { shift->studydesign_id }
 



#
# Has A
#
  
  
 
Bio::Chado::CDBI::Studydesign->has_a(study_id => 'Bio::Chado::CDBI::Study');
    
sub Bio::Chado::CDBI::Studydesign::study { return shift->study_id }
       

#
# Has Many
#
 
Bio::Chado::CDBI::Studydesign->has_many('studyfactor_studydesign_id', 'Bio::Chado::CDBI::Studyfactor' => 'studydesign_id');
  
    
sub studyfactors { return shift->studyfactor_studydesign_id }
      
Bio::Chado::CDBI::Studydesign->has_many('studydesignprop_studydesign_id', 'Bio::Chado::CDBI::Studydesignprop' => 'studydesign_id');
  
    
sub studydesignprops { return shift->studydesignprop_studydesign_id }
      


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Expression_Cvtermprop########

package Bio::Chado::CDBI::Expression_Cvtermprop;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Expression_Cvtermprop->set_up_table('expression_cvtermprop');

#
# Primary key accessors
#

sub id { shift->expression_cvtermprop_id }
sub expression_cvtermprop { shift->expression_cvtermprop_id }
 



#
# Has A
#
 
Bio::Chado::CDBI::Expression_Cvtermprop->has_a(expression_cvterm_id => 'Bio::Chado::CDBI::Expression_Cvterm');
    
sub Bio::Chado::CDBI::Expression_Cvtermprop::expression_cvterm { return shift->expression_cvterm_id }
      
 
Bio::Chado::CDBI::Expression_Cvtermprop->has_a(type_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Expression_Cvtermprop::cvterm { return shift->type_id }
       

#
# Has Many
#
  


# one to many to one
 
# one to many to many
 
#many to many to one
 
#many to many to many

 

1;

########Bio::Chado::CDBI::Phenotype########

package Bio::Chado::CDBI::Phenotype;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Phenotype->set_up_table('phenotype');

#
# Primary key accessors
#

sub id { shift->phenotype_id }
sub phenotype { shift->phenotype_id }
 



#
# Has A
#
  
  
  
  
  
 
Bio::Chado::CDBI::Phenotype->has_a(observable_id => 'Bio::Chado::CDBI::Cvterm');
    
sub observable { return shift->observable_id }
      
 
Bio::Chado::CDBI::Phenotype->has_a(attr_id => 'Bio::Chado::CDBI::Cvterm');
    
sub attr { return shift->attr_id }
      
 
Bio::Chado::CDBI::Phenotype->has_a(cvalue_id => 'Bio::Chado::CDBI::Cvterm');
    
sub cvalue { return shift->cvalue_id }
      
 
Bio::Chado::CDBI::Phenotype->has_a(assay_id => 'Bio::Chado::CDBI::Cvterm');
    
sub assay { return shift->assay_id }
       

#
# Has Many
#
 
Bio::Chado::CDBI::Phenotype->has_many('feature_phenotype_phenotype_id', 'Bio::Chado::CDBI::Feature_Phenotype' => 'phenotype_id');
   
Bio::Chado::CDBI::Phenotype->has_many('phenotype_comparison_phenotype1_id', 'Bio::Chado::CDBI::Phenotype_Comparison' => 'phenotype1_id');
   
Bio::Chado::CDBI::Phenotype->has_many('phenotype_comparison_phenotype2_id', 'Bio::Chado::CDBI::Phenotype_Comparison' => 'phenotype2_id');
   
Bio::Chado::CDBI::Phenotype->has_many('phenotype_cvterm_phenotype_id', 'Bio::Chado::CDBI::Phenotype_Cvterm' => 'phenotype_id');
  
    
sub phenotype_cvterms { return shift->phenotype_cvterm_phenotype_id }
      
Bio::Chado::CDBI::Phenotype->has_many('phenstatement_phenotype_id', 'Bio::Chado::CDBI::Phenstatement' => 'phenotype_id');
      



#
# Has Compound Many (many to many relationships in all their flavors)
#
 
  
  
sub feature_phenotype_phenotypes { return shift->feature_phenotype_phenotype_id }
 
 
  
sub phenotype_comparison_phenotype1s { return shift->phenotype_comparison_phenotype1_id }

  
sub phenotype_comparison_phenotype2s { return shift->phenotype_comparison_phenotype2_id }

   
 
  
  
  
sub phenotype_comparison_phenotype1s { return shift->phenotype_comparison_phenotype1_id }

  
sub phenotype_comparison_phenotype2s { return shift->phenotype_comparison_phenotype2_id }
 
 
  
  
  
sub phenotype_comparison_phenotype1s { return shift->phenotype_comparison_phenotype1_id }

  
sub phenotype_comparison_phenotype2s { return shift->phenotype_comparison_phenotype2_id }
 
 
  
sub phenotype_comparison_phenotype1s { return shift->phenotype_comparison_phenotype1_id }

  
sub phenotype_comparison_phenotype2s { return shift->phenotype_comparison_phenotype2_id }

   
 
  
sub phenstatement_phenotypes { return shift->phenstatement_phenotype_id }

   
 
  
  
sub phenstatement_phenotypes { return shift->phenstatement_phenotype_id }
 
 
  
  
sub phenstatement_phenotypes { return shift->phenstatement_phenotype_id }
 
 
  
sub phenstatement_phenotypes { return shift->phenstatement_phenotype_id }

   
# one to many to one
 
  
# one2one #
sub features { my $self = shift; return map $_->feature_id, $self->feature_phenotype_phenotype_id }

  
  
  
  
  

sub cvterms { my $self = shift; return map $_->type_id, $self->phenstatement_phenotype_id }

  

sub genotypes { my $self = shift; return map $_->genotype_id, $self->phenstatement_phenotype_id }

  

sub environments { my $self = shift; return map $_->environment_id, $self->phenstatement_phenotype_id }

  

sub pubs { my $self = shift; return map $_->pub_id, $self->phenstatement_phenotype_id }

# one to many to many
 
  
  
  
  
  
  
  
  
  
#many to many to one
 
  
  
# many2one #
  
  
sub phenotype_comparison_phenotype1_organisms { my $self = shift; return map $_->organism_id, $self->phenotype_comparison_phenotype1_id }
    
  
sub phenotype_comparison_phenotype2_organisms { my $self = shift; return map $_->organism_id, $self->phenotype_comparison_phenotype2_id }
    
   
  
  
  

  
  
sub phenotype_comparison_phenotype1_pubs { my $self = shift; return map $_->pub_id, $self->phenotype_comparison_phenotype1_id }
    
  
sub phenotype_comparison_phenotype2_pubs { my $self = shift; return map $_->pub_id, $self->phenotype_comparison_phenotype2_id }
    
   
  
  
  
  
#many to many to many


  
  
  
# many2many #
  
  
    
    
sub phenotype_comparison_phenotype1_genotype1s { my $self = shift; return map $_->phenotype_comparison_genotype1s, $self->phenotype_comparison_phenotype1s }
      
    
sub phenotype_comparison_phenotype1_genotype2s { my $self = shift; return map $_->phenotype_comparison_genotype2s, $self->phenotype_comparison_phenotype1s }
      
    
    
  
    
    
sub phenotype_comparison_phenotype2_genotype1s { my $self = shift; return map $_->phenotype_comparison_genotype1s, $self->phenotype_comparison_phenotype2s }
      
    
sub phenotype_comparison_phenotype2_genotype2s { my $self = shift; return map $_->phenotype_comparison_genotype2s, $self->phenotype_comparison_phenotype2s }
      
    
    
   
  

  
  
    
    
sub phenotype_comparison_phenotype1_environment1s { my $self = shift; return map $_->phenotype_comparison_environment1s, $self->phenotype_comparison_phenotype1s }
      
    
sub phenotype_comparison_phenotype1_environment2s { my $self = shift; return map $_->phenotype_comparison_environment2s, $self->phenotype_comparison_phenotype1s }
      
    
    
  
    
    
sub phenotype_comparison_phenotype2_environment1s { my $self = shift; return map $_->phenotype_comparison_environment1s, $self->phenotype_comparison_phenotype2s }
      
    
sub phenotype_comparison_phenotype2_environment2s { my $self = shift; return map $_->phenotype_comparison_environment2s, $self->phenotype_comparison_phenotype2s }
      
    
    
   
  
  
  
  
   

1;

########Bio::Chado::CDBI::Phylotree########

package Bio::Chado::CDBI::Phylotree;
use base 'Bio::Chado::DBI';
use Class::DBI::Pager;
no warnings qw(redefine);

Bio::Chado::CDBI::Phylotree->set_up_table('phylotree');

#
# Primary key accessors
#

sub id { shift->phylotree_id }
sub phylotree { shift->phylotree_id }
 



#
# Has A
#
  
  
  
 
Bio::Chado::CDBI::Phylotree->has_a(dbxref_id => 'Bio::Chado::CDBI::Dbxref');
    
sub Bio::Chado::CDBI::Phylotree::dbxref { return shift->dbxref_id }
      
 
Bio::Chado::CDBI::Phylotree->has_a(type_id => 'Bio::Chado::CDBI::Cvterm');
    
sub Bio::Chado::CDBI::Phylotree::cvterm { return shift->type_id }
      
 
Bio::Chado::CDBI::Phylotree->has_a(analysis_id => 'Bio::Chado::CDBI::Analysis');
    
sub Bio::Chado::CDBI::Phylotree::analysis { return shift->analysis_id }
       

#
# Has Many
#
 
Bio::Chado::CDBI::Phylotree->has_many('phylotree_pub_phylotree_id', 'Bio::Chado::CDBI::Phylotree_Pub' => 'phylotree_id');
   
Bio::Chado::CDBI::Phylotree->has_many('phylonode_relationship_phylotree_id', 'Bio::Chado::CDBI::Phylonode_Relationship' => 'phylotree_id');
  
    
sub phylonode_relationships { return shift->phylonode_relationship_phylotree_id }
      
Bio::Chado::CDBI::Phylotree->has_many('phylonode_phylotree_id', 'Bio::Chado::CDBI::Phylonode' => 'phylotree_id');
  
    
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

!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
