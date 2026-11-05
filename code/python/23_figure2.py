"""Figure 2: patient-versus-control
differential expression of IDI2-AS1 (A) and IL5 (B) with unshrunken per-cohort estimates.

Why redrawn: the earlier Figure 2 (code/R/06_meta_analysis.R, metafor forest plots) pooled apeglm
posterior modes weighted by apeglm posterior standard deviations. Those deviations are shrunken
(0.00144 for 87% of the genes in GSE136825, including IDI2-AS1 and IL5), so that cohort carries 99.1% of
the IDI2-AS1 weight (34.0% of the IL5 weight). Here every
cohort enters with its unshrunken log2 fold change and Wald standard error
(code/python/21_unshrunken_de_power.py), and the pooled estimate is REML with metafor's defaults.
Square size increases with the random-effects weight (area 8 + 70 w, in pt^2), which is also printed.
An interval wider than the axis ends in an arrowhead at the axis end; its full value is printed.

Inputs: results/tables/revision_2026_11/unshrunken_de.csv, unshrunken_meta.csv
Output: results/figures/submission_figs/Figure2.pdf (+ .png preview)
Run from the repository root:  python3 code/python/23_figure2.py
"""
from pathlib import Path
import importlib.util
import sys

import numpy as np
import pandas as pd

sys.path.insert(0, str(Path(__file__).resolve().parent))
from figstyle import OKABE_ITO, mm, savefig, use_journal_style  # noqa: E402
import matplotlib.pyplot as plt  # noqa: E402
from matplotlib.patches import Polygon  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "results" / "figures" / "submission_figs"
W, H = 180.0, 104.0
AX0, AW = 60.0, 66.0                      # plot area (mm); text columns are placed in mm too
X_CI, X_W = (129.0 - AX0) / AW, (177.0 - AX0) / AW
COHORT_ORDER = [("GSE152004", "Asthma"), ("GSE121212", "Atopic dermatitis"), ("GSE246323", "EoE"),
         ("GSE58640", "EoE"), ("GSE136825", "CRSwNP")]

spec = importlib.util.spec_from_file_location("rob", ROOT / "code/python/16_revision_robustness.py")
rob = importlib.util.module_from_spec(spec)
spec.loader.exec_module(rob)


def num(v):
    """Signed two-decimal number with a true minus sign, as on the axes."""
    return f"{v:+.2f}".replace("-", "\u2212")


def panel(fig, y0, h, gene, de, meta, xlim, xticks):
    ax = fig.add_axes([AX0 / W, y0 / H, AW / W, h / H])
    d = de[de.gene == gene].set_index("dataset")
    rows = [(g, lab) for g, lab in COHORT_ORDER if g in d.index]
    r = rob.reml(d.loc[[g for g, _ in rows], "log2FC"].to_numpy(), d.loc[[g for g, _ in rows], "SE"].to_numpy() ** 2)
    m = meta[(meta.gene == gene) & (meta.analysis == "REML")].iloc[0]
    assert abs(r["mu"] - m.estimate) < 1e-12, "pooled estimate differs from unshrunken_meta.csv"
    n = len(rows)
    ys = np.arange(n, 0, -1) + 1.0                       # cohorts at the top, pooled row at y = 1
    for (g, lab), y, w in zip(rows, ys, r["w"]):
        e = d.loc[g]
        # an interval wider than the axis is cut at the axis end and marked with an arrowhead there;
        # the full interval is printed in the text column
        lo, hi = max(e.ci_lo, xlim[0]), min(e.ci_hi, xlim[1])
        ax.plot([lo, hi], [y, y], color=OKABE_ITO["black"], lw=0.8, solid_capstyle="butt")
        for cut, end, mk in ((e.ci_lo < xlim[0], xlim[0], "<"), (e.ci_hi > xlim[1], xlim[1], ">")):
            if cut:
                ax.plot([end], [y], marker=mk, markersize=3.2, color=OKABE_ITO["black"], clip_on=False,
                        linestyle="none", markeredgewidth=0)
        ax.scatter([e.log2FC], [y], marker="s", s=8 + 70 * w, color=OKABE_ITO["black"], zorder=3,
                   linewidths=0)
        ax.text(-0.03, y, f"{lab}, {g} ({int(e.n_patient)}/{int(e.n_control)})", transform=ax.get_yaxis_transform(),
                ha="right", va="center")
        ax.text(X_CI, y, f"{num(e.log2FC)} [{num(e.ci_lo)}, {num(e.ci_hi)}]", transform=ax.get_yaxis_transform(),
                ha="left", va="center")
        wtxt = "<1%" if 100 * w < 0.5 else f"{100 * w:.0f}%"      # a weight that rounds to 0 is not an exclusion
        ax.text(X_W, y, wtxt, transform=ax.get_yaxis_transform(), ha="right", va="center")
    ax.add_patch(Polygon([(r["lo"], 1), (r["mu"], 1.28), (r["hi"], 1), (r["mu"], 0.72)], closed=True,
                         facecolor=OKABE_ITO["blue"], edgecolor=OKABE_ITO["blue"]))
    ax.text(-0.03, 1, f"Random effects (REML), I² = {r['I2']:.0f}%", transform=ax.get_yaxis_transform(),
            ha="right", va="center", fontweight="bold")
    ax.text(X_CI, 1, f"{num(r['mu'])} [{num(r['lo'])}, {num(r['hi'])}]", transform=ax.get_yaxis_transform(),
            ha="left", va="center", fontweight="bold")
    ax.text(X_W, 1, "100%", transform=ax.get_yaxis_transform(), ha="right", va="center", fontweight="bold")
    top = n + 1.9
    ax.text(-0.03, top, "Cohort (patients/controls)", transform=ax.get_yaxis_transform(), ha="right",
            va="center", fontweight="bold")
    ax.text(X_CI, top, "log2FC [95% CI]", transform=ax.get_yaxis_transform(), ha="left", va="center",
            fontweight="bold")
    ax.text(X_W, top, "Weight", transform=ax.get_yaxis_transform(), ha="right", va="center",
            fontweight="bold")
    ax.axvline(0, color=OKABE_ITO["black"], lw=0.6, ls=(0, (3, 2)))
    ax.set_xlim(*xlim)
    ax.set_xticks(xticks)
    ax.set_ylim(0.4, n + 2.4)
    ax.set_yticks([])
    for s in ("left", "right", "top"):
        ax.spines[s].set_visible(False)
    ax.set_xlabel("log2 fold change, patient vs control")
    return r


def figure2():
    de = pd.read_csv(ROOT / "results/tables/revision_2026_11/unshrunken_de.csv")
    meta = pd.read_csv(ROOT / "results/tables/revision_2026_11/unshrunken_meta.csv")
    use_journal_style()
    fig = plt.figure(figsize=(mm(W), mm(H)))
    panel(fig, 62, 36, "IDI2-AS1", de, meta, (-3.2, 1.2), [-3, -2, -1, 0, 1])
    fig.text(2 / W, 100 / H, "A", fontweight="bold", fontsize=10, va="top")
    panel(fig, 11, 30, "IL5", de, meta, (-1.6, 1.6), [-1.5, -1, -0.5, 0, 0.5, 1, 1.5])
    fig.text(2 / W, 47 / H, "B", fontweight="bold", fontsize=10, va="top")
    OUT.mkdir(parents=True, exist_ok=True)
    paths = savefig(fig, str(OUT / "Figure2"))
    print("wrote", ", ".join(str(Path(p).relative_to(ROOT)) for p in paths))


if __name__ == "__main__":
    figure2()
