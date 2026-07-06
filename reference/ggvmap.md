# Quick ggplot2 Voronoi map

Compute *and* plot a Voronoi map in a single call.

## Usage

``` r
ggvmap(
  weights,
  labels = NULL,
  group = NULL,
  clip = clip_square(),
  convergence_ratio = 0.01,
  max_iter = 50,
  min_weight_ratio = 0.01,
  seed = NULL,
  fill_by = NULL,
  palette = "Okabe-Ito",
  border_col = "white",
  border_size = 0.8,
  show_labels = TRUE,
  label_col = "white",
  label_size = 3,
  legend = FALSE,
  interactive = FALSE
)
```

## Arguments

- weights:

  Numeric vector of positive weights (one per cell).

- labels:

  Optional character vector of cell labels.

- group:

  Optional grouping vector (one value per cell). When supplied a
  hierarchical layout is produced.

- clip:

  Clipping polygon as a 2-column matrix (x, y), counterclockwise and
  open. Defaults to the unit square.

- convergence_ratio:

  Stop when the total area error divided by the polygon area falls below
  this ratio. Default `0.01` (1%).

- max_iter:

  Maximum number of iterations. Default `200`.

- min_weight_ratio:

  Minimum allowed data weight as a fraction of the maximum weight.
  Prevents near-empty cells. Default `0.01`.

- seed:

  Integer seed for reproducible initial positions. `NULL` (default) uses
  a random layout.

- fill_by:

  Cell aesthetic to map fill to: one of `"label"`, `"group"`,
  `"data_weight"`, or `"none"`. Defaults to `"group"` for hierarchical
  maps and `"label"` otherwise.

- palette:

  Character vector of colours, `"Okabe-Ito"` (the default,
  colourblind-safe; see
  [`okabe_ito()`](https://loukesio.github.io/ggvmap/reference/okabe_ito.md)),
  or a named palette from
  [`grDevices::hcl.colors()`](https://rdrr.io/r/grDevices/palettes.html).

- border_col:

  Border colour. Default `"white"`.

- border_size:

  Border line width. Default `0.8`.

- show_labels:

  Logical; add centroid labels? Default `TRUE`.

- label_col:

  Label colour. Default `"white"`.

- label_size:

  Label size. Default `3`.

- legend:

  Logical; show the fill legend? Default `FALSE`.

- interactive:

  Logical; make the cells interactive (hover highlight and tooltips)
  using ggiraph? Render the result with
  [`vm_girafe()`](https://loukesio.github.io/ggvmap/reference/vm_girafe.md).
  Default `FALSE`.

## Value

A ggplot object (invisibly also stores the `voronoi_map` object as
attribute `"vm"`).

## Examples

``` r
ggvmap(
  weights = c(3, 2, 5, 1, 4),
  labels  = c("A", "B", "C", "D", "E"),
  seed    = 42
)

```
