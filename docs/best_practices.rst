Chado Best Practices
==============

Chado is a generic `schema <http://gmod.org/wiki/Glossary#Database_Schema>`_, which means anyone writing software to query or write to chado (either `middleware <http://gmod.org/wiki/GMOD_Middleware>`_ or applications) should be aware of the different ways in which data can be  stored. We want to strike a nice balance between ﬂexibility and extensibility on the one hand, and strong typing and rigor on the other. We want to avoid the situation we have with GenBank entries where there are a dozen ways of representing a gene model, but we need to be able to cope with the constant surprises biology throws at us in an attempt to confound our nice computable models. This page on Best Practices represents the collective wisdom of those who use
Chado on a daily basis and are also familiar with its theoretical underpinnings.

See also:

*  `Chado Sequence Module <http://gmod.org/wiki/Chado_Sequence_Module>`_ - description of many of the terms used here
*  `Introduction to Chado <http://gmod.org/wiki/Introduction_to_Chado>`_ - useful visualizations of some of the models described here
*  `IGS Data Representation <http://gmod.org/wiki/IGS_Data_Representation>`_ - further discussion on these conventions and how they were implemented at IGS (for comparison)

.. contents:: Contents
   :local:
   :depth: 2

=====================
Canonical Gene Models
=====================

The `central dogma <https://en.wikipedia.org/wiki/Central_dogma_of_molecular_biology>`_ model states that "gene makes mRNA makes polypeptide" - for many people using Chado this may be the only data model that's relevant. This typical protein-coding gene model consists of one gene, one or more mRNAs, one or more exons, and at least one polypeptide.

Alternately spliced genes have a 1-to-many relation between gene and mRNA. Exons can be part_of more than one mRNA. No two distinct exon rows should have exact same `featureloc <http://gmod.org/wiki/Chado_Best_Practices#Table:_featureloc>`_ coordinates (this would indicate they are the same exon).

Every feature must have a featureloc with rank=0 and locgroup=0. The value of the srcfeature_id column should be identical (i.e. all features are located relative to the same feature), except in rare circumstances such as when a feature crosses two contigs (software is not guaranteed to support this). The srcfeature_id can point to a `contig <http://www.sequenceontology.org/browser/current_release/term/SO:0000149>`_, a `chromosome <http://www.sequenceontology.org/browser/current_release/term/SO:0000340>`_, `chromosome_arm <http://www.sequenceontology.org/browser/current_release/term/SO:0000105>`_ or other appropriate assembly unit.

This scenario involves rows in the following tables:

.. list-table::
   :header-rows: 1

   * - Table
     - type_id
     - Number
     - Comments
   * - feature
     - `SO:Gene <http://www.sequenceontology.org/browser/current_release/term/SO:0000704>`_
     - 1
     - The gene must always be provided
   * - feature
     - `SO:mRNA <http://www.sequenceontology.org/browser/current_release/term/SO:0000234>`_
     - 1 or more
     - One or more transcripts are required, and these are always of type `SO:mRNA <http://www.sequenceontology.org/browser/current_release/term/SO:0000234>`_ for protein-coding genes.
   * - feature
     - `SO:exon <http://www.sequenceontology.org/browser/current_release/term/SO:0000147>`_
     - 1 or more
     - Exons are always required, even if the genome under consideration has no introns.
   * - feature
     - `polypeptide <http://www.sequenceontology.org/browser/current_release/term/SO:0000104>`_
     - at least 1
     - A protein-coding gene always produces a polypeptide, by definition. The polypeptide is located relative to the same genomic feature as the exons, mRNAs and gene. A single featureloc is used, with fmin and fmax indicating the start and stop codon positions (location is inclusive of stop codon). The polypeptide sequence should be specified as an amino acid sequence.

Querying for Canonical Genes
----------------------------

Sample query: retrieve a gene, "Dredd", along with its transcripts, proteins and exons. Since this is a "canonical gene" we can assume that its `feature graph <http://gmod.org/wiki/Introduction_to_Chado#Feature_Graphs>`_ has 3 levels. If we follow this assumption:

.. code-block:: sql

 SELECT * FROM feature AS gene
     INNER JOIN
   feature_relationship AS feat0 ON (gene.feature_id = feat0.object_id)
     INNER JOIN
   feature AS subfeat1 ON (subfeat1.feature_id = feat0.subject_id)
     INNER JOIN
   feature_relationship AS feat1 ON (subfeat1.feature_id = feat1.object_id)
     INNER JOIN
   feature AS subfeat2 ON (subfeat2.feature_id = feat1.subject_id)
 WHERE
   gene.name = 'Dredd';

This query should fetch a 3-deep graph rooted at "Dredd".

Application support for canonical genes
```````````````````````````````````````

*  Supported by `Apollo <http://genomearchitect.github.io/>`_
*  Supported by `GBrowse <http://gmod.org/wiki/GBrowse>`_

====================
Feature Localization
====================

All features with sequence annotation should be localized using featureloc.

Localized features must have a featureloc with rank=0 and locgroup=0. This is the primary location of the feature. The location always indicates the boundaries of the feature. If the feature is composed of distinct subfeatures (e.g. a transcript composes of exons), then it is **not** permitted to use multiple featurelocs to indicate this. Instead, there must be rows for the subfeatures, each with their own featureloc.

In a feature graph (i.e. a group of features connected via feature_relationship rows), all features will typically be localized relative to the same source feature (i.e. they will all have the same value for featureloc.srcfeature_id).

Features are typically localized to some kind of genomic or assembly feature, but chado does not constrain you to using only this. For example, localizing features relative to a transcript or polypeptide or even exon is permitted, but unusual practices will most likely not be recognized by most software.

Feature Localization to Contigs in Assembly
-------------------------------------------

In an assembled genome, it is common to locate relative to the top-level assembly units (e.g. chromosomes). However, it is also permissible to locate to smaller units such as `contigs <http://www.sequenceontology.org/browser/current_svn/term/SO:0000149>`_ or `golden_path_units <http://www.sequenceontology.org/browser/current_svn/term/SO:0000688>`_.

If a genome assembly is not stable, it is common to locate relative to assembly units such as contigs. These contigs may then be localized relative to the top-level assembly units. This is known in chado terms as a location graph.

We discuss here location graphs of depth 2. See also N-level assemblies. This scenario is often invisible to software interoperating with Chado. The software is free to only look at the main features and the contig-level feature and ignore the top-level assembly feature. It may sometimes be desirable to have software that can perform location transformations, mapping features from contigs to top-level units and back.

Application support for localization to contigs
```````````````````````````````````````````````

*  `Apollo <http://genomearchitect.github.io/>`_: Status unclear
*  `GBrowse <http://gmod.org/wiki/GBrowse>`_: Status unclear

Apollo should be happy to treat contigs just as if they were top-level units as chromosome arms. However, the user may have to explicitly provide contigs if location queries are desired. For example, Apollo may retrieve nothing if the user asks for a certain range on "chromosome 4", and the features are located relative to contigs which are themselves on "chromosome 4".

GBrowse may expect features to be located relative to top-level units such as chromosomes.

Redundant Localizations to Different Assembly Levels
----------------------------------------------------

Features can be located relative to both contigs and top-level assembly units.

Chado allows redundant feature localization using featureloc.locgroup > 0. This allows a database to have primary locations for features relative to contigs, and secondary locations relative to top-level units such as chromosomes. The converse is also allowed.

However this scenario is discouraged unless the chado db admin knows what they are doing. They must implement solutions to ensure that featurelocs with varying locgroup do not get out of sync. These solutions are not part of the standard Chado software suite. Nevertheless, this scenario may be useful for advanced users in certain circumstances

Application support for localization to different assembly levels
`````````````````````````````````````````````````````````````````

*  `Apollo <http://genomearchitect.github.io/>`_: Status unclear
*  `GBrowse <http://gmod.org/wiki/GBrowse>`_: Status partial

It is not clear if GBrowse uses locgroup in querying. If it constrains by locgroup, then this is essentially the same as feature localization to contigs in assembly.

Not clear if Apollo uses locgroup in querying. If it constrains by locgroup, then this is essentially the same as feature localization to contigs in assembly. Apollo will not preserve redundant featurelocs when writing back to the database. This could lead to the database getting out of sync.

N-level Assemblies
------------------

In theory it is possible (but rare) to have assemblies with variable depths, or with depths > 2. This scenario is rare. If required, then Chado can deal with this - there is no theoretical limit to the depth of a location graph. One can have annotated features located relative to minicontigs which are located relative to supercontigs which are located relative to chromosomes. Most software that interoperates with Chado will not be able to deal with this, so this scenario is discouraged except by advanced users who have no other option.

Unlocalized Features
--------------------

A gene without sequence based localization.

Many chado instances are purely concerned with genome annotation - in these cases it would be strange to have genes or other features such as transcripts with no localization (i.e. no featurelocs). However, this scenario is actually common when Chado is used in a wider context. We may learn of the existence of genes through non-sequence evidence such as genetics. When we have no sequence-based localization it is perfectly valid to have gene features with no featurelocs. When the time comes to create genome annotations for these, we just 'fill out' the gene feature by adding transcript and exon features.

==========================
Other Types of Gene Models
==========================
This section describes how one describes other commonly encountered
gene models in Chado.


Noncoding Genes
---------------

Similar to canonical model (see above), except with noncoding RNA. Not all genes are protein-coding - for example, genes can code for tRNA, miRNA, snoRNA, etc. A noncoding gene model is identical to a canonical model, with the following exceptions:

*  There is no polypeptide feature
*  Instead of an mRNA feature, there is a feature that is some other sub-type of RNA

Application support for noncoding genes
```````````````````````````````````````

*  Supported by `Apollo <http://genomearchitect.github.io/>`_
*  Supported by `GBrowse <http://gmod.org/wiki/GBrowse>`_

Pseudogene
----------

A pseudogene is a non-functional relic of a gene. A pseudogene may look like an ordinary gene, and may even have discernible parts such as exons. It may sometimes be desirable to annotate the exon structure of a pseudogene - this can in principle be done using SO types such as `decayed_exon <http://www.sequenceontology.org/browser/current_release/term/SO:0000464>`_. In practice no one is using Chado to do this. There are currently two practices for psuedogenes:

*  Pseudogenes are treated analogously to Noncoding Genes (see above). That is, there are normal "gene" and "exon" features. However, in place of a subtype of RNA, there is a feature of type pseudogene. This practice is **strongly discouraged** (it is not compliant with the relations in the Sequence Ontology, as it gives false counts to the number of real genes in the database). Note that this is the current default for `FlyBase <http://flybase.org/>`_.
*  Pseudogenes are normal singleton features (see below). There is no annotation of exon structure. This practice is encouraged. If at a later date it becomes desirable to annotated the exon structure of a pseudogene, it will be compatible with this.

Application support for pseudogenes
```````````````````````````````````

*  `Apollo <http://genomearchitect.github.io/>`_: status is unclear

Apollo by default treats pseudogenes using the first method, above. It may also be possible to configure it to the second, singleton, method. Annotating the exon structure of pseudogenes the correct way has not yet been attempted to our knowledge.

Singleton Feature
-----------------

Many types of features are singletons - that is they are not related to other features through the feature_relationship table. Storage of these is basic and as one may expect. Singleton features present no major problems. Unlike genes, which typically have parts (with the parts having subparts), singletons do not form feature graphs (or rather, they form feature graphs consisting of single nodes). Singleton features are located relative to other features (usually the genome, but once can have singletons that are located relative to other features - this may not be supported by all applications).

Application support for singletons
``````````````````````````````````

*  Supported by `Apollo <http://genomearchitect.github.io/>`_
*  Supported by `GBrowse <http://gmod.org/wiki/GBrowse>`_

Apollo supports singletons provided they are located relative to the genome (singletons located relative to other features will be ignored). It may be necessary to configure apollo to make the feature type "1-level".


Trans-spliced Gene
------------------
A trans-spliced gene has one or more transcripts in which that transcript may be spliced together from different parts of the genome.

A trans-spliced transcript is spliced from exons coming from different parts of the genome. The distance between each trans-spliced part may be large, or it may be in the same location on the opposite strand.

Most *C. elegans* genes have a trans-spliced leader sequence. This is different from the trans-splicing involved in *Drosophila*, where we observe what appears to be two transcripts on separate strands (both containing coding sequence) joining together in a single functional transcript.

There are two proposals for dealing with this. One treats the trans-spliced transcript as a single transcripts, with exons coming from different locations. The other treats the trans-spliced transcript as a mature transcript created from two distinct primary transcripts. Note that these proposals focus on the *Drosophila* example. A solution for the *C. elegans* example has not been proposed.

We treat this as an ordinary gene model, but relax our rules for exon locations in a transcript. For example, for the canonical *Drosophila* trans-spliced gene, we would allow transcripts to have exons on different strands. Note that in Chado, exon ordering comes from *feature_relationship.rank* (between exon and transcript), not from the featureloc of the exon. Chado has no problem with this. However, some software may make assumptions that all exons are on the same strand, or may try to order exons by their location to get a transcript sequence. This software will have unintended consequences with trans-spliced genes modeled using this proposal.

We would introduce extra transcripts, and have relations between the transcripts. Only the mature, spliced, transcript would have a relation to the polypeptide. This may model the biology better. However, it introduces a major departure from the canonical gene model. For this reason this proposal is unlikely to be adopted.

Application support for Trans-spliced Genes
```````````````````````````````````````````

*  `Apollo <http://genomearchitect.github.io/>`_: status unclear
*  `GBrowse <http://gmod.org/wiki/GBrowse>`_: status unclear

Transposon
----------

Transposons can be annotated as singleton features or as complex annotations. You would create a feature of type transposon insertion, with a loc of type 0 for insertion sites when the insertion is absent, 1 if present, and -1 (?) to link to the "template" -- generic representation of the transposon?

A transposon may consist of various parts such as `long_terminal_repeat <http://www.sequenceontology.org/browser/current_svn/term/SO:0000286>`_ and gene models coding for genes like gag, pol, and env. These parts may have all decayed over time. Transposon annotation typically ignores these subtleties as all that is usually required is a singleton-feature of type `transposable_element <http://www.sequenceontology.org/browser/current_svn/term/SO:0000101>`_. In this case, there is no difficulty.

If one requires detailed transposon annotation then one is entering uncharted water as far as both Chado and annotation tools are concerned (which is why this scenario is marked as still needing best practices below).

Gene with Implicit Features Manifested
--------------------------------------

Some feature types such as introns are not normally manifested as rows in chado. They are normally derived on-the-fly from the gaps between consecutive exons. See for an example. Occasionally it may be desirable to store the introns as actual rows in the feature table - for example in a report database.

Immature or Primary RNA
-----------------------

Generally we do not explicitly represent primary RNA transcripts unless there is something useful to say about them. If one wants to instantiate these they would be represented as features, and the mature message would be related to the primary message with derived_from as type_id in the feature_relationship table.

Application support for unlocalized genes
`````````````````````````````````````````

*  Supported by `Apollo <http://genomearchitect.github.io/>`_
*  Supported by `GBrowse <http://gmod.org/wiki/GBrowse>`_

GBrowse supports this scenario in that unlocalized features will be ignored from the genome viewer, which is appropriate.

Apollo supports this scenario in that unlocalized features will be ignored, which is appropriate behaviour for a genome annotation tool.

Gene model types that still need best practices
-----------------------------------------------

* Operons
* Dicistronic genes (similar to operons) - See `Intro to Chado Feature Graphs <http://gmod.org/wiki/Introduction_to_Chado#Feature_Graphs>`_ for a proposed solution for storing dicistronic genes.
* Gene with Regulatory Elements - Regulatory elements may be implicitly or explicitly associated with a gene.
* Detailed Transposons Annotations - If one requires detailed transposon annotation then one is entering uncharted water as far as both Chado and annotation tools are concerned (which is why this scenario is marked as still needing best practices). One option would be to treat each transposon part as distinct singletons, but this may be unsatisfactory as one may desire to have the appropriate part_of relations between the parts.
