# Cover Letter

**To:** The Editor-in-Chief
**Journal:** *Biochemical and Biophysical Research Communications* (BBRC)
**Article type:** Full-Length Research Paper
**Date:** 2026-04-24
**Manuscript:** *Bulk tissue transcriptomes obscure the IDI2-AS1 / IL5 relationship through cell-composition effects across four type-2 allergic diseases*

Dear Editor,

I am writing to submit the above manuscript for consideration as a Full-Length Research Paper in *Biochemical and Biophysical Research Communications*. This work is the direct in vivo-context companion to our recent mechanistic study in this journal — Endo, Kurisu, Tani, *Biochem Biophys Res Commun* 2025 — in which we identified the long noncoding RNA *IDI2-AS1* as a negative regulator of interleukin 5 (*IL5*) through siRNA knock-down in HuT78 T-cells with orthogonal validation in A549 epithelial cells. The natural follow-up question — whether the same regulatory axis is detectable in patient tissue from human IL5-driven allergic disease — is directly addressed here, and the two papers together form a paired in vitro / in vivo reading of one lncRNA–cytokine circuit.

To answer this, I performed a uniform re-analysis of five public bulk RNA-seq cohorts (*n* = 856 samples) covering four IL5-driven allergic diseases: asthma, atopic dermatitis, eosinophilic esophagitis, and chronic rhinosinusitis with nasal polyposis. Three findings define the contribution of this manuscript:

1. **Tissue-bulk *IDI2-AS1* expression is invariant in every cohort** (random-effects pooled log<sub>2</sub>FC ≈ 0; *I*<sup>2</sup> = 0.26 % — a converging null across studies, not noise).

2. **Sample-level *IDI2-AS1* and *IL5* covary positively** in every testable cohort (significantly so in the largest, asthma, *n* = 695), which is the *opposite* of the within-cell repressive direction predicted by our in vitro mechanism.

3. **A mediation-style decomposition** in the asthma cohort attributes ≈ 90 % of that covariation to shared expression in the eosinophil compartment (ACME = +0.109, *p* = 0.002), with a within-tissue direct effect indistinguishable from zero (ADE = +0.012, *p* = 0.76).

Bulk patient transcriptomes therefore do not recover the predicted in vitro repressive direction. The pattern is compatible with masking of any per-cell *IDI2-AS1* → *IL5* effect by eosinophil-driven shifts in tissue cell composition — the per-cell signal of a cell-type-restricted lncRNA regulator is averaged across thousands of bystander cells, while the eosinophil compartment that co-expresses both transcripts simultaneously expands in active disease — although we cannot exclude the alternative that the in vitro repression does not generalize to patient cells. Both possibilities require cell-type-resolved follow-up for adjudication.

**Why *BBRC* is the natural home for this paper.** Three reasons:

- **Scientific continuity.** The in vitro mechanism that this study tests in vivo was published in *BBRC* 2025 by the same group. Readers of the 2025 paper are the natural audience for the present re-analysis, which directly addresses the in vivo question that the 2025 manuscript left open.
- **Methodological fit.** Beyond the *IDI2-AS1*/*IL5* case, the paper introduces a reusable cell-composition-adjusted re-analysis pipeline (partial correlation conditioning on marker-signature scores, followed by bootstrap mediation decomposition) that is directly applicable to other low-abundance, cell-type-restricted lncRNA candidates. All code is publicly released under an MIT license.
- **Journal scope.** The lncRNA–cytokine regulatory circuit, the bulk-vs-single-cell interpretive problem it exposes, and the transcriptomic decomposition framework are squarely within the biochemical / molecular biology scope of *BBRC*.

This is a single-author dry-analysis manuscript. The wet-lab mechanistic basis was published independently in *BBRC* 2025; the present study performs only computational re-analysis of publicly available datasets (GSE152004, GSE121212, GSE246323, GSE58640, GSE136825), generates no new sequencing data, and required no new ethics approvals beyond those of the original studies. The manuscript has not been published and is not under consideration elsewhere, and the author declares no conflicts of interest.

Suggested handling editors and reviewers can be provided on request.

Thank you for considering this submission.

Sincerely,

**Hidenori Tani, Ph.D.**
Associate Professor
Yokohama University of Pharmacy
601 Matano-cho, Totsuka-ku, Yokohama 245-0066, Japan
hidenori.tani@yok.hamayaku.ac.jp
+81-45-859-1300
ORCID: 0000-0001-6390-4136
