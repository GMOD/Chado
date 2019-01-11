/* https://github.com/GMOD/Chado/issues/37 */
ALTER TABLE project
ADD COLUMN type_id TYPE bigint;
COMMENT ON COLUMN project.type_id IS 'An optional cvterm_id that specifies what type of project this record is.  Prior to 1.4, project type was set with an projectprop.';



