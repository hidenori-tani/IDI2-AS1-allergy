#!/usr/bin/env Rscript
# Re-run the bulkmask pipeline for the Ensembl-keyed cohorts only and splice the
# result into the shipped tables in results/tables/bulkmask/.
#
#   Rscript --vanilla scripts/rerun_bulkmask_cohorts.R            # compare only
#   Rscript --vanilla scripts/rerun_bulkmask_cohorts.R --write    # compare, then write
#
# Why (2026-11-05): the config listed Ensembl aliases for the seven eosinophil
# markers only, so in the Ensembl-keyed cohort GSE136825 the th2 and neutrophil
# signatures resolved no genes and were NA (the 2026-08-31 `conditioners_used`
# column made that visible; it did not fix it). The aliases are now complete.
# That change can move only sig_th2 / sig_neutrophil of Ensembl-keyed cohorts and
# the two correlation models that condition on them. The script therefore refuses
# to write unless everything else is reproduced: the other columns of the rerun
# cohort, its decompositions, its other correlation models, and (because the
# aliases cannot reach symbol-keyed matrices without Ensembl rownames) the absence
# of alias IDs in every symbol-keyed cohort. Rows of other cohorts are copied
# byte for byte.
renv_lib <- "renv/library/macos/R-4.5/aarch64-apple-darwin20"
if (dir.exists(renv_lib)) .libPaths(c(.libPaths(), renv_lib))
have_xcell <- requireNamespace("xCell", quietly = TRUE)
suppressPackageStartupMessages({
  library(SummarizedExperiment); library(DESeq2); library(limma)
  library(metafor); library(ppcor); library(mediation)
  if (have_xcell) library(xCell)
  library(GSVA); library(GSEABase)
  library(ensembldb); library(EnsDb.Hsapiens.v86)
})
source("bulkmask/load_all.R")

write_out <- "--write" %in% commandArgs(trailingOnly = TRUE)
cfg  <- read_config("bulkmask/inst/config/idi2as1_il5.yml")
D    <- "results/tables/bulkmask"
CHANGED_COLS   <- c("sig_th2", "sig_neutrophil")
CHANGED_MODELS <- c("adj_marker+th2", "adj_neutrophil(neg.ctrl)")
TOL  <- 1e-10
fail <- character(0)
same <- function(a, b) all(abs(a - b) <= TOL * pmax(1, abs(b)) | (is.na(a) & is.na(b)))

pts_old  <- read.csv(file.path(D, "points.csv"), stringsAsFactors = FALSE)
cor_old  <- read.csv(file.path(D, "correlations.csv"), stringsAsFactors = FALSE)
dec_old  <- read.csv(file.path(D, "decompositions.csv"), stringsAsFactors = FALSE)
pts_lines <- readLines(file.path(D, "points.csv"))
cor_lines <- readLines(file.path(D, "correlations.csv"))
# keep each file's line terminator (correlations.csv was last written by Python's csv: CRLF)
eol_of  <- function(f) if (any(readBin(f, "raw", 65536) == as.raw(13))) "\r\n" else "\n"
pts_eol <- eol_of(file.path(D, "points.csv"))
cor_eol <- eol_of(file.path(D, "correlations.csv"))

# points.csv carries no dataset column: its rows follow the order of the analysable
# cohorts in the config (the rbind order of scripts/run_bulkmask_pipeline.R).
analysable <- unique(cor_old$dataset)
sizes <- vapply(analysable, function(id) cor_old$n[cor_old$dataset == id & cor_old$model == "raw"], numeric(1))
stopifnot(sum(sizes) == nrow(pts_old))
row_of <- split(seq_len(nrow(pts_old)), rep(analysable, sizes))

# xCell is optional here: its input (TPM mapped to symbols through ens2sym_file)
# does not depend on ensembl_aliases, so the shipped xCell columns are what a full
# rerun would produce. Without xCell they are reused and are NOT counted as a
# reproduction check (the decompositions that use them still are).
.current <- NA_character_
if (!have_xcell) {
  cat("NOTE: xCell is not installed; eos_xcell_raw / eos_xcell_comp of the rerun cohort are",
      "taken from the shipped points.csv and are not part of the reproduction check.\n")
  estimate_xcell <- function(expr, cell_type, raw = TRUE) {
    # a cohort that was not analysable must still stop before deconvolution
    if (!(.current %in% analysable)) stop("xCell needed for ", .current, ", which was not analysable before")
    old <- pts_old[row_of[[.current]], ]
    stats::setNames(old[[if (raw) "eos_xcell_raw" else "eos_xcell_comp"]], old$sample_id)
  }
}
REUSED <- if (have_xcell) character(0) else c("eos_xcell_raw", "eos_xcell_comp")

alias_ids <- unlist(cfg$ensembl_aliases)
for (co in cfg$cohorts) {
  se_path <- file.path("data/processed", paste0(co$id, "_se.rds"))
  rerun   <- co$id_type == "ensembl" && co$id %in% analysable
  if (!file.exists(se_path)) {
    if (rerun) { fail <- c(fail, sprintf("%s: %s missing (rebuild with code/R/loaders/load_%s.R)", co$id, se_path, co$id)); next }
    cat("NOTE:", co$id, "has no SE here;",
        if (co$id_type == "symbol") "its rownames are NOT checked by this run.\n"
        else "it was not analysable (exposure/outcome unresolved), which the aliases cannot change.\n")
    next
  }
  se <- readRDS(se_path)
  if (co$id_type == "symbol") {
    hit <- intersect(alias_ids, strip_ens_version(rownames(se)))
    if (length(hit)) fail <- c(fail, sprintf("%s is symbol-keyed but has Ensembl rownames %s: rerun it too",
                                             co$id, paste(hit, collapse = ",")))
    next
  }
  cat("\n==", co$id, "(ensembl) ==\n")
  cfg$.cohort_id <- co$id
  .current <- co$id
  df <- prepare_cohort(se, cfg, id_type = co$id_type)
  if (is.null(df)) {
    if (co$id %in% analysable) fail <- c(fail, paste(co$id, "is no longer analysable"))
    cat("  not analysable (exposure or outcome not resolved), as before\n")
    next
  }
  res <- analyse_cohort(df, cfg)
  old <- pts_old[row_of[[co$id]], ]
  if (!identical(old$sample_id, df$sample_id)) fail <- c(fail, paste(co$id, "sample order differs"))
  for (cc in setdiff(names(old), c("sample_id", "group", "dataset", CHANGED_COLS, REUSED))) {
    if (!same(df[[cc]], old[[cc]])) fail <- c(fail, paste(co$id, "column", cc, "changed"))
    else cat("  reproduced:", cc, "\n")
  }
  if (!identical(df$group, old$group)) fail <- c(fail, paste(co$id, "group labels changed"))
  dold <- dec_old[dec_old$dataset == co$id, ]
  dnew <- res$decompositions
  for (cc in setdiff(names(dold), "dataset")) {
    ok <- if (is.numeric(dold[[cc]])) same(dnew[[cc]], dold[[cc]]) else identical(as.character(dnew[[cc]]), dold[[cc]])
    if (!ok) fail <- c(fail, paste(co$id, "decomposition column", cc, "changed"))
  }
  cnew <- res$correlations
  cold <- cor_old[cor_old$dataset == co$id, ]
  if (!identical(cnew$model, cold$model)) fail <- c(fail, paste(co$id, "model list differs"))
  keep <- !(cold$model %in% CHANGED_MODELS)
  if (!same(cnew$rho[keep], cold$rho[keep]) || !same(cnew$p[keep], cold$p[keep]) ||
      !identical(as.character(cnew$conditioners_used[keep]), cold$conditioners_used[keep]))
    fail <- c(fail, paste(co$id, "an unaffected correlation model changed"))
  for (cc in CHANGED_COLS) cat(sprintf("  %s: %d of %d samples non-NA (was %d)\n", cc,
                                      sum(!is.na(df[[cc]])), nrow(df), sum(!is.na(old[[cc]]))))
  print(data.frame(model = cnew$model, rho_old = cold$rho, rho_new = cnew$rho,
                   used_old = cold$conditioners_used, used_new = cnew$conditioners_used), row.names = FALSE)

  # splice: same formatting as the pipeline (write.csv), other cohorts byte for byte
  tmp <- tempfile(fileext = ".csv")
  write.csv(df[, names(pts_old)], tmp, row.names = FALSE)
  new_pts <- readLines(tmp)
  if (!identical(new_pts[1], pts_lines[1])) fail <- c(fail, "points.csv header differs")
  pts_lines[row_of[[co$id]] + 1L] <- new_pts[-1]
  cnew$dataset <- co$id
  write.csv(cnew[, names(cor_old)], tmp, row.names = FALSE)
  new_cor <- readLines(tmp)
  if (!identical(new_cor[1], cor_lines[1])) fail <- c(fail, "correlations.csv header differs")
  cor_lines[which(cor_old$dataset == co$id) + 1L] <- new_cor[-1]
}

if (length(fail)) { cat("\nFAIL\n", paste(" -", fail, collapse = "\n"), "\n"); quit(status = 1) }
cat("\nAll values that the alias change cannot reach are reproduced (tolerance", TOL, ").\n")
if (write_out) {
  stamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  for (f in c("points.csv", "correlations.csv"))
    file.copy(file.path(D, f), file.path(D, paste0(f, ".bak_", stamp)))
  writeLines(pts_lines, file.path(D, "points.csv"), sep = pts_eol)
  writeLines(cor_lines, file.path(D, "correlations.csv"), sep = cor_eol)
  cat("Wrote points.csv and correlations.csv (backups .bak_", stamp, "); decompositions.csv unchanged.\n", sep = "")
} else cat("Compare only; rerun with --write to splice.\n")
