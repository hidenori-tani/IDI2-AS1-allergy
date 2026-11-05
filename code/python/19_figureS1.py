"""Figure S1: IDI2-AS1 versus the Th2
signature score in each of the four cohorts with both transcripts quantified.

Why redrawn: the earlier Figure S1 came from code/R/09_celltype_adjusted_correlation_v2.R,
a separate scoring path, with unembedded fonts and a title drawn inside the figure. Here it
is drawn from the same per-sample table as Table S5 (results/tables/bulkmask/points.csv,
row order = rbind order of the pipeline), after the 2026-11-05 alias fix gave GSE136825 a
Th2 score (scripts/rerun_bulkmask_cohorts.R).

Output: results/figures/submission_figs/FigureS1.pdf (+ .png preview)
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
W, H = 180.0, 74.0
COHORTS = [("GSE152004", 695, "Asthma (GSE152004)", "IDI2-AS1 (vst)"),
           ("GSE121212", 65, "AD (GSE121212)", "IDI2-AS1 (vst)"),
           ("GSE58640", 16, "EoE (GSE58640)", "IDI2-AS1, log2(FPKM + 1)"),
           ("GSE136825", 70, "CRSwNP (GSE136825)", "IDI2-AS1 (vst)")]


def figureS1():
    pts = pd.read_csv("results/tables/bulkmask/points.csv")
    assert len(pts) == sum(n for _, n, _, _ in COHORTS)
    use_journal_style()
    fig = plt.figure(figsize=(mm(W), mm(H)))
    start, rows = 0, []
    for i, (gse, n, label, ylab) in enumerate(COHORTS):
        d = pts.iloc[start:start + n]
        start += n
        assert d.sig_th2.notna().all(), f"{gse}: Th2 score missing"
        ax = fig.add_axes([(12 + i * 43.5) / W, 12 / H, 32 / W, 38 / H])
        # colour and marker shape both encode the group (readable in greyscale); the key is in the legend text
        for grp, col, mk in (("control", OKABE_ITO["blue"], "o"), ("patient", OKABE_ITO["vermillion"], "^")):
            s = d[d.group == grp]
            ax.scatter(s.sig_th2, s.exposure, s=4 if n > 100 else 9, alpha=0.5 if n > 100 else 0.8,
                       color=col, marker=mk, linewidths=0, rasterized=n > 100, label=grp.capitalize())
        rho, p = stats.spearmanr(d.sig_th2, d.exposure)
        rows.append((gse, n, rho, p))
        # the statistics go in the panel heading, clear of the data and the axes
        ax.set_title(f"{label}\nρ = {rho:.2f}, n = {n}".replace("-", "−").replace("IDI2−AS1", "IDI2-AS1"),
                     fontsize=7, pad=3, linespacing=1.3)
        ax.set_xlabel("Th2 signature (mean z)")
        ax.set_ylabel(ylab)
        fig.text((1 + i * 43.5) / W, 58 / H, "ABCD"[i], fontweight="bold", fontsize=10, va="bottom")
    OUT.mkdir(parents=True, exist_ok=True)
    savefig(fig, OUT / "FigureS1")
    for gse, n, rho, p in rows:
        print(f"{gse}: n = {n}, Spearman rho(IDI2-AS1, Th2) = {rho:+.3f}, p = {p:.3g}")
    return fig


if __name__ == "__main__":
    figureS1()
