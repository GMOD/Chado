-- $Id: phylogeny.sql,v 1.3 2005-07-25 16:27:17 cmungall Exp $
-- ==========================================
-- Chado phylogenetics module
--
-- Richard Bruskiewich
-- Chris Mungall
--
-- nested set tree implementation by way of Joe Celko;
-- see the excellent intro by Aaron Mackey here
-- http://www.oreillynet.com/pub/a/network/2002/11/27/bioconf.html
-- 
-- Initial design: 2004-05-27
--
-- For representing phylogenetic trees; the trees represent the
-- phylogeny of some some kind of sequence feature (mainly proteins)
-- or actual organism taxonomy trees
--
-- This module relies heavily on the sequence module
-- in particular, all the leaf nodes in a tree correspond to features;
-- these will usually be features of type SO:protein or SO:polypeptide
-- (but other trees are possible - eg intron trees)
--
-- if it is desirable to store multiple alignments for each non-leaf node,
-- then each node can be mapped to a feature of type SO:match
-- refer to the sequence module docs for details on storing multiple alignments 
--
-- Annotating nodes:
-- Each node can have a feature attached; this 'feature' is the multiple
-- alignment for non-leaf nodes. It is these features that are annotated
-- rather than annotating the nodes themselves. This has lots of advantages -
-- we can piggyback off of the sequence module and reuse the tables there
--
-- the leaf nodes may have annotations already attached - for example, GO
-- associations
--
-- In fact, it is even possible to annotate ranges along an alignment -
-- this would entail creating a new feature which has a featureloc on
-- the alignment feature
--
-- ==========================================
--
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ============
-- DEPENDENCIES
-- ============
-- :import feature from sequence
-- :import cvterm from cv
-- :import pub from pub
-- :import organism from organism
-- :import dbxref from general
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ============
-- RELATIONS
-- ============

-- ================================================
-- TABLE: phylotree
--        Global anchor for phylogenetic tree
-- ================================================

create table phylotree (
	phylotree_id serial not null,
	primary key (phylotree_id),

        dbxref_id int not null,
        foreign key (dbxref_id) references dbxref (dbxref_id) on delete cascade,
	name varchar(255) null,

-- type: protein, nucleotide, taxonomy, ???
-- the type should be any SO type, or "taxonomy"
	type_id int not null,
	foreign key(type_id) references cvterm (cvterm_id) on delete cascade,

-- REMOVED BY cjm; this is implicit from indexing - see phylonode
-- (and besides, we get into problems with cyclical foreign keys)
--	root_phylonode_id int not null,
--	foreign key (root_phylonode_id) references phylonode (phylonode_id) on delete cascade,

	comment text null,

	unique(phylotree_id)
);
create index phylotree_idx1 on phylotree (phylotree_id);

-- ================================================
-- TABLE: phylotree_pub
--        Tracks citations global to the tree
--        e.g. multiple sequence alignment
--        supporting tree construction
-- ================================================

create table phylotree_pub (
       phylotree_pub_id serial not null,
       primary key (phylotree_pub_id),

       phylotree_id int not null,
       foreign key (phylotree_id) references phylotree (phylotree_id) on delete cascade,
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id) on delete cascade,

       unique(phylotree_id, pub_id)
);
create index phylotree_pub_idx1 on phylotree_pub (phylotree_id);
create index phylotree_pub_idx2 on phylotree_pub (pub_id);

-- ================================================
-- TABLE: phylonode
--        This is the most pervasive element in the
--        phylogeny module, cataloging the 'phylonodes'
--        of tree graphs. Edges are implied
--        by the parent_phylonode_id reflexive closure
-- ================================================

create table phylonode (
       phylonode_id serial not null,
       primary key (phylonode_id),

       phylotree_id int not null,
       foreign key (phylotree_id) references phylotree (phylotree_id) on delete cascade,
       phylonode_idx int not null,

-- root phylonode can have null parent_phylonode_id value
       parent_phylonode_id int null,
       foreign key (parent_phylonode_id) references phylonode (phylonode_id) on delete cascade,

-- nested set implementation
-- for all nodes, the left and right index will be *between* the parents
-- left and right indexes
       left_idx int not null,
       right_idx int not null,

-- type: root, interior, leaf
       type_id int not null,
       foreign key(type_id) references cvterm (cvterm_id) on delete cascade,

--     phylonodes can have optional features attached to them
--        e.g. a protein or nucleotide sequence
--        usually attached to a leaf of the phylotree
--        for non-leaf nodes, the feature may be
--        a feature that is an instance of SO:match;
--        this feature is the alignment of all leaf
--        features beneath it
       feature_id int not null,
       foreign key (feature_id) references feature (feature_id) on delete cascade,

       label varchar(255) null,
       distance float  null,
--       bootstrap float null,

       unique(phylotree_id, phylonode_idx),
       unique(phylotree_id, left_idx),
       unique(phylotree_id, right_idx)
);

-- ================================================
-- TABLE: phylonode_dbxref
--        e.g. for orthology, paralogy group identifiers;
--        could also be used for NCBI taxonomy;
--        for sequences, refer to 'phylonode_feature' 
--        feature associated dbxrefs
-- ================================================

create table phylonode_dbxref (
       phylonode_dbxref_id serial not null,
       primary key (phylonode_dbxref_id),

       phylonode_id int not null,
       foreign key (phylonode_id) references phylonode (phylonode_id) on delete cascade,
       dbxref_id int not null,
       foreign key (dbxref_id) references dbxref (dbxref_id) on delete cascade,

       unique(phylonode_id,dbxref_id)
);
create index phylonode_dbxref_idx1 on phylonode_dbxref (phylonode_id);
create index phylonode_dbxref_idx2 on phylonode_dbxref (dbxref_id);

-- ================================================
-- TABLE: phylonode_pub
-- ================================================

create table phylonode_pub (
       phylonode_pub_id serial not null,
       primary key (phylonode_pub_id),

       phylonode_id int not null,
       foreign key (phylonode_id) references phylonode (phylonode_id) on delete cascade,
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id) on delete cascade,

       unique(phylonode_id, pub_id)
);
create index phylonode_pub_idx1 on phylonode_pub (phylonode_id);
create index phylonode_pub_idx2 on phylonode_pub (pub_id);

-- ================================================
-- TABLE: phylonode_organism
--        this linking table should only be used
--        for nodes in taxonomy trees; it provides
--        a mapping between the node and an organism
--
--        one node can have zero or one organisms
--        one organism can have zero or more nodes
--        (although typically it should only have one,
--         in the standard NCBI taxonomy tree. should we
--         enforce one only, or allow competing taxonomy trees?)
-- ================================================

create table phylonode_organism (
       phylonode_organism_id serial not null,
       primary key (phylonode_organism_id),

       phylonode_id int not null,
       foreign key (phylonode_id) references phylonode (phylonode_id) on delete cascade,
       organism_id int not null,
       foreign key (organism_id) references organism (organism_id) on delete cascade,

       unique(phylonode_id)
-- one phylonode cannot refer to >1 organism
);
create index phylonode_organism_idx1 on phylonode_pub (phylonode_id);
create index phylonode_organism_idx2 on phylonode_pub (organism_id);

-- ================================================
-- TABLE: phylonodeprop
-- e.g. "type_id" could designate phylonode hierarchy
--       relationships, for example: species taxonomy 
--       (kingdom, order, family, genus, species),
--      "ortholog/paralog", "fold/superfold", etc.
-- ================================================

create table phylonodeprop (
       phylonodeprop_id serial not null,
       primary key (phylonodeprop_id),

       phylonode_id int not null,
       foreign key (phylonode_id) references phylonode (phylonode_id) on delete cascade,
       type_id int not null,
       foreign key (type_id) references cvterm (cvterm_id) on delete cascade,

       value text not null default '',
-- not sure how useful the rank concept is here, but I'll leave it in for now
       rank int not null default 0,

       unique(phylonode_id, type_id, value, rank)
);
create index phylonodeprop_idx1 on phylonodeprop (phylonode_id);
create index phylonodeprop_idx2 on phylonodeprop (type_id);

-- ================================================
-- TABLE: phylonode_relationship
--        this is for exotic relationships that are
--        not strictly hierarchical; for example,
--        horizontal gene transfer
--
--        use of this table would be highly unusual;
--        most phylogenetic trees are strictly
--        hierarchical.
--        nevertheless, it is here for completion
-- ================================================

create table phylonode_relationship (
       phylonode_relationship_id serial not null,
       primary key (phylonode_relationship_id),

       subject_id int not null,
       foreign key (subject_id) references phylonode (phylonode_id) on delete cascade,
       object_id int not null,
       foreign key (object_id) references phylonode (phylonode_id) on delete cascade,
       type_id int not null,
       foreign key (type_id) references cvterm (cvterm_id) on delete cascade,
       rank int,

       unique(subject_id, object_id, type_id)
);
create index phylonode_relationship_idx1 on phylonode_relationship (subject_id);
create index phylonode_relationship_idx2 on phylonode_relationship (object_id);
create index phylonode_relationship_idx3 on phylonode_relationship (type_id);
