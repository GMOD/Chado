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
insert into cv (name,definition) values ('local','Locally created terms');
insert into cv (name,definition) values ('Statistical Terms','Locally created terms for statistics');
insert into db (name, contact_id,description) values ('null',(select contact_id from contact where name = 'null'),'a fake database for local items');

insert into dbxref (db_id,accession) values ((select db_id from db where name='null'), 'local:null');
insert into cvterm (name,cv_id,dbxref_id) values ('null',(select cv_id from cv where name = 'null'),(select dbxref_id from dbxref where accession='local:null'));

insert into dbxref (db_id,accession) values ((select db_id from db where name='null'), 'local:Note');
insert into cvterm (name,cv_id,dbxref_id) values ('Note', (select cv_id from cv where name = 'null'),(select dbxref_id from dbxref where accession='local:Note'));

insert into dbxref (db_id,accession) values ((select db_id from db where name='null'), 'local:computer file');
insert into cvterm (name,cv_id,dbxref_id) values ('computer file', (select cv_id from cv where name = 'null'),(select dbxref_id from dbxref where accession='local:computer file'));

insert into dbxref (db_id,accession) values ((select db_id from db where name='null'), 'local:synonym');
insert into cvterm (name,cv_id,dbxref_id) values ('synonym', (select cv_id from cv where name = 'null'),(select dbxref_id from dbxref where accession='local:synonym'));

insert into dbxref (db_id,accession) values ((select db_id from db where name='null'), 'local:score');
insert into cvterm (name,cv_id,dbxref_id) values ('score', (select cv_id from cv where name = 'null'), (select dbxref_id from dbxref where accession='local:score'));

insert into dbxref (db_id,accession) values ((select db_id from db where name='null'), 'local:glass');
insert into cvterm (name,definition,cv_id,dbxref_id) values ('glass','glass array',(select cv_id from cv where name = 'local'),(select dbxref_id from dbxref where accession='local:glass'));

insert into dbxref (db_id,accession) values ((select db_id from db where name='null'), 'local:photochemical_oligo');
insert into cvterm (name,definition,cv_id,dbxref_id) values ('photochemical_oligo','in-situ photochemically synthesized oligoes',(select cv_id from cv where name = 'local'),(select dbxref_id from dbxref where accession='local:photochemical_oligo'));

insert into pub (miniref,uniquename,type_id) values ('null','null',(select cvterm_id from cvterm where name = 'null'));
insert into db (name, contact_id,description) values ('GFF_source', (select contact_id from contact where name = 'null'), 'A collection of sources (ie, column 2) from GFF files');
insert into db (name, contact_id) values ('DB:refseq'   ,(select contact_id from contact where name = 'null'));
insert into db (name, contact_id) values ('DB:genbank'  ,(select contact_id from contact where name = 'null'));
insert into db (name, contact_id) values ('DB:EMBL'     ,(select contact_id from contact where name = 'null'));
insert into db (name, contact_id) values ('DB:TIGR'     ,(select contact_id from contact where name = 'null'));
insert into db (name, contact_id) values ('DB:ucsc'     ,(select contact_id from contact where name = 'null'));
insert into db (name, contact_id) values ('DB:ucla'     ,(select contact_id from contact where name = 'null'));
insert into db (name, contact_id) values ('DB:SGD',(select contact_id from contact where name = 'null'));

insert into db (name, contact_id) values ('DB:PFAM',(select contact_id from contact where name = 'null'));
insert into db (name, contact_id) values ('DB:SUPERFAMILY',(select contact_id from contact where name = 'null'));
insert into db (name, contact_id) values ('DB:PROFILE',(select contact_id from contact where name = 'null'));
insert into db (name, contact_id) values ('DB:PRODOM',(select contact_id from contact where name = 'null'));
insert into db (name, contact_id) values ('DB:PRINTS',(select contact_id from contact where name = 'null'));
insert into db (name, contact_id) values ('DB:SMART',(select contact_id from contact where name = 'null'));
insert into db (name, contact_id) values ('DB:TIGRFAMs',(select contact_id from contact where name = 'null'));
insert into db (name, contact_id) values ('DB:PIR',(select contact_id from contact where name = 'null'));

insert into db (name, contact_id,description) values ('DB:GR',(select contact_id from contact where name = 'null'),'Gramene');
insert into db (name, contact_id, description, urlprefix) values ('DB:uniprot',(select contact_id from contact where name = 'null'),'UniProt/TrEMBL','http://us.expasy.org/cgi-bin/niceprot.pl?');
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

insert into cv (name) values ('developmental statges');
insert into dbxref (db_id,accession) values ((select db_id from db where name='null'), 'developmental statges:fetus');
insert into cvterm (name,cv_id,dbxref_id) values ('fetus',      (select cv_id from cv where name = 'local'),(select dbxref_id from dbxref where accession='developmental statges:fetus'));

insert into dbxref (db_id,accession) values ((select db_id from db where name='null'), 'developmental statges:neonate');
insert into cvterm (name,cv_id,dbxref_id) values ('neonate',    (select cv_id from cv where name = 'developmental statges'), (select dbxref_id from dbxref where accession='developmental statges:neonate'));

insert into dbxref (db_id,accession) values ((select db_id from db where name='null'), 'developmental statges:child');
insert into cvterm (name,cv_id,dbxref_id) values ('child',      (select cv_id from cv where name = 'developmental statges'), (select dbxref_id from dbxref where accession='developmental statges:child'));

insert into dbxref (db_id,accession) values ((select db_id from db where name='null'), 'developmental statges:adult_young');
insert into cvterm (name,cv_id,dbxref_id) values ('adult_young',(select cv_id from cv where name = 'developmental statges'),(select dbxref_id from dbxref where accession='developmental statges:adult_young'));

insert into dbxref (db_id,accession) values ((select db_id from db where name='null'), 'developmental statges:adult');
insert into cvterm (name,cv_id,dbxref_id) values ('adult',      (select cv_id from cv where name = 'developmental statges'),(select dbxref_id from dbxref where accession='developmental statges:adult'));

insert into dbxref (db_id,accession) values ((select db_id from db where name='null'), 'developmental statges:adult_old');
insert into cvterm (name,cv_id,dbxref_id) values ('adult_old',  (select cv_id from cv where name = 'developmental statges'), (select dbxref_id from dbxref where accession='developmental statges:adult_old'));

insert into dbxref (db_id,accession) values ((select db_id from db where name='null'), 'local:survival_time');
insert into cvterm (name,cv_id,dbxref_id) values ('survival_time',(select cv_id from cv where name = 'local'),(select dbxref_id from dbxref where accession='local:survival_time'));


insert into dbxref (db_id,accession) values ((select db_id from db where name='null'), 'Statistical Terms:n');
insert into cvterm (name,definition,cv_id,dbxref_id) values ('n','sensu statistica',  (select cv_id from cv where name = 'Statistical Terms'),(select dbxref_id from dbxref where accession='Statistical Terms:n'));

insert into dbxref (db_id,accession) values ((select db_id from db where name='null'), 'Statistical Terms:minimum');
insert into cvterm (name,definition,cv_id,dbxref_id) values ('minimum','sensu statistica',  (select cv_id from cv where name = 'Statistical Terms'),(select dbxref_id from dbxref where accession='Statistical Terms:minimum'));

insert into dbxref (db_id,accession) values ((select db_id from db where name='null'), 'Statistical Terms:maximum');
insert into cvterm (name,definition,cv_id,dbxref_id) values ('maximum','sensu statistica',  (select cv_id from cv where name = 'Statistical Terms'),(select dbxref_id from dbxref where accession='Statistical Terms:maximum'));

insert into dbxref (db_id,accession) values ((select db_id from db where name='null'), 'Statistical Terms:modality');
insert into cvterm (name,definition,cv_id,dbxref_id) values ('modality','sensu statistica',  (select cv_id from cv where name = 'Statistical Terms'),(select dbxref_id from dbxref where accession='Statistical Terms:modality'));

insert into dbxref (db_id,accession) values ((select db_id from db where name='null'), 'Statistical Terms:modality p');
insert into cvterm (name,definition,cv_id,dbxref_id) values ('modality p','sensu statistica',  (select cv_id from cv where name = 'Statistical Terms'),(select dbxref_id from dbxref where accession='Statistical Terms:modality p'));

insert into dbxref (db_id,accession) values ((select db_id from db where name='null'), 'Statistical Terms:mean');
insert into cvterm (name,definition,cv_id,dbxref_id) values ('mean','sensu statistica',  (select cv_id from cv where name = 'Statistical Terms'),(select dbxref_id from dbxref where accession='Statistical Terms:mean'));

insert into dbxref (db_id,accession) values ((select db_id from db where name='null'), 'Statistical Terms:median');
insert into cvterm (name,definition,cv_id,dbxref_id) values ('median','sensu statistica',  (select cv_id from cv where name = 'Statistical Terms'),(select dbxref_id from dbxref where accession='Statistical Terms:median'));

insert into dbxref (db_id,accession) values ((select db_id from db where name='null'), 'Statistical Terms:mode');
insert into cvterm (name,definition,cv_id,dbxref_id) values ('mode','sensu statistica',  (select cv_id from cv where name = 'Statistical Terms'),(select dbxref_id from dbxref where accession='Statistical Terms:mode'));

insert into dbxref (db_id,accession) values ((select db_id from db where name='null'), 'Statistical Terms:quartile 1');
insert into cvterm (name,definition,cv_id,dbxref_id) values ('quartile 1','sensu statistica',  (select cv_id from cv where name = 'Statistical Terms'),(select dbxref_id from dbxref where accession='Statistical Terms:quartile 1'));

insert into dbxref (db_id,accession) values ((select db_id from db where name='null'), 'Statistical Terms:quartile 3');
insert into cvterm (name,definition,cv_id,dbxref_id) values ('quartile 3','sensu statistica',  (select cv_id from cv where name = 'Statistical Terms'),(select dbxref_id from dbxref where accession='Statistical Terms:quartile 3'));

insert into dbxref (db_id,accession) values ((select db_id from db where name='null'), 'Statistical Terms:skewness');
insert into cvterm (name,definition,cv_id,dbxref_id) values ('skewness','sensu statistica',  (select cv_id from cv where name = 'Statistical Terms'),(select dbxref_id from dbxref where accession='Statistical Terms:skewness'));

insert into dbxref (db_id,accession) values ((select db_id from db where name='null'), 'Statistical Terms:kurtosis');
insert into cvterm (name,definition,cv_id,dbxref_id) values ('kurtosis','sensu statistica',  (select cv_id from cv where name = 'Statistical Terms'),(select dbxref_id from dbxref where accession='Statistical Terms:kurtosis'));

insert into dbxref (db_id,accession) values ((select db_id from db where name='null'), 'Statistical Terms:chi square p');
insert into cvterm (name,definition,cv_id,dbxref_id) values ('chi square p','sensu statistica',  (select cv_id from cv where name = 'Statistical Terms'),(select dbxref_id from dbxref where accession='Statistical Terms:chi square p'));

insert into dbxref (db_id,accession) values ((select db_id from db where name='null'), 'Statistical Terms:standard deviation');
insert into cvterm (name,definition,cv_id,dbxref_id) values ('standard deviation','sensu statistica',  (select cv_id from cv where name = 'Statistical Terms'),(select dbxref_id from dbxref where accession='Statistical Terms:standard deviation'));

insert into dbxref (db_id,accession) values ((select db_id from db where name='null'), 'Statistical Terms:expectation maximization gaussian mean');
insert into cvterm (name,definition,cv_id,dbxref_id) values ('expectation maximization gaussian mean','sensu statistica',  (select cv_id from cv where name = 'Statistical Terms'),(select dbxref_id from dbxref where accession='Statistical Terms:expectation maximization gaussian mean'));

insert into dbxref (db_id,accession) values ((select db_id from db where name='null'), 'Statistical Terms:expectation maximization p');
insert into cvterm (name,definition,cv_id,dbxref_id) values ('expectation maximization p','sensu statistica',  (select cv_id from cv where name = 'Statistical Terms'),(select dbxref_id from dbxref where accession='Statistical Terms:expectation maximization p'));

insert into dbxref (db_id,accession) values ((select db_id from db where name='null'), 'Statistical Terms:histogram');
insert into cvterm (name,definition,cv_id,dbxref_id) values ('histogram','sensu statistica',  (select cv_id from cv where name = 'Statistical Terms'),(select dbxref_id from dbxref where accession='Statistical Terms:histogram'));

insert into cv (name,definition) values ('autocreated','Terms that are automatically inserted by loading software');
