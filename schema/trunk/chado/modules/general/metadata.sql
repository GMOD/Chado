-- ================================================
-- TABLE: tableinfo
-- ================================================

create table tableinfo (
       tableinfo_id serial not null,
       primary key (tableinfo_id),
       name varchar(30) not null,
       table_type varchar(40) not null,
       primary_key_column varchar(30) null,
       database_id int not null,
       is_versioned int not null,
       is_view int not null,
       view_on_table_id int null,
       superclass_table_id int null,
       is_updateable int not null,
       modification_date date not null
);

-- ================================================
-- TABLE: project
-- ================================================
create table project (
       project_id serial not null,
       primary key (project_id),
       name varchar(255) not null,
       description varchar(255) not null
);
