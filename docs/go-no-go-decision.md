# Phase 1 Go/No-go Decision

**Date:** 2026-04-18
**Decision:** **GO** (with note on tissue-dependent expression)

## Criteria

1. **[x] PASS** — 4 diseases × ≥2 RNA-seq datasets each (8 total)
2. **[x] PASS** — IDI2-AS1 detected at ≥10 reads in ≥5 samples in pilot (strong in tissue-relevant dataset)
3. **[x] PASS** — Pilot trend supports proceeding (tissue-dependent expression matches IL5/eosinophil biology)

## Pilot Detection Results

Pilot tested two tissues to characterize IDI2-AS1 baseline expression range:

| Dataset    | Tissue              | n   | Mean reads | Median | n samples ≥10 reads | n samples ≥5 reads |
|:-----------|:--------------------|:----|:----------:|:------:|:-------------------:|:------------------:|
| GSE121212  | Skin biopsy (AD/HC) | 147 | 2.84       | 2      | 3 (2.0%)            | 30 (20.4%)         |
| GSE136825  | Nasal polyp (CRSwNP) | 103 | 20.34      | 16     | 69 (67.0%)          | 82 (79.6%)         |

**Interpretation:**
- IDI2-AS1 is **strongly expressed** in eosinophil-rich, Th2-driven mucosal tissue (nasal polyp).
- IDI2-AS1 is **lower but detectable** in skin biopsy.
- This tissue-dependent pattern is biologically consistent with the original IDI2-AS1→IL5 axis (BBRC 2025): expression dominates in airway/immune-rich compartments where IL5 biology operates.

## Dataset Feasibility (Task 1.1)

```
                          n_datasets  total_patient  total_control
disease
asthma                             2            476            349
atopic_dermatitis                  2             47             38
eosinophilic_esophagitis           2             15             11
nasal_polyps                       2             59             40
```

All 4 diseases meet the ≥2 datasets, ≥1 with n_patient ≥10 threshold.

## Decision

**[x] GO** — Proceed to Phase 2 (data acquisition) for all 4 diseases.

## Notes / Adjustments for Phase 2+

- For **DESeq2 analysis**, retain default independent filtering. Low-count genes (e.g., IDI2-AS1 in skin) will be flagged via `independentFiltering = TRUE` and reported as "below detection" if applicable, rather than excluded a priori.
- **Atopic dermatitis (skin)** is expected to show smaller fold changes for IDI2-AS1 due to lower baseline expression. Address by: (a) using lesional vs non-lesional within-patient comparison in GSE65832 to maximize power, (b) reporting the tissue-context interpretation in Discussion.
- **Nasal polyp and asthma airway** datasets are the strongest validation tier. Atopic dermatitis and EoE serve as breadth-of-disease evidence.
- Low EoE patient count (GSE58640 n=10, GSE246323 n=5) is acknowledged as a field-level limitation — meta-analysis weighting will down-weight these contributions appropriately.

## Pilot CSVs (gitignored, regenerate via script)

```
results/intermediate/pilot_idi2as1_counts_GSE121212.csv
results/intermediate/pilot_idi2as1_counts_GSE136825.csv
```

Regenerate with:
```bash
Rscript code/R/02_pilot_idi2as1_detection.R GSE121212
Rscript code/R/02_pilot_idi2as1_detection.R GSE136825
```
