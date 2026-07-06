# ---- Power diagram (weighted Voronoi) via half-plane intersection ----
#
# For n sites each with position (x_i, y_i) and weight w_i, the power cell
# of site i is the set of all points closer to i in the *power distance*:
#
#   pow_i(x, y) = (x - x_i)^2 + (y - y_i)^2 - w_i
#
# The bisector between sites i and j is a *line* (not a curve):
#
#   2(x_j - x_i) x + 2(y_j - y_i) y = (x_j^2 - x_i^2 + y_j^2 - y_i^2 - w_j + w_i)
#
# So each cell is the intersection of half-planes, which we compute by
# iteratively clipping the bounding polygon (Sutherland-Hodgman).

#' Compute power-diagram cells clipped to a convex polygon
#'
#' @param sites Data frame or matrix with columns `x`, `y`, `weight`.
#' @param clip  Bounding polygon, 2-column matrix (counterclockwise, open).
#' @return A list of 2-column matrices, one per site.  Sites whose cell
#'   collapses to fewer than 3 vertices get a tiny triangle at their position.
#' @noRd
power_diagram <- function(sites, clip) {
  n <- nrow(sites)
  x <- sites[, "x"]
  y <- sites[, "y"]
  w <- sites[, "weight"]

  cells <- vector("list", n)

  for (i in seq_len(n)) {
    cell <- clip
    for (j in seq_len(n)) {
      if (j == i) next
      if (nrow(cell) < 3L) break
      # Half-plane: keep side of site i
      # a*px + b*py <= c
      a <- 2 * (x[j] - x[i])
      b <- 2 * (y[j] - y[i])
      cc <- (x[j]^2 - x[i]^2) + (y[j]^2 - y[i]^2) - (w[j] - w[i])
      cell <- clip_polygon_halfplane(cell, a, b, cc)
    }

    if (nrow(cell) < 3L) {
      # Degenerate cell -- give it a tiny triangle so it doesn't vanish
      eps <- 1e-6
      cell <- cbind(
        c(x[i] - eps, x[i] + eps, x[i]),
        c(y[i] - eps, y[i] - eps, y[i] + eps)
      )
    }
    cells[[i]] <- cell
  }
  cells
}
