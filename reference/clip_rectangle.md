# Rectangular clipping boundary

A (possibly non-square) axis-aligned rectangle. Convex, so it tiles
correctly.

## Usage

``` r
clip_rectangle(cx = 0.5, cy = 0.5, width = 1, height = 0.6)
```

## Arguments

- cx, cy:

  Centre coordinates. Default `0.5`.

- width, height:

  Full width and height. Defaults `1` and `0.6`.

## Value

A 2-column matrix suitable for the `clip` argument of
[`voronoi_map()`](https://loukesio.github.io/ggvmap/reference/voronoi_map.md).

## Examples

``` r
plot(voronoi_map(c(3, 2, 5, 4), clip = clip_rectangle(), seed = 1))
```
