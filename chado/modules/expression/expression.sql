-- This module is totally dependant on the sequence module.  Objects in the
-- genetic module cannot connect to expression data except by going via the
-- sequence module

-- We assume that we'll *always* have a controlled vocabulary for expression 
-- data.   If an experiment used a set of cv terms different from the ones
-- FlyBase uses (bodypart cv, bodypart qualifier cv, and the temporal cv
-- (which is stored in the curaton.doc under GAT6 btw)), they'd have to give
-- us the cv terms, which we could load into the cv module

-- ================================================
-- TABLE: expression
-- ================================================

create table expression (
       expression_id serial not null,
       primary key (expression_id),
       description text
);

-- ================================================
-- TABLE: feature_expression
-- ================================================

create table feature_expression (
       feature_expression_id serial not null,
       primary key (feature_expression_id),
       expression_id int not null,
       foreign key (expression_id) references expression (expression_id) on delete cascade INITIALLY DEFERRED,
       feature_id int not null,
       foreign key (feature_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,

       unique(expression_id,feature_id)       
);
create index feature_expression_idx1 on feature_expression (expression_id);
create index feature_expression_idx2 on feature_expression (feature_id);


-- ================================================
-- TABLE: expression_cvterm
-- ================================================

-- What are the possibities of combination when more than one cvterm is used
-- in a field?   
--
-- For eg (in <p> here):   <t> E | early <a> <p> anterior & dorsal
-- If the two terms used in a particular field are co-equal (both from the
-- same CV, is the relation always "&"?   May we find "or"?
--
-- Obviously another case is when a bodypart term and a bodypart qualifier
-- term are used in a specific field, eg:
--   <t> L | third instar <a> larval antennal segment sensilla | subset <p  
--
-- WRT the three-part <t><a><p> statements, are the values in the different 
-- parts *always* from different vocabularies in proforma.CV?   If not,
-- we'll need to have some kind of type qualifier telling us whether the
-- cvterm used is <t>, <a>, or <p>
-- yes we should have a type qualifier as a cv term can be from diff vocab
-- e.g. blastoderm can be body part and stage terms in dros anatomy
-- but cvterm_type needs to be a cv instead of a free text type here?

create table expression_cvterm (
       expression_cvterm_id serial not null,
       primary key (expression_cvterm_id),
       expression_id int not null,
       foreign key (expression_id) references expression (expression_id) on delete cascade INITIALLY DEFERRED,
       cvterm_id int not null,
       foreign key (cvterm_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
       rank int not null,
	   cvterm_type varchar(255),

       unique(expression_id,cvterm_id)
);
create index expression_cvterm_idx1 on expression_cvterm (expression_id);
create index expression_cvterm_idx2 on expression_cvterm (cvterm_id);


-- ================================================
-- TABLE: expression_pub
-- ================================================

create table expression_pub (
       expression_pub_id serial not null,
       primary key (expression_pub_id),
       expression_id int not null,
       foreign key (expression_id) references expression (expression_id) on delete cascade INITIALLY DEFERRED,
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,

       unique(expression_id,pub_id)       
);
create index expression_pub_idx1 on expression_pub (expression_id);
create index expression_pub_idx2 on expression_pub (pub_id);


-- ================================================
-- TABLE: eimage
-- ================================================

create table eimage (
       eimage_id serial not null,
       primary key (eimage_id),
       eimage_data text,
       eimage_type varchar(255) not null,
       image_uri varchar(255)
);
-- we expect images in eimage_data (eg jpegs) to be uuencoded
-- describes the type of data in eimage_data


-- ================================================
-- TABLE: expression_image
-- ================================================

create table expression_image (
       expression_image_id serial not null,
       primary key (expression_image_id),
       expression_id int not null,
       foreign key (expression_id) references expression (expression_id) on delete cascade INITIALLY DEFERRED,
       eimage_id int not null,
       foreign key (eimage_id) references eimage (eimage_id) on delete cascade INITIALLY DEFERRED,

       unique(expression_id,eimage_id)
);
create index expression_image_idx1 on expression_image (expression_id);
create index expression_image_idx2 on expression_image (eimage_id);
