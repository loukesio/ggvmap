# ggvmap announcement animation

- `ggvmap-options.gif`: looping 77-second tutorial, 1440 x 1680 pixels.
- `ggvmap-promo.gif`: clean 19-second country-and-city promo, with no code panels.
- `ggvmap-country-promo.gif`: country-first 42-second promo showing all 30
  country and regional categories, with a flag on Brazil only. Percentages appear
  in a separate frame so the map can also be read without them.
- `ggvmap-options.mp4`: the same silent tutorial as an H.264 video.
- `cover.png`: still image of the arc-ring example.
- `promo-cover.png`: still image for the clean country promo.
- `country-promo-cover.png`: still image for the country-first promo.
- `demo.R`: runnable plotting code.
- `create_promo_gif.py`: builds the clean promo from the rendered map frames.
- `create_country_promo.R` and `encode_country_promo.py`: build the full
  country-first promo without code panels.
- `teaching_budget.csv`: all invented input values.
- `layout_checks.csv`: convergence and measured area errors for the layouts.
- `linkedin-post.txt`: a short draft announcement.

The animation covers layout creation, readable labels, one-cell emphasis, item
colors, both arc and band rings, value labels, a hexagonal outline, and the new
real-boundary function. The country section uses the bundled freshwater data and
real country flags; the last map is a real Berlin outline using invented teaching
values.

All budget values are invented for teaching. There are no numeric axes. Read the
areas and labels: 30% means 30 of a total of 100 budget units. Larger areas mean
larger shares, not better outcomes. Gold and sage identify Research and Support
except in the explicitly labelled item-color frame, where the legend identifies
each item. Dark outer arcs identify groups; 73% and 27% are their totals.
Percentages inside cells are item shares. No statistical uncertainty is shown.
The small step counter and bottom rule show tutorial progress, not data.

Berlin is a real outline containing the same invented group totals. It does not
show Berlin spending or where activities take place. The boundary is the bundled,
50-meter-simplified ALKIS snapshot via TSB. Source and licence details are in
`inst/extdata/region-cities.README.md`. The region example requires `polyclip` and
`sf`; grouping and outer rings are not supported for region layouts.

## The requested base recipe

```r
ggvmap(vm, palette = "reading", label_col = "grey15",
       autoscale = TRUE, min_area = 0.009, wrap = 10) |>
  vm_add_ring(style = "arc", colors = "#333333", values = TRUE)
```

The animation retains these colors and options, with explicit larger label sizes
for the exported teaching frames. Rendering at a sufficiently large physical
plot size keeps text clear of the arc gaps. The value-label frame uses a separate
10% area threshold and a vertical offset to keep numbers away from borders.
These export choices are displayed in its code.

The country section uses `vm_add_flags()` with locally cached flag images, so the
animation can be rebuilt without a network connection after the flag assets are
downloaded. Flags are kept out of the invented budget and Berlin-boundary frames,
where they would have no meaning.

## Rebuild

From the repository root, with the development dependencies installed:

```sh
Rscript examples/linkedin/create_animation.R
python3 examples/linkedin/encode_animation.py
```

Rendering needs R packages devtools, ggplot2, sf, polyclip, and ragg. Encoding
needs Python Pillow, NumPy, and ffmpeg. No generative images are used; the cells, labels,
and rings are actual package output. Frame timing is recorded in `timing.csv`.
