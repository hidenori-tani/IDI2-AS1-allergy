# ============================================================
# R environment setup for IDI2-AS1 cross-disease analysis
# ============================================================
# Run from project root:
#   Rscript code/R/setup.R
#
# Expected runtime: 30-60 minutes (Bioconductor packages compile from source on macOS)
# ============================================================

# Detect repo info
options(repos = c(CRAN = "https://cloud.r-project.org"))
options(install.packages.check.source = "no")
options(install.packages.compile.from.source = "never")  # prefer binaries

cat("\n== R version ==\n")
print(R.version.string)
cat("\n== Platform ==\n")
print(R.version$platform)

# --- Step 1: renv ---
cat("\n== Step 1: renv ==\n")
if (!requireNamespace("renv", quietly = TRUE)) {
  install.packages("renv")
}

# Initialize renv inside project (settings only, no library snapshot yet)
renv::init(bare = TRUE, force = TRUE)

# --- Step 2: BiocManager ---
cat("\n== Step 2: BiocManager ==\n")
if (!requireNamespace("BiocManager", quietly = TRUE)) {
  install.packages("BiocManager")
}
BiocManager::install(version = "3.21", ask = FALSE, update = FALSE)

# --- Step 3: Bioconductor packages ---
cat("\n== Step 3: Bioconductor packages ==\n")
bioc_pkgs <- c(
  "DESeq2",          # DEG analysis
  "sva",             # ComBat-seq batch correction
  "GEOquery",        # GEO data download
  "limma",           # additional stats
  "ComplexHeatmap",  # heatmap visualization
  "apeglm",          # log2FC shrinkage for DESeq2
  "SummarizedExperiment"  # data container
)
BiocManager::install(bioc_pkgs, ask = FALSE, update = FALSE)

# --- Step 4: CRAN packages ---
cat("\n== Step 4: CRAN packages ==\n")
cran_pkgs <- c(
  "tidyverse",     # data wrangling
  "metafor",       # meta-analysis (forest plots)
  "ggplot2",       # plotting
  "patchwork",     # plot composition
  "immunedeconv",  # cell type deconvolution wrapper
  "mediation",     # mediation analysis
  "here",          # path management
  "circlize",      # heatmap colors
  "gridExtra"      # grid arrangements
)
install.packages(cran_pkgs)

# --- Step 5: snapshot ---
cat("\n== Step 5: renv snapshot ==\n")
renv::snapshot(prompt = FALSE, type = "all")

# --- Verification ---
cat("\n== Verification ==\n")
all_pkgs <- c(bioc_pkgs, cran_pkgs)
status <- sapply(all_pkgs, function(p) {
  tryCatch({
    suppressPackageStartupMessages(library(p, character.only = TRUE))
    "OK"
  }, error = function(e) paste("FAIL:", conditionMessage(e)))
})
cat("\nPackage load status:\n")
print(data.frame(package = names(status), status = unname(status)))

n_fail <- sum(!grepl("^OK", status))
if (n_fail > 0) {
  cat("\n", n_fail, "package(s) failed to load. Check errors above.\n")
  quit(status = 1)
} else {
  cat("\nAll", length(status), "packages installed and loaded successfully.\n")
}
