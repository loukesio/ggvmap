# Centroids of every cell in a voronoi_map

A data frame with one row per cell: `cell`, `label`, `group`, `cx`,
`cy`, `data_weight`, `actual_area`. Useful for placing labels, values,
flags or images (see
[`vm_add_labels()`](https://loukesio.github.io/ggvmap/reference/vm_add_labels.md),
[`vm_add_images()`](https://loukesio.github.io/ggvmap/reference/vm_add_images.md),
[`vm_add_flags()`](https://loukesio.github.io/ggvmap/reference/vm_add_flags.md)).

## Usage

``` r
vm_centroids(vm, inside = FALSE)
```

## Arguments

- vm:

  A `voronoi_map` or `voronoi_region` object.

- inside:

  For region maps, return an interior label anchor when the area
  centroid lies outside the cell or in a hole? Default `FALSE` returns
  the mathematical centroid. Convex maps are unaffected.

## Value

A data frame.
