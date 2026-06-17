# ============================================================
# 14 — Sensitivity of the eosinophil decomposition to unmeasured
#      confounding (F&IG Reviewer 1, point 5)
#
# medsens (Imai et al.) varies rho = correlation between the residuals
# of the mediator and outcome models — i.e. the strength of an
# unmeasured mediator-outcome confounder — and reports the rho at which
# the composition-attributable component (ACME) would be driven to zero.
# Run for the asthma cohort under both the marker and the xCell-raw
# eosinophil estimate. medsens requires the quasi-Bayesian (boot=FALSE)
# mediate object.
# ============================================================

suppressPackageStartupMessages({
  library(mediation); library(readr); library(dplyr)
})

pts <- read_csv("results/intermediate/xcell_points.csv", show_col_types = FALSE) %>%
  filter(dataset == "GSE152004")

run_sens <- function(med_values, label) {
  d2 <- data.frame(idi2as1 = pts$idi2as1, il5 = pts$il5, med = med_values)
  set.seed(42)
  m_model <- lm(med ~ idi2as1, data = d2)
  o_model <- lm(il5 ~ idi2as1 + med, data = d2)
  med <- mediate(m_model, o_model, treat = "idi2as1", mediator = "med",
                 sims = 1000, boot = FALSE)
  s <- medsens(med, rho.by = 0.05, effect.type = "indirect")
  ss <- summary(s)
  # rho at which ACME = 0 (zero-crossing), and R2 interpretation
  rho_star <- s$err.cr.d            # rho where ACME crosses 0 (indirect)
  cat(sprintf("\n[%s] ACME = %.3f (p=%.3g); rho* (ACME=0) = %s\n",
              label, med$d.avg, med$d.avg.p,
              paste(sprintf("%.2f", rho_star), collapse = ", ")))
  data.frame(estimator = label, ACME = med$d.avg, ACME_p = med$d.avg.p,
             rho_star = rho_star[1],
             R2star_M_O = if (!is.null(s$R2star.prod)) NA else NA,
             stringsAsFactors = FALSE)
}

out <- bind_rows(
  run_sens(pts$eos_marker,    "marker_z"),
  run_sens(pts$eos_xcell_raw, "xCell_raw")
)
write_csv(out, "results/tables/Table_mediation_sensitivity.csv")
cat("\nSaved results/tables/Table_mediation_sensitivity.csv\n")
print(out, row.names = FALSE)
