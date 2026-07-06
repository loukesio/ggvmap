# Look up ISO 3166-1 alpha-2 codes for country names

Maps common English and German country names (case-insensitive) to their
lower-case ISO alpha-2 code. Values already looking like a 2-letter code
are passed through. Unknown names return `NA`.

## Usage

``` r
country_to_iso(names)
```

## Arguments

- names:

  Character vector of country names or ISO codes.

## Value

Character vector of lower-case ISO alpha-2 codes (or `NA`).

## Examples

``` r
country_to_iso(c("China", "Deutschland", "United Kingdom", "gr"))
#> [1] "cn" "de" "gb" "gr"
```
