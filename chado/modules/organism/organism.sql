-- ================================================
-- TABLE: organism
-- ================================================

create table organism (
	organism_id serial not null,
	primary key (organism_id),
	abbrev varchar(255) null,
	genus varchar(255) not null,
	species varchar(255) not null,
	common_name varchar(255) null,
	comment text null,

	unique(genus, species)
);
-- Compared to mol5..Species, organism table lacks "approved char(1) null".  
-- We need to work w/ Aubrey & Michael to ensure that we don't need this in 
-- future [dave]
--
-- in response: this is very specific to a limited use case I think;
-- if it's really necessary we can have an organismprop table
-- for adding internal project specific data
-- [cjm]
-- done (below) 19-MAY-03 [dave]


-- ================================================
-- TABLE: organism_dbxref
-- ================================================

create table organism_dbxref (
       organism_dbxref_id serial not null,
       primary key (organism_dbxref_id),
       organism_id int not null,
       foreign key (organism_id) references organism (organism_id),
       dbxref_id int not null,
       foreign key (dbxref_id) references dbxref (dbxref_id),

       unique(organism_id,dbxref_id)
);
create index organism_dbxref_idx1 on organism_dbxref (organism_id);
create index organism_dbxref_idx2 on organism_dbxref (dbxref_id);

-- ================================================
-- TABLE: organismprop
-- ================================================

create table organismprop (
       organismprop_id serial not null,
       primary key (organismprop_id),
       organism_id int not null,
       foreign key (organism_id) references organism (organism_id),
       pkey_id int not null,
       foreign key (pkey_id) references cvterm (cvterm_id),
       pval text not null default '',
       prank int not null default 0,

       unique(organism_id, pkey_id, pval, prank)
);
create index organismprop_idx1 on organismprop (organism_id);
create index organismprop_idx2 on organismprop (pkey_id);

