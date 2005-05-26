CREATE SCHEMA godb;

--Activate this to make this bridge take precedence
--SET SEARCH PATH TO godb,public;
-- (note that placing godb first in the search path means
--  that godb.dbxref takes precedence over public.dbxref)

--- helper views

CREATE VIEW godb.go_acc AS
 SELECT 
  dbxref_id                          AS dbxref_id,
  db.name || ':' || dbxref.accession AS acc
 FROM dbxref
  INNER JOIN db USING (db_id);

--- dbxref [clash]

CREATE VIEW godb.dbxref AS
 SELECT
  dbxref_id                          AS id,
  db.name                            AS xref_dbname,
  dbxref.accession                   AS xref_key,
  CAST(NULL AS VARCHAR)              AS xref_keytype,
  description                        AS xref_desc
 FROM dbxref
  INNER JOIN db USING (db_id);

-- db [clash] (note in godb, db is only refered to from association table)

CREATE VIEW godb.db AS
 SELECT
  db_id                                 AS id,
  name                                  AS name,
  name                                  AS fullname,
  CAST(NULL AS VARCHAR)                 AS datatype,
  CAST(NULL AS VARCHAR)                 AS url_syntax
 FROM db;
  
--- term

CREATE VIEW term AS
SELECT
 cvterm_id     AS id,
 godb.go_acc.acc AS acc,
 name          AS name,
 is_obsolete   AS is_obsolete,
 0             AS is_root
FROM cvterm
 INNER JOIN godb.go_acc USING (dbxref_id);

--- term_definition

CREATE VIEW term_definition AS
SELECT
 cvterm_id AS term_id,
 definition AS term_definition
FROM cvterm
WHERE definition IS NOT NULL;

--- term_dbxref

CREATE VIEW term_dbxref AS
SELECT
 cvterm_id AS term_id,
 dbxref_id  AS dbxref_id
FROM cvterm_dbxref;

--- term_synonym

CREATE VIEW term_synonym AS
SELECT
 cvterm_id AS term_id,
 synonym  AS term_synonym
FROM cvtermsynonym;

--- term2term

CREATE VIEW term2term AS
SELECT
 cvterm_relationship_id AS id,
 type_id           AS relationship_type_id,
 object_id         AS term1_id,
 subject_id        AS term2_id
FROM cvterm_relationship;

--- graph_path

CREATE VIEW graph_path AS
SELECT
 cvtermpath_id      AS id,
 object_id      AS term1_id,
 subject_id     AS term2_id,
 pathdistance   AS distance
FROM cvtermpath;

-- species

CREATE VIEW species AS
 SELECT
  species_id                            AS id,
  CAST(accession AS INT)                AS ncbi_taxa_id,
  common_name,
  CAST(NULL AS VARCHAR)              AS lineage_string,
  genus,
  species
 FROM
  organism
  INNER JOIN organism_dbxref USING (organism_id)
  INNER JOIN dbxref USING (dbxref_id)
  INNER JOIN db     USING (db_id)
 WHERE db.name='NCBITaxon';

-- gene_product
--  note: secondary_species_id; eg for host species with parasite
--        this will be handled by a feature_relationship in chado

CREATE VIEW gene_product AS
 SELECT
  feature_id                    AS id,
  name                          AS symbol,
  dbxref_id                     AS dbxref_id,
  organism_id                   AS species_id,
  CAST(NULL AS INT)             AS secondary_species_id,
  type_id,
-- todo: make this a left outer join on a featureprop
  name                          AS fullname
 FROM feature;

-- gene_product_synonym

CREATE VIEW gene_product_synonym AS
 SELECT
  feature_id                    AS gene_product_id,
  synonym.name                  AS product_synonym
 FROM
  feature_synonym INNER JOIN synonym USING (synonym_id);

-- gene_product_property

CREATE VIEW gene_product_property AS
 SELECT
  feature_id                    AS gene_product_id
  prop.name                     AS property_key,
  value                         AS property_value
 FROM
  featureprop INNER JOIN cvterm AS prop ON (type_id=cvterm_id);

-- association

CREATE VIEW association AS
 SELECT
  feature_cvterm_id             AS id,
  cvterm_id                     AS term_id,
  feature_id                    AS gene_product_id,
  is_not,
-- not used in godb; maybe never will be
  0                             AS role_group,
-- lets be lazy for now; these are actually feature_cvtermprops
  0                             AS assocdate,
  0                             AS source_db_id
 FROM feature_cvterm;

-- association_qualifier

CREATE VIEW association_qualifier AS
 SELECT
  feature_cvtermprop_id         AS id,
  feature_cvterm_id             AS association_id,
  type_id                       AS term_id,
  value                         AS value
 FROM feature_cvtermprop;

-- evidence
TODO

CREATE VIEW evidence AS
 SELECT
  feature_cvtermprop_id         AS id,
  feature_cvterm_id             AS association_id,
  type_id                       AS term_id,
  value                         AS value
 FROM feature_cvtermprop
 INNER JOIN feature_cvterm_dbxref USING (feature_cvterm_id);

-- evidence_dbxref
TODO

CREATE VIEW evidence_dbxref AS
 SELECT
  feature_cvterm_id         AS id,
  feature_cvterm_id             AS association_id,
  type_id                       AS term_id,
  value                         AS value
 FROM feature_cvtermprop
 INNER JOIN feature_cvterm_dbxref USING (feature_cvterm_id);

-- seq

CREATE VIEW seq AS
 SELECT
  feature_id                    AS id,
  name                          AS display_id,
  name                          AS description,
  residues                      AS seq,
  seqlen                        AS seq_len,
  md5checksum,
  type.name                     AS moltype,
-- this is never used
  0                             AS timestamp
 FROM feature INNER JOIN cvterm AS name ON (type_id=cvterm_id);

-- seq_property [not used?]

CREATE VIEW seq_property AS
 SELECT
  *
 FROM feature WHERE NULL;

-- seq_dbxref
-- [in GO this typically has interpro ids, etc; diff semantics here]

CREATE VIEW seq_dbxref AS
 SELECT 
  feature_id                    AS seq_id,
  dbxref_id
 FROM feature_dbxref;

-- gene_product_seq
-- 1:{0,1} relationship between features and seqs in chado

CREATE VIEW gene_product_seq AS
 SELECT
  feature_id              AS gene_product_id,
  feature_id              AS seq_id
 FROM feature
 WHERE feature.residues IS NOT NULL;

-- gene_product_count
-- this is an OPTIONAL godb optimization
--  simulate a rowless table for now

CREATE VIEW gene_product_count AS
 SELECT
  *
 FROM feature WHERE NULL;


-- ************************************************************
-- UPDATE RULES
-- ************************************************************
-- NOT COMPLETE

-- we don't really need these as loading is easy enough
-- to do with xslts

CREATE RULE "_RuleI_term_definition" AS
 ON INSERT TO term_definition
 DO INSTEAD
  UPDATE cvterm
  SET
  definition = NEW.term_definition
  WHERE cvterm_id = NEW.term_id;

CREATE RULE "_RuleU_term_definition" AS
 ON UPDATE TO term_definition
 DO INSTEAD
  UPDATE cvterm
  SET
  definition = NEW.term_definition
  WHERE cvterm_id = OLD.term_id;

CREATE RULE "_RuleD_term_definition" AS
 ON DELETE TO term_definition
 DO INSTEAD
  UPDATE cvterm
  SET
  definition = NULL
  WHERE cvterm_id = OLD.term_id;

CREATE RULE "_RuleI_term2term" AS
 ON INSERT TO term2term
 DO INSTEAD
  INSERT INTO cvterm_relationship
  (
   type_id,
   object_id,
   subject_id)
  VALUES
  (
   NEW.relationship_type_id, 
   NEW.term1_id,
   NEW.term2_id
  );

CREATE RULE "_RuleU_term2term" AS
 ON UPDATE TO term2term
 DO INSTEAD
  UPDATE cvterm_relationship
  SET
 type_id        = NEW.relationship_type_id,
 object_id        = NEW.term1_id,
 subject_id       = NEW.term2_id
  WHERE cvterm_relationship_id = OLD.id;

CREATE RULE "_RuleD_term2term" AS
 ON DELETE TO term2term
 DO INSTEAD
  DELETE FROM cvterm_relationship
  WHERE cvterm_relationship_id = OLD.id;

CREATE RULE "_RuleI_graph_path" AS
 ON INSERT TO graph_path
 DO INSTEAD
  INSERT INTO cvtermpath
  (
   type_id,
   object_id,
   subject_id,
   pathdistance)
  VALUES
  (
   NULL,
   NEW.term1_id,
   NEW.term2_id,
   NEW.distance
  );

CREATE RULE "_RuleU_graph_path" AS
 ON UPDATE TO graph_path
 DO INSTEAD
  UPDATE cvtermpath
  SET
 type_id        = NULL,
 object_id        = NEW.term1_id,
 subject_id       = NEW.term2_id,
 pathdistance      = NEW.distance
  WHERE cvtermpath_id = OLD.id;

CREATE RULE "_RuleD_graph_path" AS
 ON DELETE TO graph_path
 DO INSTEAD
  DELETE FROM cvtermpath
  WHERE cvtermpath_id = OLD.id;


CREATE RULE "_RuleI_term_synonym" AS
 ON INSERT TO term_synonym
 DO INSTEAD
  INSERT INTO cvtermsynonym
  (cvterm_id, synonym)
  VALUES
  (NEW.term_id, NEW.term_synonym);

CREATE RULE "_RuleU_term_synonym" AS
 ON UPDATE TO term_synonym
 DO INSTEAD
  UPDATE cvtermsynonym
  SET
 cvterm_id = NEW.term_id,
 synonym  = NEW.term_synonym
  WHERE cvterm_id = OLD.term_id AND synonym = OLD.term_synonym;

CREATE RULE "_RuleD_term_synonym" AS
 ON DELETE TO term_synonym
 DO INSTEAD
  DELETE FROM cvtermsynonym
  WHERE cvterm_id = OLD.term_id AND synonym = OLD.term_synonym;

CREATE RULE "_RuleI_term_dbxref" AS
 ON INSERT TO term_dbxref
 DO INSTEAD
  INSERT INTO cvterm_dbxref
  (cvterm_id, dbxref_id)
  VALUES
  (NEW.term_id, NEW.dbxref_id);

CREATE RULE "_RuleU_term_dbxref" AS
 ON UPDATE TO term_dbxref
 DO INSTEAD
  UPDATE cvterm_dbxref
  SET
 cvterm_id = NEW.term_id,
 dbxref_id  = NEW.dbxref_id
  WHERE cvterm_id = OLD.term_id AND dbxref_id = OLD.dbxref_id;

CREATE RULE "_RuleD_term_dbxref" AS
 ON DELETE TO term_dbxref
 DO INSTEAD
  DELETE FROM cvterm_dbxref
  WHERE cvterm_id = OLD.term_id AND dbxref_id = OLD.dbxref_id;


