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
#' `alger` is the alger palette from the \pkg{ltc} package with the leading
#' black dropped.  Keys are normalised: lower case, no spaces/underscores/dashes.
#' @noRd
.vm_builtin_palettes <- list(
  alger = c("#1A5B5B", "#ACC8BE", "#F4AB5C", "#D1422F")
)

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
  if (key %in% names(.vm_builtin_palettes)) {
    base <- .vm_builtin_palettes[[key]]
    return(if (continuous || n > length(base)) grDevices::colorRampPalette(base)(n)
           else base[seq_len(n)])
  }
  if (length(palette) > 1L) {
    if (!continuous && n <= length(palette)) palette[seq_len(n)]
    else grDevices::colorRampPalette(palette)(n)
  } else {
    grDevices::hcl.colors(n, palette = palette)
  }
}
