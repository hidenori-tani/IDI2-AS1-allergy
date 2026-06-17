# BBRC Submission Checklist

**Target journal:** *Biochemical and Biophysical Research Communications* (Elsevier)
**Article type:** Full-Length Research Paper
**Submission date (planned):** 2026-04-24
**Author:** Hidenori Tani (sole)
**Portal:** Elsevier Editorial Manager

---

## 1. Manuscript files

| Item | File | Status |
|------|------|--------|
| Cover letter (DOCX) | `manuscript/Cover_Letter_BBRC.docx` | ✅ Built (Times New Roman 11pt) |
| Cover letter (Markdown source) | `manuscript/cover_letter_bbrc.md` | ✅ |
| Main manuscript (DOCX) | `manuscript/full_manuscript_bbrc.docx` | ✅ Built (citation style = `[1]` Elsevier Vancouver; 7,323 words body) |
| Source markdown | `manuscript/00_abstract.md` … `07_figure_legends.md` | ✅ |
| Tables (DOCX) | `manuscript/Tables_BBRC.docx` | ✅ Built (identical content to AllergolInt; 3 tables) |
| Reference list | rendered inline by pandoc + `elsevier-vancouver.csl` from `references.bib` | ✅ |
| Highlights (3–5 bullets, ≤ 85 char each) | `manuscript/Highlights_BBRC.docx` | ✅ Built (5 bullets, approved) |
| Graphical abstract (optional) | — | ➖ Skip (not required) |

## 2. Figures

BBRC requires halftone raster images at ≥ 300 dpi (single-column 1063 px / full-page 2244 px) or bitmapped line drawings at ≥ 1000 dpi. Current submission files are vector PDFs (suitable for initial submission via Editorial Manager; TIFF/PNG conversion may be requested at acceptance).

| File | Format | Action required |
|------|--------|-----------------|
| `results/figures/submission/Figure1.pdf` (study design) | Vector PDF | Keep for initial submission |
| `results/figures/submission/Figure2.pdf` (DEG / forest) | Vector PDF | Keep for initial submission |
| `results/figures/submission/Figure3.pdf` (correlation / scatter) | Vector PDF | Keep for initial submission |
| `results/figures/submission/Figure4.pdf` (cell-type adjusted / mediation) | Vector PDF | Keep for initial submission |
| `results/figures/submission/Figure5.pdf` (specificity heatmaps A+B) | Vector PDF | Keep for initial submission |

**Note on figure count:** Short Communication path limits figures to 4; Full-Length Research Paper has no limit — current 5 figures are fine.

**If accepted:** regenerate Figure 1–5 as TIFF at ≥ 300 dpi using `manuscript/build_labeled_figures.py` (already exists).

## 3. Declarations (inside manuscript)

All items present in `manuscript/06_declarations.md`:
- ✅ Author contributions (CRediT taxonomy, with ORCID)
- ✅ Conflict of interest (none declared)
- ✅ Funding (none received)
- ✅ Acknowledgments
- ✅ Data availability (GEO accessions + GitHub repo + MIT license)
- ✅ Generative AI disclosure (Claude Code)

## 4. Editorial Manager portal fields

- ✅ Title
- ✅ Abstract (299 words — within Elsevier 250–300 range)
- ✅ Keywords (5): Asthma; Cell composition; Eosinophil; IL5; Long noncoding RNA
- ✅ Corresponding author contact (Tani, hidenori.tani@yok.hamayaku.ac.jp)
- ✅ ORCID (0000-0001-6390-4136)
- ✅ Highlights (3–5 bullets, ≤ 85 char) — `Highlights_BBRC.docx`
- ➖ Suggested reviewers — **Not provided** (standard practice for this author at BBRC)
- ✅ No conflicts statement
- ✅ No previous/concurrent submission declaration (in cover letter)

## 5. Citation style sanity check

- Engine: pandoc + citeproc + `elsevier-vancouver.csl`
- Format: in-text `[1]`, `[1,2]`, `[1–3]`; bibliography numeric-sequence (initials first, journal abbreviated, volume (year) pages)
- 63 citations detected in rebuilt DOCX (matches expected from `references.bib`)
- CSL source: https://github.com/citation-style-language/styles/blob/master/elsevier-vancouver.csl

## 6. Remaining TODOs before submission

All package files are built. The only remaining steps are manual / portal-dependent:

1. **Final proofread** of `full_manuscript_bbrc.docx` by the author (citation numbers, Figure calls, section headings)
2. **Create Editorial Manager account / log in** at the BBRC portal
3. **Upload files** in the order: cover letter → manuscript → tables → highlights → figures (5 PDFs)
4. **Complete portal metadata** (abstract, keywords, CRediT, COI, data availability — all already drafted; copy-paste from the manuscript/declarations)
5. **Submit**. Expected decision turnaround: 45–60 days for Full-Length Research Paper.

## 7. Package file manifest (complete)

```
manuscript/
├── Cover_Letter_BBRC.docx         ← portal upload
├── full_manuscript_bbrc.docx      ← portal upload
├── Tables_BBRC.docx               ← portal upload
├── Highlights_BBRC.docx           ← portal upload
├── cover_letter_bbrc.md           (markdown source, reference only)
├── bbrc_submission_checklist.md   (this file)
├── elsevier-vancouver.csl         (citation style, used by build)
└── ...

results/figures/submission/
├── Figure1.pdf                    ← portal upload
├── Figure2.pdf                    ← portal upload
├── Figure3.pdf                    ← portal upload
├── Figure4.pdf                    ← portal upload
└── Figure5.pdf                    ← portal upload
```
