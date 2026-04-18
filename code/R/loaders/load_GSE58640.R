# GSE58640: EoE, Sherrill 2014, HiSeq 2000
# Format: FPKM (NOT raw counts), gene symbols, numeric sample IDs (168, 461, ...)
# Subset: 10 active EoE + 6 healthy control = 16 total
# Group mapping from Sample_title + Sample_characteristics_ch1 ("patient cohort: ...")
#
# IMPORTANT: This dataset is FPKM, not counts. Downstream analysis must
# branch on metadata$data_type == "fpkm" and use limma-trend on
# log2(FPKM + 1) instead of DESeq2.

suppressPackageStartupMessages({
  library(SummarizedExperiment)
  library(readr)
})
source("code/R/loaders/common.R")

load_GSE58640 <- function() {
  GSE_ID <- "GSE58640"
  raw_dir <- file.path("data/raw", GSE_ID)
  fpkm_file   <- file.path(raw_dir, "GSE58640_RNAseq_processed_GEOsubmission.txt.gz")
  series_file <- file.path(raw_dir, paste0(GSE_ID, "_series_matrix.txt.gz"))

  raw <- readr::read_tsv(fpkm_file, show_col_types = FALSE, guess_max = 5000)
  # Drop the 'locus' column; keep gene_id + sample columns
  stopifnot(all(c("gene_id", "locus") %in% colnames(raw)))
  raw <- raw[, !(colnames(raw) %in% "locus"), drop = FALSE]
  genes <- raw[["gene_id"]]
  val_cols <- setdiff(colnames(raw), "gene_id")
  fpkm <- as.matrix(sapply(raw[, val_cols, drop = FALSE], as.numeric))
  # Aggregate any duplicate gene symbols by mean (FPKM is a rate, not a count)
  rownames(fpkm) <- NULL
  fpkm_mean <- rowsum(fpkm, group = genes, reorder = FALSE, na.rm = TRUE) /
               as.numeric(table(factor(genes, levels = unique(genes))))
  storage.mode(fpkm_mean) <- "double"

  # Series matrix mapping: Sample_title -> patient cohort
  sm <- readLines(series_file)
  parse_line <- function(prefix) {
    line <- sm[startsWith(sm, prefix)]
    stopifnot(length(line) == 1)
    fields <- strsplit(sub(paste0("^", prefix, "\t"), "", line), "\t")[[1]]
    gsub('^"|"$', "", fields)
  }
  titles  <- parse_line("!Sample_title")
  cohort  <- sub("^patient cohort: ", "",
                  parse_line("!Sample_characteristics_ch1"))
  stopifnot(length(titles) == length(cohort))

  cohort_map <- setNames(cohort, titles)
  sample_ids <- colnames(fpkm_mean)
  stopifnot(all(sample_ids %in% names(cohort_map)))

  group <- ifelse(cohort_map[sample_ids] == "active EoE", "patient", "control")
  metadata <- data.frame(
    sample_id = sample_ids,
    cohort    = cohort_map[sample_ids],
    group     = group,
    row.names = sample_ids,
    stringsAsFactors = FALSE
  )

  stopifnot("group" %in% colnames(metadata))
  stopifnot(all(unique(metadata$group) %in% c("patient", "control")))
  stopifnot(nrow(metadata) == ncol(fpkm_mean))
  se <- SummarizedExperiment(
    assays   = list(fpkm = fpkm_mean),
    colData  = DataFrame(metadata),
    metadata = list(gse_id = GSE_ID,
                    n_genes = nrow(fpkm_mean),
                    n_samples = ncol(fpkm_mean),
                    data_type = "fpkm",
                    analysis_method = "limma-trend")
  )

  # IDI2-AS1 detection on FPKM uses a different threshold than counts.
  # Treat "detected" as FPKM > 0.1 in >= 5 samples.
  rn <- rownames(se)
  found <- rn[rn %in% IDI2AS1_IDS]
  n_det <- if (length(found)) sum(assay(se)[found[1], ] > 0.1) else 0L
  cat(GSE_ID, "samples:", ncol(se),
      " patient/control:", sum(metadata$group=="patient"),
      "/", sum(metadata$group=="control"),
      " IDI2-AS1 (FPKM>0.1) detected in", n_det, "samples\n")

  saveRDS(se, file.path("data/processed", paste0(GSE_ID, "_se.rds")))
  invisible(se)
}

if (sys.nframe() == 0) load_GSE58640()
