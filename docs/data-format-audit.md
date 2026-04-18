# Data Format Audit (post-download)

**Date:** 2026-04-18

After downloading 8 candidate datasets (Task 2.2), each supplementary file was opened to verify (a) IDI2-AS1 is present, (b) the data type is suitable for our analysis pipeline. **3 datasets were excluded** based on this audit; **5 are usable**.

## Audit Results

| GSE | Disease | n | Format | IDI2-AS1 | Status |
|:----|:--------|:--|:-------|:---------|:-------|
| GSE121212 | AD | 27+38 | Raw counts (gene symbol, Excel-date dups) | ✅ low (mean 2.84) | **USE → DESeq2** |
| GSE136825 | CRSwNP | 42+33 | Raw counts (featureCounts, ENSG) | ✅ strong (mean 20.34) | **USE → DESeq2** |
| GSE152004 | Asthma | 388+307 | Raw counts (gene symbol) | ✅ low (0–5 reads typical) | **USE → DESeq2** |
| GSE246323 | EoE | 5+5 (baseline) | Raw counts (ENSG) | ✅ low (0–5 reads) | **USE → DESeq2** |
| GSE58640 | EoE | 10+6 | FPKM-normalized (GAPDH≈1300, IDI2-AS1≈1.5) | ✅ low | **USE → limma-trend on log2(FPKM+1)** |
| GSE201955 | Asthma | 88+42 | log2-normalized + 13758-gene filtered list | ❌ **NOT IN FILE** | **EXCLUDE** |
| GSE65832 | AD | 20+20 paired | DEG table only (logFC, P.Value); broken line breaks | N/A | **EXCLUDE** |
| GSE179269 | CRSwNP | (2) | scRNA-seq 10x mtx (originally misidentified as bulk) | N/A | **EXCLUDE** |

## Pipeline Implication

**4 raw-count datasets** (DESeq2-friendly): GSE121212, GSE136825, GSE152004, GSE246323
**1 FPKM dataset** (limma-trend): GSE58640
**Total usable: 5 datasets**

Cross-disease coverage after exclusion:

| Disease | n datasets | Note |
|:--------|:-----------|:-----|
| Asthma | 1 (GSE152004) | Single dataset, n=695 — well-powered |
| AD | 1 (GSE121212) | Single dataset, n=147 |
| EoE | 2 (GSE246323 + GSE58640) | Mixed methods, both small; meta-analysis possible |
| CRSwNP | 1 (GSE136825) | Single dataset, n=75 |

## Methodological Adaptation

To enable consistent cross-disease comparison despite mixed input formats, the analysis pipeline is unified at the **logFC + standard error** level:

- **Raw counts** → DESeq2 with `apeglm` shrinkage → `log2FoldChange`, `lfcSE`
- **FPKM** → log2(FPKM+1) → limma-trend (`eBayes`) → `coefficients`, `stdev.unscaled * sigma`

Both produce comparable effect-size estimates per gene per disease per dataset, suitable for `metafor`-based random-effects meta-analysis (where n≥2 datasets exist) or single-dataset reporting with 95% CI (where n=1).

## Limitations (for Discussion)

1. **Per-disease meta-analysis only feasible for EoE** (2 datasets). For asthma, AD, CRSwNP, results are reported from the single best-available dataset with effect size + 95% CI.
2. **GSE201955** would have been a second high-quality asthma dataset but was unusable because the GEO-deposited processed file is a 13,758-gene filtered list that excludes IDI2-AS1. Re-quantification from SRA is out of scope.
3. **GSE65832** was the only paired lesional/non-lesional AD design; loss prevents within-patient analysis.
4. Results should be framed as **discovery in tissue-relevant single datasets, with cross-disease pattern as the primary finding**, rather than as four parallel meta-analyses.

## Pilot Confirmation Tier (most-trusted-dataset per disease)

For the headline cross-disease comparison, prioritize:
- **CRSwNP**: GSE136825 (strongest IDI2-AS1 signal, n=75)
- **AD**: GSE121212 (n=147, established Tsoi cohort)
- **Asthma**: GSE152004 (n=695, largest)
- **EoE**: GSE246323 (raw counts) with GSE58640 as supportive replication
