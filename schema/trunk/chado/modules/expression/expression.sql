## This module is totally dependant on the sequence module.  Objects in the
## genetic module cannot connect to expression data except by going via the
## sequence module


## We assume that we'll *always* have a controlled vocabulary for expression 
## data.   If an experiment used a set of cv terms different from the ones
## FlyBase uses (bodypart cv, bodypart qualifier cv, and the temporal cv
## (which is stored in the curaton.doc under GAT6 btw)), they'd have to give
## us the cv terms, which we could load into the cv module


## ================================================
## TABLE: expression
## ================================================

create table expression (
       expression_id serial not null,
       primary key (expression_id),
       description text,
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp
);

## ================================================
## TABLE: feature_expression
## ================================================

create table feature_expression (
       expression_id int not null,
       foreign key (expression_id) references expression (expression_id),
       feature_id int not null,
       foreign key (feature_id) references feature (feature_id),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp
);


## What are the possibities of combination when more than one cvterm is used
## in a field?   
##
## For eg (in <p> here):   <t> E | early <a> <p> anterior & dorsal
## If the two terms used in a particular field are co-equal (both from the
## same CV, is the relation always "&"?   May we find "or"?
##
## Obviously another case is when a bodypart term and a bodypart qualifier
## term are used in a specific field, eg:
##   <t> L | third instar <a> larval antennal segment sensilla | subset <p  
##

## WRT the three-part <t><a><p> statements, are the values in the different 
## parts *always* from different vocabularies in proforma.CV?   If not,
## we'll need to have some kind of type qualifier telling us whether the
## cvterm used is <t>, <a>, or <p>


## ================================================
## TABLE: expression_cvterm
## ================================================

create table expression_cvterm (
       expression_id int not null,
       foreign key (expression_id) references expression (expression_id),
       cvterm_id int not null,
       foreign key (cvterm_id) references cvterm (cvterm_id),
       rank int not null,
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp
);

## ================================================
## TABLE: expression_pub
## ================================================

create table expression_pub (
       expression_id int not null,
       foreign key (expression_id) references expression (expression_id),
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp
);

## ================================================
## TABLE: eimage
## ================================================

create table eimage (
       eimage_id serial not null,
       primary key (eimage_id),
## we expect images in eimage_data (eg jpegs) to be uuencoded
       eimage_data text,
## describes the type of data in eimage_data
       eimage_type varchar(255) not null,
       image_uri varchar(255),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp
);

## ================================================
## TABLE: expression_image
## ================================================

create table expression_image (
       expression_id int not null,
       foreign key (expression_id) references expression (expression_id),
       eimage_id int not null,
       foreign key (eimage_id) references eimage (eimage_id),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp
);


