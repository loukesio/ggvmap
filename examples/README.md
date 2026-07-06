# ggvmap example gallery

Rendered with `ggvmap` v0.2.0. Reproduce any of them with the package loaded
(`devtools::load_all("ggvmap")`).

| File | What it shows |
|---|---|
| `01_shape_square.png` | Flat map, `clip_square()` |
| `01_shape_hexagon.png` | Flat map, `clip_hexagon()` |
| `01_shape_circle.png` | Flat map, `clip_circle()` |
| `01_shape_diamond.png` | Flat map, `clip_diamond()` |
| `02_fill_weight.png` | `autoplot(fill_by = "data_weight")` with a viridis ramp |
| `03_grouped_square.png` | Hierarchical nested treemap (groups → sub-regions) on a square |
| `04_ring_custom.png` | World exports, grouped by income + custom-coloured outer ring |
| `05_flags_circle.png` | Top-8 merchant fleets, flags + value labels on a circle |
| `06_combined.png` | Everything: grouped sectors + ring + flags in one plot |
| `interactive_demo.html` | **Live interactive** map (open in a browser) — hover cells for tooltips, via ggiraph |

The interactive map is HTML/JS, so it only works in a browser (not in GitHub's
markdown preview). Double-click `interactive_demo.html`, or see the live version
in the [Annotations article](https://loukesio.github.io/ggvmap/articles/annotations.html#interactive-maps)
on the docs site. Reproduce with:

```r
vm <- voronoi_map(c(30,20,50,10,40,15,25),
                  labels = c("Tech","Health","Energy","Finance","Retail","Media","Auto"),
                  clip = clip_circle(), seed = 42)
autoplot(vm, interactive = TRUE) |> vm_girafe()
```

The two "reference replicas" also live at
`../man/figures/showcase_ring.png` and
`../man/figures/showcase_flags.png`.
