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


