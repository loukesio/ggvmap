# Top merchant fleets 2021

Merchant fleet sizes for 15 countries in 2021: ships on the national
register and total owned. Compiled for illustration.

## Usage

``` r
merchant_fleet
```

## Format

A data frame with 15 rows and 3 columns:

- country:

  Country name.

- registered:

  Number of ships on the national register.

- owned:

  Total number of ships owned by that country's interests.

## Source

Illustrative figures based on UNCTAD / ITF 2021 data.

## Examples

``` r
vm <- voronoi_map(merchant_fleet$owned,
                  labels = merchant_fleet$country,
                  seed = 3)
if (FALSE) { # \dontrun{
autoplot(vm) |>
  vm_add_flags() |>
  vm_add_labels(value = stats::setNames(merchant_fleet$owned,
                                        merchant_fleet$country))
} # }
```
