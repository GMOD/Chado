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
    contact_id int,
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
    name varchar(255) not null,
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
    dbxref_id int not null,
    foreign key (dbxref_id) references dbxref (dbxref_id) on delete set null INITIALLY DEFERRED,
    is_obsolete int not null default 0,
    is_relationshiptype int not null default 0,
    constraint cvterm_c1 unique (name,cv_id,is_obsolete),
    constraint cvterm_c2 unique (dbxref_id)
);
create index cvterm_idx1 on cvterm (cv_id);
create index cvterm_idx2 on cvterm (name);
create index cvterm_idx3 on cvterm (dbxref_id);

COMMENT ON TABLE cvterm IS
 'A term, class or concept within an ontology or controlled vocabulary.
  Also used for relationship types. A cvterm can also be thought of
  as a node in a graph';
COMMENT ON COLUMN cvterm.cv_id IS
 'The cv/ontology/namespace to which this cvterm belongs';
COMMENT ON COLUMN cvterm.name IS
 'A concise human-readable name describing the meaning of the cvterm';
COMMENT ON COLUMN cvterm.definition IS
 'A human-readable text definition';
COMMENT ON COLUMN cvterm.dbxref_id IS
 'Primary dbxref - The unique global OBO identifier for this cvterm.
  Note that a cvterm may  have multiple secondary dbxrefs - see also
  table: cvterm_dbxref';
COMMENT ON COLUMN cvterm.is_obsolete IS
 'Boolean 0=false,1=true; see GO documentation for details of obsoletion.
  note that two terms with different primary dbxrefs may exist if one
  is obsolete';
COMMENT ON COLUMN cvterm.is_relationshiptype IS
 'Boolean 0=false,1=true
  Relationship types (also known as Typedefs in OBO format, or as
  properties or slots) form a cv/ontology in themselves. We use this
  flag to indicate whether this cvterm is an actual term/concept or
  a relationship type';
COMMENT ON INDEX cvterm_c1 IS 
 'the OBO identifier is globally unique';
COMMENT ON INDEX cvterm_c2 IS 
 'a name can mean different things in different contexts;
  for example "chromosome" in SO and GO. A name should be unique
  within an ontology/cv. A name may exist twice in a cv, in both
  obsolete and non-obsolete forms - these will be for different
  cvterms with different OBO identifiers; so GO documentation for
  more details on obsoletion';

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
COMMENT ON TABLE cvterm_relationship IS
 'A relationship linking two cvterms. A relationship can be thought of
  as an edge in a graph, or as a natural language statement about
  two cvterms. The statement is of the form SUBJECT PREDICATE OBJECT;
  for example "wing part_of body"';

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
    type_id int,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade  INITIALLY DEFERRED,
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
    is_for_definition int not null default 0,
    constraint cvterm_dbxref_c1 unique (cvterm_id,dbxref_id)
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
create index cvtermprop_idx1 on cvtermprop (cvterm_id);
create index cvtermprop_idx2 on cvtermprop (type_id);


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
    value text not null default '',
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
    is_obsolete boolean not null default 'false',
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
-- is_obsolete is for marking records obsolete which none the less need to 
-- remain in the table. 
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
    constraint featureloc_c1 unique (feature_id,locgroup,rank),
    constraint featureloc_c2 check (fmin <= fmax)
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
-- codes; qualifiers; metadata such as the date on which the entry was
-- curated and the source of the association

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
-- TABLE: feature_cvterm_dbxref
-- ================================================

create table feature_cvterm_dbxref (
    feature_cvterm_dbxref_id serial not null,
    primary key (feature_cvterm_dbxref_id),
    feature_cvterm_id int not null,
    foreign key (feature_cvterm_id) references feature_cvterm (feature_cvterm_id) on delete cascade,
    dbxref_id int not null,
    foreign key (dbxref_id) references dbxref (dbxref_id) on delete cascade INITIALLY DEFERRED,
    constraint feature_cvterm_dbxref_c1 unique (feature_cvterm_id,dbxref_id)
);
create index feature_cvterm_dbxref_idx1 on feature_cvterm_dbxref (feature_cvterm_id);
create index feature_cvterm_dbxref_idx2 on feature_cvterm_dbxref (dbxref_id);

COMMENT ON TABLE feature_cvterm_dbxref IS
 'Additional dbxrefs for an association. Rows in the feature_cvterm table may be backed up by dbxrefs. For example, a feature_cvterm association that was inferred via a protein-protein interaction may be backed by by refering to the dbxref for the alternate protein. Corresponds to the WITH column in a GO gene association file (but can also be used for other analagous associations). See http://www.geneontology.org/doc/GO.annotation.shtml#file for more details';


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
-- changes 2004-06 (Documented by DE: 10-MAR-2005):
--   Many, including rename of gcontext to genotype,  split 
--   phenstatement into phenstatement & phenotype, created environment
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
-- we use the phendesc relation to represent the actual organismal 
-- context under observation
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
-- kind of linking table between stock and genotype
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


-- ================================================
-- TABLE: genotype
-- ================================================
-- genetic context
-- the uniquename should be derived from the features
-- making up the genoptype
--
-- uniquename: a human-readable unique identifier
--
create table genotype (
    genotype_id serial not null,
    primary key (genotype_id),
    uniquename text not null,      
    description varchar(255),
    constraint genotype_c1 unique (uniquename)
);
create index genotype_idx1 on genotype(uniquename);

COMMENT ON TABLE genotype IS NULL;


-- ===============================================
-- TABLE: feature_genotype
-- ================================================
-- A genotype is defined by a collection of features
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
create table feature_genotype (
    feature_genotype_id serial not null,
    primary key (feature_genotype_id),
    feature_id int not null,
    foreign key (feature_id) references feature (feature_id) on delete cascade,
    genotype_id int not null,
    foreign key (genotype_id) references genotype (genotype_id) on delete cascade,
    chromosome_id int,
    foreign key (chromosome_id) references feature (feature_id) on delete set null,
    rank int not null,
    cgroup     int not null,
    cvterm_id int not null,
    foreign key (cvterm_id) references cvterm (cvterm_id) on delete cascade,
    constraint feature_genotype_c1 unique (feature_id, genotype_id, cvterm_id)
);
create index feature_genotype_idx1 on feature_genotype (feature_id);
create index feature_genotype_idx2 on feature_genotype (genotype_id);

COMMENT ON TABLE feature_genotype IS NULL;



-- ================================================
-- TABLE: environment
-- ================================================
-- The environmental component of a phenotype description
create table environment (
    environment_id serial not NULL,
    primary key  (environment_id),
    uniquename text not null,
    description text,
    constraint environment_c1 unique (uniquename)
);
create index environment_idx1 on environment(uniquename);

COMMENT ON TABLE environment IS NULL;


-- ================================================
-- TABLE: environment_cvterm
-- ================================================
create table environment_cvterm (
    environment_cvterm_id serial not null,
    primary key  (environment_cvterm_id),
    environment_id int not null,
    foreign key (environment_id) references environment (environment_id) on delete cascade,
    cvterm_id int not null,
    foreign key (cvterm_id) references cvterm (cvterm_id) on delete cascade,
    constraint environment_cvterm_c1 unique (environment_id, cvterm_id)
);
create index environment_cvterm_idx1 on environment_cvterm (environment_id);
create index environment_cvterm_idx2 on environment_cvterm (cvterm_id);

COMMENT ON TABLE environment_cvterm IS NULL;

-- ================================================
-- TABLE: phenotype
-- ================================================
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
create table phenotype (
    phenotype_id serial not null,
    primary key (phenotype_id),
    uniquename text not null,  
    observable_id int,
    foreign key (observable_id) references cvterm (cvterm_id) on delete cascade,
    attr_id int,
    foreign key (attr_id) references cvterm (cvterm_id) on delete set null,
    value text,
    cvalue_id int,
    foreign key (cvalue_id) references cvterm (cvterm_id) on delete set null,
    assay_id int,
    foreign key (assay_id) references cvterm (cvterm_id) on delete set null,
    constraint phenotype_c1 unique (uniquename)
);
create index phenotype_idx1 on phenotype (cvalue_id);
create index phenotype_idx2 on phenotype (observable_id);
create index phenotype_idx3 on phenotype (attr_id);

COMMENT ON TABLE phenotype IS NULL;


-- ================================================
-- TABLE: phenotype_cvterm
-- ================================================
create table phenotype_cvterm (
    phenotype_cvterm_id serial not null,
    primary key (phenotype_cvterm_id),
    phenotype_id int not null,
    foreign key (phenotype_id) references phenotype (phenotype_id) on delete cascade,
    cvterm_id int not null,
    foreign key (cvterm_id) references cvterm (cvterm_id) on delete cascade,
    constraint phenotype_cvterm_c1 unique (phenotype_id, cvterm_id)
);
create index phenotype_cvterm_idx1 on phenotype_cvterm (phenotype_id);
create index phenotype_cvterm_idx2 on phenotype_cvterm (cvterm_id);

COMMENT ON TABLE phenotype_cvterm IS NULL;


-- ================================================
-- TABLE: phenstatement
-- ================================================
-- Phenotypes are things like "larval lethal".  Phenstatements are things
-- like "dpp[1] is recessive larval lethal". So essentially phenstatement
-- is a linking table expressing the relationship between genotype, environment,
-- and phenotype.
-- 
create table phenstatement (
    phenstatement_id serial not null,
    primary key (phenstatement_id),
    genotype_id int not null,
    foreign key (genotype_id) references genotype (genotype_id) on delete cascade,
    environment_id int not null,
    foreign key (environment_id) references environment (environment_id) on delete cascade,
    phenotype_id int not null,
    foreign key (phenotype_id) references phenotype (phenotype_id) on delete cascade,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade,
    pub_id int not null,
    foreign key (pub_id) references pub (pub_id) on delete cascade,
    constraint phenstatement_c1 unique (genotype_id,phenotype_id,environment_id,type_id,pub_id)
);
create index phenstatement_idx1 on phenstatement (genotype_id);
create index phenstatement_idx2 on phenstatement (phenotype_id);

COMMENT ON TABLE phenstatement IS NULL;


-- ================================================
-- TABLE: feature_phenotype
-- ================================================
create table feature_phenotype (
    feature_phenotype_id serial not null,
    primary key (feature_phenotype_id),
    feature_id int not null,
    foreign key (feature_id) references feature (feature_id) on delete cascade,
    phenotype_id int not null,
    foreign key (phenotype_id) references phenotype (phenotype_id) on delete cascade,
    constraint feature_phenotype_c1 unique (feature_id,phenotype_id)       
);
create index feature_phenotype_idx1 on feature_phenotype (feature_id);
create index feature_phenotype_idx2 on feature_phenotype (phenotype_id);

COMMENT ON TABLE feature_phenotype IS NULL;


-- ================================================
-- TABLE: phendesc
-- ================================================
-- RELATION: phendesc
--
-- a summary of a _set_ of phenotypic statements for any one
-- gcontext made in any one
-- publication
-- 
create table phendesc (
    phendesc_id serial not null,
    primary key (phendesc_id),
    genotype_id int not null,
    foreign key (genotype_id) references genotype (genotype_id) on delete cascade,
    environment_id int not null,
    foreign key (environment_id) references environment ( environment_id) on delete cascade,
    description text not null,
    pub_id int not null,
    foreign key (pub_id) references pub (pub_id) on delete cascade,
    constraint phendesc_c1 unique (genotype_id,environment_id,pub_id)
);
create index phendesc_idx1 on phendesc (genotype_id);
create index phendesc_idx2 on phendesc (environment_id);
create index phendesc_idx3 on phendesc (pub_id);

COMMENT ON TABLE phendesc IS NULL;


-- ================================================
-- TABLE: phenotype_comparison
-- ================================================
-- comparison of phenotypes
-- eg, genotype1/environment1/phenotype1 "non-suppressible" wrt 
-- genotype2/environment2/phenotype2
-- 
create table phenotype_comparison (
    phenotype_comparison_id serial not null,
    primary key (phenotype_comparison_id),
    genotype1_id int not null,
        foreign key (genotype1_id) references genotype (genotype_id) on delete cascade,
    environment1_id int not null,
        foreign key (environment1_id) references environment (environment_id) on delete cascade,
    genotype2_id int not null,
        foreign key (genotype2_id) references genotype (genotype_id) on delete cascade,
    environment2_id int not null,
        foreign key (environment2_id) references environment (environment_id) on delete cascade,
    phenotype1_id int not null,
        foreign key (phenotype1_id) references phenotype (phenotype_id) on delete cascade,
    phenotype2_id int,
        foreign key (phenotype2_id) references phenotype (phenotype_id) on delete cascade,
    type_id int not null,
        foreign key (type_id) references cvterm (cvterm_id) on delete cascade,
    pub_id int not null,
    foreign key (pub_id) references pub (pub_id) on delete cascade,
    constraint phenotype_comparison_c1 unique (genotype1_id,environment1_id,genotype2_id,environment2_id,phenotype1_id,type_id,pub_id)
);

COMMENT ON TABLE phenotype_comparison IS NULL;

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





-- ================================================
-- TABLE: library
-- ================================================

create table library (
    library_id serial not null,
    primary key (library_id),
    organism_id int not null,
    foreign key (organism_id) references organism (organism_id),
    name varchar(255),
    uniquename text not null,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id),
    constraint library_c1 unique (organism_id,uniquename,type_id)
);
-- The type_id foreign key links to a controlled vocabulary of library types.
-- examples of this would be: 'cDNA_library' or 'genomic_library'
create index library_name_ind1 on library(name);
create index library_idx1 on library (organism_id);
create index library_idx2 on library (type_id);
create index library_idx3 on library (uniquename);


-- ================================================
-- TABLE: library_synonym
-- ================================================

create table library_synonym (
    library_synonym_id serial not null,
    primary key (library_synonym_id),
    synonym_id int not null,
    foreign key (synonym_id) references synonym (synonym_id) on delete cascade INITIALLY DEFERRED,
    library_id int not null,
    foreign key (library_id) references library (library_id) on delete cascade INITIALLY DEFERRED,
    pub_id int not null,
    foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
    is_current boolean not null default 'true',
    is_internal boolean not null default 'false',
    constraint library_synonym_c1 unique (synonym_id,library_id,pub_id)
);
-- pub_id: the pub_id link is for relating the usage of a given synonym to the
-- publication in which it was used
-- is_current: the is_current bit indicates whether the linked synonym is the 
-- current -official- symbol for the linked library
-- is_internal: typically a synonym exists so that somebody querying the db 
-- with an obsolete name can find the object they're looking for (under its 
-- current name.  If the synonym has been used publicly & deliberately (eg in 
-- a paper), it my also be listed in reports as a synonym.   If the synonym 
-- was not used deliberately (eg, there was a typo which went public), then 
-- the is_internal bit may be set to 'true' so that it is known that the 
-- synonym is "internal" and should be queryable but should not be listed 
-- in reports as a valid synonym.
create index library_synonym_idx1 on library_synonym (synonym_id);
create index library_synonym_idx2 on library_synonym (library_id);
create index library_synonym_idx3 on library_synonym (pub_id);


-- ================================================
-- TABLE: library_pub
-- ================================================

create table library_pub (
    library_pub_id serial not null,
    primary key (library_pub_id),
    library_id int not null,
    foreign key (library_id) references library (library_id) on delete cascade INITIALLY DEFERRED,
    pub_id int not null,
    foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
    constraint library_pub_c1 unique (library_id,pub_id)
);
create index library_pub_idx1 on library_pub (library_id);
create index library_pub_idx2 on library_pub (pub_id);


-- ================================================
-- TABLE: libraryprop
-- ================================================

create table libraryprop (
    libraryprop_id serial not null,
    primary key (libraryprop_id),
    library_id int not null,
    foreign key (library_id) references library (library_id) on delete cascade INITIALLY DEFERRED,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id),
    value text null,
    rank int not null default 0,
    constraint libraryprop_c1 unique (library_id,type_id,rank)
);
create index libraryprop_idx1 on libraryprop (library_id);
create index libraryprop_idx2 on libraryprop (type_id);


-- ================================================
-- TABLE: library_cvterm
-- ================================================

create table library_cvterm (
    library_cvterm_id serial not null,
    primary key (library_cvterm_id),
    library_id int not null,
    foreign key (library_id) references library (library_id) on delete cascade INITIALLY DEFERRED,
    cvterm_id int not null,
    foreign key (cvterm_id) references cvterm (cvterm_id),
    pub_id int not null,
    foreign key (pub_id) references pub (pub_id),
    constraint library_cvterm_c1 unique (library_id,cvterm_id,pub_id)
);
-- The table library_cvterm links a library to controlled vocabularies which
-- describe the library.  For instance, there might be a link to the anatomy
-- cv for "head" or "testes" for a head or testes library.
create index library_cvterm_idx1 on library_cvterm (library_id);
create index library_cvterm_idx2 on library_cvterm (cvterm_id);
create index library_cvterm_idx3 on library_cvterm (pub_id);


-- ================================================
-- TABLE: library_feature
-- ================================================

create table library_feature (
    library_feature_id serial not null,
    primary key (library_feature_id),
    library_id int not null,
    foreign key (library_id) references library (library_id) on delete cascade INITIALLY DEFERRED,
    feature_id int not null,
    foreign key (feature_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,
    constraint library_feature_c1 unique (library_id,feature_id)
);
-- library_feature links a library to the clones which are contained in the 
-- library.  Examples of such linked features might be "cDNA_clone" or 
-- "genomic_clone".
create index library_feature_idx1 on library_feature (library_id);
create index library_feature_idx2 on library_feature (feature_id);

