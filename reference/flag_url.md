# URL of a flag PNG on flagcdn.com

URL of a flag PNG on flagcdn.com

## Usage

``` r
flag_url(iso, width = 160)
```

## Arguments

- iso:

  Character vector of ISO alpha-2 codes (see
  [`country_to_iso()`](https://loukesio.github.io/ggvmap/reference/country_to_iso.md)).

- width:

  Pixel width of the served PNG (flagcdn offers 20-2560). Default `160`.

## Value

Character vector of URLs (`NA` where `iso` is `NA`).

## Examples

``` r
flag_url(country_to_iso(c("China", "Norway")))
#> [1] "https://flagcdn.com/w160/cn.png" "https://flagcdn.com/w160/no.png"
```
