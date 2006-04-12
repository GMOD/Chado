create table tableinfo (
    tableinfo_id serial not null,
    primary key (tableinfo_id),
    name varchar(30) not null,
    primary_key_column varchar(30) null,
    is_view int not null default 0,
    view_on_table_id int null,
    superclass_table_id int null,
    is_updateable int not null default 1,
    modification_date date not null default now(),
    constraint tableinfo_c1 unique (name)
);

COMMENT ON TABLE tableinfo IS NULL;

create table db (
    db_id serial not null,
    primary key (db_id),
    name varchar(255) not null,
--    contact_id int,
--    foreign key (contact_id) references contact (contact_id) on delete cascade INITIALLY DEFERRED,
    description varchar(255) null,
    urlprefix varchar(255) null,
    url varchar(255) null,
    constraint db_c1 unique (name)
);

COMMENT ON TABLE db IS 'A database authority. Typical dbs in
bioinformatics are FlyBase, GO, UniProt, NCBI, MGI, etc. The authority
is generally known by this sortened form, which is unique within the
bioinformatics and biomedical realm.  **TODO** - add support for URIs,
URNs (eg LSIDs). We can do this by treating the url as a uri -
however, some applications may expect this to be resolvable - to be
decided';

create table dbxref (
    dbxref_id serial not null,
    primary key (dbxref_id),
    db_id int not null,
    foreign key (db_id) references db (db_id) on delete cascade INITIALLY DEFERRED,
    accession varchar(255) not null,
    version varchar(255) not null default '',
    description text,
    constraint dbxref_c1 unique (db_id,accession,version)
);
create index dbxref_idx1 on dbxref (db_id);
create index dbxref_idx2 on dbxref (accession);
create index dbxref_idx3 on dbxref (version);

COMMENT ON TABLE dbxref IS 'A unique, global, public, stable identifier. Not necessarily an eXternal reference - can reference data items inside the particular chado instance being used. Typically a row in a table can be uniquely identified with a primary identifier (called dbxref_id); a table may also have secondary identifiers (in a linking table <T>_dbxref). A dbxref is generally written as <DB>:<ACCESSION> or as <DB>:<ACCESSION>:<VERSION>. ';

COMMENT ON COLUMN dbxref.accession IS 'The local part of the identifier. Guaranteed by the db authority to be unique for that db';

-- ================================================
-- TABLE: project
-- ================================================
create table project (
    project_id serial not null,  
    primary key (project_id),
    name varchar(255) not null,
    description varchar(255) not null,
    constraint project_c1 unique (name)
);

COMMENT ON TABLE project IS NULL;

CREATE OR REPLACE FUNCTION store_db (VARCHAR) 
  RETURNS INT AS 
'DECLARE
   v_name             ALIAS FOR $1;

   v_db_id            INTEGER;
 BEGIN
    SELECT INTO v_db_id db_id
      FROM db
      WHERE name=v_name;
    IF NOT FOUND THEN
      INSERT INTO db
       (name)
         VALUES
       (v_name)
       RETURN currval(''db_db_id_seq'');
    END IF;
    RETURN v_db_id;
 END;
' LANGUAGE 'plpgsql';
  
CREATE OR REPLACE FUNCTION store_dbxref (VARCHAR,VARCHAR) 
  RETURNS INT AS 
'DECLARE
   v_dbname                ALIAS FOR $1;
   v_accession             ALIAS FOR $1;

   v_db_id                 INTEGER;
   v_dbxref_id             INTEGER;
 BEGIN
    SELECT INTO v_db_id
      store_db(v_dbname);
    SELECT INTO v_dbxref_id dbxref_id
      FROM dbxref
      WHERE db_id=v_db_id       AND
            accession=v_accession;
    IF NOT FOUND THEN
      INSERT INTO dbxref
       (db_id,accession)
         VALUES
       (v_db_id,v_accession)
       RETURN currval(''dbxref_dbxref_id_seq'');
    END IF;
    RETURN v_dbxref_id;
 END;
' LANGUAGE 'plpgsql';
  

create table cv (
    cv_id serial not null,
    primary key (cv_id),
    name varchar(255) not null,
   definition text,
   constraint cv_c1 unique (name)
);

COMMENT ON TABLE cv IS 'A controlled vocabulary or ontology. A cv is composed of cvterms (aka terms, classes, concepts, frames) and the relationships between them';

COMMENT ON COLUMN cv.name IS 'The name of the ontology. This corresponds to the obo-format -namespace-. cv names are unique';

COMMENT ON COLUMN cv.definition IS 'A description of the criteria for membership of this ontology';


create table cvterm (
    cvterm_id serial not null,
    primary key (cvterm_id),
    cv_id int not null,
    foreign key (cv_id) references cv (cv_id) on delete cascade INITIALLY DEFERRED,
    name varchar(1024) not null,
    definition text,
    dbxref_id int not null,
    foreign key (dbxref_id) references dbxref (dbxref_id) on delete set null INITIALLY DEFERRED,
    is_obsolete int not null default 0,
    is_relationshiptype int not null default 0,
    constraint cvterm_c1 unique (name,cv_id,is_obsolete),
    constraint cvterm_c2 unique (dbxref_id)
);
COMMENT ON TABLE cvterm IS
 'A term, class or concept within an ontology or controlled vocabulary.
  Also used for relationship types. A cvterm can also be thought of
  as a node in a graph';
COMMENT ON COLUMN cvterm.cv_id IS
 'The cv/ontology/namespace to which this cvterm belongs';
COMMENT ON COLUMN cvterm.name IS
 'A concise human-readable name describing the meaning of the cvterm';
COMMENT ON COLUMN cvterm.definition IS
 'A human-readable text definition';
COMMENT ON COLUMN cvterm.dbxref_id IS
 'Primary dbxref - The unique global OBO identifier for this cvterm.
  Note that a cvterm may  have multiple secondary dbxrefs - see also
  table: cvterm_dbxref';
COMMENT ON COLUMN cvterm.is_obsolete IS
 'Boolean 0=false,1=true; see GO documentation for details of obsoletion.
  note that two terms with different primary dbxrefs may exist if one
  is obsolete';
COMMENT ON COLUMN cvterm.is_relationshiptype IS
 'Boolean 0=false,1=true
  Relationship types (also known as Typedefs in OBO format, or as
  properties or slots) form a cv/ontology in themselves. We use this
  flag to indicate whether this cvterm is an actual term/concept or
  a relationship type';
COMMENT ON INDEX cvterm_c1 IS 'a name can mean different things in
different contexts; for example "chromosome" in SO and GO. A name
should be unique within an ontology/cv. A name may exist twice in a
cv, in both obsolete and non-obsolete forms - these will be for
different cvterms with different OBO identifiers; so GO documentation
for more details on obsoletion. Note that occasionally multiple
obsolete terms with the same name will exist in the same cv. If this
is a possibility for the ontology under consideration (eg GO) then the
ID should be appended to the name to ensure uniqueness';
COMMENT ON INDEX cvterm_c2 IS 
 'the OBO identifier is globally unique';

create index cvterm_idx1 on cvterm (cv_id);
create index cvterm_idx2 on cvterm (name);
create index cvterm_idx3 on cvterm (dbxref_id);

create table cvterm_relationship (
    cvterm_relationship_id serial not null,
    primary key (cvterm_relationship_id),
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    subject_id int not null,
    foreign key (subject_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    object_id int not null,
    foreign key (object_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    constraint cvterm_relationship_c1 unique (subject_id,object_id,type_id)
);
COMMENT ON TABLE cvterm_relationship IS
 'A relationship linking two cvterms. A relationship can be thought of
  as an edge in a graph, or as a natural language statement about
  two cvterms. The statement is of the form SUBJECT PREDICATE OBJECT;
  for example "wing part_of body"';

COMMENT ON COLUMN cvterm_relationship.subject_id IS 'the subject of the subj-predicate-obj sentence. In a DAG, this corresponds to the child node';
COMMENT ON COLUMN cvterm_relationship.object_id IS 'the object of the subj-predicate-obj sentence. In a DAG, this corresponds to the parent node';
COMMENT ON COLUMN cvterm_relationship.type_id IS 'relationship type between subject and object. This is a cvterm, typically from the OBO relationship ontology, although other relationship types are allowed';

create index cvterm_relationship_idx1 on cvterm_relationship (type_id);
create index cvterm_relationship_idx2 on cvterm_relationship (subject_id);
create index cvterm_relationship_idx3 on cvterm_relationship (object_id);


create table cvtermpath (
    cvtermpath_id serial not null,
    primary key (cvtermpath_id),
    type_id int,
    foreign key (type_id) references cvterm (cvterm_id) on delete set null INITIALLY DEFERRED,
    subject_id int not null,
    foreign key (subject_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    object_id int not null,
    foreign key (object_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    cv_id int not null,
    foreign key (cv_id) references cv (cv_id) on delete cascade INITIALLY DEFERRED,
    pathdistance int,
    constraint cvtermpath_c1 unique (subject_id,object_id,type_id,pathdistance)
);

COMMENT ON TABLE cvtermpath IS 'The reflexive transitive closure of the cvterm_relationship relation. For a full discussion, see the file populating-cvtermpath.txt in this directory';

COMMENT ON COLUMN cvtermpath.type_id IS 'The relationship type that this is a closure over. If null, then this is a closure over ALL relationship types. If non-null, then this references a relationship cvterm - note that the closure will apply to both this relationship AND the OBO_REL:is_a (subclass) relationship';

COMMENT ON COLUMN cvtermpath.cv_id IS 'Closures will mostly be within one cv. If the closure of a relationship traverses a cv, then this refers to the cv of the object_id cvterm';

COMMENT ON COLUMN cvtermpath.pathdistance IS 'The number of steps required to get from the subject cvterm to the object cvterm, counting from zero (reflexive relationship)';

create index cvtermpath_idx1 on cvtermpath (type_id);
create index cvtermpath_idx2 on cvtermpath (subject_id);
create index cvtermpath_idx3 on cvtermpath (object_id);
create index cvtermpath_idx4 on cvtermpath (cv_id);


create table cvtermsynonym (
    cvtermsynonym_id serial not null,
    primary key (cvtermsynonym_id),
    cvterm_id int not null,
    foreign key (cvterm_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    synonym varchar(1024) not null,
    type_id int,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade  INITIALLY DEFERRED,
    constraint cvtermsynonym_c1 unique (cvterm_id,synonym)
);

COMMENT ON TABLE cvtermsynonym IS 'A cvterm actually represents a distinct class or concept. A concept can be refered to by different phrases or names. In addition to the primary name (cvterm.name) there can be a number of alternative aliases or synonyms. For example, -T cell- as a synonym for -T lymphocyte-';

COMMENT ON COLUMN cvtermsynonym.type_id IS 'A synonym can be exact, narrow or borader than';

create index cvtermsynonym_idx1 on cvtermsynonym (cvterm_id);


create table cvterm_dbxref (
    cvterm_dbxref_id serial not null,
    primary key (cvterm_dbxref_id),
    cvterm_id int not null,
    foreign key (cvterm_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    dbxref_id int not null,
    foreign key (dbxref_id) references dbxref (dbxref_id) on delete cascade INITIALLY DEFERRED,
    is_for_definition int not null default 0,
    constraint cvterm_dbxref_c1 unique (cvterm_id,dbxref_id)
);

COMMENT ON TABLE cvterm_dbxref IS 'In addition to the primary identifier (cvterm.dbxref_id) a cvterm can have zero or more secondary identifiers, which may be in external databases';

COMMENT ON COLUMN cvterm_dbxref.is_for_definition IS 'A cvterm.definition should be supported by one or more references. If this column is true, the dbxref is not for a term in an external db - it is a dbxref for provenance information for the definition';

create index cvterm_dbxref_idx1 on cvterm_dbxref (cvterm_id);
create index cvterm_dbxref_idx2 on cvterm_dbxref (dbxref_id);


create table cvtermprop ( 
    cvtermprop_id serial not null, 
    primary key (cvtermprop_id), 
    cvterm_id int not null, 
    foreign key (cvterm_id) references cvterm (cvterm_id) on delete cascade, 
    type_id int not null, 
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade, 
    value text not null default '', 
    rank int not null default 0,

    unique(cvterm_id, type_id, value, rank) 
);

COMMENT ON TABLE cvtermprop IS 'Additional extensible properties can be attached to a cvterm using this table. Corresponds to -AnnotationProperty- in W3C OWL format';

COMMENT ON COLUMN cvtermprop.type_id IS 'The name of the property/slot is a cvterm. The meaning of the property is defined in that cvterm';

COMMENT ON COLUMN cvtermprop.value IS 'The value of the property, represented as text. Numeric values are converted to their text representation';

COMMENT ON COLUMN cvtermprop.rank IS 'Property-Value ordering. Any
cvterm can have multiple values for any particular property type -
these are ordered in a list using rank, counting from zero. For
properties that are single-valued rather than multi-valued, the
default 0 value should be used';

create index cvtermprop_idx1 on cvtermprop (cvterm_id);
create index cvtermprop_idx2 on cvtermprop (type_id);


create table dbxrefprop (
    dbxrefprop_id serial not null,
    primary key (dbxrefprop_id),
    dbxref_id int not null,
    foreign key (dbxref_id) references dbxref (dbxref_id) INITIALLY DEFERRED,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) INITIALLY DEFERRED,
    value text not null default '',
    rank int not null default 0,
    constraint dbxrefprop_c1 unique (dbxref_id,type_id,rank)
);

COMMENT ON TABLE dbxrefprop IS 'Metadata about a dbxref. Note that this is not defined in the dbxref module, as it depends on the cvterm table. This table has a structure analagous to cvtermprop';

create index dbxrefprop_idx1 on dbxrefprop (dbxref_id);
create index dbxrefprop_idx2 on dbxrefprop (type_id);

CREATE OR REPLACE VIEW cv_root AS
 SELECT 
  cv_id,
  cvterm_id AS root_cvterm_id
 FROM cvterm
 WHERE 
  cvterm_id NOT IN ( SELECT subject_id FROM cvterm_relationship)    AND
  is_obsolete=0;

COMMENT ON VIEW cv_root IS 'the roots of a cv are the set of terms
which have no parents (terms that are not the subject of a
relation). Most cvs will have a single root, some may have >1. All
will have at least 1';

CREATE OR REPLACE VIEW cv_leaf AS
 SELECT 
  cv_id,
  cvterm_id
 FROM cvterm
 WHERE 
  cvterm_id NOT IN ( SELECT object_id FROM cvterm_relationship);

COMMENT ON VIEW cv_leaf IS 'the leaves of a cv are the set of terms
which have no children (terms that are not the object of a
relation). All cvs will have at least 1 leaf';

CREATE OR REPLACE VIEW common_ancestor_cvterm AS
 SELECT
  p1.subject_id          AS cvterm1_id,
  p2.subject_id          AS cvterm2_id,
  p1.object_id           AS ancestor_cvterm_id,
  p1.pathdistance        AS pathdistance1,
  p2.pathdistance        AS pathdistance2,
  p1.pathdistance + p2.pathdistance
                         AS total_pathdistance
 FROM
  cvtermpath AS p1,
  cvtermpath AS p2
 WHERE 
  p1.object_id = p2.object_id;

COMMENT ON VIEW common_ancestor_cvterm IS 'The common ancestor of any
two terms is the intersection of both terms ancestors. Two terms can
have multiple common ancestors. Use total_pathdistance to get the
least common ancestor';

CREATE OR REPLACE VIEW common_descendant_cvterm AS
 SELECT
  p1.object_id           AS cvterm1_id,
  p2.object_id           AS cvterm2_id,
  p1.subject_id          AS ancestor_cvterm_id,
  p1.pathdistance        AS pathdistance1,
  p2.pathdistance        AS pathdistance2,
  p1.pathdistance + p2.pathdistance
                         AS total_pathdistance
 FROM
  cvtermpath AS p1,
  cvtermpath AS p2
 WHERE 
  p1.subject_id = p2.subject_id;

COMMENT ON VIEW common_descendant_cvterm IS 'The common descendant of
any two terms is the intersection of both terms descendants. Two terms
can have multiple common descendants. Use total_pathdistance to get
the least common ancestor';

CREATE OR REPLACE VIEW stats_paths_to_root AS
 SELECT 
  subject_id                            AS cvterm_id, 
  count(DISTINCT cvtermpath_id)         AS total_paths,
  avg(pathdistance)                     AS avg_distance,
  min(pathdistance)                     AS min_distance,
  max(pathdistance)                     AS max_distance
 FROM cvtermpath INNER JOIN cv_root ON (object_id=root_cvterm_id)
 GROUP BY cvterm_id;

COMMENT ON VIEW stats_paths_to_root IS 'per-cvterm statistics on its
placement in the DAG relative to the root. There may be multiple paths
from any term to the root. This gives the total number of paths, and
the average minimum and maximum distances. Here distance is defined by
cvtermpath.pathdistance';

CREATE OR REPLACE FUNCTION _get_all_subject_ids(integer) RETURNS SETOF cvtermpath AS
'
DECLARE
    root alias for $1;
    cterm cvtermpath%ROWTYPE;
    cterm2 cvtermpath%ROWTYPE;
BEGIN

    FOR cterm IN SELECT * FROM cvterm_relationship WHERE object_id = root LOOP
        RETURN NEXT cterm;
        FOR cterm2 IN SELECT * FROM _get_all_subject_ids(cterm.subject_id) LOOP
            RETURN NEXT cterm2;
        END LOOP;
    END LOOP;
    RETURN;
END;   
'
LANGUAGE 'plpgsql';

---arg: parent term id
---return: all children term id and their parent term id with relationship type id
CREATE OR REPLACE FUNCTION get_all_subject_ids(integer) RETURNS SETOF cvtermpath AS
'
DECLARE
    root alias for $1;
    cterm cvtermpath%ROWTYPE;
    exist_c int;
BEGIN

    SELECT INTO exist_c count(*) FROM cvtermpath WHERE object_id = root and pathdistance <= 0;
    IF (exist_c > 0) THEN
        FOR cterm IN SELECT * FROM cvtermpath WHERE object_id = root and pathdistance > 0 LOOP
            RETURN NEXT cterm;
        END LOOP;
    ELSE
        FOR cterm IN SELECT * FROM _get_all_subject_ids(root) LOOP
            RETURN NEXT cterm;
        END LOOP;
    END IF;
    RETURN;
END;   
'
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION get_graph_below(integer) RETURNS SETOF cvtermpath AS
'
DECLARE
    root alias for $1;
    cterm cvtermpath%ROWTYPE;
    cterm2 cvtermpath%ROWTYPE;

BEGIN

    FOR cterm IN SELECT * FROM cvterm_relationship WHERE object_id = root LOOP
        RETURN NEXT cterm;
        FOR cterm2 IN SELECT * FROM get_all_subject_ids(cterm.subject_id) LOOP
            RETURN NEXT cterm2;
        END LOOP;
    END LOOP;
    RETURN;
END;   
'
LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION get_graph_above(integer) RETURNS SETOF cvtermpath AS
'
DECLARE
    leaf alias for $1;
    cterm cvtermpath%ROWTYPE;
    cterm2 cvtermpath%ROWTYPE;

BEGIN

    FOR cterm IN SELECT * FROM cvterm_relationship WHERE subject_id = leaf LOOP
        RETURN NEXT cterm;
        FOR cterm2 IN SELECT * FROM get_all_object_ids(cterm.object_id) LOOP
            RETURN NEXT cterm2;
        END LOOP;
    END LOOP;
    RETURN;
END;   
'
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION _get_all_object_ids(integer) RETURNS SETOF cvtermpath AS
'
DECLARE
    leaf alias for $1;
    cterm cvtermpath%ROWTYPE;
    cterm2 cvtermpath%ROWTYPE;
BEGIN

    FOR cterm IN SELECT * FROM cvterm_relationship WHERE subject_id = leaf LOOP
        RETURN NEXT cterm;
        FOR cterm2 IN SELECT * FROM _get_all_object_ids(cterm.object_id) LOOP
            RETURN NEXT cterm2;
        END LOOP;
    END LOOP;
    RETURN;
END;   
'
LANGUAGE 'plpgsql';

---arg: child term id
---return: all parent term id and their childrent term id with relationship type id
CREATE OR REPLACE FUNCTION get_all_object_ids(integer) RETURNS SETOF cvtermpath AS
'
DECLARE
    leaf alias for $1;
    cterm cvtermpath%ROWTYPE;
    exist_c int;
BEGIN


    SELECT INTO exist_c count(*) FROM cvtermpath WHERE object_id = leaf and pathdistance <= 0;
    IF (exist_c > 0) THEN
        FOR cterm IN SELECT * FROM cvtermpath WHERE subject_id = leaf AND pathdistance > 0 LOOP
            RETURN NEXT cterm;
        END LOOP;
    ELSE
        FOR cterm IN SELECT * FROM _get_all_object_ids(leaf) LOOP
            RETURN NEXT cterm;
        END LOOP;
    END IF;
    RETURN;
END;   
'
LANGUAGE 'plpgsql';

---arg: sql statement which must be in the form of select cvterm_id from ...
---return: a set of cvterm ids that includes what is in sql statement and their children (subject ids)
CREATE OR REPLACE FUNCTION get_it_sub_cvterm_ids(text) RETURNS SETOF cvterm AS
'
DECLARE
    query alias for $1;
    cterm cvterm%ROWTYPE;
    cterm2 cvterm%ROWTYPE;
BEGIN
    FOR cterm IN EXECUTE query LOOP
        RETURN NEXT cterm;
        FOR cterm2 IN SELECT subject_id as cvterm_id FROM get_all_subject_ids(cterm.cvterm_id) LOOP
            RETURN NEXT cterm2;
        END LOOP;
    END LOOP;
    RETURN;
END;   
'
LANGUAGE 'plpgsql';
--- example: select * from fill_cvtermpath(7); where 7 is cv_id for an ontology
--- fill path from the node to its children and their children
CREATE OR REPLACE FUNCTION _fill_cvtermpath4node(INTEGER, INTEGER, INTEGER, INTEGER, INTEGER) RETURNS INTEGER AS
'
DECLARE
    origin alias for $1;
    child_id alias for $2;
    cvid alias for $3;
    typeid alias for $4;
    depth alias for $5;
    cterm cvterm_relationship%ROWTYPE;
    exist_c int;

BEGIN

    --- RAISE NOTICE ''depth=% root=%'', depth,child_id;
    --- not check type_id as it may be null and not very meaningful in cvtermpath when pathdistance > 1
    SELECT INTO exist_c count(*) FROM cvtermpath WHERE cv_id = cvid AND object_id = origin AND subject_id = child_id AND pathdistance = depth;

    IF (exist_c = 0) THEN
        INSERT INTO cvtermpath (object_id, subject_id, cv_id, type_id, pathdistance) VALUES(origin, child_id, cvid, typeid, depth);
    END IF;
    FOR cterm IN SELECT * FROM cvterm_relationship WHERE object_id = child_id LOOP
        PERFORM _fill_cvtermpath4node(origin, cterm.subject_id, cvid, cterm.type_id, depth+1);
    END LOOP;
    RETURN 1;
END;
'
LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION _fill_cvtermpath4root(INTEGER, INTEGER) RETURNS INTEGER AS
'
DECLARE
    rootid alias for $1;
    cvid alias for $2;
    ttype int;
    cterm cvterm_relationship%ROWTYPE;
    child cvterm_relationship%ROWTYPE;

BEGIN

    SELECT INTO ttype cvterm_id FROM cvterm WHERE (name = ''isa'' OR name = ''is_a'');
    PERFORM _fill_cvtermpath4node(rootid, rootid, cvid, ttype, 0);
    FOR cterm IN SELECT * FROM cvterm_relationship WHERE object_id = rootid LOOP
        PERFORM _fill_cvtermpath4root(cterm.subject_id, cvid);
        -- RAISE NOTICE ''DONE for term, %'', cterm.subject_id;
    END LOOP;
    RETURN 1;
END;
'
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION fill_cvtermpath(INTEGER) RETURNS INTEGER AS
'
DECLARE
    cvid alias for $1;
    root cvterm%ROWTYPE;

BEGIN

    DELETE FROM cvtermpath WHERE cv_id = cvid;

    FOR root IN SELECT DISTINCT t.* from cvterm t LEFT JOIN cvterm_relationship r ON (t.cvterm_id = r.subject_id) INNER JOIN cvterm_relationship r2 ON (t.cvterm_id = r2.object_id) WHERE t.cv_id = cvid AND r.subject_id is null LOOP
        PERFORM _fill_cvtermpath4root(root.cvterm_id, root.cv_id);
    END LOOP;
    RETURN 1;
END;   
'
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION fill_cvtermpath(cv.name%TYPE) RETURNS INTEGER AS
'
DECLARE
    cvname alias for $1;
    cv_id   int;
    rtn     int;
BEGIN

    SELECT INTO cv_id cv.cv_id from cv WHERE cv.name = cvname;
    SELECT INTO rtn fill_cvtermpath(cv_id);
    RETURN rtn;
END;   
'
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION _fill_cvtermpath4node2detect_cycle(INTEGER, INTEGER, INTEGER, INTEGER, INTEGER) RETURNS INTEGER AS
'
DECLARE
    origin alias for $1;
    child_id alias for $2;
    cvid alias for $3;
    typeid alias for $4;
    depth alias for $5;
    cterm cvterm_relationship%ROWTYPE;
    exist_c int;
    ccount  int;
    ecount  int;
    rtn     int;
BEGIN

    EXECUTE ''SELECT * FROM tmpcvtermpath p1, tmpcvtermpath p2 WHERE p1.subject_id=p2.object_id AND p1.object_id=p2.subject_id AND p1.object_id = ''|| origin || '' AND p2.subject_id = '' || child_id || ''AND '' || depth || ''> 0'';
    GET DIAGNOSTICS ccount = ROW_COUNT;
    IF (ccount > 0) THEN
        --RAISE EXCEPTION ''FOUND CYCLE: node % on cycle path'',origin;
        RETURN origin;
    END IF;

    EXECUTE ''SELECT * FROM tmpcvtermpath WHERE cv_id = '' || cvid || '' AND object_id = '' || origin || '' AND subject_id = '' || child_id || '' AND '' || origin || ''<>'' || child_id;
    GET DIAGNOSTICS ecount = ROW_COUNT;
    IF (ecount > 0) THEN
        --RAISE NOTICE ''FOUND TWICE (node), will check root obj % subj %'',origin, child_id;
        SELECT INTO rtn _fill_cvtermpath4root2detect_cycle(child_id, cvid);
        IF (rtn > 0) THEN
            RETURN rtn;
        END IF;
    END IF;

    EXECUTE ''SELECT * FROM tmpcvtermpath WHERE cv_id = '' || cvid || '' AND object_id = '' || origin || '' AND subject_id = '' || child_id || '' AND pathdistance = '' || depth;
    GET DIAGNOSTICS exist_c = ROW_COUNT;
    IF (exist_c = 0) THEN
        EXECUTE ''INSERT INTO tmpcvtermpath (object_id, subject_id, cv_id, type_id, pathdistance) VALUES('' || origin || '', '' || child_id || '', '' || cvid || '', '' || typeid || '', '' || depth || '')'';
    END IF;

    FOR cterm IN SELECT * FROM cvterm_relationship WHERE object_id = child_id LOOP
        --RAISE NOTICE ''DOING for node, % %'', origin, cterm.subject_id;
        SELECT INTO rtn _fill_cvtermpath4node2detect_cycle(origin, cterm.subject_id, cvid, cterm.type_id, depth+1);
        IF (rtn > 0) THEN
            RETURN rtn;
        END IF;
    END LOOP;
    RETURN 0;
END;
'
LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION _fill_cvtermpath4root2detect_cycle(INTEGER, INTEGER) RETURNS INTEGER AS
'
DECLARE
    rootid alias for $1;
    cvid alias for $2;
    ttype int;
    ccount int;
    cterm cvterm_relationship%ROWTYPE;
    child cvterm_relationship%ROWTYPE;
    rtn     int;
BEGIN

    SELECT INTO ttype cvterm_id FROM cvterm WHERE (name = ''isa'' OR name = ''is_a'');
    SELECT INTO rtn _fill_cvtermpath4node2detect_cycle(rootid, rootid, cvid, ttype, 0);
    IF (rtn > 0) THEN
        RETURN rtn;
    END IF;
    FOR cterm IN SELECT * FROM cvterm_relationship WHERE object_id = rootid LOOP
        EXECUTE ''SELECT * FROM tmpcvtermpath p1, tmpcvtermpath p2 WHERE p1.subject_id=p2.object_id AND p1.object_id=p2.subject_id AND p1.object_id='' || rootid || '' AND p1.subject_id='' || cterm.subject_id;
        GET DIAGNOSTICS ccount = ROW_COUNT;
        IF (ccount > 0) THEN
            --RAISE NOTICE ''FOUND TWICE (root), will check root obj % subj %'',rootid,cterm.subject_id;
            SELECT INTO rtn _fill_cvtermpath4node2detect_cycle(rootid, cterm.subject_id, cvid, ttype, 0);
            IF (rtn > 0) THEN
                RETURN rtn;
            END IF;
        ELSE
            SELECT INTO rtn _fill_cvtermpath4root2detect_cycle(cterm.subject_id, cvid);
            IF (rtn > 0) THEN
                RETURN rtn;
            END IF;
        END IF;
    END LOOP;
    RETURN 0;
END;
'
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION get_cycle_cvterm_id(INTEGER, INTEGER) RETURNS INTEGER AS
'
DECLARE
    cvid alias for $1;
    rootid alias for $2;
    rtn     int;
BEGIN

    CREATE TEMP TABLE tmpcvtermpath(object_id int, subject_id int, cv_id int, type_id int, pathdistance int);
    CREATE INDEX tmp_cvtpath1 ON tmpcvtermpath(object_id, subject_id);

    SELECT INTO rtn _fill_cvtermpath4root2detect_cycle(rootid, cvid);
    IF (rtn > 0) THEN
        DROP TABLE tmpcvtermpath;
        RETURN rtn;
    END IF;
    DROP TABLE tmpcvtermpath;
    RETURN 0;
END;   
'
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION get_cycle_cvterm_ids(INTEGER) RETURNS SETOF INTEGER AS
'
DECLARE
    cvid alias for $1;
    root cvterm%ROWTYPE;
    rtn     int;
BEGIN


    FOR root IN SELECT DISTINCT t.* from cvterm t WHERE cv_id = cvid LOOP
        SELECT INTO rtn get_cycle_cvterm_id(cvid,root.cvterm_id);
        IF (rtn > 0) THEN
            RETURN NEXT rtn;
        END IF;
    END LOOP;
    RETURN;
END;   
'
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION get_cycle_cvterm_id(INTEGER) RETURNS INTEGER AS
'
DECLARE
    cvid alias for $1;
    root cvterm%ROWTYPE;
    rtn     int;
BEGIN

    CREATE TEMP TABLE tmpcvtermpath(object_id int, subject_id int, cv_id int, type_id int, pathdistance int);
    CREATE INDEX tmp_cvtpath1 ON tmpcvtermpath(object_id, subject_id);

    FOR root IN SELECT DISTINCT t.* from cvterm t LEFT JOIN cvterm_relationship r ON (t.cvterm_id = r.subject_id) INNER JOIN cvterm_relationship r2 ON (t.cvterm_id = r2.object_id) WHERE t.cv_id = cvid AND r.subject_id is null LOOP
        SELECT INTO rtn _fill_cvtermpath4root2detect_cycle(root.cvterm_id, root.cv_id);
        IF (rtn > 0) THEN
            DROP TABLE tmpcvtermpath;
            RETURN rtn;
        END IF;
    END LOOP;
    DROP TABLE tmpcvtermpath;
    RETURN 0;
END;   
'
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION get_cycle_cvterm_id(cv.name%TYPE) RETURNS INTEGER AS
'
DECLARE
    cvname alias for $1;
    cv_id int;
    rtn int;
BEGIN

    SELECT INTO cv_id cv.cv_id from cv WHERE cv.name = cvname;
    SELECT INTO rtn  get_cycle_cvterm_id(cv_id);

    RETURN rtn;
END;   
'
LANGUAGE 'plpgsql';

create table organism (
	organism_id serial not null,
	primary key (organism_id),
	abbreviation varchar(255) null,
	genus varchar(255) not null,
	species varchar(255) not null,
	common_name varchar(255) null,
	comment text null,
    constraint organism_c1 unique (genus,species)
);

COMMENT ON TABLE organism IS 'The organismal taxonomic
classification. Note that phylogenies are represented using the
phylogeny module, and taxonomies can be represented using the cvterm
module or the phylogeny module';

COMMENT ON COLUMN organism.species IS 'A type of organism is always
uniquely identified by genus+species. When mapping from the NCBI
taxonomy names.dmp file, the unique-name column must be used where it
is present, as the name column is not always unique (eg environmental
samples). If a particular strain or subspecies is to be represented,
this is appended onto the species name. Follows standard NCBI taxonomy
pattern';

create table organism_dbxref (
    organism_dbxref_id serial not null,
    primary key (organism_dbxref_id),
    organism_id int not null,
    foreign key (organism_id) references organism (organism_id) on delete cascade INITIALLY DEFERRED,
    dbxref_id int not null,
    foreign key (dbxref_id) references dbxref (dbxref_id) on delete cascade INITIALLY DEFERRED,
    constraint organism_dbxref_c1 unique (organism_id,dbxref_id)
);
create index organism_dbxref_idx1 on organism_dbxref (organism_id);
create index organism_dbxref_idx2 on organism_dbxref (dbxref_id);

create table organismprop (
    organismprop_id serial not null,
    primary key (organismprop_id),
    organism_id int not null,
    foreign key (organism_id) references organism (organism_id) on delete cascade INITIALLY DEFERRED,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    value text null,
    rank int not null default 0,
    constraint organismprop_c1 unique (organism_id,type_id,rank)
);
create index organismprop_idx1 on organismprop (organism_id);
create index organismprop_idx2 on organismprop (type_id);

COMMENT ON TABLE organismprop IS 'tag-value properties - follows standard chado model';


CREATE OR REPLACE FUNCTION get_organism_id(VARCHAR,VARCHAR) RETURNS INT
 AS '
  SELECT organism_id 
  FROM organism
  WHERE genus=$1
    AND species=$2
 ' LANGUAGE 'sql';

CREATE OR REPLACE FUNCTION get_organism_id(VARCHAR) RETURNS INT
 AS ' 
SELECT organism_id
  FROM organism
  WHERE genus=substring($1,1,position('' '' IN $1)-1)
    AND species=substring($1,position('' '' IN $1)+1)
 ' LANGUAGE 'sql';

CREATE OR REPLACE FUNCTION get_organism_id_abbrev(VARCHAR) RETURNS INT
 AS '
SELECT organism_id
  FROM organism
  WHERE substr(genus,1,1)=substring($1,1,1)
    AND species=substring($1,position('' '' IN $1)+1)
 ' LANGUAGE 'sql';

CREATE OR REPLACE FUNCTION store_organism (VARCHAR,VARCHAR,VARCHAR) 
  RETURNS INT AS 
'DECLARE
   v_genus            ALIAS FOR $1;
   v_species          ALIAS FOR $2;
   v_common_name      ALIAS FOR $3;

   v_organism_id      INTEGER;
 BEGIN
    SELECT INTO v_organism_id organism_id
      FROM organism
      WHERE genus=v_genus               AND
            species=v_species;
    IF NOT FOUND THEN
      INSERT INTO organism
       (genus,species,common_name)
         VALUES
       (v_genus,v_species,v_common_name);
       RETURN currval(''organism_organism_id_seq'');
    ELSE
      UPDATE organism
       SET common_name=v_common_name
      WHERE organism_id = v_organism_id;
    END IF;
    RETURN v_organism_id;
 END;
' LANGUAGE 'plpgsql';
  

create table pub (
    pub_id serial not null,
    primary key (pub_id),
    title text,
    volumetitle text,
    volume varchar(255),
    series_name varchar(255),
    issue varchar(255),
    pyear varchar(255),
    pages varchar(255),
    miniref varchar(255),
    uniquename text not null,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    is_obsolete boolean default 'false',
    publisher varchar(255),
    pubplace varchar(255),
    constraint pub_c1 unique (uniquename)
);

COMMENT ON TABLE pub IS 'A documented provenance artefact - publications,
documents, personal communication';

COMMENT ON COLUMN pub.title IS 'descriptive general heading';
COMMENT ON COLUMN pub.volumetitle IS 'title of part if one of a series';
COMMENT ON COLUMN pub.series_name IS 'full name of (journal) series';
COMMENT ON COLUMN pub.pages IS 'page number range[s], eg, 457--459, viii + 664pp, lv--lvii';
COMMENT ON COLUMN pub.type_id IS  'the type of the publication (book, journal, poem, graffiti, etc). Uses pub cv';
CREATE INDEX pub_idx1 ON pub (type_id);

create table pub_relationship (
    pub_relationship_id serial not null,
    primary key (pub_relationship_id),
    subject_id int not null,
    foreign key (subject_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
    object_id int not null,
    foreign key (object_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,

    constraint pub_relationship_c1 unique (subject_id,object_id,type_id)
);
COMMENT ON TABLE pub_relationship IS 'Handle relationships between
publications, eg, when one publication makes others obsolete, when one
publication contains errata with respect to other publication(s), or
when one publication also appears in another pub (I think these three
are it - at least for fb)';


create index pub_relationship_idx1 on pub_relationship (subject_id);
create index pub_relationship_idx2 on pub_relationship (object_id);
create index pub_relationship_idx3 on pub_relationship (type_id);

create table pub_dbxref (
    pub_dbxref_id serial not null,
    primary key (pub_dbxref_id),
    pub_id int not null,
    foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
    dbxref_id int not null,
    foreign key (dbxref_id) references dbxref (dbxref_id) on delete cascade INITIALLY DEFERRED,
    is_current boolean not null default 'true',
    constraint pub_dbxref_c1 unique (pub_id,dbxref_id)
);
create index pub_dbxref_idx1 on pub_dbxref (pub_id);
create index pub_dbxref_idx2 on pub_dbxref (dbxref_id);

COMMENT ON TABLE pub_dbxref IS 'Handle links to eg, pubmed, biosis,
zoorec, OCLC, mdeline, ISSN, coden...';



create table pubauthor (
    pubauthor_id serial not null,
    primary key (pubauthor_id),
    pub_id int not null,
    foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
    rank int not null,
    editor boolean default 'false',
    surname varchar(100) not null,
    givennames varchar(100),
    suffix varchar(100),

    constraint pubauthor_c1 unique (pub_id, rank)
);

COMMENT ON TABLE pubauthor IS 'an author for a publication. Note the denormalisation (hence lack of _ in table name) - this is deliberate as it is in general too hard to assign IDs to authors.';

COMMENT ON COLUMN pubauthor.givennames IS 'first name, initials';
COMMENT ON COLUMN pubauthor.suffix IS 'Jr., Sr., etc';
COMMENT ON COLUMN pubauthor.rank IS 'order of author in author list for this pub - order is important';

COMMENT ON COLUMN pubauthor.editor IS 'indicates whether the author is an editor for linked publication. Note: this is a boolean field but does not follow the normal chado convention for naming booleans';

create index pubauthor_idx2 on pubauthor (pub_id);

create table pubprop (
    pubprop_id serial not null,
    primary key (pubprop_id),
    pub_id int not null,
    foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    value text not null,
    rank integer,

    constraint pubprop_c1 unique (pub_id,type_id,rank)
);

COMMENT ON TABLE pubprop IS 'Property-value pairs for a pub. Follows standard chado pattern - see sequence module for details';

create index pubprop_idx1 on pubprop (pub_id);
create index pubprop_idx2 on pubprop (type_id);

create table feature (
    feature_id serial not null,
    primary key (feature_id),
    dbxref_id int,
    foreign key (dbxref_id) references dbxref (dbxref_id) on delete set null INITIALLY DEFERRED,
    organism_id int not null,
    foreign key (organism_id) references organism (organism_id) on delete cascade INITIALLY DEFERRED,
    name varchar(255),
    uniquename text not null,
    residues text,
    seqlen int,
    md5checksum char(32),
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    is_analysis boolean not null default 'false',
    is_obsolete boolean not null default 'false',
    timeaccessioned timestamp not null default current_timestamp,
    timelastmodified timestamp not null default current_timestamp,
    constraint feature_c1 unique (organism_id,uniquename,type_id)
);

COMMENT ON TABLE feature IS 'A feature is a biological sequence or a
section of a biological sequence, or a collection of such
sections. Examples include genes, exons, transcripts, regulatory
regions, polypeptides, protein domains, chromosome sequences, sequence
variations, cross-genome match regions such as hits and HSPs and so
on; see the Sequence Ontology for more';

COMMENT ON COLUMN feature.dbxref_id IS 'An optional primary public stable
identifier for this feature. Secondary identifiers and external
dbxrefs go in table:feature_dbxref';

COMMENT ON COLUMN feature.organism_id IS 'The organism to which this feature
belongs. This column is mandatory';

COMMENT ON COLUMN feature.name IS 'The optional human-readable common name for
a feature, for display purposes';

COMMENT ON COLUMN feature.uniquename IS 'The unique name for a feature; may
not be necessarily be particularly human-readable, although this is
prefered. This name must be unique for this type of feature within
this organism';

COMMENT ON COLUMN feature.residues IS 'A sequence of alphabetic characters
representing biological residues (nucleic acids, amino acids). This
column does not need to be manifested for all features; it is optional
for features such as exons where the residues can be derived from the
featureloc. It is recommended that the value for this column be
manifested for features which may may non-contiguous sublocations (eg
transcripts), since derivation at query time is non-trivial. For
expressed sequence, the DNA sequence should be used rather than the
RNA sequence';

COMMENT ON COLUMN feature.seqlen IS 'The length of the residue feature. See
column:residues. This column is partially redundant with the residues
column, and also with featureloc. This column is required because the
location may be unknown and the residue sequence may not be
manifested, yet it may be desirable to store and query the length of
the feature. The seqlen should always be manifested where the length
of the sequence is known';

COMMENT ON COLUMN feature.md5checksum IS 'The 32-character checksum of the sequence,
calculated using the MD5 algorithm. This is practically guaranteed to
be unique for any feature. This column thus acts as a unique
identifier on the mathematical sequence';

COMMENT ON COLUMN feature.type_id IS 'A required reference to a table:cvterm
giving the feature type. This will typically be a Sequence Ontology
identifier. This column is thus used to subclass the feature table';

COMMENT ON COLUMN feature.is_analysis IS 'Boolean indicating whether this
feature is annotated or the result of an automated analysis. Analysis
results also use the companalysis module. Note that the dividing line
between analysis/annotation may be fuzzy, this should be determined on
a per-project basis in a consistent manner. One requirement is that
there should only be one non-analysis version of each wild-type gene
feature in a genome, whereas the same gene feature can be predicted
multiple times in different analyses';

COMMENT ON COLUMN feature.is_obsolete IS 'Boolean indicating whether this
feature has been obsoleted. Some chado instances may choose to simply
remove the feature altogether, others may choose to keep an obsolete
row in the table';

COMMENT ON COLUMN feature.timeaccessioned IS 'for handling object
accession/modification timestamps (as opposed to db auditing info,
handled elsewhere). The expectation is that these fields would be
available to software interacting with chado';

COMMENT ON COLUMN feature.timelastmodified IS 'for handling object
accession/modification timestamps (as opposed to db auditing info,
handled elsewhere). The expectation is that these fields would be
available to software interacting with chado';

--- COMMENT ON INDEX feature_c1 IS 'Any feature can be globally identified
--- by the combination of organism, uniquename and feature type';

create sequence feature_uniquename_seq;
create index feature_name_ind1 on feature(name);
create index feature_idx1 on feature (dbxref_id);
create index feature_idx2 on feature (organism_id);
create index feature_idx3 on feature (type_id);
create index feature_idx4 on feature (uniquename);
create index feature_idx5 on feature (lower(name));


create table featureloc (
    featureloc_id serial not null,
    primary key (featureloc_id),
    feature_id int not null,
    foreign key (feature_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,
    srcfeature_id int,
    foreign key (srcfeature_id) references feature (feature_id) on delete set null INITIALLY DEFERRED,
    fmin int,
    is_fmin_partial boolean not null default 'false',
    fmax int,
    is_fmax_partial boolean not null default 'false',
    strand smallint,
    phase int,
    residue_info text,
    locgroup int not null default 0,
    rank int not null default 0,
    constraint featureloc_c1 unique (feature_id,locgroup,rank),
    constraint featureloc_c2 check (fmin <= fmax)
);

COMMENT ON TABLE featureloc IS 'The location of a feature relative to
another feature.  IMPORTANT: INTERBASE COORDINATES ARE USED.(This is
vital as it allows us to represent zero-length features eg splice
sites, insertion points without an awkward fuzzy system). Features
typically have exactly ONE location, but this need not be the
case. Some features may not be localized (eg a gene that has been
characterized genetically but no sequence/molecular info is
available). NOTE ON MULTIPLE LOCATIONS: Each feature can have 0 or
more locations. Multiple locations do NOT indicate non-contiguous
locations (if a feature such as a transcript has a non-contiguous
location, then the subfeatures such as exons should always be
manifested). Instead, multiple featurelocs for a feature designate
alternate locations or grouped locations; for instance, a feature
designating a blast hit or hsp will have two locations, one on the
query feature, one on the subject feature.  features representing
sequence variation could have alternate locations instantiated on a
feature on the mutant strain.  the column:rank is used to
differentiate these different locations. Reflexive locations should
never be stored - this is for -proper- (ie non-self) locations only;
i.e. nothing should be located relative to itself';

COMMENT ON COLUMN featureloc.feature_id IS 'The feature that is being located. Any feature can have zero or more featurelocs';

COMMENT ON COLUMN featureloc.srcfeature_id IS 'The source feature which this location is relative to. Every location is relative to another feature (however, this column is nullable, because the srcfeature may not be known). All locations are -proper- that is, nothing should be located relative to itself. No cycles are allowed in the featureloc graph';

COMMENT ON COLUMN featureloc.fmin IS 'The leftmost/minimal boundary in the linear range represented by the featureloc. Sometimes (eg in bioperl) this is called -start- although this is confusing because it does not necessarily represent the 5-prime coordinate. IMPORTANT: This is space-based (INTERBASE) coordinates, counting from zero. To convert this to the leftmost position in a base-oriented system (eg GFF, bioperl), add 1 to fmin';

COMMENT ON COLUMN featureloc.fmax IS 'The rightmost/maximal boundary in the linear range represented by the featureloc. Sometimes (eg in bioperl) this is called -end- although this is confusing because it does not necessarily represent the 3-prime coordinate. IMPORTANT: This is space-based (INTERBASE) coordinates, counting from zero. No conversion is required to go from fmax to the rightmost coordinate in a base-oriented system that counts from 1 (eg GFF, bioperl)';

COMMENT ON COLUMN featureloc.strand IS 'The orientation/directionality of the
location. Should be 0,-1 or +1';

COMMENT ON COLUMN featureloc.rank IS 'Used when a feature has >1
location, otherwise the default rank 0 is used. Some features (eg
blast hits and HSPs) have two locations - one on the query and one on
the subject. Rank is used to differentiate these. Rank=0 is always
used for the query, Rank=1 for the subject. For multiple alignments,
assignment of rank is arbitrary. Rank is also used for
sequence_variant features, such as SNPs. Rank=0 indicates the wildtype
(or baseline) feature, Rank=1 indicates the mutant (or compared) feature';

COMMENT ON COLUMN featureloc.locgroup IS 'This is used to manifest redundant,
derivable extra locations for a feature. The default locgroup=0 is
used for the DIRECT location of a feature. !! MOST CHADO USERS MAY
NEVER USE featurelocs WITH logroup>0 !! Transitively derived locations
are indicated with locgroup>0. For example, the position of an exon on
a BAC and in global chromosome coordinates. This column is used to
differentiate these groupings of locations. the default locgroup 0
is used for the main/primary location, from which the others can be
derived via coordinate transformations. another example of redundant
locations is storing ORF coordinates relative to both transcript and
genome. redundant locations open the possibility of the database
getting into inconsistent states; this schema gives us the flexibility
of both warehouse instantiations with redundant locations (easier for
querying) and management instantiations with no redundant
locations. An example of using both locgroup and rank: imagine a
feature indicating a conserved region between the chromosomes of two
different species. we may want to keep redundant locations on both
contigs and chromosomes. we would thus have 4 locations for the single
conserved region feature - two distinct locgroups (contig level and
chromosome level) and two distinct ranks (for the two species)';

COMMENT ON COLUMN featureloc.residue_info IS 'Alternative residues,
when these differ from feature.residues. for instance, a SNP feature
located on a wild and mutant protein would have different alresidues.
for alignment/similarity features, the altresidues is used to
represent the alignment string (CIGAR format). Note on variation
features; even if we dont want to instantiate a mutant
chromosome/contig feature, we can still represent a SNP etc with 2
locations, one (rank 0) on the genome, the other (rank 1) would have
most fields null, except for altresidues';

COMMENT ON COLUMN featureloc.phase IS 'phase of translation wrt srcfeature_id.
Values are 0,1,2. It may not be possible to manifest this column for
some features such as exons, because the phase is dependant on the
spliceform (the same exon can appear in multiple spliceforms). This column is mostly useful for predicted exons and CDSs';

COMMENT ON COLUMN featureloc.is_fmin_partial IS 'This is typically
false, but may be true if the value for column:fmin is inaccurate or
the leftmost part of the range is unknown/unbounded';

COMMENT ON COLUMN featureloc.is_fmax_partial IS 'This is typically
false, but may be true if the value for column:fmax is inaccurate or
the rightmost part of the range is unknown/unbounded';

--- COMMENT ON INDEX featureloc_c1 IS 'locgroup and rank serve to uniquely
--- partition locations for any one feature';


create index featureloc_idx1 on featureloc (feature_id);
create index featureloc_idx2 on featureloc (srcfeature_id);
create index featureloc_idx3 on featureloc (srcfeature_id,fmin,fmax);

--

create table featureloc_pub (
    featureloc_pub_id serial not null,
    primary key (featureloc_pub_id),
    featureloc_id int not null,
    foreign key (featureloc_id) references featureloc (featureloc_id) on delete cascade INITIALLY DEFERRED,
    pub_id int not null,
    foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
    constraint featureloc_pub_c1 unique (featureloc_id,pub_id)
);
COMMENT ON TABLE featureloc_pub IS 'Provenance of featureloc. Linking table between featurelocs and publications that mention them';

create index featureloc_pub_idx1 on featureloc_pub (featureloc_id);
create index featureloc_pub_idx2 on featureloc_pub (pub_id);

--

create table feature_pub (
    feature_pub_id serial not null,
    primary key (feature_pub_id),
    feature_id int not null,
    foreign key (feature_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,
    pub_id int not null,
    foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
    constraint feature_pub_c1 unique (feature_id,pub_id)
);
COMMENT ON TABLE feature_pub IS 'Provenance. Linking table between features and publications that mention them';

create index feature_pub_idx1 on feature_pub (feature_id);
create index feature_pub_idx2 on feature_pub (pub_id);

--

create table featureprop (
    featureprop_id serial not null,
    primary key (featureprop_id),
    feature_id int not null,
    foreign key (feature_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    value text null,
    rank int not null default 0,
    constraint featureprop_c1 unique (feature_id,type_id,rank)
);
COMMENT ON TABLE featureprop IS 'A feature can have any number of slot-value property tags attached to it. This is an alternative to hardcoding a list of columns in the relational schema, and is completely extensible';

COMMENT ON COLUMN featureprop.type_id IS 'The name of the
property/slot is a cvterm. The meaning of the property is defined in
that cvterm. Certain property types will only apply to certain feature
types (e.g. the anticodon property will only apply to tRNA features) ;
the types here come from the sequence feature property ontology';

COMMENT ON COLUMN featureprop.value IS 'The value of the property, represented as text. Numeric values are converted to their text representation. This is less efficient than using native database types, but is easier to query.';

COMMENT ON COLUMN featureprop.rank IS 'Property-Value ordering. Any
feature can have multiple values for any particular property type -
these are ordered in a list using rank, counting from zero. For
properties that are single-valued rather than multi-valued, the
default 0 value should be used';

COMMENT ON INDEX featureprop_c1 IS 'for any one feature, multivalued
property-value pairs must be differentiated by rank';

create index featureprop_idx1 on featureprop (feature_id);
create index featureprop_idx2 on featureprop (type_id);

--

create table featureprop_pub (
    featureprop_pub_id serial not null,
    primary key (featureprop_pub_id),
    featureprop_id int not null,
    foreign key (featureprop_id) references featureprop (featureprop_id) on delete cascade INITIALLY DEFERRED,
    pub_id int not null,
    foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
    constraint featureprop_pub_c1 unique (featureprop_id,pub_id)
);

COMMENT ON TABLE featureprop_pub IS 'Provenance. Any featureprop assignment can optionally be supported by a publication';

create index featureprop_pub_idx1 on featureprop_pub (featureprop_id);
create index featureprop_pub_idx2 on featureprop_pub (pub_id);


create table feature_dbxref (
    feature_dbxref_id serial not null,
    primary key (feature_dbxref_id),
    feature_id int not null,
    foreign key (feature_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,
    dbxref_id int not null,
    foreign key (dbxref_id) references dbxref (dbxref_id) on delete cascade INITIALLY DEFERRED,
    is_current boolean not null default 'true',
    constraint feature_dbxref_c1 unique (feature_id,dbxref_id)
);

COMMENT ON TABLE feature_dbxref IS 'links a feature to dbxrefs. This is for secondary identifiers; primary identifiers should use feature.dbxref_id';

COMMENT ON COLUMN feature_dbxref.is_current IS 'the is_current boolean indicates whether the linked dbxref is the  current -official- dbxref for the linked feature';

create index feature_dbxref_idx1 on feature_dbxref (feature_id);
create index feature_dbxref_idx2 on feature_dbxref (dbxref_id);

--

create table feature_relationship (
    feature_relationship_id serial not null,
    primary key (feature_relationship_id),
    subject_id int not null,
    foreign key (subject_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,
    object_id int not null,
    foreign key (object_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    value text null,
    rank int not null default 0,
    constraint feature_relationship_c1 unique (subject_id,object_id,type_id,rank)
);

COMMENT ON TABLE feature_relationship IS 'features can be arranged in
graphs, eg exon part_of transcript part_of gene; translation madeby
transcript if type is thought of as a verb, each arc makes a statement
[SUBJECT VERB OBJECT] object can also be thought of as parent
(containing feature), and subject as child (contained feature or
subfeature) -- we include the relationship rank/order, because even
though most of the time we can order things implicitly by sequence
coordinates, we cant always do this - eg transpliced genes.  its also
useful for quickly getting implicit introns';

COMMENT ON COLUMN feature_relationship.subject_id IS 'the subject of the subj-predicate-obj sentence. This is typically the subfeature';

COMMENT ON COLUMN feature_relationship.object_id IS 'the object of the subj-predicate-obj sentence. This is typically the container feature';

COMMENT ON COLUMN feature_relationship.type_id IS 'relationship type between subject and object. This is a cvterm, typically from the OBO relationship ontology, although other relationship types are allowed. The most common relationship type is OBO_REL:part_of. Valid relationship types are constrained by the Sequence Ontology';

COMMENT ON COLUMN feature_relationship.rank IS 'The ordering of subject features with respect to the object feature may be important (for example, exon ordering on a transcript - not always derivable if you take trans spliced genes into consideration). rank is used to order these; starts from zero';

COMMENT ON COLUMN feature_relationship.value IS 'Additional notes/comments';

create index feature_relationship_idx1 on feature_relationship (subject_id);
create index feature_relationship_idx2 on feature_relationship (object_id);
create index feature_relationship_idx3 on feature_relationship (type_id);

--
 
create table feature_relationship_pub (
	feature_relationship_pub_id serial not null,
	primary key (feature_relationship_pub_id),
	feature_relationship_id int not null,
	foreign key (feature_relationship_id) references feature_relationship (feature_relationship_id) on delete cascade INITIALLY DEFERRED,
	pub_id int not null,
	foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
    constraint feature_relationship_pub_c1 unique (feature_relationship_id,pub_id)
);

COMMENT ON TABLE feature_relationship_pub IS 'Provenance. Attach optional evidence to a feature_relationship in the form of a publication';

create index feature_relationship_pub_idx1 on feature_relationship_pub (feature_relationship_id);
create index feature_relationship_pub_idx2 on feature_relationship_pub (pub_id);
 
--

create table feature_relationshipprop (
    feature_relationshipprop_id serial not null,
    primary key (feature_relationshipprop_id),
    feature_relationship_id int not null,
    foreign key (feature_relationship_id) references feature_relationship (feature_relationship_id) on delete cascade,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    value text null,
    rank int not null default 0,
    constraint feature_relationshipprop_c1 unique (feature_relationship_id,type_id,rank)
);

COMMENT ON TABLE feature_relationshipprop IS 'Extensible properties
for feature_relationships. Analagous structure to featureprop. This
table is largely optional and not used with a high frequency. Typical
scenarios may be if one wishes to attach additional data to a
feature_relationship - for example to say that the
feature_relationship is only true in certain contexts';

COMMENT ON COLUMN feature_relationshipprop.type_id IS 'The name of the
property/slot is a cvterm. The meaning of the property is defined in
that cvterm. Currently there is no standard ontology for
feature_relationship property types';

COMMENT ON COLUMN feature_relationshipprop.value IS 'The value of the
property, represented as text. Numeric values are converted to their
text representation. This is less efficient than using native database
types, but is easier to query.';

COMMENT ON COLUMN feature_relationshipprop.rank IS 'Property-Value
ordering. Any feature_relationship can have multiple values for any particular
property type - these are ordered in a list using rank, counting from
zero. For properties that are single-valued rather than multi-valued,
the default 0 value should be used';


create index feature_relationshipprop_idx1 on feature_relationshipprop (feature_relationship_id);
create index feature_relationshipprop_idx2 on feature_relationshipprop (type_id);

--

create table feature_relationshipprop_pub (
    feature_relationshipprop_pub_id serial not null,
    primary key (feature_relationshipprop_pub_id),
    feature_relationshipprop_id int not null,
    foreign key (feature_relationshipprop_id) references feature_relationshipprop (feature_relationshipprop_id) on delete cascade INITIALLY DEFERRED,
    pub_id int not null,
    foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
    constraint feature_relationshipprop_pub_c1 unique (feature_relationshipprop_id,pub_id)
);
create index feature_relationshipprop_pub_idx1 on feature_relationshipprop_pub (feature_relationshipprop_id);
create index feature_relationshipprop_pub_idx2 on feature_relationshipprop_pub (pub_id);

COMMENT ON TABLE feature_relationshipprop_pub IS 'Provenance for feature_relationshipprop';

--

create table feature_cvterm (
    feature_cvterm_id serial not null,
    primary key (feature_cvterm_id),
    feature_id int not null,
    foreign key (feature_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,
    cvterm_id int not null,
    foreign key (cvterm_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    pub_id int not null,
    foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
    is_not boolean not null default false,
    constraint feature_cvterm_c1 unique (feature_id,cvterm_id,pub_id)
);

COMMENT ON TABLE feature_cvterm IS 'Associate a term from a cv with a feature, for example, GO annotation';

COMMENT ON COLUMN feature_cvterm.pub_id IS 'Provenance for the annotation. Each annotation should have a single primary publication (which may be of the appropriate type for computational analyses) where more details can be found. Additional provenance dbxrefs can be attached using feature_cvterm_dbxref';

COMMENT ON COLUMN feature_cvterm.is_not IS 'if this is set to true, then this annotation is interpreted as a NEGATIVE annotation - ie the feature does NOT have the specified function, process, component, part, etc. See GO docs for more details';

create index feature_cvterm_idx1 on feature_cvterm (feature_id);
create index feature_cvterm_idx2 on feature_cvterm (cvterm_id);
create index feature_cvterm_idx3 on feature_cvterm (pub_id);

--

create table feature_cvtermprop (
    feature_cvtermprop_id serial not null,
    primary key (feature_cvtermprop_id),
    feature_cvterm_id int not null,
    foreign key (feature_cvterm_id) references feature_cvterm (feature_cvterm_id) on delete cascade,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    value text null,
    rank int not null default 0,
    constraint feature_cvtermprop_c1 unique (feature_cvterm_id,type_id,rank)
);

COMMENT ON TABLE feature_cvtermprop IS 'Extensible properties for
feature to cvterm associations. Examples: GO evidence codes;
qualifiers; metadata such as the date on which the entry was curated
and the source of the association. See the featureprop table for
meanings of type_id, value and rank';

COMMENT ON COLUMN feature_cvtermprop.type_id IS 'The name of the
property/slot is a cvterm. The meaning of the property is defined in
that cvterm. cvterms may come from the OBO evidence code cv';

COMMENT ON COLUMN feature_cvtermprop.value IS 'The value of the
property, represented as text. Numeric values are converted to their
text representation. This is less efficient than using native database
types, but is easier to query.';

COMMENT ON COLUMN feature_cvtermprop.rank IS 'Property-Value
ordering. Any feature_cvterm can have multiple values for any particular
property type - these are ordered in a list using rank, counting from
zero. For properties that are single-valued rather than multi-valued,
the default 0 value should be used';

create index feature_cvtermprop_idx1 on feature_cvtermprop (feature_cvterm_id);
create index feature_cvtermprop_idx2 on feature_cvtermprop (type_id);

--

create table feature_cvterm_dbxref (
    feature_cvterm_dbxref_id serial not null,
    primary key (feature_cvterm_dbxref_id),
    feature_cvterm_id int not null,
    foreign key (feature_cvterm_id) references feature_cvterm (feature_cvterm_id) on delete cascade,
    dbxref_id int not null,
    foreign key (dbxref_id) references dbxref (dbxref_id) on delete cascade INITIALLY DEFERRED,
    constraint feature_cvterm_dbxref_c1 unique (feature_cvterm_id,dbxref_id)
);
create index feature_cvterm_dbxref_idx1 on feature_cvterm_dbxref (feature_cvterm_id);
create index feature_cvterm_dbxref_idx2 on feature_cvterm_dbxref (dbxref_id);

COMMENT ON TABLE feature_cvterm_dbxref IS
 'Additional dbxrefs for an association. Rows in the feature_cvterm table may be backed up by dbxrefs. For example, a feature_cvterm association that was inferred via a protein-protein interaction may be backed by by refering to the dbxref for the alternate protein. Corresponds to the WITH column in a GO gene association file (but can also be used for other analagous associations). See http://www.geneontology.org/doc/GO.annotation.shtml#file for more details';

--

create table feature_cvterm_pub (
    feature_cvterm_pub_id serial not null,
    primary key (feature_cvterm_pub_id),
    feature_cvterm_id int not null,
    foreign key (feature_cvterm_id) references feature_cvterm (feature_cvterm_id) on delete cascade,
    pub_id int not null,
    foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
    constraint feature_cvterm_pub_c1 unique (feature_cvterm_id,pub_id)
);
create index feature_cvterm_pub_idx1 on feature_cvterm_pub (feature_cvterm_id);
create index feature_cvterm_pub_idx2 on feature_cvterm_pub (pub_id);

COMMENT ON TABLE feature_cvterm_pub IS 'Secondary pubs for an
association. Each feature_cvterm association is supported by a single
primary publication. Additional secondary pubs can be added using this
linking table (in a GO gene association file, these corresponding to
any IDs after the pipe symbol in the publications column';

--

create table synonym (
    synonym_id serial not null,
    primary key (synonym_id),
    name varchar(255) not null,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    synonym_sgml varchar(255) not null,
    constraint synonym_c1 unique (name,type_id)
);

COMMENT ON TABLE synonym IS 'A synonym for a feature. One feature can have multiple synonyms, and the same synonym can apply to multiple features';

COMMENT ON COLUMN synonym.name IS 'The synonym itself. Should be human-readable machine-searchable ascii text';

COMMENT ON COLUMN synonym.synonym_sgml IS 'The fully specified synonym, with any non-ascii characters encoded in SGML';

COMMENT ON COLUMN synonym.type_id IS 'types would be symbol and fullname for now';

create index synonym_idx1 on synonym (type_id);
create index synonym_idx2 on synonym ((lower(synonym_sgml)));

--

create table feature_synonym (
    feature_synonym_id serial not null,
    primary key (feature_synonym_id),
    synonym_id int not null,
    foreign key (synonym_id) references synonym (synonym_id) on delete cascade INITIALLY DEFERRED,
    feature_id int not null,
    foreign key (feature_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,
    pub_id int not null,
    foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
    is_current boolean not null default 'true',
    is_internal boolean not null default 'false',
    constraint feature_synonym_c1 unique (synonym_id,feature_id,pub_id)
);

COMMENT ON TABLE feature_synonym IS 'Linking table between feature and synonym';

COMMENT ON COLUMN feature_synonym.pub_id IS 'the pub_id link is for relating the usage of a given synonym to the publication in which it was used';

COMMENT ON COLUMN feature_synonym.is_current IS 'the is_current boolean indicates whether the linked synonym is the  current -official- symbol for the linked feature';

COMMENT ON COLUMN feature_synonym.is_internal IS 'typically a synonym exists so that somebody querying the db with an obsolete name can find the object theyre looking for (under its current name.  If the synonym has been used publicly & deliberately (eg in a paper), it my also be listed in reports as a synonym.   If the synonym was not used deliberately (eg, there was a typo which went public), then the is_internal boolean may be set to -true- so that it is known that the 
synonym is -internal- and should be queryable but should not be listed in reports as a valid synonym';

create index feature_synonym_idx1 on feature_synonym (synonym_id);
create index feature_synonym_idx2 on feature_synonym (feature_id);
create index feature_synonym_idx3 on feature_synonym (pub_id);
CREATE SCHEMA genetic_code;
SET search_path = genetic_code,public;

CREATE TABLE gencode (
        gencode_id      INTEGER PRIMARY KEY NOT NULL,
        organismstr     VARCHAR(512) NOT NULL
);

CREATE TABLE gencode_codon_aa (
        gencode_id      INTEGER NOT NULL REFERENCES gencode(gencode_id),
        codon           CHAR(3) NOT NULL,
        aa              CHAR(1) NOT NULL
);
CREATE INDEX gencode_codon_aa_i1 ON gencode_codon_aa(gencode_id,codon,aa);

CREATE TABLE gencode_startcodon (
        gencode_id      INTEGER NOT NULL REFERENCES gencode(gencode_id),
        codon           CHAR(3)
);
SET search_path = public;
--
-- functions operating on featureloc ranges
--

-- create a point
CREATE OR REPLACE FUNCTION create_point (int, int) RETURNS point AS
 'SELECT point ($1, $2)'
LANGUAGE 'sql';

-- create a range box
-- (make this immutable so we can index it)
CREATE OR REPLACE FUNCTION boxrange (int, int) RETURNS box AS
 'SELECT box (create_point(0, $1), create_point($2,500000000))'
LANGUAGE 'sql' IMMUTABLE;

-- create a query box
CREATE OR REPLACE FUNCTION boxquery (int, int) RETURNS box AS
 'SELECT box (create_point($1, $2), create_point($1, $2))'
LANGUAGE 'sql' IMMUTABLE;

--functional index that depends on the above functions
CREATE INDEX binloc_boxrange ON featureloc USING RTREE (boxrange(fmin, fmax));


CREATE OR REPLACE FUNCTION featureloc_slice(int, int) RETURNS setof featureloc AS
  'SELECT * from featureloc where boxquery($1, $2) @ boxrange(fmin,fmax)'
LANGUAGE 'sql';

CREATE OR REPLACE FUNCTION featureloc_slice(varchar, int, int)
  RETURNS setof featureloc AS
  'SELECT featureloc.* 
   FROM featureloc 
   INNER JOIN feature AS srcf ON (srcf.feature_id = featureloc.srcfeature_id)
   WHERE boxquery($2, $3) @ boxrange(fmin,fmax)
   AND srcf.name = $1 '
LANGUAGE 'sql';

CREATE OR REPLACE FUNCTION featureloc_slice(int, int, int)
  RETURNS setof featureloc AS
  'SELECT * 
   FROM featureloc 
   WHERE boxquery($2, $3) @ boxrange(fmin,fmax)
   AND srcfeature_id = $1 '
LANGUAGE 'sql';


-- can we not just do these as views?
CREATE OR REPLACE FUNCTION feature_overlaps(int)
 RETURNS setof feature AS
 'SELECT feature.*
  FROM feature
   INNER JOIN featureloc AS x ON (x.feature_id=feature.feature_id)
   INNER JOIN featureloc AS y ON (y.feature_id=$1)
  WHERE
   x.srcfeature_id = y.srcfeature_id            AND
   ( x.fmax >= y.fmin AND x.fmin <= y.fmax ) '
LANGUAGE 'sql';

CREATE OR REPLACE FUNCTION feature_disjoint_from(int)
 RETURNS setof feature AS
 'SELECT feature.*
  FROM feature
   INNER JOIN featureloc AS x ON (x.feature_id=feature.feature_id)
   INNER JOIN featureloc AS y ON (y.feature_id=$1)
  WHERE
   x.srcfeature_id = y.srcfeature_id            AND
   ( x.fmax < y.fmin OR x.fmin > y.fmax ) '
LANGUAGE 'sql';


-- reverse_string
CREATE OR REPLACE FUNCTION reverse_string(TEXT) RETURNS TEXT AS 
'
 DECLARE 
  reversed_string TEXT;
  incoming ALIAS FOR $1;
 BEGIN
   reversed_string = '''';
   FOR i IN REVERSE char_length(incoming)..1 loop
     reversed_string = reversed_string || substring(incoming FROM i FOR 1);
   END loop;
 RETURN reversed_string;
END'
language plpgsql;

-- complements DNA
CREATE OR REPLACE FUNCTION complement_residues(text) RETURNS text AS
 'SELECT (translate($1, 
                   ''acgtrymkswhbvdnxACGTRYMKSWHBVDNX'',
                   ''tgcayrkmswdvbhnxTGCAYRKMSWDVBHNX''))'
LANGUAGE 'sql';

-- revcomp
CREATE OR REPLACE FUNCTION reverse_complement(TEXT) RETURNS TEXT AS
 'SELECT reverse_string(complement_residues($1))'
LANGUAGE 'sql';

-- DNA to AA
CREATE OR REPLACE FUNCTION translate_dna(TEXT,INT) RETURNS TEXT AS 
'
 DECLARE 
  dnaseq ALIAS FOR $1;
  gcode ALIAS FOR $2;
  translation TEXT;
  dnaseqlen INT;
  codon CHAR(3);
  aa CHAR(1);
  i INT;
 BEGIN
   translation = '''';
   dnaseqlen = char_length(dnaseq);
   i=1;
   WHILE i+1 < dnaseqlen loop
     codon = substring(dnaseq,i,3);
     aa = translate_codon(codon,gcode);
     translation = translation || aa;
     i = i+3;
   END loop;
 RETURN translation;
END'
language plpgsql;

-- DNA to AA, default genetic code
CREATE OR REPLACE FUNCTION translate_dna(TEXT) RETURNS TEXT AS
 'SELECT translate_dna($1,1)'
LANGUAGE 'sql';


CREATE OR REPLACE FUNCTION translate_codon(TEXT,INT) RETURNS CHAR AS
 'SELECT aa FROM genetic_code.gencode_codon_aa WHERE codon=$1 AND gencode_id=$2'
LANGUAGE 'sql';



CREATE OR REPLACE FUNCTION concat_pair (text, text) RETURNS text AS
 'SELECT $1 || $2'
LANGUAGE 'sql';

CREATE AGGREGATE concat (
sfunc = concat_pair,
basetype = text,
stype = text,
initcond = ''
);
-- down the graph: eg from  chromosome to contig
CREATE OR REPLACE FUNCTION project_point_up(int,int,int,int)
 RETURNS int AS
'SELECT
  CASE WHEN $4<0
   THEN $3-$1             -- rev strand
   ELSE $1-$2             -- fwd strand
  END AS p'
LANGUAGE 'sql'; 

-- down the graph: eg from contig to chromosome
CREATE OR REPLACE FUNCTION project_point_down(int,int,int,int)
 RETURNS int AS
'SELECT
  CASE WHEN $4<0
   THEN $3-$1
   ELSE $1+$2
  END AS p'
LANGUAGE 'sql'; 

CREATE OR REPLACE FUNCTION project_featureloc_up(int,int)
 RETURNS featureloc AS
'
DECLARE
    in_featureloc_id alias for $1;
    up_srcfeature_id alias for $2;
    in_featureloc featureloc%ROWTYPE;
    up_featureloc featureloc%ROWTYPE;
    nu_featureloc featureloc%ROWTYPE;
    nu_fmin INT;
    nu_fmax INT;
    nu_strand INT;
BEGIN
 SELECT INTO in_featureloc
   featureloc.*
  FROM featureloc
  WHERE featureloc_id = in_featureloc_id;

 SELECT INTO up_featureloc
   up_fl.*
  FROM featureloc AS in_fl
  INNER JOIN featureloc AS up_fl
    ON (in_fl.srcfeature_id = up_fl.feature_id)
  WHERE
   in_fl.featureloc_id = in_featureloc_id AND
   up_fl.srcfeature_id = up_srcfeature_id;

  IF up_featureloc.strand IS NULL
   THEN RETURN NULL;
  END IF;
  
  IF up_featureloc.strand < 0
  THEN
   nu_fmin = project_point_up(in_featureloc.fmax,
                              up_featureloc.fmin,up_featureloc.fmax,-1);
   nu_fmax = project_point_up(in_featureloc.fmin,
                              up_featureloc.fmin,up_featureloc.fmax,-1);
   nu_strand = -in_featureloc.strand;
  ELSE
   nu_fmin = project_point_up(in_featureloc.fmin,
                              up_featureloc.fmin,up_featureloc.fmax,1);
   nu_fmax = project_point_up(in_featureloc.fmax,
                              up_featureloc.fmin,up_featureloc.fmax,1);
   nu_strand = in_featureloc.strand;
  END IF;
  in_featureloc.fmin = nu_fmin;
  in_featureloc.fmax = nu_fmax;
  in_featureloc.strand = nu_strand;
  in_featureloc.srcfeature_id = up_featureloc.srcfeature_id;
  RETURN in_featureloc;
END
'   
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION project_point_g2t(int,int,int)
 RETURNS INT AS '
 DECLARE
    in_p             alias for $1;
    srcf_id          alias for $2;
    t_id             alias for $3;
    e_floc           featureloc%ROWTYPE;
    out_p            INT;
    exon_cvterm_id   INT;
BEGIN
 SELECT INTO exon_cvterm_id get_feature_type_id(''exon'');
 SELECT INTO out_p
  CASE 
   WHEN strand<0 THEN fmax-p
   ELSE p-fmin
   END AS p
  FROM featureloc
   INNER JOIN feature USING (feature_id)
   INNER JOIN feature_relationship ON (feature.feature_id=subject_id)
  WHERE
   object_id = t_id                     AND
   feature.type_id = exon_cvterm_id     AND
   featureloc.srcfeature_id = srcf_id   AND
   in_p >= fmin                         AND
   in_p <= fmax;
  RETURN in_featureloc;
END
'   
LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION get_cv_id_for_feature() RETURNS INT
 AS 'SELECT cv_id FROM cv WHERE name=''sequence''' LANGUAGE 'sql';
CREATE OR REPLACE FUNCTION get_cv_id_for_featureprop() RETURNS INT
 AS 'SELECT cv_id FROM cv WHERE name=''feature_property''' LANGUAGE 'sql';
CREATE OR REPLACE FUNCTION get_cv_id_for_feature_relationsgip() RETURNS INT
 AS 'SELECT cv_id FROM cv WHERE name=''relationship''' LANGUAGE 'sql';

CREATE OR REPLACE FUNCTION get_feature_type_id(VARCHAR) RETURNS INT
 AS ' 
  SELECT cvterm_id 
  FROM cv INNER JOIN cvterm USING (cv_id)
  WHERE cvterm.name=$1 AND cv.name=''sequence''
 ' LANGUAGE 'sql';

CREATE OR REPLACE FUNCTION get_featureprop_type_id(VARCHAR) RETURNS INT
 AS '
  SELECT cvterm_id 
  FROM cv INNER JOIN cvterm USING (cv_id)
  WHERE cvterm.name=$1 AND cv.name=''feature_property''
 ' LANGUAGE 'sql';

CREATE OR REPLACE FUNCTION get_feature_relationship_type_id(VARCHAR) RETURNS INT
 AS '
  SELECT cvterm_id 
  FROM cv INNER JOIN cvterm USING (cv_id)
  WHERE cvterm.name=$1 AND cv.name=''relationship''
 ' LANGUAGE 'sql';

-- depends on sequence-cv-helper
CREATE OR REPLACE FUNCTION get_feature_id(VARCHAR,VARCHAR,VARCHAR) RETURNS INT
 AS '
  SELECT feature_id 
  FROM feature
  WHERE uniquename=$1
    AND type_id=get_feature_type_id($2)
    AND organism_id=get_organism_id($3)
 ' LANGUAGE 'sql';
CREATE OR REPLACE FUNCTION store_feature 
(INT,INT,INT,INT,
 INT,INT,VARCHAR,VARCHAR,INT,BOOLEAN)
 RETURNS INT AS 
'DECLARE
  v_srcfeature_id       ALIAS FOR $1;
  v_fmin                ALIAS FOR $2;
  v_fmax                ALIAS FOR $3;
  v_strand              ALIAS FOR $4;
  v_dbxref_id           ALIAS FOR $5;
  v_organism_id         ALIAS FOR $6;
  v_name                ALIAS FOR $7;
  v_uniquename          ALIAS FOR $8;
  v_type_id             ALIAS FOR $9;
  v_is_analysis         ALIAS FOR $10;
  v_feature_id          INT;
  v_featureloc_id       INT;
 BEGIN
    IF v_dbxref_id IS NULL THEN
      SELECT INTO v_feature_id feature_id
      FROM feature
      WHERE uniquename=v_uniquename     AND
            organism_id=v_organism_id   AND
            type_id=v_type_id;
    ELSE
      SELECT INTO v_feature_id feature_id
      FROM feature
      WHERE dbxref_id=v_dbxref_id;
    END IF;
    IF NOT FOUND THEN
      INSERT INTO feature
       ( dbxref_id           ,
         organism_id         ,
         name                ,
         uniquename          ,
         type_id             ,
         is_analysis         )
        VALUES
        ( v_dbxref_id           ,
          v_organism_id         ,
          v_name                ,
          v_uniquename          ,
          v_type_id             ,
          v_is_analysis         );
      v_feature_id = currval(''feature_feature_id_seq'');
    ELSE
      UPDATE feature SET
        dbxref_id   =  v_dbxref_id           ,
        organism_id =  v_organism_id         ,
        name        =  v_name                ,
        uniquename  =  v_uniquename          ,
        type_id     =  v_type_id             ,
        is_analysis =  v_is_analysis
      WHERE
        feature_id=v_feature_id;
    END IF;
  PERFORM store_featureloc(v_feature_id,
                           v_srcfeature_id,
                           v_fmin,
                           v_fmax,
                           v_strand,
                           0,
                           0);
  RETURN v_feature_id;
 END;
' LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION store_featureloc
(INT,INT,INT,INT,INT,INT,INT)
 RETURNS INT AS 
'DECLARE
  v_feature_id          ALIAS FOR $1;
  v_srcfeature_id       ALIAS FOR $2;
  v_fmin                ALIAS FOR $3;
  v_fmax                ALIAS FOR $4;
  v_strand              ALIAS FOR $5;
  v_rank                ALIAS FOR $6;
  v_locgroup            ALIAS FOR $7;
  v_featureloc_id       INT;
 BEGIN
    IF v_feature_id IS NULL THEN RAISE EXCEPTION ''feature_id cannot be null'';
    END IF;
    SELECT INTO v_featureloc_id featureloc_id
      FROM featureloc
      WHERE feature_id=v_feature_id     AND
            rank=v_rank                 AND
            locgroup=v_locgroup;
    IF NOT FOUND THEN
      INSERT INTO featureloc
        ( feature_id,
          srcfeature_id,
          fmin,
          fmax,
          strand,
          rank,
          locgroup)
        VALUES
        (  v_feature_id,
           v_srcfeature_id,
           v_fmin,
           v_fmax,
           v_strand,
           v_rank,
           v_locgroup);
      v_featureloc_id = currval(''featureloc_featureloc_id_seq'');
    ELSE
      UPDATE featureloc SET
        feature_id    =  v_feature_id,
        srcfeature_id =  v_srcfeature_id,
        fmin          =  v_fmin,
        fmax          =  v_fmax,
        strand        =  v_strand,
        rank          =  v_rank,
        locgroup      =  v_locgroup
      WHERE
        featureloc_id=v_featureloc_id;
    END IF;
  RETURN v_featureloc_id;
 END;
' LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION store_feature_synonym
(INT,VARCHAR,INT,BOOLEAN,BOOLEAN,INT)
 RETURNS INT AS 
'DECLARE
  v_feature_id          ALIAS FOR $1;
  v_syn                 ALIAS FOR $2;
  v_type_id             ALIAS FOR $3;
  v_is_current          ALIAS FOR $4;
  v_is_internal         ALIAS FOR $5;
  v_pub_id              ALIAS FOR $6;
  v_synonym_id          INT;
  v_feature_synonym_id  INT;
 BEGIN
    IF v_feature_id IS NULL THEN RAISE EXCEPTION ''feature_id cannot be null'';
    END IF;
    SELECT INTO v_synonym_id synonym_id
      FROM synonym
      WHERE name=v_syn                  AND
            type_id=v_type_id;
    IF NOT FOUND THEN
      INSERT INTO synonym
        ( name,
          synonym_sgml,
          type_id)
        VALUES
        ( v_syn,
          v_syn,
          v_type_id);
      v_synonym_id = currval(''synonym_synonym_id_seq'');
    END IF;
    SELECT INTO v_feature_synonym_id feature_synonym_id
        FROM feature_synonym
        WHERE feature_id=v_feature_id   AND
              synonym_id=v_synonym_id   AND
              pub_id=v_pub_id;
    IF NOT FOUND THEN
      INSERT INTO feature_synonym
        ( feature_id,
          synonym_id,
          pub_id,
          is_current,
          is_internal)
        VALUES
        ( v_feature_id,
          v_synonym_id,
          v_pub_id,
          v_is_current,
          v_is_internal);
      v_feature_synonym_id = currval(''feature_synonym_feature_synonym_id_seq'');
    ELSE
      UPDATE feature_synonym
        SET is_current=v_is_current, is_internal=v_is_internal
        WHERE feature_synonym_id=v_feature_synonym_id;
    END IF;
  RETURN v_feature_synonym_id;
 END;
' LANGUAGE 'plpgsql';



-- dependency_on: [sequtil,sequence-cv-helper]

CREATE OR REPLACE FUNCTION subsequence(INT,INT,INT,INT)
 RETURNS TEXT AS
 'SELECT 
  CASE WHEN $4<0 
   THEN reverse_complement(substring(srcf.residues,$2+1,($3-$2)))
   ELSE substring(residues,$2+1,($3-$2))
  END AS residues
  FROM feature AS srcf
  WHERE
   srcf.feature_id=$1'
LANGUAGE 'sql';

CREATE OR REPLACE FUNCTION subsequence_by_featureloc(INT)
 RETURNS TEXT AS
 'SELECT 
  CASE WHEN strand<0 
   THEN reverse_complement(substring(srcf.residues,fmin+1,(fmax-fmin)))
   ELSE substring(srcf.residues,fmin+1,(fmax-fmin))
  END AS residues
  FROM feature AS srcf
   INNER JOIN featureloc ON (srcf.feature_id=featureloc.srcfeature_id)
  WHERE
   featureloc_id=$1'
LANGUAGE 'sql';

CREATE OR REPLACE FUNCTION subsequence_by_feature(INT,INT,INT)
 RETURNS TEXT AS
 'SELECT 
  CASE WHEN strand<0 
   THEN reverse_complement(substring(srcf.residues,fmin+1,(fmax-fmin)))
   ELSE substring(srcf.residues,fmin+1,(fmax-fmin))
  END AS residues
  FROM feature AS srcf
   INNER JOIN featureloc ON (srcf.feature_id=featureloc.srcfeature_id)
  WHERE
   featureloc.feature_id=$1 AND
   featureloc.rank=$2 AND
   featureloc.locgroup=$3'
LANGUAGE 'sql';

CREATE OR REPLACE FUNCTION subsequence_by_feature(INT)
 RETURNS TEXT AS 'SELECT subsequence_by_feature($1,0,0)'
LANGUAGE 'sql';

-- based on subfeature sets:

-- constrained by feature_relationship.type_id
--   (allows user to construct queries that only get subsequences of
--    part_of subfeatures)

CREATE OR REPLACE FUNCTION subsequence_by_subfeatures(INT,INT,INT,INT)
 RETURNS TEXT AS '
DECLARE v_feature_id ALIAS FOR $1;
DECLARE v_rtype_id   ALIAS FOR $2;
DECLARE v_rank       ALIAS FOR $3;
DECLARE v_locgroup   ALIAS FOR $4;
DECLARE subseq       TEXT;
DECLARE seqrow       RECORD;
BEGIN 
  subseq = '''';
 FOR seqrow IN
   SELECT
    CASE WHEN strand<0 
     THEN reverse_complement(substring(srcf.residues,fmin+1,(fmax-fmin)))
     ELSE substring(srcf.residues,fmin+1,(fmax-fmin))
    END AS residues
    FROM feature AS srcf
     INNER JOIN featureloc ON (srcf.feature_id=featureloc.srcfeature_id)
     INNER JOIN feature_relationship AS fr
       ON (fr.subject_id=featureloc.feature_id)
    WHERE
     fr.object_id=v_feature_id AND
     fr.type_id=v_rtype_id AND
     featureloc.rank=v_rank AND
     featureloc.locgroup=v_locgroup
    ORDER BY fr.rank
  LOOP
   subseq = subseq  || seqrow.residues;
  END LOOP;
 RETURN subseq;
END
'
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION subsequence_by_subfeatures(INT,INT)
 RETURNS TEXT AS
 'SELECT subsequence_by_subfeatures($1,$2,0,0)'
LANGUAGE 'sql';

CREATE OR REPLACE FUNCTION subsequence_by_subfeatures(INT)
 RETURNS TEXT AS
'
SELECT subsequence_by_subfeatures($1,get_feature_relationship_type_id(''part_of''),0,0)
'
LANGUAGE 'sql';


-- constrained by subfeature.type_id (eg exons of a transcript)
CREATE OR REPLACE FUNCTION subsequence_by_typed_subfeatures(INT,INT,INT,INT)
 RETURNS TEXT AS '
DECLARE v_feature_id ALIAS FOR $1;
DECLARE v_ftype_id   ALIAS FOR $2;
DECLARE v_rank       ALIAS FOR $3;
DECLARE v_locgroup   ALIAS FOR $4;
DECLARE subseq       TEXT;
DECLARE seqrow       RECORD;
BEGIN 
  subseq = '''';
 FOR seqrow IN
   SELECT
    CASE WHEN strand<0 
     THEN reverse_complement(substring(srcf.residues,fmin+1,(fmax-fmin)))
     ELSE substring(srcf.residues,fmin+1,(fmax-fmin))
    END AS residues
  FROM feature AS srcf
   INNER JOIN featureloc ON (srcf.feature_id=featureloc.srcfeature_id)
   INNER JOIN feature AS subf ON (subf.feature_id=featureloc.feature_id)
   INNER JOIN feature_relationship AS fr ON (fr.subject_id=subf.feature_id)
  WHERE
     fr.object_id=v_feature_id AND
     subf.type_id=v_ftype_id AND
     featureloc.rank=v_rank AND
     featureloc.locgroup=v_locgroup
  ORDER BY fr.rank
   LOOP
   subseq = subseq  || seqrow.residues;
  END LOOP;
 RETURN subseq;
END
'
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION subsequence_by_typed_subfeatures(INT,INT)
 RETURNS TEXT AS
 'SELECT subsequence_by_typed_subfeatures($1,$2,0,0)'
LANGUAGE 'sql';

 


CREATE OR REPLACE FUNCTION feature_subalignments(integer) RETURNS SETOF featureloc AS '
DECLARE
  return_data featureloc%ROWTYPE;
  f_id ALIAS FOR $1;
  feature_data feature%rowtype;
  featureloc_data featureloc%rowtype;

  s text;

  fmin integer;
  slen integer;
BEGIN
  --RAISE NOTICE ''feature_id is %'', featureloc_data.feature_id;
  SELECT INTO feature_data * FROM feature WHERE feature_id = f_id;

  FOR featureloc_data IN SELECT * FROM featureloc WHERE feature_id = f_id LOOP

    --RAISE NOTICE ''fmin is %'', featureloc_data.fmin;

    return_data.feature_id      = f_id;
    return_data.srcfeature_id   = featureloc_data.srcfeature_id;
    return_data.is_fmin_partial = featureloc_data.is_fmin_partial;
    return_data.is_fmax_partial = featureloc_data.is_fmax_partial;
    return_data.strand          = featureloc_data.strand;
    return_data.phase           = featureloc_data.phase;
    return_data.residue_info    = featureloc_data.residue_info;
    return_data.locgroup        = featureloc_data.locgroup;
    return_data.rank            = featureloc_data.rank;

    s = feature_data.residues;
    fmin = featureloc_data.fmin;
    slen = char_length(s);

    WHILE char_length(s) LOOP
      --RAISE NOTICE ''residues is %'', s;

      --trim off leading match
      s = trim(leading ''|ATCGNatcgn'' from s);
      --if leading match detected
      IF slen > char_length(s) THEN
        return_data.fmin = fmin;
        return_data.fmax = featureloc_data.fmin + (slen - char_length(s));

        --if the string started with a match, return it,
        --otherwise, trim the gaps first (ie do not return this iteration)
        RETURN NEXT return_data;
      END IF;

      --trim off leading gap
      s = trim(leading ''-'' from s);

      fmin = featureloc_data.fmin + (slen - char_length(s));
    END LOOP;
  END LOOP;

  RETURN;

END;
' LANGUAGE 'plpgsql';
CREATE SCHEMA frange;
SET search_path = frange,public;

CREATE TABLE featuregroup (
    featuregroup_id serial not null,
    primary key (featuregroup_id),

    subject_id int not null,
    foreign key (subject_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,

    object_id int not null,
    foreign key (object_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,

    group_id int not null,
    foreign key (group_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,

    srcfeature_id int null,
    foreign key (srcfeature_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,

    fmin int null,
    fmax int null,
    strand int null,
    is_root int not null default 0,

    constraint featuregroup_c1 unique (subject_id,object_id,group_id,srcfeature_id,fmin,fmax,strand)
);
CREATE INDEX featuregroup_idx1 ON featuregroup (subject_id);
CREATE INDEX featuregroup_idx2 ON featuregroup (object_id);
CREATE INDEX featuregroup_idx3 ON featuregroup (group_id);
CREATE INDEX featuregroup_idx4 ON featuregroup (srcfeature_id);
CREATE INDEX featuregroup_idx5 ON featuregroup (strand);
CREATE INDEX featuregroup_idx6 ON featuregroup (is_root);

CREATE OR REPLACE FUNCTION groupoverlaps(int4, int4, varchar) RETURNS setof featuregroup AS '
  SELECT g2.*
  FROM  featuregroup g1,
        featuregroup g2
  WHERE g1.is_root = 1
    AND ( g1.srcfeature_id = g2.srcfeature_id OR g2.srcfeature_id IS NULL )
    AND g1.group_id = g2.group_id
    AND g1.srcfeature_id = (SELECT feature_id FROM feature WHERE uniquename = $3)
    AND boxquery($1, $2) @ boxrange(g1.fmin,g2.fmax)
' LANGUAGE 'sql';

CREATE OR REPLACE FUNCTION groupcontains(int4, int4, varchar) RETURNS setof featuregroup AS '
  SELECT *
  FROM groupoverlaps($1,$2,$3)
  WHERE fmin <= $1 AND fmax >= $2
' LANGUAGE 'sql';

CREATE OR REPLACE FUNCTION groupinside(int4, int4, varchar) RETURNS setof featuregroup AS '
  SELECT *
  FROM groupoverlaps($1,$2,$3)
  WHERE fmin >= $1 AND fmax <= $2
' LANGUAGE 'sql';

CREATE OR REPLACE FUNCTION groupidentical(int4, int4, varchar) RETURNS setof featuregroup AS '
  SELECT *
  FROM groupoverlaps($1,$2,$3)
  WHERE fmin = $1 AND fmax = $2
' LANGUAGE 'sql';

CREATE OR REPLACE FUNCTION groupoverlaps(int4, int4) RETURNS setof featuregroup AS '
  SELECT *
  FROM featuregroup
  WHERE is_root = 1
    AND boxquery($1, $2) @ boxrange(fmin,fmax)
' LANGUAGE 'sql';

CREATE OR REPLACE FUNCTION groupoverlaps(_int4, _int4, _varchar) RETURNS setof featuregroup AS '
DECLARE
    mins alias for $1;
    maxs alias for $2;
    srcs alias for $3;
    f featuregroup%ROWTYPE;
    i int;
    s int;
BEGIN
    i := 1;
    FOR i in array_lower( mins, 1 ) .. array_upper( mins, 1 ) LOOP
        SELECT INTO s feature_id FROM feature WHERE uniquename = srcs[i];
        FOR f IN
            SELECT *
            FROM  featuregroup WHERE group_id IN (
                SELECT group_id FROM featuregroup
                WHERE (srcfeature_id = s OR srcfeature_id IS NULL)
                  AND group_id IN (
                      SELECT group_id FROM groupoverlaps( mins[i], maxs[i] )
                      WHERE  srcfeature_id = s
                  )
            )
        LOOP
            RETURN NEXT f;
        END LOOP;
    END LOOP;
    RETURN;
END;
' LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION groupcontains(_int4, _int4, _varchar) RETURNS setof featuregroup AS '
DECLARE
    mins alias for $1;
    maxs alias for $2;
    srcs alias for $3;
    f featuregroup%ROWTYPE;
    i int;
    s int;
BEGIN
    i := 1;
    FOR i in array_lower( mins, 1 ) .. array_upper( mins, 1 ) LOOP
        SELECT INTO s feature_id FROM feature WHERE uniquename = srcs[i];
        FOR f IN
            SELECT *
            FROM  featuregroup WHERE group_id IN (
                SELECT group_id FROM featuregroup
                WHERE (srcfeature_id = s OR srcfeature_id IS NULL)
                  AND fmin <= mins[i]
                  AND fmax >= maxs[i]
                  AND group_id IN (
                      SELECT group_id FROM groupoverlaps( mins[i], maxs[i] )
                      WHERE  srcfeature_id = s
                  )
            )
        LOOP
            RETURN NEXT f;
        END LOOP;
    END LOOP;
    RETURN;
END;
' LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION groupinside(_int4, _int4, _varchar) RETURNS setof featuregroup AS '
DECLARE
    mins alias for $1;
    maxs alias for $2;
    srcs alias for $3;
    f featuregroup%ROWTYPE;
    i int;
    s int;
BEGIN
    i := 1;
    FOR i in array_lower( mins, 1 ) .. array_upper( mins, 1 ) LOOP
        SELECT INTO s feature_id FROM feature WHERE uniquename = srcs[i];
        FOR f IN
            SELECT *
            FROM  featuregroup WHERE group_id IN (
                SELECT group_id FROM featuregroup
                WHERE (srcfeature_id = s OR srcfeature_id IS NULL)
                  AND fmin >= mins[i]
                  AND fmax <= maxs[i]
                  AND group_id IN (
                      SELECT group_id FROM groupoverlaps( mins[i], maxs[i] )
                      WHERE  srcfeature_id = s
                  )
            )
        LOOP
            RETURN NEXT f;
        END LOOP;
    END LOOP;
    RETURN;
END;
' LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION groupidentical(_int4, _int4, _varchar) RETURNS setof featuregroup AS '
DECLARE
    mins alias for $1;
    maxs alias for $2;
    srcs alias for $3;
    f featuregroup%ROWTYPE;
    i int;
    s int;
BEGIN
    i := 1;
    FOR i in array_lower( mins, 1 ) .. array_upper( mins, 1 ) LOOP
        SELECT INTO s feature_id FROM feature WHERE uniquename = srcs[i];
        FOR f IN
            SELECT *
            FROM  featuregroup WHERE group_id IN (
                SELECT group_id FROM featuregroup
                WHERE (srcfeature_id = s OR srcfeature_id IS NULL)
                  AND fmin = mins[i]
                  AND fmax = maxs[i]
                  AND group_id IN (
                      SELECT group_id FROM groupoverlaps( mins[i], maxs[i] )
                      WHERE  srcfeature_id = s
                  )
            )
        LOOP
            RETURN NEXT f;
        END LOOP;
    END LOOP;
    RETURN;
END;
' LANGUAGE 'plpgsql';

--functional index that depends on the above functions
CREATE INDEX bingroup_boxrange ON featuregroup USING RTREE (boxrange(fmin, fmax)) WHERE is_root = 1;

CREATE OR REPLACE FUNCTION _fill_featuregroup(INTEGER, INTEGER) RETURNS INTEGER AS '
DECLARE
    groupid alias for $1;
    parentid alias for $2;
    g featuregroup%ROWTYPE;
BEGIN
    FOR g IN
        SELECT DISTINCT 0, fr.subject_id, fr.object_id, groupid, fl.srcfeature_id, fl.fmin, fl.fmax, fl.strand, 0
        FROM  feature_relationship AS fr,
              featureloc AS fl
        WHERE fr.object_id = parentid
          AND fr.subject_id = fl.feature_id
    LOOP
        INSERT INTO featuregroup
            (subject_id, object_id, group_id, srcfeature_id, fmin, fmax, strand, is_root)
        VALUES
            (g.subject_id, g.object_id, g.group_id, g.srcfeature_id, g.fmin, g.fmax, g.strand, 0);
        PERFORM _fill_featuregroup(groupid,g.subject_id);
    END LOOP;
    RETURN 1;
END;
' LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION fill_featuregroup() RETURNS INTEGER AS '
DECLARE
    p featuregroup%ROWTYPE;
    l featureloc%ROWTYPE;
    isa int;
    c int;
BEGIN
    TRUNCATE featuregroup;
    SELECT INTO isa cvterm_id FROM cvterm WHERE (name = ''isa'' OR name = ''is_a'');

    -- Recursion is the biggest performance killer for this function.
    -- We can dodge the first round of recursion using the "fr1 / GROUP BY" approach.
    -- Luckily, most feature graphs are only 2 levels deep, so most recursion is
    -- avoidable.

    RAISE NOTICE ''Loading root and singleton features.'';
    FOR p IN
        SELECT DISTINCT 0, f.feature_id, f.feature_id, f.feature_id, srcfeature_id, fmin, fmax, strand, 1
        FROM feature AS f
        LEFT JOIN feature_relationship ON (f.feature_id = object_id)
        LEFT JOIN featureloc           ON (f.feature_id = featureloc.feature_id)
        WHERE f.feature_id NOT IN ( SELECT subject_id FROM feature_relationship )
          AND srcfeature_id IS NOT NULL
    LOOP
        INSERT INTO featuregroup
            (subject_id, object_id, group_id, srcfeature_id, fmin, fmax, strand, is_root)
        VALUES
            (p.object_id, p.object_id, p.object_id, p.srcfeature_id, p.fmin, p.fmax, p.strand, 1);
    END LOOP;

    RAISE NOTICE ''Loading child features.  If your database contains grandchild'';
    RAISE NOTICE ''features, they will be loaded recursively and may take a long time.'';

    FOR p IN
        SELECT DISTINCT 0, fr0.subject_id, fr0.object_id, fr0.object_id, fl.srcfeature_id, fl.fmin, fl.fmax, fl.strand, count(fr1.subject_id)
        FROM  feature_relationship AS fr0
        LEFT JOIN feature_relationship AS fr1 ON ( fr0.subject_id = fr1.object_id),
        featureloc AS fl
        WHERE fr0.subject_id = fl.feature_id
          AND fr0.object_id IN (
                  SELECT f.feature_id
                  FROM feature AS f
                  LEFT JOIN feature_relationship ON (f.feature_id = object_id)
                  LEFT JOIN featureloc           ON (f.feature_id = featureloc.feature_id)
                  WHERE f.feature_id NOT IN ( SELECT subject_id FROM feature_relationship )
                    AND f.feature_id     IN ( SELECT object_id  FROM feature_relationship )
                    AND srcfeature_id IS NOT NULL
              )
        GROUP BY fr0.subject_id, fr0.object_id, fl.srcfeature_id, fl.fmin, fl.fmax, fl.strand
    LOOP
        INSERT INTO featuregroup
            (subject_id, object_id, group_id, srcfeature_id, fmin, fmax, strand, is_root)
        VALUES
            (p.subject_id, p.object_id, p.object_id, p.srcfeature_id, p.fmin, p.fmax, p.strand, 0);
        IF ( p.is_root > 0 ) THEN
            PERFORM _fill_featuregroup(p.subject_id,p.subject_id);
        END IF;
    END LOOP;

    RETURN 1;
END;   
' LANGUAGE 'plpgsql';

SET search_path = public;
--- create ontology that has instantiated located_sequence_feature part of SO
--- way as it is written, the function can not be execute more than once in one connection
--- when you get error like ERROR:  relation with OID NNNNN does not exist
--- as this is not meant to execute >1 times in one session so it should never happen
--- except at testing and test failed
--- disconnect and try again, in other words, it can NOT be executed >1 time in one connection
--- if using EXECUTE, we can avoid this problem but code is hard to write and read (lots of ', escape char)

--NOTE: private, don't call directly as relying on having temp table tmpcvtr

DROP TYPE soi_type CASCADE;
CREATE TYPE soi_type AS (
    type_id INT,
    subject_id INT,
    object_id INT
);

CREATE OR REPLACE FUNCTION _fill_cvtermpath4soinode(INTEGER, INTEGER, INTEGER, INTEGER, INTEGER) RETURNS INTEGER AS
'
DECLARE
    origin alias for $1;
    child_id alias for $2;
    cvid alias for $3;
    typeid alias for $4;
    depth alias for $5;
    cterm soi_type%ROWTYPE;
    exist_c int;

BEGIN

    --RAISE NOTICE ''depth=% o=%, root=%, cv=%, t=%'', depth,origin,child_id,cvid,typeid;
    SELECT INTO exist_c count(*) FROM cvtermpath WHERE cv_id = cvid AND object_id = origin AND subject_id = child_id AND pathdistance = depth;
    --- longest path
    IF (exist_c > 0) THEN
        UPDATE cvtermpath SET pathdistance = depth WHERE cv_id = cvid AND object_id = origin AND subject_id = child_id;
    ELSE
        INSERT INTO cvtermpath (object_id, subject_id, cv_id, type_id, pathdistance) VALUES(origin, child_id, cvid, typeid, depth);
    END IF;

    FOR cterm IN SELECT tmp_type AS type_id, subject_id FROM tmpcvtr WHERE object_id = child_id LOOP
        PERFORM _fill_cvtermpath4soinode(origin, cterm.subject_id, cvid, cterm.type_id, depth+1);
    END LOOP;
    RETURN 1;
END;
'
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION _fill_cvtermpath4soi(INTEGER, INTEGER) RETURNS INTEGER AS
'
DECLARE
    rootid alias for $1;
    cvid alias for $2;
    ttype int;
    cterm soi_type%ROWTYPE;

BEGIN
    
    SELECT INTO ttype cvterm_id FROM cvterm WHERE name = ''isa'';
    --RAISE NOTICE ''got ttype %'',ttype;
    PERFORM _fill_cvtermpath4soinode(rootid, rootid, cvid, ttype, 0);
    FOR cterm IN SELECT tmp_type AS type_id, subject_id FROM tmpcvtr WHERE object_id = rootid LOOP
        PERFORM _fill_cvtermpath4soi(cterm.subject_id, cvid);
    END LOOP;
    RETURN 1;
END;   
'
LANGUAGE 'plpgsql';

--- use tmpcvtr to temp store soi (virtural ontology)
--- using tmp tables is faster than using recursive function to create feature type relationship
--- since it gets feature type rel set by set instead of one by one
--- and getting feature type rel is very expensive
--- call _fillcvtermpath4soi to create path for the virtual ontology

CREATE OR REPLACE FUNCTION create_soi() RETURNS INTEGER AS
'
DECLARE
    parent soi_type%ROWTYPE;
    isa_id cvterm.cvterm_id%TYPE;
    soi_term TEXT := ''soi'';
    soi_def TEXT := ''ontology of SO feature instantiated in database'';
    soi_cvid INTEGER;
    soiterm_id INTEGER;
    pcount INTEGER;
    count INTEGER := 0;
    cquery TEXT;
BEGIN

    SELECT INTO isa_id cvterm_id FROM cvterm WHERE name = ''isa'';

    SELECT INTO soi_cvid cv_id FROM cv WHERE name = soi_term;
    IF (soi_cvid > 0) THEN
        DELETE FROM cvtermpath WHERE cv_id = soi_cvid;
        DELETE FROM cvterm WHERE cv_id = soi_cvid;
    ELSE
        INSERT INTO cv (name, definition) VALUES(soi_term, soi_def);
    END IF;
    SELECT INTO soi_cvid cv_id FROM cv WHERE name = soi_term;
    INSERT INTO cvterm (name, cv_id) VALUES(soi_term, soi_cvid);
    SELECT INTO soiterm_id cvterm_id FROM cvterm WHERE name = soi_term;

    CREATE TEMP TABLE tmpcvtr (tmp_type INT, type_id INT, subject_id INT, object_id INT);
    CREATE UNIQUE INDEX u_tmpcvtr ON tmpcvtr(subject_id, object_id);

    INSERT INTO tmpcvtr (tmp_type, type_id, subject_id, object_id)
        SELECT DISTINCT isa_id, soiterm_id, f.type_id, soiterm_id FROM feature f, cvterm t
        WHERE f.type_id = t.cvterm_id AND f.type_id > 0;
    EXECUTE ''select * from tmpcvtr where type_id = '' || soiterm_id || '';'';
    get diagnostics pcount = row_count;
    raise notice ''all types in feature %'',pcount;
--- do it hard way, delete any child feature type from above (NOT IN clause did not work)
    FOR parent IN SELECT DISTINCT 0, t.cvterm_id, 0 FROM feature c, feature_relationship fr, cvterm t
            WHERE t.cvterm_id = c.type_id AND c.feature_id = fr.subject_id LOOP
        DELETE FROM tmpcvtr WHERE type_id = soiterm_id and object_id = soiterm_id
            AND subject_id = parent.subject_id;
    END LOOP;
    EXECUTE ''select * from tmpcvtr where type_id = '' || soiterm_id || '';'';
    get diagnostics pcount = row_count;
    raise notice ''all types in feature after delete child %'',pcount;

    --- create feature type relationship (store in tmpcvtr)
    CREATE TEMP TABLE tmproot (cv_id INTEGER not null, cvterm_id INTEGER not null, status INTEGER DEFAULT 0);
    cquery := ''SELECT * FROM tmproot tmp WHERE tmp.status = 0;'';
    ---temp use tmpcvtr to hold instantiated SO relationship for speed
    ---use soterm_id as type_id, will delete from tmpcvtr
    ---us tmproot for this as well
    INSERT INTO tmproot (cv_id, cvterm_id, status) SELECT DISTINCT soi_cvid, c.subject_id, 0 FROM tmpcvtr c
        WHERE c.object_id = soiterm_id;
    EXECUTE cquery;
    GET DIAGNOSTICS pcount = ROW_COUNT;
    WHILE (pcount > 0) LOOP
        RAISE NOTICE ''num child temp (to be inserted) in tmpcvtr: %'',pcount;
        INSERT INTO tmpcvtr (tmp_type, type_id, subject_id, object_id)
            SELECT DISTINCT fr.type_id, soiterm_id, c.type_id, p.cvterm_id FROM feature c, feature_relationship fr,
            tmproot p, feature pf, cvterm t WHERE c.feature_id = fr.subject_id AND fr.object_id = pf.feature_id
            AND p.cvterm_id = pf.type_id AND t.cvterm_id = c.type_id AND p.status = 0;
        UPDATE tmproot SET status = 1 WHERE status = 0;
        INSERT INTO tmproot (cv_id, cvterm_id, status)
            SELECT DISTINCT soi_cvid, c.type_id, 0 FROM feature c, feature_relationship fr,
            tmproot tmp, feature p, cvterm t WHERE c.feature_id = fr.subject_id AND fr.object_id = p.feature_id
            AND tmp.cvterm_id = p.type_id AND t.cvterm_id = c.type_id AND tmp.status = 1;
        UPDATE tmproot SET status = 2 WHERE status = 1;
        EXECUTE cquery;
        GET DIAGNOSTICS pcount = ROW_COUNT; 
    END LOOP;
    DELETE FROM tmproot;

    ---get transitive closure for soi
    PERFORM _fill_cvtermpath4soi(soiterm_id, soi_cvid);

    DROP TABLE tmpcvtr;
    DROP TABLE tmproot;

    RETURN 1;
END;
'
LANGUAGE 'plpgsql';

---bad precedence: change customed type name
---drop here to remove old function
DROP TYPE feature_by_cvt_type CASCADE;
DROP TYPE fxgsfids_type CASCADE;

DROP TYPE feature_by_fx_type CASCADE;
CREATE TYPE feature_by_fx_type AS (
    feature_id INTEGER,
    depth INT
);

CREATE OR REPLACE FUNCTION get_sub_feature_ids(text) RETURNS SETOF feature_by_fx_type AS
'
DECLARE
    sql alias for $1;
    myrc feature_by_fx_type%ROWTYPE;
    myrc2 feature_by_fx_type%ROWTYPE;

BEGIN
    FOR myrc IN EXECUTE sql LOOP
        FOR myrc2 IN SELECT * FROM get_sub_feature_ids(myrc.feature_id) LOOP
            RETURN NEXT myrc2;
        END LOOP;
    END LOOP;
    RETURN;
END;
'
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION get_up_feature_ids(text) RETURNS SETOF feature_by_fx_type AS
'
DECLARE
    sql alias for $1;
    myrc feature_by_fx_type%ROWTYPE;
    myrc2 feature_by_fx_type%ROWTYPE;

BEGIN
    FOR myrc IN EXECUTE sql LOOP
        FOR myrc2 IN SELECT * FROM get_up_feature_ids(myrc.feature_id) LOOP
            RETURN NEXT myrc2;
        END LOOP;
    END LOOP;
    RETURN;
END;
'
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION get_feature_ids(text) RETURNS SETOF feature_by_fx_type AS
'
DECLARE
    sql alias for $1;
    myrc feature_by_fx_type%ROWTYPE;
    myrc2 feature_by_fx_type%ROWTYPE;
    myrc3 feature_by_fx_type%ROWTYPE;

BEGIN

    FOR myrc IN EXECUTE sql LOOP
        RETURN NEXT myrc;
        FOR myrc2 IN SELECT * FROM get_up_feature_ids(myrc.feature_id) LOOP
            RETURN NEXT myrc2;
        END LOOP;
        FOR myrc3 IN SELECT * FROM get_sub_feature_ids(myrc.feature_id) LOOP
            RETURN NEXT myrc3;
        END LOOP;
    END LOOP;
    RETURN;
END;
'
LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION get_sub_feature_ids(integer) RETURNS SETOF feature_by_fx_type AS
'
DECLARE
    root alias for $1;
    myrc feature_by_fx_type%ROWTYPE;
    myrc2 feature_by_fx_type%ROWTYPE;

BEGIN
    FOR myrc IN SELECT DISTINCT subject_id AS feature_id FROM feature_relationship WHERE object_id = root LOOP
        RETURN NEXT myrc;
        FOR myrc2 IN SELECT * FROM get_sub_feature_ids(myrc.feature_id) LOOP
            RETURN NEXT myrc2;
        END LOOP;
    END LOOP;
    RETURN;
END;
'
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION get_up_feature_ids(integer) RETURNS SETOF feature_by_fx_type AS
'
DECLARE
    leaf alias for $1;
    myrc feature_by_fx_type%ROWTYPE;
    myrc2 feature_by_fx_type%ROWTYPE;
BEGIN
    FOR myrc IN SELECT DISTINCT object_id AS feature_id FROM feature_relationship WHERE subject_id = leaf LOOP
        RETURN NEXT myrc;
        FOR myrc2 IN SELECT * FROM get_up_feature_ids(myrc.feature_id) LOOP
            RETURN NEXT myrc2;
        END LOOP;
    END LOOP;
    RETURN;
END;
'
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION get_sub_feature_ids(integer, integer) RETURNS SETOF feature_by_fx_type AS
'
DECLARE
    root alias for $1;
    depth alias for $2;
    myrc feature_by_fx_type%ROWTYPE;
    myrc2 feature_by_fx_type%ROWTYPE;

BEGIN
    FOR myrc IN SELECT DISTINCT subject_id AS feature_id, depth FROM feature_relationship WHERE object_id = root LOOP
        RETURN NEXT myrc;
        FOR myrc2 IN SELECT * FROM get_sub_feature_ids(myrc.feature_id,depth+1) LOOP
            RETURN NEXT myrc2;
        END LOOP;
    END LOOP;
    RETURN;
END;
'
LANGUAGE 'plpgsql';

--- depth is reversed and meanless when union with results from get_sub_feature_ids
CREATE OR REPLACE FUNCTION get_up_feature_ids(integer, integer) RETURNS SETOF feature_by_fx_type AS
'
DECLARE
    leaf alias for $1;
    depth alias for $2;
    myrc feature_by_fx_type%ROWTYPE;
    myrc2 feature_by_fx_type%ROWTYPE;
BEGIN
    FOR myrc IN SELECT DISTINCT object_id AS feature_id, depth FROM feature_relationship WHERE subject_id = leaf LOOP
        RETURN NEXT myrc;
        FOR myrc2 IN SELECT * FROM get_up_feature_ids(myrc.feature_id,depth+1) LOOP
            RETURN NEXT myrc2;
        END LOOP;
    END LOOP;
    RETURN;
END;
'
LANGUAGE 'plpgsql';

--- children feature ids only (not include itself--parent) for SO type and range (src)
CREATE OR REPLACE FUNCTION get_sub_feature_ids_by_type_src(cvterm.name%TYPE,feature.uniquename%TYPE,char(1)) RETURNS SETOF feature_by_fx_type AS
'
DECLARE
    gtype alias for $1;
    src alias for $2;
    is_an alias for $3;
    query text;
    myrc feature_by_fx_type%ROWTYPE;
    myrc2 feature_by_fx_type%ROWTYPE;

BEGIN

    query := ''SELECT DISTINCT f.feature_id FROM feature f INNER join cvterm t ON (f.type_id = t.cvterm_id)
        INNER join featureloc fl
        ON (f.feature_id = fl.feature_id) INNER join feature src ON (src.feature_id = fl.srcfeature_id)
        WHERE t.name = '' || quote_literal(gtype) || '' AND src.uniquename = '' || quote_literal(src)
        || '' AND f.is_analysis = '' || quote_literal(is_an) || '';'';
 
    IF (STRPOS(gtype, ''%'') > 0) THEN
        query := ''SELECT DISTINCT f.feature_id FROM feature f INNER join cvterm t ON (f.type_id = t.cvterm_id)
             INNER join featureloc fl
            ON (f.feature_id = fl.feature_id) INNER join feature src ON (src.feature_id = fl.srcfeature_id)
            WHERE t.name like '' || quote_literal(gtype) || '' AND src.uniquename = '' || quote_literal(src)
            || '' AND f.is_analysis = '' || quote_literal(is_an) || '';'';
    END IF;
    FOR myrc IN SELECT * FROM get_sub_feature_ids(query) LOOP
        RETURN NEXT myrc;
    END LOOP;
    RETURN;
END;
'
LANGUAGE 'plpgsql';

--- by SO type, usefull for tRNA, ncRNA, etc
CREATE OR REPLACE FUNCTION get_feature_ids_by_type(cvterm.name%TYPE, char(1)) RETURNS SETOF feature_by_fx_type AS
'
DECLARE
    gtype alias for $1;
    is_an alias for $2;
    query TEXT;
    myrc feature_by_fx_type%ROWTYPE;
    myrc2 feature_by_fx_type%ROWTYPE;

BEGIN

    query := ''SELECT DISTINCT f.feature_id 
        FROM feature f, cvterm t WHERE t.cvterm_id = f.type_id AND t.name = '' || quote_literal(gtype) ||
        '' AND f.is_analysis = '' || quote_literal(is_an) || '';'';
    IF (STRPOS(gtype, ''%'') > 0) THEN
        query := ''SELECT DISTINCT f.feature_id 
            FROM feature f, cvterm t WHERE t.cvterm_id = f.type_id AND t.name like ''
            || quote_literal(gtype) || '' AND f.is_analysis = '' || quote_literal(is_an) || '';'';
    END IF;

    FOR myrc IN SELECT * FROM get_feature_ids(query) LOOP
        RETURN NEXT myrc;
    END LOOP;
    RETURN;
END;
'
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION get_feature_ids_by_type_src(cvterm.name%TYPE, feature.uniquename%TYPE, char(1)) RETURNS SETOF feature_by_fx_type AS
'
DECLARE
    gtype alias for $1;
    src alias for $2;
    is_an alias for $3;
    query TEXT;
    myrc feature_by_fx_type%ROWTYPE;
    myrc2 feature_by_fx_type%ROWTYPE;

BEGIN

    query := ''SELECT DISTINCT f.feature_id 
        FROM feature f INNER join cvterm t ON (f.type_id = t.cvterm_id) INNER join featureloc fl
        ON (f.feature_id = fl.feature_id) INNER join feature src ON (src.feature_id = fl.srcfeature_id)
        WHERE t.name = '' || quote_literal(gtype) || '' AND src.uniquename = '' || quote_literal(src)
        || '' AND f.is_analysis = '' || quote_literal(is_an) || '';'';
 
    IF (STRPOS(gtype, ''%'') > 0) THEN
        query := ''SELECT DISTINCT f.feature_id 
            FROM feature f INNER join cvterm t ON (f.type_id = t.cvterm_id) INNER join featureloc fl
            ON (f.feature_id = fl.feature_id) INNER join feature src ON (src.feature_id = fl.srcfeature_id)
            WHERE t.name like '' || quote_literal(gtype) || '' AND src.uniquename = '' || quote_literal(src)
            || '' AND f.is_analysis = '' || quote_literal(is_an) || '';'';
    END IF;

    FOR myrc IN SELECT * FROM get_feature_ids(query) LOOP
        RETURN NEXT myrc;
    END LOOP;
    RETURN;
END;
'
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION get_feature_ids_by_type_name(cvterm.name%TYPE, feature.uniquename%TYPE, char(1)) RETURNS SETOF feature_by_fx_type AS
'
DECLARE
    gtype alias for $1;
    name alias for $2;
    is_an alias for $3;
    query TEXT;
    myrc feature_by_fx_type%ROWTYPE;
    myrc2 feature_by_fx_type%ROWTYPE;

BEGIN

    query := ''SELECT DISTINCT f.feature_id 
        FROM feature f INNER join cvterm t ON (f.type_id = t.cvterm_id)
        WHERE t.name = '' || quote_literal(gtype) || '' AND (f.uniquename = '' || quote_literal(name)
        || '' OR f.name = '' || quote_literal(name) || '') AND f.is_analysis = '' || quote_literal(is_an) || '';'';
 
    IF (STRPOS(name, ''%'') > 0) THEN
        query := ''SELECT DISTINCT f.feature_id 
            FROM feature f INNER join cvterm t ON (f.type_id = t.cvterm_id)
            WHERE t.name = '' || quote_literal(gtype) || '' AND (f.uniquename like '' || quote_literal(name)
            || '' OR f.name like '' || quote_literal(name) || '') AND f.is_analysis = '' || quote_literal(is_an) || '';'';
    END IF;

    FOR myrc IN SELECT * FROM get_feature_ids(query) LOOP
        RETURN NEXT myrc;
    END LOOP;
    RETURN;
END;
'
LANGUAGE 'plpgsql';

--- get all feature ids (including children) for feature that has an ontology term (say GO function)
CREATE OR REPLACE FUNCTION get_feature_ids_by_ont(cv.name%TYPE,cvterm.name%TYPE) RETURNS SETOF feature_by_fx_type AS
'
DECLARE
    aspect alias for $1;
    term alias for $2;
    query TEXT;
    myrc feature_by_fx_type%ROWTYPE;
    myrc2 feature_by_fx_type%ROWTYPE;

BEGIN

    query := ''SELECT DISTINCT fcvt.feature_id 
        FROM feature_cvterm fcvt, cv, cvterm t WHERE cv.cv_id = t.cv_id AND
        t.cvterm_id = fcvt.cvterm_id AND cv.name = '' || quote_literal(aspect) ||
        '' AND t.name = '' || quote_literal(term) || '';'';
    IF (STRPOS(term, ''%'') > 0) THEN
        query := ''SELECT DISTINCT fcvt.feature_id 
            FROM feature_cvterm fcvt, cv, cvterm t WHERE cv.cv_id = t.cv_id AND
            t.cvterm_id = fcvt.cvterm_id AND cv.name = '' || quote_literal(aspect) ||
            '' AND t.name like '' || quote_literal(term) || '';'';
    END IF;

    FOR myrc IN SELECT * FROM get_feature_ids(query) LOOP
        RETURN NEXT myrc;
    END LOOP;
    RETURN;
END;
'
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION get_feature_ids_by_ont_root(cv.name%TYPE,cvterm.name%TYPE) RETURNS SETOF feature_by_fx_type AS
'
DECLARE
    aspect alias for $1;
    term alias for $2;
    query TEXT;
    subquery TEXT;
    myrc feature_by_fx_type%ROWTYPE;
    myrc2 feature_by_fx_type%ROWTYPE;

BEGIN

    subquery := ''SELECT t.cvterm_id FROM cv, cvterm t WHERE cv.cv_id = t.cv_id 
        AND cv.name = '' || quote_literal(aspect) || '' AND t.name = '' || quote_literal(term) || '';'';
    IF (STRPOS(term, ''%'') > 0) THEN
        subquery := ''SELECT t.cvterm_id FROM cv, cvterm t WHERE cv.cv_id = t.cv_id 
            AND cv.name = '' || quote_literal(aspect) || '' AND t.name like '' || quote_literal(term) || '';'';
    END IF;
    query := ''SELECT DISTINCT fcvt.feature_id 
        FROM feature_cvterm fcvt INNER JOIN (SELECT cvterm_id FROM get_it_sub_cvterm_ids('' || quote_literal(subquery) || '')) AS ont ON (fcvt.cvterm_id = ont.cvterm_id);'';

    FOR myrc IN SELECT * FROM get_feature_ids(query) LOOP
        RETURN NEXT myrc;
    END LOOP;
    RETURN;
END;
'
LANGUAGE 'plpgsql';

--- get all feature ids (including children) for feature with the property (type, val)
CREATE OR REPLACE FUNCTION get_feature_ids_by_property(cvterm.name%TYPE,varchar) RETURNS SETOF feature_by_fx_type AS
'
DECLARE
    p_type alias for $1;
    p_val alias for $2;
    query TEXT;
    myrc feature_by_fx_type%ROWTYPE;
    myrc2 feature_by_fx_type%ROWTYPE;

BEGIN

    query := ''SELECT DISTINCT fprop.feature_id 
        FROM featureprop fprop, cvterm t WHERE t.cvterm_id = fprop.type_id AND t.name = '' ||
        quote_literal(p_type) || '' AND fprop.value = '' || quote_literal(p_val) || '';'';
    IF (STRPOS(p_val, ''%'') > 0) THEN
        query := ''SELECT DISTINCT fprop.feature_id 
            FROM featureprop fprop, cvterm t WHERE t.cvterm_id = fprop.type_id AND t.name = '' ||
            quote_literal(p_type) || '' AND fprop.value like '' || quote_literal(p_val) || '';'';
    END IF;

    FOR myrc IN SELECT * FROM get_feature_ids(query) LOOP
        RETURN NEXT myrc;
    END LOOP;
    RETURN;
END;
'
LANGUAGE 'plpgsql';

--- get all feature ids (including children) for feature with the property val
CREATE OR REPLACE FUNCTION get_feature_ids_by_propval(varchar) RETURNS SETOF feature_by_fx_type AS
'
DECLARE
    p_val alias for $1;
    query TEXT;
    myrc feature_by_fx_type%ROWTYPE;
    myrc2 feature_by_fx_type%ROWTYPE;

BEGIN

    query := ''SELECT DISTINCT fprop.feature_id 
        FROM featureprop fprop WHERE fprop.value = '' || quote_literal(p_val) || '';'';
    IF (STRPOS(p_val, ''%'') > 0) THEN
        query := ''SELECT DISTINCT fprop.feature_id 
            FROM featureprop fprop WHERE fprop.value like '' || quote_literal(p_val) || '';'';
    END IF;

    FOR myrc IN SELECT * FROM get_feature_ids(query) LOOP
        RETURN NEXT myrc;
    END LOOP;
    RETURN;
END;
'
LANGUAGE 'plpgsql';


---4 args: ptype, ctype, count, operator (valid SQL number comparison operator), and is_analysis 
---get feature ids for any node with type = ptype whose child node type = ctype
---and child node feature count comparing (using operator) to ccount
CREATE OR REPLACE FUNCTION get_feature_ids_by_child_count(cvterm.name%TYPE, cvterm.name%TYPE, INTEGER, varchar, char(1)) RETURNS SETOF feature_by_fx_type AS
'
DECLARE
    ptype alias for $1;
    ctype alias for $2;
    ccount alias for $3;
    operator alias for $4;
    is_an alias for $5;
    query TEXT;
    myrc feature_by_fx_type%ROWTYPE;
    myrc2 feature_by_fx_type %ROWTYPE;

BEGIN

    query := ''SELECT DISTINCT f.feature_id
        FROM feature f INNER join (select count(*) as c, p.feature_id FROM feature p
        INNER join cvterm pt ON (p.type_id = pt.cvterm_id) INNER join feature_relationship fr
        ON (p.feature_id = fr.object_id) INNER join feature c ON (c.feature_id = fr.subject_id)
        INNER join cvterm ct ON (c.type_id = ct.cvterm_id)
        WHERE pt.name = '' || quote_literal(ptype) || '' AND ct.name = '' || quote_literal(ctype)
        || '' AND p.is_analysis = '' || quote_literal(is_an) || '' group by p.feature_id) as cq
        ON (cq.feature_id = f.feature_id) WHERE cq.c '' || operator || ccount || '';'';
    ---RAISE NOTICE ''%'', query; 

    FOR myrc IN SELECT * FROM get_feature_ids(query) LOOP
        RETURN NEXT myrc;
    END LOOP;
    RETURN;
END;
'
LANGUAGE 'plpgsql';
-- ================================================
-- TABLE: analysis
-- ================================================

-- an analysis is a particular type of a computational analysis;
-- it may be a blast of one sequence against another, or an all by all
-- blast, or a different kind of analysis altogether.
-- it is a single unit of computation 
--
-- name: 
--   a way of grouping analyses. this should be a handy
--   short identifier that can help people find an analysis they
--   want. for instance "tRNAscan", "cDNA", "FlyPep", "SwissProt"
--   it should not be assumed to be unique. for instance, there may
--   be lots of seperate analyses done against a cDNA database.
--
-- program: 
--   e.g. blastx, blastp, sim4, genscan
--
-- programversion:
--   e.g. TBLASTX 2.0MP-WashU [09-Nov-2000]
--
-- algorithm:
--   e.g. blast
--
-- sourcename: 
--   e.g. cDNA, SwissProt
--
-- queryfeature_id:
--   the sequence that was used as the query sequence can be
--   optionally included via queryfeature_id - even though this
--   is redundant with the tables below. this can still
--   be useful - for instance, we may have an analysis that blasts
--   contigs against a database. we may then transform those hits
--   into global coordinates; it may be useful to keep a record
--   of which contig was blasted as the query.
--
--
-- MAPPING (bioperl): maps to Bio::Search::Result::ResultI
-- ** not anymore, b/c we are using analysis in a more general sense
-- ** to represent microarray analysis

--
-- sourceuri: 
--   This is an optional permanent URL/URI for the source of the
--   analysis. The idea is that someone could recreate the analysis
--   directly by going to this URI and fetching the source data
--   (eg the blast database, or the training model).

create table analysis (
    analysis_id serial not null,
    primary key (analysis_id),
    name varchar(255),
    description text,
    program varchar(255) not null,
    programversion varchar(255) not null,
    algorithm varchar(255),
    sourcename varchar(255),
    sourceversion varchar(255),
    sourceuri text,
    timeexecuted timestamp not null default current_timestamp,
    constraint analysis_c1 unique (program,programversion,sourcename)
);

-- ================================================
-- TABLE: analysisprop
-- ================================================

create table analysisprop (
    analysisprop_id serial not null,
    primary key (analysisprop_id),
    analysis_id int not null,
    foreign key (analysis_id) references analysis (analysis_id) on delete cascade INITIALLY DEFERRED,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    value text,
    constraint analysisprop_c1 unique (analysis_id,type_id,value)
);
create index analysisprop_idx1 on analysisprop (analysis_id);
create index analysisprop_idx2 on analysisprop (type_id);

-- ================================================
-- TABLE: analysisfeature
-- ================================================

-- computational analyses generate features (eg genscan generates
-- transcripts and exons; sim4 alignments generate similarity/match
-- features)

-- analysisfeatures are stored using the feature table from
-- the sequence module. the analysisfeature table is used to
-- decorate these features, with analysis specific attributes.
--
-- a feature is an analysisfeature if and only if there is
-- a corresponding entry in the analysisfeature table
--
-- analysisfeatures will have two or more featureloc entries,
-- with rank indicating query/subject

--  analysis_id:
--    scoredsets are grouped into analyses
--
--  rawscore:
--    this is the native score generated by the program; for example,
--    the bitscore generated by blast, sim4 or genscan scores.
--    one should not assume that high is necessarily better than low.
--
--  normscore:
--    this is the rawscore but semi-normalized. complete normalization
--    to allow comparison of features generated by different programs
--    would be nice but too difficult. instead the normalization should
--    strive to enforce the following semantics:
--
--    * normscores are floating point numbers >= 0
--    * high normscores are better than low one.
--
--    for most programs, it would be sufficient to make the normscore
--    the same as this rawscore, providing these semantics are
--    satisfied.
--
--  significance:
--    this is some kind of expectation or probability metric,
--    representing the probability that the scoredset would appear
--    randomly given the model.
--    as such, any program or person querying this table can assume
--    the following semantics:
--     * 0 <= significance <= n, where n is a positive number, theoretically
--       unbounded but unlikely to be more than 10
--     * low numbers are better than high numbers.
--
--  identity:
--    percent identity between the locations compared
--
--  note that these 4 metrics do not cover the full range of scores
--  possible; it would be undesirable to list every score possible, as
--  this should be kept extensible. instead, for non-standard scores, use
--  the scoredsetprop table.

create table analysisfeature (
    analysisfeature_id serial not null,
    primary key (analysisfeature_id),
    feature_id int not null,
    foreign key (feature_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,
    analysis_id int not null,
    foreign key (analysis_id) references analysis (analysis_id) on delete cascade INITIALLY DEFERRED,
    rawscore double precision,
    normscore double precision,
    significance double precision,
    identity double precision,
    constraint analysisfeature_c1 unique (feature_id,analysis_id)
);
create index analysisfeature_idx1 on analysisfeature (feature_id);
create index analysisfeature_idx2 on analysisfeature (analysis_id);

CREATE OR REPLACE FUNCTION store_analysis (VARCHAR,VARCHAR,VARCHAR) 
  RETURNS INT AS 
'DECLARE
   v_program            ALIAS FOR $1;
   v_programversion     ALIAS FOR $2;
   v_sourcename         ALIAS FOR $3;
   pkval                INTEGER;
 BEGIN
    SELECT INTO pkval analysis_id
      FROM analysis
      WHERE program=v_program AND
            programversion=v_programversion AND
            sourcename=v_sourcename;
    IF NOT FOUND THEN
      INSERT INTO analysis 
       (program,programversion,sourcename)
         VALUES
       (v_program,v_programversion,v_sourcename);
      RETURN currval(''analysis_analysis_id_seq'');
    END IF;
    RETURN pkval;
 END;
' LANGUAGE 'plpgsql';

--CREATE OR REPLACE FUNCTION store_analysisfeature
--()
--RETURNS INT AS
--'DECLARE
--  v_srcfeature_id       ALIAS FOR $1;
  

CREATE TABLE phenotype (
    phenotype_id SERIAL NOT NULL,
    primary key (phenotype_id),
    uniquename TEXT NOT NULL,  
    observable_id INT,
    FOREIGN KEY (observable_id) REFERENCES cvterm (cvterm_id) ON DELETE CASCADE,
    attr_id INT,
    FOREIGN KEY (attr_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL,
    value TEXT,
    cvalue_id INT,
    FOREIGN KEY (cvalue_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL,
    assay_id INT,
    FOREIGN KEY (assay_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL,
    CONSTRAINT phenotype_c1 UNIQUE (uniquename)
);
CREATE INDEX phenotype_idx1 ON phenotype (cvalue_id);
CREATE INDEX phenotype_idx2 ON phenotype (observable_id);
CREATE INDEX phenotype_idx3 ON phenotype (attr_id);

COMMENT ON TABLE phenotype IS 'a phenotypic statement, or a single atomic phenotypic observation a controlled sentence describing observable effect of non-wt function -- e.g. Obs=eye, attribute=color, cvalue=red';

COMMENT ON COLUMN phenotype.observable_id IS 'The entity: e.g. anatomy_part, biological_process';
COMMENT ON COLUMN phenotype.attr_id IS 'Phenotypic attribute (quality, property, attribute, character) - drawn from PATO';
COMMENT ON COLUMN phenotype.value IS 'value of attribute - unconstrained free text. Used only if cvalue_id is not appropriate';
COMMENT ON COLUMN phenotype.cvalue_id IS 'Phenotype attribute value (state)';
COMMENT ON COLUMN phenotype.assay_id IS 'evidence type';

CREATE TABLE phenotype_cvterm (
    phenotype_cvterm_id SERIAL NOT NULL,
    primary key (phenotype_cvterm_id),
    phenotype_id INT NOT NULL,
    FOREIGN KEY (phenotype_id) REFERENCES phenotype (phenotype_id) ON DELETE CASCADE,
    cvterm_id INT NOT NULL,
    FOREIGN KEY (cvterm_id) REFERENCES cvterm (cvterm_id) ON DELETE CASCADE,
    CONSTRAINT phenotype_cvterm_c1 UNIQUE (phenotype_id, cvterm_id)
);
CREATE INDEX phenotype_cvterm_idx1 ON phenotype_cvterm (phenotype_id);
CREATE INDEX phenotype_cvterm_idx2 ON phenotype_cvterm (cvterm_id);

COMMENT ON TABLE phenotype_cvterm IS NULL;

 
CREATE TABLE feature_phenotype (
    feature_phenotype_id SERIAL NOT NULL,
    primary key (feature_phenotype_id),
    feature_id INT NOT NULL,
    FOREIGN KEY (feature_id) REFERENCES feature (feature_id) ON DELETE CASCADE,
    phenotype_id INT NOT NULL,
    FOREIGN KEY (phenotype_id) REFERENCES phenotype (phenotype_id) ON DELETE CASCADE,
    CONSTRAINT feature_phenotype_c1 UNIQUE (feature_id,phenotype_id)       
);
CREATE INDEX feature_phenotype_idx1 ON feature_phenotype (feature_id);
CREATE INDEX feature_phenotype_idx2 ON feature_phenotype (phenotype_id);

COMMENT ON TABLE feature_phenotype IS NULL;


-- ==========================================
-- Chado genetics module
--
-- 2006-04-11
--   split out phenotype tables into phenotype module
--
-- redesigned 2003-10-28
--
-- changes 2003-11-10:
--   incorporating suggestions to make everything a gcontext; use 
--   gcontext_relationship to make some gcontexts derivable from others. we 
--   would incorporate environment this way - just add the environment 
--   descriptors as properties of the child gcontext
--
-- changes 2004-06 (Documented by DE: 10-MAR-2005):
--   Many, including rename of gcontext to genotype,  split 
--   phenstatement into phenstatement & phenotype, created environment
--
-- see doc/genetic-notes.txt
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ============
-- DEPENDENCIES
-- ============
-- :import feature from sequence
-- :import phenotype from phenotype
-- :import cvterm from cv
-- :import pub from pub
-- :import dbxref from general
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


-- ================================================
-- TABLE: genotype
-- ================================================
-- genetic context
-- the uniquename should be derived from the features
-- making up the genoptype
--
-- uniquename: a human-readable unique identifier
--
create table genotype (
    genotype_id serial not null,
    primary key (genotype_id),
    uniquename text not null,      
    description varchar(255),
    constraint genotype_c1 unique (uniquename)
);
create index genotype_idx1 on genotype(uniquename);

COMMENT ON TABLE genotype IS NULL;


-- ===============================================
-- TABLE: feature_genotype
-- ================================================
-- A genotype is defined by a collection of features
-- mutations, balancers, deficiencies, haplotype blocks, engineered
-- constructs
-- 
-- rank can be used for n-ploid organisms
-- 
-- group can be used for distinguishing the chromosomal groups
-- 
-- (RNAi products and so on can be treated as different groups, as
-- they do not fall on a particular chromosome)
-- 
-- OPEN QUESTION: for multicopy transgenes, should we include a 'n_copies'
-- column as well?
-- 
-- chromosome_id       : a feature of SO type 'chromosome'
-- rank                : preserves order
-- group               : spatially distinguishable group
--
create table feature_genotype (
    feature_genotype_id serial not null,
    primary key (feature_genotype_id),
    feature_id int not null,
    foreign key (feature_id) references feature (feature_id) on delete cascade,
    genotype_id int not null,
    foreign key (genotype_id) references genotype (genotype_id) on delete cascade,
    chromosome_id int,
    foreign key (chromosome_id) references feature (feature_id) on delete set null,
    rank int not null,
    cgroup    int not null,
    cvterm_id int not null,
    foreign key (cvterm_id) references cvterm (cvterm_id) on delete cascade,
    constraint feature_genotype_c1 unique (feature_id, genotype_id, cvterm_id, chromosome_id, rank, cgroup)
);
create index feature_genotype_idx1 on feature_genotype (feature_id);
create index feature_genotype_idx2 on feature_genotype (genotype_id);

COMMENT ON TABLE feature_genotype IS NULL;



-- ================================================
-- TABLE: environment
-- ================================================
-- The environmental component of a phenotype description
create table environment (
    environment_id serial not NULL,
    primary key  (environment_id),
    uniquename text not null,
    description text,
    constraint environment_c1 unique (uniquename)
);
create index environment_idx1 on environment(uniquename);

COMMENT ON TABLE environment IS NULL;


-- ================================================
-- TABLE: environment_cvterm
-- ================================================
create table environment_cvterm (
    environment_cvterm_id serial not null,
    primary key  (environment_cvterm_id),
    environment_id int not null,
    foreign key (environment_id) references environment (environment_id) on delete cascade,
    cvterm_id int not null,
    foreign key (cvterm_id) references cvterm (cvterm_id) on delete cascade,
    constraint environment_cvterm_c1 unique (environment_id, cvterm_id)
);
create index environment_cvterm_idx1 on environment_cvterm (environment_id);
create index environment_cvterm_idx2 on environment_cvterm (cvterm_id);

COMMENT ON TABLE environment_cvterm IS NULL;

CREATE TABLE phenstatement (
    phenstatement_id SERIAL NOT NULL,
    primary key (phenstatement_id),
    genotype_id INT NOT NULL,
    FOREIGN KEY (genotype_id) REFERENCES genotype (genotype_id) ON DELETE CASCADE,
    environment_id INT NOT NULL,
    FOREIGN KEY (environment_id) REFERENCES environment (environment_id) ON DELETE CASCADE,
    phenotype_id INT NOT NULL,
    FOREIGN KEY (phenotype_id) REFERENCES phenotype (phenotype_id) ON DELETE CASCADE,
    type_id INT NOT NULL,
    FOREIGN KEY (type_id) REFERENCES cvterm (cvterm_id) ON DELETE CASCADE,
    pub_id INT NOT NULL,
    FOREIGN KEY (pub_id) REFERENCES pub (pub_id) ON DELETE CASCADE,
    CONSTRAINT phenstatement_c1 UNIQUE (genotype_id,phenotype_id,environment_id,type_id,pub_id)
);
CREATE INDEX phenstatement_idx1 ON phenstatement (genotype_id);
CREATE INDEX phenstatement_idx2 ON phenstatement (phenotype_id);

COMMENT ON TABLE phenstatement IS 'Phenotypes are things like "larval lethal".  Phenstatements are things like "dpp[1] is recessive larval lethal". So essentially phenstatement is a linking table expressing the relationship between genotype, environment, and phenotype.';

CREATE TABLE phendesc (
    phendesc_id SERIAL NOT NULL,
    primary key (phendesc_id),
    genotype_id INT NOT NULL,
    FOREIGN KEY (genotype_id) REFERENCES genotype (genotype_id) ON DELETE CASCADE,
    environment_id INT NOT NULL,
    FOREIGN KEY (environment_id) REFERENCES environment ( environment_id) ON DELETE CASCADE,
    description TEXT NOT NULL,
    pub_id INT NOT NULL,
    FOREIGN KEY (pub_id) REFERENCES pub (pub_id) ON DELETE CASCADE,
    CONSTRAINT phendesc_c1 UNIQUE (genotype_id,environment_id,pub_id)
);
CREATE INDEX phendesc_idx1 ON phendesc (genotype_id);
CREATE INDEX phendesc_idx2 ON phendesc (environment_id);
CREATE INDEX phendesc_idx3 ON phendesc (pub_id);

COMMENT ON TABLE phendesc IS 'a summary of a _set_ of phenotypic statements for any one gcontext made in any one publication';

CREATE TABLE phenotype_comparison (
    phenotype_comparison_id SERIAL NOT NULL,
    primary key (phenotype_comparison_id),
    genotype1_id INT NOT NULL,
        FOREIGN KEY (genotype1_id) REFERENCES genotype (genotype_id) ON DELETE CASCADE,
    environment1_id INT NOT NULL,
        FOREIGN KEY (environment1_id) REFERENCES environment (environment_id) ON DELETE CASCADE,
    genotype2_id INT NOT NULL,
        FOREIGN KEY (genotype2_id) REFERENCES genotype (genotype_id) ON DELETE CASCADE,
    environment2_id INT NOT NULL,
        FOREIGN KEY (environment2_id) REFERENCES environment (environment_id) ON DELETE CASCADE,
    phenotype1_id INT NOT NULL,
        FOREIGN KEY (phenotype1_id) REFERENCES phenotype (phenotype_id) ON DELETE CASCADE,
    phenotype2_id INT,
        FOREIGN KEY (phenotype2_id) REFERENCES phenotype (phenotype_id) ON DELETE CASCADE,
    type_id INT NOT NULL,
        FOREIGN KEY (type_id) REFERENCES cvterm (cvterm_id) ON DELETE CASCADE,
    pub_id INT NOT NULL,
    FOREIGN KEY (pub_id) REFERENCES pub (pub_id) ON DELETE CASCADE,
    CONSTRAINT phenotype_comparison_c1 UNIQUE (genotype1_id,environment1_id,genotype2_id,environment2_id,phenotype1_id,type_id,pub_id)
);

COMMENT ON TABLE phenotype_comparison IS 'comparison of phenotypes eg, genotype1/environment1/phenotype1 "non-suppressible" wrt  genotype2/environment2/phenotype2';
-- NOTE: this module is all due for revision...

-- A possibly problematic case is where we want to localize an object
-- to the left or right of a feature (but not within it):
--
--                     |---------|  feature-to-map
--        ------------------------------------------------- map
--                |------|         |----------|   features to map wrt
--
-- How do we map the 3' end of the feature-to-map?

-- TODO:  Get a comprehensive set of mapping use-cases 

-- one set of use-cases is aberrations (which will all be involved with this 
-- module).   Simple aberrations should be do-able, but what about cases where
-- a breakpoint interrupts a gene?  This would be an example of the problematic
-- case above...  (or?)

-- ================================================
-- TABLE: featuremap
-- ================================================

create table featuremap (
    featuremap_id serial not null,
    primary key (featuremap_id),
    name varchar(255),
    description text,
    unittype_id int null,
    foreign key (unittype_id) references cvterm (cvterm_id) on delete set null INITIALLY DEFERRED,
    constraint featuremap_c1 unique (name)
);

-- ================================================
-- TABLE: featurerange
-- ================================================

-- In cases where the start and end of a mapped feature is a range, leftendf
-- and rightstartf are populated.  
-- featuremap_id is the id of the feature being mapped
-- leftstartf_id, leftendf_id, rightstartf_id, rightendf_id are the ids of
-- features with respect to with the feature is being mapped.  These may
-- be cytological bands.

create table featurerange (
    featurerange_id serial not null,
    primary key (featurerange_id),
    featuremap_id int not null,
    foreign key (featuremap_id) references featuremap (featuremap_id) on delete cascade INITIALLY DEFERRED,
    feature_id int not null,
    foreign key (feature_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,
    leftstartf_id int not null,
    foreign key (leftstartf_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,
    leftendf_id int,
    foreign key (leftendf_id) references feature (feature_id) on delete set null INITIALLY DEFERRED,
    rightstartf_id int,
    foreign key (rightstartf_id) references feature (feature_id) on delete set null INITIALLY DEFERRED,
    rightendf_id int not null,
    foreign key (rightendf_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,
    rangestr varchar(255)
);
create index featurerange_idx1 on featurerange (featuremap_id);
create index featurerange_idx2 on featurerange (feature_id);
create index featurerange_idx3 on featurerange (leftstartf_id);
create index featurerange_idx4 on featurerange (leftendf_id);
create index featurerange_idx5 on featurerange (rightstartf_id);
create index featurerange_idx6 on featurerange (rightendf_id);

-- ================================================
-- TABLE: featurepos
-- ================================================

create table featurepos (
    featurepos_id serial not null,
    primary key (featurepos_id),
    featuremap_id serial not null,
    foreign key (featuremap_id) references featuremap (featuremap_id) on delete cascade INITIALLY DEFERRED,
    feature_id int not null,
    foreign key (feature_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,
    map_feature_id int not null,
    foreign key (map_feature_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,
    mappos float not null
);
-- map_feature_id links to the feature (map) upon which the feature is
-- being localized
create index featurepos_idx1 on featurepos (featuremap_id);
create index featurepos_idx2 on featurepos (feature_id);
create index featurepos_idx3 on featurepos (map_feature_id);


-- ================================================
-- TABLE: featuremap_pub
-- ================================================

create table featuremap_pub (
    featuremap_pub_id serial not null,
    primary key (featuremap_pub_id),
    featuremap_id int not null,
    foreign key (featuremap_id) references featuremap (featuremap_id) on delete cascade INITIALLY DEFERRED,
    pub_id int not null,
    foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED
);
create index featuremap_pub_idx1 on featuremap_pub (featuremap_id);
create index featuremap_pub_idx2 on featuremap_pub (pub_id);





-- $Id: default_schema.sql,v 1.40 2006-04-12 03:19:11 scottcain Exp $
-- ==========================================
-- Chado phylogenetics module
--
-- Richard Bruskiewich
-- Chris Mungall
--
-- nested set tree implementation by way of Joe Celko;
-- see the excellent intro by Aaron Mackey here
-- http://www.oreillynet.com/pub/a/network/2002/11/27/bioconf.html
-- 
-- Initial design: 2004-05-27
--
-- For representing phylogenetic trees; the trees represent the
-- phylogeny of some some kind of sequence feature (mainly proteins)
-- or actual organism taxonomy trees
--
-- This module relies heavily on the sequence module
-- in particular, all the leaf nodes in a tree correspond to features;
-- these will usually be features of type SO:protein or SO:polypeptide
-- (but other trees are possible - eg intron trees)
--
-- if it is desirable to store multiple alignments for each non-leaf node,
-- then each node can be mapped to a feature of type SO:match
-- refer to the sequence module docs for details on storing multiple alignments 
--
-- Annotating nodes:
-- Each node can have a feature attached; this 'feature' is the multiple
-- alignment for non-leaf nodes. It is these features that are annotated
-- rather than annotating the nodes themselves. This has lots of advantages -
-- we can piggyback off of the sequence module and reuse the tables there
--
-- the leaf nodes may have annotations already attached - for example, GO
-- associations
--
-- In fact, it is even possible to annotate ranges along an alignment -
-- this would entail creating a new feature which has a featureloc on
-- the alignment feature
--
-- ==========================================
--
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ============
-- DEPENDENCIES
-- ============
-- :import feature from sequence
-- :import cvterm from cv
-- :import pub from pub
-- :import organism from organism
-- :import dbxref from general
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ============
-- RELATIONS
-- ============

-- ================================================
-- TABLE: phylotree
--        Global anchor for phylogenetic tree
-- ================================================

create table phylotree (
	phylotree_id serial not null,
	primary key (phylotree_id),

        dbxref_id int not null,
        foreign key (dbxref_id) references dbxref (dbxref_id) on delete cascade,
	name varchar(255) null,

-- type: protein, nucleotide, taxonomy, ???
-- the type should be any SO type, or "taxonomy"
	type_id int,
	foreign key(type_id) references cvterm (cvterm_id) on delete cascade,

-- REMOVED BY cjm; this is implicit from indexing - see phylonode
-- (and besides, we get into problems with cyclical foreign keys)
--	root_phylonode_id int not null,
--	foreign key (root_phylonode_id) references phylonode (phylonode_id) on delete cascade,

	comment text null,

	unique(phylotree_id)
);
create index phylotree_idx1 on phylotree (phylotree_id);

-- ================================================
-- TABLE: phylotree_pub
--        Tracks citations global to the tree
--        e.g. multiple sequence alignment
--        supporting tree construction
-- ================================================

create table phylotree_pub (
       phylotree_pub_id serial not null,
       primary key (phylotree_pub_id),

       phylotree_id int not null,
       foreign key (phylotree_id) references phylotree (phylotree_id) on delete cascade,
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id) on delete cascade,

       unique(phylotree_id, pub_id)
);
create index phylotree_pub_idx1 on phylotree_pub (phylotree_id);
create index phylotree_pub_idx2 on phylotree_pub (pub_id);

-- ================================================
-- TABLE: phylonode
--        This is the most pervasive element in the
--        phylogeny module, cataloging the 'phylonodes'
--        of tree graphs. Edges are implied
--        by the parent_phylonode_id reflexive closure
-- ================================================

create table phylonode (
       phylonode_id serial not null,
       primary key (phylonode_id),

       phylotree_id int not null,
       foreign key (phylotree_id) references phylotree (phylotree_id) on delete cascade,

-- root phylonode can have null parent_phylonode_id value
       parent_phylonode_id int null,
       foreign key (parent_phylonode_id) references phylonode (phylonode_id) on delete cascade,

-- nested set implementation
-- for all nodes, the left and right index will be *between* the parents
-- left and right indexes
       left_idx int not null,
       right_idx int not null,

-- type: root, interior, leaf
       type_id int,
       foreign key(type_id) references cvterm (cvterm_id) on delete cascade,

--     phylonodes can have optional features attached to them
--        e.g. a protein or nucleotide sequence
--        usually attached to a leaf of the phylotree
--        for non-leaf nodes, the feature may be
--        a feature that is an instance of SO:match;
--        this feature is the alignment of all leaf
--        features beneath it
       feature_id int,
       foreign key (feature_id) references feature (feature_id) on delete cascade,

       label varchar(255) null,
       distance float  null,
--       bootstrap float null,

       unique(phylotree_id, left_idx),
       unique(phylotree_id, right_idx)
);

-- ================================================
-- TABLE: phylonode_dbxref
--        e.g. for orthology, paralogy group identifiers;
--        could also be used for NCBI taxonomy;
--        for sequences, refer to 'phylonode_feature' 
--        feature associated dbxrefs
-- ================================================

create table phylonode_dbxref (
       phylonode_dbxref_id serial not null,
       primary key (phylonode_dbxref_id),

       phylonode_id int not null,
       foreign key (phylonode_id) references phylonode (phylonode_id) on delete cascade,
       dbxref_id int not null,
       foreign key (dbxref_id) references dbxref (dbxref_id) on delete cascade,

       unique(phylonode_id,dbxref_id)
);
create index phylonode_dbxref_idx1 on phylonode_dbxref (phylonode_id);
create index phylonode_dbxref_idx2 on phylonode_dbxref (dbxref_id);

-- ================================================
-- TABLE: phylonode_pub
-- ================================================

create table phylonode_pub (
       phylonode_pub_id serial not null,
       primary key (phylonode_pub_id),

       phylonode_id int not null,
       foreign key (phylonode_id) references phylonode (phylonode_id) on delete cascade,
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id) on delete cascade,

       unique(phylonode_id, pub_id)
);
create index phylonode_pub_idx1 on phylonode_pub (phylonode_id);
create index phylonode_pub_idx2 on phylonode_pub (pub_id);

-- ================================================
-- TABLE: phylonode_organism
--        this linking table should only be used
--        for nodes in taxonomy trees; it provides
--        a mapping between the node and an organism
--
--        one node can have zero or one organisms
--        one organism can have zero or more nodes
--        (although typically it should only have one,
--         in the standard NCBI taxonomy tree. should we
--         enforce one only, or allow competing taxonomy trees?)
-- ================================================

create table phylonode_organism (
       phylonode_organism_id serial not null,
       primary key (phylonode_organism_id),

       phylonode_id int not null,
       foreign key (phylonode_id) references phylonode (phylonode_id) on delete cascade,
       organism_id int not null,
       foreign key (organism_id) references organism (organism_id) on delete cascade,

       unique(phylonode_id)
-- one phylonode cannot refer to >1 organism
);
create index phylonode_organism_idx1 on phylonode_organism (phylonode_id);
create index phylonode_organism_idx2 on phylonode_organism (organism_id);

-- ================================================
-- TABLE: phylonodeprop
-- e.g. "type_id" could designate phylonode hierarchy
--       relationships, for example: species taxonomy 
--       (kingdom, order, family, genus, species),
--      "ortholog/paralog", "fold/superfold", etc.
-- ================================================

create table phylonodeprop (
       phylonodeprop_id serial not null,
       primary key (phylonodeprop_id),

       phylonode_id int not null,
       foreign key (phylonode_id) references phylonode (phylonode_id) on delete cascade,
       type_id int not null,
       foreign key (type_id) references cvterm (cvterm_id) on delete cascade,

       value text not null default '',
-- not sure how useful the rank concept is here, but I'll leave it in for now
       rank int not null default 0,

       unique(phylonode_id, type_id, value, rank)
);
create index phylonodeprop_idx1 on phylonodeprop (phylonode_id);
create index phylonodeprop_idx2 on phylonodeprop (type_id);

-- ================================================
-- TABLE: phylonode_relationship
--        this is for exotic relationships that are
--        not strictly hierarchical; for example,
--        horizontal gene transfer
--
--        use of this table would be highly unusual;
--        most phylogenetic trees are strictly
--        hierarchical.
--        nevertheless, it is here for completion
-- ================================================

create table phylonode_relationship (
       phylonode_relationship_id serial not null,
       primary key (phylonode_relationship_id),

       subject_id int not null,
       foreign key (subject_id) references phylonode (phylonode_id) on delete cascade,
       object_id int not null,
       foreign key (object_id) references phylonode (phylonode_id) on delete cascade,
       type_id int not null,
       foreign key (type_id) references cvterm (cvterm_id) on delete cascade,
       rank int,

       unique(subject_id, object_id, type_id)
);
create index phylonode_relationship_idx1 on phylonode_relationship (subject_id);
create index phylonode_relationship_idx2 on phylonode_relationship (object_id);
create index phylonode_relationship_idx3 on phylonode_relationship (type_id);

CREATE OR REPLACE FUNCTION phylonode_depth(INT)
 RETURNS FLOAT AS
 'DECLARE  id    ALIAS FOR $1;
  DECLARE  depth FLOAT := 0;
  DECLARE  curr_node phylonode%ROWTYPE;
  BEGIN
   SELECT INTO curr_node *
    FROM phylonode 
    WHERE phylonode_id=id;
   depth = depth + curr_node.distance;
   IF curr_node.parent_phylonode_id IS NULL
    THEN RETURN depth;
    ELSE RETURN depth + phylonode_depth(curr_node.parent_phylonode_id);
   END IF;
 END
'
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION phylonode_height(INT)
 RETURNS FLOAT AS
'
  SELECT coalesce(max(phylonode_height(phylonode_id) + distance), 0.0)
    FROM phylonode
    WHERE parent_phylonode_id = $1
'
LANGUAGE 'sql';

-- ================================================
-- TABLE: contact
-- ================================================
create table contact (
    contact_id serial not null,
    primary key (contact_id),
    type_id int null,
    foreign key (type_id) references cvterm (cvterm_id),
    name varchar(255) not null,
    description varchar(255) null,
    constraint contact_c1 unique (name)
);
COMMENT ON TABLE contact IS 'model persons, institutes, groups, organizations, etc';
COMMENT ON COLUMN contact.type_id IS 'what type of contact is this?  e.g. "person", "lab", etc.';

-- ================================================
-- TABLE: contact_relationship
-- ================================================
create table contact_relationship (
    contact_relationship_id serial not null,
    primary key (contact_relationship_id),
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    subject_id int not null,
    foreign key (subject_id) references contact (contact_id) on delete cascade INITIALLY DEFERRED,
    object_id int not null,
    foreign key (object_id) references contact (contact_id) on delete cascade INITIALLY DEFERRED,
    constraint contact_relationship_c1 unique (subject_id,object_id,type_id)
);
create index contact_relationship_idx1 on contact_relationship (type_id);
create index contact_relationship_idx2 on contact_relationship (subject_id);
create index contact_relationship_idx3 on contact_relationship (object_id);

COMMENT ON TABLE contact_relationship IS 'model relationships between contacts';
COMMENT ON COLUMN contact_relationship.subject_id IS 'the subject of the subj-predicate-obj sentence. In a DAG, this corresponds to the child node';
COMMENT ON COLUMN contact_relationship.object_id IS 'the object of the subj-predicate-obj sentence. In a DAG, this corresponds to the parent node';
COMMENT ON COLUMN contact_relationship.type_id IS 'relationship type between subject and object. This is a cvterm, typically from the OBO relationship ontology, although other relationship types are allowed';

-- This module is totally dependant on the sequence module.  Objects in the
-- genetic module cannot connect to expression data except by going via the
-- sequence module

-- We assume that we'll *always* have a controlled vocabulary for expression 
-- data.   If an experiment used a set of cv terms different from the ones
-- FlyBase uses (bodypart cv, bodypart qualifier cv, and the temporal cv
-- (which is stored in the curaton.doc under GAT6 btw)), they'd have to give
-- us the cv terms, which we could load into the cv module

-- ================================================
-- TABLE: expression
-- ================================================

create table expression (
       expression_id serial not null,
       primary key (expression_id),
       description text
);

-- ================================================
-- TABLE: feature_expression
-- ================================================

create table feature_expression (
       feature_expression_id serial not null,
       primary key (feature_expression_id),
       expression_id int not null,
       foreign key (expression_id) references expression (expression_id) on delete cascade INITIALLY DEFERRED,
       feature_id int not null,
       foreign key (feature_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,

       unique(expression_id,feature_id)       
);
create index feature_expression_idx1 on feature_expression (expression_id);
create index feature_expression_idx2 on feature_expression (feature_id);


-- ================================================
-- TABLE: expression_cvterm
-- ================================================

-- What are the possibities of combination when more than one cvterm is used
-- in a field?   
--
-- For eg (in <p> here):   <t> E | early <a> <p> anterior & dorsal
-- If the two terms used in a particular field are co-equal (both from the
-- same CV, is the relation always "&"?   May we find "or"?
--
-- Obviously another case is when a bodypart term and a bodypart qualifier
-- term are used in a specific field, eg:
--   <t> L | third instar <a> larval antennal segment sensilla | subset <p  
--
-- WRT the three-part <t><a><p> statements, are the values in the different 
-- parts *always* from different vocabularies in proforma.CV?   If not,
-- we'll need to have some kind of type qualifier telling us whether the
-- cvterm used is <t>, <a>, or <p>
-- yes we should have a type qualifier as a cv term can be from diff vocab
-- e.g. blastoderm can be body part and stage terms in dros anatomy
-- but cvterm_type needs to be a cv instead of a free text type here?

create table expression_cvterm (
       expression_cvterm_id serial not null,
       primary key (expression_cvterm_id),
       expression_id int not null,
       foreign key (expression_id) references expression (expression_id) on delete cascade INITIALLY DEFERRED,
       cvterm_id int not null,
       foreign key (cvterm_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
       rank int not null,
	   cvterm_type varchar(255),

       unique(expression_id,cvterm_id)
);
create index expression_cvterm_idx1 on expression_cvterm (expression_id);
create index expression_cvterm_idx2 on expression_cvterm (cvterm_id);


-- ================================================
-- TABLE: expression_pub
-- ================================================

create table expression_pub (
       expression_pub_id serial not null,
       primary key (expression_pub_id),
       expression_id int not null,
       foreign key (expression_id) references expression (expression_id) on delete cascade INITIALLY DEFERRED,
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,

       unique(expression_id,pub_id)       
);
create index expression_pub_idx1 on expression_pub (expression_id);
create index expression_pub_idx2 on expression_pub (pub_id);


-- ================================================
-- TABLE: eimage
-- ================================================

create table eimage (
       eimage_id serial not null,
       primary key (eimage_id),
       eimage_data text,
       eimage_type varchar(255) not null,
       image_uri varchar(255)
);
-- we expect images in eimage_data (eg jpegs) to be uuencoded
-- describes the type of data in eimage_data


-- ================================================
-- TABLE: expression_image
-- ================================================

create table expression_image (
       expression_image_id serial not null,
       primary key (expression_image_id),
       expression_id int not null,
       foreign key (expression_id) references expression (expression_id) on delete cascade INITIALLY DEFERRED,
       eimage_id int not null,
       foreign key (eimage_id) references eimage (eimage_id) on delete cascade INITIALLY DEFERRED,

       unique(expression_id,eimage_id)
);
create index expression_image_idx1 on expression_image (expression_id);
create index expression_image_idx2 on expression_image (eimage_id);
create table mageml (
    mageml_id serial not null,
    primary key (mageml_id),
    mage_package text not null,
    mage_ml text not null
);

COMMENT ON TABLE mageml IS 'this table is for storing extra bits of mageml in a denormalized form.  more normalization would require many more tables';

create table magedocumentation (
    magedocumentation_id serial not null,
    primary key (magedocumentation_id),
    mageml_id int not null,
    foreign key (mageml_id) references mageml (mageml_id) on delete cascade INITIALLY DEFERRED,
    tableinfo_id int not null,
    foreign key (tableinfo_id) references tableinfo (tableinfo_id) on delete cascade INITIALLY DEFERRED,
    row_id int not null,
    mageidentifier text not null
);
create index magedocumentation_idx1 on magedocumentation (mageml_id);
create index magedocumentation_idx2 on magedocumentation (tableinfo_id);
create index magedocumentation_idx3 on magedocumentation (row_id);

COMMENT ON TABLE magedocumentation IS NULL;

create table protocol (
    protocol_id serial not null,
    primary key (protocol_id),
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    pub_id int null,
    foreign key (pub_id) references pub (pub_id) on delete set null INITIALLY DEFERRED,
    dbxref_id int null,
    foreign key (dbxref_id) references dbxref (dbxref_id) on delete set null INITIALLY DEFERRED,
    name text not null,
    uri text null,
    protocoldescription text null,
    hardwaredescription text null,
    softwaredescription text null,
    constraint protocol_c1 unique (name)
);
create index protocol_idx1 on protocol (type_id);
create index protocol_idx2 on protocol (pub_id);
create index protocol_idx3 on protocol (dbxref_id);

COMMENT ON TABLE protocol IS 'procedural notes on how data was prepared and processed';

create table protocolparam (
    protocolparam_id serial not null,
    primary key (protocolparam_id),
    protocol_id int not null,
    foreign key (protocol_id) references protocol (protocol_id) on delete cascade INITIALLY DEFERRED,
    name text not null,
    datatype_id int null,
    foreign key (datatype_id) references cvterm (cvterm_id) on delete set null INITIALLY DEFERRED,
    unittype_id int null,
    foreign key (unittype_id) references cvterm (cvterm_id) on delete set null INITIALLY DEFERRED,
    value text null,
    rank int not null default 0
);
create index protocolparam_idx1 on protocolparam (protocol_id);
create index protocolparam_idx2 on protocolparam (datatype_id);
create index protocolparam_idx3 on protocolparam (unittype_id);

COMMENT ON TABLE protocolparam IS 'parameters related to a protocol.  if the protocol is a soak, this might include attributes of bath temperature and duration';

create table channel (
    channel_id serial not null,
    primary key (channel_id),
    name text not null,
    definition text not null,
    constraint channel_c1 unique (name)
);

COMMENT ON TABLE channel IS 'different array platforms can record signals from one or more channels (cDNA arrays typically use two CCD, but affy uses only one)';

create table arraydesign (
    arraydesign_id serial not null,
    primary key (arraydesign_id),
    manufacturer_id int not null,
    foreign key (manufacturer_id) references contact (contact_id) on delete cascade INITIALLY DEFERRED,
    platformtype_id int not null,
    foreign key (platformtype_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    substratetype_id int null,
    foreign key (substratetype_id) references cvterm (cvterm_id) on delete set null INITIALLY DEFERRED,
    protocol_id int null,
    foreign key (protocol_id) references protocol (protocol_id) on delete set null INITIALLY DEFERRED,
    dbxref_id int null,
    foreign key (dbxref_id) references dbxref (dbxref_id) on delete set null INITIALLY DEFERRED,
    name text not null,
    version text null,
    description text null,
    array_dimensions text null,
    element_dimensions text null,
    num_of_elements int null,
    num_array_columns int null,
    num_array_rows int null,
    num_grid_columns int null,
    num_grid_rows int null,
    num_sub_columns int null,
    num_sub_rows int null,
    constraint arraydesign_c1 unique (name)
);
create index arraydesign_idx1 on arraydesign (manufacturer_id);
create index arraydesign_idx2 on arraydesign (platformtype_id);
create index arraydesign_idx3 on arraydesign (substratetype_id);
create index arraydesign_idx4 on arraydesign (protocol_id);
create index arraydesign_idx5 on arraydesign (dbxref_id);

COMMENT ON TABLE arraydesign IS 'general properties about an array.  and array is a template used to generate physical slides, etc.  it contains layout information, as well as global array properties, such as material (glass, nylon) and spot dimensions(in rows/columns).';

create table arraydesignprop (
    arraydesignprop_id serial not null,
    primary key (arraydesignprop_id),
    arraydesign_id int not null,
    foreign key (arraydesign_id) references arraydesign (arraydesign_id) on delete cascade INITIALLY DEFERRED,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    value text null,
    rank int not null default 0,
    constraint arraydesignprop_c1 unique (arraydesign_id,type_id,rank)
);
create index arraydesignprop_idx1 on arraydesignprop (arraydesign_id);
create index arraydesignprop_idx2 on arraydesignprop (type_id);

COMMENT ON TABLE arraydesignprop IS 'extra arraydesign properties that are not accounted for in arraydesign';

create table assay (
    assay_id serial not null,
    primary key (assay_id),
    arraydesign_id int not null,
    foreign key (arraydesign_id) references arraydesign (arraydesign_id) on delete cascade INITIALLY DEFERRED,
    protocol_id int null,
    foreign key (protocol_id) references protocol (protocol_id) on delete set null INITIALLY DEFERRED,
    assaydate timestamp null default current_timestamp,
    arrayidentifier text null,
    arraybatchidentifier text null,
    operator_id int not null,
    foreign key (operator_id) references contact (contact_id) on delete cascade INITIALLY DEFERRED,
    dbxref_id int null,
    foreign key (dbxref_id) references dbxref (dbxref_id) on delete set null INITIALLY DEFERRED,
    name text null,
    description text null,
    constraint assay_c1 unique (name)
);
create index assay_idx1 on assay (arraydesign_id);
create index assay_idx2 on assay (protocol_id);
create index assay_idx3 on assay (operator_id);
create index assay_idx4 on assay (dbxref_id);

COMMENT ON TABLE assay IS 'an assay consists of a physical instance of an array, combined with the conditions used to create the array (protocols, technician info).  the assay can be thought of as a hybridization';

create table assayprop (
    assayprop_id serial not null,
    primary key (assayprop_id),
    assay_id int not null,
    foreign key (assay_id) references assay (assay_id) on delete cascade INITIALLY DEFERRED,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    value text null,
    rank int not null default 0,
    constraint assayprop_c1 unique (assay_id,type_id,rank)
);
create index assayprop_idx1 on assayprop (assay_id);
create index assayprop_idx2 on assayprop (type_id);

COMMENT ON TABLE assayprop IS 'extra assay properties that are not accounted for in assay';

create table assay_project (
    assay_project_id serial not null,
    primary key (assay_project_id),
    assay_id int not null,
    foreign key (assay_id) references assay (assay_id) INITIALLY DEFERRED,
    project_id int not null,
    foreign key (project_id) references project (project_id) INITIALLY DEFERRED,
    constraint assay_project_c1 unique (assay_id,project_id)
);
create index assay_project_idx1 on assay_project (assay_id);
create index assay_project_idx2 on assay_project (project_id);

COMMENT ON TABLE assay_project IS 'link assays to projects';

create table biomaterial (
    biomaterial_id serial not null,
    primary key (biomaterial_id),
    taxon_id int null,
    foreign key (taxon_id) references organism (organism_id) on delete set null INITIALLY DEFERRED,
    biosourceprovider_id int null,
    foreign key (biosourceprovider_id) references contact (contact_id) on delete set null INITIALLY DEFERRED,
    dbxref_id int null,
    foreign key (dbxref_id) references dbxref (dbxref_id) on delete set null INITIALLY DEFERRED,
    name text null,
    description text null,
    constraint biomaterial_c1 unique (name)
);
create index biomaterial_idx1 on biomaterial (taxon_id);
create index biomaterial_idx2 on biomaterial (biosourceprovider_id);
create index biomaterial_idx3 on biomaterial (dbxref_id);

COMMENT ON TABLE biomaterial IS 'a biomaterial represents the MAGE concept of BioSource, BioSample, and LabeledExtract.  it is essentially some biological material (tissue, cells, serum) that may have been processed.  processed biomaterials should be traceable back to raw biomaterials via the biomaterialrelationship table.';

create table biomaterial_relationship (
    biomaterial_relationship_id serial not null,
    primary key (biomaterial_relationship_id),
    subject_id int not null,
    foreign key (subject_id) references biomaterial (biomaterial_id) INITIALLY DEFERRED,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) INITIALLY DEFERRED,
    object_id int not null,
    foreign key (object_id) references biomaterial (biomaterial_id) INITIALLY DEFERRED,
    constraint biomaterial_relationship_c1 unique (subject_id,object_id,type_id)
);
create index biomaterial_relationship_idx1 on biomaterial_relationship (subject_id);
create index biomaterial_relationship_idx2 on biomaterial_relationship (object_id);
create index biomaterial_relationship_idx3 on biomaterial_relationship (type_id);

COMMENT ON TABLE biomaterial_relationship IS 'relate biomaterials to one another.  this is a way to track a series of treatments or material splits/merges, for instance';

create table biomaterialprop (
    biomaterialprop_id serial not null,
    primary key (biomaterialprop_id),
    biomaterial_id int not null,
    foreign key (biomaterial_id) references biomaterial (biomaterial_id) on delete cascade INITIALLY DEFERRED,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    value text null,
    rank int not null default 0,
    constraint biomaterialprop_c1 unique (biomaterial_id,type_id,rank)
);
create index biomaterialprop_idx1 on biomaterialprop (biomaterial_id);
create index biomaterialprop_idx2 on biomaterialprop (type_id);

COMMENT ON TABLE biomaterialprop IS 'extra biomaterial properties that are not accounted for in biomaterial';

create table biomaterial_dbxref (
    biomaterial_dbxref_id serial not null,
    primary key (biomaterial_dbxref_id),
    biomaterial_id int not null,
    foreign key (biomaterial_id) references biomaterial (biomaterial_id) on delete cascade INITIALLY DEFERRED,
    dbxref_id int not null,
    foreign key (dbxref_id) references dbxref (dbxref_id) on delete cascade INITIALLY DEFERRED,
    constraint biomaterial_dbxref_c1 unique (biomaterial_id,dbxref_id)
);
create index biomaterial_dbxref_idx1 on biomaterial_dbxref (biomaterial_id);
create index biomaterial_dbxref_idx2 on biomaterial_dbxref (dbxref_id);


create table treatment (
    treatment_id serial not null,
    primary key (treatment_id),
    rank int not null default 0,
    biomaterial_id int not null,
    foreign key (biomaterial_id) references biomaterial (biomaterial_id) on delete cascade INITIALLY DEFERRED,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    protocol_id int null,
    foreign key (protocol_id) references protocol (protocol_id) on delete set null INITIALLY DEFERRED,
    name text null
);
create index treatment_idx1 on treatment (biomaterial_id);
create index treatment_idx2 on treatment (type_id);
create index treatment_idx3 on treatment (protocol_id);

COMMENT ON TABLE treatment IS 'a biomaterial may undergo multiple treatments.  this can range from apoxia to fluorophore and biotin labeling';

create table biomaterial_treatment (
    biomaterial_treatment_id serial not null,
    primary key (biomaterial_treatment_id),
    biomaterial_id int not null,
    foreign key (biomaterial_id) references biomaterial (biomaterial_id) on delete cascade INITIALLY DEFERRED,
    treatment_id int not null,
    foreign key (treatment_id) references treatment (treatment_id) on delete cascade INITIALLY DEFERRED,
    unittype_id int null,
    foreign key (unittype_id) references cvterm (cvterm_id) on delete set null INITIALLY DEFERRED,
    value float(15) null,
    rank int not null default 0,
    constraint biomaterial_treatment_c1 unique (biomaterial_id,treatment_id)
);
create index biomaterial_treatment_idx1 on biomaterial_treatment (biomaterial_id);
create index biomaterial_treatment_idx2 on biomaterial_treatment (treatment_id);
create index biomaterial_treatment_idx3 on biomaterial_treatment (unittype_id);

COMMENT ON TABLE biomaterial_treatment IS 'link biomaterials to treatments.  treatments have an order of operations (rank), and associated measurements (unittype_id, value)';

create table assay_biomaterial (
    assay_biomaterial_id serial not null,
    primary key (assay_biomaterial_id),
    assay_id int not null,
    foreign key (assay_id) references assay (assay_id) on delete cascade INITIALLY DEFERRED,
    biomaterial_id int not null,
    foreign key (biomaterial_id) references biomaterial (biomaterial_id) on delete cascade INITIALLY DEFERRED,
    channel_id int null,
    foreign key (channel_id) references channel (channel_id) on delete set null INITIALLY DEFERRED,
    rank int not null default 0,
    constraint assay_biomaterial_c1 unique (assay_id,biomaterial_id,channel_id,rank)
);
create index assay_biomaterial_idx1 on assay_biomaterial (assay_id);
create index assay_biomaterial_idx2 on assay_biomaterial (biomaterial_id);
create index assay_biomaterial_idx3 on assay_biomaterial (channel_id);

COMMENT ON TABLE assay_biomaterial IS 'a biomaterial can be hybridized many times (technical replicates), or combined with other biomaterials in a single hybridization (for two-channel arrays)';

create table acquisition (
    acquisition_id serial not null,
    primary key (acquisition_id),
    assay_id int not null,
    foreign key (assay_id) references  assay (assay_id) on delete cascade INITIALLY DEFERRED,
    protocol_id int null,
    foreign key (protocol_id) references protocol (protocol_id) on delete set null INITIALLY DEFERRED,
    channel_id int null,
    foreign key (channel_id) references channel (channel_id) on delete set null INITIALLY DEFERRED,
    acquisitiondate timestamp null default current_timestamp,
    name text null,
    uri text null,
    constraint acquisition_c1 unique (name)
);
create index acquisition_idx1 on acquisition (assay_id);
create index acquisition_idx2 on acquisition (protocol_id);
create index acquisition_idx3 on acquisition (channel_id);

COMMENT ON TABLE acquisition IS 'this represents the scanning of hybridized material.  the output of this process is typically a digital image of an array';

create table acquisitionprop (
    acquisitionprop_id serial not null,
    primary key (acquisitionprop_id),
    acquisition_id int not null,
    foreign key (acquisition_id) references acquisition (acquisition_id) on delete cascade INITIALLY DEFERRED,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    value text null,
    rank int not null default 0,
    constraint acquisitionprop_c1 unique (acquisition_id,type_id,rank)
);
create index acquisitionprop_idx1 on acquisitionprop (acquisition_id);
create index acquisitionprop_idx2 on acquisitionprop (type_id);

COMMENT ON TABLE acquisitionprop IS 'parameters associated with image acquisition';

create table acquisition_relationship (
    acquisition_relationship_id serial not null,
    primary key (acquisition_relationship_id),
    subject_id int not null,
    foreign key (subject_id) references acquisition (acquisition_id) on delete cascade INITIALLY DEFERRED,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    object_id int not null,
    foreign key (object_id) references acquisition (acquisition_id) on delete cascade INITIALLY DEFERRED,
    value text null,
    rank int not null default 0,
    constraint acquisition_relationship_c1 unique (subject_id,object_id,type_id,rank)
);
create index acquisition_relationship_idx1 on acquisition_relationship (subject_id);
create index acquisition_relationship_idx2 on acquisition_relationship (type_id);
create index acquisition_relationship_idx3 on acquisition_relationship (object_id);

COMMENT ON TABLE acquisition_relationship IS 'multiple monochrome images may be merged to form a multi-color image.  red-green images of 2-channel hybridizations are an example of this';

create table quantification (
    quantification_id serial not null,
    primary key (quantification_id),
    acquisition_id int not null,
    foreign key (acquisition_id) references acquisition (acquisition_id) on delete cascade INITIALLY DEFERRED,
    operator_id int null,
    foreign key (operator_id) references contact (contact_id) on delete set null INITIALLY DEFERRED,
    protocol_id int null,
    foreign key (protocol_id) references protocol (protocol_id) on delete set null INITIALLY DEFERRED,
    analysis_id int not null,
    foreign key (analysis_id) references analysis (analysis_id) on delete cascade INITIALLY DEFERRED,
    quantificationdate timestamp null default current_timestamp,
    name text null,
    uri text null,
    constraint quantification_c1 unique (name,analysis_id)
);
create index quantification_idx1 on quantification (acquisition_id);
create index quantification_idx2 on quantification (operator_id);
create index quantification_idx3 on quantification (protocol_id);
create index quantification_idx4 on quantification (analysis_id);

COMMENT ON TABLE quantification IS 'quantification is the transformation of an image acquisition to numeric data.  this typically involves statistical procedures.';

create table quantificationprop (
    quantificationprop_id serial not null,
    primary key (quantificationprop_id),
    quantification_id int not null,
    foreign key (quantification_id) references quantification (quantification_id) on delete cascade INITIALLY DEFERRED,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    value text null,
    rank int not null default 0,
    constraint quantificationprop_c1 unique (quantification_id,type_id,rank)
);
create index quantificationprop_idx1 on quantificationprop (quantification_id);
create index quantificationprop_idx2 on quantificationprop (type_id);

COMMENT ON TABLE quantificationprop IS 'extra quantification properties that are not accounted for in quantification';

create table quantification_relationship (
    quantification_relationship_id serial not null,
    primary key (quantification_relationship_id),
    subject_id int not null,
    foreign key (subject_id) references quantification (quantification_id) on delete cascade INITIALLY DEFERRED,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    object_id int not null,
    foreign key (object_id) references quantification (quantification_id) on delete cascade INITIALLY DEFERRED,
    constraint quantification_relationship_c1 unique (subject_id,object_id,type_id)
);
create index quantification_relationship_idx1 on quantification_relationship (subject_id);
create index quantification_relationship_idx2 on quantification_relationship (type_id);
create index quantification_relationship_idx3 on quantification_relationship (object_id);

COMMENT ON TABLE quantification_relationship IS 'there may be multiple rounds of quantification, this allows us to keep an audit trail of what values went where';

create table control (
    control_id serial not null,
    primary key (control_id),
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    assay_id int not null,
    foreign key (assay_id) references assay (assay_id) on delete cascade INITIALLY DEFERRED,
    tableinfo_id int not null,
    foreign key (tableinfo_id) references tableinfo (tableinfo_id) on delete cascade INITIALLY DEFERRED,
    row_id int not null,
    name text null,
    value text null,
    rank int not null default 0
);
create index control_idx1 on control (type_id);
create index control_idx2 on control (assay_id);
create index control_idx3 on control (tableinfo_id);
create index control_idx4 on control (row_id);

COMMENT ON TABLE control IS NULL;

create table element (
    element_id serial not null,
    primary key (element_id),
    feature_id int null,
    foreign key (feature_id) references feature (feature_id) on delete set null INITIALLY DEFERRED,
    arraydesign_id int not null,
    foreign key (arraydesign_id) references arraydesign (arraydesign_id) on delete cascade INITIALLY DEFERRED,
    type_id int null,
    foreign key (type_id) references cvterm (cvterm_id) on delete set null INITIALLY DEFERRED,
    dbxref_id int null,
    foreign key (dbxref_id) references dbxref (dbxref_id) on delete set null INITIALLY DEFERRED,
    constraint element_c1 unique (feature_id,arraydesign_id)
);
create index element_idx1 on element (feature_id);
create index element_idx2 on element (arraydesign_id);
create index element_idx3 on element (type_id);
create index element_idx4 on element (dbxref_id);

COMMENT ON TABLE element IS 'represents a feature of the array.  this is typically a region of the array coated or bound to DNA';

create table elementresult (
    elementresult_id serial not null,
    primary key (elementresult_id),
    element_id int not null,
    foreign key (element_id) references element (element_id) on delete cascade INITIALLY DEFERRED,
    quantification_id int not null,
    foreign key (quantification_id) references quantification (quantification_id) on delete cascade INITIALLY DEFERRED,
    signal float not null,
    constraint elementresult_c1 unique (element_id,quantification_id)
);
create index elementresult_idx1 on elementresult (element_id);
create index elementresult_idx2 on elementresult (quantification_id);
create index elementresult_idx3 on elementresult (signal);

COMMENT ON TABLE elementresult IS 'an element on an array produces a measurement when hybridized to a biomaterial (traceable through quantification_id).  this is the base data from which tables that actually contain data inherit';

create table element_relationship (
    element_relationship_id serial not null,
    primary key (element_relationship_id),
    subject_id int not null,
    foreign key (subject_id) references element (element_id) INITIALLY DEFERRED,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) INITIALLY DEFERRED,
    object_id int not null,
    foreign key (object_id) references element (element_id) INITIALLY DEFERRED,
    value text null,
    rank int not null default 0,
    constraint element_relationship_c1 unique (subject_id,object_id,type_id,rank)
);
create index element_relationship_idx1 on element_relationship (subject_id);
create index element_relationship_idx2 on element_relationship (type_id);
create index element_relationship_idx3 on element_relationship (object_id);
create index element_relationship_idx4 on element_relationship (value);

COMMENT ON TABLE element_relationship IS 'sometimes we want to combine measurements from multiple elements to get a composite value.  affy combines many probes to form a probeset measurement, for instance';

create table elementresult_relationship (
    elementresult_relationship_id serial not null,
    primary key (elementresult_relationship_id),
    subject_id int not null,
    foreign key (subject_id) references elementresult (elementresult_id) INITIALLY DEFERRED,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) INITIALLY DEFERRED,
    object_id int not null,
    foreign key (object_id) references elementresult (elementresult_id) INITIALLY DEFERRED,
    value text null,
    rank int not null default 0,
    constraint elementresult_relationship_c1 unique (subject_id,object_id,type_id,rank)
);
create index elementresult_relationship_idx1 on elementresult_relationship (subject_id);
create index elementresult_relationship_idx2 on elementresult_relationship (type_id);
create index elementresult_relationship_idx3 on elementresult_relationship (object_id);
create index elementresult_relationship_idx4 on elementresult_relationship (value);

COMMENT ON TABLE elementresult_relationship IS 'sometimes we want to combine measurements from multiple elements to get a composite value.  affy combines many probes to form a probeset measurement, for instance';

create table study (
    study_id serial not null,
    primary key (study_id),
    contact_id int not null,
    foreign key (contact_id) references contact (contact_id) on delete cascade INITIALLY DEFERRED,
    pub_id int null,
    foreign key (pub_id) references pub (pub_id) on delete set null INITIALLY DEFERRED,
    dbxref_id int null,
    foreign key (dbxref_id) references dbxref (dbxref_id) on delete set null INITIALLY DEFERRED,
    name text not null,
    description text null,
    constraint study_c1 unique (name)
);
create index study_idx1 on study (contact_id);
create index study_idx2 on study (pub_id);
create index study_idx3 on study (dbxref_id);

COMMENT ON TABLE study IS NULL;

create table study_assay (
    study_assay_id serial not null,
    primary key (study_assay_id),
    study_id int not null,
    foreign key (study_id) references study (study_id) on delete cascade INITIALLY DEFERRED,
    assay_id int not null,
    foreign key (assay_id) references assay (assay_id) on delete cascade INITIALLY DEFERRED,
    constraint study_assay_c1 unique (study_id,assay_id)
);
create index study_assay_idx1 on study_assay (study_id);
create index study_assay_idx2 on study_assay (assay_id);

COMMENT ON TABLE study_assay IS NULL;

create table studydesign (
    studydesign_id serial not null,
    primary key (studydesign_id),
    study_id int not null,
    foreign key (study_id) references study (study_id) on delete cascade INITIALLY DEFERRED,
    description text null
);
create index studydesign_idx1 on studydesign (study_id);

COMMENT ON TABLE studydesign IS NULL;

create table studydesignprop (
    studydesignprop_id serial not null,
    primary key (studydesignprop_id),
    studydesign_id int not null,
    foreign key (studydesign_id) references studydesign (studydesign_id) on delete cascade INITIALLY DEFERRED,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    value text null,
    rank int not null default 0,
    constraint studydesignprop_c1 unique (studydesign_id,type_id,rank)
);
create index studydesignprop_idx1 on studydesignprop (studydesign_id);
create index studydesignprop_idx2 on studydesignprop (type_id);

COMMENT ON TABLE studydesignprop IS NULL;

create table studyfactor (
    studyfactor_id serial not null,
    primary key (studyfactor_id),
    studydesign_id int not null,
    foreign key (studydesign_id) references studydesign (studydesign_id) on delete cascade INITIALLY DEFERRED,
    type_id int null,
    foreign key (type_id) references cvterm (cvterm_id) on delete set null INITIALLY DEFERRED,
    name text not null,
    description text null
);
create index studyfactor_idx1 on studyfactor (studydesign_id);
create index studyfactor_idx2 on studyfactor (type_id);

COMMENT ON TABLE studyfactor IS NULL;

create table studyfactorvalue (
    studyfactorvalue_id serial not null,
    primary key (studyfactorvalue_id),
    studyfactor_id int not null,
    foreign key (studyfactor_id) references studyfactor (studyfactor_id) on delete cascade INITIALLY DEFERRED,
    assay_id int not null,
    foreign key (assay_id) references assay (assay_id) on delete cascade INITIALLY DEFERRED,
    factorvalue text null,
    name text null,
    rank int not null default 0
);
create index studyfactorvalue_idx1 on studyfactorvalue (studyfactor_id);
create index studyfactorvalue_idx2 on studyfactorvalue (assay_id);

COMMENT ON TABLE studyfactorvalue IS NULL;
CREATE TABLE affymetrixprobeset (
  element_id serial not null,
  primary key (element_id),
  feature_id int null,
  foreign key (feature_id) references feature (feature_id) on delete set null INITIALLY DEFERRED,
  arraydesign_id int not null,
  foreign key (arraydesign_id) references arraydesign (arraydesign_id) on delete cascade INITIALLY DEFERRED,
  type_id int null,
  foreign key (type_id) references cvterm (cvterm_id) on delete set null INITIALLY DEFERRED,
  dbxref_id int null,
  foreign key (dbxref_id) references dbxref (dbxref_id) on delete set null INITIALLY DEFERRED,
  name varchar(255) NULL
);
--ALTER TABLE affymetrixprobeset ADD CONSTRAINT affymetrixprobeset_c2 FOREIGN KEY (dbxref_id)        REFERENCES dbxref        (dbxref_id);
--ALTER TABLE affymetrixprobeset ADD CONSTRAINT affymetrixprobeset_c3 FOREIGN KEY (arraydesign_id)   REFERENCES arraydesign   (arraydesign_id);
--ALTER TABLE affymetrixprobeset ADD CONSTRAINT affymetrixprobeset_c4 FOREIGN KEY (type_id)          REFERENCES cvterm        (cvterm_id);
--ALTER TABLE affymetrixprobeset ADD CONSTRAINT affymetrixprobeset_c5 FOREIGN KEY (feature_id)       REFERENCES feature       (feature_id);
CREATE INDEX affymetrixprobeset_idx1 ON affymetrixprobeset (name);
CREATE INDEX affymetrixprobeset_idx2 ON affymetrixprobeset (feature_id);
CREATE INDEX affymetrixprobeset_idx3 ON affymetrixprobeset (dbxref_id);
CREATE INDEX affymetrixprobeset_idx4 ON affymetrixprobeset (arraydesign_id);
CREATE INDEX affymetrixprobeset_idx5 ON affymetrixprobeset (type_id);
CREATE UNIQUE INDEX affymetrixprobeset_idx6 ON affymetrixprobeset (name,arraydesign_id);
CREATE UNIQUE INDEX affymetrixprobeset_idx7 ON affymetrixprobeset (feature_id,arraydesign_id);

CREATE TABLE affymetrixprobe (
  element_id serial not null,
  primary key (element_id),
  feature_id int null,
  foreign key (feature_id) references feature (feature_id) on delete set null INITIALLY DEFERRED,
  arraydesign_id int not null,
  foreign key (arraydesign_id) references arraydesign (arraydesign_id) on delete cascade INITIALLY DEFERRED,
  type_id int null,
  foreign key (type_id) references cvterm (cvterm_id) on delete set null INITIALLY DEFERRED,
  dbxref_id int null,
  foreign key (dbxref_id) references dbxref (dbxref_id) on delete set null INITIALLY DEFERRED,
  name varchar(255) NULL,
  affymetrixprobeset_id int NULL,
  row int NOT NULL,
  col int NOT NULL
);
--ALTER TABLE affymetrixprobe ADD CONSTRAINT affymetrixprobe_c1 FOREIGN KEY (feature_id)            REFERENCES feature       (feature_id);
--ALTER TABLE affymetrixprobe ADD CONSTRAINT affymetrixprobe_c2 FOREIGN KEY (dbxref_id)             REFERENCES dbxref        (dbxref_id);
--ALTER TABLE affymetrixprobe ADD CONSTRAINT affymetrixprobe_c3 FOREIGN KEY (arraydesign_id)        REFERENCES arraydesign   (arraydesign_id);
--ALTER TABLE affymetrixprobe ADD CONSTRAINT affymetrixprobe_c4 FOREIGN KEY (type_id)               REFERENCES cvterm        (cvterm_id);
ALTER TABLE affymetrixprobe ADD CONSTRAINT affymetrixprobe_c5 FOREIGN KEY (affymetrixprobeset_id) REFERENCES affymetrixprobeset (element_id);
CREATE INDEX affymetrixprobe_idx1 ON affymetrixprobe (affymetrixprobeset_id);
CREATE INDEX affymetrixprobe_idx2 ON affymetrixprobe (name);
CREATE INDEX affymetrixprobe_idx3 ON affymetrixprobe (feature_id);
CREATE INDEX affymetrixprobe_idx4 ON affymetrixprobe (dbxref_id);
CREATE INDEX affymetrixprobe_idx5 ON affymetrixprobe (arraydesign_id);
CREATE INDEX affymetrixprobe_idx6 ON affymetrixprobe (type_id);

CREATE TABLE affymetrixcel (
  mean float NOT NULL,
  sd float NOT NULL,
  pixels int NOT NULL
) INHERITS ( elementresult );
ALTER TABLE affymetrixcel ADD PRIMARY KEY (elementresult_id);
ALTER TABLE affymetrixcel ADD CONSTRAINT affymetrixcel_c1 FOREIGN KEY (element_id)        REFERENCES affymetrixprobe (element_id);
ALTER TABLE affymetrixcel ADD CONSTRAINT affymetrixcel_c2 FOREIGN KEY (quantification_id) REFERENCES quantification  (quantification_id);
CREATE INDEX affymetrixcel_idx1 ON affymetrixcel (mean);
CREATE INDEX affymetrixcel_idx2 ON affymetrixcel (sd);
CREATE INDEX affymetrixcel_idx3 ON affymetrixcel (pixels);
CREATE INDEX affymetrixcel_idx4 ON affymetrixcel (element_id);
CREATE INDEX affymetrixcel_idx5 ON affymetrixcel (quantification_id);

CREATE TABLE affymetrixsnp (
  call smallint NULL,
  call_p float NULL,
  _signal _float4 NULL
) INHERITS ( elementresult );
ALTER TABLE affymetrixsnp ADD PRIMARY KEY (elementresult_id);
ALTER TABLE affymetrixsnp ADD CONSTRAINT affymetrixsnp_c1 FOREIGN KEY (element_id)        REFERENCES affymetrixprobeset (element_id);
ALTER TABLE affymetrixsnp ADD CONSTRAINT affymetrixsnp_c2 FOREIGN KEY (quantification_id) REFERENCES quantification  (quantification_id);
CREATE INDEX affymetrixsnp_idx1 ON affymetrixsnp (call);
CREATE INDEX affymetrixsnp_idx2 ON affymetrixsnp (signal);
CREATE INDEX affymetrixsnp_idx4 ON affymetrixsnp (element_id);
CREATE INDEX affymetrixsnp_idx5 ON affymetrixsnp (quantification_id);
CREATE INDEX affymetrixsnp_idx6 ON affymetrixsnp (call_p);

CREATE TABLE affymetrixpsi (
  q1pas INT NULL,
  q1pbs INT NULL,
  q1mas INT NULL,
  q1mbs INT NULL,
  q1paa INT NULL,
  q1pba INT NULL,
  q1maa INT NULL,
  q1mba INT NULL,

  q2pas INT NULL,
  q2pbs INT NULL,
  q2mas INT NULL,
  q2mbs INT NULL,
  q2paa INT NULL,
  q2pba INT NULL,
  q2maa INT NULL,
  q2mba INT NULL,

  q3pas INT NULL,
  q3pbs INT NULL,
  q3mas INT NULL,
  q3mbs INT NULL,
  q3paa INT NULL,
  q3pba INT NULL,
  q3maa INT NULL,
  q3mba INT NULL,

  q4pas INT NULL,
  q4pbs INT NULL,
  q4mas INT NULL,
  q4mbs INT NULL,
  q4paa INT NULL,
  q4pba INT NULL,
  q4maa INT NULL,
  q4mba INT NULL,

  q5pas INT NULL,
  q5pbs INT NULL,
  q5mas INT NULL,
  q5mbs INT NULL,
  q5paa INT NULL,
  q5pba INT NULL,
  q5maa INT NULL,
  q5mba INT NULL,

  q6pas INT NULL,
  q6pbs INT NULL,
  q6mas INT NULL,
  q6mbs INT NULL,
  q6paa INT NULL,
  q6pba INT NULL,
  q6maa INT NULL,
  q6mba INT NULL
) INHERITS ( elementresult );
ALTER TABLE affymetrixpsi ADD PRIMARY KEY (elementresult_id);
ALTER TABLE affymetrixpsi ADD CONSTRAINT affymetrixpsi_c1 FOREIGN KEY (element_id)        REFERENCES affymetrixprobeset (element_id);
ALTER TABLE affymetrixpsi ADD CONSTRAINT affymetrixpsi_c2 FOREIGN KEY (quantification_id) REFERENCES quantification  (quantification_id);
CREATE INDEX affymetrixpsi_idx4 ON affymetrixpsi (element_id);
CREATE INDEX affymetrixpsi_idx5 ON affymetrixpsi (quantification_id);


CREATE TABLE affymetrixmas5 (
  call char(1) NOT NULL,
  call_p float NOT NULL,
  statpairs int NOT NULL,
  statpairsused int NOT NULL,
  z float NULL
) INHERITS ( elementresult );
ALTER TABLE affymetrixmas5 ADD PRIMARY KEY (elementresult_id);
ALTER TABLE affymetrixmas5 ADD CONSTRAINT affymetrixmas5_c1 FOREIGN KEY (element_id)        REFERENCES affymetrixprobeset (element_id);
ALTER TABLE affymetrixmas5 ADD CONSTRAINT affymetrixmas5_c2 FOREIGN KEY (quantification_id) REFERENCES quantification  (quantification_id);
CREATE INDEX affymetrixmas5_idx1 ON affymetrixmas5 (signal);
CREATE INDEX affymetrixmas5_idx2 ON affymetrixmas5 (call);
CREATE INDEX affymetrixmas5_idx3 ON affymetrixmas5 (call_p);
CREATE INDEX affymetrixmas5_idx4 ON affymetrixmas5 (element_id);
CREATE INDEX affymetrixmas5_idx5 ON affymetrixmas5 (quantification_id);
CREATE INDEX affymetrixmas5_idx6 ON affymetrixmas5 (z);

CREATE TABLE affymetrixdchip (
  z float NULL
) INHERITS ( elementresult );
ALTER TABLE affymetrixdchip ADD PRIMARY KEY (elementresult_id);
ALTER TABLE affymetrixdchip ADD CONSTRAINT affymetrixdchip_c1 FOREIGN KEY (element_id)        REFERENCES affymetrixprobeset (element_id);
ALTER TABLE affymetrixdchip ADD CONSTRAINT affymetrixdchip_c2 FOREIGN KEY (quantification_id) REFERENCES quantification  (quantification_id);
CREATE INDEX affymetrixdchip_idx1 ON affymetrixdchip (element_id);
CREATE INDEX affymetrixdchip_idx2 ON affymetrixdchip (quantification_id);
CREATE INDEX affymetrixdchip_idx3 ON affymetrixdchip (signal);
CREATE INDEX affymetrixdchip_idx6 ON affymetrixdchip (z);

CREATE TABLE affymetrixvsn (
  z float NULL
) INHERITS ( elementresult );
ALTER TABLE affymetrixvsn ADD PRIMARY KEY (elementresult_id);
ALTER TABLE affymetrixvsn ADD CONSTRAINT affymetrixvsn_c1 FOREIGN KEY (element_id)        REFERENCES affymetrixprobeset (element_id);
ALTER TABLE affymetrixvsn ADD CONSTRAINT affymetrixvsn_c2 FOREIGN KEY (quantification_id) REFERENCES quantification  (quantification_id);
CREATE INDEX affymetrixvsn_idx1 ON affymetrixvsn (element_id);
CREATE INDEX affymetrixvsn_idx2 ON affymetrixvsn (quantification_id);
CREATE INDEX affymetrixvsn_idx3 ON affymetrixvsn (signal);
CREATE INDEX affymetrixvsn_idx6 ON affymetrixvsn (z);

CREATE TABLE affymetrixsea (
) INHERITS ( elementresult );
ALTER TABLE affymetrixsea ADD PRIMARY KEY (elementresult_id);
--ALTER TABLE affymetrixsea ADD CONSTRAINT affymetrixsea_c1 FOREIGN KEY (element_id)        REFERENCES affymetrixprobeset (element_id);
ALTER TABLE affymetrixsea ADD CONSTRAINT affymetrixsea_c2 FOREIGN KEY (quantification_id) REFERENCES quantification  (quantification_id);
CREATE INDEX affymetrixsea_idx1 ON affymetrixsea (element_id);
CREATE INDEX affymetrixsea_idx2 ON affymetrixsea (quantification_id);
CREATE INDEX affymetrixsea_idx3 ON affymetrixsea (signal);

CREATE TABLE affymetrixplier (
) INHERITS ( elementresult );
ALTER TABLE affymetrixplier ADD PRIMARY KEY (elementresult_id);
ALTER TABLE affymetrixplier ADD CONSTRAINT affymetrixplier_c1 FOREIGN KEY (element_id)        REFERENCES affymetrixprobeset (element_id);
ALTER TABLE affymetrixplier ADD CONSTRAINT affymetrixplier_c2 FOREIGN KEY (quantification_id) REFERENCES quantification  (quantification_id);
CREATE INDEX affymetrixplier_idx1 ON affymetrixplier (element_id);
CREATE INDEX affymetrixplier_idx2 ON affymetrixplier (quantification_id);
CREATE INDEX affymetrixplier_idx3 ON affymetrixplier (signal);

CREATE TABLE affymetrixdabg (
  call_p float NOT NULL
) INHERITS ( elementresult );
ALTER TABLE affymetrixdabg ADD PRIMARY KEY (elementresult_id);
ALTER TABLE affymetrixdabg ADD CONSTRAINT affymetrixdabg_c1 FOREIGN KEY (element_id)        REFERENCES affymetrixprobeset (element_id);
ALTER TABLE affymetrixdabg ADD CONSTRAINT affymetrixdabg_c2 FOREIGN KEY (quantification_id) REFERENCES quantification  (quantification_id);
CREATE INDEX affymetrixdabg_idx1 ON affymetrixdabg (element_id);
CREATE INDEX affymetrixdabg_idx2 ON affymetrixdabg (quantification_id);
CREATE INDEX affymetrixdabg_idx3 ON affymetrixdabg (call_p);

CREATE TABLE affymetrixrma (
  z float NULL
) INHERITS ( elementresult );
ALTER TABLE affymetrixrma ADD PRIMARY KEY (elementresult_id);
ALTER TABLE affymetrixrma ADD CONSTRAINT affymetrixrma_c1 FOREIGN KEY (element_id)        REFERENCES affymetrixprobeset (element_id);
ALTER TABLE affymetrixrma ADD CONSTRAINT affymetrixrma_c2 FOREIGN KEY (quantification_id) REFERENCES quantification  (quantification_id);
CREATE INDEX affymetrixrma_idx1 ON affymetrixrma (element_id);
CREATE INDEX affymetrixrma_idx2 ON affymetrixrma (quantification_id);
CREATE INDEX affymetrixrma_idx3 ON affymetrixrma (signal);
CREATE INDEX affymetrixrma_idx6 ON affymetrixrma (z);

CREATE TABLE affymetrixgcrma (
  z float NULL
) INHERITS ( elementresult );
ALTER TABLE affymetrixgcrma ADD PRIMARY KEY (elementresult_id);
ALTER TABLE affymetrixgcrma ADD CONSTRAINT affymetrixgcrma_c1 FOREIGN KEY (element_id)        REFERENCES affymetrixprobeset (element_id);
ALTER TABLE affymetrixgcrma ADD CONSTRAINT affymetrixgcrma_c2 FOREIGN KEY (quantification_id) REFERENCES quantification  (quantification_id);
CREATE INDEX affymetrixgcrma_idx1 ON affymetrixgcrma (element_id);
CREATE INDEX affymetrixgcrma_idx2 ON affymetrixgcrma (quantification_id);
CREATE INDEX affymetrixgcrma_idx3 ON affymetrixgcrma (signal);
CREATE INDEX affymetrixgcrma_idx6 ON affymetrixgcrma (z);

CREATE TABLE affymetrixprobesetstat (
  mean float NOT NULL,
  median float NOT NULL,
  quartile1 float NOT NULL,
  quartile3 float NOT NULL,
  sd float NOT NULL,
  n int NOT NULL
) INHERITS ( elementresult );
ALTER TABLE affymetrixprobesetstat ADD PRIMARY KEY (elementresult_id);
ALTER TABLE affymetrixprobesetstat ADD CONSTRAINT affymetrixprobesetstat_c1 FOREIGN KEY (element_id)        REFERENCES affymetrixprobeset (element_id);
ALTER TABLE affymetrixprobesetstat ADD CONSTRAINT affymetrixprobesetstat_c2 FOREIGN KEY (quantification_id) REFERENCES quantification  (quantification_id);
CREATE INDEX affymetrixprobesetstat_idx1 ON affymetrixprobesetstat (element_id);
CREATE INDEX affymetrixprobesetstat_idx2 ON affymetrixprobesetstat (quantification_id);
CREATE INDEX affymetrixprobesetstat_idx3 ON affymetrixprobesetstat (mean);
CREATE INDEX affymetrixprobesetstat_idx4 ON affymetrixprobesetstat (median);
CREATE INDEX affymetrixprobesetstat_idx5 ON affymetrixprobesetstat (quartile1);
CREATE INDEX affymetrixprobesetstat_idx6 ON affymetrixprobesetstat (quartile3);
CREATE INDEX affymetrixprobesetstat_idx7 ON affymetrixprobesetstat (sd);
CREATE INDEX affymetrixprobesetstat_idx8 ON affymetrixprobesetstat (n);
-- VIEW gffatts: a view to get feature attributes in a format that
-- will make it easy to convert them to GFF attributes

CREATE OR REPLACE VIEW gffatts (
    feature_id,
    type,
    attribute
) AS
SELECT feature_id, 'cvterm' AS type,  s.name AS attribute
FROM cvterm s, feature_cvterm fs
WHERE fs.cvterm_id = s.cvterm_id
UNION ALL
SELECT feature_id, 'dbxref' AS type, d.name || ':' || s.accession AS attribute
FROM dbxref s, feature_dbxref fs, db d
WHERE fs.dbxref_id = s.dbxref_id and s.db_id = d.db_id
--SELECT feature_id, 'expression' AS type, s.description AS attribute
--FROM expression s, feature_expression fs
--WHERE fs.expression_id = s.expression_id
--UNION ALL
--SELECT fg.feature_id, 'genotype' AS type, g.uniquename||': '||g.description AS attribute
--FROM gcontext g, feature_gcontext fg
--WHERE g.gcontext_id = fg.gcontext_id
--UNION ALL
--SELECT feature_id, 'genotype' AS type, s.description AS attribute
--FROM genotype s, feature_genotype fs
--WHERE fs.genotype_id = s.genotype_id
--UNION ALL
--SELECT feature_id, 'phenotype' AS type, s.description AS attribute
--FROM phenotype s, feature_phenotype fs
--WHERE fs.phenotype_id = s.phenotype_id
UNION ALL
SELECT feature_id, 'synonym' AS type, s.name AS attribute
FROM synonym s, feature_synonym fs
WHERE fs.synonym_id = s.synonym_id
UNION ALL
SELECT fp.feature_id,cv.name,fp.value
FROM featureprop fp, cvterm cv
WHERE fp.type_id = cv.cvterm_id
UNION ALL
SELECT feature_id, 'pub' AS type, s.series_name || ':' || s.title AS attribute
FROM pub s, feature_pub fs
WHERE fs.pub_id = s.pub_id;

--creates a view that can be used to assemble a GFF3 compliant attribute string
CREATE OR REPLACE VIEW gff3atts (
    feature_id,
    type,
    attribute
) AS
SELECT feature_id, 
      'Ontology_term' AS type, 
      CASE WHEN db.name like '%Gene Ontology%'    THEN 'GO:'||dbx.accession
           WHEN db.name like 'Sequence Ontology%' THEN 'SO:'||dbx.accession
           ELSE                            CAST(db.name||':'||dbx.accession AS varchar)
      END 
FROM cvterm s, dbxref dbx, feature_cvterm fs, db
WHERE fs.cvterm_id = s.cvterm_id and s.dbxref_id=dbx.dbxref_id and
      db.db_id = dbx.db_id 
UNION ALL
SELECT feature_id, 'Dbxref' AS type, d.name || ':' || s.accession AS attribute
FROM dbxref s, feature_dbxref fs, db d
WHERE fs.dbxref_id = s.dbxref_id and s.db_id = d.db_id and
      d.name != 'GFF_source'
UNION ALL
SELECT f.feature_id, 'Alias' AS type, s.name AS attribute
FROM synonym s, feature_synonym fs, feature f
WHERE fs.synonym_id = s.synonym_id and f.feature_id = fs.feature_id and
      f.name != s.name and f.uniquename != s.name
UNION ALL
SELECT fp.feature_id,cv.name,fp.value
FROM featureprop fp, cvterm cv
WHERE fp.type_id = cv.cvterm_id
UNION ALL
SELECT feature_id, 'pub' AS type, s.series_name || ':' || s.title AS attribute
FROM pub s, feature_pub fs
WHERE fs.pub_id = s.pub_id
UNION ALL
SELECT fr.subject_id as feature_id, 'Parent' as type,  parent.uniquename as attribute
FROM feature_relationship fr, feature parent
WHERE  fr.object_id=parent.feature_id
UNION ALL
SELECT feature_id, 'ID' as type, uniquename as attribute
FROM feature
WHERE type_id NOT IN (SELECT cvterm_id FROM cvterm WHERE name='CDS')
UNION ALL
SELECT feature_id, 'chado_feature_id' as type, CAST(feature_id AS varchar) as attribute
FROM feature
UNION ALL
SELECT feature_id, 'Name' as type, name as attribute
FROM feature;


CREATE OR REPLACE VIEW gff3view (
  feature_id,
  ref,
  source,
  type,
  fstart,
  fend,
  score,
  strand,
  phase,
  seqlen,
  name,
  organism_id
) AS
SELECT
  f.feature_id   ,
  sf.name        ,
  dbx.accession  ,
  cv.name        ,
  fl.fmin+1      ,
  fl.fmax        ,
  af.significance,
  fl.strand      ,
  fl.phase       ,
  f.seqlen       ,
  f.name         ,
  f.organism_id
FROM feature f
     LEFT JOIN featureloc fl     ON (f.feature_id     = fl.feature_id)
     LEFT JOIN feature sf        ON (fl.srcfeature_id = sf.feature_id)
     LEFT JOIN feature_dbxref fd ON (f.feature_id     = fd.feature_id)
     LEFT JOIN dbxref dbx        ON (dbx.dbxref_id    = fd.dbxref_id)
     LEFT JOIN cvterm cv         ON (f.type_id        = cv.cvterm_id)
     LEFT JOIN analysisfeature af ON (f.feature_id    = af.feature_id)
WHERE dbx.db_id IN (select db_id from db where db.name = 'GFF_source');

-- FUNCTION gfffeatureatts (integer) is a function to get 
-- data in the same format as the gffatts view so that 
-- it can be easily converted to GFF attributes.

CREATE FUNCTION  gfffeatureatts (integer)
RETURNS SETOF gffatts
AS
'
SELECT feature_id, ''cvterm'' AS type,  s.name AS attribute
FROM cvterm s, feature_cvterm fs
WHERE fs.feature_id= $1 AND fs.cvterm_id = s.cvterm_id
UNION
SELECT feature_id, ''dbxref'' AS type, d.name || '':'' || s.accession AS attribute
FROM dbxref s, feature_dbxref fs, db d
WHERE fs.feature_id= $1 AND fs.dbxref_id = s.dbxref_id AND s.db_id = d.db_id
--UNION
--SELECT feature_id, ''expression'' AS type, s.description AS attribute
--FROM expression s, feature_expression fs
--WHERE fs.feature_id= $1 AND fs.expression_id = s.expression_id
--UNION
--SELECT fg.feature_id, ''genotype'' AS type, g.uniquename||'': ''||g.description AS attribute
--FROM gcontext g, feature_gcontext fg
--WHERE fg.feature_id= $1 AND g.gcontext_id = fg.gcontext_id
--UNION
--SELECT feature_id, ''genotype'' AS type, s.description AS attribute
--FROM genotype s, feature_genotype fs
--WHERE fs.feature_id= $1 AND fs.genotype_id = s.genotype_id
--UNION
--SELECT feature_id, ''phenotype'' AS type, s.description AS attribute
--FROM phenotype s, feature_phenotype fs
--WHERE fs.feature_id= $1 AND fs.phenotype_id = s.phenotype_id
UNION
SELECT feature_id, ''synonym'' AS type, s.name AS attribute
FROM synonym s, feature_synonym fs
WHERE fs.feature_id= $1 AND fs.synonym_id = s.synonym_id
UNION
SELECT fp.feature_id,cv.name,fp.value
FROM featureprop fp, cvterm cv
WHERE fp.feature_id= $1 AND fp.type_id = cv.cvterm_id 
UNION
SELECT feature_id, ''pub'' AS type, s.series_name || '':'' || s.title AS attribute
FROM pub s, feature_pub fs
WHERE fs.feature_id= $1 AND fs.pub_id = s.pub_id
'
LANGUAGE SQL;


--
-- functions for creating coordinate based functions
--
-- create a point
CREATE OR REPLACE FUNCTION featureslice(int, int) RETURNS setof featureloc AS
  'SELECT * from featureloc where boxquery($1, $2) @ boxrange(fmin,fmax)'
LANGUAGE 'sql';

--uses the gff3atts to create a GFF3 compliant attribute string
CREATE OR REPLACE FUNCTION gffattstring (integer) RETURNS varchar AS
'DECLARE
  return_string      varchar;
  f_id               ALIAS FOR $1;
  atts_view          gffatts%ROWTYPE;
  feature_row        feature%ROWTYPE;
  name               varchar;
  uniquename         varchar;
  parent             varchar;
  escape_loc         int; 
BEGIN
  --Get name from feature.name
  --Get ID from feature.uniquename
                                                                                
  SELECT INTO feature_row * FROM feature WHERE feature_id = f_id;
  name  = feature_row.name;
  return_string = ''ID='' || feature_row.uniquename;
  IF name IS NOT NULL AND name != ''''
  THEN
    return_string = return_string ||'';'' || ''Name='' || name;
  END IF;
                                                                                
  --Get Parent from feature_relationship
  SELECT INTO feature_row * FROM feature f, feature_relationship fr
    WHERE fr.subject_id = f_id AND fr.object_id = f.feature_id;
  IF FOUND
  THEN
    return_string = return_string||'';''||''Parent=''||feature_row.uniquename;
  END IF;
                                                                                
  FOR atts_view IN SELECT * FROM gff3atts WHERE feature_id = f_id  LOOP
    escape_loc = position('';'' in atts_view.attribute);
    IF escape_loc > 0 THEN
      atts_view.attribute = replace(atts_view.attribute, '';'', ''%3B'');
    END IF;
    return_string = return_string || '';''
                     || atts_view.type || ''=''
                     || atts_view.attribute;
  END LOOP;
                                                                                
  RETURN return_string;
END;
'
LANGUAGE plpgsql;

--creates a view that is suitable for creating a GFF3 string
--CREATE OR REPLACE VIEW gff3view (
--REMOVED and RECREATED in sequence-gff-views.sql to avoid 
--using the function above


--------------------------------
---- dfeatureloc ---------------
--------------------------------
-- dfeatureloc is meant as an alternate representation of
-- the data in featureloc (see the descrption of featureloc
-- in sequence.sql).  In dfeatureloc, fmin and fmax are 
-- replaced with nbeg and nend.  Whereas fmin and fmax
-- are absolute coordinates relative to the parent feature, nbeg 
-- and nend are the beginning and ending coordinates
-- relative to the feature itself.  For example, nbeg would
-- mark the 5' end of a gene and nend would mark the 3' end.

CREATE OR REPLACE VIEW dfeatureloc (
 featureloc_id,
 feature_id,
 srcfeature_id,
 nbeg,
 is_nbeg_partial,
 nend,
 is_nend_partial,
 strand,
 phase,
 residue_info,
 locgroup,
 rank
) AS
SELECT featureloc_id, feature_id, srcfeature_id, fmin, is_fmin_partial,
       fmax, is_fmax_partial, strand, phase, residue_info, locgroup, rank
FROM featureloc
WHERE (strand < 0 or phase < 0)
UNION
SELECT featureloc_id, feature_id, srcfeature_id, fmax, is_fmax_partial,
       fmin, is_fmin_partial, strand, phase, residue_info, locgroup, rank
FROM featureloc
WHERE (strand is NULL or strand >= 0 or phase >= 0) ;

--------------------------------
---- f_type --------------------
--------------------------------
CREATE OR REPLACE VIEW f_type
AS
  SELECT  f.feature_id,
          f.name,
          f.dbxref_id,
          c.name AS type,
          f.residues,
          f.seqlen,
          f.md5checksum,
          f.type_id,
          f.timeaccessioned,
          f.timelastmodified
    FROM  feature f, cvterm c
   WHERE  f.type_id = c.cvterm_id;

--------------------------------
---- fnr_type ------------------
--------------------------------
CREATE OR REPLACE VIEW fnr_type
AS
  SELECT  f.feature_id,
          f.name,
          f.dbxref_id,
          c.name AS type,
          f.residues,
          f.seqlen,
          f.md5checksum,
          f.type_id,
          f.timeaccessioned,
          f.timelastmodified
    FROM  feature f left outer join analysisfeature af
          on (f.feature_id = af.feature_id), cvterm c
   WHERE  f.type_id = c.cvterm_id
          and af.feature_id is null;

--------------------------------
---- f_loc ---------------------
--------------------------------
-- Note from Scott:  I changed this view to depend on dfeatureloc,
-- since I don't know what it is used for.  The change should
-- be transparent.  I also changed dbxrefstr to dbxref_id since
-- dbxrefstr is no longer in feature

CREATE OR REPLACE VIEW f_loc
AS
  SELECT  f.feature_id,
          f.name,
          f.dbxref_id,
          fl.nbeg,
          fl.nend,
          fl.strand
    FROM  dfeatureloc fl, f_type f
   WHERE  f.feature_id = fl.feature_id;

--------------------------------
---- fp_key -------------------
--------------------------------
CREATE OR REPLACE VIEW fp_key
AS
  SELECT  fp.feature_id,
          c.name AS pkey,
          fp.value
    FROM  featureprop fp, cvterm c
   WHERE  fp.featureprop_id = c.cvterm_id;

-- [symmetric,reflexive]
-- intervals have at least one interbase point in common
-- (i.e. overlap OR abut)
-- EXAMPLE QUERY:
--   (features of same type that overlap)
--   SELECT r.*
--   FROM feature AS x 
--   INNER JOIN feature_meets AS r ON (x.feature_id=r.subject_id)
--   INNER JOIN feature AS y ON (y.feature_id=r.object_id)
--   WHERE x.type_id=y.type_id
CREATE OR REPLACE VIEW feature_meets (
  subject_id,
  object_id
) AS
SELECT
 x.feature_id,
 y.feature_id
FROM
 featureloc AS x,
 featureloc AS y
WHERE
 x.srcfeature_id=y.srcfeature_id
 AND
 ( x.fmax >= y.fmin AND x.fmin <= y.fmax );

COMMENT ON VIEW feature_meets IS 'intervals have at least one
interbase point in common (ie overlap OR abut). symmetric,reflexive';

-- [symmetric,reflexive]
-- as above, strands match
CREATE OR REPLACE VIEW feature_meets_on_same_strand (
  subject_id,
  object_id
) AS
SELECT
 x.feature_id,
 y.feature_id
FROM
 featureloc AS x,
 featureloc AS y
WHERE
 x.srcfeature_id=y.srcfeature_id
 AND
 x.strand = y.strand
 AND
 ( x.fmax >= y.fmin AND x.fmin <= y.fmax );

COMMENT ON VIEW feature_meets_on_same_strand IS 'as feature_meets, but
featurelocs must be on the same strand. symmetric,reflexive';


-- [symmetric]
-- intervals have no interbase points in common and do not abut
CREATE OR REPLACE VIEW feature_disjoint (
  subject_id,
  object_id
) AS
SELECT
 x.feature_id,
 y.feature_id
FROM
 featureloc AS x,
 featureloc AS y
WHERE
 x.srcfeature_id=y.srcfeature_id
 AND
 ( x.fmax < y.fmin AND x.fmin > y.fmax );

COMMENT ON VIEW feature_disjoint IS 'featurelocs do not meet. symmetric';

-- 4-ary relation
CREATE OR REPLACE VIEW feature_union AS
SELECT
  x.feature_id  AS subject_id,
  y.feature_id  AS object_id,
  x.srcfeature_id,
  x.strand      AS subject_strand,
  y.strand      AS object_strand,
  CASE WHEN x.fmin<y.fmin THEN x.fmin ELSE y.fmin END AS fmin,
  CASE WHEN x.fmax>y.fmax THEN x.fmax ELSE y.fmax END AS fmax
FROM
 featureloc AS x,
 featureloc AS y
WHERE
 x.srcfeature_id=y.srcfeature_id
 AND
 ( x.fmax >= y.fmin AND x.fmin <= y.fmax );

COMMENT ON VIEW feature_union IS 'set-union on interval defined by featureloc. featurelocs must meet';


-- 4-ary relation
CREATE OR REPLACE VIEW feature_intersection AS
SELECT
  x.feature_id  AS subject_id,
  y.feature_id  AS object_id,
  x.srcfeature_id,
  x.strand      AS subject_strand,
  y.strand      AS object_strand,
  CASE WHEN x.fmin<y.fmin THEN y.fmin ELSE x.fmin END AS fmin,
  CASE WHEN x.fmax>y.fmax THEN y.fmax ELSE x.fmax END AS fmax
FROM
 featureloc AS x,
 featureloc AS y
WHERE
 x.srcfeature_id=y.srcfeature_id
 AND
 ( x.fmax >= y.fmin AND x.fmin <= y.fmax );

COMMENT ON VIEW feature_intersection IS 'set-intersection on interval defined by featureloc. featurelocs must meet';

-- 4-ary relation
-- subtract object interval from subject interval
--  (may leave zero, one or two intervals)
CREATE OR REPLACE VIEW feature_difference (
  subject_id,
  object_id,
  srcfeature_id,
  fmin,
  fmax,
  strand
) AS
-- left interval
SELECT
  x.feature_id,
  y.feature_id,
  x.strand,
  x.srcfeature_id,
  x.fmin,
  y.fmin
FROM
 featureloc AS x,
 featureloc AS y
WHERE
 x.srcfeature_id=y.srcfeature_id
 AND
 (x.fmin < y.fmin AND x.fmax >= y.fmax )
UNION
-- right interval
SELECT
  x.feature_id,
  y.feature_id,
  x.strand,
  x.srcfeature_id,
  y.fmax,
  x.fmax
FROM
 featureloc AS x,
 featureloc AS y
WHERE
 x.srcfeature_id=y.srcfeature_id
 AND
 (x.fmax > y.fmax AND x.fmin <= y.fmin );

COMMENT ON VIEW feature_difference IS 'set-distance on interval defined by featureloc. featurelocs must meet';

-- 4-ary relation
CREATE OR REPLACE VIEW feature_distance AS
SELECT
  x.feature_id  AS subject_id,
  y.feature_id  AS object_id,
  x.srcfeature_id,
  x.strand      AS subject_strand,
  y.strand      AS object_strand,
  CASE WHEN x.fmax <= y.fmin THEN (x.fmax-y.fmin) ELSE (y.fmax-x.fmin) END AS distance
FROM
 featureloc AS x,
 featureloc AS y
WHERE
 x.srcfeature_id=y.srcfeature_id
 AND
 ( x.fmax <= y.fmin OR x.fmin >= y.fmax );

COMMENT ON VIEW feature_difference IS 'size of gap between two features. must be abutting or disjoint';

-- [transitive,reflexive]
-- (should this be made non-reflexive?)
-- subject intervals contains (or is same as) object interval
CREATE OR REPLACE VIEW feature_contains (
  subject_id,
  object_id
) AS
SELECT
 x.feature_id,
 y.feature_id
FROM
 featureloc AS x,
 featureloc AS y
WHERE
 x.srcfeature_id=y.srcfeature_id
 AND
 ( y.fmin >= x.fmin AND y.fmin <= x.fmax );

COMMENT ON VIEW feature_contains IS 'subject intervals contains (or is
same as) object interval. transitive,reflexive';

-- featureset relations:
--  a featureset relation is true between any two features x and y
--  if the relation is true for any x' and y' where x' and y' are
--  subfeatures of x and y

-- see feature_meets
-- example: two transcripts meet if any of their exons or CDSs overlap
-- or abut
CREATE OR REPLACE VIEW featureset_meets (
  subject_id,
  object_id
) AS
SELECT
 x.object_id,
 y.object_id
FROM
 feature_meets AS r
 INNER JOIN feature_relationship AS x ON (r.subject_id = x.subject_id)
 INNER JOIN feature_relationship AS y ON (r.object_id = y.subject_id);

