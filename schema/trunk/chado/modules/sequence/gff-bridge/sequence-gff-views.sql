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
      CASE WHEN db.name like '%Gene Ontology%'    THEN 'GO:'|| dbx.accession
           WHEN db.name like 'Sequence Ontology%' THEN 'SO:'|| dbx.accession
           ELSE                            CAST(db.name||':'|| dbx.accession AS varchar)
      END 
FROM cvterm s, dbxref dbx, feature_cvterm fs, db
WHERE fs.cvterm_id = s.cvterm_id and s.dbxref_id=dbx.dbxref_id and
      db.db_id = dbx.db_id 
UNION ALL
SELECT feature_id, 'Dbxref' AS type, d.name || ':' || s.accession AS
attribute
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
SELECT feature_id, 'pub' AS type, s.series_name || ':' || s.title AS
attribute
FROM pub s, feature_pub fs
WHERE fs.pub_id = s.pub_id
UNION ALL
SELECT fr.subject_id as feature_id, 'Parent' as type,  parent.uniquename
as attribute
FROM feature_relationship fr, feature parent
WHERE  fr.object_id=parent.feature_id AND fr.type_id = (SELECT cvterm_id
FROM cvterm WHERE name='part_of' and cv_id in (select cv_id
  FROM cv WHERE name='relationship'))
UNION ALL
SELECT fr.subject_id as feature_id, 'Derives_from' as type,
parent.uniquename as attribute
FROM feature_relationship fr, feature parent
WHERE  fr.object_id=parent.feature_id AND fr.type_id = (SELECT cvterm_id
FROM cvterm WHERE name='derives_from' and cv_id in (select cv_id
  FROM cv WHERE name='relationship'))
UNION ALL
SELECT fl.feature_id, 'Target' as type, target.name || ' ' || fl.fmin+1
|| ' ' || fl.fmax || ' ' || fl.strand as attribute
FROM featureloc fl, feature target
WHERE fl.srcfeature_id=target.feature_id
        AND fl.rank != 0
UNION ALL
SELECT feature_id, 'ID' as type, uniquename as attribute
FROM feature
WHERE type_id NOT IN (SELECT cvterm_id FROM cvterm WHERE name='CDS')
UNION ALL
SELECT feature_id, 'chado_feature_id' as type, CAST(feature_id AS
varchar) as attribute
FROM feature
UNION ALL
SELECT feature_id, 'Name' as type, name as attribute
FROM feature;


--replaced with Rob B's improved view
CREATE OR REPLACE VIEW gff3view (
feature_id, ref, source, type, fstart, fend,
score, strand, phase, seqlen, name, organism_id
) AS
SELECT
f.feature_id, sf.name, gffdbx.accession, cv.name,
fl.fmin+1, fl.fmax, af.significance,
 CASE WHEN fl.strand=-1 THEN '-'
      WHEN fl.strand=1  THEN '+'
      ELSE '.'
 END,
fl.phase, f.seqlen, f.name, f.organism_id
FROM feature f
LEFT JOIN featureloc fl ON (f.feature_id = fl.feature_id)
LEFT JOIN feature sf ON (fl.srcfeature_id = sf.feature_id)
LEFT JOIN ( SELECT fd.feature_id, d.accession
FROM feature_dbxref fd
JOIN dbxref d using(dbxref_id)
JOIN db using(db_id)
WHERE db.name = 'GFF_source'
) as gffdbx
ON (f.feature_id=gffdbx.feature_id)
LEFT JOIN cvterm cv ON (f.type_id = cv.cvterm_id)
LEFT JOIN analysisfeature af ON (f.feature_id = af.feature_id);

