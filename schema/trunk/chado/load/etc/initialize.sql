/* For load_gff3.pl */
insert into organism (abbreviation, genus, species, common_name)
       values ('H.sapiens', 'Homo','sapiens','human');
insert into organism (abbreviation, genus, species, common_name)
       values ('D.melanogaster', 'Drosophila','melanogaster','fruitfly');
insert into organism (abbreviation, genus, species, common_name)
       values ('M.musculus', 'Mus','musculus','mouse');
insert into organism (abbreviation, genus, species, common_name)
       values ('A.gambiae', 'Anopheles','gambiae','mosquito');
insert into organism (abbreviation, genus, species, common_name)
       values ('R.norvegicus', 'Rattus','norvegicus','rat');
insert into organism (abbreviation, genus, species, common_name)
       values ('A.thaliana', 'Arabidopsis','thaliana','mustard weed');
insert into organism (abbreviation, genus, species, common_name)
       values ('C.elegans', 'Caenorhabditis','elegans','worm');
insert into organism (abbreviation, genus, species, common_name)
       values ('D.rerio', 'Danio','rerio','zebrafish');
insert into organism (abbreviation, genus, species, common_name)
       values ('O.sativa', 'Oryza','sativa','rice');
insert into organism (abbreviation, genus, species, common_name)
       values ('S.cerevisiae', 'Saccharomyces','cerevisiae','yeast');
insert into contact (name) values ('Affymetrix');
insert into contact (name,description) values ('null','null');
insert into cv (name) values ('null');
insert into cv (name,definition) values ('Ad Hoc Ontology','Locally created terms');
insert into cv (name,definition) values ('Statistical Terms','Locally created terms for statistics');
insert into cvterm (name,cv_id) values ('null',       (select cv_id from cv where name = 'null'));
insesrt into cvterm (name,cv_id) values ('Note', (select cv_id from cv where name = 'null'));
insert into cvterm (name,definition,cv_id) values ('glass','glass array',(select cv_id from cv where name = 'Ad Hoc Ontology'));
insert into cvterm (name,definition,cv_id) values ('photochemical_oligo','in-situ photochemically synthesized oligoes',(select cv_id from cv where name = 'Ad Hoc Ontology'));

insert into pub (miniref,uniquename,type_id) values ('null','null',(select cvterm_id from cvterm where name = 'null'));
insert into db (name, contact_id) values ('DB:refseq'   ,(select contact_id from contact where name = 'null'));
insert into db (name, contact_id) values ('DB:genbank'  ,(select contact_id from contact where name = 'null'));
insert into db (name, contact_id) values ('DB:TIGR'     ,(select contact_id from contact where name = 'null'));
insert into db (name, contact_id) values ('DB:ucsc'     ,(select contact_id from contact where name = 'null'));
insert into db (name, contact_id) values ('DB:ucla'     ,(select contact_id from contact where name = 'null'));
insert into db (name, contact_id) values ('DB:SGD',(select contact_id from contact where name = 'null'));
insert into db (name, contact_id, description, urlprefix) values ('DB:swissprot',(select contact_id from contact where name = 'null'),'SwissProt','http://us.expasy.org/cgi-bin/niceprot.pl?');
insert into db (name, contact_id, description, urlprefix) values ('DB:refseq:mrna',(select contact_id from contact where name = 'null'),'RefSeq mRNA','http://http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=search&db=nucleotide&dopt=GenBank&term=');
insert into db (name, contact_id, description, urlprefix) values ('DB:refseq:protein',(select contact_id from contact where name = 'null'),'RefSeq Protein','http://http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=search&db=protein&dopt=GenBank&term=');
insert into db (name, contact_id, description, urlprefix) values ('DB:unigene',(select contact_id from contact where name = 'null'),'Unigene','http://http://www.ncbi.nih.gov/entrez/query.fcgi?db=unigene&cmd=search&term=');
insert into db (name, contact_id, description, urlprefix) values ('DB:omim',(select contact_id from contact where name = 'null'),'OMIM','http://http://www.ncbi.nlm.nih.gov/entrez/dispomim.cgi?id=');
insert into db (name, contact_id, description, urlprefix) values ('DB:locuslink',(select contact_id from contact where name = 'null'),'LocusLink','http://http://www.ncbi.nlm.nih.gov/LocusLink/LocRpt.cgi?l=');
insert into db (name, contact_id, description, urlprefix) values ('DB:genbank:mrna',(select contact_id from contact where name = 'null'),'GenBank mRNA','http://http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=search&db=nucleotide&dopt=GenBank&term=');
insert into db (name, contact_id, description, urlprefix) values ('DB:genbank:protein',(select contact_id from contact where name = 'null'),'GenBank Protein','http://http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=search&db=protein&dopt=GenBank&term=');
insert into db (name, contact_id, description, urlprefix) values ('DB:swissprot:display',(select contact_id from contact where name = 'null'),'SwissProt','http://http://us.expasy.org/cgi-bin/niceprot.pl?');
insert into db (name, contact_id, description, urlprefix) values ('DB:pfam',(select contact_id from contact where name = 'null'),'Pfam','http://http://www.sanger.ac.uk/cgi-bin/Pfam/dql.pl?query=');
insert into db (name, contact_id, description, urlprefix) values ('DB:affy:U133',(select contact_id from contact where name = 'null'),'Affymetrix U133','http://https://www.affymetrix.com/analysis/netaffx/fullrecord.affx?pk=HG-U133_PLUS_2:');
insert into db (name, contact_id, description, urlprefix) values ('DB:affy:U95',(select contact_id from contact where name = 'null'),'Affymetrix U95','http://https://www.affymetrix.com/analysis/netaffx/fullrecord.affx?pk=HG-U95AV2:');

insert into arraydesign (name,manufacturer_id,platformtype_id) values ('unknown'                           , (select contact_id from contact where name = 'null'),(select cvterm_id from cvterm where name = 'null'));
insert into arraydesign (name,manufacturer_id,platformtype_id) values ('virtual array'                     , (select contact_id from contact where name = 'null'),(select cvterm_id from cvterm where name = 'null'));
insert into arraydesign (name,manufacturer_id,platformtype_id,substratetype_id,num_of_elements,num_array_rows,num_array_columns) values ('U133A',(select contact_id from contact where name = 'Affymetrix'),(select cvterm_id from cvterm where name = 'photochemical_oligo'),(select cvterm_id from cvterm where name = 'glass'),506944,712,712);
insert into arraydesign (name,manufacturer_id,platformtype_id,substratetype_id,num_of_elements,num_array_rows,num_array_columns) values ('U133B',(select contact_id from contact where name = 'Affymetrix'),(select cvterm_id from cvterm where name = 'photochemical_oligo'),(select cvterm_id from cvterm where name = 'glass'),506944,712,712);
insert into arraydesign (name,manufacturer_id,platformtype_id,substratetype_id) values ('U133 Plus 2.0'    , (select contact_id from contact where name = 'Affymetrix'),(select cvterm_id from cvterm where name = 'photochemical_oligo'),(select cvterm_id from cvterm where name = 'glass'));
insert into arraydesign (name,manufacturer_id,platformtype_id,substratetype_id) values ('U133'             , (select contact_id from contact where name = 'Affymetrix'),(select cvterm_id from cvterm where name = 'photochemical_oligo'),(select cvterm_id from cvterm where name = 'glass'));
insert into arraydesign (name,manufacturer_id,platformtype_id,substratetype_id) values ('U95A'             , (select contact_id from contact where name = 'Affymetrix'),(select cvterm_id from cvterm where name = 'photochemical_oligo'),(select cvterm_id from cvterm where name = 'glass'));
insert into arraydesign (name,manufacturer_id,platformtype_id,substratetype_id) values ('U95B'             , (select contact_id from contact where name = 'Affymetrix'),(select cvterm_id from cvterm where name = 'photochemical_oligo'),(select cvterm_id from cvterm where name = 'glass'));
insert into arraydesign (name,manufacturer_id,platformtype_id,substratetype_id) values ('U95Av2'           , (select contact_id from contact where name = 'Affymetrix'),(select cvterm_id from cvterm where name = 'photochemical_oligo'),(select cvterm_id from cvterm where name = 'glass'));
insert into arraydesign (name,manufacturer_id,platformtype_id,substratetype_id) values ('HuGeneFL'           , (select contact_id from contact where name = 'Affymetrix'),(select cvterm_id from cvterm where name = 'photochemical_oligo'),(select cvterm_id from cvterm where name = 'glass'));
insert into arraydesign (name,manufacturer_id,platformtype_id,substratetype_id) values ('U74Av2'           , (select contact_id from contact where name = 'Affymetrix'),(select cvterm_id from cvterm where name = 'photochemical_oligo'),(select cvterm_id from cvterm where name = 'glass'));
insert into arraydesign (name,manufacturer_id,platformtype_id,substratetype_id) values ('U74Bv2'           , (select contact_id from contact where name = 'Affymetrix'),(select cvterm_id from cvterm where name = 'photochemical_oligo'),(select cvterm_id from cvterm where name = 'glass'));
insert into arraydesign (name,manufacturer_id,platformtype_id,substratetype_id) values ('U74Cv2'           , (select contact_id from contact where name = 'Affymetrix'),(select cvterm_id from cvterm where name = 'photochemical_oligo'),(select cvterm_id from cvterm where name = 'glass'));
insert into arraydesign (name,manufacturer_id,platformtype_id,substratetype_id) values ('U34A'             , (select contact_id from contact where name = 'Affymetrix'),(select cvterm_id from cvterm where name = 'photochemical_oligo'),(select cvterm_id from cvterm where name = 'glass'));
insert into arraydesign (name,manufacturer_id,platformtype_id,substratetype_id) values ('U34C'             , (select contact_id from contact where name = 'Affymetrix'),(select cvterm_id from cvterm where name = 'photochemical_oligo'),(select cvterm_id from cvterm where name = 'glass'));
insert into arraydesign (name,manufacturer_id,platformtype_id,substratetype_id) values ('U34 Toxicology'   , (select contact_id from contact where name = 'Affymetrix'),(select cvterm_id from cvterm where name = 'photochemical_oligo'),(select cvterm_id from cvterm where name = 'glass'));
insert into arraydesign (name,manufacturer_id,platformtype_id,substratetype_id) values ('U34 Neurobiology' , (select contact_id from contact where name = 'Affymetrix'),(select cvterm_id from cvterm where name = 'photochemical_oligo'),(select cvterm_id from cvterm where name = 'glass'));
insert into arraydesign (name,manufacturer_id,platformtype_id,substratetype_id) values ('S98'              , (select contact_id from contact where name = 'Affymetrix'),(select cvterm_id from cvterm where name = 'photochemical_oligo'),(select cvterm_id from cvterm where name = 'glass'));
insert into arraydesign (name,manufacturer_id,platformtype_id,substratetype_id) values ('230A'             , (select contact_id from contact where name = 'Affymetrix'),(select cvterm_id from cvterm where name = 'photochemical_oligo'),(select cvterm_id from cvterm where name = 'glass'));
insert into arraydesign (name,manufacturer_id,platformtype_id,substratetype_id) values ('230 2.0'          , (select contact_id from contact where name = 'Affymetrix'),(select cvterm_id from cvterm where name = 'photochemical_oligo'),(select cvterm_id from cvterm where name = 'glass'));
insert into arraydesign (name,manufacturer_id,platformtype_id,substratetype_id) values ('430A'             , (select contact_id from contact where name = 'Affymetrix'),(select cvterm_id from cvterm where name = 'photochemical_oligo'),(select cvterm_id from cvterm where name = 'glass'));
insert into arraydesign (name,manufacturer_id,platformtype_id,substratetype_id) values ('430B'             , (select contact_id from contact where name = 'Affymetrix'),(select cvterm_id from cvterm where name = 'photochemical_oligo'),(select cvterm_id from cvterm where name = 'glass'));
insert into arraydesign (name,manufacturer_id,platformtype_id,substratetype_id) values ('430 2.0'          , (select contact_id from contact where name = 'Affymetrix'),(select cvterm_id from cvterm where name = 'photochemical_oligo'),(select cvterm_id from cvterm where name = 'glass'));
insert into arraydesign (name,manufacturer_id,platformtype_id,substratetype_id) values ('ATH1'             , (select contact_id from contact where name = 'Affymetrix'),(select cvterm_id from cvterm where name = 'photochemical_oligo'),(select cvterm_id from cvterm where name = 'glass'));

insert into cvterm (name,cv_id) values ('fetus',      (select cv_id from cv where name = 'Ad Hoc Ontology'));
insert into cvterm (name,cv_id) values ('neonate',    (select cv_id from cv where name = 'Ad Hoc Ontology'));
insert into cvterm (name,cv_id) values ('child',      (select cv_id from cv where name = 'Ad Hoc Ontology'));
insert into cvterm (name,cv_id) values ('adult_young',(select cv_id from cv where name = 'Ad Hoc Ontology'));
insert into cvterm (name,cv_id) values ('adult',      (select cv_id from cv where name = 'Ad Hoc Ontology'));
insert into cvterm (name,cv_id) values ('adult_old',  (select cv_id from cv where name = 'Ad Hoc Ontology'));

insert into cvterm (name,cv_id) values ('survival_time',(select cv_id from cv where name = 'Ad Hoc Ontology'));

insert into cvterm (name,definition,cv_id) values ('n','sensu statistica',  (select cv_id from cv where name = 'Statistical Terms'));
insert into cvterm (name,definition,cv_id) values ('minimum','sensu statistica',  (select cv_id from cv where name = 'Statistical Terms'));
insert into cvterm (name,definition,cv_id) values ('maximum','sensu statistica',  (select cv_id from cv where name = 'Statistical Terms'));
insert into cvterm (name,definition,cv_id) values ('modality','sensu statistica',  (select cv_id from cv where name = 'Statistical Terms'));
insert into cvterm (name,definition,cv_id) values ('modality p','sensu statistica',  (select cv_id from cv where name = 'Statistical Terms'));
insert into cvterm (name,definition,cv_id) values ('mean','sensu statistica',  (select cv_id from cv where name = 'Statistical Terms'));
insert into cvterm (name,definition,cv_id) values ('median','sensu statistica',  (select cv_id from cv where name = 'Statistical Terms'));
insert into cvterm (name,definition,cv_id) values ('mode','sensu statistica',  (select cv_id from cv where name = 'Statistical Terms'));
insert into cvterm (name,definition,cv_id) values ('quartile 1','sensu statistica',  (select cv_id from cv where name = 'Statistical Terms'));
insert into cvterm (name,definition,cv_id) values ('quartile 3','sensu statistica',  (select cv_id from cv where name = 'Statistical Terms'));
insert into cvterm (name,definition,cv_id) values ('skewness','sensu statistica',  (select cv_id from cv where name = 'Statistical Terms'));
insert into cvterm (name,definition,cv_id) values ('kurtosis','sensu statistica',  (select cv_id from cv where name = 'Statistical Terms'));
insert into cvterm (name,definition,cv_id) values ('chi square p','sensu statistica',  (select cv_id from cv where name = 'Statistical Terms'));
insert into cvterm (name,definition,cv_id) values ('standard deviation','sensu statistica',  (select cv_id from cv where name = 'Statistical Terms'));

insert into cvterm (name,definition,cv_id) values ('expectation maximization gaussian mean','sensu statistica',  (select cv_id from cv where name = 'Statistical Terms'));
insert into cvterm (name,definition,cv_id) values ('expectation maximization p','sensu statistica',  (select cv_id from cv where name = 'Statistical Terms'));
insert into cvterm (name,definition,cv_id) values ('histogram','sensu statistica',  (select cv_id from cv where name = 'Statistical Terms'));

