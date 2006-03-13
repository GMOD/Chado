-- ==========================================
-- Chado genetics module
--
-- redesigned 2003-10-28
--
-- changes 2003-11-10:
--   incorporating suggestions to make everything a gcontext; use 
--   gcontext_relationship to make some gcontexts derivable from others. we 
--   would incorporate environment this way - just add the environment 
--   descriptors as properties of the child gcontext
--
-- changes 2004-06 (Documented by DE: 10-MAR-2005):
--   Many, including rename of gcontext to genotype,  split 
--   phenstatement into phenstatement & phenotype, created environment
--
-- for modeling simple or complex genetic screens
--
-- most genetic statements are about "alleles", although
-- sometimes the definition of allele is stretched
-- (RNAi, engineered construct). genetic statements can
-- also be about large aberrations that take out
-- multiple genes (in FlyBase the policy here is to create
-- alleles for genes within the end-points only, and to
-- attach phenotypic data and so forth to the aberration)
--
-- in chado, a mutant allele is just another feature of type "gene";
-- it is just another form of the canonical wild-type gene feature.
--
-- it is related via an "allele-of" feature_relationship; eg
-- [id:FBgn001, type:gene] <-- [id:FBal001, type:gene]
--
-- with the genetic module, features can either be attached
-- to features of type sequence_variation, or to features of
-- type 'gene' (in the case of mutant alleles).
--
-- if a sequence_variation is large (eg a deficiency) and
-- knocks out multiple genes, then we want to attach the
-- phenotype directly to the sequence variation.
--
-- if the mutation is simple, and affects a single wild-type
-- gene feature, then we would create the mutant allele
-- (another gene feature) and attach the phenotypic data via
-- that feature
--
-- this allows us the option of doing a full structural
-- annotation of the mutant allele gene feature in the future
--
-- we don't necessarily know the molecular details of the
-- the sequence variation (but if we later discover them,
-- we can simply add a featureloc to the sequence_variation
--
-- we can also have sequence variations (of type haplotype_block)
-- that are collections of smaller variations (i.e. via
-- "part_of" feature_relationships) - we could attach phenotypic
-- stuff via this haplotype_block feature or to the alleles it
-- causes
--
-- if we have a mutation affecting the shared region of a nested
-- gene, and we did not know which of the two mutant gene forms were
-- responsible for the resulting phenotype, we would attach the
-- phenotype directly to sequence_variation feature; if we knew
-- which of the two mutant forms of the gene were responsible for
-- the phenotype, we would attach it to them
--
-- we leave open the opportunity for attaching phenotypes via
-- mutant forms of transcripts/proteins/promoters
--
-- we can represent the relationship between a variation and
-- the mutant gene features via a "causes" feature_relationship
--
-- LINKING ALLELES AND VARIATIONS TO PHENOTYPES
--
-- we link via a "genetic context" table - this is essentially
-- the genotype
--
-- most genetic statements take the form
--
-- "allele x[1] shows phenotype P"
--
-- which we represent as "the genetic context defined by x[1] shows P"
--
-- we also allow
--
-- "allele x[1] shows phenotypes P, Q against a background of sev[3]"
--
-- but we actually represent it as
-- "x[1], sev[3] shows phenotypes P, Q"
--
-- x[1] sev[3] is the geneticcontext - genetic contexts can also
-- include things not part of a genotype - e.g. RNAi introduced into cell
--
-- representing environment:
--
-- "allele x[1] shows phenotype P against a background of sev[TS1] at 38 degrees"
-- "allele x[1] shows NO phenotype P against a background of sev[TS1] at 36 degrees"
--
-- we specify this with an environmental context
--
-- we use the phendesc relation to represent the actual organismal 
-- context under observation
--
-- for the description of the phenotype, we are using the standard
-- Observable/Attribute/Value model from the Phenotype Ontology
--
-- we also allow genetic interactions:
--
-- "dx[24] suppresses the wing vein phenotype of H[2]"
--
-- but we actually represent this as:
--
-- "H[2] -> wing vein phenotype P1"
-- "dx[24] -> wing vein phenotype P2"
-- "P2 < P1"
--
-- from this we can do the necessary inference
--
-- complementation:
--
-- "x[1] complements x[2]"
--
-- is actually
--
-- "x[1] -> P1"
-- "x[2] -> P2"
-- "x[2],x[2] -> P3"
-- P3 < P1, P3 < P2
--
-- complementation can be qualified, (eg due to transvection/transsplicing)
--
-- RNAi can be handled - in this case the "allele" is a RNA construct (another
-- feature type) introduced to the cell (but not the genome??) which has an
-- observable phenotypic effect
--
-- "foo[RNAi.1] shows phenotype P"
--
-- mis-expression screens (eg GAL4/UAS) are handled - here the
-- "alleles" are either the construct features, or the insertion features
-- holding the construct (we may need SO type "gal4_insertion" etc);
-- we actually need two alleles in these cases - for both GAL4 and UAS
-- we then record statements such as:
--
-- "Ras85D[V12.S35], gal4[dpp.blk1]  shows phenotype P"
--
-- we use feature_relationships to represent the relationship between
-- the construct and the original non-Scer gene
--
-- we can also record experiments made with other engineered constructs:
-- for example, rescue constructs made from transcripts with an without
-- introns, and recording the difference in phenotype
--
-- the design here is heavily indebted to Rachel Drysdale's paper
-- "Genetic Data in FlyBase"
--
-- ALLELE CLASS
--
-- alleles are amorphs, hypomorphs, etc
--
-- since alleles are features of type gene, we can just use feature_cvterm
-- for this
--
-- SHOULD WE ALSO MAKE THIS CONTEXTUAL TO PHENOTYPE??
--
-- OPEN QUESTION: homologous recombination events
--
-- STOCKS
--
-- this should be in a sub-module of this one; basically we want some
-- kind of linking table between stock and genotype
--
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ============
-- DEPENDENCIES
-- ============
-- :import feature from sequence
-- :import cvterm from cv
-- :import pub from pub
-- :import dbxref from general
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


-- ================================================
-- TABLE: genotype
-- ================================================
-- genetic context
-- the uniquename should be derived from the features
-- making up the genoptype
--
-- uniquename: a human-readable unique identifier
--
create table genotype (
    genotype_id serial not null,
    primary key (genotype_id),
    uniquename text not null,      
    description varchar(255),
    constraint genotype_c1 unique (uniquename)
);
create index genotype_idx1 on genotype(uniquename);

COMMENT ON TABLE genotype IS NULL;


-- ===============================================
-- TABLE: feature_genotype
-- ================================================
-- A genotype is defined by a collection of features
-- mutations, balancers, deficiencies, haplotype blocks, engineered
-- constructs
-- 
-- rank can be used for n-ploid organisms
-- 
-- group can be used for distinguishing the chromosomal groups
-- 
-- (RNAi products and so on can be treated as different groups, as
-- they do not fall on a particular chromosome)
-- 
-- OPEN QUESTION: for multicopy transgenes, should we include a 'n_copies'
-- column as well?
-- 
-- chromosome_id       : a feature of SO type 'chromosome'
-- rank                : preserves order
-- group               : spatially distinguishable group
--
create table feature_genotype (
    feature_genotype_id serial not null,
    primary key (feature_genotype_id),
    feature_id int not null,
    foreign key (feature_id) references feature (feature_id) on delete cascade,
    genotype_id int not null,
    foreign key (genotype_id) references genotype (genotype_id) on delete cascade,
    chromosome_id int,
    foreign key (chromosome_id) references feature (feature_id) on delete set null,
    rank int not null,
    cgroup     int not null,
    cvterm_id int not null,
    foreign key (cvterm_id) references cvterm (cvterm_id) on delete cascade,
    constraint feature_genotype_c1 unique (feature_id, genotype_id, cvterm_id, chromosome_id, rank, cgroup)
);
create index feature_genotype_idx1 on feature_genotype (feature_id);
create index feature_genotype_idx2 on feature_genotype (genotype_id);

COMMENT ON TABLE feature_genotype IS NULL;



-- ================================================
-- TABLE: environment
-- ================================================
-- The environmental component of a phenotype description
create table environment (
    environment_id serial not NULL,
    primary key  (environment_id),
    uniquename text not null,
    description text,
    constraint environment_c1 unique (uniquename)
);
create index environment_idx1 on environment(uniquename);

COMMENT ON TABLE environment IS NULL;


-- ================================================
-- TABLE: environment_cvterm
-- ================================================
create table environment_cvterm (
    environment_cvterm_id serial not null,
    primary key  (environment_cvterm_id),
    environment_id int not null,
    foreign key (environment_id) references environment (environment_id) on delete cascade,
    cvterm_id int not null,
    foreign key (cvterm_id) references cvterm (cvterm_id) on delete cascade,
    constraint environment_cvterm_c1 unique (environment_id, cvterm_id)
);
create index environment_cvterm_idx1 on environment_cvterm (environment_id);
create index environment_cvterm_idx2 on environment_cvterm (cvterm_id);

COMMENT ON TABLE environment_cvterm IS NULL;

-- ================================================
-- TABLE: phenotype
-- ================================================
-- a phenotypic statement, or a single atomic phenotypic
-- observation
-- 
-- a controlled sentence describing observable effect of non-wt function
-- 
-- e.g. Obs=eye, attribute=color, cvalue=red
-- 
-- see notes from Phenotype Ontology meeting
-- 
-- observable_id       : e.g. anatomy_part, biological_process
-- attr_id             : e.g. process
-- value               : unconstrained free text value
-- cvalue_id           : constrained value from ontology, e.g. "abnormal", "big"
-- assay_id            : e.g. name of specific test
--
create table phenotype (
    phenotype_id serial not null,
    primary key (phenotype_id),
    uniquename text not null,  
    observable_id int,
    foreign key (observable_id) references cvterm (cvterm_id) on delete cascade,
    attr_id int,
    foreign key (attr_id) references cvterm (cvterm_id) on delete set null,
    value text,
    cvalue_id int,
    foreign key (cvalue_id) references cvterm (cvterm_id) on delete set null,
    assay_id int,
    foreign key (assay_id) references cvterm (cvterm_id) on delete set null,
    constraint phenotype_c1 unique (uniquename)
);
create index phenotype_idx1 on phenotype (cvalue_id);
create index phenotype_idx2 on phenotype (observable_id);
create index phenotype_idx3 on phenotype (attr_id);

COMMENT ON TABLE phenotype IS NULL;


-- ================================================
-- TABLE: phenotype_cvterm
-- ================================================
create table phenotype_cvterm (
    phenotype_cvterm_id serial not null,
    primary key (phenotype_cvterm_id),
    phenotype_id int not null,
    foreign key (phenotype_id) references phenotype (phenotype_id) on delete cascade,
    cvterm_id int not null,
    foreign key (cvterm_id) references cvterm (cvterm_id) on delete cascade,
    constraint phenotype_cvterm_c1 unique (phenotype_id, cvterm_id)
);
create index phenotype_cvterm_idx1 on phenotype_cvterm (phenotype_id);
create index phenotype_cvterm_idx2 on phenotype_cvterm (cvterm_id);

COMMENT ON TABLE phenotype_cvterm IS NULL;


-- ================================================
-- TABLE: phenstatement
-- ================================================
-- Phenotypes are things like "larval lethal".  Phenstatements are things
-- like "dpp[1] is recessive larval lethal". So essentially phenstatement
-- is a linking table expressing the relationship between genotype, environment,
-- and phenotype.
-- 
create table phenstatement (
    phenstatement_id serial not null,
    primary key (phenstatement_id),
    genotype_id int not null,
    foreign key (genotype_id) references genotype (genotype_id) on delete cascade,
    environment_id int not null,
    foreign key (environment_id) references environment (environment_id) on delete cascade,
    phenotype_id int not null,
    foreign key (phenotype_id) references phenotype (phenotype_id) on delete cascade,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade,
    pub_id int not null,
    foreign key (pub_id) references pub (pub_id) on delete cascade,
    constraint phenstatement_c1 unique (genotype_id,phenotype_id,environment_id,type_id,pub_id)
);
create index phenstatement_idx1 on phenstatement (genotype_id);
create index phenstatement_idx2 on phenstatement (phenotype_id);

COMMENT ON TABLE phenstatement IS NULL;


-- ================================================
-- TABLE: feature_phenotype
-- ================================================
create table feature_phenotype (
    feature_phenotype_id serial not null,
    primary key (feature_phenotype_id),
    feature_id int not null,
    foreign key (feature_id) references feature (feature_id) on delete cascade,
    phenotype_id int not null,
    foreign key (phenotype_id) references phenotype (phenotype_id) on delete cascade,
    constraint feature_phenotype_c1 unique (feature_id,phenotype_id)       
);
create index feature_phenotype_idx1 on feature_phenotype (feature_id);
create index feature_phenotype_idx2 on feature_phenotype (phenotype_id);

COMMENT ON TABLE feature_phenotype IS NULL;


-- ================================================
-- TABLE: phendesc
-- ================================================
-- RELATION: phendesc
--
-- a summary of a _set_ of phenotypic statements for any one
-- gcontext made in any one
-- publication
-- 
create table phendesc (
    phendesc_id serial not null,
    primary key (phendesc_id),
    genotype_id int not null,
    foreign key (genotype_id) references genotype (genotype_id) on delete cascade,
    environment_id int not null,
    foreign key (environment_id) references environment ( environment_id) on delete cascade,
    description text not null,
    pub_id int not null,
    foreign key (pub_id) references pub (pub_id) on delete cascade,
    constraint phendesc_c1 unique (genotype_id,environment_id,pub_id)
);
create index phendesc_idx1 on phendesc (genotype_id);
create index phendesc_idx2 on phendesc (environment_id);
create index phendesc_idx3 on phendesc (pub_id);

COMMENT ON TABLE phendesc IS NULL;


-- ================================================
-- TABLE: phenotype_comparison
-- ================================================
-- comparison of phenotypes
-- eg, genotype1/environment1/phenotype1 "non-suppressible" wrt 
-- genotype2/environment2/phenotype2
-- 
create table phenotype_comparison (
    phenotype_comparison_id serial not null,
    primary key (phenotype_comparison_id),
    genotype1_id int not null,
        foreign key (genotype1_id) references genotype (genotype_id) on delete cascade,
    environment1_id int not null,
        foreign key (environment1_id) references environment (environment_id) on delete cascade,
    genotype2_id int not null,
        foreign key (genotype2_id) references genotype (genotype_id) on delete cascade,
    environment2_id int not null,
        foreign key (environment2_id) references environment (environment_id) on delete cascade,
    phenotype1_id int not null,
        foreign key (phenotype1_id) references phenotype (phenotype_id) on delete cascade,
    phenotype2_id int,
        foreign key (phenotype2_id) references phenotype (phenotype_id) on delete cascade,
    type_id int not null,
        foreign key (type_id) references cvterm (cvterm_id) on delete cascade,
    pub_id int not null,
    foreign key (pub_id) references pub (pub_id) on delete cascade,
    constraint phenotype_comparison_c1 unique (genotype1_id,environment1_id,genotype2_id,environment2_id,phenotype1_id,type_id,pub_id)
);

COMMENT ON TABLE phenotype_comparison IS NULL;

