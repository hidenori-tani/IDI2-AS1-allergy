#!/usr/bin/env bash
# Rebuild full_manuscript_bbrc_v2.docx for BBRC revision (Lichten letter,
# Manuscript No. BBRC-26-2497).
#
# Differences vs build_docx.sh:
#   - Uses 02_methods_v2.md (Fig. 4 -> "Fig. 4 and Supplementary Fig. 1")
#   - Uses 03_results_v2.md (same Fig. 4 reference update)
#   - Uses 07_figure_legends_v2.md (Fig. 4 now A+B only; Supp. Fig. 1 legend added)
#   - Output filename: full_manuscript_bbrc_v2.docx
#
# Originals are preserved.

set -euo pipefail
cd "$(dirname "$0")"

: > full_manuscript_v2.md
for f in 00_abstract.md 01_introduction.md 02_methods_v2.md 03_results_v2.md \
         04_discussion.md 05_conclusion.md 06_declarations.md \
         07_figure_legends_v2.md; do
  cat "$f" >> full_manuscript_v2.md
  printf '\n\n' >> full_manuscript_v2.md
done

# Reuse build_pandoc.R but point it at the v2 markdown input.
# We do this by creating a small wrapper that overrides the input filename.
Rscript -e '
md_in  <- "full_manuscript_v2.md"
md_out <- "full_manuscript_v2_pandoc.md"
md     <- readLines(md_in, warn = FALSE)

# (Mirror the citation rewrite + YAML steps from build_pandoc.R)
src <- paste(md, collapse = "\n")

# Re-use build_pandoc.R s logic by sourcing it after rebinding the file paths.
# build_pandoc.R reads full_manuscript.md and writes full_manuscript_pandoc.md;
# easiest is to symlink/copy.
file.copy(md_in, "full_manuscript.md", overwrite = TRUE)
source("build_pandoc.R")
# build_pandoc.R produces full_manuscript_pandoc.md; move it to v2 name.
if (file.exists("full_manuscript_pandoc.md")) {
  file.rename("full_manuscript_pandoc.md", md_out)
}
'

pandoc full_manuscript_v2_pandoc.md \
  --citeproc \
  --bibliography=references.bib \
  --csl=elsevier-vancouver.csl \
  -o full_manuscript_bbrc_v2.docx

echo "Built: full_manuscript_bbrc_v2.docx ($(wc -c < full_manuscript_bbrc_v2.docx) bytes)"
