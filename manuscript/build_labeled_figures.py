"""Build final submission figures with 'Figure N' labels.

Addresses Allergology International editorial request (JSA-AI-2026-OA-4830):
1. Each figure page must carry a 'Figure N' label.
2. Former 'Figure 6' (cytokine heatmap) is merged into Figure 5 as panel B so
   the figure/table count stays at the 8-item cap.

Input:  results/figures/Fig{1..6}*.pdf
Output: results/figures/submission/Figure{1..5}.pdf
"""
from pathlib import Path
import fitz  # PyMuPDF

ROOT = Path(__file__).resolve().parent.parent
FIG_DIR = ROOT / "results" / "figures"
OUT_DIR = FIG_DIR / "submission"
OUT_DIR.mkdir(exist_ok=True)

LABEL_FONTSIZE = 14
LABEL_MARGIN_LEFT = 36
HEADER_HEIGHT = 40  # extra vertical space reserved above the original figure for the "Figure N" label
PANEL_FONTSIZE = 16
GAP_BETWEEN_PANELS = 24
GAP_BETWEEN_PANELS_V = 24  # vertical gap when stacking A above B

# BBRC max content width: double-column = 174 mm = 6.85 in = 493 pt.
# We target 480 pt to leave a hair of margin room.
BBRC_MAX_WIDTH_PT = 480


def add_figure_label(src: Path, dst: Path, label: str) -> None:
    """Add a header band above the source figure, then stamp `label` into it.

    We expand the page height by `HEADER_HEIGHT` so the label never overlaps
    the original content (several of the source figures render text all the
    way to the top of the media box).
    """
    src_doc = fitz.open(src)
    src_page = src_doc[0]
    src_w = src_page.rect.width
    src_h = src_page.rect.height

    new_w = src_w
    new_h = src_h + HEADER_HEIGHT

    out = fitz.open()
    new_page = out.new_page(width=new_w, height=new_h)

    # "Figure N" label inside the header band
    new_page.insert_text(
        (LABEL_MARGIN_LEFT, HEADER_HEIGHT - 14),
        label,
        fontsize=LABEL_FONTSIZE,
        fontname="hebo",
        color=(0, 0, 0),
    )

    # Embed the original figure below the header, preserving its dimensions.
    target_rect = fitz.Rect(0, HEADER_HEIGHT, new_w, new_h)
    new_page.show_pdf_page(target_rect, src_doc, 0)

    out.save(dst, garbage=3, deflate=True)
    out.close()
    src_doc.close()


def combine_two_panels(
    panel_a: Path,
    panel_b: Path,
    dst: Path,
    figure_label: str,
) -> None:
    """Place two single-page PDFs side-by-side on one page, with figure + panel labels."""
    doc_a = fitz.open(panel_a)
    doc_b = fitz.open(panel_b)
    page_a = doc_a[0]
    page_b = doc_b[0]

    # Scale both panels to the same height so the composite reads cleanly.
    target_h = max(page_a.rect.height, page_b.rect.height)
    scale_a = target_h / page_a.rect.height
    scale_b = target_h / page_b.rect.height
    w_a = page_a.rect.width * scale_a
    w_b = page_b.rect.width * scale_b

    header_h = 44  # reserve space above panels for the 'Figure N' label
    panel_label_h = 18  # space inside each panel column for the 'A'/'B' letter
    total_w = w_a + GAP_BETWEEN_PANELS + w_b
    total_h = header_h + panel_label_h + target_h

    out = fitz.open()
    new_page = out.new_page(width=total_w, height=total_h)

    # Figure N label (top-left)
    new_page.insert_text(
        (LABEL_MARGIN_LEFT, 22),
        figure_label,
        fontsize=LABEL_FONTSIZE,
        fontname="hebo",
        color=(0, 0, 0),
    )

    # Panel A label
    new_page.insert_text(
        (LABEL_MARGIN_LEFT, header_h + 14),
        "A",
        fontsize=PANEL_FONTSIZE,
        fontname="hebo",
        color=(0, 0, 0),
    )
    # Panel B label
    new_page.insert_text(
        (w_a + GAP_BETWEEN_PANELS + 4, header_h + 14),
        "B",
        fontsize=PANEL_FONTSIZE,
        fontname="hebo",
        color=(0, 0, 0),
    )

    # Embed panel A
    rect_a = fitz.Rect(
        0,
        header_h + panel_label_h,
        w_a,
        header_h + panel_label_h + target_h,
    )
    new_page.show_pdf_page(rect_a, doc_a, 0)

    # Embed panel B
    rect_b = fitz.Rect(
        w_a + GAP_BETWEEN_PANELS,
        header_h + panel_label_h,
        w_a + GAP_BETWEEN_PANELS + w_b,
        header_h + panel_label_h + target_h,
    )
    new_page.show_pdf_page(rect_b, doc_b, 0)

    out.save(dst, garbage=3, deflate=True)
    out.close()
    doc_a.close()
    doc_b.close()


def stack_two_panels_vertically(
    panel_a: Path,
    panel_b: Path,
    dst: Path,
    figure_label: str,
) -> None:
    """Stack two single-page PDFs vertically (A above B) on one page.

    Used for Fig 2 (forest plots) and Fig 5 (specificity heatmaps) where a
    side-by-side layout yields an extreme ≈3:1 aspect ratio that overflows
    BBRC's double-column width. Vertical stacking fits cleanly within 480 pt
    content width without shrinking the panels so small that the forest plot
    rows become unreadable.
    """
    doc_a = fitz.open(panel_a)
    doc_b = fitz.open(panel_b)
    page_a = doc_a[0]
    page_b = doc_b[0]

    # Scale both panels to the same width so the composite reads cleanly.
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

    # Panel A label (above panel A)
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

    # Panel B label (above panel B, below panel A)
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
    """Rescale the first page of a PDF so its width ≤ max_width_pt, preserving aspect ratio.

    Used to bring figures that were generated at arbitrary plotting sizes into
    BBRC's double-column content width. Content remains vector — we just change
    the page-box dimensions and re-embed the source at the target scale.
    """
    src_doc = fitz.open(src)
    src_page = src_doc[0]
    sw, sh = src_page.rect.width, src_page.rect.height
    if sw <= max_width_pt:
        # Already fits — just copy
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
    # Figure 1 — single panel
    add_figure_label(
        FIG_DIR / "Fig1_study_design.pdf",
        OUT_DIR / "Figure1.pdf",
        "Figure 1",
    )

    # Figure 2 — two forest plots stacked vertically (A above B)
    # Side-by-side layout produced an unreadable 18×5.9 in composite; vertical
    # stacking keeps the rows legible within BBRC's column width.
    stack_two_panels_vertically(
        FIG_DIR / "Fig2_forest_IDI2AS1.pdf",
        FIG_DIR / "Fig2_forest_IL5.pdf",
        OUT_DIR / "Figure2.pdf",
        "Figure 2",
    )

    # Figure 3 — single panel (4 scatter panels inside)
    add_figure_label(
        FIG_DIR / "Fig3_correlation_scatter.pdf",
        OUT_DIR / "Figure3.pdf",
        "Figure 3",
    )

    # Figure 4 — single panel (multi-row)
    add_figure_label(
        FIG_DIR / "Fig4_celltype_adjusted.pdf",
        OUT_DIR / "Figure4.pdf",
        "Figure 4",
    )

    # Figure 5 — former Fig5 (lncRNA specificity) + former Fig6 (cytokine) stacked vertically.
    stack_two_panels_vertically(
        FIG_DIR / "Fig5_lncrna_specificity_heatmap.pdf",
        FIG_DIR / "Fig6_cytokine_specificity_heatmap.pdf",
        OUT_DIR / "Figure5.pdf",
        "Figure 5",
    )

    # Pass 2: rescale every submission figure to BBRC double-column width (≤ 480 pt)
    # in place. Vector content is preserved — this only resizes the page box.
    for fig_name in ["Figure1.pdf", "Figure2.pdf", "Figure3.pdf", "Figure4.pdf", "Figure5.pdf"]:
        fp = OUT_DIR / fig_name
        tmp = OUT_DIR / f"_tmp_{fig_name}"
        scale_to_bbrc_width(fp, tmp)
        tmp.replace(fp)

    import fitz as _fitz
    for p in sorted(OUT_DIR.glob("Figure*.pdf")):
        d = _fitz.open(p)
        w, h = d[0].rect.width, d[0].rect.height
        size = p.stat().st_size
        d.close()
        print(f"  {p.name}  {w:.0f}×{h:.0f}pt ({w/72:.2f}×{h/72:.2f}in)  ({size:,} bytes)")


if __name__ == "__main__":
    main()
