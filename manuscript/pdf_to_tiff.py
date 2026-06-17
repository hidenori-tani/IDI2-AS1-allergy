"""Convert submission PDF figures to TIFF for BBRC revision.

Targets the BBRC / Elsevier artwork guidelines:
  - Combination art (vector lines + rasterized panels + text): >= 500 dpi
  - LZW compression (standard request, smaller than uncompressed)
  - RGB color space
  - Embedded fonts (already present in source PDFs)

Input  : results/figures/submission_v2/{Figure1..5,SuppFigure1}.pdf
Output : results/figures/submission_v2_tiff/{Figure1..5,SuppFigure1}.tif

We render at 600 dpi to give a comfortable margin over the 500 dpi minimum
for combination art and to keep all text crisp at print size.
"""
from __future__ import annotations

from pathlib import Path
import fitz
from PIL import Image

DPI = 600
ROOT = Path(__file__).resolve().parent.parent
SRC_DIR = ROOT / "results" / "figures" / "submission_v2"
OUT_DIR = ROOT / "results" / "figures" / "submission_v2_tiff"
OUT_DIR.mkdir(exist_ok=True)


def pdf_to_tiff(src: Path, dst: Path, dpi: int = DPI) -> tuple[int, int, int]:
    """Render the first page of `src` to a TIFF at `dst` (LZW, RGB)."""
    doc = fitz.open(src)
    page = doc[0]
    # zoom: 72 pt/in is the PDF point unit; for `dpi` we scale by dpi/72.
    zoom = dpi / 72.0
    mat = fitz.Matrix(zoom, zoom)
    pix = page.get_pixmap(matrix=mat, alpha=False, colorspace=fitz.csRGB)
    img = Image.frombytes("RGB", (pix.width, pix.height), pix.samples)
    img.save(
        dst,
        format="TIFF",
        compression="tiff_lzw",
        dpi=(dpi, dpi),
    )
    size = dst.stat().st_size
    doc.close()
    return pix.width, pix.height, size


def main() -> None:
    files = sorted(SRC_DIR.glob("*.pdf"))
    if not files:
        raise SystemExit(f"No PDFs found in {SRC_DIR}")
    print(f"Converting {len(files)} PDFs -> TIFF (LZW, {DPI} dpi)\n")
    for src in files:
        dst = OUT_DIR / (src.stem + ".tif")
        w, h, size = pdf_to_tiff(src, dst)
        size_mb = size / (1024 * 1024)
        print(f"  {src.name:<18} -> {dst.name:<18}  {w}x{h}px  ({size_mb:.2f} MB)")


if __name__ == "__main__":
    main()
