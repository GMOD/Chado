
create table scaffold_feature (
   scaffold_feature_id  varchar(50) not null,
   primary key (scaffold_feature_id), 
   feature_id int not null,
   foreign key (feature_id) references feature (feature_id),
   scaffold_id int not null,
   foreign key (scaffold_id) references feature (feature_id),
   arm_id int not null,
   foreign key (arm_id) references feature (feature_id),
   type_id int not null,
   foreign key (type_id) references cvterm (cvterm_id),
   unique (feature_id, scaffold_id)
);




create table feature_evidence (
   feature_evidence_id varchar(50) not null,
   primary key (feature_evidence_id), 
   feature_id int not null,
   foreign key (feature_id) references feature (feature_id),
   evidence_id int not null,
   foreign key (evidence_id) references feature (feature_id),
   unique (feature_id, evidence_id)
);

create table _appdata(
  _appdata_id not null
);
