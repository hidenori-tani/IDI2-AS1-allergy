# Tables

## Table 1. Public bulk RNA-seq cohorts re-analyzed in this study

| Disease | GEO accession | Tissue | Patients (n) | Controls (n) | Total | Platform | Quantification | Reference |
|---|---|---|:-:|:-:|:-:|---|---|---|
| Asthma | GSE152004 | Nasal epithelium (brushing) | 388 | 307 | 695 | Illumina HiSeq 2000 | Raw counts | Sajuthi et al., 2020 |
| Atopic dermatitis | GSE121212 | Lesional skin / healthy control biopsy | 27 | 38 | 65 | Illumina HiSeq 2500 | Raw counts | Tsoi et al., 2019 |
| Eosinophilic esophagitis | GSE246323 | Esophageal biopsy (baseline) | 5 | 5 | 10 | Illumina NovaSeq 6000 | Raw counts | Kleuskens et al., 2024 |
| Eosinophilic esophagitis | GSE58640 | Esophageal biopsy | 10 | 6 | 16 | Illumina HiSeq 2000 | FPKM | Sherrill et al., 2014 |
| Chronic rhinosinusitis with nasal polyposis | GSE136825 | Nasal polyp tissue / control inferior turbinate | 42 | 28 | 70 | Illumina HiSeq 4000 | Raw counts (featureCounts) | Peng et al., 2019 |
| **Combined** |  |  | **472** | **384** | **856** |  |  |  |

*Three additional candidate datasets (GSE201955, GSE65832, GSE179269) were excluded because IDI2-AS1 was absent from the available processed expression matrix or because per-sample raw data could not be recovered without re-quantification from SRA. For GSE136825, patient nasal-polyp tissue (n = 42) was compared with healthy-donor inferior-turbinate tissue (n = 28); paired within-patient nasal-polyp / inferior-turbinate samples (NP_IT, n = 33) were excluded. This contrast is confounded by anatomical site (polyp vs turbinate) and donor source (patient vs unrelated healthy donor) and is therefore not structurally matched in the way the other cohorts are; the cohort is interpreted with that caveat and the quantitative decomposition does not rest on it.*

---

## Table 2. Sample-level *IDI2-AS1*–*IL5* association: raw, cell-type-adjusted, and bootstrap decomposition

| Cohort | n | **Raw Spearman ρ** | raw *p* | **Partial ρ** (\| eos + Th2) | partial *p* | Composition component (eos.) | 95 % CI | *p* | Residual | residual *p* | Prop. attributable |
|---|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| **Asthma** (GSE152004) | **695** | **+0.109** | **0.004** | **+0.052** | **0.17** | **+0.109** | [+0.041, +0.176] | **0.002** | **+0.012** | **0.76** | **0.90** |
| Eos. esophagitis (GSE58640) | 16 | +0.489 | 0.054 | +0.425 | 0.13 | — | — | — | — | — | — |
| CRSwNP (GSE136825) | 70 | +0.085 | 0.48 | +0.135 | 0.27 | −0.028 | [−0.086, +0.005] | 0.13 | +0.096 | 0.25 | (n.s.) |
| Atopic dermatitis (GSE121212) | 65 | +0.060 | 0.63 | +0.010 | 0.94 | +0.054 | [−0.006, +0.170] | 0.15 | −0.033 | 0.78 | (n.s.) |

*Partial Spearman correlation conditions on per-sample eosinophil and Th2 marker-signature scores (`ppcor::pcor.test`). The bootstrap decomposition (`mediation::mediate`, 1,000 nonparametric bootstrap resamples, percentile CIs) is adequately powered only in the asthma cohort (n = 695); the smaller-cohort estimates are listed for transparency but are underpowered and mixed in direction (AD positive, CRSwNP negative; neither significant) and should not be read as confirmation. Because the underlying data are cross-sectional, the composition and residual values are a statistical partition of the association under the assumed linear model, not a causal effect. The 0.90 proportion in asthma means ≈ 90 % of the apparent IDI2-AS1–IL5 association is statistically attributable to the eosinophil compartment, leaving a within-tissue residual indistinguishable from zero (p = 0.76); this is reproduced at a more conservative ≈ 70 % (p = 0.006) using independent xCell deconvolution (Fig. 6).*
