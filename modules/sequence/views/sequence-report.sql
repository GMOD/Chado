CREATE VIEW type_feature_count AS
  SELECT t.name AS type,count(*) AS num_features 
   FROM cvterm AS t INNER JOIN feature ON (type_id=t.cvterm_id) 
  GROUP BY t.name;
COMMENT ON VIEW type_feature_count IS 'per-feature-type feature counts';
