--- term

CREATE VIEW term AS
SELECT
 cvterm_id AS id,
--is this correct?  what is acc? -allen
 termdefinition AS acc,
 name           AS name,
 is_obsolete    AS is_obsolete,
 0              AS is_root
FROM cvterm;

CREATE RULE "_RuleI_term" AS
 ON INSERT TO term
 DO INSTEAD
  INSERT INTO cvterm
  (termdefinition, name)
  VALUES
  (NEW.acc, NEW.name);

CREATE RULE "_RuleU_term" AS
 ON UPDATE TO term
 DO INSTEAD
  UPDATE cvterm
  SET
  termdefinition = NEW.acc,
  name      = NEW.name
  WHERE cvterm_id = OLD.id;

CREATE RULE "_RuleD_term" AS
 ON DELETE TO term
 DO INSTEAD
  DELETE FROM cvterm
  WHERE cvterm_id = OLD.id;

--- term_definition

CREATE VIEW term_definition AS
SELECT
 cvterm_id AS term_id,
 termdefinition AS term_definition
FROM cvterm
WHERE termdefinition IS NOT NULL;

CREATE RULE "_RuleI_term_definition" AS
 ON INSERT TO term_definition
 DO INSTEAD
  UPDATE cvterm
  SET
  termdefinition = NEW.term_definition
  WHERE cvterm_id = NEW.term_id;

CREATE RULE "_RuleU_term_definition" AS
 ON UPDATE TO term_definition
 DO INSTEAD
  UPDATE cvterm
  SET
  termdefinition = NEW.term_definition
  WHERE cvterm_id = OLD.term_id;

CREATE RULE "_RuleD_term_definition" AS
 ON DELETE TO term_definition
 DO INSTEAD
  UPDATE cvterm
  SET
  termdefinition = NULL
  WHERE cvterm_id = OLD.term_id;

--- term2term

CREATE VIEW term2term AS
SELECT
 cvrelationship_id AS id,
 type_id        AS relationship_type_id,
 object_id        AS term1_id,
 subject_id       AS term2_id
FROM cvrelationship;

CREATE RULE "_RuleI_term2term" AS
 ON INSERT TO term2term
 DO INSTEAD
  INSERT INTO cvrelationship
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
  UPDATE cvrelationship
  SET
 type_id        = NEW.relationship_type_id,
 object_id        = NEW.term1_id,
 subject_id       = NEW.term2_id
  WHERE cvrelationship_id = OLD.id;

CREATE RULE "_RuleD_term2term" AS
 ON DELETE TO term2term
 DO INSTEAD
  DELETE FROM cvrelationship
  WHERE cvrelationship_id = OLD.id;

--- graph_path

CREATE VIEW graph_path AS
SELECT
 cvpath_id AS id,
 NULL              AS relationship_type_id,
 object_id        AS term1_id,
 subject_id       AS term2_id,
 pathdistance      AS distance
FROM cvpath;

CREATE RULE "_RuleI_graph_path" AS
 ON INSERT TO graph_path
 DO INSTEAD
  INSERT INTO cvpath
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
  UPDATE cvpath
  SET
 type_id        = NULL,
 object_id        = NEW.term1_id,
 subject_id       = NEW.term2_id,
 pathdistance      = NEW.distance
  WHERE cvpath_id = OLD.id;

CREATE RULE "_RuleD_graph_path" AS
 ON DELETE TO graph_path
 DO INSTEAD
  DELETE FROM cvpath
  WHERE cvpath_id = OLD.id;

--- term_synonym

CREATE VIEW term_synonym AS
SELECT
 cvterm_id AS term_id,
 termsynonym  AS term_synonym
FROM cvtermsynonym;

CREATE RULE "_RuleI_term_synonym" AS
 ON INSERT TO term_synonym
 DO INSTEAD
  INSERT INTO cvtermsynonym
  (cvterm_id, termsynonym)
  VALUES
  (NEW.term_id, NEW.term_synonym);

CREATE RULE "_RuleU_term_synonym" AS
 ON UPDATE TO term_synonym
 DO INSTEAD
  UPDATE cvtermsynonym
  SET
 cvterm_id = NEW.term_id,
 termsynonym  = NEW.term_synonym
  WHERE cvterm_id = OLD.term_id AND termsynonym = OLD.term_synonym;

CREATE RULE "_RuleD_term_synonym" AS
 ON DELETE TO term_synonym
 DO INSTEAD
  DELETE FROM cvtermsynonym
  WHERE cvterm_id = OLD.term_id AND termsynonym = OLD.term_synonym;

--- term_dbxref

CREATE VIEW term_dbxref AS
SELECT
 cvterm_id AS term_id,
 dbxref_id  AS dbxref_id
FROM cvterm_dbxref;

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

---- dbxref - tricky, namespace clash...

