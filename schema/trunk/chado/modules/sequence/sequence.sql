-- ================================================
-- TABLE: feature
-- ================================================

create table feature (
       feature_id serial not null,
       primary key (feature_id),

-- dbxref_string uniquely identifies editable features
       dbxref_str varchar(255),
-- dbxref_id is replaced by dbxref_str
--       dbxref_id int,
--       foreign key (dbxref_id) references dbxref (dbxref_id),
       
       name varchar(255),
       residues text,
       seqlen int,
       md5checksum char(32),
       type_id int,
       foreign key (type_id) references cvterm (cvterm_id),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp,

       unique(dbxref_str)
);

-- ================================================
-- TABLE: featureloc
-- ================================================

-- each feature can have 0 or more locations.
-- multiple locations do NOT indicate non-contiguous locations.
-- instead they designate alternate locations or grouped locations;
-- for instance, a feature designating a blast hit or hsp will have two
-- locations, one on the query feature, one on the subject feature.
-- features representing sequence variation could have alternate locations
-- instantiated on a feature on the mutant strain.
-- the field "rank" is used to differentiate these different locations.
-- the default rank '0' is used for the main/primary location (eg in
-- similarity features, 0 is query, 1 is subject), although sometimes
-- this will be symmeytical and there is no primary location.
--
-- redundant locations can also be stored - for instance, the position
-- of an exon on a BAC and in global coordinates. the field "locgroup"
-- is used to differentiate these groupings of locations. the default
-- locgroup '0' is used for the main/primary location, from which the
-- others can be derived via coordinate transformations. another
-- example of redundant locations is storing ORF coordinates relative
-- to both transcript and genome. redundant locations open the possibility
-- of the database getting into inconsistent states; this schema gives
-- us the flexibility of both 'warehouse' instantiations with redundant
-- locations (easier for querying) and 'management' instantiations with
-- no redundant locations.

-- most features (exons, transcripts, etc) will have 1 location, with
-- locgroup and rank equal to 0
--
-- an example of using both locgroup and rank:
-- imagine a feature indicating a conserved region between the chromosomes
-- of two different species. we may want to keep redundant locations on
-- both contigs and chromosomes. we would thus have 4 locations for the
-- single conserved region feature - two distinct locgroups (contig level
-- and chromosome level) and two distinct ranks (for the two species).

-- altresidues is used to store alternate residues of a feature, when these
-- differ from feature.residues. for instance, a SNP feature located on
-- a wild and mutant protein would have different alresidues.
-- for alignment/similarity features, the altresidues is used to represent
-- the alignment string.

-- note on variation features; even if we don't want to instantiate a mutant
-- chromosome/contig feature, we can still represent a SNP etc with 2 locations,
-- one (rank 0) on the genome, the other (rank 1) would have most fields null,
-- except for altresidues

-- IMPORTANT: fnbeg and fnend are space-based (INTERBASE) coordinates
-- this is vital as it allows us to represent zero-length
-- features eg splice sites, insertion points without
-- an awkward fuzzy system

-- nbeg, nend are for feature natural begin/end
-- by natural begin, end we mean these are the actual
-- beginning (5' position) and actual end (3' position)
-- rather than the low position and high position, as
-- these terms are sometimes erroneously used

create table featureloc (
       featureloc_id serial not null,
       primary key (featureloc_id),

       feature_id int not null,
       foreign key (feature_id) references feature (feature_id),
       srcfeature_id int,
       foreign key (srcfeature_id) references feature (feature_id),

       nbeg int,
       is_nbeg_partial boolean not null default 'false',
       nend int,
       is_nend_partial boolean not null default 'false',
       strand smallint,

       residue_info text,

       locgroup int not null default 0,
       rank     int not null default 0,

       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp,

       unique (feature_id, srcfeature_id),
       unique (feature_id, locgroup, rank)
);


-- ================================================
-- TABLE: feature_pub
-- ================================================

create table feature_pub (
       feature_id int not null,
       foreign key (feature_id) references feature (feature_id),
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp,

       unique(feature_id, pub_id)
);


-- ================================================
-- TABLE: featureprop
-- ================================================

create table featureprop (
       featureprop_id serial not null,
       primary key (featureprop_id),
       feature_id int not null,
       foreign key (feature_id) references feature (feature_id),
       pkey_id int not null,
       foreign key (pkey_id) references cvterm (cvterm_id),
       pval text not null default '',
       prank integer,
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp,

       unique(feature_id, pkey_id, pval, prank)
);
-- feature_prop_id allows us to link a featureprop record to a publication
-- ARE WE BEING CONSISTENT IN HOW WE LINK PROPERTIES TO PUBLICATIONS?  LOOK
-- AT ALL OTHER PROPERTY TABLES!!!


-- ================================================
-- TABLE: featureprop_pub
-- ================================================

create table featureprop_pub (
       featureprop_id int not null,
       foreign key (featureprop_id) references featureprop (featureprop_id),
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp,

       unique(featureprop_id, pub_id)
);

-- ================================================
-- TABLE: feature_dbxref
-- ================================================

create table feature_dbxref (
       feature_dbxref_id serial not null,
       primary key (feature_dbxref_id),
       feature_id int,
       foreign key (feature_id) references feature (feature_id),
       dbxref_str varchar(255),
       foreign key (dbxref_str) references dbxref (dbxref_str),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp,

       unique(feature_dbxref_id, dbxref_str)
);
-- each feature can be linked to multiple external dbs


-- ================================================
-- TABLE: feature_relationship
-- ================================================

create table feature_relationship (
       feature_relationship_id serial not null,
       primary key (feature_relationship_id),
       subjfeature_id int not null,
       foreign key (subjfeature_id) references feature (feature_id),
       objfeature_id int not null,
       foreign key (objfeature_id) references feature (feature_id),
       type_id int,
       foreign key (type_id) references cvterm (cvterm_id),
       relrank int,
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp,

       unique(subjfeature_id, objfeature_id, type_id)
);

-- features can be arranged in graphs, eg exon partof transcript 
-- partof gene; translation madeby transcript
-- if type is thought of as a verb, each arc makes a statement
-- [SUBJECT VERB OBJECT]
-- object can also be thought of as parent, and subject as child
--
-- we include the relationship rank/order, because even though
-- most of the time we can order things implicitly by sequence
-- coordinates, we can't always do this - eg transpliced genes.
-- it's also useful for quickly getting implicit introns

-- ================================================
-- TABLE: feature_cvterm
-- ================================================

create table feature_cvterm (
       feature_cvterm_id serial not null,
       primary key (feature_cvterm_id),
       feature_id int not null,
       foreign key (feature_id) references feature (feature_id),
       cvterm_id int not null,
       foreign key (cvterm_id) references cvterm (cvterm_id),
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp,

       unique(feature_id, cvterm_id, pub_id)
);
-- Link to cvterm module from feature

-- ================================================
-- TABLE: gene
-- ================================================

create table gene (
       gene_id serial not null,
       primary key (gene_id),
-- the gene symbol
       name varchar(255) not null,
-- the fullname for a gene (if different from the symbol)
       fullname varchar(255),
       type_id int,
       foreign key (type_id) references cvterm (cvterm_id),
-- accession holds the FBgn in FlyBase
       dbxref_str int,
       foreign key (dbxref_str) references dbxref(dbxref_str),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp,

       unique(name),
       unique(dbxref_str)
;
-- the set of tables handling genes, which here are exclusively grouping
-- objects.  All FlyBase data currently stored under "Gene" and associated
-- tables will need to be moved under the wildtype allele

-- The localization of gene in the sequence module, combinded with moving
-- of all data in FlyBase currently under "Gene" under the wild-type allele
-- constitutes a large  part of the "integration".

-- ================================================
-- TABLE: gene_synonym
-- ================================================

create table gene_synonym (
       synonym_id int not null,
       foreign key (synonym_id) references synonym (synonym_id),
       gene_id int not null,
       foreign key (gene_id) references gene (gene_id),
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id),
-- typically a synonym exists so that somebody querying the db with an
-- obsolete name can find the object they're looking for (under its current
-- name.  If the synonym has been used publicly & deliberately (eg in a 
-- paper), it my also be listed in reports as a synonym.   If the synonym 
-- was not used deliberately (eg, there was a typo which went public), then 
-- the is_internal bit may be set to 'true' so that it is known that the 
-- synonym is "internal" and should be queryable but should not be listed 
-- in reports as a valid synonym.
       is_internal boolean not null default 'false',
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp,

       unique(synonym_id, gene_id, pub_id)
);

-- ================================================
-- TABLE: gene_feature
-- ================================================

create table gene_feature (
       gene_id int not null,
       foreign key (gene_id) references gene (gene_id),
       feature_id int not null,
       foreign key (feature_id) references feature (feature_id),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp,

       unique(gene_id, feature_id)
);


-- ================================================
-- TABLE: feature_organism
-- ================================================

create table feature_organism (
       feature_id int not null,
       foreign key (feature_id) references feature (feature_id),
       organism_id int not null,
       foreign key (organism_id) references organism (organism_id),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp
);

-- ================================================
-- TABLE: feature_synonym
-- ================================================

create table feature_synonym (
       synonym_id int not null,
       foreign key (synonym_id) references synonym (synonym_id),
       feature_id int not null,
       foreign key (feature_id) references feature (feature_id),
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id),
-- typically a synonym exists so that somebody querying the db with an
-- obsolete name can find the object they're looking for (under its current
-- name.  If the synonym has been used publicly & deliberately (eg in a 
-- paper), it my also be listed in reports as a synonym.   If the synonym 
-- was not used deliberately (eg, there was a typo which went public), then 
-- the is_internal bit may be set to 'true' so that it is known that the 
-- synonym is "internal" and should be queryable but should not be listed 
-- in reports as a valid synonym.
       is_internal boolean not null default 'false',
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp,

       unique(synonym_id, feature_id, pub_id)
);

-- [this needs moved to a different file]
-- typed feature
create view tfeature as
 select * from feature, cvterm
 where feature.type_id = cvterm.cvterm_id;

create view fgene as
 select * from tfeature where term_name = 'gene';

create view fexon as
 select * from tfeature where term_name = 'exon';

create view ftranscript as
 select * from tfeature where term_name = 'transcript';

create view gene2transcript as
 select * from fgene, ftranscript, feature_relationship r
 where fgene.feature_id = r.objfeature_id
 and ftranscript.feature_id = r.subjfeature_id;

create view transcript2exon as
 select * from ftranscript, fexon, feature_relationship r
 where ftranscript.feature_id = r.objfeature_id
 and   fexon.feature_id = r.subjfeature_id;

-- everything related to a gene; assumes the 'gene graph'
-- goes to depth 2 maximum; will get everything up to 2 nodes
-- away, eg transcripts, exons, translations; but also 
-- other features we may want to associate - variations, regulatory
-- regions, pre/post mRNA distinctions, introns etc

create view genemodel as
 select * from fgene, tfeature1, tfeature2, 
          feature_relationship r1, feature_relationship r2
 where fgene.feature_id = r1.objfeature_id
 and tfeature1.feature_id = r1.subjfeature_id
 and r1.objfeature_id = r2.subjfeature_id
 and r2.objfeature_id = tfeature2.feature_id;

--  How do we attribute the statement that such and such a feature is at 
--  a certain location on a sequence?  This is captured in the link between
--  the feature and a publication.   

-- TODO: make a use-case where a regulatory region is included
-- in the graph.   Can mutations in the reg_region be included?

-- TODO:  decorator tables linked to feature (eg GeneData, InsertionData)?
--  instead of using feature_prop...


-- references from other modules:
--	      expression: feature_expression
