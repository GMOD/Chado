---**********************************************************
--- depends on featureloc_idx3 index
--- make query by range faster
---**********************************************************

CLUSTER featureloc_idx3 on featureloc;

---unique index/constraint(?) (subject_id, object_id) is not adequate
ALTER TABLE cvtermpath DROP CONSTRAINT cvtermpath_subject_id_key;
CREATE UNIQUE INDEX cvtermpath_subject_id_key ON cvtermpath(subject_id, object_id, cv_id, pathdistance);
