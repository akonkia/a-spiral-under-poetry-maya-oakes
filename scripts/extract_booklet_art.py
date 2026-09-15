#!/usr/bin/env python3

from pathlib import Path
import sys

from PIL import Image


ROOT = Path(__file__).resolve().parent.parent
SOURCE_DIR = ROOT / "tmp" / "pdfs" / "spiral-booklet"
OUTPUT_DIR = ROOT / "assets" / "booklet"

CROPS = {
    "spiral": ("page-01.jpg", (68, 270, 558, 760)),
    "branch": ("page-01.jpg", (0, 0, 605, 175)),
    "cartographer": ("page-03.jpg", (0, 0, 605, 390)),
    "philosopher": ("page-07.jpg", (0, 0, 525, 360)),
    "biologist": ("page-14.jpg", (25, 30, 565, 425)),
    "ethnographer": ("page-21.jpg", (0, 0, 470, 355)),
}


def main() -> None:
    source_dir = Path(sys.argv[1]).expanduser() if len(sys.argv) > 1 else SOURCE_DIR
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    for name, (filename, box) in CROPS.items():
        source = source_dir / filename
        if not source.exists():
            raise FileNotFoundError(f"Missing rendered booklet page: {source}")

        image = Image.open(source).convert("RGB").crop(box)
        image.save(OUTPUT_DIR / f"{name}.webp", "WEBP", quality=90, method=6)

    print(f"Extracted {len(CROPS)} booklet motifs into {OUTPUT_DIR}")


if __name__ == "__main__":
    main()
