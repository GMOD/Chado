create table dbxref (
       dbxref_id serial not null,
       primary key (dbxref_id),
       dbname varchar(255) not null,
       accession varchar(255) not null,
       version varchar(255) not null default '',
       dbxrefdescription text,
       unique (dbname, accession, version)
);
GRANT ALL on dbxref_dbxref_id_seq to PUBLIC;
GRANT ALL on dbxref to PUBLIC;

create table tableinfo (
       tableinfo_id serial not null,
       primary key (tableinfo_id),
       name varchar(30) not null,
       table_type varchar(40) not null,
       primary_key_column varchar(30) null,
       database_id int not null,
       is_versioned int not null,
       is_view int not null,
       view_on_table_id int null,
       superclass_table_id int null,
       is_updateable int not null,
       modification_date date not null
);
GRANT ALL on tableinfo_tableinfo_id_seq to PUBLIC;
GRANT ALL on tableinfo to PUBLIC;

create table projectinfo (
       projectinfo_id serial not null,
       primary key (projectinfo_id),
       name varchar(255) not null,
      description varchar(255) not null
);
GRANT ALL on projectinfo_projectinfo_id_seq to PUBLIC;
GRANT ALL on projectinfo to PUBLIC;

create table cv (
       cv_id serial not null,
       primary key (cv_id),
       cvname varchar(255) not null,
       cvdefinition text,
       unique(cvname)
);
GRANT ALL on cv_cv_id_seq to PUBLIC;
GRANT ALL on cv to PUBLIC;

create table cvterm (
       cvterm_id serial not null,
       primary key (cvterm_id),
       cv_id int not null,
       foreign key (cv_id) references cv (cv_id),
       name varchar(255) not null,
       termdefinition text,
       dbxref_id int,
       foreign key (dbxref_id) references dbxref (dbxref_id),
       unique(name, cv_id)
);
GRANT ALL on cvterm_cvterm_id_seq to PUBLIC;
GRANT ALL on cvterm to PUBLIC;

create index cvterm_idx1 on cvterm (cv_id);
GRANT ALL on cvterm to PUBLIC;

create table cvrelationship (
       cvrelationship_id serial not null,
       primary key (cvrelationship_id),
       reltype_id int not null,
       foreign key (reltype_id) references cvterm (cvterm_id),
       subjterm_id int not null,
       foreign key (subjterm_id) references cvterm (cvterm_id),
       objterm_id int not null,
       foreign key (objterm_id) references cvterm (cvterm_id),
       unique(reltype_id, subjterm_id, objterm_id)
);
GRANT ALL on cvrelationshi_cvrelationshi_seq to PUBLIC;
GRANT ALL on cvrelationship to PUBLIC;

create index cvrelationship_idx1 on cvrelationship (reltype_id);
GRANT ALL on cvrelationship to PUBLIC;

create index cvrelationship_idx2 on cvrelationship (subjterm_id);
GRANT ALL on cvrelationship to PUBLIC;

create index cvrelationship_idx3 on cvrelationship (objterm_id);
GRANT ALL on cvrelationship to PUBLIC;

create table cvpath (
       cvpath_id serial not null,
       primary key (cvpath_id),
       reltype_id int,
       foreign key (reltype_id) references cvterm (cvterm_id),
       subjterm_id int not null,
       foreign key (subjterm_id) references cvterm (cvterm_id),
       objterm_id int not null,
       foreign key (objterm_id) references cvterm (cvterm_id),
       cv_id int not null,
       foreign key (cv_id) references cv (cv_id),
       pathdistance int,
       unique (subjterm_id, objterm_id)
);
GRANT ALL on cvpath_cvpath_id_seq to PUBLIC;
GRANT ALL on cvpath to PUBLIC;

create index cvpath_idx1 on cvpath (reltype_id);
GRANT ALL on cvpath to PUBLIC;

create index cvpath_idx2 on cvpath (subjterm_id);
GRANT ALL on cvpath to PUBLIC;

create index cvpath_idx3 on cvpath (objterm_id);
GRANT ALL on cvpath to PUBLIC;

create index cvpath_idx4 on cvpath (cv_id);
GRANT ALL on cvpath to PUBLIC;

create table cvtermsynonym (
       cvterm_id int not null,
       foreign key (cvterm_id) references cvterm (cvterm_id),
       termsynonym varchar(255) not null,
       unique(cvterm_id, termsynonym)
);
GRANT ALL on cvtermsynonym to PUBLIC;

create index cvtermsynonym_idx1 on cvtermsynonym (cvterm_id);
GRANT ALL on cvtermsynonym to PUBLIC;

create table cvterm_dbxref (
       cvterm_dbxref_id serial not null,
       primary key (cvterm_dbxref_id),
       cvterm_id int not null,
       foreign key (cvterm_id) references cvterm (cvterm_id),
       dbxref_id int not null,
       foreign key (dbxref_id) references dbxref (dbxref_id),
       unique(cvterm_id, dbxref_id)
);
GRANT ALL on cvterm_dbxref_cvterm_dbxref_seq to PUBLIC;
GRANT ALL on cvterm_dbxref to PUBLIC;

create index cvterm_dbxref_idx1 on cvterm_dbxref (cvterm_id);
GRANT ALL on cvterm_dbxref to PUBLIC;

create index cvterm_dbxref_idx2 on cvterm_dbxref (dbxref_id);
GRANT ALL on cvterm_dbxref to PUBLIC;

create table organism (
	organism_id serial not null,
	primary key (organism_id),
	abbrev varchar(255) null,
	genus varchar(255) not null,
	taxgroup varchar(255) not null,
	species varchar(255) not null,
	common_name varchar(255) null,
	comment text null,
	unique(taxgroup, genus, species)
);
GRANT ALL on organism_organism_id_seq to PUBLIC;
GRANT ALL on organism to PUBLIC;

create table organism_dbxref (
       organism_dbxref_id serial not null,
       primary key (organism_dbxref_id),
       organism_id int not null,
       foreign key (organism_id) references organism (organism_id),
       dbxref_id int not null,
       foreign key (dbxref_id) references dbxref (dbxref_id),
       unique(organism_id,dbxref_id)
);
GRANT ALL on organism_dbxr_organism_dbxr_seq to PUBLIC;
GRANT ALL on organism_dbxref to PUBLIC;

create index organism_dbxref_idx1 on organism_dbxref (organism_id);
GRANT ALL on organism_dbxref to PUBLIC;

create index organism_dbxref_idx2 on organism_dbxref (dbxref_id);
GRANT ALL on organism_dbxref to PUBLIC;

create table pub (
       pub_id serial not null,
       primary key (pub_id),
       title text,
       volumetitle text,
       volume  varchar(255),
       series_name varchar(255),
       issue  varchar(255),
       pyear  varchar(255),
       pages  varchar(255),
       miniref varchar(255) not null,
       type_id int not null,
       foreign key (type_id) references cvterm (cvterm_id),
       is_obsolete boolean default 'false',
       publisher varchar(255),
       pubplace varchar(255),
       unique(miniref)
);
GRANT ALL on pub_pub_id_seq to PUBLIC;
GRANT ALL on pub to PUBLIC;

create index pub_idx1 on pub (type_id);
GRANT ALL on pub to PUBLIC;

create table pub_relationship (
       pub_relationship_id serial not null,
       primary key (pub_relationship_id),
       subj_pub_id int not null,
       foreign key (subj_pub_id) references pub (pub_id),
       obj_pub_id int not null,
       foreign key (obj_pub_id) references pub (pub_id),
       type_id int not null,
       foreign key (type_id) references cvterm (cvterm_id),
       unique(subj_pub_id, obj_pub_id, type_id)
);
GRANT ALL on pub_relations_pub_relations_seq to PUBLIC;
GRANT ALL on pub_relationship to PUBLIC;

create index pub_relationship_idx1 on pub_relationship (subj_pub_id);
GRANT ALL on pub_relationship to PUBLIC;

create index pub_relationship_idx2 on pub_relationship (obj_pub_id);
GRANT ALL on pub_relationship to PUBLIC;

create index pub_relationship_idx3 on pub_relationship (type_id);
GRANT ALL on pub_relationship to PUBLIC;

create table pub_dbxref (
       pub_dbxref_id serial not null,
       primary key (pub_dbxref_id),
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id),
       dbxref_id int not null,
       foreign key (dbxref_id) references dbxref (dbxref_id),
       unique(pub_id,dbxref_id)
);
GRANT ALL on pub_dbxref_pub_dbxref_id_seq to PUBLIC;
GRANT ALL on pub_dbxref to PUBLIC;

create index pub_dbxref_idx1 on pub_dbxref (pub_id);
GRANT ALL on pub_dbxref to PUBLIC;

create index pub_dbxref_idx2 on pub_dbxref (dbxref_id);
GRANT ALL on pub_dbxref to PUBLIC;

create table author (
       author_id serial not null,
       primary key (author_id),
       surname varchar(100) not null,
       givennames varchar(100),
       suffix varchar(100),
       unique(surname,givennames,suffix)
);
GRANT ALL on author_author_id_seq to PUBLIC;
GRANT ALL on author to PUBLIC;

create table pub_author (
       pub_author_id serial not null,
       primary key (pub_author_id),
       author_id int not null,
       foreign key (author_id) references author (author_id),
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id),
       arank int not null,
       editor boolean default 'false',
       unique(author_id,pub_id)
);
GRANT ALL on pub_author_pub_author_id_seq to PUBLIC;
GRANT ALL on pub_author to PUBLIC;

create index pub_author_idx1 on pub_author (author_id);
GRANT ALL on pub_author to PUBLIC;

create index pub_author_idx2 on pub_author (pub_id);
GRANT ALL on pub_author to PUBLIC;

create table pubprop (
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id),
       pkey_id int not null,
       foreign key (pkey_id) references cvterm (cvterm_id),
       pval text not null,
       prank integer,
       unique(pub_id,pkey_id,pval)
);
GRANT ALL on pubprop to PUBLIC;

create index pubprop_idx1 on pubprop (pub_id);
GRANT ALL on pubprop to PUBLIC;

create index pubprop_idx2 on pubprop (pkey_id);
GRANT ALL on pubprop to PUBLIC;

create table feature (
       feature_id serial not null,
       primary key (feature_id),
       dbxref_id int,
       foreign key (dbxref_id) references dbxref (dbxref_id),
       organism_id int not null,
       foreign key (organism_id) references organism (organism_id),
       name varchar(255),
       uniquename text not null,
       residues text,
       seqlen int,
       md5checksum char(32),
       type_id int not null,
       foreign key (type_id) references cvterm (cvterm_id),
	is_analysis boolean not null default 'false',
       timeaccessioned timestamp not null default current_timestamp,
       timelastmodified timestamp not null default current_timestamp,
       unique(organism_id,uniquename)
);
GRANT ALL on feature_feature_id_seq to PUBLIC;
GRANT ALL on feature to PUBLIC;

create sequence feature_uniquename_seq;
create index feature_name_ind1 on feature(name);
GRANT ALL on feature to PUBLIC;

create index feature_idx1 on feature (dbxref_id);
GRANT ALL on feature to PUBLIC;

create index feature_idx2 on feature (organism_id);
GRANT ALL on feature to PUBLIC;

create index feature_idx3 on feature (type_id);
GRANT ALL on feature to PUBLIC;

create index feature_idx4 on feature (uniquename);
GRANT ALL on feature to PUBLIC;

create index feature_lc_name on feature (lower(name));
GRANT ALL on feature to PUBLIC;

create table featureloc (
       featureloc_id serial not null,
       primary key (featureloc_id),
       feature_id int not null,
       foreign key (feature_id) references feature (feature_id),
       srcfeature_id int,
       foreign key (srcfeature_id) references feature (feature_id),
       nbeg int,
       is_nbeg_partial boolean not null default 'false',
       nend int,
       is_nend_partial boolean not null default 'false',
       strand smallint,
       phase int,
       residue_info text,
       locgroup int not null default 0,
       rank     int not null default 0,
       unique (feature_id, locgroup, rank)
);
GRANT ALL on featureloc_featureloc_id_seq to PUBLIC;
GRANT ALL on featureloc to PUBLIC;

create index featureloc_idx1 on featureloc (feature_id);
GRANT ALL on featureloc to PUBLIC;

create index featureloc_idx2 on featureloc (srcfeature_id);
GRANT ALL on featureloc to PUBLIC;

create index featureloc_idx3 on featureloc (srcfeature_id,nbeg,nend);
GRANT ALL on featureloc to PUBLIC;

create table feature_pub (
       feature_pub_id serial not null,
       primary key (feature_pub_id),
       feature_id int not null,
       foreign key (feature_id) references feature (feature_id),
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id),
       unique(feature_id, pub_id)
);
GRANT ALL on feature_pub_feature_pub_id_seq to PUBLIC;
GRANT ALL on feature_pub to PUBLIC;

create index feature_pub_idx1 on feature_pub (feature_id);
GRANT ALL on feature_pub to PUBLIC;

create index feature_pub_idx2 on feature_pub (pub_id);
GRANT ALL on feature_pub to PUBLIC;

create table featureprop (
       featureprop_id serial not null,
       primary key (featureprop_id),
       feature_id int not null,
       foreign key (feature_id) references feature (feature_id),
       pkey_id int not null,
       foreign key (pkey_id) references cvterm (cvterm_id),
       pval text not null default '',
       prank int not null default 0,
       unique(feature_id, pkey_id, pval, prank)
);
GRANT ALL on featureprop_featureprop_id_seq to PUBLIC;
GRANT ALL on featureprop to PUBLIC;

create index featureprop_idx1 on featureprop (feature_id);
GRANT ALL on featureprop to PUBLIC;

create index featureprop_idx2 on featureprop (pkey_id);
GRANT ALL on featureprop to PUBLIC;

create table featureprop_pub (
       featureprop_pub_id serial not null,
       primary key (featureprop_pub_id),
       featureprop_id int not null,
       foreign key (featureprop_id) references featureprop (featureprop_id),
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id),
       unique(featureprop_id, pub_id)
);
GRANT ALL on featureprop_p_featureprop_p_seq to PUBLIC;
GRANT ALL on featureprop_pub to PUBLIC;

create index featureprop_pub_idx1 on featureprop_pub (featureprop_id);
GRANT ALL on featureprop_pub to PUBLIC;

create index featureprop_pub_idx2 on featureprop_pub (pub_id);
GRANT ALL on featureprop_pub to PUBLIC;

create table feature_dbxref (
       feature_dbxref_id serial not null,
       primary key (feature_dbxref_id),
       feature_id int not null,
       foreign key (feature_id) references feature (feature_id),
       dbxref_id int not null,
       foreign key (dbxref_id) references dbxref (dbxref_id),
       is_current boolean not null default 'true',
       unique(feature_id, dbxref_id)
);
GRANT ALL on feature_dbxre_feature_dbxre_seq to PUBLIC;
GRANT ALL on feature_dbxref to PUBLIC;

create index feature_dbxref_idx1 on feature_dbxref (feature_id);
GRANT ALL on feature_dbxref to PUBLIC;

create index feature_dbxref_idx2 on feature_dbxref (dbxref_id);
GRANT ALL on feature_dbxref to PUBLIC;

create table feature_relationship (
       feature_relationship_id serial not null,
       primary key (feature_relationship_id),
       subjfeature_id int not null,
       foreign key (subjfeature_id) references feature (feature_id),
       objfeature_id int not null,
       foreign key (objfeature_id) references feature (feature_id),
       type_id int not null,
       foreign key (type_id) references cvterm (cvterm_id),
       relrank int,
       unique(subjfeature_id, objfeature_id, type_id)
);
GRANT ALL on feature_relat_feature_relat_seq to PUBLIC;
GRANT ALL on feature_relationship to PUBLIC;

create index feature_relationship_idx1 on feature_relationship (subjfeature_id);
GRANT ALL on feature_relationship to PUBLIC;

create index feature_relationship_idx2 on feature_relationship (objfeature_id);
GRANT ALL on feature_relationship to PUBLIC;

create index feature_relationship_idx3 on feature_relationship (type_id);
GRANT ALL on feature_relationship to PUBLIC;

create table feature_cvterm (
       feature_cvterm_id serial not null,
       primary key (feature_cvterm_id),
       feature_id int not null,
       foreign key (feature_id) references feature (feature_id),
       cvterm_id int not null,
       foreign key (cvterm_id) references cvterm (cvterm_id),
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id),
       unique(feature_id, cvterm_id, pub_id)
);
GRANT ALL on feature_cvter_feature_cvter_seq to PUBLIC;
GRANT ALL on feature_cvterm to PUBLIC;

create index feature_cvterm_idx1 on feature_cvterm (feature_id);
GRANT ALL on feature_cvterm to PUBLIC;

create index feature_cvterm_idx2 on feature_cvterm (cvterm_id);
GRANT ALL on feature_cvterm to PUBLIC;

create index feature_cvterm_idx3 on feature_cvterm (pub_id);
GRANT ALL on feature_cvterm to PUBLIC;

create table synonym (
       synonym_id serial not null,
       primary key (synonym_id),
       name varchar(255) not null,
       type_id int not null,
       synonym_sgml varchar(255) not null,
       foreign key (type_id) references cvterm (cvterm_id),
       unique(name,type_id)
);
GRANT ALL on synonym_synonym_id_seq to PUBLIC;
GRANT ALL on synonym to PUBLIC;

create index synonym_idx1 on synonym (type_id);
GRANT ALL on synonym to PUBLIC;

create table feature_synonym (
       feature_synonym_id serial not null,
       primary key (feature_synonym_id),
       synonym_id int not null,
       foreign key (synonym_id) references synonym (synonym_id),
       feature_id int not null,
       foreign key (feature_id) references feature (feature_id),
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id),
       is_current boolean not null,
       is_internal boolean not null default 'false',
       unique(synonym_id, feature_id, pub_id)
);
GRANT ALL on feature_synon_feature_synon_seq to PUBLIC;
GRANT ALL on feature_synonym to PUBLIC;

create index feature_synonym_idx1 on feature_synonym (synonym_id);
GRANT ALL on feature_synonym to PUBLIC;

create index feature_synonym_idx2 on feature_synonym (feature_id);
GRANT ALL on feature_synonym to PUBLIC;

create index feature_synonym_idx3 on feature_synonym (pub_id);
GRANT ALL on feature_synonym to PUBLIC;

create table synonym_pub (
       synonym_pub_id serial not null,
       primary key (synonym_pub_id),
       synonym_id int not null,
       foreign key (synonym_id) references synonym (synonym_id),
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id),
       unique(synonym_id, pub_id)
);
GRANT ALL on synonym_pub_synonym_pub_id_seq to PUBLIC;
GRANT ALL on synonym_pub to PUBLIC;

create index synonym_pub_idx1 on synonym_pub (synonym_id);
GRANT ALL on synonym_pub to PUBLIC;

create index synonym_pub_idx2 on synonym_pub (pub_id);
GRANT ALL on synonym_pub to PUBLIC;

create table genotype (
       genotype_id serial not null,
       primary key (genotype_id),
       description varchar(255)
);
GRANT ALL on genotype_genotype_id_seq to PUBLIC;
GRANT ALL on genotype to PUBLIC;

create table feature_genotype (
       feature_genotype_id serial not null,
       primary key (feature_genotype_id),
       feature_id int not null,
       foreign key (feature_id) references feature (feature_id),
       genotype_id int not null,
       foreign key (genotype_id) references genotype (genotype_id),
       unique(feature_id,genotype_id)
);
GRANT ALL on feature_genot_feature_genot_seq to PUBLIC;
GRANT ALL on feature_genotype to PUBLIC;

create index feature_genotype_idx1 on feature_genotype (feature_id);
GRANT ALL on feature_genotype to PUBLIC;

create index feature_genotype_idx2 on feature_genotype (genotype_id);
GRANT ALL on feature_genotype to PUBLIC;

create table phenotype (
       phenotype_id serial not null,
       primary key (phenotype_id),
       description text,
       statement_type int not null,
       foreign key (statement_type) references cvterm (cvterm_id),
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id),
       background_genotype_id int,
       foreign key (background_genotype_id) references genotype (genotype_id)
);
GRANT ALL on phenotype_phenotype_id_seq to PUBLIC;
GRANT ALL on phenotype to PUBLIC;

create index phenotype_idx1 on phenotype (statement_type);
GRANT ALL on phenotype to PUBLIC;

create index phenotype_idx2 on phenotype (pub_id);
GRANT ALL on phenotype to PUBLIC;

create index phenotype_idx3 on phenotype (background_genotype_id);
GRANT ALL on phenotype to PUBLIC;

create table feature_phenotype (
       feature_phenotype_id serial not null,
       primary key (feature_phenotype_id),
       feature_id int not null,
       foreign key (feature_id) references feature (feature_id),
       phenotype_id int not null,
       foreign key (phenotype_id) references phenotype (phenotype_id),
       unique(feature_id,phenotype_id)       
);
GRANT ALL on feature_pheno_feature_pheno_seq to PUBLIC;
GRANT ALL on feature_phenotype to PUBLIC;

create index feature_phenotype_idx1 on feature_phenotype (feature_id);
GRANT ALL on feature_phenotype to PUBLIC;

create index feature_phenotype_idx2 on feature_phenotype (phenotype_id);
GRANT ALL on feature_phenotype to PUBLIC;

create table phenotype_cvterm (
       phenotype_cvterm_id serial not null,
       primary key (phenotype_cvterm_id),
       phenotype_id int not null,
       foreign key (phenotype_id) references phenotype (phenotype_id),
       cvterm_id int not null,
       foreign key (cvterm_id) references cvterm (cvterm_id),
       prank int not null,
       unique(phenotype_id,cvterm_id,prank)
);
GRANT ALL on phenotype_cvt_phenotype_cvt_seq to PUBLIC;
GRANT ALL on phenotype_cvterm to PUBLIC;

create index phenotype_cvterm_idx1 on phenotype_cvterm (phenotype_id);
GRANT ALL on phenotype_cvterm to PUBLIC;

create index phenotype_cvterm_idx2 on phenotype_cvterm (cvterm_id);
GRANT ALL on phenotype_cvterm to PUBLIC;

create table interaction (
       interaction_id serial not null,
       primary key (interaction_id),
       description text,
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id),
       background_genotype_id int,
       foreign key (background_genotype_id) references genotype (genotype_id),
       phenotype_id int,
       foreign key (phenotype_id) references phenotype (phenotype_id)
);
GRANT ALL on interaction_interaction_id_seq to PUBLIC;
GRANT ALL on interaction to PUBLIC;

create index interaction_idx1 on interaction (pub_id);
GRANT ALL on interaction to PUBLIC;

create index interaction_idx2 on interaction (background_genotype_id);
GRANT ALL on interaction to PUBLIC;

create index interaction_idx3 on interaction (phenotype_id);
GRANT ALL on interaction to PUBLIC;

create table interaction_subj (
       interaction_subj_id serial not null,
       primary key (interaction_subj_id),
       feature_id int not null,
       foreign key (feature_id) references feature (feature_id),
       interaction_id int not null,
       foreign key (interaction_id) references interaction (interaction_id),
       unique(feature_id,interaction_id)
);
GRANT ALL on interaction_s_interaction_s_seq to PUBLIC;
GRANT ALL on interaction_subj to PUBLIC;

create index interaction_subj_idx1 on interaction_subj (feature_id);
GRANT ALL on interaction_subj to PUBLIC;

create index interaction_subj_idx2 on interaction_subj (interaction_id);
GRANT ALL on interaction_subj to PUBLIC;

create table interaction_obj (
       interaction_obj_id serial not null,
       primary key (interaction_obj_id),
       feature_id int not null,
       foreign key (feature_id) references feature (feature_id),
       interaction_id int not null,
       foreign key (interaction_id) references interaction (interaction_id),
       unique(feature_id,interaction_id)
);
GRANT ALL on interaction_o_interaction_o_seq to PUBLIC;
GRANT ALL on interaction_obj to PUBLIC;

create index interaction_obj_idx1 on interaction_obj (feature_id);
GRANT ALL on interaction_obj to PUBLIC;

create index interaction_obj_idx2 on interaction_obj (interaction_id);
GRANT ALL on interaction_obj to PUBLIC;

create table analysis (
    analysis_id serial not null,
    primary key (analysis_id),
    name varchar(255),
    description text,
    program varchar(255) not null,
    programversion varchar(255) not null,
    algorithm varchar(255),
    sourcename varchar(255),
    sourceversion varchar(255),
    sourceuri text,
    queryfeature_id int,
    foreign key (queryfeature_id) references feature (feature_id),
    timeexecuted timestamp not null default current_timestamp,
    unique(program, programversion, sourcename)
);
GRANT ALL on analysis_analysis_id_seq to PUBLIC;
GRANT ALL on analysis to PUBLIC;

create index analysis_idx1 on analysis (queryfeature_id);
GRANT ALL on analysis to PUBLIC;

create table analysisprop (
    analysisprop_id serial not null,
    primary key (analysisprop_id),
    analysis_id int not null,
    foreign key (analysis_id) references analysis (analysis_id),
    pkey_id int not null,
    foreign key (pkey_id) references cvterm (cvterm_id),
    pval text,
    unique(analysis_id, pkey_id, pval)
);
GRANT ALL on analysisprop_analysisprop_i_seq to PUBLIC;
GRANT ALL on analysisprop to PUBLIC;

create index analysisprop_idx1 on analysisprop (analysis_id);
GRANT ALL on analysisprop to PUBLIC;

create index analysisprop_idx2 on analysisprop (pkey_id);
GRANT ALL on analysisprop to PUBLIC;

create table analysisfeature (
    analysisfeature_id serial not null,
    primary key (analysisfeature_id),
    feature_id int not null,
    foreign key (feature_id) references feature (feature_id),
    analysis_id int not null,
    foreign key (analysis_id) references analysis (analysis_id),
    rawscore double precision,
    normscore double precision,
    significance double precision,
    identity double precision,
    unique (feature_id,analysis_id)
);
GRANT ALL on analysisfeatu_analysisfeatu_seq to PUBLIC;
GRANT ALL on analysisfeature to PUBLIC;

create index analysisfeature_idx1 on analysisfeature (feature_id);
GRANT ALL on analysisfeature to PUBLIC;

create index analysisfeature_idx2 on analysisfeature (analysis_id);
GRANT ALL on analysisfeature to PUBLIC;

create table expression (
       expression_id serial not null,
       primary key (expression_id),
       description text
);
GRANT ALL on expression_expression_id_seq to PUBLIC;
GRANT ALL on expression to PUBLIC;

create table feature_expression (
       feature_expression_id serial not null,
       primary key (feature_expression_id),
       expression_id int not null,
       foreign key (expression_id) references expression (expression_id),
       feature_id int not null,
       foreign key (feature_id) references feature (feature_id),
       unique(expression_id,feature_id)       
);
GRANT ALL on feature_expre_feature_expre_seq to PUBLIC;
GRANT ALL on feature_expression to PUBLIC;

create index feature_expression_idx1 on feature_expression (expression_id);
GRANT ALL on feature_expression to PUBLIC;

create index feature_expression_idx2 on feature_expression (feature_id);
GRANT ALL on feature_expression to PUBLIC;

create table expression_cvterm (
       expression_cvterm_id serial not null,
       primary key (expression_cvterm_id),
       expression_id int not null,
       foreign key (expression_id) references expression (expression_id),
       cvterm_id int not null,
       foreign key (cvterm_id) references cvterm (cvterm_id),
       rank int not null,
       unique(expression_id,cvterm_id)
);
GRANT ALL on expression_cv_expression_cv_seq to PUBLIC;
GRANT ALL on expression_cvterm to PUBLIC;

create index expression_cvterm_idx1 on expression_cvterm (expression_id);
GRANT ALL on expression_cvterm to PUBLIC;

create index expression_cvterm_idx2 on expression_cvterm (cvterm_id);
GRANT ALL on expression_cvterm to PUBLIC;

create table expression_pub (
       expression_pub_id serial not null,
       primary key (expression_pub_id),
       expression_id int not null,
       foreign key (expression_id) references expression (expression_id),
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id),
       unique(expression_id,pub_id)       
);
GRANT ALL on expression_pu_expression_pu_seq to PUBLIC;
GRANT ALL on expression_pub to PUBLIC;

create index expression_pub_idx1 on expression_pub (expression_id);
GRANT ALL on expression_pub to PUBLIC;

create index expression_pub_idx2 on expression_pub (pub_id);
GRANT ALL on expression_pub to PUBLIC;

create table eimage (
       eimage_id serial not null,
       primary key (eimage_id),
       eimage_data text,
       eimage_type varchar(255) not null,
       image_uri varchar(255)
);
GRANT ALL on eimage_eimage_id_seq to PUBLIC;
GRANT ALL on eimage to PUBLIC;

create table expression_image (
       expression_image_id serial not null,
       primary key (expression_image_id),
       expression_id int not null,
       foreign key (expression_id) references expression (expression_id),
       eimage_id int not null,
       foreign key (eimage_id) references eimage (eimage_id),
       unique(expression_id,eimage_id)
);
GRANT ALL on expression_im_expression_im_seq to PUBLIC;
GRANT ALL on expression_image to PUBLIC;

create index expression_image_idx1 on expression_image (expression_id);
GRANT ALL on expression_image to PUBLIC;

create index expression_image_idx2 on expression_image (eimage_id);
GRANT ALL on expression_image to PUBLIC;

create table featuremap (
       featuremap_id serial not null,
       primary key (featuremap_id),
       mapname varchar(255),
       mapdesc varchar(255),
       mapunit varchar(255),
       unique(mapname)
);
GRANT ALL on featuremap_featuremap_id_seq to PUBLIC;
GRANT ALL on featuremap to PUBLIC;

create table featurerange (
       featurerange_id serial not null,
       primary key (featurerange_id),
       featuremap_id int not null,
       foreign key (featuremap_id) references featuremap (featuremap_id),
       feature_id int not null,
       foreign key (feature_id) references feature (feature_id),
       leftstartf_id int not null,
       foreign key (leftstartf_id) references feature (feature_id),       
       leftendf_id int,
       foreign key (leftendf_id) references feature (feature_id),       
       rightstartf_id int,
       foreign key (rightstartf_id) references feature (feature_id),       
       rightendf_id int not null,
       foreign key (rightendf_id) references feature (feature_id),
       rangestr varchar(255)
);
GRANT ALL on featurerange_featurerange_i_seq to PUBLIC;
GRANT ALL on featurerange to PUBLIC;

create index featurerange_idx1 on featurerange (featuremap_id);
GRANT ALL on featurerange to PUBLIC;

create index featurerange_idx2 on featurerange (feature_id);
GRANT ALL on featurerange to PUBLIC;

create index featurerange_idx3 on featurerange (leftstartf_id);
GRANT ALL on featurerange to PUBLIC;

create index featurerange_idx4 on featurerange (leftendf_id);
GRANT ALL on featurerange to PUBLIC;

create index featurerange_idx5 on featurerange (rightstartf_id);
GRANT ALL on featurerange to PUBLIC;

create index featurerange_idx6 on featurerange (rightendf_id);
GRANT ALL on featurerange to PUBLIC;

create table featurepos (
       featurepos_id serial not null,
       primary key (featurepos_id),
       featuremap_id serial not null,
       foreign key (featuremap_id) references featuremap (featuremap_id),
       feature_id int not null,
       foreign key (feature_id) references feature (feature_id),
       map_feature_id int not null,
       foreign key (map_feature_id) references feature (feature_id),
       mappos float not null
);
GRANT ALL on featurepos_featuremap_id_seq to PUBLIC;
GRANT ALL on featurepos to PUBLIC;

create index featurepos_idx1 on featurepos (featuremap_id);
GRANT ALL on featurepos to PUBLIC;

create index featurepos_idx2 on featurepos (feature_id);
GRANT ALL on featurepos to PUBLIC;

create index featurepos_idx3 on featurepos (map_feature_id);
GRANT ALL on featurepos to PUBLIC;

create table featuremap_pub (
       featuremap_pub_id serial not null,
       primary key (featuremap_pub_id),
       featuremap_id int not null,
       foreign key (featuremap_id) references featuremap (featuremap_id),
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id)
);
GRANT ALL on featuremap_pu_featuremap_pu_seq to PUBLIC;
GRANT ALL on featuremap_pub to PUBLIC;

create index featuremap_pub_idx1 on featuremap_pub (featuremap_id);
GRANT ALL on featuremap_pub to PUBLIC;

create index featuremap_pub_idx2 on featuremap_pub (pub_id);
GRANT ALL on featuremap_pub to PUBLIC;

