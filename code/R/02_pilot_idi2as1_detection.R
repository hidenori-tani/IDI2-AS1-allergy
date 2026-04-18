# ============================================================
# Pilot: Confirm IDI2-AS1 is detected in selected GEO dataset
# ============================================================
# Target: GSE121212 (Tsoi et al. 2018, atopic dermatitis, n=27 AD + 38 HC)
# Reason: Supplementary file 'readcount.txt.gz' has explicit raw counts.
#
# Go criterion: IDI2-AS1 readcount >= 10 in >= 5 samples
# ============================================================

suppressPackageStartupMessages({
  library(GEOquery)
  library(tidyverse)
})

args <- commandArgs(trailingOnly = TRUE)
GSE_ID  <- if (length(args) >= 1) args[1] else "GSE121212"
RAW_DIR <- "data/raw"
OUT_DIR <- "results/intermediate"
dir.create(RAW_DIR, recursive = TRUE, showWarnings = FALSE)
dir.create(OUT_DIR, recursive = TRUE, showWarnings = FALSE)

# --- 1. Series matrix (sample metadata) ---
cat("\n== Step 1: Fetching GSE", GSE_ID, "metadata ==\n")
gse <- getGEO(GSE_ID, GSEMatrix = TRUE, getGPL = FALSE)
pheno <- pData(gse[[1]])
cat("Sample count:", nrow(pheno), "\n")
cat("Available phenotype columns (first 12):\n")
print(head(colnames(pheno), 12))

# --- 2. Supplementary count file ---
cat("\n== Step 2: Downloading supplementary files ==\n")
sup_files <- getGEOSuppFiles(GSE_ID, baseDir = RAW_DIR, fetch_files = TRUE)
cat("Downloaded:\n"); print(rownames(sup_files))

# Find the readcount file
sup_paths <- rownames(sup_files)
count_file <- sup_paths[grepl("readcount|count", sup_paths, ignore.case = TRUE)][1]
if (is.na(count_file)) stop("No readcount file found in supplementary files.")
cat("Using count file:", count_file, "\n")

# --- 3. Load count matrix ---
cat("\n== Step 3: Loading count matrix ==\n")
# Robust loader handling: (a) gene-symbol matrix with Excel-date duplicates,
# (b) featureCounts output (Geneid + Chr/Start/End/Strand/Length metadata).
raw <- readr::read_tsv(count_file, show_col_types = FALSE,
                        guess_max = 5000)
gene_col_name <- colnames(raw)[1]
# Detect featureCounts metadata columns
meta_cols <- intersect(colnames(raw), c("Chr","Start","End","Strand","Length"))
if (length(meta_cols) >= 3) {
  cat("Detected featureCounts format. Dropping metadata cols:",
      paste(meta_cols, collapse=","), "\n")
  raw <- raw[, !(colnames(raw) %in% meta_cols), drop = FALSE]
}
# Strip trailing .bam from sample columns if present
colnames(raw) <- sub("\\.bam$", "", colnames(raw))
# Coerce all non-gene columns to numeric
genes <- raw[[gene_col_name]]
val_cols <- setdiff(colnames(raw), gene_col_name)
mat <- suppressWarnings(as.matrix(sapply(raw[, val_cols, drop = FALSE], as.numeric)))
rownames(mat) <- NULL
# Sum duplicate gene rows
agg <- rowsum(mat, group = genes, reorder = FALSE, na.rm = TRUE)
counts <- as.data.frame(agg, check.names = FALSE)
cat("Matrix dim:", dim(counts), "\n")
cat("First 3 rownames:\n"); print(head(rownames(counts), 3))
cat("First 3 colnames:\n"); print(head(colnames(counts), 3))

# --- 4. Detect IDI2-AS1 ---
# Possible identifiers: gene symbol IDI2-AS1, Ensembl ENSG00000260196
cat("\n== Step 4: Searching for IDI2-AS1 ==\n")
hits <- grep("^IDI2-AS1$|^ENSG00000260196(\\.[0-9]+)?$", rownames(counts),
             ignore.case = TRUE, value = TRUE)
cat("Matching rownames:", length(hits), "\n")
print(hits)

if (length(hits) == 0) {
  cat("\n!! IDI2-AS1 NOT found in row names. Checking column names...\n")
  hits_col <- grep("IDI2-AS1|ENSG00000260196", colnames(counts),
                   ignore.case = TRUE, value = TRUE)
  cat("Matches in columns:", length(hits_col), "\n")
  stop("IDI2-AS1 not detected. Inspect count file format manually.")
}

idi2_row <- hits[1]
idi2_counts <- as.numeric(counts[idi2_row, ])
names(idi2_counts) <- colnames(counts)

cat("\n== Step 5: IDI2-AS1 count summary ==\n")
cat("Gene row used:", idi2_row, "\n")
cat("Samples:", length(idi2_counts), "\n")
cat("Mean:", round(mean(idi2_counts), 2), " Median:", median(idi2_counts), "\n")
cat("# samples with >=10 reads:", sum(idi2_counts >= 10), "\n")
cat("# samples with >=5 reads:",  sum(idi2_counts >= 5), "\n")

# Also check IL5
il5_hits <- grep("^IL5$|^ENSG00000113525(\\.[0-9]+)?$", rownames(counts), value = TRUE)
il5_counts <- if (length(il5_hits) > 0) as.numeric(counts[il5_hits[1], ]) else rep(NA_real_, ncol(counts))

# --- 6. Write per-sample CSV ---
cat("\n== Step 6: Writing pilot CSV ==\n")
# Try to extract group info from pheno
group_col <- NULL
for (cn in colnames(pheno)) {
  v <- as.character(pheno[[cn]])
  if (any(grepl("AD|atopic|lesional|healthy|control|HC|NL|LS", v, ignore.case = TRUE))) {
    group_col <- cn; break
  }
}
group_vec <- if (!is.null(group_col)) pheno[[group_col]][match(colnames(counts), rownames(pheno))] else rep(NA, ncol(counts))

out <- tibble(
  gse_id        = GSE_ID,
  sample_id     = colnames(counts),
  group         = group_vec,
  idi2as1_count = idi2_counts,
  il5_count     = il5_counts,
  detected      = idi2_counts >= 10
)
out_path <- file.path(OUT_DIR, paste0("pilot_idi2as1_counts_", GSE_ID, ".csv"))
write.csv(out, out_path, row.names = FALSE)
cat("Wrote:", out_path, "\n")

# --- 7. Go/No-go verdict ---
cat("\n== GO/NO-GO ==\n")
if (sum(idi2_counts >= 10) >= 5) {
  cat("GO: IDI2-AS1 detected at >=10 reads in", sum(idi2_counts >= 10), "samples.\n")
} else {
  cat("NO-GO (this dataset): IDI2-AS1 detection insufficient. Try another dataset.\n")
}
