# Chado

## What is Chado?

- A flexible, fairly abstract schema for handling all kinds of biological data
   - capable of representing many of the general classes of data frequently encountered in modern biology such as sequence, sequence comparisons, phenotypes, genotypes, ontologies, publications, and phylogeny
- intended to be used as both a primary datastore schema as well as a warehouse-style schema
- designed for use with all organisms + projects (e.g there are instances for virus, bacterial, plant + animal data)
- Controlled vocabularies (CVs) are used throughout Chado to type primary data and metadata providing a lot of flexibility
- originally conceived as the next generation Flybase database, combining the sequence annotation database gadfly with the Harvard and Cambridge databases

## Documentation

- For wiki documentation on the various modules, see http://www.gmod.org.
- All documentation will be moving over to our ReadtheDocs: https://chado.readthedocs.io/en/rtd/
- You can browse the full schema using SchemaSpy: https://chado.readthedocs.io/en/rtd/_static/schemaspy_integration/index.html

### Citation

If you use Chado in your research or integrate it into a tool you're building, please cite:

> Christopher J. Mungall, David B. Emmert, The FlyBase Consortium, A Chado case study: an ontology-based modular schema for representing genome-associated biological information, Bioinformatics, Volume 23, Issue 13, July 2007, Pages i337–i346, https://doi.org/10.1093/bioinformatics/btm189

## Installation

Please read the included [chado/INSTALL.Chado.md](./chado/INSTALL.Chado.md) document for instructions on how to install the Chado schema.

### Running the Docker Image

```
git clone https://github.com/GMOD/Chado.git
docker build --tag=GMOD/Chado:latest ./
docker run -it -d GMOD/Chado:latest
```

## Contributing to Chado

The Chado schema is open-source and community developed! Please feel free to open an issue on this repository with any suggestions, issues, or concerns you may have! 

You can see the full guide for contributors here: 
    https://chado.readthedocs.io/en/rtd/contributing.html

tl;dr

 - All PRs MUST be linked to an issue.
 - Issues must be open for 2 weeks before a PR is made.
 - PRs should be made from the GMOD:1.4 branch
 - PRs require a number of reviews for approval and can include reviews from outside the PMC. As such, your PR will be approaved faster if you get others from the community to review it ;-) 
 
## Chado Support

Please see our website and linked documentation for more information on Chado and the GMOD project:

- http://www.gmod.org/
- https://chado.readthedocs.io/en/rtd/
- https://chado.readthedocs.io/en/rtd/_static/schemaspy_integration/index.html

You can send questions to the Chado mailing list:

- gmod-schema@lists.sourceforge.net

You can search previous issues submitted to this repository and add your own here:

- https://github.com/GMOD/Chado/issues

If you are looking for the original JavaTools + XMLTools that used to be in this repository,
they were moved into a separate repository via [PR #100](https://github.com/GMOD/Chado/pull/100). They can now be found here:

- https://github.com/GMOD/chado_tools

## Particpation in a study of open source software

Please note that this repository is participating in a study into sustainability
 of open source projects. Data will be gathered about this repository for
 approximately the next 12 months, starting from June 12, 2021.

Data collected will include number of contributors, number of PRs, time taken to
 close/merge these PRs, and issues closed.

For more information, please visit
[our informational page](https://sustainable-open-science-and-software.github.io/) or download our [participant information sheet](https://sustainable-open-science-and-software.github.io/assets/PIS_sustainable_software.pdf).

More info: https://sustainable-open-science-and-software.github.io/readme_notice

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
