## This module depends on the sequence, pub, and cv modules 

## ================================================
## TABLE: genotype
## ================================================

create table genotype (
       genotype_id serial not null,
       primary key (genotype_id),
       description varchar(255),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp
);


## ================================================
## TABLE: feature_genotype
## ================================================

create table feature_genotype (
       feature_id int,
       foreign key (feature_id) references feature (feature_id),
       genotype_id int,
       foreign key (genotype_id) references genotype (genotype_id),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp
);

## ================================================
## TABLE: phenotype
## ================================================

create table phenotype (
       phenotype_id serial not null,
       primary key (phenotype_id),
       description text,
## type of phenotypic statement  [Chris, we need this or something like it
## for FB where we have three types of statement in *k: "Phenotypic class:",
## "Phenotype manifest in:", and free-text]
       statement_type int not null,
       foreign key (statement_type) references cvterm (cvterm_id),
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id),
## Do we want to call this simply genotype_id to allow natural joins?
       background_genotype_id int,
       foreign key (background_genotype_id) references genotype (genotype_id),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp
);
## ================================================
## TABLE: feature_phenotype
## ================================================

create table feature_phenotype (
       feature_id int not null,
       foreign key (feature_id) references feature (feature_id),
       phenotype_id int not null,
       foreign key (phenotype_id) references phenotype (phenotype_id),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp
);

## ================================================
## TABLE: phenoype_cvterm
## ================================================

create table phenotype_cvterm (
       phenotype_id int not null,
       foreign key (phenotype_id) references phenotype (phenotype_id),
       cvterm_id int not null,
       foreign key (cvterm_id) references cvterm (cvterm_id),
       prank int not null,
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp
);


## ================================================
## TABLE: interaction
## ================================================

create table interaction (
       interaction_id serial not null,
       primary key (interaction_id),
       description text,
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id),
## Do we want to call this simply genotype_id to allow natural joins?
       background_genotype_id int,
       foreign key (background_genotype_id) references genotype (genotype_id),
       phenotype_id int,
       foreign key (phenotype_id) references phenotype (phenotype_id),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp
);


## ================================================
## TABLE: interaction_subj
## ================================================

create table interaction_subj (
       feature_id int not null,
       foreign key (feature_id) references feature (feature_id),
       interaction_id int not null,
       foreign key (interaction_id) references interaction (interaction_id),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp
);


## ================================================
## TABLE: interaction_obj
## ================================================

create table interaction_obj (
       feature_id int not null,
       foreign key (feature_id) references feature (feature_id),
       interaction_id int not null,
       foreign key (interaction_id) references interaction (interaction_id),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp
);

