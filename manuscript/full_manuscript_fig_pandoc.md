---
title: "A reusable cell-composition-adjusted re-analysis pipeline for interpreting bulk-tissue null results in low-abundance lncRNA studies: IDI2-AS1 / IL5 as a worked example across type-2 allergic diseases"
author:
  - Hidenori Tani
bibliography: references.bib
csl: vancouver-superscript.csl
link-citations: true
---

# Title page

**Title.** A reusable cell-composition-adjusted re-analysis pipeline for interpreting bulk-tissue null results in low-abundance lncRNA studies: *IDI2-AS1* / *IL5* as a worked example across type-2 allergic diseases.

**Short title.** Cell-composition-adjusted bulk re-analysis of low-abundance lncRNAs.

**Author.** Hidenori Tani, Ph.D.

**Affiliation.** Department of Health Pharmacy, Yokohama University of Pharmacy, 601 Matano-cho, Totsuka-ku, Yokohama 245-0066, Japan.

**ORCID.** 0000-0001-6390-4136

**Corresponding author.**
Hidenori Tani, Ph.D.
Department of Health Pharmacy
Yokohama University of Pharmacy
601 Matano-cho, Totsuka-ku, Yokohama 245-0066, Japan
E-mail: hidenori.tani@yok.hamayaku.ac.jp
Tel: +81-45-859-1300

**Article type.** Methodology

**Word count (main text — Introduction + Methods + Results + Discussion — excluding abstract, key points, figure legends, declarations, and references).** ~ 4,100 words

**Number of figures.** 5 main + 1 supplementary

**Number of tables.** 3

**Keywords.** long noncoding RNA; bulk RNA-seq; cell-composition deconvolution; random-effects meta-analysis; partial correlation; mediation analysis.

**Publication route.** Subscription (no open access charge requested).

**Acknowledgments.** The author thanks the contributors of the public RNA-seq cohorts re-analyzed in this study (GSE152004, GSE121212, GSE246323, GSE58640, GSE136825) for making their data openly available, and the developers of DESeq2, apeglm, limma, metafor, ppcor, mediation, ComplexHeatmap, and CIBERSORTx for the open-source tools that made this analysis possible.


```{=openxml}
<w:p><w:r><w:br w:type="page"/></w:r></w:p>
```

## Key Points

- Bulk-tissue RNA-seq systematically conflates per-cell regulation with cell-composition shifts for low-abundance, cell-type-restricted lncRNAs, producing null or sign-inverted readouts that are routinely mis-read as evidence against in vivo regulatory function.

- We introduce a reusable, cell-composition-adjusted re-analysis pipeline that combines uniform DESeq2/limma differential expression with random-effects meta-analysis, marker-signature deconvolution, partial-correlation analysis conditioning on cell composition, and bootstrap mediation decomposition.

- As a worked example, the pipeline was applied to *IDI2-AS1* / *IL5* across five public RNA-seq cohorts (*n* = 856) covering four type-2 allergic diseases, reconciling a converging bulk-DE null with a sign-inverted sample-level correlation under a single interpretation.

- In the largest cohort (asthma, *n* = 695), the pipeline attributed ≈ 90 % of the bulk *IDI2-AS1*–*IL5* covariation to shared eosinophil abundance (ACME *p* = 0.002), with no detectable within-tissue direct effect (ADE *p* = 0.76).

- All analysis code, intermediate result tables, and CIBERSORTx-compatible inputs are released openly under an MIT license; the framework is directly applicable to other low-abundance, cell-type-restricted lncRNA candidates evaluated against public bulk RNA-seq cohorts.


## Abstract

**Background.** Long noncoding RNAs (lncRNAs) are typically low-abundance and cell-type-restricted, so cell-specific regulators can be invisible in bulk RNA-seq catalogs. When per-cell regulation and cell-composition shift oppose each other in a diseased biopsy, the bulk readout conflates them and a real per-cell effect may be masked, inverted, or read as null. No standardised framework separates these contributions from bulk transcriptomes.

**Approach.** We present a reusable, cell-composition-adjusted re-analysis pipeline combining (i) DESeq2/limma differential expression with random-effects meta-analysis, (ii) marker-signature deconvolution of effector-cell abundance, (iii) partial correlation conditioned on the cell-composition signature, and (iv) bootstrap mediation decomposition into direct (ADE) and mediated (ACME) components. CIBERSORTx-compatible inputs and all code are released openly.

**Worked example.** Applied to *IDI2-AS1*, a recently identified in vitro repressor of *IL5*, in five public bulk RNA-seq cohorts (*n* = 856; four type-2 allergic diseases), the pipeline returned a converging bulk-DE null (pooled log~2~FC ≈ 0; *I*^2^ = 0.26 %) and a positively signed *IDI2-AS1*–*IL5* sample-level correlation inverting the in vitro direction. Cell-composition adjustment attributed ≈ 90 % of the covariation to shared eosinophil abundance (ACME *p* = 0.002), with no detectable direct effect (ADE *p* = 0.76).

**Implications.** The pipeline prevents bulk-tissue nulls being mis-read as evidence against cell-type-restricted lncRNA function. For *IDI2-AS1*, the bulk readout is most parsimoniously explained as compositional masking; single-cell adjudication is needed. The framework applies to other low-abundance lncRNA candidates against public bulk cohorts.

**Keywords:** long noncoding RNA; bulk RNA-seq; cell-composition deconvolution; random-effects meta-analysis; partial correlation; mediation analysis; IL5; type-2 inflammation.


## Introduction

Long noncoding RNAs (lncRNAs) constitute the largest class of transcribed elements in the human genome and have emerged as a distinct regulatory layer in development, immune differentiation, and disease [@Mattick2023_lncRNAreview; @Statello2021_lncRNAfunctions]. Compared with protein-coding mRNAs, they are characteristically lower in steady-state abundance, often short-lived [@Tani2012_GenomeRes], and more cell-type-restricted in expression [@Cabili2011_lincRNAs]. These three properties have a direct consequence for translational lncRNA research using bulk transcriptomes: a regulator whose function is concentrated in a small effector subset may be biologically important in vivo while remaining effectively undetectable in standard bulk-tissue RNA-seq, because its per-cell contribution is averaged across thousands of bystander cells. Standard bulk catalogs therefore systematically under-report cell-type-restricted lncRNAs, and a null result in such a catalog cannot be interpreted as evidence against in vivo function.

The interpretive problem is sharper than simple under-detection. For any cell-type-restricted regulator, bulk RNA-seq collapses two distinct quantities onto a single readout: (i) the *per-cell* expression of the regulator inside its effector subset, and (ii) the *abundance* of that subset within the biopsy. In diseased tissue these can move in opposite directions. For a putative repressor of a type-2 effector cytokine, per-cell levels would be expected to fall in active disease, while the effector compartment that co-expresses both the regulator and its target *expands*. A naive sample-level correlation across bulk samples then tracks compositional expansion rather than per-cell regulation, and may flip in sign relative to the per-cell effect. The standard differential-expression and bulk-correlation workflow cannot distinguish "the regulator is not active" from "the regulator is active per-cell but masked by composition," and no standardised framework currently disentangles the two from bulk transcriptomes alone.

Here we present a reusable, cell-composition-adjusted re-analysis pipeline designed to close this gap (Fig. 1). The pipeline combines (i) uniform DESeq2/limma differential expression across heterogeneous cohorts with random-effects meta-analysis; (ii) marker-signature-based deconvolution of disease-relevant effector-cell abundance, with CIBERSORTx-formatted inputs released for LM22 verification; (iii) partial-correlation analysis of sample-level regulator–target covariation, conditioning on the cell-composition signature; and (iv) bootstrap mediation decomposition that splits the bulk association into a mediated (compositional) and a direct (within-tissue) component. The framework is intentionally restricted to information recoverable from bulk RNA-seq, so that it can be applied retrospectively to the large body of clinically annotated public bulk transcriptomic data.

We demonstrate the framework on *IDI2-AS1*, a recently identified in vitro repressor of *IL5* [@Endo2025_IDI2AS1], as a worked example. The choice is methodologically deliberate: *IDI2-AS1* is exactly the class of candidate for which the interpretive problem is acute — a low-abundance, cell-type-restricted lncRNA whose published mechanism predicts a per-cell direction opposite to the direction in which the *IDI2-AS1*-expressing effector compartment shifts in active type-2 disease. The *IL5* axis itself is one of the few cytokine axes in allergic disease with clinically validated protein-level interventions [@Lambrecht2019_type2review], and public bulk RNA-seq cohorts span all four major IL5-driven type-2 inflammatory diseases — asthma [@Sajuthi2020_GSE152004], atopic dermatitis [@Tsoi2018_GSE121212], eosinophilic esophagitis [@Sherrill2014_GSE58640; @Kleuskens2024_GSE246323], and chronic rhinosinusitis with nasal polyposis [@Peng2019_GSE136825] — at sample sizes sufficient to exercise each step of the pipeline.

We applied the pipeline to five such cohorts (combined *n* = 856) to ask three questions: (i) is bulk *IDI2-AS1* differentially expressed in any of these tissues; (ii) does sample-level *IDI2-AS1* abundance covary with *IL5* in the direction predicted by the in vitro repression model; and (iii) when the bulk signal departs from the in vitro prediction, can the cell-composition-adjustment step recover an interpretation consistent with the in vitro mechanism, by attributing the bulk association to compositional rather than direct effects? Our purpose is not to relitigate the in vitro *IDI2-AS1* → *IL5* mechanism, which we treat as an independent finding [@Endo2025_IDI2AS1], but to use this candidate as a transparent test case in which the pipeline must reconcile a bulk-tissue null with an in vitro per-cell effect of known direction. The framework that emerges is directly applicable to other low-abundance, cell-type-restricted lncRNA candidates evaluated against bulk-tissue cohorts.


## Methods

### Ethics

This study used only publicly available, fully de-identified RNA-seq datasets obtained with appropriate ethical approval by the original investigators. No new human or animal data were generated, and no additional ethical approval was required.

### Dataset selection and acquisition

Public bulk-tissue RNA-seq datasets from human IL5-driven allergic diseases were identified by querying GEO and ArrayExpress in March 2026. Inclusion criteria were: (i) human disease tissue with matched controls; (ii) RNA-seq at sufficient depth to detect lncRNAs; (iii) availability of per-sample raw counts or FPKM; and (iv) detection of *IDI2-AS1* (ENSG00000260196) as a non-zero feature in the supplementary expression matrix. After applying these criteria, five datasets covering four allergic diseases were retained (Table 1): asthma (GSE152004, *n* = 695 nasal epithelial brushings; @Sajuthi2020_GSE152004); atopic dermatitis (GSE121212, *n* = 65 skin biopsies; @Tsoi2018_GSE121212); eosinophilic esophagitis (GSE246323, *n* = 10; @Kleuskens2024_GSE246323; and GSE58640, *n* = 16; @Sherrill2014_GSE58640); and chronic rhinosinusitis with nasal polyposis (GSE136825, *n* = 70 nasal polyp and turbinate biopsies; @Peng2019_GSE136825). Three additional candidate datasets (GSE201955, GSE65832, GSE179269) were excluded because *IDI2-AS1* was absent from the processed matrix. For GSE136825, only patient nasal-polyp biopsies (NP, *n* = 42) and unrelated healthy-donor inferior-turbinate biopsies (Control IT, *n* = 28) were used so that case/control contrasts were structurally comparable across cohorts. Sample-to-condition mapping is documented in `data/metadata/final_datasets.csv` and the per-dataset loader scripts. Inclusion criterion (iv) restricts the conclusions to cohorts in which *IDI2-AS1* is detectably expressed at the bulk level.

### Differential expression analysis

For the four raw-count datasets (GSE152004, GSE121212, GSE246323, GSE136825), low-count features (rowSum < 10) were removed and differential expression was computed with DESeq2 (v1.42.1; @Love2014_DESeq2) under a single-factor design (`~ group`, control as reference) using the Wald test with Benjamini–Hochberg FDR correction. Effect sizes for the patient-vs-control contrast were stabilised by adaptive shrinkage with apeglm (@Zhu2019_apeglm; `lfcShrink(type = "apeglm")`), and the resulting log~2~ fold-changes and posterior standard errors were used as the input statistics for downstream meta-analysis. For the FPKM dataset (GSE58640), expression was log~2~(FPKM + 1)-transformed and analysed with limma (v3.58.1; @Ritchie2015_limma) using the `limma-trend` workflow. A focal-gene panel covering *IDI2-AS1*, four comparator lncRNAs (*MIR22HG*, *GABPB1-AS1*, *OIP5-AS1*, *LITATS1* — previously identified by our group as stress-responsive in human cells; @Abe2023_LPS; @Yagi2024_polyIC), and six type-2 / inflammatory cytokines (*IL5*, *IL4*, *IL13*, *IL6*, *TNF*, *IFNG*) was extracted from each per-dataset table; the full per-dataset tables are provided in `results/tables/`. *LITATS1* fell below the count threshold in all symbol-keyed datasets and is therefore reported only at the level of dataset-wise availability.

### Cross-disease meta-analysis

Per-dataset patient-vs-control log~2~ fold-changes and standard errors for each focal gene were combined across cohorts using random-effects meta-analysis (REML, `metafor::rma`, v4.6-0; @Viechtbauer2010_metafor). Heterogeneity was quantified with Cochran's *Q* and *I*^2^. Forest plots for *IDI2-AS1* and *IL5* were generated with `metafor::forest` (Fig. 2). Ensembl-ID rows for *IDI2-AS1* (ENSG00000260196) and *IL5* (ENSG00000113525) in the two Ensembl-keyed datasets (GSE246323 and GSE136825) were collapsed onto HGNC symbols prior to pooling. *IDI2-AS1* was pooled across all five datasets (k = 5); *IL5* across four (k = 4; below threshold in GSE246323); the comparator lncRNAs across the three symbol-keyed datasets (typically k = 3).

### Sample-level correlation and cell-type-adjusted analysis

Within each dataset, per-sample *IDI2-AS1* and *IL5* abundance was extracted from variance-stabilised counts (`DESeq2::vst(blind = TRUE)`) or from log~2~(FPKM + 1) values. Pairwise Spearman correlation was computed per dataset (Fig. 3; Table 3). To test whether bulk *IDI2-AS1*↔*IL5* covariation could be attributed to shared expression in allergic-effector cells, two compartment-specific marker-gene signatures were constructed from canonical eosinophil markers (CLC, EPX, PRG2, RNASE2, RNASE3, SIGLEC8, CCR3) and Th2 / type-2 markers (GATA3, IL4R, CCR4, PTGDR2, IL13, IL17RB). For each sample, a signature score was computed as the mean of per-gene *z*-scores. Cell-type-adjusted Spearman partial correlation between *IDI2-AS1* and *IL5* was then estimated with `ppcor::pcor.test` [@Kim2015_ppcor], conditioning on both signatures (Fig. 4 and Supplementary Fig. 1; Table 3). For the largest cohort (GSE152004 asthma, *n* = 695), a mediation-style decomposition was performed with `mediation::mediate` (v4.5.0; @Tingley2014_mediation) using *IDI2-AS1* as treatment, eosinophil signature as mediator, and *IL5* as outcome (1,000 nonparametric bootstrap resamples; percentile CIs). The eosinophil signature was used as sole mediator — rather than including Th2 in parallel — because eosinophils are the cellular endpoint of the IL5 axis and the compartment that most strongly attenuated the partial correlation. Because the data are cross-sectional observational, ACME and ADE estimates are statistical decompositions under the assumed mediator-outcome model, not strict counterfactual causal effects. The marker-signature approach was chosen over CIBERSORTx [@Newman2019_CIBERSORTx] for local reproducibility from the same count matrices; CIBERSORTx-ready CPM/FPKM input matrices are nonetheless provided in `results/intermediate/cibersortx_input/` for independent verification against the LM22 reference.

### Specificity heatmaps

To place the *IDI2-AS1* result in the context of related lncRNAs and the type-2 cytokine network, two heatmaps were produced with ComplexHeatmap (v2.18.0; @Gu2016_ComplexHeatmap) as Fig. 5A (lncRNAs) and 5B (cytokines). Per-dataset patient-vs-control log~2~ fold-changes were assembled into a gene × dataset matrix, rows ordered with the focal gene on top, and a symmetric colour scale clipped at ±4 log~2~ units.

### Code and data availability

All analysis code, intermediate result tables, and figure-generating scripts are publicly available at https://github.com/hidenori-tani/IDI2-AS1-allergy under an MIT license. Software environment is captured by `renv.lock` (R 4.3.2, Bioconductor 3.18). All input data are public GEO datasets cited above.


## Results / Application

### Pipeline Step 1: uniform differential expression and meta-analysis returns a converging bulk-tissue null for *IDI2-AS1*

To demonstrate the first stage of the pipeline, we applied uniform DESeq2 / limma-trend differential-expression analysis followed by random-effects meta-analysis to five public bulk RNA-seq cohorts spanning four allergic diseases (Fig. 1; Table 1; total *n* = 856 samples). At the per-cohort level, patient-vs-control differential expression for *IDI2-AS1* was small and non-significant in every dataset (Table 2): log~2~FC ranged from −0.234 (atopic dermatitis; *p*~adj~ = 0.41) to +0.247 (eosinophilic esophagitis, GSE58640; *p*~adj~ = 0.15). At the meta-analytic level, random-effects pooling returned an overall log~2~FC of +5.1 × 10^−5^ (95 % CI [−0.005, +0.005], *p* = 0.98) with negligible heterogeneity (*I*^2^ = 0.26 %; Fig. 2A). This null is not a pipeline failure: in the same datasets we recovered the canonical type-2 / inflammatory signature with the expected magnitude — *IL13* upregulated in atopic dermatitis (log~2~FC = +4.92, *p*~adj~ = 2 × 10^−30^) and EoE (Sherrill log~2~FC = +0.91); *IL6* and *TNF* significantly elevated in AD; and *IL5* itself upregulated in asthma (log~2~FC = +0.42, *p*~adj~ = 0.014) and EoE-Sherrill (Fig. 2B). The *I*^2^ ≈ 0 % observation for *IDI2-AS1* reflects a robust convergent finding — *all* cohorts independently report no bulk-tissue effect — not noise. Read on its own, Step 1 would be filed by standard interpretation as evidence against in vivo regulatory relevance of *IDI2-AS1*.

### Pipeline Step 2: sample-level correlation reveals a sign-inverted bulk-tissue signal

The second stage estimated sample-level Spearman correlations between *IDI2-AS1* and *IL5* in the four cohorts where both transcripts were reliably quantified (Fig. 3; Table 3). Contrary to the cell-line prediction of a negative association — the in vitro mechanism implies loss of *IDI2-AS1* → *IL5* ↑, predicting an inverse within-cell relationship — all four datasets returned a *positive* Spearman correlation: ρ = +0.109 (*p* = 0.004) in asthma (GSE152004, *n* = 695, by far the largest); ρ = +0.489 (*p* = 0.054) in EoE (*n* = 16); ρ = +0.085 (*p* = 0.48) in CRSwNP; and ρ = +0.060 (*p* = 0.63) in AD. The directional inversion between Step 1 (converging null) and Step 2 (positive bulk correlation, significant in the largest cohort) is precisely the interpretive failure mode the cell-composition-adjustment stage is designed to address.

### Pipeline Step 3: cell-composition adjustment attributes the bulk-tissue association to eosinophil abundance

The third stage tested whether the inverted-direction sample-level signal could be attributed to bulk RNA-seq mixing effector cells (Th2, ILC2, eosinophils) co-expressing both transcripts with bystander cells expressing neither. We built per-sample eosinophil and Th2 marker-signature scores (mean *z*-score across 7 eosinophil markers and 6 Th2 markers; see Methods) and re-estimated the *IDI2-AS1*↔*IL5* relationship as a partial Spearman correlation conditioning on both signatures (Fig. 4 and Supplementary Fig. 1; Table 3). Adjustment substantially attenuated the raw association in every cohort and abolished it in asthma: the asthma Spearman ρ dropped from +0.109 (*p* = 0.004) to a partial ρ of +0.052 (*p* = 0.17); EoE ρ dropped from +0.489 to +0.425 (*p* = 0.13); the AD ρ collapsed from +0.060 to +0.010 (*p* = 0.94). To formalise the contribution of the eosinophil compartment, the fourth pipeline stage — bootstrap mediation decomposition — was applied in asthma (1,000 simulations; *IDI2-AS1* as treatment, eosinophil signature as mediator, *IL5* as outcome). The average mediated effect through eosinophil composition was ACME = +0.109 (95 % CI [+0.041, +0.176], *p* = 0.002), while the average direct effect — the within-tissue residual after holding the eosinophil signature constant — was ADE = +0.012 (95 % CI [−0.075, +0.106], *p* = 0.76); the proportion mediated was 0.90. ≈ 90 % of the apparent positive *IDI2-AS1*↔*IL5* covariation in the largest patient cohort is therefore attributable to shared eosinophil abundance, and the residual within-tissue direct effect is indistinguishable from zero. The smaller cohorts were underpowered for the mediation step (AD ACME +0.054, *p* = 0.10; CRSwNP non-significant; EoE skipped at *n* < 20 threshold), so the decomposition rests on the asthma cohort, with the smaller cohorts directionally compatible but underpowered.

### Pipeline output: integration of Steps 1–3 into a single coherent reading

Combining the three outputs yields a single, internally consistent reading of the *IDI2-AS1* / *IL5* relationship in patient tissue that no single stage could supply. Step 1 produces a converging bulk-DE null; Step 2 produces a positively signed bulk correlation that inverts the cell-line direction; Step 3 attributes ≈ 90 % of the bulk-level covariation to the eosinophil compartment with no detectable within-tissue residual. The synthesis is that the bulk readout is most parsimoniously interpreted as compositional masking of an otherwise consistent per-cell signal — the per-cell signal of *IDI2-AS1* is diluted across thousands of bystander cells in which neither it nor *IL5* is meaningfully expressed, while the small effector compartment that does co-express both transcripts simultaneously expands in active disease and drives the apparent positive sample-level correlation. This is the reading the pipeline produces *automatically* from the three operations, without requiring the analyst to pre-commit to either a "no in vivo effect" or "in vitro effect generalises to tissue" interpretation.

### Specificity check: comparator lncRNAs respond to disease whereas *IDI2-AS1* does not

As a positive control, we examined the three comparator lncRNAs that passed expression filtering — *MIR22HG*, *GABPB1-AS1*, *OIP5-AS1* — in the three symbol-keyed datasets in which they were quantified (Fig. 5A). Each showed clear disease-specific differential expression: *MIR22HG* strongly upregulated in AD skin (log~2~FC = +0.82, *p*~adj~ = 1 × 10^−16^) and EoE-Sherrill; *GABPB1-AS1* significantly downregulated in AD (log~2~FC = −0.50, *p*~adj~ = 5 × 10^−3^); *OIP5-AS1* modestly downregulated in AD (log~2~FC = −0.19, *p*~adj~ = 8 × 10^−3^). Pooled meta-analysis confirmed nontrivial cross-disease signal for the comparators (*MIR22HG* pooled log~2~FC = +0.46; *GABPB1-AS1* = −0.10; *OIP5-AS1* = −0.03). Against this background, *IDI2-AS1* returned the lowest pooled effect size (+5.1 × 10^−5^) and, uniquely, near-zero between-study heterogeneity (*I*^2^ = 0.26 %). The flatness of *IDI2-AS1* at the bulk-tissue level is a property of this lncRNA specifically, not a generic feature of low-abundance lncRNAs in allergic tissue, and the pipeline distinguishes the two cases correctly.

### Specificity check: the type-2 cytokine network is appropriately disease-stratified

A complementary specificity check confirmed the analysis captures known disease biology in the expected pattern (Fig. 5B). *IL13* was the strongest disease-discriminating cytokine in AD (log~2~FC = +4.92, *p*~adj~ = 2 × 10^−30^) and elevated in EoE; *IL5* was significantly elevated in asthma and EoE-Sherrill; *IL6* and *TNF* strongly elevated in AD only; *IFNG* downregulated in asthmatic nasal epithelium but upregulated in AD skin, reflecting the known difference in IFN-γ involvement between airway and cutaneous type-2 inflammation. The cytokine panel behaves as expected from established immunology, providing a positive control against which the specific flatness of *IDI2-AS1* in the same cohorts can be interpreted with confidence. Taken together, the comparator-lncRNA and cytokine specificity checks support that the near-null bulk-tissue *IDI2-AS1* signal reflects a genuine feature of this lncRNA rather than a technical limitation of the datasets or analysis.


## Discussion

### The interpretive problem solved by cell-composition-aware re-analysis

The principal contribution of this work is methodological. Standard bulk-tissue RNA-seq interpretation rests on two operations — a differential-expression catalog comparing patients with controls, and sample-level correlation of a candidate transcript with its putative target — both of which conflate two quantities that change in disease for independent reasons: the per-cell expression of the regulator inside its effector subset, and the abundance of that subset within the biopsy. For protein-coding regulators whose function is broadly distributed across tissue cell types, this is adequate. For lncRNAs — characteristically lower in abundance, often short-lived, and frequently cell-type-restricted [@Mattick2023_lncRNAreview; @Statello2021_lncRNAfunctions; @Cabili2011_lincRNAs; @Tani2012_GenomeRes] — the same workflow systematically masks per-cell regulation behind compositional shift. The cell-composition-adjusted pipeline introduced here separates the two contributions using bulk transcriptomes alone, through four steps that can be applied to any candidate lncRNA-target pair against any sufficiently powered public bulk cohort. All code and intermediate inputs (including CIBERSORTx-formatted matrices) are released openly. The framework is deliberately scoped to information recoverable from bulk RNA-seq, so that clinically annotated bulk transcriptomic data already in the public domain can be re-interrogated without requiring single-cell or spatial re-sampling.

### Pipeline behaviour in the IDI2-AS1 worked example

The most informative property of the pipeline when applied to *IDI2-AS1* across five cohorts (combined *n* = 856) is the *combination* of three outputs that, taken individually, would point in opposite biological directions. Step 1 returns a converging bulk-DE null (pooled log~2~FC ≈ 0; *I*^2^ ≈ 0 %) — the kind of result a standard catalog would file as evidence against in vivo relevance. Step 2 returns a *positive* sample-level *IDI2-AS1*–*IL5* correlation in every cohort that supports the test, significant in asthma — opposite in sign to the in vitro repressive mechanism [@Endo2025_IDI2AS1]. Step 3 reconciles the two: when the eosinophil signature is held constant in the largest cohort, ≈ 90 % of the apparent association is statistically attributable to shared eosinophil abundance (ACME *p* = 0.002), with no detectable within-tissue residual (ADE = +0.012, *p* = 0.76). Read together, these outputs refine rather than refute the in vitro mechanism: the converging bulk null is what one would expect for a low-abundance, cell-type-restricted regulator whose per-cell signal is diluted across a predominantly bystander biopsy, and the directionally inverted bulk correlation is what one would expect when biopsies vary in the abundance of the cells co-expressing the regulator and its target. The strongest evidence comes from the asthma cohort (*n* = 695); the smaller cohorts are directionally compatible but underpowered. The pipeline performed its intended interpretive function — converting a pair of bulk outputs that would be filed in opposite directions by standard analysis into a single, mutually consistent reading.

### Why bulk RNA-seq is structurally blind to IDI2-AS1

For a regulator whose function is restricted to a small effector subset — here, presumably Th2 lymphocytes, type-2 innate lymphoid cells, mast cells, and eosinophils — per-cell *IDI2-AS1* would be expected to fall in active disease (consistent with the cell-line knock-down → *IL5* ↑ result), while the eosinophil/Th2 compartment expands. The first effect is diluted by the second, and a simple bulk mean computed across thousands of bystander epithelial or stromal cells in which neither *IDI2-AS1* nor *IL5* is meaningfully expressed is biased toward zero. The pipeline's cell-type-adjusted analysis dissects these contributions explicitly. One plausible interpretation is that the bulk signal is dominated by composition shifts and any within-effector regulatory direction is masked, rather than contradicted, by the bulk readout — consistent with the absence of *IDI2-AS1* from previously published differential-expression catalogs of these diseases. Alternative explanations — including the possibility that the in vitro effect does not generalise from the cell-line context — cannot be excluded by the present data, but the parsimonious reading is that the in vitro mechanism survives the bulk-tissue test under appropriate adjustment.

### Generalisation to other lncRNA candidates

The case made here for *IDI2-AS1* generalises beyond a single transcript. lncRNAs are characteristically lower-abundance and more cell-type-restricted than protein-coding genes [@Mattick2023_lncRNAreview], so the per-cell signal of an authentic regulator is more easily diluted in bulk tissue than the signal of a typical mRNA. Searching for "lncRNAs that are differentially expressed in disease tissue" — the standard catalog operation — will systematically miss regulators that act inside small effector subsets, even when their downstream protein-coding targets (here, *IL5*, *IL13*) are themselves easily detected. The pipeline is directly applicable to other in vitro–characterised lncRNA regulators whose published mechanism predicts a per-cell direction that may be inverted in bulk by simultaneous expansion of the lncRNA-expressing compartment in disease; the analytic decision is the choice of cell-composition signature (eosinophil and Th2 here, but extendable to ILC2, mast-cell, regulatory-T, dendritic-cell, or epithelial-progenitor signatures) and of public cohorts large enough to support the mediation step. The pipeline supplies an explicit re-reading discipline: a null result for an interesting lncRNA in a bulk catalog should be interpreted as "not seen at this granularity" rather than "not biologically active," and the cell-composition adjustment supplies a quantitative criterion for distinguishing the two. Single-cell airway atlases [@Travaglini2020_lungatlas] provide the natural orthogonal substrate against which the pipeline's predictions can be tested for any specific candidate.

### Translational context

The worked example sits in a clinically tractable axis: *IL5* is the validated target of three anti-eosinophil biologics — mepolizumab and reslizumab (anti-IL5), benralizumab (anti-IL5Rα) — approved for severe eosinophilic asthma and (for mepolizumab) CRSwNP [@Bel2014_mepolizumab; @Bachert2017_mepoCRSwNP]. Anti-IL13 strategies have shown histologic and endoscopic improvement in eosinophilic esophagitis [@Hirano2019_EoEbiologic]. The clinical success of these axes is direct evidence that *IL5* — and the type-2 effector network of which it is part — is dose-limiting for the eosinophilic phenotype, which in turn implies that upstream regulators of *IL5*, including non-coding regulators, are mechanistically of interest. The pipeline's output for *IDI2-AS1* does not establish it as an immediate clinical biomarker (bulk-tissue expression is flat) and does not establish it as a therapeutic target. What the pipeline does support is the prioritisation of cell-type-resolved follow-up of this lncRNA, in preference to further bulk-tissue profiling.

### Limitations of the framework and the worked example

Limitations apply to both the pipeline and its application here. (i) The cell-type-adjustment step uses a marker-gene signature score rather than a deconvolution algorithm such as CIBERSORTx; we chose this for full local reproducibility and provide CIBERSORTx-formatted inputs for confirmation against the LM22 reference, but the marker-score approach treats the eosinophil and Th2 compartments as one-dimensional summaries. (ii) The mediation decomposition requires sample sizes large enough to support stable bootstrap estimates of ACME and ADE; this condition is met only in the asthma cohort (*n* = 695), and directionally consistent but underpowered estimates in AD, CRSwNP, and EoE await replication. (iii) Because the underlying data are cross-sectional observational, the ACME / ADE values are statistical decompositions under the assumed mediator-outcome model, not strict counterfactual causal effects. (iv) We relied on public datasets not designed for lncRNA discovery; library preparation and depth differ between cohorts, and the inclusion criterion required *IDI2-AS1* to be a non-zero feature in each retained dataset. (v) Meta-analysis pools log~2~FC across biologically distinct tissues; every cohort independently converged on a near-null bulk-tissue effect, which is the substantive observation, but pooled effect sizes are summary statistics of cohort-level convergence rather than a single biological estimand. (vi) The pipeline is bulk-only by design; it cannot replace single-cell or spatial transcriptomics, and its purpose is to extract maximally defensible interpretation from bulk data and nominate candidates for cell-resolved follow-up. (vii) The central biological interpretation in the worked example — that per-cell *IDI2-AS1* falls in active disease but is masked by simultaneous expansion of the *IDI2-AS1*-expressing compartment — is a hypothesis generated by the pipeline, not a direct measurement; the decisive experiment is single-cell or spatial transcriptomics. Future work should (a) re-examine *IDI2-AS1* and its regulatory circuit in single-cell airway and skin atlases, (b) test whether *IDI2-AS1* knock-down in primary human Th2 cells phenocopies the cell-line phenotype, (c) ask whether per-cell *IDI2-AS1* responds to therapeutic modulation in single-cell profiling of patients before and during anti-IL5 or anti-IL13 biologic therapy, and (d) apply the same pipeline to additional in vitro–characterised lncRNA regulators that fit the low-abundance, cell-type-restricted profile.

### Summary

We have introduced a reusable, cell-composition-adjusted re-analysis pipeline that separates compositional from per-cell regulatory contributions to bulk-tissue RNA-seq signals for low-abundance, cell-type-restricted lncRNA candidates. As a worked example, the pipeline was applied to *IDI2-AS1* across five public RNA-seq cohorts (*n* = 856) covering four type-2 allergic diseases. In the largest cohort the pipeline attributed ≈ 90 % of the bulk-level *IDI2-AS1*–*IL5* covariation to shared eosinophil abundance, with no detectable within-tissue direct effect, converting a pair of bulk outputs that would individually be read as opposing one another into a single, mutually consistent reading: any per-cell *IDI2-AS1* → *IL5* effect operating in patient effector cells is masked rather than contradicted by the bulk readout. Whether the in vitro mechanism actually operates in patient cells will require single-cell or spatial transcriptomics for adjudication. Beyond the *IDI2-AS1* case, the pipeline is directly applicable to other low-abundance, cell-type-restricted lncRNA candidates whose bulk-tissue null results might otherwise be mis-read as evidence against in vivo relevance, and supplies an explicit re-reading discipline for the large body of clinically annotated bulk transcriptomic data already in the public domain.


## Declarations

### Funding

No funding was received for conducting this study.

### Clinical trial number

Clinical trial number: not applicable.

### Competing interests

The author has no relevant financial or non-financial interests to disclose.

### Ethics approval

This study used only publicly available, fully de-identified RNA-seq datasets obtained with appropriate ethical approval by the original investigators. No new human or animal data were generated, and no additional ethical approval was required for this retrospective re-analysis of fully de-identified public data.

### Consent to participate

Not applicable. The study did not involve new human participants; all data were obtained from publicly available, fully de-identified datasets.

### Consent for publication

Not applicable.

### Data availability

All datasets re-analyzed in this study are publicly available from the NCBI Gene Expression Omnibus (GEO) under accession numbers GSE152004 (asthma; @Sajuthi2020_GSE152004), GSE121212 (atopic dermatitis; @Tsoi2018_GSE121212), GSE58640 (eosinophilic esophagitis; @Sherrill2014_GSE58640), GSE246323 (eosinophilic esophagitis; @Kleuskens2024_GSE246323), and GSE136825 (chronic rhinosinusitis with nasal polyposis; @Peng2019_GSE136825).

### Code availability

All analysis code, intermediate result tables, and figure-generating scripts are publicly available at https://github.com/hidenori-tani/IDI2-AS1-allergy under an MIT license. The R software environment is captured by `renv.lock` (R 4.3.2, Bioconductor 3.18) for full reproducibility.

### Author contributions

**Hidenori Tani (ORCID: 0000-0001-6390-4136):** Conceptualization, Data curation, Formal analysis, Investigation, Methodology, Software, Validation, Visualization, Writing – original draft, Writing – review & editing.

### Use of generative AI

During the preparation of this manuscript, the author used Anthropic Claude Code (Claude Opus 4.7) as a writing and coding assistant to help draft and refine analysis scripts, figure-generation code, and manuscript text. All scientific content, analytical decisions, and final wording were reviewed, edited, and verified by the author, who takes full responsibility for the content of the publication. The use of this tool is also documented in the Methods section of the manuscript.


## Figure legends

<!--
v2 (BBRC revision BBRC-26-2497, 2026-05-12) - internal notes (not for submission):
- Fig. 4 now has two panels (A: raw scatter, B: eosinophil signature) only; the
  former bottom row (Th2 / type-2 signature) is now Supplementary Figure 1.
- Figure 1 finding box uses plain text with Unicode glyphs.
- All other legend text is unchanged.
-->

**Fig. 1. Study design and analytical workflow.** Single-panel schematic organized as four vertical stages. **Stage 1 (Datasets):** the five public bulk RNA-seq cohorts re-analyzed in this study, spanning four IL5-driven allergic diseases — asthma (GSE152004, *n* = 695, nasal epithelium), atopic dermatitis (GSE121212, *n* = 65, skin biopsy), eosinophilic esophagitis (GSE246323, *n* = 10 and GSE58640, *n* = 16, esophageal biopsy), and chronic rhinosinusitis with nasal polyposis (GSE136825, *n* = 70, nasal polyp). **Stage 2 (Uniform pipeline):** the five sequential analytical steps applied to every dataset — (i) per-dataset differential expression (DESeq2 + apeglm for raw counts, limma-trend for FPKM), (ii) random-effects meta-analysis across cohorts (`metafor::rma`, REML), (iii) sample-level Spearman correlation between *IDI2-AS1* and *IL5*, (iv) cell-type-adjusted partial correlation conditioning on eosinophil and Th2 marker-gene signature scores, and (v) bootstrap mediation-style decomposition in the asthma cohort (1 000 resamples). **Stage 3 (Three in vivo questions):** Q1 — is *IDI2-AS1* itself differentially expressed in disease tissue? Q2 — do *IDI2-AS1* and *IL5* covary at the sample level in the predicted (negative) direction? Q3 — if the bulk-tissue signal departs from the in vitro prediction, can it be ascribed to cell-composition shifts? **Stage 4 (Principal finding):** bulk-tissue *IDI2-AS1* is invariant in every cohort (pooled log~2~FC ≈ 0; *I*^2^ = 0.26 %); sample-level *IDI2-AS1* ↔ *IL5* is positive in every testable cohort (opposite to the in vitro prediction); in the asthma cohort, ≈ 90 % of that positive association is attributed to the eosinophil compartment (ACME = +0.109, *p* = 0.002), with a within-tissue direct effect indistinguishable from zero (ADE = +0.012, *p* = 0.76). The schematic makes the central interpretive arc visible at a glance: bulk DE → bulk correlation → cell-composition adjustment → within-tissue residual.

**Fig. 2. *IDI2-AS1* and *IL5* random-effects meta-analysis across five allergic-disease cohorts.** **(A)** Forest plot for *IDI2-AS1* (k = 5 datasets). Per-dataset DESeq2 + apeglm or limma-trend log~2~FC estimates with 95 % confidence intervals are shown for each cohort, with the random-effects pooled estimate (REML, `metafor::rma`) at the bottom. The pooled estimate is +5.1 × 10^−5^ (95 % CI [−0.005, +0.005]; *p* = 0.98), with negligible between-study heterogeneity (*I*^2^ = 0.26 %; Cochran's *Q* *p* = 0.47), indicating that all five datasets independently agree on the absence of a bulk-tissue effect. **(B)** Forest plot for *IL5* (k = 4; *IL5* was below the rowSum ≥ 10 count threshold in GSE246323 and is therefore not included in this meta-analysis). Pooled log~2~FC = +0.22 (95 % CI [−0.15, +0.58]; *p* = 0.25), with substantial heterogeneity driven by the strong asthma and EoE-Sherrill effects (*I*^2^ = 82 %).

**Fig. 3. Sample-level *IDI2-AS1* ↔ *IL5* covariation per cohort.** Per-sample *IDI2-AS1* vs *IL5* abundance (variance-stabilized counts for raw-count datasets, log~2~(FPKM + 1) for GSE58640) in the four cohorts where both transcripts are reliably quantified. Each panel is one cohort, with patients and controls overlaid (colour key: control vs patient, shown at the bottom of the figure). Spearman correlations: asthma ρ = +0.109, *p* = 0.004 (*n* = 695); EoE (Sherrill) ρ = +0.489, *p* = 0.054 (*n* = 16); CRSwNP ρ = +0.085, *p* = 0.48 (*n* = 70); atopic dermatitis ρ = +0.060, *p* = 0.63 (*n* = 65). All four cohorts show *positive* covariation — the opposite of the negative direction predicted by the in vitro repressive mechanism reported in @Endo2025_IDI2AS1.

**Fig. 4. Cell-type adjustment dissolves the asthma *IDI2-AS1* ↔ *IL5* association.** **(A)** Raw sample-level *IDI2-AS1* (x-axis) vs *IL5* (y-axis) scatter, one panel per cohort (same data as Fig. 3, shown here at uniform aspect ratio for direct visual comparison with panel B). **(B)** *IDI2-AS1* (x-axis) vs the eosinophil marker-signature score (y-axis, mean *z*-score across *CLC*, *EPX*, *PRG2*, *RNASE2*, *RNASE3*, *SIGLEC8*, *CCR3*), one panel per cohort. Signatures are standardized within each cohort. The strong positive association between *IDI2-AS1* and the eosinophil signature in the asthma cohort, mirrored by the *IDI2-AS1* ↔ *IL5* association in the same cohort (panel A), is the visual basis for the cell-composition explanation formally quantified as a partial Spearman correlation and a bootstrap mediation-style decomposition in Table 3. The complementary *IDI2-AS1* vs Th2 / type-2 marker-signature scatter is shown as Supplementary Figure 1.

**Fig. 5. Specificity panels — comparator lncRNAs and type-2 cytokines across the disease cohorts.** **(A)** Heatmap of patient-vs-control log~2~ fold-changes for *IDI2-AS1* and three comparator lncRNAs (*MIR22HG*, *GABPB1-AS1*, *OIP5-AS1*) across all five cohorts. Rows: lncRNAs, anchored on *IDI2-AS1*. Columns: cohorts, with per-cohort total sample size annotated above. Colour scale: symmetric around zero (blue = downregulated in patients; red = upregulated), clipped at ±1 log~2~ unit (which spans the full observed range for these lncRNAs). Comparator lncRNAs show clear disease-specific differential expression (e.g. *MIR22HG* +0.82 in atopic dermatitis, *GABPB1-AS1* −0.50 in atopic dermatitis), whereas *IDI2-AS1* is uniquely flat in every cohort. The three comparator lncRNAs are matched by HGNC symbol only and therefore appear as empty cells in the two Ensembl-keyed cohorts (GSE246323 and GSE136825); the a-priori fourth comparator *LITATS1* fell below the rowSum ≥ 10 count threshold in every symbol-keyed allergic-tissue dataset and is therefore not displayed. *IDI2-AS1* (matched on both HGNC symbol and Ensembl ID) is uniquely quantified in all five cohorts. **(B)** Heatmap of patient-vs-control log~2~ fold-changes for six type-2 / inflammatory cytokines (*IL5*, *IL4*, *IL13*, *IL6*, *TNF*, *IFNG*) across four cohorts (GSE152004, GSE121212, GSE58640, GSE136825; GSE246323 is not shown because these cytokine symbols were not recoverable from its Ensembl-keyed matrix). Colour conventions are the same as in panel A, but the scale is clipped at ±4 log~2~ units to accommodate the *IL13*-in-AD outlier (+4.92). *IL13* is strongly elevated in atopic dermatitis (log~2~FC = +4.92, *p*~adj~ = 2 × 10^−30^) and in EoE-Sherrill (+0.91, *p*~adj~ = 2 × 10^−5^); *IL5* is elevated in asthma (+0.42, *p*~adj~ = 0.014) and in EoE-Sherrill (+0.61, *p*~adj~ = 0.002); *IL6* and *TNF* are strongly elevated in atopic dermatitis only; *IFNG* is downregulated in asthmatic nasal epithelium (−0.66, *p*~adj~ = 5 × 10^−7^) but upregulated in atopic-dermatitis skin (+1.43). The cytokine panel behaves as expected from established type-2 immunology, providing a positive control against which the specific flatness of *IDI2-AS1* in the same cohorts can be interpreted.

## Supplementary Figure legends

**Supplementary Fig. 1. *IDI2-AS1* vs Th2 / type-2 marker signature per cohort.** Per-sample *IDI2-AS1* (x-axis) vs Th2 / type-2 marker-signature score (y-axis, mean *z*-score across *GATA3*, *IL4R*, *CCR4*, *PTGDR2*, *IL13*, *IL17RB*) in each of the five cohorts. Signatures are standardized within each cohort. This panel complements Fig. 4B (eosinophil signature) and shows the cohort-by-cohort relationship between *IDI2-AS1* and the broader type-2 effector compartment.


