# Add country flags at cell centroids

Resolves country names or ISO codes to national flags and places them at
the cell centroids. Requires the ggimage package and (unless
`cache = TRUE`) internet access.

## Usage

``` r
vm_add_flags(
  p,
  vm = NULL,
  country = NULL,
  iso = NULL,
  size = 0.045,
  method = c("geom_flag", "url"),
  width = 160,
  cache = FALSE,
  nudge_x = 0,
  nudge_y = 0,
  cells = NULL,
  ...
)
```

## Arguments

- p:

  A ggplot from
  [`autoplot.voronoi_map()`](https://loukesio.github.io/ggvmap/reference/autoplot.voronoi_map.md)
  / [`ggvmap()`](https://loukesio.github.io/ggvmap/reference/ggvmap.md).

- vm:

  Optional `voronoi_map`; taken from `p` when omitted.

- country:

  Country names (see
  [`country_to_iso()`](https://loukesio.github.io/ggvmap/reference/country_to_iso.md)):
  length-`n`, named by label, or length 1. Defaults to the cell labels.

- iso:

  ISO alpha-2 codes, as an alternative to `country`.

- size:

  Flag size as a fraction of the plot. Default `0.045`.

- method:

  Rendering back-end: `"geom_flag"` (default) or `"url"`.

- width:

  Pixel width of the fetched flag PNG (`method = "url"` only). Default
  `160`.

- cache:

  Pre-download flags for offline rendering via
  [`flag_cache()`](https://loukesio.github.io/ggvmap/reference/flag_cache.md)
  (`method = "url"` only)? Default `FALSE`.

- nudge_x, nudge_y:

  Offset from the centroid in data units. Default `0`.

- cells:

  Optional subset of cell labels to annotate.

- ...:

  Passed to the underlying geom.

## Value

The ggplot with a flag layer added.

## Details

Two rendering back-ends are available via `method`:

- `"geom_flag"`:

  (default when available) uses
  [`ggimage::geom_flag()`](https://rdrr.io/pkg/ggimage/man/geom_flag.html),
  which draws flags directly from ISO codes – no URLs to build.
  Simplest, and matches the flag set shipped with ggimage.

- `"url"`:

  builds flagcdn.com URLs (see
  [`flag_url()`](https://loukesio.github.io/ggvmap/reference/flag_url.md))
  and draws them with
  [`ggimage::geom_image()`](https://rdrr.io/pkg/ggimage/man/geom_image.html)
  via
  [`vm_add_images()`](https://loukesio.github.io/ggvmap/reference/vm_add_images.md).
  Supports `width` and offline `cache = TRUE` via
  [`flag_cache()`](https://loukesio.github.io/ggvmap/reference/flag_cache.md).

## Examples

``` r
if (FALSE) { # \dontrun{
vm <- voronoi_map(c(5, 3, 2), labels = c("China", "Norway", "Japan"),
                  seed = 1)
autoplot(vm) |> vm_add_flags()                    # geom_flag
autoplot(vm) |> vm_add_flags(method = "url")      # flagcdn + geom_image
} # }
```
