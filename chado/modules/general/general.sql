-- ================================================
-- TABLE: db
-- ================================================

create table db (
       db_id varchar(255) not null,
       primary key (db_id),
       name varchar(255) not null,
       description varchar(255) null,
       url varchar(255) null,
       unique (name)
);


-- ================================================
-- TABLE: dbxref
-- ================================================

create table dbxref (
       dbxref_id serial not null,
       primary key (dbxref_id),
       dbname varchar(255) not null,
       foreign key (dbname) references db (db_id),
       accession varchar(255) not null,
       version varchar(255) not null default '',
       dbxrefdescription text,

       unique (dbname, accession, version)
);

-- ================================================
-- TABLE: dbxrefprop
-- ================================================

create table dbxrefprop (
       dbxrefprop_id serial not null,
       primary key (dbxrefprop_id),
       dbxref_id int not null,
       foreign key (dbxref_id) references dbxref (dbxref_id),
       pkey_id int not null,
       foreign key (pkey_id) references cvterm (cvterm_id),
       pval text not null default '',
       prank int not null default 0,

       unique(dbxref_id, pkey_id, pval, prank)
);
create index dbxrefprop_idx1 on dbxrefprop (dbxref_id);
create index dbxrefprop_idx2 on dbxrefprop (pkey_id);

-- ================================================
-- TABLE: tableinfo
-- ================================================

create table tableinfo (
       tableinfo_id serial not null,
       primary key (tableinfo_id),
       name varchar(30) not null,
       table_type varchar(40) not null,
       primary_key_column varchar(30) null,
       database_id int not null,
       is_versioned int not null,
       is_view int not null,
       view_on_table_id int null,
       superclass_table_id int null,
       is_updateable int not null,
       modification_date date not null
);

-- ================================================
-- TABLE: project
-- ================================================
create table project (
       project_id serial not null,
       primary key (projectinfo_id),
       name varchar(255) not null,
      description varchar(255) not null
);
