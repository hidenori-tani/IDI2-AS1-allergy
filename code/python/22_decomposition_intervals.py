"""Intervals for the decomposition proportion, the medsens crossing point, and case/control rows
for all three eosinophil estimates (asthma, GSE152004, n = 695).

(1) Proportion ab/c with a percentile bootstrap interval. The reported decomposition
    (results/tables/bulkmask/decompositions.csv, R package mediation) reported the components with
    intervals but the proportion as a point value only. The same nonparametric bootstrap (10,000
    resamples of samples, both linear models refitted) is run here; its component intervals are
    checked against the reported ones before the proportion interval is reported.
(2) The medsens crossing point. For the two linear models used here, Imai, Keele & Yamamoto (2010,
    Statistical Science 25:51-71) give the component as a function of the sensitivity parameter rho,
    and it is zero exactly when rho equals the correlation between the residuals of M ~ X and of
    Y ~ X. That correlation is computed in closed form and compared with the medsens output of the
    original run (rho = 0.60 for the marker score on a 0.05 grid; table written by
    code/R/14_mediation_sensitivity.R, results/tables/Table_mediation_sensitivity.csv).
(3) Partial Spearman correlations given each eosinophil estimate plus case/control status; the
    marker-score row is first reproduced from the reported value (correlations.csv).

Input: results/tables/bulkmask/points.csv (first 695 rows = GSE152004), decompositions.csv,
correlations.csv. Output: results/tables/revision_2026_11/decomposition_intervals.csv.
Run from the repository root:  python3 code/python/22_decomposition_intervals.py
"""
from pathlib import Path
import importlib.util
import sys

import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "results" / "tables" / "revision_2026_11"
SEED, B = 20261105, 10000
EST = [("marker", "sig_eosinophil"), ("xcellraw", "eos_xcell_raw"), ("gsva", "eos_gsva")]
MEDSENS_ARCHIVED = {"marker": 0.60}

spec = importlib.util.spec_from_file_location("rob", ROOT / "code/python/16_revision_robustness.py")
rob = importlib.util.module_from_spec(spec)
spec.loader.exec_module(rob)
failures = []


def check(ok, msg):
    print(("PASS " if ok else "FAIL ") + msg)
    if not ok:
        failures.append(msg)


def coefs(X, M, Y, C):
    """a, b, c' and c for each bootstrap row; C (n x q or None) enters both models as covariates."""
    def fit(y, cols):
        A = np.concatenate([np.ones(y.shape + (1,))] + [c[..., None] for c in cols], axis=-1)
        beta = np.linalg.solve(np.einsum("bni,bnj->bij", A, A), np.einsum("bni,bn->bi", A, y)[..., None])[..., 0]
        return beta
    cov = [] if C is None else [C]
    a = fit(M, [X] + cov)[:, 1]
    bY = fit(Y, [X, M] + cov)
    c = fit(Y, [X] + cov)[:, 1]
    return a, bY[:, 2], bY[:, 1], c


def main():
    pts = pd.read_csv(ROOT / "results/tables/bulkmask/points.csv").iloc[:695].reset_index(drop=True)
    dec = pd.read_csv(ROOT / "results/tables/bulkmask/decompositions.csv")
    cor = pd.read_csv(ROOT / "results/tables/bulkmask/correlations.csv")
    dec = dec[dec.dataset == "GSE152004"]
    X, Y, G = (pts[c].to_numpy(float) for c in ("exposure", "outcome", "group_bin"))
    n = len(X)
    idx = np.random.default_rng(SEED).integers(0, n, size=(B, n)).astype(np.int32)
    rows = []
    for est, col in EST:
        M = pts[col].to_numpy(float)
        for adj, C in (("none", None), ("group", G)):
            pub = dec[(dec.estimator == est) & (dec.adjusted == adj)].iloc[0]
            # point estimates on the full sample must equal the published ones
            a, b, cp, c = (v[0] for v in coefs(X[None], M[None], Y[None], None if C is None else C[None]))
            check(abs(a * b - pub.ACME) < 1e-9 and abs(c - pub.total_effect) < 1e-9,
                  f"{est}/{adj}: ab and total equal the published values")
            parts = [coefs(X[j], M[j], Y[j], None if C is None else C[j])     # chunks keep memory small
                     for j in np.array_split(idx, 10)]
            a, b, cp, c = (np.concatenate(v) for v in zip(*parts))
            ab, prop = a * b, a * b / c
            lo, hi = np.percentile(ab, [2.5, 97.5])
            check(abs(lo - pub.ACME_lo) < 0.006 and abs(hi - pub.ACME_hi) < 0.006,
                  f"{est}/{adj}: bootstrap interval of ab ({lo:.3f}, {hi:.3f}) matches the published "
                  f"({pub.ACME_lo:.3f}, {pub.ACME_hi:.3f}) within resampling error")
            plo, phi = np.percentile(prop, [2.5, 97.5])
            # closed-form medsens crossing point: corr of residuals of M ~ X and Y ~ X (no covariates)
            rM = M - np.polyval(np.polyfit(X, M, 1), X)
            rY = Y - np.polyval(np.polyfit(X, Y, 1), X)
            rho_star = float(np.corrcoef(rM, rY)[0, 1]) if adj == "none" else np.nan
            # partial Spearman given the estimate (and case/control)
            Z = M[:, None] if C is None else np.column_stack([M, C])
            r, p, k = rob.partial_spearman(X, Y, Z)
            lo_r, hi_r = rob.fisher_ci(r, n, k)
            rows.append(dict(estimator=est, adjusted=adj, partial_rho=r, partial_lo=lo_r,
                             partial_hi=hi_r, partial_p=p, component=pub.ACME, total=pub.total_effect,
                             component_lo=lo, component_hi=hi,
                             component_ci_maxdiff_vs_published=max(abs(lo - pub.ACME_lo), abs(hi - pub.ACME_hi)),
                             proportion=pub.prop_mediated, proportion_lo=plo, proportion_hi=phi,
                             share_of_resamples_total_le_0=float(np.mean(c <= 0)),
                             rho_star_closed_form=rho_star,
                             rho_star_medsens_archived=MEDSENS_ARCHIVED.get(est, np.nan) if adj == "none" else np.nan))
            if adj == "group" and est == "marker":
                pub_r = cor[(cor.dataset == "GSE152004") & (cor.model == "adj_marker+group")].rho.iloc[0]
                check(abs(r - pub_r) < 1e-12, f"marker + case/control partial rho reproduces {pub_r:.4f}")
    out = pd.DataFrame(rows)
    m = out[(out.estimator == "marker") & (out.adjusted == "none")].iloc[0]
    check(abs(m.rho_star_closed_form - 0.60) <= 0.025,
          f"closed-form crossing point {m.rho_star_closed_form:.4f} rounds to the archived medsens 0.60")
    OUT.mkdir(parents=True, exist_ok=True)
    out.to_csv(OUT / "decomposition_intervals.csv", index=False)
    with pd.option_context("display.width", 220, "display.max_columns", 30):
        print(out.drop(columns=["component", "total"]).round(4).to_string(index=False))
    if failures:
        sys.exit(f"{len(failures)} check(s) failed")


if __name__ == "__main__":
    main()
