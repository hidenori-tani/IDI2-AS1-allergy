"""Shared figure style for the figure scripts in this directory.

A reduced copy of the author's figure-style module that keeps only what the scripts here use:

  use_journal_style()  fixes matplotlib rcParams before a figure is drawn (TrueType fonts embedded,
                       Arial or Helvetica, sizes in pt)
  mm()                 converts millimetres to inches for figsize
  savefig()            writes the PDF and a PNG preview at the same size
  OKABE_ITO            the Okabe & Ito colour-universal-design palette

The figure scripts call use_journal_style() (8 pt base text; tick labels and legends 7.8 pt). The panel
headings of Figures 3, 4 and S1 are set at 7 pt, the floor in JOURNAL_MIN_PT. The values below are the ones that call uses;
the full module also prints layout warnings while saving, which do not change the output.
"""
from __future__ import annotations

import os

import matplotlib
import matplotlib.pyplot as plt

MM_PER_INCH = 25.4

# Okabe & Ito colour-universal-design palette
OKABE_ITO = {
    "black": "#000000",
    "orange": "#E69F00",
    "sky_blue": "#56B4E9",
    "bluish_green": "#009E73",
    "yellow": "#F0E442",
    "blue": "#0072B2",
    "vermillion": "#D55E00",
    "reddish_purple": "#CC79A7",
}

# Order for lines on a white background (yellow, the least visible, last)
OKABE_ITO_CYCLE = [
    OKABE_ITO["blue"],
    OKABE_ITO["vermillion"],
    OKABE_ITO["bluish_green"],
    OKABE_ITO["orange"],
    OKABE_ITO["sky_blue"],
    OKABE_ITO["reddish_purple"],
    OKABE_ITO["black"],
    OKABE_ITO["yellow"],
]

BASE_FONT_PT = {"generic": 8.0}     # base text size (pt)
JOURNAL_MIN_PT = {"generic": 7.0}   # smallest text the figures may use (pt)


def safe_min_pt(journal: str = "generic") -> float:
    """Smallest text size used, kept 11.5% above the minimum so rounding never goes below it."""
    return round(JOURNAL_MIN_PT.get(journal, 7.0) * 1.115, 1)


def mm(value_mm: float) -> float:
    """Millimetres to inches (for matplotlib figsize)."""
    return value_mm / MM_PER_INCH


def _pick_sans() -> list:
    """Arial, then Helvetica, then other installed sans-serif fonts; DejaVu Sans as a last resort."""
    available = {f.name for f in matplotlib.font_manager.fontManager.ttflist}
    order = ["Arial", "Helvetica", "Helvetica Neue", "Liberation Sans", "Nimbus Sans"]
    picked = [name for name in order if name in available]
    return picked + ["DejaVu Sans"]


def use_journal_style(journal: str = "generic", base_pt: float | None = None) -> None:
    """Fix rcParams for figure output. Call once before drawing."""
    pt = base_pt if base_pt else BASE_FONT_PT.get(journal, 8.0)
    sans = _pick_sans()
    head = sans[0]
    plt.rcParams.update(
        {
            "mathtext.fontset": "custom",
            "mathtext.rm": head,
            "mathtext.it": f"{head}:italic",
            "mathtext.bf": f"{head}:bold",
            "mathtext.sf": head,
            "mathtext.tt": head,
            "mathtext.cal": f"{head}:italic",
            "pdf.fonttype": 42,
            "ps.fonttype": 42,
            "svg.fonttype": "none",
            "font.family": "sans-serif",
            "font.sans-serif": sans,
            "font.size": pt,
            "axes.titlesize": pt,
            "axes.labelsize": pt,
            "xtick.labelsize": max(pt - 0.5, safe_min_pt(journal)),
            "ytick.labelsize": max(pt - 0.5, safe_min_pt(journal)),
            "legend.fontsize": max(pt - 0.5, safe_min_pt(journal)),
            "figure.titlesize": pt + 1,
            "axes.linewidth": 0.6,
            "grid.linewidth": 0.5,
            "lines.linewidth": 1.0,
            "lines.markersize": 3.0,
            "patch.linewidth": 0.6,
            "xtick.major.width": 0.6,
            "ytick.major.width": 0.6,
            "xtick.minor.width": 0.5,
            "ytick.minor.width": 0.5,
            "xtick.major.size": 2.5,
            "ytick.major.size": 2.5,
            "axes.spines.top": False,
            "axes.spines.right": False,
            "axes.prop_cycle": plt.cycler(color=OKABE_ITO_CYCLE),
            "legend.frameon": False,
            "figure.dpi": 150,
            "savefig.dpi": 600,
            "savefig.bbox": "standard",  # "tight" would change the page size
            "savefig.transparent": False,
            "figure.facecolor": "white",
            "savefig.facecolor": "white",
        }
    )


def savefig(fig, stem: str, dpi: int = 600, formats=("pdf", "png")) -> list:
    """Write the figure as PDF (vector) and PNG (preview) at the same size."""
    os.makedirs(os.path.dirname(stem) or ".", exist_ok=True)
    written = []
    for ext in formats:
        path = f"{stem}.{ext}"
        fig.savefig(path, format=ext, dpi=dpi)
        written.append(path)
    return written
