CREATE VIEW cv_cvterm_count AS
  SELECT cv.name,count(*) AS num_terms_excl_obs FROM cv INNER JOIN cvterm USING (cv_id) WHERE is_obsolete=0 GROUP BY cv.name;
COMMENT ON VIEW cv_cvterm_count IS 'per-cv terms counts (excludes obsoletes)';

CREATE VIEW cv_cvterm_count_with_obs AS
  SELECT cv.name,count(*) AS num_terms_incl_obs FROM cv INNER JOIN cvterm USING (cv_id) GROUP BY cv.name;
COMMENT ON VIEW cv_cvterm_count_with_obs IS 'per-cv terms counts (includes obsoletes)';

CREATE VIEW cv_distinct_relations AS
 SELECT cv.name AS cv_name,
        relation.name AS relation_name,
        relation_cv.name AS relation_cv_name,
        count(*) AS num_links
 FROM cv 
  INNER JOIN cvterm ON (cvterm.cv_id=cv.cv_id) 
  INNER JOIN cvterm_relationship ON (cvterm.cvterm_id=subject_id)
  INNER JOIN cvterm AS relation ON (type_id=relation.cvterm_id)
  INNER JOIN cv AS relation_cv ON (relation.cv_id=relation_cv.cv_id) 
 GROUP BY cv.name,relation.name,relation_cv.name;

COMMENT ON VIEW cv_distinct_relations IS 'per-cv summary of number of
links (cvterm_relationships) broken down by
relationship_type. num_links is the total # of links of the specified
type in which the subject_id of the link is in the named cv';

CREATE VIEW cv_distinct_paths AS
 SELECT cv.name AS cv_name,
        relation.name AS relation_name,
        relation_cv.name AS relation_cv_name,
        count(*) AS num_paths
 FROM cv 
  INNER JOIN cvterm ON (cvterm.cv_id=cv.cv_id) 
  INNER JOIN cvtermpath ON (cvterm.cvterm_id=subject_id)
  INNER JOIN cvterm AS relation ON (type_id=relation.cvterm_id)
  INNER JOIN cv AS relation_cv ON (relation.cv_id=relation_cv.cv_id) 
 GROUP BY cv.name,relation.name,relation_cv.name;

COMMENT ON VIEW cv_distinct_paths IS 'per-cv summary of number of
paths (cvtermpaths) broken down by relationship_type. num_paths is the
total # of paths of the specified type in which the subject_id of the
path is in the named cv. See also: cv_distinct_relations';

