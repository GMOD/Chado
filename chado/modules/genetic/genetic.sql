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
-- we use the gxe relation (genetic context X environmental context) to
-- represent the actual organismal context under observation
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
-- kind of linking table between stock and gcontext
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
-- ============
-- RELATIONS
-- ============


-- RELATION: gcontext
--
-- genetic context
-- 
-- essentially a combination of genotype and extra-genotype gene
-- products; eg a genotype + some RNAi product
-- 
-- AND ALSO ENVIRONMENT!!!
-- 
-- the uniquename should be derived from the features making
-- up the genetic context(see feature_gcontext)
-- 
-- uniquename          : a human-readable unique identifier
--

CREATE TABLE gcontext (
	gcontext_id	serial not null,
	primary key (gcontext_id),
	uniquename	varchar(255) not null,
	description	text,
	pub_id	int not null,
	foreign key (pub_id) references pub (pub_id) on delete cascade,

	unique(uniquename)
);
create index gcontext_idx1 on gcontext(uniquename);
-- ****************************************


-- RELATION: gcontext_relationship
--
-- genetic contexts can be related to eachother (eg ISA/derived-from)
-- this means that different authors can talk about essentially the
-- same gcontext, although each would have their own gcontext_id;
-- they would all be descended from the same parent gcontext
-- 
--
CREATE TABLE gcontext_relationship (
	gcontext_relationship_id	serial not null,
	primary key (gcontext_relationship_id),
	subjectgc_id	int not null,
	foreign key (subjectgc_id) references gcontext (gcontext_id) on delete cascade,
	objectgc_id	int not null, 
	foreign key (objectgc_id) references gcontext (gcontext_id) on delete cascade,
 	type_id	int not null,
	foreign key (type_id) references cvterm (cvterm_id) on delete cascade,

	unique(subjectgc_id, objectgc_id, type_id)
);
create index gcontext_relationship_idx1 on gcontext_relationship (subjectgc_id);
create index gcontext_relationship_idx2 on gcontext_relationship (objectgc_id);
create index gcontext_relationship_idx3 on gcontext_relationship (type_id);
-- ****************************************


-- RELATION: feature_gcontext
--
-- A gcontext is defined by a collection of features
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
CREATE TABLE feature_gcontext (
	feature_gcontext_id	serial not null,
	primary key (feature_gcontext_id),
	feature_id	int not null,
	foreign key (feature_id) references feature (feature_id) on delete cascade,
	gcontext_id	int not null,
	foreign key (gcontext_id) references gcontext (gcontext_id) on delete cascade,
	chromosome_id	int,
	foreign key (chromosome_id) references feature(feature_id) on delete set null,
	rank	int not null,
	cgroup	int not null,
	cvterm_id	int not null,
	foreign key (cvterm_id) references cvterm(cvterm_id) on delete cascade,

	unique(feature_id, gcontext_id, cvterm_id)
);
create index feature_gcontext_idx1 on feature_gcontext (feature_id);
create index feature_gcontext_idx2 on feature_gcontext (gcontext_id);
-- ****************************************


-- RELATION: gcontextprop
--
-- key/val pairs for a genetic context
-- can be environmental; eg temperature_degrees_c=36
-- 
-- value               : unconstrained free text value
--
CREATE TABLE gcontextprop (
	gcontextprop_id	serial not null,
	primary key (gcontextprop_id),
	gcontext_id	int not null,
	foreign key (gcontext_id) references gcontext (gcontext_id) on delete cascade,
	type_id	int not null,
	foreign key (type_id) references cvterm (cvterm_id) on delete cascade,
	value	text not null,

	unique(gcontext_id, type_id, value)
);
create index gcontextprop_idx1 on gcontextprop (gcontext_id);
create index gcontextprop_idx2 on gcontextprop (type_id);
-- ****************************************


-- RELATION: phenstatement
--
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
CREATE TABLE phenstatement (
	phenstatement_id	serial not null,
	primary key (phenstatement_id),
	gcontext_id int not null,
	foreign key (gcontext_id) references gcontext (gcontext_id) on delete cascade,
	dbxref_id	int not null,
	foreign key (dbxref_id) references dbxref (dbxref_id) on delete cascade,
	observable_id	int not null,
	foreign key (observable_id) references cvterm (cvterm_id) on delete cascade,
	attr_id	int,
	foreign key (attr_id) references cvterm (cvterm_id) on delete set null,
	value	text,
	cvalue_id	int,
	foreign key (cvalue_id) references cvterm (cvterm_id) on delete set null,
	assay_id	int,
	foreign key (assay_id) references cvterm (cvterm_id) on delete set null,

	unique(gcontext_id, dbxref_id, observable_id)	
);
create index phenstatement_idx1 on phenstatement (gcontext_id);
create index phenstatement_idx2 on phenstatement (observable_id);
create index phenstatement_idx3 on phenstatement (attr_id);
-- ****************************************


-- RELATION: phendesc
--
-- a summary of a _set_ of phenotypic statements for any one
-- gcontext made in any one
-- publication
-- 
--
CREATE TABLE phendesc (
	phendesc_id	serial not null,
	primary key (phendesc_id),
	gcontext_id	int not null,
	foreign key (gcontext_id) references gcontext (gcontext_id) on delete cascade,
	description	text not null,

	unique(gcontext_id, description)
);
create index phendesc_idx1 on phendesc (gcontext_id);
-- ****************************************


-- RELATION: phenstatement_relationship
--
-- interaction (suppression, enhancement), rescue, complementation
-- are always relationships between phenstatements
-- 
--
CREATE TABLE phenstatement_relationship (
	phenstatement_relationship_id serial not null,
	primary key (phenstatement_relationship_id),
	subject_id	int not null,
	foreign key (subject_id) references phenstatement (phenstatement_id) on delete cascade,
	object_id	int not null,
	foreign key (object_id) references phenstatement (phenstatement_id) on delete cascade,
	type_id	int not null,
	foreign key (type_id) references cvterm (cvterm_id) on delete cascade,
	comment_id	int not null,
	foreign key (comment_id) references cvterm (cvterm_id) on delete cascade,

	unique(subject_id, object_id, type_id)
);
create index phenstatement_relationship_idx1 on phenstatement_relationship (subject_id);
create index phenstatement_relationship_idx2 on phenstatement_relationship (subject_id);
create index phenstatement_relationship_idx3 on phenstatement_relationship (type_id);
-- ****************************************


-- RELATION: phenstatement_cvterm
--
-- arbitrary qualifiers
-- for anything that doesn't fit into obs/attr/val model
-- 
--
CREATE TABLE phenstatement_cvterm (
	phenstatement_cvterm_id	serial not null,
	primary key (phenstatement_cvterm_id),
	phenstatement_id	int not null,
	foreign key (phenstatement_id) references phenstatement (phenstatement_id) on delete cascade,
	cvterm_id	int not null,
	foreign key (cvterm_id) references cvterm (cvterm_id) on delete cascade,

	unique(phenstatement_id, cvterm_id)
);
create index phenstatement_cvterm_idx1 on phenstatement_cvterm (phenstatement_id);	
create index phenstatement_cvterm_idx2 on phenstatement_cvterm (cvterm_id);	
-- ****************************************


-- RELATION: phenstatementprop
--
-- arbitrary key=value pairs
-- e.g. penetrance_pct=80
-- 
-- value               : unconstrained free text value
--
CREATE TABLE phenstatementprop (
	phenstatementprop_id	serial not null,
	primary key (phenstatementprop_id),
	phenstatement_id	int not null,
	foreign key (phenstatement_id) references phenstatement (phenstatement_id) on delete cascade,
	type_id	int not null,
	foreign key (type_id) references cvterm (cvterm_id) on delete cascade,
	value	text not null,

	unique(phenstatement_id, type_id, value)
);
create index phenstatementprop_idx1 on phenstatementprop (phenstatement_id);
create index phenstatementprop_idx2 on phenstatementprop (type_id);
-- ****************************************
