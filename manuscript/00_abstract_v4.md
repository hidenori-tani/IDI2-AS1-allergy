## Abstract

**Background.** Long noncoding RNAs (lncRNAs) are typically low-abundance and cell-type-restricted, so cell-specific regulators can be invisible in bulk RNA-seq catalogs. When per-cell regulation and cell-composition shift oppose each other in a diseased biopsy, the bulk readout conflates them and a real per-cell effect may be masked, inverted, or read as null. No standardised framework separates these contributions from bulk transcriptomes.

**Approach.** We present a reusable, cell-composition-adjusted re-analysis pipeline combining (i) DESeq2/limma differential expression with random-effects meta-analysis, (ii) marker-signature deconvolution of effector-cell abundance, (iii) partial correlation conditioned on the cell-composition signature, and (iv) bootstrap mediation decomposition into direct (ADE) and mediated (ACME) components. CIBERSORTx-compatible inputs and all code are released openly.

**Worked example.** Applied to *IDI2-AS1*, a recently identified in vitro repressor of *IL5*, in five public bulk RNA-seq cohorts (*n* = 856; four type-2 allergic diseases), the pipeline returned a converging bulk-DE null (pooled log<sub>2</sub>FC ≈ 0; *I*<sup>2</sup> = 0.26 %) and a positively signed *IDI2-AS1*–*IL5* sample-level correlation inverting the in vitro direction. Cell-composition adjustment attributed ≈ 90 % of the covariation to shared eosinophil abundance (ACME *p* = 0.002), with no detectable direct effect (ADE *p* = 0.76).

**Implications.** The pipeline prevents bulk-tissue nulls being mis-read as evidence against cell-type-restricted lncRNA function. For *IDI2-AS1*, the bulk readout is most parsimoniously explained as compositional masking; single-cell adjudication is needed. The framework applies to other low-abundance lncRNA candidates against public bulk cohorts.

**Keywords:** long noncoding RNA; bulk RNA-seq; cell-composition deconvolution; random-effects meta-analysis; partial correlation; mediation analysis; IL5; type-2 inflammation.
