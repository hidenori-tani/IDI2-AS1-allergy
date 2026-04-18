## Convert "(Author et al., YYYY)" plain-text citations into pandoc-citeproc
## syntax "[@bibkey]", then write a pandoc-ready manuscript file.
##
## Usage:
##   Rscript manuscript/build_pandoc.R
## Then:
##   pandoc full_manuscript_pandoc.md \
##     --citeproc --bibliography=references.bib --csl=frontiers.csl \
##     -o full_manuscript_frontiers.docx

# Run from manuscript/ directory: setwd("manuscript") if needed.
if (!file.exists("full_manuscript.md")) {
  if (file.exists("manuscript/full_manuscript.md")) setwd("manuscript")
}

src <- readLines("full_manuscript.md", warn = FALSE)
text <- paste(src, collapse = "\n")

# bib-key map for every in-text Author-year citation
cite_map <- list(
  "Endo et al., 2025"        = "Endo2025_IDI2AS1",
  "Yagi et al., 2024"        = "Yagi2024_polyIC",
  "Abe et al., 2023"         = "Abe2023_LPS",
  "Tani et al., 2012"        = "Tani2012_GenomeRes",
  "Sajuthi et al., 2020"     = "Sajuthi2020_GSE152004",
  "Tsoi et al., 2019"        = "Tsoi2018_GSE121212",
  "Sherrill et al., 2014"    = "Sherrill2014_GSE58640",
  "Kleuskens et al., 2024"   = "Kleuskens2024_GSE246323",
  "Peng et al., 2019"        = "Peng2019_GSE136825",
  "Love et al., 2014"        = "Love2014_DESeq2",
  "Zhu et al., 2019"         = "Zhu2019_apeglm",
  "Ritchie et al., 2015"     = "Ritchie2015_limma",
  "Viechtbauer, 2010"        = "Viechtbauer2010_metafor",
  "Tingley et al., 2014"     = "Tingley2014_mediation",
  "Kim, 2015"                = "Kim2015_ppcor",
  "Gu et al., 2016"          = "Gu2016_ComplexHeatmap",
  "Newman et al., 2019"      = "Newman2019_CIBERSORTx",
  "Mattick et al., 2023"     = "Mattick2023_lncRNAreview",
  "Statello et al., 2021"    = "Statello2021_lncRNAfunctions",
  "Cabili et al., 2011"      = "Cabili2011_lincRNAs",
  "Bel et al., 2014"         = "Bel2014_mepolizumab",
  "Bachert et al., 2017"     = "Bachert2019_mepoCRSwNP",
  "Hirano et al., 2019"      = "Hirano2019_EoEbiologic",
  "Lambrecht et al., 2019"   = "Lambrecht2019_type2review",
  "Travaglini et al., 2020"  = "Travaglini2020_lungatlas"
)

# Order matters when patterns share prefixes (e.g., "Tsoi et al., 2019" and
# "Travaglini et al., 2020" — both fine here, but always do longest first).
ord <- order(-nchar(names(cite_map)))
cite_map <- cite_map[ord]

# Replace each "(Author et al., YYYY)" with "[@bibkey]"
# Also handle multi-citation parenthetical groups joined by "; "
for (k in names(cite_map)) {
  bk <- cite_map[[k]]
  # parenthetical, single
  text <- gsub(paste0("\\(", k, "\\)"),
               paste0("[@", bk, "]"), text, fixed = FALSE)
  # in-paren middle of multi-cite  e.g.  (Sherrill et al., 2014; Kleuskens et al., 2024)
  text <- gsub(k, paste0("@", bk), text, fixed = TRUE)
}

# Pandoc multi-citation syntax: convert "[@a; @b]"-style groups
# After the substitutions above, "(@a; @b)" needs to become "[@a; @b]".
# Detect runs of "@bibkey" inside a paren group and rewrap.
text <- gsub("\\((@[A-Za-z0-9_]+(?:; @[A-Za-z0-9_]+)*)\\)",
             "[\\1]", text, perl = TRUE)
# Also single "(@key)" -> "[@key]" (catch-all for any leftovers)
text <- gsub("\\((@[A-Za-z0-9_]+)\\)", "[\\1]", text, perl = TRUE)

# inline narrative form e.g. "Endo et al. (2025)" — convert to "@Endo2025_IDI2AS1 [-@... ]" syntax,
# but the manuscript does not use that form, so leave it.

# Add YAML header for pandoc + bibliography metadata
yaml <- c(
  "---",
  "title: \"Tissue-bulk transcriptomes mask the IDI2-AS1 -> IL5 axis through eosinophil-composition mediation: a cross-disease re-analysis in four type-2 allergic diseases\"",
  "author:",
  "  - Hidenori Tani",
  "bibliography: references.bib",
  "csl: frontiers.csl",
  "link-citations: true",
  "---",
  ""
)
out <- c(yaml, text)
writeLines(out, "full_manuscript_pandoc.md")
cat("Wrote full_manuscript_pandoc.md (", length(out), "lines)\n")

# Sanity-check: any plain-text "et al., 20XX" left?
leftover <- regmatches(text,
  gregexpr("[A-Z][a-z]+ et al\\., 20[0-9]{2}", text))[[1]]
if (length(leftover) > 0) {
  cat("WARNING: unconverted plain-text citations remain:\n")
  print(unique(leftover))
} else {
  cat("OK: all plain-text Author-year citations converted to @bibkey form.\n")
}
