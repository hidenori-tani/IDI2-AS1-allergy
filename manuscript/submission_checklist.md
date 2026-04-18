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
| Abstract (≤350 words) | ✅ 348 words | Trimmed in B-pass (Frontiers Original Research max = 350). |
| Introduction (700–900 words) | ✅ ~670 words | Acceptable; includes Tani 2012 lncRNA-stability citation. |
| Materials & Methods | ✅ ~970 words | Reproducibility-complete; software citations added in C-pass. |
| Results | ✅ 1,159 words | 5 subsections, mapped to Fig 2–6. |
| Discussion | ✅ 1,215 words | 5 paragraphs (Summary → Mechanism → Generalization → Clinical → Limitations). |
| Conclusion | ✅ 142 words | Within ≤200 word target. |
| Total body word count | ✅ 4,798 | Within typical Frontiers range (4,000–8,000). |
| Section headings use Frontiers numbering (1., 2., 3., 3.1, …) | ✅ | Already followed. |
| Hypothesis explicitly stated | ✅ | End of Introduction (3 questions). |

## B. Figures

| Figure | Source file | Caption draft needed | Status |
|---|---|---|---|
| **Fig 1: Study design schematic** | `results/figures/Fig1_study_design.pdf` | TODO | ✅ PDF generated programmatically via R/grid (`code/R/11_fig1_study_design.R`); A4 landscape, 4 stages, ASCII-safe. Editable: re-run script after textual tweaks. Replace with BioRender if a glossier visual is preferred. |
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
| All in-text citations match `references.bib` | ✅ | 25/25 in-text citations correspond to bib entries (verified in C-pass via grep). |
| `[VERIFIED]` entries (8 software + methods) | ✅ | Confirmed at bib write-time. |
| `[VERIFY]` → `[VERIFIED via CrossRef]` (13) | ✅ | All 13 confirmed via CrossRef DOI / PubMed E-utilities in C-pass. **Substantive correction:** GSE136825 cited as Wang 2019 → corrected to Peng Y et al., Eur Respir J 2019;54:1900732 (the actual GEO-linked publication). Kleuskens 2024 placeholders filled (J Allergy Clin Immunol 153:780-792). |
| `[USER-OWNED]` entries (4) → all `[VERIFIED]` | ✅ | All 4 Tani-lab papers confirmed via PubMed/CrossRef/J-STAGE. **Author-initial corrections:** Endo Y. → Endo R.; Yagi M. → Yagi Y.; Abe K. → Abe R. (all verified against published author lists). |
| Frontiers reference style (Vancouver / numbered) | TODO | Convert from `.bib` to Frontiers numbered format using Pandoc + Frontiers CSL on final pre-submission. |

## E. Cover letter & metadata

| Item | Status | Action |
|---|---|---|
| Cover letter PDF | ✅ | `manuscript/cover_letter.md` (convert to PDF). |
| Authors (single) | ✅ | Hidenori Tani. |
| Affiliation, ORCID | ✅ | ORCID 0000-0001-6390-4136 (verified via ORCID API search) added to cover_letter.md. Department field on submission portal: please select the closest match (likely "Department of Molecular Biology" or similar — please verify on portal). |
| Conflict-of-interest declaration | ✅ | Drafted in `06_declarations.md` ("The author declares that the research was conducted in the absence of any commercial or financial relationships that could be construed as a potential conflict of interest."). |
| Funding declaration | ✅ | Drafted in `06_declarations.md` as "no specific funding". **If a grant should be listed (e.g., 科研費), please tell me the grant number and I will edit.** |
| Ethics statement | ✅ | Drafted in `06_declarations.md`. |
| Suggested reviewers (3–5) | ✅ | Verified active researchers — see Section G. |
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

## G. Suggested reviewers (verified active 2024–2026)

Each reviewer below has been confirmed by direct web lookup as currently active in their stated area. The author should still verify there is no recent co-authorship or other COI with each candidate before final submission.

1. **Marc E. Rothenberg, M.D., Ph.D.** — Director, Division of Allergy & Immunology and Cincinnati Center for Eosinophilic Disorders, Cincinnati Children's Hospital Medical Center. Eosinophilic gastrointestinal disorders, IL-5 axis, eosinophil biology. *Verified active 2026.*
2. **Bart N. Lambrecht, M.D., Ph.D.** — VIB-Ghent University Center for Inflammation Research. Type-2 immunity in asthma; cytokine network (author of Lambrecht et al., *Immunity* 2019, cited in this manuscript). *Verified active 2026 — 16 asthma publications 2024-2026.*
3. **Howard Y. Chang, M.D., Ph.D.** — Virginia & D.K. Ludwig Professor of Cancer Research, Stanford University. lncRNA biology, immune epigenomics. **NOTE: on academic leave 12/2024–12/2026 — may decline, treat as backup.**
4. **John S. Mattick, AO, FAA** — UNSW Sydney / Garvan Institute. lncRNA function and annotation (author of Mattick et al., *Nat Rev Mol Cell Biol* 2023, cited in this manuscript). *Verified active 2026 — 9 noncoding RNA publications 2023-2026.*
5. **Aaron M. Newman, Ph.D.** — Associate Professor of Biomedical Data Science, Stanford University. Developer of CIBERSORT/CIBERSORTx (cited in Methods §2.4). *Verified active 2026.*

Backup pool (in case of declines):
- **Stein Aerts** (KU Leuven) — single-cell regulation; computational methods
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

### ✅ Done (B/C self-review passes, 2026-04-18)
- Abstract trimmed to 348 words.
- All 25 in-text citations matched to bib; all author/year/journal/volume/pages verified.
- Wang 2019 → Peng 2019 correction propagated through manuscript.
- Software citations (DESeq2, apeglm, limma, metafor, ppcor, mediation, ComplexHeatmap, CIBERSORTx) added to Methods.
- Tani-lab citations (Tani 2012, Abe 2023, Yagi 2024) integrated into Introduction/Methods at appropriate points.

### Remaining action items (verification only — Sensei reviews + says yes/no)

**Done by AI on 2026-04-18 (please verify):**
- ✅ Fig 1 PDF generated at `results/figures/Fig1_study_design.pdf` (R/grid programmatic)
- ✅ Word docx with Frontiers numbered references at `manuscript/full_manuscript_frontiers.docx` (31 KB; pandoc + Frontiers CSL)
- ✅ Declarations section (Author Contributions / Funding / Acknowledgments / COI / Ethics / Data Availability) drafted in `06_declarations.md`
- ✅ ORCID 0000-0001-6390-4136 added to cover letter
- ✅ 5 suggested reviewers verified as currently active

**Sensei TODO (one-shot decisions):**
1. **Open `Fig1_study_design.pdf`** — does it look acceptable, or want me to swap to BioRender style?
2. **Open `full_manuscript_frontiers.docx` in Word** — final read for sentence flow / figure callouts (≈30-min read).
3. **GitHub push** — `gh` CLI is authenticated as `hidenori-tani`. **Say "GitHub push して" and I will create the public repo + push.** (After push, I'll also update the placeholder URL in Methods §2.6 + Data Availability + cover letter — currently set to `https://github.com/hidenori-tani/IDI2-AS1-allergy`.)
4. **Funding** — confirm "no specific funding" is correct, or give me a grant number to add.
5. **Department name on submission portal** — closest match to your affiliation block.
6. **Submit** via https://www.frontiersin.org/submission/ — upload `full_manuscript_frontiers.docx` + `cover_letter.md` (convert to PDF in Word first) + 6 figure PDFs + 3 tables.
