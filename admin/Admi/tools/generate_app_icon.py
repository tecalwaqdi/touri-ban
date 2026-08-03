"""Generate square launcher icons from the horizontal TOURI AXI logo."""
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "assets/images/__2025-07-09_133622.png"
OUT_SQUARE = ROOT / "assets/images/app_icon_square.png"
OUT_FOREGROUND = ROOT / "assets/images/app_icon_foreground.png"
SIZE = 1024


def fit_on_canvas(source: Image.Image, canvas_size: int, fill_ratio: float) -> Image.Image:
    canvas = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    w, h = source.size
    max_w = int(canvas_size * fill_ratio)
    max_h = int(canvas_size * fill_ratio)
    scale = min(max_w / w, max_h / h)
    new_w = int(w * scale)
    new_h = int(h * scale)
    resized = source.resize((new_w, new_h), Image.Resampling.LANCZOS)
    x = (canvas_size - new_w) // 2
    y = (canvas_size - new_h) // 2
    canvas.paste(resized, (x, y), resized)
    return canvas


def main() -> None:
    img = Image.open(SRC).convert("RGBA")
    print(f"Source: {SRC.name} ({img.size[0]}x{img.size[1]})")

    square = fit_on_canvas(img, SIZE, 0.76)
    square_rgb = Image.new("RGB", (SIZE, SIZE), (255, 255, 255))
    square_rgb.paste(square, mask=square.split()[3])
    square_rgb.save(OUT_SQUARE, "PNG", optimize=True)
    print(f"Saved {OUT_SQUARE.relative_to(ROOT)}")

    foreground = fit_on_canvas(img, SIZE, 0.70)
    foreground.save(OUT_FOREGROUND, "PNG", optimize=True)
    print(f"Saved {OUT_FOREGROUND.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
