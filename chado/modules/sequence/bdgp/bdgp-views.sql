-- bdgp-views.sql
--
-- these are a set of handy views used over chado within BDGP
-- typically they provide a flatter/denormalised view over chado
-- which is useful for simplifying queries

-- ================================================
-- featurepropd = featureprop * cvterm
-- ================================================
-- Adds property type name to featureprop

CREATE VIEW featurepropd AS
 SELECT featureprop.*, 
        cvterm.name AS type
 FROM 
   featureprop
    INNER JOIN cvterm ON (featureprop.type_id=cvterm.cvterm_id);

-- ================================================
-- dbxrefd = dbxref * db
-- ================================================
-- Adds dbname to dbxref
CREATE VIEW dbxrefd AS
 SELECT dbxref.*,
        db.name AS dbname
 FROM
  dbxref INNER JOIN db USING (db_id);

-- ================================================
-- tfeature = feature * cvterm
-- ================================================
-- Adds feature type name to feature
CREATE VIEW tfeature AS
 SELECT feature.*,
        cvterm.name AS type
 FROM
  feature INNER JOIN cvterm ON (feature.type_id=cvterm.cvterm_id);

-- ================================================
-- featurelocf = featureloc * (src)feature
-- ================================================
-- Adds srcfeature name to featureloc
CREATE VIEW featurelocf AS
 SELECT featureloc.*,
        feature.name AS srcname,
        feature.uniquename AS srcuniquename
 FROM
  featureloc INNER JOIN feature ON (featureloc.srcfeature_id=feature.feature_id);


