-- these are nearly identical to the triggers that flybase uses, but will
-- serve as the foundation of general triggers for GMOD.  Things that need to
-- be done:
--
--* indentify the items that have to be dynamically (at make time) extrapolated.
--* allow a more flexible naming scheme
--* remove the portion creating a flybase dbxref.
--* probably 20 more things I haven't thought of yet.



--gets the next available uniquename; note that it is
--destructive because it calls nextval on a sequence 
CREATE OR REPLACE FUNCTION next_uniquename() RETURNS varchar AS '
DECLARE
  prename      varchar;
  f_uniquename varchar;
  prefix       varchar;
  suffix       varchar;
  id           varchar;
  maxid        int;
BEGIN
  SELECT INTO prefix cp.value FROM cvtermprop cp, cvterm, cv
                             WHERE cvterm.name = ''prefix'' and
                                   cp.cvterm_id = cvterm.cvterm_id and
                                   cvterm.cv_id = cv.cv_id and
                                   cv.name = ''apollo'';
  SELECT INTO suffix cp.value FROM cvtermprop cp, cvterm, cv
                             WHERE cvterm.name = ''suffix'' and
                                   cp.cvterm_id = cvterm.cvterm_id and
                                   cvterm.cv_id = cv.cv_id and
                                   cv.name = ''apollo'';

  SELECT INTO maxid nextval(''uniquename_id_generator'');
  RAISE NOTICE ''maxid is:%'', maxid;
  id:=lpad(maxid, 6, ''000000'');
  f_uniquename:=CAST(prefix||id||suffix as VARCHAR);
  RETURN f_uniquename;
END;
'LANGUAGE plpgsql;

DROP TRIGGER tr_feature_del  ON feature;
CREATE OR REPLACE function fn_feature_del() RETURNS TRIGGER AS '
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
  f_type_snoRNA CONSTANT varchar :=''snoRNA'';
  f_type_ncRNA CONSTANT varchar :=''ncRNA'';
  f_type_snRNA CONSTANT varchar :=''snRNA'';
  f_type_tRNA CONSTANT varchar :=''tRNA'';
  f_type_rRNA CONSTANT varchar :=''rRNA'';
  f_type_promoter CONSTANT varchar :=''promoter'';
  f_type_repeat_region CONSTANT varchar :=''repeat_region'';
  f_type_miRNA CONSTANT varchar :=''miRNA'';
  f_type_transposable_element CONSTANT varchar :=''transposable_element'';
  f_type_pseudo CONSTANT varchar :=''pseudogene'';
  f_type_protein CONSTANT varchar :=''protein'';
  f_type_allele CONSTANT varchar :=''alleleof'';
  f_return feature.feature_id%TYPE;
  f_row feature%ROWTYPE;
  fr_row_transcript feature_relationship%ROWTYPE;
  fr_row_exon feature_relationship%ROWTYPE;
  fr_row_protein feature_relationship%ROWTYPE;
  message   varchar(255);
BEGIN
   RAISE NOTICE ''enter f_d, feature uniquename:%, type_id:%'',OLD.uniquename, OLD.type_id;
   f_return:=OLD.feature_id;
   SELECT INTO f_type c.name from feature f, cvterm c where f.feature_id=OLD.feature_id and f.type_id=c.cvterm_id;
   IF f_type=f_type_gene THEN
       SELECT INTO f_id_allele fr.subject_id from  feature_relationship fr, cvterm c where  (fr.object_id=OLD.feature_id or fr.subject_id=OLD.feature_id)  and fr.type_id=c.cvterm_id and c.name=f_type_allele;
       IF NOT FOUND THEN 
           FOR fr_row_transcript IN SELECT * from feature_relationship fr where fr.object_id=OLD.feature_id LOOP
               SELECT INTO f_id_transcript  f.feature_id from feature f, cvterm c where f.feature_id=fr_row_transcript.subject_id and f.type_id=c.cvterm_id and (c.name=f_type_transcript or c.name=f_type_ncRNA or c.name=f_type_snoRNA or c.name=f_type_snRNA or c.name=f_type_tRNA  or c.name=f_type_rRNA  or c.name=f_type_pseudo  or c.name=f_type_miRNA or c.name=f_type_transposable_element or c.name=f_type_promoter or c.name=f_type_repeat_region); 
               SELECT INTO f_id_gene f.feature_id from feature f, feature_relationship fr, cvterm c where f.feature_id=fr.object_id and fr.subject_id=f_id_transcript and f.type_id=c.cvterm_id and c.name=f_type_gene and f.feature_id !=OLD.feature_id;
               IF f_id_gene IS NULL and f_id_transcript IS NOT NULL THEN
                   RAISE NOTICE ''delete lonely transcript:%'', f_id_transcript;
                   message:=CAST(''delete lonely transcript''||f_id_transcript AS TEXT);
                   insert into trigger_log(value, table_name, id) values(message, ''feature'', f_id_transcript);
                   delete from feature where feature_id=f_id_transcript;
               ELSIF f_id_gene IS NOT NULL AND F_id_transcript IS NOT NULL THEN
                   RAISE NOTICE ''There is another gene:% associated with this transcript:%, so this transcript will be kept'',f_id_gene, f_id_transcript;
                   message:=CAST(''There is another gene:''||f_id_gene||'' associated with this transcript:''||f_id_transcript AS TEXT); 
               END IF;
           END LOOP;
           message:=CAST(''delete gene:''||OLD.feature_id AS TEXT);
           insert into trigger_log(value, table_name, id) values(message, ''feature'', OLD.feature_id);
       ELSE
           RAISE NOTICE ''there is other allele associated with this gene:%'', f_id_allele;
              message:=CAST(''There is other allele associated with this gene:''||f_id_allele AS TEXT); 
           insert into trigger_log(value, table_name, id) values(message, ''feature'', f_id_transcript);
           return NULL;
       END IF;
   ELSIF (f_type=f_type_transcript or f_type=f_type_ncRNA or f_type=f_type_snoRNA or f_type=f_type_snRNA or f_type=f_type_tRNA  or f_type=f_type_rRNA or f_type=f_type_pseudo or  f_type=f_type_miRNA or f_type=f_type_transposable_element or f_type=f_type_promoter or f_type=f_type_repeat_region) THEN
       FOR fr_row_exon IN SELECT * from feature_relationship fr where fr.object_id=OLD.feature_id LOOP
           select INTO f_id_exon f.feature_id from feature f, cvterm c where f.feature_id=fr_row_exon.subject_id and f.type_id=c.cvterm_id and c.name=f_type_exon;
           SELECT INTO f_id_transcript f.feature_id from feature f, feature_relationship fr, cvterm c where f.feature_id=fr.object_id and fr.subject_id=f_id_exon and f.type_id=c.cvterm_id and (c.name=f_type_transcript or c.name=f_type_ncRNA or c.name=f_type_snoRNA or c.name=f_type_snRNA or c.name=f_type_tRNA  or c.name=f_type_rRNA  or c.name=f_type_pseudo  or c.name=f_type_miRNA or c.name=f_type_transposable_element or c.name=f_type_promoter or c.name=f_type_repeat_region) and f.feature_id!=OLD.feature_id;
           IF f_id_transcript IS NULL and f_id_exon IS NOT NULL THEN
               RAISE NOTICE ''delete lonely exon:%'', f_id_exon;
               delete from feature where feature_id=f_id_exon; 
               message:=CAST(''delete lonely exon:''||f_id_exon AS TEXT); 
               insert into trigger_log(value, table_name, id) values(message, ''feature'', f_id_exon);        
           ELSIF f_id_transcript IS NOT NULL and f_id_exon IS NOT NULL THEN
               RAISE NOTICE ''There is another transcript:% associated with this exon:%, so this exon will be kept'', f_id_transcript, f_id_exon;
               message:=CAST(''There is another transcript:''||f_id_transcript||'' associated with this exon:''||f_id_exon AS TEXT); 
               insert into trigger_log(value, table_name, id) values(message, ''feature'', f_id_exon);  
           END IF;    
       END LOOP;

       FOR fr_row_protein IN SELECT * from feature_relationship fr where fr.object_id=OLD.feature_id LOOP
           SELECT INTO f_id_protein f.feature_id from feature f, cvterm c where f.feature_id=fr_row_protein.subject_id and f.type_id=c.cvterm_id and c.name=f_type_protein;
           SELECT INTO f_id_transcript f.feature_id from feature f, feature_relationship fr, cvterm c where f.feature_id=fr.object_id and fr.subject_id=f_id_protein and f.type_id=c.cvterm_id and (c.name=f_type_transcript or c.name=f_type_ncRNA or c.name=f_type_snoRNA or c.name=f_type_snRNA or c.name=f_type_tRNA  or c.name=f_type_rRNA   or c.name=f_type_pseudo or  c.name=f_type_miRNA or c.name=f_type_transposable_element or c.name=f_type_promoter or c.name=f_type_repeat_region) and f.feature_id !=OLD.feature_id;
           IF f_id_transcript IS NULL and f_id_protein IS NOT NULL THEN
               RAISE NOTICE ''delete lonely protein:%'', f_id_protein;
               delete from feature where feature_id=f_id_protein;
               message:=CAST(''delete lonely protein:''||f_id_protein AS TEXT); 
               insert into trigger_log(value, table_name, id) values(message, ''feature'', f_id_protein);  
           ELSIF f_id_transcript IS NOT NULL and f_id_protein IS NOT NULL THEN
               RAISE NOTICE ''There is another transcript:% associated with this protein:%, so this exon will be kept'', f_id_transcript, f_id_protein;
           END IF;
       END LOOP;
   END IF;
   RAISE NOTICE ''leave f_d ....'';
   RETURN OLD; 
END;
'LANGUAGE plpgsql;

GRANT ALL ON FUNCTION fn_feature_del() TO PUBLIC;

CREATE TRIGGER tr_feature_del BEFORE DELETE ON feature for EACH ROW EXECUTE PROCEDURE fn_feature_del();

DROP TRIGGER feature_assignname_tr_i ON feature;
CREATE OR REPLACE FUNCTION feature_assignname_fn_i() RETURNS TRIGGER AS '
DECLARE
  maxid      int;
  pos        int;
  id         varchar(255);
  max_id     int;
  is_anal    feature.is_analysis%TYPE;
  prefix     cvtermprop.value%TYPE;
  suffix     cvtermprop.value%TYPE;
  f_row_g    feature%ROWTYPE;
  f_row_e    feature%ROWTYPE;
  f_row_t    feature%ROWTYPE;
  f_row_p    feature%ROWTYPE;
  f_type     cvterm.name%TYPE;
  f_type_id  cvterm.cvterm_id%TYPE;
  letter_t   varchar;
  letter_p   varchar;
  f_uniquename_temp    feature.uniquename%TYPE;
  f_uniquename         feature.uniquename%TYPE;
  f_uniquename_tr      feature.uniquename%TYPE;
  f_uniquename_exon    feature.uniquename%TYPE;
  f_uniquename_protein feature.uniquename%TYPE;
  f_name               feature.name%TYPE;
  s_type_id            synonym.type_id%TYPE;
  s_id                 synonym.synonym_id%TYPE;
  c_cv_id              cv.cv_id%TYPE;
  f_s_id               feature_synonym.feature_synonym_id%TYPE;
  fr_row feature_relationship%ROWTYPE;
  f_type_gene CONSTANT varchar :=''gene'';
  f_type_exon CONSTANT varchar :=''exon'';
  f_type_transcript CONSTANT varchar :=''mRNA'';
  f_type_snoRNA CONSTANT varchar :=''snoRNA'';
  f_type_ncRNA CONSTANT varchar :=''ncRNA'';
  f_type_snRNA CONSTANT varchar :=''snRNA'';
  f_type_tRNA CONSTANT varchar :=''tRNA'';
  f_type_rRNA CONSTANT varchar :=''rRNA'';
  f_type_promoter CONSTANT varchar :=''promoter'';
  f_type_repeat_region CONSTANT varchar :=''repeat_region'';
  f_type_miRNA CONSTANT varchar :=''miRNA'';
  f_type_transposable_element CONSTANT varchar :=''transposable_element'';
  f_type_pseudo CONSTANT varchar :=''pseudogene'';
  f_type_protein CONSTANT varchar :=''protein'';
  f_type_allele CONSTANT varchar :=''alleleof'';
  f_type_remark CONSTANT varchar :=''remark'';
  f_dbname_gadfly CONSTANT varchar :=''DB:GR'';
  f_dbname_FB CONSTANT varchar :=''null'';
  o_genus  CONSTANT varchar :=''Oryza'';
  o_species  CONSTANT varchar:=''sativa'';
  c_name_synonym CONSTANT varchar:=''synonym'';
  cv_cvname_synonym CONSTANT varchar:=''null'';
  p_miniref         CONSTANT varchar:=''null'';
  p_id  pub.pub_id%TYPE;
BEGIN
  SELECT INTO is_anal is_analysis FROM feature WHERE uniquename = NEW.uniquename and 
                                                     type_id = NEW.type_id and 
                                                     organism_id = NEW.organism_id;
  IF (is_anal) THEN
      RETURN NEW;
  END IF;

  SELECT INTO prefix cp.value FROM cvtermprop cp, cvterm, cv
                             WHERE cvterm.name = ''prefix'' and
                                   cp.cvterm_id = cvterm.cvterm_id and
                                   cvterm.cv_id = cv.cv_id and
                                   cv.name = ''apollo'';
  SELECT INTO suffix cp.value FROM cvtermprop cp, cvterm, cv
                             WHERE cvterm.name = ''suffix'' and
                                   cp.cvterm_id = cvterm.cvterm_id and
                                   cvterm.cv_id = cv.cv_id and
                                   cv.name = ''apollo'';
  SELECT INTO f_type c.name
         from feature f, cvterm c
         where f.type_id=c.cvterm_id and
               f.uniquename=NEW.uniquename and
               f.organism_id =NEW.organism_id;
  SELECT INTO p_id pub_id from pub where uniquename = p_miniref;
  SELECT INTO s_type_id cvterm_id from cvterm c1, cv c2 where c1.name=c_name_synonym and c2.name=cv_cvname_synonym and c1.cv_id=c2.cv_id;

  RAISE NOTICE ''assigning names, prefix:%, suffix:%, type:%, current uniquename:%'',prefix,suffix,f_type,NEW.uniquename;

  IF (NEW.uniquename like prefix||'':temp%''||suffix) THEN

      SELECT INTO f_type c.name
         from feature f, cvterm c
         where f.type_id=c.cvterm_id and
               f.uniquename=NEW.uniquename and
               f.organism_id =NEW.organism_id;
      SELECT INTO p_id pub_id from pub where uniquename = p_miniref;
      SELECT INTO s_type_id cvterm_id from cvterm c1, cv c2 where c1.name=c_name_synonym and c2.name=cv_cvname_synonym and c1.cv_id=c2.cv_id;

      SELECT INTO f_uniquename next_uniquename();

      SELECT INTO f_row_g * from feature where uniquename=NEW.uniquename and organism_id=NEW.organism_id;

      IF f_type = f_type_gene THEN

          IF NEW.name like ''%temp%'' or NEW.name IS NULL THEN
               f_name = f_uniquename;
               UPDATE feature set uniquename=f_uniquename, name=f_uniquename where feature_id=f_row_g.feature_id;
          ELSE
               f_name = f_row_g.name;
               UPDATE feature set uniquename=f_uniquename where feature_id=f_row_g.feature_id;
          END IF;

      ELSIF (f_type=f_type_transcript or 
             f_type=f_type_ncRNA or 
             f_type=f_type_snoRNA or 
             f_type=f_type_snRNA or 
             f_type=f_type_tRNA or 
             f_type=f_type_rRNA or 
             f_type=f_type_pseudo or 
             f_type=f_type_miRNA or
             f_type=f_type_protein or
             f_type=f_type_exon) THEN

          IF NEW.name like ''%temp%'' or NEW.name IS NULL THEN
               f_name = null;
          ELSE
               f_name = f_row_g.name;
          END IF;
          UPDATE feature set uniquename=f_uniquename,name=f_name where feature_id=f_row_g.feature_id;

      ELSIF ( f_type=f_type_transposable_element or 
              f_type=f_type_promoter or 
              f_type=f_type_repeat_region or 
              f_type=f_type_remark )  THEN

          IF NEW.name like ''%temp%'' or NEW.name IS NULL THEN
               f_name := CAST(f_uniquename||''-''||f_type  AS TEXT);
               UPDATE feature set uniquename=f_uniquename, name=f_uniquename where feature_id=f_row_g.feature_id;
          ELSE
               f_name = f_row_g.name;
               UPDATE feature set uniquename=f_uniquename, name=f_name where feature_id=f_row_g.feature_id;
          END IF;

      END IF;

      RAISE NOTICE ''new uniquename of this feature is:%'', f_uniquename;

      --insert into synonym, feature_synonym
      SELECT INTO s_id synonym_id from synonym where name=f_uniquename and type_id=s_type_id;
      IF s_id IS NULL THEN
          INSERT INTO synonym(name, synonym_sgml, type_id) values(f_uniquename, f_uniquename, s_type_id);
          SELECT INTO s_id synonym_id from synonym where name=f_uniquename and type_id=s_type_id;
      END IF;
      SELECT INTO f_s_id feature_synonym_id from feature_synonym where feature_id=f_row_g.feature_id and synonym_id=s_id and pub_id=p_id;
      IF f_s_id IS NULL THEN
          INSERT INTO feature_synonym(feature_id, synonym_id, pub_id, is_current) values (f_row_g.feature_id, s_id, p_id, ''true'');
      END IF;
      RAISE NOTICE ''feature_id:%, synonym_id:% for uniquename'', f_row_g.feature_id, s_id;

      IF f_name IS NOT NULL THEN

          SELECT INTO s_id synonym_id from synonym where name=f_name and type_id=s_type_id;
          IF s_id IS NULL THEN
              INSERT INTO synonym(name, synonym_sgml, type_id) values(f_name, f_name, s_type_id);
              SELECT INTO s_id synonym_id from synonym where name=f_name and type_id=s_type_id;
          END IF;
          SELECT INTO f_s_id feature_synonym_id from feature_synonym where feature_id=f_row_g.feature_id and synonym_id=s_id and pub_id=p_id;
          IF f_s_id IS NULL THEN
              INSERT INTO feature_synonym(feature_id, synonym_id, pub_id, is_current) values (f_row_g.feature_id, s_id, p_id, ''true'');
          END IF;
          RAISE NOTICE ''feature_id:%, synonym_id:% for name'', f_row_g.feature_id, s_id;

      END IF;
  END IF;     --ends if uniquename like temp

  return NEW;    
END;
'LANGUAGE plpgsql;

GRANT ALL ON FUNCTION feature_assignname_fn_i() TO PUBLIC;

CREATE TRIGGER feature_assignname_tr_i AFTER INSERT ON feature for EACH ROW EXECUTE PROCEDURE feature_assignname_fn_i();

DROP TRIGGER feature_relationship_tr_d  ON feature_relationship;
CREATE OR REPLACE FUNCTION feature_relationship_fn_d() RETURNS TRIGGER AS '
DECLARE
  maxid         int;
  id            varchar(255);
  loginfo       varchar(255);
  len           int;
  f_row_g       feature%ROWTYPE;
  f_row_e       feature%ROWTYPE;
  f_row_t       feature%ROWTYPE;
  f_row_p       feature%ROWTYPE;
  f_type        cvterm.name%TYPE;
  f_type_temp   cvterm.name%TYPE;
  letter_e      varchar(100);
  letter_t      varchar(100);
  letter_p      varchar(100);
  f_uniquename_gene    feature.uniquename%TYPE;
  f_uniquename_transcript feature.uniquename%TYPE;
  f_uniquename_exon    feature.uniquename%TYPE;
  f_uniquename_protein feature.uniquename%TYPE;
  f_d_id               feature_dbxref.feature_dbxref_id%TYPE;
  d_id                 dbxref.dbxref_id%TYPE;
  s_type_id            synonym.type_id%TYPE;
  s_id                 synonym.synonym_id%TYPE;
  p_id                 pub.pub_id%TYPE;
  fr_row               feature_relationship%ROWTYPE;
  f_accession_temp     varchar(255);
  f_accession          varchar(255);
  f_type_gene          CONSTANT varchar :=''gene'';
  f_type_exon          CONSTANT varchar :=''exon'';
  f_type_transcript    CONSTANT varchar :=''mRNA'';
  f_type_snoRNA        CONSTANT varchar :=''snoRNA'';
  f_type_ncRNA         CONSTANT varchar :=''ncRNA'';
  f_type_snRNA         CONSTANT varchar :=''snRNA'';
  f_type_tRNA          CONSTANT varchar :=''tRNA'';
  f_type_rRNA          CONSTANT varchar :=''rRNA'';
  f_type_promoter      CONSTANT varchar :=''promoter'';
  f_type_repeat_region CONSTANT varchar :=''repeat_region'';
  f_type_miRNA         CONSTANT varchar :=''miRNA'';
  f_type_transposable_element CONSTANT varchar :=''transposable_element'';
  f_type_pseudo        CONSTANT varchar :=''pseudogene'';
  f_type_protein       CONSTANT varchar :=''protein'';
  f_type_allele        CONSTANT varchar :=''alleleof'';
  f_dbname_gadfly      CONSTANT varchar :=''Gadfly'';
  f_dbname_FB          CONSTANT varchar :=''FlyBase'';
  c_name_synonym       CONSTANT varchar:=''synonym'';
  cv_cvname_synonym    CONSTANT varchar:=''synonym type'';
  p_miniref            CONSTANT varchar:=''GadFly'';
BEGIN
 RAISE NOTICE ''enter fr_d, fr.object_id:%, fr.subject_id:%'', OLD.object_id, OLD.subject_id;
 SELECT INTO f_type name from cvterm  where cvterm_id=OLD.type_id;
 IF f_type=f_type_allele THEN
     RAISE NOTICE ''delete relationship beteen gene:% and allele:%'', OLD.object_id, OLD.subject_id; 
 ELSE
     SELECT INTO f_type c.name from feature f, cvterm c  where f.type_id=c.cvterm_id and f.feature_id=OLD.object_id;
     IF f_type=f_type_gene THEN 
         SELECT INTO f_type_temp c.name from feature f, cvterm c where f.feature_id=OLD.subject_id and f.type_id=c.cvterm_id;
         IF (f_type_temp=f_type_transcript or f_type_temp=f_type_ncRNA or f_type_temp=f_type_snoRNA  or f_type_temp=f_type_snRNA  or f_type_temp=f_type_tRNA  or f_type_temp=f_type_rRNA  or f_type_temp=f_type_miRNA  or f_type_temp=f_type_pseudo or f_type_temp=f_type_transposable_element or f_type_temp=f_type_promoter or f_type_temp=f_type_repeat_region ) THEN
             SELECT INTO fr_row * from feature_relationship where object_id<>OLD.object_id and subject_id=OLD.subject_id;
             IF fr_row.object_id IS NULL THEN
                 RAISE NOTICE ''delete this lonely transcript:%'', OLD.subject_id;
                 delete from feature where feature_id=OLD.subject_id;
             END IF;
         ELSE
             RAISE NOTICE ''wrong feature_relationship: gene->NO_transcript:object_id:%, subject_id:%'', OLD.object_id, OLD.subject_id;
         END IF;
     ELSIF (f_type=f_type_transcript or f_type=f_type_snoRNA or f_type=f_type_ncRNA or f_type=f_type_snRNA or f_type=f_type_tRNA or f_type=f_type_miRNA or f_type=f_type_rRNA or f_type=f_type_pseudo or f_type=f_type_transposable_element or f_type=f_type_promoter or f_type=f_type_repeat_region) THEN
         SELECT INTO f_type_temp c.name from feature f, cvterm c where f.feature_id=OLD.subject_id and f.type_id=c.cvterm_id;
         IF f_type_temp=f_type_protein or f_type_temp=f_type_exon THEN
             SELECT INTO fr_row * from feature_relationship where subject_id=OLD.subject_id and object_id<>OLD.object_id;  
             IF fr_row.object_id IS NULL     THEN     
                 RAISE NOTICE ''delete this lonely exon/protein:%'', OLD.subject_id;
                 delete from feature where feature_id=OLD.subject_id;          
             END IF;
         ELSE
             RAISE NOTICE ''wrong relationship: transcript->NO_protein/exon: objfeature:%, subjfeature:%'',OLD.object_id, OLD.subject_id;
         END IF;
     END IF;
 END IF;
 RAISE NOTICE ''leave fr_d ....'';
 RETURN OLD;
END;
'LANGUAGE plpgsql;

GRANT ALL ON FUNCTION feature_relationship_fn_d() TO PUBLIC;

CREATE TRIGGER feature_relationship_tr_d BEFORE DELETE ON feature_relationship  for EACH ROW EXECUTE PROCEDURE feature_relationship_fn_d();

DROP TABLE trigger_log;
CREATE TABLE trigger_log(
   value   varchar(255) not null,
   timeaccessioned   timestamp not null default current_timestamp,
   table_name   varchar(50),
   id      int 
);

GRANT ALL ON TABLE trigger_log TO PUBLIC;


DROP TRIGGER feature_relationship_propagatename_tr_i ON feature_relationship;

CREATE OR REPLACE FUNCTION feature_relationship_propagatename_fn_i() RETURNS TRIGGER AS '
DECLARE
  maxid        int;
  exon_id      int;
  id           varchar(255);
  maxid_fb     int;
  id_fb        varchar(255);
  loginfo      varchar(255);
  len          int;
  prefix       varchar;
  suffix       varchar;
  f_row_g      feature%ROWTYPE;
  f_row_e      feature%ROWTYPE;
  f_row_t      feature%ROWTYPE;
  f_row_p      feature%ROWTYPE;
  fl_row_e     featureloc%ROWTYPE;
  f_type       cvterm.name%TYPE;
  f_type_temp  cvterm.name%TYPE;
  letter_t     varchar(100);
  letter_p     varchar(100);
  f_dbxref_id          feature.dbxref_id%TYPE;
  fb_accession         dbxref.accession%TYPE;
  d_accession          dbxref.accession%TYPE;
  f_name_gene          feature.name%TYPE;
  f_name               feature.name%TYPE;
  f_d_id               feature_dbxref.feature_dbxref_id%TYPE;
  dx_id                dbxref.dbxref_id%TYPE;
  d_id                 db.db_id%TYPE;
  s_type_id            synonym.type_id%TYPE;
  s_id                 synonym.synonym_id%TYPE;
  p_id                 pub.pub_id%TYPE;
  p_type_id            cvterm.cvterm_id%TYPE;
  c_cv_id              cv.cv_id%TYPE;
  f_s_id               feature_synonym.feature_synonym_id%TYPE;
  fr_row               feature_relationship%ROWTYPE;
  f_accession_temp     varchar(255);
  f_accession          varchar(255);
  f_type_gene       CONSTANT varchar :=''gene'';
  f_type_exon       CONSTANT varchar :=''exon'';
  f_type_transcript CONSTANT varchar :=''mRNA'';
  f_type_snoRNA     CONSTANT varchar :=''snoRNA'';
  f_type_ncRNA      CONSTANT varchar :=''ncRNA'';
  f_type_snRNA      CONSTANT varchar :=''snRNA'';
  f_type_tRNA       CONSTANT varchar :=''tRNA'';
  f_type_promoter   CONSTANT varchar :=''promoter'';
  f_type_repeat_region CONSTANT varchar :=''repeat_region'';
  f_type_miRNA      CONSTANT varchar :=''miRNA'';
  f_type_transposable_element CONSTANT varchar :=''transposable_element'';
  f_type_rRNA       CONSTANT varchar :=''rRNA'';
  f_type_pseudo     CONSTANT varchar :=''pseudogene'';
  f_type_protein    CONSTANT varchar :=''protein'';
  f_type_allele     CONSTANT varchar :=''alleleof'';
  f_dbname_gadfly   CONSTANT varchar :=''DB:GR'';
  f_dbname_FB       CONSTANT varchar :=''null'';
  c_name_synonym    CONSTANT varchar:=''synonym'';
  cv_cvname_synonym CONSTANT varchar:=''null'';
  p_miniref         CONSTANT varchar:=''none'';
  p_cvterm_name     CONSTANT varchar:=''computer file'';
  p_cv_name         CONSTANT varchar:=''pub type'';
BEGIN
 SELECT INTO prefix cp.value FROM cvtermprop cp, cvterm, cv
                             WHERE cvterm.name = ''prefix'' and
                                   cp.cvterm_id = cvterm.cvterm_id and
                                   cvterm.cv_id = cv.cv_id and
                                   cv.name = ''apollo'';
 SELECT INTO suffix cp.value FROM cvtermprop cp, cvterm, cv
                             WHERE cvterm.name = ''suffix'' and
                                   cp.cvterm_id = cvterm.cvterm_id and
                                   cvterm.cv_id = cv.cv_id and
                                   cv.name = ''apollo'';

 SELECT INTO p_id pub_id from pub where uniquename = p_miniref;
 SELECT INTO s_type_id cvterm_id from cvterm c1, cv c2 where c1.name=c_name_synonym and c2.name=cv_cvname_synonym and c1.cv_id=c2.cv_id;

 RAISE NOTICE ''propagating names, prefix:%, suffix:%'',prefix,suffix;

 RAISE NOTICE ''enter fr_i, fr.object_id:%, fr.subject_id:%'', NEW.object_id, NEW.subject_id;
 SELECT INTO f_type c.name from feature f, cvterm c  where f.type_id=c.cvterm_id and f.feature_id=NEW.object_id;
 SELECT INTO f_name name from feature where feature_id = NEW.subject_id;


 -- OK, the thing having a child added is a gene
 IF (f_name IS NULL and f_type=f_type_gene) THEN
     SELECT INTO f_type_temp c.name from feature f, cvterm c where f.feature_id=NEW.subject_id and f.type_id=c.cvterm_id;
     IF (f_type_temp=f_type_transcript or 
         f_type_temp=f_type_snoRNA or 
         f_type_temp=f_type_ncRNA or 
         f_type_temp=f_type_snRNA or 
         f_type_temp=f_type_tRNA or 
         f_type_temp=f_type_rRNA or 
         f_type_temp=f_type_miRNA or 
         f_type_temp=f_type_pseudo or 
         f_type_temp=f_type_transposable_element or 
         f_type_temp=f_type_promoter or 
         f_type_temp=f_type_repeat_region) THEN

         --generate a new name based on the gene name
         SELECT INTO f_name_gene name from feature where feature_id=NEW.object_id;

         SELECT INTO maxid to_number(max(substring(name from (length(f_name_gene)+1+length(f_type)))), ''99999'') FROM feature where name like f_name_gene||''-''||f_type||''%'';
         IF maxid IS NULL THEN
             maxid = 1;
         ELSE
             maxid = maxid + 1;
         END IF;

         f_name:=CAST(f_name_gene||''-''||f_type_temp||maxid AS TEXT);

         RAISE NOTICE ''start to update feature, gene name:%, new feature name:%'', f_name_gene, f_name;
         UPDATE feature set name=f_name where feature_id=NEW.subject_id;

         SELECT INTO s_id synonym_id from synonym where name=f_name and type_id=s_type_id;
         IF s_id IS NULL THEN
             INSERT INTO synonym(name, synonym_sgml, type_id) values(f_name, f_name, s_type_id);
             SELECT INTO s_id synonym_id from synonym where name=f_name and type_id=s_type_id;
         END IF;
         RAISE NOTICE ''start to insert feature_synonym:synonym_id:%,feature_id:%, pub_id:%'', s_id, NEW.subject_id, p_id;
         SELECT INTO f_s_id feature_synonym_id from feature_synonym where feature_id=NEW.subject_id and synonym_id=s_id and pub_id=p_id;
         IF f_s_id IS NULL THEN
             INSERT INTO feature_synonym(feature_id, synonym_id, pub_id, is_current) values (NEW.subject_id, s_id, p_id, ''true'');
         END IF;
     END IF;

-- here the thing having a child added is a second level thing (eg, a transcript is getting an exon or protein)
 ELSIF (f_name IS NULL and
          (f_type=f_type_transcript or 
           f_type=f_type_ncRNA  or 
           f_type=f_type_snoRNA or 
           f_type=f_type_snRNA or 
           f_type=f_type_tRNA or 
           f_type=f_type_rRNA or 
           f_type=f_type_miRNA or 
           f_type=f_type_pseudo or 
           f_type=f_type_transposable_element or 
           f_type=f_type_promoter or 
           f_type=f_type_repeat_region) )  THEN
     SELECT INTO f_name_gene f.name from feature f, feature_relationship fr, cvterm c where f.feature_id=fr.object_id and fr.subject_id=NEW.object_id and f.type_id=c.cvterm_id and c.name=f_type_gene;
     SELECT INTO f_type_temp c.name from feature f, cvterm c where f.feature_id=NEW.subject_id and f.type_id=c.cvterm_id;

     --adding a protein to a transcript
     IF f_type_temp=f_type_protein THEN
         IF f_name_gene IS NOT NULL THEN
             SELECT INTO f_row_p * from feature where feature_id=NEW.subject_id;

             --create a new name for this protein (again repeating code in assign_names)
             SELECT INTO maxid to_number(max(substring(name from (length(f_name_gene)+1+8))), ''99999'') FROM feature where name like f_name_gene||''-protein%'';
             IF maxid IS NULL THEN
                 maxid = 1;
             ELSE
                 maxid = maxid + 1;
             END IF;

             f_name:=CAST(f_name_gene||''-protein''||maxid AS TEXT);

             RAISE NOTICE ''update name of protein:% to new name:%'',f_row_p.name, f_name;
             UPDATE feature set name=f_name where feature_id=NEW.subject_id;

             SELECT INTO s_id synonym_id from synonym where name=f_name and type_id=s_type_id;
             IF s_id IS NULL THEN
                 INSERT INTO synonym(name, synonym_sgml, type_id) values(f_name, f_name, s_type_id);
                 SELECT INTO s_id synonym_id from synonym where name=f_name and type_id=s_type_id;
             END IF;

             SELECT INTO f_s_id feature_synonym_id from feature_synonym where feature_id=f_row_p.feature_id and synonym_id=p_id;
             IF f_s_id is NULL THEN
                 INSERT INTO feature_synonym(feature_id, synonym_id, pub_id, is_current) values (f_row_p.feature_id, s_id, p_id, ''true'');
             END IF;
         ELSE
             RAISE NOTICE ''Couldnt find a gene to add this protein to (feature_id:%)'', NEW.subject_id ;
         END IF;

     --adding an exon to a transcript
     ELSIF f_type_temp=f_type_exon THEN
         IF f_name_gene IS NOT NULL THEN

             SELECT INTO f_row_e * from feature where feature_id=NEW.subject_id;
             SELECT INTO fl_row_e * from featureloc where feature_id = NEW.subject_id and rank=0;
             IF fl_row_e.fmin IS NULL OR fl_row_e.fmax IS NULL THEN
                 RAISE NOTICE ''cant create exon name for feature_id % since there is no featureloc entry'', NEW.subject_id;
                 RETURN NEW;
             ELSE
                 f_name:=CAST(f_name_gene||'':''||fl_row_e.fmin||''-''||fl_row_e.fmax  AS TEXT);
             END IF;
             RAISE NOTICE ''exon new name:%'', f_name;
             UPDATE feature set name=f_name where feature_id=NEW.subject_id;

             SELECT INTO s_id synonym_id from synonym where name=f_name and type_id=s_type_id;
             IF s_id IS NULL THEN
                 INSERT INTO synonym(name, synonym_sgml, type_id) values(f_name, f_name, s_type_id);
                 SELECT INTO s_id synonym_id from synonym where name=f_name and type_id=s_type_id;
             END IF;
             INSERT INTO feature_synonym(feature_id, synonym_id, pub_id, is_current) values (f_row_e.feature_id, s_id, p_id, ''true'');
         ELSE
             RAISE NOTICE ''Couldnt find a gene to add this exon to (feature_id:%)'',NEW.subject_id;
         END IF;
     END IF;
 ELSE
     RAISE NOTICE ''no link to gene for this transcript or wrong feature_relationship: transcript->protein/exon:object_id:%, subject_id:%'', NEW.object_id, NEW.subject_id;
 END IF;
 RAISE NOTICE ''leave fr_i ....'';
 RETURN NEW;
END;
'LANGUAGE plpgsql;

GRANT ALL ON FUNCTION feature_relationship_propagatename_fn_i() TO PUBLIC;

CREATE TRIGGER feature_relationship_propagatename_tr_i AFTER INSERT ON feature_relationship FOR EACH ROW EXECUTE PROCEDURE feature_relationship_propagatename_fn_i();


DROP TRIGGER feature_update_name_tr_u ON feature;

CREATE OR REPLACE FUNCTION feature_fn_u() RETURNS TRIGGER AS
'
DECLARE
  f_type	cvterm.name%TYPE;
  f_type_gene	CONSTANT varchar :=''gene'';
  f_row         feature%ROW;
  name_suffix   varchar;
BEGIN
  IF OLD.uniquename <> NEW.uniquename THEN
      RAISE NOTICE ''You may not change the uniquename of a feature'';
      RAISE NOTICE ''if you feel you must, contact your database admin'';
      RETURN OLD;
  END IF;
  IF OLD.name = NEW.name THEN
      --not updating name, so go ahead 
      RETURN NEW;
  END IF;

  SELECT INTO f_type cv.name FROM feature f, cvterm cv WHERE f.feature_id = OLD.feature_id and f.type_id = cv.cvterm_id; 

  IF f_type <> f_type_gene THEN
      --it's not a gene, so go ahead
      RETURN NEW;
  END IF;

  --OK, so it's a gene, and were changing the name...

  FOR f_row IN SELECT f.* FROM feature f, get_sub_feature_ids(OLD.feature_id) ch WHERE f.feature_id = ch.feature_id LOOP
      IF f_row.name LIKE OLD.name||''-%'' THEN
          SELECT INTO name_suffix  substring(name from OLD.name||''(-.+)'');
          UPDATE feature SET name = NEW.name||name_suffix WHERE feature_id = f_row.feature_id;
      END IF; 
  END LOOP;  
  
  RETURN NEW; 
END;
'LANGUAGE plpgsql;

CREATE TRIGGER feature_update_name_tr_u BEFORE INSERT ON feature FOR EACH ROW EXECUTE PROCEDURE feature_fn_u();
