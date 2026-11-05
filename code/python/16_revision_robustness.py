"""Robustness analyses (November 2026).

Five analyses that do not touch the raw count matrices:
  (1) 95 % intervals for the raw and composition-adjusted Spearman correlations (Table 2A);
  (2) a side-by-side comparison of the three eosinophil-abundance estimates;
  (3) eosinophil-specific versus broader type-2 conditioning (Th2-only model added);
  (4) multiple testing defined per question, plus the whole correlation grid;
  (5) alternative weightings of the IDI2-AS1 and IL5 meta-analyses.

Inputs (all inside this repository):
  results/tables/bulkmask/points.csv           per-sample values, 4 cohorts, 846 samples
  results/tables/bulkmask/correlations.csv     reported correlations (positive control)
  results/tables/bulkmask/decompositions.csv   reported decompositions
  results/tables/ALL_focal_genes_deg.csv       per-cohort differential expression
  results/tables/Table_meta_analysis_summary.csv  earlier meta-analysis on apeglm SDs (positive control; superseded)

The script first recomputes the reported numbers it builds on from the same inputs. It
writes all outputs regardless and then exits non-zero if any check failed, so the outputs
of a failing run must not be used.
The earlier meta-analysis is reproduced only when tau^2 is estimated with metafor's
default stopping rule (change in tau^2 < 1e-5). For IDI2-AS1 the apeglm posterior variance
of GSE136825 is about 2.1e-6 (SD 0.00144; the other four cohorts 1.1e-3 to 7.5e-2), so that
cohort carries 99.1% of the weight, and the rule stops at tau^2 = 6.8e-6 while the REML
likelihood is maximised at tau^2 = 0; both fits are written out (meta_reweighting.csv).
Outputs: results/tables/revision_2026_11/*.csv and summary.txt
Run from the repository root:  python3 code/python/16_revision_robustness.py
"""
from pathlib import Path
import sys

import numpy as np
import pandas as pd
from scipy import optimize, stats

OUT = Path("results/tables/revision_2026_11")
SEED = 20261105
B = 10000
# Row order of points.csv = rbind order in scripts/run_bulkmask_pipeline.R
# (config order; GSE246323 contributes no rows because IL5 is filtered out there).
COHORTS = [("GSE152004", 695), ("GSE121212", 65), ("GSE58640", 16), ("GSE136825", 70)]
COND = {"eos": "sig_eosinophil", "th2": "sig_th2", "neu": "sig_neutrophil", "grp": "group_bin"}
EST = {"adj_marker": "sig_eosinophil", "adj_xcellraw": "eos_xcell_raw", "adj_gsva": "eos_gsva"}
N_DE = {"GSE152004": 695, "GSE121212": 65, "GSE246323": 10, "GSE58640": 16, "GSE136825": 70}
IDS = {"IDI2-AS1": {"IDI2-AS1", "ENSG00000232656"}, "IL5": {"IL5", "ENSG00000113525"}}

failures = []


def check(ok, msg):
    if not ok:
        failures.append(msg)
        print("FAIL:", msg)


def partial_spearman(x, y, Z=None):
    """Spearman partial correlation: Pearson correlation of rank residuals.

    p from the t distribution with n - 2 - k degrees of freedom (as ppcor).
    """
    rx, ry = stats.rankdata(x), stats.rankdata(y)
    k = 0
    if Z is not None and Z.shape[1]:
        RZ = np.column_stack([stats.rankdata(z) for z in Z.T])
        A = np.column_stack([np.ones(len(rx)), RZ])
        rx = rx - A @ np.linalg.lstsq(A, rx, rcond=None)[0]
        ry = ry - A @ np.linalg.lstsq(A, ry, rcond=None)[0]
        k = RZ.shape[1]
    r = float(np.corrcoef(rx, ry)[0, 1])
    df = len(x) - 2 - k
    t = r * np.sqrt(df / (1 - r * r))
    return r, float(2 * stats.t.sf(abs(t), df)), k


def fisher_ci(r, n, k=0):
    """Fisher-z interval with the Bonett-Wright variance for Spearman."""
    se = np.sqrt((1 + r * r / 2) / (n - 3 - k))
    z = np.arctanh(r)
    return float(np.tanh(z - 1.959964 * se)), float(np.tanh(z + 1.959964 * se))


def reml_nll(y, v, t2):
    """Negative REML log-likelihood of the intercept-only random-effects model (up to a constant)."""
    w = 1 / (v + t2)
    mu = np.sum(w * y) / np.sum(w)
    return 0.5 * (np.sum(np.log(v + t2)) + np.log(np.sum(w)) + np.sum(w * (y - mu) ** 2))


def tau2_metafor(y, v, threshold=1e-5, maxiter=100):
    """tau^2 exactly as metafor::rma(method = "REML") with its default control settings:
    Fisher scoring started at the Hedges (HE) estimate, step halving at the lower bound 0,
    and termination once the change in tau^2 between iterations is below 1e-5
    (metafor 5.3-2 reference page for rma.uni, fetched 2026-11-05)."""
    k = len(y)
    X = np.ones((k, 1))
    t2 = max(0.0, float(np.sum((y - y.mean()) ** 2) / (k - 1) - v.mean()))
    change, it = np.inf, 0
    while change > threshold:
        it += 1
        if it > maxiter:
            raise RuntimeError("Fisher scoring did not converge")
        old = t2
        W = np.diag(1 / (v + t2))
        P = W - W @ X @ np.linalg.inv(X.T @ W @ X) @ X.T @ W
        adj = float((y @ P @ P @ y - np.trace(P)) / np.sum(P * P))
        while t2 + adj < 0:
            adj /= 2
        t2 += adj
        change = abs(old - t2)
    return t2


def tau2_exact(y, v):
    """tau^2 at the maximum of the REML likelihood (boundary 0 included)."""
    hi = max(10 * np.var(y), 1e-6)
    res = optimize.minimize_scalar(lambda t: reml_nll(y, v, t), bounds=(0, hi), method="bounded",
                                   options={"xatol": 1e-16, "maxiter": 5000})
    return float(res.x) if reml_nll(y, v, res.x) < reml_nll(y, v, 0.0) else 0.0


def reml(y, v, tau2="metafor"):
    """Random-effects REML (metafor::rma, method = "REML", test = "z").
    tau2 = "metafor" reproduces the earlier (superseded) apeglm-SD fit; tau2 = "exact" uses the likelihood maximum."""
    y, v = np.asarray(y, float), np.asarray(v, float)
    t2 = tau2_metafor(y, v) if tau2 == "metafor" else tau2_exact(y, v)
    w = 1 / (v + t2)
    mu = float(np.sum(w * y) / np.sum(w))
    se = float(np.sqrt(1 / np.sum(w)))
    wf = 1 / v
    mu_f = np.sum(wf * y) / np.sum(wf)
    Q = float(np.sum(wf * (y - mu_f) ** 2))
    k = len(y)
    s2 = (k - 1) * np.sum(wf) / (np.sum(wf) ** 2 - np.sum(wf ** 2))
    return dict(mu=mu, se=se, lo=mu - 1.959964 * se, hi=mu + 1.959964 * se,
                p=float(2 * stats.norm.sf(abs(mu / se))), tau2=t2, Q=Q,
                Qp=float(stats.chi2.sf(Q, k - 1)), I2=100 * t2 / (t2 + s2), w=w / w.sum())


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    pts = pd.read_csv("results/tables/bulkmask/points.csv")
    cor = pd.read_csv("results/tables/bulkmask/correlations.csv")
    dec = pd.read_csv("results/tables/bulkmask/decompositions.csv")
    deg = pd.read_csv("results/tables/ALL_focal_genes_deg.csv")
    meta = pd.read_csv("results/tables/Table_meta_analysis_summary.csv")
    lines = []

    # ---- cohort blocks, verified against the published raw correlations --------
    check(len(pts) == sum(n for _, n in COHORTS), f"points.csv has {len(pts)} rows")
    blocks, start = {}, 0
    for gse, n in COHORTS:
        blocks[gse] = pts.iloc[start:start + n].reset_index(drop=True)
        start += n
    for gse, d in blocks.items():
        r, _, _ = partial_spearman(d.exposure.values, d.outcome.values)
        pub = cor[(cor.dataset == gse) & (cor.model == "raw")].iloc[0]
        check(abs(r - pub.rho) < 1e-10 and len(d) == pub.n, f"raw rho {gse}: {r} vs {pub.rho}")

    # ---- positive control: every published conditioned correlation --------------
    pc = []
    for _, row in cor.iterrows():
        if row.model == "raw":
            continue
        d = blocks[row.dataset]
        used = str(row.conditioners_used) if pd.notna(row.conditioners_used) else ""
        cols = [EST.get(row.model, COND["eos"]) if c == "eos" else COND[c]
                for c in used.split("+") if c]
        Z = d[cols].values if cols else None
        r, p, _ = partial_spearman(d.exposure.values, d.outcome.values, Z)
        pc.append(dict(dataset=row.dataset, model=row.model, pub_rho=row.rho, rho=r,
                       pub_p=row.p, p=p))
        check(abs(r - row.rho) < 1e-8, f"{row.dataset} {row.model}: rho {r} vs {row.rho}")
        check(abs(p - row.p) <= 1e-6 * max(row.p, 1e-12) or abs(p - row.p) < 1e-9,
              f"{row.dataset} {row.model}: p {p} vs {row.p}")
    pd.DataFrame(pc).to_csv(OUT / "positive_control_correlations.csv", index=False)
    lines.append(f"Positive control: {len(pc)} published conditioned correlations reproduced "
                 f"(max |d rho| = {max(abs(x['rho'] - x['pub_rho']) for x in pc):.2e}).")

    # ---- (1) intervals for Table 2A ---------------------------------------------
    rng = np.random.default_rng(SEED)
    rows = []
    for gse, d in blocks.items():
        x, y, z = d.exposure.values, d.outcome.values, d[[COND["eos"]]].values
        n = len(d)
        r0, p0, _ = partial_spearman(x, y)
        r1, p1, _ = partial_spearman(x, y, z)
        bs0, bs1 = np.empty(B), np.empty(B)
        for b in range(B):
            i = rng.integers(0, n, n)
            bs0[b] = partial_spearman(x[i], y[i])[0]
            bs1[b] = partial_spearman(x[i], y[i], z[i])[0]
        f0, f1 = fisher_ci(r0, n), fisher_ci(r1, n, 1)
        rows.append(dict(cohort=gse, n=n,
                         raw_rho=r0, raw_boot_lo=np.nanpercentile(bs0, 2.5), raw_boot_hi=np.nanpercentile(bs0, 97.5),
                         raw_fisher_lo=f0[0], raw_fisher_hi=f0[1],
                         partial_rho=r1, partial_boot_lo=np.nanpercentile(bs1, 2.5),
                         partial_boot_hi=np.nanpercentile(bs1, 97.5),
                         partial_fisher_lo=f1[0], partial_fisher_hi=f1[1]))
    t2a = pd.DataFrame(rows)
    t2a.to_csv(OUT / "table2A_intervals.csv", index=False)
    lines.append(f"(1) Table 2A intervals: B = {B} percentile bootstrap (seed {SEED}) + Fisher z.")

    # ---- (2) the three eosinophil-abundance estimates side by side ---------------
    rows = []
    for gse, d in blocks.items():
        cc = lambda a, b: stats.spearmanr(d[a], d[b]).statistic
        rec = dict(cohort=gse, n=len(d),
                   rho_marker_gsva=cc("sig_eosinophil", "eos_gsva"),
                   rho_marker_xcellraw=cc("sig_eosinophil", "eos_xcell_raw"),
                   rho_gsva_xcellraw=cc("eos_gsva", "eos_xcell_raw"),
                   xcell_compensated_zero_frac=float((d.eos_xcell_comp == 0).mean()))
        for m in EST:
            sel = cor[(cor.dataset == gse) & (cor.model == m)]
            rec[f"partial_rho_{m[4:]}"] = float(sel.rho.iloc[0]) if len(sel) else np.nan
        for e in ("marker", "xcellraw", "gsva"):
            sel = dec[(dec.dataset == gse) & (dec.estimator == e) & (dec.adjusted == "none")]
            rec[f"prop_{e}"] = float(sel.prop_mediated.iloc[0]) if len(sel) else np.nan
            rec[f"comp_p_{e}"] = float(sel.ACME_p.iloc[0]) if len(sel) else np.nan
        rows.append(rec)
    pd.DataFrame(rows).to_csv(OUT / "estimator_comparison.csv", index=False)
    lines.append("(2) Estimator comparison written (concordance, compensated-xCell zeros, partial rho, proportion).")

    # ---- (3) eosinophil-specific versus broader type-2 conditioning ---------------
    rows = []
    for gse, d in blocks.items():
        x, y = d.exposure.values, d.outcome.values
        for label, cols in [("none", []), ("eos", ["sig_eosinophil"]), ("th2", ["sig_th2"]),
                            ("eos+th2", ["sig_eosinophil", "sig_th2"]), ("neu", ["sig_neutrophil"])]:
            if any(d[c].isna().all() for c in cols):
                rows.append(dict(cohort=gse, conditioning=label, rho=np.nan, p=np.nan, note="signature unavailable"))
                continue
            r, p, _ = partial_spearman(x, y, d[cols].values if cols else None)
            rows.append(dict(cohort=gse, conditioning=label, rho=r, p=p, note=""))
    pd.DataFrame(rows).to_csv(OUT / "type2_conditioning.csv", index=False)
    lines.append("(3) Type-2 conditioning written (none / eos / th2 / eos+th2 / neutrophil).")

    # ---- (4) multiple testing ------------------------------------------------------
    def bh(p):
        p = np.asarray(p, float)
        o = np.argsort(p)
        q = p[o] * len(p) / np.arange(1, len(p) + 1)
        q = np.minimum.accumulate(q[::-1])[::-1]
        out = np.empty_like(q)
        out[o] = np.minimum(q, 1)
        return out
    rawf = cor[cor.model == "raw"].copy()
    rawf["q_family_raw_4cohorts"] = bh(rawf.p)
    grid = cor.copy()
    grid["q_grid_28"] = bh(grid.p)
    compf = dec[(dec.dataset == "GSE152004") & (dec.adjusted == "none")].copy()
    compf["q_family_asthma_3estimators"] = bh(compf.ACME_p)
    rawf.to_csv(OUT / "mt_family_raw.csv", index=False)
    grid.to_csv(OUT / "mt_grid.csv", index=False)
    compf[["estimator", "ACME", "ACME_p", "q_family_asthma_3estimators"]].to_csv(OUT / "mt_family_asthma_components.csv", index=False)
    lines.append("(4) BH per question family (raw: 4 cohorts; asthma components: 3 estimates) and over the 28-test grid.")

    # ---- (5) meta-analysis: reproduce, then reweight -------------------------------
    rows = []
    for gene, ids in IDS.items():
        g = deg[deg.gene.isin(ids)].drop_duplicates("dataset").reset_index(drop=True)
        y, v = g.log2FC.values, g.lfcSE.values ** 2
        n = np.array([N_DE[s] for s in g.dataset])
        pub = meta[meta.gene == gene].iloc[0]
        fit = reml(y, v)
        check(len(g) == pub.k_datasets, f"{gene}: k {len(g)} vs {pub.k_datasets}")
        for key, pk, tol in [("mu", "pooled_log2FC", 1e-7), ("lo", "ci_lower", 1e-6), ("hi", "ci_upper", 1e-6),
                             ("Qp", "Q_pval", 1e-8)]:
            check(abs(fit[key] - pub[pk]) < tol + 1e-4 * abs(pub[pk]), f"{gene} {key}: {fit[key]} vs {pub[pk]}")
        check(abs(fit["tau2"] - pub.tau2) <= 1e-9 * max(pub.tau2, 1e-12) + 1e-15, f"{gene} tau2: {fit['tau2']} vs {pub.tau2}")
        check(abs(fit["I2"] - pub.I2_pct) < 1e-3 * max(pub.I2_pct, 1e-6) + 1e-6, f"{gene} I2: {fit['I2']} vs {pub.I2_pct}")
        top = g.dataset[int(np.argmax(fit["w"]))]
        rows.append(dict(gene=gene, analysis="REML (published, reproduced)", k=len(g), estimate=fit["mu"],
                         lo=fit["lo"], hi=fit["hi"], p=fit["p"], tau2=fit["tau2"], I2=fit["I2"],
                         note=f"largest weight {top} = {100 * fit['w'].max():.2f} %"))
        # the same model at the maximum of the REML likelihood (no stopping rule)
        fx = reml(y, v, tau2="exact")
        dll = reml_nll(y, v, fit["tau2"]) - reml_nll(y, v, fx["tau2"])
        rows.append(dict(gene=gene, analysis="REML at the likelihood maximum", k=len(g), estimate=fx["mu"],
                         lo=fx["lo"], hi=fx["hi"], p=fx["p"], tau2=fx["tau2"], I2=fx["I2"],
                         note=f"REML log-likelihood {dll:.2e} above the published fit"))
        # Knapp-Hartung (HKSJ) on the REML fit
        w = 1 / (v + fit["tau2"])
        qhk = np.sum(w * (y - fit["mu"]) ** 2) / (len(y) - 1)
        se_hk = np.sqrt(qhk / np.sum(w))
        tcrit = stats.t.ppf(0.975, len(y) - 1)
        rows.append(dict(gene=gene, analysis="REML + Knapp-Hartung", k=len(g), estimate=fit["mu"],
                         lo=fit["mu"] - tcrit * se_hk, hi=fit["mu"] + tcrit * se_hk,
                         p=float(2 * stats.t.sf(abs(fit["mu"] / se_hk), len(y) - 1)), note=""))
        # equal and sample-size weights (tau2 from the REML fit)
        for lab, ww in [("equal weights", np.ones(len(y))), ("sample-size weights", n.astype(float))]:
            ww = ww / ww.sum()
            est = float(np.sum(ww * y))
            se = float(np.sqrt(np.sum(ww ** 2 * (v + fit["tau2"]))))
            rows.append(dict(gene=gene, analysis=lab, k=len(g), estimate=est, lo=est - 1.959964 * se,
                             hi=est + 1.959964 * se, p=float(2 * stats.norm.sf(abs(est / se))), note=""))
        # leave-one-out
        for j, s in enumerate(g.dataset):
            keep = np.arange(len(y)) != j
            f2 = reml(y[keep], v[keep])
            rows.append(dict(gene=gene, analysis=f"REML leave-one-out (drop {s})", k=int(keep.sum()),
                             estimate=f2["mu"], lo=f2["lo"], hi=f2["hi"], p=f2["p"], tau2=f2["tau2"], I2=f2["I2"],
                             note=""))
        # Stouffer: no use of the posterior SD at all (per-cohort Wald p, sign of the estimate, sqrt(n) weights)
        zi = np.sign(y) * stats.norm.isf(g.pvalue.values / 2)
        Z = float(np.sum(np.sqrt(n) * zi) / np.sqrt(np.sum(n)))
        rows.append(dict(gene=gene, analysis="Stouffer weighted Z (sqrt n)", k=len(g), estimate=Z, lo=np.nan,
                         hi=np.nan, p=float(2 * stats.norm.sf(abs(Z))), note="estimate column = Z"))
    pd.DataFrame(rows).to_csv(OUT / "meta_reweighting.csv", index=False)
    lines.append("(5) Meta-analysis reproduced (REML as metafor's defaults: Fisher scoring, change in tau2 < 1e-5), "
                 "refitted at the REML likelihood maximum, and re-weighted (HKSJ, equal, sample-size, "
                 "leave-one-out, Stouffer).")

    (OUT / "summary.txt").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("\n".join(lines))
    if failures:
        print(f"{len(failures)} positive-control failure(s)")
        sys.exit(1)
    print("all positive controls passed")


if __name__ == "__main__":
    main()
