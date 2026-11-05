# ============================================================
# 13b — SUPERSEDED earlier version of Figure 6 (not the manuscript's figure).
#   It selected the asthma samples with grepl("^HR"), which drops the nine "SJ"
#   samples (686 of 695). The manuscript's Figure 6 is drawn by
#   code/python/18_figure6.py from the same tables on all 695 samples.
#   (three eosinophil-abundance estimates, not independent of one another:
#    marker z-score, TPM-input xCell raw enrichment, GSVA ssGSEA).
#   Reads results/tables/bulkmask/{points,correlations,decompositions}.csv
#   Writes results/figures/Fig6_superseded_13b.pdf (vector).
#   Rscript --vanilla code/R/13b_fig6_bulkmask.R
# ============================================================
suppressPackageStartupMessages({
  library(ggplot2); library(patchwork); library(ppcor); library(dplyr); library(readr)
})
dir.create("results/figures", recursive = TRUE, showWarnings = FALSE)

pts <- read_csv("results/tables/bulkmask/points.csv", show_col_types = FALSE)
ast <- pts[grepl("^HR", pts$sample_id), ]            # asthma cohort (GSE152004)
cor <- read_csv("results/tables/bulkmask/correlations.csv", show_col_types = FALSE) |>
  filter(dataset == "GSE152004")
dec <- read_csv("results/tables/bulkmask/decompositions.csv", show_col_types = FALSE) |>
  filter(dataset == "GSE152004", adjusted == "none")

z <- function(x) (x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE)
rho_xy <- function(x, y) suppressWarnings(cor(x, y, method = "spearman", use = "complete.obs"))

# ---- Panel A: concordance of the three estimates ----
a_df <- rbind(
  data.frame(marker = z(ast$sig_eosinophil), other = z(ast$eos_xcell_raw),
             panel = sprintf("xCell raw  (rho = %.2f)", rho_xy(ast$sig_eosinophil, ast$eos_xcell_raw))),
  data.frame(marker = z(ast$sig_eosinophil), other = z(ast$eos_gsva),
             panel = sprintf("GSVA ssGSEA  (rho = %.2f)", rho_xy(ast$sig_eosinophil, ast$eos_gsva))))
pA <- ggplot(a_df, aes(marker, other)) +
  geom_point(alpha = 0.25, size = 0.6, colour = "#1f78b4") +
  geom_smooth(method = "lm", se = FALSE, colour = "#e31a1c", linewidth = 0.5) +
  facet_wrap(~panel) +
  labs(x = "Eosinophil marker z-score", y = "Second estimate (z)",
       title = "A  Concordance of three eosinophil-abundance estimates (asthma)") +
  theme_bw(base_size = 8)

# ---- Panel B: partial-correlation attenuation ----
comp_partial <- ppcor::pcor.test(ast$exposure, ast$outcome, ast$eos_xcell_comp, method = "spearman")$estimate
b_df <- data.frame(
  est = factor(c("Raw", "Marker z", "xCell raw", "GSVA", "xCell comp."),
               levels = c("Raw", "Marker z", "xCell raw", "GSVA", "xCell comp.")),
  rho = c(cor$rho[cor$model == "raw"], cor$rho[cor$model == "adj_marker"],
          cor$rho[cor$model == "adj_xcellraw"], cor$rho[cor$model == "adj_gsva"], comp_partial))
pB <- ggplot(b_df, aes(est, rho, fill = est)) +
  geom_col(width = 0.65) +
  geom_hline(yintercept = 0, linewidth = 0.3) +
  scale_fill_manual(values = c(Raw = "grey60", `Marker z` = "#33a02c",
    `xCell raw` = "#1f78b4", GSVA = "#6a3d9a", `xCell comp.` = "#e31a1c"), guide = "none") +
  labs(x = NULL, y = "IDI2-AS1 - IL5 partial Spearman rho",
       title = "B  Attenuation when conditioning on eosinophils") +
  theme_bw(base_size = 8) + theme(axis.text.x = element_text(angle = 25, hjust = 1))

# ---- Panel C: decomposition ACME with 95% CI + proportion ----
lab <- c(marker = "Marker z", xcellraw = "xCell raw", gsva = "GSVA")
c_df <- dec |>
  transmute(est = factor(lab[estimator], levels = c("Marker z", "GSVA", "xCell raw")),
            ACME, lo = ACME_lo, hi = ACME_hi, p = ACME_p, prop = prop_mediated) |>
  mutate(siglab = sprintf("%.0f%%", pmin(prop, 1) * 100))
pC <- ggplot(c_df, aes(est, ACME)) +
  geom_hline(yintercept = 0, linewidth = 0.3) +
  geom_errorbar(aes(ymin = lo, ymax = hi), width = 0.15, colour = "#1f78b4") +
  geom_point(size = 1.8, colour = "#1f78b4") +
  geom_text(aes(label = siglab, y = hi), vjust = -0.6, size = 2.6) +
  labs(x = NULL, y = "Eosinophil-associated component",
       title = "C  Decomposition (10,000 resamples); % = proportion") +
  theme_bw(base_size = 8)

# ---- Panel D: spillover floor of the compensated xCell score ----
d_df <- rbind(
  data.frame(score = z(ast$eos_xcell_comp), kind = sprintf("xCell compensated (%.0f%% zero)",
                                                            100 * mean(ast$eos_xcell_comp == 0, na.rm = TRUE))),
  data.frame(score = z(ast$eos_xcell_raw),  kind = "xCell raw (0% zero)"))
pD <- ggplot(d_df, aes(score, fill = kind)) +
  geom_histogram(bins = 40, alpha = 0.6, position = "identity") +
  scale_fill_manual(values = c("#e31a1c", "#1f78b4"), name = NULL) +
  labs(x = "Eosinophil estimate (z-scaled)", y = "Samples",
       title = "D  Spillover compensation floors a rare cell type") +
  theme_bw(base_size = 8) + theme(legend.position = "bottom", legend.text = element_text(size = 6))

fig <- (pA | pB) / (pC | pD) + plot_layout(heights = c(1, 1))
ggsave("results/figures/Fig6_superseded_13b.pdf", fig, width = 9, height = 7)
cat("Wrote results/figures/Fig6_superseded_13b.pdf\n")
cat(sprintf("  panel B: raw=%.3f marker=%.3f xCellraw=%.3f gsva=%.3f comp=%.3f\n",
            b_df$rho[1], b_df$rho[2], b_df$rho[3], b_df$rho[4], b_df$rho[5]))
print(c_df)
