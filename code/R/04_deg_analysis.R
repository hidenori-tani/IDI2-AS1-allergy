# ============================================================
# Per-dataset DEG analysis with method dispatch
# ============================================================
# - Raw counts (assays = "counts")  -> DESeq2 + apeglm shrinkage
# - FPKM       (assays = "fpkm")    -> limma-trend on log2(FPKM+1)
# Both branches return a unified data frame:
#   gene, log2FC, lfcSE, pvalue, padj, method
# so downstream meta-analysis can treat all datasets identically.
# ============================================================

suppressPackageStartupMessages({
  library(SummarizedExperiment)
  library(DESeq2)
  library(limma)
  library(apeglm)
  library(dplyr)
  library(tibble)
  library(readr)
})

source("code/R/loaders/common.R")

dir.create("results/intermediate", recursive = TRUE, showWarnings = FALSE)
dir.create("results/tables",       recursive = TRUE, showWarnings = FALSE)
dir.create("logs",                 recursive = TRUE, showWarnings = FALSE)

# Focal genes for the headline tables
FOCAL_LNCRNAS   <- c("IDI2-AS1", "ENSG00000260196",
                     "MIR22HG", "GABPB1-AS1", "OIP5-AS1", "LITATS1")
FOCAL_CYTOKINES <- c("IL5", "IL4", "IL13", "IL6", "TNF", "IFNG",
                     "ENSG00000113525")
FOCAL_GENES     <- c(FOCAL_LNCRNAS, FOCAL_CYTOKINES)

# ---------- DESeq2 branch ----------
run_deg_deseq2 <- function(se) {
  colData(se)$group <- factor(colData(se)$group, levels = c("control", "patient"))
  dds <- DESeqDataSet(se, design = ~ group)
  dds <- dds[rowSums(counts(dds)) >= 10, ]
  dds <- DESeq(dds, quiet = TRUE)
  res <- lfcShrink(dds, coef = "group_patient_vs_control",
                   type = "apeglm", quiet = TRUE)
  as.data.frame(res) %>%
    rownames_to_column("gene") %>%
    transmute(gene,
              log2FC = log2FoldChange,
              lfcSE  = lfcSE,
              pvalue = pvalue,
              padj   = padj,
              method = "DESeq2-apeglm")
}

# ---------- limma-trend branch (FPKM) ----------
run_deg_limma_trend <- function(se) {
  fpkm <- assay(se)
  y    <- log2(fpkm + 1)
  # Drop genes that are essentially silent across all samples
  keep <- rowSums(fpkm > 0.1) >= ceiling(0.1 * ncol(y))
  y    <- y[keep, , drop = FALSE]

  group  <- factor(colData(se)$group, levels = c("control", "patient"))
  design <- model.matrix(~ group)
  fit    <- lmFit(y, design)
  fit    <- eBayes(fit, trend = TRUE)
  # SE for the treatment coefficient = stdev.unscaled[, 2] * sigma
  coef_idx <- "grouppatient"
  se_coef  <- fit$stdev.unscaled[, coef_idx] * fit$sigma
  tt <- topTable(fit, coef = coef_idx, number = Inf, sort.by = "none")

  data.frame(
    gene   = rownames(tt),
    log2FC = tt$logFC,
    lfcSE  = se_coef[rownames(tt)],
    pvalue = tt$P.Value,
    padj   = tt$adj.P.Val,
    method = "limma-trend",
    stringsAsFactors = FALSE
  )
}

# ---------- Dispatcher ----------
run_deg <- function(se) {
  assay_names <- names(assays(se))
  if ("counts" %in% assay_names) {
    cat("  -> DESeq2 branch (raw counts, n_genes=", nrow(se), ")\n", sep = "")
    run_deg_deseq2(se)
  } else if ("fpkm" %in% assay_names) {
    cat("  -> limma-trend branch (FPKM, n_genes=", nrow(se), ")\n", sep = "")
    run_deg_limma_trend(se)
  } else {
    stop("Unknown assay type: ", paste(assay_names, collapse = ","))
  }
}

extract_focal <- function(deg_df, genes = FOCAL_GENES) {
  hits <- deg_df %>% filter(gene %in% genes | strip_ens_version(gene) %in% genes)
  hits %>% arrange(gene)
}

# ---------- Main ----------
datasets <- read_csv("data/metadata/final_datasets.csv", show_col_types = FALSE) %>%
  filter(status == "USE")

cat("Running DEG for", nrow(datasets), "datasets:\n")
print(datasets[, c("disease", "gse_id", "n_patient", "n_control", "analysis_method")])

all_focal <- list()

for (i in seq_len(nrow(datasets))) {
  gse <- datasets$gse_id[i]
  cat("\n========================================\n")
  cat("== [", i, "/", nrow(datasets), "] ", gse,
      " (", datasets$disease[i], ")\n", sep = "")
  cat("========================================\n")

  se <- readRDS(file.path("data/processed", paste0(gse, "_se.rds")))
  deg <- run_deg(se)

  saveRDS(deg, file.path("results/intermediate", paste0(gse, "_deg.rds")))
  write_csv(deg, file.path("results/tables", paste0(gse, "_deg_full.csv.gz")))

  focal <- extract_focal(deg) %>% mutate(dataset = gse, disease = datasets$disease[i])
  write_csv(focal, file.path("results/tables", paste0(gse, "_focal_genes_deg.csv")))
  all_focal[[gse]] <- focal

  cat("  n DEG genes:", nrow(deg),
      " | n focal hits:", nrow(focal), "\n")
  if (nrow(focal)) {
    print(focal %>% select(gene, log2FC, lfcSE, pvalue, padj))
  }
}

# Combined focal gene table across all datasets
combined <- bind_rows(all_focal)
write_csv(combined, "results/tables/ALL_focal_genes_deg.csv")
cat("\nDEG analysis complete for", length(all_focal), "datasets.\n")
cat("Combined focal-gene table:", nrow(combined), "rows\n")
