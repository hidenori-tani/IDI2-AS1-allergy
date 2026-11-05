#' Read a bulkmask YAML configuration
#' @param path path to a YAML config (see inst/config/idi2as1_il5.yml).
#' @return a named list.
#' @export
read_config <- function(path) {
  cfg <- yaml::read_yaml(path)
  if (is.null(cfg$bootstrap$R)) cfg$bootstrap$R <- 10000L
  if (is.null(cfg$deconvolution$input_normalization))
    cfg$deconvolution$input_normalization <- "tpm"
  check_ensembl_aliases(cfg)
  cfg
}

#' Stop if an Ensembl-keyed cohort would lose signature genes or read the wrong gene
#'
#' Signature genes are given as symbols; in an Ensembl-keyed matrix a gene
#' resolves only through `ensembl_aliases`. A gene without an alias is silently
#' dropped there, and a signature with no alias at all becomes NA for the whole
#' cohort (GSE136825, th2 and neutrophil, until 2026-11-05).
#'
#' A hand-typed ID can also name another gene: until 2026-11-05 the EPX alias
#' was the ID of CD80 and `exposure_ensembl` an ID absent from the map. So when
#' `ens2sym_file` is given, every alias and `exposure_ensembl`/`outcome_ensembl`
#' must be in it under the same symbol. The path is read relative to the
#' working directory; a named file that is not found stops too, because the
#' check (and the symbol mapping for xCell and GSVA) would otherwise be skipped
#' without notice. All checks apply only when an Ensembl-keyed cohort is
#' configured.
#' @param cfg a bulkmask config.
#' @return `cfg`, invisibly; stops naming the missing or mismatched genes.
#' @export
check_ensembl_aliases <- function(cfg) {
  ens <- vapply(cfg$cohorts %||% list(), function(co) identical(co$id_type, "ensembl"), logical(1))
  if (!any(ens)) return(invisible(cfg))
  genes   <- unique(unlist(cfg$signatures))
  missing <- setdiff(genes, names(cfg$ensembl_aliases))
  if (length(missing))
    stop("ensembl_aliases lacks signature genes needed by Ensembl-keyed cohorts: ",
         paste(missing, collapse = ", "), call. = FALSE)
  if (!is.null(cfg$ens2sym_file) && !file.exists(cfg$ens2sym_file))
    stop("ens2sym_file not found: ", cfg$ens2sym_file, " (read relative to the working directory ",
         getwd(), ")", call. = FALSE)
  if (!is.null(cfg$ens2sym_file)) {
    ids <- unlist(cfg$ensembl_aliases)
    if (!is.null(cfg$exposure_ensembl)) ids[cfg$exposure] <- cfg$exposure_ensembl
    if (!is.null(cfg$outcome_ensembl))  ids[cfg$outcome]  <- cfg$outcome_ensembl
    map <- utils::read.csv(cfg$ens2sym_file, stringsAsFactors = FALSE)
    sym <- stats::setNames(map$symbol, map$ensembl)[strip_ens_version(unname(ids))]
    bad <- is.na(sym) | sym != names(ids)
    if (any(bad))
      stop("Ensembl IDs that ", cfg$ens2sym_file, " does not give the configured symbol: ",
           paste0(names(ids)[bad], " = ", ids[bad], " (", ifelse(is.na(sym[bad]), "absent", sym[bad]), ")",
                  collapse = ", "), call. = FALSE)
  }
  invisible(cfg)
}

#' Build the per-sample analysis table for one cohort
#'
#' Produces the exposure/outcome values plus every cell-composition estimate
#' (marker z-score, xCell raw enrichment, xCell compensated, GSVA ssGSEA) for
#' the mediator signature, and marker scores for the other configured
#' signatures (e.g. Th2, a negative-control compartment), under the chosen
#' deconvolution input normalisation (tpm / deseq2 / fpkm).
#'
#' @param se a SummarizedExperiment with assay "counts" or FPKM, colData$group.
#' @param config a bulkmask config (see [read_config()]).
#' @param id_type "symbol" or "ensembl" for this cohort's rownames.
#' @return data.frame with one row per sample.
#' @export
prepare_cohort <- function(se, config, id_type = "symbol") {
  is_counts <- "counts" %in% names(SummarizedExperiment::assays(se))
  ensg_map  <- unlist(config$ensembl_aliases)

  # ---- (a) log / vst matrix for exposure, outcome, marker z-scores ----
  if (is_counts) {
    dds  <- DESeq2::DESeqDataSetFromMatrix(
      round(SummarizedExperiment::assay(se, "counts")),
      data.frame(group = SummarizedExperiment::colData(se)$group),
      design = ~ group)
    dds  <- dds[rowSums(DESeq2::counts(dds)) >= 10, ]
    mmat <- SummarizedExperiment::assay(DESeq2::vst(dds, blind = TRUE))
    lin  <- DESeq2::counts(DESeq2::estimateSizeFactors(dds), normalized = TRUE)
    raw  <- DESeq2::counts(dds)
  } else {
    fpkm <- SummarizedExperiment::assay(se)
    fpkm <- fpkm[rowSums(fpkm) > 0, , drop = FALSE]
    mmat <- log2(fpkm + 1); lin <- fpkm; raw <- fpkm
  }

  # ---- (b) deconvolution input under the requested normalisation ----
  norm <- config$deconvolution$input_normalization
  if (is_counts && norm == "tpm") {
    gl  <- tryCatch(gene_lengths_ensdb(rownames(raw), id_type),
                    error = function(e) NULL)
    decon_in <- if (!is.null(gl) && length(gl) > 100) counts_to_tpm(raw, gl) else lin
    used_norm <- if (!is.null(gl) && length(gl) > 100) "tpm" else "deseq2(fallback)"
  } else {
    decon_in <- lin; used_norm <- if (is_counts) "deseq2" else "fpkm"
  }
  # xCell wants HGNC symbols; map Ensembl-keyed matrices if a map is provided.
  if (id_type == "ensembl" && !is.null(config$ens2sym_file) &&
      file.exists(config$ens2sym_file)) {
    decon_in <- .map_rows_to_symbol(decon_in, config$ens2sym_file)
    mmat_x   <- .map_rows_to_symbol(2^mmat - 1, config$ens2sym_file)  # for GSVA symbols
    mmat_for_gsva <- log2(mmat_x + 1)
  } else {
    mmat_for_gsva <- mmat
  }

  i_exp <- resolve_genes(rownames(mmat), c(config$exposure, config$exposure_ensembl), ensg_map)
  i_out <- resolve_genes(rownames(mmat), c(config$outcome,  config$outcome_ensembl),  ensg_map)
  if (!length(i_exp) || !length(i_out)) return(NULL)

  med_sig  <- config$mediator_signature
  df <- data.frame(
    sample_id = colnames(mmat),
    group     = as.character(SummarizedExperiment::colData(se)$group),
    exposure  = as.numeric(mmat[i_exp[1], ]),
    outcome   = as.numeric(mmat[i_out[1], ]),
    dataset   = config$.cohort_id %||% NA_character_,
    stringsAsFactors = FALSE)
  df$group_bin <- as.integer(df$group != "control")

  # marker z-scores for every configured signature
  for (sig in names(config$signatures)) {
    idx <- resolve_genes(rownames(mmat), config$signatures[[sig]], ensg_map)
    df[[paste0("sig_", sig)]] <- score_signature(mmat, idx)
  }
  # mediator signature: xCell (raw and compensated) and ssGSEA of the same markers;
  # all expression-derived, so not independent of the marker score
  df$eos_xcell_raw  <- as.numeric(estimate_xcell(decon_in,
                          config$deconvolution$xcell_cell_type, raw = TRUE)[df$sample_id])
  df$eos_xcell_comp <- as.numeric(estimate_xcell(decon_in,
                          config$deconvolution$xcell_cell_type, raw = FALSE)[df$sample_id])
  df$eos_gsva       <- estimate_gsva_ssgsea(mmat_for_gsva,
                          config$signatures[[med_sig]], set_name = med_sig)
  attr(df, "deconv_norm") <- used_norm
  df
}

#' Analyse one prepared cohort: partial correlations + decompositions
#'
#' Runs the raw association, partial correlations conditioning on each
#' composition estimate (and, when configured, additionally on case/control
#' status and on the Th2 compartment), and the bootstrap decomposition under
#' the marker, xCell-raw, and GSVA mediators — with and without the
#' case/control covariate. The Th2 model and the negative-control model run only
#' for signatures named exactly `th2` and `neutrophil`.
#'
#' @param df output of [prepare_cohort()].
#' @param config a bulkmask config.
#' @return list(correlations = data.frame, decompositions = data.frame).
#' @export
analyse_cohort <- function(df, config) {
  med <- config$mediator_signature
  est <- list(marker   = df[[paste0("sig_", med)]],
              xcellraw = df$eos_xcell_raw,
              gsva     = df$eos_gsva)
  group_cov <- isTRUE(config$adjust_for_group)
  R <- as.integer(config$bootstrap$R)

  # partial_corr() silently drops a conditioner with zero variance or all NA.
  # Record the conditioners actually used in `conditioners_used`; otherwise an
  # unconditioned value would be written under an `adj_...` label. This happened
  # once: in the Ensembl-keyed GSE136825 none of the Th2 or neutrophil marker genes
  # resolved, and the `adj_neutrophil(neg.ctrl)` row repeated the raw correlation.
  cor_row <- function(model, a) data.frame(
    model = model, rho = a$rho, p = a$p, n = a$n,
    conditioners_used = if (length(a$conditioners)) paste(a$conditioners, collapse = "+") else "")

  cors <- list()
  raw  <- partial_corr(df$exposure, df$outcome)
  cors[["raw"]] <- cor_row("raw", raw)
  for (nm in names(est)) {
    a <- partial_corr(df$exposure, df$outcome, list(eos = est[[nm]]))
    cors[[paste0("adj_", nm)]] <- cor_row(paste0("adj_", nm), a)
  }
  # + case/control, + Th2 (if present)
  if (group_cov) {
    a <- partial_corr(df$exposure, df$outcome, list(eos = est$marker, grp = df$group_bin))
    cors[["adj_marker_group"]] <- cor_row("adj_marker+group", a)
  }
  if (!is.null(df$sig_th2)) {
    a <- partial_corr(df$exposure, df$outcome, list(eos = est$marker, th2 = df$sig_th2))
    cors[["adj_marker_th2"]] <- cor_row("adj_marker+th2", a)
  }
  if (!is.null(df$sig_neutrophil)) {                    # negative control
    a <- partial_corr(df$exposure, df$outcome, list(neu = df$sig_neutrophil))
    cors[["adj_neutrophil"]] <- cor_row("adj_neutrophil(neg.ctrl)", a)
  }
  cor_tbl <- do.call(rbind, cors); cor_tbl$dataset <- df$dataset[1]; rownames(cor_tbl) <- NULL

  decs <- list()
  for (nm in names(est)) {
    dd <- data.frame(exposure = df$exposure, outcome = df$outcome, med = est[[nm]],
                     group_bin = df$group_bin)
    d0 <- decompose_association(dd, "exposure", "med", "outcome", R = R)
    if (!is.null(d0)) { d0$estimator <- nm; d0$adjusted <- "none"; decs[[paste0(nm, "_0")]] <- d0 }
    if (group_cov) {
      d1 <- decompose_association(dd, "exposure", "med", "outcome",
                                  covariates = "group_bin", R = R)
      if (!is.null(d1)) { d1$estimator <- nm; d1$adjusted <- "group"; decs[[paste0(nm, "_g")]] <- d1 }
    }
  }
  dec_tbl <- if (length(decs)) { x <- do.call(rbind, decs); x$dataset <- df$dataset[1]; rownames(x) <- NULL; x } else NULL
  list(correlations = cor_tbl, decompositions = dec_tbl)
}

`%||%` <- function(a, b) if (is.null(a)) b else a

.map_rows_to_symbol <- function(mat, ens2sym_file) {
  map <- utils::read.csv(ens2sym_file, stringsAsFactors = FALSE)
  sym <- stats::setNames(map$symbol, map$ensembl)[strip_ens_version(rownames(mat))]
  keep <- !is.na(sym) & sym != ""
  mat <- mat[keep, , drop = FALSE]
  rowsum(mat, group = sym[keep])
}
