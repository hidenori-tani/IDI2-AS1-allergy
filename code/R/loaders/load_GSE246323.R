# GSE246323: EoE, Kleuskens 2024, NovaSeq 6000
# Format: raw counts, ENSG IDs, 20 samples (15 patient timepoints + 5 controls)
# Subset: P*_bsl1 (5 patient baselines) + C02-C06 (5 controls) = n=5+5

source("code/R/loaders/common.R")

load_GSE246323 <- function() {
  GSE_ID <- "GSE246323"
  raw_dir <- file.path("data/raw", GSE_ID)
  count_file <- file.path(raw_dir, "GSE246323_Kleuskens_RNAseq_readcounts.txt.gz")

  counts_full <- load_count_table(count_file)
  rownames(counts_full) <- strip_ens_version(rownames(counts_full))

  # Keep only baseline patient samples + controls
  keep <- grepl("_bsl1_count$|^C[0-9]+_count$", colnames(counts_full))
  counts <- counts_full[, keep, drop = FALSE]

  group <- ifelse(grepl("^C[0-9]+_count$", colnames(counts)), "control", "patient")
  metadata <- data.frame(
    sample_id = colnames(counts),
    group     = group,
    row.names = colnames(counts),
    stringsAsFactors = FALSE
  )

  se <- build_se(counts, metadata, GSE_ID)
  detection <- check_idi2as1(se)
  cat(GSE_ID, "samples:", ncol(se),
      " patient/control:", sum(metadata$group=="patient"),
      "/", sum(metadata$group=="control"),
      " IDI2-AS1 detected in", detection$n_detected, "samples\n")

  saveRDS(se, file.path("data/processed", paste0(GSE_ID, "_se.rds")))
  invisible(se)
}

if (sys.nframe() == 0) load_GSE246323()
