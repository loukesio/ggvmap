# Plot a Voronoi map

Plot a Voronoi map

## Usage

``` r
# S3 method for class 'voronoi_map'
plot(
  x,
  fill = NULL,
  border = "white",
  lwd = 2,
  show_labels = TRUE,
  label_col = "white",
  label_cex = 0.8,
  ...
)
```

## Arguments

- x:

  A `voronoi_map` object.

- fill:

  Character vector of fill colours, one per cell. Defaults to a
  perceptually uniform palette.

- border:

  Border colour. Default `"white"`.

- lwd:

  Border width. Default `2`.

- show_labels:

  Logical; overlay cell labels? Default `TRUE`.

- label_col:

  Colour for labels. Default `"white"`.

- label_cex:

  Label size multiplier. Default `0.8`.

- ...:

  Further arguments passed to
  [`plot.default()`](https://rdrr.io/r/graphics/plot.default.html).
