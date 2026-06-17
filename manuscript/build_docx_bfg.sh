#!/usr/bin/env bash
# Rebuild full_manuscript_bfg.docx for Briefings in Functional Genomics submission
# (Original Article — methodology), via OUP Transfer Desk from BiB (BIB-26-1123).
#
# Differences vs build_docx_bib.sh:
#   - Uses cover_letter_bfg.md (BFG-specific framing + transfer notice)
#   - Uses title_page_bfg.md (BFG article type + subscription route)
#   - Manuscript body (key points / abstract / introduction / methods / results /
#     discussion / declarations / figure legends) is reused unchanged from
#     the BiB v3/v4 markdown sources because the scientific content is unchanged
#     and BFG editorial assessment will indicate whether further reformatting
#     (e.g., dropping Key Points) is required.
#
# Output filenames:
#   full_manuscript_bfg.docx   (main manuscript)
#   title_page_bfg.docx        (title page with author info)
#   cover_letter_bfg.docx      (BFG cover letter)
#
# Originals (BiB) are preserved.

set -euo pipefail
cd "$(dirname "$0")"

# -------- 1. Title page --------
pandoc title_page_bfg.md \
  -o title_page_bfg.docx

# -------- 2. Cover letter --------
pandoc cover_letter_bfg.md \
  -o cover_letter_bfg.docx

# -------- 3. Main manuscript --------
# Build a combined markdown then run citeproc.
# Order: Key Points -> Abstract -> Introduction -> Methods -> Results -> Discussion
# -> Declarations -> Figure legends.
# (BFG may not require a Key Points section; we retain it for now and will drop
# it if BFG editorial office requests reformatting.)

: > full_manuscript_bfg.md
for f in 00_key_points_v3.md 00_abstract_v4.md 01_introduction_v4.md \
         02_methods_v4.md 03_results_v4.md 04_discussion_v4.md \
         06_declarations.md 07_figure_legends_v2.md; do
  cat "$f" >> full_manuscript_bfg.md
  printf '\n\n' >> full_manuscript_bfg.md
done

# Reuse build_pandoc.R (rebinds citation keys to (Author year) -> [n]).
Rscript -e '
md_in  <- "full_manuscript_bfg.md"
md_out <- "full_manuscript_bfg_pandoc.md"
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
p = Path("full_manuscript_bfg_pandoc.md")
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

# BFG uses numerical Vancouver-style references; reuse vancouver-superscript.csl.
pandoc full_manuscript_bfg_pandoc.md \
  --citeproc \
  --bibliography=references.bib \
  --csl=vancouver-superscript.csl \
  -o full_manuscript_bfg.docx

echo "Built:"
echo "  title_page_bfg.docx   ($(wc -c < title_page_bfg.docx) bytes)"
echo "  cover_letter_bfg.docx ($(wc -c < cover_letter_bfg.docx) bytes)"
echo "  full_manuscript_bfg.docx ($(wc -c < full_manuscript_bfg.docx) bytes)"
