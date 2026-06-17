# Cover Letter

**To:** The Editor-in-Chief
**Journal:** *Briefings in Bioinformatics*
**Article type:** Problem solving protocol
**Date:** 2026-05-16
**Manuscript:** *A reusable cell-composition-adjusted re-analysis pipeline for interpreting bulk-tissue null results in low-abundance lncRNA studies: IDI2-AS1 / IL5 as a worked example across type-2 allergic diseases*

Dear Editor,

I am writing to submit the above manuscript for consideration as a Problem solving protocol in *Briefings in Bioinformatics*. The work addresses a recurring and, in our view, under-recognised interpretive failure of bulk-tissue RNA-seq analysis as it is currently applied to long noncoding RNA (lncRNA) candidates in clinical transcriptomics.

**The interpretive problem.** Standard bulk-tissue RNA-seq interpretation rests on two operations — a patient-vs-control differential-expression catalog, and a sample-level correlation between a candidate transcript and its putative target — both of which collapse two biologically distinct quantities onto a single readout for any cell-type-restricted regulator: (i) the *per-cell* expression of the regulator within its effector subset, and (ii) the *abundance* of that subset within the biopsy. In a diseased tissue, these two quantities can move in opposite directions. For a putative repressor of a type-2 effector cytokine, per-cell levels of the regulator would be expected to fall in active disease, while the effector compartment that co-expresses both the regulator and its target *expands*. A naive bulk-level analysis will then track compositional expansion rather than per-cell regulation, and may flip in sign relative to the per-cell effect. Despite the prevalence of this scenario in lncRNA research — lncRNAs are characteristically low-abundance and cell-type-restricted — there is currently no standardised framework that disentangles these two contributions from bulk transcriptomes alone.

**The pipeline.** The manuscript introduces a reusable, cell-composition-adjusted re-analysis pipeline designed to address this gap. The pipeline combines four steps that operate strictly on information recoverable from bulk RNA-seq: (1) uniform DESeq2/limma differential-expression analysis across heterogeneous cohorts with random-effects meta-analysis; (2) marker-signature-based deconvolution of disease-relevant effector-cell abundance, with CIBERSORTx-formatted inputs released for independent verification against the LM22 reference panel; (3) partial-correlation analysis of sample-level regulator–target covariation conditioning on the cell-composition signature; and (4) a bootstrap mediation decomposition that separates the bulk-level association into mediated (compositional) and direct (within-tissue, per-cell-surrogate) components. The framework is deliberately bulk-only, so that the large body of clinically annotated public bulk transcriptomic data already in GEO and ArrayExpress can be re-interrogated for cell-type-restricted lncRNA regulators without requiring single-cell or spatial re-sampling.

**The worked example.** We demonstrate the pipeline on *IDI2-AS1*, a recently identified in vitro repressor of *IL5* whose published per-cell mechanism predicts a direction that is opposite to the direction in which the *IDI2-AS1*-expressing effector compartment shifts in active type-2 disease — exactly the configuration in which the bulk-tissue interpretation problem is acute. Applied to five public RNA-seq cohorts (*n* = 856) covering asthma, atopic dermatitis, eosinophilic esophagitis, and chronic rhinosinusitis with nasal polyposis, the pipeline returns two outputs that would individually be read as opposing one another — a converging differential-expression null (pooled log<sub>2</sub>FC ≈ 0; *I*<sup>2</sup> = 0.26 %) and a positively signed sample-level *IDI2-AS1*–*IL5* correlation — and reconciles them: in the largest cohort, ≈ 90 % of the apparent covariation is attributable to shared eosinophil abundance (ACME *p* = 0.002), with no detectable within-tissue direct effect (ADE *p* = 0.76). The bulk readout is therefore most parsimoniously interpreted as compositional masking of an otherwise consistent per-cell signal — a reading that no single step of the standard workflow could supply on its own.

**Why *Briefings in Bioinformatics* is the natural home for this paper.**

- **Methodological fit.** The contribution is an analysis framework, not a single biological finding. The pipeline integrates components familiar to readers of *Briefings in Bioinformatics* (DESeq2, limma, metafor, ppcor, mediation, signature scoring, deconvolution) into a discipline for re-reading bulk-tissue null results on cell-type-restricted candidates, and explicitly defines the parameter choices and limitations of each step.
- **Reusability.** The framework is directly applicable to other in vitro–characterised lncRNA regulators whose published mechanism predicts a per-cell direction that may be inverted in bulk by simultaneous expansion of the lncRNA-expressing compartment. All code (R + Python), intermediate result tables, signature definitions, and CIBERSORTx-formatted inputs are publicly released under an MIT license at https://github.com/hidenori-tani/IDI2-AS1-allergy, with the analysis environment captured by `renv.lock` (R 4.3.2, Bioconductor 3.18).
- **Re-reading discipline.** Beyond the single use case, the manuscript supplies an explicit re-reading discipline for bulk-tissue null results on cell-type-restricted lncRNA candidates: a null result for an interesting lncRNA in a bulk catalog should be interpreted as "not seen at this granularity" rather than "not biologically active," and the cell-composition-adjusted decomposition supplies a quantitative criterion for distinguishing the two.

This is a single-author dry-analysis manuscript. The in vitro mechanistic basis for the worked example was established independently in a prior publication (Endo, Kurisu, Tani, *Biochem Biophys Res Commun* 2025); the present study performs only computational re-analysis of publicly available datasets (GSE152004, GSE121212, GSE246323, GSE58640, GSE136825), generates no new sequencing data, and required no new ethics approvals beyond those of the original studies. The manuscript has not been published and is not under consideration elsewhere, and the author declares no conflicts of interest.

Three suggested reviewers are provided in the corresponding ScholarOne fields: Dr Wolfgang Viechtbauer (Maastricht University, Netherlands; methodology — metafor random-effects meta-analysis), Dr Michael I. Love (University of North Carolina at Chapel Hill, USA; methodology — DESeq2 differential expression and apeglm shrinkage), and Dr Igor Ulitsky (Weizmann Institute of Science, Israel; lncRNA cell-type specificity and functional genomics). None has a prior collaborative relationship with the author.

Thank you for considering this submission.

Sincerely,

**Hidenori Tani, Ph.D.**
Associate Professor
Yokohama University of Pharmacy
601 Matano-cho, Totsuka-ku, Yokohama 245-0066, Japan
hidenori.tani@yok.hamayaku.ac.jp
+81-45-859-1300
ORCID: 0000-0001-6390-4136
