-- $Id: contact.sql,v 1.5 2007-02-25 17:00:17 briano Exp $
-- ==========================================
-- Chado contact module
--
-- =================================================================
-- Dependencies:
--
-- :import cvterm from cv
-- =================================================================

-- ================================================
-- TABLE: contact
-- ================================================

CREATE TABLE contact (
    contact_id bigserial not null,
    primary key (contact_id),
    type_id bigint null,
    foreign key (type_id) references cvterm (cvterm_id),
    name varchar(255) not null,
    description varchar(255) null,
    constraint contact_c1 unique (name)
);

COMMENT ON TABLE contact IS 'Model persons, institutes, groups, organizations, etc.';
COMMENT ON COLUMN contact.type_id IS 'What type of contact is this?  E.g. "person", "lab".';

-- ================================================
-- TABLE: contactprop
-- ================================================
CREATE TABLE contactprop (
    contactprop_id bigserial primary key not null,
    contact_id bigint NOT NULL,
    type_id bigint NOT NULL,
    value text,
    rank integer DEFAULT 0 NOT NULL,
    CONSTRAINT contactprop_c1 UNIQUE (contact_id, type_id, rank),    
    FOREIGN KEY (contact_id) REFERENCES contact(contact_id) ON DELETE CASCADE,
    FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE
);

CREATE INDEX contactprop_idx1 ON contactprop USING btree (contact_id);
CREATE INDEX contactprop_idx2 ON contactprop USING btree (type_id);

COMMENT ON TABLE contactprop IS 'A contact can have any number of slot-value property 
tags attached to it. This is an alternative to hardcoding a list of columns in the 
relational schema, and is completely extensible.';


-- ================================================
-- TABLE: contact_relationship
-- ================================================

create table contact_relationship (
    contact_relationship_id bigserial not null,
    primary key (contact_relationship_id),
    type_id bigint not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    subject_id bigint not null,
    foreign key (subject_id) references contact (contact_id) on delete cascade INITIALLY DEFERRED,
    object_id bigint not null,
    foreign key (object_id) references contact (contact_id) on delete cascade INITIALLY DEFERRED,
    constraint contact_relationship_c1 unique (subject_id,object_id,type_id)
);
create index contact_relationship_idx1 on contact_relationship (type_id);
create index contact_relationship_idx2 on contact_relationship (subject_id);
create index contact_relationship_idx3 on contact_relationship (object_id);

COMMENT ON TABLE contact_relationship IS 'Model relationships between contacts';
COMMENT ON COLUMN contact_relationship.subject_id IS 'The subject of the subj-predicate-obj sentence. In a DAG, this corresponds to the child node.';
COMMENT ON COLUMN contact_relationship.object_id IS 'The object of the subj-predicate-obj sentence. In a DAG, this corresponds to the parent node.';
COMMENT ON COLUMN contact_relationship.type_id IS 'Relationship type between subject and object. This is a cvterm, typically from the OBO relationship ontology, although other relationship types are allowed.';
