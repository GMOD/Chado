-- The cvterm module design is based on the ontology 
-- ================================================
-- TABLE: cvterm
-- ================================================

create table cvterm (
       cvterm_id serial not null,
       primary key (cvterm_id),
       termname varchar(255) not null,
       termdefinition text,
       termtype_id int,
       foreign key (termtype_id) references cvterm (cvterm_id),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp,

       unique(termname, termtype_id)
-- Its important to use termtype_id properly.  It is *NOT* used for 
-- handling, eg, parent - child relationships.  The unique key on
-- termname, termtype_id ensures that all terms are unique in a given cv
);

-- ================================================
-- TABLE: cvrelationship
-- ================================================

create table cvrelationship (
       cvrelationship_id serial not null,
       primary key (cvrelationship_id),
       reltype_id int not null,
       foreign key (reltype_id) references cvterm (cvterm_id),
       subjterm_id int not null,
       foreign key (subjterm_id) references cvterm (cvterm_id),
       objterm_id int not null,
       foreign key (objterm_id) references cvterm (cvterm_id),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp,

       unique(reltype_id, subjterm_id, objterm_id)
);
-- ================================================
-- TABLE: cvpath
-- ================================================

create table cvpath (
       cvpath_id serial not null,
       primary key (cvpath_id),
       reltype_id int,
       foreign key (reltype_id) references cvterm (cvterm_id),
       subjterm_id int not null,
       foreign key (subjterm_id) references cvterm (cvterm_id),
       objterm_id int not null,
       foreign key (objterm_id) references cvterm (cvterm_id),
       termtype_id int not null,
       foreign key (termtype_id) references cvterm (cvterm_id),
       pathdistance int,
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp,

       unique (subjterm_id, objterm_id)
);


-- ================================================
-- TABLE: cvterm_synonym
-- ================================================

create table cvterm_synonym (
       cvterm_id int not null,
       foreign key (cvterm_id) references cvterm (cvterm_id),
       termsynonym varchar(255) not null,
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp,

       unique(cvterm_id, termsynonym)
);


-- ================================================
-- TABLE: cvterm_dbxref
-- ================================================

create table cvterm_dbxref (
       cvterm_id int not null,
       foreign key (cvterm_id) references cvterm (cvterm_id),
       dbxref_id int not null,
       foreign key (dbxref_id) references dbxref (dbxref_id),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp,

       unique(cvterm_id, dbxref_id)
);

-- references from other modules:
--	      sequence: feature_cvterm




