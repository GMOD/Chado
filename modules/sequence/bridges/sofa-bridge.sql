CREATE SCHEMA sofa;

--- ************************************************
--- *** relation: transcription_end_site         ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** The site where transcription ends.       ***
--- ************************************************
---

CREATE VIEW transcription_end_site AS
  SELECT
    feature_id AS transcription_end_site_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'transcription_end_site';

--- ************************************************
--- *** relation: repeat_family                  ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A group of characterized repeat sequence ***
--- *** s.                                       ***
--- ************************************************
---

CREATE VIEW repeat_family AS
  SELECT
    feature_id AS repeat_family_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'repeat_family';

--- ************************************************
--- *** relation: intron                         ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A segment of DNA that is transcribed, bu ***
--- *** t removed from within the transcript by  ***
--- *** splicing together the sequences (exons)  ***
--- *** on either side of it.                    ***
--- ************************************************
---

CREATE VIEW intron AS
  SELECT
    feature_id AS intron_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'intron';

--- ************************************************
--- *** relation: tiling_path                    ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A set of regions which overlap with mini ***
--- *** mal polymorphism to form a linear sequen ***
--- *** ce.                                      ***
--- ************************************************
---

CREATE VIEW tiling_path AS
  SELECT
    feature_id AS tiling_path_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'tiling_path';

--- ************************************************
--- *** relation: tiling_path_fragment           ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A piece of sequence that makes up a tili ***
--- *** ng_path.SO:0000472.                      ***
--- ************************************************
---

CREATE VIEW tiling_path_fragment AS
  SELECT
    feature_id AS tiling_path_fragment_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'tiling_path_fragment';

--- ************************************************
--- *** relation: located_sequence_feature       ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A biological feature that can be attribu ***
--- *** ted to a region of biological sequence.  ***
--- ************************************************
---

CREATE VIEW located_sequence_feature AS
  SELECT
    feature_id AS located_sequence_feature_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'located_sequence_feature';

--- ************************************************
--- *** relation: primer                         ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A short preexisting polynucleotide chain ***
--- ***  to which new deoxyribonucleotides can b ***
--- *** e added by DNA polymerase.               ***
--- ************************************************
---

CREATE VIEW primer AS
  SELECT
    feature_id AS primer_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'primer';

--- ************************************************
--- *** relation: snp                            ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** SNPs are single base pair positions in g ***
--- *** enomic DNA at which different sequence a ***
--- *** lternatives (alleles) exist in normal in ***
--- *** dividuals in some population(s), wherein ***
--- ***  the least frequent allele has an abunda ***
--- *** nce of 10r greater.                    ***
--- ************************************************
---

CREATE VIEW snp AS
  SELECT
    feature_id AS snp_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'SNP';

--- ************************************************
--- *** relation: integrated_virus               ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A viral sequence which has integrated in ***
--- *** to the host genome.                      ***
--- ************************************************
---

CREATE VIEW integrated_virus AS
  SELECT
    feature_id AS integrated_virus_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'integrated_virus';

--- ************************************************
--- *** relation: methylated_c                   ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A methylated deoxy-cytosine.             ***
--- ************************************************
---

CREATE VIEW methylated_c AS
  SELECT
    feature_id AS methylated_c_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'methylated_C';

--- ************************************************
--- *** relation: reagent                        ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A sequence used in experiment.           ***
--- ************************************************
---

CREATE VIEW reagent AS
  SELECT
    feature_id AS reagent_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'reagent';

--- ************************************************
--- *** relation: oligo                          ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A short oligonucleotide sequence, of len ***
--- *** gth on the order of 10's of bases; eithe ***
--- *** r single or double stranded.             ***
--- ************************************************
---

CREATE VIEW oligo AS
  SELECT
    feature_id AS oligo_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'oligo';

--- ************************************************
--- *** relation: junction                       ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A junction refers to an interbase locati ***
--- *** on of zero in a sequence.                ***
--- ************************************************
---

CREATE VIEW junction AS
  SELECT
    feature_id AS junction_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'junction';

--- ************************************************
--- *** relation: u14_snrna                      ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** U14 small nucleolar RNA (U14 snoRNA) is  ***
--- *** required for early cleavages of eukaryot ***
--- *** ic precursor rRNAs. In yeasts, this mole ***
--- *** cule possess a stem-loop region (known a ***
--- *** s the Y-domain) which is essential for f ***
--- *** unction. A similar structure, but with a ***
--- ***  different consensus sequence, is found  ***
--- *** in plants, but is absent in vertebrates. ***
--- ************************************************
---

CREATE VIEW u14_snrna AS
  SELECT
    feature_id AS u14_snrna_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'U14_snRNA';

--- ************************************************
--- *** relation: vault_rna                      ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A family of RNAs are found as part of th ***
--- *** e enigmatic vault ribonuceoprotein compl ***
--- *** ex. The complex consists of a major vaul ***
--- *** t protein (MVP), two minor vault protein ***
--- *** s (VPARP and TEP1), and several small un ***
--- *** translated RNA molecules. It has been su ***
--- *** ggested that the vault complex is involv ***
--- *** ed in drug resistance.                   ***
--- ************************************************
---

CREATE VIEW vault_rna AS
  SELECT
    feature_id AS vault_rna_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'vault_RNA';

--- ************************************************
--- *** relation: sts                            ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Short (typically a few hundred base pair ***
--- *** s) DNA sequence that has a single occurr ***
--- *** ence in a genome and whose location and  ***
--- *** base sequence are known.                 ***
--- ************************************************
---

CREATE VIEW sts AS
  SELECT
    feature_id AS sts_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'STS';

--- ************************************************
--- *** relation: y_rna                          ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Y RNAs are components of the Ro ribonucl ***
--- *** eoprotein particle (Ro RNP), in associat ***
--- *** ion with Ro60 and La proteins. The Y RNA ***
--- *** s and Ro60 and La proteins are well cons ***
--- *** erved, but the function of the Ro RNP is ***
--- ***  not known. In humans the RNA component  ***
--- *** can be one of four small RNAs: hY1, hY3, ***
--- ***  hY4 and hY5. These small RNAs are predi ***
--- *** cted to fold into a conserved secondary  ***
--- *** structure containing three stem structur ***
--- *** es. The largest of the four, hY1, contai ***
--- *** ns an additional hairpin.                ***
--- ************************************************
---

CREATE VIEW y_rna AS
  SELECT
    feature_id AS y_rna_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'Y_RNA';

--- ************************************************
--- *** relation: exon_junction                  ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** The boundary between two exons in a proc ***
--- *** essed transcript.                        ***
--- ************************************************
---

CREATE VIEW exon_junction AS
  SELECT
    feature_id AS exon_junction_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'exon_junction';

--- ************************************************
--- *** relation: rrna_18s                       ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** 18S_rRNA -A large polynucleotide which f ***
--- *** unctions as a part of the small subunit  ***
--- *** of the ribosome                          ***
--- ************************************************
---

CREATE VIEW rrna_18s AS
  SELECT
    feature_id AS rrna_18s_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'rRNA_18S';

--- ************************************************
--- *** relation: binding_site                   ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A region on the surface of a molecule th ***
--- *** at may interact with another molecule.   ***
--- ************************************************
---

CREATE VIEW binding_site AS
  SELECT
    feature_id AS binding_site_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'binding_site';

--- ************************************************
--- *** relation: pseudogene                     ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A sequence that closely resembles a know ***
--- *** n functional gene, at another locus with ***
--- *** in a genome, that is non-functional as a ***
--- ***  consequence of (usually several) mutati ***
--- *** ons that prevent either its transcriptio ***
--- *** n or translation (or both). In general,  ***
--- *** pseudogenes result from either reverse t ***
--- *** ranscription of a transcript of their "n ***
--- *** ormal" paralog (SO:0000043) (in which ca ***
--- *** se the pseudogene typically lacks intron ***
--- *** s and includes a poly(A) tail) or from r ***
--- *** ecombination (SO:0000044) (in which case ***
--- ***  the pseudogene is typically a tandem du ***
--- *** plication of its "normal" paralog).      ***
--- ************************************************
---

CREATE VIEW pseudogene AS
  SELECT
    feature_id AS pseudogene_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'pseudogene';

--- ************************************************
--- *** relation: rnai_reagent                   ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A double stranded RNA duplex, at least 2 ***
--- *** 0bp long, used experimentally to inhibit ***
--- ***  gene function by RNA interference.      ***
--- ************************************************
---

CREATE VIEW rnai_reagent AS
  SELECT
    feature_id AS rnai_reagent_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'RNAi_reagent';

--- ************************************************
--- *** relation: rflp_fragment                  ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A polymorphism detectable by the size di ***
--- *** fferences in DNA fragments generated by  ***
--- *** a restriction enzyme.                    ***
--- ************************************************
---

CREATE VIEW rflp_fragment AS
  SELECT
    feature_id AS rflp_fragment_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'RFLP_fragment';

--- ************************************************
--- *** relation: telomere                       ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A specific structure at the end of a lin ***
--- *** ear chromosome, required for the integri ***
--- *** ty and maintenence of the end,           ***
--- ************************************************
---

CREATE VIEW telomere AS
  SELECT
    feature_id AS telomere_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'telomere';

--- ************************************************
--- *** relation: polya_signal_sequence          ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** The recognition sequence necessary for e ***
--- *** ndonuclease cleavage of an RNA transcrip ***
--- *** t that is followed by polyadenylation; c ***
--- *** onsensus=AATAAA.                         ***
--- ************************************************
---

CREATE VIEW polya_signal_sequence AS
  SELECT
    feature_id AS polya_signal_sequence_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'polyA_signal_sequence';

--- ************************************************
--- *** relation: silencer                       ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Combination of short DNA sequence elemen ***
--- *** ts which suppress the transcription of a ***
--- *** n adjacent gene or genes.                ***
--- ************************************************
---

CREATE VIEW silencer AS
  SELECT
    feature_id AS silencer_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'silencer';

--- ************************************************
--- *** relation: gene_group                     ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A collection of related genes.           ***
--- ************************************************
---

CREATE VIEW gene_group AS
  SELECT
    feature_id AS gene_group_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'gene_group';

--- ************************************************
--- *** relation: polya_site                     ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** The site on an RNA transcript to which w ***
--- *** ill be added adenine residues by post-tr ***
--- *** anscriptional polyadenylation.           ***
--- ************************************************
---

CREATE VIEW polya_site AS
  SELECT
    feature_id AS polya_site_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'polyA_site';

--- ************************************************
--- *** relation: insulator                      ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Nucleic acid regulatory sequences that l ***
--- *** imit or oppose the action of ENHANCER EL ***
--- *** EMENTS and define the boundary between d ***
--- *** ifferentially regulated gene loci.       ***
--- ************************************************
---

CREATE VIEW insulator AS
  SELECT
    feature_id AS insulator_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'insulator';

--- ************************************************
--- *** relation: chromosomal_structural_element ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A part of a chromosome that has structur ***
--- *** al function.                             ***
--- ************************************************
---

CREATE VIEW chromosomal_structural_element AS
  SELECT
    feature_id AS chromosomal_structural_element_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'chromosomal_structural_element';

--- ************************************************
--- *** relation: nc_primary_transcript          ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A primary transcript that is never trans ***
--- *** lated into a protein.                    ***
--- ************************************************
---

CREATE VIEW nc_primary_transcript AS
  SELECT
    feature_id AS nc_primary_transcript_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'nc_primary_transcript';

--- ************************************************
--- *** relation: p_coding_primary_transcript    ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A primary transcript that, at least in p ***
--- *** art, encodes one or more proteins.       ***
--- ************************************************
---

CREATE VIEW p_coding_primary_transcript AS
  SELECT
    feature_id AS p_coding_primary_transcript_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'protein_coding_primary_transcript';

--- ************************************************
--- *** relation: substitution                   ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Any change in genomic DNA caused by a si ***
--- *** ngle event.                              ***
--- ************************************************
---

CREATE VIEW substitution AS
  SELECT
    feature_id AS substitution_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'substitution';

--- ************************************************
--- *** relation: complex_substitution           ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** When no simple or well defined DNA mutat ***
--- *** ion event describes the observed DNA cha ***
--- *** nge, the keyword "complex" should be use ***
--- *** d. Usually there are multiple equally pl ***
--- *** ausible explanations for the change.     ***
--- ************************************************
---

CREATE VIEW complex_substitution AS
  SELECT
    feature_id AS complex_substitution_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'complex_substitution';

--- ************************************************
--- *** relation: point_mutation                 ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A mutation event where a single DNA nucl ***
--- *** eotide changes into another nucleotide.  ***
--- ************************************************
---

CREATE VIEW point_mutation AS
  SELECT
    feature_id AS point_mutation_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'point_mutation';

--- ************************************************
--- *** relation: restriction_fragment           ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Any of the individual polynucleotide seq ***
--- *** uences produced by digestion of DNA with ***
--- ***  a restriction endonuclease.             ***
--- ************************************************
---

CREATE VIEW restriction_fragment AS
  SELECT
    feature_id AS restriction_fragment_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'restriction_fragment';

--- ************************************************
--- *** relation: sequence_difference            ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A region where the sequences differs fro ***
--- *** m that of a specified sequence.          ***
--- ************************************************
---

CREATE VIEW sequence_difference AS
  SELECT
    feature_id AS sequence_difference_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'sequence_difference';

--- ************************************************
--- *** relation: chromosome                     ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Structural unit composed of long DNA mol ***
--- *** ecule.                                   ***
--- ************************************************
---

CREATE VIEW chromosome AS
  SELECT
    feature_id AS chromosome_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'chromosome';

--- ************************************************
--- *** relation: operator                       ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A regulatory element of an operon to whi ***
--- *** ch activators or repressors bind hereby  ***
--- *** effecting translation of genes in that o ***
--- *** peron.                                   ***
--- ************************************************
---

CREATE VIEW operator AS
  SELECT
    feature_id AS operator_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'operator';

--- ************************************************
--- *** relation: match                          ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A region of sequence, aligned to another ***
--- ***  sequence with some statistical signific ***
--- *** ance, using an algorithm such as BLAST o ***
--- *** r SIM4.                                  ***
--- ************************************************
---

CREATE VIEW match AS
  SELECT
    feature_id AS match_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'match';

--- ************************************************
--- *** relation: remark                         ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A comment about the sequence.            ***
--- ************************************************
---

CREATE VIEW remark AS
  SELECT
    feature_id AS remark_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'remark';

--- ************************************************
--- *** relation: splice_enhancer                ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Region of a transcript that regulates sp ***
--- *** licing.                                  ***
--- ************************************************
---

CREATE VIEW splice_enhancer AS
  SELECT
    feature_id AS splice_enhancer_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'splice_enhancer';

--- ************************************************
--- *** relation: possible_base_call_error       ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A region of sequence where the validity  ***
--- *** of the base calling is questionable.     ***
--- ************************************************
---

CREATE VIEW possible_base_call_error AS
  SELECT
    feature_id AS possible_base_call_error_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'possible_base_call_error';

--- ************************************************
--- *** relation: signal_peptide                 ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** The sequence for an N-terminal domain of ***
--- ***  a secreted protein; this domain is invo ***
--- *** lved in attaching nascent polypeptide to ***
--- ***  the membrane leader sequence.           ***
--- ************************************************
---

CREATE VIEW signal_peptide AS
  SELECT
    feature_id AS signal_peptide_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'signal_peptide';

--- ************************************************
--- *** relation: est                            ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Expressed Sequence Tag: The sequence of  ***
--- *** a single sequencing read from a cDNA clo ***
--- *** ne or PCR product; typically a few hundr ***
--- *** ed base pairs long.                      ***
--- ************************************************
---

CREATE VIEW est AS
  SELECT
    feature_id AS est_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'EST';

--- ************************************************
--- *** relation: possible_assembly_error        ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A region of sequence where there may hav ***
--- *** e been an error in the assembly.         ***
--- ************************************************
---

CREATE VIEW possible_assembly_error AS
  SELECT
    feature_id AS possible_assembly_error_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'possible_assembly_error';

--- ************************************************
--- *** relation: mature_peptide                 ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** The coding sequence for the mature or fi ***
--- *** nal peptide or protein product following ***
--- ***  post-translational modification.        ***
--- ************************************************
---

CREATE VIEW mature_peptide AS
  SELECT
    feature_id AS mature_peptide_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'mature_peptide';

--- ************************************************
--- *** relation: experimental_result_region     ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A region of sequence implicated in an ex ***
--- *** perimental result.                       ***
--- ************************************************
---

CREATE VIEW experimental_result_region AS
  SELECT
    feature_id AS experimental_result_region_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'experimental_result_region';

--- ************************************************
--- *** relation: nucleotide_match               ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A match against a nucleotide sequence.   ***
--- ************************************************
---

CREATE VIEW nucleotide_match AS
  SELECT
    feature_id AS nucleotide_match_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'nucleotide_match';

--- ************************************************
--- *** relation: snrna                          ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Small non-coding RNA in the nucleoplasm. ***
--- ***  A small nuclear RNA molecule involved i ***
--- *** n pre-mRNA splicing and processing       ***
--- ************************************************
---

CREATE VIEW snrna AS
  SELECT
    feature_id AS snrna_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'snRNA';

--- ************************************************
--- *** relation: gene                           ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A locatable region of genomic sequence,  ***
--- *** corresponding to a unit of inheritance,  ***
--- *** which is associated with regulatory regi ***
--- *** ons, transcribed regions and/or other fu ***
--- *** nctional sequence regions                ***
--- ************************************************
---

CREATE VIEW gene AS
  SELECT
    feature_id AS gene_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'gene';

--- ************************************************
--- *** relation: snorna                         ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Small nucleolar RNAs (snoRNAs) are invol ***
--- *** ved in the processing and modification o ***
--- *** f rRNA in the nucleolus. There are two m ***
--- *** ain classes of snoRNAs: the box C/D clas ***
--- *** s, and the box H/ACA class. U3 snoRNA is ***
--- ***  a member of the box C/D class. Indeed,  ***
--- *** the box C/D element is a subset of the s ***
--- *** ix short sequence elements found in all  ***
--- *** U3 snoRNAs, namely boxes A, A', B, C, C' ***
--- *** , and D. The U3 snoRNA secondary structu ***
--- *** re is characterised by a small 5' domain ***
--- ***  (with boxes A and A'), and a larger 3'  ***
--- *** domain (with boxes B, C, C', and D), the ***
--- ***  two domains being linked by a single-st ***
--- *** randed hinge. Boxes B and C form the B/C ***
--- ***  motif, which appears to be exclusive to ***
--- ***  U3 snoRNAs, and boxes C' and D form the ***
--- ***  C'/D motif. The latter is functionally  ***
--- *** similar to the C/D motifs found in other ***
--- ***  snoRNAs. The 5' domain and the hinge re ***
--- *** gion act as a pre-rRNA-binding domain. T ***
--- *** he 3' domain has conserved protein-bindi ***
--- *** ng sites. Both the box B/C and box C'/D  ***
--- *** motifs are sufficient for nuclear retent ***
--- *** ion of U3 snoRNA. The box C'/D motif is  ***
--- *** also necessary for nucleolar localizatio ***
--- *** n, stability and hypermethylation of U3  ***
--- *** snoRNA. Both box B/C and C'/D motifs are ***
--- ***  involved in specific protein interactio ***
--- *** ns and are necessary for the rRNA proces ***
--- *** sing functions of U3 snoRNA.             ***
--- ************************************************
---

CREATE VIEW snorna AS
  SELECT
    feature_id AS snorna_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'snoRNA';

--- ************************************************
--- *** relation: tandem_repeat                  ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Two or more adjacent copies of a DNA seq ***
--- *** uence.                                   ***
--- ************************************************
---

CREATE VIEW tandem_repeat AS
  SELECT
    feature_id AS tandem_repeat_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'tandem_repeat';

--- ************************************************
--- *** relation: p_match                        ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A match against a protein sequence.      ***
--- ************************************************
---

CREATE VIEW p_match AS
  SELECT
    feature_id AS p_match_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'protein_match';

--- ************************************************
--- *** relation: mirna                          ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Small, ~22-nt, RNA molecule that is the  ***
--- *** endogenous transcript of a miRNA gene. m ***
--- *** iRNAs are produced from precursor molecu ***
--- *** les (SO:0000647) that can form local hai ***
--- *** rpin strcutures, which ordinarily are pr ***
--- *** ocessed (via the Dicer pathway) such tha ***
--- *** t a single miRNA molecule accumulates fr ***
--- *** om one arm of a hairpinprecursor molecul ***
--- *** e. miRNAs may trigger the cleavage of th ***
--- *** eir target molecules oract as translatio ***
--- *** nal repressors.                          ***
--- ************************************************
---

CREATE VIEW mirna AS
  SELECT
    feature_id AS mirna_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'miRNA';

--- ************************************************
--- *** relation: trans_splice_acceptor_site     ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** The process that produces mature transcr ***
--- *** ipts by combining exons of independent p ***
--- *** re-mRNA molecules. The acceptor site lie ***
--- *** s on the 3' of these molecules.          ***
--- ************************************************
---

CREATE VIEW trans_splice_acceptor_site AS
  SELECT
    feature_id AS trans_splice_acceptor_site_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'trans_splice_acceptor_site';

--- ************************************************
--- *** relation: virtual_sequence               ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A continous piece of sequence similar to ***
--- ***  the 'virtual contig' concept of ensembl ***
--- *** .                                        ***
--- ************************************************
---

CREATE VIEW virtual_sequence AS
  SELECT
    feature_id AS virtual_sequence_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'virtual_sequence';

--- ************************************************
--- *** relation: utr                            ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Messenger RNA sequences that are untrans ***
--- *** lated and lie five prime and three prime ***
--- ***  to sequences which are translated.      ***
--- ************************************************
---

CREATE VIEW utr AS
  SELECT
    feature_id AS utr_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'UTR';

--- ************************************************
--- *** relation: five_prime_utr                 ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A region at the 5' end of a mature trans ***
--- *** cript (preceding the initiation codon) t ***
--- *** hat is not translated into a protein.    ***
--- ************************************************
---

CREATE VIEW five_prime_utr AS
  SELECT
    feature_id AS five_prime_utr_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'five_prime_UTR';

--- ************************************************
--- *** relation: three_prime_utr                ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A region at the 3' end of a mature trans ***
--- *** cript (following the stop codon) that is ***
--- ***  not translated into a protein.          ***
--- ************************************************
---

CREATE VIEW three_prime_utr AS
  SELECT
    feature_id AS three_prime_utr_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'three_prime_UTR';

--- ************************************************
--- *** relation: ribosome_entry_site            ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Region in mRNA where ribosome assembles. ***
--- ************************************************
---

CREATE VIEW ribosome_entry_site AS
  SELECT
    feature_id AS ribosome_entry_site_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'ribosome_entry_site';

--- ************************************************
--- *** relation: assembly                       ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A sequence of nucleotides that has been  ***
--- *** algorithmically derived from an alignmen ***
--- *** t of two or more different sequences.    ***
--- ************************************************
---

CREATE VIEW assembly AS
  SELECT
    feature_id AS assembly_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'assembly';

--- ************************************************
--- *** relation: nucleotide_motif               ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A region of nucleotide sequence correspo ***
--- *** nding to a known motif.                  ***
--- ************************************************
---

CREATE VIEW nucleotide_motif AS
  SELECT
    feature_id AS nucleotide_motif_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'nucleotide_motif';

--- ************************************************
--- *** relation: minisatellite                  ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A repetitive sequence spanning 500 to 20 ***
--- *** ,000 base pairs (a repeat unit is 5 - 30 ***
--- ***  base pairs).                            ***
--- ************************************************
---

CREATE VIEW minisatellite AS
  SELECT
    feature_id AS minisatellite_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'minisatellite';

--- ************************************************
--- *** relation: reading_frame                  ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A nucleic acid sequence that when read a ***
--- *** s sequential triplets, has the potential ***
--- ***  of encoding a sequential string of amin ***
--- *** o acids. It does not contain the start o ***
--- *** r stop codon.                            ***
--- ************************************************
---

CREATE VIEW reading_frame AS
  SELECT
    feature_id AS reading_frame_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'reading_frame';

--- ************************************************
--- *** relation: antisense_rna                  ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Antisense RNA is RNA that is transcribed ***
--- ***  from the coding, rather than the templa ***
--- *** te, strand of DNA. It is therefore compl ***
--- *** ementary to mRNA.                        ***
--- ************************************************
---

CREATE VIEW antisense_rna AS
  SELECT
    feature_id AS antisense_rna_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'antisense_RNA';

--- ************************************************
--- *** relation: antisense_primary_transcript   ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** The reverse complement of the primary tr ***
--- *** anscript.                                ***
--- ************************************************
---

CREATE VIEW antisense_primary_transcript AS
  SELECT
    feature_id AS antisense_primary_transcript_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'antisense_primary_transcript';

--- ************************************************
--- *** relation: microsatellite                 ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A very short unit sequence of DNA (2 to  ***
--- *** 4 bp) that is repeated multiple times in ***
--- ***  tandem.                                 ***
--- ************************************************
---

CREATE VIEW microsatellite AS
  SELECT
    feature_id AS microsatellite_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'microsatellite';

--- ************************************************
--- *** relation: ultracontig                    ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** An ordered and oriented set of scaffolds ***
--- ***  based on somewhat weaker sets of infere ***
--- *** ntial evidence such as one set of mate p ***
--- *** air reads together with supporting evide ***
--- *** nce from ESTs or location of markers fro ***
--- *** m SNP or microsatellite maps, or cytogen ***
--- *** etic localization of contained markers.  ***
--- ************************************************
---

CREATE VIEW ultracontig AS
  SELECT
    feature_id AS ultracontig_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'ultracontig';

--- ************************************************
--- *** relation: sirna                          ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Small RNA molecule that is the product o ***
--- *** f a longerexogenous or endogenous dsRNA, ***
--- ***  which is either a bimolecular duplexe o ***
--- *** r very longhairpin, processed (via the D ***
--- *** icer pathway) such that numerous siRNAs  ***
--- *** accumulatefrom both strands of the dsRNA ***
--- *** . sRNAs trigger the cleavage of their ta ***
--- *** rget molecules.                          ***
--- ************************************************
---

CREATE VIEW sirna AS
  SELECT
    feature_id AS sirna_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'siRNA';

--- ************************************************
--- *** relation: strna                          ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Non-coding RNAs of about 21 nucleotides  ***
--- *** in length that regulate temporal develop ***
--- *** ment; first discovered in C. elegans.    ***
--- ************************************************
---

CREATE VIEW strna AS
  SELECT
    feature_id AS strna_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'stRNA';

--- ************************************************
--- *** relation: centromere                     ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A region of chromosome where the spindle ***
--- ***  fibers attach during mitosis and meiosi ***
--- *** s.                                       ***
--- ************************************************
---

CREATE VIEW centromere AS
  SELECT
    feature_id AS centromere_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'centromere';

--- ************************************************
--- *** relation: attenuator                     ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A sequence segment located between the p ***
--- *** romoter and a structural gene that cause ***
--- *** s partial termination of transcription.  ***
--- ************************************************
---

CREATE VIEW attenuator AS
  SELECT
    feature_id AS attenuator_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'attenuator';

--- ************************************************
--- *** relation: terminator                     ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** The sequence of DNA located either at th ***
--- *** e end of the transcript that causes RNA  ***
--- *** polymerase to terminate transcription.   ***
--- ************************************************
---

CREATE VIEW terminator AS
  SELECT
    feature_id AS terminator_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'terminator';

--- ************************************************
--- *** relation: assembly_component             ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A region of sequence which may be used t ***
--- *** o manufacture a longer assembled, sequen ***
--- *** ce.                                      ***
--- ************************************************
---

CREATE VIEW assembly_component AS
  SELECT
    feature_id AS assembly_component_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'assembly_component';

--- ************************************************
--- *** relation: exon                           ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A region of the genome that codes for po ***
--- *** rtion of spliced messenger RNA (SO:00002 ***
--- *** 34); may contain 5'-untranslated region  ***
--- *** (SO:0000204), all open reading frames (S ***
--- *** O:0000236) and 3'-untranslated region (S ***
--- *** O:0000205).                              ***
--- ************************************************
---

CREATE VIEW exon AS
  SELECT
    feature_id AS exon_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'exon';

--- ************************************************
--- *** relation: supercontig                    ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** One or more contigs that have been order ***
--- *** ed and oriented using end-read informati ***
--- *** on. Contains gaps that are filled with N ***
--- *** 's.                                      ***
--- ************************************************
---

CREATE VIEW supercontig AS
  SELECT
    feature_id AS supercontig_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'supercontig';

--- ************************************************
--- *** relation: contig                         ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A contiguous sequence derived from seque ***
--- *** nce assembly. Has no gaps, but may conta ***
--- *** in N's from unvailable bases.            ***
--- ************************************************
---

CREATE VIEW contig AS
  SELECT
    feature_id AS contig_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'contig';

--- ************************************************
--- *** relation: codon                          ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A set of (usually) three nucleotide base ***
--- *** s in a DNA or RNA sequence, which togeth ***
--- *** er signify a unique amino acid or the te ***
--- *** rmination of translation.                ***
--- ************************************************
---

CREATE VIEW codon AS
  SELECT
    feature_id AS codon_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'codon';

--- ************************************************
--- *** relation: pseudogenic_exon               ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** The exon of a pseudogene.                ***
--- ************************************************
---

CREATE VIEW pseudogenic_exon AS
  SELECT
    feature_id AS pseudogenic_exon_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'pseudogenic_exon';

--- ************************************************
--- *** relation: ars                            ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A sequence that can autonomously replica ***
--- *** te, as a plasmid, when transformed into  ***
--- *** a bacterial host.                        ***
--- ************************************************
---

CREATE VIEW ars AS
  SELECT
    feature_id AS ars_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'ARS';

--- ************************************************
--- *** relation: insertion_site                 ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** The junction where an insertion occurred ***
--- *** .                                        ***
--- ************************************************
---

CREATE VIEW insertion_site AS
  SELECT
    feature_id AS insertion_site_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'insertion_site';

--- ************************************************
--- *** relation: inverted_repeat                ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** The sequence is complementarily repeated ***
--- ***  on the opposite strand. Example: GCTGA- ***
--- *** ----TCAGC.                               ***
--- ************************************************
---

CREATE VIEW inverted_repeat AS
  SELECT
    feature_id AS inverted_repeat_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'inverted_repeat';

--- ************************************************
--- *** relation: origin_of_transfer             ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A region of a DNA molecule whre transfer ***
--- ***  is initiated during the process of conj ***
--- *** ugation or mobilization.                 ***
--- ************************************************
---

CREATE VIEW origin_of_transfer AS
  SELECT
    feature_id AS origin_of_transfer_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'origin_of_transfer';

--- ************************************************
--- *** relation: t_element_insertion_site       ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** The junction in a genome where a transpo ***
--- *** sable_element has inserted.              ***
--- ************************************************
---

CREATE VIEW t_element_insertion_site AS
  SELECT
    feature_id AS t_element_insertion_site_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'transposable_element_insertion_site';

--- ************************************************
--- *** relation: transit_peptide                ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** The coding sequence for an N-terminal do ***
--- *** main of a nuclear-encoded organellar pro ***
--- *** tein: this domain is involved in post tr ***
--- *** anslational import of the protein into t ***
--- *** he organelle.                            ***
--- ************************************************
---

CREATE VIEW transit_peptide AS
  SELECT
    feature_id AS transit_peptide_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'transit_peptide';

--- ************************************************
--- *** relation: rrna_5s                        ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** 5S ribosomal RNA (5S rRNA) is a componen ***
--- *** t of the large ribosomal subunit in both ***
--- ***  prokaryotes and eukaryotes. In eukaryot ***
--- *** es, it is synthesised by RNA polymerase  ***
--- *** III (the other eukaryotic rRNAs are clea ***
--- *** ved from a 45S precursor synthesised by  ***
--- *** RNA polymerase I). In Xenopus oocytes, i ***
--- *** t has been shown that fingers 4-7 of the ***
--- ***  nine-zinc finger transcription factor T ***
--- *** FIIIA can bind to the central region of  ***
--- *** 5S RNA. Thus, in addition to positively  ***
--- *** regulating 5S rRNA transcription, TFIIIA ***
--- ***  also stabilises 5S rRNA until it is req ***
--- *** uired for transcription.                 ***
--- ************************************************
---

CREATE VIEW rrna_5s AS
  SELECT
    feature_id AS rrna_5s_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'rRNA_5S';

--- ************************************************
--- *** relation: origin_of_replication          ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** The origin of replication; starting site ***
--- ***  for duplication of a nucleic acid molec ***
--- *** ule to give two identical copies.        ***
--- ************************************************
---

CREATE VIEW origin_of_replication AS
  SELECT
    feature_id AS origin_of_replication_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'origin_of_replication';

--- ************************************************
--- *** relation: rrna_28s                       ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A component of the large ribosomal subun ***
--- *** it.                                      ***
--- ************************************************
---

CREATE VIEW rrna_28s AS
  SELECT
    feature_id AS rrna_28s_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'rRNA_28S';

--- ************************************************
--- *** relation: sequence_ontology              ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- ************************************************
---

CREATE VIEW sequence_ontology AS
  SELECT
    feature_id AS sequence_ontology_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'Sequence_Ontology';

--- ************************************************
--- *** relation: cap                            ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A structure consisting of a 7-methylguan ***
--- *** osine in 5'-5' triphosphate linkage with ***
--- ***  the first nucleotide of an mRNA. It is  ***
--- *** added post-transcriptionally, and is not ***
--- ***  encoded in the DNA.                     ***
--- ************************************************
---

CREATE VIEW cap AS
  SELECT
    feature_id AS cap_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'cap';

--- ************************************************
--- *** relation: ncrna                          ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** An mRNA sequence that does not encode fo ***
--- *** r a protein rather the RNA molecule is t ***
--- *** he gene product.                         ***
--- ************************************************
---

CREATE VIEW ncrna AS
  SELECT
    feature_id AS ncrna_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'ncRNA';

--- ************************************************
--- *** relation: region                         ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Continuous sequence.                     ***
--- ************************************************
---

CREATE VIEW region AS
  SELECT
    feature_id AS region_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'region';

--- ************************************************
--- *** relation: repeat_region                  ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A region of sequence containing one or m ***
--- *** ore repeat units.                        ***
--- ************************************************
---

CREATE VIEW repeat_region AS
  SELECT
    feature_id AS repeat_region_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'repeat_region';

--- ************************************************
--- *** relation: dispersed_repeat               ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A repeat that is located at dispersed si ***
--- *** tes in the genome.                       ***
--- ************************************************
---

CREATE VIEW dispersed_repeat AS
  SELECT
    feature_id AS dispersed_repeat_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'dispersed_repeat';

--- ************************************************
--- *** relation: pcr_product                    ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A region amplified by a PCR reaction.    ***
--- ************************************************
---

CREATE VIEW pcr_product AS
  SELECT
    feature_id AS pcr_product_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'PCR_product';

--- ************************************************
--- *** relation: read_pair                      ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A pair of sequencing reads in which the  ***
--- *** two members of the pair are related by o ***
--- *** riginating at either end of a clone inse ***
--- *** rt.                                      ***
--- ************************************************
---

CREATE VIEW read_pair AS
  SELECT
    feature_id AS read_pair_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'read_pair';

--- ************************************************
--- *** relation: group_i_intron                 ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Group I catalytic introns are large self ***
--- *** -splicing ribozymes. They catalyse their ***
--- ***  own excision from mRNA, tRNA and rRNA p ***
--- *** recursors in a wide range of organisms.  ***
--- *** The core secondary structure consists of ***
--- ***  9 paired regions (P1-P9). These fold to ***
--- ***  essentially two domains, the P4-P6 doma ***
--- *** in (formed from the stacking of P5, P4,  ***
--- *** P6 and P6a helices) and the P3-P9 domain ***
--- ***  (formed from the P8, P3, P7 and P9 heli ***
--- *** ces). Group I catalytic introns often ha ***
--- *** ve long ORFs inserted in loop regions.   ***
--- ************************************************
---

CREATE VIEW group_i_intron AS
  SELECT
    feature_id AS group_i_intron_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'group_I_intron';

--- ************************************************
--- *** relation: a_spliced_intron               ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A self spliced intron.                   ***
--- ************************************************
---

CREATE VIEW a_spliced_intron AS
  SELECT
    feature_id AS a_spliced_intron_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'autocatalytically_spliced_intron';

--- ************************************************
--- *** relation: read                           ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A sequence obtained from a single sequen ***
--- *** cing experiment. Typically a read is pro ***
--- *** duced when a base calling program interp ***
--- *** rets information from a chromatogram tra ***
--- *** ce file produced from a sequencing machi ***
--- *** ne.                                      ***
--- ************************************************
---

CREATE VIEW read AS
  SELECT
    feature_id AS read_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'read';

--- ************************************************
--- *** relation: clone                          ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A piece of DNA that has been inserted in ***
--- ***  a vector so that it can be propagated i ***
--- *** n E. coli or some other organism.        ***
--- ************************************************
---

CREATE VIEW clone AS
  SELECT
    feature_id AS clone_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'clone';

--- ************************************************
--- *** relation: inversion                      ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A continuous nucleotide sequence is inve ***
--- *** rted in the same position.               ***
--- ************************************************
---

CREATE VIEW inversion AS
  SELECT
    feature_id AS inversion_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'inversion';

--- ************************************************
--- *** relation: deletion                       ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** The sequence that is deleted.            ***
--- ************************************************
---

CREATE VIEW deletion AS
  SELECT
    feature_id AS deletion_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'deletion';

--- ************************************************
--- *** relation: small_regulatory_ncrna         ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A non-coding RNA, usually with a specifi ***
--- *** c secondary structure, that acts to regu ***
--- *** late gene expression.                    ***
--- ************************************************
---

CREATE VIEW small_regulatory_ncrna AS
  SELECT
    feature_id AS small_regulatory_ncrna_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'small_regulatory_ncRNA';

--- ************************************************
--- *** relation: pseudogenic_transcript         ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A transcript of a pseudogene             ***
--- ************************************************
---

CREATE VIEW pseudogenic_transcript AS
  SELECT
    feature_id AS pseudogenic_transcript_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'pseudogenic_transcript';

--- ************************************************
--- *** relation: enzymatic_rna                  ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A non-coding RNA, usually with a specifi ***
--- *** c secondary structure, that acts to regu ***
--- *** late gene expression.                    ***
--- ************************************************
---

CREATE VIEW enzymatic_rna AS
  SELECT
    feature_id AS enzymatic_rna_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'enzymatic_RNA';

--- ************************************************
--- *** relation: databank_entry                 ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** The sequence referred to by an entry in  ***
--- *** a databank such as Genbank or SwissProt. ***
--- ************************************************
---

CREATE VIEW databank_entry AS
  SELECT
    feature_id AS databank_entry_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'databank_entry';

--- ************************************************
--- *** relation: gap                            ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A gap in the sequence of known length. T ***
--- *** He unkown bases are filled in with N's.  ***
--- ************************************************
---

CREATE VIEW gap AS
  SELECT
    feature_id AS gap_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'gap';

--- ************************************************
--- *** relation: ribozyme                       ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** An RNA with catalytic activity.          ***
--- ************************************************
---

CREATE VIEW ribozyme AS
  SELECT
    feature_id AS ribozyme_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'ribozyme';

--- ************************************************
--- *** relation: rrna_5_8s                      ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** 5.8S ribosomal RNA (5.8S rRNA) is a comp ***
--- *** onent of the large subunit of the eukary ***
--- *** otic ribosome. It is transcribed by RNA  ***
--- *** polymerase I as part of the 45S precurso ***
--- *** r that also contains 18S and 28S rRNA. F ***
--- *** unctionally, it is thought that 5.8S rRN ***
--- *** A may be involved in ribosome translocat ***
--- *** ion. It is also known to form covalent l ***
--- *** inkage to the p53 tumour suppressor prot ***
--- *** ein. 5.8S rRNA is also found in archaea. ***
--- ************************************************
---

CREATE VIEW rrna_5_8s AS
  SELECT
    feature_id AS rrna_5_8s_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'rRNA_5.8S';

--- ************************************************
--- *** relation: spliceosomal_intron            ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** An intron which is spliced by the splice ***
--- *** osome.                                   ***
--- ************************************************
---

CREATE VIEW spliceosomal_intron AS
  SELECT
    feature_id AS spliceosomal_intron_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'spliceosomal_intron';

--- ************************************************
--- *** relation: srp_rna                        ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** The signal recognition particle (SRP) is ***
--- ***  a universally conserved ribonucleoprote ***
--- *** in. It is involved in the co-translation ***
--- *** al targeting of proteins to membranes. T ***
--- *** he eukaryotic SRP consists of a 300-nucl ***
--- *** eotide 7S RNA and six proteins: SRPs 72, ***
--- ***  68, 54, 19, 14, and 9. Archaeal SRP con ***
--- *** sists of a 7S RNA and homologues of the  ***
--- *** eukaryotic SRP19 and SRP54 proteins. In  ***
--- *** most eubacteria, the SRP consists of a 4 ***
--- *** .5S RNA and the Ffh protein (a homologue ***
--- ***  of the eukaryotic SRP54 protein). Eukar ***
--- *** yotic and archaeal 7S RNAs have very sim ***
--- *** ilar secondary structures, with eight he ***
--- *** lical elements. These fold into the Alu  ***
--- *** and S domains, separated by a long linke ***
--- *** r region. Eubacterial SRP is generally a ***
--- ***  simpler structure, with the M domain of ***
--- ***  Ffh bound to a region of the 4.5S RNA t ***
--- *** hat corresponds to helix 8 of the eukary ***
--- *** otic and archaeal SRP S domain. Some Gra ***
--- *** m-positive bacteria (e.g. Bacillus subti ***
--- *** lis), however, have a larger SRP RNA tha ***
--- *** t also has an Alu domain. The Alu domain ***
--- ***  is thought to mediate the peptide chain ***
--- ***  elongation retardation function of the  ***
--- *** SRP. The universally conserved helix whi ***
--- *** ch interacts with the SRP54/Ffh M domain ***
--- ***  mediates signal sequence recognition. I ***
--- *** n eukaryotes and archaea, the SRP19-heli ***
--- *** x 6 complex is thought to be involved in ***
--- ***  SRP assembly and stabilizes helix 8 for ***
--- ***  SRP54 binding.                          ***
--- ************************************************
---

CREATE VIEW srp_rna AS
  SELECT
    feature_id AS srp_rna_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'SRP_RNA';

--- ************************************************
--- *** relation: insertion                      ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A region of sequence identified as havin ***
--- *** g been inserted.                         ***
--- ************************************************
---

CREATE VIEW insertion AS
  SELECT
    feature_id AS insertion_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'insertion';

--- ************************************************
--- *** relation: scrna                          ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Any one of several small cytoplasmic RNA ***
--- ***  moleculespresent in the cytoplasm and s ***
--- *** ometimes nucleus of a eukaryote.         ***
--- ************************************************
---

CREATE VIEW scrna AS
  SELECT
    feature_id AS scrna_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'scRNA';

--- ************************************************
--- *** relation: est_match                      ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A match against an EST sequence.         ***
--- ************************************************
---

CREATE VIEW est_match AS
  SELECT
    feature_id AS est_match_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'EST_match';

--- ************************************************
--- *** relation: clip                           ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Part of the primary transcript that is c ***
--- *** lipped off during processing.            ***
--- ************************************************
---

CREATE VIEW clip AS
  SELECT
    feature_id AS clip_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'clip';

--- ************************************************
--- *** relation: modified_base_site             ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A modified nucleotide, i.e. a nucleotide ***
--- ***  other than A, T, C. G or (in RNA) U.    ***
--- ************************************************
---

CREATE VIEW modified_base_site AS
  SELECT
    feature_id AS modified_base_site_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'modified_base_site';

--- ************************************************
--- *** relation: processed_transcript           ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A transcript which has undergone process ***
--- *** ing to remove parts such as introns and  ***
--- *** transcribed_spacer_regions.              ***
--- ************************************************
---

CREATE VIEW processed_transcript AS
  SELECT
    feature_id AS processed_transcript_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'processed_transcript';

--- ************************************************
--- *** relation: methylated_base_feature        ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A nucleotide modified by methylation.    ***
--- ************************************************
---

CREATE VIEW methylated_base_feature AS
  SELECT
    feature_id AS methylated_base_feature_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'methylated_base_feature';

--- ************************************************
--- *** relation: methylated_a                   ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A methylated adenine.                    ***
--- ************************************************
---

CREATE VIEW methylated_a AS
  SELECT
    feature_id AS methylated_a_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'methylated_A';

--- ************************************************
--- *** relation: mrna                           ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Messenger RNA is the intermediate molecu ***
--- *** le between DNA and protein. It  includes ***
--- ***  UTR and coding sequences. It does not c ***
--- *** ontain introns.                          ***
--- ************************************************
---

CREATE VIEW mrna AS
  SELECT
    feature_id AS mrna_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'mRNA';

--- ************************************************
--- *** relation: cpg_island                     ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Regions of a few hundred to a few thousa ***
--- *** nd bases in vertebrate genomes that are  ***
--- *** relatively GC and CpG rich; they are typ ***
--- *** ically unmethylated and often found near ***
--- ***  the 5' ends of genes.                   ***
--- ************************************************
---

CREATE VIEW cpg_island AS
  SELECT
    feature_id AS cpg_island_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'CpG_island';

--- ************************************************
--- *** relation: splice_site                    ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** The position where intron is excised.    ***
--- ************************************************
---

CREATE VIEW splice_site AS
  SELECT
    feature_id AS splice_site_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'splice_site';

--- ************************************************
--- *** relation: tf_binding_site                ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A region of a molecule that binds to a t ***
--- *** ranscription factor.                     ***
--- ************************************************
---

CREATE VIEW tf_binding_site AS
  SELECT
    feature_id AS tf_binding_site_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'TF_binding_site';

--- ************************************************
--- *** relation: splice_donor_site              ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** The junction between the 3 prime end of  ***
--- *** an exon and the following intron.        ***
--- ************************************************
---

CREATE VIEW splice_donor_site AS
  SELECT
    feature_id AS splice_donor_site_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'splice_donor_site';

--- ************************************************
--- *** relation: orf                            ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** The inframe interval between the stop co ***
--- *** dons of a reading frame which when read  ***
--- *** as sequential triplets, has the potentia ***
--- *** l of encoding a sequential string of ami ***
--- *** no acids. TER(NNN)nTER                   ***
--- ************************************************
---

CREATE VIEW orf AS
  SELECT
    feature_id AS orf_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'ORF';

--- ************************************************
--- *** relation: splice_acceptor_site           ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** The junction between the 3 prime end of  ***
--- *** an intron and the following exon.        ***
--- ************************************************
---

CREATE VIEW splice_acceptor_site AS
  SELECT
    feature_id AS splice_acceptor_site_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'splice_acceptor_site';

--- ************************************************
--- *** relation: enhancer                       ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A cis-acting sequence that increases the ***
--- ***  utilization of (some) eukaryotic promot ***
--- *** ers, and can function in either orientat ***
--- *** ion and in any location (upstream or dow ***
--- *** nstream) relative to the promoter.       ***
--- ************************************************
---

CREATE VIEW enhancer AS
  SELECT
    feature_id AS enhancer_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'enhancer';

--- ************************************************
--- *** relation: flanking_region                ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** The DNA sequences extending on either si ***
--- *** de of a specific locus.                  ***
--- ************************************************
---

CREATE VIEW flanking_region AS
  SELECT
    feature_id AS flanking_region_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'flanking_region';

--- ************************************************
--- *** relation: promoter                       ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** The region on a DNA molecule involved in ***
--- ***  RNA polymerase binding to initiate tran ***
--- *** scription.                               ***
--- ************************************************
---

CREATE VIEW promoter AS
  SELECT
    feature_id AS promoter_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'promoter';

--- ************************************************
--- *** relation: hammerhead_ribozyme            ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A small catalytic RNA motif that catalyz ***
--- *** es self-cleavage reaction. Its name come ***
--- *** s from its secondary structure which res ***
--- *** embles a carpenter's hammer. The hammerh ***
--- *** ead ribozyme is involved in the replicat ***
--- *** ion of some viroid and some satellite RN ***
--- *** As.                                      ***
--- ************************************************
---

CREATE VIEW hammerhead_ribozyme AS
  SELECT
    feature_id AS hammerhead_ribozyme_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'hammerhead_ribozyme';

--- ************************************************
--- *** relation: rasirna                        ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A small, 17-28-nt, small interfering RNA ***
--- ***  derived from transcripts ofrepetitive e ***
--- *** lements.                                 ***
--- ************************************************
---

CREATE VIEW rasirna AS
  SELECT
    feature_id AS rasirna_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'rasiRNA';

--- ************************************************
--- *** relation: rnase_mrp_rna                  ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** The RNA molecule essential for the catal ***
--- *** ytic activity of RNase MRP, an enzymatic ***
--- *** ally active ribonucleoprotein with two d ***
--- *** istinct roles in eukaryotes. In mitochon ***
--- *** dria it plays a direct role in the initi ***
--- *** ation of mitochondrial DNA replication.  ***
--- *** In the nucleus it is involved in precurs ***
--- *** or rRNA processing, where it cleaves the ***
--- ***  internal transcribed spacer 1 between 1 ***
--- *** 8S and 5.8S rRNAs.                       ***
--- ************************************************
---

CREATE VIEW rnase_mrp_rna AS
  SELECT
    feature_id AS rnase_mrp_rna_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'RNase_MRP_RNA';

--- ************************************************
--- *** relation: rnase_p_rna                    ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** The RNA component of Ribonuclease P (RNa ***
--- *** se P), a ubiquitous endoribonuclease, fo ***
--- *** und in archaea, bacteria and eukarya as  ***
--- *** well as chloroplasts and mitochondria. I ***
--- *** ts best characterised activity is the ge ***
--- *** neration of mature 5 prime ends of tRNAs ***
--- ***  by cleaving the 5 prime leader elements ***
--- ***  of precursor-tRNAs. Cellular RNase Ps a ***
--- *** re ribonucleoproteins. RNA from bacteria ***
--- *** l RNase Ps retains its catalytic activit ***
--- *** y in the absence of the protein subunit, ***
--- ***  i.e. it is a ribozyme. Isolated eukaryo ***
--- *** tic and archaeal RNase P RNA has not bee ***
--- *** n shown to retain its catalytic function ***
--- *** , but is still essential for the catalyt ***
--- *** ic activity of the holoenzyme. Although  ***
--- *** the archaeal and eukaryotic holoenzymes  ***
--- *** have a much greater protein content than ***
--- ***  the bacterial ones, the RNA cores from  ***
--- *** all the three lineages are homologous. H ***
--- *** elices corresponding to P1, P2, P3, P4,  ***
--- *** and P10/11 are common to all cellular RN ***
--- *** ase P RNAs. Yet, there is considerable s ***
--- *** equence variation, particularly among th ***
--- *** e eukaryotic RNAs.                       ***
--- ************************************************
---

CREATE VIEW rnase_p_rna AS
  SELECT
    feature_id AS rnase_p_rna_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'RNase_P_RNA';

--- ************************************************
--- *** relation: transcript                     ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** An RNA synthesized on a DNA or RNA templ ***
--- *** ate by an RNA polymerase.                ***
--- ************************************************
---

CREATE VIEW transcript AS
  SELECT
    feature_id AS transcript_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'transcript';

--- ************************************************
--- *** relation: regulon                        ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A group of genes, whether linked as a cl ***
--- *** uster or not, that respond to a common r ***
--- *** egulatory signal.                        ***
--- ************************************************
---

CREATE VIEW regulon AS
  SELECT
    feature_id AS regulon_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'regulon';

--- ************************************************
--- *** relation: direct_repeat                  ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A repeat where the same sequence is repe ***
--- *** ated in the same direction. Example: GCT ***
--- *** GA-----GCTGA.                            ***
--- ************************************************
---

CREATE VIEW direct_repeat AS
  SELECT
    feature_id AS direct_repeat_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'direct_repeat';

--- ************************************************
--- *** relation: transcription_start_site       ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** The site where transcription begins.     ***
--- ************************************************
---

CREATE VIEW transcription_start_site AS
  SELECT
    feature_id AS transcription_start_site_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'transcription_start_site';

--- ************************************************
--- *** relation: cds                            ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A contiguous sequence which begins with, ***
--- ***  and includes, a start codon and ends wi ***
--- *** th, and includes, a stop codon.          ***
--- ************************************************
---

CREATE VIEW cds AS
  SELECT
    feature_id AS cds_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'CDS';

--- ************************************************
--- *** relation: guide_rna                      ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A short 3'-uridylated RNA that can form  ***
--- *** a perfect duplex (except for the oligoU  ***
--- *** tail (SO:0000609)) with a stretch of mat ***
--- *** ure edited mRNA.                         ***
--- ************************************************
---

CREATE VIEW guide_rna AS
  SELECT
    feature_id AS guide_rna_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'guide_RNA';

--- ************************************************
--- *** relation: group_ii_intron                ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Group II introns are found in rRNA, tRNA ***
--- ***  and mRNA of organelles in fungi, plants ***
--- ***  and protists, and also in mRNA in bacte ***
--- *** ria. They are large self-splicing ribozy ***
--- *** mes and have 6 structural domains (usual ***
--- *** ly designated dI to dVI). A subset of gr ***
--- *** oup II introns also encode essential spl ***
--- *** icing proteins in intronic ORFs. The len ***
--- *** gth of these introns can therefore be up ***
--- ***  to 3kb. Splicing occurs in almost ident ***
--- *** ical fashion to nuclear pre-mRNA splicin ***
--- *** g with two transesterification steps. Th ***
--- *** e 2' hydroxyl of a bulged adenosine in d ***
--- *** omain VI attacks the 5' splice site, fol ***
--- *** lowed by nucleophilic attack on the 3' s ***
--- *** plice site by the 3' OH of the upstream  ***
--- *** exon. Protein machinery is required for  ***
--- *** splicing in vivo, and long range intron- ***
--- *** intron and intron-exon interactions are  ***
--- *** important for splice site positioning. G ***
--- *** roup II introns are further sub-classifi ***
--- *** ed into groups IIA and IIB which differ  ***
--- *** in splice site consensus, distance of bu ***
--- *** lged A from 3' splice site, some tertiar ***
--- *** y interactions, and intronic ORF phyloge ***
--- *** ny.                                      ***
--- ************************************************
---

CREATE VIEW group_ii_intron AS
  SELECT
    feature_id AS group_ii_intron_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'group_II_intron';

--- ************************************************
--- *** relation: intergenic_region              ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** The region between two known genes.      ***
--- ************************************************
---

CREATE VIEW intergenic_region AS
  SELECT
    feature_id AS intergenic_region_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'intergenic_region';

--- ************************************************
--- *** relation: cross_genome_match             ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A nucleotide match against a sequence fr ***
--- *** om another organism.                     ***
--- ************************************************
---

CREATE VIEW cross_genome_match AS
  SELECT
    feature_id AS cross_genome_match_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'cross_genome_match';

--- ************************************************
--- *** relation: regulatory_region              ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A DNA sequence that controls the express ***
--- *** ion of a gene.                           ***
--- ************************************************
---

CREATE VIEW regulatory_region AS
  SELECT
    feature_id AS regulatory_region_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'regulatory_region';

--- ************************************************
--- *** relation: operon                         ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A group of contiguous genes transcribed  ***
--- *** as a single (polycistronic) mRNA from a  ***
--- *** single regulatory region.                ***
--- ************************************************
---

CREATE VIEW operon AS
  SELECT
    feature_id AS operon_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'operon';

--- ************************************************
--- *** relation: clone_start                    ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** The start of the clone insert.           ***
--- ************************************************
---

CREATE VIEW clone_start AS
  SELECT
    feature_id AS clone_start_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'clone_start';

--- ************************************************
--- *** relation: pseudogenic_region             ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A non-functional descendent of a functio ***
--- *** nal entitity.                            ***
--- ************************************************
---

CREATE VIEW pseudogenic_region AS
  SELECT
    feature_id AS pseudogenic_region_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'pseudogenic_region';

--- ************************************************
--- *** relation: telomerase_rna                 ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** The RNA component of telomerase, a rever ***
--- *** se transcriptase that synthesises telome ***
--- *** ric DNA.                                 ***
--- ************************************************
---

CREATE VIEW telomerase_rna AS
  SELECT
    feature_id AS telomerase_rna_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'telomerase_RNA';

--- ************************************************
--- *** relation: u1_snrna                       ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** U1 is a small nuclear RNA (snRNA) compon ***
--- *** ent of the spliceosome (involved in pre- ***
--- *** mRNA splicing). Its 5' end forms complem ***
--- *** entary base pairs with the 5' splice jun ***
--- *** ction, thus defining the 5' donor site o ***
--- *** f an intron. There are significant diffe ***
--- *** rences in sequence and secondary structu ***
--- *** re between metazoan and yeast U1 snRNAs, ***
--- ***  the latter being much longer (568 nucle ***
--- *** otides as compared to 164 nucleotides in ***
--- ***  human). Nevertheless, secondary structu ***
--- *** re predictions suggest that all U1 snRNA ***
--- *** s share a 'common core' consisting of he ***
--- *** lices I, II, the proximal region of III, ***
--- ***  and IV.                                 ***
--- ************************************************
---

CREATE VIEW u1_snrna AS
  SELECT
    feature_id AS u1_snrna_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'U1_snRNA';

--- ************************************************
--- *** relation: decayed_exon                   ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A non-functional descendent of an exon.  ***
--- ************************************************
---

CREATE VIEW decayed_exon AS
  SELECT
    feature_id AS decayed_exon_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'decayed_exon';

--- ************************************************
--- *** relation: u2_snrna                       ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** U2 is a small nuclear RNA (snRNA) compon ***
--- *** ent of the spliceosome (involved in pre- ***
--- *** mRNA splicing). Complementary binding be ***
--- *** tween U2 snRNA (in an area lying towards ***
--- ***  the 5' end but 3' to hairpin I) and the ***
--- ***  branchpoint sequence (BPS) of the intro ***
--- *** n results in the bulging out of an unpai ***
--- *** red adenine, on the BPS, which initiates ***
--- ***  a nucleophilic attack at the intronic 5 ***
--- *** ' splice site, thus starting the first o ***
--- *** f two transesterification reactions that ***
--- ***  mediate splicing.                       ***
--- ************************************************
---

CREATE VIEW u2_snrna AS
  SELECT
    feature_id AS u2_snrna_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'U2_snRNA';

--- ************************************************
--- *** relation: u4_snrna                       ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** U4 small nuclear RNA (U4 snRNA) is a com ***
--- *** ponent of the major U2-dependent spliceo ***
--- *** some. It forms a duplex with U6, and wit ***
--- *** h each splicing round, it is displaced f ***
--- *** rom U6 (and the spliceosome) in an ATP-d ***
--- *** ependent manner, allowing U6 to refold a ***
--- *** nd create the active site for splicing c ***
--- *** atalysis. A recycling process involving  ***
--- *** protein Prp24 re-anneals U4 and U6.      ***
--- ************************************************
---

CREATE VIEW u4_snrna AS
  SELECT
    feature_id AS u4_snrna_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'U4_snRNA';

--- ************************************************
--- *** relation: u4atac_snrna                   ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** An snRNA required for the splicing of th ***
--- *** e minor U12-dependent class of eukaryoti ***
--- *** c nuclear introns. It forms a base paire ***
--- *** d complex with U6atac_snRNA (SO:0000397) ***
--- *** .                                        ***
--- ************************************************
---

CREATE VIEW u4atac_snrna AS
  SELECT
    feature_id AS u4atac_snrna_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'U4atac_snRNA';

--- ************************************************
--- *** relation: u5_snrna                       ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** U5 RNA is a component of both types of k ***
--- *** nown spliceosome. The precise function o ***
--- *** f this molecule is unknown, though it is ***
--- ***  known that the 5' loop is required for  ***
--- *** splice site selection and p220 binding,  ***
--- *** and that both the 3' stem-loop and the S ***
--- *** m site are important for Sm protein bind ***
--- *** ing and cap methylation.                 ***
--- ************************************************
---

CREATE VIEW u5_snrna AS
  SELECT
    feature_id AS u5_snrna_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'U5_snRNA';

--- ************************************************
--- *** relation: golden_path_fragment           ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** One of the pieces of sequence that make  ***
--- *** up a golden path.                        ***
--- ************************************************
---

CREATE VIEW golden_path_fragment AS
  SELECT
    feature_id AS golden_path_fragment_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'golden_path_fragment';

--- ************************************************
--- *** relation: gene_group_regulatory_region   ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A kind of regulatory region that regulat ***
--- *** es a gene_group such as an operon, rathe ***
--- *** r than an individual gene.               ***
--- ************************************************
---

CREATE VIEW gene_group_regulatory_region AS
  SELECT
    feature_id AS gene_group_regulatory_region_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'gene_group_regulatory_region';

--- ************************************************
--- *** relation: u6_snrna                       ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** U6 snRNA is a component of the spliceoso ***
--- *** me which is involved in splicing pre-mRN ***
--- *** A. The putative secondary structure cons ***
--- *** ensus base pairing is confined to a shor ***
--- *** t 5' stem loop, but U6 snRNA is thought  ***
--- *** to form extensive base-pair interactions ***
--- ***  with U4 snRNA.                          ***
--- ************************************************
---

CREATE VIEW u6_snrna AS
  SELECT
    feature_id AS u6_snrna_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'U6_snRNA';

--- ************************************************
--- *** relation: u6atac_snrna                   ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** U6atac_snRNA -An snRNA required for the  ***
--- *** splicing of the minor U12-dependent clas ***
--- *** s of eukaryotic nuclear introns. It form ***
--- *** s a base paired complex with U4atac_snRN ***
--- *** A (SO:0000394).                          ***
--- ************************************************
---

CREATE VIEW u6atac_snrna AS
  SELECT
    feature_id AS u6atac_snrna_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'U6atac_snRNA';

--- ************************************************
--- *** relation: t_element                      ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A transposon or insertion sequence. An e ***
--- *** lement that can insert in a variety of D ***
--- *** NA sequences.                            ***
--- ************************************************
---

CREATE VIEW t_element AS
  SELECT
    feature_id AS t_element_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'transposable_element';

--- ************************************************
--- *** relation: u11_snrna                      ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** U11 snRNA plays a role in splicing of th ***
--- *** e minor U12-dependent class of eukaryoti ***
--- *** c nuclear introns, similar to U1 snRNA i ***
--- *** n the major class spliceosome it base pa ***
--- *** irs to the conserved 5' splice site sequ ***
--- *** ence.                                    ***
--- ************************************************
---

CREATE VIEW u11_snrna AS
  SELECT
    feature_id AS u11_snrna_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'U11_snRNA';

--- ************************************************
--- *** relation: expressed_sequence_match       ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A match to an EST or cDNA sequence.      ***
--- ************************************************
---

CREATE VIEW expressed_sequence_match AS
  SELECT
    feature_id AS expressed_sequence_match_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'expressed_sequence_match';

--- ************************************************
--- *** relation: u12_snrna                      ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** The U12 small nuclear (snRNA), together  ***
--- *** with U4atac/U6atac, U5, and U11 snRNAs a ***
--- *** nd associated proteins, forms a spliceos ***
--- *** ome that cleaves a divergent class of lo ***
--- *** w-abundance pre-mRNA introns.            ***
--- ************************************************
---

CREATE VIEW u12_snrna AS
  SELECT
    feature_id AS u12_snrna_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'U12_snRNA';

--- ************************************************
--- *** relation: nuclease_sensitive_site        ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A region of nucleotide sequence targetin ***
--- *** g by a nuclease enzyme.                  ***
--- ************************************************
---

CREATE VIEW nuclease_sensitive_site AS
  SELECT
    feature_id AS nuclease_sensitive_site_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'nuclease_sensitive_site';

--- ************************************************
--- *** relation: clone_end                      ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** The end of the clone insert.             ***
--- ************************************************
---

CREATE VIEW clone_end AS
  SELECT
    feature_id AS clone_end_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'clone_end';

--- ************************************************
--- *** relation: polypeptide                    ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A sequence of amino acids linked by pept ***
--- *** ide bonds which may lack appreciable ter ***
--- *** tiary structure and may not be liable to ***
--- ***  irreversable denaturation.              ***
--- ************************************************
---

CREATE VIEW polypeptide AS
  SELECT
    feature_id AS polypeptide_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'polypeptide';

--- ************************************************
--- *** relation: deletion_junction              ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** The space between two bases in a sequenc ***
--- *** e which marks the position where a delet ***
--- *** ion has occured.                         ***
--- ************************************************
---

CREATE VIEW deletion_junction AS
  SELECT
    feature_id AS deletion_junction_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'deletion_junction';

--- ************************************************
--- *** relation: golden_path                    ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A set of subregions selected from sequen ***
--- *** ce contigs which when concatenated form  ***
--- *** a nonredundant linear sequence.          ***
--- ************************************************
---

CREATE VIEW golden_path AS
  SELECT
    feature_id AS golden_path_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'golden_path';

--- ************************************************
--- *** relation: cdna_match                     ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A match against cDNA sequence.           ***
--- ************************************************
---

CREATE VIEW cdna_match AS
  SELECT
    feature_id AS cdna_match_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'cDNA_match';

--- ************************************************
--- *** relation: sequence_variant               ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A region of sequence where variation has ***
--- ***  been observed.                          ***
--- ************************************************
---

CREATE VIEW sequence_variant AS
  SELECT
    feature_id AS sequence_variant_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'sequence_variant';

--- ************************************************
--- *** relation: match_set                      ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A collection of match parts              ***
--- ************************************************
---

CREATE VIEW match_set AS
  SELECT
    feature_id AS match_set_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'match_set';

--- ************************************************
--- *** relation: match_part                     ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A part of a match, for example an hsp fr ***
--- *** om blast isa match_part.                 ***
--- ************************************************
---

CREATE VIEW match_part AS
  SELECT
    feature_id AS match_part_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'match_part';

--- ************************************************
--- *** relation: tag                            ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A nucleotide sequence that may be used t ***
--- *** o identify a larger sequence.            ***
--- ************************************************
---

CREATE VIEW tag AS
  SELECT
    feature_id AS tag_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'tag';

--- ************************************************
--- *** relation: rrna                           ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** RNA that comprises part of a ribosome, a ***
--- *** nd that can provide both structural scaf ***
--- *** folding and catalytic activity.          ***
--- ************************************************
---

CREATE VIEW rrna AS
  SELECT
    feature_id AS rrna_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'rRNA';

--- ************************************************
--- *** relation: trna                           ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Transfer RNA (tRNA) molecules are approx ***
--- *** imately 80 nucleotides in length. Their  ***
--- *** secondary structure includes four short  ***
--- *** double-helical elements and three loops  ***
--- *** (D, anti-codon, and T loops). Further hy ***
--- *** drogen bonds mediate the characteristic  ***
--- *** L-shaped molecular structure. tRNAs have ***
--- ***  two regions of fundamental functional i ***
--- *** mportance: the anti-codon, which is resp ***
--- *** onsible for specific mRNA codon recognit ***
--- *** ion, and the 3' end, to which the tRNA's ***
--- ***  corresponding amino acid is attached (b ***
--- *** y aminoacyl-tRNA synthetases). tRNAs cop ***
--- *** e with the degeneracy of the genetic cod ***
--- *** e in two manners: having more than one t ***
--- *** RNA (with a specific anti-codon) for a p ***
--- *** articular amino acid; and 'wobble' base- ***
--- *** pairing, i.e. permitting non-standard ba ***
--- *** se-pairing at the 3rd anti-codon positio ***
--- *** n.                                       ***
--- ************************************************
---

CREATE VIEW trna AS
  SELECT
    feature_id AS trna_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'tRNA';

--- ************************************************
--- *** relation: sage_tag                       ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A short diagnostic sequence tag, serial  ***
--- *** analysis of gene expression (SAGE), that ***
--- ***  allows the quantitative and simultaneou ***
--- *** s analysis of a large number of transcri ***
--- *** pts.                                     ***
--- ************************************************
---

CREATE VIEW sage_tag AS
  SELECT
    feature_id AS sage_tag_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'SAGE_tag';

--- ************************************************
--- *** relation: polya_sequence                 ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** Sequence of about 100 nucleotides of A a ***
--- *** dded to the 3' end of most eukaryotic mR ***
--- *** NAs.                                     ***
--- ************************************************
---

CREATE VIEW polya_sequence AS
  SELECT
    feature_id AS polya_sequence_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'polyA_sequence';

--- ************************************************
--- *** relation: translated_nucleotide_match    ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A match against a translated sequence.   ***
--- ************************************************
---

CREATE VIEW translated_nucleotide_match AS
  SELECT
    feature_id AS translated_nucleotide_match_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'translated_nucleotide_match';

--- ************************************************
--- *** relation: branch_site                    ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A pyrimidine rich sequence near the 3' e ***
--- *** nd of an intron to which the 5'end becom ***
--- *** es covalently bound during nuclear splic ***
--- *** ing. The resulting structure resembles a ***
--- ***  lariat.                                 ***
--- ************************************************
---

CREATE VIEW branch_site AS
  SELECT
    feature_id AS branch_site_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'branch_site';

--- ************************************************
--- *** relation: polypyrimidine_tract           ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** The polypyrimidine tract is one of the c ***
--- *** is-acting sequence elements directing in ***
--- *** tron removal in pre-mRNA splicing.       ***
--- ************************************************
---

CREATE VIEW polypyrimidine_tract AS
  SELECT
    feature_id AS polypyrimidine_tract_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'polypyrimidine_tract';

--- ************************************************
--- *** relation: non_transcribed_region         ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** A region of the gene which is not transc ***
--- *** ribed.                                   ***
--- ************************************************
---

CREATE VIEW non_transcribed_region AS
  SELECT
    feature_id AS non_transcribed_region_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'non_transcribed_region';

--- ************************************************
--- *** relation: primary_transcript             ***
--- *** relation type: VIEW                      ***
--- ***                                          ***
--- *** The primary (initial, unprocessed) trans ***
--- *** cript; includes five_prime_clip (SO:0000 ***
--- *** 555), five_prime_untranslated_region (SO ***
--- *** :0000204), open reading frames (SO:00002 ***
--- *** 36), introns (SO:0000188) and three_prim ***
--- *** e_ untranslated_region (three_prime_UTR) ***
--- *** , and three_prime_clip (SO:0000557).     ***
--- ************************************************
---

CREATE VIEW primary_transcript AS
  SELECT
    feature_id AS primary_transcript_id,
    feature.*
  FROM
    feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)
  WHERE cvterm.name = 'primary_transcript';

