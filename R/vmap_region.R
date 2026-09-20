# ---- Weighted Voronoi partitions on regions with holes and separate parts ----

#' Fit a Voronoi map inside a non-convex or multipart region
#'
#' Partition a supplied outline into cells whose areas approximate positive
#' weights. Unlike [voronoi_map()], this function supports inward dents, holes,
#' and disconnected pieces. Requires the optional package \pkg{polyclip}.
#'
#' @param weights Finite positive numeric weights, one per cell.
#' @param region A two-column coordinate matrix; a ring `list(x = ..., y = ...)`;
#'   a list of such matrices or rings; or an `sf`/`sfc` polygon object. Matrix
#'   and ring coordinates are treated as planar. Rings use the even-odd fill
#'   rule: a ring inside another ring is a hole, regardless of orientation.
#'   Repeated closing vertices are optional. For `sf`, all features are united
#'   into one region; use separate calls to fit districts independently.
#' @param labels Optional unique cell labels, otherwise `V1`, `V2`, etc.
#' @param crs Optional projected coordinate system passed to [sf::st_transform()]
#'   for `sf`/`sfc` input. Geographic longitude/latitude input must be projected
#'   explicitly. No place-name lookup or automatic projection is performed.
#' @param seed Optional integer seed. When supplied, the caller's random-number
#'   state is restored after computation.
#' @param max_iter Maximum number of iterations; default `1000`.
#' @param convergence_ratio Stop when the sum of absolute cell-area errors,
#'   divided by region area, is below this value; default `0.005`.
#' @param min_weight_ratio Minimum weight as a fraction of the largest weight.
#'   Default `0` preserves the requested proportions. Positive values inflate
#'   small weights and change the targets.
#' @param verbose Print progress every 25 iterations?
#'
#' @details Computation uses translated, uniformly scaled coordinates to avoid
#'   instability with large map coordinates. Output coordinates and areas are
#'   restored to the input (or requested projected) coordinate system. Boundaries
#'   are not simplified automatically. Invalid `sf` geometry is rejected; repair
#'   it explicitly before calling. Coordinate rings are interpreted with the
#'   even-odd rule and normalized by `polyclip`.
#'
#'   Cells may contain several disconnected pieces or holes. A successful area
#'   fit does not imply geographically meaningful cell positions. Convergence
#'   is not guaranteed for every shape or weight distribution: an unsuccessful
#'   fit emits a warning and returns the best layout found with
#'   `converged = FALSE`. Never use an unchecked layout as an exact encoding.
#'   After at most 100 position/weight iterations, a stalled fit uses the
#'   remaining iteration budget for fixed-site, coordinate-wise weight searches.
#'   These power weights may be negative; data weights remain positive.
#'
#'   Supports [ggvmap()], [autoplot()], [plot()], [vm_as_df()], [vm_centroids()],
#'   and ordinary cell annotations. Hierarchical grouping is not implemented;
#'   fit separate regions separately. Interactive rendering and the decorative
#'   outer ring are currently unavailable for region maps.
#'
#' @return A `voronoi_region` object inheriting from `voronoi_map`. It contains
#'   `cells` (one list of rings per cell), `clip` (the region rings), `sites`
#'   (positions, power weights, labels, data weights, target and actual areas),
#'   `iterations`, `convergence`, `converged`, `total_area`, and `crs` (an `sf`
#'   CRS for spatial input, otherwise `NULL`). Each ring is `list(x, y)`;
#'   outer rings are counterclockwise and holes clockwise. Coordinates use the
#'   output planar units; areas use their squares. `vm_as_df()` adds a `ring`
#'   column, to be mapped to `subgroup` with `rule = "evenodd"` when plotting.
#'
#' @examples
#' if (requireNamespace("polyclip", quietly = TRUE)) {
#'   outline <- cbind(c(0, 3, 3, 1, 1, 0), c(0, 0, 1, 1, 3, 3))
#'   vm <- vmap_region(c(5, 3, 2), outline, seed = 4)
#'   print(vm)
#'   ggvmap(vm, palette = "alger")
#' }
#' @export
vmap_region <- function(weights, region, labels = NULL, crs = NULL, seed = NULL,
                        max_iter = 1000, convergence_ratio = 0.005,
                        min_weight_ratio = 0, verbose = FALSE) {
  if (!requireNamespace("polyclip", quietly = TRUE)) {
    stop("vmap_region() requires 'polyclip'. Install it with install.packages('polyclip').", call. = FALSE)
  }
  if (!is.numeric(weights) || !length(weights) || any(!is.finite(weights)) || any(weights <= 0)) {
    stop("weights must be finite positive numbers.", call. = FALSE)
  }
  n <- length(weights)
  if (is.null(labels)) labels <- paste0("V", seq_len(n))
  labels <- as.character(labels)
  if (length(labels) != n || anyNA(labels) || any(!nzchar(labels)) || anyDuplicated(labels)) {
    stop("labels must contain one unique, nonempty label per weight.", call. = FALSE)
  }
  scalar <- function(x) is.numeric(x) && length(x) == 1L && is.finite(x)
  if (!scalar(max_iter) || max_iter < 1 || max_iter != floor(max_iter)) {
    stop("max_iter must be a positive integer.", call. = FALSE)
  }
  if (!scalar(convergence_ratio) || convergence_ratio <= 0 || convergence_ratio >= 1) {
    stop("convergence_ratio must be between 0 and 1 (exclusive).", call. = FALSE)
  }
  if (!scalar(min_weight_ratio) || min_weight_ratio < 0 || min_weight_ratio > 1) {
    stop("min_weight_ratio must be between 0 and 1.", call. = FALSE)
  }
  if (!is.logical(verbose) || length(verbose) != 1L || is.na(verbose)) {
    stop("verbose must be TRUE or FALSE.", call. = FALSE)
  }
  if (!is.null(seed)) {
    if (!scalar(seed) || seed < 0 || seed > .Machine$integer.max || seed != floor(seed)) {
      stop("seed must be a nonnegative integer.", call. = FALSE)
    }
    had_rng <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
    old_rng <- if (had_rng) get(".Random.seed", envir = .GlobalEnv) else NULL
    on.exit(if (had_rng) assign(".Random.seed", old_rng, envir = .GlobalEnv)
            else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE))
              rm(".Random.seed", envir = .GlobalEnv), add = TRUE)
    set.seed(seed)
  }
  input <- .region_input(region, crs)
  rings <- input$rings
  coords <- .region_coordinates(rings)
  origin <- apply(coords, 2, min)
  span <- max(apply(coords, 2, function(z) diff(range(z))))
  if (!is.finite(span) || span <= 0) stop("region must have positive finite extent.", call. = FALSE)
  normalized <- lapply(rings, function(p) list(x = (p$x - origin[1]) / span,
                                              y = (p$y - origin[2]) / span))
  normalized <- polyclip::polyclip(normalized, normalized, "union", eps = 1e-10)
  area <- .region_area(normalized)
  if (!is.finite(area) || area <= 1e-14) stop("region has zero or numerically negligible area.", call. = FALSE)
  safe <- pmax(weights / max(weights), min_weight_ratio)
  target <- area * safe / sum(safe)
  if (any(target <= 0)) stop("Weight range is too large to represent positive target areas.", call. = FALSE)
  solution <- .region_solve(target, normalized, max_iter, convergence_ratio, verbose)
  restore <- function(ps) lapply(ps, function(p) list(x = p$x * span + origin[1],
                                                     y = p$y * span + origin[2]))
  cells <- lapply(solution$cells, restore)
  clip <- restore(normalized)
  clip <- .set_clip_meta(clip, center = origin + colMeans(.region_coordinates(normalized)) * span,
                         radius = span / 2, shape = "region")
  sites <- data.frame(x = solution$sx * span + origin[1],
                      y = solution$sy * span + origin[2],
                      weight = solution$sw * span^2,
                      target_area = target * span^2,
                      actual_area = solution$areas * span^2,
                      label = labels, data_weight = weights, stringsAsFactors = FALSE)
  if (any(!is.finite(as.matrix(sites[c("x", "y", "weight", "target_area", "actual_area")])))) {
    stop("Output overflow: rescale the region coordinates.", call. = FALSE)
  }
  out <- structure(list(cells = cells, sites = sites, clip = clip,
                        groups = NULL, hierarchical = FALSE,
                        iterations = solution$iterations, convergence = solution$convergence,
                        converged = solution$converged, total_area = area * span^2,
                        crs = input$crs), class = c("voronoi_region", "voronoi_map"))
  if (!out$converged) warning(sprintf(
    "vmap_region() did not converge after %d iterations; best total area error is %.3f%%. Check $converged before plotting.",
    max_iter, 100 * out$convergence), call. = FALSE)
  out
}

.region_input <- function(region, crs) {
  output_crs <- NULL
  if (inherits(region, "sf") || inherits(region, "sfc")) {
    if (!requireNamespace("sf", quietly = TRUE)) stop("Spatial input requires the 'sf' package.", call. = FALSE)
    g <- sf::st_geometry(region)
    if (is.na(sf::st_crs(g))) stop("Spatial input must have a known projected CRS.", call. = FALSE)
    if (!is.null(crs)) g <- sf::st_transform(g, crs)
    if (isTRUE(sf::st_is_longlat(g))) {
      stop("Project longitude/latitude input first with sf::st_transform(), or supply a projected crs=.", call. = FALSE)
    }
    if (!length(g) || any(sf::st_is_empty(g)) ||
        !all(as.character(sf::st_geometry_type(g)) %in% c("POLYGON", "MULTIPOLYGON"))) {
      stop("region must contain nonempty POLYGON or MULTIPOLYGON geometry.", call. = FALSE)
    }
    if (!all(sf::st_is_valid(g))) stop("Invalid region geometry; repair it explicitly with sf::st_make_valid().", call. = FALSE)
    output_crs <- sf::st_crs(g)
    polygons <- sf::st_cast(sf::st_union(g), "POLYGON", warn = FALSE)
    region <- unlist(lapply(polygons, function(p) unclass(p)), recursive = FALSE)
  } else if (!is.null(crs)) {
    stop("crs is only available with sf or sfc input.", call. = FALSE)
  }
  is_ring <- function(p) is.list(p) && all(c("x", "y") %in% names(p))
  if (is.matrix(region) || is_ring(region)) region <- list(region)
  if (!is.list(region) || !length(region)) stop("region must be a coordinate matrix, ring list, or sf polygon.", call. = FALSE)
  rings <- lapply(region, function(p) {
    if (is_ring(p)) {
      if (!is.numeric(p$x) || !is.numeric(p$y) || length(p$x) != length(p$y)) {
        stop("Each ring needs equally long numeric x and y vectors.", call. = FALSE)
      }
      p <- cbind(p$x, p$y)
    }
    if (!is.matrix(p) || !is.numeric(p) || ncol(p) != 2L || nrow(p) < 3L || any(!is.finite(p))) {
      stop("Each ring must have at least three finite two-dimensional vertices.", call. = FALSE)
    }
    if (all(p[1, ] == p[nrow(p), ])) p <- p[-nrow(p), , drop = FALSE]
    if (nrow(unique(p)) < 3L) stop("Each ring needs at least three distinct vertices.", call. = FALSE)
    list(x = unname(p[, 1]), y = unname(p[, 2]))
  })
  list(rings = rings, crs = output_crs)
}

.region_coordinates <- function(ps) do.call(rbind, lapply(ps, function(p) cbind(p$x, p$y)))

.region_ring_area <- function(p) {
  # Translate before the signed integral: stable with projected map coordinates.
  x <- p$x - p$x[1]; y <- p$y - p$y[1]; j <- c(seq.int(2L, length(x)), 1L)
  sum(x * y[j] - x[j] * y) / 2
}
.region_area <- function(ps) sum(vapply(ps, .region_ring_area, numeric(1)))

.region_centroid <- function(ps) {
  a <- vapply(ps, .region_ring_area, numeric(1))
  if (!length(ps) || sum(a) <= 0) return(c(NA_real_, NA_real_))
  origin <- c(ps[[1]]$x[1], ps[[1]]$y[1])
  centers <- vapply(ps, function(p) {
    m <- cbind(p$x - origin[1], p$y - origin[2])
    polygon_centroid(m)
  }, numeric(2))
  origin + as.numeric(centers %*% a) / sum(a)
}

.region_inside <- function(pt, ps) {
  inside <- FALSE
  for (p in ps) {
    x <- p$x; y <- p$y; j <- c(seq.int(2L, length(x)), 1L)
    hit <- (y > pt[2]) != (y[j] > pt[2])
    if (any(hit)) {
      crossings <- x[hit] + (pt[2] - y[hit]) * (x[j][hit] - x[hit]) / (y[j][hit] - y[hit])
      if (sum(pt[1] < crossings) %% 2L == 1L) inside <- !inside
    }
  }
  inside
}

# Deterministic interior label anchor, even when the area centroid is in a hole.
.region_anchor <- function(ps) {
  ctr <- .region_centroid(ps)
  if (!length(ps)) return(ctr)
  if (all(is.finite(ctr)) && .region_inside(ctr, ps)) return(ctr)
  ys <- sort(unique(unlist(lapply(ps, `[[`, "y"))))
  mids <- (utils::head(ys, -1) + utils::tail(ys, -1)) / 2
  if (length(mids) > 64L) mids <- mids[unique(round(seq(1, length(mids), length.out = 64)))]
  best <- -Inf; anchor <- ctr
  for (y0 in mids) {
    xs <- sort(unlist(lapply(ps, function(p) {
      j <- c(seq.int(2L, length(p$x)), 1L)
      hit <- (p$y > y0) != (p$y[j] > y0)
      p$x[hit] + (y0 - p$y[hit]) * (p$x[j][hit] - p$x[hit]) / (p$y[j][hit] - p$y[hit])
    })))
    if (length(xs) < 2L || length(xs) %% 2L) next
    starts <- seq.int(1L, length(xs), by = 2L)
    widths <- xs[starts + 1L] - xs[starts]
    k <- which.max(widths)
    if (widths[k] > best) {
      best <- widths[k]; anchor <- c(mean(xs[c(starts[k], starts[k] + 1L)]), y0)
    }
  }
  anchor
}

.region_cell <- function(i, sx, sy, sw, box, region) {
  cell <- box
  for (j in seq_along(sx)) {
    if (j == i) next
    if (nrow(cell) < 3L) return(list())
    a <- 2 * (sx[j] - sx[i]); b <- 2 * (sy[j] - sy[i])
    cc <- sx[j]^2 - sx[i]^2 + sy[j]^2 - sy[i]^2 - sw[j] + sw[i]
    cell <- clip_polygon_halfplane(cell, a, b, cc)
  }
  if (nrow(cell) < 3L) return(list())
  polyclip::polyclip(list(list(x = cell[, 1], y = cell[, 2])), region,
                     "intersection", eps = 1e-10)
}

.region_solve <- function(target, region, max_iter, tolerance, verbose) {
  n <- length(target); area <- sum(target)
  if (n == 1L) {
    ctr <- .region_anchor(region)
    return(list(cells = list(region), sx = ctr[1], sy = ctr[2], sw = area / pi,
                areas = area, iterations = 0L, convergence = 0, converged = TRUE))
  }
  coords <- .region_coordinates(region)
  xr <- range(coords[, 1]); yr <- range(coords[, 2])
  box <- cbind(c(xr[1], xr[2], xr[2], xr[1]), c(yr[1], yr[1], yr[2], yr[2]))
  # Bounded rejection sampling: invalid or extremely thin shapes cannot hang.
  pool <- matrix(numeric(), ncol = 2); attempts <- 0L
  desired <- max(64L, n * 20L)
  while (nrow(pool) < desired && attempts < max(10000L, n * 1000L)) {
    px <- stats::runif(desired, xr[1], xr[2]); py <- stats::runif(desired, yr[1], yr[2])
    ok <- vapply(seq_along(px), function(k) .region_inside(c(px[k], py[k]), region), logical(1))
    pool <- rbind(pool, cbind(px[ok], py[ok])); attempts <- attempts + desired
  }
  if (nrow(pool) < n) stop("Could not sample enough interior points; rescale or simplify this very thin region.", call. = FALSE)
  chosen <- integer(n); chosen[1] <- 1L
  distance <- rowSums(sweep(pool, 2, pool[1, ])^2)
  for (i in 2:n) {
    distance[chosen[seq_len(i - 1L)]] <- -Inf
    chosen[i] <- which.max(distance)
    distance <- pmin(distance, rowSums(sweep(pool, 2, pool[chosen[i], ])^2))
  }
  sx <- pool[chosen, 1]; sy <- pool[chosen, 2]
  epsilon <- area * 1e-9
  sw <- pmax(target / pi, epsilon)
  history <- numeric(); best <- NULL; best_error <- Inf
  # Lloyd-style position adaptation is useful early, but can stall on thin,
  # indented shapes. Reserve the remaining budget for fixed-site balancing.
  for (it in seq_len(min(max_iter, 100L))) {
    fmr <- .flickering_ratio(history, area)
    cells <- lapply(seq_len(n), .region_cell, sx, sy, sw, box, region)
    for (i in seq_len(n)) {
      if (!length(cells[[i]])) next
      ctr <- .region_centroid(cells[[i]])
      damping <- 1 - 0.5 * fmr
      # Keep sites in their region when a concave cell's centroid lies outside.
      for (trial in seq_len(20L)) {
        next_point <- c(sx[i], sy[i]) + damping * (ctr - c(sx[i], sy[i]))
        if (.region_inside(next_point, region)) {
          sx[i] <- next_point[1]; sy[i] <- next_point[2]; break
        }
        damping <- damping / 2
      }
    }
    cells <- lapply(seq_len(n), .region_cell, sx, sy, sw, box, region)
    current <- vapply(cells, .region_area, numeric(1))
    fm <- 0.1 * fmr
    ratio <- target / pmax(current, area * 1e-15)
    sw <- pmax(sw * pmin(pmax(ratio, 0.9 + fm), 1.1 - fm), epsilon)
    sw <- .handle_overweighted(sx, sy, sw, n, epsilon)
    cells <- lapply(seq_len(n), .region_cell, sx, sy, sw, box, region)
    areas <- vapply(cells, .region_area, numeric(1))
    error <- sum(abs(target - areas))
    history <- c(history, error)
    if (error < best_error) {
      best_error <- error
      best <- list(cells = cells, sx = sx, sy = sy, sw = sw, areas = areas)
    }
    if (verbose && (it == 1L || it %% 25L == 0L)) {
      message(sprintf("Iteration %d | total area error %.4f%%", it, 100 * error / area))
    }
    if (error / area < tolerance) break
  }
  if (best_error / area >= tolerance && it < max_iter) {
    # For fixed sites, a cell's area increases monotonically with its own
    # power weight. Coordinate-wise bisection avoids the positivity/overlap
    # restrictions of the multiplicative heuristic. Power weights may be
    # negative; adding a common constant leaves the diagram unchanged.
    sx <- best$sx; sy <- best$sy; sw <- best$sw
    while (it < max_iter && best_error / area >= tolerance) {
      it <- it + 1L
      for (i in seq_len(n)) {
        lo <- min(sw) - 4; hi <- max(sw) + 4
        for (step in seq_len(45L)) {
          sw[i] <- (lo + hi) / 2
          actual <- .region_area(.region_cell(i, sx, sy, sw, box, region))
          if (abs(actual - target[i]) < area * tolerance / (20 * n)) break
          if (actual < target[i]) lo <- sw[i] else hi <- sw[i]
        }
      }
      sw <- sw - mean(sw)
      cells <- lapply(seq_len(n), .region_cell, sx, sy, sw, box, region)
      areas <- vapply(cells, .region_area, numeric(1))
      error <- sum(abs(target - areas))
      if (error < best_error) {
        best_error <- error
        best <- list(cells = cells, sx = sx, sy = sy, sw = sw, areas = areas)
      }
      if (verbose && (it %% 25L == 0L || error / area < tolerance)) {
        message(sprintf("Iteration %d (fixed sites) | total area error %.4f%%", it, 100 * error / area))
      }
    }
  }
  c(best, list(iterations = it, convergence = best_error / area,
               converged = best_error / area < tolerance))
}
