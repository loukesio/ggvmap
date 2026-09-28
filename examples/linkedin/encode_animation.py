"""Encode the actual R-rendered frames as GIF and MP4. Run from the repo root."""
from pathlib import Path
import csv
import shutil
import subprocess
import numpy as np
from PIL import Image

root = Path(__file__).resolve().parent
rows = list(csv.DictReader((root / 'timing.csv').open()))
frames = [Image.open(root / 'frames' / r['frame']).convert('RGB') for r in rows]
durations = [int(float(r['seconds']) * 1000) for r in rows]
# Use one palette across all frames so stationary colors do not flicker.
strip = Image.new('RGB', (360, 420 * len(frames)), 'white')
for i, im in enumerate(frames):
    strip.paste(im.resize((360, 420)), (0, i * 420))
palette = strip.quantize(colors=256)
# Keep the requested palette and white background exact in the indexed GIF.
fixed = ['FFFFFF', '262626', '333333', '575D5D', 'F5F5F2', 'E6E8E4',
         'EFBC68', '919F89', 'EDBDAE', '57717C', '5F97A4', 'CAEAC8',
         '95A1AE', 'C8CFD6']
exact = [int(color[j:j+2], 16) for color in fixed for j in (0, 2, 4)]
greys = [round(i * 255 / (255 - len(fixed))) for i in range(256 - len(fixed))]
palette.putpalette(exact + [v for shade in greys for v in (shade, shade, shade)])
indexed = []
for im in frames:
    rgb = np.asarray(im)
    indices = np.array(im.quantize(palette=palette, dither=Image.Dither.NONE))
    # Pillow's palette cache can round a flat fill to a nearby entry. Restore
    # declared solid colors exactly; retain quantization for antialiased edges.
    for k, color in enumerate(fixed):
        r, g, b = (int(color[j:j+2], 16) for j in (0, 2, 4))
        mask = (rgb[:, :, 0] == r) & (rgb[:, :, 1] == g) & (rgb[:, :, 2] == b)
        indices[mask] = k
    frame = Image.fromarray(indices)
    frame.putpalette(palette.getpalette())
    indexed.append(frame)
indexed[0].save(root / 'ggvmap-options.gif', save_all=True,
                append_images=indexed[1:], duration=durations, loop=0,
                optimize=False, disposal=2)
concat = root / 'frames.txt'
lines = []
for r in rows:
    lines.extend([f"file 'frames/{r['frame']}'", f"duration {r['seconds']}"])
lines.append(f"file 'frames/{rows[-1]['frame']}'")
concat.write_text('\n'.join(lines) + '\n')
subprocess.run(['ffmpeg', '-hide_banner', '-loglevel', 'error', '-y',
                '-f', 'concat', '-safe', '0', '-i', str(concat),
                '-vf', 'fps=24', '-c:v', 'libx264', '-crf', '18',
                '-pix_fmt', 'yuv420p', '-movflags', '+faststart', '-an',
                '-t', str(sum(durations) / 1000), str(root / 'ggvmap-options.mp4')], check=True)
shutil.copyfile(root / 'frames/04.png', root / 'cover.png')
with Image.open(root / 'ggvmap-options.gif') as gif:
    assert gif.n_frames == len(rows)
    total = 0
    for i in range(gif.n_frames):
        gif.seek(i)
        assert gif.size == (1440, 1680)
        total += gif.info['duration']
    assert total == sum(durations)
    print(f'GIF verified: {gif.n_frames} frames, {total / 1000:.0f} seconds, 1440 x 1680')
for ext in ['gif', 'mp4']:
    p = root / f'ggvmap-options.{ext}'
    print(f'{p.name}: {p.stat().st_size / 1e6:.2f} MB')
