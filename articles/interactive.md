# Interactive Voronoi maps

``` r

library(ggvmap)
```

Set `interactive = TRUE` on
[`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html) or
[`ggvmap()`](https://loukesio.github.io/ggvmap/reference/ggvmap.md) to
turn any Voronoi map into an interactive graphic powered by
[ggiraph](https://davidgohel.github.io/ggiraph/): cells **highlight on
hover** and show a **tooltip**. Render the result with
[`vm_girafe()`](https://loukesio.github.io/ggvmap/reference/vm_girafe.md).
Everything works in R Markdown / Quarto, Shiny and the RStudio viewer.

## A basic interactive map

Hover the cells — the tooltip shows the label and value.

``` r

vm <- voronoi_map(
  weights = c(30, 20, 50, 10, 40, 15, 25),
  labels  = c("Tech", "Health", "Energy", "Finance", "Retail", "Media", "Auto"),
  clip    = clip_circle(), seed = 42
)

autoplot(vm, interactive = TRUE) |>
  vm_girafe(width_svg = 6, height_svg = 6)
```

## Custom tooltips

Pass `tooltip =` (length-`n`, named by label, or length 1) for your own
hover text — HTML is supported.

``` r

tips <- paste0("<b>", vm$sites$label, "</b><br>", vm$sites$data_weight, "% share")

autoplot(vm, interactive = TRUE, tooltip = tips) |>
  vm_girafe(width_svg = 6, height_svg = 6)
```

## Hierarchical map, interactive

Grouped layouts are interactive too; the default tooltip includes the
group.

``` r

data(world_exports)

vmh <- voronoi_map(
  weights = world_exports$exports,
  labels  = world_exports$country,
  group   = as.character(world_exports$income_group),
  clip    = clip_circle(), seed = 1, max_iter = 80
)

autoplot(vmh, interactive = TRUE, label_size = 2) |>
  vm_girafe(width_svg = 6.5, height_svg = 6.5)
```

## Notes

- [`vm_girafe()`](https://loukesio.github.io/ggvmap/reference/vm_girafe.md)
  accepts `width_svg` / `height_svg` (inches), a `hover_css` string, and
  extra `ggiraph::opts_*()` via `opts =`.
- The static annotation layers
  ([`vm_add_ring()`](https://loukesio.github.io/ggvmap/reference/vm_add_ring.md),
  [`vm_add_flags()`](https://loukesio.github.io/ggvmap/reference/vm_add_flags.md),
  [`vm_add_labels()`](https://loukesio.github.io/ggvmap/reference/vm_add_labels.md))
  render inside the interactive canvas as well — combine them before
  calling
  [`vm_girafe()`](https://loukesio.github.io/ggvmap/reference/vm_girafe.md).
- Saved with
  [`htmlwidgets::saveWidget()`](https://rdrr.io/pkg/htmlwidgets/man/saveWidget.html),
  an interactive map is a single self-contained `.html` file you can
  share.

``` r

g <- autoplot(vm, interactive = TRUE) |> vm_girafe()
htmlwidgets::saveWidget(g, "voronoi.html", selfcontained = TRUE)
```
