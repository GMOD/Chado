


alter table featureloc add column min int;
alter table featureloc add column max int;
update featureloc set min=nbeg where strand=1;
update featureloc set max=nend where strand=1;
update featureloc set max=nbeg where strand=-1;
update featureloc set min=nend where strand=-1;
update featureloc set min=nbeg where (strand=0 or strand is null) and
nbeg<nend;
update featureloc set max=nend where (strand=0 or strand is null) and
nbeg<nend;
update featureloc set min=nend where (strand=0 or strand is null) and
nbeg>nend;
update featureloc set max=nbeg where (strand=0 or strand is null) and
nbeg>nend;
create index featureloc_src_min_max on featureloc
(srcfeature_id,min,max);

create or replace view feature_evidence(feature_evidence_id, feature_id, evidence_id) as 
select anchor.feature_id||':'||evloc.feature_id, anchor.feature_id, evloc.feature_id
from featureloc anchor, featureloc evloc, analysisfeature af
where anchor.srcfeature_id=evloc.srcfeature_id 
and evloc.min>anchor.min 
and evloc.max<anchor.max 
and anchor.strand*evloc.strand>-1
and evloc.feature_id = af.feature_id;



create or replace function fn_feature_del() RETURNS TRIGGER AS '
DECLARE 
  f_type cvterm.name%TYPE;
  f_id_gene feature.feature_id%TYPE;
  f_id_transcript feature.feature_id%TYPE;
  f_id_exon feature.feature_id%TYPE;
  f_id_exon_temp feature.feature_id%TYPE; 
  f_id_protein feature.feature_id%TYPE;
  f_id_allele feature.feature_id%TYPE;
  fr_objfeature_id feature.feature_id%TYPE;
  f_type_gene CONSTANT varchar :=''gene'';
  f_type_exon CONSTANT varchar :=''exon'';
  f_type_transcript CONSTANT varchar :=''mRNA'';
  f_type_protein CONSTANT varchar :=''protein'';
  f_type_allele CONSTANT varchar :=''allele'';
  f_return feature.feature_id%TYPE;
  f_row feature%ROWTYPE;
  fr_row_transcript feature_relationship%ROWTYPE;
  fr_row_exon feature_relationship%ROWTYPE;
  fr_row_protein feature_relationship%ROWTYPE;
BEGIN
   f_return:=OLD.feature_id;
   SELECT INTO f_type c.name from feature f, cvterm c where f.feature_id=OLD.feature_id and f.type_id=c.cvterm_id;
   IF f_type=f_type_gene THEN
    SELECT INTO f_id_allele f.feature_id from feature f, feature_relationship fr, cvterm c where f.feature_id=fr.subjfeature_id and fr.objfeature_id=OLD.feature_id and f.type_id=c.cvterm_id and c.name=f_type_allele;
    IF NOT FOUND THEN 
       FOR fr_row_transcript IN SELECt * from feature_relationship fr where fr.objfeature_id=OLD.feature_id LOOP
         SELECT INTO f_id_transcript  f.feature_id from feature f, cvterm c where f.feature_id=fr_row_transcript.subjfeature_id and f.type_id=c.cvterm_id and c.name=f_type_transcript; 
         SELECT INTO f_id_gene f.feature_id from feature f, feature_relationship fr, cvterm c where f.feature_id=fr.objfeature_id and fr.subjfeature_id=f_id_transcript and f.type_id=c.cvterm_id and c.name=f_type_gene and f.feature_id !=OLD.feature_id;
         IF f_id_gene IS NULL and f_id_transcript IS NOT NULL THEN
            RAISE NOTICE ''delete lonely transcript:%'', f_id_transcript;
            delete from feature where feature_id=f_id_transcript;
         ELSIF f_id_gene IS NOT NULL AND F_id_transcript IS NOT NULL THEN
            RAISE NOTICE ''There is another transcript:% associated with this gene:%, so this transcript will be kept'', f_id_transcript,f_id_gene;
         END IF;
      END LOOP;
    ELSE
     RAISE NOTICE ''there is other allele associated with this gene:%'', f_id_allele;
     return NULL;
    END IF;
  ELSIF f_type=f_type_transcript THEN
     FOR fr_row_exon IN SELECT * from feature_relationship fr where fr.objfeature_id=OLD.feature_id LOOP
        select INTO f_id_exon f.feature_id from feature f, cvterm c where f.feature_id=fr_row_exon.subjfeature_id and f.type_id=c.cvterm_id and c.name=f_type_exon;
        SELECT INTO f_id_transcript f.feature_id from feature f, feature_relationship fr, cvterm c where f.feature_id=fr.objfeature_id and fr.subjfeature_id=f_id_exon and f.type_id=c.cvterm_id and c.name=f_type_transcript and f.feature_id!=OLD.feature_id;
        IF f_id_transcript IS NULL and f_id_exon IS NOT NULL THEN
            RAISE NOTICE ''delete lonely exon:%'', f_id_exon;
           delete from feature where feature_id=f_id_exon;         
        ELSIF f_id_transcript IS NOT NULL and f_id_exon IS NOT NULL THEN
            RAISE NOTICE ''There is another transcript:% associated with this exon:%, so this exon will be kept'', f_id_transcript, f_id_exon;
        END IF;    
     END LOOP;

     FOR fr_row_protein IN SELECT * from feature_relationship fr where fr.objfeature_id=OLD.feature_id LOOP
        SELECT INTO f_id_protein f.feature_id from feature f, cvterm c where f.feature_id=fr_row_protein.subjfeature_id and f.type_id=c.cvterm_id and c.name=f_type_protein;
        SELECT INTO f_id_transcript f.feature_id from feature f, feature_relationship fr, cvterm c where f.feature_id=fr.objfeature_id and fr.subjfeature_id=f_id_protein and f.type_id=c.cvterm_id and c.name=f_type_exon and f.feature_id !=OLD.feature_id;
        IF f_id_transcript IS NULL and f_id_protein IS NOT NULL THEN
                  RAISE NOTICE ''delete lonely protein:%'', f_id_protein;
                  delete from feature where feature_id=f_id_protein;
        ELSIF f_id_transcript IS NOT NULL and f_id_protein IS NOT NULL THEN
                  RAISE NOTICE ''There is another transcript:% associated with this protein:%, so this exon will be kept'', f_id_transcript, f_id_protein;
        END IF;
     END LOOP;
  END IF;
  RETURN OLD; 
END;
'LANGUAGE 'plpgsql';

CREATE TRIGGER tr_feature_del BEFORE DELETE ON feature for EACH ROW EXECUTE PROCEDURE fn_feature_del();







