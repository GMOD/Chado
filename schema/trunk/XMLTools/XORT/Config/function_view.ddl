create table prediction_evidence (
   prediction_evidence_id varchar(50) not null,
   primary key (prediction_evidence_id), 
   feature_id int not null,
   foreign key (feature_id) references feature (feature_id),
   evidence_id int not null,
   foreign key (evidence_id) references feature (feature_id),
   analysis_id int not null,
   foreign key (analysis_id) references analysis (analysis_id),
   unique (feature_id, evidence_id, analysis_id)
);

create table alignment_evidence (
   alignment_evidence_id varchar(50) not null,
   primary key (alignment_evidence_id), 
   feature_id int not null,
   foreign key (feature_id) references feature (feature_id),
   evidence_id int not null,
   foreign key (evidence_id) references feature (feature_id),
   analysis_id int not null,
   foreign key (analysis_id) references analysis (analysis_id),
   unique (feature_id, evidence_id, analysis_id)
);


create table _appdata (
  _appdata_id not null,
  primary key (_appdata_id), 
);
