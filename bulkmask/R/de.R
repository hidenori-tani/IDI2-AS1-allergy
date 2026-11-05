#' Uniform per-cohort differential expression for a focal gene panel
#'
#' Count matrices are analysed with DESeq2 (Wald, BH FDR) and effect sizes are
#' shrunk with apeglm; FPKM matrices are analysed with limma-trend on
#' log2(FPKM + 1). Returns the log2 fold change, an `SE` column and the
#' adjusted p value for the focal genes only. For counts `SE` is the apeglm
#' posterior SD, not a sampling standard error, so do not pool it with
#' [run_meta()]; for FPKM it is the moderated limma standard error (logFC / t).
#'
#' @param expr gene x sample matrix (raw counts or FPKM).
#' @param group factor / character of length ncol(expr); reference = "control".
#' @param focal character vector of focal gene rownames to report.
#' @param type "counts" or "fpkm".
#' @param min_count DESeq2 pre-filter (default total count >= 10).
#' @return data.frame(gene, log2FC, SE, padj) for the focal genes present
#'   (`SE` as described above).
#' @export
run_de <- function(expr, group, focal, type = c("counts", "fpkm"), min_count = 10) {
  type  <- match.arg(type)
  group <- factor(group)
  if (!"control" %in% levels(group))
    stop("run_de: 'group' must contain a 'control' reference level")
  group <- stats::relevel(group, ref = "control")

  if (type == "counts") {
    cd <- data.frame(group = group); rownames(cd) <- colnames(expr)
    dds <- DESeq2::DESeqDataSetFromMatrix(round(as.matrix(expr)), cd, design = ~ group)
    dds <- dds[rowSums(DESeq2::counts(dds)) >= min_count, ]
    dds <- DESeq2::DESeq(dds, quiet = TRUE)
    coef <- utils::tail(DESeq2::resultsNames(dds), 1)
    res  <- as.data.frame(DESeq2::lfcShrink(dds, coef = coef, type = "apeglm", quiet = TRUE))
    out  <- data.frame(gene = rownames(res), log2FC = res$log2FoldChange,
                       SE = res$lfcSE, padj = res$padj, stringsAsFactors = FALSE)
  } else {
    logf <- log2(as.matrix(expr) + 1)
    logf <- logf[rowSums(logf) > 0, , drop = FALSE]
    design <- stats::model.matrix(~ group)
    fit <- limma::eBayes(limma::lmFit(logf, design), trend = TRUE)
    tt  <- limma::topTable(fit, coef = 2, number = Inf, sort.by = "none")
    out <- data.frame(gene = rownames(tt), log2FC = tt$logFC,
                      SE = tt$logFC / tt$t, padj = tt$adj.P.Val, stringsAsFactors = FALSE)
  }
  out[out$gene %in% focal, , drop = FALSE]
}
