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


