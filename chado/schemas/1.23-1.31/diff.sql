--
-- Name: feature_by_fx_type; Type: TYPE; Schema: public; Owner: chado
--
ALTER TYPE feature_by_fx_type ALTER ATTRIBUTE feature_id SET DATA TYPE bigint;

--
-- Name: soi_type; Type: TYPE; Schema: public; Owner: chado
--
ALTER TYPE soi_type 
    ALTER ATTRIBUTE type_id TYPE bigint,
    ALTER ATTRIBUTE subject_id TYPE bigint,
    ALTER ATTRIBUTE object_id TYPE bigint;


SET search_path=frange,public,pg_catalog;

--
-- Name: _fill_featuregroup(bigint, bigint); Type: FUNCTION; Schema: frange; Owner: chado
--
DROP FUNCTION IF EXISTS _fill_featuregroup(integer, integer);
CREATE OR REPLACE FUNCTION _fill_featuregroup(bigint, bigint) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
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
$_$;

--
-- Name: fill_featuregroup(); Type: FUNCTION; Schema: frange; Owner: chado
--
DROP FUNCTION IF EXISTS fill_featuregroup();
CREATE OR REPLACE FUNCTION fill_featuregroup() RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    p featuregroup%ROWTYPE;
    l featureloc%ROWTYPE;
    isa bigint;
    -- c int;  the c variable isnt used
BEGIN
    TRUNCATE featuregroup;
    SELECT INTO isa cvterm_id FROM cvterm WHERE (name = 'isa' OR name = 'is_a');

    -- Recursion is the biggest performance killer for this function.
    -- We can dodge the first round of recursion using the "fr1 / GROUP BY" approach.
    -- Luckily, most feature graphs are only 2 levels deep, so most recursion is
    -- avoidable.

    RAISE NOTICE 'Loading root and singleton features.';
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

    RAISE NOTICE 'Loading child features.  If your database contains grandchild';
    RAISE NOTICE 'features, they will be loaded recursively and may take a long time.';

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
$$;

--
-- Name: featuregroup; Type: TABLE; Schema: frange; Owner: chado; Tablespace: 
--
ALTER TABLE featuregroup 
    ALTER featuregroup_id TYPE bigint,
    ALTER subject_id TYPE bigint,
    ALTER object_id TYPE bigint,
    ALTER group_id TYPE bigint,
    ALTER srcfeature_id TYPE bigint,
    ALTER fmin TYPE bigint,
    ALTER fmax TYPE bigint;
  
--
-- Name: groupcontains(bigint[], bigint[], character varying[]); Type: FUNCTION; Schema: frange; Owner: chado
--
DROP FUNCTION IF EXISTS groupcontains(integer[], integer[], character varying[]);
CREATE OR REPLACE FUNCTION groupcontains(bigint[], bigint[], character varying[]) RETURNS SETOF featuregroup
    LANGUAGE plpgsql
    AS $_$
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
$_$;

--
-- Name: groupcontains(bigint, bigint, character varying); Type: FUNCTION; Schema: frange; Owner: chado
--
DROP FUNCTION IF EXISTS groupcontains(integer, integer, character varying);
CREATE OR REPLACE FUNCTION groupcontains(bigint, bigint, character varying) RETURNS SETOF featuregroup
    LANGUAGE sql
    AS $_$
  SELECT *
  FROM groupoverlaps($1,$2,$3)
  WHERE fmin <= $1 AND fmax >= $2
$_$;

--
-- Name: groupidentical(bigint[], bigint[], character varying[]); Type: FUNCTION; Schema: frange; Owner: chado
--
DROP FUNCTION IF EXISTS groupidentical(integer[], integer[], character varying[]);
CREATE OR REPLACE FUNCTION groupidentical(bigint[], bigint[], character varying[]) RETURNS SETOF featuregroup
    LANGUAGE plpgsql
    AS $_$
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
$_$;

--
-- Name: groupidentical(bigint, bigint, character varying); Type: FUNCTION; Schema: frange; Owner: chado
--
DROP FUNCTION IF EXISTS groupidentical(integer, integer, character varying);
CREATE OR REPLACE FUNCTION groupidentical(bigint, bigint, character varying) RETURNS SETOF featuregroup
    LANGUAGE sql
    AS $_$
  SELECT *
  FROM groupoverlaps($1,$2,$3)
  WHERE fmin = $1 AND fmax = $2
$_$;

--
-- Name: groupinside(bigint[], bigint[], character varying[]); Type: FUNCTION; Schema: frange; Owner: chado
--
DROP FUNCTION IF EXISTS groupinside(integer[], integer[], character varying[]);
CREATE OR REPLACE FUNCTION groupinside(bigint[], bigint[], character varying[]) RETURNS SETOF featuregroup
    LANGUAGE plpgsql
    AS $_$
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
$_$;

--
-- Name: groupinside(bigint, bigint, character varying); Type: FUNCTION; Schema: frange; Owner: chado
--
DROP FUNCTION IF EXISTS groupinside(integer, integer, character varying);
CREATE OR REPLACE FUNCTION groupinside(bigint, bigint, character varying) RETURNS SETOF featuregroup
    LANGUAGE sql
    AS $_$
  SELECT *
  FROM groupoverlaps($1,$2,$3)
  WHERE fmin >= $1 AND fmax <= $2
$_$;

--
-- Name: groupoverlaps(bigint, bigint); Type: FUNCTION; Schema: frange; Owner: chado
--
DROP FUNCTION IF EXISTS groupoverlaps(integer, integer);
CREATE OR REPLACE FUNCTION groupoverlaps(bigint, bigint) RETURNS SETOF featuregroup
    LANGUAGE sql
    AS $_$
  SELECT *
  FROM featuregroup
  WHERE is_root = 1
    AND boxquery($1, $2) @ boxrange(fmin,fmax)
$_$;

--
-- Name: groupoverlaps(bigint[], bigint[], character varying[]); Type: FUNCTION; Schema: frange; Owner: chado
--
DROP FUNCTION IF EXISTS groupoverlaps(integer[], integer[], character varying[]);
CREATE OR REPLACE FUNCTION groupoverlaps(bigint[], bigint[], character varying[]) RETURNS SETOF featuregroup
    LANGUAGE plpgsql
    AS $_$
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
$_$;

--
-- Name: groupoverlaps(bigint, bigint, character varying); Type: FUNCTION; Schema: frange; Owner: chado
--
DROP FUNCTION IF EXISTS groupoverlaps(integer, integer, character varying); 
CREATE OR REPLACE FUNCTION groupoverlaps(bigint, bigint, character varying) RETURNS SETOF featuregroup
    LANGUAGE sql
    AS $_$
  SELECT g2.*
  FROM  featuregroup g1,
        featuregroup g2
  WHERE g1.is_root = 1
    AND ( g1.srcfeature_id = g2.srcfeature_id OR g2.srcfeature_id IS NULL )
    AND g1.group_id = g2.group_id
    AND g1.srcfeature_id = (SELECT feature_id FROM feature WHERE uniquename = $3)
    AND boxquery($1, $2) @ boxrange(g1.fmin,g2.fmax)
$_$;

SET search_path = public, pg_catalog;

--
-- Name: cvtermpath; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--
ALTER TABLE cvtermpath 
    ALTER cvtermpath_id TYPE bigint,
    ALTER type_id TYPE bigint,
    ALTER subject_id TYPE bigint,
    ALTER object_id TYPE bigint,
    ALTER cv_id TYPE bigint;
  
--
-- Name: create_point(bigint, bigint); Type: FUNCTION; Schema: public; Owner: chado
--
DROP FUNCTION IF EXISTS create_point(integer, integer);
CREATE OR REPLACE FUNCTION create_point(bigint, bigint) RETURNS point
    LANGUAGE sql
    AS $_$SELECT point ($1, $2)$_$;
    
--
-- Name: boxquery(bigint, bigint); Type: FUNCTION; Schema: public; Owner: chado
--
DROP FUNCTION IF EXISTS boxquery(integer, integer);
CREATE OR REPLACE FUNCTION boxquery(bigint, bigint) RETURNS box
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT box (create_point($1, $2), create_point($1, $2))$_$;


--
-- Name: boxquery(bigint, bigint, bigint); Type: FUNCTION; Schema: public; Owner: chado
--
DROP FUNCTION IF EXISTS boxquery(integer, integer, integer);
CREATE OR REPLACE FUNCTION boxquery(bigint, bigint, bigint) RETURNS box
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT box (create_point($1, $2), create_point($1, $3))$_$;

--
-- Name: boxrange(bigint, bigint); Type: FUNCTION; Schema: public; Owner: chado
--
DROP INDEX binloc_boxrange;
DROP FUNCTION IF EXISTS boxrange(integer, integer);
CREATE OR REPLACE FUNCTION boxrange(bigint, bigint) RETURNS box
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT box (create_point(0, $1), create_point($2,500000000))$_$;

--
-- Name: boxrange(bigint, bigint, bigint); Type: FUNCTION; Schema: public; Owner: chado
--
DROP FUNCTION IF EXISTS boxrange(integer, integer, integer);
CREATE OR REPLACE FUNCTION boxrange(bigint, bigint, bigint) RETURNS box
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT box (create_point($1, $2), create_point($1,$3))$_$;
    
--
-- Name: create_soi(); Type: FUNCTION; Schema: public; Owner: chado
--
DROP FUNCTION IF EXISTS create_soi();
CREATE OR REPLACE FUNCTION create_soi() RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    parent soi_type%ROWTYPE;
    isa_id cvterm.cvterm_id%TYPE;
    soi_term TEXT := 'soi';
    soi_def TEXT := 'ontology of SO feature instantiated in database';
    soi_cvid bigint;
    soiterm_id bigint;
    pcount INTEGER;
    count INTEGER := 0;
    cquery TEXT;
BEGIN

    SELECT INTO isa_id cvterm_id FROM cvterm WHERE name = 'isa';

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

    CREATE TEMP TABLE tmpcvtr (tmp_type INT, type_id bigint, subject_id bigint, object_id bigint);
    CREATE UNIQUE INDEX u_tmpcvtr ON tmpcvtr(subject_id, object_id);

    INSERT INTO tmpcvtr (tmp_type, type_id, subject_id, object_id)
        SELECT DISTINCT isa_id, soiterm_id, f.type_id, soiterm_id FROM feature f, cvterm t
        WHERE f.type_id = t.cvterm_id AND f.type_id > 0;
    EXECUTE 'select * from tmpcvtr where type_id = ' || soiterm_id || ';';
    get diagnostics pcount = row_count;
    raise notice 'all types in feature %',pcount;
--- do it hard way, delete any child feature type from above (NOT IN clause did not work)
    FOR parent IN SELECT DISTINCT 0, t.cvterm_id, 0 FROM feature c, feature_relationship fr, cvterm t
            WHERE t.cvterm_id = c.type_id AND c.feature_id = fr.subject_id LOOP
        DELETE FROM tmpcvtr WHERE type_id = soiterm_id and object_id = soiterm_id
            AND subject_id = parent.subject_id;
    END LOOP;
    EXECUTE 'select * from tmpcvtr where type_id = ' || soiterm_id || ';';
    get diagnostics pcount = row_count;
    raise notice 'all types in feature after delete child %',pcount;

    --- create feature type relationship (store in tmpcvtr)
    CREATE TEMP TABLE tmproot (cv_id bigint not null, cvterm_id bigint not null, status INTEGER DEFAULT 0);
    cquery := 'SELECT * FROM tmproot tmp WHERE tmp.status = 0;';
    ---temp use tmpcvtr to hold instantiated SO relationship for speed
    ---use soterm_id as type_id, will delete from tmpcvtr
    ---us tmproot for this as well
    INSERT INTO tmproot (cv_id, cvterm_id, status) SELECT DISTINCT soi_cvid, c.subject_id, 0 FROM tmpcvtr c
        WHERE c.object_id = soiterm_id;
    EXECUTE cquery;
    GET DIAGNOSTICS pcount = ROW_COUNT;
    WHILE (pcount > 0) LOOP
        RAISE NOTICE 'num child temp (to be inserted) in tmpcvtr: %',pcount;
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
$$;

--
-- Name: feature; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--
ALTER TABLE feature 
    ALTER feature_id TYPE  bigint,
    ALTER dbxref_id TYPE bigint,
    ALTER organism_id TYPE bigint,
    ALTER seqlen TYPE bigint,
    ALTER type_id TYPE bigint;
  
--
-- Name: feature_disjoint_from(bigint); Type: FUNCTION; Schema: public; Owner: chado
--
DROP FUNCTION IF EXISTS feature_disjoint_from(integer);
CREATE OR REPLACE FUNCTION feature_disjoint_from(bigint) RETURNS SETOF feature
    LANGUAGE sql
    AS $_$SELECT feature.*
  FROM feature
   INNER JOIN featureloc AS x ON (x.feature_id=feature.feature_id)
   INNER JOIN featureloc AS y ON (y.feature_id = $1)
  WHERE
   x.srcfeature_id = y.srcfeature_id            AND
   ( x.fmax < y.fmin OR x.fmin > y.fmax ) $_$;

--
-- Name: feature_overlaps(bigint); Type: FUNCTION; Schema: public; Owner: chado
--
DROP FUNCTION IF EXISTS feature_overlaps(integer);
CREATE OR REPLACE FUNCTION feature_overlaps(bigint) RETURNS SETOF feature
    LANGUAGE sql
    AS $_$SELECT feature.*
  FROM feature
   INNER JOIN featureloc AS x ON (x.feature_id=feature.feature_id)
   INNER JOIN featureloc AS y ON (y.feature_id = $1)
  WHERE
   x.srcfeature_id = y.srcfeature_id            AND
   ( x.fmax >= y.fmin AND x.fmin <= y.fmax ) $_$;

--
-- Name: featureloc; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--
ALTER TABLE FEATURELOC
    ALTER featureloc_id TYPE bigint,
    ALTER feature_id TYPE bigint,
    ALTER srcfeature_id TYPE bigint,
    ALTER fmin TYPE bigint,
    ALTER fmax TYPE bigint;
  
--
-- Name: featureloc_slice(bigint, bigint); Type: FUNCTION; Schema: public; Owner: chado
--
DROP FUNCTION IF EXISTS featureloc_slice(integer, integer);
CREATE OR REPLACE FUNCTION featureloc_slice(bigint, bigint) RETURNS SETOF featureloc
    LANGUAGE sql
    AS $_$SELECT * from featureloc where boxquery($1, $2) @ boxrange(fmin,fmax)$_$;

--
-- Name: featureloc_slice(integer, bigint, bigint); Type: FUNCTION; Schema: public; Owner: chado
--
DROP FUNCTION IF EXISTS featureloc_slice(integer, integer, integer);
CREATE OR REPLACE FUNCTION featureloc_slice(integer, bigint, bigint) RETURNS SETOF featureloc
    LANGUAGE sql
    AS $_$SELECT * 
   FROM featureloc 
   WHERE boxquery($2, $3) @ boxrange(fmin,fmax)
   AND srcfeature_id = $1 $_$;

--
-- Name: featureloc_slice(bigint, bigint, bigint); Type: FUNCTION; Schema: public; Owner: chado
--
DROP FUNCTION IF EXISTS featureloc_slice(integer, integer, integer);
CREATE OR REPLACE FUNCTION featureloc_slice(bigint, bigint, bigint) RETURNS SETOF featureloc
    LANGUAGE sql
    AS $_$SELECT * 
   FROM featureloc 
   WHERE boxquery($1, $2, $3) && boxrange(srcfeature_id,fmin,fmax)$_$;

--
-- Name: featureloc_slice(character varying, bigint, bigint); Type: FUNCTION; Schema: public; Owner: chado
--
DROP FUNCTION IF EXISTS featureloc_slice(character varying, integer, integer);
CREATE OR REPLACE FUNCTION featureloc_slice(character varying, bigint, bigint) RETURNS SETOF featureloc
    LANGUAGE sql
    AS $_$SELECT featureloc.* 
   FROM featureloc 
   INNER JOIN feature AS srcf ON (srcf.feature_id = featureloc.srcfeature_id)
   WHERE boxquery($2, $3) @ boxrange(fmin,fmax)
   AND srcf.name = $1 $_$;

--
-- Name: get_cv_id_for_feature(); Type: FUNCTION; Schema: public; Owner: chado
--

DROP FUNCTION IF EXISTS get_cv_id_for_feature();
CREATE OR REPLACE FUNCTION get_cv_id_for_feature() RETURNS bigint
    LANGUAGE sql
    AS $$SELECT cv_id FROM cv WHERE name='sequence'$$;


--
-- Name: cv; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE cv ALTER cv_id TYPE bigint;
l
--
-- Name: get_cv_id_for_feature_relationsgip(); Type: FUNCTION; Schema: public; Owner: chado
--

DROP FUNCTION IF EXISTS get_cv_id_for_feature_relationsgip();
CREATE OR REPLACE FUNCTION get_cv_id_for_feature_relationsgip() RETURNS bigint
    LANGUAGE sql
    AS $$SELECT cv_id FROM cv WHERE name='relationship'$$;

--
-- Name: get_cv_id_for_featureprop(); Type: FUNCTION; Schema: public; Owner: chado
--
DROP FUNCTION IF EXISTS get_cv_id_for_featureprop()
CREATE OR REPLACE FUNCTION get_cv_id_for_featureprop() RETURNS bigint
    LANGUAGE sql
    AS $$SELECT cv_id FROM cv WHERE name='feature_property'$$;

--
-- Name: get_cycle_cvterm_id(integer); Type: FUNCTION; Schema: public; Owner: chado
--
DROP FUNCTION IF EXISTS get_cycle_cvterm_id(integer);
CREATE OR REPLACE FUNCTION get_cycle_cvterm_id(integer) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
DECLARE
    cvid alias for $1;
    root cvterm%ROWTYPE;
    rtn     int;
BEGIN

    CREATE TEMP TABLE tmpcvtermpath(object_id bigint, subject_id bigint, cv_id bigint, type_id bigint, pathdistance int);
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
$_$;

--
-- Name: get_cycle_cvterm_id(character varying); Type: FUNCTION; Schema: public; Owner: chado
--
DROP FUNCTION IF EXISTS get_cycle_cvterm_id(character varying);
CREATE OR REPLACE FUNCTION get_cycle_cvterm_id(character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
DECLARE
    cvname alias for $1;
    cv_id bigint;
    rtn int;
BEGIN

    SELECT INTO cv_id cv.cv_id from cv WHERE cv.name = cvname;
    SELECT INTO rtn  get_cycle_cvterm_id(cv_id);

    RETURN rtn;
END;   
$_$;

--
-- Name: get_cycle_cvterm_id(integer, integer); Type: FUNCTION; Schema: public; Owner: chado
--
DROP FUNCTION IF EXISTS get_cycle_cvterm_id(integer, integer);
CREATE OR REPLACE FUNCTION get_cycle_cvterm_id(integer, integer) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
DECLARE
    cvid alias for $1;
    rootid alias for $2;
    rtn     int;
BEGIN

    CREATE TEMP TABLE tmpcvtermpath(object_id bigint, subject_id bigint, cv_id bigint, type_id bigint, pathdistance int);
    CREATE INDEX tmp_cvtpath1 ON tmpcvtermpath(object_id, subject_id);

    SELECT INTO rtn _fill_cvtermpath4root2detect_cycle(rootid, cvid);
    IF (rtn > 0) THEN
        DROP TABLE tmpcvtermpath;
        RETURN rtn;
    END IF;
    DROP TABLE tmpcvtermpath;
    RETURN 0;
END;   
$_$;

--
-- Name: get_feature_id(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: chado
--
DROP FUNCTION IF EXISTS get_feature_id(character varying, character varying, character varying);
CREATE OR REPLACE FUNCTION get_feature_id(character varying, character varying, character varying) RETURNS bigint
    LANGUAGE sql
    AS $_$
  SELECT feature_id 
  FROM feature
  WHERE uniquename=$1
    AND type_id=get_feature_type_id($2)
    AND organism_id=get_organism_id($3)
 $_$;

--
-- Name: get_feature_relationship_type_id(character varying); Type: FUNCTION; Schema: public; Owner: chado
--
DROP FUNCTION IF EXISTS get_feature_relationship_type_id(character varying);
CREATE OR REPLACE FUNCTION get_feature_relationship_type_id(character varying) RETURNS bigint
    LANGUAGE sql
    AS $_$
  SELECT cvterm_id 
  FROM cv INNER JOIN cvterm USING (cv_id)
  WHERE cvterm.name=$1 AND cv.name='relationship'
 $_$;

--
-- Name: get_feature_type_id(character varying); Type: FUNCTION; Schema: public; Owner: chado
--
DROP FUNCTION IF EXISTS get_feature_type_id(character varying);
CREATE OR REPLACE FUNCTION get_feature_type_id(character varying) RETURNS bigint
    LANGUAGE sql
    AS $_$ 
  SELECT cvterm_id 
  FROM cv INNER JOIN cvterm USING (cv_id)
  WHERE cvterm.name=$1 AND cv.name='sequence'
 $_$

--
-- Name: get_featureprop_type_id(character varying); Type: FUNCTION; Schema: public; Owner: chado
--
DROP FUNCTION IF EXISTS get_featureprop_type_id(character varying);
CREATE OR REPLACE FUNCTION get_featureprop_type_id(character varying) RETURNS bigint
    LANGUAGE sql
    AS $_$
  SELECT cvterm_id 
  FROM cv INNER JOIN cvterm USING (cv_id)
  WHERE cvterm.name=$1 AND cv.name='feature_property'
 $_$;
 
--
-- Name: cvterm; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--
ALTER TABLE cvterm
    ALTER cvterm_id TYPE bigint,
    ALTER cv_id TYPE bigint,
    ALTER dbxref_id TYPE bigint; 

--
-- Name: get_organism_id(character varying); Type: FUNCTION; Schema: public; Owner: chado
--
DROP FUNCTION IF EXISTS get_organism_id(character varying);
CREATE OR REPLACE FUNCTION get_organism_id(character varying) RETURNS bigint
    LANGUAGE sql
    AS $_$ 
SELECT organism_id
  FROM organism
  WHERE genus=substring($1,1,position(' ' IN $1)-1)
    AND species=substring($1,position(' ' IN $1)+1)
 $_$;
 
--
-- Name: get_organism_id(character varying, character varying); Type: FUNCTION; Schema: public; Owner: chado
--
DROP FUNCTION IF EXISTS get_organism_id(character varying, character varying);
CREATE OR REPLACE FUNCTION get_organism_id(character varying, character varying) RETURNS bigint
    LANGUAGE sql
    AS $_$
  SELECT organism_id 
  FROM organism
  WHERE genus=$1
    AND species=$2
 $_$;
 
--
-- Name: get_organism_id_abbrev(character varying); Type: FUNCTION; Schema: public; Owner: chado
--
DROP FUNCTION IF EXISTS get_organism_id_abbrev(character varying);
CREATE OR REPLACE FUNCTION get_organism_id_abbrev(character varying) RETURNS bigint
    LANGUAGE sql
    AS $_$
SELECT organism_id
  FROM organism
  WHERE substr(genus,1,1)=substring($1,1,1)
    AND species=substring($1,position(' ' IN $1)+1)
 $_$;

--
-- Name: db; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--
ALTER TABLE db ALTER db_id TYPE bigint;

--
-- Name: dbxref; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--
ALTER TABLE dbxref
    ALTER dbxref_id TYPE bigint,
    ALTER db_id TYPE bigint;

--
-- Name: feature_cvterm; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--
ALTER TABLE feature_cvterm
    ALTER feature_cvterm_id TYPE bigint,
    ALTER feature_id TYPE bigint,
    ALTER cvterm_id TYPE bigint,
    ALTER pub_id TYPE bigint;
  
--
-- Name: feature_dbxref; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--
ALTER TABLE feature_dbxref
    ALTER feature_dbxref_id TYPE bigint,
    ALTER feature_id TYPE bigint,
    ALTER dbxref_id TYPE bigint;
  
--
-- Name: TABLE feature_dbxref; Type: COMMENT; Schema: public; Owner: chado
--
COMMENT ON TABLE feature_dbxref IS 'Links a feature to dbxrefs.';

--
-- Name: COLUMN feature_dbxref.is_current; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON COLUMN feature_dbxref.is_current IS 'True if this secondary dbxref is 
the most up to date accession in the corresponding db. Retired accessions 
should set this field to false';

--
-- Name: feature_pub; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--
ALTER TABLE feature_pub
    ALTER feature_pub_id TYPE bigint,
    ALTER feature_id  TYPE bigint,
    ALTER pub_id TYPE bigint;

--
-- Name: feature_synonym; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--
ALTER TABLE feature_synonym
    ALTER feature_synonym_id TYPE bigint,
    ALTER synonym_id TYPE bigint,
    ALTER feature_id TYPE bigint,
    ALTER pub_id TYPE bigint;
  
--
-- Name: featureprop; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--
ALTER TABLE featureprop
    ALTER featureprop_id TYPE bigint,
    ALTER feature_id TYPE bigint,
    ALTER type_id TYPE bigint;
  
--
-- Name: pub; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--
ALTER TABLE pub
    ALTER pub_id TYPE bigint,
    ALTER type_id TYPE bigint;
  
--
-- Name: synonym; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--
ALTER TABLE synonym
    ALTER synonym_id TYPE bigint,
    ALTER type_id TYPE bigin;
  
--
-- Name: phylonode_depth(bigint); Type: FUNCTION; Schema: public; Owner: chado
--
DROP FUNCTION IF EXISTS phylonode_depth(integer);
CREATE OR REPLACE FUNCTION phylonode_depth(bigint) RETURNS double precision
    LANGUAGE plpgsql
    AS $_$DECLARE  id    ALIAS FOR $1;
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
$_$;

--
-- Name: phylonode_height(bigint); Type: FUNCTION; Schema: public; Owner: chado
--
DROP FUNCTION IF EXISTS phylonode_height(integer);
CREATE OR REPLACE FUNCTION phylonode_height(bigint) RETURNS double precision
    LANGUAGE sql
    AS $_$
  SELECT coalesce(max(phylonode_height(phylonode_id) + distance), 0.0)
    FROM phylonode
    WHERE parent_phylonode_id = $1
$_$;

--
-- Name: subsequence(bigint, bigint, bigint, integer); Type: FUNCTION; Schema: public; Owner: chado
--
DROP FUNCTION IF EXISTS subsequence(integer, integer, integer, integer);
CREATE OR REPLACE FUNCTION subsequence(bigint, bigint, bigint, integer) RETURNS text
    LANGUAGE sql
    AS $_$SELECT 
  CASE WHEN $4<0 
   THEN reverse_complement(substring(srcf.residues,CAST(($2+1) as int),CAST(($3-$2) as int)))
   ELSE substring(residues,CAST(($2+1) as int),CAST(($3-$2) as int))
  END AS residues
  FROM feature AS srcf
  WHERE
   srcf.feature_id=$1$_$;

--
-- Name: subsequence_by_feature(bigint); Type: FUNCTION; Schema: public; Owner: chado
--
DROP FUNCTION IF EXISTS subsequence_by_feature(integer);
CREATE OR REPLACE FUNCTION subsequence_by_feature(bigint) RETURNS text
    LANGUAGE sql
    AS $_$SELECT subsequence_by_feature($1,0,0)$_$;

--
-- Name: subsequence_by_feature(bigint, integer, integer); Type: FUNCTION; Schema: public; Owner: chado
--
DROP FUNCTION IF EXISTS subsequence_by_feature(integer, integer, integer);
CREATE OR REPLACE FUNCTION subsequence_by_feature(bigint, integer, integer) RETURNS text
    LANGUAGE sql
    AS $_$SELECT 
  CASE WHEN strand<0 
   THEN reverse_complement(substring(srcf.residues,CAST(fmin+1 as int),CAST((fmax-fmin) as int)))
   ELSE substring(srcf.residues,CAST(fmin+1 as int),CAST((fmax-fmin) as int))
  END AS residues
  FROM feature AS srcf
   INNER JOIN featureloc ON (srcf.feature_id=featureloc.srcfeature_id)
  WHERE
   featureloc.feature_id=$1 AND
   featureloc.rank=$2 AND
   featureloc.locgroup=$3$_$;

--
-- Name: subsequence_by_featureloc(bigint); Type: FUNCTION; Schema: public; Owner: chado
--
DROP FUNCTION IF EXISTS subsequence_by_featureloc(integer);
CREATE OR REPLACE FUNCTION subsequence_by_featureloc(bigint) RETURNS text
    LANGUAGE sql
    AS $_$SELECT 
  CASE WHEN strand<0 
   THEN reverse_complement(substring(srcf.residues,CAST(fmin+1 as int),CAST((fmax-fmin) as int)))
   ELSE substring(srcf.residues,CAST(fmin+1 as int),CAST((fmax-fmin) as int))
  END AS residues
  FROM feature AS srcf
   INNER JOIN featureloc ON (srcf.feature_id=featureloc.srcfeature_id)
  WHERE
   featureloc_id=$1$_$;

--
-- Name: subsequence_by_subfeatures(bigint); Type: FUNCTION; Schema: public; Owner: chado
--
DROP FUNCTION IF EXISTS subsequence_by_subfeatures(integer);
CREATE OR REPLACE FUNCTION subsequence_by_subfeatures(bigint) RETURNS text
    LANGUAGE sql
    AS $_$
SELECT subsequence_by_subfeatures($1,get_feature_relationship_type_id('part_of'),0,0)
$_$;

--
-- Name: subsequence_by_subfeatures(bigint, bigint); Type: FUNCTION; Schema: public; Owner: chado
--
DROP FUNCTION IF EXISTS subsequence_by_subfeatures(integer, integer);
CREATE OR REPLACE FUNCTION subsequence_by_subfeatures(bigint, bigint) RETURNS text
    LANGUAGE sql
    AS $_$SELECT subsequence_by_subfeatures($1,$2,0,0)$_$;


--
-- Name: subsequence_by_subfeatures(bigint, bigint, integer, integer); Type: FUNCTION; Schema: public; Owner: chado
--
DROP FUNCTION IF EXISTS subsequence_by_subfeatures(integer, integer, integer, integer);
CREATE OR REPLACE FUNCTION subsequence_by_subfeatures(bigint, bigint, integer, integer) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE v_feature_id ALIAS FOR $1;
DECLARE v_rtype_id   ALIAS FOR $2;
DECLARE v_rank       ALIAS FOR $3;
DECLARE v_locgroup   ALIAS FOR $4;
DECLARE subseq       TEXT;
DECLARE seqrow       RECORD;
BEGIN 
  subseq = '';
 FOR seqrow IN
   SELECT
    CASE WHEN strand<0 
     THEN reverse_complement(substring(srcf.residues,CAST(fmin+1 as int),CAST((fmax-fmin) as int)))
     ELSE substring(srcf.residues,CAST(fmin+1 as int),CAST((fmax-fmin) as int))
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
$_$;

--
-- Name: subsequence_by_typed_subfeatures(bigint, bigint); Type: FUNCTION; Schema: public; Owner: chado
--
DROP FUNCTION IF EXISTS subsequence_by_typed_subfeatures(integer, integer);
CREATE OR REPLACE FUNCTION subsequence_by_typed_subfeatures(bigint, bigint) RETURNS text
    LANGUAGE sql
    AS $_$SELECT subsequence_by_typed_subfeatures($1,$2,0,0)$_$;

--
-- Name: subsequence_by_typed_subfeatures(bigint, bigint, integer, integer); Type: FUNCTION; Schema: public; Owner: chado
--
DROP FUNCTION IF EXISTS subsequence_by_typed_subfeatures(integer, integer, integer, integer);
CREATE OR REPLACE FUNCTION subsequence_by_typed_subfeatures(bigint, bigint, integer, integer) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE v_feature_id ALIAS FOR $1;
DECLARE v_ftype_id   ALIAS FOR $2;
DECLARE v_rank       ALIAS FOR $3;
DECLARE v_locgroup   ALIAS FOR $4;
DECLARE subseq       TEXT;
DECLARE seqrow       RECORD;
BEGIN 
  subseq = '';
 FOR seqrow IN
   SELECT
    CASE WHEN strand<0 
     THEN reverse_complement(substring(srcf.residues,CAST(fmin+1 as int),CAST((fmax-fmin) as int)))
     ELSE substring(srcf.residues,CAST(fmin+1 as int),CAST((fmax-fmin) as int))
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
$_$;


--
-- Name: acquisition; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--
ALTER TABLE acquisition
    ALTER acquisition_id TYPE bigint
    ALTER assy_id TYPE bigint
    ALTER protocol_id bigint
    ALTER channel_id bigint;
  
--
-- Name: acquisition_relationship; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE acquisition_relationship 
    ALTER acquisition_relationship_id TYPE bigint,
    ALTER subject_id TYPE bigint,
    ALTER type_id TYPE bigint,
    ALTER object_id TYPE bigint;

--
-- Name: acquisitionprop; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE acquisitionprop 
    ALTER acquisitionprop_id TYPE bigint,
    ALTER acquisition_id TYPE bigint,
    ALTER type_id TYPE bigint;

--
-- Name: analysis; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE analysis ALTER analysis_id TYPE bigint;

--
-- Name: analysis_cvterm; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

CREATE TABLE analysis_cvterm (
    analysis_cvterm_id bigint NOT NULL,
    analysis_id bigint NOT NULL,
    cvterm_id bigint NOT NULL,
    is_not boolean DEFAULT false NOT NULL,
    rank integer DEFAULT 0 NOT NULL
);


--
-- Name: TABLE analysis_cvterm; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON TABLE analysis_cvterm IS 'Associate a term from a cv with an analysis.';


--
-- Name: COLUMN analysis_cvterm.is_not; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON COLUMN analysis_cvterm.is_not IS 'If this is set to true, then this 
annotation is interpreted as a NEGATIVE annotation - i.e. the analysis does 
NOT have the specified term.';


--
-- Name: analysis_cvterm_analysis_cvterm_id_seq; Type: SEQUENCE; Schema: public; Owner: chado
--

CREATE SEQUENCE analysis_cvterm_analysis_cvterm_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: analysis_cvterm_analysis_cvterm_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: chado
--

ALTER SEQUENCE analysis_cvterm_analysis_cvterm_id_seq OWNED BY analysis_cvterm.analysis_cvterm_id;


--
-- Name: analysis_dbxref; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

CREATE TABLE analysis_dbxref (
    analysis_dbxref_id bigint NOT NULL,
    analysis_id bigint NOT NULL,
    dbxref_id bigint NOT NULL,
    is_current boolean DEFAULT true NOT NULL
);


--
-- Name: TABLE analysis_dbxref; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON TABLE analysis_dbxref IS 'Links an analysis to dbxrefs.';


--
-- Name: COLUMN analysis_dbxref.is_current; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON COLUMN analysis_dbxref.is_current IS 'True if this dbxref 
is the most up to date accession in the corresponding db. Retired 
accessions should set this field to false';


--
-- Name: analysis_dbxref_analysis_dbxref_id_seq; Type: SEQUENCE; Schema: public; Owner: chado
--

CREATE SEQUENCE analysis_dbxref_analysis_dbxref_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: analysis_dbxref_analysis_dbxref_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: chado
--

ALTER SEQUENCE analysis_dbxref_analysis_dbxref_id_seq OWNED BY analysis_dbxref.analysis_dbxref_id;


--
-- Name: analysis_pub; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

CREATE TABLE analysis_pub (
    analysis_pub_id bigint NOT NULL,
    analysis_id bigint NOT NULL,
    pub_id bigint NOT NULL
);



--
-- Name: TABLE analysis_pub; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON TABLE analysis_pub IS 'Provenance. Linking table between analyses and the publications that mention them.';


--
-- Name: analysis_pub_analysis_pub_id_seq; Type: SEQUENCE; Schema: public; Owner: chado
--

CREATE SEQUENCE analysis_pub_analysis_pub_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: analysis_pub_analysis_pub_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: chado
--

ALTER SEQUENCE analysis_pub_analysis_pub_id_seq OWNED BY analysis_pub.analysis_pub_id;


--
-- Name: analysis_relationship; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

CREATE TABLE analysis_relationship (
    analysis_relationship_id bigint NOT NULL,
    subject_id bigint NOT NULL,
    object_id bigint NOT NULL,
    type_id bigint NOT NULL,
    value text,
    rank integer DEFAULT 0 NOT NULL
);


--
-- Name: COLUMN analysis_relationship.subject_id; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON COLUMN analysis_relationship.subject_id IS 'analysis_relationship.subject_id i
s the subject of the subj-predicate-obj sentence.';


--
-- Name: COLUMN analysis_relationship.object_id; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON COLUMN analysis_relationship.object_id IS 'analysis_relationship.object_id 
is the object of the subj-predicate-obj sentence.';


--
-- Name: COLUMN analysis_relationship.type_id; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON COLUMN analysis_relationship.type_id IS 'analysis_relationship.type_id 
is relationship type between subject and object. This is a cvterm, typically 
from the OBO relationship ontology, although other relationship types are allowed.';


--
-- Name: COLUMN analysis_relationship.value; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON COLUMN analysis_relationship.value IS 'analysis_relationship.value 
is for additional notes or comments.';


--
-- Name: COLUMN analysis_relationship.rank; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON COLUMN analysis_relationship.rank IS 'analysis_relationship.rank is 
the ordering of subject analysiss with respect to the object analysis may be 
important where rank is used to order these; starts from zero.';


--
-- Name: analysis_relationship_analysis_relationship_id_seq; Type: SEQUENCE; Schema: public; Owner: chado
--

CREATE SEQUENCE analysis_relationship_analysis_relationship_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: analysis_relationship_analysis_relationship_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: chado
--

ALTER SEQUENCE analysis_relationship_analysis_relationship_id_seq OWNED BY analysis_relationship.analysis_relationship_id;

--
-- Name: analysisfeature; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE analysisfeature 
    ALTER analysisfeature_id TYPE bigint,
    ALTER feature_id TYPE bigint,
    ALTER analysis_id TYPE bigint;
  
--
-- Name: analysisfeatureprop; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE analysisfeatureprop 
    ALTER analysisfeatureprop_id TYPE bigint,
    ALTER analysisfeature_id TYPE bigint,
    ALTER type_id TYPE bigint;
  
--
-- Name: analysisprop; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE analysisprop 
    ALTER analysisprop_id TYPE bigint,
    ALTER analysis_id TYPE bigint,
    ALTER type_id TYPE bigint;
  
--
-- Name: arraydesign; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE arraydesign
    ALTER arraydesign_id TYPE bigint,
    ALTER manufacturer_id TYPE bigint,
    ALTER platformtype_id TYPE bigint,
    ALTER substratetype_id TYPE bigint,
    ALTER protocol_id TYPE bigint,
    ALTER dbxref_id TYPE bigint;
  
  
--
-- Name: arraydesignprop; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE arraydesignprop 
    ALTER arraydesignprop_id TYPE bigint,
    ALTER arraydesign_id TYPE bigint,
    ALTER type_id TYPE bigint;
  
  
--
-- Name: assay; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE assay 
    ALTER assay_id TYPE bigint,
    ALTER arraydesign_id TYPE bigint,
    ALTER protocol_id TYPE bigint,
    ALTER operator_id TYPE bigint,
    ALTER dbxref_id TYPE bigint;
  
--
-- Name: assay_biomaterial; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE assay_biomaterial
    ALTER assay_biomaterial_id TYPE bigint,
    ALTER assay_id TYPE bigint,
    ALTER biomaterial_id TYPE bigint,
    ALTER channel_id TYPE bigint;
  
--
-- Name: assay_project; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE assay_project
    ALTER assay_project_id TYPE bigint,
    ALTER assay_id TYPE bigint,
    ALTER project_id TYPE bigint;
  
--
-- Name: assayprop; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE assayprop 
    ALTER assayprop_id TYPE bigint,
    ALTER assay_id TYPE bigint,
    ALTER type_id TYPE bigint;
  
--
-- Name: biomaterial; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE biomaterial
    ALTER biomaterial_id TYPE bigint,
    ALTER taxon_id TYPE bigint,
    ALTER biosourceprovider_id TYPE bigint,
    ALTER dbxref_id bigint;

--
-- Name: biomaterial_dbxref; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE biomaterial_dbxref
    ALTER biomaterial_dbxref_id TYPE bigint,
    ALTER biomaterial_id TYPE bigint,
    ALTER dbxref_id TYPE bigint;
  
--
-- Name: biomaterial_dbxref; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE biomaterial_dbxref
    ALTER biomaterial_dbxref_id TYPE bigint,
    ALTER biomaterial_id TYPE bigint,
    ALTER dbxref_id TYPE bigint;

--
-- Name: biomaterial_relationship; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE biomaterial_relationship 
    ALTER biomaterial_relationship_id TYPE bigint,
    ALTER subject_id TYPE bigint,
    ALTER type_id TYPE bigint,
    ALTER object_id TYPE bigint;

--
-- Name: biomaterial_treatment; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE biomaterial_treatment 
    ALTER biomaterial_treatment_id TYPE bigint,
    ALTER biomaterial_id TYPE bigint,
    ALTER treatment_id TYPE bigint,
    ALTER unittype_id TYPE bigint;
  
--
-- Name: biomaterialprop; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE biomaterialprop 
    ALTER biomaterialprop_id TYPE bigint,
    ALTER biomaterial_id TYPE bigint,
    ALTER type_id TYPE bigint;
  
--
-- Name: cell_line; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE cell_line
    ALTER cell_line_id TYPE bigint,
    ALTER organism_id TYPE bigint;
  
--
-- Name: cell_line_cvterm; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE cell_line_cvterm 
    ALTER cell_line_cvterm_id TYPE bigint,
    ALTER cell_line_id TYPE bigint,
    ALTER cvterm_id TYPE bigint,
    ALTER pub_id TYPE bigint;
  
--
-- Name: cell_line_cvtermprop; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE cell_line_cvtermprop
    ALTER cell_line_cvtermprop_id TYPE bigint,
    ALTER cell_line_cvterm_id TYPE bigint,
    ALTER type_id TYPE bigint;
  
--
-- Name: cell_line_dbxref; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE cell_line_dbxref
    ALTER cell_line_dbxref_id TYPE bigint,
    ALTER cell_line_id TYPE bigint,
    ALTER dbxref_id TYPE bigint;
    
--
-- Name: cell_line_feature; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE cell_line_feature
    ALTER cell_line_feature_id TYPE bigint,
    ALTER cell_line_id TYPE bigint,
    ALTER feature_id TYPE bigint,
    ALTER pub_id TYPE bigint;
    
--
-- Name: cell_line_library; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE cell_line_library
    ALTER cell_line_library_id TYPE bigint,
    ALTER cell_line_id TYPE bigint,
    ALTER library_id TYPE bigint,
    ALTER pub_id TYPE bigint;
    
--
-- Name: cell_line_pub; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE cell_line_pub 
    ALTER cell_line_pub_id TYPE bigint,
    ALTER cell_line_id TYPE bigint,
    ALTER pub_id TYPE bigint;
    
--
-- Name: cell_line_relationship; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE cell_line_relationship
    ALTER cell_line_relationship_id TYPE bigint,
    ALTER subject_id TYPE bigint,
    ALTER object_id TYPE bigint,
    ALTER type_id TYPE bigint;
    
--
-- Name: cell_line_synonym; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE cell_line_synonym
    ALTER cell_line_synonym_id TYPE bigint,
    ALTER cell_line_id TYPE bigint,
    ALTER synonym_id TYPE bigint,
    ALTER pub_id TYPE bigint;
    
--
-- Name: cell_lineprop; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE cell_lineprop
    ALTER cell_lineprop_id TYPE bigint,
    ALTER cell_line_id TYPE bigint,
    ALTER type_id TYPE bigint;

--
-- Name: cell_lineprop_pub; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE cell_lineprop_pub
    ALTER cell_lineprop_pub_id TYPE bigint,
    ALTER cell_lineprop_id TYPE bigint,
    ALTER pub_id TYPE bigint;

--
-- Name: chadoprop; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE chadoprop 
    ALTER chadoprop_id TYPE bigint,
    ALTER type_id TYPE bigint;
    
--
-- Name: channel; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE channel ALTER channel_id TYPE bigint;

--
-- Name: contact; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE contact 
    ALTER contact_id TYPE bigint,
    ALTER type_id TYPE bigint;


--
-- Name: contact_relationship; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE contact_relationship 
    ALTER contact_relationship_id TYPE bigint,
    ALTER type_id TYPE bigint,
    ALTER subject_id TYPE bigint,
    ALTER object_id TYPE bigint;

--
-- Name: contactprop; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

CREATE TABLE contactprop (
    contactprop_id bigint NOT NULL,
    contact_id bigint NOT NULL,
    type_id bigint NOT NULL,
    value text,
    rank integer DEFAULT 0 NOT NULL
);

--
-- Name: TABLE contactprop; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON TABLE contactprop IS 'A contact can have any number of slot-value property 
tags attached to it. This is an alternative to hardcoding a list of columns in the 
relational schema, and is completely extensible.';


--
-- Name: contactprop_contactprop_id_seq; Type: SEQUENCE; Schema: public; Owner: chado
--

CREATE SEQUENCE contactprop_contactprop_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contactprop_contactprop_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: chado
--

ALTER SEQUENCE contactprop_contactprop_id_seq OWNED BY contactprop.contactprop_id;

--
-- Name: control; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE control 
    ALTER control_id TYPE bigint,
    ALTER type_id TYPE bigint,
    ALTER assay_id TYPE bigint,
    ALTER tableinfo_id TYPE bigint;

--
-- Name: cvterm_relationship; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE cvterm_relationship
    ALTER cvterm_relationship_id TYPE bigint,
    ALTER type_id TYPE bigint,
    ALTER subject_id TYPE bigint,
    ALTER object_id TYPE bigint;
    
--
-- Name: cvprop; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE cvprop 
    ALTER cvprop_id TYPE bigint,
    ALTER cv_id TYPE bigint,
    ALTER type_id TYPE bigint;

--
-- Name: cvterm_dbxref; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE cvterm_dbxref 
    ALTER cvterm_dbxref_id TYPE bigint,
    ALTER cvterm_id TYPE bigint,
    ALTER dbxref_id TYPE bigint;

--
-- Name: cvtermprop; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE cvtermprop
    ALTER cvtermprop_id TYPE bigint,
    ALTER cvterm_id TYPE bigint,
    ALTER type_id TYPE bigint;
    
--
-- Name: cvtermsynonym; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE cvtermsynonym
    ALTER cvtermsynonym_id TYPE bigint,
    ALTER cvterm_id TYPE bigint,
    ALTER type_id TYPE bigint;

--
-- Name: dbprop; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

CREATE TABLE dbprop (
    dbprop_id bigint NOT NULL,
    db_id bigint NOT NULL,
    type_id bigint NOT NULL,
    value text,
    rank integer DEFAULT 0 NOT NULL
);

--
-- Name: TABLE dbprop; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON TABLE dbprop IS 'An external database can have any number of
slot-value property tags attached to it. This is an alternative to
hardcoding a list of columns in the relational schema, and is
completely extensible. There is a unique constraint, dbprop_c1, for
the combination of db_id, rank, and type_id. Multivalued property-value pairs must be differentiated by rank.';


--
-- Name: dbprop_dbprop_id_seq; Type: SEQUENCE; Schema: public; Owner: chado
--

CREATE SEQUENCE dbprop_dbprop_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: dbprop_dbprop_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: chado
--

ALTER SEQUENCE dbprop_dbprop_id_seq OWNED BY dbprop.dbprop_id;

--
-- Name: dbxrefprop; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE dbxrefprop
    ALTER dbxrefprop_id TYPE bigint,
    ALTER dbxref_id TYPE bigint,
    ALTER type_id TYPE bigint;
    
--
-- Name: eimage; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE eimage ALTER eimage_id TYPE bigint;

--
-- Name: element; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE element
    ALTER element_id TYPE bigint,
    ALTER feature_id TYPE bigint,
    ALTER arraydesign_id TYPE bigint,
    ALTER type_id TYPE bigint,
    ALTER dbxref_id TYPE bigint;
    
--
-- Name: element_relationship; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE element_relationship
    ALTER element_relationship_id TYPE bigint,
    ALTER subject_id TYPE bigint,
    ALTER type_id TYPE bigint,
    ALTER object_id TYPE bigint;
    
--
-- Name: elementresult; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE elementresult 
    ALTER elementresult_id TYPE bigint,
    ALTER element_id TYPE bigint,
    ALTER quantification_id TYPE bigint;
    
--
-- Name: elementresult_relationship; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE elementresult_relationship
    ALTER elementresult_relationship_id TYPE bigint,
    ALTER subject_id TYPE bigint,
    ALTER type_id TYPE bigint,
    ALTER object_id TYPE bigint;

--
-- Name: environment; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE environment ALTER environment_id TYPE bigint;


--
-- Name: environment_cvterm; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE environment_cvterm
    ALTER environment_cvterm_id TYPE bigint,
    ALTER environment_id TYPE bigint,
    ALTER cvterm_id TYPE bigint;
    
--
-- Name: expression; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE expression ALTER expression_id TYPE bigint;

--
-- Name: expression_cvterm; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE expression_cvterm 
    ALTER expression_cvterm_id TYPE bigint,
    ALTER expression_id TYPE bigint,
    ALTER cvterm_id TYPE bigint,
    ALTER cvterm_type_id TYPE bigint;
    
--
-- Name: expression_cvtermprop; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE expression_cvtermprop 
    ALTER expression_cvtermprop_id TYPE bigint,
    ALTER expression_cvterm_id type bigint,
    ALTER type_id TYPE bigint;
    
--
-- Name: expression_image; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE expression_image 
    ALTER expression_image_id TYPE bigint,
    ALTER expression_id TYPE bigint,
    ALTER eimage_id TYPE bigint;
    
--
-- Name: expression_pub; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE expression_pub
    ALTER expression_pub_id TYPE bigint,
    ALTER expression_id TYPE bigint,
    ALTER pub_id TYPE bigint;
    
--
-- Name: expressionprop; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE expressionprop 
    ALTER expressionprop_id TYPE bigint,
    ALTER expression_id TYPE bigint,
    ALTER type_id TYPE bigint;

--
-- Name: feature_contact; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

CREATE TABLE feature_contact (
    feature_contact_id bigint NOT NULL,
    feature_id bigint NOT NULL,
    contact_id bigint NOT NULL
);

--
-- Name: TABLE feature_contact; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON TABLE feature_contact IS 'Links contact(s) with a feature.  Used to indicate a particular 
person or organization responsible for discovery or that can provide more information on a particular feature.';


--
-- Name: feature_contact_feature_contact_id_seq; Type: SEQUENCE; Schema: public; Owner: chado
--

CREATE SEQUENCE feature_contact_feature_contact_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: feature_contact_feature_contact_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: chado
--

ALTER SEQUENCE feature_contact_feature_contact_id_seq OWNED BY feature_contact.feature_contact_id;

--
-- Name: feature_cvterm_dbxref; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE feature_cvterm_dbxref 
    ALTER feature_cvterm_dbxref_id TYPE bigint,
    ALTER feature_cvterm_id TYPE bigint,
    ALTER dbxref_id TYPE bigint;
    
    
--
-- Name: feature_cvterm_pub; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE feature_cvterm_pub 
    ALTER feature_cvterm_pub_id TYPE bigint,
    ALTER feature_cvterm_id TYPE bigint,
    ALTER pub_id TYPE bigint;
    
--
-- Name: feature_cvtermprop; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE feature_cvtermprop 
    ALTER feature_cvtermprop_id TYPE bigint,
    ALTER feature_cvterm_id TYPE bigint,
    ALTER type_id TYPE bigint;
    
--
-- Name: feature_expression; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE feature_expression 
    ALTER feature_expression_id TYPE bigint,
    ALTER expression_id TYPE bigint,
    ALTER feature_id TYPE bigint,
    ALTER pub_id TYPE bigint;
    

--
-- Name: feature_expressionprop; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE feature_expressionprop 
    ALTER feature_expressionprop_id TYPE bigint,
    ALTER feature_expression_id TYPE bigint,
    ALTER type_id TYPE bigint;
    
--
-- Name: feature_genotype; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE feature_genotype
    ALTER feature_genotype_id TYPE bigint,
    ALTER feature_id TYPE bigint,
    ALTER genotype_id TYPE bigint,
    ALTER chromosome_id TYPE bigint,
    ALTER cvterm_id TYPE bigint;

--
-- Name: feature_phenotype; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE feature_phenotype
    ALTER feature_phenotype_id TYPE bigint,
    ALTER feature_id TYPE bigint,
    ALTER phenotype_id TYPE bigint;
    
--
-- Name: TABLE feature_phenotype; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON TABLE feature_phenotype IS 'Linking table between features and phenotypes.';

--
-- Name: feature_pubprop; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE feature_pubprop
    ALTER feature_pubprop_id TYPE bigint,
    ALTER feature_pub_id TYPE bigint,
    ALTER type_id TYPE bigint ;

--
-- Name: feature_relationship; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE feature_relationship
    ALTER feature_relationship_id TYPE bigint,
    ALTER subject_id TYPE bigint,
    ALTER object_id TYPE bigint,
    ALTER type_id TYPE bigint;
    
--
-- Name: feature_relationship_pub; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE feature_relationship_pub 
    ALTER feature_relationship_pub_id TYPE bigint,
    ALTER feature_relationship_id TYPE bigint,
    ALTER pub_id TYPE bigint;
    
--
-- Name: feature_relationshipprop; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE feature_relationshipprop 
    ALTER feature_relationshipprop_id TYPE bigint,
    ALTER feature_relationship_id TYPE bigint,
    ALTER type_id TYPE bigint;

--
-- Name: feature_relationshipprop_pub; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE feature_relationshipprop_pub 
    ALTER feature_relationshipprop_pub_id TYPE bigint,
    ALTER feature_relationshipprop_id TYPE bigint,
    ALTER pub_id TYPE bigint;

--
-- Name: featureloc_pub; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE featureloc_pub 
    ALTER featureloc_pub_id TYPE bigint,
    ALTER featureloc_id TYPE bigint,
    ALTER pub_id TYPE bigint;

--
-- Name: featuremap; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE featuremap 
    ALTER featuremap_id TYPE bigint,
    ALTER unittype_id TYPE bigint;

--
-- Name: featuremap_contact; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

CREATE TABLE featuremap_contact (
    featuremap_contact_id bigint NOT NULL,
    featuremap_id bigint NOT NULL,
    contact_id bigint NOT NULL
);

--
-- Name: TABLE featuremap_contact; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON TABLE featuremap_contact IS 'Links contact(s) with a featuremap.  Used to 
indicate a particular person or organization responsible for constrution of or 
that can provide more information on a particular featuremap.';


--
-- Name: featuremap_contact_featuremap_contact_id_seq; Type: SEQUENCE; Schema: public; Owner: chado
--

CREATE SEQUENCE featuremap_contact_featuremap_contact_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: featuremap_contact_featuremap_contact_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: chado
--

ALTER SEQUENCE featuremap_contact_featuremap_contact_id_seq OWNED BY featuremap_contact.featuremap_contact_id;


--
-- Name: featuremap_dbxref; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

CREATE TABLE featuremap_dbxref (
    featuremap_dbxref_id bigint NOT NULL,
    featuremap_id bigint NOT NULL,
    dbxref_id bigint NOT NULL,
    is_current boolean DEFAULT true NOT NULL
);

--
-- Name: featuremap_dbxref_featuremap_dbxref_id_seq; Type: SEQUENCE; Schema: public; Owner: chado
--

CREATE SEQUENCE featuremap_dbxref_featuremap_dbxref_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: featuremap_dbxref_featuremap_dbxref_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: chado
--

ALTER SEQUENCE featuremap_dbxref_featuremap_dbxref_id_seq OWNED BY featuremap_dbxref.featuremap_dbxref_id;

--
-- Name: featuremap_organism; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

CREATE TABLE featuremap_organism (
    featuremap_organism_id bigint NOT NULL,
    featuremap_id bigint NOT NULL,
    organism_id bigint NOT NULL
);


--
-- Name: TABLE featuremap_organism; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON TABLE featuremap_organism IS 'Links a featuremap to the organism(s) with which it is associated.';


--
-- Name: featuremap_organism_featuremap_organism_id_seq; Type: SEQUENCE; Schema: public; Owner: chado
--

CREATE SEQUENCE featuremap_organism_featuremap_organism_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: featuremap_organism_featuremap_organism_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: chado
--

ALTER SEQUENCE featuremap_organism_featuremap_organism_id_seq OWNED BY featuremap_organism.featuremap_organism_id;

--
-- Name: featuremap_pub; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE featuremap_pub 
    ALTER featuremap_pub_id TYPE bigint,
    ALTER featuremap_id TYPE bigint,
    ALTER pub_id TYPE bigint;
    
--
-- Name: featuremapprop; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

CREATE TABLE featuremapprop (
    featuremapprop_id bigint NOT NULL,
    featuremap_id bigint NOT NULL,
    type_id bigint NOT NULL,
    value text,
    rank integer DEFAULT 0 NOT NULL
);

--
-- Name: TABLE featuremapprop; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON TABLE featuremapprop IS 'A featuremap can have any number of slot-value property 
tags attached to it. This is an alternative to hardcoding a list of columns in the 
relational schema, and is completely extensible.';


--
-- Name: featuremapprop_featuremapprop_id_seq; Type: SEQUENCE; Schema: public; Owner: chado
--

CREATE SEQUENCE featuremapprop_featuremapprop_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: featuremapprop_featuremapprop_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: chado
--

ALTER SEQUENCE featuremapprop_featuremapprop_id_seq OWNED BY featuremapprop.featuremapprop_id;

--
-- Name: featurepos; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE featurepos 
    ALTER featurepos_id TYPE bigint,
    ALTER featuremap_id TYPE bigint,
    ALTER feature_id TYPE bigint,
    ALTER map_feature_id TYPE bigint;
    
--
-- Name: featureposprop; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

CREATE TABLE featureposprop (
    featureposprop_id bigint NOT NULL,
    featurepos_id bigint NOT NULL,
    type_id bigint NOT NULL,
    value text,
    rank integer DEFAULT 0 NOT NULL
);


--
-- Name: TABLE featureposprop; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON TABLE featureposprop IS 'Property or attribute of a featurepos record.';

--
-- Name: featureposprop_featureposprop_id_seq; Type: SEQUENCE; Schema: public; Owner: chado
--

CREATE SEQUENCE featureposprop_featureposprop_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: featureposprop_featureposprop_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: chado
--

ALTER SEQUENCE featureposprop_featureposprop_id_seq OWNED BY featureposprop.featureposprop_id;

--
-- Name: featureprop_pub; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE featureprop_pub 
    ALTER featureprop_pub_id TYPE bigint,
    ALTER featureprop_id TYPE bigint,
    ALTER pub_id TYPE bigint;

--
-- Name: featurerange; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE featurerange 
    ALTERfeaturerange_id TYPE bigint,
    ALTERfeaturemap_id TYPE bigint,
    ALTERfeature_id TYPE bigint,
    ALTERleftstartf_id TYPE bigint,
    ALTERleftendf_id TYPE bigint,
    ALTERrightstartf_id TYPE bigint,
    ALTERrightendf_id TYPE bigint;
    
--
-- Name: genotype; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE genotype 
    ALTER genotype_id TYPE bigint,
    ALTER description text,
    ALTER type_id TYPE bigint;

--
-- Name: genotypeprop; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE genotypeprop 
    genotypeprop_id TYPE bigint,
    genotype_id TYPE bigint,
    type_id TYPE bigint;


--
-- Name: library; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE library 
    ALTER library_id TYPE bigint,
    ALTER organism_id TYPE bigint,
    ALTER type_id TYPE bigint;

--
-- Name: COLUMN library.type_id; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON COLUMN library.type_id IS 'The type_id foreign key links to a controlled vocabulary of library types. Examples of this would be: "cDNA_library" or "genomic_library"';

--
-- Name: library_contact; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

CREATE TABLE library_contact (
    library_contact_id bigint NOT NULL,
    library_id bigint NOT NULL,
    contact_id bigint NOT NULL
);

--
-- Name: TABLE library_contact; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON TABLE library_contact IS 'Links contact(s) with a library.  Used to indicate a particular person or organization responsible for creation of or that can provide more information on a particular library.';


--
-- Name: library_contact_library_contact_id_seq; Type: SEQUENCE; Schema: public; Owner: chado
--

CREATE SEQUENCE library_contact_library_contact_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: library_contact_library_contact_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: chado
--

ALTER SEQUENCE library_contact_library_contact_id_seq OWNED BY library_contact.library_contact_id;

--
-- Name: library_cvterm; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE library_cvterm 
    ALTER library_cvterm_id TYPE bigint,
    ALTER library_id TYPE bigint,
    ALTER cvterm_id TYPE bigint,
    ALTER pub_id TYPE bigint;

--
-- Name: TABLE library_dbxref; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON TABLE library_dbxref IS 'Links a library to dbxrefs.';

--
-- Name: library_expression; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

CREATE TABLE library_expression (
    library_expression_id bigint NOT NULL,
    library_id bigint NOT NULL,
    expression_id bigint NOT NULL,
    pub_id bigint NOT NULL
);

--
-- Name: TABLE library_expression; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON TABLE library_expression IS 'Links a library to expression statements.';


--
-- Name: library_expression_library_expression_id_seq; Type: SEQUENCE; Schema: public; Owner: chado
--

CREATE SEQUENCE library_expression_library_expression_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: library_expression_library_expression_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: chado
--

ALTER SEQUENCE library_expression_library_expression_id_seq OWNED BY library_expression.library_expression_id;


--
-- Name: library_expressionprop; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

CREATE TABLE library_expressionprop (
    library_expressionprop_id bigint NOT NULL,
    library_expression_id bigint NOT NULL,
    type_id bigint NOT NULL,
    value text,
    rank integer DEFAULT 0 NOT NULL
);

--
-- Name: TABLE library_expressionprop; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON TABLE library_expressionprop IS 'Attributes of a library_expression relationship.';


--
-- Name: library_expressionprop_library_expressionprop_id_seq; Type: SEQUENCE; Schema: public; Owner: chado
--

CREATE SEQUENCE library_expressionprop_library_expressionprop_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: library_expressionprop_library_expressionprop_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: chado
--

ALTER SEQUENCE library_expressionprop_library_expressionprop_id_seq OWNED BY library_expressionprop.library_expressionprop_id;

--
-- Name: library_feature; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE library_feature
    ALTER library_feature_id TYPE bigint,
    ALTER library_id TYPE bigint,
    ALTER feature_id TYPE bigint;

--
-- Name: library_featureprop; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

CREATE TABLE library_featureprop (
    library_featureprop_id bigint NOT NULL,
    library_feature_id bigint NOT NULL,
    type_id bigint NOT NULL,
    value text,
    rank integer DEFAULT 0 NOT NULL
);

--
-- Name: TABLE library_featureprop; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON TABLE library_featureprop IS 'Attributes of a library_feature relationship.';


--
-- Name: library_featureprop_library_featureprop_id_seq; Type: SEQUENCE; Schema: public; Owner: chado
--

CREATE SEQUENCE library_featureprop_library_featureprop_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: library_featureprop_library_featureprop_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: chado
--

ALTER SEQUENCE library_featureprop_library_featureprop_id_seq OWNED BY library_featureprop.library_featureprop_id;

--
-- Name: library_pub; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE library_pub
    ALTER library_pub_id TYPE bigint,
    ALTER library_id TYPE bigint,
    ALTER pub_id TYPE bigint;
    
--
-- Name: TABLE library_pub; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON TABLE library_pub IS 'Attribution for a library.';

--
-- Name: library_relationship; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

CREATE TABLE library_relationship (
    library_relationship_id bigint NOT NULL,
    subject_id bigint NOT NULL,
    object_id bigint NOT NULL,
    type_id bigint NOT NULL
);


--
-- Name: TABLE library_relationship; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON TABLE library_relationship IS 'Relationships between libraries.';


--
-- Name: library_relationship_library_relationship_id_seq; Type: SEQUENCE; Schema: public; Owner: chado
--

CREATE SEQUENCE library_relationship_library_relationship_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: library_relationship_library_relationship_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: chado
--

ALTER SEQUENCE library_relationship_library_relationship_id_seq OWNED BY library_relationship.library_relationship_id;


--
-- Name: library_relationship_pub; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

CREATE TABLE library_relationship_pub (
    library_relationship_pub_id bigint NOT NULL,
    library_relationship_id bigint NOT NULL,
    pub_id bigint NOT NULL
);

--
-- Name: TABLE library_relationship_pub; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON TABLE library_relationship_pub IS 'Provenance of library_relationship.';


--
-- Name: library_relationship_pub_library_relationship_pub_id_seq; Type: SEQUENCE; Schema: public; Owner: chado
--

CREATE SEQUENCE library_relationship_pub_library_relationship_pub_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: library_relationship_pub_library_relationship_pub_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: chado
--

ALTER SEQUENCE library_relationship_pub_library_relationship_pub_id_seq OWNED BY library_relationship_pub.library_relationship_pub_id;


--
-- Name: library_synonym; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE library_synonym
    ALTER library_synonym_id TYPE bigint,
    ALTER synonym_id TYPE bigint,
    ALTER library_id TYPE bigint,
    ALTER pub_id TYPE bigint;
    
--
-- Name: TABLE library_synonym; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON TABLE library_synonym IS 'Linking table between library and synonym.';


--
-- Name: libraryprop; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE libraryprop
    ALTER libraryprop_id TYPE bigint,
    ALTER library_id TYPE bigint,
    ALTER type_id TYPE bigint;
    
--
-- Name: TABLE libraryprop; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON TABLE libraryprop IS 'Tag-value properties - follows standard chado model.';

--
-- Name: libraryprop_pub; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE libraryprop_pub 
    ALTER libraryprop_pub_id TYPE bigint,
    ALTER libraryprop_id TYPE bigint,
    ALTER pub_id TYPE bigint;

--
-- Name: TABLE libraryprop_pub; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON TABLE libraryprop_pub IS 'Attribution for libraryprop.';

--
-- Name: magedocumentation; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE magedocumentation 
    ALTER magedocumentation_id TYPE bigint,
    ALTER mageml_id TYPE bigint,
    ALTER tableinfo_id TYPE bigint;

--
-- Name: mageml; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE mageml ALTER mageml_id TYPE bigint;

--
-- Name: nd_experiment; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE nd_experiment
    ALTER nd_experiment_id TYPE bigint,
    ALTER nd_geolocation_id TYPE bigint,
    ALTER type_id TYPE bigint;

    --
-- Name: TABLE nd_experiment; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON TABLE nd_experiment IS 'This is the core table for the natural diversity module, 
representing each individual assay that is undertaken (this is usually *not* an 
entire experiment). Each nd_experiment should give rise to a single genotype or 
phenotype and be described via 1 (or more) protocols. Collections of assays that 
relate to each other should be linked to the same record in the project table.';


--
-- Name: nd_experiment_analysis; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

CREATE TABLE nd_experiment_analysis (
    nd_experiment_analysis_id bigint NOT NULL,
    nd_experiment_id bigint NOT NULL,
    analysis_id bigint NOT NULL,
    type_id bigint
);

--
-- Name: TABLE nd_experiment_analysis; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON TABLE nd_experiment_analysis IS 'An analysis that is used in an experiment';


--
-- Name: nd_experiment_analysis_nd_experiment_analysis_id_seq; Type: SEQUENCE; Schema: public; Owner: chado
--

CREATE SEQUENCE nd_experiment_analysis_nd_experiment_analysis_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: nd_experiment_analysis_nd_experiment_analysis_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: chado
--

ALTER SEQUENCE nd_experiment_analysis_nd_experiment_analysis_id_seq OWNED BY nd_experiment_analysis.nd_experiment_analysis_id;


--
-- Name: nd_experiment_contact; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE nd_experiment_contact 
    ALTER nd_experiment_contact_id TYPE bigint,
    ALTER nd_experiment_id TYPE bigint,
    ALTER contact_id TYPE bigint;

--
-- Name: nd_experiment_dbxref; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE nd_experiment_dbxref
    ALTER nd_experiment_dbxref_id TYPE bigint,
    ALTER nd_experiment_id TYPE bigint,
    ALTER dbxref_id TYPE bigint;
    
--
-- Name: nd_experiment_genotype; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE nd_experiment_genotype
    ALTER nd_experiment_genotype_id TYPE bigint,
    ALTER nd_experiment_id TYPE bigint,
    ALTER genotype_id TYPE bigint;
    
--
-- Name: nd_experiment_phenotype; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE nd_experiment_phenotype
    ALTER nd_experiment_phenotype_id TYPE bigint,
    ALTER nd_experiment_id TYPE bigint,
    ALTER phenotype_id TYPE bigint;
    
--
-- Name: nd_experiment_project; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE nd_experiment_project
    ALTER nd_experiment_project_id TYPE bigint,
    ALTER project_id TYPE bigint,
    ALTER nd_experiment_id TYPE bigint;
    
--
-- Name: TABLE nd_experiment_project; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON TABLE nd_experiment_project IS 'Used to group together related nd_experiment records. All nd_experiments 
should be linked to at least one project.';

--
-- Name: nd_experiment_protocol; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE nd_experiment_protocol 
    ALTER nd_experiment_protocol_id TYPE bigint,
    ALTER nd_experiment_id TYPE bigint,
    ALTER nd_protocol_id TYPE bigint;

--
-- Name: nd_experiment_pub; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE nd_experiment_pub
    ALTER nd_experiment_pub_id TYPE bigint,
    ALTER nd_experiment_id TYPE bigint,
    ALTER pub_id TYPE bigint;

--
-- Name: nd_experiment_stock; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE nd_experiment_stock
    ALTER nd_experiment_stock_id TYPE bigint,
    ALTER nd_experiment_id TYPE bigint,
    ALTER stock_id TYPE bigint,
    ALTER type_id TYPE bigint;

--
-- Name: nd_experiment_stock_dbxref; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE nd_experiment_stock_dbxref 
    ALTER nd_experiment_stock_dbxref_id TYPE bigint,
    ALTER nd_experiment_stock_id TYPE bigint,
    ALTER dbxref_id TYPE bigint;
    
--
-- Name: nd_experiment_stockprop; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE nd_experiment_stockprop 
    ALTER nd_experiment_stockprop_id TYPE bigint,
    ALTER nd_experiment_stock_id TYPE bigint,
    ALTER type_id TYPE bigint;

--
-- Name: nd_experimentprop; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE nd_experimentprop 
    ALTER nd_experimentprop_id TYPE bigint,
    ALTER nd_experiment_id TYPE bigint,
    ALTER type_id TYPE bigint;

 --
-- Name: TABLE nd_experimentprop; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON TABLE nd_experimentprop IS 'An nd_experiment can have any number of
slot-value property tags attached to it. This is an alternative to
hardcoding a list of columns in the relational schema, and is
completely extensible. There is a unique constraint, stockprop_c1, for
the combination of stock_id, rank, and type_id. Multivalued property-value pairs must be differentiated by rank.';

--
-- Name: nd_geolocation; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE nd_geolocation
    ALTER nd_geolocation_id TYPE bigint,
    ALTER description TYPE text;
  
  --
-- Name: nd_geolocationprop; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE nd_geolocationprop 
    ALTER nd_geolocationprop_id TYPE bigint,
    ALTER nd_geolocation_id TYPE bigint,
    ALTER type_id TYPE bigint;
    
   --
-- Name: nd_protocol; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE nd_protocol 
    ALTER nd_protocol_id TYPE bigint,
    ALTER type_id TYPE bigint;
    
--
-- Name: nd_protocol_reagent; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE nd_protocol_reagent
    ALTER nd_protocol_reagent_id TYPE bigint,
    ALTER nd_protocol_id TYPE bigint,
    ALTER reagent_id TYPE bigint,
    ALTER type_id TYPE bigint; 
    
--
-- Name: nd_protocolprop; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE nd_protocolprop
    ALTER nd_protocolprop_id TYPE bigint,
    ALTER nd_protocol_id TYPE bigint,
    ALTER type_id TYPE bigint;
    
--
-- Name: nd_reagent; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE nd_reagent
    ALTER nd_reagent_id TYPE bigint,
    ALTER type_id TYPE bigint ,
    ALTER feature_id TYPE bigint;

--
-- Name: nd_reagent_relationship; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE nd_reagent_relationship
    ALTER nd_reagent_relationship_id TYPE bigint,
    ALTER subject_reagent_id TYPE bigint,
    ALTER object_reagent_id TYPE bigint,
    ALTER type_id TYPE bigint;

--
-- Name: nd_reagentprop; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE nd_reagentprop
    ALTER nd_reagentprop_id TYPE bigint,
    ALTER nd_reagent_id TYPE bigint,
    ALTER type_id TYPE bigint;
    
--
-- Name: organism; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE organism
    ALTER organism_id TYPE bigint,
    ADD infraspecific_name character varying(1024),
    ADD type_id bigint;
    
--
-- Name: COLUMN organism.infraspecific_name; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON COLUMN organism.infraspecific_name IS 'The scientific name for any taxon 
below the rank of species.  The rank should be specified using the type_id field
and the name is provided here.';


--
-- Name: COLUMN organism.type_id; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON COLUMN organism.type_id IS 'A controlled vocabulary term that
specifies the organism rank below species. It is used when an infraspecific 
name is provided.  Ideally, the rank should be a valid ICN name such as 
subspecies, varietas, subvarietas, forma and subforma';


--
-- Name: organism_cvterm; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

CREATE TABLE organism_cvterm (
    organism_cvterm_id bigint NOT NULL,
    organism_id bigint NOT NULL,
    cvterm_id bigint NOT NULL,
    rank integer DEFAULT 0 NOT NULL,
    pub_id bigint NOT NULL
);

--
-- Name: TABLE organism_cvterm; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON TABLE organism_cvterm IS 'organism to cvterm associations. Examples: taxonomic name';


--
-- Name: COLUMN organism_cvterm.rank; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON COLUMN organism_cvterm.rank IS 'Property-Value
ordering. Any organism_cvterm can have multiple values for any particular
property type - these are ordered in a list using rank, counting from
zero. For properties that are single-valued rather than multi-valued,
the default 0 value should be used';


--
-- Name: organism_cvterm_organism_cvterm_id_seq; Type: SEQUENCE; Schema: public; Owner: chado
--

CREATE SEQUENCE organism_cvterm_organism_cvterm_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: organism_cvterm_organism_cvterm_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: chado
--

ALTER SEQUENCE organism_cvterm_organism_cvterm_id_seq OWNED BY organism_cvterm.organism_cvterm_id;


--
-- Name: organism_cvtermprop; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

CREATE TABLE organism_cvtermprop (
    organism_cvtermprop_id bigint NOT NULL,
    organism_cvterm_id bigint NOT NULL,
    type_id bigint NOT NULL,
    value text,
    rank integer DEFAULT 0 NOT NULL
);


--
-- Name: TABLE organism_cvtermprop; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON TABLE organism_cvtermprop IS 'Extensible properties for
organism to cvterm associations. Examples: qualifiers';


--
-- Name: COLUMN organism_cvtermprop.type_id; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON COLUMN organism_cvtermprop.type_id IS 'The name of the
property/slot is a cvterm. The meaning of the property is defined in
that cvterm. ';


--
-- Name: COLUMN organism_cvtermprop.value; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON COLUMN organism_cvtermprop.value IS 'The value of the
property, represented as text. Numeric values are converted to their
text representation. This is less efficient than using native database
types, but is easier to query.';


--
-- Name: COLUMN organism_cvtermprop.rank; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON COLUMN organism_cvtermprop.rank IS 'Property-Value
ordering. Any organism_cvterm can have multiple values for any particular
property type - these are ordered in a list using rank, counting from
zero. For properties that are single-valued rather than multi-valued,
the default 0 value should be used';


--
-- Name: organism_cvtermprop_organism_cvtermprop_id_seq; Type: SEQUENCE; Schema: public; Owner: chado
--

CREATE SEQUENCE organism_cvtermprop_organism_cvtermprop_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: organism_cvtermprop_organism_cvtermprop_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: chado
--

ALTER SEQUENCE organism_cvtermprop_organism_cvtermprop_id_seq OWNED BY organism_cvtermprop.organism_cvtermprop_id;

--
-- Name: organism_dbxref; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE organism_dbxref
    ALTER organism_dbxref_id TYPE bigint,
    ALTER organism_id TYPE bigint,
    ALTER dbxref_id TYPE bigint;
    
--
-- Name: TABLE organism_dbxref; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON TABLE organism_dbxref IS 'Links an organism to a dbxref.';


--
-- Name: organism_pub; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

CREATE TABLE organism_pub (
    organism_pub_id bigint NOT NULL,
    organism_id bigint NOT NULL,
    pub_id bigint NOT NULL
);

--
-- Name: TABLE organism_pub; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON TABLE organism_pub IS 'Attribution for organism.';


--
-- Name: organism_pub_organism_pub_id_seq; Type: SEQUENCE; Schema: public; Owner: chado
--

CREATE SEQUENCE organism_pub_organism_pub_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: organism_pub_organism_pub_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: chado
--

ALTER SEQUENCE organism_pub_organism_pub_id_seq OWNED BY organism_pub.organism_pub_id;


--
-- Name: organism_relationship; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

CREATE TABLE organism_relationship (
    organism_relationship_id bigint NOT NULL,
    subject_id bigint NOT NULL,
    object_id bigint NOT NULL,
    type_id bigint NOT NULL,
    rank integer DEFAULT 0 NOT NULL
);

--
-- Name: TABLE organism_relationship; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON TABLE organism_relationship IS 'Specifies relationships between organisms 
that are not taxonomic. For example, in breeding, relationships such as 
"sterile_with", "incompatible_with", or "fertile_with" would be appropriate. Taxonomic
relatinoships should be housed in the phylogeny tables.';


--
-- Name: organism_relationship_organism_relationship_id_seq; Type: SEQUENCE; Schema: public; Owner: chado
--

CREATE SEQUENCE organism_relationship_organism_relationship_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: organism_relationship_organism_relationship_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: chado
--

ALTER SEQUENCE organism_relationship_organism_relationship_id_seq OWNED BY organism_relationship.organism_relationship_id;

--
-- Name: organismprop; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE organismprop
    ALTER organismprop_id TYPE bigint,
    ALTER organism_id TYPE bigint,
    ALTER type_id TYPE bigint;

--
-- Name: organismprop_pub; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

CREATE TABLE organismprop_pub (
    organismprop_pub_id bigint NOT NULL,
    organismprop_id bigint NOT NULL,
    pub_id bigint NOT NULL,
    value text,
    rank integer DEFAULT 0 NOT NULL
);

--
-- Name: TABLE organismprop_pub; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON TABLE organismprop_pub IS 'Attribution for organismprop.';


--
-- Name: organismprop_pub_organismprop_pub_id_seq; Type: SEQUENCE; Schema: public; Owner: chado
--

CREATE SEQUENCE organismprop_pub_organismprop_pub_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: organismprop_pub_organismprop_pub_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: chado
--

ALTER SEQUENCE organismprop_pub_organismprop_pub_id_seq OWNED BY organismprop_pub.organismprop_pub_id;

--
-- Name: phendesc; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE phendesc 
    ALTER phendesc_id TYPE bigint,
    ALTER genotype_id TYPE bigint,
    ALTER environment_id TYPE bigint,
    ALTER type_id TYPE bigint,
    ALTER pub_id TYPE bigint;
    
--
-- Name: phenotype; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE phenotype 
    ALTER phenotype_id TYPE bigint,
    ALTER observable_id TYPE bigint,
    ALTER attr_id TYPE bigint,
    ALTER cvalue_id TYPE bigint,
    ALTER assay_id TYPE bigint;
    
--
-- Name: phenotype_comparison; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE phenotype_comparison
    ALTER phenotype_comparison_id TYPE bigint,
    ALTER genotype1_id TYPE bigint,
    ALTER environment1_id TYPE bigint,
    ALTER genotype2_id TYPE bigint,
    ALTER environment2_id TYPE bigint,
    ALTER phenotype1_id TYPE bigint,
    ALTER phenotype2_id TYPE bigint,
    ALTER pub_id TYPE bigint,
    ALTER organism_id TYPE bigint;
    
--
-- Name: phenotype_comparison_cvterm; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE phenotype_comparison_cvterm 
    ALTER phenotype_comparison_cvterm_id TYPE bigint,
    ALTER phenotype_comparison_id TYPE bigint,
    ALTER cvterm_id TYPE bigint,
    ALTER pub_id TYPE bigint;

--
-- Name: phenotype_cvterm; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE phenotype_cvterm
    ALTER phenotype_cvterm_id TYPE bigint,
    ALTER phenotype_id TYPE bigint,
    ALTER cvterm_id TYPE bigint;

--
-- Name: TABLE phenotype_cvterm; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON TABLE phenotype_cvterm IS 'phenotype to cvterm associations.';

--
-- Name: phenotypeprop; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

CREATE TABLE phenotypeprop (
    phenotypeprop_id bigint NOT NULL,
    phenotype_id bigint NOT NULL,
    type_id bigint NOT NULL,
    value text,
    rank integer DEFAULT 0 NOT NULL
);


--
-- Name: TABLE phenotypeprop; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON TABLE phenotypeprop IS 'A phenotype can have any number of slot-value property tags attached to it. This is an alternative to hardcoding a list of columns in the relational schema, and is completely extensible. There is a unique constraint, phenotypeprop_c1, for the combination of phenotype_id, rank, and type_id. Multivalued property-value pairs must be differentiated by rank.';


--
-- Name: phenotypeprop_phenotypeprop_id_seq; Type: SEQUENCE; Schema: public; Owner: chado
--

CREATE SEQUENCE phenotypeprop_phenotypeprop_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: phenotypeprop_phenotypeprop_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: chado
--

ALTER SEQUENCE phenotypeprop_phenotypeprop_id_seq OWNED BY phenotypeprop.phenotypeprop_id;

--
-- Name: phenstatement; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE phenstatement 
    ALTER phenstatement_id TYPE bigint,
    ALTER genotype_id TYPE bigint,
    ALTER environment_id TYPE bigint,
    ALTER phenotype_id TYPE bigint,
    ALTER type_id TYPE bigint,
    ALTER pub_id TYPE bigint;
    
--
-- Name: phylonode; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE phylonode
    ALTER phylonode_id TYPE bigint,
    ALTER phylotree_id TYPE bigint,
    ALTER parent_phylonode_id TYPE bigint,
    ALTER type_id TYPE bigint,
    ALTER feature_id TYPE bigint;

--
-- Name: phylonode_dbxref; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE phylonode_dbxref 
    ALTER phylonode_dbxref_id TYPE bigint,
    ALTER phylonode_id TYPE bigint,
    ALTER dbxref_id TYPE biginT;
    
--
-- Name: phylonode_organism; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE phylonode_organism 
    ALTER phylonode_organism_id TYPE bigint,
    ALTER phylonode_id TYPE bigint,
    ALTER organism_id TYPE bigint;

--
-- Name: phylonode_pub; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE phylonode_pub 
    ALTER phylonode_pub_id TYPE bigint,
    ALTER phylonode_id TYPE bigint,
    ALTER pub_id TYPE bigint;

--
-- Name: phylonode_relationship; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE phylonode_relationship 
    ALTER phylonode_relationship_id TYPE bigint,
    ALTER subject_id TYPE bigint,
    ALTER object_id TYPE bigint,
    ALTER type_id TYPE bigint,
    ALTER phylotree_id TYPE bigint;

--
-- Name: phylonodeprop; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE phylonodeprop
    ALTER phylonodeprop_id TYPE bigint,
    ALTER phylonode_id TYPE bigint,
    ALTER type_id TYPE bigint;
    
--
-- Name: phylotree; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE phylotree
    ALTER phylotree_id TYPE bigint,
    ALTER dbxref_id TYPE bigint,
    ALTER type_id TYPE bigint,
    ALTER analysis_id TYPE bigint;
    
--
-- Name: phylotree_pub; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE phylotree_pub
    ALTER phylotree_pub_id TYPE bigint,
    ALTER phylotree_id TYPE bigint,
    ALTER pub_id TYPE bigint;

--
-- Name: phylotreeprop; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

CREATE TABLE phylotreeprop (
    phylotreeprop_id bigint NOT NULL,
    phylotree_id bigint NOT NULL,
    type_id bigint NOT NULL,
    value text,
    rank integer DEFAULT 0 NOT NULL
);


--
-- Name: TABLE phylotreeprop; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON TABLE phylotreeprop IS 'A phylotree can have any number of slot-value property 
tags attached to it. This is an alternative to hardcoding a list of columns in the 
relational schema, and is completely extensible.';


--
-- Name: COLUMN phylotreeprop.type_id; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON COLUMN phylotreeprop.type_id IS 'The name of the property/slot is a cvterm. 
The meaning of the property is defined in that cvterm.';


--
-- Name: COLUMN phylotreeprop.value; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON COLUMN phylotreeprop.value IS 'The value of the property, represented as text. 
Numeric values are converted to their text representation. This is less efficient than 
using native database types, but is easier to query.';


--
-- Name: COLUMN phylotreeprop.rank; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON COLUMN phylotreeprop.rank IS 'Property-Value ordering. Any
phylotree can have multiple values for any particular property type 
these are ordered in a list using rank, counting from zero. For
properties that are single-valued rather than multi-valued, the
default 0 value should be used';


--
-- Name: phylotreeprop_phylotreeprop_id_seq; Type: SEQUENCE; Schema: public; Owner: chado
--

CREATE SEQUENCE phylotreeprop_phylotreeprop_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: phylotreeprop_phylotreeprop_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: chado
--

ALTER SEQUENCE phylotreeprop_phylotreeprop_id_seq OWNED BY phylotreeprop.phylotreeprop_id;

--
-- Name: project; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE project 
    ALTER project_id TYPE bigint,
    ALTER description TYPE text;

--
-- Name: TABLE project; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON TABLE project IS 'Standard Chado flexible property table for projects.';


--
-- Name: project_analysis; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

CREATE TABLE project_analysis (
    project_analysis_id bigint NOT NULL,
    project_id bigint NOT NULL,
    analysis_id bigint NOT NULL,
    rank integer DEFAULT 0 NOT NULL
);


--
-- Name: TABLE project_analysis; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON TABLE project_analysis IS 'Links an analysis to a project that may contain multiple analyses. 
The rank column can be used to specify a simple ordering in which analyses were executed.';


--
-- Name: project_analysis_project_analysis_id_seq; Type: SEQUENCE; Schema: public; Owner: chado
--

CREATE SEQUENCE project_analysis_project_analysis_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: project_analysis_project_analysis_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: chado
--

ALTER SEQUENCE project_analysis_project_analysis_id_seq OWNED BY project_analysis.project_analysis_id;

--
-- Name: project_contact; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE project_contact 
    ALTER project_contact_id TYPE bigint,
    ALTER project_id TYPE bigint,
    ALTER contact_id TYPE bigint;


--
-- Name: TABLE project_contact; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON TABLE project_contact IS 'Linking table for associating projects and contacts.';


--
-- Name: project_dbxref; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

CREATE TABLE project_dbxref (
    project_dbxref_id bigint NOT NULL,
    project_id bigint NOT NULL,
    dbxref_id bigint NOT NULL,
    is_current boolean DEFAULT true NOT NULL
);

--
-- Name: TABLE project_dbxref; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON TABLE project_dbxref IS 'project_dbxref links a project to dbxrefs.';


--
-- Name: COLUMN project_dbxref.is_current; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON COLUMN project_dbxref.is_current IS 'The is_current boolean indicates whether the linked dbxref is the current -official- dbxref for the linked project.';


--
-- Name: project_dbxref_project_dbxref_id_seq; Type: SEQUENCE; Schema: public; Owner: chado
--

CREATE SEQUENCE project_dbxref_project_dbxref_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: project_dbxref_project_dbxref_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: chado
--

ALTER SEQUENCE project_dbxref_project_dbxref_id_seq OWNED BY project_dbxref.project_dbxref_id;


--
-- Name: project_feature; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

CREATE TABLE project_feature (
    project_feature_id bigint NOT NULL,
    feature_id bigint NOT NULL,
    project_id bigint NOT NULL
);


--
-- Name: TABLE project_feature; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON TABLE project_feature IS 'This table is intended associate records in the feature table with a project.';


--
-- Name: project_feature_project_feature_id_seq; Type: SEQUENCE; Schema: public; Owner: chado
--

CREATE SEQUENCE project_feature_project_feature_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: project_feature_project_feature_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: chado
--

ALTER SEQUENCE project_feature_project_feature_id_seq OWNED BY project_feature.project_feature_id;

--
-- Name: project_pub; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE project_pub
    ALTER project_pub_id TYPE bigint,
    ALTER project_id TYPE bigint,
    ALTER pub_id TYPE bigint;

COMMENT ON TABLE project_pub IS 'Linking table for associating projects and publications.';

--
-- Name: project_relationship; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE project_relationship
    ALTER project_relationship_id TYPE bigint,
    ALTER subject_project_id TYPE bigint,
    ALTER object_project_id TYPE bigint,
    ALTER type_id TYPE bigint;

--
-- Name: TABLE project_relationship; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON TABLE project_relationship IS 'Linking table for relating projects to each other.  For example, a
given project could be composed of several smaller subprojects';


--
-- Name: COLUMN project_relationship.type_id; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON COLUMN project_relationship.type_id IS 'The cvterm type of the relationship being stated, such as "part of".';

--
-- Name: project_stock; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

CREATE TABLE project_stock (
    project_stock_id bigint NOT NULL,
    stock_id bigint NOT NULL,
    project_id bigint NOT NULL
);


--
-- Name: TABLE project_stock; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON TABLE project_stock IS 'This table is intended associate records in the stock table with a project.';


--
-- Name: project_stock_project_stock_id_seq; Type: SEQUENCE; Schema: public; Owner: chado
--

CREATE SEQUENCE project_stock_project_stock_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
--
-- Name: projectprop; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE projectprop 
    ALTER projectprop_id TYPE bigint,
    ALTER project_id TYPE bigint,
    ALTER type_id TYPE bigint;

--
-- Name: protocol; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE protocol
    ALTER protocol_id TYPE bigint,
    ALTER type_id TYPE bigint,
    ALTER pub_id TYPE bigint,
    ALTER dbxref_id TYPE bigint;

--
-- Name: protocolparam; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE protocolparam 
    ALTER protocolparam_id TYPE bigint,
    ALTER protocol_id TYPE bigint,
    ALTER datatype_id TYPE bigint,
    ALTER unittype_id TYPE bigint;
    
--
-- Name: pub_dbxref; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE pub_dbxref
    ALTER pub_dbxref_id TYPE bigint,
    ALTER pub_id TYPE bigint,
    ALTER dbxref_id TYPE bigint;
    
--
-- Name: pub_relationship; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE pub_relationship
    ALTER pub_relationship_id TYPE bigint,
    ALTER subject_id TYPE bigint,
    ALTER object_id TYPE bigint,
    ALTER type_id TYPE bigint;
    
--
-- Name: pubauthor; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE pubauthor
    ALTER pubauthor_id TYPE bigint,
    ALTER pub_id TYPE bigint;
    
--
-- Name: pubauthor_contact; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

CREATE TABLE pubauthor_contact (
    pubauthor_contact_id bigint NOT NULL,
    contact_id bigint NOT NULL,
    pubauthor_id bigint NOT NULL
);


--
-- Name: TABLE pubauthor_contact; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON TABLE pubauthor_contact IS 'An author on a publication may have a corresponding entry in the contact table and this table can link the two.';


--
-- Name: pubauthor_contact_pubauthor_contact_id_seq; Type: SEQUENCE; Schema: public; Owner: chado
--

CREATE SEQUENCE pubauthor_contact_pubauthor_contact_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: pubauthor_contact_pubauthor_contact_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: chado
--

ALTER SEQUENCE pubauthor_contact_pubauthor_contact_id_seq OWNED BY pubauthor_contact.pubauthor_contact_id;

--
-- Name: pubprop; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE pubprop 
    ALTER pubprop_id TYPE bigint,
    ALTER pub_id TYPE bigint,
    ALTER type_id TYPE bigint;

--
-- Name: quantification; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE quantification
    ALTER quantification_id TYPE bigint,
    ALTER acquisition_id TYPE bigint,
    ALTER operator_id TYPE bigint,
    ALTER protocol_id TYPE bigint,
    ALTER analysis_id TYPE bigint;

--
-- Name: quantification_relationship; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE quantification_relationship
    ALTER quantification_relationship_id TYPE bigint,
    ALTER subject_id TYPE bigint,
    ALTER type_id TYPE bigint,
    ALTER object_id TYPE bigint;

--
-- Name: quantificationprop; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE quantificationprop 
    ALTER quantificationprop_id TYPE bigint,
    ALTER quantification_id TYPE bigint,
    ALTER type_id TYPE bigint;
    
--
-- Name: stock; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE stock
    ALTER stock_id TYPE bigint,
    ALTER dbxref_id TYPE bigint,
    ALTER organism_id TYPE bigint,
    ALTER type_id TYPE bigint;

--
-- Name: stock_cvterm; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE stock_cvterm
    ALTER stock_cvterm_id TYPE bigint,
    ALTER stock_id TYPE bigint,
    ALTER cvterm_id TYPE bigint,
    ALTER pub_id TYPE bigint;

--
-- Name: stock_cvtermprop; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE stock_cvtermprop
    ALTER stock_cvtermprop_id TYPE bigint,
    ALTER stock_cvterm_id TYPE bigint,
    ALTER type_id TYPE bigint;
    
--
-- Name: stock_dbxref; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE stock_dbxref 
    ALTER stock_dbxref_id TYPE bigint,
    ALTER stock_id TYPE bigint,
    ALTER dbxref_id TYPE bigint;

--
-- Name: stock_dbxrefprop; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE stock_dbxrefprop 
    ALTER stock_dbxrefprop_id TYPE bigint,
    ALTER stock_dbxref_id TYPE bigint,
    ALTER type_id TYPE bigint;

--
-- Name: stock_feature; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

CREATE TABLE stock_feature (
    stock_feature_id bigint NOT NULL,
    feature_id bigint NOT NULL,
    stock_id bigint NOT NULL,
    type_id bigint NOT NULL,
    rank integer DEFAULT 0 NOT NULL
);


--
-- Name: TABLE stock_feature; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON TABLE stock_feature IS 'Links a stock to a feature.';


--
-- Name: stock_feature_stock_feature_id_seq; Type: SEQUENCE; Schema: public; Owner: chado
--

CREATE SEQUENCE stock_feature_stock_feature_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: stock_feature_stock_feature_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: chado
--

ALTER SEQUENCE stock_feature_stock_feature_id_seq OWNED BY stock_feature.stock_feature_id;


--
-- Name: stock_featuremap; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

CREATE TABLE stock_featuremap (
    stock_featuremap_id bigint NOT NULL,
    featuremap_id bigint NOT NULL,
    stock_id bigint NOT NULL,
    type_id bigint
);


--
-- Name: TABLE stock_featuremap; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON TABLE stock_featuremap IS 'Links a featuremap to a stock.';


--
-- Name: stock_featuremap_stock_featuremap_id_seq; Type: SEQUENCE; Schema: public; Owner: chado
--

CREATE SEQUENCE stock_featuremap_stock_featuremap_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: stock_genotype; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE stock_genotype 
    ALTER stock_genotype_id TYPE bigint,
    ALTER stock_id TYPE bigint,
    ALTER genotype_id TYPE bigint;

--
-- Name: stock_library; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

CREATE TABLE stock_library (
    stock_library_id bigint NOT NULL,
    library_id bigint NOT NULL,
    stock_id bigint NOT NULL
);


--
-- Name: TABLE stock_library; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON TABLE stock_library IS 'Links a stock with a library.';


--
-- Name: stock_library_stock_library_id_seq; Type: SEQUENCE; Schema: public; Owner: chado
--

CREATE SEQUENCE stock_library_stock_library_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: stock_pub; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE stock_pub 
    ALTER stock_pub_id TYPE bigint,
    ALTER stock_id TYPE bigint,
    ALTER pub_id TYPE bigint;

--
-- Name: stock_relationship; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE stock_relationship 
    ALTER stock_relationship_id TYPE bigint,
    ALTER subject_id TYPE bigint,
    ALTER object_id TYPE bigint,
    ALTER type_id TYPE bigint;

--
-- Name: stock_relationship_cvterm; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE stock_relationship_cvterm
    ALTER stock_relationship_cvterm_id TYPE bigint,
    ALTER stock_relationship_id TYPE bigint,
    ALTER cvterm_id TYPE bigint,
    ALTER pub_id TYPE bigint;
    
--
-- Name: stock_relationship_pub; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE stock_relationship_pub 
    ALTER stock_relationship_pub_id TYPE bigint,
    ALTER stock_relationship_id TYPE bigint,
    ALTER pub_id TYPE bigint;

--
-- Name: stockcollection; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE stockcollection
    ALTER stockcollection_id TYPE bigint,
    ALTER type_id TYPE bigint,
    ALTER contact_id TYPE bigint;
    
--
-- Name: stockcollection_db; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

CREATE TABLE stockcollection_db (
    stockcollection_db_id bigint NOT NULL,
    stockcollection_id bigint NOT NULL,
    db_id bigint NOT NULL
);


--
-- Name: TABLE stockcollection_db; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON TABLE stockcollection_db IS 'Stock collections may be respresented 
by an external online database. This table associates a stock collection with 
a database where its member stocks can be found. Individual stock that are part 
of this collction should have entries in the stock_dbxref table with the same 
db_id record';


--
-- Name: stockcollection_db_stockcollection_db_id_seq; Type: SEQUENCE; Schema: public; Owner: chado
--

CREATE SEQUENCE stockcollection_db_stockcollection_db_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: stockcollection_stock; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE stockcollection_stock
    ALTER stockcollection_stock_id TYPE bigint,
    ALTER stockcollection_id TYPE bigint,
    ALTER stock_id TYPE bigint;
    

--
-- Name: stockcollectionprop; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE stockcollectionprop
    ALTER stockcollectionprop_id TYPE bigint,
    ALTER stockcollection_id TYPE bigint,
    ALTER type_id TYPE bigint;

--
-- Name: stockprop; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE stockprop
    ALTER stockprop_id TYPE bigint,
    ALTER stock_id TYPE bigint,
    ALTER type_id TYPE bigint;
    
--
-- Name: stockprop_pub; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE stockprop_pub 
    ALTER stockprop_pub_id TYPE biginT,
    ALTER stockprop_id TYPE bigint,
    ALTER pub_id TYPE bigint;
    
--
-- Name: study; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE study
    ALTER study_id TYPE bigint,
    ALTER contact_id TYPE bigint,
    ALTER pub_id TYPE bigint,
    ALTER dbxref_id TYPE bigint;

--
-- Name: study_assay; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE study_assay
    ALTER study_assay_id TYPE bigint,
    ALTER study_id TYPE bigint,
    ALTER assay_id TYPE bigint;

--
-- Name: studydesign; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE studydesign
    ALTER studydesign_id TYPE bigint,
    ALTER study_id TYPE bigint;

--
-- Name: studydesignprop; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE studydesignprop 
    ALTER studydesignprop_id TYPE bigint,
    ALTER studydesign_id TYPE bigint,
    ALTER type_id TYPE bigint;

--
-- Name: studyfactor; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE studyfactor 
    ALTER studyfactor_id TYPE bigint,
    ALTER studydesign_id TYPE bigint,
    ALTER type_id TYPE bigint;
    
--
-- Name: studyfactorvalue; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE studyfactorvalue 
    ALTER studyfactorvalue_id TYPE bigint,
    ALTER studyfactor_id TYPE bigint,
    ALTER assay_id TYPE bigint;
    
--
-- Name: studyprop; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE studyprop 
    ALTER studyprop_id TYPE bigint,
    ALTER study_id TYPE bigint,
    ALTER type_id TYPE bigint;

--
-- Name: studyprop_feature; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE studyprop_feature
    ALTER studyprop_feature_id TYPE bigint,
    ALTER studyprop_id TYPE bigint,
    ALTER feature_id TYPE bigint,
    ALTER type_id TYPE bigint;

--
-- Name: tableinfo; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE tableinfo
    ALTER tableinfo_Id TYPE bigint,
    ALTER view_on_table_id TYPE bigint,
    ALTER superclass_table_id TYPE bigint;
    
--
-- Name: treatment; Type: TABLE; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE treatment
    ALTER treatment_id TYPE bigint,
    ALTER biomaterial_id TYPE bigint,
    ALTER type_id TYPE bigint,
    ALTER protocol_id TYPE bigint;
    
--
-- Name: analysis_cvterm_id; Type: DEFAULT; Schema: public; Owner: chado
--

ALTER TABLE ONLY analysis_cvterm ALTER COLUMN analysis_cvterm_id SET DEFAULT nextval('analysis_cvterm_analysis_cvterm_id_seq'::regclass);


--
-- Name: analysis_dbxref_id; Type: DEFAULT; Schema: public; Owner: chado
--

ALTER TABLE ONLY analysis_dbxref ALTER COLUMN analysis_dbxref_id SET DEFAULT nextval('analysis_dbxref_analysis_dbxref_id_seq'::regclass);


--
-- Name: analysis_pub_id; Type: DEFAULT; Schema: public; Owner: chado
--

ALTER TABLE ONLY analysis_pub ALTER COLUMN analysis_pub_id SET DEFAULT nextval('analysis_pub_analysis_pub_id_seq'::regclass);


--
-- Name: analysis_relationship_id; Type: DEFAULT; Schema: public; Owner: chado
--

ALTER TABLE ONLY analysis_relationship ALTER COLUMN analysis_relationship_id SET DEFAULT nextval('analysis_relationship_analysis_relationship_id_seq'::regclass);

--
-- Name: dbprop_id; Type: DEFAULT; Schema: public; Owner: chado
--

ALTER TABLE ONLY dbprop ALTER COLUMN dbprop_id SET DEFAULT nextval('dbprop_dbprop_id_seq'::regclass);

--
-- Name: feature_contact_id; Type: DEFAULT; Schema: public; Owner: chado
--

ALTER TABLE ONLY feature_contact ALTER COLUMN feature_contact_id SET DEFAULT nextval('feature_contact_feature_contact_id_seq'::regclass);

--
-- Name: featuremap_contact_id; Type: DEFAULT; Schema: public; Owner: chado
--

ALTER TABLE ONLY featuremap_contact ALTER COLUMN featuremap_contact_id SET DEFAULT nextval('featuremap_contact_featuremap_contact_id_seq'::regclass);


--
-- Name: featuremap_dbxref_id; Type: DEFAULT; Schema: public; Owner: chado
--

ALTER TABLE ONLY featuremap_dbxref ALTER COLUMN featuremap_dbxref_id SET DEFAULT nextval('featuremap_dbxref_featuremap_dbxref_id_seq'::regclass);


--
-- Name: featuremap_organism_id; Type: DEFAULT; Schema: public; Owner: chado
--

ALTER TABLE ONLY featuremap_organism ALTER COLUMN featuremap_organism_id SET DEFAULT nextval('featuremap_organism_featuremap_organism_id_seq'::regclass);

--
-- Name: featuremapprop_id; Type: DEFAULT; Schema: public; Owner: chado
--

ALTER TABLE ONLY featuremapprop ALTER COLUMN featuremapprop_id SET DEFAULT nextval('featuremapprop_featuremapprop_id_seq'::regclass);


--
-- Name: featureposprop_id; Type: DEFAULT; Schema: public; Owner: chado
--

ALTER TABLE ONLY featureposprop ALTER COLUMN featureposprop_id SET DEFAULT nextval('featureposprop_featureposprop_id_seq'::regclass);

--
-- Name: library_contact_id; Type: DEFAULT; Schema: public; Owner: chado
--

ALTER TABLE ONLY library_contact ALTER COLUMN library_contact_id SET DEFAULT nextval('library_contact_library_contact_id_seq'::regclass);

--
-- Name: library_expression_id; Type: DEFAULT; Schema: public; Owner: chado
--

ALTER TABLE ONLY library_expression ALTER COLUMN library_expression_id SET DEFAULT nextval('library_expression_library_expression_id_seq'::regclass);


--
-- Name: library_expressionprop_id; Type: DEFAULT; Schema: public; Owner: chado
--

ALTER TABLE ONLY library_expressionprop ALTER COLUMN library_expressionprop_id SET DEFAULT nextval('library_expressionprop_library_expressionprop_id_seq'::regclass);


--
-- Name: library_featureprop_id; Type: DEFAULT; Schema: public; Owner: chado
--

ALTER TABLE ONLY library_featureprop ALTER COLUMN library_featureprop_id SET DEFAULT nextval('library_featureprop_library_featureprop_id_seq'::regclass);

--
-- Name: library_relationship_id; Type: DEFAULT; Schema: public; Owner: chado
--

ALTER TABLE ONLY library_relationship ALTER COLUMN library_relationship_id SET DEFAULT nextval('library_relationship_library_relationship_id_seq'::regclass);


--
-- Name: library_relationship_pub_id; Type: DEFAULT; Schema: public; Owner: chado
--

ALTER TABLE ONLY library_relationship_pub ALTER COLUMN library_relationship_pub_id SET DEFAULT nextval('library_relationship_pub_library_relationship_pub_id_seq'::regclass);


--
-- Name: nd_experiment_analysis_id; Type: DEFAULT; Schema: public; Owner: chado
--

ALTER TABLE ONLY nd_experiment_analysis ALTER COLUMN nd_experiment_analysis_id SET DEFAULT nextval('nd_experiment_analysis_nd_experiment_analysis_id_seq'::regclass);

--
-- Name: organism_cvterm_id; Type: DEFAULT; Schema: public; Owner: chado
--

ALTER TABLE ONLY organism_cvterm ALTER COLUMN organism_cvterm_id SET DEFAULT nextval('organism_cvterm_organism_cvterm_id_seq'::regclass);


--
-- Name: organism_cvtermprop_id; Type: DEFAULT; Schema: public; Owner: chado
--

ALTER TABLE ONLY organism_cvtermprop ALTER COLUMN organism_cvtermprop_id SET DEFAULT nextval('organism_cvtermprop_organism_cvtermprop_id_seq'::regclass);

--
-- Name: organism_pub_id; Type: DEFAULT; Schema: public; Owner: chado
--

ALTER TABLE ONLY organism_pub ALTER COLUMN organism_pub_id SET DEFAULT nextval('organism_pub_organism_pub_id_seq'::regclass);


--
-- Name: organism_relationship_id; Type: DEFAULT; Schema: public; Owner: chado
--

ALTER TABLE ONLY organism_relationship ALTER COLUMN organism_relationship_id SET DEFAULT nextval('organism_relationship_organism_relationship_id_seq'::regclass);


--
-- Name: organismprop_pub_id; Type: DEFAULT; Schema: public; Owner: chado
--

ALTER TABLE ONLY organismprop_pub ALTER COLUMN organismprop_pub_id SET DEFAULT nextval('organismprop_pub_organismprop_pub_id_seq'::regclass);

--
-- Name: phenotypeprop_id; Type: DEFAULT; Schema: public; Owner: chado
--

ALTER TABLE ONLY phenotypeprop ALTER COLUMN phenotypeprop_id SET DEFAULT nextval('phenotypeprop_phenotypeprop_id_seq'::regclass);

--
-- Name: phylotreeprop_id; Type: DEFAULT; Schema: public; Owner: chado
--

ALTER TABLE ONLY phylotreeprop ALTER COLUMN phylotreeprop_id SET DEFAULT nextval('phylotreeprop_phylotreeprop_id_seq'::regclass);

--
-- Name: project_analysis_id; Type: DEFAULT; Schema: public; Owner: chado
--

ALTER TABLE ONLY project_analysis ALTER COLUMN project_analysis_id SET DEFAULT nextval('project_analysis_project_analysis_id_seq'::regclass);

--
-- Name: project_dbxref_id; Type: DEFAULT; Schema: public; Owner: chado
--

ALTER TABLE ONLY project_dbxref ALTER COLUMN project_dbxref_id SET DEFAULT nextval('project_dbxref_project_dbxref_id_seq'::regclass);


--
-- Name: project_feature_id; Type: DEFAULT; Schema: public; Owner: chado
--

ALTER TABLE ONLY project_feature ALTER COLUMN project_feature_id SET DEFAULT nextval('project_feature_project_feature_id_seq'::regclass);

--
-- Name: project_stock_id; Type: DEFAULT; Schema: public; Owner: chado
--

ALTER TABLE ONLY project_stock ALTER COLUMN project_stock_id SET DEFAULT nextval('project_stock_project_stock_id_seq'::regclass);

--
-- Name: pubauthor_contact_id; Type: DEFAULT; Schema: public; Owner: chado
--

ALTER TABLE ONLY pubauthor_contact ALTER COLUMN pubauthor_contact_id SET DEFAULT nextval('pubauthor_contact_pubauthor_contact_id_seq'::regclass);


--
-- Name: stock_feature_id; Type: DEFAULT; Schema: public; Owner: chado
--

ALTER TABLE ONLY stock_feature ALTER COLUMN stock_feature_id SET DEFAULT nextval('stock_feature_stock_feature_id_seq'::regclass);


--
-- Name: stock_featuremap_id; Type: DEFAULT; Schema: public; Owner: chado
--

ALTER TABLE ONLY stock_featuremap ALTER COLUMN stock_featuremap_id SET DEFAULT nextval('stock_featuremap_stock_featuremap_id_seq'::regclass);


--
-- Name: stock_library_id; Type: DEFAULT; Schema: public; Owner: chado
--

ALTER TABLE ONLY stock_library ALTER COLUMN stock_library_id SET DEFAULT nextval('stock_library_stock_library_id_seq'::regclass);

--
-- Name: stockcollection_db_id; Type: DEFAULT; Schema: public; Owner: chado
--

ALTER TABLE ONLY stockcollection_db ALTER COLUMN stockcollection_db_id SET DEFAULT nextval('stockcollection_db_stockcollection_db_id_seq'::regclass);

--
-- Name: analysis_cvterm_c1; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY analysis_cvterm
    ADD CONSTRAINT analysis_cvterm_c1 UNIQUE (analysis_id, cvterm_id, rank);


--
-- Name: analysis_cvterm_pkey; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY analysis_cvterm
    ADD CONSTRAINT analysis_cvterm_pkey PRIMARY KEY (analysis_cvterm_id);


--
-- Name: analysis_dbxref_c1; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY analysis_dbxref
    ADD CONSTRAINT analysis_dbxref_c1 UNIQUE (analysis_id, dbxref_id);


--
-- Name: analysis_dbxref_pkey; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY analysis_dbxref
    ADD CONSTRAINT analysis_dbxref_pkey PRIMARY KEY (analysis_dbxref_id);

--
-- Name: analysis_pub_c1; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY analysis_pub
    ADD CONSTRAINT analysis_pub_c1 UNIQUE (analysis_id, pub_id);


--
-- Name: analysis_pub_pkey; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY analysis_pub
    ADD CONSTRAINT analysis_pub_pkey PRIMARY KEY (analysis_pub_id);


--
-- Name: analysis_relationship_c1; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY analysis_relationship
    ADD CONSTRAINT analysis_relationship_c1 UNIQUE (subject_id, object_id, type_id, rank);


--
-- Name: analysis_relationship_pkey; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY analysis_relationship
    ADD CONSTRAINT analysis_relationship_pkey PRIMARY KEY (analysis_relationship_id);

--
-- Name: contactprop_c1; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY contactprop
    ADD CONSTRAINT contactprop_c1 UNIQUE (contact_id, type_id, rank);


--
-- Name: contactprop_pkey; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY contactprop
    ADD CONSTRAINT contactprop_pkey PRIMARY KEY (contactprop_id);

--
-- Name: dbprop_c1; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY dbprop
    ADD CONSTRAINT dbprop_c1 UNIQUE (db_id, type_id, rank);


--
-- Name: dbprop_pkey; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY dbprop
    ADD CONSTRAINT dbprop_pkey PRIMARY KEY (dbprop_id);

--
-- Name: expression_cvterm_c1; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY expression_cvterm
    ADD CONSTRAINT expression_cvterm_c1 UNIQUE (expression_id, cvterm_id, rank, cvterm_type_id);


--
-- Name: contactprop_id; Type: DEFAULT; Schema: public; Owner: chado
--

ALTER TABLE ONLY contactprop ALTER COLUMN contactprop_id SET DEFAULT nextval('contactprop_contactprop_id_seq'::regclass);

--
-- Name: feature_contact_c1; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY feature_contact
    ADD CONSTRAINT feature_contact_c1 UNIQUE (feature_id, contact_id);


--
-- Name: feature_contact_pkey; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY feature_contact
    ADD CONSTRAINT feature_contact_pkey PRIMARY KEY (feature_contact_id);

--
-- Name: featuremap_contact_c1; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY featuremap_contact
    ADD CONSTRAINT featuremap_contact_c1 UNIQUE (featuremap_id, contact_id);


--
-- Name: featuremap_contact_pkey; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY featuremap_contact
    ADD CONSTRAINT featuremap_contact_pkey PRIMARY KEY (featuremap_contact_id);


--
-- Name: featuremap_dbxref_pkey; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY featuremap_dbxref
    ADD CONSTRAINT featuremap_dbxref_pkey PRIMARY KEY (featuremap_dbxref_id);


--
-- Name: featuremap_organism_c1; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY featuremap_organism
    ADD CONSTRAINT featuremap_organism_c1 UNIQUE (featuremap_id, organism_id);


--
-- Name: featuremap_organism_pkey; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY featuremap_organism
    ADD CONSTRAINT featuremap_organism_pkey PRIMARY KEY (featuremap_organism_id);

--
-- Name: featuremapprop_c1; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY featuremapprop
    ADD CONSTRAINT featuremapprop_c1 UNIQUE (featuremap_id, type_id, rank);


--
-- Name: featuremapprop_pkey; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY featuremapprop
    ADD CONSTRAINT featuremapprop_pkey PRIMARY KEY (featuremapprop_id);

--
-- Name: featureposprop_c1; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY featureposprop
    ADD CONSTRAINT featureposprop_c1 UNIQUE (featurepos_id, type_id, rank);


--
-- Name: featureposprop_pkey; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY featureposprop
    ADD CONSTRAINT featureposprop_pkey PRIMARY KEY (featureposprop_id);

--
-- Name: library_contact_c1; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY library_contact
    ADD CONSTRAINT library_contact_c1 UNIQUE (library_id, contact_id);


--
-- Name: library_contact_pkey; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY library_contact
    ADD CONSTRAINT library_contact_pkey PRIMARY KEY (library_contact_id);

--
-- Name: library_expression_c1; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY library_expression
    ADD CONSTRAINT library_expression_c1 UNIQUE (library_id, expression_id);


--
-- Name: library_expression_pkey; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY library_expression
    ADD CONSTRAINT library_expression_pkey PRIMARY KEY (library_expression_id);


--
-- Name: library_expressionprop_c1; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY library_expressionprop
    ADD CONSTRAINT library_expressionprop_c1 UNIQUE (library_expression_id, type_id, rank);


--
-- Name: library_expressionprop_pkey; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY library_expressionprop
    ADD CONSTRAINT library_expressionprop_pkey PRIMARY KEY (library_expressionprop_id);

--
-- Name: library_featureprop_c1; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY library_featureprop
    ADD CONSTRAINT library_featureprop_c1 UNIQUE (library_feature_id, type_id, rank);


--
-- Name: library_featureprop_pkey; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY library_featureprop
    ADD CONSTRAINT library_featureprop_pkey PRIMARY KEY (library_featureprop_id);

--
-- Name: library_relationship_c1; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY library_relationship
    ADD CONSTRAINT library_relationship_c1 UNIQUE (subject_id, object_id, type_id);


--
-- Name: library_relationship_pkey; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY library_relationship
    ADD CONSTRAINT library_relationship_pkey PRIMARY KEY (library_relationship_id);


--
-- Name: library_relationship_pub_c1; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY library_relationship_pub
    ADD CONSTRAINT library_relationship_pub_c1 UNIQUE (library_relationship_id, pub_id);


--
-- Name: library_relationship_pub_pkey; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY library_relationship_pub
    ADD CONSTRAINT library_relationship_pub_pkey PRIMARY KEY (library_relationship_pub_id);

--
-- Name: nd_experiment_analysis_pkey; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY nd_experiment_analysis
    ADD CONSTRAINT nd_experiment_analysis_pkey PRIMARY KEY (nd_experiment_analysis_id);

--
-- Name: nd_experiment_project_c1; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY nd_experiment_project
    ADD CONSTRAINT nd_experiment_project_c1 UNIQUE (project_id, nd_experiment_id);

ALTER TABLE ONLY organism
    ADD CONSTRAINT organism_c1 UNIQUE (genus, species, type_id, infraspecific_name);


--
-- Name: organism_cvterm_c1; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY organism_cvterm
    ADD CONSTRAINT organism_cvterm_c1 UNIQUE (organism_id, cvterm_id, pub_id);


--
-- Name: organism_cvterm_pkey; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY organism_cvterm
    ADD CONSTRAINT organism_cvterm_pkey PRIMARY KEY (organism_cvterm_id);


--
-- Name: organism_cvtermprop_c1; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY organism_cvtermprop
    ADD CONSTRAINT organism_cvtermprop_c1 UNIQUE (organism_cvterm_id, type_id, rank);


--
-- Name: organism_cvtermprop_pkey; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY organism_cvtermprop
    ADD CONSTRAINT organism_cvtermprop_pkey PRIMARY KEY (organism_cvtermprop_id);

--
-- Name: organism_pub_c1; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY organism_pub
    ADD CONSTRAINT organism_pub_c1 UNIQUE (organism_id, pub_id);


--
-- Name: organism_pub_pkey; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY organism_pub
    ADD CONSTRAINT organism_pub_pkey PRIMARY KEY (organism_pub_id);


--
-- Name: organism_relationship_c1; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY organism_relationship
    ADD CONSTRAINT organism_relationship_c1 UNIQUE (subject_id, object_id, type_id, rank);


--
-- Name: organism_relationship_pkey; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY organism_relationship
    ADD CONSTRAINT organism_relationship_pkey PRIMARY KEY (organism_relationship_id);

--
-- Name: organismprop_pub_c1; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY organismprop_pub
    ADD CONSTRAINT organismprop_pub_c1 UNIQUE (organismprop_id, pub_id);


--
-- Name: organismprop_pub_pkey; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY organismprop_pub
    ADD CONSTRAINT organismprop_pub_pkey PRIMARY KEY (organismprop_pub_id);


--
-- Name: phenotypeprop_c1; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY phenotypeprop
    ADD CONSTRAINT phenotypeprop_c1 UNIQUE (phenotype_id, type_id, rank);


--
-- Name: phenotypeprop_pkey; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY phenotypeprop
    ADD CONSTRAINT phenotypeprop_pkey PRIMARY KEY (phenotypeprop_id);

--
-- Name: phylotreeprop_c1; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY phylotreeprop
    ADD CONSTRAINT phylotreeprop_c1 UNIQUE (phylotree_id, type_id, rank);


--
-- Name: phylotreeprop_pkey; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY phylotreeprop
    ADD CONSTRAINT phylotreeprop_pkey PRIMARY KEY (phylotreeprop_id);


--
-- Name: project_analysis_c1; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY project_analysis
    ADD CONSTRAINT project_analysis_c1 UNIQUE (project_id, analysis_id);


--
-- Name: project_analysis_pkey; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY project_analysis
    ADD CONSTRAINT project_analysis_pkey PRIMARY KEY (project_analysis_id);

-
-- Name: project_dbxref_c1; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY project_dbxref
    ADD CONSTRAINT project_dbxref_c1 UNIQUE (project_id, dbxref_id);


--
-- Name: project_dbxref_pkey; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY project_dbxref
    ADD CONSTRAINT project_dbxref_pkey PRIMARY KEY (project_dbxref_id);


--
-- Name: project_feature_c1; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY project_feature
    ADD CONSTRAINT project_feature_c1 UNIQUE (feature_id, project_id);


--
-- Name: project_feature_pkey; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY project_feature
    ADD CONSTRAINT project_feature_pkey PRIMARY KEY (project_feature_id);

--
-- Name: project_stock_c1; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY project_stock
    ADD CONSTRAINT project_stock_c1 UNIQUE (stock_id, project_id);


--
-- Name: project_stock_pkey; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY project_stock
    ADD CONSTRAINT project_stock_pkey PRIMARY KEY (project_stock_id);

--
-- Name: pubauthor_contact_c1; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY pubauthor_contact
    ADD CONSTRAINT pubauthor_contact_c1 UNIQUE (contact_id, pubauthor_id);


--
-- Name: pubauthor_contact_pkey; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY pubauthor_contact
    ADD CONSTRAINT pubauthor_contact_pkey PRIMARY KEY (pubauthor_contact_id);

--
-- Name: stock_feature_c1; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY stock_feature
    ADD CONSTRAINT stock_feature_c1 UNIQUE (feature_id, stock_id, type_id, rank);


--
-- Name: stock_feature_pkey; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY stock_feature
    ADD CONSTRAINT stock_feature_pkey PRIMARY KEY (stock_feature_id);


--
-- Name: stock_featuremap_c1; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY stock_featuremap
    ADD CONSTRAINT stock_featuremap_c1 UNIQUE (featuremap_id, stock_id, type_id);


--
-- Name: stock_featuremap_pkey; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY stock_featuremap
    ADD CONSTRAINT stock_featuremap_pkey PRIMARY KEY (stock_featuremap_id);

--
-- Name: stock_library_c1; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY stock_library
    ADD CONSTRAINT stock_library_c1 UNIQUE (library_id, stock_id);


--
-- Name: stock_library_pkey; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY stock_library
    ADD CONSTRAINT stock_library_pkey PRIMARY KEY (stock_library_id);


--
-- Name: stockcollection_db_c1; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY stockcollection_db
    ADD CONSTRAINT stockcollection_db_c1 UNIQUE (stockcollection_id, db_id);


--
-- Name: stockcollection_db_pkey; Type: CONSTRAINT; Schema: public; Owner: chado; Tablespace: 
--

ALTER TABLE ONLY stockcollection_db
    ADD CONSTRAINT stockcollection_db_pkey PRIMARY KEY (stockcollection_db_id);

--
-- Name: analysis_cvterm_idx1; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX analysis_cvterm_idx1 ON analysis_cvterm USING btree (analysis_id);


--
-- Name: analysis_cvterm_idx2; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX analysis_cvterm_idx2 ON analysis_cvterm USING btree (cvterm_id);


--
-- Name: analysis_dbxref_idx1; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX analysis_dbxref_idx1 ON analysis_dbxref USING btree (analysis_id);


--
-- Name: analysis_dbxref_idx2; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX analysis_dbxref_idx2 ON analysis_dbxref USING btree (dbxref_id);


--
-- Name: analysis_pub_idx1; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX analysis_pub_idx1 ON analysis_pub USING btree (analysis_id);


--
-- Name: analysis_pub_idx2; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX analysis_pub_idx2 ON analysis_pub USING btree (pub_id);


--
-- Name: analysis_relationship_idx1; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX analysis_relationship_idx1 ON analysis_relationship USING btree (subject_id);


--
-- Name: analysis_relationship_idx2; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX analysis_relationship_idx2 ON analysis_relationship USING btree (object_id);


--
-- Name: analysis_relationship_idx3; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX analysis_relationship_idx3 ON analysis_relationship USING btree (type_id);

--
-- Name: analysisfeatureprop_idx1; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX analysisfeatureprop_idx1 ON analysisfeatureprop USING btree (analysisfeature_id);


--
-- Name: analysisfeatureprop_idx2; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX analysisfeatureprop_idx2 ON analysisfeatureprop USING btree (type_id);

--
-- Name: contactprop_idx1; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX contactprop_idx1 ON contactprop USING btree (contact_id);


--
-- Name: contactprop_idx2; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX contactprop_idx2 ON contactprop USING btree (type_id);

--
-- Name: dbprop_idx1; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX dbprop_idx1 ON dbprop USING btree (db_id);


--
-- Name: dbprop_idx2; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX dbprop_idx2 ON dbprop USING btree (type_id);

--
-- Name: feature_contact_idx1; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX feature_contact_idx1 ON feature_contact USING btree (feature_id);


--
-- Name: feature_contact_idx2; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX feature_contact_idx2 ON feature_contact USING btree (contact_id);


--
-- Name: featuremap_contact_idx1; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX featuremap_contact_idx1 ON featuremap_contact USING btree (featuremap_id);


--
-- Name: featuremap_contact_idx2; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX featuremap_contact_idx2 ON featuremap_contact USING btree (contact_id);


--
-- Name: featuremap_dbxref_idx1; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX featuremap_dbxref_idx1 ON featuremap_dbxref USING btree (featuremap_id);


--
-- Name: featuremap_dbxref_idx2; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX featuremap_dbxref_idx2 ON featuremap_dbxref USING btree (dbxref_id);


--
-- Name: featuremap_organism_idx1; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX featuremap_organism_idx1 ON featuremap_organism USING btree (featuremap_id);


--
-- Name: featuremap_organism_idx2; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX featuremap_organism_idx2 ON featuremap_organism USING btree (organism_id);


--
-- Name: featuremapprop_idx1; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX featuremapprop_idx1 ON featuremapprop USING btree (featuremap_id);


--
-- Name: featuremapprop_idx2; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX featuremapprop_idx2 ON featuremapprop USING btree (type_id);


--
-- Name: featureposprop_idx1; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX featureposprop_idx1 ON featureposprop USING btree (featurepos_id);


--
-- Name: featureposprop_idx2; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX featureposprop_idx2 ON featureposprop USING btree (type_id);


--
-- Name: library_contact_idx1; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX library_contact_idx1 ON library USING btree (library_id);


--
-- Name: library_contact_idx2; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX library_contact_idx2 ON contact USING btree (contact_id);

--
-- Name: library_expression_idx1; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX library_expression_idx1 ON library_expression USING btree (library_id);


--
-- Name: library_expression_idx2; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX library_expression_idx2 ON library_expression USING btree (expression_id);


--
-- Name: library_expression_idx3; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX library_expression_idx3 ON library_expression USING btree (pub_id);


--
-- Name: library_expressionprop_idx1; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX library_expressionprop_idx1 ON library_expressionprop USING btree (library_expression_id);


--
-- Name: library_expressionprop_idx2; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX library_expressionprop_idx2 ON library_expressionprop USING btree (type_id);

--
-- Name: library_featureprop_idx1; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX library_featureprop_idx1 ON library_featureprop USING btree (library_feature_id);


--
-- Name: library_featureprop_idx2; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX library_featureprop_idx2 ON library_featureprop USING btree (type_id);

--
-- Name: library_relationship_idx1; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX library_relationship_idx1 ON library_relationship USING btree (subject_id);


--
-- Name: library_relationship_idx2; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX library_relationship_idx2 ON library_relationship USING btree (object_id);


--
-- Name: library_relationship_idx3; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX library_relationship_idx3 ON library_relationship USING btree (type_id);


--
-- Name: library_relationship_pub_idx1; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX library_relationship_pub_idx1 ON library_relationship_pub USING btree (library_relationship_id);


--
-- Name: library_relationship_pub_idx2; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX library_relationship_pub_idx2 ON library_relationship_pub USING btree (pub_id);

--
-- Name: nd_experiment_analysis_idx1; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX nd_experiment_analysis_idx1 ON nd_experiment_analysis USING btree (nd_experiment_id);


--
-- Name: nd_experiment_analysis_idx2; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX nd_experiment_analysis_idx2 ON nd_experiment_analysis USING btree (analysis_id);


--
-- Name: nd_experiment_analysis_idx3; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX nd_experiment_analysis_idx3 ON nd_experiment_analysis USING btree (type_id);


--
-- Name: nd_experiment_contact_idx1; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX nd_experiment_contact_idx1 ON nd_experiment_contact USING btree (nd_experiment_id);


--
-- Name: nd_experiment_contact_idx2; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX nd_experiment_contact_idx2 ON nd_experiment_contact USING btree (contact_id);


--
-- Name: nd_experiment_dbxref_idx1; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX nd_experiment_dbxref_idx1 ON nd_experiment_dbxref USING btree (nd_experiment_id);


--
-- Name: nd_experiment_dbxref_idx2; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX nd_experiment_dbxref_idx2 ON nd_experiment_dbxref USING btree (dbxref_id);


--
-- Name: nd_experiment_genotype_idx1; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX nd_experiment_genotype_idx1 ON nd_experiment_genotype USING btree (nd_experiment_id);


--
-- Name: nd_experiment_genotype_idx2; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX nd_experiment_genotype_idx2 ON nd_experiment_genotype USING btree (genotype_id);


--
-- Name: nd_experiment_idx1; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX nd_experiment_idx1 ON nd_experiment USING btree (nd_geolocation_id);


--
-- Name: nd_experiment_idx2; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX nd_experiment_idx2 ON nd_experiment USING btree (type_id);


--
-- Name: nd_experiment_phenotype_idx1; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX nd_experiment_phenotype_idx1 ON nd_experiment_phenotype USING btree (nd_experiment_id);


--
-- Name: nd_experiment_phenotype_idx2; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX nd_experiment_phenotype_idx2 ON nd_experiment_phenotype USING btree (phenotype_id);


--
-- Name: nd_experiment_project_idx1; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX nd_experiment_project_idx1 ON nd_experiment_project USING btree (project_id);


--
-- Name: nd_experiment_project_idx2; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX nd_experiment_project_idx2 ON nd_experiment_project USING btree (nd_experiment_id);


--
-- Name: nd_experiment_protocol_idx1; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX nd_experiment_protocol_idx1 ON nd_experiment_protocol USING btree (nd_experiment_id);


--
-- Name: nd_experiment_protocol_idx2; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX nd_experiment_protocol_idx2 ON nd_experiment_protocol USING btree (nd_protocol_id);





--
-- Name: nd_experiment_stock_dbxref_idx1; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX nd_experiment_stock_dbxref_idx1 ON nd_experiment_stock_dbxref USING btree (nd_experiment_stock_id);


--
-- Name: nd_experiment_stock_dbxref_idx2; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX nd_experiment_stock_dbxref_idx2 ON nd_experiment_stock_dbxref USING btree (dbxref_id);


--
-- Name: nd_experiment_stock_idx1; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX nd_experiment_stock_idx1 ON nd_experiment_stock USING btree (nd_experiment_id);


--
-- Name: nd_experiment_stock_idx2; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX nd_experiment_stock_idx2 ON nd_experiment_stock USING btree (stock_id);


--
-- Name: nd_experiment_stock_idx3; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX nd_experiment_stock_idx3 ON nd_experiment_stock USING btree (type_id);


--
-- Name: nd_experiment_stockprop_idx1; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX nd_experiment_stockprop_idx1 ON nd_experiment_stockprop USING btree (nd_experiment_stock_id);


--
-- Name: nd_experiment_stockprop_idx2; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX nd_experiment_stockprop_idx2 ON nd_experiment_stockprop USING btree (type_id);


--
-- Name: nd_experimentprop_idx1; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX nd_experimentprop_idx1 ON nd_experimentprop USING btree (nd_experiment_id);


--
-- Name: nd_experimentprop_idx2; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX nd_experimentprop_idx2 ON nd_experimentprop USING btree (type_id);


--
-- Name: nd_geolocation_idx1; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX nd_geolocation_idx1 ON nd_geolocation USING btree (latitude);


--
-- Name: nd_geolocation_idx2; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX nd_geolocation_idx2 ON nd_geolocation USING btree (longitude);


--
-- Name: nd_geolocation_idx3; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX nd_geolocation_idx3 ON nd_geolocation USING btree (altitude);


--
-- Name: nd_geolocationprop_idx1; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX nd_geolocationprop_idx1 ON nd_geolocationprop USING btree (nd_geolocation_id);


--
-- Name: nd_geolocationprop_idx2; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX nd_geolocationprop_idx2 ON nd_geolocationprop USING btree (type_id);


--
-- Name: nd_protocol_idx1; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX nd_protocol_idx1 ON nd_protocol USING btree (type_id);


--
-- Name: nd_protocol_reagent_idx1; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX nd_protocol_reagent_idx1 ON nd_protocol_reagent USING btree (nd_protocol_id);


--
-- Name: nd_protocol_reagent_idx2; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX nd_protocol_reagent_idx2 ON nd_protocol_reagent USING btree (reagent_id);


--
-- Name: nd_protocol_reagent_idx3; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX nd_protocol_reagent_idx3 ON nd_protocol_reagent USING btree (type_id);


--
-- Name: nd_protocolprop_idx1; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX nd_protocolprop_idx1 ON nd_protocolprop USING btree (nd_protocol_id);


--
-- Name: nd_protocolprop_idx2; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX nd_protocolprop_idx2 ON nd_protocolprop USING btree (type_id);


--
-- Name: nd_reagent_idx1; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX nd_reagent_idx1 ON nd_reagent USING btree (type_id);


--
-- Name: nd_reagent_idx2; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX nd_reagent_idx2 ON nd_reagent USING btree (feature_id);


--
-- Name: nd_reagent_relationship_idx1; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX nd_reagent_relationship_idx1 ON nd_reagent_relationship USING btree (subject_reagent_id);


--
-- Name: nd_reagent_relationship_idx2; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX nd_reagent_relationship_idx2 ON nd_reagent_relationship USING btree (object_reagent_id);


--
-- Name: nd_reagent_relationship_idx3; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX nd_reagent_relationship_idx3 ON nd_reagent_relationship USING btree (type_id);


--
-- Name: nd_reagentprop_idx1; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX nd_reagentprop_idx1 ON nd_reagentprop USING btree (nd_reagent_id);


--
-- Name: nd_reagentprop_idx2; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX nd_reagentprop_idx2 ON nd_reagentprop USING btree (type_id);


--
-- Name: organism_cvterm_idx1; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX organism_cvterm_idx1 ON organism_cvterm USING btree (organism_id);


--
-- Name: organism_cvterm_idx2; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX organism_cvterm_idx2 ON organism_cvterm USING btree (cvterm_id);


--
-- Name: organism_cvtermprop_idx1; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX organism_cvtermprop_idx1 ON organism_cvtermprop USING btree (organism_cvterm_id);


--
-- Name: organism_cvtermprop_idx2; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX organism_cvtermprop_idx2 ON organism_cvtermprop USING btree (type_id);


--
-- Name: organism_pub_idx1; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX organism_pub_idx1 ON organism_pub USING btree (organism_id);


--
-- Name: organism_pub_idx2; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX organism_pub_idx2 ON organism_pub USING btree (pub_id);


--
-- Name: organism_relationship_idx1; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX organism_relationship_idx1 ON organism_relationship USING btree (subject_id);


--
-- Name: organism_relationship_idx2; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX organism_relationship_idx2 ON organism_relationship USING btree (object_id);


--
-- Name: organism_relationship_idx3; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX organism_relationship_idx3 ON organism_relationship USING btree (type_id);


--
-- Name: organismprop_pub_idx1; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX organismprop_pub_idx1 ON organismprop_pub USING btree (organismprop_id);


--
-- Name: organismprop_pub_idx2; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX organismprop_pub_idx2 ON organismprop_pub USING btree (pub_id);


--
-- Name: phenotypeprop_idx1; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX phenotypeprop_idx1 ON phenotypeprop USING btree (phenotype_id);


--
-- Name: phenotypeprop_idx2; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX phenotypeprop_idx2 ON phenotypeprop USING btree (type_id);

--
-- Name: phylonode_parent_phylonode_id_idx; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX phylonode_parent_phylonode_id_idx ON phylonode USING btree (parent_phylonode_id);


--
-- Name: INDEX phylotreeprop_c1; Type: COMMENT; Schema: public; Owner: chado
--

COMMENT ON INDEX phylotreeprop_c1 IS 'For any one phylotree, multivalued
property-value pairs must be differentiated by rank.';


--
-- Name: phylotreeprop_idx1; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX phylotreeprop_idx1 ON phylotreeprop USING btree (phylotree_id);


--
-- Name: phylotreeprop_idx2; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX phylotreeprop_idx2 ON phylotreeprop USING btree (type_id);


--
-- Name: project_analysis_idx1; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX project_analysis_idx1 ON project_analysis USING btree (project_id);


--
-- Name: project_analysis_idx2; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX project_analysis_idx2 ON project_analysis USING btree (analysis_id);

--
-- Name: project_dbxref_idx1; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX project_dbxref_idx1 ON project_dbxref USING btree (project_id);


--
-- Name: project_dbxref_idx2; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX project_dbxref_idx2 ON project_dbxref USING btree (dbxref_id);


--
-- Name: project_feature_idx1; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX project_feature_idx1 ON project_feature USING btree (feature_id);


--
-- Name: project_feature_idx2; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX project_feature_idx2 ON project_feature USING btree (project_id);


--
-- Name: project_stock_idx1; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX project_stock_idx1 ON project_stock USING btree (stock_id);


--
-- Name: project_stock_idx2; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX project_stock_idx2 ON project_stock USING btree (project_id);

--
-- Name: pubauthor_contact_idx1; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX pubauthor_contact_idx1 ON pubauthor USING btree (pubauthor_id);


--
-- Name: pubauthor_contact_idx2; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX pubauthor_contact_idx2 ON contact USING btree (contact_id);

--
-- Name: stock_feature_idx1; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX stock_feature_idx1 ON stock_feature USING btree (stock_feature_id);


--
-- Name: stock_feature_idx2; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX stock_feature_idx2 ON stock_feature USING btree (feature_id);


--
-- Name: stock_feature_idx3; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX stock_feature_idx3 ON stock_feature USING btree (stock_id);


--
-- Name: stock_feature_idx4; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX stock_feature_idx4 ON stock_feature USING btree (type_id);


--
-- Name: stock_featuremap_idx1; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX stock_featuremap_idx1 ON stock_featuremap USING btree (featuremap_id);


--
-- Name: stock_featuremap_idx2; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX stock_featuremap_idx2 ON stock_featuremap USING btree (stock_id);


--
-- Name: stock_featuremap_idx3; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX stock_featuremap_idx3 ON stock_featuremap USING btree (type_id);

--
-- Name: stock_library_idx1; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX stock_library_idx1 ON stock_library USING btree (library_id);


--
-- Name: stock_library_idx2; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX stock_library_idx2 ON stock_library USING btree (stock_id);

--
-- Name: stockcollection_db_idx1; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX stockcollection_db_idx1 ON stockcollection_db USING btree (stockcollection_id);


--
-- Name: stockcollection_db_idx2; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX stockcollection_db_idx2 ON stockcollection_db USING btree (db_id);


--
-- Name: analysis_cvterm_analysis_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY analysis_cvterm
    ADD CONSTRAINT analysis_cvterm_analysis_id_fkey FOREIGN KEY (analysis_id) REFERENCES analysis(analysis_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: analysis_cvterm_cvterm_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY analysis_cvterm
    ADD CONSTRAINT analysis_cvterm_cvterm_id_fkey FOREIGN KEY (cvterm_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: analysis_dbxref_analysis_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY analysis_dbxref
    ADD CONSTRAINT analysis_dbxref_analysis_id_fkey FOREIGN KEY (analysis_id) REFERENCES analysis(analysis_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: analysis_dbxref_dbxref_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY analysis_dbxref
    ADD CONSTRAINT analysis_dbxref_dbxref_id_fkey FOREIGN KEY (dbxref_id) REFERENCES dbxref(dbxref_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: analysis_pub_analysis_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY analysis_pub
    ADD CONSTRAINT analysis_pub_analysis_id_fkey FOREIGN KEY (analysis_id) REFERENCES analysis(analysis_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: analysis_pub_pub_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY analysis_pub
    ADD CONSTRAINT analysis_pub_pub_id_fkey FOREIGN KEY (pub_id) REFERENCES pub(pub_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: analysis_relationship_object_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY analysis_relationship
    ADD CONSTRAINT analysis_relationship_object_id_fkey FOREIGN KEY (object_id) REFERENCES analysis(analysis_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: analysis_relationship_subject_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY analysis_relationship
    ADD CONSTRAINT analysis_relationship_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES analysis(analysis_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: analysis_relationship_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY analysis_relationship
    ADD CONSTRAINT analysis_relationship_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

--
-- Name: contactprop_contact_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY contactprop
    ADD CONSTRAINT contactprop_contact_id_fkey FOREIGN KEY (contact_id) REFERENCES contact(contact_id) ON DELETE CASCADE;


--
-- Name: contactprop_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY contactprop
    ADD CONSTRAINT contactprop_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE;


--
-- Name: dbprop_db_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY dbprop
    ADD CONSTRAINT dbprop_db_id_fkey FOREIGN KEY (db_id) REFERENCES db(db_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: dbprop_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY dbprop
    ADD CONSTRAINT dbprop_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: feature_contact_contact_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY feature_contact
    ADD CONSTRAINT feature_contact_contact_id_fkey FOREIGN KEY (contact_id) REFERENCES contact(contact_id) ON DELETE CASCADE;


--
-- Name: feature_contact_feature_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY feature_contact
    ADD CONSTRAINT feature_contact_feature_id_fkey FOREIGN KEY (feature_id) REFERENCES feature(feature_id) ON DELETE CASCADE;

--
-- Name: featuremap_contact_contact_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY featuremap_contact
    ADD CONSTRAINT featuremap_contact_contact_id_fkey FOREIGN KEY (contact_id) REFERENCES contact(contact_id) ON DELETE CASCADE;


--
-- Name: featuremap_contact_featuremap_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY featuremap_contact
    ADD CONSTRAINT featuremap_contact_featuremap_id_fkey FOREIGN KEY (featuremap_id) REFERENCES featuremap(featuremap_id) ON DELETE CASCADE;


--
-- Name: featuremap_dbxref_dbxref_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY featuremap_dbxref
    ADD CONSTRAINT featuremap_dbxref_dbxref_id_fkey FOREIGN KEY (dbxref_id) REFERENCES dbxref(dbxref_id) ON DELETE CASCADE;


--
-- Name: featuremap_dbxref_featuremap_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY featuremap_dbxref
    ADD CONSTRAINT featuremap_dbxref_featuremap_id_fkey FOREIGN KEY (featuremap_id) REFERENCES featuremap(featuremap_id) ON DELETE CASCADE;


--
-- Name: featuremap_organism_featuremap_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY featuremap_organism
    ADD CONSTRAINT featuremap_organism_featuremap_id_fkey FOREIGN KEY (featuremap_id) REFERENCES featuremap(featuremap_id) ON DELETE CASCADE;


--
-- Name: featuremap_organism_organism_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY featuremap_organism
    ADD CONSTRAINT featuremap_organism_organism_id_fkey FOREIGN KEY (organism_id) REFERENCES organism(organism_id) ON DELETE CASCADE;

--
-- Name: featuremapprop_featuremap_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY featuremapprop
    ADD CONSTRAINT featuremapprop_featuremap_id_fkey FOREIGN KEY (featuremap_id) REFERENCES featuremap(featuremap_id) ON DELETE CASCADE;


--
-- Name: featuremapprop_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY featuremapprop
    ADD CONSTRAINT featuremapprop_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE;

--
-- Name: featureposprop_featurepos_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY featureposprop
    ADD CONSTRAINT featureposprop_featurepos_id_fkey FOREIGN KEY (featurepos_id) REFERENCES featurepos(featurepos_id) ON DELETE CASCADE;


--
-- Name: featureposprop_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY featureposprop
    ADD CONSTRAINT featureposprop_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE;


--
-- Name: library_contact_contact_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY library_contact
    ADD CONSTRAINT library_contact_contact_id_fkey FOREIGN KEY (contact_id) REFERENCES contact(contact_id) ON DELETE CASCADE;


--
-- Name: library_contact_library_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY library_contact
    ADD CONSTRAINT library_contact_library_id_fkey FOREIGN KEY (library_id) REFERENCES library(library_id) ON DELETE CASCADE;

--
-- Name: library_expression_expression_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY library_expression
    ADD CONSTRAINT library_expression_expression_id_fkey FOREIGN KEY (expression_id) REFERENCES expression(expression_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: library_expression_library_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY library_expression
    ADD CONSTRAINT library_expression_library_id_fkey FOREIGN KEY (library_id) REFERENCES library(library_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: library_expression_pub_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY library_expression
    ADD CONSTRAINT library_expression_pub_id_fkey FOREIGN KEY (pub_id) REFERENCES pub(pub_id);


--
-- Name: library_expressionprop_library_expression_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY library_expressionprop
    ADD CONSTRAINT library_expressionprop_library_expression_id_fkey FOREIGN KEY (library_expression_id) REFERENCES library_expression(library_expression_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: library_expressionprop_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY library_expressionprop
    ADD CONSTRAINT library_expressionprop_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id);


--
-- Name: library_featureprop_library_feature_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY library_featureprop
    ADD CONSTRAINT library_featureprop_library_feature_id_fkey FOREIGN KEY (library_feature_id) REFERENCES library_feature(library_feature_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: library_featureprop_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY library_featureprop
    ADD CONSTRAINT library_featureprop_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id);


--
-- Name: library_relationship_object_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY library_relationship
    ADD CONSTRAINT library_relationship_object_id_fkey FOREIGN KEY (object_id) REFERENCES library(library_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: library_relationship_pub_library_relationship_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY library_relationship_pub
    ADD CONSTRAINT library_relationship_pub_library_relationship_id_fkey FOREIGN KEY (library_relationship_id) REFERENCES library_relationship(library_relationship_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: library_relationship_pub_pub_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY library_relationship_pub
    ADD CONSTRAINT library_relationship_pub_pub_id_fkey FOREIGN KEY (pub_id) REFERENCES pub(pub_id);


--
-- Name: library_relationship_subject_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY library_relationship
    ADD CONSTRAINT library_relationship_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES library(library_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: library_relationship_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY library_relationship
    ADD CONSTRAINT library_relationship_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id);

--
-- Name: nd_experiment_analysis_analysis_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY nd_experiment_analysis
    ADD CONSTRAINT nd_experiment_analysis_analysis_id_fkey FOREIGN KEY (analysis_id) REFERENCES analysis(analysis_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: nd_experiment_analysis_nd_experiment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY nd_experiment_analysis
    ADD CONSTRAINT nd_experiment_analysis_nd_experiment_id_fkey FOREIGN KEY (nd_experiment_id) REFERENCES nd_experiment(nd_experiment_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: nd_experiment_analysis_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY nd_experiment_analysis
    ADD CONSTRAINT nd_experiment_analysis_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: nd_reagent_feature_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY nd_reagent
    ADD CONSTRAINT nd_reagent_feature_id_fkey FOREIGN KEY (feature_id) REFERENCES feature(feature_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: organism_cvterm_cvterm_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY organism_cvterm
    ADD CONSTRAINT organism_cvterm_cvterm_id_fkey FOREIGN KEY (cvterm_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: organism_cvterm_organism_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY organism_cvterm
    ADD CONSTRAINT organism_cvterm_organism_id_fkey FOREIGN KEY (organism_id) REFERENCES organism(organism_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: organism_cvterm_pub_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY organism_cvterm
    ADD CONSTRAINT organism_cvterm_pub_id_fkey FOREIGN KEY (pub_id) REFERENCES pub(pub_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: organism_cvtermprop_organism_cvterm_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY organism_cvtermprop
    ADD CONSTRAINT organism_cvtermprop_organism_cvterm_id_fkey FOREIGN KEY (organism_cvterm_id) REFERENCES organism_cvterm(organism_cvterm_id) ON DELETE CASCADE;


--
-- Name: organism_cvtermprop_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY organism_cvtermprop
    ADD CONSTRAINT organism_cvtermprop_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: organism_pub_organism_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY organism_pub
    ADD CONSTRAINT organism_pub_organism_id_fkey FOREIGN KEY (organism_id) REFERENCES organism(organism_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: organism_pub_pub_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY organism_pub
    ADD CONSTRAINT organism_pub_pub_id_fkey FOREIGN KEY (pub_id) REFERENCES pub(pub_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: organism_relationship_object_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY organism_relationship
    ADD CONSTRAINT organism_relationship_object_id_fkey FOREIGN KEY (object_id) REFERENCES organism(organism_id) ON DELETE CASCADE;


--
-- Name: organism_relationship_subject_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY organism_relationship
    ADD CONSTRAINT organism_relationship_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES organism(organism_id) ON DELETE CASCADE;


--
-- Name: organism_relationship_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY organism_relationship
    ADD CONSTRAINT organism_relationship_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE;


--
-- Name: organism_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY organism
    ADD CONSTRAINT organism_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE;

--
-- Name: organismprop_pub_organismprop_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY organismprop_pub
    ADD CONSTRAINT organismprop_pub_organismprop_id_fkey FOREIGN KEY (organismprop_id) REFERENCES organismprop(organismprop_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: organismprop_pub_pub_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY organismprop_pub
    ADD CONSTRAINT organismprop_pub_pub_id_fkey FOREIGN KEY (pub_id) REFERENCES pub(pub_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: phenotypeprop_phenotype_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY phenotypeprop
    ADD CONSTRAINT phenotypeprop_phenotype_id_fkey FOREIGN KEY (phenotype_id) REFERENCES phenotype(phenotype_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: phenotypeprop_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY phenotypeprop
    ADD CONSTRAINT phenotypeprop_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: phylotreeprop_phylotree_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY phylotreeprop
    ADD CONSTRAINT phylotreeprop_phylotree_id_fkey FOREIGN KEY (phylotree_id) REFERENCES phylotree(phylotree_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: phylotreeprop_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY phylotreeprop
    ADD CONSTRAINT phylotreeprop_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: project_analysis_analysis_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY project_analysis
    ADD CONSTRAINT project_analysis_analysis_id_fkey FOREIGN KEY (analysis_id) REFERENCES analysis(analysis_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: project_analysis_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY project_analysis
    ADD CONSTRAINT project_analysis_project_id_fkey FOREIGN KEY (project_id) REFERENCES project(project_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

--
-- Name: project_dbxref_dbxref_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY project_dbxref
    ADD CONSTRAINT project_dbxref_dbxref_id_fkey FOREIGN KEY (dbxref_id) REFERENCES dbxref(dbxref_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: project_dbxref_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY project_dbxref
    ADD CONSTRAINT project_dbxref_project_id_fkey FOREIGN KEY (project_id) REFERENCES project(project_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: project_feature_feature_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY project_feature
    ADD CONSTRAINT project_feature_feature_id_fkey FOREIGN KEY (feature_id) REFERENCES feature(feature_id) ON DELETE CASCADE;


--
-- Name: project_feature_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY project_feature
    ADD CONSTRAINT project_feature_project_id_fkey FOREIGN KEY (project_id) REFERENCES project(project_id) ON DELETE CASCADE;


--
-- Name: project_stock_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY project_stock
    ADD CONSTRAINT project_stock_project_id_fkey FOREIGN KEY (project_id) REFERENCES project(project_id) ON DELETE CASCADE;


--
-- Name: project_stock_stock_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY project_stock
    ADD CONSTRAINT project_stock_stock_id_fkey FOREIGN KEY (stock_id) REFERENCES stock(stock_id) ON DELETE CASCADE;


--
-- Name: pubauthor_contact_contact_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY pubauthor_contact
    ADD CONSTRAINT pubauthor_contact_contact_id_fkey FOREIGN KEY (contact_id) REFERENCES contact(contact_id) ON DELETE CASCADE;


--
-- Name: pubauthor_contact_pubauthor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY pubauthor_contact
    ADD CONSTRAINT pubauthor_contact_pubauthor_id_fkey FOREIGN KEY (pubauthor_id) REFERENCES pubauthor(pubauthor_id) ON DELETE CASCADE;


--
-- Name: stock_feature_feature_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY stock_feature
    ADD CONSTRAINT stock_feature_feature_id_fkey FOREIGN KEY (feature_id) REFERENCES feature(feature_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: stock_feature_stock_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY stock_feature
    ADD CONSTRAINT stock_feature_stock_id_fkey FOREIGN KEY (stock_id) REFERENCES stock(stock_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: stock_feature_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY stock_feature
    ADD CONSTRAINT stock_feature_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: stock_featuremap_featuremap_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY stock_featuremap
    ADD CONSTRAINT stock_featuremap_featuremap_id_fkey FOREIGN KEY (featuremap_id) REFERENCES featuremap(featuremap_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: stock_featuremap_stock_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY stock_featuremap
    ADD CONSTRAINT stock_featuremap_stock_id_fkey FOREIGN KEY (stock_id) REFERENCES stock(stock_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: stock_featuremap_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY stock_featuremap
    ADD CONSTRAINT stock_featuremap_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

--
-- Name: stock_library_library_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY stock_library
    ADD CONSTRAINT stock_library_library_id_fkey FOREIGN KEY (library_id) REFERENCES library(library_id) ON DELETE CASCADE;


--
-- Name: stock_library_stock_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY stock_library
    ADD CONSTRAINT stock_library_stock_id_fkey FOREIGN KEY (stock_id) REFERENCES stock(stock_id) ON DELETE CASCADE;

--
-- Name: stockcollection_db_db_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY stockcollection_db
    ADD CONSTRAINT stockcollection_db_db_id_fkey FOREIGN KEY (db_id) REFERENCES db(db_id) ON DELETE CASCADE;


--
-- Name: stockcollection_db_stockcollection_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chado
--

ALTER TABLE ONLY stockcollection_db
    ADD CONSTRAINT stockcollection_db_stockcollection_id_fkey FOREIGN KEY (stockcollection_id) REFERENCES stockcollection(stockcollection_id) ON DELETE CASCADE;


--
-- Name: binloc_boxrange; Type: INDEX; Schema: public; Owner: chado; Tablespace: 
--

CREATE INDEX binloc_boxrange ON featureloc USING gist (boxrange(fmin, fmax));
