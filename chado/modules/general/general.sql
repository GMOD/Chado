-- ================================================
-- TABLE: dbxref
-- ================================================

create table dbxref (
       dbxref_id serial not null,
       primary key (dbxref_id),
-- dbxref_str is concatenation of dbname:accession[.version]
       dbxrefstr varchar(255) not null,
       dbname varchar(255) not null,
       accession varchar(255) not null,
-- accession_version is unique key
       version varchar(255) not null default '',
       dbxrefdescription text,
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp,

       unique (dbname, accession, version),
       unique (dbxrefstr)
);




