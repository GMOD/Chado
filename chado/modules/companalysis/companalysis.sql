create table analysis (
    analysis_id serial not null,
    primary key (analysis_id),
    name varchar(255),
## Chris, I changed this to adesc because desc is a sql keyword
    adesc text,
    timeentered timestamp not null default current_timestamp,
    timelastmod timestamp not null default current_timestamp
);

create table analysisprop (
    analysis_id int not null,
    foreign key (analysis_id) references analysis (analysis_id),
    pkey_id int not null,
    foreign key (pkey_id) references cvterm (cvterm_id),
    pval text,
    timeentered timestamp not null default current_timestamp,
    timelastmod timestamp not null default current_timestamp
);

create table featurepair (
    featurepair_id serial not null,
    primary key (featurepair_id),
    analysis_id int not null,
    foreign key (analysis_id) references analysis (analysis_id),
    feature1_id int not null,
    foreign key (feature1_id) references feature (feature_id),
    feature2_id int not null,
    foreign key (feature2_id) references feature (feature_id),
    scorestr varchar(255),
    timeentered timestamp not null default current_timestamp,
    timelastmod timestamp not null default current_timestamp

);

create table multalign (
    multalign_id serial not null,
    primary key (multalign_id),
    analysis_id int not null,
    foreign key (analysis_id)  references analysis (analysis_id),
    scorestr varchar(255),
    timeentered timestamp not null default current_timestamp,
    timelastmod timestamp not null default current_timestamp
);


create table multalign_feature (
    multalign_id int not null,
    foreign key (multalign_id) references multalign (multalign_id),
    feature_id int not null,
    foreign key (feature_id) references feature (feature_id),
    timeentered timestamp not null default current_timestamp,
    timelastmod timestamp not null default current_timestamp
);

