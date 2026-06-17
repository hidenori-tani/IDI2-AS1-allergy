#!/usr/bin/env bash
# Rebuild full_manuscript_fig.docx for Functional & Integrative Genomics submission
# (Springer Nature, Methodology article type).
#
# Differences vs build_docx_bfg.sh:
#   - Uses cover_letter_fig.md (F&IG-specific framing, no transfer history)
#   - Uses title_page_fig.md (F&IG article type = Methodology)
#   - Uses 06_declarations_fig.md (consolidated under single "Declarations"
#     heading per Springer Nature requirements)
#   - Uses springer-basic-author-date.csl (author-year citations,
#     alphabetical reference list with DOI links — per F&IG instructions)
#
# Output filenames:
#   full_manuscript_fig.docx   (main manuscript)
#   title_page_fig.docx        (title page with author info)
#   cover_letter_fig.docx      (F&IG cover letter)
#
# Originals (BFG / BiB / BBRC) are preserved.

set -euo pipefail
cd "$(dirname "$0")"

# -------- 1. Title page --------
pandoc title_page_fig.md \
  -o title_page_fig.docx

# -------- 2. Cover letter --------
pandoc cover_letter_fig.md \
  -o cover_letter_fig.docx

# -------- 3. Main manuscript --------
# Build a combined markdown then run citeproc.
# Order: Title page (page 1) -> page break -> Key Points -> Abstract ->
# Introduction -> Methods -> Results -> Discussion -> Declarations -> Figure legends.
# Title page is included on page 1 per F&IG technical-check requirement
# (round 2, 2026-05-22): "Please include a title page as page 1."
# (F&IG does not formally require a Key Points section; we retain it for
# alignment with the manuscript's didactic structure. The editorial office
# will indicate if removal is preferred.)

: > full_manuscript_fig.md
cat title_page_fig.md >> full_manuscript_fig.md
# Insert a Word-native page break (pandoc raw OpenXML block).
# `\newpage` is LaTeX-only and is ignored by pandoc's docx writer.
printf '\n\n```{=openxml}\n<w:p><w:r><w:br w:type="page"/></w:r></w:p>\n```\n\n' >> full_manuscript_fig.md
for f in 00_key_points_v3.md 00_abstract_v4.md 01_introduction_v4.md \
         02_methods_v4.md 03_results_v4.md 04_discussion_v4.md \
         06_declarations_fig.md 07_figure_legends_v2.md; do
  cat "$f" >> full_manuscript_fig.md
  printf '\n\n' >> full_manuscript_fig.md
done

# Reuse build_pandoc.R (rebinds citation keys to (Author year) -> [@key]).
Rscript -e '
md_in  <- "full_manuscript_fig.md"
md_out <- "full_manuscript_fig_pandoc.md"
file.copy(md_in, "full_manuscript.md", overwrite = TRUE)
source("build_pandoc.R")
if (file.exists("full_manuscript_pandoc.md")) {
  file.rename("full_manuscript_pandoc.md", md_out)
}
'

# Override YAML title and convert HTML sub/sup to pandoc native syntax.
python3 - <<'PYEOF'
from pathlib import Path
import re
title = ("A reusable cell-composition-adjusted re-analysis pipeline for "
         "interpreting bulk-tissue null results in low-abundance lncRNA "
         "studies: IDI2-AS1 / IL5 as a worked example across type-2 "
         "allergic diseases")
p = Path("full_manuscript_fig_pandoc.md")
text = p.read_text(encoding="utf-8")

# 1. Override YAML title.
text = re.sub(r'title: "[^"]+"', 'title: "' + title + '"', text, count=1)

# 2. Convert HTML <sub>/<sup> tags to pandoc native ~ / ^ syntax.
def _sub_replacer(m):
    inner = m.group(1).replace(' ', r'\ ')
    return '~' + inner + '~'
def _sup_replacer(m):
    inner = m.group(1).replace(' ', r'\ ')
    return '^' + inner + '^'

text, n_sub = re.subn(r'<sub>([^<]+?)</sub>', _sub_replacer, text)
text, n_sup = re.subn(r'<sup>([^<]+?)</sup>', _sup_replacer, text)

p.write_text(text, encoding="utf-8")
print(f'Title overridden: {title[:60]}...')
print(f'<sub> -> ~x~ conversions: {n_sub}')
print(f'<sup> -> ^x^ conversions: {n_sup}')
PYEOF

# F&IG uses Springer Nature Basic author-date style (Harvard-style
# (Author Year) in-text, alphabetical reference list with DOI links).
pandoc full_manuscript_fig_pandoc.md \
  --citeproc \
  --bibliography=references.bib \
  --csl=springer-basic-author-date.csl \
  -o full_manuscript_fig.docx

echo "Built:"
echo "  title_page_fig.docx     ($(wc -c < title_page_fig.docx) bytes)"
echo "  cover_letter_fig.docx   ($(wc -c < cover_letter_fig.docx) bytes)"
echo "  full_manuscript_fig.docx ($(wc -c < full_manuscript_fig.docx) bytes)"
