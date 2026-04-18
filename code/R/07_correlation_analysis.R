# ============================================================
# Sample-level IDI2-AS1 vs IL5 correlation per dataset
# ============================================================
# - Raw counts (assays = "counts")  -> vst() expression
# - FPKM       (assays = "fpkm")    -> log2(FPKM+1)
# Resolves both gene-symbol and Ensembl rownames.
# Output:
#   results/figures/Fig3_correlation_scatter.pdf
#   results/tables/Table_correlation.csv
# ============================================================

suppressPackageStartupMessages({
  library(SummarizedExperiment)
  library(DESeq2)
  library(dplyr)
  library(readr)
  library(ggplot2)
})

source("code/R/loaders/common.R")

dir.create("results/figures",      recursive = TRUE, showWarnings = FALSE)
dir.create("results/tables",       recursive = TRUE, showWarnings = FALSE)
dir.create("results/intermediate", recursive = TRUE, showWarnings = FALSE)

datasets <- read_csv("data/metadata/final_datasets.csv", show_col_types = FALSE) %>%
  filter(status == "USE")

# Resolve a gene by symbol or Ensembl ID against rownames
resolve_gene <- function(rn, ids) {
  rn_stripped <- strip_ens_version(rn)
  hit <- which(rn %in% ids | rn_stripped %in% ids)
  if (length(hit) == 0) return(NA_integer_)
  hit[1]
}

build_expr <- function(se) {
  if ("counts" %in% names(assays(se))) {
    dds <- DESeqDataSet(se, design = ~ group)
    dds <- dds[rowSums(counts(dds)) >= 10, ]
    vsd <- vst(dds, blind = TRUE)
    assay(vsd)
  } else if ("fpkm" %in% names(assays(se))) {
    log2(assay(se) + 1)
  } else {
    stop("Unknown assay type")
  }
}

per_dataset <- list()

for (i in seq_len(nrow(datasets))) {
  gse     <- datasets$gse_id[i]
  disease <- datasets$disease[i]
  cat("== ", gse, " (", disease, ")\n", sep = "")

  se   <- readRDS(file.path("data/processed", paste0(gse, "_se.rds")))
  expr <- build_expr(se)

  i_idi <- resolve_gene(rownames(expr), IDI2AS1_IDS)
  i_il5 <- resolve_gene(rownames(expr), IL5_IDS)
  if (is.na(i_idi) || is.na(i_il5)) {
    cat("  SKIP - gene not found (IDI2-AS1:", !is.na(i_idi),
        "IL5:", !is.na(i_il5), ")\n")
    next
  }

  idi <- as.numeric(expr[i_idi, ])
  il5 <- as.numeric(expr[i_il5, ])
  ct  <- suppressWarnings(cor.test(idi, il5, method = "spearman"))

  per_dataset[[gse]] <- list(
    summary = data.frame(
      dataset = gse, disease = disease,
      n = ncol(expr),
      spearman_rho = unname(ct$estimate),
      pval = ct$p.value,
      data_type = ifelse("counts" %in% names(assays(se)), "vst", "log2(FPKM+1)"),
      stringsAsFactors = FALSE
    ),
    points = data.frame(
      sample_id = colnames(expr),
      group     = colData(se)$group,
      idi2as1   = idi,
      il5       = il5,
      dataset   = gse,
      disease   = disease,
      stringsAsFactors = FALSE
    )
  )
  cat("  rho =", round(ct$estimate, 3), " p =", signif(ct$p.value, 3), "\n")
}

corr_summary <- bind_rows(lapply(per_dataset, `[[`, "summary"))
all_points   <- bind_rows(lapply(per_dataset, `[[`, "points"))

write_csv(corr_summary, "results/tables/Table_correlation.csv")
write_csv(all_points,   "results/intermediate/correlation_data.csv")

cat("\n=== Correlation summary ===\n")
print(as.data.frame(corr_summary))

# Faceted scatter plot — one panel per disease/dataset
p <- ggplot(all_points, aes(idi2as1, il5, color = group)) +
  geom_point(alpha = 0.55, size = 1.4) +
  geom_smooth(method = "lm", se = TRUE, color = "black", linewidth = 0.6) +
  facet_wrap(~ paste(disease, dataset, sep = "\n"),
             scales = "free", ncol = 3) +
  scale_color_manual(values = c(control = "#377eb8", patient = "#e41a1c")) +
  labs(x = "IDI2-AS1 expression",
       y = "IL5 expression",
       title = "IDI2-AS1 vs IL5 across allergic diseases",
       subtitle = "vst (raw-count datasets) or log2(FPKM+1) for GSE58640") +
  theme_bw(base_size = 11) +
  theme(strip.text = element_text(size = 9),
        legend.position = "bottom")

ggsave("results/figures/Fig3_correlation_scatter.pdf",
       p, width = 11, height = 7)

cat("\nSaved Fig3_correlation_scatter.pdf\n")
