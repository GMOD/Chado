-- ================================================
-- TABLE: tableinfo
-- ================================================

create table tableinfo (
       tableinfo_id serial not null,
       primary key (tableinfo_id),
       name varchar(30) not null,
       primary_key_column varchar(30) null,
       is_view int not null default 0,
       view_on_table_id int null,
       superclass_table_id int null,
       is_updateable int not null default 1,
       modification_date date not null default now(),

       unique (name)
);
create index tableinfo_idx1 on tableinfo (name);

COMMENT ON TABLE tableinfo IS NULL;

-- ================================================
-- TABLE: contact
-- ================================================
create table contact (
       contact_id serial not null,
       primary key (contact_id),
       name varchar(30) not null,
       description varchar(255) null,

       unique (name)
);
create index contact_idx1 on contact (name);

COMMENT ON TABLE contact IS NULL;

-- ================================================
-- TABLE: db
-- ================================================

create table db (
       db_id serial not null,
       primary key (db_id),
       name varchar(255) not null,
       contact_id int not null,
       foreign key (contact_id) references contact (contact_id) on delete cascade INITIALLY DEFERRED,
       description varchar(255) null,
       urlprefix varchar(255) null,
       url varchar(255) null,
       unique (name)
);
create index db_idx1 on db (name);

COMMENT ON TABLE db IS NULL;

-- ================================================
-- TABLE: dbxref
-- ================================================

create table dbxref (
       dbxref_id serial not null,
       primary key (dbxref_id),
       db_id int not null,
       foreign key (db_id) references db (db_id) on delete cascade INITIALLY DEFERRED,
       accession varchar(255) not null,
       version varchar(255) not null default '',
       description text,

       unique (db_id, accession, version)
);
create index dbxref_idx1 on dbxref (db_id);
create index dbxref_idx2 on dbxref (accession);
create index dbxref_idx3 on dbxref (version);

COMMENT ON TABLE dbxref IS NULL;

-- ================================================
-- TABLE: project
-- ================================================
create table project (
       project_id serial not null,  
       primary key (project_id),
       name varchar(255) not null,
       description varchar(255) not null,

       unique(name)
);
create index project_idx1 on project (name);

COMMENT ON TABLE project IS NULL;

