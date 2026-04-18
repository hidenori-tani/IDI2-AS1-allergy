# ============================================================
# Cell-type-adjusted IDI2-AS1 vs IL5 correlation
# ============================================================
# Tests whether the positive tissue-bulk IDI2-AS1<->IL5 correlation is
# explained by shared expression in allergic-effector cells.
#
# Strategy:
#   1. Build per-sample marker-score vectors for two compartments:
#        EOSINOPHIL : CLC, EPX, PRG2, RNASE2, RNASE3, SIGLEC8, CCR3
#        TH2/TYPE-2 : GATA3, IL4R, CCR4, PTGDR2, IL13, IL17RB
#      score = mean of per-gene z-score (per-dataset standardization).
#   2. Spearman / Pearson:
#        unadjusted   : cor(IDI2-AS1, IL5)
#        cell-adjusted: pcor(IDI2-AS1, IL5 | EOSINOPHIL, TH2)  [ppcor::pcor.test]
#   3. Mediation (per dataset where both genes & both signatures are detected):
#        treat = IDI2-AS1, mediator = EOSINOPHIL or TH2, outcome = IL5
#        -> indirect effect (ACME) and direct effect (ADE) with bootstrap CI.
# ============================================================

suppressPackageStartupMessages({
  library(SummarizedExperiment)
  library(DESeq2)
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

# ---- marker panels ----
EOS_GENES <- c("CLC","EPX","PRG2","RNASE2","RNASE3","SIGLEC8","CCR3")
TH2_GENES <- c("GATA3","IL4R","CCR4","PTGDR2","IL13","IL17RB")

# Some count matrices use Ensembl IDs (GSE136825, GSE246323).
# Provide ENSG fallbacks for the marker panels.
ENSG_MAP <- c(
  CLC     = "ENSG00000105205",
  EPX     = "ENSG00000121594",
  PRG2    = "ENSG00000186652",
  RNASE2  = "ENSG00000169385",
  RNASE3  = "ENSG00000169397",
  SIGLEC8 = "ENSG00000105366",
  CCR3    = "ENSG00000183625",
  GATA3   = "ENSG00000107485",
  IL4R    = "ENSG00000077238",
  CCR4    = "ENSG00000183813",
  PTGDR2  = "ENSG00000183134",
  IL13    = "ENSG00000169194",
  IL17RB  = "ENSG00000056736"
)

resolve_genes <- function(rn, symbols) {
  rn_stripped <- strip_ens_version(rn)
  out <- integer(0)
  for (s in symbols) {
    cand <- c(s, ENSG_MAP[s])
    cand <- cand[!is.na(cand)]
    hit  <- which(rn %in% cand | rn_stripped %in% cand)
    if (length(hit)) out <- c(out, hit[1])
  }
  unique(out)
}

build_expr <- function(se) {
  if ("counts" %in% names(assays(se))) {
    dds <- DESeqDataSet(se, design = ~ group)
    dds <- dds[rowSums(counts(dds)) >= 10, ]
    vsd <- vst(dds, blind = TRUE)
    list(mat = assay(vsd), kind = "vst")
  } else {
    list(mat = log2(assay(se) + 1), kind = "log2_FPKM_plus1")
  }
}

# Per-sample mean of standardized expression across a marker panel
score_panel <- function(mat, idx) {
  if (length(idx) == 0) return(rep(NA_real_, ncol(mat)))
  sub <- mat[idx, , drop = FALSE]
  z   <- t(scale(t(sub)))               # per-gene z-score across samples
  z[is.na(z)] <- 0
  colMeans(z, na.rm = TRUE)
}

datasets <- read_csv("data/metadata/final_datasets.csv", show_col_types = FALSE) %>%
  filter(status == "USE")

per_dataset <- list()
mediation_summary <- list()

for (i in seq_len(nrow(datasets))) {
  gse     <- datasets$gse_id[i]
  disease <- datasets$disease[i]
  cat("\n==", gse, "(", disease, ") ==\n")

  se   <- readRDS(file.path("data/processed", paste0(gse, "_se.rds")))
  ex   <- build_expr(se)
  mat  <- ex$mat

  i_idi <- resolve_genes(rownames(mat), c("IDI2-AS1", "ENSG00000260196"))
  i_il5 <- resolve_genes(rownames(mat), c("IL5", "ENSG00000113525"))
  if (length(i_idi) == 0) { cat("  SKIP IDI2-AS1 not found\n"); next }
  if (length(i_il5) == 0) { cat("  SKIP IL5 not found\n");      next }

  idx_eos <- resolve_genes(rownames(mat), EOS_GENES)
  idx_th2 <- resolve_genes(rownames(mat), TH2_GENES)

  cat("  markers detected -- eos:", length(idx_eos), "/", length(EOS_GENES),
      " th2:", length(idx_th2), "/", length(TH2_GENES), "\n")

  df <- data.frame(
    sample_id = colnames(mat),
    group     = colData(se)$group,
    idi2as1   = as.numeric(mat[i_idi[1], ]),
    il5       = as.numeric(mat[i_il5[1], ]),
    eos_score = score_panel(mat, idx_eos),
    th2_score = score_panel(mat, idx_th2),
    dataset   = gse,
    disease   = disease,
    stringsAsFactors = FALSE
  )

  # Unadjusted
  ct <- suppressWarnings(cor.test(df$idi2as1, df$il5, method = "spearman"))
  # Partial: control for both signatures (drop NA score columns first)
  ctrls <- df[, c("eos_score","th2_score"), drop = FALSE]
  ctrls <- ctrls[, sapply(ctrls, function(x) !all(is.na(x))), drop = FALSE]
  if (ncol(ctrls) > 0) {
    pp <- ppcor::pcor.test(df$idi2as1, df$il5, ctrls, method = "spearman")
    pp_rho <- pp$estimate; pp_p <- pp$p.value
  } else {
    pp_rho <- NA_real_; pp_p <- NA_real_
  }

  per_dataset[[gse]] <- list(
    points  = df,
    summary = data.frame(
      dataset = gse, disease = disease, n = nrow(df),
      n_eos_markers = length(idx_eos), n_th2_markers = length(idx_th2),
      raw_rho   = unname(ct$estimate), raw_p = ct$p.value,
      adj_rho   = pp_rho, adj_p = pp_p,
      data_type = ex$kind,
      stringsAsFactors = FALSE
    )
  )

  # ---- mediation: treat=IDI2-AS1, mediator=eos_score, outcome=IL5 ----
  if (length(idx_eos) >= 3 && nrow(df) >= 20) {
    set.seed(42)
    m_model <- lm(eos_score ~ idi2as1, data = df)
    o_model <- lm(il5 ~ idi2as1 + eos_score, data = df)
    med <- tryCatch(
      mediate(m_model, o_model, treat = "idi2as1", mediator = "eos_score",
              sims = 1000, boot = TRUE, boot.ci.type = "perc"),
      error = function(e) { cat("  mediation FAILED:", conditionMessage(e), "\n"); NULL })
    if (!is.null(med)) {
      mediation_summary[[gse]] <- data.frame(
        dataset = gse, disease = disease, mediator = "eosinophil_score",
        ACME = med$d.avg, ACME_lo = med$d.avg.ci[1], ACME_hi = med$d.avg.ci[2], ACME_p = med$d.avg.p,
        ADE  = med$z.avg, ADE_lo  = med$z.avg.ci[1], ADE_hi  = med$z.avg.ci[2], ADE_p  = med$z.avg.p,
        prop_mediated = med$n.avg,
        stringsAsFactors = FALSE
      )
      cat(sprintf("  mediation: ACME=%.3f (p=%.3g), ADE=%.3f (p=%.3g), prop=%.2f\n",
                  med$d.avg, med$d.avg.p, med$z.avg, med$z.avg.p, med$n.avg))
    }
  } else {
    cat("  mediation skipped (markers or n too small)\n")
  }
}

# ---- aggregate ----
summary_tbl <- bind_rows(lapply(per_dataset, `[[`, "summary"))
points_tbl  <- bind_rows(lapply(per_dataset, `[[`, "points"))
write_csv(summary_tbl, "results/tables/Table_celltype_adjusted_correlation.csv")
write_csv(points_tbl,  "results/intermediate/celltype_adjusted_points.csv")

cat("\n=== Cell-type-adjusted correlation summary ===\n")
print(as.data.frame(summary_tbl))

if (length(mediation_summary)) {
  med_tbl <- bind_rows(mediation_summary)
  write_csv(med_tbl, "results/tables/Table_mediation_eosinophil.csv")
  cat("\n=== Mediation (treat=IDI2-AS1, mediator=eos_score, outcome=IL5) ===\n")
  print(as.data.frame(med_tbl))
}

# ---- Figure 4: faceted scatters showing the cell-type story ----
plot_df <- points_tbl %>%
  pivot_longer(c(eos_score, th2_score),
               names_to = "panel", values_to = "score") %>%
  mutate(panel = recode(panel,
                        eos_score = "Eosinophil signature",
                        th2_score = "Th2 / type-2 signature"))

p1 <- ggplot(points_tbl, aes(idi2as1, il5, color = group)) +
  geom_point(alpha = 0.5, size = 1.3) +
  geom_smooth(method = "lm", se = TRUE, color = "black", linewidth = 0.5) +
  facet_wrap(~ paste(disease, dataset, sep = "\n"), scales = "free", ncol = 5) +
  scale_color_manual(values = c(control = "#377eb8", patient = "#e41a1c")) +
  labs(x = "IDI2-AS1", y = "IL5", title = "Raw IDI2-AS1 vs IL5") +
  theme_bw(base_size = 10) + theme(legend.position = "bottom")

p2 <- ggplot(plot_df, aes(idi2as1, score, color = group)) +
  geom_point(alpha = 0.5, size = 1.2) +
  geom_smooth(method = "lm", se = TRUE, color = "black", linewidth = 0.5) +
  facet_grid(panel ~ paste(disease, dataset, sep = "\n"), scales = "free") +
  scale_color_manual(values = c(control = "#377eb8", patient = "#e41a1c")) +
  labs(x = "IDI2-AS1", y = "Cell-type signature score (mean z)",
       title = "IDI2-AS1 vs cell-type signatures (composition driver?)") +
  theme_bw(base_size = 9) + theme(legend.position = "bottom")

ggsave("results/figures/Fig4_celltype_adjusted.pdf",
       gridExtra::arrangeGrob(p1, p2, ncol = 1, heights = c(1, 1.6)),
       width = 14, height = 11)

cat("\nSaved Fig4_celltype_adjusted.pdf\n")
