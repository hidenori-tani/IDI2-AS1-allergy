#!/usr/bin/env bash
# Build the Journal of Biomedical Informatics (Elsevier) submission package.
#
#   - v5 manuscript sources (deconvolution revision in response to F&IG peer review)
#   - Elsevier numbered Vancouver citations (elsevier-vancouver.csl)
#   - Title page embedded as page 1 (Elsevier accepts a combined file)
#   - 06_declarations_fig.md reused (Elsevier-style Declarations incl. updated
#     generative-AI statement and CRediT)
#
# Outputs:
#   title_page_jbi.docx
#   cover_letter_jbi.docx
#   full_manuscript_jbi.docx
set -euo pipefail
cd "$(dirname "$0")"

# -------- 1. Title page & cover letter --------
pandoc title_page_jbi.md  -o title_page_jbi.docx
pandoc cover_letter_jbi.md -o cover_letter_jbi.docx

# -------- 2. Assemble combined markdown --------
# Order: title page (p.1) -> page break -> Abstract -> Introduction ->
# Methods -> Results -> Discussion -> Declarations -> Figure legends.
: > full_manuscript_jbi.md
cat title_page_jbi.md >> full_manuscript_jbi.md
printf '\n\n```{=openxml}\n<w:p><w:r><w:br w:type="page"/></w:r></w:p>\n```\n\n' >> full_manuscript_jbi.md
for f in 00_abstract_v5.md 01_introduction_v5.md 02_methods_v5.md \
         03_results_v5.md 04_discussion_v5.md \
         06_declarations_fig.md 07_figure_legends_v2.md; do
  cat "$f" >> full_manuscript_jbi.md
  printf '\n\n' >> full_manuscript_jbi.md
done

# -------- 3. Rebind (Author, year) -> [@key] via build_pandoc.R --------
Rscript -e '
md_in  <- "full_manuscript_jbi.md"
md_out <- "full_manuscript_jbi_pandoc.md"
file.copy(md_in, "full_manuscript.md", overwrite = TRUE)
source("build_pandoc.R")
if (file.exists("full_manuscript_pandoc.md")) file.rename("full_manuscript_pandoc.md", md_out)
'

# -------- 4. Title override + HTML sub/sup -> pandoc native --------
python3 - <<'PYEOF'
from pathlib import Path
import re
title = ("A reusable cell-composition-adjusted re-analysis pipeline for "
         "interpreting bulk-tissue null results in low-abundance lncRNA "
         "studies: IDI2-AS1 / IL5 as a worked example across type-2 "
         "allergic diseases")
p = Path("full_manuscript_jbi_pandoc.md")
text = p.read_text(encoding="utf-8")
text = re.sub(r'title: "[^"]+"', 'title: "' + title + '"', text, count=1)
text, n_sub = re.subn(r'<sub>([^<]+?)</sub>', lambda m: '~'+m.group(1).replace(' ', r'\ ')+'~', text)
text, n_sup = re.subn(r'<sup>([^<]+?)</sup>', lambda m: '^'+m.group(1).replace(' ', r'\ ')+'^', text)
p.write_text(text, encoding="utf-8")
print(f'Title overridden; <sub>->~x~: {n_sub}, <sup>->^x^: {n_sup}')
PYEOF

# -------- 5. Render with numbered Vancouver citations --------
pandoc full_manuscript_jbi_pandoc.md \
  --citeproc \
  --bibliography=references.bib \
  --csl=elsevier-vancouver.csl \
  -o full_manuscript_jbi.docx

echo "Built:"
for f in title_page_jbi.docx cover_letter_jbi.docx full_manuscript_jbi.docx; do
  echo "  $f ($(wc -c < "$f") bytes)"
done
