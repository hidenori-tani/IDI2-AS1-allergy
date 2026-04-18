# Submission Checklist — Frontiers in Immunology

**Manuscript:** *Tissue-bulk transcriptomes mask the IDI2-AS1 → IL5 axis through eosinophil-composition mediation: a cross-disease re-analysis in four type-2 allergic diseases*
**Author:** Hidenori Tani (sole author)
**Target journal:** Frontiers in Immunology
**Suggested section:** *Molecular Innate Immunity* or *T Cell Biology* (verify on submission portal)
**Article type:** Original Research

---

## A. Manuscript text

| Item | Status | Notes / action |
|---|---|---|
| Abstract (≤350 words) | ⚠️ 470 words | Trim before submission. Frontiers Original Research max = 350. Likely candidates for trimming: Background paragraph (currently 80 w) → 50 w; Methods detail → consolidate. |
| Introduction (700–900 words) | ✅ 662 words | Acceptable. |
| Materials & Methods | ✅ 935 words | Reproducibility-complete. |
| Results | ✅ 1,159 words | 5 subsections, mapped to Fig 2–6. |
| Discussion | ✅ 1,215 words | 5 paragraphs (Summary → Mechanism → Generalization → Clinical → Limitations). |
| Conclusion | ✅ 142 words | Within ≤200 word target. |
| Total body word count | ✅ 4,806 | Within typical Frontiers range (4,000–8,000). |
| Section headings use Frontiers numbering (1., 2., 3., 3.1, …) | ✅ | Already followed. |
| Hypothesis explicitly stated | ✅ | End of Introduction (3 questions). |

## B. Figures

| Figure | Source file | Caption draft needed | Status |
|---|---|---|---|
| **Fig 1: Study design schematic** | — | TODO | ❌ Must be drafted (illustrator-style: 5 datasets → uniform pipeline → meta + correlation + mediation → conclusion). Recommended: BioRender or Inkscape, single A4-landscape panel. |
| **Fig 2A: Forest plot — IDI2-AS1 (k=5)** | `results/figures/Fig2_forest_IDI2AS1.pdf` | TODO | ✅ PDF exists. Caption: random-effects pooled estimate ~0, I²=0.26%, Q p=0.47. |
| **Fig 2B: Forest plot — IL5 (k=4)** | `results/figures/Fig2_forest_IL5.pdf` | TODO | ✅ PDF exists. Pair with 2A as Fig 2 (combine in vector tool, side-by-side). |
| **Fig 3: IDI2-AS1 vs IL5 sample-level scatter (4 panels)** | `results/figures/Fig3_correlation_scatter.pdf` | TODO | ✅ PDF exists. Per-cohort Spearman ρ + p in panel headers. |
| **Fig 4: Cell-type adjustment (raw vs partial scatter)** | `results/figures/Fig4_celltype_adjusted.pdf` | TODO | ✅ PDF exists. Top: raw IDI2-AS1↔IL5; bottom: IDI2-AS1↔eosinophil/Th2 signatures. |
| **Fig 5: lncRNA specificity heatmap** | `results/figures/Fig5_lncrna_specificity_heatmap.pdf` | TODO | ✅ PDF exists. |
| **Fig 6: Cytokine specificity heatmap** | `results/figures/Fig6_cytokine_specificity_heatmap.pdf` | TODO | ✅ PDF exists. |
| All figures embedded fonts (Arial / Helvetica) | ⚠️ | Verify on PDF (R defaults usually OK; ggsave with `device = cairo_pdf` recommended). |
| All figures ≥ 300 dpi for raster panels | ✅ | All current figures are vector PDF (no raster panels). |
| Figure captions in single Captions.docx | TODO | Build after Fig 1 is added. |

## C. Tables

| Table | Source | Action |
|---|---|---|
| **Table 1: Dataset characteristics** | `data/metadata/final_datasets.csv` (filter `status==USE`) | Format as paper-ready (5 rows × columns: Disease, GSE, Tissue, n patient, n control, Platform, Quantification, Reference). See `manuscript/tables_for_paper.md` (auto-generated). |
| **Table 2: Per-dataset DEG and meta-analysis for IDI2-AS1 and IL5** | `results/tables/Table_meta_analysis_summary.csv` + `ALL_focal_genes_deg.csv` | Two-row meta summary + per-dataset rows. |
| **Table 3: Cell-type-adjusted correlation and mediation** | `results/tables/Table_celltype_adjusted_correlation.csv` + `Table_mediation_eosinophil.csv` | Combined table with raw ρ, adj ρ, and (asthma) ACME / ADE / proportion-mediated. |
| **Supp Table S1: Full focal-gene DEG (5 datasets × 11 genes)** | `results/tables/ALL_focal_genes_deg.csv` | Direct deposit. |
| **Supp Table S2–S6: Per-dataset full DEG** | `results/tables/GSE*_deg_full.csv.gz` | Direct deposit. |
| **Supp Table S7: Marker-signature gene panels** | Hard-coded in `code/R/09_celltype_adjusted_correlation.R` | Extract to TSV: panel name, gene symbol, ENSG, source citation. |

## D. References

| Item | Status | Action |
|---|---|---|
| All in-text citations match `references.bib` | ✅ | All Author-year mentions in manuscript correspond to `.bib` entries. |
| `[VERIFIED]` entries (8) | ✅ | Methods/software citations confirmed. |
| `[VERIFY]` entries (13) | ⚠️ | **Phase C of this workflow** will WebFetch each. Author/year/journal must be PubMed-confirmed; XXXX placeholders for volume/page must be filled in. |
| `[USER-OWNED]` entries (4) | ⚠️ | Tani lab papers — user fills in volume/page/DOI directly. |
| Frontiers reference style (Vancouver / numbered) | TODO | Convert from `.bib` to Frontiers numbered format using Pandoc + Frontiers CSL on final pre-submission. |

## E. Cover letter & metadata

| Item | Status | Action |
|---|---|---|
| Cover letter PDF | ✅ | `manuscript/cover_letter.md` (convert to PDF). |
| Authors (single) | ✅ | Hidenori Tani. |
| Affiliation, ORCID | TODO | Confirm ORCID and affiliation block: Yokohama University of Pharmacy, Department of [verify]. |
| Conflict-of-interest declaration | TODO | Add: "The author declares no competing interests." |
| Funding declaration | TODO | List any grant numbers; if none, "This work received no external funding." |
| Ethics statement | ✅ | All data are public GEO; no new sequencing; IRB-exempt. State explicitly: "This study used only publicly available, fully de-identified GEO datasets and required no additional ethical approval." |
| Suggested reviewers (3–5) | TODO | Draft list below. |
| Excluded reviewers | TODO | Optional. Default = none. |

## F. Code & data availability

| Item | Status | Action |
|---|---|---|
| GitHub repository public | ⚠️ | Push to `github.com/hidey0001/IDI2-AS1-allergy` (or chosen username). Update placeholder in Methods §2.6 + cover letter. |
| README.md with reproduce-from-scratch instructions | ⚠️ | Verify `README.md` covers `renv::restore()` + `Rscript code/R/01_…` ordering. |
| `renv.lock` committed | ✅ | Yes. |
| `requirements.txt` for any Python (none used) | ✅ | Python placeholder file present; can be removed. |
| Zenodo DOI for code (optional but recommended) | TODO | Link GitHub → Zenodo, mint a DOI on tagged release `v1.0-submission`. |
| GEO accession numbers cited in Methods + Data Availability | ✅ | Methods §2.1 lists all five GSE IDs. |

## G. Suggested reviewers (draft, please confirm/replace)

These are placeholders chosen on topical relevance. Do not submit without confirming each reviewer is currently active, has no recent co-authorship with the author, and works in an appropriate area.

1. **Marc Rothenberg** (Cincinnati Children's) — eosinophilic esophagitis, IL5, eosinophil biology. *Verify no COI.*
2. **Bart Lambrecht** (Ghent University) — type-2 immunity in asthma; cytokine network. *Verify no COI.*
3. **Howard Chang** (Stanford) — lncRNA biology, immune regulation. *Verify no COI.*
4. **John Mattick** (Garvan/UNSW) — lncRNA function and annotation. *Verify no COI.*
5. **Aaron Newman** (Stanford) — CIBERSORTx / cell-type deconvolution methodology. *Verify no COI.*

Backup pool (in case of declines):
- **Stein Aerts** (KU Leuven) — single-cell regulation; comparator computational methods
- **Jacques Banchereau** (Jackson Lab) — translational immunology, type-2 disease

## H. Pre-submission self-checks (post-format conversion)

- [ ] Read full manuscript once more in Word format (line breaks/figure placement check)
- [ ] Verify reference numbering matches in-text after CSL conversion
- [ ] Verify figure callouts in correct order (Fig 1, 2A, 2B, 3, 4, 5, 6)
- [ ] Confirm Table callouts in order (Table 1, 2, 3)
- [ ] Spell-check (US English; Frontiers default)
- [ ] Confirm gene names italicized throughout (`*IDI2-AS1*`, `*IL5*`)

---

## Action items in priority order

1. **Trim Abstract from 470 → ≤350 words** (~25 minutes)
2. **Verify [VERIFY] references via PubMed** (Phase C of current workflow; WebFetch-driven)
3. **Draft Fig 1 study-design schematic** (BioRender / illustrator; 1–2 hours)
4. **Format Table 1, 2, 3 from CSV → paper-ready** (`manuscript/tables_for_paper.md`)
5. **Push code to public GitHub + update Methods §2.6 URL**
6. **Confirm author affiliation + ORCID; add COI / funding / ethics block to cover letter**
7. **Confirm 3 suggested reviewers (replace placeholders)**
8. **Pandoc/CSL conversion to Frontiers numbered reference style**
9. **Final read in Word format**
10. **Submit via https://www.frontiersin.org/submission/**
