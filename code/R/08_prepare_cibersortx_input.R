# ============================================================
# Prepare CIBERSORTx input matrices (one TSV per dataset)
# ============================================================
# CIBERSORTx (Stanford, web service: https://cibersortx.stanford.edu/)
# expects:
#   - Tab-separated, first column = "GeneSymbol", remaining columns = samples
#   - Linear, non-log values (CPM/TPM scale recommended)
#
# This script prepares the input but does NOT call the web API. Its output
# (results/intermediate/cibersortx_input/) is not in the repository, and
# CIBERSORTx was not used in the manuscript, whose composition estimates
# (marker score, ssGSEA, xCell) come from the bulkmask package
# (scripts/run_bulkmask_pipeline.R). For the Ensembl-keyed series the
# first column holds Ensembl IDs, not symbols.
# ============================================================

suppressPackageStartupMessages({
  library(SummarizedExperiment)
  library(dplyr)
  library(readr)
})

dir.create("results/intermediate/cibersortx_input",
           recursive = TRUE, showWarnings = FALSE)

datasets <- read_csv("data/metadata/final_datasets.csv", show_col_types = FALSE) %>%
  filter(status == "USE")

for (i in seq_len(nrow(datasets))) {
  gse <- datasets$gse_id[i]
  se  <- readRDS(file.path("data/processed", paste0(gse, "_se.rds")))

  if ("counts" %in% names(assays(se))) {
    counts <- assay(se)
    cpm    <- t(t(counts) / colSums(counts)) * 1e6
    mat    <- cpm
    note   <- "CPM"
  } else {
    mat  <- assay(se)  # already FPKM
    note <- "FPKM"
  }

  out <- data.frame(GeneSymbol = rownames(mat),
                    mat,
                    check.names = FALSE,
                    stringsAsFactors = FALSE)
  out_path <- file.path("results/intermediate/cibersortx_input",
                        paste0(gse, "_for_cibersortx.tsv"))
  write.table(out, out_path, sep = "\t", quote = FALSE, row.names = FALSE)
  cat(sprintf("  %s: %d genes x %d samples (%s) -> %s\n",
              gse, nrow(mat), ncol(mat), note, basename(out_path)))
}

cat("\nUpload to https://cibersortx.stanford.edu/ with signature LM22, ",
    "100 permutations, no batch correction.\n", sep = "")
