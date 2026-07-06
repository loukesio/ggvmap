# The Okabe-Ito colourblind-safe qualitative palette

Eight qualitative colours (plus optional black and grey) designed by
Okabe & Ito to be distinguishable by viewers with the common forms of
colour-vision deficiency. This is the default palette used by
[`autoplot.voronoi_map()`](https://loukesio.github.io/ggvmap/reference/autoplot.voronoi_map.md),
[`ggvmap()`](https://loukesio.github.io/ggvmap/reference/ggvmap.md) and
[`vm_add_ring()`](https://loukesio.github.io/ggvmap/reference/vm_add_ring.md).

## Usage

``` r
okabe_ito(n = NULL, black = FALSE, grey = FALSE)
```

## Arguments

- n:

  Number of colours to return. `NULL` (default) returns the whole
  palette. If `n` exceeds the number of available colours they are
  recycled.

- black:

  Include black as the first colour? Default `FALSE`.

- grey:

  Include mid grey as the last colour? Default `FALSE`.

## Value

A character vector of hex colours.

## References

Okabe, M. & Ito, K. (2008). "Color Universal Design (CUD)."

## Examples

``` r
okabe_ito()
#> [1] "#E69F00" "#56B4E9" "#009E73" "#F0E442" "#0072B2" "#D55E00" "#CC79A7"
okabe_ito(3)
#> [1] "#E69F00" "#56B4E9" "#009E73"
okabe_ito(10)          # recycles beyond the 7 base colours
#>  [1] "#E69F00" "#56B4E9" "#009E73" "#F0E442" "#0072B2" "#D55E00" "#CC79A7"
#>  [8] "#E69F00" "#56B4E9" "#009E73"
```
