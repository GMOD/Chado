create table dbxref (
       dbxref_id serial not null,
       primary key (dbxref_id),
       dbname varchar(255) not null,
       accession varchar(255) not null,
       version varchar(255) not null default '',
       dbxrefdescription text,
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp,
       unique (dbname, accession, version)
);
GRANT ALL on dbxref_dbxref_id_seq to PUBLIC;
GRANT ALL on dbxref to PUBLIC;

create table synonym (
       synonym_id serial not null,
       primary key (synonym_id),
       synonym varchar(255) not null,
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp,
       unique(synonym)
);
GRANT ALL on synonym_synonym_id_seq to PUBLIC;
GRANT ALL on synonym to PUBLIC;

create table cvterm (
       cvterm_id serial not null,
       primary key (cvterm_id),
       termname varchar(255) not null,
       termdefinition text,
       termtype_id int,
       foreign key (termtype_id) references cvterm (cvterm_id),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp,
       unique(termname, termtype_id)
);
GRANT ALL on cvterm_cvterm_id_seq to PUBLIC;
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
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp,
       unique(reltype_id, subjterm_id, objterm_id)
);
GRANT ALL on cvrelationshi_cvrelationshi_seq to PUBLIC;
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
       termtype_id int not null,
       foreign key (termtype_id) references cvterm (cvterm_id),
       pathdistance int,
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp,
       unique (subjterm_id, objterm_id)
);
GRANT ALL on cvpath_cvpath_id_seq to PUBLIC;
GRANT ALL on cvpath to PUBLIC;

create table cvterm_synonym (
       cvterm_id int not null,
       foreign key (cvterm_id) references cvterm (cvterm_id),
       termsynonym varchar(255) not null,
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp,
       unique(cvterm_id, termsynonym)
);
GRANT ALL on cvterm_synonym to PUBLIC;

create table cvterm_dbxref (
       cvterm_id int not null,
       foreign key (cvterm_id) references cvterm (cvterm_id),
       dbxref_id int not null,
       foreign key (dbxref_id) references dbxref (dbxref_id),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp,
       unique(cvterm_id, dbxref_id)
);
GRANT ALL on cvterm_dbxref to PUBLIC;

create table organism (
	organism_id serial not null,
	primary key (organism_id),
	abbrev varchar(255) null,
	genus varchar(255) null,
	taxgroup varchar(255) null,
	species varchar(255) null,
	common_name varchar(255) null,
	comment text null,
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp,
	unique(abbrev),
	unique(taxgroup, genus, species, comment)
);
GRANT ALL on organism_organism_id_seq to PUBLIC;
GRANT ALL on organism to PUBLIC;

create table organism_dbxref (
       organism_dbxref_id serial not null,
       primary key (organism_dbxref_id),
       organism_id int,
       foreign key (organism_id) references organism (organism_id),
       dbxref_id int,
       foreign key (dbxref_id) references dbxref (dbxref_id),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp
);
GRANT ALL on organism_dbxr_organism_dbxr_seq to PUBLIC;
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
       type_id int not null,
       foreign key (type_id) references cvterm (cvterm_id),
       is_obsolete boolean default 'false',
       publisher varchar(255),
       pubplace varchar(255),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp
);
GRANT ALL on pub_pub_id_seq to PUBLIC;
GRANT ALL on pub to PUBLIC;

create table pub_relationship (
       subj_pub_id int not null,
       foreign key (subj_pub_id) references pub (pub_id),
       obj_pub_id int not null,
       foreign key (obj_pub_id) references pub (pub_id),
       type_id int not null,
       foreign key (type_id) references cvterm (cvterm_id),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp,
       unique(subj_pub_id, obj_pub_id, type_id)
);
GRANT ALL on pub_relationship to PUBLIC;

create table pub_dbxref (
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id),
       dbxref_id int not null,
       foreign key (dbxref_id) references dbxref (dbxref_id),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp,
       unique(pub_id,dbxref_id)
);
GRANT ALL on pub_dbxref to PUBLIC;

create index pub_dbxref_ind1 on pub_dbxref (dbxref_id);
GRANT ALL on pub_dbxref to PUBLIC;

create table author (
       author_id serial not null,
       primary key (author_id),
       surname varchar(255) not null,
       givennames varchar(255),
       suffix varchar(255),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp
);
GRANT ALL on author_author_id_seq to PUBLIC;
GRANT ALL on author to PUBLIC;

create table pub_author (
       author_id int not null,
       foreign key (author_id) references author (author_id),
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id),
       arank int not null,
       editor boolean default 'false',
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp
);
GRANT ALL on pub_author to PUBLIC;

create table pubprop (
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id),
       pkey_id int not null,
       foreign key (pkey_id) references cvterm (cvterm_id),
       pval text not null,
       prank integer,
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp,
       unique(pub_id,pkey_id,pval)
);
GRANT ALL on pubprop to PUBLIC;

create table feature (
       feature_id serial not null,
       primary key (feature_id),
       name varchar(255) not null,
       end5 int,
       end3 int,
       strand smallint,
       residues text,
       seqlen int,
       md5checksum char(32),
       type_id int,
       foreign key (type_id) references cvterm (cvterm_id),
       source_feature_id int,
       foreign key (source_feature_id) references feature (feature_id),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp,
       unique(name, fmin, fmax, fstrand, seqlen, md5checksum, type_id)
);
GRANT ALL on feature_feature_id_seq to PUBLIC;
GRANT ALL on feature to PUBLIC;

create table feature_pub (
       feature_id int not null,
       foreign key (feature_id) references feature (feature_id),
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp,
       unique(feature_id, pub_id)
);
GRANT ALL on feature_pub to PUBLIC;

create table featureprop (
       featureprop_id serial not null,
       primary key (featureprop_id),
       feature_id int not null,
       foreign key (feature_id) references feature (feature_id),
       pkey_id int not null,
       foreign key (pkey_id) references cvterm (cvterm_id),
       pval text not null,
       prank integer,
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp,
       unique(feature_id, pkey_id, pval, prank)
);
GRANT ALL on featureprop_featureprop_id_seq to PUBLIC;
GRANT ALL on featureprop to PUBLIC;

create table featureprop_pub (
       featureprop_id int not null,
       foreign key (featureprop_id) references featureprop (featureprop_id),
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp,
       unique(featureprop_id, pub_id)
);
GRANT ALL on featureprop_pub to PUBLIC;

create table feature_dbxref (
       feature_dbxref_id serial not null,
       primary key (feature_dbxref_id),
       feature_id int,
       foreign key (feature_id) references feature (feature_id),
       dbxref_id int,
       foreign key (dbxref_id) references dbxref (dbxref_id),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp,
       unique(feature_dbxref_id, dbxref_id)
);
GRANT ALL on feature_dbxre_feature_dbxre_seq to PUBLIC;
GRANT ALL on feature_dbxref to PUBLIC;

create table feature_relationship (
       feature_relationship_id serial not null,
       primary key (feature_relationship_id),
       subjfeature_id int not null,
       foreign key (subjfeature_id) references feature (feature_id),
       objfeature_id int not null,
       foreign key (objfeature_id) references feature (feature_id),
       type_id int,
       foreign key (type_id) references cvterm (cvterm_id),
       relrank int,
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp,
       unique(subjfeature_id, objfeature_id, type_id)
);
GRANT ALL on feature_relat_feature_relat_seq to PUBLIC;
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
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp,
       unique(feature_id, cvterm_id, pub_id)
);
GRANT ALL on feature_cvter_feature_cvter_seq to PUBLIC;
GRANT ALL on feature_cvterm to PUBLIC;

create table gene (
       gene_id serial not null,
       primary key (gene_id),
       name varchar(255) not null,
       type_id int,
       foreign key (type_id) references cvterm (cvterm_id),
       dbxref_id int,
       foreign key (dbxref_id) references dbxref(dbxref_id),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp,
       unique(name),
       unique(dbxref_id)
);
GRANT ALL on gene_gene_id_seq to PUBLIC;
GRANT ALL on gene to PUBLIC;

create table gene_synonym (
       synonym_id int not null,
       foreign key (synonym_id) references synonym (synonym_id),
       gene_id int not null,
       foreign key (gene_id) references gene (gene_id),
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id),
       is_internal boolean not null default 'false',
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp,
       unique(synonym_id, gene_id, pub_id)
);
GRANT ALL on gene_synonym to PUBLIC;

create table gene_feature (
       gene_id int not null,
       foreign key (gene_id) references gene (gene_id),
       feature_id int not null,
       foreign key (feature_id) references feature (feature_id),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp,
       unique(gene_id, feature_id)
);
GRANT ALL on gene_feature to PUBLIC;

create table feature_organism (
       feature_id int not null,
       foreign key (feature_id) references feature (feature_id),
       organism_id int not null,
       foreign key (organism_id) references organism (organism_id),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp
);
GRANT ALL on feature_organism to PUBLIC;

create table feature_synonym (
       synonym_id int not null,
       foreign key (synonym_id) references synonym (synonym_id),
       feature_id int not null,
       foreign key (feature_id) references feature (feature_id),
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id),
       is_internal boolean not null default 'false',
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp,
       unique(synonym_id, feature_id, pub_id)
);
GRANT ALL on feature_synonym to PUBLIC;

create table genotype (
       genotype_id serial not null,
       primary key (genotype_id),
       description varchar(255),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp
);
GRANT ALL on genotype_genotype_id_seq to PUBLIC;
GRANT ALL on genotype to PUBLIC;

create table feature_genotype (
       feature_id int,
       foreign key (feature_id) references feature (feature_id),
       genotype_id int,
       foreign key (genotype_id) references genotype (genotype_id),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp
);
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
       foreign key (background_genotype_id) references genotype (genotype_id),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp
);
GRANT ALL on phenotype_phenotype_id_seq to PUBLIC;
GRANT ALL on phenotype to PUBLIC;

create table feature_phenotype (
       feature_id int not null,
       foreign key (feature_id) references feature (feature_id),
       phenotype_id int not null,
       foreign key (phenotype_id) references phenotype (phenotype_id),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp
);
GRANT ALL on feature_phenotype to PUBLIC;

create table phenotype_cvterm (
       phenotype_id int not null,
       foreign key (phenotype_id) references phenotype (phenotype_id),
       cvterm_id int not null,
       foreign key (cvterm_id) references cvterm (cvterm_id),
       prank int not null,
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp
);
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
       foreign key (phenotype_id) references phenotype (phenotype_id),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp
);
GRANT ALL on interaction_interaction_id_seq to PUBLIC;
GRANT ALL on interaction to PUBLIC;

create table interaction_subj (
       feature_id int not null,
       foreign key (feature_id) references feature (feature_id),
       interaction_id int not null,
       foreign key (interaction_id) references interaction (interaction_id),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp
);
GRANT ALL on interaction_subj to PUBLIC;

create table interaction_obj (
       feature_id int not null,
       foreign key (feature_id) references feature (feature_id),
       interaction_id int not null,
       foreign key (interaction_id) references interaction (interaction_id),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp
);
GRANT ALL on interaction_obj to PUBLIC;

create table analysis (
    analysis_id serial not null,
    primary key (analysis_id),
    name varchar(255),
    adesc text,
    timeentered timestamp not null default current_timestamp,
    timelastmod timestamp not null default current_timestamp
);
GRANT ALL on analysis_analysis_id_seq to PUBLIC;
GRANT ALL on analysis to PUBLIC;

create table analysisprop (
    analysis_id int not null,
    foreign key (analysis_id) references analysis (analysis_id),
    pkey_id int not null,
    foreign key (pkey_id) references cvterm (cvterm_id),
    pval text,
    timeentered timestamp not null default current_timestamp,
    timelastmod timestamp not null default current_timestamp
);
GRANT ALL on analysisprop to PUBLIC;

create table featurepair (
    featurepair_id serial not null,
    primary key (featurepair_id),
    analysis_id int not null,
    foreign key (analysis_id) references analysis (analysis_id),
    feature1_id int not null,
    foreign key (feature1_id) references feature (feature_id),
    feature2_id int not null,
    foreign key (feature2_id) references feature (feature_id),
    scorestr varchar(255),
    timeentered timestamp not null default current_timestamp,
    timelastmod timestamp not null default current_timestamp
);
GRANT ALL on featurepair_featurepair_id_seq to PUBLIC;
GRANT ALL on featurepair to PUBLIC;

create table multalign (
    multalign_id serial not null,
    primary key (multalign_id),
    analysis_id int not null,
    foreign key (analysis_id)  references analysis (analysis_id),
    scorestr varchar(255),
    timeentered timestamp not null default current_timestamp,
    timelastmod timestamp not null default current_timestamp
);
GRANT ALL on multalign_multalign_id_seq to PUBLIC;
GRANT ALL on multalign to PUBLIC;

create table multalign_feature (
    multalign_id int not null,
    foreign key (multalign_id) references multalign (multalign_id),
    feature_id int not null,
    foreign key (feature_id) references feature (feature_id),
    timeentered timestamp not null default current_timestamp,
    timelastmod timestamp not null default current_timestamp
);
GRANT ALL on multalign_feature to PUBLIC;

create table expression (
       expression_id serial not null,
       primary key (expression_id),
       description text,
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp
);
GRANT ALL on expression_expression_id_seq to PUBLIC;
GRANT ALL on expression to PUBLIC;

create table feature_expression (
       expression_id int not null,
       foreign key (expression_id) references expression (expression_id),
       feature_id int not null,
       foreign key (feature_id) references feature (feature_id),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp
);
GRANT ALL on feature_expression to PUBLIC;

create table expression_cvterm (
       expression_id int not null,
       foreign key (expression_id) references expression (expression_id),
       cvterm_id int not null,
       foreign key (cvterm_id) references cvterm (cvterm_id),
       rank int not null,
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp
);
GRANT ALL on expression_cvterm to PUBLIC;

create table expression_pub (
       expression_id int not null,
       foreign key (expression_id) references expression (expression_id),
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp
);
GRANT ALL on expression_pub to PUBLIC;

create table eimage (
       eimage_id serial not null,
       primary key (eimage_id),
       eimage_data text,
       eimage_type varchar(255) not null,
       image_uri varchar(255),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp
);
GRANT ALL on eimage_eimage_id_seq to PUBLIC;
GRANT ALL on eimage to PUBLIC;

create table expression_image (
       expression_id int not null,
       foreign key (expression_id) references expression (expression_id),
       eimage_id int not null,
       foreign key (eimage_id) references eimage (eimage_id),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp
);
GRANT ALL on expression_image to PUBLIC;

create table featuremap (
       featuremap_id serial not null,
       primary key (featuremap_id),
       mapname varchar(255),
       mapdesc varchar(255),
       mapunit varchar(255),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp
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
       rangestr varchar(255),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp
);
GRANT ALL on featurerange_featurerange_i_seq to PUBLIC;
GRANT ALL on featurerange to PUBLIC;

create table featurepos (
       featuremap_id serial not null,
       foreign key (featuremap_id) references featuremap (featuremap_id),
       feature_id int not null,
       foreign key (feature_id) references feature (feature_id),
       map_feature_id int not null,
       foreign key (map_feature_id) references feature (feature_id),
       mappos float not null,
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp
);
GRANT ALL on featurepos_featuremap_id_seq to PUBLIC;
GRANT ALL on featurepos to PUBLIC;

create table featuremap_pub (
       featuremap_id int not null,
       foreign key (featuremap_id) references featuremap (featuremap_id),
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp
);
GRANT ALL on featuremap_pub to PUBLIC;

