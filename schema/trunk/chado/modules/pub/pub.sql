-- We should take a look in OMG for a standard representation we might use 
-- instead of this.

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
-- title: title of paper, chapter of book, journal, etc
-- volumetitle: title of part if one of a series
-- series_name: full name of (journal) series
-- pages: page number range[s], eg, 457--459, viii + 664pp, lv--lvii
-- type_id: the type of the publication (book, journal, poem, graffiti, etc)
-- is_obsolete: do we want this even though we have the relationship in pub_relationship?
create index pub_idx1 on pub (type_id);

-- ================================================
-- TABLE: pub_relationship
-- ================================================

-- Handle relationships between publications, eg, when one publication
-- makes others obsolete, when one publication contains errata with
-- respect to other publication(s), or when one publication also 
-- appears in another pub (I think these three are it - at least for fb)

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

-- ================================================
-- TABLE: pub_dbxref
-- ================================================

-- Handle links to eg, pubmed, biosis, zoorec, OCLC, mdeline, ISSN, coden...

create table pub_dbxref (
    pub_dbxref_id serial not null,
    primary key (pub_dbxref_id),
    pub_id int not null,
    foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
    dbxref_id int not null,
    foreign key (dbxref_id) references dbxref (dbxref_id) on delete cascade INITIALLY DEFERRED,

    constraint pub_dbxref_c1 unique (pub_id,dbxref_id)
);
create index pub_dbxref_idx1 on pub_dbxref (pub_id);
create index pub_dbxref_idx2 on pub_dbxref (dbxref_id);


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
-- givennames: first name, initials
-- suffix: Jr., Sr., etc       
-- rank: order of author in author list for this pub
-- editor: indicates whether the author is an editor for linked publication
create index pubauthor_idx2 on pubauthor (pub_id);


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

    constraint pubprop_c1 unique (pub_id,type_id,value)
);
create index pubprop_idx1 on pubprop (pub_id);
create index pubprop_idx2 on pubprop (type_id);
