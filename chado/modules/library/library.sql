-- =================================================================
-- Dependencies:
--
-- :import feature from sequence
-- :import synonym from sequence
-- :import cvterm from cv
-- :import pub from pub
-- :import organism from organism
-- =================================================================

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

