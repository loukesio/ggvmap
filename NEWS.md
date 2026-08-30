# ggvmap (development version)

## New features

* **All 32 ltc palettes built in.** The `palette` argument now accepts every
  palette of the [ltc package](https://github.com/loukesio/ltc_palettes) by
  name (e.g. `palette = "casa_natal"`), vendored so ltc need not be
  installed. Names match case-insensitively and ignore spaces, underscores
  and dashes. A few palettes are curated for use as map fills (pure-black
  and near-white entries dropped); the `heatmap0`--`heatmap3` ramps are
  always interpolated end-to-end, making them the natural choice for
  `fill_by = "data_weight"`. New `vm_palettes()` lists them all, and an
  unknown palette name now gives an informative error instead of the bare
  `hcl.colors()` one.

* **Per-cell label sizes.** `label_size` (in `ggvmap()`) and `size` (in
  `vm_add_labels()`) now accept a vector named by cell label, matching the
  behaviour already documented for `label_col` and `fontface`; unnamed cells
  keep the default. Previously a named vector was silently recycled in cell
  order, sizing the wrong cells.

## Bug fixes

* **Arc ring labels are no longer struck through by the arc line.** The gap
  cut into the arc under each label was too narrow (and did not scale with
  `label_size`), so long labels overlapped the line. The gap now scales with
  the label's length and size, and a label wider than its own segment (e.g. a
  long group name on a 1% group) keeps its place on the ring — its gap is
  cut into the neighbouring segments' arcs as well, so every label follows
  the same pattern. A message points out when this happens, and an empty
  string in `labels` (e.g. `labels = c("Middle East" = "")`) omits that
  group's ring label and leaves its arc unbroken.

* **`data(freshwater)`** — share of global renewable internal freshwater
  resources by country (2022, FAO Aquastat via World Bank): 30 rows of
  `country`, `share`, `region`. Now the canonical demo dataset; see
  `examples/freshwater_tour.R`.

* **`family` argument** on `ggvmap()` / `autoplot()`, `vm_add_labels()` and
  `vm_add_ring()` — sets the font family of the text layers directly (no more
  `update_geom_defaults()` workaround). Default `NULL` keeps the ggplot2
  default.

* **Arc ring style.** `vm_add_ring(style = "arc")` draws a thin line per group
  instead of the filled band, with the group label sitting in a gap broken
  into the arc at the segment midpoint — the classic infographic look. New
  arc-specific arguments: `linewidth`, `linetype`, `offset` (distance from
  the map edge; `width` is ignored), and `values = TRUE` to append each
  group's share (e.g. "LATAM 32%" with a middle-dot separator).
  `label_col = NULL` (the new default) means white labels on the band and
  arc-coloured labels on the arc; `style = "band"` output is unchanged.

* **Per-cell label colours.** `label_col` (in `ggvmap()`) and `col` (in
  `vm_add_labels()`) now also accept a length-`n` vector or a vector named by
  cell label; unnamed cells keep the default. Handy for light text on dark
  cells.

* **Softer hover highlight.** The `vm_girafe()` default `hover_css` now fades
  the hovered cell and thickens its white outline instead of drawing a dark
  border; pass your own `hover_css` to restore the old effect.

* `vm_add_ring()` gains `label_fontface` (default `"bold"`, the previous
  hard-coded value), completing font control of the ring labels alongside
  `family`, `label_size` and `label_col`.

* **Label wrapping.** `ggvmap()` and `vm_add_labels()` gain `wrap`: labels
  longer than that many characters break onto multiple lines (word-aware,
  via `strwrap()`), so long names fit inside narrow cells.

* `vm_add_ring()` gains `values_sep` (default: middle dot). On Windows
  `pdf()` devices the dot can fail glyph-encoding conversion (seen on CI as
  U+A78F in `mbcsToSbcs`); pass `values_sep = " - "` there. The shipped
  example does so.

# ggvmap 0.3.0

## API change

* **`ggvmap()` is now the main plotting function.** It accepts either an
  existing `voronoi_map` object or a numeric vector of weights (in which case
  the map is computed first, as before). `autoplot()` still works and is now a
  thin wrapper around `ggvmap()`, so existing code keeps running. Note that
  `ggvmap()`'s first argument is now called `x` (was `weights`); calls that
  spelled out `ggvmap(weights = ...)` need updating.

## New features

* **Label font faces.** `ggvmap()` gains a `fontface` argument (default
  `"bold"`, the previous hard-coded behaviour) and `vm_add_labels()`'s existing
  `fontface` is extended: both now also accept a vector *named by cell label*,
  e.g. `c(Brazil = "bold", Russia = "bold.italic")`, styling only those cells
  while the rest stay `"plain"`.

* **Small-cell label handling.** Both `ggvmap()` and `vm_add_labels()` gain:
  * `min_area` — cells whose area fraction is below this threshold get no
    label at all (default `0`, off).
  * `autoscale` — per-cell text size scaled by
    `size * pmin(1, sqrt(cell_area / median_area))`, floored at 60% of `size`,
    so labels shrink gracefully in tiny cells (default `FALSE`).
  * Leader lines / outside callouts for tiny cells are noted as future work;
    they need ggrepel-style logic that would break the zero-dependency goal.

* **Value labels stay inside their cells.** `vm_add_labels()` scales its
  default `nudge_y` to each cell's own size and gains `inside = TRUE`, which
  clamps the label anchor inside the cell polygon.

* **Per-cell label toggling.** `ggvmap(label_cells = c(...))` draws name
  labels only for the given cells; `vm_add_labels(cells = ...)` filters value
  labels the same way.

* **Per-group border colours.** `group_border_col` now also accepts a vector
  named by group, e.g. `c("LATAM" = "#333333")` outlines only that region; a
  plain string still colours all group borders.

* **New built-in palette `"alger"`** (`#1A5B5B`, `#ACC8BE`, `#F4AB5C`,
  `#D1422F`; from the **ltc** package, with its leading black dropped) —
  `ggvmap(vm, palette = "alger")`. Colours are interpolated when a map needs
  more than four. Okabe-Ito remains the default. The README, examples and
  vignettes now use alger.

# ggvmap 0.2.0

## New features

* **Hierarchical (grouped) layouts.** `voronoi_map()` gains a `group =`
  argument. The boundary is first partitioned into one convex sub-region per
  group (area proportional to the group's total weight); each sub-region is
  then filled with its member cells. On a circular boundary the groups are
  seeded radially so they form contiguous angular sectors.

* **Outer annotation ring.** `vm_add_ring()` wraps a circular map in a
  coloured ring divided into one labelled arc segment per group — reproducing
  the classic Voronoi-treemap infographic look. Segment extents are derived
  from the geometry, so the ring lines up with a grouped layout.

* **Flag, image and value annotations.**
  * `vm_add_images()` places arbitrary images (logos, icons, photos) at cell
    centroids (via **ggimage**).
  * `vm_add_flags()` resolves country names / ISO codes to national flags from
    flagcdn.com, with an offline `cache =` option.
  * `vm_add_labels()` adds value labels beneath the category names.
  * Helpers `country_to_iso()`, `flag_url()`, `flag_cache()` and
    `vm_centroids()`.

* **Bundled datasets** `world_exports` and `merchant_fleet` for the examples
  and vignette.

## Algorithm & correctness

* **Verified geometry.** A numerical validation study confirms the power
  diagram satisfies its defining property (the cell containing a point is the
  site of minimum power distance), that cells tile the domain exactly (to
  machine epsilon) with no gaps or overlaps, that every cell is convex, and
  that the hierarchical layout is a valid nested power diagram. These
  invariants are now enforced by `tests/testthat/test-correctness.R`.
* **Faster, more robust convergence.** Power weights are initialised
  proportional to each cell's target area, and initial site positions use
  farthest-point ("best candidate") sampling instead of a purely random start.
  Across a 75-config sweep this removed all transient degenerate-cell
  fallbacks and cut the worst-case per-cell area error from ~16x to ~5x.
* `polygon_centroid()` guards against near-zero-area cells (returns the vertex
  mean instead of `NaN`).

## Improvements

* **Okabe-Ito is the default palette.** `autoplot()`, `ggvmap()` and
  `vm_add_ring()` default to the colourblind-safe Okabe-Ito palette (new
  exported `okabe_ito()`). Qualitative palettes are *recycled* (not
  interpolated) when there are more cells than colours, so every cell keeps a
  true palette colour.
* `vm_add_flags()` gains a `method` argument: `"geom_flag"` (default) draws
  flags straight from ISO codes via `ggimage::geom_flag()`, while `"url"` keeps
  the flagcdn.com + `geom_image()` path with offline `cache = TRUE`.
* **Interactive plots.** `autoplot(interactive = TRUE)` (and
  `ggvmap(interactive = TRUE)`) makes the cells hoverable with tooltips via
  \pkg{ggiraph}; render the widget with the new `vm_girafe()`.
* `autoplot()` is group-aware: hierarchical maps default to filling by group
  and drawing heavier group boundaries; new `fill_by` (`"group"`, `"label"`,
  `"data_weight"`, `"none"`) and `legend` arguments; multi-colour palettes are
  interpolated.
* Clip constructors carry `"center"` / `"radius"` / `"shape"` metadata used by
  radial seeding and the ring.
* Plots built by `autoplot()` / `ggvmap()` carry the `voronoi_map` object as a
  `"vm"` attribute, enabling the `|>` annotation pipeline.

# ggvmap 0.1.0

* First release: pure-R Voronoi map treemaps following Nocaj & Brandes (2012),
  with base-R and ggplot2 (`autoplot()`, `ggvmap()`) output and convex clip
  shapes (`clip_square()`, `clip_hexagon()`, `clip_circle()`, `clip_diamond()`).
