"""Build BBRC revision submission figures (v2).

Addresses BBRC editor letter BBRC-26-2497 (M. Lichten, May 2026):
font sizes in the original submission were below the BBRC 6pt absolute
minimum / 8pt preferred threshold.

Changes vs v1 (build_labeled_figures.py):
  - All source figures are now rendered at 9 in wide with fonts >= 11pt
    (so the post-stage scale to 480pt keeps fonts >= 8.15pt).
  - Figure 4 is composited from two new panel PDFs (Fig4A_raw + Fig4B_eos)
    via stack_two_panels_vertically (Th2 row moved to SuppFig1).
  - Adds a Supplementary Figure 1 build for the Th2 signature row.

Input:  results/figures/Fig{1..6}*.pdf and Fig4A/4B/SuppFig1
Output: results/figures/submission_v2/Figure{1..5}.pdf + SuppFigure1.pdf
"""
from pathlib import Path
import fitz

ROOT = Path(__file__).resolve().parent.parent
FIG_DIR = ROOT / "results" / "figures"
OUT_DIR = FIG_DIR / "submission_v2"
OUT_DIR.mkdir(exist_ok=True)

LABEL_FONTSIZE = 14
LABEL_MARGIN_LEFT = 36
HEADER_HEIGHT = 40
PANEL_FONTSIZE = 16
GAP_BETWEEN_PANELS = 24
GAP_BETWEEN_PANELS_V = 24

# BBRC max content width: double-column = 174 mm = 6.85 in = 493 pt.
BBRC_MAX_WIDTH_PT = 480


def add_figure_label(src: Path, dst: Path, label: str) -> None:
    src_doc = fitz.open(src)
    src_page = src_doc[0]
    src_w = src_page.rect.width
    src_h = src_page.rect.height

    new_w = src_w
    new_h = src_h + HEADER_HEIGHT

    out = fitz.open()
    new_page = out.new_page(width=new_w, height=new_h)
    new_page.insert_text(
        (LABEL_MARGIN_LEFT, HEADER_HEIGHT - 14),
        label,
        fontsize=LABEL_FONTSIZE,
        fontname="hebo",
        color=(0, 0, 0),
    )
    target_rect = fitz.Rect(0, HEADER_HEIGHT, new_w, new_h)
    new_page.show_pdf_page(target_rect, src_doc, 0)
    out.save(dst, garbage=3, deflate=True)
    out.close()
    src_doc.close()


def stack_two_panels_vertically(
    panel_a: Path,
    panel_b: Path,
    dst: Path,
    figure_label: str,
) -> None:
    """Stack panel A above panel B with figure + A/B labels."""
    doc_a = fitz.open(panel_a)
    doc_b = fitz.open(panel_b)
    page_a = doc_a[0]
    page_b = doc_b[0]

    target_w = max(page_a.rect.width, page_b.rect.width)
    scale_a = target_w / page_a.rect.width
    scale_b = target_w / page_b.rect.width
    h_a = page_a.rect.height * scale_a
    h_b = page_b.rect.height * scale_b

    header_h = 44
    panel_label_h = 18
    total_w = target_w
    total_h = header_h + panel_label_h + h_a + GAP_BETWEEN_PANELS_V + panel_label_h + h_b

    out = fitz.open()
    new_page = out.new_page(width=total_w, height=total_h)

    new_page.insert_text(
        (LABEL_MARGIN_LEFT, 22),
        figure_label,
        fontsize=LABEL_FONTSIZE, fontname="hebo", color=(0, 0, 0),
    )

    new_page.insert_text(
        (LABEL_MARGIN_LEFT, header_h + 14),
        "A",
        fontsize=PANEL_FONTSIZE, fontname="hebo", color=(0, 0, 0),
    )
    rect_a = fitz.Rect(
        0, header_h + panel_label_h,
        target_w, header_h + panel_label_h + h_a,
    )
    new_page.show_pdf_page(rect_a, doc_a, 0)

    b_label_y = header_h + panel_label_h + h_a + GAP_BETWEEN_PANELS_V
    new_page.insert_text(
        (LABEL_MARGIN_LEFT, b_label_y + 14),
        "B",
        fontsize=PANEL_FONTSIZE, fontname="hebo", color=(0, 0, 0),
    )
    rect_b = fitz.Rect(
        0, b_label_y + panel_label_h,
        target_w, b_label_y + panel_label_h + h_b,
    )
    new_page.show_pdf_page(rect_b, doc_b, 0)

    out.save(dst, garbage=3, deflate=True)
    out.close()
    doc_a.close()
    doc_b.close()


def scale_to_bbrc_width(src: Path, dst: Path, max_width_pt: float = BBRC_MAX_WIDTH_PT) -> None:
    src_doc = fitz.open(src)
    src_page = src_doc[0]
    sw, sh = src_page.rect.width, src_page.rect.height
    if sw <= max_width_pt:
        out = fitz.open()
        out.insert_pdf(src_doc)
        out.save(dst, garbage=3, deflate=True)
        out.close()
        src_doc.close()
        return
    scale = max_width_pt / sw
    new_w = max_width_pt
    new_h = sh * scale
    out = fitz.open()
    new_page = out.new_page(width=new_w, height=new_h)
    new_page.show_pdf_page(fitz.Rect(0, 0, new_w, new_h), src_doc, 0)
    out.save(dst, garbage=3, deflate=True)
    out.close()
    src_doc.close()


def main() -> None:
    # Figure 1 — schematic
    add_figure_label(
        FIG_DIR / "Fig1_study_design.pdf",
        OUT_DIR / "Figure1.pdf",
        "Figure 1",
    )

    # Figure 2 — two forest plots stacked vertically (unchanged layout, v1 fonts already OK)
    stack_two_panels_vertically(
        FIG_DIR / "Fig2_forest_IDI2AS1.pdf",
        FIG_DIR / "Fig2_forest_IL5.pdf",
        OUT_DIR / "Figure2.pdf",
        "Figure 2",
    )

    # Figure 3 — single panel
    add_figure_label(
        FIG_DIR / "Fig3_correlation_scatter.pdf",
        OUT_DIR / "Figure3.pdf",
        "Figure 3",
    )

    # Figure 4 — new 2-panel composite (raw + eosinophil signature), Th2 moved to SuppFig1
    stack_two_panels_vertically(
        FIG_DIR / "Fig4A_raw_correlation.pdf",
        FIG_DIR / "Fig4B_eosinophil_signature.pdf",
        OUT_DIR / "Figure4.pdf",
        "Figure 4",
    )

    # Figure 5 — heatmaps stacked vertically (cell font 8 → 11)
    stack_two_panels_vertically(
        FIG_DIR / "Fig5_lncrna_specificity_heatmap.pdf",
        FIG_DIR / "Fig6_cytokine_specificity_heatmap.pdf",
        OUT_DIR / "Figure5.pdf",
        "Figure 5",
    )

    # Supplementary Figure 1 — Th2 signature row
    add_figure_label(
        FIG_DIR / "SuppFig1_th2_signature.pdf",
        OUT_DIR / "SuppFigure1.pdf",
        "Supplementary Figure 1",
    )

    # Pass 2: rescale every figure to BBRC double-column width (<= 480pt)
    for fig_name in ["Figure1.pdf", "Figure2.pdf", "Figure3.pdf",
                     "Figure4.pdf", "Figure5.pdf", "SuppFigure1.pdf"]:
        fp = OUT_DIR / fig_name
        tmp = OUT_DIR / f"_tmp_{fig_name}"
        scale_to_bbrc_width(fp, tmp)
        tmp.replace(fp)

    print("\nFinal submission v2 figure dimensions:")
    for p in sorted(OUT_DIR.glob("*.pdf")):
        d = fitz.open(p)
        w, h = d[0].rect.width, d[0].rect.height
        size = p.stat().st_size
        d.close()
        print(f"  {p.name}  {w:.0f}x{h:.0f}pt ({w/72:.2f}x{h/72:.2f}in)  ({size:,} bytes)")


if __name__ == "__main__":
    main()
