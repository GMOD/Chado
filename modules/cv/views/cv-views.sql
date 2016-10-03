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
