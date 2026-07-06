# World goods exports 2021

Approximate merchandise exports for 40 economies in 2021, tagged with
their World Bank income group. Compiled for illustration; values are
rounded.

## Usage

``` r
world_exports
```

## Format

A data frame with 40 rows and 3 columns:

- country:

  Country / economy name.

- exports:

  Goods exports in billions of US dollars.

- income_group:

  Factor: World Bank income group (`"High income"`, `"Upper middle"`,
  `"Lower middle"`, `"Low income"`).

## Source

Illustrative figures based on WTO / World Bank 2021 data.

## Examples

``` r
vm <- voronoi_map(world_exports$exports,
                  labels = world_exports$country,
                  group  = as.character(world_exports$income_group),
                  clip   = clip_circle(), seed = 1)
autoplot(vm, show_labels = FALSE) |> vm_add_ring()
```
