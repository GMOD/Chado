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

