CREATE SCHEMA godb;

--Activate this to make this bridge take precedence
--SET SEARCH PATH TO godb,public;
-- (note that placing godb first in the search path means
--  that godb.dbxref takes precedence over public.dbxref)

CREATE TABLE godb.instance_data (
  release_name varchar(255),
  release_type varchar(255),
  release_notes text
);

--- helper views

--view
CREATE VIEW godb.v_go_acc AS
 SELECT 
  dbxref_id                          AS dbxref_id,
  db.name || ':' || dbxref.accession AS acc
 FROM public.dbxref
  INNER JOIN public.db USING (db_id);
--materialized view
CREATE TABLE godb.go_acc (
  dbxref_id int,
  acc text
);
CREATE INDEX go_acc_idx1 ON godb.go_acc (dbxref_id);
CREATE INDEX go_acc_idx2 ON godb.go_acc (acc);
--load
INSERT INTO godb.go_acc SELECT * FROM godb.v_go_acc;

--- dbxref [clash]

--view
CREATE VIEW godb.v_dbxref AS
 SELECT
  dbxref_id                          AS id,
  db.name                            AS xref_dbname,
  dbxref.accession                   AS xref_key,
  CAST(NULL AS VARCHAR)              AS xref_keytype,
  dbxref.description                 AS xref_desc
 FROM public.dbxref
  INNER JOIN public.db USING (db_id);
--materialized view
CREATE TABLE godb.dbxref (
  id int,
  xref_dbname varchar(255),
  xref_key varchar(255),
  xref_keytype varchar(255),
  xref_desc text
);
CREATE INDEX dbxref_idx1 ON godb.dbxref (id);
CREATE INDEX dbxref_idx2 ON godb.dbxref (xref_dbname);
CREATE INDEX dbxref_idx3 ON godb.dbxref (xref_key);
CREATE INDEX dbxref_idx4 ON godb.dbxref (xref_keytype);
CREATE INDEX dbxref_idx5 ON godb.dbxref (xref_desc);
--load
INSERT INTO godb.dbxref SELECT * FROM godb.v_dbxref;


--
--/allen
--

-- db [clash] (note in godb, db is only refered to from association table)

--view
CREATE VIEW godb.v_db AS
 SELECT
  db_id                                 AS id,
  name                                  AS name,
  name                                  AS fullname,
  CAST(NULL AS VARCHAR)                 AS datatype,
  CAST(NULL AS VARCHAR)                 AS url_syntax
 FROM public.db;
--materialized view
CREATE TABLE godb.db (
  id int,
  name varchar(255),
  fullname varchar(255),
  datatype varchar(255),
  url_syntax varchar(255)
);
CREATE INDEX db_idx1 ON godb.db (id);
CREATE INDEX db_idx2 ON godb.db (name);
CREATE INDEX db_idx3 ON godb.db (fullname);
CREATE INDEX db_idx4 ON godb.db (datatype);
CREATE INDEX db_idx5 ON godb.db (url_syntax);
--load
INSERT INTO godb.db SELECT * FROM godb.v_db;
  
--- term

--view
CREATE VIEW godb.v_term AS
SELECT
 cvterm_id     AS id,
 godb.go_acc.acc AS acc,
 name          AS name,
 is_obsolete   AS is_obsolete,
 0             AS is_root
FROM public.cvterm
 INNER JOIN godb.go_acc USING (dbxref_id);
--materialized_view
CREATE TABLE godb.term (
  id int,
  acc text,
  name varchar(1024),
  is_obsolete int,
  is_root int
);
CREATE INDEX term_idx1 ON godb.term (id);
CREATE INDEX term_idx2 ON godb.term (acc);
CREATE INDEX term_idx3 ON godb.term (name);
CREATE INDEX term_idx4 ON godb.term (is_obsolete);
CREATE INDEX term_idx5 ON godb.term (is_root);
--load
INSERT INTO godb.term SELECT * FROM godb.v_term;
UPDATE term SET is_root = 1 WHERE id IN (SELECT cvterm_id FROM cvterm WHERE cvterm_id NOT IN (SELECT DISTINCT subject_id FROM cvterm_relationship) AND is_obsolete = 0 AND is_relationshiptype = 0);

--- term_definition
--view
CREATE VIEW godb.term_definition AS
SELECT
 cvterm_id AS term_id,
 definition AS term_definition
FROM public.cvterm
WHERE definition IS NOT NULL;

--- term_dbxref
--view
CREATE VIEW godb.term_dbxref AS
SELECT
 cvterm_id AS term_id,
 dbxref_id  AS dbxref_id,
 0 AS is_for_definition
FROM public.cvterm_dbxref;

--- term_synonym
--view
CREATE VIEW godb.term_synonym AS
SELECT
 cvterm_id AS term_id,
 synonym  AS term_synonym,
 type_id AS synonym_type_id
FROM public.cvtermsynonym;

--- term2term
--view
CREATE VIEW godb.v_term2term AS
SELECT
 cvterm_relationship_id AS id,
 type_id           AS relationship_type_id,
 object_id         AS term1_id,
 subject_id        AS term2_id
FROM public.cvterm_relationship;
--materialized view
CREATE TABLE godb.term2term (
  id int,
  relationship_type_id int,
  term1_id int,
  term2_id int
);
CREATE INDEX term2term_idx1 ON godb.term2term (id);
CREATE INDEX term2term_idx2 ON godb.term2term (relationship_type_id);
CREATE INDEX term2term_idx3 ON godb.term2term (term1_id);
CREATE INDEX term2term_idx4 ON godb.term2term (term2_id);
--load
INSERT INTO godb.term2term SELECT * FROM godb.v_term2term;

--- graph_path
--view
CREATE VIEW godb.v_graph_path AS
SELECT
 cvtermpath_id      AS id,
 object_id      AS term1_id,
 subject_id     AS term2_id,
 pathdistance   AS distance
FROM public.cvtermpath;
--materialized view
CREATE TABLE godb.graph_path (
  id int,
  term1_id int,
  term2_id int,
  distance int 
);
CREATE INDEX graph_path_idx1 ON godb.graph_path (id);
CREATE INDEX graph_path_idx2 ON godb.graph_path (term1_id);
CREATE INDEX graph_path_idx3 ON godb.graph_path (term2_id);
CREATE INDEX graph_path_idx4 ON godb.graph_path (distance);
--load
INSERT INTO godb.graph_path SELECT * FROM godb.v_graph_path;

--Activate this to make this bridge take precedence
--SET SEARCH PATH TO godb,public;

-- species
--view
CREATE VIEW godb.species AS
 SELECT
  organism_id                        AS id,
--FIXME this cast does not work
--  CAST(accession AS INT)             AS ncbi_taxa_id,
  accession                          AS ncbi_taxa_id,
  common_name,
  CAST(NULL AS VARCHAR)              AS lineage_string,
  genus,
  species
 FROM
  public.organism
  INNER JOIN public.organism_dbxref USING (organism_id)
  INNER JOIN public.dbxref USING (dbxref_id) --schema correct?
  INNER JOIN public.db     USING (db_id) --schema correct?
 WHERE db.name='NCBITaxon';

-- gene_product
--  note: secondary_species_id; eg for host species with parasite
--        this will be handled by a feature_relationship in chado
--view
CREATE VIEW godb.gene_product AS
 SELECT
  feature_id                    AS id,
  name                          AS symbol,
  dbxref_id                     AS dbxref_id,
  organism_id                   AS species_id,
  CAST(NULL AS INT)             AS secondary_species_id,
  type_id,
-- todo: make this a left outer join on a featureprop
  name                          AS fullname
 FROM public.feature;

-- gene_product_synonym
--view
CREATE VIEW godb.gene_product_synonym AS
 SELECT
  feature_id                    AS gene_product_id,
  synonym.name                  AS product_synonym
 FROM
  public.feature_synonym INNER JOIN public.synonym USING (synonym_id);

-- gene_product_property
--view
CREATE VIEW godb.gene_product_property AS
 SELECT
  feature_id                    AS gene_product_id,
  prop.name                     AS property_key,
  value                         AS property_value
 FROM
  public.featureprop INNER JOIN public.cvterm AS prop ON (type_id=cvterm_id);

-- association
--view
CREATE VIEW godb.association AS
 SELECT
  feature_cvterm_id             AS id,
  cvterm_id                     AS term_id,
  feature_id                    AS gene_product_id,
  is_not                        AS is_not,
-- not used in godb; maybe never will be
  0                             AS role_group,
-- lets be lazy for now; these are actually feature_cvtermprops
  0                             AS assocdate,
  0                             AS source_db_id
 FROM public.feature_cvterm;

-- association_qualifier
--view
CREATE VIEW godb.association_qualifier AS
 SELECT
  feature_cvtermprop_id         AS id,
  feature_cvterm_id             AS association_id,
  type_id                       AS term_id,
  value                         AS value
 FROM public.feature_cvtermprop;

-- evidence
-- TODO!!
--view
CREATE VIEW godb.evidence AS
 SELECT
  feature_cvtermprop_id         AS id,
  feature_cvterm_id             AS association_id,
  type_id                       AS term_id,
  value                         AS value
 FROM public.feature_cvtermprop
 INNER JOIN public.feature_cvterm_dbxref USING (feature_cvterm_id);

-- evidence_dbxref
-- TODO
--view
CREATE VIEW godb.evidence_dbxref AS
 SELECT
  feature_cvterm_id         AS id,
  feature_cvterm_id             AS association_id,
  type_id                       AS term_id,
  value                         AS value
 FROM public.feature_cvtermprop
 INNER JOIN public.feature_cvterm_dbxref USING (feature_cvterm_id);

-- seq
--view
CREATE VIEW godb.seq AS
 SELECT
  feature_id                    AS id,
  feature.name                  AS display_id,
  feature.name                  AS description,
  residues                      AS seq,
  seqlen                        AS seq_len,
  md5checksum,
  type.name                     AS moltype,
-- this is never used
  0                             AS timestamp
 FROM public.feature INNER JOIN public.cvterm AS type ON (type_id=cvterm_id);

-- seq_property [not used?]
--view
CREATE VIEW godb.seq_property AS
 SELECT
  *
 FROM public.feature WHERE NULL;

-- seq_dbxref
-- [in GO this typically has interpro ids, etc; diff semantics here]
--view
CREATE VIEW godb.seq_dbxref AS
 SELECT 
  feature_id                    AS seq_id,
  dbxref_id
 FROM public.feature_dbxref;

-- gene_product_seq
-- 1:{0,1} relationship between features and seqs in chado
--view
CREATE VIEW godb.gene_product_seq AS
 SELECT
  feature_id              AS gene_product_id,
  feature_id              AS seq_id
 FROM public.feature
 WHERE feature.residues IS NOT NULL;

-- gene_product_count
-- this is an OPTIONAL godb optimization
--  simulate a rowless table for now
--view
CREATE VIEW godb.gene_product_count AS
 SELECT
  *
 FROM public.feature WHERE NULL;



-- ************************************************************
-- UPDATE RULES
-- ************************************************************
-- NOT COMPLETE

-- we don't really need these as loading is easy enough
-- to do with xslts

CREATE RULE "_RuleI_term_definition" AS
 ON INSERT TO godb.term_definition
 DO INSTEAD
  UPDATE public.cvterm
  SET
  definition = NEW.term_definition
  WHERE cvterm_id = NEW.term_id;

CREATE RULE "_RuleU_term_definition" AS
 ON UPDATE TO godb.term_definition
 DO INSTEAD
  UPDATE public.cvterm
  SET
  definition = NEW.term_definition
  WHERE cvterm_id = OLD.term_id;

CREATE RULE "_RuleD_term_definition" AS
 ON DELETE TO godb.term_definition
 DO INSTEAD
  UPDATE public.cvterm
  SET
  definition = NULL
  WHERE cvterm_id = OLD.term_id;

CREATE RULE "_RuleI_term2term" AS
 ON INSERT TO godb.term2term
 DO INSTEAD
  INSERT INTO public.cvterm_relationship
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
 ON UPDATE TO godb.term2term
 DO INSTEAD
  UPDATE public.cvterm_relationship
  SET
 type_id        = NEW.relationship_type_id,
 object_id        = NEW.term1_id,
 subject_id       = NEW.term2_id
  WHERE cvterm_relationship_id = OLD.id;

CREATE RULE "_RuleD_term2term" AS
 ON DELETE TO godb.term2term
 DO INSTEAD
  DELETE FROM public.cvterm_relationship
  WHERE cvterm_relationship_id = OLD.id;

CREATE RULE "_RuleI_graph_path" AS
 ON INSERT TO godb.graph_path
 DO INSTEAD
  INSERT INTO public.cvtermpath
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
 ON UPDATE TO godb.graph_path
 DO INSTEAD
  UPDATE public.cvtermpath
  SET
 type_id        = NULL,
 object_id        = NEW.term1_id,
 subject_id       = NEW.term2_id,
 pathdistance      = NEW.distance
  WHERE cvtermpath_id = OLD.id;

CREATE RULE "_RuleD_graph_path" AS
 ON DELETE TO godb.graph_path
 DO INSTEAD
  DELETE FROM public.cvtermpath
  WHERE cvtermpath_id = OLD.id;


CREATE RULE "_RuleI_term_synonym" AS
 ON INSERT TO godb.term_synonym
 DO INSTEAD
  INSERT INTO public.cvtermsynonym
  (cvterm_id, synonym)
  VALUES
  (NEW.term_id, NEW.term_synonym);

CREATE RULE "_RuleU_term_synonym" AS
 ON UPDATE TO godb.term_synonym
 DO INSTEAD
  UPDATE public.cvtermsynonym
  SET
 cvterm_id = NEW.term_id,
 synonym  = NEW.term_synonym
  WHERE cvterm_id = OLD.term_id AND synonym = OLD.term_synonym;

CREATE RULE "_RuleD_term_synonym" AS
 ON DELETE TO godb.term_synonym
 DO INSTEAD
  DELETE FROM public.cvtermsynonym
  WHERE cvterm_id = OLD.term_id AND synonym = OLD.term_synonym;

CREATE RULE "_RuleI_term_dbxref" AS
 ON INSERT TO godb.term_dbxref
 DO INSTEAD
  INSERT INTO public.cvterm_dbxref
  (cvterm_id, dbxref_id)
  VALUES
  (NEW.term_id, NEW.dbxref_id);

CREATE RULE "_RuleU_term_dbxref" AS
 ON UPDATE TO godb.term_dbxref
 DO INSTEAD
  UPDATE public.cvterm_dbxref
  SET
 cvterm_id = NEW.term_id,
 dbxref_id  = NEW.dbxref_id
  WHERE cvterm_id = OLD.term_id AND dbxref_id = OLD.dbxref_id;

CREATE RULE "_RuleD_term_dbxref" AS
 ON DELETE TO godb.term_dbxref
 DO INSTEAD
  DELETE FROM public.cvterm_dbxref
  WHERE cvterm_id = OLD.term_id AND dbxref_id = OLD.dbxref_id;
