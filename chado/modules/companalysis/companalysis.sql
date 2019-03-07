-- $Id: companalysis.sql,v 1.37 2007-03-23 15:18:02 scottcain Exp $
-- ==========================================
-- Chado companalysis module
--
-- =================================================================
-- Dependencies:
--
-- :import feature from sequence
-- :import cvterm from cv
-- :import dbxref from db
-- :import pub from pub
-- =================================================================

-- ================================================
-- TABLE: analysis
-- ================================================

create table analysis (
    analysis_id bigserial not null,
    primary key (analysis_id),
    name varchar(255),
    description text,
    program varchar(255) not null,
    programversion varchar(255) not null,
    algorithm varchar(255),
    sourcename varchar(255),
    sourceversion varchar(255),
    sourceuri text,
    timeexecuted timestamp not null default current_timestamp,
    type_id bigint,
    foreign key (type_id) references cvterm (cvterm_id),
    constraint analysis_c1 unique (program,programversion,sourcename)
);
COMMENT ON TABLE analysis IS 'An analysis is a particular type of a
    computational analysis; it may be a blast of one sequence against
    another, or an all by all blast, or a different kind of analysis
    altogether. It is a single unit of computation.';
COMMENT ON COLUMN analysis.name IS 'A way of grouping analyses. This
    should be a handy short identifier that can help people find an
    analysis they want. For instance "tRNAscan", "cDNA", "FlyPep",
    "SwissProt", and it should not be assumed to be unique. For instance, there may be lots of separate analyses done against a cDNA database.';
COMMENT ON COLUMN analysis.program IS 'Program name, e.g. blastx, blastp, sim4, genscan.';
COMMENT ON COLUMN analysis.programversion IS 'Version description, e.g. TBLASTX 2.0MP-WashU [09-Nov-2000].';
COMMENT ON COLUMN analysis.algorithm IS 'Algorithm name, e.g. blast.';
COMMENT ON COLUMN analysis.sourcename IS 'Source name, e.g. cDNA, SwissProt.';
COMMENT ON COLUMN analysis.sourceuri IS 'This is an optional, permanent URL or URI for the source of the  analysis. The idea is that someone could recreate the analysis directly by going to this URI and fetching the source data (e.g. the blast database, or the training model).';
COMMENT ON COLUMN analysis.type_id IS 'An optional cvterm_id that specifies what type of analysis this record is.  Prior to 1.4, analysis type was set with an analysisprop.';

-- ================================================
-- TABLE: analysisprop
-- ================================================

create table analysisprop (
    analysisprop_id bigserial not null,
    primary key (analysisprop_id),
    analysis_id bigint not null,
    foreign key (analysis_id) references analysis (analysis_id) on delete cascade INITIALLY DEFERRED,
    type_id bigint not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    value text,
    rank int not null default 0,
    cvalue_id bigint,
    FOREIGN KEY (cvalue_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL,
    constraint analysisprop_c1 unique (analysis_id,type_id,rank)
);
create index analysisprop_idx1 on analysisprop (analysis_id);
create index analysisprop_idx2 on analysisprop (type_id);
CREATE index analysisprop_idx3 ON analysisprop (cvalue_id);

COMMENT ON COLUMN analysisprop.cvalue_id IS 'The value of the property if that value should be the name of a controlled vocabulary term.  It is preferred that a property either use the value or cvalue_id column but not both.  For example, if the property type is "color" then the cvalue_id could be a term named "green".';


-- ================================================
-- TABLE: analysisfeature
-- ================================================

create table analysisfeature (
    analysisfeature_id bigserial not null,
    primary key (analysisfeature_id),
    feature_id bigint not null,
    foreign key (feature_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,
    analysis_id bigint not null,
    foreign key (analysis_id) references analysis (analysis_id) on delete cascade INITIALLY DEFERRED,
    rawscore double precision,
    normscore double precision,
    significance double precision,
    identity double precision,
    constraint analysisfeature_c1 unique (feature_id,analysis_id)
);
create index analysisfeature_idx1 on analysisfeature (feature_id);
create index analysisfeature_idx2 on analysisfeature (analysis_id);

COMMENT ON TABLE analysisfeature IS 'Computational analyses generate features (e.g. Genscan generates transcripts and exons; sim4 alignments generate similarity/match features). analysisfeatures are stored using the feature table from the sequence module. The analysisfeature table is used to decorate these features, with analysis specific attributes. A feature is an analysisfeature if and only if there is a corresponding entry in the analysisfeature table. analysisfeatures will have two or more featureloc entries,
 with rank indicating query/subject';
COMMENT ON COLUMN analysisfeature.identity IS 'Percent identity between the locations compared.  Note that these 4 metrics do not cover the full range of scores possible; it would be undesirable to list every score possible, as this should be kept extensible. instead, for non-standard scores, use the analysisprop table.';
COMMENT ON COLUMN analysisfeature.significance IS 'This is some kind of expectation or probability metric, representing the probability that the analysis would appear randomly given the model. As such, any program or person querying this table can assume the following semantics:
   * 0 <= significance <= n, where n is a positive number, theoretically unbounded but unlikely to be more than 10
  * low numbers are better than high numbers.';
COMMENT ON COLUMN analysisfeature.normscore IS 'This is the rawscore but
    semi-normalized. Complete normalization to allow comparison of
    features generated by different programs would be nice but too
    difficult. Instead the normalization should strive to enforce the
    following semantics: * normscores are floating point numbers >= 0,
    * high normscores are better than low one. For most programs, it would be sufficient to make the normscore the same as this rawscore, providing these semantics are satisfied.';
COMMENT ON COLUMN analysisfeature.rawscore IS 'This is the native score generated by the program; for example, the bitscore generated by blast, sim4 or genscan scores. One should not assume that high is necessarily better than low.';

-- ================================================
-- TABLE: analysisfeatureprop
-- ================================================

CREATE TABLE analysisfeatureprop (
    analysisfeatureprop_id bigserial PRIMARY KEY,
    analysisfeature_id bigint NOT NULL REFERENCES analysisfeature(analysisfeature_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
    type_id bigint NOT NULL REFERENCES cvterm(cvterm_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
    value TEXT,
    rank int NOT NULL,
    cvalue_id bigint,
    FOREIGN KEY (cvalue_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL,
    CONSTRAINT analysisfeature_id_type_id_rank UNIQUE(analysisfeature_id, type_id, rank)
);
create index analysisfeatureprop_idx1 on analysisfeatureprop (analysisfeature_id);
create index analysisfeatureprop_idx2 on analysisfeatureprop (type_id);
create index analysisfeatureprop_idx3 on analysisfeatureprop (cvalue_id);

COMMENT ON COLUMN analysisfeatureprop.cvalue_id IS 'The value of the property if that value should be the name of a controlled vocabulary term.  It is preferred that a property either use the value or cvalue_id column but not both.  For example, if the property type is "color" then the cvalue_id could be a term named "green".';


-- ================================================
-- TABLE: analysis_dbxref
-- ================================================

create table analysis_dbxref (
  analysis_dbxref_id bigserial not null,
  analysis_id bigint not null,
  dbxref_id bigint not null,
  primary key (analysis_dbxref_id),
  is_current boolean not null default 'true',
  foreign key (analysis_id) references analysis (analysis_id) on delete cascade INITIALLY DEFERRED,
  foreign key (dbxref_id) references dbxref (dbxref_id) on delete cascade INITIALLY DEFERRED,
  constraint analysis_dbxref_c1 unique (analysis_id,dbxref_id)
);
create index analysis_dbxref_idx1 on analysis_dbxref (analysis_id);
create index analysis_dbxref_idx2 on analysis_dbxref (dbxref_id);

COMMENT ON TABLE analysis_dbxref IS 'Links an analysis to dbxrefs.';

COMMENT ON COLUMN analysis_dbxref.is_current IS 'True if this dbxref 
is the most up to date accession in the corresponding db. Retired 
accessions should set this field to false';


-- ================================================
-- TABLE: analysis_cvterm
-- ================================================

create table analysis_cvterm (
  analysis_cvterm_id bigserial not null,
  analysis_id bigint not null,
  cvterm_id bigint not null,
  is_not boolean not null default false,
  rank integer not null default 0,
  primary key (analysis_cvterm_id),
  foreign key (analysis_id) references analysis (analysis_id) on delete cascade INITIALLY DEFERRED,
  foreign key (cvterm_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
  constraint analysis_cvterm_c1 unique (analysis_id,cvterm_id,rank)
);
create index analysis_cvterm_idx1 on analysis_cvterm (analysis_id);
create index analysis_cvterm_idx2 on analysis_cvterm (cvterm_id);

COMMENT ON TABLE analysis_cvterm IS 'Associate a term from a cv with an analysis.';

COMMENT ON COLUMN analysis_cvterm.is_not IS 'If this is set to true, then this 
annotation is interpreted as a NEGATIVE annotation - i.e. the analysis does 
NOT have the specified term.';

-- ================================================
-- TABLE: analysis_relationship
-- ================================================

create table analysis_relationship (
  analysis_relationship_id bigserial not null,
  subject_id bigint not null,
  object_id bigint not null,
  type_id bigint not null,
  value text null,
  rank int not null default 0,
  primary key (analysis_relationship_id),
  foreign key (subject_id) references analysis (analysis_id) on delete cascade INITIALLY DEFERRED,
  foreign key (object_id) references analysis (analysis_id) on delete cascade INITIALLY DEFERRED,
  foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
  constraint analysis_relationship_c1 unique (subject_id,object_id,type_id,rank)
);
create index analysis_relationship_idx1 on analysis_relationship (subject_id);
create index analysis_relationship_idx2 on analysis_relationship (object_id);
create index analysis_relationship_idx3 on analysis_relationship (type_id);

COMMENT ON COLUMN analysis_relationship.subject_id IS 'analysis_relationship.subject_id i
s the subject of the subj-predicate-obj sentence.';

COMMENT ON COLUMN analysis_relationship.object_id IS 'analysis_relationship.object_id 
is the object of the subj-predicate-obj sentence.';

COMMENT ON COLUMN analysis_relationship.type_id IS 'analysis_relationship.type_id 
is relationship type between subject and object. This is a cvterm, typically 
from the OBO relationship ontology, although other relationship types are allowed.';

COMMENT ON COLUMN analysis_relationship.rank IS 'analysis_relationship.rank is 
the ordering of subject analysiss with respect to the object analysis may be 
important where rank is used to order these; starts from zero.';

COMMENT ON COLUMN analysis_relationship.value IS 'analysis_relationship.value 
is for additional notes or comments.';

-- ================================================
-- TABLE: analysis_pub
-- ================================================

create table analysis_pub (
    analysis_pub_id bigserial not null,
    primary key (analysis_pub_id),
    analysis_id bigint not null,
    foreign key (analysis_id) references analysis (analysis_id) on delete cascade INITIALLY DEFERRED,
    pub_id bigint not null,
    foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
    constraint analysis_pub_c1 unique (analysis_id, pub_id)
);
create index analysis_pub_idx1 on analysis_pub (analysis_id);
create index analysis_pub_idx2 on analysis_pub (pub_id);

COMMENT ON TABLE analysis_pub IS 'Provenance. Linking table between analyses and the publications that mention them.';
