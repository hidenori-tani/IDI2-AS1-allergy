# Briefings in Bioinformatics — submission checklist

**Submission portal.** ScholarOne Manuscripts — https://mc.manuscriptcentral.com/bib

**Article type.** Method (use this when the system asks for article type).

**Review model.** BiB is single-blind by default (author info visible to reviewers). The main manuscript may contain author info; double-blind is optional and not necessary unless the author elects it.

## Files to upload

| Slot | File | Purpose |
|---|---|---|
| Cover letter | `manuscript/cover_letter_bib.docx` | Methodology-first framing, BiB scope match |
| Title page | `manuscript/title_page_bib.docx` | Author, affiliation, ORCID, word count, keywords |
| Main manuscript | `manuscript/full_manuscript_bib.docx` | Key Points + Abstract + Introduction + Methods + Results + Discussion + Declarations + Figure legends |
| Figure 1 | `results/figures/submission_v2/Figure1.pdf` | Study design / workflow schematic |
| Figure 2 | `results/figures/submission_v2/Figure2.pdf` | Random-effects meta-analysis forest plots |
| Figure 3 | `results/figures/submission_v2/Figure3.pdf` | Sample-level Spearman scatter per cohort |
| Figure 4 | `results/figures/submission_v2/Figure4.pdf` | Cell-composition-adjusted partial correlation (A: raw; B: eosinophil signature) |
| Figure 5 | `results/figures/submission_v2/Figure5.pdf` | Comparator lncRNA + cytokine specificity heatmap |
| Supplementary Figure 1 | `results/figures/submission_v2/SuppFigure1.pdf` | Th2 signature partial correlation |
| Tables | `manuscript/Tables_BBRC.docx` (rename to `Tables_BIB.docx` if requested) | Table 1 (datasets), Table 2 (DE), Table 3 (correlation + mediation) |

## At ScholarOne, the system will request

1. **Title** — paste from `title_page_bib.md`.
2. **Running title** — "Cell-composition-adjusted bulk re-analysis of low-abundance lncRNAs"
3. **Keywords (8)** — long noncoding RNA; bulk RNA-seq; cell-composition deconvolution; random-effects meta-analysis; partial correlation; mediation analysis; *IL5*; type-2 inflammation
4. **Abstract** — paste from `00_abstract_v3.md` (or let the system extract from main DOCX).
5. **Key Points** — paste 5 bullets from `00_key_points_v3.md` if a separate slot is provided.
6. **Author list** — Hidenori Tani (corresponding author), Yokohama University of Pharmacy, ORCID 0000-0001-6390-4136.
7. **Funding** — "No specific funding was received for this work."
8. **Conflict of interest** — "The author declares no conflict of interest."
9. **Suggested reviewers** — leave blank or provide on request.
10. **Data availability** — public GEO datasets (GSE152004, GSE121212, GSE246323, GSE58640, GSE136825); analysis code at https://github.com/hidenori-tani/IDI2-AS1-allergy under MIT license.

## Pre-submit verification

- [ ] Open `full_manuscript_bib.docx` in Word and confirm: (a) section order Key Points → Abstract → Introduction → Methods → Results → Discussion → Declarations → Figure legends; (b) Vancouver numerical superscript references rendered; (c) subscripts/superscripts (log<sub>2</sub>FC, *I*<sup>2</sup>) rendered.
- [ ] Open `title_page_bib.docx` and confirm author info, ORCID, word count, keywords.
- [ ] Open `cover_letter_bib.docx` and confirm date 2026-05-16, BiB framing, "Method" article type, no residual BBRC wording.
- [ ] Confirm Figure 1-5 + SuppFigure1 in `results/figures/submission_v2/` open correctly as PDFs.
- [ ] Confirm Tables file (`Tables_BBRC.docx`, possibly renamed) opens correctly.
- [ ] At ScholarOne, after upload, generate the system PDF proof and verify nothing is corrupted before clicking "Submit".

## Word counts (estimated)

- Main text (Introduction + Methods + Results + Discussion): ~ 6,200 words
- Abstract: ~ 380 words (BiB target 250-300; acceptable for Method papers)
- Key Points: 5 bullets, ~ 130 words total
- References: ~ 25 (Vancouver numerical superscript)

## Re-build command

```bash
cd ~/claude-work/research/paper-IDI2-AS1-allergy_dry/manuscript
./build_docx_bib.sh
```

Produces: `title_page_bib.docx`, `cover_letter_bib.docx`, `full_manuscript_bib.docx`.

## Files preserved from BBRC submission

- `full_manuscript_bbrc_v2.docx` — BBRC R1 submission (rejected 2026-05-16 by Michael Lichten)
- `Cover_Letter_BBRC.docx`, `Highlights_BBRC.docx`, `Declaration_of_Interest_BBRC.docx`, `Tables_BBRC.docx` — BBRC submission package
- `results/figures/submission_v2/` — re-used for BiB (figures are publication-ready PDFs, all panels ≥ 8 pt)
- All v1, v2 markdown files retained
