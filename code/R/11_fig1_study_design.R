## Fig 1 — Study design schematic
## A4-landscape vector PDF, no external image dependencies.
## Device: macOS native quartz(type="pdf") for full Unicode + true sub/superscripts
## (no XQuartz / cairo dependency).
## Layout: 4 stages stacked top-to-bottom
##   Stage 1: 5 datasets (4 diseases, n = 856)
##   Stage 2: uniform pipeline (DESeq2/limma → meta → corr → mediation)
##   Stage 3: three analytical questions
##   Stage 4: principal finding (composition mediation ≈ 90 %)

suppressPackageStartupMessages({
  library(grid)
})

# ---- helper to draw a labeled box ----
# label may be a character string OR a plotmath/expression object
box_grob <- function(x, y, w, h, label, fill = "white", col = "black",
                     fontsize = 9, fontface = "plain", lwd = 1) {
  grobTree(
    rectGrob(x = x, y = y, width = w, height = h,
             gp = gpar(fill = fill, col = col, lwd = lwd)),
    textGrob(label, x = x, y = y,
             gp = gpar(fontsize = fontsize, fontface = fontface,
                       lineheight = 0.95))
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

# macOS-native vector PDF — full Unicode, no XQuartz, embedded fonts
quartz(type = "pdf", file = out_pdf, width = 11.69, height = 8.27)

grid.newpage()
pushViewport(viewport(x = 0.5, y = 0.5, width = 0.96, height = 0.94))

# ----- Title -----
grid.text("Cross-disease re-analysis of the IDI2-AS1 / IL5 axis in IL5-driven allergic disease",
          x = 0.5, y = 0.97,
          gp = gpar(fontsize = 14, fontface = "bold"))
grid.text("Five public bulk RNA-seq cohorts, 856 samples, uniform pipeline",
          x = 0.5, y = 0.935,
          gp = gpar(fontsize = 10, fontface = "italic", col = "grey30"))

# ----- Stage 1 — 5 dataset boxes -----
grid.text("STAGE 1 \u2014 Datasets",
          x = 0.07, y = 0.88, hjust = 0,
          gp = gpar(fontsize = 10, fontface = "bold", col = "steelblue4"))

ds <- list(
  list("Asthma\nGSE152004\nn = 695\nNasal epithelium",     "#D6EAF8"),
  list("Atopic dermatitis\nGSE121212\nn = 65\nSkin biopsy", "#FADBD8"),
  list("EoE\nGSE246323\nn = 10\nEsophagus",                 "#FCF3CF"),
  list("EoE\nGSE58640\nn = 16\nEsophagus",                  "#FCF3CF"),
  list("CRSwNP\nGSE136825\nn = 70\nNasal polyp",            "#D5F5E3")
)
xs <- seq(0.10, 0.90, length.out = 5)
for (i in seq_along(ds)) {
  grid.draw(box_grob(xs[i], 0.80, 0.16, 0.10,
                     label = ds[[i]][[1]],
                     fill = ds[[i]][[2]], fontsize = 8))
}

# ----- Single horizontal aggregator bar Stage 1 -> Stage 2 -----
# Avoids the messy 5-arrows-converging look of the previous version.
grid.lines(x = c(xs[1], xs[5]), y = c(0.745, 0.745),
           gp = gpar(lwd = 0.8, col = "grey40"))
for (i in seq_along(ds)) {
  grid.lines(x = c(xs[i], xs[i]), y = c(0.75, 0.745),
             gp = gpar(lwd = 0.8, col = "grey40"))
}
grid.draw(arrow_grob(0.5, 0.745, 0.5, 0.71, lwd = 0.9))

# ----- Stage 2 — pipeline -----
grid.text("STAGE 2 \u2014 Uniform pipeline",
          x = 0.07, y = 0.69, hjust = 0,
          gp = gpar(fontsize = 10, fontface = "bold", col = "steelblue4"))

# Use bquote/expression for the IDI2-AS1 ↔ IL5 cell so the arrow renders
# as a proper Unicode glyph (already U+2194 here; quartz embeds it).
pipe <- list(
  "DESeq2 + apeglm\n(raw counts)\n  /  limma-trend\n(FPKM)",
  "Random-effects\nmeta-analysis\n(metafor REML)",
  "Sample-level\nSpearman\nIDI2-AS1 \u2194 IL5",
  "Cell-type-adjusted\npartial correlation\n(eosinophil + Th2\nsignatures)",
  "Causal mediation\n(asthma cohort,\n1,000 bootstraps)"
)
xp <- seq(0.10, 0.90, length.out = 5)
for (i in seq_along(pipe)) {
  grid.draw(box_grob(xp[i], 0.61, 0.17, 0.10,
                     label = pipe[[i]], fill = "#EAF2F8", fontsize = 7.5))
  if (i < length(pipe)) {
    grid.draw(arrow_grob(xp[i] + 0.085, 0.61, xp[i + 1] - 0.085, 0.61, lwd = 0.8))
  }
}

# ----- Stage 3 — three questions -----
grid.text("STAGE 3 \u2014 Three in vivo questions",
          x = 0.07, y = 0.50, hjust = 0,
          gp = gpar(fontsize = 10, fontface = "bold", col = "steelblue4"))

q <- c(
  "Q1.\nIs IDI2-AS1 itself\ndifferentially\nexpressed in disease\ntissue?",
  "Q2.\nDo IDI2-AS1 and IL5\ncovary at the\nsample level\nin the predicted\n(negative) direction?",
  "Q3.\nIf the bulk signal\ndeparts from the\nin vitro prediction,\ncan it be ascribed to\ncell composition?"
)
xq <- c(0.20, 0.50, 0.80)
for (i in seq_along(q)) {
  grid.draw(box_grob(xq[i], 0.41, 0.22, 0.13,
                     label = q[i], fill = "#FDEBD0", fontsize = 8.5))
}
for (i in seq_along(xq)) {
  grid.draw(arrow_grob(xq[i], 0.345, xq[i], 0.275, lwd = 0.7))
}

# ----- Stage 4 — principal finding -----
grid.text("STAGE 4 \u2014 Principal finding",
          x = 0.07, y = 0.255, hjust = 0,
          gp = gpar(fontsize = 10, fontface = "bold", col = "steelblue4"))

# Use plotmath so log2 / I^2 / ≈ render as true sub-/super-scripts and the
# arrow → as a real glyph. paste()/atop() are needed for multi-line math.
finding_label <- bquote(atop(
  atop(
    atop(
      "Tissue-bulk " * italic("IDI2-AS1") * " expression is invariant in every cohort (pooled " * log[2] * "FC " %~~% " 0; " * italic(I)^2 * " = 0.26 %).",
      "Sample-level " * italic("IDI2-AS1") * " " * symbol("\xab") * " " * italic("IL5") * " covariation is POSITIVE \u2014 opposite to the in vitro repressive direction."
    ),
    atop(
      "Causal mediation in the asthma cohort attributes " %~~% " 90 % of the covariation to the eosinophil compartment",
      "(ACME = +0.109, " * italic(p) * " = 0.002), with a within-tissue direct effect indistinguishable from zero (ADE = +0.012, " * italic(p) * " = 0.76)."
    )
  ),
  atop(
    "  ",
    atop(
      "\u21d2  The published in vitro " * italic("IDI2-AS1") %->% italic("IL5") * " axis is MASKED, not contradicted, by bulk RNA-seq.",
      "\u21d2  Single-cell follow-up is the natural next step."
    )
  )
))

grid.draw(box_grob(0.5, 0.135, 0.86, 0.17,
                   label = finding_label,
                   fill = "#E8F8F5", col = "darkgreen", lwd = 1.5,
                   fontsize = 9, fontface = "plain"))

popViewport()
dev.off()

cat("Wrote", out_pdf, "\n")
