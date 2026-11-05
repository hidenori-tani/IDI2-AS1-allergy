"""Figure 1: the study-design schematic of
code/python/11_fig1_study_design.py, used as drawn (A4-landscape canvas saved with a tight
bounding box, about 290 x 203 mm; fonts embedded by matplotlib).
The figure file is this script's output unchanged (same page size and text, checked with
--check).

    python3 code/python/24_figure1.py            # results/figures/submission_figs/Figure1.pdf
    python3 code/python/24_figure1.py --check    # also compares page size and text with the
                                                     # current Figure1.pdf (for the reproduction check)
"""
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

import fitz

ROOT = Path(__file__).resolve().parents[2]
FIG = ROOT / "results" / "figures"
OUT = FIG / "submission_figs" / "Figure1.pdf"


def build(dst: Path) -> None:
    subprocess.run([sys.executable, str(ROOT / "code/python/11_fig1_study_design.py")], check=True,
                   cwd=ROOT, capture_output=True)
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(FIG / "Fig1_study_design.pdf", dst)


def page(path):
    p = fitz.open(path)[0]
    return round(p.rect.width, 1), round(p.rect.height, 1), " ".join(p.get_text().split())


if __name__ == "__main__":
    if "--check" in sys.argv:
        with tempfile.TemporaryDirectory() as td:
            new = Path(td) / "Figure1.pdf"
            build(new)
            a, b = page(OUT), page(new)
            print("size current", a[:2], "rebuilt", b[:2], "| text identical:", a[2] == b[2])
            sys.exit(0 if a == b else 1)
    build(OUT)
    print(f"wrote {OUT.relative_to(ROOT)}")
