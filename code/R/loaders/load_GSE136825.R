# GSE136825: CRSwNP, Wang 2019, HiSeq 4000
# Format: featureCounts (Geneid + Chr/Start/End/Strand/Length + RHP*.bam), ENSG IDs
# Subset: Nasal Polyp Tissue (patient) vs Control Inferior Turbinate (true healthy control)
#         42 + 28 = 70 (excludes 33 within-patient NP_IT samples)
# Mapping RHP*.bam -> GSM/tissue comes from the series matrix.

source("code/R/loaders/common.R")

load_GSE136825 <- function() {
  GSE_ID <- "GSE136825"
  raw_dir <- file.path("data/raw", GSE_ID)
  count_file   <- file.path(raw_dir, "GSE136825_genecounts_20190903.txt.gz")
  series_file  <- file.path(raw_dir, paste0(GSE_ID, "_series_matrix.txt.gz"))

  counts_full <- load_count_table(count_file)
  rownames(counts_full) <- strip_ens_version(rownames(counts_full))

  # Build RHP -> tissue map from the series matrix.
  # Lines !Sample_description (RHP IDs) and !Sample_source_name_ch1 (tissue)
  # are parallel; both have one entry per sample.
  sm <- readLines(series_file)
  parse_line <- function(prefix) {
    line <- sm[startsWith(sm, prefix)]
    stopifnot(length(line) == 1)
    fields <- strsplit(sub(paste0("^", prefix, "\t"), "", line), "\t")[[1]]
    gsub('^"|"$', "", fields)
  }
  rhp_ids <- parse_line("!Sample_description")
  tissue  <- parse_line("!Sample_source_name_ch1")
  stopifnot(length(rhp_ids) == length(tissue))

  tissue_map <- setNames(tissue, rhp_ids)

  # Strip .bam from count column names (already done in load_count_table)
  sample_ids <- colnames(counts_full)
  stopifnot(all(sample_ids %in% names(tissue_map)))
  sample_tissue <- tissue_map[sample_ids]

  keep <- sample_tissue %in% c("Nasal Polyp Tissue", "Control Inferior Turbinate")
  counts <- counts_full[, keep, drop = FALSE]
  group <- ifelse(sample_tissue[keep] == "Nasal Polyp Tissue", "patient", "control")

  metadata <- data.frame(
    sample_id = colnames(counts),
    tissue    = sample_tissue[keep],
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

if (sys.nframe() == 0) load_GSE136825()
