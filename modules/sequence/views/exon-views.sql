-- requires: so-views

CREATE OR REPLACE VIEW unshared_exon AS
 SELECT
 FROM
  exon AS exon1 INNER JOIN featureloc AS fl1 USING (feature_id),
  exon AS exon2 INNER JOIN featureloc AS fl2 USING (feature_id)
 WHERE
  exon1.feature_id != exon2.feature_id AND
  fl1.srcfeature_id = fl2.srcfeature_id AND
  fl1.fmin = fl2.fmin AND
  fl1.fmax = fl2.fmax AND
  fl1.strand = fl2.strand;
