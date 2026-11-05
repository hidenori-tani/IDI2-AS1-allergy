#' xCell eosinophil (or any cell-type) abundance estimate
#'
#' Runs xCell on a linear-scale, symbol-keyed expression matrix and returns the
#' per-sample score for one cell type. For rare, spillover-prone cell types
#' (e.g. eosinophils in epithelial tissue) the default spillover-compensated
#' score can be floored to zero; `raw = TRUE` returns the raw ssGSEA enrichment
#' score instead, which retains a usable distribution.
#'
#' @param expr_linear gene x sample matrix, linear scale, HGNC-symbol rownames.
#' @param cell_type xCell cell-type label (default "Eosinophils").
#' @param raw logical; TRUE = raw ssGSEA enrichment, FALSE = compensated score.
#' @return named numeric vector of per-sample scores (NA if unavailable).
#' @export
estimate_xcell <- function(expr_linear, cell_type = "Eosinophils", raw = TRUE) {
  expr_linear <- as.matrix(expr_linear)
  if (raw) {
    enr <- tryCatch(
      xCell::rawEnrichmentAnalysis(expr_linear,
        signatures = xCell::xCell.data$signatures,
        genes = xCell::xCell.data$genes, parallel.sz = 1),
      error = function(e) NULL)
    if (is.null(enr) || !(cell_type %in% rownames(enr)))
      return(stats::setNames(rep(NA_real_, ncol(expr_linear)), colnames(expr_linear)))
    return(enr[cell_type, ])
  }
  xc <- tryCatch(xCell::xCellAnalysis(expr_linear, rnaseq = TRUE, parallel.sz = 1),
                 error = function(e) NULL)
  if (is.null(xc) || !(cell_type %in% rownames(xc)))
    return(stats::setNames(rep(NA_real_, ncol(expr_linear)), colnames(expr_linear)))
  xc[cell_type, ]
}

#' ssGSEA enrichment of a marker set (GSVA)
#'
#' A second summarization of the same marker set as an estimate of compartment abundance:
#' single-sample GSEA (ssGSEA) of the supplied marker set, computed by GSVA.
#' This differs from both the marker-mean z-score (no rank transform) and from
#' xCell (different signature, different normalisation), so concordance across
#' the three is informative about method dependence.
#'
#' @param expr_mat gene x sample matrix (log / vst scale), symbol rownames.
#' @param marker_genes character vector of marker symbols.
#' @param set_name name for the gene set.
#' @return named numeric vector of per-sample ssGSEA scores.
#' @export
estimate_gsva_ssgsea <- function(expr_mat, marker_genes, set_name = "signature") {
  expr_mat <- as.matrix(expr_mat)
  present  <- intersect(marker_genes, rownames(expr_mat))
  if (length(present) < 2)
    return(stats::setNames(rep(NA_real_, ncol(expr_mat)), colnames(expr_mat)))
  gs <- list(present); names(gs) <- set_name
  # GSVA >= 1.50 (Bioc 3.18+) uses parameter objects; older uses method=.
  res <- tryCatch({
    par <- GSVA::ssgseaParam(expr_mat, gs)
    GSVA::gsva(par)
  }, error = function(e) {
    tryCatch(GSVA::gsva(expr_mat, gs, method = "ssgsea", verbose = FALSE),
             error = function(e2) NULL)
  })
  if (is.null(res)) return(stats::setNames(rep(NA_real_, ncol(expr_mat)), colnames(expr_mat)))
  as.numeric(res[set_name, ])
}
