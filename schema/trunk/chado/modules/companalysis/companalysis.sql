-- ================================================
-- TABLE: analysis
-- ================================================

-- an analysis is a particular type of a computational analysis;
-- it may be a blast of one sequence against another, or an all by all
-- blast, or a different kind of analysis altogether.
-- it is a single unit of computation 
--
-- name: 
--   a way of grouping analyses. this should be a handy
--   short identifier that can help people find an analysis they
--   want. for instance "tRNAscan", "cDNA", "FlyPep", "SwissProt"
--   it should not be assumed to be unique. for instance, there may
--   be lots of seperate analyses done against a cDNA database.
--
-- program: 
--   e.g. blastx, blastp, sim4, genscan
--
-- programversion:
--   e.g. TBLASTX 2.0MP-WashU [09-Nov-2000]
--
-- algorithm:
--   e.g. blast
--
-- sourcename: 
--   e.g. cDNA, SwissProt
--
-- queryfeature_id:
--   the sequence that was used as the query sequence can be
--   optionally included via queryfeature_id - even though this
--   is redundant with the tables below. this can still
--   be useful - for instance, we may have an analysis that blasts
--   contigs against a database. we may then transform those hits
--   into global coordinates; it may be useful to keep a record
--   of which contig was blasted as the query.
--
--
-- MAPPING (bioperl): maps to Bio::Search::Result::ResultI
-- ** not anymore, b/c we are using analysis in a more general sense
-- ** to represent microarray analysis

--
-- sourceuri: 
--   This is an optional permanent URL/URI for the source of the
--   analysis. The idea is that someone could recreate the analysis
--   directly by going to this URI and fetching the source data
--   (eg the blast database, or the training model).

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

    unique(program, programversion, sourcename)
);

-- ================================================
-- TABLE: analysisinvocation
-- ================================================

-- an analysisinvocation is an instance (ie a run) or an analysis.
-- parameters for the analysis are stored as key/value pairs in
-- analysisprop.  if different blast runs were instantiated over
-- different query sequences, there would be multiple entries here.
--
-- an analysis has inputs and outputs.  data from elsewhere in the
-- database is fed into an analysis (referenced by the composite FK
-- inputtableinfo_id/inputrow_id), and is the output is stored
-- elsewhere in the database (referenced by the composite FK
-- ouputtableinfo_id/outputrow_id).
-- 
-- composite FKs are necessary because analyses can be done on
-- multiple types of data coming from fundamentally different tables
-- (array normalization and feature alignment, for example)

-- input* fields store data about what data from elsewhere in the
-- database (data referenced by *tableinfo_id/*inputrow_id composite FK) was used in a particular
-- analysis invocation.

create table analysisinvocation (
    analysisinvocation_id serial not null,
    primary key (analysisinvocation_id),
    analysis_id int not null,
    foreign key (analysis_id) references analysis (analysis_id),
    description text,

    inputtableinfo_id int not null,
    foreign key (inputtableinfo_id) references tableinfo (tableinfo_id),
    inputrow_id int not null,

    outputtableinfo_id int not null,
    foreign key (outputtableinfo_id) references tableinfo (tableinfo_id),
    outputrow_id int not null
);


-- ================================================
-- TABLE: analysisinvocationprop
-- ================================================

-- analysis invocations can have various properties attached - eg the
-- parameters used in running a blast

create table analysisinvocationprop (
    analysisinvocationprop_id serial not null,
    primary key (analysisinvocationprop_id),
    analysisinvocation_id int not null,
    foreign key (analysisinvocation_id) references analysisinvocation (analysisinvocation_id),
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id),
    value text,

    unique(analysisinvocation_id, type_id, value)
);
create index analysisinvocationprop_idx1 on analysisinvocationprop (analysisinvocation_id);
create index analysisinvocationprop_idx2 on analysisinvocationprop (type_id);

-- ** not sure this table is still necessary with the introduction
-- ** of analysis input/output fields
-- ================================================
-- TABLE: analysisfeature
-- ================================================

-- computational analyses generate features (eg genscan generates
-- transcripts and exons; sim4 alignments generate similarity/match
-- features)

-- analysisfeatures are stored using the feature table from
-- the sequence module. the analysisfeature table is used to
-- decorate these features, with analysis specific attributes.
--
-- a feature is an analysisfeature if and only if there is
-- a corresponding entry in the analysisfeature table
--
-- analysisfeatures will have two or more featureloc entries,
-- with rank indicating query/subject

--  analysis_id:
--    scoredsets are grouped into analyses
--
--  rawscore:
--    this is the native score generated by the program; for example,
--    the bitscore generated by blast, sim4 or genscan scores.
--    one should not assume that high is necessarily better than low.
--
--  normscore:
--    this is the rawscore but semi-normalized. complete normalization
--    to allow comparison of features generated by different programs
--    would be nice but too difficult. instead the normalization should
--    strive to enforce the following semantics:
--
--    * normscores are floating point numbers >= 0
--    * high normscores are better than low one.
--
--    for most programs, it would be sufficient to make the normscore
--    the same as this rawscore, providing these semantics are
--    satisfied.
--
--  significance:
--    this is some kind of expectation or probability metric,
--    representing the probability that the scoredset would appear
--    randomly given the model.
--    as such, any program or person querying this table can assume
--    the following semantics:
--     * 0 <= significance <= n, where n is a positive number, theoretically
--       unbounded but unlikely to be more than 10
--     * low numbers are better than high numbers.
--
--  identity:
--    percent identity between the locations compared
--
--  note that these 4 metrics do not cover the full range of scores
--  possible; it would be undesirable to list every score possible, as
--  this should be kept extensible. instead, for non-standard scores, use
--  the scoredsetprop table.

create table analysisfeature (
    analysisfeature_id serial not null,
    primary key (analysisfeature_id),
    feature_id int not null,
    foreign key (feature_id) references feature (feature_id),
    analysis_id int not null,
    foreign key (analysis_id) references analysis (analysis_id),
    rawscore double precision,
    normscore double precision,
    significance double precision,
    identity double precision,

    unique (feature_id,analysis_id)
);
create index analysisfeature_idx1 on analysisfeature (feature_id);
create index analysisfeature_idx2 on analysisfeature (analysis_id);
