/* https://github.com/GMOD/Chado/issues/140 */
/* Contact Linkers */
/* -- Feature */
ALTER TABLE feature_contact ADD COLUMN type_id bigint;
ALTER TABLE feature_contact ADD COLUMN rank int DEFAULT 0;
ALTER TABLE feature_contact ADD FOREIGN KEY (type_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL;
ALTER TABLE feature_contact DROP CONSTRAINT feature_contact_c1;
ALTER TABLE feature_contact ADD CONSTRAINT feature_contact_c1 UNIQUE NULLS NOT DISTINCT (feature_id, contact_id, type_id, rank);
/* -- Featuremap */
ALTER TABLE featuremap_contact ADD COLUMN type_id bigint;
ALTER TABLE featuremap_contact ADD COLUMN rank int DEFAULT 0;
ALTER TABLE featuremap_contact ADD FOREIGN KEY (type_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL;
ALTER TABLE featuremap_contact DROP CONSTRAINT featuremap_contact_c1;
ALTER TABLE featuremap_contact ADD CONSTRAINT featuremap_contact_c1 UNIQUE NULLS NOT DISTINCT (featuremap_id, contact_id, type_id, rank);
/* -- Library */
ALTER TABLE library_contact ADD COLUMN type_id bigint;
ALTER TABLE library_contact ADD COLUMN rank int DEFAULT 0;
ALTER TABLE library_contact ADD FOREIGN KEY (type_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL;
ALTER TABLE library_contact DROP CONSTRAINT library_contact_c1;
ALTER TABLE library_contact ADD CONSTRAINT library_contact_c1 UNIQUE NULLS NOT DISTINCT (library_id, contact_id, type_id, rank);
/* -- ND Experiment */
ALTER TABLE nd_experiment_contact ADD COLUMN type_id bigint;
ALTER TABLE nd_experiment_contact ADD COLUMN rank int DEFAULT 0;
ALTER TABLE nd_experiment_contact ADD FOREIGN KEY (type_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL;
ALTER TABLE nd_experiment_contact ADD CONSTRAINT nd_experiment_contact_c1 UNIQUE NULLS NOT DISTINCT (nd_experiment_id, contact_id, type_id, rank);
/* -- Project */
ALTER TABLE project_contact ADD COLUMN type_id bigint;
ALTER TABLE project_contact ADD COLUMN rank int DEFAULT 0;
ALTER TABLE project_contact ADD FOREIGN KEY (type_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL;
ALTER TABLE project_contact DROP CONSTRAINT project_contact_c1;
ALTER TABLE project_contact ADD CONSTRAINT project_contact_c1 UNIQUE NULLS NOT DISTINCT (project_id, contact_id, type_id, rank);
/* -- Pubauthor */
ALTER TABLE pubauthor_contact ADD COLUMN type_id bigint;
ALTER TABLE pubauthor_contact ADD COLUMN rank int DEFAULT 0;
ALTER TABLE pubauthor_contact ADD FOREIGN KEY (type_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL;
ALTER TABLE pubauthor_contact DROP CONSTRAINT pubauthor_contact_c1;
ALTER TABLE pubauthor_contact ADD CONSTRAINT pubauthor_contact_c1 UNIQUE NULLS NOT DISTINCT (pubauthor_id, contact_id, type_id, rank);
