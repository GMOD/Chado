-- ================================================
-- TABLE: dbxref
-- ================================================

create table dbxref (
       dbxref_id serial not null,
       primary key (dbxref_id),
       dbname varchar(255) not null,
       accession varchar(255) not null,
       version varchar(255) not null default '',
       dbxrefdescription text,

       unique (dbname, accession, version)
);

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
-- TABLE: projectinfo
-- ================================================
create table projectinfo (
       projectinfo_id serial not null,
       primary key (projectinfo_id),
       name varchar(255) not null,
      description varchar(255) not null
);
