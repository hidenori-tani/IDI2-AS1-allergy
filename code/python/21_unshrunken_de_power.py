"""Unshrunken differential expression, power and pooling for IDI2-AS1 and IL5.

Why: the per-cohort estimates of the earlier meta-analysis are apeglm posterior modes with posterior standard
deviations. Those standard deviations are shrunken (in GSE136825 they are 0.00144 for 87% of
the genes, including IDI2-AS1 and IL5), so they cannot serve as sampling errors, either as meta-analysis weights or for a power
calculation. This script refits unshrunken estimates from the deposited counts and uses them for
(i) the smallest log2 fold change each cohort could detect with 80% power and (ii) the pooled
estimate.

Model, per count cohort and gene: a negative binomial GLM, counts ~ group, with log(size factor)
as offset. Size factors are DESeq2's median of ratios, computed after the same filter as the
published analysis (total count >= 10, code/R/04_deg_analysis.R); the dispersion is the gene-wise
maximum-likelihood estimate (DESeq2 would shrink it toward a trend, which matters little at these
sample sizes; the Wald p values are compared with the published DESeq2 ones below).
GSE58640 (FPKM) keeps its published limma-trend estimate and ordinary standard error.

Positive controls (the script exits non-zero if one fails):
  - the samples and groups equal those in results/tables/bulkmask/points.csv;
  - normalized counts rank the samples exactly as the published vst values do (vst is monotone
    in the normalized count, so Spearman rho must be 1 up to ties);
  - the REML routine of 16_revision_robustness.py reproduces the earlier (superseded) apeglm-SD pooled
    estimate from its inputs before it is applied to the unshrunken ones;
  - Stouffer's Z from the per-cohort Wald p values reproduces the Stouffer rows of
    results/tables/revision_2026_11/meta_reweighting.csv.

Inputs: data/raw/<GSE>/ (public GEO supplementary files, see Table 1; GSE152004, GSE121212,
GSE246323 and GSE136825 re-downloaded 2026-11-05), results/tables/bulkmask/points.csv,
results/tables/ALL_focal_genes_deg.csv, results/tables/Table_meta_analysis_summary.csv and
results/tables/revision_2026_11/meta_reweighting.csv (an output of 16_revision_robustness.py,
whose REML routine is also imported: run 16 first).
Outputs: results/tables/revision_2026_11/unshrunken_de.csv, unshrunken_meta.csv.
Run from the repository root:  python3 code/python/21_unshrunken_de_power.py
"""
from pathlib import Path
import gzip
import importlib.util
import re
import sys

import numpy as np
import pandas as pd
from scipy import stats
import statsmodels.api as sm

ROOT = Path(__file__).resolve().parents[2]
RAW = ROOT / "data" / "raw"
OUT = ROOT / "results" / "tables" / "revision_2026_11"
IDS = {"IDI2-AS1": ("IDI2-AS1", "ENSG00000232656"), "IL5": ("IL5", "ENSG00000113525")}
Z80 = stats.norm.ppf(0.975) + stats.norm.ppf(0.80)

spec = importlib.util.spec_from_file_location("rob", ROOT / "code/python/16_revision_robustness.py")
rob = importlib.util.module_from_spec(spec)
spec.loader.exec_module(rob)

failures = []


def check(ok, msg):
    print(("PASS " if ok else "FAIL ") + msg)
    if not ok:
        failures.append(msg)


def load_count_table(path):
    """Python port of load_count_table() in code/R/loaders/common.R."""
    with gzip.open(path, "rt") as fh:
        hdr = fh.readline().rstrip("\n").split("\t")
        row1 = fh.readline().rstrip("\n").split("\t")
    if len(row1) == len(hdr) + 1:
        raw = pd.read_csv(path, sep="\t", skiprows=1, header=None, names=["gene_id"] + hdr,
                          low_memory=False)
    else:
        raw = pd.read_csv(path, sep="\t", low_memory=False)
    raw.columns = [str(c).strip('"') for c in raw.columns]
    gene_col = raw.columns[0]
    meta = [c for c in ("Chr", "Start", "End", "Strand", "Length") if c in raw.columns]
    if len(meta) >= 3:
        raw = raw.drop(columns=meta)
    raw.columns = [re.sub(r"\.bam$", "", c) for c in raw.columns]
    genes = raw[gene_col].astype(str).str.strip('"')
    mat = raw.drop(columns=[gene_col]).apply(pd.to_numeric, errors="coerce").fillna(0)
    mat.index = genes
    return mat.groupby(level=0, sort=False).sum().astype(np.int64)


def strip_version(index):
    return index.str.replace(r"\.[0-9]+$", "", regex=True)


def series_field(path, prefix):
    with gzip.open(path, "rt") as fh:
        lines = [ln.rstrip("\n") for ln in fh if ln.startswith(prefix + "\t")]
    assert len(lines) == 1, prefix
    return [f.strip('"') for f in lines[0].split("\t")[1:]]


def cohort(gse):
    """Counts (genes x samples) and group (1 = patient), selected as in code/R/loaders/."""
    if gse == "GSE152004":
        m = load_count_table(RAW / gse / "GSE152004_695_raw_counts.txt.gz")
        grp = None                                   # taken from points.csv (asthma status)
    elif gse == "GSE121212":
        m = load_count_table(RAW / gse / "GSE121212_readcount.txt.gz")
        keep = [c for c in m.columns if re.match(r"^AD_[0-9]+_lesional$|^AD_[0-9]+_chronic_lesion$|^CTRL_", c)]
        m = m[keep]
        grp = pd.Series([0 if c.startswith("CTRL_") else 1 for c in keep], index=keep)
    elif gse == "GSE246323":
        m = load_count_table(RAW / gse / "GSE246323_Kleuskens_RNAseq_readcounts.txt.gz")
        m.index = strip_version(m.index)
        keep = [c for c in m.columns if re.search(r"_bsl1_count$|^C[0-9]+_count$", c)]
        m = m[keep]
        grp = pd.Series([0 if re.match(r"^C[0-9]+_count$", c) else 1 for c in keep], index=keep)
    elif gse == "GSE136825":
        m = load_count_table(RAW / gse / "GSE136825_genecounts_20190903.txt.gz")
        m.index = strip_version(m.index)
        sm_path = RAW / gse / "GSE136825_series_matrix.txt.gz"
        tissue = dict(zip(series_field(sm_path, "!Sample_description"),
                          series_field(sm_path, "!Sample_source_name_ch1")))
        keep = [c for c in m.columns if tissue[c] in ("Nasal Polyp Tissue", "Control Inferior Turbinate")]
        m = m[keep]
        grp = pd.Series([1 if tissue[c] == "Nasal Polyp Tissue" else 0 for c in keep], index=keep)
    return m, grp


def size_factors(m):
    """DESeq2 median-of-ratios on the matrix passed in."""
    logm = np.log(m.to_numpy(dtype=float))
    with np.errstate(divide="ignore", invalid="ignore"):
        lgm = logm.mean(axis=1)
        ok = np.isfinite(lgm)
        return np.exp(np.median(logm[ok] - lgm[ok, None], axis=0))


def nb_wald(y, g, sf):
    X = sm.add_constant(g.astype(float))
    fit = sm.NegativeBinomial(y, X, offset=np.log(sf), loglike_method="nb2").fit(
        method="newton", maxiter=200, disp=0)
    if not fit.mle_retvals.get("converged", True):
        fit = sm.NegativeBinomial(y, X, offset=np.log(sf), loglike_method="nb2").fit(
            method="bfgs", maxiter=2000, disp=0)
    b, se = fit.params[1], fit.bse[1]
    return b / np.log(2), se / np.log(2), 2 * stats.norm.sf(abs(b / se)), fit.params[-1]


def main():
    pts = pd.read_csv(ROOT / "results/tables/bulkmask/points.csv")
    deg = pd.read_csv(ROOT / "results/tables/ALL_focal_genes_deg.csv")
    starts, s = {}, 0
    for gse, n in rob.COHORTS:
        starts[gse] = pts.iloc[s:s + n].reset_index(drop=True)
        s += n

    rows = []
    for gse in ("GSE152004", "GSE121212", "GSE246323", "GSE136825"):
        m, grp = cohort(gse)
        if gse in starts:
            p = starts[gse]
            if grp is None:
                grp = pd.Series(p.group_bin.to_numpy(), index=p.sample_id.astype(str))
            check(sorted(grp.index) == sorted(p.sample_id.astype(str)),
                  f"{gse}: samples equal points.csv ({len(grp)})")
            check(bool((grp.loc[p.sample_id.astype(str)].to_numpy() == p.group_bin.to_numpy()).all()),
                  f"{gse}: groups equal points.csv")
        m = m[grp.index]
        m = m[m.sum(axis=1) >= 10]
        sf = size_factors(m)
        for gene, ids in IDS.items():
            hit = [i for i in m.index if i in ids]
            pub = deg[(deg.dataset == gse) & deg.gene.isin(ids)]
            if not hit:
                print(f"skip {gse} {gene}: below the count filter")
                continue
            y = m.loc[hit[0]].to_numpy(dtype=float)
            if gse in starts:
                col = "exposure" if gene == "IDI2-AS1" else "outcome"
                p = starts[gse].set_index(starts[gse].sample_id.astype(str))
                rho = stats.spearmanr(y / sf, p.loc[m.columns, col]).statistic
                check(rho > 0.999, f"{gse} {gene}: normalized counts rank as published vst (rho = {rho:.5f})")
            lfc, se, pval, alpha = nb_wald(y, grp.to_numpy(), sf)
            rows.append(dict(gene=gene, dataset=gse, model="NB GLM (unshrunken)",
                             n_patient=int(grp.sum()), n_control=int((1 - grp).sum()),
                             zero_samples=int((y == 0).sum()), dispersion=alpha,
                             log2FC=lfc, SE=se, ci_lo=lfc - 1.959964 * se, ci_hi=lfc + 1.959964 * se,
                             p=pval, p_published=float(pub.pvalue.iloc[0]) if len(pub) else np.nan,
                             log2FC_apeglm=float(pub.log2FC.iloc[0]) if len(pub) else np.nan,
                             mde80_log2=Z80 * se))
    # FPKM series: the published limma-trend estimate and ordinary SE are already unshrunken
    for gene, ids in IDS.items():
        pub = deg[(deg.dataset == "GSE58640") & deg.gene.isin(ids)].iloc[0]
        df = 16 - 2
        tc = stats.t.ppf(0.975, df)
        f = lambda d: stats.nct.sf(tc, df, d / pub.lfcSE) + stats.nct.cdf(-tc, df, d / pub.lfcSE) - 0.80
        from scipy.optimize import brentq
        rows.append(dict(gene=gene, dataset="GSE58640", model="limma-trend (published)",
                         n_patient=10, n_control=6, zero_samples=np.nan, dispersion=np.nan,
                         log2FC=pub.log2FC, SE=pub.lfcSE,
                         ci_lo=pub.log2FC - stats.t.ppf(0.975, df) * pub.lfcSE,
                         ci_hi=pub.log2FC + stats.t.ppf(0.975, df) * pub.lfcSE,
                         p=pub.pvalue, p_published=pub.pvalue, log2FC_apeglm=np.nan,
                         mde80_log2=brentq(f, 1e-6, 6 * pub.lfcSE)))
    de = pd.DataFrame(rows)

    # positive controls for the pooling routines, then the unshrunken pooling
    # (same estimators and formulas as code/python/16_revision_robustness.py, section 5)
    meta_pub = pd.read_csv(ROOT / "results/tables/Table_meta_analysis_summary.csv")
    rew_pub = pd.read_csv(ROOT / "results/tables/revision_2026_11/meta_reweighting.csv")
    mrows = []
    for gene in IDS:
        inp = deg[deg.gene.isin(IDS[gene])]
        r = rob.reml(inp.log2FC.to_numpy(), inp.lfcSE.to_numpy() ** 2)
        pub = meta_pub[meta_pub.gene == gene].iloc[0]
        check(abs(r["mu"] - pub.pooled_log2FC) <= 1e-9 + 1e-6 * abs(pub.pooled_log2FC),
              f"{gene}: REML on the apeglm-SD inputs reproduces the earlier (superseded) pooled estimate")
        n_pub = np.array([rob.N_DE[g] for g in inp.dataset])
        z_pub = np.sum(np.sqrt(n_pub) * np.sign(inp.log2FC.to_numpy()) * stats.norm.isf(inp.pvalue.to_numpy() / 2)) / np.sqrt(n_pub.sum())
        z_ref = rew_pub[(rew_pub.gene == gene) & rew_pub.analysis.str.startswith("Stouffer")].estimate.iloc[0]
        check(abs(z_pub - z_ref) < 1e-9, f"{gene}: Stouffer's Z reproduces {z_ref:.3f} in meta_reweighting.csv")
        mrows.append(dict(gene=gene, analysis="REML, apeglm posterior SDs as SEs (superseded)", k=len(inp),
                          estimate=r["mu"], lo=r["lo"], hi=r["hi"], p=r["p"], tau2=r["tau2"], I2=r["I2"],
                          max_weight_pct=100 * r["w"].max(),
                          max_weight_dataset=inp.dataset.to_numpy()[r["w"].argmax()]))

        d = de[de.gene == gene].reset_index(drop=True)
        y, v = d.log2FC.to_numpy(), d.SE.to_numpy() ** 2
        n = np.array([rob.N_DE[g] for g in d.dataset], dtype=float)
        fit = rob.reml(y, v)                                    # metafor REML defaults
        mrows.append(dict(gene=gene, analysis="REML", k=len(d), estimate=fit["mu"], lo=fit["lo"], hi=fit["hi"],
                          p=fit["p"], tau2=fit["tau2"], I2=fit["I2"], Q_p=fit["Qp"],
                          max_weight_pct=100 * fit["w"].max(),
                          max_weight_dataset=d.dataset[int(fit["w"].argmax())]))
        for lab, ww in (("Equal weights", np.ones(len(y))), ("Sample-size weights", n)):
            ww = ww / ww.sum()
            est = float(np.sum(ww * y))
            se = float(np.sqrt(np.sum(ww ** 2 * (v + fit["tau2"]))))
            mrows.append(dict(gene=gene, analysis=lab, k=len(d), estimate=est, lo=est - 1.959964 * se,
                              hi=est + 1.959964 * se, p=float(2 * stats.norm.sf(abs(est / se)))))
        for j, g in enumerate(d.dataset):
            keep = np.arange(len(y)) != j
            f2 = rob.reml(y[keep], v[keep])
            mrows.append(dict(gene=gene, analysis=f"REML, {g} left out", k=int(keep.sum()), estimate=f2["mu"],
                              lo=f2["lo"], hi=f2["hi"], p=f2["p"], tau2=f2["tau2"], I2=f2["I2"]))
        zi = np.sign(y) * stats.norm.isf(d.p_published.to_numpy() / 2)   # DESeq2 / limma Wald p values
        Z = float(np.sum(np.sqrt(n) * zi) / np.sqrt(n.sum()))
        mrows.append(dict(gene=gene, analysis="Stouffer weighted Z (sqrt n)", k=len(d), estimate=Z,
                          p=float(2 * stats.norm.sf(abs(Z)))))
    meta = pd.DataFrame(mrows)

    OUT.mkdir(parents=True, exist_ok=True)
    de.to_csv(OUT / "unshrunken_de.csv", index=False)
    meta.to_csv(OUT / "unshrunken_meta.csv", index=False)
    with pd.option_context("display.width", 200, "display.max_columns", 30):
        print(de[["gene", "dataset", "n_patient", "n_control", "zero_samples", "log2FC", "SE",
                  "p", "p_published", "mde80_log2"]].round(4).to_string(index=False))
        print(meta[["gene", "analysis", "k", "estimate", "lo", "hi", "p", "I2", "max_weight_pct"]].round(4).to_string(index=False))
    if failures:
        sys.exit(f"{len(failures)} check(s) failed")


if __name__ == "__main__":
    main()
