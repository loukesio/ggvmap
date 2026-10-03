# ---- Main algorithm: voronoi_map() ----
#
# Implements the iterative power-diagram adaptation of
# Nocaj & Brandes (2012) "Computing Voronoi Treemaps --
# Faster, Simpler, and Resolution-independent".
#
# The iteration heuristics (flickering damping, clamped weight updates,
# over-weighted-site correction) and their constants are ported from
# d3-voronoi-map, Copyright (c) 2018 Franck Lebeau, BSD 3-Clause licence;
# see inst/COPYRIGHTS.

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
#'                 polygon area falls below this ratio. The total area error
#'                 is the sum over cells of |actual area - target area|: each
#'                 cell's mistake, too big or too small, added up. `0.01`
#'                 means these mistakes add up to at most 1% of the map.
#'                 For grouped layouts the budget is split in half between
#'                 the group level and the member level, so the whole map
#'                 meets the same bound. Default `0.01` (1%).
#' @param max_iter Maximum number of iterations.  Default `200`. The
#'                 heuristic rounds use at most `max_iter - min(30, max_iter %/% 4)`
#'                 of them and stop early if the error has not improved for 25
#'                 rounds; the remaining budget goes to a second phase that
#'                 holds the sites fixed and solves for the weights with a
#'                 damped Newton method, which rescues layouts the heuristic
#'                 rounds cannot fit (typically when one value dominates).
#' @param min_weight_ratio  Minimum allowed data weight as a fraction of
#'                 the maximum weight.  Weights below this floor are raised
#'                 to it before the layout is computed, so those cells are
#'                 drawn *larger* than their value; compare `target_area`
#'                 with the data to see which cells were affected. Set to
#'                 `0` to keep every area strictly proportional.
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
#'                 and `sites`, and `fit`, a data frame with the iterations,
#'                 area-error ratio and convergence of the group level and of
#'                 each group's members; otherwise `NULL`.}
#'   \item{hierarchical}{Logical flag.}
#'   \item{iterations}{Number of iterations performed (group level when
#'                 hierarchical; see `groups$fit` for the member levels).}
#'   \item{convergence}{Final area-error ratio of the whole map: the sum over
#'                 cells of |actual - target| area, divided by the map area.}
#'   \item{converged}{Logical; is `convergence` below `convergence_ratio`?}
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
  if (any(!is.finite(clip))) stop("clip must have finite coordinates.", call. = FALSE)
  if (all(clip[1, ] == clip[nrow(clip), ])) clip <- clip[-nrow(clip), , drop = FALSE]
  edges <- clip[c(seq.int(2L, nrow(clip)), 1L), , drop = FALSE] - clip
  next_edges <- edges[c(seq.int(2L, nrow(edges)), 1L), , drop = FALSE]
  turns <- edges[, 1] * next_edges[, 2] - edges[, 2] * next_edges[, 1]
  rotation <- sum(atan2(turns, rowSums(edges * next_edges)))
  if (nrow(clip) < 3L || abs(polygon_area(clip)) == 0 ||
      !(all(turns >= 0) || all(turns <= 0)) || abs(abs(rotation) - 2 * pi) > 1e-7) {
    stop("voronoi_map() requires a convex clip. Use vmap_region() for concave outlines, holes or separate pieces.", call. = FALSE)
  }
  if (polygon_area(clip) < 0) clip <- clip[nrow(clip):1L, , drop = FALSE]

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

  # Apply the small-weight floor once, globally, so both levels aim at the
  # same targets that the final error is measured against.
  weights_floor <- pmax(weights, max(weights) * min_weight_ratio)
  g_weight <- vapply(g_levels, function(g) sum(weights_floor[group == g]), numeric(1))

  # Split the error budget between the two levels. The group-level error and
  # the member-level errors add up at most, so giving each level half of
  # `convergence_ratio` keeps the whole map within `convergence_ratio`.
  level_ratio <- convergence_ratio / 2

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
    convergence_ratio = level_ratio,
    max_iter          = max_iter,
    min_weight_ratio  = 0,
    verbose           = verbose
  )

  group_sites <- data.frame(
    x           = top$sx,
    y           = top$sy,
    weight      = top$sw,
    target_area = top$target_areas,
    actual_area = top$actual_areas,
    label       = g_levels,
    data_weight = vapply(g_levels, function(g) sum(weights[group == g]), numeric(1)),
    stringsAsFactors = FALSE
  )

  # --- Level 2: fill each group cell with its members ---
  cells   <- vector("list", length(weights))
  site_df <- vector("list", ng)
  group_fit <- data.frame(group = g_levels, iterations = 0L,
                          convergence = 0, converged = TRUE,
                          stringsAsFactors = FALSE)

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
        actual_areas = abs(polygon_area(g_cell)),
        iterations   = 0L,
        convergence  = 0,
        converged    = TRUE
      )
    } else {
      pos <- .init_positions(length(idx), g_clip)
      sub <- .vmap_solve(
        weights           = weights_floor[idx],
        clip              = g_clip,
        positions         = pos,
        convergence_ratio = level_ratio,
        max_iter          = max_iter,
        min_weight_ratio  = 0,
        verbose           = FALSE
      )
    }
    group_fit$iterations[k]  <- sub$iterations
    group_fit$convergence[k] <- sub$convergence
    group_fit$converged[k]   <- sub$converged

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
  target_all   <- total_area * weights_floor / sum(weights_floor)
  convergence  <- sum(abs(target_all - actual_areas)) / total_area
  # The final targets are the global ones, not each group's local targets.
  sites$target_area <- target_all

  structure(
    list(
      cells        = cells,
      sites        = sites,
      clip         = clip,
      groups       = list(cells = top$cells, sites = group_sites,
                          fit = rbind(
                            data.frame(group = "(groups)",
                                       iterations = top$iterations,
                                       convergence = top$convergence,
                                       converged = top$converged,
                                       stringsAsFactors = FALSE),
                            group_fit)),
      hierarchical = TRUE,
      iterations   = top$iterations,
      convergence  = convergence,
      converged    = convergence < convergence_ratio
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
  best <- list(error = Inf, iter = 0L)

  # Phase 1 (heuristic rounds) may use all but a reserve of the budget, and
  # stops early once it stalls. Phase 2 (below) gets the rest.
  newton_reserve <- min(30L, max_iter %/% 4L)
  stall_rounds   <- 25L

  cells <- power_diagram(cbind(x = sx, y = sy, weight = sw), clip)

  for (it in seq_len(max_iter - newton_reserve)) {
    iter <- it

    # `cells` holds the diagram for the current sites and weights (computed
    # before the loop, then at the end of each iteration).
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
    if (area_error < best$error) {
      best <- list(error = area_error, iter = it, sx = sx, sy = sy)
    } else if (it - best$iter >= stall_rounds) {
      break
    }
  }

  # Phase 2: the heuristic rounds can get stuck, typically when one value
  # dominates. Keep the best site positions found so far and solve for the
  # weights directly (damped Newton); for fixed sites, weights giving exactly
  # the target areas always exist.
  # options(ggvmap.newton = FALSE) switches phase 2 off; used only by the
  # accuracy study (data-raw/fit_study.R) to measure what phase 2 adds.
  if (!converged && iter < max_iter && is.finite(best$error) &&
      isTRUE(getOption("ggvmap.newton", TRUE))) {
    nw <- .newton_weights(best$sx, best$sy, target_areas, clip,
                          tol_abs = area_error_thresh,
                          max_steps = max_iter - iter, verbose = verbose)
    if (!is.null(nw)) {
      iter <- iter + nw$steps
      if (nw$error < sum(abs(target_areas - actual_areas))) {
        sx <- best$sx; sy <- best$sy; sw <- nw$sw
        cells <- nw$cells; actual_areas <- nw$areas
      }
      converged <- sum(abs(target_areas - actual_areas)) < area_error_thresh
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

#' Fit power weights to target areas with the sites held fixed
#'
#' Damped Newton method for the area equations a(w) = A (Kitagawa, Merigot &
#' Thibert 2019, J. Eur. Math. Soc. 21:2603-2651). Increasing w_i by d moves
#' the border between cells i and j towards site j by d / (2 |s_i - s_j|), so
#' da_i/dw_j = -L_ij / (2 |s_i - s_j|) for neighbours sharing a border of
#' length L_ij, and da_i/dw_i is minus the sum of the others. Starting from
#' equal weights (an ordinary Voronoi diagram), every cell contains its site
#' and is non-empty; each step is halved until all cells keep at least half
#' the smallest starting or target area and the error has dropped.
#' Returns NULL when the start is unusable (e.g. coincident sites).
#' @noRd
.newton_weights <- function(sx, sy, target, clip, tol_abs, max_steps,
                            verbose = FALSE) {
  n <- length(sx)
  sw <- numeric(n)
  sites <- function(w) cbind(x = sx, y = sy, weight = w)
  cells <- power_diagram(sites(sw), clip)
  areas <- abs(vapply(cells, polygon_area, numeric(1)))
  min_area <- 0.5 * min(target, areas)
  if (!(min_area > 1e-12 * sum(target))) return(NULL)
  resid <- function(a) sqrt(sum((target - a)^2))
  steps <- 0L
  while (steps < max_steps && sum(abs(target - areas)) >= tol_abs) {
    steps <- steps + 1L
    H <- .power_jacobian(cells, sx, sy, sw, clip)
    # Adding a constant to every weight changes nothing, so fix sw[1].
    delta <- tryCatch(
      c(0, solve(H[-1, -1, drop = FALSE], (target - areas)[-1])),
      error = function(e) NULL)
    if (is.null(delta)) break
    tau <- 1; accepted <- FALSE
    for (halving in seq_len(30L)) {
      w_try <- sw + tau * delta
      c_try <- power_diagram(sites(w_try), clip)
      a_try <- abs(vapply(c_try, polygon_area, numeric(1)))
      if (min(a_try) >= min_area &&
          resid(a_try) <= (1 - tau / 2) * resid(areas)) {
        accepted <- TRUE
        break
      }
      tau <- tau / 2
    }
    if (!accepted) break
    sw <- w_try; cells <- c_try; areas <- a_try
    if (verbose) {
      message(sprintf("Newton step %2d | error: %.4f%%", steps,
                      100 * sum(abs(target - areas)) / sum(target)))
    }
  }
  list(sw = sw - min(sw), cells = cells, areas = areas, steps = steps,
       error = sum(abs(target - areas)))
}

#' Jacobian of the cell areas with respect to the power weights
#'
#' Each edge of cell i either lies on the clip boundary or on the border with
#' the neighbour j whose power distance at the edge midpoint equals i's.
#' @noRd
.power_jacobian <- function(cells, sx, sy, sw, clip) {
  n <- length(sx)
  H <- matrix(0, n, n)
  span <- max(diff(range(clip[, 1])), diff(range(clip[, 2])))
  tol <- 1e-7 * span^2
  for (i in seq_len(n)) {
    v <- cells[[i]]
    k <- nrow(v)
    if (k < 3L) next
    nxt <- c(seq.int(2L, k), 1L)
    mx <- (v[, 1] + v[nxt, 1]) / 2
    my <- (v[, 2] + v[nxt, 2]) / 2
    len <- sqrt((v[nxt, 1] - v[, 1])^2 + (v[nxt, 2] - v[, 2])^2)
    for (e in seq_len(k)) {
      if (len[e] <= 0) next
      pw <- (mx[e] - sx)^2 + (my[e] - sy)^2 - sw
      gap <- pw - pw[i]
      gap[i] <- Inf
      j <- which.min(gap)
      if (abs(gap[j]) > tol) next          # edge on the clip boundary
      d <- sqrt((sx[i] - sx[j])^2 + (sy[i] - sy[j])^2)
      H[i, j] <- H[i, j] - len[e] / (2 * d)
    }
    H[i, i] <- -sum(H[i, -i])
  }
  H
}


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
  fit <- x$groups$fit
  if (isTRUE(x$hierarchical) && !is.null(fit) && !all(fit$converged)) {
    cat(sprintf("  Unconverged levels: %s\n",
                paste(fit$group[!fit$converged], collapse = ", ")))
  }
  invisible(x)
}
