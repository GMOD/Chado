create table featuremap (
       featuremap_id serial not null,
       mapname varchar(255),
       mapdesc varchar(255),
       mapunit varchar(255)
);

create table featurerange (
       featurerange_id serial not null,
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
       foreign key (rightstartf_id) references feature (feature_id),
       rangestr varchar(255)
);


create table featurepos (
       featuremap_id serial not null,
       foreign key (featuremap_id) references featuremap (featuremap_id),
       feature_id int not null,
       foreign key (feature_id) references feature (feature_id),
       mappos float not null
)

create table featuremap_pub (
       featuremap_id int not null,
       foreign key (featuremap_id) references featuremap (featuremap_id),
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id)              
)
