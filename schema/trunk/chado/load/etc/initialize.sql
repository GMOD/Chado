/* For load_gff3.pl */
insert into organism (abbreviation, genus, species, common_name)
       values ('H.sapiens', 'Homo','sapiens','Human');
insert into contact (name) values ('DBUSER');
insert into cv (name) values ('null');
insert into cvterm (name,cv_id) values ('null',(select cv_id from cv where name = 'null'));
insert into pub (miniref,type_id) values ('null',(select cvterm_id from cvterm where name = 'null'));
insert into db (name, contact_id) values ('DB:refseq',1);

