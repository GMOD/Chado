-- =================================================================
-- Dependencies:
--
-- :import feature from sequence
-- :import cvterm from cv
-- :import pub from pub
-- :import phenotype from phenotype
-- :import organism from organism
-- :import genotype from genetic
-- :import contact from contact
-- :import project from project
-- :import stock from stock
-- :import synonym
-- =================================================================


-- this probably needs some work, depending on how cross-database we
-- want to be.  In Postgres, at least, there are much better ways to 
-- represent geo information.

CREATE TABLE nd_geolocation (
    nd_geolocation_id serial PRIMARY KEY NOT NULL,
    description character varying(255),
    latitude real,
    longitude real,
    geodetic_datum character varying(32),
    altitude real
);

COMMENT ON TABLE nd_geolocation IS 'The geo-referencable location of the stock. NOTE: This entity is subject to change as a more general and possibly more OpenGIS-compliant geolocation module may be introduced into Chado.';

COMMENT ON COLUMN nd_geolocation.description IS 'A textual representation of the location, if this is the original georeference. Optional if the original georeference is available in lat/long coordinates.';


COMMENT ON COLUMN nd_geolocation.latitude IS 'The decimal latitude coordinate of the georeference, using positive and negative sign to indicate N and S, respectively.';

COMMENT ON COLUMN nd_geolocation.longitude IS 'The decimal longitude coordinate of the georeference, using positive and negative sign to indicate E and W, respectively.';

COMMENT ON COLUMN nd_geolocation.geodetic_datum IS 'The geodetic system on which the geo-reference coordinates are based. For geo-references measured between 1984 and 2010, this will typically be WGS84.';

COMMENT ON COLUMN nd_geolocation.altitude IS 'The altitude (elevation) of the location in meters. If the altitude is only known as a range, this is the average, and altitude_dev will hold half of the width of the range.';



CREATE TABLE nd_experiment (
    nd_experiment_id serial PRIMARY KEY NOT NULL,
    nd_geolocation_id integer NOT NULL references nd_geolocation (nd_geolocation_id) on delete cascade INITIALLY DEFERRED,
    type_id integer NOT NULL references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED 
);

--
--used to be nd_diversityexperiment_project
--then was nd_assay_project
CREATE TABLE nd_experiment_project (
    nd_experiment_project_id serial PRIMARY KEY NOT NULL,
    project_id integer not null references project (project_id) on delete cascade INITIALLY DEFERRED,
    nd_experiment_id integer NOT NULL references nd_experiment (nd_experiment_id) on delete cascade INITIALLY DEFERRED
);



CREATE TABLE nd_experimentprop (
    nd_experimentprop_id serial PRIMARY KEY NOT NULL,
    nd_experiment_id integer NOT NULL references nd_experiment (nd_experiment_id) on delete cascade INITIALLY DEFERRED,
    type_id integer NOT NULL references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED ,
    value text null,
    rank integer NOT NULL default 0,
    constraint nd_experimentprop_c1 unique (nd_experiment_id,type_id,rank)
);

CREATE TABLE nd_experiment_pub (
       nd_experiment_pub_id serial PRIMARY KEY not null,
       nd_experiment_id int not null,
       foreign key (nd_experiment_id) references nd_experiment (nd_experiment_id) on delete cascade INITIALLY DEFERRED,
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
       constraint nd_experiment_pub_c1 unique (nd_experiment_id,pub_id)
);
create index nd_experiment_pub_idx1 on nd_experiment_pub (nd_experiment_id);
create index nd_experiment_pub_idx2 on nd_experiment_pub (pub_id);

COMMENT ON TABLE nd_experiment_pub IS 'Linking nd_experiment(s) to publication(s)';




CREATE TABLE nd_geolocationprop (
    nd_geolocationprop_id serial PRIMARY KEY NOT NULL,
    nd_geolocation_id integer NOT NULL references nd_geolocation (nd_geolocation_id) on delete cascade INITIALLY DEFERRED,
    type_id integer NOT NULL references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    value text null,
    rank integer NOT NULL DEFAULT 0,
    constraint nd_geolocationprop_c1 unique (nd_geolocation_id,type_id,rank)
);

COMMENT ON TABLE nd_geolocationprop IS 'Property/value associations for geolocations. This table can store the properties such as location and environment';

COMMENT ON COLUMN nd_geolocationprop.type_id IS 'The name of the property as a reference to a controlled vocabulary term.';

COMMENT ON COLUMN nd_geolocationprop.value IS 'The value of the property.';

COMMENT ON COLUMN nd_geolocationprop.rank IS 'The rank of the property value, if the property has an array of values.';


CREATE TABLE nd_protocol (
    nd_protocol_id serial PRIMARY KEY  NOT NULL,
    name character varying(255) NOT NULL unique,
    type_id integer NOT NULL references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED
);

COMMENT ON TABLE nd_protocol IS 'A protocol can be anything that is done as part of the experiment.';

COMMENT ON COLUMN nd_protocol.name IS 'The protocol name.';

CREATE TABLE nd_reagent (
    nd_reagent_id serial PRIMARY KEY NOT NULL,
    name character varying(80) NOT NULL,
    type_id integer NOT NULL references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    feature_id integer
);

COMMENT ON TABLE nd_reagent IS 'A reagent such as a primer, an enzyme, an adapter oligo, a linker oligo. Reagents are used in genotyping experiments, or in any other kind of experiment.';

COMMENT ON COLUMN nd_reagent.name IS 'The name of the reagent. The name should be unique for a given type.';

COMMENT ON COLUMN nd_reagent.type_id IS 'The type of the reagent, for example linker oligomer, or forward primer.';

COMMENT ON COLUMN nd_reagent.feature_id IS 'If the reagent is a primer, the feature that it corresponds to. More generally, the corresponding feature for any reagent that has a sequence that maps to another sequence.';



CREATE TABLE nd_protocol_reagent (
    nd_protocol_reagent_id serial PRIMARY KEY NOT NULL,
    nd_protocol_id integer NOT NULL references nd_protocol (nd_protocol_id) on delete cascade INITIALLY DEFERRED,
    reagent_id integer NOT NULL references nd_reagent (nd_reagent_id) on delete cascade INITIALLY DEFERRED,
    type_id integer NOT NULL references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED
);


CREATE TABLE nd_protocolprop (
    nd_protocolprop_id serial PRIMARY KEY NOT NULL,
    nd_protocol_id integer NOT NULL references nd_protocol (nd_protocol_id) on delete cascade INITIALLY DEFERRED,
    type_id integer NOT NULL references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    value text null,
    rank integer DEFAULT 0 NOT NULL,
    constraint nd_protocolprop_c1 unique (nd_protocol_id,type_id,rank)
);

COMMENT ON TABLE nd_protocolprop IS 'Property/value associations for protocol.';

COMMENT ON COLUMN nd_protocolprop.nd_protocol_id IS 'The protocol to which the property applies.';

COMMENT ON COLUMN nd_protocolprop.type_id IS 'The name of the property as a reference to a controlled vocabulary term.';

COMMENT ON COLUMN nd_protocolprop.value IS 'The value of the property.';

COMMENT ON COLUMN nd_protocolprop.rank IS 'The rank of the property value, if the property has an array of values.';



CREATE TABLE nd_experiment_stock (
    nd_experiment_stock_id serial PRIMARY KEY NOT NULL,
    nd_experiment_id integer NOT NULL references nd_experiment (nd_experiment_id) on delete cascade INITIALLY DEFERRED,
    stock_id integer NOT NULL references stock (stock_id)  on delete cascade INITIALLY DEFERRED,
    type_id integer NOT NULL references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED
);

COMMENT ON TABLE nd_experiment_stock IS 'Part of a stock or a clone of a stock that is used in an experiment';


COMMENT ON COLUMN nd_experiment_stock.stock_id IS 'stock used in the extraction or the corresponding stock for the clone';


CREATE TABLE nd_experiment_protocol (
    nd_experiment_protocol_id serial PRIMARY KEY NOT NULL,
    nd_experiment_id integer NOT NULL references nd_experiment (nd_experiment_id) on delete cascade INITIALLY DEFERRED,
    nd_protocol_id integer NOT NULL references nd_protocol (nd_protocol_id) on delete cascade INITIALLY DEFERRED
);

COMMENT ON TABLE nd_experiment_protocol IS 'Linking table: experiments to the protocols they involve.';


CREATE TABLE nd_experiment_phenotype (
    nd_experiment_phenotype_id serial PRIMARY KEY NOT NULL,
    nd_experiment_id integer NOT NULL REFERENCES nd_experiment (nd_experiment_id) on delete cascade INITIALLY DEFERRED,
    phenotype_id integer NOT NULL references phenotype (phenotype_id) on delete cascade INITIALLY DEFERRED,
   constraint nd_experiment_phenotype_c1 unique (nd_experiment_id,phenotype_id)
); 

COMMENT ON TABLE nd_experiment_phenotype IS 'Linking table: experiments to the phenotypes they produce. There is a one-to-one relationship between an experiment and a phenotype since each phenotype record should point to one experiment. Add a new experiment_id for each phenotype record.';

CREATE TABLE nd_experiment_genotype (
    nd_experiment_genotype_id serial PRIMARY KEY NOT NULL,
    nd_experiment_id integer NOT NULL references nd_experiment (nd_experiment_id) on delete cascade INITIALLY DEFERRED,
    genotype_id integer NOT NULL references genotype (genotype_id) on delete cascade INITIALLY DEFERRED ,
    constraint nd_experiment_genotype_c1 unique (nd_experiment_id,genotype_id)
);

COMMENT ON TABLE nd_experiment_genotype IS 'Linking table: experiments to the genotypes they produce. There is a one-to-one relationship between an experiment and a genotype since each genotype record should point to one experiment. Add a new experiment_id for each genotype record.';


CREATE TABLE nd_reagent_relationship (
    nd_reagent_relationship_id serial PRIMARY KEY NOT NULL,
    subject_reagent_id integer NOT NULL references nd_reagent (nd_reagent_id) on delete cascade INITIALLY DEFERRED,
    object_reagent_id integer NOT NULL  references nd_reagent (nd_reagent_id) on delete cascade INITIALLY DEFERRED,
    type_id integer NOT NULL  references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED
);

COMMENT ON TABLE nd_reagent_relationship IS 'Relationships between reagents. Some reagents form a group. i.e., they are used all together or not at all. Examples are adapter/linker/enzyme experiment reagents.';

COMMENT ON COLUMN nd_reagent_relationship.subject_reagent_id IS 'The subject reagent in the relationship. In parent/child terminology, the subject is the child. For example, in "linkerA 3prime-overhang-linker enzymeA" linkerA is the subject, 3prime-overhand-linker is the type, and enzymeA is the object.';

COMMENT ON COLUMN nd_reagent_relationship.object_reagent_id IS 'The object reagent in the relationship. In parent/child terminology, the object is the parent. For example, in "linkerA 3prime-overhang-linker enzymeA" linkerA is the subject, 3prime-overhand-linker is the type, and enzymeA is the object.';

COMMENT ON COLUMN nd_reagent_relationship.type_id IS 'The type (or predicate) of the relationship. For example, in "linkerA 3prime-overhang-linker enzymeA" linkerA is the subject, 3prime-overhand-linker is the type, and enzymeA is the object.';


CREATE TABLE nd_reagentprop (
    nd_reagentprop_id serial PRIMARY KEY NOT NULL,
    nd_reagent_id integer NOT NULL references nd_reagent (nd_reagent_id) on delete cascade INITIALLY DEFERRED,
    type_id integer NOT NULL references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    value text null,
    rank integer DEFAULT 0 NOT NULL,
    constraint nd_reagentprop_c1 unique (nd_reagent_id,type_id,rank)
);

CREATE TABLE nd_experiment_stockprop (
    nd_experiment_stockprop_id serial PRIMARY KEY NOT NULL,
    nd_experiment_stock_id integer NOT NULL references nd_experiment_stock (nd_experiment_stock_id) on delete cascade INITIALLY DEFERRED,
    type_id integer NOT NULL references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    value text null,
    rank integer DEFAULT 0 NOT NULL,
    constraint nd_experiment_stockprop_c1 unique (nd_experiment_stock_id,type_id,rank)
);

COMMENT ON TABLE nd_experiment_stockprop IS 'Property/value associations for experiment_stocks. This table can store the properties such as treatment';

COMMENT ON COLUMN nd_experiment_stockprop.nd_experiment_stock_id IS 'The experiment_stock to which the property applies.';

COMMENT ON COLUMN nd_experiment_stockprop.type_id IS 'The name of the property as a reference to a controlled vocabulary term.';

COMMENT ON COLUMN nd_experiment_stockprop.value IS 'The value of the property.';

COMMENT ON COLUMN nd_experiment_stockprop.rank IS 'The rank of the property value, if the property has an array of values.';


CREATE TABLE nd_experiment_stock_dbxref (
    nd_experiment_stock_dbxref_id serial PRIMARY KEY NOT NULL,
    nd_experiment_stock_id integer NOT NULL references nd_experiment_stock (nd_experiment_stock_id) on delete cascade INITIALLY DEFERRED,
    dbxref_id integer NOT NULL references dbxref (dbxref_id) on delete cascade INITIALLY DEFERRED
);

COMMENT ON TABLE nd_experiment_stock_dbxref IS 'Cross-reference experiment_stock to accessions, images, etc';



CREATE TABLE nd_experiment_dbxref (
    nd_experiment_dbxref_id serial PRIMARY KEY NOT NULL,
    nd_experiment_id integer NOT NULL references nd_experiment (nd_experiment_id) on delete cascade INITIALLY DEFERRED,
    dbxref_id integer NOT NULL references dbxref (dbxref_id) on delete cascade INITIALLY DEFERRED
);

COMMENT ON TABLE nd_experiment_dbxref IS 'Cross-reference experiment to accessions, images, etc';


CREATE TABLE nd_experiment_contact (
    nd_experiment_contact_id serial PRIMARY KEY NOT NULL,
    nd_experiment_id integer NOT NULL references nd_experiment (nd_experiment_id) on delete cascade INITIALLY DEFERRED,
    contact_id integer NOT NULL references contact (contact_id) on delete cascade INITIALLY DEFERRED
);
