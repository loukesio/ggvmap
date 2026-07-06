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

The two "reference replicas" also live at
`../man/figures/showcase_ring.png` and
`../man/figures/showcase_flags.png`.
