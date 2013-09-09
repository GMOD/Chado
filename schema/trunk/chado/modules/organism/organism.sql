-- $Id: organism.sql,v 1.19 2007/04/01 18:45:41 briano Exp $
-- ==========================================
-- Chado organism module
--
-- ============
-- DEPENDENCIES
-- ============
-- :import cvterm from cv
-- :import dbxref from general
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- ================================================
-- TABLE: organism
-- ================================================

drop table organism cascade;
create table organism (
	organism_id serial not null,
	primary key (organism_id),
	abbreviation varchar(255) null,
	genus varchar(255) not null,
	species varchar(255) not null,
	common_name varchar(255) null,
	comment text null,
	constraint organism_c1 unique (genus,species)
);

COMMENT ON TABLE organism IS 'The organismal taxonomic
classification. Note that phylogenies are represented using the
phylogeny module, and taxonomies can be represented using the cvterm
module or the phylogeny module.';

COMMENT ON COLUMN organism.species IS 'A type of organism is always
uniquely identified by genus and species. When mapping from the NCBI
taxonomy names.dmp file, this column must be used where it
is present, as the common_name column is not always unique (e.g. environmental
samples). If a particular strain or subspecies is to be represented,
this is appended onto the species name. Follows standard NCBI taxonomy
pattern.';


-- ================================================
-- TABLE: organism_dbxref
-- ================================================

drop table organism_dbxref cascade;
create table organism_dbxref (
    organism_dbxref_id serial not null,
    primary key (organism_dbxref_id),
    organism_id int not null,
    foreign key (organism_id) references organism (organism_id) on delete cascade INITIALLY DEFERRED,
    dbxref_id int not null,
    foreign key (dbxref_id) references dbxref (dbxref_id) on delete cascade INITIALLY DEFERRED,
    constraint organism_dbxref_c1 unique (organism_id,dbxref_id)
);
create index organism_dbxref_idx1 on organism_dbxref (organism_id);
create index organism_dbxref_idx2 on organism_dbxref (dbxref_id);

COMMENT ON TABLE library_dbxref IS 'Links a library to dbxrefs.';


-- ================================================
-- TABLE: organismprop
-- ================================================

drop table organismprop cascade;
create table organismprop (
    organismprop_id serial not null,
    primary key (organismprop_id),
    organism_id int not null,
    foreign key (organism_id) references organism (organism_id) on delete cascade INITIALLY DEFERRED,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    value text null,
    rank int not null default 0,
    constraint organismprop_c1 unique (organism_id,type_id,rank)
);
create index organismprop_idx1 on organismprop (organism_id);
create index organismprop_idx2 on organismprop (type_id);

COMMENT ON TABLE organismprop IS 'Tag-value properties - follows standard chado model.';


-- ================================================
-- TABLE: organismprop_pub
-- ================================================

drop table organismprop_pub cascade;
create table organismprop_pub (
    organismprop_pub_id serial not null,
    primary key (organismprop_pub_id),
    organismprop_id int not null,
    foreign key (organismprop_id) references organismprop (organismprop_id) on delete cascade INITIALLY DEFERRED,
    pub_id int not null,
    foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
    value text null,
    rank int not null default 0,
    constraint organismprop_pub_c1 unique (organismprop_id,pub_id)
);
create index organismprop_pub_idx1 on organismprop_pub (organismprop_id);
create index organismprop_pub_idx2 on organismprop_pub (pub_id);

COMMENT ON TABLE organismprop_pub IS 'Attribution for organismprop.';


-- ================================================
-- TABLE: organism_pub
-- ================================================

drop table organism_pub cascade;
create table organism_pub (
       organism_pub_id serial not null,
       primary key (organism_pub_id),
       organism_id int not null,
       foreign key (organism_id) references organism (organism_id) on delete cascade INITIALLY DEFERRED,
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
       constraint organism_pub_c1 unique (organism_id,pub_id)
);
create index organism_pub_idx1 on organism_pub (organism_id);
create index organism_pub_idx2 on organism_pub (pub_id);

COMMENT ON TABLE organism_pub IS 'Attribution for organism.';


-- ================================================
-- TABLE: organism_cvterm
-- ================================================

drop table organism_cvterm cascade;
create table organism_cvterm (
       organism_cvterm_id serial not null,
       primary key (organism_cvterm_id),
       organism_id int not null,
       foreign key (organism_id) references organism (organism_id) on delete cascade INITIALLY
DEFERRED,
       cvterm_id int not null,
       foreign key (cvterm_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
       rank int not null default 0,
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
       constraint organism_cvterm_c1 unique(organism_id,cvterm_id,pub_id) 
);
create index organism_cvterm_idx1 on organism_cvterm (organism_id);
create index organism_cvterm_idx2 on organism_cvterm (cvterm_id);

COMMENT ON TABLE organism_cvterm IS 'organism to cvterm associations. Examples: taxonomic name';

COMMENT ON COLUMN organism_cvterm.rank IS 'Property-Value
ordering. Any organism_cvterm can have multiple values for any particular
property type - these are ordered in a list using rank, counting from
zero. For properties that are single-valued rather than multi-valued,
the default 0 value should be used';


-- ================================================
-- TABLE: organism_cvtermprop
-- ================================================

drop table organism_cvtermprop cascade;
create table organism_cvtermprop (
    organism_cvtermprop_id serial not null,
    primary key (organism_cvtermprop_id),
    organism_cvterm_id int not null,
    foreign key (organism_cvterm_id) references organism_cvterm (organism_cvterm_id) on delete cascade,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    value text null,
    rank int not null default 0,
    constraint organism_cvtermprop_c1 unique (organism_cvterm_id,type_id,rank)
);
create index organism_cvtermprop_idx1 on organism_cvtermprop (organism_cvterm_id);
create index organism_cvtermprop_idx2 on organism_cvtermprop (type_id);

COMMENT ON TABLE organism_cvtermprop IS 'Extensible properties for
organism to cvterm associations. Examples: qualifiers';

COMMENT ON COLUMN organism_cvtermprop.type_id IS 'The name of the
property/slot is a cvterm. The meaning of the property is defined in
that cvterm. ';

COMMENT ON COLUMN organism_cvtermprop.value IS 'The value of the
property, represented as text. Numeric values are converted to their
text representation. This is less efficient than using native database
types, but is easier to query.';

COMMENT ON COLUMN organism_cvtermprop.rank IS 'Property-Value
ordering. Any organism_cvterm can have multiple values for any particular
property type - these are ordered in a list using rank, counting from
zero. For properties that are single-valued rather than multi-valued,
the default 0 value should be used';


-- ================================================
-- TABLE: strain
-- ================================================

drop table strain cascade;
create table strain (
	strain_id serial not null,
	primary key (strain_id),
	name varchar(255) null,
	uniquename text not null,
	organism_id int not null,
	foreign key (organism_id) references organism (organism_id) on delete cascade INITIALLY DEFERRED,
	dbxref_id int null,
	foreign key (dbxref_id) references dbxref (dbxref_id) on delete cascade INITIALLY DEFERRED,
	is_obsolete boolean not null default 'false',
	constraint strain_c1 unique (organism_id, uniquename)
);

create index strain_idx1 on strain (uniquename);
create index strain_idx2 on strain (name);

COMMENT ON TABLE strain IS 'A characterized strain of a given organism.';


-- ================================================
-- TABLE: strain_cvterm
-- ================================================

drop table strain_cvterm cascade;
create table strain_cvterm (
       strain_cvterm_id serial not null,
       primary key (strain_cvterm_id),
       strain_id int not null,
       foreign key (strain_id) references strain (strain_id) on delete cascade INITIALLY DEFERRED,
       cvterm_id int not null,
       foreign key (cvterm_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
        pub_id int not null,
       foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
       constraint strain_cvterm_c1 unique(strain_id,cvterm_id,pub_id) 
);
create index strain_cvterm_idx1 on strain_cvterm (strain_id);
create index strain_cvterm_idx2 on strain_cvterm (cvterm_id);

COMMENT ON TABLE strain_cvterm IS 'strain to cvterm associations. Examples: GOid';

-- ================================================
-- TABLE: strain_cvtermprop
-- ================================================

drop table strain_cvtermprop cascade;
create table strain_cvtermprop (
    strain_cvtermprop_id serial not null,
    primary key (strain_cvtermprop_id),
    strain_cvterm_id int not null,
    foreign key (strain_cvterm_id) references strain_cvterm (strain_cvterm_id) on delete cascade,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    value text null,
    rank int not null default 0,
    constraint strain_cvtermprop_c1 unique (strain_cvterm_id,type_id,rank)
);
create index strain_cvtermprop_idx1 on strain_cvtermprop (strain_cvterm_id);
create index strain_cvtermprop_idx2 on strain_cvtermprop (type_id);

COMMENT ON TABLE strain_cvtermprop IS 'Extensible properties for
strain to cvterm associations. Examples: qualifiers';

COMMENT ON COLUMN strain_cvtermprop.type_id IS 'The name of the
property/slot is a cvterm. The meaning of the property is defined in
that cvterm. ';

COMMENT ON COLUMN strain_cvtermprop.value IS 'The value of the
property, represented as text. Numeric values are converted to their
text representation. This is less efficient than using native database
types, but is easier to query.';

COMMENT ON COLUMN strain_cvtermprop.rank IS 'Property-Value
ordering. Any strain_cvterm can have multiple values for any particular
property type - these are ordered in a list using rank, counting from
zero. For properties that are single-valued rather than multi-valued,
the default 0 value should be used';


-- ================================================
-- TABLE: strain_relationship
-- ================================================

drop table strain_relationship cascade;
create table strain_relationship (
	strain_relationship_id serial not null,
	primary key (strain_relationship_id),
	subject_id int not null,
	foreign key (subject_id) references strain (strain_id) on delete cascade INITIALLY DEFERRED,
	object_id int not null,
	foreign key (object_id) references strain (strain_id) on delete cascade INITIALLY DEFERRED,
	type_id int not null,
	foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
	value text null,
	rank int not null default 0,
	constraint strain_relationship_c1 unique (subject_id, object_id, type_id, rank)
);
create index strain_relationship_idx1 on strain_relationship (subject_id);
create index strain_relationship_idx2 on strain_relationship (object_id);

COMMENT ON TABLE strain_relationship IS 'Relationships between strains, eg, progenitor.';


-- ================================================
-- TABLE: strain_relationship_pub
-- ================================================

drop table strain_relationship_pub cascade;
create table strain_relationship_pub (
        strain_relationship_pub_id serial not null,
        primary key (strain_relationship_pub_id),
	strain_relationship_id int not null,
        foreign key (strain_relationship_id) references strain_relationship (strain_relationship_id) on delete cascade INITIALLY DEFERRED,
	pub_id int not null,
	foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
	constraint strain_relationship_pub_c1 unique (strain_relationship_id,pub_id)
);
create index strain_relationship_pub_idx1 on strain_relationship_pub (strain_relationship_id);
create index strain_relationship_pub_idx2 on strain_relationship_pub (pub_id);

COMMENT ON TABLE strain_relationship_pub IS 'Provenance. Attach optional evidence to a strain_relationship in the form of a publication.';


-- ================================================
-- TABLE: strainprop
-- ================================================

drop table strainprop cascade;
create table strainprop (
	strainprop_id serial not null,
	primary key (strainprop_id),
	strain_id int not null,
	foreign key (strain_id) references strain (strain_id) on delete cascade INITIALLY DEFERRED,
	type_id int not null,
	foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
	value text null,
	rank int not null default 0,
	constraint strainprop_c1 unique (strain_id, type_id, rank)
);
create index strainprop_idx1 on strainprop (strain_id);
create index strainprop_idx2 on strainprop (type_id);

COMMENT ON TABLE strainprop IS 'Attributes of a given strain';


-- ================================================
-- TABLE: strainprop_pub
-- ================================================

drop table strainprop_pub cascade;
create table strainprop_pub (
	strainprop_pub_id serial not null,
	primary key (strainprop_pub_id),
	strainprop_id int not null,
	foreign key (strainprop_id) references strainprop (strainprop_id) on delete cascade INITIALLY DEFERRED,
	pub_id int not null,
	foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
	constraint strainprop_pub_c1 unique (strainprop_id,pub_id)
);
create index strainprop_pub_idx1 on strainprop_pub (strainprop_id);
create index strainprop_pub_idx2 on strainprop_pub (pub_id);

COMMENT ON TABLE strainprop_pub IS 'Provenance.  Any strainprop assignment can optionally be supported by a publication.';


-- ================================================
-- TABLE: strain_dbxref
-- ================================================

drop table strain_dbxref cascade;
create table strain_dbxref (
    strain_dbxref_id serial not null,
    primary key (strain_dbxref_id),
    strain_id int not null,
    foreign key (strain_id) references strain (strain_id) on delete cascade INITIALLY DEFERRED,
    dbxref_id int not null,
    foreign key (dbxref_id) references dbxref (dbxref_id) on delete cascade INITIALLY DEFERRED,
    is_current boolean not null default 'true',
    constraint strain_dbxref_c1 unique (strain_id,dbxref_id)
);
create index strain_dbxref_idx1 on strain_dbxref (strain_id);
create index strain_dbxref_idx2 on strain_dbxref (dbxref_id);

COMMENT ON TABLE strain_dbxref IS 'Links a strain to dbxrefs. This is for secondary identifiers; primary identifiers should use strain.dbxref_id.';


-- ================================================
-- TABLE: strain_pub
-- ================================================

drop table strain_pub cascade;
create table strain_pub (
       strain_pub_id serial not null,
       primary key (strain_pub_id),
       strain_id int not null,
       foreign key (strain_id) references strain (strain_id) on delete cascade INITIALLY DEFERRED,
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
       unique(strain_id,pub_id)
);
create index strain_pub_idx1 on strain_pub (strain_id);
create index strain_pub_idx2 on strain_pub (pub_id);

COMMENT ON TABLE strain_pub IS 'Provenance.  Linking table between strains and publications that mention them.';


-- ================================================
-- TABLE: strain_synonym
-- ================================================

drop table strain_synonym cascade;
create table strain_synonym (
	strain_synonym_id serial not null,
	primary key (strain_synonym_id),
	strain_id int not null,
	foreign key (strain_id) references strain (strain_id) on delete cascade INITIALLY DEFERRED,
	synonym_id int not null,
	foreign key (synonym_id) references synonym (synonym_id) on delete cascade INITIALLY DEFERRED,
	pub_id int not null,
	foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
	is_current boolean not null default 'false',
	is_internal boolean not null default 'false',
	constraint strain_synonym_c1 unique (synonym_id,strain_id,pub_id)
);
create index strain_synonym_idx1 on strain_synonym (synonym_id);
create index strain_synonym_idx2 on strain_synonym (strain_id);
create index strain_synonym_idx3 on strain_synonym (pub_id);

COMMENT ON TABLE strain_synonym IS 'Linking table between strain and synonym.';


-- ================================================
-- TABLE: strain_feature
-- ================================================

drop table strain_feature cascade;
create table strain_feature (
	strain_feature_id serial not null,
	primary key (strain_feature_id),
	strain_id int not null,
	foreign key (strain_id) references strain (strain_id) on delete cascade INITIALLY DEFERRED,
	feature_id int not null,
	foreign key (feature_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,
	pub_id int not null,
	foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
	constraint strain_feature_c1 unique (strain_id,feature_id,pub_id)
);
create index strain_feature_idx1 on strain_feature (strain_id);
create index strain_feature_idx2 on strain_feature (feature_id);

COMMENT ON TABLE strain_feature IS 'strain_feature links a strain to features associated with the strain.  Type may 
be, eg, "homozygous" or "heterozygous".';


-- ================================================
-- TABLE: strain_featureprop
-- ================================================

drop table strain_featureprop cascade;
create table strain_featureprop (
	strain_featureprop_id serial not null,
	primary key (strain_featureprop_id),
	strain_feature_id int not null,
	foreign key (strain_feature_id) references strain_feature (strain_feature_id) on delete cascade INITIALLY DEFERRED,
	type_id int not null,
	foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
	value text null,
	rank int not null default 0,
	constraint strain_featureprop_c1 unique (strain_feature_id,type_id,rank)
);
create index strain_featureprop_idx1 on strain_featureprop (strain_feature_id);
create index strain_featureprop_idx2 on strain_featureprop (type_id);

COMMENT ON TABLE strain_featureprop IS 'Attributes of a strain_feature relationship.  Eg, a comment';


-- ================================================
-- TABLE: strain_phenotype
-- ================================================

drop table strain_phenotype cascade;
create table strain_phenotype (
	strain_phenotype_id SERIAL NOT NULL,
	primary key (strain_phenotype_id),
	strain_id INT NOT NULL,
	foreign key (strain_id) references strain (strain_id) on delete cascade,
	phenotype_id INT NOT NULL,
	foreign key (phenotype_id) references phenotype (phenotype_id) on delete cascade,
	pub_id int not null,
	foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
	constraint strain_phenotype_c1 unique (strain_id,phenotype_id,pub_id)
);
create index strain_phenotype_idx1 ON strain_phenotype (strain_id);
create index strain_phenotype_idx2 ON strain_phenotype (phenotype_id);

COMMENT on table strain_phenotype IS 'Links phenotype(s) associated with a given strain.  Types may be, eg, "selected" or "unassigned".';


-- ================================================
-- TABLE: strain_phenotypeprop
-- ================================================

drop table strain_phenotypeprop cascade;
create table strain_phenotypeprop (
        strain_phenotypeprop_id serial not null,
        primary key (strain_phenotypeprop_id),
	strain_phenotype_id int not null,
        foreign key (strain_phenotype_id) references strain_phenotype (strain_phenotype_id) on delete cascade INITIALLY DEFERRED,
	type_id int not null,
	foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
	value text null,
        rank int not null default 0,
        constraint strain_phenotypeprop_c1 unique (strain_phenotype_id,type_id,rank)
);
create index strain_phenotypeprop_idx1 on strain_phenotypeprop (strain_phenotype_id);
create index strain_phenotypeprop_idx2 on strain_phenotypeprop (type_id);

COMMENT ON TABLE strain_phenotypeprop IS 'Attributes of a strain_phenotype relationship.  Eg, a comment';

