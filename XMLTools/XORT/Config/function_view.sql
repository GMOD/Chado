create or replace view feature_evidence(feature_evidence_id, feature_id, evidence_id) as 
select anchor.feature_id||':'||evloc.feature_id, anchor.feature_id, evloc.feature_id
from featureloc anchor, featureloc evloc, analysisfeature af
where anchor.srcfeature_id=evloc.srcfeature_id 
and evloc.min>anchor.min 
and evloc.max<anchor.max 
and anchor.strand*evloc.strand>-1
and evloc.feature_id = af.feature_id;


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

