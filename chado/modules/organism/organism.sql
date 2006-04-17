
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

COMMENT ON TABLE organism IS 'The organismal taxonomic
classification. Note that phylogenies are represented using the
phylogeny module, and taxonomies can be represented using the cvterm
module or the phylogeny module';

COMMENT ON COLUMN organism.species IS 'A type of organism is always
uniquely identified by genus+species. When mapping from the NCBI
taxonomy names.dmp file, the unique-name column must be used where it
is present, as the name column is not always unique (eg environmental
samples). If a particular strain or subspecies is to be represented,
this is appended onto the species name. Follows standard NCBI taxonomy
pattern';

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

COMMENT ON TABLE organismprop IS 'tag-value properties - follows standard chado model';

-- ================================================
-- TABLE: organism_relationship
-- ================================================

CREATE TABLE organism_relationship (
    organism_relationship_id serial not null,
    PRIMARY KEY (organism_relationship_id),
    subject_id int not null,
    FOREIGN KEY (subject_id) REFERENCES organism (organism_id) INITIALLY DEFERRED,
    object_id int not null,
    FOREIGN KEY (object_id) REFERENCES organism (organism_id) INITIALLY DEFERRED,
    type_id int not null,
    FOREIGN KEY (type_id) REFERENCES cvterm (cvterm_id) INITIALLY DEFERRED,
    CONSTRAINT organism_relationship_c1 UNIQUE (subject_id, object_id, type_id)
);
CREATE INDEX organism_relationship_idx1 ON organism_relationship (subject_id);
CREATE INDEX organism_relationship_idx2 ON organism_relationship (object_id);
CREATE INDEX organism_relationship_idx3 ON organism_relationship (type_id);

-- ================================================
-- TABLE: organismpath
-- ================================================

CREATE TABLE organismpath (
    organismpath_id serial not null,
    PRIMARY KEY (organismpath_id),
    subject_id int not null,
    FOREIGN KEY (subject_id) REFERENCES organism (organism_id) INITIALLY DEFERRED,
    object_id int not null,
    FOREIGN KEY (object_id) REFERENCES organism (organism_id) INITIALLY DEFERRED,
    type_id int not null,
    FOREIGN KEY (type_id) REFERENCES cvterm (cvterm_id) INITIALLY DEFERRED,
    pathdistance int,
    CONSTRAINT organismpath_c1 UNIQUE (subject_id,object_id,type_id,pathdistance)
);
CREATE INDEX organismpath_idx1 ON organismpath (type_id);
CREATE INDEX organismpath_idx2 ON organismpath (subject_id);
CREATE INDEX organismpath_idx3 ON organismpath (object_id);

