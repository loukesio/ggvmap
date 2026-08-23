# Global renewable freshwater resources 2022

Share of the world's renewable internal freshwater resources for 25
countries plus five "Rest of " aggregates (30 rows, summing to ~100%).
This is the package's canonical demo dataset; see
`examples/freshwater_tour.R` for a full tour.

## Usage

``` r
freshwater
```

## Format

A data frame with 30 rows and 3 columns:

- country:

  Country name or regional remainder (e.g. `"Rest of LATAM"`).

- share:

  Share of global renewable internal freshwater resources, in percent
  (2022, rounded).

- region:

  Region: `"LATAM"`, `"Asia-Pacific"`, `"North America"`, `"Europe"`,
  `"Africa"`, or `"Middle East"`.

## Source

FAO Aquastat via World Bank, 2022 figures.

## Examples

``` r
vm <- voronoi_map(freshwater$share,
                  labels = freshwater$country,
                  group  = freshwater$region,
                  clip   = clip_circle(), seed = 5)
ggvmap(vm, palette = "alger", autoscale = TRUE)
```
