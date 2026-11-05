# A cell-composition-adjusted reanalysis workflow for bulk-tissue lncRNA interpretation (IDI2-AS1 / IL5 worked example)

A reusable workflow that reports three things for a candidate regulator and its target in bulk patient tissue: how much of their association is shared with cell composition, how much that share depends on the composition estimate, and what remains. The worked example is *IDI2-AS1*, reported to repress *IL5* in vitro, across five public bulk RNA-seq cohorts (n = 856) from four type-2 allergic diseases.

- **Author**: Hidenori Tani (Yokohama University of Pharmacy)
- **In vitro study whose IDI2-AS1–IL5 relationship is examined here in patient tissue**: Endo, Kurisu, Tani (BBRC 2025) — *Long noncoding RNA IDI2-AS1 modulates the expression of interleukin 5 in human cells*

## Main result

- **Differential expression**: no cohort showed significant *IDI2-AS1* differential expression (adjusted p ≥ 0.15 where estimable).
  - The asthma cohort had 80% power to detect a 1.2-fold change.
  - The pooled log2 fold change from unshrunken estimates was +0.02 (95% CI −0.21 to 0.25; I² = 28%).
- **Correlation in asthma**: in nasal brushings (n = 695), *IDI2-AS1* correlated positively with *IL5* (Spearman ρ = 0.109; 95% CI 0.035 to 0.182), opposite to the in vitro direction.
  - Conditioning on an eosinophil marker score reduced the correlation to 0.048 (−0.026 to 0.122).
  - Under all three expression-derived eosinophil estimates, the composition-associated component was significant (all p ≤ 0.0014) and no residual association was detected.
  - Adjustment for case/control status changed neither result.
- **Interpretation**: these data neither support nor refute per-cell regulation of *IL5* by *IDI2-AS1*.
  - The quantitative result is limited to asthma.
  - The smaller cohorts gave imprecise, estimator-dependent results.

## Diseases / cohorts analyzed

1. Asthma — GSE152004 (nasal airway epithelium, brushing; n = 695)
2. Atopic dermatitis — GSE121212 (lesional skin / healthy skin; n = 65)
3. Eosinophilic esophagitis — GSE58640 (n = 16) and GSE246323 (n = 10), esophageal biopsies
4. Chronic rhinosinusitis with nasal polyps (CRSwNP) — GSE136825 (nasal polyp / control inferior turbinate; n = 70)

## Workflow (code/R and the bulkmask package)

The steps run in this order:
1. DESeq2 / limma-trend differential expression.
2. Sample-level Spearman correlation.
3. Partial correlation conditioned on composition estimates.
4. Bootstrap decomposition of the association into a composition-associated and a residual component. This is a statistical partition, not a causal one.

Eosinophil abundance is estimated from expression in three ways, all computed by the bulkmask package:
- a seven-gene marker score;
- single-sample enrichment (ssGSEA) of the same genes;
- xCell enrichment, computed from transcripts per million (FPKM for GSE58640).

The three estimates are not independent: two share the seven genes, and xCell shares three of them. Th2 and neutrophil signatures are scored for comparison. `code/R/14_mediation_sensitivity.R` runs the medsens sensitivity analysis for unmeasured confounding in asthma (1,000 quasi-Bayesian simulations, ρ grid in steps of 0.05) and writes `results/tables/Table_mediation_sensitivity.csv`. Its marker-score row (ρ = 0.60) is the value the manuscript reports; its xCell row (0.50) uses the earlier xCell estimate described below and is not a manuscript result. The closed-form crossing points of the three bulkmask estimates (marker score 0.600, xCell 0.593, ssGSEA 0.602) are in `results/tables/revision_2026_11/decomposition_intervals.csv`. Script 14 reads the per-sample table `results/intermediate/xcell_points.csv` that `code/R/12_xcell_deconvolution.R` writes (not in the repository), so run that script first.

The workflow is packaged as the R package `bulkmask/`. The gene pair, signatures, cohorts and bootstrap depth are set in one configuration file (`bulkmask/inst/config/idi2as1_il5.yml`). To run it from the GEO data:
1. `Rscript --vanilla code/R/03_download_all_datasets.R` downloads every series of `data/metadata/final_datasets.csv` to `data/raw/`, including the three excluded ones (about 300 MB more);
2. the loaders in `code/R/loaders/` write `data/processed/<GSE>_se.rds`;
3. `Rscript --vanilla scripts/run_bulkmask_pipeline.R` writes `results/tables/bulkmask/`.

The shipped tables in `results/tables/bulkmask/` were then amended by two scripts: `scripts/annotate_correlations_used.py` added the `conditioners_used` column to `correlations.csv` (every rho, p and n unchanged), and `scripts/rerun_bulkmask_cohorts.R` re-ran the Ensembl-keyed cohorts with the complete marker aliases and replaced their Th2 and neutrophil signature values and the two correlation models that condition on them. Last, two hand-typed Ensembl identifiers were corrected on 2026-11-05. *IDI2-AS1* is ENSG00000232656: the mistyped identifier had also been hard-coded in `code/R/02`, `04`, `06`, `09_v2`, `10_v2`, `12`, `code/R/loaders/common.R`, `code/python/16` (which used it to pick the *IDI2-AS1* rows of `ALL_focal_genes_deg.csv`) and `code/python/21` (which used it to read the GSE136825 and GSE246323 counts for its unshrunken refits), and was corrected there. EPX is ENSG00000121053: the configuration, `code/R/09_v2` and `code/R/12` had used the identifier of CD80 instead, and were corrected. No output of 09_v2 or 12 in this repository depends on either identifier: their tables are not included, the symbol map that 12 wrote (`data/metadata/ensembl_to_symbol.csv`) is keyed by the matrices' own identifiers, and `Table_mediation_sensitivity.csv`, which script 14 computes from 12's per-sample table, uses only GSE152004, whose rows are gene symbols. The GSE136825 rows of the three tables in `results/tables/bulkmask/` (`correlations.csv`, `decompositions.csv` and `points.csv`) were recomputed with the corrected configuration; the xCell columns of `points.csv` were carried over, because the xCell input (transcripts per million of the filtered counts, mapped to symbols with `data/metadata/ensembl_to_symbol.csv`) does not use these identifiers. Recomputed with the corrected *IDI2-AS1* identifier were also the GSE136825 and GSE246323 rows of `results/tables/ALL_focal_genes_deg.csv` and of the two per-cohort tables, `results/tables/Table_meta_analysis_summary.csv`, the tables in `results/tables/revision_2026_11/` and `results/figures/Fig5_lncrna_specificity_heatmap.pdf`. `read_config()` now checks every identifier against `data/metadata/ensembl_to_symbol.csv`. `points.csv` has no `dataset` column (the driver now writes one as the second column). Its rows follow the configured order of the cohorts that have both genes (GSE152004 695, GSE121212 65, GSE58640 16, GSE136825 70; GSE246323 has none because *IL5* does not pass the count filter), and the Python scripts rely on that order.

An earlier xCell analysis is also kept. `code/R/12_xcell_deconvolution.R` ran xCell on DESeq2-normalized counts (FPKM for GSE58640) and repeated the decomposition with 1,000 bootstrap resamples, `12b` summarizes the raw eosinophil enrichment behind the spillover floor of the compensated score and `13` plots the comparison with the marker score. These are not the manuscript's xCell results, which come from bulkmask. Of their tables, the repository includes the diagnostic `results/tables/Table_xcell_raw_eos_diagnostic.csv`; script 12 writes the others (`results/tables/Table_xcell_vs_marker_*.csv`).

## Robustness analyses and figures (code/python)

The analysis scripts first reproduce the values they build on (the main analysis in `results/tables/bulkmask/`, and the earlier meta-analysis in `results/tables/Table_meta_analysis_summary.csv` as a positive control), and exit with a non-zero status if any differs. They write their outputs before exiting, so the outputs of a failing run must not be used. In the code and its tables, "published" means these reproduced values, not a separate publication.

| Script | What it does | Output |
|---|---|---|
| `16_revision_robustness.py` | 95% intervals for the raw and composition-adjusted correlations, a comparison of the three eosinophil estimates, Th2-only conditioning, multiple-testing families, and alternative weightings of the earlier meta-analysis | `results/tables/revision_2026_11/` |
| `17_partial_intervals_and_fig6_inputs.py` | Fisher-z intervals for the partial correlations of Table 2A and Table S5, and the inputs of Figure 6 | `results/tables/revision_2026_11/` |
| `21_unshrunken_de_power.py` | Unshrunken negative-binomial refits of *IDI2-AS1* and *IL5* from the GEO count tables, whose Wald p values are close to the DESeq2 ones. Also gives 95% intervals, the minimum fold change detectable with 80% power, and random-effects pooling (REML) with sensitivity analyses | `results/tables/revision_2026_11/unshrunken_de.csv`, `unshrunken_meta.csv` |
| `22_decomposition_intervals.py` | Bootstrap intervals for the composition-associated proportion, the medsens crossing point in closed form, and case/control-adjusted decompositions and partial correlations for all three eosinophil estimates | `results/tables/revision_2026_11/decomposition_intervals.csv` |
| `24_figure1.py` (runs `11_fig1_study_design.py` and copies its output), `23_figure2.py`, `25_figures3_4.py`, `18_figure6.py`, `19_figureS1.py` | Figures 1, 2, 3, 4, 6 and S1; `figstyle.py` sets the fonts and sizes of Figures 2, 3, 4, 6 and S1 (the Figure 1 script sets its own) | `results/figures/submission_figs/` |

Figures 3 and 4 are drawn by `25_figures3_4.py` from `results/tables/bulkmask/points.csv`, the per-sample table behind Table 2 and Table S5, so the plotted values and the reported correlations come from one computation. `code/R/07_correlation_analysis_v2.R` and `code/R/09b_fig4_replot_v2.R` (which plots the per-sample table that `code/R/09_celltype_adjusted_correlation_v2.R` writes to `results/intermediate/`) draw earlier versions of the same plots from a separate computation, under file names marked superseded. Figure 5 stacks the two heatmaps drawn by `code/R/10_specificity_heatmaps_v2.R`: `Fig5_lncrna_specificity_heatmap.pdf` is panel A and `Fig6_cytokine_specificity_heatmap.pdf` is panel B (not Figure 6). Figure 5 was stacked by a helper of the manuscript build that is not in the repository.

For *IDI2-AS1* and *IL5*, the unshrunken refits supersede the pooled estimates in `results/tables/Table_meta_analysis_summary.csv` and the weighted re-poolings in `results/tables/revision_2026_11/meta_reweighting.csv`, which used apeglm posterior standard deviations as standard errors; the other eight genes of that table are not used in the manuscript. The Stouffer rows of `meta_reweighting.csv` combine Wald p values and are the same as in `unshrunken_meta.csv`. `Table_meta_analysis_summary.csv` is kept because scripts 16 and 21 reproduce it first; `code/R/06_meta_analysis.R`, which wrote it, is marked superseded. `meta_reweighting.csv` is an output of script 16 and an input of script 21 (its Stouffer check), so run 16 before 21.

## Documents

- [`docs/data-format-audit.md`](docs/data-format-audit.md) — the format of each deposited matrix, checked after download

## Project structure

```
data/
  raw/         # Downloaded GEO data (gitignored)
  metadata/    # Dataset catalogs
bulkmask/      # The workflow as a configurable R package (tests, vignette, worked configuration)
code/
  R/           # Download, loaders, differential expression, meta-analysis, composition estimates, decomposition
  python/      # GEO search, robustness analyses, figures
scripts/       # bulkmask driver and the two scripts that amended its shipped tables
results/
  figures/     # Figure panels and heatmaps; submission_figs/ holds Figures 1, 2, 3, 4, 6 and S1
  tables/      # Result tables (revision_2026_11/: robustness analyses)
docs/          # Data-format audit
logs/          # R session information and the inventory of downloaded files
```

## Reproducibility

- Python packages are listed in `requirements.txt`.
- R: `logs/bulkmask_sessionInfo.txt` records R 4.5.0 and the packages loaded by the bulkmask driver run (`scripts/run_bulkmask_pipeline.R`), which are Bioconductor 3.22 releases (for example DESeq2 1.50.2 and limma 3.66.0). The scripts in `code/R` (differential expression, meta-analysis, the earlier xCell run) recorded no session, so the versions they used are not known, nor are those of packages that the driver run did not load (for example apeglm, used by `run_de()` and `code/R/04_deg_analysis.R`, GEOquery and ComplexHeatmap). The packages are listed in `bulkmask/README.md`; the scripts in `code/R` also use tidyverse (readr, dplyr, tidyr, tibble, purrr, ggplot2), GEOquery, biomaRt, patchwork, gridExtra, ComplexHeatmap and circlize. `renv.lock` records only renv and BiocManager (and names Bioconductor 3.21), so it is not a complete lock file. `code/R/setup.R` (the initial environment setup) does not reproduce this environment either: it pins Bioconductor 3.21, does not install every package listed here, and requests immunedeconv, which is not on CRAN and is not used by any script, so its final load check fails. Run the R scripts with `Rscript --vanilla`, as the pipeline drivers do; this skips the renv activation in `.Rprofile` and uses the installed packages.
- The input data are the public GEO series GSE152004, GSE121212, GSE58640, GSE246323 and GSE136825.
- License: MIT (`LICENSE`).
