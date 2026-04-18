# GSE152004: Asthma, Sajuthi 2020, HiSeq 2000
# Format: raw counts, gene symbols, HR* sample IDs
# Subset: all 695 samples (441 asthmatic + 254 healthy control)
# Group mapping: from Sample_title (HR*) + 2nd Sample_characteristics_ch1 (asthma status)

source("code/R/loaders/common.R")

load_GSE152004 <- function() {
  GSE_ID <- "GSE152004"
  raw_dir <- file.path("data/raw", GSE_ID)
  count_file  <- file.path(raw_dir, "GSE152004_695_raw_counts.txt.gz")
  series_file <- file.path(raw_dir, paste0(GSE_ID, "_series_matrix.txt.gz"))

  counts_full <- load_count_table(count_file)

  # Parse series matrix: !Sample_title gives HR IDs;
  # 2nd !Sample_characteristics_ch1 line gives "asthma status: ..."
  sm <- readLines(series_file)
  parse_line <- function(line) {
    fields <- strsplit(sub("^[^\t]+\t", "", line), "\t")[[1]]
    gsub('^"|"$', "", fields)
  }
  hr_ids <- parse_line(sm[startsWith(sm, "!Sample_title")])
  ch_lines <- sm[startsWith(sm, "!Sample_characteristics_ch1")]
  status_line <- ch_lines[grepl("asthma status", ch_lines)][1]
  asthma_status <- sub("^asthma status: ", "", parse_line(status_line))
  stopifnot(length(hr_ids) == length(asthma_status))

  status_map <- setNames(asthma_status, hr_ids)
  sample_ids <- colnames(counts_full)
  stopifnot(all(sample_ids %in% names(status_map)))

  group <- ifelse(status_map[sample_ids] == "asthmatic", "patient", "control")
  metadata <- data.frame(
    sample_id     = sample_ids,
    asthma_status = status_map[sample_ids],
    group         = group,
    row.names     = sample_ids,
    stringsAsFactors = FALSE
  )

  se <- build_se(counts_full, metadata, GSE_ID)
  detection <- check_idi2as1(se)
  cat(GSE_ID, "samples:", ncol(se),
      " patient/control:", sum(metadata$group=="patient"),
      "/", sum(metadata$group=="control"),
      " IDI2-AS1 detected in", detection$n_detected, "samples\n")

  saveRDS(se, file.path("data/processed", paste0(GSE_ID, "_se.rds")))
  invisible(se)
}

if (sys.nframe() == 0) load_GSE152004()
