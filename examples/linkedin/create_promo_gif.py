"""Build the clean, no-code promo GIF from the rendered ggvmap frames."""
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent
SOURCE_FRAMES = ["09.png", "10.png", "11.png"]
DURATIONS = [5000, 7000, 7000]

# Keep the title, map, flags/ring, and legend. The lower part of the tutorial
# frames contains the R code panel, which is intentionally excluded from promo.
frames = []
for name in SOURCE_FRAMES:
    with Image.open(ROOT / "frames" / name) as image:
        frames.append(image.convert("RGB").crop((0, 0, 1440, 1100)))

frames[0].save(
    ROOT / "ggvmap-promo.gif",
    save_all=True,
    append_images=frames[1:],
    duration=DURATIONS,
    loop=0,
    optimize=False,
    disposal=2,
)

# A still cover is useful for LinkedIn previews.
frames[0].save(ROOT / "promo-cover.png")
print("wrote ggvmap-promo.gif (3 clean frames, 19 seconds)")
