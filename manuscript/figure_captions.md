# Figure Captions

> One paragraph per figure; first sentence is bold and acts as the figure title.
> Mentions of statistical values inside captions are repeated from the Results
> section so each figure stands alone. Figures and tables have been combined to
> satisfy Allergology International's limit of 8 display items per article
> (current total: 5 figures + 3 tables = 8).

---

## Fig. 1. Study design and analytical workflow.

Single-panel overview showing: (left) five public bulk RNA-seq cohorts spanning four IL5-driven allergic diseases (asthma, atopic dermatitis, eosinophilic esophagitis × 2 cohorts, chronic rhinosinusitis with nasal polyposis; total n = 856 samples); (centre) uniform per-dataset differential-expression pipeline (DESeq2 + apeglm for raw counts, limma-trend for FPKM); (right) three downstream analyses — random-effects meta-analysis of IDI2-AS1 and IL5 across cohorts, sample-level Spearman correlation between IDI2-AS1 and IL5 within each cohort, and cell-type-adjusted partial correlation plus a mediation-style decomposition in the asthma cohort using marker-gene signature scores for the eosinophil and Th2 compartments. The schematic makes the central interpretive arc visible at a glance: bulk DE → bulk correlation → cell-composition adjustment → within-tissue residual.

*Source: `code/python/11_fig1_study_design.py`; figure label added by `manuscript/build_labeled_figures.py`. File: `results/figures/submission/Figure1.pdf`.*

---

## Fig. 2. *IDI2-AS1* and *IL5* random-effects meta-analysis across five allergic-disease cohorts.

**(A)** Forest plot for *IDI2-AS1* (k = 5 datasets). Per-dataset DESeq2 + apeglm or limma-trend log<sub>2</sub>FC estimates with 95 % confidence intervals are shown for each cohort, with the random-effects pooled estimate (REML, `metafor::rma`) at the bottom. The pooled estimate is +5.1 × 10⁻⁵ (95 % CI [−0.005, +0.005]; *p* = 0.98), with negligible between-study heterogeneity (*I*² = 0.26 %; Cochran's *Q* *p* = 0.47), indicating that all five datasets independently agree on the absence of a bulk-tissue effect. **(B)** Forest plot for *IL5* (k = 4; below count threshold in GSE246323). Pooled log<sub>2</sub>FC = +0.22 (95 % CI [−0.15, +0.58]; *p* = 0.25), with substantial heterogeneity driven by the strong asthma and EoE-Sherrill effects (*I*² = 82 %).

*Source: `code/R/06_meta_analysis.R`; panels A and B combined into a single submission file by `manuscript/build_labeled_figures.py`. File: `results/figures/submission/Figure2.pdf` (panel A = former `Fig2_forest_IDI2AS1.pdf`; panel B = former `Fig2_forest_IL5.pdf`).*

---

## Fig. 3. Sample-level *IDI2-AS1* ↔ *IL5* covariation per cohort.

Per-sample *IDI2-AS1* vs *IL5* abundance (variance-stabilized counts for raw-count datasets, log<sub>2</sub>(FPKM + 1) for GSE58640) in the four cohorts where both transcripts are reliably quantified. Each panel is one cohort, with patients (red) and controls (blue) overlaid; black lines show within-panel linear regression with 95 % confidence ribbon. Spearman correlations: asthma ρ = +0.109, *p* = 0.004 (n = 695); EoE (Sherrill) ρ = +0.489, *p* = 0.054 (n = 16); CRSwNP ρ = +0.085, *p* = 0.48 (n = 70); atopic dermatitis ρ = +0.060, *p* = 0.63 (n = 65). All four cohorts show *positive* covariation — the opposite of the negative direction predicted by the in vitro repressive mechanism reported in Endo et al. (2025).

*Source: `code/R/07_correlation_analysis.R`; figure label added by `manuscript/build_labeled_figures.py`. File: `results/figures/submission/Figure3.pdf`.*

---

## Fig. 4. Cell-type adjustment dissolves the asthma *IDI2-AS1* ↔ *IL5* association.

**(Top row)** Raw IDI2-AS1 vs IL5 scatter, one panel per cohort, with per-sample regression line (same data as Fig. 3, rendered at uniform aspect ratio for direct visual comparison with the bottom rows). **(Bottom rows)** IDI2-AS1 vs per-sample marker-signature score for the eosinophil compartment (CLC, EPX, PRG2, RNASE2, RNASE3, SIGLEC8, CCR3) and the Th2 / type-2 compartment (GATA3, IL4R, CCR4, PTGDR2, IL13, IL17RB), each computed as the mean per-gene z-score within the cohort. The strong positive association between IDI2-AS1 and the eosinophil signature in the asthma cohort, mirrored by the IDI2-AS1 ↔ IL5 association in the same panel, is the visual basis for the cell-composition explanation quantified by the mediation-style decomposition in Table 3.

*Source: `code/R/09_celltype_adjusted_correlation.R`; figure label added by `manuscript/build_labeled_figures.py`. File: `results/figures/submission/Figure4.pdf`.*

---

## Fig. 5. Specificity panels — comparator lncRNAs and type-2 cytokines across five cohorts.

**(A)** Heatmap of patient-vs-control log<sub>2</sub> fold-changes for *IDI2-AS1* and four comparator lncRNAs (*MIR22HG*, *GABPB1-AS1*, *OIP5-AS1*, *LITATS1*) across the five cohorts. Rows: lncRNAs, anchored on *IDI2-AS1*. Columns: cohorts, ordered by disease (annotation bar above), with per-cohort total sample size. Colour scale: symmetric around zero (blue = downregulated in patients; red = upregulated), clipped at ±4 log<sub>2</sub> units. Comparator lncRNAs show clear disease-specific differential expression (e.g. *MIR22HG* +0.82 in atopic dermatitis, *GABPB1-AS1* −0.50 in atopic dermatitis), whereas *IDI2-AS1* is uniquely flat in every cohort. (Comparator lncRNAs other than *IDI2-AS1* are quantified by HGNC symbol only and therefore appear in three of the five cohorts; the two Ensembl-keyed cohorts have empty cells for those rows.) **(B)** Heatmap of patient-vs-control log<sub>2</sub> fold-changes for six type-2 / inflammatory cytokines (*IL5*, *IL4*, *IL13*, *IL6*, *TNF*, *IFNG*) across the same five cohorts, with identical layout and colour conventions. *IL13* is strongly elevated in atopic dermatitis (log<sub>2</sub>FC = +4.92, *p*<sub>adj</sub> = 2 × 10⁻³⁰) and in EoE-Sherrill (+0.91, *p*<sub>adj</sub> = 2 × 10⁻⁵); *IL5* is elevated in asthma (+0.42, *p*<sub>adj</sub> = 0.014) and in EoE-Sherrill (+0.61, *p*<sub>adj</sub> = 0.002); *IL6* and *TNF* are strongly elevated in atopic dermatitis only; *IFNG* is downregulated in asthmatic nasal epithelium (−0.66, *p*<sub>adj</sub> = 5 × 10⁻⁷) but upregulated in atopic-dermatitis skin. The cytokine panel behaves as expected from established immunology, providing a positive control against which the specific flatness of *IDI2-AS1* in the same cohorts can be interpreted.

*Source: `code/R/10_specificity_heatmaps.R`; panels A and B combined into a single submission file by `manuscript/build_labeled_figures.py`. File: `results/figures/submission/Figure5.pdf` (panel A = former `Fig5_lncrna_specificity_heatmap.pdf`; panel B = former `Fig6_cytokine_specificity_heatmap.pdf`).*
