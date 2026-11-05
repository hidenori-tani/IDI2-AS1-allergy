#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Add `conditioners_used` to results/tables/bulkmask/correlations.csv.

The pipeline now records which conditioners `partial_corr()` actually used. For a
table written before that change, rather than hand-editing the file, this
derives the column from points.csv -- the same per-sample values the pipeline
conditioned on -- and rewrites the table with every rho, p and n byte-identical.
The shipped table already has the column (added by this script on 2026-08-31);
run on it, the script only checks the column and does not rewrite the file.

It also re-derives every rho independently (rank-transform + inverse correlation
matrix) and refuses to write unless all of them reproduce the shipped values, so
the annotation cannot quietly disagree with the numbers it annotates.

    python3 scripts/annotate_correlations_used.py [--write]
"""
from __future__ import annotations

import argparse
import csv
import math
import pathlib
import sys

POINTS = pathlib.Path("results/tables/bulkmask/points.csv")
CORRS = pathlib.Path("results/tables/bulkmask/correlations.csv")

# model name -> the covariate columns the pipeline passes to partial_corr()
MODELS = {
    "raw": [],
    "adj_marker": ["sig_eosinophil"],
    "adj_xcellraw": ["eos_xcell_raw"],
    "adj_gsva": ["eos_gsva"],
    "adj_marker+group": ["sig_eosinophil", "group_bin"],
    "adj_marker+th2": ["sig_eosinophil", "sig_th2"],
    "adj_neutrophil(neg.ctrl)": ["sig_neutrophil"],
}
# the pipeline's internal names for those covariates, in the same order
NAMES = {
    "sig_eosinophil": "eos", "group_bin": "grp", "sig_th2": "th2",
    "sig_neutrophil": "neu", "eos_xcell_raw": "eos", "eos_gsva": "eos",
}
TOL = 2e-3


def cohort(sample_id: str) -> str:
    if sample_id.startswith(("HR", "SJ")):
        return "GSE152004"
    if sample_id.startswith("RHP"):
        return "GSE136825"
    if sample_id.startswith(("AD_", "CTRL_")):
        return "GSE121212"
    return "GSE58640"


def num(v: str) -> float:
    return float("nan") if v in ("NA", "") else float(v)


def rank(a):
    import numpy as np
    a = np.asarray(a, float)
    order = a.argsort()
    r = np.empty(len(a))
    r[order] = np.arange(1, len(a) + 1)
    out = np.empty(len(a))
    for v in set(a.tolist()):
        m = a == v
        out[m] = r[m].mean()
    return out


def _betacf(a, b, x):
    MAXIT, EPS, FPMIN = 300, 3e-14, 1e-300
    qab, qap, qam = a + b, a + 1, a - 1
    c, d = 1.0, 1 - qab * x / qap
    d = 1 / (FPMIN if abs(d) < FPMIN else d)
    h = d
    for m in range(1, MAXIT + 1):
        m2 = 2 * m
        aa = m * (b - m) * x / ((qam + m2) * (a + m2))
        d = 1 + aa * d
        d = 1 / (FPMIN if abs(d) < FPMIN else d)
        c = 1 + aa / c
        c = FPMIN if abs(c) < FPMIN else c
        h *= d * c
        aa = -(a + m) * (qab + m) * x / ((a + m2) * (qap + m2))
        d = 1 + aa * d
        d = 1 / (FPMIN if abs(d) < FPMIN else d)
        c = 1 + aa / c
        c = FPMIN if abs(c) < FPMIN else c
        de = d * c
        h *= de
        if abs(de - 1) < EPS:
            break
    return h


def _betainc(a, b, x):
    if x <= 0:
        return 0.0
    if x >= 1:
        return 1.0
    bt = math.exp(math.lgamma(a + b) - math.lgamma(a) - math.lgamma(b)
                  + a * math.log(x) + b * math.log(1 - x))
    if x < (a + 1) / (a + b + 2):
        return bt * _betacf(a, b, x) / a
    return 1 - bt * _betacf(b, a, 1 - x) / b


def pcor(x, y, Z):
    """ppcor::pcor.test(method="spearman") equivalent."""
    import numpy as np
    M = np.column_stack([rank(x), rank(y)] + [rank(z) for z in Z])
    Pm = np.linalg.inv(np.corrcoef(M, rowvar=False))
    r = -Pm[0, 1] / math.sqrt(Pm[0, 0] * Pm[1, 1])
    n, k = len(x), len(Z)
    df = n - 2 - k
    t = r * math.sqrt(df / max(1e-300, 1 - r * r))
    xx = df / (df + t * t)
    p = _betainc(df / 2, 0.5, xx)
    return r, p, n


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--write", action="store_true")
    a = ap.parse_args()

    pts = list(csv.DictReader(POINTS.open()))
    for r in pts:
        r["ds"] = cohort(r["sample_id"])
    shipped = list(csv.DictReader(CORRS.open()))

    used_map, bad = {}, []
    for row in shipped:
        ds, model = row["dataset"], row["model"]
        rows = [r for r in pts if r["ds"] == ds]
        Z, used = [], []
        for c in MODELS[model]:
            z = [num(r[c]) for r in rows]
            if all(math.isnan(v) for v in z):
                continue
            lo, hi = min(v for v in z if not math.isnan(v)), max(v for v in z if not math.isnan(v))
            if lo == hi:
                continue
            Z.append(z)
            used.append(NAMES[c])
        x = [num(r["exposure"]) for r in rows]
        y = [num(r["outcome"]) for r in rows]
        keep = [i for i in range(len(x))
                if not math.isnan(x[i]) and not math.isnan(y[i])
                and all(not math.isnan(z[i]) for z in Z)]
        r_, p_, n_ = pcor([x[i] for i in keep], [y[i] for i in keep],
                          [[z[i] for i in keep] for z in Z])
        if abs(r_ - float(row["rho"])) > TOL or n_ != int(row["n"]):
            bad.append(f"{ds}/{model}: recomputed rho={r_:+.4f} n={n_} vs shipped rho={float(row['rho']):+.4f} n={row['n']}")
        used_map[(ds, model)] = "+".join(used)

    print(f"Reproduction check: {len(bad)} of {len(shipped)} rows differ")
    for b in bad:
        print("  MISMATCH", b)
    if bad:
        return 1

    print("\nRows whose label names a conditioner that was not used:")
    dropped = 0
    for row in shipped:
        want = [NAMES[c] for c in MODELS[row["model"]]]
        got = used_map[(row["dataset"], row["model"])]
        got_l = got.split("+") if got else []
        if want != got_l:
            dropped += 1
            print(f"  MISMATCH {row['dataset']:11} {row['model']:26} expected={'+'.join(want) or '(none)':16} used={got or '(none)'}")
    if dropped == 0:
        print("  none")

    fields = list(shipped[0].keys())
    if "conditioners_used" in fields:
        differ = [f"{r['dataset']}/{r['model']}" for r in shipped
                  if r["conditioners_used"] != used_map[(r["dataset"], r["model"])]]
        print(f"\nconditioners_used is already in the table; {len(differ)} rows differ from "
              "the derived values; the file is not rewritten")
        for d in differ:
            print("  DIFFERS", d)
        return 1 if differ else 0

    if not a.write:
        print("\n(dry run) add --write to write the file")
        return 0

    fields.insert(fields.index("dataset"), "conditioners_used")
    with CORRS.open("w", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=fields, quoting=csv.QUOTE_NONNUMERIC)
        w.writeheader()
        for row in shipped:
            out = dict(row)
            out["conditioners_used"] = used_map[(row["dataset"], row["model"])]
            out["rho"] = float(out["rho"])
            out["p"] = float(out["p"])
            out["n"] = int(out["n"])
            w.writerow(out)
    print(f"\nWrote {CORRS} (rho, p and n unchanged; one column added)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
