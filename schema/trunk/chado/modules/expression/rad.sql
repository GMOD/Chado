--changed some of the pk/fk names to conform to chado conventions (removed _)
--changed field names (removed _s)
--changed some tablenames by adding _ to link tables, dropping _ where no link.
--dropped trailing '-imp' off some tablenames
--dropped external_database_release_id fields
--mapped contact links to author table
--mapped bibliographic references to pub table
--source_id changed to dbxref_id

--ok
--drop table acquisition;
create table acquisition (
    acquisition_id           																				serial not null,
	primary key (acquisition_id),
    assay_id                 																				int not null,
	foreign key (assay_id) references  assay (assay_id),
    protocol_id              																				int null,
	foreign key (protocol_id) references protocol (protocol_id),
    channel_id               																				int null,
	foreign key (channel_id) references channel (channel_id),
    acquisitiondate          																				date null,
    name                     																				varchar(100) null,
    uri                      																				varchar(255) null
);

--ok
--drop table if exists acquisitionparam;
create table acquisitionparam (
    acquisitionparam_id      																				serial not null,
	primary key (acquisitionparam_id),
    acquisition_id           																				int not null,
	foreign key (acquisition_id) references acquisition (acquisition_id),
    name                     																				varchar(100) not null,
    value                    																				varchar(50) not null
);

--ok
--drop table if exists analysis;
create table analysis (
    analysis_id              																				serial not null,
	primary key (analysis_id),
    name                     																				varchar(100) not null,
    description              																				varchar(500) null
);

--ok
--drop table if exists analysisimplementation;
create table analysisimplementation (
    analysisimplementation_id          																		serial not null,
	primary key (analysisimplementation_id),
    analysis_id                        																		int not null,
	foreign key (analysis_id) references analysis (analysis_id),
    name                               																		varchar(100) not null,
    description  																		         			varchar(500) null
);

--ok
--drop table if exists analysisimplementationparam;
create table analysisimplementationparam (
    analysisimplementationparam_id     																		serial not null,
	primary key (analysisimplementationparam_id),
    analysisimplementation_id          																		int not null,
	foreign key (analysisimplementation_id) references analysisimplementation (analysisimplementation_id),
    name                               																		varchar(100) not null,
    value                              																		varchar(100) not null
);

--ok
--drop table if exists analysisinput;
create table analysisinput (
    analysisinput_id         																				serial not null,
	primary key (analysisinput_id),
    analysisinvocation_id    																				int not null,
	foreign key (analysisinvocation_id) references analysisinvocation (analysisinvocation_id),
    tableinfo_id                 																			int null,
	foreign key (tableinfo_id) references tableinfo (tableinfo_id),
    inputrow_id             																				int null,
    inputvalue              																				varchar(50) null
);

--ok
--drop table if exists analysisinvocation;
create table analysisinvocation (
    analysisinvocation_id              																		serial not null,
	primary key (analysisinvocation_id),
    analysisimplementation_id          																		int not null,
	foreign key (analysisimplementation_id) references analysisimplementation (analysisimplementation_id),
    name                               																		varchar(100) not null,
    description                        																		varchar(500) null
);

--ok
--drop table if exists analysisinvocationparam;
create table analysisinvocationparam (
    analysisinvocationparam_id         																		serial not null,
	primary key (analysisinvocationparam_id),
    analysisinvocation_id              																		int not null,
	foreign key (analysisinvocation_id) references analysisinvocation (analysisinvocation_id),
    name                               																		varchar(100) not null,
    value                            																		varchar(100) not null
);

--ok
--drop table if exists analysisoutput;
create table analysisoutput (
    analysisoutput_id       																				serial not null,
	primary key (analysisoutput_id),
    analysisinvocation_id   																				int not null,
	foreign key (analysisinvocation_id) references analysisinvocation (analysisinvocation_id),
    name                    																				varchar(100) not null,
    type                    																				varchar(50) not null,
    value                   																				int not null
);

--ok
--drop table if exists array;
create table array (
    array_id                           																		serial not null,
	primary key (array_id),
    manufacturer_id                    																		int not null,
	foreign key (manufacturer_id) references author (author_id),
    platformtype_id                   																		int not null,
	foreign key (platformtype_id) references cvterm (cvterm_id),
    substrate_type_id                  																		int null,
	foreign key (substrate_type_id) references cvterm (cvterm_id),
    protocol_id                        																		int null,
	foreign key (protocol_id) references protocol (protocol_id),
    dbxref_id                          																		int null,
	foreign key (dbxref_id) references dbxref (dbxref_id),
    name                               																		varchar(100) not null,
    version                            																		varchar(50)  null,
    description                        																		varchar(500) null,
    array_dimensions                   																		varchar(50) null,
    element_dimensions                 																		varchar(50) null,
    number_of_elements                 																		int null,
    num_array_columns                  																		int null,
    num_array_rows                     																		int null,
    num_grid_columns                   																		int null,
    num_grid_rows                      																		int null,
    num_sub_columns                    																		int null,
    num_sub_rows                       																		int null
);

--ok
--drop table if exists arrayannotation;
create table arrayannotation (
    arrayannotation_id      																				int not null,
	primary key (arrayannotation_id),
    array_id                																				int not null,
	foreign key (array_id) references array (array_id),
    name                    																				varchar(500) not null,
    value                   																				varchar(100) not null
);

--ok
--drop table if exists assay;
create table assay (
    assay_id                           																		serial not null,
	primary key (assay_id),
    array_id                         																		int not null,
	foreign key (array_id) references array (array_id),
    protocol_id                        																		int null,
	foreign key (protocol_id) references protocol (protocol_id),
    assaydate                         																		date null,
    arrayidentifier                   																		varchar(100) null,
    arraybatchidentifier             																		varchar(100) null,
    operator_id                        																		int not null,
	foreign key (operator_id) references author (author_id),
    dbxref_id                          																		int null,
	foreign key (dbxref_id) references dbxref (dbxref_id),
    name                               																		varchar(100) null,
    description                        																		varchar(500) null
);

--ok
--drop table if exists assay_biomaterial;
create table assay_biomaterial (
    assay_biomaterial_id    																				serial not null,
	primary key (assay_biomaterial_id),
    assay_id                 																				int not null,
	foreign key (assay_id) references assay (assay_id),
    biomaterial_id          																				int not null,
	foreign key (biomaterial_id) references biomaterial (biomaterial_id)
);

--ok
--drop table if exists assay_labeledextract;
create table assay_labeledextract (
    assay_labeledextract_id 																				serial not null,
	primary key (assay_labeledextract_id),
    assay_id                																				int not null,
	foreign key (assay_id) references assay (assay_id),
    labeledextract_id       																				int not null,
	foreign key (labeledextract_id) references biomaterial (biomaterial_id),
    channel_id              																				int not null,
	foreign key (channel_id) references channel (channel_id)
);

--ok
--renamed biomaterialcharacteristic to biomaterial_cvterm
--drop table if exists biomaterial_cvterm;
create table biomaterial_cvterm (
    biomaterial_cvterm_id     																				serial not null,
	primary key (biomaterial_cvterm_id),
    biomaterial_id            																				int not null,
	foreign key (biomaterial_id) references biomaterial (biomaterial_id),
    cvterm_id                 																				int not null,
	foreign key (cvterm_id) references cvterm (cvterm_id),
    value                     																				varchar(100) null
);

--ok
--renamed from biomaterialimp
--drop table if exists biomaterial;
create table biomaterial (
    biomaterial_id                   																		serial not null,
	primary key (biomaterial_id),
    labelmethod_id                  																		int null,
	foreign key (labelmethod_id) references labelmethod (labelmethod_id),
    taxon_id                         																		int null,
	foreign key (taxon_id) references organism (organism_id),
    biosourceprovider_id             																		int null,
	foreign key (biosourceprovider_id) references author (author_id),
    subclass_view                    																		varchar(27) not null,
    dbxref_id                        																		varchar(50) null,
	foreign key (dbxref_id) references dbxref (dbxref_id),
    string1                          																		varchar(100) null,
    string2                          																		varchar(500) null
);

--ok
--drop table if exists biomaterialmeasurement;
create table biomaterialmeasurement (
    biomaterialmeasurement_id        																		serial not null,
	primary key (biomaterialmeasurement_id),
    treatment_id                     																		int not null,
	foreign key (treatment_id) references treatment (treatment_id),
    biomaterial_id                   																		int not null,
	foreign key (biomaterial_id) references biomaterial (biomaterial_id),
    value                            																		float(15) null,
    unittype_id                     																		int null,
	foreign key (unittype_id) references cvterm (cvterm_id)
);

--ok
--drop table if exists channel;
create table channel (
    channel_id               																				serial not null,
	primary key (channel_id),
    name                     																				varchar(100) not null,
    definition               																				varchar(500) not null
);

--dropped compositeelementannotation.  use featureprop instead.
--dropped compositeelementgus.         use feature instead.
--dropped compositeelement.            use feature instead.

--ok
--drop table if exists compositeelementresult;
create table compositeelementresult (
    compositeelementresult_id          																		serial not null,
	primary key (compositeelementresult_id),
    compositeelement_id                																		int not null,
	foreign key (compositeelement_id) references feature (feature_id),
    quantification_id                  																		int not null,
	foreign key (quantification_id) references quantification (quantification_id),
    subclass_view                      																		varchar(27) not null,
    float1                             																		float(15) null,
    float2                             																		float(15) null,
    float3                             																		float(15) null,
    float4                             																		float(15) null,
    int1                               																		int null,
    smallint1                          																		int null,
    smallint2                          																		int null,
    smallint3                          																		int null,
    tinyint1                           																		int null,
    tinyint2                           																		int null,
    tinyint3                           																		int null,
    char1                              																		varchar(5) null,
    char2                              																		varchar(5) null,
    char3                              																		varchar(5) null,
    string1                            																		varchar(500) null,
    string2                            																		varchar(500) null
);

--ok
--drop table if exists control;
create table control (
    control_id               																				serial not null,
	primary key (control_id),
    controltype_id          																				int not null,
	foreign key (controltype_id) references cvterm (cvterm_id),
    assay_id                 																				int not null,
	foreign key (assay_id) references assay (assay_id),
    tableinfo_id                 																			int not null,
	foreign key (tableinfo_id) references tableinfo (tableinfo_id),
    row_id                   																				int not null,
    name                     																				varchar(100) null,
    value                    																				varchar(255) null
);

--dropped elementannotation.  use featureprop instead.

--ok
--drop table if exists element;
create table element (
    element_id                         																		serial not null,
	primary key (element_id),
    feature_id           		     																		int null,
	foreign key (feature_id) references feature (feature_id),
    array_id                           																		int not null,
	foreign key (array_id) references array (array_id),
    element_type_id                    																		int null,
	foreign key (element_type_id) references cvterm (cvterm_id),
    dbxref_id                          																		int null,
	foreign key (dbxref_id) references dbxref (dbxref_id),
    subclass_view                      																		varchar(27) not null,
    tinyint1                           																		int null,
    smallint1                          																		int null,
    char1                              																		varchar(5) null,
    char2                              																		varchar(5) null,
    char3                              																		varchar(5) null,
    char4                              																		varchar(5) null,
    char5                              																		varchar(5) null,
    char6                              																		varchar(5) null,
    char7                              																		varchar(5) null,
    tinystring1                        																		varchar(50) null,
    tinystring2                        																		varchar(50) null,
    smallstring1                       																		varchar(100) null,
    smallstring2                       																		varchar(100) null,
    string1                            																		varchar(500) null,
    string2                            																		varchar(500) null
);

--ok
--drop table if exists elementresult;
create table elementresult (
    elementresult_id                   																		serial not null,
	primary key (elementresult_id),
    element_id                         																		int not null,
	foreign key (element_id) references element (element_id),
    compositeelementresult_id          																		int null,
	foreign key (compositeelementresult_id) references compositeelementresult (compositeelementresult_id),
    quantification_id                  																		int not null,
	foreign key (quantification_id) references quantification (quantification_id),
    subclass_view                      																		varchar(27) not null,
    foreground                         																		float(15) null,
    background                         																		float(15) null,
    foreground_sd                      																		float(15) null,
    background_sd                      																		float(15) null,
    float1                             																		float(15) null,
    float2                             																		float(15) null,
    float3                             																		float(15) null,
    float4                             																		float(15) null,
    float5                             																		float(15) null,
    float6                             																		float(15) null,
    float7                             																		float(15) null,
    float8                             																		float(15) null,
    float9                             																		float(15) null,
    float10                            																		float(15) null,
    float11                            																		float(15) null,
    float12                            																		float(15) null,
    float13                            																		float(15) null,
    float14                            																		float(15) null,
    int1                               																		int null,
    int2                               																		int null,
    int3                               																		int null,
    int4                               																		int null,
    int5                               																		int null,
    int6                               																		int null,
    int7                               																		int null,
    int8                              																		int null,
    int9                               																		int null,
    int10                              																		int null,
    int11                              																		int null,
    int12                              																		int null,
    int13                              																		int null,
    int14                              																		int null,
    int15                              																		int null,
    tinyint1                           																		int null,
    tinyint2                           																		int null,
    tinyint3                           																		int null,
    smallint1                          																		int null,
    smallint2                          																		int null,
    smallint3                          																		int null,
    char1                              																		varchar(5) null,
    char2                              																		varchar(5) null,
    char3                              																		varchar(5) null,
    char4                              																		varchar(5) null,
    tinystring1                        																		varchar(50) null,
    tinystring2                        																		varchar(50) null,
    tinystring3                        																		varchar(50) null,
    smallstring1                       																		varchar(100) null,
    smallstring2                       																		varchar(100) null,
    string1                            																		varchar(500) null,
    string2                            																		varchar(500) null
);

--ok
--drop table if exists labelmethod;
create table labelmethod (
    labelmethod_id           																				serial not null,
	primary key (labelmethod_id),
    protocol_id              																				int not null,
	foreign key (protocol_id) references protocol (protocol_id),
    channel_id               																				int not null,
	foreign key (channel_id) references channel (channel_id),
    labelused               																				varchar(50) null,
    labelmethod             																				varchar(1000) null
);

--ok
--drop table if exists magedocumentation;
create table magedocumentation (
    magedocumentation_id     																				serial not null,
	primary key (magedocumentation_id),
    mageml_id                																				int not null,
	foreign key (mageml_id) references mageml (mageml_id),
    tableinfo_id                 																			int not null,
	foreign key (tableinfo_id) references tableinfo (tableinfo_id),
    row_id                   																				int not null,
    mageidentifier          																				varchar(100) not null
);

--ok
-- warning - mage_ml does not appear in core.tableinfo
--drop table if exists mageml;
create table mageml (
    mageml_id                																				serial not null,
	primary key (mageml_id),
    mage_package             																				varchar(100) not null,
    mage_ml                  																				varchar not null
);

--ok
--drop table if exists processimplementation;
create table processimplementation (
    processimplementation_id           																		serial not null,
	primary key (processimplementation_id),
    processtype_id                    																		int not null,
	foreign key (processtype_id) references cvterm (cvterm_id),
    name                               																		varchar(100) null
);

--ok
--drop table if exists processimplementationparam;
create table processimplementationparam (
    processimplementationparam_id       																		serial not null,
	primary key (processimplementationparam_id),
    processimplementation_id           																		int not null,
	foreign key (processimplementation_id) references processimplementation (processimplementation_id),
    name                               																		varchar(100) not null,
    value                              																		varchar(100) not null
);

--ok
--drop table if exists processinvocation;
create table processinvocation (
    processinvocation_id              																		serial not null,
	primary key (processinvocation_id),
    processimplementation_id          																		int not null,
	foreign key (processimplementation_id) references processimplementation (processimplementation_id),
    processinvocationdate             																		date not null,
    description                        																		varchar(500) null
);

--ok
--drop table if exists processinvocationparam;
create table processinvocationparam (
    processinvocationparam_id          																		serial not null,
	primary key (processinvocationparam_id),
    processinvocation_id               																		int not null,
	foreign key (processinvocation_id) references processinvocation (processinvocation_id),
    name                               																		varchar(100) not null,
    value                              																		varchar(100) not null
);

--ok
--renamed from processinv_quantification to processinvocation_quantification
--drop table if exists processinvocation_quantification;
create table processinvocation_quantification (
    processinvocation_quantification_id      																serial not null,
	primary key (processinvocation_quantification_id),
    processinvocation_id                     																int not null,
	foreign key (processinvocation_id) references processinvocation (processinvocation_id),
    quantification_id                        																int not null,
	foreign key (quantification_id) references quantification (quantification_id)
);

--ok
--drop table if exists processio;
create table processio (
    processio_id             																				serial not null,
	primary key (processio_id),
    processinvocation_id     																				int not null,
	foreign key (processinvocation_id) references processinvocation (processinvocation_id),
    inputtable_id                 																			int not null,
	foreign key (inputtable_id) references tableinfo (tableinfo_id),
    inputrow_id          																					int not null,
    input_role               																				varchar(50) null,
    outputrow_id         																					int not null,
	foreign key (outputrow_id) references processresult (processresult_id)
);

--ok
--drop table if exists processresult;
create table processresult (
    processresult_id         																				serial not null,
	primary key (processresult_id),
    value                   																				float(15) not null,
    unittype_id             																				int null,
	foreign key (unittype_id) references cvterm (cvterm_id)
);

--ok
--drop table if exists projectlink;
create table projectlink (
    projectlink_id           																				serial not null,
	primary key (projectlink_id),
    projectinfo_id               																			int not null,
	foreign key (projectinfo_id) references projectinfo (projectinfo_id),
    tableinfo_id                 																			int not null,
	foreign key (tableinfo_id) references tableinfo (tableinfo_id),
    id                       																				int not null,
    currentversion          																				varchar(4) null
);

--ok
--drop table if exists protocol;
create table protocol (
    protocol_id                        																		serial not null,
	primary key (protocol_id),
    protocol_type_id                   																		int not null,
	foreign key (protocol_type_id) references cvterm (cvterm_id),
    pub_id         																							int null,
	foreign key (pub_id) references pub (pub_id),
    dbxref_id                          																		int null,
	foreign key (dbxref_id) references dbxref (dbxref_id),
    name                               																		varchar(100) not null,
    uri                                																		varchar(100) null,
    protocoldescription               																		varchar(4000) null,
    hardwaredescription               																		varchar(500) null,
    softwaredescription               																		varchar(500) null
);

--ok
--drop table if exists protocolparam;
create table protocolparam (
    protocolparam_id         																				serial not null,
	primary key (protocolparam_id),
    protocol_id              																				int not null,
	foreign key (protocol_id) references protocol (protocol_id),
    name                     																				varchar(100) not null,
    datatype_id             																				int null,
	foreign key (datatype_id) references cvterm (cvterm_id),
    unittype_id             																				int null,
	foreign key (unittype_id) references cvterm (cvterm_id),
    value                    																				varchar(100) null
);

--ok
--drop table if exists quantification;
create table quantification (
    quantification_id        																				serial not null,
	primary key (quantification_id),
    acquisition_id           																				int not null,
	foreign key (acquisition_id) references acquisition (acquisition_id),
    operator_id              																				int null,
	foreign key (operator_id) references author (author_id),
    protocol_id              																				int null,
	foreign key (protocol_id) references protocol (protocol_id),
    resulttable_id          																				int null,
	foreign key (resulttable_id) references tableinfo (tableinfo_id),
    quantificationdate       																				date null,
    name                     																				varchar(100) null,
    uri                      																				varchar(500) null
);

--ok
--drop table if exists quantificationparam;
create table quantificationparam (
    quantificationparam_id   																				serial not null,
	primary key (quantificationparam_id),
    quantification_id        																				int not null,
	foreign key (quantification_id) references quantification (quantification_id),
    name                     																				varchar(100) not null,
    value                    																				varchar(50) not null
);

--ok
--drop table if exists relatedacquisition;
create table relatedacquisition (
    relatedacquisition_id              																		serial not null,
	primary key (relatedacquisition_id),
    acquisition_id                     																		int not null,
	foreign key (acquisition_id) references acquisition (acquisition_id),
    associatedacquisition_id          																		int not null,
	foreign key (associatedacquisition_id) references acquisition (acquisition_id),
    name                               																		varchar(100) null,
    designation                        																		varchar(50) null,
    associateddesignation             																		varchar(50) null
);

--ok
--drop table if exists relatedquantification;
create table relatedquantification (
    relatedquantification_id           																		serial not null,
	primary key (relatedquantification_id),
    quantification_id                  																		int not null,
	foreign key (quantification_id) references quantification (quantification_id),
    associatedquantification_id       																		int not null,
	foreign key (associatedquantification_id) references quantification (quantification_id),
    name                               																		varchar(100) null,
    designation                        																		varchar(50) null,
    associateddesignation             																		varchar(50) null
);

--ok
--drop table if exists study;
create table study (
    study_id                           																		serial not null,
	primary key (study_id),
    contact_id                         																		int not null,
	foreign key (contact_id) references author (author_id),
   	pub_id         																							int null,
	foreign key (pub_id) references pub (pub_id),
    dbxref_id                          																		int null,
	foreign key (dbxref_id) references dbxref (dbxref_id),
    name                               																		varchar(100) not null,
    description                        																		varchar(4000) null
);

--ok
--renamed from studyassay to study_assay
--drop table if exists study_assay;
create table study_assay (
    study_assay_id           																				serial not null,
	primary key (study_assay_id),
    study_id                 																				int not null,
	foreign key (study_id) references study (study_id),
    assay_id                 																				int not null,
	foreign key (assay_id) references assay (assay_id)
);

--ok
--drop table if exists studydesign;
create table studydesign (
    studydesign_id           																				serial not null,
	primary key (studydesign_id),
    study_id                 																				int not null,
	foreign key (study_id) references study (study_id),
    studydesigntype_id     																					int  null,
	foreign key (studydesigntype_id) references cvterm (cvterm_id),
    description              																				varchar(4000) null
);

--ok
--renamed from studydesignassay to studydesign_assay
--drop table if exists studydesign_assay;
create table studydesign_assay (
    studydesign_assay_id    																				serial not null,
	primary key (studydesign_assay_id),
    studydesign_id          																				int not null,
	foreign key (studydesign_id) references studydesign (studydesign_id),
    assay_id                																				int not null,
	foreign key (assay_id) references assay (assay_id)
);

--ok
--drop table if exists studydesigndescription;
create table studydesigndescription (
    studydesigndescription_id         																		serial not null,
	primary key (studydesigndescription_id),
    studydesign_id                     																		int not null,
	foreign key (studydesign_id) references studydesign (studydesign_id),
    descriptiontype_id                 																		int not null,
	foreign key (descriptiontype_id) references cvterm (cvterm_id),
    description                        																		varchar(4000) not null
);

--ok
--drop table if exists studyfactor;
create table studyfactor (
    studyfactor_id          																				serial not null,
	primary key (studyfactor_id),
    studydesign_id          																				int not null,
	foreign key (studydesign_id) references studydesign (studydesign_id),
    studyfactortype_id     																					int null,
	foreign key (studyfactortype_id) references cvterm (cvterm_id),
    name                     																				varchar(100) not null,
    description              																				varchar(500) null
);

--ok
--drop table if exists studyfactorvalue;
create table studyfactorvalue (
    studyfactorvalue_id      																				serial not null,
	primary key (studyfactorvalue_id),
    studyfactor_id           																				int not null,
	foreign key (studyfactor_id) references studyfactor (studyfactor_id),
    assay_id                 																				int not null,
	foreign key (assay_id) references assay (assay_id),
    factorvalue             																				varchar(100) not null,
    name                     																				varchar(100) null
);

--ok
--drop table if exists treatment;
create table treatment (
    treatment_id             																				serial not null,
	primary key (treatment_id),
    ordernum                																				int not null,
    biomaterial_id           																				int not null,
	foreign key (biomaterial_id) references biomaterial (biomaterial_id),
    treatmenttype_id        																				int not null,
	foreign key (treatmenttype_id) references cvterm (cvterm_id),
    protocol_id              																				int null,
	foreign key (protocol_id) references protocol (protocol_id),
    name                     																				varchar(100) null
);