--------------------------------
---- f_type --------------------
--------------------------------
DROP VIEW f_type;
CREATE VIEW f_type
AS
  SELECT  f.feature_id,
          f.name,
          f.dbxrefstr,
          c.termname AS type,
          f.residues,
          f.seqlen,
          f.md5checksum,
          f.type_id,
          f.timeentered,
          f.timelastmod
    FROM  feature f, cvterm c
   WHERE  f.type_id = c.cvterm_id;

--------------------------------
---- fnr_type ------------------
--------------------------------
DROP VIEW fnr_type;
CREATE VIEW fnr_type
AS
  SELECT  f.feature_id,
          f.name,
          f.dbxrefstr,
          c.termname AS type,
          f.residues,
          f.seqlen,
          f.md5checksum,
          f.type_id,
          f.timeentered,
          f.timelastmod
    FROM  feature f left outer join analysisfeature af
          on (f.feature_id = af.feature_id), cvterm c
   WHERE  f.type_id = c.cvterm_id
          and af.feature_id is null;

--------------------------------
---- f_loc ---------------------
--------------------------------
DROP VIEW f_loc;
CREATE VIEW f_loc
AS
  SELECT  f.feature_id,
          f.name,
          f.dbxrefstr,
          fl.nbeg,
          fl.nend,
          fl.strand
    FROM  featureloc fl, f_type f
   WHERE  f.feature_id = fl.feature_id;

--------------------------------
---- fp_key -------------------
--------------------------------
DROP VIEW fp_key;
CREATE VIEW fp_key
AS
  SELECT  fp.feature_id,
          c.termname AS pkey,
          fp.pval
    FROM  featureprop fp, cvterm c
   WHERE  fp.pkey_id = c.cvterm_id;

