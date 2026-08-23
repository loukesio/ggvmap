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
  cells = NULL,
  inside = TRUE,
  min_area = 0,
  autoscale = FALSE,
  family = NULL,
  wrap = NULL
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

  Text colour: a single colour (default `"grey20"`), a length-`n` vector
  in cell order, or a vector named by cell label (cells not named keep
  the default).

- fontface:

  Font face: a single value (default `"plain"`) applied to all labels,
  or a vector named by cell label (e.g. `c(Brazil = "bold")`) styling
  only those cells while the rest stay `"plain"`.

- nudge_x, nudge_y:

  Offset from the centroid. `nudge_y` defaults to a small downward shift
  scaled to each cell so the value sits below the name without leaving
  small cells.

- cells:

  Optional subset of cell labels to annotate.

- inside:

  Logical; clamp the label anchor inside its cell when the nudge would
  push it out? Default `TRUE`.

- min_area:

  Cells whose area fraction of the map is below this threshold get no
  value label. Default `0` (label every cell).

- autoscale:

  Logical; shrink label text in small cells? Each cell's text size
  becomes `size * pmin(1, sqrt(cell_area / median_area))`, floored at
  60% of `size`. Default `FALSE`.

- family:

  Font family for the value labels, passed to the text layer. `NULL`
  (default) uses the ggplot2 default.

- wrap:

  Wrap value labels longer than this many characters onto multiple lines
  (word-aware, via [`strwrap()`](https://rdrr.io/r/base/strwrap.html)).
  Default `NULL` (no wrapping).

## Value

The ggplot with a value-label layer added.
