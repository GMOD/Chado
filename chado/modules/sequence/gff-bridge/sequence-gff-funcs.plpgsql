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
UNION
SELECT fg.feature_id, ''genotype'' AS type, g.uniquename||'': ''||g.description AS attribute
FROM gcontext g, feature_gcontext fg
WHERE fg.feature_id= $1 AND g.gcontext_id = fg.gcontext_id
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
CREATE OR REPLACE FUNCTION p (int, int) RETURNS point AS
 'SELECT point ($1, $2)'
LANGUAGE 'sql';

-- create a range box
-- (make this immutable so we can index it)
CREATE OR REPLACE FUNCTION boxrange (int, int) RETURNS box AS
 'SELECT box (p(0, $1), p($2,500000000))'
LANGUAGE 'sql' IMMUTABLE;

-- create a query box
CREATE OR REPLACE FUNCTION boxquery (int, int) RETURNS box AS
 'SELECT box (p($1, $2), p($1, $2))'
LANGUAGE 'sql' IMMUTABLE;

CREATE OR REPLACE FUNCTION featureslice(int, int) RETURNS setof featureloc AS
  'SELECT * from featureloc where boxquery($1, $2) @ boxrange(fmin,fmax)'
LANGUAGE 'sql';

--functional index that depends on the above functions
CREATE INDEX binloc_boxrange ON featureloc USING RTREE (boxrange(fmin, fmax));

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
    return_string = return_string || '';''
                     || atts_view.type || ''=''
                     || atts_view.attribute;
  END LOOP;
                                                                                
  RETURN return_string;
END;
'
LANGUAGE plpgsql;

--creates a view that is suitable for creating a GFF3 string
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
  attributes,
  seqlen,
  name
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
  gffattstring(f.feature_id),
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

