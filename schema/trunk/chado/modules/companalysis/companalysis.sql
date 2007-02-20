-- $Id: companalysis.sql,v 1.33 2007-02-20 18:19:32 briano Exp $
-- ==========================================
-- Chado companalysis module
--
-- =================================================================
-- Dependencies:
--
-- :import feature from sequence
-- :import cvterm from cv
-- =================================================================

-- ================================================
-- TABLE: analysis
-- ================================================

create table analysis (
    analysis_id serial not null,
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
    constraint analysis_c1 unique (program,programversion,sourcename)
);
COMMENT ON TABLE ANALYSIS IS 'An analysis is a particular type of a
    computational analysis; it may be a blast of one sequence against
    another, or an all by all blast, or a different kind of analysis
    altogether. It is a single unit of computation.';
COMMENT ON COLUMN ANALYSIS.NAME IS 'A way of grouping analyses. This
    should be a handy short identifier that can help people find an
    analysis they want. For instance "tRNAscan", "cDNA", "FlyPep",
    "SwissProt", and it should not be assumed to be unique. For instance, there may be lots of separate analyses done against a cDNA database.';
COMMENT ON COLUMN ANALYSIS.PROGRAM IS 'Program name, e.g. blastx, blastp, sim4, genscan.';
COMMENT ON COLUMN ANALYSIS.PROGRAMVERSION IS 'Version description, e.g. TBLASTX 2.0MP-WashU [09-Nov-2000].';
COMMENT ON COLUMN ANALYSIS.ALGORITHM IS 'Algorithm name, e.g. blast.';
COMMENT ON COLUMN ANALYSIS.SOURCENAME IS 'Source name, e.g. cDNA, SwissProt.';
COMMENT ON COLUMN ANALYSIS.SOURCEURI 'This is an optional permanent
    URL/URI for the source of the  analysis. The idea is that someone
    could recreate the analysis directly by going to this URI and fetching the source data (e.g. the blast database, or the training model).';

-- ================================================
-- TABLE: analysisprop
-- ================================================

create table analysisprop (
    analysisprop_id serial not null,
    primary key (analysisprop_id),
    analysis_id int not null,
    foreign key (analysis_id) references analysis (analysis_id) on delete cascade INITIALLY DEFERRED,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    value text,
    constraint analysisprop_c1 unique (analysis_id,type_id,value)
);
create index analysisprop_idx1 on analysisprop (analysis_id);
create index analysisprop_idx2 on analysisprop (type_id);

-- ================================================
-- TABLE: analysisfeature
-- ================================================

create table analysisfeature (
    analysisfeature_id serial not null,
    primary key (analysisfeature_id),
    feature_id int not null,
    foreign key (feature_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,
    analysis_id int not null,
    foreign key (analysis_id) references analysis (analysis_id) on delete cascade INITIALLY DEFERRED,
    rawscore double precision,
    normscore double precision,
    significance double precision,
    identity double precision,
    constraint analysisfeature_c1 unique (feature_id,analysis_id)
);
create index analysisfeature_idx1 on analysisfeature (feature_id);
create index analysisfeature_idx2 on analysisfeature (analysis_id);

COMMENT ON TABLE ANALYSISFEATURE IS 'Computational analyses generate features (e.g. Genscan generates transcripts and exons; sim4 alignments generate similarity/match features). analysisfeatures are stored using the feature table from the sequence module. The analysisfeature table is used to decorate these features, with analysis specific attributes. A feature is an analysisfeature if and only if there is a corresponding entry in the analysisfeature table. analysisfeatures will have two or more featureloc entries,
 with rank indicating query/subject';
COMMENT ON COLUMN ANALYSISFEATURE.IDENTITY IS 'Percent identity between the locations compared.  Note that these 4 metrics do not cover the full range of scores possible; it would be undesirable to list every score possible, as this should be kept extensible. instead, for non-standard scores, use the analysisprop table.';
COMMENT ON COLUMN ANALYSISFEATURE.SIGNIFICANCE IS 'This is some kind of expectation or probability metric, representing the probability that the analysis would appear randomly given the model. As such, any program or person querying this table can assume the following semantics:
   * 0 <= significance <= n, where n is a positive number, theoretically unbounded but unlikely to be more than 10
  * low numbers are better than high numbers.';
COMMENT ON COLUMN ANALYSISFEATURE.NORMSCORE IS 'This is the rawscore but
    semi-normalized. Complete normalization to allow comparison of
    features generated by different programs would be nice but too
    difficult. Instead the normalization should strive to enforce the
    following semantics: * normscores are floating point numbers >= 0,
    * high normscores are better than low one. For most programs, it would be sufficient to make the normscore the same as this rawscore, providing these semantics are satisfied.';
COMMNENT ON COLUMN ANALYSISFEATURE.RAWSCORE IS 'This is the native score generated by the program; for example, the bitscore generated by blast, sim4 or genscan scores. One should not assume that high is necessarily better than low.';
