-- these are nearly identical to the triggers that flybase uses, but will
-- serve as the foundation of general triggers for GMOD.  Things that need to
-- be done:
--
--* indentify the items that have to be dynamically (at make time) extrapolated.
--* allow a more flexible naming scheme
--* remove the portion creating a flybase dbxref.
--* probably 20 more things I haven't thought of yet.

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
END
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

DROP table trigger_log;
CREATE table trigger_log(
   value   varchar(255) not null,
   timeaccessioned   timestamp not null default current_timestamp,
   table_name   varchar(50),
   id      int 
);

GRANT ALL ON TABLE trigger_log TO PUBLIC;

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
  RAISE NOTICE ''assigning names, prefix:%, suffix:%, type:%'',prefix,suffix,f_type;

  RAISE NOTICE ''enter f_i: feature.uniquename:%, feature.type_id:%'', NEW.uniquename, NEW.type_id;
  IF (NEW.uniquename like prefix||'':temp%''||suffix) and  NEW.uniquename not like ''%-%''  THEN
      IF f_type=f_type_gene THEN
          RAISE NOTICE ''in f_i, feature type is:%'', f_type;
          SELECT INTO f_row_g * from feature where uniquename=NEW.uniquename and organism_id=NEW.organism_id;
          SELECT INTO f_uniquename next_uniquename();

          IF NEW.name like ''%temp%'' or NEW.name IS NULL THEN
               UPDATE feature set uniquename=f_uniquename, name=f_uniquename where feature_id=f_row_g.feature_id;
          ELSE
               UPDATE feature set uniquename=f_uniquename where feature_id=f_row_g.feature_id;
          END IF;
          RAISE NOTICE ''old uniquename of this feature is:%'', f_row_g.uniquename;
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
          RAISE NOTICE ''feature_id:%, synonym_id:%'', f_row_g.feature_id, s_id;
      END IF; --ends if gene
  END IF;     --ends if uniquename like temp

  --deal with non-gene entries
  IF (NEW.uniquename not like prefix||'':temp%''||suffix and 
      (NEW.uniquename like ''%-R%'' or NEW.uniquename like ''%-P%'' or NEW.uniquename like ''%:temp%'' ))  THEN
      IF (f_type=f_type_transcript or f_type=f_type_ncRNA or f_type=f_type_snoRNA or f_type=f_type_snRNA or f_type=f_type_tRNA or f_type=f_type_rRNA or f_type=f_type_pseudo or f_type=f_type_miRNA ) THEN
          SELECT INTO f_row_t * from feature where uniquename=NEW.uniquename and organism_id=NEW.organism_id;

          --assume the temp name is like gene_uniquename-RtempXXX
          --transcripts of various types are named after the genename like gene_name-typeXXX

          pos:=position(''-'' in NEW.uniquename)-1;
          f_uniquename:=substring(NEW.uniquename from 1 for pos);
          RAISE NOTICE ''gene uniquename for this transcript:% should be:%'', NEW.uniquename, f_uniquename;

          SELECT INTO max_id to_number(max(substring(uniquename from (pos+1+length(f_type)))), ''99999'') FROM feature where uniquename like f_uniquename||''-''||f_type||''%'';
          IF max_id IS NULL THEN
              max_id = 1;
          ELSE
              max_id = max_id + 1;
          END IF;

          f_uniquename_tr:=CAST(f_uniquename||''-''||f_type||max_id AS TEXT);

          RAISE NOTICE ''New uniquename for % feature is %'',f_type,f_uniquename_tr;

          IF NEW.name IS NULL OR NEW.name like ''%temp%'' THEN
              UPDATE feature SET uniquename=f_uniquename_tr, name=f_uniquename_tr WHERE feature_id=f_row_t.feature_id;
          ELSE
              UPDATE feature SET uniquename=f_uniquename_tr WHERE feature_id=f_row_t.feature_id;
          END IF;

          SELECT INTO s_id synonym_id from synonym where name=f_uniquename_tr and type_id=s_type_id;
          IF s_id IS NULL THEN
              INSERT INTO synonym(name, synonym_sgml, type_id) values(f_uniquename_tr, f_uniquename_tr, s_type_id);
              SELECT INTO s_id synonym_id from synonym where name=f_uniquename_tr and type_id=s_type_id;
          END IF;
          SELECT INTO f_s_id feature_synonym_id from feature_synonym where feature_id=f_row_t.feature_id and synonym_id=s_id and pub_id=p_id;
          IF f_s_id IS NULL THEN
              INSERT INTO feature_synonym(feature_id, synonym_id, pub_id, is_current) values (f_row_t.feature_id, s_id, p_id, ''true'');
          END IF;
      END IF;  --ends if type = other three level type
      IF f_type=f_type_protein THEN
          SELECT INTO f_row_p * from feature where uniquename=NEW.uniquename and organism_id=NEW.organism_id;
          RAISE NOTICE ''old uniquename of this feature is:%'', f_row_p.uniquename; 

          --assume protein temp uname is like real_genename-P

          --get genename
          pos:=position(''-'' in NEW.uniquename)-1;
          f_uniquename:=substring(NEW.uniquename from 1 for pos);
          RAISE NOTICE ''gene uniquename for this protein:% should be:%'', NEW.uniquename, f_uniquename;
          
          --get max protein that belongs to this gene
          SELECT INTO max_id to_number(max(substring(uniquename from (pos+1+8))), ''99999'') FROM feature where uniquename like f_uniquename||''-protein%'';
          IF max_id IS NULL THEN
              max_id = 1;
          ELSE
              max_id = max_id + 1;
          END IF;
         
          f_uniquename_protein:=CAST(f_uniquename||''-protein''||max_id AS TEXT);
          RAISE NOTICE ''new protein uniquename is %'',f_uniquename_protein;
          IF NEW.name IS NULL OR NEW.name like ''%temp%'' THEN
              UPDATE feature SET uniquename=f_uniquename_protein, name=f_uniquename_protein WHERE feature_id=f_row_p.feature_id;
          ELSE
              UPDATE feature SET uniquename=f_uniquename_protein WHERE feature_id=f_row_p.feature_id;
          END IF; 

          SELECT INTO s_id synonym_id from synonym where name=f_uniquename_protein and type_id=s_type_id;
          IF s_id IS NULL THEN
              INSERT INTO synonym(name, synonym_sgml, type_id) values(f_uniquename_protein, f_uniquename_protein, s_type_id);
              SELECT INTO s_id synonym_id from synonym where name=f_uniquename_protein and type_id=s_type_id;
          END IF;
          SELECT INTO f_s_id feature_synonym_id from feature_synonym where feature_id=f_row_p.feature_id and synonym_id=s_id and pub_id=p_id;
          IF f_s_id IS NULL THEN
              INSERT INTO feature_synonym(feature_id, synonym_id, pub_id, is_current) values (f_row_p.feature_id, s_id, p_id, ''true'');
          END IF;
      END IF; --ends if type = protein
      IF f_type=f_type_exon THEN
          SELECT INTO f_row_e * from feature where uniquename=NEW.uniquename and organism_id=NEW.organism_id;
          IF f_row_e.uniquename like ''%temp%'' THEN
              RAISE NOTICE ''This exons uniquename is %, but a new uniquename cannot be assigned,'',f_row_e.uniquename;
              RAISE NOTICE ''since the uniquename should contain featureloc fmin and fmax, but they dont exist yet'';
              RETURN OLD;
          ELSE
              IF NEW.name like ''%temp%'' THEN
                  UPDATE feature set name=f_row_e.uniquename where feature_id=f_row_e.feature_id;
              END IF;
              SELECT INTO s_id synonym_id from synonym where name=f_row_euniquename and type_id=s_type_id;
              IF s_id IS NULL THEN
                  INSERT INTO synonym(name, synonym_sgml, type_id) values(f_row_e.uniquename, f_row_e.uniquename, s_type_id);
                  SELECT INTO s_id synonym_id from synonym where name=f_row_e.uniquename and type_id=s_type_id;
              END IF;
              SELECT INTO f_s_id feature_synonym_id from feature_synonym where feature_id=f_row_e.feature_id and synonym_id=s_id and pub_id=p_id;
              IF f_s_id IS NULL THEN
                  INSERT INTO feature_synonym(feature_id, synonym_id, pub_id, is_current) values (f_row_e.feature_id, s_id, p_id, ''true'');
              END IF;
          END IF;
      END IF; --ends if type=exon
  END IF;     --ends if misc cases

  IF ( f_type=f_type_transposable_element or f_type=f_type_promoter or f_type=f_type_repeat_region or f_type=f_type_remark )  THEN
      SELECT INTO f_uniquename next_uniquename();
      IF NEW.name IS NULL THEN
          f_name  :=CAST(f_type||'':''||id as TEXT);
      ELSE
          f_name  :=NEW.name;
      END IF;
      RAISE NOTICE ''new unquename:%, old uniquename is:%, new name is:%'', f_uniquename, NEW.uniquename, f_name;
      UPDATE feature set uniquename=f_uniquename, name=f_name where feature_id=NEW.feature_id;

      SELECT INTO s_id synonym_id from synonym where name=f_uniquename and type_id=s_type_id;
      IF s_id IS NULL THEN
          INSERT INTO synonym (name, synonym_sgml, type_id) values (f_uniquename, f_uniquename, s_type_id);
          SELECT INTO s_id synonym_id from synonym where name=f_uniquename and type_id=s_type_id;
      END IF;
      SELECT INTO f_s_id feature_synonym_id from feature_synonym where feature_id=f_row_e.feature_id and synonym_id=s_id and pub_id=p_id;
      IF f_s_id IS NULL THEN
          INSERT INTO feature_synonym(feature_id, synonym_id, pub_id, is_current) values (f_row_e.feature_id, s_id, p_id, ''true'');
      END IF;
  END IF; --end dealing with one level types
  RAISE NOTICE ''leave f_i .......'';
  return NEW;    
END;
'LANGUAGE plpgsql;

GRANT ALL ON FUNCTION feature_assignname_fn_i() TO PUBLIC;

CREATE TRIGGER feature_assignname_tr_i AFTER INSERT ON feature for EACH ROW EXECUTE PROCEDURE feature_assignname_fn_i();

DROP TABLE trigger_log;
CREATE table trigger_log(
   value   varchar(255) not null,
   timeaccessioned   timestamp not null default current_timestamp,
   table_name   varchar(50),
   id      int 
);

GRANT ALL ON TABLE trigger_log TO PUBLIC;

DROP TRIGGER feature_relationship_tr_d  ON feature_relationship;
CREATE OR REPLACE FUNCTION feature_relationship_fn_d() RETURNS TRIGGER AS '
DECLARE
  maxid int;
  exon_id int;
  id    varchar(255);
  maxid_fb int;
  id_fb    varchar(255);
  loginfo      varchar(255);
  len   int;
  f_row_g feature%ROWTYPE;
  f_row_e feature%ROWTYPE;
  f_row_t feature%ROWTYPE;
  f_row_p feature%ROWTYPE;
  f_type  cvterm.name%TYPE;
  f_type_temp  cvterm.name%TYPE;
  letter_e varchar(100);
  letter_t varchar(100);
  letter_p varchar(100);
  f_dbxref_id feature.dbxref_id%TYPE;
  fb_accession dbxref.accession%TYPE;
  d_accession dbxref.accession%TYPE;
  f_uniquename_gene feature.uniquename%TYPE;
  f_uniquename_transcript feature.uniquename%TYPE;
  f_uniquename_exon feature.uniquename%TYPE;
  f_uniquename_protein feature.uniquename%TYPE;
  f_d_id               feature_dbxref.feature_dbxref_id%TYPE;
  d_id                 dbxref.dbxref_id%TYPE;
  s_type_id            synonym.type_id%TYPE;
  s_id                 synonym.synonym_id%TYPE;
  p_id                 pub.pub_id%TYPE;
  fr_row feature_relationship%ROWTYPE;
  f_accession_temp varchar(255);
  f_accession varchar(255);
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
 f_dbname_gadfly CONSTANT varchar :=''Gadfly'';
 f_dbname_FB CONSTANT varchar :=''FlyBase'';
  c_name_synonym CONSTANT varchar:=''synonym'';
  cv_cvname_synonym CONSTANT varchar:=''synonym type'';
  p_miniref         CONSTANT varchar:=''GadFly'';
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
             if fr_row.object_id IS NULL THEN
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

DROP TRIGGER feature_relationship_propagatename_tr_i ON feature_relationship;

CREATE OR REPLACE FUNCTION feature_relationship_propagatename_fn_i() RETURNS TRIGGER AS '
DECLARE
  maxid    int;
  exon_id  int;
  id       varchar(255);
  maxid_fb int;
  id_fb    varchar(255);
  loginfo  varchar(255);
  len      int;
  prefix   constants.value%TYPE;
  suffix   constants.value%TYPE;
  f_row_g  feature%ROWTYPE;
  f_row_e  feature%ROWTYPE;
  f_row_t  feature%ROWTYPE;
  f_row_p  feature%ROWTYPE;
  f_type   cvterm.name%TYPE;
  f_type_temp  cvterm.name%TYPE;
  letter_e varchar(100);
  letter_t varchar(100);
  letter_p varchar(100);
  f_dbxref_id          feature.dbxref_id%TYPE;
  fb_accession         dbxref.accession%TYPE;
  d_accession          dbxref.accession%TYPE;
  f_uniquename_gene    feature.uniquename%TYPE;
  f_uniquename_transcript feature.uniquename%TYPE;
  f_uniquename_exon feature.uniquename%TYPE;
  f_uniquename_protein feature.uniquename%TYPE;
  f_d_id               feature_dbxref.feature_dbxref_id%TYPE;
  dx_id                dbxref.dbxref_id%TYPE;
  d_id                 db.db_id%TYPE;
  s_type_id            synonym.type_id%TYPE;
  s_id                 synonym.synonym_id%TYPE;
  p_id                 pub.pub_id%TYPE;
  p_type_id            cvterm.cvterm_id%TYPE;
  c_cv_id              cv.cv_id%TYPE;
  f_s_id               feature_synonym.feature_synonym_id%TYPE;
  fr_row              feature_relationship%ROWTYPE;
  f_accession_temp varchar(255);
  f_accession varchar(255);
  f_type_gene CONSTANT varchar :=''gene'';
  f_type_exon CONSTANT varchar :=''exon'';
  f_type_transcript CONSTANT varchar :=''mRNA'';
  f_type_snoRNA CONSTANT varchar :=''snoRNA'';
  f_type_ncRNA CONSTANT varchar :=''ncRNA'';
  f_type_snRNA CONSTANT varchar :=''snRNA'';
  f_type_tRNA CONSTANT varchar :=''tRNA'';
  f_type_promoter CONSTANT varchar :=''promoter'';
  f_type_repeat_region CONSTANT varchar :=''repeat_region'';
  f_type_miRNA CONSTANT varchar :=''miRNA'';
  f_type_transposable_element CONSTANT varchar :=''transposable_element'';
  f_type_rRNA CONSTANT varchar :=''rRNA'';
  f_type_pseudo CONSTANT varchar :=''pseudogene'';
  f_type_protein CONSTANT varchar :=''protein'';
  f_type_allele CONSTANT varchar :=''alleleof'';
  f_dbname_gadfly CONSTANT varchar :=''DB:GR'';
  f_dbname_FB CONSTANT varchar :=''null'';
  c_name_synonym CONSTANT varchar:=''synonym'';
  cv_cvname_synonym CONSTANT varchar:=''null'';
  p_miniref         CONSTANT varchar:=''none'';
  p_cvterm_name     CONSTANT varchar:=''computer file'';
  p_cv_name         CONSTANT varchar:=''pub type'';
BEGIN
 SELECT INTO prefix c.value FROM constants c, cvterm, cv  
                            WHERE c.name = ''prefix'' and
                                  c.application_id = cvterm.cvterm_id and
                                  cvterm.name = ''apollo'' and 
                                  cvterm.cv_id = cv.cv_id and
                                  cv.name = ''applications'';
 SELECT INTO suffix c.value FROM constants c, cvterm, cv
                            WHERE c.name = ''suffix'' and
                                  c.application_id = cvterm.cvterm_id and
                                  cvterm.name = ''apollo'' and
                                  cvterm.cv_id = cv.cv_id and
                                  cv.name = ''applications'';
 SELECT INTO p_id pub_id from pub p, cvterm c where uniquename=p_miniref and c.name=p_cvterm_name and c.cvterm_id=p.type_id;
 SELECT INTO s_type_id cvterm_id from cvterm c1, cv c2 where c1.name=c_name_synonym and c2.name=cv_cvname_synonym and c1.cv_id=c2.cv_id;

 RAISE NOTICE ''propagating names, prefix:%, suffix:%'',prefix,suffix;
 

 RAISE NOTICE ''enter fr_i, fr.object_id:%, fr.subject_id:%'', NEW.object_id, NEW.subject_id;
 SELECT INTO f_type c.name from feature f, cvterm c  where f.type_id=c.cvterm_id and f.feature_id=NEW.object_id;
 IF f_type=f_type_gene THEN 
     SELECT INTO f_type_temp c.name from feature f, cvterm c where f.feature_id=NEW.subject_id and f.type_id=c.cvterm_id;
     IF (f_type_temp=f_type_transcript or f_type_temp=f_type_snoRNA or f_type_temp=f_type_ncRNA or f_type_temp=f_type_snRNA or f_type_temp=f_type_tRNA or f_type_temp=f_type_rRNA or f_type_temp=f_type_miRNA or f_type_temp=f_type_pseudo or f_type_temp=f_type_transposable_element or f_type_temp=f_type_promoter or f_type_temp=f_type_repeat_region) THEN
         SELECT INTO f_row_t * from feature where feature_id=NEW.subject_id;
         RAISE NOTICE ''start to update feature, old:%, new:%'', f_row_t.uniquename, f_uniquename_transcript;
         IF f_row_t.name like ''%temp%'' THEN
             RAISE NOTICE ''also update feature.name'';
             UPDATE feature set name=f_uniquename_transcript, uniquename=f_uniquename_transcript where feature_id=NEW.subject_id;
         ELSE                
             UPDATE feature set  uniquename=f_uniquename_transcript where feature_id=NEW.subject_id;
         END IF;   
         RAISE NOTICE ''assign new number for transcript:%'', NEW.subject_id;
         RAISE NOTICE ''s_type_id:%'', s_type_id;
         SELECT INTO s_id synonym_id from synonym where name=f_uniquename_transcript and type_id=s_type_id;
         IF s_id IS NULL THEN 
             INSERT INTO synonym(name, synonym_sgml, type_id) values(f_uniquename_transcript, f_uniquename_transcript, s_type_id);
             SELECT INTO s_id synonym_id from synonym where name=f_uniquename_transcript and type_id=s_type_id;
         END IF;
         IF p_id IS NULL THEN
             SELECT INTO p_type_id cvterm_id from cvterm where name=p_cvterm_name;
             IF p_type_id IS NULL THEN
                 SELECT INTO c_cv_id cv_id from cv where name=p_cv_name;
                 IF c_cv_id IS NULL THEN
                     INSERT INTO cv(name) values(p_cv_name);
                     SELECT INTO c_cv_id cv_id from cv where name=p_cv_name;
                 END IF;
                 INSERT INTO cvterm(name, cv_id) values(p_cvterm_name, c_cv_id);
                 SELECT INTO c_cv_id cv_id from cv where name=p_cv_name;
             END IF;
             INSERT INTO pub(uniquename, miniref, type_id) values(p_miniref, p_miniref, p_type_id);
             SELECT INTO p_id pub_id from pub p, cvterm c where uniquename=p_miniref and c.name=p_cvterm_name and c.cvterm_id=p.type_id;
         END IF;
         RAISE NOTICE ''start to insert feature_synonym:synonym_id:%,feature_id:%, pub_id:%'', s_id, f_row_t.feature_id, p_id;
         SELECT INTO f_s_id feature_synonym_id from feature_synonym where feature_id=f_row_t.feature_id and synonym_id=s_id and pub_id=p_id;
         IF f_s_id IS NULL THEN 
             INSERT INTO feature_synonym(feature_id, synonym_id, pub_id, is_current) values (f_row_t.feature_id, s_id, p_id, ''true'');           
         END IF;     
     END IF;

 ELSIF (f_type=f_type_transcript or f_type=f_type_ncRNA  or f_type=f_type_snoRNA or f_type=f_type_snRNA or f_type=f_type_tRNA or f_type=f_type_rRNA or f_type=f_type_miRNA or f_type=f_type_pseudo or f_type=f_type_transposable_element or f_type=f_type_promoter or f_type=f_type_repeat_region)   THEN
     SELECT INTO f_uniquename_gene f.uniquename from feature f, feature_relationship fr, cvterm c where f.feature_id=fr.object_id and fr.subject_id=NEW.object_id and f.type_id=c.cvterm_id and c.name=f_type_gene;
     SELECT INTO f_type_temp c.name from feature f, cvterm c where f.feature_id=NEW.subject_id and f.type_id=c.cvterm_id;
     IF f_type_temp=f_type_protein and f_uniquename_gene IS NOT NULL THEN
         SELECT INTO f_row_p * from feature where feature_id=NEW.subject_id;  
         RAISE NOTICE ''update uniquename of protein:% to new uniquename:%'',f_row_p.uniquename, f_uniquename_protein;
         SELECT INTO d_id db_id from db where name=f_dbname_gadfly;
         SELECT INTO dx_id dbxref_id from dbxref dx, db d  where dx.db_id=d.db_id and d.name=f_dbname_gadfly and accession=f_uniquename_protein;
         IF  dx_id IS NULL THEN
             INSERT into dbxref (db_id, accession) values(d_id, f_uniquename_protein);
             SELECT INTO dx_id dbxref_id from dbxref dx, db d  where dx.db_id=d.db_id and d.name=f_dbname_gadfly and accession=f_uniquename_protein;
         END IF;
         SELECT INTO f_d_id feature_dbxref_id from feature_dbxref where feature_id=NEW.subject_id and dbxref_id=dx_id;
         IF f_d_id IS NULL THEN 
             INSERT INTO feature_dbxref(feature_id, dbxref_id, is_current) values(NEW.subject_id, dx_id, ''false'');
         END IF;
         IF f_row_p.name like ''%temp%'' THEN
             UPDATE feature set name=f_uniquename_protein, uniquename=f_uniquename_protein, dbxref_id=dx_id where feature_id=NEW.subject_id;
         ELSE
             UPDATE feature set  uniquename=f_uniquename_protein, dbxref_id=dx_id where feature_id=NEW.subject_id;
         END IF;   
         RAISE NOTICE ''assign new number:% for protein:%'', f_uniquename_protein,  NEW.subject_id;
         SELECT INTO s_type_id cvterm_id from cvterm c1, cv c2 where c1.name=c_name_synonym and c2.name=cv_cvname_synonym and c1.cv_id=c2.cv_id;
         SELECT INTO s_id synonym_id from synonym where name=f_uniquename_protein and type_id=s_type_id;
         IF s_id IS NULL THEN
             INSERT INTO synonym(name, synonym_sgml, type_id) values(f_uniquename_protein, f_uniquename_protein, s_type_id);
             SELECT INTO s_id synonym_id from synonym where name=f_uniquename_protein and type_id=s_type_id;
         END IF;

         SELECT INTO p_id pub_id from pub p, cvterm c where uniquename=p_miniref and c.name=p_cvterm_name and c.cvterm_id=p.type_id;
         IF p_id IS NULL THEN
             SELECT INTO p_type_id cvterm_id from cvterm where name=p_cvterm_name;
             IF p_type_id IS NULL THEN
                 SELECT INTO c_cv_id cv_id from cv where name=p_cv_name;
                 IF c_cv_id IS NULL THEN
                     INSERT INTO cv(name) values(p_cv_name);
                     SELECT INTO c_cv_id cv_id from cv where name=p_cv_name;
                 END IF;
                 INSERT INTO cvterm(name, cv_id) values(p_cvterm_name, c_cv_id);
                 SELECT INTO c_cv_id cv_id from cv where name=p_cv_name;
             END IF;
             INSERT INTO pub(uniquename, miniref, type_id) values(p_miniref, p_miniref, p_type_id);
             SELECT INTO p_id pub_id from pub p, cvterm c where uniquename=p_miniref and c.name=p_cvterm_name and c.cvterm_id=p.type_id;
         END IF;
         SELECT INTo f_s_id feature_synonym_id from feature_synonym where feature_id=f_row_p.feature_id and synonym_id=p_id;
         INSERT INTO feature_synonym(feature_id, synonym_id, pub_id, is_current) values (f_row_p.feature_id, s_id, p_id, ''true'');
                
     ELSIF (f_row_p.uniquename like prefix||''%''||suffix||''-P_'') and  f_row_p.uniquename not like ''%:%'' THEN
         RAISE NOTICE ''add protein to exist transcript'';
     ELSE
         RAISE NOTICE ''warning:unexpected format of protein uniquename:%'', f_row_p.uniquename;
     END IF;
 ELSIF f_type_temp=f_type_exon and f_uniquename_gene IS NOT NULL THEN
     SELECT INTO f_row_e * from feature where feature_id=NEW.subject_id;
     IF f_row_e.uniquename like prefix||'':temp%''||suffix   THEN            
         f_accession_temp:=f_row_e.uniquename;
         IF f_accession_temp like prefix||'':temp_:%''||suffix  THEN
              len:=length(f_accession_temp);
              letter_e:=substring(f_accession_temp from ''\:([^:]+)$'');             
              f_uniquename_exon:=CAST(f_uniquename_gene||'':''||letter_e  AS TEXT);
         ELSIF f_accession_temp like prefix||'':temp__:%''||suffix THEN
              len:=length(f_accession_temp);
              letter_e:=substring(f_accession_temp from 11);             
              f_uniquename_exon:=CAST(f_uniquename_gene||'':''||letter_e  AS TEXT);
         ELSE 
              f_uniquename_exon:=f_accession_temp;
         END IF;
         RAISE NOTICE ''letter_e:%, uniquename:%'', letter_e, f_uniquename_exon;
         IF f_row_e.uniquename like ''%temp%'' THEN
             UPDATE feature set name=f_uniquename_exon, uniquename=f_uniquename_exon where feature_id=NEW.subject_id;
         ELSE
             UPDATE feature set  uniquename=f_uniquename_exon where feature_id=NEW.subject_id;
         END IF;   
         SELECT INTO s_type_id cvterm_id from cvterm c1, cv c2 where c1.name=c_name_synonym and c2.name=cv_cvname_synonym and c1.cv_id=c2.cv_id;
         SELECT INTO s_id synonym_id from synonym where name=f_uniquename_exon and type_id=s_type_id; 
         IF s_id IS NULL THEN
             INSERT INTO synonym(name, synonym_sgml, type_id) values(f_uniquename_exon, f_uniquename_exon, s_type_id);
             SELECT INTO s_id synonym_id from synonym where name=f_uniquename_exon and type_id=s_type_id;
         END IF;
         SELECT INTO p_id pub_id from pub p, cvterm c where uniquename=p_miniref and c.name=p_cvterm_name and c.cvterm_id=p.type_id;
         IF p_id IS NULL THEN
             SELECT INTO p_type_id cvterm_id from cvterm where name=p_cvterm_name;
             IF p_type_id IS NULL THEN
                 SELECT INTO c_cv_id cv_id from cv where name=p_cv_name;
                 IF c_cv_id IS NULL THEN
                     INSERT INTO cv(name) values(p_cv_name);
                     SELECT INTO c_cv_id cv_id from cv where name=p_cv_name;
                 END IF;
                 INSERT INTO cvterm(name, cv_id) values(p_cvterm_name, c_cv_id);
                 SELECT INTO c_cv_id cv_id from cv where name=p_cv_name;
             END IF;
             INSERT INTO pub(uniquename, miniref, type_id) values(p_miniref, p_miniref, p_type_id);
             SELECT INTO p_id pub_id from pub p, cvterm c where uniquename=p_miniref and c.name=p_cvterm_name and c.cvterm_id=p.type_id;
         END IF;
         INSERT INTO feature_synonym(feature_id, synonym_id, pub_id, is_current) values (f_row_e.feature_id, s_id, p_id, ''true'');                
     ELSIF f_row_e.uniquename like prefix||''%:%''||suffix THEN 
         RAISE NOTICE ''add exon to exist transcript'';  
     ELSE
         RAISE NOTICE ''unexpected format of exon uniquename:%'', f_row_e.uniquename;            
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

-- this is the place to check FBtr/FBpp, not in tr_f_i, before 
DROP TRIGGER feature_propagatename_tr_u  ON feature ;
CREATE OR REPLACE FUNCTION feature_propagatename_fn_u() RETURNS TRIGGER AS '
DECLARE
maxid int;
id    varchar(255);
maxid_fb int;
len     int;
pos     int;
no      int;
id_fb    varchar(255);
message   varchar(255);
exon_id int;
f_row   feature%ROWTYPE;
f_row_g feature%ROWTYPE;
f_row_e feature%ROWTYPE;
f_row_t feature%ROWTYPE;
f_row_p feature%ROWTYPE;
fr_row  feature_relationship%ROWTYPE;
f_type  cvterm.name%TYPE;
f_type_temp  cvterm.name%TYPE;
letter_t varchar;
letter_p varchar;
letter_e varchar;
uniquename_exon_like varchar;
f_dbxref_id feature.dbxref_id%TYPE;
fb_accession dbxref.accession%TYPE;
d_accession dbxref.accession%TYPE;
f_uniquename_temp feature.uniquename%TYPE;
f_uniquename feature.uniquename%TYPE;
f_uniquename_tr feature.uniquename%TYPE;
f_uniquename_exon feature.uniquename%TYPE;
f_uniquename_protein feature.uniquename%TYPE;
f_feature_id_exon feature.feature_id%TYPE;
f_feature_id_protein feature.feature_id%TYPE;
d_id                 db.db_id%TYPE;
dx_id                dbxref.dbxref_id%TYPE;
dx_id_temp           dbxref.dbxref_id%TYPE;
d_id_temp            dbxref.dbxref_id%TYPE; 
s_type_id            synonym.type_id%TYPE;
s_id                 synonym.synonym_id%TYPE;
p_id                 pub.pub_id%TYPE;
  p_type_id            cvterm.cvterm_id%TYPE;
  c_cv_id              cv.cv_id%TYPE;
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
  f_type_allele CONSTANT varchar :=''allele'';
  f_dbname_gadfly CONSTANT varchar :=''DB:GR'';
  f_dbname_FB CONSTANT varchar :=''null'';
  o_genus  CONSTANT varchar :=''Oryza'';
  o_species  CONSTANT varchar:=''sativa'';
  c_name_synonym CONSTANT varchar:=''synonym'';
  cv_cvname_synonym CONSTANT varchar:=''null'';
  p_miniref         CONSTANT varchar:=''none'';
  p_cvterm_name     CONSTANT varchar:=''computer file'';
  p_cv_name         CONSTANT varchar:=''pub type'';
BEGIN
  IF NEW.uniquename <>OLD.uniquename and (NEW.uniquename like ''CG%'' or NEW.uniquename like ''CR%'') THEN
      SELECT INTO f_type c.name from feature f, cvterm c, organism o where f.type_id=c.cvterm_id and f.uniquename=NEW.uniquename and f.organism_id =NEW.organism_id;
      IF f_type is NOT NULL THEN
        RAISE NOTICE ''in f_u, type of this feature is:%'', f_type;
      END IF;
      IF f_type=f_type_gene THEN
        RAISE NOTICE ''in f_u, synchronize the transcript uniquename with genes'';
        FOR fr_row IN SELECT * from feature_relationship where object_id=OLD.feature_id LOOP
           SELECT INTO f_type c.name from feature f, cvterm c where f.type_id=c.cvterm_id and f.feature_id=fr_row.subject_id;
           IF (f_type =f_type_transcript or f_type =f_type_ncRNA or f_type =f_type_snoRNA or f_type =f_type_snRNA or f_type =f_type_tRNA  or f_type =f_type_rRNA or f_type =f_type_pseudo or f_type =f_type_miRNA or f_type=f_type_transposable_element or f_type=f_type_promoter or f_type=f_type_repeat_region) THEN
              SELECT INTO f_uniquename_temp uniquename from feature where feature_id=fr_row.subject_id; 
              len:=length (f_uniquename_temp);                        
              letter_t:=substring(f_uniquename_temp from len );             
              f_uniquename_tr:=CAST(NEW.uniquename||''-R''||letter_t  AS TEXT);
              RAISE NOTICE ''f_uniquename_tr:%'', f_uniquename_tr;
              UPDATE feature set uniquename=f_uniquename_tr where feature_id=fr_row.subject_id;
           ELSE
              RAISE NOTICE ''wrong relationship:gene->no_RNA: obj:%, subj:%'', fr_row.object_id, fr_row.subject_id;
              message:=CAST(''wrong relationship:gene->no_RNA''||''object:''||fr_row.object_id||''subject:''||fr_row.subject_id AS TEXT);
              insert into trigger_log(value, table_name, id) values(message, ''feature_relationship'', fr_row.feature_relationship_id);
           END IF;
        END LOOP;
      ELSIF (f_type =f_type_transcript or f_type =f_type_ncRNA or f_type =f_type_snoRNA or f_type =f_type_snRNA or f_type =f_type_tRNA or f_type =f_type_rRNA  or f_type =f_type_pseudo or f_type =f_type_miRNA or f_type=f_type_transposable_element or f_type=f_type_promoter or f_type=f_type_repeat_region) THEN
        select INTO f_uniquename f.uniquename from feature f, feature_relationship fr where f.feature_id=fr.object_id and fr.subject_id=OLD.feature_id;
        IF f_uniquename IS NOT NULL THEN
          FOR fr_row IN SELECT * from feature_relationship where object_id=OLD.feature_id LOOP
             select INTO f_type_temp c.name from cvterm c, feature f where c.cvterm_id=f.type_id and f.feature_id=fr_row.subject_id;
             IF f_type_temp =f_type_protein THEN
                SELECT INTO f_row * from feature where feature_id=fr_row.subject_id;
                RAISE NOTICE ''f_row.uniquename:%'', f_row.uniquename;
                IF f_row.uniquename like ''CG:temp%'' or f_row.uniquename like ''CR:temp%'' THEN
                   len:=length(f_row.uniquename);
                   RAISE NOTICE ''len:% for uniquename:%'', len, f_row.uniquename;
                   letter_p:=substring(f_row.uniquename from len for 1); 

                   f_uniquename_protein:=CAST(f_uniquename||''-P''||letter_p  AS TEXT);
                   RAISE NOTICE ''letter_p:%, uniquename:%'', letter_p, f_uniquename_protein;
                   SELECT INTO d_id db_id from db where name=f_dbname_gadfly;                   
                   SELECT INTO dx_id dbxref_id from dbxref where db_id=d_id and accession=f_uniquename_protein;
                   IF dx_id IS NULL THEN                    
                      INSERT INTO dbxref(db_id, accession) values(d_id, f_uniquename_protein);
                      SELECT INTO dx_id dbxref_id from dbxref where db_id=d_id and accession=f_uniquename_protein;
                   END IF;
                   SELECT INTO d_id_temp dbxref_id from feature_dbxref where feature_id=fr_row.subject_id and dbxref_id=dx_id;
                   IF d_id_temp IS NULL THEN 
                      INSERT INTO feature_dbxref (feature_id, dbxref_id, is_current)  values(fr_row.subject_id, dx_id, ''false'');
                   END IF;
                   SELECT INTO maxid_fb max(to_number(substring(accession from 5 for 11),''9999999'')) from dbxref dx, db d where dx.db_id=d.db_id and d.name = f_dbname_FB and accession like ''FBpp%'';  
                   IF maxid_fb IS NULL OR maxid_fb< 70000  THEN
                      maxid_fb:=70000;
                   ELSE 
                    maxid_fb:=maxid_fb+1;
                   END IF;
                   id_fb:=lpad(maxid_fb, 7, ''0000000'');
                   fb_accession:=CAST(''FBpp''||id_fb AS TEXT);
                   RAISE NOTICE ''fb_accession is:%'', fb_accession;
                   SELECT INTO d_id db_id from db where name=f_dbname_FB;
                   INSERT INTO dbxref(db_id, accession) values(d_id, fb_accession);
                   SELECT INTO dx_id dbxref_id from dbxref dx , db d where dx.db_id=d.db_id and d.name=f_dbname_FB and accession=fb_accession;
                   INSERT INTO feature_dbxref(feature_id, dbxref_id) values(fr_row.subject_id, dx_id);
                   RAISE NOTICE ''insert FBpp:% into feature_dbxref, and set is_current as true'', fb_accession;
                   SELECT INTO s_type_id cvterm_id from cvterm c1, cv c2 where c1.name=c_name_synonym and c2.name=cv_cvname_synonym and c1.cv_id=c2.cv_id;
                   RAISE NOTICE ''s_type_id:%'', s_type_id;
                   SELECT INTO s_id synonym_id from synonym where name=f_uniquename_protein and type_id=s_type_id;
                   IF s_id IS NULL THEN 
                      INSERT INTO synonym(name, synonym_sgml, type_id) values(f_uniquename_protein, f_uniquename_protein, s_type_id);
                      SELECT INTO s_id synonym_id from synonym where name=f_uniquename_protein and type_id=s_type_id;
                   END IF;
                   SELECT INTO p_id pub_id from pub p, cvterm c where uniquename=p_miniref and c.name=p_cvterm_name and c.cvterm_id=p.type_id;
                      IF p_id IS NULL THEN
                         SELECT INTO p_type_id cvterm_id from cvterm where name=p_cvterm_name;
                         IF p_type_id IS NULL THEN
                             SELECT INTO c_cv_id cv_id from cv where name=p_cv_name;
                             IF c_cv_id IS NULL THEN
                                INSERT INTO cv(name) values(p_cv_name);
                                SELECT INTO c_cv_id cv_id from cv where name=p_cv_name;
                             END IF;
                             INSERT INTO cvterm(name, cv_id) values(p_cvterm_name, c_cv_id);
                             SELECT INTO c_cv_id cv_id from cv where name=p_cv_name;
                         END IF;
                         INSERT INTO pub(uniquename, miniref, type_id) values(p_miniref, p_miniref, p_type_id);
                         SELECT INTO p_id pub_id from pub p, cvterm c where uniquename=p_miniref and c.name=p_cvterm_name and c.cvterm_id=p.type_id;
                   END IF;
                   RAISE NOTICe ''start to insert feature_synonym:synonym_id:%,feature_id:%'', s_id, fr_row.subject_id;
                   INSERT INTO feature_synonym(feature_id, synonym_id, pub_id, is_current) values (fr_row.subject_id, s_id, p_id, ''true'');
                ELSIF  (f_row.uniquename like ''CG%-P_'' or f_row.uniquename like ''CR%-P_'') and  f_row.uniquename not like ''%temp%''  THEN
                   len:=length(f_row.uniquename);
                   letter_p:=substring(f_row.uniquename from len);
                   f_uniquename_protein:=CAST(f_uniquename||''-P''||letter_p  AS TEXT);
                   RAISE NOTICE ''letter_p:%, len:%, f_uniquename_protein:%'', letter_p, len, f_uniquename_protein;
                END IF;
                IF (f_row.name like ''%temp%'' or f_row.name like ''CG%'' or f_row.name like ''CR%'') and f_row.uniquename like ''%temp%'' THEN         
                    UPDATE feature set uniquename=f_uniquename_protein, name=f_uniquename_protein,  dbxref_id=d_id_temp where feature_id=fr_row.subject_id;
                ELSIF  f_row.uniquename like ''%temp%'' THEN
                   UPDATE feature set uniquename=f_uniquename_protein, dbxref_id=d_id_temp where feature_id=fr_row.subject_id;
                END IF;
             ELSIF f_type_temp =f_type_exon THEN
                RAISE NOTICE ''in f_u, update exon:%'', fr_row.subject_id;
                SELECT INTO f_row_e * from feature where feature_id=fr_row.subject_id;
                IF f_row_e.uniquename like ''CG:temp%'' or f_row_e.uniquename like ''CR:temp%'' THEN
                   len:=length(f_row_e.uniquename)-1;
                   RAISE NOTICE ''in f_u, uniquename for exon is:%'', f_row_e.uniquename;
                   RAISE NOTICE ''in f_u, no is:%'', len;
                   letter_e:=substring(f_row_e.uniquename from len for 2); 
                  RAISE NOTICE ''in f_u, letter_e:% for for exon:%'',letter_e, f_row_e.uniquename; 
                  pos:=position('':'' in letter_e);
                  IF pos =1 THEN
                     len:=len+1; 
                     letter_e:=substring(f_row_e.uniquename from len for 1); 
                  END IF;
                   f_uniquename_exon:=CAST(f_uniquename||'':''||letter_e AS TEXT); 
                   RAISE NOTICE ''letter_e:%, uniquename:%'', letter_e, f_uniquename_exon;
                   SELECT INTO d_id db_id from db where name=f_dbname_gadfly;
                   SELECT INTO dx_id dbxref_id from dbxref where db_id=d_id and accession=f_uniquename_exon;  
                   IF dx_id is NULL THEN
                       INSERT INTO dbxref(db_id, accession) values(d_id, f_uniquename_exon);
                       SELECT INTO dx_id dbxref_id from dbxref where db_id=d_id and accession=f_uniquename_exon;
                   END IF;
                   INSERT INTO feature_dbxref (feature_id, dbxref_id, is_current)  values(fr_row.subject_id, dx_id, ''false'');
                   SELECT INTO maxid_fb max(to_number(substring(accession from 5 for 11),''9999999'')) from dbxref dx, db d where dx.db_id=d.db_id and d.name = f_dbname_FB and accession like ''FBex%'';  
                   IF maxid_fb IS NULL OR maxid_fb< 70000  THEN
                      maxid_fb:=70000;
                   ELSE 
                    maxid_fb:=maxid_fb+1;
                   END IF;
                   id_fb:=lpad(maxid_fb, 7, ''0000000'');
                   fb_accession:=CAST(''FBex''||id_fb AS TEXT);
                   RAISE NOTICE ''fb_accession is:%'', fb_accession;
                   SELECT INTO d_id db_id from db where name=f_dbname_FB;
                   INSERT INTO dbxref(db_id, accession) values(d_id, fb_accession);
                   SELECT INTO dx_id dbxref_id from dbxref dx, db d where dx.db_id=d.db_id and d.name=f_dbname_FB and accession=fb_accession;
                   INSERT INTO feature_dbxref(feature_id, dbxref_id) values(fr_row.subject_id, dx_id);
                   RAISE NOTICE ''insert FBex:% into feature_dbxref, and set is_current as true'', fb_accession;
                   SELECT INTO s_type_id cvterm_id from cvterm c1, cv c2 where c1.name=c_name_synonym and c2.name=cv_cvname_synonym and c1.cv_id=c2.cv_id;
                   RAISE NOTICE ''s_type_id:%'', s_type_id;
                   SELECT INTO s_id synonym_id from synonym where name=f_uniquename_exon and type_id=s_type_id;
                   IF s_id IS NULL THEN
                     INSERT INTO synonym(name, synonym_sgml, type_id) values(f_uniquename_exon, f_uniquename_exon, s_type_id);
                     SELECT INTO s_id synonym_id from synonym where name=f_uniquename_exon and type_id=s_type_id;
                   END IF;
                   SELECT INTO p_id pub_id from pub p, cvterm c where uniquename=p_miniref and c.name=p_cvterm_name and c.cvterm_id=p.type_id;
                      IF p_id IS NULL THEN
                         SELECT INTO p_type_id cvterm_id from cvterm where name=p_cvterm_name;
                         IF p_type_id IS NULL THEN
                             SELECT INTO c_cv_id cv_id from cv where name=p_cv_name;
                             IF c_cv_id IS NULL THEN
                                INSERT INTO cv(name) values(p_cv_name);
                                SELECT INTO c_cv_id cv_id from cv where name=p_cv_name;
                             END IF;
                             INSERT INTO cvterm(name, cv_id) values(p_cvterm_name, c_cv_id);
                             SELECT INTO c_cv_id cv_id from cv where name=p_cv_name;
                         END IF;
                         INSERT INTO pub(uniquename, miniref, type_id) values(p_miniref, p_miniref, p_type_id);
                         SELECT INTO p_id pub_id from pub p, cvterm c where uniquename=p_miniref and c.name=p_cvterm_name and c.cvterm_id=p.type_id;
                   END IF;
                   RAISE NOTICe ''start to insert feature_synonym:synonym_id:%,feature_id:%'', s_id, fr_row.subject_id;
                   INSERT INTO feature_synonym(feature_id, synonym_id, pub_id, is_current) values (fr_row.subject_id, s_id, p_id, ''true'');

                   RAISE NOTICE ''in f_u, new uniquename for exon:%, old unqiuename:%'', f_uniquename_exon, f_row_e.uniquename;
                   SELECT INTO f_feature_id_exon feature_id from feature where uniquename=f_uniquename_exon;
                   IF f_feature_id_exon IS NOT NULL THEN 
                      RAISE NOTICE ''this exon:% share with other transcript, re_direct to exist exon and delete this one'', f_row_e.uniquename;
                      UPDATE feature_relationship set subject_id=f_feature_id_exon where feature_relationship_id=fr_row.feature_relationship_id;
                      delete from feature_dbxref where feature_id=f_row_e.feature_id;
                      delete from feature_synonym where  feature_id=f_row_e.feature_id;
                      delete from featureprop where feature_id=f_row_e.feature_id;
                      DELETE from featureloc where feature_id=f_row_e.feature_id;
                      DELETE from feature where feature_id=f_row_e.feature_id;
                   ELSE 
                     IF (f_row_e.name like ''%temp%'' or f_row_e.name like ''CG%'' or  f_row_e.name like ''CR%'') and f_row_e.uniquename like ''%temp%'' THEN         
                        RAISE NOTICE ''in f_u, update both uniquename and name for exon:%'', f_row_e.uniquename;  
                        UPDATE feature set uniquename=f_uniquename_exon, name=f_uniquename_exon,  dbxref_id=dx_id where feature_id=fr_row.subject_id;
                     ELSIF f_row_e.uniquename like ''%temp%'' THEN
                        RAISE NOTICE ''in f_u, update exon uniuqnename:% to %'', f_row_e.uniquename, f_uniquename_exon;   
                        UPDATE feature set uniquename=f_uniquename_exon, dbxref_id=dx_id where feature_id=fr_row.subject_id;
                     END IF;
                   END IF;
                ELSIF  (f_row_e.uniquename like ''CG%:_%'' or f_row_e.uniquename like ''CR%:_%'') and f_row_e.uniquename not like ''%temp%'' THEN
                   len:=position('':'' in f_row_e.uniquename);
                   pos:=length (f_uniquename);
                   RAISE NOTICE ''len:%'', len;
                   letter_e:=substring(f_row_e.uniquename from len+1);
                   f_uniquename_exon:=CAST(f_uniquename||'':''||letter_e AS TEXT);
                   RAISE NOTICE ''f_uniquename_exon:%, f_row.uniquename:%, len:%'', f_uniquename_exon, f_row_e.uniquename, len;
                END IF;

             ELSE
                RAISE NOTICE ''wrong relationship: transcript->no_exon/protein, obj:%, subj:%'', fr_row.object_id, fr_row.subject_id;
             END IF;
          END LOOP;
        END IF;
      END IF;
  END IF; 
  RETURN OLD;
END;
'LANGUAGE plpgsql;

GRANT ALL ON FUNCTION feature_propagatename_fn_u() TO PUBLIC;

CREATE TRIGGER feature_propagatename_tr_u AFTER UPDATE ON feature FOR EACH ROW EXECUTE PROCEDURE feature_propagatename_fn_u();

DROP TABLE trigger_log;
CREATE TABLE trigger_log(
   value   varchar(255) not null,
   timeaccessioned   timestamp not null default current_timestamp,
   table_name   varchar(50),
   id      int 
);

GRANT ALL ON TABLE trigger_log TO PUBLIC;
