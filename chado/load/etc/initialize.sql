/* For load_gff3.pl */
insert into organism (abbreviation, genus, species, common_name)
       values ('H.sapiens', 'Homo','sapiens','Human');
insert into contact (name) values ('Affymetrix');
insert into contact (name,description) values ('null','null');
insert into cv (name) values ('null');
insert into cv (name,definition) values ('Ad Hoc Ontology','Locally created terms');
insert into cvterm (name,cv_id) values ('null',       (select cv_id from cv where name = 'null'));
insert into cvterm (name,cv_id) values ('adult',      (select cv_id from cv where name = 'Ad Hoc Ontology'));
insert into cvterm (name,cv_id) values ('adult_old',  (select cv_id from cv where name = 'Ad Hoc Ontology'));
insert into cvterm (name,cv_id) values ('adult_young',(select cv_id from cv where name = 'Ad Hoc Ontology'));
insert into cvterm (name,cv_id) values ('child',      (select cv_id from cv where name = 'Ad Hoc Ontology'));
insert into cvterm (name,cv_id) values ('fetus',      (select cv_id from cv where name = 'Ad Hoc Ontology'));
insert into cvterm (name,cv_id) values ('survival_time',(select cv_id from cv where name = 'Ad Hoc Ontology'));
insert into cvterm (name,definition,cv_id) values ('glass','glass array',(select cv_id from cv where name = 'Ad Hoc Ontology'));
insert into cvterm (name,definition,cv_id) values ('photochemical_oligo','in-situ photochemically synthesized oligoes',(select cv_id from cv where name = 'Ad Hoc Ontology'));

insert into pub (miniref,uniquename,type_id) values ('null','null',(select cvterm_id from cvterm where name = 'null'));
insert into db (name, contact_id) values ('DB:refseq' ,(select contact_id from contact where name = 'null'));
insert into db (name, contact_id) values ('DB:genbank',(select contact_id from contact where name = 'null'));
insert into db (name, contact_id) values ('DB:ucsc'   ,(select contact_id from contact where name = 'null'));
insert into db (name, contact_id) values ('DB:swissprot'   ,(select contact_id from contact where name = 'null'));

insert into array (name,manufacturer_id,platformtype_id) values ('unknown',(select contact_id from contact where name = 'null'),(select cvterm_id from cvterm where name = 'null'));
insert into array (name,manufacturer_id,platformtype_id,substratetype_id,num_of_elements,num_array_rows,num_array_columns) values ('U133A',(select contact_id from contact where name = 'Affymetrix'),(select cvterm_id from cvterm where name = 'photochemical_oligo'),(select cvterm_id from cvterm where name = 'glass'),506944,712,712);
insert into array (name,manufacturer_id,platformtype_id,substratetype_id,num_of_elements,num_array_rows,num_array_columns) values ('U133B',(select contact_id from contact where name = 'Affymetrix'),(select cvterm_id from cvterm where name = 'photochemical_oligo'),(select cvterm_id from cvterm where name = 'glass'),506944,712,712);
insert into array (name,manufacturer_id,platformtype_id,substratetype_id) values ('U95A' ,(select contact_id from contact where name = 'Affymetrix'),(select cvterm_id from cvterm where name = 'photochemical_oligo'),(select cvterm_id from cvterm where name = 'glass'));

/* we need to have the ontologies loaded before we can do this.  "make prepdb" now needs to come after "make ontologies" */
insert into cvterm_relationship (subject_id,object_id,type_id) values (
  (select cvterm_id from cvterm where name = 'blood_cell' and cv_id = (select cv_id from cv where name = 'Cell Ontology')),
  (select cvterm_id from cvterm where name = 'blood' and cv_id = (select cv_id from cv where name = 'Mouse Adult Anatomy Ontology')),
  (select cvterm_id from cvterm where name = 'part_of' and cv_id = (select cv_id from cv where name = 'Relationship Ontology'))
);


