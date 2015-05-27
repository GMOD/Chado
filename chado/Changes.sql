--when schema elements are added, including new tables or changes to table
--columns, or when initialize.sql is changed, the sql to make those changes
--happen should go here.

--gmod version 1.01

--This is a function to seek out exons of transcripts and orders them,
--using feature_relationship.rank, in "transcript order" numbering
--from 0, taking strand into account. It will not touch transcripts that
--already have their exons ordered (in case they have a non-obvious
--ordering due to trans splicing). It takes as an argument the
--feature.type_id of the parent transcript type (typically, mRNA, although
--non coding transcript types should work too).

CREATE OR REPLACE FUNCTION order_exons (integer) RETURNS void AS '
  DECLARE
    parent_type      ALIAS FOR $1;
    exon_id          int;
    part_of          int;
    exon_type        int;
    strand           int;
    arow             RECORD;
    order_by         varchar;
    rowcount         int;
    exon_count       int;
    ordered_exons    int;    
    transcript_id    int;
  BEGIN
    SELECT INTO part_of cvterm_id FROM cvterm WHERE name=''part_of''
      AND cv_id IN (SELECT cv_id FROM cv WHERE name=''relationship'');
    --SELECT INTO exon_type cvterm_id FROM cvterm WHERE name=''exon''
    --  AND cv_id IN (SELECT cv_id FROM cv WHERE name=''sequence'');

    --RAISE NOTICE ''part_of %, exon %'',part_of,exon_type;

    FOR transcript_id IN
      SELECT feature_id FROM feature WHERE type_id = parent_type
    LOOP
      SELECT INTO rowcount count(*) FROM feature_relationship
        WHERE object_id = transcript_id
          AND rank = 0;

      --Dont modify this transcript if there are already numbered exons or
      --if there is only one exon
      IF rowcount = 1 THEN
        --RAISE NOTICE ''skipping transcript %, row count %'',transcript_id,rowcount;
        CONTINUE;
      END IF;

      --need to reverse the order if the strand is negative
      SELECT INTO strand strand FROM featureloc WHERE feature_id=transcript_id;
      IF strand > 0 THEN
          order_by = ''fl.fmin'';      
      ELSE
          order_by = ''fl.fmax desc'';
      END IF;

      exon_count = 0;
      FOR arow IN EXECUTE 
        ''SELECT fr.*, fl.fmin, fl.fmax
          FROM feature_relationship fr, featureloc fl
          WHERE fr.object_id  = ''||transcript_id||''
            AND fr.subject_id = fl.feature_id
            AND fr.type_id    = ''||part_of||''
            ORDER BY ''||order_by
      LOOP
        --number the exons for a given transcript
        UPDATE feature_relationship
          SET rank = exon_count 
          WHERE feature_relationship_id = arow.feature_relationship_id;
        exon_count = exon_count + 1;
      END LOOP; 

    END LOOP;

  END;
' LANGUAGE 'plpgsql';


--added foreign key for pub_id to phenotype_comparison_cvterm
ALTER TABLE phenotype_comparison_cvterm ADD FOREIGN KEY (pub_id) references pub (pub_id) on delete cascade;

--Changed the Audit table triggers to work with newer versions of Postgres.
--This didn't change the the default schema at all (since audit.sql isn't
--part of the default schema.

--all_feature_name view also searches featureprop and dbxref.accesion
--see the comments in modules/sequence/sequence_views.sql  for more
--information on how this works
CREATE OR REPLACE VIEW all_feature_names (
  feature_id,
  name
) AS
SELECT feature_id,CAST(substring(uniquename from 0 for 255) as varchar(255)) as name FROM feature
UNION
SELECT feature_id, name FROM feature where name is not null
UNION
SELECT fs.feature_id,s.name FROM feature_synonym fs, synonym s
  WHERE fs.synonym_id = s.synonym_id
UNION
SELECT fp.feature_id, CAST(substring(fp.value from 0 for 255) as varchar(255)) as name FROM featureprop fp
UNION
SELECT fd.feature_id, d.accession FROM feature_dbxref fd, dbxref d
  WHERE fd.dbxref_id = d.dbxref_id;


DROP VIEW all_feature_names;
CREATE OR REPLACE VIEW all_feature_names (
  feature_id,
  name,
  organism_id
) AS
SELECT feature_id,CAST(substring(uniquename from 0 for 255) as varchar(255)) as name,organism_id FROM feature
UNION
SELECT feature_id, name, organism_id FROM feature where name is not null
UNION
SELECT fs.feature_id,s.name,f.organism_id FROM feature_synonym fs, synonym s, feature f
  WHERE fs.synonym_id = s.synonym_id AND fs.feature_id = f.feature_id
UNION
SELECT fp.feature_id, CAST(substring(fp.value from 0 for 255) as varchar(255)) as name,f.organism_id FROM featureprop fp, feature f
  WHERE f.feature_id = fp.feature_id
UNION
SELECT fd.feature_id, d.accession, f.organism_id FROM feature_dbxref fd, dbxref d,feature f
  WHERE fd.dbxref_id = d.dbxref_id AND fd.feature_id = f.feature_id;


--all of the primary keys were changed to be bigserial/bigint

ALTER TABLE cell_line ALTER COLUMN cell_line_id TYPE bigserial;
ALTER TABLE cell_line_relationship ALTER COLUMN cell_line_relationship_id TYPE bigserial;
ALTER TABLE cell_line_synonym ALTER COLUMN cell_line_synonym_id TYPE bigserial;
ALTER TABLE cell_line_cvterm ALTER COLUMN cell_line_cvterm_id TYPE bigserial;
ALTER TABLE cell_line_dbxref ALTER COLUMN cell_line_dbxref_id TYPE bigserial;
ALTER TABLE cell_lineprop ALTER COLUMN cell_lineprop_id TYPE bigserial;
ALTER TABLE cell_lineprop_pub ALTER COLUMN cell_lineprop_pub_id TYPE bigserial;
ALTER TABLE cell_line_feature ALTER COLUMN cell_line_feature_id TYPE bigserial;
ALTER TABLE cell_line_cvtermprop ALTER COLUMN cell_line_cvtermprop_id TYPE bigserial;
ALTER TABLE cell_line_pub ALTER COLUMN cell_line_pub_id TYPE bigserial;
ALTER TABLE cell_line_library ALTER COLUMN cell_line_library_id TYPE bigserial;
ALTER TABLE analysis ALTER COLUMN analysis_id TYPE bigserial;
ALTER TABLE analysisprop ALTER COLUMN analysisprop_id TYPE bigserial;
ALTER TABLE analysisfeature ALTER COLUMN analysisfeature_id TYPE bigserial;
ALTER TABLE contact ALTER COLUMN contact_id TYPE bigserial;
ALTER TABLE contact_relationship ALTER COLUMN contact_relationship_id TYPE bigserial;
ALTER TABLE cv ALTER COLUMN cv_id TYPE bigserial;
ALTER TABLE cvterm ALTER COLUMN cvterm_id TYPE bigserial;
ALTER TABLE cvterm_relationship ALTER COLUMN cvterm_relationship_id TYPE bigserial;
ALTER TABLE cvtermpath ALTER COLUMN cvtermpath_id TYPE bigserial;
ALTER TABLE cvtermsynonym ALTER COLUMN cvtermsynonym_id TYPE bigserial;
ALTER TABLE cvterm_dbxref ALTER COLUMN cvterm_dbxref_id TYPE bigserial;
ALTER TABLE cvtermprop ALTER COLUMN cvtermprop_id TYPE bigserial; 
ALTER TABLE dbxrefprop ALTER COLUMN dbxrefprop_id TYPE bigserial;
ALTER TABLE cvprop ALTER COLUMN cvprop_id TYPE bigserial;
ALTER TABLE chadoprop ALTER COLUMN chadoprop_id TYPE bigserial;
ALTER TABLE expression ALTER COLUMN expression_id TYPE bigserial;
ALTER TABLE expression_cvterm ALTER COLUMN expression_cvterm_id TYPE bigserial;
ALTER TABLE expression_cvtermprop ALTER COLUMN expression_cvtermprop_id TYPE bigserial;
ALTER TABLE expressionprop ALTER COLUMN expressionprop_id TYPE bigserial;
ALTER TABLE expression_pub ALTER COLUMN expression_pub_id TYPE bigserial;
ALTER TABLE feature_expression ALTER COLUMN feature_expression_id TYPE bigserial;
ALTER TABLE feature_expressionprop ALTER COLUMN feature_expressionprop_id TYPE bigserial;
ALTER TABLE eimage ALTER COLUMN eimage_id TYPE bigserial;
ALTER TABLE expression_image ALTER COLUMN expression_image_id TYPE bigserial;
ALTER TABLE tableinfo ALTER COLUMN tableinfo_id TYPE bigserial;
ALTER TABLE db ALTER COLUMN db_id TYPE bigserial;
ALTER TABLE dbxref ALTER COLUMN dbxref_id TYPE bigserial;
ALTER TABLE genotype ALTER COLUMN genotype_id TYPE bigserial;
ALTER TABLE feature_genotype ALTER COLUMN feature_genotype_id TYPE bigserial;
ALTER TABLE environment ALTER COLUMN environment_id TYPE bigserial;
ALTER TABLE environment_cvterm ALTER COLUMN environment_cvterm_id TYPE bigserial;
ALTER TABLE phenstatement ALTER COLUMN phenstatement_id TYPE bigserial;
ALTER TABLE phendesc ALTER COLUMN phendesc_id TYPE bigserial;
ALTER TABLE phenotype_comparison ALTER COLUMN phenotype_comparison_id TYPE bigserial;
ALTER TABLE phenotype_comparison_cvterm ALTER COLUMN phenotype_comparison_cvterm_id TYPE bigserial;
ALTER TABLE genotypeprop ALTER COLUMN genotypeprop_id TYPE bigserial;
ALTER TABLE interaction ALTER COLUMN interaction_id TYPE bigserial;
ALTER TABLE interactionprop ALTER COLUMN interactionprop_id TYPE bigserial;
ALTER TABLE interactionprop_pub ALTER COLUMN interactionprop_pub_id TYPE bigserial;
ALTER TABLE interaction_pub ALTER COLUMN interaction_pub_id TYPE bigserial;
ALTER TABLE interaction_expression ALTER COLUMN interaction_expression_id TYPE bigserial;
ALTER TABLE interaction_expressionprop ALTER COLUMN interaction_expressionprop_id TYPE bigserial;
ALTER TABLE interaction_cvterm ALTER COLUMN interaction_cvterm_id TYPE bigserial;
ALTER TABLE interaction_cvtermprop ALTER COLUMN interaction_cvtermprop_id TYPE bigserial;
ALTER TABLE feature_interaction ALTER COLUMN feature_interaction_id TYPE bigserial;
ALTER TABLE feature_interactionprop ALTER COLUMN feature_interactionprop_id TYPE bigserial;
ALTER TABLE feature_interaction_pub ALTER COLUMN feature_interaction_pub_id TYPE bigserial;
ALTER TABLE interaction_cell_line ALTER COLUMN interaction_cell_line_id TYPE bigserial;
ALTER TABLE interaction_group ALTER COLUMN interaction_group_id TYPE bigserial;
ALTER TABLE interaction_group_feature_interaction ALTER COLUMN interaction_group_feature_interaction_id TYPE bigserial;
ALTER TABLE library ALTER COLUMN library_id TYPE bigserial;
ALTER TABLE library_synonym ALTER COLUMN library_synonym_id TYPE bigserial;
ALTER TABLE library_pub ALTER COLUMN library_pub_id TYPE bigserial;
ALTER TABLE libraryprop ALTER COLUMN libraryprop_id TYPE bigserial;
ALTER TABLE libraryprop_pub ALTER COLUMN libraryprop_pub_id TYPE bigserial;
ALTER TABLE library_cvterm ALTER COLUMN library_cvterm_id TYPE bigserial;
ALTER TABLE library_feature ALTER COLUMN library_feature_id TYPE bigserial;
ALTER TABLE library_dbxref ALTER COLUMN library_dbxref_id TYPE bigserial;
ALTER TABLE library_expression ALTER COLUMN library_expression_id TYPE bigserial;
ALTER TABLE library_expressionprop ALTER COLUMN library_expressionprop_id TYPE bigserial;
ALTER TABLE library_featureprop ALTER COLUMN library_featureprop_id TYPE bigserial;
ALTER TABLE library_interaction ALTER COLUMN library_interaction_id TYPE bigserial;
ALTER TABLE library_relationship ALTER COLUMN library_relationship_id TYPE bigserial;
ALTER TABLE library_relationship_pub ALTER COLUMN library_relationship_pub_id TYPE bigserial;
ALTER TABLE library_strain ALTER COLUMN library_strain_id TYPE bigserial;
ALTER TABLE mageml ALTER COLUMN mageml_id TYPE bigserial;
ALTER TABLE magedocumentation ALTER COLUMN magedocumentation_id TYPE bigserial;
ALTER TABLE protocol ALTER COLUMN protocol_id TYPE bigserial;
ALTER TABLE protocolparam ALTER COLUMN protocolparam_id TYPE bigserial;
ALTER TABLE channel ALTER COLUMN channel_id TYPE bigserial;
ALTER TABLE arraydesign ALTER COLUMN arraydesign_id TYPE bigserial;
ALTER TABLE arraydesignprop ALTER COLUMN arraydesignprop_id TYPE bigserial;
ALTER TABLE assay ALTER COLUMN assay_id TYPE bigserial;
ALTER TABLE assayprop ALTER COLUMN assayprop_id TYPE bigserial;
ALTER TABLE assay_project ALTER COLUMN assay_project_id TYPE bigserial;
ALTER TABLE biomaterial ALTER COLUMN biomaterial_id TYPE bigserial;
ALTER TABLE biomaterial_relationship ALTER COLUMN biomaterial_relationship_id TYPE bigserial;
ALTER TABLE biomaterialprop ALTER COLUMN biomaterialprop_id TYPE bigserial;
ALTER TABLE biomaterial_dbxref ALTER COLUMN biomaterial_dbxref_id TYPE bigserial;
ALTER TABLE treatment ALTER COLUMN treatment_id TYPE bigserial;
ALTER TABLE biomaterial_treatment ALTER COLUMN biomaterial_treatment_id TYPE bigserial;
ALTER TABLE assay_biomaterial ALTER COLUMN assay_biomaterial_id TYPE bigserial;
ALTER TABLE acquisition ALTER COLUMN acquisition_id TYPE bigserial;
ALTER TABLE acquisitionprop ALTER COLUMN acquisitionprop_id TYPE bigserial;
ALTER TABLE acquisition_relationship ALTER COLUMN acquisition_relationship_id TYPE bigserial;
ALTER TABLE quantification ALTER COLUMN quantification_id TYPE bigserial;
ALTER TABLE quantificationprop ALTER COLUMN quantificationprop_id TYPE bigserial;
ALTER TABLE quantification_relationship ALTER COLUMN quantification_relationship_id TYPE bigserial;
ALTER TABLE control ALTER COLUMN control_id TYPE bigserial;
ALTER TABLE element ALTER COLUMN element_id TYPE bigserial;
ALTER TABLE elementresult ALTER COLUMN elementresult_id TYPE bigserial;
ALTER TABLE element_relationship ALTER COLUMN element_relationship_id TYPE bigserial;
ALTER TABLE elementresult_relationship ALTER COLUMN elementresult_relationship_id TYPE bigserial;
ALTER TABLE study ALTER COLUMN study_id TYPE bigserial;
ALTER TABLE study_assay ALTER COLUMN study_assay_id TYPE bigserial;
ALTER TABLE studydesign ALTER COLUMN studydesign_id TYPE bigserial;
ALTER TABLE studydesignprop ALTER COLUMN studydesignprop_id TYPE bigserial;
ALTER TABLE studyfactor ALTER COLUMN studyfactor_id TYPE bigserial;
ALTER TABLE studyfactorvalue ALTER COLUMN studyfactorvalue_id TYPE bigserial;
ALTER TABLE studyprop ALTER COLUMN studyprop_id TYPE bigserial;
ALTER TABLE studyprop_feature ALTER COLUMN studyprop_feature_id TYPE bigserial;
ALTER TABLE featuremap ALTER COLUMN featuremap_id TYPE bigserial;
ALTER TABLE featurerange ALTER COLUMN featurerange_id TYPE bigserial;
ALTER TABLE featurepos ALTER COLUMN featurepos_id TYPE bigserial;
ALTER TABLE featuremap_pub ALTER COLUMN featuremap_pub_id TYPE bigserial;
ALTER TABLE nd_geolocation ALTER COLUMN nd_geolocation_id TYPE bigserial;
ALTER TABLE nd_experiment ALTER COLUMN nd_experiment_id TYPE bigserial;
ALTER TABLE nd_experiment_project ALTER COLUMN nd_experiment_project_id TYPE bigserial;
ALTER TABLE nd_experimentprop ALTER COLUMN nd_experimentprop_id TYPE bigserial;
ALTER TABLE nd_experiment_pub ALTER COLUMN nd_experiment_pub_id TYPE bigserial;
ALTER TABLE nd_geolocationprop ALTER COLUMN nd_geolocationprop_id TYPE bigserial;
ALTER TABLE nd_protocol ALTER COLUMN nd_protocol_id TYPE bigserial; 
ALTER TABLE nd_reagent ALTER COLUMN nd_reagent_id TYPE bigserial;
ALTER TABLE nd_protocol_reagent ALTER COLUMN nd_protocol_reagent_id TYPE bigserial;
ALTER TABLE nd_protocolprop ALTER COLUMN nd_protocolprop_id TYPE bigserial;
ALTER TABLE nd_experiment_stock ALTER COLUMN nd_experiment_stock_id TYPE bigserial;
ALTER TABLE nd_experiment_protocol ALTER COLUMN nd_experiment_protocol_id TYPE bigserial;
ALTER TABLE nd_experiment_phenotype ALTER COLUMN nd_experiment_phenotype_id TYPE bigserial;
ALTER TABLE nd_experiment_genotype ALTER COLUMN nd_experiment_genotype_id TYPE bigserial;
ALTER TABLE nd_reagent_relationship ALTER COLUMN nd_reagent_relationship_id TYPE bigserial;
ALTER TABLE nd_reagentprop ALTER COLUMN nd_reagentprop_id TYPE bigserial;
ALTER TABLE nd_experiment_stockprop ALTER COLUMN nd_experiment_stockprop_id TYPE bigserial;
ALTER TABLE nd_experiment_stock_dbxref ALTER COLUMN nd_experiment_stock_dbxref_id TYPE bigserial;
ALTER TABLE nd_experiment_dbxref ALTER COLUMN nd_experiment_dbxref_id TYPE bigserial;
ALTER TABLE nd_experiment_contact ALTER COLUMN nd_experiment_contact_id TYPE bigserial;
ALTER TABLE organism ALTER COLUMN organism_id TYPE bigserial;
ALTER TABLE organism_dbxref ALTER COLUMN organism_dbxref_id TYPE bigserial;
ALTER TABLE organismprop ALTER COLUMN organismprop_id TYPE bigserial;
ALTER TABLE organismprop_pub ALTER COLUMN organismprop_pub_id TYPE bigserial;
ALTER TABLE organism_pub ALTER COLUMN organism_pub_id TYPE bigserial;
ALTER TABLE organism_cvterm ALTER COLUMN organism_cvterm_id TYPE bigserial;
ALTER TABLE organism_cvtermprop ALTER COLUMN organism_cvtermprop_id TYPE bigserial;
ALTER TABLE strain ALTER COLUMN strain_id TYPE bigserial;
ALTER TABLE strain_cvterm ALTER COLUMN strain_cvterm_id TYPE bigserial;
ALTER TABLE strain_cvtermprop ALTER COLUMN strain_cvtermprop_id TYPE bigserial;
ALTER TABLE strain_relationship ALTER COLUMN strain_relationship_id TYPE bigserial;
ALTER TABLE strain_relationship_pub ALTER COLUMN strain_relationship_pub_id TYPE bigserial;
ALTER TABLE strainprop ALTER COLUMN strainprop_id TYPE bigserial;
ALTER TABLE strainprop_pub ALTER COLUMN strainprop_pub_id TYPE bigserial;
ALTER TABLE strain_dbxref ALTER COLUMN strain_dbxref_id TYPE bigserial;
ALTER TABLE strain_pub ALTER COLUMN strain_pub_id TYPE bigserial;
ALTER TABLE strain_synonym ALTER COLUMN strain_synonym_id TYPE bigserial;
ALTER TABLE strain_feature ALTER COLUMN strain_feature_id TYPE bigserial;
ALTER TABLE strain_featureprop ALTER COLUMN strain_featureprop_id TYPE bigserial;
ALTER TABLE strain_phenotype ALTER COLUMN strain_phenotype_id TYPE bigserial;
ALTER TABLE strain_phenotypeprop ALTER COLUMN strain_phenotypeprop_id TYPE bigserial;
ALTER TABLE phenotype ALTER COLUMN phenotype_id TYPE bigserial;
ALTER TABLE phenotype_cvterm ALTER COLUMN phenotype_cvterm_id TYPE bigserial;
ALTER TABLE feature_phenotype ALTER COLUMN feature_phenotype_id TYPE bigserial;
ALTER TABLE phenotypeprop ALTER COLUMN phenotypeprop_id TYPE bigserial;
ALTER TABLE phylotree ALTER COLUMN phylotree_id TYPE bigserial;
ALTER TABLE phylotree_pub ALTER COLUMN phylotree_pub_id TYPE bigserial;
ALTER TABLE phylonode ALTER COLUMN phylonode_id TYPE bigserial;
ALTER TABLE phylonode_dbxref ALTER COLUMN phylonode_dbxref_id TYPE bigserial;
ALTER TABLE phylonode_pub ALTER COLUMN phylonode_pub_id TYPE bigserial;
ALTER TABLE phylonode_organism ALTER COLUMN phylonode_organism_id TYPE bigserial;
ALTER TABLE phylonodeprop ALTER COLUMN phylonodeprop_id TYPE bigserial;
ALTER TABLE phylonode_relationship ALTER COLUMN phylonode_relationship_id TYPE bigserial;
ALTER TABLE project ALTER COLUMN project_id TYPE bigserial;
ALTER TABLE projectprop ALTER COLUMN projectprop_id TYPE bigserial;
ALTER TABLE project_relationship ALTER COLUMN project_relationship_id TYPE bigserial;
ALTER TABLE project_pub ALTER COLUMN project_pub_id TYPE bigserial;
ALTER TABLE project_contact ALTER COLUMN project_contact_id TYPE bigserial;
ALTER TABLE pub ALTER COLUMN pub_id TYPE bigserial;
ALTER TABLE pub_relationship ALTER COLUMN pub_relationship_id TYPE bigserial;
ALTER TABLE pub_dbxref ALTER COLUMN pub_dbxref_id TYPE bigserial;
ALTER TABLE pubauthor ALTER COLUMN pubauthor_id TYPE bigserial;
ALTER TABLE pubprop ALTER COLUMN pubprop_id TYPE bigserial;
ALTER TABLE feature ALTER COLUMN feature_id TYPE bigserial;
ALTER TABLE featureloc ALTER COLUMN featureloc_id TYPE bigserial;
ALTER TABLE featureloc_pub ALTER COLUMN featureloc_pub_id TYPE bigserial;
ALTER TABLE feature_pub ALTER COLUMN feature_pub_id TYPE bigserial;
ALTER TABLE feature_pubprop ALTER COLUMN feature_pubprop_id TYPE bigserial;
ALTER TABLE featureprop ALTER COLUMN featureprop_id TYPE bigserial;
ALTER TABLE featureprop_pub ALTER COLUMN featureprop_pub_id TYPE bigserial;
ALTER TABLE feature_dbxref ALTER COLUMN feature_dbxref_id TYPE bigserial;
ALTER TABLE feature_relationship ALTER COLUMN feature_relationship_id TYPE bigserial;
ALTER TABLE feature_relationship_pub ALTER COLUMN feature_relationship_pub_id TYPE bigserial;
ALTER TABLE feature_relationshipprop ALTER COLUMN feature_relationshipprop_id TYPE bigserial;
ALTER TABLE feature_relationshipprop_pub ALTER COLUMN feature_relationshipprop_pub_id TYPE bigserial;
ALTER TABLE feature_cvterm ALTER COLUMN feature_cvterm_id TYPE bigserial;
ALTER TABLE feature_cvtermprop ALTER COLUMN feature_cvtermprop_id TYPE bigserial;
ALTER TABLE feature_cvterm_dbxref ALTER COLUMN feature_cvterm_dbxref_id TYPE bigserial;
ALTER TABLE feature_cvterm_pub ALTER COLUMN feature_cvterm_pub_id TYPE bigserial;
ALTER TABLE synonym ALTER COLUMN synonym_id TYPE bigserial;
ALTER TABLE feature_synonym ALTER COLUMN feature_synonym_id TYPE bigserial;
ALTER TABLE stock ALTER COLUMN stock_id TYPE bigserial;
ALTER TABLE stock_pub ALTER COLUMN stock_pub_id TYPE bigserial;
ALTER TABLE stockprop ALTER COLUMN stockprop_id TYPE bigserial;
ALTER TABLE stockprop_pub ALTER COLUMN stockprop_pub_id TYPE bigserial;
ALTER TABLE stock_relationship ALTER COLUMN stock_relationship_id TYPE bigserial;
ALTER TABLE stock_relationship_cvterm ALTER COLUMN stock_relationship_cvterm_id TYPE bigserial;
ALTER TABLE stock_relationship_pub ALTER COLUMN stock_relationship_pub_id TYPE bigserial;
ALTER TABLE stock_dbxref ALTER COLUMN stock_dbxref_id TYPE bigserial;
ALTER TABLE stock_cvterm ALTER COLUMN stock_cvterm_id TYPE bigserial;
ALTER TABLE stock_cvtermprop ALTER COLUMN stock_cvtermprop_id TYPE bigserial;
ALTER TABLE stock_genotype ALTER COLUMN stock_genotype_id TYPE bigserial;
ALTER TABLE stockcollection ALTER COLUMN stockcollection_id TYPE bigserial; 
ALTER TABLE stockcollectionprop ALTER COLUMN stockcollectionprop_id TYPE bigserial;
ALTER TABLE stockcollection_stock ALTER COLUMN stockcollection_stock_id TYPE bigserial;
ALTER TABLE stock_dbxrefprop ALTER COLUMN stock_dbxrefprop_id TYPE bigserial;


ALTER TABLE cell_line ALTER COLUMN organism_id type bigint;
ALTER TABLE cell_line_relationship ALTER COLUMN         subject_id type bigint;
ALTER TABLE cell_line_relationship ALTER COLUMN         object_id type bigint;
ALTER TABLE cell_line_relationship ALTER COLUMN  type_id type bigint;
ALTER TABLE cell_line_synonym ALTER COLUMN  cell_line_id type bigint;
ALTER TABLE cell_line_synonym ALTER COLUMN  synonym_id type bigint;
ALTER TABLE cell_line_synonym ALTER COLUMN  pub_id type bigint;
ALTER TABLE cell_line_cvterm ALTER COLUMN  cell_line_id type bigint;
ALTER TABLE cell_line_cvterm ALTER COLUMN  cvterm_id type bigint;
ALTER TABLE cell_line_cvterm ALTER COLUMN  pub_id type bigint;
ALTER TABLE cell_line_dbxref ALTER COLUMN  cell_line_id type bigint;
ALTER TABLE cell_line_dbxref ALTER COLUMN  dbxref_id type bigint;
ALTER TABLE cell_lineprop ALTER COLUMN  cell_line_id type bigint;
ALTER TABLE cell_lineprop ALTER COLUMN  type_id type bigint;
ALTER TABLE cell_lineprop_pub ALTER COLUMN  cell_lineprop_id type bigint;
ALTER TABLE cell_lineprop_pub ALTER COLUMN  pub_id type bigint;
ALTER TABLE cell_line_feature ALTER COLUMN  cell_line_id type bigint;
ALTER TABLE cell_line_feature ALTER COLUMN  feature_id type bigint;
ALTER TABLE cell_line_feature ALTER COLUMN  pub_id type bigint;
ALTER TABLE cell_line_cvtermprop ALTER COLUMN  cell_line_cvterm_id type bigint;
ALTER TABLE cell_line_cvtermprop ALTER COLUMN  type_id type bigint;
ALTER TABLE cell_line_pub ALTER COLUMN  cell_line_id type bigint;
ALTER TABLE cell_line_pub ALTER COLUMN  pub_id type bigint;
ALTER TABLE cell_line_library ALTER COLUMN  cell_line_id type bigint;
ALTER TABLE cell_line_library ALTER COLUMN  library_id type bigint;
ALTER TABLE cell_line_library ALTER COLUMN  pub_id type bigint;
ALTER TABLE analysisprop ALTER COLUMN     analysis_id type bigint;
ALTER TABLE analysisprop ALTER COLUMN     type_id type bigint;
ALTER TABLE analysisfeature ALTER COLUMN     feature_id type bigint;
ALTER TABLE analysisfeature ALTER COLUMN     analysis_id type bigint;
ALTER TABLE analysisfeatureprop ALTER COLUMN     analysisfeature_id type bigint;
ALTER TABLE analysisfeatureprop ALTER COLUMN     type_id type bigint;
ALTER TABLE contact ALTER COLUMN     type_id type bigint;
ALTER TABLE contact_relationship ALTER COLUMN     type_id type bigint;
ALTER TABLE contact_relationship ALTER COLUMN     subject_id type bigint;
ALTER TABLE contact_relationship ALTER COLUMN     object_id type bigint;
ALTER TABLE cvterm ALTER COLUMN     cv_id type bigint;
ALTER TABLE cvterm ALTER COLUMN     dbxref_id type bigint;
ALTER TABLE cvterm_relationship ALTER COLUMN     type_id type bigint;
ALTER TABLE cvterm_relationship ALTER COLUMN     subject_id type bigint;
ALTER TABLE cvterm_relationship ALTER COLUMN     object_id type bigint;
ALTER TABLE cvtermpath ALTER COLUMN     type_id type bigint;
ALTER TABLE cvtermpath ALTER COLUMN     subject_id type bigint;
ALTER TABLE cvtermpath ALTER COLUMN     object_id type bigint;
ALTER TABLE cvtermpath ALTER COLUMN     cv_id type bigint;
ALTER TABLE cvtermsynonym ALTER COLUMN     cvterm_id type bigint;
ALTER TABLE cvtermsynonym ALTER COLUMN     type_id type bigint,;
ALTER TABLE cvterm_dbxref ALTER COLUMN     cvterm_id type bigint;
ALTER TABLE cvterm_dbxref ALTER COLUMN     dbxref_id type bigint;
ALTER TABLE cvtermprop ALTER COLUMN     cvterm_id type bigint ;
ALTER TABLE cvtermprop ALTER COLUMN     type_id type bigint ;
ALTER TABLE dbxrefprop ALTER COLUMN     dbxref_id type bigint;
ALTER TABLE dbxrefprop ALTER COLUMN     type_id type bigint;
ALTER TABLE cvprop ALTER COLUMN     cv_id type bigint;
ALTER TABLE cvprop ALTER COLUMN     type_id type bigint;
ALTER TABLE chadoprop ALTER COLUMN     type_id type bigint;
ALTER TABLE expression_cvterm ALTER COLUMN        expression_id type bigint;
ALTER TABLE expression_cvterm ALTER COLUMN        cvterm_id type bigint;
ALTER TABLE expression_cvterm ALTER COLUMN        cvterm_type_id type bigint;
ALTER TABLE expression_cvtermprop ALTER COLUMN     expression_cvterm_id type bigint;
ALTER TABLE expression_cvtermprop ALTER COLUMN     type_id type bigint;
ALTER TABLE expressionprop ALTER COLUMN     expression_id type bigint;
ALTER TABLE expressionprop ALTER COLUMN     type_id type bigint;
ALTER TABLE expression_pub ALTER COLUMN        expression_id type bigint;
ALTER TABLE expression_pub ALTER COLUMN        pub_id type bigint;
ALTER TABLE feature_expression ALTER COLUMN        expression_id type bigint;
ALTER TABLE feature_expression ALTER COLUMN        feature_id type bigint;
ALTER TABLE feature_expression ALTER COLUMN        pub_id type bigint;
ALTER TABLE feature_expressionprop ALTER COLUMN        feature_expression_id type bigint;
ALTER TABLE feature_expressionprop ALTER COLUMN        type_id type bigint;
ALTER TABLE expression_image ALTER COLUMN        expression_id type bigint;
ALTER TABLE expression_image ALTER COLUMN        eimage_id type bigint;
ALTER TABLE tableinfo ALTER COLUMN     view_on_table_id type bigint null,;
ALTER TABLE tableinfo ALTER COLUMN     superclass_table_id type bigint null,;
ALTER TABLE dbxref ALTER COLUMN     db_id type bigint;
ALTER TABLE genotype ALTER COLUMN     type_id type bigint;
ALTER TABLE feature_genotype ALTER COLUMN     feature_id type bigint;
ALTER TABLE feature_genotype ALTER COLUMN     genotype_id type bigint;
ALTER TABLE feature_genotype ALTER COLUMN     chromosome_id type bigint,;
ALTER TABLE feature_genotype ALTER COLUMN     cvterm_id type bigint;
ALTER TABLE environment_cvterm ALTER COLUMN     environment_id type bigint;
ALTER TABLE environment_cvterm ALTER COLUMN     cvterm_id type bigint;
ALTER TABLE phenstatement ALTER COLUMN     genotype_id type bigint;
ALTER TABLE phenstatement ALTER COLUMN     environment_id type bigint;
ALTER TABLE phenstatement ALTER COLUMN     phenotype_id type bigint;
ALTER TABLE phenstatement ALTER COLUMN     type_id type bigint;
ALTER TABLE phenstatement ALTER COLUMN     pub_id type bigint;
ALTER TABLE phendesc ALTER COLUMN     genotype_id type bigint;
ALTER TABLE phendesc ALTER COLUMN     environment_id type bigint;
ALTER TABLE phendesc ALTER COLUMN     type_id type bigint;
ALTER TABLE phendesc ALTER COLUMN     pub_id type bigint;
ALTER TABLE phenotype_comparison ALTER COLUMN     genotype1_id type bigint;
ALTER TABLE phenotype_comparison ALTER COLUMN     environment1_id type bigint;
ALTER TABLE phenotype_comparison ALTER COLUMN     genotype2_id type bigint;
ALTER TABLE phenotype_comparison ALTER COLUMN     environment2_id type bigint;
ALTER TABLE phenotype_comparison ALTER COLUMN     phenotype1_id type bigint;
ALTER TABLE phenotype_comparison ALTER COLUMN     phenotype2_id type bigint,;
ALTER TABLE phenotype_comparison ALTER COLUMN     pub_id type bigint;
ALTER TABLE phenotype_comparison ALTER COLUMN     organism_id type bigint;
ALTER TABLE phenotype_comparison_cvterm ALTER COLUMN     phenotype_comparison_id type bigint;
ALTER TABLE phenotype_comparison_cvterm ALTER COLUMN     cvterm_id type bigint;
ALTER TABLE phenotype_comparison_cvterm ALTER COLUMN     pub_id type bigint;
ALTER TABLE genotypeprop ALTER COLUMN     genotype_id type bigint;
ALTER TABLE genotypeprop ALTER COLUMN     type_id type bigint;
ALTER TABLE interaction ALTER COLUMN         type_id type bigint;
ALTER TABLE interactionprop ALTER COLUMN     interaction_id type bigint;
ALTER TABLE interactionprop ALTER COLUMN     type_id type bigint;
ALTER TABLE interactionprop_pub ALTER COLUMN        interactionprop_id type bigint;
ALTER TABLE interactionprop_pub ALTER COLUMN      pub_id type bigint;
ALTER TABLE interaction_pub ALTER COLUMN        interaction_id type bigint;
ALTER TABLE interaction_pub ALTER COLUMN        pub_id type bigint;
ALTER TABLE interaction_expression ALTER COLUMN        expression_id type bigint;
ALTER TABLE interaction_expression ALTER COLUMN        interaction_id type bigint;
ALTER TABLE interaction_expression ALTER COLUMN        pub_id type bigint;
ALTER TABLE interaction_expressionprop ALTER COLUMN     interaction_expression_id type bigint;
ALTER TABLE interaction_expressionprop ALTER COLUMN     type_id type bigint;
ALTER TABLE interaction_cvterm ALTER COLUMN        interaction_id type bigint;
ALTER TABLE interaction_cvterm ALTER COLUMN        cvterm_id type bigint;
ALTER TABLE interaction_cvtermprop ALTER COLUMN     interaction_cvterm_id type bigint;
ALTER TABLE interaction_cvtermprop ALTER COLUMN     type_id type bigint;
ALTER TABLE feature_interaction ALTER COLUMN        feature_id type bigint;
ALTER TABLE feature_interaction ALTER COLUMN        interaction_id type bigint;
ALTER TABLE feature_interaction ALTER COLUMN        role_id type bigint;
ALTER TABLE feature_interactionprop ALTER COLUMN        feature_interaction_id type bigint;
ALTER TABLE feature_interactionprop ALTER COLUMN        type_id type bigint;
ALTER TABLE feature_interaction_pub ALTER COLUMN        feature_interaction_id type bigint;
ALTER TABLE feature_interaction_pub ALTER COLUMN        pub_id type bigint;
ALTER TABLE interaction_cell_line ALTER COLUMN        cell_line_id type bigint;
ALTER TABLE interaction_cell_line ALTER COLUMN        interaction_id type bigint;
ALTER TABLE interaction_cell_line ALTER COLUMN        pub_id type bigint;
ALTER TABLE interaction_group_feature_interaction ALTER COLUMN        interaction_group_id type bigint;
ALTER TABLE interaction_group_feature_interaction ALTER COLUMN        feature_interaction_id type bigint;
ALTER TABLE library ALTER COLUMN     organism_id type bigint;
ALTER TABLE library ALTER COLUMN     type_id type bigint;
ALTER TABLE library_synonym ALTER COLUMN     synonym_id type bigint;
ALTER TABLE library_synonym ALTER COLUMN     library_id type bigint;
ALTER TABLE library_synonym ALTER COLUMN     pub_id type bigint;
ALTER TABLE library_pub ALTER COLUMN     library_id type bigint;
ALTER TABLE library_pub ALTER COLUMN     pub_id type bigint;
ALTER TABLE libraryprop ALTER COLUMN     library_id type bigint;
ALTER TABLE libraryprop ALTER COLUMN     type_id type bigint;
ALTER TABLE libraryprop_pub ALTER COLUMN     libraryprop_id type bigint;
ALTER TABLE libraryprop_pub ALTER COLUMN     pub_id type bigint;
ALTER TABLE library_cvterm ALTER COLUMN     library_id type bigint;
ALTER TABLE library_cvterm ALTER COLUMN     cvterm_id type bigint;
ALTER TABLE library_cvterm ALTER COLUMN     pub_id type bigint;
ALTER TABLE library_feature ALTER COLUMN     library_id type bigint;
ALTER TABLE library_feature ALTER COLUMN     feature_id type bigint;
ALTER TABLE library_dbxref ALTER COLUMN     library_id type bigint;
ALTER TABLE library_dbxref ALTER COLUMN     dbxref_id type bigint;
ALTER TABLE library_expression ALTER COLUMN     library_id type bigint;
ALTER TABLE library_expression ALTER COLUMN     expression_id type bigint;
ALTER TABLE library_expression ALTER COLUMN     pub_id type bigint;
ALTER TABLE library_expressionprop ALTER COLUMN     library_expression_id type bigint;
ALTER TABLE library_expressionprop ALTER COLUMN     type_id type bigint;
ALTER TABLE library_featureprop ALTER COLUMN     library_feature_id type bigint;
ALTER TABLE library_featureprop ALTER COLUMN     type_id type bigint;
ALTER TABLE library_interaction ALTER COLUMN     library_id type bigint;
ALTER TABLE library_interaction ALTER COLUMN     interaction_id type bigint;
ALTER TABLE library_interaction ALTER COLUMN     pub_id type bigint;
ALTER TABLE library_relationship ALTER COLUMN     subject_id type bigint;
ALTER TABLE library_relationship ALTER COLUMN     object_id type bigint;
ALTER TABLE library_relationship ALTER COLUMN     type_id type bigint;
ALTER TABLE library_relationship_pub ALTER COLUMN     library_relationship_id type bigint;
ALTER TABLE library_relationship_pub ALTER COLUMN     pub_id type bigint;
ALTER TABLE mage ALTER COLUMN     mageml_id type bigint;
ALTER TABLE mage ALTER COLUMN     tableinfo_id type bigint;
ALTER TABLE mage ALTER COLUMN     row_id type bigint;
ALTER TABLE mage ALTER COLUMN     type_id type bigint;
ALTER TABLE mage ALTER COLUMN     pub_id type bigint null,;
ALTER TABLE mage ALTER COLUMN     dbxref_id type bigint null,;
ALTER TABLE mage ALTER COLUMN     protocol_id type bigint;
ALTER TABLE mage ALTER COLUMN     datatype_id type bigint null,;
ALTER TABLE mage ALTER COLUMN     unittype_id type bigint null,;
ALTER TABLE mage ALTER COLUMN     manufacturer_id type bigint;
ALTER TABLE mage ALTER COLUMN     platformtype_id type bigint;
ALTER TABLE mage ALTER COLUMN     substratetype_id type bigint null,;
ALTER TABLE mage ALTER COLUMN     protocol_id type bigint null,;
ALTER TABLE mage ALTER COLUMN     dbxref_id type bigint null,;
ALTER TABLE mage ALTER COLUMN     arraydesign_id type bigint;
ALTER TABLE mage ALTER COLUMN     type_id type bigint;
ALTER TABLE mage ALTER COLUMN     arraydesign_id type bigint;
ALTER TABLE mage ALTER COLUMN     protocol_id type bigint null,;
ALTER TABLE mage ALTER COLUMN     operator_id type bigint;
ALTER TABLE mage ALTER COLUMN     dbxref_id type bigint null,;
ALTER TABLE mage ALTER COLUMN     assay_id type bigint;
ALTER TABLE mage ALTER COLUMN     type_id type bigint;
ALTER TABLE mage ALTER COLUMN     assay_id type bigint;
ALTER TABLE mage ALTER COLUMN     project_id type bigint;
ALTER TABLE mage ALTER COLUMN     taxon_id type bigint null,;
ALTER TABLE mage ALTER COLUMN     biosourceprovider_id type bigint null,;
ALTER TABLE mage ALTER COLUMN     dbxref_id type bigint null,;
ALTER TABLE mage ALTER COLUMN     subject_id type bigint;
ALTER TABLE mage ALTER COLUMN     type_id type bigint;
ALTER TABLE mage ALTER COLUMN     object_id type bigint;
ALTER TABLE mage ALTER COLUMN     biomaterial_id type bigint;
ALTER TABLE mage ALTER COLUMN     type_id type bigint;
ALTER TABLE mage ALTER COLUMN     biomaterial_id type bigint;
ALTER TABLE mage ALTER COLUMN     dbxref_id type bigint;
ALTER TABLE mage ALTER COLUMN     biomaterial_id type bigint;
ALTER TABLE mage ALTER COLUMN     type_id type bigint;
ALTER TABLE mage ALTER COLUMN     protocol_id type bigint null,;
ALTER TABLE mage ALTER COLUMN     biomaterial_id type bigint;
ALTER TABLE mage ALTER COLUMN     treatment_id type bigint;
ALTER TABLE mage ALTER COLUMN     unittype_id type bigint null,;
ALTER TABLE mage ALTER COLUMN     assay_id type bigint;
ALTER TABLE mage ALTER COLUMN     biomaterial_id type bigint;
ALTER TABLE mage ALTER COLUMN     channel_id type bigint null,;
ALTER TABLE mage ALTER COLUMN     assay_id type bigint;
ALTER TABLE mage ALTER COLUMN     protocol_id type bigint null,;
ALTER TABLE mage ALTER COLUMN     channel_id type bigint null,;
ALTER TABLE mage ALTER COLUMN     acquisition_id type bigint;
ALTER TABLE mage ALTER COLUMN     type_id type bigint;
ALTER TABLE mage ALTER COLUMN     subject_id type bigint;
ALTER TABLE mage ALTER COLUMN     type_id type bigint;
ALTER TABLE mage ALTER COLUMN     object_id type bigint;
ALTER TABLE mage ALTER COLUMN     acquisition_id type bigint;
ALTER TABLE mage ALTER COLUMN     operator_id type bigint null,;
ALTER TABLE mage ALTER COLUMN     protocol_id type bigint null,;
ALTER TABLE mage ALTER COLUMN     analysis_id type bigint;
ALTER TABLE mage ALTER COLUMN     quantification_id type bigint;
ALTER TABLE mage ALTER COLUMN     type_id type bigint;
ALTER TABLE mage ALTER COLUMN     subject_id type bigint;
ALTER TABLE mage ALTER COLUMN     type_id type bigint;
ALTER TABLE mage ALTER COLUMN     object_id type bigint;
ALTER TABLE mage ALTER COLUMN     type_id type bigint;
ALTER TABLE mage ALTER COLUMN     assay_id type bigint;
ALTER TABLE mage ALTER COLUMN     tableinfo_id type bigint;
ALTER TABLE mage ALTER COLUMN     row_id type bigint;
ALTER TABLE mage ALTER COLUMN     feature_id type bigint null,;
ALTER TABLE mage ALTER COLUMN     arraydesign_id type bigint;
ALTER TABLE mage ALTER COLUMN     type_id type bigint null,;
ALTER TABLE mage ALTER COLUMN     dbxref_id type bigint null,;
ALTER TABLE mage ALTER COLUMN     element_id type bigint;
ALTER TABLE mage ALTER COLUMN     quantification_id type bigint;
ALTER TABLE mage ALTER COLUMN     subject_id type bigint;
ALTER TABLE mage ALTER COLUMN     type_id type bigint;
ALTER TABLE mage ALTER COLUMN     object_id type bigint;
ALTER TABLE mage ALTER COLUMN     subject_id type bigint;
ALTER TABLE mage ALTER COLUMN     type_id type bigint;
ALTER TABLE mage ALTER COLUMN     object_id type bigint;
ALTER TABLE mage ALTER COLUMN     contact_id type bigint;
ALTER TABLE mage ALTER COLUMN     pub_id type bigint null,;
ALTER TABLE mage ALTER COLUMN     dbxref_id type bigint null,;
ALTER TABLE mage ALTER COLUMN     study_id type bigint;
ALTER TABLE mage ALTER COLUMN     assay_id type bigint;
ALTER TABLE mage ALTER COLUMN     study_id type bigint;
ALTER TABLE mage ALTER COLUMN     studydesign_id type bigint;
ALTER TABLE mage ALTER COLUMN     type_id type bigint;
ALTER TABLE mage ALTER COLUMN     studydesign_id type bigint;
ALTER TABLE mage ALTER COLUMN     type_id type bigint null,;
ALTER TABLE mage ALTER COLUMN     studyfactor_id type bigint;
ALTER TABLE mage ALTER COLUMN     assay_id type bigint;
ALTER TABLE mage ALTER COLUMN     study_id type bigint;
ALTER TABLE mage ALTER COLUMN     type_id type bigint;
ALTER TABLE mage ALTER COLUMN     studyprop_id type bigint;
ALTER TABLE mage ALTER COLUMN     feature_id type bigint;
ALTER TABLE mage ALTER COLUMN     type_id type bigint,;
ALTER TABLE featuremap ALTER COLUMN     unittype_id type bigint null,;
ALTER TABLE featurerange ALTER COLUMN     featuremap_id type bigint;
ALTER TABLE featurerange ALTER COLUMN     feature_id type bigint;
ALTER TABLE featurerange ALTER COLUMN     leftstartf_id type bigint;
ALTER TABLE featurerange ALTER COLUMN     leftendf_id type bigint,;
ALTER TABLE featurerange ALTER COLUMN     rightstartf_id type bigint,;
ALTER TABLE featurerange ALTER COLUMN     rightendf_id type bigint;
ALTER TABLE featurepos ALTER COLUMN featuremap_id type bigint;
ALTER TABLE featurepos ALTER COLUMN     feature_id type bigint;
ALTER TABLE featurepos ALTER COLUMN     map_feature_id type bigint;
ALTER TABLE featuremap_pub ALTER COLUMN     featuremap_id type bigint;
ALTER TABLE featuremap_pub ALTER COLUMN     pub_id type bigint;
ALTER TABLE natural_diversity ALTER COLUMN     nd_geolocation_id type bigint;
ALTER TABLE natural_diversity ALTER COLUMN     type_id type bigint;
ALTER TABLE natural_diversity ALTER COLUMN     project_id type bigint;
ALTER TABLE natural_diversity ALTER COLUMN     nd_experiment_id type bigint;
ALTER TABLE natural_diversity ALTER COLUMN     nd_experiment_id type bigint;
ALTER TABLE natural_diversity ALTER COLUMN     type_id type bigint;
ALTER TABLE natural_diversity ALTER COLUMN        nd_experiment_id type bigint;
ALTER TABLE natural_diversity ALTER COLUMN        pub_id type bigint;
ALTER TABLE natural_diversity ALTER COLUMN     nd_geolocation_id type bigint;
ALTER TABLE natural_diversity ALTER COLUMN     type_id type bigint;
ALTER TABLE natural_diversity ALTER COLUMN     type_id type bigint;
ALTER TABLE natural_diversity ALTER COLUMN     type_id type bigint;
ALTER TABLE natural_diversity ALTER COLUMN     nd_protocol_id type bigint;
ALTER TABLE natural_diversity ALTER COLUMN     reagent_id type bigint;
ALTER TABLE natural_diversity ALTER COLUMN     type_id type bigint;
ALTER TABLE natural_diversity ALTER COLUMN     nd_protocol_id type bigint;
ALTER TABLE natural_diversity ALTER COLUMN     type_id type bigint;
ALTER TABLE natural_diversity ALTER COLUMN     nd_experiment_id type bigint;
ALTER TABLE natural_diversity ALTER COLUMN     stock_id type bigint;
ALTER TABLE natural_diversity ALTER COLUMN     type_id type bigint;
ALTER TABLE natural_diversity ALTER COLUMN     nd_experiment_id type bigint;
ALTER TABLE natural_diversity ALTER COLUMN     nd_protocol_id type bigint;
ALTER TABLE natural_diversity ALTER COLUMN     nd_experiment_id type bigint;
ALTER TABLE natural_diversity ALTER COLUMN     phenotype_id type bigint;
ALTER TABLE natural_diversity ALTER COLUMN     nd_experiment_id type bigint;
ALTER TABLE natural_diversity ALTER COLUMN     genotype_id type bigint;
ALTER TABLE natural_diversity ALTER COLUMN     subject_reagent_id type bigint;
ALTER TABLE natural_diversity ALTER COLUMN     object_reagent_id type bigint;
ALTER TABLE natural_diversity ALTER COLUMN     type_id type bigint;
ALTER TABLE natural_diversity ALTER COLUMN     nd_reagent_id type bigint;
ALTER TABLE natural_diversity ALTER COLUMN     type_id type bigint;
ALTER TABLE natural_diversity ALTER COLUMN     nd_experiment_stock_id type bigint;
ALTER TABLE natural_diversity ALTER COLUMN     type_id type bigint;
ALTER TABLE natural_diversity ALTER COLUMN     nd_experiment_stock_id type bigint;
ALTER TABLE natural_diversity ALTER COLUMN     dbxref_id type bigint;
ALTER TABLE natural_diversity ALTER COLUMN     nd_experiment_id type bigint;
ALTER TABLE natural_diversity ALTER COLUMN     dbxref_id type bigint;
ALTER TABLE natural_diversity ALTER COLUMN     nd_experiment_id type bigint;
ALTER TABLE natural_diversity ALTER COLUMN     contact_id type bigint;
ALTER TABLE organism_dbxref ALTER COLUMN     organism_id type bigint;
ALTER TABLE organism_dbxref ALTER COLUMN     dbxref_id type bigint;
ALTER TABLE organismprop ALTER COLUMN     organism_id type bigint;
ALTER TABLE organismprop ALTER COLUMN     type_id type bigint;
ALTER TABLE organismprop_pub ALTER COLUMN     organismprop_id type bigint;
ALTER TABLE organismprop_pub ALTER COLUMN     pub_id type bigint;
ALTER TABLE organism_pub ALTER COLUMN        organism_id type bigint;
ALTER TABLE organism_pub ALTER COLUMN        pub_id type bigint;
ALTER TABLE organism_cvterm ALTER COLUMN        organism_id type bigint;
ALTER TABLE organism_cvterm ALTER COLUMN        cvterm_id type bigint;
ALTER TABLE organism_cvterm ALTER COLUMN        pub_id type bigint;
ALTER TABLE organism_cvtermprop ALTER COLUMN     organism_cvterm_id type bigint;
ALTER TABLE organism_cvtermprop ALTER COLUMN     type_id type bigint;
ALTER TABLE phenotype ALTER COLUMN     observable_id type bigint,;
ALTER TABLE phenotype ALTER COLUMN     attr_id type bigint,;
ALTER TABLE phenotype ALTER COLUMN     cvalue_id type bigint,;
ALTER TABLE phenotype ALTER COLUMN     assay_id type bigint,;
ALTER TABLE phenotype ALTER COLUMN     phenotype_id type bigint;
ALTER TABLE phenotype ALTER COLUMN     cvterm_id type bigint;
ALTER TABLE phenotype ALTER COLUMN     feature_id type bigint;
ALTER TABLE phenotype ALTER COLUMN     phenotype_id type bigint;
ALTER TABLE phenotype ALTER COLUMN        phenotype_id type bigint;
ALTER TABLE phenotype ALTER COLUMN        type_id type bigint;
ALTER TABLE phylogeny ALTER COLUMN    dbxref_id type bigint;
ALTER TABLE phylogeny ALTER COLUMN  type_id type bigint,;
ALTER TABLE phylogeny ALTER COLUMN  analysis_id type bigint null,;
ALTER TABLE phylogeny ALTER COLUMN        phylotree_id type bigint;
ALTER TABLE phylogeny ALTER COLUMN        pub_id type bigint;
ALTER TABLE phylogeny ALTER COLUMN        phylotree_id type bigint;
ALTER TABLE phylogeny ALTER COLUMN        parent_phylonode_id type bigint null,;
ALTER TABLE phylogeny ALTER COLUMN        type_id type bigint,;
ALTER TABLE phylogeny ALTER COLUMN        feature_id type bigint,;
ALTER TABLE phylogeny ALTER COLUMN        phylonode_id type bigint;
ALTER TABLE phylogeny ALTER COLUMN        dbxref_id type bigint;
ALTER TABLE phylogeny ALTER COLUMN        phylonode_id type bigint;
ALTER TABLE phylogeny ALTER COLUMN        pub_id type bigint;
ALTER TABLE phylogeny ALTER COLUMN        phylonode_id type bigint;
ALTER TABLE phylogeny ALTER COLUMN        organism_id type bigint;
ALTER TABLE phylogeny ALTER COLUMN        phylonode_id type bigint;
ALTER TABLE phylogeny ALTER COLUMN        type_id type bigint;
ALTER TABLE phylogeny ALTER COLUMN        subject_id type bigint;
ALTER TABLE phylogeny ALTER COLUMN        object_id type bigint;
ALTER TABLE phylogeny ALTER COLUMN        type_id type bigint;
ALTER TABLE phylogeny ALTER COLUMN        phylotree_id type bigint;
ALTER TABLE project ALTER COLUMN  project_id type bigint;
ALTER TABLE project ALTER COLUMN  type_id type bigint;
ALTER TABLE project ALTER COLUMN  subject_project_id type bigint;
ALTER TABLE project ALTER COLUMN  object_project_id type bigint;
ALTER TABLE project ALTER COLUMN  type_id type bigint;
ALTER TABLE project ALTER COLUMN        project_id type bigint;
ALTER TABLE project ALTER COLUMN        pub_id type bigint;
ALTER TABLE project ALTER COLUMN        project_id type bigint;
ALTER TABLE project ALTER COLUMN        contact_id type bigint;
ALTER TABLE pub ALTER COLUMN     type_id type bigint;
ALTER TABLE pub ALTER COLUMN     subject_id type bigint;
ALTER TABLE pub ALTER COLUMN     object_id type bigint;
ALTER TABLE pub ALTER COLUMN     type_id type bigint;
ALTER TABLE pub ALTER COLUMN     pub_id type bigint;
ALTER TABLE pub ALTER COLUMN     dbxref_id type bigint;
ALTER TABLE pub ALTER COLUMN     pub_id type bigint;
ALTER TABLE pub ALTER COLUMN     pub_id type bigint;
ALTER TABLE pub ALTER COLUMN     type_id type bigint;
ALTER TABLE sequence ALTER COLUMN     dbxref_id type bigint,;
ALTER TABLE sequence ALTER COLUMN     organism_id type bigint;
ALTER TABLE sequence ALTER COLUMN     seqlen type bigint,;
ALTER TABLE sequence ALTER COLUMN     type_id type bigint;
ALTER TABLE sequence ALTER COLUMN     feature_id type bigint;
ALTER TABLE sequence ALTER COLUMN     srcfeature_id type bigint,;
ALTER TABLE sequence ALTER COLUMN     fmin type bigint,;
ALTER TABLE sequence ALTER COLUMN     fmax type bigint,;
ALTER TABLE sequence ALTER COLUMN     featureloc_id type bigint;
ALTER TABLE sequence ALTER COLUMN     pub_id type bigint;
ALTER TABLE sequence ALTER COLUMN     feature_id type bigint;
ALTER TABLE sequence ALTER COLUMN     pub_id type bigint;
ALTER TABLE sequence ALTER COLUMN     feature_pub_id type bigint;
ALTER TABLE sequence ALTER COLUMN     type_id type bigint;
ALTER TABLE sequence ALTER COLUMN     feature_id type bigint;
ALTER TABLE sequence ALTER COLUMN     type_id type bigint;
ALTER TABLE sequence ALTER COLUMN     featureprop_id type bigint;
ALTER TABLE sequence ALTER COLUMN     pub_id type bigint;
ALTER TABLE sequence ALTER COLUMN     feature_id type bigint;
ALTER TABLE sequence ALTER COLUMN     dbxref_id type bigint;
ALTER TABLE sequence ALTER COLUMN     subject_id type bigint;
ALTER TABLE sequence ALTER COLUMN     object_id type bigint;
ALTER TABLE sequence ALTER COLUMN     type_id type bigint;
ALTER TABLE sequence ALTER COLUMN  feature_relationship_id type bigint;
ALTER TABLE sequence ALTER COLUMN  pub_id type bigint;
ALTER TABLE sequence ALTER COLUMN     feature_relationship_id type bigint;
ALTER TABLE sequence ALTER COLUMN     type_id type bigint;
ALTER TABLE sequence ALTER COLUMN     feature_relationshipprop_id type bigint;
ALTER TABLE sequence ALTER COLUMN     pub_id type bigint;
ALTER TABLE sequence ALTER COLUMN     feature_id type bigint;
ALTER TABLE sequence ALTER COLUMN     cvterm_id type bigint;
ALTER TABLE sequence ALTER COLUMN     pub_id type bigint;
ALTER TABLE sequence ALTER COLUMN     feature_cvterm_id type bigint;
ALTER TABLE sequence ALTER COLUMN     type_id type bigint;
ALTER TABLE sequence ALTER COLUMN     feature_cvterm_id type bigint;
ALTER TABLE sequence ALTER COLUMN     dbxref_id type bigint;
ALTER TABLE sequence ALTER COLUMN     feature_cvterm_id type bigint;
ALTER TABLE sequence ALTER COLUMN     pub_id type bigint;
ALTER TABLE sequence ALTER COLUMN     type_id type bigint;
ALTER TABLE sequence ALTER COLUMN     synonym_id type bigint;
ALTER TABLE sequence ALTER COLUMN     feature_id type bigint;
ALTER TABLE sequence ALTER COLUMN     pub_id type bigint;
ALTER TABLE sequence ALTER COLUMN --   feature_id type bigint,name varchar(255),organism_id bigint;
ALTER TABLE sequence ALTER COLUMN -- gmod_materialized_view_tool.pl --create_view --view_name all_feature_names --table_name public.all_feature_names --refresh_time daily --column_def "feature_id type bigint,name varchar(255),organism_id bigint" --sql_query "SELECT feature_id,CAST(substring(uniquename from 0 for 255) as varchar(255)) as name,organism_id FROM feature UNION SELECT feature_id, name, organism_id FROM feature where name is not null UNION SELECT fs.feature_id,s.name,f.organism_id FROM feature_synonym fs, synonym s, feature f WHERE fs.synonym_id = s.synonym_id AND fs.feature_id = f.feature_id UNION SELECT fp.feature_id, CAST(substring(fp.value from 0 for 255) as varchar(255)) as name,f.organism_id FROM featureprop fp, feature f WHERE f.feature_id = fp.feature_id UNION SELECT fd.feature_id, d.accession, f.organism_id FROM feature_dbxref fd, dbxref d,feature f WHERE fd.dbxref_id = d.dbxref_id AND fd.feature_id = f.feature_id" --index_fields "feature_id,name" --special_index "create index all_feature_names_lower_name on all_feature_names (lower(name))" --yes;
ALTER TABLE sequence ALTER COLUMN -- gmod_materialized_view_tool.pl --create_view --view_name all_feature_names --table_name public.all_feature_names --refresh_time daily --column_def "feature_id type bigint,name varchar(255),organism_id bigint,searchable_name tsvector" --sql_query "SELECT feature_id, CAST(substring(uniquename FROM 0 FOR 255) AS varchar(255)) AS name, organism_id, to_tsvector('english', CAST(substring(uniquename FROM 0 FOR 255) AS varchar(255))) AS searchable_name FROM feature UNION SELECT feature_id, name, organism_id, to_tsvector('english', name) AS searchable_name FROM feature WHERE name IS NOT NULL UNION SELECT fs.feature_id, s.name, f.organism_id, to_tsvector('english', s.name) AS searchable_name FROM feature_synonym fs, synonym s, feature f WHERE fs.synonym_id = s.synonym_id AND fs.feature_id = f.feature_id UNION SELECT fp.feature_id, CAST(substring(fp.value FROM 0 FOR 255) AS varchar(255)) AS name, f.organism_id, to_tsvector('english',CAST(substring(fp.value FROM 0 FOR 255) AS varchar(255))) AS searchable_name FROM featureprop fp, feature f WHERE f.feature_id = fp.feature_id UNION SELECT fd.feature_id, d.accession, f.organism_id,to_tsvector('english',d.accession) AS searchable_name FROM feature_dbxref fd, dbxref d,feature f WHERE fd.dbxref_id = d.dbxref_id AND fd.feature_id = f.feature_id" --index_fields "feature_id,name" --special_index "CREATE INDEX searchable_all_feature_names_idx ON all_feature_names USING gin(searchable_name)" --yes ;
ALTER TABLE stock ALTER COLUMN        dbxref_id type bigint,;
ALTER TABLE stock ALTER COLUMN        organism_id type bigint,;
ALTER TABLE stock ALTER COLUMN        type_id type bigint;
ALTER TABLE stock_pub ALTER COLUMN        stock_id type bigint;
ALTER TABLE stock_pub ALTER COLUMN        pub_id type bigint;
ALTER TABLE stockprop ALTER COLUMN        stock_id type bigint;
ALTER TABLE stockprop ALTER COLUMN        type_id type bigint;
ALTER TABLE stockprop_pub ALTER COLUMN      stockprop_id type bigint;
ALTER TABLE stockprop_pub ALTER COLUMN      pub_id type bigint;
ALTER TABLE stock_relationship ALTER COLUMN        subject_id type bigint;
ALTER TABLE stock_relationship ALTER COLUMN        object_id type bigint;
ALTER TABLE stock_relationship ALTER COLUMN        type_id type bigint;
ALTER TABLE stock_relationship_cvterm ALTER COLUMN  stock_relationship_id type bigint;
ALTER TABLE stock_relationship_cvterm ALTER COLUMN  cvterm_id type bigint;
ALTER TABLE stock_relationship_cvterm ALTER COLUMN  pub_id type bigint,;
ALTER TABLE stock_relationship_pub ALTER COLUMN       stock_relationship_id type bigint;
ALTER TABLE stock_relationship_pub ALTER COLUMN       pub_id type bigint;
ALTER TABLE stock_dbxref ALTER COLUMN      stock_id type bigint;
ALTER TABLE stock_dbxref ALTER COLUMN      dbxref_id type bigint;
ALTER TABLE stock_cvterm ALTER COLUMN      stock_id type bigint;
ALTER TABLE stock_cvterm ALTER COLUMN      cvterm_id type bigint;
ALTER TABLE stock_cvterm ALTER COLUMN      pub_id type bigint;
ALTER TABLE stock_cvtermprop ALTER COLUMN     stock_cvterm_id type bigint;
ALTER TABLE stock_cvtermprop ALTER COLUMN     type_id type bigint;
ALTER TABLE stock_genotype ALTER COLUMN        stock_id type bigint;
ALTER TABLE stock_genotype ALTER COLUMN        genotype_id type bigint;
ALTER TABLE stockcollection ALTER COLUMN  type_id type bigint;
ALTER TABLE stockcollection ALTER COLUMN         contact_id type bigint null,;
ALTER TABLE stockcollectionprop ALTER COLUMN     stockcollection_id type bigint;
ALTER TABLE stockcollectionprop ALTER COLUMN     type_id type bigint;
ALTER TABLE stockcollection_stock ALTER COLUMN     stockcollection_id type bigint;
ALTER TABLE stockcollection_stock ALTER COLUMN     stock_id type bigint;
ALTER TABLE stock_dbxrefprop ALTER COLUMN        stock_dbxref_id type bigint;
ALTER TABLE stock_dbxrefprop ALTER COLUMN        type_id type bigint;
