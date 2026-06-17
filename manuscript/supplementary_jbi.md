# Supplementary material

## Supplementary Table 1. Per-dataset and meta-analytic patient-vs-control differential expression for *IDI2-AS1* and *IL5*

| Gene | Disease | GEO | Method | log₂FC | SE | *p*<sub>adj</sub> |
|---|---|---|---|:-:|:-:|:-:|
| **IDI2-AS1** | Asthma | GSE152004 | DESeq2 + apeglm | +0.0015 | 0.033 | 0.94 |
|  | Atopic dermatitis | GSE121212 | DESeq2 + apeglm | −0.234 | 0.274 | 0.41 |
|  | Eos. esophagitis | GSE246323 | DESeq2 + apeglm | −0.036 | 0.145 | 0.50 |
|  | Eos. esophagitis | GSE58640 | limma-trend | +0.246 | 0.148 | 0.15 |
|  | CRSwNP | GSE136825 | DESeq2 + apeglm | −2.8 × 10⁻⁶ | 0.0014 | 0.54 |
|  | **Meta-analysis (k = 5)** |  | REML | **+5.1 × 10⁻⁵** | [−0.005, +0.005] | **0.98** |
|  | *Heterogeneity* |  |  |  | *I*² = 0.26 % |  *Q* p = 0.47 |
| **IL5** | Asthma | GSE152004 | DESeq2 + apeglm | **+0.424** | 0.232 | **0.014** |
|  | Atopic dermatitis | GSE121212 | DESeq2 + apeglm | −0.264 | 0.325 | 0.39 |
|  | Eos. esophagitis | GSE58640 | limma-trend | **+0.609** | 0.159 | **0.002** |
|  | CRSwNP | GSE136825 | DESeq2 + apeglm | +1.0 × 10⁻⁶ | 0.0014 | 0.78 |
|  | **Meta-analysis (k = 4)** |  | REML | +0.216 | [−0.148, +0.580] | 0.25 |
|  | *Heterogeneity* |  |  |  | *I*² = 82.0 % | *Q* p = 3.3 × 10⁻⁴ |

*IL5 was below the rowSum ≥ 10 count threshold in GSE246323 and is therefore not included in that cohort's IL5 rows or in the IL5 meta-analysis (k = 4). p-values are Benjamini–Hochberg adjusted.*

---

## Supplementary Figure 1. *IDI2-AS1* vs Th2 / type-2 marker signature per cohort

Per-sample *IDI2-AS1* (x-axis) vs Th2 / type-2 marker-signature score (y-axis, mean *z*-score across *GATA3*, *IL4R*, *CCR4*, *PTGDR2*, *IL13*, *IL17RB*) in each of the five cohorts. Signatures are standardized within each cohort. This panel complements Fig. 4B (eosinophil signature) and shows the cohort-by-cohort relationship between *IDI2-AS1* and the broader type-2 effector compartment.
