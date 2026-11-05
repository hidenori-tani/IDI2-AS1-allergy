"""Figure 6, redrawn on the full asthma
cohort (GSE152004, n = 695).

Why redrawn: code/R/13b_fig6_bulkmask.R selected the asthma cohort with
grepl("^HR", sample_id), which drops the nine samples whose identifiers start with "SJ";
panels A and D and the compensated-xCell value in panel B were therefore drawn on 686
samples. Here the cohort is the first 695 rows of points.csv (row order = rbind order of
the pipeline, as in 16_revision_robustness.py).

Panels (no titles inside the figure):
  A  marker score vs xCell enrichment and vs ssGSEA (within-cohort z), Spearman rho
  B  IDI2-AS1-IL5 partial Spearman rho with 95% Fisher-z CI under each conditioning
  C  decomposition: composition-associated component and residual, 95% bootstrap CI
  D  xCell compensated vs uncompensated eosinophil score (z-scaled)

Inputs: results/tables/bulkmask/{points,decompositions}.csv and
        results/tables/revision_2026_11/partial_fisher_intervals.csv
Output: results/figures/submission_figs/Figure6.pdf (+ .png preview)
"""
from pathlib import Path
import sys

import numpy as np
import pandas as pd
from scipy import stats

sys.path.insert(0, str(Path(__file__).resolve().parent))
from figstyle import OKABE_ITO, mm, savefig, use_journal_style  # noqa: E402
import matplotlib.pyplot as plt  # noqa: E402

OUT = Path("results/figures/submission_figs")
W, H = 180.0, 132.0


def z(x):
    x = np.asarray(x, float)
    return (x - x.mean()) / x.std(ddof=1)


def figure6():
    pts = pd.read_csv("results/tables/bulkmask/points.csv")
    ast = pts.iloc[:695].reset_index(drop=True)
    assert len(ast) == 695 and ast.sample_id.str.match(r"^(HR|SJ)").all()
    part = pd.read_csv("results/tables/revision_2026_11/partial_fisher_intervals.csv")
    part = part[part.dataset == "GSE152004"].set_index("model")
    dec = pd.read_csv("results/tables/bulkmask/decompositions.csv")
    dec = dec[(dec.dataset == "GSE152004") & (dec.adjusted == "none")].set_index("estimator")

    use_journal_style()
    fig = plt.figure(figsize=(mm(W), mm(H)))

    def axes(x0, y0, w, h):
        return fig.add_axes([x0 / W, y0 / H, w / W, h / H])

    # ---- A: concordance (two small panels) ----
    xa = z(ast.sig_eosinophil)
    a_axes = [axes(14, 74, 34, 42), axes(58, 74, 34, 42)]
    for ax, col, lab in zip(a_axes, ["eos_xcell_raw", "eos_gsva"],
                            ["xCell enrichment (z)", "ssGSEA enrichment (z)"]):
        yv = z(ast[col])
        rho = stats.spearmanr(ast.sig_eosinophil, ast[col])[0]
        ax.scatter(xa, yv, s=2, alpha=0.35, color=OKABE_ITO["blue"], linewidths=0, rasterized=True)
        slope, icpt = np.polyfit(xa, yv, 1)
        xs = np.array([xa.min(), xa.max()])
        ax.plot(xs, icpt + slope * xs, color=OKABE_ITO["vermillion"], lw=0.8)
        ax.set_xlabel("Marker score (z)")
        ax.set_ylabel(lab)
        ax.text(0.04, 0.96, f"ρ = {rho:.2f}", transform=ax.transAxes, ha="left", va="top")
    fig.text(2 / W, 118 / H, "A", fontweight="bold", fontsize=10, va="bottom")

    # ---- B: partial correlations with 95% CI ----
    axb = axes(128, 74, 48, 42)
    rows = [("Unadjusted", "raw"), ("Marker score", "adj_marker"), ("xCell", "adj_xcellraw"),
            ("ssGSEA", "adj_gsva"), ("xCell, compensated", "adj_xcellcomp"),
            ("Th2 signature", "adj_th2_only"), ("Neutrophil signature", "adj_neutrophil(neg.ctrl)")]
    ypos = np.arange(len(rows))[::-1]
    for y, (lab, key) in zip(ypos, rows):
        r = part.loc[key]
        col = OKABE_ITO["black"] if key in ("raw", "adj_neutrophil(neg.ctrl)") else OKABE_ITO["bluish_green"]
        axb.errorbar(r.rho, y, xerr=[[r.rho - r.fisher_lo], [r.fisher_hi - r.rho]], fmt="o", ms=3,
                     color=col, ecolor=col, elinewidth=0.8, capsize=1.5)
    axb.axvline(0, color="0.5", lw=0.5)
    axb.set_yticks(ypos)
    axb.set_yticklabels([lab for lab, _ in rows])
    axb.set_xlabel("Partial Spearman ρ (95% CI)")
    axb.set_ylim(-0.7, len(rows) - 0.3)
    fig.text(98 / W, 118 / H, "B", fontweight="bold", fontsize=10, va="bottom")

    # ---- C: decomposition ----
    axc = axes(14, 14, 70, 44)
    est = [("Marker score", "marker"), ("ssGSEA", "gsva"), ("xCell", "xcellraw")]
    for i, (lab, key) in enumerate(est):
        r = dec.loc[key]
        axc.errorbar(i - 0.12, r.ACME, yerr=[[r.ACME - r.ACME_lo], [r.ACME_hi - r.ACME]], fmt="o", ms=3.5,
                     color=OKABE_ITO["blue"], elinewidth=0.8, capsize=2,
                     label="Composition-associated" if i == 0 else None)
        axc.errorbar(i + 0.12, r.ADE, yerr=[[r.ADE - r.ADE_lo], [r.ADE_hi - r.ADE]], fmt="o", ms=3.5,
                     mfc="white", color=OKABE_ITO["vermillion"], elinewidth=0.8, capsize=2,
                     label="Residual" if i == 0 else None)
        axc.text(i, 0.235, f"{r.prop_mediated:.2f}", ha="center", va="bottom")
    axc.axhline(0, color="0.5", lw=0.5)
    axc.set_xticks(range(len(est)))
    axc.set_xticklabels([lab for lab, _ in est])
    axc.set_xlim(-0.6, len(est) - 0.4)
    axc.set_ylim(-0.24, 0.27)
    axc.set_ylabel("Component (95% CI)")
    axc.legend(loc="lower center", ncol=2, frameon=False, handletextpad=0.3, columnspacing=1.2)
    fig.text(2 / W, 60 / H, "C", fontweight="bold", fontsize=10, va="bottom")

    # ---- D: compensated vs uncompensated xCell score ----
    axd = axes(104, 14, 72, 44)
    comp, raw = ast.eos_xcell_comp.values, ast.eos_xcell_raw.values
    zero = 100 * np.mean(comp == 0)
    bins = np.linspace(-2.5, 6.5, 46)
    axd.hist(z(comp), bins=bins, color=OKABE_ITO["vermillion"], alpha=0.6,
             label=f"Compensated ({zero:.0f}% zero)")
    axd.hist(z(raw), bins=bins, color=OKABE_ITO["blue"], alpha=0.6,
             label=f"Uncompensated ({100 * np.mean(raw == 0):.0f}% zero)")
    axd.set_xlabel("xCell eosinophil score (z)")
    axd.set_ylabel("Samples")
    axd.legend(loc="upper right", frameon=False)
    fig.text(90 / W, 60 / H, "D", fontweight="bold", fontsize=10, va="bottom")

    OUT.mkdir(parents=True, exist_ok=True)
    paths = savefig(fig, str(OUT / "Figure6"))
    plt.close(fig)
    print("wrote", paths)
    print(f"A: rho marker-xCell {stats.spearmanr(ast.sig_eosinophil, ast.eos_xcell_raw)[0]:.4f}, "
          f"marker-ssGSEA {stats.spearmanr(ast.sig_eosinophil, ast.eos_gsva)[0]:.4f} (n = {len(ast)})")
    print(f"D: compensated zero fraction {zero / 100:.4f}; uncompensated median {np.median(raw):.1f}")


if __name__ == "__main__":
    figure6()
