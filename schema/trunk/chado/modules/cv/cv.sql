-- For an overview of this module, see cv-intro.txt
--

-- ================================================
-- TABLE: cv
-- ================================================

create table cv (
       cv_id serial not null,
       primary key (cv_id),
       name varchar(255) not null,
       definition text,

       unique(name)
);

-- ================================================
-- TABLE: cvterm
-- ================================================

create table cvterm (
       cvterm_id serial not null,
       primary key (cvterm_id),
       cv_id int not null,
       foreign key (cv_id) references cv (cv_id) on delete cascade,
       name varchar(255) not null,
       definition text,
       dbxref_id int,
       foreign key (dbxref_id) references dbxref (dbxref_id) on delete set null,
       is_obsolete int not null default 0,
       is_relationshiptype int not null default 0,
       
       unique(name, cv_id)
);
create index cvterm_idx1 on cvterm (cv_id);
-- the primary dbxref for this term.  Other dbxrefs may be cvterm_dbxref
-- The unique key on termname, cv_id ensures that all terms are 
-- unique within a given cv

-- all relationship types are extensible, and have user-defined semantics.
-- the exception is the 'is_a' (subtyping or subclassing) relationship,
-- which MUST be present, and has fixed semantics)
INSERT INTO cv (name) VALUES ('__axiomatic');
INSERT INTO cvterm (name, is_relationshiptype, cv_id) SELECT 'is_a', 1, cv_id FROM cv WHERE name = '__internal';

-- ================================================
-- TABLE: cvterm_relationship
-- ================================================

create table cvterm_relationship (
       cvterm_relationship_id serial not null,
       primary key (cvterm_relationship_id),
       type_id int not null,
       foreign key (type_id) references cvterm (cvterm_id) on delete cascade,
       subject_id int not null,
       foreign key (subject_id) references cvterm (cvterm_id) on delete cascade,
       object_id int not null,
       foreign key (object_id) references cvterm (cvterm_id) on delete cascade,

       unique(type_id, subject_id, object_id)
);
create index cvterm_relationship_idx1 on cvterm_relationship (type_id);
create index cvterm_relationship_idx2 on cvterm_relationship (subject_id);
create index cvterm_relationship_idx3 on cvterm_relationship (object_id);


-- ================================================
-- TABLE: cvtermpath
-- ================================================

create table cvtermpath (
       cvtermpath_id serial not null,
       primary key (cvtermpath_id),
       type_id int,
       foreign key (type_id) references cvterm (cvterm_id) on delete set null,
       subject_id int not null,
       foreign key (subject_id) references cvterm (cvterm_id) on delete cascade,
       object_id int not null,
       foreign key (object_id) references cvterm (cvterm_id) on delete cascade,
       cv_id int not null,
       foreign key (cv_id) references cv (cv_id) on delete cascade,
       pathdistance int
);
create index cvtermpath_idx1 on cvtermpath (type_id);
create index cvtermpath_idx2 on cvtermpath (subject_id);
create index cvtermpath_idx3 on cvtermpath (object_id);
create index cvtermpath_idx4 on cvtermpath (cv_id);
create unique index cvtermpath_idx5 on cvtermpath (subject_id, object_id, type_id, pathdistance);


-- ================================================
-- TABLE: cvtermsynonym
-- ================================================

-- synonyms can have optional types: e.g. narrower_than, exact

create table cvtermsynonym (
       cvtermsynonym_id serial not null,
       primary key (cvtermsynonym_id),
       cvterm_id int not null,
       foreign key (cvterm_id) references cvterm (cvterm_id) on delete cascade,
       synonym varchar(255) not null,
       type_id int,
       foreign key (type_id) references cvterm (cvterm_id) on delete cascade,

       unique(cvterm_id, synonym)
);
create index cvtermsynonym_idx1 on cvtermsynonym (cvterm_id);


-- ================================================
-- TABLE: cvterm_dbxref
-- ================================================

create table cvterm_dbxref (
       cvterm_dbxref_id serial not null,
       primary key (cvterm_dbxref_id),
       cvterm_id int not null,
       foreign key (cvterm_id) references cvterm (cvterm_id) on delete cascade,
       dbxref_id int not null,
       foreign key (dbxref_id) references dbxref (dbxref_id) on delete cascade,
       is_for_definition int not null default 0,

       unique(cvterm_id, dbxref_id)
);
create index cvterm_dbxref_idx1 on cvterm_dbxref (cvterm_id);
create index cvterm_dbxref_idx2 on cvterm_dbxref (dbxref_id);

-- ================================================
-- TABLE: cvtermprop
-- ================================================

create table cvtermprop (
       cvtermprop_id serial not null,
       primary key (cvtermprop_id),
       cvterm_id int not null,
       foreign key (cvterm_id) references cvterm (cvterm_id) on delete cascade,
       type_id int not null,
       foreign key (type_id) references cvterm (cvterm_id) on delete cascade,
       value text not null default '',
       rank int not null default 0,

       unique(cvterm_id, type_id, value, rank)
);

-- ================================================
-- TABLE: dbxrefprop
-- ================================================

create table dbxrefprop (
       dbxrefprop_id serial not null,
       primary key (dbxrefprop_id),
       dbxref_id int not null,
       foreign key (dbxref_id) references dbxref (dbxref_id),
       type_id int not null,
       foreign key (type_id) references cvterm (cvterm_id),
       value text not null default '',
       rank int not null default 0,

       unique(dbxref_id, type_id, value, rank)
);
create index dbxrefprop_idx1 on dbxrefprop (dbxref_id);
create index dbxrefprop_idx2 on dbxrefprop (type_id);

