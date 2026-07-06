# Elliptical clipping boundary

A convex ellipse approximated by an `n`-gon.

## Usage

``` r
clip_ellipse(cx = 0.5, cy = 0.5, a = 0.5, b = 0.32, n = 72)
```

## Arguments

- cx, cy:

  Centre coordinates. Default `0.5`.

- a, b:

  Semi-axis lengths (x and y radii). Defaults `0.5` and `0.32`.

- n:

  Number of vertices used to approximate the ellipse. Default `72`.

## Value

A 2-column matrix suitable for the `clip` argument of
[`voronoi_map()`](https://loukesio.github.io/ggvmap/reference/voronoi_map.md).

## Examples

``` r
plot(voronoi_map(c(3, 2, 5, 4, 6), clip = clip_ellipse(), seed = 1))
```
