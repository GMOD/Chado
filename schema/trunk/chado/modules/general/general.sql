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

-- ================================================
-- TABLE: db
-- ================================================

create table db (
       db_id serial not null,
       primary key (db_id),
       name varchar(255) not null,
       contact_id int not null,
       foreign key (contact_id) references contact (contact_id) on delete cascade,
       description varchar(255) null,
       urlprefix varchar(255) null,
       url varchar(255) null,
       unique (name)
);


-- ================================================
-- TABLE: dbxref
-- ================================================

create table dbxref (
       dbxref_id serial not null,
       primary key (dbxref_id),
       db_id int not null,
       foreign key (db_id) references db (db_id) on delete cascade,
       accession varchar(255) not null,
       version varchar(255) not null default '',
       description text,

       unique (db_id, accession, version)
);

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
