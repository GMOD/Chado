-- ==========================================
-- Chado project module. Used primarily by other Chado modules to
-- group experiments, stocks, and so forth that are associated with
-- eachother administratively or organizationally.
--
-- =================================================================
-- Dependencies:
--
-- :import cvterm from cv
-- :import pub from pub
-- :import contact from contact
-- :import dbxref from db
-- :import analysis from companalysis
-- :import feature from sequence
-- :import stock from stock
-- =================================================================


-- ================================================
-- TABLE: project
-- ================================================

create table project (
    project_id bigserial not null,
    primary key (project_id),
    name varchar(255) not null,
    description text,
    constraint project_c1 unique (name)
);

COMMENT ON TABLE project IS
'A project is some kind of planned endeavor.  Used primarily by other
Chado modules to group experiments, stocks, and so forth that are
associated with eachother administratively or organizationally.';

-- ================================================
-- TABLE: projectprop
-- ================================================

CREATE TABLE projectprop (
	projectprop_id bigserial NOT NULL,
	PRIMARY KEY (projectprop_id),
	project_id bigint NOT NULL,
	FOREIGN KEY (project_id) REFERENCES project (project_id) ON DELETE CASCADE,
	type_id bigint NOT NULL,
	FOREIGN KEY (type_id) REFERENCES cvterm (cvterm_id) ON DELETE CASCADE,
	value text,
	rank int not null default 0,
        cvalue_id bigint,
        FOREIGN KEY (cvalue_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL,
	CONSTRAINT projectprop_c1 UNIQUE (project_id, type_id, rank)
);

CREATE INDEX projectprop_idx1 ON projectprop (cvalue_id);

COMMENT ON TABLE projectprop IS 'Standard Chado flexible property table for projects.';

COMMENT ON COLUMN projectprop.cvalue_id IS 'The value of the property if that value should be the name of a controlled vocabulary term.  It is preferred that a property either use the value or cvalue_id column but not both.  For example, if the property type is "color" then the cvalue_id could be a term named "green".';

-- ================================================
-- TABLE: project_relationship
-- ================================================

CREATE TABLE project_relationship (
	project_relationship_id bigserial NOT NULL,
	PRIMARY KEY (project_relationship_id),
	subject_project_id bigint NOT NULL,
	FOREIGN KEY (subject_project_id) REFERENCES project (project_id) ON DELETE CASCADE,
	object_project_id bigint NOT NULL,
	FOREIGN KEY (object_project_id) REFERENCES project (project_id) ON DELETE CASCADE,
	type_id bigint NOT NULL,
	FOREIGN KEY (type_id) REFERENCES cvterm (cvterm_id) ON DELETE RESTRICT,
	CONSTRAINT project_relationship_c1 UNIQUE (subject_project_id, object_project_id, type_id)
);

COMMENT ON TABLE project_relationship IS
'Linking table for relating projects to each other.  For example, a
given project could be composed of several smaller subprojects';

COMMENT ON COLUMN project_relationship.type_id IS
'The cvterm type of the relationship being stated, such as "part of".';

-- ================================================
-- TABLE: project_pub
-- ================================================

create table project_pub (
       project_pub_id bigserial not null,
       primary key (project_pub_id),
       project_id bigint not null,
       foreign key (project_id) references project (project_id) on delete cascade INITIALLY DEFERRED,
       pub_id bigint not null,
       foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
       constraint project_pub_c1 unique (project_id,pub_id)
);
create index project_pub_idx1 on project_pub (project_id);
create index project_pub_idx2 on project_pub (pub_id);

COMMENT ON TABLE project_pub IS 'Linking table for associating projects and publications.';

-- ================================================
-- TABLE: project_contact
-- ================================================

create table project_contact (
       project_contact_id bigserial not null,
       primary key (project_contact_id),
       project_id bigint not null,
       foreign key (project_id) references project (project_id) on delete cascade INITIALLY DEFERRED,
       contact_id bigint not null,
       foreign key (contact_id) references contact (contact_id) on delete cascade INITIALLY DEFERRED,
       constraint project_contact_c1 unique (project_id,contact_id)
);
create index project_contact_idx1 on project_contact (project_id);
create index project_contact_idx2 on project_contact (contact_id);

COMMENT ON TABLE project_contact IS 'Linking table for associating projects and contacts.';

-- ================================================
-- TABLE: project_dbxref
-- ================================================

create table project_dbxref (
  project_dbxref_id bigserial not null,
  project_id bigint not null,
  dbxref_id bigint not null,
  is_current boolean not null default 'true',
  primary key (project_dbxref_id),
  foreign key (dbxref_id) references dbxref (dbxref_id) on delete cascade INITIALLY DEFERRED,
  foreign key (project_id) references project (project_id) on delete cascade INITIALLY DEFERRED,
  constraint project_dbxref_c1 unique (project_id,dbxref_id)
);
create index project_dbxref_idx1 on project_dbxref (project_id);
create index project_dbxref_idx2 on project_dbxref (dbxref_id);

COMMENT ON TABLE project_dbxref IS 'project_dbxref links a project to dbxrefs.';
COMMENT ON COLUMN project_dbxref.is_current IS 'The is_current boolean indicates whether the linked dbxref is the current -official- dbxref for the linked project.';

-- ================================================
-- TABLE: project_analysis
-- ================================================

create table project_analysis (
       project_analysis_id bigserial not null,
       primary key (project_analysis_id),
       project_id bigint not null,
       foreign key (project_id) references project (project_id) on delete cascade INITIALLY DEFERRED,
       analysis_id bigint not null,
       foreign key (analysis_id) references analysis (analysis_id) on delete cascade INITIALLY DEFERRED,
       rank int not null default 0,
       constraint project_analysis_c1 unique (project_id,analysis_id)
);
create index project_analysis_idx1 on project_analysis (project_id);
create index project_analysis_idx2 on project_analysis (analysis_id);

COMMENT ON TABLE project_analysis IS 'Links an analysis to a project that may contain multiple analyses. 
The rank column can be used to specify a simple ordering in which analyses were executed.';


-- ================================================
-- TABLE: project_feature
-- ================================================

CREATE TABLE project_feature (
    project_feature_id bigserial primary key NOT NULL,
    feature_id bigint NOT NULL,
    project_id bigint NOT NULL,
    CONSTRAINT project_feature_c1 UNIQUE (feature_id, project_id),
    FOREIGN KEY (feature_id) REFERENCES feature(feature_id) ON DELETE CASCADE,
    FOREIGN KEY (project_id) REFERENCES project(project_id) ON DELETE CASCADE
);

CREATE INDEX project_feature_idx1 ON project_feature USING btree (feature_id);
CREATE INDEX project_feature_idx2 ON project_feature USING btree (project_id);

COMMENT ON TABLE project_feature IS 'This table is intended associate records in the feature table with a project.';

-- ================================================
-- TABLE: project_stock
-- ================================================

CREATE TABLE project_stock (
    project_stock_id bigserial primary key NOT NULL,
    stock_id bigint NOT NULL,
    project_id bigint NOT NULL,
    CONSTRAINT project_stock_c1 UNIQUE (stock_id, project_id),
    FOREIGN KEY (stock_id) REFERENCES stock(stock_id) ON DELETE CASCADE,
    FOREIGN KEY (project_id) REFERENCES project(project_id) ON DELETE CASCADE
);

CREATE INDEX project_stock_idx1 ON project_stock USING btree (stock_id);
CREATE INDEX project_stock_idx2 ON project_stock USING btree (project_id);


COMMENT ON TABLE project_stock IS 'This table is intended associate records in the stock table with a project.';
