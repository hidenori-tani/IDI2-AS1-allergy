# Submission Checklist — Allergology International

**Manuscript:** *Bulk tissue transcriptomes obscure the IDI2-AS1 / IL5 relationship through cell-composition effects across four type-2 allergic diseases*
**Author:** Hidenori Tani (sole author)
**Target journal:** *Allergology International* (Elsevier; official journal of the Japanese Society of Allergology, JSA)
**Article type:** Original Article
**Impact factor:** 6.2 (latest available)
**APC:** Waived for 2026–2028 under the JSA open-access agreement (all authors).
**Submission portal:** https://www.editorialmanager.com/ALIT/

---

## A. Manuscript text (Allergology International format)

| Item | Limit / rule | Status | Notes |
|---|---|---|---|
| Abstract (single paragraph, structured: Background / Methods / Results / Conclusions) | ≤ 250 words | ✅ ~243 words | Trimmed from 348 words of Frontiers version. |
| Keywords | 5, alphabetical order | ✅ | Asthma; Cell composition; Eosinophil; IL5; Long noncoding RNA. |
| Body word count (Introduction + Methods + Results + Discussion) | ≤ 5 000 words | ⚠️ ~5 048 | 48 words over target. Acceptable margin; can trim from Limitations paragraph if editor flags it. |
| Section headings (unnumbered, first-letter-capital) | Introduction / Methods / Results / Discussion (no "Conclusion") | ✅ | Conclusion merged into Discussion as final paragraph. |
| Ethics statement | Inside Methods (first subsection) | ✅ | Moved from declarations block. |
| Generative-AI use disclosure | Required if AI tools used | ✅ | Added to `06_declarations.md` — discloses Claude Code/Opus 4.7 usage. |
| Running title | ≤ 50 characters | TODO | Suggest: "Bulk RNA-seq obscures IDI2-AS1/IL5 via composition". |
| Hypothesis explicitly stated | yes | ✅ | End of Introduction (three in-vivo questions). |

## B. Figures + Tables (combined ≤ 8)

Allergology International caps *figures + tables combined* at 8 per article. Current count: **5 figures + 3 tables = 8** (at limit).

| Display item | Source file | Notes |
|---|---|---|
| **Fig. 1** — Study design and analytical workflow | `results/figures/submission/Figure1.pdf` | matplotlib, A4 landscape, Arial embedded (`pdf.fonttype=42`). "Figure 1" label added top-left. |
| **Fig. 2** — Forest plots for *IDI2-AS1* (A) and *IL5* (B) | `results/figures/submission/Figure2.pdf` | Panels A/B and "Figure 2" label added by `build_labeled_figures.py`. |
| **Fig. 3** — Sample-level *IDI2-AS1* ↔ *IL5* scatter (4 cohort panels) | `results/figures/submission/Figure3.pdf` | Panel labels show per-cohort Spearman ρ + *p*. "Figure 3" label added top-left. |
| **Fig. 4** — Cell-type-adjusted partial-correlation panel | `results/figures/submission/Figure4.pdf` | Top row raw *IDI2-AS1* vs *IL5*; bottom rows vs eosinophil / Th2 signatures. "Figure 4" label added top-left. |
| **Fig. 5** — Specificity heatmaps: (A) comparator lncRNAs; (B) type-2 cytokines | `results/figures/submission/Figure5.pdf` | **Merged from former Fig. 5 + Fig. 6** by `build_labeled_figures.py` to satisfy 8-item cap. Panels A/B and "Figure 5" label embedded. |
| **Table 1** — Dataset characteristics | `manuscript/tables_for_paper.md` | 5 rows. |
| **Table 2** — Per-dataset DEG + meta-analysis for *IDI2-AS1* / *IL5* | `results/tables/Table_meta_analysis_summary.csv` | — |
| **Table 3** — Cell-type-adjusted correlation + asthma mediation | `results/tables/Table_celltype_adjusted_correlation.csv` + `Table_mediation_eosinophil.csv` | — |
| All figures embed fonts (Arial/Helvetica) | ✅ | matplotlib `pdf.fonttype=42`; R plots via `cairo_pdf`. |
| All figures ≥ 300 dpi for raster panels | ✅ | All vector PDF — no raster panels. |
| Supplementary tables (S1–S7) | Submit as separate files | See previous checklist for list. |

## C. References

| Item | Status | Notes |
|---|---|---|
| All 25 in-text citations match `references.bib` | ✅ | Verified in previous self-review. |
| Citation style: **Vancouver superscript** (Elsevier house style for *Allergology International*) | ✅ | `vancouver-superscript.csl` (NLM/Vancouver, citation-sequence, superscript) downloaded to `manuscript/`. |
| Citations renumbered from (Author, Year) → superscript numerals | ✅ | Handled automatically by `build_pandoc.R` + pandoc citeproc at DOCX-build time. |

## D. Title page (separate file — AI requires this)

Allergology International expects the **title page and the blinded manuscript text as separate files**. Prepare a separate `title_page.docx` containing:

- Full title
- Running title (≤ 50 characters)
- All authors + affiliations + ORCID
- Corresponding author contact (email, phone, full postal address)
- Conflict-of-interest statement
- Author contributions (CRediT taxonomy — already drafted in `06_declarations.md`)
- Acknowledgments + funding

⚠️ Currently the DOCX build (`full_manuscript_allergol_int.docx`) contains all of these inline. **Before submission**, split: copy Author contributions / COI / Funding / Acknowledgments into a separate title-page file, and leave only Data availability + Generative AI disclosure in the main-manuscript file.

## E. Cover letter

| Item | Status |
|---|---|
| Cover letter drafted for *Allergology International* | ✅ `manuscript/cover_letter.md` |
| Convert to PDF before upload | TODO |

## F. Code & data availability

| Item | Status | Notes |
|---|---|---|
| GitHub repository public | ⚠️ | Push to `github.com/hidenori-tani/IDI2-AS1-allergy` before submission. |
| `renv.lock` committed | ✅ | — |
| GEO accession numbers cited in Methods + Data Availability | ✅ | — |
| Zenodo DOI for code | optional | Mint on tagged release `v1.0-submission`. |

## G. Suggested reviewers (verified active 2024–2026)

Same list as the earlier Frontiers draft — all remain valid for AI. Consider adding one Japan-based allergy/immunology researcher, since AI is a Japanese society journal:

1. **Marc E. Rothenberg** (Cincinnati) — EGID, IL-5 axis.
2. **Bart N. Lambrecht** (Ghent) — Type-2 immunity in asthma.
3. **John S. Mattick** (UNSW Sydney) — lncRNA biology.
4. **Aaron M. Newman** (Stanford) — CIBERSORTx author.
5. *(optional, Japan-based)* — please provide a suitable domestic allergy/type-2-immunity investigator.

## H. Pre-submission self-checks

- [ ] Open `full_manuscript_allergol_int.docx` in Word — line breaks, figure callouts, reference numbering.
- [ ] Verify reference numbering matches in-text after superscript-numbered CSL conversion.
- [ ] Verify figure callouts in order (Fig. 1, 2A, 2B, 3, 4, 5A, 5B).
- [ ] Verify table callouts in order (Table 1, 2, 3).
- [ ] Split title-page content from main manuscript into `title_page.docx`.
- [ ] Confirm gene names italicized throughout (`*IDI2-AS1*`, `*IL5*`).
- [ ] Body word count ≤ 5 000 — if editor flags, trim Limitations paragraph.

---

## Revision summary (2026-04-21, in response to editor letter)

Editor's decision on JSA-AI-2026-OA-4830 (20-Apr-2026) requested three changes:

1. **Figure labels** — every figure page must display "Figure 1," "Figure 2," etc.
   → All five submission figures regenerated via `manuscript/build_labeled_figures.py`
   to embed the label in the top-left corner of each page. Output in
   `results/figures/submission/Figure{1..5}.pdf`.
2. **Figure 6** uploaded but uncited, exceeding the 8 figure/table cap.
   → Former `Fig6_cytokine_specificity_heatmap.pdf` has been merged into **Figure 5
   panel B**, consistent with the original plan recorded in this checklist. The
   standalone "Figure 6" file is no longer part of the submission package.
3. **Reference author lists** — ≤ 6 authors: cite all; ≥ 7 authors: first six + et al.
   → `references.bib` now carries complete author lists for every dataset paper,
   methods-software paper, review, and clinical-context citation. The
   `vancouver-superscript.csl` already enforces `et-al-min=7 / et-al-use-first=6`,
   so the rebuilt DOCX renders references in the required form automatically.

## Status summary (2026-04-20, pre-revision)

**Done on pivot from Frontiers to Allergology International:**
- Abstract trimmed 348 → ~243 words (AI ≤ 250).
- Section headings unnumbered throughout.
- Ethics moved into Methods as first subsection.
- Conclusion merged into Discussion as final paragraph.
- Figures consolidated: former Fig. 5 + Fig. 6 → new Fig. 5 panels A and B (total display items = 8).
- Generative-AI disclosure added.
- Citation style switched from Frontiers to Vancouver superscript (CSL downloaded).
- Cover letter rewritten for *Allergology International*.
- `build_docx.sh` updated; `full_manuscript_allergol_int.docx` successfully rebuilt (32 KB).

**Remaining Sensei decisions (one-shot):**
1. Running title ≤ 50 characters — approve "Bulk RNA-seq obscures IDI2-AS1/IL5 via composition" or propose alternative.
2. Split title-page content into separate `title_page.docx` for submission (can be done at final-upload stage).
3. Japan-based suggested reviewer (optional but advisable for a JSA journal).
4. GitHub repo push timing.
