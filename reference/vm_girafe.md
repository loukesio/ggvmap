# Render an interactive Voronoi map

Wraps a plot built with `interactive = TRUE` (see
[`autoplot.voronoi_map()`](https://loukesio.github.io/ggvmap/reference/autoplot.voronoi_map.md)
/ [`ggvmap()`](https://loukesio.github.io/ggvmap/reference/ggvmap.md))
into a ggiraph `girafe` htmlwidget, so cells highlight on hover and show
tooltips. Works in R Markdown / Quarto, Shiny and the RStudio viewer.

## Usage

``` r
vm_girafe(
  p,
  width_svg = 7,
  height_svg = 7,
  hover_css = "stroke:#222222;stroke-width:1.4px;",
  opts = NULL,
  ...
)
```

## Arguments

- p:

  A ggplot built with `interactive = TRUE`.

- width_svg, height_svg:

  Size of the SVG canvas in inches. Default `7`.

- hover_css:

  CSS applied to the hovered cell. Default highlights its outline.

- opts:

  Optional list of extra ggiraph `opts_*()` objects to append.

- ...:

  Passed to
  [`ggiraph::girafe()`](https://davidgohel.github.io/ggiraph/reference/girafe.html).

## Value

A `girafe` htmlwidget.

## Examples

``` r
if (FALSE) { # \dontrun{
vm <- voronoi_map(c(5, 3, 8, 2, 6), labels = LETTERS[1:5], seed = 1)
autoplot(vm, interactive = TRUE) |> vm_girafe()
} # }
```
