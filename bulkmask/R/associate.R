#' Spearman correlation, optionally partial on one or more conditioners
#'
#' With no conditioners this is an ordinary Spearman correlation; with one or
#' more it is a Spearman partial correlation (ppcor) conditioning on all of
#' them simultaneously. Conditioners with zero variance or all-NA are dropped.
#'
#' @param x,y numeric vectors.
#' @param conditioners named list of numeric covariate vectors (may be empty).
#' @return list(rho, p, n, conditioners = names actually used).
#' @export
partial_corr <- function(x, y, conditioners = list()) {
  ok <- stats::complete.cases(x, y)
  used <- character(0)
  if (length(conditioners)) {
    keep <- vapply(conditioners, function(z)
      !all(is.na(z)) && stats::sd(z, na.rm = TRUE) > 0, logical(1))
    conditioners <- conditioners[keep]
    used <- names(conditioners)
    for (z in conditioners) ok <- ok & !is.na(z)
  }
  x <- x[ok]; y <- y[ok]
  if (length(conditioners) == 0) {
    ct <- suppressWarnings(stats::cor.test(x, y, method = "spearman"))
    return(list(rho = unname(ct$estimate), p = ct$p.value, n = length(x),
                conditioners = character(0)))
  }
  Z <- as.data.frame(lapply(conditioners, function(z) z[ok]))
  pp <- ppcor::pcor.test(x, y, Z, method = "spearman")
  list(rho = pp$estimate, p = pp$p.value, n = length(x), conditioners = used)
}

#' Bootstrap decomposition of a bulk association into composition + residual
#'
#' Decomposes the exposure->outcome association into the part flowing through a
#' composition (mediator) estimate and a residual ("direct") part, via a linear
#' two-model bootstrap (mediation::mediate). Optional nuisance covariates
#' (e.g. case/control status) are included in BOTH models and the effects are
#' evaluated at `covariate_values`.
#'
#' Reported as a STATISTICAL PARTITION under a linear model on cross-sectional
#' data, not a counterfactual causal effect.
#'
#' @param d data.frame with the named columns below.
#' @param exposure,mediator,outcome column names in `d`.
#' @param covariates character vector of additional covariate columns in `d`.
#' @param covariate_values named list of values at which to evaluate effects
#'   (defaults to 0 for each covariate, e.g. the control baseline).
#' @param R bootstrap resamples (default 10000).
#' @param seed integer RNG seed.
#' @return one-row data.frame of ACME/ADE/total/prop with percentile CIs, or NULL.
#' @export
decompose_association <- function(d, exposure, mediator, outcome,
                                  covariates = character(0),
                                  covariate_values = NULL,
                                  R = 10000, seed = 42) {
  if (stats::sd(d[[mediator]], na.rm = TRUE) == 0 || nrow(d) < 20) return(NULL)
  set.seed(seed)
  dd <- data.frame(.x = d[[exposure]], .m = d[[mediator]], .y = d[[outcome]])
  cov_terms <- ""
  if (length(covariates)) {
    for (cv in covariates) dd[[cv]] <- d[[cv]]
    cov_terms <- paste0(" + ", paste(covariates, collapse = " + "))
  }
  # mediate(boot=TRUE) re-evaluates each model's stored call on resampled data.
  # A call holding a formula *variable* (m_form) fails on re-eval ("object not
  # found"); bquote() splices the formula OBJECT in literally so the stored call
  # is self-contained. Safe metaprogramming: the formula template is fixed and
  # the only interpolated tokens are internal covariate column names (not
  # user-supplied code).
  m_form <- stats::as.formula(paste0(".m ~ .x", cov_terms))
  o_form <- stats::as.formula(paste0(".y ~ .x + .m", cov_terms))
  m_model <- eval(bquote(stats::lm(.(m_form), data = dd)))
  o_model <- eval(bquote(stats::lm(.(o_form), data = dd)))
  if (is.null(covariate_values) && length(covariates))
    covariate_values <- stats::setNames(as.list(rep(0, length(covariates))), covariates)
  med <- tryCatch(
    mediation::mediate(m_model, o_model, treat = ".x", mediator = ".m",
                       covariates = covariate_values,
                       sims = R, boot = TRUE, boot.ci.type = "perc"),
    error = function(e) { message("  decompose FAILED: ", conditionMessage(e)); NULL })
  if (is.null(med)) return(NULL)
  data.frame(
    mediator = mediator, n = nrow(dd), R = R,
    covariates = paste(covariates, collapse = "+"),
    ACME = med$d.avg, ACME_lo = med$d.avg.ci[1], ACME_hi = med$d.avg.ci[2], ACME_p = med$d.avg.p,
    ADE  = med$z.avg, ADE_lo  = med$z.avg.ci[1], ADE_hi  = med$z.avg.ci[2], ADE_p  = med$z.avg.p,
    total_effect = med$tau.coef, total_p = med$tau.p,
    prop_mediated = med$n.avg,
    stringsAsFactors = FALSE)
}

#' Random-effects (REML) meta-analysis of per-cohort log2 fold-changes
#' @param lfc numeric per-cohort log2 fold-changes.
#' @param se numeric per-cohort standard errors.
#' @return list(pooled, ci_lo, ci_hi, p, I2, Q_p, k).
#' @export
run_meta <- function(lfc, se) {
  ok <- is.finite(lfc) & is.finite(se) & se > 0
  lfc <- lfc[ok]; se <- se[ok]
  if (length(lfc) < 2) stop("run_meta: need >= 2 cohorts")
  m <- metafor::rma(yi = lfc, sei = se, method = "REML")
  list(pooled = as.numeric(m$beta), ci_lo = m$ci.lb, ci_hi = m$ci.ub,
       p = m$pval, I2 = m$I2, Q_p = m$QEp, k = m$k)
}
