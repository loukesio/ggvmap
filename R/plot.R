# ---- Plotting: base R + ggplot2 integration ----

#' @importFrom grDevices hcl.colors
#' @importFrom ggplot2 ggplot aes geom_polygon geom_text theme_void
#'   coord_equal labs scale_fill_manual
NULL

# --- Base R plot method -----------------------------------------------------

#' Plot a Voronoi map
#'
#' @param x A `voronoi_map` object.
#' @param fill Character vector of fill colours, one per cell.
#'   Defaults to a perceptually uniform palette.
#' @param border Border colour.  Default `"white"`.
#' @param lwd Border width.  Default `2`.
#' @param show_labels Logical; overlay cell labels?  Default `TRUE`.
#' @param label_col Colour for labels.  Default `"white"`.
#' @param label_cex Label size multiplier.  Default `0.8`.
#' @param ... Further arguments passed to [plot.default()].
#'
#' @export
plot.voronoi_map <- function(
  x,
  fill        = NULL,
  border      = "white",
  lwd         = 2,
  show_labels = TRUE,
  label_col   = "white",
  label_cex   = 0.8,
  ...
) {
  n <- length(x$cells)
  if (is.null(fill)) {
    fill <- grDevices::hcl.colors(n, palette = "Dark 3")
  }
  fill <- rep_len(fill, n)

  xr <- range(x$clip[, 1])
  yr <- range(x$clip[, 2])

  plot(NULL, xlim = xr, ylim = yr, asp = 1, axes = FALSE,
       xlab = "", ylab = "", ...)

  for (i in seq_len(n)) {
    cell <- x$cells[[i]]
    graphics::polygon(cell[, 1], cell[, 2],
                      col = fill[i], border = border, lwd = lwd)
  }

  if (show_labels) {
    for (i in seq_len(n)) {
      ctr <- polygon_centroid(x$cells[[i]])
      graphics::text(ctr[1], ctr[2], labels = x$sites$label[i],
                     col = label_col, cex = label_cex, font = 2)
    }
  }
}

# --- ggplot2 integration ---------------------------------------------------

#' Convert a voronoi_map to a tidy data frame
#'
#' Each row is one vertex of one cell polygon, with columns
#' `cell`, `label`, `x`, `y`, `target_area`, `actual_area`, `data_weight`.
#'
#' @param vm A `voronoi_map` object.
#' @return A data frame.
#' @export
vm_as_df <- function(vm) {
  grp <- if (!is.null(vm$sites$group)) vm$sites$group else rep(NA_character_, nrow(vm$sites))
  dfs <- lapply(seq_along(vm$cells), function(i) {
    cell <- vm$cells[[i]]
    data.frame(
      cell        = i,
      label       = vm$sites$label[i],
      group       = grp[i],
      x           = cell[, 1],
      y           = cell[, 2],
      target_area = vm$sites$target_area[i],
      actual_area = vm$sites$actual_area[i],
      data_weight = vm$sites$data_weight[i]
    )
  })
  do.call(rbind, dfs)
}

#' Centroids of every cell in a voronoi_map
#'
#' A data frame with one row per cell: `cell`, `label`, `group`, `cx`, `cy`,
#' `data_weight`, `actual_area`.  Useful for placing labels, values, flags or
#' images (see [vm_add_labels()], [vm_add_images()], [vm_add_flags()]).
#'
#' @param vm A `voronoi_map` object.
#' @return A data frame.
#' @export
vm_centroids <- function(vm) {
  grp <- if (!is.null(vm$sites$group)) vm$sites$group else rep(NA_character_, nrow(vm$sites))
  ctr <- t(vapply(vm$cells, polygon_centroid, numeric(2)))
  data.frame(
    cell        = seq_along(vm$cells),
    label       = vm$sites$label,
    group       = grp,
    cx          = ctr[, 1],
    cy          = ctr[, 2],
    data_weight = vm$sites$data_weight,
    actual_area = vm$sites$actual_area,
    stringsAsFactors = FALSE
  )
}

#' Autoplot method for voronoi_map objects
#'
#' Produces a ggplot2 visualisation with `geom_polygon()`.  For hierarchical
#' maps the default fill is the group and heavier borders separate the groups.
#'
#' @param object A `voronoi_map` object.
#' @param fill_by Cell aesthetic to map fill to: one of `"label"`, `"group"`,
#'   `"data_weight"`, or `"none"`.  Defaults to `"group"` for hierarchical
#'   maps and `"label"` otherwise.
#' @param border_col Border colour.  Default `"white"`.
#' @param border_size Border line width.  Default `0.8`.
#' @param group_border_col Colour of the heavier group boundaries drawn for
#'   hierarchical maps.  `NA` disables them.  Default `"white"`.
#' @param group_border_size Line width of group boundaries.  Default `1.8`.
#' @param show_labels Logical; add centroid labels?  Default `TRUE`.
#' @param label_col Label colour.  Default `"white"`.
#' @param label_size Label size.  Default `3`.
#' @param palette Character vector of colours, or a named palette from
#'   [grDevices::hcl.colors()].  Default `"Dark 3"`.
#' @param legend Logical; show the fill legend?  Default `FALSE`.
#' @param ... Ignored.
#'
#' @return A ggplot object.
#' @importFrom ggplot2 autoplot
#' @export
autoplot.voronoi_map <- function(
  object,
  fill_by           = NULL,
  border_col        = "white",
  border_size       = 0.8,
  group_border_col  = "white",
  group_border_size = 1.8,
  show_labels       = TRUE,
  label_col         = "white",
  label_size        = 3,
  palette           = "Dark 3",
  legend            = FALSE,
  ...
) {
  hier <- isTRUE(object$hierarchical)
  if (is.null(fill_by)) fill_by <- if (hier) "group" else "label"
  fill_by <- match.arg(fill_by, c("group", "label", "data_weight", "none"))

  df <- vm_as_df(object)
  centroids <- vm_centroids(object)

  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$x, y = .data$y, group = .data$cell))

  if (fill_by == "none") {
    p <- p + ggplot2::geom_polygon(fill = "grey80", colour = border_col,
                                   linewidth = border_size)
  } else if (fill_by == "data_weight") {
    p <- p + ggplot2::geom_polygon(ggplot2::aes(fill = .data$data_weight),
                                   colour = border_col, linewidth = border_size) +
      ggplot2::scale_fill_gradientn(colours = .vm_palette(64, palette))
  } else {
    key  <- if (fill_by == "group") "group" else "label"
    levs <- unique(df[[key]])
    cols <- stats::setNames(.vm_palette(length(levs), palette), levs)
    p <- p +
      ggplot2::geom_polygon(ggplot2::aes(fill = .data[[key]]),
                            colour = border_col, linewidth = border_size) +
      ggplot2::scale_fill_manual(values = cols)
  }

  # Heavier group outlines for hierarchical maps
  if (hier && !is.na(group_border_col)) {
    gdf <- do.call(rbind, lapply(seq_along(object$groups$cells), function(i) {
      cell <- object$groups$cells[[i]]
      data.frame(gid = i, x = cell[, 1], y = cell[, 2])
    }))
    p <- p + ggplot2::geom_polygon(
      data = gdf,
      mapping = ggplot2::aes(x = .data$x, y = .data$y, group = .data$gid),
      inherit.aes = FALSE, fill = NA,
      colour = group_border_col, linewidth = group_border_size
    )
  }

  p <- p +
    ggplot2::coord_equal() +
    ggplot2::theme_void() +
    ggplot2::labs(fill = NULL)
  if (!legend) p <- p + ggplot2::theme(legend.position = "none")

  if (show_labels) {
    p <- p + ggplot2::geom_text(
      data    = centroids,
      mapping = ggplot2::aes(x = .data$cx, y = .data$cy, label = .data$label),
      inherit.aes = FALSE,
      colour  = label_col,
      size    = label_size,
      fontface = "bold"
    )
  }
  attr(p, "vm") <- object
  p
}

#' Resolve a palette specification to a vector of `n` colours
#' @noRd
.vm_palette <- function(n, palette) {
  if (length(palette) > 1L) {
    grDevices::colorRampPalette(palette)(n)
  } else {
    grDevices::hcl.colors(n, palette = palette)
  }
}

#' @importFrom ggplot2 ggplot
#' @export
ggplot2::autoplot

# --- Convenience: ggvmap() shortcut -----------------------------------------

#' Quick ggplot2 Voronoi map
#'
#' Compute *and* plot a Voronoi map in a single call.
#'
#' @inheritParams voronoi_map
#' @inheritParams autoplot.voronoi_map
#' @return A ggplot object (invisibly also stores the `voronoi_map` object
#'   as attribute `"vm"`).
#'
#' @examples
#' ggvmap(
#'   weights = c(3, 2, 5, 1, 4),
#'   labels  = c("A", "B", "C", "D", "E"),
#'   seed    = 42
#' )
#'
#' @export
ggvmap <- function(
  weights,
  labels            = NULL,
  group             = NULL,
  clip              = clip_square(),
  convergence_ratio = 0.01,
  max_iter          = 50,
  min_weight_ratio  = 0.01,
  seed              = NULL,
  fill_by           = NULL,
  palette           = "Dark 3",
  border_col        = "white",
  border_size       = 0.8,
  show_labels       = TRUE,
  label_col         = "white",
  label_size        = 3,
  legend            = FALSE
) {
  vm <- voronoi_map(
    weights           = weights,
    labels            = labels,
    group             = group,
    clip              = clip,
    convergence_ratio = convergence_ratio,
    max_iter          = max_iter,
    min_weight_ratio  = min_weight_ratio,
    seed              = seed
  )
  p <- autoplot(vm,
    fill_by     = fill_by,
    palette     = palette,
    border_col  = border_col,
    border_size = border_size,
    show_labels = show_labels,
    label_col   = label_col,
    label_size  = label_size,
    legend      = legend
  )
  attr(p, "vm") <- vm
  p
}
