CREATE OR REPLACE VIEW v_genepage3 
    (feature_id, field, value)
  AS
    SELECT feature_id AS feature_id, 'Name' as field, name as value FROM feature
  UNION ALL
    SELECT feature_id AS feature_id, 'uniquename' as field, uniquename as value FROM feature 
  UNION ALL
    SELECT feature_id AS feature_id, 'seqlen' as field, text('seqlen') as value FROM feature  
  UNION ALL
    SELECT f.feature_id AS feature_id, 'type' as field, c.name as value 
    FROM feature f, cvterm c  WHERE f.type_id = c.cvterm_id 
  UNION ALL
    SELECT f.feature_id AS feature_id, 'organism' as field, o.abbreviation as value  
    FROM feature f, organism o WHERE  f.organism_id = o.organism_id 
  
  UNION ALL
    SELECT fs.feature_id AS feature_id,  
      CASE WHEN fs.is_current IS FALSE THEN 'synonym_2nd' ELSE 'synonym' END AS field,
      s.name as value 
    FROM  feature_synonym fs, synonym s 
    WHERE fs.synonym_id = s.synonym_id  
  
  UNION ALL
    SELECT f.feature_id AS feature_id, 'dbxref' as field, gd.name||':'||gx.accession as value
    FROM   feature f, db gd, dbxref gx
    WHERE  f.dbxref_id = gx.dbxref_id and gx.db_id = gd.db_id  
  
  UNION ALL
    SELECT fs.feature_id AS feature_id,  
      CASE WHEN fs.is_current IS FALSE THEN 'dbxref obsolete' ELSE 'dbxref 2' END AS field, 
      (d.name || ':' || s.accession)::text AS value
    FROM  feature_dbxref fs, dbxref s, db d
    WHERE fs.dbxref_id = s.dbxref_id and s.db_id = d.db_id
  
  UNION ALL
    SELECT fc.feature_id AS feature_id, c.name AS field, 
          substr(cv.name,1,40) || '; '|| dx.accession AS value
    FROM  feature_cvterm fc, cvterm cv, cv c, dbxref dx
    WHERE fc.cvterm_id = cv.cvterm_id and cv.cv_id = c.cv_id  
          and cv.dbxref_id = dx.dbxref_id
  
  UNION ALL
    SELECT fp.feature_id AS feature_id, cv.name AS field, fp.value AS value
    FROM  featureprop fp, cvterm cv
    WHERE fp.type_id = cv.cvterm_id  
  
  UNION ALL
    SELECT fl.feature_id AS feature_id, 'location' as field, 
        chr.uniquename ||':'|| cast( fl.fmin+1 as text) ||'..'|| cast( fl.fmax as text)
        || CASE 
          WHEN fl.strand IS NULL THEN ' '
          WHEN fl.strand < 0 THEN ' [-]'
          ELSE ' [+]'
          END AS value
    FROM   featureloc fl, feature chr
    WHERE  fl.srcfeature_id = chr.feature_id 
  
  UNION ALL
    SELECT af.feature_id AS feature_id,   
     'an:' ||  
     CASE 
        WHEN a.name IS NOT NULL THEN a.name
        WHEN a.sourcename IS NOT NULL THEN (a.program || '.' || a.sourcename)::text
        ELSE a.program
      END  AS field,
      CASE  
        WHEN af.rawscore IS NOT NULL THEN cast(af.rawscore as text)
        WHEN af.normscore  IS NOT NULL  THEN cast(af.normscore  as text)
        WHEN af.significance  IS NOT NULL THEN cast(af.significance as text)
        ELSE cast(af.identity  as text)
      END  AS value 
    FROM   analysisfeature af, analysis a
    WHERE  af.analysis_id = a.analysis_id 
;
