
ALTER TABLE cv     ALTER COLUMN cv_id     TYPE bigserial;
ALTER TABLE cvterm ALTER COLUMN cvterm_id TYPE bigserial;
ALTER TABLE cvterm ALTER COLUMN cv_id     TYPE bigint;
ALTER TABLE cvterm ALTER COLUMN dbxref_id TYPE bigint;
ALTER TABLE cvterm_relationship ALTER COLUMN cvterm_relationship_id TYPE bigserial;
ALTER TABLE cvterm_relationship ALTER COLUMN type_id                TYPE bigint;
ALTER TABLE cvterm_relationship ALTER COLUMN subject_id             TYPE bigint;
ALTER TABLE cvterm_relationship ALTER COLUMN object_id              TYPE bigint;
ALTER TABLE cvtermpath ALTER COLUMN cvtermpath_id TYPE bigserial;
ALTER TABLE cvtermpath ALTER COLUMN type_id       TYPE bigint;
ALTER TABLE cvtermpath ALTER COLUMN subject_id    TYPE bigint;
ALTER TABLE cvtermpath ALTER COLUMN object_id     TYPE bigint;
ALTER TABLE cvtermsynonym ALTER COLUMN cvtermsynonym_id TYPE bigserial;
ALTER TABLE cvtermsynonym ALTER COLUMN cvterm_id        TYPE bigint;
ALTER TABLE cvtermsynonym ALTER COLUMN type_id          TYPE bigint;
ALTER TABLE cvterm_dbxref ALTER COLUMN cvterm_dbxref_id TYPE bigserial;
ALTER TABLE cvterm_dbxref ALTER COLUMN cvterm_id TYPE bigint;
ALTER TABLE cvterm_dbxref ALTER COLUMN dbxref_id TYPE bigint;
ALTER TABLE cvtermprop ALTER COLUMN cvtermprop_id TYPE bigserial;
ALTER TABLE cvtermprop ALTER COLUMN cvterm_id     TYPE bigint;
ALTER TABLE cvtermprop ALTER COLUMN type_id       TYPE bigint;
ALTER TABLE dbxrefprop ALTER COLUMN dbxrefprop_id TYPE bigserial;
ALTER TABLE dbxrefprop ALTER COLUMN dbxref_id     TYPE bigint;
ALTER TABLE dbxrefprop ALTER COLUMN type_id       TYPE bigint;
ALTER TABLE cvprop ALTER COLUMN cvprop_id TYPE bigserial;
ALTER TABLE cvprop ALTER COLUMN cv_id     TYPE bigint;
ALTER TABLE cvprop ALTER COLUMN type_id   TYPE bigint;
ALTER TABLE chadoprop ALTER COLUMN chadoprop_id TYPE bigserial;
ALTER TABLE chadoprop ALTER COLUMN type_id      TYPE bigint;

create table dbprop (
  dbprop_id bigserial not null,
  primary key (dbprop_id),
  db_id bigint not null,
  type_id bigint not null,
  value text null,
  rank int not null default 0,
  foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
  foreign key (db_id) references db (db_id) on delete cascade INITIALLY DEFERRED,
  constraint dbprop_c1 unique (db_id,type_id,rank)
);
create index dbprop_idx1 on dbprop (db_id);
create index dbprop_idx2 on dbprop (type_id);

COMMENT ON TABLE dbprop IS 'An external database can have any number of
slot-value property tags attached to it. This is an alternative to
hardcoding a list of columns in the relational schema, and is
completely extensible. There is a unique constraint, dbprop_c1, for
the combination of db_id, rank, and type_id. Multivalued property-value pairs must be differentiated by rank.';

--not sure about the syntax of the ALTER TYPE command, but this is probably right
--from functions/deductive_closure.plpgsql
ALTER TYPE closure_result ALTER ATTRIBUTE cvterm_id TYPE bigint;

--I don't think I need to include *.sqlapi changes

--There are definitely residual bugs in the functions. They must not have been caught during the load becuase the functions don't get evaluated.  Ugh, that's going to be a lot of things to fix.
--on the upside, since the functions are all "CREATE OR REPLACE" the results won't have to go here.

--from bridges/godb-bridge.plpgsql
ALTER TABLE godb.go_acc ALTER COLUMN dbxref_id TYPE bigint;

ALTER TABLE godb.term2term ALTER COLUMN relationship_type_id TYPE bigint;
ALTER TABLE godb.term2term ALTER COLUMN term1_id TYPE bigint;
ALTER TABLE godb.term2term ALTER COLUMN term2_id TYPE bigint;
ALTER TABLE godb.graph_path ALTER COLUMN term1_id TYPE bigint;
ALTER TABLE godb.graph_path ALTER COLUMN term2_id TYPE bigint;
