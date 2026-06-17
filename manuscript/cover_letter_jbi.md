# Cover Letter

**To:** The Editor-in-Chief
**Journal:** *Journal of Biomedical Informatics*
**Article type:** Methods / Original research (methodology)
**Date:** 2026-06-17
**Manuscript:** *A reusable cell-composition-adjusted re-analysis pipeline for interpreting bulk-tissue null results in low-abundance lncRNA studies: IDI2-AS1 / IL5 as a worked example across type-2 allergic diseases*

Dear Editor-in-Chief,

I am pleased to submit the above manuscript for consideration in the *Journal of Biomedical Informatics*. The work contributes a **reusable analytical methodology of general applicability** for a recurring inference problem in the re-use of public biomedical transcriptomic data: how to interpret a bulk-tissue RNA-seq null or sign-inverted result for a low-abundance, cell-type-restricted molecular feature, when the bulk readout conflates per-cell regulation with shifts in cell composition. The method is demonstrated on a single concrete case (*IDI2-AS1* / *IL5* across five public cohorts, *n* = 856), but the methodological contribution — and the released, reusable software — is the primary subject of the paper.

**The methodological problem.** A large fraction of biomedical-informatics analysis now consists of re-interrogating public bulk transcriptomes (GEO, ArrayExpress) that were not designed for the question being asked. Two standard operations — a case-vs-control differential-expression catalog and a sample-level correlation between a candidate feature and its putative target — each collapse two biologically distinct quantities onto one readout for any cell-type-restricted feature: the *per-cell* expression of the feature within its effector subset, and the *abundance* of that subset within the sample. When these move in opposite directions across samples, the bulk readout can be masked, inverted, or read as null, leading to incorrect inferences from otherwise high-quality public data. No standardised, reusable workflow currently isolates these two contributions from bulk data alone.

**The method.** The manuscript introduces a four-stage pipeline that operates strictly on information recoverable from bulk RNA-seq: (1) uniform differential expression across heterogeneous cohorts with random-effects meta-analysis; (2) estimation of effector-cell abundance, computed both with a transparent marker-signature score and, independently, with transcriptome-wide deconvolution (xCell); (3) partial correlation of the feature–target association conditioned on cell-composition; and (4) a bootstrap decomposition of the observed cross-sectional association into composition-attributable and residual components — reported explicitly as a statistical partition under a linear model, not a causal effect. A key methodological result is a cross-method robustness check: the two abundance estimators agree (Spearman ρ = 0.62) and yield the same qualitative conclusion, and we document a concrete pitfall — the default spillover-compensation step of off-the-shelf deconvolution floors a rare, spillover-prone cell type in epithelial samples and would have produced a spuriously null adjustment if used uncritically.

**The worked example.** Applied to *IDI2-AS1*, an in vitro repressor of *IL5*, across asthma, atopic dermatitis, eosinophilic esophagitis, and chronic rhinosinusitis with nasal polyposis, the pipeline reconciles two outputs that would individually be read as opposing one another — a converging differential-expression null (pooled log<sub>2</sub>FC ≈ 0; *I*<sup>2</sup> = 0.26 %) and a positively signed bulk *IDI2-AS1*–*IL5* correlation. In the only adequately powered cohort (asthma, *n* = 695), the majority of the bulk covariation is attributable to shared eosinophil abundance — ≈ 90 % under the marker signature and ≈ 70 % under independent deconvolution (both *p* ≤ 0.006) — with no detectable within-tissue residual. The bulk readout is therefore most parsimoniously interpreted as compositional masking: a hypothesis for cell-resolved follow-up, not a validated mechanism. The quantitative claim is restricted to the asthma cohort; the smaller cohorts are underpowered and mixed in direction and are presented as qualitative context only, which is stated explicitly.

**Fit with the *Journal of Biomedical Informatics*.**

- **A new methodology of general applicability.** The contribution is a reusable analytical workflow for re-using public biomedical data, not a single biological finding. It integrates established components (differential expression, meta-analysis, deconvolution, partial correlation, effect decomposition) into a defined inference discipline, with explicit parameter choices, a cross-method robustness check, a documented failure mode, and an unmeasured-confounding sensitivity analysis. This matches the journal's remit for novel methodologies and techniques with general applicability to biomedical data.
- **Reproducibility and reuse.** All code (R + Python), intermediate result tables, signature definitions, and deconvolution inputs are publicly released under an MIT license at https://github.com/hidenori-tani/IDI2-AS1-allergy, with the analysis environment captured by `renv.lock`. The pipeline is directly applicable to other low-abundance, cell-type-restricted features whose bulk-tissue null results might otherwise be mis-read as evidence against in vivo relevance.
- **A portable re-reading discipline.** A null result for a cell-type-restricted feature in a bulk catalog should be interpreted as "not seen at this granularity" rather than "not biologically active," and the cell-composition-adjusted decomposition supplies a quantitative criterion for distinguishing the two — a discipline portable to any biomedical study re-using clinically annotated bulk transcriptomes.

**Submission details.** This is a single-author dry-analysis manuscript. The in vitro basis for the worked example was established independently in a prior publication (Endo, Kurisu, Tani, *Biochem Biophys Res Commun* 2025); the present study performs only computational re-analysis of publicly available datasets (GSE152004, GSE121212, GSE246323, GSE58640, GSE136825), generates no new data, and required no new ethics approvals. The manuscript has not been published and is not under consideration elsewhere, and the author declares no competing interests. **I have selected the subscription publication route** (no open access / article publishing charge requested). Use of an AI coding/writing assistant is disclosed in full, including the boundary of its involvement in analytical decisions.

**Suggested reviewers.** Dr Wolfgang Viechtbauer (Maastricht University, Netherlands; random-effects meta-analysis methodology, metafor), Dr Michael I. Love (University of North Carolina at Chapel Hill, USA; differential-expression methodology, DESeq2/apeglm), and Dr Igor Ulitsky (Weizmann Institute of Science, Israel; lncRNA cell-type specificity and functional genomics). None has a prior collaborative relationship with the author.

Thank you for considering this submission.

Sincerely,

**Hidenori Tani, Ph.D.**
Associate Professor
Department of Health Pharmacy
Yokohama University of Pharmacy
601 Matano-cho, Totsuka-ku, Yokohama 245-0066, Japan
hidenori.tani@yok.hamayaku.ac.jp
+81-45-859-1300
ORCID: 0000-0001-6390-4136
