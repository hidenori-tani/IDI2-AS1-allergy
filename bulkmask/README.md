# bulkmask

**Report how much of a gene-pair association in bulk RNA-seq is shared with cell composition.**

When a regulator is low-abundance and restricted to a rare cell type, a per-cell
effect can be diluted below detection in bulk tissue while differences in cell
composition dominate the bulk signal. `bulkmask` is a parameterised, reusable
pipeline that reports, for an arbitrary exposure/outcome gene pair across one or
more cohorts, the unadjusted association, the association adjusted for
composition estimates, and a statistical partition of the association into a
composition-associated and a residual component. It does not test per-cell
regulation, which requires cell-resolved data.

The shipped worked configuration is *IDI2-AS1* → *IL5* across five public
type-2 allergic-disease cohorts, but the same pipeline runs on **your** count
matrix, gene pair, and marker signatures by editing one YAML file.

## The four steps

1. **Differential expression** — `run_de()` (DESeq2 with apeglm-shrunken fold
   changes, or limma-trend). For count matrices its `SE` column is the apeglm
   posterior SD, which is not a sampling standard error, so do not pool it with
   `run_meta()` (random-effects REML); pool unshrunken estimates instead (the
   manuscript's pooled estimates come from `code/python/21_unshrunken_de_power.py`).
   For FPKM matrices `run_de()` keeps genes with any non-zero value and returns
   the moderated limma SE, whereas the manuscript's differential expression
   (`code/R/04_deg_analysis.R`) keeps genes above 0.1 FPKM in at least 10% of
   samples and reports the ordinary SE.
2. **Effector-cell abundance** — three expression-derived estimates of the
   compartment: marker-mean z-score (`score_signature()`), xCell raw enrichment
   (`estimate_xcell()`), and ssGSEA of the same marker set
   (`estimate_gsva_ssgsea()`, GSVA). Two share the marker genes and xCell shares
   some of them, so their agreement tests robustness to summarization more than
   to the choice of genes. Count cohorts are length-normalised to **TPM**
   (`counts_to_tpm()`, lengths from `gene_lengths_ensdb()`) for the
   deconvolution input; FPKM cohorts use FPKM. Count cohorts keep genes with
   at least 10 reads in total, FPKM cohorts genes with any non-zero value.
3. **Composition-adjusted partial correlation** — `partial_corr()`, conditioning
   on the composition estimate and, optionally, on case/control status and the
   Th2 compartment; a neutrophil panel serves as a specificity negative control.
   These two models run only for signatures named exactly `th2` and
   `neutrophil`.
4. **Bootstrap decomposition** — `decompose_association()` partitions the bulk
   association into a composition-associated component and a residual component
   (10,000 resamples), **as a statistical partition under a linear model, not a
   causal effect**.

`prepare_cohort()` (step 2) and `analyse_cohort()` (steps 3–4) process one
cohort; the driver `scripts/run_bulkmask_pipeline.R` runs them over the cohorts
in `inst/config/idi2as1_il5.yml`. Step 1 is run separately.

## Quick start

```r
source("bulkmask/load_all.R")            # or: devtools::load_all("bulkmask")
cfg <- read_config("bulkmask/inst/config/idi2as1_il5.yml")

se  <- readRDS("data/processed/GSE152004_se.rds")
cfg$.cohort_id <- "GSE152004"
df  <- prepare_cohort(se, cfg, id_type = "symbol")
res <- analyse_cohort(df, cfg)
res$correlations    # raw + composition-adjusted partial correlations
res$decompositions  # composition-associated vs residual, 3 estimators
```

To apply it to a different lncRNA/target, copy the YAML and change `exposure`
and `exposure_ensembl`, `outcome` and `outcome_ensembl`, the `signatures` with
one `ensembl_aliases` entry per signature gene (needed for Ensembl-keyed
matrices), `mediator_signature`, `deconvolution: xcell_cell_type`, and the
`cohorts`; then point the loaders at your data. `read_config()` stops if a
signature gene has no alias, or if an alias, `exposure_ensembl` or
`outcome_ensembl` is absent from `ens2sym_file` or maps to another symbol there.
These checks apply when an Ensembl-keyed cohort is configured. `ens2sym_file`
is read relative to the working directory (run from the repository root), and
`read_config()` also stops if it is named but not found; without
`ens2sym_file` the identifiers are not checked.

A self-contained synthetic example that needs no external data is in
`vignettes/quickstart.Rmd` and in most of `tests/test_bulkmask.R`. Run the tests
from the repository root (`Rscript --vanilla bulkmask/tests/test_bulkmask.R`):
the checks of the shipped configuration read `data/metadata/ensembl_to_symbol.csv`.

## Install / dependencies

Bioconductor: `SummarizedExperiment`, `DESeq2`, `limma`, `apeglm`, `GSVA`,
`GSEABase`, `ensembldb`, `EnsDb.Hsapiens.v86`. CRAN: `metafor`, `ppcor`,
`mediation`, `matrixStats`, `yaml`. GitHub: `xCell`
(`remotes::install_github("dviraran/xCell")`).

```r
R CMD INSTALL bulkmask        # or devtools::install("bulkmask")
```

## Reproducibility

All RNG-dependent steps take a fixed `seed` (default 42). `sessionInfo()` is
written by the driver script. Licensed MIT.
