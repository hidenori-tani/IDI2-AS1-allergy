#' Resolve a set of gene symbols / Ensembl IDs to row indices of a matrix
#'
#' Tries the symbol, then an optional Ensembl alias, against both the raw
#' rownames and their version-stripped form. Returns the first matching row per
#' query gene.
#'
#' @param rn rownames of the expression matrix.
#' @param genes character vector of gene symbols (or IDs) to resolve.
#' @param ensg_map optional named character vector symbol -> ENSG alias.
#' @return integer vector of matched row indices (unique, order of `genes`).
#' @export
resolve_genes <- function(rn, genes, ensg_map = NULL) {
  rn_stripped <- strip_ens_version(rn)
  out <- integer(0)
  for (s in genes) {
    cand <- s
    if (!is.null(ensg_map) && !is.na(ensg_map[s])) cand <- c(cand, ensg_map[[s]])
    hit <- which(rn %in% cand | rn_stripped %in% cand)
    if (length(hit)) out <- c(out, hit[1])
  }
  unique(out)
}

#' Marker-signature score (mean within-dataset z-score)
#'
#' For each marker gene, expression is standardised across the samples of the
#' single dataset (z-score); the per-sample signature score is the mean z across
#' the available markers. This is a within-cohort relative-abundance index, not
#' an absolute fraction.
#'
#' @param expr_mat gene x sample matrix on a log / variance-stabilised scale.
#' @param idx integer row indices of the marker genes (see [resolve_genes()]).
#' @return numeric vector of per-sample signature scores (NA if no markers).
#' @export
score_signature <- function(expr_mat, idx) {
  if (length(idx) == 0) return(rep(NA_real_, ncol(expr_mat)))
  sub <- expr_mat[idx, , drop = FALSE]
  z   <- t(scale(t(sub)))
  z[is.na(z)] <- 0
  colMeans(z, na.rm = TRUE)
}
