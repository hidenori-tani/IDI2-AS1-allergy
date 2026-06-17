# Response to Editor — JSA-AI-2026-OA-4830

**Manuscript:** *Bulk tissue transcriptomes obscure the IDI2-AS1 / IL5 relationship through cell-composition effects across four type-2 allergic diseases*
**Author:** Hidenori Tani (sole author)
**Target journal:** *Allergology International*
**Date of revision:** 21 April 2026

Dear Editor,

Thank you for your email of 20 April 2026 and for the opportunity to revise the manuscript. I have addressed each of the three editorial requests in full. A point-by-point response is provided below, and a revised submission package is attached.

---

## 1. Figure number labels on every figure page

**Editor's request:** *"Please indicate the figure number either below or above each figure. Add labels such as 'Figure 1,' 'Figure 2,' and so on to every figure page."*

**Action taken:** All five submission figures have been regenerated to carry a visible "Figure 1," "Figure 2," … label in the top-left corner of the page. The labels are embedded into the PDF content stream (not comments), so they are preserved in every downstream format (PDF viewer, Word proof, typeset proof). The new files are provided as:

| Display item | Revised file |
|---|---|
| Figure 1 | `Figure1.pdf` |
| Figure 2 | `Figure2.pdf` |
| Figure 3 | `Figure3.pdf` |
| Figure 4 | `Figure4.pdf` |
| Figure 5 | `Figure5.pdf` |

The script used to embed the labels (`manuscript/build_labeled_figures.py`, based on PyMuPDF) is included in the reproducibility repository and will be part of the public release on acceptance, so the labeling step is fully reproducible.

---

## 2. Removal of uncited "Figure 6"

**Editor's observation:** *"A file for 'Figure 6' has been uploaded; however, it is not cited in the main text. … If Figure 6 is cited, the total number of figures/tables will exceed the journal's limit."*

**Explanation and action taken:** The file uploaded as "Figure 6" was an internal working file for the type-2 cytokine specificity heatmap, which was intended from the outset to appear as **panel B of Figure 5** (paired with the comparator lncRNA heatmap as panel A). This was the plan recorded in the submission checklist when the manuscript was adapted from the earlier *Frontiers in Immunology* draft to fit the *Allergology International* 8-item cap. The two working files were, however, uploaded separately during the portal submission, which produced the uncited "Figure 6" that the editorial office identified.

In the revised submission:

- The two heatmap panels have been combined into a single Figure 5 PDF (panels A and B side-by-side, with "Figure 5" and "A"/"B" panel labels embedded), consistent with the manuscript text.
- The standalone "Figure 6" file has been removed from the submission package.
- Total display items in the revised submission = **5 figures + 3 tables = 8**, within the journal's limit.

The manuscript text already cites these panels as *Fig. 5A* and *Fig. 5B*; no in-text changes were needed for this point.

---

## 3. Reference author-list formatting

**Editor's request:** *"Cite the names of all authors when there are six or fewer. When there are seven or more authors, list the first six authors followed by et al."*

**Action taken:** The reference list has been fully re-checked against CrossRef/PubMed and the BibTeX source (`references.bib`) now carries the complete author list for every entry. The CSL style for *Allergology International* (`vancouver-superscript.csl`) is configured with `et-al-min="7" et-al-use-first="6"`, which — given the complete underlying author lists — automatically renders each reference in exactly the required form:

- Entries with ≤ 6 authors → all authors cited (e.g., Statello et al. 2021, 4 authors; Endo et al. 2025, 3 authors; Kleuskens et al. 2024, 6 authors; Lambrecht et al. 2019, 3 authors).
- Entries with ≥ 7 authors → first six authors followed by *et al.* (e.g., Mattick et al. 2023, 29 authors; Sajuthi et al. 2020, 28 authors; Tsoi et al. 2019, 22 authors; Hirano et al. 2019, 22 authors; Travaglini et al. 2020, 18 authors; Sherrill et al. 2014, 17 authors; Bachert et al. 2017, 14 authors; Peng et al. 2019, 13 authors; Newman et al. 2019, 12 authors; Tani et al. 2012, 9 authors; Bel et al. 2014, 8 authors; Cabili et al. 2011, 7 authors; Ritchie et al. 2015, 7 authors).

The revised reference list in the rebuilt `full_manuscript_allergol_int.docx` reflects these settings. No citation was added, removed, or reordered — only the rendered form of the existing entries has changed.

---

## Files uploaded with this revision

| Item | File | Status |
|---|---|---|
| Main manuscript (single file, revised) | `full_manuscript_allergol_int.docx` | Rebuilt with complete author lists. |
| Figure 1 | `Figure1.pdf` | Revised; "Figure 1" label added. |
| Figure 2 | `Figure2.pdf` | Revised; panels A/B merged, "Figure 2" label added. |
| Figure 3 | `Figure3.pdf` | Revised; "Figure 3" label added. |
| Figure 4 | `Figure4.pdf` | Revised; "Figure 4" label added. |
| Figure 5 | `Figure5.pdf` | Revised; former Fig. 6 content integrated as panel B; "Figure 5" label added. |
| Cover letter (unchanged) | `Cover_Letter_AllergolInt.docx` | — |
| Tables (unchanged) | `Tables_AllergolInt.docx` | — |

No changes were made to the scientific content, word count, figure/table count, or suggested reviewers.

I am grateful for the editorial office's careful reading of the submission package. Please do not hesitate to contact me if any further clarification is needed.

Sincerely,

Hidenori Tani, Ph.D.
Associate Professor, Yokohama University of Pharmacy
hidenori.tani@yok.hamayaku.ac.jp
