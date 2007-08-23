#!/usr/bin/perl -w
use strict;
use XML::DOM;

=head1 NAME

  WriteChadoMac.pm - A module to write chado xml elements

  Updated Version - can be used to produce macroized chado-xml

=head1 SYNOPSIS

 use XML::DOM;
 use WriteChadoMac;
 use PrettyPrintDom;
 $doc = new XML::DOM::Document;
 $feat_el = create_ch_feature(doc => $doc,
                              uniquename => 'Hoppy',
                              genus => 'Bufo'
                              species => 'marinus'
                              type => 'invader'
                              with_id => 1,
                              );

 pretty_print($feat_el,\*STDOUT);

 This module can be used to produce either verbose or macroized chado-xml

 NOTE: that this is not backward compatible with previous version that only 
       produced verbose chado-xml 

 Many of the elements are keyed by column name.
 HOWEVER, in some cases where a column is an _id column referencing fields from a different table
 then if the parameter is specified as column name (e.g. type_id) then an id referencing a previously
 defined element or an XML::DOM element itself is expected as the argument.  In a subset of these cases 
 there is a parameter of the same name as the _id column lacking the _id suffix (e.g. type).  These expect
 a string which will be converted into an element as appropriate and specified which is then added
 to the parent element.

 Check the method descriptions for allowed parameters.

 When producing macroized xml the caller is responsible for ensuring that a macro id 
 is assigned for an element that will be used later and must keep track of these ids.
 
 WARNING - for the most part garbage in means garbage out as there is not tons of
           error checking implemented

 FUNCTIONS EXIST TO CREATE CHADO XML FOR THE FOLLOWING 

 analysis and analysis_id
 analysisfeature
 contact and contact_id
 cv and cv_id
 cvterm
 cvtermprop
 cvterm_relationship
 db and db_id
 dbxref and dbxref_id
 environment and environment_id
 environment_cvterm
 expression and expression_id
 expression_cvterm
 expression_cvtermprop
 expression_pub
 expressionprop
 feature
 feature_cvterm
 feature_cvtermprop
 feature_dbxref
 feature_expression
 feature_expressionprop
 feature_genotype
 feature_pub
 feature_pubprop
 feature_relationship (can be either subject or object)
 feature_relationshipprop
 feature_relationshipprop_pub
 feature_relationship_pub
 feature_synonym
 featureloc
 featureloc_pub
 featureprop
 featureprop_pub
 genotype and genotype_id
 library and library_id
 libraryprop
 library_feature
 library_pub
 library_synonym
 organism and organism_id
 phendesc
 phenotype and phenotype_id
 phenotype_comparison
 phenotype_comparison_cvterm
 phenotype_cvterm
 phenstatement
 pub and pub_id
 pubauthor
 pubprop
 pub_dbxref
 pub_relationship
 synonym and synonym_id
 generic prop

=head1 DESCRIPTION

=head2 Methods

=over 12

=item C<create_ch_analysis>

 CREATE analysis or analysis_id element
 params 
 doc - XML::DOM::Document optional - required
 program - required string
 programversion - required string (usually a number) NOTE: can add default 1.0?
 sourcename - optional string NOTE: this is part of the unique key and while it can be it usually shouldn't be null
 name - optional string
 description - optional string
 algorithm - optional string
 sourceversion - optional string
 sourceuri -optional string
 timeexecuted - optional string value like '1999-01-08 04:05:06' default will be whenever data is added
                NOTE: not sure on xort-postgres interaction regarding invalid timestamp formats
 macro_id - string optional if provide then add an ID attribute to the top level element of provided value
 with_id - optional if true will create analysis_id at top level

=item C<create_ch_analysisfeature>

 CREATE analysisfeature element
 params 
 doc - XML::DOM::Document optional - required

 Parameters to make a feature element must either pass a feature_id or the other necessary bits
 feature_id - macro feature id or XML::DOM feature element
 uniquename - string
 organism_id - macro organism id or XML::DOM organism element
 genus - string
 species - string
 type_id -  macro id for feature type or XML::DOM cvterm element for type
 type - string valid SO feature type

 Parameters to make an analysis element must either pass analysis_id or required bits
 analysis_id - macro analysis id or XML::DOM analysis element
 program - string
 programversion - string
 sourcename - string

 Here are the optional bits that can be added to the analysisfeature
 rawscore - number (double) 
 normscore - number (double)  
 significance - number (double)
 identity - number (double)    

=item C<create_ch_contact>

 CREATE contact or contact_id element
 params
 doc - XML::DOM::Document optional - required
 name - string required
 description - string optional
 macro_id - optional string to specify as ID attribute for contact
 with_id - boolean optional if 1 then contact_id element is returned

=item C<create_ch_cv>

 CREATE cv or cv_id element
 params
 doc - XML::DOM::Document required
 name - string required
 definition - string optional
 macro_id - optional string to specify as ID attribute for cv
 with_id - boolean optional if 1 then cv_id element is returned

=item C<create_ch_cvterm>

 CREATE cvterm element
 params
 doc - XML::DOM::Document required
 name - string
 cv_id - macro id for cv or XML::DOM cv element
 cv - string = cvname
 definition - string optional
 dbxref_id - macro id for dbxref XML::DOM dbxref element
 is_obsolete - boolean optional default = 0
 is_relationshiptype - boolean optional default = 0
 macro_id - optional string to specify as ID attribute for cvterm
 no_lookup - boolean optional
 note that we don't have a with_id parameter because either it will be freestanding 
 term or will have another type of id (e.g. type_id)

 note: there are 2 unique keys on the cvterm table (name, cv_id, is_obsolete) and (dbxref_id)
 this method requires that all the info for at least one of the unique keys is present
 it is up to the to make sure that the right key is used upon loading

=item C<create_ch_cvtermprop>

 CREATE cvtermprop element
 params
 doc - XML::DOM::Document required
 cvterm_id - optional macro id for a cvterm or XML::DOM cvterm element for standalone cvtermprop
 value - string - not strictly required and in some cases this value is null in chado
 type_id - macro id for cvterm property type or XML::DOM cvterm element required
 type - string from cvterm_property_type cv
        Note: will default to making a cvtermprop from above cv unless cvname is provided
 cvname - string optional 
          but see above for type and do not provide if passing a cvterm element
 rank - integer with a default of zero so don't use unless you want a rank other than 0

=item C<create_ch_cvterm_relationship>

 CREATE cvterm_relationship element
 NOTE: this can now create a free standing cvterm relationship if you pass subject_id or object_id
 params
 doc - XML::DOM::Document required
 object _id - macro id for object feature or XML::DOM feature element
 subject_id - macro id for subject feature or XML::DOM feature element
 is_object - boolean 't'     Note: either is_subject OR is_object and NOT both must be passed
 is_subject - boolean 't'          this flag indicates if the cvterm info provided should be 
                                   added in as subject or object cvterm
 rtype_id -  macro for relationship type or XML::DOM cvterm element 
 rtype - string for relationship type note: if relationship name is given will be assigned to relationship_type cv
 (Note: currently all is_relationship = '0')
 cvterm_id - macro id for cvterm or XML::DOM cvterm element required unless name and cv info provided
 name - string
 cv_id - macro id for a cv or XML::DOM cv element
 cv - cv name string required if name and not cv_id
 dbxref_id - macro id for dbxref or XML::DOM dbxref element
 macro_id - optional string to add as ID attribute value to cvterm

 Alias: create_ch_cr

=item C<create_ch_db>

 CREATE db or db_id element
 params
 doc - XML::DOM::Document required
 name - string required
 contact_id - macro id for contact or XML::DOM contact element optional
 contact - string = contact name
 description - string optional
 urlprefix - string optional
 url - string optional
 macro_id - optional string to add as ID attribute value to db
 with_id - boolean optional if 1 then db_id element is returned

=item C<create_ch_dbxref>

 CREATE dbxref or dbxref_id element
 params
 doc - XML::DOM::Document required
 accession - string required
 db_id - macro id for db or XML::DOM db element required unless db
 db - string = db name required unless db_id
 version - string optional will default to ''
 description - string optional
 macro_id - optional string to add as ID attribute value to dbxref
 with_id - boolean optional if 1 then dbxref_id element is returned
 no_lookup - boolean optional

=item C<create_ch_environment>

 CREATE environment or environment_id element
 params
 doc - XML::DOM::Document optional - required
 uniquename - string required
 description - string optional
 with_id - boolean optional if 1 then expression_id element is returned
 macro_id - string to specify as id attribute of this element for later use

=item C<create_ch_environment_cvterm>

 CREATE environment_cvterm element
 params
 doc - XML::DOM::Document optional - required
 environment_id - macro id for environment of XML::DOM environment element
 uniquename - environment uniquename
 NOTE: you need to pass environment bits if attaching to existing cvterm element or 
       creating a freestanding environment_cvterm
 cvterm_id -  macro id for cvterm of XML::DOM cvterm element
 name - cvterm name
 cv_id - macro id for a CV or XML::DOM cv element
 cv - name of a cv
 is_obsolete - optional param for cvterm
 NOTE: you need to pass cvterm bits if attaching to existing environment element or 
       creating a freestanding environment_cvterm

=item C<create_ch_expression>

 CREATE expression or expression_id element
 params
 doc - XML::DOM::Document
 uniquename - string required
 description - string optional
 md5checksum - char(32) optional
 macro_id - optional string to add as ID attribute value to expression
 with_id - boolean optional if 1 then expression_id element is returned

=item C<create_ch_expression_cvterm>

 CREATE expression_cvterm 
 params
 doc - XML::DOM::Document - required
 expression_id - OPTIONAL macro expression id or XML::DOM expression element to create freestanding expression_cvterm
 cvterm_id - macro id for a cvterm or XML::DOM cvterm element - required unless name and cv params
 name - string name for cvterm required unless cvterm_id
 cv_id - macro id for cv or XML::DOM cv element required unless cvterm_id or cv provided
 cv - string = cvname required unless cvterm_id or cv_id provided
 cvterm_type_id - macro id for expression slot cvterm or XML::DOM cvterm element - required unless type
 cvterm_type - string from the expression slots cv
 rank - integer with default of 0 - this plus type_id used for ordering items 

=item C<create_ch_expression_cvtermprop>

 CREATE expression_cvtermprop
 params
 doc - XML::DOM::Document - require
 expression_cvterm_id - optional macro id for a expression_cvterm or XML::DOM expression_cvterm element 
                        for standalone expression_cvtermprop
 value - string
 type_id - macro id for a expression_cvtermprop type cvterm or XML::DOM cvterm element required
 type - string from expression_cvtermprop type cv
     Note: will default to making a cvtermprop from 'expression_cvtermprop type' cv unless cvname is provided
 cvname - string optional but see above for the default 
 rank - integer with a default of zero so don't use unless you want a rank other than 0


=item C<create_ch_expression_pub>

 CREATE expression_pub element
 Note that this is just calling create_ch_pub setting with_id = 1 
      and adding returned pub_id element as a child of expression_pub
      or just appending the pub element to expression_pub if that is passed 
 params
 doc - XML::DOM::Document required
 expression_id - OPTIONAL macro expression id or XML::DOM expression element to create freestanding expression_pub
 pub_id - macro id for pub or XML::DOM pub element - if this is used then pass this and doc (optional expression_id)  as only params
 uniquename - string for pub uniquename required unless pub_id
 type_id - macro id for pub type or XML::DOM cvterm element optional unless 
           creating a new pub (i.e. not null value but not part of unique key
 type - string from pub type cv same requirement as type_id
 title - optional string
 volumetitle - optional string
 volume - optional string
 series_name - optional string
 issue - optional string
 pyear - optional string
 pages - optional string
 miniref - optional string
 is_obsolete - optional string 't' boolean value with default = 'f'
 publisher - optional string

=item C<create_ch_expressionprop>

 CREATE expressionprop element
 params
 doc - XML::DOM::Document required
 expression_id - optional macro id for a expression or XML::DOM expression element for standalone expressionprop
 value - string - not strictly required but if you don't provide this then not much point
 type_id - macro id for property type or XML::DOM cvterm element required
 type - string from expressionprop type cv 
        Note: will default to making a featureprop from 'expressionprop type' cv unless cvname is provided
 cvname - string 'optional' but see above for type and do not provide if passing a cvterm element
 rank - integer with a default of zero so don't use unless you want a rank other than 0


=item C<create_ch_feature>

 CREATE feature element
 params
 doc - XML::DOM::Document required
 uniquename - string required
 type_id - macro id for cvterm or XML::DOM cvterm element required 
 type - string for a cvterm name Note: will default to using SO cv unless a cvname is provided
 cvname - string optional to specify a cv other than SO for the type_id
          do not use if providing a cvterm element to type_id
 organism_id - organism macro id or XML::DOM organism element required if no genus and species
 genus - string required if no organism
 species - string required if no organism
 dbxref_id - dbxref macro id or XML::DOM dbxref element optional
 name - string optional
 residue - string optional
 seqlen - integer optional (if seqlen = 0 pass as string)
 md5checksum - string optional
 is_analysis - boolean 't' or 'f' default = 'f' optional
 is_obsolete - boolean 't' or 'f' default = 'f' optional
 macro_id - optional string to add as ID attribute value to feature
 with_id - boolean optional if 1 then feature_id element is returned
 no_lookup - boolean optional

=item C<create_ch_feature_cvterm>

 CREATE feature_cvterm element
 params
 doc - XML::DOM::Document required
 feature_id - OPTIONAL macro feature id or XML::DOM feature element to create freestanding feature_cvterm
 cvterm_id - cvterm macro id or XML::DOM cvterm element unless other cvterm bits are provided
 name - string required unless cvterm_id provided
 cv_id - macro id for cv or XML::DOM cv element required unless cvterm_id provided
 cv - string = cvname
 pub_id - macro id for a pub or XML::DOM pub element required unless pub 
 pub - string pub uniquename Note: cannot create a new pub if uniquename provided
 is_not - optional boolean 't' or 'f' with default = 'f' so don't pass unless you know you want to change

=item C<create_ch_feature_cvtermprop>

 CREATE feature_cvtermprop element
 params
 doc - XML::DOM::Document required
 feature_cvterm_id - optional macro id for a feature_cvterm or XML::DOM feature_cvterm element 
                     for standalone feature_cvtermprop
 value - string - not strictly required but if you don't provide this then not much point
 type_id - macro id for feature_cvtermprop type or XML::DOM cvterm element required
 type -  string from  feature_cvtermprop type cv 
        Note: will default to making a featureprop from 'property type' cv unless cvname is provided
 cvname - string (probably want to pass 'feature_cvtermprop type') optional
          but see above for type and do not provide if passing a cvterm element
 rank - integer with a default of zero so don't use unless you want a rank other than 0

=item C<create_ch_feature_dbxref>

 CREATE feature_dbxref element
 params
 doc - XML::DOM::Document required
 feature_id - OPTIONAL macro feature id or XML::DOM feature element to create freestanding feature_dbxref
 dbxref_id - macro dbxref id or XML::DOM dbxref element - required unless accession and db provided
 accession - string required unless dbxref_id provided
 db_id - macro db id or XML::DOM db element required if accession and not db provided
 db - string = db name required if accession and not db_id provided
 version - string optional
 description - string optional
 is_current - string 't' or 'f' boolean default = 't' so don't pass unless
              this should be changed

=item C<create_ch_feature_expression>

 CREATE feature_expression element
 params
 doc - XML::DOM::Document required
 feature_id - OPTIONAL macro feature id or XML::DOM feature element to create freestanding feature_expression 
 expression_id - macro expression id or XML::DOM expression element - required unless uniquename provided
 uniquename - string required unless expression_id
 pub_id - macro pub id or XML::DOM pub element - required unless puname provided
 pub - string uniquename for pub (note will have lookup so can't create new pub here)

=item C<create_ch_feature_expressionprop>

 CREATE feature_expressionprop element
 params
 doc - XML::DOM::Document required
 feature_expression_id - optional macro id for a feature_expression or XML::DOM feature_expression element 
                         for standalone feature_expressionprop
 value - string - not strictly required but if you don't provide this then not much point
 type_id - macro id for feature_expressionprop type or XML::DOM cvterm element required
 type -  string from  expression_cvtermprop type cv 
        Note: will default to making a featureprop from 'expression_cvtermprop type' cv unless cvname is provided
 cvname - string (probably want to pass 'feature_expressionprop type') optional
          but see above for type and do not provide if passing a cvterm element
 rank - integer with a default of zero so don't use unless you want a rank other than 0

=item C<create_ch_feature_genotype>

 CREATE feature_genotype or feature_genotype_id element
 params
 doc - XML::DOM::Document - required
 feature_id - OPTIONAL macro feature id or XML::DOM feature element to create freestanding feature_genotype
 genotype_id - macro id for genotype or XML::DOM genotype element required unless uniquename
 uniquename - string = genotype uniquename
 chromosome_id - macro id for chromosome feature or XML::DOM feature element required
 cvterm_id - macro id for a cvterm or XML::DOM cvterm element required 
 rank - integer optional with default = 0
 cgroup - integer optional with default = 0

=item C<create_ch_feature_pub>

 CREATE feature_pub element
 Note that this is just calling create_ch_pub setting with_id = 1 
      and adding returned pub_id element as a child of feature_pub
      or just appending the pub element to feature_pub if that is passed 
 params
 doc - XML::DOM::Document required
 feature_id - OPTIONAL macro feature id or XML::DOM feature element to create freestanding feature_pub
 pub_id - macro id for pub or XML::DOM pub element - if this is used then pass this and doc (optional feature_id)  as only params
 uniquename - string for pub uniquename required unless pub_id
 type_id - macro id for pub type or XML::DOM cvterm element optional unless 
           creating a new pub (i.e. not null value but not part of unique key
 type - string from pub type cv same requirement as type_id
 title - optional string
 volumetitle - optional string
 volume - optional string
 series_name - optional string
 issue - optional string
 pyear - optional string
 pages - optional string
 miniref - optional string
 is_obsolete - optional string 't' boolean value with default = 'f'
 publisher - optional string

=item C<create_ch_feature_pubprop>

 CREATE feature_pubprop element
 params
 doc - XML::DOM::Document required
 feature_pub_id - optional macro id for a feature_pub or XML::DOM feature_pub element for standalone feature_pubprop
 value - string - not strictly required
 type_id - macro id for feature_pubprop type or XML::DOM cvterm element required 
 type - string from feature_pubprop type cv
        Note: will default to making a pubprop from above cv unless cvname is provided
 cvname - string optional 
          but see above for type and do not provide if passing a cvterm element
 rank - integer with a default of zero so don't use unless you want a rank other than 0

=item C<create_ch_fr>

 CREATE feature_relationship element
 NOTE: this can now create a free standing feature relationship if you pass subject_id or object_id
 params
 doc - XML::DOM::Document required
 object _id - macro id for object feature or XML::DOM feature element
 subject_id - macro id for subject feature or XML::DOM feature element
 NOTE you can pass one or both of the above parameters with the following rules:
    if only one of the two are passed then the converse is_{object,subject} param is assumed for creation of other feature
    if both are passed then is_object, is_subject and any parameters to create a feature are ignored
 is_object - boolean 't'     Note: either is_subject OR is_object and NOT both must be passed
 is_subject - boolean 't'          this flag indicates if the feature info provided should be 
                                   added in as subject or object feature
 rtype_id - macro id for cvterm or XML::DOM cvterm element
 rtype - string for relationship type note: if relationship name is given will be assigned to 'relationship type' cv
 rank - integer optional with default = 0
 feature_id - macro id for feature or XML::DOM feature element required unless minimal feature bits provided
 uniquename - string required unless feature_id provided
 organism_id - macro id for an organism or XML::DOM organism element required unless feature_id or (genus & species) provided
 genus - string required unless feature_id or organism_id provided
 species - string required unless feature_id or organism_id provided
 ftype_id -  macro id for cvterm or XML::DOM cvterm element required unless feature provided
 ftype - string = name of feature type 

 Alias: create_ch_feature_relationship
 Alias: create_ch_f_r

=item C<create_ch_frprop>

 CREATE feature_relationshipprop element
 params
 doc - XML::DOM::Document required
 feature_relationship_id - optional macro id for a feature_relationship or XML::DOM feature_relationship element 
                           for standalone feature_relationshipprop
 value - string - not strictly required but if you don't provide this then not much point
 type_id - macro id for a feature_relationshipprop type or XML::DOM cvterm element required
 type - string from feature_relationshipprop type cv 
        Note: will default to making a featureprop from above cv unless cvname is provided
 cvname - string optional 
          but see above for type and do not provide if passing a cvterm element
 rank - integer with a default of zero so don't use unless you want a rank other than 0

 Alias: create_ch_fr_prop is a synonym for backward compatibility
 Alias: create_ch_feature_relationshipprop
 Alias: create_ch_f_rprop

=item C<create_ch_frprop_pub>

 CREATE feature_relationshipprop_pub element
 Note that this is just calling create_ch_pub 
      and adding returned pub_id element as a child of feature_relationshipprop_pub
      or just appending the pub element to feature_relationshipprop_pub if that is passed
 params
 doc - XML::DOM::Document required
 feature_relationshipprop_id -optional feature_relationshipprop XML::DOM element or macro id
 pub_id - XML::DOM pub element - if this is used then pass this and doc as only params
 uniquename - string required
 type_id - macro id for pub type or XML::DOM cvterm element optional unless 
 type -  string from pub type cv 
 title - optional string
 volumetitle - optional string
 volume - optional string
 series_name - optional string
 issue - optional string
 pyear - optional string
 pages - optional string
 miniref - optional string
 is_obsolete - optional string 't' boolean value with default = 'f'
 publisher - optional string

 Alias: create_ch_feature_relationshipprop_pub
 Alias: create_ch_f_rprop_pub

=item C<create_ch_fr_pub>

 CREATE feature_relationship_pub element
 Note that this is just calling create_ch_pub 
      and adding returned pub_id element as a child of feature_relationship_pub
      or just appending the pub element to feature_relationship_pub if that is passed
 params
 doc - XML::DOM::Document required
 feature_relationship_id -optional feature_relationship XML::DOM element or macro id
 pub_id - XML::DOM pub element - if this is used then pass this and doc (and optional fr_id) as only params
 uniquename - string required
 type_id - macro id for pub type or XML::DOM cvterm element optional unless 
 type -  string from pub type cv 
 title - optional string
 volumetitle - optional string
 volume - optional string
 series_name - optional string
 issue - optional string
 pyear - optional string
 pages - optional string
 miniref - optional string
 is_obsolete - optional string 't' boolean value with default = 'f'
 publisher - optional string

 Alias: create_ch_feature_relationship_pub

=item C<create_ch_feature_synonym>

 CREATE feature_synonym element
 params
 doc - XML::DOM::Document required
 feature_id - OPTIONAL macro feature id or XML::DOM feature element to create freestanding feature_synonym
 synonym_id - macro id for synonym or XML::DOM synonym element required unless name and type provided
 name - string required unless synonym_id element provided
 type_id - macro id for cvterm or XML::DOM cvterm element required if name and not type
 type - string = name from the 'synonym type' cv required if name and type_id
 pub_id - macro id for a pub or a XML::DOM pub element required
 pub - a pub uniquename (i.e. FBrf)
 synonym_sgml - string optional but if not provided then synonym_sgml = name
               - do not provide if a synonym_id element is provided
 is_current - optional string = 'f' or 't' default is 't' so don't provide this param
               unless you know you want to change the value
 is_internal - optional string = 't' default is 'f' so don't provide this param
               unless you know you want to change the value

=item C<create_ch_featureloc>

 CREATE featureloc element
 params
 none of these parameters are strictly required and some warning is done
 but if you misbehave you could set up some funky featurelocs?
 srcfeature_id macro id for a feature or a XML::DOM feature element
 fmin - integer (NOTE: if fmin = 0 you can pass as string to avoid an error but it works ok even with error)
 fmax - integer
 strand - 1, 1 or 0 (0 must be passed as string or else will be undef)
 phase - int
 residue_info - string
 locgroup - int (default = 0 so don't pass unless you know its different)
 rank - int (default = 0 so don't pass unless you know its different)
 is_fmin_partial - boolean 't' or 'f' default = 'f'
 is_fmax_partial - boolean 't' or 'f' default = 'f'

=item C<create_ch_featureloc_pub>

 CREATE featureloc_pub element
 Note that this is just calling create_ch_pub setting with_id = 1 
      and adding returned pub_id element as a child of featureloc_pub
      or just appending the pub element to featureloc_pub if that is passed
 params
 doc - XML::DOM::Document required
 featureloc_id - OPTIONAL macro featureloc id or XML::DOM featureloc element to create freestanding featureloc_pub
 pub_id - macro id for pub or XML::DOM pub element - if this is used then pass this and doc (optional featureloc_id) as only params
 uniquename - string required unless pub_id
 type_id - macro id for a pub or XML::DOM cvterm element optional unless creating a new pub 
 type - string from pub type cv                          (i.e. not null value but not part of unique key
 title - optional string
 volumetitle - optional string
 volume - optional string
 series_name - optional string
 issue - optional string
 pyear - optional string
 pages - optional string
 miniref - optional string
 is_obsolete - optional string 't' boolean value with default = 'f'
 publisher - optional string

=item C<create_ch_featureprop>

 CREATE featureprop element
 params
 doc - XML::DOM::Document required
 feature_id - optional macro id for a feature or XML::DOM feature element for standalone featureprop
 value - string - not strictly required but if you don't provide this then not much point
 type_id - macro id for property type or XML::DOM cvterm element required
 type - string from property type cv 
        Note: will default to making a featureprop from 'property type' cv unless cvname is provided
 cvname - string 'optional' but see above for type and do not provide if passing a cvterm element
 rank - integer with a default of zero so don't use unless you want a rank other than 0

=item C<create_ch_featureprop_pub>

 CREATE featureprop_pub element
 Note that this is just calling create_ch_pub setting with_id = 1 
      and adding returned pub_id element as a child of featureprop_pub
      or just appending the pub element to featureprop_pub if that is passed
 params
 doc - XML::DOM::Document required
 featureprop_id  - OPTIONAL macro featureprop id or XML::DOM featureprop element to create freestanding featureprop_pub
 pub_id - macro id for pub or XML::DOM pub element - if this is used then pass this and doc as only params
 uniquename - string required unless pub_id
 type_id - macro id for a pub or XML::DOM cvterm element optional unless creating a new pub 
 type - string from pub type cv                          (i.e. not null value but not part of unique key
 title - optional string
 volumetitle - optional string
 volume - optional string
 series_name - optional string
 issue - optional string
 pyear - optional string
 pages - optional string
 miniref - optional string
 is_obsolete - optional string 't' boolean value with default = 'f'
 publisher - optional string

=item C<create_ch_genotype>

 CREATE genotype or genotype_id element
 params
 doc - XML::DOM::Document - required
 uniquenname - string required
 description - string optional
 name - string optional
 macro_id - optional string to specify as ID attribute for genotype
 with_id - boolean optional if 1 then genotype_id element is returned

=item C<create_ch_library>

 CREATE library or library_id element
 params
 doc - XML::DOM::Document
 uniquename - string required
 type_id - macro id for library type or XML::DOM cvterm element required
 type - string for library type from library type cv
 organism_id - macro_id for organism or XML::DOM organism element required if no genus and species
 genus - string required if no organism_id
 species - string required if no organism_id
 name - string optional
 macro_id -  optional string to specify as ID attribute for library
 with_id - boolean optional if 1 then db_id element is returned

=item C<create_ch_libraryprop>

 CREATE libraryprop element
 params
 doc - XML::DOM::Document required
 library_id - optional macro id for a library or XML::DOM library element for standalone libraryprop
 value - string - not strictly required but if you don't provide this then not much point
 type_id - macro id for a library property type or XML::DOM cvterm element required
 type - string from library property type cv
        Note: will default to making a featureprop from 'library property type' cv unless cvname is provided
 cvname - string 'optional' but see above for type and do not provide if passing a cvterm element
 rank - integer with a default of zero so don't use unless you want a rank other than 0

=item C<create_ch_library_feature>

 CREATE library_feature element
 params
 doc - XML::DOM::Document required
 organism_id - macro id for organism or XML::DOM organism element
 genus - string
 species - string
 NOTE: you can use the generic paramaters in the following cases:
       1.  you are only building either a library or feature element and not both
       2.  or both library and feature have the same organism
       otherwise use the prefixed parameters
 WARNING - if you provide both generic and prefixed parameters then the prefixed ones will be used
 library_id - macro id for library or XML::DOM library element
 lib_uniquename - string library uniquename
 lib_organism_id - macro id for organism or XML::DOM organism element to link to library
 lib_genus - string for genus for library organism
 lib_species - string for species for library organism
 lib_type_id - macro id for library type or XML::DOM cvterm element 
 lib_type - string for library type from library type cv
 feature_id - macro id for feature or XML::DOM feature element
 feat_uniquename - string feature uniquename
 feat_organism_id - macro id for organism or XML::DOM organism element to link to feature
 feat_genus - string for genus for feature organism
 feat_species - string for species for feature organism
 feat_type_id - macro id for feature type or XML::DOM cvterm element
 feat_type - string for feature type from SO cv

=item C<create_ch_library_pub>

 CREATE library_pub element
 Note that this is just calling create_ch_pub setting with_id = 1 
      and adding returned pub_id element as a child of library_pub
      or just appending the pub element to library_pub if that is passed
 params
 doc - XML::DOM::Document required
 library_id - OPTIONAL macro library id or XML::DOM featureloc element to create freestanding library_pub
 pub_id - macro id for pub or XML::DOM pub element - if this is used then pass this (optional library_id)  and doc as only params
 uniquename - string for pub uniquename required unless pub_id
 type_id - macro id for pub type or XML::DOM cvterm element optional unless 
           creating a new pub (i.e. not null value but not part of unique key
 type - string from pub type cv same requirement as type_id
 title - optional string
 volumetitle - optional string
 volume - optional string
 series_name - optional string
 issue - optional string
 pyear - optional string
 pages - optional string
 miniref - optional string
 is_obsolete - optional string 't' boolean value with default = 'f'
 publisher - optional string

=item C<create_ch_library_synonym>

 CREATE library_synonym element
 params
 doc - XML::DOM::Document required
 library_id - OPTIONAL macro library id or XML::DOM library element to create freestanding library_synonym
 synonym_id - macro id for synonym or XML::DOM synonym element required unless name and type provided
 name - string required unless synonym_id element provided
 type_id - macro id for cvterm or XML::DOM cvterm element required if name and not type
 type - string = name from the 'synonym type' cv required if name and type_id
 pub_id - macro id for a pub or a XML::DOM pub element required
 pub - a pub uniquename (i.e. FBrf)
 synonym_sgml - string optional but if not provided then synonym_sgml = name
               - do not provide if a synonym element is provided
 is_current - optional string = 'f' or 't' default is 't' so don't provide this param
               unless you know you want to change the value
 is_internal - optional string = 't' default is 'f' so don't provide this param
               unless you know you want to change the value

=item C<create_ch_organism>

 CREATE organism or organism_id element
 params
 doc - XML::DOM::Document
 genus - string required
 species - string required
 abbreviation - string optional
 common_name - string optional
 comment - string optional
 macro_id - optional string to add as ID attribute value to organism
 with_id - boolean optional if 1 then organism_id element is returned

=item C<create_ch_phendesc>

 CREATE phendesc element
 params
 doc - XML::DOM::Document required
 genotype_id - macro id for genotype or XML::DOM genotype element
 genotype - string genotype uniquename 
 environment_id - macro id for environment or XML::DOM environment element
 environment - string environment uniquename
 description - string optional but if creating a new phendesc this can't be null
 type_id - macro id for phendesc type or XML::DOM cvterm element
 type - string for cvterm name from phendesc type CV
 pub_id - macro id for pub or XML::DOM pub element
 pub - string pub uniquename

=item C<create_ch_phenotype>

 CREATE phenotype or phenotype_id element
 params
 doc - XML::DOM::Document required
 uniquename - string required
 observable_id - macro id for observable or XML::DOM cvterm element optional
 attr_id - macro id for attr or XML::DOM cvterm element optional
 cvalue_id - macro id for cvalue or XML::DOM cvterm element optional
 assay_id - macro id for assay or XML::DOM cvterm element optional
 value - string optional
 macro_id - optional string to specify as ID attribute for genotype
 with_id - boolean optional if 1 then genotype_id element is returned

=item C<create_ch_phenotype_comparison>

 CREATE phenotype_comparison element
 params
 doc - XML::DOM::Document required
 organism_id - macro id for an organism or XML::DOM organism element required unless genus and species
 genus - string required if no organism_id
 species - string required if no organism_id
 genotype1_id - macro id for a genotype or XML::DOM genotype element required unless genotype1
 genotype1 - string genotype uniquename required unless genotype1_id
 environment1_id - macro id for a environment or XML::DOM environment element required unless environment1
 environment1 - string environment uniquename required unless environment1_id
 genotype2_id - macro id for a genotype or XML::DOM genotype element required unless genotype2
 genotype2 - string genotype uniquename required unless genotype2_id
 environment2_id - macro id for a environment or XML::DOM environment element required unless environment2
 environment2 - string environment uniquename required unless environment2_id
 phenotype1_id - macro id for phenotype or XML::DOM phenotype element required unless phenotype1
 phenotype1 - string phenotype uniquename required unless phenotype1_id
 phenotype2_id - macro id for phenotype or XML::DOM phenotype element optional
 phenotype2 - string phenotype uniquename optional
 pub_id macro id for a pub or a XML::DOM pub element required unless pub
 pub - a pub uniquename (i.e. FBrf) required unless pub_id

 Alias: create_ch_ph_comp

=item C<create_ch_phenotype_comparison_cvterm>

 CREATE phenotype_comparison_cvterm element
 params
 doc - XML::DOM::Document optional - required
 phenotype_comparison_id - optional macro id for phenotype_comparison or phenotype_comparison XML::DOM element
 NOTE: to make a standalone element
 cvterm_id -  macro id for cvterm of XML::DOM cvterm element
 name - cvterm name
 cv_id - macro id for a CV or XML::DOM cv element
 cv - name of a cv
 is_obsolete - optional param for cvterm
 NOTE: you need to pass cvterm bits if attaching to existing phenotype element or 
       creating a freestanding phenotype_cvterm
 rank - optional with default = 0 so only pass if you want a different rank

 Alias: create_ch_ph_comp_cvt

=item C<create_ch_phenotype_cvterm>

 CREATE phenotype_cvterm element
 params
 doc - XML::DOM::Document optional - required
 phenotype_id - macro id for phenotype or XML::DOM phenotype element
 uniquename - phenotype uniquename
 NOTE: you need to pass phenotype bits if attaching to existing cvterm element or 
       creating a freestanding phenotype_cvterm
 cvterm_id -  macro id for cvterm of XML::DOM cvterm element
 name - cvterm name
 cv_id - macro id for a CV or XML::DOM cv element
 cv - name of a cv
 is_obsolete - optional param for cvterm
 NOTE: you need to pass cvterm bits if attaching to existing phenotype element or 
       creating a freestanding phenotype_cvterm
 rank - optional with default = 0 so only pass if you want a different rank

 Alias: create_ch_ph_cvt

=item C<create_ch_phenstatement>

 CREATE phenstatement element
 params
 doc - XML::DOM::Document required
 genotype_id - macro id for a genotype or XML::DOM genotype element required unless genotype
 genotype - string genotype uniquename required unless genotype_id
 environment_id - macro id for a environment or XML::DOM environment element required unless environment
 environment - string environment uniquename required unless environment_id
 phenotype_id - macro id for phenotype or XML::DOM phenotype element required unless phenotype
 phenotype - string phenotype uniquename required unless phenotype_id
 type_id - macro id for a phenstatement type or XML::DOM cvterm element
 pub_id - macro id for a pub or a XML::DOM pub element required unless pub
 pub - a pub uniquename (i.e. FBrf) required unless pub_id

=item C<create_ch_pub>

 CREATE pub or pub_id element
 params
 doc - XML::DOM::Document required
 uniquename - string required
 type_id - macro id for pub type or XML::DOM cvterm element optional unless 
        creating a new pub (i.e. not null value but not part of unique key
 type - string from pub type cv
 title - optional string
 volumetitle - optional string
 volume - optional string
 series_name - optional string
 issue - optional string
 pyear - optional string
 pages - optional string
 miniref - optional string
 is_obsolete - optional string 't' boolean value with default = 'f'
 publisher - optional string
 macro_id - optional string to add as ID attribute value to pub
 with_id - boolean optional if 1 then pub_id element is returned
 no_lookup - boolean optional

=item C<create_ch_pubauthor>

 CREATE pubauthor element
 params
 doc - XML::DOM::Document required
 pub_id -  macro pub id or XML::DOM pub element optional to create a freestanding pubauthor element
 pub - pub uniquename optional but required if making a freestanding element unless pub_id 
 rank - positive integer required 
 surname - string - required if creating a pubauthor element but optional for other operations
 editor - boolean 't' or 'f' default = 'f' so don't pass unless you want to change
 givennames - string optional
 suffix - string optional  

=item C<create_ch_pubprop>

 CREATE pubprop element
 params
 doc - XML::DOM::Document required
 pub_id - optional macro id for a pub or XML::DOM pub element for standalone pubprop
 value - string - not strictly required and in some cases this value is null in chado
 type_id - macro id for a pubprop type or XML::DOM cvterm element required
 type - string from pubprop type cv 
        Note: will default to making a pubprop from above cv unless cvname is provided
 cvname - string optional 
          but see above for type and do not provide if passing a cvterm element
 rank - integer with a default of zero so don't use unless you want a rank other than 0

=item C<create_ch_pub_dbxref>

 CREATE pub_dbxref element
 params
 doc - XML::DOM::Document required
 pub_id - macro pub id or XML::DOM pub element optional to create freestanding pub_dbxref
 dbxref_id - macro dbxref id or XML::DOM dbxref element - required unless accession and db provided
 accession - string required unless dbxref_id provided
 db_id - macro db id or XML::DOM db element required unless dbxref_id provided
 db - string name of db
 is_current - string 't' or 'f' boolean default = 't' so don't pass unless

=item C<create_ch_pub_relationship>

 CREATE pub_relationship element
NOTE: this can now create a free standing pub relationship if you pass subject_id or object_id
 params
 doc - XML::DOM::Document required
 object _id - macro id for object feature or XML::DOM feature element
 subject_id - macro id for subject feature or XML::DOM feature element
 is_object - boolean 't'     Note: either is_subject OR is_object and NOT both must be passed
 is_subject - boolean 't'          this flag indicates if the pub info provided should be 
                                   added in as subject or object pub
 rtype_id -  macro for relationship type or XML::DOM cvterm element 
 rtype - string for relationship type note: if relationship name is given will be assigned to relationship_type cv
 pub_id - macro id for a pub or XML::DOM pub element required unless uniquename provided
 uniquename - uniquename of the pub - required unless pub element provided
 type_id - macro id for a pub type or XML::DOM cvterm element for pub type
 type - string specifying pub type

 Alias: create_ch_pr

=item C<create_ch_synonym>

 CREATE synonym or synonym_id element
 params
 doc - XML::DOM::Document required
 name - string required
 synonym_sgml - string optional but if not provided then synonym_sgml = name
 type_id - macro id for synonym type or XML::DOM cvterm element
 type - string = name from the 'synonym type' cv
 macro_id - optional string to add as ID attribute value to synonym
 with_id - boolean optional if 1 then synonym_id element is returned

=item C<create_ch_prop>

 GENERIC METHOD FOR CREATING ANY TYPE OF PROP element
 params
 doc - XML::DOM::Document required
 parentname - string that is the name of the element that you want to attach the prop element to
              eg. pass 'feature' to make 'featureprop' element
 parent_id - macro id for the parent table or XML::DOM table_id element
             NOTE: name of this parameter should match table_id for 
             type of prop eg. feature_id for a featureprop or pub_id for pubprop
 value - string - not strictly required but if you don't provide this then not much point actually
 type_id - macro id for a property type or XML::DOM cvterm element required
 type - string from a property type cv 
           Note: will default to making a type of from 'tablenameprop type' cv unless cvname is provided
  WARNING: as property type cv names are not consistent SAFEST to provide cvname
 cvname - string 'optional' but see above for type and do not provide if passing a cvterm element
 rank - integer with a default of zero so don't use unless you want a rank other than 0

 NOTE: this method is now called by all the create_ch_xxxxprop methods which are really just
       wrappers that provide the most likely desired cvname for the property type unless you
       provide one

=item C<_create_simple_element>

 helper method that is called by functions to build simple table elements
 i.e. those that do not reference another table
 eg. contact, expression, genotype, organism

=item C<_build_element>

 helper method to build up elements

=back

=head1 AUTHOR

Andy Schroeder - andy@morgan.harvard.edu

=head1 SEE ALSO

PrettyPrintDom,  XML::DOM

=cut

# CREATE analysis or analysis_id element
# params 
# doc - XML::DOM::Document optional - required
# program - required string
# programversion - required string (usually a number) NOTE: can add default 1.0?
# sourcename - optional string NOTE: this is part of the unique key and while no constraint usually shouldn't be null
# name - optional string
# description - optional string
# algorithm - optional string
# sourceversion - optional string
# sourceuri -optional string
# timeexecuted - optional string value like '1999-01-08 04:05:06' default will be whenever data is added
#                NOTE: not sure on xort-postgres interaction regarding invalid timestamp formats
# macro_id - string optional if provide then add an ID attribute to the top level element of provided value
# with_id - optional if true will create analysis_id at top level
sub create_ch_analysis {
    my %params = @_;
    print "WARNING -- While 'sourcename' is not required it is usually useful to provide this and you haven't\n"
      unless $params{sourcename};
    $params{required} = ['program','programversion'];
    $params{elname} = 'analysis';
    my $ael = _create_simple_element(%params);
    return $ael;
}

# CREATE analysisfeature element
# params 
# doc - XML::DOM::Document optional - required
#
# Here are parameters to make a feature element must either pass a feature_id or the other necessary bits
# feature_id - macro feature id or XML::DOM feature element
# uniquename - string
# organism_id - macro organism id or XML::DOM organism element
# genus - string
# species - string
# type_id -  macro id for feature type or XML::DOM cvterm element for type
# type - string valid SO feature type
#
# Here are parameters to make an analysis element must either pass analysis_id or required bits
# analysis_id - macro analysis id or XML::DOM analysis element
# program - string
# programversion - string
# sourcename - string
#
# Here are the optional bits that can be added to the analysisfeature
# rawscore - number (double) 
# normscore - number (double)  
# significance - number (double)
# identity - number (double)    
sub create_ch_analysisfeature {
    my %params = @_;
    print "WARNING -- no XML::DOM::Document specified\n" and return unless $params{doc};
    my $ldoc = $params{doc};    ## XML::DOM::Document

    my $af_el = $ldoc->createElement('analysisfeature');

    # this first section identifies if a feature needs to be dealt with
    #create a feature element if params are provided
    if ($params{uniquename}) {
      print "You don't have all the parameters required to make a feature, NO GO!\n" and return
	unless ($params{organism_id} or ($params{genus} and $params{species})) and ($params{type_id} or $params{type});

      my @f_ok = qw(doc uniquename organism_id genus species type_id type); # valid feature parameters
      my %fparams;
      # populate the feature parameter hash 
      foreach my $p (keys %params) {
	if (grep $_ eq $p, @f_ok) {
	  $fparams{$p} = $params{$p};
	  delete $params{$p} unless $p eq 'doc';
	}
      }
      $params{feature_id} = create_ch_feature(%fparams);
    }
      
    # or if a macro id or existing element have been provided
    if ($params{feature_id}) {
      $af_el->appendChild(_build_element($ldoc,'feature_id',$params{feature_id}));
      delete $params{feature_id};
    }


    # and here we are dealing with analysis info if provided
    if ($params{program} or $params{programversion} or $params{sourcename}) {
      print "WARNING -- You are trying to make an analysis without providing both program and programversion, NO GO!\n"
	unless ($params{program} and $params{programversion});
      
      my @a_ok = qw(doc program programversion sourcename); # valid feature parameters
      my %aparams;
      # populate the feature parameter hash 
      foreach my $p (keys %params) {
	if (grep $_ eq $p, @a_ok) {
	  $aparams{$p} = $params{$p};
	  delete $params{$p} unless $p eq 'doc';
	}
      }
      $params{analysis_id} = create_ch_analysis(%aparams);
    }

    if ($params{analysis_id}) {
      $af_el->appendChild(_build_element($ldoc,'analysis_id',$params{analysis_id}));
      delete $params{analysis_id};
    }


    foreach my $e (keys %params) {
      next if ($e eq 'doc');
      print "WARNING -- $e should be a valid double number and it's not\n" 
	if $params{$e} !~  /[+-]?(\d+\.\d+|\d+\.|\.\d+)/;  # floating point, no exponent
      $af_el->appendChild(_build_element($ldoc,$e,$params{$e}));
    }    

    return $af_el;
}


# CREATE contact or contact_id element
# params
# doc - XML::DOM::Document optional - required
# name - string required
# description - string optional
# macro_id - string optional if provide then add an ID attribute to the top level element of provided value
# with_id - boolean optional if 1 then contact_id element is returned
sub create_ch_contact {
  my %params = @_;
  $params{elname} = 'contact';
  $params{required} = ['name'];
  my $eel = _create_simple_element(%params);
  return $eel;
}   

# CREATE cv or cv_id element
# params
# doc - XML::DOM::Document required
# name - string required
# definition - string optional
# macro_id - string optional if provide then add an ID attribute to the top level element of provided value
# with_id - boolean optional if 1 then cv_id element is returned
sub create_ch_cv {
  my %params = @_;
  $params{elname} = 'cv';
  $params{required} = ['name'];
  my $eel = _create_simple_element(%params);
  return $eel;
}

# CREATE cvterm element
# params
# doc - XML::DOM::Document required
# name - string required
# cv_id - string = macro_id or XML::DOM cv element required
# cv - name of a cv
# definition - string optional
# dbxref_id - macro_id string or XML::DOM dbxref element
# is_obsolete - boolean optional default = false
# is_relationshiptype - boolean optional
# macro_id - string optional if provide then add an ID attribute to the top level element of provided value 
# no_lookup - boolean option if 1 then default op="lookup" attribute will not be added to element
# note that we don't have a with_id parameter because either it will be freestanding 
# term or will have another type of id (e.g. type_id)
sub create_ch_cvterm {
    my %params = @_;
    print "WARNING -- no XML::DOM::Document specified\n" and return unless $params{doc};
    my $ldoc = $params{doc};    ## XML::DOM::Document

    # check for required parameters
    print "WARNING -- missing parameters required for at least one of the two unique keys on cvterm\n"
      and return
	unless ($params{dbxref_id} or ($params{name} and ($params{cv_id} or $params{cv})));

    ## cvterm element (will be returned)
    my $cvt_el = $ldoc->createElement('cvterm');
    $cvt_el->setAttribute('id',$params{macro_id}) if $params{macro_id};  

    # add an op="lookup" attribute unless no_lookup is specified
    unless ($params{no_lookup}) {
	$cvt_el->setAttribute('op','lookup');
    }

    # check for cv parameter and if present convert into cv_id element
    if ($params{cv}) {
      $params{cv_id} = create_ch_cv(doc => $ldoc,
				    name => $params{cv},);
      delete $params{cv};
    }

    foreach my $e (keys %params) {
	next if ($e eq 'doc' || $e eq 'macro_id' || $e eq 'no_lookup');
	$cvt_el->appendChild(_build_element($ldoc,$e,$params{$e}));
    }
  
    return $cvt_el;
}

sub create_ch_cvtermprop {
    my %params = @_;
    $params{parentname} = 'cvterm';
    unless ($params{type_id}) {
	$params{cvname} = 'cvterm_property_type' unless $params{cvname};
    }
    my $fp_el = create_ch_prop(%params);
    return $fp_el;
}



# CREATE cvterm_relationship element
# NOTE: this will create either a subject_id or object_id cvterm_relationship but 
# you have to attach this to the related cvterm elsewhere.
# params
# doc - XML::DOM::Document required
# is_object - boolean 't'     Note: either is_subject OR is_object and NOT both must be passed
# is_subject - boolean 't'          this flag indicates if the cvterm info provided should be 
#                                   added in as subject or object cvterm
# rtype_id - required macro id for relationship type cvterm or XML::DOM cvterm element unless rtype
# rtype - required string unless rtype_id provided
# note: if rtype is used cvterm will be assigned to 'relationship type' cv
# cvterm_id - macro id for cvterm or XML::DOM cvterm element required unless cvterm bits provided
# name - name of the cvterm - required unless cvterm element provided
# cv_id - macro id for cv or XML::DOM cv element required unless cv provided if you have a name
# cv - string name of a cv required unless cv_id if name provided
# dbxref_id - macro id for cvterm dbxref or XML::DOM dbxref element optional
# macro_id - string optional will add id attribute to cvterm element
sub create_ch_cvterm_relationship {
    my %params = @_;
    print "WARNING -- no XML::DOM::Document specified\n" and return unless $params{doc};
    my $ldoc = $params{doc};    ## XML::DOM::Document

    ## cvterm_relationship element (will be returned)
    my $fr_el = $ldoc->createElement('cvterm_relationship');

    # first deal with type
    my $rtype_el = $ldoc->createElement('type_id');
    if ($params{rtype}) {
      my $cvterm_el = create_ch_cvterm(doc => $ldoc,
				       name => $params{rtype},
				       cv => 'relationship type'
				       # note that we may want to add is_relationship = 1 in the future
				      );
      $rtype_el->appendChild($cvterm_el);
    } elsif (ref($params{rtype_id})) {
      $rtype_el->appendChild($params{rtype_id});
    } else {
      my $val = $ldoc->createTextNode("$params{rtype_id}");
      $rtype_el->appendChild($val);
    }

    $fr_el->appendChild($rtype_el);

    # now deal with various cvterm options
    if ($params{object_id}) { 
         # create the object_id element
	$fr_el->appendChild(_build_element($ldoc,'object_id',$params{object_id}));
	$params{is_subject} = 1 unless $params{subject_id};
    }

    if ($params{subject_id}) { 
         # create the subject_id element
	$fr_el->appendChild(_build_element($ldoc,'subject_id',$params{subject_id}));
	$params{is_object} = 1 unless $params{object_id};
    }

    return $fr_el if (defined($params{object_id})  and defined($params{subject_id}));
    
    # deal with creating the cvterm bits if present
    unless ($params{cvterm_id}) {
      print "WARNING -- missing required parameters for cvterm creation\n" and return
	unless $params{name} and ($params{cv} or $params{cv_id});

      my %cvt_params = (doc => $ldoc,
			name => $params{name},
		       );
      
      if ($params{cv_id}) {
	$cvt_params{cv_id} = $params{cv_id};
      } else {
	$cvt_params{cv} = $params{cv};
      }

      $cvt_params{dbxref_id} = $params{dbxref_id} if $params{dbxref_id};
      $cvt_params{macro_id} = $params{macro_id} if $params{macro_id};

      $params{cvterm_id} = create_ch_cvterm(%cvt_params);
    } # now we have a cvterm element to associate as subject or object

    # so do it as either subject or object
    my $fr_id;
    if ($params{is_object}) {
	$fr_id = $ldoc->createElement('object_id');
    } else {
	$fr_id = $ldoc->createElement('subject_id');
    }

    $fr_id->appendChild($params{cvterm_id});

    $fr_el->appendChild($fr_id);

    return $fr_el;
}
*create_ch_cr = \&create_ch_cvterm_relationship;

# CREATE db or db_id element
# params
# doc - XML::DOM::Document required
# name - string required
# contact_id - string = a macro id or XML::DOM contact element optional
# contact - string = contact name optional NOTE: if you provide both contact_id and contact the contact 
#                                                value will be used
# description - string optional
# urlprefix - string optional
# url - string optional
# macro_id - string optional if provide then add an ID attribute to the top level element of provided value
# with_id - boolean optional if 1 then db_id element is returned
sub create_ch_db {
    my %params = @_;
    print "WARNING -- no XML::DOM::Document specified\n" and return unless $params{doc};
    my $ldoc = $params{doc};    ## XML::DOM::Document

    my $dbid_el = $ldoc->createElement('db_id') if $params{with_id};
    my $db_el = $ldoc->createElement('db');
    $db_el->setAttribute('id',$params{macro_id}) if $params{macro_id};

    # check to see if contact param is used and if it is create a contact_id element
    # and remove contact from the param list
    if ($params{contact}) {
      $params{contact_id} = create_ch_contact(doc => $ldoc,
					      name => $params{contact},);
      delete $params{contact};
    }

    foreach my $e (keys %params) {
      next if ($e eq 'doc' || $e eq 'with_id' || $e eq 'macro_id');
      $db_el->appendChild(_build_element($ldoc,$e,$params{$e}));
    }

    if ($dbid_el) {
      $dbid_el->appendChild($db_el);
      return $dbid_el;
    }
    return $db_el;
}


# CREATE dbxref or dbxref_id element
# params
# doc - XML::DOM::Document required
# accession - string required
# db_id - string = macro id for db or XML::DOM db element required
# db - string dbname required if db_id not provided
# version - string optional
# description - string optional
# macro_id - string optional if provide then add an ID attribute to the top level element of provided value
# with_id - boolean optional if 1 then dbxref_id element is returned
# no_lookup - boolean option if 1 then default op="lookup" attribute will not be added to element
sub create_ch_dbxref {
    my %params = @_;
    print "WARNING -- no XML::DOM::Document specified\n" and return unless $params{doc};
    my $ldoc = $params{doc};    ## XML::DOM::Document

    ## dbxref_id element (will be returned)
    my $dxid_el = $ldoc->createElement('dbxref_id') if $params{with_id};
    my $dx_el = $ldoc->createElement('dbxref');
    $dx_el->setAttribute('id',$params{macro_id}) if $params{macro_id};

    # add an op="lookup" attribute unless no_lookup is specified
    unless ($params{no_lookup}) {
	$dx_el->setAttribute('op','lookup');
    }

    # check for db param and if so make db_id element and delete db param
    if ($params{db}) {
      $params{db_id} = create_ch_db(doc => $ldoc,
				    name => $params{db},);
      delete $params{db};
    }

    foreach my $e (keys %params) {
	next if ($e eq 'doc' || $e eq 'with_id' || $e eq 'macro_id' || $e eq 'no_lookup');
	if ($e eq 'db_id') {
	    if (!ref($params{$e})) {
		$dx_el->appendChild(create_ch_db(doc => $ldoc,
						 name => $params{$e},
						 with_id => 1,));
	    } else {
		 $dx_el->appendChild(_build_element($ldoc,$e,$params{$e}));
	    }
	} else {
	    $dx_el->appendChild(_build_element($ldoc,$e,$params{$e}));
	}
    }

    if ($dxid_el) {
	$dxid_el->appendChild($dx_el);
	return $dxid_el;
    }
    return $dx_el;
}

# CREATE environment or environment_id element
# params
# doc - XML::DOM::Document optional - required
# uniquename - string required
# description - string optional
# with_id - boolean optional if 1 then expression_id element is returned
# macro_id - string to specify as id attribute of this element for later use
sub create_ch_environment {
    my %params = @_;
    $params{elname} = 'environment';
    $params{required} = ['uniquename'];
    my $eel = _create_simple_element(%params);
    return $eel;
}

# CREATE environment_cvterm element
# params
# doc - XML::DOM::Document optional - required
# environment_id - macro id for environment of XML::DOM environment element
# uniquename - environment uniquename
# NOTE: you need to pass environment bits if attaching to existing cvterm element or 
#       creating a freestanding environment_cvterm
# cvterm_id -  macro id for cvterm of XML::DOM cvterm element
# name - cvterm name
# cv_id - macro id for a CV or XML::DOM cv element
# cv - name of a cv
# is_obsolete - optional param for cvterm
# NOTE: you need to pass cvterm bits if attaching to existing environment element or 
#       creating a freestanding environment_cvterm
sub create_ch_environment_cvterm {
  my %params = @_;
  print "WARNING -- no XML::DOM::Document specified\n" and return unless $params{doc};
  my $ldoc = $params{doc};    ## XML::DOM::Document

  my $ect_el = $ldoc->createElement('environment_cvterm');

  # create an environment term if necessary
  if ($params{uniquename}) {
    $params{environment_id} = create_ch_environment(doc => $ldoc,
						    uniquename => $params{uniquename},
						   );
    delete $params{uniquename};
  }
    
  # create a cvterm element if necessary
  if ($params{name}) {
    print "ERROR: You don't have all the parameters required to make a cvterm, NO GO!\n" and return
      unless ($params{cv_id} or $params{cv});
    my %cvtparams = (doc => $ldoc,
		     name => $params{name},
		    );
    delete $params{name};
    
    if ($params{cv_id}) {
      $cvtparams{cv_id} = $params{cv_id};
      delete $params{cv_id}; 
    } elsif ($params{cv}) {
      $cvtparams{cv} = $params{cv};
      delete $params{cv}; 
    } else {
      print "WARNING -- you're trying to make a cvterm without providing a cv - Sorry, NO GO\n" and return;
    }

    if ($params{is_obsolete}) {
      $cvtparams{is_obsolete} = $params{is_obsolete};
      delete $params{is_obsolete};
    }
    $params{cvterm_id} = create_ch_cvterm(%cvtparams);      
  }

  # now see which elements to attach to environment_cvterm
  $ect_el->appendChild(_build_element($ldoc,'environment_id',$params{environment_id})) if $params{environment_id};
  $ect_el->appendChild(_build_element($ldoc,'cvterm_id',$params{cvterm_id})) if $params{cvterm_id};
  
  return $ect_el;
}

# CREATE expression or expression_id element
# params
# doc - XML::DOM::Document optional - required
# uniquename - string required
# md5checksum
# description - string optional
# with_id - boolean optional if 1 then expression_id element is returned
# macro_id - string to specify as id attribute of this element for later use
sub create_ch_expression {
    my %params = @_;
    $params{elname} = 'expression';
    $params{required} = ['uniquename'];
    my $eel = _create_simple_element(%params);
    return $eel;
}

# CREATE expression_cvterm element
# params
# doc - XML::DOM::Document required
# cvterm_id - XML::DOM cvterm element unless other cvterm bits are provided
# name - string required unless cvterm_id provided
# cv_id -  macro id for a cv or XML::DOM cv element required unless cvterm_id or cv provided
# cv - string = cvname required unless cvterm_id or cv_id provided
# cvterm_type_id - macro id for expression slots cvterm or XML::DOM cvterm element - required unless cvterm_type
# cvterm_type - string from the expression slots cv
# rank - int (default = 0 so don't pass unless you know it's different)  
# think about adding is_not column with default = false
sub create_ch_expression_cvterm {
  my %params = @_;
  print "WARNING -- no XML::DOM::Document specified\n" and return unless $params{doc};
  my $ldoc = $params{doc};    ## XML::DOM::Document

  my $ect_el = $ldoc->createElement('expression_cvterm');

  # create a cvterm element if necessary
  unless ($params{cvterm_id}) {
    print "WARNING -- you haven't provided params to make a cvterm, Sorry\n" and return unless ($params{name});
    my %cvtparams = (doc => $ldoc,
		     name => $params{name},
		    );
    delete $params{name};
    
    if ($params{cv_id}) {
      $cvtparams{cv_id} = $params{cv_id};
      delete $params{cv_id}; 
    } elsif ($params{cv}) {
      $cvtparams{cv} = $params{cv};
      delete $params{cv}; 
    } else {
      print "WARNING -- you're trying to make a cvterm without providing a cv - Sorry, NO GO\n" and return;
    }
    $params{cvterm_id} = create_ch_cvterm(%cvtparams);      
  }
  
  # deal with the type_id info 
  unless ($params{cvterm_type_id}) {
      print "WARNING -- you are trying to create a expression type without providing the info - Sorry, NO GO\n"
	and return unless $params{cvterm_type};

      $params{cvterm_type_id} = create_ch_cvterm(doc => $ldoc,
						 name => $params{cvterm_type},
						 cv => 'expression slots', # need to determine what this cv will be called
						);

      delete $params{cvterm_type};
  }
  
  #now set required rank to 0 if not provided
  $params{rank} = '0' unless $params{rank};

  foreach my $e (keys %params) {
    next if ($e eq 'doc');
    $ect_el->appendChild(_build_element($ldoc,$e,$params{$e}));
  }
  return $ect_el;
}

# CREATE expression_cvtermprop element
# params
# doc - XML::DOM::Document required
# value - string - not strictly required but if you don't provide this then not much point
# type_id - macro id for cvterm from expression_cvtprop type cv or XML::DOM cvterm element required
# type -  string from  expression_cvtermprop type cv
#         Note: will default to making a expressionprop from 'expression_cvtermprop type' cv unless
#              cvname is provided
# cvname - string optional but see above for type and do not provide if passing type_id
# rank - integer with a default of zero so don't use unless you want a rank other than 0
sub create_ch_expression_cvtermprop {
    my %params = @_;
    $params{parentname} = 'expression_cvterm';
    my $fp_el = create_ch_prop(%params);
    return $fp_el;
}

# CREATE expression_pub element
# Note that this is just calling create_ch_pub setting with_id = 1
#      and adding returned pub_id element as a child of expression_pub
#      or just appending the pub element to expression_pub if that is passed
# params
# doc - XML::DOM::Document required
# pub_id - XML::DOM pub element - if this is used then pass this and doc as only params
# uniquename - string required
# type_id - macro id for pub type or XML::DOM cvterm element optional unless 
#            creating a new pub (i.e. not null value but not part of unique key
# type - string from pub type cv same requirement as type_id
# title - optional string
# volumetitle - optional string
# volume - optional string
# series_name - optional string
# issue - optional string
# pyear - optional string
# pages - optional string
# miniref - optional string
# is_obsolete - optional string 't' boolean value with default = 'f'
# publisher - optional string
sub create_ch_expression_pub {
  my %params = @_;
  print "WARNING -- no XML::DOM::Document specified\n" and return unless $params{doc};
  my $ldoc = $params{doc};    ## XML::DOM::Document
  
  my $ep_el = $ldoc->createElement('expression_pub');
  
    if ($params{expression_id}) {
	$ep_el->appendChild(_build_element($ldoc,'feature_id',$params{expression_id}));
	delete $params{expression_id};
    }

  unless ($params{pub_id}) {
    $params{pub_id} = create_ch_pub(%params); #will return a pub element
  }
  $ep_el->appendChild(_build_element($ldoc,'pub_id',$params{pub_id}));

  return $ep_el;
}

# CREATE expressionprop element
# params
# doc - XML::DOM::Document required
# value - string - not strictly required but if you don't provide this then not much point
# type_id - string from realtionship property type cv or XML::DOM cvterm element required
#        Note: will default to making a expressionprop from 'property type' cv unless cvname is provided
# cvname - string 'optional' but see above for type and do not provide if passing a cvterm element
# rank - integer with a default of zero so don't use unless you want a rank other than 0
sub create_ch_expressionprop {
    my %params = @_;
    $params{parentname} = 'expression';
    unless ($params{type_id}) {
	$params{cvname} = 'expressionprop type' unless $params{cvname};
    }
    my $ep_el = create_ch_prop(%params);
    return $ep_el;
}

# CREATE feature element
# params
# doc - XML::DOM::Document required
# uniquename - string required
# type_id - cvterm macro id or XML::DOM cvterm element required unless type
# type - string for a cvterm Note: will default to using SO cv unless a cvname is provided
# cvname - string optional to specify a cv other than SO for the type_id
#          do not use if providing a cvterm element or macro id to type_id
# organism_id - organism macro id or XML::DOM organism element required if no genus and species
# genus - string required if no organism
# species - string required if no organism
# dbxref_id - dbxref macro id or XML::DOM dbxref element optional
# name - string optional
# residue - string optional
# seqlen - integer optional (if seqlen = 0 pass as string)
# md5checksum - string optional
# is_analysis - boolean 't' or 'f' default = 'f' optional
# is_obsolete - boolean 't' or 'f' default = 'f' optional
# macro_id - string optional if provide then add an ID attribute to the top level element of provided value
# with_id - boolean optional if 1 then feature_id element is returned
# no_lookup - boolean option if 1 then default op="lookup" attribute will not be added to element
sub create_ch_feature {
    my %params = @_;
    print "WARNING -- no XML::DOM::Document specified\n" and return unless $params{doc};
    my $ldoc = $params{doc};    ## XML::DOM::Document

    my $fid_el = $ldoc->createElement('feature_id') if $params{with_id};

    ## feature element (will be returned)
    my $f_el = $ldoc->createElement('feature');
    $f_el->setAttribute('id',$params{macro_id}) if $params{macro_id};    

    # add an op="lookup" attribute unless no_lookup is specified
    unless ($params{no_lookup}) {
	$f_el->setAttribute('op','lookup');
    }
	
    #create organism_id element if genus and species are provided
    unless ($params{organism_id}) {
	$params{organism_id} = create_ch_organism(doc => $ldoc,
					genus => $params{genus},
					species => $params{species},
					);

	delete $params{genus}; delete $params{species};
    }

    # figure out which cv to use in type_id element that we make below
    my $cv = 'SO';
    if ($params{cvname}) {
	$cv = $params{cvname};
	delete $params{cvname};
    }

    # now deal make a cvterm element for type_id if string is provided
    if ($params{type}) {
      $params{type_id} = create_ch_cvterm(doc => $ldoc,
				   name => $params{type},
				   cv => $cv,
				  );
      delete $params{type};
    }

    foreach my $e (keys %params) {
	next if ($e eq 'doc' || $e eq 'with_id' || $e eq 'macro_id' || $e eq 'no_lookup');
	$f_el->appendChild(_build_element($ldoc, $e,$params{$e}));
    }

    if ($fid_el) {
	$fid_el->appendChild($f_el);
	return $fid_el;
    }
    return $f_el;
}


# CREATE feature_cvterm element
# params
# doc - XML::DOM::Document required
# cvterm_id - cvterm macro id or XML::DOM cvterm element unless other cvterm bits are provided
# name - string required unless cvterm_id provided Note: a cvterm has a lookup by default cannot make a new cvterm 
#                                                        with this method
# cv_id - macro id for cv or XML::DOM cv element required if name and not cv
# cv - string for name of cv required if name and not cv_id
# pub_id - macro id for pub or XML::DOM pub element required unless pub
# pub - string = pub uniquename Note: as pub has lookup option by default can't make a new pub using this param
# is_not - optional boolean 't' or 'f' with default = 'f' so don't pass unless you know you want to change
sub create_ch_feature_cvterm {
    my %params = @_;
    print "WARNING -- no XML::DOM::Document specified\n" and return unless $params{doc};
    my $ldoc = $params{doc};    ## XML::DOM::Document

    my $fct_el = $ldoc->createElement('feature_cvterm');

    #create a cvterm element if necessary
    unless ($params{cvterm_id}) {
      print "WARNING -- you haven't provided params to make a cvterm, Sorry\n" and return unless ($params{name});
      my %cvtparams = (doc => $ldoc,
		       name => $params{name},
		      );
      delete $params{name};

      if ($params{cv_id}) {
	$cvtparams{cv_id} = $params{cv_id};
	delete $params{cv_id}; 
      } elsif ($params{cv}) {
	$cvtparams{cv} = $params{cv};
	delete $params{cv}; 
      } else {
	print "WARNING -- you're trying to make a cvterm without providing a cv - Sorry, NO GO\n" and return;
      }
      $params{cvterm_id} = create_ch_cvterm(%cvtparams);      
    }

    #create a pub element if necessary
    if ($params{pub}) {
      $params{pub_id} = create_ch_pub(doc => $ldoc,
				      uniquename => $params{pub},
				     );
      delete $params{pub};
    }

    foreach my $e (keys %params) {
	next if ($e eq 'doc');
	$fct_el->appendChild(_build_element($ldoc,$e,$params{$e}));
    }
    return $fct_el;
}

# CREATE feature_cvtermprop element
# params
# doc - XML::DOM::Document required
# value - string - not strictly required but if you don't provide this then not much point
# type_id - string from  feature_cvtermprop type cv or XML::DOM cvterm element required 
#        Note: will default to making a featureprop from 'feature_cvtermprop type' cv unless 
#              cvname is provided
# cvname - string optional
#          but see above for type and do not provide if passing a cvterm element
# rank - integer with a default of zero so don't use unless you want a rank other than 0
sub create_ch_feature_cvtermprop {
    my %params = @_;
    $params{parentname} = 'feature_cvterm';
    my $fp_el = create_ch_prop(%params);
    return $fp_el;
}


# CREATE feature_dbxref element
# params
# doc - XML::DOM::Document required
# feature_id - macro feature id or XML::DOM feature element optionaal to create freestanding feature_dbxref
# dbxref_id - macro dbxref id or XML::DOM dbxref element - required unless accession and db provided
# accession - string required unless dbxref_id provided
# db_id - macro db id or XML::DOM db element required unless dbxref_id provided
# db - string name of db
# version - string optional
# description - string optional
# is_current - string 't' or 'f' boolean default = 't' so don't pass unless
#              this shoud be changed
sub create_ch_feature_dbxref {
    my %params = @_;
    print "WARNING -- no XML::DOM::Document specified\n" and return unless $params{doc};
    my $ldoc = $params{doc};    ## XML::DOM::Document

    my $fd_el = $ldoc->createElement('feature_dbxref');

    if ($params{feature_id}) {
	$fd_el->appendChild(_build_element($ldoc,'feature_id',$params{feature_id}));
	delete $params{feature_id};
    }

    my $ic;
    if ($params{is_current}) { #assign value to a var and then remove from params
	$ic = $params{is_current};
	delete $params{is_current};
    }

    # create a dbxref element if necessary
    unless ($params{dbxref_id}) {
      print "WARNING - missing required parameters, NO GO.\n" and return unless 
	($params{accession} and ($params{db_id} or $params{db}));
      if ($params{db}) {
	$params{db_id} = create_ch_db(doc => $ldoc,
				      name => $params{db},
				     );
	delete $params{db};
      }
      
	
      $params{dbxref_id} = create_ch_dbxref(%params);
    }

    $fd_el->appendChild(_build_element($ldoc,'dbxref_id',$params{dbxref_id})); #add dbxref element
    $fd_el->appendChild(_build_element($ldoc,'is_current',$ic)) if $ic;

    return $fd_el;
}

# CREATE feature_expression element
# params
# doc - XML::DOM::Document required
# feature_id - OPTIONAL macro feature id or XML::DOM feature element to create freestanding feature_expression 
# expression_id - macro expression id or XML::DOM expression element - required unless uniquename provided
# uniquename - string required unless expression_id
# pub_id - macro pub id or XML::DOM pub element - required unless puname provided
# pub - string uniquename for pub (note will have lookup so can't create new pub here)
sub create_ch_feature_expression {
    my %params = @_;
    print "WARNING -- no XML::DOM::Document specified\n" and return unless $params{doc};
    my $ldoc = $params{doc};    ## XML::DOM::Document

    my $fd_el = $ldoc->createElement('feature_expression');

    # check for feature_id parameter
    $fd_el->appendChild(_build_element($ldoc,'feature_id',$params{feature_id})) if  $params{feature_id};

    # create a expression element if necessary
    unless ($params{expression_id}) {
      print "WARNING - missing required expression info, NO GO.\n" and return unless $params{uniquename};
      $params{expression_id} = create_ch_expression(doc => $ldoc,
						   uniquename => $params{uniquename},);
      delete $params{uniquename};
    }

    #create a pub element if necessary
    unless ($params{pub_id}) {
	print "WARNING - missing required pub info, NO GO.\n" and return unless $params{pub};
	$params{pub_id} = create_ch_pub(doc => $ldoc,
					uniquename => $params{pub},
				       );
	delete $params{pub};
    }

    foreach my $e (keys %params) {
	next if ($e eq 'doc');
	$fd_el->appendChild(_build_element($ldoc,$e,$params{$e}));
    }

    return $fd_el;
}

# CREATE feature_expressionprop element
# params
# doc - XML::DOM::Document required
# value - string - not strictly required but if you don't provide this then not much point
# type_id - macro id for feature_expressionprop type or XML::DOM cvterm element required
# type -  string from  expression_cvtermprop type cv 
#        Note: will default to making a featureprop from 'expression_cvtermprop type' cv unless cvname is provided
# cvname - string (probably want to pass 'feature_expressionprop type') optional
#          but see above for type and do not provide if passing a cvterm element
# rank - integer with a default of zero so don't use unless you want a rank other than 0
sub create_ch_feature_expressionprop {
    my %params = @_;
    $params{parentname} = 'feature_expression';
    my $fp_el = create_ch_prop(%params);
    return $fp_el;
}

# CREATE feature_genotype element
# params
# doc - XML::DOM::Document optional - required
# genotype_id - macro_id for a genotype or XML::DOM genotype element
# uniquename - string = genotype uniquename
# chromosome_id macro id for chromosome feature or XML::DOM feature element
#      NOTE: that this is part of the key but can be null so not required
# cgroup - int (default = 0 so don't pass unless you know its different)
# rank - int (default = 0 so don't pass unless you know its different)
# cvterm_id - macro id for a cvterm or XML::DOM cvterm element required
sub create_ch_feature_genotype {
    my %params = @_;
    print "WARNING -- no XML::DOM::Document specified\n" and return unless $params{doc};
    my $ldoc = $params{doc};    ## XML::DOM::Document

    ## feature_genotype element (will be returned)
    my $fl_el = $ldoc->createElement('feature_genotype');

    #first warn about potential oddness
    print STDERR "WARNING - no genotype_id object\n" and return unless ($params{genotype_id} or $params{uniquename});
    print STDERR "WARNING - no chromosome_id feature object\n" unless $params{chromosome_id};
    print STDERR "WARNING - no cvterm_id object\n" and return unless $params{cvterm_id};

    #now set required cgroup and ranks to 0 if not provided
    $params{cgroup} = '0' unless $params{cgroup};
    $params{rank} = '0' unless $params{rank};

    # make a genotype element if uniquename is specified
    if ($params{uniquename}) {
      $params{genotype_id} = create_ch_genotype(doc => $ldoc,
						uniquename => $params{uniquename},
					       );
      delete $params{uniquename};
    }

    foreach my $e (keys %params) {
	next if ($e eq 'doc');
	$fl_el->appendChild(_build_element($ldoc,$e,$params{$e}));
    }
    return $fl_el
}


# CREATE feature_pub element
# Note that this is just calling create_ch_pub setting with_id = 1 
#      and adding returned pub_id element as a child of feature_pub
#      or just appending the pub element to feature_pub if that is passed
# params
# doc - XML::DOM::Document required
# pub_id - macro_id for pub or XML::DOM pub element - if this is used then pass this and doc as only params
# uniquename - string required
# type_id - macro id for pub type or XML::DOM cvterm element optional unless 
#        creating a new pub (i.e. not null value but not part of unique key
# type - string for type from pub type cv 
# title - optional string
# volumetitle - optional string
# volume - optional string
# series_name - optional string
# issue - optional string
# pyear - optional string
# pages - optional string
# miniref - optional string
# is_obsolete - optional string 't' boolean value with default = 'f'
# publisher - optional string
sub create_ch_feature_pub {
    my %params = @_;
    print "WARNING -- no XML::DOM::Document specified\n" and return unless $params{doc};
    my $ldoc = $params{doc};    ## XML::DOM::Document

    my $fp_el = $ldoc->createElement('feature_pub');

    if ($params{feature_id}) {
	$fp_el->appendChild(_build_element($ldoc,'feature_id',$params{feature_id}));
	delete $params{feature_id};
    }
    
    unless ($params{pub_id}) {
	$params{pub_id} = create_ch_pub(%params); #will return a pub element
    }
    $fp_el->appendChild(_build_element($ldoc,'pub_id',$params{pub_id}));
    return $fp_el;
}

# just calling create_ch_prop with correct params to make desired prop
# note that there are cases here where the value is null
sub create_ch_feature_pubprop {
    my %params = @_;
    $params{parentname} = 'feature_pub';
    unless ($params{type_id}) {
	$params{cvname} = 'pubprop type' unless $params{cvname};
    }
    my $fp_el = create_ch_prop(%params);
    return $fp_el;
}

# CREATE feature_relationship element
# NOTE: this will create either a subject_id or object_id feature_relationship element
# but you have to attach this to the related feature elsewhere
# params
# doc - XML::DOM::Document required
# object _id - macro id for object feature or XML::DOM feature element
# subject_id - macro id for subject feature or XML::DOM feature element
# NOTE you can pass one or both of the above parameters with the following rules:
# if only one of the two are passed then the converse is_{object,subject} param is assumed for creation of other feature
# if both are passed then is_object, is_subject and any parameters to create a feature are ignored
# is_object - boolean 't'     Note: either is_subject OR is_object and NOT both must be passed
# is_subject - boolean 't'          this flag indicates if the feature info provided should be 
#                                   added in as subject or object feature
# rtype_id - macro id for relationship type or XML::DOM cvterm element (Note: currently all is_relationship = '0'
# rtype - string for relationship type note: with this param  type will be assigned to relationship_type cv
# rank - integer optional with default = 0
# feature_id - macro_id for a feature or XML::DOM feature element required unless minimal feature bits provided
# uniquename - string required unless feature provided
# organism_id - macro id for organism or XML::DOM organism element required unless feature or (genus & species) provided
# genus - string required unless feature or organism provided
# species - string required unless feature or organism provided
# ftype_id - macro id for feature type or XML::DOM cvterm element required unless feature provided
# ftype - string for feature type (will be assigned to SO cv and can't be new as will be lookup)
sub create_ch_fr {
    my %params = @_;
    print "WARNING -- no XML::DOM::Document specified\n" and return unless $params{doc};
    my $ldoc = $params{doc};    ## XML::DOM::Document

    ## feature_relationship element (will be returned)
    my $fr_el = $ldoc->createElement('feature_relationship');

    # deal with the type, rank first
    # add relationship type
    my $rtype_el = $ldoc->createElement('type_id');
    if ($params{rtype}) {
	my $cv_el = create_ch_cv(doc => $ldoc,
				 name => 'relationship type',
				);
	my $cvterm_el = create_ch_cvterm(doc => $ldoc,
					 name => $params{rtype},
					 cv_id => $cv_el,
					 # note that we may want to add is_relationship = 1 in the future
					);
	$rtype_el->appendChild($cvterm_el);
    } else {
      if (!ref($params{rtype_id})) {
	my $val = $ldoc->createTextNode("$params{rtype_id}");
	$rtype_el->appendChild($val);
      } else {
	$rtype_el->appendChild($params{rtype_id});
      }
    }
    $fr_el->appendChild($rtype_el);

    # and add rank
    my $rank = '0';
    $rank = $params{rank} if $params{rank};
    $fr_el->appendChild(_build_element($ldoc,'rank',$rank));

    # now deal with various feature options
    if ($params{object_id}) { 
         # create the object_id element
	$fr_el->appendChild(_build_element($ldoc,'object_id',$params{object_id}));
	$params{is_subject} = 1 unless $params{subject_id};
    }

    if ($params{subject_id}) { 
         # create the subject_id element
	$fr_el->appendChild(_build_element($ldoc,'subject_id',$params{subject_id}));
	$params{is_object} = 1 unless $params{object_id};
    }

    return $fr_el if (defined($params{object_id})  and defined($params{subject_id}));

    # deal with creating the feature bits if present
    unless ($params{feature_id}) {
	$params{organism_id} = create_ch_organism(doc => $ldoc,
						  genus => $params{genus},
						  species => $params{species},
						 ) unless $params{organism_id};
	# before creating feature figure out which parameters
	my %fparams = (doc => $ldoc,
		       uniquename => $params{uniquename},
		       organism_id => $params{organism_id},
		      );
	if ($params{ftype_id}) { 
	  $fparams{type_id} = $params{ftype_id};
	} elsif ($params{ftype}) {
	  $fparams{type} = $params{ftype};
	} else {
	  print "WARNING -- you need to provide a feature type to make a feature!\n" and return;
	}
	$params{feature_id} = create_ch_feature(%fparams);
    } # now we have a feature element to associate as subject or object
    # so do it as either subject or object
    my $fr_id;
    if ($params{is_object}) {
	$fr_id = $ldoc->createElement('object_id');
    } else {
	$fr_id = $ldoc->createElement('subject_id');
    }

    if (!ref($params{feature_id})) {
      my $val = $ldoc->createTextNode("$params{feature_id}");
      $fr_id->appendChild($val);
    } else {
      $fr_id->appendChild($params{feature_id});
    }

    $fr_el->appendChild($fr_id);

    return $fr_el;
}
*create_ch_feature_relationship = \&create_ch_fr;
*create_ch_f_r = \&create_ch_fr;

# CREATE feature_relationshipprop element
# params
# doc - XML::DOM::Document required
# value - string - not strictly required but if you don't provide this then not much point
# type_id - string from feature_relationshipprop type cv or XML::DOM cvterm element required 
#        Note: will default to making a featureprop from 'fr property type' cv unless cvname is provided
# cvname - string optional 
#          but see above for type and do not provide if passing a cvterm element
# rank - integer with a default of zero so don't use unless you want a rank other than 0
sub create_ch_frprop {
    my %params = @_;
    $params{parentname} = 'feature_relationship';
    my $fp_el = create_ch_prop(%params);
    return $fp_el;
}
*create_ch_fr_prop = \&create_ch_frprop;
*create_ch_feature_relationshipprop = \&create_ch_frprop;
*create_ch_f_rprop = \&create_ch_frprop;

# CREATE feature_relationshipprop_pub element
# # Note that this is just calling create_ch_pub 
#      and adding returned pub_id element as a child of feature_relationshipprop_pub
#      or just appending the pub element to feature_relationshipprop_pub if that is passed
# params
# doc - XML::DOM::Document required
# feature_relationshipprop_id -optional feature_relationshipprop XML::DOM element or macro id
# pub_id - XML::DOM pub element - if this is used then pass this and doc as only params
# uniquename - string required
# type_id - macro id for pub type or XML::DOM cvterm element optional unless 
# type -  string from pub type cv 
# title - optional string
# volumetitle - optional string
# volume - optional string
# series_name - optional string
# issue - optional string
# pyear - optional string
# pages - optional string
# miniref - optional string
# is_obsolete - optional string 't' boolean value with default = 'f'
# publisher - optional string
sub create_ch_frprop_pub {
    my %params = @_;
    print "WARNING -- no XML::DOM::Document specified\n" and return unless $params{doc};
    my $ldoc = $params{doc};    ## XML::DOM::Document

    my $fp_el = $ldoc->createElement('feature_relationshipprop_pub');

    if ($params{feature_relationshipprop_id}) {
	$fp_el->appendChild(_build_element($ldoc,'feature_relationshipprop_id',$params{feature_relationshipprop_id}));
	delete $params{feature_relationshipprop_id};
    }

    unless ($params{pub_id}) {
	$params{pub_id} = create_ch_pub(%params); #will return a pub element
    }
    $fp_el->appendChild(_build_element($ldoc,'pub_id',$params{pub_id}));
    return $fp_el;
}
*create_ch_feature_relationshipprop_pub = \& create_ch_frprop_pub;
*create_ch_f_rprop_pub = \& create_ch_frprop_pub;

# CREATE feature_relationship_pub element
# # Note that this is just calling create_ch_pub 
#      and adding returned pub_id element as a child of feature_relationship_pub
#      or just appending the pub element to feature_relationship_pub if that is passed
# params
# doc - XML::DOM::Document required
# feature_relationship_id -optional feature_relationship XML::DOM element or macro id
# pub_id - XML::DOM pub element - if this is used then pass this and doc as only params
# uniquename - string required
# type_id - macro id for pub type or XML::DOM cvterm element optional unless 
# type -  string from pub type cv 
# title - optional string
# volumetitle - optional string
# volume - optional string
# series_name - optional string
# issue - optional string
# pyear - optional string
# pages - optional string
# miniref - optional string
# is_obsolete - optional string 't' boolean value with default = 'f'
# publisher - optional string
sub create_ch_fr_pub {
    my %params = @_;
    print "WARNING -- no XML::DOM::Document specified\n" and return unless $params{doc};
    my $ldoc = $params{doc};    ## XML::DOM::Document

    my $fp_el = $ldoc->createElement('feature_relationship_pub');

    if ($params{feature_relationship_id}) {
	$fp_el->appendChild(_build_element($ldoc,'feature_relationship_id',$params{feature_relationship_id}));
	delete $params{feature_relationship_id};
    }

    unless ($params{pub_id}) {
	$params{pub_id} = create_ch_pub(%params); #will return a pub element
    }
    $fp_el->appendChild(_build_element($ldoc,'pub_id',$params{pub_id}));
    return $fp_el;
}
*create_ch_feature_relationship_pub = \& create_ch_fr_pub;



# CREATE feature_synonym element
# params
# doc - XML::DOM::Document required
# synonym_id - macro id for synonym? or XML::DOM synonym element required unless name and type provided
# name - string required unless synonym_id element provided
# type_id - macro id for synonym type or XML::DOM cvterm element
# type - string = name from the 'synonym type' cv
# pub_id - macro id for pub or a XML::DOM pub element required
# pub - a pub uniquename (i.e. FBrf)
# synonym_sgml - string optional but if not provided then synonym_sgml = name
#               - do not provide if a synonym element is provided
# is_current - optional string = 'f' or 't' default is 't' so don't provide this param
#               unless you know you want to change the value
# is_internal - optional string = 't' default is 'f' so don't provide this param
#               unless you know you want to change the value
sub create_ch_feature_synonym {
    my %params = @_;
    print "WARNING -- no XML::DOM::Document specified\n" and return unless $params{doc};
    my $ldoc = $params{doc};    ## XML::DOM::Document

    ## feature_synonym element (will be returned)
    my $fs_el = $ldoc->createElement('feature_synonym');

    #create a synonym element and undefine name, type and synonym_sgml bits
    unless($params{synonym_id}) {
      # gather params for synonym
      print "WARNING - you haven't provided info to create a synonym element\n" and return unless $params{name};
      my %syn_params = (doc => $ldoc,
			name => $params{name},
		       );
      delete $params{name};
      if ($params{synonym_sgml}) {
	$syn_params{synonym_sgml} = $params{synonym_sgml};
	delete $params{synonym_sgml};
      }
       
      # check for type or type_id
      if ($params{type}) {
	$syn_params{type} = $params{type};
	delete $params{type};
      } elsif ($params{type_id}) {
	$syn_params{type_id} = $params{type_id};
	delete $params{type_id};
      } else {
	print "WARNING - you haven't provided a synonym type\n" and return;
      }
      my $syn_el = create_ch_synonym(%syn_params);
      $params{synonym_id} = $syn_el;	
    }

    # check for pub 
    if ($params{pub}) {
      $params{pub_id} = create_ch_pub(doc => $ldoc,
				      uniquename => $params{pub},
				     );
      delete $params{pub};
    }

    foreach my $e (keys %params) {
      next if ($e eq 'doc');
      $fs_el->appendChild(_build_element($ldoc,$e,$params{$e}));
    }
    
    return $fs_el;
}


# CREATE featureloc element
# params
# none of these parameters are strictly required and some warning is done
# but if you misbehave you could set up some funky featurelocs?
# srcfeature_id macro id for a feature or XML::DOM feature element
# fmin - integer
# fmax - integer
# strand - 1, 1 or 0 (0 must be passed as string or else will be undef)
# phase - int
# residue_info - string
# locgroup - int (default = 0 so don't pass unless you know its different)
# rank - int (default = 0 so don't pass unless you know its different)
# is_fmin_partial - boolean 't' or 'f' default = 'f'
# is_fmax_partial - boolean 't' or 'f' default = 'f'
sub create_ch_featureloc {
    my %params = @_;
    print "WARNING -- no XML::DOM::Document specified\n" and return unless $params{doc};
    my $ldoc = $params{doc};    ## XML::DOM::Document

    ## featureloc element (will be returned)
    my $fl_el = $ldoc->createElement('featureloc');

    #first warn about potential oddness
#    print STDERR "WARNING - no srcfeature object\n" unless $params{srcfeature_id};
#    print STDERR "WARNING - no min and max coordinate pair\n" unless ($params{fmin} && $params{fmax});
#    print STDERR "WARNING - no strand\n" unless $params{strand};

    #now set required loc_group and ranks to 0 if not provided
    $params{locgroup} = '0' unless $params{locgroup};
    $params{rank} = '0' unless $params{rank};

    foreach my $e (keys %params) {
	next if ($e eq 'doc');
	$fl_el->appendChild(_build_element($ldoc,$e,$params{$e}));
    }
    return $fl_el
}

# CREATE featureloc_pub element
# Note that this is just calling create_ch_pub 
#      and adding returned pub_id element as a child of featureloc_pub
#      or just appending the pub element to featureloc_pub if that is passed
# params
# doc - XML::DOM::Document required
# pub_id - macro id for pub or XML::DOM pub element - if this is used then pass this and doc as only params
# uniquename - string required unless pub_id
# type_id - macro id for pub or XML::DOM cvterm element optional unless 
#        creating a new pub (i.e. not null value but not part of unique key
# type - string from pub type cv
# title - optional string
# volumetitle - optional string
# volume - optional string
# series_name - optional string
# issue - optional string
# pyear - optional string
# pages - optional string
# miniref - optional string
# is_obsolete - optional string 't' boolean value with default = 'f'
# publisher - optional string
sub create_ch_featureloc_pub {
  my %params = @_;
  print "WARNING -- no XML::DOM::Document specified\n" and return unless $params{doc};
  my $ldoc = $params{doc};    ## XML::DOM::Document
  
  my $fp_el = $ldoc->createElement('featureloc_pub');
  # add optional featureloc_id element if param is passed
  if ($params{featureloc_id}) {
	$fp_el->appendChild(_build_element($ldoc,'featureloc_id',$params{featureloc_id}));
	delete $params{featureloc_id};
    }

  unless ($params{pub_id}) {
    $params{pub_id} = create_ch_pub(%params); #will return a pub element
  }
  $fp_el->appendChild(_build_element($ldoc,'pub_id',$params{pub_id}));
  return $fp_el;  
}

# CREATE featureprop element
# params
# doc - XML::DOM::Document required
# value - string - not strictly required but if you don't provide this then not much point
# type_id - macro id or XML::DOM cvterm element required 
#        Note: will default to making a featureprop from 'property type' cv unless cvname is provided
# type - string from property type cv
# cvname - string 'optional' but see above for type and do not provide if passing a cvterm element
# rank - integer with a default of zero so don't use unless you want a rank other than 0
sub create_ch_featureprop {
    my %params = @_;
    $params{parentname} = 'feature';
    unless ($params{type_id}) {
	$params{cvname} = 'property type' unless $params{cvname};
    }
    my $fp_el = create_ch_prop(%params);
    return $fp_el;
}


# CREATE featureprop_pub element
# Note that this is just calling create_ch_pub 
#      and adding returned pub_id element as a child of featureprop_pub
#      or just appending the pub element to featureprop_pub if that is passed
# params
# doc - XML::DOM::Document required
# pub_id - XML::DOM pub element - if this is used then pass this and doc as only params
# uniquename - string required
# type_id - macro id for pub type or XML::DOM cvterm element optional unless 
# type -  string from pub type cv 
# title - optional string
# volumetitle - optional string
# volume - optional string
# series_name - optional string
# issue - optional string
# pyear - optional string
# pages - optional string
# miniref - optional string
# is_obsolete - optional string 't' boolean value with default = 'f'
# publisher - optional string
sub create_ch_featureprop_pub {
    my %params = @_;
    print "WARNING -- no XML::DOM::Document specified\n" and return unless $params{doc};
    my $ldoc = $params{doc};    ## XML::DOM::Document

    my $fp_el = $ldoc->createElement('featureprop_pub');

    if ($params{featureprop_id}) {
	$fp_el->appendChild(_build_element($ldoc,'featureprop_id',$params{featureprop_id}));
	delete $params{featureprop_id};
    }

    unless ($params{pub_id}) {
	$params{pub_id} = create_ch_pub(%params); #will return a pub element
    }
    $fp_el->appendChild(_build_element($ldoc,'pub_id',$params{pub_id}));
    return $fp_el;
}

# CREATE genotype or genotype_id element
# params
# doc - XML::DOM::Document optional - required
# uniquename - string required
# description - string optional
# name - string optional
# macro_id
# with_id - boolean optional if 1 then genotype_id element is returned
sub create_ch_genotype {
  my %params = @_;
  $params{elname} = 'genotype';
  $params{required} = ['uniquename'];
  my $eel = _create_simple_element(%params);
  return $eel;
}

# CREATE library or library_id element
# params
# doc - XML::DOM::Document
# uniquename - string required
# type_id - macro id for library type or XML::DOM cvterm element required
# type - string to specify library type from library type cv
# organism_id - macro id for organism or XML::DOM organism element required if no genus and species
# genus - string required if no organism
# species - string required if no organism
# name - string optional
# macro_id - string to specify as id attribute
# with_id - boolean optional if 1 then db_id element is returned
sub create_ch_library {
    my %params = @_;
    print "WARNING -- no XML::DOM::Document specified\n" and return unless $params{doc};
    my $ldoc = $params{doc};    ## XML::DOM::Document
    print "WARNING -- required params are missing - info for uniquename, type and organism are needed\n" and return
      unless ($params{uniquename} and ($params{type_id} or $params{type}) and ($params{organism_id} or ($params{genus} and $params{species})));

    my $libid_el = $ldoc->createElement('library_id') if $params{with_id};
    my $lib_el = $ldoc->createElement('library');
    $lib_el->setAttribute('id',$params{macro_id}) if $params{macro_id};  

    #create organism_id element if genus and species are provided
    unless ($params{organism_id}) {
	$params{organism_id} = create_ch_organism(doc => $ldoc,
					genus => $params{genus},
					species => $params{species},
					);

	delete $params{genus}; delete $params{species};
    }

    # create type_id element if type is specified
    if ($params{type}) {
      $params{type_id} = create_ch_cvterm(doc => $ldoc,
					  name => $params{type},
					  cv => 'library type',
				  );
      delete $params{type};
    }

    foreach my $e (keys %params) {
	next if ($e eq 'doc' || $e eq 'with_id' || $e eq 'macro_id');
	$lib_el->appendChild(_build_element($ldoc, $e,$params{$e}));
    }


    if ($libid_el) {
	$libid_el->appendChild($lib_el);
	return $libid_el;
    }
    return $lib_el;
}


# CREATE libraryprop element
# params
# doc - XML::DOM::Document required
# value - string - not strictly required but if you don't provide this then not much point
# type_id - string from realtionship property type cv or XML::DOM cvterm element required 
#        Note: will default to making a featureprop from 'property type' cv unless cvname is provided
# cvname - string 'optional' but see above for type and do not provide if passing a cvterm element
# rank - integer with a default of zero so don't use unless you want a rank other than 0
sub create_ch_libraryprop {
    my %params = @_;
    $params{parentname} = 'library';
    unless ($params{type_id}) {
	$params{cvname} = 'library property type' unless $params{cvname};
    }
    my $fp_el = create_ch_prop(%params);
    return $fp_el;
}

# CREATE library_feature element
# params
# doc - XML::DOM::Document required
# organism_id - macro id for organism or XML::DOM organism element
# genus - string
# species - string
# NOTE: you can use the generic paramaters in the following cases:
#       1.  you are only building either a library or feature element and not both
#       2.  or both library and feature have the same organism
#       otherwise use the prefixed parameters
# WARNING - if you provide both generic and prefixed parameters then the prefixed ones will be used
# library_id - macro id for library or XML::DOM library element
# lib_uniquename - string library uniquename
# lib_organism_id - macro id for organism or XML::DOM organism element to link to library
# lib_genus
# lib_species
# lib_type_id
# lib_type
# feature_id - macro id for feature or XML::DOM feature element
# feat_uniquename
# feat_organism_id - macro id for organism or XML::DOM organism element to link to feature
# feat_genus
# feat_species
# feat_type_id
# feat_type
sub create_ch_library_feature {
  my %params = @_;
  print "ERROR -- no XML::DOM::Document specified\n" and return unless $params{doc};
  my $ldoc = $params{doc};    ## XML::DOM::Document

  #have to think about the checks a bit

  my $lf_el = $ldoc->createElement('library_feature');

  # deal with feature bits
  if ($params{feat_uniquename}) {
    print "ERROR -- you don't have required parameters to make a feature, NO GO!\n" and return
      unless (($params{organism_id} or $params{feat_organism_id} or ($params{genus} and $params{species}) 
	       or ($params{feat_genus} and $params{feat_species}))
	      and ($params{feat_type_id} or $params{feat_type}));

    unless ($params{feat_organism_id} or ($params{feat_genus} and $params{feat_species})) {
      $params{feat_organism_id} = $params{organism_id} if $params{organism_id};
      $params{feat_genus} = $params{genus} if $params{genus};
      $params{feat_species} = $params{species} if $params{species};
    }

    # gather all the feature parameters
    my %fparams = (doc => $ldoc,);
    foreach my $p (keys %params) {
      if ($p =~ /feat_(.+)/) {
	$fparams{$1} = $params{$p};
      }
    }

    $params{feature_id} = create_ch_feature(%fparams);
  }

  # likewise deal with the library bits
  if ($params{lib_uniquename}) {
    print "ERROR -- you don't have required parameters to make a library, NO GO!\n" and return
      unless (($params{organism_id} or $params{lib_organism_id} or ($params{genus} and $params{species}) 
	       or ($params{lib_genus} and $params{lib_species}))
	      and ($params{lib_type_id} or $params{lib_type}));

    unless ($params{lib_organism_id} or ($params{lib_genus} and $params{lib_species})) {
      $params{lib_organism_id} = $params{organism_id} if $params{organism_id};
      $params{lib_genus} = $params{genus} if $params{genus};
      $params{lib_species} = $params{species} if $params{species};
    }

    # gather all the library parameters
    my %lparams = (doc => $ldoc,);
    foreach my $p (keys %params) {
      if ($p =~ /lib_(.+)/) {
	$lparams{$1} = $params{$p};
      }
    }

    $params{library_id} = create_ch_library(%lparams);
  }

  # and then add the feature, library or both to the library_feature element
  $lf_el->appendChild(_build_element($ldoc,'library_id',$params{library_id})) if $params{library_id};
  $lf_el->appendChild(_build_element($ldoc,'feature_id',$params{feature_id})) if $params{feature_id};

  return $lf_el;
}

# CREATE library_pub element
# Note that this is just calling create_ch_pub  
#      and adding returned pub_id element as a child of library_pub
#      or just appending the pub element to library_pub if that is passed
# params
# doc - XML::DOM::Document required
# pub_id - XML::DOM pub element - if this is used then pass this and doc as only params
# uniquename - string required
# type_id - macro id for pub type or XML::DOM cvterm element optional unless 
#        creating a new pub (i.e. not null value but not part of unique key
# type - string for type from pub type cv 
# title - optional string
# volumetitle - optional string
# volume - optional string
# series_name - optional string
# issue - optional string
# pyear - optional string
# pages - optional string
# miniref - optional string
# is_obsolete - optional string 't' boolean value with default = 'f'
# publisher - optional string
sub create_ch_library_pub {
    my %params = @_;
    print "WARNING -- no XML::DOM::Document specified\n" and return unless $params{doc};
    my $ldoc = $params{doc};    ## XML::DOM::Document

    my $fp_el = $ldoc->createElement('library_pub');
    if ($params{library_id}) {
	$fp_el->appendChild(_build_element($ldoc,'library_id',$params{library_id}));
	delete $params{library_id};
    }

    unless ($params{pub_id}) {
	$params{pub_id} = create_ch_pub(%params); #will return a pub element
    }
    $fp_el->appendChild(_build_element($ldoc,'pub_id',$params{pub_id}));
    return $fp_el;
}


# CREATE library_synonym element
# params
# doc - XML::DOM::Document required
# synonym_id - XML::DOM synonym element required unless name and type provided
# name - string required unless synonym_id element provided
# type_id - macro id for synonym type or XML::DOM cvterm element
#                 required unless a synonym element provided
# type - string = name from the 'synonym type' cv
# pub_id macro id for a pub or a XML::DOM pub element required
# pub - a pub uniquename (i.e. FBrf)
# synonym_sgml - string optional but if not provided then synonym_sgml = name
#               - do not provide if a synonym element is provided
# is_current - optional string = 'f' or 't' default is 't' so don't provide this param
#               unless you know you want to change the value
# is_internal - optional string = 't' default is 'f' so don't provide this param
#               unless you know you want to change the value
sub create_ch_library_synonym {
    my %params = @_;
    print "WARNING -- no XML::DOM::Document specified\n" and return unless $params{doc};
    my $ldoc = $params{doc};    ## XML::DOM::Document

    my $ls_el = $ldoc->createElement('library_synonym');

    # this is exactly the same thing as create_ch_feature_synonym with different name
    # so call that method then change parentage?
    my $el = create_ch_feature_synonym(%params);
    my @children = $el->getChildNodes;
    $ls_el->appendChild($_) for @children;

    return $ls_el;
}

# CREATE organism or organism_id element
# params
# doc - XML::DOM::Document
# genus - string required
# species - string required
# abbreviation - string optional
# common_name - string optional
# comment - string optional
# macro_id - string to specify with id attribute
# with_id - boolean optional if 1 then organism_id element is returned
sub create_ch_organism {
    my %params = @_;
    $params{elname} = 'organism';
    $params{required} = ['genus','species'];
    my $eel = _create_simple_element(%params);
    return $eel;
}

# CREATE phendesc element
# params
# doc - XML::DOM::Document required
# genotype_id - macro id for genotype or XML::DOM genotype element
# genotype - string genotype uniquename 
# environment_id - macro id for environment or XML::DOM environment element
# environment - string environment uniquename
# description - string optional but can't be null if creating new
# type_id - macro id for phendesc type or XML::DOM cvterm element
# type - string for cvterm name from phendesc type CV
# pub_id - macro id for pub or XML::DOM pub element
# pub - string pub uniquename
sub create_ch_phendesc {
    my %params = @_;
    print "WARNING -- no XML::DOM::Document specified\n" and return unless $params{doc};
    my $ldoc = $params{doc};    ## XML::DOM::Document
    print "ERROR -- required parameters are missing: description, type or pub info - NO GO!\n" and return
      unless (($params{type_id} or $params{type}) and ($params{pub_id} or $params{pub}));
    print "ERROR -- you need either genotype info or environment info or both - NO GO!\n" and return
      unless ($params{genotype_id} or $params{genotype} or $params{environment_id} or $params{environment});


    my $pd_el = $ldoc->createElement('phendesc');  

    if ($params{genotype}) {
      $params{genotype_id} = create_ch_genotype(doc => $ldoc, uniquename => $params{genotype});
      delete $params{genotype};
    }

    if ($params{environment}) {
      $params{environment_id} = create_ch_environment(doc => $ldoc, uniquename => $params{environment});
      delete $params{environment};
    }

    if ($params{type}) {
      $params{type_id} = create_ch_cvterm(doc => $ldoc, name => $params{type}, cv => 'phendesc type');
      delete $params{type};
    }

    if ($params{pub}) {
      $params{pub_id} = create_ch_pub(doc => $ldoc, uniquename => $params{pub},);
      delete $params{pub};
    }

    foreach my $e (keys %params) {
      next if ($e eq 'doc');
	$pd_el->appendChild(_build_element($ldoc,$e,$params{$e}));
    }

    return $pd_el;
}

# CREATE phenotype or phenotype_id element
# params
# doc - XML::DOM::Document required
# uniquename - string required
# observable_id - macro id for observable or XML::DOM cvterm element optional
# attr_id - macro id for attr or XML::DOM cvterm element optional
# cvalue_id - macro id for cvalue or XML::DOM cvterm element optional
# assay_id - macro id for assay or XML::DOM cvterm element optional
# value - string optional
# macro_id - optional string to specify as ID attribute for genotype
# with_id - boolean optional if 1 then genotype_id element is returned
sub create_ch_phenotype {
    my %params = @_;
    print "WARNING -- no XML::DOM::Document specified\n" and return unless $params{doc};
    my $ldoc = $params{doc};    ## XML::DOM::Document
    print "WARNING -- no uniquename specified\n" and return unless $params{uniquename};

    my $phid_el = $ldoc->createElement('phenotype_id') if $params{with_id};
    my $ph_el = $ldoc->createElement('phenotype');
    $ph_el->setAttribute('id',$params{macro_id}) if $params{macro_id};

    foreach my $e (keys %params) {
      next if ($e eq 'doc' || $e eq 'with_id' || $e eq 'macro_id');
	$ph_el->appendChild(_build_element($ldoc,$e,$params{$e}));
    }

    if ($phid_el) {
	$phid_el->appendChild($ph_el);
	return $phid_el;
    }
    return $ph_el;
}

# CREATE phenotype_comparison element
# params
# doc - XML::DOM::Document required
# organism_id - macro id for an organism or XML::DOM organism element required unless genus and species
# genus - string required if no organism_id
# species - string required if no organism_id
# genotype1_id - macro id for a genotype or XML::DOM genotype element required unless genotype1
# genotype1 - string genotype uniquename required unless genotype1_id
# environment1_id - macro id for a environment or XML::DOM environment element required unless environment1
# environment1 - string environment uniquename required unless environment1_id
# genotype2_id - macro id for a genotype or XML::DOM genotype element required unless genotype2
# genotype2 - string genotype uniquename required unless genotype2_id
# environment2_id - macro id for a environment or XML::DOM environment element required unless environment2
# environment2 - string environment uniquename required unless environment2_id
# phenotype1_id - macro id for phenotype or XML::DOM phenotype element required unless phenotype1
# phenotype1 - string phenotype uniquename required unless phenotype1_id
# phenotype2_id - macro id for phenotype or XML::DOM phenotype element optional
# phenotype2 - string phenotype uniquename optional
# pub_id macro id for a pub or a XML::DOM pub element required unless pub
# pub - a pub uniquename (i.e. FBrf) required unless pub_id
sub create_ch_phenotype_comparison {
  my %params = @_;
  print "WARNING -- no XML::DOM::Document specified\n" and return unless $params{doc};
  my $ldoc = $params{doc};    ## XML::DOM::Document
  print "ERROR -- required parameters are missing: organism, genotype1, environment1, genotype2, environment2, phenotype1 or pub info - NO GO!\n" 
    and return
    unless (($params{genotype1_id} or $params{genotype1}) and ($params{genotype2_id} or $params{genotype2})
	    and ($params{environment1_id} or $params{environment1}) and ($params{environment2_id} or $params{environment2})
	    and ($params{phenotype1_id} or $params{phenotype1}) and ($params{pub_id} or $params{pub}) 
	    and ($params{organism_id} or ($params{genus} and $params{species})));

  my $pc_el = $ldoc->createElement('phenotype_comparison');

  #create organism_id element if genus and species are provided
  unless ($params{organism_id}) {
    $params{organism_id} = create_ch_organism(doc => $ldoc,
					      genus => $params{genus},
					      species => $params{species},
					     );

    delete $params{genus}; delete $params{species};
  }

  if ($params{genotype1}) {
    $params{genotype1_id} = create_ch_genotype(doc => $ldoc, uniquename => $params{genotype1});
    delete $params{genotype1};
  }

  if ($params{environment1}) {
    $params{environment1_id} = create_ch_environment(doc => $ldoc, uniquename => $params{environment1});
    delete $params{environment1};
  }

  if ($params{genotype2}) {
    $params{genotype2_id} = create_ch_genotype(doc => $ldoc, uniquename => $params{genotype2});
    delete $params{genotype2};
  }

  if ($params{environment2}) {
    $params{environment2_id} = create_ch_environment(doc => $ldoc, uniquename => $params{environment2});
    delete $params{environment2};
  }

  if ($params{phenotype1}) {
    $params{phenotype1_id} = create_ch_phenotype(doc => $ldoc, uniquename => $params{phenotype1});
    delete $params{phenotype1};
  }

  if ($params{phenotype2}) {
    $params{phenotype2_id} = create_ch_phenotype(doc => $ldoc, uniquename => $params{phenotype2});
    delete $params{phenotype2};
  }

  if ($params{pub}) {
    $params{pub_id} = create_ch_pub(doc => $ldoc, uniquename => $params{pub},);
    delete $params{pub};
  }

  foreach my $e (keys %params) {
    next if ($e eq 'doc');
    $pc_el->appendChild(_build_element($ldoc,$e,$params{$e}));
  }

  return $pc_el;
}
*create_ch_ph_comp = \&create_ch_phenotype_comparison;

# CREATE phenotype_comparison_cvterm element
# params
# doc - XML::DOM::Document optional - required
# phenotype_comparison_id - optional macro id for phenotype_comparison or phenotype_comparison XML::DOM element
# NOTE: to make a standalone element
# cvterm_id -  macro id for cvterm of XML::DOM cvterm element
# name - cvterm name
# cv_id - macro id for a CV or XML::DOM cv element
# cv - name of a cv
# is_obsolete - optional param for cvterm
# NOTE: you need to pass cvterm bits if attaching to existing phenotype element or 
#       creating a freestanding phenotype_cvterm
# rank - optional with default = 0 so only pass if you want a different rank
sub create_ch_phenotype_comparison_cvterm {
  my %params = @_;
  print "WARNING -- no XML::DOM::Document specified\n" and return unless $params{doc};
  my $ldoc = $params{doc};    ## XML::DOM::Document

  my $ect_el = $ldoc->createElement('phenotype_comparison_cvterm');

  # create a cvterm element if necessary
  if ($params{name}) {
    print "ERROR: You don't have all the parameters required to make a cvterm, NO GO!\n" and return
      unless ($params{cv_id} or $params{cv});
    my %cvtparams = (doc => $ldoc,
		     name => $params{name},
		    );
    delete $params{name};

    if ($params{cv_id}) {
      $cvtparams{cv_id} = $params{cv_id};
      delete $params{cv_id}; 
    } elsif ($params{cv}) {
      $cvtparams{cv} = $params{cv};
      delete $params{cv}; 
    } else {
      print "WARNING -- you're trying to make a cvterm without providing a cv - Sorry, NO GO\n" and return;
    }

    if ($params{is_obsolete}) {
      $cvtparams{is_obsolete} = $params{is_obsolete};
      delete $params{is_obsolete};
    }
    $params{cvterm_id} = create_ch_cvterm(%cvtparams);
  }

  # now see which elements to attach to phenotype_cvterm
  $ect_el->appendChild(_build_element($ldoc,'phenotype_comparison_id',$params{phenotype_comparison_id})) if $params{phenotype_comparison_id};
  $ect_el->appendChild(_build_element($ldoc,'cvterm_id',$params{cvterm_id})) if $params{cvterm_id};

  #add the required rank element 
  my $rank = '0';
  $rank = $params{rank} if $params{rank};
  $ect_el->appendChild(_build_element($ldoc,'rank',$rank));

  return $ect_el;
}
*create_ch_ph_comp_cvt = \&create_ch_phenotype_comparison_cvterm;

# CREATE phenotype_cvterm element
# params
# doc - XML::DOM::Document optional - required
# phenotype_id - macro id for phenotype or XML::DOM phenotype element
# uniquename - phenotype uniquename
# NOTE: you need to pass phenotype bits if attaching to existing cvterm element or 
#       creating a freestanding phenotype_cvterm
# cvterm_id -  macro id for cvterm of XML::DOM cvterm element
# name - cvterm name
# cv_id - macro id for a CV or XML::DOM cv element
# cv - name of a cv
# is_obsolete - optional param for cvterm
# rank - optional with default = 0 so only pass if you want a different rank
# NOTE: you need to pass cvterm bits if attaching to existing phenotype element or 
#       creating a freestanding phenotype_cvterm
sub create_ch_phenotype_cvterm {
  my %params = @_;
  print "WARNING -- no XML::DOM::Document specified\n" and return unless $params{doc};
  my $ldoc = $params{doc};    ## XML::DOM::Document

  my $ect_el = $ldoc->createElement('phenotype_cvterm');

  # create an phenotype if necessary
  if ($params{uniquename}) {
    $params{phenotype_id} = create_ch_phenotype(doc => $ldoc,
						uniquename => $params{uniquename},
					       );
    delete $params{uniquename};
  }

  # create a cvterm element if necessary
  if ($params{name}) {
    print "ERROR: You don't have all the parameters required to make a cvterm, NO GO!\n" and return
      unless ($params{cv_id} or $params{cv});
    my %cvtparams = (doc => $ldoc,
		     name => $params{name},
		    );
    delete $params{name};

    if ($params{cv_id}) {
      $cvtparams{cv_id} = $params{cv_id};
      delete $params{cv_id}; 
    } elsif ($params{cv}) {
      $cvtparams{cv} = $params{cv};
      delete $params{cv}; 
    } else {
      print "WARNING -- you're trying to make a cvterm without providing a cv - Sorry, NO GO\n" and return;
    }

    if ($params{is_obsolete}) {
      $cvtparams{is_obsolete} = $params{is_obsolete};
      delete $params{is_obsolete};
    }
    $params{cvterm_id} = create_ch_cvterm(%cvtparams);      
  }

  # now see which elements to attach to phenotype_cvterm
  $ect_el->appendChild(_build_element($ldoc,'phenotype_id',$params{phenotype_id})) if $params{phenotype_id};
  $ect_el->appendChild(_build_element($ldoc,'cvterm_id',$params{cvterm_id})) if $params{cvterm_id};

  #add the required rank element 
  my $rank = '0';
  $rank = $params{rank} if $params{rank};
  $ect_el->appendChild(_build_element($ldoc,'rank',$rank));
  
  return $ect_el;
}
*create_ch_ph_cvt = \&create_ch_phenotype_cvterm;

# CREATE phenstatement element
# params
# doc - XML::DOM::Document required
# genotype_id - macro id for a genotype or XML::DOM genotype element required unless genotype
# genotype - string genotype uniquename required unless genotype_id
# environment_id - macro id for a environment or XML::DOM environment element required unless environment
# environment - string environment uniquename required unless environment_id
# phenotype_id - macro id for phenotype or XML::DOM phenotype element required unless phenotype
# phenotype - string phenotype uniquename required unless phenotype_id
# type_id - macro id for a phenstatement type or XML::DOM cvterm element
# pub_id - macro id for a pub or a XML::DOM pub element required unless pub
# pub - a pub uniquename (i.e. FBrf) required unless pub_id
sub create_ch_phenstatement {
  my %params = @_;
  print "WARNING -- no XML::DOM::Document specified\n" and return unless $params{doc};
  my $ldoc = $params{doc};    ## XML::DOM::Document
  print "ERROR -- required parameters are missing: genotype, environment, phenotype, type and pub all required - NO GO!\n" 
    and return
    unless (($params{genotype_id} or $params{genotype}) and ($params{environment_id} or $params{environment}) 
	    and ($params{phenotype_id} or $params{phenotype}) and ($params{pub_id} or $params{pub}) 
	    and $params{type_id});

  my $pc_el = $ldoc->createElement('phenstatement');

  if ($params{genotype}) {
    $params{genotype_id} = create_ch_genotype(doc => $ldoc, uniquename => $params{genotype});
    delete $params{genotype};
  }

  if ($params{environment}) {
    $params{environment_id} = create_ch_environment(doc => $ldoc, uniquename => $params{environment});
    delete $params{environment};
  }

  if ($params{phenotype}) {
    $params{phenotype_id} = create_ch_phenotype(doc => $ldoc, uniquename => $params{phenotype});
    delete $params{phenotype};
  }

  if ($params{pub}) {
    $params{pub_id} = create_ch_pub(doc => $ldoc, uniquename => $params{pub},);
    delete $params{pub};
  }

  foreach my $e (keys %params) {
    next if ($e eq 'doc');
    $pc_el->appendChild(_build_element($ldoc,$e,$params{$e}));
  }

  return $pc_el;
}

# CREATE pub or pub_id element
# params
# doc - XML::DOM::Document required
# uniquename - string required
# type_id - macro id for pub type or XML::DOM cvterm element optional unless 
#        creating a new pub (i.e. not null value but not part of unique key
# type - string from pub type cv
# title - optional string
# volumetitle - optional string
# volume - optional string
# series_name - optional string
# issue - optional string
# pyear - optional string
# pages - optional string
# miniref - optional string
# is_obsolete - optional string 't' boolean value with default = 'f'
# publisher - optional string
# macro_id - string optional if provide then add an ID attribute to the top level element of provided value
# with_id - boolean optional if 1 then pub_id element is returned
# no_lookup - boolean option if 1 then default op="lookup" attribute will not be added to element
sub create_ch_pub {
    my %params = @_;
    print "WARNING -- no XML::DOM::Document specified\n" and return unless $params{doc};
    my $ldoc = $params{doc};    ## XML::DOM::Document

    my $pubid_el = $ldoc->createElement('pub_id') if $params{with_id};

    my $pub_el = $ldoc->createElement('pub');
    $pub_el->setAttribute('id',$params{macro_id}) if $params{macro_id};  

    # add an op="lookup" attribute unless no_lookup is specified
    unless ($params{no_lookup}) {
	$pub_el->setAttribute('op','lookup');
    }

    if ($params{type}) {
      $params{type_id} = create_ch_cvterm(doc => $ldoc,
				   name => $params{type},
				   cv => 'pub type',
				  );
      delete $params{type};
    }

    foreach my $e (keys %params) {
	next if ($e eq 'doc' || $e eq 'with_id' || $e eq 'no_lookup' || $e eq 'macro_id');
	$pub_el->appendChild(_build_element($ldoc,$e,$params{$e}));
    }

    if ($pubid_el) {
	$pubid_el->appendChild($pub_el);
	return $pubid_el;
    }
    return $pub_el;
}

# CREATE pubauthor element
# params
# doc - XML::DOM::Document required
# pub_id -  macro pub id or XML::DOM pub element optional to create a freestanding pubauthor element
# pub - pub uniquename optional but required if making a freestanding element unless pub_id 
# rank - positive integer required 
# surname - string required 
# editor - boolean 't' or 'f' default = 'f' so don't pass unless you want to change
# givennames - string optional
# suffix - string optional  
sub create_ch_pubauthor {
    my %params = @_;
    print "WARNING -- no XML::DOM::Document specified\n" and return unless $params{doc};
    my $ldoc = $params{doc};    ## XML::DOM::Document

    print "WARNING -- missing required rank (positive integer) -- NO GO!\n" 
      and return unless ($params{rank});

    print "WARNING -- no surname parameter present -- I TRUST YOU ARE NOT DOING AN INSERT\n"
      unless ($params{surname});

    ## issue some warnings if surname, givennames or suffix are too long
    print "WARNING - long surname.  Truncation to 100 characters will occur" 
      if $params{surname} and (length($params{surname}) > 100);
    print "WARNING - long givennames.  Truncation to 100 characters will occur" 
      if $params{givennames} and (length($params{givennames}) > 100);
    print "WARNING - long suffix.  Truncation to 100 characters will occur" 
      if $params{suffix} and (length($params{suffix}) > 100);

    my $pa_el = $ldoc->createElement('pubauthor');

    # deal with pub info if provided - implies a freestanding pubauthor
    if ($params{pub}) {
      $params{pub_id} = create_ch_pub(doc => $ldoc, uniquename => $params{pub});
      delete $params{pub};
    }

    foreach my $e (keys %params) {
      next if ($e eq 'doc');
      $pa_el->appendChild(_build_element($ldoc,$e,$params{$e}));
    }
    
    return $pa_el;
}

sub create_ch_pubprop {
    my %params = @_;
    $params{parentname} = 'pub';
    my $fp_el = create_ch_prop(%params);
    return $fp_el;
}

# CREATE pub_dbxref element
# params
# doc - XML::DOM::Document required
# pub_id - macro pub id or XML::DOM pub element optional to create freestanding pub_dbxref
# dbxref_id - macro dbxref id or XML::DOM dbxref element - required unless accession and db provided
# accession - string required unless dbxref_id provided
# db_id - macro db id or XML::DOM db element required unless dbxref_id provided
# db - string name of db
# is_current - string 't' or 'f' boolean default = 't' so don't pass unless
sub create_ch_pub_dbxref {
    my %params = @_;
    print "WARNING -- no XML::DOM::Document specified\n" and return unless $params{doc};
    my $ldoc = $params{doc};    ## XML::DOM::Document

    my $fd_el = $ldoc->createElement('pub_dbxref');

    if ($params{pub_id}) {
	$fd_el->appendChild(_build_element($ldoc,'pub_id',$params{pub_id}));
	delete $params{pub_id};
    }

    my $ic;
    if ($params{is_current}) { #assign value to a var and then remove from params
	$ic = $params{is_current};
	delete $params{is_current};
    }

    # create a dbxref element if necessary
    unless ($params{dbxref_id}) {
      print "WARNING - missing required parameters, NO GO.\n" and return unless 
	($params{accession} and ($params{db_id} or $params{db}));
      if ($params{db}) {
	$params{db_id} = create_ch_db(doc => $ldoc,
				      name => $params{db},
				     );
	delete $params{db};
      }
      
	
      $params{dbxref_id} = create_ch_dbxref(%params);
    }

    $fd_el->appendChild(_build_element($ldoc,'dbxref_id',$params{dbxref_id})); #add dbxref element
    $fd_el->appendChild(_build_element($ldoc,'is_current',$ic)) if $ic;

    return $fd_el;
}


# CREATE pub_relationship element
# NOTE: now can create freestanding
# params
# doc - XML::DOM::Document required
# object_id
# subject_id
# is_object - boolean 't'     Note: either is_subject OR is_object and NOT both must be passed
# is_subject - boolean 't'          this flag indicates if the pub info provided should be 
#                                   added in as subject or object pub
# rtype_id - macro id for a relationship type  or XML::DOM cvterm element
# rtype - string for relationship type
# NOTE: if relationship name is given will be assigned to 'pub relationship type' cv
# pub_id - macro id for a pub or XML::DOM pub element required unless uniquename provided
# uniquename - uniquename of the pub - required unless pub element provided
# type_id - macro id for a pub type or XML::DOM cvterm element for pub type
#           note: this is optional for the moment but encouraged
# type - string from pub type cv
sub create_ch_pub_relationship {
    my %params = @_;
    print "WARNING -- no XML::DOM::Document specified\n" and return unless $params{doc};
    my $ldoc = $params{doc};    ## XML::DOM::Document

    ## pub_relationship element (will be returned)
    my $fr_el = $ldoc->createElement('pub_relationship');

    # add relationship type
    my $rtype_el = $ldoc->createElement('type_id');
    if ($params{rtype}) {
      my $cvterm_el = create_ch_cvterm(doc => $ldoc,
				       name => $params{rtype},
				       cv => 'pub relationship type'
				       # note that we may want to add is_relationship = 1 in the future
				      );
      $rtype_el->appendChild($cvterm_el);
    } elsif (ref($params{rtype_id})) {
      $rtype_el->appendChild($params{rtype_id});
    } else {
      my $val = $ldoc->createTextNode("$params{rtype_id}");
      $rtype_el->appendChild($val);
    }

    $fr_el->appendChild($rtype_el);

    # now deal with various pub  options
    if ($params{object_id}) { 
         # create the object_id element
	$fr_el->appendChild(_build_element($ldoc,'object_id',$params{object_id}));
	$params{is_subject} = 1 unless $params{subject_id};
    }

    if ($params{subject_id}) { 
         # create the subject_id element
	$fr_el->appendChild(_build_element($ldoc,'subject_id',$params{subject_id}));
	$params{is_object} = 1 unless $params{object_id};
    }

    return $fr_el if (defined($params{object_id})  and defined($params{subject_id}));

    # deal with creating the pub bits if present
    unless ($params{pub_id}) {
	my %pub_params = (doc => $ldoc,
			  uniquename => $params{uniquename},
			 );

	if ($params{type}) {
	  $params{type_id} = create_ch_cvterm(doc => $ldoc,
					      name => $params{type},
					      cv => 'pub type',
					     );
	  delete $params{type};
	}
	$pub_params{type_id} = $params{type_id} if $params{type_id};
	$params{pub_id} = create_ch_pub(%pub_params);
    } # now we have a pub element to associate as subject or object

    # so do it as either subject or object
    my $fr_id;
    if ($params{is_object}) {
	$fr_id = $ldoc->createElement('object_id');
    } else {
	$fr_id = $ldoc->createElement('subject_id');
    }

    $fr_id->appendChild($params{pub_id});

    $fr_el->appendChild($fr_id);

    return $fr_el;
}
*create_ch_pr = \&create_ch_pub_relationship;

# CREATE synonym or synonym_id element
# params
# doc - XML::DOM::Document required
# name - string required
# synonym_sgml - string optional but if not provided then synonym_sgml = name
# type_id - macro id or XML::DOM cvterm element
# type - string = name from the 'synonym type' cv 
# macro_id - string to assign id attribute to this element
# with_id - boolean optional if 1 then synonym_id element is returned
sub create_ch_synonym {
    my %params = @_;
    print "WARNING -- no XML::DOM::Document specified\n" and return unless $params{doc};
    my $ldoc = $params{doc};    ## XML::DOM::Document

    #assign required synonym_sgml field to name if synonym_sgml not provided
    $params{synonym_sgml} = $params{name} unless ($params{synonym_sgml});
    ## synonym_id element (will be returned)
    my $synid_el = $ldoc->createElement('synonym_id') if $params{with_id};

    my $syn_el = $ldoc->createElement('synonym');
    $syn_el->setAttribute('id',$params{macro_id}) if $params{macro_id};     
    
    # set up a type_id element if necessary
    if ($params{type}) {
      my $cv_el = create_ch_cv(doc => $ldoc,
			       name => 'synonym type',
			      );
      $params{type_id} = create_ch_cvterm(doc => $ldoc,
					  name => $params{type},
					  cv_id => $cv_el,);
      delete $params{type};
    }

    foreach my $e (keys %params) {
      next if ($e eq 'doc' || $e eq 'with_id' || $e eq 'macro_id');
      $syn_el->appendChild(_build_element($ldoc,$e,$params{$e}));
    }

    if ($synid_el) {
	$synid_el->appendChild($syn_el);
	return $synid_el;
    }
    return $syn_el;
}

# generic helper method for creating a simple table element that does not contain elements 
# that refer to other tables (i.e. no foreign key references)
# params
# doc - XML::DOM::Document required
# elname - string required - the element (table) name that you want to create
# required - array ref to list of required elements - do not need to pass doc here
# all other parameters wanted for that element
sub _create_simple_element {
  my %params = @_;
  print "ERROR -- no XML::DOM::Document specified\n" and return unless $params{doc};
  my $ldoc = $params{doc};    ## XML::DOM::Document
  print "ERROR -- you must provide the name of the elementname\n" 
    and return unless $params{elname};  
  print "ERROR -- you must provide at least one required element\n" 
    and return unless $params{required};

  my $elname = $params{elname};
  my @required = @{$params{required}};
  delete $params{elname};
  delete $params{required};

  for (@required) {
    print "ERROR: You are missing a required parameter - $_ - NO GO!\n" and return 
      unless $params{$_};
  }

  my $id_el = $ldoc->createElement("${elname}_id") if $params{with_id};


  my $el = $ldoc->createElement("$elname");
  $el->setAttribute('id',$params{macro_id}) if $params{macro_id};  
  
  foreach my $e (keys %params) {
    next if ($e eq 'doc' || $e eq 'with_id' || $e eq 'macro_id');
    $el->appendChild(_build_element($ldoc,$e,$params{$e}));
  }
  if ($id_el) {
    $id_el->appendChild($el);
    return $id_el;
  }
  return $el;
}


# generic method for creating a prop element
# params
# doc - XML::DOM::Document required
# parentname - string required - the parent element name that you want to add prop to eg. feature
#              to make a featureprop or feature_cvterm to make feature_cvtermprop
# parent_id - optional macro_id or XML::DOM element for an table_id for the prop to make a standalone prop
#             NOTE that this param name should be eg. feature_id for featureprop or pub_id for pubprop etc.
# value - string - not strictly required but if you don't provide this then not much point
# type_id - macro_id for a property type or XML::DOM cvterm element required
# type - string from a property type cv
#        Note: will default to making a type of from 'tablenameprop type' cv unless cvname is provided
# WARNING: as property type cv names are not consistent SAFEST to provide cvname
# cvname - string 'optional' but see above for type and do not provide if passing a cvterm element
# rank - integer with a default of zero so don't use unless you want a rank other than 0
sub create_ch_prop {
    my %params = @_;
    print "WARNING -- no XML::DOM::Document specified\n" and return unless $params{doc};
    my $ldoc = $params{doc};    ## XML::DOM::Document
    print "WARNING -- you must provide the name of the element to which this prop will be added\n" 
      and return unless $params{parentname};
    my $tbl = $params{parentname};
    print "WARNING -- you haven't provided the required information for type -- NO GO!\n" 
      and return unless ($params{type} or $params{type_id});

    my $p_el = $ldoc->createElement("${tbl}prop");

    # check to see if making a stand alone prop element
    if ($params{"${tbl}_id"}) {
      $p_el->appendChild(_build_element($ldoc,"${tbl}_id",$params{"${tbl}_id"}));
      delete $params{"${tbl}_id"};
    }

    foreach my $e (keys %params) {
	next unless ($e eq 'value' || $e eq 'type_id' || $e eq 'type');
	if ($e eq 'value') {
	    #my $val = $params{$e};
	    ## Strip non-ascii characters from the featureprop value
	    #$val =~ s/[\x80-\xff]//g;
	    ## Escape single-quotes
	    #$val =~ s/\'/\\\'/g;
	    #$params{$e} = $val;
	    $p_el->appendChild(_build_element($ldoc,$e,$params{$e}));
	} elsif ($e eq 'type_id') {
	  $p_el->appendChild(_build_element($ldoc,$e,$params{$e}));
	} else {
	  my $cv = "${tbl}prop type";
	  $cv = $params{cvname} if $params{cvname};
	  my $cv_el =  create_ch_cv(doc => $ldoc,
				    name => $cv,
				   );
	  my $ct_el = (create_ch_cvterm(doc => $ldoc,
					name => $params{$e},
					cv_id => $cv_el,));
	  $p_el->appendChild(_build_element($ldoc,'type_id',$ct_el));
	}
    }

    #add the required rank element 
    my $rank = '0';
    $rank = $params{rank} if $params{rank};
    $p_el->appendChild(_build_element($ldoc,'rank',$rank));

    return $p_el;
}

# helper method to build up elements
sub _build_element {
    my $doc = shift;
    my $ename = shift;
    my $eval = shift;

    my $el = $doc->createElement("$ename");
    my $val;
    if (!ref($eval)) {
	$val = $doc->createTextNode("$eval");
    } else {
	$val = $eval;
    }
    $el->appendChild($val);
    return $el;
}

1;
