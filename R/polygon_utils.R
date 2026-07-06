# ---- Polygon utilities ----
# Low-level geometry helpers used throughout the package.
# All polygons are represented as 2-column matrices (x, y),
# open (no duplicated closing point), counterclockwise.

#' Signed area of a simple polygon (shoelace formula)
#' @param poly A 2-column matrix (x, y).
#' @return Signed area (positive if counterclockwise).
#' @noRd
polygon_area <- function(poly) {

  n <- nrow(poly)
  if (n < 3L) return(0)
  # Shoelace formula
  j <- c(2:n, 1L)
  0.5 * sum(poly[, 1] * poly[j, 2] - poly[j, 1] * poly[, 2])
}

#' Centroid of a simple polygon
#' @param poly A 2-column matrix (x, y).
#' @return Numeric vector c(cx, cy).
#' @noRd
polygon_centroid <- function(poly) {
  n <- nrow(poly)
  if (n < 3L) return(colMeans(poly))
  j  <- c(2:n, 1L)
  cross <- poly[, 1] * poly[j, 2] - poly[j, 1] * poly[, 2]
  a  <- sum(cross)  # 2 * signed area
  # Degenerate (near-zero area) polygon: the centroid formula divides by ~0,
  # so fall back to the vertex mean instead of returning NaN/Inf.
  if (abs(a) < 1e-12) return(colMeans(poly))
  cx <- sum((poly[, 1] + poly[j, 1]) * cross) / (3 * a)
  cy <- sum((poly[, 2] + poly[j, 2]) * cross) / (3 * a)
  c(cx, cy)
}

#' Test whether a point lies inside a convex polygon
#' Uses the cross-product winding approach.
#' @param point Numeric vector c(x, y).
#' @param poly  2-column matrix (x, y), counterclockwise.
#' @return Logical.
#' @noRd
point_in_polygon <- function(point, poly) {
  n <- nrow(poly)
  for (i in seq_len(n)) {
    j <- if (i == n) 1L else i + 1L
    # Cross product of edge vector and point vector
    cross <- (poly[j, 1] - poly[i, 1]) * (point[2] - poly[i, 2]) -
             (poly[j, 2] - poly[i, 2]) * (point[1] - poly[i, 1])
    if (cross < -1e-10) return(FALSE)
  }
  TRUE
}

#' Clip a convex polygon by a half-plane  (Sutherland-Hodgman, single edge)
#'
#' Keeps the region where  a*x + b*y <= c.
#'
#' @param poly 2-column matrix.
#' @param a,b,c Half-plane coefficients.
#' @return Clipped polygon (2-column matrix), or a zero-row matrix if empty.
#' @noRd
clip_polygon_halfplane <- function(poly, a, b, c) {
  n <- nrow(poly)
  if (n < 1L) return(matrix(numeric(0), ncol = 2))

  out_x <- numeric(2L * n)
  out_y <- numeric(2L * n)
  k     <- 0L

  # Evaluate which side each vertex is on
  vals <- a * poly[, 1] + b * poly[, 2] - c

  for (i in seq_len(n)) {
    j <- if (i == n) 1L else i + 1L
    vi <- vals[i]
    vj <- vals[j]
    inside_i <- vi <= 1e-10
    inside_j <- vj <= 1e-10

    if (inside_i) {
      k <- k + 1L
      out_x[k] <- poly[i, 1]
      out_y[k] <- poly[i, 2]
    }

    if ((inside_i && !inside_j) || (!inside_i && inside_j)) {
      # Edge crosses the boundary -- compute intersection
      t <- vi / (vi - vj)
      k <- k + 1L
      out_x[k] <- poly[i, 1] + t * (poly[j, 1] - poly[i, 1])
      out_y[k] <- poly[i, 2] + t * (poly[j, 2] - poly[i, 2])
    }
  }

  if (k == 0L) return(matrix(numeric(0), ncol = 2))
  cbind(out_x[1:k], out_y[1:k])
}

#' Generate a regular polygon with n sides inscribed in a circle
#' @param n Number of sides.
#' @param cx,cy Centre coordinates.
#' @param r Radius.
#' @return 2-column matrix (x, y), counterclockwise, open.  The matrix carries
#'   attributes `"center"`, `"radius"` and `"shape"` describing the boundary,
#'   which downstream helpers (radial seeding, the annotation ring) read.
#' @export
regular_polygon <- function(n = 6, cx = 0.5, cy = 0.5, r = 0.5) {
  angles <- seq(0, 2 * pi, length.out = n + 1)[-(n + 1)] - pi / 2
  m <- cbind(cx + r * cos(angles), cy + r * sin(angles))
  .set_clip_meta(m, center = c(cx, cy), radius = r,
                 shape = if (n >= 32) "circle" else "polygon")
}

#' Attach boundary metadata to a clip polygon
#' @noRd
.set_clip_meta <- function(m, center, radius, shape) {
  attr(m, "center") <- center
  attr(m, "radius") <- radius
  attr(m, "shape")  <- shape
  m
}

#' Infer boundary metadata for any clip polygon
#'
#' Reads the `"center"` / `"radius"` / `"shape"` attributes when present,
#' otherwise estimates them from the polygon geometry.
#' @noRd
.clip_meta <- function(clip) {
  center <- attr(clip, "center")
  radius <- attr(clip, "radius")
  shape  <- attr(clip, "shape")
  if (is.null(center)) center <- colMeans(clip)
  if (is.null(radius)) {
    radius <- mean(sqrt((clip[, 1] - center[1])^2 + (clip[, 2] - center[2])^2))
  }
  if (is.null(shape)) {
    d <- sqrt((clip[, 1] - center[1])^2 + (clip[, 2] - center[2])^2)
    shape <- if (stats::sd(d) / mean(d) < 0.02) "circle" else "polygon"
  }
  list(center = center, radius = radius, shape = shape,
       circular = shape == "circle")
}

#' Generate common clipping shapes
#'
#' Convenience wrappers around [regular_polygon()] for common shapes.
#'
#' @param cx,cy Centre coordinates.  Default `0.5`.
#' @param r Radius (half-width for the square).  Default `0.5`.
#' @param n Number of sides used to approximate the circle.  Default `64`.
#' @return A 2-column matrix suitable for the `clip` argument of [voronoi_map()].
#' @name clip_shapes
#' @export
clip_square <- function(cx = 0.5, cy = 0.5, r = 0.5) {
  s <- r
  # Counterclockwise in standard math coordinates
  m <- cbind(
    c(cx - s, cx + s, cx + s, cx - s),
    c(cy - s, cy - s, cy + s, cy + s)
  )
  .set_clip_meta(m, center = c(cx, cy), radius = r, shape = "square")
}

#' @rdname clip_shapes
#' @export
clip_hexagon <- function(cx = 0.5, cy = 0.5, r = 0.5) {
  regular_polygon(6, cx, cy, r)
}

#' @rdname clip_shapes
#' @export
clip_circle <- function(cx = 0.5, cy = 0.5, r = 0.5, n = 64) {
  regular_polygon(n, cx, cy, r)
}

#' @rdname clip_shapes
#' @export
clip_diamond <- function(cx = 0.5, cy = 0.5, r = 0.5) {
  regular_polygon(4, cx, cy, r)
}
