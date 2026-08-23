# Add a colored outer annotation ring

Wraps a circular Voronoi map in a decorative ring divided into one arc
segment per group (as in a Voronoi-treemap infographic). Each segment
spans the angular extent actually occupied by its group's cells, so the
ring lines up with a hierarchical layout produced by
`voronoi_map(..., group =)`.

## Usage

``` r
vm_add_ring(
  p,
  vm = NULL,
  groups = NULL,
  colors = NULL,
  labels = TRUE,
  curved = NULL,
  palette = "Okabe-Ito",
  style = c("band", "arc"),
  width = 0.1,
  gap = 0.02,
  pad = 1,
  label_col = NULL,
  label_size = 3.2,
  label_fontface = "bold",
  border_col = "white",
  border_size = 0.4,
  family = NULL,
  linewidth = 0.5,
  linetype = "solid",
  offset = 0.06,
  values = FALSE,
  values_sep = " · "
)
```

## Arguments

- p:

  A ggplot produced by
  [`autoplot.voronoi_map()`](https://loukesio.github.io/ggvmap/reference/autoplot.voronoi_map.md)
  or
  [`ggvmap()`](https://loukesio.github.io/ggvmap/reference/ggvmap.md).

- vm:

  Optional `voronoi_map`; taken from `p` when omitted.

- groups:

  Optional character vector selecting and ordering which groups to draw.
  Defaults to all groups.

- colors:

  Colours for the ring segments (band fills or arc lines): `NULL`
  (default) uses the `palette`, so each group matches its cells; a
  single colour (e.g. `"#333333"`) colours every segment the same; a
  named vector keyed by group (e.g. `c(LATAM = "#333333")` with the
  other groups named too) sets each group individually; an unnamed
  vector is interpolated across the groups. With `style = "arc"`, the
  labels follow the arc colours unless `label_col` is set.

- labels:

  Logical, or a named character vector of display labels keyed by group.
  `TRUE` (default) uses the group names; `FALSE` draws no text.

- curved:

  Draw labels curved along the arc using geomtextpath? `NULL` (default)
  curves them when that package is installed and otherwise uses straight
  tangential text; `TRUE`/`FALSE` force the choice.

- palette:

  Palette used when `colors` is `NULL`. Default `"Okabe-Ito"`.

- style:

  Ring style: `"band"` (default) draws the filled arc segments; `"arc"`
  draws a thin line per group with the group label sitting in a gap
  broken into the arc at the segment midpoint (the classic infographic
  look, e.g. "NORTH AMERICA 13%" with a middle-dot separator).

- width:

  Band thickness as a fraction of the map radius (`style = "band"`
  only). Default `0.10`.

- gap:

  Radial gap between the map and the ring, as a fraction of the radius.
  Default `0.02`.

- pad:

  Angular padding trimmed from each segment end, in degrees. Default
  `1`.

- label_col:

  Ring label colour. `NULL` (default) means `"white"` for
  `style = "band"` and each arc's own colour for `style = "arc"`.

- label_size:

  Ring label size. Default `3.2`.

- label_fontface:

  Ring label font face. Default `"bold"`.

- border_col:

  Segment border colour (`style = "band"`). Default `"white"`.

- border_size:

  Segment border width (`style = "band"`). Default `0.4`.

- family:

  Font family for the ring labels. `NULL` (default) uses the ggplot2
  default.

- linewidth:

  Arc line width (`style = "arc"`). Default `0.5`.

- linetype:

  Arc line type (`style = "arc"`), e.g. `"dashed"`. Default `"solid"`.

- offset:

  Distance of the arc and its label from the map edge, as a fraction of
  the radius (`style = "arc"`; `width` is ignored). Default `0.06`.

- values:

  Append each group's share to its label (`style = "arc"`), e.g. "LATAM
  32%" with a middle-dot separator? Computed from the group weights.
  Default `FALSE`.

- values_sep:

  Separator between the group name and its share. Default is a middle
  dot (`" \u00b7 "`). On Windows
  [`pdf()`](https://rdrr.io/r/grDevices/pdf.html) devices the dot can
  hit an encoding conversion failure – pass an ASCII separator such as
  `" - "` there.

## Value

The ggplot with ring layers added.

## Examples

``` r
vm <- voronoi_map(c(5, 3, 8, 4, 6, 2),
                  group = c("A", "A", "B", "B", "C", "C"),
                  clip = clip_circle(), seed = 1)
ggvmap(vm, palette = "alger") |> vm_add_ring(palette = "alger")

ggvmap(vm, palette = "alger") |>
  vm_add_ring(style = "arc", palette = "alger", values = TRUE,
              values_sep = " - ")   # ASCII sep keeps pdf() happy everywhere
```
