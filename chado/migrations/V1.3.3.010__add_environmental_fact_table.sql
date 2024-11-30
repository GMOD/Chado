-- Adds a new "nd_fact" table to store environmental data.
CREATE TABLE nd_fact(
    nd_fact_id BIGSERIAL PRIMARY KEY NOT NULL,
    nd_geolocation_id BIGINT NOT NULL REFERENCES nd_geolocation (nd_geolocation_id) ON DELETE CASCADE INITIALLY DEFERRED,
    type_id BIGINT NOT NULL REFERENCES cvterm (cvterm_id) ON DELETE CASCADE INITIALLY DEFERRED,
    timecaptured TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    timecapturedend TIMESTAMP,
    value TEXT NULL,
    CONSTRAINT nd_fact_c1 UNIQUE (nd_geolocation_id, type_id, timecaptured)
  );
CREATE INDEX nd_fact_idx1 ON nd_fact (nd_geolocation_id);
CREATE INDEX nd_fact_idx2 ON nd_fact (timecaptured);

COMMENT ON TABLE nd_fact IS 'The fact table contains facts (temparture, weather condition,...) at a given time for a given geolocation.';
COMMENT ON COLUMN nd_fact.value IS 'The value can be NULL if the type_id is self-explicit. For instance, if the type_id term is "sunny day", there is no need for a value.';
COMMENT ON COLUMN nd_fact.timecapturedend IS 'This optional value can be used to mark the end of the time that the catured fact data refers to, that is to provide a time span rather than a time point; can be null.';
