# Add value labels at (or near) cell centroids

Draws a secondary text label per cell – typically a numeric value
beneath the category name added by
[`autoplot.voronoi_map()`](https://loukesio.github.io/ggvmap/reference/autoplot.voronoi_map.md).

## Usage

``` r
vm_add_labels(
  p,
  vm = NULL,
  value = NULL,
  secondary = NULL,
  fmt = NULL,
  prefix = "",
  suffix = "",
  size = 2.8,
  col = "grey20",
  fontface = "plain",
  nudge_x = 0,
  nudge_y = NULL,
  cells = NULL
)
```

## Arguments

- p:

  A ggplot from
  [`autoplot.voronoi_map()`](https://loukesio.github.io/ggvmap/reference/autoplot.voronoi_map.md)
  / [`ggvmap()`](https://loukesio.github.io/ggvmap/reference/ggvmap.md).

- vm:

  Optional `voronoi_map`; taken from `p` when omitted.

- value:

  Values to display: length-`n`, named by label, or length 1. Defaults
  to each cell's `data_weight`.

- secondary:

  Optional second value shown in parentheses (e.g. a count).

- fmt:

  A function applied to `value` (and `secondary`) for formatting, e.g.
  [`scales::comma`](https://scales.r-lib.org/reference/comma.html).
  Default: [`format()`](https://rdrr.io/r/base/format.html) with
  `big.mark = ","`.

- prefix, suffix:

  Strings wrapped around the formatted value.

- size:

  Text size. Default `2.8`.

- col:

  Text colour. Default `"grey20"`.

- fontface:

  Font face. Default `"plain"`.

- nudge_x, nudge_y:

  Offset from the centroid. `nudge_y` defaults to a small downward shift
  scaled to the map so the value sits below the name.

- cells:

  Optional subset of cell labels to annotate.

## Value

The ggplot with a value-label layer added.
