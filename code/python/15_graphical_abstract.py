"""Graphical abstract for the JBI submission (Elsevier landscape format).

Single-panel visual summary, ASCII-only text (the default PDF text path can
turn Unicode glyphs into empty boxes), exported as a vector PDF plus a PNG.
Aspect ~2.5:1 (Elsevier graphical-abstract preferred ratio); 12 x 4.8 in at
300 dpi = 3600 x 1440 px, well above the 1328 x 531 px minimum.
"""
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch

W, H = 12.0, 4.8
fig = plt.figure(figsize=(W, H))
ax = fig.add_axes([0, 0, 1, 1])
ax.set_xlim(0, 12)
ax.set_ylim(0, 4.8)
ax.axis("off")

BLUE = "#1f6fb4"
RED = "#c0392b"
GREEN = "#1e8449"
GREY = "#566573"
LIGHT = {"problem": "#FDEBD0", "pipe": "#EAF2F8", "result": "#E8F8F5"}


def box(x, y, w, h, fc, ec, lw=1.2):
    ax.add_patch(FancyBboxPatch((x, y), w, h,
                 boxstyle="round,pad=0.02,rounding_size=0.06",
                 fc=fc, ec=ec, lw=lw, zorder=1))


def arrow(x0, y0, x1, y1, color=GREY, lw=2.2):
    ax.add_patch(FancyArrowPatch((x0, y0), (x1, y1),
                 arrowstyle="-|>", mutation_scale=16,
                 color=color, lw=lw, zorder=3))


# ---- Title band ----
ax.text(6.0, 4.55,
        "A cell-composition-adjusted re-analysis pipeline separates per-cell regulation "
        "from cell-composition shift in bulk RNA-seq",
        ha="center", va="center", fontsize=11.5, fontweight="bold")
ax.text(6.0, 4.2,
        "Worked example: the lncRNA IDI2-AS1 and its in vitro target IL5 across "
        "five public cohorts of type-2 allergic disease (n = 856)",
        ha="center", va="center", fontsize=9, style="italic", color=GREY)

# =================== Panel 1: the problem ===================
box(0.25, 0.45, 3.55, 3.45, LIGHT["problem"], "#E59866")
ax.text(2.02, 3.68, "THE PROBLEM", ha="center", fontsize=9.5,
        fontweight="bold", color="#A04000")
ax.text(2.02, 3.30, "Bulk tissue mixes two signals", ha="center",
        fontsize=8.6, color="#7E5109")
# cartoon: bystander field + small effector cluster
import numpy as np
rng = np.random.default_rng(7)
bx = 0.55 + rng.random(60) * 2.9
by = 1.55 + rng.random(60) * 1.35
ax.scatter(bx, by, s=14, c="#D5DBDB", edgecolors="none", zorder=2)
ex = 2.55 + rng.random(9) * 0.5
ey = 1.7 + rng.random(9) * 0.5
ax.scatter(ex, ey, s=26, c=RED, edgecolors="white", lw=0.4, zorder=2)
ax.text(0.95, 1.28, "bystander cells\n(IDI2-AS1, IL5 ~ off)", ha="center",
        fontsize=7, color=GREY)
ax.text(2.78, 1.28, "small effector\ncompartment (expands\nin disease)",
        ha="center", fontsize=7, color=RED)
ax.text(2.02, 0.72,
        "Per-cell IDI2-AS1 may fall, but the\n"
        "effector compartment expands -> the\n"
        "bulk average is masked or sign-inverted",
        ha="center", fontsize=7.3, color="#7E5109")

arrow(3.85, 2.15, 4.35, 2.15)

# =================== Panel 2: the pipeline ===================
box(4.4, 0.45, 3.2, 3.45, LIGHT["pipe"], BLUE)
ax.text(6.0, 3.68, "THE PIPELINE", ha="center", fontsize=9.5,
        fontweight="bold", color=BLUE)
ax.text(6.0, 3.34, "bulk-only, open source", ha="center", fontsize=8,
        style="italic", color=GREY)
steps = [
    "1  Differential expression\n   + random-effects meta-analysis",
    "2  Sample-level IDI2-AS1 vs IL5\n   correlation",
    "3  Cell-composition adjustment\n   (marker signature + xCell)",
    "4  Effect decomposition\n   + confounding sensitivity",
]
sy = [2.95, 2.30, 1.65, 1.00]
for s, y in zip(steps, sy):
    box(4.6, y - 0.26, 2.8, 0.52, "white", BLUE, lw=1.0)
    ax.text(4.75, y, s, ha="left", va="center", fontsize=7.2, color="#1A5276")
for i in range(len(sy) - 1):
    arrow(6.0, sy[i] - 0.27, 6.0, sy[i + 1] + 0.27, color=BLUE, lw=1.4)

arrow(7.65, 2.15, 8.15, 2.15)

# =================== Panel 3: the result ===================
box(8.2, 0.45, 3.55, 3.45, LIGHT["result"], GREEN)
ax.text(9.97, 3.68, "THE RESULT  (asthma, n = 695)", ha="center",
        fontsize=9.3, fontweight="bold", color=GREEN)

# bar: attributable fraction range 70-90%
bx0, bw, byb, bh = 8.6, 2.7, 2.55, 0.5
ax.add_patch(FancyBboxPatch((bx0, byb), bw, bh, boxstyle="square,pad=0",
             fc="#D5F5E3", ec=GREEN, lw=1.0))
ax.add_patch(FancyBboxPatch((bx0, byb), bw * 0.70, bh, boxstyle="square,pad=0",
             fc=GREEN, ec=GREEN, lw=0))
ax.add_patch(FancyBboxPatch((bx0 + bw * 0.70, byb), bw * 0.20, bh,
             boxstyle="square,pad=0", fc="#82E0AA", ec=GREEN, lw=0))
ax.text(9.97, 3.16,
        "~70-90% of the bulk IDI2-AS1-IL5\ncovariation attributable to eosinophils",
        ha="center", fontsize=7.6, color="#145A32")
ax.text(bx0 + bw * 0.35, byb + bh / 2, "70%", ha="center", va="center",
        fontsize=7.5, color="white", fontweight="bold")
ax.text(bx0 + bw * 0.80, byb + bh / 2, "90%", ha="center", va="center",
        fontsize=7.0, color="#145A32")
ax.text(9.97, 2.18,
        "marker signature ~90% | xCell ~70% (both p <= 0.006)\n"
        "within-tissue residual component ~ 0",
        ha="center", fontsize=7.0, color=GREY)
ax.text(9.97, 1.30,
        "=> A bulk null is compositional MASKING\n"
        "    of a per-cell hypothesis, not its refutation",
        ha="center", fontsize=8.0, color="#145A32", fontweight="bold")
ax.text(9.97, 0.72,
        "Next step: single-cell / spatial test\n(the pipeline nominates; it does not validate)",
        ha="center", fontsize=7.0, style="italic", color=GREY)

out = "results/figures/Graphical_Abstract"
fig.savefig(out + ".pdf")
fig.savefig(out + ".png", dpi=300)
print("Saved", out + ".pdf and .png")
