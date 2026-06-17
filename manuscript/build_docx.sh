#!/usr/bin/env bash
# Rebuild the Allergology International-style .docx from the section markdown files.
# Steps:
#   1. concatenate 00_abstract..06_declarations -> full_manuscript.md
#      (05_conclusion.md is kept as an empty placeholder — AI has no separate
#      Conclusion section, so its content was merged into Discussion)
#   2. Rscript build_pandoc.R -> full_manuscript_pandoc.md (citation rewrite + YAML)
#   3. pandoc + citeproc + vancouver-superscript CSL -> full_manuscript_allergol_int.docx
set -euo pipefail
cd "$(dirname "$0")"

# Concatenate sections, inserting a blank line between files so that pandoc
# reliably recognizes the leading `## Section` of each file as a Heading 2.
# (Plain `cat` without separators caused Introduction/Methods/Results/Discussion
# H2s to be silently dropped in the DOCX output.)
: > full_manuscript.md
for f in 00_abstract.md 01_introduction.md 02_methods.md 03_results.md \
         04_discussion.md 05_conclusion.md 06_declarations.md \
         07_figure_legends.md; do
  cat "$f" >> full_manuscript.md
  printf '\n\n' >> full_manuscript.md
done

Rscript build_pandoc.R

pandoc full_manuscript_pandoc.md \
  --citeproc \
  --bibliography=references.bib \
  --csl=vancouver-superscript.csl \
  -o full_manuscript_allergol_int.docx

echo "Built: full_manuscript_allergol_int.docx ($(wc -c < full_manuscript_allergol_int.docx) bytes)"

# BBRC target: Elsevier Vancouver (numeric square brackets)
pandoc full_manuscript_pandoc.md \
  --citeproc \
  --bibliography=references.bib \
  --csl=elsevier-vancouver.csl \
  -o full_manuscript_bbrc.docx

echo "Built: full_manuscript_bbrc.docx ($(wc -c < full_manuscript_bbrc.docx) bytes)"
