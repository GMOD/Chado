-- ================================================
-- TABLE: tableinfo
-- ================================================

create table tableinfo (
    tableinfo_id serial not null,
    primary key (tableinfo_id),
    name varchar(30) not null,
    primary_key_column varchar(30) null,
    is_view int not null default 0,
    view_on_table_id int null,
    superclass_table_id int null,
    is_updateable int not null default 1,
    modification_date date not null default now(),
    constraint tableinfo_c1 unique (name)
);

COMMENT ON TABLE tableinfo IS NULL;

-- ================================================
-- TABLE: contact
-- ================================================
create table contact (
    contact_id serial not null,
    primary key (contact_id),
    name varchar(30) not null,
    description varchar(255) null,
    constraint contact_c1 unique (name)
);

COMMENT ON TABLE contact IS NULL;

-- ================================================
-- TABLE: db
-- ================================================

create table db (
    db_id serial not null,
    primary key (db_id),
    name varchar(255) not null,
    contact_id int not null,
    foreign key (contact_id) references contact (contact_id) on delete cascade INITIALLY DEFERRED,
    description varchar(255) null,
    urlprefix varchar(255) null,
    url varchar(255) null,
    constraint db_c1 unique (name)
);

COMMENT ON TABLE db IS NULL;

-- ================================================
-- TABLE: dbxref
-- ================================================

create table dbxref (
    dbxref_id serial not null,
    primary key (dbxref_id),
    db_id int not null,
    foreign key (db_id) references db (db_id) on delete cascade INITIALLY DEFERRED,
    accession varchar(255) not null,
    version varchar(255) not null default '',
    description text,
    constraint dbxref_c1 unique (db_id,accession,version)
);
create index dbxref_idx1 on dbxref (db_id);
create index dbxref_idx2 on dbxref (accession);
create index dbxref_idx3 on dbxref (version);

COMMENT ON TABLE dbxref IS NULL;

-- ================================================
-- TABLE: project
-- ================================================
create table project (
    project_id serial not null,  
    primary key (project_id),
    name varchar(255) not null,
    description varchar(255) not null,
    constraint project_c1 unique (name)
);

COMMENT ON TABLE project IS NULL;
-- See cv-intro.txt

-- ================================================
-- TABLE: cv
-- ================================================

create table cv (
    cv_id serial not null,
    primary key (cv_id),
    name varchar(1024) not null,
   definition text,
   constraint cv_c1 unique (name)
);

-- ================================================
-- TABLE: cvterm
-- ================================================

create table cvterm (
    cvterm_id serial not null,
    primary key (cvterm_id),
    cv_id int not null,
    foreign key (cv_id) references cv (cv_id) on delete cascade INITIALLY DEFERRED,
    name varchar(1024) not null,
    definition text,
    dbxref_id int,
    foreign key (dbxref_id) references dbxref (dbxref_id) on delete set null INITIALLY DEFERRED,
    constraint cvterm_c1 unique (name,cv_id)
);
create index cvterm_idx1 on cvterm (cv_id);
create index cvterm_idx2 on cvterm (name);
create index cvterm_idx3 on cvterm (dbxref_id);

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
    foreign key (object_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    constraint cvterm_relationship_c1 unique (subject_id,object_id,type_id)
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
    foreign key (type_id) references cvterm (cvterm_id) on delete set null INITIALLY DEFERRED,
    subject_id int not null,
    foreign key (subject_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    object_id int not null,
    foreign key (object_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    cv_id int not null,
    foreign key (cv_id) references cv (cv_id) on delete cascade INITIALLY DEFERRED,
    pathdistance int,
    constraint cvtermpath_c1 unique (subject_id,object_id,type_id,pathdistance)
);
create index cvtermpath_idx1 on cvtermpath (type_id);
create index cvtermpath_idx2 on cvtermpath (subject_id);
create index cvtermpath_idx3 on cvtermpath (object_id);
create index cvtermpath_idx4 on cvtermpath (cv_id);

-- ================================================
-- TABLE: cvtermsynonym
-- ================================================

create table cvtermsynonym (
    cvtermsynonym_id serial not null,
    primary key (cvtermsynonym_id),
    cvterm_id int not null,
    foreign key (cvterm_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    synonym varchar(1024) not null,
    constraint cvtermsynonym_c1 unique (cvterm_id,synonym)
);
create index cvtermsynonym_idx1 on cvtermsynonym (cvterm_id);

-- ================================================
-- TABLE: cvterm_dbxref
-- ================================================

create table cvterm_dbxref (
    cvterm_dbxref_id serial not null,
    primary key (cvterm_dbxref_id),
    cvterm_id int not null,
    foreign key (cvterm_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    dbxref_id int not null,
    foreign key (dbxref_id) references dbxref (dbxref_id) on delete cascade INITIALLY DEFERRED,
    constraint cvterm_dbxref_c1 unique (cvterm_id,dbxref_id)
);
create index cvterm_dbxref_idx1 on cvterm_dbxref (cvterm_id);
create index cvterm_dbxref_idx2 on cvterm_dbxref (dbxref_id);

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
    rank int not null default 0,
    constraint dbxrefprop_c1 unique (dbxref_id,type_id,rank)
);
create index dbxrefprop_idx1 on dbxrefprop (dbxref_id);
create index dbxrefprop_idx2 on dbxrefprop (type_id);
-- ================================================
-- TABLE: organism
-- ================================================

create table organism (
	organism_id serial not null,
	primary key (organism_id),
	abbreviation varchar(255) null,
	genus varchar(255) not null,
	species varchar(255) not null,
	common_name varchar(255) null,
	comment text null,
    constraint organism_c1 unique (genus,species)
);

-- Compared to mol5..Species, organism table lacks "approved char(1) null".  
-- We need to work w/ Aubrey & Michael to ensure that we don't need this in 
-- future [dave]
--
-- in response: this is very specific to a limited use case I think;
-- if it's really necessary we can have an organismprop table
-- for adding internal project specific data
-- [cjm]
-- done (below) 19-MAY-03 [dave]


-- ================================================
-- TABLE: organism_dbxref
-- ================================================

create table organism_dbxref (
    organism_dbxref_id serial not null,
    primary key (organism_dbxref_id),
    organism_id int not null,
    foreign key (organism_id) references organism (organism_id) on delete cascade INITIALLY DEFERRED,
    dbxref_id int not null,
    foreign key (dbxref_id) references dbxref (dbxref_id) on delete cascade INITIALLY DEFERRED,
    constraint organism_dbxref_c1 unique (organism_id,dbxref_id)
);
create index organism_dbxref_idx1 on organism_dbxref (organism_id);
create index organism_dbxref_idx2 on organism_dbxref (dbxref_id);

-- ================================================
-- TABLE: organismprop
-- ================================================

create table organismprop (
    organismprop_id serial not null,
    primary key (organismprop_id),
    organism_id int not null,
    foreign key (organism_id) references organism (organism_id) on delete cascade INITIALLY DEFERRED,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    value text null,
    rank int not null default 0,
    constraint organismprop_c1 unique (organism_id,type_id,rank)
);
create index organismprop_idx1 on organismprop (organism_id);
create index organismprop_idx2 on organismprop (type_id);
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
    constraint pub_c1 unique (uniquename,type_id)
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
-- TABLE: author
-- ================================================

-- using the FB author table columns

create table author (
    author_id serial not null,
    primary key (author_id),
    contact_id int null,
    foreign key (contact_id) references contact (contact_id) INITIALLY DEFERRED,
    surname varchar(100) not null,
    givennames varchar(100),
    suffix varchar(100),

    constraint author_c1 unique (surname,givennames,suffix)
);
-- givennames: first name, initials
-- suffix: Jr., Sr., etc       


-- ================================================
-- TABLE: pub_author
-- ================================================

create table pub_author (
    pub_author_id serial not null,
    primary key (pub_author_id),
    author_id int not null,
    foreign key (author_id) references author (author_id) on delete cascade INITIALLY DEFERRED,
    pub_id int not null,
    foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
    rank int not null,
    editor boolean default 'false',

    constraint pub_author_c1 unique (author_id,pub_id)
);
-- rank: order of author in author list for this pub
-- editor: indicates whether the author is an editor for linked publication
create index pub_author_idx1 on pub_author (author_id);
create index pub_author_idx2 on pub_author (pub_id);


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
-- ================================================
-- TABLE: feature
-- ================================================

create table feature (
    feature_id serial not null,
    primary key (feature_id),
    dbxref_id int,
    foreign key (dbxref_id) references dbxref (dbxref_id) on delete set null INITIALLY DEFERRED,
    organism_id int not null,
    foreign key (organism_id) references organism (organism_id) on delete cascade INITIALLY DEFERRED,
    name varchar(255),
    uniquename text not null,
    residues text,
    seqlen int,
    md5checksum char(32),
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    is_analysis boolean not null default 'false',
    timeaccessioned timestamp not null default current_timestamp,
    timelastmodified timestamp not null default current_timestamp,
    constraint feature_c1 unique (organism_id,uniquename,type_id)
);
-- dbxref_id here is intended for the primary dbxref for this feature.   
-- Additional dbxref links are made via feature_dbxref
-- name: the human-readable common name for a feature, for display
-- uniquename: the unique name for a feature; may not be particularly human-readable

-- timeaccessioned and timelastmodified are for handling object accession/
-- modification timestamps (as opposed to db auditing info, handled elsewhere).
-- The expectation is that these fields would be available to software 
-- interacting with chado.
create sequence feature_uniquename_seq;
create index feature_name_ind1 on feature(name);
create index feature_idx1 on feature (dbxref_id);
create index feature_idx2 on feature (organism_id);
create index feature_idx3 on feature (type_id);
create index feature_idx4 on feature (uniquename);
create index feature_idx5 on feature (lower(name));
--This ALTER TABLE statement changes the way sequence data
--is stored on disk to make extracting substrings much faster
--at the expense of more disk space
--ALTER TABLE feature ALTER COLUMN residues SET STORAGE EXTENDED;


-- ================================================
-- TABLE: featureloc
-- ================================================

-- each feature can have 0 or more locations.
-- multiple locations do NOT indicate non-contiguous locations.
-- instead they designate alternate locations or grouped locations;
-- for instance, a feature designating a blast hit or hsp will have two
-- locations, one on the query feature, one on the subject feature.
-- features representing sequence variation could have alternate locations
-- instantiated on a feature on the mutant strain.
-- the field "rank" is used to differentiate these different locations.
-- the default rank '0' is used for the main/primary location (eg in
-- similarity features, 0 is query, 1 is subject), although sometimes
-- this will be symmeytical and there is no primary location.
--
-- redundant locations can also be stored - for instance, the position
-- of an exon on a BAC and in global coordinates. the field "locgroup"
-- is used to differentiate these groupings of locations. the default
-- locgroup '0' is used for the main/primary location, from which the
-- others can be derived via coordinate transformations. another
-- example of redundant locations is storing ORF coordinates relative
-- to both transcript and genome. redundant locations open the possibility
-- of the database getting into inconsistent states; this schema gives
-- us the flexibility of both 'warehouse' instantiations with redundant
-- locations (easier for querying) and 'management' instantiations with
-- no redundant locations.

-- most features (exons, transcripts, etc) will have 1 location, with
-- locgroup and rank equal to 0
--
-- an example of using both locgroup and rank:
-- imagine a feature indicating a conserved region between the chromosomes
-- of two different species. we may want to keep redundant locations on
-- both contigs and chromosomes. we would thus have 4 locations for the
-- single conserved region feature - two distinct locgroups (contig level
-- and chromosome level) and two distinct ranks (for the two species).

-- altresidues is used to store alternate residues of a feature, when these
-- differ from feature.residues. for instance, a SNP feature located on
-- a wild and mutant protein would have different alresidues.
-- for alignment/similarity features, the altresidues is used to represent
-- the alignment string.

-- note on variation features; even if we don't want to instantiate a mutant
-- chromosome/contig feature, we can still represent a SNP etc with 2 locations,
-- one (rank 0) on the genome, the other (rank 1) would have most fields null,
-- except for altresidues

-- IMPORTANT: fnbeg and fnend are space-based (INTERBASE) coordinates
-- this is vital as it allows us to represent zero-length
-- features eg splice sites, insertion points without
-- an awkward fuzzy system

-- Note that nbeg and nend have been replaced with fmin and fmax,
-- which are the minimum and maximum coordinates of the feature
-- relative to the parent feature.  By contrast,
-- nbeg, nend are for feature natural begin/end
-- by natural begin, end we mean these are the actual
-- beginning (5' position) and actual end (3' position)
-- rather than the low position and high position, as
-- these terms are sometimes erroneously used.  To compensate
-- for the removal of nbeg and nend from featureloc, a view
-- based on featureloc, dfeatureloc, is provided in sequence_views.sql.

create table featureloc (
    featureloc_id serial not null,
    primary key (featureloc_id),
    feature_id int not null,
    foreign key (feature_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,
    srcfeature_id int,
    foreign key (srcfeature_id) references feature (feature_id) on delete set null INITIALLY DEFERRED,
    fmin int,
    is_fmin_partial boolean not null default 'false',
    fmax int,
    is_fmax_partial boolean not null default 'false',
    strand smallint,
    phase int,
    residue_info text,
    locgroup int not null default 0,
    rank int not null default 0,
    constraint featureloc_c1 unique (feature_id,locgroup,rank)
);
-- phase: phase of translation wrt srcfeature_id.  Values are 0,1,2
create index featureloc_idx1 on featureloc (feature_id);
create index featureloc_idx2 on featureloc (srcfeature_id);
create index featureloc_idx3 on featureloc (srcfeature_id,fmin,fmax);

-- ================================================
-- TABLE: feature_pub
-- ================================================

create table feature_pub (
    feature_pub_id serial not null,
    primary key (feature_pub_id),
    feature_id int not null,
    foreign key (feature_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,
    pub_id int not null,
    foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
    constraint feature_pub_c1 unique (feature_id,pub_id)
);
create index feature_pub_idx1 on feature_pub (feature_id);
create index feature_pub_idx2 on feature_pub (pub_id);

-- ================================================
-- TABLE: featureprop
-- ================================================

create table featureprop (
    featureprop_id serial not null,
    primary key (featureprop_id),
    feature_id int not null,
    foreign key (feature_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    value text null,
    rank int not null default 0,
    constraint featureprop_c1 unique (feature_id,type_id,rank)
);
create index featureprop_idx1 on featureprop (feature_id);
create index featureprop_idx2 on featureprop (type_id);

-- ================================================
-- TABLE: featureprop_pub
-- ================================================

create table featureprop_pub (
    featureprop_pub_id serial not null,
    primary key (featureprop_pub_id),
    featureprop_id int not null,
    foreign key (featureprop_id) references featureprop (featureprop_id) on delete cascade INITIALLY DEFERRED,
    pub_id int not null,
    foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
    constraint featureprop_pub_c1 unique (featureprop_id,pub_id)
);
create index featureprop_pub_idx1 on featureprop_pub (featureprop_id);
create index featureprop_pub_idx2 on featureprop_pub (pub_id);

-- ================================================
-- TABLE: feature_dbxref
-- ================================================
-- links a feature to dbxrefs.  Note that there is also feature.dbxref_id
-- link for the primary dbxref link.

create table feature_dbxref (
    feature_dbxref_id serial not null,
    primary key (feature_dbxref_id),
    feature_id int not null,
    foreign key (feature_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,
    dbxref_id int not null,
    foreign key (dbxref_id) references dbxref (dbxref_id) on delete cascade INITIALLY DEFERRED,
    is_current boolean not null default 'true',
    constraint feature_dbxref_c1 unique (feature_id,dbxref_id)
);
create index feature_dbxref_idx1 on feature_dbxref (feature_id);
create index feature_dbxref_idx2 on feature_dbxref (dbxref_id);

-- ================================================
-- TABLE: feature_relationship
-- ================================================

-- features can be arranged in graphs, eg exon partof transcript 
-- partof gene; translation madeby transcript
-- if type is thought of as a verb, each arc makes a statement
-- [SUBJECT VERB OBJECT]
-- object can also be thought of as parent, and subject as child
--
-- we include the relationship rank/order, because even though
-- most of the time we can order things implicitly by sequence
-- coordinates, we can't always do this - eg transpliced genes.
-- it's also useful for quickly getting implicit introns

create table feature_relationship (
    feature_relationship_id serial not null,
    primary key (feature_relationship_id),
    subject_id int not null,
    foreign key (subject_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,
    object_id int not null,
    foreign key (object_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    value text null,
    rank int not null default 0,
    constraint feature_relationship_c1 unique (subject_id,object_id,type_id,rank)
);
create index feature_relationship_idx1 on feature_relationship (subject_id);
create index feature_relationship_idx2 on feature_relationship (object_id);
create index feature_relationship_idx3 on feature_relationship (type_id);

-- ================================================
-- TABLE: feature_relationship_pub
-- ================================================
 
create table feature_relationship_pub (
	feature_relationship_pub_id serial not null,
	primary key (feature_relationship_pub_id),
	feature_relationship_id int not null,
	foreign key (feature_relationship_id) references feature_relationship (feature_relationship_id) on delete cascade INITIALLY DEFERRED,
	pub_id int not null,
	foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
    constraint feature_relationship_pub_c1 unique (feature_relationship_id,pub_id)
);
create index feature_relationship_pub_idx1 on feature_relationship_pub (feature_relationship_id);
create index feature_relationship_pub_idx2 on feature_relationship_pub (pub_id);
 
-- ================================================
-- TABLE: feature_relationshipprop
-- ================================================
-- store attributes of feature relationships

create table feature_relationshipprop (
    feature_relationshipprop_id serial not null,
    primary key (feature_relationshipprop_id),
    feature_relationship_id int not null,
    foreign key (feature_relationship_id) references feature_relationship (feature_relationship_id) on delete cascade,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    value text null,
    rank int not null default 0,
    constraint feature_relationshipprop_c1 unique (feature_relationship_id,type_id,rank)
);
create index feature_relationshipprop_idx1 on feature_relationshipprop (feature_relationship_id);
create index feature_relationshipprop_idx2 on feature_relationshipprop (type_id);

-- ================================================
-- TABLE: feature_relationshipprop_pub
-- ================================================

create table feature_relationshipprop_pub (
    feature_relationshipprop_pub_id serial not null,
    primary key (feature_relationshipprop_pub_id),
    feature_relationshipprop_id int not null,
    foreign key (feature_relationshipprop_id) references feature_relationshipprop (feature_relationshipprop_id) on delete cascade INITIALLY DEFERRED,
    pub_id int not null,
    foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
    constraint feature_relationshipprop_pub_c1 unique (feature_relationshipprop_id,pub_id)
);
create index feature_relationshipprop_pub_idx1 on feature_relationshipprop_pub (feature_relationshipprop_id);
create index feature_relationshipprop_pub_idx2 on feature_relationshipprop_pub (pub_id);

-- ================================================
-- TABLE: feature_cvterm
-- ================================================

create table feature_cvterm (
    feature_cvterm_id serial not null,
    primary key (feature_cvterm_id),
    feature_id int not null,
    foreign key (feature_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,
    cvterm_id int not null,
    foreign key (cvterm_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    pub_id int not null,
    foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
    constraint feature_cvterm_c1 unique (feature_id,cvterm_id,pub_id)
);
create index feature_cvterm_idx1 on feature_cvterm (feature_id);
create index feature_cvterm_idx2 on feature_cvterm (cvterm_id);
create index feature_cvterm_idx3 on feature_cvterm (pub_id);

-- ================================================
-- TABLE: feature_cvtermprop
-- ================================================
-- store attributes of feature_cvterm relationships, for instance GO evidence
-- codes

create table feature_cvtermprop (
    feature_cvtermprop_id serial not null,
    primary key (feature_cvtermprop_id),
    feature_cvterm_id int not null,
    foreign key (feature_cvterm_id) references feature_cvterm (feature_cvterm_id) on delete cascade,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    value text null,
    rank int not null default 0,
    constraint feature_cvtermprop_c1 unique (feature_cvterm_id,type_id,rank)
);
create index feature_cvtermprop_idx1 on feature_cvtermprop (feature_cvterm_id);
create index feature_cvtermprop_idx2 on feature_cvtermprop (type_id);


-- ================================================
-- TABLE: synonym
-- ================================================

create table synonym (
    synonym_id serial not null,
    primary key (synonym_id),
    name varchar(255) not null,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    synonym_sgml varchar(255) not null,
    constraint synonym_c1 unique (name,type_id)
);
-- type_id: types would be symbol and fullname for now
-- synonym_sgml: sgml-ized version of symbols
create index synonym_idx1 on synonym (type_id);

-- ================================================
-- TABLE: feature_synonym
-- ================================================

create table feature_synonym (
    feature_synonym_id serial not null,
    primary key (feature_synonym_id),
    synonym_id int not null,
    foreign key (synonym_id) references synonym (synonym_id) on delete cascade INITIALLY DEFERRED,
    feature_id int not null,
    foreign key (feature_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,
    pub_id int not null,
    foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
    is_current boolean not null default 'true',
    is_internal boolean not null default 'false',
    constraint feature_synonym_c1 unique (synonym_id,feature_id,pub_id)
);
-- pub_id: the pub_id link is for relating the usage of a given synonym to the
-- publication in which it was used
-- is_current: the is_current bit indicates whether the linked synonym is the 
-- current -official- symbol for the linked feature
-- is_internal: typically a synonym exists so that somebody querying the db with an
-- obsolete name can find the object they're looking for (under its current
-- name.  If the synonym has been used publicly & deliberately (eg in a 
-- paper), it my also be listed in reports as a synonym.   If the synonym 
-- was not used deliberately (eg, there was a typo which went public), then 
-- the is_internal bit may be set to 'true' so that it is known that the 
-- synonym is "internal" and should be queryable but should not be listed 
-- in reports as a valid synonym.
create index feature_synonym_idx1 on feature_synonym (synonym_id);
create index feature_synonym_idx2 on feature_synonym (feature_id);
create index feature_synonym_idx3 on feature_synonym (pub_id);
-- ==========================================
-- Chado genetics module
--
-- redesigned 2003-10-28
--
-- changes 2003-11-10:
--   incorporating suggestions to make everything a gcontext; use 
--   gcontext_relationship to make some gcontexts derivable from others. we 
--   would incorporate environment this way - just add the environment 
--   descriptors as properties of the child gcontext
--
-- for modeling simple or complex genetic screens
--
-- most genetic statements are about "alleles", although
-- sometimes the definition of allele is stretched
-- (RNAi, engineered construct). genetic statements can
-- also be about large aberrations that take out
-- multiple genes (in FlyBase the policy here is to create
-- alleles for genes within the end-points only, and to
-- attach phenotypic data and so forth to the aberration)
--
-- in chado, a mutant allele is just another feature of type "gene";
-- it is just another form of the canonical wild-type gene feature.
--
-- it is related via an "allele-of" feature_relationship; eg
-- [id:FBgn001, type:gene] <-- [id:FBal001, type:gene]
--
-- with the genetic module, features can either be attached
-- to features of type sequence_variation, or to features of
-- type 'gene' (in the case of mutant alleles).
--
-- if a sequence_variation is large (eg a deficiency) and
-- knocks out multiple genes, then we want to attach the
-- phenotype directly to the sequence variation.
--
-- if the mutation is simple, and affects a single wild-type
-- gene feature, then we would create the mutant allele
-- (another gene feature) and attach the phenotypic data via
-- that feature
--
-- this allows us the option of doing a full structural
-- annotation of the mutant allele gene feature in the future
--
-- we don't necessarily know the molecular details of the
-- the sequence variation (but if we later discover them,
-- we can simply add a featureloc to the sequence_variation
--
-- we can also have sequence variations (of type haplotype_block)
-- that are collections of smaller variations (i.e. via
-- "part_of" feature_relationships) - we could attach phenotypic
-- stuff via this haplotype_block feature or to the alleles it
-- causes
--
-- if we have a mutation affecting the shared region of a nested
-- gene, and we did not know which of the two mutant gene forms were
-- responsible for the resulting phenotype, we would attach the
-- phenotype directly to sequence_variation feature; if we knew
-- which of the two mutant forms of the gene were responsible for
-- the phenotype, we would attach it to them
--
-- we leave open the opportunity for attaching phenotypes via
-- mutant forms of transcripts/proteins/promoters
--
-- we can represent the relationship between a variation and
-- the mutant gene features via a "causes" feature_relationship
--
-- LINKING ALLELES AND VARIATIONS TO PHENOTYPES
--
-- we link via a "genetic context" table - this is essentially
-- the genotype
--
-- most genetic statements take the form
--
-- "allele x[1] shows phenotype P"
--
-- which we represent as "the genetic context defined by x[1] shows P"
--
-- we also allow
--
-- "allele x[1] shows phenotypes P, Q against a background of sev[3]"
--
-- but we actually represent it as
-- "x[1], sev[3] shows phenotypes P, Q"
--
-- x[1] sev[3] is the geneticcontext - genetic contexts can also
-- include things not part of a genotype - e.g. RNAi introduced into cell
--
-- representing environment:
--
-- "allele x[1] shows phenotype P against a background of sev[TS1] at 38 degrees"
-- "allele x[1] shows NO phenotype P against a background of sev[TS1] at 36 degrees"
--
-- we specify this with an environmental context
--
-- we use the gxe relation (genetic context X environmental context) to
-- represent the actual organismal context under observation
--
-- for the description of the phenotype, we are using the standard
-- Observable/Attribute/Value model from the Phenotype Ontology
--
-- we also allow genetic interactions:
--
-- "dx[24] suppresses the wing vein phenotype of H[2]"
--
-- but we actually represent this as:
--
-- "H[2] -> wing vein phenotype P1"
-- "dx[24] -> wing vein phenotype P2"
-- "P2 < P1"
--
-- from this we can do the necessary inference
--
-- complementation:
--
-- "x[1] complements x[2]"
--
-- is actually
--
-- "x[1] -> P1"
-- "x[2] -> P2"
-- "x[2],x[2] -> P3"
-- P3 < P1, P3 < P2
--
-- complementation can be qualified, (eg due to transvection/transsplicing)
--
-- RNAi can be handled - in this case the "allele" is a RNA construct (another
-- feature type) introduced to the cell (but not the genome??) which has an
-- observable phenotypic effect
--
-- "foo[RNAi.1] shows phenotype P"
--
-- mis-expression screens (eg GAL4/UAS) are handled - here the
-- "alleles" are either the construct features, or the insertion features
-- holding the construct (we may need SO type "gal4_insertion" etc);
-- we actually need two alleles in these cases - for both GAL4 and UAS
-- we then record statements such as:
--
-- "Ras85D[V12.S35], gal4[dpp.blk1]  shows phenotype P"
--
-- we use feature_relationships to represent the relationship between
-- the construct and the original non-Scer gene
--
-- we can also record experiments made with other engineered constructs:
-- for example, rescue constructs made from transcripts with an without
-- introns, and recording the difference in phenotype
--
-- the design here is heavily indebted to Rachel Drysdale's paper
-- "Genetic Data in FlyBase"
--
-- ALLELE CLASS
--
-- alleles are amorphs, hypomorphs, etc
--
-- since alleles are features of type gene, we can just use feature_cvterm
-- for this
--
-- SHOULD WE ALSO MAKE THIS CONTEXTUAL TO PHENOTYPE??
--
-- OPEN QUESTION: homologous recombination events
--
-- STOCKS
--
-- this should be in a sub-module of this one; basically we want some
-- kind of linking table between stock and gcontext
--
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ============
-- DEPENDENCIES
-- ============
-- :import feature from sequence
-- :import cvterm from cv
-- :import pub from pub
-- :import dbxref from general
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ============
-- RELATIONS
-- ============


-- RELATION: gcontext
--
-- genetic context
-- 
-- essentially a combination of genotype and extra-genotype gene
-- products; eg a genotype + some RNAi product
-- 
-- AND ALSO ENVIRONMENT!!!
-- 
-- the uniquename should be derived from the features making
-- up the genetic context(see feature_gcontext)
-- 
-- uniquename          : a human-readable unique identifier
--

create table gcontext (
    gcontext_id	serial not null,
    primary key (gcontext_id),
    uniquename varchar(255) not null,
    description	text,
    pub_id int not null,
    foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
    constraint gcontext_c1 unique (uniquename)
);

-- ****************************************


-- RELATION: gcontext_relationship
--
-- genetic contexts can be related to eachother (eg ISA/derived-from)
-- this means that different authors can talk about essentially the
-- same gcontext, although each would have their own gcontext_id;
-- they would all be descended from the same parent gcontext
-- 
--
create table gcontext_relationship (
    gcontext_relationship_id serial not null,
    primary key (gcontext_relationship_id),
    subject_id int not null,
    foreign key (subject_id) references gcontext (gcontext_id) on delete cascade INITIALLY DEFERRED,
    object_id int not null, 
    foreign key (object_id) references gcontext (gcontext_id) on delete cascade INITIALLY DEFERRED,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    constraint gcontext_relationship_c1 unique (subject_id,object_id,type_id)
);
create index gcontext_relationship_idx1 on gcontext_relationship (subject_id);
create index gcontext_relationship_idx2 on gcontext_relationship (object_id);
create index gcontext_relationship_idx3 on gcontext_relationship (type_id);

-- RELATION: feature_gcontext
--
-- A gcontext is defined by a collection of features
-- mutations, balancers, deficiencies, haplotype blocks, engineered
-- constructs
-- 
-- rank can be used for n-ploid organisms
-- 
-- group can be used for distinguishing the chromosomal groups
-- 
-- (RNAi products and so on can be treated as different groups, as
-- they do not fall on a particular chromosome)
-- 
-- OPEN QUESTION: for multicopy transgenes, should we include a 'n_copies'
-- column as well?
-- 
-- chromosome_id       : a feature of SO type 'chromosome'
-- rank                : preserves order
-- group               : spatially distinguishable group
--
create table feature_gcontext (
	feature_gcontext_id	serial not null,
	primary key (feature_gcontext_id),
	feature_id int not null,
	foreign key (feature_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,
	gcontext_id	int not null,
	foreign key (gcontext_id) references gcontext (gcontext_id) on delete cascade INITIALLY DEFERRED,
	chromosome_id int,
	foreign key (chromosome_id) references feature(feature_id) on delete set null INITIALLY DEFERRED,
	rank int not null,
	cgroup int not null,
	cvterm_id int not null,
	foreign key (cvterm_id) references cvterm(cvterm_id) on delete cascade INITIALLY DEFERRED,
    constraint feature_gcontext_c1 unique (feature_id,gcontext_id,cvterm_id)
);
create index feature_gcontext_idx1 on feature_gcontext (feature_id);
create index feature_gcontext_idx2 on feature_gcontext (gcontext_id);

-- RELATION: gcontextprop
--
-- key/val pairs for a genetic context
-- can be environmental; eg temperature_degrees_c=36
-- 
-- value               : unconstrained free text value
--
create table gcontextprop (
	gcontextprop_id	serial not null,
	primary key (gcontextprop_id),
	gcontext_id	int not null,
	foreign key (gcontext_id) references gcontext (gcontext_id) on delete cascade INITIALLY DEFERRED,
	type_id	int not null,
	foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
	value	text null,
	rank int not null default 0,
    constraint gcontextprop_c1 unique (gcontext_id,type_id,rank)
);
create index gcontextprop_idx1 on gcontextprop (gcontext_id);
create index gcontextprop_idx2 on gcontextprop (type_id);

-- RELATION: phenstatement
--
-- a phenotypic statement, or a single atomic phenotypic
-- observation
-- 
-- a controlled sentence describing observable effect of non-wt function
-- 
-- e.g. Obs=eye, attribute=color, cvalue=red
-- 
-- see notes from Phenotype Ontology meeting
-- 
-- observable_id       : e.g. anatomy_part, biological_process
-- attr_id             : e.g. process
-- value               : unconstrained free text value
-- cvalue_id           : constrained value from ontology, e.g. "abnormal", "big"
-- assay_id            : e.g. name of specific test
--
create table phenstatement (
	phenstatement_id	serial not null,
	primary key (phenstatement_id),
	gcontext_id int not null,
	foreign key (gcontext_id) references gcontext (gcontext_id) on delete cascade INITIALLY DEFERRED,
	dbxref_id int not null,
	foreign key (dbxref_id) references dbxref (dbxref_id) on delete cascade INITIALLY DEFERRED,
	observable_id	int not null,
	foreign key (observable_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
	attr_id	int,
	foreign key (attr_id) references cvterm (cvterm_id) on delete set null INITIALLY DEFERRED,
	value text,
	cvalue_id int,
	foreign key (cvalue_id) references cvterm (cvterm_id) on delete set null INITIALLY DEFERRED,
	assay_id int,
	foreign key (assay_id) references cvterm (cvterm_id) on delete set null INITIALLY DEFERRED,
    constraint phenstatement_c1 unique (gcontext_id,dbxref_id,observable_id)
);
create index phenstatement_idx1 on phenstatement (gcontext_id);
create index phenstatement_idx2 on phenstatement (observable_id);
create index phenstatement_idx3 on phenstatement (attr_id);

-- RELATION: phendesc
--
-- a summary of a _set_ of phenotypic statements for any one
-- gcontext made in any one
-- publication
-- 
--
create table phendesc (
	phendesc_id	serial not null,
	primary key (phendesc_id),
	gcontext_id	int not null,
	foreign key (gcontext_id) references gcontext (gcontext_id) on delete cascade INITIALLY DEFERRED,
	description	text not null,
    constraint phendesc_c1 unique (gcontext_id,description)
);
create index phendesc_idx1 on phendesc (gcontext_id);

-- RELATION: phenstatement_relationship
--
-- interaction (suppression, enhancement), rescue, complementation
-- are always relationships between phenstatements
-- 
--
create table phenstatement_relationship (
	phenstatement_relationship_id serial not null,
	primary key (phenstatement_relationship_id),
	subject_id int not null,
	foreign key (subject_id) references phenstatement (phenstatement_id) on delete cascade INITIALLY DEFERRED,
	object_id int not null,
	foreign key (object_id) references phenstatement (phenstatement_id) on delete cascade INITIALLY DEFERRED,
	type_id	int not null,
	foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
	comment_id int not null,
	foreign key (comment_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    constraint phenstatement_relationship_c1 unique (subject_id,object_id,type_id)
);
create index phenstatement_relationship_idx1 on phenstatement_relationship (subject_id);
create index phenstatement_relationship_idx2 on phenstatement_relationship (object_id);
create index phenstatement_relationship_idx3 on phenstatement_relationship (type_id);

-- RELATION: phenstatement_cvterm
--
-- arbitrary qualifiers
-- for anything that doesn't fit into obs/attr/val model
-- 
--
create table phenstatement_cvterm (
    phenstatement_cvterm_id serial not null,
    primary key (phenstatement_cvterm_id),
    phenstatement_id int not null,
    foreign key (phenstatement_id) references phenstatement (phenstatement_id) on delete cascade INITIALLY DEFERRED,
    cvterm_id int not null,
    foreign key (cvterm_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    constraint phenstatement_cvterm_c1 unique (phenstatement_id,cvterm_id)
);
create index phenstatement_cvterm_idx1 on phenstatement_cvterm (phenstatement_id);	
create index phenstatement_cvterm_idx2 on phenstatement_cvterm (cvterm_id);	

-- RELATION: phenstatementprop
--
-- arbitrary key=value pairs
-- e.g. penetrance_pct=80
-- 
-- value               : unconstrained free text value
--
create table phenstatementprop (
	phenstatementprop_id	serial not null,
	primary key (phenstatementprop_id),
	phenstatement_id	int not null,
	foreign key (phenstatement_id) references phenstatement (phenstatement_id) on delete cascade INITIALLY DEFERRED,
	type_id	int not null,
	foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
	value	text null,
	rank int not null default 0,
    constraint phenstatementprop_c1 unique (phenstatement_id,type_id,rank)
);
create index phenstatementprop_idx1 on phenstatementprop (phenstatement_id);
create index phenstatementprop_idx2 on phenstatementprop (type_id);
-- ================================================
-- TABLE: analysis
-- ================================================

-- an analysis is a particular type of a computational analysis;
-- it may be a blast of one sequence against another, or an all by all
-- blast, or a different kind of analysis altogether.
-- it is a single unit of computation 
--
-- name: 
--   a way of grouping analyses. this should be a handy
--   short identifier that can help people find an analysis they
--   want. for instance "tRNAscan", "cDNA", "FlyPep", "SwissProt"
--   it should not be assumed to be unique. for instance, there may
--   be lots of seperate analyses done against a cDNA database.
--
-- program: 
--   e.g. blastx, blastp, sim4, genscan
--
-- programversion:
--   e.g. TBLASTX 2.0MP-WashU [09-Nov-2000]
--
-- algorithm:
--   e.g. blast
--
-- sourcename: 
--   e.g. cDNA, SwissProt
--
-- queryfeature_id:
--   the sequence that was used as the query sequence can be
--   optionally included via queryfeature_id - even though this
--   is redundant with the tables below. this can still
--   be useful - for instance, we may have an analysis that blasts
--   contigs against a database. we may then transform those hits
--   into global coordinates; it may be useful to keep a record
--   of which contig was blasted as the query.
--
--
-- MAPPING (bioperl): maps to Bio::Search::Result::ResultI
-- ** not anymore, b/c we are using analysis in a more general sense
-- ** to represent microarray analysis

--
-- sourceuri: 
--   This is an optional permanent URL/URI for the source of the
--   analysis. The idea is that someone could recreate the analysis
--   directly by going to this URI and fetching the source data
--   (eg the blast database, or the training model).

create table analysis (
    analysis_id serial not null,
    primary key (analysis_id),
    name varchar(255),
    description text,
    program varchar(255) not null,
    programversion varchar(255) not null,
    algorithm varchar(255),
    sourcename varchar(255),
    sourceversion varchar(255),
    sourceuri text,
    timeexecuted timestamp not null default current_timestamp,
    constraint analysis_c1 unique (program,programversion,sourcename)
);

-- ================================================
-- TABLE: analysisprop
-- ================================================

create table analysisprop (
    analysisprop_id serial not null,
    primary key (analysisprop_id),
    analysis_id int not null,
    foreign key (analysis_id) references analysis (analysis_id) on delete cascade INITIALLY DEFERRED,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    value text,
    constraint analysisprop_c1 unique (analysis_id,type_id,value)
);
create index analysisprop_idx1 on analysisprop (analysis_id);
create index analysisprop_idx2 on analysisprop (type_id);

-- ================================================
-- TABLE: analysisfeature
-- ================================================

-- computational analyses generate features (eg genscan generates
-- transcripts and exons; sim4 alignments generate similarity/match
-- features)

-- analysisfeatures are stored using the feature table from
-- the sequence module. the analysisfeature table is used to
-- decorate these features, with analysis specific attributes.
--
-- a feature is an analysisfeature if and only if there is
-- a corresponding entry in the analysisfeature table
--
-- analysisfeatures will have two or more featureloc entries,
-- with rank indicating query/subject

--  analysis_id:
--    scoredsets are grouped into analyses
--
--  rawscore:
--    this is the native score generated by the program; for example,
--    the bitscore generated by blast, sim4 or genscan scores.
--    one should not assume that high is necessarily better than low.
--
--  normscore:
--    this is the rawscore but semi-normalized. complete normalization
--    to allow comparison of features generated by different programs
--    would be nice but too difficult. instead the normalization should
--    strive to enforce the following semantics:
--
--    * normscores are floating point numbers >= 0
--    * high normscores are better than low one.
--
--    for most programs, it would be sufficient to make the normscore
--    the same as this rawscore, providing these semantics are
--    satisfied.
--
--  significance:
--    this is some kind of expectation or probability metric,
--    representing the probability that the scoredset would appear
--    randomly given the model.
--    as such, any program or person querying this table can assume
--    the following semantics:
--     * 0 <= significance <= n, where n is a positive number, theoretically
--       unbounded but unlikely to be more than 10
--     * low numbers are better than high numbers.
--
--  identity:
--    percent identity between the locations compared
--
--  note that these 4 metrics do not cover the full range of scores
--  possible; it would be undesirable to list every score possible, as
--  this should be kept extensible. instead, for non-standard scores, use
--  the scoredsetprop table.

create table analysisfeature (
    analysisfeature_id serial not null,
    primary key (analysisfeature_id),
    feature_id int not null,
    foreign key (feature_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,
    analysis_id int not null,
    foreign key (analysis_id) references analysis (analysis_id) on delete cascade INITIALLY DEFERRED,
    rawscore double precision,
    normscore double precision,
    significance double precision,
    identity double precision,
    constraint analysisfeature_c1 unique (feature_id,analysis_id)
);
create index analysisfeature_idx1 on analysisfeature (feature_id);
create index analysisfeature_idx2 on analysisfeature (analysis_id);
-- NOTE: this module is all due for revision...

-- A possibly problematic case is where we want to localize an object
-- to the left or right of a feature (but not within it):
--
--                     |---------|  feature-to-map
--        ------------------------------------------------- map
--                |------|         |----------|   features to map wrt
--
-- How do we map the 3' end of the feature-to-map?

-- TODO:  Get a comprehensive set of mapping use-cases 

-- one set of use-cases is aberrations (which will all be involved with this 
-- module).   Simple aberrations should be do-able, but what about cases where
-- a breakpoint interrupts a gene?  This would be an example of the problematic
-- case above...  (or?)

-- ================================================
-- TABLE: featuremap
-- ================================================

create table featuremap (
    featuremap_id serial not null,
    primary key (featuremap_id),
    name varchar(255),
    description text,
    unittype_id int null,
    foreign key (unittype_id) references cvterm (cvterm_id) on delete set null INITIALLY DEFERRED,
    constraint featuremap_c1 unique (name)
);

-- ================================================
-- TABLE: featurerange
-- ================================================

-- In cases where the start and end of a mapped feature is a range, leftendf
-- and rightstartf are populated.  
-- featuremap_id is the id of the feature being mapped
-- leftstartf_id, leftendf_id, rightstartf_id, rightendf_id are the ids of
-- features with respect to with the feature is being mapped.  These may
-- be cytological bands.

create table featurerange (
    featurerange_id serial not null,
    primary key (featurerange_id),
    featuremap_id int not null,
    foreign key (featuremap_id) references featuremap (featuremap_id) on delete cascade INITIALLY DEFERRED,
    feature_id int not null,
    foreign key (feature_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,
    leftstartf_id int not null,
    foreign key (leftstartf_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,
    leftendf_id int,
    foreign key (leftendf_id) references feature (feature_id) on delete set null INITIALLY DEFERRED,
    rightstartf_id int,
    foreign key (rightstartf_id) references feature (feature_id) on delete set null INITIALLY DEFERRED,
    rightendf_id int not null,
    foreign key (rightendf_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,
    rangestr varchar(255)
);
create index featurerange_idx1 on featurerange (featuremap_id);
create index featurerange_idx2 on featurerange (feature_id);
create index featurerange_idx3 on featurerange (leftstartf_id);
create index featurerange_idx4 on featurerange (leftendf_id);
create index featurerange_idx5 on featurerange (rightstartf_id);
create index featurerange_idx6 on featurerange (rightendf_id);

-- ================================================
-- TABLE: featurepos
-- ================================================

create table featurepos (
    featurepos_id serial not null,
    primary key (featurepos_id),
    featuremap_id serial not null,
    foreign key (featuremap_id) references featuremap (featuremap_id) on delete cascade INITIALLY DEFERRED,
    feature_id int not null,
    foreign key (feature_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,
    map_feature_id int not null,
    foreign key (map_feature_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,
    mappos float not null
);
-- map_feature_id links to the feature (map) upon which the feature is
-- being localized
create index featurepos_idx1 on featurepos (featuremap_id);
create index featurepos_idx2 on featurepos (feature_id);
create index featurepos_idx3 on featurepos (map_feature_id);


-- ================================================
-- TABLE: featuremap_pub
-- ================================================

create table featuremap_pub (
    featuremap_pub_id serial not null,
    primary key (featuremap_pub_id),
    featuremap_id int not null,
    foreign key (featuremap_id) references featuremap (featuremap_id) on delete cascade INITIALLY DEFERRED,
    pub_id int not null,
    foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED
);
create index featuremap_pub_idx1 on featuremap_pub (featuremap_id);
create index featuremap_pub_idx2 on featuremap_pub (pub_id);





-- VIEW gffatts: a view to get feature attributes in a format that
-- will make it easy to convert them to GFF attributes

CREATE OR REPLACE VIEW gffatts (
    feature_id,
    type,
    attribute
) AS
SELECT feature_id, 'cvterm' AS type,  s.name AS attribute
FROM cvterm s, feature_cvterm fs
WHERE fs.cvterm_id = s.cvterm_id
UNION ALL
SELECT feature_id, 'dbxref' AS type, d.name || ':' || s.accession AS attribute
FROM dbxref s, feature_dbxref fs, db d
WHERE fs.dbxref_id = s.dbxref_id and s.db_id = d.db_id
--SELECT feature_id, 'expression' AS type, s.description AS attribute
--FROM expression s, feature_expression fs
--WHERE fs.expression_id = s.expression_id
UNION ALL
SELECT fg.feature_id, 'genotype' AS type, g.uniquename||': '||g.description AS attribute
FROM gcontext g, feature_gcontext fg
WHERE g.gcontext_id = fg.gcontext_id
--UNION ALL
--SELECT feature_id, 'genotype' AS type, s.description AS attribute
--FROM genotype s, feature_genotype fs
--WHERE fs.genotype_id = s.genotype_id
--UNION ALL
--SELECT feature_id, 'phenotype' AS type, s.description AS attribute
--FROM phenotype s, feature_phenotype fs
--WHERE fs.phenotype_id = s.phenotype_id
UNION ALL
SELECT feature_id, 'synonym' AS type, s.name AS attribute
FROM synonym s, feature_synonym fs
WHERE fs.synonym_id = s.synonym_id
UNION ALL
SELECT fp.feature_id,cv.name,fp.value
FROM featureprop fp, cvterm cv
WHERE fp.type_id = cv.cvterm_id
UNION ALL
SELECT feature_id, 'pub' AS type, s.series_name || ':' || s.title AS attribute
FROM pub s, feature_pub fs
WHERE fs.pub_id = s.pub_id;

--creates a view that can be used to assemble a GFF3 compliant attribute string
CREATE OR REPLACE VIEW gff3atts (
    feature_id,
    type,
    attribute
) AS
SELECT feature_id, 'Ontology_term' AS type,  dbx.accession AS attribute
FROM cvterm s, dbxref dbx, feature_cvterm fs
WHERE fs.cvterm_id = s.cvterm_id and s.dbxref_id=dbx.dbxref_id
UNION ALL
SELECT feature_id, 'Dbxref' AS type, d.name || ':' || s.accession AS attribute
FROM dbxref s, feature_dbxref fs, db d
WHERE fs.dbxref_id = s.dbxref_id and s.db_id = d.db_id and
      d.name != 'GFF_source'
UNION ALL
SELECT fg.feature_id, 'genotype' AS type, g.uniquename||': '||g.description AS attribute
FROM gcontext g, feature_gcontext fg
WHERE g.gcontext_id = fg.gcontext_id
UNION ALL
SELECT f.feature_id, 'Alias' AS type, s.name AS attribute
FROM synonym s, feature_synonym fs, feature f
WHERE fs.synonym_id = s.synonym_id and f.feature_id = fs.feature_id and
      f.name != s.name
UNION ALL
SELECT fp.feature_id,cv.name,fp.value
FROM featureprop fp, cvterm cv
WHERE fp.type_id = cv.cvterm_id
UNION ALL
SELECT feature_id, 'pub' AS type, s.series_name || ':' || s.title AS attribute
FROM pub s, feature_pub fs
WHERE fs.pub_id = s.pub_id;


create table mageml (
    mageml_id serial not null,
    primary key (mageml_id),
    mage_package text not null,
    mage_ml text not null
);

COMMENT ON TABLE mageml IS 'this table is for storing extra bits of mageml in a denormalized form.  more normalization would require many more tables';

create table magedocumentation (
    magedocumentation_id serial not null,
    primary key (magedocumentation_id),
    mageml_id int not null,
    foreign key (mageml_id) references mageml (mageml_id) on delete cascade INITIALLY DEFERRED,
    tableinfo_id int not null,
    foreign key (tableinfo_id) references tableinfo (tableinfo_id) on delete cascade INITIALLY DEFERRED,
    row_id int not null,
    mageidentifier text not null
);
create index magedocumentation_idx1 on magedocumentation (mageml_id);
create index magedocumentation_idx2 on magedocumentation (tableinfo_id);
create index magedocumentation_idx3 on magedocumentation (row_id);

COMMENT ON TABLE magedocumentation IS NULL;

create table protocol (
    protocol_id serial not null,
    primary key (protocol_id),
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    pub_id int null,
    foreign key (pub_id) references pub (pub_id) on delete set null INITIALLY DEFERRED,
    dbxref_id int null,
    foreign key (dbxref_id) references dbxref (dbxref_id) on delete set null INITIALLY DEFERRED,
    name text not null,
    uri text null,
    protocoldescription text null,
    hardwaredescription text null,
    softwaredescription text null,
    constraint protocol_c1 unique (name)
);
create index protocol_idx1 on protocol (type_id);
create index protocol_idx2 on protocol (pub_id);
create index protocol_idx3 on protocol (dbxref_id);

COMMENT ON TABLE protocol IS 'procedural notes on how data was prepared and processed';

create table protocolparam (
    protocolparam_id serial not null,
    primary key (protocolparam_id),
    protocol_id int not null,
    foreign key (protocol_id) references protocol (protocol_id) on delete cascade INITIALLY DEFERRED,
    name text not null,
    datatype_id int null,
    foreign key (datatype_id) references cvterm (cvterm_id) on delete set null INITIALLY DEFERRED,
    unittype_id int null,
    foreign key (unittype_id) references cvterm (cvterm_id) on delete set null INITIALLY DEFERRED,
    value text null,
    rank int not null default 0
);
create index protocolparam_idx1 on protocolparam (protocol_id);
create index protocolparam_idx2 on protocolparam (datatype_id);
create index protocolparam_idx3 on protocolparam (unittype_id);

COMMENT ON TABLE protocolparam IS 'parameters related to a protocol.  if the protocol is a soak, this might include attributes of bath temperature and duration';

create table channel (
    channel_id serial not null,
    primary key (channel_id),
    name text not null,
    definition text not null,
    constraint channel_c1 unique (name)
);

COMMENT ON TABLE channel IS 'different array platforms can record signals from one or more channels (cDNA arrays typically use two CCD, but affy uses only one)';

create table arraydesign (
    arraydesign_id serial not null,
    primary key (arraydesign_id),
    manufacturer_id int not null,
    foreign key (manufacturer_id) references contact (contact_id) on delete cascade INITIALLY DEFERRED,
    platformtype_id int not null,
    foreign key (platformtype_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    substratetype_id int null,
    foreign key (substratetype_id) references cvterm (cvterm_id) on delete set null INITIALLY DEFERRED,
    protocol_id int null,
    foreign key (protocol_id) references protocol (protocol_id) on delete set null INITIALLY DEFERRED,
    dbxref_id int null,
    foreign key (dbxref_id) references dbxref (dbxref_id) on delete set null INITIALLY DEFERRED,
    name text not null,
    version text null,
    description text null,
    array_dimensions text null,
    element_dimensions text null,
    num_of_elements int null,
    num_array_columns int null,
    num_array_rows int null,
    num_grid_columns int null,
    num_grid_rows int null,
    num_sub_columns int null,
    num_sub_rows int null,
    constraint arraydesign_c1 unique (name)
);
create index arraydesign_idx1 on arraydesign (manufacturer_id);
create index arraydesign_idx2 on arraydesign (platformtype_id);
create index arraydesign_idx3 on arraydesign (substratetype_id);
create index arraydesign_idx4 on arraydesign (protocol_id);
create index arraydesign_idx5 on arraydesign (dbxref_id);

COMMENT ON TABLE arraydesign IS 'general properties about an array.  and array is a template used to generate physical slides, etc.  it contains layout information, as well as global array properties, such as material (glass, nylon) and spot dimensions(in rows/columns).';

create table arraydesignprop (
    arraydesignprop_id serial not null,
    primary key (arraydesignprop_id),
    arraydesign_id int not null,
    foreign key (arraydesign_id) references arraydesign (arraydesign_id) on delete cascade INITIALLY DEFERRED,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    value text null,
    rank int not null default 0,
    constraint arraydesignprop_c1 unique (arraydesign_id,type_id,rank)
);
create index arraydesignprop_idx1 on arraydesignprop (arraydesign_id);
create index arraydesignprop_idx2 on arraydesignprop (type_id);

COMMENT ON TABLE arraydesignprop IS 'extra arraydesign properties that are not accounted for in arraydesign';

create table assay (
    assay_id serial not null,
    primary key (assay_id),
    arraydesign_id int not null,
    foreign key (arraydesign_id) references arraydesign (arraydesign_id) on delete cascade INITIALLY DEFERRED,
    protocol_id int null,
    foreign key (protocol_id) references protocol (protocol_id) on delete set null INITIALLY DEFERRED,
    assaydate timestamp null default current_timestamp,
    arrayidentifier text null,
    arraybatchidentifier text null,
    operator_id int not null,
    foreign key (operator_id) references contact (contact_id) on delete cascade INITIALLY DEFERRED,
    dbxref_id int null,
    foreign key (dbxref_id) references dbxref (dbxref_id) on delete set null INITIALLY DEFERRED,
    name text null,
    description text null,
    constraint assay_c1 unique (name)
);
create index assay_idx1 on assay (arraydesign_id);
create index assay_idx2 on assay (protocol_id);
create index assay_idx3 on assay (operator_id);
create index assay_idx4 on assay (dbxref_id);

COMMENT ON TABLE assay IS 'an assay consists of a physical instance of an array, combined with the conditions used to create the array (protocols, technician info).  the assay can be thought of as a hybridization';

create table assayprop (
    assayprop_id serial not null,
    primary key (assayprop_id),
    assay_id int not null,
    foreign key (assay_id) references assay (assay_id) on delete cascade INITIALLY DEFERRED,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    value text null,
    rank int not null default 0,
    constraint assayprop_c1 unique (assay_id,type_id,rank)
);
create index assayprop_idx1 on assayprop (assay_id);
create index assayprop_idx2 on assayprop (type_id);

COMMENT ON TABLE assayprop IS 'extra assay properties that are not accounted for in assay';

create table assay_project (
    assay_project_id serial not null,
    primary key (assay_project_id),
    assay_id int not null,
    foreign key (assay_id) references assay (assay_id) INITIALLY DEFERRED,
    project_id int not null,
    foreign key (project_id) references project (project_id) INITIALLY DEFERRED,
    constraint assay_project_c1 unique (assay_id,project_id)
);
create index assay_project_idx1 on assay_project (assay_id);
create index assay_project_idx2 on assay_project (project_id);

COMMENT ON TABLE assay_project IS 'link assays to projects';

create table biomaterial (
    biomaterial_id serial not null,
    primary key (biomaterial_id),
    taxon_id int null,
    foreign key (taxon_id) references organism (organism_id) on delete set null INITIALLY DEFERRED,
    biosourceprovider_id int null,
    foreign key (biosourceprovider_id) references contact (contact_id) on delete set null INITIALLY DEFERRED,
    dbxref_id int null,
    foreign key (dbxref_id) references dbxref (dbxref_id) on delete set null INITIALLY DEFERRED,
    name text null,
    description text null,
    constraint biomaterial_c1 unique (name)
);
create index biomaterial_idx1 on biomaterial (taxon_id);
create index biomaterial_idx2 on biomaterial (biosourceprovider_id);
create index biomaterial_idx3 on biomaterial (dbxref_id);

COMMENT ON TABLE biomaterial IS 'a biomaterial represents the MAGE concept of BioSource, BioSample, and LabeledExtract.  it is essentially some biological material (tissue, cells, serum) that may have been processed.  processed biomaterials should be traceable back to raw biomaterials via the biomaterialrelationship table.';

create table biomaterial_relationship (
    biomaterial_relationship_id serial not null,
    primary key (biomaterial_relationship_id),
    subject_id int not null,
    foreign key (subject_id) references biomaterial (biomaterial_id) INITIALLY DEFERRED,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) INITIALLY DEFERRED,
    object_id int not null,
    foreign key (object_id) references biomaterial (biomaterial_id) INITIALLY DEFERRED,
    constraint biomaterial_relationship_c1 unique (subject_id,object_id,type_id)
);
create index biomaterial_relationship_idx1 on biomaterial_relationship (subject_id);
create index biomaterial_relationship_idx2 on biomaterial_relationship (object_id);
create index biomaterial_relationship_idx3 on biomaterial_relationship (type_id);

COMMENT ON TABLE biomaterial_relationship IS 'relate biomaterials to one another.  this is a way to track a series of treatments or material splits/merges, for instance';

create table biomaterialprop (
    biomaterialprop_id serial not null,
    primary key (biomaterialprop_id),
    biomaterial_id int not null,
    foreign key (biomaterial_id) references biomaterial (biomaterial_id) on delete cascade INITIALLY DEFERRED,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    value text null,
    rank int not null,
    constraint biomaterialprop_c1 unique (biomaterial_id,type_id,rank)
);
create index biomaterialprop_idx1 on biomaterialprop (biomaterial_id);
create index biomaterialprop_idx2 on biomaterialprop (type_id);

COMMENT ON TABLE biomaterialprop IS 'extra biomaterial properties that are not accounted for in biomaterial';

create table treatment (
    treatment_id serial not null,
    primary key (treatment_id),
    rank int not null default 0,
    biomaterial_id int not null,
    foreign key (biomaterial_id) references biomaterial (biomaterial_id) on delete cascade INITIALLY DEFERRED,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    protocol_id int null,
    foreign key (protocol_id) references protocol (protocol_id) on delete set null INITIALLY DEFERRED,
    name text null
);
create index treatment_idx1 on treatment (biomaterial_id);
create index treatment_idx2 on treatment (type_id);
create index treatment_idx3 on treatment (protocol_id);

COMMENT ON TABLE treatment IS 'a biomaterial may undergo multiple treatments.  this can range from apoxia to fluorophore and biotin labeling';

create table biomaterial_treatment (
    biomaterial_treatment_id serial not null,
    primary key (biomaterial_treatment_id),
    biomaterial_id int not null,
    foreign key (biomaterial_id) references biomaterial (biomaterial_id) on delete cascade INITIALLY DEFERRED,
    treatment_id int not null,
    foreign key (treatment_id) references treatment (treatment_id) on delete cascade INITIALLY DEFERRED,
    unittype_id int null,
    foreign key (unittype_id) references cvterm (cvterm_id) on delete set null INITIALLY DEFERRED,
    value float(15) null,
    rank int not null default 0,
    constraint biomaterial_treatment_c1 unique (biomaterial_id,treatment_id)
);
create index biomaterial_treatment_idx1 on biomaterial_treatment (biomaterial_id);
create index biomaterial_treatment_idx2 on biomaterial_treatment (treatment_id);
create index biomaterial_treatment_idx3 on biomaterial_treatment (unittype_id);

COMMENT ON TABLE biomaterial_treatment IS 'link biomaterials to treatments.  treatments have an order of operations (rank), and associated measurements (unittype_id, value)';

create table assay_biomaterial (
    assay_biomaterial_id serial not null,
    primary key (assay_biomaterial_id),
    assay_id int not null,
    foreign key (assay_id) references assay (assay_id) on delete cascade INITIALLY DEFERRED,
    biomaterial_id int not null,
    foreign key (biomaterial_id) references biomaterial (biomaterial_id) on delete cascade INITIALLY DEFERRED,
    channel_id int null,
    foreign key (channel_id) references channel (channel_id) on delete set null INITIALLY DEFERRED,
    constraint assay_biomaterial_c1 unique (assay_id,biomaterial_id,channel_id)
);
create index assay_biomaterial_idx1 on assay_biomaterial (assay_id);
create index assay_biomaterial_idx2 on assay_biomaterial (biomaterial_id);
create index assay_biomaterial_idx3 on assay_biomaterial (channel_id);

COMMENT ON TABLE assay_biomaterial IS 'a biomaterial can be hybridized many times (technical replicates), or combined with other biomaterials in a single hybridization (for two-channel arrays)';

create table acquisition (
    acquisition_id serial not null,
    primary key (acquisition_id),
    assay_id int not null,
    foreign key (assay_id) references  assay (assay_id) on delete cascade INITIALLY DEFERRED,
    protocol_id int null,
    foreign key (protocol_id) references protocol (protocol_id) on delete set null INITIALLY DEFERRED,
    channel_id int null,
    foreign key (channel_id) references channel (channel_id) on delete set null INITIALLY DEFERRED,
    acquisitiondate timestamp null default current_timestamp,
    name text null,
    uri text null,
    constraint acquisition_c1 unique (name)
);
create index acquisition_idx1 on acquisition (assay_id);
create index acquisition_idx2 on acquisition (protocol_id);
create index acquisition_idx3 on acquisition (channel_id);

COMMENT ON TABLE acquisition IS 'this represents the scanning of hybridized material.  the output of this process is typically a digital image of an array';

create table acquisitionprop (
    acquisitionprop_id serial not null,
    primary key (acquisitionprop_id),
    acquisition_id int not null,
    foreign key (acquisition_id) references acquisition (acquisition_id) on delete cascade INITIALLY DEFERRED,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    value text null,
    rank int not null default 0,
    constraint acquisitionprop_c1 unique (acquisition_id,type_id,rank)
);
create index acquisitionprop_idx1 on acquisitionprop (acquisition_id);
create index acquisitionprop_idx2 on acquisitionprop (type_id);

COMMENT ON TABLE acquisitionprop IS 'parameters associated with image acquisition';

create table acquisition_relationship (
    acquisition_relationship_id serial not null,
    primary key (acquisition_relationship_id),
    subject_id int not null,
    foreign key (subject_id) references acquisition (acquisition_id) on delete cascade INITIALLY DEFERRED,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    object_id int not null,
    foreign key (object_id) references acquisition (acquisition_id) on delete cascade INITIALLY DEFERRED,
    value text null,
    rank int not null default 0,
    constraint acquisition_relationship_c1 unique (subject_id,object_id,type_id,rank)
);
create index acquisition_relationship_idx1 on acquisition_relationship (subject_id);
create index acquisition_relationship_idx2 on acquisition_relationship (type_id);
create index acquisition_relationship_idx3 on acquisition_relationship (object_id);

COMMENT ON TABLE acquisition_relationship IS 'multiple monochrome images may be merged to form a multi-color image.  red-green images of 2-channel hybridizations are an example of this';

create table quantification (
    quantification_id serial not null,
    primary key (quantification_id),
    acquisition_id int not null,
    foreign key (acquisition_id) references acquisition (acquisition_id) on delete cascade INITIALLY DEFERRED,
    operator_id int null,
    foreign key (operator_id) references contact (contact_id) on delete set null INITIALLY DEFERRED,
    protocol_id int null,
    foreign key (protocol_id) references protocol (protocol_id) on delete set null INITIALLY DEFERRED,
    analysis_id int not null,
    foreign key (analysis_id) references analysis (analysis_id) on delete cascade INITIALLY DEFERRED,
    quantificationdate timestamp null default current_timestamp,
    name text null,
    uri text null,
    constraint quantification_c1 unique (name,analysis_id)
);
create index quantification_idx1 on quantification (acquisition_id);
create index quantification_idx2 on quantification (operator_id);
create index quantification_idx3 on quantification (protocol_id);
create index quantification_idx4 on quantification (analysis_id);

COMMENT ON TABLE quantification IS 'quantification is the transformation of an image acquisition to numeric data.  this typically involves statistical procedures.';

create table quantificationprop (
    quantificationprop_id serial not null,
    primary key (quantificationprop_id),
    quantification_id int not null,
    foreign key (quantification_id) references quantification (quantification_id) on delete cascade INITIALLY DEFERRED,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    value text null,
    rank int not null default 0,
    constraint quantificationprop_c1 unique (quantification_id,type_id,rank)
);
create index quantificationprop_idx1 on quantificationprop (quantification_id);
create index quantificationprop_idx2 on quantificationprop (type_id);

COMMENT ON TABLE quantificationprop IS 'extra quantification properties that are not accounted for in quantification';

create table quantification_relationship (
    quantification_relationship_id serial not null,
    primary key (quantification_relationship_id),
    subject_id int not null,
    foreign key (subject_id) references quantification (quantification_id) on delete cascade INITIALLY DEFERRED,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    object_id int not null,
    foreign key (object_id) references quantification (quantification_id) on delete cascade INITIALLY DEFERRED,
    constraint quantification_relationship_c1 unique (subject_id,object_id,type_id)
);
create index quantification_relationship_idx1 on quantification_relationship (subject_id);
create index quantification_relationship_idx2 on quantification_relationship (type_id);
create index quantification_relationship_idx3 on quantification_relationship (object_id);

COMMENT ON TABLE quantification_relationship IS 'there may be multiple rounds of quantification, this allows us to keep an audit trail of what values went where';

create table control (
    control_id serial not null,
    primary key (control_id),
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    assay_id int not null,
    foreign key (assay_id) references assay (assay_id) on delete cascade INITIALLY DEFERRED,
    tableinfo_id int not null,
    foreign key (tableinfo_id) references tableinfo (tableinfo_id) on delete cascade INITIALLY DEFERRED,
    row_id int not null,
    name text null,
    value text null,
    rank int not null default 0
);
create index control_idx1 on control (type_id);
create index control_idx2 on control (assay_id);
create index control_idx3 on control (tableinfo_id);
create index control_idx4 on control (row_id);

COMMENT ON TABLE control IS NULL;

create table element (
    element_id serial not null,
    primary key (element_id),
    feature_id int null,
    foreign key (feature_id) references feature (feature_id) on delete set null INITIALLY DEFERRED,
    arraydesign_id int not null,
    foreign key (arraydesign_id) references arraydesign (arraydesign_id) on delete cascade INITIALLY DEFERRED,
    type_id int null,
    foreign key (type_id) references cvterm (cvterm_id) on delete set null INITIALLY DEFERRED,
    dbxref_id int null,
    foreign key (dbxref_id) references dbxref (dbxref_id) on delete set null INITIALLY DEFERRED,
    subclass_view varchar(27) not null,
    tinyint1 int null,
    smallint1 int null,
    smallint2 int null,
    char1 varchar(5) null,
    char2 varchar(5) null,
    char3 varchar(5) null,
    char4 varchar(5) null,
    char5 varchar(5) null,
    char6 varchar(5) null,
    char7 varchar(5) null,
    tinystring1 varchar(50) null,
    tinystring2 varchar(50) null,
    smallstring1 varchar(100) null,
    smallstring2 varchar(100) null,
    string1 varchar(500) null,
    string2 varchar(500) null,
    constraint element_c1 unique (feature_id,arraydesign_id)
);
create index element_idx1 on element (feature_id);
create index element_idx2 on element (arraydesign_id);
create index element_idx3 on element (type_id);
create index element_idx4 on element (dbxref_id);
create index element_idx5 on element (subclass_view);

COMMENT ON TABLE element IS 'represents a feature of the array.  this is typically a region of the array coated or bound to DNA';

create table elementresult (
    elementresult_id serial not null,
    primary key (elementresult_id),
    element_id int not null,
    foreign key (element_id) references element (element_id) on delete cascade INITIALLY DEFERRED,
    quantification_id int not null,
    foreign key (quantification_id) references quantification (quantification_id) on delete cascade INITIALLY DEFERRED,
    subclass_view varchar(27) not null,
    foreground float(15) null,
    background float(15) null,
    foreground_sd float(15) null,
    background_sd float(15) null,
    float1 float(15) null,
    float2 float(15) null,
    float3 float(15) null,
    float4 float(15) null,
    float5 float(15) null,
    float6 float(15) null,
    float7 float(15) null,
    float8 float(15) null,
    float9 float(15) null,
    float10 float(15) null,
    int1 int null,
    int2 int null,
    int3 int null,
    int4 int null,
    int5 int null,
    int6 int null,
    tinyint1 int null,
    tinyint2 int null,
    tinyint3 int null,
    smallint1 int null,
    smallint2 int null,
    char1 varchar(5) null,
    char2 varchar(5) null,
    char3 varchar(5) null,
    char4 varchar(5) null,
    char5 varchar(5) null,
    char6 varchar(5) null,
    tinystring1 varchar(50) null,
    tinystring2 varchar(50) null,
    tinystring3 varchar(50) null,
    smallstring1 varchar(100) null,
    smallstring2 varchar(100) null,
    string1 varchar(500) null,
    string2 varchar(500) null,
    constraint elementresult_c1 unique (element_id,quantification_id,subclass_view)
);
create index elementresult_idx1 on elementresult (element_id);
create index elementresult_idx2 on elementresult (quantification_id);
create index elementresult_idx3 on elementresult (subclass_view);

COMMENT ON TABLE elementresult IS 'an element on an array produces a measurement when hybridized to a biomaterial (traceable through quantification_id).  this is the "real" data from the microarray hybridization.  the fields of this table are intentionally generic so that many different platforms can be stored in a common table.  each platform should have a corresponding view onto this table, mapping specific parameters of the platform to generic columns';

create table element_relationship (
    element_relationship_id serial not null,
    primary key (element_relationship_id),
    subject_id int not null,
    foreign key (subject_id) references element (element_id) INITIALLY DEFERRED,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) INITIALLY DEFERRED,
    object_id int not null,
    foreign key (object_id) references element (element_id) INITIALLY DEFERRED,
    value text null,
    rank int not null default 0,
    constraint element_relationship_c1 unique (subject_id,object_id,type_id,rank)
);
create index element_relationship_idx1 on element_relationship (subject_id);
create index element_relationship_idx2 on element_relationship (type_id);
create index element_relationship_idx3 on element_relationship (object_id);
create index element_relationship_idx4 on element_relationship (value);

COMMENT ON TABLE element_relationship IS 'sometimes we want to combine measurements from multiple elements to get a composite value.  affy combines many probes to form a probeset measurement, for instance';

create table elementresult_relationship (
    elementresult_relationship_id serial not null,
    primary key (elementresult_relationship_id),
    subject_id int not null,
    foreign key (subject_id) references elementresult (elementresult_id) INITIALLY DEFERRED,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) INITIALLY DEFERRED,
    object_id int not null,
    foreign key (object_id) references elementresult (elementresult_id) INITIALLY DEFERRED,
    value text null,
    rank int not null default 0,
    constraint elementresult_relationship_c1 unique (subject_id,object_id,type_id,rank)
);
create index elementresult_relationship_idx1 on elementresult_relationship (subject_id);
create index elementresult_relationship_idx2 on elementresult_relationship (type_id);
create index elementresult_relationship_idx3 on elementresult_relationship (object_id);
create index elementresult_relationship_idx4 on elementresult_relationship (value);

COMMENT ON TABLE elementresult_relationship IS 'sometimes we want to combine measurements from multiple elements to get a composite value.  affy combines many probes to form a probeset measurement, for instance';

create table study (
    study_id serial not null,
    primary key (study_id),
    contact_id int not null,
    foreign key (contact_id) references contact (contact_id) on delete cascade INITIALLY DEFERRED,
    pub_id int null,
    foreign key (pub_id) references pub (pub_id) on delete set null INITIALLY DEFERRED,
    dbxref_id int null,
    foreign key (dbxref_id) references dbxref (dbxref_id) on delete set null INITIALLY DEFERRED,
    name text not null,
    description text null,
    constraint study_c1 unique (name)
);
create index study_idx1 on study (contact_id);
create index study_idx2 on study (pub_id);
create index study_idx3 on study (dbxref_id);

COMMENT ON TABLE study IS NULL;

create table study_assay (
    study_assay_id serial not null,
    primary key (study_assay_id),
    study_id int not null,
    foreign key (study_id) references study (study_id) on delete cascade INITIALLY DEFERRED,
    assay_id int not null,
    foreign key (assay_id) references assay (assay_id) on delete cascade INITIALLY DEFERRED,
    constraint study_assay_c1 unique (study_id,assay_id)
);
create index study_assay_idx1 on study_assay (study_id);
create index study_assay_idx2 on study_assay (assay_id);

COMMENT ON TABLE study_assay IS NULL;

create table studydesign (
    studydesign_id serial not null,
    primary key (studydesign_id),
    study_id int not null,
    foreign key (study_id) references study (study_id) on delete cascade INITIALLY DEFERRED,
    description text null
);
create index studydesign_idx1 on studydesign (study_id);

COMMENT ON TABLE studydesign IS NULL;

create table studydesignprop (
    studydesignprop_id serial not null,
    primary key (studydesignprop_id),
    studydesign_id int not null,
    foreign key (studydesign_id) references studydesign (studydesign_id) on delete cascade INITIALLY DEFERRED,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    value text null,
    rank int not null default 0,
    constraint studydesignprop_c1 unique (studydesign_id,type_id,rank)
);
create index studydesignprop_idx1 on studydesignprop (studydesign_id);
create index studydesignprop_idx2 on studydesignprop (type_id);

COMMENT ON TABLE studydesignprop IS NULL;

create table studyfactor (
    studyfactor_id serial not null,
    primary key (studyfactor_id),
    studydesign_id int not null,
    foreign key (studydesign_id) references studydesign (studydesign_id) on delete cascade INITIALLY DEFERRED,
    type_id int null,
    foreign key (type_id) references cvterm (cvterm_id) on delete set null INITIALLY DEFERRED,
    name text not null,
    description text null
);
create index studyfactor_idx1 on studyfactor (studydesign_id);
create index studyfactor_idx2 on studyfactor (type_id);

COMMENT ON TABLE studyfactor IS NULL;

create table studyfactorvalue (
    studyfactorvalue_id serial not null,
    primary key (studyfactorvalue_id),
    studyfactor_id int not null,
    foreign key (studyfactor_id) references studyfactor (studyfactor_id) on delete cascade INITIALLY DEFERRED,
    assay_id int not null,
    foreign key (assay_id) references assay (assay_id) on delete cascade INITIALLY DEFERRED,
    factorvalue text null,
    name text null,
    rank int not null default 0
);
create index studyfactorvalue_idx1 on studyfactorvalue (studyfactor_id);
create index studyfactorvalue_idx2 on studyfactorvalue (assay_id);

COMMENT ON TABLE studyfactorvalue IS NULL;
-- This module is totally dependant on the sequence module.  Objects in the
-- genetic module cannot connect to expression data except by going via the
-- sequence module

-- We assume that we'll *always* have a controlled vocabulary for expression 
-- data.   If an experiment used a set of cv terms different from the ones
-- FlyBase uses (bodypart cv, bodypart qualifier cv, and the temporal cv
-- (which is stored in the curaton.doc under GAT6 btw)), they'd have to give
-- us the cv terms, which we could load into the cv module

-- ================================================
-- TABLE: expression
-- ================================================

create table expression (
       expression_id serial not null,
       primary key (expression_id),
       description text
);

-- ================================================
-- TABLE: feature_expression
-- ================================================

create table feature_expression (
       feature_expression_id serial not null,
       primary key (feature_expression_id),
       expression_id int not null,
       foreign key (expression_id) references expression (expression_id) on delete cascade INITIALLY DEFERRED,
       feature_id int not null,
       foreign key (feature_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,

       unique(expression_id,feature_id)       
);
create index feature_expression_idx1 on feature_expression (expression_id);
create index feature_expression_idx2 on feature_expression (feature_id);


-- ================================================
-- TABLE: expression_cvterm
-- ================================================

-- What are the possibities of combination when more than one cvterm is used
-- in a field?   
--
-- For eg (in <p> here):   <t> E | early <a> <p> anterior & dorsal
-- If the two terms used in a particular field are co-equal (both from the
-- same CV, is the relation always "&"?   May we find "or"?
--
-- Obviously another case is when a bodypart term and a bodypart qualifier
-- term are used in a specific field, eg:
--   <t> L | third instar <a> larval antennal segment sensilla | subset <p  
--
-- WRT the three-part <t><a><p> statements, are the values in the different 
-- parts *always* from different vocabularies in proforma.CV?   If not,
-- we'll need to have some kind of type qualifier telling us whether the
-- cvterm used is <t>, <a>, or <p>
-- yes we should have a type qualifier as a cv term can be from diff vocab
-- e.g. blastoderm can be body part and stage terms in dros anatomy
-- but cvterm_type needs to be a cv instead of a free text type here?

create table expression_cvterm (
       expression_cvterm_id serial not null,
       primary key (expression_cvterm_id),
       expression_id int not null,
       foreign key (expression_id) references expression (expression_id) on delete cascade INITIALLY DEFERRED,
       cvterm_id int not null,
       foreign key (cvterm_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
       rank int not null,
	   cvterm_type varchar(255),

       unique(expression_id,cvterm_id)
);
create index expression_cvterm_idx1 on expression_cvterm (expression_id);
create index expression_cvterm_idx2 on expression_cvterm (cvterm_id);


-- ================================================
-- TABLE: expression_pub
-- ================================================

create table expression_pub (
       expression_pub_id serial not null,
       primary key (expression_pub_id),
       expression_id int not null,
       foreign key (expression_id) references expression (expression_id) on delete cascade INITIALLY DEFERRED,
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,

       unique(expression_id,pub_id)       
);
create index expression_pub_idx1 on expression_pub (expression_id);
create index expression_pub_idx2 on expression_pub (pub_id);


-- ================================================
-- TABLE: eimage
-- ================================================

create table eimage (
       eimage_id serial not null,
       primary key (eimage_id),
       eimage_data text,
       eimage_type varchar(255) not null,
       image_uri varchar(255)
);
-- we expect images in eimage_data (eg jpegs) to be uuencoded
-- describes the type of data in eimage_data


-- ================================================
-- TABLE: expression_image
-- ================================================

create table expression_image (
       expression_image_id serial not null,
       primary key (expression_image_id),
       expression_id int not null,
       foreign key (expression_id) references expression (expression_id) on delete cascade INITIALLY DEFERRED,
       eimage_id int not null,
       foreign key (eimage_id) references eimage (eimage_id) on delete cascade INITIALLY DEFERRED,

       unique(expression_id,eimage_id)
);
create index expression_image_idx1 on expression_image (expression_id);
create index expression_image_idx2 on expression_image (eimage_id);
-- FUNCTION gfffeatureatts (integer) is a function to get 
-- data in the same format as the gffatts view so that 
-- it can be easily converted to GFF attributes.

CREATE FUNCTION  gfffeatureatts (integer)
RETURNS SETOF gffatts
AS
'
SELECT feature_id, ''cvterm'' AS type,  s.name AS attribute
FROM cvterm s, feature_cvterm fs
WHERE fs.feature_id= $1 AND fs.cvterm_id = s.cvterm_id
UNION
SELECT feature_id, ''dbxref'' AS type, d.name || '':'' || s.accession AS attribute
FROM dbxref s, feature_dbxref fs, db d
WHERE fs.feature_id= $1 AND fs.dbxref_id = s.dbxref_id AND s.db_id = d.db_id
--UNION
--SELECT feature_id, ''expression'' AS type, s.description AS attribute
--FROM expression s, feature_expression fs
--WHERE fs.feature_id= $1 AND fs.expression_id = s.expression_id
UNION
SELECT fg.feature_id, ''genotype'' AS type, g.uniquename||'': ''||g.description AS attribute
FROM gcontext g, feature_gcontext fg
WHERE fg.feature_id= $1 AND g.gcontext_id = fg.gcontext_id
--UNION
--SELECT feature_id, ''genotype'' AS type, s.description AS attribute
--FROM genotype s, feature_genotype fs
--WHERE fs.feature_id= $1 AND fs.genotype_id = s.genotype_id
--UNION
--SELECT feature_id, ''phenotype'' AS type, s.description AS attribute
--FROM phenotype s, feature_phenotype fs
--WHERE fs.feature_id= $1 AND fs.phenotype_id = s.phenotype_id
UNION
SELECT feature_id, ''synonym'' AS type, s.name AS attribute
FROM synonym s, feature_synonym fs
WHERE fs.feature_id= $1 AND fs.synonym_id = s.synonym_id
UNION
SELECT fp.feature_id,cv.name,fp.value
FROM featureprop fp, cvterm cv
WHERE fp.feature_id= $1 AND fp.type_id = cv.cvterm_id 
UNION
SELECT feature_id, ''pub'' AS type, s.series_name || '':'' || s.title AS attribute
FROM pub s, feature_pub fs
WHERE fs.feature_id= $1 AND fs.pub_id = s.pub_id
'
LANGUAGE SQL;


--
-- functions for creating coordinate based functions
--
-- create a point
CREATE OR REPLACE FUNCTION p (int, int) RETURNS point AS
 'SELECT point ($1, $2)'
LANGUAGE 'sql';

-- create a range box
-- (make this immutable so we can index it)
CREATE OR REPLACE FUNCTION boxrange (int, int) RETURNS box AS
 'SELECT box (p(0, $1), p($2,500000000))'
LANGUAGE 'sql' IMMUTABLE;

-- create a query box
CREATE OR REPLACE FUNCTION boxquery (int, int) RETURNS box AS
 'SELECT box (p($1, $2), p($1, $2))'
LANGUAGE 'sql' IMMUTABLE;

CREATE OR REPLACE FUNCTION featureslice(int, int) RETURNS setof featureloc AS
  'SELECT * from featureloc where boxquery($1, $2) @ boxrange(fmin,fmax)'
LANGUAGE 'sql';

--functional index that depends on the above functions
CREATE INDEX binloc_boxrange ON featureloc USING RTREE (boxrange(fmin, fmax));

--uses the gff3atts to create a GFF3 compliant attribute string
CREATE OR REPLACE FUNCTION gffattstring (integer) RETURNS varchar AS
'DECLARE
  return_string      varchar;
  f_id               ALIAS FOR $1;
  atts_view          gffatts%ROWTYPE;
  feature_row        feature%ROWTYPE;
  name               varchar;
  uniquename         varchar;
  parent             varchar;
                                                                                
BEGIN
  --Get name from feature.name
  --Get ID from feature.uniquename
                                                                                
  SELECT INTO feature_row * FROM feature WHERE feature_id = f_id;
  name  = feature_row.name;
  return_string = ''ID='' || feature_row.uniquename;
  IF name IS NOT NULL AND name != ''''
  THEN
    return_string = return_string ||'';'' || ''Name='' || name;
  END IF;
                                                                                
  --Get Parent from feature_relationship
  SELECT INTO feature_row * FROM feature f, feature_relationship fr
    WHERE fr.subject_id = f_id AND fr.object_id = f.feature_id;
  IF FOUND
  THEN
    return_string = return_string||'';''||''Parent=''||feature_row.uniquename;
  END IF;
                                                                                
  FOR atts_view IN SELECT * FROM gff3atts WHERE feature_id = f_id  LOOP
    return_string = return_string || '';''
                     || atts_view.type || ''=''
                     || atts_view.attribute;
  END LOOP;
                                                                                
  RETURN return_string;
END;
'
LANGUAGE plpgsql;

--creates a view that is suitable for creating a GFF3 string
CREATE OR REPLACE VIEW gff3view (
  feature_id,
  ref,
  source,
  type,
  fstart,
  fend,
  score,
  strand,
  phase,
  attributes,
  seqlen,
  name
) AS
SELECT
  f.feature_id   ,
  sf.name        ,
  dbx.accession  ,
  cv.name        ,
  fl.fmin+1      ,
  fl.fmax        ,
  '.'            ,
  fl.strand      ,
  fl.phase       ,
  gffattstring(f.feature_id),
  f.seqlen       ,
  f.name         ,
  f.organism_id
FROM feature f
     LEFT JOIN featureloc fl     ON (f.feature_id     = fl.feature_id)
     LEFT JOIN feature sf        ON (fl.srcfeature_id = sf.feature_id) 
     LEFT JOIN feature_dbxref fd ON (f.feature_id     = fd.feature_id)
     LEFT JOIN dbxref dbx        ON (dbx.dbxref_id    = fd.dbxref_id)
     LEFT JOIN cvterm cv         ON (f.type_id        = cv.cvterm_id)
WHERE dbx.db_id IN (select db_id from db where db.name = 'GFF_source');

CREATE OR REPLACE FUNCTION feature_subalignments(integer) RETURNS SETOF featureloc AS '
DECLARE
  return_data featureloc%ROWTYPE;
  f_id ALIAS FOR $1;
  feature_data feature%rowtype;
  featureloc_data featureloc%rowtype;

  s text;

  fmin integer;
  slen integer;
BEGIN
  --RAISE NOTICE ''feature_id is %'', featureloc_data.feature_id;
  SELECT INTO feature_data * FROM feature WHERE feature_id = f_id;

  FOR featureloc_data IN SELECT * FROM featureloc WHERE feature_id = f_id LOOP

    --RAISE NOTICE ''fmin is %'', featureloc_data.fmin;

    return_data.feature_id      = f_id;
    return_data.srcfeature_id   = featureloc_data.srcfeature_id;
    return_data.is_fmin_partial = featureloc_data.is_fmin_partial;
    return_data.is_fmax_partial = featureloc_data.is_fmax_partial;
    return_data.strand          = featureloc_data.strand;
    return_data.phase           = featureloc_data.phase;
    return_data.residue_info    = featureloc_data.residue_info;
    return_data.locgroup        = featureloc_data.locgroup;
    return_data.rank            = featureloc_data.rank;

    s = feature_data.residues;
    fmin = featureloc_data.fmin;
    slen = char_length(s);

    WHILE char_length(s) LOOP
      --RAISE NOTICE ''residues is %'', s;

      --trim off leading match
      s = trim(leading ''|ATCGNatcgn'' from s);
      --if leading match detected
      IF slen > char_length(s) THEN
        return_data.fmin = fmin;
        return_data.fmax = featureloc_data.fmin + (slen - char_length(s));

        --if the string started with a match, return it,
        --otherwise, trim the gaps first (ie do not return this iteration)
        RETURN NEXT return_data;
      END IF;

      --trim off leading gap
      s = trim(leading ''-'' from s);

      fmin = featureloc_data.fmin + (slen - char_length(s));
    END LOOP;
  END LOOP;

  RETURN;

END;
' LANGUAGE 'plpgsql';
