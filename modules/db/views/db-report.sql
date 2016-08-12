CREATE VIEW db_dbxref_count AS
  SELECT db.name,count(*) AS num_dbxrefs FROM db INNER JOIN dbxref USING (db_id) GROUP BY db.name;
COMMENT ON VIEW db_dbxref_count IS 'per-db dbxref counts';
