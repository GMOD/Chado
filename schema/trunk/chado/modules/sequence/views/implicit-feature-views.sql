-- introns are implicit from surrounding exons
-- combines intron features with location and parent transcript
-- the same intron appearing in multiple transcripts will appear
-- multiple times
CREATE VIEW intron_combined_view AS
 SELECT
  x1.feature_id         AS exon1_id,
  x2.feature_id         AS exon2_id,
  CASE WHEN l1.strand=-1  THEN l2.fmax ELSE l1.fmax END AS fmin,
  CASE WHEN l1.strand=-1  THEN l1.fmin ELSE l2.fmin END AS fmax,
  l1.strand             AS strand,
  l1.srcfeature_id      AS srcfeature_id,
  r1.rank               AS intron_rank,
  r1.object_id          AS transcript_id
 FROM
 cvterm
  INNER JOIN 
   feature                AS x1    ON (x1.type_id=cvterm.cvterm_id)
    INNER JOIN
     feature_relationship AS r1    ON (x1.feature_id=r1.subject_id)
    INNER JOIN
     featureloc           AS l1    ON (x1.feature_id=l1.feature_id)
  INNER JOIN
   feature                AS x2    ON (x2.type_id=cvterm.cvterm_id)
    INNER JOIN
     feature_relationship AS r2    ON (x2.feature_id=r2.subject_id)
    INNER JOIN
     featureloc           AS l2    ON (x2.feature_id=l2.feature_id)
 WHERE
  cvterm.name='exon'            AND
  (r2.rank - r1.rank) = 1       AND
  r1.object_id=r2.object_id     AND
  l1.strand = l2.strand         AND
  l1.srcfeature_id = l2.srcfeature_id         AND
  l1.locgroup=0                 AND
  l2.locgroup=0;

-- intron locations. intron IDs are the (exon1,exon2) ID pair
-- this means that introns may be counted twice if the start of
-- the 5' exon or the end of the 3' exon vary
-- introns shared by transcripts will not appear twice
CREATE VIEW intronloc_view AS
 SELECT DISTINCT
  exon1_id,
  exon2_id,
  fmin,
  fmax,
  strand,
  srcfeature_id
 FROM intron_combined_view;
