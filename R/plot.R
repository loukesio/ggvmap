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
    fill <- okabe_ito(n)
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

# --- Per-cell label helpers -------------------------------------------------

#' Area of every cell as a fraction of the total map area
#' @noRd
.area_fractions <- function(vm) {
  area <- abs(vapply(vm$cells, polygon_area, numeric(1)))
  area / sum(area)
}

#' Resolve `fontface` to one face per cell
#'
#' A named vector styles only the named cells (rest `"plain"`); a single
#' value (or length-`n` vector) applies as-is, following `.align_to_cells()`.
#' @noRd
.resolve_fontface <- function(vm, fontface) {
  labs <- vm$sites$label
  if (!is.null(names(fontface))) {
    out <- stats::setNames(rep("plain", length(labs)), labs)
    keep <- intersect(names(fontface), labs)
    out[keep] <- fontface[keep]
    return(unname(out))
  }
  rep_len(fontface, length(labs))
}

#' Wrap labels at a character width (NULL = no wrapping)
#' @noRd
.wrap_labels <- function(x, wrap) {
  if (is.null(wrap) || !is.finite(wrap)) return(x)
  vapply(x, function(s) paste(strwrap(s, width = wrap), collapse = "\n"),
         character(1), USE.NAMES = FALSE)
}

#' Resolve a label colour spec to one colour per cell
#'
#' Accepts a scalar, a length-`n` vector (cell order), or a vector named by
#' cell label; cells not named fall back to `default`.
#' @noRd
.resolve_label_col <- function(vm, col, default) {
  out <- .align_to_cells(vm, col, "label_col")
  out[is.na(out)] <- default
  out
}

#' Per-cell text sizes, optionally shrunk for small cells
#'
#' A vector named by cell label sizes only the named cells (the rest keep
#' `default`), like the other cell-level arguments.  With `autoscale = TRUE`
#' each cell's size is `size * pmin(1, sqrt(cell_area / median_area))`,
#' floored at 60% of `size` so text in tiny cells stays legible.
#' @noRd
.label_sizes <- function(vm, size, autoscale, default = 3) {
  n <- length(vm$cells)
  if (!is.null(names(size))) {
    labs <- vm$sites$label
    out <- stats::setNames(rep(default, n), labs)
    keep <- intersect(names(size), labs)
    out[keep] <- size[keep]
    size <- unname(out)
  }
  if (!isTRUE(autoscale)) return(rep_len(size, n))
  area <- abs(vapply(vm$cells, polygon_area, numeric(1)))
  pmax(0.6 * size, size * pmin(1, sqrt(area / stats::median(area))))
}

#' Plot a Voronoi map with ggplot2
#'
#' The main plotting function of \pkg{ggvmap}.  Produces a ggplot2
#' visualisation with `geom_polygon()`; for hierarchical maps the default fill
#' is the group and heavier borders separate the groups.
#'
#' `x` may be an existing [voronoi_map()] object, or a numeric vector of
#' weights -- in which case the map is computed first (see the layout
#' arguments below), so `ggvmap(weights, labels = ...)` computes *and* plots
#' in one call.
#'
#' @param x A `voronoi_map` object, or a numeric vector of weights.
#' @param fill_by Cell aesthetic to map fill to: one of `"label"`, `"group"`,
#'   `"data_weight"`, or `"none"`.  Defaults to `"group"` for hierarchical
#'   maps and `"label"` otherwise.
#' @param border_col Border colour.  Default `"white"`.
#' @param border_size Border line width.  Default `0.8`.
#' @param group_border_col Colour of the heavier group boundaries drawn for
#'   hierarchical maps.  `NA` disables them.  Default `"white"`.  May also be
#'   a vector named by group: only the named groups get a border, each in its
#'   own colour (e.g. `c("LATAM" = "#333333")` outlines one region only).
#' @param group_border_size Line width of group boundaries.  Default `1.8`.
#' @param show_labels Logical; add centroid labels?  Default `TRUE`.
#' @param label_cells Optional character vector of cell labels to annotate;
#'   others get no name label.  Default `NULL` (all cells).
#' @param label_col Label colour: a single colour (default `"white"`), a
#'   length-`n` vector in cell order, or a vector named by cell label (cells
#'   not named keep the default) -- useful for light text on dark cells.
#' @param label_size Label size: a single value, a length-`n` vector in cell
#'   order, or a vector named by cell label (unnamed cells keep the default
#'   `3`) -- e.g. `c(Brazil = 5)` to enlarge one label.  Default `3`.
#' @param fontface Font face for the name labels: a single value (e.g.
#'   `"bold"`, the default) applied to all labels, or a vector named by cell
#'   label (e.g. `c(Brazil = "bold", Russia = "bold.italic")`) styling only
#'   those cells while the rest stay `"plain"`.
#' @param min_area Cells whose area fraction of the map is below this
#'   threshold get no name label.  Default `0` (label every cell).
#' @param autoscale Logical; shrink label text in small cells?  Each cell's
#'   text size becomes `label_size * pmin(1, sqrt(cell_area / median_area))`,
#'   floored at 60% of `label_size`.  Default `FALSE`.
#' @param family Font family for the name labels, passed to the text layer.
#'   `NULL` (default) uses the ggplot2 default.
#' @param wrap Wrap name labels longer than this many characters onto
#'   multiple lines (word-aware, via [strwrap()]) -- e.g. `wrap = 10` turns
#'   "Papua New Guinea" into two lines.  Default `NULL` (no wrapping).
#' @param palette Character vector of colours, `"Okabe-Ito"` (the default,
#'   colourblind-safe; see [okabe_ito()]), a built-in named palette such as
#'   `"alger"`, or a named palette from [grDevices::hcl.colors()].
#' @param legend Logical; show the fill legend?  Default `FALSE`.
#' @param interactive Logical; make the cells interactive (hover highlight and
#'   tooltips) using \pkg{ggiraph}?  Render the result with [vm_girafe()].
#'   Default `FALSE`.
#' @param tooltip Optional per-cell tooltip text (length-`n`, named by label, or
#'   length 1) used when `interactive = TRUE`.  Defaults to the label and value.
#' @param labels,group,clip,convergence_ratio,max_iter,min_weight_ratio,seed
#'   Layout arguments passed to [voronoi_map()] when `x` is a vector of
#'   weights; ignored when `x` is already a `voronoi_map`.
#'
#' @return A ggplot object (pass to [vm_girafe()] to render an interactive
#'   widget when `interactive = TRUE`).  The underlying `voronoi_map` is
#'   attached as attribute `"vm"` so annotation helpers can be chained.
#'
#' @examples
#' # Compute and plot in one call
#' ggvmap(c(3, 2, 5, 1, 4), labels = c("A", "B", "C", "D", "E"), seed = 42)
#'
#' # Or plot an existing map
#' vm <- voronoi_map(c(5, 3, 8, 2, 6), labels = LETTERS[1:5], seed = 1)
#' ggvmap(vm, palette = "alger")
#'
#' @export
ggvmap <- function(
  x,
  fill_by           = NULL,
  border_col        = "white",
  border_size       = 0.8,
  group_border_col  = "white",
  group_border_size = 1.8,
  show_labels       = TRUE,
  label_cells       = NULL,
  label_col         = "white",
  label_size        = 3,
  fontface          = "bold",
  min_area          = 0,
  autoscale         = FALSE,
  family            = NULL,
  wrap              = NULL,
  palette           = "Okabe-Ito",
  legend            = FALSE,
  interactive       = FALSE,
  tooltip           = NULL,
  labels            = NULL,
  group             = NULL,
  clip              = clip_square(),
  convergence_ratio = 0.01,
  max_iter          = 50,
  min_weight_ratio  = 0.01,
  seed              = NULL
) {
  object <- if (inherits(x, "voronoi_map")) {
    x
  } else {
    voronoi_map(
      weights           = x,
      labels            = labels,
      group             = group,
      clip              = clip,
      convergence_ratio = convergence_ratio,
      max_iter          = max_iter,
      min_weight_ratio  = min_weight_ratio,
      seed              = seed
    )
  }
  hier <- isTRUE(object$hierarchical)
  if (is.null(fill_by)) fill_by <- if (hier) "group" else "label"
  fill_by <- match.arg(fill_by, c("group", "label", "data_weight", "none"))

  if (interactive && !requireNamespace("ggiraph", quietly = TRUE)) {
    stop("interactive = TRUE requires the 'ggiraph' package. ",
         "Install it with install.packages('ggiraph').", call. = FALSE)
  }

  df <- vm_as_df(object)
  centroids <- vm_centroids(object)

  # geom_polygon() or its interactive counterpart, injecting tooltip/data_id.
  poly_layer <- function(mapping, ...) {
    if (interactive) {
      mapping <- utils::modifyList(
        mapping,
        ggplot2::aes(tooltip = .data$tooltip, data_id = .data$data_id))
      ggiraph::geom_polygon_interactive(mapping = mapping, ...)
    } else {
      ggplot2::geom_polygon(mapping = mapping, ...)
    }
  }
  if (interactive) {
    tip <- .align_to_cells(object, tooltip, "tooltip")
    if (is.null(tip)) {
      val <- format(centroids$data_weight, big.mark = ",", trim = TRUE)
      tip <- if (hier) sprintf("%s (%s): %s", centroids$label, centroids$group, val)
             else sprintf("%s: %s", centroids$label, val)
    }
    df$tooltip <- tip[df$cell]
    df$data_id <- as.character(df$cell)
  }

  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$x, y = .data$y, group = .data$cell))

  if (fill_by == "none") {
    p <- p + poly_layer(ggplot2::aes(), fill = "grey80", colour = border_col,
                        linewidth = border_size)
  } else if (fill_by == "data_weight") {
    p <- p + poly_layer(ggplot2::aes(fill = .data$data_weight),
                        colour = border_col, linewidth = border_size) +
      ggplot2::scale_fill_gradientn(colours = .vm_palette(64, palette, continuous = TRUE))
  } else {
    key  <- if (fill_by == "group") "group" else "label"
    levs <- unique(df[[key]])
    cols <- stats::setNames(.vm_palette(length(levs), palette), levs)
    p <- p +
      poly_layer(ggplot2::aes(fill = .data[[key]]),
                 colour = border_col, linewidth = border_size) +
      ggplot2::scale_fill_manual(values = cols)
  }

  # Heavier group outlines for hierarchical maps
  if (hier && !all(is.na(group_border_col))) {
    gnames <- object$groups$sites$label
    gdf <- do.call(rbind, lapply(seq_along(object$groups$cells), function(i) {
      cell <- object$groups$cells[[i]]
      data.frame(gid = i, gname = gnames[i], x = cell[, 1], y = cell[, 2])
    }))
    # group_border_col can be: a single colour (all group borders), or a
    # vector named by group (colour only those groups / different colours).
    if (length(group_border_col) > 1L || !is.null(names(group_border_col))) {
      gcols <- if (is.null(names(group_border_col))) {
        stats::setNames(rep_len(group_border_col, length(gnames)), gnames)
      } else {
        out <- stats::setNames(rep(NA_character_, length(gnames)), gnames)
        keep <- intersect(names(group_border_col), gnames)
        out[keep] <- group_border_col[keep]
        out
      }
      gdf$gcol <- gcols[gdf$gname]
      gdf <- gdf[!is.na(gdf$gcol), , drop = FALSE]
      if (nrow(gdf)) {
        p <- p + ggplot2::geom_polygon(
          data = gdf,
          mapping = ggplot2::aes(x = .data$x, y = .data$y, group = .data$gid,
                                 colour = .data$gcol),
          inherit.aes = FALSE, fill = NA,
          linewidth = group_border_size, show.legend = FALSE
        ) + ggplot2::scale_colour_identity()
      }
    } else {
      p <- p + ggplot2::geom_polygon(
        data = gdf,
        mapping = ggplot2::aes(x = .data$x, y = .data$y, group = .data$gid),
        inherit.aes = FALSE, fill = NA,
        colour = group_border_col, linewidth = group_border_size
      )
    }
  }

  p <- p +
    ggplot2::coord_equal() +
    ggplot2::theme_void() +
    ggplot2::labs(fill = NULL)
  if (!legend) p <- p + ggplot2::theme(legend.position = "none")

  if (show_labels) {
    lab_df <- centroids
    lab_df$size      <- .label_sizes(object, label_size, autoscale)
    lab_df$fontface  <- .resolve_fontface(object, fontface)
    lab_df$area_frac <- .area_fractions(object)
    lab_df$col       <- .resolve_label_col(object, label_col, "white")
    if (!is.null(label_cells)) lab_df <- lab_df[lab_df$label %in% label_cells, , drop = FALSE]
    if (min_area > 0) lab_df <- lab_df[lab_df$area_frac >= min_area, , drop = FALSE]
    lab_df$label <- .wrap_labels(lab_df$label, wrap)
    if (nrow(lab_df)) {
      p <- p + do.call(ggplot2::geom_text, .add_family(
        list(
          data    = lab_df,
          mapping = ggplot2::aes(x = .data$cx, y = .data$cy, label = .data$label),
          inherit.aes = FALSE,
          colour  = lab_df$col,
          size    = lab_df$size,
          fontface = lab_df$fontface
        ), family))
    }
  }
  attr(p, "vm") <- object
  p
}

#' Autoplot method for voronoi_map objects
#'
#' A thin wrapper around [ggvmap()], kept so the standard ggplot2
#' `autoplot()` generic keeps working: `autoplot(vm, ...)` is identical to
#' `ggvmap(vm, ...)`.
#'
#' @param object A `voronoi_map` object.
#' @param ... Passed to [ggvmap()].
#' @return A ggplot object.
#' @importFrom ggplot2 autoplot
#' @export
autoplot.voronoi_map <- function(object, ...) {
  ggvmap(object, ...)
}

# --- Interactive rendering (ggiraph) ----------------------------------------

#' Render an interactive Voronoi map
#'
#' Wraps a plot built with `interactive = TRUE` (see [autoplot.voronoi_map()] /
#' [ggvmap()]) into a \pkg{ggiraph} `girafe` htmlwidget, so cells highlight on
#' hover and show tooltips. Works in R Markdown / Quarto, Shiny and the RStudio
#' viewer.
#'
#' @param p A ggplot built with `interactive = TRUE`.
#' @param width_svg,height_svg Size of the SVG canvas in inches.  Default `7`.
#' @param hover_css CSS applied to the hovered cell.  The default fades the
#'   cell slightly and thickens its white outline -- no dark border.  Pass
#'   your own CSS to change the effect (e.g.
#'   `"stroke:#222222;stroke-width:1.4px;"` for a dark outline).
#' @param opts Optional list of extra \pkg{ggiraph} `opts_*()` objects to append.
#' @param ... Passed to [ggiraph::girafe()].
#' @return A `girafe` htmlwidget.
#' @examples
#' \dontrun{
#' vm <- voronoi_map(c(5, 3, 8, 2, 6), labels = LETTERS[1:5], seed = 1)
#' ggvmap(vm, interactive = TRUE) |> vm_girafe()
#' }
#' @export
vm_girafe <- function(p, width_svg = 7, height_svg = 7,
                      hover_css = "fill-opacity:0.75;stroke:#ffffff;stroke-width:2.2px;",
                      opts = NULL, ...) {
  if (!requireNamespace("ggiraph", quietly = TRUE)) {
    stop("vm_girafe() requires the 'ggiraph' package. ",
         "Install it with install.packages('ggiraph').", call. = FALSE)
  }
  options <- c(
    list(
      ggiraph::opts_hover(css = hover_css),
      ggiraph::opts_tooltip(
        css = paste0("background:rgba(255,255,255,0.95);color:#222;",
                     "padding:5px 8px;border-radius:4px;",
                     "font-family:sans-serif;font-size:12px;",
                     "box-shadow:0 1px 4px rgba(0,0,0,0.25);")),
      ggiraph::opts_zoom(max = 4)
    ),
    opts
  )
  ggiraph::girafe(ggobj = p, width_svg = width_svg, height_svg = height_svg,
                  options = options, ...)
}

#' @importFrom ggplot2 ggplot
#' @export
ggplot2::autoplot
