# ---- Colour palettes ----

#' The Okabe-Ito colourblind-safe qualitative palette
#'
#' Eight qualitative colours (plus optional black and grey) designed by Okabe &
#' Ito to be distinguishable by viewers with the common forms of colour-vision
#' deficiency.  This is the default palette used by [autoplot.voronoi_map()],
#' [ggvmap()] and [vm_add_ring()].
#'
#' @param n Number of colours to return.  `NULL` (default) returns the whole
#'   palette.  If `n` exceeds the number of available colours they are recycled.
#' @param black Include black as the first colour?  Default `FALSE`.
#' @param grey Include mid grey as the last colour?  Default `FALSE`.
#' @return A character vector of hex colours.
#' @references Okabe, M. & Ito, K. (2008). "Color Universal Design (CUD)."
#' @examples
#' okabe_ito()
#' okabe_ito(3)
#' okabe_ito(10)          # recycles beyond the 7 base colours
#' @export
okabe_ito <- function(n = NULL, black = FALSE, grey = FALSE) {
  cols <- c(
    "#E69F00", # orange
    "#56B4E9", # sky blue
    "#009E73", # bluish green
    "#F0E442", # yellow
    "#0072B2", # blue
    "#D55E00", # vermillion
    "#CC79A7"  # reddish purple
  )
  if (black) cols <- c("#000000", cols)
  if (grey)  cols <- c(cols, "#999999")
  if (is.null(n)) return(cols)
  rep_len(cols, n)
}

#' Names that resolve to the Okabe-Ito palette
#' @noRd
.okabe_aliases <- c("okabeito", "okabe", "okabe-ito", "oi", "cud")

#' Built-in named palettes (beyond Okabe-Ito)
#'
#' All 32 palettes of the \pkg{ltc} package
#' (https://github.com/loukesio/ltc_palettes), vendored so they work by name
#' with no extra dependency.  A few are curated for use as cell fills on a
#' white background: pure-black and near-white entries are dropped (from
#' `alger`, `hat`, `casa_natal`, `luminaries`, `seafarer`, `lincoln`,
#' `midnight`, `remains`, and `maya`).  Lookup normalises the name: lower
#' case, spaces/underscores/dashes ignored, so `"casa_natal"`,
#' `"Casa Natal"` and `"casanatal"` all match.
#' @noRd
.vm_builtin_palettes <- list(
  paloma     = c("#83AF9B", "#C8C8A9", "#f8da8a", "#f7bf95", "#fe8ca1"),
  maya       = c("#3d5a80", "#98c1d9", "#ee6c4d", "#293241"),
  dora       = c("#52777A", "#542437", "#C02942", "#D95B43", "#ECD078"),
  ploen      = c("#3F5671", "#83A1C3", "#CEB5C8", "#FAC898", "#B17776"),
  olga       = c("#c9e3c2", "#8bc8cb", "#eccd80", "#f5ab70", "#9c87a1"),
  mterese    = c("#f7ddaa", "#fac3ad", "#f897a1", "#9298BA", "#9cbeed"),
  gaby       = c("#fceaab", "#f1a890", "#a8c4cc", "#82A0C2", "#85496F"),
  franscoise = c("#5980B1", "#b96a8d", "#A55062", "#E05256", "#E9A986"),
  fernande   = c("#ff7676", "#F9D662", "#7cab7d", "#75B7D1"),
  sylvie     = c("#E8B961", "#E88170", "#C6BDE8", "#5DB7C4", "#FD95BC"),
  expevo     = c("#FC4E07", "#E7B800", "#00AFBB", "#8B4769", "#1d457f", "#808080"),
  minou      = c("#00798c", "#d1495b", "#edae49", "#66a182", "#2e4057", "#8d96a3"),
  kiss       = c("#FF7C7E", "#FEC300", "#9E3F71", "#31BCBA", "#E20035"),
  hat        = c("#efb306", "#eb990c", "#e8351e", "#cd023d", "#852f88",
                 "#4e54ac", "#0f8096", "#7db954", "#17a769"),
  reading    = c("#EFBC68", "#919F89", "#EDBDAE", "#57717C", "#5F97A4",
                 "#CAEAC8", "#95A1AE", "#C8CFD6"),
  alger      = c("#1A5B5B", "#ACC8BE", "#F4AB5C", "#D1422F"),
  trio1      = c("#0E7175", "#FD7901", "#C35BCA"),
  trio2      = c("#89973D", "#E8B92F", "#A45E41"),
  trio3      = c("#E69F00", "#56B4E9", "#009E73"),
  trio4      = c("#94475E", "#364C54", "#E5A11F"),
  heatmap0   = c("#001219", "#005F73", "#0A9396", "#94D2BD", "#E9D8A6",
                 "#EE9B00", "#CA6702", "#AE2012", "#9B2226"),
  pantone23  = c("#7A92A5", "#1F2C43", "#FFB000", "#842c48", "#46483d"),
  remains    = c("#69326E", "#FF6D1F", "#EED455"),
  midnight   = c("#16232A", "#FF5B04", "#075056"),
  lincoln    = c("#C9C1B1", "#2C3B4D", "#FFB162", "#A35139", "#1B2632"),
  luminaries = c("#FF5B04", "#075056", "#233038", "#F4D47C", "#D3DBDD"),
  seafarer   = c("#013D5A", "#BDD3CE", "#708C69", "#E4A25B"),
  shuggie    = c("#5B5F8D", "#9BB29E", "#DA6B51", "#F1DCBA", "#484149"),
  heatmap1   = c("#4d7799", "#7fa4c4", "#c5c8d4", "#d48e95", "#b5515b"),
  heatmap2   = c("#ca0020", "#f4a582", "#f7f7f7", "#92c5de", "#0571b0"),
  heatmap3   = c("#d7191c", "#fdae61", "#ffffbf", "#abd9e9", "#2c7bb6"),
  casa_natal = c("#245E55", "#ED773C", "#808BC5", "#C63F3E", "#EAC119",
                 "#EAA7C7", "#9ED6DF")
)

#' Built-in palettes that are ordered ramps, not qualitative sets
#'
#' These are sequential/diverging scales; picking their first `n` colours for
#' categorical fill would be misleading, so they are always interpolated
#' end-to-end.
#' @noRd
.vm_ramp_palettes <- c("heatmap0", "heatmap1", "heatmap2", "heatmap3")

#' List the built-in colour palettes
#'
#' Returns the built-in named palettes that the `palette` argument of
#' [ggvmap()], [vm_add_ring()] and friends accepts as a string: the 32
#' palettes of the ltc package (vendored, so ltc need not be installed; a few
#' are curated for use as map fills -- pure-black and near-white entries are
#' dropped).  Palette names are matched case-insensitively and ignore
#' spaces, underscores, and dashes.  The `heatmap0`--`heatmap3` palettes are
#' ordered ramps intended for continuous fill (`fill_by = "data_weight"`)
#' and are always interpolated end-to-end.
#'
#' @return A named list of hex-colour vectors.
#' @examples
#' names(vm_palettes())
#' vm_palettes()$casa_natal
#' @export
vm_palettes <- function() .vm_builtin_palettes

#' Resolve a palette specification to a vector of `n` colours
#'
#' Accepts a colour vector, a named `grDevices::hcl.colors()` palette,
#' `"Okabe-Ito"`, or a built-in named palette (see `.vm_builtin_palettes`).
#'
#' For **categorical** use (`continuous = FALSE`, the default) the Okabe-Ito
#' palette is *recycled* when `n` exceeds its length, so every cell keeps a
#' true palette colour rather than a muddy interpolated one; smaller built-in
#' palettes such as `"alger"` are interpolated via [grDevices::colorRampPalette()]
#' when more colours are needed.  For **continuous** use the colours are
#' interpolated into a smooth ramp.
#' @noRd
.vm_palette <- function(n, palette, continuous = FALSE) {
  key <- if (length(palette) == 1L) gsub("[ _-]", "", tolower(palette)) else ""
  if (key %in% .okabe_aliases) {
    base <- okabe_ito()
    return(if (continuous) grDevices::colorRampPalette(base)(n) else rep_len(base, n))
  }
  hit <- match(key, gsub("[ _-]", "", tolower(names(.vm_builtin_palettes))))
  if (!is.na(hit)) {
    base <- .vm_builtin_palettes[[hit]]
    ramp <- names(.vm_builtin_palettes)[hit] %in% .vm_ramp_palettes
    return(if (continuous || ramp || n > length(base))
             grDevices::colorRampPalette(base)(n)
           else base[seq_len(n)])
  }
  if (length(palette) > 1L) {
    if (!continuous && n <= length(palette)) palette[seq_len(n)]
    else grDevices::colorRampPalette(palette)(n)
  } else {
    tryCatch(
      grDevices::hcl.colors(n, palette = palette),
      error = function(e) stop(
        "Unknown palette \"", palette, "\". Supply a vector of colours, ",
        "an hcl.colors() palette name, \"Okabe-Ito\", or one of the ",
        "built-in palettes listed by vm_palettes().", call. = FALSE)
    )
  }
}
