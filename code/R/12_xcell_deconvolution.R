# ============================================================
# 12 — Actual cell-type deconvolution (xCell) vs marker z-score
#
# Addresses F&IG Reviewer 2, point 2:
#   "Marker-signature scores are a crude substitute for cell-type
#    proportion deconvolution ... the authors do not report whether
#    the same results are obtained with actual cell-type proportion
#    estimates."
#
# This script runs xCell (Aran et al. 2017, Genome Biology) — an
# ssGSEA-based deconvolution with spillover compensation that models
# 64 cell types INCLUDING Eosinophils — locally (no external upload),
# extracts the per-sample Eosinophils enrichment score, and re-runs
# the cell-type-adjusted partial correlation and the mediation analysis
# using the xCell eosinophil estimate in place of the 7-gene marker
# z-score. Results are reported SIDE BY SIDE with the marker-z-score
# version so reviewers can see concordance.
#
# Deconvolution input: linear-scale, library-size-normalized expression
# (DESeq2 normalized counts for count datasets; FPKM for GSE58640),
# with HGNC gene symbols as rownames (xCell requirement). Ensembl-keyed
# datasets are mapped to symbols via a cached biomaRt lookup.
# ============================================================

suppressPackageStartupMessages({
  library(SummarizedExperiment)
  library(DESeq2)
  library(xCell)
  library(ppcor)
  library(mediation)
  library(dplyr)
  library(readr)
  library(ggplot2)
  library(tidyr)
})

source("code/R/loaders/common.R")

dir.create("results/figures",      recursive = TRUE, showWarnings = FALSE)
dir.create("results/tables",       recursive = TRUE, showWarnings = FALSE)
dir.create("results/intermediate", recursive = TRUE, showWarnings = FALSE)
dir.create("logs",                 recursive = TRUE, showWarnings = FALSE)

set.seed(42)

# 7-gene eosinophil marker panel (kept identical to script 09 for the
# apples-to-apples marker-z-score comparison).
EOS_GENES <- c("CLC","EPX","PRG2","RNASE2","RNASE3","SIGLEC8","CCR3")

ENSG_MAP <- c(
  CLC = "ENSG00000105205", EPX = "ENSG00000121594", PRG2 = "ENSG00000186652",
  RNASE2 = "ENSG00000169385", RNASE3 = "ENSG00000169397",
  SIGLEC8 = "ENSG00000105366", CCR3 = "ENSG00000183625"
)

resolve_genes <- function(rn, symbols) {
  rn_stripped <- strip_ens_version(rn)
  out <- integer(0)
  for (s in symbols) {
    cand <- c(s, ENSG_MAP[s]); cand <- cand[!is.na(cand)]
    hit  <- which(rn %in% cand | rn_stripped %in% cand)
    if (length(hit)) out <- c(out, hit[1])
  }
  unique(out)
}

score_panel <- function(mat, idx) {            # mean z across markers (script-09 method)
  if (length(idx) == 0) return(rep(NA_real_, ncol(mat)))
  sub <- mat[idx, , drop = FALSE]
  z   <- t(scale(t(sub))); z[is.na(z)] <- 0
  colMeans(z, na.rm = TRUE)
}

# ---- Ensembl -> symbol map (cached; biomaRt is a public reference GET) ----
ENS_MAP_FILE <- "data/metadata/ensembl_to_symbol.csv"
get_ens2sym <- function(ens_ids) {
  ens_ids <- unique(strip_ens_version(ens_ids))
  cache <- if (file.exists(ENS_MAP_FILE))
    read_csv(ENS_MAP_FILE, show_col_types = FALSE) else
    data.frame(ensembl = character(), symbol = character())
  missing <- setdiff(ens_ids, cache$ensembl)
  if (length(missing)) {
    message("  biomaRt lookup for ", length(missing), " Ensembl IDs ...")
    mart <- biomaRt::useEnsembl(biomart = "genes",
                                dataset = "hsapiens_gene_ensembl")
    bm <- biomaRt::getBM(
      attributes = c("ensembl_gene_id", "hgnc_symbol"),
      filters = "ensembl_gene_id", values = missing, mart = mart)
    bm <- bm[bm$hgnc_symbol != "" & !is.na(bm$hgnc_symbol), ]
    cache <- rbind(cache, data.frame(ensembl = bm$ensembl_gene_id,
                                     symbol  = bm$hgnc_symbol))
    cache <- cache[!duplicated(cache$ensembl), ]
    write_csv(cache, ENS_MAP_FILE)
  }
  setNames(cache$symbol, cache$ensembl)
}

# ---- Build a symbol-keyed, linear-scale expression matrix for xCell ----
build_xcell_input <- function(se, id_type) {
  if ("counts" %in% names(assays(se))) {
    dds <- DESeqDataSet(se, design = ~ group)
    dds <- dds[rowSums(counts(dds)) >= 10, ]
    dds <- estimateSizeFactors(dds)
    expr <- counts(dds, normalized = TRUE)          # linear, lib-size normalized
  } else {
    expr <- assay(se)                                # already FPKM (linear)
    expr <- expr[rowSums(expr) > 0, , drop = FALSE]
  }
  rn <- rownames(expr)
  if (id_type == "ensembl") {
    m  <- get_ens2sym(rn)
    sym <- m[strip_ens_version(rn)]
    keep <- !is.na(sym)
    expr <- expr[keep, , drop = FALSE]
    sym  <- sym[keep]
    expr <- rowsum(expr, group = sym)                # collapse dup symbols
  }
  expr[!duplicated(rownames(expr)), , drop = FALSE]
}

# ---- VST/log matrix for the marker z-score (script-09 method) ----
build_marker_mat <- function(se) {
  if ("counts" %in% names(assays(se))) {
    dds <- DESeqDataSet(se, design = ~ group)
    dds <- dds[rowSums(counts(dds)) >= 10, ]
    assay(vst(dds, blind = TRUE))
  } else {
    log2(assay(se) + 1)
  }
}

datasets <- read_csv("data/metadata/final_datasets.csv", show_col_types = FALSE) %>%
  filter(status == "USE")

per_dataset       <- list()
mediation_summary <- list()
xcell_full        <- list()

for (i in seq_len(nrow(datasets))) {
  gse     <- datasets$gse_id[i]
  disease <- datasets$disease[i]
  id_type <- datasets$id_type[i]
  cat("\n==", gse, "(", disease, ") ==\n")

  se  <- readRDS(file.path("data/processed", paste0(gse, "_se.rds")))

  # focal genes from the marker/VST matrix (same as script 09)
  mmat  <- build_marker_mat(se)
  i_idi <- resolve_genes(rownames(mmat), c("IDI2-AS1", "ENSG00000260196"))
  i_il5 <- resolve_genes(rownames(mmat), c("IL5", "ENSG00000113525"))
  if (length(i_idi) == 0 || length(i_il5) == 0) { cat("  SKIP focal gene missing\n"); next }
  idx_eos <- resolve_genes(rownames(mmat), EOS_GENES)

  # ---- xCell deconvolution ----
  xin <- build_xcell_input(se, id_type)
  cat("  xCell input:", nrow(xin), "symbols x", ncol(xin), "samples\n")
  xc  <- tryCatch(
    xCellAnalysis(xin, rnaseq = TRUE, parallel.sz = 1),
    error = function(e) { cat("  xCell FAILED:", conditionMessage(e), "\n"); NULL })
  if (is.null(xc) || !("Eosinophils" %in% rownames(xc))) {
    cat("  xCell unavailable for this cohort\n"); next
  }
  xcell_full[[gse]] <- xc
  # align xCell columns to SE samples (spillover-compensated final score)
  eos_xcell <- xc["Eosinophils", colnames(mmat)]

  # RAW ssGSEA enrichment (BEFORE spillover compensation). The compensated
  # score floors eosinophils in epithelial cohorts (see script 12b diagnostic:
  # final score median ~= 0 / ~40% zeros, but raw enrichment median ~500 /
  # 0% zeros). The raw enrichment is therefore the fair "actual deconvolution"
  # mediator for this rare, spillover-prone cell type.
  raw_enr <- tryCatch(
    rawEnrichmentAnalysis(as.matrix(xin),
      signatures = xCell.data$signatures, genes = xCell.data$genes,
      parallel.sz = 1),
    error = function(e) { cat("  rawEnrichment FAILED:", conditionMessage(e), "\n"); NULL })
  eos_xcell_raw <- if (!is.null(raw_enr) && "Eosinophils" %in% rownames(raw_enr))
    raw_enr["Eosinophils", colnames(mmat)] else rep(NA_real_, ncol(mmat))

  df <- data.frame(
    sample_id   = colnames(mmat),
    group       = colData(se)$group,
    idi2as1     = as.numeric(mmat[i_idi[1], ]),
    il5         = as.numeric(mmat[i_il5[1], ]),
    eos_marker  = score_panel(mmat, idx_eos),       # 7-gene mean z (old)
    eos_xcell   = as.numeric(eos_xcell),            # xCell spillover-compensated
    eos_xcell_raw = as.numeric(eos_xcell_raw),      # xCell raw ssGSEA enrichment
    dataset     = gse,
    disease     = disease,
    stringsAsFactors = FALSE
  )

  # ---- partial correlation: marker vs xCell conditioning ----
  ct  <- suppressWarnings(cor.test(df$idi2as1, df$il5, method = "spearman"))
  pcor_one <- function(ctrl) {
    if (all(is.na(ctrl)) || sd(ctrl, na.rm = TRUE) == 0)
      return(c(rho = NA_real_, p = NA_real_))
    pp <- ppcor::pcor.test(df$idi2as1, df$il5, ctrl, method = "spearman")
    c(rho = pp$estimate, p = pp$p.value)
  }
  adj_marker    <- pcor_one(df$eos_marker)
  adj_xcell     <- pcor_one(df$eos_xcell)
  adj_xcell_raw <- pcor_one(df$eos_xcell_raw)

  # spearman concordance of each deconvolution estimate with the marker score
  conc      <- suppressWarnings(cor(df$eos_marker, df$eos_xcell,
                                    method = "spearman", use = "complete.obs"))
  conc_raw  <- suppressWarnings(cor(df$eos_marker, df$eos_xcell_raw,
                                    method = "spearman", use = "complete.obs"))

  per_dataset[[gse]] <- list(
    points  = df,
    summary = data.frame(
      dataset = gse, disease = disease, n = nrow(df),
      raw_rho = unname(ct$estimate), raw_p = ct$p.value,
      adj_rho_marker   = unname(adj_marker["rho"]),    adj_p_marker   = unname(adj_marker["p"]),
      adj_rho_xcell    = unname(adj_xcell["rho"]),     adj_p_xcell    = unname(adj_xcell["p"]),
      adj_rho_xcellraw = unname(adj_xcell_raw["rho"]), adj_p_xcellraw = unname(adj_xcell_raw["p"]),
      marker_xcell_concordance     = conc,
      marker_xcellraw_concordance  = conc_raw,
      xcell_eos_frac_zero = mean(df$eos_xcell == 0, na.rm = TRUE),
      xcell_eos_sd        = sd(df$eos_xcell, na.rm = TRUE),
      xcellraw_eos_sd     = sd(df$eos_xcell_raw, na.rm = TRUE),
      stringsAsFactors = FALSE
    )
  )
  cat(sprintf("  raw rho=%.3f | adj(marker)=%.3f | adj(xCell)=%.3f | marker~xCell rho=%.3f\n",
              ct$estimate, adj_marker["rho"], adj_xcell["rho"], conc))

  # ---- mediation with xCell eosinophil score as mediator ----
  # NOTE: reported as a linear effect decomposition (proportion of the
  # bulk IDI2-AS1-IL5 association statistically attributable to eosinophil
  # abundance), NOT a causal effect — see manuscript Limitations.
  # Literal formulas / fixed column names: mediate(boot=TRUE) re-evaluates
  # each model's stored call on bootstrap-resampled data, which fails if the
  # call contains a programmatic formula constructor (as.formula/paste) or a
  # non-global variable. Building d2 with fixed names + literal formulas keeps
  # the call self-contained.
  run_med <- function(med_values, label) {
    if (sd(med_values, na.rm = TRUE) == 0 || nrow(df) < 20) return(NULL)
    d2 <- data.frame(idi2as1 = df$idi2as1, il5 = df$il5, med = med_values)
    m_model <- lm(med ~ idi2as1, data = d2)
    o_model <- lm(il5 ~ idi2as1 + med, data = d2)
    med <- tryCatch(
      mediate(m_model, o_model, treat = "idi2as1", mediator = "med",
              sims = 1000, boot = TRUE, boot.ci.type = "perc"),
      error = function(e) { cat("  mediation FAILED (", label, "):",
                                conditionMessage(e), "\n"); NULL })
    if (is.null(med)) return(NULL)
    data.frame(
      dataset = gse, disease = disease, mediator = label,
      ACME = med$d.avg, ACME_lo = med$d.avg.ci[1], ACME_hi = med$d.avg.ci[2], ACME_p = med$d.avg.p,
      ADE  = med$z.avg, ADE_lo  = med$z.avg.ci[1], ADE_hi  = med$z.avg.ci[2], ADE_p  = med$z.avg.p,
      total_effect = med$tau.coef, total_p = med$tau.p,
      prop_mediated = med$n.avg,
      stringsAsFactors = FALSE)
  }
  mm <- run_med(df$eos_marker,    "eosinophil_marker_z")
  mx <- run_med(df$eos_xcell,     "eosinophil_xCell_compensated")
  mr <- run_med(df$eos_xcell_raw, "eosinophil_xCell_raw")
  mediation_summary[[gse]] <- bind_rows(mm, mx, mr)
  if (!is.null(mr))
    cat(sprintf("  mediation(xCell raw): ACME=%.3f (p=%.3g) total=%.3f prop=%.2f\n",
                mr$ACME, mr$ACME_p, mr$total_effect, mr$prop_mediated))
}

summary_tbl <- bind_rows(lapply(per_dataset, `[[`, "summary"))
points_tbl  <- bind_rows(lapply(per_dataset, `[[`, "points"))
write_csv(summary_tbl, "results/tables/Table_xcell_vs_marker_correlation.csv")
write_csv(points_tbl,  "results/intermediate/xcell_points.csv")

cat("\n=== xCell vs marker partial-correlation summary ===\n")
print(as.data.frame(summary_tbl), row.names = FALSE)

if (length(mediation_summary)) {
  med_tbl <- bind_rows(mediation_summary)
  write_csv(med_tbl, "results/tables/Table_xcell_vs_marker_mediation.csv")
  cat("\n=== Mediation: marker-z vs xCell mediator ===\n")
  print(as.data.frame(med_tbl), row.names = FALSE)
}

# save full xCell matrices (all 64 cell types) for the supplement / repo
for (g in names(xcell_full)) {
  write.csv(xcell_full[[g]],
            file = file.path("results/intermediate", paste0("xcell_", g, ".csv")))
}

cat("\nDONE. Wrote Table_xcell_vs_marker_{correlation,mediation}.csv and per-dataset xcell_*.csv\n")
