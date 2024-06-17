/* https://github.com/GMOD/Chado/issues/140 */
/* Upgrade unique constraints with nullable columns if PostgreSQL version > 15 */
CREATE OR REPLACE PROCEDURE addUniqueLinkerConstraint(table_name varchar, constraint_name varchar, columns varchar[])
  LANGUAGE plpgsql
  AS $$
  DECLARE
    newer_than_15 boolean;
  BEGIN
    -- Determine the version of PostgreSQL
    SELECT CASE WHEN current_setting('server_version_num')::INT > 150000 THEN true ELSE false END AS supported INTO newer_than_15;

    -- IF the version is newer then we can use the new UNIQUE NULLS NOT DISTINCT
    -- which does not treat 2 records that are the same but include NULL as distict.
    IF newer_than_15 THEN
      EXECUTE format('ALTER TABLE %s ADD CONSTRAINT %s UNIQUE NULLS NOT DISTINCT (%s)', table_name, constraint_name, array_to_string(columns, ','));
    -- IF the version is <15 then we use the original UNIQUE style constraint
    ELSE
      EXECUTE format('ALTER TABLE %s ADD CONSTRAINT %s UNIQUE (%s)', table_name, constraint_name, array_to_string(columns, ','));
    END IF;
  END
$$;
/* Contact Linkers */
/* -- Feature */
ALTER TABLE feature_contact ADD COLUMN type_id bigint;
ALTER TABLE feature_contact ADD COLUMN rank int DEFAULT 0;
ALTER TABLE feature_contact ADD FOREIGN KEY (type_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL;
ALTER TABLE feature_contact DROP CONSTRAINT feature_contact_c1;
CALL addUniqueLinkerConstraint('feature_contact', 'feature_contact_c1', ARRAY['feature_id', 'contact_id', 'type_id']);
/* -- Featuremap */
ALTER TABLE featuremap_contact ADD COLUMN type_id bigint;
ALTER TABLE featuremap_contact ADD COLUMN rank int DEFAULT 0;
ALTER TABLE featuremap_contact ADD FOREIGN KEY (type_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL;
ALTER TABLE featuremap_contact DROP CONSTRAINT featuremap_contact_c1;
CALL addUniqueLinkerConstraint('featuremap_contact', 'featuremap_contact_c1', ARRAY['featuremap_id', 'contact_id', 'type_id']);
/* -- Library */
ALTER TABLE library_contact ADD COLUMN type_id bigint;
ALTER TABLE library_contact ADD COLUMN rank int DEFAULT 0;
ALTER TABLE library_contact ADD FOREIGN KEY (type_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL;
ALTER TABLE library_contact DROP CONSTRAINT library_contact_c1;
CALL addUniqueLinkerConstraint('library_contact', 'library_contact_c1', ARRAY['library_id', 'contact_id', 'type_id']);
/* -- ND Experiment */
ALTER TABLE nd_experiment_contact ADD COLUMN type_id bigint;
ALTER TABLE nd_experiment_contact ADD COLUMN rank int DEFAULT 0;
ALTER TABLE nd_experiment_contact ADD FOREIGN KEY (type_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL;
CALL addUniqueLinkerConstraint('nd_experiment_contact', 'nd_experiment_contact_c1', ARRAY['nd_experiment_id', 'contact_id', 'type_id']);
/* -- Project */
ALTER TABLE project_contact ADD COLUMN type_id bigint;
ALTER TABLE project_contact ADD COLUMN rank int DEFAULT 0;
ALTER TABLE project_contact ADD FOREIGN KEY (type_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL;
ALTER TABLE project_contact DROP CONSTRAINT project_contact_c1;
CALL addUniqueLinkerConstraint('project_contact', 'project_contact_c1', ARRAY['project_id', 'contact_id', 'type_id']);
/* -- Pubauthor */
ALTER TABLE pubauthor_contact ADD COLUMN type_id bigint;
ALTER TABLE pubauthor_contact ADD COLUMN rank int DEFAULT 0;
ALTER TABLE pubauthor_contact ADD FOREIGN KEY (type_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL;
ALTER TABLE pubauthor_contact DROP CONSTRAINT pubauthor_contact_c1;
CALL addUniqueLinkerConstraint('pubauthor_contact', 'pubauthor_contact_c1', ARRAY['pubauthor_id', 'contact_id', 'type_id']);
/* Project Linkers */
/* -- Features */
ALTER TABLE project_feature ADD COLUMN type_id bigint;
ALTER TABLE project_feature ADD COLUMN rank int DEFAULT 0;
ALTER TABLE project_feature ADD FOREIGN KEY (type_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL;
ALTER TABLE project_feature DROP CONSTRAINT project_feature_c1;
CALL addUniqueLinkerConstraint('project_feature', 'project_feature_c1', ARRAY['feature_id', 'project_id', 'type_id']);
/* -- Publications */
ALTER TABLE project_pub ADD COLUMN type_id bigint;
ALTER TABLE project_pub ADD COLUMN rank int DEFAULT 0;
ALTER TABLE project_pub ADD FOREIGN KEY (type_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL;
ALTER TABLE project_pub DROP CONSTRAINT project_pub_c1;
CALL addUniqueLinkerConstraint('project_pub', 'project_pub_c1', ARRAY['pub_id', 'project_id', 'type_id']);
/* -- ND Experiments */
ALTER TABLE nd_experiment_project ADD COLUMN type_id bigint;
ALTER TABLE nd_experiment_project ADD COLUMN rank int DEFAULT 0;
ALTER TABLE nd_experiment_project ADD FOREIGN KEY (type_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL;
ALTER TABLE nd_experiment_project DROP CONSTRAINT nd_experiment_project_c1;
CALL addUniqueLinkerConstraint('nd_experiment_project', 'nd_experiment_project_c1', ARRAY['nd_experiment_id', 'project_id', 'type_id']);
/* -- Analysis */
/*    Already has a rank */
ALTER TABLE project_analysis ADD COLUMN type_id bigint;
ALTER TABLE project_analysis ADD FOREIGN KEY (type_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL;
ALTER TABLE project_analysis DROP CONSTRAINT project_analysis_c1;
CALL addUniqueLinkerConstraint('project_analysis', 'project_analysis_c1', ARRAY['analysis_id', 'project_id', 'type_id']);
/* -- Stock */
ALTER TABLE project_stock ADD COLUMN type_id bigint;
ALTER TABLE project_stock ADD COLUMN rank int DEFAULT 0;
ALTER TABLE project_stock ADD FOREIGN KEY (type_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL;
ALTER TABLE project_stock DROP CONSTRAINT project_stock_c1;
CALL addUniqueLinkerConstraint('project_stock', 'project_stock_c1', ARRAY['stock_id', 'project_id', 'type_id']);
/* -- Assay */
ALTER TABLE assay_project ADD COLUMN type_id bigint;
ALTER TABLE assay_project ADD COLUMN rank int DEFAULT 0;
ALTER TABLE assay_project ADD FOREIGN KEY (type_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL;
ALTER TABLE assay_project DROP CONSTRAINT assay_project_c1;
CALL addUniqueLinkerConstraint('assay_project', 'assay_project_c1', ARRAY['assay_id', 'project_id', 'type_id']);
/* -- Dbxref */
ALTER TABLE project_dbxref ADD COLUMN type_id bigint;
ALTER TABLE project_dbxref ADD COLUMN rank int DEFAULT 0;
ALTER TABLE project_dbxref ADD FOREIGN KEY (type_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL;
ALTER TABLE project_dbxref DROP CONSTRAINT project_dbxref_c1;
CALL addUniqueLinkerConstraint('project_dbxref', 'project_dbxref_c1', ARRAY['dbxref_id', 'project_id', 'type_id']);
/* -- biomaterial_project */
ALTER TABLE biomaterial_project ADD COLUMN type_id bigint;
ALTER TABLE biomaterial_project ADD COLUMN rank int DEFAULT 0;
ALTER TABLE biomaterial_project ADD FOREIGN KEY (type_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL;
ALTER TABLE biomaterial_project DROP CONSTRAINT biomaterial_project_c1;
CALL addUniqueLinkerConstraint('biomaterial_project', 'biomaterial_project_c1', ARRAY['biomaterial_id', 'project_id', 'type_id']);
