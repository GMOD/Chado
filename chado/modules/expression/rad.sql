--changed some of the pk/fk names to conform to chado conventions (removed _)
--changed field names (removed _s)
--changed some tablenames by adding _ to link tables, dropping _ where no link.
--dropped trailing '-imp' off some tablenames
--dropped external_database_release_id fields
--mapped contact links to author table
--mapped bibliographic references to pub table
--source_id changed to dbxref_id
--dropped analysis in favor of companalysis/analysis
--dropped analysisimplementation in favor of companalysis/analysis
--dropped analysisimplementationparam in favor of companalysis/analysis
--dropped analysisinvocation in favor of companalysis/analysisinvocation
--arrayannotation renamed as arrayprop
--dropped projectlink
--dropped studydesign_assay
--renamed studydesigndescription as studydesignprop
--renamed assay_labeledextract as assay_biomaterial for clarity, made channel_id nullable, and dropped old assay_biomaterial table
--dropped compositeelementresult, we can just use elementresult instead for both composite and simple elements
--quantificationparam renamed as quantificationprop
--process* tables have been removed.  processes are analagous to analyses, and unless i can be convinced otherwise, the same tables
--used in companalysis will suffice.  maybe the companalysis should be renamed as compprocess?
--dropped analysisinvocation_quantification in favor of having analysisinvocation_id as a nullable FK in quantification.  how can a quantification ever have more than one associated processing step associated with it?  tableinfo_id is in analysisinvocation, so we can drop it from quantification
--dropped labeledextract table, it's the same thing as biomaterial but with a labelelmethod fk.  let's make the labelmethod a biomaterialprop, so then we can knock out the labelmethod table
--added a biomaterialrelationship table so that we can track biosource->biosample->labeledextract processing steps

create table mageml (
    mageml_id serial not null,
	primary key (mageml_id),
    mage_package varchar(100) not null,
    mage_ml varchar not null
);

create table magedocumentation (
    magedocumentation_id serial not null,
	primary key (magedocumentation_id),
    mageml_id int not null,
	foreign key (mageml_id) references mageml (mageml_id) on delete cascade,
    tableinfo_id int not null,
	foreign key (tableinfo_id) references tableinfo (tableinfo_id) on delete cascade,
    row_id int not null,
    mageidentifier varchar(100) not null
);

create table protocol (
    protocol_id serial not null,
	primary key (protocol_id),
    type_id int not null,
	foreign key (type_id) references cvterm (cvterm_id) on delete cascade,
    pub_id int null,
	foreign key (pub_id) references pub (pub_id) on delete set null,
    dbxref_id int null,
	foreign key (dbxref_id) references dbxref (dbxref_id) on delete set null,
    name varchar(100) not null,
    uri varchar(100) null,
    protocoldescription varchar(4000) null,
    hardwaredescription varchar(500) null,
    softwaredescription varchar(500) null
);

create table protocolparam (
    protocolparam_id serial not null,
	primary key (protocolparam_id),
    protocol_id int not null,
	foreign key (protocol_id) references protocol (protocol_id) on delete cascade,
    name varchar(100) not null,
    datatype_id int null,
	foreign key (datatype_id) references cvterm (cvterm_id) on delete set null,
    unittype_id int null,
	foreign key (unittype_id) references cvterm (cvterm_id) on delete set null,
    value varchar(100) null
);

create table channel (
    channel_id serial not null,
	primary key (channel_id),
    name varchar(100) not null,
    definition varchar(500) not null
);

create table array (
    array_id serial not null,
	primary key (array_id),
    manufacturer_id int not null,
	foreign key (manufacturer_id) references contact (contact_id) on delete cascade,
    platformtype_id int not null,
	foreign key (platformtype_id) references cvterm (cvterm_id) on delete cascade,
    substratetype_id int null,
	foreign key (substratetype_id) references cvterm (cvterm_id) on delete set null,
    protocol_id int null,
	foreign key (protocol_id) references protocol (protocol_id) on delete set null,
    dbxref_id int null,
	foreign key (dbxref_id) references dbxref (dbxref_id) on delete set null,
    name varchar(100) not null,
    version varchar(50) null,
    description varchar(500) null,
    array_dimensions varchar(50) null,
    element_dimensions varchar(50) null,
    num_of_elements int null,
    num_array_columns int null,
    num_array_rows int null,
    num_grid_columns int null,
    num_grid_rows int null,
    num_sub_columns int null,
    num_sub_rows int null
);

create table arrayprop (
    arrayprop_id int not null,
	primary key (arrayprop_id),
    array_id int not null,
	foreign key (array_id) references array (array_id) on delete cascade,
    type_id int not null,
	foreign key (type_id) references cvterm (cvterm_id) on delete cascade,
    value varchar(100) not null
);

create table assay (
    assay_id serial not null,
	primary key (assay_id),
    array_id int not null,
	foreign key (array_id) references array (array_id) or delete cascade,
    protocol_id int null,
	foreign key (protocol_id) references protocol (protocol_id) on delete set null,
    assaydate date null,
    arrayidentifier varchar(100) null,
    arraybatchidentifier varchar(100) null,
    operator_id int not null,
	foreign key (operator_id) references contact (contact_id) on delete cascade,
    dbxref_id int null,
	foreign key (dbxref_id) references dbxref (dbxref_id) on delete set null,
    name varchar(100) null,
    description varchar(500) null
);

create table biomaterial (
    biomaterial_id serial not null,
	primary key (biomaterial_id),
    taxon_id int null,
	foreign key (taxon_id) references organism (organism_id) on delete set null,
    biosourceprovider_id int null,
	foreign key (biosourceprovider_id) references contact (contact_id) on delete set null,
--is this table still an imp, needs to have a view to use?
--    subclass_view varchar(27) not null,
    dbxref_id varchar(50) null,
	foreign key (dbxref_id) references dbxref (dbxref_id) on delete set null,
--what about these fields?
    name varchar(100) null,
    description varchar(500) null
);

create table biomaterialrelationship (
    biomaterialrelationship_id serial not null,
        primary key (biomaterialrelationship_id),
    subject_id int not null
        foreign key (subject_id) references cvterm (cvterm_id),
    type_id int not null,
        foreign key (type_id) references cvterm (cvterm_id),
    object_id int not null
        foreign key (object_id) references cvterm (cvterm_id)
);

create table biomaterialprop (
    biomaterialprop_id serial not null,
	primary key (biomaterialprop_id),
    biomaterial_id int not null,
	foreign key (biomaterial_id) references biomaterial (biomaterial_id) on delete cascade,
    type_id int not null,
	foreign key (type_id) references cvterm (cvterm_id) on delete cascade,
    value varchar(100) null
);

create table treatment (
    treatment_id serial not null,
	primary key (treatment_id),
--what is this field for?
    ordernum int not null,
--and this one?  shouldn't biomaterial reference treatments, not the other way around?
    biomaterial_id int not null,
	foreign key (biomaterial_id) references biomaterial (biomaterial_id) on delete cascade,
    type_id int not null,
	foreign key (type_id) references cvterm (cvterm_id) on delete cascade,
    protocol_id int null,
	foreign key (protocol_id) references protocol (protocol_id) on delete set null,
    name varchar(100) null
);

create table biomaterialmeasurement (
    biomaterialmeasurement_id serial not null,
	primary key (biomaterialmeasurement_id),
    treatment_id int not null,
	foreign key (treatment_id) references treatment (treatment_id) on delete cascade,
    biomaterial_id int not null,
	foreign key (biomaterial_id) references biomaterial (biomaterial_id) on delete cascade,
    value float(15) null,
    unittype_id int null,
	foreign key (unittype_id) references cvterm (cvterm_id) on delete set null
);

create table assay_biomaterial (
    assay_biomaterial_id serial not null,
	primary key (assay_biomaterial_id),
    assay_id int not null,
	foreign key (assay_id) references assay (assay_id) on delete cascade,
    biomaterial_id int not null,
	foreign key (biomaterial_id) references biomaterial (biomaterial_id) on delete cascade,
    channel_id int null,
	foreign key (channel_id) references channel (channel_id) on delete set null
);

create table acquisition (
    acquisition_id serial not null,
	primary key (acquisition_id),
    assay_id int not null,
	foreign key (assay_id) references  assay (assay_id) on delete cascade,
    protocol_id int null,
	foreign key (protocol_id) references protocol (protocol_id) on delete set null,
    channel_id int null,
	foreign key (channel_id) references channel (channel_id) on delete set null,
    acquisitiondate date null,
    name varchar(100) null,
    uri varchar(255) null
);

create table acquisitionprop (
    acquisitionprop_id serial not null,
	primary key (acquisitionprop_id),
    acquisition_id int not null,
	foreign key (acquisition_id) references acquisition (acquisition_id) on delete cascade,
    type_id int not null,
        foreign key (type_id) references cvterm (cvterm_id) on delete cascade,
    value varchar(50) not null
);

create table acquisitionrelationship (
    acquisitionrelationship_id serial not null,
	primary key (acquisitionrelationship_id),
    subject_id int not null,
	foreign key (subject_id) references acquisition (acquisition_id) on delete cascade,
    type_id int not null,
	foreign key (type_id) references cvterm (cvterm_id) on delete cascade,
    object_id int not null,
	foreign key (object_id) references acquisition (acquisition_id) on delete cascade
);

create table quantification (
    quantification_id serial not null,
	primary key (quantification_id),
    acquisition_id int not null,
	foreign key (acquisition_id) references acquisition (acquisition_id) on delete cascade,
    operator_id int null,
	foreign key (operator_id) references contact (contact_id) on delete set null,
    protocol_id int null,
	foreign key (protocol_id) references protocol (protocol_id) on delete set null,
    analysisinvocation_id int not null,
	foreign key (analysisinvocation_id) references analysisinvocation (analysisinvocation_id) on delete cascade,
    quantificationdate date null,
    name varchar(100) null,
    uri varchar(500) null
);

create table quantificationprop (
    quantificationprop_id serial not null,
	primary key (quantificationprop_id),
    quantification_id int not null,
	foreign key (quantification_id) references quantification (quantification_id) on delete cascade,
    type_id int not null,
	foreign key (type_id) references cvterm (cvterm_id) on delete cascade,
    value varchar(50) not null
);

create table quantificationrelationship (
    quantificationrelationship_id serial not null,
	primary key (quantificationrelationship_id),
    subject_id int not null,
	foreign key (subject_id) references quantification (quantification_id) on delete cascade,
	type_id int not null,
	foreign key (type_id) references cvterm (cvterm_id) on delete cascade,
    object_id int not null,
	foreign key (object_id) references quantification (quantification_id) on delete cascade
);

create table control (
    control_id serial not null,
	primary key (control_id),
    controltype_id int not null,
	foreign key (controltype_id) references cvterm (cvterm_id) on delete cascade,
    assay_id int not null,
	foreign key (assay_id) references assay (assay_id) on delete cascade,
    tableinfo_id int not null,
	foreign key (tableinfo_id) references tableinfo (tableinfo_id) on delete cascade,
    row_id int not null,
    name varchar(100) null,
    value varchar(255) null
);

create table element (
    element_id serial not null,
	primary key (element_id),
    feature_id int null,
	foreign key (feature_id) references feature (feature_id) on delete set null,
    array_id int not null,
	foreign key (array_id) references array (array_id) on delete cascade,
    type_id int null,
	foreign key (type_id) references cvterm (cvterm_id) on delete set null,
    dbxref_id int null,
	foreign key (dbxref_id) references dbxref (dbxref_id) on delete set null,
    subclass_view varchar(27) not null,
    tinyint1 int null,
    smallint1 int null,
    char1 varchar(5) null,
    char2 varchar(5) null,
    char3 varchar(5) null,
    char4 varchar(5) null,
    char5 varchar(5) null,
    char6 varchar(5) null,
    char7 varchar(5) null,
    tinystring1 varchar(50) null,
    tinystring2 varchar(50) null,
    smallstring1 varchar(100) null,
    smallstring2 varchar(100) null,
    string1 varchar(500) null,
    string2 varchar(500) null
);

create table elementresult (
    elementresult_id serial not null,
	primary key (elementresult_id),
    element_id int not null,
	foreign key (element_id) references element (element_id) on delete cascade,
    quantification_id int not null,
	foreign key (quantification_id) references quantification (quantification_id) on delete cascade,
    subclass_view varchar(27) not null,
    foreground float(15) null,
    background float(15) null,
    foreground_sd float(15) null,
    background_sd float(15) null,
    float1 float(15) null,
    float2 float(15) null,
    float3 float(15) null,
    float4 float(15) null,
    float5 float(15) null,
    float6 float(15) null,
    float7 float(15) null,
    float8 float(15) null,
    float9 float(15) null,
    float10 float(15) null,
    int1 int null,
    int2 int null,
    int3 int null,
    int4 int null,
    int5 int null,
    int6 int null,
    tinyint1 int null,
    tinyint2 int null,
    smallint1 int null,
    smallint2 int null,
    char1 varchar(5) null,
    char2 varchar(5) null,
    char3 varchar(5) null,
    char4 varchar(5) null,
    char5 varchar(5) null,
    char6 varchar(5) null,
    tinystring1 varchar(50) null,
    tinystring2 varchar(50) null,
    tinystring3 varchar(50) null,
    smallstring1 varchar(100) null,
    smallstring2 varchar(100) null,
    string1 varchar(500) null,
    string2 varchar(500) null
);

--this is so we can knock out the compositeelementresult_id FK from elementresult
--better to just have a part_of relationship between elements
create table elementesultrelationship (
    elementresultrelationship_id serial not null,
        primary key (elementresultrelationship_id),
    subject_id int not null,
        foreign key (subject_id) references cvterm (cvterm_id),
    type_id int not null,
        foreign key (type_id) references cvterm (cvterm_id),
    object_id int not null,
        foreign key (object_id) references cvterm (cvterm_id),
);

create table study (
    study_id serial not null,
	primary key (study_id),
    contact_id int not null,
	foreign key (contact_id) references contact (contact_id) on delete cascade,
   	pub_id int null,
	foreign key (pub_id) references pub (pub_id) on delete set null,
    dbxref_id int null,
	foreign key (dbxref_id) references dbxref (dbxref_id) on delete set null,
    name varchar(100) not null,
    description varchar(4000) null
);

create table study_assay (
    study_assay_id serial not null,
	primary key (study_assay_id),
    study_id int not null,
	foreign key (study_id) references study (study_id) on delete cascade,
    assay_id int not null,
	foreign key (assay_id) references assay (assay_id) on delete cascade
);

create table studydesign (
    studydesign_id serial not null,
	primary key (studydesign_id),
    study_id int not null,
	foreign key (study_id) references study (study_id) on delete cascade,
    description varchar(4000) null
);

create table studydesignprop (
    studydesignprop_id serial not null,
	primary key (studydesignprop_id),
    studydesign_id int not null,
	foreign key (studydesign_id) references studydesign (studydesign_id) on delete cascade,
	type_id int not null,
	foreign key (type_id) references cvterm (cvterm_id) on delete cascade,
    value varchar(500) not null
);

create table studyfactor (
    studyfactor_id serial not null,
	primary key (studyfactor_id),
    studydesign_id int not null,
	foreign key (studydesign_id) references studydesign (studydesign_id) on delete cascade,
    type_id int null,
	foreign key (type_id) references cvterm (cvterm_id) on delete set null,
    name varchar(100) not null,
    description varchar(500) null
);

create table studyfactorvalue (
    studyfactorvalue_id serial not null,
	primary key (studyfactorvalue_id),
    studyfactor_id int not null,
	foreign key (studyfactor_id) references studyfactor (studyfactor_id) on delete cascade,
    assay_id int not null,
	foreign key (assay_id) references assay (assay_id) on delete cascade,
    factorvalue varchar(100) not null,
    name varchar(100) null
);
