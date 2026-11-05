# ============================================================
# Earlier random-effects meta-analysis (superseded; not the manuscript's Figure 2)
# ============================================================
# Pools the apeglm posterior modes with their posterior SDs as standard errors.
# Those SDs are shrunken (0.00144 for 87% of the genes in GSE136825, including
# IDI2-AS1 and IL5), so GSE136825 carries 99.1% of the IDI2-AS1 weight and the
# interval is artificially narrow.
# Its IDI2-AS1 and IL5 rows are the 'earlier version; not used' rows of Table S7;
# code/python/16 and 21 reproduce this table as a positive control. The
# manuscript's pooled estimates and Figure 2 come from
# code/python/21_unshrunken_de_power.py and code/python/23_figure2.py.
# Inputs:
#   results/tables/ALL_focal_genes_deg.csv   (combined focal-gene DEG)
# Outputs:
#   results/figures/forest_apeglm_superseded_<gene>.pdf
#   results/tables/Table_meta_analysis_summary.csv
# ============================================================

suppressPackageStartupMessages({
  library(metafor)
  library(dplyr)
  library(readr)
  library(purrr)
})

dir.create("results/figures", recursive = TRUE, showWarnings = FALSE)
dir.create("results/tables",  recursive = TRUE, showWarnings = FALSE)

source("code/R/loaders/common.R")

all_results <- read_csv("results/tables/ALL_focal_genes_deg.csv",
                         show_col_types = FALSE)

# Collapse Ensembl-ID-named rows into the symbol so each gene has one row per dataset
sym_map <- c(
  "ENSG00000232656" = "IDI2-AS1",
  "ENSG00000113525" = "IL5"
)
all_results <- all_results %>%
  mutate(gene = ifelse(gene %in% names(sym_map), sym_map[gene], gene))

# Per-dataset table for the headline genes
key_genes <- c("IDI2-AS1", "IL5", "IL4", "IL13", "IL6", "IFNG", "TNF",
               "MIR22HG", "OIP5-AS1", "GABPB1-AS1")

run_ma <- function(df) {
  # Drop rows with missing SE / log2FC (e.g. apeglm couldn't shrink)
  df <- df %>% filter(is.finite(log2FC), is.finite(lfcSE), lfcSE > 0)
  if (nrow(df) < 2) return(NULL)
  rma(yi = df$log2FC, sei = df$lfcSE, method = "REML",
      slab = paste(df$dataset, df$disease, sep = " | "))
}

ma_results <- list()
for (g in key_genes) {
  sub <- all_results %>% filter(gene == g)
  res <- run_ma(sub)
  if (!is.null(res)) ma_results[[g]] <- res
}

# Forest plots for the headline genes (IDI2-AS1, IL5)
for (g in c("IDI2-AS1", "IL5")) {
  if (!is.null(ma_results[[g]])) {
    pdf(sprintf("results/figures/forest_apeglm_superseded_%s.pdf",
                gsub("-", "", g)),
        width = 9, height = 5)
    forest(ma_results[[g]],
           xlab = "log2 fold change (patient vs control)",
           main = sprintf("%s: cross-disease random-effects meta-analysis", g))
    dev.off()
    cat("Saved forest plot for", g, "\n")
  }
}

# Summary table for all genes that had >=2 datasets
ma_summary <- tibble(
  gene          = names(ma_results),
  k_datasets    = map_int(ma_results, ~ .x$k),
  pooled_log2FC = map_dbl(ma_results, ~ as.numeric(.x$beta)),
  ci_lower      = map_dbl(ma_results, ~ .x$ci.lb),
  ci_upper      = map_dbl(ma_results, ~ .x$ci.ub),
  pval          = map_dbl(ma_results, ~ .x$pval),
  Q_pval        = map_dbl(ma_results, ~ .x$QEp),
  I2_pct        = map_dbl(ma_results, ~ .x$I2),
  tau2          = map_dbl(ma_results, ~ .x$tau2)
) %>% arrange(pval)

write_csv(ma_summary, "results/tables/Table_meta_analysis_summary.csv")
cat("\n=== Meta-analysis summary ===\n")
print(as.data.frame(ma_summary))
