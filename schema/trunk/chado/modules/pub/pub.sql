
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

COMMENT ON TABLE pub IS 'A documented provenance artefact - publications,
documents, personal communication';

COMMENT ON COLUMN pub.title IS 'descriptive general heading';
COMMENT ON COLUMN pub.volumetitle IS 'title of part if one of a series';
COMMENT ON COLUMN pub.series_name IS 'full name of (journal) series';
COMMENT ON COLUMN pub.pages IS 'page number range[s], eg, 457--459, viii + 664pp, lv--lvii';
COMMENT ON COLUMN pub.type_id IS  'the type of the publication (book, journal, poem, graffiti, etc). Uses pub cv';
CREATE INDEX pub_idx1 ON pub (type_id);

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
COMMENT ON TABLE pub_relationship IS 'Handle relationships between
publications, eg, when one publication makes others obsolete, when one
publication contains errata with respect to other publication(s), or
when one publication also appears in another pub (I think these three
are it - at least for fb)';


create index pub_relationship_idx1 on pub_relationship (subject_id);
create index pub_relationship_idx2 on pub_relationship (object_id);
create index pub_relationship_idx3 on pub_relationship (type_id);

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

COMMENT ON TABLE pub_dbxref IS 'Handle links to eg, pubmed, biosis,
zoorec, OCLC, mdeline, ISSN, coden...';



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

COMMENT ON TABLE pubauthor IS 'an author for a publication. Note the denormalisation (hence lack of _ in table name) - this is deliberate as it is in general too hard to assign IDs to authors.';

COMMENT ON COLUMN pubauthor.givennames IS 'first name, initials';
COMMENT ON COLUMN pubauthor.suffix IS 'Jr., Sr., etc';
COMMENT ON COLUMN pubauthor.rank IS 'order of author in author list for this pub - order is important';

COMMENT ON COLUMN pubauthor.editor IS 'indicates whether the author is an editor for linked publication. Note: this is a boolean field but does not follow the normal chado convention for naming booleans';

create index pubauthor_idx2 on pubauthor (pub_id);

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

COMMENT ON TABLE pubprop IS 'Property-value pairs for a pub. Follows standard chado pattern - see sequence module for details';

create index pubprop_idx1 on pubprop (pub_id);
create index pubprop_idx2 on pubprop (type_id);
