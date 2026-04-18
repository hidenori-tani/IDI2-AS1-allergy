## Fig 1 — Study design schematic
## Single A4-landscape PDF, vector, no external image dependencies.
## Layout: 4 horizontal stages
##   Stage 1: 5 datasets (4 diseases, n=856)
##   Stage 2: uniform pipeline (DESeq2/limma → meta-analysis → correlation → mediation)
##   Stage 3: three analytical questions
##   Stage 4: principal finding (composition mediation 90%)

suppressPackageStartupMessages({
  library(ggplot2)
  library(grid)
})

# ---- helper to draw a labeled box ----
box_grob <- function(x, y, w, h, label, fill = "white", col = "black",
                     fontsize = 9, fontface = "plain", lwd = 1) {
  grobTree(
    rectGrob(x = x, y = y, width = w, height = h,
             gp = gpar(fill = fill, col = col, lwd = lwd)),
    textGrob(label, x = x, y = y,
             gp = gpar(fontsize = fontsize, fontface = fontface, lineheight = 0.95))
  )
}

# ---- helper to draw an arrow between two points ----
arrow_grob <- function(x0, y0, x1, y1, lwd = 1) {
  segmentsGrob(x0 = x0, y0 = y0, x1 = x1, y1 = y1,
               gp = gpar(lwd = lwd),
               arrow = arrow(type = "closed", length = unit(0.10, "inches")))
}

out_pdf <- "results/figures/Fig1_study_design.pdf"
dir.create(dirname(out_pdf), recursive = TRUE, showWarnings = FALSE)

cairo_pdf(out_pdf, width = 11.69, height = 8.27)   # A4 landscape — cairo for Unicode

grid.newpage()
pushViewport(viewport(x = 0.5, y = 0.5, width = 0.96, height = 0.94))

# ----- Title -----
grid.text("Cross-disease re-analysis of the IDI2-AS1 / IL5 axis in IL5-driven allergic disease",
          x = 0.5, y = 0.97,
          gp = gpar(fontsize = 14, fontface = "bold"))
grid.text("Five public bulk RNA-seq cohorts, 856 samples, uniform pipeline",
          x = 0.5, y = 0.935,
          gp = gpar(fontsize = 10, fontface = "italic", col = "grey30"))

# ----- Stage 1 — 5 datasets header -----
grid.text("STAGE 1 — Datasets",
          x = 0.07, y = 0.86, hjust = 0,
          gp = gpar(fontsize = 10, fontface = "bold", col = "steelblue4"))

# 5 dataset boxes in a row
ds <- list(
  list("Asthma\nGSE152004\nn = 695\nNasal epithelium",  "#D6EAF8"),
  list("Atopic dermatitis\nGSE121212\nn = 65\nSkin biopsy", "#FADBD8"),
  list("EoE\nGSE246323\nn = 10\nEsophagus", "#FCF3CF"),
  list("EoE\nGSE58640\nn = 16\nEsophagus", "#FCF3CF"),
  list("CRSwNP\nGSE136825\nn = 70\nNasal polyp", "#D5F5E3")
)
xs <- seq(0.10, 0.90, length.out = 5)
for (i in seq_along(ds)) {
  grid.draw(box_grob(xs[i], 0.78, 0.16, 0.10,
                     label = ds[[i]][[1]],
                     fill = ds[[i]][[2]], fontsize = 8))
}

# ----- Funnel down to Stage 2 -----
for (i in seq_along(ds)) {
  grid.draw(arrow_grob(xs[i], 0.73, 0.5, 0.66, lwd = 0.6))
}

# ----- Stage 2 — pipeline -----
grid.text("STAGE 2 — Uniform pipeline",
          x = 0.07, y = 0.66, hjust = 0,
          gp = gpar(fontsize = 10, fontface = "bold", col = "steelblue4"))

pipe <- c(
  "DESeq2 + apeglm\n(raw counts)\n  /  limma-trend\n(FPKM)",
  "Random-effects\nmeta-analysis\n(metafor REML)",
  "Sample-level\nSpearman\nIDI2-AS1 ↔ IL5",
  "Cell-type-adjusted\npartial correlation\n(eosinophil + Th2\nsignatures)",
  "Causal mediation\n(asthma cohort,\n1,000 bootstraps)"
)
xp <- seq(0.10, 0.90, length.out = 5)
for (i in seq_along(pipe)) {
  grid.draw(box_grob(xp[i], 0.58, 0.17, 0.10,
                     label = pipe[i], fill = "#EAF2F8", fontsize = 7.5))
  if (i < length(pipe)) {
    grid.draw(arrow_grob(xp[i] + 0.085, 0.58, xp[i + 1] - 0.085, 0.58, lwd = 0.8))
  }
}

# ----- Stage 3 — three questions -----
grid.text("STAGE 3 — Three in vivo questions",
          x = 0.07, y = 0.46, hjust = 0,
          gp = gpar(fontsize = 10, fontface = "bold", col = "steelblue4"))

q <- c(
  "Q1.\nIs IDI2-AS1 itself\ndifferentially\nexpressed in disease\ntissue?",
  "Q2.\nDo IDI2-AS1 and IL5\ncovary at the\nsample level\nin the predicted\n(negative) direction?",
  "Q3.\nIf the bulk signal\ndeparts from the\nin vitro prediction,\ncan it be ascribed to\ncell composition?"
)
xq <- c(0.20, 0.50, 0.80)
for (i in seq_along(q)) {
  grid.draw(box_grob(xq[i], 0.36, 0.22, 0.12,
                     label = q[i], fill = "#FDEBD0", fontsize = 8.5))
}
for (i in seq_along(xq)) {
  grid.draw(arrow_grob(xq[i], 0.30, xq[i], 0.23, lwd = 0.6))
}

# ----- Stage 4 — principal finding -----
grid.text("STAGE 4 — Principal finding",
          x = 0.07, y = 0.21, hjust = 0,
          gp = gpar(fontsize = 10, fontface = "bold", col = "steelblue4"))

grid.draw(box_grob(0.5, 0.13, 0.84, 0.16,
                   label = paste0(
                     "Tissue-bulk IDI2-AS1 expression is invariant in every cohort (pooled log2FC ~ 0; I^2 = 0.26%).\n",
                     "Sample-level IDI2-AS1 vs IL5 covariation is POSITIVE -- opposite to the in vitro repressive direction.\n",
                     "Causal mediation in the asthma cohort attributes ~90% of the covariation to the eosinophil compartment\n",
                     "(ACME = +0.109, p = 0.002), with a within-tissue direct effect indistinguishable from zero (ADE = +0.012, p = 0.76).\n\n",
                     "=> The published in vitro IDI2-AS1 -> IL5 axis is MASKED, not contradicted, by bulk RNA-seq.\n",
                     "=> Single-cell follow-up is the natural next step."),
                   fill = "#E8F8F5", col = "darkgreen", lwd = 1.5,
                   fontsize = 9, fontface = "plain"))

popViewport()
dev.off()

cat("Wrote", out_pdf, "\n")
