create table mageml (
    mageml_id serial not null,
	primary key (mageml_id),
    mage_package text not null,
    mage_ml text not null
);

COMMENT ON TABLE mageml IS 'this table is for storing extra bits of mageml in a denormalized form.  more normalization would require many more tables';

create table magedocumentation (
    magedocumentation_id serial not null,
	primary key (magedocumentation_id),
    mageml_id int not null,
	foreign key (mageml_id) references mageml (mageml_id) on delete cascade,
    tableinfo_id int not null,
	foreign key (tableinfo_id) references tableinfo (tableinfo_id) on delete cascade,
    row_id int not null,
    mageidentifier text not null
);
create index magedocumentation_idx1 on magedocumentation (mageml_id);
create index magedocumentation_idx2 on magedocumentation (tableinfo_id);
create index magedocumentation_idx3 on magedocumentation (row_id);

COMMENT ON TABLE magedocumentation IS NULL;

create table protocol (
    protocol_id serial not null,
	primary key (protocol_id),
    type_id int not null,
	foreign key (type_id) references cvterm (cvterm_id) on delete cascade,
    pub_id int null,
	foreign key (pub_id) references pub (pub_id) on delete set null,
    dbxref_id int null,
	foreign key (dbxref_id) references dbxref (dbxref_id) on delete set null,
    name text not null,
    uri text null,
    protocoldescription text null,
    hardwaredescription text null,
    softwaredescription text null,
    unique(name)
);
create index protocol_idx1 on protocol (type_id);
create index protocol_idx2 on protocol (pub_id);
create index protocol_idx3 on protocol (dbxref_id);

COMMENT ON TABLE protocol IS 'procedural notes on how data was prepared and processed';

create table protocolparam (
    protocolparam_id serial not null,
	primary key (protocolparam_id),
    protocol_id int not null,
	foreign key (protocol_id) references protocol (protocol_id) on delete cascade,
    name text not null,
    datatype_id int null,
	foreign key (datatype_id) references cvterm (cvterm_id) on delete set null,
    unittype_id int null,
	foreign key (unittype_id) references cvterm (cvterm_id) on delete set null,
    value text null,
    rank int not null default 0
);
create index protocolparam_idx1 on protocolparam (protocol_id);
create index protocolparam_idx2 on protocolparam (datatype_id);
create index protocolparam_idx3 on protocolparam (unittype_id);

COMMENT ON TABLE protocolparam IS 'parameters related to a protocol.  if the protocol is a soak, this might include attributes of bath temperature and duration';

create table channel (
    channel_id serial not null,
	primary key (channel_id),
    name text not null,
    definition text not null,
    unique(name)
);

COMMENT ON TABLE channel IS 'different array platforms can record signals from one or more channels (cDNA arrays typically use two CCD, but affy uses only one)';

create table arraydesign (
    arraydesign_id serial not null,
	primary key (arraydesign_id),
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
    name text not null,
    version text null,
    description text null,
    array_dimensions text null,
    element_dimensions text null,
    num_of_elements int null,
    num_array_columns int null,
    num_array_rows int null,
    num_grid_columns int null,
    num_grid_rows int null,
    num_sub_columns int null,
    num_sub_rows int null,
    unique(name)
);
create index arraydesign_idx1 on arraydesign (manufacturer_id);
create index arraydesign_idx2 on arraydesign (platformtype_id);
create index arraydesign_idx3 on arraydesign (substratetype_id);
create index arraydesign_idx4 on arraydesign (protocol_id);
create index arraydesign_idx5 on arraydesign (dbxref_id);

COMMENT ON TABLE arraydesign IS 'general properties about an array.  and array is a template used to generate physical slides, etc.  it contains layout information, as well as global array properties, such as material (glass, nylon) and spot dimensions(in rows/columns).';

create table arrayprop (
    arrayprop_id serial not null,
	primary key (arrayprop_id),
    arraydesign_id int not null,
	foreign key (arraydesign_id) references arraydesign (arraydesign_id) on delete cascade,
    type_id int not null,
	foreign key (type_id) references cvterm (cvterm_id) on delete cascade,
    value text not null,
    rank int not null default 0,
    unique(arraydesign_id, type_id, rank)
);
create index arrayprop_idx1 on arrayprop (arraydesign_id);
create index arrayprop_idx2 on arrayprop (type_id);

COMMENT ON TABLE arrayprop IS 'extra array properties that are not accounted for in array';

create table assay (
    assay_id serial not null,
	primary key (assay_id),
    arraydesign_id int not null,
	foreign key (arraydesign_id) references arraydesign (arraydesign_id) on delete cascade,
    protocol_id int null,
	foreign key (protocol_id) references protocol (protocol_id) on delete set null,
    assaydate timestamp null default current_timestamp,
    arrayidentifier text null,
    arraybatchidentifier text null,
    operator_id int not null,
	foreign key (operator_id) references contact (contact_id) on delete cascade,
    dbxref_id int null,
	foreign key (dbxref_id) references dbxref (dbxref_id) on delete set null,
    name text null,
    description text null,
    unique(name)
);
create index assay_idx1 on assay (arraydesign_id);
create index assay_idx2 on assay (protocol_id);
create index assay_idx3 on assay (operator_id);
create index assay_idx4 on assay (dbxref_id);

COMMENT ON TABLE assay IS 'an assay consists of a physical instance of an array, combined with the conditions used to create the array (protocols, technician info).  the assay can be thought of as a hybridization';

create table assayprop (
    assayprop_id serial not null,
	primary key (assayprop_id),
    assay_id int not null,
	foreign key (assay_id) references assay (assay_id) on delete cascade,
    type_id int not null,
	foreign key (type_id) references cvterm (cvterm_id) on delete cascade,
    value text not null,
    rank int not null default 0,
    unique(assay_id, type_id, rank)
);
create index assayprop_idx1 on assayprop (assay_id);
create index assayprop_idx2 on assayprop (type_id);

COMMENT ON TABLE assayprop IS 'extra assay properties that are not accounted for in assay';

create table assay_project (
    assay_project_id serial not null,
        primary key (assay_project_id),
    assay_id int not null,
        foreign key (assay_id) references assay (assay_id),
    project_id int not null,
        foreign key (project_id) references project (project_id),
    unique(assay_id,project_id)
);
create index assay_project_idx1 on assay_project (assay_id);
create index assay_project_idx2 on assay_project (project_id);

COMMENT ON TABLE assay_project IS 'link assays to projects';

create table biomaterial (
    biomaterial_id serial not null,
	primary key (biomaterial_id),
    taxon_id int null,
	foreign key (taxon_id) references organism (organism_id) on delete set null,
    biosourceprovider_id int null,
	foreign key (biosourceprovider_id) references contact (contact_id) on delete set null,
    dbxref_id int null,
	foreign key (dbxref_id) references dbxref (dbxref_id) on delete set null,
    name text null,
    description text null,
    unique(name)
);
create index biomaterial_idx1 on biomaterial (taxon_id);
create index biomaterial_idx2 on biomaterial (biosourceprovider_id);
create index biomaterial_idx3 on biomaterial (dbxref_id);

COMMENT ON TABLE biomaterial IS 'a biomaterial represents the MAGE concept of BioSource, BioSample, and LabeledExtract.  it is essentially some biological material (tissue, cells, serum) that may have been processed.  processed biomaterials should be traceable back to raw biomaterials via the biomaterialrelationship table.';

create table biomaterial_relationship (
    biomaterial_relationship_id serial not null,
        primary key (biomaterial_relationship_id),
    subject_id int not null,
        foreign key (subject_id) references biomaterial (biomaterial_id),
    type_id int not null,
        foreign key (type_id) references cvterm (cvterm_id),
    object_id int not null,
        foreign key (object_id) references biomaterial (biomaterial_id),
    unique(subject_id,type_id,object_id)
);
create index biomaterial_relationship_idx1 on biomaterial_relationship (subject_id);
create index biomaterial_relationship_idx2 on biomaterial_relationship (object_id);
create index biomaterial_relationship_idx3 on biomaterial_relationship (type_id);

COMMENT ON TABLE biomaterial_relationship IS 'relate biomaterials to one another.  this is a way to track a series of treatments or material splits/merges, for instance';

create table biomaterialprop (
    biomaterialprop_id serial not null,
	primary key (biomaterialprop_id),
    biomaterial_id int not null,
	foreign key (biomaterial_id) references biomaterial (biomaterial_id) on delete cascade,
    type_id int not null,
	foreign key (type_id) references cvterm (cvterm_id) on delete cascade,
    value text null,
    rank int not null,
    unique(biomaterial_id,type_id,rank)
);
create index biomaterialprop_idx1 on biomaterialprop (biomaterial_id);
create index biomaterialprop_idx2 on biomaterialprop (type_id);

COMMENT ON TABLE biomaterialprop IS 'extra biomaterial properties that are not accounted for in biomaterial';

create table treatment (
    treatment_id serial not null,
	primary key (treatment_id),
    rank int not null default 0,
    biomaterial_id int not null,
	foreign key (biomaterial_id) references biomaterial (biomaterial_id) on delete cascade,
    type_id int not null,
	foreign key (type_id) references cvterm (cvterm_id) on delete cascade,
    protocol_id int null,
	foreign key (protocol_id) references protocol (protocol_id) on delete set null,
    name text null
);
create index treatment_idx1 on treatment (biomaterial_id);
create index treatment_idx2 on treatment (type_id);
create index treatment_idx3 on treatment (protocol_id);

COMMENT ON TABLE treatment IS 'a biomaterial may undergo multiple treatments.  this can range from apoxia to fluorophore and biotin labeling';

create table biomaterial_treatment (
    biomaterial_treatment_id serial not null,
        primary key (biomaterial_treatment_id),
    biomaterial_id int not null,
	foreign key (biomaterial_id) references biomaterial (biomaterial_id) on delete cascade,
    treatment_id int not null,
	foreign key (treatment_id) references treatment (treatment_id) on delete cascade,
    unittype_id int null,
	foreign key (unittype_id) references cvterm (cvterm_id) on delete set null,
    value float(15) null,
    rank int not null default 0
);
create index biomaterial_treatment_idx1 on biomaterial_treatment (biomaterial_id);
create index biomaterial_treatment_idx2 on biomaterial_treatment (treatment_id);
create index biomaterial_treatment_idx3 on biomaterial_treatment (unittype_id);

COMMENT ON TABLE biomaterial_treatment IS 'link biomaterials to treatments.  treatments have an order of operations (rank), and associated measurements (unittype_id, value)';

create table assay_biomaterial (
    assay_biomaterial_id serial not null,
	primary key (assay_biomaterial_id),
    assay_id int not null,
	foreign key (assay_id) references assay (assay_id) on delete cascade,
    biomaterial_id int not null,
	foreign key (biomaterial_id) references biomaterial (biomaterial_id) on delete cascade,
    channel_id int null,
	foreign key (channel_id) references channel (channel_id) on delete set null,
    unique(assay_id,biomaterial_id,channel_id)
);
create index assay_biomaterial_idx1 on assay_biomaterial (assay_id);
create index assay_biomaterial_idx2 on assay_biomaterial (biomaterial_id);
create index assay_biomaterial_idx3 on assay_biomaterial (channel_id);

COMMENT ON TABLE assay_biomaterial IS 'a biomaterial can be hybridized many times (technical replicates), or combined with other biomaterials in a single hybridization (for two-channel arrays)';

create table acquisition (
    acquisition_id serial not null,
	primary key (acquisition_id),
    assay_id int not null,
	foreign key (assay_id) references  assay (assay_id) on delete cascade,
    protocol_id int null,
	foreign key (protocol_id) references protocol (protocol_id) on delete set null,
    channel_id int null,
	foreign key (channel_id) references channel (channel_id) on delete set null,
    acquisitiondate timestamp null default current_timestamp,
    name text null,
    uri text null,
    unique(name)
);
create index acquisition_idx1 on acquisition (assay_id);
create index acquisition_idx2 on acquisition (protocol_id);
create index acquisition_idx3 on acquisition (channel_id);

COMMENT ON TABLE acquisition IS 'this represents the scanning of hybridized material.  the output of this process is typically a digital image of an array';

create table acquisitionprop (
    acquisitionprop_id serial not null,
	primary key (acquisitionprop_id),
    acquisition_id int not null,
	foreign key (acquisition_id) references acquisition (acquisition_id) on delete cascade,
    type_id int not null,
        foreign key (type_id) references cvterm (cvterm_id) on delete cascade,
    value text null,
    rank int not null default 0,
    unique(acquisition_id, type_id, rank)
);
create index acquisitionprop_idx1 on acquisitionprop (acquisition_id);
create index acquisitionprop_idx2 on acquisitionprop (type_id);

COMMENT ON TABLE acquisitionprop IS 'parameters associated with image acquisition';

create table acquisition_relationship (
    acquisition_relationship_id serial not null,
	primary key (acquisition_relationship_id),
    subject_id int not null,
	foreign key (subject_id) references acquisition (acquisition_id) on delete cascade,
    type_id int not null,
	foreign key (type_id) references cvterm (cvterm_id) on delete cascade,
    object_id int not null,
	foreign key (object_id) references acquisition (acquisition_id) on delete cascade,
    value text null,
    rank int not null default 0,
    unique(subject_id, type_id, object_id, rank)
);
create index acquisition_relationship_idx1 on acquisition_relationship (subject_id);
create index acquisition_relationship_idx2 on acquisition_relationship (type_id);
create index acquisition_relationship_idx3 on acquisition_relationship (object_id);

COMMENT ON TABLE acquisition_relationship IS 'multiple monochrome images may be merged to form a multi-color image.  red-green images of 2-channel hybridizations are an example of this';

create table quantification (
    quantification_id serial not null,
	primary key (quantification_id),
    acquisition_id int not null,
	foreign key (acquisition_id) references acquisition (acquisition_id) on delete cascade,
    operator_id int null,
	foreign key (operator_id) references contact (contact_id) on delete set null,
    protocol_id int null,
	foreign key (protocol_id) references protocol (protocol_id) on delete set null,
    analysis_id int not null,
	foreign key (analysis_id) references analysis (analysis_id) on delete cascade,
    quantificationdate timestamp null default current_timestamp,
    name text null,
    uri text null,
    unique(name,analysis_id)
);
create index quantification_idx1 on quantification (acquisition_id);
create index quantification_idx2 on quantification (operator_id);
create index quantification_idx3 on quantification (protocol_id);
create index quantification_idx4 on quantification (analysis_id);

COMMENT ON TABLE quantification IS 'quantification is the transformation of an image acquisition to numeric data.  this typically involves statistical procedures.';

create table quantificationprop (
    quantificationprop_id serial not null,
	primary key (quantificationprop_id),
    quantification_id int not null,
	foreign key (quantification_id) references quantification (quantification_id) on delete cascade,
    type_id int not null,
	foreign key (type_id) references cvterm (cvterm_id) on delete cascade,
    value text null,
    rank int not null default 0,
    unique(quantification_id, type_id, rank)
);
create index quantificationprop_idx1 on quantificationprop (quantification_id);
create index quantificationprop_idx2 on quantificationprop (type_id);

COMMENT ON TABLE quantificationprop IS 'extra quantification properties that are not accounted for in quantification';

create table quantification_relationship (
    quantification_relationship_id serial not null,
	primary key (quantification_relationship_id),
    subject_id int not null,
	foreign key (subject_id) references quantification (quantification_id) on delete cascade,
    type_id int not null,
	foreign key (type_id) references cvterm (cvterm_id) on delete cascade,
    object_id int not null,
	foreign key (object_id) references quantification (quantification_id) on delete cascade,
    unique(subject_id,type_id,object_id)
);
create index quantification_relationship_idx1 on quantification_relationship (subject_id);
create index quantification_relationship_idx2 on quantification_relationship (type_id);
create index quantification_relationship_idx3 on quantification_relationship (object_id);

COMMENT ON TABLE quantification_relationship IS 'there may be multiple rounds of quantification, this allows us to keep an audit trail of what values went where';

create table control (
    control_id serial not null,
	primary key (control_id),
    type_id int not null,
	foreign key (type_id) references cvterm (cvterm_id) on delete cascade,
    assay_id int not null,
	foreign key (assay_id) references assay (assay_id) on delete cascade,
    tableinfo_id int not null,
	foreign key (tableinfo_id) references tableinfo (tableinfo_id) on delete cascade,
    row_id int not null,
    name text null,
    value text null,
    rank int not null default 0
);
create index control_idx1 on control (type_id);
create index control_idx2 on control (assay_id);
create index control_idx3 on control (tableinfo_id);
create index control_idx4 on control (row_id);

COMMENT ON TABLE control IS NULL;

create table element (
    element_id serial not null,
	primary key (element_id),
    feature_id int null,
	foreign key (feature_id) references feature (feature_id) on delete set null,
    arraydesign_id int not null,
	foreign key (arraydesign_id) references arraydesign (arraydesign_id) on delete cascade,
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
create index element_idx1 on element (feature_id);
create index element_idx2 on element (arraydesign_id);
create index element_idx3 on element (type_id);
create index element_idx4 on element (dbxref_id);
create index element_idx5 on element (subclass_view);

COMMENT ON TABLE element IS 'represents a feature of the array.  this is typically a region of the array coated or bound to DNA';

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
    tinyint3 int null,
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
create index elementresult_idx1 on elementresult (element_id);
create index elementresult_idx2 on elementresult (quantification_id);
create index elementresult_idx3 on elementresult (subclass_view);
create unique index elementresult_idx4 on elementresult (element_id,quantification_id,subclass_view);

COMMENT ON TABLE elementresult IS 'an element on an array produces a measurement when hybridized to a biomaterial (traceable through quantification_id).  this is the "real" data from the microarray hybridization.  the fields of this table are intentionally generic so that many different platforms can be stored in a common table.  each platform should have a corresponding view onto this table, mapping specific parameters of the platform to generic columns';

create table elementresult_relationship (
    elementresult_relationship_id serial not null,
        primary key (elementresult_relationship_id),
    subject_id int not null,
        foreign key (subject_id) references elementresult (elementresult_id),
    type_id int not null,
        foreign key (type_id) references cvterm (cvterm_id),
    object_id int not null,
        foreign key (object_id) references elementresult (elementresult_id),
    value text null,
    rank int not null default 0,
    unique(subject_id,type_id,object_id,rank)
);
create index elementresult_relationship_idx1 on elementresult_relationship (subject_id);
create index elementresult_relationship_idx2 on elementresult_relationship (type_id);
create index elementresult_relationship_idx3 on elementresult_relationship (object_id);
create index elementresult_relationship_idx4 on elementresult_relationship (value);

COMMENT ON TABLE elementresult_relationship IS 'sometimes we want to combine measurements from multiple elements to get a composite value.  affy combines many probes to form a probeset measurement, for instance';

create table study (
    study_id serial not null,
	primary key (study_id),
    contact_id int not null,
	foreign key (contact_id) references contact (contact_id) on delete cascade,
    pub_id int null,
	foreign key (pub_id) references pub (pub_id) on delete set null,
    dbxref_id int null,
	foreign key (dbxref_id) references dbxref (dbxref_id) on delete set null,
    name text not null,
    description text null,
    unique(name)
);
create index study_idx1 on study (contact_id);
create index study_idx2 on study (pub_id);
create index study_idx3 on study (dbxref_id);

COMMENT ON TABLE study IS NULL;

create table study_assay (
    study_assay_id serial not null,
	primary key (study_assay_id),
    study_id int not null,
	foreign key (study_id) references study (study_id) on delete cascade,
    assay_id int not null,
	foreign key (assay_id) references assay (assay_id) on delete cascade,
    unique(study_id,assay_id)
);
create index study_assay_idx1 on study_assay (study_id);
create index study_assay_idx2 on study_assay (assay_id);

COMMENT ON TABLE study_assay IS NULL;

create table studydesign (
    studydesign_id serial not null,
	primary key (studydesign_id),
    study_id int not null,
	foreign key (study_id) references study (study_id) on delete cascade,
    description text null
);
create index studydesign_idx1 on studydesign (study_id);

COMMENT ON TABLE studydesign IS NULL;

create table studydesignprop (
    studydesignprop_id serial not null,
	primary key (studydesignprop_id),
    studydesign_id int not null,
	foreign key (studydesign_id) references studydesign (studydesign_id) on delete cascade,
    type_id int not null,
	foreign key (type_id) references cvterm (cvterm_id) on delete cascade,
    value text null,
    rank int not null default 0,
    unique(studydesign_id, type_id, rank)
);
create index studydesignprop_idx1 on studydesignprop (studydesign_id);
create index studydesignprop_idx2 on studydesignprop (type_id);

COMMENT ON TABLE studydesignprop IS NULL;

create table studyfactor (
    studyfactor_id serial not null,
	primary key (studyfactor_id),
    studydesign_id int not null,
	foreign key (studydesign_id) references studydesign (studydesign_id) on delete cascade,
    type_id int null,
	foreign key (type_id) references cvterm (cvterm_id) on delete set null,
    name text not null,
    description text null
);
create index studyfactor_idx1 on studyfactor (studydesign_id);
create index studyfactor_idx2 on studyfactor (type_id);

COMMENT ON TABLE studyfactor IS NULL;

create table studyfactorvalue (
    studyfactorvalue_id serial not null,
	primary key (studyfactorvalue_id),
    studyfactor_id int not null,
	foreign key (studyfactor_id) references studyfactor (studyfactor_id) on delete cascade,
    assay_id int not null,
	foreign key (assay_id) references assay (assay_id) on delete cascade,
    factorvalue text null,
    name text null,
    rank int not null default 0
);
create index studyfactorvalue_idx1 on studyfactorvalue (studyfactor_id);
create index studyfactorvalue_idx2 on studyfactorvalue (assay_id);

COMMENT ON TABLE studyfactorvalue IS NULL;
