create table dbxref_audit (
       dbxref_id int not null,
       dbname varchar(255) not null,
       accession varchar(255) not null,
       version varchar(255) not null default '',
       dbxrefdescription text,
       timeentered timestamp not null,
       timelastmod timestamp not null,
	transaction_date timestamp not null,
	transaction_type char not null
);
GRANT ALL on dbxref_audit to PUBLIC;

create table synonym_audit (
       synonym_id int not null,
       synonym varchar(255) not null,
       timeentered timestamp not null,
       timelastmod timestamp not null,
	transaction_date timestamp not null,
	transaction_type char not null
);
GRANT ALL on synonym_audit to PUBLIC;

create table cvterm_audit (
       cvterm_id int not null,
       dbxref_id int,
       termname varchar(255) not null,
       termdefinition text,
       termtype_id int,
       timeentered timestamp not null,
       timelastmod timestamp not null,
	transaction_date timestamp not null,
	transaction_type char not null
);
GRANT ALL on cvterm_audit to PUBLIC;

create table cvrelationship_audit (
       cvrelationship_id int not null,
       reltype_id int not null,
       subjterm_id int not null,
       objterm_id int not null,
       timeentered timestamp not null,
       timelastmod timestamp not null,
	transaction_date timestamp not null,
	transaction_type char not null
);
GRANT ALL on cvrelationship_audit to PUBLIC;

create table cvpath_audit (
       cvpath_id int not null,
       reltype_id int,
       subjterm_id int not null,
       objterm_id int not null,
       pathdistance int,
       timeentered timestamp not null,
       timelastmod timestamp not null,
	transaction_date timestamp not null,
	transaction_type char not null
);
GRANT ALL on cvpath_audit to PUBLIC;

create table cvterm_synonym_audit (
       cvterm_id int not null,
       termsynonym varchar(255) not null,
       timeentered timestamp not null,
       timelastmod timestamp not null,
	transaction_date timestamp not null,
	transaction_type char not null
);
GRANT ALL on cvterm_synonym_audit to PUBLIC;

create table cvterm_dbxref_audit (
       cvterm_id int not null,
       dbxref_id int not null,
       timeentered timestamp not null,
       timelastmod timestamp not null,
	transaction_date timestamp not null,
	transaction_type char not null
);
GRANT ALL on cvterm_dbxref_audit to PUBLIC;

create table organism_audit (
	organism_id int not null,
	abbrev varchar(255) null,
	genus varchar(255) null,
	taxgroup varchar(255) null,
	species varchar(255) null,
	common_name varchar(255) null,
	comment text null,
       timeentered timestamp not null,
       timelastmod timestamp not null,
	transaction_date timestamp not null,
	transaction_type char not null
);
GRANT ALL on organism_audit to PUBLIC;

create table organism_dbxref_audit (
       organism_dbxref_id int not null,
       organism_id int,
       dbxref_id int,
       timeentered timestamp not null,
       timelastmod timestamp not null,
	transaction_date timestamp not null,
	transaction_type char not null
);
GRANT ALL on organism_dbxref_audit to PUBLIC;

create table pub_audit (
       pub_id int not null,
       title text,
       abbreviation varchar(255),
       volumetitle text,
       volume  varchar(255),
       abstract text,
       languages varchar(255),
       series_name varchar(255),
       series_abbrev  varchar(255),
       issue  varchar(255),
       pyear  varchar(255),
       pages  varchar(255),
       type_id varchar(255),
       is_obsolete boolean default 'false',
       publisher varchar(255),
       pubplace varchar(255),
       miniref varchar(255),
       timeentered timestamp not null,
       timelastmod timestamp not null,
	transaction_date timestamp not null,
	transaction_type char not null
);
GRANT ALL on pub_audit to PUBLIC;

create table pub_relationship_audit (
       subj_pub_id int not null,
       obj_pub_id int not null,
       type_id int not null,
       timeentered timestamp not null,
       timelastmod timestamp not null,
	transaction_date timestamp not null,
	transaction_type char not null
);
GRANT ALL on pub_relationship_audit to PUBLIC;

create table pub_dbxref_audit (
       pub_id int not null,
       dbxref_id int not null,
       timeentered timestamp not null,
       timelastmod timestamp not null,
	transaction_date timestamp not null,
	transaction_type char not null
);
GRANT ALL on pub_dbxref_audit to PUBLIC;

create table author_audit (
       author_id int not null,
       surname varchar(255) not null,
       givennames varchar(255),
       suffix varchar(255),
       timeentered timestamp not null,
       timelastmod timestamp not null,
	transaction_date timestamp not null,
	transaction_type char not null
);
GRANT ALL on author_audit to PUBLIC;

create table pub_author_audit (
       author_id int not null,
       pub_id int not null,
       arank int not null,
       timeentered timestamp not null,
       timelastmod timestamp not null,
	transaction_date timestamp not null,
	transaction_type char not null
);
GRANT ALL on pub_author_audit to PUBLIC;

create table pubprop_audit (
       pub_id int not null,
       pkey_id int not null,
       pval text not null,
       prank integer,
       timeentered timestamp not null,
       timelastmod timestamp not null,
	transaction_date timestamp not null,
	transaction_type char not null
);
GRANT ALL on pubprop_audit to PUBLIC;

create table feature_audit (
       feature_id int not null,
       name varchar(255) not null,
       dbxref_id int,
       fmin int,
       fmax int,
       fstrand smallint,
       residues text,
       seqlen int,
       md5checksum char(32),
       type_id int,
       source_feature_id int,
       timeentered timestamp not null,
       timelastmod timestamp not null,
	transaction_date timestamp not null,
	transaction_type char not null
);
GRANT ALL on feature_audit to PUBLIC;

create table featureprop_audit (
       featureprop_id int not null,
       feature_id int,
       pkey_id int not null,
       pval text not null,
       prank integer,
       timeentered timestamp not null,
       timelastmod timestamp not null,
	transaction_date timestamp not null,
	transaction_type char not null
);
GRANT ALL on featureprop_audit to PUBLIC;

create table featureprop_pub_audit (
       featureprop_id int not null,
       pub_id int not null,
       timeentered timestamp not null,
       timelastmod timestamp not null,
	transaction_date timestamp not null,
	transaction_type char not null
);
GRANT ALL on featureprop_pub_audit to PUBLIC;

create table feature_dbxref_audit (
       feature_dbxref_id int not null,
       feature_id int,
       dbxref_id int,
       timeentered timestamp not null,
       timelastmod timestamp not null,
	transaction_date timestamp not null,
	transaction_type char not null
);
GRANT ALL on feature_dbxref_audit to PUBLIC;

create table feature_relationship_audit (
       feature_relationship_id int not null,
       subjfeature_id int,
       objfeature_id int,
       type_id int,
       relrank int,
       timeentered timestamp not null,
       timelastmod timestamp not null,
	transaction_date timestamp not null,
	transaction_type char not null
);
GRANT ALL on feature_relationship_audit to PUBLIC;

create table feature_cvterm_audit (
       feature_cvterm_id int not null,
       feature_id int not null,
       cvterm_id int not null,
       pub_id int not null,
       timeentered timestamp not null,
       timelastmod timestamp not null,
	transaction_date timestamp not null,
	transaction_type char not null
);
GRANT ALL on feature_cvterm_audit to PUBLIC;

create table gene_audit (
       gene_id int not null,
       name varchar(255) not null,
       dbxref_id int,
       timeentered timestamp not null,
       timelastmod timestamp not null,
	transaction_date timestamp not null,
	transaction_type char not null
);
GRANT ALL on gene_audit to PUBLIC;

create table gene_synonym_audit (
       synonym_id int not null,
       gene_id int not null,
       pub_id int not null,
       is_internal boolean not null default 'false',
       timeentered timestamp not null,
       timelastmod timestamp not null,
	transaction_date timestamp not null,
	transaction_type char not null
);
GRANT ALL on gene_synonym_audit to PUBLIC;

create table gene_feature_audit (
       gene_id int not null,
       feature_id int not null,
       timeentered timestamp not null,
       timelastmod timestamp not null,
	transaction_date timestamp not null,
	transaction_type char not null
);
GRANT ALL on gene_feature_audit to PUBLIC;

create table feature_organism_audit (
       feature_id int not null,
       organism_id int not null,
       timeentered timestamp not null,
       timelastmod timestamp not null,
	transaction_date timestamp not null,
	transaction_type char not null
);
GRANT ALL on feature_organism_audit to PUBLIC;

create table feature_synonym_audit (
       synonym_id int not null,
       feature_id int not null,
       pub_id int not null,
       is_internal boolean not null default 'false',
       timeentered timestamp not null,
       timelastmod timestamp not null,
	transaction_date timestamp not null,
	transaction_type char not null
);
GRANT ALL on feature_synonym_audit to PUBLIC;

create table allele_audit (
       allele_id int not null,
       dbxref_id int,
       fullsymbol varchar(255) not null,
       designator varchar(255) not null,
       gene_id int not null,
       causative_feature_id int,
       gene_feature_id int,
       is_wildtype boolean not null,
       timeentered timestamp not null,
       timelastmod timestamp not null,
	transaction_date timestamp not null,
	transaction_type char not null
);
GRANT ALL on allele_audit to PUBLIC;

create table alleleprop_audit (
       alleleprop_id int not null,
       allele_id int not null,
       pkey_id int not null,
       pval text not null,
       timeentered timestamp not null,
       timelastmod timestamp not null,
	transaction_date timestamp not null,
	transaction_type char not null
);
GRANT ALL on alleleprop_audit to PUBLIC;

create table alleleprop_pub_audit (
       alleleprop_id int not null,
       pub_id int not null,
       timeentered timestamp not null,
       timelastmod timestamp not null,
	transaction_date timestamp not null,
	transaction_type char not null
);
GRANT ALL on alleleprop_pub_audit to PUBLIC;

create table allele_cvterm_audit (
       allele_id int not null,
       cvterm_id int not null,
       timeentered timestamp not null,
       timelastmod timestamp not null,
	transaction_date timestamp not null,
	transaction_type char not null
);
GRANT ALL on allele_cvterm_audit to PUBLIC;

create table genotype_audit (
       genotype_id int not null,
       description varchar(255),
       timeentered timestamp not null,
       timelastmod timestamp not null,
	transaction_date timestamp not null,
	transaction_type char not null
);
GRANT ALL on genotype_audit to PUBLIC;

create table allele_genotype_audit (
       allele_id int not null,
       genotype_id int,
       timeentered timestamp not null,
       timelastmod timestamp not null,
	transaction_date timestamp not null,
	transaction_type char not null
);
GRANT ALL on allele_genotype_audit to PUBLIC;

create table feature_genotype_audit (
       feature_id int,
       genotype_id int,
       timeentered timestamp not null,
       timelastmod timestamp not null,
	transaction_date timestamp not null,
	transaction_type char not null
);
GRANT ALL on feature_genotype_audit to PUBLIC;

create table phenotype_audit (
       phenotype_id int not null,
       description text,
       pub_id int not null,
       background_genotype_id int,
       timeentered timestamp not null,
       timelastmod timestamp not null,
	transaction_date timestamp not null,
	transaction_type char not null
);
GRANT ALL on phenotype_audit to PUBLIC;

create table allele_phenotype_audit (
       allele_id int not null,
       phenotype_id int not null,
       timeentered timestamp not null,
       timelastmod timestamp not null,
	transaction_date timestamp not null,
	transaction_type char not null
);
GRANT ALL on allele_phenotype_audit to PUBLIC;

create table phenoype_cvterm_audit (
       phenotype_id int not null,
       cvterm_id int not null,
       timeentered timestamp not null,
       timelastmod timestamp not null,
	transaction_date timestamp not null,
	transaction_type char not null
);
GRANT ALL on phenoype_cvterm_audit to PUBLIC;

create table interaction_audit (
       interaction_id int not null,
       description text,
       pub_id int not null,
       background_genotype_id int,
       phenotype_id int,
       timeentered timestamp not null,
       timelastmod timestamp not null,
	transaction_date timestamp not null,
	transaction_type char not null
);
GRANT ALL on interaction_audit to PUBLIC;

create table interaction_subj_audit (
       allele_id int not null,
       interaction_id int not null,
       timeentered timestamp not null,
       timelastmod timestamp not null,
	transaction_date timestamp not null,
	transaction_type char not null
);
GRANT ALL on interaction_subj_audit to PUBLIC;

create table interaction_obj_audit (
       allele_id int not null,
       interaction_id int not null,
       timeentered timestamp not null,
       timelastmod timestamp not null,
	transaction_date timestamp not null,
	transaction_type char not null
);
GRANT ALL on interaction_obj_audit to PUBLIC;

create table analysis_audit (
    analysis_id int not null,
    name varchar(255),
    adesc text,
    timeentered timestamp not null,
    timelastmod timestamp not null,
	transaction_date timestamp not null,
	transaction_type char not null
);
GRANT ALL on analysis_audit to PUBLIC;

create table analysisprop_audit (
    analysis_id int not null,
    pkey_id int not null,
    pval text,
    timeentered timestamp not null,
    timelastmod timestamp not null,
	transaction_date timestamp not null,
	transaction_type char not null
);
GRANT ALL on analysisprop_audit to PUBLIC;

create table featurepair_audit (
    featurepair_id int not null,
    analysis_id int not null,
    feature1_id int not null,
    feature2_id int not null,
    scorestr varchar(255),
    timeentered timestamp not null,
    timelastmod timestamp not null,
	transaction_date timestamp not null,
	transaction_type char not null
);
GRANT ALL on featurepair_audit to PUBLIC;

create table multalign_audit (
    multalign_id int not null,
    analysis_id int not null,
    scorestr varchar(255),
    timeentered timestamp not null,
    timelastmod timestamp not null,
	transaction_date timestamp not null,
	transaction_type char not null
);
GRANT ALL on multalign_audit to PUBLIC;

create table multalign_feature_audit (
    multalign_id int not null,
    feature_id int not null,
    timeentered timestamp not null,
    timelastmod timestamp not null,
	transaction_date timestamp not null,
	transaction_type char not null
);
GRANT ALL on multalign_feature_audit to PUBLIC;

create table expression_audit (
       expression_id int not null,
       description text,
       timeentered timestamp not null,
       timelastmod timestamp not null,
	transaction_date timestamp not null,
	transaction_type char not null
);
GRANT ALL on expression_audit to PUBLIC;

create table feature_expression_audit (
       expression_id int not null,
       feature_id int not null,
       timeentered timestamp not null,
       timelastmod timestamp not null,
	transaction_date timestamp not null,
	transaction_type char not null
);
GRANT ALL on feature_expression_audit to PUBLIC;

create table expression_cvterm_audit (
       expression_id int not null,
       cvterm_id int not null,
       rank int not null,
       timeentered timestamp not null,
       timelastmod timestamp not null,
	transaction_date timestamp not null,
	transaction_type char not null
);
GRANT ALL on expression_cvterm_audit to PUBLIC;

create table expression_pub_audit (
       expression_id int not null,
       pub_id int not null,
       timeentered timestamp not null,
       timelastmod timestamp not null,
	transaction_date timestamp not null,
	transaction_type char not null
);
GRANT ALL on expression_pub_audit to PUBLIC;

create table eimage_audit (
       eimage_id int not null,
       eimage_data text,
       eimage_type varchar(255) not null,
       image_uri varchar(255),
       timeentered timestamp not null,
       timelastmod timestamp not null,
	transaction_date timestamp not null,
	transaction_type char not null
);
GRANT ALL on eimage_audit to PUBLIC;

create table expression_image_audit (
       expression_id int not null,
       eimage_id int not null,
       timeentered timestamp not null,
       timelastmod timestamp not null,
	transaction_date timestamp not null,
	transaction_type char not null
);
GRANT ALL on expression_image_audit to PUBLIC;

create table featuremap_audit (
       featuremap_id int not null,
       mapname varchar(255),
       mapdesc varchar(255),
       mapunit varchar(255),
       timeentered timestamp not null,
       timelastmod timestamp not null,
	transaction_date timestamp not null,
	transaction_type char not null
);
GRANT ALL on featuremap_audit to PUBLIC;

create table featurerange_audit (
       featurerange_id int not null,
       featuremap_id int not null,
       feature_id int not null,
       leftstartf_id int not null,
       leftendf_id int,
       rightstartf_id int,
       rightendf_id int not null,
       rangestr varchar(255),
       timeentered timestamp not null,
       timelastmod timestamp not null,
	transaction_date timestamp not null,
	transaction_type char not null
);
GRANT ALL on featurerange_audit to PUBLIC;

create table featurepos_audit (
       featuremap_id int not null,
       feature_id int not null,
       map_feature_id int not null,
       mappos float not null,
       timeentered timestamp not null,
       timelastmod timestamp not null,
	transaction_date timestamp not null,
	transaction_type char not null
);
GRANT ALL on featurepos_audit to PUBLIC;

create table featuremap_pub_audit (
       featuremap_id int not null,
       pub_id int not null,
       timeentered timestamp not null,
       timelastmod timestamp not null,
	transaction_date timestamp not null,
	transaction_type char not null
);
GRANT ALL on featuremap_pub_audit to PUBLIC;

