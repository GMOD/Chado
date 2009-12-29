-- $Id: www.sql,v 1.7 2007-02-19 21:34:11 briano Exp $
-- ==========================================
-- Chado www module
--
-- =================================================================
-- Dependencies:
--
-- :import feature from sequence
-- :import cvterm from cv
-- :import pub from pub
-- :import phenotype from phenotype
-- :import organism from organism
-- :import genotype from genetic
-- :import expression from expression
-- :import project from general
--
-- WARNING: unresolvable dependency 'author'! 
-- =================================================================

-- ================================================
-- TABLE: wwwuser
-- ================================================

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

COMMENT ON TABLE wwwuser IS 'Keep track of WWW users. This may also be useful in an audit module at some point.';

-- ================================================
-- TABLE: wwwuser_project
-- ================================================

create table wwwuser_project (
	wwwuser_project_id serial not null,
	primary key (wwwuser_project_id),
	wwwuser_id int not null,
	foreign key (wwwuser_id) references wwwuser (wwwuser_id) on delete cascade INITIALLY DEFERRED,
	project_id int not null,
	foreign key (project_id) references project (project_id) on delete cascade INITIALLY DEFERRED,
	world_read smallint not null default 1,
	unique(wwwuser_id,project_id)
);
create index wwwuser_project_idx1 on wwwuser_project(wwwuser_id);
create index wwwuser_project_idx2 on wwwuser_project(project_id);

COMMENT ON TABLE wwwuser_project IS 'Link wwwuser accounts to projects';

-- ================================================
-- TABLE: wwwuser_author
-- ================================================

create table wwwuser_author (
	wwwuser_author_id serial not null,
	primary key (wwwuser_author_id),
	wwwuser_id int not null,
	foreign key (wwwuser_id) references wwwuser (wwwuser_id) on delete cascade INITIALLY DEFERRED,
	author_id int not null,
	foreign key (author_id) references author (author_id) on delete cascade INITIALLY DEFERRED,
	world_read smallint not null default 1,
	unique(wwwuser_id,author_id)
);
create index wwwuser_author_idx1 on wwwuser_author(wwwuser_id);
create index wwwuser_author_idx2 on wwwuser_author(author_id);

COMMENT ON TABLE wwwuser_author IS 'Track wwwuser interest in authors.';

-- ================================================
-- TABLE: wwwuser_cvterm
-- ================================================

create table wwwuser_cvterm (
	wwwuser_cvterm_id serial not null,
	primary key (wwwuser_cvterm_id),
	wwwuser_id int not null,
	foreign key (wwwuser_id) references wwwuser (wwwuser_id) on delete cascade INITIALLY DEFERRED,
	cvterm_id int not null,
	foreign key (cvterm_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
	world_read smallint not null default 1,
	unique(wwwuser_id,cvterm_id)
);
create index wwwuser_cvterm_idx1 on wwwuser_cvterm(wwwuser_id);
create index wwwuser_cvterm_idx2 on wwwuser_cvterm(cvterm_id);

COMMENT ON TABLE wwwuser_cvterm IS 'Track wwwuser interest in cvterms.';

-- ================================================
-- TABLE: wwwuser_expression
-- ================================================

create table wwwuser_expression (
	wwwuser_expression_id serial not null,
	primary key (wwwuser_expression_id),
	wwwuser_id int not null,
	foreign key (wwwuser_id) references wwwuser (wwwuser_id) on delete cascade INITIALLY DEFERRED,
	expression_id int not null,
	foreign key (expression_id) references expression (expression_id) on delete cascade INITIALLY DEFERRED,
	world_read smallint not null default 1,
	unique(wwwuser_id,expression_id)
);
create index wwwuser_expression_idx1 on wwwuser_expression(wwwuser_id);
create index wwwuser_expression_idx2 on wwwuser_expression(expression_id);

COMMENT ON TABLE wwwuser_expression IS 'Track wwwuser interest in expressions.';

-- ================================================
-- TABLE: wwwuser_feature
-- ================================================

create table wwwuser_feature (
	wwwuser_feature_id serial not null,
	primary key (wwwuser_feature_id),
	wwwuser_id int not null,
	foreign key (wwwuser_id) references wwwuser (wwwuser_id) on delete cascade INITIALLY DEFERRED,
	feature_id int not null,
	foreign key (feature_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,
	world_read smallint not null default 1,
	unique(wwwuser_id,feature_id)
);
create index wwwuser_feature_idx1 on wwwuser_feature(wwwuser_id);
create index wwwuser_feature_idx2 on wwwuser_feature(feature_id);

COMMENT ON TABLE wwwuser_feature IS 'Track wwwuser interest in features.';

-- ================================================
-- TABLE: wwwuser_genotype
-- ================================================

create table wwwuser_genotype (
	wwwuser_genotype_id serial not null,
	primary key (wwwuser_genotype_id),
	wwwuser_id int not null,
	foreign key (wwwuser_id) references wwwuser (wwwuser_id) on delete cascade INITIALLY DEFERRED,
	genotype_id int not null,
	foreign key (genotype_id) references genotype (genotype_id) on delete cascade INITIALLY DEFERRED,
	world_read smallint not null default 1,
	unique(wwwuser_id,genotype_id)
);
create index wwwuser_genotype_idx1 on wwwuser_genotype(wwwuser_id);
create index wwwuser_genotype_idx2 on wwwuser_genotype(genotype_id);

COMMENT ON TABLE wwwuser_genotype IS 'Track wwwuser interest in genotypes.';

-- ================================================
-- TABLE: wwwuser_interaction
-- ================================================

create table wwwuser_interaction (
	wwwuser_interaction_id serial not null,
	primary key (wwwuser_interaction_id),
	wwwuser_id int not null,
	foreign key (wwwuser_id) references wwwuser (wwwuser_id) on delete cascade INITIALLY DEFERRED,
	interaction_id int not null,
	foreign key (interaction_id) references interaction (interaction_id) on delete cascade INITIALLY DEFERRED,
	world_read smallint not null default 1,
	unique(wwwuser_id,interaction_id)
);
create index wwwuser_interaction_idx1 on wwwuser_interaction(wwwuser_id);
create index wwwuser_interaction_idx2 on wwwuser_interaction(interaction_id);

COMMENT ON TABLE wwwuser_interaction IS 'Track wwwuser interest in interactions.';

-- ================================================
-- TABLE: wwwuser_organism
-- ================================================

create table wwwuser_organism (
	wwwuser_organism_id serial not null,
	primary key (wwwuser_organism_id),
	wwwuser_id int not null,
	foreign key (wwwuser_id) references wwwuser (wwwuser_id) on delete cascade INITIALLY DEFERRED,
	organism_id int not null,
	foreign key (organism_id) references organism (organism_id) on delete cascade INITIALLY DEFERRED,
	world_read smallint not null default 1,
	unique(wwwuser_id,organism_id)
);
create index wwwuser_organism_idx1 on wwwuser_organism(wwwuser_id);
create index wwwuser_organism_idx2 on wwwuser_organism(organism_id);

COMMENT ON TABLE wwwuser_organism IS 'Track wwwuser interest in
organisms.';

-- ================================================
-- TABLE: wwwuser_phenotype
-- ================================================

create table wwwuser_phenotype (
	wwwuser_phenotype_id serial not null,
	primary key (wwwuser_phenotype_id),
	wwwuser_id int not null,
	foreign key (wwwuser_id) references wwwuser (wwwuser_id) on delete cascade INITIALLY DEFERRED,
	phenotype_id int not null,
	foreign key (phenotype_id) references phenotype (phenotype_id) on delete cascade INITIALLY DEFERRED,
	world_read smallint not null default 1,
	unique(wwwuser_id,phenotype_id)
);
create index wwwuser_phenotype_idx1 on wwwuser_phenotype(wwwuser_id);
create index wwwuser_phenotype_idx2 on wwwuser_phenotype(phenotype_id);

COMMENT ON TABLE wwwuser_phenotype IS 'Track wwwuser interest in phenotypes.';

-- ================================================
-- TABLE: wwwuser_pub
-- ================================================

create table wwwuser_pub (
	wwwuser_pub_id serial not null,
	primary key (wwwuser_pub_id),
	wwwuser_id int not null,
	foreign key (wwwuser_id) references wwwuser (wwwuser_id) on delete cascade INITIALLY DEFERRED,
	pub_id int not null,
	foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
	world_read smallint not null default 1,
	unique(wwwuser_id,pub_id)
);
create index wwwuser_pub_idx1 on wwwuser_pub(wwwuser_id);
create index wwwuser_pub_idx2 on wwwuser_pub(pub_id);

COMMENT ON TABLE wwwuser_pub IS 'Track wwwuser interest in publications.';

-- ================================================
-- TABLE: wwwuserrelationship
-- ================================================

create table wwwuserrelationship (
	wwwuserrelationship_id serial not null,
	primary key (wwwuserrelationship_id),
	objwwwuser_id int not null,
	foreign key (objwwwuser_id) references wwwuser (wwwuser_id) on delete cascade INITIALLY DEFERRED,
	subjwwwuser_id int not null,
	foreign key (subjwwwuser_id) references wwwuser (wwwuser_id) on delete cascade INITIALLY DEFERRED,
	world_read smallint not null default 1,
	unique(objwwwuser_id,subjwwwuser_id)
);
create index wwwuserrelationship_idx1 on wwwuserrelationship(subjwwwuser_id);
create index wwwuserrelationship_idx2 on wwwuserrelationship(objwwwuser_id);

COMMENT ON TABLE wwwuserrelationship IS 'Track wwwuser interest in other wwwusers.';
