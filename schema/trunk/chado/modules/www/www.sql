-- ================================================
-- TABLE: user
-- ================================================
-- keep track of www users.  this may also be useful
-- in an audit module at some point (?).

create table user (
	user_id serial not null,
	primary key (user_id),
	username varchar(32) not null,
	unique(username),
	password varchar(32) not null,
	email varchar(128) not null,
	profile text null
);
create index user_idx1 on user (username);

-- ================================================
-- TABLE: user
-- ================================================
-- link user accounts to projects

create table user_project (
	user_project_id serial not null,
	primary key (user_project_id),
	user_id int not null,
	foreign key (user_id) references user (user_id),
	project_id int not null,
	foreign key (project_id) references project (project_id),
	world_read smallint not null default 1,
	unique(user_id,project_id)
);
create index user_project_idx1 on user_project(user_id);
create index user_project_idx2 on user_project(project_id);

-- ================================================
-- TABLE: user_author
-- ================================================
-- track user interest in authors

create table user_author (
	user_author_id serial not null,
	primary key (user_author_id),
	user_id int not null,
	foreign key (user_id) references user (user_id),
	author_id int not null,
	foreign key (author_id) references author (author_id),
	world_read smallint not null default 1,
	unique(user_id,author_id)
);
create index user_author_idx1 on user_author(user_id);
create index user_author_idx2 on user_author(author_id);

-- ================================================
-- TABLE: user_cvterm
-- ================================================
-- track user interest in cvterms

create table user_cvterm (
	user_cvterm_id serial not null,
	primary key (user_cvterm_id),
	user_id int not null,
	foreign key (user_id) references user (user_id),
	cvterm_id int not null,
	foreign key (cvterm_id) references cvterm (cvterm_id),
	world_read smallint not null default 1,
	unique(user_id,cvterm_id)
);
create index user_cvterm_idx1 on user_cvterm(user_id);
create index user_cvterm_idx2 on user_cvterm(cvterm_id);

-- ================================================
-- TABLE: user_expression
-- ================================================
-- track user interest in expressions

create table user_expression (
	user_expression_id serial not null,
	primary key (user_expression_id),
	user_id int not null,
	foreign key (user_id) references user (user_id),
	expression_id int not null,
	foreign key (expression_id) references expression (expression_id),
	world_read smallint not null default 1,
	unique(user_id,expression_id)
);
create index user_expression_idx1 on user_expression(user_id);
create index user_expression_idx2 on user_expression(expression_id);

-- ================================================
-- TABLE: user_feature
-- ================================================
-- track user interest in features

create table user_feature (
	user_feature_id serial not null,
	primary key (user_feature_id),
	user_id int not null,
	foreign key (user_id) references user (user_id),
	feature_id int not null,
	foreign key (feature_id) references feature (feature_id),
	world_read smallint not null default 1,
	unique(user_id,feature_id)
);
create index user_feature_idx1 on user_feature(user_id);
create index user_feature_idx2 on user_feature(feature_id);

-- ================================================
-- TABLE: user_gene
-- ================================================
-- track user interest in genes

create table user_gene (
	user_gene_id serial not null,
	primary key (user_gene_id),
	user_id int not null,
	foreign key (user_id) references user (user_id),
	gene_id int not null,
	foreign key (gene_id) references gene (gene_id),
	world_read smallint not null default 1,
	unique(user_id,gene_id)
);
create index user_gene_idx1 on user_gene(user_id);
create index user_gene_idx2 on user_gene(gene_id);

-- ================================================
-- TABLE: user_genotype
-- ================================================
-- track user interest in genotypes

create table user_genotype (
	user_genotype_id serial not null,
	primary key (user_genotype_id),
	user_id int not null,
	foreign key (user_id) references user (user_id),
	genotype_id int not null,
	foreign key (genotype_id) references genotype (genotype_id),
	world_read smallint not null default 1,
	unique(user_id,genotype_id)
);
create index user_genotype_idx1 on user_genotype(user_id);
create index user_genotype_idx2 on user_genotype(genotype_id);

-- ================================================
-- TABLE: user_interaction
-- ================================================
-- track user interest in interactions

create table user_interaction (
	user_interaction_id serial not null,
	primary key (user_interaction_id),
	user_id int not null,
	foreign key (user_id) references user (user_id),
	interaction_id int not null,
	foreign key (interaction_id) references interaction (interaction_id),
	world_read smallint not null default 1,
	unique(user_id,interaction_id)
);
create index user_interaction_idx1 on user_interaction(user_id);
create index user_interaction_idx2 on user_interaction(interaction_id);

-- ================================================
-- TABLE: user_organism
-- ================================================
-- track user interest in organisms

create table user_organism (
	user_organism_id serial not null,
	primary key (user_organism_id),
	user_id int not null,
	foreign key (user_id) references user (user_id),
	organism_id int not null,
	foreign key (organism_id) references organism (organism_id),
	world_read smallint not null default 1,
	unique(user_id,organism_id)
);
create index user_organism_idx1 on user_organism(user_id);
create index user_organism_idx2 on user_organism(organism_id);

-- ================================================
-- TABLE: user_phenotype
-- ================================================
-- track user interest in phenotypes

create table user_phenotype (
	user_phenotype_id serial not null,
	primary key (user_phenotype_id),
	user_id int not null,
	foreign key (user_id) references user (user_id),
	phenotype_id int not null,
	foreign key (phenotype_id) references phenotype (phenotype_id),
	world_read smallint not null default 1,
	unique(user_id,phenotype_id)
);
create index user_phenotype_idx1 on user_phenotype(user_id);
create index user_phenotype_idx2 on user_phenotype(phenotype_id);

-- ================================================
-- TABLE: user_pub
-- ================================================
-- track user interest in publications

create table user_pub (
	user_pub_id serial not null,
	primary key (user_pub_id),
	user_id int not null,
	foreign key (user_id) references user (user_id),
	pub_id int not null,
	foreign key (pub_id) references pub (pub_id),
	world_read smallint not null default 1,
	unique(user_id,pub_id)
);
create index user_pub_idx1 on user_pub(user_id);
create index user_pub_idx2 on user_pub(pub_id);

-- ================================================
-- TABLE: userrelationship
-- ================================================
-- track user interest in other users

create table userrelationship (
	userrelationship_id serial not null,
	primary key (userrelationship_id),
	objuser_id int not null,
	foreign key (objuser_id) references user (user_id),
	subjuser_id int not null,
	foreign key (subjuser_id) references user (user_id),
	world_read smallint not null default 1,
	unique(objuser_id,subjuser_id)
);
create index userrelationship_idx1 on userrelationship(subjuser_id);
create index userrelationship_idx2 on userrelationship(objuser_id);

