#' Union-exon gene lengths from EnsDb.Hsapiens.v86
#'
#' Returns the union-exon length (sum of widths of the reduced exons of a gene),
#' which is the standard denominator for TPM, for the requested identifiers.
#' Identifiers may be HGNC symbols or Ensembl gene IDs (with or without a
#' version suffix).
#'
#' @param ids character vector of gene identifiers.
#' @param id_type "symbol" or "ensembl".
#' @return named numeric vector of lengths (bp), names = input ids that resolved.
#' @export
gene_lengths_ensdb <- function(ids, id_type = c("symbol", "ensembl")) {
  id_type <- match.arg(id_type)
  edb <- EnsDb.Hsapiens.v86::EnsDb.Hsapiens.v86
  # Union-exon length per gene_id (sum of widths of non-overlapping exons).
  glen <- ensembldb::lengthOf(edb, of = "gene")          # named by ENSG id
  g    <- ensembldb::genes(edb, columns = c("gene_id", "gene_name"))
  gid  <- g$gene_id
  gname <- g$gene_name

  if (id_type == "ensembl") {
    key <- strip_ens_version(ids)
    out <- glen[key]
    names(out) <- ids
  } else {
    # map symbol -> gene_id (first match), then to length
    sym2id <- stats::setNames(gid, gname)
    key <- sym2id[ids]
    out <- glen[key]
    names(out) <- ids
  }
  out[!is.na(out)]
}

#' Counts-per-million (no length normalisation)
#' @param counts gene x sample numeric matrix of raw counts.
#' @return CPM matrix.
#' @export
counts_to_cpm <- function(counts) {
  lib <- colSums(counts)
  sweep(counts, 2, lib, "/") * 1e6
}

#' Transcripts-per-million from raw counts and gene lengths
#'
#' TPM divides each gene's count by its length (rate), then scales each sample's
#' rates to sum to 1e6. Genes without a known length are dropped.
#'
#' @param counts gene x sample numeric matrix of raw counts (rownames = ids).
#' @param gene_lengths named numeric vector of lengths (bp); names match rownames.
#' @return TPM matrix restricted to genes with a known length.
#' @export
counts_to_tpm <- function(counts, gene_lengths) {
  common <- intersect(rownames(counts), names(gene_lengths))
  if (length(common) < 2)
    stop("counts_to_tpm: fewer than 2 genes have a known length")
  counts <- counts[common, , drop = FALSE]
  len_kb <- gene_lengths[common] / 1000
  rate   <- counts / len_kb                      # reads per kb
  scale  <- colSums(rate)
  sweep(rate, 2, scale, "/") * 1e6
}

#' Strip an Ensembl version suffix (ENSG00000123456.7 -> ENSG00000123456)
#' @param x character vector.
#' @export
strip_ens_version <- function(x) sub("\\.\\d+$", "", x)
