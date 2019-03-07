-- $Id: map.sql,v 1.14 2007-03-23 15:18:02 scottcain Exp $
-- ==========================================
-- Chado map module
--
-- =================================================================
-- Dependencies:
--
-- :import feature from sequence
-- :import cvterm from cv
-- :import pub from pub
-- :import contact from contact
-- :import dbxref from db
-- :import organism from organism
-- =================================================================

-- ================================================
-- TABLE: featuremap
-- ================================================

create table featuremap (
    featuremap_id bigserial not null,
    primary key (featuremap_id),
    name varchar(255),
    description text,
    unittype_id bigint null,
    foreign key (unittype_id) references cvterm (cvterm_id) on delete set null INITIALLY DEFERRED,
    constraint featuremap_c1 unique (name)
);

-- ================================================
-- TABLE: featurerange
-- ================================================

create table featurerange (
    featurerange_id bigserial not null,
    primary key (featurerange_id),
    featuremap_id bigint not null,
    foreign key (featuremap_id) references featuremap (featuremap_id) on delete cascade INITIALLY DEFERRED,
    feature_id bigint not null,
    foreign key (feature_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,
    leftstartf_id bigint not null,
    foreign key (leftstartf_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,
    leftendf_id bigint,
    foreign key (leftendf_id) references feature (feature_id) on delete set null INITIALLY DEFERRED,
    rightstartf_id bigint,
    foreign key (rightstartf_id) references feature (feature_id) on delete set null INITIALLY DEFERRED,
    rightendf_id bigint not null,
    foreign key (rightendf_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,
    rangestr varchar(255)
);
create index featurerange_idx1 on featurerange (featuremap_id);
create index featurerange_idx2 on featurerange (feature_id);
create index featurerange_idx3 on featurerange (leftstartf_id);
create index featurerange_idx4 on featurerange (leftendf_id);
create index featurerange_idx5 on featurerange (rightstartf_id);
create index featurerange_idx6 on featurerange (rightendf_id);

COMMENT ON TABLE featurerange IS 'In cases where the start and end of a mapped feature is a range, leftendf and rightstartf are populated. leftstartf_id, leftendf_id, rightstartf_id, rightendf_id are the ids of features with respect to which the feature is being mapped. These may be cytological bands.';
COMMENT ON COLUMN featurerange.featuremap_id IS 'featuremap_id is the id of the feature being mapped.';


-- ================================================
-- TABLE: featurepos
-- ================================================

create table featurepos (
    featurepos_id bigserial not null,
    primary key (featurepos_id),
    featuremap_id bigint not null,
    foreign key (featuremap_id) references featuremap (featuremap_id) on delete cascade INITIALLY DEFERRED,
    feature_id bigint not null,
    foreign key (feature_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,
    map_feature_id bigint not null,
    foreign key (map_feature_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,
    mappos float not null
);
create index featurepos_idx1 on featurepos (featuremap_id);
create index featurepos_idx2 on featurepos (feature_id);
create index featurepos_idx3 on featurepos (map_feature_id);

COMMENT ON COLUMN featurepos.map_feature_id IS 'map_feature_id
links to the feature (map) upon which the feature is being localized.';

-- ================================================
-- TABLE: featureposprop
-- ================================================

CREATE TABLE featureposprop (
    featureposprop_id bigserial primary key NOT NULL,
    featurepos_id bigint NOT NULL,
    type_id bigint NOT NULL,
    value text,
    rank integer DEFAULT 0 NOT NULL,
    cvalue_id bigint,
    CONSTRAINT featureposprop_c1 UNIQUE (featurepos_id, type_id, rank),
    FOREIGN KEY (featurepos_id) REFERENCES featurepos(featurepos_id) ON DELETE CASCADE,
    FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE,
    FOREIGN KEY (cvalue_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL
);

CREATE INDEX featureposprop_idx1 ON featureposprop USING btree (featurepos_id);
CREATE INDEX featureposprop_idx2 ON featureposprop USING btree (type_id);
CREATE INDEX featureposprop_idx3 ON featureposprop USING btree (cvalue_id);

COMMENT ON TABLE featureposprop IS 'Property or attribute of a featurepos record.';
COMMENT ON COLUMN featureposprop.cvalue_id IS 'The value of the property if that value should be the name of a controlled vocabulary term.  It is preferred that a property either use the value or cvalue_id column but not both.  For example, if the property type is "color" then the cvalue_id could be a term named "green".';

-- ================================================
-- TABLE: featuremap_pub
-- ================================================

create table featuremap_pub (
    featuremap_pub_id bigserial not null,
    primary key (featuremap_pub_id),
    featuremap_id bigint not null,
    foreign key (featuremap_id) references featuremap (featuremap_id) on delete cascade INITIALLY DEFERRED,
    pub_id bigint not null,
    foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED
);
create index featuremap_pub_idx1 on featuremap_pub (featuremap_id);
create index featuremap_pub_idx2 on featuremap_pub (pub_id);

-- ================================================
-- TABLE: featuremapprop
-- ================================================

CREATE TABLE featuremapprop (
    featuremapprop_id bigserial primary key NOT NULL,
    featuremap_id bigint NOT NULL,
    type_id bigint NOT NULL,
    value text,
    rank integer DEFAULT 0 NOT NULL,
    cvalue_id bigint,
    FOREIGN KEY (cvalue_id) REFERENCES cvterm (cvterm_id) ON DELETE SET NULL,
    FOREIGN KEY (featuremap_id) REFERENCES featuremap(featuremap_id) ON DELETE CASCADE,
    FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE,
    CONSTRAINT featuremapprop_c1 UNIQUE (featuremap_id, type_id, rank)
);
create index featuremapprop_idx1 on featuremapprop(featuremap_id);
create index featuremapprop_idx2 on featuremapprop(type_id);
create index featuremapprop_idx3 on featuremapprop(cvalue_id);

COMMENT ON TABLE featuremapprop IS 'A featuremap can have any number of slot-value property 
tags attached to it. This is an alternative to hardcoding a list of columns in the 
relational schema, and is completely extensible.';
COMMENT ON COLUMN featuremapprop.cvalue_id IS 'The value of the property if that value should be the name of a controlled vocabulary term.  It is preferred that a property either use the value or cvalue_id column but not both.  For example, if the property type is "color" then the cvalue_id could be a term named "green".';


-- ================================================
-- TABLE: featuremap_contact
-- ================================================
CREATE TABLE featuremap_contact (
    featuremap_contact_id bigserial primary key NOT NULL,
    featuremap_id bigint NOT NULL,
    contact_id bigint NOT NULL,
    CONSTRAINT featuremap_contact_c1 UNIQUE (featuremap_id, contact_id),
    FOREIGN KEY (contact_id) REFERENCES contact(contact_id) ON DELETE CASCADE,
    FOREIGN KEY (featuremap_id) REFERENCES featuremap(featuremap_id) ON DELETE CASCADE
);

CREATE INDEX featuremap_contact_idx1 ON featuremap_contact USING btree (featuremap_id);
CREATE INDEX featuremap_contact_idx2 ON featuremap_contact USING btree (contact_id);

COMMENT ON TABLE featuremap_contact IS 'Links contact(s) with a featuremap.  Used to 
indicate a particular person or organization responsible for constrution of or 
that can provide more information on a particular featuremap.';


-- ================================================
-- TABLE: featuremap_dbxref
-- ================================================

CREATE TABLE featuremap_dbxref (
    featuremap_dbxref_id bigserial primary key NOT NULL,
    featuremap_id bigint NOT NULL,
    dbxref_id bigint NOT NULL,
    is_current boolean DEFAULT true NOT NULL,
    FOREIGN KEY (featuremap_id) REFERENCES featuremap(featuremap_id) ON DELETE CASCADE,
    FOREIGN KEY (dbxref_id) REFERENCES dbxref(dbxref_id) ON DELETE CASCADE
);

CREATE INDEX featuremap_dbxref_idx1 ON featuremap_dbxref USING btree (featuremap_id);
CREATE INDEX featuremap_dbxref_idx2 ON featuremap_dbxref USING btree (dbxref_id);

COMMENT ON TABLE feature_dbxref IS 'Links a feature to dbxrefs.';

COMMENT ON COLUMN feature_dbxref.is_current IS 'True if this secondary dbxref is 
the most up to date accession in the corresponding db. Retired accessions 
should set this field to false';


-- ================================================
-- TABLE: featuremap_organism
-- ================================================

CREATE TABLE featuremap_organism (
    featuremap_organism_id bigserial primary key NOT NULL,
    featuremap_id bigint NOT NULL,
    organism_id bigint NOT NULL,
    CONSTRAINT featuremap_organism_c1 UNIQUE (featuremap_id, organism_id),
    FOREIGN KEY (featuremap_id) REFERENCES featuremap(featuremap_id) ON DELETE CASCADE,
    FOREIGN KEY (organism_id) REFERENCES organism(organism_id) ON DELETE CASCADE
);

CREATE INDEX featuremap_organism_idx1 ON featuremap_organism USING btree (featuremap_id);
CREATE INDEX featuremap_organism_idx2 ON featuremap_organism USING btree (organism_id);

COMMENT ON TABLE featuremap_organism IS 'Links a featuremap to the organism(s) with which it is associated.';
