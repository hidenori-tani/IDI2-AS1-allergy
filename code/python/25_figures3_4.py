"""Figures 3 and 4: per-sample IDI2-AS1 versus
IL5 (Figure 3; Figure 4A) and versus the eosinophil marker score (Figure 4B) in the four cohorts in
which both transcripts were quantified.

Why redrawn: the earlier Figures 3 and 4 were ggplot2 panels from a separate R path
(code/R/07_correlation_analysis_v2.R, 09_celltype_adjusted_correlation_v2.R, 09b_fig4_replot_v2.R).
Here, as for Figure S1, they are drawn from the per-sample table behind Table 2 and Table S5
(results/tables/bulkmask/points.csv, row order = rbind order of the pipeline), so the figures and
the tables share one computation.

Lines are ordinary least-squares fits with 95% confidence bands, drawn for display; the reported
associations are Spearman correlations (Table 2A), printed in each panel heading.

Output: results/figures/submission_figs/Figure3.pdf, Figure4.pdf (+ .png previews)
Run from the repository root:  python3 code/python/25_figures3_4.py
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
# (GSE, rows in points.csv, panel heading, unit of the expression values)
COHORTS = [("GSE152004", 695, "Asthma (GSE152004)", "vst"),
           ("GSE121212", 65, "AD (GSE121212)", "vst"),
           ("GSE58640", 16, "EoE (GSE58640)", "fpkm"),
           ("GSE136825", 70, "CRSwNP (GSE136825)", "vst")]
GROUPS = (("control", OKABE_ITO["blue"], "o"), ("patient", OKABE_ITO["vermillion"], "^"))


def label(gene, unit):
    return f"{gene} (vst)" if unit == "vst" else f"{gene}, log2(FPKM + 1)"


def cohorts():
    pts = pd.read_csv("results/tables/bulkmask/points.csv")
    assert len(pts) == sum(n for _, n, _, _ in COHORTS), "points.csv rows differ from the cohort sizes"
    start, out = 0, []
    for gse, n, head, unit in COHORTS:
        d = pts.iloc[start:start + n]
        start += n
        assert d[["exposure", "outcome", "sig_eosinophil"]].notna().all().all(), f"{gse}: missing values"
        out.append((gse, n, head, unit, d))
    return out


def panel(ax, d, x, y, head, n, xlab, ylab):
    # colour and marker shape both encode the group (readable in greyscale); the key is in the legend text
    for grp, col, mk in GROUPS:
        s = d[d.group == grp]
        ax.scatter(s[x], s[y], s=4 if n > 100 else 9, alpha=0.5 if n > 100 else 0.8, color=col, marker=mk,
                   linewidths=0, rasterized=n > 100)
    # least-squares line with its 95% confidence band (display only)
    xv, yv = d[x].to_numpy(float), d[y].to_numpy(float)
    b, a = np.polyfit(xv, yv, 1)
    gx = np.linspace(xv.min(), xv.max(), 100)
    resid = yv - (a + b * xv)
    s2 = resid @ resid / (n - 2)
    se = np.sqrt(s2 * (1 / n + (gx - xv.mean()) ** 2 / ((xv - xv.mean()) ** 2).sum()))
    t = stats.t.ppf(0.975, n - 2)
    ax.fill_between(gx, a + b * gx - t * se, a + b * gx + t * se, color="0.6", alpha=0.35, linewidth=0)
    ax.plot(gx, a + b * gx, color=OKABE_ITO["black"], lw=0.8)
    rho = stats.spearmanr(xv, yv).statistic
    # the statistics go in the panel heading, clear of the data and the axes
    ax.set_title(f"{head}\nρ = {rho:.2f}, n = {n}".replace("-", "−").replace("IDI2−AS1", "IDI2-AS1"),
                 fontsize=7, pad=3, linespacing=1.3)
    ax.set_xlabel(xlab)
    ax.set_ylabel(ylab)
    return rho


def figure3(data):
    W, H = 180.0, 136.0
    fig = plt.figure(figsize=(mm(W), mm(H)))
    rows = []
    for i, (gse, n, head, unit, d) in enumerate(data):
        col, row = i % 2, i // 2
        ax = fig.add_axes([(17 + col * 88) / W, (78 - row * 64) / H, 66 / W, 44 / H])
        rho = panel(ax, d, "exposure", "outcome", head, n, label("IDI2-AS1", unit), label("IL5", unit))
        rows.append((gse, n, rho))
    savefig(fig, str(OUT / "Figure3"))
    plt.close(fig)
    return rows


def figure4(data):
    W, H = 180.0, 122.0
    fig = plt.figure(figsize=(mm(W), mm(H)))
    rows = []
    for r, (y, letter, y0) in enumerate((("outcome", "A", 74), ("sig_eosinophil", "B", 12))):
        for i, (gse, n, head, unit, d) in enumerate(data):
            ax = fig.add_axes([(13 + i * 44.5) / W, y0 / H, 30.5 / W, 34 / H])
            ylab = label("IL5", unit) if y == "outcome" else "Eosinophil score (mean z)"
            rho = panel(ax, d, "exposure", y, head, n, label("IDI2-AS1", unit), ylab)
            rows.append((letter, gse, n, rho))
        fig.text(1 / W, (y0 + 42) / H, letter, fontweight="bold", fontsize=10, va="bottom")
    savefig(fig, str(OUT / "Figure4"))
    plt.close(fig)
    return rows


def main():
    use_journal_style()
    OUT.mkdir(parents=True, exist_ok=True)
    data = cohorts()
    for gse, n, rho in figure3(data):
        print(f"Figure 3  {gse}: n = {n}, Spearman rho(IDI2-AS1, IL5) = {rho:+.3f}")
    for letter, gse, n, rho in figure4(data):
        what = "IL5" if letter == "A" else "eosinophil marker score"
        print(f"Figure 4{letter} {gse}: n = {n}, Spearman rho(IDI2-AS1, {what}) = {rho:+.3f}")
    print("wrote", OUT / "Figure3.pdf", "and", OUT / "Figure4.pdf")


if __name__ == "__main__":
    main()
