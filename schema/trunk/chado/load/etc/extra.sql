/* we need to have the ontologies loaded before we can do this.  "make prepdb" now needs to come after "make ontologies" */
insert into cvterm_relationship (subject_id,object_id,type_id) values (
  (select cvterm_id from cvterm where name = 'blood_cell' and cv_id = (select cv_id from cv where name = 'Cell Ontology')),
  (select cvterm_id from cvterm where name = 'blood' and cv_id = (select cv_id from cv where name = 'Mouse Adult Anatomy Ontology')),
  (select cvterm_id from cvterm where name = 'part_of' and cv_id = (select cv_id from cv where name = 'Relationship Ontology'))
);
insert into cvterm_relationship (subject_id,object_id,type_id) values (
  (select cvterm_id from cvterm where name = 'chondrocyte' and cv_id = (select cv_id from cv where name = 'Cell Ontology')),
  (select cvterm_id from cvterm where name = 'cartilage' and cv_id = (select cv_id from cv where name = 'Mouse Adult Anatomy Ontology')),
  (select cvterm_id from cvterm where name = 'part_of' and cv_id = (select cv_id from cv where name = 'Relationship Ontology'))
);

