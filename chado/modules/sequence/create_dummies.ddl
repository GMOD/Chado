create table ontology (
        ontology_id serial not null,
        term_name varchar(255) not null,
        term_description text
);

create table dbxref (
	dbxref_id serial not null,
	accno varchar(255) not null
);
