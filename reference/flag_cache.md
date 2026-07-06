# Pre-download flags for offline use

Downloads flag PNGs into a local directory and returns the file paths,
so plots can be rendered without network access. Requires an internet
connection at download time.

## Usage

``` r
flag_cache(
  iso,
  dir = file.path(tempdir(), "ggvmap-flags"),
  width = 160,
  overwrite = FALSE
)
```

## Arguments

- iso:

  Character vector of ISO alpha-2 codes.

- dir:

  Destination directory. Default: a per-session cache under
  [`tempdir()`](https://rdrr.io/r/base/tempfile.html).

- width:

  Pixel width to fetch. Default `160`.

- overwrite:

  Re-download files that already exist? Default `FALSE`.

## Value

Character vector of local file paths (`NA` where download failed).
