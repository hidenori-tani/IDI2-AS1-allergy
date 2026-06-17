"""Fig 1 — Study design schematic (matplotlib version).

A4-landscape vector PDF (11.69 x 8.27 in). Single-column variant also produced
for Frontiers (single-column fig ~85 mm wide).

Layout: 4 stages stacked top-to-bottom
  Stage 1: 5 datasets (4 diseases, n = 856)
  Stage 2: uniform pipeline (DESeq2/limma -> meta -> corr -> mediation)
  Stage 3: three analytical questions
  Stage 4: principal finding (composition mediation ~= 90 %)
"""

from pathlib import Path

import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from matplotlib.patches import FancyArrowPatch

plt.rcParams["font.family"] = "Arial"
plt.rcParams["pdf.fonttype"] = 42  # TrueType-embedded fonts
plt.rcParams["ps.fonttype"] = 42

OUT_PDF = Path(__file__).resolve().parents[2] / "results" / "figures" / "Fig1_study_design.pdf"
OUT_PDF.parent.mkdir(parents=True, exist_ok=True)


def draw_box(ax, x, y, w, h, label, *, fc="white", ec="black", lw=1.0,
             fontsize=8, fontweight="normal"):
    """Draw a centered rounded box with a label (x, y = center)."""
    rect = mpatches.FancyBboxPatch(
        (x - w / 2, y - h / 2), w, h,
        boxstyle="round,pad=0.002,rounding_size=0.008",
        linewidth=lw, edgecolor=ec, facecolor=fc,
    )
    ax.add_patch(rect)
    ax.text(x, y, label, ha="center", va="center",
            fontsize=fontsize, fontweight=fontweight,
            linespacing=1.15)


def draw_arrow(ax, x0, y0, x1, y1, lw=0.9, color="black"):
    arr = FancyArrowPatch(
        (x0, y0), (x1, y1),
        arrowstyle="-|>", mutation_scale=9,
        linewidth=lw, color=color,
        shrinkA=0, shrinkB=0,
    )
    ax.add_patch(arr)


def build_figure():
    fig = plt.figure(figsize=(11.69, 8.27))  # A4 landscape
    ax = fig.add_axes([0.02, 0.03, 0.96, 0.94])
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    ax.set_axis_off()

    # -------- Title --------
    ax.text(0.5, 0.975,
            "Cross-disease re-analysis of the IDI2-AS1 / IL5 axis in IL5-driven allergic disease",
            ha="center", va="center",
            fontsize=13.5, fontweight="bold")
    ax.text(0.5, 0.942,
            "Five public bulk RNA-seq cohorts, 856 samples, uniform pipeline",
            ha="center", va="center",
            fontsize=10, style="italic", color="#444444")

    # -------- Stage 1: datasets --------
    ax.text(0.07, 0.89, "STAGE 1 — Datasets",
            ha="left", va="center",
            fontsize=10.5, fontweight="bold", color="#2874A6")

    ds = [
        ("Asthma\nGSE152004\nn = 695\nNasal epithelium",     "#D6EAF8"),
        ("Atopic dermatitis\nGSE121212\nn = 65\nSkin biopsy", "#FADBD8"),
        ("EoE\nGSE246323\nn = 10\nEsophagus",                 "#FCF3CF"),
        ("EoE\nGSE58640\nn = 16\nEsophagus",                  "#FCF3CF"),
        ("CRSwNP\nGSE136825\nn = 70\nNasal polyp",            "#D5F5E3"),
    ]
    xs = [0.12 + 0.19 * i for i in range(5)]
    y_stage1 = 0.81
    for (label, fc), x in zip(ds, xs):
        draw_box(ax, x, y_stage1, 0.165, 0.105, label, fc=fc, fontsize=8)

    # aggregator bar Stage 1 -> Stage 2
    bar_y = 0.745
    ax.plot([xs[0], xs[-1]], [bar_y, bar_y], color="#666666", lw=0.8)
    for x in xs:
        ax.plot([x, x], [y_stage1 - 0.052, bar_y], color="#666666", lw=0.8)
    draw_arrow(ax, 0.5, bar_y, 0.5, 0.712, lw=1.0, color="#444444")

    # -------- Stage 2: pipeline --------
    ax.text(0.07, 0.69, "STAGE 2 — Uniform pipeline",
            ha="left", va="center",
            fontsize=10.5, fontweight="bold", color="#2874A6")

    pipe = [
        "DESeq2 + apeglm\n(raw counts)\n/ limma-trend\n(FPKM)",
        "Random-effects\nmeta-analysis\n(metafor REML)",
        "Sample-level\nSpearman\nIDI2-AS1 ↔ IL5",
        "Cell-type-adjusted\npartial correlation\n(eosinophil + Th2\nsignatures)",
        "Causal mediation\n(asthma cohort,\n1,000 bootstraps)",
    ]
    xp = [0.12 + 0.19 * i for i in range(5)]
    y_stage2 = 0.61
    box_w = 0.175
    for label, x in zip(pipe, xp):
        draw_box(ax, x, y_stage2, box_w, 0.105,
                 label, fc="#EAF2F8", fontsize=7.5)
    for i in range(len(xp) - 1):
        draw_arrow(ax, xp[i] + box_w / 2, y_stage2,
                   xp[i + 1] - box_w / 2, y_stage2, lw=0.9, color="#444444")

    # -------- Stage 3: three questions --------
    ax.text(0.07, 0.49, "STAGE 3 — Three in vivo questions",
            ha="left", va="center",
            fontsize=10.5, fontweight="bold", color="#2874A6")

    q = [
        "Q1.\nIs IDI2-AS1 itself\ndifferentially expressed\nin disease tissue?",
        "Q2.\nDo IDI2-AS1 and IL5\ncovary at the sample level\nin the predicted\n(negative) direction?",
        "Q3.\nIf the bulk signal\ndeparts from the\nin vitro prediction,\ncan it be ascribed to\ncell composition?",
    ]
    xq = [0.22, 0.50, 0.78]
    y_stage3 = 0.41
    for label, x in zip(q, xq):
        draw_box(ax, x, y_stage3, 0.22, 0.125,
                 label, fc="#FDEBD0", fontsize=8.5)
    for x in xq:
        draw_arrow(ax, x, y_stage3 - 0.068, x, 0.285, lw=0.9, color="#444444")

    # -------- Stage 4: principal finding --------
    ax.text(0.07, 0.265, "STAGE 4 — Principal finding",
            ha="left", va="center",
            fontsize=10.5, fontweight="bold", color="#2874A6")

    finding = (
        "Tissue-bulk IDI2-AS1 expression is invariant in every cohort "
        "(pooled log$_2$FC ≈ 0; $I^2$ = 0.26 %).\n"
        "Sample-level IDI2-AS1 ↔ IL5 covariation is POSITIVE — opposite to the in vitro repressive direction.\n"
        "Causal mediation in the asthma cohort attributes ≈ 90 % of the covariation to the eosinophil compartment\n"
        "(ACME = +0.109, $p$ = 0.002), with a within-tissue direct effect indistinguishable from zero (ADE = +0.012, $p$ = 0.76).\n"
        "\n"
        "→ The published in vitro IDI2-AS1 → IL5 axis is MASKED, not contradicted, by bulk RNA-seq.\n"
        "→ Single-cell follow-up is the natural next step."
    )
    finding_box = mpatches.FancyBboxPatch(
        (0.07, 0.05), 0.86, 0.17,
        boxstyle="round,pad=0.004,rounding_size=0.012",
        linewidth=1.6, edgecolor="#1E6B3B", facecolor="#E8F8F5",
    )
    ax.add_patch(finding_box)
    ax.text(0.5, 0.135, finding, ha="center", va="center",
            fontsize=9, linespacing=1.4)

    return fig


def main():
    fig = build_figure()
    fig.savefig(OUT_PDF, format="pdf", bbox_inches="tight")
    # also a 300 dpi PNG for preview
    png = OUT_PDF.with_suffix(".png")
    fig.savefig(png, format="png", dpi=300, bbox_inches="tight")
    plt.close(fig)
    print(f"Wrote {OUT_PDF}")
    print(f"Wrote {png}")


if __name__ == "__main__":
    main()
