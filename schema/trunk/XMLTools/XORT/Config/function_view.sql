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





create or replace view scaffold_feature (scaffold_feature_id, feature_id, type_id,  scaffold_id, arm_id) as 
select hit.feature_id||':'||scaffold.feature_id, hit.feature_id, hit.type_id, scaffold.feature_id, arm.feature_id
from featureloc scafl, featureloc hitloc, feature hit, feature scaffold, feature arm
where hit.feature_id=hitloc.feature_id and hitloc.min>scafl.min and hitloc.max<scafl.max and scafl.srcfeature_id=scaffold.feature_id and arm.feature_id=hitloc.srcfeature_id


create or replace view scaffold_feature (scaffold_feature_id, feature_id, type_id,  scaffold_id, arm_id) as 
select hitloc.feature_id||':'||scafl.feature_id, hitloc.feature_id, hit.type_id, scafl.feature_id, scafl.srcfeature_id
from featureloc scafl, featureloc hitloc, feature hit
where hitloc.min>scafl.min 
and hitloc.max<scafl.max 
and scafl.srcfeature_id=hitloc.srcfeature_id
and hit.feature_id = hitloc.feature_id;




select * from scaffold_feature where scaffold_id=2641585 and type_id=2 and arm_id=1


select fl.feature_id, fl2.featureloc_id, fl2.nbeg, fl2.nend, fl2.rank, fl2.srcfeature_id from feature f1, featureloc fl, featureloc fl2 where 
fl.srcfeature_id = 2641585 and fl.feature_id = fl2.feature_id and fl2.srcfeature_id = f1.feature_id and f1.type_id = 31;


select f1.feature_id, f1.uniquename from feature f1 where exists(select * from featureloc fl where fl.feature_id=f1.feature_id and fl.srcfeature_id=2 and fl.min>1 and fl.max <100 ) and f1.type_id=2;

create table feature_evidence (
   feature_evidence_id varchar(50) not null,
   primary key (feature_evidence_id), 
   feature_id int not null,
   foreign key (feature_id) references feature (feature_id),
   evidence_id int not null,
   foreign key (evidence_id) references feature (feature_id),
   unique (feature_id, evidence_id)
);



/* Stan's new version - april 22 */
create or replace view feature_evidence(feature_evidence_id, feature_id, evidence_id) as 
select anchor.feature_id||':'||evloc.feature_id, anchor.feature_id, evloc.feature_id
from featureloc anchor, featureloc evloc, analysisfeature af
where anchor.srcfeature_id=evloc.srcfeature_id 
and evloc.min>anchor.min 
and evloc.max<anchor.max 
and anchor.strand*evloc.strand>-1
and evloc.feature_id = af.feature_id;



select anchor.feature_id||':'||evloc.feature_id, anchor.feature_id, evloc.feature_id
from featureloc anchor, featureloc evloc, analysisfeature af
where anchor.srcfeature_id=evloc.srcfeature_id 
and evloc.min>anchor.min 
and evloc.max<anchor.max 
and anchor.strand*evloc.strand>-1
and evloc.feature_id = af.feature_id
and anchor.feature_id=110737
and evloc.feature_id=113407


here hsp.type_id should be: alignment_hit and alignment_hsp


create or replace view feature_evidence(feature_evidence_id, feature_id, featureloc_id, hit_id) as 
select anchor.featureloc_id||':'||hsploc.featureloc_id||':'||hitloc.featureloc_id||':'||hsp.feature_id, anchor.feature_id, hsploc.featureloc_id, hitloc.srcfeature_id
from featureloc anchor, featureloc hsploc, feature hsp, featureloc hitloc
where anchor.srcfeature_id=hsploc.srcfeature_id 
and hsploc.min>anchor.min 
and hsploc.max<anchor.max 
and hsploc.feature_id=hsp.feature_id 
and hsp.type_id in (13, 14) 
and anchor.strand*hsploc.strand>-1
and hitloc.feature_id = hsploc.feature_id
and hitloc.rank != hsploc.rank




select * 
from feature_evidence 
where feature_id=10 
and exists (select feature_evidence_0.feature_evidence_id from featureloc featureloc_0 , feature feature_0 where  feature_0.uniquename<>'X.3')



create table contained_in (
       featureloc_id serial not null,
       primary key (featureloc_id),
       feature_id int not null,
       foreign key (feature_id) references feature (feature_id),
       srcfeature_id int,
       foreign key (srcfeature_id) references feature (feature_id),
       nbeg int,
       is_nbeg_partial boolean not null default 'false',
       nend int,
       is_nend_partial boolean not null default 'false',
       strand smallint,
       phase int,
       residue_info text,
       locgroup int not null default 0,
       rank     int not null default 0,
       unique (feature_id, locgroup, rank)
);


drop function contained_in(integer, integer, integer);
create function contained_in(integer, integer, integer) returns setof featureloc as
'select *
from featureloc
where srcfeature_id = $1
and min >= $2
and max <= $3; '
language SQL;


select feature_0.timeaccessioned , feature_0.name , feature_0.timelastmodified , feature_0.residues , feature_0.dbxref_id , feature_0.feature_id , feature_0.uniquename , feature_0.seqlen , feature_0.md5checksum , feature_0.organism_id , feature_0.type_id from feature feature_0 where  exists (select * from contained_in(6, 25786, 1130546) contained_in_0 , feature feature_1 where  feature_1.uniquename='X.3' and contained_in_0.srcfeature_id=feature_1.feature_id and feature_0.feature_id=contained_in_0.feature_id)




select c.srcfeature_id, c.max from contained_in(6, 19657747, 19664554) c, feature f where f.uniquename='CG9565' and f.feature_id=c.feature_id



/* neighborhood( srcfeature_id, feature_id, marginwidth ) => setof featureloc */
create function neighborhood(integer, integer, integer) returns setof featureloc as
'select 
from featureloc loc, featureloc anchor
where anchor.srcfeature_id = $1
and anchor.feature_id = $2
and loc.srcfeature_id = $1
and loc.min >= anchor.nbeg - $3
and loc.max <= anchor.nend + $3; '
language SQL;





select f1.feature_id from feature f1 where exists( select * from featureloc fl where fl.feature_id=f1.feature_id and fl.min>   and fl.max< )







<chado>
   <_appdata name="title">$4</_appdata>
   <_appdata name="arm">$1</_appdata>
   <_appdata name="min">$2</_appdata>
   <_appdata name="max">$3</_appdata>
   <_appdata name="residues"><sql>select substr(residues, $2, $3-$2+1) from feature where feature_id=$1</sql></_appdata>
   <feature>
       <type_id test="yes"> {gene cvterm id} </type_id>
       <featureloc test="yes">
           <srcfeature_id>$1</srcfeature_id>
           <min test="gt">$2</min>
           <max test="lt">$3</max>
       </featureloc>
       { insert central dogma dumpspec }
  </feature>
   <feature>
       <type_id test="no"> {gene cvterm id} </type_id>
       <featureloc test="yes">
           <srcfeature_id>$1</srcfeature_id>
           <min test="gt">$2</min>
           <max test="lt">$3</max>
       </featureloc>
       { insert noncentral dogma dumpspec }
  </feature>
</chado>


----------------------------------

<chado dumpspec="scaffold_dumpspec.xml" date="Tue Apr 22 12:45:36 EDT 2003">
   <_appdata name="arm">12345</_appdata>
   <_appdata name="min">175</_appdata>
   <_appdata name="max">250</_appdata>
   <_appdata name="residues">AATGCGTATATGA...</_appdata>
   <feature>
	...
  </feature>
   <feature>
	...
  </feature>
   <feature>
	...
  </feature>
</chado>



# here to add min max to featureloc
alter table featureloc add column min int;
alter table featureloc add column max int;
update featureloc set min=nbeg where strand=1;
update featureloc set max=nend where strand=1;
update featureloc set max=nbeg where strand=-1;
update featureloc set min=nend where strand=-1;
update featureloc set min=nbeg where (strand=0 or strand is null) and
nbeg<nend;
update featureloc set max=nend where (strand=0 or strand is null) and
nbeg<nend;
update featureloc set min=nend where (strand=0 or strand is null) and
nbeg>nend;
update featureloc set max=nbeg where (strand=0 or strand is null) and
nbeg>nend;
create index featureloc_src_min_max on featureloc
(srcfeature_id,min,max);
select count(*) from featureloc where min is null and nbeg is not null;




select prodfunction_text,root_PubObject_id_pubobj,id_pub, GeneData.date_updated date_updated 
from GeneData,Report_d where root_PubObject_id_pubobj like "gn%" and node_PubObject_id_pubobj
 like "gd%" and PubObject_id_pubobj = node_PubObject_id_pubobj and convert(varchar(255),prodfunction_text)
 is not null and id_pub=105495