
/* feature before (?)deletion trigger implements the following rules:

     -if feature to be deleted is a 
	
	transcript:
	-delete any exons having this as their only related transcript
	-delete any proteins having this as their only related transcript
	-prevent deletion if there are any alleles of the transcript?
     
	gene:
	-prevent deletion if there are any alleles of the gene? or other info?
	-delete all transcripts that are related only to this gene

	what needs to be preserved about dbxrefs, etc.? 	
*/

CREATE OR REPLACE FUNCTION feature_del_tr () RETURNS TRIGGER AS '
body goes here




' LANGUAGE SQL (?);
or language plpgsql;

CREATE TRIGGER name { BEFORE | AFTER } { event [OR ...] }
          ON table FOR EACH { ROW | STATEMENT }
          EXECUTE PROCEDURE func ( arguments )
 
CREATE TRIGGER feature_del_tr BEFORE DELETE ON feature FOR EACH { ROW | STATEMENT }
	EXECUTE PROCEDURE feature_del_tr ; 
