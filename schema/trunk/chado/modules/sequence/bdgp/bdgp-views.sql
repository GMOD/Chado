

CREATE VIEW featurepropd AS
 SELECT featureprop.*, 
        cvterm.name AS type
 FROM 
   featureprop
    INNER JOIN cvterm ON (featureprop.type_id=cvterm.cvterm_id);

CREATE VIEW dbxrefd AS
 SELECT dbxref.*,
        db.name AS dbname
 FROM
  dbxref INNER JOIN db USING (db_id);

CREATE VIEW tfeature AS
 SELECT feature.*,
        cvterm.name AS type
 FROM
  feature INNER JOIN cvterm ON (feature.type_id=cvterm.cvterm_id);
