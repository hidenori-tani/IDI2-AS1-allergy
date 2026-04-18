# ============================================================
# Common loader utilities for all GEO datasets
# ============================================================
# Each per-dataset loader source()s this file and returns a
# SummarizedExperiment with assay 'counts' and colData$group in
# {"patient", "control"}.
# ============================================================

suppressPackageStartupMessages({
  library(SummarizedExperiment)
  library(readr)
})

# Canonical IDs for the focal genes
IDI2AS1_IDS <- c("IDI2-AS1", "ENSG00000260196", "NR_024628")
IL5_IDS     <- c("IL5", "ENSG00000113525")

#' Load a count matrix that may be either a gene-symbol table or a
#' featureCounts output. Handles missing first-column header,
#' Excel-date duplicate symbols, and metadata columns.
load_count_table <- function(path) {
  # Some GEO headers omit the leading delimiter for the gene-name column,
  # so the header has N fields and data rows have N+1. Detect this and
  # re-read with col_names=FALSE + explicit names so we don't silently
  # lose a sample column.
  con <- gzfile(path, "rt"); on.exit(close(con), add = TRUE)
  hdr  <- strsplit(readLines(con, n = 1), "\t", fixed = TRUE)[[1]]
  row1 <- strsplit(readLines(con, n = 1), "\t", fixed = TRUE)[[1]]
  if (length(row1) == length(hdr) + 1) {
    raw <- readr::read_tsv(path, show_col_types = FALSE, guess_max = 5000,
                            skip = 1, col_names = c("gene_id", hdr))
  } else {
    raw <- readr::read_tsv(path, show_col_types = FALSE, guess_max = 5000)
  }
  gene_col <- colnames(raw)[1]
  meta <- intersect(colnames(raw), c("Chr","Start","End","Strand","Length"))
  if (length(meta) >= 3) raw <- raw[, !(colnames(raw) %in% meta), drop = FALSE]
  colnames(raw) <- sub("\\.bam$", "", colnames(raw))
  genes <- raw[[gene_col]]
  val_cols <- setdiff(colnames(raw), gene_col)
  mat <- suppressWarnings(as.matrix(sapply(raw[, val_cols, drop = FALSE], as.numeric)))
  rownames(mat) <- NULL
  agg <- rowsum(mat, group = genes, reorder = FALSE, na.rm = TRUE)
  storage.mode(agg) <- "integer"
  agg
}

#' Strip Ensembl version suffix so ENSG00000260196.1 -> ENSG00000260196
strip_ens_version <- function(ids) sub("\\.[0-9]+$", "", ids)

#' Build a SummarizedExperiment with required group column
build_se <- function(counts, metadata, gse_id) {
  stopifnot("group" %in% colnames(metadata))
  stopifnot(all(unique(metadata$group) %in% c("patient", "control")))
  stopifnot(nrow(metadata) == ncol(counts))
  SummarizedExperiment(
    assays   = list(counts = as.matrix(counts)),
    colData  = DataFrame(metadata),
    metadata = list(gse_id = gse_id,
                    n_genes = nrow(counts),
                    n_samples = ncol(counts))
  )
}

#' Verify IDI2-AS1 is detectable in the SummarizedExperiment.
check_idi2as1 <- function(se, min_count = 10, min_samples = 5) {
  rn <- rownames(se)
  rn_stripped <- strip_ens_version(rn)
  found <- rn[rn %in% IDI2AS1_IDS | rn_stripped %in% IDI2AS1_IDS]
  if (length(found) == 0) {
    return(list(id_used = NA_character_, n_detected = 0L, pass = FALSE))
  }
  counts <- assay(se)[found[1], ]
  n_det <- sum(counts >= min_count)
  list(id_used = found[1], n_detected = n_det, pass = n_det >= min_samples)
}
