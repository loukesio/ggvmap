# Autoplot method for voronoi_map objects

Produces a ggplot2 visualisation with `geom_polygon()`. For hierarchical
maps the default fill is the group and heavier borders separate the
groups.

## Usage

``` r
# S3 method for class 'voronoi_map'
autoplot(
  object,
  fill_by = NULL,
  border_col = "white",
  border_size = 0.8,
  group_border_col = "white",
  group_border_size = 1.8,
  show_labels = TRUE,
  label_col = "white",
  label_size = 3,
  palette = "Okabe-Ito",
  legend = FALSE,
  interactive = FALSE,
  tooltip = NULL,
  ...
)
```

## Arguments

- object:

  A `voronoi_map` object.

- fill_by:

  Cell aesthetic to map fill to: one of `"label"`, `"group"`,
  `"data_weight"`, or `"none"`. Defaults to `"group"` for hierarchical
  maps and `"label"` otherwise.

- border_col:

  Border colour. Default `"white"`.

- border_size:

  Border line width. Default `0.8`.

- group_border_col:

  Colour of the heavier group boundaries drawn for hierarchical maps.
  `NA` disables them. Default `"white"`.

- group_border_size:

  Line width of group boundaries. Default `1.8`.

- show_labels:

  Logical; add centroid labels? Default `TRUE`.

- label_col:

  Label colour. Default `"white"`.

- label_size:

  Label size. Default `3`.

- palette:

  Character vector of colours, `"Okabe-Ito"` (the default,
  colourblind-safe; see
  [`okabe_ito()`](https://loukesio.github.io/ggvmap/reference/okabe_ito.md)),
  or a named palette from
  [`grDevices::hcl.colors()`](https://rdrr.io/r/grDevices/palettes.html).

- legend:

  Logical; show the fill legend? Default `FALSE`.

- interactive:

  Logical; make the cells interactive (hover highlight and tooltips)
  using ggiraph? Render the result with
  [`vm_girafe()`](https://loukesio.github.io/ggvmap/reference/vm_girafe.md).
  Default `FALSE`.

- tooltip:

  Optional per-cell tooltip text (length-`n`, named by label, or
  length 1) used when `interactive = TRUE`. Defaults to the label and
  value.

- ...:

  Ignored.

## Value

A ggplot object (pass to
[`vm_girafe()`](https://loukesio.github.io/ggvmap/reference/vm_girafe.md)
to render an interactive widget when `interactive = TRUE`).
