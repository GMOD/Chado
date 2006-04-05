CREATE VIEW cvterm_relationship_with_typename AS
 SELECT
  cvterm_relationship.*,
  typeterm.name AS typename,
  typeterm.cv_id AS typeterm_cv_id
 FROM cvterm_relationship
      INNER JOIN cvterm AS typeterm ON (type_id=typeterm.cvterm_id);

CREATE VIEW cvtermprop_with_propname AS
 SELECT
  cvtermprop.*,
  propterm.name AS propname,
  propterm.cv_id AS propterm_cv_id
 FROM cvtermprop
      INNER JOIN cvterm AS propterm ON (type_id=propterm.cvterm_id);

