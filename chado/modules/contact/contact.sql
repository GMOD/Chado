-- ================================================
-- TABLE: contact
-- ================================================
create table contact (
    contact_id serial not null,
    primary key (contact_id),
    type_id int null,
    foreign key (type_id) references cvterm (cvterm_id),
    name varchar(255) not null,
    description varchar(255) null,
    constraint contact_c1 unique (name)
);
COMMENT ON TABLE contact IS 'model persons, institutes, groups, organizations, etc';
COMMENT ON COLUMN contact.type_id IS 'what type of contact is this?  e.g. "person", "lab", etc.';

-- ================================================
-- TABLE: contact_relationship
-- ================================================
create table contact_relationship (
    contact_relationship_id serial not null,
    primary key (contact_relationship_id),
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    subject_id int not null,
    foreign key (subject_id) references contact (contact_id) on delete cascade INITIALLY DEFERRED,
    object_id int not null,
    foreign key (object_id) references contact (contact_id) on delete cascade INITIALLY DEFERRED,
    constraint contact_relationship_c1 unique (subject_id,object_id,type_id)
);
create index contact_relationship_idx1 on contact_relationship (type_id);
create index contact_relationship_idx2 on contact_relationship (subject_id);
create index contact_relationship_idx3 on contact_relationship (object_id);

COMMENT ON TABLE contact_relationship IS 'model relationships between contacts';
COMMENT ON COLUMN contact_relationship.subject_id IS 'the subject of the subj-predicate-obj sentence. In a DAG, this corresponds to the child node';
COMMENT ON COLUMN contact_relationship.object_id IS 'the object of the subj-predicate-obj sentence. In a DAG, this corresponds to the parent node';
COMMENT ON COLUMN contact_relationship.type_id IS 'relationship type between subject and object. This is a cvterm, typically from the OBO relationship ontology, although other relationship types are allowed';

