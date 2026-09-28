"""Encode the clean country-first promo frames as a looping GIF."""
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent
names = sorted((ROOT / 'country_frames').glob('*.png'))[:6]
frames = [Image.open(path).convert('RGB') for path in names]
durations = [3000, 3000, 4000, 4000, 4000, 4000]
assert len(frames) == len(durations) == 6
frames[0].save(ROOT / 'ggvmap-country-promo.gif', save_all=True,
               append_images=frames[1:], duration=durations, loop=0,
               optimize=False, disposal=2)
frames[0].save(ROOT / 'country-promo-cover.png')
print('GIF verified:', len(frames), 'frames,', sum(durations) // 1000,
      'seconds,', frames[0].size[0], 'x', frames[0].size[1])
