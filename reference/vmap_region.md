# Fit a Voronoi map inside a non-convex or multipart region

Partition a supplied outline into cells whose areas approximate positive
weights. Unlike
[`voronoi_map()`](https://loukesio.github.io/ggvmap/reference/voronoi_map.md),
this function supports inward dents, holes, and disconnected pieces.
Requires the optional package polyclip.

## Usage

``` r
vmap_region(
  weights,
  region,
  labels = NULL,
  crs = NULL,
  seed = NULL,
  max_iter = 1000,
  convergence_ratio = 0.005,
  min_weight_ratio = 0,
  verbose = FALSE
)
```

## Arguments

- weights:

  Finite positive numeric weights, one per cell.

- region:

  A two-column coordinate matrix; a ring `list(x = ..., y = ...)`; a
  list of such matrices or rings; or an `sf`/`sfc` polygon object.
  Matrix and ring coordinates are treated as planar. Rings use the
  even-odd fill rule: a ring inside another ring is a hole, regardless
  of orientation. Repeated closing vertices are optional. For `sf`, all
  features are united into one region; use separate calls to fit
  districts independently.

- labels:

  Optional unique cell labels, otherwise `V1`, `V2`, etc.

- crs:

  Optional projected coordinate system passed to
  [`sf::st_transform()`](https://r-spatial.github.io/sf/reference/st_transform.html)
  for `sf`/`sfc` input. Geographic longitude/latitude input must be
  projected explicitly. No place-name lookup or automatic projection is
  performed.

- seed:

  Optional integer seed. When supplied, the caller's random-number state
  is restored after computation.

- max_iter:

  Maximum number of iterations; default `1000`.

- convergence_ratio:

  Stop when the sum of absolute cell-area errors, divided by region
  area, is below this value; default `0.005`.

- min_weight_ratio:

  Minimum weight as a fraction of the largest weight. Default `0`
  preserves the requested proportions. Positive values inflate small
  weights and change the targets.

- verbose:

  Print progress every 25 iterations?

## Value

A `voronoi_region` object inheriting from `voronoi_map`. It contains
`cells` (one list of rings per cell), `clip` (the region rings), `sites`
(positions, power weights, labels, data weights, target and actual
areas), `iterations`, `convergence`, `converged`, `total_area`, and
`crs` (an `sf` CRS for spatial input, otherwise `NULL`). Each ring is
`list(x, y)`; outer rings are counterclockwise and holes clockwise.
Coordinates use the output planar units; areas use their squares.
[`vm_as_df()`](https://loukesio.github.io/ggvmap/reference/vm_as_df.md)
adds a `ring` column, to be mapped to `subgroup` with `rule = "evenodd"`
when plotting.

## Details

Computation uses translated, uniformly scaled coordinates to avoid
instability with large map coordinates. Output coordinates and areas are
restored to the input (or requested projected) coordinate system.
Boundaries are not simplified automatically. Invalid `sf` geometry is
rejected; repair it explicitly before calling. Coordinate rings are
interpreted with the even-odd rule and normalized by `polyclip`.

Cells may contain several disconnected pieces or holes. A successful
area fit does not imply geographically meaningful cell positions.
Convergence is not guaranteed for every shape or weight distribution: an
unsuccessful fit emits a warning and returns the best layout found with
`converged = FALSE`. Never use an unchecked layout as an exact encoding.
After at most 100 position/weight iterations, a stalled fit uses the
remaining iteration budget for fixed-site, coordinate-wise weight
searches. These power weights may be negative; data weights remain
positive.

Supports
[`ggvmap()`](https://loukesio.github.io/ggvmap/reference/ggvmap.md),
[`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html),
[`plot()`](https://r-spatial.github.io/sf/reference/plot.html),
[`vm_as_df()`](https://loukesio.github.io/ggvmap/reference/vm_as_df.md),
[`vm_centroids()`](https://loukesio.github.io/ggvmap/reference/vm_centroids.md),
and ordinary cell annotations. Hierarchical grouping is not implemented;
fit separate regions separately. Interactive rendering and the
decorative outer ring are currently unavailable for region maps.

## Examples

``` r
if (requireNamespace("polyclip", quietly = TRUE)) {
  outline <- cbind(c(0, 3, 3, 1, 1, 0), c(0, 0, 1, 1, 3, 3))
  vm <- vmap_region(c(5, 3, 2), outline, seed = 4)
  print(vm)
  ggvmap(vm, palette = "alger")
}
#> Voronoi Map
#>   3 cells | 12 iterations | convergence: 0.333%
#>   Converged: TRUE
```
