# Changelog

## ggvmap 0.2.0

### New features

- **Hierarchical (grouped) layouts.**
  [`voronoi_map()`](https://loukesio.github.io/ggvmap/reference/voronoi_map.md)
  gains a `group =` argument. The boundary is first partitioned into one
  convex sub-region per group (area proportional to the group’s total
  weight); each sub-region is then filled with its member cells. On a
  circular boundary the groups are seeded radially so they form
  contiguous angular sectors.

- **Outer annotation ring.**
  [`vm_add_ring()`](https://loukesio.github.io/ggvmap/reference/vm_add_ring.md)
  wraps a circular map in a coloured ring divided into one labelled arc
  segment per group — reproducing the classic Voronoi-treemap
  infographic look. Segment extents are derived from the geometry, so
  the ring lines up with a grouped layout.

- **Flag, image and value annotations.**

  - [`vm_add_images()`](https://loukesio.github.io/ggvmap/reference/vm_add_images.md)
    places arbitrary images (logos, icons, photos) at cell centroids
    (via **ggimage**).
  - [`vm_add_flags()`](https://loukesio.github.io/ggvmap/reference/vm_add_flags.md)
    resolves country names / ISO codes to national flags from
    flagcdn.com, with an offline `cache =` option.
  - [`vm_add_labels()`](https://loukesio.github.io/ggvmap/reference/vm_add_labels.md)
    adds value labels beneath the category names.
  - Helpers
    [`country_to_iso()`](https://loukesio.github.io/ggvmap/reference/country_to_iso.md),
    [`flag_url()`](https://loukesio.github.io/ggvmap/reference/flag_url.md),
    [`flag_cache()`](https://loukesio.github.io/ggvmap/reference/flag_cache.md)
    and
    [`vm_centroids()`](https://loukesio.github.io/ggvmap/reference/vm_centroids.md).

- **Bundled datasets** `world_exports` and `merchant_fleet` for the
  examples and vignette.

### Algorithm & correctness

- **Verified geometry.** A numerical validation study confirms the power
  diagram satisfies its defining property (the cell containing a point
  is the site of minimum power distance), that cells tile the domain
  exactly (to machine epsilon) with no gaps or overlaps, that every cell
  is convex, and that the hierarchical layout is a valid nested power
  diagram. These invariants are now enforced by
  `tests/testthat/test-correctness.R`.
- **Faster, more robust convergence.** Power weights are initialised
  proportional to each cell’s target area, and initial site positions
  use farthest-point (“best candidate”) sampling instead of a purely
  random start. Across a 75-config sweep this removed all transient
  degenerate-cell fallbacks and cut the worst-case per-cell area error
  from ~16x to ~5x.
- `polygon_centroid()` guards against near-zero-area cells (returns the
  vertex mean instead of `NaN`).

### Improvements

- **Okabe-Ito is the default palette.**
  [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html),
  [`ggvmap()`](https://loukesio.github.io/ggvmap/reference/ggvmap.md)
  and
  [`vm_add_ring()`](https://loukesio.github.io/ggvmap/reference/vm_add_ring.md)
  default to the colourblind-safe Okabe-Ito palette (new exported
  [`okabe_ito()`](https://loukesio.github.io/ggvmap/reference/okabe_ito.md)).
  Qualitative palettes are *recycled* (not interpolated) when there are
  more cells than colours, so every cell keeps a true palette colour.
- [`vm_add_flags()`](https://loukesio.github.io/ggvmap/reference/vm_add_flags.md)
  gains a `method` argument: `"geom_flag"` (default) draws flags
  straight from ISO codes via
  [`ggimage::geom_flag()`](https://rdrr.io/pkg/ggimage/man/geom_flag.html),
  while `"url"` keeps the flagcdn.com + `geom_image()` path with offline
  `cache = TRUE`.
- **Interactive plots.** `autoplot(interactive = TRUE)` (and
  `ggvmap(interactive = TRUE)`) makes the cells hoverable with tooltips
  via ; render the widget with the new
  [`vm_girafe()`](https://loukesio.github.io/ggvmap/reference/vm_girafe.md).
- [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
  is group-aware: hierarchical maps default to filling by group and
  drawing heavier group boundaries; new `fill_by` (`"group"`, `"label"`,
  `"data_weight"`, `"none"`) and `legend` arguments; multi-colour
  palettes are interpolated.
- Clip constructors carry `"center"` / `"radius"` / `"shape"` metadata
  used by radial seeding and the ring.
- Plots built by
  [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
  / [`ggvmap()`](https://loukesio.github.io/ggvmap/reference/ggvmap.md)
  carry the `voronoi_map` object as a `"vm"` attribute, enabling the
  `|>` annotation pipeline.

## ggvmap 0.1.0

- First release: pure-R Voronoi map treemaps following Nocaj & Brandes
  (2012), with base-R and ggplot2
  ([`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html),
  [`ggvmap()`](https://loukesio.github.io/ggvmap/reference/ggvmap.md))
  output and convex clip shapes
  ([`clip_square()`](https://loukesio.github.io/ggvmap/reference/clip_shapes.md),
  [`clip_hexagon()`](https://loukesio.github.io/ggvmap/reference/clip_shapes.md),
  [`clip_circle()`](https://loukesio.github.io/ggvmap/reference/clip_shapes.md),
  [`clip_diamond()`](https://loukesio.github.io/ggvmap/reference/clip_shapes.md)).
