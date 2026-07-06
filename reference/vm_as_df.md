# Convert a voronoi_map to a tidy data frame

Each row is one vertex of one cell polygon, with columns `cell`,
`label`, `x`, `y`, `target_area`, `actual_area`, `data_weight`.

## Usage

``` r
vm_as_df(vm)
```

## Arguments

- vm:

  A `voronoi_map` object.

## Value

A data frame.
