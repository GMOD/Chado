-- This module depends on the sequence, pub, and cv modules 
-- 18-JAN-03 (DE): This module is unfinished and due for schema review (Bill 
-- Gelbart will be leading the charge)   

-- ================================================
-- TABLE: genotype
-- ================================================

create table genotype (
       genotype_id serial not null,
       primary key (genotype_id),
       description varchar(255)
);


-- ================================================
-- TABLE: feature_genotype
-- ================================================

create table feature_genotype (
       feature_genotype_id serial not null,
       primary key (feature_genotype_id),
       feature_id int not null,
       foreign key (feature_id) references feature (feature_id),
       genotype_id int not null,
       foreign key (genotype_id) references genotype (genotype_id),

       unique(feature_id,genotype_id)
);
create index feature_genotype_idx1 on feature_genotype (feature_id);
create index feature_genotype_idx2 on feature_genotype (genotype_id);


-- ================================================
-- TABLE: phenotype
-- ================================================

create table phenotype (
       phenotype_id serial not null,
       primary key (phenotype_id),
       description text,
-- type of phenotypic statement  [Chris, we need this or something like it
-- for FB where we have three types of statement in *k: "Phenotypic class:",
-- "Phenotype manifest in:", and free-text]
       statement_type int not null,
       foreign key (statement_type) references cvterm (cvterm_id),
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id),
-- Do we want to call this simply genotype_id to allow natural joins?
       background_genotype_id int,
       foreign key (background_genotype_id) references genotype (genotype_id)
);
create index phenotype_idx1 on phenotype (statement_type);
create index phenotype_idx2 on phenotype (pub_id);
create index phenotype_idx3 on phenotype (background_genotype_id);


-- ================================================
-- TABLE: feature_phenotype
-- ================================================

create table feature_phenotype (
       feature_phenotype_id serial not null,
       primary key (feature_phenotype_id),
       feature_id int not null,
       foreign key (feature_id) references feature (feature_id),
       phenotype_id int not null,
       foreign key (phenotype_id) references phenotype (phenotype_id),

       unique(feature_id,phenotype_id)       
);
create index feature_phenotype_idx1 on feature_phenotype (feature_id);
create index feature_phenotype_idx2 on feature_phenotype (phenotype_id);


-- ================================================
-- TABLE: phenoype_cvterm
-- ================================================

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
create index phenotype_cvterm_idx1 on phenotype_cvterm (phenotype_id);
create index phenotype_cvterm_idx2 on phenotype_cvterm (cvterm_id);


-- ================================================
-- TABLE: interaction
-- ================================================

create table interaction (
       interaction_id serial not null,
       primary key (interaction_id),
       description text,
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id),
-- Do we want to call this simply genotype_id to allow natural joins?
       background_genotype_id int,
       foreign key (background_genotype_id) references genotype (genotype_id),
       phenotype_id int,
       foreign key (phenotype_id) references phenotype (phenotype_id)
);
create index interaction_idx1 on interaction (pub_id);
create index interaction_idx2 on interaction (background_genotype_id);
create index interaction_idx3 on interaction (phenotype_id);


-- ================================================
-- TABLE: interaction_subj
-- ================================================

create table interaction_subj (
       interaction_subj_id serial not null,
       primary key (interaction_subj_id),
       feature_id int not null,
       foreign key (feature_id) references feature (feature_id),
       interaction_id int not null,
       foreign key (interaction_id) references interaction (interaction_id),

       unique(feature_id,interaction_id)
);
create index interaction_subj_idx1 on interaction_subj (feature_id);
create index interaction_subj_idx2 on interaction_subj (interaction_id);


-- ================================================
-- TABLE: interaction_obj
-- ================================================

create table interaction_obj (
       interaction_obj_id serial not null,
       primary key (interaction_obj_id),
       feature_id int not null,
       foreign key (feature_id) references feature (feature_id),
       interaction_id int not null,
       foreign key (interaction_id) references interaction (interaction_id),

       unique(feature_id,interaction_id)
);
create index interaction_obj_idx1 on interaction_obj (feature_id);
create index interaction_obj_idx2 on interaction_obj (interaction_id);
