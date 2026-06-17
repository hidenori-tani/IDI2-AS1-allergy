# Response to Editor

**Manuscript:** BBRC-26-2497
**Title:** Bulk tissue transcriptomes obscure the IDI2-AS1 / IL5 relationship through cell-composition effects across four type-2 allergic diseases
**Author:** Hidenori Tani (Yokohama University of Pharmacy)
**Date:** 2026-05-12

---

Dear Dr. Lichten,

Thank you very much for your assessment of our manuscript and for the constructive guidance regarding figure readability. I appreciate the time you took to review the submission and to point me toward the BBRC Guide for Authors and the Elsevier artwork sizing instructions.

I have addressed both points raised in your letter. A point-by-point response follows.

---

## Point 1. Figure readability — font size

**Editor's comment.** "Many of the figures in the review copy of the manuscript are not readable; we cannot ask reviewers to spend their time on an article that cannot be clearly read. … As a rule of thumb, 6 point should be the absolute minimum size for fonts in figures (as they would appear in the final review copy); most type should be 8 point or larger. Increasing font size to meet this standard may require removing some figure panels or moving them to a supplement; please keep only those figure panels that are essential to the meaning of the manuscript."

**Action taken.** All five main figures and one new supplementary figure have been fully redrawn so that every text element in the review-copy PDF is ≥ 8 pt. I verified this directly on the final PDFs by extracting the font size of every text span; the minimum across all main figures and Supplementary Figure 1 is now 8.1 pt, with most text at 8.9–11.9 pt. No element falls below the 6 pt absolute minimum.

The specific changes are:

| Figure | Change | Before (review copy) | After (review copy) |
|---|---|---|---|
| Figure 1 (study design) | Source canvas reduced from 11.69 × 8.27 in to 9.0 × 7.2 in; all label fonts raised to ≥ 11 pt at source; sub/superscripts (log₂, *I*²) replaced with Unicode glyphs so every glyph renders at the declared 11 pt rather than the plotmath 0.66 × parent default | min 3.7 pt | min 8.1 pt |
| Figure 2 (forest plots) | Unchanged (already met the threshold) | min 8.9 pt | min 8.9 pt |
| Figure 3 (correlation scatter) | Source canvas reduced from 11 × 7 in to 9 × 7 in; ggplot `base_size` raised from 11 to 12; strip and axis text raised to 11 pt | min 5.5 pt | min 8.1 pt |
| Figure 4 (cell-type-adjusted scatter) | Restructured from a 3-row × 5-column composite (raw / eosinophil signature / Th2 signature) to a 2-panel composite showing only the raw scatter (panel A) and the eosinophil signature scatter (panel B). The Th2 / type-2 signature row was the least essential to the principal mediation finding and has been moved to **Supplementary Figure 1** in accordance with your suggestion. Source canvas 14 × 11 in → 9 × 6.6 in; `base_size` 9–10 → 12; strip and axis text 11 pt | min 3.3 pt | min 8.1 pt |
| Figure 5 (specificity heatmaps) | In-cell value labels raised from 8 pt to 11 pt; row / column names, column title, and annotation legend explicitly set to 12 pt; PDF height increased to prevent label–cell collisions | min 5.9 pt | min 8.1 pt |
| Supplementary Figure 1 (new) | New supplementary figure containing the *IDI2-AS1* vs Th2 / type-2 signature scatter previously shown as the bottom row of Figure 4 | n/a | min 8.1 pt |

In addition, every source figure is rendered at 9 in wide so that the post-processing scale to BBRC's 480 pt (≈ 6.67 in, double-column) content width applies only a 0.74 × shrink. With ≥ 11 pt at source this guarantees ≥ 8.15 pt in the final review copy, with comfortable margin above the 6 pt absolute floor.

The figure-legend file has been updated (`manuscript/07_figure_legends_v2.md`) to reflect the new Figure 4 panel structure (A + B only) and to add a Supplementary Figure 1 legend. The statistical content of Figure 4 is unchanged — the mediation analysis, partial correlation, and per-cohort raw correlation use the same point data and the same numerical values as in the original submission; only the layout has changed.

Files affected:

- `results/figures/submission_v2_tiff/Figure1.tif` — Figure 1
- `results/figures/submission_v2_tiff/Figure2.tif` — Figure 2
- `results/figures/submission_v2_tiff/Figure3.tif` — Figure 3
- `results/figures/submission_v2_tiff/Figure4.tif` — Figure 4 (new 2-panel layout)
- `results/figures/submission_v2_tiff/Figure5.tif` — Figure 5
- `results/figures/submission_v2_tiff/SuppFigure1.tif` — Supplementary Figure 1 (new)

All figures are LZW-compressed TIFFs rendered at 600 dpi (exceeds Elsevier's 500 dpi minimum for combination art); RGB color; embedded within the 174 mm (6.85 in) double-column width.

Underlying analysis code: new versions of the relevant scripts have been deposited alongside the originals (`code/R/11_fig1_study_design_v2.R`, `07_correlation_analysis_v2.R`, `09b_fig4_replot_v2.R`, `10_specificity_heatmaps_v2.R`, and `manuscript/build_labeled_figures_v2.py`) so that the figure regeneration is fully reproducible.

## Point 2. Highlights as a separate file

**Editor's comment.** "Highlights are mandatory. They consist of a short collection of bullet points that convey the core findings of the article and should be submitted in a separate file in the online submission system. Please use 'Highlights' in the file name and include 3 to 5 bullet points (maximum 85 characters, including spaces, per bullet point)."

**Action taken.** A file named **`Highlights_BBRC.docx`** has been uploaded as a separate file in this revision. It contains five bullet points conveying the core findings; every bullet is ≤ 80 characters (well within the 85-character limit). The content of the five bullets is:

1. Re-analysis of 5 public RNA-seq cohorts (n=856) across four IL5-driven allergies (80 chars)
2. Bulk-tissue IDI2-AS1 expression is uniformly null across all cohorts (I² ≈ 0) (77 chars)
3. Sample-level IDI2-AS1 covaries positively — not negatively — with IL5 (69 chars)
4. ≈ 90 % of the covariation is mediated by the eosinophil compartment (67 chars)
5. Framework is reusable for other cell-type-restricted lncRNA candidates (70 chars)

---

## Summary of new and modified files in this revision

**New / replaced files uploaded to Editorial Manager:**

- `Figure1.tif` … `Figure5.tif` (five redrawn main figures, LZW-compressed TIFF at 600 dpi)
- `SuppFigure1.tif` (new supplementary figure containing the moved Th2 panel, LZW-compressed TIFF at 600 dpi)
- `Highlights_BBRC.docx` (already present in the original submission; re-confirmed as a separate file in this revision)
- `Response_to_Reviewers_BBRC_v2.docx` (this letter — named to match the Editorial Manager upload slot "Response to Reviewers")
- `full_manuscript_bbrc_v2.docx` (updated figure-legend section: Figure 4 now A + B; new Supplementary Figure 1 legend added; two one-word body-text updates noted below)
- `Revised_Manuscript_with_Changes_Marked.docx` (v2 manuscript with all differences from the original submission shown as Word tracked revisions — Review pane can accept/reject each change)

**Minor body-text changes consequent to the Figure 4 restructure:**

- Methods, subsection "Sample-level correlation and cell-type-adjusted analysis": the parenthetical figure callout changed from "(Fig. 4; Table 3)" to "(Fig. 4 and Supplementary Fig. 1; Table 3)" so that the Th2 / type-2 signature visualization, now in Supplementary Figure 1, is still pointed to from the body text.
- Results, subsection "The tissue-level *IDI2-AS1* ↔ *IL5* association is mediated by eosinophil composition": the same callout update.
- The numerical content (partial correlation values, mediation ACME / ADE, table data) is unchanged in both sections — only the figure pointer was edited.

**Files not changed:**

- Abstract, Introduction, Discussion, Conclusion — unchanged.
- Tables 1–3 — unchanged.
- Cover Letter, Declaration of Interest — unchanged.

I am happy to make any further adjustments you may suggest, and I look forward to the opportunity for the manuscript to enter peer review.

With sincere thanks for your guidance,

Hidenori Tani
Associate Professor, Department of Health Pharmacy
Yokohama University of Pharmacy
601 Matano-cho, Totsuka-ku, Yokohama 245-0066, Japan
hidenori.tani@yok.hamayaku.ac.jp
ORCID: 0000-0001-6390-4136
