# Paper-ready Tables

> Auto-generated from `data/metadata/final_datasets.csv` and `results/tables/*.csv`.
> Format: GitHub-flavored Markdown. For Word/LaTeX submission, paste into a table tool
> and apply Frontiers Original Research table style (sans-serif, no vertical rules).

---

## Table 1. Public bulk RNA-seq cohorts re-analyzed in this study

| Disease | GEO accession | Tissue | Patients (n) | Controls (n) | Total | Platform | Quantification | Reference |
|---|---|---|:-:|:-:|:-:|---|---|---|
| Asthma | GSE152004 | Nasal epithelium (brushing) | 388 | 307 | 695 | Illumina HiSeq 2000 | Raw counts | Sajuthi et al., 2020 |
| Atopic dermatitis | GSE121212 | Lesional skin / healthy control biopsy | 27 | 38 | 65 | Illumina HiSeq 2500 | Raw counts | Tsoi et al., 2019 |
| Eosinophilic esophagitis | GSE246323 | Esophageal biopsy (baseline) | 5 | 5 | 10 | Illumina NovaSeq 6000 | Raw counts | Kleuskens et al., 2024 |
| Eosinophilic esophagitis | GSE58640 | Esophageal biopsy | 10 | 6 | 16 | Illumina HiSeq 2000 | FPKM | Sherrill et al., 2014 |
| Chronic rhinosinusitis with nasal polyposis | GSE136825 | Nasal polyp tissue / control inferior turbinate | 42 | 28 | 70 | Illumina HiSeq 4000 | Raw counts (featureCounts) | Peng et al., 2019 |
| **Combined** |  |  | **472** | **384** | **856** |  |  |  |

*Three additional candidate datasets (GSE201955, GSE65832, GSE179269) were excluded because IDI2-AS1 was absent from the available processed expression matrix or because per-sample raw data could not be recovered without re-quantification from SRA. For GSE136825, paired within-patient nasal-polyp / inferior-turbinate samples (NP_IT, n = 33) were excluded so that the case/control contrast in this cohort was structurally comparable to the four other cohorts (NP tissue vs healthy-donor inferior turbinate).*

---

## Table 2. Per-dataset and meta-analytic patient-vs-control differential expression for *IDI2-AS1* and *IL5*

| Gene | Disease | GEO | Method | log₂FC | SE | *p*<sub>adj</sub> |
|---|---|---|---|:-:|:-:|:-:|
| **IDI2-AS1** | Asthma | GSE152004 | DESeq2 + apeglm | +0.0015 | 0.033 | 0.94 |
|  | Atopic dermatitis | GSE121212 | DESeq2 + apeglm | −0.234 | 0.274 | 0.41 |
|  | Eos. esophagitis | GSE246323 | DESeq2 + apeglm | −0.036 | 0.145 | 0.50 |
|  | Eos. esophagitis | GSE58640 | limma-trend | +0.247 | 0.148 | 0.15 |
|  | CRSwNP | GSE136825 | DESeq2 + apeglm | −2.8 × 10⁻⁶ | 0.0014 | 0.54 |
|  | **Meta-analysis (k = 5)** |  | REML | **+5.1 × 10⁻⁵** | [−0.005, +0.005] | **0.98** |
|  | *Heterogeneity* |  |  |  | *I*² = 0.26 % |  *Q* p = 0.47 |
| **IL5** | Asthma | GSE152004 | DESeq2 + apeglm | **+0.424** | 0.232 | **0.014** |
|  | Atopic dermatitis | GSE121212 | DESeq2 + apeglm | −0.264 | 0.325 | 0.39 |
|  | Eos. esophagitis | GSE58640 | limma-trend | **+0.609** | 0.159 | **0.002** |
|  | CRSwNP | GSE136825 | DESeq2 + apeglm | +1.0 × 10⁻⁶ | 0.0014 | 0.78 |
|  | **Meta-analysis (k = 4)** |  | REML | +0.216 | [−0.148, +0.580] | 0.25 |
|  | *Heterogeneity* |  |  |  | *I*² = 82.0 % | *Q* p = 3.3 × 10⁻⁴ |

*IL5 was below the rowSum ≥ 10 count threshold in GSE246323 and is therefore not included in the IL5 meta-analysis. Bolded p-values reach a conventional p < 0.05 cutoff; meta-analytic estimates use a random-effects REML model (`metafor::rma`).*

---

## Table 3. Sample-level *IDI2-AS1* ↔ *IL5* association: raw, cell-type-adjusted, and causal mediation

| Cohort | n | **Raw Spearman ρ** | raw *p* | **Partial ρ** (\| eos + Th2) | partial *p* | ACME (eos.) | ACME 95 % CI | ACME *p* | ADE | ADE *p* | Prop. mediated |
|---|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| **Asthma** (GSE152004) | **695** | **+0.109** | **0.004** | **+0.052** | **0.17** | **+0.109** | [+0.041, +0.176] | **0.002** | **+0.012** | **0.76** | **0.90** |
| Eos. esophagitis (GSE58640) | 16 | +0.489 | 0.054 | +0.425 | 0.13 | — | — | — | — | — | — |
| CRSwNP (GSE136825) | 70 | +0.085 | 0.48 | +0.135 | 0.27 | −0.028 | [−0.086, +0.005] | 0.13 | +0.096 | 0.25 | (n.s.) |
| Atopic dermatitis (GSE121212) | 65 | +0.060 | 0.63 | +0.010 | 0.94 | +0.054 | [−0.006, +0.170] | 0.10 | −0.033 | 0.78 | (n.s.) |

*Partial Spearman correlation conditions on per-sample eosinophil and Th2 marker-signature scores (`ppcor::pcor.test`). Causal mediation was performed only in the asthma cohort with sufficient power (n = 695); estimates from the smaller cohorts are listed for transparency but are underpowered (n < 100) and should be interpreted as directional only. Bootstrap = 1,000 simulations, percentile CIs, `mediation::mediate`. The 90 % proportion mediated in the asthma cohort means that ≈ 90 % of the apparent IDI2-AS1 → IL5 association is statistically attributable to shared expression in the eosinophil compartment, leaving a within-tissue direct effect indistinguishable from zero (ADE p = 0.76).*

---

## Notes on table formatting for Frontiers submission

- Frontiers prefers tables embedded in the manuscript file (not as separate uploads).
- All p-values < 0.001 should be reported as "< 0.001" rather than "0.000" once converted.
- Italicize gene names (*IDI2-AS1*, *IL5*) consistently in the final formatted version.
- Heterogeneity rows in Table 2 may be folded into the meta-analysis row with a footnote in tighter formats.
