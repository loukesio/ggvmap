# Generate common clipping shapes

Convenience wrappers around
[`regular_polygon()`](https://loukesio.github.io/ggvmap/reference/regular_polygon.md)
for common shapes.

## Usage

``` r
clip_square(cx = 0.5, cy = 0.5, r = 0.5)

clip_hexagon(cx = 0.5, cy = 0.5, r = 0.5)

clip_circle(cx = 0.5, cy = 0.5, r = 0.5, n = 64)

clip_diamond(cx = 0.5, cy = 0.5, r = 0.5)
```

## Arguments

- cx, cy:

  Centre coordinates. Default `0.5`.

- r:

  Radius (half-width for the square). Default `0.5`.

- n:

  Number of sides used to approximate the circle. Default `64`.

## Value

A 2-column matrix suitable for the `clip` argument of
[`voronoi_map()`](https://loukesio.github.io/ggvmap/reference/voronoi_map.md).
