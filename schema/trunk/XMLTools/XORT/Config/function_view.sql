create or replace view alignment_evidence(alignment_evidence_id, feature_id, evidence_id, analysis_id) as 
select  anchor.feature_id||':'||fr.object_id||':'||af.analysis_id,   anchor.feature_id, fr.object_id, af.analysis_id
from featureloc anchor, analysisfeature af, feature_relationship fr, featureloc hsploc
where anchor.srcfeature_id=hsploc.srcfeature_id 
and hsploc.feature_id = af.feature_id
and hsploc.feature_id=fr.subject_id
and ((hsploc.fmin>=anchor.fmin and hsploc.fmax<=anchor.fmax) or (hsploc.fmin<=anchor.fmin and hsploc.fmax>=anchor.fmax)  or (hsploc.fmin<=anchor.fmax and hsploc.fmax>=anchor.fmax) or (hsploc.fmin<=anchor.fmin and hsploc.fmax>=anchor.fmin))
group by anchor.feature_id, fr.object_id, af.analysis_id
;


create or replace view prediction_evidence(prediction_evidence_id, feature_id, evidence_id, analysis_id) as 
select anchor.feature_id||':'||evloc.feature_id||':'||af.analysis_id, anchor.feature_id, evloc.feature_id, af.analysis_id
from featureloc anchor, featureloc evloc, analysisfeature af
where anchor.srcfeature_id=evloc.srcfeature_id 
and evloc.feature_id = af.feature_id 
and ((evloc.fmin>=anchor.fmin and evloc.fmax<=anchor.fmax) or (evloc.fmin<=anchor.fmin and evloc.fmax>=anchor.fmax)  or (evloc.fmin<=anchor.fmax and evloc.fmax>=anchor.fmax) or (evloc.fmin<=anchor.fmin and evloc.fmax>=anchor.fmin));