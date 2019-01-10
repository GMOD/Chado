Best Practices
==============

Chado is a generic `schema<http://gmod.org/wiki/Glossary#Database_Schema>`_, which means anyone writing software to query or write to chado (either `middleware <http://gmod.org/wiki/GMOD_Middleware>`_ or applications) should be aware of the different ways in which data can be  stored. We want to strike a nice balance between ﬂexibility and extensibility on the one hand, and strong typing and rigor on the other. We want to avoid the situation we have with GenBank entries where there are a dozen ways of representing a gene model, but we need to be able to cope with the constant surprises biology throws at us in an attempt to confound our nice computable models. This page on Best Practices represents the collective wisdom of those who use
Chado on a daily basis and are also familiar with its theoretical underpinnings.

See also:

*  `Chado Sequence Module <http://gmod.org/wiki/Chado_Sequence_Module>`_ - description of many of the terms used here
*  `Introduction to Chado <http://gmod.org/wiki/Introduction_to_Chado>`_ - useful visualizations of some of the models described here
*  `IGS Data Representation <http://gmod.org/wiki/IGS_Data_Representation>`_ - further discussion on these conventions and how they were implemented at IGS (for comparison)

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
   :widths: 10 30
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
