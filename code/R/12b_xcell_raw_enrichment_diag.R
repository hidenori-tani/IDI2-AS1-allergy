# ============================================================
# 12b — Is the xCell eosinophil floor a biology signal or a
#       spillover-compensation artifact?
#
# Compares raw ssGSEA enrichment (rawEnrichmentAnalysis, BEFORE the
# spillover compensation + transform that xCellAnalysis applies) with
# the final adjusted xCell score, for the Eosinophils signature, in
# every USE cohort. If the RAW enrichment also has near-zero variance
# in epithelial cohorts, the floor reflects genuinely low eosinophil
# content (brushings/skin), not a compensation artifact.
# ============================================================

suppressPackageStartupMessages({
  library(SummarizedExperiment); library(DESeq2); library(xCell)
  library(dplyr); library(readr)
})
source("code/R/loaders/common.R")

ENS_MAP_FILE <- "data/metadata/ensembl_to_symbol.csv"
get_ens2sym <- function(ens_ids) {
  cache <- read_csv(ENS_MAP_FILE, show_col_types = FALSE)
  setNames(cache$symbol, cache$ensembl)
}
build_xcell_input <- function(se, id_type) {
  if ("counts" %in% names(assays(se))) {
    dds <- DESeqDataSet(se, design = ~ group)
    dds <- dds[rowSums(counts(dds)) >= 10, ]
    dds <- estimateSizeFactors(dds)
    expr <- counts(dds, normalized = TRUE)
  } else {
    expr <- assay(se); expr <- expr[rowSums(expr) > 0, , drop = FALSE]
  }
  rn <- rownames(expr)
  if (id_type == "ensembl") {
    m <- get_ens2sym(rn); sym <- m[strip_ens_version(rn)]
    keep <- !is.na(sym); expr <- rowsum(expr[keep, , drop = FALSE], group = sym[keep])
  }
  expr[!duplicated(rownames(expr)), , drop = FALSE]
}

datasets <- read_csv("data/metadata/final_datasets.csv", show_col_types = FALSE) %>%
  filter(status == "USE")

out <- list()
for (i in seq_len(nrow(datasets))) {
  gse <- datasets$gse_id[i]; disease <- datasets$disease[i]; id_type <- datasets$id_type[i]
  se  <- readRDS(file.path("data/processed", paste0(gse, "_se.rds")))
  xin <- build_xcell_input(se, id_type)
  raw <- tryCatch(rawEnrichmentAnalysis(as.matrix(xin),
            signatures   = xCell.data$signatures,
            genes        = xCell.data$genes,
            parallel.sz  = 1),
          error = function(e) { cat(gse, "raw FAILED:", conditionMessage(e), "\n"); NULL })
  if (is.null(raw) || !("Eosinophils" %in% rownames(raw))) next
  eo <- as.numeric(raw["Eosinophils", ])
  out[[gse]] <- data.frame(
    dataset = gse, disease = disease, n = ncol(xin),
    raw_eos_sd = sd(eo), raw_eos_median = median(eo),
    raw_eos_frac_zero = mean(eo == 0), raw_eos_cv = sd(eo)/mean(eo),
    stringsAsFactors = FALSE)
  cat(sprintf("%-11s raw eos: sd=%.4g median=%.4g frac0=%.2f cv=%.3f\n",
              gse, sd(eo), median(eo), mean(eo == 0), sd(eo)/mean(eo)))
}
res <- bind_rows(out)
write_csv(res, "results/tables/Table_xcell_raw_eos_diagnostic.csv")
cat("\nSaved Table_xcell_raw_eos_diagnostic.csv\n")
