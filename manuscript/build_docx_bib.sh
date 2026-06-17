#!/usr/bin/env bash
# Rebuild full_manuscript_bib.docx for Briefings in Bioinformatics submission
# (Method article).
#
# Differences vs build_docx_v2.sh:
#   - Uses 00_abstract_v3.md (methodology-first re-framing)
#   - Uses 00_key_points_v3.md (BiB-required Key Points section)
#   - Uses 01_introduction_v3.md (lead with bulk-interpretation problem)
#   - Uses 02_methods_v2.md (journal-agnostic methods, reused unchanged)
#   - Uses 03_results_v3.md (sections re-headed as Pipeline Steps 1-3 + outputs)
#   - Uses 04_discussion_v3.md (pipeline reusability as primary contribution)
#   - Uses 07_figure_legends_v2.md (Fig. 4 A+B, SuppFig 1; reused unchanged)
#   - Output filenames:
#       full_manuscript_bib.docx   (main manuscript, anonymized — title page separate)
#       title_page_bib.docx        (title page with author info)
#       cover_letter_bib.docx      (cover letter)
#
# Originals (v1, v2) are preserved.

set -euo pipefail
cd "$(dirname "$0")"

# -------- 1. Title page --------
pandoc title_page_bib.md \
  -o title_page_bib.docx

# -------- 2. Cover letter --------
pandoc cover_letter_bib.md \
  -o cover_letter_bib.docx

# -------- 3. Main manuscript --------
# Build a combined markdown then run citeproc.
# Order: Key Points -> Abstract -> Introduction -> Methods -> Results -> Discussion
# -> Declarations -> Figure legends.

: > full_manuscript_bib.md
for f in 00_key_points_v3.md 00_abstract_v4.md 01_introduction_v4.md \
         02_methods_v4.md 03_results_v4.md 04_discussion_v4.md \
         06_declarations.md 07_figure_legends_v2.md; do
  cat "$f" >> full_manuscript_bib.md
  printf '\n\n' >> full_manuscript_bib.md
done

# Reuse build_pandoc.R (rebinds citation keys to (Author year) -> [n]).
Rscript -e '
md_in  <- "full_manuscript_bib.md"
md_out <- "full_manuscript_bib_pandoc.md"
file.copy(md_in, "full_manuscript.md", overwrite = TRUE)
source("build_pandoc.R")
if (file.exists("full_manuscript_pandoc.md")) {
  file.rename("full_manuscript_pandoc.md", md_out)
}
'

# Override YAML title with the new BiB title (build_pandoc.R hardcodes the old BBRC title),
# and convert HTML <sub>/<sup> tags into pandoc-native subscript/superscript syntax
# (~x~ / ^x^), which pandoc reliably renders as Word sub/superscript runs.
python3 - <<'PYEOF'
from pathlib import Path
import re
title = ("A reusable cell-composition-adjusted re-analysis pipeline for "
         "interpreting bulk-tissue null results in low-abundance lncRNA "
         "studies: IDI2-AS1 / IL5 as a worked example across type-2 "
         "allergic diseases")
p = Path("full_manuscript_bib_pandoc.md")
text = p.read_text(encoding="utf-8")

# 1. Override YAML title.
text = re.sub(r'title: "[^"]+"', 'title: "' + title + '"', text, count=1)

# 2. Convert HTML <sub>/<sup> tags to pandoc native ~ / ^ syntax.
#    Pandoc converts ~x~ -> subscript and ^x^ -> superscript reliably for DOCX.
#    Use a non-greedy match so multi-character content is captured correctly,
#    and convert any embedded space to non-breaking '\ ' (pandoc convention).
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

# BiB uses numerical Vancouver references with superscript citations.
# vancouver-superscript.csl is already in this directory (used in earlier Frontiers
# build).
pandoc full_manuscript_bib_pandoc.md \
  --citeproc \
  --bibliography=references.bib \
  --csl=vancouver-superscript.csl \
  -o full_manuscript_bib.docx

echo "Built:"
echo "  title_page_bib.docx   ($(wc -c < title_page_bib.docx) bytes)"
echo "  cover_letter_bib.docx ($(wc -c < cover_letter_bib.docx) bytes)"
echo "  full_manuscript_bib.docx ($(wc -c < full_manuscript_bib.docx) bytes)"
