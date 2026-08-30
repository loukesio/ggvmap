# ---- Annotation layers: outer ring, flags, images, value labels ----
#
# All `vm_add_*()` helpers take a ggplot built by ggvmap() (or autoplot())
# and return a new ggplot with extra layers.  They read the underlying
# `voronoi_map` object from the plot's `"vm"` attribute (attached by
# ggvmap()), or from an explicit `vm =` argument, and re-attach it so the
# helpers can be chained with the pipe:
#
#   vm |> ggvmap() |> vm_add_ring() |> vm_add_flags(country = name)

#' Retrieve the voronoi_map backing a plot
#' @noRd
.vm_of <- function(p, vm) {
  if (!is.null(vm)) return(vm)
  vm <- attr(p, "vm", exact = TRUE)
  if (is.null(vm)) {
    stop("No voronoi_map found. Pass `vm =` explicitly, or build the plot ",
         "with autoplot()/ggvmap() so it is attached.", call. = FALSE)
  }
  vm
}

#' Add layers to a plot while preserving the attached voronoi_map
#' @noRd
.vm_plus <- function(p, layers, vm) {
  out <- p + layers
  attr(out, "vm") <- vm
  out
}

# --- Outer annotation ring --------------------------------------------------

#' Add a colored outer annotation ring
#'
#' Wraps a circular Voronoi map in a decorative ring divided into one arc
#' segment per group (as in a Voronoi-treemap infographic).  Each segment
#' spans the angular extent actually occupied by its group's cells, so the
#' ring lines up with a hierarchical layout produced by
#' `voronoi_map(..., group =)`.
#'
#' @param p A ggplot produced by [autoplot.voronoi_map()] or [ggvmap()].
#' @param vm Optional `voronoi_map`; taken from `p` when omitted.
#' @param groups Optional character vector selecting and ordering which groups
#'   to draw.  Defaults to all groups.
#' @param colors Colours for the ring segments (band fills or arc lines):
#'   `NULL` (default) uses the `palette`, so each group matches its cells; a
#'   single colour (e.g. `"#333333"`) colours every segment the same; a named
#'   vector keyed by group (e.g. `c(LATAM = "#333333")` with the other groups
#'   named too) sets each group individually; an unnamed vector is
#'   interpolated across the groups.  With `style = "arc"`, the labels follow
#'   the arc colours unless `label_col` is set.
#' @param labels Logical, or a named character vector of display labels keyed
#'   by group.  `TRUE` (default) uses the group names; `FALSE` draws no text.
#'   In the `"arc"` style, an empty string omits one group's label and leaves
#'   its arc unbroken (e.g. `labels = c("Middle East" = "")`) -- useful when a
#'   group's segment is too short to carry its label, which otherwise stays
#'   on the ring with its gap cut into the neighbouring arcs (a message
#'   points this out when it happens).
#' @param curved Draw labels curved along the arc using \pkg{geomtextpath}?
#'   `NULL` (default) curves them when that package is installed and otherwise
#'   uses straight tangential text; `TRUE`/`FALSE` force the choice.
#' @param palette Palette used when `colors` is `NULL`: a colour vector, a
#'   built-in palette name (see [vm_palettes()]), or an
#'   [grDevices::hcl.colors()] name.  Default `"Okabe-Ito"`.
#' @param style Ring style: `"band"` (default) draws the filled arc segments;
#'   `"arc"` draws a thin line per group with the group label sitting in a gap
#'   broken into the arc at the segment midpoint (the classic infographic
#'   look, e.g. "NORTH AMERICA 13%" with a middle-dot separator).
#' @param width Band thickness as a fraction of the map radius (`style =
#'   "band"` only).  Default `0.10`.
#' @param gap Radial gap between the map and the ring, as a fraction of the
#'   radius.  Default `0.02`.
#' @param pad Angular padding trimmed from each segment end, in degrees.
#'   Default `1`.
#' @param label_col Ring label colour.  `NULL` (default) means `"white"` for
#'   `style = "band"` and each arc's own colour for `style = "arc"`.
#' @param label_size Ring label size.  Default `3.2`.
#' @param label_fontface Ring label font face.  Default `"bold"`.
#' @param border_col Segment border colour (`style = "band"`).  Default `"white"`.
#' @param border_size Segment border width (`style = "band"`).  Default `0.4`.
#' @param family Font family for the ring labels.  `NULL` (default) uses the
#'   ggplot2 default.
#' @param linewidth Arc line width (`style = "arc"`).  Default `0.5`.
#' @param linetype Arc line type (`style = "arc"`), e.g. `"dashed"`.
#'   Default `"solid"`.
#' @param offset Distance of the arc and its label from the map edge, as a
#'   fraction of the radius (`style = "arc"`; `width` is ignored).
#'   Default `0.06`.
#' @param values Append each group's share to its label (`style = "arc"`),
#'   e.g. "LATAM 32%" with a middle-dot separator?  Computed from the group
#'   weights.  Default `FALSE`.
#' @param values_sep Separator between the group name and its share.
#'   Default is a middle dot (`" \u00b7 "`).  On Windows `pdf()` devices the
#'   dot can hit an encoding conversion failure -- pass an ASCII separator
#'   such as `" - "` there.
#'
#' @return The ggplot with ring layers added.
#' @examples
#' vm <- voronoi_map(c(5, 3, 8, 4, 6, 2),
#'                   group = c("A", "A", "B", "B", "C", "C"),
#'                   clip = clip_circle(), seed = 1)
#' ggvmap(vm, palette = "alger") |> vm_add_ring(palette = "alger")
#' ggvmap(vm, palette = "alger") |>
#'   vm_add_ring(style = "arc", palette = "alger", values = TRUE,
#'               values_sep = " - ")   # ASCII sep keeps pdf() happy everywhere
#' @export
vm_add_ring <- function(
  p,
  vm          = NULL,
  groups      = NULL,
  colors      = NULL,
  labels      = TRUE,
  curved      = NULL,
  palette     = "Okabe-Ito",
  style       = c("band", "arc"),
  width       = 0.10,
  gap         = 0.02,
  pad         = 1,
  label_col   = NULL,
  label_size  = 3.2,
  label_fontface = "bold",
  border_col  = "white",
  border_size = 0.4,
  family      = NULL,
  linewidth   = 0.5,
  linetype    = "solid",
  offset      = 0.06,
  values      = FALSE,
  values_sep  = " \u00b7 "
) {
  style <- match.arg(style)
  vm   <- .vm_of(p, vm)
  meta <- .clip_meta(vm$clip)
  if (!meta$circular) {
    warning("vm_add_ring() is designed for circular clips; ",
            "results on other shapes may look off.", call. = FALSE)
  }
  seg <- .ring_segments(vm, groups)
  if (nrow(seg) == 0L) return(p)

  cx <- meta$center[1]; cy <- meta$center[2]; r <- meta$radius
  ri <- r * (1 + gap)
  ro <- r * (1 + gap + width)
  pad_rad <- pad * pi / 180

  if (style == "arc") {
    return(.vm_ring_arc(p, vm, seg, meta, colors, labels, curved, palette,
                        gap, pad_rad, label_col, label_size, label_fontface,
                        family, linewidth, linetype, offset, values,
                        values_sep))
  }
  if (is.null(label_col)) label_col <- "white"

  # Match autoplot's group -> colour assignment (level order = cell order) so
  # the ring segments share the colours of the cells they wrap.
  glevels <- if (isTRUE(vm$hierarchical)) vm$groups$sites$label else unique(vm$sites$label)
  cols <- .resolve_group_colors(colors, glevels, palette)

  # One constant-fill polygon per segment -- avoids touching the plot's own
  # fill scale, so the ring colours are independent of the cell colours.
  layers <- lapply(seq_len(nrow(seg)), function(k) {
    a0 <- seg$start[k] + pad_rad
    a1 <- seg$end[k]   - pad_rad
    if (a1 <= a0) { a0 <- seg$start[k]; a1 <- seg$end[k] }
    npt <- max(2L, ceiling((a1 - a0) / (2 * pi) * 256))
    ang <- seq(a0, a1, length.out = npt)
    inner <- cbind(cx + ri * cos(ang),      cy + ri * sin(ang))
    outer <- cbind(cx + ro * cos(rev(ang)), cy + ro * sin(rev(ang)))
    poly  <- data.frame(x = c(inner[, 1], outer[, 1]),
                        y = c(inner[, 2], outer[, 2]))
    ggplot2::geom_polygon(
      data = poly,
      mapping = ggplot2::aes(x = .data$x, y = .data$y),
      inherit.aes = FALSE,
      fill = unname(cols[seg$group[k]]),
      colour = border_col, linewidth = border_size
    )
  })

  if (!isFALSE(labels)) {
    lab_txt <- if (is.character(labels)) labels[seg$group] else seg$group
    lab_txt[is.na(lab_txt)] <- seg$group[is.na(lab_txt)]
    rm <- (ri + ro) / 2

    has_gtp <- requireNamespace("geomtextpath", quietly = TRUE)
    use_curved <- if (is.null(curved)) has_gtp else isTRUE(curved)
    if (use_curved && !has_gtp) {
      warning("curved ring labels need the 'geomtextpath' package; ",
              "falling back to straight labels. install.packages('geomtextpath')",
              call. = FALSE)
      use_curved <- FALSE
    }

    if (use_curved) {
      # A poly-line path along the ring centre-line per segment; geom_textpath
      # bends the label to follow it (upright = never upside down).
      path_df <- do.call(rbind, lapply(seq_len(nrow(seg)), function(k) {
        a0 <- seg$start[k] + pad_rad
        a1 <- seg$end[k]   - pad_rad
        if (a1 <= a0) { a0 <- seg$start[k]; a1 <- seg$end[k] }
        ang <- seq(a0, a1, length.out = 64)
        data.frame(seg = k, x = cx + rm * cos(ang), y = cy + rm * sin(ang),
                   label = lab_txt[k])
      }))
      layers <- c(layers, list(do.call(geomtextpath::geom_textpath, .add_family(
        list(
          data = path_df,
          mapping = ggplot2::aes(x = .data$x, y = .data$y,
                                 label = .data$label, group = .data$seg),
          inherit.aes = FALSE, colour = label_col, size = label_size,
          fontface = label_fontface, text_only = TRUE, upright = TRUE
        ), family))))
    } else {
      mid <- ((seg$start + seg$end) / 2) %% (2 * pi)  # position angle [0, 2*pi)
      # Tangent to the ring; flip any that would read upside down.
      ang_txt <- (mid * 180 / pi - 90) %% 360
      flip <- ang_txt > 90 & ang_txt < 270
      ang_txt[flip] <- (ang_txt[flip] + 180) %% 360
      lab_df <- data.frame(
        x = cx + rm * cos(mid), y = cy + rm * sin(mid),
        label = lab_txt, angle = ang_txt
      )
      layers <- c(layers, list(do.call(ggplot2::geom_text, .add_family(
        list(
          data = lab_df,
          mapping = ggplot2::aes(x = .data$x, y = .data$y,
                                 label = .data$label, angle = .data$angle),
          inherit.aes = FALSE, colour = label_col, size = label_size,
          fontface = label_fontface
        ), family))))
    }
  }

  # Expand limits so the ring is not clipped
  lim <- ro * 1.08
  layers <- c(layers, list(
    ggplot2::expand_limits(x = c(cx - lim, cx + lim), y = c(cy - lim, cy + lim))
  ))

  .vm_plus(p, layers, vm)
}

#' Append `family` to a geom argument list only when it is set
#' @noRd
.add_family <- function(args, family) {
  if (!is.null(family)) args$family <- family
  args
}

#' The "arc" ring style: a thin line per group, broken at the segment
#' midpoint by a gap holding the group label
#' @noRd
.vm_ring_arc <- function(p, vm, seg, meta, colors, labels, curved, palette,
                         gap, pad_rad, label_col, label_size, label_fontface,
                         family, linewidth, linetype, offset, values,
                         values_sep = " \u00b7 ") {
  cx <- meta$center[1]; cy <- meta$center[2]; r <- meta$radius
  ra <- r * (1 + gap + offset)

  glevels <- if (isTRUE(vm$hierarchical)) vm$groups$sites$label else unique(vm$sites$label)
  cols <- .resolve_group_colors(colors, glevels, palette)

  # Group shares for `values = TRUE`
  gw <- if (isTRUE(vm$hierarchical)) {
    stats::setNames(vm$groups$sites$data_weight, vm$groups$sites$label)
  } else {
    stats::setNames(vm$sites$data_weight, vm$sites$label)
  }
  shares <- 100 * gw / sum(gw)

  # Display labels.  An empty string ("") for a group omits its ring label
  # entirely (the arc is drawn unbroken) -- the escape hatch for a group
  # whose segment is too short to carry text.
  lab_txt <- if (is.character(labels)) labels[seg$group] else seg$group
  lab_txt[is.na(lab_txt)] <- seg$group[is.na(lab_txt)]
  omit <- !nzchar(lab_txt)
  if (isTRUE(values)) {
    lab_txt <- paste0(lab_txt, values_sep, round(shares[seg$group]), "%")
  }
  draw_labels <- !isFALSE(labels)

  has_gtp <- requireNamespace("geomtextpath", quietly = TRUE)
  use_curved <- if (is.null(curved)) has_gtp else isTRUE(curved)
  if (use_curved && !has_gtp) {
    warning("curved ring labels need the 'geomtextpath' package; ",
            "falling back to straight labels. install.packages('geomtextpath')",
            call. = FALSE)
    use_curved <- FALSE
  }

  arc_path <- function(a0, a1, id) {
    if (a1 <= a0) return(NULL)
    npt <- max(2L, ceiling((a1 - a0) / (2 * pi) * 256))
    ang <- seq(a0, a1, length.out = npt)
    data.frame(id = id, x = cx + ra * cos(ang), y = cy + ra * sin(ang))
  }

  # Pass 1 -- padded segment extents and, per label, the angular interval it
  # occupies on the ring: ~0.027 rad per character at the default label size,
  # scaled with `label_size`.  Every label sits ON the ring; a label wider
  # than its own segment keeps its place and its gap is cut into the
  # neighbouring segments' arcs as well (pass 2), so all labels follow the
  # same pattern.
  seg_a0 <- seg_a1 <- numeric(nrow(seg))
  for (k in seq_len(nrow(seg))) {
    a0 <- seg$start[k] + pad_rad
    a1 <- seg$end[k]   - pad_rad
    if (a1 <= a0) { a0 <- seg$start[k]; a1 <- seg$end[k] }
    seg_a0[k] <- a0; seg_a1[k] <- a1
  }
  lab_rows <- list()
  cuts <- NULL
  if (draw_labels) {
    for (k in seq_len(nrow(seg))) {
      if (omit[k]) next
      mid <- (seg_a0[k] + seg_a1[k]) / 2
      gap_ang <- 0.027 * (label_size / 3.2) * nchar(lab_txt[k])
      lab_rows[[k]] <- data.frame(seg = k, group = seg$group[k], mid = mid,
                                  a0 = mid - gap_ang / 2,
                                  a1 = mid + gap_ang / 2,
                                  label = lab_txt[k],
                                  col = unname(cols[seg$group[k]]),
                                  stringsAsFactors = FALSE)
      cuts <- rbind(cuts, data.frame(c0 = mid - gap_ang / 2,
                                     c1 = mid + gap_ang / 2))
    }
    over <- !omit &
      0.027 * (label_size / 3.2) * nchar(lab_txt) > (seg_a1 - seg_a0)
    if (any(over)) {
      message("Ring label(s) wider than their arc segment: ",
              paste0('"', lab_txt[over], '"', collapse = ", "),
              ". They stay on the ring and their gap is cut into the ",
              "neighbouring arcs. To omit one instead, pass e.g. labels = c(\"",
              seg$group[which(over)[1]], "\" = \"\").")
    }
  }

  # Pass 2 -- draw each segment's arc minus every label interval that
  # intersects it (its own and, for overflowing labels, its neighbours').
  layers <- list()
  for (k in seq_len(nrow(seg))) {
    iv <- list(c(seg_a0[k], seg_a1[k]))
    if (!is.null(cuts)) {
      for (j in seq_len(nrow(cuts))) {
        for (shift in c(-2 * pi, 0, 2 * pi)) {  # labels wrap around 0/2pi
          c0 <- cuts$c0[j] + shift; c1 <- cuts$c1[j] + shift
          iv <- unlist(lapply(iv, function(p) {
            if (c1 <= p[1] || c0 >= p[2]) return(list(p))
            out <- list()
            if (c0 > p[1]) out <- c(out, list(c(p[1], c0)))
            if (c1 < p[2]) out <- c(out, list(c(c1, p[2])))
            out
          }), recursive = FALSE)
        }
      }
    }
    col_k  <- unname(cols[seg$group[k]])
    pieces <- do.call(rbind, lapply(seq_along(iv), function(i) {
      p <- iv[[i]]
      if (p[2] - p[1] < 0.02) return(NULL)   # drop sliver stubs
      arc_path(p[1], p[2], paste0(k, "-", i))
    }))
    if (!is.null(pieces) && nrow(pieces)) {
      layers <- c(layers, list(ggplot2::geom_path(
        data = pieces,
        mapping = ggplot2::aes(x = .data$x, y = .data$y, group = .data$id),
        inherit.aes = FALSE, colour = col_k,
        linewidth = linewidth, linetype = linetype
      )))
    }
  }

  lab <- do.call(rbind, lab_rows)
  if (draw_labels && !is.null(lab)) {
    lab$col_final <- if (is.null(label_col)) lab$col else rep_len(label_col, nrow(lab))
    if (use_curved) {
      path_df <- do.call(rbind, lapply(seq_len(nrow(lab)), function(k) {
        ang <- seq(lab$a0[k], lab$a1[k], length.out = 64)
        data.frame(seg = lab$seg[k],
                   x = cx + ra * cos(ang), y = cy + ra * sin(ang),
                   label = lab$label[k], col_final = lab$col_final[k])
      }))
      layers <- c(layers, list(do.call(geomtextpath::geom_textpath, .add_family(
        list(
          data = path_df,
          mapping = ggplot2::aes(x = .data$x, y = .data$y,
                                 label = .data$label, group = .data$seg,
                                 colour = .data$col_final),
          inherit.aes = FALSE, size = label_size,
          fontface = label_fontface, text_only = TRUE, upright = TRUE,
          show.legend = FALSE
        ), family)), ggplot2::scale_colour_identity()))
    } else {
      mid <- lab$mid %% (2 * pi)
      ang_txt <- (mid * 180 / pi - 90) %% 360
      flip <- ang_txt > 90 & ang_txt < 270
      ang_txt[flip] <- (ang_txt[flip] + 180) %% 360
      lab_df <- data.frame(
        x = cx + ra * cos(mid), y = cy + ra * sin(mid),
        label = lab$label, angle = ang_txt, col_final = lab$col_final
      )
      layers <- c(layers, list(do.call(ggplot2::geom_text, .add_family(
        list(
          data = lab_df,
          mapping = ggplot2::aes(x = .data$x, y = .data$y,
                                 label = .data$label, angle = .data$angle,
                                 colour = .data$col_final),
          inherit.aes = FALSE, size = label_size, fontface = label_fontface,
          show.legend = FALSE
        ), family)), ggplot2::scale_colour_identity()))
    }
  }

  lim <- ra * 1.10
  layers <- c(layers, list(
    ggplot2::expand_limits(x = c(cx - lim, cx + lim), y = c(cy - lim, cy + lim))
  ))
  .vm_plus(p, layers, vm)
}

#' Angular extent of every group, robust to wrap-around
#'
#' Returns a data frame with `group`, `start`, `end` (radians, `start < end`,
#' possibly exceeding 2*pi to encode a segment that crosses angle 0).
#' @noRd
.ring_segments <- function(vm, groups = NULL) {
  meta <- .clip_meta(vm$clip)
  cx <- meta$center[1]; cy <- meta$center[2]; r <- meta$radius

  if (isTRUE(vm$hierarchical)) {
    g_levels <- vm$groups$sites$label
    cell_of  <- function(g) vm$groups$cells[[match(g, g_levels)]]
  } else {
    # Treat each cell as its own "group"
    g_levels <- vm$sites$label
    cell_of  <- function(g) vm$cells[[match(g, g_levels)]]
  }
  if (is.null(groups)) groups <- g_levels
  groups <- groups[groups %in% g_levels]

  rows <- lapply(groups, function(g) {
    cell <- cell_of(g)
    d <- sqrt((cell[, 1] - cx)^2 + (cell[, 2] - cy)^2)
    on_edge <- d > 0.9 * r
    pts <- if (any(on_edge)) cell[on_edge, , drop = FALSE] else cell
    ang <- atan2(pts[, 2] - cy, pts[, 1] - cx) %% (2 * pi)
    span <- .angular_span(ang)
    data.frame(group = g, start = span[1], end = span[2])
  })
  out <- do.call(rbind, rows)
  out[order(out$start), , drop = FALSE]
}

#' Contiguous angular span of a set of angles (handles wrap-around)
#'
#' Finds the largest empty gap between sorted angles; the occupied arc is its
#' complement.  Returns `c(start, end)` with `start < end`.
#' @noRd
.angular_span <- function(ang) {
  ang <- sort(unique(ang %% (2 * pi)))
  if (length(ang) == 1L) return(c(ang - 1e-3, ang + 1e-3))
  gaps <- diff(c(ang, ang[1] + 2 * pi))
  k <- which.max(gaps)                 # largest empty gap is *after* ang[k]
  start <- ang[(k %% length(ang)) + 1L]
  end   <- ang[k]
  if (end <= start) end <- end + 2 * pi
  c(start, end)
}

#' Resolve group -> colour mapping
#' @noRd
.resolve_group_colors <- function(colors, groups, palette) {
  ug <- unique(groups)
  if (is.null(colors)) {
    stats::setNames(.vm_palette(length(ug), palette), ug)
  } else if (!is.null(names(colors))) {
    colors
  } else {
    stats::setNames(grDevices::colorRampPalette(colors)(length(ug)), ug)
  }
}

# --- Image / flag / value annotations ---------------------------------------

#' Align a per-cell input to cell order
#'
#' Accepts a vector of length `n` (cell order), a vector named by cell label,
#' or a scalar (recycled).  Returns a vector in cell order (or `NULL`).
#' @noRd
.align_to_cells <- function(vm, x, arg = "x") {
  if (is.null(x)) return(NULL)
  labs <- vm$sites$label
  n <- length(labs)
  if (!is.null(names(x))) return(unname(x[labs]))
  if (length(x) == 1L) return(rep(x, n))
  if (length(x) == n)  return(x)
  stop(sprintf("`%s` must have length %d (one per cell), be named by label, or be length 1.",
               arg, n), call. = FALSE)
}

#' Add images at cell centroids
#'
#' Places an image (logo, icon, flag, photo) at the centroid of each cell.
#' Requires the \pkg{ggimage} package.
#'
#' @param p A ggplot from [autoplot.voronoi_map()] / [ggvmap()].
#' @param vm Optional `voronoi_map`; taken from `p` when omitted.
#' @param image Image paths or URLs: length-`n` (cell order), named by cell
#'   label, or length 1.  `NA` entries are skipped.
#' @param size Image size as a fraction of the plot.  Default `0.05`.
#' @param by Size dimension passed to [ggimage::geom_image()]: `"width"`
#'   (default) or `"height"`.
#' @param asp Aspect-ratio correction passed to [ggimage::geom_image()].
#'   Default `1`.
#' @param alpha Image opacity.  Default `1`.
#' @param nudge_x,nudge_y Position offset in data units.  Default `0`.
#' @param cells Optional subset of cell labels to annotate.
#' @return The ggplot with an image layer added.
#' @export
vm_add_images <- function(p, vm = NULL, image, size = 0.05, by = "width",
                          asp = 1, alpha = 1, nudge_x = 0, nudge_y = 0,
                          cells = NULL) {
  if (!requireNamespace("ggimage", quietly = TRUE)) {
    stop("vm_add_images() requires the 'ggimage' package. ",
         "Install it with install.packages('ggimage').", call. = FALSE)
  }
  vm  <- .vm_of(p, vm)
  img <- .align_to_cells(vm, image, "image")
  ctr <- vm_centroids(vm)
  df  <- data.frame(x = ctr$cx + nudge_x, y = ctr$cy + nudge_y,
                    image = img, label = ctr$label, stringsAsFactors = FALSE)
  if (!is.null(cells)) df <- df[df$label %in% cells, , drop = FALSE]
  df <- df[!is.na(df$image), , drop = FALSE]
  if (nrow(df) == 0L) {
    warning("No images to draw (all NA / filtered out).", call. = FALSE)
    return(p)
  }
  layer <- ggimage::geom_image(
    data = df,
    mapping = ggplot2::aes(x = .data$x, y = .data$y, image = .data$image),
    inherit.aes = FALSE, size = size, by = by, asp = asp, alpha = alpha
  )
  .vm_plus(p, layer, vm)
}

#' Add country flags at cell centroids
#'
#' Resolves country names or ISO codes to national flags and places them at the
#' cell centroids.  Requires the \pkg{ggimage} package and (unless
#' `cache = TRUE`) internet access.
#'
#' Two rendering back-ends are available via `method`:
#' \describe{
#'   \item{`"geom_flag"`}{(default when available) uses
#'     [ggimage::geom_flag()], which draws flags directly from ISO codes -- no
#'     URLs to build. Simplest, and matches the flag set shipped with
#'     \pkg{ggimage}.}
#'   \item{`"url"`}{builds flagcdn.com URLs (see [flag_url()]) and draws them
#'     with [ggimage::geom_image()] via [vm_add_images()]. Supports `width` and
#'     offline `cache = TRUE` via [flag_cache()].}
#' }
#'
#' @param p A ggplot from [autoplot.voronoi_map()] / [ggvmap()].
#' @param vm Optional `voronoi_map`; taken from `p` when omitted.
#' @param country Country names (see [country_to_iso()]): length-`n`, named by
#'   label, or length 1.  Defaults to the cell labels.
#' @param iso ISO alpha-2 codes, as an alternative to `country`.
#' @param size Flag size as a fraction of the plot.  Default `0.045`.
#' @param method Rendering back-end: `"geom_flag"` (default) or `"url"`.
#' @param width Pixel width of the fetched flag PNG (`method = "url"` only).
#'   Default `160`.
#' @param cache Pre-download flags for offline rendering via [flag_cache()]
#'   (`method = "url"` only)?  Default `FALSE`.
#' @param nudge_x,nudge_y Offset from the centroid in data units.  Default `0`.
#' @param cells Optional subset of cell labels to annotate.
#' @param ... Passed to the underlying geom.
#' @return The ggplot with a flag layer added.
#' @examples
#' \dontrun{
#' vm <- voronoi_map(c(5, 3, 2), labels = c("China", "Norway", "Japan"),
#'                   seed = 1)
#' ggvmap(vm, palette = "alger") |> vm_add_flags()          # geom_flag
#' ggvmap(vm, palette = "alger") |> vm_add_flags(method = "url")  # flagcdn + geom_image
#' }
#' @export
vm_add_flags <- function(p, vm = NULL, country = NULL, iso = NULL,
                         size = 0.045, method = c("geom_flag", "url"),
                         width = 160, cache = FALSE,
                         nudge_x = 0, nudge_y = 0, cells = NULL, ...) {
  method <- match.arg(method)
  if (!requireNamespace("ggimage", quietly = TRUE)) {
    stop("vm_add_flags() requires the 'ggimage' package. ",
         "Install it with install.packages('ggimage').", call. = FALSE)
  }
  vm <- .vm_of(p, vm)
  if (is.null(iso)) {
    if (is.null(country)) country <- vm$sites$label
    country <- .align_to_cells(vm, country, "country")
    iso <- country_to_iso(country)
  } else {
    iso <- .align_to_cells(vm, iso, "iso")
  }
  if (all(is.na(iso))) {
    warning("No country names resolved to ISO codes; nothing drawn. ",
            "See country_to_iso().", call. = FALSE)
    return(p)
  }

  if (method == "url") {
    image <- if (isTRUE(cache)) flag_cache(iso, width = width) else flag_url(iso, width)
    return(vm_add_images(p, vm = vm, image = image, size = size,
                         nudge_x = nudge_x, nudge_y = nudge_y, cells = cells, ...))
  }

  # method == "geom_flag": ggimage draws flags straight from ISO codes
  ctr <- vm_centroids(vm)
  df  <- data.frame(x = ctr$cx + nudge_x, y = ctr$cy + nudge_y,
                    iso = iso, label = ctr$label, stringsAsFactors = FALSE)
  if (!is.null(cells)) df <- df[df$label %in% cells, , drop = FALSE]
  df <- df[!is.na(df$iso), , drop = FALSE]
  if (nrow(df) == 0L) {
    warning("No flags to draw (all NA / filtered out).", call. = FALSE)
    return(p)
  }
  layer <- ggimage::geom_flag(
    data = df,
    mapping = ggplot2::aes(x = .data$x, y = .data$y, image = .data$iso),
    inherit.aes = FALSE, size = size, ...
  )
  .vm_plus(p, layer, vm)
}

#' Add value labels at (or near) cell centroids
#'
#' Draws a secondary text label per cell -- typically a numeric value beneath
#' the category name added by [autoplot.voronoi_map()].
#'
#' @param p A ggplot from [autoplot.voronoi_map()] / [ggvmap()].
#' @param vm Optional `voronoi_map`; taken from `p` when omitted.
#' @param value Values to display: length-`n`, named by label, or length 1.
#'   Defaults to each cell's `data_weight`.
#' @param secondary Optional second value shown in parentheses (e.g. a count).
#' @param fmt A function applied to `value` (and `secondary`) for formatting,
#'   e.g. `scales::comma`.  Default: [format()] with `big.mark = ","`.
#' @param prefix,suffix Strings wrapped around the formatted value.
#' @param size Text size: a single value, a length-`n` vector in cell order,
#'   or a vector named by cell label (unnamed cells keep the default `2.8`).
#'   Default `2.8`.
#' @param col Text colour: a single colour (default `"grey20"`), a length-`n`
#'   vector in cell order, or a vector named by cell label (cells not named
#'   keep the default).
#' @param fontface Font face: a single value (default `"plain"`) applied to
#'   all labels, or a vector named by cell label (e.g.
#'   `c(Brazil = "bold")`) styling only those cells while the rest stay
#'   `"plain"`.
#' @param nudge_x,nudge_y Offset from the centroid.  `nudge_y` defaults to a
#'   small downward shift scaled to each cell so the value sits below the name
#'   without leaving small cells.
#' @param cells Optional subset of cell labels to annotate.
#' @param inside Logical; clamp the label anchor inside its cell when the
#'   nudge would push it out?  Default `TRUE`.
#' @param min_area Cells whose area fraction of the map is below this
#'   threshold get no value label.  Default `0` (label every cell).
#' @param autoscale Logical; shrink label text in small cells?  Each cell's
#'   text size becomes `size * pmin(1, sqrt(cell_area / median_area))`,
#'   floored at 60% of `size`.  Default `FALSE`.
#' @param family Font family for the value labels, passed to the text layer.
#'   `NULL` (default) uses the ggplot2 default.
#' @param wrap Wrap value labels longer than this many characters onto
#'   multiple lines (word-aware, via [strwrap()]).  Default `NULL`
#'   (no wrapping).
#' @return The ggplot with a value-label layer added.
#' @export
vm_add_labels <- function(p, vm = NULL, value = NULL, secondary = NULL,
                          fmt = NULL, prefix = "", suffix = "",
                          size = 2.8, col = "grey20", fontface = "plain",
                          nudge_x = 0, nudge_y = NULL, cells = NULL,
                          inside = TRUE, min_area = 0, autoscale = FALSE,
                          family = NULL, wrap = NULL) {
  vm  <- .vm_of(p, vm)
  if (is.null(value)) value <- vm$sites$data_weight
  value <- .align_to_cells(vm, value, "value")
  sec   <- .align_to_cells(vm, secondary, "secondary")
  if (is.null(fmt)) {
    fmt <- function(v) format(v, big.mark = ",", trim = TRUE)
  }
  txt <- paste0(prefix, fmt(value), suffix)
  if (!is.null(sec)) txt <- paste0(txt, " (", fmt(sec), ")")
  txt <- .wrap_labels(txt, wrap)

  meta <- .clip_meta(vm$clip)
  ctr  <- vm_centroids(vm)

  # Adaptive nudge: proportional to each cell's own size so the value label
  # of a small cell is not pushed out of it.  Capped at the old global default.
  if (is.null(nudge_y)) {
    cell_r  <- sqrt(abs(vapply(vm$cells, polygon_area, numeric(1))) / pi)
    nudge_y <- -pmin(0.10 * meta$radius, 0.45 * cell_r)
  }
  xs <- ctr$cx + nudge_x
  ys <- ctr$cy + nudge_y

  # Clamp: if the nudged anchor falls outside its cell, shrink the offset
  # toward the centroid until it is inside (centroid itself always is,
  # since cells are convex).
  if (isTRUE(inside)) {
    for (i in seq_along(xs)) {
      f <- 1
      while (f > 0 &&
             !point_in_polygon(c(ctr$cx[i] + f * (xs[i] - ctr$cx[i]),
                                 ctr$cy[i] + f * (ys[i] - ctr$cy[i])),
                               vm$cells[[i]])) {
        f <- f - 0.25
      }
      f <- max(f, 0)
      xs[i] <- ctr$cx[i] + f * (xs[i] - ctr$cx[i])
      ys[i] <- ctr$cy[i] + f * (ys[i] - ctr$cy[i])
    }
  }

  df <- data.frame(x = xs, y = ys,
                   label = txt, cell_label = ctr$label,
                   size = .label_sizes(vm, size, autoscale, default = 2.8),
                   fontface = .resolve_fontface(vm, fontface),
                   area_frac = .area_fractions(vm),
                   col = .resolve_label_col(vm, col, "grey20"),
                   stringsAsFactors = FALSE)
  if (!is.null(cells)) df <- df[df$cell_label %in% cells, , drop = FALSE]
  if (min_area > 0) df <- df[df$area_frac >= min_area, , drop = FALSE]
  if (nrow(df) == 0L) return(p)

  layer <- do.call(ggplot2::geom_text, .add_family(
    list(
      data = df,
      mapping = ggplot2::aes(x = .data$x, y = .data$y, label = .data$label),
      inherit.aes = FALSE, colour = df$col, size = df$size, fontface = df$fontface
    ), family))
  .vm_plus(p, layer, vm)
}
