library(testthat)

# Internal geometry helpers are reached via ::: ; exported API directly.
polygon_area          <- ggvmap:::polygon_area
polygon_centroid      <- ggvmap:::polygon_centroid
point_in_polygon      <- ggvmap:::point_in_polygon
clip_polygon_halfplane <- ggvmap:::clip_polygon_halfplane
power_diagram         <- ggvmap:::power_diagram

test_that("polygon_area computes correct areas", {
  # Unit square
  sq <- clip_square()
  expect_equal(polygon_area(sq), 1, tolerance = 1e-10)

  # Hexagon inscribed in r=0.5 circle
  hex <- clip_hexagon()
  expected <- 0.5^2 * 6 * sin(pi / 3) / 2
  expect_equal(polygon_area(hex), expected, tolerance = 1e-10)

  # Diamond
  dm <- clip_diamond()
  expect_equal(abs(polygon_area(dm)), 0.5, tolerance = 1e-10)
})

test_that("polygon_centroid returns correct centroids", {
  sq <- clip_square()
  expect_equal(polygon_centroid(sq), c(0.5, 0.5), tolerance = 1e-10)

  sq2 <- clip_square(cx = 2, cy = 3)
  expect_equal(polygon_centroid(sq2), c(2, 3), tolerance = 1e-10)
})

test_that("point_in_polygon works correctly", {
  sq <- clip_square()
  expect_true(point_in_polygon(c(0.5, 0.5), sq))
  expect_true(point_in_polygon(c(0.1, 0.1), sq))
  expect_false(point_in_polygon(c(2, 2), sq))
  expect_false(point_in_polygon(c(-0.1, 0.5), sq))
})

test_that("clip_polygon_halfplane clips correctly", {
  sq <- clip_square()
  # Clip by x <= 0.5  (a=1, b=0, c=0.5)
  clipped <- clip_polygon_halfplane(sq, 1, 0, 0.5)
  expect_equal(abs(polygon_area(clipped)), 0.5, tolerance = 1e-10)
})

test_that("power_diagram produces valid cells", {
  sq <- clip_square()
  sites <- cbind(
    x      = c(0.3, 0.7, 0.5),
    y      = c(0.3, 0.3, 0.7),
    weight = c(0.1, 0.1, 0.1)
  )
  cells <- power_diagram(sites, sq)
  expect_length(cells, 3)

  # Total cell area should equal polygon area
  total <- sum(abs(vapply(cells, polygon_area, numeric(1))))
  expect_equal(total, 1.0, tolerance = 0.01)
})

test_that("voronoi_map converges for small examples", {
  vm <- voronoi_map(c(3, 2, 5, 1, 4), seed = 42)
  expect_s3_class(vm, "voronoi_map")
  expect_true(vm$converged)
  expect_true(vm$convergence < 0.02)
  expect_length(vm$cells, 5)

  # Cell areas should be roughly proportional to weights
  ratios <- vm$sites$actual_area / vm$sites$target_area
  expect_true(all(ratios > 0.8 & ratios < 1.2))
})

test_that("voronoi_map works with different shapes", {
  fns <- list(clip_square, clip_hexagon, clip_diamond, clip_circle,
              clip_triangle, clip_pentagon, clip_octagon,
              clip_rectangle, clip_ellipse)
  for (shape_fn in fns) {
    clip <- shape_fn()
    vm <- voronoi_map(c(1, 2, 3, 4), clip = clip, seed = 1)
    expect_s3_class(vm, "voronoi_map")
    expect_length(vm$cells, 4)
    # cells tile the clip exactly
    total <- sum(abs(vapply(vm$cells, polygon_area, numeric(1))))
    expect_equal(total, abs(polygon_area(clip)), tolerance = 1e-6)
  }
})

test_that("new clip shapes are convex and have the expected areas", {
  # rectangle area = width * height
  expect_equal(abs(polygon_area(clip_rectangle(width = 1, height = 0.6))), 0.6,
               tolerance = 1e-10)
  # ellipse area approaches pi * a * b
  el <- clip_ellipse(a = 0.5, b = 0.3, n = 512)
  expect_equal(abs(polygon_area(el)), pi * 0.5 * 0.3, tolerance = 1e-3)
})

test_that("vm_as_df returns correct structure", {
  vm <- voronoi_map(c(3, 2, 5), labels = c("A", "B", "C"), seed = 1)
  df <- vm_as_df(vm)
  expect_true(is.data.frame(df))
  expect_true(all(c("cell", "label", "x", "y", "target_area", "actual_area") %in% names(df)))
  expect_equal(length(unique(df$cell)), 3)
})

test_that("seed ensures reproducibility", {
  vm1 <- voronoi_map(c(3, 2, 5), seed = 42)
  vm2 <- voronoi_map(c(3, 2, 5), seed = 42)
  expect_equal(vm1$sites$x, vm2$sites$x)
  expect_equal(vm1$sites$y, vm2$sites$y)
})

test_that("vm_fit reports per-cell shares that sum to one", {
  vm <- voronoi_map(c(50, 30, 15, 5), labels = c("A", "B", "C", "D"), seed = 1)
  fit <- vm_fit(vm)
  expect_equal(nrow(fit), 4L)
  expect_equal(sum(fit$target_share), 1, tolerance = 1e-9)
  expect_equal(sum(fit$actual_share), 1, tolerance = 1e-6)
  expect_equal(fit$value_share, c(50, 30, 15, 5) / 100)
  expect_equal(sum(abs(fit$abs_error)), vm$convergence, tolerance = 1e-6)
})

test_that("min_weight_ratio = 0 keeps targets strictly proportional", {
  w <- c(1000, 1, 5, 200)
  vm <- voronoi_map(w, seed = 3, min_weight_ratio = 0)
  expect_equal(vm_fit(vm)$target_share, w / sum(w), tolerance = 1e-9)
})

test_that("a dominant value is fitted (Newton phase rescues stalled rounds)", {
  set.seed(1003)
  w <- rlnorm(20, 3, 2)             # one value is ~80% of the total
  vm <- voronoi_map(w, clip = clip_circle(), seed = 3)
  expect_true(vm$converged)
  expect_lt(vm$convergence, 0.01)
  fit <- vm_fit(vm)
  big <- which.max(fit$value)
  expect_lt(abs(fit$rel_error[big]), 0.01)
})

test_that("Newton weights reproduce target areas for fixed sites", {
  set.seed(4)
  clip <- clip_square()
  sx <- runif(12, 0.05, 0.95); sy <- runif(12, 0.05, 0.95)
  target <- c(0.5, rep(0.5 / 11, 11))
  nw <- ggvmap:::.newton_weights(sx, sy, target, clip, tol_abs = 1e-8,
                                 max_steps = 50)
  expect_lt(nw$error, 1e-8)
  expect_equal(sum(nw$areas), 1, tolerance = 1e-9)
})
