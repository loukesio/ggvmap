# Convert a voronoi_map to a tidy data frame

Each row is one vertex of one cell polygon, with columns `cell`,
`label`, `x`, `y`, `target_area`, `actual_area`, `data_weight`.

## Usage

``` r
vm_as_df(vm)
```

## Arguments

- vm:

  A `voronoi_map` or `voronoi_region` object.

## Value

A data frame.

## Details

Region maps from
[`vmap_region()`](https://loukesio.github.io/ggvmap/reference/vmap_region.md)
add `ring`, identifying each boundary ring within a cell. Map `ring` to
`subgroup` and use `rule = "evenodd"` to retain holes when drawing these
rows with `geom_polygon()`.
