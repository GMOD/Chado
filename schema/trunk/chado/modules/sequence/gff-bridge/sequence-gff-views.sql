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
UNION ALL
SELECT feature_id, 'expression' AS type, s.description AS attribute
FROM expression s, feature_expression fs
WHERE fs.expression_id = s.expression_id
UNION ALL
SELECT feature_id, 'genotype' AS type, s.description AS attribute
FROM genotype s, feature_genotype fs
WHERE fs.genotype_id = s.genotype_id
UNION ALL
SELECT feature_id, 'phenotype' AS type, s.description AS attribute
FROM phenotype s, feature_phenotype fs
WHERE fs.phenotype_id = s.phenotype_id
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

