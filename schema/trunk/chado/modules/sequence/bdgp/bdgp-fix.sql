update cv set name = 'so' where name = 'SO';

update feature set residues = null where exists (select 1 from cvterm where feature.type_id = cvterm.cvterm_id and cvterm.name = 'chromosome_arm');
