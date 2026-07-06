# Add images at cell centroids

Places an image (logo, icon, flag, photo) at the centroid of each cell.
Requires the ggimage package.

## Usage

``` r
vm_add_images(
  p,
  vm = NULL,
  image,
  size = 0.05,
  by = "width",
  asp = 1,
  alpha = 1,
  nudge_x = 0,
  nudge_y = 0,
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

- image:

  Image paths or URLs: length-`n` (cell order), named by cell label, or
  length 1. `NA` entries are skipped.

- size:

  Image size as a fraction of the plot. Default `0.05`.

- by:

  Size dimension passed to
  [`ggimage::geom_image()`](https://rdrr.io/pkg/ggimage/man/geom_image.html):
  `"width"` (default) or `"height"`.

- asp:

  Aspect-ratio correction passed to
  [`ggimage::geom_image()`](https://rdrr.io/pkg/ggimage/man/geom_image.html).
  Default `1`.

- alpha:

  Image opacity. Default `1`.

- nudge_x, nudge_y:

  Position offset in data units. Default `0`.

- cells:

  Optional subset of cell labels to annotate.

## Value

The ggplot with an image layer added.
