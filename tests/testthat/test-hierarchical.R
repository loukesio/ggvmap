test_that("hierarchical layout partitions by group weight", {
  w <- c(5, 3, 2, 8, 4, 6, 1, 2, 3)
  g <- c("A", "A", "A", "B", "B", "B", "C", "C", "C")
  vm <- voronoi_map(w, group = g, clip = clip_circle(), seed = 1)

  expect_s3_class(vm, "voronoi_map")
  expect_true(vm$hierarchical)
  expect_length(vm$cells, length(w))
  expect_equal(nrow(vm$groups$sites), 3)

  # Total cell area equals the clip area
  total_clip <- abs(ggvmap:::polygon_area(vm$clip))
  total_cell <- sum(abs(vapply(vm$cells, ggvmap:::polygon_area, numeric(1))))
  expect_equal(total_cell, total_clip, tolerance = 0.01)

  # Group areas roughly proportional to group weights
  ga <- tapply(vm$sites$actual_area, vm$sites$group, sum)
  gw <- tapply(w, g, sum)
  ga <- ga[names(gw)]
  expect_true(all(abs(ga / sum(ga) - gw / sum(gw)) < 0.05))
})

test_that("sites carry group labels in cell order", {
  w <- c(4, 2, 6, 1)
  g <- c("X", "Y", "X", "Y")
  vm <- voronoi_map(w, labels = c("a", "b", "c", "d"), group = g, seed = 2)
  expect_equal(vm$sites$group, g)
  expect_equal(vm$sites$label, c("a", "b", "c", "d"))
})

test_that("single-member groups fill their whole sub-region", {
  w <- c(5, 3, 2)
  g <- c("A", "B", "C")           # every group has one member
  vm <- voronoi_map(w, group = g, clip = clip_circle(), seed = 1)
  expect_length(vm$cells, 3)
  # member cell area == group cell area for single-member groups
  for (k in 1:3) {
    expect_equal(
      abs(ggvmap:::polygon_area(vm$cells[[k]])),
      abs(ggvmap:::polygon_area(vm$groups$cells[[k]])),
      tolerance = 1e-6
    )
  }
})

test_that("vm_as_df includes a group column when hierarchical", {
  vm <- voronoi_map(c(3, 2, 5), group = c("A", "A", "B"), seed = 1)
  df <- vm_as_df(vm)
  expect_true("group" %in% names(df))
  expect_setequal(unique(df$group), c("A", "B"))
})

test_that("grouped `converged` reflects the whole-map error", {
  data(freshwater, package = "ggvmap", envir = environment())
  vm <- voronoi_map(freshwater$share, labels = freshwater$country,
                    group = freshwater$region, clip = clip_circle(),
                    seed = 5, max_iter = 80)
  # The reported error is measured against the targets stored in `sites`.
  err <- sum(abs(vm$sites$actual_area - vm$sites$target_area)) /
    abs(ggvmap:::polygon_area(vm$clip))
  expect_equal(vm$convergence, err, tolerance = 1e-9)
  expect_identical(vm$converged, vm$convergence < 0.01)
  expect_true(vm$converged)
  # One fit row for the group level plus one per group
  expect_equal(nrow(vm$groups$fit), 1L + length(unique(freshwater$region)))
  expect_true(all(vm$groups$fit$convergence < 0.005 | !vm$groups$fit$converged))
})

test_that("an exhausted budget is reported as not converged", {
  set.seed(9)
  vm <- voronoi_map(rlnorm(40, 3, 1), group = rep(c("A", "B", "C", "D"), 10),
                    clip = clip_circle(), seed = 1, max_iter = 2)
  expect_false(vm$converged)
  expect_gte(vm$convergence, 0.01)
  expect_output(print(vm), "Unconverged levels")
})

test_that("small-weight floor is applied once, to the whole map", {
  w <- c(100, 50, 0.1, 30, 0.2, 20)
  g <- c("A", "A", "A", "B", "B", "B")
  vm <- voronoi_map(w, group = g, clip = clip_circle(), seed = 2)
  floor <- pmax(w, max(w) * 0.01)
  expect_equal(vm$sites$target_area / sum(vm$sites$target_area),
               floor / sum(floor), tolerance = 1e-9)
})
