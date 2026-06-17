# A cell-composition-adjusted re-analysis pipeline for bulk-tissue lncRNA interpretation (IDI2-AS1 / IL5 worked example)

A reusable pipeline that separates per-cell regulation from cell-composition shift when interpreting bulk RNA-seq for low-abundance, cell-type-restricted lncRNAs, applied to *IDI2-AS1* (an in vitro repressor of *IL5*) across five public cohorts (n = 856) spanning four type-2 allergic diseases.

- **Author**: Hidenori Tani (Yokohama University of Pharmacy)
- **Companion to**: Endo, Kurisu, Tani (BBRC 2025) — *Long noncoding RNA IDI2-AS1 modulates the expression of interleukin 5 in human cells*

## Headline result

Bulk *IDI2-AS1* is invariant across cohorts (pooled log2FC ≈ 0; I² = 0.26 %), yet sample-level *IDI2-AS1*–*IL5* correlation is positive (opposite to the in vitro direction). In the only adequately powered cohort (asthma, n = 695), cell-composition adjustment attributes the majority of that covariation to shared **eosinophil abundance** — **≈ 90 % under a marker signature and ≈ 70 % under independent xCell deconvolution** (concordance ρ = 0.62; both p ≤ 0.006) — with no detectable within-tissue residual. The bulk null is therefore most parsimoniously read as compositional masking, a hypothesis for single-cell follow-up rather than a validated mechanism. The quantitative claim is restricted to asthma; smaller cohorts are directionally consistent but underpowered.

## Diseases / cohorts analyzed

1. Asthma — GSE152004 (nasal epithelium, n = 695)
2. Atopic dermatitis — GSE121212 (skin biopsy, n = 65)
3. Eosinophilic esophagitis — GSE58640 (n = 16) and GSE246323 (n = 10)
4. Nasal polyposis / CRSwNP — GSE136825 (nasal polyp, n = 70)

## Pipeline (code/R)

DESeq2/limma differential expression → random-effects meta-analysis (metafor) → sample-level Spearman correlation → cell-composition-adjusted partial correlation → bootstrap effect decomposition (a statistical, not causal, partition). Eosinophil abundance is estimated both by a marker-gene signature and, independently, by xCell deconvolution (`12_xcell_deconvolution.R`), with a spillover-floor diagnostic (`12b`), a validation figure (`13`), and an unmeasured-confounding sensitivity analysis (`14_mediation_sensitivity.R`, medsens).

## Documents

- Spec: [`docs/spec.md`](docs/spec.md) — full design rationale
- Plan: [`docs/plan.md`](docs/plan.md) — task-by-task execution plan

## Project structure

```
data/
  raw/         # Downloaded GEO data (gitignored)
  processed/   # Cleaned SummarizedExperiments
  metadata/    # Dataset catalogs
code/
  R/           # DEG, meta-analysis, deconvolution
  python/      # GEO search, sequence retrieval
results/
  figures/     # Manuscript figures
  tables/      # Manuscript tables
  intermediate/ # CIBERSORTx outputs etc.
manuscript/    # Markdown drafts
docs/          # Spec, plan, decision logs
logs/          # Run logs
```

## Reproducibility

- R packages locked via `renv.lock`
- Python packages locked via `requirements.txt`
- All analysis code will be public on GitHub at submission
