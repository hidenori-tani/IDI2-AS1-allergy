# ============================================================
# Fig 5 — Specificity heatmaps: lncRNA panel + cytokine panel
# v2: BBRC font-size revision (editor letter BBRC-26-2497, M. Lichten)
#
# Changes vs v1:
#   - cell-value text fontsize 8 → 11
#   - column_title 11 → 13
#   - row_names / column_names explicit 12pt (was implicit default ~10)
#   - PDF height bumped so labels never collide with cells
# ============================================================

suppressPackageStartupMessages({
  library(ComplexHeatmap)
  library(circlize)
  library(dplyr)
  library(tidyr)
  library(tibble)
  library(readr)
})

source("code/R/loaders/common.R")

dir.create("results/figures", recursive = TRUE, showWarnings = FALSE)

LNCRNAS   <- c("IDI2-AS1", "MIR22HG", "GABPB1-AS1", "OIP5-AS1", "LITATS1")
CYTOKINES <- c("IL5", "IL4", "IL13", "IL6", "TNF", "IFNG")

all <- read_csv("results/tables/ALL_focal_genes_deg.csv", show_col_types = FALSE)

sym_map <- c(
  "ENSG00000260196" = "IDI2-AS1",
  "ENSG00000113525" = "IL5"
)
all <- all %>%
  mutate(gene = ifelse(gene %in% names(sym_map), sym_map[gene], gene))

datasets_meta <- read_csv("data/metadata/final_datasets.csv", show_col_types = FALSE)

build_matrix <- function(panel) {
  wide <- all %>%
    filter(gene %in% panel) %>%
    select(gene, dataset, log2FC) %>%
    group_by(gene, dataset) %>%
    summarize(log2FC = mean(log2FC, na.rm = TRUE), .groups = "drop") %>%
    pivot_wider(names_from = dataset, values_from = log2FC) %>%
    column_to_rownames("gene") %>%
    as.matrix()
  anchor <- panel[1]
  ord <- c(anchor, setdiff(panel, anchor))
  ord <- ord[ord %in% rownames(wide)]
  wide[ord, , drop = FALSE]
}

draw_heatmap <- function(mat, title, out_pdf) {
  col_order <- order(datasets_meta$disease[match(colnames(mat), datasets_meta$gse_id)])
  mat <- mat[, col_order, drop = FALSE]

  meta_for_cols <- datasets_meta[match(colnames(mat), datasets_meta$gse_id), ]
  disease_anno <- HeatmapAnnotation(
    disease = meta_for_cols$disease,
    n_total = anno_text(paste0("n=", meta_for_cols$n_patient + meta_for_cols$n_control),
                        rot = 0, just = "center",
                        gp = gpar(fontsize = 12)),
    col = list(disease = setNames(
      RColorBrewer::brewer.pal(max(3, length(unique(meta_for_cols$disease))),
                                "Set2")[seq_along(unique(meta_for_cols$disease))],
      unique(meta_for_cols$disease))),
    annotation_name_gp = gpar(fontsize = 12),
    annotation_legend_param = list(
      disease = list(title_gp = gpar(fontsize = 12, fontface = "bold"),
                     labels_gp = gpar(fontsize = 11))
    )
  )

  rng <- max(abs(mat), na.rm = TRUE)
  rng <- min(max(rng, 1), 4)
  col_fun <- colorRamp2(c(-rng, 0, rng), c("#3b82f6", "white", "#dc2626"))

  pdf(out_pdf, width = 9, height = max(3.0, 0.6 * nrow(mat) + 2.5))
  draw(Heatmap(
    mat,
    name = "log2FC\n(P vs C)",
    col = col_fun,
    top_annotation = disease_anno,
    cluster_rows = FALSE,
    cluster_columns = FALSE,
    show_row_names = TRUE,
    show_column_names = TRUE,
    column_title = title,
    column_title_gp = gpar(fontsize = 13, fontface = "bold"),
    row_names_gp = gpar(fontsize = 12),
    column_names_gp = gpar(fontsize = 12),
    heatmap_legend_param = list(
      title_gp = gpar(fontsize = 12, fontface = "bold"),
      labels_gp = gpar(fontsize = 11)
    ),
    cell_fun = function(j, i, x, y, width, height, fill) {
      v <- mat[i, j]
      if (!is.na(v))
        grid.text(sprintf("%.2f", v), x, y, gp = gpar(fontsize = 11))
    }
  ), padding = unit(c(2, 12, 2, 12), "mm"))
  dev.off()
}

lncrna_mat <- build_matrix(LNCRNAS)
cat("lncRNA panel: rows=", nrow(lncrna_mat), " cols=", ncol(lncrna_mat), "\n", sep = "")
print(round(lncrna_mat, 3))
draw_heatmap(lncrna_mat,
             "lncRNA panel: per-disease log2FC (patient vs control)",
             "results/figures/Fig5_lncrna_specificity_heatmap.pdf")

cyto_mat <- build_matrix(CYTOKINES)
cat("\ncytokine panel: rows=", nrow(cyto_mat), " cols=", ncol(cyto_mat), "\n", sep = "")
print(round(cyto_mat, 3))
draw_heatmap(cyto_mat,
             "Type-2 cytokine panel: per-disease log2FC (patient vs control)",
             "results/figures/Fig6_cytokine_specificity_heatmap.pdf")

cat("\nSaved Fig5 and Fig6 (v2: 9 in wide, fonts ≥11pt).\n")
