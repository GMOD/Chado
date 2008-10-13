CREATE SCHEMA so;
SET search_path=so,public,pg_catalog;

--- ************************************************
--- *** relation: region                         ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology 'Typed Feature' View   ***
--- ***                                          ***
--- ************************************************
---
--- SO Term:
--- "region"

CREATE VIEW region AS
  SELECT
    feature_id AS region_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'region';

--- ************************************************
--- *** relation: sib_region                     ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Sibling View   ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "region"
CREATE VIEW sib_region AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    region1.feature_id AS feature_id1,
    region1.dbxref_id AS dbxref_id1,
    region1.organism_id AS organism_id1,
    region1.name AS name1,
    region1.uniquename AS uniquename1,
    region1.residues AS residues1,
    region1.seqlen AS seqlen1,
    region1.md5checksum AS md5checksum1,
    region1.type_id AS type_id1,
    region1.is_analysis AS is_analysis1,
    region1.timeaccessioned AS timeaccessioned1,
    region1.timelastmodified AS timelastmodified1,
    region2.feature_id AS feature_id2,
    region2.dbxref_id AS dbxref_id2,
    region2.organism_id AS organism_id2,
    region2.name AS name2,
    region2.uniquename AS uniquename2,
    region2.residues AS residues2,
    region2.seqlen AS seqlen2,
    region2.md5checksum AS md5checksum2,
    region2.type_id AS type_id2,
    region2.is_analysis AS is_analysis2,
    region2.timeaccessioned AS timeaccessioned2,
    region2.timelastmodified AS timelastmodified2
  FROM
    region AS region1 INNER JOIN
    feature_relationship AS fr1 ON (region1.region_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    region AS region2 ON (region1.region_id = fr2.subject_id)
;

--- ************************************************
--- *** relation: region_invsib                  ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "region"
CREATE VIEW region_invsib AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    region1.feature_id AS feature_id1,
    region1.dbxref_id AS dbxref_id1,
    region1.organism_id AS organism_id1,
    region1.name AS name1,
    region1.uniquename AS uniquename1,
    region1.residues AS residues1,
    region1.seqlen AS seqlen1,
    region1.md5checksum AS md5checksum1,
    region1.type_id AS type_id1,
    region1.is_analysis AS is_analysis1,
    region1.timeaccessioned AS timeaccessioned1,
    region1.timelastmodified AS timelastmodified1,
    region2.feature_id AS feature_id2,
    region2.dbxref_id AS dbxref_id2,
    region2.organism_id AS organism_id2,
    region2.name AS name2,
    region2.uniquename AS uniquename2,
    region2.residues AS residues2,
    region2.seqlen AS seqlen2,
    region2.md5checksum AS md5checksum2,
    region2.type_id AS type_id2,
    region2.is_analysis AS is_analysis2,
    region2.timeaccessioned AS timeaccessioned2,
    region2.timelastmodified AS timelastmodified2
  FROM
    region AS region1 INNER JOIN
    feature_relationship AS fr1 ON (region1.region_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    region AS region2 ON (region1.region_id = fr2.object_id);


--- ************************************************
--- *** relation: csib_region                    ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Sibling View   ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "region"
CREATE VIEW csib_region AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    region1.feature_id AS feature_id1,
    region1.dbxref_id AS dbxref_id1,
    region1.organism_id AS organism_id1,
    region1.name AS name1,
    region1.uniquename AS uniquename1,
    region1.residues AS residues1,
    region1.seqlen AS seqlen1,
    region1.md5checksum AS md5checksum1,
    region1.type_id AS type_id1,
    region1.is_analysis AS is_analysis1,
    region1.timeaccessioned AS timeaccessioned1,
    region1.timelastmodified AS timelastmodified1,
    region2.feature_id AS feature_id2,
    region2.dbxref_id AS dbxref_id2,
    region2.organism_id AS organism_id2,
    region2.name AS name2,
    region2.uniquename AS uniquename2,
    region2.residues AS residues2,
    region2.seqlen AS seqlen2,
    region2.md5checksum AS md5checksum2,
    region2.type_id AS type_id2,
    region2.is_analysis AS is_analysis2,
    region2.timeaccessioned AS timeaccessioned2,
    region2.timelastmodified AS timelastmodified2
  FROM
    region AS region1 INNER JOIN
    feature_relationship AS fr1 ON (region1.region_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    region AS region2 ON (region1.region_id = fr2.subject_id)
  WHERE fr2.rank - fr1.rank = 1
;

--- ************************************************
--- *** relation: cregion_invsib                 ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "region"
CREATE VIEW cregion_invsib AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    region1.feature_id AS feature_id1,
    region1.dbxref_id AS dbxref_id1,
    region1.organism_id AS organism_id1,
    region1.name AS name1,
    region1.uniquename AS uniquename1,
    region1.residues AS residues1,
    region1.seqlen AS seqlen1,
    region1.md5checksum AS md5checksum1,
    region1.type_id AS type_id1,
    region1.is_analysis AS is_analysis1,
    region1.timeaccessioned AS timeaccessioned1,
    region1.timelastmodified AS timelastmodified1,
    region2.feature_id AS feature_id2,
    region2.dbxref_id AS dbxref_id2,
    region2.organism_id AS organism_id2,
    region2.name AS name2,
    region2.uniquename AS uniquename2,
    region2.residues AS residues2,
    region2.seqlen AS seqlen2,
    region2.md5checksum AS md5checksum2,
    region2.type_id AS type_id2,
    region2.is_analysis AS is_analysis2,
    region2.timeaccessioned AS timeaccessioned2,
    region2.timelastmodified AS timelastmodified2
  FROM
    region AS region1 INNER JOIN
    feature_relationship AS fr1 ON (region1.region_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    region AS region2 ON (region1.region_id = fr2.object_id);


--- ************************************************
--- *** relation: transposable_element_gene      ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology 'Typed Feature' View   ***
--- ***                                          ***
--- ************************************************
---
--- SO Term:
--- "transposable_element_gene"

CREATE VIEW transposable_element_gene AS
  SELECT
    feature_id AS transposable_element_gene_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'transposable_element_gene';

--- ************************************************
--- *** relation: sib_transposable_element_gene  ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Sibling View   ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "transposable_element_gene"
CREATE VIEW sib_transposable_element_gene AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    transposable_element_gene1.feature_id AS feature_id1,
    transposable_element_gene1.dbxref_id AS dbxref_id1,
    transposable_element_gene1.organism_id AS organism_id1,
    transposable_element_gene1.name AS name1,
    transposable_element_gene1.uniquename AS uniquename1,
    transposable_element_gene1.residues AS residues1,
    transposable_element_gene1.seqlen AS seqlen1,
    transposable_element_gene1.md5checksum AS md5checksum1,
    transposable_element_gene1.type_id AS type_id1,
    transposable_element_gene1.is_analysis AS is_analysis1,
    transposable_element_gene1.timeaccessioned AS timeaccessioned1,
    transposable_element_gene1.timelastmodified AS timelastmodified1,
    transposable_element_gene2.feature_id AS feature_id2,
    transposable_element_gene2.dbxref_id AS dbxref_id2,
    transposable_element_gene2.organism_id AS organism_id2,
    transposable_element_gene2.name AS name2,
    transposable_element_gene2.uniquename AS uniquename2,
    transposable_element_gene2.residues AS residues2,
    transposable_element_gene2.seqlen AS seqlen2,
    transposable_element_gene2.md5checksum AS md5checksum2,
    transposable_element_gene2.type_id AS type_id2,
    transposable_element_gene2.is_analysis AS is_analysis2,
    transposable_element_gene2.timeaccessioned AS timeaccessioned2,
    transposable_element_gene2.timelastmodified AS timelastmodified2
  FROM
    transposable_element_gene AS transposable_element_gene1 INNER JOIN
    feature_relationship AS fr1 ON (transposable_element_gene1.transposable_element_gene_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    transposable_element_gene AS transposable_element_gene2 ON (transposable_element_gene1.transposable_element_gene_id = fr2.subject_id)
;

--- ************************************************
--- *** relation: transposable_element_gene_invsib***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "transposable_element_gene"
CREATE VIEW transposable_element_gene_invsib AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    transposable_element_gene1.feature_id AS feature_id1,
    transposable_element_gene1.dbxref_id AS dbxref_id1,
    transposable_element_gene1.organism_id AS organism_id1,
    transposable_element_gene1.name AS name1,
    transposable_element_gene1.uniquename AS uniquename1,
    transposable_element_gene1.residues AS residues1,
    transposable_element_gene1.seqlen AS seqlen1,
    transposable_element_gene1.md5checksum AS md5checksum1,
    transposable_element_gene1.type_id AS type_id1,
    transposable_element_gene1.is_analysis AS is_analysis1,
    transposable_element_gene1.timeaccessioned AS timeaccessioned1,
    transposable_element_gene1.timelastmodified AS timelastmodified1,
    transposable_element_gene2.feature_id AS feature_id2,
    transposable_element_gene2.dbxref_id AS dbxref_id2,
    transposable_element_gene2.organism_id AS organism_id2,
    transposable_element_gene2.name AS name2,
    transposable_element_gene2.uniquename AS uniquename2,
    transposable_element_gene2.residues AS residues2,
    transposable_element_gene2.seqlen AS seqlen2,
    transposable_element_gene2.md5checksum AS md5checksum2,
    transposable_element_gene2.type_id AS type_id2,
    transposable_element_gene2.is_analysis AS is_analysis2,
    transposable_element_gene2.timeaccessioned AS timeaccessioned2,
    transposable_element_gene2.timelastmodified AS timelastmodified2
  FROM
    transposable_element_gene AS transposable_element_gene1 INNER JOIN
    feature_relationship AS fr1 ON (transposable_element_gene1.transposable_element_gene_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    transposable_element_gene AS transposable_element_gene2 ON (transposable_element_gene1.transposable_element_gene_id = fr2.object_id);


--- ************************************************
--- *** relation: csib_transposable_element_gene ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Sibling View   ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "transposable_element_gene"
CREATE VIEW csib_transposable_element_gene AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    transposable_element_gene1.feature_id AS feature_id1,
    transposable_element_gene1.dbxref_id AS dbxref_id1,
    transposable_element_gene1.organism_id AS organism_id1,
    transposable_element_gene1.name AS name1,
    transposable_element_gene1.uniquename AS uniquename1,
    transposable_element_gene1.residues AS residues1,
    transposable_element_gene1.seqlen AS seqlen1,
    transposable_element_gene1.md5checksum AS md5checksum1,
    transposable_element_gene1.type_id AS type_id1,
    transposable_element_gene1.is_analysis AS is_analysis1,
    transposable_element_gene1.timeaccessioned AS timeaccessioned1,
    transposable_element_gene1.timelastmodified AS timelastmodified1,
    transposable_element_gene2.feature_id AS feature_id2,
    transposable_element_gene2.dbxref_id AS dbxref_id2,
    transposable_element_gene2.organism_id AS organism_id2,
    transposable_element_gene2.name AS name2,
    transposable_element_gene2.uniquename AS uniquename2,
    transposable_element_gene2.residues AS residues2,
    transposable_element_gene2.seqlen AS seqlen2,
    transposable_element_gene2.md5checksum AS md5checksum2,
    transposable_element_gene2.type_id AS type_id2,
    transposable_element_gene2.is_analysis AS is_analysis2,
    transposable_element_gene2.timeaccessioned AS timeaccessioned2,
    transposable_element_gene2.timelastmodified AS timelastmodified2
  FROM
    transposable_element_gene AS transposable_element_gene1 INNER JOIN
    feature_relationship AS fr1 ON (transposable_element_gene1.transposable_element_gene_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    transposable_element_gene AS transposable_element_gene2 ON (transposable_element_gene1.transposable_element_gene_id = fr2.subject_id)
  WHERE fr2.rank - fr1.rank = 1
;

--- ************************************************
--- *** relation: ctransposable_element_gene_invsib***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "transposable_element_gene"
CREATE VIEW ctransposable_element_gene_invsib AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    transposable_element_gene1.feature_id AS feature_id1,
    transposable_element_gene1.dbxref_id AS dbxref_id1,
    transposable_element_gene1.organism_id AS organism_id1,
    transposable_element_gene1.name AS name1,
    transposable_element_gene1.uniquename AS uniquename1,
    transposable_element_gene1.residues AS residues1,
    transposable_element_gene1.seqlen AS seqlen1,
    transposable_element_gene1.md5checksum AS md5checksum1,
    transposable_element_gene1.type_id AS type_id1,
    transposable_element_gene1.is_analysis AS is_analysis1,
    transposable_element_gene1.timeaccessioned AS timeaccessioned1,
    transposable_element_gene1.timelastmodified AS timelastmodified1,
    transposable_element_gene2.feature_id AS feature_id2,
    transposable_element_gene2.dbxref_id AS dbxref_id2,
    transposable_element_gene2.organism_id AS organism_id2,
    transposable_element_gene2.name AS name2,
    transposable_element_gene2.uniquename AS uniquename2,
    transposable_element_gene2.residues AS residues2,
    transposable_element_gene2.seqlen AS seqlen2,
    transposable_element_gene2.md5checksum AS md5checksum2,
    transposable_element_gene2.type_id AS type_id2,
    transposable_element_gene2.is_analysis AS is_analysis2,
    transposable_element_gene2.timeaccessioned AS timeaccessioned2,
    transposable_element_gene2.timelastmodified AS timelastmodified2
  FROM
    transposable_element_gene AS transposable_element_gene1 INNER JOIN
    feature_relationship AS fr1 ON (transposable_element_gene1.transposable_element_gene_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    transposable_element_gene AS transposable_element_gene2 ON (transposable_element_gene1.transposable_element_gene_id = fr2.object_id);


--- ************************************************
--- *** relation: ltr_retrotransposon            ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology 'Typed Feature' View   ***
--- ***                                          ***
--- ************************************************
---
--- SO Term:
--- "LTR_retrotransposon"

CREATE VIEW ltr_retrotransposon AS
  SELECT
    feature_id AS ltr_retrotransposon_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'LTR_retrotransposon';

--- ************************************************
--- *** relation: sib_ltr_retrotransposon        ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Sibling View   ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "LTR_retrotransposon"
CREATE VIEW sib_ltr_retrotransposon AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    ltr_retrotransposon1.feature_id AS feature_id1,
    ltr_retrotransposon1.dbxref_id AS dbxref_id1,
    ltr_retrotransposon1.organism_id AS organism_id1,
    ltr_retrotransposon1.name AS name1,
    ltr_retrotransposon1.uniquename AS uniquename1,
    ltr_retrotransposon1.residues AS residues1,
    ltr_retrotransposon1.seqlen AS seqlen1,
    ltr_retrotransposon1.md5checksum AS md5checksum1,
    ltr_retrotransposon1.type_id AS type_id1,
    ltr_retrotransposon1.is_analysis AS is_analysis1,
    ltr_retrotransposon1.timeaccessioned AS timeaccessioned1,
    ltr_retrotransposon1.timelastmodified AS timelastmodified1,
    ltr_retrotransposon2.feature_id AS feature_id2,
    ltr_retrotransposon2.dbxref_id AS dbxref_id2,
    ltr_retrotransposon2.organism_id AS organism_id2,
    ltr_retrotransposon2.name AS name2,
    ltr_retrotransposon2.uniquename AS uniquename2,
    ltr_retrotransposon2.residues AS residues2,
    ltr_retrotransposon2.seqlen AS seqlen2,
    ltr_retrotransposon2.md5checksum AS md5checksum2,
    ltr_retrotransposon2.type_id AS type_id2,
    ltr_retrotransposon2.is_analysis AS is_analysis2,
    ltr_retrotransposon2.timeaccessioned AS timeaccessioned2,
    ltr_retrotransposon2.timelastmodified AS timelastmodified2
  FROM
    ltr_retrotransposon AS ltr_retrotransposon1 INNER JOIN
    feature_relationship AS fr1 ON (ltr_retrotransposon1.ltr_retrotransposon_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    ltr_retrotransposon AS ltr_retrotransposon2 ON (ltr_retrotransposon1.ltr_retrotransposon_id = fr2.subject_id)
;

--- ************************************************
--- *** relation: ltr_retrotransposon_invsib     ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "LTR_retrotransposon"
CREATE VIEW ltr_retrotransposon_invsib AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    ltr_retrotransposon1.feature_id AS feature_id1,
    ltr_retrotransposon1.dbxref_id AS dbxref_id1,
    ltr_retrotransposon1.organism_id AS organism_id1,
    ltr_retrotransposon1.name AS name1,
    ltr_retrotransposon1.uniquename AS uniquename1,
    ltr_retrotransposon1.residues AS residues1,
    ltr_retrotransposon1.seqlen AS seqlen1,
    ltr_retrotransposon1.md5checksum AS md5checksum1,
    ltr_retrotransposon1.type_id AS type_id1,
    ltr_retrotransposon1.is_analysis AS is_analysis1,
    ltr_retrotransposon1.timeaccessioned AS timeaccessioned1,
    ltr_retrotransposon1.timelastmodified AS timelastmodified1,
    ltr_retrotransposon2.feature_id AS feature_id2,
    ltr_retrotransposon2.dbxref_id AS dbxref_id2,
    ltr_retrotransposon2.organism_id AS organism_id2,
    ltr_retrotransposon2.name AS name2,
    ltr_retrotransposon2.uniquename AS uniquename2,
    ltr_retrotransposon2.residues AS residues2,
    ltr_retrotransposon2.seqlen AS seqlen2,
    ltr_retrotransposon2.md5checksum AS md5checksum2,
    ltr_retrotransposon2.type_id AS type_id2,
    ltr_retrotransposon2.is_analysis AS is_analysis2,
    ltr_retrotransposon2.timeaccessioned AS timeaccessioned2,
    ltr_retrotransposon2.timelastmodified AS timelastmodified2
  FROM
    ltr_retrotransposon AS ltr_retrotransposon1 INNER JOIN
    feature_relationship AS fr1 ON (ltr_retrotransposon1.ltr_retrotransposon_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    ltr_retrotransposon AS ltr_retrotransposon2 ON (ltr_retrotransposon1.ltr_retrotransposon_id = fr2.object_id);


--- ************************************************
--- *** relation: csib_ltr_retrotransposon       ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Sibling View   ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "LTR_retrotransposon"
CREATE VIEW csib_ltr_retrotransposon AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    ltr_retrotransposon1.feature_id AS feature_id1,
    ltr_retrotransposon1.dbxref_id AS dbxref_id1,
    ltr_retrotransposon1.organism_id AS organism_id1,
    ltr_retrotransposon1.name AS name1,
    ltr_retrotransposon1.uniquename AS uniquename1,
    ltr_retrotransposon1.residues AS residues1,
    ltr_retrotransposon1.seqlen AS seqlen1,
    ltr_retrotransposon1.md5checksum AS md5checksum1,
    ltr_retrotransposon1.type_id AS type_id1,
    ltr_retrotransposon1.is_analysis AS is_analysis1,
    ltr_retrotransposon1.timeaccessioned AS timeaccessioned1,
    ltr_retrotransposon1.timelastmodified AS timelastmodified1,
    ltr_retrotransposon2.feature_id AS feature_id2,
    ltr_retrotransposon2.dbxref_id AS dbxref_id2,
    ltr_retrotransposon2.organism_id AS organism_id2,
    ltr_retrotransposon2.name AS name2,
    ltr_retrotransposon2.uniquename AS uniquename2,
    ltr_retrotransposon2.residues AS residues2,
    ltr_retrotransposon2.seqlen AS seqlen2,
    ltr_retrotransposon2.md5checksum AS md5checksum2,
    ltr_retrotransposon2.type_id AS type_id2,
    ltr_retrotransposon2.is_analysis AS is_analysis2,
    ltr_retrotransposon2.timeaccessioned AS timeaccessioned2,
    ltr_retrotransposon2.timelastmodified AS timelastmodified2
  FROM
    ltr_retrotransposon AS ltr_retrotransposon1 INNER JOIN
    feature_relationship AS fr1 ON (ltr_retrotransposon1.ltr_retrotransposon_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    ltr_retrotransposon AS ltr_retrotransposon2 ON (ltr_retrotransposon1.ltr_retrotransposon_id = fr2.subject_id)
  WHERE fr2.rank - fr1.rank = 1
;

--- ************************************************
--- *** relation: cltr_retrotransposon_invsib    ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "LTR_retrotransposon"
CREATE VIEW cltr_retrotransposon_invsib AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    ltr_retrotransposon1.feature_id AS feature_id1,
    ltr_retrotransposon1.dbxref_id AS dbxref_id1,
    ltr_retrotransposon1.organism_id AS organism_id1,
    ltr_retrotransposon1.name AS name1,
    ltr_retrotransposon1.uniquename AS uniquename1,
    ltr_retrotransposon1.residues AS residues1,
    ltr_retrotransposon1.seqlen AS seqlen1,
    ltr_retrotransposon1.md5checksum AS md5checksum1,
    ltr_retrotransposon1.type_id AS type_id1,
    ltr_retrotransposon1.is_analysis AS is_analysis1,
    ltr_retrotransposon1.timeaccessioned AS timeaccessioned1,
    ltr_retrotransposon1.timelastmodified AS timelastmodified1,
    ltr_retrotransposon2.feature_id AS feature_id2,
    ltr_retrotransposon2.dbxref_id AS dbxref_id2,
    ltr_retrotransposon2.organism_id AS organism_id2,
    ltr_retrotransposon2.name AS name2,
    ltr_retrotransposon2.uniquename AS uniquename2,
    ltr_retrotransposon2.residues AS residues2,
    ltr_retrotransposon2.seqlen AS seqlen2,
    ltr_retrotransposon2.md5checksum AS md5checksum2,
    ltr_retrotransposon2.type_id AS type_id2,
    ltr_retrotransposon2.is_analysis AS is_analysis2,
    ltr_retrotransposon2.timeaccessioned AS timeaccessioned2,
    ltr_retrotransposon2.timelastmodified AS timelastmodified2
  FROM
    ltr_retrotransposon AS ltr_retrotransposon1 INNER JOIN
    feature_relationship AS fr1 ON (ltr_retrotransposon1.ltr_retrotransposon_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    ltr_retrotransposon AS ltr_retrotransposon2 ON (ltr_retrotransposon1.ltr_retrotransposon_id = fr2.object_id);


--- ************************************************
--- *** relation: intron                         ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology 'Typed Feature' View   ***
--- ***                                          ***
--- ************************************************
---
--- SO Term:
--- "intron"

CREATE VIEW intron AS
  SELECT
    feature_id AS intron_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'intron';

--- ************************************************
--- *** relation: sib_intron                     ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Sibling View   ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "intron"
CREATE VIEW sib_intron AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    intron1.feature_id AS feature_id1,
    intron1.dbxref_id AS dbxref_id1,
    intron1.organism_id AS organism_id1,
    intron1.name AS name1,
    intron1.uniquename AS uniquename1,
    intron1.residues AS residues1,
    intron1.seqlen AS seqlen1,
    intron1.md5checksum AS md5checksum1,
    intron1.type_id AS type_id1,
    intron1.is_analysis AS is_analysis1,
    intron1.timeaccessioned AS timeaccessioned1,
    intron1.timelastmodified AS timelastmodified1,
    intron2.feature_id AS feature_id2,
    intron2.dbxref_id AS dbxref_id2,
    intron2.organism_id AS organism_id2,
    intron2.name AS name2,
    intron2.uniquename AS uniquename2,
    intron2.residues AS residues2,
    intron2.seqlen AS seqlen2,
    intron2.md5checksum AS md5checksum2,
    intron2.type_id AS type_id2,
    intron2.is_analysis AS is_analysis2,
    intron2.timeaccessioned AS timeaccessioned2,
    intron2.timelastmodified AS timelastmodified2
  FROM
    intron AS intron1 INNER JOIN
    feature_relationship AS fr1 ON (intron1.intron_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    intron AS intron2 ON (intron1.intron_id = fr2.subject_id)
;

--- ************************************************
--- *** relation: intron_invsib                  ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "intron"
CREATE VIEW intron_invsib AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    intron1.feature_id AS feature_id1,
    intron1.dbxref_id AS dbxref_id1,
    intron1.organism_id AS organism_id1,
    intron1.name AS name1,
    intron1.uniquename AS uniquename1,
    intron1.residues AS residues1,
    intron1.seqlen AS seqlen1,
    intron1.md5checksum AS md5checksum1,
    intron1.type_id AS type_id1,
    intron1.is_analysis AS is_analysis1,
    intron1.timeaccessioned AS timeaccessioned1,
    intron1.timelastmodified AS timelastmodified1,
    intron2.feature_id AS feature_id2,
    intron2.dbxref_id AS dbxref_id2,
    intron2.organism_id AS organism_id2,
    intron2.name AS name2,
    intron2.uniquename AS uniquename2,
    intron2.residues AS residues2,
    intron2.seqlen AS seqlen2,
    intron2.md5checksum AS md5checksum2,
    intron2.type_id AS type_id2,
    intron2.is_analysis AS is_analysis2,
    intron2.timeaccessioned AS timeaccessioned2,
    intron2.timelastmodified AS timelastmodified2
  FROM
    intron AS intron1 INNER JOIN
    feature_relationship AS fr1 ON (intron1.intron_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    intron AS intron2 ON (intron1.intron_id = fr2.object_id);


--- ************************************************
--- *** relation: csib_intron                    ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Sibling View   ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "intron"
CREATE VIEW csib_intron AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    intron1.feature_id AS feature_id1,
    intron1.dbxref_id AS dbxref_id1,
    intron1.organism_id AS organism_id1,
    intron1.name AS name1,
    intron1.uniquename AS uniquename1,
    intron1.residues AS residues1,
    intron1.seqlen AS seqlen1,
    intron1.md5checksum AS md5checksum1,
    intron1.type_id AS type_id1,
    intron1.is_analysis AS is_analysis1,
    intron1.timeaccessioned AS timeaccessioned1,
    intron1.timelastmodified AS timelastmodified1,
    intron2.feature_id AS feature_id2,
    intron2.dbxref_id AS dbxref_id2,
    intron2.organism_id AS organism_id2,
    intron2.name AS name2,
    intron2.uniquename AS uniquename2,
    intron2.residues AS residues2,
    intron2.seqlen AS seqlen2,
    intron2.md5checksum AS md5checksum2,
    intron2.type_id AS type_id2,
    intron2.is_analysis AS is_analysis2,
    intron2.timeaccessioned AS timeaccessioned2,
    intron2.timelastmodified AS timelastmodified2
  FROM
    intron AS intron1 INNER JOIN
    feature_relationship AS fr1 ON (intron1.intron_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    intron AS intron2 ON (intron1.intron_id = fr2.subject_id)
  WHERE fr2.rank - fr1.rank = 1
;

--- ************************************************
--- *** relation: cintron_invsib                 ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "intron"
CREATE VIEW cintron_invsib AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    intron1.feature_id AS feature_id1,
    intron1.dbxref_id AS dbxref_id1,
    intron1.organism_id AS organism_id1,
    intron1.name AS name1,
    intron1.uniquename AS uniquename1,
    intron1.residues AS residues1,
    intron1.seqlen AS seqlen1,
    intron1.md5checksum AS md5checksum1,
    intron1.type_id AS type_id1,
    intron1.is_analysis AS is_analysis1,
    intron1.timeaccessioned AS timeaccessioned1,
    intron1.timelastmodified AS timelastmodified1,
    intron2.feature_id AS feature_id2,
    intron2.dbxref_id AS dbxref_id2,
    intron2.organism_id AS organism_id2,
    intron2.name AS name2,
    intron2.uniquename AS uniquename2,
    intron2.residues AS residues2,
    intron2.seqlen AS seqlen2,
    intron2.md5checksum AS md5checksum2,
    intron2.type_id AS type_id2,
    intron2.is_analysis AS is_analysis2,
    intron2.timeaccessioned AS timeaccessioned2,
    intron2.timelastmodified AS timelastmodified2
  FROM
    intron AS intron1 INNER JOIN
    feature_relationship AS fr1 ON (intron1.intron_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    intron AS intron2 ON (intron1.intron_id = fr2.object_id);


--- ************************************************
--- *** relation: noncoding_exon                 ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology 'Typed Feature' View   ***
--- ***                                          ***
--- ************************************************
---
--- SO Term:
--- "noncoding_exon"

CREATE VIEW noncoding_exon AS
  SELECT
    feature_id AS noncoding_exon_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'noncoding_exon';

--- ************************************************
--- *** relation: sib_noncoding_exon             ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Sibling View   ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "noncoding_exon"
CREATE VIEW sib_noncoding_exon AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    noncoding_exon1.feature_id AS feature_id1,
    noncoding_exon1.dbxref_id AS dbxref_id1,
    noncoding_exon1.organism_id AS organism_id1,
    noncoding_exon1.name AS name1,
    noncoding_exon1.uniquename AS uniquename1,
    noncoding_exon1.residues AS residues1,
    noncoding_exon1.seqlen AS seqlen1,
    noncoding_exon1.md5checksum AS md5checksum1,
    noncoding_exon1.type_id AS type_id1,
    noncoding_exon1.is_analysis AS is_analysis1,
    noncoding_exon1.timeaccessioned AS timeaccessioned1,
    noncoding_exon1.timelastmodified AS timelastmodified1,
    noncoding_exon2.feature_id AS feature_id2,
    noncoding_exon2.dbxref_id AS dbxref_id2,
    noncoding_exon2.organism_id AS organism_id2,
    noncoding_exon2.name AS name2,
    noncoding_exon2.uniquename AS uniquename2,
    noncoding_exon2.residues AS residues2,
    noncoding_exon2.seqlen AS seqlen2,
    noncoding_exon2.md5checksum AS md5checksum2,
    noncoding_exon2.type_id AS type_id2,
    noncoding_exon2.is_analysis AS is_analysis2,
    noncoding_exon2.timeaccessioned AS timeaccessioned2,
    noncoding_exon2.timelastmodified AS timelastmodified2
  FROM
    noncoding_exon AS noncoding_exon1 INNER JOIN
    feature_relationship AS fr1 ON (noncoding_exon1.noncoding_exon_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    noncoding_exon AS noncoding_exon2 ON (noncoding_exon1.noncoding_exon_id = fr2.subject_id)
;

--- ************************************************
--- *** relation: noncoding_exon_invsib          ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "noncoding_exon"
CREATE VIEW noncoding_exon_invsib AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    noncoding_exon1.feature_id AS feature_id1,
    noncoding_exon1.dbxref_id AS dbxref_id1,
    noncoding_exon1.organism_id AS organism_id1,
    noncoding_exon1.name AS name1,
    noncoding_exon1.uniquename AS uniquename1,
    noncoding_exon1.residues AS residues1,
    noncoding_exon1.seqlen AS seqlen1,
    noncoding_exon1.md5checksum AS md5checksum1,
    noncoding_exon1.type_id AS type_id1,
    noncoding_exon1.is_analysis AS is_analysis1,
    noncoding_exon1.timeaccessioned AS timeaccessioned1,
    noncoding_exon1.timelastmodified AS timelastmodified1,
    noncoding_exon2.feature_id AS feature_id2,
    noncoding_exon2.dbxref_id AS dbxref_id2,
    noncoding_exon2.organism_id AS organism_id2,
    noncoding_exon2.name AS name2,
    noncoding_exon2.uniquename AS uniquename2,
    noncoding_exon2.residues AS residues2,
    noncoding_exon2.seqlen AS seqlen2,
    noncoding_exon2.md5checksum AS md5checksum2,
    noncoding_exon2.type_id AS type_id2,
    noncoding_exon2.is_analysis AS is_analysis2,
    noncoding_exon2.timeaccessioned AS timeaccessioned2,
    noncoding_exon2.timelastmodified AS timelastmodified2
  FROM
    noncoding_exon AS noncoding_exon1 INNER JOIN
    feature_relationship AS fr1 ON (noncoding_exon1.noncoding_exon_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    noncoding_exon AS noncoding_exon2 ON (noncoding_exon1.noncoding_exon_id = fr2.object_id);


--- ************************************************
--- *** relation: csib_noncoding_exon            ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Sibling View   ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "noncoding_exon"
CREATE VIEW csib_noncoding_exon AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    noncoding_exon1.feature_id AS feature_id1,
    noncoding_exon1.dbxref_id AS dbxref_id1,
    noncoding_exon1.organism_id AS organism_id1,
    noncoding_exon1.name AS name1,
    noncoding_exon1.uniquename AS uniquename1,
    noncoding_exon1.residues AS residues1,
    noncoding_exon1.seqlen AS seqlen1,
    noncoding_exon1.md5checksum AS md5checksum1,
    noncoding_exon1.type_id AS type_id1,
    noncoding_exon1.is_analysis AS is_analysis1,
    noncoding_exon1.timeaccessioned AS timeaccessioned1,
    noncoding_exon1.timelastmodified AS timelastmodified1,
    noncoding_exon2.feature_id AS feature_id2,
    noncoding_exon2.dbxref_id AS dbxref_id2,
    noncoding_exon2.organism_id AS organism_id2,
    noncoding_exon2.name AS name2,
    noncoding_exon2.uniquename AS uniquename2,
    noncoding_exon2.residues AS residues2,
    noncoding_exon2.seqlen AS seqlen2,
    noncoding_exon2.md5checksum AS md5checksum2,
    noncoding_exon2.type_id AS type_id2,
    noncoding_exon2.is_analysis AS is_analysis2,
    noncoding_exon2.timeaccessioned AS timeaccessioned2,
    noncoding_exon2.timelastmodified AS timelastmodified2
  FROM
    noncoding_exon AS noncoding_exon1 INNER JOIN
    feature_relationship AS fr1 ON (noncoding_exon1.noncoding_exon_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    noncoding_exon AS noncoding_exon2 ON (noncoding_exon1.noncoding_exon_id = fr2.subject_id)
  WHERE fr2.rank - fr1.rank = 1
;

--- ************************************************
--- *** relation: cnoncoding_exon_invsib         ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "noncoding_exon"
CREATE VIEW cnoncoding_exon_invsib AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    noncoding_exon1.feature_id AS feature_id1,
    noncoding_exon1.dbxref_id AS dbxref_id1,
    noncoding_exon1.organism_id AS organism_id1,
    noncoding_exon1.name AS name1,
    noncoding_exon1.uniquename AS uniquename1,
    noncoding_exon1.residues AS residues1,
    noncoding_exon1.seqlen AS seqlen1,
    noncoding_exon1.md5checksum AS md5checksum1,
    noncoding_exon1.type_id AS type_id1,
    noncoding_exon1.is_analysis AS is_analysis1,
    noncoding_exon1.timeaccessioned AS timeaccessioned1,
    noncoding_exon1.timelastmodified AS timelastmodified1,
    noncoding_exon2.feature_id AS feature_id2,
    noncoding_exon2.dbxref_id AS dbxref_id2,
    noncoding_exon2.organism_id AS organism_id2,
    noncoding_exon2.name AS name2,
    noncoding_exon2.uniquename AS uniquename2,
    noncoding_exon2.residues AS residues2,
    noncoding_exon2.seqlen AS seqlen2,
    noncoding_exon2.md5checksum AS md5checksum2,
    noncoding_exon2.type_id AS type_id2,
    noncoding_exon2.is_analysis AS is_analysis2,
    noncoding_exon2.timeaccessioned AS timeaccessioned2,
    noncoding_exon2.timelastmodified AS timelastmodified2
  FROM
    noncoding_exon AS noncoding_exon1 INNER JOIN
    feature_relationship AS fr1 ON (noncoding_exon1.noncoding_exon_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    noncoding_exon AS noncoding_exon2 ON (noncoding_exon1.noncoding_exon_id = fr2.object_id);


--- ************************************************
--- *** relation: rrna                           ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology 'Typed Feature' View   ***
--- ***                                          ***
--- ************************************************
---
--- SO Term:
--- "rRNA"

CREATE VIEW rrna AS
  SELECT
    feature_id AS rrna_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'rRNA';

--- ************************************************
--- *** relation: sib_rrna                       ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Sibling View   ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "rRNA"
CREATE VIEW sib_rrna AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    rrna1.feature_id AS feature_id1,
    rrna1.dbxref_id AS dbxref_id1,
    rrna1.organism_id AS organism_id1,
    rrna1.name AS name1,
    rrna1.uniquename AS uniquename1,
    rrna1.residues AS residues1,
    rrna1.seqlen AS seqlen1,
    rrna1.md5checksum AS md5checksum1,
    rrna1.type_id AS type_id1,
    rrna1.is_analysis AS is_analysis1,
    rrna1.timeaccessioned AS timeaccessioned1,
    rrna1.timelastmodified AS timelastmodified1,
    rrna2.feature_id AS feature_id2,
    rrna2.dbxref_id AS dbxref_id2,
    rrna2.organism_id AS organism_id2,
    rrna2.name AS name2,
    rrna2.uniquename AS uniquename2,
    rrna2.residues AS residues2,
    rrna2.seqlen AS seqlen2,
    rrna2.md5checksum AS md5checksum2,
    rrna2.type_id AS type_id2,
    rrna2.is_analysis AS is_analysis2,
    rrna2.timeaccessioned AS timeaccessioned2,
    rrna2.timelastmodified AS timelastmodified2
  FROM
    rrna AS rrna1 INNER JOIN
    feature_relationship AS fr1 ON (rrna1.rrna_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    rrna AS rrna2 ON (rrna1.rrna_id = fr2.subject_id)
;

--- ************************************************
--- *** relation: rrna_invsib                    ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "rRNA"
CREATE VIEW rrna_invsib AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    rrna1.feature_id AS feature_id1,
    rrna1.dbxref_id AS dbxref_id1,
    rrna1.organism_id AS organism_id1,
    rrna1.name AS name1,
    rrna1.uniquename AS uniquename1,
    rrna1.residues AS residues1,
    rrna1.seqlen AS seqlen1,
    rrna1.md5checksum AS md5checksum1,
    rrna1.type_id AS type_id1,
    rrna1.is_analysis AS is_analysis1,
    rrna1.timeaccessioned AS timeaccessioned1,
    rrna1.timelastmodified AS timelastmodified1,
    rrna2.feature_id AS feature_id2,
    rrna2.dbxref_id AS dbxref_id2,
    rrna2.organism_id AS organism_id2,
    rrna2.name AS name2,
    rrna2.uniquename AS uniquename2,
    rrna2.residues AS residues2,
    rrna2.seqlen AS seqlen2,
    rrna2.md5checksum AS md5checksum2,
    rrna2.type_id AS type_id2,
    rrna2.is_analysis AS is_analysis2,
    rrna2.timeaccessioned AS timeaccessioned2,
    rrna2.timelastmodified AS timelastmodified2
  FROM
    rrna AS rrna1 INNER JOIN
    feature_relationship AS fr1 ON (rrna1.rrna_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    rrna AS rrna2 ON (rrna1.rrna_id = fr2.object_id);


--- ************************************************
--- *** relation: csib_rrna                      ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Sibling View   ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "rRNA"
CREATE VIEW csib_rrna AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    rrna1.feature_id AS feature_id1,
    rrna1.dbxref_id AS dbxref_id1,
    rrna1.organism_id AS organism_id1,
    rrna1.name AS name1,
    rrna1.uniquename AS uniquename1,
    rrna1.residues AS residues1,
    rrna1.seqlen AS seqlen1,
    rrna1.md5checksum AS md5checksum1,
    rrna1.type_id AS type_id1,
    rrna1.is_analysis AS is_analysis1,
    rrna1.timeaccessioned AS timeaccessioned1,
    rrna1.timelastmodified AS timelastmodified1,
    rrna2.feature_id AS feature_id2,
    rrna2.dbxref_id AS dbxref_id2,
    rrna2.organism_id AS organism_id2,
    rrna2.name AS name2,
    rrna2.uniquename AS uniquename2,
    rrna2.residues AS residues2,
    rrna2.seqlen AS seqlen2,
    rrna2.md5checksum AS md5checksum2,
    rrna2.type_id AS type_id2,
    rrna2.is_analysis AS is_analysis2,
    rrna2.timeaccessioned AS timeaccessioned2,
    rrna2.timelastmodified AS timelastmodified2
  FROM
    rrna AS rrna1 INNER JOIN
    feature_relationship AS fr1 ON (rrna1.rrna_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    rrna AS rrna2 ON (rrna1.rrna_id = fr2.subject_id)
  WHERE fr2.rank - fr1.rank = 1
;

--- ************************************************
--- *** relation: crrna_invsib                   ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "rRNA"
CREATE VIEW crrna_invsib AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    rrna1.feature_id AS feature_id1,
    rrna1.dbxref_id AS dbxref_id1,
    rrna1.organism_id AS organism_id1,
    rrna1.name AS name1,
    rrna1.uniquename AS uniquename1,
    rrna1.residues AS residues1,
    rrna1.seqlen AS seqlen1,
    rrna1.md5checksum AS md5checksum1,
    rrna1.type_id AS type_id1,
    rrna1.is_analysis AS is_analysis1,
    rrna1.timeaccessioned AS timeaccessioned1,
    rrna1.timelastmodified AS timelastmodified1,
    rrna2.feature_id AS feature_id2,
    rrna2.dbxref_id AS dbxref_id2,
    rrna2.organism_id AS organism_id2,
    rrna2.name AS name2,
    rrna2.uniquename AS uniquename2,
    rrna2.residues AS residues2,
    rrna2.seqlen AS seqlen2,
    rrna2.md5checksum AS md5checksum2,
    rrna2.type_id AS type_id2,
    rrna2.is_analysis AS is_analysis2,
    rrna2.timeaccessioned AS timeaccessioned2,
    rrna2.timelastmodified AS timelastmodified2
  FROM
    rrna AS rrna1 INNER JOIN
    feature_relationship AS fr1 ON (rrna1.rrna_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    rrna AS rrna2 ON (rrna1.rrna_id = fr2.object_id);


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
--- *** relation: sib_trna                       ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Sibling View   ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "tRNA"
CREATE VIEW sib_trna AS
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
    trna AS trna2 ON (trna1.trna_id = fr2.subject_id)
;

--- ************************************************
--- *** relation: trna_invsib                    ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "tRNA"
CREATE VIEW trna_invsib AS
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
--- *** relation: csib_trna                      ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Sibling View   ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "tRNA"
CREATE VIEW csib_trna AS
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
    trna AS trna2 ON (trna1.trna_id = fr2.subject_id)
  WHERE fr2.rank - fr1.rank = 1
;

--- ************************************************
--- *** relation: ctrna_invsib                   ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "tRNA"
CREATE VIEW ctrna_invsib AS
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
--- *** relation: sib_snrna                      ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Sibling View   ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "snRNA"
CREATE VIEW sib_snrna AS
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
    snrna AS snrna2 ON (snrna1.snrna_id = fr2.subject_id)
;

--- ************************************************
--- *** relation: snrna_invsib                   ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "snRNA"
CREATE VIEW snrna_invsib AS
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
--- *** relation: csib_snrna                     ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Sibling View   ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "snRNA"
CREATE VIEW csib_snrna AS
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
    snrna AS snrna2 ON (snrna1.snrna_id = fr2.subject_id)
  WHERE fr2.rank - fr1.rank = 1
;

--- ************************************************
--- *** relation: csnrna_invsib                  ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "snRNA"
CREATE VIEW csnrna_invsib AS
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
--- *** relation: sib_snorna                     ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Sibling View   ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "snoRNA"
CREATE VIEW sib_snorna AS
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
    snorna AS snorna2 ON (snorna1.snorna_id = fr2.subject_id)
;

--- ************************************************
--- *** relation: snorna_invsib                  ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "snoRNA"
CREATE VIEW snorna_invsib AS
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
--- *** relation: csib_snorna                    ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Sibling View   ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "snoRNA"
CREATE VIEW csib_snorna AS
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
    snorna AS snorna2 ON (snorna1.snorna_id = fr2.subject_id)
  WHERE fr2.rank - fr1.rank = 1
;

--- ************************************************
--- *** relation: csnorna_invsib                 ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "snoRNA"
CREATE VIEW csnorna_invsib AS
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
--- *** relation: long_terminal_repeat           ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology 'Typed Feature' View   ***
--- ***                                          ***
--- ************************************************
---
--- SO Term:
--- "long_terminal_repeat"

CREATE VIEW long_terminal_repeat AS
  SELECT
    feature_id AS long_terminal_repeat_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'long_terminal_repeat';

--- ************************************************
--- *** relation: sib_long_terminal_repeat       ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Sibling View   ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "long_terminal_repeat"
CREATE VIEW sib_long_terminal_repeat AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    long_terminal_repeat1.feature_id AS feature_id1,
    long_terminal_repeat1.dbxref_id AS dbxref_id1,
    long_terminal_repeat1.organism_id AS organism_id1,
    long_terminal_repeat1.name AS name1,
    long_terminal_repeat1.uniquename AS uniquename1,
    long_terminal_repeat1.residues AS residues1,
    long_terminal_repeat1.seqlen AS seqlen1,
    long_terminal_repeat1.md5checksum AS md5checksum1,
    long_terminal_repeat1.type_id AS type_id1,
    long_terminal_repeat1.is_analysis AS is_analysis1,
    long_terminal_repeat1.timeaccessioned AS timeaccessioned1,
    long_terminal_repeat1.timelastmodified AS timelastmodified1,
    long_terminal_repeat2.feature_id AS feature_id2,
    long_terminal_repeat2.dbxref_id AS dbxref_id2,
    long_terminal_repeat2.organism_id AS organism_id2,
    long_terminal_repeat2.name AS name2,
    long_terminal_repeat2.uniquename AS uniquename2,
    long_terminal_repeat2.residues AS residues2,
    long_terminal_repeat2.seqlen AS seqlen2,
    long_terminal_repeat2.md5checksum AS md5checksum2,
    long_terminal_repeat2.type_id AS type_id2,
    long_terminal_repeat2.is_analysis AS is_analysis2,
    long_terminal_repeat2.timeaccessioned AS timeaccessioned2,
    long_terminal_repeat2.timelastmodified AS timelastmodified2
  FROM
    long_terminal_repeat AS long_terminal_repeat1 INNER JOIN
    feature_relationship AS fr1 ON (long_terminal_repeat1.long_terminal_repeat_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    long_terminal_repeat AS long_terminal_repeat2 ON (long_terminal_repeat1.long_terminal_repeat_id = fr2.subject_id)
;

--- ************************************************
--- *** relation: long_terminal_repeat_invsib    ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "long_terminal_repeat"
CREATE VIEW long_terminal_repeat_invsib AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    long_terminal_repeat1.feature_id AS feature_id1,
    long_terminal_repeat1.dbxref_id AS dbxref_id1,
    long_terminal_repeat1.organism_id AS organism_id1,
    long_terminal_repeat1.name AS name1,
    long_terminal_repeat1.uniquename AS uniquename1,
    long_terminal_repeat1.residues AS residues1,
    long_terminal_repeat1.seqlen AS seqlen1,
    long_terminal_repeat1.md5checksum AS md5checksum1,
    long_terminal_repeat1.type_id AS type_id1,
    long_terminal_repeat1.is_analysis AS is_analysis1,
    long_terminal_repeat1.timeaccessioned AS timeaccessioned1,
    long_terminal_repeat1.timelastmodified AS timelastmodified1,
    long_terminal_repeat2.feature_id AS feature_id2,
    long_terminal_repeat2.dbxref_id AS dbxref_id2,
    long_terminal_repeat2.organism_id AS organism_id2,
    long_terminal_repeat2.name AS name2,
    long_terminal_repeat2.uniquename AS uniquename2,
    long_terminal_repeat2.residues AS residues2,
    long_terminal_repeat2.seqlen AS seqlen2,
    long_terminal_repeat2.md5checksum AS md5checksum2,
    long_terminal_repeat2.type_id AS type_id2,
    long_terminal_repeat2.is_analysis AS is_analysis2,
    long_terminal_repeat2.timeaccessioned AS timeaccessioned2,
    long_terminal_repeat2.timelastmodified AS timelastmodified2
  FROM
    long_terminal_repeat AS long_terminal_repeat1 INNER JOIN
    feature_relationship AS fr1 ON (long_terminal_repeat1.long_terminal_repeat_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    long_terminal_repeat AS long_terminal_repeat2 ON (long_terminal_repeat1.long_terminal_repeat_id = fr2.object_id);


--- ************************************************
--- *** relation: csib_long_terminal_repeat      ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Sibling View   ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "long_terminal_repeat"
CREATE VIEW csib_long_terminal_repeat AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    long_terminal_repeat1.feature_id AS feature_id1,
    long_terminal_repeat1.dbxref_id AS dbxref_id1,
    long_terminal_repeat1.organism_id AS organism_id1,
    long_terminal_repeat1.name AS name1,
    long_terminal_repeat1.uniquename AS uniquename1,
    long_terminal_repeat1.residues AS residues1,
    long_terminal_repeat1.seqlen AS seqlen1,
    long_terminal_repeat1.md5checksum AS md5checksum1,
    long_terminal_repeat1.type_id AS type_id1,
    long_terminal_repeat1.is_analysis AS is_analysis1,
    long_terminal_repeat1.timeaccessioned AS timeaccessioned1,
    long_terminal_repeat1.timelastmodified AS timelastmodified1,
    long_terminal_repeat2.feature_id AS feature_id2,
    long_terminal_repeat2.dbxref_id AS dbxref_id2,
    long_terminal_repeat2.organism_id AS organism_id2,
    long_terminal_repeat2.name AS name2,
    long_terminal_repeat2.uniquename AS uniquename2,
    long_terminal_repeat2.residues AS residues2,
    long_terminal_repeat2.seqlen AS seqlen2,
    long_terminal_repeat2.md5checksum AS md5checksum2,
    long_terminal_repeat2.type_id AS type_id2,
    long_terminal_repeat2.is_analysis AS is_analysis2,
    long_terminal_repeat2.timeaccessioned AS timeaccessioned2,
    long_terminal_repeat2.timelastmodified AS timelastmodified2
  FROM
    long_terminal_repeat AS long_terminal_repeat1 INNER JOIN
    feature_relationship AS fr1 ON (long_terminal_repeat1.long_terminal_repeat_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    long_terminal_repeat AS long_terminal_repeat2 ON (long_terminal_repeat1.long_terminal_repeat_id = fr2.subject_id)
  WHERE fr2.rank - fr1.rank = 1
;

--- ************************************************
--- *** relation: clong_terminal_repeat_invsib   ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "long_terminal_repeat"
CREATE VIEW clong_terminal_repeat_invsib AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    long_terminal_repeat1.feature_id AS feature_id1,
    long_terminal_repeat1.dbxref_id AS dbxref_id1,
    long_terminal_repeat1.organism_id AS organism_id1,
    long_terminal_repeat1.name AS name1,
    long_terminal_repeat1.uniquename AS uniquename1,
    long_terminal_repeat1.residues AS residues1,
    long_terminal_repeat1.seqlen AS seqlen1,
    long_terminal_repeat1.md5checksum AS md5checksum1,
    long_terminal_repeat1.type_id AS type_id1,
    long_terminal_repeat1.is_analysis AS is_analysis1,
    long_terminal_repeat1.timeaccessioned AS timeaccessioned1,
    long_terminal_repeat1.timelastmodified AS timelastmodified1,
    long_terminal_repeat2.feature_id AS feature_id2,
    long_terminal_repeat2.dbxref_id AS dbxref_id2,
    long_terminal_repeat2.organism_id AS organism_id2,
    long_terminal_repeat2.name AS name2,
    long_terminal_repeat2.uniquename AS uniquename2,
    long_terminal_repeat2.residues AS residues2,
    long_terminal_repeat2.seqlen AS seqlen2,
    long_terminal_repeat2.md5checksum AS md5checksum2,
    long_terminal_repeat2.type_id AS type_id2,
    long_terminal_repeat2.is_analysis AS is_analysis2,
    long_terminal_repeat2.timeaccessioned AS timeaccessioned2,
    long_terminal_repeat2.timelastmodified AS timelastmodified2
  FROM
    long_terminal_repeat AS long_terminal_repeat1 INNER JOIN
    feature_relationship AS fr1 ON (long_terminal_repeat1.long_terminal_repeat_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    long_terminal_repeat AS long_terminal_repeat2 ON (long_terminal_repeat1.long_terminal_repeat_id = fr2.object_id);


--- ************************************************
--- *** relation: cds                            ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology 'Typed Feature' View   ***
--- ***                                          ***
--- ************************************************
---
--- SO Term:
--- "CDS"

CREATE VIEW cds AS
  SELECT
    feature_id AS cds_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'CDS';

--- ************************************************
--- *** relation: sib_cds                        ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Sibling View   ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "CDS"
CREATE VIEW sib_cds AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    cds1.feature_id AS feature_id1,
    cds1.dbxref_id AS dbxref_id1,
    cds1.organism_id AS organism_id1,
    cds1.name AS name1,
    cds1.uniquename AS uniquename1,
    cds1.residues AS residues1,
    cds1.seqlen AS seqlen1,
    cds1.md5checksum AS md5checksum1,
    cds1.type_id AS type_id1,
    cds1.is_analysis AS is_analysis1,
    cds1.timeaccessioned AS timeaccessioned1,
    cds1.timelastmodified AS timelastmodified1,
    cds2.feature_id AS feature_id2,
    cds2.dbxref_id AS dbxref_id2,
    cds2.organism_id AS organism_id2,
    cds2.name AS name2,
    cds2.uniquename AS uniquename2,
    cds2.residues AS residues2,
    cds2.seqlen AS seqlen2,
    cds2.md5checksum AS md5checksum2,
    cds2.type_id AS type_id2,
    cds2.is_analysis AS is_analysis2,
    cds2.timeaccessioned AS timeaccessioned2,
    cds2.timelastmodified AS timelastmodified2
  FROM
    cds AS cds1 INNER JOIN
    feature_relationship AS fr1 ON (cds1.cds_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    cds AS cds2 ON (cds1.cds_id = fr2.subject_id)
;

--- ************************************************
--- *** relation: cds_invsib                     ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "CDS"
CREATE VIEW cds_invsib AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    cds1.feature_id AS feature_id1,
    cds1.dbxref_id AS dbxref_id1,
    cds1.organism_id AS organism_id1,
    cds1.name AS name1,
    cds1.uniquename AS uniquename1,
    cds1.residues AS residues1,
    cds1.seqlen AS seqlen1,
    cds1.md5checksum AS md5checksum1,
    cds1.type_id AS type_id1,
    cds1.is_analysis AS is_analysis1,
    cds1.timeaccessioned AS timeaccessioned1,
    cds1.timelastmodified AS timelastmodified1,
    cds2.feature_id AS feature_id2,
    cds2.dbxref_id AS dbxref_id2,
    cds2.organism_id AS organism_id2,
    cds2.name AS name2,
    cds2.uniquename AS uniquename2,
    cds2.residues AS residues2,
    cds2.seqlen AS seqlen2,
    cds2.md5checksum AS md5checksum2,
    cds2.type_id AS type_id2,
    cds2.is_analysis AS is_analysis2,
    cds2.timeaccessioned AS timeaccessioned2,
    cds2.timelastmodified AS timelastmodified2
  FROM
    cds AS cds1 INNER JOIN
    feature_relationship AS fr1 ON (cds1.cds_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    cds AS cds2 ON (cds1.cds_id = fr2.object_id);


--- ************************************************
--- *** relation: csib_cds                       ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Sibling View   ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "CDS"
CREATE VIEW csib_cds AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    cds1.feature_id AS feature_id1,
    cds1.dbxref_id AS dbxref_id1,
    cds1.organism_id AS organism_id1,
    cds1.name AS name1,
    cds1.uniquename AS uniquename1,
    cds1.residues AS residues1,
    cds1.seqlen AS seqlen1,
    cds1.md5checksum AS md5checksum1,
    cds1.type_id AS type_id1,
    cds1.is_analysis AS is_analysis1,
    cds1.timeaccessioned AS timeaccessioned1,
    cds1.timelastmodified AS timelastmodified1,
    cds2.feature_id AS feature_id2,
    cds2.dbxref_id AS dbxref_id2,
    cds2.organism_id AS organism_id2,
    cds2.name AS name2,
    cds2.uniquename AS uniquename2,
    cds2.residues AS residues2,
    cds2.seqlen AS seqlen2,
    cds2.md5checksum AS md5checksum2,
    cds2.type_id AS type_id2,
    cds2.is_analysis AS is_analysis2,
    cds2.timeaccessioned AS timeaccessioned2,
    cds2.timelastmodified AS timelastmodified2
  FROM
    cds AS cds1 INNER JOIN
    feature_relationship AS fr1 ON (cds1.cds_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    cds AS cds2 ON (cds1.cds_id = fr2.subject_id)
  WHERE fr2.rank - fr1.rank = 1
;

--- ************************************************
--- *** relation: ccds_invsib                    ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "CDS"
CREATE VIEW ccds_invsib AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    cds1.feature_id AS feature_id1,
    cds1.dbxref_id AS dbxref_id1,
    cds1.organism_id AS organism_id1,
    cds1.name AS name1,
    cds1.uniquename AS uniquename1,
    cds1.residues AS residues1,
    cds1.seqlen AS seqlen1,
    cds1.md5checksum AS md5checksum1,
    cds1.type_id AS type_id1,
    cds1.is_analysis AS is_analysis1,
    cds1.timeaccessioned AS timeaccessioned1,
    cds1.timelastmodified AS timelastmodified1,
    cds2.feature_id AS feature_id2,
    cds2.dbxref_id AS dbxref_id2,
    cds2.organism_id AS organism_id2,
    cds2.name AS name2,
    cds2.uniquename AS uniquename2,
    cds2.residues AS residues2,
    cds2.seqlen AS seqlen2,
    cds2.md5checksum AS md5checksum2,
    cds2.type_id AS type_id2,
    cds2.is_analysis AS is_analysis2,
    cds2.timeaccessioned AS timeaccessioned2,
    cds2.timelastmodified AS timelastmodified2
  FROM
    cds AS cds1 INNER JOIN
    feature_relationship AS fr1 ON (cds1.cds_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    cds AS cds2 ON (cds1.cds_id = fr2.object_id);


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
--- *** relation: sib_pseudogene                 ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Sibling View   ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "pseudogene"
CREATE VIEW sib_pseudogene AS
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
    pseudogene AS pseudogene2 ON (pseudogene1.pseudogene_id = fr2.subject_id)
;

--- ************************************************
--- *** relation: pseudogene_invsib              ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "pseudogene"
CREATE VIEW pseudogene_invsib AS
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
--- *** relation: csib_pseudogene                ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Sibling View   ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "pseudogene"
CREATE VIEW csib_pseudogene AS
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
    pseudogene AS pseudogene2 ON (pseudogene1.pseudogene_id = fr2.subject_id)
  WHERE fr2.rank - fr1.rank = 1
;

--- ************************************************
--- *** relation: cpseudogene_invsib             ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "pseudogene"
CREATE VIEW cpseudogene_invsib AS
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
--- *** relation: chromosome                     ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology 'Typed Feature' View   ***
--- ***                                          ***
--- ************************************************
---
--- SO Term:
--- "chromosome"

CREATE VIEW chromosome AS
  SELECT
    feature_id AS chromosome_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'chromosome';

--- ************************************************
--- *** relation: sib_chromosome                 ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Sibling View   ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "chromosome"
CREATE VIEW sib_chromosome AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    chromosome1.feature_id AS feature_id1,
    chromosome1.dbxref_id AS dbxref_id1,
    chromosome1.organism_id AS organism_id1,
    chromosome1.name AS name1,
    chromosome1.uniquename AS uniquename1,
    chromosome1.residues AS residues1,
    chromosome1.seqlen AS seqlen1,
    chromosome1.md5checksum AS md5checksum1,
    chromosome1.type_id AS type_id1,
    chromosome1.is_analysis AS is_analysis1,
    chromosome1.timeaccessioned AS timeaccessioned1,
    chromosome1.timelastmodified AS timelastmodified1,
    chromosome2.feature_id AS feature_id2,
    chromosome2.dbxref_id AS dbxref_id2,
    chromosome2.organism_id AS organism_id2,
    chromosome2.name AS name2,
    chromosome2.uniquename AS uniquename2,
    chromosome2.residues AS residues2,
    chromosome2.seqlen AS seqlen2,
    chromosome2.md5checksum AS md5checksum2,
    chromosome2.type_id AS type_id2,
    chromosome2.is_analysis AS is_analysis2,
    chromosome2.timeaccessioned AS timeaccessioned2,
    chromosome2.timelastmodified AS timelastmodified2
  FROM
    chromosome AS chromosome1 INNER JOIN
    feature_relationship AS fr1 ON (chromosome1.chromosome_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    chromosome AS chromosome2 ON (chromosome1.chromosome_id = fr2.subject_id)
;

--- ************************************************
--- *** relation: chromosome_invsib              ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "chromosome"
CREATE VIEW chromosome_invsib AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    chromosome1.feature_id AS feature_id1,
    chromosome1.dbxref_id AS dbxref_id1,
    chromosome1.organism_id AS organism_id1,
    chromosome1.name AS name1,
    chromosome1.uniquename AS uniquename1,
    chromosome1.residues AS residues1,
    chromosome1.seqlen AS seqlen1,
    chromosome1.md5checksum AS md5checksum1,
    chromosome1.type_id AS type_id1,
    chromosome1.is_analysis AS is_analysis1,
    chromosome1.timeaccessioned AS timeaccessioned1,
    chromosome1.timelastmodified AS timelastmodified1,
    chromosome2.feature_id AS feature_id2,
    chromosome2.dbxref_id AS dbxref_id2,
    chromosome2.organism_id AS organism_id2,
    chromosome2.name AS name2,
    chromosome2.uniquename AS uniquename2,
    chromosome2.residues AS residues2,
    chromosome2.seqlen AS seqlen2,
    chromosome2.md5checksum AS md5checksum2,
    chromosome2.type_id AS type_id2,
    chromosome2.is_analysis AS is_analysis2,
    chromosome2.timeaccessioned AS timeaccessioned2,
    chromosome2.timelastmodified AS timelastmodified2
  FROM
    chromosome AS chromosome1 INNER JOIN
    feature_relationship AS fr1 ON (chromosome1.chromosome_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    chromosome AS chromosome2 ON (chromosome1.chromosome_id = fr2.object_id);


--- ************************************************
--- *** relation: csib_chromosome                ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Sibling View   ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "chromosome"
CREATE VIEW csib_chromosome AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    chromosome1.feature_id AS feature_id1,
    chromosome1.dbxref_id AS dbxref_id1,
    chromosome1.organism_id AS organism_id1,
    chromosome1.name AS name1,
    chromosome1.uniquename AS uniquename1,
    chromosome1.residues AS residues1,
    chromosome1.seqlen AS seqlen1,
    chromosome1.md5checksum AS md5checksum1,
    chromosome1.type_id AS type_id1,
    chromosome1.is_analysis AS is_analysis1,
    chromosome1.timeaccessioned AS timeaccessioned1,
    chromosome1.timelastmodified AS timelastmodified1,
    chromosome2.feature_id AS feature_id2,
    chromosome2.dbxref_id AS dbxref_id2,
    chromosome2.organism_id AS organism_id2,
    chromosome2.name AS name2,
    chromosome2.uniquename AS uniquename2,
    chromosome2.residues AS residues2,
    chromosome2.seqlen AS seqlen2,
    chromosome2.md5checksum AS md5checksum2,
    chromosome2.type_id AS type_id2,
    chromosome2.is_analysis AS is_analysis2,
    chromosome2.timeaccessioned AS timeaccessioned2,
    chromosome2.timelastmodified AS timelastmodified2
  FROM
    chromosome AS chromosome1 INNER JOIN
    feature_relationship AS fr1 ON (chromosome1.chromosome_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    chromosome AS chromosome2 ON (chromosome1.chromosome_id = fr2.subject_id)
  WHERE fr2.rank - fr1.rank = 1
;

--- ************************************************
--- *** relation: cchromosome_invsib             ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "chromosome"
CREATE VIEW cchromosome_invsib AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    chromosome1.feature_id AS feature_id1,
    chromosome1.dbxref_id AS dbxref_id1,
    chromosome1.organism_id AS organism_id1,
    chromosome1.name AS name1,
    chromosome1.uniquename AS uniquename1,
    chromosome1.residues AS residues1,
    chromosome1.seqlen AS seqlen1,
    chromosome1.md5checksum AS md5checksum1,
    chromosome1.type_id AS type_id1,
    chromosome1.is_analysis AS is_analysis1,
    chromosome1.timeaccessioned AS timeaccessioned1,
    chromosome1.timelastmodified AS timelastmodified1,
    chromosome2.feature_id AS feature_id2,
    chromosome2.dbxref_id AS dbxref_id2,
    chromosome2.organism_id AS organism_id2,
    chromosome2.name AS name2,
    chromosome2.uniquename AS uniquename2,
    chromosome2.residues AS residues2,
    chromosome2.seqlen AS seqlen2,
    chromosome2.md5checksum AS md5checksum2,
    chromosome2.type_id AS type_id2,
    chromosome2.is_analysis AS is_analysis2,
    chromosome2.timeaccessioned AS timeaccessioned2,
    chromosome2.timelastmodified AS timelastmodified2
  FROM
    chromosome AS chromosome1 INNER JOIN
    feature_relationship AS fr1 ON (chromosome1.chromosome_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    chromosome AS chromosome2 ON (chromosome1.chromosome_id = fr2.object_id);


--- ************************************************
--- *** relation: nucleotide_match               ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology 'Typed Feature' View   ***
--- ***                                          ***
--- ************************************************
---
--- SO Term:
--- "nucleotide_match"

CREATE VIEW nucleotide_match AS
  SELECT
    feature_id AS nucleotide_match_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'nucleotide_match';

--- ************************************************
--- *** relation: sib_nucleotide_match           ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Sibling View   ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "nucleotide_match"
CREATE VIEW sib_nucleotide_match AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    nucleotide_match1.feature_id AS feature_id1,
    nucleotide_match1.dbxref_id AS dbxref_id1,
    nucleotide_match1.organism_id AS organism_id1,
    nucleotide_match1.name AS name1,
    nucleotide_match1.uniquename AS uniquename1,
    nucleotide_match1.residues AS residues1,
    nucleotide_match1.seqlen AS seqlen1,
    nucleotide_match1.md5checksum AS md5checksum1,
    nucleotide_match1.type_id AS type_id1,
    nucleotide_match1.is_analysis AS is_analysis1,
    nucleotide_match1.timeaccessioned AS timeaccessioned1,
    nucleotide_match1.timelastmodified AS timelastmodified1,
    nucleotide_match2.feature_id AS feature_id2,
    nucleotide_match2.dbxref_id AS dbxref_id2,
    nucleotide_match2.organism_id AS organism_id2,
    nucleotide_match2.name AS name2,
    nucleotide_match2.uniquename AS uniquename2,
    nucleotide_match2.residues AS residues2,
    nucleotide_match2.seqlen AS seqlen2,
    nucleotide_match2.md5checksum AS md5checksum2,
    nucleotide_match2.type_id AS type_id2,
    nucleotide_match2.is_analysis AS is_analysis2,
    nucleotide_match2.timeaccessioned AS timeaccessioned2,
    nucleotide_match2.timelastmodified AS timelastmodified2
  FROM
    nucleotide_match AS nucleotide_match1 INNER JOIN
    feature_relationship AS fr1 ON (nucleotide_match1.nucleotide_match_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    nucleotide_match AS nucleotide_match2 ON (nucleotide_match1.nucleotide_match_id = fr2.subject_id)
;

--- ************************************************
--- *** relation: nucleotide_match_invsib        ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "nucleotide_match"
CREATE VIEW nucleotide_match_invsib AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    nucleotide_match1.feature_id AS feature_id1,
    nucleotide_match1.dbxref_id AS dbxref_id1,
    nucleotide_match1.organism_id AS organism_id1,
    nucleotide_match1.name AS name1,
    nucleotide_match1.uniquename AS uniquename1,
    nucleotide_match1.residues AS residues1,
    nucleotide_match1.seqlen AS seqlen1,
    nucleotide_match1.md5checksum AS md5checksum1,
    nucleotide_match1.type_id AS type_id1,
    nucleotide_match1.is_analysis AS is_analysis1,
    nucleotide_match1.timeaccessioned AS timeaccessioned1,
    nucleotide_match1.timelastmodified AS timelastmodified1,
    nucleotide_match2.feature_id AS feature_id2,
    nucleotide_match2.dbxref_id AS dbxref_id2,
    nucleotide_match2.organism_id AS organism_id2,
    nucleotide_match2.name AS name2,
    nucleotide_match2.uniquename AS uniquename2,
    nucleotide_match2.residues AS residues2,
    nucleotide_match2.seqlen AS seqlen2,
    nucleotide_match2.md5checksum AS md5checksum2,
    nucleotide_match2.type_id AS type_id2,
    nucleotide_match2.is_analysis AS is_analysis2,
    nucleotide_match2.timeaccessioned AS timeaccessioned2,
    nucleotide_match2.timelastmodified AS timelastmodified2
  FROM
    nucleotide_match AS nucleotide_match1 INNER JOIN
    feature_relationship AS fr1 ON (nucleotide_match1.nucleotide_match_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    nucleotide_match AS nucleotide_match2 ON (nucleotide_match1.nucleotide_match_id = fr2.object_id);


--- ************************************************
--- *** relation: csib_nucleotide_match          ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Sibling View   ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "nucleotide_match"
CREATE VIEW csib_nucleotide_match AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    nucleotide_match1.feature_id AS feature_id1,
    nucleotide_match1.dbxref_id AS dbxref_id1,
    nucleotide_match1.organism_id AS organism_id1,
    nucleotide_match1.name AS name1,
    nucleotide_match1.uniquename AS uniquename1,
    nucleotide_match1.residues AS residues1,
    nucleotide_match1.seqlen AS seqlen1,
    nucleotide_match1.md5checksum AS md5checksum1,
    nucleotide_match1.type_id AS type_id1,
    nucleotide_match1.is_analysis AS is_analysis1,
    nucleotide_match1.timeaccessioned AS timeaccessioned1,
    nucleotide_match1.timelastmodified AS timelastmodified1,
    nucleotide_match2.feature_id AS feature_id2,
    nucleotide_match2.dbxref_id AS dbxref_id2,
    nucleotide_match2.organism_id AS organism_id2,
    nucleotide_match2.name AS name2,
    nucleotide_match2.uniquename AS uniquename2,
    nucleotide_match2.residues AS residues2,
    nucleotide_match2.seqlen AS seqlen2,
    nucleotide_match2.md5checksum AS md5checksum2,
    nucleotide_match2.type_id AS type_id2,
    nucleotide_match2.is_analysis AS is_analysis2,
    nucleotide_match2.timeaccessioned AS timeaccessioned2,
    nucleotide_match2.timelastmodified AS timelastmodified2
  FROM
    nucleotide_match AS nucleotide_match1 INNER JOIN
    feature_relationship AS fr1 ON (nucleotide_match1.nucleotide_match_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    nucleotide_match AS nucleotide_match2 ON (nucleotide_match1.nucleotide_match_id = fr2.subject_id)
  WHERE fr2.rank - fr1.rank = 1
;

--- ************************************************
--- *** relation: cnucleotide_match_invsib       ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "nucleotide_match"
CREATE VIEW cnucleotide_match_invsib AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    nucleotide_match1.feature_id AS feature_id1,
    nucleotide_match1.dbxref_id AS dbxref_id1,
    nucleotide_match1.organism_id AS organism_id1,
    nucleotide_match1.name AS name1,
    nucleotide_match1.uniquename AS uniquename1,
    nucleotide_match1.residues AS residues1,
    nucleotide_match1.seqlen AS seqlen1,
    nucleotide_match1.md5checksum AS md5checksum1,
    nucleotide_match1.type_id AS type_id1,
    nucleotide_match1.is_analysis AS is_analysis1,
    nucleotide_match1.timeaccessioned AS timeaccessioned1,
    nucleotide_match1.timelastmodified AS timelastmodified1,
    nucleotide_match2.feature_id AS feature_id2,
    nucleotide_match2.dbxref_id AS dbxref_id2,
    nucleotide_match2.organism_id AS organism_id2,
    nucleotide_match2.name AS name2,
    nucleotide_match2.uniquename AS uniquename2,
    nucleotide_match2.residues AS residues2,
    nucleotide_match2.seqlen AS seqlen2,
    nucleotide_match2.md5checksum AS md5checksum2,
    nucleotide_match2.type_id AS type_id2,
    nucleotide_match2.is_analysis AS is_analysis2,
    nucleotide_match2.timeaccessioned AS timeaccessioned2,
    nucleotide_match2.timelastmodified AS timelastmodified2
  FROM
    nucleotide_match AS nucleotide_match1 INNER JOIN
    feature_relationship AS fr1 ON (nucleotide_match1.nucleotide_match_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    nucleotide_match AS nucleotide_match2 ON (nucleotide_match1.nucleotide_match_id = fr2.object_id);


--- ************************************************
--- *** relation: binding_site                   ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology 'Typed Feature' View   ***
--- ***                                          ***
--- ************************************************
---
--- SO Term:
--- "binding_site"

CREATE VIEW binding_site AS
  SELECT
    feature_id AS binding_site_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'binding_site';

--- ************************************************
--- *** relation: sib_binding_site               ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Sibling View   ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "binding_site"
CREATE VIEW sib_binding_site AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    binding_site1.feature_id AS feature_id1,
    binding_site1.dbxref_id AS dbxref_id1,
    binding_site1.organism_id AS organism_id1,
    binding_site1.name AS name1,
    binding_site1.uniquename AS uniquename1,
    binding_site1.residues AS residues1,
    binding_site1.seqlen AS seqlen1,
    binding_site1.md5checksum AS md5checksum1,
    binding_site1.type_id AS type_id1,
    binding_site1.is_analysis AS is_analysis1,
    binding_site1.timeaccessioned AS timeaccessioned1,
    binding_site1.timelastmodified AS timelastmodified1,
    binding_site2.feature_id AS feature_id2,
    binding_site2.dbxref_id AS dbxref_id2,
    binding_site2.organism_id AS organism_id2,
    binding_site2.name AS name2,
    binding_site2.uniquename AS uniquename2,
    binding_site2.residues AS residues2,
    binding_site2.seqlen AS seqlen2,
    binding_site2.md5checksum AS md5checksum2,
    binding_site2.type_id AS type_id2,
    binding_site2.is_analysis AS is_analysis2,
    binding_site2.timeaccessioned AS timeaccessioned2,
    binding_site2.timelastmodified AS timelastmodified2
  FROM
    binding_site AS binding_site1 INNER JOIN
    feature_relationship AS fr1 ON (binding_site1.binding_site_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    binding_site AS binding_site2 ON (binding_site1.binding_site_id = fr2.subject_id)
;

--- ************************************************
--- *** relation: binding_site_invsib            ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "binding_site"
CREATE VIEW binding_site_invsib AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    binding_site1.feature_id AS feature_id1,
    binding_site1.dbxref_id AS dbxref_id1,
    binding_site1.organism_id AS organism_id1,
    binding_site1.name AS name1,
    binding_site1.uniquename AS uniquename1,
    binding_site1.residues AS residues1,
    binding_site1.seqlen AS seqlen1,
    binding_site1.md5checksum AS md5checksum1,
    binding_site1.type_id AS type_id1,
    binding_site1.is_analysis AS is_analysis1,
    binding_site1.timeaccessioned AS timeaccessioned1,
    binding_site1.timelastmodified AS timelastmodified1,
    binding_site2.feature_id AS feature_id2,
    binding_site2.dbxref_id AS dbxref_id2,
    binding_site2.organism_id AS organism_id2,
    binding_site2.name AS name2,
    binding_site2.uniquename AS uniquename2,
    binding_site2.residues AS residues2,
    binding_site2.seqlen AS seqlen2,
    binding_site2.md5checksum AS md5checksum2,
    binding_site2.type_id AS type_id2,
    binding_site2.is_analysis AS is_analysis2,
    binding_site2.timeaccessioned AS timeaccessioned2,
    binding_site2.timelastmodified AS timelastmodified2
  FROM
    binding_site AS binding_site1 INNER JOIN
    feature_relationship AS fr1 ON (binding_site1.binding_site_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    binding_site AS binding_site2 ON (binding_site1.binding_site_id = fr2.object_id);


--- ************************************************
--- *** relation: csib_binding_site              ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Sibling View   ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "binding_site"
CREATE VIEW csib_binding_site AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    binding_site1.feature_id AS feature_id1,
    binding_site1.dbxref_id AS dbxref_id1,
    binding_site1.organism_id AS organism_id1,
    binding_site1.name AS name1,
    binding_site1.uniquename AS uniquename1,
    binding_site1.residues AS residues1,
    binding_site1.seqlen AS seqlen1,
    binding_site1.md5checksum AS md5checksum1,
    binding_site1.type_id AS type_id1,
    binding_site1.is_analysis AS is_analysis1,
    binding_site1.timeaccessioned AS timeaccessioned1,
    binding_site1.timelastmodified AS timelastmodified1,
    binding_site2.feature_id AS feature_id2,
    binding_site2.dbxref_id AS dbxref_id2,
    binding_site2.organism_id AS organism_id2,
    binding_site2.name AS name2,
    binding_site2.uniquename AS uniquename2,
    binding_site2.residues AS residues2,
    binding_site2.seqlen AS seqlen2,
    binding_site2.md5checksum AS md5checksum2,
    binding_site2.type_id AS type_id2,
    binding_site2.is_analysis AS is_analysis2,
    binding_site2.timeaccessioned AS timeaccessioned2,
    binding_site2.timelastmodified AS timelastmodified2
  FROM
    binding_site AS binding_site1 INNER JOIN
    feature_relationship AS fr1 ON (binding_site1.binding_site_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    binding_site AS binding_site2 ON (binding_site1.binding_site_id = fr2.subject_id)
  WHERE fr2.rank - fr1.rank = 1
;

--- ************************************************
--- *** relation: cbinding_site_invsib           ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "binding_site"
CREATE VIEW cbinding_site_invsib AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    binding_site1.feature_id AS feature_id1,
    binding_site1.dbxref_id AS dbxref_id1,
    binding_site1.organism_id AS organism_id1,
    binding_site1.name AS name1,
    binding_site1.uniquename AS uniquename1,
    binding_site1.residues AS residues1,
    binding_site1.seqlen AS seqlen1,
    binding_site1.md5checksum AS md5checksum1,
    binding_site1.type_id AS type_id1,
    binding_site1.is_analysis AS is_analysis1,
    binding_site1.timeaccessioned AS timeaccessioned1,
    binding_site1.timelastmodified AS timelastmodified1,
    binding_site2.feature_id AS feature_id2,
    binding_site2.dbxref_id AS dbxref_id2,
    binding_site2.organism_id AS organism_id2,
    binding_site2.name AS name2,
    binding_site2.uniquename AS uniquename2,
    binding_site2.residues AS residues2,
    binding_site2.seqlen AS seqlen2,
    binding_site2.md5checksum AS md5checksum2,
    binding_site2.type_id AS type_id2,
    binding_site2.is_analysis AS is_analysis2,
    binding_site2.timeaccessioned AS timeaccessioned2,
    binding_site2.timelastmodified AS timelastmodified2
  FROM
    binding_site AS binding_site1 INNER JOIN
    feature_relationship AS fr1 ON (binding_site1.binding_site_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    binding_site AS binding_site2 ON (binding_site1.binding_site_id = fr2.object_id);


--- ************************************************
--- *** relation: ars                            ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology 'Typed Feature' View   ***
--- ***                                          ***
--- ************************************************
---
--- SO Term:
--- "ARS"

CREATE VIEW ars AS
  SELECT
    feature_id AS ars_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'ARS';

--- ************************************************
--- *** relation: sib_ars                        ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Sibling View   ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "ARS"
CREATE VIEW sib_ars AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    ars1.feature_id AS feature_id1,
    ars1.dbxref_id AS dbxref_id1,
    ars1.organism_id AS organism_id1,
    ars1.name AS name1,
    ars1.uniquename AS uniquename1,
    ars1.residues AS residues1,
    ars1.seqlen AS seqlen1,
    ars1.md5checksum AS md5checksum1,
    ars1.type_id AS type_id1,
    ars1.is_analysis AS is_analysis1,
    ars1.timeaccessioned AS timeaccessioned1,
    ars1.timelastmodified AS timelastmodified1,
    ars2.feature_id AS feature_id2,
    ars2.dbxref_id AS dbxref_id2,
    ars2.organism_id AS organism_id2,
    ars2.name AS name2,
    ars2.uniquename AS uniquename2,
    ars2.residues AS residues2,
    ars2.seqlen AS seqlen2,
    ars2.md5checksum AS md5checksum2,
    ars2.type_id AS type_id2,
    ars2.is_analysis AS is_analysis2,
    ars2.timeaccessioned AS timeaccessioned2,
    ars2.timelastmodified AS timelastmodified2
  FROM
    ars AS ars1 INNER JOIN
    feature_relationship AS fr1 ON (ars1.ars_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    ars AS ars2 ON (ars1.ars_id = fr2.subject_id)
;

--- ************************************************
--- *** relation: ars_invsib                     ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "ARS"
CREATE VIEW ars_invsib AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    ars1.feature_id AS feature_id1,
    ars1.dbxref_id AS dbxref_id1,
    ars1.organism_id AS organism_id1,
    ars1.name AS name1,
    ars1.uniquename AS uniquename1,
    ars1.residues AS residues1,
    ars1.seqlen AS seqlen1,
    ars1.md5checksum AS md5checksum1,
    ars1.type_id AS type_id1,
    ars1.is_analysis AS is_analysis1,
    ars1.timeaccessioned AS timeaccessioned1,
    ars1.timelastmodified AS timelastmodified1,
    ars2.feature_id AS feature_id2,
    ars2.dbxref_id AS dbxref_id2,
    ars2.organism_id AS organism_id2,
    ars2.name AS name2,
    ars2.uniquename AS uniquename2,
    ars2.residues AS residues2,
    ars2.seqlen AS seqlen2,
    ars2.md5checksum AS md5checksum2,
    ars2.type_id AS type_id2,
    ars2.is_analysis AS is_analysis2,
    ars2.timeaccessioned AS timeaccessioned2,
    ars2.timelastmodified AS timelastmodified2
  FROM
    ars AS ars1 INNER JOIN
    feature_relationship AS fr1 ON (ars1.ars_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    ars AS ars2 ON (ars1.ars_id = fr2.object_id);


--- ************************************************
--- *** relation: csib_ars                       ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Sibling View   ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "ARS"
CREATE VIEW csib_ars AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    ars1.feature_id AS feature_id1,
    ars1.dbxref_id AS dbxref_id1,
    ars1.organism_id AS organism_id1,
    ars1.name AS name1,
    ars1.uniquename AS uniquename1,
    ars1.residues AS residues1,
    ars1.seqlen AS seqlen1,
    ars1.md5checksum AS md5checksum1,
    ars1.type_id AS type_id1,
    ars1.is_analysis AS is_analysis1,
    ars1.timeaccessioned AS timeaccessioned1,
    ars1.timelastmodified AS timelastmodified1,
    ars2.feature_id AS feature_id2,
    ars2.dbxref_id AS dbxref_id2,
    ars2.organism_id AS organism_id2,
    ars2.name AS name2,
    ars2.uniquename AS uniquename2,
    ars2.residues AS residues2,
    ars2.seqlen AS seqlen2,
    ars2.md5checksum AS md5checksum2,
    ars2.type_id AS type_id2,
    ars2.is_analysis AS is_analysis2,
    ars2.timeaccessioned AS timeaccessioned2,
    ars2.timelastmodified AS timelastmodified2
  FROM
    ars AS ars1 INNER JOIN
    feature_relationship AS fr1 ON (ars1.ars_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    ars AS ars2 ON (ars1.ars_id = fr2.subject_id)
  WHERE fr2.rank - fr1.rank = 1
;

--- ************************************************
--- *** relation: cars_invsib                    ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "ARS"
CREATE VIEW cars_invsib AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    ars1.feature_id AS feature_id1,
    ars1.dbxref_id AS dbxref_id1,
    ars1.organism_id AS organism_id1,
    ars1.name AS name1,
    ars1.uniquename AS uniquename1,
    ars1.residues AS residues1,
    ars1.seqlen AS seqlen1,
    ars1.md5checksum AS md5checksum1,
    ars1.type_id AS type_id1,
    ars1.is_analysis AS is_analysis1,
    ars1.timeaccessioned AS timeaccessioned1,
    ars1.timelastmodified AS timelastmodified1,
    ars2.feature_id AS feature_id2,
    ars2.dbxref_id AS dbxref_id2,
    ars2.organism_id AS organism_id2,
    ars2.name AS name2,
    ars2.uniquename AS uniquename2,
    ars2.residues AS residues2,
    ars2.seqlen AS seqlen2,
    ars2.md5checksum AS md5checksum2,
    ars2.type_id AS type_id2,
    ars2.is_analysis AS is_analysis2,
    ars2.timeaccessioned AS timeaccessioned2,
    ars2.timelastmodified AS timelastmodified2
  FROM
    ars AS ars1 INNER JOIN
    feature_relationship AS fr1 ON (ars1.ars_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    ars AS ars2 ON (ars1.ars_id = fr2.object_id);


--- ************************************************
--- *** relation: five_prime_utr_intron          ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology 'Typed Feature' View   ***
--- ***                                          ***
--- ************************************************
---
--- SO Term:
--- "five_prime_UTR_intron"

CREATE VIEW five_prime_utr_intron AS
  SELECT
    feature_id AS five_prime_utr_intron_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'five_prime_UTR_intron';

--- ************************************************
--- *** relation: sib_five_prime_utr_intron      ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Sibling View   ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "five_prime_UTR_intron"
CREATE VIEW sib_five_prime_utr_intron AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    five_prime_utr_intron1.feature_id AS feature_id1,
    five_prime_utr_intron1.dbxref_id AS dbxref_id1,
    five_prime_utr_intron1.organism_id AS organism_id1,
    five_prime_utr_intron1.name AS name1,
    five_prime_utr_intron1.uniquename AS uniquename1,
    five_prime_utr_intron1.residues AS residues1,
    five_prime_utr_intron1.seqlen AS seqlen1,
    five_prime_utr_intron1.md5checksum AS md5checksum1,
    five_prime_utr_intron1.type_id AS type_id1,
    five_prime_utr_intron1.is_analysis AS is_analysis1,
    five_prime_utr_intron1.timeaccessioned AS timeaccessioned1,
    five_prime_utr_intron1.timelastmodified AS timelastmodified1,
    five_prime_utr_intron2.feature_id AS feature_id2,
    five_prime_utr_intron2.dbxref_id AS dbxref_id2,
    five_prime_utr_intron2.organism_id AS organism_id2,
    five_prime_utr_intron2.name AS name2,
    five_prime_utr_intron2.uniquename AS uniquename2,
    five_prime_utr_intron2.residues AS residues2,
    five_prime_utr_intron2.seqlen AS seqlen2,
    five_prime_utr_intron2.md5checksum AS md5checksum2,
    five_prime_utr_intron2.type_id AS type_id2,
    five_prime_utr_intron2.is_analysis AS is_analysis2,
    five_prime_utr_intron2.timeaccessioned AS timeaccessioned2,
    five_prime_utr_intron2.timelastmodified AS timelastmodified2
  FROM
    five_prime_utr_intron AS five_prime_utr_intron1 INNER JOIN
    feature_relationship AS fr1 ON (five_prime_utr_intron1.five_prime_utr_intron_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    five_prime_utr_intron AS five_prime_utr_intron2 ON (five_prime_utr_intron1.five_prime_utr_intron_id = fr2.subject_id)
;

--- ************************************************
--- *** relation: five_prime_utr_intron_invsib   ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "five_prime_UTR_intron"
CREATE VIEW five_prime_utr_intron_invsib AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    five_prime_utr_intron1.feature_id AS feature_id1,
    five_prime_utr_intron1.dbxref_id AS dbxref_id1,
    five_prime_utr_intron1.organism_id AS organism_id1,
    five_prime_utr_intron1.name AS name1,
    five_prime_utr_intron1.uniquename AS uniquename1,
    five_prime_utr_intron1.residues AS residues1,
    five_prime_utr_intron1.seqlen AS seqlen1,
    five_prime_utr_intron1.md5checksum AS md5checksum1,
    five_prime_utr_intron1.type_id AS type_id1,
    five_prime_utr_intron1.is_analysis AS is_analysis1,
    five_prime_utr_intron1.timeaccessioned AS timeaccessioned1,
    five_prime_utr_intron1.timelastmodified AS timelastmodified1,
    five_prime_utr_intron2.feature_id AS feature_id2,
    five_prime_utr_intron2.dbxref_id AS dbxref_id2,
    five_prime_utr_intron2.organism_id AS organism_id2,
    five_prime_utr_intron2.name AS name2,
    five_prime_utr_intron2.uniquename AS uniquename2,
    five_prime_utr_intron2.residues AS residues2,
    five_prime_utr_intron2.seqlen AS seqlen2,
    five_prime_utr_intron2.md5checksum AS md5checksum2,
    five_prime_utr_intron2.type_id AS type_id2,
    five_prime_utr_intron2.is_analysis AS is_analysis2,
    five_prime_utr_intron2.timeaccessioned AS timeaccessioned2,
    five_prime_utr_intron2.timelastmodified AS timelastmodified2
  FROM
    five_prime_utr_intron AS five_prime_utr_intron1 INNER JOIN
    feature_relationship AS fr1 ON (five_prime_utr_intron1.five_prime_utr_intron_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    five_prime_utr_intron AS five_prime_utr_intron2 ON (five_prime_utr_intron1.five_prime_utr_intron_id = fr2.object_id);


--- ************************************************
--- *** relation: csib_five_prime_utr_intron     ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Sibling View   ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "five_prime_UTR_intron"
CREATE VIEW csib_five_prime_utr_intron AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    five_prime_utr_intron1.feature_id AS feature_id1,
    five_prime_utr_intron1.dbxref_id AS dbxref_id1,
    five_prime_utr_intron1.organism_id AS organism_id1,
    five_prime_utr_intron1.name AS name1,
    five_prime_utr_intron1.uniquename AS uniquename1,
    five_prime_utr_intron1.residues AS residues1,
    five_prime_utr_intron1.seqlen AS seqlen1,
    five_prime_utr_intron1.md5checksum AS md5checksum1,
    five_prime_utr_intron1.type_id AS type_id1,
    five_prime_utr_intron1.is_analysis AS is_analysis1,
    five_prime_utr_intron1.timeaccessioned AS timeaccessioned1,
    five_prime_utr_intron1.timelastmodified AS timelastmodified1,
    five_prime_utr_intron2.feature_id AS feature_id2,
    five_prime_utr_intron2.dbxref_id AS dbxref_id2,
    five_prime_utr_intron2.organism_id AS organism_id2,
    five_prime_utr_intron2.name AS name2,
    five_prime_utr_intron2.uniquename AS uniquename2,
    five_prime_utr_intron2.residues AS residues2,
    five_prime_utr_intron2.seqlen AS seqlen2,
    five_prime_utr_intron2.md5checksum AS md5checksum2,
    five_prime_utr_intron2.type_id AS type_id2,
    five_prime_utr_intron2.is_analysis AS is_analysis2,
    five_prime_utr_intron2.timeaccessioned AS timeaccessioned2,
    five_prime_utr_intron2.timelastmodified AS timelastmodified2
  FROM
    five_prime_utr_intron AS five_prime_utr_intron1 INNER JOIN
    feature_relationship AS fr1 ON (five_prime_utr_intron1.five_prime_utr_intron_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    five_prime_utr_intron AS five_prime_utr_intron2 ON (five_prime_utr_intron1.five_prime_utr_intron_id = fr2.subject_id)
  WHERE fr2.rank - fr1.rank = 1
;

--- ************************************************
--- *** relation: cfive_prime_utr_intron_invsib  ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "five_prime_UTR_intron"
CREATE VIEW cfive_prime_utr_intron_invsib AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    five_prime_utr_intron1.feature_id AS feature_id1,
    five_prime_utr_intron1.dbxref_id AS dbxref_id1,
    five_prime_utr_intron1.organism_id AS organism_id1,
    five_prime_utr_intron1.name AS name1,
    five_prime_utr_intron1.uniquename AS uniquename1,
    five_prime_utr_intron1.residues AS residues1,
    five_prime_utr_intron1.seqlen AS seqlen1,
    five_prime_utr_intron1.md5checksum AS md5checksum1,
    five_prime_utr_intron1.type_id AS type_id1,
    five_prime_utr_intron1.is_analysis AS is_analysis1,
    five_prime_utr_intron1.timeaccessioned AS timeaccessioned1,
    five_prime_utr_intron1.timelastmodified AS timelastmodified1,
    five_prime_utr_intron2.feature_id AS feature_id2,
    five_prime_utr_intron2.dbxref_id AS dbxref_id2,
    five_prime_utr_intron2.organism_id AS organism_id2,
    five_prime_utr_intron2.name AS name2,
    five_prime_utr_intron2.uniquename AS uniquename2,
    five_prime_utr_intron2.residues AS residues2,
    five_prime_utr_intron2.seqlen AS seqlen2,
    five_prime_utr_intron2.md5checksum AS md5checksum2,
    five_prime_utr_intron2.type_id AS type_id2,
    five_prime_utr_intron2.is_analysis AS is_analysis2,
    five_prime_utr_intron2.timeaccessioned AS timeaccessioned2,
    five_prime_utr_intron2.timelastmodified AS timelastmodified2
  FROM
    five_prime_utr_intron AS five_prime_utr_intron1 INNER JOIN
    feature_relationship AS fr1 ON (five_prime_utr_intron1.five_prime_utr_intron_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    five_prime_utr_intron AS five_prime_utr_intron2 ON (five_prime_utr_intron1.five_prime_utr_intron_id = fr2.object_id);


--- ************************************************
--- *** relation: centromere                     ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology 'Typed Feature' View   ***
--- ***                                          ***
--- ************************************************
---
--- SO Term:
--- "centromere"

CREATE VIEW centromere AS
  SELECT
    feature_id AS centromere_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'centromere';

--- ************************************************
--- *** relation: sib_centromere                 ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Sibling View   ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "centromere"
CREATE VIEW sib_centromere AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    centromere1.feature_id AS feature_id1,
    centromere1.dbxref_id AS dbxref_id1,
    centromere1.organism_id AS organism_id1,
    centromere1.name AS name1,
    centromere1.uniquename AS uniquename1,
    centromere1.residues AS residues1,
    centromere1.seqlen AS seqlen1,
    centromere1.md5checksum AS md5checksum1,
    centromere1.type_id AS type_id1,
    centromere1.is_analysis AS is_analysis1,
    centromere1.timeaccessioned AS timeaccessioned1,
    centromere1.timelastmodified AS timelastmodified1,
    centromere2.feature_id AS feature_id2,
    centromere2.dbxref_id AS dbxref_id2,
    centromere2.organism_id AS organism_id2,
    centromere2.name AS name2,
    centromere2.uniquename AS uniquename2,
    centromere2.residues AS residues2,
    centromere2.seqlen AS seqlen2,
    centromere2.md5checksum AS md5checksum2,
    centromere2.type_id AS type_id2,
    centromere2.is_analysis AS is_analysis2,
    centromere2.timeaccessioned AS timeaccessioned2,
    centromere2.timelastmodified AS timelastmodified2
  FROM
    centromere AS centromere1 INNER JOIN
    feature_relationship AS fr1 ON (centromere1.centromere_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    centromere AS centromere2 ON (centromere1.centromere_id = fr2.subject_id)
;

--- ************************************************
--- *** relation: centromere_invsib              ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "centromere"
CREATE VIEW centromere_invsib AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    centromere1.feature_id AS feature_id1,
    centromere1.dbxref_id AS dbxref_id1,
    centromere1.organism_id AS organism_id1,
    centromere1.name AS name1,
    centromere1.uniquename AS uniquename1,
    centromere1.residues AS residues1,
    centromere1.seqlen AS seqlen1,
    centromere1.md5checksum AS md5checksum1,
    centromere1.type_id AS type_id1,
    centromere1.is_analysis AS is_analysis1,
    centromere1.timeaccessioned AS timeaccessioned1,
    centromere1.timelastmodified AS timelastmodified1,
    centromere2.feature_id AS feature_id2,
    centromere2.dbxref_id AS dbxref_id2,
    centromere2.organism_id AS organism_id2,
    centromere2.name AS name2,
    centromere2.uniquename AS uniquename2,
    centromere2.residues AS residues2,
    centromere2.seqlen AS seqlen2,
    centromere2.md5checksum AS md5checksum2,
    centromere2.type_id AS type_id2,
    centromere2.is_analysis AS is_analysis2,
    centromere2.timeaccessioned AS timeaccessioned2,
    centromere2.timelastmodified AS timelastmodified2
  FROM
    centromere AS centromere1 INNER JOIN
    feature_relationship AS fr1 ON (centromere1.centromere_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    centromere AS centromere2 ON (centromere1.centromere_id = fr2.object_id);


--- ************************************************
--- *** relation: csib_centromere                ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Sibling View   ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "centromere"
CREATE VIEW csib_centromere AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    centromere1.feature_id AS feature_id1,
    centromere1.dbxref_id AS dbxref_id1,
    centromere1.organism_id AS organism_id1,
    centromere1.name AS name1,
    centromere1.uniquename AS uniquename1,
    centromere1.residues AS residues1,
    centromere1.seqlen AS seqlen1,
    centromere1.md5checksum AS md5checksum1,
    centromere1.type_id AS type_id1,
    centromere1.is_analysis AS is_analysis1,
    centromere1.timeaccessioned AS timeaccessioned1,
    centromere1.timelastmodified AS timelastmodified1,
    centromere2.feature_id AS feature_id2,
    centromere2.dbxref_id AS dbxref_id2,
    centromere2.organism_id AS organism_id2,
    centromere2.name AS name2,
    centromere2.uniquename AS uniquename2,
    centromere2.residues AS residues2,
    centromere2.seqlen AS seqlen2,
    centromere2.md5checksum AS md5checksum2,
    centromere2.type_id AS type_id2,
    centromere2.is_analysis AS is_analysis2,
    centromere2.timeaccessioned AS timeaccessioned2,
    centromere2.timelastmodified AS timelastmodified2
  FROM
    centromere AS centromere1 INNER JOIN
    feature_relationship AS fr1 ON (centromere1.centromere_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    centromere AS centromere2 ON (centromere1.centromere_id = fr2.subject_id)
  WHERE fr2.rank - fr1.rank = 1
;

--- ************************************************
--- *** relation: ccentromere_invsib             ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "centromere"
CREATE VIEW ccentromere_invsib AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    centromere1.feature_id AS feature_id1,
    centromere1.dbxref_id AS dbxref_id1,
    centromere1.organism_id AS organism_id1,
    centromere1.name AS name1,
    centromere1.uniquename AS uniquename1,
    centromere1.residues AS residues1,
    centromere1.seqlen AS seqlen1,
    centromere1.md5checksum AS md5checksum1,
    centromere1.type_id AS type_id1,
    centromere1.is_analysis AS is_analysis1,
    centromere1.timeaccessioned AS timeaccessioned1,
    centromere1.timelastmodified AS timelastmodified1,
    centromere2.feature_id AS feature_id2,
    centromere2.dbxref_id AS dbxref_id2,
    centromere2.organism_id AS organism_id2,
    centromere2.name AS name2,
    centromere2.uniquename AS uniquename2,
    centromere2.residues AS residues2,
    centromere2.seqlen AS seqlen2,
    centromere2.md5checksum AS md5checksum2,
    centromere2.type_id AS type_id2,
    centromere2.is_analysis AS is_analysis2,
    centromere2.timeaccessioned AS timeaccessioned2,
    centromere2.timelastmodified AS timelastmodified2
  FROM
    centromere AS centromere1 INNER JOIN
    feature_relationship AS fr1 ON (centromere1.centromere_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    centromere AS centromere2 ON (centromere1.centromere_id = fr2.object_id);


--- ************************************************
--- *** relation: telomere                       ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology 'Typed Feature' View   ***
--- ***                                          ***
--- ************************************************
---
--- SO Term:
--- "telomere"

CREATE VIEW telomere AS
  SELECT
    feature_id AS telomere_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'telomere';

--- ************************************************
--- *** relation: sib_telomere                   ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Sibling View   ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "telomere"
CREATE VIEW sib_telomere AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    telomere1.feature_id AS feature_id1,
    telomere1.dbxref_id AS dbxref_id1,
    telomere1.organism_id AS organism_id1,
    telomere1.name AS name1,
    telomere1.uniquename AS uniquename1,
    telomere1.residues AS residues1,
    telomere1.seqlen AS seqlen1,
    telomere1.md5checksum AS md5checksum1,
    telomere1.type_id AS type_id1,
    telomere1.is_analysis AS is_analysis1,
    telomere1.timeaccessioned AS timeaccessioned1,
    telomere1.timelastmodified AS timelastmodified1,
    telomere2.feature_id AS feature_id2,
    telomere2.dbxref_id AS dbxref_id2,
    telomere2.organism_id AS organism_id2,
    telomere2.name AS name2,
    telomere2.uniquename AS uniquename2,
    telomere2.residues AS residues2,
    telomere2.seqlen AS seqlen2,
    telomere2.md5checksum AS md5checksum2,
    telomere2.type_id AS type_id2,
    telomere2.is_analysis AS is_analysis2,
    telomere2.timeaccessioned AS timeaccessioned2,
    telomere2.timelastmodified AS timelastmodified2
  FROM
    telomere AS telomere1 INNER JOIN
    feature_relationship AS fr1 ON (telomere1.telomere_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    telomere AS telomere2 ON (telomere1.telomere_id = fr2.subject_id)
;

--- ************************************************
--- *** relation: telomere_invsib                ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "telomere"
CREATE VIEW telomere_invsib AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    telomere1.feature_id AS feature_id1,
    telomere1.dbxref_id AS dbxref_id1,
    telomere1.organism_id AS organism_id1,
    telomere1.name AS name1,
    telomere1.uniquename AS uniquename1,
    telomere1.residues AS residues1,
    telomere1.seqlen AS seqlen1,
    telomere1.md5checksum AS md5checksum1,
    telomere1.type_id AS type_id1,
    telomere1.is_analysis AS is_analysis1,
    telomere1.timeaccessioned AS timeaccessioned1,
    telomere1.timelastmodified AS timelastmodified1,
    telomere2.feature_id AS feature_id2,
    telomere2.dbxref_id AS dbxref_id2,
    telomere2.organism_id AS organism_id2,
    telomere2.name AS name2,
    telomere2.uniquename AS uniquename2,
    telomere2.residues AS residues2,
    telomere2.seqlen AS seqlen2,
    telomere2.md5checksum AS md5checksum2,
    telomere2.type_id AS type_id2,
    telomere2.is_analysis AS is_analysis2,
    telomere2.timeaccessioned AS timeaccessioned2,
    telomere2.timelastmodified AS timelastmodified2
  FROM
    telomere AS telomere1 INNER JOIN
    feature_relationship AS fr1 ON (telomere1.telomere_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    telomere AS telomere2 ON (telomere1.telomere_id = fr2.object_id);


--- ************************************************
--- *** relation: csib_telomere                  ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Sibling View   ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "telomere"
CREATE VIEW csib_telomere AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    telomere1.feature_id AS feature_id1,
    telomere1.dbxref_id AS dbxref_id1,
    telomere1.organism_id AS organism_id1,
    telomere1.name AS name1,
    telomere1.uniquename AS uniquename1,
    telomere1.residues AS residues1,
    telomere1.seqlen AS seqlen1,
    telomere1.md5checksum AS md5checksum1,
    telomere1.type_id AS type_id1,
    telomere1.is_analysis AS is_analysis1,
    telomere1.timeaccessioned AS timeaccessioned1,
    telomere1.timelastmodified AS timelastmodified1,
    telomere2.feature_id AS feature_id2,
    telomere2.dbxref_id AS dbxref_id2,
    telomere2.organism_id AS organism_id2,
    telomere2.name AS name2,
    telomere2.uniquename AS uniquename2,
    telomere2.residues AS residues2,
    telomere2.seqlen AS seqlen2,
    telomere2.md5checksum AS md5checksum2,
    telomere2.type_id AS type_id2,
    telomere2.is_analysis AS is_analysis2,
    telomere2.timeaccessioned AS timeaccessioned2,
    telomere2.timelastmodified AS timelastmodified2
  FROM
    telomere AS telomere1 INNER JOIN
    feature_relationship AS fr1 ON (telomere1.telomere_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    telomere AS telomere2 ON (telomere1.telomere_id = fr2.subject_id)
  WHERE fr2.rank - fr1.rank = 1
;

--- ************************************************
--- *** relation: ctelomere_invsib               ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "telomere"
CREATE VIEW ctelomere_invsib AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    telomere1.feature_id AS feature_id1,
    telomere1.dbxref_id AS dbxref_id1,
    telomere1.organism_id AS organism_id1,
    telomere1.name AS name1,
    telomere1.uniquename AS uniquename1,
    telomere1.residues AS residues1,
    telomere1.seqlen AS seqlen1,
    telomere1.md5checksum AS md5checksum1,
    telomere1.type_id AS type_id1,
    telomere1.is_analysis AS is_analysis1,
    telomere1.timeaccessioned AS timeaccessioned1,
    telomere1.timelastmodified AS timelastmodified1,
    telomere2.feature_id AS feature_id2,
    telomere2.dbxref_id AS dbxref_id2,
    telomere2.organism_id AS organism_id2,
    telomere2.name AS name2,
    telomere2.uniquename AS uniquename2,
    telomere2.residues AS residues2,
    telomere2.seqlen AS seqlen2,
    telomere2.md5checksum AS md5checksum2,
    telomere2.type_id AS type_id2,
    telomere2.is_analysis AS is_analysis2,
    telomere2.timeaccessioned AS timeaccessioned2,
    telomere2.timelastmodified AS timelastmodified2
  FROM
    telomere AS telomere1 INNER JOIN
    feature_relationship AS fr1 ON (telomere1.telomere_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    telomere AS telomere2 ON (telomere1.telomere_id = fr2.object_id);


--- ************************************************
--- *** relation: i_transcribed_spacer_region    ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology 'Typed Feature' View   ***
--- ***                                          ***
--- ************************************************
---
--- SO Term:
--- "internal_transcribed_spacer_region"

CREATE VIEW i_transcribed_spacer_region AS
  SELECT
    feature_id AS i_transcribed_spacer_region_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'internal_transcribed_spacer_region';

--- ************************************************
--- *** relation: sib_i_transcribed_spacer_region***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Sibling View   ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "internal_transcribed_spacer_region"
CREATE VIEW sib_i_transcribed_spacer_region AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    i_transcribed_spacer_region1.feature_id AS feature_id1,
    i_transcribed_spacer_region1.dbxref_id AS dbxref_id1,
    i_transcribed_spacer_region1.organism_id AS organism_id1,
    i_transcribed_spacer_region1.name AS name1,
    i_transcribed_spacer_region1.uniquename AS uniquename1,
    i_transcribed_spacer_region1.residues AS residues1,
    i_transcribed_spacer_region1.seqlen AS seqlen1,
    i_transcribed_spacer_region1.md5checksum AS md5checksum1,
    i_transcribed_spacer_region1.type_id AS type_id1,
    i_transcribed_spacer_region1.is_analysis AS is_analysis1,
    i_transcribed_spacer_region1.timeaccessioned AS timeaccessioned1,
    i_transcribed_spacer_region1.timelastmodified AS timelastmodified1,
    i_transcribed_spacer_region2.feature_id AS feature_id2,
    i_transcribed_spacer_region2.dbxref_id AS dbxref_id2,
    i_transcribed_spacer_region2.organism_id AS organism_id2,
    i_transcribed_spacer_region2.name AS name2,
    i_transcribed_spacer_region2.uniquename AS uniquename2,
    i_transcribed_spacer_region2.residues AS residues2,
    i_transcribed_spacer_region2.seqlen AS seqlen2,
    i_transcribed_spacer_region2.md5checksum AS md5checksum2,
    i_transcribed_spacer_region2.type_id AS type_id2,
    i_transcribed_spacer_region2.is_analysis AS is_analysis2,
    i_transcribed_spacer_region2.timeaccessioned AS timeaccessioned2,
    i_transcribed_spacer_region2.timelastmodified AS timelastmodified2
  FROM
    i_transcribed_spacer_region AS i_transcribed_spacer_region1 INNER JOIN
    feature_relationship AS fr1 ON (i_transcribed_spacer_region1.i_transcribed_spacer_region_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    i_transcribed_spacer_region AS i_transcribed_spacer_region2 ON (i_transcribed_spacer_region1.i_transcribed_spacer_region_id = fr2.subject_id)
;

--- ************************************************
--- *** relation: i_transcribed_spacer_region_invsib***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "internal_transcribed_spacer_region"
CREATE VIEW i_transcribed_spacer_region_invsib AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    i_transcribed_spacer_region1.feature_id AS feature_id1,
    i_transcribed_spacer_region1.dbxref_id AS dbxref_id1,
    i_transcribed_spacer_region1.organism_id AS organism_id1,
    i_transcribed_spacer_region1.name AS name1,
    i_transcribed_spacer_region1.uniquename AS uniquename1,
    i_transcribed_spacer_region1.residues AS residues1,
    i_transcribed_spacer_region1.seqlen AS seqlen1,
    i_transcribed_spacer_region1.md5checksum AS md5checksum1,
    i_transcribed_spacer_region1.type_id AS type_id1,
    i_transcribed_spacer_region1.is_analysis AS is_analysis1,
    i_transcribed_spacer_region1.timeaccessioned AS timeaccessioned1,
    i_transcribed_spacer_region1.timelastmodified AS timelastmodified1,
    i_transcribed_spacer_region2.feature_id AS feature_id2,
    i_transcribed_spacer_region2.dbxref_id AS dbxref_id2,
    i_transcribed_spacer_region2.organism_id AS organism_id2,
    i_transcribed_spacer_region2.name AS name2,
    i_transcribed_spacer_region2.uniquename AS uniquename2,
    i_transcribed_spacer_region2.residues AS residues2,
    i_transcribed_spacer_region2.seqlen AS seqlen2,
    i_transcribed_spacer_region2.md5checksum AS md5checksum2,
    i_transcribed_spacer_region2.type_id AS type_id2,
    i_transcribed_spacer_region2.is_analysis AS is_analysis2,
    i_transcribed_spacer_region2.timeaccessioned AS timeaccessioned2,
    i_transcribed_spacer_region2.timelastmodified AS timelastmodified2
  FROM
    i_transcribed_spacer_region AS i_transcribed_spacer_region1 INNER JOIN
    feature_relationship AS fr1 ON (i_transcribed_spacer_region1.i_transcribed_spacer_region_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    i_transcribed_spacer_region AS i_transcribed_spacer_region2 ON (i_transcribed_spacer_region1.i_transcribed_spacer_region_id = fr2.object_id);


--- ************************************************
--- *** relation: csib_i_transcribed_spacer_region***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Sibling View   ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "internal_transcribed_spacer_region"
CREATE VIEW csib_i_transcribed_spacer_region AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    i_transcribed_spacer_region1.feature_id AS feature_id1,
    i_transcribed_spacer_region1.dbxref_id AS dbxref_id1,
    i_transcribed_spacer_region1.organism_id AS organism_id1,
    i_transcribed_spacer_region1.name AS name1,
    i_transcribed_spacer_region1.uniquename AS uniquename1,
    i_transcribed_spacer_region1.residues AS residues1,
    i_transcribed_spacer_region1.seqlen AS seqlen1,
    i_transcribed_spacer_region1.md5checksum AS md5checksum1,
    i_transcribed_spacer_region1.type_id AS type_id1,
    i_transcribed_spacer_region1.is_analysis AS is_analysis1,
    i_transcribed_spacer_region1.timeaccessioned AS timeaccessioned1,
    i_transcribed_spacer_region1.timelastmodified AS timelastmodified1,
    i_transcribed_spacer_region2.feature_id AS feature_id2,
    i_transcribed_spacer_region2.dbxref_id AS dbxref_id2,
    i_transcribed_spacer_region2.organism_id AS organism_id2,
    i_transcribed_spacer_region2.name AS name2,
    i_transcribed_spacer_region2.uniquename AS uniquename2,
    i_transcribed_spacer_region2.residues AS residues2,
    i_transcribed_spacer_region2.seqlen AS seqlen2,
    i_transcribed_spacer_region2.md5checksum AS md5checksum2,
    i_transcribed_spacer_region2.type_id AS type_id2,
    i_transcribed_spacer_region2.is_analysis AS is_analysis2,
    i_transcribed_spacer_region2.timeaccessioned AS timeaccessioned2,
    i_transcribed_spacer_region2.timelastmodified AS timelastmodified2
  FROM
    i_transcribed_spacer_region AS i_transcribed_spacer_region1 INNER JOIN
    feature_relationship AS fr1 ON (i_transcribed_spacer_region1.i_transcribed_spacer_region_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    i_transcribed_spacer_region AS i_transcribed_spacer_region2 ON (i_transcribed_spacer_region1.i_transcribed_spacer_region_id = fr2.subject_id)
  WHERE fr2.rank - fr1.rank = 1
;

--- ************************************************
--- *** relation: ci_transcribed_spacer_region_invsib***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "internal_transcribed_spacer_region"
CREATE VIEW ci_transcribed_spacer_region_invsib AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    i_transcribed_spacer_region1.feature_id AS feature_id1,
    i_transcribed_spacer_region1.dbxref_id AS dbxref_id1,
    i_transcribed_spacer_region1.organism_id AS organism_id1,
    i_transcribed_spacer_region1.name AS name1,
    i_transcribed_spacer_region1.uniquename AS uniquename1,
    i_transcribed_spacer_region1.residues AS residues1,
    i_transcribed_spacer_region1.seqlen AS seqlen1,
    i_transcribed_spacer_region1.md5checksum AS md5checksum1,
    i_transcribed_spacer_region1.type_id AS type_id1,
    i_transcribed_spacer_region1.is_analysis AS is_analysis1,
    i_transcribed_spacer_region1.timeaccessioned AS timeaccessioned1,
    i_transcribed_spacer_region1.timelastmodified AS timelastmodified1,
    i_transcribed_spacer_region2.feature_id AS feature_id2,
    i_transcribed_spacer_region2.dbxref_id AS dbxref_id2,
    i_transcribed_spacer_region2.organism_id AS organism_id2,
    i_transcribed_spacer_region2.name AS name2,
    i_transcribed_spacer_region2.uniquename AS uniquename2,
    i_transcribed_spacer_region2.residues AS residues2,
    i_transcribed_spacer_region2.seqlen AS seqlen2,
    i_transcribed_spacer_region2.md5checksum AS md5checksum2,
    i_transcribed_spacer_region2.type_id AS type_id2,
    i_transcribed_spacer_region2.is_analysis AS is_analysis2,
    i_transcribed_spacer_region2.timeaccessioned AS timeaccessioned2,
    i_transcribed_spacer_region2.timelastmodified AS timelastmodified2
  FROM
    i_transcribed_spacer_region AS i_transcribed_spacer_region1 INNER JOIN
    feature_relationship AS fr1 ON (i_transcribed_spacer_region1.i_transcribed_spacer_region_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    i_transcribed_spacer_region AS i_transcribed_spacer_region2 ON (i_transcribed_spacer_region1.i_transcribed_spacer_region_id = fr2.object_id);


--- ************************************************
--- *** relation: e_transcribed_spacer_region    ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology 'Typed Feature' View   ***
--- ***                                          ***
--- ************************************************
---
--- SO Term:
--- "external_transcribed_spacer_region"

CREATE VIEW e_transcribed_spacer_region AS
  SELECT
    feature_id AS e_transcribed_spacer_region_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'external_transcribed_spacer_region';

--- ************************************************
--- *** relation: sib_e_transcribed_spacer_region***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Sibling View   ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "external_transcribed_spacer_region"
CREATE VIEW sib_e_transcribed_spacer_region AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    e_transcribed_spacer_region1.feature_id AS feature_id1,
    e_transcribed_spacer_region1.dbxref_id AS dbxref_id1,
    e_transcribed_spacer_region1.organism_id AS organism_id1,
    e_transcribed_spacer_region1.name AS name1,
    e_transcribed_spacer_region1.uniquename AS uniquename1,
    e_transcribed_spacer_region1.residues AS residues1,
    e_transcribed_spacer_region1.seqlen AS seqlen1,
    e_transcribed_spacer_region1.md5checksum AS md5checksum1,
    e_transcribed_spacer_region1.type_id AS type_id1,
    e_transcribed_spacer_region1.is_analysis AS is_analysis1,
    e_transcribed_spacer_region1.timeaccessioned AS timeaccessioned1,
    e_transcribed_spacer_region1.timelastmodified AS timelastmodified1,
    e_transcribed_spacer_region2.feature_id AS feature_id2,
    e_transcribed_spacer_region2.dbxref_id AS dbxref_id2,
    e_transcribed_spacer_region2.organism_id AS organism_id2,
    e_transcribed_spacer_region2.name AS name2,
    e_transcribed_spacer_region2.uniquename AS uniquename2,
    e_transcribed_spacer_region2.residues AS residues2,
    e_transcribed_spacer_region2.seqlen AS seqlen2,
    e_transcribed_spacer_region2.md5checksum AS md5checksum2,
    e_transcribed_spacer_region2.type_id AS type_id2,
    e_transcribed_spacer_region2.is_analysis AS is_analysis2,
    e_transcribed_spacer_region2.timeaccessioned AS timeaccessioned2,
    e_transcribed_spacer_region2.timelastmodified AS timelastmodified2
  FROM
    e_transcribed_spacer_region AS e_transcribed_spacer_region1 INNER JOIN
    feature_relationship AS fr1 ON (e_transcribed_spacer_region1.e_transcribed_spacer_region_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    e_transcribed_spacer_region AS e_transcribed_spacer_region2 ON (e_transcribed_spacer_region1.e_transcribed_spacer_region_id = fr2.subject_id)
;

--- ************************************************
--- *** relation: e_transcribed_spacer_region_invsib***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "external_transcribed_spacer_region"
CREATE VIEW e_transcribed_spacer_region_invsib AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    e_transcribed_spacer_region1.feature_id AS feature_id1,
    e_transcribed_spacer_region1.dbxref_id AS dbxref_id1,
    e_transcribed_spacer_region1.organism_id AS organism_id1,
    e_transcribed_spacer_region1.name AS name1,
    e_transcribed_spacer_region1.uniquename AS uniquename1,
    e_transcribed_spacer_region1.residues AS residues1,
    e_transcribed_spacer_region1.seqlen AS seqlen1,
    e_transcribed_spacer_region1.md5checksum AS md5checksum1,
    e_transcribed_spacer_region1.type_id AS type_id1,
    e_transcribed_spacer_region1.is_analysis AS is_analysis1,
    e_transcribed_spacer_region1.timeaccessioned AS timeaccessioned1,
    e_transcribed_spacer_region1.timelastmodified AS timelastmodified1,
    e_transcribed_spacer_region2.feature_id AS feature_id2,
    e_transcribed_spacer_region2.dbxref_id AS dbxref_id2,
    e_transcribed_spacer_region2.organism_id AS organism_id2,
    e_transcribed_spacer_region2.name AS name2,
    e_transcribed_spacer_region2.uniquename AS uniquename2,
    e_transcribed_spacer_region2.residues AS residues2,
    e_transcribed_spacer_region2.seqlen AS seqlen2,
    e_transcribed_spacer_region2.md5checksum AS md5checksum2,
    e_transcribed_spacer_region2.type_id AS type_id2,
    e_transcribed_spacer_region2.is_analysis AS is_analysis2,
    e_transcribed_spacer_region2.timeaccessioned AS timeaccessioned2,
    e_transcribed_spacer_region2.timelastmodified AS timelastmodified2
  FROM
    e_transcribed_spacer_region AS e_transcribed_spacer_region1 INNER JOIN
    feature_relationship AS fr1 ON (e_transcribed_spacer_region1.e_transcribed_spacer_region_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    e_transcribed_spacer_region AS e_transcribed_spacer_region2 ON (e_transcribed_spacer_region1.e_transcribed_spacer_region_id = fr2.object_id);


--- ************************************************
--- *** relation: csib_e_transcribed_spacer_region***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Sibling View   ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "external_transcribed_spacer_region"
CREATE VIEW csib_e_transcribed_spacer_region AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    e_transcribed_spacer_region1.feature_id AS feature_id1,
    e_transcribed_spacer_region1.dbxref_id AS dbxref_id1,
    e_transcribed_spacer_region1.organism_id AS organism_id1,
    e_transcribed_spacer_region1.name AS name1,
    e_transcribed_spacer_region1.uniquename AS uniquename1,
    e_transcribed_spacer_region1.residues AS residues1,
    e_transcribed_spacer_region1.seqlen AS seqlen1,
    e_transcribed_spacer_region1.md5checksum AS md5checksum1,
    e_transcribed_spacer_region1.type_id AS type_id1,
    e_transcribed_spacer_region1.is_analysis AS is_analysis1,
    e_transcribed_spacer_region1.timeaccessioned AS timeaccessioned1,
    e_transcribed_spacer_region1.timelastmodified AS timelastmodified1,
    e_transcribed_spacer_region2.feature_id AS feature_id2,
    e_transcribed_spacer_region2.dbxref_id AS dbxref_id2,
    e_transcribed_spacer_region2.organism_id AS organism_id2,
    e_transcribed_spacer_region2.name AS name2,
    e_transcribed_spacer_region2.uniquename AS uniquename2,
    e_transcribed_spacer_region2.residues AS residues2,
    e_transcribed_spacer_region2.seqlen AS seqlen2,
    e_transcribed_spacer_region2.md5checksum AS md5checksum2,
    e_transcribed_spacer_region2.type_id AS type_id2,
    e_transcribed_spacer_region2.is_analysis AS is_analysis2,
    e_transcribed_spacer_region2.timeaccessioned AS timeaccessioned2,
    e_transcribed_spacer_region2.timelastmodified AS timelastmodified2
  FROM
    e_transcribed_spacer_region AS e_transcribed_spacer_region1 INNER JOIN
    feature_relationship AS fr1 ON (e_transcribed_spacer_region1.e_transcribed_spacer_region_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    e_transcribed_spacer_region AS e_transcribed_spacer_region2 ON (e_transcribed_spacer_region1.e_transcribed_spacer_region_id = fr2.subject_id)
  WHERE fr2.rank - fr1.rank = 1
;

--- ************************************************
--- *** relation: ce_transcribed_spacer_region_invsib***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "external_transcribed_spacer_region"
CREATE VIEW ce_transcribed_spacer_region_invsib AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    e_transcribed_spacer_region1.feature_id AS feature_id1,
    e_transcribed_spacer_region1.dbxref_id AS dbxref_id1,
    e_transcribed_spacer_region1.organism_id AS organism_id1,
    e_transcribed_spacer_region1.name AS name1,
    e_transcribed_spacer_region1.uniquename AS uniquename1,
    e_transcribed_spacer_region1.residues AS residues1,
    e_transcribed_spacer_region1.seqlen AS seqlen1,
    e_transcribed_spacer_region1.md5checksum AS md5checksum1,
    e_transcribed_spacer_region1.type_id AS type_id1,
    e_transcribed_spacer_region1.is_analysis AS is_analysis1,
    e_transcribed_spacer_region1.timeaccessioned AS timeaccessioned1,
    e_transcribed_spacer_region1.timelastmodified AS timelastmodified1,
    e_transcribed_spacer_region2.feature_id AS feature_id2,
    e_transcribed_spacer_region2.dbxref_id AS dbxref_id2,
    e_transcribed_spacer_region2.organism_id AS organism_id2,
    e_transcribed_spacer_region2.name AS name2,
    e_transcribed_spacer_region2.uniquename AS uniquename2,
    e_transcribed_spacer_region2.residues AS residues2,
    e_transcribed_spacer_region2.seqlen AS seqlen2,
    e_transcribed_spacer_region2.md5checksum AS md5checksum2,
    e_transcribed_spacer_region2.type_id AS type_id2,
    e_transcribed_spacer_region2.is_analysis AS is_analysis2,
    e_transcribed_spacer_region2.timeaccessioned AS timeaccessioned2,
    e_transcribed_spacer_region2.timelastmodified AS timelastmodified2
  FROM
    e_transcribed_spacer_region AS e_transcribed_spacer_region1 INNER JOIN
    feature_relationship AS fr1 ON (e_transcribed_spacer_region1.e_transcribed_spacer_region_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    e_transcribed_spacer_region AS e_transcribed_spacer_region2 ON (e_transcribed_spacer_region1.e_transcribed_spacer_region_id = fr2.object_id);


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
--- *** relation: sib_ncrna                      ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Sibling View   ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "ncRNA"
CREATE VIEW sib_ncrna AS
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
    ncrna AS ncrna2 ON (ncrna1.ncrna_id = fr2.subject_id)
;

--- ************************************************
--- *** relation: ncrna_invsib                   ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "ncRNA"
CREATE VIEW ncrna_invsib AS
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
--- *** relation: csib_ncrna                     ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Sibling View   ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "ncRNA"
CREATE VIEW csib_ncrna AS
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
    ncrna AS ncrna2 ON (ncrna1.ncrna_id = fr2.subject_id)
  WHERE fr2.rank - fr1.rank = 1
;

--- ************************************************
--- *** relation: cncrna_invsib                  ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "ncRNA"
CREATE VIEW cncrna_invsib AS
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
--- *** relation: sib_repeat_region              ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Sibling View   ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "repeat_region"
CREATE VIEW sib_repeat_region AS
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
    repeat_region AS repeat_region2 ON (repeat_region1.repeat_region_id = fr2.subject_id)
;

--- ************************************************
--- *** relation: repeat_region_invsib           ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "repeat_region"
CREATE VIEW repeat_region_invsib AS
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
--- *** relation: csib_repeat_region             ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Sibling View   ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "repeat_region"
CREATE VIEW csib_repeat_region AS
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
    repeat_region AS repeat_region2 ON (repeat_region1.repeat_region_id = fr2.subject_id)
  WHERE fr2.rank - fr1.rank = 1
;

--- ************************************************
--- *** relation: crepeat_region_invsib          ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "repeat_region"
CREATE VIEW crepeat_region_invsib AS
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
--- *** relation: insertion                      ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology 'Typed Feature' View   ***
--- ***                                          ***
--- ************************************************
---
--- SO Term:
--- "insertion"

CREATE VIEW insertion AS
  SELECT
    feature_id AS insertion_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'insertion';

--- ************************************************
--- *** relation: sib_insertion                  ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Sibling View   ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "insertion"
CREATE VIEW sib_insertion AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    insertion1.feature_id AS feature_id1,
    insertion1.dbxref_id AS dbxref_id1,
    insertion1.organism_id AS organism_id1,
    insertion1.name AS name1,
    insertion1.uniquename AS uniquename1,
    insertion1.residues AS residues1,
    insertion1.seqlen AS seqlen1,
    insertion1.md5checksum AS md5checksum1,
    insertion1.type_id AS type_id1,
    insertion1.is_analysis AS is_analysis1,
    insertion1.timeaccessioned AS timeaccessioned1,
    insertion1.timelastmodified AS timelastmodified1,
    insertion2.feature_id AS feature_id2,
    insertion2.dbxref_id AS dbxref_id2,
    insertion2.organism_id AS organism_id2,
    insertion2.name AS name2,
    insertion2.uniquename AS uniquename2,
    insertion2.residues AS residues2,
    insertion2.seqlen AS seqlen2,
    insertion2.md5checksum AS md5checksum2,
    insertion2.type_id AS type_id2,
    insertion2.is_analysis AS is_analysis2,
    insertion2.timeaccessioned AS timeaccessioned2,
    insertion2.timelastmodified AS timelastmodified2
  FROM
    insertion AS insertion1 INNER JOIN
    feature_relationship AS fr1 ON (insertion1.insertion_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    insertion AS insertion2 ON (insertion1.insertion_id = fr2.subject_id)
;

--- ************************************************
--- *** relation: insertion_invsib               ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "insertion"
CREATE VIEW insertion_invsib AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    insertion1.feature_id AS feature_id1,
    insertion1.dbxref_id AS dbxref_id1,
    insertion1.organism_id AS organism_id1,
    insertion1.name AS name1,
    insertion1.uniquename AS uniquename1,
    insertion1.residues AS residues1,
    insertion1.seqlen AS seqlen1,
    insertion1.md5checksum AS md5checksum1,
    insertion1.type_id AS type_id1,
    insertion1.is_analysis AS is_analysis1,
    insertion1.timeaccessioned AS timeaccessioned1,
    insertion1.timelastmodified AS timelastmodified1,
    insertion2.feature_id AS feature_id2,
    insertion2.dbxref_id AS dbxref_id2,
    insertion2.organism_id AS organism_id2,
    insertion2.name AS name2,
    insertion2.uniquename AS uniquename2,
    insertion2.residues AS residues2,
    insertion2.seqlen AS seqlen2,
    insertion2.md5checksum AS md5checksum2,
    insertion2.type_id AS type_id2,
    insertion2.is_analysis AS is_analysis2,
    insertion2.timeaccessioned AS timeaccessioned2,
    insertion2.timelastmodified AS timelastmodified2
  FROM
    insertion AS insertion1 INNER JOIN
    feature_relationship AS fr1 ON (insertion1.insertion_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    insertion AS insertion2 ON (insertion1.insertion_id = fr2.object_id);


--- ************************************************
--- *** relation: csib_insertion                 ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Sibling View   ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "insertion"
CREATE VIEW csib_insertion AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    insertion1.feature_id AS feature_id1,
    insertion1.dbxref_id AS dbxref_id1,
    insertion1.organism_id AS organism_id1,
    insertion1.name AS name1,
    insertion1.uniquename AS uniquename1,
    insertion1.residues AS residues1,
    insertion1.seqlen AS seqlen1,
    insertion1.md5checksum AS md5checksum1,
    insertion1.type_id AS type_id1,
    insertion1.is_analysis AS is_analysis1,
    insertion1.timeaccessioned AS timeaccessioned1,
    insertion1.timelastmodified AS timelastmodified1,
    insertion2.feature_id AS feature_id2,
    insertion2.dbxref_id AS dbxref_id2,
    insertion2.organism_id AS organism_id2,
    insertion2.name AS name2,
    insertion2.uniquename AS uniquename2,
    insertion2.residues AS residues2,
    insertion2.seqlen AS seqlen2,
    insertion2.md5checksum AS md5checksum2,
    insertion2.type_id AS type_id2,
    insertion2.is_analysis AS is_analysis2,
    insertion2.timeaccessioned AS timeaccessioned2,
    insertion2.timelastmodified AS timelastmodified2
  FROM
    insertion AS insertion1 INNER JOIN
    feature_relationship AS fr1 ON (insertion1.insertion_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    insertion AS insertion2 ON (insertion1.insertion_id = fr2.subject_id)
  WHERE fr2.rank - fr1.rank = 1
;

--- ************************************************
--- *** relation: cinsertion_invsib              ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "insertion"
CREATE VIEW cinsertion_invsib AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    insertion1.feature_id AS feature_id1,
    insertion1.dbxref_id AS dbxref_id1,
    insertion1.organism_id AS organism_id1,
    insertion1.name AS name1,
    insertion1.uniquename AS uniquename1,
    insertion1.residues AS residues1,
    insertion1.seqlen AS seqlen1,
    insertion1.md5checksum AS md5checksum1,
    insertion1.type_id AS type_id1,
    insertion1.is_analysis AS is_analysis1,
    insertion1.timeaccessioned AS timeaccessioned1,
    insertion1.timelastmodified AS timelastmodified1,
    insertion2.feature_id AS feature_id2,
    insertion2.dbxref_id AS dbxref_id2,
    insertion2.organism_id AS organism_id2,
    insertion2.name AS name2,
    insertion2.uniquename AS uniquename2,
    insertion2.residues AS residues2,
    insertion2.seqlen AS seqlen2,
    insertion2.md5checksum AS md5checksum2,
    insertion2.type_id AS type_id2,
    insertion2.is_analysis AS is_analysis2,
    insertion2.timeaccessioned AS timeaccessioned2,
    insertion2.timelastmodified AS timelastmodified2
  FROM
    insertion AS insertion1 INNER JOIN
    feature_relationship AS fr1 ON (insertion1.insertion_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    insertion AS insertion2 ON (insertion1.insertion_id = fr2.object_id);


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
--- *** relation: sib_gene                       ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Sibling View   ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "gene"
CREATE VIEW sib_gene AS
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
    gene AS gene2 ON (gene1.gene_id = fr2.subject_id)
;

--- ************************************************
--- *** relation: gene_invsib                    ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "gene"
CREATE VIEW gene_invsib AS
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
--- *** relation: csib_gene                      ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Sibling View   ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "gene"
CREATE VIEW csib_gene AS
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
    gene AS gene2 ON (gene1.gene_id = fr2.subject_id)
  WHERE fr2.rank - fr1.rank = 1
;

--- ************************************************
--- *** relation: cgene_invsib                   ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "gene"
CREATE VIEW cgene_invsib AS
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
--- *** relation: gene_cassette                  ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology 'Typed Feature' View   ***
--- ***                                          ***
--- ************************************************
---
--- SO Term:
--- "gene_cassette"

CREATE VIEW gene_cassette AS
  SELECT
    feature_id AS gene_cassette_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'gene_cassette';

--- ************************************************
--- *** relation: sib_gene_cassette              ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Sibling View   ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "gene_cassette"
CREATE VIEW sib_gene_cassette AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    gene_cassette1.feature_id AS feature_id1,
    gene_cassette1.dbxref_id AS dbxref_id1,
    gene_cassette1.organism_id AS organism_id1,
    gene_cassette1.name AS name1,
    gene_cassette1.uniquename AS uniquename1,
    gene_cassette1.residues AS residues1,
    gene_cassette1.seqlen AS seqlen1,
    gene_cassette1.md5checksum AS md5checksum1,
    gene_cassette1.type_id AS type_id1,
    gene_cassette1.is_analysis AS is_analysis1,
    gene_cassette1.timeaccessioned AS timeaccessioned1,
    gene_cassette1.timelastmodified AS timelastmodified1,
    gene_cassette2.feature_id AS feature_id2,
    gene_cassette2.dbxref_id AS dbxref_id2,
    gene_cassette2.organism_id AS organism_id2,
    gene_cassette2.name AS name2,
    gene_cassette2.uniquename AS uniquename2,
    gene_cassette2.residues AS residues2,
    gene_cassette2.seqlen AS seqlen2,
    gene_cassette2.md5checksum AS md5checksum2,
    gene_cassette2.type_id AS type_id2,
    gene_cassette2.is_analysis AS is_analysis2,
    gene_cassette2.timeaccessioned AS timeaccessioned2,
    gene_cassette2.timelastmodified AS timelastmodified2
  FROM
    gene_cassette AS gene_cassette1 INNER JOIN
    feature_relationship AS fr1 ON (gene_cassette1.gene_cassette_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    gene_cassette AS gene_cassette2 ON (gene_cassette1.gene_cassette_id = fr2.subject_id)
;

--- ************************************************
--- *** relation: gene_cassette_invsib           ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "gene_cassette"
CREATE VIEW gene_cassette_invsib AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    gene_cassette1.feature_id AS feature_id1,
    gene_cassette1.dbxref_id AS dbxref_id1,
    gene_cassette1.organism_id AS organism_id1,
    gene_cassette1.name AS name1,
    gene_cassette1.uniquename AS uniquename1,
    gene_cassette1.residues AS residues1,
    gene_cassette1.seqlen AS seqlen1,
    gene_cassette1.md5checksum AS md5checksum1,
    gene_cassette1.type_id AS type_id1,
    gene_cassette1.is_analysis AS is_analysis1,
    gene_cassette1.timeaccessioned AS timeaccessioned1,
    gene_cassette1.timelastmodified AS timelastmodified1,
    gene_cassette2.feature_id AS feature_id2,
    gene_cassette2.dbxref_id AS dbxref_id2,
    gene_cassette2.organism_id AS organism_id2,
    gene_cassette2.name AS name2,
    gene_cassette2.uniquename AS uniquename2,
    gene_cassette2.residues AS residues2,
    gene_cassette2.seqlen AS seqlen2,
    gene_cassette2.md5checksum AS md5checksum2,
    gene_cassette2.type_id AS type_id2,
    gene_cassette2.is_analysis AS is_analysis2,
    gene_cassette2.timeaccessioned AS timeaccessioned2,
    gene_cassette2.timelastmodified AS timelastmodified2
  FROM
    gene_cassette AS gene_cassette1 INNER JOIN
    feature_relationship AS fr1 ON (gene_cassette1.gene_cassette_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    gene_cassette AS gene_cassette2 ON (gene_cassette1.gene_cassette_id = fr2.object_id);


--- ************************************************
--- *** relation: csib_gene_cassette             ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Sibling View   ***
--- *** features linked by common container      ***
--- ************************************************
---
--- SO Term:
--- "gene_cassette"
CREATE VIEW csib_gene_cassette AS
  SELECT
    fr1.object_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    gene_cassette1.feature_id AS feature_id1,
    gene_cassette1.dbxref_id AS dbxref_id1,
    gene_cassette1.organism_id AS organism_id1,
    gene_cassette1.name AS name1,
    gene_cassette1.uniquename AS uniquename1,
    gene_cassette1.residues AS residues1,
    gene_cassette1.seqlen AS seqlen1,
    gene_cassette1.md5checksum AS md5checksum1,
    gene_cassette1.type_id AS type_id1,
    gene_cassette1.is_analysis AS is_analysis1,
    gene_cassette1.timeaccessioned AS timeaccessioned1,
    gene_cassette1.timelastmodified AS timelastmodified1,
    gene_cassette2.feature_id AS feature_id2,
    gene_cassette2.dbxref_id AS dbxref_id2,
    gene_cassette2.organism_id AS organism_id2,
    gene_cassette2.name AS name2,
    gene_cassette2.uniquename AS uniquename2,
    gene_cassette2.residues AS residues2,
    gene_cassette2.seqlen AS seqlen2,
    gene_cassette2.md5checksum AS md5checksum2,
    gene_cassette2.type_id AS type_id2,
    gene_cassette2.is_analysis AS is_analysis2,
    gene_cassette2.timeaccessioned AS timeaccessioned2,
    gene_cassette2.timelastmodified AS timelastmodified2
  FROM
    gene_cassette AS gene_cassette1 INNER JOIN
    feature_relationship AS fr1 ON (gene_cassette1.gene_cassette_id = fr1.subject_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)
    INNER JOIN
    gene_cassette AS gene_cassette2 ON (gene_cassette1.gene_cassette_id = fr2.subject_id)
  WHERE fr2.rank - fr1.rank = 1
;

--- ************************************************
--- *** relation: cgene_cassette_invsib          ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology Feature Inverse Pair   ***
--- *** features linked by common contained      ***
--- *** child feature                            ***
--- ************************************************
---
--- SO Term:
--- "gene_cassette"
CREATE VIEW cgene_cassette_invsib AS
  SELECT
    fr1.subject_id,
    fr1.rank AS rank1,
    fr2.rank AS rank2,
    fr2.rank - fr1.rank AS rankdiff,
    gene_cassette1.feature_id AS feature_id1,
    gene_cassette1.dbxref_id AS dbxref_id1,
    gene_cassette1.organism_id AS organism_id1,
    gene_cassette1.name AS name1,
    gene_cassette1.uniquename AS uniquename1,
    gene_cassette1.residues AS residues1,
    gene_cassette1.seqlen AS seqlen1,
    gene_cassette1.md5checksum AS md5checksum1,
    gene_cassette1.type_id AS type_id1,
    gene_cassette1.is_analysis AS is_analysis1,
    gene_cassette1.timeaccessioned AS timeaccessioned1,
    gene_cassette1.timelastmodified AS timelastmodified1,
    gene_cassette2.feature_id AS feature_id2,
    gene_cassette2.dbxref_id AS dbxref_id2,
    gene_cassette2.organism_id AS organism_id2,
    gene_cassette2.name AS name2,
    gene_cassette2.uniquename AS uniquename2,
    gene_cassette2.residues AS residues2,
    gene_cassette2.seqlen AS seqlen2,
    gene_cassette2.md5checksum AS md5checksum2,
    gene_cassette2.type_id AS type_id2,
    gene_cassette2.is_analysis AS is_analysis2,
    gene_cassette2.timeaccessioned AS timeaccessioned2,
    gene_cassette2.timelastmodified AS timelastmodified2
  FROM
    gene_cassette AS gene_cassette1 INNER JOIN
    feature_relationship AS fr1 ON (gene_cassette1.gene_cassette_id = fr1.object_id)
    INNER JOIN
    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)
    INNER JOIN
    gene_cassette AS gene_cassette2 ON (gene_cassette1.gene_cassette_id = fr2.object_id);


--- ************************************************
--- *** relation: transposable_element_gene2region***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology PART-OF view           ***
--- ************************************************
---
--- Subject Type: region
--- Object Type:  transposable_element_gene
--- Predicate:    PART-OF

CREATE VIEW transposable_element_gene2region AS
  SELECT
    feature_relationship_id,
    subject_id AS region_id,
    object_id AS transposable_element_gene_id,
    subject_id,
    object_id,
    feature_relationship.type_id
  FROM
    region INNER JOIN feature_relationship ON (region.feature_id = subject_id)
        INNER JOIN transposable_element_gene ON (transposable_element_gene.feature_id = object_id);

--- ************************************************
--- *** relation: rrna2region                    ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology PART-OF view           ***
--- ************************************************
---
--- Subject Type: region
--- Object Type:  rrna
--- Predicate:    PART-OF

CREATE VIEW rrna2region AS
  SELECT
    feature_relationship_id,
    subject_id AS region_id,
    object_id AS rrna_id,
    subject_id,
    object_id,
    feature_relationship.type_id
  FROM
    region INNER JOIN feature_relationship ON (region.feature_id = subject_id)
        INNER JOIN rrna ON (rrna.feature_id = object_id);

--- ************************************************
--- *** relation: pseudogene2region              ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology PART-OF view           ***
--- ************************************************
---
--- Subject Type: region
--- Object Type:  pseudogene
--- Predicate:    PART-OF

CREATE VIEW pseudogene2region AS
  SELECT
    feature_relationship_id,
    subject_id AS region_id,
    object_id AS pseudogene_id,
    subject_id,
    object_id,
    feature_relationship.type_id
  FROM
    region INNER JOIN feature_relationship ON (region.feature_id = subject_id)
        INNER JOIN pseudogene ON (pseudogene.feature_id = object_id);

--- ************************************************
--- *** relation: centromere2region              ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology PART-OF view           ***
--- ************************************************
---
--- Subject Type: region
--- Object Type:  centromere
--- Predicate:    PART-OF

CREATE VIEW centromere2region AS
  SELECT
    feature_relationship_id,
    subject_id AS region_id,
    object_id AS centromere_id,
    subject_id,
    object_id,
    feature_relationship.type_id
  FROM
    region INNER JOIN feature_relationship ON (region.feature_id = subject_id)
        INNER JOIN centromere ON (centromere.feature_id = object_id);

--- ************************************************
--- *** relation: gene2region                    ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology PART-OF view           ***
--- ************************************************
---
--- Subject Type: region
--- Object Type:  gene
--- Predicate:    PART-OF

CREATE VIEW gene2region AS
  SELECT
    feature_relationship_id,
    subject_id AS region_id,
    object_id AS gene_id,
    subject_id,
    object_id,
    feature_relationship.type_id
  FROM
    region INNER JOIN feature_relationship ON (region.feature_id = subject_id)
        INNER JOIN gene ON (gene.feature_id = object_id);

--- ************************************************
--- *** relation: gene_cassette2region           ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology PART-OF view           ***
--- ************************************************
---
--- Subject Type: region
--- Object Type:  gene_cassette
--- Predicate:    PART-OF

CREATE VIEW gene_cassette2region AS
  SELECT
    feature_relationship_id,
    subject_id AS region_id,
    object_id AS gene_cassette_id,
    subject_id,
    object_id,
    feature_relationship.type_id
  FROM
    region INNER JOIN feature_relationship ON (region.feature_id = subject_id)
        INNER JOIN gene_cassette ON (gene_cassette.feature_id = object_id);

--- ************************************************
--- *** relation: rrna2intron                    ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology PART-OF view           ***
--- ************************************************
---
--- Subject Type: intron
--- Object Type:  rrna
--- Predicate:    PART-OF

CREATE VIEW rrna2intron AS
  SELECT
    feature_relationship_id,
    subject_id AS intron_id,
    object_id AS rrna_id,
    subject_id,
    object_id,
    feature_relationship.type_id
  FROM
    intron INNER JOIN feature_relationship ON (intron.feature_id = subject_id)
        INNER JOIN rrna ON (rrna.feature_id = object_id);

--- ************************************************
--- *** relation: trna2intron                    ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology PART-OF view           ***
--- ************************************************
---
--- Subject Type: intron
--- Object Type:  trna
--- Predicate:    PART-OF

CREATE VIEW trna2intron AS
  SELECT
    feature_relationship_id,
    subject_id AS intron_id,
    object_id AS trna_id,
    subject_id,
    object_id,
    feature_relationship.type_id
  FROM
    intron INNER JOIN feature_relationship ON (intron.feature_id = subject_id)
        INNER JOIN trna ON (trna.feature_id = object_id);

--- ************************************************
--- *** relation: snorna2intron                  ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology PART-OF view           ***
--- ************************************************
---
--- Subject Type: intron
--- Object Type:  snorna
--- Predicate:    PART-OF

CREATE VIEW snorna2intron AS
  SELECT
    feature_relationship_id,
    subject_id AS intron_id,
    object_id AS snorna_id,
    subject_id,
    object_id,
    feature_relationship.type_id
  FROM
    intron INNER JOIN feature_relationship ON (intron.feature_id = subject_id)
        INNER JOIN snorna ON (snorna.feature_id = object_id);

--- ************************************************
--- *** relation: gene2intron                    ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology PART-OF view           ***
--- ************************************************
---
--- Subject Type: intron
--- Object Type:  gene
--- Predicate:    PART-OF

CREATE VIEW gene2intron AS
  SELECT
    feature_relationship_id,
    subject_id AS intron_id,
    object_id AS gene_id,
    subject_id,
    object_id,
    feature_relationship.type_id
  FROM
    intron INNER JOIN feature_relationship ON (intron.feature_id = subject_id)
        INNER JOIN gene ON (gene.feature_id = object_id);

--- ************************************************
--- *** relation: rrna2noncoding_exon            ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology PART-OF view           ***
--- ************************************************
---
--- Subject Type: noncoding_exon
--- Object Type:  rrna
--- Predicate:    PART-OF

CREATE VIEW rrna2noncoding_exon AS
  SELECT
    feature_relationship_id,
    subject_id AS noncoding_exon_id,
    object_id AS rrna_id,
    subject_id,
    object_id,
    feature_relationship.type_id
  FROM
    noncoding_exon INNER JOIN feature_relationship ON (noncoding_exon.feature_id = subject_id)
        INNER JOIN rrna ON (rrna.feature_id = object_id);

--- ************************************************
--- *** relation: trna2noncoding_exon            ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology PART-OF view           ***
--- ************************************************
---
--- Subject Type: noncoding_exon
--- Object Type:  trna
--- Predicate:    PART-OF

CREATE VIEW trna2noncoding_exon AS
  SELECT
    feature_relationship_id,
    subject_id AS noncoding_exon_id,
    object_id AS trna_id,
    subject_id,
    object_id,
    feature_relationship.type_id
  FROM
    noncoding_exon INNER JOIN feature_relationship ON (noncoding_exon.feature_id = subject_id)
        INNER JOIN trna ON (trna.feature_id = object_id);

--- ************************************************
--- *** relation: snrna2noncoding_exon           ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology PART-OF view           ***
--- ************************************************
---
--- Subject Type: noncoding_exon
--- Object Type:  snrna
--- Predicate:    PART-OF

CREATE VIEW snrna2noncoding_exon AS
  SELECT
    feature_relationship_id,
    subject_id AS noncoding_exon_id,
    object_id AS snrna_id,
    subject_id,
    object_id,
    feature_relationship.type_id
  FROM
    noncoding_exon INNER JOIN feature_relationship ON (noncoding_exon.feature_id = subject_id)
        INNER JOIN snrna ON (snrna.feature_id = object_id);

--- ************************************************
--- *** relation: snorna2noncoding_exon          ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology PART-OF view           ***
--- ************************************************
---
--- Subject Type: noncoding_exon
--- Object Type:  snorna
--- Predicate:    PART-OF

CREATE VIEW snorna2noncoding_exon AS
  SELECT
    feature_relationship_id,
    subject_id AS noncoding_exon_id,
    object_id AS snorna_id,
    subject_id,
    object_id,
    feature_relationship.type_id
  FROM
    noncoding_exon INNER JOIN feature_relationship ON (noncoding_exon.feature_id = subject_id)
        INNER JOIN snorna ON (snorna.feature_id = object_id);

--- ************************************************
--- *** relation: ncrna2noncoding_exon           ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology PART-OF view           ***
--- ************************************************
---
--- Subject Type: noncoding_exon
--- Object Type:  ncrna
--- Predicate:    PART-OF

CREATE VIEW ncrna2noncoding_exon AS
  SELECT
    feature_relationship_id,
    subject_id AS noncoding_exon_id,
    object_id AS ncrna_id,
    subject_id,
    object_id,
    feature_relationship.type_id
  FROM
    noncoding_exon INNER JOIN feature_relationship ON (noncoding_exon.feature_id = subject_id)
        INNER JOIN ncrna ON (ncrna.feature_id = object_id);

--- ************************************************
--- *** relation: transposable_element_gene2cds  ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology PART-OF view           ***
--- ************************************************
---
--- Subject Type: cds
--- Object Type:  transposable_element_gene
--- Predicate:    PART-OF

CREATE VIEW transposable_element_gene2cds AS
  SELECT
    feature_relationship_id,
    subject_id AS cds_id,
    object_id AS transposable_element_gene_id,
    subject_id,
    object_id,
    feature_relationship.type_id
  FROM
    cds INNER JOIN feature_relationship ON (cds.feature_id = subject_id)
        INNER JOIN transposable_element_gene ON (transposable_element_gene.feature_id = object_id);

--- ************************************************
--- *** relation: pseudogene2cds                 ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology PART-OF view           ***
--- ************************************************
---
--- Subject Type: cds
--- Object Type:  pseudogene
--- Predicate:    PART-OF

CREATE VIEW pseudogene2cds AS
  SELECT
    feature_relationship_id,
    subject_id AS cds_id,
    object_id AS pseudogene_id,
    subject_id,
    object_id,
    feature_relationship.type_id
  FROM
    cds INNER JOIN feature_relationship ON (cds.feature_id = subject_id)
        INNER JOIN pseudogene ON (pseudogene.feature_id = object_id);

--- ************************************************
--- *** relation: gene2cds                       ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology PART-OF view           ***
--- ************************************************
---
--- Subject Type: cds
--- Object Type:  gene
--- Predicate:    PART-OF

CREATE VIEW gene2cds AS
  SELECT
    feature_relationship_id,
    subject_id AS cds_id,
    object_id AS gene_id,
    subject_id,
    object_id,
    feature_relationship.type_id
  FROM
    cds INNER JOIN feature_relationship ON (cds.feature_id = subject_id)
        INNER JOIN gene ON (gene.feature_id = object_id);

--- ************************************************
--- *** relation: ars2nucleotide_match           ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology PART-OF view           ***
--- ************************************************
---
--- Subject Type: nucleotide_match
--- Object Type:  ars
--- Predicate:    PART-OF

CREATE VIEW ars2nucleotide_match AS
  SELECT
    feature_relationship_id,
    subject_id AS nucleotide_match_id,
    object_id AS ars_id,
    subject_id,
    object_id,
    feature_relationship.type_id
  FROM
    nucleotide_match INNER JOIN feature_relationship ON (nucleotide_match.feature_id = subject_id)
        INNER JOIN ars ON (ars.feature_id = object_id);

--- ************************************************
--- *** relation: repeat_region2nucleotide_match ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology PART-OF view           ***
--- ************************************************
---
--- Subject Type: nucleotide_match
--- Object Type:  repeat_region
--- Predicate:    PART-OF

CREATE VIEW repeat_region2nucleotide_match AS
  SELECT
    feature_relationship_id,
    subject_id AS nucleotide_match_id,
    object_id AS repeat_region_id,
    subject_id,
    object_id,
    feature_relationship.type_id
  FROM
    nucleotide_match INNER JOIN feature_relationship ON (nucleotide_match.feature_id = subject_id)
        INNER JOIN repeat_region ON (repeat_region.feature_id = object_id);

--- ************************************************
--- *** relation: repeat_region2binding_site     ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology PART-OF view           ***
--- ************************************************
---
--- Subject Type: binding_site
--- Object Type:  repeat_region
--- Predicate:    PART-OF

CREATE VIEW repeat_region2binding_site AS
  SELECT
    feature_relationship_id,
    subject_id AS binding_site_id,
    object_id AS repeat_region_id,
    subject_id,
    object_id,
    feature_relationship.type_id
  FROM
    binding_site INNER JOIN feature_relationship ON (binding_site.feature_id = subject_id)
        INNER JOIN repeat_region ON (repeat_region.feature_id = object_id);

--- ************************************************
--- *** relation: gene2five_prime_utr_intron     ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology PART-OF view           ***
--- ************************************************
---
--- Subject Type: five_prime_utr_intron
--- Object Type:  gene
--- Predicate:    PART-OF

CREATE VIEW gene2five_prime_utr_intron AS
  SELECT
    feature_relationship_id,
    subject_id AS five_prime_utr_intron_id,
    object_id AS gene_id,
    subject_id,
    object_id,
    feature_relationship.type_id
  FROM
    five_prime_utr_intron INNER JOIN feature_relationship ON (five_prime_utr_intron.feature_id = subject_id)
        INNER JOIN gene ON (gene.feature_id = object_id);

--- ************************************************
--- *** relation: rrna2i_transcribed_spacer_region***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology PART-OF view           ***
--- ************************************************
---
--- Subject Type: i_transcribed_spacer_region
--- Object Type:  rrna
--- Predicate:    PART-OF

CREATE VIEW rrna2i_transcribed_spacer_region AS
  SELECT
    feature_relationship_id,
    subject_id AS i_transcribed_spacer_region_id,
    object_id AS rrna_id,
    subject_id,
    object_id,
    feature_relationship.type_id
  FROM
    i_transcribed_spacer_region INNER JOIN feature_relationship ON (i_transcribed_spacer_region.feature_id = subject_id)
        INNER JOIN rrna ON (rrna.feature_id = object_id);

--- ************************************************
--- *** relation: rrna2e_transcribed_spacer_region***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology PART-OF view           ***
--- ************************************************
---
--- Subject Type: e_transcribed_spacer_region
--- Object Type:  rrna
--- Predicate:    PART-OF

CREATE VIEW rrna2e_transcribed_spacer_region AS
  SELECT
    feature_relationship_id,
    subject_id AS e_transcribed_spacer_region_id,
    object_id AS rrna_id,
    subject_id,
    object_id,
    feature_relationship.type_id
  FROM
    e_transcribed_spacer_region INNER JOIN feature_relationship ON (e_transcribed_spacer_region.feature_id = subject_id)
        INNER JOIN rrna ON (rrna.feature_id = object_id);

--- ************************************************
--- *** relation: repeat_region2repeat_region    ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology PART-OF view           ***
--- ************************************************
---
--- Subject Type: repeat_region
--- Object Type:  repeat_region
--- Predicate:    PART-OF

CREATE VIEW repeat_region2repeat_region AS
  SELECT
    feature_relationship_id,
    subject_id AS repeat_region_id,
    object_id AS repeat_region_id,
    subject_id,
    object_id,
    feature_relationship.type_id
  FROM
    repeat_region INNER JOIN feature_relationship ON (repeat_region.feature_id = subject_id)
        INNER JOIN repeat_region ON (repeat_region.feature_id = object_id);

--- ************************************************
--- *** relation: repeat_region2insertion        ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence Ontology PART-OF view           ***
--- ************************************************
---
--- Subject Type: insertion
--- Object Type:  repeat_region
--- Predicate:    PART-OF

CREATE VIEW repeat_region2insertion AS
  SELECT
    feature_relationship_id,
    subject_id AS insertion_id,
    object_id AS repeat_region_id,
    subject_id,
    object_id,
    feature_relationship.type_id
  FROM
    insertion INNER JOIN feature_relationship ON (insertion.feature_id = subject_id)
        INNER JOIN repeat_region ON (repeat_region.feature_id = object_id);



SET search_path = public,pg_catalog;
