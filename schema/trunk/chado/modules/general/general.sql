--
-- should this be in pub?
--
-- ================================================
-- TABLE: contact
-- ================================================
create table contact (
       contact_id serial not null,
       primary key (contact_id),
-- fields to be added after discussion
       description varchar(255) null
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


