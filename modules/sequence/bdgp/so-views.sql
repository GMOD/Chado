--- ************************************************
--- *** relation: so                             ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology 'Typed Feature' View   ***
--- ***                                          ***
--- ************************************************
---
--- SO Term:
--- "so"

CREATE VIEW so AS
  SELECT
    feature_id AS so_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'so';

--- ************************************************
--- *** relation: so_pair                        ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Pair View      ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "so"
CREATE VIEW so_pair AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    so1.feature_id AS feature_id1,
    so1.dbxref_id AS dbxref_id1,
    so1.organism_id AS organism_id1,
    so1.name AS name1,
    so1.uniquename AS uniquename1,
    so1.residues AS residues1,
    so1.seqlen AS seqlen1,
    so1.md5checksum AS md5checksum1,
    so1.type_id AS type_id1,
    so1.is_analysis AS is_analysis1,
    so1.timeaccessioned AS timeaccessioned1,
    so1.timelastmodified AS timelastmodified1,
    so2.feature_id AS feature_id2,
    so2.dbxref_id AS dbxref_id2,
    so2.organism_id AS organism_id2,
    so2.name AS name2,
    so2.uniquename AS uniquename2,
    so2.residues AS residues2,
    so2.seqlen AS seqlen2,
    so2.md5checksum AS md5checksum2,
    so2.type_id AS type_id2,
    so2.is_analysis AS is_analysis2,
    so2.timeaccessioned AS timeaccessioned2,
    so2.timelastmodified AS timelastmodified2
  FROM
    so AS so1 INNER JOIN
    feature_relationship AS fr1 ON (so1.so_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    so AS so2 ON (so1.so_id = fr2.subject_id);


--- ************************************************
--- *** relation: so_invpair                     ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "so"
CREATE VIEW so_invpair AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    so1.feature_id AS feature_id1,
    so1.dbxref_id AS dbxref_id1,
    so1.organism_id AS organism_id1,
    so1.name AS name1,
    so1.uniquename AS uniquename1,
    so1.residues AS residues1,
    so1.seqlen AS seqlen1,
    so1.md5checksum AS md5checksum1,
    so1.type_id AS type_id1,
    so1.is_analysis AS is_analysis1,
    so1.timeaccessioned AS timeaccessioned1,
    so1.timelastmodified AS timelastmodified1,
    so2.feature_id AS feature_id2,
    so2.dbxref_id AS dbxref_id2,
    so2.organism_id AS organism_id2,
    so2.name AS name2,
    so2.uniquename AS uniquename2,
    so2.residues AS residues2,
    so2.seqlen AS seqlen2,
    so2.md5checksum AS md5checksum2,
    so2.type_id AS type_id2,
    so2.is_analysis AS is_analysis2,
    so2.timeaccessioned AS timeaccessioned2,
    so2.timelastmodified AS timelastmodified2
  FROM
    so AS so1 INNER JOIN
    feature_relationship AS fr1 ON (so1.so_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    so AS so2 ON (so1.so_id = fr2.object_id);


--- ************************************************
--- *** relation: te                             ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology 'Typed Feature' View   ***
--- ***                                          ***
--- ************************************************
---
--- SO Term:
--- "transposable_element"

CREATE VIEW te AS
  SELECT
    feature_id AS te_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'transposable_element';

--- ************************************************
--- *** relation: te_pair                        ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Pair View      ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "transposable_element"
CREATE VIEW te_pair AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    te1.feature_id AS feature_id1,
    te1.dbxref_id AS dbxref_id1,
    te1.organism_id AS organism_id1,
    te1.name AS name1,
    te1.uniquename AS uniquename1,
    te1.residues AS residues1,
    te1.seqlen AS seqlen1,
    te1.md5checksum AS md5checksum1,
    te1.type_id AS type_id1,
    te1.is_analysis AS is_analysis1,
    te1.timeaccessioned AS timeaccessioned1,
    te1.timelastmodified AS timelastmodified1,
    te2.feature_id AS feature_id2,
    te2.dbxref_id AS dbxref_id2,
    te2.organism_id AS organism_id2,
    te2.name AS name2,
    te2.uniquename AS uniquename2,
    te2.residues AS residues2,
    te2.seqlen AS seqlen2,
    te2.md5checksum AS md5checksum2,
    te2.type_id AS type_id2,
    te2.is_analysis AS is_analysis2,
    te2.timeaccessioned AS timeaccessioned2,
    te2.timelastmodified AS timelastmodified2
  FROM
    te AS te1 INNER JOIN
    feature_relationship AS fr1 ON (te1.te_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    te AS te2 ON (te1.te_id = fr2.subject_id);


--- ************************************************
--- *** relation: te_invpair                     ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "transposable_element"
CREATE VIEW te_invpair AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    te1.feature_id AS feature_id1,
    te1.dbxref_id AS dbxref_id1,
    te1.organism_id AS organism_id1,
    te1.name AS name1,
    te1.uniquename AS uniquename1,
    te1.residues AS residues1,
    te1.seqlen AS seqlen1,
    te1.md5checksum AS md5checksum1,
    te1.type_id AS type_id1,
    te1.is_analysis AS is_analysis1,
    te1.timeaccessioned AS timeaccessioned1,
    te1.timelastmodified AS timelastmodified1,
    te2.feature_id AS feature_id2,
    te2.dbxref_id AS dbxref_id2,
    te2.organism_id AS organism_id2,
    te2.name AS name2,
    te2.uniquename AS uniquename2,
    te2.residues AS residues2,
    te2.seqlen AS seqlen2,
    te2.md5checksum AS md5checksum2,
    te2.type_id AS type_id2,
    te2.is_analysis AS is_analysis2,
    te2.timeaccessioned AS timeaccessioned2,
    te2.timelastmodified AS timelastmodified2
  FROM
    te AS te1 INNER JOIN
    feature_relationship AS fr1 ON (te1.te_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    te AS te2 ON (te1.te_id = fr2.object_id);


--- ************************************************
--- *** relation: chromosome_arm                 ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology 'Typed Feature' View   ***
--- ***                                          ***
--- ************************************************
---
--- SO Term:
--- "chromosome_arm"

CREATE VIEW chromosome_arm AS
  SELECT
    feature_id AS chromosome_arm_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'chromosome_arm';

--- ************************************************
--- *** relation: chromosome_arm_pair            ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Pair View      ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "chromosome_arm"
CREATE VIEW chromosome_arm_pair AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    chromosome_arm1.feature_id AS feature_id1,
    chromosome_arm1.dbxref_id AS dbxref_id1,
    chromosome_arm1.organism_id AS organism_id1,
    chromosome_arm1.name AS name1,
    chromosome_arm1.uniquename AS uniquename1,
    chromosome_arm1.residues AS residues1,
    chromosome_arm1.seqlen AS seqlen1,
    chromosome_arm1.md5checksum AS md5checksum1,
    chromosome_arm1.type_id AS type_id1,
    chromosome_arm1.is_analysis AS is_analysis1,
    chromosome_arm1.timeaccessioned AS timeaccessioned1,
    chromosome_arm1.timelastmodified AS timelastmodified1,
    chromosome_arm2.feature_id AS feature_id2,
    chromosome_arm2.dbxref_id AS dbxref_id2,
    chromosome_arm2.organism_id AS organism_id2,
    chromosome_arm2.name AS name2,
    chromosome_arm2.uniquename AS uniquename2,
    chromosome_arm2.residues AS residues2,
    chromosome_arm2.seqlen AS seqlen2,
    chromosome_arm2.md5checksum AS md5checksum2,
    chromosome_arm2.type_id AS type_id2,
    chromosome_arm2.is_analysis AS is_analysis2,
    chromosome_arm2.timeaccessioned AS timeaccessioned2,
    chromosome_arm2.timelastmodified AS timelastmodified2
  FROM
    chromosome_arm AS chromosome_arm1 INNER JOIN
    feature_relationship AS fr1 ON (chromosome_arm1.chromosome_arm_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    chromosome_arm AS chromosome_arm2 ON (chromosome_arm1.chromosome_arm_id = fr2.subject_id);


--- ************************************************
--- *** relation: chromosome_arm_invpair         ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "chromosome_arm"
CREATE VIEW chromosome_arm_invpair AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    chromosome_arm1.feature_id AS feature_id1,
    chromosome_arm1.dbxref_id AS dbxref_id1,
    chromosome_arm1.organism_id AS organism_id1,
    chromosome_arm1.name AS name1,
    chromosome_arm1.uniquename AS uniquename1,
    chromosome_arm1.residues AS residues1,
    chromosome_arm1.seqlen AS seqlen1,
    chromosome_arm1.md5checksum AS md5checksum1,
    chromosome_arm1.type_id AS type_id1,
    chromosome_arm1.is_analysis AS is_analysis1,
    chromosome_arm1.timeaccessioned AS timeaccessioned1,
    chromosome_arm1.timelastmodified AS timelastmodified1,
    chromosome_arm2.feature_id AS feature_id2,
    chromosome_arm2.dbxref_id AS dbxref_id2,
    chromosome_arm2.organism_id AS organism_id2,
    chromosome_arm2.name AS name2,
    chromosome_arm2.uniquename AS uniquename2,
    chromosome_arm2.residues AS residues2,
    chromosome_arm2.seqlen AS seqlen2,
    chromosome_arm2.md5checksum AS md5checksum2,
    chromosome_arm2.type_id AS type_id2,
    chromosome_arm2.is_analysis AS is_analysis2,
    chromosome_arm2.timeaccessioned AS timeaccessioned2,
    chromosome_arm2.timelastmodified AS timelastmodified2
  FROM
    chromosome_arm AS chromosome_arm1 INNER JOIN
    feature_relationship AS fr1 ON (chromosome_arm1.chromosome_arm_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    chromosome_arm AS chromosome_arm2 ON (chromosome_arm1.chromosome_arm_id = fr2.object_id);


--- ************************************************
--- *** relation: chromosome_band                ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology 'Typed Feature' View   ***
--- ***                                          ***
--- ************************************************
---
--- SO Term:
--- "chromosome_band"

CREATE VIEW chromosome_band AS
  SELECT
    feature_id AS chromosome_band_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'chromosome_band';

--- ************************************************
--- *** relation: chromosome_band_pair           ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Pair View      ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "chromosome_band"
CREATE VIEW chromosome_band_pair AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    chromosome_band1.feature_id AS feature_id1,
    chromosome_band1.dbxref_id AS dbxref_id1,
    chromosome_band1.organism_id AS organism_id1,
    chromosome_band1.name AS name1,
    chromosome_band1.uniquename AS uniquename1,
    chromosome_band1.residues AS residues1,
    chromosome_band1.seqlen AS seqlen1,
    chromosome_band1.md5checksum AS md5checksum1,
    chromosome_band1.type_id AS type_id1,
    chromosome_band1.is_analysis AS is_analysis1,
    chromosome_band1.timeaccessioned AS timeaccessioned1,
    chromosome_band1.timelastmodified AS timelastmodified1,
    chromosome_band2.feature_id AS feature_id2,
    chromosome_band2.dbxref_id AS dbxref_id2,
    chromosome_band2.organism_id AS organism_id2,
    chromosome_band2.name AS name2,
    chromosome_band2.uniquename AS uniquename2,
    chromosome_band2.residues AS residues2,
    chromosome_band2.seqlen AS seqlen2,
    chromosome_band2.md5checksum AS md5checksum2,
    chromosome_band2.type_id AS type_id2,
    chromosome_band2.is_analysis AS is_analysis2,
    chromosome_band2.timeaccessioned AS timeaccessioned2,
    chromosome_band2.timelastmodified AS timelastmodified2
  FROM
    chromosome_band AS chromosome_band1 INNER JOIN
    feature_relationship AS fr1 ON (chromosome_band1.chromosome_band_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    chromosome_band AS chromosome_band2 ON (chromosome_band1.chromosome_band_id = fr2.subject_id);


--- ************************************************
--- *** relation: chromosome_band_invpair        ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "chromosome_band"
CREATE VIEW chromosome_band_invpair AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    chromosome_band1.feature_id AS feature_id1,
    chromosome_band1.dbxref_id AS dbxref_id1,
    chromosome_band1.organism_id AS organism_id1,
    chromosome_band1.name AS name1,
    chromosome_band1.uniquename AS uniquename1,
    chromosome_band1.residues AS residues1,
    chromosome_band1.seqlen AS seqlen1,
    chromosome_band1.md5checksum AS md5checksum1,
    chromosome_band1.type_id AS type_id1,
    chromosome_band1.is_analysis AS is_analysis1,
    chromosome_band1.timeaccessioned AS timeaccessioned1,
    chromosome_band1.timelastmodified AS timelastmodified1,
    chromosome_band2.feature_id AS feature_id2,
    chromosome_band2.dbxref_id AS dbxref_id2,
    chromosome_band2.organism_id AS organism_id2,
    chromosome_band2.name AS name2,
    chromosome_band2.uniquename AS uniquename2,
    chromosome_band2.residues AS residues2,
    chromosome_band2.seqlen AS seqlen2,
    chromosome_band2.md5checksum AS md5checksum2,
    chromosome_band2.type_id AS type_id2,
    chromosome_band2.is_analysis AS is_analysis2,
    chromosome_band2.timeaccessioned AS timeaccessioned2,
    chromosome_band2.timelastmodified AS timelastmodified2
  FROM
    chromosome_band AS chromosome_band1 INNER JOIN
    feature_relationship AS fr1 ON (chromosome_band1.chromosome_band_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    chromosome_band AS chromosome_band2 ON (chromosome_band1.chromosome_band_id = fr2.object_id);


--- ************************************************
--- *** relation: gene                           ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology 'Typed Feature' View   ***
--- ***                                          ***
--- ************************************************
---
--- SO Term:
--- "gene"

CREATE VIEW gene AS
  SELECT
    feature_id AS gene_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'gene';

--- ************************************************
--- *** relation: gene_pair                      ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Pair View      ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "gene"
CREATE VIEW gene_pair AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    gene1.feature_id AS feature_id1,
    gene1.dbxref_id AS dbxref_id1,
    gene1.organism_id AS organism_id1,
    gene1.name AS name1,
    gene1.uniquename AS uniquename1,
    gene1.residues AS residues1,
    gene1.seqlen AS seqlen1,
    gene1.md5checksum AS md5checksum1,
    gene1.type_id AS type_id1,
    gene1.is_analysis AS is_analysis1,
    gene1.timeaccessioned AS timeaccessioned1,
    gene1.timelastmodified AS timelastmodified1,
    gene2.feature_id AS feature_id2,
    gene2.dbxref_id AS dbxref_id2,
    gene2.organism_id AS organism_id2,
    gene2.name AS name2,
    gene2.uniquename AS uniquename2,
    gene2.residues AS residues2,
    gene2.seqlen AS seqlen2,
    gene2.md5checksum AS md5checksum2,
    gene2.type_id AS type_id2,
    gene2.is_analysis AS is_analysis2,
    gene2.timeaccessioned AS timeaccessioned2,
    gene2.timelastmodified AS timelastmodified2
  FROM
    gene AS gene1 INNER JOIN
    feature_relationship AS fr1 ON (gene1.gene_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    gene AS gene2 ON (gene1.gene_id = fr2.subject_id);


--- ************************************************
--- *** relation: gene_invpair                   ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "gene"
CREATE VIEW gene_invpair AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    gene1.feature_id AS feature_id1,
    gene1.dbxref_id AS dbxref_id1,
    gene1.organism_id AS organism_id1,
    gene1.name AS name1,
    gene1.uniquename AS uniquename1,
    gene1.residues AS residues1,
    gene1.seqlen AS seqlen1,
    gene1.md5checksum AS md5checksum1,
    gene1.type_id AS type_id1,
    gene1.is_analysis AS is_analysis1,
    gene1.timeaccessioned AS timeaccessioned1,
    gene1.timelastmodified AS timelastmodified1,
    gene2.feature_id AS feature_id2,
    gene2.dbxref_id AS dbxref_id2,
    gene2.organism_id AS organism_id2,
    gene2.name AS name2,
    gene2.uniquename AS uniquename2,
    gene2.residues AS residues2,
    gene2.seqlen AS seqlen2,
    gene2.md5checksum AS md5checksum2,
    gene2.type_id AS type_id2,
    gene2.is_analysis AS is_analysis2,
    gene2.timeaccessioned AS timeaccessioned2,
    gene2.timelastmodified AS timelastmodified2
  FROM
    gene AS gene1 INNER JOIN
    feature_relationship AS fr1 ON (gene1.gene_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    gene AS gene2 ON (gene1.gene_id = fr2.object_id);


--- ************************************************
--- *** relation: est                            ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology 'Typed Feature' View   ***
--- ***                                          ***
--- ************************************************
---
--- SO Term:
--- "EST"

CREATE VIEW est AS
  SELECT
    feature_id AS est_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'EST';

--- ************************************************
--- *** relation: est_pair                       ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Pair View      ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "EST"
CREATE VIEW est_pair AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    est1.feature_id AS feature_id1,
    est1.dbxref_id AS dbxref_id1,
    est1.organism_id AS organism_id1,
    est1.name AS name1,
    est1.uniquename AS uniquename1,
    est1.residues AS residues1,
    est1.seqlen AS seqlen1,
    est1.md5checksum AS md5checksum1,
    est1.type_id AS type_id1,
    est1.is_analysis AS is_analysis1,
    est1.timeaccessioned AS timeaccessioned1,
    est1.timelastmodified AS timelastmodified1,
    est2.feature_id AS feature_id2,
    est2.dbxref_id AS dbxref_id2,
    est2.organism_id AS organism_id2,
    est2.name AS name2,
    est2.uniquename AS uniquename2,
    est2.residues AS residues2,
    est2.seqlen AS seqlen2,
    est2.md5checksum AS md5checksum2,
    est2.type_id AS type_id2,
    est2.is_analysis AS is_analysis2,
    est2.timeaccessioned AS timeaccessioned2,
    est2.timelastmodified AS timelastmodified2
  FROM
    est AS est1 INNER JOIN
    feature_relationship AS fr1 ON (est1.est_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    est AS est2 ON (est1.est_id = fr2.subject_id);


--- ************************************************
--- *** relation: est_invpair                    ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "EST"
CREATE VIEW est_invpair AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    est1.feature_id AS feature_id1,
    est1.dbxref_id AS dbxref_id1,
    est1.organism_id AS organism_id1,
    est1.name AS name1,
    est1.uniquename AS uniquename1,
    est1.residues AS residues1,
    est1.seqlen AS seqlen1,
    est1.md5checksum AS md5checksum1,
    est1.type_id AS type_id1,
    est1.is_analysis AS is_analysis1,
    est1.timeaccessioned AS timeaccessioned1,
    est1.timelastmodified AS timelastmodified1,
    est2.feature_id AS feature_id2,
    est2.dbxref_id AS dbxref_id2,
    est2.organism_id AS organism_id2,
    est2.name AS name2,
    est2.uniquename AS uniquename2,
    est2.residues AS residues2,
    est2.seqlen AS seqlen2,
    est2.md5checksum AS md5checksum2,
    est2.type_id AS type_id2,
    est2.is_analysis AS is_analysis2,
    est2.timeaccessioned AS timeaccessioned2,
    est2.timelastmodified AS timelastmodified2
  FROM
    est AS est1 INNER JOIN
    feature_relationship AS fr1 ON (est1.est_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    est AS est2 ON (est1.est_id = fr2.object_id);


--- ************************************************
--- *** relation: exon                           ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology 'Typed Feature' View   ***
--- ***                                          ***
--- ************************************************
---
--- SO Term:
--- "exon"

CREATE VIEW exon AS
  SELECT
    feature_id AS exon_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'exon';

--- ************************************************
--- *** relation: exon_pair                      ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Pair View      ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "exon"
CREATE VIEW exon_pair AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    exon1.feature_id AS feature_id1,
    exon1.dbxref_id AS dbxref_id1,
    exon1.organism_id AS organism_id1,
    exon1.name AS name1,
    exon1.uniquename AS uniquename1,
    exon1.residues AS residues1,
    exon1.seqlen AS seqlen1,
    exon1.md5checksum AS md5checksum1,
    exon1.type_id AS type_id1,
    exon1.is_analysis AS is_analysis1,
    exon1.timeaccessioned AS timeaccessioned1,
    exon1.timelastmodified AS timelastmodified1,
    exon2.feature_id AS feature_id2,
    exon2.dbxref_id AS dbxref_id2,
    exon2.organism_id AS organism_id2,
    exon2.name AS name2,
    exon2.uniquename AS uniquename2,
    exon2.residues AS residues2,
    exon2.seqlen AS seqlen2,
    exon2.md5checksum AS md5checksum2,
    exon2.type_id AS type_id2,
    exon2.is_analysis AS is_analysis2,
    exon2.timeaccessioned AS timeaccessioned2,
    exon2.timelastmodified AS timelastmodified2
  FROM
    exon AS exon1 INNER JOIN
    feature_relationship AS fr1 ON (exon1.exon_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    exon AS exon2 ON (exon1.exon_id = fr2.subject_id);


--- ************************************************
--- *** relation: exon_invpair                   ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "exon"
CREATE VIEW exon_invpair AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    exon1.feature_id AS feature_id1,
    exon1.dbxref_id AS dbxref_id1,
    exon1.organism_id AS organism_id1,
    exon1.name AS name1,
    exon1.uniquename AS uniquename1,
    exon1.residues AS residues1,
    exon1.seqlen AS seqlen1,
    exon1.md5checksum AS md5checksum1,
    exon1.type_id AS type_id1,
    exon1.is_analysis AS is_analysis1,
    exon1.timeaccessioned AS timeaccessioned1,
    exon1.timelastmodified AS timelastmodified1,
    exon2.feature_id AS feature_id2,
    exon2.dbxref_id AS dbxref_id2,
    exon2.organism_id AS organism_id2,
    exon2.name AS name2,
    exon2.uniquename AS uniquename2,
    exon2.residues AS residues2,
    exon2.seqlen AS seqlen2,
    exon2.md5checksum AS md5checksum2,
    exon2.type_id AS type_id2,
    exon2.is_analysis AS is_analysis2,
    exon2.timeaccessioned AS timeaccessioned2,
    exon2.timelastmodified AS timelastmodified2
  FROM
    exon AS exon1 INNER JOIN
    feature_relationship AS fr1 ON (exon1.exon_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    exon AS exon2 ON (exon1.exon_id = fr2.object_id);


--- ************************************************
--- *** relation: t_start_site                   ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology 'Typed Feature' View   ***
--- ***                                          ***
--- ************************************************
---
--- SO Term:
--- "transcription_start_site"

CREATE VIEW t_start_site AS
  SELECT
    feature_id AS t_start_site_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'transcription_start_site';

--- ************************************************
--- *** relation: t_start_site_pair              ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Pair View      ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "transcription_start_site"
CREATE VIEW t_start_site_pair AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    t_start_site1.feature_id AS feature_id1,
    t_start_site1.dbxref_id AS dbxref_id1,
    t_start_site1.organism_id AS organism_id1,
    t_start_site1.name AS name1,
    t_start_site1.uniquename AS uniquename1,
    t_start_site1.residues AS residues1,
    t_start_site1.seqlen AS seqlen1,
    t_start_site1.md5checksum AS md5checksum1,
    t_start_site1.type_id AS type_id1,
    t_start_site1.is_analysis AS is_analysis1,
    t_start_site1.timeaccessioned AS timeaccessioned1,
    t_start_site1.timelastmodified AS timelastmodified1,
    t_start_site2.feature_id AS feature_id2,
    t_start_site2.dbxref_id AS dbxref_id2,
    t_start_site2.organism_id AS organism_id2,
    t_start_site2.name AS name2,
    t_start_site2.uniquename AS uniquename2,
    t_start_site2.residues AS residues2,
    t_start_site2.seqlen AS seqlen2,
    t_start_site2.md5checksum AS md5checksum2,
    t_start_site2.type_id AS type_id2,
    t_start_site2.is_analysis AS is_analysis2,
    t_start_site2.timeaccessioned AS timeaccessioned2,
    t_start_site2.timelastmodified AS timelastmodified2
  FROM
    t_start_site AS t_start_site1 INNER JOIN
    feature_relationship AS fr1 ON (t_start_site1.t_start_site_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    t_start_site AS t_start_site2 ON (t_start_site1.t_start_site_id = fr2.subject_id);


--- ************************************************
--- *** relation: t_start_site_invpair           ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "transcription_start_site"
CREATE VIEW t_start_site_invpair AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    t_start_site1.feature_id AS feature_id1,
    t_start_site1.dbxref_id AS dbxref_id1,
    t_start_site1.organism_id AS organism_id1,
    t_start_site1.name AS name1,
    t_start_site1.uniquename AS uniquename1,
    t_start_site1.residues AS residues1,
    t_start_site1.seqlen AS seqlen1,
    t_start_site1.md5checksum AS md5checksum1,
    t_start_site1.type_id AS type_id1,
    t_start_site1.is_analysis AS is_analysis1,
    t_start_site1.timeaccessioned AS timeaccessioned1,
    t_start_site1.timelastmodified AS timelastmodified1,
    t_start_site2.feature_id AS feature_id2,
    t_start_site2.dbxref_id AS dbxref_id2,
    t_start_site2.organism_id AS organism_id2,
    t_start_site2.name AS name2,
    t_start_site2.uniquename AS uniquename2,
    t_start_site2.residues AS residues2,
    t_start_site2.seqlen AS seqlen2,
    t_start_site2.md5checksum AS md5checksum2,
    t_start_site2.type_id AS type_id2,
    t_start_site2.is_analysis AS is_analysis2,
    t_start_site2.timeaccessioned AS timeaccessioned2,
    t_start_site2.timelastmodified AS timelastmodified2
  FROM
    t_start_site AS t_start_site1 INNER JOIN
    feature_relationship AS fr1 ON (t_start_site1.t_start_site_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    t_start_site AS t_start_site2 ON (t_start_site1.t_start_site_id = fr2.object_id);


--- ************************************************
--- *** relation: p_transcript                   ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology 'Typed Feature' View   ***
--- ***                                          ***
--- ************************************************
---
--- SO Term:
--- "processed_transcript"

CREATE VIEW p_transcript AS
  SELECT
    feature_id AS p_transcript_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'processed_transcript';

--- ************************************************
--- *** relation: p_transcript_pair              ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Pair View      ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "processed_transcript"
CREATE VIEW p_transcript_pair AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    p_transcript1.feature_id AS feature_id1,
    p_transcript1.dbxref_id AS dbxref_id1,
    p_transcript1.organism_id AS organism_id1,
    p_transcript1.name AS name1,
    p_transcript1.uniquename AS uniquename1,
    p_transcript1.residues AS residues1,
    p_transcript1.seqlen AS seqlen1,
    p_transcript1.md5checksum AS md5checksum1,
    p_transcript1.type_id AS type_id1,
    p_transcript1.is_analysis AS is_analysis1,
    p_transcript1.timeaccessioned AS timeaccessioned1,
    p_transcript1.timelastmodified AS timelastmodified1,
    p_transcript2.feature_id AS feature_id2,
    p_transcript2.dbxref_id AS dbxref_id2,
    p_transcript2.organism_id AS organism_id2,
    p_transcript2.name AS name2,
    p_transcript2.uniquename AS uniquename2,
    p_transcript2.residues AS residues2,
    p_transcript2.seqlen AS seqlen2,
    p_transcript2.md5checksum AS md5checksum2,
    p_transcript2.type_id AS type_id2,
    p_transcript2.is_analysis AS is_analysis2,
    p_transcript2.timeaccessioned AS timeaccessioned2,
    p_transcript2.timelastmodified AS timelastmodified2
  FROM
    p_transcript AS p_transcript1 INNER JOIN
    feature_relationship AS fr1 ON (p_transcript1.p_transcript_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    p_transcript AS p_transcript2 ON (p_transcript1.p_transcript_id = fr2.subject_id);


--- ************************************************
--- *** relation: p_transcript_invpair           ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "processed_transcript"
CREATE VIEW p_transcript_invpair AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    p_transcript1.feature_id AS feature_id1,
    p_transcript1.dbxref_id AS dbxref_id1,
    p_transcript1.organism_id AS organism_id1,
    p_transcript1.name AS name1,
    p_transcript1.uniquename AS uniquename1,
    p_transcript1.residues AS residues1,
    p_transcript1.seqlen AS seqlen1,
    p_transcript1.md5checksum AS md5checksum1,
    p_transcript1.type_id AS type_id1,
    p_transcript1.is_analysis AS is_analysis1,
    p_transcript1.timeaccessioned AS timeaccessioned1,
    p_transcript1.timelastmodified AS timelastmodified1,
    p_transcript2.feature_id AS feature_id2,
    p_transcript2.dbxref_id AS dbxref_id2,
    p_transcript2.organism_id AS organism_id2,
    p_transcript2.name AS name2,
    p_transcript2.uniquename AS uniquename2,
    p_transcript2.residues AS residues2,
    p_transcript2.seqlen AS seqlen2,
    p_transcript2.md5checksum AS md5checksum2,
    p_transcript2.type_id AS type_id2,
    p_transcript2.is_analysis AS is_analysis2,
    p_transcript2.timeaccessioned AS timeaccessioned2,
    p_transcript2.timelastmodified AS timelastmodified2
  FROM
    p_transcript AS p_transcript1 INNER JOIN
    feature_relationship AS fr1 ON (p_transcript1.p_transcript_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    p_transcript AS p_transcript2 ON (p_transcript1.p_transcript_id = fr2.object_id);


--- ************************************************
--- *** relation: mrna                           ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology 'Typed Feature' View   ***
--- ***                                          ***
--- ************************************************
---
--- SO Term:
--- "mRNA"

CREATE VIEW mrna AS
  SELECT
    feature_id AS mrna_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'mRNA';

--- ************************************************
--- *** relation: mrna_pair                      ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Pair View      ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "mRNA"
CREATE VIEW mrna_pair AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    mrna1.feature_id AS feature_id1,
    mrna1.dbxref_id AS dbxref_id1,
    mrna1.organism_id AS organism_id1,
    mrna1.name AS name1,
    mrna1.uniquename AS uniquename1,
    mrna1.residues AS residues1,
    mrna1.seqlen AS seqlen1,
    mrna1.md5checksum AS md5checksum1,
    mrna1.type_id AS type_id1,
    mrna1.is_analysis AS is_analysis1,
    mrna1.timeaccessioned AS timeaccessioned1,
    mrna1.timelastmodified AS timelastmodified1,
    mrna2.feature_id AS feature_id2,
    mrna2.dbxref_id AS dbxref_id2,
    mrna2.organism_id AS organism_id2,
    mrna2.name AS name2,
    mrna2.uniquename AS uniquename2,
    mrna2.residues AS residues2,
    mrna2.seqlen AS seqlen2,
    mrna2.md5checksum AS md5checksum2,
    mrna2.type_id AS type_id2,
    mrna2.is_analysis AS is_analysis2,
    mrna2.timeaccessioned AS timeaccessioned2,
    mrna2.timelastmodified AS timelastmodified2
  FROM
    mrna AS mrna1 INNER JOIN
    feature_relationship AS fr1 ON (mrna1.mrna_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    mrna AS mrna2 ON (mrna1.mrna_id = fr2.subject_id);


--- ************************************************
--- *** relation: mrna_invpair                   ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "mRNA"
CREATE VIEW mrna_invpair AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    mrna1.feature_id AS feature_id1,
    mrna1.dbxref_id AS dbxref_id1,
    mrna1.organism_id AS organism_id1,
    mrna1.name AS name1,
    mrna1.uniquename AS uniquename1,
    mrna1.residues AS residues1,
    mrna1.seqlen AS seqlen1,
    mrna1.md5checksum AS md5checksum1,
    mrna1.type_id AS type_id1,
    mrna1.is_analysis AS is_analysis1,
    mrna1.timeaccessioned AS timeaccessioned1,
    mrna1.timelastmodified AS timelastmodified1,
    mrna2.feature_id AS feature_id2,
    mrna2.dbxref_id AS dbxref_id2,
    mrna2.organism_id AS organism_id2,
    mrna2.name AS name2,
    mrna2.uniquename AS uniquename2,
    mrna2.residues AS residues2,
    mrna2.seqlen AS seqlen2,
    mrna2.md5checksum AS md5checksum2,
    mrna2.type_id AS type_id2,
    mrna2.is_analysis AS is_analysis2,
    mrna2.timeaccessioned AS timeaccessioned2,
    mrna2.timelastmodified AS timelastmodified2
  FROM
    mrna AS mrna1 INNER JOIN
    feature_relationship AS fr1 ON (mrna1.mrna_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    mrna AS mrna2 ON (mrna1.mrna_id = fr2.object_id);


--- ************************************************
--- *** relation: ncrna                          ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology 'Typed Feature' View   ***
--- ***                                          ***
--- ************************************************
---
--- SO Term:
--- "ncRNA"

CREATE VIEW ncrna AS
  SELECT
    feature_id AS ncrna_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'ncRNA';

--- ************************************************
--- *** relation: ncrna_pair                     ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Pair View      ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "ncRNA"
CREATE VIEW ncrna_pair AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    ncrna1.feature_id AS feature_id1,
    ncrna1.dbxref_id AS dbxref_id1,
    ncrna1.organism_id AS organism_id1,
    ncrna1.name AS name1,
    ncrna1.uniquename AS uniquename1,
    ncrna1.residues AS residues1,
    ncrna1.seqlen AS seqlen1,
    ncrna1.md5checksum AS md5checksum1,
    ncrna1.type_id AS type_id1,
    ncrna1.is_analysis AS is_analysis1,
    ncrna1.timeaccessioned AS timeaccessioned1,
    ncrna1.timelastmodified AS timelastmodified1,
    ncrna2.feature_id AS feature_id2,
    ncrna2.dbxref_id AS dbxref_id2,
    ncrna2.organism_id AS organism_id2,
    ncrna2.name AS name2,
    ncrna2.uniquename AS uniquename2,
    ncrna2.residues AS residues2,
    ncrna2.seqlen AS seqlen2,
    ncrna2.md5checksum AS md5checksum2,
    ncrna2.type_id AS type_id2,
    ncrna2.is_analysis AS is_analysis2,
    ncrna2.timeaccessioned AS timeaccessioned2,
    ncrna2.timelastmodified AS timelastmodified2
  FROM
    ncrna AS ncrna1 INNER JOIN
    feature_relationship AS fr1 ON (ncrna1.ncrna_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    ncrna AS ncrna2 ON (ncrna1.ncrna_id = fr2.subject_id);


--- ************************************************
--- *** relation: ncrna_invpair                  ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "ncRNA"
CREATE VIEW ncrna_invpair AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    ncrna1.feature_id AS feature_id1,
    ncrna1.dbxref_id AS dbxref_id1,
    ncrna1.organism_id AS organism_id1,
    ncrna1.name AS name1,
    ncrna1.uniquename AS uniquename1,
    ncrna1.residues AS residues1,
    ncrna1.seqlen AS seqlen1,
    ncrna1.md5checksum AS md5checksum1,
    ncrna1.type_id AS type_id1,
    ncrna1.is_analysis AS is_analysis1,
    ncrna1.timeaccessioned AS timeaccessioned1,
    ncrna1.timelastmodified AS timelastmodified1,
    ncrna2.feature_id AS feature_id2,
    ncrna2.dbxref_id AS dbxref_id2,
    ncrna2.organism_id AS organism_id2,
    ncrna2.name AS name2,
    ncrna2.uniquename AS uniquename2,
    ncrna2.residues AS residues2,
    ncrna2.seqlen AS seqlen2,
    ncrna2.md5checksum AS md5checksum2,
    ncrna2.type_id AS type_id2,
    ncrna2.is_analysis AS is_analysis2,
    ncrna2.timeaccessioned AS timeaccessioned2,
    ncrna2.timelastmodified AS timelastmodified2
  FROM
    ncrna AS ncrna1 INNER JOIN
    feature_relationship AS fr1 ON (ncrna1.ncrna_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    ncrna AS ncrna2 ON (ncrna1.ncrna_id = fr2.object_id);


--- ************************************************
--- *** relation: snorna                         ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology 'Typed Feature' View   ***
--- ***                                          ***
--- ************************************************
---
--- SO Term:
--- "snoRNA"

CREATE VIEW snorna AS
  SELECT
    feature_id AS snorna_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'snoRNA';

--- ************************************************
--- *** relation: snorna_pair                    ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Pair View      ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "snoRNA"
CREATE VIEW snorna_pair AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    snorna1.feature_id AS feature_id1,
    snorna1.dbxref_id AS dbxref_id1,
    snorna1.organism_id AS organism_id1,
    snorna1.name AS name1,
    snorna1.uniquename AS uniquename1,
    snorna1.residues AS residues1,
    snorna1.seqlen AS seqlen1,
    snorna1.md5checksum AS md5checksum1,
    snorna1.type_id AS type_id1,
    snorna1.is_analysis AS is_analysis1,
    snorna1.timeaccessioned AS timeaccessioned1,
    snorna1.timelastmodified AS timelastmodified1,
    snorna2.feature_id AS feature_id2,
    snorna2.dbxref_id AS dbxref_id2,
    snorna2.organism_id AS organism_id2,
    snorna2.name AS name2,
    snorna2.uniquename AS uniquename2,
    snorna2.residues AS residues2,
    snorna2.seqlen AS seqlen2,
    snorna2.md5checksum AS md5checksum2,
    snorna2.type_id AS type_id2,
    snorna2.is_analysis AS is_analysis2,
    snorna2.timeaccessioned AS timeaccessioned2,
    snorna2.timelastmodified AS timelastmodified2
  FROM
    snorna AS snorna1 INNER JOIN
    feature_relationship AS fr1 ON (snorna1.snorna_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    snorna AS snorna2 ON (snorna1.snorna_id = fr2.subject_id);


--- ************************************************
--- *** relation: snorna_invpair                 ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "snoRNA"
CREATE VIEW snorna_invpair AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    snorna1.feature_id AS feature_id1,
    snorna1.dbxref_id AS dbxref_id1,
    snorna1.organism_id AS organism_id1,
    snorna1.name AS name1,
    snorna1.uniquename AS uniquename1,
    snorna1.residues AS residues1,
    snorna1.seqlen AS seqlen1,
    snorna1.md5checksum AS md5checksum1,
    snorna1.type_id AS type_id1,
    snorna1.is_analysis AS is_analysis1,
    snorna1.timeaccessioned AS timeaccessioned1,
    snorna1.timelastmodified AS timelastmodified1,
    snorna2.feature_id AS feature_id2,
    snorna2.dbxref_id AS dbxref_id2,
    snorna2.organism_id AS organism_id2,
    snorna2.name AS name2,
    snorna2.uniquename AS uniquename2,
    snorna2.residues AS residues2,
    snorna2.seqlen AS seqlen2,
    snorna2.md5checksum AS md5checksum2,
    snorna2.type_id AS type_id2,
    snorna2.is_analysis AS is_analysis2,
    snorna2.timeaccessioned AS timeaccessioned2,
    snorna2.timelastmodified AS timelastmodified2
  FROM
    snorna AS snorna1 INNER JOIN
    feature_relationship AS fr1 ON (snorna1.snorna_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    snorna AS snorna2 ON (snorna1.snorna_id = fr2.object_id);


--- ************************************************
--- *** relation: snrna                          ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology 'Typed Feature' View   ***
--- ***                                          ***
--- ************************************************
---
--- SO Term:
--- "snRNA"

CREATE VIEW snrna AS
  SELECT
    feature_id AS snrna_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'snRNA';

--- ************************************************
--- *** relation: snrna_pair                     ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Pair View      ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "snRNA"
CREATE VIEW snrna_pair AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    snrna1.feature_id AS feature_id1,
    snrna1.dbxref_id AS dbxref_id1,
    snrna1.organism_id AS organism_id1,
    snrna1.name AS name1,
    snrna1.uniquename AS uniquename1,
    snrna1.residues AS residues1,
    snrna1.seqlen AS seqlen1,
    snrna1.md5checksum AS md5checksum1,
    snrna1.type_id AS type_id1,
    snrna1.is_analysis AS is_analysis1,
    snrna1.timeaccessioned AS timeaccessioned1,
    snrna1.timelastmodified AS timelastmodified1,
    snrna2.feature_id AS feature_id2,
    snrna2.dbxref_id AS dbxref_id2,
    snrna2.organism_id AS organism_id2,
    snrna2.name AS name2,
    snrna2.uniquename AS uniquename2,
    snrna2.residues AS residues2,
    snrna2.seqlen AS seqlen2,
    snrna2.md5checksum AS md5checksum2,
    snrna2.type_id AS type_id2,
    snrna2.is_analysis AS is_analysis2,
    snrna2.timeaccessioned AS timeaccessioned2,
    snrna2.timelastmodified AS timelastmodified2
  FROM
    snrna AS snrna1 INNER JOIN
    feature_relationship AS fr1 ON (snrna1.snrna_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    snrna AS snrna2 ON (snrna1.snrna_id = fr2.subject_id);


--- ************************************************
--- *** relation: snrna_invpair                  ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "snRNA"
CREATE VIEW snrna_invpair AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    snrna1.feature_id AS feature_id1,
    snrna1.dbxref_id AS dbxref_id1,
    snrna1.organism_id AS organism_id1,
    snrna1.name AS name1,
    snrna1.uniquename AS uniquename1,
    snrna1.residues AS residues1,
    snrna1.seqlen AS seqlen1,
    snrna1.md5checksum AS md5checksum1,
    snrna1.type_id AS type_id1,
    snrna1.is_analysis AS is_analysis1,
    snrna1.timeaccessioned AS timeaccessioned1,
    snrna1.timelastmodified AS timelastmodified1,
    snrna2.feature_id AS feature_id2,
    snrna2.dbxref_id AS dbxref_id2,
    snrna2.organism_id AS organism_id2,
    snrna2.name AS name2,
    snrna2.uniquename AS uniquename2,
    snrna2.residues AS residues2,
    snrna2.seqlen AS seqlen2,
    snrna2.md5checksum AS md5checksum2,
    snrna2.type_id AS type_id2,
    snrna2.is_analysis AS is_analysis2,
    snrna2.timeaccessioned AS timeaccessioned2,
    snrna2.timelastmodified AS timelastmodified2
  FROM
    snrna AS snrna1 INNER JOIN
    feature_relationship AS fr1 ON (snrna1.snrna_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    snrna AS snrna2 ON (snrna1.snrna_id = fr2.object_id);


--- ************************************************
--- *** relation: trna                           ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology 'Typed Feature' View   ***
--- ***                                          ***
--- ************************************************
---
--- SO Term:
--- "tRNA"

CREATE VIEW trna AS
  SELECT
    feature_id AS trna_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'tRNA';

--- ************************************************
--- *** relation: trna_pair                      ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Pair View      ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "tRNA"
CREATE VIEW trna_pair AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    trna1.feature_id AS feature_id1,
    trna1.dbxref_id AS dbxref_id1,
    trna1.organism_id AS organism_id1,
    trna1.name AS name1,
    trna1.uniquename AS uniquename1,
    trna1.residues AS residues1,
    trna1.seqlen AS seqlen1,
    trna1.md5checksum AS md5checksum1,
    trna1.type_id AS type_id1,
    trna1.is_analysis AS is_analysis1,
    trna1.timeaccessioned AS timeaccessioned1,
    trna1.timelastmodified AS timelastmodified1,
    trna2.feature_id AS feature_id2,
    trna2.dbxref_id AS dbxref_id2,
    trna2.organism_id AS organism_id2,
    trna2.name AS name2,
    trna2.uniquename AS uniquename2,
    trna2.residues AS residues2,
    trna2.seqlen AS seqlen2,
    trna2.md5checksum AS md5checksum2,
    trna2.type_id AS type_id2,
    trna2.is_analysis AS is_analysis2,
    trna2.timeaccessioned AS timeaccessioned2,
    trna2.timelastmodified AS timelastmodified2
  FROM
    trna AS trna1 INNER JOIN
    feature_relationship AS fr1 ON (trna1.trna_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    trna AS trna2 ON (trna1.trna_id = fr2.subject_id);


--- ************************************************
--- *** relation: trna_invpair                   ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "tRNA"
CREATE VIEW trna_invpair AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    trna1.feature_id AS feature_id1,
    trna1.dbxref_id AS dbxref_id1,
    trna1.organism_id AS organism_id1,
    trna1.name AS name1,
    trna1.uniquename AS uniquename1,
    trna1.residues AS residues1,
    trna1.seqlen AS seqlen1,
    trna1.md5checksum AS md5checksum1,
    trna1.type_id AS type_id1,
    trna1.is_analysis AS is_analysis1,
    trna1.timeaccessioned AS timeaccessioned1,
    trna1.timelastmodified AS timelastmodified1,
    trna2.feature_id AS feature_id2,
    trna2.dbxref_id AS dbxref_id2,
    trna2.organism_id AS organism_id2,
    trna2.name AS name2,
    trna2.uniquename AS uniquename2,
    trna2.residues AS residues2,
    trna2.seqlen AS seqlen2,
    trna2.md5checksum AS md5checksum2,
    trna2.type_id AS type_id2,
    trna2.is_analysis AS is_analysis2,
    trna2.timeaccessioned AS timeaccessioned2,
    trna2.timelastmodified AS timelastmodified2
  FROM
    trna AS trna1 INNER JOIN
    feature_relationship AS fr1 ON (trna1.trna_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    trna AS trna2 ON (trna1.trna_id = fr2.object_id);


--- ************************************************
--- *** relation: match                          ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology 'Typed Feature' View   ***
--- ***                                          ***
--- ************************************************
---
--- SO Term:
--- "match"

CREATE VIEW match AS
  SELECT
    feature_id AS match_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'match';

--- ************************************************
--- *** relation: match_pair                     ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Pair View      ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "match"
CREATE VIEW match_pair AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    match1.feature_id AS feature_id1,
    match1.dbxref_id AS dbxref_id1,
    match1.organism_id AS organism_id1,
    match1.name AS name1,
    match1.uniquename AS uniquename1,
    match1.residues AS residues1,
    match1.seqlen AS seqlen1,
    match1.md5checksum AS md5checksum1,
    match1.type_id AS type_id1,
    match1.is_analysis AS is_analysis1,
    match1.timeaccessioned AS timeaccessioned1,
    match1.timelastmodified AS timelastmodified1,
    match2.feature_id AS feature_id2,
    match2.dbxref_id AS dbxref_id2,
    match2.organism_id AS organism_id2,
    match2.name AS name2,
    match2.uniquename AS uniquename2,
    match2.residues AS residues2,
    match2.seqlen AS seqlen2,
    match2.md5checksum AS md5checksum2,
    match2.type_id AS type_id2,
    match2.is_analysis AS is_analysis2,
    match2.timeaccessioned AS timeaccessioned2,
    match2.timelastmodified AS timelastmodified2
  FROM
    match AS match1 INNER JOIN
    feature_relationship AS fr1 ON (match1.match_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    match AS match2 ON (match1.match_id = fr2.subject_id);


--- ************************************************
--- *** relation: match_invpair                  ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "match"
CREATE VIEW match_invpair AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    match1.feature_id AS feature_id1,
    match1.dbxref_id AS dbxref_id1,
    match1.organism_id AS organism_id1,
    match1.name AS name1,
    match1.uniquename AS uniquename1,
    match1.residues AS residues1,
    match1.seqlen AS seqlen1,
    match1.md5checksum AS md5checksum1,
    match1.type_id AS type_id1,
    match1.is_analysis AS is_analysis1,
    match1.timeaccessioned AS timeaccessioned1,
    match1.timelastmodified AS timelastmodified1,
    match2.feature_id AS feature_id2,
    match2.dbxref_id AS dbxref_id2,
    match2.organism_id AS organism_id2,
    match2.name AS name2,
    match2.uniquename AS uniquename2,
    match2.residues AS residues2,
    match2.seqlen AS seqlen2,
    match2.md5checksum AS md5checksum2,
    match2.type_id AS type_id2,
    match2.is_analysis AS is_analysis2,
    match2.timeaccessioned AS timeaccessioned2,
    match2.timelastmodified AS timelastmodified2
  FROM
    match AS match1 INNER JOIN
    feature_relationship AS fr1 ON (match1.match_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    match AS match2 ON (match1.match_id = fr2.object_id);


--- ************************************************
--- *** relation: g_path_region                  ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology 'Typed Feature' View   ***
--- ***                                          ***
--- ************************************************
---
--- SO Term:
--- "golden_path_region"

CREATE VIEW g_path_region AS
  SELECT
    feature_id AS g_path_region_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'golden_path_region';

--- ************************************************
--- *** relation: g_path_region_pair             ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Pair View      ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "golden_path_region"
CREATE VIEW g_path_region_pair AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    g_path_region1.feature_id AS feature_id1,
    g_path_region1.dbxref_id AS dbxref_id1,
    g_path_region1.organism_id AS organism_id1,
    g_path_region1.name AS name1,
    g_path_region1.uniquename AS uniquename1,
    g_path_region1.residues AS residues1,
    g_path_region1.seqlen AS seqlen1,
    g_path_region1.md5checksum AS md5checksum1,
    g_path_region1.type_id AS type_id1,
    g_path_region1.is_analysis AS is_analysis1,
    g_path_region1.timeaccessioned AS timeaccessioned1,
    g_path_region1.timelastmodified AS timelastmodified1,
    g_path_region2.feature_id AS feature_id2,
    g_path_region2.dbxref_id AS dbxref_id2,
    g_path_region2.organism_id AS organism_id2,
    g_path_region2.name AS name2,
    g_path_region2.uniquename AS uniquename2,
    g_path_region2.residues AS residues2,
    g_path_region2.seqlen AS seqlen2,
    g_path_region2.md5checksum AS md5checksum2,
    g_path_region2.type_id AS type_id2,
    g_path_region2.is_analysis AS is_analysis2,
    g_path_region2.timeaccessioned AS timeaccessioned2,
    g_path_region2.timelastmodified AS timelastmodified2
  FROM
    g_path_region AS g_path_region1 INNER JOIN
    feature_relationship AS fr1 ON (g_path_region1.g_path_region_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    g_path_region AS g_path_region2 ON (g_path_region1.g_path_region_id = fr2.subject_id);


--- ************************************************
--- *** relation: g_path_region_invpair          ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "golden_path_region"
CREATE VIEW g_path_region_invpair AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    g_path_region1.feature_id AS feature_id1,
    g_path_region1.dbxref_id AS dbxref_id1,
    g_path_region1.organism_id AS organism_id1,
    g_path_region1.name AS name1,
    g_path_region1.uniquename AS uniquename1,
    g_path_region1.residues AS residues1,
    g_path_region1.seqlen AS seqlen1,
    g_path_region1.md5checksum AS md5checksum1,
    g_path_region1.type_id AS type_id1,
    g_path_region1.is_analysis AS is_analysis1,
    g_path_region1.timeaccessioned AS timeaccessioned1,
    g_path_region1.timelastmodified AS timelastmodified1,
    g_path_region2.feature_id AS feature_id2,
    g_path_region2.dbxref_id AS dbxref_id2,
    g_path_region2.organism_id AS organism_id2,
    g_path_region2.name AS name2,
    g_path_region2.uniquename AS uniquename2,
    g_path_region2.residues AS residues2,
    g_path_region2.seqlen AS seqlen2,
    g_path_region2.md5checksum AS md5checksum2,
    g_path_region2.type_id AS type_id2,
    g_path_region2.is_analysis AS is_analysis2,
    g_path_region2.timeaccessioned AS timeaccessioned2,
    g_path_region2.timelastmodified AS timelastmodified2
  FROM
    g_path_region AS g_path_region1 INNER JOIN
    feature_relationship AS fr1 ON (g_path_region1.g_path_region_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    g_path_region AS g_path_region2 ON (g_path_region1.g_path_region_id = fr2.object_id);


--- ************************************************
--- *** relation: bac                            ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology 'Typed Feature' View   ***
--- ***                                          ***
--- ************************************************
---
--- SO Term:
--- "BAC"

CREATE VIEW bac AS
  SELECT
    feature_id AS bac_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'BAC';

--- ************************************************
--- *** relation: bac_pair                       ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Pair View      ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "BAC"
CREATE VIEW bac_pair AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    bac1.feature_id AS feature_id1,
    bac1.dbxref_id AS dbxref_id1,
    bac1.organism_id AS organism_id1,
    bac1.name AS name1,
    bac1.uniquename AS uniquename1,
    bac1.residues AS residues1,
    bac1.seqlen AS seqlen1,
    bac1.md5checksum AS md5checksum1,
    bac1.type_id AS type_id1,
    bac1.is_analysis AS is_analysis1,
    bac1.timeaccessioned AS timeaccessioned1,
    bac1.timelastmodified AS timelastmodified1,
    bac2.feature_id AS feature_id2,
    bac2.dbxref_id AS dbxref_id2,
    bac2.organism_id AS organism_id2,
    bac2.name AS name2,
    bac2.uniquename AS uniquename2,
    bac2.residues AS residues2,
    bac2.seqlen AS seqlen2,
    bac2.md5checksum AS md5checksum2,
    bac2.type_id AS type_id2,
    bac2.is_analysis AS is_analysis2,
    bac2.timeaccessioned AS timeaccessioned2,
    bac2.timelastmodified AS timelastmodified2
  FROM
    bac AS bac1 INNER JOIN
    feature_relationship AS fr1 ON (bac1.bac_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    bac AS bac2 ON (bac1.bac_id = fr2.subject_id);


--- ************************************************
--- *** relation: bac_invpair                    ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "BAC"
CREATE VIEW bac_invpair AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    bac1.feature_id AS feature_id1,
    bac1.dbxref_id AS dbxref_id1,
    bac1.organism_id AS organism_id1,
    bac1.name AS name1,
    bac1.uniquename AS uniquename1,
    bac1.residues AS residues1,
    bac1.seqlen AS seqlen1,
    bac1.md5checksum AS md5checksum1,
    bac1.type_id AS type_id1,
    bac1.is_analysis AS is_analysis1,
    bac1.timeaccessioned AS timeaccessioned1,
    bac1.timelastmodified AS timelastmodified1,
    bac2.feature_id AS feature_id2,
    bac2.dbxref_id AS dbxref_id2,
    bac2.organism_id AS organism_id2,
    bac2.name AS name2,
    bac2.uniquename AS uniquename2,
    bac2.residues AS residues2,
    bac2.seqlen AS seqlen2,
    bac2.md5checksum AS md5checksum2,
    bac2.type_id AS type_id2,
    bac2.is_analysis AS is_analysis2,
    bac2.timeaccessioned AS timeaccessioned2,
    bac2.timelastmodified AS timelastmodified2
  FROM
    bac AS bac1 INNER JOIN
    feature_relationship AS fr1 ON (bac1.bac_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    bac AS bac2 ON (bac1.bac_id = fr2.object_id);


--- ************************************************
--- *** relation: cdna_clone                     ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology 'Typed Feature' View   ***
--- ***                                          ***
--- ************************************************
---
--- SO Term:
--- "cDNA_clone"

CREATE VIEW cdna_clone AS
  SELECT
    feature_id AS cdna_clone_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'cDNA_clone';

--- ************************************************
--- *** relation: cdna_clone_pair                ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Pair View      ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "cDNA_clone"
CREATE VIEW cdna_clone_pair AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    cdna_clone1.feature_id AS feature_id1,
    cdna_clone1.dbxref_id AS dbxref_id1,
    cdna_clone1.organism_id AS organism_id1,
    cdna_clone1.name AS name1,
    cdna_clone1.uniquename AS uniquename1,
    cdna_clone1.residues AS residues1,
    cdna_clone1.seqlen AS seqlen1,
    cdna_clone1.md5checksum AS md5checksum1,
    cdna_clone1.type_id AS type_id1,
    cdna_clone1.is_analysis AS is_analysis1,
    cdna_clone1.timeaccessioned AS timeaccessioned1,
    cdna_clone1.timelastmodified AS timelastmodified1,
    cdna_clone2.feature_id AS feature_id2,
    cdna_clone2.dbxref_id AS dbxref_id2,
    cdna_clone2.organism_id AS organism_id2,
    cdna_clone2.name AS name2,
    cdna_clone2.uniquename AS uniquename2,
    cdna_clone2.residues AS residues2,
    cdna_clone2.seqlen AS seqlen2,
    cdna_clone2.md5checksum AS md5checksum2,
    cdna_clone2.type_id AS type_id2,
    cdna_clone2.is_analysis AS is_analysis2,
    cdna_clone2.timeaccessioned AS timeaccessioned2,
    cdna_clone2.timelastmodified AS timelastmodified2
  FROM
    cdna_clone AS cdna_clone1 INNER JOIN
    feature_relationship AS fr1 ON (cdna_clone1.cdna_clone_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    cdna_clone AS cdna_clone2 ON (cdna_clone1.cdna_clone_id = fr2.subject_id);


--- ************************************************
--- *** relation: cdna_clone_invpair             ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "cDNA_clone"
CREATE VIEW cdna_clone_invpair AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    cdna_clone1.feature_id AS feature_id1,
    cdna_clone1.dbxref_id AS dbxref_id1,
    cdna_clone1.organism_id AS organism_id1,
    cdna_clone1.name AS name1,
    cdna_clone1.uniquename AS uniquename1,
    cdna_clone1.residues AS residues1,
    cdna_clone1.seqlen AS seqlen1,
    cdna_clone1.md5checksum AS md5checksum1,
    cdna_clone1.type_id AS type_id1,
    cdna_clone1.is_analysis AS is_analysis1,
    cdna_clone1.timeaccessioned AS timeaccessioned1,
    cdna_clone1.timelastmodified AS timelastmodified1,
    cdna_clone2.feature_id AS feature_id2,
    cdna_clone2.dbxref_id AS dbxref_id2,
    cdna_clone2.organism_id AS organism_id2,
    cdna_clone2.name AS name2,
    cdna_clone2.uniquename AS uniquename2,
    cdna_clone2.residues AS residues2,
    cdna_clone2.seqlen AS seqlen2,
    cdna_clone2.md5checksum AS md5checksum2,
    cdna_clone2.type_id AS type_id2,
    cdna_clone2.is_analysis AS is_analysis2,
    cdna_clone2.timeaccessioned AS timeaccessioned2,
    cdna_clone2.timelastmodified AS timelastmodified2
  FROM
    cdna_clone AS cdna_clone1 INNER JOIN
    feature_relationship AS fr1 ON (cdna_clone1.cdna_clone_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    cdna_clone AS cdna_clone2 ON (cdna_clone1.cdna_clone_id = fr2.object_id);


--- ************************************************
--- *** relation: oligonucleotide                ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology 'Typed Feature' View   ***
--- ***                                          ***
--- ************************************************
---
--- SO Term:
--- "oligonucleotide"

CREATE VIEW oligonucleotide AS
  SELECT
    feature_id AS oligonucleotide_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'oligonucleotide';

--- ************************************************
--- *** relation: oligonucleotide_pair           ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Pair View      ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "oligonucleotide"
CREATE VIEW oligonucleotide_pair AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    oligonucleotide1.feature_id AS feature_id1,
    oligonucleotide1.dbxref_id AS dbxref_id1,
    oligonucleotide1.organism_id AS organism_id1,
    oligonucleotide1.name AS name1,
    oligonucleotide1.uniquename AS uniquename1,
    oligonucleotide1.residues AS residues1,
    oligonucleotide1.seqlen AS seqlen1,
    oligonucleotide1.md5checksum AS md5checksum1,
    oligonucleotide1.type_id AS type_id1,
    oligonucleotide1.is_analysis AS is_analysis1,
    oligonucleotide1.timeaccessioned AS timeaccessioned1,
    oligonucleotide1.timelastmodified AS timelastmodified1,
    oligonucleotide2.feature_id AS feature_id2,
    oligonucleotide2.dbxref_id AS dbxref_id2,
    oligonucleotide2.organism_id AS organism_id2,
    oligonucleotide2.name AS name2,
    oligonucleotide2.uniquename AS uniquename2,
    oligonucleotide2.residues AS residues2,
    oligonucleotide2.seqlen AS seqlen2,
    oligonucleotide2.md5checksum AS md5checksum2,
    oligonucleotide2.type_id AS type_id2,
    oligonucleotide2.is_analysis AS is_analysis2,
    oligonucleotide2.timeaccessioned AS timeaccessioned2,
    oligonucleotide2.timelastmodified AS timelastmodified2
  FROM
    oligonucleotide AS oligonucleotide1 INNER JOIN
    feature_relationship AS fr1 ON (oligonucleotide1.oligonucleotide_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    oligonucleotide AS oligonucleotide2 ON (oligonucleotide1.oligonucleotide_id = fr2.subject_id);


--- ************************************************
--- *** relation: oligonucleotide_invpair        ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "oligonucleotide"
CREATE VIEW oligonucleotide_invpair AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    oligonucleotide1.feature_id AS feature_id1,
    oligonucleotide1.dbxref_id AS dbxref_id1,
    oligonucleotide1.organism_id AS organism_id1,
    oligonucleotide1.name AS name1,
    oligonucleotide1.uniquename AS uniquename1,
    oligonucleotide1.residues AS residues1,
    oligonucleotide1.seqlen AS seqlen1,
    oligonucleotide1.md5checksum AS md5checksum1,
    oligonucleotide1.type_id AS type_id1,
    oligonucleotide1.is_analysis AS is_analysis1,
    oligonucleotide1.timeaccessioned AS timeaccessioned1,
    oligonucleotide1.timelastmodified AS timelastmodified1,
    oligonucleotide2.feature_id AS feature_id2,
    oligonucleotide2.dbxref_id AS dbxref_id2,
    oligonucleotide2.organism_id AS organism_id2,
    oligonucleotide2.name AS name2,
    oligonucleotide2.uniquename AS uniquename2,
    oligonucleotide2.residues AS residues2,
    oligonucleotide2.seqlen AS seqlen2,
    oligonucleotide2.md5checksum AS md5checksum2,
    oligonucleotide2.type_id AS type_id2,
    oligonucleotide2.is_analysis AS is_analysis2,
    oligonucleotide2.timeaccessioned AS timeaccessioned2,
    oligonucleotide2.timelastmodified AS timelastmodified2
  FROM
    oligonucleotide AS oligonucleotide1 INNER JOIN
    feature_relationship AS fr1 ON (oligonucleotide1.oligonucleotide_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    oligonucleotide AS oligonucleotide2 ON (oligonucleotide1.oligonucleotide_id = fr2.object_id);


--- ************************************************
--- *** relation: repeat_region                  ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology 'Typed Feature' View   ***
--- ***                                          ***
--- ************************************************
---
--- SO Term:
--- "repeat_region"

CREATE VIEW repeat_region AS
  SELECT
    feature_id AS repeat_region_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'repeat_region';

--- ************************************************
--- *** relation: repeat_region_pair             ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Pair View      ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "repeat_region"
CREATE VIEW repeat_region_pair AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    repeat_region1.feature_id AS feature_id1,
    repeat_region1.dbxref_id AS dbxref_id1,
    repeat_region1.organism_id AS organism_id1,
    repeat_region1.name AS name1,
    repeat_region1.uniquename AS uniquename1,
    repeat_region1.residues AS residues1,
    repeat_region1.seqlen AS seqlen1,
    repeat_region1.md5checksum AS md5checksum1,
    repeat_region1.type_id AS type_id1,
    repeat_region1.is_analysis AS is_analysis1,
    repeat_region1.timeaccessioned AS timeaccessioned1,
    repeat_region1.timelastmodified AS timelastmodified1,
    repeat_region2.feature_id AS feature_id2,
    repeat_region2.dbxref_id AS dbxref_id2,
    repeat_region2.organism_id AS organism_id2,
    repeat_region2.name AS name2,
    repeat_region2.uniquename AS uniquename2,
    repeat_region2.residues AS residues2,
    repeat_region2.seqlen AS seqlen2,
    repeat_region2.md5checksum AS md5checksum2,
    repeat_region2.type_id AS type_id2,
    repeat_region2.is_analysis AS is_analysis2,
    repeat_region2.timeaccessioned AS timeaccessioned2,
    repeat_region2.timelastmodified AS timelastmodified2
  FROM
    repeat_region AS repeat_region1 INNER JOIN
    feature_relationship AS fr1 ON (repeat_region1.repeat_region_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    repeat_region AS repeat_region2 ON (repeat_region1.repeat_region_id = fr2.subject_id);


--- ************************************************
--- *** relation: repeat_region_invpair          ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "repeat_region"
CREATE VIEW repeat_region_invpair AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    repeat_region1.feature_id AS feature_id1,
    repeat_region1.dbxref_id AS dbxref_id1,
    repeat_region1.organism_id AS organism_id1,
    repeat_region1.name AS name1,
    repeat_region1.uniquename AS uniquename1,
    repeat_region1.residues AS residues1,
    repeat_region1.seqlen AS seqlen1,
    repeat_region1.md5checksum AS md5checksum1,
    repeat_region1.type_id AS type_id1,
    repeat_region1.is_analysis AS is_analysis1,
    repeat_region1.timeaccessioned AS timeaccessioned1,
    repeat_region1.timelastmodified AS timelastmodified1,
    repeat_region2.feature_id AS feature_id2,
    repeat_region2.dbxref_id AS dbxref_id2,
    repeat_region2.organism_id AS organism_id2,
    repeat_region2.name AS name2,
    repeat_region2.uniquename AS uniquename2,
    repeat_region2.residues AS residues2,
    repeat_region2.seqlen AS seqlen2,
    repeat_region2.md5checksum AS md5checksum2,
    repeat_region2.type_id AS type_id2,
    repeat_region2.is_analysis AS is_analysis2,
    repeat_region2.timeaccessioned AS timeaccessioned2,
    repeat_region2.timelastmodified AS timelastmodified2
  FROM
    repeat_region AS repeat_region1 INNER JOIN
    feature_relationship AS fr1 ON (repeat_region1.repeat_region_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    repeat_region AS repeat_region2 ON (repeat_region1.repeat_region_id = fr2.object_id);


--- ************************************************
--- *** relation: tei_site                       ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology 'Typed Feature' View   ***
--- ***                                          ***
--- ************************************************
---
--- SO Term:
--- "transposable_element_insertion_site"

CREATE VIEW tei_site AS
  SELECT
    feature_id AS tei_site_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'transposable_element_insertion_site';

--- ************************************************
--- *** relation: tei_site_pair                  ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Pair View      ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "transposable_element_insertion_site"
CREATE VIEW tei_site_pair AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    tei_site1.feature_id AS feature_id1,
    tei_site1.dbxref_id AS dbxref_id1,
    tei_site1.organism_id AS organism_id1,
    tei_site1.name AS name1,
    tei_site1.uniquename AS uniquename1,
    tei_site1.residues AS residues1,
    tei_site1.seqlen AS seqlen1,
    tei_site1.md5checksum AS md5checksum1,
    tei_site1.type_id AS type_id1,
    tei_site1.is_analysis AS is_analysis1,
    tei_site1.timeaccessioned AS timeaccessioned1,
    tei_site1.timelastmodified AS timelastmodified1,
    tei_site2.feature_id AS feature_id2,
    tei_site2.dbxref_id AS dbxref_id2,
    tei_site2.organism_id AS organism_id2,
    tei_site2.name AS name2,
    tei_site2.uniquename AS uniquename2,
    tei_site2.residues AS residues2,
    tei_site2.seqlen AS seqlen2,
    tei_site2.md5checksum AS md5checksum2,
    tei_site2.type_id AS type_id2,
    tei_site2.is_analysis AS is_analysis2,
    tei_site2.timeaccessioned AS timeaccessioned2,
    tei_site2.timelastmodified AS timelastmodified2
  FROM
    tei_site AS tei_site1 INNER JOIN
    feature_relationship AS fr1 ON (tei_site1.tei_site_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    tei_site AS tei_site2 ON (tei_site1.tei_site_id = fr2.subject_id);


--- ************************************************
--- *** relation: tei_site_invpair               ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "transposable_element_insertion_site"
CREATE VIEW tei_site_invpair AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    tei_site1.feature_id AS feature_id1,
    tei_site1.dbxref_id AS dbxref_id1,
    tei_site1.organism_id AS organism_id1,
    tei_site1.name AS name1,
    tei_site1.uniquename AS uniquename1,
    tei_site1.residues AS residues1,
    tei_site1.seqlen AS seqlen1,
    tei_site1.md5checksum AS md5checksum1,
    tei_site1.type_id AS type_id1,
    tei_site1.is_analysis AS is_analysis1,
    tei_site1.timeaccessioned AS timeaccessioned1,
    tei_site1.timelastmodified AS timelastmodified1,
    tei_site2.feature_id AS feature_id2,
    tei_site2.dbxref_id AS dbxref_id2,
    tei_site2.organism_id AS organism_id2,
    tei_site2.name AS name2,
    tei_site2.uniquename AS uniquename2,
    tei_site2.residues AS residues2,
    tei_site2.seqlen AS seqlen2,
    tei_site2.md5checksum AS md5checksum2,
    tei_site2.type_id AS type_id2,
    tei_site2.is_analysis AS is_analysis2,
    tei_site2.timeaccessioned AS timeaccessioned2,
    tei_site2.timelastmodified AS timelastmodified2
  FROM
    tei_site AS tei_site1 INNER JOIN
    feature_relationship AS fr1 ON (tei_site1.tei_site_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    tei_site AS tei_site2 ON (tei_site1.tei_site_id = fr2.object_id);


--- ************************************************
--- *** relation: pseudogene                     ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology 'Typed Feature' View   ***
--- ***                                          ***
--- ************************************************
---
--- SO Term:
--- "pseudogene"

CREATE VIEW pseudogene AS
  SELECT
    feature_id AS pseudogene_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'pseudogene';

--- ************************************************
--- *** relation: pseudogene_pair                ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Pair View      ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "pseudogene"
CREATE VIEW pseudogene_pair AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    pseudogene1.feature_id AS feature_id1,
    pseudogene1.dbxref_id AS dbxref_id1,
    pseudogene1.organism_id AS organism_id1,
    pseudogene1.name AS name1,
    pseudogene1.uniquename AS uniquename1,
    pseudogene1.residues AS residues1,
    pseudogene1.seqlen AS seqlen1,
    pseudogene1.md5checksum AS md5checksum1,
    pseudogene1.type_id AS type_id1,
    pseudogene1.is_analysis AS is_analysis1,
    pseudogene1.timeaccessioned AS timeaccessioned1,
    pseudogene1.timelastmodified AS timelastmodified1,
    pseudogene2.feature_id AS feature_id2,
    pseudogene2.dbxref_id AS dbxref_id2,
    pseudogene2.organism_id AS organism_id2,
    pseudogene2.name AS name2,
    pseudogene2.uniquename AS uniquename2,
    pseudogene2.residues AS residues2,
    pseudogene2.seqlen AS seqlen2,
    pseudogene2.md5checksum AS md5checksum2,
    pseudogene2.type_id AS type_id2,
    pseudogene2.is_analysis AS is_analysis2,
    pseudogene2.timeaccessioned AS timeaccessioned2,
    pseudogene2.timelastmodified AS timelastmodified2
  FROM
    pseudogene AS pseudogene1 INNER JOIN
    feature_relationship AS fr1 ON (pseudogene1.pseudogene_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    pseudogene AS pseudogene2 ON (pseudogene1.pseudogene_id = fr2.subject_id);


--- ************************************************
--- *** relation: pseudogene_invpair             ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "pseudogene"
CREATE VIEW pseudogene_invpair AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    pseudogene1.feature_id AS feature_id1,
    pseudogene1.dbxref_id AS dbxref_id1,
    pseudogene1.organism_id AS organism_id1,
    pseudogene1.name AS name1,
    pseudogene1.uniquename AS uniquename1,
    pseudogene1.residues AS residues1,
    pseudogene1.seqlen AS seqlen1,
    pseudogene1.md5checksum AS md5checksum1,
    pseudogene1.type_id AS type_id1,
    pseudogene1.is_analysis AS is_analysis1,
    pseudogene1.timeaccessioned AS timeaccessioned1,
    pseudogene1.timelastmodified AS timelastmodified1,
    pseudogene2.feature_id AS feature_id2,
    pseudogene2.dbxref_id AS dbxref_id2,
    pseudogene2.organism_id AS organism_id2,
    pseudogene2.name AS name2,
    pseudogene2.uniquename AS uniquename2,
    pseudogene2.residues AS residues2,
    pseudogene2.seqlen AS seqlen2,
    pseudogene2.md5checksum AS md5checksum2,
    pseudogene2.type_id AS type_id2,
    pseudogene2.is_analysis AS is_analysis2,
    pseudogene2.timeaccessioned AS timeaccessioned2,
    pseudogene2.timelastmodified AS timelastmodified2
  FROM
    pseudogene AS pseudogene1 INNER JOIN
    feature_relationship AS fr1 ON (pseudogene1.pseudogene_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    pseudogene AS pseudogene2 ON (pseudogene1.pseudogene_id = fr2.object_id);


--- ************************************************
--- *** relation: protein                        ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology 'Typed Feature' View   ***
--- ***                                          ***
--- ************************************************
---
--- SO Term:
--- "protein"

CREATE VIEW protein AS
  SELECT
    feature_id AS protein_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'protein';

--- ************************************************
--- *** relation: protein_pair                   ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Pair View      ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "protein"
CREATE VIEW protein_pair AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    protein1.feature_id AS feature_id1,
    protein1.dbxref_id AS dbxref_id1,
    protein1.organism_id AS organism_id1,
    protein1.name AS name1,
    protein1.uniquename AS uniquename1,
    protein1.residues AS residues1,
    protein1.seqlen AS seqlen1,
    protein1.md5checksum AS md5checksum1,
    protein1.type_id AS type_id1,
    protein1.is_analysis AS is_analysis1,
    protein1.timeaccessioned AS timeaccessioned1,
    protein1.timelastmodified AS timelastmodified1,
    protein2.feature_id AS feature_id2,
    protein2.dbxref_id AS dbxref_id2,
    protein2.organism_id AS organism_id2,
    protein2.name AS name2,
    protein2.uniquename AS uniquename2,
    protein2.residues AS residues2,
    protein2.seqlen AS seqlen2,
    protein2.md5checksum AS md5checksum2,
    protein2.type_id AS type_id2,
    protein2.is_analysis AS is_analysis2,
    protein2.timeaccessioned AS timeaccessioned2,
    protein2.timelastmodified AS timelastmodified2
  FROM
    protein AS protein1 INNER JOIN
    feature_relationship AS fr1 ON (protein1.protein_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    protein AS protein2 ON (protein1.protein_id = fr2.subject_id);


--- ************************************************
--- *** relation: protein_invpair                ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "protein"
CREATE VIEW protein_invpair AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    protein1.feature_id AS feature_id1,
    protein1.dbxref_id AS dbxref_id1,
    protein1.organism_id AS organism_id1,
    protein1.name AS name1,
    protein1.uniquename AS uniquename1,
    protein1.residues AS residues1,
    protein1.seqlen AS seqlen1,
    protein1.md5checksum AS md5checksum1,
    protein1.type_id AS type_id1,
    protein1.is_analysis AS is_analysis1,
    protein1.timeaccessioned AS timeaccessioned1,
    protein1.timelastmodified AS timelastmodified1,
    protein2.feature_id AS feature_id2,
    protein2.dbxref_id AS dbxref_id2,
    protein2.organism_id AS organism_id2,
    protein2.name AS name2,
    protein2.uniquename AS uniquename2,
    protein2.residues AS residues2,
    protein2.seqlen AS seqlen2,
    protein2.md5checksum AS md5checksum2,
    protein2.type_id AS type_id2,
    protein2.is_analysis AS is_analysis2,
    protein2.timeaccessioned AS timeaccessioned2,
    protein2.timelastmodified AS timelastmodified2
  FROM
    protein AS protein1 INNER JOIN
    feature_relationship AS fr1 ON (protein1.protein_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    protein AS protein2 ON (protein1.protein_id = fr2.object_id);


--- ************************************************
--- *** relation: mrna2exon                      ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology PART-OF view           ***
--- ************************************************
---
--- Subject Type: exon
--- Object Type:  mrna
--- Predicate:    PART-OF

CREATE VIEW mrna2exon AS
  SELECT
    feature_relationship_id,
    subject_id AS exon_id,
    object_id AS mrna_id,
    subject_id,
    object_id,
    feature_relationship.type_id
  FROM
    exon INNER JOIN feature_relationship ON (exon.feature_id = subject_id)
        INNER JOIN mrna ON (mrna.feature_id = object_id);

--- ************************************************
--- *** relation: ncrna2exon                     ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology PART-OF view           ***
--- ************************************************
---
--- Subject Type: exon
--- Object Type:  ncrna
--- Predicate:    PART-OF

CREATE VIEW ncrna2exon AS
  SELECT
    feature_relationship_id,
    subject_id AS exon_id,
    object_id AS ncrna_id,
    subject_id,
    object_id,
    feature_relationship.type_id
  FROM
    exon INNER JOIN feature_relationship ON (exon.feature_id = subject_id)
        INNER JOIN ncrna ON (ncrna.feature_id = object_id);

--- ************************************************
--- *** relation: snorna2exon                    ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology PART-OF view           ***
--- ************************************************
---
--- Subject Type: exon
--- Object Type:  snorna
--- Predicate:    PART-OF

CREATE VIEW snorna2exon AS
  SELECT
    feature_relationship_id,
    subject_id AS exon_id,
    object_id AS snorna_id,
    subject_id,
    object_id,
    feature_relationship.type_id
  FROM
    exon INNER JOIN feature_relationship ON (exon.feature_id = subject_id)
        INNER JOIN snorna ON (snorna.feature_id = object_id);

--- ************************************************
--- *** relation: snrna2exon                     ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology PART-OF view           ***
--- ************************************************
---
--- Subject Type: exon
--- Object Type:  snrna
--- Predicate:    PART-OF

CREATE VIEW snrna2exon AS
  SELECT
    feature_relationship_id,
    subject_id AS exon_id,
    object_id AS snrna_id,
    subject_id,
    object_id,
    feature_relationship.type_id
  FROM
    exon INNER JOIN feature_relationship ON (exon.feature_id = subject_id)
        INNER JOIN snrna ON (snrna.feature_id = object_id);

--- ************************************************
--- *** relation: trna2exon                      ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology PART-OF view           ***
--- ************************************************
---
--- Subject Type: exon
--- Object Type:  trna
--- Predicate:    PART-OF

CREATE VIEW trna2exon AS
  SELECT
    feature_relationship_id,
    subject_id AS exon_id,
    object_id AS trna_id,
    subject_id,
    object_id,
    feature_relationship.type_id
  FROM
    exon INNER JOIN feature_relationship ON (exon.feature_id = subject_id)
        INNER JOIN trna ON (trna.feature_id = object_id);

--- ************************************************
--- *** relation: pseudogene2exon                ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology PART-OF view           ***
--- ************************************************
---
--- Subject Type: exon
--- Object Type:  pseudogene
--- Predicate:    PART-OF

CREATE VIEW pseudogene2exon AS
  SELECT
    feature_relationship_id,
    subject_id AS exon_id,
    object_id AS pseudogene_id,
    subject_id,
    object_id,
    feature_relationship.type_id
  FROM
    exon INNER JOIN feature_relationship ON (exon.feature_id = subject_id)
        INNER JOIN pseudogene ON (pseudogene.feature_id = object_id);

--- ************************************************
--- *** relation: gene2mrna                      ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology PART-OF view           ***
--- ************************************************
---
--- Subject Type: mrna
--- Object Type:  gene
--- Predicate:    PART-OF

CREATE VIEW gene2mrna AS
  SELECT
    feature_relationship_id,
    subject_id AS mrna_id,
    object_id AS gene_id,
    subject_id,
    object_id,
    feature_relationship.type_id
  FROM
    mrna INNER JOIN feature_relationship ON (mrna.feature_id = subject_id)
        INNER JOIN gene ON (gene.feature_id = object_id);

--- ************************************************
--- *** relation: gene2ncrna                     ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology PART-OF view           ***
--- ************************************************
---
--- Subject Type: ncrna
--- Object Type:  gene
--- Predicate:    PART-OF

CREATE VIEW gene2ncrna AS
  SELECT
    feature_relationship_id,
    subject_id AS ncrna_id,
    object_id AS gene_id,
    subject_id,
    object_id,
    feature_relationship.type_id
  FROM
    ncrna INNER JOIN feature_relationship ON (ncrna.feature_id = subject_id)
        INNER JOIN gene ON (gene.feature_id = object_id);

--- ************************************************
--- *** relation: gene2snorna                    ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology PART-OF view           ***
--- ************************************************
---
--- Subject Type: snorna
--- Object Type:  gene
--- Predicate:    PART-OF

CREATE VIEW gene2snorna AS
  SELECT
    feature_relationship_id,
    subject_id AS snorna_id,
    object_id AS gene_id,
    subject_id,
    object_id,
    feature_relationship.type_id
  FROM
    snorna INNER JOIN feature_relationship ON (snorna.feature_id = subject_id)
        INNER JOIN gene ON (gene.feature_id = object_id);

--- ************************************************
--- *** relation: gene2snrna                     ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology PART-OF view           ***
--- ************************************************
---
--- Subject Type: snrna
--- Object Type:  gene
--- Predicate:    PART-OF

CREATE VIEW gene2snrna AS
  SELECT
    feature_relationship_id,
    subject_id AS snrna_id,
    object_id AS gene_id,
    subject_id,
    object_id,
    feature_relationship.type_id
  FROM
    snrna INNER JOIN feature_relationship ON (snrna.feature_id = subject_id)
        INNER JOIN gene ON (gene.feature_id = object_id);

--- ************************************************
--- *** relation: gene2trna                      ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology PART-OF view           ***
--- ************************************************
---
--- Subject Type: trna
--- Object Type:  gene
--- Predicate:    PART-OF

CREATE VIEW gene2trna AS
  SELECT
    feature_relationship_id,
    subject_id AS trna_id,
    object_id AS gene_id,
    subject_id,
    object_id,
    feature_relationship.type_id
  FROM
    trna INNER JOIN feature_relationship ON (trna.feature_id = subject_id)
        INNER JOIN gene ON (gene.feature_id = object_id);

--- ************************************************
--- *** relation: match2match                    ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology PART-OF view           ***
--- ************************************************
---
--- Subject Type: match
--- Object Type:  match
--- Predicate:    PART-OF

CREATE VIEW match2match AS
  SELECT
    feature_relationship_id,
    subject_id AS match_id,
    object_id AS match_id,
    subject_id,
    object_id,
    feature_relationship.type_id
  FROM
    match INNER JOIN feature_relationship ON (match.feature_id = subject_id)
        INNER JOIN match ON (match.feature_id = object_id);

--- ************************************************
--- *** relation: chromosome_arm2g_path_region   ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology PART-OF view           ***
--- ************************************************
---
--- Subject Type: g_path_region
--- Object Type:  chromosome_arm
--- Predicate:    PART-OF

CREATE VIEW chromosome_arm2g_path_region AS
  SELECT
    feature_relationship_id,
    subject_id AS g_path_region_id,
    object_id AS chromosome_arm_id,
    subject_id,
    object_id,
    feature_relationship.type_id
  FROM
    g_path_region INNER JOIN feature_relationship ON (g_path_region.feature_id = subject_id)
        INNER JOIN chromosome_arm ON (chromosome_arm.feature_id = object_id);

--- ************************************************
--- *** relation: gene2pseudogene                ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology PART-OF view           ***
--- ************************************************
---
--- Subject Type: pseudogene
--- Object Type:  gene
--- Predicate:    PART-OF

CREATE VIEW gene2pseudogene AS
  SELECT
    feature_relationship_id,
    subject_id AS pseudogene_id,
    object_id AS gene_id,
    subject_id,
    object_id,
    feature_relationship.type_id
  FROM
    pseudogene INNER JOIN feature_relationship ON (pseudogene.feature_id = subject_id)
        INNER JOIN gene ON (gene.feature_id = object_id);

--- ************************************************
--- *** relation: mrna2protein                   ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology PART-OF view           ***
--- ************************************************
---
--- Subject Type: protein
--- Object Type:  mrna
--- Predicate:    PART-OF

CREATE VIEW mrna2protein AS
  SELECT
    feature_relationship_id,
    subject_id AS protein_id,
    object_id AS mrna_id,
    subject_id,
    object_id,
    feature_relationship.type_id
  FROM
    protein INNER JOIN feature_relationship ON (protein.feature_id = subject_id)
        INNER JOIN mrna ON (mrna.feature_id = object_id);

