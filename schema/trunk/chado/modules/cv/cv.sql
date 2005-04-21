
create table cv (
    cv_id serial not null,
    primary key (cv_id),
    name varchar(255) not null,
   definition text,
   constraint cv_c1 unique (name)
);

COMMENT ON TABLE cv IS 'A controlled vocabulary or ontology. A cv is composed of cvterms (aka terms, classes, concepts, frames) and the relationships between them';

COMMENT ON COLUMN cv.name IS 'The name of the ontology. This corresponds to the obo-format -namespace-. cv names are unique';

COMMENT ON COLUMN cv.definition IS 'A description of the criteria for membership of this ontology';


create table cvterm (
    cvterm_id serial not null,
    primary key (cvterm_id),
    cv_id int not null,
    foreign key (cv_id) references cv (cv_id) on delete cascade INITIALLY DEFERRED,
    name varchar(1024) not null,
    definition text,
    dbxref_id int not null,
    foreign key (dbxref_id) references dbxref (dbxref_id) on delete set null INITIALLY DEFERRED,
    is_obsolete int not null default 0,
    is_relationshiptype int not null default 0,
    constraint cvterm_c1 unique (name,cv_id,is_obsolete),
    constraint cvterm_c2 unique (dbxref_id)
);
COMMENT ON TABLE cvterm IS
 'A term, class or concept within an ontology or controlled vocabulary.
  Also used for relationship types. A cvterm can also be thought of
  as a node in a graph';
COMMENT ON COLUMN cvterm.cv_id IS
 'The cv/ontology/namespace to which this cvterm belongs';
COMMENT ON COLUMN cvterm.name IS
 'A concise human-readable name describing the meaning of the cvterm';
COMMENT ON COLUMN cvterm.definition IS
 'A human-readable text definition';
COMMENT ON COLUMN cvterm.dbxref_id IS
 'Primary dbxref - The unique global OBO identifier for this cvterm.
  Note that a cvterm may  have multiple secondary dbxrefs - see also
  table: cvterm_dbxref';
COMMENT ON COLUMN cvterm.is_obsolete IS
 'Boolean 0=false,1=true; see GO documentation for details of obsoletion.
  note that two terms with different primary dbxrefs may exist if one
  is obsolete';
COMMENT ON COLUMN cvterm.is_relationshiptype IS
 'Boolean 0=false,1=true
  Relationship types (also known as Typedefs in OBO format, or as
  properties or slots) form a cv/ontology in themselves. We use this
  flag to indicate whether this cvterm is an actual term/concept or
  a relationship type';
COMMENT ON INDEX cvterm_c1 IS 
 'the OBO identifier is globally unique';
COMMENT ON INDEX cvterm_c2 IS 
 'a name can mean different things in different contexts;
  for example "chromosome" in SO and GO. A name should be unique
  within an ontology/cv. A name may exist twice in a cv, in both
  obsolete and non-obsolete forms - these will be for different
  cvterms with different OBO identifiers; so GO documentation for
  more details on obsoletion';

create index cvterm_idx1 on cvterm (cv_id);
create index cvterm_idx2 on cvterm (name);
create index cvterm_idx3 on cvterm (dbxref_id);


create table cvterm_relationship (
    cvterm_relationship_id serial not null,
    primary key (cvterm_relationship_id),
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    subject_id int not null,
    foreign key (subject_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    object_id int not null,
    foreign key (object_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    constraint cvterm_relationship_c1 unique (subject_id,object_id,type_id)
);
COMMENT ON TABLE cvterm_relationship IS
 'A relationship linking two cvterms. A relationship can be thought of
  as an edge in a graph, or as a natural language statement about
  two cvterms. The statement is of the form SUBJECT PREDICATE OBJECT;
  for example "wing part_of body"';

COMMENT ON COLUMN cvterm_relationship.subject_id IS 'the subject of the subj-predicate-obj sentence. In a DAG, this corresponds to the child node';

COMMENT ON COLUMN cvterm_relationship.object_id IS 'the object of the subj-predicate-obj sentence. In a DAG, this corresponds to the parent node';

COMMENT ON COLUMN cvterm_relationship.type_id IS 'relationship type between subject and object. This is a cvterm, typically from the OBO relationship ontology, although other relationship types are allowed';

create index cvterm_relationship_idx1 on cvterm_relationship (type_id);
create index cvterm_relationship_idx2 on cvterm_relationship (subject_id);
create index cvterm_relationship_idx3 on cvterm_relationship (object_id);


create table cvtermpath (
    cvtermpath_id serial not null,
    primary key (cvtermpath_id),
    type_id int,
    foreign key (type_id) references cvterm (cvterm_id) on delete set null INITIALLY DEFERRED,
    subject_id int not null,
    foreign key (subject_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    object_id int not null,
    foreign key (object_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    cv_id int not null,
    foreign key (cv_id) references cv (cv_id) on delete cascade INITIALLY DEFERRED,
    pathdistance int,
    constraint cvtermpath_c1 unique (subject_id,object_id,type_id,pathdistance)
);

COMMENT ON TABLE cvtermpath IS 'The reflexive transitive closure of the cvterm_relationship relation. For a full discussion, see the file populating-cvtermpath.txt in this directory';

COMMENT ON COLUMN cvtermpath.type_id IS 'The relationship type that this is a closure over. If null, then this is a closure over ALL relationship types. If non-null, then this references a relationship cvterm - note that the closure will apply to both this relationship AND the OBO_REL:is_a (subclass) relationship';

COMMENT ON COLUMN cvtermpath.cv_id IS 'Closures will mostly be within one cv. If the closure of a relationship traverses a cv, then this refers to the cv of the object_id cvterm';

COMMENT ON COLUMN cvtermpath.pathdistance IS 'The number of steps required to get from the subject cvterm to the object cvterm, counting from zero (reflexive relationship)';

create index cvtermpath_idx1 on cvtermpath (type_id);
create index cvtermpath_idx2 on cvtermpath (subject_id);
create index cvtermpath_idx3 on cvtermpath (object_id);
create index cvtermpath_idx4 on cvtermpath (cv_id);


create table cvtermsynonym (
    cvtermsynonym_id serial not null,
    primary key (cvtermsynonym_id),
    cvterm_id int not null,
    foreign key (cvterm_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    synonym varchar(1024) not null,
    type_id int,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade  INITIALLY DEFERRED,
    constraint cvtermsynonym_c1 unique (cvterm_id,synonym)
);

COMMENT ON TABLE cvtermsynonym IS 'A cvterm actually represents a distinct class or concept. A concept can be refered to by different phrases or names. In addition to the primary name (cvterm.name) there can be a number of alternative aliases or synonyms. For example, -T cell- as a synonym for -T lymphocyte-';

COMMENT ON COLUMN cvtermsynonym.type_id IS 'A synonym can be exact, narrow or borader than';

create index cvtermsynonym_idx1 on cvtermsynonym (cvterm_id);


create table cvterm_dbxref (
    cvterm_dbxref_id serial not null,
    primary key (cvterm_dbxref_id),
    cvterm_id int not null,
    foreign key (cvterm_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    dbxref_id int not null,
    foreign key (dbxref_id) references dbxref (dbxref_id) on delete cascade INITIALLY DEFERRED,
    is_for_definition int not null default 0,
    constraint cvterm_dbxref_c1 unique (cvterm_id,dbxref_id)
);

COMMENT ON TABLE cvterm_dbxref IS 'In addition to the primary identifier (cvterm.dbxref_id) a cvterm can have zero or more secondary identifiers, which may be in external databases';

COMMENT ON COLUMN cvterm_dbxref.is_for_definition IS 'A cvterm.definition should be supported by one or more references. If this column is true, the dbxref is not for a term in an external db - it is a dbxref for provenance information for the definition';

create index cvterm_dbxref_idx1 on cvterm_dbxref (cvterm_id);
create index cvterm_dbxref_idx2 on cvterm_dbxref (dbxref_id);


create table cvtermprop ( 
    cvtermprop_id serial not null, 
    primary key (cvtermprop_id), 
    cvterm_id int not null, 
    foreign key (cvterm_id) references cvterm (cvterm_id) on delete cascade, 
    type_id int not null, 
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade, 
    value text not null default '', 
    rank int not null default 0,

    unique(cvterm_id, type_id, value, rank) 
);

COMMENT ON TABLE cvtermprop IS 'Additional extensible properties can be attached to a cvterm using this table. Corresponds to -AnnotationProperty- in W3C OWL format';

COMMENT ON COLUMN cvtermprop.type_id IS 'The name of the property/slot is a cvterm. The meaning of the property is defined in that cvterm';

COMMENT ON COLUMN cvtermprop.value IS 'The value of the property, represented as text. Numeric values are converted to their text representation';

COMMENT ON COLUMN cvtermprop.rank IS 'Property-Value ordering. Any
cvterm can have multiple values for any particular property type -
these are ordered in a list using rank, counting from zero. For
properties that are single-valued rather than multi-valued, the
default 0 value should be used';

create index cvtermprop_idx1 on cvtermprop (cvterm_id);
create index cvtermprop_idx2 on cvtermprop (type_id);


create table dbxrefprop (
    dbxrefprop_id serial not null,
    primary key (dbxrefprop_id),
    dbxref_id int not null,
    foreign key (dbxref_id) references dbxref (dbxref_id) INITIALLY DEFERRED,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) INITIALLY DEFERRED,
    value text not null default '',
    rank int not null default 0,
    constraint dbxrefprop_c1 unique (dbxref_id,type_id,rank)
);

COMMENT ON TABLE dbxrefprop IS 'Metadata about a dbxref. Note that this is not defined in the dbxref module, as it depends on the cvterm table. This table has a structure analagous to cvtermprop';

create index dbxrefprop_idx1 on dbxrefprop (dbxref_id);
create index dbxrefprop_idx2 on dbxrefprop (type_id);
