-- ================================================
-- TABLE: wwwuser
-- ================================================
-- keep track of www users.  this may also be useful
-- in an audit module at some point (?).

create table wwwuser (
	wwwuser_id serial not null,
	primary key (wwwuser_id),
	username varchar(32) not null,
	unique(username),
	password varchar(32) not null,
	email varchar(128) not null,
	profile text null
);
create index wwwuser_idx1 on wwwuser (username);

-- ================================================
-- TABLE: wwwuser
-- ================================================
-- link wwwuser accounts to projects

create table wwwuser_project (
	wwwuser_project_id serial not null,
	primary key (wwwuser_project_id),
	wwwuser_id int not null,
	foreign key (wwwuser_id) references wwwuser (wwwuser_id),
	project_id int not null,
	foreign key (project_id) references project (project_id),
	world_read smallint not null default 1,
	unique(wwwuser_id,project_id)
);
create index wwwuser_project_idx1 on wwwuser_project(wwwuser_id);
create index wwwuser_project_idx2 on wwwuser_project(project_id);

-- ================================================
-- TABLE: wwwuser_author
-- ================================================
-- track wwwuser interest in authors

create table wwwuser_author (
	wwwuser_author_id serial not null,
	primary key (wwwuser_author_id),
	wwwuser_id int not null,
	foreign key (wwwuser_id) references wwwuser (wwwuser_id),
	author_id int not null,
	foreign key (author_id) references author (author_id),
	world_read smallint not null default 1,
	unique(wwwuser_id,author_id)
);
create index wwwuser_author_idx1 on wwwuser_author(wwwuser_id);
create index wwwuser_author_idx2 on wwwuser_author(author_id);

-- ================================================
-- TABLE: wwwuser_cvterm
-- ================================================
-- track wwwuser interest in cvterms

create table wwwuser_cvterm (
	wwwuser_cvterm_id serial not null,
	primary key (wwwuser_cvterm_id),
	wwwuser_id int not null,
	foreign key (wwwuser_id) references wwwuser (wwwuser_id),
	cvterm_id int not null,
	foreign key (cvterm_id) references cvterm (cvterm_id),
	world_read smallint not null default 1,
	unique(wwwuser_id,cvterm_id)
);
create index wwwuser_cvterm_idx1 on wwwuser_cvterm(wwwuser_id);
create index wwwuser_cvterm_idx2 on wwwuser_cvterm(cvterm_id);

-- ================================================
-- TABLE: wwwuser_expression
-- ================================================
-- track wwwuser interest in expressions

create table wwwuser_expression (
	wwwuser_expression_id serial not null,
	primary key (wwwuser_expression_id),
	wwwuser_id int not null,
	foreign key (wwwuser_id) references wwwuser (wwwuser_id),
	expression_id int not null,
	foreign key (expression_id) references expression (expression_id),
	world_read smallint not null default 1,
	unique(wwwuser_id,expression_id)
);
create index wwwuser_expression_idx1 on wwwuser_expression(wwwuser_id);
create index wwwuser_expression_idx2 on wwwuser_expression(expression_id);

-- ================================================
-- TABLE: wwwuser_feature
-- ================================================
-- track wwwuser interest in features

create table wwwuser_feature (
	wwwuser_feature_id serial not null,
	primary key (wwwuser_feature_id),
	wwwuser_id int not null,
	foreign key (wwwuser_id) references wwwuser (wwwuser_id),
	feature_id int not null,
	foreign key (feature_id) references feature (feature_id),
	world_read smallint not null default 1,
	unique(wwwuser_id,feature_id)
);
create index wwwuser_feature_idx1 on wwwuser_feature(wwwuser_id);
create index wwwuser_feature_idx2 on wwwuser_feature(feature_id);

-- ================================================
-- TABLE: wwwuser_genotype
-- ================================================
-- track wwwuser interest in genotypes

create table wwwuser_genotype (
	wwwuser_genotype_id serial not null,
	primary key (wwwuser_genotype_id),
	wwwuser_id int not null,
	foreign key (wwwuser_id) references wwwuser (wwwuser_id),
	genotype_id int not null,
	foreign key (genotype_id) references genotype (genotype_id),
	world_read smallint not null default 1,
	unique(wwwuser_id,genotype_id)
);
create index wwwuser_genotype_idx1 on wwwuser_genotype(wwwuser_id);
create index wwwuser_genotype_idx2 on wwwuser_genotype(genotype_id);

-- ================================================
-- TABLE: wwwuser_interaction
-- ================================================
-- track wwwuser interest in interactions

create table wwwuser_interaction (
	wwwuser_interaction_id serial not null,
	primary key (wwwuser_interaction_id),
	wwwuser_id int not null,
	foreign key (wwwuser_id) references wwwuser (wwwuser_id),
	interaction_id int not null,
	foreign key (interaction_id) references interaction (interaction_id),
	world_read smallint not null default 1,
	unique(wwwuser_id,interaction_id)
);
create index wwwuser_interaction_idx1 on wwwuser_interaction(wwwuser_id);
create index wwwuser_interaction_idx2 on wwwuser_interaction(interaction_id);

-- ================================================
-- TABLE: wwwuser_organism
-- ================================================
-- track wwwuser interest in organisms

create table wwwuser_organism (
	wwwuser_organism_id serial not null,
	primary key (wwwuser_organism_id),
	wwwuser_id int not null,
	foreign key (wwwuser_id) references wwwuser (wwwuser_id),
	organism_id int not null,
	foreign key (organism_id) references organism (organism_id),
	world_read smallint not null default 1,
	unique(wwwuser_id,organism_id)
);
create index wwwuser_organism_idx1 on wwwuser_organism(wwwuser_id);
create index wwwuser_organism_idx2 on wwwuser_organism(organism_id);

-- ================================================
-- TABLE: wwwuser_phenotype
-- ================================================
-- track wwwuser interest in phenotypes

create table wwwuser_phenotype (
	wwwuser_phenotype_id serial not null,
	primary key (wwwuser_phenotype_id),
	wwwuser_id int not null,
	foreign key (wwwuser_id) references wwwuser (wwwuser_id),
	phenotype_id int not null,
	foreign key (phenotype_id) references phenotype (phenotype_id),
	world_read smallint not null default 1,
	unique(wwwuser_id,phenotype_id)
);
create index wwwuser_phenotype_idx1 on wwwuser_phenotype(wwwuser_id);
create index wwwuser_phenotype_idx2 on wwwuser_phenotype(phenotype_id);

-- ================================================
-- TABLE: wwwuser_pub
-- ================================================
-- track wwwuser interest in publications

create table wwwuser_pub (
	wwwuser_pub_id serial not null,
	primary key (wwwuser_pub_id),
	wwwuser_id int not null,
	foreign key (wwwuser_id) references wwwuser (wwwuser_id),
	pub_id int not null,
	foreign key (pub_id) references pub (pub_id),
	world_read smallint not null default 1,
	unique(wwwuser_id,pub_id)
);
create index wwwuser_pub_idx1 on wwwuser_pub(wwwuser_id);
create index wwwuser_pub_idx2 on wwwuser_pub(pub_id);

-- ================================================
-- TABLE: wwwuserrelationship
-- ================================================
-- track wwwuser interest in other wwwusers

create table wwwuserrelationship (
	wwwuserrelationship_id serial not null,
	primary key (wwwuserrelationship_id),
	objwwwuser_id int not null,
	foreign key (objwwwuser_id) references wwwuser (wwwuser_id),
	subjwwwuser_id int not null,
	foreign key (subjwwwuser_id) references wwwuser (wwwuser_id),
	world_read smallint not null default 1,
	unique(objwwwuser_id,subjwwwuser_id)
);
create index wwwuserrelationship_idx1 on wwwuserrelationship(subjwwwuser_id);
create index wwwuserrelationship_idx2 on wwwuserrelationship(objwwwuser_id);
