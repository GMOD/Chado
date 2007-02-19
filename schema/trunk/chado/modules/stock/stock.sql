-- $Id: stock.sql,v 1.3 2007-02-19 23:50:36 briano Exp $
-- ==========================================
-- Chado stock module
--
-- DEPENDENCIES
-- ============
-- :import cvterm from cv
-- :import pub from pub
-- :import dbxref from general
-- :import organism from organism
-- :import genotype from genetic

-- ================================================
-- TABLE: stock
-- ================================================

create table stock (
       stock_id serial not null,
       primary key (stock_id),
       dbxref_id int,
       foreign key (dbxref_id) references dbxref (dbxref_id) on delete set null INITIALLY DEFERRED,
       organism_id int not null,
       foreign key (organism_id) references organism (organism_id) on delete cascade INITIALLY DEFERRED,
       name varchar(255),
       uniquename text not null,
       description text,
       type_id int not null,
       foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
       is_obsolete boolean not null default 'false',
       constraint stock_c1 unique (organism_id,uniquename,type_id)
);
create index stock_name_ind1 on stock (name);
create index stock_idx1 on stock (dbxref_id);
create index stock_idx2 on stock (organism_id);
create index stock_idx3 on stock (type_id);
create index stock_idx4 on stock (uniquename);

COMMENT ON TABLE STOCK IS 'Any stock can be globally identified by the
combination of organism, uniquename and stock type. A stock is the physical entities, either living or preserved, held by collections. Stocks belong to a collection; they have IDs, type, organism, description and may have a genotype.';
COMMENT ON COLUMN STOCK.DBXREF_ID IS 'The dbxref_id is an optional primary stable identifier for this stock. Secondary indentifiers and external dbxrefs go in table: stock_dbxref.';
COMMENT ON COLUMN STOCK.ORGANISM_ID IS 'The organism_id is the organism to which the stock belongs. This column is mandatory.';
COMMENT ON COLUMN STOCK.TYPE_ID IS 'The type_id foreign key links to a controlled vocabulary of stock types. The would include living stock, genomic DNA, preserved specimen. Secondary cvterms for stocks would go in stock_cvterm.';
COMMENT ON COLUMN STOCK.DESCRIPTION IS 'The description is the genetic description provided in the stock list.';
COMMENT ON COLUMN STOCK.NAME IS 'The name is a human-readable local name for a stock.';


-- ================================================
-- TABLE: stock_pub
-- ================================================

create table stock_pub (
       stock_pub_id serial not null,
       primary key (stock_pub_id),
       stock_id int not null,
       foreign key (stock_id) references stock (stock_id)  on delete cascade INITIALLY DEFERRED,
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
       constraint stock_pub_c1 unique (stock_id,pub_id)
);
create index stock_pub_idx1 on stock_pub (stock_id);
create index stock_pub_idx2 on stock_pub (pub_id);

COMMENT ON TABLE STOCK_PUB IS 'Provenance. Linking table between stocks and, for example, a stocklist computer file.';


-- ================================================
-- TABLE: stockprop
-- ================================================

create table stockprop (
       stockprop_id serial not null,
       primary key (stockprop_id),
       stock_id int not null,
       foreign key (stock_id) references stock (stock_id) on delete cascade INITIALLY DEFERRED,
       type_id int not null,
       foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
       value text null,
       rank int not null default 0,
       constraint stockprop_c1 unique (stock_id,type_id,rank)
);
create index stockprop_idx1 on stockprop (stock_id);
create index stockprop_idx2 on stockprop (type_id);

COMMENT ON TABLE STOCKPROP IS 'A stock can have any number of slot-value property tags attached to it. This is an alternative to hardcoding a list of columns in the relational schema, and is completely extensible.';
COMMENT ON COLUMN STOCKPROP.STOCKPROP_C1 IS 'Unique index stockprop_c1 for any one stock, multivalued property-value pairs must be differentiated by rank.';


-- ================================================
-- TABLE: stockprop_pub
-- ================================================

create table stockprop_pub (
     stockprop_pub_id serial not null,
     primary key (stockprop_pub_id),
     stockprop_id int not null,
     foreign key (stockprop_id) references stockprop (stockprop_id) on delete cascade INITIALLY DEFERRED,
     pub_id int not null,
     foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
     constraint stockprop_pub_c1 unique (stockprop_id,pub_id)
);
create index stockprop_pub_idx1 on stockprop_pub (stockprop_id);
create index stockprop_pub_idx2 on stockprop_pub (pub_id); 

COMMENT ON TABLE STOCKPROP_PUB IS 'Provenance. Any stockprop assignment can optionally be supported by a publication.';


-- ================================================
-- TABLE: stock_relationship
-- ================================================

create table stock_relationship (
       stock_relationship_id serial not null,
       primary key (stock_relationship_id),
       subject_id int not null,
       foreign key (subject_id) references stock (stock_id) on delete cascade INITIALLY DEFERRED,
       object_id int not null,
       foreign key (object_id) references stock (stock_id) on delete cascade INITIALLY DEFERRED,
       type_id int not null,
       foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
       value text null,
       rank int not null default 0,
       constraint stock_relationship_c1 unique (subject_id,object_id,type_id,rank)
);
create index stock_relationship_idx1 on stock_relationship (subject_id);
create index stock_relationship_idx2 on stock_relationship (object_id);
create index stock_relationship_idx3 on stock_relationship (type_id);

COMMENT ON STOCK_RELATIONSHIP.SUBJECT_ID IS 'stock_relationship.subject_id is the subject of the subj-predicate-obj sentence. This is typically the substock.';
COMMENT ON STOCK_RELATIONSHIP.OBJECT_ID IS 'stock_relationship.object_id is the object of the subj-predicate-obj sentence. This is typically the container stock.';
COMMENT ON STOCK_RELATIONSHIP.TYPE_ID IS 'stock_relationship.type_id is relationship type between subject and object. This is a cvterm, typically from the OBO relationship ontology, although other relationship types are allowed.';
COMMENT ON STOCK_RELATIONSHIP.RANK IS 'stock_relationship.rank is the ordering of subject stocks with respect to the object stock may be important where rank is used to order these; starts from zero.';
COMMENT ON STOCK_RELATIONSHIP.VALUE IS 'stock_relationship.value is
for additional notes/comments.';


-- ================================================
-- TABLE: stock_relationship_pub
-- ================================================

create table stock_relationship_pub (
      stock_relationship_pub_id serial not null,
      primary key (stock_relationship_pub_id),
      stock_relationship_id int not null,
      foreign key (stock_relationship_id) references stock_relationship (stock_relationship_id) on delete cascade INITIALLY DEFERRED,
      pub_id int not null,
      foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
      constraint stock_relationship_pub_c1 unique (stock_relationship_id,pub_id)
);
create index stock_relationship_pub_idx1 on stock_relationship_pub (stock_relationship_id);
create index stock_relationship_pub_idx2 on stock_relationship_pub (pub_id);

COMMENT ON TABLE STOCK_RELATIONSHIP_PUB IS 'Provenance. Attach optional evidence to a stock_relationship in the form of a publication.';


-- ================================================
-- TABLE: stock_dbxref
-- ================================================

create table stock_dbxref (
     stock_dbxref_id serial not null,
     primary key (stock_dbxref_id),
     stock_id int not null,
     foreign key (stock_id) references stock (stock_id) on delete cascade INITIALLY DEFERRED,
     dbxref_id int not null,
     foreign key (dbxref_id) references dbxref (dbxref_id) on delete cascade INITIALLY DEFERRED,
     is_current boolean not null default 'true',
     constraint stock_dbxref_c1 unique (stock_id,dbxref_id)
);
create index stock_dbxref_idx1 on stock_dbxref (stock_id);
create index stock_dbxref_idx2 on stock_dbxref (dbxref_id);

COMMENT ON TABLE STOCK_DBXREF IS 'stock_dbxref links a stock to dbxrefs. This is for secondary identifiers; primary identifiers should use stock.dbxref_id.';
COMMENT ON COLUMN STOCK_DBXREF.IS_CURRENT IS 'The is_current boolean indicates whether the linked dbxref is the current -official- dbxref for the linked stock.';


-- ================================================
-- TABLE: stock_cvterm
-- ================================================

create table stock_cvterm (
     stock_cvterm_id serial not null,
     primary key (stock_cvterm_id),
     stock_id int not null,
     foreign key (stock_id) references stock (stock_id) on delete cascade INITIALLY DEFERRED,
     cvterm_id int not null,
     foreign key (cvterm_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
     pub_id int not null,
     foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
     constraint stock_cvterm_c1 unique (stock_id,cvterm_id,pub_id)
);
create index stock_cvterm_idx1 on stock_cvterm (stock_id);
create index stock_cvterm_idx2 on stock_cvterm (cvterm_id);
create index stock_cvterm_idx3 on stock_cvterm (pub_id);

COMMENT ON TABLE STOCK_CVTERM IS 'stock_cvterm links a stock to cvterms. This is for secondary cvterms; primary cvterms should use stock.type_id.';


-- ================================================
-- TABLE: stock_genotype
-- ================================================

create table stock_genotype (
       stock_genotype_id serial not null,
       primary key (stock_genotype_id),
       stock_id int not null,
       foreign key (stock_id) references stock (stock_id) on delete cascade,
       genotype_id int not null,
       foreign key (genotype_id) references genotype (genotype_id) on delete cascade,
       constraint stock_genotype_c1 unique (stock_id, genotype_id)
);
create index stock_genotype_idx1 on stock_genotype (stock_id);
create index stock_genotype_idx2 on stock_genotype (genotype_id);

COMMENT ON TABLE STOCK_GENOTYPE IS 'Simple table linking a stock to
a genotype. Features with genotypes can be linked to stocks thru feature_genotype -> genotype -> stock_genotype -> stock.';


-- ================================================
-- TABLE: stockcollection
-- ================================================

create table stockcollection (
	stockcollection_id serial not null, 
        primary key (stockcollection_id),
	type_id int not null,
        foreign key (type_id) references cvterm (cvterm_id) on delete cascade,
        contact_id int null,
        foreign key (contact_id) references contact (contact_id) on delete set null INITIALLY DEFERRED,
	name varchar(255),
	uniquename text not null,
	constraint stockcollection_c1 unique (uniquename,type_id)
);
create index stockcollection_name_ind1 on stockcollection (name);
create index stockcollection_idx1 on stockcollection (contact_id);
create index stockcollection_idx2 on stockcollection (type_id);
create index stockcollection_idx3 on stockcollection (uniquename);

COMMENT ON TABLE STOCKCOLLECTION IS 'The lab or stock center distributing the stocks in their collection.';
COMMENT ON COLUMN STOCKCOLLECTION.UNIQUENAME IS 'uniqename is the value of the collection cv.';
COMMENT ON COLUMN STOCKCOLLECTION.TYPE_ID IS 'type_id is the collection type cv.';
COMMENT ON COLUMN STOCKCOLLECTION.NAME IS 'name is the collection.';
COMMENT ON COLUMN STOCKCOLLECTION.CONTACT_ID IS 'contact_id links to the contact info for the collection.';


-- ================================================
-- TABLE: stockcollectionprop
-- ================================================

create table stockcollectionprop (
    stockcollectionprop_id serial not null,
    primary key (stockcollectionprop_id),
    stockcollection_id int not null,
    foreign key (stockcollection_id) references stockcollection (stockcollection_id) on delete cascade INITIALLY DEFERRED,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id),
    value text null,
    rank int not null default 0,
    constraint stockcollectionprop_c1 unique (stockcollection_id,type_id,rank)
);
create index stockcollectionprop_idx1 on stockcollectionprop (stockcollection_id);
create index stockcollectionprop_idx2 on stockcollectionprop (type_id);

COMMENT ON TABLE STOCKCOLLECTIONPROP IS 'The table stockcollectionprop
contains the value of the stock collection such as website/email URLs;
the value of the stock collection order URLs.';
-- COMMENT ON COLUMN STOCKCOLLECTIONPROP.TYPE_ID IS 'The cv for the type_id is "stockcollection property type".';


-- ================================================
-- TABLE: stockcollection_stock
-- ================================================

create table stockcollection_stock (
    stockcollection_stock_id serial not null,
    primary key (stockcollection_stock_id),
    stockcollection_id int not null,
    foreign key (stockcollection_id) references stockcollection (stockcollection_id) on delete cascade INITIALLY DEFERRED,
    stock_id int not null,
    foreign key (stock_id) references stock (stock_id) on delete cascade INITIALLY DEFERRED,
    constraint stockcollection_stock_c1 unique (stockcollection_id,stock_id)
);
create index stockcollection_stock_idx1 on stockcollection_stock (stockcollection_id);
create index stockcollection_stock_idx2 on stockcollection_stock (stock_id);

COMMENT ON TABLE STOCKCOLLECTION_STOCK IS 'stockcollection_stock links
a stock collection to the stocks which are contained in the collection.';
