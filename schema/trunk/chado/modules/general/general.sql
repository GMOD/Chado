-- ================================================
-- TABLE: dbxref
-- ================================================

create table dbxref (
       dbxref_id serial not null,
       primary key (dbxref_id),
       dbname varchar(85) not null,
       accession varchar(85) not null,
       version varchar(85) not null default '',
       dbxrefdescription text,

       unique (dbname, accession, version)
);

-- ================================================
-- TABLE: tableinfo
-- ================================================

create table tableinfo (
       table_id serial not null,
       primary key (table_id),
       name varchar(30) not null,
       table_type varchar(40) not null,
       primary_key_column varchar(30) null,
       database_id int(5) not null,
       is_versioned int(1) not null,
       is_view int(1) not null,
       view_on_table_id int(5) null,
       superclass_table_id int(5) null,
       is_updateable int(1) not null,
       modification_date date not null
);
