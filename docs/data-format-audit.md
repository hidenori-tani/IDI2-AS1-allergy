# Data format audit (after download)

The deposited files of the eight candidate series were opened after download (April 2026) to check that
*IDI2-AS1* is present and that the data type suits the analysis (for GSE179269 only its single-cell
SubSeries was downloaded; see the table). In the two Ensembl-keyed series (GSE246323 and GSE136825) that
check looked up a mistyped Ensembl identifier, corrected on 2026-11-05 to ENSG00000232656. GSE201955 is keyed
by gene symbols (13,757 genes) and has no *IDI2-AS1* row (checked again on 2026-11-05). Five series were used
and three were excluded. The *IDI2-AS1* levels in the table were measured on 2026-11-05 from the deposited
files (all deposited samples of each series; ENSG00000232656 in the Ensembl-keyed files).

| GSE | Disease | Patients + controls analysed | Deposited format | *IDI2-AS1* in the file | Use |
|:----|:--------|:-----------------------------|:-----------------|:-----------------------|:----|
| GSE152004 | Asthma | 441 + 254 | Raw counts (gene symbols) | Present; median 3 reads (10th–90th percentile 0–8) | DESeq2 |
| GSE121212 | Atopic dermatitis | 27 + 38 (lesional AD skin; healthy skin) | Raw counts (gene symbols; Excel-date duplicate symbols) | Present; mean 2.84 reads | DESeq2 |
| GSE246323 | Eosinophilic esophagitis | 5 + 5 (baseline biopsies) | Raw counts (Ensembl IDs) | Present; median 0 reads (range 0–5; non-zero in 7 of 20 samples) | DESeq2 |
| GSE58640 | Eosinophilic esophagitis | 10 + 6 | FPKM | Present; median 2.1 FPKM (GAPDH median 1,400) | limma-trend on log2(FPKM + 1) |
| GSE136825 | CRSwNP | 42 + 28 (nasal polyp; control inferior turbinate) | Raw counts (featureCounts, Ensembl IDs) | Present; mean 1.49 reads (non-zero in 50 of 103 samples) | DESeq2 |
| GSE201955 | Asthma | — | TMM/voom log2 values of a filtered gene list, with sequencing batch, age, sex, current smoking and the first three ancestry principal components regressed out (limma removeBatchEffect) | Absent | Excluded |
| GSE65832 | Atopic dermatitis | — | Differential-expression table only (logFC, P.Value) | — | Excluded |
| GSE179269 | CRSwNP | — | SuperSeries: single-cell 10x matrices from two samples (SubSeries GSE179268), the only files examined in April 2026; its bulk read counts (SubSeries GSE179265; 17 + 7) were overlooked | Bulk: 2 reads in total across the 24 samples (checked 2026-11-05) | Excluded |

The five series give 856 samples. Deposited samples that were not used:

- GSE121212 (147 samples): non-lesional AD skin (27) and psoriasis skin (lesional 28, non-lesional 27).
- GSE246323 (20 samples): the ten patient biopsies taken 20 minutes after intramucosal food-extract
  injection; only the baseline biopsies of the five patients were used, with the five control biopsies.
- GSE136825 (103 samples): inferior turbinate from the patients with nasal polyps (33), so the contrast is
  polyp tissue versus control turbinate.

The GSE179265 count was made outside this repository; no script here downloads GSE179265. Its deposited file
`GSE179265_readcount_genename.txt.gz` has one row for ENSG00000232656 (*IDI2-AS1*), with one read in each of two
polyp samples (Jpn_NP_6 and US_NP_5) and none in the other 22 samples.

CRSwNP, chronic rhinosinusitis with nasal polyps.
