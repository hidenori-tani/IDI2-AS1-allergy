# ============================================================
# Download all 8 GEO datasets (series matrix + supplementary files)
# ============================================================
# Skips datasets where the GSE directory already has files.
# Logs to logs/download.log via tee in the calling shell.
# ============================================================

suppressPackageStartupMessages({
  library(GEOquery)
  library(readr)
})

datasets <- read_csv("data/metadata/final_datasets.csv", show_col_types = FALSE)
RAW_DIR  <- "data/raw"
LOG_DIR  <- "logs"
dir.create(RAW_DIR, recursive = TRUE, showWarnings = FALSE)
dir.create(LOG_DIR, recursive = TRUE, showWarnings = FALSE)

results <- list()

for (i in seq_len(nrow(datasets))) {
  gse_id <- datasets$gse_id[i]
  cat("\n========================================\n")
  cat("== [", i, "/", nrow(datasets), "] ", gse_id, " ==\n", sep = "")
  cat("========================================\n")

  gse_dir <- file.path(RAW_DIR, gse_id)
  already_present <- dir.exists(gse_dir) && length(list.files(gse_dir)) > 0

  if (already_present) {
    cat("Already downloaded; skipping. Files:\n")
    print(list.files(gse_dir))
    results[[gse_id]] <- list(status = "skipped", files = list.files(gse_dir))
    next
  }

  status <- "OK"
  files  <- character(0)

  # Series matrix (sample metadata)
  ok_series <- tryCatch({
    gse <- getGEO(gse_id, GSEMatrix = TRUE, getGPL = FALSE, destdir = gse_dir)
    saveRDS(gse, file.path(gse_dir, paste0(gse_id, "_seriesMatrix.rds")))
    cat("  series matrix OK\n")
    TRUE
  }, error = function(e) {
    cat("  ERROR series:", conditionMessage(e), "\n")
    FALSE
  })

  # Supplementary files (count matrices)
  ok_supp <- tryCatch({
    sup <- getGEOSuppFiles(gse_id, baseDir = RAW_DIR, makeDirectory = TRUE,
                            fetch_files = TRUE)
    files <<- rownames(sup)
    cat("  supplementary OK (", length(files), "files )\n")
    TRUE
  }, error = function(e) {
    cat("  ERROR supplementary:", conditionMessage(e), "\n")
    FALSE
  })

  if (!ok_series || !ok_supp) status <- "PARTIAL"
  results[[gse_id]] <- list(status = status, files = files)
}

# --- Summary ---
cat("\n\n========================================\n")
cat("== Download summary\n")
cat("========================================\n")
for (gse_id in names(results)) {
  r <- results[[gse_id]]
  cat(sprintf("  %-12s  %-8s  %d files\n",
              gse_id, r$status, length(r$files)))
}
