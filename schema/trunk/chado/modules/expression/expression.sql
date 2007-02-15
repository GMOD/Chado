-- This module is for how curated expression data is stored in chado. 
-- This module is totally dependant on the sequence module.  Objects in the
-- genetic module cannot connect to expression data except by going via the
-- sequence module
-- We assume that we'll *always* have a controlled vocabulary for expression 
-- data.   

-- An example of a simple case of the sort of data that FlyBase curates. 
-- The dpp transcript is expressed in embryonic stage 13-15 in the cephalic
-- segment as reported in a paper by Blackman et al. in 1991.
-- This would be implemented in the expression module by linking the dpp
-- transcript feature to expression via feature_expression (we would add a
-- pub_id column to feature_expression to link to the publication in the
-- pub table).
-- We would then link the following cvterms to the expression using
-- expression_cvterm
-- 'embryonic stage 13' where the cvterm_type would be stage and the rank=0
-- 'embryonic stage 14' where the cvterm_type would be stage and the rank=1
-- 'embryonic stage 15' where the cvterm_type would be stage and the rank=1
-- 'cephalic segment' where the cvterm_type would be anatomy and the rank=0
-- 'in situ hybridization' where the cvterm_type would be assat and the
-- rank=0
-- Note that we would change the cvterm_type column to cvterm_type_id and
-- use a cvterm_id for a particular expression slot (i.e. stage, anatomy,
-- assay, 'subcellular location' and that cvterms from different obo
-- ontologies can share the same cvterm_type 

-- =================================================================
-- Dependencies:
--
-- :import feature from sequence
-- :import cvterm from cv
-- :import pub from pub
-- =================================================================


-- ================================================
-- TABLE: expression
-- ================================================

-- expression essentially a bridge table

create table expression (
       expression_id serial not null,
       primary key (expression_id),
       uniquename text not null,
       md5checksum character(32),
       description text,
       expression_c1 unique(uniquename)       
);


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
-- but cvterm_type_id needs to be a cv instead of a free text type

create table expression_cvterm (
       expression_cvterm_id serial not null,
       primary key (expression_cvterm_id),
       expression_id int not null,
       foreign key (expression_id) references expression (expression_id) on delete cascade INITIALLY DEFERRED,
       cvterm_id int not null,
       foreign key (cvterm_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
       rank int not null default 0,
       cvterm_type_id int not null,
       foreign key (cvterm_type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
       unique(expression_id,cvterm_id,cvterm_type_id)
);
create index expression_cvterm_idx1 on expression_cvterm (expression_id);
create index expression_cvterm_idx2 on expression_cvterm (cvterm_id);
create index expression_cvterm_idx3 on expression_cvterm (cvterm_type_id);

--================================================
-- TABLE: expression_cvtermprop
-- ================================================

create table expression_cvtermprop (
    expression_cvtermprop_id serial not null,
    primary key (expression_cvtermprop_id),
    expression_cvterm_id int not null,
    foreign key (expression_cvterm_id) references expression_cvterm (expression_cvterm_id) on delete cascade INITIALLY DEFERRED,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    value text null,
    rank int not null default 0,
    unique (expression_cvterm_id,type_id,rank)
);


create index expression_cvtermprop_idx1 on expression_cvtermprop (expression_cvterm_id);
create index expression_cvtermprop_idx2 on expression_cvtermprop (type_id);

COMMENT ON TABLE expression_cvtermprop IS 'Extensible properties for
expression to cvterm associations. Examples: qualifiers';

COMMENT ON COLUMN expression_cvtermprop.type_id IS 'The name of the
property/slot is a cvterm. The meaning of the property is defined in
that cvterm. cvterms may come from the FlyBase miscellaneous cv';

COMMENT ON COLUMN expression_cvtermprop.value IS 'The value of the
property, represented as text. Numeric values are converted to their
text representation. This is less efficient than using native database
types, but is easier to query.';

COMMENT ON COLUMN expression_cvtermprop.rank IS 'Property-Value
ordering. Any expression_cvterm can have multiple values for any particular
property type - these are ordered in a list using rank, counting from
zero. For properties that are single-valued rather than multi-valued,
the default 0 value should be used';

-- ================================================
-- TABLE: expressionprop
-- ================================================

create table expressionprop (
    expressionprop_id serial not null,
    primary key (expressionprop_id),
    expression_id int not null,
    foreign key (expression_id) references expression (expression_id) on delete cascade INITIALLY DEFERRED,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
    value text null,
    rank int not null default 0,
    unique (expression_id,type_id,rank)
);
create index expressionprop_idx1 on expressionprop (expression_id);
create index expressionprop_idx2 on expressionprop (type_id);


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
-- TABLE: feature_expression
-- ================================================

create table feature_expression (
       feature_expression_id serial not null,
       primary key (feature_expression_id),
       expression_id int not null,
       foreign key (expression_id) references expression (expression_id) on delete cascade INITIALLY DEFERRED,
       feature_id int not null,
       foreign key (feature_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
       unique(expression_id,feature_id,pub_id)       
);
create index feature_expression_idx1 on feature_expression (expression_id);
create index feature_expression_idx2 on feature_expression (feature_id);
create index feature_expression_idx2 on feature_expression (pub_id);


-- ================================================
-- TABLE: feature_expressionprop
-- ================================================
-- modeled on feature_cvtermprop

create table feature_expressionprop (
       feature_expressionprop_id serial not null,
       primary key (feature_expressionprop_id),
       feature_expression_id int not null,
       foreign key (feature_expression_id) references feature_expression (feature_expression_id) on delete cascade INITIALLY DEFERRED,
       type_id int not null,
       foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
       value text null,
       rank int not null default 0,
       unique (feature_expression_id,type_id,rank)
);


create index feature_expressionprop_idx1 on feature_expressionprop (feature_expression_id);
create index expression_cvtermprop_idx2 on feature_expressionprop (type_id);

COMMENT ON TABLE feature_expressionprop IS 'Extensible properties for
	feature_expression text. Examples: comments';


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
