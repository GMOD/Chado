--when schema elements are added, including new tables or changes to table
--columns, or when initialize.sql is changed, the sql to make those changes
--happen should go here.

--gmod version 1.01

--This is a function to seek out exons of transcripts and orders them,
--using feature_relationship.rank, in "transcript order" numbering
--from 0, taking strand into account. It will not touch transcripts that
--already have their exons ordered (in case they have a non-obvious
--ordering due to trans splicing). It takes as an argument the
--feature.type_id of the parent transcript type (typically, mRNA, although
--non coding transcript types should work too).

CREATE OR REPLACE FUNCTION order_exons (integer) RETURNS void AS '
  DECLARE
    parent_type      ALIAS FOR $1;
    exon_id          int;
    part_of          int;
    exon_type        int;
    strand           int;
    arow             RECORD;
    order_by         varchar;
    rowcount         int;
    exon_count       int;
    ordered_exons    int;    
    transcript_id    int;
  BEGIN
    SELECT INTO part_of cvterm_id FROM cvterm WHERE name=''part_of''
      AND cv_id IN (SELECT cv_id FROM cv WHERE name=''relationship'');
    --SELECT INTO exon_type cvterm_id FROM cvterm WHERE name=''exon''
    --  AND cv_id IN (SELECT cv_id FROM cv WHERE name=''sequence'');

    --RAISE NOTICE ''part_of %, exon %'',part_of,exon_type;

    FOR transcript_id IN
      SELECT feature_id FROM feature WHERE type_id = parent_type
    LOOP
      SELECT INTO rowcount count(*) FROM feature_relationship
        WHERE object_id = transcript_id
          AND rank = 0;

      --Dont modify this transcript if there are already numbered exons or
      --if there is only one exon
      IF rowcount = 1 THEN
        --RAISE NOTICE ''skipping transcript %, row count %'',transcript_id,rowcount;
        CONTINUE;
      END IF;

      --need to reverse the order if the strand is negative
      SELECT INTO strand strand FROM featureloc WHERE feature_id=transcript_id;
      IF strand > 0 THEN
          order_by = ''fl.fmin'';      
      ELSE
          order_by = ''fl.fmax desc'';
      END IF;

      exon_count = 0;
      FOR arow IN EXECUTE 
        ''SELECT fr.*, fl.fmin, fl.fmax
          FROM feature_relationship fr, featureloc fl
          WHERE fr.object_id  = ''||transcript_id||''
            AND fr.subject_id = fl.feature_id
            AND fr.type_id    = ''||part_of||''
            ORDER BY ''||order_by
      LOOP
        --number the exons for a given transcript
        UPDATE feature_relationship
          SET rank = exon_count 
          WHERE feature_relationship_id = arow.feature_relationship_id;
        exon_count = exon_count + 1;
      END LOOP; 

    END LOOP;

  END;
' LANGUAGE 'plpgsql';


--added foreign key for pub_id to phenotype_comparison_cvterm
ALTER TABLE phenotype_comparison_cvterm ADD FOREIGN KEY (pub_id) references pub (pub_id) on delete cascade;

--Changed the Audit table triggers to work with newer versions of Postgres.
--This didn't change the the default schema at all (since audit.sql isn't
--part of the default schema.

--all_feature_name view also searches featureprop and dbxref.accesion
--see the comments in modules/sequence/sequence_views.sql  for more
--information on how this works
CREATE OR REPLACE VIEW all_feature_names (
  feature_id,
  name
) AS
SELECT feature_id,CAST(substring(uniquename from 0 for 255) as varchar(255)) as name FROM feature
UNION
SELECT feature_id, name FROM feature where name is not null
UNION
SELECT fs.feature_id,s.name FROM feature_synonym fs, synonym s
  WHERE fs.synonym_id = s.synonym_id
UNION
SELECT fp.feature_id, CAST(substring(fp.value from 0 for 255) as varchar(255)) as name FROM featureprop fp
UNION
SELECT fd.feature_id, d.accession FROM feature_dbxref fd, dbxref d
  WHERE fd.dbxref_id = d.dbxref_id;

