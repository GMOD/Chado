
alter table featureloc add column fmin int;
alter table featureloc add column fmax int;
update featureloc set fmin=nbeg where strand=1;
update featureloc set fmax=nend where strand=1;
update featureloc set fmax=nbeg where strand=-1;
update featureloc set fmin=nend where strand=-1;
update featureloc set fmin=nbeg where (strand=0 or strand is null) and
nbeg<nend;
update featureloc set fmax=nend where (strand=0 or strand is null) and
nbeg<nend;
update featureloc set fmin=nend where (strand=0 or strand is null) and
nbeg>nend;
update featureloc set fmax=nbeg where (strand=0 or strand is null) and
nbeg>nend;
create index featureloc_src_min_max on featureloc
(srcfeature_id,fmin,fmax);


create or replace view alignment_evidence(alignment_evidence_id, feature_id, evidence_id, analysis_id) as 
select  anchor.feature_id||':'||fr.object_id||':'||af.analysis_id,   anchor.feature_id, fr.object_id, af.analysis_id
from featureloc anchor, analysisfeature af, feature_relationship fr, featureloc hsploc
where anchor.srcfeature_id=hsploc.srcfeature_id 
and hsploc.fmin>anchor.fmin 
and hsploc.fmax<anchor.fmax 
and hsploc.feature_id = af.feature_id
and hsploc.feature_id=fr.subject_id
group by anchor.feature_id, fr.object_id, af.analysis_id
;

create or replace view prediction_evidence(prediction_evidence_id, feature_id, evidence_id, analysis_id) as 
select anchor.feature_id||':'||evloc.feature_id||':'||af.analysis_id, anchor.feature_id, evloc.feature_id, af.analysis_id
from featureloc anchor, featureloc evloc, analysisfeature af
where anchor.srcfeature_id=evloc.srcfeature_id 
and evloc.fmin>anchor.fmin 
and evloc.fmax<anchor.fmax 
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
  fr_object_id feature.feature_id%TYPE;
  f_type_gene CONSTANT varchar :=''gene'';
  f_type_exon CONSTANT varchar :=''exon'';
  f_type_transcript CONSTANT varchar :=''mRNA'';
  f_type_protein CONSTANT varchar :=''protein'';
  f_type_allele CONSTANT varchar :=''alleleof'';
  f_return feature.feature_id%TYPE;
  f_row feature%ROWTYPE;
  fr_row_transcript feature_relationship%ROWTYPE;
  fr_row_exon feature_relationship%ROWTYPE;
  fr_row_protein feature_relationship%ROWTYPE;
BEGIN
   f_return:=OLD.feature_id;
   SELECT INTO f_type c.name from feature f, cvterm c where f.feature_id=OLD.feature_id and f.type_id=c.cvterm_id;
   IF f_type=f_type_gene THEN
    SELECT INTO f_id_allele fr.subject_id from  feature_relationship fr, cvterm c where  (fr.object_id=OLD.feature_id or fr.subject_id=OLD.feature_id)  and fr.type_id=c.cvterm_id and c.name=f_type_allele;
    IF NOT FOUND THEN 
       FOR fr_row_transcript IN SELECt * from feature_relationship fr where fr.object_id=OLD.feature_id LOOP
         SELECT INTO f_id_transcript  f.feature_id from feature f, cvterm c where f.feature_id=fr_row_transcript.subject_id and f.type_id=c.cvterm_id and c.name=f_type_transcript; 
         SELECT INTO f_id_gene f.feature_id from feature f, feature_relationship fr, cvterm c where f.feature_id=fr.object_id and fr.subject_id=f_id_transcript and f.type_id=c.cvterm_id and c.name=f_type_gene and f.feature_id !=OLD.feature_id;
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
     FOR fr_row_exon IN SELECT * from feature_relationship fr where fr.object_id=OLD.feature_id LOOP
        select INTO f_id_exon f.feature_id from feature f, cvterm c where f.feature_id=fr_row_exon.subject_id and f.type_id=c.cvterm_id and c.name=f_type_exon;
        SELECT INTO f_id_transcript f.feature_id from feature f, feature_relationship fr, cvterm c where f.feature_id=fr.object_id and fr.subject_id=f_id_exon and f.type_id=c.cvterm_id and c.name=f_type_transcript and f.feature_id!=OLD.feature_id;
        IF f_id_transcript IS NULL and f_id_exon IS NOT NULL THEN
            RAISE NOTICE ''delete lonely exon:%'', f_id_exon;
           delete from feature where feature_id=f_id_exon;         
        ELSIF f_id_transcript IS NOT NULL and f_id_exon IS NOT NULL THEN
            RAISE NOTICE ''There is another transcript:% associated with this exon:%, so this exon will be kept'', f_id_transcript, f_id_exon;
        END IF;    
     END LOOP;

     FOR fr_row_protein IN SELECT * from feature_relationship fr where fr.object_id=OLD.feature_id LOOP
        SELECT INTO f_id_protein f.feature_id from feature f, cvterm c where f.feature_id=fr_row_protein.subject_id and f.type_id=c.cvterm_id and c.name=f_type_protein;
        SELECT INTO f_id_transcript f.feature_id from feature f, feature_relationship fr, cvterm c where f.feature_id=fr.object_id and fr.subject_id=f_id_protein and f.type_id=c.cvterm_id and c.name=f_type_exon and f.feature_id !=OLD.feature_id;
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







----June 18 2003, will assign CG/CR for temp gene ----

create or replace function feature_assignname_fn_i() RETURNS TRIGGER AS '
DECLARE
maxid int;
id    varchar(255);
maxid_fb int;
id_fb    varchar(255);
len   int;
f_row_g feature%ROWTYPE;
f_row_e feature%ROWTYPE;
f_row_t feature%ROWTYPE;
f_row_p feature%ROWTYPE;
f_type  cvterm.name%TYPE;
letter_t varchar;
letter_p varchar;
f_dbxref_id feature.dbxref_id%TYPE;
fb_accession dbxref.accession%TYPE;
d_accession dbxref.accession%TYPE;
f_uniquename feature.uniquename%TYPE;
f_uniquename_tr feature.uniquename%TYPE;
f_uniquename_exon feature.uniquename%TYPE;
f_uniquename_protein feature.uniquename%TYPE;
s_type_id            synonym.type_id%TYPE;
s_id                 synonym.synonym_id%TYPE;
p_id                 pub.pub_id%TYPE;
fr_row feature_relationship%ROWTYPE;
  f_type_gene CONSTANT varchar :=''gene'';
  f_type_exon CONSTANT varchar :=''exon'';
  f_type_transcript CONSTANT varchar :=''mRNA'';
  f_type_protein CONSTANT varchar :=''protein'';
  f_type_allele CONSTANT varchar :=''allele'';
  f_dbname_gadfly CONSTANT varchar :=''Gadfly'';
  f_dbname_FB CONSTANT varchar :=''FlyBase'';
  o_genus  CONSTANT varchar :=''Drosophila'';
  o_species  CONSTANT varchar:=''melanogaster'';
  c_name_synonym CONSTANT varchar:=''synonym'';
  cv_cvname_synonym CONSTANT varchar:=''synonym type'';
  p_miniref         CONSTANT varchar:=''GadFly'';
BEGIN
  IF (NEW.uniquename like ''CG:temp%'' or NEW.uniquename like ''CR:temp%'') and  NEW.uniquename not like ''%-%''  THEN
      SELECT INTO f_type c.name from feature f, cvterm c, organism o where f.type_id=c.cvterm_id and f.uniquename=NEW.uniquename and f.organism_id =NEW.organism_id;
      IF f_type is NOT NULL THEN
        RAISE NOTICE ''type of this feature is:%'', f_type;
      END IF;
      IF f_type=f_type_gene THEN
          SELECT INTO f_row_g * from feature where uniquename=NEW.uniquename;
          IF f_row_g.uniquename like ''CG%'' THEN
               SELECT INTO maxid max(to_number(substring(accession from 3 for 7), ''99999'')) from dbxref where dbname=f_dbname_gadfly and accession like ''CG%'' and accession not like ''%:%'' and accession not like ''%-%'';
               IF maxid IS NULL THEN
                   maxid:=1;
               ELSE
                   maxid:=maxid+1;
               END IF;
               id:=lpad(maxid, 5, ''00000'');
               f_uniquename:=CAST(''CG''||id as TEXT);
          ELSIF f_row_g.uniquename like ''CR%'' THEN
               SELECT INTO maxid max(to_number(substring(accession from 3 for 7), ''99999'')) from dbxref where dbname=f_dbname_gadfly and accession like ''CR%'' and accession not like ''%:%'' and accession not like ''%-%'';
               IF maxid IS NULL THEN
                   maxid:=1;
               ELSE
                   maxid:=maxid+1;
               END IF;
               id:=lpad(maxid, 5, ''00000'');
               f_uniquename:=CAST(''CR''||id as TEXT);
          END IF;

               INSERT INTO dbxref(dbname, accession ) values(f_dbname_gadfly, f_uniquename);
               SELECT INTO f_dbxref_id dbxref_id from dbxref where dbname=f_dbname_gadfly and accession=f_uniquename;
               IF NEW.name like ''CG:temp%'' or NEW.name like ''CR:temp%'' THEN
                   UPDATE feature set uniquename=f_uniquename, dbxref_id=f_dbxref_id, name=f_uniquename where feature_id=f_row_g.feature_id;
               ELSE
                   UPDATE feature set uniquename=f_uniquename, dbxref_id=f_dbxref_id where feature_id=f_row_g.feature_id;
               END IF;
               RAISE NOTICE ''old uniquename of this feature is:%'', f_row_g.uniquename;
               RAISE NOTICE ''new uniquename of this feature is:%'', f_uniquename;
               INSERT INTO feature_dbxref(feature_id, dbxref_id) values(f_row_g.feature_id, f_dbxref_id);
               SELECT INTO s_type_id cvterm_id from cvterm c, cv cv where name=c_name_synonym and cvname=cv_cvname_synonym and c.cv_id=cv.cv_id;
               INSERT INTO synonym(name, synonym_sgml, type_id) values(f_uniquename, f_uniquename, s_type_id);
               SELECT INTO s_id synonym_id from synonym where name=f_uniquename and type_id=s_type_id;
               SELECT INTO p_id pub_id from pub where miniref=p_miniref;
               INSERT INTO feature_synonym(feature_id, synonym_id, pub_id, is_current) values (f_row_g.feature_id, s_id, p_id, ''true'');

      END IF;
  END IF; 
   return f_row_g;   
END;
'LANGUAGE 'plpgsql';

CREATE TRIGGER feature_assignname_tr_i AFTER INSERT ON feature for EACH ROW EXECUTE PROCEDURE feature_assignname_fn_i();