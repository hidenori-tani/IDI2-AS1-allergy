# ============================================================
# 13 - Deconvolution-validation figure (answers F&IG Reviewer 2.2)
#
# Shows that the marker-based eosinophil-composition result is
# reproduced by ACTUAL cell-type deconvolution (xCell raw ssGSEA
# enrichment), and exposes the spillover-compensation floor artifact
# that makes the *compensated* xCell score inappropriate for this
# rare, spillover-prone cell type.
#
#  A  Concordance: 7-gene marker z-score vs xCell raw enrichment (asthma)
#  B  Partial-correlation attenuation under each estimator, all cohorts
#  C  Mediation proportion (bootstrap CI) under each estimator, asthma
#  D  Spillover floor: compensated vs raw eosinophil estimate (asthma)
# ============================================================

suppressPackageStartupMessages({
  library(dplyr); library(readr); library(ggplot2); library(tidyr); library(gridExtra)
})

dir.create("results/figures", showWarnings = FALSE, recursive = TRUE)

corr <- read_csv("results/tables/Table_xcell_vs_marker_correlation.csv", show_col_types = FALSE)
med  <- read_csv("results/tables/Table_xcell_vs_marker_mediation.csv",    show_col_types = FALSE)
pts  <- read_csv("results/intermediate/xcell_points.csv",                 show_col_types = FALSE)

disease_lab <- c(asthma = "Asthma", atopic_dermatitis = "Atopic dermatitis",
                 eosinophilic_esophagitis = "Eos. esophagitis", nasal_polyps = "Nasal polyps")
base <- theme_bw(base_size = 9) +
  theme(plot.title = element_text(face = "bold", size = 10),
        legend.position = "bottom", legend.title = element_blank())

# ---- A: marker vs xCell raw enrichment concordance (asthma) ----
a_df <- pts %>% filter(dataset == "GSE152004")
rA <- cor(a_df$eos_marker, a_df$eos_xcell_raw, method = "spearman", use = "complete.obs")
pA <- ggplot(a_df, aes(eos_marker, eos_xcell_raw)) +
  geom_point(alpha = 0.4, size = 1, colour = "#1f78b4") +
  geom_smooth(method = "lm", se = TRUE, colour = "black", linewidth = 0.5) +
  labs(x = "7-gene marker z-score", y = "xCell raw enrichment",
       title = sprintf("A  Eosinophil estimate concordance\n   (asthma, Spearman rho = %.2f)", rA)) +
  base

# ---- B: partial-correlation attenuation, all cohorts ----
b_df <- corr %>%
  transmute(disease,
            Raw = raw_rho,
            `Marker z` = adj_rho_marker,
            `xCell raw` = adj_rho_xcellraw,
            `xCell comp.` = adj_rho_xcell) %>%
  pivot_longer(-disease, names_to = "estimator", values_to = "rho") %>%
  mutate(disease = disease_lab[disease],
         estimator = factor(estimator,
                            levels = c("Raw","Marker z","xCell raw","xCell comp.")))
pB <- ggplot(b_df, aes(estimator, rho, fill = estimator)) +
  geom_col(width = 0.7) +
  geom_hline(yintercept = 0, linewidth = 0.3) +
  facet_wrap(~ disease, nrow = 1) +
  scale_fill_manual(values = c(Raw = "grey60", `Marker z` = "#33a02c",
                               `xCell raw` = "#1f78b4", `xCell comp.` = "#e31a1c")) +
  labs(x = NULL, y = "IDI2-AS1 - IL5 (partial) Spearman rho",
       title = "B  Partial-correlation attenuation when conditioning on eosinophils") +
  base + theme(axis.text.x = element_text(angle = 35, hjust = 1, size = 7))

# ---- C: mediation proportion with bootstrap CI (asthma) ----
c_df <- med %>% filter(dataset == "GSE152004") %>%
  transmute(estimator = recode(mediator,
              eosinophil_marker_z = "Marker z",
              eosinophil_xCell_raw = "xCell raw",
              eosinophil_xCell_compensated = "xCell comp."),
            prop = prop_mediated, ACME, lo = ACME_lo, hi = ACME_hi, p = ACME_p) %>%
  mutate(estimator = factor(estimator, levels = c("Marker z","xCell raw","xCell comp.")),
         sig = ifelse(p < 0.05, "p < 0.05", "n.s."))
pC <- ggplot(c_df, aes(estimator, ACME, colour = sig)) +
  geom_hline(yintercept = 0, linewidth = 0.3, colour = "grey50") +
  geom_pointrange(aes(ymin = lo, ymax = hi), linewidth = 0.7, size = 0.5) +
  geom_text(aes(label = sprintf("%.0f%% med.", 100 * prop)),
            vjust = -1.1, size = 2.8, show.legend = FALSE) +
  scale_colour_manual(values = c("p < 0.05" = "#1f78b4", "n.s." = "#e31a1c")) +
  labs(x = NULL, y = "ACME (eosinophil-mediated effect)",
       title = "C  Mediation of IDI2-AS1->IL5 via eosinophils\n   (asthma, n = 695; bootstrap 95% CI)") +
  base

# ---- D: spillover floor - compensated vs raw (asthma) ----
d_df <- a_df %>%
  transmute(`xCell compensated` = scale(eos_xcell)[,1],
            `xCell raw` = scale(eos_xcell_raw)[,1]) %>%
  pivot_longer(everything(), names_to = "score", values_to = "z")
fz <- mean(a_df$eos_xcell == 0)
pD <- ggplot(d_df, aes(z, fill = score)) +
  geom_histogram(bins = 40, alpha = 0.6, position = "identity") +
  scale_fill_manual(values = c("xCell compensated" = "#e31a1c", "xCell raw" = "#1f78b4")) +
  labs(x = "Eosinophil estimate (z-scaled)", y = "Samples",
       title = sprintf("D  Spillover-compensation floors eosinophils\n   (asthma: %.0f%% of compensated scores = 0)", 100 * fz)) +
  base

g <- arrangeGrob(pA, pC, pB, pD, layout_matrix = rbind(c(1, 2), c(3, 3), c(4, 4)),
                 heights = c(1.1, 1.0, 1.0))
# cairo_pdf renders Unicode glyphs (rho, ->, -) that the default pdf() device
# turns into empty boxes - the root cause of F&IG Reviewer 1, point 7
# ("empty boxes in Figure 1").
ggsave("results/figures/Fig_deconvolution_validation.pdf", g, width = 8.5, height = 9.5)
cat("Saved results/figures/Fig_deconvolution_validation.pdf\n")
