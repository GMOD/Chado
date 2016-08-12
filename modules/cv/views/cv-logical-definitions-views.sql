-- Cross-products, logical definitions

-- These views are for advanced use - you will only need them if
-- you are loading ontologies that use either advanced obo format 1.2
-- features or OWL DL ontologies. Please read the relevant documentation
-- first

-- keywords: defined classes, OWL, Aristotelian definitions

CREATE OR REPLACE VIEW is_anonymous_cvterm AS
 SELECT cvterm_id
 FROM cvtermprop_with_propname
 WHERE propname='is_anonymous' AND value='1';

CREATE OR REPLACE VIEW cvterm_ldef_intersection AS
SELECT *
FROM 
 cvterm_relationship_with_typename
WHERE
 typename='intersection_of';

COMMENT ON VIEW cvterm_ldef_intersection IS 'for advanced OWL/Description Logic style definitions, chado allows the specification of an equivalentClass using intersection_of links between the defined term and the cross-product';


CREATE OR REPLACE VIEW cvterm_genus AS
SELECT
 i.subject_id AS cvterm_id,
 i.object_id AS genus_id
FROM
 cvterm_ldef_intersection AS i
WHERE
 i.object_id NOT IN (SELECT cvterm_id FROM is_anonymous_cvterm);

COMMENT ON VIEW cvterm_genus IS 'In a logical (cross-product) definition, there is a generic term (genus) and discriminating characteristics. E.g. a biosynthesis (genus) which outputs cysteine (differentia). The genus is the -true- is_a parent';

CREATE OR REPLACE VIEW cvterm_differentium AS
SELECT
 i.subject_id AS cvterm_id,
 diff.*
FROM
 cvterm_ldef_intersection AS i
 INNER JOIN cvterm_relationship AS diff ON (i.object_id=diff.subject_id)
 INNER JOIN is_anonymous_cvterm AS anon  ON (anon.cvterm_id=i.object_id);

COMMENT ON VIEW cvterm_differentium IS 'In a logical (cross-product) definition, there is a generic term (genus) and discriminating characteristics. E.g. a biosynthesis (genus) which outputs cysteine (differentia). Each differentium is a link via a relation to another cvterm which discriminates the defined term from other is_a siblings';

