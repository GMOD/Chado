-- $Id: pub.sql,v 1.27 2007-02-19 20:50:44 briano Exp $
-- ==========================================
-- Chado pub module
--
-- =================================================================
-- Dependencies:
--
-- :import cvterm from cv
-- :import dbxref from general
-- =================================================================

-- ================================================
-- TABLE: pub
-- ================================================

create table pub (
    pub_id serial not null,
    primary key (pub_id),
    title text,
    volumetitle text,
    volume varchar(255),
    series_name varchar(255),
    issue varchar(255),
    pyear varchar(255),
    pages varchar(255),
    miniref varchar(255),
    uniquename text not null,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    is_obsolete boolean default 'false',
    publisher varchar(255),
    pubplace varchar(255),
    constraint pub_c1 unique (uniquename)
);
CREATE INDEX pub_idx1 ON pub (type_id);

COMMENT ON TABLE pub IS 'A documented provenance artefact - publications,
documents, personal communication.';
COMMENT ON COLUMN pub.title IS 'Descriptive general heading.';
COMMENT ON COLUMN pub.volumetitle IS 'Title of part if one of a series.';
COMMENT ON COLUMN pub.series_name IS 'Full name of (journal) series.';
COMMENT ON COLUMN pub.pages IS 'Page number range[s], e.g. 457--459, viii + 664pp, lv--lvii.';
COMMENT ON COLUMN pub.type_id IS  'The type of the publication (book, journal, poem, graffiti, etc). Uses pub cv.';

-- ================================================
-- TABLE: pub_relationship
-- ================================================

create table pub_relationship (
    pub_relationship_id serial not null,
    primary key (pub_relationship_id),
    subject_id int not null,
    foreign key (subject_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
    object_id int not null,
    foreign key (object_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,

    constraint pub_relationship_c1 unique (subject_id,object_id,type_id)
);
create index pub_relationship_idx1 on pub_relationship (subject_id);
create index pub_relationship_idx2 on pub_relationship (object_id);
create index pub_relationship_idx3 on pub_relationship (type_id);

COMMENT ON TABLE pub_relationship IS 'Handle relationships between
publications, e.g. when one publication makes others obsolete, when one
publication contains errata with respect to other publication(s), or
when one publication also appears in another pub.';

-- ================================================
-- TABLE: pub_dbxref
-- ================================================

create table pub_dbxref (
    pub_dbxref_id serial not null,
    primary key (pub_dbxref_id),
    pub_id int not null,
    foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
    dbxref_id int not null,
    foreign key (dbxref_id) references dbxref (dbxref_id) on delete cascade INITIALLY DEFERRED,
    is_current boolean not null default 'true',
    constraint pub_dbxref_c1 unique (pub_id,dbxref_id)
);
create index pub_dbxref_idx1 on pub_dbxref (pub_id);
create index pub_dbxref_idx2 on pub_dbxref (dbxref_id);

COMMENT ON TABLE pub_dbxref IS 'Handle links to repositories,
e.g. Pubmed, Biosis, zoorec, OCLC, Medline, ISSN, coden...';


-- ================================================
-- TABLE: pubauthor
-- ================================================

create table pubauthor (
    pubauthor_id serial not null,
    primary key (pubauthor_id),
    pub_id int not null,
    foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
    rank int not null,
    editor boolean default 'false',
    surname varchar(100) not null,
    givennames varchar(100),
    suffix varchar(100),

    constraint pubauthor_c1 unique (pub_id, rank)
);
create index pubauthor_idx2 on pubauthor (pub_id);

COMMENT ON TABLE pubauthor IS 'An author for a publication. Note the denormalisation (hence lack of _ in table name) - this is deliberate as it is in general too hard to assign IDs to authors.';
COMMENT ON COLUMN pubauthor.givennames IS 'First name, initials';
COMMENT ON COLUMN pubauthor.suffix IS 'Jr., Sr., etc';
COMMENT ON COLUMN pubauthor.rank IS 'Order of author in author list for this pub - order is important.';
COMMENT ON COLUMN pubauthor.editor IS 'Indicates whether the author is an editor for linked publication. Note: this is a boolean field but does not follow the normal chado convention for naming booleans.';


-- ================================================
-- TABLE: pubprop
-- ================================================

create table pubprop (
    pubprop_id serial not null,
    primary key (pubprop_id),
    pub_id int not null,
    foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    value text not null,
    rank integer,

    constraint pubprop_c1 unique (pub_id,type_id,rank)
);
create index pubprop_idx1 on pubprop (pub_id);
create index pubprop_idx2 on pubprop (type_id);

COMMENT ON TABLE pubprop IS 'Property-value pairs for a pub. Follows standard chado pattern.';
