## ================================================
## TABLE: feature
## ================================================

create table feature (
       feature_id serial not null,
       primary key (feature_id),
       name varchar(255) not null,
       fmin int,
       fmax int,
       fstrand smallint,
       residues text,
       seqlen int,
       md5checksum char(32),
       type_id int,
       foreign key (type_id) references cvterm (cvterm_id),
       source_feature_id int,
       foreign key (source_feature_id) references feature (feature_id),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp,

       unique(name, fmin, fmax, fstrand, seqlen, md5checksum, type_id)
);
## dbxref should be unique; does that work w/ null values?
## every feature has to have an accession (dbxref_id)
## IMPORTANT: fmin and fmax are space-based coordinates
## this is vital as it allows us to represent zero-length
## features eg splice sites, insertion points without
## an awkward fuzzy system

## by using min and max rather than start/end we make
## intersection queries faster/easier, but we also make
## queries involing up/downstream more difficult.
## min and max is good as it is unambiguous - many systems
## (eg bioperl, gff) use "start" and "end" whereas what they actually
## mean is min and max, NOT 5', 3'

## seqlen is redundant except for transcripts (where we're being ambiguous)

## ================================================
## TABLE: feature_pub
## ================================================

create table feature_pub (
       feature_id int not null,
       foreign key (feature_id) references feature (feature_id),
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp,

       unique(feature_id, pub_id)
);


## ================================================
## TABLE: featureprop
## ================================================

create table featureprop (
       featureprop_id serial not null,
       primary key (featureprop_id),
       feature_id int,
       foreign key (feature_id) references feature (feature_id),
       pkey_id int not null,
       foreign key (pkey_id) references cvterm (cvterm_id),
       pval text not null,
       prank integer,
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp,

       unique(feature_id, pkey_id, pval, prank)
);
## feature_prop_id allows us to link a featureprop record to a publication
## ARE WE BEING CONSISTENT IN HOW WE LINK PROPERTIES TO PUBLICATIONS?  LOOK
## AT ALL OTHER PROPERTY TABLES!!!


## ================================================
## TABLE: featureprop_pub
## ================================================

create table featureprop_pub (
       featureprop_id int not null,
       foreign key (featureprop_id) references featureprop (featureprop_id),
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp,

       unique(featureprop_id, pub_id)
);

## ================================================
## TABLE: feature_dbxref
## ================================================

create table feature_dbxref (
       feature_dbxref_id serial not null,
       primary key (feature_dbxref_id),
       feature_id int,
       foreign key (feature_id) references feature (feature_id),
       dbxref_id int,
       foreign key (dbxref_id) references dbxref (dbxref_id),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp,

       unique(feature_dbxref_id, dbxref_id)
);
## each feature can be linked to multiple external dbs


## ================================================
## TABLE: feature_relationship
## ================================================

create table feature_relationship (
       feature_relationship_id serial not null,
       primary key (feature_relationship_id),
       subjfeature_id int,
       foreign key (subjfeature_id) references feature (feature_id),
       objfeature_id int,
       foreign key (objfeature_id) references feature (feature_id),
       type_id int,
       foreign key (type_id) references cvterm (cvterm_id),
       relrank int,
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp,

       unique(subjfeature_id, objfeature_id, type_id)
);

# features can be arranged in graphs, eg exon partof transcript 
# partof gene; translation madeby transcript
# if type is thought of as a verb, each arc makes a statement
# [SUBJECT VERB OBJECT]
# object can also be thought of as parent, and subject as child
#
# we include the relationship rank/order, because even though
# most of the time we can order things implicitly by sequence
# coordinates, we can't always do this - eg transpliced genes.
# it's also useful for quickly getting implicit introns

## ================================================
## TABLE: feature_cvterm
## ================================================

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
## Link to cvterm module from feature

## ================================================
## TABLE: gene
## ================================================

create table gene (
       gene_id serial not null,
       primary key (gene_id),
## in FlyBase, the gene symbol
       name varchar(255) not null,
       type_id int,
       foreign key (type_id) references cvterm (cvterm_id),
## accession holds the FBgn in FlyBase
       dbxref_id int,
       foreign key (dbxref_id) references dbxref(dbxref_id),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp,

       unique(name),
       unique(dbxref_id)
);
## the set of tables handling genes, which here are exclusively grouping
## objects.  All FlyBase data currently stored under "Gene" and associated
## tables will need to be moved under the wildtype allele

## The localization of gene in the sequence module, combinded with moving
## of all data in FlyBase currently under "Gene" under the wild-type allele
## constitutes a large  part of the "integration".

## ================================================
## TABLE: gene_synonym
## ================================================

create table gene_synonym (
       synonym_id int not null,
       foreign key (synonym_id) references synonym (synonym_id),
       gene_id int not null,
       foreign key (gene_id) references gene (gene_id),
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id),
## typically a synonym exists so that somebody querying the db with an
## obsolete name can find the object they're looking for (under its current
## name.  If the synonym has been used publicly & deliberately (eg in a 
## paper), it my also be listed in reports as a synonym.   If the synonym 
## was not used deliberately (eg, there was a typo which went public), then 
## the is_internal bit may be set to 'true' so that it is known that the 
## synonym is "internal" and should be queryable but should not be listed 
## in reports as a valid synonym.
       is_internal boolean not null default 'false',
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp,

       unique(synonym_id, gene_id, pub_id)
);

## ================================================
## TABLE: gene_feature
## ================================================

create table gene_feature (
       gene_id int not null,
       foreign key (gene_id) references gene (gene_id),
       feature_id int not null,
       foreign key (feature_id) references feature (feature_id),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp,

       unique(gene_id, feature_id)
);


## ================================================
## TABLE: feature_organism
## ================================================

create table feature_organism (
       feature_id int not null,
       foreign key (feature_id) references feature (feature_id),
       organism_id int not null,
       foreign key (organism_id) references organism (organism_id),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp
);

## ================================================
## TABLE: feature_synonym
## ================================================

create table feature_synonym (
       synonym_id int not null,
       foreign key (synonym_id) references synonym (synonym_id),
       feature_id int not null,
       foreign key (feature_id) references feature (feature_id),
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id),
## typically a synonym exists so that somebody querying the db with an
## obsolete name can find the object they're looking for (under its current
## name.  If the synonym has been used publicly & deliberately (eg in a 
## paper), it my also be listed in reports as a synonym.   If the synonym 
## was not used deliberately (eg, there was a typo which went public), then 
## the is_internal bit may be set to 'true' so that it is known that the 
## synonym is "internal" and should be queryable but should not be listed 
## in reports as a valid synonym.
       is_internal boolean not null default 'false',
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp,

       unique(synonym_id, feature_id, pub_id)
);

# [this needs moved to a different file]
# typed feature
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

# everything related to a gene; assumes the 'gene graph'
# goes to depth 2 maximum; will get everything up to 2 nodes
# away, eg transcripts, exons, translations; but also 
# other features we may want to associate - variations, regulatory
# regions, pre/post mRNA distinctions, introns etc

create view genemodel as
 select * from fgene, tfeature1, tfeature2, 
          feature_relationship r1, feature_relationship r2
 where fgene.feature_id = r1.objfeature_id
 and tfeature1.feature_id = r1.subjfeature_id
 and r1.objfeature_id = r2.subjfeature_id
 and r2.objfeature_id = tfeature2.feature_id;

##  How do we attribute the statement that such and such a feature is at 
##  a certain location on a sequence?  This is captured in the link between
##  the feature and a publication.   

## TODO: make a use-case where a regulatory region is included
## in the graph.   Can mutations in the reg_region be included?

## TODO:  decorator tables linked to feature (eg GeneData, InsertionData)?
##  instead of using feature_prop...


## references from other modules:
##	      expression: feature_expression
