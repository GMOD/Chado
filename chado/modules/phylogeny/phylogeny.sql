-- $Id: phylogeny.sql,v 1.9 2007-03-23 15:18:02 scottcain Exp $
-- ==========================================
-- Chado phylogenetics module
--
-- Richard Bruskiewich
-- Chris Mungall
--
-- Initial design: 2004-05-27
--
-- ============
-- DEPENDENCIES
-- ============
-- :import feature from sequence
-- :import cvterm from cv
-- :import pub from pub
-- :import organism from organism
-- :import dbxref from general
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- ================================================
-- TABLE: phylotree
-- ================================================

create table phylotree (
	phylotree_id serial not null,
	primary key (phylotree_id),
   dbxref_id int not null,
   foreign key (dbxref_id) references dbxref (dbxref_id) on delete cascade,
	name varchar(255) null,
	type_id int,
	foreign key(type_id) references cvterm (cvterm_id) on delete cascade,
	comment text null,
	unique(phylotree_id)
);
create index phylotree_idx1 on phylotree (phylotree_id);

COMMENT ON TABLE phylotree IS 'Global anchor for phylogenetic tree.';
COMMENT ON COLUMN phylotree.type_id IS 'Type: protein, nucleotide, taxonomy, for example. The type should be any SO type, or "taxonomy".';


-- ================================================
-- TABLE: phylotree_pub
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

COMMENT ON TABLE phylotree_pub IS 'Tracks citations global to the tree e.g. multiple sequence alignment supporting tree construction.';

-- ================================================
-- TABLE: phylonode
-- ================================================

create table phylonode (
       phylonode_id serial not null,
       primary key (phylonode_id),
       phylotree_id int not null,
       foreign key (phylotree_id) references phylotree (phylotree_id) on delete cascade,
       parent_phylonode_id int null,
       foreign key (parent_phylonode_id) references phylonode (phylonode_id) on delete cascade,
       left_idx int not null,
       right_idx int not null,
       type_id int,
       foreign key(type_id) references cvterm (cvterm_id) on delete cascade,
       feature_id int,
       foreign key (feature_id) references feature (feature_id) on delete cascade,
       label varchar(255) null,
       distance float  null,
--       Bootstrap float null.
       unique(phylotree_id, left_idx),
       unique(phylotree_id, right_idx)
);
COMMENT ON TABLE phylonode IS 'This is the most pervasive
       element in the phylogeny module, cataloging the "phylonodes" of
       tree graphs. Edges are implied by the parent_phylonode_id
       reflexive closure. For all nodes in a nested set implementation the left and right index will be *between* the parents left and right indexes.';
COMMENT ON COLUMN phylonode.feature_id IS 'Phylonodes can have optional features attached to them e.g. a protein or nucleotide sequence usually attached to a leaf of the phylotree for non-leaf nodes, the feature may be a feature that is an instance of SO:match; this feature is the alignment of all leaf features beneath it.';
COMMENT ON COLUMN phylonode.type_id IS 'Type: e.g. root, interior, leaf.';
COMMENT ON COLUMN phylonode.parent_phylonode_id IS 'Root phylonode can have null parent_phylonode_id value.';


-- ================================================
-- TABLE: phylonode_dbxref
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

COMMENT ON TABLE phylonode_dbxref IS 'For example, for orthology, paralogy group identifiers; could also be used for NCBI taxonomy; for sequences, refer to phylonode_feature, feature associated dbxrefs.';


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
-- ================================================

create table phylonode_organism (
       phylonode_organism_id serial not null,
       primary key (phylonode_organism_id),

       phylonode_id int not null,
       foreign key (phylonode_id) references phylonode (phylonode_id) on delete cascade,
       organism_id int not null,
       foreign key (organism_id) references organism (organism_id) on delete cascade,

       unique(phylonode_id)
);
create index phylonode_organism_idx1 on phylonode_organism (phylonode_id);
create index phylonode_organism_idx2 on phylonode_organism (organism_id);

COMMENT ON TABLE phylonode_organism IS 'This linking table should only be used for nodes in taxonomy trees; it provides a mapping between the node and an organism. One node can have zero or one organisms, one organism can have zero or more nodes (although typically it should only have one in the standard NCBI taxonomy tree).';
COMMENT ON COLUMN phylonode_organism.phylonode_id IS 'One phylonode cannot refer to >1 organism.';


-- ================================================
-- TABLE: phylonodeprop
-- ================================================

create table phylonodeprop (
       phylonodeprop_id serial not null,
       primary key (phylonodeprop_id),

       phylonode_id int not null,
       foreign key (phylonode_id) references phylonode (phylonode_id) on delete cascade,
       type_id int not null,
       foreign key (type_id) references cvterm (cvterm_id) on delete cascade,

       value text not null default '',
-- It is not clear how useful the rank concept is here, leave it in for now.
       rank int not null default 0,

       unique(phylonode_id, type_id, value, rank)
);
create index phylonodeprop_idx1 on phylonodeprop (phylonode_id);
create index phylonodeprop_idx2 on phylonodeprop (type_id);

COMMENT ON COLUMN phylonodeprop.type_id IS 'type_id could designate phylonode hierarchy relationships, for example: species taxonomy (kingdom, order, family, genus, species), "ortholog/paralog", "fold/superfold", etc.';

-- ================================================
-- TABLE: phylonode_relationship
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

COMMENT ON TABLE phylonode_relationship IS 'This is for exotic relationships that are not strictly hierarchical; for example, horizontal gene transfer. Use of this table would be highly unusual; most phylogenetic trees are strictly hierarchical. Nevertheless, it is here for completeness.';
