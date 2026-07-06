# Compute a Voronoi map

Partition a convex polygon into cells whose areas are proportional to a
set of weights, using an iteratively refined power diagram.

## Usage

``` r
voronoi_map(
  weights,
  labels = NULL,
  group = NULL,
  clip = clip_square(),
  convergence_ratio = 0.01,
  max_iter = 200,
  min_weight_ratio = 0.01,
  seed = NULL,
  verbose = FALSE
)
```

## Arguments

- weights:

  Numeric vector of positive weights (one per cell).

- labels:

  Optional character vector of cell labels.

- group:

  Optional grouping vector (one value per cell). When supplied a
  hierarchical layout is produced.

- clip:

  Clipping polygon as a 2-column matrix (x, y), counterclockwise and
  open. Defaults to the unit square.

- convergence_ratio:

  Stop when the total area error divided by the polygon area falls below
  this ratio. Default `0.01` (1%).

- max_iter:

  Maximum number of iterations. Default `200`.

- min_weight_ratio:

  Minimum allowed data weight as a fraction of the maximum weight.
  Prevents near-empty cells. Default `0.01`.

- seed:

  Integer seed for reproducible initial positions. `NULL` (default) uses
  a random layout.

- verbose:

  Print iteration progress? Default `FALSE`.

## Value

An object of class `"voronoi_map"` (a list) containing:

- cells:

  List of 2-column polygon matrices.

- sites:

  Data frame with columns `x`, `y`, `weight`, `target_area`,
  `actual_area`, `label`, `data_weight` and (when hierarchical) `group`.

- clip:

  The clipping polygon.

- groups:

  When hierarchical: a list with the group-level `cells` and `sites`;
  otherwise `NULL`.

- hierarchical:

  Logical flag.

- iterations:

  Number of iterations performed (top level).

- convergence:

  Final area-error ratio.

- converged:

  Logical; did convergence_ratio threshold get reached?

## Details

When `group` is supplied the layout becomes **hierarchical**: the
boundary is first partitioned into one convex sub-region per group (with
area proportional to the group's total weight), and each sub-region is
then filled with its member cells. On a circular boundary the groups are
seeded radially so that they form contiguous angular sectors – the
arrangement the
[`vm_add_ring()`](https://loukesio.github.io/ggvmap/reference/vm_add_ring.md)
annotation ring is designed to wrap.

## Examples

``` r
# Simple example: 5 sectors
vm <- voronoi_map(
  weights = c(3, 2, 5, 1, 4),
  labels  = c("A", "B", "C", "D", "E"),
  seed    = 42
)
plot(vm)


# Hierarchical example on a circular boundary
vm_h <- voronoi_map(
  weights = c(5, 3, 2, 8, 4, 1, 6, 2),
  labels  = letters[1:8],
  group   = c("X", "X", "X", "Y", "Y", "Z", "Z", "Z"),
  clip    = clip_circle(),
  seed    = 1
)
plot(vm_h)

```
