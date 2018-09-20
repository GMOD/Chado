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

Please read the included [chado/INSTALL.Chado.md](./chado/INSTALL.Chado.md) document for instructions on how to
install the Chado schema.

## Chado Support

Please see our website for more information on Chado and the GMOD project:

    http://www.gmod.org/

You can send questions to the Chado mailing list:

    gmod-schema@lists.sourceforge.net

You can browse the schema CVS repository here:

    http://cvs.sourceforge.net/cgi-bin/viewcvs.cgi/gmod/schema/


## Authors

Chris Mungall, David Emmert and the GMOD team

Full list of committers:

- a8wright <a8wright@224a875b-6a50-0410-9993-82261b5d0d45>
- Allen Day <allenday@users.sourceforge.net>
- Ben Faga <mwz444@users.sourceforge.net>
- Bobular <bobular@users.sourceforge.net>
- Brian O. <briano@users.sourceforge.net>
- Brian O'Connor <boconnor@users.sourceforge.net>
- Chris Vandevelde <cnvandev@users.sourceforge.net>
- Chun-Huai Cheng <chunhuaicheng@gmail.com>
- cmungall <cjmungall@lbl.gov>
- Colin Wiel <cwiel@users.sourceforge.net>
- Cyril Pommier <cpommier_gmod@users.sourceforge.net>
- Dave Clements <clements@galaxyproject.org>
- David Emmert <emmert@users.sourceforge.net>
- Don Gilbert <don@dongilbert.net>
- elee <gk_fan@users.sourceforge.net>
- Eric Just <ejust@users.sourceforge.net>
- Eric Rasche <rasche.eric@gmail.com>
- Frank Smutniak <smutniak@users.sourceforge.net>
- Hilmar Lapp <hlapp@drycafe.net>
- Jason Stajich <stajich@users.sourceforge.net>
- Jay Sundaram <jaysundaram@users.sourceforge.net>
- Jim Hu <jimhu@users.sourceforge.net>
- Josh Goodman <jogoodma@indiana.edu>
- Kathleen Falls <kfalls@users.sourceforge.net>
- Ken Youens-Clark <kycl4rk@users.sourceforge.net>
- Lacey-Anne Sanderson <laceyannesanderson@gmail.com>
- lallsonu <lallsonu@224a875b-6a50-0410-9993-82261b5d0d45>
- Lincoln Stein <lincoln.stein@gmail.com>
- Malcolm Cook <malcolm.cook@gmail.com>
- Marc RJ Carlson <mcarlson@users.sourceforge.net>
- Mark Gibson <mgibson@users.sourceforge.net>
- Meg Staton <mestato@gmail.com>
- Monty Schulman <montys9@users.sourceforge.net>
- Nathan Liles <nliles@users.sourceforge.net>
- nm249 <nm249@cornell.edu>
- nmenda <nm249@cornell.edu>
- Nomi Harris <nomi@users.sourceforge.net>
- Peili Zhnag <peili@users.sourceforge.net>
- Peter Ruzanov <pruzanov@users.sourceforge.net>
- Pinglei Zhou <pinglei@users.sourceforge.net>
- Ram Podicheti <mnrusimh@indiana.edu>
- Richard D. Hayes <rdhayes@users.sourceforge.net>
- Rob Buels <rbuels@gmail.com>
- Scott Cain <scott@scottcain.net>
- Seth Redmond <sethnr@users.sourceforge.net>
- Sheldon McKay <sheldon.mckay@gmail.com>
- Shengqiang Shu <sshu@users.sourceforge.net>
- Stan Letovsky <sletovsky@users.sourceforge.net>
- Stephen Ficklin <spficklin@gmail.com>
- Tony deCatanzaro <tonydecat@users.sourceforge.net>
- Yuri Bendana <ybendana@users.sourceforge.net>
- zheng zha <zzgw@users.sourceforge.net>

