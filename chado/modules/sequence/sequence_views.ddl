create view tfeature as
 select * from feature, ontology
 where feature.type_id = ontology.ontology_id;

create view fgene as
 select * from tfeature where term_name = 'gene';

create view fexon as
 select * from tfeature where term_name = 'exon';

create view ftranscript as
 select * from tfeature where term_name = 'transcript';

create view gene2transcript as
 select * from fgene, ftranscript, feature_relationship r
 where fgene.feature_id = r.obj_feature_id
 and ftranscript.feature_id = r.subj_feature_id;

create view transcript2exon as
 select * from ftranscript, fexon, feature_relationship r
 where ftranscript.feature_id = r.obj_feature_id
 and   fexon.feature_id = r.subj_feature_id;


create view genemodel as
 select * from fgene, tfeature1, tfeature2, 
          feature_relationship r1, feature_relationship r2
 where fgene.feature_id = r1.obj_feature_id
 and tfeature1.feature_id = r1.subj_feature_id
 and r1.obj_feature_id = r2.subj_feature_id
 and r2.obj_feature_id = tfeature2.feature_id;



