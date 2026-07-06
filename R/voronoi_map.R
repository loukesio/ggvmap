# ---- Main algorithm: voronoi_map() ----
#
# Implements the iterative power-diagram adaptation of
# Nocaj & Brandes (2012) "Computing Voronoi Treemaps --
# Faster, Simpler, and Resolution-independent".

#' Compute a Voronoi map
#'
#' Partition a convex polygon into cells whose areas are proportional
#' to a set of weights, using an iteratively refined power diagram.
#'
#' When `group` is supplied the layout becomes **hierarchical**: the boundary
#' is first partitioned into one convex sub-region per group (with area
#' proportional to the group's total weight), and each sub-region is then
#' filled with its member cells.  On a circular boundary the groups are seeded
#' radially so that they form contiguous angular sectors -- the arrangement the
#' [vm_add_ring()] annotation ring is designed to wrap.
#'
#' @param weights  Numeric vector of positive weights (one per cell).
#' @param labels   Optional character vector of cell labels.
#' @param group    Optional grouping vector (one value per cell).  When
#'                 supplied a hierarchical layout is produced.
#' @param clip     Clipping polygon as a 2-column matrix (x, y),
#'                 counterclockwise and open.
#'                 Defaults to the unit square.
#' @param convergence_ratio  Stop when the total area error divided by the
#'                 polygon area falls below this ratio.
#'                 Default `0.01` (1%).
#' @param max_iter Maximum number of iterations.  Default `200`.
#' @param min_weight_ratio  Minimum allowed data weight as a fraction of
#'                 the maximum weight.  Prevents near-empty cells.
#'                 Default `0.01`.
#' @param seed     Integer seed for reproducible initial positions.
#'                 `NULL` (default) uses a random layout.
#' @param verbose  Print iteration progress? Default `FALSE`.
#'
#' @return An object of class `"voronoi_map"` (a list) containing:
#' \describe{
#'   \item{cells}{List of 2-column polygon matrices.}
#'   \item{sites}{Data frame with columns `x`, `y`, `weight`,
#'                `target_area`, `actual_area`, `label`, `data_weight`
#'                and (when hierarchical) `group`.}
#'   \item{clip}{The clipping polygon.}
#'   \item{groups}{When hierarchical: a list with the group-level `cells`
#'                 and `sites`; otherwise `NULL`.}
#'   \item{hierarchical}{Logical flag.}
#'   \item{iterations}{Number of iterations performed (top level).}
#'   \item{convergence}{Final area-error ratio.}
#'   \item{converged}{Logical; did convergence_ratio threshold get reached?}
#' }
#'
#' @examples
#' # Simple example: 5 sectors
#' vm <- voronoi_map(
#'   weights = c(3, 2, 5, 1, 4),
#'   labels  = c("A", "B", "C", "D", "E"),
#'   seed    = 42
#' )
#' plot(vm)
#'
#' # Hierarchical example on a circular boundary
#' vm_h <- voronoi_map(
#'   weights = c(5, 3, 2, 8, 4, 1, 6, 2),
#'   labels  = letters[1:8],
#'   group   = c("X", "X", "X", "Y", "Y", "Z", "Z", "Z"),
#'   clip    = clip_circle(),
#'   seed    = 1
#' )
#' plot(vm_h)
#'
#' @export
voronoi_map <- function(
  weights,
  labels            = NULL,
  group             = NULL,
  clip              = clip_square(),
  convergence_ratio = 0.01,
  max_iter          = 200,
  min_weight_ratio  = 0.01,
  seed              = NULL,
  verbose           = FALSE
) {

  # --- Validate inputs ---
  stopifnot(is.numeric(weights), length(weights) >= 1, all(weights > 0))
  n <- length(weights)
  if (is.null(labels)) labels <- paste0("V", seq_len(n))
  stopifnot(length(labels) == n)
  stopifnot(is.matrix(clip), ncol(clip) == 2, nrow(clip) >= 3)

  if (!is.null(group)) {
    stopifnot(length(group) == n)
    return(.voronoi_map_grouped(
      weights, labels, group, clip,
      convergence_ratio, max_iter, min_weight_ratio, seed, verbose
    ))
  }

  if (!is.null(seed)) set.seed(seed)
  positions <- .init_positions(n, clip)

  sol <- .vmap_solve(
    weights           = weights,
    clip              = clip,
    positions         = positions,
    convergence_ratio = convergence_ratio,
    max_iter          = max_iter,
    min_weight_ratio  = min_weight_ratio,
    verbose           = verbose
  )

  sites <- data.frame(
    x           = sol$sx,
    y           = sol$sy,
    weight      = sol$sw,
    target_area = sol$target_areas,
    actual_area = sol$actual_areas,
    label       = labels,
    data_weight = weights,
    group       = NA_character_,
    stringsAsFactors = FALSE
  )

  structure(
    list(
      cells        = sol$cells,
      sites        = sites,
      clip         = clip,
      groups       = NULL,
      hierarchical = FALSE,
      iterations   = sol$iterations,
      convergence  = sol$convergence,
      converged    = sol$converged
    ),
    class = "voronoi_map"
  )
}

# --- Hierarchical driver ----------------------------------------------------

#' @noRd
.voronoi_map_grouped <- function(weights, labels, group, clip,
                                 convergence_ratio, max_iter,
                                 min_weight_ratio, seed, verbose) {
  group <- as.character(group)
  # Preserve first-appearance order of groups
  g_levels <- unique(group)
  ng <- length(g_levels)
  g_weight <- vapply(g_levels, function(g) sum(weights[group == g]), numeric(1))

  meta <- .clip_meta(clip)

  if (!is.null(seed)) set.seed(seed)

  # --- Level 1: partition the boundary into one convex cell per group ---
  if (meta$circular && ng > 1L) {
    g_positions <- .radial_positions(g_weight, meta$center, meta$radius)
  } else {
    g_positions <- .init_positions(ng, clip)
  }
  top <- .vmap_solve(
    weights           = g_weight,
    clip              = clip,
    positions         = g_positions,
    convergence_ratio = convergence_ratio,
    max_iter          = max_iter,
    min_weight_ratio  = min_weight_ratio,
    verbose           = verbose
  )

  group_sites <- data.frame(
    x           = top$sx,
    y           = top$sy,
    weight      = top$sw,
    target_area = top$target_areas,
    actual_area = top$actual_areas,
    label       = g_levels,
    data_weight = g_weight,
    stringsAsFactors = FALSE
  )

  # --- Level 2: fill each group cell with its members ---
  cells   <- vector("list", length(weights))
  site_df <- vector("list", ng)

  for (k in seq_len(ng)) {
    g       <- g_levels[k]
    idx     <- which(group == g)
    g_cell  <- top$cells[[k]]
    g_clip  <- .as_clip(g_cell)

    if (length(idx) == 1L) {
      sub <- list(
        cells        = list(g_cell),
        sx           = mean(g_cell[, 1]),
        sy           = mean(g_cell[, 2]),
        sw           = 1,
        target_areas = abs(polygon_area(g_cell)),
        actual_areas = abs(polygon_area(g_cell))
      )
    } else {
      pos <- .init_positions(length(idx), g_clip)
      sub <- .vmap_solve(
        weights           = weights[idx],
        clip              = g_clip,
        positions         = pos,
        convergence_ratio = convergence_ratio,
        max_iter          = max_iter,
        min_weight_ratio  = min_weight_ratio,
        verbose           = FALSE
      )
    }

    cells[idx] <- sub$cells
    site_df[[k]] <- data.frame(
      idx         = idx,
      x           = sub$sx,
      y           = sub$sy,
      weight      = sub$sw,
      target_area = sub$target_areas,
      actual_area = sub$actual_areas,
      label       = labels[idx],
      data_weight = weights[idx],
      group       = g,
      stringsAsFactors = FALSE
    )
  }

  sites <- do.call(rbind, site_df)
  sites <- sites[order(sites$idx), , drop = FALSE]
  sites$idx <- NULL
  rownames(sites) <- NULL

  total_area   <- abs(polygon_area(clip))
  actual_areas <- abs(vapply(cells, polygon_area, numeric(1)))
  target_all   <- (total_area * pmax(weights, max(weights) * min_weight_ratio)) /
    sum(pmax(weights, max(weights) * min_weight_ratio))
  convergence  <- sum(abs(target_all - actual_areas)) / total_area

  structure(
    list(
      cells        = cells,
      sites        = sites,
      clip         = clip,
      groups       = list(cells = top$cells, sites = group_sites),
      hierarchical = TRUE,
      iterations   = top$iterations,
      convergence  = convergence,
      converged    = top$converged
    ),
    class = "voronoi_map"
  )
}

# --- Core solver ------------------------------------------------------------

#' Core power-diagram iteration.
#'
#' Given weights, a clip polygon and starting positions, run the
#' Nocaj & Brandes adaptation loop and return the fitted cells + sites.
#' @noRd
.vmap_solve <- function(weights, clip, positions,
                        convergence_ratio, max_iter,
                        min_weight_ratio, verbose) {
  n <- length(weights)

  total_area        <- abs(polygon_area(clip))
  area_error_thresh <- convergence_ratio * total_area
  epsilon           <- total_area * 1e-6

  max_w   <- max(weights)
  min_w   <- max_w * min_weight_ratio
  w_safe  <- pmax(weights, min_w)
  total_w <- sum(w_safe)
  target_areas <- (total_area * w_safe) / total_w

  # Degenerate single-cell case: the cell *is* the clip.
  if (n == 1L) {
    return(list(
      cells        = list(clip[, 1:2, drop = FALSE]),
      sx           = mean(clip[, 1]),
      sy           = mean(clip[, 2]),
      sw           = total_area / 2,
      target_areas = target_areas,
      actual_areas = total_area,
      iterations   = 0L,
      convergence  = 0,
      converged    = TRUE
    ))
  }

  # Initialise power weights proportional to each cell's target area (a cell of
  # area A has characteristic radius ~ sqrt(A / pi), so weight ~ A / pi). This
  # converges markedly faster than a uniform start when there are many cells or
  # a wide weight range, and avoids transient cell collapses.
  sx <- positions[, 1]
  sy <- positions[, 2]
  sw <- pmax(target_areas / pi, epsilon)

  flickering_history <- numeric(0)
  converged <- FALSE
  iter <- 0L
  cells <- NULL
  actual_areas <- NULL

  for (it in seq_len(max_iter)) {
    iter <- it

    site_mat <- cbind(x = sx, y = sy, weight = sw)
    cells <- power_diagram(site_mat, clip)

    flicker_influence_pos <- 0.5
    fmr <- .flickering_ratio(flickering_history, total_area)
    damping <- 1 - flicker_influence_pos * fmr

    for (i in seq_len(n)) {
      ctr <- polygon_centroid(cells[[i]])
      dx <- (ctr[1] - sx[i]) * damping
      dy <- (ctr[2] - sy[i]) * damping
      nx <- sx[i] + dx
      ny <- sy[i] + dy
      if (point_in_polygon(c(nx, ny), clip)) {
        sx[i] <- nx
        sy[i] <- ny
      }
    }

    site_mat <- cbind(x = sx, y = sy, weight = sw)
    cells <- power_diagram(site_mat, clip)

    flicker_influence_wt <- 0.1
    fm <- flicker_influence_wt * fmr

    for (i in seq_len(n)) {
      cur_area <- abs(polygon_area(cells[[i]]))
      if (cur_area < 1e-12) next
      ratio <- target_areas[i] / cur_area
      ratio <- max(ratio, 1 - flicker_influence_wt + fm)
      ratio <- min(ratio, 1 + flicker_influence_wt - fm)
      sw[i] <- max(sw[i] * ratio, epsilon)
    }

    sw <- .handle_overweighted(sx, sy, sw, n, epsilon)

    site_mat <- cbind(x = sx, y = sy, weight = sw)
    cells <- power_diagram(site_mat, clip)
    actual_areas <- abs(vapply(cells, polygon_area, numeric(1)))
    area_error <- sum(abs(target_areas - actual_areas))
    flickering_history <- c(flickering_history, area_error)
    conv_ratio <- area_error / total_area

    if (verbose && (it <= 5 || it %% 10 == 0 || it == max_iter)) {
      message(sprintf("Iteration %3d | error: %.4f%%", it, conv_ratio * 100))
    }

    if (area_error < area_error_thresh) {
      converged <- TRUE
      break
    }
  }

  list(
    cells        = cells,
    sx           = sx,
    sy           = sy,
    sw           = sw,
    target_areas = target_areas,
    actual_areas = actual_areas,
    iterations   = iter,
    convergence  = sum(abs(target_areas - actual_areas)) / total_area,
    converged    = converged
  )
}

# --- Internal helpers -------------------------------------------------------

#' Turn a bare polygon matrix into a clip with inferred metadata
#' @noRd
.as_clip <- function(poly) {
  poly <- poly[, 1:2, drop = FALSE]
  ctr  <- colMeans(poly)
  rad  <- mean(sqrt((poly[, 1] - ctr[1])^2 + (poly[, 2] - ctr[2])^2))
  .set_clip_meta(poly, center = ctr, radius = rad, shape = "polygon")
}

#' Seed group sites around a circle by cumulative angular weight
#'
#' Produces contiguous angular sectors reaching the boundary, so the
#' hierarchical layout matches the outer annotation ring.
#' @noRd
.radial_positions <- function(g_weight, center, radius) {
  frac <- g_weight / sum(g_weight)
  cum  <- cumsum(frac)
  mid  <- (c(0, cum[-length(cum)]) + cum) / 2       # mid-fraction of each sector
  ang  <- 2 * pi * mid - pi / 2                     # start at top, go clockwise-ish
  rr   <- radius * 0.55
  cbind(center[1] + rr * cos(ang), center[2] + rr * sin(ang))
}

#' Rejection-sample points uniformly inside a convex polygon
#' @noRd
.rejection_sample <- function(m, clip) {
  xr <- range(clip[, 1]); yr <- range(clip[, 2])
  pts <- matrix(nrow = 0, ncol = 2)
  guard <- 0L
  while (nrow(pts) < m && guard < 1000L) {
    guard <- guard + 1L
    cx <- stats::runif(m * 4, xr[1], xr[2])
    cy <- stats::runif(m * 4, yr[1], yr[2])
    inside <- vapply(seq_along(cx), function(k) {
      point_in_polygon(c(cx[k], cy[k]), clip)
    }, logical(1))
    pts <- rbind(pts, cbind(cx[inside], cy[inside]))
  }
  if (nrow(pts) < m) {
    # Fallback: jitter around the centroid (thin/degenerate clips)
    ctr <- colMeans(clip)
    pts <- rbind(pts, cbind(ctr[1] + stats::runif(m, -1e-3, 1e-3),
                            ctr[2] + stats::runif(m, -1e-3, 1e-3)))
  }
  pts[seq_len(m), , drop = FALSE]
}

#' Generate well-spread initial positions inside a convex polygon
#'
#' Farthest-point ("best candidate") sampling from a uniform pool: each new site
#' is the pooled point that maximises the distance to the sites chosen so far.
#' A spread-out start converges much faster and avoids the transient cell
#' collapses a clustered random start can cause.
#' @noRd
.init_positions <- function(n, clip) {
  if (n == 1L) return(matrix(colMeans(clip), nrow = 1))
  pool <- .rejection_sample(max(n * 20L, 64L), clip)
  m <- nrow(pool)
  chosen <- integer(n)
  chosen[1] <- 1L
  mind <- (pool[, 1] - pool[1, 1])^2 + (pool[, 2] - pool[1, 2])^2
  for (k in 2:n) {
    mind[chosen[seq_len(k - 1L)]] <- -Inf
    pick <- which.max(mind)
    chosen[k] <- pick
    d <- (pool[, 1] - pool[pick, 1])^2 + (pool[, 2] - pool[pick, 2])^2
    mind <- pmin(mind, d)
  }
  pool[chosen, , drop = FALSE]
}

#' Compute a flickering-mitigation ratio from the error history
#' @noRd
.flickering_ratio <- function(history, total_area) {
  len <- length(history)
  if (len < 10) return(0)
  recent <- utils::tail(history, 10)
  diffs  <- diff(recent)
  sum(diffs > 0) / length(diffs)
}

#' Heuristic: increase light weights when two sites overlap
#' Returns the modified weight vector.
#' @noRd
.handle_overweighted <- function(sx, sy, sw, n, epsilon) {
  max_fixes <- n * n  # cap total fixes to avoid infinite loops
  fix_count <- 0L
  repeat {
    fixed <- FALSE
    for (i in seq_len(n - 1L)) {
      for (j in (i + 1L):n) {
        if (sw[i] > sw[j]) {
          hi <- i; lo <- j
        } else {
          hi <- j; lo <- i
        }
        sqr_d <- (sx[i] - sx[j])^2 + (sy[i] - sy[j])^2
        if (sqr_d < sw[hi] - sw[lo]) {
          overweight <- sw[hi] - sw[lo] - sqr_d
          sw[lo] <- sw[lo] + overweight + epsilon
          fixed <- TRUE
          fix_count <- fix_count + 1L
          break
        }
      }
      if (fixed) break
    }
    if (!fixed || fix_count >= max_fixes) break
  }
  sw
}

# --- Print method -----------------------------------------------------------

#' @export
print.voronoi_map <- function(x, ...) {
  cat("Voronoi Map\n")
  if (isTRUE(x$hierarchical)) {
    cat(sprintf("  hierarchical | %d groups | %d cells\n",
                nrow(x$groups$sites), nrow(x$sites)))
  }
  cat(sprintf("  %d cells | %d iterations | convergence: %.3f%%\n",
              nrow(x$sites), x$iterations, x$convergence * 100))
  cat(sprintf("  Converged: %s\n", x$converged))
  invisible(x)
}
