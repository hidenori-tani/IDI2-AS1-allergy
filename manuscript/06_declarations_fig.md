## Declarations

### Funding

No funding was received for conducting this study.

### Clinical trial number

Clinical trial number: not applicable.

### Competing interests

The author has no relevant financial or non-financial interests to disclose.

### Ethics approval

This study used only publicly available, fully de-identified RNA-seq datasets obtained with appropriate ethical approval by the original investigators. No new human or animal data were generated, and no additional ethical approval was required for this retrospective re-analysis of fully de-identified public data.

### Consent to participate

Not applicable. The study did not involve new human participants; all data were obtained from publicly available, fully de-identified datasets.

### Consent for publication

Not applicable.

### Data availability

All datasets re-analyzed in this study are publicly available from the NCBI Gene Expression Omnibus (GEO) under accession numbers GSE152004 (asthma; Sajuthi et al., 2020), GSE121212 (atopic dermatitis; Tsoi et al., 2019), GSE58640 (eosinophilic esophagitis; Sherrill et al., 2014), GSE246323 (eosinophilic esophagitis; Kleuskens et al., 2024), and GSE136825 (chronic rhinosinusitis with nasal polyposis; Peng et al., 2019).

### Code availability

All analysis code, intermediate result tables, and figure-generating scripts are publicly available at https://github.com/hidenori-tani/IDI2-AS1-allergy under an MIT license. The R software environment is captured by `renv.lock` (R 4.3.2, Bioconductor 3.18) for full reproducibility.

### Author contributions

**Hidenori Tani (ORCID: 0000-0001-6390-4136):** Conceptualization, Data curation, Formal analysis, Investigation, Methodology, Software, Validation, Visualization, Writing – original draft, Writing – review & editing.

### Use of generative AI

During the preparation of this manuscript, the author used Anthropic Claude Code (Claude Opus) as a writing and coding assistant. To make the boundary of this assistance explicit, as requested by peer review: the AI assistant was used to (i) implement analysis and figure-generation code from the author's specifications, and (ii) draft and copy-edit manuscript prose. All substantive statistical and analytical decisions were made by the author — specifically, the choice of differential-expression and meta-analysis models, the decision to use random-effects pooling, the selection of the eosinophil and Th2 marker panels, the choice to condition on cell-composition signatures and to use a mediation-style decomposition, the decision to validate the marker result with an independent deconvolution (xCell) and to use the raw rather than spillover-compensated enrichment, the restriction of the quantitative claim to the asthma cohort, and the framing of the decomposition as a statistical rather than causal partition. Every numerical result was regenerated from the released code and verified by the author against the source data. The author takes full responsibility for the content of the publication. This use is also noted in the Methods.
