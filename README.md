# Chado

Chado is a modular schema for handling all kinds of biological
data.  It is intended to be used as both a primary datastore schema as
well as a warehouse-style schema.

## Introduction

Chado was originally conceived as the next generation Flybase
database, combining the sequence annotation database gadfly with the
Harvard and Cambridge databases.  We have avoided organism or
project specificity in the schema, and we hope it will be of use to
other projects.

The modules currently in chado are:

Module                     | Description
-------------------------- | ------------------------------
Audit                      | database audits
Companalysis               | data from computational analysis
Contact                    | people and groups
Controlled Vocabulary (cv) | controlled vocabularies and ontologies
Expression                 | summarized RNA and protein expresssion
General                    | identifiers
Genetic                    | genetic data and genotypes
Library                    | descriptions of molecular libraries
Mage                       | microarray data
Map                        | maps without sequence
Organism                   | species
Phenotype                  | phenotypic data
Phylogeny                  | phylogenetic trees
Publication (pub)          | publications and references
Sequence                   | sequences and sequence features
Stock                      | specimens and biological collections
WWW                        | generic classes for web interfaces

For documentation on the various modules, see http://www.gmod.org.

Other modules are possible; the existing modules cover a very large
variety of use cases.

Chado has a fairly abstract schema, and ontologies and controlled
vocabularies (CVs) are utilised where their use is favourable to
relational modeling.  In particular, the sequence ontology (SO) is vital to
the sequence module.

Some (but not all) of the use cases we have discussed are:

* Central dogma genome annotations

* Genes that break the central dogma (of which there are many
  Annotated in fly, including polycistronic transcripts, transplicing,
  selenocysteine readthroughs, rna editing, ....)

* Sequence variation data, including SNPs, transposable element
  insertions, indels, ... how this relates to phenotypes, how these
  effect the central dogma....

* Non-wildtype data, including representing a wildtype transcriptome
  and proteome on a non wildtype genome; implicit and explicit central
  dogma examples for mutant strains

* Complex phenotypic data

* Ontologies structured as graphs; querying over graph ontologies
  non-recursively by pre-computing the closure

* Sequence ontology

* Comparative data

* Genetic interactions

* Transgene constructs, complex genetic experiments and their results

The core schema is DBMS independent.  The SQL table create files can
be found in the chado/modules directory.  The main Chado developers
are currently using PostgreSQL.


## Installation

Please read the included [INSTALL.Chado](./INSTALL.Chado) document for instructions on how to
install the Chado schema.

## Chado Support
-------------

Please see our website for more information on Chado and the GMOD project:

    http://www.gmod.org/

You can send questions to the Chado mailing list:

    gmod-schema@lists.sourceforge.net

You can browse the schema CVS repository here:

    http://cvs.sourceforge.net/cgi-bin/viewcvs.cgi/gmod/schema/


## Authors

Chris Mungall, David Emmert and the GMOD team
