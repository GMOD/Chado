## ================================================
## TABLE: organism
## ================================================

create table organism (
	organism_id serial not null,
	primary key (organism_id),
	abbrev varchar(255) null,
	genus varchar(255) null,
	taxgroup varchar(255) null,
	species varchar(255) null,
	common_name varchar(255) null,
	comment text null,
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp,

	unique(abbrev),
	unique(taxgroup, genus, species, comment)
);
## Compared to mol5..Species, organism table lacks "approved char(1) null".  
## We need to work w/ Aubrey & Michael to ensure that we don't need this in 
## future [dave]
##
## in response: this is very specific to a limited use case I think;
## if it's really necessary we can have an organismprop table
## for adding internal project specific data
## [cjm]


## ================================================
## TABLE: organism_dbxref
## ================================================

create table organism_dbxref (
       organism_dbxref_id serial not null,
       primary key (organism_dbxref_id),
       organism_id int,
       foreign key (organism_id) references organism (organism_id),
       dbxref_id int,
       foreign key (dbxref_id) references dbxref (dbxref_id),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp
);
