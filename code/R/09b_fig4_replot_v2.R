# Re-plot Figure 4 (and new Supp Fig 1) from existing points CSV.
# Avoids re-running the upstream statistical pipeline (ppcor / mediation
# already executed in v1 run on Apr 18; outputs in results/intermediate/).
# Used to ship the BBRC font-size revision (editor letter BBRC-26-2497).
#
# Saves panels A and B as separate PDFs; build_labeled_figures.py composites
# them via stack_two_panels_vertically (same pattern used for Fig 2 and Fig 5).

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(ggplot2)
})

dir.create("results/figures", recursive = TRUE, showWarnings = FALSE)

points_tbl <- read_csv("results/intermediate/celltype_adjusted_points.csv",
                       show_col_types = FALSE)

raw_df <- points_tbl %>%
  transmute(idi2as1, il5_or_score = il5, group, dataset, disease)
eos_df <- points_tbl %>%
  transmute(idi2as1, il5_or_score = eos_score, group, dataset, disease)
th2_df <- points_tbl %>%
  transmute(idi2as1, score = th2_score, group, dataset, disease)

theme_bbrc <- theme_bw(base_size = 12) +
  theme(strip.text = element_text(size = 11),
        axis.text  = element_text(size = 11),
        axis.title = element_text(size = 12),
        legend.position = "bottom",
        legend.text  = element_text(size = 11),
        legend.title = element_text(size = 11),
        plot.title = element_text(face = "bold", size = 12))

p1 <- ggplot(raw_df, aes(idi2as1, il5_or_score, color = group)) +
  geom_point(alpha = 0.5, size = 1.3) +
  geom_smooth(method = "lm", se = TRUE, color = "black", linewidth = 0.5) +
  facet_wrap(~ paste(disease, dataset, sep = "\n"), scales = "free", ncol = 5) +
  scale_color_manual(values = c(control = "#377eb8", patient = "#e41a1c")) +
  labs(x = "IDI2-AS1", y = "IL5") +
  theme_bbrc

ggsave("results/figures/Fig4A_raw_correlation.pdf",
       p1, width = 9, height = 3.3)
cat("Saved Fig4A_raw_correlation.pdf\n")

p2 <- ggplot(eos_df, aes(idi2as1, il5_or_score, color = group)) +
  geom_point(alpha = 0.5, size = 1.2) +
  geom_smooth(method = "lm", se = TRUE, color = "black", linewidth = 0.5) +
  facet_wrap(~ paste(disease, dataset, sep = "\n"), scales = "free", ncol = 5) +
  scale_color_manual(values = c(control = "#377eb8", patient = "#e41a1c")) +
  labs(x = "IDI2-AS1", y = "Eosinophil signature (mean z)") +
  theme_bbrc

ggsave("results/figures/Fig4B_eosinophil_signature.pdf",
       p2, width = 9, height = 3.3)
cat("Saved Fig4B_eosinophil_signature.pdf\n")

p_th2 <- ggplot(th2_df, aes(idi2as1, score, color = group)) +
  geom_point(alpha = 0.5, size = 1.2) +
  geom_smooth(method = "lm", se = TRUE, color = "black", linewidth = 0.5) +
  facet_wrap(~ paste(disease, dataset, sep = "\n"), scales = "free", ncol = 5) +
  scale_color_manual(values = c(control = "#377eb8", patient = "#e41a1c")) +
  labs(x = "IDI2-AS1", y = "Th2 / type-2 signature (mean z)",
       title = "IDI2-AS1 vs Th2 / type-2 signature (per cohort)") +
  theme_bbrc

ggsave("results/figures/SuppFig1_th2_signature.pdf",
       p_th2, width = 9, height = 3.5)
cat("Saved SuppFig1_th2_signature.pdf (Th2 row moved from main Fig 4)\n")
