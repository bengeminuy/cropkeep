"""Generate tightened logo + adaptive-icon foreground from assets/branding/logo.png."""

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "assets" / "branding" / "logo.png"
TIGHT = ROOT / "assets" / "branding" / "logo.png"  # overwrite in place
FG = ROOT / "assets" / "branding" / "logo_foreground.png"
BACKUP = ROOT / "assets" / "branding" / "logo_original.png"

CANVAS = 1024
TIGHT_FILL = 0.92   # tighter source: artwork fills 92% of canvas
FG_FILL = 0.66      # adaptive foreground: artwork fills 66% (inside safe zone)


def alpha_bbox(im: Image.Image, threshold: int = 8) -> tuple[int, int, int, int]:
    if im.mode != "RGBA":
        im = im.convert("RGBA")
    alpha = im.split()[-1]
    mask = alpha.point(lambda v: 255 if v > threshold else 0)
    bbox = mask.getbbox()
    if bbox is None:
        raise RuntimeError("logo.png appears to be fully transparent")
    return bbox


def resized_into_canvas(src: Image.Image, fill_ratio: float) -> Image.Image:
    bbox = alpha_bbox(src)
    cropped = src.crop(bbox)
    target = int(CANVAS * fill_ratio)
    w, h = cropped.size
    scale = target / max(w, h)
    new_w = max(1, int(round(w * scale)))
    new_h = max(1, int(round(h * scale)))
    resized = cropped.resize((new_w, new_h), Image.LANCZOS)
    canvas = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    ox = (CANVAS - new_w) // 2
    oy = (CANVAS - new_h) // 2
    canvas.paste(resized, (ox, oy), resized)
    return canvas


def main() -> None:
    src = Image.open(SRC).convert("RGBA")
    print(f"Source: {SRC.name} {src.size} mode={src.mode}")
    bbox = alpha_bbox(src)
    bw, bh = bbox[2] - bbox[0], bbox[3] - bbox[1]
    print(f"Artwork bbox: {bbox} -> {bw}x{bh} (fills {bw/src.size[0]:.0%} x {bh/src.size[1]:.0%})")

    if not BACKUP.exists():
        BACKUP.write_bytes(SRC.read_bytes())
        print(f"Backed up original -> {BACKUP.name}")

    tight = resized_into_canvas(src, TIGHT_FILL)
    tight.save(TIGHT, "PNG", optimize=True)
    print(f"Wrote {TIGHT.name} (artwork fills {TIGHT_FILL:.0%})")

    fg = resized_into_canvas(src, FG_FILL)
    fg.save(FG, "PNG", optimize=True)
    print(f"Wrote {FG.name} (artwork fills {FG_FILL:.0%}, sized for adaptive safe zone)")


if __name__ == "__main__":
    main()
