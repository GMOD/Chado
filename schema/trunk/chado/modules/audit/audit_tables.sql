--audit tables generated from 
-- % sqlt -f PostgreSQL -t TTSchema --template add-audits.tmpl nofuncs.sql>audit_tables.sql


   DROP TABLE audit_tableinfo;
   CREATE TABLE audit_tableinfo ( 
       tableinfo_id integer, 
       name varchar(30), 
       primary_key_column varchar(30), 
       is_view integer, 
       view_on_table_id integer, 
       superclass_table_id integer, 
       is_updateable integer, 
       modification_date date, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_tableinfo to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_tableinfo() RETURNS trigger AS
   '
   DECLARE
       tableinfo_id_var integer; 
       name_var varchar(30); 
       primary_key_column_var varchar(30); 
       is_view_var integer; 
       view_on_table_id_var integer; 
       superclass_table_id_var integer; 
       is_updateable_var integer; 
       modification_date_var date; 
       
       transaction_type_var char;
   BEGIN
       tableinfo_id_var = OLD.tableinfo_id;
       name_var = OLD.name;
       primary_key_column_var = OLD.primary_key_column;
       is_view_var = OLD.is_view;
       view_on_table_id_var = OLD.view_on_table_id;
       superclass_table_id_var = OLD.superclass_table_id;
       is_updateable_var = OLD.is_updateable;
       modification_date_var = OLD.modification_date;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_tableinfo ( 
             tableinfo_id, 
             name, 
             primary_key_column, 
             is_view, 
             view_on_table_id, 
             superclass_table_id, 
             is_updateable, 
             modification_date, 
             transaction_type
       ) VALUES ( 
             tableinfo_id_var, 
             name_var, 
             primary_key_column_var, 
             is_view_var, 
             view_on_table_id_var, 
             superclass_table_id_var, 
             is_updateable_var, 
             modification_date_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER tableinfo_audit_ud ON tableinfo;
   CREATE TRIGGER tableinfo_audit_ud
       BEFORE UPDATE OR DELETE ON tableinfo
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_tableinfo ();


   DROP TABLE audit_db;
   CREATE TABLE audit_db ( 
       db_id integer, 
       name varchar(255), 
       description varchar(255), 
       urlprefix varchar(255), 
       url varchar(255), 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_db to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_db() RETURNS trigger AS
   '
   DECLARE
       db_id_var integer; 
       name_var varchar(255); 
       description_var varchar(255); 
       urlprefix_var varchar(255); 
       url_var varchar(255); 
       
       transaction_type_var char;
   BEGIN
       db_id_var = OLD.db_id;
       name_var = OLD.name;
       description_var = OLD.description;
       urlprefix_var = OLD.urlprefix;
       url_var = OLD.url;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_db ( 
             db_id, 
             name, 
             description, 
             urlprefix, 
             url, 
             transaction_type
       ) VALUES ( 
             db_id_var, 
             name_var, 
             description_var, 
             urlprefix_var, 
             url_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER db_audit_ud ON db;
   CREATE TRIGGER db_audit_ud
       BEFORE UPDATE OR DELETE ON db
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_db ();


   DROP TABLE audit_dbxref;
   CREATE TABLE audit_dbxref ( 
       dbxref_id integer, 
       db_id integer, 
       accession varchar(255), 
       version varchar(255), 
       description text, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_dbxref to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_dbxref() RETURNS trigger AS
   '
   DECLARE
       dbxref_id_var integer; 
       db_id_var integer; 
       accession_var varchar(255); 
       version_var varchar(255); 
       description_var text; 
       
       transaction_type_var char;
   BEGIN
       dbxref_id_var = OLD.dbxref_id;
       db_id_var = OLD.db_id;
       accession_var = OLD.accession;
       version_var = OLD.version;
       description_var = OLD.description;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_dbxref ( 
             dbxref_id, 
             db_id, 
             accession, 
             version, 
             description, 
             transaction_type
       ) VALUES ( 
             dbxref_id_var, 
             db_id_var, 
             accession_var, 
             version_var, 
             description_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER dbxref_audit_ud ON dbxref;
   CREATE TRIGGER dbxref_audit_ud
       BEFORE UPDATE OR DELETE ON dbxref
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_dbxref ();


   DROP TABLE audit_cv;
   CREATE TABLE audit_cv ( 
       cv_id integer, 
       name varchar(255), 
       definition text, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_cv to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_cv() RETURNS trigger AS
   '
   DECLARE
       cv_id_var integer; 
       name_var varchar(255); 
       definition_var text; 
       
       transaction_type_var char;
   BEGIN
       cv_id_var = OLD.cv_id;
       name_var = OLD.name;
       definition_var = OLD.definition;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_cv ( 
             cv_id, 
             name, 
             definition, 
             transaction_type
       ) VALUES ( 
             cv_id_var, 
             name_var, 
             definition_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER cv_audit_ud ON cv;
   CREATE TRIGGER cv_audit_ud
       BEFORE UPDATE OR DELETE ON cv
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_cv ();


   DROP TABLE audit_cvterm;
   CREATE TABLE audit_cvterm ( 
       cvterm_id integer, 
       cv_id integer, 
       name varchar(1024), 
       definition text, 
       dbxref_id integer, 
       is_obsolete integer, 
       is_relationshiptype integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_cvterm to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_cvterm() RETURNS trigger AS
   '
   DECLARE
       cvterm_id_var integer; 
       cv_id_var integer; 
       name_var varchar(1024); 
       definition_var text; 
       dbxref_id_var integer; 
       is_obsolete_var integer; 
       is_relationshiptype_var integer; 
       
       transaction_type_var char;
   BEGIN
       cvterm_id_var = OLD.cvterm_id;
       cv_id_var = OLD.cv_id;
       name_var = OLD.name;
       definition_var = OLD.definition;
       dbxref_id_var = OLD.dbxref_id;
       is_obsolete_var = OLD.is_obsolete;
       is_relationshiptype_var = OLD.is_relationshiptype;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_cvterm ( 
             cvterm_id, 
             cv_id, 
             name, 
             definition, 
             dbxref_id, 
             is_obsolete, 
             is_relationshiptype, 
             transaction_type
       ) VALUES ( 
             cvterm_id_var, 
             cv_id_var, 
             name_var, 
             definition_var, 
             dbxref_id_var, 
             is_obsolete_var, 
             is_relationshiptype_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER cvterm_audit_ud ON cvterm;
   CREATE TRIGGER cvterm_audit_ud
       BEFORE UPDATE OR DELETE ON cvterm
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_cvterm ();


   DROP TABLE audit_cvterm_relationship;
   CREATE TABLE audit_cvterm_relationship ( 
       cvterm_relationship_id integer, 
       type_id integer, 
       subject_id integer, 
       object_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_cvterm_relationship to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_cvterm_relationship() RETURNS trigger AS
   '
   DECLARE
       cvterm_relationship_id_var integer; 
       type_id_var integer; 
       subject_id_var integer; 
       object_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       cvterm_relationship_id_var = OLD.cvterm_relationship_id;
       type_id_var = OLD.type_id;
       subject_id_var = OLD.subject_id;
       object_id_var = OLD.object_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_cvterm_relationship ( 
             cvterm_relationship_id, 
             type_id, 
             subject_id, 
             object_id, 
             transaction_type
       ) VALUES ( 
             cvterm_relationship_id_var, 
             type_id_var, 
             subject_id_var, 
             object_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER cvterm_relationship_audit_ud ON cvterm_relationship;
   CREATE TRIGGER cvterm_relationship_audit_ud
       BEFORE UPDATE OR DELETE ON cvterm_relationship
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_cvterm_relationship ();


   DROP TABLE audit_cvtermpath;
   CREATE TABLE audit_cvtermpath ( 
       cvtermpath_id integer, 
       type_id integer, 
       subject_id integer, 
       object_id integer, 
       cv_id integer, 
       pathdistance integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_cvtermpath to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_cvtermpath() RETURNS trigger AS
   '
   DECLARE
       cvtermpath_id_var integer; 
       type_id_var integer; 
       subject_id_var integer; 
       object_id_var integer; 
       cv_id_var integer; 
       pathdistance_var integer; 
       
       transaction_type_var char;
   BEGIN
       cvtermpath_id_var = OLD.cvtermpath_id;
       type_id_var = OLD.type_id;
       subject_id_var = OLD.subject_id;
       object_id_var = OLD.object_id;
       cv_id_var = OLD.cv_id;
       pathdistance_var = OLD.pathdistance;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_cvtermpath ( 
             cvtermpath_id, 
             type_id, 
             subject_id, 
             object_id, 
             cv_id, 
             pathdistance, 
             transaction_type
       ) VALUES ( 
             cvtermpath_id_var, 
             type_id_var, 
             subject_id_var, 
             object_id_var, 
             cv_id_var, 
             pathdistance_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER cvtermpath_audit_ud ON cvtermpath;
   CREATE TRIGGER cvtermpath_audit_ud
       BEFORE UPDATE OR DELETE ON cvtermpath
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_cvtermpath ();


   DROP TABLE audit_cvtermsynonym;
   CREATE TABLE audit_cvtermsynonym ( 
       cvtermsynonym_id integer, 
       cvterm_id integer, 
       synonym varchar(1024), 
       type_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_cvtermsynonym to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_cvtermsynonym() RETURNS trigger AS
   '
   DECLARE
       cvtermsynonym_id_var integer; 
       cvterm_id_var integer; 
       synonym_var varchar(1024); 
       type_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       cvtermsynonym_id_var = OLD.cvtermsynonym_id;
       cvterm_id_var = OLD.cvterm_id;
       synonym_var = OLD.synonym;
       type_id_var = OLD.type_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_cvtermsynonym ( 
             cvtermsynonym_id, 
             cvterm_id, 
             synonym, 
             type_id, 
             transaction_type
       ) VALUES ( 
             cvtermsynonym_id_var, 
             cvterm_id_var, 
             synonym_var, 
             type_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER cvtermsynonym_audit_ud ON cvtermsynonym;
   CREATE TRIGGER cvtermsynonym_audit_ud
       BEFORE UPDATE OR DELETE ON cvtermsynonym
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_cvtermsynonym ();


   DROP TABLE audit_cvterm_dbxref;
   CREATE TABLE audit_cvterm_dbxref ( 
       cvterm_dbxref_id integer, 
       cvterm_id integer, 
       dbxref_id integer, 
       is_for_definition integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_cvterm_dbxref to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_cvterm_dbxref() RETURNS trigger AS
   '
   DECLARE
       cvterm_dbxref_id_var integer; 
       cvterm_id_var integer; 
       dbxref_id_var integer; 
       is_for_definition_var integer; 
       
       transaction_type_var char;
   BEGIN
       cvterm_dbxref_id_var = OLD.cvterm_dbxref_id;
       cvterm_id_var = OLD.cvterm_id;
       dbxref_id_var = OLD.dbxref_id;
       is_for_definition_var = OLD.is_for_definition;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_cvterm_dbxref ( 
             cvterm_dbxref_id, 
             cvterm_id, 
             dbxref_id, 
             is_for_definition, 
             transaction_type
       ) VALUES ( 
             cvterm_dbxref_id_var, 
             cvterm_id_var, 
             dbxref_id_var, 
             is_for_definition_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER cvterm_dbxref_audit_ud ON cvterm_dbxref;
   CREATE TRIGGER cvterm_dbxref_audit_ud
       BEFORE UPDATE OR DELETE ON cvterm_dbxref
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_cvterm_dbxref ();


   DROP TABLE audit_cvtermprop;
   CREATE TABLE audit_cvtermprop ( 
       cvtermprop_id integer, 
       cvterm_id integer, 
       type_id integer, 
       value text, 
       rank integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_cvtermprop to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_cvtermprop() RETURNS trigger AS
   '
   DECLARE
       cvtermprop_id_var integer; 
       cvterm_id_var integer; 
       type_id_var integer; 
       value_var text; 
       rank_var integer; 
       
       transaction_type_var char;
   BEGIN
       cvtermprop_id_var = OLD.cvtermprop_id;
       cvterm_id_var = OLD.cvterm_id;
       type_id_var = OLD.type_id;
       value_var = OLD.value;
       rank_var = OLD.rank;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_cvtermprop ( 
             cvtermprop_id, 
             cvterm_id, 
             type_id, 
             value, 
             rank, 
             transaction_type
       ) VALUES ( 
             cvtermprop_id_var, 
             cvterm_id_var, 
             type_id_var, 
             value_var, 
             rank_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER cvtermprop_audit_ud ON cvtermprop;
   CREATE TRIGGER cvtermprop_audit_ud
       BEFORE UPDATE OR DELETE ON cvtermprop
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_cvtermprop ();


   DROP TABLE audit_dbxrefprop;
   CREATE TABLE audit_dbxrefprop ( 
       dbxrefprop_id integer, 
       dbxref_id integer, 
       type_id integer, 
       value text, 
       rank integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_dbxrefprop to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_dbxrefprop() RETURNS trigger AS
   '
   DECLARE
       dbxrefprop_id_var integer; 
       dbxref_id_var integer; 
       type_id_var integer; 
       value_var text; 
       rank_var integer; 
       
       transaction_type_var char;
   BEGIN
       dbxrefprop_id_var = OLD.dbxrefprop_id;
       dbxref_id_var = OLD.dbxref_id;
       type_id_var = OLD.type_id;
       value_var = OLD.value;
       rank_var = OLD.rank;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_dbxrefprop ( 
             dbxrefprop_id, 
             dbxref_id, 
             type_id, 
             value, 
             rank, 
             transaction_type
       ) VALUES ( 
             dbxrefprop_id_var, 
             dbxref_id_var, 
             type_id_var, 
             value_var, 
             rank_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER dbxrefprop_audit_ud ON dbxrefprop;
   CREATE TRIGGER dbxrefprop_audit_ud
       BEFORE UPDATE OR DELETE ON dbxrefprop
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_dbxrefprop ();


   DROP TABLE audit_cvprop;
   CREATE TABLE audit_cvprop ( 
       cvprop_id integer, 
       cv_id integer, 
       type_id integer, 
       value text, 
       rank integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_cvprop to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_cvprop() RETURNS trigger AS
   '
   DECLARE
       cvprop_id_var integer; 
       cv_id_var integer; 
       type_id_var integer; 
       value_var text; 
       rank_var integer; 
       
       transaction_type_var char;
   BEGIN
       cvprop_id_var = OLD.cvprop_id;
       cv_id_var = OLD.cv_id;
       type_id_var = OLD.type_id;
       value_var = OLD.value;
       rank_var = OLD.rank;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_cvprop ( 
             cvprop_id, 
             cv_id, 
             type_id, 
             value, 
             rank, 
             transaction_type
       ) VALUES ( 
             cvprop_id_var, 
             cv_id_var, 
             type_id_var, 
             value_var, 
             rank_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER cvprop_audit_ud ON cvprop;
   CREATE TRIGGER cvprop_audit_ud
       BEFORE UPDATE OR DELETE ON cvprop
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_cvprop ();


   DROP TABLE audit_pub;
   CREATE TABLE audit_pub ( 
       pub_id integer, 
       title text, 
       volumetitle text, 
       volume varchar(255), 
       series_name varchar(255), 
       issue varchar(255), 
       pyear varchar(255), 
       pages varchar(255), 
       miniref varchar(255), 
       uniquename text, 
       type_id integer, 
       is_obsolete boolean, 
       publisher varchar(255), 
       pubplace varchar(255), 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_pub to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_pub() RETURNS trigger AS
   '
   DECLARE
       pub_id_var integer; 
       title_var text; 
       volumetitle_var text; 
       volume_var varchar(255); 
       series_name_var varchar(255); 
       issue_var varchar(255); 
       pyear_var varchar(255); 
       pages_var varchar(255); 
       miniref_var varchar(255); 
       uniquename_var text; 
       type_id_var integer; 
       is_obsolete_var boolean; 
       publisher_var varchar(255); 
       pubplace_var varchar(255); 
       
       transaction_type_var char;
   BEGIN
       pub_id_var = OLD.pub_id;
       title_var = OLD.title;
       volumetitle_var = OLD.volumetitle;
       volume_var = OLD.volume;
       series_name_var = OLD.series_name;
       issue_var = OLD.issue;
       pyear_var = OLD.pyear;
       pages_var = OLD.pages;
       miniref_var = OLD.miniref;
       uniquename_var = OLD.uniquename;
       type_id_var = OLD.type_id;
       is_obsolete_var = OLD.is_obsolete;
       publisher_var = OLD.publisher;
       pubplace_var = OLD.pubplace;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_pub ( 
             pub_id, 
             title, 
             volumetitle, 
             volume, 
             series_name, 
             issue, 
             pyear, 
             pages, 
             miniref, 
             uniquename, 
             type_id, 
             is_obsolete, 
             publisher, 
             pubplace, 
             transaction_type
       ) VALUES ( 
             pub_id_var, 
             title_var, 
             volumetitle_var, 
             volume_var, 
             series_name_var, 
             issue_var, 
             pyear_var, 
             pages_var, 
             miniref_var, 
             uniquename_var, 
             type_id_var, 
             is_obsolete_var, 
             publisher_var, 
             pubplace_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER pub_audit_ud ON pub;
   CREATE TRIGGER pub_audit_ud
       BEFORE UPDATE OR DELETE ON pub
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_pub ();


   DROP TABLE audit_pub_relationship;
   CREATE TABLE audit_pub_relationship ( 
       pub_relationship_id integer, 
       subject_id integer, 
       object_id integer, 
       type_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_pub_relationship to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_pub_relationship() RETURNS trigger AS
   '
   DECLARE
       pub_relationship_id_var integer; 
       subject_id_var integer; 
       object_id_var integer; 
       type_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       pub_relationship_id_var = OLD.pub_relationship_id;
       subject_id_var = OLD.subject_id;
       object_id_var = OLD.object_id;
       type_id_var = OLD.type_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_pub_relationship ( 
             pub_relationship_id, 
             subject_id, 
             object_id, 
             type_id, 
             transaction_type
       ) VALUES ( 
             pub_relationship_id_var, 
             subject_id_var, 
             object_id_var, 
             type_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER pub_relationship_audit_ud ON pub_relationship;
   CREATE TRIGGER pub_relationship_audit_ud
       BEFORE UPDATE OR DELETE ON pub_relationship
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_pub_relationship ();


   DROP TABLE audit_pub_dbxref;
   CREATE TABLE audit_pub_dbxref ( 
       pub_dbxref_id integer, 
       pub_id integer, 
       dbxref_id integer, 
       is_current boolean, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_pub_dbxref to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_pub_dbxref() RETURNS trigger AS
   '
   DECLARE
       pub_dbxref_id_var integer; 
       pub_id_var integer; 
       dbxref_id_var integer; 
       is_current_var boolean; 
       
       transaction_type_var char;
   BEGIN
       pub_dbxref_id_var = OLD.pub_dbxref_id;
       pub_id_var = OLD.pub_id;
       dbxref_id_var = OLD.dbxref_id;
       is_current_var = OLD.is_current;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_pub_dbxref ( 
             pub_dbxref_id, 
             pub_id, 
             dbxref_id, 
             is_current, 
             transaction_type
       ) VALUES ( 
             pub_dbxref_id_var, 
             pub_id_var, 
             dbxref_id_var, 
             is_current_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER pub_dbxref_audit_ud ON pub_dbxref;
   CREATE TRIGGER pub_dbxref_audit_ud
       BEFORE UPDATE OR DELETE ON pub_dbxref
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_pub_dbxref ();


   DROP TABLE audit_pubauthor;
   CREATE TABLE audit_pubauthor ( 
       pubauthor_id integer, 
       pub_id integer, 
       rank integer, 
       editor boolean, 
       surname varchar(100), 
       givennames varchar(100), 
       suffix varchar(100), 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_pubauthor to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_pubauthor() RETURNS trigger AS
   '
   DECLARE
       pubauthor_id_var integer; 
       pub_id_var integer; 
       rank_var integer; 
       editor_var boolean; 
       surname_var varchar(100); 
       givennames_var varchar(100); 
       suffix_var varchar(100); 
       
       transaction_type_var char;
   BEGIN
       pubauthor_id_var = OLD.pubauthor_id;
       pub_id_var = OLD.pub_id;
       rank_var = OLD.rank;
       editor_var = OLD.editor;
       surname_var = OLD.surname;
       givennames_var = OLD.givennames;
       suffix_var = OLD.suffix;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_pubauthor ( 
             pubauthor_id, 
             pub_id, 
             rank, 
             editor, 
             surname, 
             givennames, 
             suffix, 
             transaction_type
       ) VALUES ( 
             pubauthor_id_var, 
             pub_id_var, 
             rank_var, 
             editor_var, 
             surname_var, 
             givennames_var, 
             suffix_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER pubauthor_audit_ud ON pubauthor;
   CREATE TRIGGER pubauthor_audit_ud
       BEFORE UPDATE OR DELETE ON pubauthor
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_pubauthor ();


   DROP TABLE audit_pubprop;
   CREATE TABLE audit_pubprop ( 
       pubprop_id integer, 
       pub_id integer, 
       type_id integer, 
       value text, 
       rank integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_pubprop to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_pubprop() RETURNS trigger AS
   '
   DECLARE
       pubprop_id_var integer; 
       pub_id_var integer; 
       type_id_var integer; 
       value_var text; 
       rank_var integer; 
       
       transaction_type_var char;
   BEGIN
       pubprop_id_var = OLD.pubprop_id;
       pub_id_var = OLD.pub_id;
       type_id_var = OLD.type_id;
       value_var = OLD.value;
       rank_var = OLD.rank;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_pubprop ( 
             pubprop_id, 
             pub_id, 
             type_id, 
             value, 
             rank, 
             transaction_type
       ) VALUES ( 
             pubprop_id_var, 
             pub_id_var, 
             type_id_var, 
             value_var, 
             rank_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER pubprop_audit_ud ON pubprop;
   CREATE TRIGGER pubprop_audit_ud
       BEFORE UPDATE OR DELETE ON pubprop
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_pubprop ();


   DROP TABLE audit_organism;
   CREATE TABLE audit_organism ( 
       organism_id integer, 
       abbreviation varchar(255), 
       genus varchar(255), 
       species varchar(255), 
       common_name varchar(255), 
       comment text, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_organism to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_organism() RETURNS trigger AS
   '
   DECLARE
       organism_id_var integer; 
       abbreviation_var varchar(255); 
       genus_var varchar(255); 
       species_var varchar(255); 
       common_name_var varchar(255); 
       comment_var text; 
       
       transaction_type_var char;
   BEGIN
       organism_id_var = OLD.organism_id;
       abbreviation_var = OLD.abbreviation;
       genus_var = OLD.genus;
       species_var = OLD.species;
       common_name_var = OLD.common_name;
       comment_var = OLD.comment;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_organism ( 
             organism_id, 
             abbreviation, 
             genus, 
             species, 
             common_name, 
             comment, 
             transaction_type
       ) VALUES ( 
             organism_id_var, 
             abbreviation_var, 
             genus_var, 
             species_var, 
             common_name_var, 
             comment_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER organism_audit_ud ON organism;
   CREATE TRIGGER organism_audit_ud
       BEFORE UPDATE OR DELETE ON organism
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_organism ();


   DROP TABLE audit_organism_dbxref;
   CREATE TABLE audit_organism_dbxref ( 
       organism_dbxref_id integer, 
       organism_id integer, 
       dbxref_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_organism_dbxref to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_organism_dbxref() RETURNS trigger AS
   '
   DECLARE
       organism_dbxref_id_var integer; 
       organism_id_var integer; 
       dbxref_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       organism_dbxref_id_var = OLD.organism_dbxref_id;
       organism_id_var = OLD.organism_id;
       dbxref_id_var = OLD.dbxref_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_organism_dbxref ( 
             organism_dbxref_id, 
             organism_id, 
             dbxref_id, 
             transaction_type
       ) VALUES ( 
             organism_dbxref_id_var, 
             organism_id_var, 
             dbxref_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER organism_dbxref_audit_ud ON organism_dbxref;
   CREATE TRIGGER organism_dbxref_audit_ud
       BEFORE UPDATE OR DELETE ON organism_dbxref
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_organism_dbxref ();


   DROP TABLE audit_organismprop;
   CREATE TABLE audit_organismprop ( 
       organismprop_id integer, 
       organism_id integer, 
       type_id integer, 
       value text, 
       rank integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_organismprop to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_organismprop() RETURNS trigger AS
   '
   DECLARE
       organismprop_id_var integer; 
       organism_id_var integer; 
       type_id_var integer; 
       value_var text; 
       rank_var integer; 
       
       transaction_type_var char;
   BEGIN
       organismprop_id_var = OLD.organismprop_id;
       organism_id_var = OLD.organism_id;
       type_id_var = OLD.type_id;
       value_var = OLD.value;
       rank_var = OLD.rank;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_organismprop ( 
             organismprop_id, 
             organism_id, 
             type_id, 
             value, 
             rank, 
             transaction_type
       ) VALUES ( 
             organismprop_id_var, 
             organism_id_var, 
             type_id_var, 
             value_var, 
             rank_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER organismprop_audit_ud ON organismprop;
   CREATE TRIGGER organismprop_audit_ud
       BEFORE UPDATE OR DELETE ON organismprop
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_organismprop ();


   DROP TABLE audit_feature;
   CREATE TABLE audit_feature ( 
       feature_id integer, 
       dbxref_id integer, 
       organism_id integer, 
       name varchar(255), 
       uniquename text, 
       residues text, 
       seqlen integer, 
       md5checksum char(32), 
       type_id integer, 
       is_analysis boolean, 
       is_obsolete boolean, 
       timeaccessioned timestamp, 
       timelastmodified timestamp, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_feature to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_feature() RETURNS trigger AS
   '
   DECLARE
       feature_id_var integer; 
       dbxref_id_var integer; 
       organism_id_var integer; 
       name_var varchar(255); 
       uniquename_var text; 
       residues_var text; 
       seqlen_var integer; 
       md5checksum_var char(32); 
       type_id_var integer; 
       is_analysis_var boolean; 
       is_obsolete_var boolean; 
       timeaccessioned_var timestamp; 
       timelastmodified_var timestamp; 
       
       transaction_type_var char;
   BEGIN
       feature_id_var = OLD.feature_id;
       dbxref_id_var = OLD.dbxref_id;
       organism_id_var = OLD.organism_id;
       name_var = OLD.name;
       uniquename_var = OLD.uniquename;
       residues_var = OLD.residues;
       seqlen_var = OLD.seqlen;
       md5checksum_var = OLD.md5checksum;
       type_id_var = OLD.type_id;
       is_analysis_var = OLD.is_analysis;
       is_obsolete_var = OLD.is_obsolete;
       timeaccessioned_var = OLD.timeaccessioned;
       timelastmodified_var = OLD.timelastmodified;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_feature ( 
             feature_id, 
             dbxref_id, 
             organism_id, 
             name, 
             uniquename, 
             residues, 
             seqlen, 
             md5checksum, 
             type_id, 
             is_analysis, 
             is_obsolete, 
             timeaccessioned, 
             timelastmodified, 
             transaction_type
       ) VALUES ( 
             feature_id_var, 
             dbxref_id_var, 
             organism_id_var, 
             name_var, 
             uniquename_var, 
             residues_var, 
             seqlen_var, 
             md5checksum_var, 
             type_id_var, 
             is_analysis_var, 
             is_obsolete_var, 
             timeaccessioned_var, 
             timelastmodified_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER feature_audit_ud ON feature;
   CREATE TRIGGER feature_audit_ud
       BEFORE UPDATE OR DELETE ON feature
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_feature ();


   DROP TABLE audit_featureloc;
   CREATE TABLE audit_featureloc ( 
       featureloc_id integer, 
       feature_id integer, 
       srcfeature_id integer, 
       fmin integer, 
       is_fmin_partial boolean, 
       fmax integer, 
       is_fmax_partial boolean, 
       strand integer, 
       phase integer, 
       residue_info text, 
       locgroup integer, 
       rank integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_featureloc to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_featureloc() RETURNS trigger AS
   '
   DECLARE
       featureloc_id_var integer; 
       feature_id_var integer; 
       srcfeature_id_var integer; 
       fmin_var integer; 
       is_fmin_partial_var boolean; 
       fmax_var integer; 
       is_fmax_partial_var boolean; 
       strand_var integer; 
       phase_var integer; 
       residue_info_var text; 
       locgroup_var integer; 
       rank_var integer; 
       
       transaction_type_var char;
   BEGIN
       featureloc_id_var = OLD.featureloc_id;
       feature_id_var = OLD.feature_id;
       srcfeature_id_var = OLD.srcfeature_id;
       fmin_var = OLD.fmin;
       is_fmin_partial_var = OLD.is_fmin_partial;
       fmax_var = OLD.fmax;
       is_fmax_partial_var = OLD.is_fmax_partial;
       strand_var = OLD.strand;
       phase_var = OLD.phase;
       residue_info_var = OLD.residue_info;
       locgroup_var = OLD.locgroup;
       rank_var = OLD.rank;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_featureloc ( 
             featureloc_id, 
             feature_id, 
             srcfeature_id, 
             fmin, 
             is_fmin_partial, 
             fmax, 
             is_fmax_partial, 
             strand, 
             phase, 
             residue_info, 
             locgroup, 
             rank, 
             transaction_type
       ) VALUES ( 
             featureloc_id_var, 
             feature_id_var, 
             srcfeature_id_var, 
             fmin_var, 
             is_fmin_partial_var, 
             fmax_var, 
             is_fmax_partial_var, 
             strand_var, 
             phase_var, 
             residue_info_var, 
             locgroup_var, 
             rank_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER featureloc_audit_ud ON featureloc;
   CREATE TRIGGER featureloc_audit_ud
       BEFORE UPDATE OR DELETE ON featureloc
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_featureloc ();


   DROP TABLE audit_featureloc_pub;
   CREATE TABLE audit_featureloc_pub ( 
       featureloc_pub_id integer, 
       featureloc_id integer, 
       pub_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_featureloc_pub to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_featureloc_pub() RETURNS trigger AS
   '
   DECLARE
       featureloc_pub_id_var integer; 
       featureloc_id_var integer; 
       pub_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       featureloc_pub_id_var = OLD.featureloc_pub_id;
       featureloc_id_var = OLD.featureloc_id;
       pub_id_var = OLD.pub_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_featureloc_pub ( 
             featureloc_pub_id, 
             featureloc_id, 
             pub_id, 
             transaction_type
       ) VALUES ( 
             featureloc_pub_id_var, 
             featureloc_id_var, 
             pub_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER featureloc_pub_audit_ud ON featureloc_pub;
   CREATE TRIGGER featureloc_pub_audit_ud
       BEFORE UPDATE OR DELETE ON featureloc_pub
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_featureloc_pub ();


   DROP TABLE audit_feature_pub;
   CREATE TABLE audit_feature_pub ( 
       feature_pub_id integer, 
       feature_id integer, 
       pub_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_feature_pub to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_feature_pub() RETURNS trigger AS
   '
   DECLARE
       feature_pub_id_var integer; 
       feature_id_var integer; 
       pub_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       feature_pub_id_var = OLD.feature_pub_id;
       feature_id_var = OLD.feature_id;
       pub_id_var = OLD.pub_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_feature_pub ( 
             feature_pub_id, 
             feature_id, 
             pub_id, 
             transaction_type
       ) VALUES ( 
             feature_pub_id_var, 
             feature_id_var, 
             pub_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER feature_pub_audit_ud ON feature_pub;
   CREATE TRIGGER feature_pub_audit_ud
       BEFORE UPDATE OR DELETE ON feature_pub
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_feature_pub ();


   DROP TABLE audit_feature_pubprop;
   CREATE TABLE audit_feature_pubprop ( 
       feature_pubprop_id integer, 
       feature_pub_id integer, 
       type_id integer, 
       value text, 
       rank integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_feature_pubprop to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_feature_pubprop() RETURNS trigger AS
   '
   DECLARE
       feature_pubprop_id_var integer; 
       feature_pub_id_var integer; 
       type_id_var integer; 
       value_var text; 
       rank_var integer; 
       
       transaction_type_var char;
   BEGIN
       feature_pubprop_id_var = OLD.feature_pubprop_id;
       feature_pub_id_var = OLD.feature_pub_id;
       type_id_var = OLD.type_id;
       value_var = OLD.value;
       rank_var = OLD.rank;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_feature_pubprop ( 
             feature_pubprop_id, 
             feature_pub_id, 
             type_id, 
             value, 
             rank, 
             transaction_type
       ) VALUES ( 
             feature_pubprop_id_var, 
             feature_pub_id_var, 
             type_id_var, 
             value_var, 
             rank_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER feature_pubprop_audit_ud ON feature_pubprop;
   CREATE TRIGGER feature_pubprop_audit_ud
       BEFORE UPDATE OR DELETE ON feature_pubprop
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_feature_pubprop ();


   DROP TABLE audit_featureprop;
   CREATE TABLE audit_featureprop ( 
       featureprop_id integer, 
       feature_id integer, 
       type_id integer, 
       value text, 
       rank integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_featureprop to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_featureprop() RETURNS trigger AS
   '
   DECLARE
       featureprop_id_var integer; 
       feature_id_var integer; 
       type_id_var integer; 
       value_var text; 
       rank_var integer; 
       
       transaction_type_var char;
   BEGIN
       featureprop_id_var = OLD.featureprop_id;
       feature_id_var = OLD.feature_id;
       type_id_var = OLD.type_id;
       value_var = OLD.value;
       rank_var = OLD.rank;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_featureprop ( 
             featureprop_id, 
             feature_id, 
             type_id, 
             value, 
             rank, 
             transaction_type
       ) VALUES ( 
             featureprop_id_var, 
             feature_id_var, 
             type_id_var, 
             value_var, 
             rank_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER featureprop_audit_ud ON featureprop;
   CREATE TRIGGER featureprop_audit_ud
       BEFORE UPDATE OR DELETE ON featureprop
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_featureprop ();


   DROP TABLE audit_featureprop_pub;
   CREATE TABLE audit_featureprop_pub ( 
       featureprop_pub_id integer, 
       featureprop_id integer, 
       pub_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_featureprop_pub to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_featureprop_pub() RETURNS trigger AS
   '
   DECLARE
       featureprop_pub_id_var integer; 
       featureprop_id_var integer; 
       pub_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       featureprop_pub_id_var = OLD.featureprop_pub_id;
       featureprop_id_var = OLD.featureprop_id;
       pub_id_var = OLD.pub_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_featureprop_pub ( 
             featureprop_pub_id, 
             featureprop_id, 
             pub_id, 
             transaction_type
       ) VALUES ( 
             featureprop_pub_id_var, 
             featureprop_id_var, 
             pub_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER featureprop_pub_audit_ud ON featureprop_pub;
   CREATE TRIGGER featureprop_pub_audit_ud
       BEFORE UPDATE OR DELETE ON featureprop_pub
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_featureprop_pub ();


   DROP TABLE audit_feature_dbxref;
   CREATE TABLE audit_feature_dbxref ( 
       feature_dbxref_id integer, 
       feature_id integer, 
       dbxref_id integer, 
       is_current boolean, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_feature_dbxref to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_feature_dbxref() RETURNS trigger AS
   '
   DECLARE
       feature_dbxref_id_var integer; 
       feature_id_var integer; 
       dbxref_id_var integer; 
       is_current_var boolean; 
       
       transaction_type_var char;
   BEGIN
       feature_dbxref_id_var = OLD.feature_dbxref_id;
       feature_id_var = OLD.feature_id;
       dbxref_id_var = OLD.dbxref_id;
       is_current_var = OLD.is_current;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_feature_dbxref ( 
             feature_dbxref_id, 
             feature_id, 
             dbxref_id, 
             is_current, 
             transaction_type
       ) VALUES ( 
             feature_dbxref_id_var, 
             feature_id_var, 
             dbxref_id_var, 
             is_current_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER feature_dbxref_audit_ud ON feature_dbxref;
   CREATE TRIGGER feature_dbxref_audit_ud
       BEFORE UPDATE OR DELETE ON feature_dbxref
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_feature_dbxref ();


   DROP TABLE audit_feature_relationship;
   CREATE TABLE audit_feature_relationship ( 
       feature_relationship_id integer, 
       subject_id integer, 
       object_id integer, 
       type_id integer, 
       value text, 
       rank integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_feature_relationship to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_feature_relationship() RETURNS trigger AS
   '
   DECLARE
       feature_relationship_id_var integer; 
       subject_id_var integer; 
       object_id_var integer; 
       type_id_var integer; 
       value_var text; 
       rank_var integer; 
       
       transaction_type_var char;
   BEGIN
       feature_relationship_id_var = OLD.feature_relationship_id;
       subject_id_var = OLD.subject_id;
       object_id_var = OLD.object_id;
       type_id_var = OLD.type_id;
       value_var = OLD.value;
       rank_var = OLD.rank;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_feature_relationship ( 
             feature_relationship_id, 
             subject_id, 
             object_id, 
             type_id, 
             value, 
             rank, 
             transaction_type
       ) VALUES ( 
             feature_relationship_id_var, 
             subject_id_var, 
             object_id_var, 
             type_id_var, 
             value_var, 
             rank_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER feature_relationship_audit_ud ON feature_relationship;
   CREATE TRIGGER feature_relationship_audit_ud
       BEFORE UPDATE OR DELETE ON feature_relationship
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_feature_relationship ();


   DROP TABLE audit_feature_relationship_pub;
   CREATE TABLE audit_feature_relationship_pub ( 
       feature_relationship_pub_id integer, 
       feature_relationship_id integer, 
       pub_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_feature_relationship_pub to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_feature_relationship_pub() RETURNS trigger AS
   '
   DECLARE
       feature_relationship_pub_id_var integer; 
       feature_relationship_id_var integer; 
       pub_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       feature_relationship_pub_id_var = OLD.feature_relationship_pub_id;
       feature_relationship_id_var = OLD.feature_relationship_id;
       pub_id_var = OLD.pub_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_feature_relationship_pub ( 
             feature_relationship_pub_id, 
             feature_relationship_id, 
             pub_id, 
             transaction_type
       ) VALUES ( 
             feature_relationship_pub_id_var, 
             feature_relationship_id_var, 
             pub_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER feature_relationship_pub_audit_ud ON feature_relationship_pub;
   CREATE TRIGGER feature_relationship_pub_audit_ud
       BEFORE UPDATE OR DELETE ON feature_relationship_pub
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_feature_relationship_pub ();


   DROP TABLE audit_feature_relationshipprop;
   CREATE TABLE audit_feature_relationshipprop ( 
       feature_relationshipprop_id integer, 
       feature_relationship_id integer, 
       type_id integer, 
       value text, 
       rank integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_feature_relationshipprop to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_feature_relationshipprop() RETURNS trigger AS
   '
   DECLARE
       feature_relationshipprop_id_var integer; 
       feature_relationship_id_var integer; 
       type_id_var integer; 
       value_var text; 
       rank_var integer; 
       
       transaction_type_var char;
   BEGIN
       feature_relationshipprop_id_var = OLD.feature_relationshipprop_id;
       feature_relationship_id_var = OLD.feature_relationship_id;
       type_id_var = OLD.type_id;
       value_var = OLD.value;
       rank_var = OLD.rank;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_feature_relationshipprop ( 
             feature_relationshipprop_id, 
             feature_relationship_id, 
             type_id, 
             value, 
             rank, 
             transaction_type
       ) VALUES ( 
             feature_relationshipprop_id_var, 
             feature_relationship_id_var, 
             type_id_var, 
             value_var, 
             rank_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER feature_relationshipprop_audit_ud ON feature_relationshipprop;
   CREATE TRIGGER feature_relationshipprop_audit_ud
       BEFORE UPDATE OR DELETE ON feature_relationshipprop
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_feature_relationshipprop ();


   DROP TABLE audit_feature_relationshipprop_pub;
   CREATE TABLE audit_feature_relationshipprop_pub ( 
       feature_relationshipprop_pub_id integer, 
       feature_relationshipprop_id integer, 
       pub_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_feature_relationshipprop_pub to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_feature_relationshipprop_pub() RETURNS trigger AS
   '
   DECLARE
       feature_relationshipprop_pub_id_var integer; 
       feature_relationshipprop_id_var integer; 
       pub_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       feature_relationshipprop_pub_id_var = OLD.feature_relationshipprop_pub_id;
       feature_relationshipprop_id_var = OLD.feature_relationshipprop_id;
       pub_id_var = OLD.pub_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_feature_relationshipprop_pub ( 
             feature_relationshipprop_pub_id, 
             feature_relationshipprop_id, 
             pub_id, 
             transaction_type
       ) VALUES ( 
             feature_relationshipprop_pub_id_var, 
             feature_relationshipprop_id_var, 
             pub_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER feature_relationshipprop_pub_audit_ud ON feature_relationshipprop_pub;
   CREATE TRIGGER feature_relationshipprop_pub_audit_ud
       BEFORE UPDATE OR DELETE ON feature_relationshipprop_pub
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_feature_relationshipprop_pub ();


   DROP TABLE audit_feature_cvterm;
   CREATE TABLE audit_feature_cvterm ( 
       feature_cvterm_id integer, 
       feature_id integer, 
       cvterm_id integer, 
       pub_id integer, 
       is_not boolean, 
       rank integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_feature_cvterm to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_feature_cvterm() RETURNS trigger AS
   '
   DECLARE
       feature_cvterm_id_var integer; 
       feature_id_var integer; 
       cvterm_id_var integer; 
       pub_id_var integer; 
       is_not_var boolean; 
       rank_var integer; 
       
       transaction_type_var char;
   BEGIN
       feature_cvterm_id_var = OLD.feature_cvterm_id;
       feature_id_var = OLD.feature_id;
       cvterm_id_var = OLD.cvterm_id;
       pub_id_var = OLD.pub_id;
       is_not_var = OLD.is_not;
       rank_var = OLD.rank;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_feature_cvterm ( 
             feature_cvterm_id, 
             feature_id, 
             cvterm_id, 
             pub_id, 
             is_not, 
             rank, 
             transaction_type
       ) VALUES ( 
             feature_cvterm_id_var, 
             feature_id_var, 
             cvterm_id_var, 
             pub_id_var, 
             is_not_var, 
             rank_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER feature_cvterm_audit_ud ON feature_cvterm;
   CREATE TRIGGER feature_cvterm_audit_ud
       BEFORE UPDATE OR DELETE ON feature_cvterm
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_feature_cvterm ();


   DROP TABLE audit_feature_cvtermprop;
   CREATE TABLE audit_feature_cvtermprop ( 
       feature_cvtermprop_id integer, 
       feature_cvterm_id integer, 
       type_id integer, 
       value text, 
       rank integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_feature_cvtermprop to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_feature_cvtermprop() RETURNS trigger AS
   '
   DECLARE
       feature_cvtermprop_id_var integer; 
       feature_cvterm_id_var integer; 
       type_id_var integer; 
       value_var text; 
       rank_var integer; 
       
       transaction_type_var char;
   BEGIN
       feature_cvtermprop_id_var = OLD.feature_cvtermprop_id;
       feature_cvterm_id_var = OLD.feature_cvterm_id;
       type_id_var = OLD.type_id;
       value_var = OLD.value;
       rank_var = OLD.rank;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_feature_cvtermprop ( 
             feature_cvtermprop_id, 
             feature_cvterm_id, 
             type_id, 
             value, 
             rank, 
             transaction_type
       ) VALUES ( 
             feature_cvtermprop_id_var, 
             feature_cvterm_id_var, 
             type_id_var, 
             value_var, 
             rank_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER feature_cvtermprop_audit_ud ON feature_cvtermprop;
   CREATE TRIGGER feature_cvtermprop_audit_ud
       BEFORE UPDATE OR DELETE ON feature_cvtermprop
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_feature_cvtermprop ();


   DROP TABLE audit_feature_cvterm_dbxref;
   CREATE TABLE audit_feature_cvterm_dbxref ( 
       feature_cvterm_dbxref_id integer, 
       feature_cvterm_id integer, 
       dbxref_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_feature_cvterm_dbxref to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_feature_cvterm_dbxref() RETURNS trigger AS
   '
   DECLARE
       feature_cvterm_dbxref_id_var integer; 
       feature_cvterm_id_var integer; 
       dbxref_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       feature_cvterm_dbxref_id_var = OLD.feature_cvterm_dbxref_id;
       feature_cvterm_id_var = OLD.feature_cvterm_id;
       dbxref_id_var = OLD.dbxref_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_feature_cvterm_dbxref ( 
             feature_cvterm_dbxref_id, 
             feature_cvterm_id, 
             dbxref_id, 
             transaction_type
       ) VALUES ( 
             feature_cvterm_dbxref_id_var, 
             feature_cvterm_id_var, 
             dbxref_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER feature_cvterm_dbxref_audit_ud ON feature_cvterm_dbxref;
   CREATE TRIGGER feature_cvterm_dbxref_audit_ud
       BEFORE UPDATE OR DELETE ON feature_cvterm_dbxref
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_feature_cvterm_dbxref ();


   DROP TABLE audit_feature_cvterm_pub;
   CREATE TABLE audit_feature_cvterm_pub ( 
       feature_cvterm_pub_id integer, 
       feature_cvterm_id integer, 
       pub_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_feature_cvterm_pub to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_feature_cvterm_pub() RETURNS trigger AS
   '
   DECLARE
       feature_cvterm_pub_id_var integer; 
       feature_cvterm_id_var integer; 
       pub_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       feature_cvterm_pub_id_var = OLD.feature_cvterm_pub_id;
       feature_cvterm_id_var = OLD.feature_cvterm_id;
       pub_id_var = OLD.pub_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_feature_cvterm_pub ( 
             feature_cvterm_pub_id, 
             feature_cvterm_id, 
             pub_id, 
             transaction_type
       ) VALUES ( 
             feature_cvterm_pub_id_var, 
             feature_cvterm_id_var, 
             pub_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER feature_cvterm_pub_audit_ud ON feature_cvterm_pub;
   CREATE TRIGGER feature_cvterm_pub_audit_ud
       BEFORE UPDATE OR DELETE ON feature_cvterm_pub
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_feature_cvterm_pub ();


   DROP TABLE audit_synonym;
   CREATE TABLE audit_synonym ( 
       synonym_id integer, 
       name varchar(255), 
       type_id integer, 
       synonym_sgml varchar(255), 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_synonym to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_synonym() RETURNS trigger AS
   '
   DECLARE
       synonym_id_var integer; 
       name_var varchar(255); 
       type_id_var integer; 
       synonym_sgml_var varchar(255); 
       
       transaction_type_var char;
   BEGIN
       synonym_id_var = OLD.synonym_id;
       name_var = OLD.name;
       type_id_var = OLD.type_id;
       synonym_sgml_var = OLD.synonym_sgml;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_synonym ( 
             synonym_id, 
             name, 
             type_id, 
             synonym_sgml, 
             transaction_type
       ) VALUES ( 
             synonym_id_var, 
             name_var, 
             type_id_var, 
             synonym_sgml_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER synonym_audit_ud ON synonym;
   CREATE TRIGGER synonym_audit_ud
       BEFORE UPDATE OR DELETE ON synonym
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_synonym ();


   DROP TABLE audit_feature_synonym;
   CREATE TABLE audit_feature_synonym ( 
       feature_synonym_id integer, 
       synonym_id integer, 
       feature_id integer, 
       pub_id integer, 
       is_current boolean, 
       is_internal boolean, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_feature_synonym to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_feature_synonym() RETURNS trigger AS
   '
   DECLARE
       feature_synonym_id_var integer; 
       synonym_id_var integer; 
       feature_id_var integer; 
       pub_id_var integer; 
       is_current_var boolean; 
       is_internal_var boolean; 
       
       transaction_type_var char;
   BEGIN
       feature_synonym_id_var = OLD.feature_synonym_id;
       synonym_id_var = OLD.synonym_id;
       feature_id_var = OLD.feature_id;
       pub_id_var = OLD.pub_id;
       is_current_var = OLD.is_current;
       is_internal_var = OLD.is_internal;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_feature_synonym ( 
             feature_synonym_id, 
             synonym_id, 
             feature_id, 
             pub_id, 
             is_current, 
             is_internal, 
             transaction_type
       ) VALUES ( 
             feature_synonym_id_var, 
             synonym_id_var, 
             feature_id_var, 
             pub_id_var, 
             is_current_var, 
             is_internal_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER feature_synonym_audit_ud ON feature_synonym;
   CREATE TRIGGER feature_synonym_audit_ud
       BEFORE UPDATE OR DELETE ON feature_synonym
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_feature_synonym ();


   DROP TABLE audit_gencode;
   CREATE TABLE audit_gencode ( 
       gencode_id integer, 
       organismstr VARCHAR, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_gencode to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_gencode() RETURNS trigger AS
   '
   DECLARE
       gencode_id_var integer; 
       organismstr_var VARCHAR; 
       
       transaction_type_var char;
   BEGIN
       gencode_id_var = OLD.gencode_id;
       organismstr_var = OLD.organismstr;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_gencode ( 
             gencode_id, 
             organismstr, 
             transaction_type
       ) VALUES ( 
             gencode_id_var, 
             organismstr_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER gencode_audit_ud ON gencode;
   CREATE TRIGGER gencode_audit_ud
       BEFORE UPDATE OR DELETE ON gencode
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_gencode ();


   DROP TABLE audit_gencode_codon_aa;
   CREATE TABLE audit_gencode_codon_aa ( 
       gencode_id integer, 
       codon char(3), 
       aa char(1), 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_gencode_codon_aa to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_gencode_codon_aa() RETURNS trigger AS
   '
   DECLARE
       gencode_id_var integer; 
       codon_var char(3); 
       aa_var char(1); 
       
       transaction_type_var char;
   BEGIN
       gencode_id_var = OLD.gencode_id;
       codon_var = OLD.codon;
       aa_var = OLD.aa;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_gencode_codon_aa ( 
             gencode_id, 
             codon, 
             aa, 
             transaction_type
       ) VALUES ( 
             gencode_id_var, 
             codon_var, 
             aa_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER gencode_codon_aa_audit_ud ON gencode_codon_aa;
   CREATE TRIGGER gencode_codon_aa_audit_ud
       BEFORE UPDATE OR DELETE ON gencode_codon_aa
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_gencode_codon_aa ();


   DROP TABLE audit_gencode_startcodon;
   CREATE TABLE audit_gencode_startcodon ( 
       gencode_id integer, 
       codon char(3), 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_gencode_startcodon to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_gencode_startcodon() RETURNS trigger AS
   '
   DECLARE
       gencode_id_var integer; 
       codon_var char(3); 
       
       transaction_type_var char;
   BEGIN
       gencode_id_var = OLD.gencode_id;
       codon_var = OLD.codon;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_gencode_startcodon ( 
             gencode_id, 
             codon, 
             transaction_type
       ) VALUES ( 
             gencode_id_var, 
             codon_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER gencode_startcodon_audit_ud ON gencode_startcodon;
   CREATE TRIGGER gencode_startcodon_audit_ud
       BEFORE UPDATE OR DELETE ON gencode_startcodon
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_gencode_startcodon ();


   DROP TABLE audit_analysis;
   CREATE TABLE audit_analysis ( 
       analysis_id integer, 
       name varchar(255), 
       description text, 
       program varchar(255), 
       programversion varchar(255), 
       algorithm varchar(255), 
       sourcename varchar(255), 
       sourceversion varchar(255), 
       sourceuri text, 
       timeexecuted timestamp, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_analysis to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_analysis() RETURNS trigger AS
   '
   DECLARE
       analysis_id_var integer; 
       name_var varchar(255); 
       description_var text; 
       program_var varchar(255); 
       programversion_var varchar(255); 
       algorithm_var varchar(255); 
       sourcename_var varchar(255); 
       sourceversion_var varchar(255); 
       sourceuri_var text; 
       timeexecuted_var timestamp; 
       
       transaction_type_var char;
   BEGIN
       analysis_id_var = OLD.analysis_id;
       name_var = OLD.name;
       description_var = OLD.description;
       program_var = OLD.program;
       programversion_var = OLD.programversion;
       algorithm_var = OLD.algorithm;
       sourcename_var = OLD.sourcename;
       sourceversion_var = OLD.sourceversion;
       sourceuri_var = OLD.sourceuri;
       timeexecuted_var = OLD.timeexecuted;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_analysis ( 
             analysis_id, 
             name, 
             description, 
             program, 
             programversion, 
             algorithm, 
             sourcename, 
             sourceversion, 
             sourceuri, 
             timeexecuted, 
             transaction_type
       ) VALUES ( 
             analysis_id_var, 
             name_var, 
             description_var, 
             program_var, 
             programversion_var, 
             algorithm_var, 
             sourcename_var, 
             sourceversion_var, 
             sourceuri_var, 
             timeexecuted_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER analysis_audit_ud ON analysis;
   CREATE TRIGGER analysis_audit_ud
       BEFORE UPDATE OR DELETE ON analysis
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_analysis ();


   DROP TABLE audit_analysisprop;
   CREATE TABLE audit_analysisprop ( 
       analysisprop_id integer, 
       analysis_id integer, 
       type_id integer, 
       value text, 
       rank integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_analysisprop to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_analysisprop() RETURNS trigger AS
   '
   DECLARE
       analysisprop_id_var integer; 
       analysis_id_var integer; 
       type_id_var integer; 
       value_var text; 
       rank_var integer; 
       
       transaction_type_var char;
   BEGIN
       analysisprop_id_var = OLD.analysisprop_id;
       analysis_id_var = OLD.analysis_id;
       type_id_var = OLD.type_id;
       value_var = OLD.value;
       rank_var = OLD.rank;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_analysisprop ( 
             analysisprop_id, 
             analysis_id, 
             type_id, 
             value, 
             rank, 
             transaction_type
       ) VALUES ( 
             analysisprop_id_var, 
             analysis_id_var, 
             type_id_var, 
             value_var, 
             rank_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER analysisprop_audit_ud ON analysisprop;
   CREATE TRIGGER analysisprop_audit_ud
       BEFORE UPDATE OR DELETE ON analysisprop
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_analysisprop ();


   DROP TABLE audit_analysisfeature;
   CREATE TABLE audit_analysisfeature ( 
       analysisfeature_id integer, 
       feature_id integer, 
       analysis_id integer, 
       rawscore float, 
       normscore float, 
       significance float, 
       identity float, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_analysisfeature to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_analysisfeature() RETURNS trigger AS
   '
   DECLARE
       analysisfeature_id_var integer; 
       feature_id_var integer; 
       analysis_id_var integer; 
       rawscore_var float; 
       normscore_var float; 
       significance_var float; 
       identity_var float; 
       
       transaction_type_var char;
   BEGIN
       analysisfeature_id_var = OLD.analysisfeature_id;
       feature_id_var = OLD.feature_id;
       analysis_id_var = OLD.analysis_id;
       rawscore_var = OLD.rawscore;
       normscore_var = OLD.normscore;
       significance_var = OLD.significance;
       identity_var = OLD.identity;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_analysisfeature ( 
             analysisfeature_id, 
             feature_id, 
             analysis_id, 
             rawscore, 
             normscore, 
             significance, 
             identity, 
             transaction_type
       ) VALUES ( 
             analysisfeature_id_var, 
             feature_id_var, 
             analysis_id_var, 
             rawscore_var, 
             normscore_var, 
             significance_var, 
             identity_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER analysisfeature_audit_ud ON analysisfeature;
   CREATE TRIGGER analysisfeature_audit_ud
       BEFORE UPDATE OR DELETE ON analysisfeature
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_analysisfeature ();


   DROP TABLE audit_analysisfeatureprop;
   CREATE TABLE audit_analysisfeatureprop ( 
       analysisfeatureprop_id integer, 
       analysisfeature_id integer, 
       type_id integer, 
       value text, 
       rank integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_analysisfeatureprop to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_analysisfeatureprop() RETURNS trigger AS
   '
   DECLARE
       analysisfeatureprop_id_var integer; 
       analysisfeature_id_var integer; 
       type_id_var integer; 
       value_var text; 
       rank_var integer; 
       
       transaction_type_var char;
   BEGIN
       analysisfeatureprop_id_var = OLD.analysisfeatureprop_id;
       analysisfeature_id_var = OLD.analysisfeature_id;
       type_id_var = OLD.type_id;
       value_var = OLD.value;
       rank_var = OLD.rank;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_analysisfeatureprop ( 
             analysisfeatureprop_id, 
             analysisfeature_id, 
             type_id, 
             value, 
             rank, 
             transaction_type
       ) VALUES ( 
             analysisfeatureprop_id_var, 
             analysisfeature_id_var, 
             type_id_var, 
             value_var, 
             rank_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER analysisfeatureprop_audit_ud ON analysisfeatureprop;
   CREATE TRIGGER analysisfeatureprop_audit_ud
       BEFORE UPDATE OR DELETE ON analysisfeatureprop
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_analysisfeatureprop ();


   DROP TABLE audit_phenotype;
   CREATE TABLE audit_phenotype ( 
       phenotype_id integer, 
       uniquename text, 
       observable_id integer, 
       attr_id integer, 
       value text, 
       cvalue_id integer, 
       assay_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_phenotype to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_phenotype() RETURNS trigger AS
   '
   DECLARE
       phenotype_id_var integer; 
       uniquename_var text; 
       observable_id_var integer; 
       attr_id_var integer; 
       value_var text; 
       cvalue_id_var integer; 
       assay_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       phenotype_id_var = OLD.phenotype_id;
       uniquename_var = OLD.uniquename;
       observable_id_var = OLD.observable_id;
       attr_id_var = OLD.attr_id;
       value_var = OLD.value;
       cvalue_id_var = OLD.cvalue_id;
       assay_id_var = OLD.assay_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_phenotype ( 
             phenotype_id, 
             uniquename, 
             observable_id, 
             attr_id, 
             value, 
             cvalue_id, 
             assay_id, 
             transaction_type
       ) VALUES ( 
             phenotype_id_var, 
             uniquename_var, 
             observable_id_var, 
             attr_id_var, 
             value_var, 
             cvalue_id_var, 
             assay_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER phenotype_audit_ud ON phenotype;
   CREATE TRIGGER phenotype_audit_ud
       BEFORE UPDATE OR DELETE ON phenotype
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_phenotype ();


   DROP TABLE audit_phenotype_cvterm;
   CREATE TABLE audit_phenotype_cvterm ( 
       phenotype_cvterm_id integer, 
       phenotype_id integer, 
       cvterm_id integer, 
       rank integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_phenotype_cvterm to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_phenotype_cvterm() RETURNS trigger AS
   '
   DECLARE
       phenotype_cvterm_id_var integer; 
       phenotype_id_var integer; 
       cvterm_id_var integer; 
       rank_var integer; 
       
       transaction_type_var char;
   BEGIN
       phenotype_cvterm_id_var = OLD.phenotype_cvterm_id;
       phenotype_id_var = OLD.phenotype_id;
       cvterm_id_var = OLD.cvterm_id;
       rank_var = OLD.rank;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_phenotype_cvterm ( 
             phenotype_cvterm_id, 
             phenotype_id, 
             cvterm_id, 
             rank, 
             transaction_type
       ) VALUES ( 
             phenotype_cvterm_id_var, 
             phenotype_id_var, 
             cvterm_id_var, 
             rank_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER phenotype_cvterm_audit_ud ON phenotype_cvterm;
   CREATE TRIGGER phenotype_cvterm_audit_ud
       BEFORE UPDATE OR DELETE ON phenotype_cvterm
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_phenotype_cvterm ();


   DROP TABLE audit_feature_phenotype;
   CREATE TABLE audit_feature_phenotype ( 
       feature_phenotype_id integer, 
       feature_id integer, 
       phenotype_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_feature_phenotype to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_feature_phenotype() RETURNS trigger AS
   '
   DECLARE
       feature_phenotype_id_var integer; 
       feature_id_var integer; 
       phenotype_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       feature_phenotype_id_var = OLD.feature_phenotype_id;
       feature_id_var = OLD.feature_id;
       phenotype_id_var = OLD.phenotype_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_feature_phenotype ( 
             feature_phenotype_id, 
             feature_id, 
             phenotype_id, 
             transaction_type
       ) VALUES ( 
             feature_phenotype_id_var, 
             feature_id_var, 
             phenotype_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER feature_phenotype_audit_ud ON feature_phenotype;
   CREATE TRIGGER feature_phenotype_audit_ud
       BEFORE UPDATE OR DELETE ON feature_phenotype
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_feature_phenotype ();


   DROP TABLE audit_genotype;
   CREATE TABLE audit_genotype ( 
       genotype_id integer, 
       name text, 
       uniquename text, 
       description varchar(255), 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_genotype to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_genotype() RETURNS trigger AS
   '
   DECLARE
       genotype_id_var integer; 
       name_var text; 
       uniquename_var text; 
       description_var varchar(255); 
       
       transaction_type_var char;
   BEGIN
       genotype_id_var = OLD.genotype_id;
       name_var = OLD.name;
       uniquename_var = OLD.uniquename;
       description_var = OLD.description;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_genotype ( 
             genotype_id, 
             name, 
             uniquename, 
             description, 
             transaction_type
       ) VALUES ( 
             genotype_id_var, 
             name_var, 
             uniquename_var, 
             description_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER genotype_audit_ud ON genotype;
   CREATE TRIGGER genotype_audit_ud
       BEFORE UPDATE OR DELETE ON genotype
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_genotype ();


   DROP TABLE audit_feature_genotype;
   CREATE TABLE audit_feature_genotype ( 
       feature_genotype_id integer, 
       feature_id integer, 
       genotype_id integer, 
       chromosome_id integer, 
       rank integer, 
       cgroup integer, 
       cvterm_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_feature_genotype to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_feature_genotype() RETURNS trigger AS
   '
   DECLARE
       feature_genotype_id_var integer; 
       feature_id_var integer; 
       genotype_id_var integer; 
       chromosome_id_var integer; 
       rank_var integer; 
       cgroup_var integer; 
       cvterm_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       feature_genotype_id_var = OLD.feature_genotype_id;
       feature_id_var = OLD.feature_id;
       genotype_id_var = OLD.genotype_id;
       chromosome_id_var = OLD.chromosome_id;
       rank_var = OLD.rank;
       cgroup_var = OLD.cgroup;
       cvterm_id_var = OLD.cvterm_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_feature_genotype ( 
             feature_genotype_id, 
             feature_id, 
             genotype_id, 
             chromosome_id, 
             rank, 
             cgroup, 
             cvterm_id, 
             transaction_type
       ) VALUES ( 
             feature_genotype_id_var, 
             feature_id_var, 
             genotype_id_var, 
             chromosome_id_var, 
             rank_var, 
             cgroup_var, 
             cvterm_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER feature_genotype_audit_ud ON feature_genotype;
   CREATE TRIGGER feature_genotype_audit_ud
       BEFORE UPDATE OR DELETE ON feature_genotype
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_feature_genotype ();


   DROP TABLE audit_environment;
   CREATE TABLE audit_environment ( 
       environment_id integer, 
       uniquename text, 
       description text, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_environment to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_environment() RETURNS trigger AS
   '
   DECLARE
       environment_id_var integer; 
       uniquename_var text; 
       description_var text; 
       
       transaction_type_var char;
   BEGIN
       environment_id_var = OLD.environment_id;
       uniquename_var = OLD.uniquename;
       description_var = OLD.description;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_environment ( 
             environment_id, 
             uniquename, 
             description, 
             transaction_type
       ) VALUES ( 
             environment_id_var, 
             uniquename_var, 
             description_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER environment_audit_ud ON environment;
   CREATE TRIGGER environment_audit_ud
       BEFORE UPDATE OR DELETE ON environment
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_environment ();


   DROP TABLE audit_environment_cvterm;
   CREATE TABLE audit_environment_cvterm ( 
       environment_cvterm_id integer, 
       environment_id integer, 
       cvterm_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_environment_cvterm to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_environment_cvterm() RETURNS trigger AS
   '
   DECLARE
       environment_cvterm_id_var integer; 
       environment_id_var integer; 
       cvterm_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       environment_cvterm_id_var = OLD.environment_cvterm_id;
       environment_id_var = OLD.environment_id;
       cvterm_id_var = OLD.cvterm_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_environment_cvterm ( 
             environment_cvterm_id, 
             environment_id, 
             cvterm_id, 
             transaction_type
       ) VALUES ( 
             environment_cvterm_id_var, 
             environment_id_var, 
             cvterm_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER environment_cvterm_audit_ud ON environment_cvterm;
   CREATE TRIGGER environment_cvterm_audit_ud
       BEFORE UPDATE OR DELETE ON environment_cvterm
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_environment_cvterm ();


   DROP TABLE audit_phenstatement;
   CREATE TABLE audit_phenstatement ( 
       phenstatement_id integer, 
       genotype_id integer, 
       environment_id integer, 
       phenotype_id integer, 
       type_id integer, 
       pub_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_phenstatement to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_phenstatement() RETURNS trigger AS
   '
   DECLARE
       phenstatement_id_var integer; 
       genotype_id_var integer; 
       environment_id_var integer; 
       phenotype_id_var integer; 
       type_id_var integer; 
       pub_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       phenstatement_id_var = OLD.phenstatement_id;
       genotype_id_var = OLD.genotype_id;
       environment_id_var = OLD.environment_id;
       phenotype_id_var = OLD.phenotype_id;
       type_id_var = OLD.type_id;
       pub_id_var = OLD.pub_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_phenstatement ( 
             phenstatement_id, 
             genotype_id, 
             environment_id, 
             phenotype_id, 
             type_id, 
             pub_id, 
             transaction_type
       ) VALUES ( 
             phenstatement_id_var, 
             genotype_id_var, 
             environment_id_var, 
             phenotype_id_var, 
             type_id_var, 
             pub_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER phenstatement_audit_ud ON phenstatement;
   CREATE TRIGGER phenstatement_audit_ud
       BEFORE UPDATE OR DELETE ON phenstatement
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_phenstatement ();


   DROP TABLE audit_phendesc;
   CREATE TABLE audit_phendesc ( 
       phendesc_id integer, 
       genotype_id integer, 
       environment_id integer, 
       description text, 
       type_id integer, 
       pub_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_phendesc to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_phendesc() RETURNS trigger AS
   '
   DECLARE
       phendesc_id_var integer; 
       genotype_id_var integer; 
       environment_id_var integer; 
       description_var text; 
       type_id_var integer; 
       pub_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       phendesc_id_var = OLD.phendesc_id;
       genotype_id_var = OLD.genotype_id;
       environment_id_var = OLD.environment_id;
       description_var = OLD.description;
       type_id_var = OLD.type_id;
       pub_id_var = OLD.pub_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_phendesc ( 
             phendesc_id, 
             genotype_id, 
             environment_id, 
             description, 
             type_id, 
             pub_id, 
             transaction_type
       ) VALUES ( 
             phendesc_id_var, 
             genotype_id_var, 
             environment_id_var, 
             description_var, 
             type_id_var, 
             pub_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER phendesc_audit_ud ON phendesc;
   CREATE TRIGGER phendesc_audit_ud
       BEFORE UPDATE OR DELETE ON phendesc
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_phendesc ();


   DROP TABLE audit_phenotype_comparison;
   CREATE TABLE audit_phenotype_comparison ( 
       phenotype_comparison_id integer, 
       genotype1_id integer, 
       environment1_id integer, 
       genotype2_id integer, 
       environment2_id integer, 
       phenotype1_id integer, 
       phenotype2_id integer, 
       pub_id integer, 
       organism_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_phenotype_comparison to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_phenotype_comparison() RETURNS trigger AS
   '
   DECLARE
       phenotype_comparison_id_var integer; 
       genotype1_id_var integer; 
       environment1_id_var integer; 
       genotype2_id_var integer; 
       environment2_id_var integer; 
       phenotype1_id_var integer; 
       phenotype2_id_var integer; 
       pub_id_var integer; 
       organism_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       phenotype_comparison_id_var = OLD.phenotype_comparison_id;
       genotype1_id_var = OLD.genotype1_id;
       environment1_id_var = OLD.environment1_id;
       genotype2_id_var = OLD.genotype2_id;
       environment2_id_var = OLD.environment2_id;
       phenotype1_id_var = OLD.phenotype1_id;
       phenotype2_id_var = OLD.phenotype2_id;
       pub_id_var = OLD.pub_id;
       organism_id_var = OLD.organism_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_phenotype_comparison ( 
             phenotype_comparison_id, 
             genotype1_id, 
             environment1_id, 
             genotype2_id, 
             environment2_id, 
             phenotype1_id, 
             phenotype2_id, 
             pub_id, 
             organism_id, 
             transaction_type
       ) VALUES ( 
             phenotype_comparison_id_var, 
             genotype1_id_var, 
             environment1_id_var, 
             genotype2_id_var, 
             environment2_id_var, 
             phenotype1_id_var, 
             phenotype2_id_var, 
             pub_id_var, 
             organism_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER phenotype_comparison_audit_ud ON phenotype_comparison;
   CREATE TRIGGER phenotype_comparison_audit_ud
       BEFORE UPDATE OR DELETE ON phenotype_comparison
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_phenotype_comparison ();


   DROP TABLE audit_phenotype_comparison_cvterm;
   CREATE TABLE audit_phenotype_comparison_cvterm ( 
       phenotype_comparison_cvterm_id integer, 
       phenotype_comparison_id integer, 
       cvterm_id integer, 
       pub_id integer, 
       rank integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_phenotype_comparison_cvterm to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_phenotype_comparison_cvterm() RETURNS trigger AS
   '
   DECLARE
       phenotype_comparison_cvterm_id_var integer; 
       phenotype_comparison_id_var integer; 
       cvterm_id_var integer; 
       pub_id_var integer; 
       rank_var integer; 
       
       transaction_type_var char;
   BEGIN
       phenotype_comparison_cvterm_id_var = OLD.phenotype_comparison_cvterm_id;
       phenotype_comparison_id_var = OLD.phenotype_comparison_id;
       cvterm_id_var = OLD.cvterm_id;
       pub_id_var = OLD.pub_id;
       rank_var = OLD.rank;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_phenotype_comparison_cvterm ( 
             phenotype_comparison_cvterm_id, 
             phenotype_comparison_id, 
             cvterm_id, 
             pub_id, 
             rank, 
             transaction_type
       ) VALUES ( 
             phenotype_comparison_cvterm_id_var, 
             phenotype_comparison_id_var, 
             cvterm_id_var, 
             pub_id_var, 
             rank_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER phenotype_comparison_cvterm_audit_ud ON phenotype_comparison_cvterm;
   CREATE TRIGGER phenotype_comparison_cvterm_audit_ud
       BEFORE UPDATE OR DELETE ON phenotype_comparison_cvterm
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_phenotype_comparison_cvterm ();


   DROP TABLE audit_featuremap;
   CREATE TABLE audit_featuremap ( 
       featuremap_id integer, 
       name varchar(255), 
       description text, 
       unittype_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_featuremap to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_featuremap() RETURNS trigger AS
   '
   DECLARE
       featuremap_id_var integer; 
       name_var varchar(255); 
       description_var text; 
       unittype_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       featuremap_id_var = OLD.featuremap_id;
       name_var = OLD.name;
       description_var = OLD.description;
       unittype_id_var = OLD.unittype_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_featuremap ( 
             featuremap_id, 
             name, 
             description, 
             unittype_id, 
             transaction_type
       ) VALUES ( 
             featuremap_id_var, 
             name_var, 
             description_var, 
             unittype_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER featuremap_audit_ud ON featuremap;
   CREATE TRIGGER featuremap_audit_ud
       BEFORE UPDATE OR DELETE ON featuremap
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_featuremap ();


   DROP TABLE audit_featurerange;
   CREATE TABLE audit_featurerange ( 
       featurerange_id integer, 
       featuremap_id integer, 
       feature_id integer, 
       leftstartf_id integer, 
       leftendf_id integer, 
       rightstartf_id integer, 
       rightendf_id integer, 
       rangestr varchar(255), 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_featurerange to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_featurerange() RETURNS trigger AS
   '
   DECLARE
       featurerange_id_var integer; 
       featuremap_id_var integer; 
       feature_id_var integer; 
       leftstartf_id_var integer; 
       leftendf_id_var integer; 
       rightstartf_id_var integer; 
       rightendf_id_var integer; 
       rangestr_var varchar(255); 
       
       transaction_type_var char;
   BEGIN
       featurerange_id_var = OLD.featurerange_id;
       featuremap_id_var = OLD.featuremap_id;
       feature_id_var = OLD.feature_id;
       leftstartf_id_var = OLD.leftstartf_id;
       leftendf_id_var = OLD.leftendf_id;
       rightstartf_id_var = OLD.rightstartf_id;
       rightendf_id_var = OLD.rightendf_id;
       rangestr_var = OLD.rangestr;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_featurerange ( 
             featurerange_id, 
             featuremap_id, 
             feature_id, 
             leftstartf_id, 
             leftendf_id, 
             rightstartf_id, 
             rightendf_id, 
             rangestr, 
             transaction_type
       ) VALUES ( 
             featurerange_id_var, 
             featuremap_id_var, 
             feature_id_var, 
             leftstartf_id_var, 
             leftendf_id_var, 
             rightstartf_id_var, 
             rightendf_id_var, 
             rangestr_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER featurerange_audit_ud ON featurerange;
   CREATE TRIGGER featurerange_audit_ud
       BEFORE UPDATE OR DELETE ON featurerange
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_featurerange ();


   DROP TABLE audit_featurepos;
   CREATE TABLE audit_featurepos ( 
       featurepos_id integer, 
       featuremap_id integer, 
       feature_id integer, 
       map_feature_id integer, 
       mappos float, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_featurepos to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_featurepos() RETURNS trigger AS
   '
   DECLARE
       featurepos_id_var integer; 
       featuremap_id_var integer; 
       feature_id_var integer; 
       map_feature_id_var integer; 
       mappos_var float; 
       
       transaction_type_var char;
   BEGIN
       featurepos_id_var = OLD.featurepos_id;
       featuremap_id_var = OLD.featuremap_id;
       feature_id_var = OLD.feature_id;
       map_feature_id_var = OLD.map_feature_id;
       mappos_var = OLD.mappos;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_featurepos ( 
             featurepos_id, 
             featuremap_id, 
             feature_id, 
             map_feature_id, 
             mappos, 
             transaction_type
       ) VALUES ( 
             featurepos_id_var, 
             featuremap_id_var, 
             feature_id_var, 
             map_feature_id_var, 
             mappos_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER featurepos_audit_ud ON featurepos;
   CREATE TRIGGER featurepos_audit_ud
       BEFORE UPDATE OR DELETE ON featurepos
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_featurepos ();


   DROP TABLE audit_featuremap_pub;
   CREATE TABLE audit_featuremap_pub ( 
       featuremap_pub_id integer, 
       featuremap_id integer, 
       pub_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_featuremap_pub to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_featuremap_pub() RETURNS trigger AS
   '
   DECLARE
       featuremap_pub_id_var integer; 
       featuremap_id_var integer; 
       pub_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       featuremap_pub_id_var = OLD.featuremap_pub_id;
       featuremap_id_var = OLD.featuremap_id;
       pub_id_var = OLD.pub_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_featuremap_pub ( 
             featuremap_pub_id, 
             featuremap_id, 
             pub_id, 
             transaction_type
       ) VALUES ( 
             featuremap_pub_id_var, 
             featuremap_id_var, 
             pub_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER featuremap_pub_audit_ud ON featuremap_pub;
   CREATE TRIGGER featuremap_pub_audit_ud
       BEFORE UPDATE OR DELETE ON featuremap_pub
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_featuremap_pub ();


   DROP TABLE audit_phylotree;
   CREATE TABLE audit_phylotree ( 
       phylotree_id integer, 
       dbxref_id integer, 
       name varchar(255), 
       type_id integer, 
       analysis_id integer, 
       comment text, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_phylotree to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_phylotree() RETURNS trigger AS
   '
   DECLARE
       phylotree_id_var integer; 
       dbxref_id_var integer; 
       name_var varchar(255); 
       type_id_var integer; 
       analysis_id_var integer; 
       comment_var text; 
       
       transaction_type_var char;
   BEGIN
       phylotree_id_var = OLD.phylotree_id;
       dbxref_id_var = OLD.dbxref_id;
       name_var = OLD.name;
       type_id_var = OLD.type_id;
       analysis_id_var = OLD.analysis_id;
       comment_var = OLD.comment;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_phylotree ( 
             phylotree_id, 
             dbxref_id, 
             name, 
             type_id, 
             analysis_id, 
             comment, 
             transaction_type
       ) VALUES ( 
             phylotree_id_var, 
             dbxref_id_var, 
             name_var, 
             type_id_var, 
             analysis_id_var, 
             comment_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER phylotree_audit_ud ON phylotree;
   CREATE TRIGGER phylotree_audit_ud
       BEFORE UPDATE OR DELETE ON phylotree
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_phylotree ();


   DROP TABLE audit_phylotree_pub;
   CREATE TABLE audit_phylotree_pub ( 
       phylotree_pub_id integer, 
       phylotree_id integer, 
       pub_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_phylotree_pub to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_phylotree_pub() RETURNS trigger AS
   '
   DECLARE
       phylotree_pub_id_var integer; 
       phylotree_id_var integer; 
       pub_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       phylotree_pub_id_var = OLD.phylotree_pub_id;
       phylotree_id_var = OLD.phylotree_id;
       pub_id_var = OLD.pub_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_phylotree_pub ( 
             phylotree_pub_id, 
             phylotree_id, 
             pub_id, 
             transaction_type
       ) VALUES ( 
             phylotree_pub_id_var, 
             phylotree_id_var, 
             pub_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER phylotree_pub_audit_ud ON phylotree_pub;
   CREATE TRIGGER phylotree_pub_audit_ud
       BEFORE UPDATE OR DELETE ON phylotree_pub
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_phylotree_pub ();


   DROP TABLE audit_phylonode;
   CREATE TABLE audit_phylonode ( 
       phylonode_id integer, 
       phylotree_id integer, 
       parent_phylonode_id integer, 
       left_idx integer, 
       right_idx integer, 
       type_id integer, 
       feature_id integer, 
       label varchar(255), 
       distance float, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_phylonode to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_phylonode() RETURNS trigger AS
   '
   DECLARE
       phylonode_id_var integer; 
       phylotree_id_var integer; 
       parent_phylonode_id_var integer; 
       left_idx_var integer; 
       right_idx_var integer; 
       type_id_var integer; 
       feature_id_var integer; 
       label_var varchar(255); 
       distance_var float; 
       
       transaction_type_var char;
   BEGIN
       phylonode_id_var = OLD.phylonode_id;
       phylotree_id_var = OLD.phylotree_id;
       parent_phylonode_id_var = OLD.parent_phylonode_id;
       left_idx_var = OLD.left_idx;
       right_idx_var = OLD.right_idx;
       type_id_var = OLD.type_id;
       feature_id_var = OLD.feature_id;
       label_var = OLD.label;
       distance_var = OLD.distance;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_phylonode ( 
             phylonode_id, 
             phylotree_id, 
             parent_phylonode_id, 
             left_idx, 
             right_idx, 
             type_id, 
             feature_id, 
             label, 
             distance, 
             transaction_type
       ) VALUES ( 
             phylonode_id_var, 
             phylotree_id_var, 
             parent_phylonode_id_var, 
             left_idx_var, 
             right_idx_var, 
             type_id_var, 
             feature_id_var, 
             label_var, 
             distance_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER phylonode_audit_ud ON phylonode;
   CREATE TRIGGER phylonode_audit_ud
       BEFORE UPDATE OR DELETE ON phylonode
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_phylonode ();


   DROP TABLE audit_phylonode_dbxref;
   CREATE TABLE audit_phylonode_dbxref ( 
       phylonode_dbxref_id integer, 
       phylonode_id integer, 
       dbxref_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_phylonode_dbxref to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_phylonode_dbxref() RETURNS trigger AS
   '
   DECLARE
       phylonode_dbxref_id_var integer; 
       phylonode_id_var integer; 
       dbxref_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       phylonode_dbxref_id_var = OLD.phylonode_dbxref_id;
       phylonode_id_var = OLD.phylonode_id;
       dbxref_id_var = OLD.dbxref_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_phylonode_dbxref ( 
             phylonode_dbxref_id, 
             phylonode_id, 
             dbxref_id, 
             transaction_type
       ) VALUES ( 
             phylonode_dbxref_id_var, 
             phylonode_id_var, 
             dbxref_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER phylonode_dbxref_audit_ud ON phylonode_dbxref;
   CREATE TRIGGER phylonode_dbxref_audit_ud
       BEFORE UPDATE OR DELETE ON phylonode_dbxref
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_phylonode_dbxref ();


   DROP TABLE audit_phylonode_pub;
   CREATE TABLE audit_phylonode_pub ( 
       phylonode_pub_id integer, 
       phylonode_id integer, 
       pub_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_phylonode_pub to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_phylonode_pub() RETURNS trigger AS
   '
   DECLARE
       phylonode_pub_id_var integer; 
       phylonode_id_var integer; 
       pub_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       phylonode_pub_id_var = OLD.phylonode_pub_id;
       phylonode_id_var = OLD.phylonode_id;
       pub_id_var = OLD.pub_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_phylonode_pub ( 
             phylonode_pub_id, 
             phylonode_id, 
             pub_id, 
             transaction_type
       ) VALUES ( 
             phylonode_pub_id_var, 
             phylonode_id_var, 
             pub_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER phylonode_pub_audit_ud ON phylonode_pub;
   CREATE TRIGGER phylonode_pub_audit_ud
       BEFORE UPDATE OR DELETE ON phylonode_pub
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_phylonode_pub ();


   DROP TABLE audit_phylonode_organism;
   CREATE TABLE audit_phylonode_organism ( 
       phylonode_organism_id integer, 
       phylonode_id integer, 
       organism_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_phylonode_organism to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_phylonode_organism() RETURNS trigger AS
   '
   DECLARE
       phylonode_organism_id_var integer; 
       phylonode_id_var integer; 
       organism_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       phylonode_organism_id_var = OLD.phylonode_organism_id;
       phylonode_id_var = OLD.phylonode_id;
       organism_id_var = OLD.organism_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_phylonode_organism ( 
             phylonode_organism_id, 
             phylonode_id, 
             organism_id, 
             transaction_type
       ) VALUES ( 
             phylonode_organism_id_var, 
             phylonode_id_var, 
             organism_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER phylonode_organism_audit_ud ON phylonode_organism;
   CREATE TRIGGER phylonode_organism_audit_ud
       BEFORE UPDATE OR DELETE ON phylonode_organism
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_phylonode_organism ();


   DROP TABLE audit_phylonodeprop;
   CREATE TABLE audit_phylonodeprop ( 
       phylonodeprop_id integer, 
       phylonode_id integer, 
       type_id integer, 
       value text, 
       rank integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_phylonodeprop to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_phylonodeprop() RETURNS trigger AS
   '
   DECLARE
       phylonodeprop_id_var integer; 
       phylonode_id_var integer; 
       type_id_var integer; 
       value_var text; 
       rank_var integer; 
       
       transaction_type_var char;
   BEGIN
       phylonodeprop_id_var = OLD.phylonodeprop_id;
       phylonode_id_var = OLD.phylonode_id;
       type_id_var = OLD.type_id;
       value_var = OLD.value;
       rank_var = OLD.rank;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_phylonodeprop ( 
             phylonodeprop_id, 
             phylonode_id, 
             type_id, 
             value, 
             rank, 
             transaction_type
       ) VALUES ( 
             phylonodeprop_id_var, 
             phylonode_id_var, 
             type_id_var, 
             value_var, 
             rank_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER phylonodeprop_audit_ud ON phylonodeprop;
   CREATE TRIGGER phylonodeprop_audit_ud
       BEFORE UPDATE OR DELETE ON phylonodeprop
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_phylonodeprop ();


   DROP TABLE audit_phylonode_relationship;
   CREATE TABLE audit_phylonode_relationship ( 
       phylonode_relationship_id integer, 
       subject_id integer, 
       object_id integer, 
       type_id integer, 
       rank integer, 
       phylotree_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_phylonode_relationship to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_phylonode_relationship() RETURNS trigger AS
   '
   DECLARE
       phylonode_relationship_id_var integer; 
       subject_id_var integer; 
       object_id_var integer; 
       type_id_var integer; 
       rank_var integer; 
       phylotree_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       phylonode_relationship_id_var = OLD.phylonode_relationship_id;
       subject_id_var = OLD.subject_id;
       object_id_var = OLD.object_id;
       type_id_var = OLD.type_id;
       rank_var = OLD.rank;
       phylotree_id_var = OLD.phylotree_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_phylonode_relationship ( 
             phylonode_relationship_id, 
             subject_id, 
             object_id, 
             type_id, 
             rank, 
             phylotree_id, 
             transaction_type
       ) VALUES ( 
             phylonode_relationship_id_var, 
             subject_id_var, 
             object_id_var, 
             type_id_var, 
             rank_var, 
             phylotree_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER phylonode_relationship_audit_ud ON phylonode_relationship;
   CREATE TRIGGER phylonode_relationship_audit_ud
       BEFORE UPDATE OR DELETE ON phylonode_relationship
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_phylonode_relationship ();


   DROP TABLE audit_contact;
   CREATE TABLE audit_contact ( 
       contact_id integer, 
       type_id integer, 
       name varchar(255), 
       description varchar(255), 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_contact to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_contact() RETURNS trigger AS
   '
   DECLARE
       contact_id_var integer; 
       type_id_var integer; 
       name_var varchar(255); 
       description_var varchar(255); 
       
       transaction_type_var char;
   BEGIN
       contact_id_var = OLD.contact_id;
       type_id_var = OLD.type_id;
       name_var = OLD.name;
       description_var = OLD.description;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_contact ( 
             contact_id, 
             type_id, 
             name, 
             description, 
             transaction_type
       ) VALUES ( 
             contact_id_var, 
             type_id_var, 
             name_var, 
             description_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER contact_audit_ud ON contact;
   CREATE TRIGGER contact_audit_ud
       BEFORE UPDATE OR DELETE ON contact
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_contact ();


   DROP TABLE audit_contact_relationship;
   CREATE TABLE audit_contact_relationship ( 
       contact_relationship_id integer, 
       type_id integer, 
       subject_id integer, 
       object_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_contact_relationship to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_contact_relationship() RETURNS trigger AS
   '
   DECLARE
       contact_relationship_id_var integer; 
       type_id_var integer; 
       subject_id_var integer; 
       object_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       contact_relationship_id_var = OLD.contact_relationship_id;
       type_id_var = OLD.type_id;
       subject_id_var = OLD.subject_id;
       object_id_var = OLD.object_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_contact_relationship ( 
             contact_relationship_id, 
             type_id, 
             subject_id, 
             object_id, 
             transaction_type
       ) VALUES ( 
             contact_relationship_id_var, 
             type_id_var, 
             subject_id_var, 
             object_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER contact_relationship_audit_ud ON contact_relationship;
   CREATE TRIGGER contact_relationship_audit_ud
       BEFORE UPDATE OR DELETE ON contact_relationship
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_contact_relationship ();


   DROP TABLE audit_expression;
   CREATE TABLE audit_expression ( 
       expression_id integer, 
       uniquename text, 
       md5checksum char(32), 
       description text, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_expression to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_expression() RETURNS trigger AS
   '
   DECLARE
       expression_id_var integer; 
       uniquename_var text; 
       md5checksum_var char(32); 
       description_var text; 
       
       transaction_type_var char;
   BEGIN
       expression_id_var = OLD.expression_id;
       uniquename_var = OLD.uniquename;
       md5checksum_var = OLD.md5checksum;
       description_var = OLD.description;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_expression ( 
             expression_id, 
             uniquename, 
             md5checksum, 
             description, 
             transaction_type
       ) VALUES ( 
             expression_id_var, 
             uniquename_var, 
             md5checksum_var, 
             description_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER expression_audit_ud ON expression;
   CREATE TRIGGER expression_audit_ud
       BEFORE UPDATE OR DELETE ON expression
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_expression ();


   DROP TABLE audit_expression_cvterm;
   CREATE TABLE audit_expression_cvterm ( 
       expression_cvterm_id integer, 
       expression_id integer, 
       cvterm_id integer, 
       rank integer, 
       cvterm_type_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_expression_cvterm to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_expression_cvterm() RETURNS trigger AS
   '
   DECLARE
       expression_cvterm_id_var integer; 
       expression_id_var integer; 
       cvterm_id_var integer; 
       rank_var integer; 
       cvterm_type_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       expression_cvterm_id_var = OLD.expression_cvterm_id;
       expression_id_var = OLD.expression_id;
       cvterm_id_var = OLD.cvterm_id;
       rank_var = OLD.rank;
       cvterm_type_id_var = OLD.cvterm_type_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_expression_cvterm ( 
             expression_cvterm_id, 
             expression_id, 
             cvterm_id, 
             rank, 
             cvterm_type_id, 
             transaction_type
       ) VALUES ( 
             expression_cvterm_id_var, 
             expression_id_var, 
             cvterm_id_var, 
             rank_var, 
             cvterm_type_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER expression_cvterm_audit_ud ON expression_cvterm;
   CREATE TRIGGER expression_cvterm_audit_ud
       BEFORE UPDATE OR DELETE ON expression_cvterm
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_expression_cvterm ();


   DROP TABLE audit_expression_cvtermprop;
   CREATE TABLE audit_expression_cvtermprop ( 
       expression_cvtermprop_id integer, 
       expression_cvterm_id integer, 
       type_id integer, 
       value text, 
       rank integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_expression_cvtermprop to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_expression_cvtermprop() RETURNS trigger AS
   '
   DECLARE
       expression_cvtermprop_id_var integer; 
       expression_cvterm_id_var integer; 
       type_id_var integer; 
       value_var text; 
       rank_var integer; 
       
       transaction_type_var char;
   BEGIN
       expression_cvtermprop_id_var = OLD.expression_cvtermprop_id;
       expression_cvterm_id_var = OLD.expression_cvterm_id;
       type_id_var = OLD.type_id;
       value_var = OLD.value;
       rank_var = OLD.rank;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_expression_cvtermprop ( 
             expression_cvtermprop_id, 
             expression_cvterm_id, 
             type_id, 
             value, 
             rank, 
             transaction_type
       ) VALUES ( 
             expression_cvtermprop_id_var, 
             expression_cvterm_id_var, 
             type_id_var, 
             value_var, 
             rank_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER expression_cvtermprop_audit_ud ON expression_cvtermprop;
   CREATE TRIGGER expression_cvtermprop_audit_ud
       BEFORE UPDATE OR DELETE ON expression_cvtermprop
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_expression_cvtermprop ();


   DROP TABLE audit_expressionprop;
   CREATE TABLE audit_expressionprop ( 
       expressionprop_id integer, 
       expression_id integer, 
       type_id integer, 
       value text, 
       rank integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_expressionprop to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_expressionprop() RETURNS trigger AS
   '
   DECLARE
       expressionprop_id_var integer; 
       expression_id_var integer; 
       type_id_var integer; 
       value_var text; 
       rank_var integer; 
       
       transaction_type_var char;
   BEGIN
       expressionprop_id_var = OLD.expressionprop_id;
       expression_id_var = OLD.expression_id;
       type_id_var = OLD.type_id;
       value_var = OLD.value;
       rank_var = OLD.rank;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_expressionprop ( 
             expressionprop_id, 
             expression_id, 
             type_id, 
             value, 
             rank, 
             transaction_type
       ) VALUES ( 
             expressionprop_id_var, 
             expression_id_var, 
             type_id_var, 
             value_var, 
             rank_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER expressionprop_audit_ud ON expressionprop;
   CREATE TRIGGER expressionprop_audit_ud
       BEFORE UPDATE OR DELETE ON expressionprop
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_expressionprop ();


   DROP TABLE audit_expression_pub;
   CREATE TABLE audit_expression_pub ( 
       expression_pub_id integer, 
       expression_id integer, 
       pub_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_expression_pub to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_expression_pub() RETURNS trigger AS
   '
   DECLARE
       expression_pub_id_var integer; 
       expression_id_var integer; 
       pub_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       expression_pub_id_var = OLD.expression_pub_id;
       expression_id_var = OLD.expression_id;
       pub_id_var = OLD.pub_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_expression_pub ( 
             expression_pub_id, 
             expression_id, 
             pub_id, 
             transaction_type
       ) VALUES ( 
             expression_pub_id_var, 
             expression_id_var, 
             pub_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER expression_pub_audit_ud ON expression_pub;
   CREATE TRIGGER expression_pub_audit_ud
       BEFORE UPDATE OR DELETE ON expression_pub
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_expression_pub ();


   DROP TABLE audit_feature_expression;
   CREATE TABLE audit_feature_expression ( 
       feature_expression_id integer, 
       expression_id integer, 
       feature_id integer, 
       pub_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_feature_expression to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_feature_expression() RETURNS trigger AS
   '
   DECLARE
       feature_expression_id_var integer; 
       expression_id_var integer; 
       feature_id_var integer; 
       pub_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       feature_expression_id_var = OLD.feature_expression_id;
       expression_id_var = OLD.expression_id;
       feature_id_var = OLD.feature_id;
       pub_id_var = OLD.pub_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_feature_expression ( 
             feature_expression_id, 
             expression_id, 
             feature_id, 
             pub_id, 
             transaction_type
       ) VALUES ( 
             feature_expression_id_var, 
             expression_id_var, 
             feature_id_var, 
             pub_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER feature_expression_audit_ud ON feature_expression;
   CREATE TRIGGER feature_expression_audit_ud
       BEFORE UPDATE OR DELETE ON feature_expression
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_feature_expression ();


   DROP TABLE audit_feature_expressionprop;
   CREATE TABLE audit_feature_expressionprop ( 
       feature_expressionprop_id integer, 
       feature_expression_id integer, 
       type_id integer, 
       value text, 
       rank integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_feature_expressionprop to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_feature_expressionprop() RETURNS trigger AS
   '
   DECLARE
       feature_expressionprop_id_var integer; 
       feature_expression_id_var integer; 
       type_id_var integer; 
       value_var text; 
       rank_var integer; 
       
       transaction_type_var char;
   BEGIN
       feature_expressionprop_id_var = OLD.feature_expressionprop_id;
       feature_expression_id_var = OLD.feature_expression_id;
       type_id_var = OLD.type_id;
       value_var = OLD.value;
       rank_var = OLD.rank;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_feature_expressionprop ( 
             feature_expressionprop_id, 
             feature_expression_id, 
             type_id, 
             value, 
             rank, 
             transaction_type
       ) VALUES ( 
             feature_expressionprop_id_var, 
             feature_expression_id_var, 
             type_id_var, 
             value_var, 
             rank_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER feature_expressionprop_audit_ud ON feature_expressionprop;
   CREATE TRIGGER feature_expressionprop_audit_ud
       BEFORE UPDATE OR DELETE ON feature_expressionprop
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_feature_expressionprop ();


   DROP TABLE audit_eimage;
   CREATE TABLE audit_eimage ( 
       eimage_id integer, 
       eimage_data text, 
       eimage_type varchar(255), 
       image_uri varchar(255), 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_eimage to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_eimage() RETURNS trigger AS
   '
   DECLARE
       eimage_id_var integer; 
       eimage_data_var text; 
       eimage_type_var varchar(255); 
       image_uri_var varchar(255); 
       
       transaction_type_var char;
   BEGIN
       eimage_id_var = OLD.eimage_id;
       eimage_data_var = OLD.eimage_data;
       eimage_type_var = OLD.eimage_type;
       image_uri_var = OLD.image_uri;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_eimage ( 
             eimage_id, 
             eimage_data, 
             eimage_type, 
             image_uri, 
             transaction_type
       ) VALUES ( 
             eimage_id_var, 
             eimage_data_var, 
             eimage_type_var, 
             image_uri_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER eimage_audit_ud ON eimage;
   CREATE TRIGGER eimage_audit_ud
       BEFORE UPDATE OR DELETE ON eimage
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_eimage ();


   DROP TABLE audit_expression_image;
   CREATE TABLE audit_expression_image ( 
       expression_image_id integer, 
       expression_id integer, 
       eimage_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_expression_image to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_expression_image() RETURNS trigger AS
   '
   DECLARE
       expression_image_id_var integer; 
       expression_id_var integer; 
       eimage_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       expression_image_id_var = OLD.expression_image_id;
       expression_id_var = OLD.expression_id;
       eimage_id_var = OLD.eimage_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_expression_image ( 
             expression_image_id, 
             expression_id, 
             eimage_id, 
             transaction_type
       ) VALUES ( 
             expression_image_id_var, 
             expression_id_var, 
             eimage_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER expression_image_audit_ud ON expression_image;
   CREATE TRIGGER expression_image_audit_ud
       BEFORE UPDATE OR DELETE ON expression_image
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_expression_image ();


   DROP TABLE audit_project;
   CREATE TABLE audit_project ( 
       project_id integer, 
       name varchar(255), 
       description varchar(255), 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_project to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_project() RETURNS trigger AS
   '
   DECLARE
       project_id_var integer; 
       name_var varchar(255); 
       description_var varchar(255); 
       
       transaction_type_var char;
   BEGIN
       project_id_var = OLD.project_id;
       name_var = OLD.name;
       description_var = OLD.description;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_project ( 
             project_id, 
             name, 
             description, 
             transaction_type
       ) VALUES ( 
             project_id_var, 
             name_var, 
             description_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER project_audit_ud ON project;
   CREATE TRIGGER project_audit_ud
       BEFORE UPDATE OR DELETE ON project
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_project ();


   DROP TABLE audit_projectprop;
   CREATE TABLE audit_projectprop ( 
       projectprop_id integer, 
       project_id integer, 
       type_id integer, 
       value text, 
       rank integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_projectprop to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_projectprop() RETURNS trigger AS
   '
   DECLARE
       projectprop_id_var integer; 
       project_id_var integer; 
       type_id_var integer; 
       value_var text; 
       rank_var integer; 
       
       transaction_type_var char;
   BEGIN
       projectprop_id_var = OLD.projectprop_id;
       project_id_var = OLD.project_id;
       type_id_var = OLD.type_id;
       value_var = OLD.value;
       rank_var = OLD.rank;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_projectprop ( 
             projectprop_id, 
             project_id, 
             type_id, 
             value, 
             rank, 
             transaction_type
       ) VALUES ( 
             projectprop_id_var, 
             project_id_var, 
             type_id_var, 
             value_var, 
             rank_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER projectprop_audit_ud ON projectprop;
   CREATE TRIGGER projectprop_audit_ud
       BEFORE UPDATE OR DELETE ON projectprop
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_projectprop ();


   DROP TABLE audit_project_relationship;
   CREATE TABLE audit_project_relationship ( 
       project_relationship_id integer, 
       subject_project_id integer, 
       object_project_id integer, 
       type_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_project_relationship to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_project_relationship() RETURNS trigger AS
   '
   DECLARE
       project_relationship_id_var integer; 
       subject_project_id_var integer; 
       object_project_id_var integer; 
       type_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       project_relationship_id_var = OLD.project_relationship_id;
       subject_project_id_var = OLD.subject_project_id;
       object_project_id_var = OLD.object_project_id;
       type_id_var = OLD.type_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_project_relationship ( 
             project_relationship_id, 
             subject_project_id, 
             object_project_id, 
             type_id, 
             transaction_type
       ) VALUES ( 
             project_relationship_id_var, 
             subject_project_id_var, 
             object_project_id_var, 
             type_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER project_relationship_audit_ud ON project_relationship;
   CREATE TRIGGER project_relationship_audit_ud
       BEFORE UPDATE OR DELETE ON project_relationship
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_project_relationship ();


   DROP TABLE audit_project_pub;
   CREATE TABLE audit_project_pub ( 
       project_pub_id integer, 
       project_id integer, 
       pub_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_project_pub to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_project_pub() RETURNS trigger AS
   '
   DECLARE
       project_pub_id_var integer; 
       project_id_var integer; 
       pub_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       project_pub_id_var = OLD.project_pub_id;
       project_id_var = OLD.project_id;
       pub_id_var = OLD.pub_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_project_pub ( 
             project_pub_id, 
             project_id, 
             pub_id, 
             transaction_type
       ) VALUES ( 
             project_pub_id_var, 
             project_id_var, 
             pub_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER project_pub_audit_ud ON project_pub;
   CREATE TRIGGER project_pub_audit_ud
       BEFORE UPDATE OR DELETE ON project_pub
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_project_pub ();


   DROP TABLE audit_project_contact;
   CREATE TABLE audit_project_contact ( 
       project_contact_id integer, 
       project_id integer, 
       contact_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_project_contact to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_project_contact() RETURNS trigger AS
   '
   DECLARE
       project_contact_id_var integer; 
       project_id_var integer; 
       contact_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       project_contact_id_var = OLD.project_contact_id;
       project_id_var = OLD.project_id;
       contact_id_var = OLD.contact_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_project_contact ( 
             project_contact_id, 
             project_id, 
             contact_id, 
             transaction_type
       ) VALUES ( 
             project_contact_id_var, 
             project_id_var, 
             contact_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER project_contact_audit_ud ON project_contact;
   CREATE TRIGGER project_contact_audit_ud
       BEFORE UPDATE OR DELETE ON project_contact
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_project_contact ();


   DROP TABLE audit_mageml;
   CREATE TABLE audit_mageml ( 
       mageml_id integer, 
       mage_package text, 
       mage_ml text, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_mageml to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_mageml() RETURNS trigger AS
   '
   DECLARE
       mageml_id_var integer; 
       mage_package_var text; 
       mage_ml_var text; 
       
       transaction_type_var char;
   BEGIN
       mageml_id_var = OLD.mageml_id;
       mage_package_var = OLD.mage_package;
       mage_ml_var = OLD.mage_ml;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_mageml ( 
             mageml_id, 
             mage_package, 
             mage_ml, 
             transaction_type
       ) VALUES ( 
             mageml_id_var, 
             mage_package_var, 
             mage_ml_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER mageml_audit_ud ON mageml;
   CREATE TRIGGER mageml_audit_ud
       BEFORE UPDATE OR DELETE ON mageml
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_mageml ();


   DROP TABLE audit_magedocumentation;
   CREATE TABLE audit_magedocumentation ( 
       magedocumentation_id integer, 
       mageml_id integer, 
       tableinfo_id integer, 
       row_id integer, 
       mageidentifier text, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_magedocumentation to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_magedocumentation() RETURNS trigger AS
   '
   DECLARE
       magedocumentation_id_var integer; 
       mageml_id_var integer; 
       tableinfo_id_var integer; 
       row_id_var integer; 
       mageidentifier_var text; 
       
       transaction_type_var char;
   BEGIN
       magedocumentation_id_var = OLD.magedocumentation_id;
       mageml_id_var = OLD.mageml_id;
       tableinfo_id_var = OLD.tableinfo_id;
       row_id_var = OLD.row_id;
       mageidentifier_var = OLD.mageidentifier;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_magedocumentation ( 
             magedocumentation_id, 
             mageml_id, 
             tableinfo_id, 
             row_id, 
             mageidentifier, 
             transaction_type
       ) VALUES ( 
             magedocumentation_id_var, 
             mageml_id_var, 
             tableinfo_id_var, 
             row_id_var, 
             mageidentifier_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER magedocumentation_audit_ud ON magedocumentation;
   CREATE TRIGGER magedocumentation_audit_ud
       BEFORE UPDATE OR DELETE ON magedocumentation
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_magedocumentation ();


   DROP TABLE audit_protocol;
   CREATE TABLE audit_protocol ( 
       protocol_id integer, 
       type_id integer, 
       pub_id integer, 
       dbxref_id integer, 
       name text, 
       uri text, 
       protocoldescription text, 
       hardwaredescription text, 
       softwaredescription text, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_protocol to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_protocol() RETURNS trigger AS
   '
   DECLARE
       protocol_id_var integer; 
       type_id_var integer; 
       pub_id_var integer; 
       dbxref_id_var integer; 
       name_var text; 
       uri_var text; 
       protocoldescription_var text; 
       hardwaredescription_var text; 
       softwaredescription_var text; 
       
       transaction_type_var char;
   BEGIN
       protocol_id_var = OLD.protocol_id;
       type_id_var = OLD.type_id;
       pub_id_var = OLD.pub_id;
       dbxref_id_var = OLD.dbxref_id;
       name_var = OLD.name;
       uri_var = OLD.uri;
       protocoldescription_var = OLD.protocoldescription;
       hardwaredescription_var = OLD.hardwaredescription;
       softwaredescription_var = OLD.softwaredescription;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_protocol ( 
             protocol_id, 
             type_id, 
             pub_id, 
             dbxref_id, 
             name, 
             uri, 
             protocoldescription, 
             hardwaredescription, 
             softwaredescription, 
             transaction_type
       ) VALUES ( 
             protocol_id_var, 
             type_id_var, 
             pub_id_var, 
             dbxref_id_var, 
             name_var, 
             uri_var, 
             protocoldescription_var, 
             hardwaredescription_var, 
             softwaredescription_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER protocol_audit_ud ON protocol;
   CREATE TRIGGER protocol_audit_ud
       BEFORE UPDATE OR DELETE ON protocol
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_protocol ();


   DROP TABLE audit_protocolparam;
   CREATE TABLE audit_protocolparam ( 
       protocolparam_id integer, 
       protocol_id integer, 
       name text, 
       datatype_id integer, 
       unittype_id integer, 
       value text, 
       rank integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_protocolparam to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_protocolparam() RETURNS trigger AS
   '
   DECLARE
       protocolparam_id_var integer; 
       protocol_id_var integer; 
       name_var text; 
       datatype_id_var integer; 
       unittype_id_var integer; 
       value_var text; 
       rank_var integer; 
       
       transaction_type_var char;
   BEGIN
       protocolparam_id_var = OLD.protocolparam_id;
       protocol_id_var = OLD.protocol_id;
       name_var = OLD.name;
       datatype_id_var = OLD.datatype_id;
       unittype_id_var = OLD.unittype_id;
       value_var = OLD.value;
       rank_var = OLD.rank;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_protocolparam ( 
             protocolparam_id, 
             protocol_id, 
             name, 
             datatype_id, 
             unittype_id, 
             value, 
             rank, 
             transaction_type
       ) VALUES ( 
             protocolparam_id_var, 
             protocol_id_var, 
             name_var, 
             datatype_id_var, 
             unittype_id_var, 
             value_var, 
             rank_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER protocolparam_audit_ud ON protocolparam;
   CREATE TRIGGER protocolparam_audit_ud
       BEFORE UPDATE OR DELETE ON protocolparam
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_protocolparam ();


   DROP TABLE audit_channel;
   CREATE TABLE audit_channel ( 
       channel_id integer, 
       name text, 
       definition text, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_channel to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_channel() RETURNS trigger AS
   '
   DECLARE
       channel_id_var integer; 
       name_var text; 
       definition_var text; 
       
       transaction_type_var char;
   BEGIN
       channel_id_var = OLD.channel_id;
       name_var = OLD.name;
       definition_var = OLD.definition;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_channel ( 
             channel_id, 
             name, 
             definition, 
             transaction_type
       ) VALUES ( 
             channel_id_var, 
             name_var, 
             definition_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER channel_audit_ud ON channel;
   CREATE TRIGGER channel_audit_ud
       BEFORE UPDATE OR DELETE ON channel
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_channel ();


   DROP TABLE audit_arraydesign;
   CREATE TABLE audit_arraydesign ( 
       arraydesign_id integer, 
       manufacturer_id integer, 
       platformtype_id integer, 
       substratetype_id integer, 
       protocol_id integer, 
       dbxref_id integer, 
       name text, 
       version text, 
       description text, 
       array_dimensions text, 
       element_dimensions text, 
       num_of_elements integer, 
       num_array_columns integer, 
       num_array_rows integer, 
       num_grid_columns integer, 
       num_grid_rows integer, 
       num_sub_columns integer, 
       num_sub_rows integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_arraydesign to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_arraydesign() RETURNS trigger AS
   '
   DECLARE
       arraydesign_id_var integer; 
       manufacturer_id_var integer; 
       platformtype_id_var integer; 
       substratetype_id_var integer; 
       protocol_id_var integer; 
       dbxref_id_var integer; 
       name_var text; 
       version_var text; 
       description_var text; 
       array_dimensions_var text; 
       element_dimensions_var text; 
       num_of_elements_var integer; 
       num_array_columns_var integer; 
       num_array_rows_var integer; 
       num_grid_columns_var integer; 
       num_grid_rows_var integer; 
       num_sub_columns_var integer; 
       num_sub_rows_var integer; 
       
       transaction_type_var char;
   BEGIN
       arraydesign_id_var = OLD.arraydesign_id;
       manufacturer_id_var = OLD.manufacturer_id;
       platformtype_id_var = OLD.platformtype_id;
       substratetype_id_var = OLD.substratetype_id;
       protocol_id_var = OLD.protocol_id;
       dbxref_id_var = OLD.dbxref_id;
       name_var = OLD.name;
       version_var = OLD.version;
       description_var = OLD.description;
       array_dimensions_var = OLD.array_dimensions;
       element_dimensions_var = OLD.element_dimensions;
       num_of_elements_var = OLD.num_of_elements;
       num_array_columns_var = OLD.num_array_columns;
       num_array_rows_var = OLD.num_array_rows;
       num_grid_columns_var = OLD.num_grid_columns;
       num_grid_rows_var = OLD.num_grid_rows;
       num_sub_columns_var = OLD.num_sub_columns;
       num_sub_rows_var = OLD.num_sub_rows;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_arraydesign ( 
             arraydesign_id, 
             manufacturer_id, 
             platformtype_id, 
             substratetype_id, 
             protocol_id, 
             dbxref_id, 
             name, 
             version, 
             description, 
             array_dimensions, 
             element_dimensions, 
             num_of_elements, 
             num_array_columns, 
             num_array_rows, 
             num_grid_columns, 
             num_grid_rows, 
             num_sub_columns, 
             num_sub_rows, 
             transaction_type
       ) VALUES ( 
             arraydesign_id_var, 
             manufacturer_id_var, 
             platformtype_id_var, 
             substratetype_id_var, 
             protocol_id_var, 
             dbxref_id_var, 
             name_var, 
             version_var, 
             description_var, 
             array_dimensions_var, 
             element_dimensions_var, 
             num_of_elements_var, 
             num_array_columns_var, 
             num_array_rows_var, 
             num_grid_columns_var, 
             num_grid_rows_var, 
             num_sub_columns_var, 
             num_sub_rows_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER arraydesign_audit_ud ON arraydesign;
   CREATE TRIGGER arraydesign_audit_ud
       BEFORE UPDATE OR DELETE ON arraydesign
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_arraydesign ();


   DROP TABLE audit_arraydesignprop;
   CREATE TABLE audit_arraydesignprop ( 
       arraydesignprop_id integer, 
       arraydesign_id integer, 
       type_id integer, 
       value text, 
       rank integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_arraydesignprop to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_arraydesignprop() RETURNS trigger AS
   '
   DECLARE
       arraydesignprop_id_var integer; 
       arraydesign_id_var integer; 
       type_id_var integer; 
       value_var text; 
       rank_var integer; 
       
       transaction_type_var char;
   BEGIN
       arraydesignprop_id_var = OLD.arraydesignprop_id;
       arraydesign_id_var = OLD.arraydesign_id;
       type_id_var = OLD.type_id;
       value_var = OLD.value;
       rank_var = OLD.rank;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_arraydesignprop ( 
             arraydesignprop_id, 
             arraydesign_id, 
             type_id, 
             value, 
             rank, 
             transaction_type
       ) VALUES ( 
             arraydesignprop_id_var, 
             arraydesign_id_var, 
             type_id_var, 
             value_var, 
             rank_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER arraydesignprop_audit_ud ON arraydesignprop;
   CREATE TRIGGER arraydesignprop_audit_ud
       BEFORE UPDATE OR DELETE ON arraydesignprop
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_arraydesignprop ();


   DROP TABLE audit_assay;
   CREATE TABLE audit_assay ( 
       assay_id integer, 
       arraydesign_id integer, 
       protocol_id integer, 
       assaydate timestamp, 
       arrayidentifier text, 
       arraybatchidentifier text, 
       operator_id integer, 
       dbxref_id integer, 
       name text, 
       description text, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_assay to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_assay() RETURNS trigger AS
   '
   DECLARE
       assay_id_var integer; 
       arraydesign_id_var integer; 
       protocol_id_var integer; 
       assaydate_var timestamp; 
       arrayidentifier_var text; 
       arraybatchidentifier_var text; 
       operator_id_var integer; 
       dbxref_id_var integer; 
       name_var text; 
       description_var text; 
       
       transaction_type_var char;
   BEGIN
       assay_id_var = OLD.assay_id;
       arraydesign_id_var = OLD.arraydesign_id;
       protocol_id_var = OLD.protocol_id;
       assaydate_var = OLD.assaydate;
       arrayidentifier_var = OLD.arrayidentifier;
       arraybatchidentifier_var = OLD.arraybatchidentifier;
       operator_id_var = OLD.operator_id;
       dbxref_id_var = OLD.dbxref_id;
       name_var = OLD.name;
       description_var = OLD.description;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_assay ( 
             assay_id, 
             arraydesign_id, 
             protocol_id, 
             assaydate, 
             arrayidentifier, 
             arraybatchidentifier, 
             operator_id, 
             dbxref_id, 
             name, 
             description, 
             transaction_type
       ) VALUES ( 
             assay_id_var, 
             arraydesign_id_var, 
             protocol_id_var, 
             assaydate_var, 
             arrayidentifier_var, 
             arraybatchidentifier_var, 
             operator_id_var, 
             dbxref_id_var, 
             name_var, 
             description_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER assay_audit_ud ON assay;
   CREATE TRIGGER assay_audit_ud
       BEFORE UPDATE OR DELETE ON assay
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_assay ();


   DROP TABLE audit_assayprop;
   CREATE TABLE audit_assayprop ( 
       assayprop_id integer, 
       assay_id integer, 
       type_id integer, 
       value text, 
       rank integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_assayprop to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_assayprop() RETURNS trigger AS
   '
   DECLARE
       assayprop_id_var integer; 
       assay_id_var integer; 
       type_id_var integer; 
       value_var text; 
       rank_var integer; 
       
       transaction_type_var char;
   BEGIN
       assayprop_id_var = OLD.assayprop_id;
       assay_id_var = OLD.assay_id;
       type_id_var = OLD.type_id;
       value_var = OLD.value;
       rank_var = OLD.rank;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_assayprop ( 
             assayprop_id, 
             assay_id, 
             type_id, 
             value, 
             rank, 
             transaction_type
       ) VALUES ( 
             assayprop_id_var, 
             assay_id_var, 
             type_id_var, 
             value_var, 
             rank_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER assayprop_audit_ud ON assayprop;
   CREATE TRIGGER assayprop_audit_ud
       BEFORE UPDATE OR DELETE ON assayprop
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_assayprop ();


   DROP TABLE audit_assay_project;
   CREATE TABLE audit_assay_project ( 
       assay_project_id integer, 
       assay_id integer, 
       project_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_assay_project to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_assay_project() RETURNS trigger AS
   '
   DECLARE
       assay_project_id_var integer; 
       assay_id_var integer; 
       project_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       assay_project_id_var = OLD.assay_project_id;
       assay_id_var = OLD.assay_id;
       project_id_var = OLD.project_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_assay_project ( 
             assay_project_id, 
             assay_id, 
             project_id, 
             transaction_type
       ) VALUES ( 
             assay_project_id_var, 
             assay_id_var, 
             project_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER assay_project_audit_ud ON assay_project;
   CREATE TRIGGER assay_project_audit_ud
       BEFORE UPDATE OR DELETE ON assay_project
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_assay_project ();


   DROP TABLE audit_biomaterial;
   CREATE TABLE audit_biomaterial ( 
       biomaterial_id integer, 
       taxon_id integer, 
       biosourceprovider_id integer, 
       dbxref_id integer, 
       name text, 
       description text, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_biomaterial to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_biomaterial() RETURNS trigger AS
   '
   DECLARE
       biomaterial_id_var integer; 
       taxon_id_var integer; 
       biosourceprovider_id_var integer; 
       dbxref_id_var integer; 
       name_var text; 
       description_var text; 
       
       transaction_type_var char;
   BEGIN
       biomaterial_id_var = OLD.biomaterial_id;
       taxon_id_var = OLD.taxon_id;
       biosourceprovider_id_var = OLD.biosourceprovider_id;
       dbxref_id_var = OLD.dbxref_id;
       name_var = OLD.name;
       description_var = OLD.description;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_biomaterial ( 
             biomaterial_id, 
             taxon_id, 
             biosourceprovider_id, 
             dbxref_id, 
             name, 
             description, 
             transaction_type
       ) VALUES ( 
             biomaterial_id_var, 
             taxon_id_var, 
             biosourceprovider_id_var, 
             dbxref_id_var, 
             name_var, 
             description_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER biomaterial_audit_ud ON biomaterial;
   CREATE TRIGGER biomaterial_audit_ud
       BEFORE UPDATE OR DELETE ON biomaterial
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_biomaterial ();


   DROP TABLE audit_biomaterial_relationship;
   CREATE TABLE audit_biomaterial_relationship ( 
       biomaterial_relationship_id integer, 
       subject_id integer, 
       type_id integer, 
       object_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_biomaterial_relationship to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_biomaterial_relationship() RETURNS trigger AS
   '
   DECLARE
       biomaterial_relationship_id_var integer; 
       subject_id_var integer; 
       type_id_var integer; 
       object_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       biomaterial_relationship_id_var = OLD.biomaterial_relationship_id;
       subject_id_var = OLD.subject_id;
       type_id_var = OLD.type_id;
       object_id_var = OLD.object_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_biomaterial_relationship ( 
             biomaterial_relationship_id, 
             subject_id, 
             type_id, 
             object_id, 
             transaction_type
       ) VALUES ( 
             biomaterial_relationship_id_var, 
             subject_id_var, 
             type_id_var, 
             object_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER biomaterial_relationship_audit_ud ON biomaterial_relationship;
   CREATE TRIGGER biomaterial_relationship_audit_ud
       BEFORE UPDATE OR DELETE ON biomaterial_relationship
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_biomaterial_relationship ();


   DROP TABLE audit_biomaterialprop;
   CREATE TABLE audit_biomaterialprop ( 
       biomaterialprop_id integer, 
       biomaterial_id integer, 
       type_id integer, 
       value text, 
       rank integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_biomaterialprop to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_biomaterialprop() RETURNS trigger AS
   '
   DECLARE
       biomaterialprop_id_var integer; 
       biomaterial_id_var integer; 
       type_id_var integer; 
       value_var text; 
       rank_var integer; 
       
       transaction_type_var char;
   BEGIN
       biomaterialprop_id_var = OLD.biomaterialprop_id;
       biomaterial_id_var = OLD.biomaterial_id;
       type_id_var = OLD.type_id;
       value_var = OLD.value;
       rank_var = OLD.rank;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_biomaterialprop ( 
             biomaterialprop_id, 
             biomaterial_id, 
             type_id, 
             value, 
             rank, 
             transaction_type
       ) VALUES ( 
             biomaterialprop_id_var, 
             biomaterial_id_var, 
             type_id_var, 
             value_var, 
             rank_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER biomaterialprop_audit_ud ON biomaterialprop;
   CREATE TRIGGER biomaterialprop_audit_ud
       BEFORE UPDATE OR DELETE ON biomaterialprop
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_biomaterialprop ();


   DROP TABLE audit_biomaterial_dbxref;
   CREATE TABLE audit_biomaterial_dbxref ( 
       biomaterial_dbxref_id integer, 
       biomaterial_id integer, 
       dbxref_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_biomaterial_dbxref to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_biomaterial_dbxref() RETURNS trigger AS
   '
   DECLARE
       biomaterial_dbxref_id_var integer; 
       biomaterial_id_var integer; 
       dbxref_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       biomaterial_dbxref_id_var = OLD.biomaterial_dbxref_id;
       biomaterial_id_var = OLD.biomaterial_id;
       dbxref_id_var = OLD.dbxref_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_biomaterial_dbxref ( 
             biomaterial_dbxref_id, 
             biomaterial_id, 
             dbxref_id, 
             transaction_type
       ) VALUES ( 
             biomaterial_dbxref_id_var, 
             biomaterial_id_var, 
             dbxref_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER biomaterial_dbxref_audit_ud ON biomaterial_dbxref;
   CREATE TRIGGER biomaterial_dbxref_audit_ud
       BEFORE UPDATE OR DELETE ON biomaterial_dbxref
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_biomaterial_dbxref ();


   DROP TABLE audit_treatment;
   CREATE TABLE audit_treatment ( 
       treatment_id integer, 
       rank integer, 
       biomaterial_id integer, 
       type_id integer, 
       protocol_id integer, 
       name text, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_treatment to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_treatment() RETURNS trigger AS
   '
   DECLARE
       treatment_id_var integer; 
       rank_var integer; 
       biomaterial_id_var integer; 
       type_id_var integer; 
       protocol_id_var integer; 
       name_var text; 
       
       transaction_type_var char;
   BEGIN
       treatment_id_var = OLD.treatment_id;
       rank_var = OLD.rank;
       biomaterial_id_var = OLD.biomaterial_id;
       type_id_var = OLD.type_id;
       protocol_id_var = OLD.protocol_id;
       name_var = OLD.name;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_treatment ( 
             treatment_id, 
             rank, 
             biomaterial_id, 
             type_id, 
             protocol_id, 
             name, 
             transaction_type
       ) VALUES ( 
             treatment_id_var, 
             rank_var, 
             biomaterial_id_var, 
             type_id_var, 
             protocol_id_var, 
             name_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER treatment_audit_ud ON treatment;
   CREATE TRIGGER treatment_audit_ud
       BEFORE UPDATE OR DELETE ON treatment
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_treatment ();


   DROP TABLE audit_biomaterial_treatment;
   CREATE TABLE audit_biomaterial_treatment ( 
       biomaterial_treatment_id integer, 
       biomaterial_id integer, 
       treatment_id integer, 
       unittype_id integer, 
       value float, 
       rank integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_biomaterial_treatment to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_biomaterial_treatment() RETURNS trigger AS
   '
   DECLARE
       biomaterial_treatment_id_var integer; 
       biomaterial_id_var integer; 
       treatment_id_var integer; 
       unittype_id_var integer; 
       value_var float; 
       rank_var integer; 
       
       transaction_type_var char;
   BEGIN
       biomaterial_treatment_id_var = OLD.biomaterial_treatment_id;
       biomaterial_id_var = OLD.biomaterial_id;
       treatment_id_var = OLD.treatment_id;
       unittype_id_var = OLD.unittype_id;
       value_var = OLD.value;
       rank_var = OLD.rank;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_biomaterial_treatment ( 
             biomaterial_treatment_id, 
             biomaterial_id, 
             treatment_id, 
             unittype_id, 
             value, 
             rank, 
             transaction_type
       ) VALUES ( 
             biomaterial_treatment_id_var, 
             biomaterial_id_var, 
             treatment_id_var, 
             unittype_id_var, 
             value_var, 
             rank_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER biomaterial_treatment_audit_ud ON biomaterial_treatment;
   CREATE TRIGGER biomaterial_treatment_audit_ud
       BEFORE UPDATE OR DELETE ON biomaterial_treatment
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_biomaterial_treatment ();


   DROP TABLE audit_assay_biomaterial;
   CREATE TABLE audit_assay_biomaterial ( 
       assay_biomaterial_id integer, 
       assay_id integer, 
       biomaterial_id integer, 
       channel_id integer, 
       rank integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_assay_biomaterial to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_assay_biomaterial() RETURNS trigger AS
   '
   DECLARE
       assay_biomaterial_id_var integer; 
       assay_id_var integer; 
       biomaterial_id_var integer; 
       channel_id_var integer; 
       rank_var integer; 
       
       transaction_type_var char;
   BEGIN
       assay_biomaterial_id_var = OLD.assay_biomaterial_id;
       assay_id_var = OLD.assay_id;
       biomaterial_id_var = OLD.biomaterial_id;
       channel_id_var = OLD.channel_id;
       rank_var = OLD.rank;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_assay_biomaterial ( 
             assay_biomaterial_id, 
             assay_id, 
             biomaterial_id, 
             channel_id, 
             rank, 
             transaction_type
       ) VALUES ( 
             assay_biomaterial_id_var, 
             assay_id_var, 
             biomaterial_id_var, 
             channel_id_var, 
             rank_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER assay_biomaterial_audit_ud ON assay_biomaterial;
   CREATE TRIGGER assay_biomaterial_audit_ud
       BEFORE UPDATE OR DELETE ON assay_biomaterial
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_assay_biomaterial ();


   DROP TABLE audit_acquisition;
   CREATE TABLE audit_acquisition ( 
       acquisition_id integer, 
       assay_id integer, 
       protocol_id integer, 
       channel_id integer, 
       acquisitiondate timestamp, 
       name text, 
       uri text, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_acquisition to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_acquisition() RETURNS trigger AS
   '
   DECLARE
       acquisition_id_var integer; 
       assay_id_var integer; 
       protocol_id_var integer; 
       channel_id_var integer; 
       acquisitiondate_var timestamp; 
       name_var text; 
       uri_var text; 
       
       transaction_type_var char;
   BEGIN
       acquisition_id_var = OLD.acquisition_id;
       assay_id_var = OLD.assay_id;
       protocol_id_var = OLD.protocol_id;
       channel_id_var = OLD.channel_id;
       acquisitiondate_var = OLD.acquisitiondate;
       name_var = OLD.name;
       uri_var = OLD.uri;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_acquisition ( 
             acquisition_id, 
             assay_id, 
             protocol_id, 
             channel_id, 
             acquisitiondate, 
             name, 
             uri, 
             transaction_type
       ) VALUES ( 
             acquisition_id_var, 
             assay_id_var, 
             protocol_id_var, 
             channel_id_var, 
             acquisitiondate_var, 
             name_var, 
             uri_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER acquisition_audit_ud ON acquisition;
   CREATE TRIGGER acquisition_audit_ud
       BEFORE UPDATE OR DELETE ON acquisition
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_acquisition ();


   DROP TABLE audit_acquisitionprop;
   CREATE TABLE audit_acquisitionprop ( 
       acquisitionprop_id integer, 
       acquisition_id integer, 
       type_id integer, 
       value text, 
       rank integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_acquisitionprop to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_acquisitionprop() RETURNS trigger AS
   '
   DECLARE
       acquisitionprop_id_var integer; 
       acquisition_id_var integer; 
       type_id_var integer; 
       value_var text; 
       rank_var integer; 
       
       transaction_type_var char;
   BEGIN
       acquisitionprop_id_var = OLD.acquisitionprop_id;
       acquisition_id_var = OLD.acquisition_id;
       type_id_var = OLD.type_id;
       value_var = OLD.value;
       rank_var = OLD.rank;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_acquisitionprop ( 
             acquisitionprop_id, 
             acquisition_id, 
             type_id, 
             value, 
             rank, 
             transaction_type
       ) VALUES ( 
             acquisitionprop_id_var, 
             acquisition_id_var, 
             type_id_var, 
             value_var, 
             rank_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER acquisitionprop_audit_ud ON acquisitionprop;
   CREATE TRIGGER acquisitionprop_audit_ud
       BEFORE UPDATE OR DELETE ON acquisitionprop
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_acquisitionprop ();


   DROP TABLE audit_acquisition_relationship;
   CREATE TABLE audit_acquisition_relationship ( 
       acquisition_relationship_id integer, 
       subject_id integer, 
       type_id integer, 
       object_id integer, 
       value text, 
       rank integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_acquisition_relationship to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_acquisition_relationship() RETURNS trigger AS
   '
   DECLARE
       acquisition_relationship_id_var integer; 
       subject_id_var integer; 
       type_id_var integer; 
       object_id_var integer; 
       value_var text; 
       rank_var integer; 
       
       transaction_type_var char;
   BEGIN
       acquisition_relationship_id_var = OLD.acquisition_relationship_id;
       subject_id_var = OLD.subject_id;
       type_id_var = OLD.type_id;
       object_id_var = OLD.object_id;
       value_var = OLD.value;
       rank_var = OLD.rank;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_acquisition_relationship ( 
             acquisition_relationship_id, 
             subject_id, 
             type_id, 
             object_id, 
             value, 
             rank, 
             transaction_type
       ) VALUES ( 
             acquisition_relationship_id_var, 
             subject_id_var, 
             type_id_var, 
             object_id_var, 
             value_var, 
             rank_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER acquisition_relationship_audit_ud ON acquisition_relationship;
   CREATE TRIGGER acquisition_relationship_audit_ud
       BEFORE UPDATE OR DELETE ON acquisition_relationship
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_acquisition_relationship ();


   DROP TABLE audit_quantification;
   CREATE TABLE audit_quantification ( 
       quantification_id integer, 
       acquisition_id integer, 
       operator_id integer, 
       protocol_id integer, 
       analysis_id integer, 
       quantificationdate timestamp, 
       name text, 
       uri text, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_quantification to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_quantification() RETURNS trigger AS
   '
   DECLARE
       quantification_id_var integer; 
       acquisition_id_var integer; 
       operator_id_var integer; 
       protocol_id_var integer; 
       analysis_id_var integer; 
       quantificationdate_var timestamp; 
       name_var text; 
       uri_var text; 
       
       transaction_type_var char;
   BEGIN
       quantification_id_var = OLD.quantification_id;
       acquisition_id_var = OLD.acquisition_id;
       operator_id_var = OLD.operator_id;
       protocol_id_var = OLD.protocol_id;
       analysis_id_var = OLD.analysis_id;
       quantificationdate_var = OLD.quantificationdate;
       name_var = OLD.name;
       uri_var = OLD.uri;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_quantification ( 
             quantification_id, 
             acquisition_id, 
             operator_id, 
             protocol_id, 
             analysis_id, 
             quantificationdate, 
             name, 
             uri, 
             transaction_type
       ) VALUES ( 
             quantification_id_var, 
             acquisition_id_var, 
             operator_id_var, 
             protocol_id_var, 
             analysis_id_var, 
             quantificationdate_var, 
             name_var, 
             uri_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER quantification_audit_ud ON quantification;
   CREATE TRIGGER quantification_audit_ud
       BEFORE UPDATE OR DELETE ON quantification
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_quantification ();


   DROP TABLE audit_quantificationprop;
   CREATE TABLE audit_quantificationprop ( 
       quantificationprop_id integer, 
       quantification_id integer, 
       type_id integer, 
       value text, 
       rank integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_quantificationprop to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_quantificationprop() RETURNS trigger AS
   '
   DECLARE
       quantificationprop_id_var integer; 
       quantification_id_var integer; 
       type_id_var integer; 
       value_var text; 
       rank_var integer; 
       
       transaction_type_var char;
   BEGIN
       quantificationprop_id_var = OLD.quantificationprop_id;
       quantification_id_var = OLD.quantification_id;
       type_id_var = OLD.type_id;
       value_var = OLD.value;
       rank_var = OLD.rank;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_quantificationprop ( 
             quantificationprop_id, 
             quantification_id, 
             type_id, 
             value, 
             rank, 
             transaction_type
       ) VALUES ( 
             quantificationprop_id_var, 
             quantification_id_var, 
             type_id_var, 
             value_var, 
             rank_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER quantificationprop_audit_ud ON quantificationprop;
   CREATE TRIGGER quantificationprop_audit_ud
       BEFORE UPDATE OR DELETE ON quantificationprop
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_quantificationprop ();


   DROP TABLE audit_quantification_relationship;
   CREATE TABLE audit_quantification_relationship ( 
       quantification_relationship_id integer, 
       subject_id integer, 
       type_id integer, 
       object_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_quantification_relationship to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_quantification_relationship() RETURNS trigger AS
   '
   DECLARE
       quantification_relationship_id_var integer; 
       subject_id_var integer; 
       type_id_var integer; 
       object_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       quantification_relationship_id_var = OLD.quantification_relationship_id;
       subject_id_var = OLD.subject_id;
       type_id_var = OLD.type_id;
       object_id_var = OLD.object_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_quantification_relationship ( 
             quantification_relationship_id, 
             subject_id, 
             type_id, 
             object_id, 
             transaction_type
       ) VALUES ( 
             quantification_relationship_id_var, 
             subject_id_var, 
             type_id_var, 
             object_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER quantification_relationship_audit_ud ON quantification_relationship;
   CREATE TRIGGER quantification_relationship_audit_ud
       BEFORE UPDATE OR DELETE ON quantification_relationship
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_quantification_relationship ();


   DROP TABLE audit_control;
   CREATE TABLE audit_control ( 
       control_id integer, 
       type_id integer, 
       assay_id integer, 
       tableinfo_id integer, 
       row_id integer, 
       name text, 
       value text, 
       rank integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_control to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_control() RETURNS trigger AS
   '
   DECLARE
       control_id_var integer; 
       type_id_var integer; 
       assay_id_var integer; 
       tableinfo_id_var integer; 
       row_id_var integer; 
       name_var text; 
       value_var text; 
       rank_var integer; 
       
       transaction_type_var char;
   BEGIN
       control_id_var = OLD.control_id;
       type_id_var = OLD.type_id;
       assay_id_var = OLD.assay_id;
       tableinfo_id_var = OLD.tableinfo_id;
       row_id_var = OLD.row_id;
       name_var = OLD.name;
       value_var = OLD.value;
       rank_var = OLD.rank;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_control ( 
             control_id, 
             type_id, 
             assay_id, 
             tableinfo_id, 
             row_id, 
             name, 
             value, 
             rank, 
             transaction_type
       ) VALUES ( 
             control_id_var, 
             type_id_var, 
             assay_id_var, 
             tableinfo_id_var, 
             row_id_var, 
             name_var, 
             value_var, 
             rank_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER control_audit_ud ON control;
   CREATE TRIGGER control_audit_ud
       BEFORE UPDATE OR DELETE ON control
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_control ();


   DROP TABLE audit_element;
   CREATE TABLE audit_element ( 
       element_id integer, 
       feature_id integer, 
       arraydesign_id integer, 
       type_id integer, 
       dbxref_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_element to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_element() RETURNS trigger AS
   '
   DECLARE
       element_id_var integer; 
       feature_id_var integer; 
       arraydesign_id_var integer; 
       type_id_var integer; 
       dbxref_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       element_id_var = OLD.element_id;
       feature_id_var = OLD.feature_id;
       arraydesign_id_var = OLD.arraydesign_id;
       type_id_var = OLD.type_id;
       dbxref_id_var = OLD.dbxref_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_element ( 
             element_id, 
             feature_id, 
             arraydesign_id, 
             type_id, 
             dbxref_id, 
             transaction_type
       ) VALUES ( 
             element_id_var, 
             feature_id_var, 
             arraydesign_id_var, 
             type_id_var, 
             dbxref_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER element_audit_ud ON element;
   CREATE TRIGGER element_audit_ud
       BEFORE UPDATE OR DELETE ON element
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_element ();


   DROP TABLE audit_elementresult;
   CREATE TABLE audit_elementresult ( 
       elementresult_id integer, 
       element_id integer, 
       quantification_id integer, 
       signal float, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_elementresult to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_elementresult() RETURNS trigger AS
   '
   DECLARE
       elementresult_id_var integer; 
       element_id_var integer; 
       quantification_id_var integer; 
       signal_var float; 
       
       transaction_type_var char;
   BEGIN
       elementresult_id_var = OLD.elementresult_id;
       element_id_var = OLD.element_id;
       quantification_id_var = OLD.quantification_id;
       signal_var = OLD.signal;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_elementresult ( 
             elementresult_id, 
             element_id, 
             quantification_id, 
             signal, 
             transaction_type
       ) VALUES ( 
             elementresult_id_var, 
             element_id_var, 
             quantification_id_var, 
             signal_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER elementresult_audit_ud ON elementresult;
   CREATE TRIGGER elementresult_audit_ud
       BEFORE UPDATE OR DELETE ON elementresult
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_elementresult ();


   DROP TABLE audit_element_relationship;
   CREATE TABLE audit_element_relationship ( 
       element_relationship_id integer, 
       subject_id integer, 
       type_id integer, 
       object_id integer, 
       value text, 
       rank integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_element_relationship to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_element_relationship() RETURNS trigger AS
   '
   DECLARE
       element_relationship_id_var integer; 
       subject_id_var integer; 
       type_id_var integer; 
       object_id_var integer; 
       value_var text; 
       rank_var integer; 
       
       transaction_type_var char;
   BEGIN
       element_relationship_id_var = OLD.element_relationship_id;
       subject_id_var = OLD.subject_id;
       type_id_var = OLD.type_id;
       object_id_var = OLD.object_id;
       value_var = OLD.value;
       rank_var = OLD.rank;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_element_relationship ( 
             element_relationship_id, 
             subject_id, 
             type_id, 
             object_id, 
             value, 
             rank, 
             transaction_type
       ) VALUES ( 
             element_relationship_id_var, 
             subject_id_var, 
             type_id_var, 
             object_id_var, 
             value_var, 
             rank_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER element_relationship_audit_ud ON element_relationship;
   CREATE TRIGGER element_relationship_audit_ud
       BEFORE UPDATE OR DELETE ON element_relationship
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_element_relationship ();


   DROP TABLE audit_elementresult_relationship;
   CREATE TABLE audit_elementresult_relationship ( 
       elementresult_relationship_id integer, 
       subject_id integer, 
       type_id integer, 
       object_id integer, 
       value text, 
       rank integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_elementresult_relationship to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_elementresult_relationship() RETURNS trigger AS
   '
   DECLARE
       elementresult_relationship_id_var integer; 
       subject_id_var integer; 
       type_id_var integer; 
       object_id_var integer; 
       value_var text; 
       rank_var integer; 
       
       transaction_type_var char;
   BEGIN
       elementresult_relationship_id_var = OLD.elementresult_relationship_id;
       subject_id_var = OLD.subject_id;
       type_id_var = OLD.type_id;
       object_id_var = OLD.object_id;
       value_var = OLD.value;
       rank_var = OLD.rank;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_elementresult_relationship ( 
             elementresult_relationship_id, 
             subject_id, 
             type_id, 
             object_id, 
             value, 
             rank, 
             transaction_type
       ) VALUES ( 
             elementresult_relationship_id_var, 
             subject_id_var, 
             type_id_var, 
             object_id_var, 
             value_var, 
             rank_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER elementresult_relationship_audit_ud ON elementresult_relationship;
   CREATE TRIGGER elementresult_relationship_audit_ud
       BEFORE UPDATE OR DELETE ON elementresult_relationship
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_elementresult_relationship ();


   DROP TABLE audit_study;
   CREATE TABLE audit_study ( 
       study_id integer, 
       contact_id integer, 
       pub_id integer, 
       dbxref_id integer, 
       name text, 
       description text, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_study to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_study() RETURNS trigger AS
   '
   DECLARE
       study_id_var integer; 
       contact_id_var integer; 
       pub_id_var integer; 
       dbxref_id_var integer; 
       name_var text; 
       description_var text; 
       
       transaction_type_var char;
   BEGIN
       study_id_var = OLD.study_id;
       contact_id_var = OLD.contact_id;
       pub_id_var = OLD.pub_id;
       dbxref_id_var = OLD.dbxref_id;
       name_var = OLD.name;
       description_var = OLD.description;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_study ( 
             study_id, 
             contact_id, 
             pub_id, 
             dbxref_id, 
             name, 
             description, 
             transaction_type
       ) VALUES ( 
             study_id_var, 
             contact_id_var, 
             pub_id_var, 
             dbxref_id_var, 
             name_var, 
             description_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER study_audit_ud ON study;
   CREATE TRIGGER study_audit_ud
       BEFORE UPDATE OR DELETE ON study
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_study ();


   DROP TABLE audit_study_assay;
   CREATE TABLE audit_study_assay ( 
       study_assay_id integer, 
       study_id integer, 
       assay_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_study_assay to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_study_assay() RETURNS trigger AS
   '
   DECLARE
       study_assay_id_var integer; 
       study_id_var integer; 
       assay_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       study_assay_id_var = OLD.study_assay_id;
       study_id_var = OLD.study_id;
       assay_id_var = OLD.assay_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_study_assay ( 
             study_assay_id, 
             study_id, 
             assay_id, 
             transaction_type
       ) VALUES ( 
             study_assay_id_var, 
             study_id_var, 
             assay_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER study_assay_audit_ud ON study_assay;
   CREATE TRIGGER study_assay_audit_ud
       BEFORE UPDATE OR DELETE ON study_assay
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_study_assay ();


   DROP TABLE audit_studydesign;
   CREATE TABLE audit_studydesign ( 
       studydesign_id integer, 
       study_id integer, 
       description text, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_studydesign to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_studydesign() RETURNS trigger AS
   '
   DECLARE
       studydesign_id_var integer; 
       study_id_var integer; 
       description_var text; 
       
       transaction_type_var char;
   BEGIN
       studydesign_id_var = OLD.studydesign_id;
       study_id_var = OLD.study_id;
       description_var = OLD.description;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_studydesign ( 
             studydesign_id, 
             study_id, 
             description, 
             transaction_type
       ) VALUES ( 
             studydesign_id_var, 
             study_id_var, 
             description_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER studydesign_audit_ud ON studydesign;
   CREATE TRIGGER studydesign_audit_ud
       BEFORE UPDATE OR DELETE ON studydesign
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_studydesign ();


   DROP TABLE audit_studydesignprop;
   CREATE TABLE audit_studydesignprop ( 
       studydesignprop_id integer, 
       studydesign_id integer, 
       type_id integer, 
       value text, 
       rank integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_studydesignprop to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_studydesignprop() RETURNS trigger AS
   '
   DECLARE
       studydesignprop_id_var integer; 
       studydesign_id_var integer; 
       type_id_var integer; 
       value_var text; 
       rank_var integer; 
       
       transaction_type_var char;
   BEGIN
       studydesignprop_id_var = OLD.studydesignprop_id;
       studydesign_id_var = OLD.studydesign_id;
       type_id_var = OLD.type_id;
       value_var = OLD.value;
       rank_var = OLD.rank;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_studydesignprop ( 
             studydesignprop_id, 
             studydesign_id, 
             type_id, 
             value, 
             rank, 
             transaction_type
       ) VALUES ( 
             studydesignprop_id_var, 
             studydesign_id_var, 
             type_id_var, 
             value_var, 
             rank_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER studydesignprop_audit_ud ON studydesignprop;
   CREATE TRIGGER studydesignprop_audit_ud
       BEFORE UPDATE OR DELETE ON studydesignprop
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_studydesignprop ();


   DROP TABLE audit_studyfactor;
   CREATE TABLE audit_studyfactor ( 
       studyfactor_id integer, 
       studydesign_id integer, 
       type_id integer, 
       name text, 
       description text, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_studyfactor to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_studyfactor() RETURNS trigger AS
   '
   DECLARE
       studyfactor_id_var integer; 
       studydesign_id_var integer; 
       type_id_var integer; 
       name_var text; 
       description_var text; 
       
       transaction_type_var char;
   BEGIN
       studyfactor_id_var = OLD.studyfactor_id;
       studydesign_id_var = OLD.studydesign_id;
       type_id_var = OLD.type_id;
       name_var = OLD.name;
       description_var = OLD.description;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_studyfactor ( 
             studyfactor_id, 
             studydesign_id, 
             type_id, 
             name, 
             description, 
             transaction_type
       ) VALUES ( 
             studyfactor_id_var, 
             studydesign_id_var, 
             type_id_var, 
             name_var, 
             description_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER studyfactor_audit_ud ON studyfactor;
   CREATE TRIGGER studyfactor_audit_ud
       BEFORE UPDATE OR DELETE ON studyfactor
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_studyfactor ();


   DROP TABLE audit_studyfactorvalue;
   CREATE TABLE audit_studyfactorvalue ( 
       studyfactorvalue_id integer, 
       studyfactor_id integer, 
       assay_id integer, 
       factorvalue text, 
       name text, 
       rank integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_studyfactorvalue to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_studyfactorvalue() RETURNS trigger AS
   '
   DECLARE
       studyfactorvalue_id_var integer; 
       studyfactor_id_var integer; 
       assay_id_var integer; 
       factorvalue_var text; 
       name_var text; 
       rank_var integer; 
       
       transaction_type_var char;
   BEGIN
       studyfactorvalue_id_var = OLD.studyfactorvalue_id;
       studyfactor_id_var = OLD.studyfactor_id;
       assay_id_var = OLD.assay_id;
       factorvalue_var = OLD.factorvalue;
       name_var = OLD.name;
       rank_var = OLD.rank;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_studyfactorvalue ( 
             studyfactorvalue_id, 
             studyfactor_id, 
             assay_id, 
             factorvalue, 
             name, 
             rank, 
             transaction_type
       ) VALUES ( 
             studyfactorvalue_id_var, 
             studyfactor_id_var, 
             assay_id_var, 
             factorvalue_var, 
             name_var, 
             rank_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER studyfactorvalue_audit_ud ON studyfactorvalue;
   CREATE TRIGGER studyfactorvalue_audit_ud
       BEFORE UPDATE OR DELETE ON studyfactorvalue
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_studyfactorvalue ();


   DROP TABLE audit_studyprop;
   CREATE TABLE audit_studyprop ( 
       studyprop_id integer, 
       study_id integer, 
       type_id integer, 
       value text, 
       rank integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_studyprop to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_studyprop() RETURNS trigger AS
   '
   DECLARE
       studyprop_id_var integer; 
       study_id_var integer; 
       type_id_var integer; 
       value_var text; 
       rank_var integer; 
       
       transaction_type_var char;
   BEGIN
       studyprop_id_var = OLD.studyprop_id;
       study_id_var = OLD.study_id;
       type_id_var = OLD.type_id;
       value_var = OLD.value;
       rank_var = OLD.rank;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_studyprop ( 
             studyprop_id, 
             study_id, 
             type_id, 
             value, 
             rank, 
             transaction_type
       ) VALUES ( 
             studyprop_id_var, 
             study_id_var, 
             type_id_var, 
             value_var, 
             rank_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER studyprop_audit_ud ON studyprop;
   CREATE TRIGGER studyprop_audit_ud
       BEFORE UPDATE OR DELETE ON studyprop
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_studyprop ();


   DROP TABLE audit_studyprop_feature;
   CREATE TABLE audit_studyprop_feature ( 
       studyprop_feature_id integer, 
       studyprop_id integer, 
       feature_id integer, 
       type_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_studyprop_feature to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_studyprop_feature() RETURNS trigger AS
   '
   DECLARE
       studyprop_feature_id_var integer; 
       studyprop_id_var integer; 
       feature_id_var integer; 
       type_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       studyprop_feature_id_var = OLD.studyprop_feature_id;
       studyprop_id_var = OLD.studyprop_id;
       feature_id_var = OLD.feature_id;
       type_id_var = OLD.type_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_studyprop_feature ( 
             studyprop_feature_id, 
             studyprop_id, 
             feature_id, 
             type_id, 
             transaction_type
       ) VALUES ( 
             studyprop_feature_id_var, 
             studyprop_id_var, 
             feature_id_var, 
             type_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER studyprop_feature_audit_ud ON studyprop_feature;
   CREATE TRIGGER studyprop_feature_audit_ud
       BEFORE UPDATE OR DELETE ON studyprop_feature
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_studyprop_feature ();


   DROP TABLE audit_stock;
   CREATE TABLE audit_stock ( 
       stock_id integer, 
       dbxref_id integer, 
       organism_id integer, 
       name varchar(255), 
       uniquename text, 
       description text, 
       type_id integer, 
       is_obsolete boolean, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_stock to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_stock() RETURNS trigger AS
   '
   DECLARE
       stock_id_var integer; 
       dbxref_id_var integer; 
       organism_id_var integer; 
       name_var varchar(255); 
       uniquename_var text; 
       description_var text; 
       type_id_var integer; 
       is_obsolete_var boolean; 
       
       transaction_type_var char;
   BEGIN
       stock_id_var = OLD.stock_id;
       dbxref_id_var = OLD.dbxref_id;
       organism_id_var = OLD.organism_id;
       name_var = OLD.name;
       uniquename_var = OLD.uniquename;
       description_var = OLD.description;
       type_id_var = OLD.type_id;
       is_obsolete_var = OLD.is_obsolete;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_stock ( 
             stock_id, 
             dbxref_id, 
             organism_id, 
             name, 
             uniquename, 
             description, 
             type_id, 
             is_obsolete, 
             transaction_type
       ) VALUES ( 
             stock_id_var, 
             dbxref_id_var, 
             organism_id_var, 
             name_var, 
             uniquename_var, 
             description_var, 
             type_id_var, 
             is_obsolete_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER stock_audit_ud ON stock;
   CREATE TRIGGER stock_audit_ud
       BEFORE UPDATE OR DELETE ON stock
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_stock ();


   DROP TABLE audit_stock_pub;
   CREATE TABLE audit_stock_pub ( 
       stock_pub_id integer, 
       stock_id integer, 
       pub_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_stock_pub to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_stock_pub() RETURNS trigger AS
   '
   DECLARE
       stock_pub_id_var integer; 
       stock_id_var integer; 
       pub_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       stock_pub_id_var = OLD.stock_pub_id;
       stock_id_var = OLD.stock_id;
       pub_id_var = OLD.pub_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_stock_pub ( 
             stock_pub_id, 
             stock_id, 
             pub_id, 
             transaction_type
       ) VALUES ( 
             stock_pub_id_var, 
             stock_id_var, 
             pub_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER stock_pub_audit_ud ON stock_pub;
   CREATE TRIGGER stock_pub_audit_ud
       BEFORE UPDATE OR DELETE ON stock_pub
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_stock_pub ();


   DROP TABLE audit_stockprop;
   CREATE TABLE audit_stockprop ( 
       stockprop_id integer, 
       stock_id integer, 
       type_id integer, 
       value text, 
       rank integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_stockprop to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_stockprop() RETURNS trigger AS
   '
   DECLARE
       stockprop_id_var integer; 
       stock_id_var integer; 
       type_id_var integer; 
       value_var text; 
       rank_var integer; 
       
       transaction_type_var char;
   BEGIN
       stockprop_id_var = OLD.stockprop_id;
       stock_id_var = OLD.stock_id;
       type_id_var = OLD.type_id;
       value_var = OLD.value;
       rank_var = OLD.rank;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_stockprop ( 
             stockprop_id, 
             stock_id, 
             type_id, 
             value, 
             rank, 
             transaction_type
       ) VALUES ( 
             stockprop_id_var, 
             stock_id_var, 
             type_id_var, 
             value_var, 
             rank_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER stockprop_audit_ud ON stockprop;
   CREATE TRIGGER stockprop_audit_ud
       BEFORE UPDATE OR DELETE ON stockprop
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_stockprop ();


   DROP TABLE audit_stockprop_pub;
   CREATE TABLE audit_stockprop_pub ( 
       stockprop_pub_id integer, 
       stockprop_id integer, 
       pub_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_stockprop_pub to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_stockprop_pub() RETURNS trigger AS
   '
   DECLARE
       stockprop_pub_id_var integer; 
       stockprop_id_var integer; 
       pub_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       stockprop_pub_id_var = OLD.stockprop_pub_id;
       stockprop_id_var = OLD.stockprop_id;
       pub_id_var = OLD.pub_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_stockprop_pub ( 
             stockprop_pub_id, 
             stockprop_id, 
             pub_id, 
             transaction_type
       ) VALUES ( 
             stockprop_pub_id_var, 
             stockprop_id_var, 
             pub_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER stockprop_pub_audit_ud ON stockprop_pub;
   CREATE TRIGGER stockprop_pub_audit_ud
       BEFORE UPDATE OR DELETE ON stockprop_pub
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_stockprop_pub ();


   DROP TABLE audit_stock_relationship;
   CREATE TABLE audit_stock_relationship ( 
       stock_relationship_id integer, 
       subject_id integer, 
       object_id integer, 
       type_id integer, 
       value text, 
       rank integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_stock_relationship to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_stock_relationship() RETURNS trigger AS
   '
   DECLARE
       stock_relationship_id_var integer; 
       subject_id_var integer; 
       object_id_var integer; 
       type_id_var integer; 
       value_var text; 
       rank_var integer; 
       
       transaction_type_var char;
   BEGIN
       stock_relationship_id_var = OLD.stock_relationship_id;
       subject_id_var = OLD.subject_id;
       object_id_var = OLD.object_id;
       type_id_var = OLD.type_id;
       value_var = OLD.value;
       rank_var = OLD.rank;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_stock_relationship ( 
             stock_relationship_id, 
             subject_id, 
             object_id, 
             type_id, 
             value, 
             rank, 
             transaction_type
       ) VALUES ( 
             stock_relationship_id_var, 
             subject_id_var, 
             object_id_var, 
             type_id_var, 
             value_var, 
             rank_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER stock_relationship_audit_ud ON stock_relationship;
   CREATE TRIGGER stock_relationship_audit_ud
       BEFORE UPDATE OR DELETE ON stock_relationship
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_stock_relationship ();


   DROP TABLE audit_stock_relationship_cvterm;
   CREATE TABLE audit_stock_relationship_cvterm ( 
       stock_relationship_cvterm_id integer, 
       stock_relatiohship_id integer, 
       cvterm_id integer, 
       pub_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_stock_relationship_cvterm to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_stock_relationship_cvterm() RETURNS trigger AS
   '
   DECLARE
       stock_relationship_cvterm_id_var integer; 
       stock_relatiohship_id_var integer; 
       cvterm_id_var integer; 
       pub_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       stock_relationship_cvterm_id_var = OLD.stock_relationship_cvterm_id;
       stock_relatiohship_id_var = OLD.stock_relatiohship_id;
       cvterm_id_var = OLD.cvterm_id;
       pub_id_var = OLD.pub_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_stock_relationship_cvterm ( 
             stock_relationship_cvterm_id, 
             stock_relatiohship_id, 
             cvterm_id, 
             pub_id, 
             transaction_type
       ) VALUES ( 
             stock_relationship_cvterm_id_var, 
             stock_relatiohship_id_var, 
             cvterm_id_var, 
             pub_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER stock_relationship_cvterm_audit_ud ON stock_relationship_cvterm;
   CREATE TRIGGER stock_relationship_cvterm_audit_ud
       BEFORE UPDATE OR DELETE ON stock_relationship_cvterm
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_stock_relationship_cvterm ();


   DROP TABLE audit_stock_relationship_pub;
   CREATE TABLE audit_stock_relationship_pub ( 
       stock_relationship_pub_id integer, 
       stock_relationship_id integer, 
       pub_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_stock_relationship_pub to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_stock_relationship_pub() RETURNS trigger AS
   '
   DECLARE
       stock_relationship_pub_id_var integer; 
       stock_relationship_id_var integer; 
       pub_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       stock_relationship_pub_id_var = OLD.stock_relationship_pub_id;
       stock_relationship_id_var = OLD.stock_relationship_id;
       pub_id_var = OLD.pub_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_stock_relationship_pub ( 
             stock_relationship_pub_id, 
             stock_relationship_id, 
             pub_id, 
             transaction_type
       ) VALUES ( 
             stock_relationship_pub_id_var, 
             stock_relationship_id_var, 
             pub_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER stock_relationship_pub_audit_ud ON stock_relationship_pub;
   CREATE TRIGGER stock_relationship_pub_audit_ud
       BEFORE UPDATE OR DELETE ON stock_relationship_pub
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_stock_relationship_pub ();


   DROP TABLE audit_stock_dbxref;
   CREATE TABLE audit_stock_dbxref ( 
       stock_dbxref_id integer, 
       stock_id integer, 
       dbxref_id integer, 
       is_current boolean, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_stock_dbxref to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_stock_dbxref() RETURNS trigger AS
   '
   DECLARE
       stock_dbxref_id_var integer; 
       stock_id_var integer; 
       dbxref_id_var integer; 
       is_current_var boolean; 
       
       transaction_type_var char;
   BEGIN
       stock_dbxref_id_var = OLD.stock_dbxref_id;
       stock_id_var = OLD.stock_id;
       dbxref_id_var = OLD.dbxref_id;
       is_current_var = OLD.is_current;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_stock_dbxref ( 
             stock_dbxref_id, 
             stock_id, 
             dbxref_id, 
             is_current, 
             transaction_type
       ) VALUES ( 
             stock_dbxref_id_var, 
             stock_id_var, 
             dbxref_id_var, 
             is_current_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER stock_dbxref_audit_ud ON stock_dbxref;
   CREATE TRIGGER stock_dbxref_audit_ud
       BEFORE UPDATE OR DELETE ON stock_dbxref
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_stock_dbxref ();


   DROP TABLE audit_stock_cvterm;
   CREATE TABLE audit_stock_cvterm ( 
       stock_cvterm_id integer, 
       stock_id integer, 
       cvterm_id integer, 
       pub_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_stock_cvterm to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_stock_cvterm() RETURNS trigger AS
   '
   DECLARE
       stock_cvterm_id_var integer; 
       stock_id_var integer; 
       cvterm_id_var integer; 
       pub_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       stock_cvterm_id_var = OLD.stock_cvterm_id;
       stock_id_var = OLD.stock_id;
       cvterm_id_var = OLD.cvterm_id;
       pub_id_var = OLD.pub_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_stock_cvterm ( 
             stock_cvterm_id, 
             stock_id, 
             cvterm_id, 
             pub_id, 
             transaction_type
       ) VALUES ( 
             stock_cvterm_id_var, 
             stock_id_var, 
             cvterm_id_var, 
             pub_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER stock_cvterm_audit_ud ON stock_cvterm;
   CREATE TRIGGER stock_cvterm_audit_ud
       BEFORE UPDATE OR DELETE ON stock_cvterm
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_stock_cvterm ();


   DROP TABLE audit_stock_genotype;
   CREATE TABLE audit_stock_genotype ( 
       stock_genotype_id integer, 
       stock_id integer, 
       genotype_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_stock_genotype to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_stock_genotype() RETURNS trigger AS
   '
   DECLARE
       stock_genotype_id_var integer; 
       stock_id_var integer; 
       genotype_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       stock_genotype_id_var = OLD.stock_genotype_id;
       stock_id_var = OLD.stock_id;
       genotype_id_var = OLD.genotype_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_stock_genotype ( 
             stock_genotype_id, 
             stock_id, 
             genotype_id, 
             transaction_type
       ) VALUES ( 
             stock_genotype_id_var, 
             stock_id_var, 
             genotype_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER stock_genotype_audit_ud ON stock_genotype;
   CREATE TRIGGER stock_genotype_audit_ud
       BEFORE UPDATE OR DELETE ON stock_genotype
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_stock_genotype ();


   DROP TABLE audit_stockcollection;
   CREATE TABLE audit_stockcollection ( 
       stockcollection_id integer, 
       type_id integer, 
       contact_id integer, 
       name varchar(255), 
       uniquename text, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_stockcollection to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_stockcollection() RETURNS trigger AS
   '
   DECLARE
       stockcollection_id_var integer; 
       type_id_var integer; 
       contact_id_var integer; 
       name_var varchar(255); 
       uniquename_var text; 
       
       transaction_type_var char;
   BEGIN
       stockcollection_id_var = OLD.stockcollection_id;
       type_id_var = OLD.type_id;
       contact_id_var = OLD.contact_id;
       name_var = OLD.name;
       uniquename_var = OLD.uniquename;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_stockcollection ( 
             stockcollection_id, 
             type_id, 
             contact_id, 
             name, 
             uniquename, 
             transaction_type
       ) VALUES ( 
             stockcollection_id_var, 
             type_id_var, 
             contact_id_var, 
             name_var, 
             uniquename_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER stockcollection_audit_ud ON stockcollection;
   CREATE TRIGGER stockcollection_audit_ud
       BEFORE UPDATE OR DELETE ON stockcollection
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_stockcollection ();


   DROP TABLE audit_stockcollectionprop;
   CREATE TABLE audit_stockcollectionprop ( 
       stockcollectionprop_id integer, 
       stockcollection_id integer, 
       type_id integer, 
       value text, 
       rank integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_stockcollectionprop to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_stockcollectionprop() RETURNS trigger AS
   '
   DECLARE
       stockcollectionprop_id_var integer; 
       stockcollection_id_var integer; 
       type_id_var integer; 
       value_var text; 
       rank_var integer; 
       
       transaction_type_var char;
   BEGIN
       stockcollectionprop_id_var = OLD.stockcollectionprop_id;
       stockcollection_id_var = OLD.stockcollection_id;
       type_id_var = OLD.type_id;
       value_var = OLD.value;
       rank_var = OLD.rank;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_stockcollectionprop ( 
             stockcollectionprop_id, 
             stockcollection_id, 
             type_id, 
             value, 
             rank, 
             transaction_type
       ) VALUES ( 
             stockcollectionprop_id_var, 
             stockcollection_id_var, 
             type_id_var, 
             value_var, 
             rank_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER stockcollectionprop_audit_ud ON stockcollectionprop;
   CREATE TRIGGER stockcollectionprop_audit_ud
       BEFORE UPDATE OR DELETE ON stockcollectionprop
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_stockcollectionprop ();


   DROP TABLE audit_stockcollection_stock;
   CREATE TABLE audit_stockcollection_stock ( 
       stockcollection_stock_id integer, 
       stockcollection_id integer, 
       stock_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_stockcollection_stock to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_stockcollection_stock() RETURNS trigger AS
   '
   DECLARE
       stockcollection_stock_id_var integer; 
       stockcollection_id_var integer; 
       stock_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       stockcollection_stock_id_var = OLD.stockcollection_stock_id;
       stockcollection_id_var = OLD.stockcollection_id;
       stock_id_var = OLD.stock_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_stockcollection_stock ( 
             stockcollection_stock_id, 
             stockcollection_id, 
             stock_id, 
             transaction_type
       ) VALUES ( 
             stockcollection_stock_id_var, 
             stockcollection_id_var, 
             stock_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER stockcollection_stock_audit_ud ON stockcollection_stock;
   CREATE TRIGGER stockcollection_stock_audit_ud
       BEFORE UPDATE OR DELETE ON stockcollection_stock
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_stockcollection_stock ();


   DROP TABLE audit_stock_dbxrefprop;
   CREATE TABLE audit_stock_dbxrefprop ( 
       stock_dbxrefprop_id integer, 
       stock_dbxref_id integer, 
       type_id integer, 
       value text, 
       rank integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_stock_dbxrefprop to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_stock_dbxrefprop() RETURNS trigger AS
   '
   DECLARE
       stock_dbxrefprop_id_var integer; 
       stock_dbxref_id_var integer; 
       type_id_var integer; 
       value_var text; 
       rank_var integer; 
       
       transaction_type_var char;
   BEGIN
       stock_dbxrefprop_id_var = OLD.stock_dbxrefprop_id;
       stock_dbxref_id_var = OLD.stock_dbxref_id;
       type_id_var = OLD.type_id;
       value_var = OLD.value;
       rank_var = OLD.rank;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_stock_dbxrefprop ( 
             stock_dbxrefprop_id, 
             stock_dbxref_id, 
             type_id, 
             value, 
             rank, 
             transaction_type
       ) VALUES ( 
             stock_dbxrefprop_id_var, 
             stock_dbxref_id_var, 
             type_id_var, 
             value_var, 
             rank_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER stock_dbxrefprop_audit_ud ON stock_dbxrefprop;
   CREATE TRIGGER stock_dbxrefprop_audit_ud
       BEFORE UPDATE OR DELETE ON stock_dbxrefprop
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_stock_dbxrefprop ();


   DROP TABLE audit_library;
   CREATE TABLE audit_library ( 
       library_id integer, 
       organism_id integer, 
       name varchar(255), 
       uniquename text, 
       type_id integer, 
       is_obsolete integer, 
       timeaccessioned timestamp, 
       timelastmodified timestamp, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_library to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_library() RETURNS trigger AS
   '
   DECLARE
       library_id_var integer; 
       organism_id_var integer; 
       name_var varchar(255); 
       uniquename_var text; 
       type_id_var integer; 
       is_obsolete_var integer; 
       timeaccessioned_var timestamp; 
       timelastmodified_var timestamp; 
       
       transaction_type_var char;
   BEGIN
       library_id_var = OLD.library_id;
       organism_id_var = OLD.organism_id;
       name_var = OLD.name;
       uniquename_var = OLD.uniquename;
       type_id_var = OLD.type_id;
       is_obsolete_var = OLD.is_obsolete;
       timeaccessioned_var = OLD.timeaccessioned;
       timelastmodified_var = OLD.timelastmodified;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_library ( 
             library_id, 
             organism_id, 
             name, 
             uniquename, 
             type_id, 
             is_obsolete, 
             timeaccessioned, 
             timelastmodified, 
             transaction_type
       ) VALUES ( 
             library_id_var, 
             organism_id_var, 
             name_var, 
             uniquename_var, 
             type_id_var, 
             is_obsolete_var, 
             timeaccessioned_var, 
             timelastmodified_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER library_audit_ud ON library;
   CREATE TRIGGER library_audit_ud
       BEFORE UPDATE OR DELETE ON library
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_library ();


   DROP TABLE audit_library_synonym;
   CREATE TABLE audit_library_synonym ( 
       library_synonym_id integer, 
       synonym_id integer, 
       library_id integer, 
       pub_id integer, 
       is_current boolean, 
       is_internal boolean, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_library_synonym to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_library_synonym() RETURNS trigger AS
   '
   DECLARE
       library_synonym_id_var integer; 
       synonym_id_var integer; 
       library_id_var integer; 
       pub_id_var integer; 
       is_current_var boolean; 
       is_internal_var boolean; 
       
       transaction_type_var char;
   BEGIN
       library_synonym_id_var = OLD.library_synonym_id;
       synonym_id_var = OLD.synonym_id;
       library_id_var = OLD.library_id;
       pub_id_var = OLD.pub_id;
       is_current_var = OLD.is_current;
       is_internal_var = OLD.is_internal;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_library_synonym ( 
             library_synonym_id, 
             synonym_id, 
             library_id, 
             pub_id, 
             is_current, 
             is_internal, 
             transaction_type
       ) VALUES ( 
             library_synonym_id_var, 
             synonym_id_var, 
             library_id_var, 
             pub_id_var, 
             is_current_var, 
             is_internal_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER library_synonym_audit_ud ON library_synonym;
   CREATE TRIGGER library_synonym_audit_ud
       BEFORE UPDATE OR DELETE ON library_synonym
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_library_synonym ();


   DROP TABLE audit_library_pub;
   CREATE TABLE audit_library_pub ( 
       library_pub_id integer, 
       library_id integer, 
       pub_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_library_pub to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_library_pub() RETURNS trigger AS
   '
   DECLARE
       library_pub_id_var integer; 
       library_id_var integer; 
       pub_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       library_pub_id_var = OLD.library_pub_id;
       library_id_var = OLD.library_id;
       pub_id_var = OLD.pub_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_library_pub ( 
             library_pub_id, 
             library_id, 
             pub_id, 
             transaction_type
       ) VALUES ( 
             library_pub_id_var, 
             library_id_var, 
             pub_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER library_pub_audit_ud ON library_pub;
   CREATE TRIGGER library_pub_audit_ud
       BEFORE UPDATE OR DELETE ON library_pub
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_library_pub ();


   DROP TABLE audit_libraryprop;
   CREATE TABLE audit_libraryprop ( 
       libraryprop_id integer, 
       library_id integer, 
       type_id integer, 
       value text, 
       rank integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_libraryprop to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_libraryprop() RETURNS trigger AS
   '
   DECLARE
       libraryprop_id_var integer; 
       library_id_var integer; 
       type_id_var integer; 
       value_var text; 
       rank_var integer; 
       
       transaction_type_var char;
   BEGIN
       libraryprop_id_var = OLD.libraryprop_id;
       library_id_var = OLD.library_id;
       type_id_var = OLD.type_id;
       value_var = OLD.value;
       rank_var = OLD.rank;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_libraryprop ( 
             libraryprop_id, 
             library_id, 
             type_id, 
             value, 
             rank, 
             transaction_type
       ) VALUES ( 
             libraryprop_id_var, 
             library_id_var, 
             type_id_var, 
             value_var, 
             rank_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER libraryprop_audit_ud ON libraryprop;
   CREATE TRIGGER libraryprop_audit_ud
       BEFORE UPDATE OR DELETE ON libraryprop
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_libraryprop ();


   DROP TABLE audit_libraryprop_pub;
   CREATE TABLE audit_libraryprop_pub ( 
       libraryprop_pub_id integer, 
       libraryprop_id integer, 
       pub_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_libraryprop_pub to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_libraryprop_pub() RETURNS trigger AS
   '
   DECLARE
       libraryprop_pub_id_var integer; 
       libraryprop_id_var integer; 
       pub_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       libraryprop_pub_id_var = OLD.libraryprop_pub_id;
       libraryprop_id_var = OLD.libraryprop_id;
       pub_id_var = OLD.pub_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_libraryprop_pub ( 
             libraryprop_pub_id, 
             libraryprop_id, 
             pub_id, 
             transaction_type
       ) VALUES ( 
             libraryprop_pub_id_var, 
             libraryprop_id_var, 
             pub_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER libraryprop_pub_audit_ud ON libraryprop_pub;
   CREATE TRIGGER libraryprop_pub_audit_ud
       BEFORE UPDATE OR DELETE ON libraryprop_pub
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_libraryprop_pub ();


   DROP TABLE audit_library_cvterm;
   CREATE TABLE audit_library_cvterm ( 
       library_cvterm_id integer, 
       library_id integer, 
       cvterm_id integer, 
       pub_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_library_cvterm to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_library_cvterm() RETURNS trigger AS
   '
   DECLARE
       library_cvterm_id_var integer; 
       library_id_var integer; 
       cvterm_id_var integer; 
       pub_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       library_cvterm_id_var = OLD.library_cvterm_id;
       library_id_var = OLD.library_id;
       cvterm_id_var = OLD.cvterm_id;
       pub_id_var = OLD.pub_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_library_cvterm ( 
             library_cvterm_id, 
             library_id, 
             cvterm_id, 
             pub_id, 
             transaction_type
       ) VALUES ( 
             library_cvterm_id_var, 
             library_id_var, 
             cvterm_id_var, 
             pub_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER library_cvterm_audit_ud ON library_cvterm;
   CREATE TRIGGER library_cvterm_audit_ud
       BEFORE UPDATE OR DELETE ON library_cvterm
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_library_cvterm ();


   DROP TABLE audit_library_feature;
   CREATE TABLE audit_library_feature ( 
       library_feature_id integer, 
       library_id integer, 
       feature_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_library_feature to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_library_feature() RETURNS trigger AS
   '
   DECLARE
       library_feature_id_var integer; 
       library_id_var integer; 
       feature_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       library_feature_id_var = OLD.library_feature_id;
       library_id_var = OLD.library_id;
       feature_id_var = OLD.feature_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_library_feature ( 
             library_feature_id, 
             library_id, 
             feature_id, 
             transaction_type
       ) VALUES ( 
             library_feature_id_var, 
             library_id_var, 
             feature_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER library_feature_audit_ud ON library_feature;
   CREATE TRIGGER library_feature_audit_ud
       BEFORE UPDATE OR DELETE ON library_feature
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_library_feature ();


   DROP TABLE audit_library_dbxref;
   CREATE TABLE audit_library_dbxref ( 
       library_dbxref_id integer, 
       library_id integer, 
       dbxref_id integer, 
       is_current boolean, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_library_dbxref to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_library_dbxref() RETURNS trigger AS
   '
   DECLARE
       library_dbxref_id_var integer; 
       library_id_var integer; 
       dbxref_id_var integer; 
       is_current_var boolean; 
       
       transaction_type_var char;
   BEGIN
       library_dbxref_id_var = OLD.library_dbxref_id;
       library_id_var = OLD.library_id;
       dbxref_id_var = OLD.dbxref_id;
       is_current_var = OLD.is_current;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_library_dbxref ( 
             library_dbxref_id, 
             library_id, 
             dbxref_id, 
             is_current, 
             transaction_type
       ) VALUES ( 
             library_dbxref_id_var, 
             library_id_var, 
             dbxref_id_var, 
             is_current_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER library_dbxref_audit_ud ON library_dbxref;
   CREATE TRIGGER library_dbxref_audit_ud
       BEFORE UPDATE OR DELETE ON library_dbxref
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_library_dbxref ();


   DROP TABLE audit_cell_line;
   CREATE TABLE audit_cell_line ( 
       cell_line_id integer, 
       name varchar(255), 
       uniquename varchar(255), 
       organism_id integer, 
       timeaccessioned timestamp, 
       timelastmodified timestamp, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_cell_line to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_cell_line() RETURNS trigger AS
   '
   DECLARE
       cell_line_id_var integer; 
       name_var varchar(255); 
       uniquename_var varchar(255); 
       organism_id_var integer; 
       timeaccessioned_var timestamp; 
       timelastmodified_var timestamp; 
       
       transaction_type_var char;
   BEGIN
       cell_line_id_var = OLD.cell_line_id;
       name_var = OLD.name;
       uniquename_var = OLD.uniquename;
       organism_id_var = OLD.organism_id;
       timeaccessioned_var = OLD.timeaccessioned;
       timelastmodified_var = OLD.timelastmodified;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_cell_line ( 
             cell_line_id, 
             name, 
             uniquename, 
             organism_id, 
             timeaccessioned, 
             timelastmodified, 
             transaction_type
       ) VALUES ( 
             cell_line_id_var, 
             name_var, 
             uniquename_var, 
             organism_id_var, 
             timeaccessioned_var, 
             timelastmodified_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER cell_line_audit_ud ON cell_line;
   CREATE TRIGGER cell_line_audit_ud
       BEFORE UPDATE OR DELETE ON cell_line
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_cell_line ();


   DROP TABLE audit_cell_line_relationship;
   CREATE TABLE audit_cell_line_relationship ( 
       cell_line_relationship_id integer, 
       subject_id integer, 
       object_id integer, 
       type_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_cell_line_relationship to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_cell_line_relationship() RETURNS trigger AS
   '
   DECLARE
       cell_line_relationship_id_var integer; 
       subject_id_var integer; 
       object_id_var integer; 
       type_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       cell_line_relationship_id_var = OLD.cell_line_relationship_id;
       subject_id_var = OLD.subject_id;
       object_id_var = OLD.object_id;
       type_id_var = OLD.type_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_cell_line_relationship ( 
             cell_line_relationship_id, 
             subject_id, 
             object_id, 
             type_id, 
             transaction_type
       ) VALUES ( 
             cell_line_relationship_id_var, 
             subject_id_var, 
             object_id_var, 
             type_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER cell_line_relationship_audit_ud ON cell_line_relationship;
   CREATE TRIGGER cell_line_relationship_audit_ud
       BEFORE UPDATE OR DELETE ON cell_line_relationship
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_cell_line_relationship ();


   DROP TABLE audit_cell_line_synonym;
   CREATE TABLE audit_cell_line_synonym ( 
       cell_line_synonym_id integer, 
       cell_line_id integer, 
       synonym_id integer, 
       pub_id integer, 
       is_current boolean, 
       is_internal boolean, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_cell_line_synonym to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_cell_line_synonym() RETURNS trigger AS
   '
   DECLARE
       cell_line_synonym_id_var integer; 
       cell_line_id_var integer; 
       synonym_id_var integer; 
       pub_id_var integer; 
       is_current_var boolean; 
       is_internal_var boolean; 
       
       transaction_type_var char;
   BEGIN
       cell_line_synonym_id_var = OLD.cell_line_synonym_id;
       cell_line_id_var = OLD.cell_line_id;
       synonym_id_var = OLD.synonym_id;
       pub_id_var = OLD.pub_id;
       is_current_var = OLD.is_current;
       is_internal_var = OLD.is_internal;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_cell_line_synonym ( 
             cell_line_synonym_id, 
             cell_line_id, 
             synonym_id, 
             pub_id, 
             is_current, 
             is_internal, 
             transaction_type
       ) VALUES ( 
             cell_line_synonym_id_var, 
             cell_line_id_var, 
             synonym_id_var, 
             pub_id_var, 
             is_current_var, 
             is_internal_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER cell_line_synonym_audit_ud ON cell_line_synonym;
   CREATE TRIGGER cell_line_synonym_audit_ud
       BEFORE UPDATE OR DELETE ON cell_line_synonym
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_cell_line_synonym ();


   DROP TABLE audit_cell_line_cvterm;
   CREATE TABLE audit_cell_line_cvterm ( 
       cell_line_cvterm_id integer, 
       cell_line_id integer, 
       cvterm_id integer, 
       pub_id integer, 
       rank integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_cell_line_cvterm to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_cell_line_cvterm() RETURNS trigger AS
   '
   DECLARE
       cell_line_cvterm_id_var integer; 
       cell_line_id_var integer; 
       cvterm_id_var integer; 
       pub_id_var integer; 
       rank_var integer; 
       
       transaction_type_var char;
   BEGIN
       cell_line_cvterm_id_var = OLD.cell_line_cvterm_id;
       cell_line_id_var = OLD.cell_line_id;
       cvterm_id_var = OLD.cvterm_id;
       pub_id_var = OLD.pub_id;
       rank_var = OLD.rank;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_cell_line_cvterm ( 
             cell_line_cvterm_id, 
             cell_line_id, 
             cvterm_id, 
             pub_id, 
             rank, 
             transaction_type
       ) VALUES ( 
             cell_line_cvterm_id_var, 
             cell_line_id_var, 
             cvterm_id_var, 
             pub_id_var, 
             rank_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER cell_line_cvterm_audit_ud ON cell_line_cvterm;
   CREATE TRIGGER cell_line_cvterm_audit_ud
       BEFORE UPDATE OR DELETE ON cell_line_cvterm
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_cell_line_cvterm ();


   DROP TABLE audit_cell_line_dbxref;
   CREATE TABLE audit_cell_line_dbxref ( 
       cell_line_dbxref_id integer, 
       cell_line_id integer, 
       dbxref_id integer, 
       is_current boolean, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_cell_line_dbxref to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_cell_line_dbxref() RETURNS trigger AS
   '
   DECLARE
       cell_line_dbxref_id_var integer; 
       cell_line_id_var integer; 
       dbxref_id_var integer; 
       is_current_var boolean; 
       
       transaction_type_var char;
   BEGIN
       cell_line_dbxref_id_var = OLD.cell_line_dbxref_id;
       cell_line_id_var = OLD.cell_line_id;
       dbxref_id_var = OLD.dbxref_id;
       is_current_var = OLD.is_current;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_cell_line_dbxref ( 
             cell_line_dbxref_id, 
             cell_line_id, 
             dbxref_id, 
             is_current, 
             transaction_type
       ) VALUES ( 
             cell_line_dbxref_id_var, 
             cell_line_id_var, 
             dbxref_id_var, 
             is_current_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER cell_line_dbxref_audit_ud ON cell_line_dbxref;
   CREATE TRIGGER cell_line_dbxref_audit_ud
       BEFORE UPDATE OR DELETE ON cell_line_dbxref
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_cell_line_dbxref ();


   DROP TABLE audit_cell_lineprop;
   CREATE TABLE audit_cell_lineprop ( 
       cell_lineprop_id integer, 
       cell_line_id integer, 
       type_id integer, 
       value text, 
       rank integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_cell_lineprop to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_cell_lineprop() RETURNS trigger AS
   '
   DECLARE
       cell_lineprop_id_var integer; 
       cell_line_id_var integer; 
       type_id_var integer; 
       value_var text; 
       rank_var integer; 
       
       transaction_type_var char;
   BEGIN
       cell_lineprop_id_var = OLD.cell_lineprop_id;
       cell_line_id_var = OLD.cell_line_id;
       type_id_var = OLD.type_id;
       value_var = OLD.value;
       rank_var = OLD.rank;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_cell_lineprop ( 
             cell_lineprop_id, 
             cell_line_id, 
             type_id, 
             value, 
             rank, 
             transaction_type
       ) VALUES ( 
             cell_lineprop_id_var, 
             cell_line_id_var, 
             type_id_var, 
             value_var, 
             rank_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER cell_lineprop_audit_ud ON cell_lineprop;
   CREATE TRIGGER cell_lineprop_audit_ud
       BEFORE UPDATE OR DELETE ON cell_lineprop
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_cell_lineprop ();


   DROP TABLE audit_cell_lineprop_pub;
   CREATE TABLE audit_cell_lineprop_pub ( 
       cell_lineprop_pub_id integer, 
       cell_lineprop_id integer, 
       pub_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_cell_lineprop_pub to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_cell_lineprop_pub() RETURNS trigger AS
   '
   DECLARE
       cell_lineprop_pub_id_var integer; 
       cell_lineprop_id_var integer; 
       pub_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       cell_lineprop_pub_id_var = OLD.cell_lineprop_pub_id;
       cell_lineprop_id_var = OLD.cell_lineprop_id;
       pub_id_var = OLD.pub_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_cell_lineprop_pub ( 
             cell_lineprop_pub_id, 
             cell_lineprop_id, 
             pub_id, 
             transaction_type
       ) VALUES ( 
             cell_lineprop_pub_id_var, 
             cell_lineprop_id_var, 
             pub_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER cell_lineprop_pub_audit_ud ON cell_lineprop_pub;
   CREATE TRIGGER cell_lineprop_pub_audit_ud
       BEFORE UPDATE OR DELETE ON cell_lineprop_pub
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_cell_lineprop_pub ();


   DROP TABLE audit_cell_line_feature;
   CREATE TABLE audit_cell_line_feature ( 
       cell_line_feature_id integer, 
       cell_line_id integer, 
       feature_id integer, 
       pub_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_cell_line_feature to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_cell_line_feature() RETURNS trigger AS
   '
   DECLARE
       cell_line_feature_id_var integer; 
       cell_line_id_var integer; 
       feature_id_var integer; 
       pub_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       cell_line_feature_id_var = OLD.cell_line_feature_id;
       cell_line_id_var = OLD.cell_line_id;
       feature_id_var = OLD.feature_id;
       pub_id_var = OLD.pub_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_cell_line_feature ( 
             cell_line_feature_id, 
             cell_line_id, 
             feature_id, 
             pub_id, 
             transaction_type
       ) VALUES ( 
             cell_line_feature_id_var, 
             cell_line_id_var, 
             feature_id_var, 
             pub_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER cell_line_feature_audit_ud ON cell_line_feature;
   CREATE TRIGGER cell_line_feature_audit_ud
       BEFORE UPDATE OR DELETE ON cell_line_feature
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_cell_line_feature ();


   DROP TABLE audit_cell_line_cvtermprop;
   CREATE TABLE audit_cell_line_cvtermprop ( 
       cell_line_cvtermprop_id integer, 
       cell_line_cvterm_id integer, 
       type_id integer, 
       value text, 
       rank integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_cell_line_cvtermprop to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_cell_line_cvtermprop() RETURNS trigger AS
   '
   DECLARE
       cell_line_cvtermprop_id_var integer; 
       cell_line_cvterm_id_var integer; 
       type_id_var integer; 
       value_var text; 
       rank_var integer; 
       
       transaction_type_var char;
   BEGIN
       cell_line_cvtermprop_id_var = OLD.cell_line_cvtermprop_id;
       cell_line_cvterm_id_var = OLD.cell_line_cvterm_id;
       type_id_var = OLD.type_id;
       value_var = OLD.value;
       rank_var = OLD.rank;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_cell_line_cvtermprop ( 
             cell_line_cvtermprop_id, 
             cell_line_cvterm_id, 
             type_id, 
             value, 
             rank, 
             transaction_type
       ) VALUES ( 
             cell_line_cvtermprop_id_var, 
             cell_line_cvterm_id_var, 
             type_id_var, 
             value_var, 
             rank_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER cell_line_cvtermprop_audit_ud ON cell_line_cvtermprop;
   CREATE TRIGGER cell_line_cvtermprop_audit_ud
       BEFORE UPDATE OR DELETE ON cell_line_cvtermprop
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_cell_line_cvtermprop ();


   DROP TABLE audit_cell_line_pub;
   CREATE TABLE audit_cell_line_pub ( 
       cell_line_pub_id integer, 
       cell_line_id integer, 
       pub_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_cell_line_pub to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_cell_line_pub() RETURNS trigger AS
   '
   DECLARE
       cell_line_pub_id_var integer; 
       cell_line_id_var integer; 
       pub_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       cell_line_pub_id_var = OLD.cell_line_pub_id;
       cell_line_id_var = OLD.cell_line_id;
       pub_id_var = OLD.pub_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_cell_line_pub ( 
             cell_line_pub_id, 
             cell_line_id, 
             pub_id, 
             transaction_type
       ) VALUES ( 
             cell_line_pub_id_var, 
             cell_line_id_var, 
             pub_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER cell_line_pub_audit_ud ON cell_line_pub;
   CREATE TRIGGER cell_line_pub_audit_ud
       BEFORE UPDATE OR DELETE ON cell_line_pub
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_cell_line_pub ();


   DROP TABLE audit_cell_line_library;
   CREATE TABLE audit_cell_line_library ( 
       cell_line_library_id integer, 
       cell_line_id integer, 
       library_id integer, 
       pub_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_cell_line_library to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_cell_line_library() RETURNS trigger AS
   '
   DECLARE
       cell_line_library_id_var integer; 
       cell_line_id_var integer; 
       library_id_var integer; 
       pub_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       cell_line_library_id_var = OLD.cell_line_library_id;
       cell_line_id_var = OLD.cell_line_id;
       library_id_var = OLD.library_id;
       pub_id_var = OLD.pub_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_cell_line_library ( 
             cell_line_library_id, 
             cell_line_id, 
             library_id, 
             pub_id, 
             transaction_type
       ) VALUES ( 
             cell_line_library_id_var, 
             cell_line_id_var, 
             library_id_var, 
             pub_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER cell_line_library_audit_ud ON cell_line_library;
   CREATE TRIGGER cell_line_library_audit_ud
       BEFORE UPDATE OR DELETE ON cell_line_library
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_cell_line_library ();


   DROP TABLE audit_nd_geolocation;
   CREATE TABLE audit_nd_geolocation ( 
       nd_geolocation_id integer, 
       description varchar(255), 
       latitude real, 
       longitude real, 
       geodetic_datum varchar(32), 
       altitude real, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_nd_geolocation to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_nd_geolocation() RETURNS trigger AS
   '
   DECLARE
       nd_geolocation_id_var integer; 
       description_var varchar(255); 
       latitude_var real; 
       longitude_var real; 
       geodetic_datum_var varchar(32); 
       altitude_var real; 
       
       transaction_type_var char;
   BEGIN
       nd_geolocation_id_var = OLD.nd_geolocation_id;
       description_var = OLD.description;
       latitude_var = OLD.latitude;
       longitude_var = OLD.longitude;
       geodetic_datum_var = OLD.geodetic_datum;
       altitude_var = OLD.altitude;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_nd_geolocation ( 
             nd_geolocation_id, 
             description, 
             latitude, 
             longitude, 
             geodetic_datum, 
             altitude, 
             transaction_type
       ) VALUES ( 
             nd_geolocation_id_var, 
             description_var, 
             latitude_var, 
             longitude_var, 
             geodetic_datum_var, 
             altitude_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER nd_geolocation_audit_ud ON nd_geolocation;
   CREATE TRIGGER nd_geolocation_audit_ud
       BEFORE UPDATE OR DELETE ON nd_geolocation
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_nd_geolocation ();


   DROP TABLE audit_nd_experiment;
   CREATE TABLE audit_nd_experiment ( 
       nd_experiment_id integer, 
       nd_geolocation_id integer, 
       type_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_nd_experiment to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_nd_experiment() RETURNS trigger AS
   '
   DECLARE
       nd_experiment_id_var integer; 
       nd_geolocation_id_var integer; 
       type_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       nd_experiment_id_var = OLD.nd_experiment_id;
       nd_geolocation_id_var = OLD.nd_geolocation_id;
       type_id_var = OLD.type_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_nd_experiment ( 
             nd_experiment_id, 
             nd_geolocation_id, 
             type_id, 
             transaction_type
       ) VALUES ( 
             nd_experiment_id_var, 
             nd_geolocation_id_var, 
             type_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER nd_experiment_audit_ud ON nd_experiment;
   CREATE TRIGGER nd_experiment_audit_ud
       BEFORE UPDATE OR DELETE ON nd_experiment
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_nd_experiment ();


   DROP TABLE audit_nd_experiment_project;
   CREATE TABLE audit_nd_experiment_project ( 
       nd_experiment_project_id integer, 
       project_id integer, 
       nd_experiment_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_nd_experiment_project to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_nd_experiment_project() RETURNS trigger AS
   '
   DECLARE
       nd_experiment_project_id_var integer; 
       project_id_var integer; 
       nd_experiment_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       nd_experiment_project_id_var = OLD.nd_experiment_project_id;
       project_id_var = OLD.project_id;
       nd_experiment_id_var = OLD.nd_experiment_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_nd_experiment_project ( 
             nd_experiment_project_id, 
             project_id, 
             nd_experiment_id, 
             transaction_type
       ) VALUES ( 
             nd_experiment_project_id_var, 
             project_id_var, 
             nd_experiment_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER nd_experiment_project_audit_ud ON nd_experiment_project;
   CREATE TRIGGER nd_experiment_project_audit_ud
       BEFORE UPDATE OR DELETE ON nd_experiment_project
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_nd_experiment_project ();


   DROP TABLE audit_nd_experimentprop;
   CREATE TABLE audit_nd_experimentprop ( 
       nd_experimentprop_id integer, 
       nd_experiment_id integer, 
       type_id integer, 
       value varchar(255), 
       rank integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_nd_experimentprop to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_nd_experimentprop() RETURNS trigger AS
   '
   DECLARE
       nd_experimentprop_id_var integer; 
       nd_experiment_id_var integer; 
       type_id_var integer; 
       value_var varchar(255); 
       rank_var integer; 
       
       transaction_type_var char;
   BEGIN
       nd_experimentprop_id_var = OLD.nd_experimentprop_id;
       nd_experiment_id_var = OLD.nd_experiment_id;
       type_id_var = OLD.type_id;
       value_var = OLD.value;
       rank_var = OLD.rank;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_nd_experimentprop ( 
             nd_experimentprop_id, 
             nd_experiment_id, 
             type_id, 
             value, 
             rank, 
             transaction_type
       ) VALUES ( 
             nd_experimentprop_id_var, 
             nd_experiment_id_var, 
             type_id_var, 
             value_var, 
             rank_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER nd_experimentprop_audit_ud ON nd_experimentprop;
   CREATE TRIGGER nd_experimentprop_audit_ud
       BEFORE UPDATE OR DELETE ON nd_experimentprop
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_nd_experimentprop ();


   DROP TABLE audit_nd_experiment_pub;
   CREATE TABLE audit_nd_experiment_pub ( 
       nd_experiment_pub_id integer, 
       nd_experiment_id integer, 
       pub_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_nd_experiment_pub to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_nd_experiment_pub() RETURNS trigger AS
   '
   DECLARE
       nd_experiment_pub_id_var integer; 
       nd_experiment_id_var integer; 
       pub_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       nd_experiment_pub_id_var = OLD.nd_experiment_pub_id;
       nd_experiment_id_var = OLD.nd_experiment_id;
       pub_id_var = OLD.pub_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_nd_experiment_pub ( 
             nd_experiment_pub_id, 
             nd_experiment_id, 
             pub_id, 
             transaction_type
       ) VALUES ( 
             nd_experiment_pub_id_var, 
             nd_experiment_id_var, 
             pub_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER nd_experiment_pub_audit_ud ON nd_experiment_pub;
   CREATE TRIGGER nd_experiment_pub_audit_ud
       BEFORE UPDATE OR DELETE ON nd_experiment_pub
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_nd_experiment_pub ();


   DROP TABLE audit_nd_geolocationprop;
   CREATE TABLE audit_nd_geolocationprop ( 
       nd_geolocationprop_id integer, 
       nd_geolocation_id integer, 
       type_id integer, 
       value varchar(250), 
       rank integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_nd_geolocationprop to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_nd_geolocationprop() RETURNS trigger AS
   '
   DECLARE
       nd_geolocationprop_id_var integer; 
       nd_geolocation_id_var integer; 
       type_id_var integer; 
       value_var varchar(250); 
       rank_var integer; 
       
       transaction_type_var char;
   BEGIN
       nd_geolocationprop_id_var = OLD.nd_geolocationprop_id;
       nd_geolocation_id_var = OLD.nd_geolocation_id;
       type_id_var = OLD.type_id;
       value_var = OLD.value;
       rank_var = OLD.rank;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_nd_geolocationprop ( 
             nd_geolocationprop_id, 
             nd_geolocation_id, 
             type_id, 
             value, 
             rank, 
             transaction_type
       ) VALUES ( 
             nd_geolocationprop_id_var, 
             nd_geolocation_id_var, 
             type_id_var, 
             value_var, 
             rank_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER nd_geolocationprop_audit_ud ON nd_geolocationprop;
   CREATE TRIGGER nd_geolocationprop_audit_ud
       BEFORE UPDATE OR DELETE ON nd_geolocationprop
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_nd_geolocationprop ();


   DROP TABLE audit_nd_protocol;
   CREATE TABLE audit_nd_protocol ( 
       nd_protocol_id integer, 
       name varchar(255), 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_nd_protocol to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_nd_protocol() RETURNS trigger AS
   '
   DECLARE
       nd_protocol_id_var integer; 
       name_var varchar(255); 
       
       transaction_type_var char;
   BEGIN
       nd_protocol_id_var = OLD.nd_protocol_id;
       name_var = OLD.name;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_nd_protocol ( 
             nd_protocol_id, 
             name, 
             transaction_type
       ) VALUES ( 
             nd_protocol_id_var, 
             name_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER nd_protocol_audit_ud ON nd_protocol;
   CREATE TRIGGER nd_protocol_audit_ud
       BEFORE UPDATE OR DELETE ON nd_protocol
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_nd_protocol ();


   DROP TABLE audit_nd_reagent;
   CREATE TABLE audit_nd_reagent ( 
       nd_reagent_id integer, 
       name varchar(80), 
       type_id integer, 
       feature_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_nd_reagent to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_nd_reagent() RETURNS trigger AS
   '
   DECLARE
       nd_reagent_id_var integer; 
       name_var varchar(80); 
       type_id_var integer; 
       feature_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       nd_reagent_id_var = OLD.nd_reagent_id;
       name_var = OLD.name;
       type_id_var = OLD.type_id;
       feature_id_var = OLD.feature_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_nd_reagent ( 
             nd_reagent_id, 
             name, 
             type_id, 
             feature_id, 
             transaction_type
       ) VALUES ( 
             nd_reagent_id_var, 
             name_var, 
             type_id_var, 
             feature_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER nd_reagent_audit_ud ON nd_reagent;
   CREATE TRIGGER nd_reagent_audit_ud
       BEFORE UPDATE OR DELETE ON nd_reagent
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_nd_reagent ();


   DROP TABLE audit_nd_protocol_reagent;
   CREATE TABLE audit_nd_protocol_reagent ( 
       nd_protocol_reagent_id integer, 
       nd_protocol_id integer, 
       reagent_id integer, 
       type_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_nd_protocol_reagent to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_nd_protocol_reagent() RETURNS trigger AS
   '
   DECLARE
       nd_protocol_reagent_id_var integer; 
       nd_protocol_id_var integer; 
       reagent_id_var integer; 
       type_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       nd_protocol_reagent_id_var = OLD.nd_protocol_reagent_id;
       nd_protocol_id_var = OLD.nd_protocol_id;
       reagent_id_var = OLD.reagent_id;
       type_id_var = OLD.type_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_nd_protocol_reagent ( 
             nd_protocol_reagent_id, 
             nd_protocol_id, 
             reagent_id, 
             type_id, 
             transaction_type
       ) VALUES ( 
             nd_protocol_reagent_id_var, 
             nd_protocol_id_var, 
             reagent_id_var, 
             type_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER nd_protocol_reagent_audit_ud ON nd_protocol_reagent;
   CREATE TRIGGER nd_protocol_reagent_audit_ud
       BEFORE UPDATE OR DELETE ON nd_protocol_reagent
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_nd_protocol_reagent ();


   DROP TABLE audit_nd_protocolprop;
   CREATE TABLE audit_nd_protocolprop ( 
       nd_protocolprop_id integer, 
       nd_protocol_id integer, 
       type_id integer, 
       value varchar(255), 
       rank integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_nd_protocolprop to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_nd_protocolprop() RETURNS trigger AS
   '
   DECLARE
       nd_protocolprop_id_var integer; 
       nd_protocol_id_var integer; 
       type_id_var integer; 
       value_var varchar(255); 
       rank_var integer; 
       
       transaction_type_var char;
   BEGIN
       nd_protocolprop_id_var = OLD.nd_protocolprop_id;
       nd_protocol_id_var = OLD.nd_protocol_id;
       type_id_var = OLD.type_id;
       value_var = OLD.value;
       rank_var = OLD.rank;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_nd_protocolprop ( 
             nd_protocolprop_id, 
             nd_protocol_id, 
             type_id, 
             value, 
             rank, 
             transaction_type
       ) VALUES ( 
             nd_protocolprop_id_var, 
             nd_protocol_id_var, 
             type_id_var, 
             value_var, 
             rank_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER nd_protocolprop_audit_ud ON nd_protocolprop;
   CREATE TRIGGER nd_protocolprop_audit_ud
       BEFORE UPDATE OR DELETE ON nd_protocolprop
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_nd_protocolprop ();


   DROP TABLE audit_nd_experiment_stock;
   CREATE TABLE audit_nd_experiment_stock ( 
       nd_experiment_stock_id integer, 
       nd_experiment_id integer, 
       stock_id integer, 
       type_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_nd_experiment_stock to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_nd_experiment_stock() RETURNS trigger AS
   '
   DECLARE
       nd_experiment_stock_id_var integer; 
       nd_experiment_id_var integer; 
       stock_id_var integer; 
       type_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       nd_experiment_stock_id_var = OLD.nd_experiment_stock_id;
       nd_experiment_id_var = OLD.nd_experiment_id;
       stock_id_var = OLD.stock_id;
       type_id_var = OLD.type_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_nd_experiment_stock ( 
             nd_experiment_stock_id, 
             nd_experiment_id, 
             stock_id, 
             type_id, 
             transaction_type
       ) VALUES ( 
             nd_experiment_stock_id_var, 
             nd_experiment_id_var, 
             stock_id_var, 
             type_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER nd_experiment_stock_audit_ud ON nd_experiment_stock;
   CREATE TRIGGER nd_experiment_stock_audit_ud
       BEFORE UPDATE OR DELETE ON nd_experiment_stock
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_nd_experiment_stock ();


   DROP TABLE audit_nd_experiment_protocol;
   CREATE TABLE audit_nd_experiment_protocol ( 
       nd_experiment_protocol_id integer, 
       nd_experiment_id integer, 
       nd_protocol_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_nd_experiment_protocol to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_nd_experiment_protocol() RETURNS trigger AS
   '
   DECLARE
       nd_experiment_protocol_id_var integer; 
       nd_experiment_id_var integer; 
       nd_protocol_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       nd_experiment_protocol_id_var = OLD.nd_experiment_protocol_id;
       nd_experiment_id_var = OLD.nd_experiment_id;
       nd_protocol_id_var = OLD.nd_protocol_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_nd_experiment_protocol ( 
             nd_experiment_protocol_id, 
             nd_experiment_id, 
             nd_protocol_id, 
             transaction_type
       ) VALUES ( 
             nd_experiment_protocol_id_var, 
             nd_experiment_id_var, 
             nd_protocol_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER nd_experiment_protocol_audit_ud ON nd_experiment_protocol;
   CREATE TRIGGER nd_experiment_protocol_audit_ud
       BEFORE UPDATE OR DELETE ON nd_experiment_protocol
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_nd_experiment_protocol ();


   DROP TABLE audit_nd_experiment_phenotype;
   CREATE TABLE audit_nd_experiment_phenotype ( 
       nd_experiment_phenotype_id integer, 
       nd_experiment_id integer, 
       phenotype_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_nd_experiment_phenotype to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_nd_experiment_phenotype() RETURNS trigger AS
   '
   DECLARE
       nd_experiment_phenotype_id_var integer; 
       nd_experiment_id_var integer; 
       phenotype_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       nd_experiment_phenotype_id_var = OLD.nd_experiment_phenotype_id;
       nd_experiment_id_var = OLD.nd_experiment_id;
       phenotype_id_var = OLD.phenotype_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_nd_experiment_phenotype ( 
             nd_experiment_phenotype_id, 
             nd_experiment_id, 
             phenotype_id, 
             transaction_type
       ) VALUES ( 
             nd_experiment_phenotype_id_var, 
             nd_experiment_id_var, 
             phenotype_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER nd_experiment_phenotype_audit_ud ON nd_experiment_phenotype;
   CREATE TRIGGER nd_experiment_phenotype_audit_ud
       BEFORE UPDATE OR DELETE ON nd_experiment_phenotype
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_nd_experiment_phenotype ();


   DROP TABLE audit_nd_experiment_genotype;
   CREATE TABLE audit_nd_experiment_genotype ( 
       nd_experiment_genotype_id integer, 
       nd_experiment_id integer, 
       genotype_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_nd_experiment_genotype to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_nd_experiment_genotype() RETURNS trigger AS
   '
   DECLARE
       nd_experiment_genotype_id_var integer; 
       nd_experiment_id_var integer; 
       genotype_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       nd_experiment_genotype_id_var = OLD.nd_experiment_genotype_id;
       nd_experiment_id_var = OLD.nd_experiment_id;
       genotype_id_var = OLD.genotype_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_nd_experiment_genotype ( 
             nd_experiment_genotype_id, 
             nd_experiment_id, 
             genotype_id, 
             transaction_type
       ) VALUES ( 
             nd_experiment_genotype_id_var, 
             nd_experiment_id_var, 
             genotype_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER nd_experiment_genotype_audit_ud ON nd_experiment_genotype;
   CREATE TRIGGER nd_experiment_genotype_audit_ud
       BEFORE UPDATE OR DELETE ON nd_experiment_genotype
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_nd_experiment_genotype ();


   DROP TABLE audit_nd_reagent_relationship;
   CREATE TABLE audit_nd_reagent_relationship ( 
       nd_reagent_relationship_id integer, 
       subject_reagent_id integer, 
       object_reagent_id integer, 
       type_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_nd_reagent_relationship to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_nd_reagent_relationship() RETURNS trigger AS
   '
   DECLARE
       nd_reagent_relationship_id_var integer; 
       subject_reagent_id_var integer; 
       object_reagent_id_var integer; 
       type_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       nd_reagent_relationship_id_var = OLD.nd_reagent_relationship_id;
       subject_reagent_id_var = OLD.subject_reagent_id;
       object_reagent_id_var = OLD.object_reagent_id;
       type_id_var = OLD.type_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_nd_reagent_relationship ( 
             nd_reagent_relationship_id, 
             subject_reagent_id, 
             object_reagent_id, 
             type_id, 
             transaction_type
       ) VALUES ( 
             nd_reagent_relationship_id_var, 
             subject_reagent_id_var, 
             object_reagent_id_var, 
             type_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER nd_reagent_relationship_audit_ud ON nd_reagent_relationship;
   CREATE TRIGGER nd_reagent_relationship_audit_ud
       BEFORE UPDATE OR DELETE ON nd_reagent_relationship
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_nd_reagent_relationship ();


   DROP TABLE audit_nd_reagentprop;
   CREATE TABLE audit_nd_reagentprop ( 
       nd_reagentprop_id integer, 
       nd_reagent_id integer, 
       type_id integer, 
       value varchar(255), 
       rank integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_nd_reagentprop to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_nd_reagentprop() RETURNS trigger AS
   '
   DECLARE
       nd_reagentprop_id_var integer; 
       nd_reagent_id_var integer; 
       type_id_var integer; 
       value_var varchar(255); 
       rank_var integer; 
       
       transaction_type_var char;
   BEGIN
       nd_reagentprop_id_var = OLD.nd_reagentprop_id;
       nd_reagent_id_var = OLD.nd_reagent_id;
       type_id_var = OLD.type_id;
       value_var = OLD.value;
       rank_var = OLD.rank;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_nd_reagentprop ( 
             nd_reagentprop_id, 
             nd_reagent_id, 
             type_id, 
             value, 
             rank, 
             transaction_type
       ) VALUES ( 
             nd_reagentprop_id_var, 
             nd_reagent_id_var, 
             type_id_var, 
             value_var, 
             rank_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER nd_reagentprop_audit_ud ON nd_reagentprop;
   CREATE TRIGGER nd_reagentprop_audit_ud
       BEFORE UPDATE OR DELETE ON nd_reagentprop
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_nd_reagentprop ();


   DROP TABLE audit_nd_experiment_stockprop;
   CREATE TABLE audit_nd_experiment_stockprop ( 
       nd_experiment_stockprop_id integer, 
       nd_experiment_stock_id integer, 
       type_id integer, 
       value varchar(255), 
       rank integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_nd_experiment_stockprop to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_nd_experiment_stockprop() RETURNS trigger AS
   '
   DECLARE
       nd_experiment_stockprop_id_var integer; 
       nd_experiment_stock_id_var integer; 
       type_id_var integer; 
       value_var varchar(255); 
       rank_var integer; 
       
       transaction_type_var char;
   BEGIN
       nd_experiment_stockprop_id_var = OLD.nd_experiment_stockprop_id;
       nd_experiment_stock_id_var = OLD.nd_experiment_stock_id;
       type_id_var = OLD.type_id;
       value_var = OLD.value;
       rank_var = OLD.rank;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_nd_experiment_stockprop ( 
             nd_experiment_stockprop_id, 
             nd_experiment_stock_id, 
             type_id, 
             value, 
             rank, 
             transaction_type
       ) VALUES ( 
             nd_experiment_stockprop_id_var, 
             nd_experiment_stock_id_var, 
             type_id_var, 
             value_var, 
             rank_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER nd_experiment_stockprop_audit_ud ON nd_experiment_stockprop;
   CREATE TRIGGER nd_experiment_stockprop_audit_ud
       BEFORE UPDATE OR DELETE ON nd_experiment_stockprop
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_nd_experiment_stockprop ();


   DROP TABLE audit_nd_experiment_stock_dbxref;
   CREATE TABLE audit_nd_experiment_stock_dbxref ( 
       nd_experiment_stock_dbxref_id integer, 
       nd_experiment_stock_id integer, 
       dbxref_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_nd_experiment_stock_dbxref to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_nd_experiment_stock_dbxref() RETURNS trigger AS
   '
   DECLARE
       nd_experiment_stock_dbxref_id_var integer; 
       nd_experiment_stock_id_var integer; 
       dbxref_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       nd_experiment_stock_dbxref_id_var = OLD.nd_experiment_stock_dbxref_id;
       nd_experiment_stock_id_var = OLD.nd_experiment_stock_id;
       dbxref_id_var = OLD.dbxref_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_nd_experiment_stock_dbxref ( 
             nd_experiment_stock_dbxref_id, 
             nd_experiment_stock_id, 
             dbxref_id, 
             transaction_type
       ) VALUES ( 
             nd_experiment_stock_dbxref_id_var, 
             nd_experiment_stock_id_var, 
             dbxref_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER nd_experiment_stock_dbxref_audit_ud ON nd_experiment_stock_dbxref;
   CREATE TRIGGER nd_experiment_stock_dbxref_audit_ud
       BEFORE UPDATE OR DELETE ON nd_experiment_stock_dbxref
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_nd_experiment_stock_dbxref ();


   DROP TABLE audit_nd_experiment_dbxref;
   CREATE TABLE audit_nd_experiment_dbxref ( 
       nd_experiment_dbxref_id integer, 
       nd_experiment_id integer, 
       dbxref_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_nd_experiment_dbxref to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_nd_experiment_dbxref() RETURNS trigger AS
   '
   DECLARE
       nd_experiment_dbxref_id_var integer; 
       nd_experiment_id_var integer; 
       dbxref_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       nd_experiment_dbxref_id_var = OLD.nd_experiment_dbxref_id;
       nd_experiment_id_var = OLD.nd_experiment_id;
       dbxref_id_var = OLD.dbxref_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_nd_experiment_dbxref ( 
             nd_experiment_dbxref_id, 
             nd_experiment_id, 
             dbxref_id, 
             transaction_type
       ) VALUES ( 
             nd_experiment_dbxref_id_var, 
             nd_experiment_id_var, 
             dbxref_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER nd_experiment_dbxref_audit_ud ON nd_experiment_dbxref;
   CREATE TRIGGER nd_experiment_dbxref_audit_ud
       BEFORE UPDATE OR DELETE ON nd_experiment_dbxref
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_nd_experiment_dbxref ();


   DROP TABLE audit_nd_experiment_contact;
   CREATE TABLE audit_nd_experiment_contact ( 
       nd_experiment_contact_id integer, 
       nd_experiment_id integer, 
       contact_id integer, 
       transaction_date timestamp not null default now(),
       transaction_type char(1) not null
   );
   GRANT ALL on audit_nd_experiment_contact to PUBLIC;

   CREATE OR REPLACE FUNCTION audit_update_delete_nd_experiment_contact() RETURNS trigger AS
   '
   DECLARE
       nd_experiment_contact_id_var integer; 
       nd_experiment_id_var integer; 
       contact_id_var integer; 
       
       transaction_type_var char;
   BEGIN
       nd_experiment_contact_id_var = OLD.nd_experiment_contact_id;
       nd_experiment_id_var = OLD.nd_experiment_id;
       contact_id_var = OLD.contact_id;
       
       IF TG_OP = ''DELETE'' THEN
           transaction_type_var = ''D'';
       ELSE
           transaction_type_var = ''U'';
       END IF;

       INSERT INTO audit_nd_experiment_contact ( 
             nd_experiment_contact_id, 
             nd_experiment_id, 
             contact_id, 
             transaction_type
       ) VALUES ( 
             nd_experiment_contact_id_var, 
             nd_experiment_id_var, 
             contact_id_var, 
             transaction_type_var
       );

       IF TG_OP = ''DELETE'' THEN
           return OLD;
       ELSE
           return NEW;
       END IF;
   END
   '
   LANGUAGE plpgsql; 

   DROP TRIGGER nd_experiment_contact_audit_ud ON nd_experiment_contact;
   CREATE TRIGGER nd_experiment_contact_audit_ud
       BEFORE UPDATE OR DELETE ON nd_experiment_contact
       FOR EACH ROW
       EXECUTE PROCEDURE audit_update_delete_nd_experiment_contact ();


