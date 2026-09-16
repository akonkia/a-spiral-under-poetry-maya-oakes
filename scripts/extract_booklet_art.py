#!/usr/bin/env python3

from pathlib import Path
import sys

from PIL import Image, ImageOps


ROOT = Path(__file__).resolve().parent.parent
SOURCE_DIR = ROOT / "tmp" / "pdfs" / "spiral-booklet"
OUTPUT_DIR = ROOT / "assets" / "booklet"
POEM_OUTPUT_DIR = ROOT / "assets" / "poems"

CROPS = {
    "spiral": ("page-01.jpg", (68, 270, 558, 760)),
    "branch": ("page-01.jpg", (0, 0, 605, 175)),
    "cartographer": ("page-03.jpg", (0, 0, 605, 390)),
    "philosopher": ("page-07.jpg", (0, 0, 525, 360)),
    "biologist": ("page-14.jpg", (25, 30, 565, 425)),
    "ethnographer": ("page-21.jpg", (0, 0, 470, 355)),
}

POEM_CROPS = {
    "map-i-eulogy-to-unborn": ("page-05.jpg", (185, 480, 575, 930)),
    "paintbox": ("page-08.jpg", (300, 700, 590, 920)),
    "overflow": ("page-09.jpg", (105, 420, 520, 800)),
    "linocut": ("page-11.jpg", (105, 540, 510, 915)),
    "aivolved": ("page-13.jpg", (390, 490, 580, 700)),
    "these-pets-of-mine": ("page-16.jpg", (0, 650, 535, 920)),
    "blue-canary": ("page-17.jpg", (90, 670, 520, 880)),
    "the-gift": ("page-18.jpg", (320, 700, 605, 935)),
    "yearning": ("page-19.jpg", (0, 0, 132, 285)),
    "farmer-and-the-one-eyed-likho": ("page-23.jpg", (205, 535, 450, 850)),
    "koschei-and-the-prince": ("page-24.jpg", (330, 585, 605, 935)),
}


def trim_whitespace(image: Image.Image, padding: int = 12) -> Image.Image:
    inverted = ImageOps.invert(image.convert("L"))
    mask = inverted.point(lambda value: 255 if value > 12 else 0)
    bounds = mask.getbbox()
    if bounds is None:
        return image

    left, top, right, bottom = bounds
    return image.crop((
        max(0, left - padding),
        max(0, top - padding),
        min(image.width, right + padding),
        min(image.height, bottom + padding),
    ))


def main() -> None:
    source_dir = Path(sys.argv[1]).expanduser() if len(sys.argv) > 1 else SOURCE_DIR
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    for name, (filename, box) in CROPS.items():
        source = source_dir / filename
        if not source.exists():
            raise FileNotFoundError(f"Missing rendered booklet page: {source}")

        image = Image.open(source).convert("RGB").crop(box)
        image.save(OUTPUT_DIR / f"{name}.webp", "WEBP", quality=90, method=6)

    POEM_OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    for slug, (filename, box) in POEM_CROPS.items():
        source = source_dir / filename
        if not source.exists():
            raise FileNotFoundError(f"Missing rendered booklet page: {source}")

        image = Image.open(source).convert("RGB").crop(box)
        if slug == "koschei-and-the-prince":
            image.paste("white", (0, 0, 215, 180))
        trim_whitespace(image).save(
            POEM_OUTPUT_DIR / f"{slug}.webp", "WEBP", quality=92, method=6
        )

    print(
        f"Extracted {len(CROPS)} booklet motifs and "
        f"{len(POEM_CROPS)} poem illustrations"
    )


if __name__ == "__main__":
    main()
