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
SELECT feature_id, ''dbxref'' AS type, dbname || '':'' || s.accession AS attribute
FROM dbxref s, feature_dbxref fs
WHERE fs.feature_id= $1 AND fs.dbxref_id = s.dbxref_id
UNION
SELECT feature_id, ''expression'' AS type, s.description AS attribute
FROM expression s, feature_expression fs
WHERE fs.feature_id= $1 AND fs.expression_id = s.expression_id
UNION
SELECT feature_id, ''genotype'' AS type, s.description AS attribute
FROM genotype s, feature_genotype fs
WHERE fs.feature_id= $1 AND fs.genotype_id = s.genotype_id
UNION
SELECT feature_id, ''phenotype'' AS type, s.description AS attribute
FROM phenotype s, feature_phenotype fs
WHERE fs.feature_id= $1 AND fs.phenotype_id = s.phenotype_id
UNION
SELECT feature_id, ''synonym'' AS type, s.name AS attribute
FROM synonym s, feature_synonym fs
WHERE fs.feature_id= $1 AND fs.synonym_id = s.synonym_id
UNION
SELECT feature_id, ''pub'' AS type, s.series_name || '':'' || s.title AS attribute
FROM pub s, feature_pub fs
WHERE fs.feature_id= $1 AND fs.pub_id = s.pub_id
'
LANGUAGE SQL;

