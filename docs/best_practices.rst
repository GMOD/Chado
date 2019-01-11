Best Practices
==============

Chado is a generic `schema<http://gmod.org/wiki/Glossary#Database_Schema>`_, which means anyone writing software to query or write to chado (either `middleware <http://gmod.org/wiki/GMOD_Middleware>`_ or applications) should be aware of the different ways in which data can be  stored. We want to strike a nice balance between ﬂexibility and extensibility on the one hand, and strong typing and rigor on the other. We want to avoid the situation we have with GenBank entries where there are a dozen ways of representing a gene model, but we need to be able to cope with the constant surprises biology throws at us in an attempt to confound our nice computable models. This page on Best Practices represents the collective wisdom of those who use
Chado on a daily basis and are also familiar with its theoretical underpinnings.

See also:

*  `Chado Sequence Module <http://gmod.org/wiki/Chado_Sequence_Module>`_ - description of many of the terms used here
*  `Introduction to Chado <http://gmod.org/wiki/Introduction_to_Chado>`_ - useful visualizations of some of the models described here
*  `IGS Data Representation <http://gmod.org/wiki/IGS_Data_Representation>`_ - further discussion on these conventions and how they were implemented at IGS (for comparison)

.. contents::

===========
Gene Models
===========
This section describes how one describes commonly encountered
gene models in Chado.

Canonical Gene Model
--------------------

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

Many types of features are singletons - that is they are not related to other features through the feature_relationship table. Storage of these is basic and as one may expect. Singleton features present no major problems. Unlike genes, which typically have parts (with the parts having subparts), singletons do not form feature graphs (or rather, they form feature graphs consisting of single nodes). Singleton features are located relative to other features (usually the genome, but once can have singletons that are located relative to other features - this may not be supported by all applications)
