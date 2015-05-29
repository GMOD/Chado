-- $Id: organism.sql,v 1.19 2007/04/01 18:45:41 briano Exp $
-- ==========================================
-- Chado organism module
--
-- ============
-- DEPENDENCIES
-- ============
-- :import cvterm from cv
-- :import dbxref from db
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- ================================================
-- TABLE: organism
-- ================================================

drop table organism cascade;
create table organism (
	organism_id bigserial not null,
	primary key (organism_id),
	abbreviation varchar(255) null,
	genus varchar(255) not null,
	species varchar(255) not null,
	common_name varchar(255) null,
  infraspecific_name varchar(1024) null,
  type_id bigint default null,
  FOREIGN KEY (type_id) REFERENCES cvterm (cvterm_id) ON DELETE CASCADE,
	comment text null,
	constraint organism_c1 unique (genus,species,type_id,infraspecific_name)
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

COMMENT ON COLUMN organism.type_id IS 'A controlled vocabulary term that
specifies the organism rank below species. It is used when an infraspecific 
name is provided.  Ideally, the rank should be a valid ICN name such as 
subspecies, varietas, subvarietas, forma and subforma';

COMMENT ON COLUMN organism.infraspecific_name IS 'The scientific name for any taxon 
below the rank of species.  The rank should be specified using the type_id field
and the name is provided here.';


-- ================================================
-- TABLE: organism_dbxref
-- ================================================

drop table organism_dbxref cascade;
create table organism_dbxref (
    organism_dbxref_id bigserial not null,
    primary key (organism_dbxref_id),
    organism_id bigint not null,
    foreign key (organism_id) references organism (organism_id) on delete cascade INITIALLY DEFERRED,
    dbxref_id bigint not null,
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
    organismprop_id bigserial not null,
    primary key (organismprop_id),
    organism_id bigint not null,
    foreign key (organism_id) references organism (organism_id) on delete cascade INITIALLY DEFERRED,
    type_id bigint not null,
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
    organismprop_pub_id bigserial not null,
    primary key (organismprop_pub_id),
    organismprop_id bigint not null,
    foreign key (organismprop_id) references organismprop (organismprop_id) on delete cascade INITIALLY DEFERRED,
    pub_id bigint not null,
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
       organism_pub_id bigserial not null,
       primary key (organism_pub_id),
       organism_id bigint not null,
       foreign key (organism_id) references organism (organism_id) on delete cascade INITIALLY DEFERRED,
       pub_id bigint not null,
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
       organism_cvterm_id bigserial not null,
       primary key (organism_cvterm_id),
       organism_id bigint not null,
       foreign key (organism_id) references organism (organism_id) on delete cascade INITIALLY
DEFERRED,
       cvterm_id bigint not null,
       foreign key (cvterm_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
       rank int not null default 0,
       pub_id bigint not null,
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
    organism_cvtermprop_id bigserial not null,
    primary key (organism_cvtermprop_id),
    organism_cvterm_id bigint not null,
    foreign key (organism_cvterm_id) references organism_cvterm (organism_cvterm_id) on delete cascade,
    type_id bigint not null,
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
-- TABLE: organism_relationship
-- ================================================

CREATE TABLE organism_relationship (
    organism_relationship_id bigserial primary key NOT NULL,
    subject_id bigint NOT NULL,
    object_id bigint NOT NULL,
    type_id bigint NOT NULL,
    rank integer DEFAULT 0 NOT NULL,
    CONSTRAINT organism_relationship_c1 UNIQUE (subject_id, object_id, type_id, rank),
    FOREIGN KEY (object_id) REFERENCES organism(organism_id) ON DELETE CASCADE,
    FOREIGN KEY (subject_id) REFERENCES organism(organism_id) ON DELETE CASCADE,
    FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE    
);

CREATE INDEX organism_relationship_idx1 ON organism_relationship USING btree (subject_id);
CREATE INDEX organism_relationship_idx2 ON organism_relationship USING btree (object_id);
CREATE INDEX organism_relationship_idx3 ON organism_relationship USING btree (type_id);

COMMENT ON TABLE organism_relationship IS 'Specifies relationships between organisms 
that are not taxonomic. For example, in breeding, relationships such as 
"sterile_with", "incompatible_with", or "fertile_with" would be appropriate. Taxonomic
relatinoships should be housed in the phylogeny tables.';


