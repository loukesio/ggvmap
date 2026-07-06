# Mathematical-correctness invariants for the power-diagram / Voronoi treemap.
# These encode the definitional properties verified in the package's validation
# study: the defining argmin property, exact tiling, convexity, and finiteness.

`in_convex` <- function(pt, poly, margin = 0) {
  n <- nrow(poly); cr <- numeric(n)
  for (i in seq_len(n)) {
    j <- if (i == n) 1L else i + 1L
    cr[i] <- (poly[j,1]-poly[i,1])*(pt[2]-poly[i,2]) -
             (poly[j,2]-poly[i,2])*(pt[1]-poly[i,1])
  }
  all(cr > margin) || all(cr < -margin)
}
`pow_dist` <- function(pt, sx, sy, sw) (pt[1]-sx)^2 + (pt[2]-sy)^2 - sw
`cell_area` <- function(c) abs(ggvmap:::polygon_area(c))
`convex_ok` <- function(poly) {
  n <- nrow(poly); if (n < 3) return(FALSE); s <- c()
  for (i in seq_len(n)) {
    a <- poly[i, ]; b <- poly[if (i == n) 1 else i + 1, ]
    cc <- poly[if (i >= n - 1) (i + 1) %% n + 1 else i + 2, ]
    s <- c(s, sign((b[1]-a[1])*(cc[2]-b[2]) - (b[2]-a[2])*(cc[1]-b[1])))
  }
  s <- s[s != 0]; all(s >= 0) || all(s <= 0)
}
`sample_in` <- function(clip, n) {
  xr <- range(clip[,1]); yr <- range(clip[,2]); o <- matrix(nrow=0, ncol=2); t <- 0
  while (nrow(o) < n && t < 50) {
    t <- t + 1; k <- (n-nrow(o))*3
    cx <- stats::runif(k, xr[1], xr[2]); cy <- stats::runif(k, yr[1], yr[2])
    ok <- vapply(seq_len(k), function(i) in_convex(c(cx[i],cy[i]), clip, 1e-9), logical(1))
    o <- rbind(o, cbind(cx[ok], cy[ok]))
  }
  o[seq_len(min(n, nrow(o))), , drop = FALSE]
}

test_that("power_diagram cell = argmin power distance (defining property)", {
  set.seed(1)
  clip <- clip_square()
  for (rep in 1:5) {
    n <- sample(3:8, 1)
    sx <- runif(n, 0.1, 0.9); sy <- runif(n, 0.1, 0.9); sw <- runif(n, 0, 0.04)
    cells <- ggvmap:::power_diagram(cbind(x = sx, y = sy, weight = sw), clip)
    pts <- sample_in(clip, 300)
    for (p in seq_len(nrow(pts))) {
      pt <- pts[p, ]
      inside <- which(vapply(cells, function(c) in_convex(pt, c, 1e-10), logical(1)))
      if (length(inside) == 1L) {
        expect_equal(inside, which.min(pow_dist(pt, sx, sy, sw)))
      }
    }
  }
})

test_that("flat treemap cells tile the clip exactly and stay convex", {
  for (sh in list(clip_square(), clip_circle(), clip_hexagon(), clip_diamond())) {
    vm <- voronoi_map(c(5, 3, 8, 2, 6, 4), clip = sh, seed = 1)
    total <- sum(vapply(vm$cells, cell_area, numeric(1)))
    expect_equal(total, cell_area(vm$clip), tolerance = 1e-6)
    expect_true(all(vapply(vm$cells, convex_ok, logical(1))))
    expect_false(any(vapply(vm$cells, function(c)
      any(!is.finite(ggvmap:::polygon_centroid(c))), logical(1))))
  }
})

test_that("no point lands in zero or multiple cells (partition)", {
  set.seed(2)
  vm <- voronoi_map(runif(15, 1, 50), clip = clip_circle(), seed = 5)
  pts <- sample_in(vm$clip, 800)
  counts <- vapply(seq_len(nrow(pts)), function(p)
    sum(vapply(vm$cells, function(c) in_convex(pts[p, ], c, 1e-10), logical(1))),
    integer(1))
  expect_equal(mean(counts == 1L), 1, tolerance = 0.001)  # no gaps, no overlaps
})

test_that("hierarchical member cells exactly fill their group cell", {
  set.seed(3)
  n <- 18
  grp <- sample(c("A", "B", "C"), n, replace = TRUE)
  vm <- voronoi_map(runif(n, 1, 40), group = grp, clip = clip_circle(), seed = 4)
  for (k in seq_along(vm$groups$sites$label)) {
    g <- vm$groups$sites$label[k]
    idx <- which(vm$sites$group == g)
    filled <- sum(vapply(vm$cells[idx], cell_area, numeric(1)))
    expect_equal(filled, cell_area(vm$groups$cells[[k]]), tolerance = 1e-6)
  }
  # global tiling too
  expect_equal(sum(vapply(vm$cells, cell_area, numeric(1))),
               cell_area(vm$clip), tolerance = 1e-6)
})

test_that("polygon_centroid is finite for a degenerate (near-zero-area) cell", {
  degenerate <- cbind(c(0, 1, 2), c(0, 1e-14, 0))  # collinear -> ~0 area
  ctr <- ggvmap:::polygon_centroid(degenerate)
  expect_true(all(is.finite(ctr)))
})
