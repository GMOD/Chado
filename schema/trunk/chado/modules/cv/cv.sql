-- See cv-intro.txt

-- ================================================
-- TABLE: cv
-- ================================================

create table cv (
       cv_id serial not null,
       primary key (cv_id),
       name varchar(255) not null,
       definition text
);
create unique index cv_idx1 on cv (name);

-- ================================================
-- TABLE: cvterm
-- ================================================

create table cvterm (
       cvterm_id serial not null,
       primary key (cvterm_id),
       cv_id int not null,
       foreign key (cv_id) references cv (cv_id) on delete cascade INITIALLY DEFERRED,
       name varchar(255) not null,
       definition text,
       dbxref_id int,
       foreign key (dbxref_id) references dbxref (dbxref_id) on delete set null INITIALLY DEFERRED
);
create index cvterm_idx1 on cvterm (cv_id);
create index cvterm_idx2 on cvterm (name);
create index cvterm_idx3 on cvterm (dbxref_id);
create unique index cvterm_idx4 on cvterm (name,cv_id);

-- the primary dbxref for this term.  Other dbxrefs may be cvterm_dbxref
-- The unique key on termname, cv_id ensures that all terms are 
-- unique within a given cv


-- ================================================
-- TABLE: cvterm_relationship
-- ================================================

create table cvterm_relationship (
       cvterm_relationship_id serial not null,
       primary key (cvterm_relationship_id),
       type_id int not null,
       foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
       subject_id int not null,
       foreign key (subject_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
       object_id int not null,
       foreign key (object_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED
);
create index cvterm_relationship_idx1 on cvterm_relationship (type_id);
create index cvterm_relationship_idx2 on cvterm_relationship (subject_id);
create index cvterm_relationship_idx3 on cvterm_relationship (object_id);
create unique index cvterm_relationship_idx4 on cvterm_relationship (type_id,subject_id,object_id);


-- ================================================
-- TABLE: cvtermpath
-- ================================================

create table cvtermpath (
       cvtermpath_id serial not null,
       primary key (cvtermpath_id),
       type_id int,
       foreign key (type_id) references cvterm (cvterm_id) on delete set null INITIALLY DEFERRED,
       subject_id int not null,
       foreign key (subject_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
       object_id int not null,
       foreign key (object_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
       cv_id int not null,
       foreign key (cv_id) references cv (cv_id) on delete cascade INITIALLY DEFERRED,
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

create table cvtermsynonym (
       cvtermsynonym_id serial not null,
       primary key (cvtermsynonym_id),
       cvterm_id int not null,
       foreign key (cvterm_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
       synonym varchar(255) not null
);
create index cvtermsynonym_idx1 on cvtermsynonym (cvterm_id);
create unique index cvtermsynonym_idx2 on cvtermsynonym (cvterm_id,synonym);

-- ================================================
-- TABLE: cvterm_dbxref
-- ================================================

create table cvterm_dbxref (
       cvterm_dbxref_id serial not null,
       primary key (cvterm_dbxref_id),
       cvterm_id int not null,
       foreign key (cvterm_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
       dbxref_id int not null,
       foreign key (dbxref_id) references dbxref (dbxref_id) on delete cascade INITIALLY DEFERRED
);
create index cvterm_dbxref_idx1 on cvterm_dbxref (cvterm_id);
create index cvterm_dbxref_idx2 on cvterm_dbxref (dbxref_id);
create unique index cvterm_dbxref_idx3 on cvterm_dbxref (cvterm_id,dbxref_id);

-- ================================================
-- TABLE: dbxrefprop
-- ================================================

create table dbxrefprop (
       dbxrefprop_id serial not null,
       primary key (dbxrefprop_id),
       dbxref_id int not null,
       foreign key (dbxref_id) references dbxref (dbxref_id) INITIALLY DEFERRED,
       type_id int not null,
       foreign key (type_id) references cvterm (cvterm_id) INITIALLY DEFERRED,
       value text null,
       rank int not null default 0
);
create index dbxrefprop_idx1 on dbxrefprop (dbxref_id);
create index dbxrefprop_idx2 on dbxrefprop (type_id);
create index dbxrefprop_idx3 on dbxrefprop (dbxref_id,type_id,rank);
