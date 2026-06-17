## Key Points

- Bulk-tissue RNA-seq systematically conflates per-cell regulation with cell-composition shifts for low-abundance, cell-type-restricted lncRNAs, producing null or sign-inverted readouts that are routinely mis-read as evidence against in vivo regulatory function.

- We introduce a reusable, cell-composition-adjusted re-analysis pipeline that combines uniform DESeq2/limma differential expression with random-effects meta-analysis, marker-signature deconvolution, partial-correlation analysis conditioning on cell composition, and bootstrap mediation decomposition.

- As a worked example, the pipeline was applied to *IDI2-AS1* / *IL5* across five public RNA-seq cohorts (*n* = 856) covering four type-2 allergic diseases, reconciling a converging bulk-DE null with a sign-inverted sample-level correlation under a single interpretation.

- In the largest cohort (asthma, *n* = 695), the pipeline attributed ≈ 90 % of the bulk *IDI2-AS1*–*IL5* covariation to shared eosinophil abundance (ACME *p* = 0.002), with no detectable within-tissue direct effect (ADE *p* = 0.76).

- All analysis code, intermediate result tables, and CIBERSORTx-compatible inputs are released openly under an MIT license; the framework is directly applicable to other low-abundance, cell-type-restricted lncRNA candidates evaluated against public bulk RNA-seq cohorts.
