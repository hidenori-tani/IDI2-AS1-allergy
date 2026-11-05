"""Fisher-z intervals for the partial correlations of Table 2A and Table S5 (the case/control-adjusted
rows of Table 2B come from 22_decomposition_intervals.py),
and the xCell-compensated partial correlation on the full asthma cohort (n = 695).

Inputs (tracked):
  results/tables/bulkmask/points.csv                 per-sample values (row order = COHORTS)
  results/tables/revision_2026_11/mt_grid.csv        rho, p, n, conditioners for 28 tests
  results/tables/revision_2026_11/type2_conditioning.csv
  results/tables/revision_2026_11/table2A_intervals.csv   (positive control)

Positive controls (the script exits 1 if any fails):
  1. Fisher intervals recomputed from (rho, n, k) reproduce table2A_intervals.csv (1e-6).
  2. The rank-residual partial Spearman reproduces adj_xcellraw and adj_marker for asthma (1e-10).
  3. On the 686-sample subset that code/R/13b_fig6_bulkmask.R selected with grepl("^HR"),
     the xCell-compensated partial correlation reproduces the value drawn in the old
     Figure 6B (+0.065, two decimals).
Negative control: dropping the k term from the Fisher standard error must change the
asthma partial interval (otherwise the check is not looking at k).

Writes results/tables/revision_2026_11/partial_fisher_intervals.csv,
results/tables/revision_2026_11/xcell_comp_partial.csv,
results/tables/revision_2026_11/detectable_partial_rho.csv (smallest partial correlation detectable with
80% power at two-sided alpha = 0.05, same standard error as the intervals) and
results/tables/revision_2026_11/mt_grid_distinct.csv (BH over the grid once pseudo-tests are excluded;
none remain after the 2026-11-05 alias fix, so all 28 tests enter).
"""
from pathlib import Path
import sys

import numpy as np
import pandas as pd
from scipy import stats

OUT = Path("results/tables/revision_2026_11")
COHORTS = [("GSE152004", 695), ("GSE121212", 65), ("GSE58640", 16), ("GSE136825", 70)]
K = {"raw": 0, "eos": 1, "th2": 1, "neu": 1, "grp": 1, "eos+grp": 2, "eos+th2": 2}
failures = []


def check(ok, msg):
    if not ok:
        failures.append(msg)
        print("FAIL", msg)


def fisher_ci(r, n, k, drop_k=False):
    se = np.sqrt((1 + r * r / 2) / (n - 3 - (0 if drop_k else k)))
    z = np.arctanh(r)
    return float(np.tanh(z - 1.959963984540054 * se)), float(np.tanh(z + 1.959963984540054 * se))


def detectable_rho(n, k, power=0.80, alpha=0.05):
    """Smallest |r| whose Fisher-z test (SE as in fisher_ci) reaches the given power."""
    need = stats.norm.ppf(1 - alpha / 2) + stats.norm.ppf(power)
    r = 0.1
    for _ in range(100):
        r = float(np.tanh(need * np.sqrt((1 + r * r / 2) / (n - 3 - k))))
    return r


def power_at(r, n, k, alpha=0.05):
    se = np.sqrt((1 + r * r / 2) / (n - 3 - k))
    zc, zr = stats.norm.ppf(1 - alpha / 2), np.arctanh(r) / se
    return float(stats.norm.sf(zc - zr) + stats.norm.cdf(-zc - zr))


def partial_spearman(x, y, zs):
    rx, ry = stats.rankdata(x), stats.rankdata(y)
    Z = np.column_stack([np.ones(len(x))] + [stats.rankdata(z) for z in zs])
    ex = rx - Z @ np.linalg.lstsq(Z, rx, rcond=None)[0]
    ey = ry - Z @ np.linalg.lstsq(Z, ry, rcond=None)[0]
    r = float(np.corrcoef(ex, ey)[0, 1])
    df = len(x) - 2 - len(zs)
    t = r * np.sqrt(df / (1 - r * r))
    return r, float(2 * stats.t.sf(abs(t), df))


def main():
    pts = pd.read_csv("results/tables/bulkmask/points.csv")
    check(len(pts) == sum(n for _, n in COHORTS), f"points.csv rows {len(pts)}")
    start, blocks = 0, {}
    for gse, n in COHORTS:
        blocks[gse] = pts.iloc[start:start + n].reset_index(drop=True)
        start += n
    ast = blocks["GSE152004"]

    # 1. positive control: Table 2A intervals
    t2a = pd.read_csv(OUT / "table2A_intervals.csv")
    for row in t2a.itertuples():
        lo, hi = fisher_ci(row.raw_rho, row.n, 0)
        check(abs(lo - row.raw_fisher_lo) < 1e-6 and abs(hi - row.raw_fisher_hi) < 1e-6,
              f"{row.cohort} raw Fisher [{lo}, {hi}]")
        lo, hi = fisher_ci(row.partial_rho, row.n, 1)
        check(abs(lo - row.partial_fisher_lo) < 1e-6 and abs(hi - row.partial_fisher_hi) < 1e-6,
              f"{row.cohort} partial Fisher [{lo}, {hi}]")
    # negative control: without k the asthma partial interval must differ
    a = t2a[t2a.cohort == "GSE152004"].iloc[0]
    lo0, _ = fisher_ci(a.partial_rho, a.n, 1, drop_k=True)
    check(abs(lo0 - a.partial_fisher_lo) > 1e-6, "negative control: k has no effect on the interval")

    # 2. positive control: partial Spearman by rank residuals
    grid = pd.read_csv(OUT / "mt_grid.csv")
    for model, col in [("adj_marker", "sig_eosinophil"), ("adj_xcellraw", "eos_xcell_raw")]:
        pub = grid[(grid.dataset == "GSE152004") & (grid.model == model)].iloc[0]
        r, _ = partial_spearman(ast.exposure, ast.outcome, [ast[col]])
        check(abs(r - pub.rho) < 1e-10, f"{model}: {r} vs {pub.rho}")

    # 3. xCell compensated: reproduce the old figure on 686 samples, then the full 695
    hr = ast[ast.sample_id.str.match(r"^HR")]
    r686, _ = partial_spearman(hr.exposure, hr.outcome, [hr.eos_xcell_comp])
    check(abs(r686 - 0.065) < 0.0005,
          f"686-sample xCell comp partial {r686:.4f} does not reproduce old Figure 6B (+0.065)")
    r695, p695 = partial_spearman(ast.exposure, ast.outcome, [ast.eos_xcell_comp])
    lo695, hi695 = fisher_ci(r695, len(ast), 1)
    pd.DataFrame([dict(cohort="GSE152004", n=len(ast), partial_rho=r695, p=p695, fisher_lo=lo695, fisher_hi=hi695,
                       zero_frac=float((ast.eos_xcell_comp == 0).mean()),
                       n_hr_subset=len(hr), partial_rho_hr_subset=r686)]
                 ).to_csv(OUT / "xcell_comp_partial.csv", index=False)

    # Fisher intervals for every test in the grid and the Th2-only rows
    rows = []
    for r in grid.itertuples():
        k = K["raw"] if r.model == "raw" else K.get(str(r.conditioners_used), 1)
        lo, hi = fisher_ci(r.rho, r.n, k)
        rows.append(dict(dataset=r.dataset, model=r.model, conditioners=r.conditioners_used, n=r.n, k=k,
                         rho=r.rho, p=r.p, fisher_lo=lo, fisher_hi=hi))
    t2 = pd.read_csv(OUT / "type2_conditioning.csv")
    n_of = dict(COHORTS)
    for r in t2[(t2.conditioning == "th2") & t2.rho.notna()].itertuples():
        lo, hi = fisher_ci(r.rho, n_of[r.cohort], 1)
        rows.append(dict(dataset=r.cohort, model="adj_th2_only", conditioners="th2", n=n_of[r.cohort], k=1,
                         rho=r.rho, p=r.p, fisher_lo=lo, fisher_hi=hi))
    rows.append(dict(dataset="GSE152004", model="adj_xcellcomp", conditioners="eos", n=len(ast), k=1,
                     rho=r695, p=p695, fisher_lo=lo695, fisher_hi=hi695))
    pd.DataFrame(rows).to_csv(OUT / "partial_fisher_intervals.csv", index=False)

    # Guard against pseudo-tests in the 28-test grid of 16_revision_robustness.py: a row whose
    # conditioner silently dropped out repeats another test under an adjusted label. Until
    # 2026-11-05 there were two (GSE136825: the Th2 and neutrophil signatures resolved no genes
    # because the config lacked their Ensembl aliases; scripts/rerun_bulkmask_cohorts.R fixed it).
    pseudo = ((grid.model != "raw") & grid.conditioners_used.isna()) | \
             ((grid.model == "adj_marker+th2") & (grid.conditioners_used != "eos+th2"))
    check(int(pseudo.sum()) == 0, f"expected no pseudo-tests, found {int(pseudo.sum())}")
    distinct = grid[~pseudo].copy()
    m = len(distinct)
    order = np.argsort(distinct.p.values)
    q = np.empty(m)
    q[order] = np.minimum.accumulate((distinct.p.values[order] * m / np.arange(1, m + 1))[::-1])[::-1]
    distinct["q_grid_distinct"] = np.minimum(q, 1)
    distinct.to_csv(OUT / "mt_grid_distinct.csv", index=False)

    # Precision of the null residual (Discussion): one conditioning variable, per cohort.
    det = pd.DataFrame([{"cohort": c, "n": n, "k": 1, "power": 0.80, "alpha": 0.05,
                         "detectable_rho": detectable_rho(n, 1)} for c, n in COHORTS])
    r_a = det.detectable_rho[0]
    check(abs(power_at(r_a, 695, 1) - 0.80) < 1e-6, "power at the detectable rho is not 0.80")
    check(power_at(0.9 * r_a, 695, 1) < 0.80, "negative control: power below the detectable rho is not < 0.80")
    det.to_csv(OUT / "detectable_partial_rho.csv", index=False)
    print(f"detectable partial rho (80% power, k = 1): asthma n = 695 -> {r_a:.4f}")
    print(f"grid of {m} distinct tests: min q = {distinct.q_grid_distinct.min():.3f}; "
          f"q < 0.05 in {(distinct.q_grid_distinct < 0.05).sum()} test(s)")

    print(f"xCell compensated partial rho: 686 samples {r686:+.4f}; 695 samples {r695:+.4f} (p = {p695:.3g})")
    if failures:
        print(f"{len(failures)} check(s) failed")
        return 1
    print("all positive and negative controls passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
