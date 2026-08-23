# Autoplot method for voronoi_map objects

A thin wrapper around
[`ggvmap()`](https://loukesio.github.io/ggvmap/reference/ggvmap.md),
kept so the standard ggplot2
[`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
generic keeps working: `autoplot(vm, ...)` is identical to
`ggvmap(vm, ...)`.

## Usage

``` r
# S3 method for class 'voronoi_map'
autoplot(object, ...)
```

## Arguments

- object:

  A `voronoi_map` object.

- ...:

  Passed to
  [`ggvmap()`](https://loukesio.github.io/ggvmap/reference/ggvmap.md).

## Value

A ggplot object.
