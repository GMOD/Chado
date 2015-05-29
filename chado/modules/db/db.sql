-- ================================================
-- TABLE: db
-- ================================================

create table db (
    db_id bigserial not null,
    primary key (db_id),
    name varchar(255) not null,
--    contact_id bigint,
--    foreign key (contact_id) references contact (contact_id) on delete cascade INITIALLY DEFERRED,
    description varchar(255) null,
    urlprefix varchar(255) null,
    url varchar(255) null,
    constraint db_c1 unique (name)
);

COMMENT ON TABLE db IS 'A database authority. Typical databases in
bioinformatics are FlyBase, GO, UniProt, NCBI, MGI, etc. The authority
is generally known by this shortened form, which is unique within the
bioinformatics and biomedical realm.  To Do - add support for URIs,
URNs (e.g. LSIDs). We can do this by treating the URL as a URI -
however, some applications may expect this to be resolvable - to be
decided.';

-- ================================================
-- TABLE: dbxref
-- ================================================

create table dbxref (
    dbxref_id bigserial not null,
    primary key (dbxref_id),
    db_id bigint not null,
    foreign key (db_id) references db (db_id) on delete cascade INITIALLY DEFERRED,
    accession varchar(1024) not null,
    version varchar(255) not null default '',
    description text,
    constraint dbxref_c1 unique (db_id,accession,version)
);
create index dbxref_idx1 on dbxref (db_id);
create index dbxref_idx2 on dbxref (accession);
create index dbxref_idx3 on dbxref (version);

COMMENT ON TABLE dbxref IS 'A unique, global, public, stable identifier. Not necessarily an external reference - can reference data items inside the particular chado instance being used. Typically a row in a table can be uniquely identified with a primary identifier (called dbxref_id); a table may also have secondary identifiers (in a linking table <T>_dbxref). A dbxref is generally written as <DB>:<ACCESSION> or as <DB>:<ACCESSION>:<VERSION>.';

COMMENT ON COLUMN dbxref.accession IS 'The local part of the identifier. Guaranteed by the db authority to be unique for that db.';


-- ================================================
-- TABLE: dbprop
-- ================================================

create table dbprop (
  dbprop_id bigserial not null,
  primary key (dbprop_id),
  db_id bigint not null,
  type_id bigint not null,
  value text null,
  rank int not null default 0,
  foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
  foreign key (db_id) references db (db_id) on delete cascade INITIALLY DEFERRED,
  constraint dbprop_c1 unique (db_id,type_id,rank)
);
create index dbprop_idx1 on dbprop (db_id);
create index dbprop_idx2 on dbprop (type_id);

COMMENT ON TABLE dbprop IS 'An external database can have any number of
slot-value property tags attached to it. This is an alternative to
hardcoding a list of columns in the relational schema, and is
completely extensible. There is a unique constraint, dbprop_c1, for
the combination of db_id, rank, and type_id. Multivalued property-value pairs must be differentiated by rank.';
