-- NOTE: this is all due for revision

create table featuremap (
       featuremap_id serial not null,
       primary key (featuremap_id),
       mapname varchar(255),
       mapdesc varchar(255),
       mapunit varchar(255),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp
);

create table featurerange (
       featurerange_id serial not null,
       primary key (featurerange_id),
       featuremap_id int not null,
       foreign key (featuremap_id) references featuremap (featuremap_id),
       feature_id int not null,
       foreign key (feature_id) references feature (feature_id),
       leftstartf_id int not null,
       foreign key (leftstartf_id) references feature (feature_id),       
       leftendf_id int,
       foreign key (leftendf_id) references feature (feature_id),       
       rightstartf_id int,
       foreign key (rightstartf_id) references feature (feature_id),       
       rightendf_id int not null,
       foreign key (rightendf_id) references feature (feature_id),
       rangestr varchar(255),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp
);

-- In cases where the start and end of a mapped feature is a range, leftendf
-- and rightstartf are populated.  
-- featuremap_id is the id of the feature being mapped
-- leftstartf_id, leftendf_id, rightstartf_id, rightendf_id are the ids of
-- features with respect to with the feature is being mapped.  These may
-- be cytological bands.

create table featurepos (
       featuremap_id serial not null,
       foreign key (featuremap_id) references featuremap (featuremap_id),
       feature_id int not null,
       foreign key (feature_id) references feature (feature_id),
-- map_feature_id links to the feature (map) upon which the feature is
-- being localized
       map_feature_id int not null,
       foreign key (map_feature_id) references feature (feature_id),
       mappos float not null,
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp
);

create table featuremap_pub (
       featuremap_id int not null,
       foreign key (featuremap_id) references featuremap (featuremap_id),
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id),
       timeentered timestamp not null default current_timestamp,
       timelastmod timestamp not null default current_timestamp
);

-- A possibly problematic case is where we want to localize an object
-- to the left or right of a feature (but not within it):
--
--                     |---------|  feature-to-map
--        ------------------------------------------------- map
--                |------|         |----------|   features to map wrt
--
-- How do we map the 3' end of the feature-to-map?

-- TODO:  Get a comprehensive set of mapping use-cases 

-- one set of use-cases is aberrations (which will all be involved with this 
-- module).   Simple aberrations should be do-able, but what about cases where
-- a breakpoint interrupts a gene?  This would be an example of the problematic
-- case above...  (or?)

