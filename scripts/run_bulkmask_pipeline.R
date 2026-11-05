#!/usr/bin/env Rscript
# Run bulkmask steps 2-4 (composition estimates, partial correlations, bootstrap
# decomposition; see bulkmask/README.md) over all configured cohorts.
#   Rscript --vanilla scripts/run_bulkmask_pipeline.R [R_boot]
# R_boot overrides config bootstrap R (use a small value for smoke tests).
#
# Library path: system library (DESeq2/GSVA/EnsDb/...) + renv project library
# (xCell only). --vanilla avoids renv's broken-cache activation.
renv_lib <- "renv/library/macos/R-4.5/aarch64-apple-darwin20"
if (dir.exists(renv_lib)) .libPaths(c(.libPaths(), renv_lib))

suppressPackageStartupMessages({
  library(SummarizedExperiment); library(DESeq2); library(limma)
  library(metafor); library(ppcor); library(mediation)
  library(xCell); library(GSVA); library(GSEABase)
  library(ensembldb); library(EnsDb.Hsapiens.v86)
})
source("bulkmask/load_all.R")

args  <- commandArgs(trailingOnly = TRUE)
cfg   <- read_config("bulkmask/inst/config/idi2as1_il5.yml")
if (length(args) >= 1) cfg$bootstrap$R <- as.integer(args[1])
cat("Bootstrap R =", cfg$bootstrap$R, "\n")

dir.create("results/tables/bulkmask", recursive = TRUE, showWarnings = FALSE)
all_cor <- list(); all_dec <- list(); all_pts <- list()
missing_se <- character(0); failed <- character(0)

for (co in cfg$cohorts) {
  se_path <- file.path("data/processed", paste0(co$id, "_se.rds"))
  if (!file.exists(se_path)) { cat("SKIP (no SE):", co$id, "\n"); missing_se <- c(missing_se, co$id); next }
  cat("\n==", co$id, "(", co$disease, ", id_type=", co$id_type, ") ==\n")
  se  <- readRDS(se_path)
  cfg$.cohort_id <- co$id
  df  <- tryCatch(prepare_cohort(se, cfg, id_type = co$id_type),
                  error = function(e) {
                    cat("  prepare FAILED:", conditionMessage(e), "\n"); failed <<- c(failed, co$id); NULL })
  if (is.null(df)) {
    # GSE246323 ends here by design: IL5 does not pass the count filter
    if (!co$id %in% failed) cat("  SKIP: the exposure or outcome gene is absent after the count filter\n")
    next
  }
  cat("  deconv input normalisation:", attr(df, "deconv_norm"), "| n =", nrow(df), "\n")
  res <- analyse_cohort(df, cfg)
  all_cor[[co$id]] <- res$correlations
  all_dec[[co$id]] <- res$decompositions
  all_pts[[co$id]] <- df[, intersect(c("sample_id","dataset","group","group_bin","exposure","outcome",
                                        paste0("sig_", names(cfg$signatures)),
                                        "eos_xcell_raw","eos_xcell_comp","eos_gsva"), names(df))]
  print(res$correlations, row.names = FALSE)
  if (!is.null(res$decompositions))
    print(res$decompositions[, c("estimator","adjusted","ACME","ACME_p","ADE","ADE_p",
                                 "total_effect","prop_mediated")], row.names = FALSE)
}

# a partial run must not overwrite the tables with fewer cohorts
if (length(missing_se))
  stop("No SE file for ", paste(missing_se, collapse = ", "), " (data/processed/<GSE>_se.rds). ",
       "If the files are missing, run code/R/03_download_all_datasets.R and the loaders in ",
       "code/R/loaders/ first. The tables in results/tables/bulkmask/ were left unchanged.")
if (length(failed))
  stop("prepare_cohort() failed for ", paste(failed, collapse = ", "),
       "; the tables in results/tables/bulkmask/ were left unchanged.")
if (length(all_cor) == 0)
  stop("No cohort has both the exposure and the outcome gene after the count filter; ",
       "the tables in results/tables/bulkmask/ were left unchanged.")

cor_tbl <- do.call(rbind, all_cor); dec_tbl <- do.call(rbind, all_dec)
pts_tbl <- do.call(rbind, all_pts)
write.csv(cor_tbl, "results/tables/bulkmask/correlations.csv", row.names = FALSE)
write.csv(dec_tbl, "results/tables/bulkmask/decompositions.csv", row.names = FALSE)
write.csv(pts_tbl, "results/tables/bulkmask/points.csv", row.names = FALSE)

dir.create("logs", showWarnings = FALSE)
writeLines(capture.output(sessionInfo()), "logs/bulkmask_sessionInfo.txt")
cat("\nDONE. Wrote results/tables/bulkmask/{correlations,decompositions,points}.csv\n")
