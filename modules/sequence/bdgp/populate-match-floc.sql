--
-- the location of a parent match feature is the maximal extent
-- of the featurelocs of the child, on a per-rank basis
--
CREATE TEMPORARY TABLE floc_tmp 
 AS SELECT
        feature_relationship.object_id AS feature_id,
        featureloc.rank                AS rank,
        min(featureloc.fmin) AS fmin,
        max(featureloc.fmax) AS fmax,
        min(featureloc.strand) AS strandmin,
        max(featureloc.strand) AS strandmax
 FROM        feature
  INNER JOIN featureloc           USING (feature_id)
  INNER JOIN feature_relationship ON (featureloc.feature_id=subject_id)
 WHERE feature.type_id IN 
                (SELECT cvterm_id 
                 FROM cvterm
                 WHERE name='match')
       AND locgroup = 0
 GROUP BY feature_relationship.object_id, featureloc.rank;

--
-- how do we treat child features on varying strands?
-- we can either insert consistent-only or insert all

-- OPTION 1
INSERT INTO featureloc
 (feature_id,rank,fmin,fmax,strand)
 SELECT 
  feature_id,rank,fmin,fmax,strandmin
 FROM floc_tmp
 WHERE strandmin = strandmax
 ORDER BY feature_id,rank;

-- OPTION 2
-- just choose strand 1; or should it be strand 0?
INSERT INTO featureloc
 (feature_id,rank,fmin,fmax,strand)
 SELECT 
  feature_id,rank,fmin,fmax,1
 FROM floc_tmp
 ORDER BY feature_id,rank;

-- report inconsistent;
-- perhaps we actually want to include these, with arbitrary strand?
SELECT count(feature_id) FROM floc_tmp WHERE strandmin != strandmax;
SELECT feature_id FROM floc_tmp WHERE strandmin != strandmax;

