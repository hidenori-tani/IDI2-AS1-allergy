## Fig 1 - Study design schematic (v2: BBRC font-size revision)
## Editor letter BBRC-26-2497 (M. Lichten): fonts must be >= 6pt (>= 8pt preferred)
## After build_labeled_figures.py scales source canvas from 9in to 480pt (6.67in)
## the scale factor is 0.741; so source fonts >= 11pt yield final >= 8.15pt.
##
## Changes vs v1:
##  - quartz canvas 11.69x8.27 -> 9.00x7.20
##  - all fontsize values raised to >= 11pt
##  - box heights slightly increased to keep multi-line labels inside boxes
##  - Stage1 labels condensed to 3 lines (one combined "GSE / n / tissue" line)

suppressPackageStartupMessages({
  library(grid)
})

box_grob <- function(x, y, w, h, label, fill = "white", col = "black",
                     fontsize = 11, fontface = "plain", lwd = 1) {
  grobTree(
    rectGrob(x = x, y = y, width = w, height = h,
             gp = gpar(fill = fill, col = col, lwd = lwd)),
    textGrob(label, x = x, y = y,
             gp = gpar(fontsize = fontsize, fontface = fontface,
                       lineheight = 0.95))
  )
}

arrow_grob <- function(x0, y0, x1, y1, lwd = 1) {
  segmentsGrob(x0 = x0, y0 = y0, x1 = x1, y1 = y1,
               gp = gpar(lwd = lwd),
               arrow = arrow(type = "closed", length = unit(0.10, "inches")))
}

out_pdf <- "results/figures/Fig1_study_design.pdf"
dir.create(dirname(out_pdf), recursive = TRUE, showWarnings = FALSE)

quartz(type = "pdf", file = out_pdf, width = 9.00, height = 7.20)

grid.newpage()
pushViewport(viewport(x = 0.5, y = 0.5, width = 0.96, height = 0.94))

# ----- Title -----
grid.text("Cross-disease re-analysis of the IDI2-AS1 / IL5 axis in IL5-driven allergic disease",
          x = 0.5, y = 0.97,
          gp = gpar(fontsize = 14, fontface = "bold"))
grid.text("Five public bulk RNA-seq cohorts, 856 samples, uniform pipeline",
          x = 0.5, y = 0.935,
          gp = gpar(fontsize = 11, fontface = "italic", col = "grey30"))

# ----- Stage 1 - 5 dataset boxes (condensed labels, 3 lines each) -----
grid.text("STAGE 1 - Datasets",
          x = 0.07, y = 0.88, hjust = 0,
          gp = gpar(fontsize = 11, fontface = "bold", col = "steelblue4"))

ds <- list(
  list("Asthma\nGSE152004 (n=695)\nNasal epithelium",     "#D6EAF8"),
  list("Atopic dermatitis\nGSE121212 (n=65)\nSkin biopsy", "#FADBD8"),
  list("EoE\nGSE246323 (n=10)\nEsophagus",                 "#FCF3CF"),
  list("EoE\nGSE58640 (n=16)\nEsophagus",                  "#FCF3CF"),
  list("CRSwNP\nGSE136825 (n=70)\nPolyp vs IT control",    "#D5F5E3")
)
xs <- seq(0.10, 0.90, length.out = 5)
for (i in seq_along(ds)) {
  grid.draw(box_grob(xs[i], 0.80, 0.17, 0.11,
                     label = ds[[i]][[1]],
                     fill = ds[[i]][[2]], fontsize = 11))
}

grid.lines(x = c(xs[1], xs[5]), y = c(0.735, 0.735),
           gp = gpar(lwd = 0.8, col = "grey40"))
for (i in seq_along(ds)) {
  grid.lines(x = c(xs[i], xs[i]), y = c(0.745, 0.735),
             gp = gpar(lwd = 0.8, col = "grey40"))
}
grid.draw(arrow_grob(0.5, 0.735, 0.5, 0.695, lwd = 0.9))

# ----- Stage 2 - pipeline -----
grid.text("STAGE 2 - Uniform pipeline",
          x = 0.07, y = 0.675, hjust = 0,
          gp = gpar(fontsize = 11, fontface = "bold", col = "steelblue4"))

pipe <- list(
  "DESeq2 + apeglm\n(raw counts) /\nlimma-trend (FPKM)",
  "Random-effects\nmeta-analysis\n(metafor REML)",
  "Sample-level\nSpearman\nIDI2-AS1 vs IL5",
  "Cell-type-adjusted\npartial correlation\n(marker + xCell)",
  "Effect decomposition\n(asthma cohort,\n1,000 bootstraps)"
)
xp <- seq(0.10, 0.90, length.out = 5)
for (i in seq_along(pipe)) {
  grid.draw(box_grob(xp[i], 0.59, 0.17, 0.12,
                     label = pipe[[i]], fill = "#EAF2F8", fontsize = 11))
  if (i < length(pipe)) {
    grid.draw(arrow_grob(xp[i] + 0.085, 0.59, xp[i + 1] - 0.085, 0.59, lwd = 0.8))
  }
}

# ----- Stage 3 - three questions -----
grid.text("STAGE 3 - Three in vivo questions",
          x = 0.07, y = 0.47, hjust = 0,
          gp = gpar(fontsize = 11, fontface = "bold", col = "steelblue4"))

q <- c(
  "Q1.\nIs IDI2-AS1 itself\ndifferentially expressed\nin disease tissue?",
  "Q2.\nDo IDI2-AS1 and IL5\ncovary in the predicted\n(negative) direction?",
  "Q3.\nIf bulk signal departs\nfrom in vitro prediction,\nis it cell-composition?"
)
xq <- c(0.20, 0.50, 0.80)
for (i in seq_along(q)) {
  grid.draw(box_grob(xq[i], 0.385, 0.24, 0.13,
                     label = q[i], fill = "#FDEBD0", fontsize = 11))
}
for (i in seq_along(xq)) {
  grid.draw(arrow_grob(xq[i], 0.315, xq[i], 0.255, lwd = 0.7))
}

# ----- Stage 4 - principal finding -----
grid.text("STAGE 4 - Principal finding",
          x = 0.07, y = 0.235, hjust = 0,
          gp = gpar(fontsize = 11, fontface = "bold", col = "steelblue4"))

# Plain-text multi-line finding panel (avoids nested atop() which shrinks
# inner-line fontsize by 0.8^n at each nesting level and would push fonts
# below the BBRC 6pt minimum). Each line is drawn as a separate grid.text
# so the declared fontsize is honored everywhere.
# All glyphs are ASCII only: the default R pdf() device renders Unicode
# characters (e.g. log-sub-2, I-squared, double-arrow) as empty boxes
# (the cause of the empty-box glyphs flagged in F&IG review, Fig. 1), and
# cairo is unavailable in this environment, so ASCII is the robust fix.
finding_lines <- c(
  "Tissue-bulk IDI2-AS1 expression is invariant in every cohort (pooled log2FC ~ 0; I2 = 0.26%).",
  "Sample-level IDI2-AS1 vs IL5 covariation is POSITIVE - opposite to the in vitro repressive direction.",
  "Effect decomposition (asthma) attributes the majority of the covariation to eosinophils:",
  "~90% (marker) and ~70% (independent xCell), both p <= 0.006; within-tissue residual component ~ 0.",
  "=> Bulk RNA-seq is compatible with compositional masking of the proposed in vitro axis,",
  "=> not its refutation; single-cell follow-up is required (a hypothesis, not a validation)."
)

# Outer green box
grid.rect(x = 0.5, y = 0.115, width = 0.92, height = 0.20,
          gp = gpar(fill = "#E8F8F5", col = "darkgreen", lwd = 1.5))

# Stack lines vertically, all at the same 11pt fontsize.
n_lines <- length(finding_lines)
line_step <- 0.025  # ~ 0.18 in spacing at 7.2 in canvas - fits 6 lines in 0.20 box height
y_top <- 0.115 + 0.20/2 - line_step
for (k in seq_len(n_lines)) {
  grid.text(finding_lines[[k]],
            x = 0.5, y = y_top - (k - 1) * line_step,
            gp = gpar(fontsize = 11, fontface = "plain"))
}

popViewport()
dev.off()

cat("Wrote", out_pdf, "(v2: 9.0x7.2 in, fonts >=11pt)\n")
