# Tests for bulkmask (base-R assertions; no testthat needed). Run them from the repository root:
#   Rscript --vanilla bulkmask/tests/test_bulkmask.R
# Section [8] reads bulkmask/inst/config/idi2as1_il5.yml and data/metadata/ensembl_to_symbol.csv; the other
# sections use synthetic data only.
suppressPackageStartupMessages({ library(mediation); library(metafor); library(ppcor) })
source("bulkmask/load_all.R")

pass <- 0L; fail <- 0L
check <- function(cond, msg) {
  if (isTRUE(cond)) { pass <<- pass + 1L; cat("  PASS:", msg, "\n") }
  else              { fail <<- fail + 1L; cat("  FAIL:", msg, "\n") }
}

cat("\n[1] strip_ens_version\n")
check(strip_ens_version("ENSG00000232656.7") == "ENSG00000232656", "version stripped")
check(strip_ens_version("ENSG00000232656")   == "ENSG00000232656", "bare id unchanged")

cat("\n[2] counts_to_tpm: columns sum to 1e6; length normalisation correct\n")
counts <- matrix(c(1000, 1000,    # g1
                    500,  2000,   # g2
                    500,  500,    # g3
                    200,  400),   # g4
                 nrow = 4, byrow = TRUE,
                 dimnames = list(c("g1","g2","g3","g4"), c("s1","s2")))
len <- c(g1 = 1000, g2 = 2000, g3 = 500, g4 = 4000)  # bp
tpm <- counts_to_tpm(counts, len)
check(all(abs(colSums(tpm) - 1e6) < 1e-6), "each sample sums to 1e6")
# g1 (1000 reads / 1kb) and g3 (500 reads / 0.5kb) have equal rate -> equal TPM
check(abs(tpm["g1","s1"] - tpm["g3","s1"]) < 1e-6, "equal rate -> equal TPM")

cat("\n[3] score_signature: mean within-dataset z-score\n")
m <- matrix(rnorm(20 * 6), nrow = 20, dimnames = list(paste0("g", 1:20), paste0("s", 1:6)))
sc <- score_signature(m, 1:5)
check(length(sc) == 6 && abs(mean(sc)) < 1e-6, "z-score signature centred across samples")
check(all(is.na(score_signature(m, integer(0)))), "no markers -> NA")

cat("\n[4] partial_corr: conditioning on the confounder removes the association\n")
set.seed(1)
comp <- rnorm(300)
x <- comp + rnorm(300, sd = 0.5)        # exposure co-expressed in compartment
y <- comp + rnorm(300, sd = 0.5)        # outcome co-expressed in compartment
raw <- partial_corr(x, y)
adj <- partial_corr(x, y, list(comp = comp))
check(raw$rho > 0.4 && raw$p < 1e-6, "raw association positive & significant")
check(abs(adj$rho) < 0.15, "conditioning on the compartment abolishes it")

cat("\n[5] decompose_association: most of the association flows through the mediator\n")
d <- data.frame(exposure = x, outcome = y, med = comp)
dec <- decompose_association(d, "exposure", "med", "outcome", R = 200, seed = 7)
check(!is.null(dec), "decomposition returns a result")
check(dec$prop_mediated > 0.6, "majority attributed to the mediator")
check(dec$ADE_p > 0.05, "residual (direct) component indistinguishable from zero")

cat("\n[6] decompose with a nuisance covariate runs\n")
d$group_bin <- as.integer(comp > 0)
decg <- decompose_association(d, "exposure", "med", "outcome",
                              covariates = "group_bin", R = 200, seed = 7)
check(!is.null(decg) && is.finite(decg$ACME), "covariate-adjusted decomposition runs")

cat("\n[7] run_meta: pooled estimate of a converging null\n")
mm <- run_meta(lfc = c(0.01, -0.02, 0.00, 0.015), se = c(0.05, 0.06, 0.04, 0.05))
check(abs(mm$pooled) < 0.05 && mm$p > 0.2, "near-zero pooled effect, non-significant")
check(mm$k == 4, "k counts contributing cohorts")

cat("\n[8] check_ensembl_aliases: every signature gene needs an alias for Ensembl-keyed cohorts\n")
cfg_ok  <- list(signatures = list(a = c("G1", "G2")), ensembl_aliases = list(G1 = "E1", G2 = "E2"),
                cohorts = list(list(id = "X", id_type = "ensembl")))
cfg_bad <- cfg_ok; cfg_bad$ensembl_aliases <- list(G1 = "E1")
cfg_sym <- cfg_bad; cfg_sym$cohorts <- list(list(id = "Y", id_type = "symbol"))
check(!inherits(try(check_ensembl_aliases(cfg_ok),  silent = TRUE), "try-error"), "complete aliases pass")
check( inherits(try(check_ensembl_aliases(cfg_bad), silent = TRUE), "try-error"), "missing alias stops (negative control)")
check(!inherits(try(check_ensembl_aliases(cfg_sym), silent = TRUE), "try-error"), "symbol-only cohorts need no aliases")
cfg_real <- try(read_config("bulkmask/inst/config/idi2as1_il5.yml"), silent = TRUE)
check(!inherits(cfg_real, "try-error"), "shipped config has an alias for every signature gene")
map_tmp <- tempfile(fileext = ".csv")
write.csv(data.frame(ensembl = c("E1", "E2", "E9"), symbol = c("G1", "G2", "OTHER")), map_tmp, row.names = FALSE)
cfg_map <- c(cfg_ok, list(ens2sym_file = map_tmp, exposure = "X1", exposure_ensembl = "E1.5"))
check( inherits(try(check_ensembl_aliases(cfg_map), silent = TRUE), "try-error"), "exposure ID of another gene stops (negative control)")
cfg_map$exposure <- "G1"
check(!inherits(try(check_ensembl_aliases(cfg_map), silent = TRUE), "try-error"), "IDs that the map confirms pass (version suffix ignored)")
cfg_map$ensembl_aliases$G2 <- "E9"
check( inherits(try(check_ensembl_aliases(cfg_map), silent = TRUE), "try-error"), "alias of another gene stops (negative control)")
cfg_map$ensembl_aliases$G2 <- "E7"
check( inherits(try(check_ensembl_aliases(cfg_map), silent = TRUE), "try-error"), "alias absent from the map stops (negative control)")
# Each negative control checks the reason for the stop: since a missing map also stops (2026-11-05), "some error"
# would pass even when the comparison never ran (run from the repository root, where the map is).
stops_for <- function(expr, why) {
  r <- try(expr, silent = TRUE)
  inherits(r, "try-error") && grepl(why, r, fixed = TRUE)
}
real_wrong <- yaml::read_yaml("bulkmask/inst/config/idi2as1_il5.yml")
real_wrong$ensembl_aliases$EPX <- paste0("ENSG", "00000121594")   # CD80; built from parts so the ID scans of the release do not read it as a pair
check(stops_for(check_ensembl_aliases(real_wrong), "does not give the configured symbol"), "the old EPX alias (CD80) stops (negative control)")
real_wrong <- yaml::read_yaml("bulkmask/inst/config/idi2as1_il5.yml")
real_wrong$exposure_ensembl <- "ENSG00000000000"   # absent from the map, as the old IDI2-AS1 ID was
check(stops_for(check_ensembl_aliases(real_wrong), "does not give the configured symbol"), "an exposure ID absent from the map stops (negative control)")
cfg_nomap <- c(cfg_ok, list(ens2sym_file = file.path(tempdir(), "no_such_map.csv")))
check(stops_for(check_ensembl_aliases(cfg_nomap), "ens2sym_file not found"), "a named map that is not found stops (negative control)")
unlink(map_tmp)

cat(sprintf("\n=== bulkmask tests: %d passed, %d failed ===\n", pass, fail))
if (fail > 0) quit(status = 1)
