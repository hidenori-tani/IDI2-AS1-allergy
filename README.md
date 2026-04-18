# IDI2-AS1-IL5 Cross-Disease Analysis

Cross-disease transcriptomic analysis of IDI2-AS1 in IL5-driven allergic diseases.

- **Target journal**: Frontiers in Immunology
- **Author**: Hidenori Tani (Yokohama University of Pharmacy)
- **Companion to**: Endo, Kurisu, Tani (BBRC 2025) — *Long noncoding RNA IDI2-AS1 modulates the expression of interleukin 5 in human cells*

## Diseases analyzed

1. Asthma (bronchial epithelium)
2. Atopic dermatitis (skin biopsy)
3. Eosinophilic esophagitis (esophageal biopsy)
4. Nasal polyposis / CRSwNP (nasal mucosa)

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
