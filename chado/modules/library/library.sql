-- $Id: library.sql,v 1.10 2008-03-25 16:00:43 emmert Exp $
-- =================================================================
-- Dependencies:
--
-- :import feature from sequence
-- :import synonym from sequence
-- :import cvterm from cv
-- :import pub from pub
-- :import organism from organism
-- :import expression from expression
-- :import dbxref from db
-- :import contact from contact
-- =================================================================

-- ================================================
-- TABLE: library
-- ================================================

create table library (
    library_id bigserial not null,
    primary key (library_id),
    organism_id bigint not null,
    foreign key (organism_id) references organism (organism_id),
    name varchar(255),
    uniquename text not null,
    type_id bigint not null,
    foreign key (type_id) references cvterm (cvterm_id),
    is_obsolete int not null default 0,
    timeaccessioned timestamp not null default current_timestamp,
    timelastmodified timestamp not null default current_timestamp,
    constraint library_c1 unique (organism_id,uniquename,type_id)
);
create index library_name_ind1 on library(name);
create index library_idx1 on library (organism_id);
create index library_idx2 on library (type_id);
create index library_idx3 on library (uniquename);

COMMENT ON COLUMN library.type_id IS 'The type_id foreign key links to a controlled vocabulary of library types. Examples of this would be: "cDNA_library" or "genomic_library"';


-- ================================================
-- TABLE: library_synonym
-- ================================================

create table library_synonym (
    library_synonym_id bigserial not null,
    primary key (library_synonym_id),
    synonym_id bigint not null,
    foreign key (synonym_id) references synonym (synonym_id) on delete cascade INITIALLY DEFERRED,
    library_id bigint not null,
    foreign key (library_id) references library (library_id) on delete cascade INITIALLY DEFERRED,
    pub_id bigint not null,
    foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
    is_current boolean not null default 'true',
    is_internal boolean not null default 'false',
    constraint library_synonym_c1 unique (synonym_id,library_id,pub_id)
);
create index library_synonym_idx1 on library_synonym (synonym_id);
create index library_synonym_idx2 on library_synonym (library_id);
create index library_synonym_idx3 on library_synonym (pub_id);

COMMENT ON TABLE library_synonym IS 'Linking table between library and synonym.';

COMMENT ON COLUMN library_synonym.is_current IS 'The is_current bit indicates whether the linked synonym is the current -official- symbol for the linked library.';

COMMENT ON COLUMN library_synonym.pub_id IS 'The pub_id link is for
relating the usage of a given synonym to the publication in which it was used.';

COMMENT ON COLUMN library_synonym.is_internal IS 'Typically a synonym
exists so that somebody querying the database with an obsolete name
can find the object they are looking for under its current name.  If
the synonym has been used publicly and deliberately (e.g. in a paper), it my also be listed in reports as a synonym.   If the synonym was not used deliberately (e.g., there was a typo which went public), then the is_internal bit may be set to "true" so that it is known that the synonym is "internal" and should be queryable but should not be listed in reports as a valid synonym.';


-- ================================================
-- TABLE: library_pub
-- ================================================

create table library_pub (
    library_pub_id bigserial not null,
    primary key (library_pub_id),
    library_id bigint not null,
    foreign key (library_id) references library (library_id) on delete cascade INITIALLY DEFERRED,
    pub_id bigint not null,
    foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
    constraint library_pub_c1 unique (library_id,pub_id)
);
create index library_pub_idx1 on library_pub (library_id);
create index library_pub_idx2 on library_pub (pub_id);

COMMENT ON TABLE library_pub IS 'Attribution for a library.';


-- ================================================
-- TABLE: libraryprop
-- ================================================

create table libraryprop (
    libraryprop_id bigserial not null,
    primary key (libraryprop_id),
    library_id bigint not null,
    foreign key (library_id) references library (library_id) on delete cascade INITIALLY DEFERRED,
    type_id bigint not null,
    foreign key (type_id) references cvterm (cvterm_id),
    value text null,
    rank int not null default 0,
    cvalue_id bigint,
  FOREIGN KEY (cvalue_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL,
    constraint libraryprop_c1 unique (library_id,type_id,rank)
);
create index libraryprop_idx1 on libraryprop (library_id);
create index libraryprop_idx2 on libraryprop (type_id);
create index libraryprop_idx3 on libraryprop (cvalue_id);

COMMENT ON TABLE libraryprop IS 'Tag-value properties - follows standard chado model.';
COMMENT ON COLUMN libraryprop.cvalue_id IS 'The value of the property if that value should be the name of a controlled vocabulary term.  It is preferred that a property either use the value or cvalue_id column but not both.  For example, if the property type is "color" then the cvalue_id could be a term named "green".';


-- ================================================
-- TABLE: libraryprop_pub
-- ================================================

create table libraryprop_pub (
    libraryprop_pub_id bigserial not null,
    primary key (libraryprop_pub_id),
    libraryprop_id bigint not null,
    foreign key (libraryprop_id) references libraryprop (libraryprop_id) on delete cascade INITIALLY DEFERRED,
    pub_id bigint not null,
    foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
    constraint libraryprop_pub_c1 unique (libraryprop_id,pub_id)
);
create index libraryprop_pub_idx1 on libraryprop_pub (libraryprop_id);
create index libraryprop_pub_idx2 on libraryprop_pub (pub_id);

COMMENT ON TABLE libraryprop_pub IS 'Attribution for libraryprop.';


-- ================================================
-- TABLE: library_cvterm
-- ================================================

create table library_cvterm (
    library_cvterm_id bigserial not null,
    primary key (library_cvterm_id),
    library_id bigint not null,
    foreign key (library_id) references library (library_id) on delete cascade INITIALLY DEFERRED,
    cvterm_id bigint not null,
    foreign key (cvterm_id) references cvterm (cvterm_id),
    pub_id bigint not null,
    foreign key (pub_id) references pub (pub_id),
    constraint library_cvterm_c1 unique (library_id,cvterm_id,pub_id)
);
create index library_cvterm_idx1 on library_cvterm (library_id);
create index library_cvterm_idx2 on library_cvterm (cvterm_id);
create index library_cvterm_idx3 on library_cvterm (pub_id);

COMMENT ON TABLE library_cvterm IS 'The table library_cvterm links a library to controlled vocabularies which describe the library.  For instance, there might be a link to the anatomy cv for "head" or "testes" for a head or testes library.';


-- ================================================
-- TABLE: library_feature
-- ================================================

create table library_feature (
    library_feature_id bigserial not null,
    primary key (library_feature_id),
    library_id bigint not null,
    foreign key (library_id) references library (library_id) on delete cascade INITIALLY DEFERRED,
    feature_id bigint not null,
    foreign key (feature_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,
    constraint library_feature_c1 unique (library_id,feature_id)
);
create index library_feature_idx1 on library_feature (library_id);
create index library_feature_idx2 on library_feature (feature_id);

COMMENT ON TABLE library_feature IS 'library_feature links a library to the clones which are contained in the library.  Examples of such linked features might be "cDNA_clone" or  "genomic_clone".';


-- ================================================
-- TABLE: library_dbxref
-- ================================================

create table library_dbxref (
    library_dbxref_id bigserial not null,
    primary key (library_dbxref_id),
    library_id bigint not null,
    foreign key (library_id) references library (library_id) on delete cascade INITIALLY DEFERRED,
    dbxref_id bigint not null,
    foreign key (dbxref_id) references dbxref (dbxref_id) on delete cascade INITIALLY DEFERRED,
    is_current boolean not null default 'true',
    constraint library_dbxref_c1 unique (library_id,dbxref_id)
);
create index library_dbxref_idx1 on library_dbxref (library_id);
create index library_dbxref_idx2 on library_dbxref (dbxref_id);

COMMENT ON TABLE library_dbxref IS 'Links a library to dbxrefs.';


-- ================================================
-- TABLE: library_expression
-- ================================================

create table library_expression (
    library_expression_id bigserial not null,
    primary key (library_expression_id),
    library_id bigint not null,
    foreign key (library_id) references library (library_id) on delete cascade INITIALLY DEFERRED,
    expression_id bigint not null,
    foreign key (expression_id) references expression (expression_id) on delete cascade INITIALLY DEFERRED,
    pub_id bigint not null,
    foreign key (pub_id) references pub (pub_id),
    constraint library_expression_c1 unique (library_id,expression_id)
);
create index library_expression_idx1 on library_expression (library_id);
create index library_expression_idx2 on library_expression (expression_id);
create index library_expression_idx3 on library_expression (pub_id);

COMMENT ON TABLE library_expression IS 'Links a library to expression statements.';


-- ================================================
-- TABLE: library_expressionprop
-- ================================================

create table library_expressionprop (
    library_expressionprop_id bigserial not null,
    primary key (library_expressionprop_id),
    library_expression_id bigint not null,
    foreign key (library_expression_id) references library_expression (library_expression_id) on delete cascade INITIALLY DEFERRED,
    type_id bigint not null,
    foreign key (type_id) references cvterm (cvterm_id),
    value text null,
    rank int not null default 0,
    cvalue_id bigint,
  FOREIGN KEY (cvalue_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL,
    constraint library_expressionprop_c1 unique (library_expression_id,type_id,rank)
);
create index library_expressionprop_idx1 on library_expressionprop (library_expression_id);
create index library_expressionprop_idx2 on library_expressionprop (type_id);
create index library_expressionprop_idx3 on library_expressionprop (cvalue_id);

COMMENT ON TABLE library_expressionprop IS 'Attributes of a library_expression relationship.';
COMMENT ON COLUMN library_expressionprop.cvalue_id IS 'The value of the property if that value should be the name of a controlled vocabulary term.  It is preferred that a property either use the value or cvalue_id column but not both.  For example, if the property type is "color" then the cvalue_id could be a term named "green".';


-- ================================================
-- TABLE: library_featureprop
-- ================================================

create table library_featureprop (
    library_featureprop_id bigserial not null,
    primary key (library_featureprop_id),
    library_feature_id bigint not null,
    foreign key (library_feature_id) references library_feature (library_feature_id) on delete cascade INITIALLY DEFERRED,
    type_id bigint not null,
    foreign key (type_id) references cvterm (cvterm_id),
    value text null,
    rank int not null default 0,
     cvalue_id bigint,
  FOREIGN KEY (cvalue_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL,
    constraint library_featureprop_c1 unique (library_feature_id,type_id,rank)
);
create index library_featureprop_idx1 on library_featureprop (library_feature_id);
create index library_featureprop_idx2 on library_featureprop (type_id);
create index library_featureprop_idx3 on library_featureprop (cvalue_id);

COMMENT ON TABLE library_featureprop IS 'Attributes of a library_feature relationship.';
COMMENT ON COLUMN library_featureprop.cvalue_id IS 'The value of the property if that value should be the name of a controlled vocabulary term.  It is preferred that a property either use the value or cvalue_id column but not both.  For example, if the property type is "color" then the cvalue_id could be a term named "green".';

-- ================================================
-- TABLE: library_relationship
-- ================================================

create table library_relationship (
    library_relationship_id bigserial not null,
    primary key (library_relationship_id),
    subject_id bigint not null,
    foreign key (subject_id) references library (library_id) on delete cascade INITIALLY DEFERRED,
    object_id bigint not null,
    foreign key (object_id) references library (library_id) on delete cascade INITIALLY DEFERRED,
    type_id bigint not null,
    foreign key (type_id) references cvterm (cvterm_id),
    constraint library_relationship_c1 unique (subject_id,object_id,type_id)
);
create index library_relationship_idx1 on library_relationship (subject_id);
create index library_relationship_idx2 on library_relationship (object_id);
create index library_relationship_idx3 on library_relationship (type_id);

COMMENT ON TABLE library_relationship IS 'Relationships between libraries.';


-- ================================================
-- TABLE: library_relationship_pub
-- ================================================

create table library_relationship_pub (
    library_relationship_pub_id bigserial not null,
    primary key (library_relationship_pub_id),
    library_relationship_id bigint not null,
    foreign key (library_relationship_id) references library_relationship (library_relationship_id) on delete cascade INITIALLY DEFERRED,
    pub_id bigint not null,
    foreign key (pub_id) references pub (pub_id),
    constraint library_relationship_pub_c1 unique (library_relationship_id,pub_id)
);
create index library_relationship_pub_idx1 on library_relationship_pub (library_relationship_id);
create index library_relationship_pub_idx2 on library_relationship_pub (pub_id);

COMMENT ON TABLE library_relationship_pub IS 'Provenance of library_relationship.';


-- ================================================
-- TABLE: library_contact
-- ================================================

CREATE TABLE library_contact (
    library_contact_id bigserial primary key NOT NULL,
    library_id bigint NOT NULL,
    contact_id bigint NOT NULL,
    CONSTRAINT library_contact_c1 UNIQUE (library_id, contact_id),
    FOREIGN KEY (library_id) REFERENCES library(library_id) ON DELETE CASCADE,
    FOREIGN KEY (contact_id) REFERENCES contact(contact_id) ON DELETE CASCADE
);

CREATE INDEX library_contact_idx1 ON library USING btree (library_id);
CREATE INDEX library_contact_idx2 ON contact USING btree (contact_id);

COMMENT ON TABLE library_contact IS 'Links contact(s) with a library.  Used to indicate a particular person or organization responsible for creation of or that can provide more information on a particular library.';

