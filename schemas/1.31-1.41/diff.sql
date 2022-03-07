ALTER TABLE featureprop ADD COLUMN cvalue_id bigint;
ALTER TABLE featureprop ADD FOREIGN KEY (cvalue_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL;
COMMENT ON COLUMN featureprop.cvalue_id IS 'The value of the property if that value should be the name of a controlled vocabulary term.  It is preferred that a property either use the value or cvalue_id column but not both.  For example, if the property type is "color" then the cvalue_id could be a term named "green".';

ALTER TABLE acquisitionprop ADD COLUMN cvalue_id bigint;
ALTER TABLE acquisitionprop ADD FOREIGN KEY (cvalue_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL;
COMMENT ON COLUMN acquisitionprop.cvalue_id IS 'The value of the property if that value should be the name of a controlled vocabulary term.  It is preferred that a property either use the value or cvalue_id column but not both.  For example, if the property type is "color" then the cvalue_id could be a term named "green".';

ALTER TABLE analysisfeatureprop ADD COLUMN cvalue_id bigint;
ALTER TABLE analysisfeatureprop ADD FOREIGN KEY (cvalue_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL;
COMMENT ON COLUMN analysisfeatureprop.cvalue_id IS 'The value of the property if that value should be the name of a controlled vocabulary term.  It is preferred that a property either use the value or cvalue_id column but not both.  For example, if the property type is "color" then the cvalue_id could be a term named "green".';

ALTER TABLE analysisprop ADD COLUMN cvalue_id bigint;
ALTER TABLE analysisprop ADD FOREIGN KEY (cvalue_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL;
COMMENT ON COLUMN analysisprop.cvalue_id IS 'The value of the property if that value should be the name of a controlled vocabulary term.  It is preferred that a property either use the value or cvalue_id column but not both.  For example, if the property type is "color" then the cvalue_id could be a term named "green".';

ALTER TABLE arraydesignprop ADD COLUMN cvalue_id bigint;
ALTER TABLE arraydesignprop ADD FOREIGN KEY (cvalue_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL;
COMMENT ON COLUMN arraydesignprop.cvalue_id IS 'The value of the property if that value should be the name of a controlled vocabulary term.  It is preferred that a property either use the value or cvalue_id column but not both.  For example, if the property type is "color" then the cvalue_id could be a term named "green".';

ALTER TABLE assayprop ADD COLUMN cvalue_id bigint;
ALTER TABLE assayprop ADD FOREIGN KEY (cvalue_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL;
COMMENT ON COLUMN assayprop.cvalue_id IS 'The value of the property if that value should be the name of a controlled vocabulary term.  It is preferred that a property either use the value or cvalue_id column but not both.  For example, if the property type is "color" then the cvalue_id could be a term named "green".';

ALTER TABLE biomaterialprop ADD COLUMN cvalue_id bigint;
ALTER TABLE biomaterialprop ADD FOREIGN KEY (cvalue_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL;
COMMENT ON COLUMN biomaterialprop.cvalue_id IS 'The value of the property if that value should be the name of a controlled vocabulary term.  It is preferred that a property either use the value or cvalue_id column but not both.  For example, if the property type is "color" then the cvalue_id could be a term named "green".';

ALTER TABLE cell_lineprop ADD COLUMN cvalue_id bigint;
ALTER TABLE cell_lineprop ADD FOREIGN KEY (cvalue_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL;
COMMENT ON COLUMN cell_lineprop.cvalue_id IS 'The value of the property if that value should be the name of a controlled vocabulary term.  It is preferred that a property either use the value or cvalue_id column but not both.  For example, if the property type is "color" then the cvalue_id could be a term named "green".';

ALTER TABLE contactprop ADD COLUMN cvalue_id bigint;
ALTER TABLE contactprop ADD FOREIGN KEY (cvalue_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL;
COMMENT ON COLUMN contactprop.cvalue_id IS 'The value of the property if that value should be the name of a controlled vocabulary term.  It is preferred that a property either use the value or cvalue_id column but not both.  For example, if the property type is "color" then the cvalue_id could be a term named "green".';

ALTER TABLE expressionprop ADD COLUMN cvalue_id bigint;
ALTER TABLE expressionprop ADD FOREIGN KEY (cvalue_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL;
COMMENT ON COLUMN expressionprop.cvalue_id IS 'The value of the property if that value should be the name of a controlled vocabulary term.  It is preferred that a property either use the value or cvalue_id column but not both.  For example, if the property type is "color" then the cvalue_id could be a term named "green".';

ALTER TABLE feature_expressionprop ADD COLUMN cvalue_id bigint;
ALTER TABLE feature_expressionprop ADD FOREIGN KEY (cvalue_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL;
COMMENT ON COLUMN feature_expressionprop.cvalue_id IS 'The value of the property if that value should be the name of a controlled vocabulary term.  It is preferred that a property either use the value or cvalue_id column but not both.  For example, if the property type is "color" then the cvalue_id could be a term named "green".';

ALTER TABLE featuremapprop ADD COLUMN cvalue_id bigint;
ALTER TABLE featuremapprop ADD FOREIGN KEY (cvalue_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL;
COMMENT ON COLUMN featuremapprop.cvalue_id IS 'The value of the property if that value should be the name of a controlled vocabulary term.  It is preferred that a property either use the value or cvalue_id column but not both.  For example, if the property type is "color" then the cvalue_id could be a term named "green".';

ALTER TABLE featureposprop ADD COLUMN cvalue_id bigint;
ALTER TABLE featureposprop ADD FOREIGN KEY (cvalue_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL;
COMMENT ON COLUMN featureposprop.cvalue_id IS 'The value of the property if that value should be the name of a controlled vocabulary term.  It is preferred that a property either use the value or cvalue_id column but not both.  For example, if the property type is "color" then the cvalue_id could be a term named "green".';

ALTER TABLE genotypeprop ADD COLUMN cvalue_id bigint;
ALTER TABLE genotypeprop ADD FOREIGN KEY (cvalue_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL;
COMMENT ON COLUMN genotypeprop.cvalue_id IS 'The value of the property if that value should be the name of a controlled vocabulary term.  It is preferred that a property either use the value or cvalue_id column but not both.  For example, if the property type is "color" then the cvalue_id could be a term named "green".';

ALTER TABLE library_expressionprop ADD COLUMN cvalue_id bigint;
ALTER TABLE library_expressionprop ADD FOREIGN KEY (cvalue_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL;
COMMENT ON COLUMN library_expressionprop.cvalue_id IS 'The value of the property if that value should be the name of a controlled vocabulary term.  It is preferred that a property either use the value or cvalue_id column but not both.  For example, if the property type is "color" then the cvalue_id could be a term named "green".';

ALTER TABLE library_featureprop ADD COLUMN cvalue_id bigint;
ALTER TABLE library_featureprop ADD FOREIGN KEY (cvalue_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL;
COMMENT ON COLUMN library_featureprop.cvalue_id IS 'The value of the property if that value should be the name of a controlled vocabulary term.  It is preferred that a property either use the value or cvalue_id column but not both.  For example, if the property type is "color" then the cvalue_id could be a term named "green".';

ALTER TABLE libraryprop ADD COLUMN cvalue_id bigint;
ALTER TABLE libraryprop ADD FOREIGN KEY (cvalue_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL;
COMMENT ON COLUMN libraryprop.cvalue_id IS 'The value of the property if that value should be the name of a controlled vocabulary term.  It is preferred that a property either use the value or cvalue_id column but not both.  For example, if the property type is "color" then the cvalue_id could be a term named "green".';

ALTER TABLE nd_experiment_stockprop ADD COLUMN cvalue_id bigint;
ALTER TABLE nd_experiment_stockprop ADD FOREIGN KEY (cvalue_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL;
COMMENT ON COLUMN nd_experiment_stockprop.cvalue_id IS 'The value of the property if that value should be the name of a controlled vocabulary term.  It is preferred that a property either use the value or cvalue_id column but not both.  For example, if the property type is "color" then the cvalue_id could be a term named "green".';

ALTER TABLE nd_experimentprop ADD COLUMN cvalue_id bigint;
ALTER TABLE nd_experimentprop ADD FOREIGN KEY (cvalue_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL;
COMMENT ON COLUMN nd_experimentprop.cvalue_id IS 'The value of the property if that value should be the name of a controlled vocabulary term.  It is preferred that a property either use the value or cvalue_id column but not both.  For example, if the property type is "color" then the cvalue_id could be a term named "green".';

ALTER TABLE nd_geolocationprop ADD COLUMN cvalue_id bigint;
ALTER TABLE nd_geolocationprop ADD FOREIGN KEY (cvalue_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL;
COMMENT ON COLUMN nd_geolocationprop.cvalue_id IS 'The value of the property if that value should be the name of a controlled vocabulary term.  It is preferred that a property either use the value or cvalue_id column but not both.  For example, if the property type is "color" then the cvalue_id could be a term named "green".';

ALTER TABLE nd_protocolprop ADD COLUMN cvalue_id bigint;
ALTER TABLE nd_protocolprop ADD FOREIGN KEY (cvalue_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL;
COMMENT ON COLUMN nd_protocolprop.cvalue_id IS 'The value of the property if that value should be the name of a controlled vocabulary term.  It is preferred that a property either use the value or cvalue_id column but not both.  For example, if the property type is "color" then the cvalue_id could be a term named "green".';

ALTER TABLE nd_reagentprop ADD COLUMN cvalue_id bigint;
ALTER TABLE nd_reagentprop ADD FOREIGN KEY (cvalue_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL;
COMMENT ON COLUMN nd_reagentprop.cvalue_id IS 'The value of the property if that value should be the name of a controlled vocabulary term.  It is preferred that a property either use the value or cvalue_id column but not both.  For example, if the property type is "color" then the cvalue_id could be a term named "green".';

ALTER TABLE organismprop ADD COLUMN cvalue_id bigint;
ALTER TABLE organismprop ADD FOREIGN KEY (cvalue_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL;
COMMENT ON COLUMN organismprop.cvalue_id IS 'The value of the property if that value should be the name of a controlled vocabulary term.  It is preferred that a property either use the value or cvalue_id column but not both.  For example, if the property type is "color" then the cvalue_id could be a term named "green".';

ALTER TABLE phenotypeprop ADD COLUMN cvalue_id bigint;
ALTER TABLE phenotypeprop ADD FOREIGN KEY (cvalue_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL;
COMMENT ON COLUMN phenotypeprop.cvalue_id IS 'The value of the property if that value should be the name of a controlled vocabulary term.  It is preferred that a property either use the value or cvalue_id column but not both.  For example, if the property type is "color" then the cvalue_id could be a term named "green".';

ALTER TABLE phylonodeprop ADD COLUMN cvalue_id bigint;
ALTER TABLE phylonodeprop ADD FOREIGN KEY (cvalue_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL;
COMMENT ON COLUMN phylonodeprop.cvalue_id IS 'The value of the property if that value should be the name of a controlled vocabulary term.  It is preferred that a property either use the value or cvalue_id column but not both.  For example, if the property type is "color" then the cvalue_id could be a term named "green".';

ALTER TABLE phylotreeprop ADD COLUMN cvalue_id bigint;
ALTER TABLE phylotreeprop ADD FOREIGN KEY (cvalue_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL;
COMMENT ON COLUMN phylotreeprop.cvalue_id IS 'The value of the property if that value should be the name of a controlled vocabulary term.  It is preferred that a property either use the value or cvalue_id column but not both.  For example, if the property type is "color" then the cvalue_id could be a term named "green".';

ALTER TABLE projectprop ADD COLUMN cvalue_id bigint;
ALTER TABLE projectprop ADD FOREIGN KEY (cvalue_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL;
COMMENT ON COLUMN projectprop.cvalue_id IS 'The value of the property if that value should be the name of a controlled vocabulary term.  It is preferred that a property either use the value or cvalue_id column but not both.  For example, if the property type is "color" then the cvalue_id could be a term named "green".';
COMMENT ON TABLE projectprop IS 'Standard Chado flexible property table for projects.';

ALTER TABLE pubprop ADD COLUMN cvalue_id bigint;
ALTER TABLE pubprop ADD FOREIGN KEY (cvalue_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL;
COMMENT ON COLUMN pubprop.cvalue_id IS 'The value of the property if that value should be the name of a controlled vocabulary term.  It is preferred that a property either use the value or cvalue_id column but not both.  For example, if the property type is "color" then the cvalue_id could be a term named "green".';

ALTER TABLE quantificationprop ADD COLUMN cvalue_id bigint;
ALTER TABLE quantificationprop ADD FOREIGN KEY (cvalue_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL;
COMMENT ON COLUMN quantificationprop.cvalue_id IS 'The value of the property if that value should be the name of a controlled vocabulary term.  It is preferred that a property either use the value or cvalue_id column but not both.  For example, if the property type is "color" then the cvalue_id could be a term named "green".';

ALTER TABLE stockcollectionprop ADD COLUMN cvalue_id bigint;
ALTER TABLE stockcollectionprop ADD FOREIGN KEY (cvalue_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL;
COMMENT ON COLUMN stockcollectionprop.cvalue_id IS 'The value of the property if that value should be the name of a controlled vocabulary term.  It is preferred that a property either use the value or cvalue_id column but not both.  For example, if the property type is "color" then the cvalue_id could be a term named "green".';

ALTER TABLE stockprop ADD COLUMN cvalue_id bigint;
ALTER TABLE stockprop ADD FOREIGN KEY (cvalue_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL;
COMMENT ON COLUMN stockprop.cvalue_id IS 'The value of the property if that value should be the name of a controlled vocabulary term.  It is preferred that a property either use the value or cvalue_id column but not both.  For example, if the property type is "color" then the cvalue_id could be a term named "green".';

ALTER TABLE studydesignprop ADD COLUMN cvalue_id bigint;
ALTER TABLE studydesignprop ADD FOREIGN KEY (cvalue_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL;
COMMENT ON COLUMN studydesignprop.cvalue_id IS 'The value of the property if that value should be the name of a controlled vocabulary term.  It is preferred that a property either use the value or cvalue_id column but not both.  For example, if the property type is "color" then the cvalue_id could be a term named "green".';

ALTER TABLE studyprop ADD COLUMN cvalue_id bigint;
ALTER TABLE studyprop ADD FOREIGN KEY (cvalue_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL;
COMMENT ON COLUMN studyprop.cvalue_id IS 'The value of the property if that value should be the name of a controlled vocabulary term.  It is preferred that a property either use the value or cvalue_id column but not both.  For example, if the property type is "color" then the cvalue_id could be a term named "green".';

CREATE INDEX acquisitionprop_idx3 ON acquisitionprop USING btree (cvalue_id);
CREATE INDEX analysisfeatureprop_idx3 ON analysisfeatureprop USING btree (cvalue_id);
CREATE INDEX analysisprop_idx3 ON analysisprop USING btree (cvalue_id);
CREATE INDEX arraydesignprop_idx3 ON arraydesignprop USING btree (cvalue_id);
CREATE INDEX assayprop_idx3 ON assayprop USING btree (cvalue_id);
CREATE INDEX biomaterialprop_idx3 ON biomaterialprop USING btree (cvalue_id);
CREATE INDEX cell_lineprop_idx1 ON cell_lineprop USING btree (cvalue_id);
CREATE INDEX contactprop_idx3 ON contactprop USING btree (cvalue_id);
CREATE INDEX expressionprop_idx3 ON expressionprop USING btree (cvalue_id);
CREATE INDEX feature_expressionprop_idx3 ON feature_expressionprop USING btree (cvalue_id);
CREATE INDEX featuremapprop_idx3 ON featuremapprop USING btree (cvalue_id);
CREATE INDEX featureposprop_idx3 ON featureposprop USING btree (cvalue_id);
CREATE INDEX featureprop_idx3 ON featureprop USING btree (cvalue_id);
CREATE INDEX genotypeprop_idx3 ON genotypeprop USING btree (cvalue_id);
CREATE INDEX library_expressionprop_idx3 ON library_expressionprop USING btree (cvalue_id);
CREATE INDEX library_featureprop_idx3 ON library_featureprop USING btree (cvalue_id);
CREATE INDEX libraryprop_idx3 ON libraryprop USING btree (cvalue_id);
CREATE INDEX nd_experiment_stockprop_idx3 ON nd_experiment_stockprop USING btree (cvalue_id);
CREATE INDEX nd_experimentprop_idx3 ON nd_experimentprop USING btree (cvalue_id);
CREATE INDEX nd_geolocationprop_idx3 ON nd_geolocationprop USING btree (cvalue_id);
CREATE INDEX nd_protocolprop_idx3 ON nd_protocolprop USING btree (cvalue_id);
CREATE INDEX nd_reagentprop_idx3 ON nd_reagentprop USING btree (cvalue_id);
CREATE INDEX organismprop_idx3 ON organismprop USING btree (cvalue_id);
CREATE INDEX phenotypeprop_idx3 ON phenotypeprop USING btree (cvalue_id);
CREATE INDEX phylonodeprop_idx3 ON phylonodeprop USING btree (cvalue_id);
CREATE INDEX phylotreeprop_idx3 ON phylotreeprop USING btree (cvalue_id);
CREATE INDEX projectprop_idx1 ON projectprop USING btree (cvalue_id);
CREATE INDEX pubprop_idx3 ON pubprop USING btree (cvalue_id);
CREATE INDEX quantificationprop_idx3 ON quantificationprop USING btree (cvalue_id);
CREATE INDEX stockcollectionprop_idx3 ON stockcollectionprop USING btree (cvalue_id);
CREATE INDEX stockprop_idx3 ON stockprop USING btree (cvalue_id);
CREATE INDEX studydesignprop_idx3 ON studydesignprop USING btree (cvalue_id);
CREATE INDEX studyprop_idx3 ON studyprop USING btree (cvalue_id);

COMMENT ON TABLE project IS 'A project is some kind of planned endeavor.  Used primarily by other Chado modules to group experiments, stocks, and so forth that are associated with eachother administratively or organizationally.';


