## We should take a look in OMG for a standard representation we might use 
## instead of this.

## ================================================
## TABLE: pub
## ================================================

create table pub (
       pub_id serial not null,
       primary key (pub_id),
## title of paper, chapter of book, journal, etc
       title text,
## title of part if one of a series
       volumetitle text,
       volume  varchar(255),
## full name of (journal) series
       series_name varchar(255),
       issue  varchar(255),
       pyear  varchar(255),
## page number range[s], eg, 457--459, viii + 664pp, lv--lvii
       pages  varchar(255),
## the type of the publication (book, journal, poem, graffiti, etc)
       type_id int not null,
       foreign key (type_id) references cvterm (cvterm_id),
## do we want this even though we have the relationship in pub_relationship?
       is_obsolete boolean default 'false',
       publisher varchar(255),
       pubplace varchar(255),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp
);

## ================================================
## TABLE: pub_relationship
## ================================================

## Handle relationships between publications, eg, when one publication
## makes others obsolete, when one publication contains errata with
## respect to other publication(s), or when one publication also 
## appears in another pub (I think these three are it - at least for fb)

create table pub_relationship (
       subj_pub_id int not null,
       foreign key (subj_pub_id) references pub (pub_id),
       obj_pub_id int not null,
       foreign key (obj_pub_id) references pub (pub_id),
       type_id int not null,
       foreign key (type_id) references cvterm (cvterm_id),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp,

       unique(subj_pub_id, obj_pub_id, type_id)
);

## ================================================
## TABLE: pub_dbxref
## ================================================

## Handle links to eg, pubmed, biosis, zoorec, OCLC, mdeline, ISSN, coden...

create table pub_dbxref (
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id),
       dbxref_id int not null,
       foreign key (dbxref_id) references dbxref (dbxref_id),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp,

       unique(pub_id,dbxref_id)
);

create index pub_dbxref_ind1 on pub_dbxref (dbxref_id);


## ================================================
## TABLE: author
## ================================================

## using the FB author table columns

create table author (
       author_id serial not null,
       primary key (author_id),
       surname varchar(255) not null,
## first name, initials
       givennames varchar(255),
## Jr., Sr., etc       
       suffix varchar(255),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp
);

## ================================================
## TABLE: pub_author
## ================================================

create table pub_author (
       author_id int not null,
       foreign key (author_id) references author (author_id),
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id),
## order of author in author list for this pub
       arank int not null,
## indicates whether the author is an editor for linked publication
       editor boolean default 'false',
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp
);

## ================================================
## TABLE: pubprop
## ================================================

create table pubprop (
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id),
       pkey_id int not null,
       foreign key (pkey_id) references cvterm (cvterm_id),
       pval text not null,
       prank integer,
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp,

       unique(pub_id,pkey_id,pval)
);

