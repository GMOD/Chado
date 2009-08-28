-- ==========================================
-- Chado cell line module
--
-- ============
-- DEPENDENCIES
-- ============
-- :import feature from sequence
-- :import synonym from sequence
-- :import library from library
-- :import cvterm from cv
-- :import dbxref from general
-- :import pub from pub
-- :import organism from organism
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- ================================================
-- TABLE: cell_line
-- ================================================

drop table cell_line cascade;
create table cell_line (
        cell_line_id serial not null,
        primary key (cell_line_id),
        name varchar(255) null,
        uniquename varchar(255) not null,
	organism_id int not null,
	foreign key (organism_id) references organism (organism_id) on delete cascade INITIALLY DEFERRED,
	timeaccessioned timestamp not null default current_timestamp,
	timelastmodified timestamp not null default current_timestamp,
        constraint cell_line_c1 unique (uniquename, organism_id)
);
grant all on cell_line to PUBLIC;


-- ================================================
-- TABLE: cell_line_relationship
-- ================================================

drop table cell_line_relationship cascade;
create table cell_line_relationship (
	cell_line_relationship_id serial not null,
	primary key (cell_line_relationship_id),	
        subject_id int not null,
	foreign key (subject_id) references cell_line (cell_line_id) on delete cascade INITIALLY DEFERRED,
        object_id int not null,
	foreign key (object_id) references cell_line (cell_line_id) on delete cascade INITIALLY DEFERRED,
	type_id int not null,
	foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
	constraint cell_line_relationship_c1 unique (subject_id, object_id, type_id)
);
grant all on cell_line_relationship to PUBLIC;


-- ================================================
-- TABLE: cell_line_synonym
-- ================================================

drop table cell_line_synonym cascade;
create table cell_line_synonym (
	cell_line_synonym_id serial not null,
	primary key (cell_line_synonym_id),
	cell_line_id int not null,
	foreign key (cell_line_id) references cell_line (cell_line_id) on delete cascade INITIALLY DEFERRED,
	synonym_id int not null,
	foreign key (synonym_id) references synonym (synonym_id) on delete cascade INITIALLY DEFERRED,
	pub_id int not null,
	foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
	is_current boolean not null default 'false',
	is_internal boolean not null default 'false',
	constraint cell_line_synonym_c1 unique (synonym_id,cell_line_id,pub_id)	
);
grant all on cell_line_synonym to PUBLIC;


-- ================================================
-- TABLE: cell_line_cvterm
-- ================================================

drop table cell_line_cvterm cascade;
create table cell_line_cvterm (
	cell_line_cvterm_id serial not null,
	primary key (cell_line_cvterm_id),
	cell_line_id int not null,
	foreign key (cell_line_id) references cell_line (cell_line_id) on delete cascade INITIALLY DEFERRED,
	cvterm_id int not null,
	foreign key (cvterm_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
	pub_id int not null,
	foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
	rank int not null default 0,
	constraint cell_line_cvterm_c1 unique (cell_line_id,cvterm_id,pub_id,rank)
);
grant all on cell_line_cvterm to PUBLIC;


-- ================================================
-- TABLE: cell_line_dbxref
-- ================================================

drop table cell_line_dbxref cascade;
create table cell_line_dbxref (
	cell_line_dbxref_id serial not null,
	primary key (cell_line_dbxref_id),
	cell_line_id int not null,
	foreign key (cell_line_id) references cell_line (cell_line_id) on delete cascade INITIALLY DEFERRED,
	dbxref_id int not null,
	foreign key (dbxref_id) references dbxref (dbxref_id) on delete cascade INITIALLY DEFERRED,
	is_current boolean not null default 'true',
	constraint cell_line_dbxref_c1 unique (cell_line_id,dbxref_id)
);
grant all on cell_line_dbxref to PUBLIC;


-- ================================================
-- TABLE: cell_lineprop
-- ================================================

drop table cell_lineprop cascade;
create table cell_lineprop (
	cell_lineprop_id serial not null,
	primary key (cell_lineprop_id),
	cell_line_id int not null,
	foreign key (cell_line_id) references cell_line (cell_line_id) on delete cascade INITIALLY DEFERRED,
	type_id int not null,
	foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
	value text null,
	rank int not null default 0,
	constraint cell_lineprop_c1 unique (cell_line_id,type_id,rank)
);
grant all on cell_lineprop to PUBLIC;


-- ================================================
-- TABLE: cell_lineprop_pub
-- ================================================

drop table cell_lineprop_pub cascade;
create table cell_lineprop_pub (
	cell_lineprop_pub_id serial not null,
	primary key (cell_lineprop_pub_id),
	cell_lineprop_id int not null,
	foreign key (cell_lineprop_id) references cell_lineprop (cell_lineprop_id) on delete cascade INITIALLY DEFERRED,
	pub_id int not null,
	foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
	constraint cell_lineprop_pub_c1 unique (cell_lineprop_id,pub_id)
);
grant all on cell_lineprop_pub to PUBLIC;


-- ================================================
-- TABLE: cell_line_feature
-- ================================================

drop table cell_line_feature cascade;
create table cell_line_feature (
	cell_line_feature_id serial not null,
	primary key (cell_line_feature_id),
	cell_line_id int not null,
	foreign key (cell_line_id) references cell_line (cell_line_id) on delete cascade INITIALLY DEFERRED,
	feature_id int not null,
	foreign key (feature_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,
	pub_id int not null,
	foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
	constraint cell_line_feature_c1 unique (cell_line_id, feature_id, pub_id)
);
grant all on cell_line_feature to PUBLIC;


-- ================================================
-- TABLE: cell_line_cvtermprop
-- ================================================

drop table cell_line_cvtermprop cascade;
create table cell_line_cvtermprop (
	cell_line_cvtermprop_id serial not null,
	primary key (cell_line_cvtermprop_id),
	cell_line_cvterm_id int not null,
	foreign key (cell_line_cvterm_id) references cell_line_cvterm (cell_line_cvterm_id) on delete cascade INITIALLY DEFERRED,
	type_id int not null,
	foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
	value text null,
	rank int not null default 0,
	constraint cell_line_cvtermprop_c1 unique (cell_line_cvterm_id, type_id, rank)
);
grant all on cell_line_cvtermprop to PUBLIC;


-- ================================================
-- TABLE: cell_line_pub
-- ================================================

drop table cell_line_pub cascade;
create table cell_line_pub (
	cell_line_pub_id serial not null,
	primary key (cell_line_pub_id),
	cell_line_id int not null,
	foreign key (cell_line_id) references cell_line (cell_line_id) on delete cascade INITIALLY DEFERRED,
	pub_id int not null,
	foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
	constraint cell_line_pub_c1 unique (cell_line_id, pub_id)
);
grant all on cell_line_pub to PUBLIC;


-- ================================================
-- TABLE: cell_line_library
-- ================================================

drop table cell_line_library cascade;
create table cell_line_library (
	cell_line_library_id serial not null,
	primary key (cell_line_library_id),
	cell_line_id int not null,
	foreign key (cell_line_id) references cell_line (cell_line_id) on delete cascade INITIALLY DEFERRED,
	library_id int not null,
	foreign key (library_id) references library (library_id) on delete cascade INITIALLY DEFERRED,
	pub_id int not null,
	foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
	constraint cell_line_library_c1 unique (cell_line_id, library_id, pub_id)
);
grant all on cell_line_library to PUBLIC;

