create table feature_evidence (
   feature_evidence_id varchar(50) not null,
   primary key (feature_evidence_id), 
   feature_id int not null,
   foreign key (feature_id) references feature (feature_id),
   evidence_id int not null,
   foreign key (evidence_id) references feature (feature_id),
   unique (feature_id, evidence_id)
);

create table _appdata (
  _appdata_id not null,
  primary key (_appdata_id), 
);
