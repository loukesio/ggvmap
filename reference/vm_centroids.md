# Centroids of every cell in a voronoi_map

A data frame with one row per cell: `cell`, `label`, `group`, `cx`,
`cy`, `data_weight`, `actual_area`. Useful for placing labels, values,
flags or images (see
[`vm_add_labels()`](https://loukesio.github.io/ggvmap/reference/vm_add_labels.md),
[`vm_add_images()`](https://loukesio.github.io/ggvmap/reference/vm_add_images.md),
[`vm_add_flags()`](https://loukesio.github.io/ggvmap/reference/vm_add_flags.md)).

## Usage

``` r
vm_centroids(vm)
```

## Arguments

- vm:

  A `voronoi_map` object.

## Value

A data frame.
