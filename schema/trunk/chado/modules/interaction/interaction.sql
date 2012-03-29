

-- ==========================================
-- Chado interaction module
--
-- ==========================================
-- NOTES:
--
-- Designed to represent various types of interactions 
-- initially to be deployed for physical interactions (protein-protein)
-- between n number of chado features
--
-- prop and pub tables follow usual chado conventions
--
-- table:interaction serves as a coalescing table for all aspects of the interaction
--       a uniquename and link to a cvterm for the type of interaction are stored here
--
-- table:feature_interaction links features to the interaction
--       a cvterm_id for the role that the feature is playing in the interaction
--       must be specified (eg. prey, bait, evidence_for)
--       rank may be used to order interacting features in an interaction
--

-- ================================================
-- TABLE: interaction
-- ================================================
drop table interaction cascade;
create table interaction (
       	interaction_id serial NOT NULL,
       	primary key (interaction_id),
	uniquename text NOT NULL,
        type_id int NOT NULL,
        foreign key (type_id) references cvterm (cvterm_id)
	on delete cascade INITIALLY DEFERRED,
        description text,
 	is_obsolete boolean not null default false,
	constraint interaction_c1 unique(uniquename,type_id)
);
create index interaction_idx1 on interaction (uniquename);
create index interaction_idx2 on interaction (type_id);

grant all on interaction to public;
grant all on interaction_interaction_id_seq to public;

-- ================================================
-- TABLE: interactionprop
-- ================================================

drop table interactionprop cascade;
create table interactionprop (
    interactionprop_id serial not null,
    primary key (interactionprop_id),
    interaction_id int not null,
    foreign key (interaction_id) references interaction (interaction_id) on delete cascade INITIALLY DEFERRED,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    value text null,
    rank int not null default 0,
    constraint interactionprop_c1 unique (interaction_id,type_id,rank)
);
create index interactionprop_idx1 on interactionprop (interaction_id);
create index interactionprop_idx2 on interactionprop (type_id);

grant all on interactionprop to public;
grant all on interactionprop_interactionprop_id_seq to public;

-- ================================================
-- TABLE: interactionprop_pub
-- ================================================
create table interactionprop_pub (
       interactionprop_pub_id serial not null,
       primary key (interactionprop_pub_id),
       interactionprop_id int not null,
          foreign key (interactionprop_id) references interactionprop (interactionprop_id) on delete cascade INITIALLY DEFERRED,
     pub_id int not null,
     foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
     constraint interactionprop_pub_c1 unique (interactionprop_id,pub_id)
);
create index interactionprop_pub_idx1 on interactionprop_pub (interactionprop_id);
create index interactionprop_pub_idx2 on interactionprop_pub (pub_id);


grant all on interactionprop_pub to public;
grant all on interactionprop_pub_interactionprop_pub_id_seq to public;

-- ================================================
-- TABLE: interaction_pub
-- ================================================

drop table interaction_pub cascade;
create table interaction_pub (
       interaction_pub_id serial not null,
       primary key (interaction_pub_id),
       interaction_id int not null,
       foreign key (interaction_id) references interaction (interaction_id) on delete cascade INITIALLY DEFERRED,
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
       constraint interaction_pub_c1 unique(interaction_id,pub_id)       
);
create index interaction_pub_idx1 on interaction_pub (interaction_id);
create index interaction_pub_idx2 on interaction_pub (pub_id);

grant all on interaction_pub to public;
grant all on interaction_pub_interaction_pub_id_seq to public;

-- ================================================
-- TABLE: interaction_expression
-- ================================================

drop table interaction_expression cascade;

create table interaction_expression (
       interaction_expression_id serial not null,
       primary key (interaction_expression_id),
       expression_id int not null,
       foreign key (expression_id) references expression (expression_id) on delete cascade INITIALLY DEFERRED,
       interaction_id int not null,
       foreign key (interaction_id) references interaction (interaction_id) on delete cascade INITIALLY DEFERRED,
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
       unique(expression_id,interaction_id,pub_id)       
);
create index interaction_expression_idx1 on interaction_expression (expression_id);
create index interaction_expression_idx2 on interaction_expression (interaction_id);
create index interaction_expression_idx3 on interaction_expression (pub_id);

grant all on interaction_expression to public;
grant all on interaction_expression_interaction_expression_id_seq to public;

--================================================
-- TABLE: interaction_expressionprop
-- ================================================

drop table interaction_expressionprop;
create table interaction_expressionprop (
    interaction_expressionprop_id serial not null,
    primary key (interaction_expressionprop_id),
    interaction_expression_id int not null,
    foreign key (interaction_expression_id) references interaction_expression (interaction_expression_id) on delete cascade,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    value text null,
    rank int not null default 0,
    unique (interaction_expression_id,type_id,rank)
);


create index interaction_expressionprop_idx1 on interaction_expressionprop (interaction_expression_id);
create index interaction_expressionprop_idx2 on interaction_expressionprop (type_id);

grant all on interaction_expressionprop to public;
grant all on interaction_expressionprop_interaction_expressionprop_id_seq to public;

-- ================================================
-- TABLE: interaction_cvterm
-- ================================================

drop table interaction_cvterm cascade;

create table interaction_cvterm (
       interaction_cvterm_id serial not null,
       primary key (interaction_cvterm_id),
       interaction_id int not null,
       foreign key (interaction_id) references interaction (interaction_id) on delete cascade INITIALLY DEFERRED,
       cvterm_id int not null,
       foreign key (cvterm_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
       unique(interaction_id,cvterm_id)
);
create index interaction_cvterm_idx1 on interaction_cvterm (interaction_id);
create index interaction_cvterm_idx2 on interaction_cvterm (cvterm_id);
create index interaction_cvterm_idx3 on interaction_cvterm (pub_id);

grant all on interaction_cvterm to public;
grant all on interaction_cvterm_interaction_cvterm_id_seq to public;

--================================================
-- TABLE: interaction_cvtermprop
-- ================================================

drop table interaction_cvtermprop;
create table interaction_cvtermprop (
    interaction_cvtermprop_id serial not null,
    primary key (interaction_cvtermprop_id),
    interaction_cvterm_id int not null,
    foreign key (interaction_cvterm_id) references interaction_cvterm (interaction_cvterm_id) on delete cascade,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    value text null,
    rank int not null default 0,
    unique (interaction_cvterm_id,type_id,rank)
);


create index interaction_cvtermprop_idx1 on interaction_cvtermprop (interaction_cvterm_id);
create index interaction_cvtermprop_idx2 on interaction_cvtermprop (type_id);

grant all on interaction_cvtermprop to public;
grant all on interaction_cvtermprop_interaction_cvtermprop_id_seq to public;


-- ================================================
-- TABLE: library_interaction
-- ================================================

drop table library_interaction cascade;

create table library_interaction (
       library_interaction_id serial not null,
       primary key (library_interaction_id),
       interaction_id int not null,
       foreign key (interaction_id) references interaction (interaction_id) on delete cascade INITIALLY DEFERRED,
       library_id int not null,
       foreign key (library_id) references library (library_id) on delete cascade INITIALLY DEFERRED,
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
       unique(interaction_id,library_id,pub_id)       
);
create index library_interaction_idx1 on library_interaction (interaction_id);
create index library_interaction_idx2 on library_interaction (library_id);
create index library_interaction_idx3 on library_interaction (pub_id);

grant all on library_interaction to public;
grant all on library_interaction_library_interaction_id_seq to public;

-- ================================================
-- TABLE: feature_interaction
-- ================================================

drop table feature_interaction cascade;
create table feature_interaction (
       feature_interaction_id serial not null,
       primary key (feature_interaction_id),
       feature_id int not null,
       foreign key (feature_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,
       interaction_id int not null,
       foreign key (interaction_id) references interaction (interaction_id) on delete cascade INITIALLY DEFERRED,
       role_id int not null,
       foreign key (role_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
       rank int not null default 0,
       unique(feature_id,interaction_id, role_id)
);
create index feature_interaction_idx1 on feature_interaction (feature_id);
create index feature_interaction_idx2 on feature_interaction (interaction_id);
create index feature_interaction_idx3 on feature_interaction (role_id);

grant all on feature_interaction to public;
grant all on feature_interaction_feature_interaction_id_seq to public;

-- ? do we want to add rank to the unique key ? thinking stochiometry issues
-- and might we have one form modified and not another ? may be too much

-- ================================================
-- TABLE: feature_interactionprop
-- ================================================

drop table feature_interactionprop cascade;
create table feature_interactionprop (
       feature_interactionprop_id serial not null,
       primary key (feature_interactionprop_id),
       feature_interaction_id int not null,
       foreign key (feature_interaction_id) references feature_interaction (feature_interaction_id) on delete cascade INITIALLY DEFERRED,
       type_id int not null,
       foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
       value text null,
       rank int not null default 0,
       constraint feature_interactionprop_c1 unique (feature_interaction_id,type_id,rank)
);
create index feature_interactionprop_idx1 on feature_interactionprop (feature_interaction_id);
create index feature_interactionprop_idx2 on feature_interactionprop (type_id);

grant all on feature_interactionprop to public;
grant all on feature_interactionprop_feature_interactionprop_id_seq to public;

-- ================================================
-- TABLE: feature_interaction_pub
-- ================================================

drop table feature_interaction_pub cascade;
create table feature_interaction_pub (
       feature_interaction_pub_id serial not null,
       primary key (feature_interaction_pub_id),
       feature_interaction_id int not null,
       foreign key (feature_interaction_id) references feature_interaction (feature_interaction_id) on delete cascade INITIALLY DEFERRED,
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
       constraint feature_interaction_pub_c1 unique(feature_interaction_id,pub_id)       
);
create index feature_interaction_pub_idx1 on feature_interaction_pub (feature_interaction_id);
create index feature_interaction_pub_idx2 on feature_interaction_pub (pub_id);

grant all on feature_interaction_pub to public;
grant all on feature_interaction_pub_feature_interaction_pub_id_seq to public;

-- ================================================
-- TABLE: interaction_cell_line
-- ================================================

drop table interaction_cell_line cascade;

create table interaction_cell_line (
       interaction_cell_line_id serial not null,
       primary key (interaction_cell_line_id),
       cell_line_id int not null,
       foreign key (cell_line_id) references cell_line (cell_line_id) on delete cascade INITIALLY DEFERRED,
       interaction_id int not null,
       foreign key (interaction_id) references interaction (interaction_id) on delete cascade INITIALLY DEFERRED,
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
       unique(cell_line_id,interaction_id,pub_id)       
);
create index interaction_cell_line_idx1 on interaction_cell_line (cell_line_id);
create index interaction_cell_line_idx2 on interaction_cell_line (interaction_id);
create index interaction_cell_line_idx3 on interaction_cell_line (pub_id);

grant all on interaction_cell_line to public;
grant all on interaction_cell_line_interaction_cell_line_id_seq to public;
