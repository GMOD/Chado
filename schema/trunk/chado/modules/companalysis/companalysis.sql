## $Id: companalysis.sql,v 1.8 2002-11-11 19:11:43 cwiel Exp $

# an analysis is a particular execution of a computational analysis;
# it may be a blast of one sequence against another, or an all by all
# blast, or a different kind of analysis altogether.
# it is a single unit of computation - if different blast runs
# were instantiated over differnet query sequences, there would
# be multiple entries here.
#
# the sequence that was used as the query sequence can be
# optionally included via queryfeature_id - even though this
# is redundant with the hitpair table below. this can still
# be useful - for instance, we may have an analysis that blasts
# contigs against a database. we may then transform those hits
# into global coordinates; it can still be useful to keep a record
# of which contig was blasted as the query.
#
# name: a way of grouping analyses. this should be a handy
# short identifier that can help people find an analysis they
# want. for instance "tRNAscan", "cDNA", "FlyPep", "SwissProt"
#
# program: e.g. blastx, blastp, sim4, genscan
# programversion: e.g. TBLASTX 2.0MP-WashU [09-Nov-2000]
# algorithm: eg blast
# sourcename: eg cDNA, SwissProt
#
# MAPPING (bioperl): maps to Bio::Search::Result::ResultI

create table analysis (
    analysis_id serial not null,
    primary key (analysis_id),
    name varchar(255),
    description text,
    program varchar(255) not null,
    programversion varchar(255) not null,
    algorithm varchar(255),
    sourcename varchar(255),
    sourceversion varchar(255),
    queryfeature_id int,
    foreign key (queryfeature_id) references feature (feature_id),

    timeentered timestamp not null default current_timestamp,
    timelastmod timestamp not null default current_timestamp
);

# analyses can have various properties attached - eg the parameters
# used in running a blast
create table analysisprop (
    analysis_id int not null,
    foreign key (analysis_id) references analysis (analysis_id),
    pkey_id int not null,
    foreign key (pkey_id) references cvterm (cvterm_id),
    pval text,

    timeentered timestamp not null default current_timestamp,
    timelastmod timestamp not null default current_timestamp
);

# An analysis result covers anything that comes out of an analysis,
# is scorable, and can be locatable on one or more features.
#
# analysisresults are different from features in that:
# - they may have multiple locations (eg in pairwise or multi alignments)
# - they are managed differently; they don't have stable accessions;
#   they aren't edited/curated, they are simply bulkloaded deleted or
#   replaced
# - they have scores as a fundamental defining property
#
# furthermore, storing analysisresults as features could
# risk overpopulating the feature table
#
# analysisresults are hierarchically composed - the parentresult_id
# points to another analysisresult.
# 
# most analyses produce two level hierarchies; for example,
# blast hits and blast HSPs. genscan genes and genscan exons.
# however, it is conceivable that there could be more than 2.
# for instance, gene finders that find alternate spliceforms.
# this table allows for an arbitrary number of levels in the
# compositional hierarchy.
#
# chado instantiations may have a policy that a max of 2 levels
# is allowed - this makes applications job of querying the database
# much simpler. alternate spliceforms could be represented as
# unconnected transcripts.
#
# results are also typed by a controlled vocabulary. this is assumed
# to be SO, although any feature type ontology would work. in the
# case of a prediction, the type would be the type of the feature
# predicted - gene, exon, UTR, tRNA, promoter, etc.
# in the case of an alignment, the type is determined by the sequence
# aligned. aligning cDNA sequence will have features of type 'transcript'
# and 'exon'. becuase this is an analysisresult and not a feature, there
# is no danger of confusing curated gene models with aligned gene features.
# what about aligning ESTs? the parent type would be something like
# 'transcript fragment' or even 'EST'??? Question for SO.
# for interpro analysis, the type would be a protein feature type,
# such as 'domain' (not the actual interpro structural class - this
# would be a cvterm attached to the interpro feature).
# what about blastp? i guess both parent and child features would be
# of type 'protein'
# 
# scores can be attached at any level in the hierarchy.
#
# scores:
# <see note>
create table analysisresult (
    analysisresult_id serial not null,
    primary key (analysisresult_id),
    analysis_id int not null,
    foreign key (analysis_id) references analysis (analysis_id),

    parentresult_id int,
    foreign key (parentresult_id) references analysisresult (analysisresult_id),
    type_id int,
    foreign key (type_id) references cvterm (cvterm_id),

    rawscore double precision,
    normscore double precision,
    significance double precision,

    timeentered timestamp not null default current_timestamp
);

# note: resultlocation does not have a primary key; this is fine
# as we don't want to attach any extra information to it.
#
# any analysisresult can have multiple locations.
#
# prediction type results (eg genscan) will only have ONE location
# (note that a prediction of a gene with multiple exons is stored as
#  multiple exon results plus one parent result)
#
# alignment / pairwise similarity data will have two locations, one
# on the query, one on the subject.
# (again - one blast hit with multiple HSPs is stored as one
#  analysisresult per HSP plus one for the hit)
#
# multiple alignments will have multiple locations
#
# the "rank" field is used to store the ordering of the locations
# across the different sequences the locations are on. for predictions,
# this will always be 0. We use 0 to mean the reference/query sequence
# in an analysis.
#
# in a pairwise result, the rank will be 0 or 1, depending on whether
# the location is for the query or subject portion of the HSP/Hit.
# (Note that this means the database is NON reference-genome-centric)
#
# in a multiple alignment, the rank will be 0 to n-1 sequences;
# there is no semantics to the rank, but presumably the order of
# sequences analysed should be preserved.
#
# please read the docs in the feature module on locations - the
# same applies here. interbase and (end - start) * strand >= 0.
#
# all locations are on a feature - we must instantiate a feature
# for any sequence aligned. this feature may be a sequence floating
# in space, or it may be localised, in which case it will have all
# the normal properties of a feature. this is a good thing, as
# we can attach all kinds of feature-like properties to the thing
# that is aligned.
#
# the alignment string can also be optionally stored; this can be
# used to reconstuct an actual residue to residue mapping
#
create table resultlocation (
       analysisresult_id int,
       foreign key (analysisresult_id) references analysisresult (analysisresult_id),
       fnbeg int,
       fnend int,
       strand smallint,
       source_feature_id int not null,
       foreign key (source_feature_id) references feature (feature_id),

       alignment text,

       rank int not null,

       unique (analysisresult_id, fnbeg, fnend, strand),
       unique (analysisresult_id, rank)
);




