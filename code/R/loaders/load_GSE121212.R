# GSE121212: AD, Tsoi 2018, HiSeq 2500
# Format: raw counts, gene symbols (Excel-date dups handled), ENS-free
# Subset: AD lesional (incl. chronic_lesion) + CTRL = 27 + 38

source("code/R/loaders/common.R")

load_GSE121212 <- function() {
  GSE_ID <- "GSE121212"
  raw_dir <- file.path("data/raw", GSE_ID)
  count_file <- file.path(raw_dir, "GSE121212_readcount.txt.gz")

  counts_full <- load_count_table(count_file)

  # Keep AD lesional (and chronic_lesion) + CTRL; drop AD non-lesional and PSO
  keep <- grepl("^AD_[0-9]+_lesional$|^AD_[0-9]+_chronic_lesion$|^CTRL_", colnames(counts_full))
  counts <- counts_full[, keep, drop = FALSE]

  group <- ifelse(grepl("^CTRL_", colnames(counts)), "control", "patient")
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

if (sys.nframe() == 0) load_GSE121212()
