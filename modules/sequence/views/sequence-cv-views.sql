CREATE VIEW cv_for_feature
 AS SELECT * FROM cv WHERE name='sequence';
CREATE VIEW cv_for_featureprop
 AS SELECT * FROM cv WHERE name='feature_property';
CREATE VIEW cv_for_feature_relationship
 AS SELECT * FROM cv WHERE name='relationship';
